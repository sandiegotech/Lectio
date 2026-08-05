#!/usr/bin/env python3
"""Cover every shell that has no artwork yet.

A shelf with holes in it looks broken; a shelf of quiet cards looks like a series with more
coming. These are the same board, frame, rails and type as every other cover — only the
medallion is empty, carrying the mark instead of a motif. When artwork arrives, the work
gets a real recipe and the placeholder is simply replaced.

    python3 print/covers/build_placeholders.py
"""

from __future__ import annotations

import glob
import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from build_covers import EAST, HERE, ROOT, WEST, board  # noqa: E402
from build_planned import JPEG_HEIGHT, raster, split_title  # noqa: E402
from build_covers import render  # noqa: E402

OUT_SVG = HERE / "placeholders"

# The two series boards, at the tone the published covers average to.
TONE = {"West": "#c6b294", "East": "#121924"}


def shells() -> dict[str, dict]:
    """Every planned entry whose cover file does not exist -> the entry itself."""
    want = {}
    for f in sorted(glob.glob(str(ROOT / "content/collections/*.json"))):
        for p in json.loads(Path(f).read_text()).get("planned", []) or []:
            cover = p.get("cover")
            if cover and not (ROOT / "content" / cover).exists():
                want.setdefault(Path(cover).stem, p)
    return want


def main() -> int:
    OUT_SVG.mkdir(parents=True, exist_ok=True)
    todo = shells()
    print(f"{len(todo)} shells without artwork")
    total = 0
    for stem, meta in sorted(todo.items()):
        east = (meta.get("tradition") or "West") == "East"
        family = EAST if east else WEST
        spec = dict(
            palette=board(family, TONE["East" if east else "West"]),
            author=(meta.get("author") or "").upper(),
            title=split_title((meta.get("title") or "").upper()),
            art=None,
        )
        svg = OUT_SVG / f"{stem}.svg"
        svg.write_text(render(spec))
        jpg = ROOT / "content/collections/book-covers" / f"{stem}.jpg"
        raster(svg, jpg)
        total += jpg.stat().st_size
        print(f"  {stem:<50} {jpg.stat().st_size/1024:4.0f} KB")
    print(f"total {total/1e6:.2f} MB")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
