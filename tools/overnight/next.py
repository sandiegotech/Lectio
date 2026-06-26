#!/usr/bin/env python3
"""Deterministic work queue for the overnight Vernacular loop.

Run from the repo root. Prints the next N missing Lectio Modern sections as JSON.
Progress is derived ENTIRELY from committed git state (pipeline/modern/*.json vs the
source editions), so the loop is fully resumable on any machine that clones the repo —
including a cloud session. A wifi drop or crash can only pause it, never lose work.

    python3 tools/overnight/next.py [N]   # N defaults to 3
"""
import json, os, sys

# (work_id, slug, source_edition_short) — the modern Lectio mirrors the source's sections.
# Append new works here to extend the loop; an empty queue means everything is done.
PRIORITY = [
    ("work.aristotle.nicomachean-ethics", "nicomachean-ethics", "chase-1911"),
    ("work.shakespeare.hamlet",            "hamlet",             "original"),
    ("work.dante.divine-comedy",           "divine-comedy",      "longfellow-1867"),
    ("work.augustine.confessions",         "confessions",        "pusey-1838"),
    ("work.confucius.analects",            "analects",           "legge-1893"),
    ("work.machiavelli.the-prince",        "the-prince",         "marriott-1908"),
    ("work.plato.republic",                "republic",           "jowett-1871"),
    ("work.vyasa.bhagavad-gita",           "bhagavad-gita",      "arnold-1885"),
    ("work.dhammapada",                    "dhammapada",         "muller-1881"),
]
N = int(sys.argv[1]) if len(sys.argv) > 1 else 3

def modern_orders(slug):
    mj = f"pipeline/modern/{slug}.json"; present = set()
    if os.path.exists(mj):
        present = {b["order"] for b in json.load(open(mj)).get("books", [])}
    ed = f"pipeline/modern/{slug}-books"
    if os.path.isdir(ed):
        for f in os.listdir(ed):
            if f.startswith("book-") and f.endswith(".json"):
                present.add(int(f.split("book-")[1].split(".")[0]))
    return present

out = []
for wid, slug, src in PRIORITY:
    se = f"content/works/{wid}/editions/{src}.json"
    if not os.path.exists(se): continue
    present = modern_orders(slug)
    for sec in json.load(open(se))["sections"]:
        if sec["order"] not in present:
            out.append({"work_id": wid, "slug": slug, "order": sec["order"],
                        "label": sec["label"], "pds": [src]})
        if len(out) >= N: break
    if len(out) >= N: break
print(json.dumps(out, ensure_ascii=False))
