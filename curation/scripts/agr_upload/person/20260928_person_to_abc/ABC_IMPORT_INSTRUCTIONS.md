# WormBase person data → ABC import instructions

WormBase is moving its person data to the ABC (`agr_literature_service`) in a single, one-time
transfer. This file tells the ABC import script what each export file holds, which order to load
them in, and how each field maps onto ABC models.

The exporter is `curation/scripts/agr_upload/person/20260928_person_to_abc/person_to_abc.pl` in
`caltech-curation-services`. Every run writes all of its files from one database snapshot. Never
mix files from different runs: persons are created during author verification, so a person file
and a paper file taken at different times won't agree. For the final transfer, WormBase freezes
person creation and author verification before it runs the export.

## Where the files are

`https://caltech-curation.textpressolab.com/files/priv/agr_upload/person/` (HTTP basic auth, ask
WormBase for the login). On the WormBase server this is
`/usr/caltech_curation_files/priv/agr_upload/person/`.

The directory sits behind a login because the files hold emails, addresses, internal curator
notes and requests not to be contacted. Don't copy them anywhere public.

Each run writes `person_to_abc.<YYYYMMDD_HHMMSS>.<suffix>`.
`person_to_abc.latest.<suffix>` is a symlink to the newest run.

| suffix | contents |
|---|---|
| `ABC_IMPORT_INSTRUCTIONS.md` | this file, as it was for that run |
| `laboratory.jsonl` | one laboratory per line |
| `person.jsonl` | one person per line, including their laboratory memberships |
| `person_lineage.tsv` | one validated person-to-person relationship per line |
| `person_lineage_submission.tsv` | one WormBase lineage row per line, the submitted claims |
| `paper_author_person.tsv` | one verified author → person connection per line |
| `counts.tsv` | how many rows were exported or skipped, to check the import against |
| `not_loaded.tsv` | WormBase data ABC can't hold: what it is, how many rows, and whether it is in the files |
| `problems.tsv` | row-level issues for WormBase curators to fix before the final export, with a summary at the top |
| `character_fixes.tsv` | every value whose garbled characters the exporter repaired, before and after, with a summary at the top |

## General format

- **Encoding:** every file is UTF-8. A few WormBase values had garbled characters: UTF-8 text that
  was once read as Latin-1 or Windows-1252, so an apostrophe was stored as `â` plus two invisible
  control characters. The exporter repairs these, writing repaired apostrophes, dashes, double quotes and spaces as plain `'`, `-`, `"` and space. Each
  repair is listed in `character_fixes.tsv`, and the importer doesn't need to do anything.
- **Line breaks:** values that hold several lines (`street_address`, `biography_research_interest`,
  `additional_information`, `private_note`) separate the lines with a newline. In JSONL that is the
  `\n` escape, which a JSON parser already turns into a line break, so store the string as it is.
- **JSONL:** one complete JSON object per line, so the files can be read a line at a time.
  Report errors by line number.
- **TSV:**
  - The first line is the header. There's no quoting.
  - Tabs and newlines inside values were replaced with a space.
  - An empty column means no value.
- **Value wrapper:** in the JSONL files, almost every value comes as
  `{"value": ..., "curator": "WBPerson1", "timestamp": "2014-01-24T17:19:21.338866-08:00"}`.
  Child rows (names, emails, notes and so on) carry `curator` and `timestamp` beside their own fields.
- **Timestamps:** ISO 8601 with the UTC offset.
- **Curators:** WormBase person ids (`WBPerson1`). An empty curator means WormBase didn't record one.
- **Record dates:** each JSONL record has `date_created` and `date_updated` for the record as a
  whole. For persons, `date_created` is when the WBPerson was made. `date_updated` is the latest
  timestamp found anywhere in the record.
- **Identifiers:**
  - persons: `WB:WBPerson<n>` (person_cross_reference)
  - laboratories: `WB:<lab code>` (laboratory_cross_reference)
  - papers: `WB:WBPaper<8 digits>` (reference cross_reference)

  The importer resolves every link between files through these cross references.

### Audit fields (`date_created`, `date_updated`, `created_by`, `updated_by`)

- Set `date_created` and `date_updated` from the `timestamp` of each row, or from the record's
  `date_created` and `date_updated`. ABC's `before_insert` keeps explicit values.
- Every curator is a WBPerson, and every exported WBPerson is created as an ABC person in step 2.
  Which ABC `users` row each curator becomes is ABC's decision. What WormBase knows:
  - About 12,000 distinct WBPersons appear as curators, because authors who verified their own
    papers are recorded as the curator.
  - Earlier WormBase loads (topic entity tags) used `WBPerson<n>` directly as `created_by`, so some
    curators already have a `users` row with that id and no person linked. Existing data points at
    those rows.
  - Some curators, mostly WormBase staff, also have a person-linked `users` row from logging into
    ABC. That means ABC already has a person for them.
  - ABC's login finds a user through `person_email` to `users.person_id`.

  The importer should end with one `users` row per human where it can, and should not create a
  second ABC person for someone who already has one. Matching an existing ABC person by its
  `WB:WBPerson<n>` cross reference, then by email, is one way to find them.
- A curator WBPerson that wasn't exported (Invalid and never merged) has no ABC person. Use the
  import's default user for those.
- `person_lineage` has no WormBase curator at all; see step 4.

## Before loading

1. **Resolve `problems.tsv`.** The commented summary at the top gives, for each kind of problem,
   its severity, file, count and why it matters:
   - `blocks import`: ABC will reject the rows.
   - `fix or importer default`: the importer has to supply a value if WormBase doesn't fix it.
   - `info`: already handled by the exporter, listed so nothing changes silently.

   WormBase curators fix problems in WormBase and then re-run the export. The `blocks import` ones,
   which must all be zero for the final transfer, are:
   - **paper_author_person: same person on more than one author position.** ABC has a unique
     index on (reference_id, person_id), so this must be zero.
   - **person: ORCID on more than one person, and more than one ORCID on a person.** ABC has unique
     indexes on the live (non-obsolete) `curie`, and on (person_id, curie_prefix).
   - **person_lineage_submission: no two_sender.** ABC requires `who_sent_this`.
   - **person: no last name.** ABC requires `person_name.last_name`.

   Everything else in the file is informational: rows skipped or adjusted, with the reason.
2. Read `not_loaded.tsv`. It is the record of what WormBase data won't exist at ABC after the switch.
3. Do a dry run against a copy of the ABC database, and compare against `counts.tsv`.
4. Load each file in one transaction, so a failure leaves nothing half loaded. Every new person and
   laboratory mints a MATI curie, and MATI ids are not rolled back, so dry runs should mint test ids.

## Load order

| step | file | ABC tables | needs |
|---|---|---|---|
| 1 | `laboratory.jsonl` | laboratory, laboratory_cross_reference, laboratory_allele_designation | |
| 2 | `person.jsonl` | person, person_name, person_email, person_institution, person_cross_reference, person_note | |
| 3 | `person.jsonl`, `laboratories` | laboratory_person | steps 1 and 2 |
| 4 | `person_lineage.tsv` | person_lineage | step 2 |
| 5 | `person_lineage_submission.tsv` | person_lineage_submission | steps 2 and 4 |
| 6 | `paper_author_person.tsv` | author.person_id | step 2, and WormBase references already in ABC |

Steps 2 and 3 can share one pass over `person.jsonl`, since all laboratories exist after step 1.

## Step 1: laboratory.jsonl

Only labs that are Valid in WormBase are exported.

| JSON key | ABC | notes |
|---|---|---|
| `strain_designation.value` | `laboratory.strain_designation` | WormBase lab codes are CGC strain designations (`PS`, `CB`) |
| `cross_references[]` | `laboratory_cross_reference` | `WB:<code>` |
| (none) | `laboratory.name` | WormBase has no separate lab name; leave it null |
| `status.value` | `laboratory.status` | always `active` |
| `institution[].value` | `laboratory.institution` (array) | |
| `email[].value` | `laboratory.email` (array) | `email_visibility` is ABC's decision |
| `webpage[].value` | `laboratory.webpage` (array) | |
| `allele_designations[].value` | `laboratory_allele_designation.allele_designation` | `mod_id` = WB |
| `additional_information.value` | `laboratory.additional_information` | public remarks, joined with newlines |
| `private_note.value` | `laboratory.private_note` | internal comments, joined with newlines |
| `wb_lab_id` | | WormBase's internal key (`lab185`), for tracing only |

## Step 2: person.jsonl

Only Valid persons are exported. A person that was merged into another is not exported as its own
person. It appears as an obsolete `WB:WBPerson` cross reference on the person it was merged into.

| JSON key | ABC | notes |
|---|---|---|
| `wb_person_id` | | the WBPerson id, also in `cross_references` |
| `cross_references[]` | `person_cross_reference` | `curie` and `is_obsolete`. One live `WB:WBPerson<n>`, obsolete `WB:WBPerson<n>` for merged persons, and `ORCID:<id>` |
| `display_name.value` | `person.display_name` | the WormBase standard name. If it's missing, listed in problems; build it from the primary name |
| `names[]` | `person_name` | `first_name`, `middle_name`, `last_name`, `is_primary`. One primary; the rest are also-known-as names |
| `emails[]` | `person_email` | `email_address`, and `date_made_old_email` (null = current) |
| `institutions[]` | `person_institution` | `institution`, and `date_made_old_institution` (null = current) |
| `street_address.value` | `person.street_address` | WormBase street lines joined with newlines |
| `city` `state` `postal_code` `country` (`.value`) | same-named `person` columns | |
| (address timestamps) | `person.address_last_updated` | the latest timestamp of the address fields |
| `webpage[].value` | `person.webpage` (array) | |
| `biography_research_interest.value` | `person.biography_research_interest` | the WormBase public comments, joined with newlines |
| `notes[]` | `person_note.note` | internal curator notes, one row each |
| `active_status.value` | `person.active_status` | `deceased` or `retired`. Absent means `active` |
| `privacy.value` | `person.privacy` | `fully_hidden` for persons who asked not to be shown. Absent leaves ABC's default (`hide_email`); whether WormBase's other persons should get `show_all` is a decision for WormBase and ABC |
| `unsubscribe.value` | `person.unsubscribe` | `true` |
| `laboratories[]` | `laboratory_person` | step 3 |
| `unmapped` | not stored | see below |
| `date_created` `date_updated` | audit fields | |

`unmapped` holds WormBase data with no ABC field, each a list of value wrappers. It is exported
so ABC can decide whether to keep any of it, for example as a `person_note`. Its counts are in
`not_loaded.tsv`.

| key | what it is |
|---|---|
| `left_field` | "Left the field", "Deceased 2010" and similar. When it says deceased or retired, `active_status` is also set |
| `hide` | the reason the person asked to be hidden |
| `privacy` | mostly email addresses the person wanted kept private, a few free-text requests |
| `unable_to_contact` | "No current address available" and similar |
| `usefulwebpage` | WormBase's flag on a webpage; `value` is the webpage it flags |
| `cgc_numeric_pi` | CGC numeric PI ids (`source` two_pis or two_oldpis). These PIs have no lab code and no lab object, so there is no laboratory to attach them to |

## Step 3: laboratory_person (from person.jsonl `laboratories`)

One entry per person and laboratory:

```json
{"laboratory": "WB:EG", "is_pi": null, "former_pi": null, "alum": "2013-09-10T09:56:23.767235-07:00", "curator": "WBPerson1", "timestamp": "2013-09-10T09:56:23.767235-07:00"}
```

- Find the laboratory by its cross reference `laboratory`. A code with no lab object is listed in
  `problems.tsv`; skip that entry.
- `is_pi`, `former_pi` and `alum` are timestamps or null. Copy them as they are. WormBase only
  knows when the row was entered, not when the person became PI or left.
- An entry with all three null is a current member.
- `lab_position` is null, because WormBase doesn't record a position. `is_lab_contact` and
  `can_edit_lab` are false.

## Step 4: person_lineage.tsv

```
person_lineage_key  person_subject  person_object  relationship  start_date  end_date  date_created  date_updated  submissions
WBPerson10009|WBPerson22573|Postdoc Supervisor of  WBPerson10009  WBPerson22573  Postdoc Supervisor of  2016    2019-04-11T08:24:06.889895-07:00  2019-04-11T08:24:06.915976-07:00  2
```

- `person_subject`, `person_object`: WBPerson ids. Resolve them through `WB:WBPerson<n>`. Persons
  that were merged have already been replaced by the person they were merged into.
- `relationship`: the exact name of a `vocabulary_term_abc` term in the `person_person_relationship`
  vocabulary. The subject is the supervisor, so `A  B  PhD Supervisor of` means A supervised B's
  PhD. For `Collaborator of` (symmetric) the subject is the lower WBPerson number.
- `start_date`, `end_date`: four-digit years, or empty. WormBase stores only the year; convert to
  `YYYY-01-01` (the precision loss is in `not_loaded.tsv`). An ongoing relationship has an empty
  `end_date`.
- `date_created`, `date_updated`: earliest and latest WormBase row behind the relationship.
- `created_by`: WormBase has no record of who validated a relationship. Every row sent by a person
  was accepted once both people resolved to WBPersons. So use the import's default user; the sender
  is kept on the submissions.
- `person_lineage_key`: the line's identity, `subject|object|relationship`. Step 5 uses it to link
  submissions. It matches ABC's unique constraint, so it is unique in the file.
- `submissions`: how many submission rows point at this relationship. It is usually 2: WormBase
  stored each relationship once on each person.

## Step 5: person_lineage_submission.tsv

Every WormBase lineage row, including the mirrored copies and repeat submissions:

```
submission_id  person_subject_name  person_object_name  person_subject  person_object  relationship  who_sent_this  start_date  end_date  status  person_lineage_key  date_created  wb_joinkey  wb_number  wb_role
1     Andrew Chisholm     Ian Chin-Sang      WBPerson105  WBPerson103  Unknown Role Supervisor of  Original - Andrew Hallman    validated  WBPerson105|WBPerson103|Unknown Role Supervisor of  2003-08-21T00:00:00-07:00  two103  two105  withUnknown
1845  Katherine L. Wilson Yosef Gruenbaum                WBPerson222  Collaborator of             REV - GRU@VMSHUJIACIL  partially_resolved  2003-11-07T14:37:36.632912-08:00  two 2503  two222  Collaborated
```

| column | ABC | notes |
|---|---|---|
| `person_subject_name` `person_object_name` | same-named columns | the names as submitted, in supervisor → supervisee order |
| `person_subject` `person_object` | `person_subject_id` `person_object_id` | WBPerson ids, empty when unresolved |
| `relationship` | `relationship_vocab_term_abc_id` | as in step 4 |
| `who_sent_this` | `who_sent_this` | WormBase `two_sender` exactly as stored: an email, a name, or a curator note such as `YO from lab webpage`. `REV - ` at the start marks the mirror copy WormBase made for the other person |
| `start_date` `end_date` | same-named columns | years, as in step 4 |
| `status` | `status` | `validated` (both persons resolved), `partially_resolved` (one side), `pending` (neither), `rejected` (a relationship with oneself) |
| `person_lineage_key` | `person_lineage_id` | the step 4 row with this key. Empty unless `validated` |
| `date_created` | `date_created` | when WormBase received the row |
| `submission_id` | | line identity within this file |
| `wb_joinkey` `wb_number` `wb_role` | | the raw WormBase values, for tracing |

In `wb_joinkey` or `wb_number`, `NO` means a curator decided that person is not and won't be a
WBPerson. Those rows stay `partially_resolved`.

## Step 6: paper_author_person.tsv

Only connections verified as YES are exported, one row per author position.

```
reference  author_order  author_name  person  verified  verification_method  curator  timestamp  wb_author_id  wb_pap_join
WB:WBPaper00000003  1  Abdul Kader N  WBPerson24444  YES  Cecilia Nakamura      WBPerson1    2014-01-24T17:19:21.338866-08:00  1    1
WB:WBPaper00000088  1  Deppe U        WBPerson2515   YES  Raymond Lee  inferred lab raymond  WBPerson363  2007-03-16T15:57:30.78249-07:00   126  1
```

1. Find the reference by the cross reference in `reference`.
2. Find that reference's `author` row with `author_order`. Check that its name matches
   `author_name`. WormBase writes author names as last name and initials (`Abdul Kader N`); ABC
   may hold them differently.
3. If it matches, set `author.person_id` to the person found through `WB:<person>`.
   Set `updated_by` from `curator` and `date_updated` from `timestamp`: they say who verified
   the connection and when.
4. If the author row is missing, or the names don't match because ABC's author list has changed,
   ABC decides what to do. ABC already supports linking a person straight to a reference: an
   `author` row with `person_id` set and `author_order` null.
5. `verified` is WormBase's verification text, and `verification_method` marks the two Raymond Lee
   script inferences: `inferred lab raymond` and `inferred lineage raymond`. Empty means verified
   by a curator or by the person. ABC's `author` has no field for either; the importer decides
   whether to keep them.

`wb_author_id` and `wb_pap_join` are WormBase's keys, for tracing.

Not exported: NO verifications, possible matches that were never verified, and verifications on
papers that aren't valid. All are counted in `not_loaded.tsv` and `counts.tsv`.

## Checking the import

`counts.tsv` lists, for this run:

- `laboratory exported`
- `person exported`
- `person_lineage exported`
- `person_lineage_submission validated`, `partially_resolved`, `pending`
- `paper_author_person exported`, including the two inferred counts

After loading, ABC's counts should match, apart from rows the importer deliberately skipped. The
importer should report those skips.

## Decisions left to ABC

- Which `users` row each curator becomes, how to match persons ABC already has, the default user
  for `person_lineage.created_by`, and the default user for curators that weren't exported.
- `person.privacy` for persons WormBase didn't hide, and `laboratory.email_visibility`.
- Whether to keep any of `unmapped`, for example as `person_note`.
- What to do when an author row no longer matches `paper_author_person`.
- Whether to store `verified` and `verification_method`.
