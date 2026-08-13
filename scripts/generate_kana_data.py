import json

# Gojuon table definition.
# row index: 0=a,1=ka,2=sa,3=ta,4=na,5=ha,6=ma,7=ya,8=ra,9=wa,10=n
# column index: 0=a,1=i,2=u,3=e,4=o
ROWS = [
    # (row_index, romaji_list, hiragana_list, katakana_list, columns)
    (0, ["a", "i", "u", "e", "o"], ["あ", "い", "う", "え", "お"], ["ア", "イ", "ウ", "エ", "オ"], [0, 1, 2, 3, 4]),
    (1, ["ka", "ki", "ku", "ke", "ko"], ["か", "き", "く", "け", "こ"], ["カ", "キ", "ク", "ケ", "コ"], [0, 1, 2, 3, 4]),
    (2, ["sa", "shi", "su", "se", "so"], ["さ", "し", "す", "せ", "そ"], ["サ", "シ", "ス", "セ", "ソ"], [0, 1, 2, 3, 4]),
    (3, ["ta", "chi", "tsu", "te", "to"], ["た", "ち", "つ", "て", "と"], ["タ", "チ", "ツ", "テ", "ト"], [0, 1, 2, 3, 4]),
    (4, ["na", "ni", "nu", "ne", "no"], ["な", "に", "ぬ", "ね", "の"], ["ナ", "ニ", "ヌ", "ネ", "ノ"], [0, 1, 2, 3, 4]),
    (5, ["ha", "hi", "fu", "he", "ho"], ["は", "ひ", "ふ", "へ", "ほ"], ["ハ", "ヒ", "フ", "ヘ", "ホ"], [0, 1, 2, 3, 4]),
    (6, ["ma", "mi", "mu", "me", "mo"], ["ま", "み", "む", "め", "も"], ["マ", "ミ", "ム", "メ", "モ"], [0, 1, 2, 3, 4]),
    (7, ["ya", "yu", "yo"], ["や", "ゆ", "よ"], ["ヤ", "ユ", "ヨ"], [0, 2, 4]),
    (8, ["ra", "ri", "ru", "re", "ro"], ["ら", "り", "る", "れ", "ろ"], ["ラ", "リ", "ル", "レ", "ロ"], [0, 1, 2, 3, 4]),
    (9, ["wa", "wo"], ["わ", "を"], ["ワ", "ヲ"], [0, 4]),
    (10, ["n"], ["ん"], ["ン"], [0]),
    # Dakuten (゛) rows 11-14 and handakuten (゜) row 15 — voiced/semi-voiced
    # variants of か/さ/た/は, none of which existed in this dataset before
    # (Batch 1 only ever covered the plain 46+46 gojuon set). ぢ/づ are
    # given the romaji "di"/"du" rather than "ji"/"zu" — modern standard
    # Japanese pronounces them identically to じ/ず (the yotsugana merger),
    # but this dataset's `id` is derived from `romaji`
    # (`{type}_{romaji}`), so a literal "ji"/"zu" would collide with じ/ず's
    # own id and — worse — silently share one KanaProgress mastery record
    # between two different characters. "di"/"du" is a real, still-used
    # convention for exactly this disambiguation in beginner material, not
    # an invented one.
    (11, ["ga", "gi", "gu", "ge", "go"], ["が", "ぎ", "ぐ", "げ", "ご"], ["ガ", "ギ", "グ", "ゲ", "ゴ"], [0, 1, 2, 3, 4]),
    (12, ["za", "ji", "zu", "ze", "zo"], ["ざ", "じ", "ず", "ぜ", "ぞ"], ["ザ", "ジ", "ズ", "ゼ", "ゾ"], [0, 1, 2, 3, 4]),
    (13, ["da", "di", "du", "de", "do"], ["だ", "ぢ", "づ", "で", "ど"], ["ダ", "ヂ", "ヅ", "デ", "ド"], [0, 1, 2, 3, 4]),
    (14, ["ba", "bi", "bu", "be", "bo"], ["ば", "び", "ぶ", "べ", "ぼ"], ["バ", "ビ", "ブ", "ベ", "ボ"], [0, 1, 2, 3, 4]),
    (15, ["pa", "pi", "pu", "pe", "po"], ["ぱ", "ぴ", "ぷ", "ぺ", "ぽ"], ["パ", "ピ", "プ", "ペ", "ポ"], [0, 1, 2, 3, 4]),
    # Youon (small-ya/yu/yo combination mora) rows 16-26 — the 11 rows that
    # actually combine in modern Japanese (seion き/し/ち/に/ひ/み/り plus
    # dakuten/handakuten ぎ/じ/び/ぴ). ぢゃ/ぢゅ/ぢょ are deliberately left
    # out — essentially unused in modern vocabulary (unlike ぢ/づ alone,
    # which at least appear in real words like ちぢむ/つづく). Columns
    # 0/1/2 stand for ゃ/ゅ/ょ, reusing the same column axis the base rows
    # use for あ/い/う/え/お — it's just "which of this row's 3 members".
    (16, ["kya", "kyu", "kyo"], ["きゃ", "きゅ", "きょ"], ["キャ", "キュ", "キョ"], [0, 1, 2]),
    (17, ["sha", "shu", "sho"], ["しゃ", "しゅ", "しょ"], ["シャ", "シュ", "ショ"], [0, 1, 2]),
    (18, ["cha", "chu", "cho"], ["ちゃ", "ちゅ", "ちょ"], ["チャ", "チュ", "チョ"], [0, 1, 2]),
    (19, ["nya", "nyu", "nyo"], ["にゃ", "にゅ", "にょ"], ["ニャ", "ニュ", "ニョ"], [0, 1, 2]),
    (20, ["hya", "hyu", "hyo"], ["ひゃ", "ひゅ", "ひょ"], ["ヒャ", "ヒュ", "ヒョ"], [0, 1, 2]),
    (21, ["mya", "myu", "myo"], ["みゃ", "みゅ", "みょ"], ["ミャ", "ミュ", "ミョ"], [0, 1, 2]),
    (22, ["rya", "ryu", "ryo"], ["りゃ", "りゅ", "りょ"], ["リャ", "リュ", "リョ"], [0, 1, 2]),
    (23, ["gya", "gyu", "gyo"], ["ぎゃ", "ぎゅ", "ぎょ"], ["ギャ", "ギュ", "ギョ"], [0, 1, 2]),
    (24, ["ja", "ju", "jo"], ["じゃ", "じゅ", "じょ"], ["ジャ", "ジュ", "ジョ"], [0, 1, 2]),
    (25, ["bya", "byu", "byo"], ["びゃ", "びゅ", "びょ"], ["ビャ", "ビュ", "ビョ"], [0, 1, 2]),
    (26, ["pya", "pyu", "pyo"], ["ぴゃ", "ぴゅ", "ぴょ"], ["ピャ", "ピュ", "ピョ"], [0, 1, 2]),
]

# Youon glyphs are two Unicode characters (base kana + small ゃ/ゅ/ょ), so
# there is no single KanjiVG codepoint to fetch a combined stroke-order SVG
# from. This maps a youon romaji to the base romaji whose existing
# `assets/svg/{type}/{romaji}.svg` supplies the first half.
#
# The second half comes from SMALL_KANA_SVG below, and that is a correction
# to what this comment used to claim. Pointing a youon at its base consonant
# alone was described here as "honest"; it was not. きょ was drawn as three
# strokes when the mora has six, and the ょ a learner actually has to write
# was never shown at all. There is no combined file, true — but each half
# exists on its own, so the pair is fetched separately (see
# scripts/fetch_kana_small_svg.py) and the card draws them side by side as
# one continuous stroke sequence.
SVG_ASSET_OVERRIDE = {
    "kya": "ki", "kyu": "ki", "kyo": "ki",
    "sha": "shi", "shu": "shi", "sho": "shi",
    "cha": "chi", "chu": "chi", "cho": "chi",
    "nya": "ni", "nyu": "ni", "nyo": "ni",
    "hya": "hi", "hyu": "hi", "hyo": "hi",
    "mya": "mi", "myu": "mi", "myo": "mi",
    "rya": "ri", "ryu": "ri", "ryo": "ri",
    "gya": "gi", "gyu": "gi", "gyo": "gi",
    "ja": "ji", "ju": "ji", "jo": "ji",
    "bya": "bi", "byu": "bi", "byo": "bi",
    "pya": "pi", "pyu": "pi", "pyo": "pi",
}

# The small half of every youon, keyed by the romaji's final vowel — every
# youon ends in one of ya/yu/yo, including the ones whose romaji hides it
# ("ja"/"ju"/"jo", "sha"/"shu"/"sho", "cha"/"chu"/"cho").
SMALL_KANA_SVG = {"a": "small_ya", "u": "small_yu", "o": "small_yo"}

HIRAGANA_EXAMPLES = {
    "a": ("あさ", "asa", "Pagi"),
    "i": ("いぬ", "inu", "Anjing"),
    "u": ("うみ", "umi", "Laut"),
    "e": ("えき", "eki", "Stasiun"),
    "o": ("おちゃ", "ocha", "Teh"),
    "ka": ("かさ", "kasa", "Payung"),
    "ki": ("きもの", "kimono", "Baju tradisional Jepang"),
    "ku": ("くつ", "kutsu", "Sepatu"),
    "ke": ("けしき", "keshiki", "Pemandangan"),
    "ko": ("こども", "kodomo", "Anak"),
    "sa": ("さかな", "sakana", "Ikan"),
    "shi": ("しお", "shio", "Garam"),
    "su": ("すし", "sushi", "Sushi"),
    "se": ("せんせい", "sensei", "Guru"),
    "so": ("そら", "sora", "Langit"),
    "ta": ("たまご", "tamago", "Telur"),
    "chi": ("ちいさい", "chiisai", "Kecil"),
    "tsu": ("つき", "tsuki", "Bulan"),
    "te": ("てがみ", "tegami", "Surat"),
    "to": ("とり", "tori", "Burung"),
    "na": ("なつ", "natsu", "Musim panas"),
    "ni": ("にく", "niku", "Daging"),
    "nu": ("ぬの", "nuno", "Kain"),
    "ne": ("ねこ", "neko", "Kucing"),
    "no": ("のみもの", "nomimono", "Minuman"),
    "ha": ("はな", "hana", "Bunga"),
    "hi": ("ひと", "hito", "Orang"),
    "fu": ("ふゆ", "fuyu", "Musim dingin"),
    "he": ("へや", "heya", "Kamar"),
    "ho": ("ほし", "hoshi", "Bintang"),
    "ma": ("まど", "mado", "Jendela"),
    "mi": ("みず", "mizu", "Air"),
    "mu": ("むし", "mushi", "Serangga"),
    "me": ("めがね", "megane", "Kacamata"),
    "mo": ("もり", "mori", "Hutan"),
    "ya": ("やま", "yama", "Gunung"),
    "yu": ("ゆき", "yuki", "Salju"),
    "yo": ("よる", "yoru", "Malam"),
    "ra": ("らいねん", "rainen", "Tahun depan"),
    "ri": ("りんご", "ringo", "Apel"),
    "ru": ("るす", "rusu", "Tidak ada di rumah"),
    "re": ("れきし", "rekishi", "Sejarah"),
    "ro": ("ろうそく", "rousoku", "Lilin"),
    "wa": ("わたし", "watashi", "Saya"),
    "wo": None,
    "n": None,
    # Dakuten/handakuten
    "ga": ("がっこう", "gakkou", "Sekolah"),
    "gi": ("ぎんこう", "ginkou", "Bank"),
    "gu": ("ぐあい", "guai", "Kondisi (badan)"),
    "ge": ("げんき", "genki", "Sehat, bersemangat"),
    "go": ("ごはん", "gohan", "Nasi, makanan"),
    "za": ("ざっし", "zasshi", "Majalah"),
    "ji": ("じかん", "jikan", "Waktu"),
    "zu": ("ずつう", "zutsuu", "Sakit kepala"),
    "ze": ("ぜんぶ", "zenbu", "Semua"),
    "zo": ("ぞう", "zou", "Gajah"),
    "da": ("だいがく", "daigaku", "Universitas"),
    # ぢ almost never opens a real word (a yotsugana), so — unlike every
    # other entry here — this one doesn't start with its own kana. ちぢむ
    # ("to shrink") is one of the few common words that use it at all.
    "di": ("ちぢむ", "chijimu", "Menyusut/mengerut"),
    "du": ("つづく", "tsuzuku", "Berlanjut/berlangsung"),
    "de": ("でんわ", "denwa", "Telepon"),
    "do": ("どうぶつ", "doubutsu", "Hewan"),
    "ba": ("ばしょ", "basho", "Tempat"),
    "bi": ("びょういん", "byouin", "Rumah sakit"),
    "bu": ("ぶた", "buta", "Babi"),
    "be": ("べんきょう", "benkyou", "Belajar"),
    "bo": ("ぼうし", "boushi", "Topi"),
    "pa": ("ぱん", "pan", "Roti"),
    "pi": ("えんぴつ", "enpitsu", "Pensil"),
    "pu": ("きっぷ", "kippu", "Tiket"),
    "pe": ("ぺらぺら", "perapera", "Fasih (berbicara lancar)"),
    "po": ("たんぽぽ", "tanpopo", "Bunga dandelion"),
    # Youon
    "kya": ("きゃく", "kyaku", "Tamu, pelanggan"),
    "kyu": ("きゅうり", "kyuuri", "Timun"),
    "kyo": ("きょう", "kyou", "Hari ini"),
    "sha": ("しゃしん", "shashin", "Foto"),
    "shu": ("しゅくだい", "shukudai", "Pekerjaan rumah"),
    "sho": ("しょうがっこう", "shougakkou", "Sekolah dasar"),
    "cha": ("ちゃいろ", "chairo", "Warna coklat"),
    "chu": ("ちゅうがっこう", "chuugakkou", "Sekolah menengah pertama"),
    "cho": ("ちょうちょう", "choucho", "Kupu-kupu"),
    "nya": ("にゃんこ", "nyanko", "Kucing (panggilan akrab)"),
    "nyu": ("にゅうがく", "nyuugaku", "Masuk sekolah"),
    "nyo": ("にょろにょろ", "nyoronyoro", "Meliuk-liuk (spt. ular)"),
    "hya": ("ひゃく", "hyaku", "Seratus"),
    "hyu": ("ひゅうひゅう", "hyuuhyuu", "Suara angin bertiup kencang"),
    "hyo": ("ひょう", "hyou", "Macan tutul"),
    "mya": ("みゃく", "myaku", "Denyut nadi"),
    "myu": ("みゅーじかる", "myuujikaru", "Pertunjukan musikal"),
    "myo": ("みょうじ", "myouji", "Nama keluarga/marga"),
    "rya": ("りゃくご", "ryakugo", "Singkatan (kata)"),
    "ryu": ("りゅう", "ryuu", "Naga"),
    "ryo": ("りょこう", "ryokou", "Perjalanan wisata"),
    "gya": ("ぎゃく", "gyaku", "Kebalikan"),
    "gyu": ("ぎゅうにゅう", "gyuunyuu", "Susu sapi"),
    "gyo": ("ぎょうざ", "gyouza", "Pangsit goreng"),
    "ja": ("じゃがいも", "jagaimo", "Kentang"),
    "ju": ("じゅぎょう", "jugyou", "Pelajaran, kelas"),
    "jo": ("じょうず", "jouzu", "Pandai, mahir"),
    "bya": ("さんびゃく", "sanbyaku", "Tiga ratus"),
    "byu": ("びゅうびゅう", "byuubyuu", "Suara angin kencang"),
    "byo": ("びょうき", "byouki", "Sakit"),
    "pya": ("はっぴゃく", "happyaku", "Delapan ratus"),
    "pyu": ("ぴゅうぴゅう", "pyuupyuu", "Suara angin bersiul"),
    "pyo": ("ぴょんぴょん", "pyonpyon", "Melompat-lompat"),
}

KATAKANA_EXAMPLES = {
    "a": ("アイス", "aisu", "Es krim"),
    "i": ("イチゴ", "ichigo", "Stroberi"),
    "u": ("ウサギ", "usagi", "Kelinci"),
    "e": ("エビ", "ebi", "Udang"),
    "o": ("オレンジ", "orenji", "Jeruk"),
    "ka": ("カメラ", "kamera", "Kamera"),
    "ki": ("キリン", "kirin", "Jerapah"),
    "ku": ("クラス", "kurasu", "Kelas"),
    "ke": ("ケーキ", "keeki", "Kue"),
    "ko": ("コーヒー", "koohii", "Kopi"),
    "sa": ("サラダ", "sarada", "Salad"),
    "shi": ("シャツ", "shatsu", "Kemeja"),
    "su": ("スキー", "sukii", "Ski"),
    "se": ("セーター", "seetaa", "Sweater"),
    "so": ("ソース", "soosu", "Saus"),
    "ta": ("タクシー", "takushii", "Taksi"),
    "chi": ("チーズ", "chiizu", "Keju"),
    "tsu": ("ツアー", "tsuaa", "Tur"),
    "te": ("テレビ", "terebi", "Televisi"),
    "to": ("トマト", "tomato", "Tomat"),
    "na": ("ナイフ", "naifu", "Pisau"),
    # Pre-existing content bug, found while authoring the new ニュ (nyu)
    # youon entry below: this example was ニュース ("nyuusu", news), which
    # doesn't actually start with ニ (ni) at all — it starts with ニュ
    # (nyu). Every other entry in this table genuinely starts with its own
    # kana; this one never did. Fixed to a real ニ-starting word.
    "ni": ("ニンジン", "ninjin", "Wortel"),
    "nu": ("ヌードル", "nuudoru", "Mi"),
    "ne": ("ネクタイ", "nekutai", "Dasi"),
    "no": ("ノート", "nooto", "Buku catatan"),
    "ha": ("ハンバーガー", "hanbaagaa", "Burger"),
    "hi": ("ヒーロー", "hiiroo", "Pahlawan"),
    "fu": ("フォーク", "fooku", "Garpu"),
    "he": ("ヘリコプター", "herikoputaa", "Helikopter"),
    "ho": ("ホテル", "hoteru", "Hotel"),
    "ma": ("マスク", "masuku", "Masker"),
    "mi": ("ミルク", "miruku", "Susu"),
    "mu": ("ムービー", "muubii", "Film"),
    "me": ("メニュー", "menyuu", "Menu"),
    "mo": ("モデル", "moderu", "Model"),
    "ya": ("ヤード", "yaado", "Yard"),
    "yu": ("ユーモア", "yuumoa", "Humor"),
    "yo": ("ヨーグルト", "yooguruto", "Yogurt"),
    "ra": ("ラジオ", "rajio", "Radio"),
    "ri": ("リボン", "ribon", "Pita"),
    "ru": ("ルール", "ruuru", "Aturan"),
    "re": ("レストラン", "resutoran", "Restoran"),
    "ro": ("ロボット", "robotto", "Robot"),
    "wa": ("ワイン", "wain", "Anggur"),
    "wo": None,
    "n": None,
    # Dakuten/handakuten
    "ga": ("ガム", "gamu", "Permen karet"),
    "gi": ("ギター", "gitaa", "Gitar"),
    "gu": ("グラス", "gurasu", "Gelas"),
    "ge": ("ゲーム", "geemu", "Permainan, game"),
    "go": ("ゴム", "gomu", "Karet"),
    "za": ("ザリガニ", "zarigani", "Udang karang"),
    "ji": ("ジーンズ", "jiinzu", "Celana jins"),
    "zu": ("ズボン", "zubon", "Celana panjang"),
    "ze": ("ゼロ", "zero", "Nol"),
    "zo": ("ゾーン", "zoon", "Zona, area"),
    "da": ("ダンス", "dansu", "Tari, dansa"),
    # ヂ/ヅ are essentially unused in modern katakana — every loanword that
    # would phonetically need them is written with ジ/ズ instead (the same
    # yotsugana merger that shaped this dataset's "di"/"du" romaji choice
    # above). No real example word exists, same as を/ん in the base 46.
    "di": None,
    "du": None,
    "de": ("デパート", "depaato", "Toko serba ada"),
    "do": ("ドア", "doa", "Pintu"),
    "ba": ("バス", "basu", "Bus"),
    "bi": ("ビル", "biru", "Gedung"),
    "bu": ("ブラシ", "burashi", "Sikat"),
    "be": ("ベッド", "beddo", "Tempat tidur"),
    "bo": ("ボール", "booru", "Bola"),
    "pa": ("パーティー", "paatii", "Pesta"),
    "pi": ("ピアノ", "piano", "Piano"),
    "pu": ("プール", "puuru", "Kolam renang"),
    "pe": ("ペン", "pen", "Pulpen"),
    "po": ("ポケット", "poketto", "Kantong, saku"),
    # Youon
    "kya": ("キャンプ", "kyanpu", "Berkemah"),
    "kyu": ("キュート", "kyuuto", "Lucu, imut"),
    "kyo": ("キョロキョロ", "kyorokyoro", "Melihat sekeliling dengan gelisah"),
    "sha": ("シャツ", "shatsu", "Kemeja"),
    "shu": ("シュート", "shuuto", "Tembakan (olahraga)"),
    "sho": ("ショップ", "shoppu", "Toko"),
    "cha": ("チャンス", "chansu", "Kesempatan"),
    "chu": ("チューリップ", "chuurippu", "Bunga tulip"),
    "cho": ("チョコレート", "chokoreeto", "Coklat"),
    "nya": ("ニャー", "nyaa", "Suara kucing (meong)"),
    "nyu": ("ニュース", "nyuusu", "Berita"),
    # ニョ is genuinely rare in katakana — no common real word.
    "nyo": None,
    "hya": ("ヒャッホー", "hyahhoo", "Seruan gembira"),
    "hyu": ("ヒューマン", "hyuuman", "Manusia"),
    # ヒョ is genuinely rare in katakana — no common real word.
    "hyo": None,
    "mya": ("ミャンマー", "myanmaa", "Myanmar (nama negara)"),
    "myu": ("ミュージック", "myuujikku", "Musik"),
    # ミョ is genuinely rare in katakana — no common real word.
    "myo": None,
    # リャ is genuinely rare in katakana — no common real word.
    "rya": None,
    "ryu": ("リュック", "ryukku", "Tas ransel"),
    # リョ is genuinely rare in katakana — no common real word.
    "ryo": None,
    "gya": ("ギャラリー", "gyararii", "Galeri"),
    # ギュ/ギョ are genuinely rare in katakana (native ぎゅうにゅう/ぎょうざ
    # cover them in hiragana instead) — no common katakana-native word.
    "gyu": None,
    "gyo": None,
    "ja": ("ジャム", "jamu", "Selai"),
    "ju": ("ジュース", "juusu", "Jus"),
    "jo": ("ジョギング", "jogingu", "Jogging"),
    # ビャ is genuinely rare in katakana — no common real word.
    "bya": None,
    "byu": ("ビュッフェ", "byuffe", "Prasmanan (buffet)"),
    # ビョ is genuinely rare in katakana — no common real word.
    "byo": None,
    # ピャ is genuinely rare in katakana — no common real word.
    "pya": None,
    "pyu": ("ピュア", "pyua", "Murni, polos"),
    # ピョ is genuinely rare in katakana — no common real word.
    "pyo": None,
}


def build_entries(kana_type, chars_by_romaji_index, examples_map):
    entries = []
    for row_index, romaji_list, hira_list, kata_list, columns in ROWS:
        char_list = hira_list if kana_type == "hiragana" else kata_list
        for i, romaji in enumerate(romaji_list):
            column = columns[i]
            char = char_list[i]
            example = examples_map.get(romaji)
            examples = []
            if example:
                word, reading, meaning = example
                examples = [{"word": word, "reading": reading, "meaning": meaning}]
            svg_romaji = SVG_ASSET_OVERRIDE.get(romaji, romaji)
            entry = {
                "id": f"{kana_type}_{romaji}",
                "character": char,
                "romaji": romaji,
                "type": kana_type,
                "row": row_index,
                "column": column,
                "svgAsset": f"assets/svg/{kana_type}/{svg_romaji}.svg",
                "examples": examples,
            }
            # Only youon carry a second glyph, and they are exactly the
            # entries that needed an override to find their first one.
            if romaji in SVG_ASSET_OVERRIDE:
                small = SMALL_KANA_SVG[romaji[-1]]
                entry["svgAssetSecondary"] = (
                    f"assets/svg/{kana_type}/{small}.svg"
                )
            entries.append(entry)
    return entries


all_entries = []
all_entries.extend(build_entries("hiragana", ROWS, HIRAGANA_EXAMPLES))
all_entries.extend(build_entries("katakana", ROWS, KATAKANA_EXAMPLES))

assert len(all_entries) == 208, f"Expected 208 entries, got {len(all_entries)}"
hira_count = sum(1 for e in all_entries if e["type"] == "hiragana")
kata_count = sum(1 for e in all_entries if e["type"] == "katakana")
assert hira_count == 104, f"Expected 104 hiragana, got {hira_count}"
assert kata_count == 104, f"Expected 104 katakana, got {kata_count}"
ids = [e["id"] for e in all_entries]
assert len(ids) == len(set(ids)), "Duplicate kana id found"
chars_by_type = {}
for e in all_entries:
    chars_by_type.setdefault(e["type"], set())
    assert e["character"] not in chars_by_type[e["type"]], (
        f"Duplicate {e['type']} character {e['character']}"
    )
    chars_by_type[e["type"]].add(e["character"])

with open("assets/data/kana_data.json", "w", encoding="utf-8") as f:
    json.dump(all_entries, f, ensure_ascii=False, indent=2)

print(f"Wrote {len(all_entries)} entries ({hira_count} hiragana, {kata_count} katakana)")
