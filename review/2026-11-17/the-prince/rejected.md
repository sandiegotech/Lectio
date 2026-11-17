# The Prince · lectio-modern · rejected issues (verify, run 2026-11-17)

- IV `seg-0003` · the report's fix "slaves and bondmen, are hard to corrupt": rejected as worded; "bondmen" misreads *obligati* (beholden to the lord) as serfdom. A different minimal fix ("slaves and beholden to him") is in patch.json.
- VIII `seg-0002` · the report's fix "after taking up soldiering, he rose through its ranks": rejected as worded ("its" has no ranks to point to); patched as "after joining the army".
- XVII `seg-0004` · present the Virgil translation as an editorial gloss: rejected as a text patch. It is already its own segment, as Marriott's translations are; how it is set apart is a rendering question for the app, with no wording to change.
- XIX `seg-0017` · the report's fix "for a sluggard": rejected as worded (archaic); patched as "Knowing how slack the emperor Julianus was".
- XXI `seg-0003` · the report's fix "no claim, and nothing, to defend you or give you shelter": rejected as worded (the commas stall it); patched as "no claim and nothing else to defend you or take you in".
- XXI `seg-0007` · "open a business" → "open a trade": rejected; "open a business" is the plain current rendering of *aprire uno traffico*. Only "the taxman" is patched.
- XXVI `seg-0002` · "the excellence of Theseus" → "the virtù of Theseus": rejected. The Italian is "illustrare la eccellenzia di Teseo", not virtù, so "excellence" is right. Likewise Cyrus is "la grandezza dello animo" and stays.
- XXVI `seg-0007` · "how superior the Italians are in strength": not virtù (Italian "con le forze"); stays.
- XXVI `seg-0011` / `seg-0012` · restore the Petrarch line breaks: rejected as a patch. pipeline/modern/the-prince.json already has both the Italian and the English broken into four lines. The build collapses the newlines for this prose-form work, so the fix belongs in the pipeline, not the text. The same build fix is needed before the XVII Virgil break in patch.json will show.
- XXVI `seg-0011` · "set the English apart as an editorial translation": same as XVII `seg-0004`; a rendering question with no wording to change.
- Virtù policy · English adjective *virtuoso* ("able" in XII, XXI, XXVI `seg-0001`) and the moral plural *virtù* (XI Leo X "infinite other virtues"; XV/XVI virtue against vice): left in English by design; see the policy in the patch notes.

## Finish (2026-11-17)

Patch was already applied to `pipeline/modern/the-prince.json`. Paragraph counts checked before and after: 197, identical per section. JSON formatting kept (indent 2, non-ASCII, no trailing newline).

- **Mechanical policies.** None to run. The only policy stated is virtù (noun kept as *virtù*; adjective *virtuoso* and the moral plural stay English), and it needs judgment case by case; the patch entries carried it. Name spellings named in the patch (Forlì, Vailà, Alessandria, Gaul for Roman *Francia*) checked across the whole file: no stray Forli, Vaila or Allesandria left; every remaining "France" is the modern kingdom. 0 changes.
- **Divergence notes rewritten: 2.** Chapter I (`virtù`): `lectio` now "either by fortune or by virtù"; the note no longer says the word is glossed at first use, and says the noun is kept from I to XXVI with its meaning explained in the margin. Chapter XIX (`parlamento`): `lectio` now "the first of these is the Parlement and its authority"; the note says the gloss moved to the margin. Overview and introduction describe no reversed choice; unchanged. The Chapter VI and XI notes ("keeps the Italian … throughout") are now true and were left alone.
- **Left for the editor.**
  - Add a `virtù` entry to `content/works/work.machiavelli.the-prince/enrichment.json`; there is none, and the Chapter I note now points to the margin. The glossary has a "parliament" entry; check it matches "Parlement" as printed.
  - VI `seg-0008` area (Hiero): "He abolished the old militia and raised a new one" (*spense la milizia vecchia*) has the same "militia" problem the patch fixed in VIII; a judgment call, not patched.
  - Pipeline: the build collapses newlines in this prose-form work, so the XVII Virgil and XXVI Petrarch line breaks do not show yet.
  - Pre-existing, not caused by the patch: several notes quote the text loosely (ellipses, or wording that differs slightly: IV, XVI, XVII, XVIII, XIX `scoglio`, XX, XXII, XXVI Petrarch with line breaks). Worth one pass to make each `lectio` match the text as printed.
