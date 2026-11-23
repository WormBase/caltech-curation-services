import os

from sync_ack_tags import report


def test_report_files(tmp_path):
    actions = [{"action": "delete", "source": "ACKnowledge_form", "reason": "VALIDATED; stale", "curie": "AGRKB:1",
                "wb_paper": "WBPaper00000001",
                "tag": {"topic_entity_tag_id": 5, "topic": "ATP:0000027", "negated": True,
                        "validation_by_author": "validated_right"}},
               {"action": "create", "source": "ACKnowledge_form", "reason": "author set changed", "curie": "AGRKB:1",
                "wb_paper": "WBPaper00000001", "tag": {"topic": "ATP:0000027", "negated": True}}]
    problems = [("00000002", "", "no AGRKB curie")]
    report.write(str(tmp_path), actions, problems, None, "DRY RUN")
    assert sorted(os.listdir(tmp_path)) == ["actions.tsv", "affected_curies.txt", "problems.tsv", "summary.txt"]
    lines = (tmp_path / "actions.tsv").read_text().splitlines()
    assert len(lines) == 3 and "validated_right" in lines[1]
    assert (tmp_path / "affected_curies.txt").read_text() == "AGRKB:1\n"
    summary = (tmp_path / "summary.txt").read_text()
    assert "DRY RUN" in summary and "ACKnowledge_form\tATP:0000027\tdelete\t1" in summary
    assert "WBPaper00000002" in (tmp_path / "problems.tsv").read_text()


def test_report_with_results(tmp_path):
    results = [{"action": "create", "source": "ACKnowledge_form", "reason": "r", "curie": "AGRKB:1",
                "wb_paper": "WBPaper00000001", "tag": {"topic": "ATP:0000027"}, "status": "ok", "http_status": 201,
                "detail": ""}]
    report.write(str(tmp_path), results, [], results, "APPLY")
    assert (tmp_path / "results.tsv").exists()
    assert "ACKnowledge_form create ok\t1" in (tmp_path / "summary.txt").read_text()
