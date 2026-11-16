# sync_ack_tags (SCRUM-6598)

Makes the ABC's ACKnowledge tags (`ACKnowledge_pipeline`, `ACKnowledge_form`) match the Caltech tables. It replaces
the one-off Perl upload scripts for these two sources until ACKnowledge reads and writes the ABC directly, and is
deleted after that switch. It also writes negated `paper_editor_genes_curator`/`paper_editor_species` tags (see
below), but never changes or deletes the paper editor's own tags. Tags of every other source are never read, changed or
deleted.

- **Pipeline tags** (papers the Caltech pipeline processed): one tag per pre-populated entity from `tfp_*`, a
  negated "none found" tag for an empty `tfp_*` row, and one classification tag per pre-checked data type from
  `cur_blackbox`. Compared tag by tag: missing tags are created, stale ones deleted, duplicates left alone.
- **Author tags** (every ACKnowledge submission, final or partial): the entities, "other" answers and data-type
  flags of `afp_*`, as entered, one set per contributor in `afp_contributor` (`unknown_author` if none). Compared tag by tag as well (notes count
  for topic-only tags), so unchanged tags keep their ids and validations; exact duplicates are left alone.
- **Curator removals**: an author gene or species a curator removed in the paper editor (an `h_pap_gene` /
  `h_pap_species` row with no value at the author entry's `pap_order`) and that is not back in `pap_gene` /
  `pap_species` gets a negated tag of the paper editor source, by that curator on the date of the removal, as long as
  the author's `afp_*` answer still has it. A removal that only corrected an id gets none: the author's species name
  already resolves to the curator's taxon. These tags carry the note `author entry removed by a curator in the paper
  editor`, or `As a result of a merge, author entry removed by a curator in the paper editor` on the papers a curator
  confirmed as gene or taxon merges (`MERGE_REMOVALS` in `constants.py`). Only tags with one of these two notes are
  ever deleted from the paper editor sources, and a tag whose note changed is replaced.
- Entity tags of a topic whose values did not all resolve (see `problems.tsv`) are never deleted.

A paper whose Caltech data has not changed since it was imported gets no actions.

## Setup (caltech-curation host)

```bash
cd curation/scripts/agr_upload/pap_papers
python3 -m venv ~/venvs/sync_ack_tags && . ~/venvs/sync_ack_tags/bin/activate
pip install -r sync_ack_tags/requirements.txt
set -a; . /usr/lib/.env; set +a        # PSQL_* (Caltech DB, opened read only)
export COGNITO_ADMIN_CLIENT_ID=... COGNITO_ADMIN_CLIENT_SECRET=... COGNITO_TOKEN_URL=...
```

`API_SERVER` defaults to production (`literature-rest.alliancegenome.org`); use
`API_SERVER=stage-literature-rest.alliancegenome.org` for stage.

## Run

```bash
python3 -m sync_ack_tags --out-dir dry_run                       # dry run, everything
python3 -m sync_ack_tags --papers WBPaper00068690 --out-dir one  # dry run, some papers
python3 -m sync_ack_tags --apply --out-dir applied               # make the changes (--workers N: papers in
                                                                 # parallel, default 6)
python3 -m sync_ack_tags --pipeline-cutoff 2026-11-01 ...        # after the ABC-based pipeline release: leave the
                                                                 # pipeline tags of later papers alone
```

Report files in `--out-dir`:

- `actions.tsv`: every delete and create, with its reason; deletes carry the tag's id and validation values, and a
  `VALIDATED; ` prefix when a curator or an author had validated it
- `problems.tsv`: papers without an AGRKB curie (in `pap_identifier` or, by `WB:WBPaper…`, in the ABC),
  unresolved names, entities without a taxon
- `results.tsv` (`--apply`): the status of every action; a paper stops at its first error and the next run fixes it
- `summary.txt`: counts per source, topic and action (and per result status)
- `affected_curies.txt`: the references the actions touch (for review)

## Procedure

1. Dry run; read `summary.txt` and check `actions.tsv` (review the production dry run with the curators).
2. `--apply`. No separate revalidation is needed: the ABC API validates each created tag on insert and revalidates
   the reference on each delete.
3. Dry run again: it must report no actions.

## Tests

```bash
cd curation/scripts/agr_upload/pap_papers && python3 -m pytest sync_ack_tags/tests -q
```

The tests never touch a database or the network.
