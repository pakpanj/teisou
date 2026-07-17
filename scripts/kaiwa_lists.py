# Canonical Kaiwa scenario/dialogue scope — the single source of truth
# generate_kaiwa_seed.py imports to know which dialogues to write full
# content for, mirroring how particle_lists.py / bunpou_grammar_lists.py /
# kanji_char_lists.py lock their own module's scope.
#
# Categories are situational/thematic (a conversation textbook's chapter
# list: Perkenalan, Di Restoran, ...), not JLPT-level-based like Kanji/
# Bunpou — a real conversation doesn't sort itself by grammar difficulty,
# per the explicit product decision recorded when this module was scoped.
#
# All 7 originally-planned categories are now authored (as of the content
# completion pass). PLANNED_CATEGORIES stays as an empty list rather than
# being deleted, so a future new category still has an obvious place to
# register as `available: False` before its dialogue list is ready,
# without a separate manual list that could drift out of sync (the same
# "don't hand-edit _categories.json and forget the word-list script"
# gotcha already documented for Kotoba applies here).

PERKENALAN_TITLES = [
    "Berkenalan dengan Teman Baru",
    "Menyapa di Pagi Hari",
    "Menanyakan Asal Negara",
]

RESTORAN_TITLES = [
    "Memesan Makanan di Restoran",
    "Meminta Bill / Membayar",
    "Menanyakan Menu Rekomendasi",
]

STASIUN_TITLES = [
    "Membeli Tiket Kereta",
    "Menanyakan Peron/Jalur",
    "Menanyakan Jadwal Kereta",
]

BELANJA_TITLES = [
    "Menanyakan Harga Barang",
    "Mencoba Baju di Toko",
    "Membayar di Kasir",
]

ARAH_JALAN_TITLES = [
    "Menanyakan Jalan ke Stasiun",
    "Menanyakan Jalan ke Toilet Umum",
    "Menanyakan Jarak Tempuh",
]

SEKOLAH_TITLES = [
    "Menyapa Guru di Kelas",
    "Menanyakan Pekerjaan Rumah (PR)",
    "Meminjam Alat Tulis",
]

CUACA_BASA_BASI_TITLES = [
    "Membicarakan Cuaca",
    "Menanyakan Kegiatan Akhir Pekan",
    "Berpamitan",
]

# category_id -> (display name, icon emoji)
CATEGORY_META = {
    "perkenalan": ("Perkenalan", "👋"),
    "restoran": ("Di Restoran", "🍽️"),
    "stasiun": ("Di Stasiun", "🚉"),
    "belanja": ("Belanja", "🛍️"),
    "arah_jalan": ("Menanyakan Arah", "🧭"),
    "sekolah": ("Di Sekolah", "🏫"),
    "cuaca_basa_basi": ("Cuaca & Basa-basi", "☁️"),
}

# category_id -> locked dialogue title list, for categories with real
# content.
AVAILABLE_CATEGORIES = {
    "perkenalan": PERKENALAN_TITLES,
    "restoran": RESTORAN_TITLES,
    "stasiun": STASIUN_TITLES,
    "belanja": BELANJA_TITLES,
    "arah_jalan": ARAH_JALAN_TITLES,
    "sekolah": SEKOLAH_TITLES,
    "cuaca_basa_basi": CUACA_BASA_BASI_TITLES,
}

# (id, display name, icon emoji) for categories with no dataset yet —
# registered in _categories.json as available: False. Empty for now; see
# the module docstring above for why this stays as a list rather than
# being removed.
PLANNED_CATEGORIES = []

_ALL_TITLE_LISTS = {
    "PERKENALAN_TITLES": PERKENALAN_TITLES,
    "RESTORAN_TITLES": RESTORAN_TITLES,
    "STASIUN_TITLES": STASIUN_TITLES,
    "BELANJA_TITLES": BELANJA_TITLES,
    "ARAH_JALAN_TITLES": ARAH_JALAN_TITLES,
    "SEKOLAH_TITLES": SEKOLAH_TITLES,
    "CUACA_BASA_BASI_TITLES": CUACA_BASA_BASI_TITLES,
}
for _name, _titles in _ALL_TITLE_LISTS.items():
    assert len(_titles) == 3, f"{_name} should have exactly 3 dialogues, has {len(_titles)}"
    assert len(_titles) == len(set(_titles)), f"duplicate title in {_name}"

_planned_ids = [c[0] for c in PLANNED_CATEGORIES]
assert len(_planned_ids) == len(set(_planned_ids)), "duplicate id in PLANNED_CATEGORIES"
assert set(_planned_ids).isdisjoint(AVAILABLE_CATEGORIES.keys()), (
    "a planned category id collides with an available one"
)
