#!/usr/bin/env python3
"""Raster the vector covers into the bundle's cover.jpg files, for the app.

The SVG in this directory is the master; SwiftUI has no runtime SVG decoder, so the app
still reads a JPEG out of content/. This renders each cover through typst at ~1400px and
writes it back at the size and quality CLAUDE.md specifies for bundled cover art.

    python3 tools/print/covers/build_covers.py        # masters
    python3 tools/print/covers/export_app_covers.py   # app copies
"""

from __future__ import annotations

import subprocess
import sys
import tempfile
from pathlib import Path

from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent))
from build_covers import BOOKS, ROOT, HERE          # noqa: E402

PPI = 165          # 8.5in -> ~1400px tall
QUALITY = 82


def export(slug: str) -> tuple[Path, int]:
    svg = HERE / f"{slug}.svg"
    if not svg.exists():
        raise SystemExit(f"{svg} missing — run build_covers.py first")
    # The recipe's src is the traced original in covers/source; the app copy belongs
    # in the bundle, under the work id that source file is named for.
    work_id = Path(BOOKS[slug]["src"]).stem
    dest = ROOT / "content/works" / work_id / "cover.jpg"

    with tempfile.TemporaryDirectory() as td:
        # typst resolves image paths against --root, so the shim lives inside the repo.
        shim = HERE / "_export.typ"
        shim.write_text(
            "#set page(width: 5.5in, height: 8.5in, margin: 0pt)\n"
            f'#image("/{svg.relative_to(ROOT).as_posix()}", width: 100%, height: 100%)\n')
        png = Path(td) / "cover.png"
        try:
            subprocess.run(["typst", "compile", "--root", str(ROOT), "--format", "png",
                            "--ppi", str(PPI), str(shim), str(png)], check=True)
        finally:
            shim.unlink(missing_ok=True)
        im = Image.open(png).convert("RGB")
        im.save(dest, "JPEG", quality=QUALITY, optimize=True, progressive=True)
    return dest, dest.stat().st_size


def main() -> int:
    want = sys.argv[1:] or [k for k in BOOKS if k != "meditations-es"]
    total = 0
    for slug in want:
        dest, size = export(slug)
        total += size
        print(f"{dest.relative_to(ROOT)}  ({size/1024:.0f} KB)")
    print(f"{len(want)} covers, {total/1e6:.1f} MB")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
