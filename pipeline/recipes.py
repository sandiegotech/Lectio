"""Per-book build recipes.

A recipe fetches sources, applies each book's structure, and returns
(Work, [Edition], spine_or_None). One Work can carry several Editions (multiple
translations + the original-language text). Add a function, append it to RECIPES.
"""
from __future__ import annotations

import json
import os
import re

from .adapters import gutenberg, wikisource
from .model import Edition, Provenance, Work
from .segment import build_section

_MODERN_DIR = os.path.join(os.path.dirname(__file__), "modern")

_ROMAN = ["I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X", "XI", "XII",
          "XIII", "XIV", "XV", "XVI", "XVII", "XVIII", "XIX", "XX", "XXI", "XXII",
          "XXIII", "XXIV"]

MEDITATIONS_WORK_ID = "work.marcus-aurelius.meditations"
RETRIEVED = "2026-06-15"


# ---------------------------------------------------------------------------
# Meditations — three editions: George Long (1862), Casaubon (1634), Greek original
# ---------------------------------------------------------------------------

def _casaubon_edition() -> Edition:
    edition_id = "edition.meditations.casaubon-1634"
    body = gutenberg.strip_boilerplate(gutenberg.fetch(2680))
    raw = gutenberg.split_sections(body, heading_re=r"^THE [A-Z]+ BOOK[ \t]*$",
                                   end_re=r"^APPENDIX[ \t]*$")
    if len(raw) != 12:
        raise ValueError(f"Casaubon: expected 12 books, got {len(raw)}")
    sections = [
        build_section(edition_id, f"book-{i:02d}", i, f"Book {_ROMAN[i-1]}", text, form="prose")
        for i, (_, text) in enumerate(raw, start=1)
    ]
    return Edition(
        id=edition_id, workId=MEDITATIONS_WORK_ID, kind="translation", language="en",
        form="prose", translator="Méric Casaubon", translatorYears="1599–1671",
        publishedYear=1634,
        character="The first English Meditations — ornate, archaic, devotional.",
        provenance=Provenance(source="gutenberg", rightsStatus="public_domain",
                              rightsNote="US public domain; Casaubon translation first published 1634.",
                              sourceUrl="https://www.gutenberg.org/ebooks/2680",
                              sourceId="2680", retrievedDate=RETRIEVED),
        sections=sections,
    )


def _clean_long(text: str) -> str:
    """Long's text is interleaved with scholarly footnotes. Drop footnote-definition
    paragraphs ([A] ...) and strip inline footnote markers, keeping the prose."""
    out = []
    for para in re.split(r"\n\s*\n", text):
        if re.match(r"^\s*\[[A-Z]{1,3}\]", para):       # a footnote definition block
            continue
        if re.match(r"^\s*\[Illustration", para):       # plate/figure caption
            continue
        para = re.sub(r"\[Illustration:[^\]]*\]", "", para)  # inline caption
        para = re.sub(r"\[[A-Z]{1,3}\]", "", para)      # inline footnote markers like [A]
        if para.strip():
            out.append(para)
    return "\n\n".join(out)


def _long_edition() -> Edition:
    edition_id = "edition.meditations.long-1862"
    body = gutenberg.strip_boilerplate(gutenberg.fetch(15877))
    raw = gutenberg.split_sections(body, heading_re=r"^[IVXL]+\.[ \t]*$",
                                   end_re=r"^INDEXES\.[ \t]*$")
    if len(raw) != 12:
        raise ValueError(f"Long: expected 12 books, got {len(raw)}")
    sections = [
        build_section(edition_id, f"book-{i:02d}", i, f"Book {_ROMAN[i-1]}",
                      _clean_long(text), form="prose")
        for i, (_, text) in enumerate(raw, start=1)
    ]
    return Edition(
        id=edition_id, workId=MEDITATIONS_WORK_ID, kind="translation", language="en",
        form="prose", translator="George Long", translatorYears="1800–1879",
        publishedYear=1862,
        character="The classic Victorian standard — clear, dignified, widely read.",
        provenance=Provenance(source="gutenberg", rightsStatus="public_domain",
                              rightsNote="US public domain; George Long translation, 1862.",
                              sourceUrl="https://www.gutenberg.org/ebooks/15877",
                              sourceId="15877", retrievedDate=RETRIEVED),
        sections=sections,
    )


def _greek_edition() -> Edition:
    edition_id = "edition.meditations.greek-original"
    sections = []
    for i in range(1, 13):
        wikitext = wikisource.fetch_wikitext(f"Τα εις εαυτόν/{i}", lang="el")
        aphorisms = wikisource.list_items(wikitext)
        if not aphorisms:
            raise ValueError(f"Greek: book {i} produced no aphorisms")
        body = "\n\n".join(aphorisms)
        sections.append(
            build_section(edition_id, f"book-{i:02d}", i, f"Book {_ROMAN[i-1]}", body, form="prose")
        )
    return Edition(
        id=edition_id, workId=MEDITATIONS_WORK_ID, kind="original", language="grc",
        form="prose", translator=None, translatorYears=None, publishedYear=None,
        character="The original Koine Greek — Marcus's private notebook (Τὰ εἰς ἑαυτόν).",
        provenance=Provenance(source="wikisource", rightsStatus="public_domain",
                              rightsNote="Ancient Greek source text (c. 170–180 CE); public domain.",
                              sourceUrl="https://el.wikisource.org/wiki/Τα_εις_εαυτόν",
                              sourceId="el:Τα εις εαυτόν", retrievedDate=RETRIEVED),
        sections=sections,
    )


def _estimate_tokens(*editions: Edition, output_chars: int) -> int:
    """Rough token estimate (~4 chars/token) for producing the Modern Edition:
    the source editions fed in + the modern text produced. Honest approximation."""
    src_chars = sum(len(seg.text) for e in editions for s in e.sections for seg in s.segments)
    return round((src_chars + output_chars) / 4)


def _modern_edition(work_id: str, slug: str, sources: list) -> Edition:
    """The Lectio Modern Edition — authored/reviewed modern English produced by deep
    research from public-domain sources (see pipeline/modern/<slug>.json)."""
    with open(os.path.join(_MODERN_DIR, f"{slug}.json"), encoding="utf-8") as f:
        data = json.load(f)
    books = list(data["books"])

    # Additional books live as bare paragraph-array files in modern/<slug>-books/book-NN.json
    extra_dir = os.path.join(_MODERN_DIR, f"{slug}-books")
    if os.path.isdir(extra_dir):
        have = {b["order"] for b in books}
        for n in range(1, 100):
            path = os.path.join(extra_dir, f"book-{n:02d}.json")
            if n in have or not os.path.exists(path):
                continue
            with open(path, encoding="utf-8") as f:
                paragraphs = json.load(f)
            books.append({"order": n, "label": f"Book {_ROMAN[n - 1]}", "paragraphs": paragraphs})
    books.sort(key=lambda b: b["order"])

    edition_id = f"edition.{slug}.lectio-modern"
    sections = []
    output_chars = 0
    for book in books:
        output_chars += sum(len(p) for p in book["paragraphs"])
        body = "\n\n".join(book["paragraphs"])
        sections.append(
            build_section(edition_id, f"book-{book['order']:02d}", book["order"],
                          book["label"], body, form="prose", title=book.get("title"))
        )
    return Edition(
        id=edition_id, workId=work_id, kind="modern", language="en", form="prose",
        translator=None, translatorYears=None, publishedYear=None,
        character="Plain modern English — the sense of the original, made to read with ease today.",
        introduction=data.get("introduction"),
        provenance=Provenance(
            source="lectio", rightsStatus="lectio-original",
            rightsNote=data["method"], aiModel=data.get("model"),
            aiSourceEditionId=(data.get("sourceEditionIds") or [None])[0],
            aiProfile="plain_modern", retrievedDate=data.get("date"),
            sourcesCited=data.get("sourcesCited"),
            vintage=data.get("vintage"),
            tokensEstimated=_estimate_tokens(*sources, output_chars=output_chars),
        ),
        sections=sections,
    )


def meditations():
    long_ed = _long_edition()
    casaubon = _casaubon_edition()
    greek = _greek_edition()
    modern = _modern_edition(MEDITATIONS_WORK_ID, "meditations", [long_ed, casaubon, greek])

    work = Work(
        id=MEDITATIONS_WORK_ID, title="Meditations", author="Marcus Aurelius",
        originalLang="grc", composed="c. 170–180 CE", type="philosophy",
        referenceScheme="book.section",
        defaultEditionId=modern.id,   # the Lectio Modern Edition reads by default
        blurb=("The private notebook of a Roman emperor — Stoic reflections on duty, "
               "mortality, and how to live well, written only for himself."),
        collections=["collection.harvard-classics"],
    )
    return work, [modern, long_ed, casaubon, greek], None


# ---------------------------------------------------------------------------
# The Iliad — Pope (verse, 1715), Butler (prose, 1898), + the Lectio Edition
# ---------------------------------------------------------------------------

ILIAD_WORK_ID = "work.homer.iliad"


def _iliad_book_sections(edition_id: str, body: str, form: str):
    raw = gutenberg.split_sections(body, heading_re=r"^BOOK [IVXL]+\.[ \t]*$")
    if len(raw) != 24:
        raise ValueError(f"Iliad ({edition_id}): expected 24 books, got {len(raw)}")
    return [
        build_section(edition_id, f"book-{i:02d}", i, f"Book {_ROMAN[i-1]}", text, form=form)
        for i, (_, text) in enumerate(raw, start=1)
    ]


def _iliad_pope_edition() -> Edition:
    edition_id = "edition.iliad.pope-1715"
    body = gutenberg.strip_boilerplate(gutenberg.fetch(6130))
    body = body.split("END OF THE ILIAD")[0]   # drop trailing notes/appendix
    body = re.sub(r"\[\d+\]", "", body)         # strip footnote-reference markers
    return Edition(
        id=edition_id, workId=ILIAD_WORK_ID, kind="translation", language="en",
        form="verse", translator="Alexander Pope", translatorYears="1688–1744",
        publishedYear=1715,
        character="Stately heroic couplets — 18th-century grandeur.",
        provenance=Provenance(source="gutenberg", rightsStatus="public_domain",
                              rightsNote="US public domain; Pope's verse Iliad, 1715–20.",
                              sourceUrl="https://www.gutenberg.org/ebooks/6130",
                              sourceId="6130", retrievedDate=RETRIEVED),
        sections=_iliad_book_sections(edition_id, body, form="verse"),
    )


def _iliad_butler_edition() -> Edition:
    edition_id = "edition.iliad.butler-1898"
    body = gutenberg.strip_boilerplate(gutenberg.fetch(2199))
    return Edition(
        id=edition_id, workId=ILIAD_WORK_ID, kind="translation", language="en",
        form="prose", translator="Samuel Butler", translatorYears="1835–1902",
        publishedYear=1898,
        character="Plain, clear Victorian prose.",
        provenance=Provenance(source="gutenberg", rightsStatus="public_domain",
                              rightsNote="US public domain; Butler's prose Iliad, 1898.",
                              sourceUrl="https://www.gutenberg.org/ebooks/2199",
                              sourceId="2199", retrievedDate=RETRIEVED),
        sections=_iliad_book_sections(edition_id, body, form="prose"),
    )


def iliad():
    pope = _iliad_pope_edition()
    butler = _iliad_butler_edition()
    modern = _modern_edition(ILIAD_WORK_ID, "iliad", [pope, butler])

    work = Work(
        id=ILIAD_WORK_ID, title="The Iliad", author="Homer",
        originalLang="grc", composed="c. 8th century BCE", type="epic_poem",
        referenceScheme="book.line",
        defaultEditionId=modern.id,
        blurb=("Homer's epic of the Trojan War — rage, honor, grief, and mortality, "
               "set in a few weeks of the war's tenth year."),
        collections=["collection.epics"],
    )
    return work, [modern, pope, butler], None


# ---------------------------------------------------------------------------
# The Odyssey — Samuel Butler prose (1900), Gutenberg #1727
# ---------------------------------------------------------------------------

def odyssey():
    work_id = "work.homer.odyssey"
    edition_id = "edition.odyssey.butler-1900"
    body = gutenberg.strip_boilerplate(gutenberg.fetch(1727))
    raw = gutenberg.split_sections(body, heading_re=r"^BOOK [IVXL]+[ \t]*$")
    if len(raw) != 24:
        raise ValueError(f"Odyssey: expected 24 books, got {len(raw)}")
    sections = [
        build_section(edition_id, f"book-{i:02d}", i, f"Book {_ROMAN[i-1]}", text, form="prose")
        for i, (_, text) in enumerate(raw, start=1)
    ]
    edition = Edition(
        id=edition_id, workId=work_id, kind="translation", language="en", form="prose",
        translator="Samuel Butler", translatorYears="1835–1902", publishedYear=1900,
        character="Plain, clear Victorian prose.",
        provenance=Provenance(source="gutenberg", rightsStatus="public_domain",
                              rightsNote="US public domain; Butler's prose Odyssey, 1900.",
                              sourceUrl="https://www.gutenberg.org/ebooks/1727",
                              sourceId="1727", retrievedDate=RETRIEVED),
        sections=sections,
    )
    modern = _modern_edition(work_id, "odyssey", [edition])
    work = Work(
        id=work_id, title="The Odyssey", author="Homer", originalLang="grc",
        composed="c. 8th century BCE", type="epic_poem", referenceScheme="book.line",
        defaultEditionId=modern.id,
        blurb=("Homer's epic of the long way home — Odysseus's ten-year voyage back "
               "from Troy through monsters, gods, and temptations to Ithaca."),
        collections=["collection.epics", "collection.harvard-classics"],
    )
    return work, [modern, edition], None


# ---------------------------------------------------------------------------
# The Aeneid — John Dryden verse (1697), Gutenberg #228
# ---------------------------------------------------------------------------

def aeneid():
    work_id = "work.virgil.aeneid"
    edition_id = "edition.aeneid.dryden-1697"
    body = gutenberg.strip_boilerplate(gutenberg.fetch(228))
    # Drop the table of contents: start at the real "BOOK I" (the one followed by
    # its ARGUMENT); the contents lists BOOK I–XII with deeper indentation.
    m = re.search(r"^ *BOOK I[ \t]*\n+ *THE ARGUMENT\.", body, re.M)
    if m:
        body = body[m.start():]
    body = re.sub(r"\[\d+\]", "", body)   # strip footnote-reference markers
    raw = gutenberg.split_sections(body, heading_re=r"^ *BOOK +[IVXL]+[ \t]*$")
    if len(raw) != 12:
        raise ValueError(f"Aeneid: expected 12 books, got {len(raw)}")
    sections = [
        build_section(edition_id, f"book-{i:02d}", i, f"Book {_ROMAN[i-1]}", text, form="verse")
        for i, (_, text) in enumerate(raw, start=1)
    ]
    edition = Edition(
        id=edition_id, workId=work_id, kind="translation", language="en", form="verse",
        translator="John Dryden", translatorYears="1631–1700", publishedYear=1697,
        character="Stately heroic couplets — the great English Virgil.",
        provenance=Provenance(source="gutenberg", rightsStatus="public_domain",
                              rightsNote="US public domain; Dryden's verse Aeneid, 1697.",
                              sourceUrl="https://www.gutenberg.org/ebooks/228",
                              sourceId="228", retrievedDate=RETRIEVED),
        sections=sections,
    )
    modern = _modern_edition(work_id, "aeneid", [edition])
    work = Work(
        id=work_id, title="The Aeneid", author="Virgil", originalLang="la",
        composed="29–19 BCE", type="epic_poem", referenceScheme="book.line",
        defaultEditionId=modern.id,
        blurb=("Virgil's Roman epic — Aeneas's flight from fallen Troy to found the "
               "race that would build Rome. Descended from Homer; ancestor of Dante."),
        collections=["collection.epics", "collection.harvard-classics"],
    )
    return work, [modern, edition], None


RECIPES = [meditations, iliad, odyssey, aeneid]
