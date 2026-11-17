# The Odyssey · lectio-modern · verify 2026-11-17

Checked against butler-1900 and the Greek. The Greek is not bundled, so it was judged from my own knowledge of the text, and each `why` in patch.json says so by citing book.line. patch.json has 283 entries (2 high, 31 medium, 250 low). Every one was checked in order against the current text: `old` occurs exactly once in its segment and once in its section, and `tools/review/apply.py odyssey --dry` applies all 283 with none skipped.

## Policies

The house list. Each policy below was swept across all 24 books, and every departure found is in patch.json, not only the ones the reviewers reported.

**Names.** The introduction's rule is that gods and heroes keep their Greek names: Odysseus, not Ulysses; Athena, not Minerva. That rule is about Greek against Roman names. It does not choose a transliteration. Within the rule, the house spelling is the familiar Latinized English form of each Greek name. The edition already uses that form for nearly every name (Telemachus, Menelaus, Alcinous, Calypso, Circe, Achilles; Antinous 52 times against Antinoos 7), and the Lectio Iliad uses it too (Cronus, 89 times). Patched to that form:

- Antinoos → Antinous
- Eurymachos → Eurymachus
- Ikarios → Icarius
- Eurykleia and Euryclea → Eurycleia
- Aigisthos → Aegisthus (21 times; the one Greek form the edition used in the majority, changed so that a single rule holds)
- Kronos → Cronus (matches the Iliad)
- Aigyptios → Aegyptius
- Phronios → Phronius
- Polybos → Polybus
- Leokritos → Leocritus
- Polyphemos → Polyphemus
- Phorkys → Phorcys
- Phemios → Phemius
- Zakynthos → Zacynthus
- Doulichion → Dulichium
- Epeians → Epeans
- Mykene → Mycenae
- Eurynomos → Eurynomus
- Mermeros → Mermerus
- Anchialos → Anchialus
- Antiphos → Antiphus
- Geraistos → Geraestus
- Phaistos → Phaestus
- Peirithous → Pirithous
- Acroneos → Acroneus
- Alkmene → Alcmene

Place names already in standard English (Pylos, Lesbos, Chios, Argos, Minos, Helios) are unchanged.

**The army.** Ἀχαιοί, Ἀργεῖοι and Δαναοί, and their adjectives, are rendered "Greeks" and "Greek", the edition's own word (107 uses). One "Argives" (I) and five "Achaean" (XXI) were patched. There are two exceptions:
- XIX seg-0015 keeps "Achaeans" in the list of Crete's peoples, beside Cretans and Dorians, where "Greeks" would be wrong.
- IV seg-0070 has "the suitors", because there Ἀχαιοί means the suitors' crew.

**Fixed epithets and formulas.**
- αἰγίοχος Ζεύς → "Zeus who holds the storm-shield", which is also the Lectio Iliad's form. The variants "storm-cloud" and "carries" were patched. The object itself stays "aegis" (XXII seg-0027), as in the Iliad. This rejects the XXII and XXIV suggestion to use "aegis" for the epithet.
- γλαυκῶπις → "grey-eyed". This is the introduction's stated rendering and has 40 uses; "bright-eyed" was patched 3 times in XXIV.
- ἔπεα πτερόεντα → "winged words". "His words flying", "his words came winged" and "their winged answer" were patched (11 entries). ἄπτερος μῦθος (XXI) means she made no reply, and is rendered that way.
- ἑκατόμβη → "hecatomb". The one "hundred-beasts" was patched.
- ἐνοσίχθων / ἐννοσίγαιος → "earth-shaker", lower case. "Earthshaker" and "Earth-Shaker" were patched.
- νεφεληγερέτα → "Zeus who gathers the clouds". "The cloud-gatherer" was patched.
- διογενὲς Λαερτιάδη, πολυμήχαν' Ὀδυσσεῦ → "Royal son of Laertes, Odysseus of the many schemes", as in V. Variants in X, XI, XIII, XIV, XVI, XXII and XXIV were patched (12 entries).
- "The man of many turns" stays as the hero's narrative epithet. That is the introduction's choice, and it is not changed here.
- τερψίμβροτος (the Sun) → "who gives men joy".
- ἀμφίαλος → "sea-girt". This is kept as a fixed epithet: it is still current in poetic English. The archaic verb "girt" (XXI) was patched.

**Lines Homer repeats word for word are rendered word for word.**
- "For the iron itself draws a man on" (16.294 = 19.13): XIX was patched.
- The shroud speech (2.96–102 = 19.139–47 = 24.131–7): XIX and XXIV now repeat Book II exactly.
- "A quick death and a bitter wedding" (1.266 = 4.346 = 17.137).
- Menelaus' lion speech (4.333–46 = 17.124–37): XVII now repeats IV as patched.
- "When the child of morning, rosy-fingered Dawn, appeared": 9 variants patched.
- "Hellas and the heart of Argos" (1.344, 4.726, 4.816, 15.80).

**Homeric idioms carried over literally.**
- κεφαλή meaning a person is rendered as the person: I seg-0024, XI seg-0045. "Pay with your own head" and "gambling with their heads" are kept, because English carries those idioms.
- παρὰ μηροῦ → "from beside my/your thigh": 5 patched in X and XI.

**Modern idioms with the wrong sense and leftover archaisms.** All of these were patched:
- "got around", "make your play", "do their business", "good luck to you", "wearing thin", "working away at"
- "last supper", "God forbid" → "Heaven forbid"
- "mouthing off" (Eurymachus). Melantho's "running your mouth" in XVIII is kept, because it suits her.
- "public house", "kilt", "cadging", "trumpery", "corn" (meaning grain)
- "wallet" → "beggar's bag" at first mention, then "bag"
- "steading" → "the farm", and "fold" for the animal pen in VI

**Mechanical normalizations: policy only, not patched entry by entry.** Do these in one pass at apply time:
- Book XIII alone uses curly quotes (“ ” ’). Normalize to the straight quotes used everywhere else.
- "grey" (13 uses) and "gray" (8 uses) are mixed. Use "grey" throughout, to match "grey-eyed".

## Needs the editor

A segment cannot be removed or emptied, so these two need a decision about the pipeline or the id ledger, not a text patch.

- **V seg-0033** (form, medium; reported medium). The whole segment is a bracketed "[Trans. note: …]" on Ino's krēdemnon, printed as Homer's text, as the book's last segment. Its content is accurate. Recommendation: stop this segment from rendering as reading text by retiring its id in the ledger (a tombstone, not a renumbering). The other option is to give it a non-reading kind (`note`) that the reader, print and audio skip. Move the note to `enrichment.json` as a passage note on V seg-0022, where Ino gives Odysseus the veil.
- **XIV seg-0033** (form, high). The whole segment is a bracketed "[Trans. note: …]" inside the reading text. Its claim is false: Homer apostrophizes Eumaeus ("and you answered him, Eumaeus, swineherd") again in XV, XVI, XVII and XXII (15 times in all), and the Iliad does the same with Patroclus and Menelaus. Recommendation: handle it like V seg-0033 (retire it or make it a non-reading kind). If the point is wanted, move it to `enrichment.json` on XIV seg-0031, worded as "Homer often turns to address Eumaeus directly…", without "only". The XXII seg-0018 patch restores one of the apostrophes the edition had smoothed away.
- **XXIII seg-0019** (high) is patched in-segment, not referred here. The seven Helen lines (23.218–24) fit inside Penelope's speech in the same segment. These lines were doubted by ancient critics (Aristarchus). If the editor wants the provenance to say they were restored, add a line to the edition's divergences. No segment change is needed.
- **III seg-0035** (high) is patched in-segment as well. The missing 3.497 is restored at the end of the segment, so Book IV still opens with the arrival at Lacedaemon.
- Optional, low: XVII seg-0011 continues past the harmonized lion speech with Menelaus' report of Odysseus on Calypso's island (17.142–6 = 4.556–60). It is still worded differently from IV seg-0044. Patching the formula and the speech seemed enough; a word-for-word match there is a matter of taste.

## Rejected

- I seg-0022 · low · "godlike as he was": not causal in English; it reads as description, and it renders ἰσόθεος φώς adequately.
- II seg-0027 · low · "in his strength": a fair rendering of the formula ἱερὴ ἲς Τηλεμάχοιο. Adding "young" adds a word the Greek does not have.
- IV seg-0014 · low · "keep the wolves from his door": the stock sense, staving off ruin to one's living, fits exactly, because the suitors are eating the estate. The phrase is apt, not a slip.
- IV whole section · medium · names: not rejected, but closed by the Names policy instead of a section fix.
- XXII seg-0027 · low · "aegis in both places": partly rejected. The epithet stays "storm-shield" and the object stays "aegis", matching the Lectio Iliad. Only XIII's form is unchanged.
- XXI seg-0026 · low · the Eurycleia spelling: no fix needed in XXI. It is closed by the Names policy (XVII and XX patched).
- XIII seg-0006, XIV seg-0007, XXIV seg-0034 · low: the suggested wordings ("his words had wings", "he called back") were set aside for the single house formula "with winged words". The issue itself was confirmed and patched.
- XXIV seg-0009 · low: the suggested "cruel death lays him low" was set aside. All three shroud speeches now use Book II's wording instead. The issue was confirmed and patched.

## Finish

Done 2026-11-17 on `pipeline/modern/odyssey.json`, after `apply.py` (all 283 entries in the text; XI seg-0040's vocative entry was absorbed by the "winged words" entry on the same words). Paragraph counts are identical in all 24 books before and after, and the file's formatting is unchanged (indent 2, non-ASCII kept, no trailing newline). The pipeline build was not run.

**Mechanical policies.** At the assignment's direction, the Odyssey takes the Iliad's conventions, since the two poems are one voice. This supersedes the two "Mechanical normalizations" lines above (straight quotes; "grey").
- Quotation style: typographic “ ” for speech, ‘ ’ for a quotation inside speech, ’ for apostrophes, over the whole file (books, overview, introduction, divergences). 2,015 straight double quotes and 1,221 straight single quotes converted, in 987 strings; Book XIII's curly quotes now match the rest. No straight quote is left in the text. Every paragraph checks out with no unopened close or double open. The only unmatched opens are the usual ones at the start of a paragraph in a speech that runs on (Books IX, XI, XII and others).
- Spelling: American "gray" throughout, as in the Iliad ("gray-eyed", 11 uses there). 61 changes: 44 "grey-eyed", 4 "Grey-eyed", 13 "grey", plus the introduction's "grey-eyed Athena". So γλαυκῶπις now prints "gray-eyed", not the "grey-eyed" the Formulas policy above names. The Iliad's other spelling items ("Achilles's", "débris", "Cronos") have no instance here. British spellings left in the divergences ("humour", "marvellous", "labour", "towards") are inside quotations from Butler, so they stay.

**Divergence notes rewritten (4 of 72).**
- Book 12 (Planktai): "the Earthshaker" becomes "the earth-shaker", in the lectio and the note, with the house form stated.
- Book 18 (Irus): the patch cut the explanatory "a man's twist on Iris" from Homer's sentence. The note now quotes the text as it stands and gives the reason: Homer states only why the name fits (18.6–7), and the pun belongs in the notes.
- Book 21, line 411 (bow and lyre): quotes the simile as it now begins its own sentence, and says why.
- Book 21, line 413: Kronos becomes Cronus in phrase, lectio and note, with the house name rule.
No note was removed. The overview needed nothing; the introduction changed only "grey-eyed" (above).

**Still left for the editor.**
- V seg-0033 and XIV seg-0033, the bracketed "[Trans. note: …]" segments (see Needs the editor). They are still reading text.
- XXIII seg-0019, the restored Helen lines (23.218–24): there is still no divergence note on them, if the editor wants the provenance to record it.
- Optional: the XVII seg-0011 word-for-word match with IV seg-0044.
- The Iliad's own finish pass, so that both files actually carry these conventions; `iliad.json` still mixes quote styles.
- `python3 -m pipeline.build`, then read the diff and commit.
