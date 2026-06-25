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
          "XXIII", "XXIV", "XXV", "XXVI", "XXVII", "XXVIII", "XXIX", "XXX"]

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
        overview=("Méric Casaubon, son of the great scholar Isaac Casaubon, produced the first "
                  "complete English Meditations. His version is Jacobean in flavour — ornate, "
                  "archaic, and openly devotional, closer to a 17th-century book of prayer than a "
                  "modern translation. It is a historical document as much as a translation, "
                  "valued for its period voice rather than its accuracy; set beside George Long's "
                  "sober Victorian prose it can read as a different book."),
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
        overview=("George Long was a Victorian classical scholar who aimed at accuracy over "
                  "elegance. His Meditations was the standard English text for over a century — "
                  "plain, dignified, and faithful, if occasionally stiff to a modern ear. Where "
                  "Casaubon is ornate and devotional, Long is sober and precise; it remains the "
                  "most reliable of the public-domain translations."),
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
        overview=("The Koine Greek of Marcus's private notebook, titled in the manuscripts "
                  "Τὰ εἰς ἑαυτόν — 'To Himself.' Marcus wrote in Greek, the language of "
                  "philosophy, though Latin was his working tongue as emperor. The text survives "
                  "through only a handful of medieval manuscripts; this is the public-domain "
                  "source edition, offered for readers who want the words behind the translations."),
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
                          book["label"], body, form=data.get("form", "prose"),
                          title=book.get("title"))
        )
    return Edition(
        id=edition_id, workId=work_id, kind="modern", language="en",
        form=data.get("form", "prose"),
        translator=None, translatorYears=None, publishedYear=None,
        character="Plain modern English — the sense of the original, made to read with ease today.",
        overview=data.get("overview"),
        introduction=data.get("introduction"),
        divergences=data.get("divergences"),
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
        originalLang="grc", composed="170–180 CE", type="philosophy",
        referenceScheme="book.section",
        defaultEditionId=modern.id,   # the Lectio Modern Edition reads by default
        blurb=("The private notebook of a Roman emperor — Stoic reflections on duty, "
               "mortality, and how to live well, written only for himself."),
        collections=["collection.harvard-classics", "collection.great-books"],
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
        overview=("Alexander Pope's Iliad is one of the monuments of English verse — twenty-four "
                  "books in polished heroic couplets, the work of six years. It is magnificent but "
                  "very much an 18th-century poem: Pope heightens, ornaments, and regularises Homer "
                  "to Augustan taste. Read it for its grandeur and music; for a literal sense of "
                  "the Greek, Butler's prose or the Lectio Edition is closer."),
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
        overview=("Samuel Butler — better known as a novelist — rendered the Iliad into plain "
                  "Victorian prose, deliberately stripping away the poetic machinery to make the "
                  "story clear. It reads easily and tracks the sense closely, but loses the metre "
                  "and grandeur entirely. Where Pope is grand and free, Butler is plain and "
                  "faithful — the most readable of the public-domain versions."),
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
        originalLang="grc", composed="800–701 BCE", type="epic_poem",
        referenceScheme="book.line",
        defaultEditionId=modern.id,
        blurb=("Homer's epic of the Trojan War — rage, honor, grief, and mortality, "
               "set in a few weeks of the war's tenth year."),
        collections=["collection.epics", "collection.great-books"],
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
        overview=("Samuel Butler's prose Odyssey, like his Iliad, trades poetry for clarity — a "
                  "readable, faithful narrative in plain Victorian English. Butler held an "
                  "eccentric theory that the poem was written by a woman, but the translation "
                  "itself is straightforward and reliable: the easiest public-domain way into the "
                  "story before the Lectio Edition modernises it further."),
        provenance=Provenance(source="gutenberg", rightsStatus="public_domain",
                              rightsNote="US public domain; Butler's prose Odyssey, 1900.",
                              sourceUrl="https://www.gutenberg.org/ebooks/1727",
                              sourceId="1727", retrievedDate=RETRIEVED),
        sections=sections,
    )
    modern = _modern_edition(work_id, "odyssey", [edition])
    work = Work(
        id=work_id, title="The Odyssey", author="Homer", originalLang="grc",
        composed="800–701 BCE", type="epic_poem", referenceScheme="book.line",
        defaultEditionId=modern.id,
        blurb=("Homer's epic of the long way home — Odysseus's ten-year voyage back "
               "from Troy through monsters, gods, and temptations to Ithaca."),
        collections=["collection.epics", "collection.harvard-classics", "collection.great-books"],
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
        overview=("John Dryden's Aeneid is the great English Virgil — heroic couplets of enormous "
                  "energy and polish, the work of England's first Poet Laureate at the height of "
                  "his powers. Like Pope's Homer it is a free, grand, Augustan rendering that adds "
                  "and smooths to suit English verse. It is a masterpiece in its own right, prized "
                  "for its momentum more than its literal fidelity."),
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
        collections=["collection.epics", "collection.harvard-classics", "collection.great-books"],
    )
    return work, [modern, edition], None


# ---------------------------------------------------------------------------
# Plato's Republic — Benjamin Jowett prose (1871), Gutenberg #1497
# ---------------------------------------------------------------------------

REPUBLIC_WORK_ID = "work.plato.republic"


def republic():
    work_id = REPUBLIC_WORK_ID
    edition_id = "edition.republic.jowett-1871"
    body = gutenberg.strip_boilerplate(gutenberg.fetch(1497))

    # The file carries a table of contents and Jowett's long Introduction + Analysis
    # before the dialogue; both walk through the books. Anchor on the dialogue's first
    # line and start at the BOOK I heading just before it.
    marker = body.index("I went down yesterday to the Piraeus")
    book1 = max(m.start() for m in re.finditer(r"^[ \t]*BOOK I\.[ \t]*$", body, re.M)
                if m.start() < marker)
    body = body[book1:]
    raw = gutenberg.split_sections(body, heading_re=r"^[ \t]*BOOK [IVXL]+\.[ \t]*$")
    if len(raw) != 10:
        raise ValueError(f"Republic: expected 10 books, got {len(raw)}")
    sections = [
        build_section(edition_id, f"book-{i:02d}", i, f"Book {_ROMAN[i-1]}", text, form="prose")
        for i, (_, text) in enumerate(raw, start=1)
    ]
    edition = Edition(
        id=edition_id, workId=work_id, kind="translation", language="en", form="prose",
        translator="Benjamin Jowett", translatorYears="1817–1893", publishedYear=1871,
        character="The classic Victorian Republic — Jowett's lucid, hugely influential standard.",
        overview=("Benjamin Jowett, Master of Balliol, produced the English Republic that shaped "
                  "how the dialogue was read for a century — fluent, dignified, and readable, if "
                  "freer and more Victorian than the Greek. It remains the most widely known "
                  "public-domain translation; later scholars prize it for grace more than for "
                  "literal precision."),
        provenance=Provenance(source="gutenberg", rightsStatus="public_domain",
                              rightsNote="US public domain; Jowett's prose Republic, 1871.",
                              sourceUrl="https://www.gutenberg.org/ebooks/1497",
                              sourceId="1497", retrievedDate=RETRIEVED),
        sections=sections,
    )
    work = Work(
        id=work_id, title="The Republic", author="Plato", originalLang="grc",
        composed="375 BCE", type="philosophy", referenceScheme="book.section",
        defaultEditionId=edition.id,
        blurb=("Plato's great dialogue on justice — what it is, why it's worth having, and the "
               "just city built in words to find it. Home of the Cave, the philosopher-king, "
               "and the divided line."),
        collections=["collection.great-books"],
    )
    return work, [edition], None


# ---------------------------------------------------------------------------
# Nicomachean Ethics — D. P. Chase translation (Everyman; intro by J. A. Smith)
# ---------------------------------------------------------------------------
def nicomachean_ethics():
    work_id = "work.aristotle.nicomachean-ethics"
    edition_id = "edition.nicomachean-ethics.chase-1911"
    body = gutenberg.strip_boilerplate(gutenberg.fetch(8438))

    # The translation runs BOOK I–X; an appended NOTES section repeats per-book
    # footnotes (its own BOOK I, II, III, …). Drop everything from the second
    # 'BOOK I' on, and trim the trailing NOTES header off Book X.
    book_i = [m.start() for m in re.finditer(r"^BOOK I[ \t]*$", body, re.M)]
    if len(book_i) >= 2:
        body = body[: book_i[1]]
    raw = gutenberg.split_sections(body, heading_re=r"^BOOK [IVX]+[ \t]*$",
                                   end_re=r"^NOTES[ \t]*$")
    if len(raw) != 10:
        raise ValueError(f"Nicomachean Ethics: expected 10 books, got {len(raw)}")
    sections = [
        build_section(edition_id, f"book-{i:02d}", i, f"Book {_ROMAN[i-1]}", text, form="prose")
        for i, (_, text) in enumerate(raw, start=1)
    ]
    edition = Edition(
        id=edition_id, workId=work_id, kind="translation", language="en", form="prose",
        translator="D. P. Chase", translatorYears="1820–1902", publishedYear=1911,
        character="The compact Everyman Ethics — Chase's plain, readable Victorian prose.",
        overview=("Drummond Percy Chase's translation, long the Everyman's Library standard "
                  "(here with J. A. Smith's introduction), renders Aristotle's lecture notes "
                  "into clear, economical English. Faithful and unadorned, it is the version "
                  "that introduced generations to virtue as a habit, the mean between extremes, "
                  "and happiness as the soul's activity in accordance with excellence."),
        provenance=Provenance(source="gutenberg", rightsStatus="public_domain",
                              rightsNote="US public domain; Chase's translation, Everyman ed., 1911.",
                              sourceUrl="https://www.gutenberg.org/ebooks/8438",
                              sourceId="8438", retrievedDate=RETRIEVED),
        sections=sections,
    )
    work = Work(
        id=work_id, title="Nicomachean Ethics", author="Aristotle", originalLang="grc",
        composed="340 BCE", type="philosophy", referenceScheme="book.chapter",
        defaultEditionId="edition.nicomachean-ethics.lectio-modern", tradition="West",
        blurb=("Aristotle's enquiry into the good life: happiness (eudaimonia) as the soul's "
               "activity in accordance with virtue, virtue as a mean formed by habit, and "
               "friendship and contemplation as the crown of a human life."),
        collections=["collection.great-books"],
    )
    return work, [_modern_edition(work_id, "nicomachean-ethics", [edition]), edition], None


# ---------------------------------------------------------------------------
# The Prince — W. K. Marriott translation (1908)
# ---------------------------------------------------------------------------
def the_prince():
    work_id = "work.machiavelli.the-prince"
    edition_id = "edition.the-prince.marriott-1908"
    body = gutenberg.strip_boilerplate(gutenberg.fetch(1232))

    # 26 chapters (ch. XVIII carries a footnote marker, 'CHAPTER XVIII.[1]'). Two
    # appendices follow ch. XXVI — the Duke Valentino 'Description' and the Life of
    # Castruccio; cut them off the last chapter at the 'DESCRIPTION OF THE METHODS' head.
    raw = gutenberg.split_sections(
        body, heading_re=r"^CHAPTER [IVXL]+\.(?:\[\d+\])?[ \t]*$",
        end_re=r"^DESCRIPTION OF THE METHODS")
    if len(raw) != 26:
        raise ValueError(f"The Prince: expected 26 chapters, got {len(raw)}")
    sections = [
        build_section(edition_id, f"chapter-{i:02d}", i, f"Chapter {_ROMAN[i-1]}", text, form="prose")
        for i, (_, text) in enumerate(raw, start=1)
    ]
    edition = Edition(
        id=edition_id, workId=work_id, kind="translation", language="en", form="prose",
        translator="W. K. Marriott", translatorYears=None, publishedYear=1908,
        character="The standard public-domain Prince — Marriott's clear, faithful Edwardian English.",
        overview=("William K. Marriott's 1908 translation is the most widely read public-domain "
                  "Prince: direct, unfussy, and close to Machiavelli's lean Italian. It carries "
                  "the whole argument — fortune and virtù, the lion and the fox, why it is safer "
                  "to be feared than loved — that made the book a byword for political realism."),
        provenance=Provenance(source="gutenberg", rightsStatus="public_domain",
                              rightsNote="US public domain; Marriott's translation, 1908.",
                              sourceUrl="https://www.gutenberg.org/ebooks/1232",
                              sourceId="1232", retrievedDate=RETRIEVED),
        sections=sections,
    )
    work = Work(
        id=work_id, title="The Prince", author="Niccolò Machiavelli", originalLang="it",
        composed="1513", type="politics", referenceScheme="chapter",
        defaultEditionId=edition.id, tradition="West",
        blurb=("Machiavelli's unflinching handbook of power — how principalities are won, held, "
               "and lost. Fortune and virtù, cruelty and mercy, and the founding text of modern "
               "political realism."),
        collections=["collection.great-books", "collection.harvard-classics"],
    )
    return work, [edition], None


# ---------------------------------------------------------------------------
# The Analects — James Legge translation (rev. 1893)
# ---------------------------------------------------------------------------
def analects():
    work_id = "work.confucius.analects"
    edition_id = "edition.analects.legge-1893"
    body = gutenberg.strip_boilerplate(gutenberg.fetch(3330))

    # 20 books, each titled with a Chinese name ('BOOK I.  HSIO R.'). Consume the
    # whole heading line so the subtitle doesn't bleed into the body text.
    raw = gutenberg.split_sections(body, heading_re=r"^BOOK [IVXL]+\..*$")
    if len(raw) != 20:
        raise ValueError(f"The Analects: expected 20 books, got {len(raw)}")
    sections = [
        build_section(edition_id, f"book-{i:02d}", i, f"Book {_ROMAN[i-1]}", text, form="prose")
        for i, (_, text) in enumerate(raw, start=1)
    ]
    edition = Edition(
        id=edition_id, workId=work_id, kind="translation", language="en", form="prose",
        translator="James Legge", translatorYears="1815–1897", publishedYear=1893,
        character="The scholar's Analects — Legge's careful, literal Victorian standard.",
        overview=("James Legge, the great Victorian sinologist, produced the translation that "
                  "first made the Confucian classics available in English. His Analects (revised "
                  "1893) is literal and exact, preserving the terse, aphoristic shape of the "
                  "Master's recorded sayings on learning, ritual, and ren — human-heartedness."),
        provenance=Provenance(source="gutenberg", rightsStatus="public_domain",
                              rightsNote="US public domain; Legge's translation, rev. 1893.",
                              sourceUrl="https://www.gutenberg.org/ebooks/3330",
                              sourceId="3330", retrievedDate=RETRIEVED),
        sections=sections,
    )
    work = Work(
        id=work_id, title="The Analects", author="Confucius", originalLang="lzh",
        composed="479–221 BCE", type="philosophy", referenceScheme="book.chapter",
        defaultEditionId=edition.id, tradition="East",
        blurb=("The recorded conversations of Confucius and his students — the ground text of "
               "East Asian ethics. Becoming fully human through learning, ritual, and ren "
               "(human-heartedness); the golden rule, stated as a negative."),
        collections=["collection.eastern-canon"],
    )
    return work, [edition], None


# ---------------------------------------------------------------------------
# Confessions — E. B. Pusey translation (1838)
# ---------------------------------------------------------------------------
def confessions():
    work_id = "work.augustine.confessions"
    edition_id = "edition.confessions.pusey-1838"
    body = gutenberg.strip_boilerplate(gutenberg.fetch(3296))
    raw = gutenberg.split_sections(body, heading_re=r"^BOOK [IVX]+[ \t]*$")
    if len(raw) != 13:
        raise ValueError(f"Confessions: expected 13 books, got {len(raw)}")
    sections = [
        build_section(edition_id, f"book-{i:02d}", i, f"Book {_ROMAN[i-1]}", text, form="prose")
        for i, (_, text) in enumerate(raw, start=1)
    ]
    edition = Edition(
        id=edition_id, workId=work_id, kind="translation", language="en", form="prose",
        translator="E. B. Pusey", translatorYears="1800–1882", publishedYear=1838,
        character="The devotional classic Confessions — Pusey's reverent, 'Thou'-keeping English.",
        overview=("Edward Bouverie Pusey's translation, made for the Oxford Library of the "
                  "Fathers, has been the most beloved English Confessions for nearly two "
                  "centuries. It keeps the intimate second person — Augustine speaking to God — "
                  "and the cadence of prayer: 'Thou hast made us for Thyself, and our heart is "
                  "restless, until it repose in Thee.'"),
        provenance=Provenance(source="gutenberg", rightsStatus="public_domain",
                              rightsNote="US public domain; Pusey's translation, 1838.",
                              sourceUrl="https://www.gutenberg.org/ebooks/3296",
                              sourceId="3296", retrievedDate=RETRIEVED),
        sections=sections,
    )
    work = Work(
        id=work_id, title="Confessions", author="Saint Augustine", originalLang="la",
        composed="397–400 CE", type="religion", referenceScheme="book.chapter",
        defaultEditionId=edition.id, tradition="West",
        blurb=("The first true autobiography of a soul: Augustine's restless, brilliant life "
               "turning at last toward God. Sin and conversion, memory and time, and a heart "
               "that finds no rest until it rests in God."),
        collections=["collection.great-books", "collection.harvard-classics"],
    )
    return work, [edition], None


# ---------------------------------------------------------------------------
# Hamlet — Shakespeare (original English; no translation)
# ---------------------------------------------------------------------------
def hamlet():
    work_id = "work.shakespeare.hamlet"
    edition_id = "edition.hamlet.original"
    body = gutenberg.strip_boilerplate(gutenberg.fetch(1524))
    raw = gutenberg.split_sections(body, heading_re=r"^ACT [IVX]+[ \t]*$")
    if len(raw) != 5:
        raise ValueError(f"Hamlet: expected 5 acts, got {len(raw)}")
    sections = [
        build_section(edition_id, f"act-{i:02d}", i, f"Act {_ROMAN[i-1]}", text, form="verse")
        for i, (_, text) in enumerate(raw, start=1)
    ]
    edition = Edition(
        id=edition_id, workId=work_id, kind="original", language="en", form="verse",
        translator=None, translatorYears=None, publishedYear=1603,
        character="Shakespeare's text — the tragedy entire, in five acts.",
        overview=("The Tragedy of Hamlet, Prince of Denmark, in Shakespeare's own English — no "
                  "translation needed. A father's ghost, a mother's hasty marriage, and a son "
                  "undone by thought: the most searching of the tragedies, and the source of "
                  "more familiar lines than any other play."),
        provenance=Provenance(source="gutenberg", rightsStatus="public_domain",
                              rightsNote="Public domain; Shakespeare's text via Project Gutenberg.",
                              sourceUrl="https://www.gutenberg.org/ebooks/1524",
                              sourceId="1524", retrievedDate=RETRIEVED),
        sections=sections,
    )
    work = Work(
        id=work_id, title="Hamlet", author="William Shakespeare", originalLang="en",
        composed="1600–1601", type="drama", referenceScheme="act.scene",
        defaultEditionId=edition.id, tradition="West",
        blurb=("Shakespeare's deepest tragedy: a prince, a murdered father, and the paralysis "
               "of thought. 'To be, or not to be' — the play that holds more of the language's "
               "famous lines than any other."),
        collections=["collection.lectio"],
    )
    return work, [_modern_edition(work_id, "hamlet", [edition]), edition], None


# ---------------------------------------------------------------------------
# The Epic of Gilgamesh — Lectio Modern ONLY (no clean PD English exists, so the
# Lectio Edition is the primary text, built first). First pass: Tablet I.
# ---------------------------------------------------------------------------
def gilgamesh():
    work_id = "work.gilgamesh"
    modern = _modern_edition(work_id, "gilgamesh", [])  # no PD source editions to feed in
    work = Work(
        id=work_id, title="The Epic of Gilgamesh", author="Anonymous · Sumer & Akkad",
        originalLang="akk", composed="2100–1200 BCE", type="epic_poem",
        referenceScheme="tablet.line", defaultEditionId=modern.id, tradition="East",
        blurb=("The oldest surviving epic. The king Gilgamesh and the wild man Enkidu become "
               "friends; when Enkidu dies, Gilgamesh refuses his own death and sets out to find "
               "the secret of living forever — and learns, instead, how to come home. The root "
               "beneath both East and West."),
        collections=["collection.eastern-canon"],
    )
    return work, [modern], None


# ---------------------------------------------------------------------------
# The Divine Comedy — Longfellow's translation (1867); 100 cantos (verse)
# ---------------------------------------------------------------------------
def divine_comedy():
    work_id = "work.dante.divine-comedy"
    edition_id = "edition.divine-comedy.longfellow-1867"
    body = gutenberg.strip_boilerplate(gutenberg.fetch(1004))
    raw = gutenberg.split_sections(
        body, heading_re=r"^(?:Inferno|Purgatorio|Paradiso): Canto [IVXL]+[ \t]*$")
    if len(raw) != 100:
        raise ValueError(f"Divine Comedy: expected 100 cantos, got {len(raw)}")
    sections = [
        build_section(edition_id, f"canto-{i:03d}", i, head.strip(), text, form="verse")
        for i, (head, text) in enumerate(raw, start=1)
    ]
    edition = Edition(
        id=edition_id, workId=work_id, kind="translation", language="en", form="verse",
        translator="Henry Wadsworth Longfellow", translatorYears="1807–1882", publishedYear=1867,
        character="Longfellow's landmark American Dante — faithful blank verse, line for line.",
        overview=("Henry Wadsworth Longfellow's 1867 translation was the first major American "
                  "Divine Comedy: an unrhymed, line-by-line rendering that follows Dante's sense "
                  "closely and reads with grave music. It remains among the most respected "
                  "public-domain versions, prized for fidelity over ornament."),
        provenance=Provenance(source="gutenberg", rightsStatus="public_domain",
                              rightsNote="US public domain; Longfellow's translation, 1867.",
                              sourceUrl="https://www.gutenberg.org/ebooks/1004",
                              sourceId="1004", retrievedDate=RETRIEVED),
        sections=sections,
    )
    work = Work(
        id=work_id, title="The Divine Comedy", author="Dante Alighieri", originalLang="it",
        composed="1308–1320", type="epic_poem", referenceScheme="cantica.canto",
        defaultEditionId="edition.divine-comedy.lectio-modern", tradition="West",
        blurb=("Dante's journey through Hell, Purgatory, and Paradise — guided first by Virgil, "
               "then by Beatrice. The summit of the medieval imagination and one of the supreme "
               "poems of any age."),
        collections=["collection.great-books"],
    )
    return work, [_modern_edition(work_id, "divine-comedy", [edition]), edition], None


RECIPES = [meditations, iliad, odyssey, aeneid, republic,
           nicomachean_ethics, the_prince, analects, confessions, hamlet, gilgamesh,
           divine_comedy]
