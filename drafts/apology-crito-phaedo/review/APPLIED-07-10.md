# Applied fixes · books 07–10 (Phaedo 78b–118a)

Every finding in 07.md–10.md was checked a second time against Burnet's Greek, with Jowett as the control. Burnet's bracketed deletions were read from the `<del>` elements in `pipeline/.cache/perseus-tlg0059.tlg004.perseus-grc2.xml`, because the flattened `burnet-phaedo-grc.txt` prints them without brackets. Only text was changed. Paragraph counts are unchanged (87, 105, 144, 48), the JSON is valid, and the file formatting is untouched (each fix was replaced in place).

## Medium
| Book | Para | Stephanus | Old → New | Why |
|---|---|---|---|---|
| 08 | p-014 | 88a | "he no longer conceded that it does not suffer in its many births, and at the end perish" → "he would not go on to concede that it does not suffer in its many births, and does not at the end perish" | The second verb had lost its construction, and μὴ οὐ after a negated verb of granting has to be carried by both verbs. |
| 10 | p-026 | 115a | "so awaits the journey to Hades, ready to make it whenever fate calls." → "so awaits the journey to Hades." | Burnet deletes [ὡς πορευσόμενος ὅταν ἡ εἱμαρμένη καλῇ]. It anticipates "fate is calling" in the next sentence. |
| 10 | p-001 | 107c | "now the danger would indeed" → "now the risk would indeed" | ὁ κίνδυνος. Brings the text into line with the 114d divergence note ("risk" both times). |

## Low
| Book | Para | Stephanus | Old → New | Why |
|---|---|---|---|---|
| 07 | p-010 | 78e | "or the many equal things or beautiful things, or all" → "or the many equal things, or all" | Burnet deletes [ἢ καλῶν]. |
| 07 | p-008 | 78d | "itself by itself, stay in the same condition" → "itself by itself, always stay in the same condition" | ἀεί had been dropped. |
| 07 | p-054 | 81c | "will get away itself by itself" → "will part from it itself by itself" | ἀπαλλάξεσθαι is "part from" (STYLE §11). |
| 07 | p-055 | 81c | "Not in the least" → "Not in any way whatever" | οὐδ' ὁπωστιοῦν, rendered as in book 08. |
| 07 | p-068 | 82b | "without philosophy and understanding" → "without philosophy and intelligence" | νοῦς of a person (STYLE §11). |
| 07 | p-077 | 83b | "pleasures and desires and pains and fears as far" → "pleasures and desires and pains as far"; "intense pleasure or fear or pain or desire" → "intense pleasure or fear or desire" | Burnet deletes [καὶ φόβων] and [ἢ λυπηθῇ]. |
| 07 | p-077 | 83c | "and he does not reckon it in." → "and he does not take it into his reckoning." | Not an idiom; keeps the echo of λογιζομένη / λογίζεται. |
| 07 | p-079 | 83c | "the thing which most causes it to feel this" → "the thing it feels this about most strongly" | περὶ ὃ … πάσχῃ: what the feeling is about, not its cause. |
| 07 | p-087 | 84b | "After a nurture like that, and having pursued these things, Simmias" → "After a nurture like that, Simmias" | Burnet deletes [ταῦτα δ' ἐπιτηδεύσασα]. |
| 07 | p-087 | 84b | "blown away by the winds and gone flying off" → "blown apart by the winds, flying off and gone" | διαφυσηθεῖσα, rendered as at 80d ("blown apart"). Reads aloud better. |
| 08 | p-009 | 86e | "troubled you in your turn and makes you disbelieve?" → "troubled you in your turn?" | Burnet deletes [ἀπιστίαν παρέχει]. |
| 08 | p-004 | 85b | "the eleven men of Athens" → "the Eleven of Athens" | The institution keeps its capitalized name (STYLE §5–6). |
| 09 | p-027 | 100d–e | "all beautiful things become beautiful" → "all beautiful things are beautiful"; "beautiful things become beautiful" → "beautiful things are beautiful" | Burnet deletes [γίγνεται] both times. |
| 09 | p-002 | 95a | "you made astonishingly, beyond" → "you put astonishingly well, beyond" | Not English as it stood. θαυμαστῶς … εἶπες. |
| 09 | p-068 | 103e | "this name that we are now speaking" → "this name that we are now using" | "Speak a name" is not English. |
| 10 | p-001 | 107c | "if death were a release from everything … to be released at once from the body and from their own wickedness" → "if death were a riddance of everything … to be rid at once of the body and of their own wickedness" | ἀπαλλαγή / ἀπηλλάχθαι; "release" is reserved for λύσις (STYLE §11). |
| 10 | p-026 | 114e | "as foreign to him, and judging" → "as foreign to him, judging" | The "and" tied the participle to nothing. |
| 10 | p-019 | 112c | "it flows through the earth into the streams over there" → "it flows into the streams in that part of the earth" | Burnet deletes [διὰ]. |
| 10 | p-031 | 115e | "not only a fault in itself" → "not only a false note in itself" | πλημμελές, the same word as πλημμελοῖεν at 117d ("strike such a false note"). |
| 10 | p-032 | 116b | "and after that not much was said." → "and after that he did not say much." | Socrates is the subject of διελέχθη. |
| 10 | p-035 | 116e | "very late, long after the order" → "very late, after the order" | "Long" is not in the Greek. |
| 10 | p-042 | 117d | "broke out in a roar of weeping and grief," → "broke out roaring, weeping and distressed," | Three verbs kept as three. ἀγανακτεῖν is "be distressed" in the death scene (STYLE §11). |
| 10 | p-047 | 118a | "he gave no answer." → "he gave no further answer." | οὐδὲν ἔτι ἀπεκρίνατο. |

## Divergence notes updated
- Book 10, *Phaedo* 114d: the note now reads "the same word as the 'risk' of neglecting the soul at 107c" (it was "'danger'"), to match p-001 as it now stands. The `lectio` fields of the other notes quote wording that did not change.

## Dropped on second look
- 07 p-001 (78b), "Good, he said." → "Well said, he said.": dropped because "Well said, he said" is clumsy aloud. STYLE §7 should fix καλῶς λέγεις instead.
- 08 p-031 (90a), "the very good and the very bad are few": the analogy that follows (very large, very small; the winners of a contest in wickedness) supports reading σφόδρα with the extremes. The draft is defensible.
- 08 p-009 (86d), "looked straight at us": "us" is implied by the narrator's scene. It is harmless.
- 08 p-102–103 (94e), "I think so" after a two-sided question: the Greek has the same looseness. Not changed; left for the editor (below).
- 10 p-025 (114b), "freed and released … as from prisons": "rid of" would be worse English, and the prison image licenses "released". Raised as a challenge to STYLE §11, not as an error.
- 10 p-044 (117e), "took hold of him … touched him again himself": acceptable for ἐφαπτόμενος / ἥπτετο. "Again" is fair, since he had already felt him.

## For the editor
1. *Phaedo* 94e: whether to recast the question (Jowett's "or rather …?") so that Simmias' "By Zeus, Socrates, I think so" plainly agrees with Socrates.
2. Burnet's deletions now followed at 78e, 83b, 84b, 86e, 100d–e, 112c and 115a. Of these, 115a and 100d–e affect meaning. If the edition is to follow a later text, revisit them. Books 01–06 should be checked against the same `<del>` list.
3. STYLE changes proposed: allow εἶδος as "kind" where it is not a Form (79a–e); allow "released" for ἀπαλλάττεσθαι in the prison image; add καλῶς λέγεις and οὐδ' ὁπωστιοῦν to the §7 formulas; mark Burnet's brackets in the flattened cache.
