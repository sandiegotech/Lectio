#!/usr/bin/env python3
"""Set a Lectio cover in vector.

Every cover in the library is the same cover: one board, one frame, author over a
rubricated star, the title, one motif in a medallion at the centre, two rules down the
sides, and the same foot. That layout is LAYOUT below and it is not per-book. A recipe
carries only what is genuinely this book's — which motif, how it separates from its
ground, how big it sits, and which of the two series palettes it belongs to.

The artwork is traced out of the existing raster cover: crop the motif, threshold it off
the ground (dark on light, light on dark, or a mid-tone band under the black), drop the
speckles the paper texture leaves, upsample, potrace. Everything else is drawn geometry and
the type is live text — so the finished SVG scales and stays editable.

    brew install potrace
    python3 tools/print/covers/build_covers.py             # every recipe
    python3 tools/print/covers/build_covers.py iliad       # one
"""

from __future__ import annotations

import math
import subprocess
import sys
import tempfile
from collections import deque
from pathlib import Path

from PIL import Image, ImageFilter

ROOT = Path(__file__).resolve().parents[2]
HERE = Path(__file__).resolve().parent
W, H = 1100, 1700          # 5.5 x 8.5 at 200 units/inch


# ================================================================= the house style

# The two series palettes. The board tells you which tradition you are in before you read
# the title; everything else on the cover is identical, which is what makes them a set.
WEST = dict(paper="#c3b090", paper_lit="#cfbe9f", paper_edge="#bcaa8a",
            ink="#221f1c", rule="#7f6944", gold="#8a6f49", disc="#a88b5f", mid="#6f5f45")
EAST = dict(paper="#111721", paper_lit="#1a2230", paper_edge="#0b0f16",
            ink="#c2a05c", rule="#9d7f45", gold="#c2a05c", disc="#1e2836", mid="#7c6434")

# One layout, shared by every cover.
LAYOUT = dict(
    author=dict(y=268, size=46, track=8),
    star=dict(y=312, r=26, rules=(300, 486, 614, 800)),
    title=dict(y=424, size=104, track=7),           # one line
    title2=dict(y=(392, 496), size=84, track=7),    # two lines
    disc=dict(cx=550, cy=850, r=318),
    rails=dict(x=(121, 977), y=(632, 1140)),
    sub=dict(t="A NEW TRANSLATION", y=1348, size=34, track=11),
    rule=dict(y=1400, x=(275, 825), w=0.9),
    laurel=dict(y=1524, span=260),
    foot=dict(t="LECTIO EDITION 2026", y=1590, size=32, track=10),
)


def work(slug: str) -> Path:
    """The original raster artwork a cover is traced from.

    Deliberately NOT content/works/<id>/cover.jpg: that file is now generated from these
    covers (export_app_covers.py), so tracing it would feed the pipeline its own output.
    """
    return HERE / "source" / f"{slug}.jpg"


def _hex(rgb) -> str:
    return "#%02x%02x%02x" % tuple(max(0, min(255, int(round(v)))) for v in rgb)


def _rgb(h: str):
    return tuple(int(h[i:i + 2], 16) for i in (1, 3, 5))


def mix(a: str, b: str, t: float) -> str:
    ra, rb = _rgb(a), _rgb(b)
    return _hex(ra[i] + (rb[i] - ra[i]) * t for i in range(3))


def board(family: dict, sample: str, t: float = 0.45) -> dict:
    """A board of its own.

    Every cover shares one ink, one rubrication red-brown and one gold; only the board
    shifts, pulled part of the way from the family paper toward the tone of this book's
    own artwork. Enough that a shelf of them looks pressed rather than generated, not so
    much that they stop being a set. The medallion follows the board it sits on.
    """
    paper = mix(family["paper"], sample, t)
    return dict(family,
                paper=paper,
                paper_lit=mix(paper, "#ffffff", 0.10),
                paper_edge=mix(paper, "#000000", 0.06),
                disc=mix(paper, family["disc"], 0.72))


def dark(core=80, ext=110, min_area=18, simplify=(5, 0.5)):
    """Line work on a light board."""
    return dict(kind="dark", core=core, ext=ext, color="ink",
                min_area=min_area, simplify=simplify)


def light(core=96, ext=68, min_area=16, simplify=(7, 0.7)):
    """Gold stamped on dark cloth."""
    return dict(kind="light", core=core, ext=ext, color="gold",
                min_area=min_area, simplify=simplify)


def midtone(core=(80, 142), ext=(70, 152), color="mid", min_area=26, simplify=(9, 0.9)):
    """The hatch of a tonal engraving, printed under the black line work."""
    return dict(kind="band", core=core, ext=ext, color=color,
                min_area=min_area, simplify=simplify)


# A recipe is: the motif, how it separates, how big it sits, and which series it is in.
BOOKS = {
    "meditations": dict(
        src=work("work.marcus-aurelius.meditations"), palette=board(WEST, "#c3b090"),
        author="MARCUS AURELIUS", title="MEDITATIONS",
        art=dict(box=(225, 395, 795, 1075), width=756, dy=80, inks=[dark()])),

    "iliad": dict(
        src=work("work.homer.iliad"), palette=dict(board(WEST, "#d9c9a5"), accent="#a35f2c"),
        author="HOMER", title="THE ILIAD",
        art=dict(box=(330, 445, 700, 1080), width=470, dy=0,
                 inks=[midtone(core=(62, 132), ext=(48, 150), color="accent"),
                       dark(core=40, ext=78, min_area=14)])),

    "odyssey": dict(
        src=work("work.homer.odyssey"), palette=board(WEST, "#cdb890"),
        author="HOMER", title="THE ODYSSEY",
        art=dict(box=(150, 470, 875, 1105), width=720, dy=20,
                 inks=[dark(core=68, ext=112, simplify=(7, 0.7))])),

    "aeneid": dict(
        src=work("work.virgil.aeneid"), palette=board(WEST, "#c8ae80"),
        author="VIRGIL", title="THE AENEID",
        art=dict(box=(130, 480, 895, 1170), width=740, dy=10,
                 inks=[midtone(), dark(core=48, ext=78, min_area=16, simplify=(7, 0.7))])),

    "republic": dict(
        src=work("work.plato.republic"), palette=board(WEST, "#ccb88f"),
        author="PLATO", title="THE REPUBLIC",
        art=dict(box=(150, 470, 880, 1140), width=720, dy=10,
                 inks=[midtone(core=(82, 145), ext=(72, 155)),
                       dark(core=50, ext=80, min_area=16, simplify=(7, 0.7))])),

    "the-prince": dict(
        src=work("work.machiavelli.the-prince"), palette=board(WEST, "#c4ac7f"),
        author="NICCOLO MACHIAVELLI", title="THE PRINCE",
        art=dict(box=(250, 480, 810, 1100), width=720, dy=20,
                 inks=[dark(core=50, ext=86, min_area=14, simplify=(6, 0.6))])),

    "nicomachean-ethics": dict(
        src=work("work.aristotle.nicomachean-ethics"), palette=board(WEST, "#c2a06c"),
        author="ARISTOTLE", title=("NICOMACHEAN", "ETHICS"),
        art=dict(box=(245, 565, 800, 1140), width=700, dy=20,
                 inks=[dark(core=52, ext=88, min_area=14, simplify=(6, 0.6))])),

    "confessions": dict(
        src=work("work.augustine.confessions"), palette=board(WEST, "#cfbe97"),
        author="SAINT AUGUSTINE", title="CONFESSIONS",
        art=dict(box=(265, 445, 800, 1070), width=720, dy=10,
                 inks=[dark(core=48, ext=84, min_area=14, simplify=(6, 0.6))])),

    "gilgamesh": dict(
        src=work("work.gilgamesh"), palette=board(EAST, "#141c27"),
        author="SUMER & AKKAD", title=("THE EPIC OF", "GILGAMESH"),
        art=dict(box=(258, 560, 790, 1090), width=640, dy=0, inks=[light()])),

    "analects": dict(
        src=work("work.confucius.analects"), palette=board(EAST, "#0b1016"),
        author="CONFUCIUS", title="THE ANALECTS",
        art=dict(box=(200, 590, 855, 1148), width=730, dy=20,
                 inks=[light(core=92, ext=64)])),
}


def variant(base: str, **over) -> dict:
    """Another edition of the same cover — usually just the wording."""
    return dict(BOOKS[base], **over)


BOOKS["meditations-es"] = variant("meditations", author="MARCO AURELIO",
                                  title="MEDITACIONES",
                                  sub="UNA NUEVA TRADUCCIÓN",
                                  foot="EDICIÓN LECTIO 2026")


# ================================================================= tracing

def _components(w, h, ext, core, min_area):
    """Hysteresis + speckle removal: keep a blob only if it reaches the strict threshold."""
    seen = bytearray(w * h)
    keep = bytearray(w * h)
    nb = (-w - 1, -w, -w + 1, -1, 1, w - 1, w, w + 1)
    for i in range(w * h):
        if not ext[i] or seen[i]:
            continue
        comp, q, has_core = [], deque([i]), False
        seen[i] = 1
        while q:
            j = q.popleft()
            comp.append(j)
            has_core = has_core or core[j]
            x = j % w
            for d in nb:
                k = j + d
                if 0 <= k < w * h and not seen[k] and ext[k] and abs(k % w - x) <= 1:
                    seen[k] = 1
                    q.append(k)
        if has_core and len(comp) >= min_area:
            for j in comp:
                keep[j] = 1
    return keep


def trace_ink(img: Image.Image, ink: dict, max_side: int | None = None) -> str:
    """One ink of the artwork -> potrace paths (in the cropped image's own coordinates)."""
    if max_side and max(img.size) > max_side:
        k = max_side / max(img.size)
        img = img.resize((max(1, round(img.width * k)), max(1, round(img.height * k))),
                         Image.LANCZOS)
    w, h = img.size
    rgb = list(img.getdata())
    lum = [(3 * r + 6 * g + b) // 10 for r, g, b in rgb]

    kind = ink["kind"]
    if kind == "dark":
        ext = [v < ink["ext"] for v in lum]
        core = [v < ink["core"] for v in lum]
    elif kind == "light":
        ext = [v > ink["ext"] for v in lum]
        core = [v > ink["core"] for v in lum]
    elif kind == "band":
        # A second ink on warm paper does not separate by hue — the paper is warm too —
        # but it does sit in its own luminance band between the black and the ground.
        clo, chi = ink["core"]
        elo, ehi = ink["ext"]
        core = [clo < v < chi for v in lum]
        ext = [elo < v < ehi for v in lum]
    else:
        raise ValueError(kind)

    keep = _components(w, h, ext, core, ink.get("min_area", 14))
    mask = Image.new("L", (w, h))
    mask.putdata([0 if keep[i] else 255 for i in range(w * h)])
    big = mask.resize((w * 3, h * 3), Image.LANCZOS).filter(ImageFilter.GaussianBlur(1.0))
    binary = big.point(lambda p: 0 if p < 128 else 255).convert("1")

    with tempfile.TemporaryDirectory() as td:
        bmp, svg = Path(td) / "p.bmp", Path(td) / "p.svg"
        binary.save(bmp)
        # Dense tonal art traces to a lot of path data; `simplify` trades detail for size.
        turd, opttol = ink.get("simplify", (5, 0.5))
        subprocess.run(["potrace", "-s", "--turdsize", str(turd), "--alphamax", "1.0",
                        "--opttolerance", str(opttol), str(bmp), "-o", str(svg)], check=True)
        traced = svg.read_text()
    return traced[traced.index("<g transform"):traced.rindex("</g>") + 4]


# ================================================================= drawing

def leaf(cx, cy, rx, ry, angle, fill) -> str:
    return (f'<ellipse cx="0" cy="0" rx="{rx:.1f}" ry="{ry:.1f}" fill="{fill}" '
            f'transform="translate({cx:.1f} {cy:.1f}) rotate({angle:.1f})"/>')


def laurel(cx, cy, span, fill) -> str:
    """Two branches sweeping up and outward from a common stem."""
    out = []
    for side in (-1, 1):
        x0, y0 = cx, cy
        x1, y1 = cx + side * span * 0.26, cy - span * 0.06
        x2, y2 = cx + side * span * 0.48, cy - span * 0.30
        out.append(f'<path d="M{x0:.1f} {y0:.1f} Q{x1:.1f} {y1:.1f} {x2:.1f} {y2:.1f}" '
                   f'fill="none" stroke="{fill}" stroke-width="{span*0.011:.1f}" '
                   f'stroke-linecap="round"/>')
        for i in range(6):
            t = 0.22 + 0.78 * i / 5
            bx = (1 - t) ** 2 * x0 + 2 * (1 - t) * t * x1 + t ** 2 * x2
            by = (1 - t) ** 2 * y0 + 2 * (1 - t) * t * y1 + t ** 2 * y2
            tx = 2 * (1 - t) * (x1 - x0) + 2 * t * (x2 - x1)
            ty = 2 * (1 - t) * (y1 - y0) + 2 * t * (y2 - y1)
            ang = math.degrees(math.atan2(ty, tx)) - side * 48
            half = span * (0.075 - 0.022 * t)
            a = math.radians(ang)
            out.append(leaf(bx + math.cos(a) * half, by + math.sin(a) * half,
                            half, half * 0.33, ang, fill))
    return "".join(out)


def palmette(cx, cy, span, fill) -> str:
    """A small spread fan — the tail-piece under a subtitle."""
    out = [f'<path d="M{cx-span*0.5:.1f} {cy:.1f} Q{cx:.1f} {cy+span*0.10:.1f} '
           f'{cx+span*0.5:.1f} {cy:.1f}" fill="none" stroke="{fill}" '
           f'stroke-width="{span*0.022:.1f}" stroke-linecap="round"/>']
    for i in range(5):
        f = (i - 2) / 2
        ang = -90 + f * 46
        a = math.radians(ang)
        half = span * (0.20 - 0.05 * abs(f))
        out.append(leaf(cx + f * span * 0.19 + math.cos(a) * half,
                        cy + math.sin(a) * half, half, half * 0.30, ang, fill))
    return "".join(out)


def fleuron(cx, cy, size, fill, flip=1) -> str:
    out = [leaf(cx, cy + flip * size * 0.95, size * 0.95, size * 0.20, 90, fill)]
    for side in (-1, 1):
        out.append(leaf(cx + side * size * 0.26, cy + flip * size * 0.40,
                        size * 0.46, size * 0.16, 90 + side * flip * 26, fill))
    return "".join(out)


def star(cx, cy, r, fill, points=4) -> str:
    pts = []
    for i in range(points * 2):
        a = math.radians(i * 180 / points - 90)
        rad = r if i % 2 == 0 else r * 0.22
        pts.append(f"{cx + rad * math.cos(a):.1f},{cy + rad * math.sin(a):.1f}")
    return f'<polygon points="{" ".join(pts)}" fill="{fill}"/>'


def rule(x1, y1, x2, y2, color, width) -> str:
    return (f'<line x1="{x1:.1f}" y1="{y1:.1f}" x2="{x2:.1f}" y2="{y2:.1f}" '
            f'stroke="{color}" stroke-width="{width}"/>')


def fit(text: str, size: float, track: float, max_w: float) -> float:
    """Shrink a line until it fits the block. Nothing on a cover may run off the board."""
    n = max(1, len(text))
    est = n * size * 0.62 + track * (n - 1)
    return size if est <= max_w else size * max_w / est


def caps(text, y, size, fill, track, weight="400") -> str:
    text = text.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")
    cx = W / 2 + float(track) / 2      # letter-spacing adds a trailing gap; take half back
    return (f'<text x="{cx:.1f}" y="{y}" text-anchor="middle" fill="{fill}" '
            f'font-family="New York, Iowan Old Style, Palatino, Georgia, serif" '
            f'font-size="{size}" font-weight="{weight}" letter-spacing="{track}" '
            f'>{text}</text>')


# ================================================================= assembly

def render(book: dict) -> str:
    pal = dict(book["palette"])
    pal.setdefault("accent", pal["ink"])
    pal.setdefault("disc_hatch", "#8a7448")
    C = lambda k: pal[k]
    L = LAYOUT

    art = book.get("art")
    if art:
        img = Image.open(book["src"]).convert("RGB")
        crop = img.crop(art["box"])
        aw = art["width"]
        ah = aw * crop.height / crop.width
        ax = W / 2 - aw / 2
        ay = L["disc"]["cy"] + art.get("dy", 0) - ah / 2
        # trace_ink may work at a reduced resolution; the paths come back in that space.
        eff_w = crop.width
        ms = art.get("max_side")
        if ms and max(crop.size) > ms:
            eff_w = round(crop.width * ms / max(crop.size))
        scale = aw / (eff_w * 3)

    out = [f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {W} {H}" '
           f'width="{W}" height="{H}">',
           f'''<defs>
  <radialGradient id="ground" cx="50%" cy="44%" r="72%">
    <stop offset="0%" stop-color="{C('paper_lit')}"/>
    <stop offset="62%" stop-color="{C('paper')}"/>
    <stop offset="100%" stop-color="{C('paper_edge')}"/>
  </radialGradient>
</defs>''',
           f'<rect width="{W}" height="{H}" fill="url(#ground)"/>',
           f'<rect x="46" y="46" width="{W-92}" height="{H-92}" fill="none" '
           f'stroke="{C("rule")}" stroke-width="2.4"/>',
           f'<rect x="59" y="59" width="{W-118}" height="{H-118}" fill="none" '
           f'stroke="{C("rule")}" stroke-width="0.9" stroke-opacity="0.75"/>']

    # medallion, then the traced motif over it
    d = L["disc"]
    out.append(f'<circle cx="{d["cx"]}" cy="{d["cy"]}" r="{d["r"]}" fill="{C("disc")}"/>')
    if not art:
        # A shell with no artwork yet: the medallion carries the mark instead, so the card
        # reads as a quiet member of the set rather than a hole in the shelf.
        out.append(star(W / 2, d["cy"], 62, C("gold")))
        out.append(f'<circle cx="{W/2}" cy="{d["cy"]}" r="{d["r"]*0.62:.0f}" fill="none" '
                   f'stroke="{C("gold")}" stroke-width="1.1" stroke-opacity="0.5"/>')
    if art and art.get("clip"):
        out.append(f'<clipPath id="med"><circle cx="{d["cx"]}" cy="{d["cy"]}" '
                   f'r="{d["r"]}"/></clipPath><g clip-path="url(#med)">')
    if art:
        out.append(f'<g transform="translate({ax:.1f} {ay:.1f}) scale({scale:.5f})">')
        for ink in art["inks"]:                # first ink first: it sits underneath
            out.append(trace_ink(crop, ink, art.get("max_side"))
                       .replace('fill="#000000"', f'fill="{C(ink["color"])}"'))
        out.append('</g>')
        if art.get("clip"):
            out.append('</g>')

    # the rails
    r = L["rails"]
    for x in r["x"]:
        out.append(rule(x, r["y"][0], x, r["y"][1], C("gold"), 1.6))
        out.append(fleuron(x, r["y"][0], 30, C("gold"), flip=-1))
        out.append(fleuron(x, r["y"][1], 30, C("gold"), flip=1))

    # author, star, title
    a = L["author"]
    if book["author"]:          # an anonymous work simply has no author line
        out.append(caps(book["author"], a["y"],
                        fit(book["author"], a["size"], a["track"], 780),
                        C("ink"), a["track"]))
    st = L["star"]
    x1, x2, x3, x4 = st["rules"]
    out.append(rule(x1, st["y"], x2, st["y"], C("rule"), 1.4))
    out.append(rule(x3, st["y"], x4, st["y"], C("rule"), 1.4))
    out.append(star(W / 2, st["y"], st["r"], C("rule")))

    title = book["title"]
    if isinstance(title, str):
        t = L["title"]
        size = fit(title, t["size"], t["track"], 900)
        out.append(caps(title, t["y"], size, C("ink"), t["track"], weight="500"))
    else:
        t = L["title2"]
        size = min(fit(line, t["size"], t["track"], 900) for line in title)
        for line, y in zip(title, t["y"]):
            out.append(caps(line, y, size, C("ink"), t["track"], weight="500"))

    # foot
    sub, ru, la, fo = L["sub"], L["rule"], L["laurel"], L["foot"]
    out.append(caps(book.get("sub", sub["t"]), sub["y"], sub["size"], C("ink"), sub["track"]))
    out.append(rule(ru["x"][0], ru["y"], ru["x"][1], ru["y"], C("rule"), ru["w"]))
    out.append(laurel(W / 2, la["y"], la["span"], C("gold")))
    out.append(caps(book.get("foot", fo["t"]), fo["y"], fo["size"], C("gold"), fo["track"]))

    out.append('</svg>')
    return "\n".join(out) + "\n"


def main() -> int:
    want = sys.argv[1:] or [k for k in BOOKS if k != "meditations-es"]
    for slug in want:
        if slug not in BOOKS:
            print(f"no recipe for {slug}; have {', '.join(BOOKS)}", file=sys.stderr)
            return 2
        out = HERE / f"{slug}.svg"
        out.write_text(render(BOOKS[slug]))
        print(f"{out.relative_to(ROOT)}  ({out.stat().st_size/1024:.0f} KB)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
