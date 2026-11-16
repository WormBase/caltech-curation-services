"""The negated paper editor tags of the author genes and species a curator removed (decided 2026-10-26)."""
import re
from typing import List, Optional

from sync_ack_tags.author import in_author_scope
from sync_ack_tags.caltech import CaltechData
from sync_ack_tags.constants import (CONTEXT_ENTITY, ENTITY_TYPES, MERGE_REMOVAL_NOTE, MERGE_REMOVALS,
                                     NOVELTY_EXISTING, PAPER_EDITOR_SOURCES, REMOVAL_NOTE)
from sync_ack_tags.entities import parse_entities
from sync_ack_tags.tags import make_tag


def _removed_curie(entity_type: str, value: str) -> Optional[str]:
    if entity_type == "gene":
        return "WB:WBGene" + value if re.fullmatch(r"\d{8}", value) else None
    return "NCBITaxon:" + value if value.isdigit() else None


def paper_editor_tags(joinkey: str, curie: str, data: CaltechData) -> List[dict]:
    """one negated tag, by the curator on the date of the removal, per entity of the author's afp_* answer that a
    curator removed from pap_gene/pap_species. An entity the answer no longer has gets none, nor does a removal that
    corrected an id (the author's species name already resolves to the curator's taxon). Removals on papers a curator
    confirmed as merges get MERGE_REMOVAL_NOTE."""
    if not in_author_scope(joinkey, data):
        return []
    tags: List[dict] = []
    for name, source in PAPER_EDITOR_SOURCES.items():
        entity_type = ENTITY_TYPES[name]
        afp = data.tables.get(entity_type.afp_table, {}).get(joinkey)
        if afp is None or not afp.data:
            continue
        answered = {e.curie: e for e in parse_entities(name, afp.data, data)[0]}
        note = MERGE_REMOVAL_NOTE if joinkey in MERGE_REMOVALS.get(name, set()) else REMOVAL_NOTE
        for removal in data.removals.get(name, {}).get(joinkey, []):
            entity = answered.get(_removed_curie(name, removal.value) or "")
            if entity is None:
                continue
            tags.append(make_tag(reference_curie=curie, source_method=source, topic=entity_type.topic,
                                 entity_type=entity_type.topic, entity=entity.curie, species=entity.species,
                                 entity_id_validation="alliance", negated=True, data_novelty=NOVELTY_EXISTING,
                                 data_context=CONTEXT_ENTITY, note=note, created_by=removal.curator,
                                 date_created=removal.timestamp))
    return tags
