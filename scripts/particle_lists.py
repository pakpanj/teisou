# Canonical particle scope — the single source of truth
# generate_particle_seed.py imports to know which particles to write full
# content for, mirroring how kanji_char_lists.py / bunpou_grammar_lists.py
# lock their own module's scope.
#
# There is no official JLPT particle list (JLPT publishes no particle list
# at all, official or otherwise), so this follows the same "well-
# established community source, not a nonexistent authority" approach
# already used for Kanji/Bunpou: the three-way case/adverbial/sentence-
# final (格助詞/副助詞/終助詞) split is the standard taxonomy used by Tae
# Kim's Guide to Japanese Grammar (https://guidetojapanese.org/learn/) and
# cross-referenced against jlptsensei.com's particle-tagged grammar
# entries. Scope is deliberately the ~25 core particles taught at
# beginner-to-intermediate level, not an exhaustive list of every
# classical/literary/dialectal particle.
#
# Overlap with scripts/bunpou_grammar_lists.py is INTENTIONAL, not a
# scope-boundary mistake — see CLAUDE.md's Partikel section. Bunpou gives
# one terse meaning per JLPT-tagged pattern; this module catalogs a
# particle's FULL set of distinct functions side by side. Both modules
# deliberately cover the same core particles at different depths.
#
# か appears only once, under AKHIR_KALIMAT (its primary/definitional
# classification as a sentence-final question marker) — its secondary
# "か～か" (or-listing) use is modeled as a nested ParticleFunction under
# that same entry rather than a second top-level list membership, since
# ParticleEntry.category is a single value per particle. Same reasoning
# applies to の (its casual sentence-final question use is a nested
# function under its Kasus entry).

KASUS_PARTICLES = [
    "が",
    "を",
    "に",
    "で",
    "と",
    "へ",
    "から",
    "まで",
    "の",
]

KETERANGAN_PARTICLES = [
    "は",
    "も",
    "しか",
    "だけ",
    "くらい",
    "ばかり",
    "でも",
    "や",
]

AKHIR_KALIMAT_PARTICLES = [
    "か",
    "ね",
    "よ",
    "な",
    "わ",
    "ぞ",
    "ぜ",
    "さ",
]

assert len(KASUS_PARTICLES) == 9
assert len(KETERANGAN_PARTICLES) == 8
assert len(AKHIR_KALIMAT_PARTICLES) == 8

assert len(KASUS_PARTICLES) == len(set(KASUS_PARTICLES)), "duplicate in KASUS_PARTICLES"
assert len(KETERANGAN_PARTICLES) == len(set(KETERANGAN_PARTICLES)), "duplicate in KETERANGAN_PARTICLES"
assert len(AKHIR_KALIMAT_PARTICLES) == len(
    set(AKHIR_KALIMAT_PARTICLES)
), "duplicate in AKHIR_KALIMAT_PARTICLES"

# Mechanical safeguard: would have caught か living in two categories
# automatically, instead of relying on a manual re-read of both lists.
_kasus_set = set(KASUS_PARTICLES)
_keterangan_set = set(KETERANGAN_PARTICLES)
_akhir_set = set(AKHIR_KALIMAT_PARTICLES)
assert _kasus_set & _keterangan_set == set(), "KASUS/KETERANGAN overlap"
assert _kasus_set & _akhir_set == set(), "KASUS/AKHIR_KALIMAT overlap"
assert _keterangan_set & _akhir_set == set(), "KETERANGAN/AKHIR_KALIMAT overlap"

ALL_PARTICLES = KASUS_PARTICLES + KETERANGAN_PARTICLES + AKHIR_KALIMAT_PARTICLES
assert len(ALL_PARTICLES) == 25
assert len(ALL_PARTICLES) == len(set(ALL_PARTICLES)), "duplicate across categories"
