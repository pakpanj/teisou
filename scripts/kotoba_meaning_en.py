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
    Done (10, all of "Alam & Lingkungan"): ikan, hewan_darat, burung,
    serangga, pohon, bunga_tanaman, buah, sayuran, cuaca, bencana_alam
    (145/1266 words). Remaining: 35 categories, 1121 words.
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
    "hewan_darat": {
        "kotoba_hewan_darat_inu": "dog",
        "kotoba_hewan_darat_neko": "cat",
        "kotoba_hewan_darat_usagi": "rabbit",
        "kotoba_hewan_darat_zou": "elephant",
        "kotoba_hewan_darat_raion": "lion",
        "kotoba_hewan_darat_tora": "tiger",
        "kotoba_hewan_darat_kuma": "bear",
        "kotoba_hewan_darat_saru": "monkey",
        "kotoba_hewan_darat_uma": "horse",
        "kotoba_hewan_darat_ushi": "cow",
        "kotoba_hewan_darat_buta": "pig",
        "kotoba_hewan_darat_hitsuji": "sheep",
        "kotoba_hewan_darat_panda": "panda",
        "kotoba_hewan_darat_kirin": "giraffe",
        "kotoba_hewan_darat_nezumi": "mouse",
        "kotoba_hewan_darat_shika": "deer",
        "kotoba_hewan_darat_koala": "koala",
        "kotoba_hewan_darat_kame": "turtle",
        "kotoba_hewan_darat_hebi": "snake",
        "kotoba_hewan_darat_kaeru": "frog",
        "kotoba_hewan_darat_risu": "squirrel",
        "kotoba_hewan_darat_ookami": "wolf",
    },
    "burung": {
        "kotoba_burung_tori": "bird",
        "kotoba_burung_niwatori": "chicken",
        "kotoba_burung_ahiru": "duck",
        "kotoba_burung_suzume": "sparrow",
        "kotoba_burung_karasu": "crow",
        "kotoba_burung_hato": "pigeon/dove",
        "kotoba_burung_tsuru": "crane",
        "kotoba_burung_fukurou": "owl",
        "kotoba_burung_taka": "hawk",
        "kotoba_burung_pengin": "penguin",
        "kotoba_burung_hakuchou": "swan",
        "kotoba_burung_kiji": "pheasant (Japan's national bird)",
        "kotoba_burung_inko": "parakeet",
        "kotoba_burung_kodori": "small bird",
    },
    "serangga": {
        "kotoba_serangga_mushi": "insect/bug",
        "kotoba_serangga_chou": "butterfly",
        "kotoba_serangga_hachi": "bee",
        "kotoba_serangga_ari": "ant",
        "kotoba_serangga_ka": "mosquito",
        "kotoba_serangga_hae": "fly",
        "kotoba_serangga_kumo": "spider",
        "kotoba_serangga_tonbo": "dragonfly",
        "kotoba_serangga_semi": "cicada",
        "kotoba_serangga_kabutomushi": "rhinoceros beetle",
        "kotoba_serangga_tentoumushi": "ladybug",
        "kotoba_serangga_batta": "grasshopper",
        "kotoba_serangga_kuwagata": "stag beetle",
    },
    "pohon": {
        "kotoba_pohon_ki": "tree",
        "kotoba_pohon_sakura": "cherry blossom tree",
        "kotoba_pohon_matsu": "pine tree",
        "kotoba_pohon_take": "bamboo",
        "kotoba_pohon_momiji": "maple tree (momiji)",
        "kotoba_pohon_yashi": "palm/coconut tree",
        "kotoba_pohon_ichou": "ginkgo tree",
        "kotoba_pohon_sugi": "Japanese cedar tree",
    },
    "bunga_tanaman": {
        "kotoba_bunga_tanaman_hana": "flower",
        "kotoba_bunga_tanaman_bara": "rose",
        "kotoba_bunga_tanaman_yuri": "lily",
        "kotoba_bunga_tanaman_himawari": "sunflower",
        "kotoba_bunga_tanaman_tanpopo": "dandelion",
        "kotoba_bunga_tanaman_ajisai": "hydrangea",
        "kotoba_bunga_tanaman_sumire": "violet",
        "kotoba_bunga_tanaman_ume": "plum blossom/tree (ume)",
        "kotoba_bunga_tanaman_shokubutsu": "plant",
        "kotoba_bunga_tanaman_kusabana": "flowering plants",
        "kotoba_bunga_tanaman_shibafu": "lawn/turf grass",
    },
    "buah": {
        "kotoba_buah_ringo": "apple",
        "kotoba_buah_banana": "banana",
        "kotoba_buah_mikan": "mandarin orange",
        "kotoba_buah_budou": "grape",
        "kotoba_buah_momo": "peach",
        "kotoba_buah_suika": "watermelon",
        "kotoba_buah_ichigo": "strawberry",
        "kotoba_buah_nashi": "Asian pear",
        "kotoba_buah_kaki": "persimmon",
        "kotoba_buah_remon": "lemon",
        "kotoba_buah_meron": "melon",
        "kotoba_buah_papaiya": "papaya",
        "kotoba_buah_anzu": "apricot",
        "kotoba_buah_sakuranbo": "cherry",
    },
    "sayuran": {
        "kotoba_sayuran_yasai": "vegetable (general)",
        "kotoba_sayuran_ninjin": "carrot",
        "kotoba_sayuran_jagaimo": "potato",
        "kotoba_sayuran_tamanegi": "onion",
        "kotoba_sayuran_kyabetsu": "cabbage",
        "kotoba_sayuran_tomato": "tomato",
        "kotoba_sayuran_kyuuri": "cucumber",
        "kotoba_sayuran_nasu": "eggplant",
        "kotoba_sayuran_daikon": "daikon radish",
        "kotoba_sayuran_hourensou": "spinach",
        "kotoba_sayuran_piiman": "green bell pepper",
        "kotoba_sayuran_renkon": "lotus root",
        "kotoba_sayuran_negi": "green onion/scallion",
        "kotoba_sayuran_ninniku": "garlic",
    },
    "cuaca": {
        "kotoba_cuaca_tenki": "weather",
        "kotoba_cuaca_hare": "sunny/clear",
        "kotoba_cuaca_ame": "rain",
        "kotoba_cuaca_kumori": "cloudy",
        "kotoba_cuaca_yuki": "snow",
        "kotoba_cuaca_kaze": "wind",
        "kotoba_cuaca_kaminari": "thunder/lightning",
        "kotoba_cuaca_kiri": "fog",
        "kotoba_cuaca_taifuu": "typhoon",
        "kotoba_cuaca_niji": "rainbow",
        "kotoba_cuaca_tsuyu": "rainy season (Japan)",
        "kotoba_cuaca_hyou": "hail",
        "kotoba_cuaca_shitsudo": "humidity",
        "kotoba_cuaca_kiatsu": "air pressure",
        "kotoba_cuaca_mousho": "extreme heat",
        "kotoba_cuaca_kanpa": "cold wave",
        "kotoba_cuaca_tenkiyohou": "weather forecast",
        "kotoba_cuaca_aozora": "blue sky",
        "kotoba_cuaca_kansou": "drying/dryness",
        "kotoba_cuaca_kion": "air temperature",
        "kotoba_cuaca_kouon": "high temperature",
        "kotoba_cuaca_nikkou": "sunlight",
        "kotoba_cuaca_kuuki": "air",
    },
    "bencana_alam": {
        "kotoba_bencana_alam_jishin": "earthquake",
        "kotoba_bencana_alam_tsunami": "tsunami",
        "kotoba_bencana_alam_kouzui": "flood",
        "kotoba_bencana_alam_kaji": "fire",
        "kotoba_bencana_alam_funka": "volcanic eruption",
        "kotoba_bencana_alam_teiden": "power outage",
        "kotoba_bencana_alam_kazan": "volcano",
        "kotoba_bencana_alam_hinan": "evacuation",
        "kotoba_bencana_alam_arashi": "storm",
        "kotoba_bencana_alam_bousai": "disaster prevention/mitigation",
        "kotoba_bencana_alam_hinanjo": "evacuation shelter",
        "kotoba_bencana_alam_fukkyuu": "recovery (post-disaster)",
        "kotoba_bencana_alam_houkai": "collapse",
        "kotoba_bencana_alam_hisai": "being disaster-stricken",
        "kotoba_bencana_alam_songai": "damage/loss",
        "kotoba_bencana_alam_kyuujo": "rescue",
        "kotoba_bencana_alam_tatsumaki": "tornado",
        "kotoba_bencana_alam_kasai": "fire (formal term)",
    },
    # Add the next category here, e.g.:
    # "makanan_jepang": {
    #     "kotoba_makanan_jepang_...": "...",
    # },
}
