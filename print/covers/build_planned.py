#!/usr/bin/env python3
"""Set the planned-shelf covers in the house style, automatically.

The library's ten published works each get a hand-tuned recipe in build_covers.py. The ~230
planned works — the shelves you can browse but not yet read — cannot: that is 230 recipes
nobody will ever maintain. They do not need one. They are all the same kind of object (board,
title, one motif in a medallion, series line) so the recipe can be *derived* from the master
artwork instead of written:

  seam   the spine/board edge, as the darkest column on the left
  board  the paper tone, sampled from the plain margins
  motif  the medallion, as the densest block of edges below the title
  inks   dark board -> gold line work; light board -> black over a mid-tone

Everything else comes from the shared LAYOUT, and the type comes from the collection data —
so a planned cover is the same design as a published one, and the shelf reads as one library.

    python3 print/covers/build_planned.py --pilot 9     # sample, for review
    python3 print/covers/build_planned.py               # all of them
"""

from __future__ import annotations

import argparse
import glob
import json
import statistics
import sys
from pathlib import Path

from PIL import Image, ImageFilter

sys.path.insert(0, str(Path(__file__).resolve().parent))
from build_covers import (BOOKS, EAST, HERE, ROOT, WEST, board, dark, light,  # noqa: E402
                          midtone, render)

MASTERS = Path.home() / "Documents/Slate Shared/Lectio-Masters/collections/book-covers"
OUT_SVG = HERE / "planned"
OUT_JPG = ROOT / "content/collections/book-covers"
JPEG_HEIGHT = 1000          # these are browse thumbnails; 48x70pt on screen
JPEG_QUALITY = 80
MAX_W, MAX_H = 760, 880     # the motif may overflow the medallion, never the board


# ---------------------------------------------------------------- the metadata

def planned_index() -> dict[str, dict]:
    """cover filename -> the entry the app shows beside it.

    A shell can name TWO images: `cover`, and `originalCover` for the shelf that shows a
    book in its own series livery (the Harvard Classics reds). Both must be built, and
    neither may be mistaken for unused art.
    """
    out = {}
    for f in sorted(glob.glob(str(ROOT / "content/collections/*.json"))):
        for p in json.loads(Path(f).read_text()).get("planned", []) or []:
            for key in ("cover", "originalCover"):
                if p.get(key):
                    out.setdefault(Path(p[key]).stem, p)
    return out


# ---------------------------------------------------------------- the derivation

def detect_seam(gray: Image.Image) -> int:
    """The spine ends at the darkest column in the left quarter of the scan."""
    w, h = gray.size
    px = gray.load()
    band = range(int(h * 0.2), int(h * 0.8), max(1, h // 60))
    cols = [(statistics.mean(px[x, y] for y in band), x)
            for x in range(int(w * 0.04), int(w * 0.28))]
    return min(cols)[1] + 2


def sample_board(rgb: Image.Image) -> str:
    """The board tone, taken from the plain margins the design never prints on."""
    w, h = rgb.size
    px = rgb.load()
    xs = list(range(int(w * 0.03), int(w * 0.09))) + list(range(int(w * 0.91), int(w * 0.97)))
    ys = range(int(h * 0.18), int(h * 0.86), max(1, h // 80))
    vals = [px[x, y] for x in xs for y in ys]
    med = tuple(int(statistics.median(v[i] for v in vals)) for i in range(3))
    return "#%02x%02x%02x" % med


def _longest_run(vals: list[float], lo: int, hi: int, thr: float, gap: int = 2):
    """The longest contiguous stretch above a threshold, tolerating small gaps."""
    best = run = None
    slack = 0
    for i in range(lo, hi):
        if vals[i] > thr:
            run = [i, i] if run is None else [run[0], i]
            slack = 0
        elif run is not None:
            slack += 1
            if slack > gap:
                if best is None or run[1] - run[0] > best[1] - best[0]:
                    best = run
                run = None
    if run is not None and (best is None or run[1] - run[0] > best[1] - best[0]):
        best = run
    return best


def detect_motif(rgb: Image.Image, tone: str) -> tuple[int, int, int, int]:
    """The medallion, and only the medallion.

    Edge energy cannot tell a line of type from a picture — both are dense — so this measures
    *coverage* instead: per row, the fraction of the board that is not board colour. A line of
    title type covers maybe a fifth of the width; the medallion covers most of it, for many
    rows together. The medallion is the longest such run, and anything implausible falls back
    to the band the family always draws it in.
    """
    w, h = rgb.size
    small = rgb.resize((w // 4, h // 4), Image.LANCZOS)
    sw, sh = small.size
    px = small.load()
    br, bg, bb = (int(tone[i:i + 2], 16) for i in (1, 3, 5))
    base = 0.3 * br + 0.6 * bg + 0.1 * bb

    lo_x, hi_x = int(sw * 0.10), int(sw * 0.90)
    top, bot = int(sh * 0.36), int(sh * 0.88)
    span = hi_x - lo_x

    def frac_row(y):
        n = 0
        for x in range(lo_x, hi_x):
            r, g, b = px[x, y]
            if abs(0.3 * r + 0.6 * g + 0.1 * b - base) > 16:
                n += 1
        return n / span

    rows = [frac_row(y) for y in range(sh)]
    thr = max(rows[top:bot]) * 0.55
    rrun = _longest_run(rows, top, bot, thr, gap=3)

    fallback = (int(w * 0.14), int(h * 0.41), int(w * 0.86), int(h * 0.79))
    if rrun is None:
        return fallback
    y0, y1 = rrun
    if not (0.16 * sh <= y1 - y0 <= 0.58 * sh):
        return fallback

    def frac_col(x):
        n = 0
        for y in range(y0, y1 + 1):
            r, g, b = px[x, y]
            if abs(0.3 * r + 0.6 * g + 0.1 * b - base) > 16:
                n += 1
        return n / max(1, y1 - y0)

    cols = [frac_col(x) for x in range(sw)]
    crun = _longest_run(cols, lo_x, hi_x, max(cols[lo_x:hi_x]) * 0.45, gap=6)
    if crun is None:
        return fallback
    x0, x1 = crun
    mid = (x0 + x1) / 2 / sw
    if not (0.34 <= mid <= 0.66 and 0.32 * sw <= x1 - x0 <= 0.97 * sw):
        return fallback

    pad = 3
    return (max(0, x0 - pad) * 4, max(0, y0 - pad) * 4,
            min(sw, x1 + pad) * 4, min(sh, y1 + pad) * 4)


def luminance(hexcolor: str) -> float:
    r, g, b = (int(hexcolor[i:i + 2], 16) for i in (1, 3, 5))
    return 0.3 * r + 0.6 * g + 0.1 * b


def recipe_for(master: Path, meta: dict) -> dict:
    """Derive a full cover recipe from the master artwork plus the shelf entry."""
    im = Image.open(master).convert("RGB")
    gray = im.convert("L")
    seam = detect_seam(gray)
    front = im.crop((seam, 0, im.width, im.height))
    tone = sample_board(front)
    dark_board = luminance(tone) < 70

    fx0, fy0, fx1, fy1 = detect_motif(front, tone)
    # A wildly elongated detection is a detection failure, not a tall motif.
    if not (0.45 <= (fx1 - fx0) / max(1, fy1 - fy0) <= 2.6):
        fx0, fy0 = int(front.width * 0.14), int(front.height * 0.41)
        fx1, fy1 = int(front.width * 0.86), int(front.height * 0.79)
    box = (seam + fx0, fy0, seam + fx1, fy1)

    family = EAST if dark_board else WEST
    # Line work only, and never a mid-tone ink: a band ink fills the medallion's own tint as
    # a solid shape, which is what makes an unclipped motif read as a pasted rectangle. Ink
    # the engraving and let the board show through, the way the Meditations bust does.
    inks = [light()] if dark_board else [dark(core=50, ext=84, min_area=14,
                                              simplify=(6, 0.6))]
    # Size by BOTH dimensions. Scaling a tall motif by width alone is what made the
    # Hammurabi stele 1178 units high on a 1700-unit board — it filled the whole cover.
    bw, bh = box[2] - box[0], max(1, box[3] - box[1])
    aspect = bw / bh
    width = min(730 if aspect > 1.15 else 660, MAX_W, MAX_H * aspect)

    title = (meta.get("title") or master.stem.replace("-", " ")).upper()
    for prefix in ("LECTIO ", "HARVARD CLASSICS RED ", "HARVARD CLASSICS ", "EASTERN "):
        if title.startswith(prefix):
            title = title[len(prefix):]
    author = (meta.get("author") or "").upper()
    return dict(
        src=master, palette=board(family, tone),
        author=author,
        title=split_title(title),
        art=dict(box=box, width=width, dy=30, inks=inks, max_side=560),
    )


def split_title(title: str):
    """One line if it fits the block, otherwise two — never three."""
    if len(title) <= 13:
        return title
    words = title.split()
    best, score = None, 1e9
    for i in range(1, len(words)):
        a, b = " ".join(words[:i]), " ".join(words[i:])
        s = abs(len(a) - len(b)) + 3 * max(0, max(len(a), len(b)) - 15)
        if s < score:
            best, score = (a, b), s
    return best or title


# ---------------------------------------------------------------- the run

def build(stems: list[str], index: dict) -> list[tuple[str, int, int]]:
    OUT_SVG.mkdir(parents=True, exist_ok=True)
    made = []
    for stem in stems:
        master = MASTERS / f"{stem}.png"
        if not master.exists():
            print(f"  ! no master for {stem}", file=sys.stderr)
            continue
        spec = recipe_for(master, index.get(stem, {}))
        svg = OUT_SVG / f"{stem}.svg"
        svg.write_text(render(spec))

        jpg = OUT_JPG / f"{stem}.jpg"
        raster(svg, jpg)
        made.append((stem, svg.stat().st_size, jpg.stat().st_size))
        print(f"  {stem:<46} svg {svg.stat().st_size/1024:5.0f} KB   jpg "
              f"{jpg.stat().st_size/1024:4.0f} KB")
    return made


def raster(svg: Path, dest: Path) -> None:
    import subprocess
    import tempfile
    shim = HERE / "_planned.typ"
    shim.write_text("#set page(width: 5.5in, height: 8.5in, margin: 0pt)\n"
                    f'#image("/{svg.relative_to(ROOT).as_posix()}", width: 100%, height: 100%)\n')
    try:
        with tempfile.TemporaryDirectory() as td:
            png = Path(td) / "c.png"
            subprocess.run(["typst", "compile", "--root", str(ROOT), "--format", "png",
                            "--ppi", str(round(JPEG_HEIGHT / 8.5)), str(shim), str(png)],
                           check=True, capture_output=True)
            Image.open(png).convert("RGB").save(
                dest, "JPEG", quality=JPEG_QUALITY, optimize=True, progressive=True)
    finally:
        shim.unlink(missing_ok=True)


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--pilot", type=int, default=0, help="build an evenly spaced sample")
    ap.add_argument("stems", nargs="*")
    a = ap.parse_args()

    index = planned_index()
    all_stems = sorted(p.stem for p in MASTERS.glob("*.png"))
    published = {Path(b["src"]).stem for b in BOOKS.values()}
    stems = a.stems or [s for s in all_stems if s in index]
    if a.pilot:
        step = max(1, len(stems) // a.pilot)
        stems = stems[::step][:a.pilot]

    print(f"{len(stems)} planned covers (of {len(all_stems)} masters, "
          f"{len(published)} published works have their own recipe)")
    made = build(stems, index)
    if made:
        print(f"total svg {sum(m[1] for m in made)/1e6:.1f} MB   "
              f"jpg {sum(m[2] for m in made)/1e6:.1f} MB")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
