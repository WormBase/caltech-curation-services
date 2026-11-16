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
