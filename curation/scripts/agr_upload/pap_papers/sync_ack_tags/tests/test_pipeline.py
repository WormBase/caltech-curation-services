from sync_ack_tags.caltech import Row
from sync_ack_tags.pipeline import pipeline_tags, processed_before
from sync_ack_tags.tests.conftest import make_data

ELEGANS = "NCBITaxon:6239"
PAPER, CURIE = "00000001", "AGRKB:101000000000001"


def test_empty_row_gives_one_negated_topic_tag():
    data = make_data(tables={"tfp_strain": {PAPER: Row("", "2024-01-01T00:00:00")}})
    tags, problems = pipeline_tags(PAPER, CURIE, data)
    assert len(tags) == 1
    tag = tags[0]
    assert tag["negated"] is True and tag["topic"] == "ATP:0000027" and "entity" not in tag
    assert tag["data_novelty"] == "ATP:0000334" and tag["data_context"] == "ATP:0000325"
    assert tag["created_by"] == "ACKnowledge_pipeline" and tag["source_method"] == "ACKnowledge_pipeline"
    assert tag["reference_curie"] == CURIE and tag["date_created"] == "2024-01-01T00:00:00"
    assert problems == []


def test_entities_give_positive_tags():
    data = make_data(tables={"tfp_variation": {PAPER: Row("WBVar1;%;a | WBVar2;%;b", "2024-01-01T00:00:00")}},
                     variation_taxon={"WB:WBVar1": ELEGANS, "WB:WBVar2": ELEGANS})
    tags, _ = pipeline_tags(PAPER, CURIE, data)
    assert [t["entity"] for t in tags] == ["WB:WBVar1", "WB:WBVar2"]
    tag = tags[0]
    assert tag["negated"] is False and tag["topic"] == tag["entity_type"] == "ATP:0000285"
    assert tag["species"] == ELEGANS and "entity_published_as" not in tag  # removed from the ABC (SCRUM-4218)
    assert tag["entity_id_validation"] == "alliance" and tag["data_context"] == "ATP:0000325"


def test_species_and_gene_tags():
    data = make_data(tables={"tfp_species": {PAPER: Row("Caenorhabditis elegans", "2024-01-01T00:00:00")},
                             "tfp_genestudied": {PAPER: Row("00000239;%;bas-1", "2024-01-01T00:00:00")}},
                     species_taxon={"Caenorhabditis elegans": ELEGANS}, gene_taxon={"WB:WBGene00000239": ELEGANS})
    tags, _ = pipeline_tags(PAPER, CURIE, data)
    by_topic = {t["topic"]: t for t in tags}
    assert by_topic["ATP:0000123"]["entity"] == ELEGANS and "species" not in by_topic["ATP:0000123"]
    assert "entity_published_as" not in by_topic["ATP:0000123"]
    assert by_topic["ATP:0000005"]["species"] == ELEGANS and "entity_published_as" not in by_topic["ATP:0000005"]


def test_empty_species_row_uses_existing_data_novelty():
    data = make_data(tables={"tfp_species": {PAPER: Row("", "2024-01-01T00:00:00")}})
    tags, _ = pipeline_tags(PAPER, CURIE, data)
    assert tags[0]["data_novelty"] == "ATP:0000334"


def test_classification_tags():
    data = make_data(tables={"tfp_strain": {PAPER: Row("", "2024-01-01T00:00:00")}},
                     blackbox={PAPER: {"rnai": "MEDIUM", "geneint": "LOW", "antibody": "HIGH"}})
    tags, _ = pipeline_tags(PAPER, CURIE, data)
    classes = {t["topic"]: t for t in tags if "confidence_level" in t}
    assert set(classes) == {"ATP:0000082", "ATP:0000068"}
    assert classes["ATP:0000082"]["negated"] is False and classes["ATP:0000082"]["confidence_level"] == "MEDIUM"
    assert classes["ATP:0000068"]["negated"] is True and classes["ATP:0000068"]["confidence_level"] == "LOW"
    assert classes["ATP:0000082"]["data_novelty"] == "ATP:0000335"
    assert classes["ATP:0000082"]["data_context"] == "ATP:0000323"


def test_processed_before():
    data = make_data(tables={"tfp_strain": {PAPER: Row("", "2026-01-01T00:00:00")},
                             "tfp_species": {PAPER: Row("", "2026-03-01T10:00:00")}})
    assert processed_before(PAPER, data, None) is True
    assert processed_before(PAPER, data, "2026-03-02") is True
    assert processed_before(PAPER, data, "2026-03-01") is False
    assert processed_before("00000002", data, None) is False
