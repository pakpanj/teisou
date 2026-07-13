import json

# Kotoba vocab — grup "Waktu & Angka" (Batch 7, final group).
# Same per-entry registers approach as the other Batch 7 scripts.
#
# hari_bulan is larger (22) than most categories on purpose: days of the
# week and months are small, closed, complete sets (unlike e.g. animals,
# where a subset is a curatorial choice) — learners expect all 7 days and
# all 12 months, not a sample. Month readings include the three standard
# irregulars: 四月=shigatsu (not yongatsu), 七月=shichigatsu (not
# nanagatsu), 九月=kugatsu (not kyuugatsu).
#
# angka_satuan sticks to pure numbers (1-10, 100, 1000, 10000) and skips
# counters/josuushi (mai, hon, hiki...) — those are bound morphemes that
# don't stand alone as words the way every other entry in this dataset
# does, and representing them accurately would need explaining irregular
# counting-sequence readings, which is a deeper grammar topic than this
# category's scope.
#
# warna keeps the real noun/adjective split: akai/aoi/kiiroi/shiroi/kuroi
# are true i-adjectives (the five basic historical colors), the rest
# (midori, chairo, murasaki, pinku, orenji, haiiro) are nouns used with
# no/desu, not aoi-style adjectives — mirroring how they actually behave.
#
# Each tuple: (id_suffix, kanji_or_None, hiragana, romaji, meaning,
#              jlptLevel, wordType, casual, casual_romaji, formal,
#              formal_romaji, examples)


def _registers(casual, casual_romaji, formal, formal_romaji, word_type):
    label = {
        "noun": "kata benda ini",
        "verb": "kata kerja ini",
        "adjective": "kata sifat ini",
    }.get(word_type, "kata ini")
    return {
        "casual": f"{casual} ({casual_romaji})",
        "formal": f"{formal} ({formal_romaji})",
        "keigo": f"{casual} ({casual_romaji}) — tidak ada bentuk keigo khusus untuk {label}",
    }


CATEGORIES = {
    "hari_bulan": [
        ("getsuyoubi", "月曜日", "げつようび", "getsuyoubi", "hari Senin", "N5", "noun", "月曜日", "getsuyoubi", "月曜日", "getsuyoubi", [
            ("月曜日に学校があります。", "Getsuyoubi ni gakkou ga arimasu.", "Hari Senin ada sekolah."),
        ]),
        ("kayoubi", "火曜日", "かようび", "kayoubi", "hari Selasa", "N5", "noun", "火曜日", "kayoubi", "火曜日", "kayoubi", [
            ("火曜日に会議があります。", "Kayoubi ni kaigi ga arimasu.", "Hari Selasa ada rapat."),
        ]),
        ("suiyoubi", "水曜日", "すいようび", "suiyoubi", "hari Rabu", "N5", "noun", "水曜日", "suiyoubi", "水曜日", "suiyoubi", [
            ("水曜日は休みです。", "Suiyoubi wa yasumi desu.", "Hari Rabu libur."),
        ]),
        ("mokuyoubi", "木曜日", "もくようび", "mokuyoubi", "hari Kamis", "N5", "noun", "木曜日", "mokuyoubi", "木曜日", "mokuyoubi", [
            ("木曜日に映画を見ます。", "Mokuyoubi ni eiga o mimasu.", "Hari Kamis saya menonton film."),
        ]),
        ("kinyoubi", "金曜日", "きんようび", "kinyoubi", "hari Jumat", "N5", "noun", "金曜日", "kinyoubi", "金曜日", "kinyoubi", [
            ("金曜日が好きです。", "Kinyoubi ga suki desu.", "Saya suka hari Jumat."),
        ]),
        ("doyoubi", "土曜日", "どようび", "doyoubi", "hari Sabtu", "N5", "noun", "土曜日", "doyoubi", "土曜日", "doyoubi", [
            ("土曜日に買い物します。", "Doyoubi ni kaimono shimasu.", "Hari Sabtu saya berbelanja."),
        ]),
        ("nichiyoubi", "日曜日", "にちようび", "nichiyoubi", "hari Minggu", "N5", "noun", "日曜日", "nichiyoubi", "日曜日", "nichiyoubi", [
            ("日曜日は家族と過ごします。", "Nichiyoubi wa kazoku to sugoshimasu.", "Hari Minggu saya menghabiskan waktu dengan keluarga."),
        ]),
        ("kyou", "今日", "きょう", "kyou", "hari ini", "N5", "noun", "今日", "kyou", "今日", "kyou", [
            ("今日は暑いです。", "Kyou wa atsui desu.", "Hari ini panas."),
        ]),
        ("ashita", "明日", "あした", "ashita", "besok", "N5", "noun", "明日", "ashita", "明日", "ashita", [
            ("明日テストがあります。", "Ashita tesuto ga arimasu.", "Besok ada tes."),
        ]),
        ("kinou", "昨日", "きのう", "kinou", "kemarin", "N5", "noun", "昨日", "kinou", "昨日", "kinou", [
            ("昨日雨でした。", "Kinou ame deshita.", "Kemarin hujan."),
        ]),
        ("ichigatsu", "一月", "いちがつ", "ichigatsu", "bulan Januari", "N5", "noun", "一月", "ichigatsu", "一月", "ichigatsu", [
            ("一月は寒いです。", "Ichigatsu wa samui desu.", "Bulan Januari dingin."),
        ]),
        ("nigatsu", "二月", "にがつ", "nigatsu", "bulan Februari", "N5", "noun", "二月", "nigatsu", "二月", "nigatsu", [
            ("二月は短いです。", "Nigatsu wa mijikai desu.", "Bulan Februari pendek."),
        ]),
        ("sangatsu", "三月", "さんがつ", "sangatsu", "bulan Maret", "N5", "noun", "三月", "sangatsu", "三月", "sangatsu", [
            ("三月に卒業します。", "Sangatsu ni sotsugyou shimasu.", "Saya lulus di bulan Maret."),
        ]),
        ("shigatsu", "四月", "しがつ", "shigatsu", "bulan April", "N5", "noun", "四月", "shigatsu", "四月", "shigatsu", [
            ("四月に学校が始まります。", "Shigatsu ni gakkou ga hajimarimasu.", "Sekolah dimulai bulan April."),
        ]),
        ("gogatsu", "五月", "ごがつ", "gogatsu", "bulan Mei", "N5", "noun", "五月", "gogatsu", "五月", "gogatsu", [
            ("五月は過ごしやすいです。", "Gogatsu wa sugoshiyasui desu.", "Bulan Mei nyaman (cuacanya)."),
        ]),
        ("rokugatsu", "六月", "ろくがつ", "rokugatsu", "bulan Juni", "N5", "noun", "六月", "rokugatsu", "六月", "rokugatsu", [
            ("六月によく雨が降ります。", "Rokugatsu ni yoku ame ga furimasu.", "Bulan Juni sering hujan."),
        ]),
        ("shichigatsu", "七月", "しちがつ", "shichigatsu", "bulan Juli", "N5", "noun", "七月", "shichigatsu", "七月", "shichigatsu", [
            ("七月は暑いです。", "Shichigatsu wa atsui desu.", "Bulan Juli panas."),
        ]),
        ("hachigatsu", "八月", "はちがつ", "hachigatsu", "bulan Agustus", "N5", "noun", "八月", "hachigatsu", "八月", "hachigatsu", [
            ("八月に花火大会があります。", "Hachigatsu ni hanabi taikai ga arimasu.", "Bulan Agustus ada festival kembang api."),
        ]),
        ("kugatsu", "九月", "くがつ", "kugatsu", "bulan September", "N5", "noun", "九月", "kugatsu", "九月", "kugatsu", [
            ("九月に新学期が始まります。", "Kugatsu ni shingakki ga hajimarimasu.", "Semester baru dimulai bulan September."),
        ]),
        ("juugatsu", "十月", "じゅうがつ", "juugatsu", "bulan Oktober", "N5", "noun", "十月", "juugatsu", "十月", "juugatsu", [
            ("十月は涼しいです。", "Juugatsu wa suzushii desu.", "Bulan Oktober sejuk."),
        ]),
        ("juuichigatsu", "十一月", "じゅういちがつ", "juuichigatsu", "bulan November", "N5", "noun", "十一月", "juuichigatsu", "十一月", "juuichigatsu", [
            ("十一月に紅葉が綺麗です。", "Juuichigatsu ni kouyou ga kirei desu.", "Bulan November daun-daun indah warnanya."),
        ]),
        ("juunigatsu", "十二月", "じゅうにがつ", "juunigatsu", "bulan Desember", "N5", "noun", "十二月", "juunigatsu", "十二月", "juunigatsu", [
            ("十二月にクリスマスがあります。", "Juunigatsu ni kurisumasu ga arimasu.", "Ada Natal di bulan Desember."),
        ]),
    ],
    "musim": [
        ("haru", "春", "はる", "haru", "musim semi", "N5", "noun", "春", "haru", "春", "haru", [
            ("春に桜が咲きます。", "Haru ni sakura ga sakimasu.", "Di musim semi, bunga sakura mekar."),
        ]),
        ("natsu", "夏", "なつ", "natsu", "musim panas", "N5", "noun", "夏", "natsu", "夏", "natsu", [
            ("夏は暑いです。", "Natsu wa atsui desu.", "Musim panas itu panas."),
        ]),
        ("aki", "秋", "あき", "aki", "musim gugur", "N5", "noun", "秋", "aki", "秋", "aki", [
            ("秋に紅葉が綺麗です。", "Aki ni kouyou ga kirei desu.", "Di musim gugur, daun berwarna indah."),
        ]),
        ("fuyu", "冬", "ふゆ", "fuyu", "musim dingin", "N5", "noun", "冬", "fuyu", "冬", "fuyu", [
            ("冬は寒いです。", "Fuyu wa samui desu.", "Musim dingin itu dingin."),
        ]),
        ("kisetsu", "季節", "きせつ", "kisetsu", "musim (kata umum)", "N4", "noun", "季節", "kisetsu", "季節", "kisetsu", [
            ("どの季節が好きですか。", "Dono kisetsu ga suki desu ka.", "Musim apa yang kamu suka?"),
        ]),
    ],
    "angka_satuan": [
        ("ichi", "一", "いち", "ichi", "satu (1)", "N5", "noun", "一", "ichi", "一", "ichi", [
            ("答えは一です。", "Kotae wa ichi desu.", "Jawabannya adalah satu."),
        ]),
        ("ni", "二", "に", "ni", "dua (2)", "N5", "noun", "二", "ni", "二", "ni", [
            ("答えは二です。", "Kotae wa ni desu.", "Jawabannya adalah dua."),
        ]),
        ("san", "三", "さん", "san", "tiga (3)", "N5", "noun", "三", "san", "三", "san", [
            ("答えは三です。", "Kotae wa san desu.", "Jawabannya adalah tiga."),
        ]),
        ("yon", "四", "よん", "yon", "empat (4)", "N5", "noun", "四", "yon", "四", "yon", [
            ("答えは四です。", "Kotae wa yon desu.", "Jawabannya adalah empat."),
        ]),
        ("go", "五", "ご", "go", "lima (5)", "N5", "noun", "五", "go", "五", "go", [
            ("答えは五です。", "Kotae wa go desu.", "Jawabannya adalah lima."),
        ]),
        ("roku", "六", "ろく", "roku", "enam (6)", "N5", "noun", "六", "roku", "六", "roku", [
            ("答えは六です。", "Kotae wa roku desu.", "Jawabannya adalah enam."),
        ]),
        ("nana", "七", "なな", "nana", "tujuh (7)", "N5", "noun", "七", "nana", "七", "nana", [
            ("答えは七です。", "Kotae wa nana desu.", "Jawabannya adalah tujuh."),
        ]),
        ("hachi", "八", "はち", "hachi", "delapan (8)", "N5", "noun", "八", "hachi", "八", "hachi", [
            ("答えは八です。", "Kotae wa hachi desu.", "Jawabannya adalah delapan."),
        ]),
        ("kyuu", "九", "きゅう", "kyuu", "sembilan (9)", "N5", "noun", "九", "kyuu", "九", "kyuu", [
            ("答えは九です。", "Kotae wa kyuu desu.", "Jawabannya adalah sembilan."),
        ]),
        ("juu", "十", "じゅう", "juu", "sepuluh (10)", "N5", "noun", "十", "juu", "十", "juu", [
            ("答えは十です。", "Kotae wa juu desu.", "Jawabannya adalah sepuluh."),
        ]),
        ("hyaku", "百", "ひゃく", "hyaku", "seratus (100)", "N4", "noun", "百", "hyaku", "百", "hyaku", [
            ("答えは百です。", "Kotae wa hyaku desu.", "Jawabannya adalah seratus."),
        ]),
        ("sen", "千", "せん", "sen", "seribu (1000)", "N4", "noun", "千", "sen", "千", "sen", [
            ("答えは千です。", "Kotae wa sen desu.", "Jawabannya adalah seribu."),
        ]),
        ("ichiman", "一万", "いちまん", "ichiman", "sepuluh ribu (10.000)", "N3", "noun", "一万", "ichiman", "一万", "ichiman", [
            ("答えは一万です。", "Kotae wa ichiman desu.", "Jawabannya adalah sepuluh ribu."),
        ]),
    ],
    "warna": [
        ("akai", "赤い", "あかい", "akai", "merah", "N5", "adjective", "赤い", "akai", "赤いです", "akai desu", [
            ("赤いりんごです。", "Akai ringo desu.", "Ini apel merah."),
        ]),
        ("aoi", "青い", "あおい", "aoi", "biru", "N5", "adjective", "青い", "aoi", "青いです", "aoi desu", [
            ("空は青いです。", "Sora wa aoi desu.", "Langit itu biru."),
        ]),
        ("kiiroi", "黄色い", "きいろい", "kiiroi", "kuning", "N5", "adjective", "黄色い", "kiiroi", "黄色いです", "kiiroi desu", [
            ("バナナは黄色いです。", "Banana wa kiiroi desu.", "Pisang itu kuning."),
        ]),
        ("midori", "緑", "みどり", "midori", "hijau", "N5", "noun", "緑", "midori", "緑です", "midori desu", [
            ("木の葉は緑です。", "Ki no ha wa midori desu.", "Daun pohon berwarna hijau."),
        ]),
        ("shiroi", "白い", "しろい", "shiroi", "putih", "N5", "adjective", "白い", "shiroi", "白いです", "shiroi desu", [
            ("雪は白いです。", "Yuki wa shiroi desu.", "Salju berwarna putih."),
        ]),
        ("kuroi", "黒い", "くろい", "kuroi", "hitam", "N5", "adjective", "黒い", "kuroi", "黒いです", "kuroi desu", [
            ("猫は黒いです。", "Neko wa kuroi desu.", "Kucing itu hitam."),
        ]),
        ("chairo", "茶色", "ちゃいろ", "chairo", "coklat (warna)", "N4", "noun", "茶色", "chairo", "茶色です", "chairo desu", [
            ("犬は茶色です。", "Inu wa chairo desu.", "Anjing itu berwarna coklat."),
        ]),
        ("murasaki", "紫", "むらさき", "murasaki", "ungu", "N3", "noun", "紫", "murasaki", "紫です", "murasaki desu", [
            ("ぶどうは紫です。", "Budou wa murasaki desu.", "Anggur berwarna ungu."),
        ]),
        ("pinku", None, "ピンク", "pinku", "merah muda (pink)", "N4", "noun", "ピンク", "pinku", "ピンクです", "pinku desu", [
            ("桜はピンクです。", "Sakura wa pinku desu.", "Sakura berwarna pink."),
        ]),
        ("orenji", None, "オレンジ", "orenji", "oranye", "N4", "noun", "オレンジ", "orenji", "オレンジです", "orenji desu", [
            ("オレンジ色が好きです。", "Orenji-iro ga suki desu.", "Saya suka warna oranye."),
        ]),
        ("haiiro", "灰色", "はいいろ", "haiiro", "abu-abu", "N3", "noun", "灰色", "haiiro", "灰色です", "haiiro desu", [
            ("空は灰色です。", "Sora wa haiiro desu.", "Langit berwarna abu-abu."),
        ]),
    ],
    "bentuk": [
        ("maru", "丸", "まる", "maru", "lingkaran/bulat", "N4", "noun", "丸", "maru", "丸", "maru", [
            ("丸を描きます。", "Maru o kakimasu.", "Saya menggambar lingkaran."),
        ]),
        ("shikaku", "四角", "しかく", "shikaku", "persegi/kotak", "N4", "noun", "四角", "shikaku", "四角", "shikaku", [
            ("四角を描きます。", "Shikaku o kakimasu.", "Saya menggambar persegi."),
        ]),
        ("sankaku", "三角", "さんかく", "sankaku", "segitiga", "N4", "noun", "三角", "sankaku", "三角", "sankaku", [
            ("三角を描きます。", "Sankaku o kakimasu.", "Saya menggambar segitiga."),
        ]),
        ("hoshi", "星", "ほし", "hoshi", "bintang (bentuk)", "N4", "noun", "星", "hoshi", "星", "hoshi", [
            ("星の形です。", "Hoshi no katachi desu.", "Ini bentuk bintang."),
        ]),
        ("haato", None, "ハート", "haato", "hati (bentuk)", "N3", "noun", "ハート", "haato", "ハート", "haato", [
            ("ハートの形です。", "Haato no katachi desu.", "Ini bentuk hati."),
        ]),
        ("katachi", "形", "かたち", "katachi", "bentuk (kata umum)", "N3", "noun", "形", "katachi", "形", "katachi", [
            ("この形は何ですか。", "Kono katachi wa nan desu ka.", "Bentuk apa ini?"),
        ]),
        ("chouhoukei", "長方形", "ちょうほうけい", "chouhoukei", "persegi panjang", "N2", "noun", "長方形", "chouhoukei", "長方形", "chouhoukei", [
            ("長方形の紙です。", "Chouhoukei no kami desu.", "Ini kertas persegi panjang."),
        ]),
    ],
}


def build_entries(category_id, words):
    entries = []
    for suffix, kanji, hiragana, romaji, meaning, level, word_type, casual, casual_romaji, formal, formal_romaji, examples in words:
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
            "wordType": word_type,
            "registers": _registers(casual, casual_romaji, formal, formal_romaji, word_type),
            "sentenceExamples": [
                {"japanese": jp, "romaji": ro, "translation": tr}
                for jp, ro, tr in examples
            ],
            "imagePath": f"kotoba_images/{category_id}/{entry_id}.png",
        })
    return entries


def main():
    total = 0
    for category_id, words in CATEGORIES.items():
        data = build_entries(category_id, words)
        path = f"assets/data/kotoba/{category_id}.json"
        with open(path, "w", encoding="utf-8") as f:
            json.dump(data, f, ensure_ascii=False, indent=2)
        print(f"Wrote {len(data)} entries to {path}")
        total += len(data)
    print(f"Total: {total}")


if __name__ == "__main__":
    main()
