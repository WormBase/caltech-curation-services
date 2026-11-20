"""The ACKnowledge_pipeline tags a paper processed by the Caltech pipeline should have."""
from typing import List, Optional, Tuple

from sync_ack_tags.caltech import CaltechData
from sync_ack_tags.constants import (ACK_PIPELINE, CLASSIFIER_TOPICS, CONTEXT_CLASSIFICATION, CONTEXT_ENTITY,
                                     ENTITY_TYPES, NOVELTY_CLASSIFICATION, NOVELTY_EXISTING, PRECHECK_LEVELS)
from sync_ack_tags.entities import parse_entities
from sync_ack_tags.tags import make_tag


def _tfp_rows(joinkey: str, data: CaltechData):
    return [(entity_type, data.tables.get(entity_type.tfp_table, {}).get(joinkey))
            for entity_type in ENTITY_TYPES.values()]


def processed_before(joinkey: str, data: CaltechData, cutoff: Optional[str]) -> bool:
    """the pipeline processed the paper, and before the cutoff date (YYYY-MM-DD) when one is given"""
    timestamps = [row.timestamp for _, row in _tfp_rows(joinkey, data) if row is not None]
    if not timestamps:
        return False
    return cutoff is None or max(timestamps)[:10] < cutoff


def pipeline_tags(joinkey: str, curie: str, data: CaltechData) -> Tuple[List[dict], List[Tuple[str, str]]]:
    """the expected ACKnowledge_pipeline entity and classification tags of a paper, and the problems found as
    (topic, message)"""
    tags: List[dict] = []
    problems: List[Tuple[str, str]] = []
    common = {"reference_curie": curie, "source_method": ACK_PIPELINE, "created_by": ACK_PIPELINE}
    latest = ""
    for entity_type, row in _tfp_rows(joinkey, data):
        if row is None:
            continue
        latest = max(latest, row.timestamp)
        if row.data == "":
            tags.append(make_tag(**common, topic=entity_type.topic, negated=True, data_novelty=NOVELTY_EXISTING,
                                 data_context=CONTEXT_ENTITY, date_created=row.timestamp))
            continue
        entities, entity_problems = parse_entities(entity_type.name, row.data, data)
        problems.extend((entity_type.topic, f"{entity_type.tfp_table}: {p}") for p in entity_problems)
        for entity in entities:
            tags.append(make_tag(
                **common, topic=entity_type.topic, entity_type=entity_type.topic, entity=entity.curie,
                species=entity.species, entity_id_validation="alliance", negated=False,
                data_novelty=NOVELTY_EXISTING, data_context=CONTEXT_ENTITY,
                date_created=row.timestamp))
    for datatype, topic in CLASSIFIER_TOPICS.items():
        level = data.blackbox.get(joinkey, {}).get(datatype)
        if level is None:
            continue
        tags.append(make_tag(**common, topic=topic, negated=level not in PRECHECK_LEVELS, confidence_level=level,
                             data_novelty=NOVELTY_CLASSIFICATION, data_context=CONTEXT_CLASSIFICATION,
                             date_created=latest or None))
    return tags, problems
