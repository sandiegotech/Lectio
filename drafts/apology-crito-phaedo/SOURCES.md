# The Trial and Death of Socrates — sources

Plato, *Apology*, *Crito*, *Phaedo*, set as one work in three dialogues.
Slug `apology-crito-phaedo`. Drafted 2026-11-17.

## The public-domain base (control on meaning)

Benjamin Jowett (1817–1893), *The Dialogues of Plato*, 3rd ed., Oxford 1892. Public domain.

| Dialogue | Project Gutenberg | Cached as | Text begins |
|---|---|---|---|
| Apology | #1656, https://www.gutenberg.org/ebooks/1656 | `pipeline/.cache/gutenberg-1656.txt` | line 486, "How you, O Athenians" |
| Crito | #1657, https://www.gutenberg.org/ebooks/1657 | `pipeline/.cache/gutenberg-1657.txt` | line 410, "PERSONS OF THE DIALOGUE" |
| Phaedo | #1658, https://www.gutenberg.org/ebooks/1658 | `pipeline/.cache/gutenberg-1658.txt` | line 1375, "PERSONS OF THE DIALOGUE" |

www.gutenberg.org was down for maintenance on the day of the draft, so the three files were
fetched with curl from the Project Gutenberg mirror, `https://gutenberg.pglaf.org/1/6/5/<id>/`
(`1656-0.txt`, `1657.txt`, `1658.txt`). They are the same files the ingest adapter fetches from
`https://www.gutenberg.org/cache/epub/<id>/pg<id>.txt`.

Jowett's introductions (Apology lines 49–482, Crito 296–400, Phaedo 44–1371) are his own
essays and are **not** part of the text. Nothing from them is in the draft. Jowett prints no
footnotes inside these three translations, but he does add words of explanation in places
(for example "the son of Thetis" is left, but "God" is printed for ὁ θεός throughout); the
draft follows the Greek.

## The original

Plato, *Platonis Opera*, vol. I, ed. John Burnet (1863–1928), Oxford Classical Texts, 1900.
Public domain. Digital text from the Perseus Digital Library (Tufts), `canonical-greekLit`,
TEI XML, licensed CC BY-SA; it is used here only as the text checked against, not reproduced.

| Dialogue | URL | Cached as |
|---|---|---|
| Apology (tlg0059.tlg002) | https://raw.githubusercontent.com/PerseusDL/canonical-greekLit/master/data/tlg0059/tlg002/tlg0059.tlg002.perseus-grc2.xml | `pipeline/.cache/perseus-tlg0059.tlg002.perseus-grc2.xml` |
| Crito (tlg0059.tlg003) | …/tlg003/tlg0059.tlg003.perseus-grc2.xml | `pipeline/.cache/perseus-tlg0059.tlg003.perseus-grc2.xml` |
| Phaedo (tlg0059.tlg004) | …/tlg004/tlg0059.tlg004.perseus-grc2.xml | `pipeline/.cache/perseus-tlg0059.tlg004.perseus-grc2.xml` |

For reading, each XML file was flattened to plain text, one Stephanus section per line with
the section number in square brackets and speaker labels in braces:
`pipeline/.cache/burnet-apology-grc.txt`, `burnet-crito-grc.txt`, `burnet-phaedo-grc.txt`.
Find a passage with, for example, `grep -n '^\[117c\]' pipeline/.cache/burnet-phaedo-grc.txt`.

## Sections

Ten sections, in order. The Apology and Crito have no internal divisions in Jowett beyond the
three speeches of the Apology; the Phaedo is divided at the joints of its argument. References
are Stephanus pages (vol. I), as printed in Burnet.

| File | Label | Title | Stephanus |
|---|---|---|---|
| book-01.json | Apology · The Defense | The Defense | *Apology* 17a–35d |
| book-02.json | Apology · The Counter-Penalty | The Counter-Penalty | *Apology* 35e–38b |
| book-03.json | Apology · The Last Words | The Last Words | *Apology* 38c–42a |
| book-04.json | Crito | Crito | *Crito* 43a–54e |
| book-05.json | Phaedo · The Philosopher's Death | The Philosopher's Death | *Phaedo* 57a–69e |
| book-06.json | Phaedo · Opposites and Recollection | Opposites and Recollection | *Phaedo* 69e–78b |
| book-07.json | Phaedo · The Soul's Kinship | The Soul's Kinship | *Phaedo* 78b–84b |
| book-08.json | Phaedo · Two Objections | Two Objections | *Phaedo* 84c–95a |
| book-09.json | Phaedo · The Final Argument | The Final Argument | *Phaedo* 95a–107b |
| book-10.json | Phaedo · The True Earth and the Death | The True Earth and the Death | *Phaedo* 107c–118a |

What each Phaedo section holds:

- **57a–69e.** The frame at Phlius; the prison; pleasure and pain; Evenus and the ban on
  suicide; Socrates' defense of the philosopher's readiness to die.
- **69e–78b.** Cebes' doubt; the argument from opposites (70c–72e); the argument from
  recollection (72e–77a); the two joined, and the child within who fears the dark (77a–78b).
- **78b–84b.** The argument from affinity; the fate of pure and impure souls; philosophy as
  release.
- **84c–95a.** The swan song; Simmias' objection (the attunement) and Cebes' (the weaver);
  the break in the frame; the warning against hatred of argument (89d–91c); the reply to
  Simmias (91c–95a).
- **95a–107b.** Cebes' objection restated; Socrates' own history and Anaxagoras; the second
  voyage and the method of hypothesis; the frame again (102a); the final argument.
- **107c–118a.** The story of the true earth and the rivers of the underworld (107c–115a);
  the death of Socrates (115a–118a).

## Consulted, not quoted

Burnet's commentaries (*Plato's Phaedo*, 1911; *Euthyphro, Apology and Crito*, 1924), for
the sense of the Greek at the cruxes recorded in each section's `divergences`. Modern
translations are research inputs only; no wording is taken from any translation in copyright.
