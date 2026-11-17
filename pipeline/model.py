"""Canonical data model for Lectio content.

These dataclasses ARE the contract. The pipeline produces them; they serialize to
the JSON bundle the app consumes (see CONTENT_PIPELINE.md §2, §7). Keep field names
and shapes in sync with the Swift Codable models in app/Lectio/Models.swift.

Design rules:
- Stable IDs never change once published (see id-ledger handling in publish.py).
- Every Edition and media asset carries a Provenance record.
- Output is plain, portable JSON. No app coupling.
"""
from __future__ import annotations

from dataclasses import dataclass, field, asdict
from typing import Optional


# ---------------------------------------------------------------------------
# Provenance — required on every Edition and media asset
# ---------------------------------------------------------------------------
@dataclass
class Provenance:
    source: str                       # standard_ebooks | gutenberg | wikisource | archive_org | ai | museum | seed
    rightsStatus: str                 # public_domain | cc0 | cc-by | ...
    rightsNote: str = ""
    sourceUrl: Optional[str] = None
    sourceId: Optional[str] = None
    retrievedDate: Optional[str] = None
    # AI / Lectio Modern Edition:
    aiModel: Optional[str] = None     # model used to produce the edition
    aiSourceEditionId: Optional[str] = None
    aiProfile: Optional[str] = None   # plain_modern | faithful | poetic
    sourcesCited: Optional[list] = None   # named sources synthesized (translations, scholarship)
    tokensEstimated: Optional[int] = None # est. tokens used to produce (input sources + output)
    vintage: Optional[int] = None         # edition year, for citable vintages
    revised: Optional[str] = None     # date of the last revision within this vintage (YYYY-MM-DD)
    # Museum images:
    creator: Optional[str] = None
    holdingInstitution: Optional[str] = None


# ---------------------------------------------------------------------------
# Spine — alignment coordinate for cross-translation sync (CONTENT_PIPELINE.md §4)
# ---------------------------------------------------------------------------
@dataclass
class SpineRange:
    fromRef: str                      # e.g. "1.1"  (book.line for Homer)
    toRef: str                        # e.g. "1.7"


# ---------------------------------------------------------------------------
# Segment — the atomic readable unit; everything anchors to its id
# ---------------------------------------------------------------------------
@dataclass
class Segment:
    id: str                           # frozen once published, e.g. edition...book-01.seg-0007
    order: int
    kind: str                         # paragraph | verse_block | heading | epigraph | omit
    text: str                         # may contain '\n' for verse line breaks
    spine: Optional[SpineRange] = None


@dataclass
class Section:
    id: str
    order: int
    label: str                        # "Book I"
    title: Optional[str] = None       # "The Contention of Achilles and Agamemnon"
    segments: list[Segment] = field(default_factory=list)


@dataclass
class Edition:
    id: str
    workId: str
    kind: str                         # modern | translation | original | ai_translation
                                      #   modern = the Lectio Modern Edition (deep-research; default for reading)
    language: str                     # ISO 639-1
    form: str                         # verse | prose
    provenance: Provenance
    translator: Optional[str] = None
    translatorYears: Optional[str] = None
    publishedYear: Optional[int] = None
    character: str = ""               # one-line "feel" of this translation
    overview: Optional[str] = None    # fuller note: the translator's approach + how it compares to other editions
    introduction: Optional[str] = None  # short, skippable intro shown before the text (Lectio editions)
    divergences: Optional[list] = None  # Lectio Edition only: notable departures from older translations, with reasons
                                        #   each: {locus?, phrase?, older, lectio, note}
    sections: list[Section] = field(default_factory=list)


@dataclass
class Work:
    id: str
    title: str
    author: str
    originalLang: str
    composed: str
    type: str                         # epic_poem | philosophy | drama | ...
    referenceScheme: str              # "book.line" | "book.chapter" | "linear"
    defaultEditionId: str
    blurb: str = ""
    tradition: str = "West"           # West | East — drives broad shelf identity and cover theme
    collections: list[str] = field(default_factory=list)
    editionIds: list[str] = field(default_factory=list)
    # "YYYY-MM-DD" from catalog/books.json; absent = already out. The app hides a work
    # until this day (app/Lectio/Library.swift).
    releaseDate: Optional[str] = None


@dataclass
class CollectionItem:
    workId: str
    volume: Optional[int] = None
    note: str = ""
    part: str = ""      # sub-section within a collection (e.g. "The New Testament")


@dataclass
class PlannedWork:
    """A shell on a shelf — a work not yet ingested, shown as a 'coming soon' placeholder.
    Ingest the work and add it to the collection to replace the shell."""
    title: str
    author: str = ""
    era: str = ""        # when the work is from, for context (e.g. "c. 800–200 BCE")
    part: str = ""       # sub-section within a collection (e.g. "India", "China")
    note: str = ""       # a basic one-line overview of the book
    tradition: str = ""  # West | East — drives broad shelf identity and cover theme
    cover: Optional[str] = None  # optional path under content/ for a planned-work cover
    originalCover: Optional[str] = None  # optional cover for the public-domain/source translation
    rights: Optional[str] = None  # "in-copyright" for works not yet free; else public domain / Lectio edition
    opens: Optional[int] = None   # year an in-copyright work enters the public domain


@dataclass
class Collection:
    id: str
    title: str
    curator: str
    blurb: str
    about: Optional[str] = None    # the backstory, shown on the collection's own page
    introduction: Optional[str] = None   # a longer readable Lectio overview (the "introduction" book)
    kind: str = "series"   # series = a recognized canon; theme = a Lectio cross-cutting grouping
    group: Optional[str] = None   # optional umbrella header several shelves share (e.g. "Religious Texts")
    items: list[CollectionItem] = field(default_factory=list)
    planned: list[PlannedWork] = field(default_factory=list)


def to_json_dict(obj) -> dict:
    """Serialize a dataclass to a plain dict, dropping None values and renaming
    fields whose Python name differs from the JSON contract (fromRef/toRef -> from/to)."""
    d = asdict(obj)
    return _clean(d)


def _clean(value):
    if isinstance(value, dict):
        out = {}
        for k, v in value.items():
            if v is None:
                continue
            # JSON contract uses reserved-word-friendly names
            jk = {"fromRef": "from", "toRef": "to"}.get(k, k)
            out[jk] = _clean(v)
        return out
    if isinstance(value, list):
        return [_clean(v) for v in value]
    return value
