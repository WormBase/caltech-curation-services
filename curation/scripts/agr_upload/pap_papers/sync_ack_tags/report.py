"""The report files: actions.tsv, problems.tsv, results.tsv (--apply), summary.txt, affected_curies.txt."""
import csv
import os
from collections import Counter
from typing import List, Optional, Tuple

TAG_FIELDS = ("topic_entity_tag_id", "topic", "entity_type", "entity", "species", "negated", "data_novelty",
              "data_context", "confidence_level", "created_by", "date_created", "note", "validation_by_author",
              "validation_by_professional_biocurator")
ACTION_FIELDS = ("source", "action", "wb_paper", "curie", "reason")
RESULT_FIELDS = ("status", "http_status", "detail")


def _rows(actions: List[dict], extra: Tuple[str, ...] = ()):
    for action in actions:
        row = {field: action["tag"].get(field, "") for field in TAG_FIELDS}
        row.update({field: action.get(field, "") for field in ACTION_FIELDS + extra})
        yield row


def _write_tsv(path: str, fields, rows):
    with open(path, "w", newline="") as fh:
        writer = csv.DictWriter(fh, fieldnames=fields, delimiter="\t", extrasaction="ignore")
        writer.writeheader()
        writer.writerows(rows)


def write(out_dir: str, actions: List[dict], problems: List[Tuple[str, str, str]], results: Optional[List[dict]],
          header: str):
    os.makedirs(out_dir, exist_ok=True)
    _write_tsv(os.path.join(out_dir, "actions.tsv"), ACTION_FIELDS + TAG_FIELDS, _rows(actions))
    _write_tsv(os.path.join(out_dir, "problems.tsv"), ("wb_paper", "curie", "problem"),
               ({"wb_paper": "WBPaper" + joinkey, "curie": curie, "problem": problem}
                for joinkey, curie, problem in problems))
    counts = Counter((a["source"], a["tag"].get("topic", ""), a["action"]) for a in actions)
    papers = len({a["curie"] for a in actions})
    lines = [header, f"{len(actions)} actions on {papers} references, {len(problems)} problems", "",
             "source\ttopic\taction\ttags"]
    lines += [f"{source}\t{topic}\t{action}\t{n}" for (source, topic, action), n in sorted(counts.items())]
    if results is not None:
        _write_tsv(os.path.join(out_dir, "results.tsv"), ACTION_FIELDS + RESULT_FIELDS + TAG_FIELDS,
                   _rows(results, RESULT_FIELDS))
        statuses = Counter(f"{r['source']} {r['action']} {r['status']}" for r in results)
        lines += ["", "results"] + [f"{key}\t{n}" for key, n in sorted(statuses.items())]
    with open(os.path.join(out_dir, "summary.txt"), "w") as fh:
        fh.write("\n".join(lines) + "\n")
    with open(os.path.join(out_dir, "affected_curies.txt"), "w") as fh:
        fh.write("".join(f"{curie}\n" for curie in sorted({a["curie"] for a in actions})))
    return "\n".join(lines)
