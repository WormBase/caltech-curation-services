from sync_ack_tags.__main__ import apply, plan_paper, select_papers
from sync_ack_tags.caltech import Row
from sync_ack_tags.tests.conftest import make_data

PAPER, CURIE = "00000001", "AGRKB:101000000000001"


def data_with_strain_rows():
    return make_data(valid={PAPER, "00000002"}, agrkb={PAPER: CURIE}, ack_papers={PAPER},
                     tables={"tfp_strain": {PAPER: Row("", "2024-01-01T00:00:00")},
                             "afp_strain": {PAPER: Row("", "2024-02-01T00:00:00")},
                             "afp_rnai": {"00000002": Row("x", "2024-02-01T00:00:00")}})


def test_select_papers_reports_missing_curies():
    papers, problems = select_papers(data_with_strain_rows(), None)
    assert papers == {PAPER: CURIE}
    assert problems == [("00000002", "", "no AGRKB curie")]
    assert select_papers(data_with_strain_rows(), {"00000009"}) == ({}, [])


def test_select_papers_looks_up_missing_curies_in_the_abc():
    lookups = []

    def lookup(xref):
        lookups.append(xref)
        return "AGRKB:101000000000002"

    papers, problems = select_papers(data_with_strain_rows(), None, lookup)
    assert papers == {PAPER: CURIE, "00000002": "AGRKB:101000000000002"} and problems == []
    assert lookups == ["WB:WBPaper00000002"]


def test_plan_paper_respects_the_cutoff():
    data = data_with_strain_rows()
    actions, _ = plan_paper(PAPER, CURIE, data, [], cutoff="2023-01-01")
    assert {a["source"] for a in actions} == {"ACKnowledge_form"}
    actions, _ = plan_paper(PAPER, CURIE, data, [], cutoff=None)
    assert {a["source"] for a in actions} == {"ACKnowledge_form", "ACKnowledge_pipeline"}
    assert all(a["wb_paper"] == "WBPaper" + PAPER and a["curie"] == CURIE for a in actions)


def test_plan_paper_matching_tags_give_no_actions():
    data = data_with_strain_rows()
    existing = [
        {"topic_entity_tag_id": 1, "topic": "ATP:0000027", "negated": True, "data_novelty": "ATP:0000334",
         "tag_source": {"source_method": "ACKnowledge_pipeline"}, "created_by": "ACKnowledge_pipeline"},
        {"topic_entity_tag_id": 2, "topic": "ATP:0000027", "negated": True, "data_novelty": "ATP:0000334",
         "tag_source": {"source_method": "ACKnowledge_form"}, "created_by": "unknown_author"}]
    assert plan_paper(PAPER, CURIE, data, existing, cutoff=None) == ([], [])


class FakeAbc:
    def __init__(self, fail_on=None):
        self.calls = []
        self.fail_on = fail_on

    def delete(self, tag_id):
        self.calls.append(("delete", tag_id))
        return ("error", 500, "boom") if tag_id == self.fail_on else ("ok", 204, "")

    def update_note(self, tag, note):
        self.calls.append(("update", tag["topic_entity_tag_id"]))
        return "ok", 200, ""

    def create(self, tag):
        self.calls.append(("create", tag["n"]))
        return "ok", 201, ""


def action(kind, curie, n):
    tag = {"n": n} if kind == "create" else {"topic_entity_tag_id": n}
    return {"action": kind, "new_note": "", "source": "ACKnowledge_form", "reason": "r", "tag": tag, "curie": curie,
            "wb_paper": "WBPaper" + curie[-8:]}


def test_parallel_apply_keeps_each_papers_order_and_the_result_order():
    actions = [action("create", f"AGRKB:{n}", n) for n in range(1, 30)] + \
        [action("delete", f"AGRKB:{n}", 100 + n) for n in range(1, 30)]
    abc = FakeAbc()
    results = apply(abc, actions, workers=4)
    assert len(results) == len(actions) and all(r["status"] == "ok" for r in results)
    assert [r["curie"] for r in results] == [c for n in range(1, 30) for c in (f"AGRKB:{n}",) * 2]
    for n in range(1, 30):
        assert abc.calls.index(("delete", 100 + n)) < abc.calls.index(("create", n))


def test_apply_deletes_first_and_stops_a_paper_on_error():
    actions = [action("create", "AGRKB:1", 1), action("delete", "AGRKB:1", 10), action("delete", "AGRKB:1", 11),
               action("create", "AGRKB:2", 2), action("delete", "AGRKB:2", 20)]
    abc = FakeAbc(fail_on=10)
    results = apply(abc, actions)
    assert abc.calls == [("delete", 10), ("delete", 20), ("create", 2)]
    assert [r["status"] for r in results] == ["error", "not run", "not run", "ok", "ok"]


def test_apply_runs_deletes_then_note_updates_then_creates():
    actions = [action("create", "AGRKB:1", 1), action("update", "AGRKB:1", 30), action("delete", "AGRKB:1", 10)]
    abc = FakeAbc()
    apply(abc, actions)
    assert abc.calls == [("delete", 10), ("update", 30), ("create", 1)]
