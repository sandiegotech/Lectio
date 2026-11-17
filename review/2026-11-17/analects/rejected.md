# The Analects · lectio-modern · rejected issues (verify, run 2026-11-17)

- I.12 `seg-0012` · "To know the worth of ease and be easy" — rejected: the echo mirrors 知和而和 on purpose; the jingle is the source's.
- I.15 `seg-0015` · "Tell him what came before, and he knows what comes next." — rejected: 告諸往而知來者 has no subject; the conditional imperative is ordinary English, and Legge's "I told him" is his interpretation.
- V.13 `seg-0013` · "no one gets to hear" — rejected: 不可得而聞 is literally "cannot get to hear"; "get to" is plain current English, not slang.
- VI.1 `seg-0001` · "seat him on a throne" — rejected: 可使南面 means he could hold a ruler's seat; a prince's seat is a throne too, and the line keeps its force.
- VI.28 `seg-0028` · "wanting to arrive, he helps others arrive" — rejected: 達 is to get through, to succeed, and "arrive" carries that sense today; the proposed "get on" is weaker.
- VII.25 `seg-0025` · "A sage I will never get to see" — rejected: 不得而見 is literally "not get to see"; plain, not chatty (same ruling as V.13).
- XII.4 `seg-0004` · "finds nothing to be sick over" — rejected: 疚 is a chronic sore or ailment, and the phrase keeps the image in plain words.
- Curly quotes, form issue raised at VI.1, VII.1, VIII.1, IX.2, X.3 — not rejected, but handled as one policy: every segment in Books VI–X with curly marks gets an entry that normalizes the span to straight quotes. These entries come first in patch.json, and no content fix's `old` contains a quote mark, so the two kinds of entry apply in either order.

## Finish (2026-11-17)

Patch was already applied to `pipeline/modern/analects.json`. Paragraph counts checked before and after: 471, identical per section. JSON formatting kept (indent 2, non-ASCII, no trailing newline).

- **Policy: straight quotes.** Section text was already all straight after the patch (0 curly marks in Books I–XX). The same split ran through the divergence notes for Books VI–X: 11 notes, 35 marks (12 “, 12 ”, 11 ’). Curly apostrophes became `'`; curly double quotes became straight single quotes, the convention every other note already uses for quoting (the notes held no straight double quotes). No curly mark is left anywhere in the file.
- **Divergence notes rewritten: 3**, where the patch changed or reversed the quoted wording. VIII.2: `lectio` now "honesty without ritual is harshness"; the note now argues for "harshness" (the knife image was the translator's). XVII.9: `lectio` now "They can teach you how to voice a grievance", note says why not "complain". XX.1: `lectio` now "Hold faithfully to the center", note adds the reason for "faithfully". Overview and introduction unchanged; they describe no reversed choice. Other notes flagged by overlap (VI.1, VI.16, VI.23, VII.14, VII.29, VIII.9, VIII.12, IX.5, IX.22, IX.25, X.18, XVI.1, XII) quote text the patch only re-quoted or did not touch.
- **Left for the editor.**
  - Gloss policy: the glosses removed from V.15, XIV.19 (Wan, "the cultured") and XI.5 (the content of Nan Yung's ode) need margin entries in `content/works/work.confucius.analects/enrichment.json` if they are wanted.
  - Pre-existing, not caused by the patch: the X.6 note quotes only the first clause of its sentence, and the XI note on 過猶不及 quotes "Too far is no better than not far enough." where the text interrupts it with "said the Master". Both fine as quotations; listed only because they do not match the text verbatim.
