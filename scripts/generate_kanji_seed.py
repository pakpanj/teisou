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
        ("一月", "ichigatsu", "bulan Januari"),
        ("一人", "hitori", "satu orang/sendirian"),
    ], [
        ("りんごを一つください。", "Ringo o hitotsu kudasai.", "Tolong satu apel."),
        ("一月は寒いです。", "Ichigatsu wa samui desu.", "Bulan Januari dingin."),
    ]),
    ("ni", "二", ["ニ"], ["ふた", "ふた-つ"], ["dua", "two"], 2, "二", [
        ("二つ", "futatsu", "dua (unit)"),
        ("二月", "nigatsu", "bulan Februari"),
        ("二人", "futari", "dua orang"),
    ], [
        ("みかんを二つ買いました。", "Mikan o futatsu kaimashita.", "Saya membeli dua jeruk."),
        ("二月に旅行します。", "Nigatsu ni ryokou shimasu.", "Bulan Februari saya akan bepergian."),
    ]),
    ("san", "三", ["サン"], ["み", "み-つ"], ["tiga", "three"], 3, "一", [
        ("三つ", "mittsu", "tiga (unit)"),
        ("三月", "sangatsu", "bulan Maret"),
        ("三人", "sannin", "tiga orang"),
    ], [
        ("卵を三つ使います。", "Tamago o mittsu tsukaimasu.", "Saya memakai tiga telur."),
        ("三月に卒業します。", "Sangatsu ni sotsugyou shimasu.", "Bulan Maret saya lulus."),
    ]),
    ("yon", "四", ["シ"], ["よ", "よん", "よ-つ"], ["empat", "four"], 5, "囗", [
        ("四月", "shigatsu", "bulan April"),
        ("四人", "yonin", "empat orang"),
        ("四つ", "yottsu", "empat (unit)"),
    ], [
        ("四月に日本へ行きます。", "Shigatsu ni Nihon e ikimasu.", "Saya pergi ke Jepang bulan April."),
        ("家族は四人です。", "Kazoku wa yonin desu.", "Keluarga saya berjumlah empat orang."),
    ]),
    ("go", "五", ["ゴ"], ["いつ", "いつ-つ"], ["lima", "five"], 4, "二", [
        ("五つ", "itsutsu", "lima (unit)"),
        ("五月", "gogatsu", "bulan Mei"),
        ("五人", "gonin", "lima orang"),
    ], [
        ("五つの部屋があります。", "Itsutsu no heya ga arimasu.", "Ada lima kamar."),
        ("五月は暖かいです。", "Gogatsu wa atatakai desu.", "Bulan Mei hangat."),
    ]),
    ("roku", "六", ["ロク"], ["む", "む-つ"], ["enam", "six"], 4, "八", [
        ("六月", "rokugatsu", "bulan Juni"),
        ("六つ", "muttsu", "enam (unit)"),
        ("六人", "rokunin", "enam orang"),
    ], [
        ("六月は雨が多いです。", "Rokugatsu wa ame ga ooi desu.", "Bulan Juni banyak hujan."),
        ("六人で旅行しました。", "Rokunin de ryokou shimashita.", "Kami bepergian berenam."),
    ]),
    ("shichi", "七", ["シチ"], ["なな", "なな-つ"], ["tujuh", "seven"], 2, "一", [
        ("七つ", "nanatsu", "tujuh (unit)"),
        ("七月", "shichigatsu", "bulan Juli"),
        ("七人", "shichinin", "tujuh orang"),
    ], [
        ("七つの星が見えます。", "Nanatsu no hoshi ga miemasu.", "Terlihat tujuh bintang."),
        ("七月に夏休みが始まります。", "Shichigatsu ni natsuyasumi ga hajimarimasu.", "Bulan Juli liburan musim panas dimulai."),
    ]),
    ("hachi", "八", ["ハチ"], ["や", "や-つ"], ["delapan", "eight"], 2, "八", [
        ("八月", "hachigatsu", "bulan Agustus"),
        ("八つ", "yattsu", "delapan (unit)"),
        ("八人", "hachinin", "delapan orang"),
    ], [
        ("八月はとても暑いです。", "Hachigatsu wa totemo atsui desu.", "Bulan Agustus sangat panas."),
        ("八人が参加します。", "Hachinin ga sanka shimasu.", "Delapan orang akan berpartisipasi."),
    ]),
    ("kyuu", "九", ["キュウ", "ク"], ["ここの", "ここの-つ"], ["sembilan", "nine"], 2, "乙", [
        ("九つ", "kokonotsu", "sembilan (unit)"),
        ("九月", "kugatsu", "bulan September"),
        ("九人", "kyuunin", "sembilan orang"),
    ], [
        ("九つの箱があります。", "Kokonotsu no hako ga arimasu.", "Ada sembilan kotak."),
        ("九月に新学期が始まります。", "Kugatsu ni shingakki ga hajimarimasu.", "Bulan September semester baru dimulai."),
    ]),
    ("juu", "十", ["ジュウ"], ["とお"], ["sepuluh", "ten"], 2, "十", [
        ("十日", "tooka", "tanggal sepuluh / sepuluh hari"),
        ("十人", "juunin", "sepuluh orang"),
        ("十月", "juugatsu", "bulan Oktober"),
    ], [
        ("十日に会いましょう。", "Tooka ni aimashou.", "Ayo bertemu tanggal sepuluh."),
        ("十月に文化祭があります。", "Juugatsu ni bunkasai ga arimasu.", "Bulan Oktober ada festival budaya."),
    ]),
    ("hito", "人", ["ジン", "ニン"], ["ひと"], ["orang", "person"], 2, "人", [
        ("日本人", "nihonjin", "orang Jepang"),
        ("一人", "hitori", "satu orang/sendirian"),
        ("人々", "hitobito", "orang-orang"),
    ], [
        ("彼は日本人です。", "Kare wa nihonjin desu.", "Dia orang Jepang."),
        ("教室に一人います。", "Kyoushitsu ni hitori imasu.", "Ada satu orang di kelas."),
    ]),
    ("hi", "日", ["ニチ", "ジツ"], ["ひ", "か"], ["hari", "matahari", "sun/day"], 4, "日", [
        ("日曜日", "nichiyoubi", "hari Minggu"),
        ("毎日", "mainichi", "setiap hari"),
        ("誕生日", "tanjoubi", "hari ulang tahun"),
    ], [
        ("日曜日は休みです。", "Nichiyoubi wa yasumi desu.", "Hari Minggu libur."),
        ("毎日日本語を勉強します。", "Mainichi nihongo o benkyou shimasu.", "Setiap hari saya belajar bahasa Jepang."),
    ]),
    ("tsuki", "月", ["ゲツ", "ガツ"], ["つき"], ["bulan", "moon/month"], 4, "月", [
        ("月曜日", "getsuyoubi", "hari Senin"),
        ("月", "tsuki", "bulan (langit)"),
        ("今月", "kongetsu", "bulan ini"),
    ], [
        ("月曜日から学校です。", "Getsuyoubi kara gakkou desu.", "Sekolah mulai hari Senin."),
        ("今夜、月がきれいです。", "Kon'ya, tsuki ga kirei desu.", "Malam ini, bulan indah."),
    ]),
    ("yama", "山", ["サン"], ["やま"], ["gunung", "mountain"], 3, "山", [
        ("富士山", "fujisan", "Gunung Fuji"),
        ("山", "yama", "gunung"),
        ("登山", "tozan", "mendaki gunung"),
    ], [
        ("富士山はきれいです。", "Fujisan wa kirei desu.", "Gunung Fuji indah."),
        ("週末に山に登ります。", "Shuumatsu ni yama ni noborimasu.", "Akhir pekan saya mendaki gunung."),
    ]),
    ("kawa", "川", ["セン"], ["かわ"], ["sungai", "river"], 3, "川", [
        ("川", "kawa", "sungai"),
        ("小川", "ogawa", "sungai kecil"),
        ("川岸", "kawagishi", "tepi sungai"),
    ], [
        ("川で泳ぎました。", "Kawa de oyogimashita.", "Saya berenang di sungai."),
        ("小川の水はきれいです。", "Ogawa no mizu wa kirei desu.", "Air sungai kecil itu jernih."),
    ]),
    # --- Batch A: 百千万円 + 年時分間週曜今半 + 木林森田火水土空気雨石花 (24) ---
    ("hyaku", "百", ["ヒャク"], [], ["ratus", "hundred"], 6, "白", [
        ("百円", "hyakuen", "seratus yen"),
        ("百人", "hyakunin", "seratus orang"),
        ("百点", "hyakuten", "nilai seratus/nilai sempurna"),
    ], [
        ("このりんごは百円です。", "Kono ringo wa hyakuen desu.", "Apel ini seratus yen."),
        ("テストで百点を取りました。", "Tesuto de hyakuten o torimashita.", "Saya mendapat nilai 100 di tes."),
    ]),
    ("sen", "千", ["セン"], ["ち"], ["ribu", "thousand"], 3, "十", [
        ("千円", "sen'en", "seribu yen"),
        ("千人", "sennin", "seribu orang"),
        ("二千", "nisen", "dua ribu"),
    ], [
        ("このかばんは千円です。", "Kono kaban wa sen'en desu.", "Tas ini seribu yen."),
        ("千人がそのコンサートに来ました。", "Sennin ga sono konsaato ni kimashita.", "Seribu orang datang ke konser itu."),
    ]),
    ("man", "万", ["マン", "バン"], [], ["puluh ribu", "ten thousand"], 3, "一", [
        ("一万円", "ichiman'en", "sepuluh ribu yen"),
        ("万年筆", "mannenhitsu", "pena tinta (fountain pen)"),
        ("十万", "juuman", "seratus ribu"),
    ], [
        ("このパソコンは十万円です。", "Kono pasokon wa juuman'en desu.", "Komputer ini seratus ribu yen."),
        ("誕生日に一万円もらいました。", "Tanjoubi ni ichiman'en moraimashita.", "Saya mendapat sepuluh ribu yen saat ulang tahun."),
    ]),
    ("en", "円", ["エン"], ["まる"], ["yen", "lingkaran/bundar", "circle/round"], 4, "冂", [
        ("円", "en", "yen"),
        ("百円", "hyakuen", "seratus yen"),
        ("千円", "sen'en", "seribu yen"),
    ], [
        ("これは百円です。", "Kore wa hyakuen desu.", "Ini seratus yen."),
        ("千円貸してください。", "Sen'en kashite kudasai.", "Tolong pinjamkan saya seribu yen."),
    ]),
    ("nen", "年", ["ネン"], ["とし"], ["tahun", "year"], 6, "干", [
        ("来年", "rainen", "tahun depan"),
        ("今年", "kotoshi", "tahun ini"),
        ("毎年", "mainen", "setiap tahun"),
    ], [
        ("今年、日本語を勉強します。", "Kotoshi, nihongo o benkyou shimasu.", "Tahun ini, saya belajar bahasa Jepang."),
        ("来年、日本へ行きます。", "Rainen, Nihon e ikimasu.", "Tahun depan, saya akan pergi ke Jepang."),
    ]),
    ("ji", "時", ["ジ"], ["とき"], ["waktu", "jam", "time", "hour"], 10, "日", [
        ("時間", "jikan", "waktu/jam"),
        ("何時", "nanji", "jam berapa"),
        ("時々", "tokidoki", "kadang-kadang"),
    ], [
        ("今何時ですか。", "Ima nanji desu ka.", "Sekarang jam berapa?"),
        ("時々映画を見ます。", "Tokidoki eiga o mimasu.", "Kadang-kadang saya menonton film."),
    ]),
    ("fun", "分", ["フン", "ブン", "ブ"], ["わ-かる", "わ-ける"], ["menit", "bagian", "minute", "part", "understand"], 4, "刀", [
        ("五分", "gofun", "lima menit"),
        ("分かる", "wakaru", "mengerti"),
        ("半分", "hanbun", "setengah"),
    ], [
        ("駅まで五分かかります。", "Eki made gofun kakarimasu.", "Sampai stasiun butuh lima menit."),
        ("この問題が分かりません。", "Kono mondai ga wakarimasen.", "Saya tidak mengerti soal ini."),
    ]),
    ("kan", "間", ["カン", "ケン"], ["あいだ", "ま"], ["antara", "jarak waktu", "between", "interval"], 12, "門", [
        ("時間", "jikan", "waktu"),
        ("間", "aida", "antara/celah"),
        ("一週間", "isshuukan", "satu minggu"),
    ], [
        ("授業は一時間です。", "Jugyou wa ichijikan desu.", "Pelajaran berlangsung satu jam."),
        ("木と木の間に猫がいます。", "Ki to ki no aida ni neko ga imasu.", "Ada kucing di antara pohon-pohon."),
    ]),
    ("shuu", "週", ["シュウ"], [], ["minggu", "week"], 11, "辶", [
        ("今週", "konshuu", "minggu ini"),
        ("来週", "raishuu", "minggu depan"),
        ("毎週", "maishuu", "setiap minggu"),
    ], [
        ("今週は忙しいです。", "Konshuu wa isogashii desu.", "Minggu ini sibuk."),
        ("毎週日曜日に掃除します。", "Maishuu nichiyoubi ni souji shimasu.", "Setiap hari Minggu saya bersih-bersih."),
    ]),
    ("you", "曜", ["ヨウ"], [], ["hari (dalam minggu)", "day of the week"], 18, "日", [
        ("曜日", "youbi", "hari (dalam minggu)"),
        ("月曜日", "getsuyoubi", "hari Senin"),
        ("何曜日", "nanyoubi", "hari apa"),
    ], [
        ("今日は何曜日ですか。", "Kyou wa nanyoubi desu ka.", "Hari ini hari apa?"),
        ("土曜日に友達と遊びます。", "Doyoubi ni tomodachi to asobimasu.", "Hari Sabtu saya bermain dengan teman."),
    ]),
    ("ima", "今", ["コン", "キン"], ["いま"], ["sekarang", "now"], 4, "人", [
        ("今", "ima", "sekarang"),
        ("今日", "kyou", "hari ini"),
        ("今年", "kotoshi", "tahun ini"),
    ], [
        ("今、忙しいです。", "Ima, isogashii desu.", "Sekarang, saya sibuk."),
        ("今日は暑いです。", "Kyou wa atsui desu.", "Hari ini panas."),
    ]),
    ("han", "半", ["ハン"], ["なか-ば"], ["setengah", "half"], 5, "十", [
        ("半分", "hanbun", "setengah"),
        ("一時半", "ichijihan", "jam satu setengah"),
        ("半年", "hantoshi", "setengah tahun"),
    ], [
        ("今、三時半です。", "Ima, sanjihan desu.", "Sekarang jam setengah empat (3:30)."),
        ("りんごを半分食べました。", "Ringo o hanbun tabemashita.", "Saya makan setengah apel."),
    ]),
    ("ki", "木", ["モク", "ボク"], ["き"], ["pohon", "kayu", "tree", "wood"], 4, "木", [
        ("木曜日", "mokuyoubi", "hari Kamis"),
        ("木", "ki", "pohon"),
        ("大木", "taiboku", "pohon besar"),
    ], [
        ("公園に大きい木があります。", "Kouen ni ookii ki ga arimasu.", "Ada pohon besar di taman."),
        ("木曜日に会いましょう。", "Mokuyoubi ni aimashou.", "Ayo bertemu hari Kamis."),
    ]),
    ("hayashi", "林", ["リン"], ["はやし"], ["hutan kecil", "woods", "grove"], 8, "木", [
        ("林", "hayashi", "hutan kecil"),
        ("森林", "shinrin", "hutan"),
        ("山林", "sanrin", "hutan gunung"),
    ], [
        ("林の中を歩きました。", "Hayashi no naka o arukimashita.", "Saya berjalan di dalam hutan kecil."),
        ("この山は森林が多いです。", "Kono yama wa shinrin ga ooi desu.", "Gunung ini banyak hutannya."),
    ]),
    ("mori", "森", ["シン"], ["もり"], ["hutan", "forest"], 12, "木", [
        ("森", "mori", "hutan"),
        ("森林", "shinrin", "hutan"),
        ("深い森", "fukai mori", "hutan yang dalam"),
    ], [
        ("森の中で鳥の声が聞こえます。", "Mori no naka de tori no koe ga kikoemasu.", "Terdengar suara burung di dalam hutan."),
        ("この森はとても静かです。", "Kono mori wa totemo shizuka desu.", "Hutan ini sangat sunyi."),
    ]),
    ("ta", "田", ["デン"], ["た"], ["sawah", "ladang", "rice field"], 5, "田", [
        ("田んぼ", "tanbo", "sawah"),
        ("水田", "suiden", "sawah berair"),
        ("田植え", "taue", "menanam padi"),
    ], [
        ("田んぼで米を作ります。", "Tanbo de kome o tsukurimasu.", "Menanam padi di sawah."),
        ("祖父は田んぼで働いています。", "Sofu wa tanbo de hataraite imasu.", "Kakek saya bekerja di sawah."),
    ]),
    ("hi2", "火", ["カ"], ["ひ"], ["api", "fire"], 4, "火", [
        ("火曜日", "kayoubi", "hari Selasa"),
        ("火", "hi", "api"),
        ("花火", "hanabi", "kembang api"),
    ], [
        ("火曜日に病院へ行きます。", "Kayoubi ni byouin e ikimasu.", "Hari Selasa saya pergi ke rumah sakit."),
        ("夏に花火を見ました。", "Natsu ni hanabi o mimashita.", "Musim panas saya melihat kembang api."),
    ]),
    ("mizu", "水", ["スイ"], ["みず"], ["air", "water"], 4, "水", [
        ("水曜日", "suiyoubi", "hari Rabu"),
        ("水", "mizu", "air"),
        ("水泳", "suiei", "berenang"),
    ], [
        ("水を飲みます。", "Mizu o nomimasu.", "Saya minum air."),
        ("水曜日にテストがあります。", "Suiyoubi ni tesuto ga arimasu.", "Hari Rabu ada tes."),
    ]),
    ("tsuchi", "土", ["ド", "ト"], ["つち"], ["tanah", "bumi", "earth", "soil"], 3, "土", [
        ("土曜日", "doyoubi", "hari Sabtu"),
        ("土", "tsuchi", "tanah"),
        ("土地", "tochi", "lahan/tanah"),
    ], [
        ("土曜日は休みです。", "Doyoubi wa yasumi desu.", "Hari Sabtu libur."),
        ("花に土をあげました。", "Hana ni tsuchi o agemashita.", "Saya memberi tanah untuk bunga."),
    ]),
    ("sora", "空", ["クウ"], ["そら", "から", "あ-く"], ["langit", "kosong", "sky", "empty"], 8, "穴", [
        ("空", "sora", "langit"),
        ("空気", "kuuki", "udara"),
        ("空港", "kuukou", "bandara"),
    ], [
        ("空が青いです。", "Sora ga aoi desu.", "Langit biru."),
        ("空港まで電車で行きます。", "Kuukou made densha de ikimasu.", "Saya pergi ke bandara naik kereta."),
    ]),
    ("ki2", "気", ["キ", "ケ"], [], ["semangat", "udara", "spirit", "energy", "feeling"], 6, "气", [
        ("元気", "genki", "sehat/semangat"),
        ("天気", "tenki", "cuaca"),
        ("気持ち", "kimochi", "perasaan"),
    ], [
        ("元気ですか。", "Genki desu ka.", "Apa kabar?"),
        ("今日の天気はいいです。", "Kyou no tenki wa ii desu.", "Cuaca hari ini bagus."),
    ]),
    ("ame", "雨", ["ウ"], ["あめ"], ["hujan", "rain"], 8, "雨", [
        ("雨", "ame", "hujan"),
        ("大雨", "ooame", "hujan lebat"),
        ("雨天", "uten", "cuaca hujan"),
    ], [
        ("今日は雨です。", "Kyou wa ame desu.", "Hari ini hujan."),
        ("明日は雨が降るでしょう。", "Ashita wa ame ga furu deshou.", "Besok mungkin akan hujan."),
    ]),
    ("ishi", "石", ["セキ", "シャク"], ["いし"], ["batu", "stone"], 5, "石", [
        ("石", "ishi", "batu"),
        ("石鹸", "sekken", "sabun"),
        ("宝石", "houseki", "batu permata"),
    ], [
        ("川で石を拾いました。", "Kawa de ishi o hiroimashita.", "Saya memungut batu di sungai."),
        ("これは宝石です。", "Kore wa houseki desu.", "Ini adalah batu permata."),
    ]),
    ("hana", "花", ["カ"], ["はな"], ["bunga", "flower"], 7, "艹", [
        ("花", "hana", "bunga"),
        ("花見", "hanami", "melihat bunga sakura"),
        ("花瓶", "kabin", "vas bunga"),
    ], [
        ("花がきれいです。", "Hana ga kirei desu.", "Bunganya indah."),
        ("春に花見をします。", "Haru ni hanami o shimasu.", "Musim semi kami melihat bunga sakura."),
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
