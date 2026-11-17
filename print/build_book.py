#!/usr/bin/env python3
"""Set a Lectio edition as a print-ready book (PDF), straight from the content bundle.

The bundle is the single source of truth: the same text, book arguments, provenance and
translation notes the app reads. Nothing here is hand-typed prose about the book — every
line of content comes out of content/, or out of an --overlay for editions that do not
live in the bundle yet.

    python3 tools/print/build_book.py                       # Meditations, Lectio Edition
    python3 tools/print/build_book.py --paper parchment     # warm-paper screen variant
    python3 tools/print/build_book.py --overlay tools/print/experiments/meditations-es.json

Requires typst (brew install typst).
"""

from __future__ import annotations

import argparse
import json
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CONTENT = ROOT / "content"
OUT = Path(__file__).resolve().parent / "out"

# "The Margin" palette (app/Lectio/Theme.swift, Palette.natural).
INK = "#26221A"
SOFT = "#6B6355"
ACCENT = "#9E3B2E"
GOLD = "#B98A2E"
PARCHMENT = "#F4EEE1"

ROMAN = ["", "I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X", "XI", "XII",
         "XIII", "XIV", "XV", "XVI", "XVII", "XVIII", "XIX", "XX", "XXI", "XXII",
         "XXIII", "XXIV"]

# Every word of chrome on the page. An edition prints in one language throughout, so the
# furniture is keyed by --lang; an overlay may override any single string.
STRINGS = {
    "en": {
        "book": "Book",
        "contents": "Contents",
        "introduction": "Introduction",
        "edition_line": "The Lectio Edition",
        "imprint": "San Diego Institute of Technology",
        "colophon_imprint": "San Diego Institute of Technology",
        "rights_1": "{title} — the Lectio Edition.",
        "rights_2": "Produced {date} · model {model} · vintage {vintage}. Every edition in "
                    "Lectio carries its provenance; see #emph[{note_title}] at the back of this book.",
        "rights_3": "The historical translations and the original from which this edition was made "
                    "are in the public domain. This rendering is Lectio's own edition, derived from "
                    "those public-domain sources — not a historical translation.",
        "rights_4": "Set from the Lectio content bundle. Text, book arguments and notes are "
                    "identical to those in the Lectio app.",
        "rights_5": "Published by the San Diego Institute of Technology, a 501(c)(3) nonprofit · "
                    "San Diego, California · sandiegotech.org/lectio",
        "rights_6": "The Lectio Edition text is released under CC BY-NC 4.0 — free to read, share, "
                    "quote, and teach from, with attribution; commercial rights reserved to the "
                    "Institute, whose printed editions fund the work. "
                    "creativecommons.org/licenses/by-nc/4.0",
        "note_edition": "A Note on This Edition",
        "how_made": "How it was made",
        "sources": "Sources consulted",
        "provenance": "Provenance",
        "row_edition": "Edition",
        "row_model": "Model",
        "row_produced": "Produced",
        "row_tokens": "Tokens used",
        "row_base": "Base text",
        "row_reference": "Reference",
        "row_translator": "Translator",
        "row_rights": "Rights",
        "row_source": "Source",
        "row_older": "Older",
        "row_lectio": "Lectio",
        "tokens_fmt": "≈ {n} (estimated)",
        "numbering_note": "#emph[On the numbering.] The sections are numbered as they fall in this "
                          "edition, book by book. They follow the traditional divisions closely, but "
                          "the Lectio Edition sets some runs of short sayings and quoted fragments as "
                          "sections of their own, so the counts can part company with the older "
                          "numbering toward the end of a book. Where you need to cite by the standard "
                          "reference, check the passage against a historical translation — in the app, "
                          "the Compare panel puts them side by side.",
        "differs": "Where This Edition Differs",
        "differs_lede": "Places where the Lectio Edition departs from the older translations, and why.",
        "compare": "The Same Passage, Four Ways",
        "compare_lede": "Book {book}, section {sec}, in every edition Lectio carries for this work — "
                        "the modern rendering you have just read, the historical translations, and the "
                        "original. In the app these sit side by side, aligned line for line; here they "
                        "are set one after another.",
        "this_edition": "The Lectio Edition",
        "modern_other": "The Lectio Edition",
        "original_head": "The original",
        "editions": "The Other Editions in Lectio",
        "editions_lede": "Every work in Lectio carries its modern edition and the public-domain texts "
                         "behind it. The reader moves freely between them; they are listed here as "
                         "they stand in the library.",
        "threads": "Where This Book Leads",
        "threads_lede": "The threads Lectio draws from this work to others in the library.",
        "themes": "Themes",
        "whoswho": "Who's who in Book I",
        "colophon": "Colophon",
        "colophon_1": "{title} — the Lectio Edition — was set from the Lectio content bundle: "
                      "{books} books, {secs} sections, the same text the reader carries.",
        "colophon_2": "The text is {font}, Apple's serif, the face the app reads in. Headings and "
                      "running heads are letterspaced small capitals; the section figures and rubrics "
                      "are set in a single rubrication red, after the medieval practice the design "
                      "language is named for. Trim {w} × {h} inches.",
    },
    "es": {
        "book": "Libro",
        "contents": "Contenido",
        "introduction": "Introducción",
        "edition_line": "La Edición Lectio",
        "imprint": "San Diego Institute of Technology",
        "colophon_imprint": "San Diego Institute of Technology",
        "rights_1": "{title} — la Edición Lectio.",
        "rights_2": "Producida el {date} · modelo {model} · añada {vintage}. Cada edición de Lectio "
                    "lleva consigo su procedencia; véase #emph[{note_title}] al final de este libro.",
        "rights_3": "Las traducciones históricas y el original de los que procede esta edición son de "
                    "dominio público. Esta versión es una edición propia de Lectio, derivada de esas "
                    "fuentes de dominio público — no es una traducción histórica.",
        "rights_4": "Compuesta a partir del corpus de contenido de Lectio.",
        "rights_5": "Publicado por el San Diego Institute of Technology, organización sin fines de "
                    "lucro 501(c)(3) · San Diego, California · sandiegotech.org/lectio",
        "rights_6": "El texto de la Edición Lectio se publica bajo CC BY-NC 4.0 — libre para leer, "
                    "compartir, citar y enseñar, con atribución; los derechos comerciales quedan "
                    "reservados al Instituto. creativecommons.org/licenses/by-nc/4.0",
        "note_edition": "Nota sobre esta edición",
        "how_made": "Cómo se hizo",
        "sources": "Fuentes consultadas",
        "provenance": "Procedencia",
        "row_edition": "Edición",
        "row_model": "Modelo",
        "row_produced": "Producida",
        "row_tokens": "Tokens",
        "row_base": "Texto base",
        "row_reference": "Referencia",
        "row_translator": "Traductor",
        "row_rights": "Derechos",
        "row_source": "Fuente",
        "row_older": "Antes",
        "row_lectio": "Lectio",
        "tokens_fmt": "≈ {n} (estimado)",
        "numbering_note": "#emph[Sobre la numeración.] Las secciones van numeradas tal como caen en "
                          "esta edición, libro por libro. Siguen de cerca las divisiones tradicionales, "
                          "pero la Edición Lectio presenta algunas series de sentencias breves y de "
                          "fragmentos citados como secciones aparte, de modo que las cuentas pueden "
                          "separarse de la numeración antigua hacia el final de un libro. Si necesitas "
                          "citar a Marco Aurelio por la referencia habitual, coteja el pasaje con una "
                          "traducción histórica.",
        "differs": "En qué se aparta esta edición",
        "differs_lede": "Lugares donde la Edición Lectio se aparta de las traducciones antiguas, y por qué.",
        "compare": "El mismo pasaje, de cuatro maneras",
        "compare_lede": "Libro {book}, sección {sec}, en todas las ediciones que Lectio conserva de "
                        "esta obra: la versión moderna que acabas de leer, las traducciones históricas "
                        "al inglés y el griego de Marco Aurelio. En la aplicación aparecen una junto a "
                        "otra, alineadas línea por línea; aquí van una tras otra.",
        "this_edition": "La Edición Lectio en español",
        "modern_other": "La Edición Lectio en inglés",
        "original_head": "El original griego",
        "editions": "Las otras ediciones en Lectio",
        "editions_lede": "Cada obra de Lectio lleva su edición moderna y los textos de dominio público "
                         "que hay detrás. El lector pasa libremente de una a otra; aquí se enumeran "
                         "tal como están en la biblioteca.",
        "threads": "Adónde lleva este libro",
        "threads_lede": "Los hilos que Lectio tiende desde esta obra hacia otras de la biblioteca.",
        "themes": "Temas",
        "whoswho": "Quién es quién en el Libro I",
        "colophon": "Colofón",
        "colophon_1": "{title} — la Edición Lectio — se compuso a partir del corpus de contenido de "
                      "Lectio: {books} libros, {secs} secciones.",
        "colophon_2": "El texto va en {font}, la serif de Apple, la misma letra con la que lee la "
                      "aplicación. Los títulos y los folios llevan versalitas espaciadas; las cifras de "
                      "sección y las rúbricas van en un solo rojo de rubricación, según la práctica "
                      "medieval que da nombre al lenguaje de diseño. Formato {w} × {h} pulgadas.",
    },
}


# ---------------------------------------------------------------- text hygiene

def smarten(s: str) -> str:
    """Straight quotes -> typographic quotes; a few print-typography niceties."""
    out = []
    for i, ch in enumerate(s):
        prev = s[i - 1] if i else ""
        if ch == '"':
            out.append("“" if (prev == "" or prev in " \t([—‘“-") else "”")
        elif ch == "'":
            out.append("‘" if (prev == "" or prev in " \t([—“-") else "’")
        else:
            out.append(ch)
    t = "".join(out)
    t = t.replace("...", "…")
    return t


def tq(s: str) -> str:
    """Escape a Python string for a Typst string literal."""
    return '"' + s.replace("\\", "\\\\").replace('"', '\\"') + '"'


def tqs(s: str) -> str:
    return tq(smarten(s))


_SPECIAL = set("\\#$*_`<>@[]~=")


def mk(s: str) -> str:
    """Bundle text -> Typst markup: nothing in the text may act as markup.

    The one exception is the _underscore italics_ that survive in the Gutenberg-sourced
    historical translations — those become real italics, since that is what they mean.
    """
    def esc(t: str) -> str:
        t = "".join("\\" + c if c in _SPECIAL else c for c in t)
        # "16." opening a paragraph would otherwise start a numbered list.
        return re.sub(r"^(\s*\d+)\.", r"\1\\.", t)

    parts = re.split(r"_([^_\n]+)_", smarten(s))
    return "".join(esc(p) if i % 2 == 0 else "#emph[" + esc(p) + "]"
                   for i, p in enumerate(parts))


# ---------------------------------------------------------------- bundle access

def load_work(work_id: str):
    wdir = CONTENT / "works" / work_id
    work = json.loads((wdir / "work.json").read_text())
    editions = {}
    for f in sorted((wdir / "editions").glob("*.json")):
        ed = json.loads(f.read_text())
        editions[ed["id"]] = ed
    enrich = {}
    ef = wdir / "enrichment.json"
    if ef.exists():
        enrich = json.loads(ef.read_text())
    explore = None
    xf = CONTENT / "explore.json"
    if xf.exists():
        for rec in json.loads(xf.read_text()).get("records", []):
            if rec.get("title") == work["title"]:
                explore = rec
                break
    return wdir, work, editions, enrich, explore


def merge(base: dict, over: dict) -> dict:
    """Recursive dict merge — the overlay wins, lists replace wholesale."""
    out = dict(base or {})
    for k, v in (over or {}).items():
        out[k] = merge(out[k], v) if isinstance(v, dict) and isinstance(out.get(k), dict) else v
    return out


def spine_key(v: str):
    return tuple(int(p) if p.isdigit() else p for p in v.split("."))


def overlaps(seg, lo, hi) -> bool:
    sp = seg.get("spine")
    if not sp:
        return False
    return not (spine_key(sp["to"]) < lo or spine_key(sp["from"]) > hi)


_STOP = frozenset("""
    the and of to a in that is it for with as be are will not or but on at from
    which what into unto upon shall may can his her their there then than this
    these those thou thy thee hath doth were was have has had they them your you
""".split())


def content_words(text: str) -> set:
    """Longish lexical words — a cheap fingerprint for 'is this the same passage?'."""
    return {w for w in re.findall(r"[a-z']+", text.lower())
            if len(w) >= 5 and w not in _STOP}


def near_spine(seg, key, slack: int) -> bool:
    """Within `slack` minor units of `key` in the same major unit (book/canto)."""
    sp = seg.get("spine")
    if not sp:
        return False
    a, b = spine_key(sp["from"]), spine_key(sp["to"])
    if a[:-1] != key[:-1] or b[:-1] != key[:-1]:
        return False
    lo, hi, n = a[-1], b[-1], key[-1]
    if not all(isinstance(v, int) for v in (lo, hi, n)):
        return False
    return lo - slack <= n <= hi + slack


def passage_across_editions(editions, ed_id, locus):
    """The same passage in every edition: spine overlap first, refined by shared
    vocabulary with the printed edition's text — the v1 spine is proportional, so a
    historical edition's segment for a locus can sit a section or two off."""
    key = lo = hi = spine_key(locus)
    rows = []
    ref_words: set = set()
    order = [ed_id] + [i for i in editions if i != ed_id]
    for eid in order:
        ed = editions.get(eid)
        if not ed:
            continue
        segs = [g for s in ed["sections"] for g in s["segments"]]
        hits = [g for g in segs if overlaps(g, lo, hi)]
        # Other editions: among nearby segments, prefer the one that actually shares
        # the passage's vocabulary (skipped when nothing scores — e.g. the Greek).
        if eid != ed_id and ref_words:
            cands = [g for g in segs if near_spine(g, key, 3)] or hits
            scored = max(cands, default=None,
                         key=lambda g: len(ref_words & content_words(g["text"])))
            if scored is not None and len(ref_words & content_words(scored["text"])) >= 3:
                hits = [scored]
        if not hits:
            continue
        text = " ".join(h["text"] for h in hits)
        if len(text) > 900:  # a spine cell that swallowed a run of paragraphs
            text = text[:900].rsplit(" ", 1)[0] + "…"
        if eid == ed_id:
            ref_words = content_words(text)
        rows.append((ed, text))
    return rows


def edition_head(e2, printed_id, S, sep=", "):
    """What an edition is called in the back matter."""
    if e2["id"] == printed_id:
        return S["this_edition"]
    if e2.get("kind") == "original" or e2.get("language") == "grc":
        return S["original_head"]
    who = e2.get("translator")
    if who:
        return f"{who}{sep}{e2.get('publishedYear', '')}".strip()
    return S["modern_other"]


# ---------------------------------------------------------------- the typesetting

PREAMBLE = r"""
// ---------------------------------------------------------------------------
// Lectio — print edition. Generated by tools/print/build_book.py; do not edit.
// Design language: "The Margin" (warm ink, one rubrication red, serif text).
// ---------------------------------------------------------------------------

#let ink = rgb("%(ink)s")
#let soft = rgb("%(soft)s")
#let accent = rgb("%(accent)s")
#let gold = rgb("%(gold)s")
#let paper = %(paper)s
#let bodyfont = "%(bodyfont)s"

#set document(title: %(doctitle)s, author: %(docauthor)s)

#set page(
  width: %(pw)s, height: %(ph)s,
  margin: (inside: %(mi)s, outside: %(mo)s, top: %(mt)s, bottom: %(mb)s),
  binding: left,
  fill: paper,
)
#set text(font: bodyfont, size: %(bodysize)s, fill: ink, lang: "%(lang)s", hyphenate: true,
          number-type: "old-style")
#set par(justify: true, leading: %(leading)s, spacing: %(leading)s, linebreaks: "optimized")

// Letterspaced small caps — used for running heads, labels and rubrics.
#let rubric(body, size: 8pt, fill: soft, track: 0.16em) = text(
  size: size, fill: fill, tracking: track, weight: "regular", number-type: "lining",
)[#smallcaps(body)]

#let hairline(w: 100%%, c: soft, t: 0.4pt) = line(length: w, stroke: t + c)

// A centred ornament between movements of the back matter.
#let ornament = align(center)[#v(6pt) #text(fill: gold, size: 9pt)[\u{2767}] #v(6pt)]

// --- running heads --------------------------------------------------------
// Verso carries the work, recto the book (or the back-matter section) you are in.
// Both are suppressed on any page that opens one, as in a printed edition.
#let worktitle = %(doctitle)s
#let rh = state("runhead", none)
#let openmark = metadata("lectio-open")

#let runhead = context {
  let p = here().page()
  if query(metadata.where(value: "lectio-open")).any(m => m.location().page() == p) { return none }
  let cur = rh.get()
  if cur == none { return none }
  let folio = text(size: 8.5pt, fill: soft, number-type: "lining")[#counter(page).display()]
  set align(if calc.even(p) { left } else { right })
  if calc.even(p) { box[#folio #h(0.9em) #rubric(worktitle, size: 7.6pt)] }
  else { box[#rubric(cur, size: 7.6pt) #h(0.9em) #folio] }
}

// --- book opening ---------------------------------------------------------
#show heading.where(level: 1): it => {
  openmark
  set align(center)
  v(%(openerdrop)s)
  block(spacing: 0pt)[
    #rubric(%(booklabel)s, size: 8pt, fill: soft, track: 0.34em)
    #v(6pt)
    #text(size: 30pt, fill: accent, font: bodyfont, number-type: "lining")[#it.body]
  ]
  v(11pt)
  align(center, hairline(w: 22%%, c: gold, t: 0.5pt))
  v(11pt)
}

#let booktitle(t) = {
  align(center, block(width: 74%%)[
    #set par(justify: false, leading: 0.62em)
    #text(size: 14pt, style: "italic", fill: ink)[#t]
  ])
  v(9pt)
}

// The "argument": the editorial note on what this book holds (from enrichment.json).
#let argument(t) = {
  align(center, block(width: 78%%)[
    #set par(justify: false, leading: 0.72em)
    #text(size: 8.8pt, style: "italic", fill: soft)[#t]
  ])
  v(20pt)
}

// --- a numbered section of the text --------------------------------------
#let sec(n, paras) = {
  block(spacing: %(secgap)s)[
    #set par(first-line-indent: (amount: 1.1em, all: true))
    #for (i, p) in paras.enumerate() [
      #if i == 0 [
        #par(first-line-indent: 0em)[#box[#text(
            size: 8.4pt, fill: accent, number-type: "lining", tracking: 0.02em)[#n]]#h(0.62em)#p]
      ] else [#p]
    ]
  ]
}

// --- front & back matter --------------------------------------------------
#let matter-title(t, drop: %(mattertop)s) = {
  openmark
  rh.update(t)
  v(drop)
  align(center)[
    #rubric(t, size: 10pt, fill: ink, track: 0.3em)
    #v(9pt)
    #hairline(w: 16%%, c: gold, t: 0.5pt)
  ]
  v(22pt)
}

#let sublabel(t) = block(above: 16pt, below: 7pt)[#rubric(t, size: 7.6pt, fill: accent)]

#let prose(t, size: 10pt, fill: ink, indent: true) = block(spacing: 0.9em)[
  #set par(first-line-indent: (amount: if indent { 1.1em } else { 0em }, all: false))
  #text(size: size, fill: fill)[#t]
]

#let datarow(k, v) = block(spacing: 6pt)[
  #grid(columns: (5.6em, 1fr), column-gutter: 10pt,
    text(size: 8.2pt, fill: soft)[#k],
    text(size: 8.8pt, fill: ink)[#v])
]

#let bullet(t) = block(spacing: 5pt)[
  #grid(columns: (0.9em, 1fr),
    text(fill: gold, size: 9pt)[\u{00b7}],
    text(size: 8.8pt, fill: ink)[#t])
]
"""


def build_typ(args) -> str:
    wdir, work, editions, enrich, explore = load_work(args.work)
    ed = editions[args.edition]
    lang = args.lang

    # An overlay carries an edition that is not (or not yet) in the bundle: its own work
    # metadata, sections, apparatus and chrome. Everything else still comes from content/.
    if args.overlay:
        ov = json.loads(Path(args.overlay).read_text())
        lang = ov.get("lang", lang)
        work = merge(work, ov.get("work", {}))
        ed = merge(ed, ov.get("edition", {}))
        enrich = merge(enrich, ov.get("enrichment", {}))
        explore = merge(explore or {}, ov.get("explore", {}))
        editions = dict(editions)
        for eid, patch in (ov.get("otherEditions") or {}).items():
            if eid in editions:
                editions[eid] = merge(editions[eid], patch)
        editions[ed["id"]] = ed

    S = dict(STRINGS[lang])
    if args.overlay:
        S.update(json.loads(Path(args.overlay).read_text()).get("strings", {}))

    prov = ed.get("provenance", {})
    chapters = {str(k): v for k, v in (enrich.get("chapters") or {}).items()}

    paper = f'rgb("{PARCHMENT}")' if args.paper == "parchment" else "white"
    L = []
    add = L.append

    add(PREAMBLE % dict(
        ink=INK, soft=SOFT, accent=ACCENT, gold=GOLD, paper=paper, bodyfont=args.font,
        doctitle=tq(work["title"]), docauthor=tq(work["author"]), lang=lang,
        booklabel=tq(S["book"]),
        pw=args.width, ph=args.height, mi=args.inside, mo=args.outside,
        mt=args.top, mb=args.bottom, bodysize=args.size, leading=args.leading,
        openerdrop="%s" % args.opener_drop, mattertop="%s" % args.opener_drop,
        secgap="1.05em",
    ))

    # ---------------------------------------------------------------- cover
    # A vector cover (tools/print/covers/<work-slug>.svg) wins over the bundle's raster
    # one, so the whole book — type, rules, engraving — stays vector at any size.
    if args.cover:
        cover = Path(args.cover)
        if not cover.is_absolute():
            cover = (ROOT / cover).resolve()
    else:
        svg = Path(__file__).resolve().parent / "covers" / f"{args.work.split('.')[-1]}.svg"
        cover = svg if svg.exists() else wdir / "cover.jpg"
    if cover.exists() and not args.no_cover:
        # Paths are resolved against typst's --root, which is the repo.
        rel = "/" + cover.relative_to(ROOT).as_posix()
        add(f'''
#page(margin: 0pt, header: none, footer: none, numbering: none)[
  #image("{rel}", width: 100%, height: 100%, fit: "cover")
]
#page(header: none, footer: none, numbering: none)[]
''')

    # ------------------------------------------------------- front matter
    # The cover is not part of the book block: the leaves are numbered from the half title,
    # in roman, as a printed book numbers its prelims.
    add('#set page(numbering: "i", header: none, footer: none)\n')

    # Half title — recto, and the first leaf the printed block counts.
    add(f'''
#page[
  #counter(page).update(1)
  #v(32%)
  #align(center)[
    #rubric({tq(work["title"].upper())}, size: 15pt, fill: ink, track: 0.42em)
    #v(14pt)
    #hairline(w: 14%, c: gold, t: 0.5pt)
  ]
]
''')

    # Title page.
    era = work.get("composed", "")
    subtitle = work.get("subtitle", "")
    add('#page(header: none, footer: none)[]\n')   # half-title verso
    add(f'''
#page[
  #v(20%)
  #align(center)[
    #rubric({tq(work["title"].upper())}, size: 22pt, fill: ink, track: 0.36em)
    #v(16pt)
    #text(size: 12pt, style: "italic", fill: soft)[{mk(work["author"])}]
    #v(4pt)
    #text(size: 8.6pt, fill: soft)[{mk(era)}]
    #v(30pt)
    #hairline(w: 18%, c: gold, t: 0.5pt)
    #v(30pt)
    #rubric({tq(S["edition_line"])}, size: 11pt, fill: accent, track: 0.28em)
    {f'#v(7pt) #text(size: 8pt, fill: soft, style: "italic")[{mk(subtitle)}]' if subtitle else ''}
    #v(10pt)
    #block(width: 70%)[
      #set par(justify: false, leading: 0.7em)
      #text(size: 9.4pt, style: "italic", fill: soft)[{mk(ed.get("character", ""))}]
    ]
  ]
  #v(1fr)
  #align(center)[
    #rubric("Lectio", size: 9pt, fill: ink, track: 0.34em)
    #v(3pt)
    #text(size: 7.2pt, fill: soft)[{mk(S["imprint"])}]
  ]
]
''')

    # Copyright / provenance page.
    sources = prov.get("sourcesCited") or []
    src_lines = "".join(f"  #bullet[{mk(s)}]\n" for s in sources)
    rights_2 = S["rights_2"].format(date=smarten(str(prov.get("retrievedDate", "—"))),
                                    model=smarten(str(prov.get("aiModel", "—"))),
                                    vintage=prov.get("vintage", "—"),
                                    note_title=S["note_edition"])
    add(f'''
#page[
  #v(1fr)
  #set par(justify: false, leading: 0.72em)
  #text(size: 7.6pt, fill: soft)[
    {mk(S["rights_1"].format(title=work["title"]))}
    #v(7pt)
    {mk(prov.get("rightsNote", ""))}
    #v(7pt)
    {rights_2}
    #v(7pt)
    {mk(S["rights_3"])}
    #v(7pt)
    {mk(S["rights_4"])}
    #v(7pt)
    {mk(S["rights_5"])}
    #v(7pt)
    {mk(S["rights_6"])}
  ]
]
''')

    # Contents.
    body_secs = ed["sections"]
    rows = []
    for s in body_secs:
        n = ROMAN[s["order"]] if s["order"] < len(ROMAN) else str(s["order"])
        title = mk(s.get("title") or "")
        rows.append((f'{S["book"]} {n}', title, f"book-{s['order']}"))
    back = [(S["note_edition"], "", "note-edition"),
            (S["differs"], "", "note-differs"),
            (S["compare"], "", "note-compare"),
            (S["editions"], "", "note-editions"),
            (S["threads"], "", "note-threads"),
            (S["colophon"], "", "note-colophon")]

    def toc_row(label, title, tag, roman=False):
        t = f' #h(0.5em) #text(size: 9pt, style: "italic", fill: soft)[{title}]' if title else ""
        folio = (f'numbering("i", counter(page).at(label("{tag}")).first())' if roman
                 else f'counter(page).at(label("{tag}")).first()')
        return (f'  #block(spacing: 8pt)[#box(width: 100%)['
                f'#rubric({tq(label)}, size: 8.4pt, fill: ink)'
                f'{t}'
                f' #box(width: 1fr, inset: (bottom: 2.5pt), repeat[#text(fill: soft.lighten(45%), size: 7pt)[.]])'
                f' #text(size: 8.4pt, fill: soft, number-type: "lining")['
                f'#context {folio}]]]\n')

    toc = "".join(toc_row(a, b, c) for a, b, c in rows)
    toc_back = "".join(toc_row(a, b, c) for a, b, c in back)
    add(f'''
#page[
  #matter-title({tq(S["contents"])}, drop: 9%)
  #block(width: 92%)[
{toc_row(S["introduction"], "", "intro", roman=True)}
  #v(9pt)
{toc}
  #v(11pt)
{toc_back}
  ]
]
''')

    # Introduction.
    intro = ed.get("introduction") or ""
    # The prelims carry a roman folio at the foot from the Introduction onward.
    add('#pagebreak(to: "odd", weak: true)\n')
    add('#page(footer: context align(center, text(size: 8.2pt, fill: soft,'
        ' number-type: "lining")[#counter(page).display("i")]))[\n'
        f'  #matter-title({tq(S["introduction"])}) #metadata(none) <intro>\n')
    for para in intro.split("\n\n"):
        add(f'  #prose[{mk(para)}]\n')
    if explore and explore.get("essence"):
        add(f'''  #v(10pt)
  #align(center, block(width: 80%)[
    #set par(justify: false, leading: 0.7em)
    #text(size: 9pt, style: "italic", fill: soft)[{mk(explore["essence"])}]
  ])
''')
    add(']\n')

    # Epigraph, facing the text.
    if explore and explore.get("quote"):
        add('#pagebreak(to: "odd", weak: true)\n')
        add(f'''
#page[
  #v(34%)
  #align(center, block(width: 82%)[
    #set par(justify: false, leading: 0.78em)
    #text(size: 12.5pt, style: "italic", fill: ink)[“{mk(explore["quote"])}”]
    #v(12pt)
    #text(size: 7.6pt, fill: soft)[{mk(explore["source"])}]
  ])
]
''')

    # ------------------------------------------------------------- the text
    add('\n#set page(numbering: "1", header: runhead, footer: none)\n')

    book_label = S["book"]
    for s in body_secs:
        n = ROMAN[s["order"]] if s["order"] < len(ROMAN) else str(s["order"])
        add('\n#rh.update(none)\n#pagebreak(to: "odd", weak: true)\n')
        if s is body_secs[0]:
            # Book I opens the arabic sequence, on a recto, at 1.
            add('#counter(page).update(1)\n')
        add(f'= {n} <book-{s["order"]}>\n')
        add(f'#rh.update({tq(book_label + " " + n)})\n')
        if s.get("title"):
            add(f'#booktitle[{mk(s["title"])}]\n')
        note = chapters.get(str(s["order"]))
        if note:
            add(f'#argument[{mk(note)}]\n')
        # Sections: paragraphs numbered in the order they are read, as in the app.
        # A segment marked "omit" is an editor's note kept only for its id; it is not printed.
        readable = [g for g in s["segments"] if g.get("kind") != "omit"]
        for i, g in enumerate(readable, start=1):
            add(f'#sec({i}, ({tqs(g["text"])},))\n')

    # ------------------------------------------------------------ back matter
    add('\n#rh.update(none)\n#pagebreak(to: "odd", weak: true)\n')
    add(f'#matter-title({tq(S["note_edition"])}) #metadata(none) <note-edition>\n')
    if ed.get("overview"):
        add(f'#prose[{mk(ed["overview"])}]\n')
    add(f'#sublabel({tq(S["how_made"])})\n')
    add(f'#prose(size: 9.2pt, fill: ink)[{mk(prov.get("rightsNote", ""))}]\n')
    if sources:
        add(f'#sublabel({tq(S["sources"])})\n')
        add(src_lines)
    add(f'#sublabel({tq(S["provenance"])})\n')
    vintage = prov.get("vintage")
    ed_line = S["edition_line"] + (" · " + str(vintage) if vintage else "")
    add(f'#datarow({tq(S["row_edition"])}, {tq(ed_line)})\n')
    if prov.get("aiModel"):
        add(f'#datarow({tq(S["row_model"])}, {tq(prov["aiModel"])})\n')
    if prov.get("retrievedDate"):
        add(f'#datarow({tq(S["row_produced"])}, {tq(str(prov["retrievedDate"]))})\n')
    if prov.get("tokensEstimated"):
        ntok = "{:,}".format(prov["tokensEstimated"])
        add(f'#datarow({tq(S["row_tokens"])}, {tq(S["tokens_fmt"].format(n=ntok))})\n')
    if prov.get("aiSourceEditionId"):
        base = editions.get(prov["aiSourceEditionId"], {})
        who = base.get("translator") or prov["aiSourceEditionId"]
        yr = base.get("publishedYear", "")
        add(f'#datarow({tq(S["row_base"])}, {tq(f"{who}, {yr}" if yr else str(who))})\n')
    elif prov.get("baseTextLabel"):
        add(f'#datarow({tq(S["row_base"])}, {tqs(prov["baseTextLabel"])})\n')
    add(f'#datarow({tq(S["row_reference"])}, {tq(work.get("referenceScheme", ""))})\n')
    add('#v(12pt)\n')
    add(f'#prose(size: 8.4pt, fill: soft, indent: false)[{S["numbering_note"]}]\n')

    # Divergences.
    divs = ed.get("divergences") or []
    if divs:
        add('\n#pagebreak(weak: true)\n')
        add(f'#matter-title({tq(S["differs"])}) #metadata(none) <note-differs>\n')
        add(f'#prose(size: 9.2pt, fill: soft, indent: false)[{mk(S["differs_lede"])}]\n#v(6pt)\n')
        for d in divs:
            add(f'''#block(spacing: 15pt, breakable: false)[
  #rubric({tqs(d.get("locus",""))}, size: 7.4pt, fill: accent)
  #v(4pt)
  #text(size: 11pt, fill: ink)[{mk(d.get("phrase",""))}]
  #v(5pt)
  #datarow({tq(S["row_older"])}, {tqs(d.get("older",""))})
  #datarow({tq(S["row_lectio"])}, {tqs(d.get("lectio",""))})
  #v(4pt)
  #block(width: 100%)[#set par(justify: true, leading: 0.72em)
    #text(size: 8.8pt, fill: soft)[{mk(d.get("note",""))}]]
]
''')

    # The same passage in every edition.
    rowsx = passage_across_editions(editions, ed["id"], args.compare_locus)
    if len(rowsx) > 1:
        bk, sc = (args.compare_locus.split(".") + [""])[:2]
        add('\n#pagebreak(weak: true)\n')
        add(f'#matter-title({tq(S["compare"])}) #metadata(none) <note-compare>\n')
        add(f'#prose(size: 9.2pt, fill: soft, indent: false)'
            f'[{mk(S["compare_lede"].format(book=bk, sec=sc))}]\n#v(4pt)\n')
        for e2, text in rowsx:
            head = edition_head(e2, ed["id"], S)
            grc = e2.get("language") == "grc"
            font = ', font: "New York"' if grc else ""
            add(f'''#block(spacing: 15pt)[
  #rubric({tqs(head)}, size: 7.4pt, fill: accent)
  #v(3pt)
  #text(size: 7.6pt, fill: soft, style: "italic")[{mk(e2.get("character",""))}]
  #v(6pt)
  #block(width: 100%)[#set par(justify: true, leading: 0.75em)
    #text(size: 9.4pt, fill: ink{font})[{mk(text)}]]
]
''')

    # The other editions.
    add('\n#pagebreak(weak: true)\n')
    add(f'#matter-title({tq(S["editions"])}) #metadata(none) <note-editions>\n')
    add(f'#prose(size: 9.2pt, fill: soft, indent: false)[{mk(S["editions_lede"])}]\n#v(8pt)\n')
    for eid in work["editionIds"]:
        if eid == ed["id"] or eid not in editions:
            continue
        e2 = editions[eid]
        p2 = e2.get("provenance", {})
        who = e2.get("translator")
        yrs = e2.get("translatorYears")
        head = edition_head(e2, ed["id"], S, sep=" · ")
        add(f'''#block(spacing: 16pt, breakable: false)[
  #rubric({tqs(head)}, size: 7.6pt, fill: accent)
  #v(4pt)
  #block(width: 100%)[#set par(justify: true, leading: 0.72em)
    #text(size: 9.2pt, fill: ink)[{mk(e2.get("character",""))}]]
  #v(5pt)
  {f'#datarow({tq(S["row_translator"])}, {tqs(who + (" (" + yrs + ")" if yrs else ""))})' if who else ""}
  #datarow({tq(S["row_rights"])}, {tqs(p2.get("rightsNote",""))})
  {f'#datarow({tq(S["row_source"])}, {tq(p2.get("sourceUrl",""))})' if p2.get("sourceUrl") else ""}
]
''')

    # Threads.
    if explore and explore.get("connections"):
        add('\n#pagebreak(weak: true)\n')
        add(f'#matter-title({tq(S["threads"])}) #metadata(none) <note-threads>\n')
        add(f'#prose(size: 9.2pt, fill: soft, indent: false)[{mk(S["threads_lede"])}]\n#v(8pt)\n')
        for c in explore["connections"]:
            add(f'''#block(spacing: 13pt, breakable: false)[
  #rubric({tqs(c.get("type",""))}, size: 7pt, fill: gold)
  #h(0.6em) #text(size: 10pt, style: "italic", fill: ink)[{mk(c.get("to",""))}]
  #v(4pt)
  #block(width: 100%)[#set par(justify: true, leading: 0.72em)
    #text(size: 8.8pt, fill: soft)[{mk(c.get("note",""))}]]
]
''')
        if explore.get("themes"):
            add(f'#sublabel({tq(S["themes"])})\n')
            add(f'#prose(size: 9pt, fill: ink, indent: false)'
                f'[{mk(" · ".join(explore["themes"]))}]\n')

    # People named, from the enrichment sidecar (the app's who's-who).
    people = []
    for p in (enrich.get("passages") or []):
        if p.get("sectionId", "").startswith(ed["id"]):
            people += p.get("people", [])
    if people:
        add(f'#sublabel({tq(S["whoswho"])})\n')
        add(f'#prose(size: 9pt, fill: ink, indent: false)'
            f'[{mk(" · ".join(dict.fromkeys(people)))}]\n')

    # Colophon.
    nsegs = sum(len(s["segments"]) for s in body_secs)
    add('\n#rh.update(none)\n#pagebreak(to: "odd", weak: true)\n')
    add(f'#matter-title({tq(S["colophon"])}) #metadata(none) <note-colophon>\n')
    add(f'''#align(center, block(width: 82%)[
  #set par(justify: false, leading: 0.8em)
  #text(size: 9pt, fill: ink)[
    {mk(S["colophon_1"].format(title=work["title"], books=len(body_secs), secs=nsegs))}
    #v(9pt)
    {mk(S["colophon_2"].format(font=args.font,
                               w=args.width.replace("in", ""), h=args.height.replace("in", "")))}
    #v(9pt)
    #rubric("Lectio", size: 9pt, fill: ink, track: 0.34em)
    #v(3pt)
    {mk(S["colophon_imprint"])}
  ]
])
''')
    return "".join(L)


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--work", default="work.marcus-aurelius.meditations")
    ap.add_argument("--edition", default="edition.meditations.lectio-modern")
    ap.add_argument("--overlay", default=None,
                    help="JSON overriding work/edition/enrichment/explore/strings — for an "
                         "edition that is not in the bundle (e.g. a translation experiment)")
    ap.add_argument("--lang", default="en", choices=sorted(STRINGS))
    ap.add_argument("--out", default=None)
    ap.add_argument("--paper", choices=["white", "parchment"], default="white")
    ap.add_argument("--font", default="New York")
    ap.add_argument("--width", default="5.5in")
    ap.add_argument("--height", default="8.5in")
    ap.add_argument("--inside", default="0.86in")
    ap.add_argument("--outside", default="0.62in")
    ap.add_argument("--top", default="0.78in")
    ap.add_argument("--bottom", default="0.8in")
    ap.add_argument("--size", default="10.6pt")
    ap.add_argument("--leading", default="0.78em")
    ap.add_argument("--opener-drop", default="16%")
    ap.add_argument("--compare-locus", default="5.16")
    ap.add_argument("--cover", default=None,
                    help="cover artwork (SVG or JPEG); defaults to tools/print/covers/"
                         "<work-slug>.svg, else the bundle's cover.jpg")
    ap.add_argument("--no-cover", action="store_true")
    ap.add_argument("--keep-typ", action="store_true")
    args = ap.parse_args()

    if args.overlay:
        ov = json.loads(Path(args.overlay).read_text())
        args.out = args.out or ov.get("out")
        args.compare_locus = ov.get("compareLocus", args.compare_locus)
        args.cover = args.cover or ov.get("cover")

    OUT.mkdir(parents=True, exist_ok=True)
    stem = args.out or (args.edition.replace("edition.", "").replace(".", "-")
                        + ("-parchment" if args.paper == "parchment" else ""))
    if args.out and args.paper == "parchment":
        stem += "-parchment"
    typ = OUT / f"{stem}.typ"
    pdf = OUT / f"{stem}.pdf"
    typ.write_text(build_typ(args))

    r = subprocess.run(["typst", "compile", "--root", str(ROOT), str(typ), str(pdf)],
                       capture_output=True, text=True)
    if r.returncode != 0:
        sys.stderr.write(r.stdout + r.stderr)
        return r.returncode
    if r.stderr.strip():
        sys.stderr.write(r.stderr)
    if not args.keep_typ:
        pass  # the .typ stays next to the pdf; it is the print source
    print(f"{pdf}  ({pdf.stat().st_size/1e6:.1f} MB)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
