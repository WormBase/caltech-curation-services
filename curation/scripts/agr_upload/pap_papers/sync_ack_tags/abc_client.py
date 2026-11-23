"""The ABC API calls of the sync: tag sources, a paper's tags of the synced sources, delete, note update, create."""
from typing import Callable, Dict, List, Optional, Tuple

import requests
from agr_cognito_py import generate_headers, get_admin_token

from sync_ack_tags.constants import ACK_FORM, ACK_PIPELINE, PAPER_EDITOR_SOURCES, SOURCES
from sync_ack_tags.tags import ALLOWED_CREATE_FIELDS

REQUEST_TIMEOUT = 300
BATCH_SIZE = 100
WB_PERSON_XREF_PREFIX = "WB:WBPerson"


class AbcError(RuntimeError):
    pass


class Abc:
    def __init__(self, api_server: str, session: Optional[requests.Session] = None,
                 token_fn: Callable[[], str] = get_admin_token):
        self.base = f"https://{api_server}"
        self.session = session or requests.Session()
        self.token_fn = token_fn
        self.headers = generate_headers(token_fn())
        self.source_ids: Dict[str, int] = {}
        # ABC person curie -> the person's bare WB person id (None: no WB cross reference)
        self.wb_person_ids: Dict[str, Optional[str]] = {}

    def _call(self, method: str, path: str, body=None):
        """one request; on 401 a new token and one retry"""
        url = self.base + path
        response = self.session.request(method, url, headers=self.headers, json=body, timeout=REQUEST_TIMEOUT)
        if response.status_code == 401:
            self.headers = generate_headers(self.token_fn())
            response = self.session.request(method, url, headers=self.headers, json=body, timeout=REQUEST_TIMEOUT)
        return response

    def source_id(self, method: str) -> int:
        if method not in self.source_ids:
            response = self._call("GET", f"/tag_source/{SOURCES[method]}/{method}/WB/WB")
            if response.status_code != 200:
                raise AbcError(f"tag source {method}: HTTP {response.status_code} {response.text[:200]}")
            self.source_ids[method] = response.json()["tag_source_id"]
        return self.source_ids[method]

    def reference_curie(self, xref: str) -> Optional[str]:
        """the curie of the reference with a cross-reference (e.g. WB:WBPaper00065018), or None if there is none"""
        response = self._call("GET", f"/reference/by_cross_reference/{xref}")
        if response.status_code == 404:
            return None
        if response.status_code != 200:
            raise AbcError(f"by_cross_reference {xref}: HTTP {response.status_code} {response.text[:200]}")
        return response.json()["curie"]

    def tags(self, curies: List[str]) -> Dict[str, List[dict]]:
        """the ACKnowledge_pipeline, ACKnowledge_form and paper editor gene/species tags of the references, by
        curie"""
        result: Dict[str, List[dict]] = {}
        for i in range(0, len(curies), BATCH_SIZE):
            body = {"curies_or_reference_ids": curies[i:i + BATCH_SIZE],
                    "filters": {"source_methods": [ACK_PIPELINE, ACK_FORM, *PAPER_EDITOR_SOURCES.values()]}}
            response = self._call("POST", "/topic_entity_tag/by_references", body)
            if response.status_code != 200:
                raise AbcError(f"by_references: HTTP {response.status_code} {response.text[:200]}")
            for curie, tags in response.json()["tags"].items():
                result[curie] = [self._as_wb_persons(tag) for tag in tags]
        return result

    def wb_person_id(self, person_curie: str) -> Optional[str]:
        """the bare WB person id (WBPerson1843) of an ABC person, from their WB cross reference; None if they have
        none. Looked up once per person."""
        if person_curie not in self.wb_person_ids:
            response = self._call("GET", f"/person_cross_reference/person/{person_curie}")
            if response.status_code == 404:
                self.wb_person_ids[person_curie] = None
                return None
            if response.status_code != 200:
                raise AbcError(f"person cross references {person_curie}: HTTP {response.status_code} "
                               f"{response.text[:200]}")
            wb_ids = sorted(xref["curie"].split(":", 1)[1] for xref in response.json()
                            if xref["curie"].startswith(WB_PERSON_XREF_PREFIX) and not xref.get("is_obsolete"))
            self.wb_person_ids[person_curie] = wb_ids[0] if wb_ids else None
        return self.wb_person_ids[person_curie]

    def _as_wb_persons(self, tag: dict) -> dict:
        """the tag with its created_by / updated_by as the WB person ids the sync writes

        Since SCRUM-6729 the ABC records a WB person it knows under their ABC person curie (and returns their display
        name in created_by), even when it was sent the WBPerson id. The sync compares authors and curators by WB
        person id, so those are mapped back from the raw *_user_id; the ABC's value is kept in abc_<field>_user_id.
        Anything else (WBPerson placeholders, unknown_author, ACKnowledge_pipeline, persons without a WB id) is
        left as it is.
        """
        out = dict(tag)
        for field in ("created_by", "updated_by"):
            raw = tag.get(f"{field}_user_id") or tag.get(field)
            if not isinstance(raw, str) or not raw.startswith("AGRKB:"):
                continue
            wb_id = self.wb_person_id(raw)
            if wb_id is not None:
                out[field] = wb_id
                out[f"{field}_user_id"] = wb_id
                out[f"abc_{field}_user_id"] = raw
        return out

    def _status(self, call) -> Tuple[str, int, str]:
        try:
            response = call()
        except requests.RequestException as exc:
            return "error", 0, repr(exc)
        if response.status_code in (200, 201, 204):
            return "ok", response.status_code, ""
        if response.status_code == 409 and "duplicate" in response.text:
            return "exists", 409, ""
        return "error", response.status_code, response.text[:500]

    def delete(self, tag_id: int) -> Tuple[str, int, str]:
        return self._status(lambda: self._call("DELETE", f"/topic_entity_tag/{tag_id}"))

    def update_note(self, tag: dict, note: str) -> Tuple[str, int, str]:
        """only the note changes: updated_by and date_updated are sent as they are, so the PATCH does not stamp the
        sync's user and today's date on the tag (the ABC still records the change in db_date_updated)"""
        payload = {"note": note or None, "updated_by": tag.get("updated_by") or tag.get("created_by")}
        if tag.get("date_updated"):
            payload["date_updated"] = tag["date_updated"]
        return self._status(lambda: self._call("PATCH", f"/topic_entity_tag/{tag['topic_entity_tag_id']}", payload))

    def create(self, tag: dict) -> Tuple[str, int, str]:
        payload = {k: v for k, v in tag.items() if k != "source_method"}
        unknown = set(payload) - ALLOWED_CREATE_FIELDS
        if unknown:
            return "error", 0, f"fields the ABC does not accept: {sorted(unknown)}"
        try:
            payload["tag_source_id"] = self.source_id(tag["source_method"])
        except (AbcError, requests.RequestException) as exc:
            return "error", 0, repr(exc)
        return self._status(lambda: self._call("POST", "/topic_entity_tag/", payload))
