"""Publish structured content to the portable JSON bundle (CONTENT_PIPELINE.md §7).

Layout produced under <out>/:
    manifest.json
    collections/<id>.json
    works/<workId>/work.json
    works/<workId>/editions/<editionShort>.json
    works/<workId>/spine.json            (when alignment exists)
    works/<workId>/enrichment.json       (hand-authored; carries the curated tap-to-define glossary)
"""
from __future__ import annotations

import hashlib
import json
import os
from typing import Iterable

from .model import Collection, Edition, Work, to_json_dict


SCHEMA_VERSION = 1


def _write_json(path: str, obj) -> str:
    os.makedirs(os.path.dirname(path), exist_ok=True)
    data = json.dumps(obj, ensure_ascii=False, indent=2, sort_keys=False)
    with open(path, "w", encoding="utf-8") as f:
        f.write(data)
        f.write("\n")
    return hashlib.sha256(data.encode("utf-8")).hexdigest()[:16]


def _edition_short(edition_id: str) -> str:
    # edition.iliad.pope-1720 -> pope-1720
    return edition_id.split(".")[-1]


def publish(
    out_dir: str,
    works: Iterable[Work],
    editions: Iterable[Edition],
    collections: Iterable[Collection],
    spines: dict[str, dict] | None = None,
) -> dict:
    """Write the full bundle and return the manifest dict."""
    works = list(works)
    editions = list(editions)
    collections = list(collections)
    spines = spines or {}

    editions_by_work: dict[str, list[Edition]] = {}
    for e in editions:
        editions_by_work.setdefault(e.workId, []).append(e)

    manifest = {
        "schemaVersion": SCHEMA_VERSION,
        "generator": "lectio-pipeline",
        "collections": [],
        "works": [],
        "dictionaries": [],
    }

    for c in collections:
        h = _write_json(os.path.join(out_dir, "collections", f"{c.id}.json"), to_json_dict(c))
        manifest["collections"].append({"id": c.id, "title": c.title, "checksum": h})

    for w in works:
        work_dir = os.path.join(out_dir, "works", w.id)
        # keep editionIds consistent with what we actually publish
        w.editionIds = [e.id for e in editions_by_work.get(w.id, [])]
        wh = _write_json(os.path.join(work_dir, "work.json"), to_json_dict(w))

        ed_entries = []
        for e in editions_by_work.get(w.id, []):
            eh = _write_json(
                os.path.join(work_dir, "editions", f"{_edition_short(e.id)}.json"),
                to_json_dict(e),
            )
            ed_entries.append({
                "id": e.id,
                "translator": e.translator,
                "publishedYear": e.publishedYear,
                "form": e.form,
                "kind": e.kind,
                "character": e.character,
                "checksum": eh,
            })

        spine_present = w.id in spines
        if spine_present:
            _write_json(os.path.join(work_dir, "spine.json"), spines[w.id])

        manifest["works"].append({
            "id": w.id,
            "title": w.title,
            "author": w.author,
            "referenceScheme": w.referenceScheme,
            "defaultEditionId": w.defaultEditionId,
            "collections": w.collections,
            "editions": ed_entries,
            "hasAlignment": spine_present,
            "checksum": wh,
        })

    _write_json(os.path.join(out_dir, "manifest.json"), manifest)
    return manifest


def validate(works, editions, collections) -> list[str]:
    """Cheap structural checks before publish. Returns a list of problems (empty = ok)."""
    problems: list[str] = []
    edition_ids = {e.id for e in editions}
    work_ids = {w.id for w in works}

    for w in works:
        if w.defaultEditionId not in edition_ids:
            problems.append(f"work {w.id}: defaultEditionId {w.defaultEditionId} missing")
    for e in editions:
        if e.workId not in work_ids:
            problems.append(f"edition {e.id}: workId {e.workId} missing")
        if e.provenance is None:
            problems.append(f"edition {e.id}: missing provenance")
        seen = set()
        for s in e.sections:
            for seg in s.segments:
                if seg.id in seen:
                    problems.append(f"edition {e.id}: duplicate segment id {seg.id}")
                seen.add(seg.id)
    for c in collections:
        for item in c.items:
            if item.workId not in work_ids:
                problems.append(f"collection {c.id}: references missing work {item.workId}")
    return problems
