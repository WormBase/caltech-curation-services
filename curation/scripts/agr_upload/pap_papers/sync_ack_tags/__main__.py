"""Sync the ACKnowledge tags of the ABC with the Caltech tables (SCRUM-6598).

Usage (from curation/scripts/agr_upload/pap_papers):
  python3 -m sync_ack_tags [--apply] [--workers N] [--papers WBPaper00068690,...] [--out-dir DIR]
                           [--pipeline-cutoff YYYY-MM-DD]

Without --apply it only writes the report (dry run). Environment:
  PSQL_HOST, PSQL_PORT, PSQL_DATABASE, PSQL_USERNAME, PSQL_PASSWORD   Caltech DB (read only)
  COGNITO_ADMIN_CLIENT_ID, COGNITO_ADMIN_CLIENT_SECRET, COGNITO_TOKEN_URL   ABC token
  API_SERVER   ABC API host (default literature-rest.alliancegenome.org)
"""
import argparse
import logging
import os
import re
import sys
from collections import OrderedDict
from concurrent.futures import ThreadPoolExecutor, as_completed
from datetime import datetime
from typing import Callable, Dict, List, Optional, Set, Tuple

from sync_ack_tags import report
from sync_ack_tags.author import author_tags
from sync_ack_tags.caltech import CaltechData
from sync_ack_tags.constants import ACK_FORM, ACK_PIPELINE, PAPER_EDITOR_SOURCES
from sync_ack_tags.curator import paper_editor_tags
from sync_ack_tags.diff import diff_author, diff_paper_editor, diff_pipeline
from sync_ack_tags.pipeline import pipeline_tags, processed_before
from sync_ack_tags.tags import source_method

logger = logging.getLogger("sync_ack_tags")
DEFAULT_API_SERVER = "literature-rest.alliancegenome.org"

Problem = Tuple[str, str, str]  # (joinkey, curie, problem)


def select_papers(data: CaltechData, only: Optional[Set[str]],
                  lookup: Optional[Callable[[str], Optional[str]]] = None) -> Tuple[Dict[str, str], List[Problem]]:
    """valid papers with ACKnowledge rows -> AGRKB curie, from pap_identifier or else from the ABC by the paper's
    WB cross-reference (lookup); papers with neither are reported"""
    joinkeys = {joinkey for rows in data.tables.values() for joinkey in rows}
    papers: Dict[str, str] = {}
    problems: List[Problem] = []
    for joinkey in sorted(joinkeys):
        if only and joinkey not in only:
            continue
        curie = data.agrkb.get(joinkey) or (lookup("WB:WBPaper" + joinkey) if lookup else None)
        if curie:
            papers[joinkey] = curie
        else:
            problems.append((joinkey, "", "no AGRKB curie"))
    return papers, problems


def plan_paper(joinkey: str, curie: str, data: CaltechData, existing: List[dict],
               cutoff: Optional[str]) -> Tuple[List[dict], List[Problem]]:
    """the actions for one paper: pipeline tags only for papers processed before the cutoff, author tags and the
    curators' negations of author entities always"""
    actions: List[dict] = []
    problems: List[Tuple[str, str]] = []
    if processed_before(joinkey, data, cutoff):
        expected, pipeline_problems = pipeline_tags(joinkey, curie, data)
        problems += pipeline_problems
        actions += diff_pipeline(expected, [t for t in existing if source_method(t) == ACK_PIPELINE],
                                 protect={topic for topic, _ in pipeline_problems})
    expected, author_problems = author_tags(joinkey, curie, data)
    problems += author_problems
    actions += diff_author(expected, [t for t in existing if source_method(t) == ACK_FORM],
                           protect={topic for topic, _ in author_problems})
    removals = paper_editor_tags(joinkey, curie, data)
    for source in PAPER_EDITOR_SOURCES.values():
        actions += diff_paper_editor(source, [t for t in removals if source_method(t) == source],
                                     [t for t in existing if source_method(t) == source])
    for action in actions:
        action.update({"wb_paper": "WBPaper" + joinkey, "curie": curie})
    return actions, [(joinkey, curie, message) for _topic, message in problems]


AUTHOR_CREATED_BY = re.compile(r"WBPerson\w+|unknown_author")  # format only (WBPersonundefined -> unknown_author)


def check_created_by(existing: Dict[str, List[dict]]):
    """stop if the ABC returns ACKnowledge_form authors in another form than the sync writes them (e.g. person
    names once WBPerson agents are linked to people): every author tag would look changed"""
    odd = sorted({t.get("created_by") or "" for tags in existing.values() for t in tags
                  if source_method(t) == ACK_FORM and not AUTHOR_CREATED_BY.fullmatch(t.get("created_by") or "")})
    if odd:
        sys.exit(f"ACKnowledge_form tags with an unexpected created_by, e.g. {odd[:5]}: stopping")


def _apply_paper(abc, paper_actions: List[dict]) -> List[dict]:
    """one paper's actions, deletes then creates; its first error stops the paper (the next run fixes it)"""
    results = []
    failed = False
    for action in sorted(paper_actions, key=lambda a: a["action"] != "delete"):
        if failed:
            status, http_status, detail = "not run", "", ""
        elif action["action"] == "delete":
            status, http_status, detail = abc.delete(action["tag"]["topic_entity_tag_id"])
        else:
            status, http_status, detail = abc.create(action["tag"])
        failed = failed or status == "error"
        results.append(dict(action, status=status, http_status=http_status, detail=detail))
    return results


def apply(abc, actions: List[dict], workers: int = 1) -> List[dict]:
    """the actions paper by paper, `workers` papers at a time (papers are independent; the ABC validates each
    change against the paper's other tags, which makes every request slow); results in action order per paper"""
    by_paper: "OrderedDict[str, List[dict]]" = OrderedDict()
    for action in actions:
        by_paper.setdefault(action["curie"], []).append(action)
    papers = list(by_paper.values())
    results: List[List[dict]] = [[] for _ in papers]
    with ThreadPoolExecutor(max_workers=workers) as pool:
        futures = {pool.submit(_apply_paper, abc, paper_actions): i for i, paper_actions in enumerate(papers)}
        for n, future in enumerate(as_completed(futures), 1):
            results[futures[future]] = future.result()
            if n % 100 == 0:
                logger.info("applied %d/%d references", n, len(papers))
    return [result for paper_results in results for result in paper_results]


def main():  # pragma: no cover - wiring of the database, the API and the report
    import psycopg2
    from sync_ack_tags.abc_client import Abc
    from sync_ack_tags.caltech import load

    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--apply", action="store_true", help="make the changes (default: dry run)")
    parser.add_argument("--workers", type=int, default=6, help="papers applied in parallel (default: 6)")
    parser.add_argument("--papers", help="comma-separated WBPaper ids (default: all)")
    parser.add_argument("--out-dir", default=".", help="report directory")
    parser.add_argument("--pipeline-cutoff", help="YYYY-MM-DD: leave the pipeline tags of papers processed on or "
                                                  "after it alone (default: none)")
    args = parser.parse_args()
    logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(message)s")
    api_server = os.environ.get("API_SERVER") or DEFAULT_API_SERVER
    only = {p.replace("WBPaper", "") for p in args.papers.split(",")} if args.papers else None

    conn = psycopg2.connect(host=os.environ["PSQL_HOST"], port=os.environ.get("PSQL_PORT", "5432"),
                            dbname=os.environ["PSQL_DATABASE"], user=os.environ["PSQL_USERNAME"],
                            password=os.environ["PSQL_PASSWORD"], options="-c default_transaction_read_only=on")
    data = load(conn)
    conn.close()
    abc = Abc(api_server)
    papers, problems = select_papers(data, only, abc.reference_curie)
    logger.info("%d papers to check", len(papers))
    existing = abc.tags(sorted(set(papers.values())))
    check_created_by(existing)
    actions: List[dict] = []
    for joinkey, curie in papers.items():
        paper_actions, paper_problems = plan_paper(joinkey, curie, data, existing.get(curie, []),
                                                   args.pipeline_cutoff)
        actions += paper_actions
        problems += paper_problems
    results = apply(abc, actions, args.workers) if args.apply else None
    header = (f"API_SERVER {api_server}\n{'APPLY' if args.apply else 'DRY RUN'} {datetime.now().isoformat()}\n"
              f"pipeline cutoff {args.pipeline_cutoff or 'none'}")
    print(report.write(args.out_dir, results if results is not None else actions, problems, results, header))


if __name__ == "__main__":
    main()
