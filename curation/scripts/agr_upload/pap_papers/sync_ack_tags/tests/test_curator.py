from sync_ack_tags.caltech import Removal, Row
from sync_ack_tags.constants import MERGE_REMOVAL_NOTE, REMOVAL_NOTE
from sync_ack_tags.curator import paper_editor_tags
from sync_ack_tags.diff import diff_paper_editor
from sync_ack_tags.tests.conftest import make_data

ELEGANS, TROPICALIS = "NCBITaxon:6239", "NCBITaxon:1561998"
PAPER, CURIE = "00000001", "AGRKB:101000000000001"
TS = "2024-01-01T00:00:00"
REMOVED = "2024-07-09T02:23:26"


def ack(tables, removals):
    return make_data(tables=tables, ack_papers={PAPER}, removals=removals,
                     gene_taxon={"WB:WBGene00016571": ELEGANS, "WB:WBGene00000001": ELEGANS},
                     species_taxon={"Caenorhabditis elegans": ELEGANS, "Caenorhabditis tropicalis": TROPICALIS})


def test_removed_author_gene_is_negated_by_the_curator():
    data = ack({"afp_genestudied": {PAPER: Row("00016571;%;C41H7.1 | 00000001;%;aap-1", TS)}},
               {"gene": {PAPER: [Removal("00016571", "WBPerson1843", REMOVED)]}})
    tags = paper_editor_tags(PAPER, CURIE, data)
    assert tags == [{
        "reference_curie": CURIE, "source_method": "paper_editor_genes_curator", "topic": "ATP:0000005",
        "entity_type": "ATP:0000005", "entity": "WB:WBGene00016571", "species": ELEGANS,
        "entity_id_validation": "alliance", "negated": True, "data_novelty": "ATP:0000334",
        "data_context": "ATP:0000325", "note": REMOVAL_NOTE, "created_by": "WBPerson1843",
        "date_created": REMOVED, "force_insertion": True, "updated_by": "WBPerson1843", "date_updated": REMOVED}]


def test_id_corrections_and_entities_the_author_dropped_get_no_tag():
    data = ack({"afp_species": {PAPER: Row("Caenorhabditis tropicalis", TS)},
                "afp_genestudied": {PAPER: Row("00000001;%;aap-1", TS)}},
               {"species": {PAPER: [Removal("886184", "WBPerson1843", REMOVED)]},
                "gene": {PAPER: [Removal("00016571", "WBPerson1843", REMOVED)]}})
    assert paper_editor_tags(PAPER, CURIE, data) == []


def test_removed_species_tag_has_no_species_field():
    data = ack({"afp_species": {PAPER: Row("Caenorhabditis elegans", TS)}},
               {"species": {PAPER: [Removal("6239", "WBPerson1843", REMOVED)]}})
    tags = paper_editor_tags(PAPER, CURIE, data)
    assert [(t["source_method"], t["entity"], "species" in t) for t in tags] == [
        ("paper_editor_species", ELEGANS, False)]


def test_out_of_author_scope_gets_no_tag():
    data = ack({"afp_genestudied": {PAPER: Row("00016571;%;C41H7.1", TS)}},
               {"gene": {PAPER: [Removal("00016571", "WBPerson1843", REMOVED)]}})
    data.ack_papers = set()
    assert paper_editor_tags(PAPER, CURIE, data) == []


def editor_tag(tag_id, entity, negated, note):
    return {"topic_entity_tag_id": tag_id, "topic": "ATP:0000005", "entity_type": "ATP:0000005", "entity": entity,
            "species": ELEGANS, "negated": negated, "data_novelty": "ATP:0000334", "note": note,
            "created_by": "WBPerson1843", "tag_source": {"source_method": "paper_editor_genes_curator"}}


def test_diff_never_deletes_the_paper_editors_own_tags():
    existing = [editor_tag(1, "WB:WBGene00006710", False, 'Manually_connected\t"WBGene00006710"'),
                editor_tag(2, "WB:WBGene00000002", True, "a curator's own negation"),
                editor_tag(3, "WB:WBGene00000003", True, REMOVAL_NOTE)]
    actions = diff_paper_editor("paper_editor_genes_curator", [], existing)
    assert [(a["action"], a["tag"]["topic_entity_tag_id"]) for a in actions] == [("delete", 3)]


def test_diff_keeps_a_matching_removal_tag():
    data = ack({"afp_genestudied": {PAPER: Row("00016571;%;C41H7.1", TS)}},
               {"gene": {PAPER: [Removal("00016571", "WBPerson1843", REMOVED)]}})
    expected = paper_editor_tags(PAPER, CURIE, data)
    existing = [editor_tag(3, "WB:WBGene00016571", True, REMOVAL_NOTE)]
    assert diff_paper_editor("paper_editor_genes_curator", expected, existing) == []


MERGED_PAPER = "00066528"  # removals confirmed as gene merges


def test_removals_confirmed_as_merges_get_the_merge_note():
    data = ack({"afp_genestudied": {MERGED_PAPER: Row("00016571;%;C41H7.1", TS)},
                "afp_species": {"00059443": Row("Caenorhabditis tropicalis", TS)}},
               {"gene": {MERGED_PAPER: [Removal("00016571", "WBPerson1843", REMOVED)]},
                "species": {"00059443": [Removal("1561998", "WBPerson1843", REMOVED)]}})
    data.ack_papers = {MERGED_PAPER, "00059443"}
    assert [t["note"] for t in paper_editor_tags(MERGED_PAPER, CURIE, data)] == [MERGE_REMOVAL_NOTE]
    assert [t["note"] for t in paper_editor_tags("00059443", CURIE, data)] == [MERGE_REMOVAL_NOTE]


def test_species_removal_on_a_gene_merge_paper_keeps_the_plain_note():
    data = ack({"afp_species": {MERGED_PAPER: Row("Caenorhabditis elegans", TS)}},
               {"species": {MERGED_PAPER: [Removal("6239", "WBPerson1843", REMOVED)]}})
    data.ack_papers = {MERGED_PAPER}
    assert [t["note"] for t in paper_editor_tags(MERGED_PAPER, CURIE, data)] == [REMOVAL_NOTE]


def test_diff_replaces_a_removal_tag_whose_note_changed():
    data = ack({"afp_genestudied": {MERGED_PAPER: Row("00016571;%;C41H7.1", TS)}},
               {"gene": {MERGED_PAPER: [Removal("00016571", "WBPerson1843", REMOVED)]}})
    data.ack_papers = {MERGED_PAPER}
    expected = paper_editor_tags(MERGED_PAPER, CURIE, data)
    existing = [editor_tag(3, "WB:WBGene00016571", True, REMOVAL_NOTE)]
    actions = diff_paper_editor("paper_editor_genes_curator", expected, existing)
    assert [(a["action"], a["tag"].get("topic_entity_tag_id"), a["tag"]["note"]) for a in actions] == [
        ("delete", 3, REMOVAL_NOTE), ("create", None, MERGE_REMOVAL_NOTE)]


def test_diff_keeps_a_matching_merge_removal_tag_and_deletes_a_stale_one():
    existing = [editor_tag(4, "WB:WBGene00000004", True, MERGE_REMOVAL_NOTE)]
    actions = diff_paper_editor("paper_editor_genes_curator", [], existing)
    assert [(a["action"], a["tag"]["topic_entity_tag_id"]) for a in actions] == [("delete", 4)]
