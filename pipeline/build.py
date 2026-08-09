"""Build entrypoint: run every recipe and publish the content bundle.

    python3 -m pipeline.build

Aborts on structural validation errors; warns (but proceeds) on ID drift.
"""
from __future__ import annotations

import os
import sys

from . import align, idledger, publish
from .collections import build_collections
from .recipes import RECIPES

OUT_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "content"))


def main() -> int:
    works, editions = [], []
    spines: dict[str, dict] = {}

    for recipe in RECIPES:
        work, eds, spine = recipe()
        works.append(work)
        editions.extend(eds)
        # Stage 5 (ALIGN): attach spine ranges; a recipe's own spine wins.
        spine = spine or align.apply(work, eds)
        if spine:
            spines[work.id] = spine
        aligned = sum(1 for e in eds for s in e.sections for seg in s.segments if seg.spine)
        print(f"  built {work.id}: {len(eds)} edition(s), "
              f"{sum(len(s.segments) for e in eds for s in e.sections)} segments"
              + (f", {aligned} spine-aligned" if aligned else ""))

    collections = build_collections(works)

    problems = publish.validate(works, editions, collections)
    if problems:
        print("\nVALIDATION FAILED:")
        for p in problems:
            print(f"  - {p}")
        return 1

    drift = idledger.check_and_update(OUT_DIR, editions)
    for w in drift:
        print(f"  WARNING (id drift): {w}")

    manifest = publish.publish(OUT_DIR, works, editions, collections, spines)

    print(f"\nPublished to {OUT_DIR}")
    print(f"  {len(manifest['works'])} work(s), "
          f"{sum(len(w['editions']) for w in manifest['works'])} edition(s), "
          f"{len(manifest['collections'])} collection(s)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
