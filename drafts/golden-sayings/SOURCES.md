# The Golden Sayings of Epictetus · sources

Drafted 2026-11-17. Slug `golden-sayings`. Nothing here ships until the book is ingested and reviewed.

## The public-domain base (a control on meaning, not the text modernized)

- **Hastings Crossley, *The Golden Sayings of Epictetus, with the Hymn of Cleanthes*,
  translated and arranged (London: Macmillan, 1903)**; the selection reprinted in the Harvard
  Classics, vol. 2 (1909). Published before 1929, so in the public domain in the United
  States; Crossley's death date was not checked for this draft and should be confirmed
  before any claim is made for life-plus-70 countries.
- Project Gutenberg ebook #871. `www.gutenberg.org` was down for maintenance on the day of
  the draft, so the file was taken from Gutenberg's own mirror:
  `https://gutenberg.pglaf.org/8/7/871/871-0.txt` (152,011 bytes, the same file as
  `https://www.gutenberg.org/cache/epub/871/pg871.txt`). Cached as
  `pipeline/.cache/gutenberg-871.txt`.
- The file holds: sayings I–CLXXXIX; Appendix A, "Fragments Attributed to Epictetus", I–XXIV,
  closed by a signed note of Crossley's on the fragments; Appendix B, "The Hymn of Cleanthes",
  in Crossley's English hexameters.
- **Crossley's apparatus is not text.** His note at the end of the fragments, the two
  "(APPENDIX …)" headings, his bracketed "[Greek: Anechou kai apechou]" in CLXXXIII, his
  italics and his ellipsis dots are his own. None of it enters a paragraph. The Gutenberg
  file prints none of his source references, so the concordance below was made for this draft.
- Crossley's selection is an anthology. He lifts passages out of Arrian, runs passages from
  one chapter together, drops sentences without always marking it, and now and then turns a
  clause into a free-standing maxim. The Lectio keeps his **order, numbering and extent** and
  takes the **words** from the Greek.

## The original

- **Arrian, *Discourses of Epictetus* (Ἐπικτήτου διατριβαί), four books; the *Enchiridion*; the
  fragments.** Text of Heinrich Schenkl, *Epicteti Dissertationes ab Arriano digestae*, editio
  maior (Leipzig: Teubner, 1916), as encoded by the Perseus Digital Library (CC BY-SA; the
  Greek is ancient and Schenkl's edition is in the public domain):
  - `https://raw.githubusercontent.com/PerseusDL/canonical-greekLit/master/data/tlg0557/tlg001/tlg0557.tlg001.perseus-grc2.xml`
    (Discourses) → `pipeline/.cache/perseus-tlg0557.tlg001.perseus-grc2.xml`
  - `…/tlg0557/tlg002/tlg0557.tlg002.perseus-grc2.xml` (Enchiridion) →
    `pipeline/.cache/perseus-tlg0557.tlg002.perseus-grc2.xml`
  - `…/tlg0557/tlg003/tlg0557.tlg003.perseus-grc2.xml` (fragments 1–36 in Schenkl's
    numbering) → `pipeline/.cache/perseus-tlg0557.tlg003.perseus-grc2.xml`
- **The "Gnomologium Epicteteum" and the doubtful fragments** (the maxims Stobaeus and the
  Byzantine collections pass down under Epictetus's name, which Schweighäuser numbered and
  Crossley drew on) are not in Perseus. They are read from the scan of the same Schenkl
  volume at the Internet Archive, OCR text:
  `https://archive.org/download/ldpd_10922736_000/ldpd_10922736_000_djvu.txt` →
  `pipeline/.cache/schenkl-1916-archive-djvu.txt`. The OCR of the Greek is rough (wrong
  breathings, theta as ϑ, stray Latin letters); every line used was read and corrected by
  hand against the sense, and the corrected Greek is quoted in the concordance or in
  `divergences` where it matters. Schenkl prints Schweighäuser's number beside his own.
- **Aulus Gellius, *Attic Nights* XVII.19** (Latin, with Epictetus's two Greek words) is the
  source of CLXXXIII; Schenkl prints it as fragment 10.
- **Cleanthes, Hymn to Zeus** (Stobaeus, *Eclogae* I.1.12; von Arnim, *SVF* I.537). Greek from
  Greek Wikisource, `https://el.wikisource.org/wiki/Ύμνος_εις_Δία`, fetched as raw wikitext →
  `pipeline/.cache/wikisource-el-cleanthes-hymn.txt`. The single manuscript is damaged in
  places; the Wikisource text prints the usual supplements in angle brackets. Where the draft
  depends on a supplement, the section's `divergences` say so.

## Controls consulted, not quoted

- George Long's *Discourses of Epictetus* (1877) and T. W. Higginson's *Works of Epictetus*
  (1865), both public domain, both from Perseus (`…tlg001.perseus-eng3.xml`,
  `…tlg001.perseus-eng4.xml`, `…tlg002.perseus-eng4.xml`, cached under the same names). They
  were used by machine to find which chapter each of Crossley's sayings comes from, and by
  eye as a second control on meaning.
- George Long's version of the fragments in Schweighäuser's numbering, from the same 1877
  volume (`…/tlg0557/tlg003a/tlg0557.tlg003a.perseus-eng3.xml` →
  `pipeline/.cache/perseus-tlg0557.tlg003a.perseus-eng3.xml`). This is the second witness for
  the eighteen sayings whose Greek was not to hand (below), and it supplied Schweighäuser's
  number for every fragment.
- Modern translations are in copyright; none was open during the draft and none is quoted.

## How the concordance was made

Each of Crossley's sayings was matched by word overlap against Long and Higginson chapter by
chapter, the Greek sections of the matching stretch were then read, and the first and last
section were fixed by eye. References are to Schenkl's book.chapter.section for the
Discourses (D), chapter.section for the Enchiridion (E), and Schenkl's fragment number (fr.)
with Schweighäuser's where Schenkl gives it. "Gnom." is the Gnomologium Epicteteum Stobaei
(Schenkl's part C). A comma between references means Crossley has joined passages or
skipped; the Lectio makes the join where he does and prints no dots.

## Sections

Ten. Crossley's sayings run straight through without divisions of their own; the eight
sections of sayings are cut where his selection moves from one book of the Discourses to the
next, which is also where the lengths come out even. Labels are roman, as in Crossley.

| File | Label | What it holds | Crossley's words |
|---|---|---|---|
| `book-01.json` | Sayings I–XXV | the opening sayings; Discourses I.1–I.10 | 3,126 |
| `book-02.json` | Sayings XXVI–LII | Discourses I.12–I.30 | 2,633 |
| `book-03.json` | Sayings LIII–LXVIII | Discourses II.1–II.14 | 2,724 |
| `book-04.json` | Sayings LXIX–LXXXIII | Discourses II.15–II.24 | 2,482 |
| `book-05.json` | Sayings LXXXIV–CIX | Discourses III.1–III.21 | 3,000 |
| `book-06.json` | Sayings CX–CXXXV | Discourses III.22–III.26 | 2,854 |
| `book-07.json` | Sayings CXXXVI–CLVII | Discourses IV | 2,834 |
| `book-08.json` | Sayings CLVIII–CLXXXIX | the Enchiridion; the closing sayings | 2,618 |
| `book-09.json` | Fragments | Appendix A, fragments I–XXIV | 427 |
| `book-10.json` | The Hymn of Cleanthes | Appendix B | 36 lines of verse in four stanzas |

Sections 1–8 have no `title` (Crossley gives none and none is invented); 9 and 10 carry
Crossley's own appendix titles. Each paragraph is one saying and begins with its number as in the base ("XXV. …"); the
four paragraphs of the hymn, one for each of Crossley's stanzas, are not numbered. Where
Crossley sets a saying in several short paragraphs (the turns of a dialogue, a quoted verse),
the Lectio runs them into the one paragraph.

## Concordance

D = Discourses (book.chapter.section, Schenkl); E = Enchiridion (chapter.section); fr. =
Schenkl's fragment number; Gnom. = Gnomologium Epicteteum Stobaei (Schenkl, part C), with
Schweighäuser's fragment number in brackets as Schenkl and Long give it. Greek words in
brackets mark where an extract begins or ends inside a section.

**Not placed in the Greek (18 paragraphs).** Sayings LXII, LXV, XCVI, CXLIII, CLXXXI, CLXXXII and fragments
IV, V, VI, IX, X, XIII, XVII, XIX, XX, XXI, XXIII, XXIV are Schweighäuser fragments drawn from the Byzantine
anthologies of Antonius and Maximus. Schenkl's edition omits them as not Epictetus's, and no
Greek text of them was to hand. Each is identified by its Schweighäuser number and made from
Crossley's English alone, with Long's version of the same fragment as a second witness. They
are short (about 330 words in all) but they are the one place where this draft is not from
the original, and they need Schweighäuser's Greek before the edition is called ready.

**The hymn.** The cached Wikisource text is two lines short at lines 26–27 of the standard
numbering (the rush "each after a different thing" and "a quarrelsome zeal for fame"), which
Crossley has; they are rendered from the standard text (von Arnim, *SVF* I.537) as
remembered and must be checked when a full Greek text is bundled. Lines 4 and 14 rest on
editors' repairs. All three points are in the section's `divergences`.

**Readings.** Where the Perseus file and Schenkl's printed page differ, or Schenkl prints a
gap, the choice is recorded in `divergences`: IV (4.12.11, the gap filled with ἐμοί), LIII
(3.1.37, ἵν' ἀγνοῇς kept), LXXI (2.16.42, σός for ἴσος), CIII (3.14.3, σκώφθητι kept), CXXX
(3.24.94, οὐκ ἔσει kept). In VIII (1.2.17) the Perseus file's ἀνόμοιος is read as ἂν ὅμοιος,
with Schenkl's page and the sense.

Total: 217 paragraphs, 23,736 words (counting the saying numbers).

### `book-01.json` · Sayings I–XXV (25 paragraphs, 3,214 words)

| Saying | Source |
|---|---|
| I | D 1.16.15–21 |
| II | D 2.23.36–39 |
| III | D 4.4.26 |
| IV | D 4.12.11–12 |
| V | D 3.23.29 |
| VI | D 1.1.9 (last sentence)–13 |
| VII | D 4.6.20 |
| VIII | D 1.2.11–18 |
| IX | D 1.3.1–6 |
| X | fr. 26 (Schweighäuser 176) = Marcus Aurelius 4.41 |
| XI | D 1.18.15–16 (first sentence) |
| XII | D 1.29.21 (without the last sentence) |
| XIII | D 1.6.19–22 |
| XIV | D 1.6.23–29 |
| XV | D 1.9.1 |
| XVI | D 1.9.4–7 |
| XVII | D 1.9.10–15 |
| XVIII | D 1.9.16–17 |
| XIX | D 1.9.18–21 |
| XX | D 1.6.37–43 |
| XXI | D 1.9.22 |
| XXII | D 1.17.27, 28 (from ἐὰν θέλῃς) |
| XXIII | D 1.5.3–5 (to καλοῦμεν) |
| XXIV | D 1.10.1–7 (to μὴ γένοιτο), 9–10 |
| XXV | D 1.9.27–28 |

### `book-02.json` · Sayings XXVI–LII (27 paragraphs, 2,693 words)

| Saying | Source |
|---|---|
| XXVI | D 1.12.15 (from ἀλλὰ τὸ παιδεύεσθαι)–16 (to τῶν ὅλων) |
| XXVII | D 4.3.1 |
| XXVIII | D 1.12.1–3 |
| XXIX | D 1.12.7–12 |
| XXX | fr. 16 (Schweighäuser 72) |
| XXXI | D 1.12.20–21 (to δέχεσθαι) |
| XXXII | D 1.12.21 (from τίς οὖν ἡ κόλασις)–23 |
| XXXIII | D 1.12.26–27 |
| XXXIV | D 1.13.1–5 |
| XXXV | fr. 17 (Schweighäuser 15) |
| XXXVI | D 1.14.1–6 |
| XXXVII | D 1.14.11–17 |
| XXXVIII | D 1.15.5 |
| XXXIX | D 1.15.6–8 |
| XL | D 1.19.19–23 |
| XLI | Gnom. 36 (Schweighäuser 42) |
| XLII | D 1.19.24–25 |
| XLIII | D 1.19.26–29 |
| XLIV | D 1.24.20 |
| XLV | D 1.25.18–22 |
| XLVI | D 1.26.15–16 |
| XLVII | D 1.26.17–18 |
| XLVIII | D 2.2.8–9 |
| XLIX | D 1.29.46–49 |
| L | Gnom. 7 (Schweighäuser 7) |
| LI | D 1.30.1–4 |
| LII | D 1.29.16–18 |

### `book-03.json` · Sayings LIII–LXVIII (16 paragraphs, 2,814 words)

| Saying | Source |
|---|---|
| LIII | D 3.1.36–38 |
| LIV | D 2.2.17–18 (first sentence) |
| LV | D 2.1.8, 13 |
| LVI | D 2.5.24–26, 27 (from ἀδύνατον)–28 |
| LVII | D 2.3.1–2 |
| LVIII | D 2.7.10–14 |
| LIX | D 2.8.1–3 (to the second οὔ) |
| LX | D 2.8.9–14 |
| LXI | D 2.8.15–23 (to ἀτάραχον), 27–28 (to θείως) |
| LXII | Schweighäuser fr. 57 (not in Schenkl; no Greek to hand; from Crossley, checked against Long) |
| LXIII | D 2.12.3–4 |
| LXIV | D 2.12.14–25 |
| LXV | Schweighäuser fr. 170 (not in Schenkl; no Greek to hand; from Crossley, checked against Long) |
| LXVI | D 2.14.10–13 |
| LXVII | D 2.14.19 (from ἂν οὖν σοι δείξω)–22 |
| LXVIII | D 2.14.23–29 |

### `book-04.json` · Sayings LXIX–LXXXIII (15 paragraphs, 2,686 words)

| Saying | Source |
|---|---|
| LXIX | D 2.15.13 (from ὥστε μοι δοκῶ)–14 |
| LXX | D 2.16.32–34 |
| LXXI | D 2.16.41–42, 44 (from ὁ Ἡρακλῆς)–47 |
| LXXII | D 2.17.1 |
| LXXIII | D 2.17.29–33 |
| LXXIV | fr. 28 (Schweighäuser 178) = Marcus Aurelius 11.38 |
| LXXV | D 2.18.5 (from ὅταν ὀργισθῇς)–13 (to τῷ θεῷ) |
| LXXVI | D 2.18.19 |
| LXXVII | D 2.18.27–29 (first sentence) |
| LXXVIII | D 2.19.23–28 |
| LXXIX | E 37 |
| LXXX | D 2.21.11–16 (first sentence) |
| LXXXI | D 2.24.1–2, 3 (δοκεῖ), 4–5, 7 (from τὸν ἀνδριάντα), 10–12, 13 (first and third questions), 14 (first question), 15 (first question; from δεῖξον οὖν)–16, 19–20, 27–29 |
| LXXXII | D 2.22.24–27, 29–30 |
| LXXXIII | D 3.22.105 (last sentence) = Marcus Aurelius 11.36 |

### `book-05.json` · Sayings LXXXIV–CIX (26 paragraphs, 3,104 words)

| Saying | Source |
|---|---|
| LXXXIV | D 3.5.7–11 |
| LXXXV | D 3.5.16 (from οὐδέν σοι δοκεῖ)–17 (first and last sentences), 18 |
| LXXXVI | D 3.7.26 (last question)–28 |
| LXXXVII | D 3.3.1 (first sentence) |
| LXXXVIII | fr. 5 (Schweighäuser 67) |
| LXXXIX | D 3.3.3–4 |
| XC | D 3.6.8 |
| XCI | D 3.7.30 (οἶδας κρίνειν;), 34 (first sentence), 35–36 |
| XCII | D 3.8.5–6 |
| XCIII | D 3.9.6 (from καὶ ὡς νῦν)–14 |
| XCIV | D 3.9.16 (from σὺ δ')–18 |
| XCV | D 3.9.21 (from σοὶ πάντα)–22 |
| XCVI | Schweighäuser fr. 68 (not in Schenkl; no Greek to hand; from Crossley, checked against Long) |
| XCVII | D 3.10.19–20 |
| XCVIII | D 3.13.6–8 |
| XCIX | D 3.16.1–8 |
| C | D 3.12.16–17 |
| CI | D 3.13.21 (from μελέτησον to ὀρεχθῇς) |
| CII | D 3.13.22 (last sentence)–23 |
| CIII | D 3.14.1–3 |
| CIV | D 3.15.2–7, 9–12 (first sentence) |
| CV | D 3.19.6 (second sentence) |
| CVI | D 3.20.9–12 |
| CVII | D 3.16.9–10 |
| CVIII | D 3.21.17–20 |
| CIX | D 3.21.23 |

### `book-06.json` · Sayings CX–CXXXV (26 paragraphs, 2,875 words)

| Saying | Source |
|---|---|
| CX | D 3.22.1–5, 7–8 |
| CXI | D 3.22.14–15 |
| CXII | D 3.22.21 (from θάνατος)–22 |
| CXIII | D 3.22.23–25 |
| CXIV | D 3.22.45–48 (to ἐλεύθερος; from πότ' ἐμεμψάμην)–49 |
| CXV | D 3.22.53 (first sentence) |
| CXVI | D 3.22.67–69 |
| CXVII | D 3.22.83–85 |
| CXVIII | D 3.22.86–89 |
| CXIX | D 3.22.94 (from τοῖς βασιλεῦσι)–96 |
| CXX | D 3.23.27–28 |
| CXXI | D 3.23.30–32 (first sentence) |
| CXXII | D 3.24.2 |
| CXXIII | D 3.24.9–11 (to ᾠκειωμένων) |
| CXXIV | D 3.24.14 (from ὅς γε καὶ ἐγάμει)–16 |
| CXXV | D 3.24.31 (from οὐκ οἶσθ')–32, 34–35 |
| CXXVI | D 3.24.50 (from πάλιν ἐπελάθου), 51 (from ἔπαθλον)–52 |
| CXXVII | D 3.24.63 |
| CXXVIII | D 3.24.64–65 |
| CXXIX | D 3.24.83 (last sentence) |
| CXXX | D 3.24.86 (to τοῦ ἔτους), 89 (the objection; from σὺ δὲ δύσφημα), 90 (first sentence), 91–94 |
| CXXXI | D 3.24.95–98 |
| CXXXII | D 3.24.99 (from ἣν ἂν χώραν)–101 |
| CXXXIII | D 3.24.109–110 |
| CXXXIV | D 3.26.28 (last clause)–30 |
| CXXXV | D 3.26.38 (from ἆρ' οὖν)–39 |

### `book-07.json` · Sayings CXXXVI–CLVII (22 paragraphs, 2,825 words)

| Saying | Source |
|---|---|
| CXXXVI | D 4.1.1–3 |
| CXXXVII | D 4.1.91–98 |
| CXXXVIII | D 4.1.99–100 (first sentence) |
| CXXXIX | D 4.1.103–106 (to ἐγένου) |
| CXL | D 4.1.106 (from τί ἄπληστος εἶ)–109 |
| CXLI | D 4.1.151–155 |
| CXLII | D 4.1.170–173 |
| CXLIII | Schweighäuser fr. 130 (not in Schenkl; no Greek to hand; from Crossley, checked against Long) |
| CXLIV | D 4.3.9 (last sentence)–12 |
| CXLV | D 4.4.1–5 |
| CXLVI | D 4.4.46 (from εἰ τὸ κακόηθες)–47 (first sentence) |
| CXLVII | D 4.4.47 (from ταῦτα ἐκ σοῦ)–48 |
| CXLVIII | D 4.5.34 (last clause)–35 |
| CXLIX | Gnom. 29 (Schweighäuser 39) |
| CL | D 4.6.24 |
| CLI | D 4.7.6 (from ὅτι ὁ θεός)–11 |
| CLII | D 4.7.19–20 |
| CLIII | D 3.5.14 |
| CLIV | D 4.8.16 (from ἀλλ' ἁρμόζεται)–20 (first sentence) |
| CLV | D 4.8.35 (from ἀγνοεῖσθαι)–37 |
| CLVI | D 4.9.14–16 |
| CLVII | D 1.24.1–2 (to οὐ γίγνεται) |

### `book-08.json` · Sayings CLVIII–CLXXXIX (32 paragraphs, 2,649 words)

| Saying | Source |
|---|---|
| CLVIII | E 13 (first sentence) |
| CLIX | E 15 (to συνάρχων) |
| CLX | E 17 |
| CLXI | E 21 |
| CLXII | E 27 |
| CLXIII | E 31.1 |
| CLXIV | E 33.1–3 |
| CLXV | E 33.4 |
| CLXVI | E 33.5 (first sentence) |
| CLXVII | E 33.5 (second sentence)–6 |
| CLXVIII | E 33.7 (first sentence) |
| CLXIX | E 33.9 |
| CLXX | E 33.13 |
| CLXXI | E 33.14–16 |
| CLXXII | E 35 |
| CLXXIII | E 41 |
| CLXXIV | E 43 |
| CLXXV | E 46.1–2 (to ἄρχῃ τοῦ ἔργου) |
| CLXXVI | E 47 (to περιλάμβανε) |
| CLXXVII | E 49 |
| CLXXVIII | Gnom. 20 (Schweighäuser 31) |
| CLXXIX | Gnom. 23 (Schweighäuser 33) |
| CLXXX | Gnom. 24 (Schweighäuser 34) |
| CLXXXI | Schweighäuser fr. 173 (not in Schenkl; no Greek to hand; from Crossley, checked against Long) |
| CLXXXII | Schweighäuser fr. 172 (not in Schenkl; no Greek to hand; from Crossley, checked against Long) |
| CLXXXIII | fr. 10 (Schweighäuser 179) = Aulus Gellius 17.19.5–6 (Latin) |
| CLXXXIV | E 53 |
| CLXXXV | D 2.6.26 |
| CLXXXVI | D 2.5.9–13 |
| CLXXXVII | D 1.24.3–9 (to γέμει) |
| CLXXXVIII | D 3.13.12–16 |
| CLXXXIX | D 4.10.12–13 (to ἀποδιδούς), 14–17 |

### `book-09.json` · Fragments (24 paragraphs, 462 words)

| Fragment | Source |
|---|---|
| I | Gnom. 1 (Schweighäuser 1) |
| II | Gnom. 2 (Schweighäuser 2) |
| III | Gnom. 22 (Schweighäuser 12) |
| IV | Schweighäuser fr. 103 (not in Schenkl; no Greek to hand; from Crossley, checked against Long) |
| V | Schweighäuser fr. 141 (not in Schenkl; no Greek to hand; from Crossley, checked against Long) |
| VI | Schweighäuser fr. 142 (not in Schenkl; no Greek to hand; from Crossley, checked against Long) |
| VII | Gnom. 50 (Schweighäuser 60) |
| VIII | Gnom. 55 (Schweighäuser 65) |
| IX | Schweighäuser fr. 96 (not in Schenkl; no Greek to hand; from Crossley, checked against Long) |
| X | Schweighäuser fr. 8, first and last sentences (not in Schenkl; no Greek to hand; from Crossley, checked against Long) |
| XI | fr. 33 (Schweighäuser 54) |
| XII | fr. 34 (Schweighäuser 55) |
| XIII | Schweighäuser fr. 104 (not in Schenkl; no Greek to hand; from Crossley, checked against Long) |
| XIV | Gnom. 5 (Schweighäuser 5) |
| XV | fr. 35 (Schweighäuser 114) |
| XVI | fr. 30 (Schweighäuser 89) |
| XVII | Schweighäuser fr. 138 (not in Schenkl; no Greek to hand; from Crossley, checked against Long) |
| XVIII | Gnom. 46 (Schweighäuser 13) |
| XIX | Schweighäuser fr. 119 (not in Schenkl; no Greek to hand; from Crossley, checked against Long) |
| XX | Schweighäuser fr. 144 (not in Schenkl; no Greek to hand; from Crossley, checked against Long) |
| XXI | Schweighäuser fr. 118 (not in Schenkl; no Greek to hand; from Crossley, checked against Long) |
| XXII | Gnom. 67 (Schweighäuser 88) |
| XXIII | Schweighäuser fr. 156 (not in Schenkl; no Greek to hand; from Crossley, checked against Long) |
| XXIV | Schweighäuser fr. 120 (not in Schenkl; no Greek to hand; from Crossley, checked against Long) |

### `book-10.json` · The Hymn of Cleanthes (4 paragraphs, 414 words)

| Stanza | Source |
|---|---|
| 1 | lines 1–6 |
| 2 | lines 7–14 |
| 3 | lines 15–29 |
| 4 | lines 30–37 |
