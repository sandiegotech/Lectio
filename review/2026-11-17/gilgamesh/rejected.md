# The Epic of Gilgamesh · lectio-modern · verify, run 2026-11-17

No comparison edition is bundled. Fidelity judgments are made against the Standard Babylonian
epic from knowledge, and every entry that rests on that is marked "unverified against a bundled
source" in `patch.json`.

## Policies

1. **Commentary, added emotion and morals.** A sentence or clause that explains, interprets,
   moralizes, cross-references or adds a feeling the tablet does not give is cut, not reworded.
   A cut never empties a segment. A segment that is editorial from end to end is not patched; it
   is listed below under "Needs the editor". Patched: I-16 (light), II-8, II-11, II-12, II-13,
   III-10, III-11, III-12, III-14, IV-3, IV-9, IV-10, V-2, V-6, V-8, V-11, VII-3, VII-7, VIII-11,
   IX-1, IX-3, X-8, X-11, XI-2, XI-19.
2. **Lacunae.** A gap is reported once, in square brackets, outside the story's voice, in one or
   two short sentences: what is lost (with a line count where known), and at most where the text
   resumes. Never in the narrator's voice, never commenting on the edition, never narrating the
   next tablet. Patched every gap note in the work to this form: III-13, III-14, III-15, IV-11,
   VII-8, VII-10, VII-13, VIII-12, VIII-14, IX-2, IX-6, IX-7, IX-14.
3. **Compressed or skipped source, and proper nouns.** Where one phrase restores a name the
   tablet gives, it is restored (Ninurta I-6, Ishhara II-9, Sirion V-6, Anzu VII-8, Belet-ili
   XI-7). Where a fix restores a single image or item in place (rock dream I-14/15, the half sar
   I-2 and XI-19, the elephant VI-3, the dung VI-9, the winds III-9), it is patched. Anything
   that means writing new passages of the epic into the edition goes under "Needs the editor".
4. **Quotation marks.** Tablets I–IX use curly quotes (“ ” and ‘ ’); Tablets X and XI use
   straight quotes (" and '). Normalize X–XI to curly in one mechanical pass when the patch is
   applied: " to “ ” by position, and ' to ‘ ’ where it marks a quote nested inside speech.
   Apostrophes (Ishtar's, Enlil's) stay straight, as they are in Tablets I–IX. Not patched entry
   by entry; the X and XI patch entries keep straight quotes in `old` and `new` so they still
   match the current text, and the pass curls them along with the rest. The one non-mechanical
   quote fault, the stray opening mark and single-quoted dialogue in XI seg-0015, is patched.

## Rejected or changed

- I `seg-0016` — report's alternative "And Shamhat told Enkidu the dreams of Gilgamesh" not used; "So Gilgamesh told his dreams" fixes the confusion with less reach. Patched with the safer wording.
- II `seg-0005` — report's fix "Why are you running so hard?" loses the source's "hard journey"; patched instead as "What hard road are you on?"
- VI `seg-0003` — report's "elephant that throws off its harness": the object is a covering or saddle-cloth, not a harness; patched as "covering".
- VII `seg-0010` — not adding Belet-seri's question ("Who has brought this one here?") after the break; restoration, not repair. Gap bracketed only.
- IX `seg-0011` — the eight and nine double-hour lines are left as they are: the source itself varies there (he cries out; the north wind). Only three through seven are brought to the formula.
- X `seg-0003` — report's "Tell me your name" not used; it adds words the source does not give. Siduri's line reduced to "Who are you?"
- X `seg-0009` — report's fix (direct speech for Ur-shanabi's exchange) rejected as a patch: restoring the repetition is a several-sentence addition, so it goes to the editor (below). The summary as it stands is not wrong.
- XI `seg-0013` — "where the waters begin" cut along with "source", not kept as a gloss.

## Needs the editor

These hold up, but fixing them means reordering segments, writing new passages, or replacing a
whole segment. Segment ids are frozen, so none of them can be done by patch.

- **IV `seg-0010` (high) — Shamash's warning is misplaced.** In the SB it comes at the forest's edge, after all the dreams, when Gilgamesh weeps before Shamash. Here it sits between the third dream and the (now bracketed) remaining dreams in seg-0011. The patch cuts the wind sentence that belonged to Tablet V and fixes the opening ("Gilgamesh wept before Shamash"), but the position can only be fixed by swapping the texts of seg-0010 and seg-0011, which moves anchored content. Editor's call.
- **VIII `seg-0013` (high) — the whole segment is an editorial summary** of the funeral and of Gilgamesh leaving Uruk, in the narrator's voice ("From this grief he will not recover"). Every sentence is commentary or narrates events not on the tablet. Cutting it would empty the segment. Options: replace it with the broken grave-goods entries (see VIII-12 below), or with a bracketed note, or retire the segment in a re-segmentation.
- **I after `seg-0002` (medium) — the prologue's hymn to the king (SB I 29–44) is missing:** surpassing all kings, wild bull of Uruk, opened the mountain passes, dug wells, crossed the ocean to Uta-napishti, restored the shrines, "who can say like Gilgamesh, 'I am king'?" A full paragraph; would have to be appended to seg-0002 or seg-0003.
- **II `seg-0016` (medium) — the forge scene is skipped:** Gilgamesh announces the expedition and the craftsmen cast the great axes and swords before departure. Several sentences.
- **IV `seg-0011` (medium) — the fourth dream** (the Anzu-like fire-breathing creature, the man who binds and frees Gilgamesh, Enkidu's reading) is largely legible and is skipped. The patch turns the narrator's summary into a bracketed note; rendering the dream in the pattern of the first three is new text.
- **VII `seg-0003` (medium) — Gilgamesh's answer to the door speech is dropped:** the gods gave Enkidu a wide mind; the grief is left to the living; he will pray to the great gods and make Enkidu's image in gold. The patch replaces the invented sentence with his weeping; the speech itself is new text.
- **VIII `seg-0012` (medium) — the grave-goods list survives in good part** in a repeated formula (a gift for each netherworld power, shown to Shamash: "may he welcome my friend and walk at his side"). Rendering the legible entries needs the editor's source; the patch only trims the bracket.
- **X `seg-0009` (low) — the repeated exchange with Ur-shanabi** is reported secondhand, breaking the three-fold repetition (Siduri, Ur-shanabi, Uta-napishti). Giving Ur-shanabi's question and Gilgamesh's opening in direct speech is a few sentences of new text.
- **XI `seg-0003` (low) — Ea's cover story is reduced to "Ea taught me what to tell them".** The SB gives it in full (Enlil hates me; I go down to the deep to live with Ea; he will rain plenty on you, bread at dawn, wheat at dusk), and its double meaning is the point. Several sentences.

## Finish

Done on 2026-11-17, after `patch.json` was applied, in `pipeline/modern/gilgamesh.json` only.
Paragraph counts per tablet are unchanged (16, 16, 15, 15, 12, 13, 13, 14, 14, 15, 19).

- **Policy 4, quotation marks:** Tablets X and XI curled in one pass: 85 double marks (43 in X,
  42 in XI) to “ ” by position, and 18 single marks to ‘ ’ where they mark speech quoted inside
  Uta-napishti's tale (XI). The two apostrophes in XI (Ishtar's, man's) stay straight, as in
  Tablets I–IX. Checked: in every paragraph the marks alternate open and close; the paragraphs
  that end with a speech left open (X `seg-0004`, `0006`, `0014`; XI `seg-0002` to `0013`, the
  flood tale) are speeches that continue into the next paragraph. The X and XI entries
  in `patch.json` still show straight quotes; they are already applied.
- **Policies 1–3:** patched entry by entry; nothing mechanical left.
- **Divergence notes:** 9 rewritten to quote the text as it now stands and give the reason the
  patch gives: Tablet III the winds (the thirteen named winds), III the adoption (the gloss on
  the token is gone), V the killing (the door clause), V the curse, VII the door (the cut
  sentence "he tore it down in his heart" no longer quoted), VII Shamhat (the blessing now ends
  in a courtesan's glory), IX the opening lament (the restored question), X the Stone Ones (no
  longer explained in the narration), XI the reed wall (the trick shown, not explained). None
  removed. Overview and introduction unchanged; they describe no choice the edition has dropped.

Still left for the editor:

- Everything under "Needs the editor" above, untouched.
- The notes for Tablets X and XI (and the work-level notes after them) still use straight
  quotes inside the note text, while the two rewritten here use curly ones; the policy covers
  the tablets, not the notes.
- The note "Tablet V, the killing" still says the new lines let Humbaba "reproach the heroes for
  laying waste a forest he was set to guard". The text has him invoke Enlil's law of the forest
  and threaten Enkidu, not reproach them for the felling. No patch touched this; the editor
  should decide which to change.
