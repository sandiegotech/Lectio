"""Stable-ID ledger (CONTENT_PIPELINE.md stage 8 / principle 2).

Segment IDs are the anchor for user highlights, notes, art, and cross-translation
alignment. They are deterministic from (editionId, sectionSlug, order), so they stay
stable as long as content order doesn't change. The ledger records the IDs first
published for each edition and flags *drift* — a previously-published ID disappearing
on a later build — which is exactly what would silently break user annotations.
"""
from __future__ import annotations

import json
import os


def _path(out_dir: str) -> str:
    return os.path.join(out_dir, ".idledger.json")


def load(out_dir: str) -> dict:
    p = _path(out_dir)
    if os.path.exists(p):
        with open(p, encoding="utf-8") as f:
            return json.load(f)
    return {}


def check_and_update(out_dir: str, editions) -> list[str]:
    """Compare this build's segment IDs against the ledger, then update it.

    Returns a list of drift warnings (empty = clean). New editions are recorded
    silently; only the disappearance of an already-published ID is flagged.
    """
    os.makedirs(out_dir, exist_ok=True)
    ledger = load(out_dir)
    warnings: list[str] = []

    for e in editions:
        ids = [seg.id for s in e.sections for seg in s.segments]
        if e.id in ledger:
            current = set(ids)
            missing = [i for i in ledger[e.id] if i not in current]
            if missing:
                warnings.append(
                    f"edition {e.id}: {len(missing)} previously-published segment id(s) "
                    f"no longer present (e.g. {missing[0]}). User annotations would break."
                )
        ledger[e.id] = ids

    with open(_path(out_dir), "w", encoding="utf-8") as f:
        json.dump(ledger, f, ensure_ascii=False, indent=2)
        f.write("\n")
    return warnings
