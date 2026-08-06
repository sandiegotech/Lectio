"""Curated collections — the library's shelves (BIBLE.md §3).

One corpus, many curations. Every shell work is defined ONCE in the WORKS registry
(title+author -> era, genre, note, cover). Each collection is a list of references
into it — so the same work can sit on several shelves with identical, drift-free
metadata, and the Lectio Collection is a literal curated pull from the big sets.

Two axes: kind="series" shelves (Lectio, the Great Books sets, Harvard, Beyond the
Collections) and kind="theme" source-only groupings whose books flow into the Genres axis.
"""
from __future__ import annotations

from .model import Collection, CollectionItem, PlannedWork

LECTIO_ALL = "collection.lectio"
RELIGION = "Religious Texts"

# The registry: every shell work, defined once. Key is (title, author).
WORKS = {
    ('A Discourse on Inequality', 'Jean-Jacques Rousseau'): {"era": '1755', "genre": 'Politics & Economics', "note": 'Rousseau on how society made men unequal — a seed of the French Revolution.', "cover": 'collections/book-covers/lectio-rousseau-discourse-on-inequality.jpg'},
    ("A Doll's House", 'Henrik Ibsen'): {"era": '1879', "genre": 'Drama', "note": "Ibsen's quiet bombshell — a wife walks out of her marriage, and the modern theater begins."},
    ('A Vindication of the Rights of Woman', 'Mary Wollstonecraft'): {"era": '1792', "genre": 'Politics & Economics', "note": 'The founding work of feminist thought — reason and education are not the property of men.', "cover": 'collections/book-covers/lectio-vindication-of-the-rights-of-woman.jpg'},
    ('American Historical Documents', ''): {"era": '1000–1904', "genre": 'History & Biography', "note": 'The charters and speeches that made a nation, 1000–1904.', "cover": 'collections/book-covers/lectio-american-historical-documents.jpg'},
    ('An Enquiry Concerning Human Understanding', 'David Hume'): {"era": '1748', "genre": 'Philosophy', "note": "Hume's elegant skepticism — cause, habit, and the limits of reason.", "cover": 'collections/book-covers/lectio-enquiry-concerning-human-understanding.jpg'},
    ('An Essay Concerning Human Understanding', 'John Locke'): {"era": '1689', "genre": 'Philosophy', "note": 'Locke on the mind as a blank slate — the foundation of empiricism.', "cover": 'collections/book-covers/lectio-essay-concerning-human-understanding.jpg'},
    ('Apology, Crito & Phaedo', 'Plato'): {"era": '399–387 BCE', "genre": 'Philosophy', "note": 'The trial, imprisonment, and death of Socrates — the founding drama of the examined life.', "cover": 'collections/book-covers/lectio-plato-apology-crito-phaedo.jpg', "originalCover": 'collections/book-covers/harvard-classics-red-plato-apology-crito-phaedo.jpg'},
    ('Areopagitica', 'John Milton'): {"era": '1644', "genre": 'Essays & Letters', "note": "Milton's classic defense of free speech and a free press, against censorship.", "cover": 'collections/book-covers/lectio-areopagitica.jpg'},
    ('Beyond Good and Evil', 'Friedrich Nietzsche'): {"era": '1886', "genre": 'Philosophy', "note": "Nietzsche's assault on inherited morality — and his demand that we create our own values."},
    ('Candide', 'Voltaire'): {"era": '1759', "genre": 'Fiction', "note": "Voltaire's lightning satire — innocence loose in a brutal world, and the case for tending one's garden.", "cover": 'collections/book-covers/lectio-candide.jpg'},
    ('Capital', 'Karl Marx'): {"era": '1867', "genre": 'Politics & Economics', "note": "Marx's anatomy of capitalism — labor, value, and the engine he believed would undo it.", "cover": 'collections/book-covers/lectio-capital.jpg'},
    ('Characteristics & Inaugural Address', 'Thomas Carlyle'): {"era": '1831–1866', "genre": 'Essays & Letters', "note": 'Carlyle, the Victorian prophet, on work, heroism, and the machine age.', "cover": 'collections/book-covers/lectio-characteristics-and-inaugural-address.jpg'},
    ('Chronicle and Romance', 'Froissart, Malory, Holinshed'): {"era": '1370–1580', "genre": 'History & Biography', "note": 'Froissart, Malory, and Holinshed — the chronicles and legends behind medieval England.', "cover": 'collections/book-covers/lectio-chronicle-and-romance.jpg'},
    ('Confessions', 'Saint Augustine'): {"era": '397–400 CE', "genre": 'Religion', "note": "Augustine's first true autobiography of a soul — sin, restlessness, and conversion, addressed to God.", "cover": 'collections/book-covers/lectio-confessions.jpg'},
    ('Democracy in America', 'Alexis de Tocqueville'): {"era": '1835–1840', "genre": 'History & Biography', "note": "Tocqueville's clear-eyed report on the young United States — democracy's promise and its perils.", "cover": 'collections/book-covers/lectio-democracy-in-america.jpg'},
    ('Discourse on Method', 'René Descartes'): {"era": '1637', "genre": 'Philosophy', "note": "Descartes founds modern philosophy on doubt — 'I think, therefore I am.'", "cover": 'collections/book-covers/lectio-discourse-on-method.jpg'},
    ('Doctor Faustus', 'Christopher Marlowe'): {"era": '1592', "genre": 'Drama', "note": "Marlowe's Elizabethan tragedy of forbidden knowledge and the bargain with the devil.", "cover": 'collections/book-covers/lectio-doctor-faustus.jpg'},
    ('Don Quixote', 'Miguel de Cervantes'): {"era": '1605–1615', "genre": 'Fiction', "note": 'The first modern novel, entire — a mad knight, his earthbound squire, and the comedy of ideals meeting the world.', "cover": 'collections/book-covers/lectio-don-quixote-part-i.jpg'},
    ('Dream of the Red Chamber', 'Cao Xueqin'): {'era': '1750–1791', 'genre': 'Fiction', 'note': 'The slow ruin of a great family seen through a doomed love — the subtlest of the Chinese novels.', 'cover': 'collections/book-covers/eastern-dream-of-the-red-chamber.jpg'},
    ('Elizabethan Drama I', 'Marlowe & Shakespeare'): {"era": '1590–1610', "genre": 'Drama', "note": 'Marlowe and Shakespeare — the birth of the English stage.'},
    ('Elizabethan Drama II', 'Jonson, Webster, Massinger & others'): {"era": '1600–1630', "genre": 'Drama', "note": 'Jonson, Webster, and the other masters of the Jacobean stage.'},
    ('English Essays: Sidney to Macaulay', ''): {"era": '1580–1840', "genre": 'Essays & Letters', "note": 'Four centuries of the English essay, Elizabethans to Victorians.', "cover": 'collections/book-covers/lectio-english-essays-sidney-to-macaulay.jpg'},
    ('English Poetry I: Chaucer to Gray', ''): {"era": '1370–1750', "genre": 'Poetry & Epic', "note": 'The first age of English verse, Chaucer through the eighteenth century.', "cover": 'collections/book-covers/lectio-english-poetry-i-chaucer-to-gray.jpg'},
    ('English Poetry II: Collins to Fitzgerald', ''): {"era": '1745–1860', "genre": 'Poetry & Epic', "note": 'The Romantic century of English poetry.', "cover": 'collections/book-covers/lectio-english-poetry-ii-collins-to-fitzgerald.jpg'},
    ('English Poetry III: Tennyson to Whitman', ''): {"era": '1830–1892', "genre": 'Poetry & Epic', "note": 'The Victorians and the first American voices.', "cover": 'collections/book-covers/lectio-english-poetry-iii-tennyson-to-whitman.jpg'},
    ('Epic and Saga', 'Beowulf, Roland, the Nibelungenlied'): {"era": '700–1300', "genre": 'Poetry & Epic', "note": 'Beowulf, the Song of Roland, and the Nibelungenlied — the epics of the North.'},
    ('Essays & English Traits', 'Ralph Waldo Emerson'): {"era": '1841–1856', "genre": 'Essays & Letters', "note": "American self-reliance and the transcendentalist vision, in Emerson's founding essays.", "cover": 'collections/book-covers/lectio-essays-and-english-traits.jpg'},
    ('Essays in Idleness', 'Yoshida Kenkō'): {'era': '1330–1332', 'genre': 'Essays & Letters', 'note': "Kenkō's reflections of a recluse monk — the classic of Japanese taste and the beauty of transience.", 'cover': 'collections/book-covers/eastern-essays-in-idleness.jpg'},
    ('Essays, Civil and Moral', 'Francis Bacon'): {"era": '1597–1625', "genre": 'Essays & Letters', "note": 'The first great English essays — worldly, compressed wisdom on work, fortune, and friendship.', "cover": 'collections/book-covers/lectio-essays-civil-and-moral.jpg'},
    ('Essays: English and American', ''): {"era": '1600–1900', "genre": 'Essays & Letters', "note": 'A gathering of the finest shorter prose on either side of the Atlantic.', "cover": 'collections/book-covers/lectio-essays-english-and-american.jpg'},
    ('Ethics', 'Baruch Spinoza'): {"era": '1677', "genre": 'Philosophy', "note": 'Spinoza proves a philosophy like geometry — God, nature, and freedom as one necessary order.', "cover": 'collections/book-covers/lectio-ethics-spinoza.jpg'},
    ('Eugene Onegin', 'Alexander Pushkin'): {"era": '1833', "genre": 'Poetry & Epic', "note": "Russia's beloved novel in verse — and the fountainhead of its entire literature.", "cover": 'collections/book-covers/lectio-eugene-onegin.jpg'},
    ('Faust', 'Johann Wolfgang von Goethe'): {"era": '1808–1832', "genre": 'Drama', "note": "Goethe's supreme drama — the scholar who wagers his soul for the whole of human experience.", "cover": 'collections/book-covers/lectio-faust-goethe.jpg'},
    ('Fear and Trembling', 'Søren Kierkegaard'): {"era": '1843', "genre": 'Philosophy', "note": 'Kierkegaard on Abraham and the leap of faith — the birth of existential thought.', "cover": 'collections/book-covers/lectio-fear-and-trembling.jpg'},
    ('Folklore and Fable', 'Aesop, Grimm & Andersen'): {"era": '600 BCE–1850', "genre": 'Fiction', "note": 'Aesop, Grimm, and Andersen — the fables and fairy tales that raised the West.', "cover": 'collections/book-covers/lectio-folklore-and-fable.jpg'},
    ('Frankenstein', 'Mary Shelley'): {"era": '1818', "genre": 'Fiction', "note": 'A teenager invents science fiction — the creature, its maker, and the terror of what we make.', "cover": 'collections/book-covers/lectio-frankenstein.jpg'},
    ('Fruits of Solitude', 'William Penn'): {"era": '1693', "genre": 'Essays & Letters', "note": 'Aphorisms on living well from William Penn, founder of Pennsylvania.', "cover": 'collections/book-covers/lectio-penn-fruits-of-solitude.jpg', "originalCover": 'collections/book-covers/harvard-classics-red-penn-fruits-of-solitude.jpg'},
    ('Gargantua and Pantagruel', 'François Rabelais'): {"era": '1532–1564', "genre": 'Fiction', "note": "Rabelais's giant, riotous satire — learning and appetite, the body and the book, in full Renaissance laughter.", "cover": 'collections/book-covers/lectio-gargantua-and-pantagruel.jpg'},
    ('Genesis', 'The Bible'): {"era": '1200–500 BCE', "genre": 'Religion', "note": "The Bible's first book — creation, the fall, the flood, and the patriarchs."},
    ('Gitanjali', 'Rabindranath Tagore'): {'era': '1910', 'genre': 'Poetry & Epic', 'note': "Tagore's song-offerings — the lyric devotion that brought India its first Nobel in literature.", 'cover': 'collections/book-covers/eastern-gitanjali.jpg'},
    ('Great Expectations', 'Charles Dickens'): {"era": '1861', "genre": 'Fiction', "note": "Dickens's masterpiece of self-deception — a poor boy, a secret fortune, and the cost of becoming a gentleman.", "cover": 'collections/book-covers/lectio-great-expectations.jpg'},
    ("Gulliver's Travels", 'Jonathan Swift'): {"era": '1726', "genre": 'Fiction', "note": "Swift's voyages to impossible lands — the sharpest satire of human folly ever written.", "cover": 'collections/book-covers/lectio-gullivers-travels.jpg'},
    ('Hamlet', 'William Shakespeare'): {"era": '1600–1601', "genre": 'Drama', "note": "Shakespeare's deepest tragedy — a prince, a murder, and the paralysis of thought."},
    ('Heart of Darkness', 'Joseph Conrad'): {"era": '1899', "genre": 'Fiction', "note": "Conrad's voyage up the Congo into the heart of empire — and of human darkness."},
    ('History of the Peloponnesian War', 'Thucydides'): {"era": '400 BCE', "genre": 'History & Biography', "note": 'Thucydides on the war that broke Athens — history written cold, as a possession for all time.', "cover": 'collections/book-covers/lectio-history-of-the-peloponnesian-war.jpg'},
    ('In Praise of Folly', 'Erasmus'): {"era": '1511', "genre": 'Essays & Letters', "note": 'Erasmus lets Folly praise herself — the witty satire that lit the fuse of the Reformation.', "cover": 'collections/book-covers/lectio-in-praise-of-folly.jpg'},
    ('In Search of Lost Time', 'Marcel Proust'): {"era": '1913–1927', "genre": 'Fiction', "note": 'Memory, time, and a taste of cake — the longest and deepest novel of the modern age.', "cover": 'collections/book-covers/lectio-in-search-of-lost-time.jpg'},
    ('Jane Eyre', 'Charlotte Brontë'): {"era": '1847', "genre": 'Fiction', "note": 'A governess who will not be owned — the novel that gave the heroine her own fierce voice.', "cover": 'collections/book-covers/lectio-jane-eyre.jpg'},
    ('Journal', 'John Woolman'): {"era": '1774', "genre": 'History & Biography', "note": 'The inner life of a Quaker conscience — an early, searching American voice against slavery.', "cover": 'collections/book-covers/lectio-woolman-journal.jpg', "originalCover": 'collections/book-covers/harvard-classics-red-woolman-journal.jpg'},
    ('Journey to the West', "Wu Cheng'en"): {'era': '1592', 'genre': 'Fiction', 'note': "The Monkey King escorts a monk to fetch the scriptures — China's beloved comic-spiritual epic.", 'cover': 'collections/book-covers/eastern-journey-to-the-west.jpg'},
    ('Layla and Majnun', 'Nizami'): {'era': '1192', 'genre': 'Poetry & Epic', 'note': "Nizami's tragic romance — the lover driven mad by love, the East's Romeo and Juliet.", 'cover': 'collections/book-covers/eastern-layla-and-majnun.jpg'},
    ('Leaves of Grass', 'Walt Whitman'): {"era": '1855', "genre": 'Poetry & Epic', "note": 'Whitman sings America and himself — the barbaric yawp that remade what a poem could be.', "cover": 'collections/book-covers/lectio-leaves-of-grass.jpg'},
    ('Les Misérables', 'Victor Hugo'): {"era": '1862', "genre": 'Fiction', "note": "An ex-convict's long redemption against the barricades of Paris — the great novel of mercy and justice.", "cover": 'collections/book-covers/lectio-les-miserables.jpg'},
    ('Letters', 'Pliny the Younger'): {"era": '100–112 CE', "genre": 'Essays & Letters', "note": 'Vivid letters from the Roman world — including the eyewitness account of Vesuvius.', "cover": 'collections/book-covers/lectio-letters.jpg'},
    ('Letters on England', 'Voltaire'): {"era": '1733', "genre": 'Essays & Letters', "note": "Voltaire's witty letters carrying English liberty and science to France.", "cover": 'collections/book-covers/lectio-letters-on-england.jpg'},
    ('Leviathan', 'Thomas Hobbes'): {"era": '1651', "genre": 'Politics & Economics', "note": "Hobbes on the state of nature and the social contract — life without authority, 'nasty, brutish, and short.'", "cover": 'collections/book-covers/lectio-hobbes-of-man-leviathan.jpg'},
    ('Literary and Philosophical Essays', 'Montaigne, Sainte-Beuve, Renan'): {"era": '1580–1900', "genre": 'Essays & Letters', "note": 'Montaigne, Sainte-Beuve, Renan and others — the Continental art of the essay.', "cover": 'collections/book-covers/lectio-literary-and-philosophical-essays.jpg'},
    ('Lives', 'Plutarch'): {"era": '100–120 CE', "genre": 'History & Biography', "note": "Plutarch's paired lives of Greeks and Romans that taught Europe what greatness looks like.", "cover": 'collections/book-covers/lectio-lives.jpg'},
    ('Lyrical Ballads', 'Wordsworth & Coleridge'): {"era": '1798', "genre": 'Poetry & Epic', "note": 'The book that began English Romanticism — ordinary life and the rime of the ancient mariner.', "cover": 'collections/book-covers/lectio-lyrical-ballads.jpg'},
    ('Madame Bovary', 'Gustave Flaubert'): {"era": '1857', "genre": 'Fiction', "note": 'A provincial wife dreams beyond her life — the novel that made prose an exact art.', "cover": 'collections/book-covers/lectio-madame-bovary.jpg'},
    ('Metamorphoses', 'Ovid'): {"era": '8 CE', "genre": 'Poetry & Epic', "note": "Ovid's endlessly inventive epic of transformation — the myths the whole West would draw on forever.", "cover": 'collections/book-covers/lectio-metamorphoses.jpg'},
    ('Middlemarch', 'George Eliot'): {"era": '1871–1872', "genre": 'Fiction', "note": "George Eliot's study of a provincial town — the grandest English novel of ordinary lives and thwarted hopes."},
    ('Moby-Dick', 'Herman Melville'): {"era": '1851', "genre": 'Fiction', "note": "Melville's white whale — an American epic of obsession, the sea, and the unknowable.", "cover": 'collections/book-covers/lectio-moby-dick.jpg'},
    ('Mrs Dalloway', 'Virginia Woolf'): {"era": '1925', "genre": 'Fiction', "note": 'One London day inside many minds — Woolf remakes the novel as the flow of consciousness.', "cover": 'collections/book-covers/lectio-mrs-dalloway.jpg'},
    ('Narrative of the Life of Frederick Douglass', 'Frederick Douglass'): {"era": '1845', "genre": 'History & Biography', "note": 'The escaped slave who wrote his own freedom — the most powerful American memoir of the century.', "cover": 'collections/book-covers/lectio-narrative-of-the-life-of-frederick-douglass.jpg'},
    ('Nicomachean Ethics', 'Aristotle'): {"era": '340 BCE', "genre": 'Philosophy', "note": "Aristotle on virtue and the good life — happiness as the soul's activity in excellence.", "cover": 'collections/book-covers/lectio-nicomachean-ethics.jpg'},
    ('Nine Greek Dramas', 'Aeschylus, Sophocles, Euripides, Aristophanes'): {"era": '472–405 BCE', "genre": 'Drama', "note": 'The masterpieces of Athenian tragedy and comedy — Aeschylus, Sophocles, Euripides, Aristophanes.', "cover": 'collections/book-covers/lectio-nine-greek-dramas.jpg'},
    ('Ninety-Five Theses & Addresses', 'Martin Luther'): {"era": '1517–1520', "genre": 'Religion', "note": "The spark of the Reformation and Luther's founding manifestos.", "cover": 'collections/book-covers/lectio-ninety-five-theses-and-addresses.jpg'},
    ('On Friendship & On Old Age', 'Cicero'): {"era": '44 BCE', "genre": 'Philosophy', "note": "Cicero's wise essays on the goods that ripen with age.", "cover": 'collections/book-covers/lectio-on-friendship-and-on-old-age.jpg'},
    ('On Liberty', 'John Stuart Mill'): {"era": '1859', "genre": 'Politics & Economics', "note": "Mill's classic argument for individual freedom against the tyranny of the majority.", "cover": 'collections/book-covers/lectio-on-liberty.jpg'},
    ('On the Art of the Noh Drama', 'Zeami'): {'era': '1400–1420', 'genre': 'Drama', 'note': "Zeami's secret teachings on Noh — the deepest meditation on acting before the modern age.", 'cover': 'collections/book-covers/eastern-art-of-the-noh-drama.jpg'},
    ('On the Motion of the Heart and Blood', 'William Harvey'): {"era": '1628', "genre": 'Science & Mathematics', "note": 'Harvey discovers the circulation of the blood — the birth of modern physiology.', "cover": 'collections/book-covers/lectio-on-the-motion-of-the-heart-and-blood.jpg'},
    ('On the Nature of Things', 'Lucretius'): {"era": '50 BCE', "genre": 'Philosophy', "note": 'Lucretius sets the whole universe in verse — atoms, mortality, and freedom from the fear of death.', "cover": 'collections/book-covers/lectio-on-the-nature-of-things.jpg'},
    ('On the Revolutions of the Heavenly Spheres', 'Nicolaus Copernicus'): {"era": '1543', "genre": 'Science & Mathematics', "note": 'Copernicus moves the earth — the book that began the scientific revolution.', "cover": 'collections/book-covers/lectio-on-the-revolutions-of-the-heavenly-spheres.jpg'},
    ('One Thousand and One Nights', ''): {"era": '800–1400', "genre": 'Fiction', "note": "Scheherazade's treasury of tales — the wellspring of the frame narrative.", "cover": 'collections/book-covers/lectio-thousand-and-one-nights.jpg'},
    ('Paradise Lost', 'John Milton'): {"era": '1667', "genre": 'Poetry & Epic', "note": "Milton's English epic of the fall — Satan, Eden, and the ways of God to men.", "cover": 'collections/book-covers/lectio-paradise-lost.jpg'},
    ('Pensées', 'Blaise Pascal'): {"era": '1670', "genre": 'Philosophy', "note": "Pascal's fragments on faith and doubt — the wager, the abyss, and the thinking reed.", "cover": 'collections/book-covers/lectio-pensees.jpg'},
    ('Poems & The Reply to Sor Filotea', 'Sor Juana Inés de la Cruz'): {"era": '1690', "genre": 'Poetry & Epic', "note": "The brilliant nun of colonial Mexico — and her fierce defense of a woman's right to learn.", "cover": 'collections/book-covers/lectio-poems-and-the-reply-to-sor-filotea.jpg'},
    ('Poems and Songs', 'Robert Burns'): {"era": '1786–1796', "genre": 'Poetry & Epic', "note": "Scotland's national poet — love, drink, and democratic feeling in living dialect.", "cover": 'collections/book-covers/lectio-poems-and-songs.jpg'},
    ('Prefaces and Prologues', ''): {"era": '1580–1900', "genre": 'Essays & Letters', "note": 'Great writers introducing their own work — the craft of literature in its own words.', "cover": 'collections/book-covers/lectio-prefaces-and-prologues.jpg'},
    ('Pride and Prejudice', 'Jane Austen'): {"era": '1813', "genre": 'Fiction', "note": "Austen's perfect comedy of manners — wit, money, and the slow education of the heart.", "cover": 'collections/book-covers/lectio-pride-and-prejudice.jpg'},
    ('Principles of Human Knowledge', 'George Berkeley'): {"era": '1710', "genre": 'Philosophy', "note": "Berkeley's startling case that to be is to be perceived.", "cover": 'collections/book-covers/lectio-principles-of-human-knowledge.jpg'},
    ('Records of the Grand Historian', 'Sima Qian'): {'era': '145–86 BCE', 'genre': 'History & Biography', 'note': 'The founding work of Chinese history, whose author chose disgrace over death to finish it.', 'cover': 'collections/book-covers/eastern-records-of-the-grand-historian.jpg'},
    ('Reflections on the Revolution in France', 'Edmund Burke'): {"era": '1790', "genre": 'Politics & Economics', "note": 'The founding text of modern conservatism — order, tradition, and the danger of abstraction.', "cover": 'collections/book-covers/lectio-reflections-on-the-revolution-in-france.jpg'},
    ('Religio Medici', 'Sir Thomas Browne'): {"era": '1643', "genre": 'Religion', "note": "A physician's eloquent meditation on faith, doubt, and the mysteries of the self.", "cover": 'collections/book-covers/lectio-religio-medici.jpg'},
    ('Robinson Crusoe', 'Daniel Defoe'): {"era": '1719', "genre": 'Fiction', "note": 'The castaway who built a world from nothing — often called the first English novel.', "cover": 'collections/book-covers/lectio-robinson-crusoe.jpg'},
    ('Romance of the Three Kingdoms', 'Luo Guanzhong'): {'era': '1321–1400', 'genre': 'Fiction', 'note': "China's great historical epic — war, loyalty, and strategy in the empire's collapse.", 'cover': 'collections/book-covers/eastern-romance-of-the-three-kingdoms.jpg'},
    ('Sacred Writings I', 'Confucian, Hebrew, Christian'): {"era": '1000 BCE–100 CE', "genre": 'Religion', "note": 'Confucian, Hebrew, and Christian scripture, set side by side.', "cover": 'collections/book-covers/lectio-sacred-writings-i.jpg'},
    ('Sacred Writings II', 'Buddhist, Hindu, Mohammedan'): {"era": '500 BCE–650 CE', "genre": 'Religion', "note": 'Buddhist, Hindu, and Muslim scripture, set side by side.', "cover": 'collections/book-covers/lectio-sacred-writings-ii.jpg'},
    ('Scientific Papers: Physics & Chemistry', 'Faraday, Helmholtz, Kelvin & others'): {"era": '1800–1900', "genre": 'Science & Mathematics', "note": 'Landmark papers of physics and chemistry, in the words of their discoverers.', "cover": 'collections/book-covers/lectio-scientific-papers-faraday-helmholtz-kelvin.jpg'},
    ('Scientific Papers: Medicine & Biology', 'Harvey, Jenner, Lister, Pasteur'): {"era": '1628–1878', "genre": 'Science & Mathematics', "note": 'The papers that founded modern medicine — circulation, vaccination, antisepsis, germs.', "cover": 'collections/book-covers/lectio-scientific-papers-harvey-jenner-lister-pasteur.jpg'},
    ('Songs of Innocence and of Experience', 'William Blake'): {"era": '1789–1794', "genre": 'Poetry & Epic', "note": "Blake's visionary lyrics — the lamb and the tiger, innocence and its loss, in poems and his own engravings.", "cover": 'collections/book-covers/lectio-songs-of-innocence-and-of-experience.jpg'},
    ('Summa Theologica', 'Thomas Aquinas'): {"era": '1265–1274', "genre": 'Religion', "note": "Aquinas's towering synthesis of faith and reason — medieval theology's masterwork.", "cover": 'collections/book-covers/lectio-summa-theologica.jpg'},
    ('Tartuffe & The Misanthrope', 'Molière'): {"era": '1664–1666', "genre": 'Drama', "note": 'The master of French comedy — hypocrisy and honesty skewered with perfect timing.', "cover": 'collections/book-covers/lectio-tartuffe-and-the-misanthrope.jpg'},
    ('The Adventures of Huckleberry Finn', 'Mark Twain'): {"era": '1884', "genre": 'Fiction', "note": "Twain's runaway boy and a freedom-seeking man on a raft — the great American novel of conscience."},
    ('The Almagest', 'Ptolemy'): {"era": '150 CE', "genre": 'Science & Mathematics', "note": "Ptolemy's astronomy — the earth-centered cosmos that ruled the Western mind for fourteen centuries.", "cover": 'collections/book-covers/lectio-the-almagest.jpg'},
    ('The Analects', 'Confucius'): {'era': '551–479 BCE', 'genre': 'Philosophy', 'note': 'The ground text of East Asian ethics — becoming fully human through ritual, learning, and human-heartedness.', 'cover': 'collections/book-covers/eastern-analects.jpg'},
    ('The Annals', 'Tacitus'): {"era": '110–120 CE', "genre": 'History & Biography', "note": 'Tacitus on the early Roman emperors — power, fear, and corruption, in the most unsparing prose of antiquity.', "cover": 'collections/book-covers/lectio-the-annals.jpg'},
    ('The Art of War', 'Sun Tzu'): {'era': '500–401 BCE', 'genre': 'Politics & Economics', 'note': 'Thirteen chapters: the supreme excellence is to win without fighting, and every battle is decided before it is joined.', 'cover': 'collections/book-covers/eastern-art-of-war.jpg'},
    ('The Arthashastra', 'Kautilya'): {'era': '300 BCE–100 CE', 'genre': 'Politics & Economics', 'note': "Kautilya's unsparing manual of statecraft and power — India's answer to Machiavelli, written far earlier.", 'cover': 'collections/book-covers/eastern-arthashastra.jpg'},
    ('The Autobiography of Benjamin Franklin', 'Benjamin Franklin'): {"era": '1771–1790', "genre": 'History & Biography', "note": 'The model American life, told by the man who invented himself — printer, scientist, statesman.', "cover": 'collections/book-covers/lectio-franklin-autobiography.jpg', "originalCover": 'collections/book-covers/harvard-classics-red-franklin-autobiography.jpg'},
    ('The Autobiography of Benvenuto Cellini', 'Benvenuto Cellini'): {"era": '1558–1563', "genre": 'History & Biography', "note": 'The swaggering memoir of a Renaissance goldsmith — art, brawls, and bravado.', "cover": 'collections/book-covers/lectio-cellini-autobiography.jpg'},
    ('The Betrothed', 'Alessandro Manzoni'): {"era": '1827', "genre": 'Fiction', "note": "Italy's great historical novel — two lovers kept apart by power and plague.", "cover": 'collections/book-covers/lectio-the-betrothed.jpg'},
    ('The Bhagavad Gita', ''): {"era": '200–101 BCE', "genre": 'Religion', "note": 'On the eve of battle a warrior refuses to fight; a god answers him — act without grasping at the fruit of action.', "cover": 'collections/book-covers/eastern-bhagavad-gita.jpg'},
    ('The Book of Five Rings & Hagakure', 'Musashi & Tsunetomo'): {'era': '1645 & 1716', 'genre': 'Philosophy', 'note': "The way of the warrior from two sides — a duelist's strategy and a samurai's meditations on death.", 'cover': 'collections/book-covers/eastern-book-of-five-rings-hagakure.jpg'},
    ('The Book of Songs', 'Anonymous'): {'era': '1000–600 BCE', 'genre': 'Poetry & Epic', 'note': "China's oldest poetry — three hundred ancient odes and folk songs, edited, by tradition, by Confucius.", 'cover': 'collections/book-covers/eastern-book-of-songs.jpg'},
    ('The Brothers Karamazov', 'Fyodor Dostoevsky'): {"era": '1880', "genre": 'Fiction', "note": "Dostoevsky's final novel — a murder, three brothers, and the deepest argument in fiction over God and freedom."},
    ('The Canon of Medicine', 'Avicenna'): {'era': '1025', 'genre': 'Science & Mathematics', 'note': "Avicenna's encyclopedia of medicine — the standard text in East and West for six hundred years.", 'cover': 'collections/book-covers/eastern-canon-of-medicine.jpg'},
    ('The Canterbury Tales', 'Geoffrey Chaucer'): {"era": '1387–1400', "genre": 'Poetry & Epic', "note": "Chaucer's pilgrims trade stories on the road to Canterbury — the founding comedy of English literature.", "cover": 'collections/book-covers/lectio-the-canterbury-tales.jpg'},
    ('The City of God', 'Saint Augustine'): {"era": '413–426 CE', "genre": 'Religion', "note": 'Written as Rome fell — the eternal city of God set against the earthly city of men.', "cover": 'collections/book-covers/lectio-the-city-of-god.jpg'},
    ('The Code of Hammurabi', 'Babylon'): {'era': '1754 BCE', 'genre': 'Politics & Economics', 'note': 'The oldest great code of law — an eye for an eye, carved in stone four thousand years ago.', 'cover': 'collections/book-covers/eastern-code-of-hammurabi.jpg'},
    ('The Complete English Poems', 'John Milton'): {"era": '1645–1671', "genre": 'Poetry & Epic', "note": 'Paradise Lost and the shorter poems — the height of English epic and lyric.', "cover": 'collections/book-covers/lectio-the-complete-english-poems.jpg'},
    ('The Conference of the Birds', 'Attar'): {'era': '1177', 'genre': 'Poetry & Epic', 'note': "Attar's Sufi allegory — the birds journey to find their king and discover themselves.", 'cover': 'collections/book-covers/eastern-conference-of-the-birds.jpg'},
    ('The Consolation of Philosophy', 'Boethius'): {"era": '524 CE', "genre": 'Philosophy', "note": 'Awaiting execution, Boethius is visited by Philosophy herself — the most read book of the Middle Ages after the Bible.', "cover": 'collections/book-covers/lectio-consolation-of-philosophy.jpg'},
    ('The Critique of Pure Reason', 'Immanuel Kant'): {"era": '1781', "genre": 'Philosophy', "note": 'Kant remakes philosophy — what the mind can know, and the limits it cannot cross.', "cover": 'collections/book-covers/lectio-the-critique-of-pure-reason.jpg'},
    ('The Decameron', 'Giovanni Boccaccio'): {"era": '1353', "genre": 'Fiction', "note": 'A hundred tales told by ten young Florentines fleeing the plague — the birth of European prose fiction.', "cover": 'collections/book-covers/lectio-decameron.jpg'},
    ('The Decisive Treatise', 'Averroes'): {'era': '1180', 'genre': 'Philosophy', 'note': 'Averroes argues that philosophy and revelation, rightly read, cannot conflict — the book that taught Europe Aristotle.', 'cover': 'collections/book-covers/eastern-decisive-treatise.jpg'},
    ('The Decline and Fall of the Roman Empire', 'Edward Gibbon'): {"era": '1776–1789', "genre": 'History & Biography', "note": "Gibbon's vast, ironic chronicle of how the greatest empire of antiquity came undone.", "cover": 'collections/book-covers/lectio-the-decline-and-fall-of-the-roman-empire.jpg'},
    ('The Dhammapada', 'Early Buddhist tradition'): {'era': '300–201 BCE', 'genre': 'Religion', 'note': "The Buddha's path at its plainest: the mind makes the world, craving makes the suffering, and a way out exists.", 'cover': 'collections/book-covers/eastern-dhammapada.jpg'},
    ('The Divan', 'Hafez'): {'era': '1320–1390', 'genre': 'Poetry & Epic', 'note': "Hafez's ghazals — wine, love, and the divine entwined in the most cherished poetry of Iran.", 'cover': 'collections/book-covers/eastern-divan.jpg'},
    ('The Divine Comedy', 'Dante Alighieri'): {"era": '1308–1320', "genre": 'Poetry & Epic', "note": "Dante's journey through Hell, Purgatory, and Paradise — the summit of the medieval imagination.", "cover": 'collections/book-covers/lectio-the-divine-comedy.jpg'},
    ('The Doctrine of the Mean', 'Attributed to Zisi'): {'era': '400 BCE', 'genre': 'Philosophy', 'note': 'One of the Confucian Four Books — the path of balance and sincerity at the still center of all things.', 'cover': 'collections/book-covers/eastern-doctrine-of-the-mean.jpg'},
    ('The Egyptian Book of the Dead', 'Anonymous · Egypt'): {'era': '1550–1070 BCE', 'genre': 'Religion', 'note': "Spells to guide the soul through the underworld — Egypt's map of death and judgment.", 'cover': 'collections/book-covers/eastern-egyptian-book-of-the-dead.jpg'},
    ('The Elements', 'Euclid'): {"era": '300 BCE', "genre": 'Science & Mathematics', "note": "Euclid's geometry — the model of reasoning from first principles that every later science would imitate.", "cover": 'collections/book-covers/lectio-the-elements.jpg'},
    ('The Enneads', 'Plotinus'): {"era": '250–270 CE', "genre": 'Philosophy', "note": "Plotinus and the last great vision of pagan philosophy — the soul's ascent toward the One.", "cover": 'collections/book-covers/lectio-the-enneads.jpg'},
    ('The Enuma Elish', 'Babylon'): {'era': '1200–1100 BCE', 'genre': 'Religion', 'note': 'The Babylonian creation epic — the world made from the body of a slain god.', 'cover': 'collections/book-covers/eastern-enuma-elish.jpg'},
    ('The Epic of Gilgamesh', 'Anonymous · Sumer & Akkad'): {'era': '2100–1200 BCE', 'genre': 'Poetry & Epic', 'note': 'The oldest surviving epic: a king loses his friend, refuses his own death, and comes home wiser — the root beneath East and West.', 'cover': 'collections/book-covers/eastern-gilgamesh.jpg'},
    ('The Essays', 'Michel de Montaigne'): {"era": '1580', "genre": 'Essays & Letters', "note": 'Montaigne invents the essay to study one subject without end — himself — and so discovers all of us.', "cover": 'collections/book-covers/lectio-the-essays-montaigne.jpg'},
    ('The Federalist Papers', 'Hamilton, Madison & Jay'): {"era": '1788', "genre": 'Politics & Economics', "note": 'The argument for the American Constitution — the finest writing on how a free republic actually works.', "cover": 'collections/book-covers/lectio-the-federalist-papers.jpg'},
    ('The Gita Govinda', 'Jayadeva'): {'era': '1200', 'genre': 'Poetry & Epic', 'note': "Jayadeva's rapturous song of Krishna and Radha — devotion sung as love poetry.", 'cover': 'collections/book-covers/eastern-gita-govinda.jpg'},
    ('The Golden Sayings', 'Epictetus'): {"era": '108 CE', "genre": 'Philosophy', "note": 'The Stoic handbook of the slave-philosopher: master what is yours, accept what is not.', "cover": 'collections/book-covers/lectio-epictetus-golden-sayings.jpg', "originalCover": 'collections/book-covers/harvard-classics-red-epictetus-golden-sayings.jpg'},
    ('The Greek Tragedies', 'Aeschylus, Sophocles & Euripides'): {"era": '472–405 BCE', "genre": 'Drama', "note": 'The masterpieces of the Athenian stage — Aeschylus, Sophocles, and Euripides on fate, the gods, and the cost of pride.', "cover": 'collections/book-covers/lectio-the-greek-tragedies.jpg'},
    ('The Gulistan', 'Saadi'): {'era': '1258', 'genre': 'Poetry & Epic', 'note': "Saadi's 'Rose Garden' — wise, witty tales and verse on how to live, the most read book in the Persian world.", 'cover': 'collections/book-covers/eastern-gulistan.jpg'},
    ('The Hadith', ''): {"era": '700–900 CE', "genre": 'Religion', "note": "The recorded sayings and deeds of the Prophet Muhammad — Islam's second source after the Qur'an.", "cover": 'collections/book-covers/eastern-hadith.jpg'},
    ('The Han Feizi', 'Han Fei'): {'era': '280–233 BCE', 'genre': 'Politics & Economics', 'note': 'The masterwork of Legalism — order through law and power, the philosophy that unified China.', 'cover': 'collections/book-covers/eastern-han-feizi.jpg'},
    ('The Histories', 'Herodotus'): {"era": '440 BCE', "genre": 'History & Biography', "note": 'The first work of history — Herodotus on the war between Greece and Persia, and everything he learned along the way.', "cover": 'collections/book-covers/lectio-the-histories.jpg'},
    ('The Holy Bible', 'King James Version'): {"era": '1200 BCE–100 CE', "genre": 'Religion', "note": 'The scriptures of Judaism and Christianity, whole — law, poetry, prophecy, and gospel.'},
    ('The I Ching', 'Anonymous'): {'era': '800–200 BCE', 'genre': 'Philosophy', 'note': 'The Book of Changes — the oracle and cosmology at the root of Chinese thought.', 'cover': 'collections/book-covers/eastern-i-ching.jpg'},
    ('The Imitation of Christ', 'Thomas à Kempis'): {"era": '1418–1427', "genre": 'Religion', "note": 'The most read Christian devotional after the Bible — humility and the inner life.', "cover": 'collections/book-covers/lectio-the-imitation-of-christ.jpg'},
    ('The Interpretation of Dreams', 'Sigmund Freud'): {"era": '1899', "genre": 'Science & Mathematics', "note": 'Freud opens the unconscious — dreams as the royal road to the hidden mind.'},
    ('The Kama Sutra', 'Vatsyayana'): {'era': '200–300 CE', 'genre': 'Philosophy', 'note': "Far more than its reputation — Vatsyayana's classical treatise on desire, love, and the art of living well.", 'cover': 'collections/book-covers/eastern-kama-sutra.jpg'},
    ('The Kojiki', 'Ō no Yasumaro'): {'era': '712', 'genre': 'History & Biography', 'note': "Japan's oldest book — the myths of the gods and the origins of the islands and their emperors.", 'cover': 'collections/book-covers/eastern-kojiki.jpg'},
    ('The Kokinshu', 'Compiled'): {'era': '905', 'genre': 'Poetry & Epic', 'note': "The first imperial anthology of Japanese verse — the collection that fixed the nation's taste for a thousand years.", 'cover': 'collections/book-covers/eastern-kokinshu.jpg'},
    ('The Lives of Donne and Herbert', 'Izaak Walton'): {"era": '1640–1670', "genre": 'History & Biography', "note": "Izaak Walton's tender biographies of two English poet-priests.", "cover": 'collections/book-covers/lectio-the-lives-of-donne-and-herbert.jpg'},
    ('The Lotus Sutra', 'Mahayana Buddhist tradition'): {'era': '100–200 CE', 'genre': 'Religion', 'note': 'The central scripture of Mahayana Buddhism — the promise that all beings may awaken.', 'cover': 'collections/book-covers/eastern-lotus-sutra.jpg'},
    ('The Mahabharata', 'Attributed to Vyasa'): {'era': '400 BCE–400 CE', 'genre': 'Poetry & Epic', 'note': 'The longest epic ever composed — a war between cousins that swells to hold the whole of dharma and its ambiguities.', 'cover': 'collections/book-covers/eastern-mahabharata.jpg'},
    ('The Manyoshu', 'Compiled'): {'era': '759', 'genre': 'Poetry & Epic', 'note': 'The first great anthology of Japanese poetry — ten thousand leaves, from emperors to frontier guards.', 'cover': 'collections/book-covers/eastern-manyoshu.jpg'},
    ('The Maqamat', 'Al-Hariri'): {'era': '1100–1110', 'genre': 'Fiction', 'note': "Al-Hariri's dazzling tales of a silver-tongued rogue — the showpiece of classical Arabic prose.", 'cover': 'collections/book-covers/eastern-maqamat.jpg'},
    ('The Masnavi', 'Rumi'): {'era': '1258–1273', 'genre': 'Poetry & Epic', 'note': "Rumi's vast spiritual epic — called 'the Quran in Persian,' the summit of Sufi poetry.", 'cover': 'collections/book-covers/eastern-masnavi.jpg'},
    ('The Mencius', 'Mencius'): {'era': '300–250 BCE', 'genre': 'Philosophy', 'note': "The 'second sage' of Confucianism — human nature is good, and a ruler governs by virtue or not at all.", 'cover': 'collections/book-covers/eastern-mencius.jpg'},
    ('The Mozi', 'Mozi'): {'era': '470–391 BCE', 'genre': 'Philosophy', 'note': "Mozi's case against Confucius — impartial love, plain living, and the first logic in China.", 'cover': 'collections/book-covers/eastern-mozi.jpg'},
    ('The Muqaddimah', 'Ibn Khaldun'): {'era': '1377', 'genre': 'History & Biography', 'note': 'The first science of history and society — why civilizations cohere, harden, and fall; sociology founded centuries early.', 'cover': 'collections/book-covers/eastern-muqaddimah.jpg'},
    ('The Narrow Road to the Deep North', 'Bashō'): {'era': '1644–1694', 'genre': 'Poetry & Epic', 'note': "Bashō's journey on foot through northern Japan, prose and haiku woven, the eternal held in a few syllables.", 'cover': 'collections/book-covers/eastern-narrow-road-to-the-deep-north.jpg'},
    ('The New Organon', 'Francis Bacon'): {"era": '1620', "genre": 'Philosophy', "note": "Bacon's manifesto for a new science built on experiment and evidence rather than authority.", "cover": 'collections/book-covers/lectio-the-new-organon.jpg'},
    ('The Origin of Species', 'Charles Darwin'): {"era": '1859', "genre": 'Science & Mathematics', "note": 'The book that remade biology — evolution by natural selection.', "cover": 'collections/book-covers/lectio-the-origin-of-species.jpg'},
    ('The Panchatantra', 'Anonymous'): {'era': '300 BCE–300 CE', 'genre': 'Fiction', 'note': "The world's most-traveled fables — animal tales of cunning and rule that reached every continent.", 'cover': 'collections/book-covers/eastern-panchatantra.jpg'},
    ('The Peony Pavilion', 'Tang Xianzu'): {'era': '1598', 'genre': 'Drama', 'note': 'The summit of Chinese drama — a love so strong it brings the dead back to life.', 'cover': 'collections/book-covers/eastern-peony-pavilion.jpg'},
    ('The Philosophy of History', 'G. W. F. Hegel'): {"era": '1837', "genre": 'Philosophy', "note": 'Hegel reads all of history as the unfolding of freedom — the idea that shaped the modern age.', "cover": 'collections/book-covers/lectio-philosophy-of-history.jpg'},
    ("The Pilgrim's Progress", 'John Bunyan'): {"era": '1678', "genre": 'Fiction', "note": 'The great allegory of the Christian life as a perilous journey.', "cover": 'collections/book-covers/lectio-the-pilgrim-s-progress.jpg'},
    ('The Pillow Book', 'Sei Shōnagon'): {'era': '1002', 'genre': 'Essays & Letters', 'note': "A lady-in-waiting's lists and merciless judgments — the sharpest eye in classical literature.", 'cover': 'collections/book-covers/eastern-pillow-book.jpg'},
    ('The Platform Sutra', 'Huineng'): {'era': '700–800 CE', 'genre': 'Religion', 'note': "The founding text of Zen — Huineng's teaching that awakening is sudden and within.", 'cover': 'collections/book-covers/eastern-platform-sutra.jpg'},
    ('The Plays & Poems of Kalidasa', 'Kalidasa'): {'era': '301–500 CE', 'genre': 'Poetry & Epic', 'note': 'The summit of Sanskrit literature — the drama Shakuntala and the lyric Cloud Messenger.', 'cover': 'collections/book-covers/eastern-kalidasa-plays-and-poems.jpg'},
    ('The Plays and Sonnets', 'William Shakespeare'): {"era": '1590–1613', "genre": 'Drama', "note": 'Shakespeare whole — the tragedies, comedies, histories, and sonnets that map the range of what we are.', "cover": 'collections/book-covers/lectio-the-plays-and-sonnets.jpg'},
    ('The Poems of Emily Dickinson', 'Emily Dickinson'): {"era": '1860–1886', "genre": 'Poetry & Epic', "note": 'Eighteen hundred tiny, electric poems on death, the soul, and the slant of light — published only after she died.', "cover": 'collections/book-covers/lectio-poems-of-emily-dickinson.jpg'},
    ('The Poems of Sappho', 'Sappho'): {"era": '600 BCE', "genre": 'Poetry & Epic', "note": 'The greatest lyric poet of antiquity — fragments of desire and longing that still feel newly broken open.', "cover": 'collections/book-covers/lectio-poems-of-sappho.jpg'},
    ('The Poems of the Tang', 'Li Bai, Du Fu, Wang Wei'): {'era': '701–900 CE', 'genre': 'Poetry & Epic', 'note': "The summit of Chinese verse — Li Bai's moonlight, Du Fu's grief, Wang Wei's empty mountains.", 'cover': 'collections/book-covers/eastern-poems-of-the-tang.jpg'},
    ('The Prince', 'Niccolò Machiavelli'): {"era": '1513', "genre": 'Politics & Economics', "note": "Machiavelli's unflinching handbook of power — how it is really won and kept.", "cover": 'collections/book-covers/lectio-the-prince.jpg'},
    ('The Principia', 'Isaac Newton'): {"era": '1687', "genre": 'Science & Mathematics', "note": "Newton's laws of motion and gravity — the mathematical system of the world.", "cover": 'collections/book-covers/lectio-the-principia.jpg'},
    ('The Principles of Psychology', 'William James'): {"era": '1890', "genre": 'Science & Mathematics', "note": 'William James founds modern psychology — the stream of consciousness, habit, and the self.'},
    ("The Qur'an", ''): {"era": '610–632 CE', "genre": 'Religion', "note": 'For Muslims the literal speech of God, and the standard of the Arabic language — the book that shaped a civilization.', "cover": 'collections/book-covers/eastern-quran.jpg'},
    ('The Ramayana', 'Valmiki'): {'era': '500–301 BCE', 'genre': 'Poetry & Epic', 'note': 'The exile of a prince and the war to win back his abducted wife — order tested against grief; living scripture across Asia.', 'cover': 'collections/book-covers/eastern-ramayana.jpg'},
    ('The Red and the Black', 'Stendhal'): {"era": '1830', "genre": 'Fiction', "note": "A carpenter's son claws toward the top of Restoration France — the first great psychological novel.", "cover": 'collections/book-covers/lectio-the-red-and-the-black.jpg'},
    ('The Revival of the Religious Sciences', 'Al-Ghazali'): {'era': '1058–1111', 'genre': 'Religion', 'note': 'Al-Ghazali put reason in its place and rescued faith through the inner life — the most influential Muslim after the Prophet.', 'cover': 'collections/book-covers/eastern-revival-of-the-religious-sciences.jpg'},
    ('The Rig Veda', 'Anonymous'): {'era': '1500–1100 BCE', 'genre': 'Religion', 'note': 'The oldest scripture of India — hymns to the gods at the source of the whole tradition.', 'cover': 'collections/book-covers/eastern-rig-veda.jpg'},
    ('The Romance of the West Chamber', 'Wang Shifu'): {'era': '1295–1307', 'genre': 'Drama', 'note': "China's most beloved love comedy — a scholar, a minister's daughter, and the maid who outwits everyone.", 'cover': 'collections/book-covers/eastern-romance-of-the-west-chamber.jpg'},
    ('The Rubaiyat', 'Omar Khayyam'): {'era': '1048–1131', 'genre': 'Poetry & Epic', 'note': "Omar Khayyam's quatrains — wine, doubt, and the fleeting day, beloved across the world.", 'cover': 'collections/book-covers/eastern-rubaiyat.jpg'},
    ('The Shahnameh', 'Ferdowsi'): {'era': '940–1020', 'genre': 'Poetry & Epic', 'note': 'Fifty thousand couplets recovering all of Persian myth and history, written to save the language itself.', 'cover': 'collections/book-covers/eastern-shahnameh.jpg'},
    ('The Social Contract', 'Jean-Jacques Rousseau'): {"era": '1762', "genre": 'Politics & Economics', "note": "Rousseau on freedom and the general will — 'man is born free, and everywhere he is in chains.'", "cover": 'collections/book-covers/lectio-the-social-contract.jpg'},
    ('The Song Lyrics', 'Su Shi & Li Qingzhao'): {'era': '1050–1150', 'genre': 'Poetry & Epic', 'note': 'The ci poetry of the Song dynasty — Su Shi and Li Qingzhao, the most intimate verse in Chinese.', 'cover': 'collections/book-covers/eastern-song-lyrics.jpg'},
    ('The Songs of Kabir', 'Kabir'): {'era': '1440–1518', 'genre': 'Poetry & Epic', 'note': "The poet-weaver who mocked temple and mosque alike — India's fiercest voice for the God beyond religion.", 'cover': 'collections/book-covers/eastern-songs-of-kabir.jpg'},
    ('The Spirit of the Laws', 'Montesquieu'): {"era": '1748', "genre": 'Politics & Economics', "note": 'Montesquieu on what makes laws just — and the separation of powers that shaped every later republic.', "cover": 'collections/book-covers/lectio-the-spirit-of-the-laws.jpg'},
    ('The Stranger', 'Albert Camus'): {"era": '1942', "genre": 'Fiction', "note": "A man who feels nothing at his mother's funeral — the novel of the absurd that defined an era.", "rights": 'in-copyright', "opens": 2038, "cover": 'collections/book-covers/lectio-the-stranger.jpg'},
    ('1984', 'George Orwell'): {"era": '1949', "genre": 'Fiction', "note": "Big Brother, Newspeak, and the boot on the human face forever — the century's defining dystopia.", "rights": 'in-copyright', "opens": 2045, "cover": 'collections/book-covers/lectio-1984.jpg'},
    ('The Old Man and the Sea', 'Ernest Hemingway'): {"era": '1952', "genre": 'Fiction', "note": 'An old fisherman, a great marlin, and the dignity of struggle — Hemingway at his sparest.', "rights": 'in-copyright', "opens": 2048, "cover": 'collections/book-covers/lectio-the-old-man-and-the-sea.jpg'},
    ('Waiting for Godot', 'Samuel Beckett'): {"era": '1953', "genre": 'Drama', "note": 'Two men wait for someone who never comes — the play that remade modern theater.', "rights": 'in-copyright', "opens": 2049, "cover": 'collections/book-covers/lectio-waiting-for-godot.jpg'},
    ('The Second Sex', 'Simone de Beauvoir'): {"era": '1949', "genre": 'Philosophy', "note": "'One is not born, but rather becomes, a woman' — the foundation of modern feminist thought.", "rights": 'in-copyright', "opens": 2045, "cover": 'collections/book-covers/lectio-the-second-sex.jpg'},
    ('Things Fall Apart', 'Chinua Achebe'): {"era": '1958', "genre": 'Fiction', "note": 'An Igbo leader and the coming of the British — the novel that gave modern African literature its voice.', "rights": 'in-copyright', "opens": 2054, "cover": 'collections/book-covers/lectio-things-fall-apart.jpg'},
    ('One Hundred Years of Solitude', 'Gabriel García Márquez'): {"era": '1967', "genre": 'Fiction', "note": 'The Buendía family across generations — the masterpiece of magical realism.', "rights": 'in-copyright', "opens": 2063, "cover": 'collections/book-covers/lectio-one-hundred-years-of-solitude.jpg'},
    ('Beloved', 'Toni Morrison'): {"era": '1987', "genre": 'Fiction', "note": 'A mother, a ghost, and the unhealed wound of slavery — the great American novel of memory.', "rights": 'in-copyright', "opens": 2083, "cover": 'collections/book-covers/lectio-beloved.jpg'},
    ('Seven Pillars of Wisdom', 'T. E. Lawrence'): {"era": '1926', "genre": 'History & Biography', "note": "Lawrence's first-hand epic of the Arab Revolt — guerrilla war across the desert, and the making and unmaking of a legend."},
    ('The Tale of Genji', 'Murasaki Shikibu'): {'era': '1008', 'genre': 'Fiction', 'note': "The world's first psychological novel — the loves and aging of a Heian prince, written by a woman a thousand years ago.", 'cover': 'collections/book-covers/eastern-tale-of-genji.jpg'},
    ('The Tale of the Heike', 'Anonymous'): {'era': '1300–1330', 'genre': 'Poetry & Epic', 'note': "The fall of a samurai clan — Japan's national war epic, on glory and impermanence.", 'cover': 'collections/book-covers/eastern-tale-of-the-heike.jpg'},
    ('The Talmud', ''): {"era": '200–500 CE', "genre": 'Religion', "note": 'The central text of rabbinic Judaism — the law argued out across generations.'},
    ('The Tanakh', 'The Hebrew Bible'): {"era": '1200–165 BCE', "genre": 'Religion', "note": 'The Hebrew Bible — Torah, Prophets, and Writings, the scripture of Judaism.'},
    ('The Tao Te Ching', 'Laozi'): {"era": '400–301 BCE', "genre": 'Philosophy', "note": 'Eighty-one chapters on the way that cannot be named and the power that works by yielding.', "cover": 'collections/book-covers/eastern-tao-te-ching.jpg'},
    ('The Tirukkural', 'Tiruvalluvar'): {'era': '450–500 CE', 'genre': 'Philosophy', 'note': "Tamil couplets on virtue, wealth, and love — South India's most beloved book of wisdom.", 'cover': 'collections/book-covers/eastern-tirukkural.jpg'},
    ('The Travels of Ibn Battuta', 'Ibn Battuta'): {'era': '1355', 'genre': 'History & Biography', 'note': 'Thirty years and the whole medieval world on foot — the greatest travel book before modern times.', 'cover': 'collections/book-covers/eastern-travels-of-ibn-battuta.jpg'},
    ('The Trial', 'Franz Kafka'): {"era": '1925', "genre": 'Fiction', "note": "Kafka's nightmare of a man arrested for a crime never named — the modern condition as parable."},
    ('The Upanishads', 'Anonymous'): {'era': '800–200 BCE', 'genre': 'Religion', 'note': 'The fountainhead of Indian philosophy — the discovery that the self within and the ground of all being are one.', 'cover': 'collections/book-covers/eastern-upanishads.jpg'},
    ('The Virtuous City', 'Al-Farabi'): {'era': '940', 'genre': 'Philosophy', 'note': "Al-Farabi imagines the ideal state — Plato's Republic remade for the Islamic world.", 'cover': 'collections/book-covers/eastern-virtuous-city.jpg'},
    ('The Voyage of the Beagle', 'Charles Darwin'): {"era": '1839', "genre": 'History & Biography', "note": "The young naturalist's travel journal — the voyage that planted evolution.", "cover": 'collections/book-covers/lectio-the-voyage-of-the-beagle.jpg'},
    ('The Waste Land', 'T. S. Eliot'): {"era": '1922', "genre": 'Poetry & Epic', "note": "T. S. Eliot's fractured masterpiece — the defining poem of the modern century."},
    ('The Water Margin', "Shi Nai'an"): {'era': '1368–1400', 'genre': 'Fiction', 'note': "Outlaws of the marsh — a band of rebels turned folk heroes, China's tale of honor among bandits.", 'cover': 'collections/book-covers/eastern-water-margin.jpg'},
    ('The Wealth of Nations', 'Adam Smith'): {"era": '1776', "genre": 'Politics & Economics', "note": 'The founding work of modern economics — the division of labor and the invisible hand.', "cover": 'collections/book-covers/lectio-the-wealth-of-nations.jpg'},
    ('The Works of Archimedes', 'Archimedes'): {"era": '250 BCE', "genre": 'Science & Mathematics', "note": 'The greatest mathematician of antiquity — levers, spheres, and the first reach toward the calculus.', "cover": 'collections/book-covers/lectio-the-works-of-archimedes.jpg'},
    ('The Yoga Sutras', 'Patanjali'): {'era': '200 BCE–400 CE', 'genre': 'Philosophy', 'note': "Patanjali's terse map of the mind and the eightfold path to stilling it.", 'cover': 'collections/book-covers/eastern-yoga-sutras.jpg'},
    ('The Zhuangzi', 'Zhuangzi'): {'era': '369–286 BCE', 'genre': 'Philosophy', 'note': 'Philosophy by parable and joke — the man who dreams he is a butterfly; the freest book in the tradition.', 'cover': 'collections/book-covers/eastern-zhuangzi.jpg'},
    ('Tractatus Logico-Philosophicus', 'Ludwig Wittgenstein'): {"era": '1921', "genre": 'Philosophy', "note": "Seven austere propositions on the limits of language — 'whereof one cannot speak, thereof one must be silent.'", "cover": 'collections/book-covers/lectio-tractatus-logico-philosophicus.jpg'},
    ('Two New Sciences', 'Galileo Galilei'): {"era": '1638', "genre": 'Science & Mathematics', "note": 'Galileo founds modern physics — motion and materials, argued in plain dialogue against the schoolmen.', "cover": 'collections/book-covers/lectio-two-new-sciences.jpg'},
    ('Two Treatises of Government', 'John Locke'): {"era": '1689', "genre": 'Politics & Economics', "note": 'Locke on natural rights and government by consent — the philosophy behind modern liberty.', "cover": 'collections/book-covers/lectio-two-treatises-of-government.jpg'},
    ('Two Years Before the Mast', 'Richard Henry Dana'): {"era": '1840', "genre": 'History & Biography', "note": "A Harvard man's plain account of life as a common sailor — the sea without romance.", "cover": 'collections/book-covers/lectio-two-years-before-the-mast.jpg'},
    ('Ulysses', 'James Joyce'): {"era": '1922', "genre": 'Fiction', "note": 'Joyce remakes the novel — one Dublin day rendered whole, the Odyssey turned inside out.'},
    ('Utopia', 'Sir Thomas More'): {"era": '1516', "genre": 'Politics & Economics', "note": "More's book that named the genre — an island of perfect order, half-ideal, half-warning.", "cover": 'collections/book-covers/lectio-utopia.jpg'},
    ('Voyages and Travels', ''): {"era": '400 BCE–1900', "genre": 'History & Biography', "note": 'Great first-hand accounts of exploration, ancient and modern.', "cover": 'collections/book-covers/lectio-voyages-and-travels.jpg'},
    ('Walden', 'Henry David Thoreau'): {"era": '1854', "genre": 'Essays & Letters', "note": 'Two years alone at a pond — the American testament of simplicity and self-reliance.', "cover": 'collections/book-covers/lectio-walden.jpg'},
    ('War and Peace', 'Leo Tolstoy'): {"era": '1869', "genre": 'Fiction', "note": "Tolstoy's vast novel of Russia at war with Napoleon — the whole of life held in one book."},
    ('Wuthering Heights', 'Emily Brontë'): {"era": '1847', "genre": 'Fiction', "note": 'Love as a force of nature on the Yorkshire moors — wild, strange, and unlike anything before it.', "cover": 'collections/book-covers/lectio-wuthering-heights.jpg'},
}

REAL_GENRE = {
    'The Iliad': 'Poetry & Epic',
    'The Odyssey': 'Poetry & Epic',
    'The Aeneid': 'Poetry & Epic',
    'Meditations': 'Philosophy',
    'The Republic': 'Philosophy',
}

LECTIO_REFS = [
    ('Genesis', 'The Bible', ''),
    ('The Epic of Gilgamesh', 'Anonymous · Sumer & Akkad', ''),
    ('The Analects', 'Confucius', ''),
    ('The Tao Te Ching', 'Laozi', ''),
    ('The Bhagavad Gita', '', ''),
    ('The Dhammapada', 'Early Buddhist tradition', ''),
    ('The Art of War', 'Sun Tzu', ''),
    ('Nicomachean Ethics', 'Aristotle', ''),
    ('Confessions', 'Saint Augustine', ''),
    ('The Divine Comedy', 'Dante Alighieri', ''),
    ('The Prince', 'Niccolò Machiavelli', ''),
    ('Don Quixote', 'Miguel de Cervantes', ''),
    ('Hamlet', 'William Shakespeare', ''),
    ('One Thousand and One Nights', '', ''),
    ('The Tale of Genji', 'Murasaki Shikibu', ''),
    ('The Rubaiyat', 'Omar Khayyam', ''),
    ('Candide', 'Voltaire', ''),
    ('Pride and Prejudice', 'Jane Austen', ''),
    ('The Brothers Karamazov', 'Fyodor Dostoevsky', ''),
    ('Frankenstein', 'Mary Shelley', ''),
]

WESTERN_REFS = [
    ('The Greek Tragedies', 'Aeschylus, Sophocles & Euripides', 'Greece & Rome'),
    ('The Histories', 'Herodotus', 'Greece & Rome'),
    ('History of the Peloponnesian War', 'Thucydides', 'Greece & Rome'),
    ('Nicomachean Ethics', 'Aristotle', 'Greece & Rome'),
    ('The Elements', 'Euclid', 'Greece & Rome'),
    ('The Works of Archimedes', 'Archimedes', 'Greece & Rome'),
    ('On the Nature of Things', 'Lucretius', 'Greece & Rome'),
    ('Lives', 'Plutarch', 'Greece & Rome'),
    ('The Annals', 'Tacitus', 'Greece & Rome'),
    ('The Almagest', 'Ptolemy', 'Greece & Rome'),
    ('The Enneads', 'Plotinus', 'Greece & Rome'),
    ('The City of God', 'Saint Augustine', 'The Middle Ages'),
    ('Summa Theologica', 'Thomas Aquinas', 'The Middle Ages'),
    ('The Divine Comedy', 'Dante Alighieri', 'The Middle Ages'),
    ('The Canterbury Tales', 'Geoffrey Chaucer', 'The Middle Ages'),
    ('On the Revolutions of the Heavenly Spheres', 'Nicolaus Copernicus', 'The Renaissance'),
    ('The Prince', 'Niccolò Machiavelli', 'The Renaissance'),
    ('Gargantua and Pantagruel', 'François Rabelais', 'The Renaissance'),
    ('The Essays', 'Michel de Montaigne', 'The Renaissance'),
    ('Don Quixote', 'Miguel de Cervantes', 'The Renaissance'),
    ('The Plays and Sonnets', 'William Shakespeare', 'The Renaissance'),
    ('The New Organon', 'Francis Bacon', 'The Renaissance'),
    ('On the Motion of the Heart and Blood', 'William Harvey', 'The Renaissance'),
    ('Two New Sciences', 'Galileo Galilei', 'The Renaissance'),
    ('Discourse on Method', 'René Descartes', 'The Enlightenment'),
    ('Leviathan', 'Thomas Hobbes', 'The Enlightenment'),
    ('Paradise Lost', 'John Milton', 'The Enlightenment'),
    ('Pensées', 'Blaise Pascal', 'The Enlightenment'),
    ('Ethics', 'Baruch Spinoza', 'The Enlightenment'),
    ('Two Treatises of Government', 'John Locke', 'The Enlightenment'),
    ('The Principia', 'Isaac Newton', 'The Enlightenment'),
    ("Gulliver's Travels", 'Jonathan Swift', 'The Enlightenment'),
    ('The Spirit of the Laws', 'Montesquieu', 'The Enlightenment'),
    ('Candide', 'Voltaire', 'The Enlightenment'),
    ('The Social Contract', 'Jean-Jacques Rousseau', 'The Enlightenment'),
    ('The Wealth of Nations', 'Adam Smith', 'The Enlightenment'),
    ('The Decline and Fall of the Roman Empire', 'Edward Gibbon', 'The Enlightenment'),
    ('The Critique of Pure Reason', 'Immanuel Kant', 'The Enlightenment'),
    ('The Federalist Papers', 'Hamilton, Madison & Jay', 'The Enlightenment'),
    ('Faust', 'Johann Wolfgang von Goethe', 'The Nineteenth Century'),
    ('Pride and Prejudice', 'Jane Austen', 'The Nineteenth Century'),
    ('Democracy in America', 'Alexis de Tocqueville', 'The Nineteenth Century'),
    ('The Philosophy of History', 'G. W. F. Hegel', 'The Nineteenth Century'),
    ('Fear and Trembling', 'Søren Kierkegaard', 'The Nineteenth Century'),
    ('Moby-Dick', 'Herman Melville', 'The Nineteenth Century'),
    ('On Liberty', 'John Stuart Mill', 'The Nineteenth Century'),
    ('The Origin of Species', 'Charles Darwin', 'The Nineteenth Century'),
    ('Great Expectations', 'Charles Dickens', 'The Nineteenth Century'),
    ('Capital', 'Karl Marx', 'The Nineteenth Century'),
    ('War and Peace', 'Leo Tolstoy', 'The Nineteenth Century'),
    ('Middlemarch', 'George Eliot', 'The Nineteenth Century'),
    ('The Brothers Karamazov', 'Fyodor Dostoevsky', 'The Nineteenth Century'),
    ('The Adventures of Huckleberry Finn', 'Mark Twain', 'The Nineteenth Century'),
    ('Beyond Good and Evil', 'Friedrich Nietzsche', 'The Nineteenth Century'),
    ("A Doll's House", 'Henrik Ibsen', 'The Nineteenth Century'),
    ('The Principles of Psychology', 'William James', 'The Modern World'),
    ('Heart of Darkness', 'Joseph Conrad', 'The Modern World'),
    ('The Interpretation of Dreams', 'Sigmund Freud', 'The Modern World'),
    ('The Waste Land', 'T. S. Eliot', 'The Modern World'),
    ('Ulysses', 'James Joyce', 'The Modern World'),
    ('The Trial', 'Franz Kafka', 'The Modern World'),
]

EASTERN_REFS = [
    ('The Epic of Gilgamesh', 'Anonymous · Sumer & Akkad', 'Prologue · The Common Root'),
    ('The Code of Hammurabi', 'Babylon', 'Prologue · The Common Root'),
    ('The Enuma Elish', 'Babylon', 'Prologue · The Common Root'),
    ('The Egyptian Book of the Dead', 'Anonymous · Egypt', 'Prologue · The Common Root'),
    ('The Rig Veda', 'Anonymous', 'India'),
    ('The Upanishads', 'Anonymous', 'India'),
    ('The Mahabharata', 'Attributed to Vyasa', 'India'),
    ('The Bhagavad Gita', '', 'India'),
    ('The Ramayana', 'Valmiki', 'India'),
    ('The Dhammapada', 'Early Buddhist tradition', 'India'),
    ('The Arthashastra', 'Kautilya', 'India'),
    ('The Yoga Sutras', 'Patanjali', 'India'),
    ('The Panchatantra', 'Anonymous', 'India'),
    ('The Lotus Sutra', 'Mahayana Buddhist tradition', 'India'),
    ('The Kama Sutra', 'Vatsyayana', 'India'),
    ('The Tirukkural', 'Tiruvalluvar', 'India'),
    ('The Plays & Poems of Kalidasa', 'Kalidasa', 'India'),
    ('The Gita Govinda', 'Jayadeva', 'India'),
    ('The Songs of Kabir', 'Kabir', 'India'),
    ('Gitanjali', 'Rabindranath Tagore', 'India'),
    ('The Book of Songs', 'Anonymous', 'China'),
    ('The I Ching', 'Anonymous', 'China'),
    ('The Analects', 'Confucius', 'China'),
    ('The Art of War', 'Sun Tzu', 'China'),
    ('The Mozi', 'Mozi', 'China'),
    ('The Tao Te Ching', 'Laozi', 'China'),
    ('The Doctrine of the Mean', 'Attributed to Zisi', 'China'),
    ('The Mencius', 'Mencius', 'China'),
    ('The Zhuangzi', 'Zhuangzi', 'China'),
    ('The Han Feizi', 'Han Fei', 'China'),
    ('Records of the Grand Historian', 'Sima Qian', 'China'),
    ('The Platform Sutra', 'Huineng', 'China'),
    ('The Poems of the Tang', 'Li Bai, Du Fu, Wang Wei', 'China'),
    ('The Song Lyrics', 'Su Shi & Li Qingzhao', 'China'),
    ('The Romance of the West Chamber', 'Wang Shifu', 'China'),
    ('Romance of the Three Kingdoms', 'Luo Guanzhong', 'China'),
    ('The Water Margin', "Shi Nai'an", 'China'),
    ('Journey to the West', "Wu Cheng'en", 'China'),
    ('The Peony Pavilion', 'Tang Xianzu', 'China'),
    ('Dream of the Red Chamber', 'Cao Xueqin', 'China'),
    ("The Qur'an", '', 'Persia & the Islamic World'),
    ('The Virtuous City', 'Al-Farabi', 'Persia & the Islamic World'),
    ('The Shahnameh', 'Ferdowsi', 'Persia & the Islamic World'),
    ('The Canon of Medicine', 'Avicenna', 'Persia & the Islamic World'),
    ('The Revival of the Religious Sciences', 'Al-Ghazali', 'Persia & the Islamic World'),
    ('The Rubaiyat', 'Omar Khayyam', 'Persia & the Islamic World'),
    ('The Maqamat', 'Al-Hariri', 'Persia & the Islamic World'),
    ('The Conference of the Birds', 'Attar', 'Persia & the Islamic World'),
    ('The Decisive Treatise', 'Averroes', 'Persia & the Islamic World'),
    ('Layla and Majnun', 'Nizami', 'Persia & the Islamic World'),
    ('The Masnavi', 'Rumi', 'Persia & the Islamic World'),
    ('The Gulistan', 'Saadi', 'Persia & the Islamic World'),
    ('The Divan', 'Hafez', 'Persia & the Islamic World'),
    ('The Travels of Ibn Battuta', 'Ibn Battuta', 'Persia & the Islamic World'),
    ('The Muqaddimah', 'Ibn Khaldun', 'Persia & the Islamic World'),
    ('One Thousand and One Nights', '', 'Persia & the Islamic World'),
    ('The Kojiki', 'Ō no Yasumaro', 'Japan'),
    ('The Manyoshu', 'Compiled', 'Japan'),
    ('The Kokinshu', 'Compiled', 'Japan'),
    ('The Pillow Book', 'Sei Shōnagon', 'Japan'),
    ('The Tale of Genji', 'Murasaki Shikibu', 'Japan'),
    ('The Tale of the Heike', 'Anonymous', 'Japan'),
    ('Essays in Idleness', 'Yoshida Kenkō', 'Japan'),
    ('On the Art of the Noh Drama', 'Zeami', 'Japan'),
    ('The Narrow Road to the Deep North', 'Bashō', 'Japan'),
    ('The Book of Five Rings & Hagakure', 'Musashi & Tsunetomo', 'Japan'),
]

HARVARD_REFS = [
    ('The Autobiography of Benjamin Franklin', 'Benjamin Franklin', ''),
    ('Journal', 'John Woolman', ''),
    ('Fruits of Solitude', 'William Penn', ''),
    ('Apology, Crito & Phaedo', 'Plato', ''),
    ('The Golden Sayings', 'Epictetus', ''),
    ('Essays, Civil and Moral', 'Francis Bacon', ''),
    ('Areopagitica', 'John Milton', ''),
    ('Religio Medici', 'Sir Thomas Browne', ''),
    ('The Complete English Poems', 'John Milton', ''),
    ('Essays & English Traits', 'Ralph Waldo Emerson', ''),
    ('Poems and Songs', 'Robert Burns', ''),
    ('Confessions', 'Saint Augustine', ''),
    ('The Imitation of Christ', 'Thomas à Kempis', ''),
    ('Nine Greek Dramas', 'Aeschylus, Sophocles, Euripides, Aristophanes', ''),
    ('On Friendship & On Old Age', 'Cicero', ''),
    ('Letters', 'Pliny the Younger', ''),
    ('The Wealth of Nations', 'Adam Smith', ''),
    ('The Origin of Species', 'Charles Darwin', ''),
    ('Lives', 'Plutarch', ''),
    ('Don Quixote', 'Miguel de Cervantes', ''),
    ("The Pilgrim's Progress", 'John Bunyan', ''),
    ('The Lives of Donne and Herbert', 'Izaak Walton', ''),
    ('One Thousand and One Nights', '', ''),
    ('Folklore and Fable', 'Aesop, Grimm & Andersen', ''),
    ('Faust', 'Johann Wolfgang von Goethe', ''),
    ('Doctor Faustus', 'Christopher Marlowe', ''),
    ('The Divine Comedy', 'Dante Alighieri', ''),
    ('The Betrothed', 'Alessandro Manzoni', ''),
    ('Two Years Before the Mast', 'Richard Henry Dana', ''),
    ('Reflections on the Revolution in France', 'Edmund Burke', ''),
    ('On Liberty', 'John Stuart Mill', ''),
    ('Characteristics & Inaugural Address', 'Thomas Carlyle', ''),
    ('English Essays: Sidney to Macaulay', '', ''),
    ('Essays: English and American', '', ''),
    ('The Voyage of the Beagle', 'Charles Darwin', ''),
    ('Scientific Papers: Physics & Chemistry', 'Faraday, Helmholtz, Kelvin & others', ''),
    ('The Autobiography of Benvenuto Cellini', 'Benvenuto Cellini', ''),
    ('Literary and Philosophical Essays', 'Montaigne, Sainte-Beuve, Renan', ''),
    ('Voyages and Travels', '', ''),
    ('Discourse on Method', 'René Descartes', ''),
    ('Letters on England', 'Voltaire', ''),
    ('A Discourse on Inequality', 'Jean-Jacques Rousseau', ''),
    ('Leviathan', 'Thomas Hobbes', ''),
    ('Chronicle and Romance', 'Froissart, Malory, Holinshed', ''),
    ('The Prince', 'Niccolò Machiavelli', ''),
    ('Utopia', 'Sir Thomas More', ''),
    ('Ninety-Five Theses & Addresses', 'Martin Luther', ''),
    ('An Essay Concerning Human Understanding', 'John Locke', ''),
    ('Principles of Human Knowledge', 'George Berkeley', ''),
    ('An Enquiry Concerning Human Understanding', 'David Hume', ''),
    ('Scientific Papers: Medicine & Biology', 'Harvey, Jenner, Lister, Pasteur', ''),
    ('Prefaces and Prologues', '', ''),
    ('English Poetry I: Chaucer to Gray', '', ''),
    ('English Poetry II: Collins to Fitzgerald', '', ''),
    ('English Poetry III: Tennyson to Whitman', '', ''),
    ('American Historical Documents', '', ''),
    ('Sacred Writings I', 'Confucian, Hebrew, Christian', ''),
    ('Sacred Writings II', 'Buddhist, Hindu, Mohammedan', ''),
    ('Elizabethan Drama I', 'Marlowe & Shakespeare', ''),
    ('Elizabethan Drama II', 'Jonson, Webster, Massinger & others', ''),
    ('Pensées', 'Blaise Pascal', ''),
    ('Epic and Saga', 'Beowulf, Roland, the Nibelungenlied', ''),
]

BEYOND_REFS = [
    ('The Poems of Sappho', 'Sappho', 'Antiquity & the Middle Ages'),
    ('Metamorphoses', 'Ovid', 'Antiquity & the Middle Ages'),
    ('The Consolation of Philosophy', 'Boethius', 'Antiquity & the Middle Ages'),
    ('The Decameron', 'Giovanni Boccaccio', 'Antiquity & the Middle Ages'),
    ('In Praise of Folly', 'Erasmus', 'The Renaissance & Enlightenment'),
    ('Tartuffe & The Misanthrope', 'Molière', 'The Renaissance & Enlightenment'),
    ('Robinson Crusoe', 'Daniel Defoe', 'The Renaissance & Enlightenment'),
    ('Poems & The Reply to Sor Filotea', 'Sor Juana Inés de la Cruz', 'The Renaissance & Enlightenment'),
    ('A Vindication of the Rights of Woman', 'Mary Wollstonecraft', 'The Renaissance & Enlightenment'),
    ('Songs of Innocence and of Experience', 'William Blake', 'The Romantic Age'),
    ('Lyrical Ballads', 'Wordsworth & Coleridge', 'The Romantic Age'),
    ('Frankenstein', 'Mary Shelley', 'The Romantic Age'),
    ('Eugene Onegin', 'Alexander Pushkin', 'The Romantic Age'),
    ('The Red and the Black', 'Stendhal', 'The Nineteenth Century'),
    ('Madame Bovary', 'Gustave Flaubert', 'The Nineteenth Century'),
    ('Les Misérables', 'Victor Hugo', 'The Nineteenth Century'),
    ('Walden', 'Henry David Thoreau', 'The Nineteenth Century'),
    ('Leaves of Grass', 'Walt Whitman', 'The Nineteenth Century'),
    ('The Poems of Emily Dickinson', 'Emily Dickinson', 'The Nineteenth Century'),
    ('Narrative of the Life of Frederick Douglass', 'Frederick Douglass', 'The Nineteenth Century'),
    ('Jane Eyre', 'Charlotte Brontë', 'The Nineteenth Century'),
    ('Wuthering Heights', 'Emily Brontë', 'The Nineteenth Century'),
    ('In Search of Lost Time', 'Marcel Proust', 'The Modern World'),
    ('Mrs Dalloway', 'Virginia Woolf', 'The Modern World'),
    ('Tractatus Logico-Philosophicus', 'Ludwig Wittgenstein', 'The Modern World'),
    ('Seven Pillars of Wisdom', 'T. E. Lawrence', 'The Modern World'),
    ('The Stranger', 'Albert Camus', 'Still Under Copyright'),
    ('The Second Sex', 'Simone de Beauvoir', 'Still Under Copyright'),
    ('1984', 'George Orwell', 'Still Under Copyright'),
    ('The Old Man and the Sea', 'Ernest Hemingway', 'Still Under Copyright'),
    ('Waiting for Godot', 'Samuel Beckett', 'Still Under Copyright'),
    ('Things Fall Apart', 'Chinua Achebe', 'Still Under Copyright'),
    ('One Hundred Years of Solitude', 'Gabriel García Márquez', 'Still Under Copyright'),
    ('Beloved', 'Toni Morrison', 'Still Under Copyright'),
]

EPICS_REFS = [
    ('The Divine Comedy', 'Dante Alighieri', ''),
    ('Paradise Lost', 'John Milton', ''),
]

CHRISTIANITY_REFS = [
    ('The Holy Bible', 'King James Version', ''),
    ('Confessions', 'Saint Augustine', ''),
    ('The City of God', 'Saint Augustine', ''),
    ('The Imitation of Christ', 'Thomas à Kempis', ''),
    ("The Pilgrim's Progress", 'John Bunyan', ''),
    ('Summa Theologica', 'Thomas Aquinas', ''),
]

JUDAISM_REFS = [
    ('The Tanakh', 'The Hebrew Bible', ''),
    ('The Talmud', '', ''),
]

ISLAM_REFS = [
    ("The Qur'an", '', ''),
    ('The Hadith', '', ''),
]

EASTERN_INTRO = (
    "The works without which no account of the Eastern mind is complete. An original Lectio "
    "collection, built deliberately as the equal of the great Western sets — not a sampler of the "
    "exotic but a full shelf, scripture and philosophy standing beside history, poetry, and "
    "the novel, across five civilizations and four thousand years.\n\n"

    "The cut refuses one temptation in particular — letting the easy availability of old "
    "scripture crowd out literature. A library of the East that is all Veda, Quran, and "
    "Analects, with no Tang poetry, no Genji, no Bashō, is a record of a civilization's "
    "theology, not its mind. Here the poets and novelists keep their seats beside the "
    "prophets and philosophers.\n\n"

    "Four civilizations and one prologue, in a rough order of age — four thousand years, "
    "Gilgamesh to the haiku. Read straight through, the set is a single conversation about "
    "the self, the state, the sacred, and the passing moment, carried by voices that mostly "
    "never heard one another and arriving again and again at the same questions.\n\n"

    "The Common Root. Before the traditions divided, the Near East set down the first epic. "
    "The Epic of Gilgamesh (c. 2100–1200 BCE) is older than all of them and a parent to both "
    "East and West: a king loses his friend, refuses his own death, and comes home empty-"
    "handed and wiser.\n\n"

    "India. The longest unbroken philosophical tradition on earth, turned from the start "
    "toward the inner question. The Upanishads discover that the self within and the ground "
    "of being are one; the Bhagavad Gita answers a warrior who will not fight; the "
    "Mahabharata and Ramayana hold the whole of dharma and its impossible ambiguities; the "
    "Dhammapada gives the Buddha's path in its plainest form; and Kalidasa is the summit of "
    "Sanskrit literature as distinct from its scripture.\n\n"

    "China. Three thousand years of one literate civilization arguing over a single "
    "question: what is the well-ordered life, and the well-ordered state? The Analects and "
    "the Tao Te Ching set the poles; the Zhuangzi is its freest book; Sun Tzu wins without "
    "fighting; Sima Qian founds its history; the Tang poets are the summit of its verse; and "
    "Dream of the Red Chamber the subtlest of its novels.\n\n"

    "Persia & the Islamic World. For five centuries the most advanced civilization on the "
    "planet — it kept Greek philosophy alive when Europe had lost it and founded the science "
    "of history. The Quran; Al-Ghazali, who put reason in its place; Ibn Khaldun's "
    "Muqaddimah, sociology founded three centuries early; Ferdowsi's Shahnameh; the Persian "
    "lyric poets, never bettered; and the Thousand and One Nights.\n\n"

    "Japan. An island that took Chinese letters and Buddhist thought and made an aesthetic "
    "of impermanence and restraint. The Tale of Genji — the world's first psychological "
    "novel, written by a woman a thousand years ago; the Pillow Book; Bashō's haiku journey; "
    "and the way of the warrior, from the duelist's strategy to the acceptance of death.\n\n"

    "Read straight through, the set is one argument carried by many voices that the West "
    "joined late and has never finished. Compiled for the Lectio library."
)

HARVARD_INTRO = (
    "In 1909 Charles W. Eliot, who had just stepped down after forty years as president "
    "of Harvard, made a claim that sounded like a boast: the essentials of a liberal "
    "education, he said, could be had by anyone willing to spend fifteen minutes a day "
    "with a shelf of books about five feet long. A publisher took him up on it, and "
    "Eliot — with the scholar William Allan Neilson — chose the books. The result, "
    "fifty-one volumes, became the Harvard Classics: the most ambitious attempt ever "
    "made to put a university education into an ordinary home.\n\n"

    "Eliot's conviction was a democratic one. A great education, he believed, was not the "
    "private property of those who could come to Cambridge; it was a birthright that only "
    "needed to be made portable. The five-foot shelf was exactly that — sold by "
    "subscription to hundreds of thousands of families who would never see Harvard.\n\n"

    "The set is arranged not by difficulty but by the shape of human knowledge. It gathers "
    "philosophy and religion, history and biography, science and political thought, poetry "
    "and drama and prose fiction, the essay and criticism, voyages and travel. Read across "
    "it and you are meant to feel the whole of the Western mind at once — Plato beside "
    "Darwin, the Psalms beside the Declaration of Independence.\n\n"

    "Lectio carries the Harvard Classics in the spirit Eliot intended, only further: every "
    "work in a clear modern edition, read by default, with the original always a tap away. "
    "You needn't read it in order, or in full. Open any volume, give it fifteen minutes, "
    "and you are doing precisely what Eliot promised.\n\n"

    "What follows is the shelf in brief — what is on it, and why each kind of book belongs.\n\n"

    "Philosophy & Religion. The trial and death of Socrates in Plato's Apology, Crito, and "
    "Phaedo — the founding drama of the examined life; Marcus Aurelius's Meditations, a "
    "Roman emperor's private Stoic notebook; Epictetus, the slave who taught freedom; "
    "Augustine's Confessions, the first true autobiography of a soul; and the sacred "
    "writings of the world's faiths, set side by side. They are here because every other "
    "question begins with how one ought to live.\n\n"

    "History & Biography. Plutarch's Lives — paired portraits of Greeks and Romans that "
    "taught Europe what greatness looked like — and the memoirs of Franklin and Cellini. "
    "Included because character is best learned from lives, not maxims.\n\n"

    "Science. Darwin's Origin of Species entire, the book that remade biology, alongside "
    "the papers of Faraday, Lavoisier, and Pasteur. Eliot refused to wall the sciences off "
    "from the humanities; to him they were one inquiry, and a liberal education that "
    "skipped them was not liberal at all.\n\n"

    "Political Thought. Machiavelli's Prince and More's Utopia; Hobbes, Locke, Berkeley, "
    "and Hume; the great documents of liberty. Here so a reader can trace the long argument "
    "over how human beings should be governed — and govern themselves.\n\n"

    "Poetry, Drama & Fiction. Homer's Odyssey and Virgil's Aeneid; the Greek tragedies; "
    "Dante's Divine Comedy; Milton; Cervantes' Don Quixote; the Elizabethan dramatists. "
    "The imagination of the West, in the works that formed it.\n\n"

    "The Essay & Criticism. Bacon, Montaigne, Emerson, Carlyle — the art of thinking "
    "openly on the page, which is finally what the whole shelf is meant to teach.\n\n"

    "Eliot called it a library of the world's best literature. It is more than that: it is "
    "an argument that any person, given the books and a quarter of an hour a day, can join "
    "the long conversation of humankind. Lectio exists to make that argument true again."
)

COLLECTIONS = {
    LECTIO_ALL: {
        "kind": 'series',
        "title": 'The Lectio Collection',
        "curator": 'Where to begin',
        "blurb": (
            "The curated starting point — a short, balanced shelf drawn from the great sets of East and West and the world's scriptures. If you read nothing else, read these."
        ),
        "about": (
            "The two great sets behind this app — the Western and the Eastern — run to sixty books each. That is a library, not a starting point. The Lectio Collection is the starting point: a short, deliberately balanced shelf, drawn from both and from the world's scriptures, of the books we'd put in a reader's hands first.\n\n"
            'It crosses every border on purpose — Homer beside the Analects, Augustine beside the Bhagavad Gita, Austen beside the Tale of Genji — so a first year of reading is a conversation across civilizations, not a tour of one. Every work is offered in a clear modern Lectio edition; public-domain first, and growing over time.'
        ),
        "all_works": True,
        "refs": LECTIO_REFS,
    },
    'collection.great-books': {
        "kind": 'series',
        "group": 'The Western World',
        "title": 'Great Books of the Western World',
        "curator": 'Hutchins & Adler (1952)',
        "blurb": (
            "Britannica's mid-century collection — the long conversation of the West, from Homer to the moderns, gathered as one continuous argument."
        ),
        "about": (
            "Conceived at the University of Chicago by Robert Hutchins and Mortimer Adler and published by Encyclopædia Britannica in 1952, the Great Books of the Western World gathered the central works of Western thought — 54 volumes, Homer to Freud — into a single 'Great Conversation.'\n\n"
            "Its spine was the Syntopicon: Adler's vast index of 102 'Great Ideas' that let a reader trace one theme — justice, the soul, time — across three thousand years of authors answering one another. It was the mid-century heir to Eliot's shelf — more philosophical, more systematic — and the foundation of the Great Books movement.\n\n"
            'A second edition in 1990 grew the set to sixty volumes, carrying the conversation into the twentieth century. Lectio shelves it in its own volume order — author and principal work, the Greeks to the moderns, each a voice the next one answers.'
        ),
        "refs": WESTERN_REFS,
    },
    'collection.eastern-canon': {
        "kind": 'series',
        "group": 'The Eastern World',
        "title": 'Great Books of the Eastern World',
        "curator": 'An original Lectio collection',
        "blurb": (
            'The essential works of the Eastern mind — Gilgamesh to the haiku — gathered as one conversation across four civilizations and four thousand years.'
        ),
        "about": (
            "Lectio's own collection of the East, built deliberately as the equal of the great Western sets — the same depth and range, sixty books deep. Four civilizations and one prologue: the Near Eastern root, India, China, Persia and the Islamic world, and Japan, set in a rough order of age.\n\n"
            "The rule is balance. Scripture and philosophy take their place, but so do the historians, the poets, and the novelists — because a library that is all Veda, Quran, and Analects records a civilization's theology, not its mind. Here the Tang poets, the Tale of Genji, and Bashō keep their seats beside the prophets and sages."
        ),
        "introduction": EASTERN_INTRO,
        "refs": EASTERN_REFS,
    },
    'collection.beyond': {
        "kind": 'series',
        "group": 'More Collections',
        "title": 'Beyond the Collections',
        "curator": 'An original Lectio collection',
        "blurb": (
            'The great works the famous lists never shelved — masterpieces Eliot and Adler overlooked, and the voices the old lists shut out.'
        ),
        "about": (
            "Every great-books list is also a list of exclusions. The Harvard Classics and the Great Books of the Western World were assembled by a few men with the tastes of their time — and they left out a great deal: almost every woman, most of the Romantic poets, the modern novel, and writers who didn't fit the mold.\n\n"
            "Beyond the Collections is Lectio's correction — not a junk drawer of leftovers but a deliberate shelf of works that belong with the greatest and were simply missed: Sappho and Ovid, Murasaki's Western sisters, Frankenstein and Walden, Douglass and Dickinson, Proust and Woolf. The conversation the old lists started, continued by the voices they left out."
        ),
        "refs": BEYOND_REFS,
    },
    'collection.harvard-classics': {
        "kind": 'series',
        "group": 'More Collections',
        "title": 'The Harvard Classics',
        "curator": 'Charles W. Eliot (1909)',
        "blurb": (
            "Dr. Eliot's famous 'Five-Foot Shelf of Books' — a 51-volume anthology assembled in 1909 to deliver a liberal education in fifteen minutes a day."
        ),
        "about": (
            'In 1909 Charles W. Eliot, newly retired after forty years as president of Harvard, set out to prove that a liberal education could fit on a shelf about five feet long. He had often said the essentials could be had by reading just fifteen minutes a day; the publisher P. F. Collier dared him to assemble the books. The result was the Harvard Classics.\n\n'
            "Fifty-one volumes gather the West's essential philosophy, history, science, poetry, drama, and scripture, each introduced for the general reader and opened by Eliot's own guide to the whole set. Sold on the famous promise of 'fifteen minutes a day,' it carried a university bookshelf into hundreds of thousands of homes and became the most influential self-education project of its century.\n\n"
            'Several of those fifty-one volumes are anthologies — Plato bound together with Epictetus and Marcus Aurelius, four philosophers gathered into one book — so Lectio unpacks them into the individual works inside, each opened on its own. That is why the shelf below counts more works than the original counted volumes: one famous five-foot shelf, here laid out as the separate books a reader actually opens.'
        ),
        "introduction": HARVARD_INTRO,
        "refs": HARVARD_REFS,
    },
    'collection.epics': {
        "kind": 'theme',
        "title": 'Epics of War & Homecoming',
        "curator": 'A Lectio theme',
        "blurb": (
            'The founding epics of the Western imagination — war, the long road home, gods and mortals, and the weight of fate.'
        ),
        "about": (
            'A Lectio theme, not a historical set — the founding epics gathered for their kinship. War and the long road home, gods and mortals, and the weight of fate, from Homer through Virgil to Dante and Milton. Read together, you watch one tradition answer itself across two thousand years.'
        ),
        "refs": EPICS_REFS,
    },
    'collection.christianity': {
        "kind": 'theme',
        "title": 'Christianity',
        "curator": 'The King James Bible & the Christian classics',
        "group": 'Religious Texts',
        "blurb": (
            'The Holy Bible, whole (its books read within) — and the great Christian writings beyond it.'
        ),
        "about": (
            "The scriptures and classics of the Christian tradition. The Holy Bible is read whole — in the King James Version of 1611, with its sixty-six books (and the Apocrypha) within it — alongside the great writings that grew around it: Augustine's Confessions and City of God, the Imitation of Christ, the Pilgrim's Progress, and Aquinas's Summa."
        ),
        "refs": CHRISTIANITY_REFS,
    },
    'collection.bible': {
        "kind": 'series',
        "group": 'Religious Texts',
        "title": 'The Bible',
        "curator": 'Read book by book',
        "blurb": (
            'The book most people mean when they say the Bible — read the way it is actually '
            'read, one book at a time, each in a clear modern edition with the King James beside it.'
        ),
        "about": (
            "The Bible is not one book but a library: sixty-six of them, written across a thousand "
            "years in three languages, by people who mostly did not know they were contributing to "
            "a collection. Lectio shelves it the way it is actually read \u2014 a book at a time, each one "
            "opening on its own, each with a clear modern edition and the King James Version a tap "
            "away.\n\n"
            "The two testaments are the Christian arrangement, and this shelf uses it because it is "
            "the one most readers arrive with. The same books appear on the Judaism shelf in their "
            "own order and under their own names, as the Tanakh \u2014 Torah, Prophets, Writings \u2014 which "
            "is not a translation of the Christian order but a different book with a different ending."
        ),
        "refs": [],
    },
    'collection.judaism': {
        "kind": 'theme',
        "title": 'Judaism',
        "curator": 'The Hebrew Bible & the Talmud',
        "group": 'Religious Texts',
        "blurb": (
            'Jewish scripture and law — the Tanakh (Torah within it) and the Talmud (Mishnah within it).'
        ),
        "about": (
            'The foundational texts of Judaism. The Tanakh is the Hebrew Bible — the Torah (the Five Books of Moses), the Prophets, and the Writings, all read within it. The Talmud is the central work of rabbinic Judaism, the Mishnah and its centuries of commentary, the record of the law argued out across generations.'
        ),
        "refs": JUDAISM_REFS,
    },
    'collection.islam': {
        "kind": 'theme',
        "title": 'Islam',
        "curator": "The Qur'an & Hadith",
        "group": 'Religious Texts',
        "blurb": (
            'The scripture of Islam and the traditions of the Prophet.'
        ),
        "about": (
            "The texts of Islam. The Qur'an is its scripture, held to be the word of God revealed to the Prophet Muhammad. The Hadith are the recorded sayings and deeds of the Prophet — the second great source, after the Qur'an, of Islamic teaching and law."
        ),
        "refs": ISLAM_REFS,
    },
}

GENRES = [
    ('Religion', "Scripture and theology from the world's faiths."),
    ('Philosophy', 'The love of wisdom — how to think, and how to live.'),
    ('History & Biography', 'The record of what happened, and the lives that shaped it.'),
    ('Science & Mathematics', 'The works that built our understanding of the natural world.'),
    ('Politics & Economics', 'Power, the state, wealth, and how we govern ourselves.'),
    ('Fiction', 'Novels and stories — the truth told through invention.'),
    ('Poetry & Epic', 'Verse and the great epics, from Homer to the moderns.'),
    ('Drama', 'The stage — tragedy and comedy across the ages.'),
    ('Essays & Letters', 'The art of thinking on the page — essays, letters, reflection.'),
]


EASTERN_KEYS = {(title, author) for title, author, _ in EASTERN_REFS}
EASTERN_KEYS.update({
    ("The Bhagavad Gita", ""),
    ("The Hadith", ""),
    ("The Qur'an", ""),
    ("The Tao Te Ching", "Laozi"),
    ("One Thousand and One Nights", ""),
})
EASTERN_TITLES = {
    "Journey to the West",
    "Layla and Majnun",
    "One Thousand and One Nights",
    "Records of the Grand Historian",
    "Romance of the Three Kingdoms",
    "The Analects",
    "The Arthashastra",
    "The Art of War",
    "The Bhagavad Gita",
    "The Book of Five Rings & Hagakure",
    "The Book of Songs",
    "The Canon of Medicine",
    "The Code of Hammurabi",
    "The Conference of the Birds",
    "The Decisive Treatise",
    "The Dhammapada",
    "The Divan",
    "The Doctrine of the Mean",
    "The Egyptian Book of the Dead",
    "The Enuma Elish",
    "The Epic of Gilgamesh",
    "The Gita Govinda",
    "The Gulistan",
    "The Hadith",
    "The Han Feizi",
    "The I Ching",
    "The Kama Sutra",
    "The Kojiki",
    "The Kokinshu",
    "The Lotus Sutra",
    "The Mahabharata",
    "The Manyoshu",
    "The Maqamat",
    "The Masnavi",
    "The Mencius",
    "The Mozi",
    "The Muqaddimah",
    "The Narrow Road to the Deep North",
    "The Panchatantra",
    "The Peony Pavilion",
    "The Pillow Book",
    "The Platform Sutra",
    "The Plays & Poems of Kalidasa",
    "The Poems of the Tang",
    "The Qur'an",
    "The Ramayana",
    "The Revival of the Religious Sciences",
    "The Rig Veda",
    "The Romance of the West Chamber",
    "The Rubaiyat",
    "The Shahnameh",
    "The Song Lyrics",
    "The Songs of Kabir",
    "The Tale of Genji",
    "The Tale of the Heike",
    "The Tao Te Ching",
    "The Tirukkural",
    "The Travels of Ibn Battuta",
    "The Upanishads",
    "The Virtuous City",
    "The Water Margin",
    "The Yoga Sutras",
    "The Zhuangzi",
    "Dream of the Red Chamber",
    "Essays in Idleness",
    "Gitanjali",
    "On the Art of the Noh Drama",
}


def _tradition_of(title, author=""):
    if (title, author) in EASTERN_KEYS or title in EASTERN_TITLES:
        return "East"
    return "West"


def _placeholder_cover(title: str) -> str:
    """Shells with no artwork still get a cover — a plain board in the house style, built
    by print/covers/build_placeholders.py. A blank card is worse than a quiet one."""
    slug = "".join(c if c.isalnum() else "-" for c in title.lower()).strip("-")
    while "--" in slug:
        slug = slug.replace("--", "-")
    return f"collections/book-covers/placeholder-{slug}.jpg"


def _ref(title, author="", part=""):
    r = WORKS[(title, author)]
    return PlannedWork(title=title, author=author, era=r.get("era", ""), part=part,
                       note=r.get("note", ""),
                       tradition=r.get("tradition", _tradition_of(title, author)),
                       cover=r.get("cover") or _placeholder_cover(title),
                       originalCover=r.get("originalCover"),
                       rights=r.get("rights"), opens=r.get("opens"))


def _genre_of(title, author=""):
    if (title, author) in WORKS:
        return WORKS[(title, author)]["genre"]
    for (t, a), r in WORKS.items():
        if t == title:
            return r["genre"]
    return REAL_GENRE.get(title, "")


# Home shelves, in reading order: Lectio (start here, ungrouped), then the two great
# canons facing each other, then the further collections. Beyond is last on purpose —
# it is the shelf you reach for once the canons are familiar.
SERIES_ORDER = [
    LECTIO_ALL,
    "collection.great-books",
    "collection.eastern-canon",
    "collection.harvard-classics",
    "collection.beyond",
    "collection.bible",
]


def _genre_slug(name):
    return "genre." + name.lower().replace(" & ", "-").replace(" ", "-")


def _first_year(era):
    """First integer in an era string, negative for BCE (for age bucketing)."""
    num = ""
    for ch in era:
        if ch.isdigit():
            num += ch
        elif num:
            break
    if not num:
        return None
    y = int(num)
    return -y if "BCE" in era.upper() else y


_WEST_AGES = [(500, "Antiquity"), (1450, "The Middle Ages"), (1650, "The Renaissance"),
              (1800, "The Enlightenment"), (1900, "The Nineteenth Century")]


def _west_part(title, author):
    y = _first_year(WORKS.get((title, author), {}).get("era", ""))
    if y is None:
        return "The Modern World"
    for bound, name in _WEST_AGES:
        if y < bound:
            return name
    return "The Modern World"


def _west_home_refs():
    """The Western home gathers every Western work — the Great Books set, the Harvard
    Classics, and Beyond the Collections — deduped and regrouped by age."""
    out, seen = [], set()
    for src in (WESTERN_REFS, HARVARD_REFS, BEYOND_REFS):
        for (t, a, _p) in src:
            if (t, a) in seen:
                continue
            seen.add((t, a))
            out.append((t, a, _west_part(t, a)))
    return out


# Which testament each biblical book belongs to on the Bible shelf.
BIBLE_PART = {
    "work.bible.genesis": "The Old Testament",
    "work.bible.mark": "The New Testament",
}


def build_collections(works):
    works = list(works)
    # A published work must never also appear as a shell: the same book would sit twice on
    # the shelf, once readable and once "coming soon".
    published = {w.title for w in works}

    series = []
    for cid, meta in COLLECTIONS.items():
        kind = meta.get("kind", "series")
        if kind not in ("series", "list"):
            continue   # themes are source-only; their books surface under Genres
        if meta.get("all_works"):
            items = [CollectionItem(workId=w.id) for w in works]
        else:
            items = [CollectionItem(workId=w.id, part=BIBLE_PART.get(w.id, ""))
                     for w in works if cid in getattr(w, "collections", [])]
        planned = [p for p in (_ref(*r) for r in meta.get("refs", []))
                   if p.title not in published]
        if not items and not planned:
            continue
        series.append(Collection(
            id=cid, title=meta["title"], curator=meta["curator"], blurb=meta["blurb"],
            about=meta.get("about"), introduction=meta.get("introduction"),
            kind=kind, group=meta.get("group"), items=items, planned=planned,
        ))
    series.sort(key=lambda c: SERIES_ORDER.index(c.id) if c.id in SERIES_ORDER else 999)

    # Genre sections, from the whole corpus (every referenced work, deduped).
    master, seen = [], set()
    for meta in COLLECTIONS.values():
        for (t, a, _p) in meta.get("refs", []):
            if (t, a) in seen:
                continue
            seen.add((t, a))
            master.append((t, a))

    genres = []
    for name, blurb in GENRES:
        gitems = [CollectionItem(workId=w.id) for w in works if _genre_of(w.title) == name]
        gplanned = [p for p in (_ref(t, a) for (t, a) in master
                                if WORKS[(t, a)]["genre"] == name)
                    if p.title not in published]
        if not gitems and not gplanned:
            continue
        genres.append(Collection(
            id=_genre_slug(name), title=name, curator="A Lectio section", blurb=blurb,
            kind="genre", items=gitems, planned=gplanned,
        ))

    return series + genres
