"""Per-book build recipes.

A recipe fetches a source, applies the book's specific structure (heading patterns,
labels), and returns (Work, [Edition], spine_or_None). Recipes are where editorial
decisions live; the generic modules stay dumb. Add a function, append it to RECIPES.
"""
from __future__ import annotations

from .adapters import gutenberg
from .model import Edition, Provenance, Work
from .segment import build_section

# Casaubon's books are headed "THE FIRST BOOK" ... "THE TWELFTH BOOK".
_ORDINAL_TO_ROMAN = {
    "FIRST": "I", "SECOND": "II", "THIRD": "III", "FOURTH": "IV",
    "FIFTH": "V", "SIXTH": "VI", "SEVENTH": "VII", "EIGHTH": "VIII",
    "NINTH": "IX", "TENTH": "X", "ELEVENTH": "XI", "TWELFTH": "XII",
}


def meditations():
    """Marcus Aurelius, *Meditations* — Méric Casaubon translation (1634), Gutenberg #2680.

    The work is in the Harvard Classics (Vol. 2). Note: the HC volume printed the
    later George Long translation; Casaubon is the edition we ingest here and can sit
    alongside a George Long edition later (the collection references the *work*).
    """
    edition_id = "edition.meditations.casaubon-1634"
    work_id = "work.marcus-aurelius.meditations"

    raw = gutenberg.fetch(2680)
    body = gutenberg.strip_boilerplate(raw)
    raw_sections = gutenberg.split_sections(
        body,
        heading_re=r"^THE [A-Z]+ BOOK[ \t]*$",
        end_re=r"^APPENDIX[ \t]*$",  # cut the trailing APPENDIX/NOTES/GLOSSARY off Book XII
    )
    if len(raw_sections) != 12:
        raise ValueError(f"Meditations: expected 12 books, got {len(raw_sections)}")

    sections = []
    for order, (heading, text) in enumerate(raw_sections, start=1):
        ordinal = heading.replace("THE ", "").replace(" BOOK", "").strip()
        roman = _ORDINAL_TO_ROMAN[ordinal]
        sections.append(
            build_section(
                edition_id=edition_id,
                section_slug=f"book-{order:02d}",
                order=order,
                label=f"Book {roman}",
                body=text,
                form="prose",
            )
        )

    edition = Edition(
        id=edition_id,
        workId=work_id,
        kind="translation",
        language="en",
        form="prose",
        provenance=Provenance(
            source="gutenberg",
            rightsStatus="public_domain",
            rightsNote="US public domain; Casaubon translation first published 1634.",
            sourceUrl="https://www.gutenberg.org/ebooks/2680",
            sourceId="2680",
            retrievedDate="2026-06-15",
        ),
        translator="Méric Casaubon",
        translatorYears="1599–1671",
        publishedYear=1634,
        character="The first English Meditations — ornate, archaic, devotional.",
        sections=sections,
    )

    work = Work(
        id=work_id,
        title="Meditations",
        author="Marcus Aurelius",
        originalLang="grc",
        composed="c. 170–180 CE",
        type="philosophy",
        referenceScheme="book.section",
        defaultEditionId=edition_id,
        blurb=(
            "The private notebook of a Roman emperor — Stoic reflections on duty, "
            "mortality, and how to live well, written only for himself."
        ),
        collections=["collection.harvard-classics"],
    )

    return work, [edition], None


RECIPES = [meditations]
