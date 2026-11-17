# Bhagavad Gita · verify · 2026-11-17

The Sanskrit is not bundled; every check was made against the Sanskrit from the verifier's own
knowledge, with Arnold (1885) as the comparison edition.

## Policies

Term sheet for the whole work. Patch entries in `patch.json` bring every section into line.

- **Yoga.** "Discipline" stays the running English for *yoga*, and "disciplined (soul)" for
  *yukta* / *yogin*. Use the name **Yoga**, capital Y, where the text defines or names the teaching:
  2.39, 2.48, 2.50 ("Yoga is skill in action"), 4.1–3, 6.23, 18.75, Sankhya-and-Yoga at 5.4–5,
  and *yogeśvara* = "the lord of Yoga" (11.4, 11.9, 18.75, 18.78). "Yogi" is a common noun,
  lower case. Mechanical (not patched one by one): lower-case "yoga" that names the teaching
  becomes "Yoga" (IV seg-0005 "practice of yoga", IV seg-0006 "discipline of yoga", VI seg-0001
  "the yoga of work", VI seg-0005 "what is meant by yoga").
- **The three gunas.** Always "the three qualities (of nature)", never "strands". The names are
  sattva, rajas, tamas, and their English is **goodness, passion, darkness**. The adjectives are
  sattvic, rajasic, tamasic. Tamas is never "ignorance": ignorance is what it is born of (14.8)
  and what it yields (14.16–17). Exception: in XVIII's threefold tables the sattvic kind stays
  "of light" ("the knowledge of light"), paired with "of passion" and "of darkness". 14.6 has
  just said that sattva gives light, and "the doer of goodness" would read as "do-gooder".
- **Brahman.** Wherever the Sanskrit has *brahman*, the text says Brahman: never "the eternal",
  "the sacred order" or "God". Brahma (the creator god) stays Brahma. 3.15, where *brahman* may
  mean the Veda, keeps "Brahman" too, as ambiguous as the Sanskrit.
- **brahmanirvāṇa.** Always "the nirvana of Brahman" (2.72, 5.24, 5.25, 5.26). Never "the peace
  of God", "the peace of Brahman", or "the great extinction". *nirvāṇa* alone (6.15) is "nirvana".
- **The Vedas.** *veda* and *śabdabrahman* are "the Vedas". "Scripture(s)" is kept only for
  *śāstra* (16.23–24, 17.1, 17.5, 17.24), where it is right.
- **Sankhya.** The name stays, with no gloss: never "analysis", "the way of knowledge" or
  "clear reflection" in place of the name (2.39, 5.4–5, 13.24, 18.13).
- **Other named things.** Vasudeva stays Vasudeva (7.19). Yakshas and Rakshasas are capitalized
  as in XI (10.23, 17.4). The Rudras are not the storm-gods (10.23). *ākāśa* / *kha* is
  "space", never "air" or "ether" (7.4, 7.8, 13.32). "brahmin" is lower case as in V, IX and
  XVIII. Mechanical: I seg-0003 "best of Brahmins" becomes "best of brahmins".

**Note for the editor.** `apply.py` patches the section text only. The `divergences` block in
`pipeline/modern/bhagavad-gita.json` still quotes the old wording and needs a hand pass after
the patch lands:
- 14.5–8 quotes "goodness, passion, and ignorance" and says its note glosses them that way.
- 7.8-9 quotes "the sound in air".
- 18.78 quotes "the lord of all discipline".
- 13.29-30 describes nature's "three strands".

## Rejected

No issue was rejected outright. Each reported issue held against the Sanskrit. Where the
reviewer's fix was changed, the reason is below.

- II seg-0019 (2.72): took "the nirvana of Brahman" alone, not "the stillness of Brahman, the nirvana of Brahman". The doubled phrase would itself be a gloss.
- II seg-0009 (2.24): the reviewer's "steady, immovable, eternal" ends on two near-synonyms after "unchanging". Used "steady, unmoving, everlasting" so *acala* and *sanātana* are both there without repetition.
- I seg-0005 (1.23): kept the edition's "ready" and "wicked-minded". Only the prepositions are fixed, because the segment already says "eager for battle".
- I seg-0004 (1.12): kept "eldest of the Kurus" and added "their grandsire" (*pitāmahaḥ*), instead of the reviewer's "old grandsire". That keeps the word "old" well away from the king's name.
- IV seg-0003 (4.8): used "I am born", not "I come into being". The same segment has just said "I bring myself into being" (4.7).
- XIV seg-0003 (14.6): kept the edition's "clear and untroubled" (*nirmala*, *anāmaya*) and only cut "brings health". The reviewer's "free of all affliction" rewrote more than the fix needed.
- XVIII seg-0013 (18.33): moved "unwavering" from the steadiness to the discipline, where *avyabhicāriṇī* belongs. The reviewer's fix left both.

## Finish (2026-11-17)

Done in `pipeline/modern/bhagavad-gita.json` after the patch was applied. Paragraph counts unchanged in all 18 sections; JSON formatting kept.

- **Yoga: 4 changes.** "yoga" naming the teaching became "Yoga" at IV seg-0005 ("the practice of Yoga"), IV seg-0006 ("the discipline of Yoga"), VI seg-0001 ("the Yoga of work") and VI seg-0005 ("what is meant by Yoga"). No lower-case "yoga" is left.
- **brahmin: 1 change.** I seg-0003 "best of Brahmins" became "best of brahmins". No capitalized "Brahmin" is left.
- **Other policies.** Carried by the patch entries; nothing mechanical remained.
- **Divergence notes rewritten: 11 of 60.** The four flagged above: 14.5–8 ("goodness, passion, and darkness", and why tamas is not "ignorance"), 7.8–9 ("the sound in space"), 18.78 ("the lord of Yoga"), 13.29–30 ("the three qualities"). The same check found seven more that quoted patched wording: 4.7–8 ("I am born"), 4.18 ("he is disciplined, even while he does every kind of work"), 8.12–13 ("the single syllable that is Brahman"), 11.32 ("I have come forth"), 12.8–12 (no "blind" practice), 13.1–2 (no "who watches over it") and 17.1–4 ("the Yakshas and Rakshasas").
- **Overview and introduction.** Neither describes a choice the patch reversed; no change.

Left for the editor: the pipeline build has not been run, and the edition's provenance does not yet record the revision.
