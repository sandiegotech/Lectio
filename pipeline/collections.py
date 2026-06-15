"""Curated collections — the app's 'shelves' (BIBLE.md §3).

Collection metadata lives here; membership is declared on each Work (`collections=[...]`)
so a work can belong to several shelves. `build_collections` assembles each Collection's
item list from the works that reference it.
"""
from __future__ import annotations

from .model import Collection, CollectionItem

COLLECTIONS = {
    "collection.harvard-classics": {
        "title": "The Harvard Classics",
        "curator": "Charles W. Eliot (1909)",
        "blurb": (
            "Dr. Eliot's famous 'Five-Foot Shelf of Books' — a 51-volume anthology "
            "assembled in 1909 to deliver a liberal education in fifteen minutes a day."
        ),
    },
    "collection.epics": {
        "title": "Epics of War & Homecoming",
        "curator": "A Lectio collection",
        "blurb": (
            "The founding epics of the Western imagination — war, the long road home, "
            "gods and mortals, and the weight of fate."
        ),
    },
}


def build_collections(works) -> list[Collection]:
    items: dict[str, list[CollectionItem]] = {cid: [] for cid in COLLECTIONS}
    for w in works:
        for cid in getattr(w, "collections", []):
            if cid in items:
                items[cid].append(CollectionItem(workId=w.id))

    return [
        Collection(
            id=cid,
            title=meta["title"],
            curator=meta["curator"],
            blurb=meta["blurb"],
            items=items[cid],
        )
        for cid, meta in COLLECTIONS.items()
        if items[cid]  # only publish shelves that actually have works
    ]
