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
    kind: str                         # paragraph | verse_block | heading | epigraph
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
    introduction: Optional[str] = None  # short, skippable intro shown before the text (Lectio editions)
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
    collections: list[str] = field(default_factory=list)
    editionIds: list[str] = field(default_factory=list)


@dataclass
class CollectionItem:
    workId: str
    volume: Optional[int] = None
    note: str = ""


@dataclass
class Collection:
    id: str
    title: str
    curator: str
    blurb: str
    items: list[CollectionItem] = field(default_factory=list)


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
