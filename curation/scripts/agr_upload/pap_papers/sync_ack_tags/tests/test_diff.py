from sync_ack_tags.diff import diff_author, diff_pipeline
from sync_ack_tags.tags import make_tag

PIPE = {"source_method": "ACKnowledge_pipeline", "created_by": "ACKnowledge_pipeline"}


def abc(tag_id, **fields):
    method = fields.pop("method", "ACKnowledge_pipeline")
    return dict(fields, topic_entity_tag_id=tag_id, tag_source={"source_method": method})


def expected(**fields):
    return make_tag(**dict(PIPE, **fields))


NEG_STRAIN = {"topic": "ATP:0000027", "negated": True, "data_novelty": "ATP:0000334"}


def test_pipeline_duplicates_are_left_alone():
    existing = [abc(1, **NEG_STRAIN), abc(2, **NEG_STRAIN)]
    assert diff_pipeline([expected(**NEG_STRAIN)], existing) == []


def test_pipeline_stale_and_missing():
    gene = {"topic": "ATP:0000005", "entity_type": "ATP:0000005", "entity": "WB:WBGene1", "negated": False,
            "data_novelty": "ATP:0000334", "species": "NCBITaxon:6239"}
    actions = diff_pipeline([expected(**gene)], [abc(1, **NEG_STRAIN)])
    assert [(a["action"], a["reason"]) for a in actions] == [("delete", "stale"), ("create", "missing")]
    assert actions[0]["tag"]["topic_entity_tag_id"] == 1


def test_pipeline_equal_sets():
    assert diff_pipeline([expected(**NEG_STRAIN)], [abc(1, **NEG_STRAIN, created_by="x", note="n")]) == []


def author(who, **fields):
    return make_tag(source_method="ACKnowledge_form", created_by=who, **fields)


def abc_author(tag_id, who, **fields):
    return abc(tag_id, method="ACKnowledge_form", created_by=who, **fields)


def test_author_equal_sets_in_any_order():
    exp = [author("WBPerson1", **NEG_STRAIN), author("WBPerson1", topic="ATP:0000082", negated=False,
                                                     data_novelty="ATP:0000335")]
    existing = [abc_author(2, "WBPerson1", topic="ATP:0000082", negated=False, data_novelty="ATP:0000335"),
                abc_author(1, "WBPerson1", **NEG_STRAIN)]
    assert diff_author(exp, existing) == []


def test_author_added_tag_is_only_created():
    exp = [author("WBPerson1", **NEG_STRAIN), author("WBPerson2", **NEG_STRAIN)]
    existing = [abc_author(1, "WBPerson1", **NEG_STRAIN)]
    actions = diff_author(exp, existing)
    assert [(a["action"], a["reason"], a["tag"]["created_by"]) for a in actions] == [
        ("create", "missing", "WBPerson2")]


def test_author_changed_tag_is_replaced_and_the_rest_kept():
    flag = {"topic": "ATP:0000082", "negated": False, "data_novelty": "ATP:0000335"}
    exp = [author("WBPerson1", **NEG_STRAIN), author("WBPerson1", **dict(flag, negated=True))]
    existing = [abc_author(1, "WBPerson1", **NEG_STRAIN), abc_author(2, "WBPerson1", **flag)]
    actions = diff_author(exp, existing)
    assert [(a["action"], a["reason"]) for a in actions] == [("delete", "stale"), ("create", "missing")]
    assert actions[0]["tag"]["topic_entity_tag_id"] == 2


def test_author_extra_copy_is_left_alone():
    existing = [abc_author(1, "WBPerson1", **NEG_STRAIN), abc_author(2, "WBPerson1", **NEG_STRAIN)]
    assert diff_author([author("WBPerson1", **NEG_STRAIN)], existing) == []


def test_author_no_data_deletes_everything():
    actions = diff_author([], [abc_author(1, "unknown_author", **NEG_STRAIN)])
    assert [(a["action"], a["reason"]) for a in actions] == [("delete", "no ACKnowledge author data")]


def test_validated_deletes_are_flagged():
    stale = abc(1, **NEG_STRAIN, validation_by_professional_biocurator="validated_right")
    actions = diff_pipeline([], [stale])
    assert actions[0]["reason"] == "VALIDATED; stale"
    author_stale = abc_author(1, "WBPerson1", **NEG_STRAIN, validation_by_author="validated_wrong")
    assert diff_author([], [author_stale])[0]["reason"].startswith("VALIDATED; ")
