#!/usr/bin/env python3
"""One-off fix of the ACKnowledge strain and transgene tags in the ABC (SCRUM-6622).

populate_strain_topic_entity.pl and populate_transgene_topic_entity.pl left wrong and missing negated tags in the
ABC. This script reads the Caltech tables, compares them with the ABC tags and fixes them:

  A   delete per-strain negated ACKnowledge_form tags filed under the transgene topic (strain list left empty)
  B1  create a negated strain tag for each pipeline strain the author removed from a non-empty strain list
  C   delete the negated ACKnowledge_pipeline transgene topic tag made by the strain script next to pipeline transgenes
  D   create the negated strain topic tag "new to database" when "other strains" is empty
  E   create the negated strain topic tag "existing data" when the strain list is empty
  F   create the negated transgene topic tag "existing data" when the transgene list is empty
  G1  delete per-transgene negated tags when the author left the transgene list and "other transgenes" empty
  G2  delete per-transgene negated tags when the author left the transgene list empty and filled "other transgenes"
  H   delete negated strain and allele topic tags on old author first pass form submissions

Scope: final ACKnowledge submissions up to the last production import of the Perl scripts (2026-05-15). A final
submission (afp_lasttouched) is an ACKnowledge one when the paper has ACKnowledge section rows (afp_species,
afp_strain, ...). Tags to delete that a professional biocurator validated are deleted too (they were wrong in the
first place) and flagged CURATOR-VALIDATED in the report.

Usage:
  fix_ack_strain_transgene_tags.py [--apply] [--papers WBPaper00068690,...] [--out-dir DIR]

Without --apply it only writes the report (dry run). Environment:
  PSQL_HOST, PSQL_PORT, PSQL_DATABASE, PSQL_USERNAME, PSQL_PASSWORD   Caltech DB (read only)
  COGNITO_ADMIN_CLIENT_ID, COGNITO_ADMIN_CLIENT_SECRET, COGNITO_TOKEN_URL   ABC token
  API_SERVER   ABC API host, e.g. stage-literature-rest.alliancegenome.org (no default: the target must be explicit)

Output in --out-dir: actions.tsv (every planned action, with the full tag content for deletes), skipped.tsv, results.tsv
(with --apply), affected_curies.txt (the references to revalidate after --apply) and summary.txt.
"""
import argparse
import csv
import logging
import os
import re
import sys
from collections import defaultdict
from datetime import datetime, timezone
from typing import Dict, List, Optional, Set

import psycopg2
import requests
from agr_cognito_py import generate_headers, get_admin_token

logger = logging.getLogger("fix_ack_strain_transgene_tags")

ACK_START = "2019-03-22"
LAST_IMPORT_END = "2026-05-16"  # submissions before this date were loaded by the 2026-05-15 production run

STRAIN = "ATP:0000027"
TRANSGENE = "ATP:0000110"
ALLELE = "ATP:0000285"
EXISTING_DATA = "ATP:0000334"
NEW_TO_DB = "ATP:0000228"
EMPTY_OTHER = '[{"id":1,"name":""}]'

ACK_FORM = "ACKnowledge_form"
ACK_PIPELINE = "ACKnowledge_pipeline"

# ACKnowledge writes a row in each of these at every final submission, empty or not; the old form never does
ACK_SECTION_TABLES = ("afp_species", "afp_strain", "afp_otherstrain", "afp_variation", "afp_othervariation",
                      "afp_transgene", "afp_othertransgene")

REQUEST_TIMEOUT = 300
BATCH_SIZE = 100


# ---------------------------------------------------------------- Caltech data

def query(cur, sql: str) -> List[tuple]:
    cur.execute(sql)
    return cur.fetchall()


def utc_iso(ts) -> str:
    return ts.astimezone(timezone.utc).replace(tzinfo=None).isoformat()


def load_caltech(conn) -> dict:
    """read the Caltech tables the fix needs; timestamps are converted to naive UTC ISO strings"""
    cur = conn.cursor()
    data: dict = {}
    data["valid"] = {r[0] for r in query(cur, "SELECT joinkey FROM pap_status WHERE pap_status = 'valid'")}
    # merged paper id -> paper it was merged into
    data["merged_into"] = {r[1]: r[0] for r in query(
        cur, "SELECT joinkey, pap_identifier FROM pap_identifier WHERE pap_identifier ~ '^[0-9]{8}$'")}
    data["agrkb"] = {r[0]: r[1] for r in query(
        cur, "SELECT joinkey, pap_identifier FROM pap_identifier WHERE pap_identifier ~ 'AGRKB'")}
    data["lasttouched"] = {}
    for joinkey, ts in query(cur, "SELECT joinkey, afp_timestamp FROM afp_lasttouched ORDER BY afp_timestamp"):
        if ts:
            keep_row(data, data["lasttouched"], joinkey, ts)
    data["ack_rows"] = set()
    for table in ACK_SECTION_TABLES:
        data["ack_rows"].update(valid_paper(data, r[0]) for r in query(
            cur, f"SELECT DISTINCT joinkey FROM {table}"))  # noqa: S608
    # contributors, as the Perl scripts collect them: later rows overwrite earlier ones
    contributors: Dict[str, Dict[str, str]] = defaultdict(dict)
    for sql in ("SELECT joinkey, pap_curator, pap_timestamp FROM pap_species "
                "WHERE pap_evidence ~ 'from author first pass'",
                "SELECT joinkey, pap_curator, pap_timestamp FROM pap_gene "
                "WHERE pap_evidence ~ 'from author first pass'",
                "SELECT joinkey, afp_contributor, afp_timestamp FROM afp_contributor ORDER BY afp_timestamp"):
        for joinkey, who, ts in query(cur, sql):
            if who and valid_paper(data, joinkey):
                contributors[valid_paper(data, joinkey)][who.replace("two", "WBPerson")] = utc_iso(ts)
    data["contributors"] = dict(contributors)
    for table in ("afp_strain", "afp_otherstrain", "afp_transgene", "afp_othertransgene", "tfp_strain"):
        data[table] = {}
        for joinkey, value, ts in query(cur, f"SELECT joinkey, {table}, {table.split('_')[0]}_timestamp "  # noqa: S608
                                             f"FROM {table} ORDER BY {table.split('_')[0]}_timestamp"):
            keep_row(data, data[table], joinkey, {"data": value or "", "timestamp": utc_iso(ts)})
    for table in ("lasttouched", "afp_strain", "afp_otherstrain", "afp_transgene", "afp_othertransgene", "tfp_strain"):
        data[table].pop("_own", None)
    data["strain_by_name"], data["strain_taxon"] = load_strains(cur)
    cur.close()
    return data


def keep_row(data: dict, rows: dict, joinkey: str, row):
    """store a row under the valid paper it belongs to; the paper's own row wins over a merged paper's row
    (e.g. the pipeline rerun of a merged duplicate must not replace the run the author saw)"""
    valid = valid_paper(data, joinkey)
    if valid is None:
        return
    own = rows.setdefault("_own", set())
    if joinkey == valid:
        rows[valid] = row
        own.add(valid)
    elif valid not in own:
        rows[valid] = row


def load_strains(cur):
    """strain name -> WBStrain id, and WB:WBStrain id -> NCBITaxon, from obo_data_strain as the strain script does"""
    strain_by_name: Dict[str, str] = {}
    strain_species: Dict[str, str] = {}
    for wbstrain, data, _ in query(cur, "SELECT * FROM obo_data_strain"):
        if not data:
            continue
        species = re.findall(r'species: "(.*?)"', data)
        names = re.findall(r'name: "(.*?)"', data)
        if species:
            strain_species["WB:" + wbstrain] = species[0]
        strain_by_name[names[0] if names else ""] = wbstrain
    taxon_by_species = {r[1]: "NCBITaxon:" + r[0] for r in query(
        cur, "SELECT pap_species_index.joinkey, pap_species_index.pap_species_index FROM pap_species_index")}
    strain_taxon = {strain: taxon_by_species[sp] for strain, sp in strain_species.items() if sp in taxon_by_species}
    return strain_by_name, strain_taxon


def valid_paper(data: dict, joinkey: str) -> Optional[str]:
    """the valid paper a paper id resolves to through merges, or None"""
    seen = set()
    while joinkey not in data["valid"]:
        if joinkey in seen or joinkey not in data["merged_into"]:
            return None
        seen.add(joinkey)
        joinkey = data["merged_into"][joinkey]
    return joinkey


def strains_in(text: str, strain_by_name: Dict[str, str]) -> Set[str]:
    """WB:WBStrain curies in an afp_strain / tfp_strain value ("WBStrain1;%;name | ..." or plain names)"""
    found = set()
    for word in text.split(" | ") if text else []:
        if "WBStrain" in word:
            found.add("WB:" + word.split(";%;")[0])
        elif word in strain_by_name:
            found.add("WB:" + strain_by_name[word])
        elif re.sub(r"\s+", "", word) in strain_by_name:
            found.add("WB:" + strain_by_name[re.sub(r"\s+", "", word)])
    return {s for s in found if s != "WB:"}


# ---------------------------------------------------------------- ABC

class Abc:
    def __init__(self, api_server: str):
        self.base = f"https://{api_server}"
        self.headers = generate_headers(get_admin_token())

    def refresh_token(self):
        self.headers = generate_headers(get_admin_token())

    def source_id(self, assertion: str, method: str) -> int:
        url = f"{self.base}/tag_source/{assertion}/{method}/WB/WB"
        response = requests.get(url, headers=self.headers, timeout=REQUEST_TIMEOUT)
        response.raise_for_status()
        return response.json()["tag_source_id"]

    def tags(self, curies: List[str]) -> Dict[str, List[dict]]:
        """ACKnowledge_form and ACKnowledge_pipeline tags of the references"""
        result: Dict[str, List[dict]] = {}
        for i in range(0, len(curies), BATCH_SIZE):
            batch = curies[i:i + BATCH_SIZE]
            body = {"curies_or_reference_ids": batch, "filters": {"source_methods": [ACK_FORM, ACK_PIPELINE]}}
            response = requests.post(f"{self.base}/topic_entity_tag/by_references", json=body,
                                     headers=self.headers, timeout=REQUEST_TIMEOUT)
            if response.status_code == 401:
                self.refresh_token()
                response = requests.post(f"{self.base}/topic_entity_tag/by_references", json=body,
                                         headers=self.headers, timeout=REQUEST_TIMEOUT)
            response.raise_for_status()
            for curie, tags in response.json()["tags"].items():
                result[curie] = tags
            logger.info("fetched ABC tags for %d/%d references", min(i + BATCH_SIZE, len(curies)), len(curies))
        return result

    def _call(self, method: str, url: str, **kwargs) -> requests.Response:
        response = requests.request(method, url, headers=self.headers, timeout=REQUEST_TIMEOUT, **kwargs)
        if response.status_code == 401:
            self.refresh_token()
            response = requests.request(method, url, headers=self.headers, timeout=REQUEST_TIMEOUT, **kwargs)
        return response

    def delete(self, tag_id: int) -> requests.Response:
        return self._call("DELETE", f"{self.base}/topic_entity_tag/{tag_id}")

    def create(self, tag: dict) -> requests.Response:
        return self._call("POST", f"{self.base}/topic_entity_tag/", json=tag)


# ---------------------------------------------------------------- planning

def source_method(tag: dict) -> str:
    return (tag.get("tag_source") or {}).get("source_method", "")


def is_topic_only(tag: dict) -> bool:
    return not tag.get("entity") and not tag.get("entity_type")


def new_tag(curie: str, source_id: int, author: str, date: str, topic: str, novelty: str,
            entity: Optional[str] = None, species: Optional[str] = None) -> dict:
    """a negated ACKnowledge_form tag with the fields the allele script uses"""
    tag = {"reference_curie": curie, "tag_source_id": source_id, "negated": True, "force_insertion": True,
           "topic": topic, "data_novelty": novelty, "created_by": author, "updated_by": author,
           "date_created": date, "date_updated": date}
    if entity:
        tag.update({"entity_type": topic, "entity": entity, "entity_id_validation": "alliance"})
        if species:
            tag["species"] = species
    return tag


def same_negated_tag(existing: dict, tag: dict) -> bool:
    return (source_method(existing) == ACK_FORM and existing.get("negated") is True
            and existing.get("created_by") == tag["created_by"] and existing.get("topic") == tag["topic"]
            and (existing.get("entity") or None) == tag.get("entity")
            and existing.get("data_novelty") == tag["data_novelty"])


def plan_paper(data: dict, joinkey: str, paper: dict, abc_tags: List[dict], ack_source_id: int) -> List[dict]:
    """the actions for one valid paper: dicts with category, action and tag (delete: the ABC tag, create: payload)

    A and C tags are wrong wherever they are; the other categories only apply to a final submission in scope
    (paper["in_scope"]), as ACKnowledge (paper["is_ack"]) or old form.
    """
    curie = paper["curie"]
    actions: List[dict] = []

    def delete(category: str, tag: dict, reason: str):
        actions.append({"category": category, "action": "delete", "tag": tag, "reason": reason})

    def create(category: str, tag: dict, reason: str):
        if any(same_negated_tag(existing, tag) for existing in abc_tags):
            return
        actions.append({"category": category, "action": "create", "tag": tag, "reason": reason})

    form_tags = [t for t in abc_tags if source_method(t) == ACK_FORM]
    pipeline_tags = [t for t in abc_tags if source_method(t) == ACK_PIPELINE]

    tfp_strain = data["tfp_strain"].get(joinkey)

    # A: per-strain negated tags under the transgene topic
    for tag in form_tags:
        if tag.get("negated") is True and tag.get("topic") == TRANSGENE and (tag.get("entity") or "").startswith(
                "WB:WBStrain"):
            delete("A", tag, "strain filed under the transgene topic; strain list empty, covered by the E topic tag")

    # C: the strain script's negated pipeline transgene topic tag (empty tfp_strain) next to pipeline transgenes
    if tfp_strain is not None and tfp_strain["data"] == "" and any(
            t.get("negated") is False and t.get("topic") == TRANSGENE and t.get("entity") for t in pipeline_tags):
        for tag in pipeline_tags:
            if tag.get("negated") is True and tag.get("topic") == TRANSGENE and is_topic_only(tag):
                delete("C", tag, "pipeline found transgenes; tag made by the strain script for an empty tfp_strain")

    if not paper["in_scope"]:
        return actions
    if not paper["is_ack"]:
        # H: old author first pass form submission, it never answered the strain and allele questions
        for tag in form_tags:
            if tag.get("negated") is True and is_topic_only(tag) and tag.get("topic") in (STRAIN, ALLELE):
                delete("H", tag, "old author first pass form submission (no ACKnowledge section rows)")
        return actions

    afp_strain = data["afp_strain"].get(joinkey)
    afp_otherstrain = data["afp_otherstrain"].get(joinkey)
    afp_transgene = data["afp_transgene"].get(joinkey)
    afp_othertransgene = data["afp_othertransgene"].get(joinkey)
    contributors = data["contributors"].get(joinkey) or {}
    authors = sorted(contributors) or ["unknown_author"]
    lasttouched = utc_iso(data["lasttouched"][joinkey])

    def date_for(author: str, fallback: Optional[dict] = None) -> str:
        if author in contributors:
            return contributors[author]
        return fallback["timestamp"] if fallback else lasttouched

    strain_list_empty = afp_strain is not None and afp_strain["data"] == ""
    transgene_list_empty = afp_transgene is not None and afp_transgene["data"] == ""

    # G1, G2: per-transgene negated tags when the author left the transgene list empty
    if transgene_list_empty:
        other_filled = afp_othertransgene is not None and afp_othertransgene["data"] not in ("", EMPTY_OTHER)
        for tag in form_tags:
            if tag.get("negated") is True and (tag.get("entity") or "").startswith("WB:WBTransgene"):
                delete("G2" if other_filled else "G1", tag,
                       "transgene list empty, covered by the F topic tag")

    for author in authors:
        # E: strain list empty -> negated strain topic tag, existing data
        if strain_list_empty:
            create("E", new_tag(curie, ack_source_id, author, date_for(author), STRAIN, EXISTING_DATA),
                   "strain list empty")
        # D: "other strains" empty -> negated strain topic tag, new to database
        if afp_otherstrain is not None and afp_otherstrain["data"] == EMPTY_OTHER:
            create("D", new_tag(curie, ack_source_id, author, date_for(author), STRAIN, NEW_TO_DB),
                   "other strains empty")
        # F: transgene list empty -> negated transgene topic tag, existing data
        if transgene_list_empty:
            create("F", new_tag(curie, ack_source_id, author, date_for(author), TRANSGENE, EXISTING_DATA),
                   "transgene list empty")

    # B1: the author kept a non-empty strain list -> one negated tag per pipeline strain they removed
    if afp_strain is not None and afp_strain["data"] and tfp_strain is not None and tfp_strain["data"]:
        author_strains = strains_in(afp_strain["data"], data["strain_by_name"])
        for strain in sorted(strains_in(tfp_strain["data"], data["strain_by_name"]) - author_strains):
            taxon = data["strain_taxon"].get(strain)
            if not taxon:
                actions.append({"category": "B1", "action": "skip", "tag": {"entity": strain},
                                "reason": "removed strain has no taxon in obo_data_strain"})
                continue
            for author in authors:
                create("B1", new_tag(curie, ack_source_id, author, date_for(author, afp_strain), STRAIN,
                                     EXISTING_DATA, entity=strain, species=taxon), "author removed this strain")
    return actions


def plan(data: dict, abc_tags: Dict[str, List[dict]], ack_source_id: int, papers: Dict[str, dict]) -> List[dict]:
    actions = []
    for joinkey, paper in sorted(papers.items()):
        for action in plan_paper(data, joinkey, paper, abc_tags.get(paper["curie"], []), ack_source_id):
            action.update({"wb_paper": "WBPaper" + joinkey, "curie": paper["curie"]})
            if action["action"] == "delete" and str(
                    action["tag"].get("validation_by_professional_biocurator") or "").startswith("validated"):
                # wrong in the first place, so deleted anyway; flagged for the curators' review
                action["reason"] = "CURATOR-VALIDATED; " + action["reason"]
            actions.append(action)
    return actions


def select_papers(data: dict, only: Optional[Set[str]]) -> Dict[str, dict]:
    """valid papers with an AGRKB curie and ACKnowledge rows: {joinkey: {"curie", "in_scope", "is_ack"}}

    in_scope: a final submission from ACK_START up to the last production import; is_ack: it was made with
    ACKnowledge (the paper has ACKnowledge section rows).
    """
    papers: Dict[str, dict] = {}
    for joinkey in set(data["lasttouched"]) | set(data["tfp_strain"]) | set(data["afp_transgene"]):
        if joinkey not in data["agrkb"] or (only and joinkey not in only):
            continue
        ts = data["lasttouched"].get(joinkey)
        papers[joinkey] = {"curie": data["agrkb"][joinkey],
                           "in_scope": bool(ts) and ACK_START <= utc_iso(ts)[:10] < LAST_IMPORT_END,
                           "is_ack": joinkey in data["ack_rows"]}
    return papers


# ---------------------------------------------------------------- report and apply

TAG_FIELDS = ("topic_entity_tag_id", "topic", "entity_type", "entity", "species", "negated", "data_novelty",
              "created_by", "date_created", "note", "validation_by_author", "validation_by_professional_biocurator")


def tag_row(tag: dict) -> dict:
    row = {field: tag.get(field, "") for field in TAG_FIELDS}
    row["source_method"] = source_method(tag) or ACK_FORM
    return row


def write_tsv(path: str, rows: List[dict], extra: tuple = ()):
    columns = ("category", "action", "wb_paper", "curie", "reason", "source_method") + TAG_FIELDS + extra
    with open(path, "w", newline="") as fh:
        writer = csv.DictWriter(fh, fieldnames=columns, delimiter="\t", extrasaction="ignore")
        writer.writeheader()
        for row in rows:
            writer.writerow(row)


def action_row(action: dict) -> dict:
    row = tag_row(action["tag"])
    row.update({k: action[k] for k in ("category", "action", "wb_paper", "curie", "reason")})
    return row


def summarize(actions: List[dict]) -> str:
    counts: Dict[tuple, Set[str]] = defaultdict(set)
    tags: Dict[tuple, int] = defaultdict(int)
    for action in actions:
        key = (action["category"], action["action"])
        counts[key].add(action["curie"])
        tags[key] += 1
    lines = ["category\taction\tpapers\ttags"]
    lines += [f"{c}\t{a}\t{len(counts[(c, a)])}\t{tags[(c, a)]}" for c, a in sorted(counts)]
    return "\n".join(lines)


def apply(abc: Abc, actions: List[dict]) -> List[dict]:
    """per paper: deletes first (avoids duplicate and opposite-negation rejections), then creates"""
    results = []
    by_paper: Dict[str, List[dict]] = defaultdict(list)
    for action in actions:
        if action["action"] in ("delete", "create"):
            by_paper[action["curie"]].append(action)
    for n, (_curie, paper_actions) in enumerate(sorted(by_paper.items()), 1):
        for action in sorted(paper_actions, key=lambda a: a["action"] != "delete"):
            if action["action"] == "delete":
                response = abc.delete(action["tag"]["topic_entity_tag_id"])
            else:
                response = abc.create(action["tag"])
            status = "ok" if response.status_code in (200, 201, 204) else "error"
            detail = "" if status == "ok" else response.text[:500]
            if action["action"] == "create" and response.status_code == 409 and "duplicate" in response.text:
                status, detail = "exists", ""
            row = action_row(action)
            row.update({"status": status, "http_status": response.status_code, "detail": detail,
                        "result": response.text[:200] if status == "ok" else ""})
            results.append(row)
        if n % 100 == 0:
            logger.info("applied %d/%d papers", n, len(by_paper))
    return results


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--apply", action="store_true", help="make the changes (default: dry run)")
    parser.add_argument("--papers", help="comma-separated WBPaper ids (default: all)")
    parser.add_argument("--out-dir", default=".", help="report directory")
    args = parser.parse_args()
    logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(message)s")

    api_server = os.environ.get("API_SERVER")
    if not api_server:
        sys.exit("API_SERVER is not set")
    only = {p.replace("WBPaper", "") for p in args.papers.split(",")} if args.papers else None
    os.makedirs(args.out_dir, exist_ok=True)

    conn = psycopg2.connect(host=os.environ["PSQL_HOST"], port=os.environ.get("PSQL_PORT", "5432"),
                            dbname=os.environ["PSQL_DATABASE"], user=os.environ["PSQL_USERNAME"],
                            password=os.environ["PSQL_PASSWORD"], options="-c default_transaction_read_only=on")
    data = load_caltech(conn)
    conn.close()
    papers = select_papers(data, only)
    logger.info("%d papers checked, %d with a final submission in scope (%d ACKnowledge, %d old form)", len(papers),
                sum(p["in_scope"] for p in papers.values()),
                sum(p["in_scope"] and p["is_ack"] for p in papers.values()),
                sum(p["in_scope"] and not p["is_ack"] for p in papers.values()))

    abc = Abc(api_server)
    ack_source_id = abc.source_id("ATP:0000035", ACK_FORM)
    abc_tags = abc.tags(sorted({p["curie"] for p in papers.values()}))
    # creates only on papers the Perl scripts loaded, i.e. that already have ACKnowledge_form tags
    loaded = {curie for curie, tags in abc_tags.items() if any(source_method(t) == ACK_FORM for t in tags)}
    actions = [a for a in plan(data, abc_tags, ack_source_id, papers)
               if a["action"] != "create" or a["curie"] in loaded]

    write_tsv(os.path.join(args.out_dir, "actions.tsv"),
              [action_row(a) for a in actions if a["action"] in ("delete", "create")])
    write_tsv(os.path.join(args.out_dir, "skipped.tsv"), [action_row(a) for a in actions if a["action"] == "skip"])
    summary = f"API_SERVER {api_server}\n{'APPLY' if args.apply else 'DRY RUN'} {datetime.now().isoformat()}\n" \
              f"{summarize(actions)}\n"
    if args.apply:
        results = apply(abc, actions)
        write_tsv(os.path.join(args.out_dir, "results.tsv"), results,
                  extra=("status", "http_status", "detail", "result"))
        status_counts: Dict[str, int] = defaultdict(int)
        for row in results:
            status_counts[f"{row['category']} {row['action']} {row['status']}"] += 1
        summary += "\nresults\n" + "\n".join(f"{k}\t{v}" for k, v in sorted(status_counts.items())) + "\n"
    with open(os.path.join(args.out_dir, "affected_curies.txt"), "w") as fh:
        fh.write("".join(f"{c}\n" for c in sorted({a["curie"] for a in actions if a["action"] != "skip"})))
    with open(os.path.join(args.out_dir, "summary.txt"), "w") as fh:
        fh.write(summary)
    print(summary)


if __name__ == "__main__":
    main()
