import requests

from sync_ack_tags.abc_client import Abc


class Response:
    def __init__(self, status_code, payload=None, text=""):
        self.status_code = status_code
        self._payload = payload
        self.text = text

    def json(self):
        return self._payload


class Session:
    """records calls and answers from a queue of responses (or exceptions)"""

    def __init__(self, responses):
        self.responses = list(responses)
        self.calls = []

    def request(self, method, url, headers=None, json=None, timeout=None):
        self.calls.append((method, url, json, headers))
        answer = self.responses.pop(0)
        if isinstance(answer, Exception):
            raise answer
        return answer


def tokens():
    counter = iter(range(100))
    return lambda: f"token{next(counter)}"


def make(responses):
    session = Session(responses)
    return Abc("abc.example.org", session=session, token_fn=tokens()), session


def test_tags_are_fetched_in_batches_of_100():
    abc, session = make([Response(200, {"tags": {f"c{i}": []}}) for i in range(3)])
    result = abc.tags([f"c{i}" for i in range(250)])
    posts = [call for call in session.calls if call[0] == "POST"]
    assert [len(call[2]["curies_or_reference_ids"]) for call in posts] == [100, 100, 50]
    assert posts[0][2]["filters"] == {"source_methods": ["ACKnowledge_pipeline", "ACKnowledge_form",
                                                         "paper_editor_genes_curator", "paper_editor_species"]}
    assert set(result) == {"c0", "c1", "c2"}


def test_401_refreshes_the_token_once():
    abc, session = make([Response(401), Response(200, {"tags": {"c1": [{"topic": "x"}]}})])
    assert abc.tags(["c1"]) == {"c1": [{"topic": "x"}]}
    assert session.calls[0][3]["Authorization"] != session.calls[1][3]["Authorization"]


def test_create_sends_the_tag_source_id_and_reports_duplicates():
    abc, session = make([Response(200, {"tag_source_id": 159}), Response(409, text='{"reason":"duplicate"}')])
    status = abc.create({"source_method": "ACKnowledge_pipeline", "topic": "ATP:0000005"})
    assert status == ("exists", 409, "")
    sent = session.calls[1][2]
    assert sent["tag_source_id"] == 159 and "source_method" not in sent
    assert session.calls[0][1].endswith("/tag_source/ECO:0008021/ACKnowledge_pipeline/WB/WB")


def test_source_ids_are_cached():
    abc, session = make([Response(200, {"tag_source_id": 159}), Response(201, text="1"), Response(201, text="2")])
    abc.create({"source_method": "ACKnowledge_pipeline"})
    abc.create({"source_method": "ACKnowledge_pipeline"})
    assert len(session.calls) == 3


def test_errors_are_returned_not_raised():
    abc, _ = make([Response(500, text="x" * 600), requests.ConnectionError("down")])
    status, http_status, detail = abc.delete(5)
    assert (status, http_status, len(detail)) == ("error", 500, 500)
    status, http_status, detail = abc.delete(6)
    assert (status, http_status) == ("error", 0) and "down" in detail


def test_reference_curie_by_cross_reference():
    abc, session = make([Response(200, {"curie": "AGRKB:1"}), Response(404, text="not found")])
    assert abc.reference_curie("WB:WBPaper00065018") == "AGRKB:1"
    assert abc.reference_curie("WB:WBPaper99999999") is None
    assert session.calls[0][1] == "https://abc.example.org/reference/by_cross_reference/WB:WBPaper00065018"


def test_delete_ok():
    abc, session = make([Response(204)])
    assert abc.delete(7) == ("ok", 204, "")
    assert session.calls[0][:2] == ("DELETE", "https://abc.example.org/topic_entity_tag/7")


def test_update_note_patches_only_the_note_and_keeps_the_audit_fields():
    abc, session = make([Response(200)])
    tag = {"topic_entity_tag_id": 9, "created_by": "WBPerson1", "updated_by": "WBPerson1",
           "date_updated": "2021-06-24T00:00:00", "note": None}
    assert abc.update_note(tag, "dpy-5 ( WB:WBGene1 )") == ("ok", 200, "")
    method, url, body, _ = session.calls[0]
    assert (method, url) == ("PATCH", "https://abc.example.org/topic_entity_tag/9")
    assert body == {"note": "dpy-5 ( WB:WBGene1 )", "updated_by": "WBPerson1", "date_updated": "2021-06-24T00:00:00"}


def test_update_note_to_empty_sends_null():
    abc, session = make([Response(200)])
    abc.update_note({"topic_entity_tag_id": 9, "created_by": "WBPerson1"}, "")
    assert session.calls[0][2] == {"note": None, "updated_by": "WBPerson1"}


KIMBERLY = "AGRKB:103000000000024"


def test_tags_map_abc_persons_back_to_wb_person_ids():
    """SCRUM-6729: a WB person the ABC knows is recorded under their ABC curie and shown by display name; the sync
    compares authors and curators by WB person id, so the tags are read back with it (one lookup per person)."""
    tags = [{"topic_entity_tag_id": 1, "created_by": "Kimberly Van Auken", "created_by_user_id": KIMBERLY,
             "updated_by": "Kimberly Van Auken", "updated_by_user_id": KIMBERLY},
            {"topic_entity_tag_id": 2, "created_by": "Kimberly Van Auken", "created_by_user_id": KIMBERLY,
             "updated_by": "WBPerson13824", "updated_by_user_id": "WBPerson13824"},
            {"topic_entity_tag_id": 3, "created_by": "unknown_author", "created_by_user_id": "unknown_author"}]
    abc, session = make([Response(200, {"tags": {"c1": tags}}),
                         Response(200, [{"curie": "ORCID:0000-0001", "is_obsolete": False},
                                        {"curie": "WB:WBPerson1843", "is_obsolete": False}])])
    read = abc.tags(["c1"])["c1"]
    assert [(t["created_by"], t.get("updated_by")) for t in read] == [
        ("WBPerson1843", "WBPerson1843"), ("WBPerson1843", "WBPerson13824"), ("unknown_author", None)]
    assert read[0]["abc_created_by_user_id"] == KIMBERLY
    gets = [call for call in session.calls if call[0] == "GET"]
    assert len(gets) == 1 and gets[0][1].endswith(f"/person_cross_reference/person/{KIMBERLY}")


def test_tags_keep_a_person_without_a_wb_id():
    tags = [{"topic_entity_tag_id": 1, "created_by": "Some Curator", "created_by_user_id": KIMBERLY}]
    abc, _ = make([Response(200, {"tags": {"c1": tags}}), Response(200, [{"curie": "ORCID:1", "is_obsolete": False}])])
    assert abc.tags(["c1"])["c1"][0]["created_by"] == "Some Curator"
