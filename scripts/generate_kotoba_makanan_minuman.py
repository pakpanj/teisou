import json

# Kotoba vocab — grup "Makanan & Minuman" (Batch 7).
# Nomina konkret (nama makanan/minuman/bumbu/alat) pakai pola registers apa
# adanya seperti generate_kotoba_alam.py. cara_memasak beda: isinya kata
# kerja (verb), jadi casual/formal betulan berbeda (bentuk kamus vs ~masu),
# bukan honest-fallback — itu tata bahasa dasar yang tidak ambigu.
#
# Each tuple: (id_suffix, kanji_or_None, hiragana, romaji, meaning, jlptLevel, examples)


def _plain_registers(word, romaji, noun_label):
    return {
        "casual": f"{word} ({romaji})",
        "formal": f"{word} ({romaji}) — kesopanan ada di kalimat, mis. '~です' / '~があります'",
        "keigo": f"{word} ({romaji}) — tidak ada bentuk keigo khusus untuk {noun_label}",
    }


def _verb_registers(dict_form, dict_romaji, masu_form, masu_romaji):
    return {
        "casual": f"{dict_form} ({dict_romaji})",
        "formal": f"{masu_form} ({masu_romaji})",
        "keigo": f"{dict_form} ({dict_romaji}) — tidak ada bentuk keigo khusus untuk kata kerja memasak ini",
    }


CATEGORIES = {
    "makanan_jepang": ("nama makanan", "noun", [
        ("sushi", "寿司", "すし", "sushi", "sushi", "N4", [
            ("寿司が好きです。", "Sushi ga suki desu.", "Saya suka sushi."),
        ]),
        ("ramen", None, "ラーメン", "ramen", "ramen (mi kuah)", "N5", [
            ("ラーメンを食べます。", "Ramen o tabemasu.", "Saya makan ramen."),
        ]),
        ("udon", None, "うどん", "udon", "udon (mi tebal)", "N4", [
            ("うどんは太いです。", "Udon wa futoi desu.", "Udon itu tebal (mi-nya)."),
        ]),
        ("soba", "蕎麦", "そば", "soba", "soba (mi soba)", "N4", [
            ("そばを食べました。", "Soba o tabemashita.", "Saya sudah makan soba."),
        ]),
        ("tenpura", "天ぷら", "てんぷら", "tenpura", "tempura (gorengan)", "N4", [
            ("天ぷらはサクサクです。", "Tenpura wa sakusaku desu.", "Tempura itu renyah."),
        ]),
        ("sashimi", "刺身", "さしみ", "sashimi", "sashimi (ikan mentah)", "N3", [
            ("刺身は新鮮です。", "Sashimi wa shinsen desu.", "Sashimi itu segar."),
        ]),
        ("onigiri", None, "おにぎり", "onigiri", "onigiri (nasi kepal)", "N4", [
            ("おにぎりを作ります。", "Onigiri o tsukurimasu.", "Saya membuat onigiri."),
        ]),
        ("misoshiru", "味噌汁", "みそしる", "misoshiru", "sup miso", "N4", [
            ("朝、味噌汁を飲みます。", "Asa, misoshiru o nomimasu.", "Pagi hari, saya minum sup miso."),
        ]),
        ("gyouza", "餃子", "ぎょうざ", "gyouza", "pangsit goreng (gyoza)", "N3", [
            ("餃子は美味しいです。", "Gyouza wa oishii desu.", "Gyoza itu enak."),
        ]),
        ("okonomiyaki", None, "おこのみやき", "okonomiyaki", "okonomiyaki (pancake gurih)", "N2", [
            ("お好み焼きは大阪の名物です。", "Okonomiyaki wa Oosaka no meibutsu desu.", "Okonomiyaki adalah makanan khas Osaka."),
        ]),
        ("karaage", "唐揚げ", "からあげ", "karaage", "ayam goreng ala Jepang", "N3", [
            ("唐揚げが大好きです。", "Karaage ga daisuki desu.", "Saya sangat suka karaage."),
        ]),
        ("katsudon", None, "かつどん", "katsudon", "nasi dengan katsu (daging goreng tepung)", "N3", [
            ("かつ丼を注文しました。", "Katsudon o chuumon shimashita.", "Saya memesan katsudon."),
        ]),
        ("nattou", "納豆", "なっとう", "nattou", "natto (kedelai fermentasi)", "N3", [
            ("納豆は匂いが強いです。", "Nattou wa nioi ga tsuyoi desu.", "Natto baunya kuat."),
        ]),
        ("takoyaki", None, "たこやき", "takoyaki", "takoyaki (bola gurita)", "N3", [
            ("たこ焼きを食べたいです。", "Takoyaki o tabetai desu.", "Saya ingin makan takoyaki."),
        ]),
        ("yakitori", "焼き鳥", "やきとり", "yakitori", "sate ayam Jepang", "N3", [
            ("焼き鳥屋に行きます。", "Yakitoriya ni ikimasu.", "Saya pergi ke kedai yakitori."),
        ]),
    ]),
    "makanan_indonesia": ("nama makanan", "noun", [
        ("nasigoreng", None, "ナシゴレン", "nashigoren", "nasi goreng", "N3", [
            ("ナシゴレンはインドネシアの料理です。", "Nashigoren wa Indoneshia no ryouri desu.", "Nasi goreng adalah masakan Indonesia."),
        ]),
        ("miegoreng", None, "ミーゴレン", "miigoren", "mie goreng", "N3", [
            ("ミーゴレンを食べました。", "Miigoren o tabemashita.", "Saya sudah makan mie goreng."),
        ]),
        ("sate", None, "サテ", "sate", "sate", "N3", [
            ("サテは串焼きです。", "Sate wa kushiyaki desu.", "Sate adalah makanan panggang tusuk."),
        ]),
        ("gadogado", None, "ガドガド", "gadogado", "gado-gado", "N3", [
            ("ガドガドは野菜料理です。", "Gadogado wa yasai ryouri desu.", "Gado-gado adalah masakan sayuran."),
        ]),
        ("rendang", None, "ルンダン", "rundan", "rendang", "N3", [
            ("ルンダンは辛いです。", "Rundan wa karai desu.", "Rendang itu pedas."),
        ]),
        ("tempe", None, "テンペ", "tenpe", "tempe", "N3", [
            ("テンペは大豆から作ります。", "Tenpe wa daizu kara tsukurimasu.", "Tempe dibuat dari kedelai."),
        ]),
        ("sambal", None, "サンバル", "sanbaru", "sambal", "N3", [
            ("サンバルは辛いソースです。", "Sanbaru wa karai soosu desu.", "Sambal adalah saus pedas."),
        ]),
    ]),
    "makanan_barat": ("nama makanan", "noun", [
        ("pan", None, "パン", "pan", "roti", "N5", [
            ("パンを食べます。", "Pan o tabemasu.", "Saya makan roti."),
        ]),
        ("hanbaagaa", None, "ハンバーガー", "hanbaagaa", "hamburger", "N5", [
            ("ハンバーガーを買いました。", "Hanbaagaa o kaimashita.", "Saya membeli hamburger."),
        ]),
        ("piza", None, "ピザ", "piza", "pizza", "N5", [
            ("ピザが好きです。", "Piza ga suki desu.", "Saya suka pizza."),
        ]),
        ("pasuta", None, "パスタ", "pasuta", "pasta", "N4", [
            ("パスタを作ります。", "Pasuta o tsukurimasu.", "Saya membuat pasta."),
        ]),
        ("sarada", None, "サラダ", "sarada", "salad", "N5", [
            ("サラダを食べましょう。", "Sarada o tabemashou.", "Ayo makan salad."),
        ]),
        ("suteeki", None, "ステーキ", "suteeki", "steak", "N4", [
            ("ステーキを注文しました。", "Suteeki o chuumon shimashita.", "Saya memesan steak."),
        ]),
        ("suupu", None, "スープ", "suupu", "sup", "N5", [
            ("スープは温かいです。", "Suupu wa atatakai desu.", "Sup itu hangat."),
        ]),
        ("sandoicchi", None, "サンドイッチ", "sandoicchi", "sandwich", "N4", [
            ("サンドイッチを作ります。", "Sandoicchi o tsukurimasu.", "Saya membuat sandwich."),
        ]),
        ("omuretsu", None, "オムレツ", "omuretsu", "omelet", "N4", [
            ("朝食にオムレツを食べます。", "Choushoku ni omuretsu o tabemasu.", "Saya makan omelet untuk sarapan."),
        ]),
        ("furaidopoteto", None, "フライドポテト", "furaido poteto", "kentang goreng", "N4", [
            ("フライドポテトが好きです。", "Furaido poteto ga suki desu.", "Saya suka kentang goreng."),
        ]),
        ("chiizu", None, "チーズ", "chiizu", "keju", "N4", [
            ("チーズはミルクから作ります。", "Chiizu wa miruku kara tsukurimasu.", "Keju dibuat dari susu."),
        ]),
        ("dezaato", None, "デザート", "dezaato", "hidangan penutup (dessert)", "N4", [
            ("デザートを食べましょう。", "Dezaato o tabemashou.", "Ayo makan dessert."),
        ]),
        ("keeki", None, "ケーキ", "keeki", "kue (cake)", "N5", [
            ("誕生日にケーキを食べます。", "Tanjoubi ni keeki o tabemasu.", "Saya makan kue di hari ulang tahun."),
        ]),
        ("supagetti", None, "スパゲッティ", "supagetti", "spageti", "N4", [
            ("スパゲッティを茹でます。", "Supagetti o yudemasu.", "Saya merebus spageti."),
        ]),
    ]),
    "minuman": ("nama minuman", "noun", [
        ("mizu", "水", "みず", "mizu", "air", "N5", [
            ("水を飲みます。", "Mizu o nomimasu.", "Saya minum air."),
        ]),
        ("ocha", "お茶", "おちゃ", "ocha", "teh (Jepang)", "N5", [
            ("お茶をどうぞ。", "Ocha o douzo.", "Silakan minum teh."),
        ]),
        ("koucha", "紅茶", "こうちゃ", "koucha", "teh hitam", "N4", [
            ("紅茶に砂糖を入れます。", "Koucha ni satou o iremasu.", "Saya memasukkan gula ke teh hitam."),
        ]),
        ("koohii", None, "コーヒー", "koohii", "kopi", "N5", [
            ("毎朝コーヒーを飲みます。", "Maiasa koohii o nomimasu.", "Saya minum kopi setiap pagi."),
        ]),
        ("gyuunyuu", "牛乳", "ぎゅうにゅう", "gyuunyuu", "susu sapi", "N4", [
            ("牛乳を買いました。", "Gyuunyuu o kaimashita.", "Saya membeli susu."),
        ]),
        ("juusu", None, "ジュース", "juusu", "jus", "N5", [
            ("ジュースを飲みます。", "Juusu o nomimasu.", "Saya minum jus."),
        ]),
        ("koora", None, "コーラ", "koora", "cola", "N4", [
            ("コーラは甘いです。", "Koora wa amai desu.", "Cola itu manis."),
        ]),
        ("biiru", None, "ビール", "biiru", "bir", "N4", [
            ("ビールを飲みます。", "Biiru o nomimasu.", "Saya minum bir."),
        ]),
        ("nihonshu", "日本酒", "にほんしゅ", "nihonshu", "sake (arak beras Jepang)", "N3", [
            ("日本酒は米から作ります。", "Nihonshu wa kome kara tsukurimasu.", "Sake dibuat dari beras."),
        ]),
        ("wain", None, "ワイン", "wain", "anggur (wine)", "N4", [
            ("赤ワインが好きです。", "Aka wain ga suki desu.", "Saya suka anggur merah."),
        ]),
        ("tansan", "炭酸", "たんさん", "tansan", "minuman soda/berkarbonasi", "N3", [
            ("炭酸が好きです。", "Tansan ga suki desu.", "Saya suka minuman soda."),
        ]),
        ("mirukutii", None, "ミルクティー", "mirukutii", "teh susu", "N3", [
            ("ミルクティーを飲みます。", "Mirukutii o nomimasu.", "Saya minum teh susu."),
        ]),
    ]),
    "bumbu_rempah": ("nama bumbu", "noun", [
        ("shio", "塩", "しお", "shio", "garam", "N5", [
            ("塩を入れます。", "Shio o iremasu.", "Saya memasukkan garam."),
        ]),
        ("satou", "砂糖", "さとう", "satou", "gula", "N5", [
            ("砂糖は甘いです。", "Satou wa amai desu.", "Gula itu manis."),
        ]),
        ("shouyu", "醤油", "しょうゆ", "shouyu", "kecap asin (soy sauce)", "N4", [
            ("醤油をかけます。", "Shouyu o kakemasu.", "Saya menuangkan kecap asin."),
        ]),
        ("miso", "味噌", "みそ", "miso", "pasta miso (fermentasi kedelai)", "N4", [
            ("味噌は大豆から作ります。", "Miso wa daizu kara tsukurimasu.", "Miso dibuat dari kedelai."),
        ]),
        ("su", "酢", "す", "su", "cuka", "N3", [
            ("酢を少し入れます。", "Su o sukoshi iremasu.", "Saya memasukkan sedikit cuka."),
        ]),
        ("koshou", "胡椒", "こしょう", "koshou", "merica", "N3", [
            ("胡椒を振ります。", "Koshou o furimasu.", "Saya menaburkan merica."),
        ]),
        ("abura", "油", "あぶら", "abura", "minyak", "N4", [
            ("油で揚げます。", "Abura de agemasu.", "Saya menggoreng dengan minyak."),
        ]),
        ("shouga", "生姜", "しょうが", "shouga", "jahe", "N3", [
            ("生姜は体を温めます。", "Shouga wa karada o atatamemasu.", "Jahe menghangatkan tubuh."),
        ]),
        ("karashi", "辛子", "からし", "karashi", "mustard Jepang (karashi)", "N2", [
            ("からしは辛いです。", "Karashi wa karai desu.", "Karashi itu pedas."),
        ]),
        ("wasabi", None, "わさび", "wasabi", "wasabi", "N3", [
            ("お寿司にわさびをつけます。", "Osushi ni wasabi o tsukemasu.", "Saya mengoleskan wasabi ke sushi."),
        ]),
        ("katsuobushi", "鰹節", "かつおぶし", "katsuobushi", "serutan ikan cakalang kering", "N2", [
            ("かつおぶしをかけます。", "Katsuobushi o kakemasu.", "Saya menaburkan katsuobushi."),
        ]),
        ("mirin", None, "みりん", "mirin", "mirin (arak masak manis)", "N2", [
            ("料理にみりんを使います。", "Ryouri ni mirin o tsukaimasu.", "Saya menggunakan mirin dalam masakan."),
        ]),
    ]),
    "peralatan_masak": ("nama alat masak", "noun", [
        ("nabe", "鍋", "なべ", "nabe", "panci", "N4", [
            ("鍋でスープを作ります。", "Nabe de suupu o tsukurimasu.", "Saya membuat sup dengan panci."),
        ]),
        ("furaipan", None, "フライパン", "furaipan", "wajan (frying pan)", "N4", [
            ("フライパンで焼きます。", "Furaipan de yakimasu.", "Saya memasak dengan wajan."),
        ]),
        ("houchou", "包丁", "ほうちょう", "houchou", "pisau dapur", "N3", [
            ("包丁で切ります。", "Houchou de kirimasu.", "Saya memotong dengan pisau dapur."),
        ]),
        ("manaita", "まな板", "まないた", "manaita", "talenan", "N3", [
            ("まな板の上で切ります。", "Manaita no ue de kirimasu.", "Saya memotong di atas talenan."),
        ]),
        ("oobun", None, "オーブン", "oobun", "oven", "N4", [
            ("オーブンで焼きます。", "Oobun de yakimasu.", "Saya memanggang dengan oven."),
        ]),
        ("denshirenji", "電子レンジ", "でんしレンジ", "denshi renji", "microwave", "N4", [
            ("電子レンジで温めます。", "Denshi renji de atatamemasu.", "Saya menghangatkan dengan microwave."),
        ]),
        ("suihanki", "炊飯器", "すいはんき", "suihanki", "rice cooker", "N3", [
            ("炊飯器でご飯を炊きます。", "Suihanki de gohan o takimasu.", "Saya memasak nasi dengan rice cooker."),
        ]),
        ("oosaji", "大さじ", "おおさじ", "oosaji", "sendok makan (takaran)", "N3", [
            ("大さじ一杯の砂糖。", "Oosaji ippai no satou.", "Satu sendok makan gula."),
        ]),
        ("kosaji", "小さじ", "こさじ", "kosaji", "sendok teh (takaran)", "N3", [
            ("小さじ半分の塩。", "Kosaji hanbun no shio.", "Setengah sendok teh garam."),
        ]),
        ("zaru", None, "ざる", "zaru", "saringan (anyaman)", "N2", [
            ("ざるで水を切ります。", "Zaru de mizu o kirimasu.", "Saya meniriskan air dengan saringan."),
        ]),
        ("yakan", None, "やかん", "yakan", "ketel/teko", "N3", [
            ("やかんでお湯を沸かします。", "Yakan de oyu o wakashimasu.", "Saya merebus air dengan ketel."),
        ]),
        ("sara", "皿", "さら", "sara", "piring", "N4", [
            ("皿を洗います。", "Sara o araimasu.", "Saya mencuci piring."),
        ]),
    ]),
}

# cara_memasak — verbs, real casual/formal register (dict form vs ~masu).
CARA_MEMASAK = [
    ("yaku", "焼く", "やく", "yaku", "焼きます", "yakimasu", "memanggang/menggoreng (sedikit minyak)", "N4", [
        ("魚を焼きます。", "Sakana o yakimasu.", "Saya memanggang ikan."),
    ]),
    ("niru", "煮る", "にる", "niru", "煮ます", "nimasu", "merebus/memasak dengan kuah", "N4", [
        ("野菜を煮ます。", "Yasai o nimasu.", "Saya merebus sayuran."),
    ]),
    ("ageru", "揚げる", "あげる", "ageru", "揚げます", "agemasu", "menggoreng (deep fry)", "N4", [
        ("天ぷらを揚げます。", "Tenpura o agemasu.", "Saya menggoreng tempura."),
    ]),
    ("musu", "蒸す", "むす", "musu", "蒸します", "mushimasu", "mengukus", "N3", [
        ("野菜を蒸します。", "Yasai o mushimasu.", "Saya mengukus sayuran."),
    ]),
    ("itameru", "炒める", "いためる", "itameru", "炒めます", "itamemasu", "menumis", "N3", [
        ("野菜を炒めます。", "Yasai o itamemasu.", "Saya menumis sayuran."),
    ]),
    ("yuderu", "茹でる", "ゆでる", "yuderu", "茹でます", "yudemasu", "merebus (dalam air mendidih)", "N3", [
        ("卵を茹でます。", "Tamago o yudemasu.", "Saya merebus telur."),
    ]),
    ("kiru", "切る", "きる", "kiru", "切ります", "kirimasu", "memotong", "N5", [
        ("野菜を切ります。", "Yasai o kirimasu.", "Saya memotong sayuran."),
    ]),
    ("mazeru", "混ぜる", "まぜる", "mazeru", "混ぜます", "mazemasu", "mencampur", "N4", [
        ("材料を混ぜます。", "Zairyou o mazemasu.", "Saya mencampur bahan-bahan."),
    ]),
    ("tsukuru", "作る", "つくる", "tsukuru", "作ります", "tsukurimasu", "membuat (memasak)", "N5", [
        ("料理を作ります。", "Ryouri o tsukurimasu.", "Saya membuat masakan."),
    ]),
    ("taku", "炊く", "たく", "taku", "炊きます", "takimasu", "menanak (nasi)", "N3", [
        ("ご飯を炊きます。", "Gohan o takimasu.", "Saya menanak nasi."),
    ]),
]


def build_noun_entries(category_id, noun_label, words):
    entries = []
    for suffix, kanji, hiragana, romaji, meaning, level, examples in words:
        entry_id = f"kotoba_{category_id}_{suffix}"
        entries.append({
            "id": entry_id,
            "word": hiragana,
            "kanji": kanji,
            "reading": hiragana,
            "romaji": romaji,
            "meaning": meaning,
            "jlptLevel": level,
            "category": category_id,
            "wordType": "noun",
            "registers": _plain_registers(hiragana, romaji, noun_label),
            "sentenceExamples": [
                {"japanese": jp, "romaji": ro, "translation": tr}
                for jp, ro, tr in examples
            ],
            "imagePath": f"kotoba_images/{category_id}/{entry_id}.png",
        })
    return entries


def build_verb_entries(category_id, words):
    entries = []
    for suffix, kanji, hiragana, romaji, masu_kanji, masu_romaji, meaning, level, examples in words:
        entry_id = f"kotoba_{category_id}_{suffix}"
        entries.append({
            "id": entry_id,
            "word": hiragana,
            "kanji": kanji,
            "reading": hiragana,
            "romaji": romaji,
            "meaning": meaning,
            "jlptLevel": level,
            "category": category_id,
            "wordType": "verb",
            "registers": _verb_registers(kanji, romaji, masu_kanji, masu_romaji),
            "sentenceExamples": [
                {"japanese": jp, "romaji": ro, "translation": tr}
                for jp, ro, tr in examples
            ],
            "imagePath": f"kotoba_images/{category_id}/{entry_id}.png",
        })
    return entries


def main():
    total = 0
    for category_id, (noun_label, word_type, words) in CATEGORIES.items():
        data = build_noun_entries(category_id, noun_label, words)
        path = f"assets/data/kotoba/{category_id}.json"
        with open(path, "w", encoding="utf-8") as f:
            json.dump(data, f, ensure_ascii=False, indent=2)
        print(f"Wrote {len(data)} entries to {path}")
        total += len(data)

    data = build_verb_entries("cara_memasak", CARA_MEMASAK)
    path = "assets/data/kotoba/cara_memasak.json"
    with open(path, "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
    print(f"Wrote {len(data)} entries to {path}")
    total += len(data)

    print(f"Total: {total}")


if __name__ == "__main__":
    main()
