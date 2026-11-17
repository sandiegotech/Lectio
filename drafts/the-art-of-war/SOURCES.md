# The Art of War · sources

Drafted 2026-11-17. Slug `the-art-of-war`. Nothing here ships until the book is ingested and reviewed.

## The public-domain base (a control on meaning, not the text modernized)

- **Lionel Giles, *Sun Tzŭ on the Art of War: The Oldest Military Treatise in the World*,
  translated from the Chinese with introduction and critical notes (London: Luzac, 1910).**
  Giles died in 1958; the 1910 text is in the public domain in the United States and
  everywhere that counts life plus 70.
- Project Gutenberg ebook #132. `www.gutenberg.org` was down for maintenance on the day of
  the draft, so the file was taken from Gutenberg's own mirror:
  `https://gutenberg.pglaf.org/1/3/132/132-0.txt` (315,648 bytes, same file as
  `https://www.gutenberg.org/cache/epub/132/pg132.txt`).
- Cached as `pipeline/.cache/gutenberg-132.txt`.
- **Giles's commentary is not text.** In the Gutenberg file every numbered saying is followed
  by Giles's notes and his digest of the Chinese commentators, set in square brackets, often
  many paragraphs long, and with brackets that do not always balance. None of it may enter
  the edition. A working copy with the bracketed matter removed is cached as
  `pipeline/.cache/gutenberg-132-giles-text-only.txt` (about 11,500 words). It was made by a
  rough script and still holds a few stray lines of Giles's own (book references such as
  "Aids to Scouting", "Marshal Turenne", one "Tu Yu says", one "The latter defined as", and
  the note on the general's sense of honour in VIII). It is a reading aid for the drafter,
  not an ingest source. The ingest recipe must strip the commentary properly and check the
  count of numbered sayings per chapter.
- Giles's numbering of sayings (I.1 to XIII.27) is his own, not the Chinese text's. The draft
  uses it only as a locus in `divergences` ("I.18"), never in a paragraph.

## The original

- **孫子兵法, the received text of the thirteen chapters**, in traditional characters, from
  Chinese Wikisource: `https://zh.wikisource.org/wiki/孫子兵法`, fetched as raw wikitext
  (`?action=raw`). Cached as `pipeline/.cache/wikisource-zh-sunzi-bingfa.txt` (31,198 bytes).
  The text is ancient and in the public domain; Wikisource's transcription is CC BY-SA / public
  domain text.
- The page gives the thirteen chapters under their traditional headings (始計第一 … 用間第十三)
  and then an appendix, 答話 (the dialogues of the King of Wu with Sun Wu, from later
  sources). **The appendix is not part of the thirteen chapters and is not drafted.**
- The page marks two variants with a template: VI 勝可擅也 / 勝可為也 and IX 兵非貴益多也 /
  兵非貴益多. The draft reads 為 in VI, with the received text and Giles.
- The draft follows this received text (the tradition of the *Eleven Commentators* and the
  *Seven Military Classics*). The Yinqueshan bamboo-slip text (found 1972) is not bundled and
  is not followed. Where the received text is commonly thought damaged, the draft still
  translates what stands and says so in `divergences`.
- Places where the cached text and Giles's text differ, or where the reading is disputed, each
  recorded in the section's `divergences`: II.13–14 (the tenths); III.8 守之 / 逃之; IV.6 守則不足，
  攻則有餘 (bamboo text reversed); VI.5 不趨 / 必趨; VI.32 兵無成勢，無恒形; VII.26 金鼓 / 火鼓;
  VIII the "nine changes" and VIII.6 地利 / 五利; XI.53 四五者; XI.60 佯順 / 順詳; XIII.7 鄉間 / 因間.
- The cached text also reads 七計 ("seven calculations") at I.12, where most editions have 計
  alone; the draft translates the cached text.

## Consulted, not quoted

The Chinese commentary tradition as reported in Giles's notes (Ts'ao Ts'ao, Tu Mu, Mei
Yao-ch'en, Chang Yü and others) was read for the cruxes. Modern translations are in
copyright; none was open during the draft and none is quoted. Readings in the notes that go
against Giles are argued from the Chinese.

## Sections

Thirteen, along the work's own division into chapters. Labels are roman, as in Giles.

| File | Label | Chinese title | Lectio title | Giles's title |
|---|---|---|---|---|
| book-01.json | Chapter I | 計 (始計) | First Calculations | Laying Plans |
| book-02.json | Chapter II | 作戰 | Waging War | Waging War |
| book-03.json | Chapter III | 謀攻 | Attack by Strategy | Attack by Stratagem |
| book-04.json | Chapter IV | 形 (軍形) | Form | Tactical Dispositions |
| book-05.json | Chapter V | 勢 (兵勢) | Momentum | Energy |
| book-06.json | Chapter VI | 虛實 | The Hollow and the Solid | Weak Points and Strong |
| book-07.json | Chapter VII | 軍爭 | The Contest of Armies | Manœuvring |
| book-08.json | Chapter VIII | 九變 | The Nine Changes | Variation of Tactics |
| book-09.json | Chapter IX | 行軍 | The Army on the March | The Army on the March |
| book-10.json | Chapter X | 地形 | Terrain | Terrain |
| book-11.json | Chapter XI | 九地 | The Nine Grounds | The Nine Situations |
| book-12.json | Chapter XII | 火攻 | Attack by Fire | The Attack by Fire |
| book-13.json | Chapter XIII | 用間 | The Use of Spies | The Use of Spies |

Paragraphs follow the order of the Chinese. One paragraph holds one of Giles's numbered
sayings or a small group of them that make one thought.
