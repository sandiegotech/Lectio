# Genesis 35–50 · Lectio Vernacular · first draft · notes for the editor

Drafted 2026-11-17 from the Hebrew (Westminster Leningrad Codex, from the model's own
knowledge; the Hebrew is not bundled, so every reading below should be checked against a
printed text), with KJV 1611 as the control. Files: `chapter-35.json` … `chapter-50.json`, in
the shape of a `chapters` entry in `pipeline/modern/bible-genesis.json`. `selfcheck.py` in this
folder checks JSON, spine/paragraph counts and verse coverage against the bundled KJV.
Nothing here is integrated; `pipeline/modern/bible-genesis.json` is untouched.

Policies followed are those of `review/2026-11-17/bible-genesis/rejected.md`: received Hebrew
kept where it is unclear and the guess left out of the sentence; only words the Hebrew has;
"sky" for the physical sky; *hesed* as "kindness". No apparatus is printed in any paragraph.

## Needs the pipeline

- **Chapter 49 is poetry and is written as prose.** The build flattens line breaks, so Jacob's
  blessing (49:2–27) is one paragraph per tribe, 49:1–2 as the opening, 49:28–33 as the prose
  close. Each sentence is one or two parallel lines, so it can be broken into lines without
  rewording once the pipeline keeps `\n` inside a segment (same fix as the seven poems listed
  in the review). The speech runs across twelve paragraphs: each opens with a quotation mark
  and only the last (Benjamin) closes it.
- **Three paragraphs open mid-speech** with an opening quote and no close on the paragraph
  before (44:30, 45:9, and chapter 49), the convention chapter 31 already uses.

## Carried over from chapters 1–34

"the LORD"; El Shaddai kept as a name (35:11, 43:14, 48:3; bare "Shaddai" at 49:25, as the
Hebrew has it); "messenger" for *mal'akh* (48:16); "standing stone"; "offspring" for *zera*;
"slave" for *shifchah/amah* and for *eved* when it means ownership, "servant" in polite
self-reference ("your servant") and for Pharaoh's court; "These are the generations of"
(36:1, 36:9, 37:2); "burial holding" (49:30, 50:13, as in chapter 23); "breathed his last …
gathered to his people"; "Here I am"; "Am I in God's place?" (50:19, word for word as Jacob
says it at 30:2); "put your hand under my thigh" (47:29, as 24:2); "pieces of silver" where
the Hebrew says only "silver" with a number (37:28, 45:22). Place-name meanings are not
glossed (Allon-bacuth, Ben-oni, Abel-mizraim, Perez), as in the earlier chapters.

## The Joseph story: key words held constant

- **The coat** (*ketonet passim*, 37:3, 23, 32). "an ornamented coat". See crux 1. Plain
  "coat" wherever the Hebrew has *ketonet* alone. Joseph's later clothes are different words
  and are kept different: "garment" (*beged*, eight times in chapter 39), "garments of fine
  linen" (41:42), "change of clothes" (45:22).
- **Recognize** (*hikkir*): "Recognize it, please" (37:32) and "Recognize, please" (38:25)
  are the same two Hebrew words, and the echo is why chapter 38 sits where it does. Then
  42:7–8, where "he made himself a stranger to them" is the same root.
- **Dream / interpret**: "dreamed a dream" kept doubled every time; "master of dreams"
  (37:19); "interpret" and "meaning" for *patar/pitron* throughout 40–41.
- **Sent** (*shalach*): "I will send you to them" (37:13), "he sent him" (37:14), "they sent
  the ornamented coat" (37:32), then "God sent me ahead of you … it was not you who sent me
  here, but God" (45:5–8).
- **The pit** (*bor*): the cistern of chapter 37 and Joseph's prison at 40:15 and 41:14 are
  the same word and are both "the pit".
- **Went down / brought down**, **silver**, **"so that we live and do not die"** (42:2, 43:8,
  47:19), **"torn, torn to pieces"** (37:33, quoted back at 44:28), **"bring my gray head
  down to Sheol"** (42:38, 44:29, 44:31), **"lift up your head"** three ways in chapter 40,
  **"pledge"** (38:17–20 and Judah's "I myself will be his pledge", 43:9, 44:32), and
  **"provide for"** (*kilkel*, 45:11, 47:12, 50:21) are each rendered one way.
- **Jacob / Israel** alternate as in the Hebrew, never harmonized.

## Cruxes, most important first

1. **37:3 *ketonet passim*.** Nobody knows what *passim* means. "Many colours" is the
   Septuagint's guess; "long-sleeved" or "reaching to the wrists and ankles" is the other
   (the only other wearer is a king's daughter, 2 Samuel 13:18). "Ornamented" is the
   least-committed word I could find that still reads as English, but it is still a gloss.
   Under the review's policy 2 the strict alternative is a plain "a special coat" or even
   "a coat of passim". Editor's call; it changes three verses (37:3, 23, 32).
2. **37:28 and 37:36: who sold Joseph.** The Hebrew has Ishmaelites (37:25, 27, 28; 39:1),
   Midianites (37:28) and, at 37:36, *Medanim*, "Medanites" (a different son of Keturah,
   25:2). KJV prints "Midianites" at 37:36. I print the three names as the Hebrew has them
   and leave "they pulled Joseph up" (37:28) with the same loose subject the Hebrew has.
3. **49:10 "until Shiloh comes".** The most disputed line in the book: "until Shiloh comes",
   "until he comes to Shiloh", "until tribute comes to him", "until he comes to whom it
   belongs". Printed as the received text reads; needs a `divergences` entry.
4. **49:5 *mekheroteihem*.** Unknown word. "Their weapons" is a context guess (KJV took it as
   "habitations"). Strictly this is a guess in the sentence; I could find no way to leave it
   open that was still a sentence. Flagged for the editor.
5. **49:22–26, the Joseph blessing.** Nearly every line is uncertain. *ben porat* is printed
   as "a fruitful bough" (the other reading is "a wild donkey", with "daughters" as the wild
   asses on the ridge, not "branches … over the wall"). 49:24 "from there, the Shepherd, the
   Stone of Israel" follows the Masoretic pointing word for word. 49:26 "the blessings of my
   ancestors, up to the bounds of the everlasting hills" follows the received *horai*
   ("those who conceived me"); most modern versions emend to "the ancient mountains".
6. **49:21 Naphtali.** "who gives lovely words" is the received pointing (*imre shafer*); the
   common alternative is "who bears lovely fawns". 49:14 "saddlebags" (*mishpetayim*) is
   also read "sheepfolds". 49:4 "My couch he went up to!" keeps the Hebrew's sudden turn to
   the third person. 49:20 "From Asher" keeps the received *me'asher*.
7. **36:24 *yemim*.** Unknown; KJV "mules", Vulgate "hot springs". Printed "the yemim", on
   the model of "gopher wood" at 6:14. 36:26 the Hebrew reads **Dishan** where the list
   requires Dishon (so KJV and 1 Chronicles 1:41); I print the received "Dishan", which makes
   two "sons of Dishan" in the paragraph. 36:39 "Hadar" (Chronicles: Hadad) is kept. 36:2 and
   36:14 "Anah, daughter of Zibeon" kept as the Hebrew has it (the versions read "son").
8. **38:21–22 *qedeshah*.** Judah takes Tamar for a *zonah* ("whore", as at 34:31), but his
   friend asks the townsmen for the *qedeshah*, a politer word from the root "holy".
   Rendered "the consecrated woman" so the change of word shows. KJV has "harlot" for both.
9. **41:40 "by your word all my people will be led".** The verb looks like "kiss"
   (*yishaq*); the sense is guessed from context by every version. 41:43 "Abrek!" is kept
   untranslated (KJV "Bow the knee"; possibly Egyptian). 41:56 "Joseph opened all that was
   in them" is the received text, which lacks a noun; the versions supply "the storehouses".
   41:34 "take a fifth from the land" keeps the Hebrew's "fifth the land".
10. **47:21 "he moved them into the cities".** Received Hebrew. The Samaritan and Greek read
    "he made them slaves", which fits 47:19 and 47:25 and is what most modern versions print.
    47:31 "bowed at the head of the bed": the Greek read the same consonants as "staff"
    (hence Hebrews 11:21). Both want `divergences` entries.
11. **48:22 "one shoulder of land".** *shekhem* is "shoulder" and is also the city Shechem;
    the pun is the point and cannot be kept. "of land" is my addition to make "shoulder"
    readable and is the one place I added words the Hebrew does not have.
12. **45:24 "Do not be stirred up on the road".** *tirgezu* is "be agitated": "do not
    quarrel" (KJV "fall not out") or "do not be afraid". Left as open as English allows.
13. **39:6 "well built and beautiful".** The Hebrew phrase is the one used of Rachel at
    29:17 ("shapely and beautiful" in the edition); the echo of his mother is deliberate.
    I changed only the first word. 39:14, 17 "to play with us/me" is the verb of 26:8
    ("playing with Rebekah") and of Isaac's name.
14. **35:7 "God had shown himself"**: the verb is plural in the Hebrew. 35:16 and 48:7
    "some distance" renders *kivrat ha'arets*, an unknown measure. 35:22 has a break in the
    middle of the verse in the Hebrew; "And Israel heard." ends the sentence and the list of
    sons starts the next, in the same paragraph, since a spine cannot split a verse.
15. **40:16 "baskets of white bread"** (*chori*: also read "wicker baskets"). 40:19 "lift up
    your head — off you —" keeps the grim third turn of the phrase. 39:20 *bet hassohar*
    (a word found only in this story) is plain "prison".
16. **46:13 "Iob"** is the received spelling (KJV "Job"; Numbers 26:24 and the versions have
    Jashub). 46:15 says thirty-three and the names as listed do not obviously add up to it;
    the numbers are printed as given, 33 + 16 + 14 + 7 = 70 (46:27), and 66 at 46:26.
17. **50:20.** "You planned evil against me; God planned it for good" uses one verb twice,
    as the Hebrew does (*chashav*), where KJV has "thought … meant".

## Smaller decisions

- Names in chapters 36 and 46 use the standard modern English spellings (Oholibamah,
  Basemath, Jalam, Pallu, Perez, Zerah, Puvah), not KJV's (Aholibamah, Bashemath, Jaalam,
  Phallu, Pharez, Zarah, Phuvah). *alluf* is "chief" (KJV "duke").
- *keseph* is "silver" throughout 42–47, never "money", so the silver cup and the silver in
  the sacks stay one thing.
- Two words for the brothers' bags are kept apart: "sack" (*saq*) and "pack" (*amtachat*).
- 43:14 and 43:30 "compassion" for *rachamim* both times. 47:9 "my life as a stranger" for
  *megurai*, matching "stranger" in chapters 15–37.
- 38:9 "wasted it on the ground" is as plain as the Hebrew. 38:26 "did not know her again".
- 37:35, 42:38, 44:29, 44:31 "Sheol" is kept as a name (first appearances in the book).

## Not done

- No `divergences` objects were written (the chapter shape has no field for them). Cruxes 1,
  2, 3, 5, 8, 10 and 11 are the ones a reader should be told about.
- No second-reader review. The Hebrew was not available to check against on disk.
