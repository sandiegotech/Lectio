# The Iliad · verify pass · 2026-11-17

Lectio edition `lectio-modern`, checked against Butler 1898 (the close prose base) and Pope 1715 (a second witness only). The original is not bundled, so the Greek readings cited in `patch.json` come from the verifier's own knowledge of the text.

## Policies

- **Patronymics.** When the Greek patronymic names a remote ancestor, it is rendered as descent, not fatherhood. For Achilles, Αἰακίδης becomes "grandson of Aeacus", the edition's existing form in II and XVII; this is patched in IX seg-0014, XI seg-0052, XVI seg-0007/0008/0046/0047, XVII seg-0006 and XVIII seg-0018. "Peleus, son of Aeacus" is literal and stays (XVI seg-0001, XVIII seg-0030, XXI seg-0009). For Priam and Ilus, Δαρδανίδης becomes "of the line of Dardanus", matching III seg-0027; this is patched in XI seg-0011/0028, XIII seg-0027, XXII seg-0021 and XXIV seg-0012/0024/0042. In XXIV seg-0042 the doubled "Priam of the line of Dardanus" is kept, because it is Homer's deliberate mirror (24.629-31).
- **"Car" for chariot.** It becomes "chariot" ("cars" becomes "chariots") everywhere: 53 entries across III, V, VIII, XI, XIV-XVII, XIX, XX and XXIII. Each one is patched individually, because a blind replace would also hit words like "care" and "carry".
- **Leftover archaisms.** "chine" becomes "back" (VII) or "backbone" (IX). "a whit" becomes "in the least" (VIII). "without let" becomes "without pause" (XII) or "without rest or pause" (XIV). "targets" is recast as shields of hide (V). "corn" becomes "grain" (V). "Rings of his shirt" becomes "plaited tunic" (V), to avoid medieval mail. All are patched.
- **Modern slang.** "blowhard" becomes "slanderer". "Damn it" becomes "Ah, no", and "To hell with you" becomes "Go to ruin". Sports-page "the win" becomes "victory" or "to win" (XVII, XXI, XXIII). "We're for it" and "let her have it" are recast. "Bite the dust" becomes "bite the earth" in XI, XIX, XXII and XXIV; that is Homer's own image (ὀδὰξ ἕλον οὖδας), and II seg-0027 already says "bitten the earth". All are patched. Plain current words such as "nobody", "tough", "peddle" and "hug" are not slang and stay (see Rejected).
- **Biblical or Christian idiom in a pagan poem.** All of it is replaced with the Greek's own sense, and all of it is patched: "take the name of the gods in vain" (XIX), "the spirit may be willing" (XIX), "a time to mourn" (XXIII), "sin against" (XXIV ×2), "his sins" (V), "God keep me" (XVI), "hound of hell" (VIII), "To hell" (XXIII). Ordinary uses of "in vain" and "holy" stay.
- **δαιμόνιε / δαιμονίη.** "You strange man/woman" stays where the address is a rebuke or bewilderment: I seg-0044, III seg-0034, IV seg-0003, VI seg-0023/0030/0036 and IX seg-0004. It changes in two kinds of scene. In tenderness it becomes "My dearest" (Hector to Andromache, VI seg-0033). In a battle taunt it becomes "Madman" (XIII seg-0030/0047).
- **Quotation style (mechanical, not patched).** Books I, VIII–X and XIV–XX use curly quotes; II–VII, XI–XIII and XXI–XXIV use straight ones. One style for the whole work: typographic “ ” for speech, ‘ ’ for a quotation inside speech, and ’ for apostrophes. Normalize with one script pass over `pipeline/modern/iliad.json` after the patch is applied. The script must treat a word-final ' after s (as in "Achilles'") as an apostrophe. This also fixes the mismatched ‘…' in IX seg-0018 and seg-0037.
- **Spelling (mechanical, not patched).** Use American spelling and the edition's majority forms: "gray", not "grey" (XI seg-0018); "debris", not "débris" (XXI seg-0013); "Cronus", not "Cronos" (XX seg-0023); and "Achilles'", not "Achilles's" (II seg-0019/0052, XVI seg-0040). Other names keep the edition's 's (Odysseus's, Eumelus's). Do this in the same normalization pass.

## Needs the editor

A segment can never be removed or emptied, because ids are frozen. These issues are confirmed, but a text patch can't fix them properly.

- **V seg-0058** "And so the gods withdrew from the field." · invented, high. It has no source: Book V ends at 5.909 with Hera and Athena going back to Zeus's house (Butler seg-0068), and the line repeats Book VI's opening. Recommended: retire the segment with a tombstone mark in the pipeline (the id stays in the ledger, and the reader, print and audio skip it). Failing that, move the last sentence of seg-0057 ("And Argive Hera and Athena of Alalcomenae … drove back to the house of great Zeus.") into seg-0058 so that it replaces the invented line. That mirrors Butler's own paragraphing, but it shifts the spine slightly.
- **X seg-0050** "And so the night … had cost them nothing." · invented, high. The book ends at 10.579 with the libation to Athena (seg-0049). The sentence is editorial comment, and its claims ("the only Greek victory in many days") are not Homer's. Recommended: a tombstone. Failing that, move seg-0049's final sentence ("Washed and rubbed with oil, they sat down to eat … poured the first of it out to Athena.") into seg-0050.
- **XXIII seg-0051** "[Trans. note: …]" · editorial note printed as text, high. Recommended: a tombstone, with the note's content moved to `enrichment.json` as a passage note on XXIII seg-0050. Failing that, move seg-0050's last sentence ("Achilles gave the bronze spear to Meriones … the herald Talthybius.") into seg-0051.
- **I seg-0033**, Achilles' retelling to Thetis (1.365-92). The Briareus cut is fixed in `patch.json` (high). What remains is that 28 lines of speech are collapsed into a narrated list ("the priest, the plague, the quarrel, Briseis carried off"), and the opening "You know; why tell you what you know?" is gone. Restoring that speech means writing a long passage, and it should be drafted and read by the editor rather than queued as a patch. Recommended: restore it as direct speech, compressed if need be, after "With a heavy groan swift-footed Achilles answered".

## Rejected

- I seg-0026 · Theseus son of Aegeus missing from Nestor's list: 1.265 is bracketed by most editors, so omitting it is defensible. The rest of that issue is patched.
- V seg-0058 · the reviewer's "delete or empty the segment" fix is impossible with frozen ids; see Needs the editor.
- VI seg-0015 · "the blood and the line I claim to be from": ending on a preposition is natural English and the line is faithful (6.211). The proposed fix adds "proud".
- IX seg-0018, seg-0037 · mismatched inner quotes: covered by the quotation-style policy and not patched individually.
- XI seg-0018 "grey", XVI seg-0040 "Achilles's", XX seg-0023 "Cronos", XXI seg-0013 "débris": covered by the spelling policy.
- XIV seg-0031 · "tough soldier": plain, current English for μενέχαρμος. It is not slang and not wrong.
- XV seg-0014 · "some nobody", "bullying": plain current words that fit κακός and Poseidon's contempt. The register objection is taste.
- XVIII seg-0023 · "peddle that kind of talk": the contemptuous sense suits Hector's rebuke and is current. It is not cheapening.
- XXIII seg-0022 · "Hug it close as you wheel": the ordinary idiom for driving close to a turn (23.334 ἐγχρίμψας). The "car" in that segment is patched under the chariot policy.

## Finish

Done on 2026-11-17 in `pipeline/modern/iliad.json`, after the patch (163 entries) was applied. The paragraph count is the same in every book before and after (1,046 in all). The JSON formatting is unchanged.

- **Quotation style.** One script pass over the book titles, paragraphs, overview, introduction and divergence notes. It made 918 double quotes into “ ” and 28 single opening quotes into ‘. It made 1,404 internal apostrophes and 152 closing single quotes or word-final apostrophes (Achilles’, gods’) into ’. No straight quote is left in any text field. Paragraphs whose quotes don't balance are the same 28 as before, all speeches that run across paragraphs. The mismatched ‘…' in IX seg-0018 and seg-0037 is fixed.
- **Spelling.** "Achilles's" became "Achilles'" (×3: II seg-0019 and seg-0052, XVI seg-0040). "grey" became "gray" (XI seg-0018). "Cronos" became "Cronus" (XX seg-0023). "débris" became "debris" (XXI seg-0013). In the edition's own note prose, "favour" became "favor" (note on μῆνις) and "metre" became "meter" (note on Achaeans/Argives/Danaans). Spellings inside quotations from Butler and Pope ("valour", "vapour") were left alone.
- **Divergence notes rewritten (2).** The note on Book 7 (Nestor, and the honor-cut for Ajax) now quotes "the long cuts of the back" and gives the archaism reason. Its locus is now 7.321. The note on Book 16, line 850 now quotes "you come only third in the killing of me" and gives the reason from the patch: Apollo stripped the armor and Euphorbus took none. No other note, and nothing in the overview or introduction, quotes wording the patch changed or describes a choice the edition no longer makes.

Still left for the editor:
- The four items under "Needs the editor" above: V seg-0058, X seg-0050, XXIII seg-0051 and the I seg-0033 speech.
- "draught" in XI seg-0046 (×2, Hecamede's drink) was left as it is. It is also standard American spelling for a drink. Change it to "draft" only if the edition wants that.
- The `method` metadata field still has a straight apostrophe ("SDIT's"). It is provenance, not edition text, so it was not touched.
- The pipeline build has not been run.
