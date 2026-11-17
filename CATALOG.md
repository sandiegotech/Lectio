# Lectio — Content Catalog & Status

_Generated from the content bundle by `tools/catalog.py` — regenerate after any build._

**17 works ingested** · **17/17 with covers** · **17/17 with a complete Lectio edition**

> Lectio (Vernacular) editions are first-pass **drafts pending human review** (BIBLE non-negotiable). The *Translated* column is the model + date that produced each one — revise when it predates the current translation method.

## Works

| Work | Author | Trad. | Cover | Lectio edition | Translated | Reads by default |
|------|--------|-------|-------|----------------|------------|------------------|
| Nicomachean Ethics | Aristotle | West | ✅ | ✅ 10 books | Opus 4.8 · 2026-06-24 | Lectio |
| Confessions | Saint Augustine | West | ✅ | ✅ 13 books | Fable 5 · 2026-07-07 | Lectio |
| Genesis | Anonymous · Ancient Israel | West | ✅ | ✅ 50 chapters | claude-opus-5 · 2026-08-06 | kjv-1611 |
| The Gospel of Mark | Anonymous · attributed to Mark | West | ✅ | ✅ 16 chapters | claude-opus-5 · 2026-08-06 | Lectio |
| The Analects | Confucius | East | ✅ | ✅ 20 books | Fable 5 · 2026-07-07 | Lectio |
| The Divine Comedy | Dante Alighieri | West | ✅ | ✅ 100 cantos | Opus 4.8 · 2026-06-24 | Lectio |
| The Dhammapada | Early Buddhist tradition | East | ✅ | ✅ 26 chapters | Opus 4.8 · 2026-06-26 | Lectio |
| The Epic of Gilgamesh | Anonymous · Sumer & Akkad | East | ✅ | ✅ 11 tablets | Opus 4.8 · 2026-06-23 | Lectio |
| The Iliad | Homer | West | ✅ | ✅ 24 books | Opus 4.8 · 2026-06-15 | Lectio |
| The Odyssey | Homer | West | ✅ | ✅ 24 books | Opus 4.8 · 2026-06-16 | Lectio |
| The Tao Te Ching | Laozi | East | ✅ | ✅ 81 chapters | Opus 4.8 · 2026-06-27 | Lectio |
| The Prince | Niccolò Machiavelli | West | ✅ | ✅ 26 chapters | Fable 5 · 2026-07-07 | Lectio |
| Meditations | Marcus Aurelius | West | ✅ | ✅ 12 books | Opus 4.8 · 2026-06-15 | Lectio |
| The Republic | Plato | West | ✅ | ✅ 10 books | Fable 5 · 2026-07-07 | Lectio |
| Hamlet | William Shakespeare | West | ✅ | ✅ 5 acts | Opus 4.8 · 2026-06-24 | original |
| The Aeneid | Virgil | West | ✅ | ✅ 12 books | Opus 4.8 · 2026-06-16 | Lectio |
| The Bhagavad Gita |  | East | ✅ | ✅ 18 chapters | Opus 4.8 · 2026-06-26 | Lectio |

## Needs attention

- **Missing a work cover** (0): none  
  → add `content/works/<id>/cover.jpg` (master in `~/Documents/Lectio-Masters/`, see CLAUDE.md).
- **No Lectio edition yet** (0): none  
  → run the overnight loop (`tools/overnight/`) or `/ingest-book` then translate.
- **Planned shelf works missing cover art** (0): none  
  → add the art under `content/collections/book-covers/` and set its `cover` in `pipeline/collections.py`.

## Editions on hand

**Nicomachean Ethics** · `work.aristotle.nicomachean-ethics`
  - **Lectio (Vernacular)** — Opus 4.8, 2026-06-24; base: `chase-1911` — 10 books
  - D. P. Chase 1911 — 10 books

**Confessions** · `work.augustine.confessions`
  - **Lectio (Vernacular)** — Fable 5, 2026-07-07; base: `pusey-1838` — 13 books
  - E. B. Pusey 1838 — 13 books

**Genesis** · `work.bible.genesis`
  - **Lectio (Vernacular)** — claude-opus-5, 2026-08-06; base: `kjv-1611` — 50 chapters
  - The King James translators 1611 — 50 chapters

**The Gospel of Mark** · `work.bible.mark`
  - **Lectio (Vernacular)** — claude-opus-5, 2026-08-06; base: `kjv-1611` — 16 chapters
  - The King James translators 1611 — 16 chapters

**The Analects** · `work.confucius.analects`
  - **Lectio (Vernacular)** — Fable 5, 2026-07-07; base: `legge-1893` — 20 books
  - James Legge 1893 — 20 books

**The Divine Comedy** · `work.dante.divine-comedy`
  - **Lectio (Vernacular)** — Opus 4.8, 2026-06-24; base: `longfellow-1867` — 100 cantos
  - Henry Wadsworth Longfellow 1867 — 100 cantos

**The Dhammapada** · `work.dhammapada`
  - **Lectio (Vernacular)** — Opus 4.8, 2026-06-26; base: `muller-1881` — 26 chapters
  - F. Max Müller 1881 — 26 chapters

**The Epic of Gilgamesh** · `work.gilgamesh`
  - **Lectio (Vernacular)** — Opus 4.8, 2026-06-23 — 11 tablets

**The Iliad** · `work.homer.iliad`
  - **Lectio (Vernacular)** — Opus 4.8, 2026-06-15; base: `pope-1715` — 24 books
  - Samuel Butler 1898 — 24 books
  - Alexander Pope 1715 — 24 books

**The Odyssey** · `work.homer.odyssey`
  - **Lectio (Vernacular)** — Opus 4.8, 2026-06-16; base: `butler-1900` — 24 books
  - Samuel Butler 1900 — 24 books

**The Tao Te Ching** · `work.laozi.tao-te-ching`
  - **Lectio (Vernacular)** — Opus 4.8, 2026-06-27; base: `legge-1891` — 81 chapters
  - James Legge 1891 — 81 chapters

**The Prince** · `work.machiavelli.the-prince`
  - **Lectio (Vernacular)** — Fable 5, 2026-07-07; base: `marriott-1908` — 26 chapters
  - W. K. Marriott 1908 — 26 chapters

**Meditations** · `work.marcus-aurelius.meditations`
  - **Lectio (Vernacular)** — Opus 4.8, 2026-06-15; base: `long-1862` — 12 books
  - Méric Casaubon 1634 — 12 books
  - George Long 1862 — 12 books
  - Original (grc) — 12 books

**The Republic** · `work.plato.republic`
  - **Lectio (Vernacular)** — Fable 5, 2026-07-07; base: `jowett-1871` — 10 books
  - Benjamin Jowett 1871 — 10 books

**Hamlet** · `work.shakespeare.hamlet`
  - **Lectio (Vernacular)** — Opus 4.8, 2026-06-24; base: `original` — 5 acts
  - Original (en) — 5 acts

**The Aeneid** · `work.virgil.aeneid`
  - **Lectio (Vernacular)** — Opus 4.8, 2026-06-16; base: `dryden-1697` — 12 books
  - John Dryden 1697 — 12 books

**The Bhagavad Gita** · `work.vyasa.bhagavad-gita`
  - **Lectio (Vernacular)** — Opus 4.8, 2026-06-26; base: `arnold-1885` — 18 chapters
  - Edwin Arnold 1885 — 18 chapters

## Not yet ingested

Planned / “coming soon” shelf works are defined in `pipeline/collections.py` (and shown greyed in the app) but have no content bundle yet, so they are not listed above. Ingest a work with the `/ingest-book` skill.
