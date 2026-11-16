"""Compare a paper's expected tags with its ABC tags and list the deletes and creates."""
from typing import List, Optional, Set

from sync_ack_tags.constants import ACK_FORM, ACK_PIPELINE, REMOVAL_NOTES
from sync_ack_tags.tags import author_key, pipeline_key


# validated by other tags; validated_right_self (the tag's own source) is not a validation to review
VALIDATED = {"validated_right", "validated_wrong", "validation_conflict"}


def _validated(tag: dict) -> bool:
    return any(tag.get(field) in VALIDATED
               for field in ("validation_by_author", "validation_by_professional_biocurator"))


def _delete(source: str, tag: dict, reason: str) -> dict:
    return {"action": "delete", "source": source, "tag": tag,
            "reason": ("VALIDATED; " if _validated(tag) else "") + reason}


def _create(source: str, tag: dict, reason: str) -> dict:
    return {"action": "create", "source": source, "tag": tag, "reason": reason}


def _diff(source: str, key, expected: List[dict], existing: List[dict], stale_reason: str,
          protect: Optional[Set[str]] = None) -> List[dict]:
    """per tag: delete ABC tags no expected tag matches, create expected tags no ABC tag matches; extra copies of a
    matching tag are left alone (spec amendment 7), so unchanged tags keep their ids and validations. Entity tags
    of a protected topic (one whose values did not all resolve) are never deleted."""
    protect = protect or set()
    expected_keys = {key(tag) for tag in expected}
    existing_keys = {key(tag) for tag in existing}
    actions = [_delete(source, tag, stale_reason)
               for tag in sorted(existing, key=lambda t: t.get("topic_entity_tag_id") or 0)
               if key(tag) not in expected_keys and not (tag.get("entity") and tag.get("topic") in protect)]
    created = set()
    for tag in expected:
        if key(tag) not in existing_keys and key(tag) not in created:
            created.add(key(tag))
            actions.append(_create(source, tag, "missing"))
    return actions


def diff_pipeline(expected: List[dict], existing: List[dict], protect: Optional[Set[str]] = None) -> List[dict]:
    return _diff(ACK_PIPELINE, pipeline_key, expected, existing, "stale", protect)


def diff_author(expected: List[dict], existing: List[dict], protect: Optional[Set[str]] = None) -> List[dict]:
    """per tag as well (not delete-all-and-recreate): the end state is the same and unchanged author tags keep
    their validations"""
    return _diff(ACK_FORM, author_key, expected, existing, "stale" if expected else "no ACKnowledge author data",
                 protect)


def diff_paper_editor(source: str, expected: List[dict], existing: List[dict]) -> List[dict]:
    """only the sync's own tags of a paper editor source (negated, with one of REMOVAL_NOTES) are compared, so the
    paper editor's own tags are never deleted. The note is part of the key, so a removal whose note changed (e.g.
    confirmed as a merge) is replaced"""
    own = [tag for tag in existing if tag.get("negated") and tag.get("note") in REMOVAL_NOTES]
    return _diff(source, _paper_editor_key, expected, own, "stale")


def _paper_editor_key(tag: dict):
    return author_key(tag) + (tag.get("note"),)
