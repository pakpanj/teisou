"""
kotoba_meaning_en.py

Locked source of truth for Kotoba's English word-meaning translations
(the `meaningEn` field on `KotobaEntry` — see lib/data/models/kotoba_entry.dart
and CLAUDE.md's "Correction, Kotoba only" note under the language-toggle
section for the full story). Same locked-list pattern as
dokkai_lists.py/bunpou_grammar_lists.py: this file is the only place
translations get authored; apply_kotoba_meaning_en.py reads it and
patches the real JSON files, so there's never a second copy to keep in
sync by hand.

STATUS (update this line every time a category is finished):
    Done: ikan (8/8). Remaining: 44 categories, ~511 words.
    See CLAUDE.md's Kotoba-localization note for the full per-category
    checklist and the exact workflow to add a new category here.

Structure: one dict per category id, mapping the word's `id` (from that
category's assets/data/kotoba/{category_id}.json) to a short English
gloss — translate what `meaning` already says, don't invent new content.
Keep entries in the same order as the JSON file for easy side-by-side
diffing while authoring.

Cara pakai (nambah kategori baru):
    1. Buka assets/data/kotoba/{category_id}.json, baca tiap `id` + `meaning`.
    2. Tambah dict baru di MEANING_EN, key = category_id, isi id -> english.
    3. Jalankan: python scripts/apply_kotoba_meaning_en.py {category_id}
       (atau tanpa argumen buat proses SEMUA kategori yang ada di dict ini).
    4. Cek output-nya: "Patched N/N" harus match jumlah kata di kategori itu,
       dan tidak ada "GAGAL"/id yang tidak ketemu.
    5. flutter analyze / flutter test, lalu commit.
"""

MEANING_EN: dict[str, dict[str, str]] = {
    "ikan": {
        "kotoba_ikan_maguro": "tuna",
        "kotoba_ikan_sake": "salmon",
        "kotoba_ikan_tai": "red seabream",
        "kotoba_ikan_unagi": "eel",
        "kotoba_ikan_iwashi": "sardine",
        "kotoba_ikan_saba": "mackerel",
        "kotoba_ikan_katsuo": "bonito (skipjack tuna)",
        "kotoba_ikan_fugu": "pufferfish (fugu)",
    },
    # Add the next category here, e.g.:
    # "hewan_darat": {
    #     "kotoba_hewan_darat_inu": "dog",
    #     ...
    # },
}
