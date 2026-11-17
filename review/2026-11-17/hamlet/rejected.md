# Hamlet · verify 2026-11-17 · rejected issues and policies

Verified against the bundled original (`original`, Gutenberg 1524, the conflated Q2/F text).
The edition's own rule is a light touch: keep the verse lines and Shakespeare's words, clear
only dead vocabulary, archaic grammar and inverted syntax. Most confirmed entries in `patch.json`
put the source wording back.

## Policies

1. **Line-initial capitals: sentence case.** The edition starts every verse line after the
   first in lower case, and it does so consistently in all five acts. Keep it. Changing it would
   touch every speech, and nothing is lost by it, because line breaks are kept exactly. Songs,
   Hamlet's poem and the Mousetrap follow the same rule. No patch entries.
2. **"Ay": keep Shakespeare's "Ay".** Acts III and V already keep it, and every reader takes it
   as "aye". Acts I, II and IV had changed it to "Yes", so they get one entry each (low). "Yea"
   may stay "yes". Exception: Act II `seg-0222` and `seg-0224` are identical paragraphs
   ("FIRST PLAYER / Yes, my lord."), so `apply.py`, which needs a unique match per section,
   cannot target them. The editor changes those two by hand.
3. **thou/thee: "you" throughout, with a closed list of exceptions.** A line keeps Shakespeare's
   pronoun only where the pronoun is part of a proverbial quotation: "Frailty, thy name is woman"
   (already kept), "to thine own self be true", "Get thee to a nunnery" (already kept), "absent
   thee from felicity awhile", "flights of angels sing thee to thy rest". No other line gets one.
4. **Royal "we": Claudius keeps the plural wherever Shakespeare gives it to him.** Where
   Shakespeare's Claudius says "I", the edition keeps "I". Act IV was the only act that
   converted his plural; it is restored in `seg-0009`, `0040`, `0133`, `0152`, `0182` and
   `0206`, which includes two places the reviewer missed (`0040`, `0152`).
5. **O / Oh: "O" for direct address, "Oh" for a bare exclamation.** This is mechanical: the
   editor normalizes it in one pass. Patched only in Act I `seg-0252`, where the line mixed the
   two.
6. **Set pieces stay in italics.** The letter, Hamlet's poem, the Player's speeches, the songs
   and the Prologue keep the source's `_…_` italics and song indentation. Act II's set pieces
   had been put in quotation marks, and Act IV's songs had lost their indent. This is a
   mechanical typographic pass, not patched entry by entry. Exception: Act I `seg-0292`
   ("Hic et ubique") is patched, because it also takes out a bracketed gloss.
7. **Speaker labels carry no trailing period.** Act V has "HAMLET." where Acts I–IV have
   "HAMLET". Mechanical; the editor fixes it in one pass.
8. **Recorded divergences to revise.** Two entries overrule notes in `pipeline/modern/hamlet.json`
   → `divergences`: "methinks" (III.ii, now restored) and "the mobled queen" (2.2, now
   restored). `apply.py` changes book text only, so the editor updates those two notes by hand.

## Rejected

- Act I `seg-0004` · "No—you answer me" correctly clears "Nay, answer me"; the reviewer gave no reading for it.
- Act I `seg-0007` · "He." as an answer is archaic grammar (the third person for "it's me"). "The same." is a fair clearing.
- Act I `seg-0011` · "a quiet watch" for "quiet guard": in modern English "a quiet guard" would mean the person. The edition's word is right.
- Act I `seg-0112` · "fine" is an accurate modern equivalent of "goodly" (handsome, fine), so there is no sense shift. Restoring it gains nothing.
- Act I whole act · line-initial lower case: covered by Policy 1.
- Act II `seg-0157` · "in understanding" for "in apprehension": today "apprehension" means anxiety, so this clears a sense readers no longer carry. Correct as is.
- Act II `seg-0137` · "A fine one" for "A goodly one": same reasoning as Act I `seg-0112`.
- Act II `seg-0189` · "Bah, bah" for "Buzz, buzz": a recorded divergence. To a modern ear "buzz" is a sound effect, not a put-down, and the note gives a sound reason. Kept.
- Act II `seg-0097` · "Very well" for "Excellent well": the adjective-as-adverb is archaic grammar, so clearing it is within the rule.
- Act II `seg-0195` · "passing well": "passing" (very) is dead vocabulary. The couplet "more / well" does not rhyme in the source either, and the meter stays close.
- Act II `seg-0073`, `0075`, `0205`, `0207`, `0213` · lost italics and capitals in the letter, poem and Player's speech: covered by Policies 1 and 6. The poem's one wording change ("doubt truth to be a liar") is patched.
- Act III whole act · "Ay" kept in this act but not elsewhere: covered by Policy 2. Act III is the model.
- Act IV `seg-0112`, `0114`, `0123`, `0177` · song indentation and initial capitals: covered by Policies 1 and 6. The two wording points ("shoon", "betime") are patched.
- Act IV `seg-0009`, `0182`, `0206` · royal "we": accepted and patched under Policy 4 (listed here only as a pointer).
- Act V `seg-0084` · "imagination" for "fancy": a recorded divergence. Today "fancy" reads as a whim, so the clearing is sound. The repetition of "imagination" two lines later is Shakespeare's own word in that place. Only "chapfallen" is patched.
- Act V `seg-0120` · "To show me up": in American usage "show up" means to outdo or put to shame, which is the sense of "outface" here. Not British slang in this context.
- Act V whole act · trailing period on speaker labels: covered by Policy 7.

## Finish

Done on 2026-11-17, after `patch.json` was applied (all 147 entries are in the text), in
`pipeline/modern/hamlet.json` only. Paragraph counts per act are unchanged (299, 231, 311, 247,
305), and so is the number of line breaks in every paragraph.

- **Policy 2, "Ay":** Act II `seg-0222` and `seg-0224` changed by hand from "Yes, my lord." to
  "Ay, my lord." (2 changes).
- **Policy 5, O / Oh:** 42 changes. "O" kept or restored wherever it stands directly before the
  one addressed, including apostrophes to things ("O my prophetic soul", "O wretched state",
  "O cursèd spite", "O proud Death"). Changed: "Oh" before an addressee to "O" (8: Act II
  `0141` "O God, I could"; Act IV `0011`, `0131` twice, `0147`, `0166` three times, all as in the
  source); "O," before an addressee loses its comma (3: Act III `0075`, `0188`, `0199`, as in the
  source); "O" as a bare exclamation becomes "Oh," (31, in Acts III and V; mid-line "But, O, what
  form" in `0237` becomes "But, oh, what form"). Left as they are, for the editor to judge:
  Act I `0250` "O horrible! O horrible! most horrible!"; Act II `0203` "Oh, my old friend!"
  (source has the comma); Act III `0021` "O heavy burden!", `0091` "O ho!", `0107` the quoted
  ballad tag "For, O, for O, the hobby-horse is forgot!", `0269` "O me", `0279` "O shame!";
  Act V `0274` "O villainy!".
- **Policy 7, speaker labels:** the trailing period removed from all 256 speaker labels in Act V
  (including "OSRIC and LORDS").
- **Policy 8, divergence notes:** "the mobled queen" and "The lady protests too much, methinks"
  rewritten to quote the text as it now stands and give the reason the patch gives. Overview,
  method and introduction still describe the edition correctly; unchanged.
- **Policies 1, 3, 4:** nothing left to do (Policy 1 keeps the text as is; 3 and 4 were patched).

Still left for the editor:

- **Policy 6, italics for the set pieces** (the letter, Hamlet's poem, the Player's speeches,
  the songs, the Prologue; Act II's quotation marks, Act IV's song indentation). Not done here.
- The O / Oh cases listed above.
- Two older notes quote the text a little differently from how it reads, though no patch touched
  them: "argal ... se offendendo" quotes "argal, she drowned herself on purpose" (text: "Argal,
  she drowned herself on purpose."), and "Alas, poor Yorick" quotes "Horatio — a fellow" (text:
  "Horatio—a fellow").
