# The Divine Comedy · Inferno (sections 1–34) · verify, 2026-11-17

Lectio `lectio-modern` checked against Longfellow 1867 and Dante's Italian. The Italian is not
bundled; readings are from the verifier's own knowledge of the text (Petrocchi line numbers).
Confirmed fixes are in `patch-inferno.json`.

## Policies

1. **Latin stays Latin, with no in-line English gloss.** When Dante quotes Latin as Latin (hymn,
   liturgy, scripture), the Lectio prints the Latin and nothing in the verse translates it.
   Applied: XXXIV `seg-0001`, where "the banners of the king of Hell advance" is cut and the
   tercet goes back to three lines ("Vexilla regis prodeunt inferni / toward us. …"). Scope note:
   a Latin word built into Dante's Italian sentence is translated with the sentence, so I 65
   "Miserere di me" stays "Have pity on me". Non-language (VII 1 "Pape Satàn", XXXI 67 "Raphèl")
   stays as Dante wrote it, untranslated, as it already is.
2. **The canto's closing line stands alone.** Dante's single last line is the canto's last
   segment, by itself: no tercet line spills into it, and it is never folded into the last
   tercet. 32 of 34 Inferno cantos already do this. Applied: XIX (realigned, below), so
   "And from there another valley opened to me." stands alone. XI and XXXIII break the rule
   and cannot be fixed by text patch (see "Needs the editor").
3. **Tercet alignment.** One tercet per segment, on Dante's lines. Where the English has slipped
   a line, the lines are moved between neighbouring segments, each segment its own patch entry;
   no segment added or removed. Applied: XIX `seg-0041`–`0045` (slip found in this verify:
   `seg-0041` stretched XIX 121–122 to three lines, so the canto ran 134 lines and the closing line
   shared a segment) and XXXIV `seg-0041`–`0044` (Inf. XXXIV 121–132; Virgil's speech now ends with
   `seg-0042` and the narration opens `seg-0043`). A proper-noun scan of all 34 cantos against
   Longfellow (which is line-for-line) found no other slip; the remaining one-line name shifts
   (XXVIII `seg-0003`, XXIX `seg-0017`, XXX `seg-0007`, XXXI `seg-0021`) are enjambment inside the
   tercet boundary and are left.
4. **Interjections.** Dante's "Ahi" / "Ahimè" is "Ah", as the edition already prints it seven times
   in the Inferno; never "God,". "Omè" in the falconer's cry is "Oh". Patched: XVI `seg-0004`,
   `seg-0040`; XVIII `seg-0013`; XVII `seg-0043`. "O vengeance of God" (XIV) and "Justice of God!"
   (VII) are Dante's own apostrophes and stay.
5. **Leftover archaism.** "Ecco" is "Look", not "Behold"; "yonder" is "over there"; "the while" is
   "meanwhile". Patched: XVII `seg-0001` (twice), XXX `seg-0014`, XX `seg-0044`. A full scan of the
   Inferno found no other thee/thou/ye/hath/doth/whence/ere/lo; "all the while" (XXX `seg-0047`)
   is current English and stays.
6. **Single words that mislead a modern reader** are replaced with the thing Dante means, not
   glossed: XIX "tomb" for the bolgia (→ "ditch"; the heretics' tombs in IX–XI and Lucifer's
   "tomb" in XXXIV `seg-0043`, Dante's own figure for Hell, stay), XXIII "pane of leaded glass"
   (→ "mirror"), XXIV "lying on down" (→ "sitting on feather cushions"), XXV "drew his back"
   (→ "drew his muzzle back"), XXVII "specialist" (→ "physician").
7. **Quotation nesting (mechanical, not patched entry by entry).** Speech within speech alternates
   double / single / double. In Canto II, Virgil (double) quotes Beatrice (single), who quotes
   Mary (`seg-0033`) and Lucia (`seg-0035`–`0036`): those third-level quotations take double
   quotes. Apply as a normalization when the edition is next built.

## Needs the editor

- **Inferno XI** — Dante's closing line (XI 115, "e 'l balzo via là oltra si dismonta") is the
  fourth line of `seg-0038`; the canto has 38 segments where Dante's form (and Longfellow's 39)
  needs 39. Giving the closing line its own segment means adding a segment, which a patch cannot do.
- **Inferno XXXIII** — same: XXXIII 157 ("e in corpo par vivo ancor di sopra") is the fourth line
  of `seg-0052`; 52 segments against Longfellow's 53.

## Rejected

- I `seg-0029` · "the noble style" → "beautiful style": "lo bello stilo" is commonly and fairly
  rendered "noble"; it misleads no one, and "beautiful style" is weaker in English.
- XIII `seg-0022` · "sluttish eyes" → "whorish eyes": "occhi putti" is whorish; "sluttish" is the
  same coarse sense, and the proposed fix ("The whore who never takes her whorish eyes") only adds
  a clumsy echo.
- XX `seg-0001` · "the drowned" → "those sunk below": "sommersi" is literally the submerged or
  drowned, and "the drowned" is the established English (cf. Levi, *I sommersi e i salvati*);
  the context makes clear it means the damned.
- XXXIV `seg-0044` · long final line: not patched separately; resolved by the realignment of
  `seg-0041`–`0044`.
- II `seg-0033` · quotation marks: confirmed, but handled as policy 7, not as a patch entry.

## Finish

Done on 2026-11-17 in `pipeline/modern/divine-comedy.json` for all hundred cantos, after the three patches (`patch-inferno.json`, `patch-purgatorio.json`, `patch-paradiso.json`; 307 text entries) were applied. Before starting I checked that every entry's `new` text is in its canto. In Purgatorio III the four entries sit two paragraphs earlier than their seg ids say, because paragraphs 1 and 3 there each hold two segments separated by a blank line. That was already so at HEAD, and the same is true of Paradiso XXII paragraph 51. The paragraph count of every canto is the same before and after (4,804 in all). No line break was added or removed in any paragraph. The JSON formatting is unchanged: indent 2, non-ASCII kept, no trailing newline.

The three verifiers wrote their policies separately. They were applied as one rule across all three canticles:

- **Straight quotes (Paradiso Q).** 22 curly quotes became straight: 14 in Paradiso V, 6 in Paradiso XXXII and 2 in Paradiso XXXIII. In V seg-0023 the nested ‘I did wrong,’ became 'I did wrong,'. No curly quote is left in the cantos.
- **Quotation nesting (Inferno 7).** In Inferno II, 6 marks changed from single to double: Mary's words at seg-0033, and Lucia's at seg-0035 to seg-0036. They are third-level quotations: Virgil quotes Beatrice, who quotes them. This fits Q, which only says ' is used one level down.
- **No stray leading spaces (Paradiso S).** Leading spaces were removed from 83 continuation lines, all in Paradiso VII. No other canto had any.
- **Latin stays Latin, with no gloss in the line (Inferno 1, Purgatorio L, Paradiso L).** This needed no further change. A scan of all 100 cantos found every Latin quotation already in Latin with no English beside it. The cases are Inf. XXXIV and Purg. II, V, VII, VIII, IX, X, XII, XV, XVI, XVII, XIX, XX, XXII, XXIII, XXV, XXVII, XXVIII, XXX, XXXI and XXXIII, plus Par. III, VII, XII, XV, XVI, XVIII, XXIII, XXV and XXXII. The one exception is the bracketed English of Arnaut's Occitan in Purg. XXVI seg-0050 to seg-0052, already under the editor's items.
- **The canto's closing line stands alone (Inferno 2, Purgatorio C, Paradiso C).** This also needed no further change. In 92 cantos the last segment is that one line. Seven cantos have the closing line as the fourth line of the last segment, on a line of its own: Inf. XI and XXXIII, Purg. II, XIII, XXIV and XXXIII, and Par. XVII. Text alone cannot change this, because a new segment would be needed. In Purg. XXII the closing line is still run into seg-0052, as described under that verifier's items.
- **Divergence notes rewritten (33).** 31 notes quoted wording that a patch changed, and the patch had also reversed the choice the note argued for. Each was rewritten so it quotes the text as it now stands and gives the reason from the patch's `why`. These are Inf. VI.49, XVII.1, XVIII.130, XX.13, XXIV.46, XXVI.118 and XXXIV.1; Purg. I.31, III.37, X.95, XI.121, XVII.91, XVIII.67, XIX.73, XIX (Adrian), XX.127, XXII.40, XXVI.117, XXVII.10 and XXXIII.142; and Par. I.70, IV.28, VIII.139, XI.52, XIV.104, XVIII.91, XVIII.127, XXIV.34, XXXII.40, XXXIII.85 and XXXIII.142. Six of these had argued for an English gloss of Latin and now argue for the Latin: Inf. XXXIV.1, Purg. XIX.73, Purg. XIX (Adrian), Purg. XX, and Par. XVIII.91 and XXXII.40. For Purg. XXII.40 the `phrase`, `lectio` and `note` were all rewritten, because the patch reads "sacra fame" as Statius does ("holy hunger … rule"), not as Virgil does ("cursed"). Two more notes had a sentence that was no longer true and were corrected. Purg. XII.97 named the beatitude in English, which the text now gives in Latin. Par. XXV.73 said that the verse's later echo at XXV.98 was in English, but it is now Latin. No note was removed. All 309 notes are still objects with `locus`, `phrase`, `older`, `lectio` and `note`. The overview and introduction describe no choice that the edition has dropped, so they were not touched.

Where the three verifiers really conflicted:

1. **Whether a closing line inside the last segment is acceptable.** Inferno policy 2 treats it as a breach and sends XI and XXXIII to the editor. Purgatorio and Paradiso C accept it as a fallback when the frozen ids leave no segment for the line. Even so, Paradiso still sends XVII to the editor. Seven cantos are in this position (listed above), so the editor should make one ruling for all of them.
2. **Whole-canto realignment when it renumbers anchors.** The Purgatorio verifier would not realign Purg. XXII (41 segments, one line off) because highlights and notes from seg-0019 onward would point at different tercets. The Paradiso verifier made the same kind of one-line shift across Par. XXX seg-0012 to seg-0050 (39 segments), and that has now been applied. Anything anchored to Par. XXX segments in user data or sidecars should be checked. The editor should also decide whether Purg. XXII gets the same treatment.
3. **Latin quoted inside an Italian sentence.** Inferno's scope note says a Latin word built into Dante's Italian sentence is translated with it ("Miserere di me", I 65). Purgatorio keeps "Qui lugent" (XIX 50, seg-0017) and "Beati / pacifici" (XVII 68, seg-0023) in Latin and translates only the Italian that follows. Under that practice, three passages now in English would also keep their Latin words: Par. XX 94 "Regnum celorum violenza pate" (seg-0032, "The Kingdom of Heaven suffers violence"), Purg. XXIX 85 "Benedicta tue" (seg-0029, "Blessed are you") and Purg. XXIV 151 "Beati cui alluma" (seg-0051, "Blessed are they whom grace"). These need a judgment, so they were left as they are. The note on Par. XX.94 still argues for the English.

Still left for the editor:
- Every item under "Needs the editor" in the three `rejected-*.md` files. These are Inf. XI and XXXIII, Purg. XXII and XXVI, and Par. XVII, together with conflicts 1 to 3 above. The Occitan note (Purg. XXVI.140) still describes the bracketed English, because that text has not changed.
- Inferno policies 4 to 6 (interjections, archaism and misleading single words) were patched in the Inferno only. The cantos after the Inferno still contain "behold" (6 in the Paradiso, 1 in the Purgatorio), one "the while" and one "lo". They were not changed, because no Purgatorio or Paradiso policy names them.
- Fourteen notes paraphrase or summarize instead of quoting the text exactly. Examples are Inf. XXI (the Malebranche), Purg. IX.94, XII.16 and XII.25, and Par. XX.106. That was already so at HEAD and has nothing to do with the patches, so they were left.
- The pipeline build has not been run.
