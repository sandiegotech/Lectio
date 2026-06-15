"""AI backend seam (see BIBLE.md §10.1).

Classics v1 ships with NO AI — content quality comes first. But the architecture must
accommodate several interchangeable backends later, selected at runtime by device
capability and subscription tier. This package defines the contract so build-time
enrichment (recaps, AI translations) and, by mirror, the app's runtime features can
swap backends without touching call sites.
"""
