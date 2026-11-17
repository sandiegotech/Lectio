# The Golden Sayings of Epictetus · fix pass

Applied 2026-11-17 to `book-01.json` … `book-08.json` after a second check of every finding in `01.md`–`10.md` against Schenkl's Greek (Perseus), the Gnomologium in the Schenkl scan, the cached Cleanthes, and Crossley. Text only: no paragraph added, removed or reordered (counts per file unchanged: 25, 27, 16, 15, 26, 26, 22, 32, 24, 4); each file still round-trips exactly as JSON with indent 1, non-ASCII kept, no trailing newline. No divergence note quoted any wording that changed, so no note was rewritten. `book-09.json` and `book-10.json` are untouched.

## Changes (37 edits in 29 sayings: 11 medium, 18 low)

### Medium
| Saying | Old → new | Why |
|---|---|---|
| VII | "to do good and to be abused for it" → "to do good and to be spoken ill of" | Shared with Marcus (Meditations VII.36); the Lectio Meditations prints "It is kingly to do good and to be spoken ill of." Greek κακῶς δ' ἀκούειν has no "for it". |
| LXXXIII | "No one can rob us of our will;" → "No one can rob us of our free will;" | Shared with Marcus (XI.36); the Lectio Meditations prints "No one can rob us of our free will." Applied under the shared-line policy; see the editor's list. |
| IX | "A miserable little man." "This wretched flesh of mine." → "A miserable little man, and this wretched flesh of mine." | One utterance in the Greek (1.3.5); two quotations read as two speakers. |
| XVI | "…the universe is governed, and has learned that…" → "…the universe is governed. He has learned that…" | Read-aloud: a ninety-word period before the main verb. The Greek's structure is kept; only the opening is made a sentence. |
| XVII | "who, once they have recognized … and seen that we have … would want to throw them off" → "who recognize … and see that we have … and then want to throw them off" | Read-aloud: fifty words hung between "who" and its verb. Same Greek (ἐπιγνόντες … ἀπορρῖψαι θέλωσιν). |
| XXIX | "But for me to want, at random, whatever I happen to fancy to come about:" → "But that I should want things at random, and that whatever I happen to fancy should come about:" | Two parallel clauses in the Greek (τὸ δ' ὡς ἔτυχέν με βούλεσθαι τὰ δ' ὡς ἔτυχεν δόξαντα γίνεσθαι); the infinitive chain could not be followed. |
| LXXI | "From here, out of your mind, throw out, in place of" → "Throw out of your own mind, in place of" | Read-aloud: four stops before the object. ἐντεῦθεν ἐκ τῆς διανοίας ἔκβαλε. |
| XCVIII | "…something to do; to turn our minds…; to look at how…; …to work it out" → "…something to do. We should turn our minds…; look at how…; …work it out" | Read-aloud: one 120-word sentence; the Greek has a stop after διαγωγῆς μὴ ἀπορεῖν. |
| CIV | "If not, see that you are behaving like children" → "If not, know that you will be behaving like children" | Read as an order to behave like children. ὅρα ὅτι … ἀναστραφήσῃ, future. |
| CXV | "Question the divine." → "Consult the divine." | Read as "doubt God". ἀνάκρινον τὸ δαιμόνιον: inquire of it, as of an oracle. |
| CLIV | "I ate well for myself" → "I ate properly, for myself" | "Ate well" now means good food. ἤσθιον ἐμαυτῷ καλῶς. |

### Low
| Saying | Old → new | Why |
|---|---|---|
| I | "hymn too, that he has given" → "hymn too: that he has given" | The clause gives the hymn's content; the comma made it read as a relative. |
| VI | "I pray to the gods that I may be." → "I pray to the gods." | εὔχομαι δὲ τοῖς θεοῖς; the rest was explanation. |
| XI | "had felt something not hard to understand" → "had felt something natural enough" | οὐκ ἀπίθανον; the double negative trips aloud. |
| XII | "better than I am at staying awake" → "better than I was at staying awake" | κρείσσων ἦν, past. |
| XIV | "Do you not bathe badly?" → "Are you not badly off for a bath?" | Odd English; keeps the run of "Are you not". |
| XIV | "what do I still care about anything" → "why should I still care about anything" | Idiom. |
| XXVII | "I have lost by it." → "I have suffered a loss." | Dated idiom; ἐζημίωμαι. |
| XLI | "it looks as if you were a slave yourself first" → "you seem to have been a slave yourself first" | Gnom. 36 αὐτὸς ὑπάρχειν πρότερον ἔοικας δοῦλος. |
| LVIII | "call on the god and beg him" → "call on God and beg him" | Same ὁ θεός as "what seems good to God" two sentences on; style sheet. |
| XCI | "the well-behaved man" → "the decent man" | Nursery register for τὸν κόσμιον. |
| XCIX | "A man who goes in often with certain people" → "A man who mixes often with certain people" | συγκαθιέντα; "goes in with" is not idiomatic. |
| CX | quoted speech ("…," he said. "But this much…" with inner single quotes) → "He said: We will look into it… But this much…" with inner double quotes, no closing mark | Style sheet: after Arrian's "he said" a speech of Epictetus is not quoted (as XXXIV, XXXVI, XC). Five edits in the one paragraph; words unchanged. |
| CXIX | "When he sees that he has kept watch" → "When you see that he has kept watch" | ὅταν ἴδῃς; Crossley's "when he knows" had been followed. |
| CXXI | "Men, the philosopher's school" → "Gentlemen, the philosopher's school" | ἄνδρες addressing the class; style sheet. |
| CXXX | "Going abroad is this, and a small change. Death is this, a greater change" → "Going abroad is this: a small change. Death is this: a greater change" | Restores the Greek's parallel. |
| CLIII | "in following my own improvement" → "in watching myself grow better" | παρακολουθῶν ἐμαυτῷ βελτίονι γινομένῳ; "following" was ambiguous. |
| CLVI | "do not give yourself up" → "do not despair of yourself" | μὴ ἀπογνῷς σεαυτοῦ; read as surrender, and doubled the next clause. |
| CLXXXVI | "What do I still care?" → "What does it matter to me now?" | Idiom; τί οὖν ἔτι μοι μέλει. |
| CLXXXVIII | "(for how could he proclaim it?)" → "—for how could he proclaim it?—" | No brackets in a paragraph; unspaced em dashes per the Meditations policy. |

## Dropped on second look
- Hymn, stanza 3, "apart from you, O god": considered changing to avoid an exclamation-like "O god"; in an invocation it reads as address, and δαῖμον is rendered literally. Kept.
- LIII, the long question about the raven and the messenger: one indignant question in the Greek; it carries aloud with the colon. Kept.
- CXXX, "ears of grain" against the Lectio Meditations' "ears of corn" (XI.34): Marcus paraphrases rather than quotes, so this is not a shared line; and "corn" means maize to an American reader. Kept.
- LXX, "never got past a philosopher's door": close enough to οὐδὲ θύραν παρῆλθον. Kept.
- XII, LIX, CXXXIII, extent: not changed; see the editor's list.
- Hymn lines 26–27: not changed; see the editor's list.

## For the editor
1. **LXXXIII and the word "will".** The shared-line policy forced "free will", which the Greek does not say and this book otherwise never uses for προαίρεσις. The cleaner fix is to change the Lectio Meditations XI.36 to "No one can rob us of our will." and revert LXXXIII. Decide which book moves.
2. **Extent rule.** The draft completes Greek sentences Crossley cut short (XII "for a lamp he became like a wild beast"; XCVII "and that is another's … that can be hindered"; CXXXIII "not in word but in deed"; LXXVII and CXXIV, which have notes) and in LIX restores three questions Crossley skipped ("Flesh? … Land? … Fame? Far from it."), with no gap recorded. The style sheet says to skip where he skipped and to complete only a half that cannot stand. Either tighten these to Crossley or widen the rule in STYLE.md.
3. **The hymn, lines 26–27** ("they rush off without sense, each after a different thing: some in a quarrelsome zeal for fame") were rendered from memory and the reading behind "without sense" (ἄνευ νόου or ἄνευ καλοῦ) is unsettled. Check against von Arnim, SVF I.537, or Thom before release.
4. **IV divergence note** names Salmasius and Schweighäuser/Simplicius as sources of the two fillings of Schenkl's gap; not verified in this pass.
5. **STYLE.md** lists κόσμιος only as "a citizen of the universe"; in XCI it is the ordinary "decent". Add the second sense.
6. No full read-aloud of the edition was done apart from this review's.

## Paragraphs that rest on no Greek
Made from Crossley's English, checked only against Long's version of the same Schweighäuser fragment:

- Saying LXII (Schweighäuser fr. 57)
- Saying LXV (fr. 170)
- Saying XCVI (fr. 68)
- Saying CXLIII (fr. 130)
- Saying CLXXXI (fr. 173)
- Saying CLXXXII (fr. 172)
- Fragment IV (fr. 103)
- Fragment V (fr. 141)
- Fragment VI (fr. 142)
- Fragment IX (fr. 96)
- Fragment X (fr. 8, first and last sentences)
- Fragment XIII (fr. 104)
- Fragment XVII (fr. 138)
- Fragment XIX (fr. 119)
- Fragment XX (fr. 144)
- Fragment XXI (fr. 118)
- Fragment XXIII (fr. 156)
- Fragment XXIV (fr. 120)

Also not from a full Greek text: hymn lines 26–27 (from memory, above).
