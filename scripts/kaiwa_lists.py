# Canonical Kaiwa scenario/dialogue scope for Fase 1 — the single source of
# truth generate_kaiwa_seed.py imports to know which dialogues to write full
# content for, mirroring how particle_lists.py / bunpou_grammar_lists.py /
# kanji_char_lists.py lock their own module's scope.
#
# Categories are situational/thematic (a conversation textbook's chapter
# list: Perkenalan, Di Restoran, ...), not JLPT-level-based like Kanji/
# Bunpou — a real conversation doesn't sort itself by grammar difficulty,
# per the explicit product decision recorded when this module was scoped.
#
# Fase 1 authors real content for 2 of the eventual categories (PERKENALAN,
# RESTORAN); the rest are locked here as PLANNED_CATEGORIES placeholders so
# _categories.json can register them as `available: False` from day one,
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

# category_id -> (display name, icon emoji)
CATEGORY_META = {
    "perkenalan": ("Perkenalan", "👋"),
    "restoran": ("Di Restoran", "🍽️"),
}

# category_id -> locked dialogue title list, for categories with real
# content in Fase 1.
AVAILABLE_CATEGORIES = {
    "perkenalan": PERKENALAN_TITLES,
    "restoran": RESTORAN_TITLES,
}

# (id, display name, icon emoji) for categories with no dataset yet —
# registered in _categories.json as available: False.
PLANNED_CATEGORIES = [
    ("stasiun", "Di Stasiun", "🚉"),
    ("belanja", "Belanja", "🛍️"),
    ("arah_jalan", "Menanyakan Arah", "🧭"),
    ("sekolah", "Di Sekolah", "🏫"),
    ("cuaca_basa_basi", "Cuaca & Basa-basi", "☁️"),
]

assert len(PERKENALAN_TITLES) == 3
assert len(RESTORAN_TITLES) == 3
assert len(PERKENALAN_TITLES) == len(set(PERKENALAN_TITLES)), "duplicate in PERKENALAN_TITLES"
assert len(RESTORAN_TITLES) == len(set(RESTORAN_TITLES)), "duplicate in RESTORAN_TITLES"

_planned_ids = [c[0] for c in PLANNED_CATEGORIES]
assert len(_planned_ids) == len(set(_planned_ids)), "duplicate id in PLANNED_CATEGORIES"
assert set(_planned_ids).isdisjoint(AVAILABLE_CATEGORIES.keys()), (
    "a planned category id collides with an available one"
)
