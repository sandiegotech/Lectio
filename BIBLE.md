# Project Bible — Lectio

> *Lectio* (Latin: "a reading"). The goal is simple and ambitious: **let any person today read a great
> work of the Western canon — any of the Harvard Classics — with genuine ease.** Built for iPad first,
> then iPhone and Mac.

---

## 1. The North Star

The greatest books ever written are free and in the public domain — and almost nobody reads them. Not
because people aren't capable, but because the on-ramp is brutal: archaic translations, no context, dense
walls of text, names and references that assume a 1900 classical education. Existing reading apps (Kindle,
Apple Books) just hand you the same forbidding 1909 file and wish you luck.

**Lectio removes the friction.** Open *The Iliad* or *Meditations* and you get a clear, modern, readable
version by default — then, the moment you're curious, you can hold it against any historical translation or
the original language, with the people, words, and ideas explained right beside the text. The measure of
success: *a smart, busy person with no classics background finishes a great book and feels it was easy and
worth it.*

---

## 2. The Flagship: the Lectio Modern Edition

The headline feature, and the thing only we do: **a fresh, plain-modern-English edition of each work,
produced by deep research.** This is what makes a daunting classic feel like a great book you can actually
read today.

**What it is.** A faithful rendering of the work into clear contemporary English — the sense and force of the
original, in the language people actually read now. Not a dumbed-down summary; a real, readable edition.

**How it's made (the deep-research process).** For each section we:
1. Gather *all* the public-domain translations of that passage + the original-language text.
2. Research the passage: what it means, where translators diverge, what context a modern reader is missing.
3. Produce a modern rendering that is faithful to the original and grounded in the existing translations —
   not invented from nothing, but triangulated from the source and the scholarly record.
4. **Human review gate** before publish — checked against the sources for accuracy and flagged where the text
   is genuinely interpretive.

**Honesty is non-negotiable.** The Modern Edition is clearly labeled as *Lectio's* modern edition, a
derivative of public-domain sources. Its provenance records the source editions consulted, the method, the
model/researcher, and the date. It is **never** passed off as a historical translation. This is the same
provenance discipline applied to every word in the app (see §6).

**It's the default, not the only option.** You read the Modern Edition by default; one tap switches to any
public-domain translation (Pope, Butler, Long, Casaubon…) or the original language. *Accessibility by
default, depth on demand.*

---

## 3. Read Any Version (already built)

Every work carries multiple **editions**: the Lectio Modern Edition, every public-domain translation we can
source, and the **original-language** text. The reader has an edition switcher: latest/most-readable first,
the original last. Switching keeps your place (same book/chapter across editions). Each edition shows its
translator, year, a one-line "character," and its provenance.

*Status: shipped for Meditations (George Long 1862, Méric Casaubon 1634, and the Greek original).*

---

## 4. The Margin — comprehension beside the text

The signature UI ("The Margin"): the reading column stays calm while a quiet right-hand **rail** carries the
living layer — tap a word for its definition, see the people in the passage, the connections to other works
and ideas, your saved words, and your reading progress. This is where context lives so the text doesn't have
to be interrupted. (Later: the full connection graph, art per scene — see §7.)

*Status: shipped — tap-to-explore words, save words, editorial enrichment per passage.*

---

## 5. The Corpus — start with 3 works, get it right

We prove the whole experience (Modern Edition + multi-translation + Margin) on **three great works** before
scaling to the rest of the Harvard Classics:

1. **Meditations** — Marcus Aurelius (Stoic philosophy). *In progress.*
2. **The Iliad** — Homer (epic poetry; the multi-translation showcase: Pope's couplets vs. Butler's prose).
3. **Plato or Aristotle** — a foundational philosophical work. Recommended: **Plato's *Apology / Crito /
   Phaedo*** (the trial and death of Socrates) — short, gripping, and far more approachable than Aristotle
   for a first reader. (Both are in Harvard Classics Vol. 2 alongside Meditations.) *Decision pending.*

Getting these three right — especially the Modern Edition quality — is the whole game. Breadth comes after.

---

## 6. Sourcing & Rights (the discipline)

| Layer | Source | Rights |
|---|---|---|
| Public-domain translations | Standard Ebooks, Project Gutenberg, Wikisource | PD; redistributable |
| Original-language texts | Wikisource, etc. | PD |
| **Lectio Modern Edition** | Produced by us from PD sources via deep research | Ours; provenance = sources + method + date |
| Modern in-copyright translations (Fagles, Wilson…) | — | **Never included** |
| Dictionary | Webster's 1913 (PD) | PD |
| Art (later) | Museum open-access, Wikimedia Commons | PD / CC0 |

**Rule:** every piece of content carries a provenance record or it doesn't ship. The Modern Edition lives or
dies on this — accessibility must never come at the cost of honesty about what the reader is reading.

---

## 7. Beyond the MVP (the depth layer)

The connection graph ("Connect Gloss"): works, people, places, ideas, and artworks as linked nodes — walk a
work's influences and descendants, jump between every author on a theme, see the art a scene inspired. The
Margin is already the surface for this; the graph fills it in. Shared with the sibling app **Gloss**.

---

## 8. Ecosystem, AI & Business Model

**Ecosystem.** Lectio is one of several apps sharing an account-level identity and a tuned AI ("the
Philosopher") with the sibling app **Gloss**. Lectio *consumes* these; it doesn't own them.

**AI strategy (swappable, deferred).** The pipeline ships no live AI; the Modern Edition is produced offline
and reviewed, then served as static, finished content. Runtime comprehension aids route through a capability
layer with interchangeable backends:
- **Apple Foundation Models** — on-device, free, offline; light aids (define, recap, simplify) where hardware allows.
- **Gemma (MLX)** — later optional offline pack.
- **Claude API** — the cloud tuned "Philosopher"; highest fidelity, cross-app, any device.

**Business model — SDIT subscription.**
- **Free** — read any public-domain edition + the original, the Margin's basic aids, dictionary, saved words.
- **SDIT subscription** — the **Lectio Modern Edition** (the deep-research modern translations) + the cloud AI
  comprehension aids and cross-app intelligence. Tiers: *Student* and *Philosopher*. Login ships from day one.

The split: **public-domain reading is free; the modern, made-for-today experience is the paid value.**

---

## 9. Roadmap

- **P0 — Foundation** *(done)*: pipeline → portable JSON bundle; stable IDs; provenance; iPad reader.
- **P1 — Multi-edition reading** *(done)*: edition switcher; Meditations w/ 3 editions; the Margin; word save.
- **P2 — The 3-work corpus**: ingest Iliad (multiple PD translations) + Plato/Aristotle; fuller enrichment;
  full Webster's 1913 dictionary so every word resolves.
- **P3 — The Modern Edition**: build the deep-research production process; produce + review the Modern Edition
  for the 3 works; ship it as the default edition; account/login + subscription gating.
- **P4 — Depth**: connection graph, art per scene, the 15-min/day Harvard reading path, streaks.
- **P5 — Scale**: the rest of the Harvard Classics; more collections.

## 10. The MVP

**A reader where a newcomer opens one of the 3 works, reads the Lectio Modern Edition with ease, taps a hard
word and gets it, switches to a historical translation or the Greek out of curiosity, and finishes feeling it
was approachable.** Free public-domain reading + the paid Modern Edition, proven on three works.

## 11. Open questions
- Plato vs. Aristotle for work #3 (recommend Plato's *Apology/Crito/Phaedo*).
- How much of the Modern Edition is acceptable to generate vs. how much human review per work.
- Exact free/Student/Philosopher boundaries and pricing.
- Original-language depth (display only, or interlinear/lexical for Greek/Latin).
