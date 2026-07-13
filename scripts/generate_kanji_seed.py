import json

# Seed data for the Kanji dictionary (Batch 4 — Search & Dictionary).
# Real content only exists for N5 so far (15 basic kanji); N4-N1 get
# "placeholder": true marker rows so getByLevel() still returns something
# for every level instead of an empty list. To add a real kanji, replace a
# placeholder row (or append a new one) with the same shape as the N5
# entries below and set jlptLevel/svgAsset/examples accordingly. Re-run
# this script to regenerate assets/data/kanji_data.json.

# Each tuple: (id_suffix, character, onyomi, kunyomi, meanings, strokeCount, examples)
# examples: list of (word, reading, meaning, sentence, sentenceTranslation)
N5_KANJI = [
    ("ichi", "一", ["イチ", "イツ"], ["ひと", "ひと-つ"], ["satu", "one"], 1, [
        ("一つ", "hitotsu", "satu (unit)", "りんごを一つください。", "Tolong satu apel."),
    ]),
    ("ni", "二", ["ニ"], ["ふた", "ふた-つ"], ["dua", "two"], 2, [
        ("二つ", "futatsu", "dua (unit)", "みかんを二つ買いました。", "Saya membeli dua jeruk."),
    ]),
    ("san", "三", ["サン"], ["み", "み-つ"], ["tiga", "three"], 3, [
        ("三つ", "mittsu", "tiga (unit)", "卵を三つ使います。", "Saya memakai tiga telur."),
    ]),
    ("yon", "四", ["シ"], ["よ", "よん", "よ-つ"], ["empat", "four"], 5, [
        ("四月", "shigatsu", "bulan April", "四月に日本へ行きます。", "Saya pergi ke Jepang bulan April."),
    ]),
    ("go", "五", ["ゴ"], ["いつ", "いつ-つ"], ["lima", "five"], 4, [
        ("五つ", "itsutsu", "lima (unit)", "五つの部屋があります。", "Ada lima kamar."),
    ]),
    ("roku", "六", ["ロク"], ["む", "む-つ"], ["enam", "six"], 4, [
        ("六月", "rokugatsu", "bulan Juni", "六月は雨が多いです。", "Bulan Juni banyak hujan."),
    ]),
    ("shichi", "七", ["シチ"], ["なな", "なな-つ"], ["tujuh", "seven"], 2, [
        ("七つ", "nanatsu", "tujuh (unit)", "七つの星が見えます。", "Terlihat tujuh bintang."),
    ]),
    ("hachi", "八", ["ハチ"], ["や", "や-つ"], ["delapan", "eight"], 2, [
        ("八月", "hachigatsu", "bulan Agustus", "八月はとても暑いです。", "Bulan Agustus sangat panas."),
    ]),
    ("kyuu", "九", ["キュウ", "ク"], ["ここの", "ここの-つ"], ["sembilan", "nine"], 2, [
        ("九つ", "kokonotsu", "sembilan (unit)", "九つの箱があります。", "Ada sembilan kotak."),
    ]),
    ("juu", "十", ["ジュウ"], ["とお"], ["sepuluh", "ten"], 2, [
        ("十日", "tooka", "tanggal sepuluh / sepuluh hari", "十日に会いましょう。", "Ayo bertemu tanggal sepuluh."),
    ]),
    ("hito", "人", ["ジン", "ニン"], ["ひと"], ["orang", "person"], 2, [
        ("日本人", "nihonjin", "orang Jepang", "彼は日本人です。", "Dia orang Jepang."),
    ]),
    ("hi", "日", ["ニチ", "ジツ"], ["ひ", "か"], ["hari", "matahari", "sun/day"], 4, [
        ("日曜日", "nichiyoubi", "hari Minggu", "日曜日は休みです。", "Hari Minggu libur."),
    ]),
    ("tsuki", "月", ["ゲツ", "ガツ"], ["つき"], ["bulan", "moon/month"], 4, [
        ("月曜日", "getsuyoubi", "hari Senin", "月曜日から学校です。", "Sekolah mulai hari Senin."),
    ]),
    ("yama", "山", ["サン"], ["やま"], ["gunung", "mountain"], 3, [
        ("富士山", "fujisan", "Gunung Fuji", "富士山はきれいです。", "Gunung Fuji indah."),
    ]),
    ("kawa", "川", ["セン"], ["かわ"], ["sungai", "river"], 3, [
        ("川", "kawa", "sungai", "川で泳ぎました。", "Saya berenang di sungai."),
    ]),
]

PLACEHOLDER_COUNTS = {"N4": 5, "N3": 5, "N2": 5, "N1": 5}


def build_n5_entries():
    entries = []
    for suffix, char, on, kun, meanings, strokes, examples in N5_KANJI:
        entries.append({
            "id": f"kanji_{suffix}",
            "character": char,
            "jlptLevel": "N5",
            "onyomi": on,
            "kunyomi": kun,
            "meanings": meanings,
            "strokeCount": strokes,
            "svgAsset": f"assets/svg/kanji/{suffix}.svg",
            "examples": [
                {
                    "word": word,
                    "reading": reading,
                    "meaning": meaning,
                    "sentence": sentence,
                    "sentenceTranslation": translation,
                }
                for word, reading, meaning, sentence, translation in examples
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
                "examples": [],
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
