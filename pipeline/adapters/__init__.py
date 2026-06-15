"""Source adapters: fetch + parse raw editions into clean text (pipeline stages 1-2).

One adapter per source type. Adapters do NOT decide structure — they fetch, strip
source-specific boilerplate, and offer a split helper. Per-book *recipes* supply the
heading patterns, because heading conventions vary too much to auto-detect reliably.
"""
