import json

# Seed data for the Kotoba dictionary (Batch 4 — Search & Dictionary).
# 30 N5 entries across 4 categories (salam, angka, warna dasar, keluarga,
# waktu) so search/filter UI has something real to show end-to-end. To add
# more, append a tuple below with the same shape and re-run this script to
# regenerate assets/data/kotoba_data.json. There's no N4-N1 placeholder
# convention here (unlike kanji) since the level filter chips degrade
# gracefully to an empty result list for levels with no kotoba yet.

# Each tuple:
# (id_suffix, word, kanji, reading, romaji, meaning, category, wordType,
#  registers{casual,formal,keigo}, sentence_japanese, sentence_translation)
N5_KOTOBA = [
    # --- Salam ---
    ("ohayou", "おはよう", None, "ohayou", "ohayou", "selamat pagi", "salam", "expression",
     {"casual": "おはよう (ohayou)", "formal": "おはようございます (ohayou gozaimasu)", "keigo": "おはようございます (ohayou gozaimasu)"},
     "おはよう、げんきですか？", "Selamat pagi, apa kabar?"),
    ("konnichiwa", "こんにちは", None, "konnichiwa", "konnichiwa", "selamat siang", "salam", "expression",
     {"casual": "こんにちは (konnichiwa)", "formal": "こんにちは (konnichiwa)", "keigo": "こんにちは (konnichiwa)"},
     "こんにちは、はじめまして。", "Selamat siang, senang berkenalan."),
    ("konbanwa", "こんばんは", None, "konbanwa", "konbanwa", "selamat malam", "salam", "expression",
     {"casual": "こんばんは (konbanwa)", "formal": "こんばんは (konbanwa)", "keigo": "こんばんは (konbanwa)"},
     "こんばんは、お疲れさまです。", "Selamat malam, terima kasih atas kerja kerasnya."),
    ("sayounara", "さようなら", None, "sayounara", "sayounara", "selamat tinggal", "salam", "expression",
     {"casual": "またね (matane)", "formal": "さようなら (sayounara)", "keigo": "失礼します (shitsurei shimasu)"},
     "さようなら、また明日。", "Selamat tinggal, sampai besok."),
    ("arigatou", "ありがとう", None, "arigatou", "arigatou", "terima kasih", "salam", "expression",
     {"casual": "ありがとう (arigatou)", "formal": "ありがとうございます (arigatou gozaimasu)", "keigo": "誠にありがとうございます (makoto ni arigatou gozaimasu)"},
     "手伝ってくれてありがとう。", "Terima kasih sudah membantu."),

    # --- Angka 1-10 ---
    ("ichi", "いち", "一", "ichi", "ichi", "satu", "angka", "noun",
     {"casual": "いち (ichi)", "formal": "いち (ichi)", "keigo": "いち (ichi)"},
     "いちばんが好きです。", "Saya suka yang nomor satu."),
    ("ni", "に", "二", "ni", "ni", "dua", "angka", "noun",
     {"casual": "に (ni)", "formal": "に (ni)", "keigo": "に (ni)"},
     "にかいに行きます。", "Saya pergi ke lantai dua."),
    ("san", "さん", "三", "san", "san", "tiga", "angka", "noun",
     {"casual": "さん (san)", "formal": "さん (san)", "keigo": "さん (san)"},
     "さんじに会いましょう。", "Ayo bertemu jam tiga."),
    ("yon", "よん", "四", "yon", "yon", "empat", "angka", "noun",
     {"casual": "よん (yon)", "formal": "よん (yon)", "keigo": "よん (yon)"},
     "よんにんかぞくです。", "Keluarga kami berempat."),
    ("go", "ご", "五", "go", "go", "lima", "angka", "noun",
     {"casual": "ご (go)", "formal": "ご (go)", "keigo": "ご (go)"},
     "ごふんまってください。", "Tolong tunggu lima menit."),
    ("roku", "ろく", "六", "roku", "roku", "enam", "angka", "noun",
     {"casual": "ろく (roku)", "formal": "ろく (roku)", "keigo": "ろく (roku)"},
     "ろくじに起きます。", "Saya bangun jam enam."),
    ("nana", "なな", "七", "nana", "nana", "tujuh", "angka", "noun",
     {"casual": "なな (nana)", "formal": "なな (nana)", "keigo": "なな (nana)"},
     "ななつ星があります。", "Ada tujuh bintang."),
    ("hachi", "はち", "八", "hachi", "hachi", "delapan", "angka", "noun",
     {"casual": "はち (hachi)", "formal": "はち (hachi)", "keigo": "はち (hachi)"},
     "はちじに寝ます。", "Saya tidur jam delapan."),
    ("kyuu", "きゅう", "九", "kyuu", "kyuu", "sembilan", "angka", "noun",
     {"casual": "きゅう (kyuu)", "formal": "きゅう (kyuu)", "keigo": "きゅう (kyuu)"},
     "きゅうさいです。", "Umur saya sembilan tahun."),
    ("juu", "じゅう", "十", "juu", "juu", "sepuluh", "angka", "noun",
     {"casual": "じゅう (juu)", "formal": "じゅう (juu)", "keigo": "じゅう (juu)"},
     "じゅっぷんかかります。", "Butuh waktu sepuluh menit."),

    # --- Warna dasar ---
    ("aka", "あか", "赤", "aka", "aka", "merah", "warna", "noun",
     {"casual": "あか (aka)", "formal": "あか (aka)", "keigo": "あか (aka)"},
     "赤いりんごが好きです。", "Saya suka apel merah."),
    ("ao", "あお", "青", "ao", "ao", "biru", "warna", "noun",
     {"casual": "あお (ao)", "formal": "あお (ao)", "keigo": "あお (ao)"},
     "空は青いです。", "Langit berwarna biru."),
    ("kiiro", "きいろ", "黄色", "kiiro", "kiiro", "kuning", "warna", "noun",
     {"casual": "きいろ (kiiro)", "formal": "きいろ (kiiro)", "keigo": "きいろ (kiiro)"},
     "黄色い花です。", "Bunga berwarna kuning."),
    ("shiro", "しろ", "白", "shiro", "shiro", "putih", "warna", "noun",
     {"casual": "しろ (shiro)", "formal": "しろ (shiro)", "keigo": "しろ (shiro)"},
     "白い猫がいます。", "Ada kucing putih."),
    ("kuro", "くろ", "黒", "kuro", "kuro", "hitam", "warna", "noun",
     {"casual": "くろ (kuro)", "formal": "くろ (kuro)", "keigo": "くろ (kuro)"},
     "黒いかばんを買いました。", "Saya membeli tas hitam."),

    # --- Keluarga ---
    ("kazoku", "かぞく", "家族", "kazoku", "kazoku", "keluarga", "keluarga", "noun",
     {"casual": "かぞく (kazoku)", "formal": "ごかぞく (go-kazoku)", "keigo": "ごかぞく (go-kazoku)"},
     "家族は四人です。", "Keluarga saya berempat."),
    ("okaasan", "おかあさん", "お母さん", "okaasan", "okaasan", "ibu", "keluarga", "noun",
     {"casual": "ママ (mama)", "formal": "お母さん (okaasan)", "keigo": "お母様 (okaasama)"},
     "お母さんは料理が上手です。", "Ibu pandai memasak."),
    ("otousan", "おとうさん", "お父さん", "otousan", "otousan", "ayah", "keluarga", "noun",
     {"casual": "パパ (papa)", "formal": "お父さん (otousan)", "keigo": "お父様 (otousama)"},
     "お父さんは会社員です。", "Ayah bekerja sebagai karyawan kantor."),
    ("kyoudai", "きょうだい", "兄弟", "kyoudai", "kyoudai", "saudara kandung", "keluarga", "noun",
     {"casual": "きょうだい (kyoudai)", "formal": "ごきょうだい (go-kyoudai)", "keigo": "ごきょうだい (go-kyoudai)"},
     "兄弟は三人います。", "Saya punya tiga saudara kandung."),
    ("kodomo", "こども", "子供", "kodomo", "kodomo", "anak", "keluarga", "noun",
     {"casual": "こども (kodomo)", "formal": "お子さん (okosan)", "keigo": "お子様 (okosama)"},
     "子供が公園で遊んでいます。", "Anak-anak bermain di taman."),

    # --- Waktu ---
    ("kyou", "きょう", "今日", "kyou", "kyou", "hari ini", "waktu", "noun",
     {"casual": "きょう (kyou)", "formal": "きょう (kyou)", "keigo": "ほんじつ (honjitsu)"},
     "今日は暑いです。", "Hari ini panas."),
    ("ashita", "あした", "明日", "ashita", "ashita", "besok", "waktu", "noun",
     {"casual": "あした (ashita)", "formal": "あす (asu)", "keigo": "みょうにち (myounichi)"},
     "明日は休みです。", "Besok libur."),
    ("kinou", "きのう", "昨日", "kinou", "kinou", "kemarin", "waktu", "noun",
     {"casual": "きのう (kinou)", "formal": "きのう (kinou)", "keigo": "さくじつ (sakujitsu)"},
     "昨日は雨でした。", "Kemarin hujan."),
    ("ima", "いま", "今", "ima", "ima", "sekarang", "waktu", "noun",
     {"casual": "いま (ima)", "formal": "いま (ima)", "keigo": "ただいま (tadaima)"},
     "今、何時ですか。", "Sekarang jam berapa?"),
    ("jikan", "じかん", "時間", "jikan", "jikan", "waktu", "waktu", "noun",
     {"casual": "じかん (jikan)", "formal": "おじかん (o-jikan)", "keigo": "おじかん (o-jikan)"},
     "時間がありません。", "Tidak ada waktu."),
]


def build_entries():
    entries = []
    for (suffix, word, kanji, reading, romaji, meaning, category, word_type,
         registers, sentence, translation) in N5_KOTOBA:
        entries.append({
            "id": f"kotoba_{suffix}",
            "word": word,
            "kanji": kanji,
            "reading": reading,
            "romaji": romaji,
            "meaning": meaning,
            "jlptLevel": "N5",
            "category": category,
            "wordType": word_type,
            "registers": registers,
            "sentenceExample": {
                "japanese": sentence,
                "translation": translation,
            },
            "imageAsset": None,
        })
    return entries


def main():
    data = build_entries()
    with open("assets/data/kotoba_data.json", "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
    print(f"Wrote {len(data)} kotoba entries.")


if __name__ == "__main__":
    main()
