# Lectio — Content Catalog & Status

_Generated from the content bundle by `tools/catalog.py` — regenerate after any build._

**12 works ingested** · **11/12 with covers** · **8/12 with a complete Lectio edition**

> Lectio (Vernacular) editions are first-pass **drafts pending human review** (BIBLE non-negotiable). The *Translated* column is the model + date that produced each one — revise when it predates the current translation method.

## Works

| Work | Author | Trad. | Cover | Lectio edition | Translated | Reads by default |
|------|--------|-------|-------|----------------|------------|------------------|
| Nicomachean Ethics | Aristotle | West | ✅ | ✅ 10 books | Opus 4.8 · 2026-06-24 | Lectio |
| Confessions | Saint Augustine | West | ✅ | ◐ 0/13 sections | Opus 4.8 · 2026-06-25 | pusey-1838 |
| The Analects | Confucius | East | ✅ | ◐ 0/20 sections | Opus 4.8 · 2026-06-25 | legge-1893 |
| The Divine Comedy | Dante Alighieri | West | ✅ | ✅ 100 cantos | Opus 4.8 · 2026-06-24 | Lectio |
| The Epic of Gilgamesh | Anonymous · Sumer & Akkad | East | ✅ | ✅ 11 tablets | Opus 4.8 · 2026-06-23 | Lectio |
| The Iliad | Homer | West | ✅ | ✅ 24 books | Opus 4.8 · 2026-06-15 | Lectio |
| The Odyssey | Homer | West | ✅ | ✅ 24 books | Opus 4.8 · 2026-06-16 | Lectio |
| The Prince | Niccolò Machiavelli | West | ✅ | ◐ 0/26 sections | Opus 4.8 · 2026-06-25 | marriott-1908 |
| Meditations | Marcus Aurelius | West | ✅ | ✅ 12 books | Opus 4.8 · 2026-06-15 | Lectio |
| The Republic | Plato | West | ✅ | ◐ 0/10 sections | Opus 4.8 · 2026-06-25 | jowett-1871 |
| Hamlet | William Shakespeare | West | ❌ needs cover | ✅ 5 acts | Opus 4.8 · 2026-06-24 | original |
| The Aeneid | Virgil | West | ✅ | ✅ 12 books | Opus 4.8 · 2026-06-16 | Lectio |

## Needs attention

- **Missing a work cover** (1): Hamlet  
  → add `content/works/<id>/cover.jpg` (master in `~/Documents/Lectio-Masters/`, see CLAUDE.md).
- **No Lectio edition yet** (0): none  
  → run the overnight loop (`tools/overnight/`) or `/ingest-book` then translate.
- **Planned shelf works missing cover art** (15): Beyond Good and Evil, Epic and Saga, Genesis, Hamlet, Seven Pillars of Wisdom, The Brothers Karamazov, The Holy Bible, The Interpretation of Dreams, The Principles of Psychology, The Talmud, The Tanakh, The Trial, The Waste Land, Ulysses, War and Peace  
  → add the art under `content/collections/book-covers/` and set its `cover` in `pipeline/collections.py`.

## Editions on hand

**Nicomachean Ethics** · `work.aristotle.nicomachean-ethics`
  - **Lectio (Vernacular)** — Opus 4.8, 2026-06-24; base: `chase-1911` — 10 books
  - D. P. Chase 1911 — 10 books

**Confessions** · `work.augustine.confessions`
  - **Lectio (Vernacular)** — Opus 4.8, 2026-06-25; base: `pusey-1838` — 0 sections
  - E. B. Pusey 1838 — 13 books

**The Analects** · `work.confucius.analects`
  - **Lectio (Vernacular)** — Opus 4.8, 2026-06-25; base: `legge-1893` — 0 sections
  - James Legge 1893 — 20 books

**The Divine Comedy** · `work.dante.divine-comedy`
  - **Lectio (Vernacular)** — Opus 4.8, 2026-06-24; base: `longfellow-1867` — 100 cantos
  - Henry Wadsworth Longfellow 1867 — 100 cantos

**The Epic of Gilgamesh** · `work.gilgamesh`
  - **Lectio (Vernacular)** — Opus 4.8, 2026-06-23 — 11 tablets

**The Iliad** · `work.homer.iliad`
  - **Lectio (Vernacular)** — Opus 4.8, 2026-06-15; base: `pope-1715` — 24 books
  - Samuel Butler 1898 — 24 books
  - Alexander Pope 1715 — 24 books

**The Odyssey** · `work.homer.odyssey`
  - **Lectio (Vernacular)** — Opus 4.8, 2026-06-16; base: `butler-1900` — 24 books
  - Samuel Butler 1900 — 24 books

**The Prince** · `work.machiavelli.the-prince`
  - **Lectio (Vernacular)** — Opus 4.8, 2026-06-25; base: `marriott-1908` — 0 sections
  - W. K. Marriott 1908 — 26 chapters

**Meditations** · `work.marcus-aurelius.meditations`
  - **Lectio (Vernacular)** — Opus 4.8, 2026-06-15; base: `long-1862` — 12 books
  - Méric Casaubon 1634 — 12 books
  - George Long 1862 — 12 books
  - Original (grc) — 12 books

**The Republic** · `work.plato.republic`
  - **Lectio (Vernacular)** — Opus 4.8, 2026-06-25; base: `jowett-1871` — 0 sections
  - Benjamin Jowett 1871 — 10 books

**Hamlet** · `work.shakespeare.hamlet`
  - **Lectio (Vernacular)** — Opus 4.8, 2026-06-24; base: `original` — 5 acts
  - **Lectio (Vernacular)** — Opus 4.8, 2026-06-24; base: `original` — 5 acts
  - Original (en) — 5 acts

**The Aeneid** · `work.virgil.aeneid`
  - **Lectio (Vernacular)** — Opus 4.8, 2026-06-16; base: `dryden-1697` — 12 books
  - John Dryden 1697 — 12 books

## Not yet ingested

Planned / “coming soon” shelf works are defined in `pipeline/collections.py` (and shown greyed in the app) but have no content bundle yet, so they are not listed above. Ingest a work with the `/ingest-book` skill.
