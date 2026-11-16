"""The ABC API calls of the sync: tag sources, a paper's tags of the synced sources, delete and create."""
from typing import Callable, Dict, List, Optional, Tuple

import requests
from agr_cognito_py import generate_headers, get_admin_token

from sync_ack_tags.constants import ACK_FORM, ACK_PIPELINE, PAPER_EDITOR_SOURCES, SOURCES
from sync_ack_tags.tags import ALLOWED_CREATE_FIELDS

REQUEST_TIMEOUT = 300
BATCH_SIZE = 100


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
            result.update(response.json()["tags"])
        return result

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
