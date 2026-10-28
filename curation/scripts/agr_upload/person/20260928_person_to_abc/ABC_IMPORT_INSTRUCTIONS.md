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
| `person_lineage_date_conflicts.tsv` | relationships whose submissions give different years, one line each. Nothing to import: `person_lineage.tsv` has the latest submission's years and every version is in `person_lineage_submission.tsv` |
| `paper_author_person.tsv` | one verified author → person connection per line |
| `paper_author_corresponding.tsv` | one corresponding author per line, by paper and author order |
| `counts.tsv` | how many rows were exported or skipped, to check the import against |
| `not_loaded.tsv` | WormBase data ABC can't hold: what it is, how many rows, and whether it is in the files |
| `problems.tsv` | row-level issues that still need addressing before the final export, with a summary at the top |
| `problems_accounted_for.tsv` | row-level issues WormBase has reviewed and agreed to, so nothing more is needed. Same format |
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
- `person_lineage` and `person_lineage_submission` use `WBPerson1` and `wormbase_initial_import`; see steps 4 and 5.

## Before loading

1. **Resolve `problems.tsv`.** Problems come in two files, both with a commented summary at the
   top giving, for each kind of problem, its severity, file, count and why it matters:
   - `problems.tsv`: what still needs addressing.
     - `blocks import`: ABC will reject the rows.
     - `fix or importer default`: the importer has to supply a value if WormBase doesn't fix it.
     - `curator review`: a WormBase curator still has to look at these.
     - `info`: already handled by the exporter, listed so nothing changes silently.
   - `problems_accounted_for.tsv`: problems WormBase has reviewed and agreed to (severity
     `accounted for`), for example verified and corresponding authors no longer on any paper, merged persons replaced
     by the person they were merged into, and lineage years where the latest submission was kept.
     Nothing more is needed; they are listed so nothing changes silently.

   WormBase curators fix problems in WormBase and then re-run the export. The `blocks import` ones,
   which must all be zero for the final transfer, are:
   - **paper_author_person: same person on more than one author position.** ABC has a unique
     index on (reference_id, person_id), so this must be zero.
   - **paper_author_person: author id on more than one paper.** A WormBase author id is one author
     position on one paper, so these are broken WormBase data, and the verified person would be
     connected to every paper the id is on. WormBase fixes `pap_author` first.
   - **person: ORCID on more than one person, and more than one ORCID on a person.** ABC has unique
     indexes on the live (non-obsolete) `curie`, and on (person_id, curie_prefix).
   - **person_lineage_submission: no two_sender.** ABC requires `who_sent_this`.
   - **person: no last name.** ABC requires `person_name.last_name`.

   Everything else in `problems.tsv` is for WormBase curators or the importer, with the reason.
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
| 7 | `paper_author_corresponding.tsv` | author.corresponding_author | WormBase references already in ABC |

Steps 2 and 3 can share one pass over `person.jsonl`, since all laboratories exist after step 1.

## Step 1: laboratory.jsonl

Only labs that are Valid in WormBase are exported, with status `active`.

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
| `emails[]` | `person_email` | `email_address`, and `date_made_old_email` (null = current). Includes the addresses WormBase kept private (`two_privacy`); those persons have `privacy` `hide_email` |
| `institutions[]` | `person_institution` | `institution`, and `date_made_old_institution` (null = current) |
| `street_address.value` | `person.street_address` | WormBase street lines joined with newlines |
| `city` `state` `postal_code` `country` (`.value`) | same-named `person` columns | |
| (address timestamps) | `person.address_last_updated` | the latest timestamp of the address fields |
| `webpage[].value` | `person.webpage` (array) | |
| `biography_research_interest.value` | `person.biography_research_interest` | the WormBase public comments, joined with newlines |
| `notes[]` | `person_note.note` | internal notes, one row each: curator comments, the reason a person asked to be hidden, and the left-the-field text (`Not in Worm Field`, or the text as written, e.g. `Now in a fly lab`, `Deceased June 23, 2009`) |
| `active_status.value` | `person.active_status` | `deceased` or `retired`, from WormBase's left-the-field text. Absent means `active` |
| `privacy.value` | `person.privacy` | `fully_hidden` for persons who asked not to be shown, `hide_email` for persons with private email addresses. **Absent means `show_all`**: set it explicitly, since ABC's default is `hide_email` |
| `unsubscribe.value` | `person.unsubscribe` | `true` |
| `laboratories[]` | `laboratory_person` | step 3 |
| `date_created` `date_updated` | audit fields | |

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
person_lineage_key  person_subject  person_object  relationship  start_date  end_date  created_by  date_created  date_updated  submissions
WBPerson10009|WBPerson22573|Postdoc Supervisor of  WBPerson10009  WBPerson22573  Postdoc Supervisor of  2016-01-01    WBPerson1  2019-04-11T08:24:06.889895-07:00  2019-04-11T08:24:06.915976-07:00  2
```

- `person_subject`, `person_object`: WBPerson ids. Resolve them through `WB:WBPerson<n>`. Persons
  that were merged have already been replaced by the person they were merged into.
- `relationship`: the exact name of a `vocabulary_term_abc` term in the `person_person_relationship`
  vocabulary. The subject is the supervisor, so `A  B  PhD Supervisor of` means A supervised B's
  PhD. For `Collaborator of` (symmetric) the subject is the lower WBPerson number.
- `start_date`, `end_date`: dates, `YYYY-MM-DD`, or empty. WormBase stores years, so a year is
  sent as January 1st (`2016-01-01`) and a year and month as the 1st of the month. Text that can't
  be read as a date is left empty and listed in `problems.tsv`; the fields are optional. An
  ongoing relationship has an empty `end_date`.
- `date_created`, `date_updated`: earliest and latest WormBase row behind the relationship.
- `created_by`: always `WBPerson1`, Cecilia Nakamura. A script connects the submitted names to
  WBPersons and Cecilia verifies the connections, so she validated every relationship. WormBase
  doesn't record when, so `date_created` is the first submission's time. Who sent each claim is on
  the submissions (`who_sent_this`).
- `person_lineage_key`: the line's identity, `subject|object|relationship`. Step 5 uses it to link
  submissions. It matches ABC's unique constraint, so it is unique in the file.
- `submissions`: how many submission rows point at this relationship. It is usually 2: WormBase
  stored each relationship once on each person.

## Step 5: person_lineage_submission.tsv

Every WormBase lineage row, including the mirrored copies and repeat submissions:

```
submission_id  person_subject_name  person_object_name  person_subject  person_object  relationship  who_sent_this  start_date  end_date  status  created_by  updated_by  person_lineage_key  date_created  wb_joinkey  wb_number  wb_role
1     Andrew Chisholm     Ian Chin-Sang      WBPerson105  WBPerson103  Unknown Role Supervisor of  Original - Andrew Hallman    validated  wormbase_initial_import  WBPerson1  WBPerson105|WBPerson103|Unknown Role Supervisor of  2003-08-21T00:00:00-07:00  two103  two105  withUnknown
```

| column | ABC | notes |
|---|---|---|
| `person_subject_name` `person_object_name` | same-named columns | the names as submitted, in supervisor → supervisee order |
| `person_subject` `person_object` | `person_subject_id` `person_object_id` | WBPerson ids, empty when unresolved |
| `relationship` | `relationship_vocab_term_abc_id` | as in step 4 |
| `who_sent_this` | `who_sent_this` | WormBase `two_sender` exactly as stored: an email, a name, or a curator note such as `YO from lab webpage`. `REV - ` at the start marks the mirror copy WormBase made for the other person |
| `start_date` `end_date` | same-named columns | dates, as in step 4 |
| `status` | `status` | `validated` (both persons resolved), `rejected` (a curator set one side to `NO`, or a relationship with oneself), `partially_resolved` (one side), `pending` (neither) |
| `created_by` | `created_by` | always `wormbase_initial_import`, an automation user for this load. Who sent the claim is `who_sent_this` |
| `updated_by` | `updated_by` | `WBPerson1` (Cecilia) on `validated` rows and on `rejected` rows with a `NO`: she does every validation and rejection. `wormbase_initial_import` otherwise |
| `person_lineage_key` | `person_lineage_id` | the step 4 row with this key. Empty unless `validated` |
| `date_created` | `date_created` | when WormBase received the row |
| `submission_id` | | line identity within this file |
| `wb_joinkey` `wb_number` `wb_role` | | the raw WormBase values, for tracing |

In `wb_joinkey` or `wb_number`, `NO` means a curator decided that person is not and won't be a
WBPerson. Those rows are `rejected`, and the other side is still filled in when it is a WBPerson.

`partially_resolved` and `pending` rows are submissions WormBase curators had not finished: a
submitted name was never connected to a WBPerson, nor marked `NO`. They are not problems. Load
them with that status, so they arrive in ABC as submissions that still need a curator to resolve
them, the same as a new submission would.

## Step 6: paper_author_person.tsv

Only connections verified as YES are exported, one row per author position.

```
reference  author_order  author_name  person  verified  verification_method  created_by  curator  timestamp  wb_author_id  wb_pap_join
WB:WBPaper00000003  1  Abdul Kader N  WBPerson24444  YES  Cecilia Nakamura                        WBPerson1                 WBPerson1    2014-01-24T17:19:21.338866-08:00  1    1
WB:WBPaper00000088  1  Deppe U        WBPerson2515   YES  Raymond Lee  inferred lab raymond  automated_via_person_laboratory  WBPerson363  2007-03-16T15:57:30.78249-07:00   126  1
```

1. Find the reference by the cross reference in `reference`.
2. Find that reference's `author` row with `author_order`. Check that its name matches
   `author_name`. WormBase writes author names as last name and initials (`Abdul Kader N`); ABC
   may hold them differently.
3. If it matches, set `author.person_id` to the person found through `WB:<person>`.
   Set the connection's `created_by` from `created_by` and its date from `timestamp`:
   - `automated_via_person_laboratory` and `automated_via_person_lineage`: the two Raymond Lee script inferences,
     from lab membership and from lineage. These are automation users.
   - the author's own WBPerson, when the person verified their own paper.
   - otherwise the curator who verified it, almost always Cecilia (`WBPerson1`).

   `curator` is the WormBase curator on the row, for tracing.
4. If the author row is missing, or the names don't match because ABC's author list has changed,
   connect the person directly to the reference: an `author` row with `person_id` set and
   `author_order` null. The connection is never dropped.
5. `verified` is WormBase's verification text, and `verification_method` marks the two Raymond Lee
   script inferences: `inferred lab raymond` and `inferred lineage raymond`. Empty means verified
   by a curator or by the person. ABC's `author` has no field for either; `created_by` carries the
   difference.

`wb_author_id` and `wb_pap_join` are WormBase's keys, for tracing.

Not exported: NO verifications, possible matches that were never verified, and verifications on
papers that aren't valid. All are counted in `not_loaded.tsv` and `counts.tsv`.

## Step 7: paper_author_corresponding.tsv

```
reference  author_order  author_name  corresponding_author  curator  timestamp  wb_author_id
```

1. Find the reference by `reference`, and its `author` row with `author_order`. Check that the
   name matches `author_name`, as in step 6.
2. If it matches, set `author.corresponding_author` to true, with `updated_by` from `curator` and
   `date_updated` from `timestamp`.
3. If the author row is missing or the name doesn't match, don't set it. **Write the line to a
   report and send it back to WormBase**, so a curator can find the right author.

WormBase has no first author flag: the first author is author order 1, which ABC already has.


## Checking the import

`counts.tsv` lists, for this run:

- `laboratory exported`
- `person exported`
- `person_lineage exported`
- `person_lineage_submission validated`, `rejected`, `partially_resolved`, `pending`
- `paper_author_person exported`, including the two inferred counts
- `paper_author_corresponding exported`

After loading, ABC's counts should match, apart from rows the importer deliberately skipped. The
importer should report those skips.

## Not sent, approved by WormBase

WormBase has reviewed this data and agreed it does not need to reach ABC as it is. Each item is
also a row in `not_loaded.tsv`, with `approved` saying who agreed and when.

| WormBase data | what happens | approved |
|---|---|---|
| `two_unable_to_contact` | not sent | Cecilia, 2026-10-22 |
| `two_usefulwebpage`, a curator checkbox on a webpage | not sent; the webpage itself is sent | Cecilia, 2026-10-22 |
| CGC numeric PI ids in `two_pis` and `two_oldpis` | not sent; PIs with a lab code are sent | Cecilia, 2026-10-22 |
| curator and timestamp of each `two_wormbase_comment` and `two_street` line | the text is all sent, joined into one ABC value with the latest curator and timestamp | Cecilia, 2026-10-22 |
| Invalid persons that were not merged | not sent; checked, and correct as they are | Cecilia, 2026-10-22 |
| possible author matches never verified | not sent; ABC cannot hold a possible match | Cecilia, 2026-10-22 |
| NO author verifications | not sent; ABC cannot hold a NO | Cecilia, 2026-10-22 |
| who proposed an author match, and when | not sent, not important | Cecilia, 2026-10-22 |
| author verification method | resolved: sent as `verification_method` and as `created_by` (`automated_via_person_laboratory`, `automated_via_person_lineage`) | Cecilia, 2026-10-22 |
| the exact wording of "Left the field", "Not in the field" and their typos | sent as the note `Not in Worm Field` | Cecilia, 2026-10-22 |
| phone and fax numbers (`two_mainphone`, `two_labphone`, `two_officephone`, `two_otherphone`, `two_fax`, `lab_phone`, `lab_fax`) | not sent | Cecilia, 2026-10-22 |
| `two_contactdata`, contact attempt notes | not sent | Cecilia, 2026-10-22 |
| `two_paper`, the legacy person paper list | not sent | Cecilia, 2026-10-22 |
| `two_curator_ip`, `two_user_ip`, form ip addresses | not sent | WormBase Caltech call, 2026-10-22 |
| `frm_email_skip`, `frm_wbperson_skip`, form mailing skip lists | not sent | WormBase Caltech call, 2026-10-22 |
| `frm_ip_block`, `frm_user_save`, form ip blocks and saved input | not sent | WormBase Caltech call, 2026-10-22 |
| `pap_author_sent`, log of author verification emails sent | not sent | Cecilia, 2026-10-22 |
| verified author connections whose author id is on no paper | not sent: the author was removed from the paper after it was verified, and Cecilia couldn't place them | Cecilia, 2026-10-22 |
| corresponding authors whose author id is on no paper | not sent: the author was removed from the paper after it was marked corresponding | Kimberly and Cecilia, 2026-10-23 |
| Raymond Lee lab or lineage inferences onto a person who is Invalid and not merged | not sent, since the person isn't sent | Cecilia, 2026-10-23 |
| `two_fullname`, a legacy full name table | not sent; the names come from the first, middle and last name tables | Cecilia, 2026-10-22 |
| edit history tables (`h_two_*`, `lab_*_hst`, `h_pap_*`) | not sent; the current values are sent with their curator and timestamp | Juancarlos, 2026-10-22 |
| when Cecilia verified each lineage relationship | can't be tracked: WormBase doesn't record it. `date_created` is the first submission's time | Juancarlos, 2026-10-22 |
| the character repairs in `character_fixes.tsv` | sent repaired | Cecilia, 2026-10-22 |

## Decisions left to ABC

- Which `users` row each curator becomes, how to match persons ABC already has, and the default
  user for curators that weren't exported.
- `laboratory.email_visibility`.
- What to do when an author row no longer matches `paper_author_person`.
