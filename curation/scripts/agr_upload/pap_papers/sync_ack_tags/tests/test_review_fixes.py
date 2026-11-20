"""Tests for the final-review findings (C1, I1-I5)."""
from datetime import datetime, timezone

import pytest

from sync_ack_tags.__main__ import check_created_by, plan_paper
from sync_ack_tags.abc_client import Abc
from sync_ack_tags.author import author_tags
from sync_ack_tags.caltech import Row, build_data, load
from sync_ack_tags.diff import diff_pipeline
from sync_ack_tags.pipeline import pipeline_tags
from sync_ack_tags.tags import ALLOWED_CREATE_FIELDS, author_key, make_tag
from sync_ack_tags.tests.conftest import make_data

ELEGANS = "NCBITaxon:6239"
PAPER, CURIE = "00000001", "AGRKB:101000000000001"
TS = "2024-01-01T00:00:00"


def rich_data():
    return make_data(
        ack_papers={PAPER}, agrkb={PAPER: CURIE}, valid={PAPER},
        tables={"tfp_variation": {PAPER: Row("WBVar1;%;e1", TS)},
                "afp_variation": {PAPER: Row("WBVar1;%;e1", TS)},
                "afp_othervariation": {PAPER: Row('[{"id":1,"name":"x"}]', TS)},
                "tfp_transgene": {PAPER: Row("WBTransgene1;%;oxEx1", TS)},
                "afp_rnai": {PAPER: Row("yes", TS)}},
        variation_taxon={"WB:WBVar1": ELEGANS}, blackbox={PAPER: {"rnai": "HIGH"}})


# C1: the ABC rejects unknown fields (extra='forbid'); entity_published_as was removed in SCRUM-4218
def test_expected_tags_only_use_fields_the_abc_accepts():
    data = rich_data()
    tags = pipeline_tags(PAPER, CURIE, data)[0] + author_tags(PAPER, CURIE, data)[0]
    assert tags
    for tag in tags:
        assert set(tag) - {"source_method"} <= ALLOWED_CREATE_FIELDS, set(tag) - ALLOWED_CREATE_FIELDS


def test_create_refuses_unknown_fields_without_calling_the_abc():
    class NoCalls:
        def request(self, *args, **kwargs):
            raise AssertionError("no request expected")

    abc = Abc("abc.example.org", session=NoCalls(), token_fn=lambda: "t")
    abc.source_ids["ACKnowledge_form"] = 1
    status, http_status, detail = abc.create({"source_method": "ACKnowledge_form", "entity_published_as": "x"})
    assert (status, http_status) == ("error", 0) and "entity_published_as" in detail


# I1: only real validations are flagged
def test_validation_flag_values():
    neg = {"topic": "ATP:0000027", "negated": True, "data_novelty": "ATP:0000334"}

    def reason(value):
        tag = dict(neg, topic_entity_tag_id=1, tag_source={"source_method": "ACKnowledge_pipeline"},
                   validation_by_author=value)
        return diff_pipeline([], [tag])[0]["reason"]

    assert reason("validation_conflict").startswith("VALIDATED; ")
    assert reason("validated_wrong").startswith("VALIDATED; ")
    assert reason("validated_right_self") == "stale"


# I2: a lookup gap must not delete tags
def pipeline_abc_tag(tag_id, entity):
    return {"topic_entity_tag_id": tag_id, "topic": "ATP:0000027", "entity_type": "ATP:0000027", "entity": entity,
            "species": ELEGANS, "negated": False, "data_novelty": "ATP:0000334",
            "tag_source": {"source_method": "ACKnowledge_pipeline"}, "created_by": "ACKnowledge_pipeline"}


def test_entity_tags_of_a_topic_with_lookup_problems_are_not_deleted():
    data = make_data(tables={"tfp_strain": {PAPER: Row("WBStrain9;%;x", TS)}})  # no taxon for WBStrain9
    actions, problems = plan_paper(PAPER, CURIE, data, [pipeline_abc_tag(1, "WB:WBStrain9")], cutoff=None)
    assert [a for a in actions if a["action"] == "delete"] == []
    assert problems and "WBStrain9" in problems[0][2]


def test_unresolved_author_items_skip_the_removed_negations():
    data = make_data(ack_papers={PAPER}, strain_taxon={"WB:WBStrain1": ELEGANS},
                     tables={"afp_strain": {PAPER: Row("unknown strain name", TS)},
                             "tfp_strain": {PAPER: Row("WBStrain1;%;N2", TS)}})
    tags, problems = author_tags(PAPER, CURIE, data)
    assert [t for t in tags if t.get("entity")] == []
    assert problems


def test_load_uses_one_read_only_snapshot():
    calls = []

    class Cursor:
        def execute(self, sql):
            pass

        def fetchall(self):
            return []

        def close(self):
            pass

    class Conn:
        def set_session(self, **kwargs):
            calls.append(kwargs)

        def cursor(self):
            return Cursor()

    load(Conn())
    assert calls == [{"readonly": True, "isolation_level": "REPEATABLE READ"}]


# I3: the paper's own blackbox rows win over a merged paper's later rows
def test_blackbox_own_rows_win():
    t0, t1 = datetime(2024, 1, 1, tzinfo=timezone.utc), datetime(2024, 6, 1, tzinfo=timezone.utc)
    data = build_data({"valid": [(PAPER,)], "merges": [(PAPER, "00000002")],
                       "blackbox": [(PAPER, "rnai", "HIGH", t0), ("00000002", "rnai", "NEG", t1)]})
    assert data.blackbox == {PAPER: {"rnai": "HIGH"}}


# I4: changed notes of topic-only author tags are synced
def test_author_key_compares_notes_of_topic_only_tags():
    base = {"source_method": "ACKnowledge_form", "created_by": "WBPerson1", "topic": "ATP:0000082",
            "negated": False, "data_novelty": "ATP:0000335"}
    assert author_key(make_tag(**base, note="old")) != author_key(make_tag(**base, note="new"))
    entity = dict(base, topic="ATP:0000005", entity_type="ATP:0000005", entity="WB:WBGene1")
    assert author_key(make_tag(**entity, note="old")) == author_key(make_tag(**entity, note="new"))


# I5: stop when the ABC returns created_by in another form than the sync writes
def test_check_created_by():
    check_created_by({"c": [{"created_by": "WBPerson12", "tag_source": {"source_method": "ACKnowledge_form"}},
                            {"created_by": "unknown_author", "tag_source": {"source_method": "ACKnowledge_form"}},
                            # a broken id (141 prod tags on 5 papers): replaced as stale, not a format change
                            {"created_by": "WBPersonundefined", "tag_source": {"source_method": "ACKnowledge_form"}},
                            {"created_by": "ACKnowledge_pipeline",
                             "tag_source": {"source_method": "ACKnowledge_pipeline"}}]})
    with pytest.raises(SystemExit):
        check_created_by({"c": [{"created_by": "Jane Doe", "tag_source": {"source_method": "ACKnowledge_form"}}]})


def test_other_answer_note_is_the_raw_names_as_perl_wrote_them():
    from sync_ack_tags.entities import other_note
    raw = '[{"id":1,"name":"PS7518  plg-1 V "},{"id":2,"name":"IG356\\tdaf-2"},{"id":3,"name":""}]'
    assert other_note(raw) == 'PS7518  plg-1 V \nIG356\\tdaf-2\n'  # empty names too, as Perl
