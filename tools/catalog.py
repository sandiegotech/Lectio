#!/usr/bin/env python3
"""Generate CATALOG.md — a status board for the ingested content bundle.

Reads content/works/*/ and reports, per work: cover present, Lectio (Vernacular)
edition status + the model/date that produced it (so you know if it predates the
current method and wants revising), the other editions on hand, and what reads by
default. Run from the repo root after a build:

    python3 tools/catalog.py        # writes CATALOG.md
    python3 tools/catalog.py --check  # print to stdout, don't write

Everything is derived from the bundle, so it can't drift — regenerate any time.
"""
from __future__ import annotations

import glob
import json
import os
import sys

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
WORKS = os.path.join(ROOT, "content", "works")

MODEL_NAMES = {
    "claude-fable-5": "Fable 5",
    "claude-opus-4-8": "Opus 4.8",
    "claude-opus-4-7": "Opus 4.7",
    "claude-opus-4-6": "Opus 4.6",
    "claude-sonnet-4-6": "Sonnet 4.6",
    "claude-sonnet-4-5": "Sonnet 4.5",
    "claude-haiku-4-5": "Haiku 4.5",
}


def model_name(mid):
    return MODEL_NAMES.get(mid, mid or "—")


def unit(label):
    l = (label or "").lower()
    for key, word in (("canto", "cantos"), ("book", "books"), ("act", "acts"),
                      ("tablet", "tablets"), ("chapter", "chapters")):
        if key in l:
            return word
    return "sections"


def load_work(wd):
    w = json.load(open(os.path.join(wd, "work.json")))
    eds = [json.load(open(f)) for f in sorted(glob.glob(os.path.join(wd, "editions", "*.json")))]
    return w, eds


def planned_without_cover():
    """Planned / 'coming soon' shelf books (in content/collections/*.json) that render a
    placeholder because they carry no cover, or a cover whose file is missing. Returns a
    sorted list of titles."""
    collections = os.path.join(ROOT, "content", "collections")
    seen = {}

    def walk(o):
        if isinstance(o, dict):
            if o.get("title") and o.get("author") is not None and ("era" in o or "part" in o) and "workId" not in o:
                seen.setdefault(o["title"], o)
            for v in o.values():
                walk(v)
        elif isinstance(o, list):
            for v in o:
                walk(v)

    for f in glob.glob(os.path.join(collections, "*.json")):
        walk(json.load(open(f)))
    missing = []
    for title, o in seen.items():
        cov = o.get("cover")
        if not cov or not os.path.exists(os.path.join(ROOT, "content", cov)):
            missing.append(title)
    return sorted(missing)


def main():
    rows, details, missing_cover, no_lectio = [], [], [], []
    n_cover = n_lectio = 0
    work_dirs = sorted(d for d in glob.glob(os.path.join(WORKS, "*/"))
                       if os.path.exists(os.path.join(d, "work.json")))

    for wd in work_dirs:
        w, eds = load_work(wd)
        wid = w["id"]
        title = w["title"]
        has_cover = os.path.exists(os.path.join(wd, "cover.jpg"))
        modern = next((e for e in eds if e.get("kind") == "modern"), None)
        others = [e for e in eds if e.get("kind") != "modern"]
        base = max(others, key=lambda e: len(e["sections"]), default=None)

        # cover
        if has_cover:
            n_cover += 1
        else:
            missing_cover.append(title)
        cover_cell = "✅" if has_cover else "❌ needs cover"

        # Lectio (Vernacular) edition status
        if modern:
            msec = len(modern["sections"])
            bsec = len(base["sections"]) if base else 0
            u = unit(modern["sections"][0]["label"] if modern["sections"] else "")
            if base and bsec:
                complete = msec >= bsec
                lectio_cell = (f"✅ {msec} {u}" if complete else f"◐ {msec}/{bsec} {u}")
                if complete:
                    n_lectio += 1
            else:
                lectio_cell = f"✅ {msec} {u}"   # synthesized, no separate base edition
                n_lectio += 1
            prov = modern.get("provenance", {})
            translated = f"{model_name(prov.get('aiModel'))} · {prov.get('retrievedDate', '—')}"
        else:
            lectio_cell = "—"
            translated = "—"
            no_lectio.append(title)

        default_short = w.get("defaultEditionId", "").split(".")[-1]
        default_label = "Lectio" if default_short.startswith("lectio") else default_short
        rows.append((title, w.get("author", ""), w.get("tradition", ""),
                     cover_cell, lectio_cell, translated, default_label))

        # per-work edition detail
        ed_lines = []
        for e in sorted(eds, key=lambda e: {"modern": 0, "translation": 1, "original": 2}.get(e.get("kind"), 1)):
            secs = len(e["sections"])
            if e.get("kind") == "modern":
                p = e.get("provenance", {})
                desc = f"**Lectio (Vernacular)** — {model_name(p.get('aiModel'))}, {p.get('retrievedDate','—')}"
                srcid = p.get("aiSourceEditionId", "")
                if srcid:
                    desc += f"; base: `{srcid.split('.')[-1]}`"
            elif e.get("kind") == "original":
                desc = f"Original ({e.get('language','?')})"
            else:
                yr = f" {e['publishedYear']}" if e.get("publishedYear") else ""
                desc = f"{e.get('translator','Unknown')}{yr}"
            ed_lines.append(f"  - {desc} — {secs} {unit(e['sections'][0]['label'] if e['sections'] else '')}")
        details.append((title, wid, ed_lines))

    # ---- render ----
    out = []
    out.append("# Lectio — Content Catalog & Status\n")
    out.append("_Generated from the content bundle by `tools/catalog.py` — regenerate after any build._\n")
    out.append(f"**{len(work_dirs)} works ingested** · "
               f"**{n_cover}/{len(work_dirs)} with covers** · "
               f"**{n_lectio}/{len(work_dirs)} with a complete Lectio edition**\n")
    out.append("> Lectio (Vernacular) editions are first-pass **drafts pending human review** "
               "(BIBLE non-negotiable). The *Translated* column is the model + date that produced "
               "each one — revise when it predates the current translation method.\n")

    out.append("## Works\n")
    out.append("| Work | Author | Trad. | Cover | Lectio edition | Translated | Reads by default |")
    out.append("|------|--------|-------|-------|----------------|------------|------------------|")
    for r in rows:
        out.append("| " + " | ".join(r) + " |")
    out.append("")

    # needs-attention rollups
    out.append("## Needs attention\n")
    out.append(f"- **Missing a work cover** ({len(missing_cover)}): "
               + (", ".join(missing_cover) if missing_cover else "none") + "  ")
    out.append(f"  → add `content/works/<id>/cover.jpg` (master in `~/Documents/Lectio-Masters/`, see CLAUDE.md).")
    out.append(f"- **No Lectio edition yet** ({len(no_lectio)}): "
               + (", ".join(no_lectio) if no_lectio else "none") + "  ")
    out.append(f"  → run the overnight loop (`tools/overnight/`) or `/ingest-book` then translate.")
    planned_missing = planned_without_cover()
    out.append(f"- **Planned shelf works missing cover art** ({len(planned_missing)}): "
               + (", ".join(planned_missing) if planned_missing else "none") + "  ")
    out.append(f"  → add the art under `content/collections/book-covers/` and set its `cover` in `pipeline/collections.py`.\n")

    out.append("## Editions on hand\n")
    for title, wid, ed_lines in details:
        out.append(f"**{title}** · `{wid}`")
        out.extend(ed_lines)
        out.append("")

    out.append("## Not yet ingested\n")
    out.append("Planned / “coming soon” shelf works are defined in `pipeline/collections.py` "
               "(and shown greyed in the app) but have no content bundle yet, so they are not "
               "listed above. Ingest a work with the `/ingest-book` skill.\n")

    text = "\n".join(out)
    if "--check" in sys.argv:
        print(text)
    else:
        with open(os.path.join(ROOT, "CATALOG.md"), "w") as f:
            f.write(text)
        print(f"Wrote CATALOG.md — {len(work_dirs)} works, {n_cover} covers, {n_lectio} complete Lectio editions.")


if __name__ == "__main__":
    main()
