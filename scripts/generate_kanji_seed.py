import json

# Seed data for the Kanji dictionary (Batch 4, restructured for Batch 7).
#
# Batch 7 split the old flat "one word + one embedded sentence" example
# shape into two separate lists — wordExamples ("contoh kata") and
# sentenceExamples ("contoh kalimat", now with romaji) — matching how
# KanjiEntry.examples is now a *computed* backward-compat getter (pairs
# wordExamples[i] with sentenceExamples[i]) rather than a stored field, so
# `search/kanji_detail_screen.dart` keeps working unchanged.
#
# This pass only *migrates* the 15 existing N5 entries to the new shape
# (added romaji + radical, still one word/one sentence each) to prove the
# schema end-to-end — bringing every N5 kanji up to the Fase 1 minimum of
# 3 word examples / 2 sentence examples happens in the full N5+N4 dataset
# pass (see generate_kanji_n5.py / generate_kanji_n4.py once those land).
#
# Each tuple: (id_suffix, character, onyomi, kunyomi, meanings, strokeCount,
#              radical, word_examples, sentence_examples)
# word_examples: list of (word, reading, meaning)
# sentence_examples: list of (japanese, romaji, translation)
N5_KANJI = [
    ("ichi", "一", ["イチ", "イツ"], ["ひと", "ひと-つ"], ["satu", "one"], 1, "一", [
        ("一つ", "hitotsu", "satu (unit)"),
    ], [
        ("りんごを一つください。", "Ringo o hitotsu kudasai.", "Tolong satu apel."),
    ]),
    ("ni", "二", ["ニ"], ["ふた", "ふた-つ"], ["dua", "two"], 2, "二", [
        ("二つ", "futatsu", "dua (unit)"),
    ], [
        ("みかんを二つ買いました。", "Mikan o futatsu kaimashita.", "Saya membeli dua jeruk."),
    ]),
    ("san", "三", ["サン"], ["み", "み-つ"], ["tiga", "three"], 3, "一", [
        ("三つ", "mittsu", "tiga (unit)"),
    ], [
        ("卵を三つ使います。", "Tamago o mittsu tsukaimasu.", "Saya memakai tiga telur."),
    ]),
    ("yon", "四", ["シ"], ["よ", "よん", "よ-つ"], ["empat", "four"], 5, "囗", [
        ("四月", "shigatsu", "bulan April"),
    ], [
        ("四月に日本へ行きます。", "Shigatsu ni Nihon e ikimasu.", "Saya pergi ke Jepang bulan April."),
    ]),
    ("go", "五", ["ゴ"], ["いつ", "いつ-つ"], ["lima", "five"], 4, "二", [
        ("五つ", "itsutsu", "lima (unit)"),
    ], [
        ("五つの部屋があります。", "Itsutsu no heya ga arimasu.", "Ada lima kamar."),
    ]),
    ("roku", "六", ["ロク"], ["む", "む-つ"], ["enam", "six"], 4, "八", [
        ("六月", "rokugatsu", "bulan Juni"),
    ], [
        ("六月は雨が多いです。", "Rokugatsu wa ame ga ooi desu.", "Bulan Juni banyak hujan."),
    ]),
    ("shichi", "七", ["シチ"], ["なな", "なな-つ"], ["tujuh", "seven"], 2, "一", [
        ("七つ", "nanatsu", "tujuh (unit)"),
    ], [
        ("七つの星が見えます。", "Nanatsu no hoshi ga miemasu.", "Terlihat tujuh bintang."),
    ]),
    ("hachi", "八", ["ハチ"], ["や", "や-つ"], ["delapan", "eight"], 2, "八", [
        ("八月", "hachigatsu", "bulan Agustus"),
    ], [
        ("八月はとても暑いです。", "Hachigatsu wa totemo atsui desu.", "Bulan Agustus sangat panas."),
    ]),
    ("kyuu", "九", ["キュウ", "ク"], ["ここの", "ここの-つ"], ["sembilan", "nine"], 2, "乙", [
        ("九つ", "kokonotsu", "sembilan (unit)"),
    ], [
        ("九つの箱があります。", "Kokonotsu no hako ga arimasu.", "Ada sembilan kotak."),
    ]),
    ("juu", "十", ["ジュウ"], ["とお"], ["sepuluh", "ten"], 2, "十", [
        ("十日", "tooka", "tanggal sepuluh / sepuluh hari"),
    ], [
        ("十日に会いましょう。", "Tooka ni aimashou.", "Ayo bertemu tanggal sepuluh."),
    ]),
    ("hito", "人", ["ジン", "ニン"], ["ひと"], ["orang", "person"], 2, "人", [
        ("日本人", "nihonjin", "orang Jepang"),
    ], [
        ("彼は日本人です。", "Kare wa nihonjin desu.", "Dia orang Jepang."),
    ]),
    ("hi", "日", ["ニチ", "ジツ"], ["ひ", "か"], ["hari", "matahari", "sun/day"], 4, "日", [
        ("日曜日", "nichiyoubi", "hari Minggu"),
    ], [
        ("日曜日は休みです。", "Nichiyoubi wa yasumi desu.", "Hari Minggu libur."),
    ]),
    ("tsuki", "月", ["ゲツ", "ガツ"], ["つき"], ["bulan", "moon/month"], 4, "月", [
        ("月曜日", "getsuyoubi", "hari Senin"),
    ], [
        ("月曜日から学校です。", "Getsuyoubi kara gakkou desu.", "Sekolah mulai hari Senin."),
    ]),
    ("yama", "山", ["サン"], ["やま"], ["gunung", "mountain"], 3, "山", [
        ("富士山", "fujisan", "Gunung Fuji"),
    ], [
        ("富士山はきれいです。", "Fujisan wa kirei desu.", "Gunung Fuji indah."),
    ]),
    ("kawa", "川", ["セン"], ["かわ"], ["sungai", "river"], 3, "川", [
        ("川", "kawa", "sungai"),
    ], [
        ("川で泳ぎました。", "Kawa de oyogimashita.", "Saya berenang di sungai."),
    ]),
]

PLACEHOLDER_COUNTS = {"N4": 5, "N3": 5, "N2": 5, "N1": 5}


def build_n5_entries():
    entries = []
    for suffix, char, on, kun, meanings, strokes, radical, word_examples, sentence_examples in N5_KANJI:
        entries.append({
            "id": f"kanji_{suffix}",
            "character": char,
            "jlptLevel": "N5",
            "onyomi": on,
            "kunyomi": kun,
            "meanings": meanings,
            "strokeCount": strokes,
            "svgAsset": f"assets/kanjivg/{ord(char):05x}.svg",
            "radical": radical,
            "wordExamples": [
                {"word": word, "reading": reading, "meaning": meaning}
                for word, reading, meaning in word_examples
            ],
            "sentenceExamples": [
                {"japanese": jp, "romaji": ro, "translation": tr}
                for jp, ro, tr in sentence_examples
            ],
            "relatedBunpou": [],
        })
    return entries


def build_placeholder_entries():
    entries = []
    for level, count in PLACEHOLDER_COUNTS.items():
        for i in range(1, count + 1):
            entries.append({
                "id": f"kanji_{level.lower()}_placeholder_{i}",
                "character": "",
                "jlptLevel": level,
                "onyomi": [],
                "kunyomi": [],
                "meanings": [],
                "strokeCount": 0,
                "svgAsset": None,
                "radical": None,
                "wordExamples": [],
                "sentenceExamples": [],
                "relatedBunpou": [],
                "placeholder": True,
            })
    return entries


def main():
    data = build_n5_entries() + build_placeholder_entries()
    with open("assets/data/kanji_data.json", "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
    print(f"Wrote {len(data)} kanji entries ({len(N5_KANJI)} real N5 + "
          f"{sum(PLACEHOLDER_COUNTS.values())} placeholders).")


if __name__ == "__main__":
    main()
