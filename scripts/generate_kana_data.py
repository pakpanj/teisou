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
]

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
    "ni": ("ニュース", "nyuusu", "Berita"),
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
            entries.append({
                "id": f"{kana_type}_{romaji}",
                "character": char,
                "romaji": romaji,
                "type": kana_type,
                "row": row_index,
                "column": column,
                "svgAsset": f"assets/svg/{kana_type}/{romaji}.svg",
                "examples": examples,
            })
    return entries


all_entries = []
all_entries.extend(build_entries("hiragana", ROWS, HIRAGANA_EXAMPLES))
all_entries.extend(build_entries("katakana", ROWS, KATAKANA_EXAMPLES))

assert len(all_entries) == 92, f"Expected 92 entries, got {len(all_entries)}"
hira_count = sum(1 for e in all_entries if e["type"] == "hiragana")
kata_count = sum(1 for e in all_entries if e["type"] == "katakana")
assert hira_count == 46, f"Expected 46 hiragana, got {hira_count}"
assert kata_count == 46, f"Expected 46 katakana, got {kata_count}"

with open("assets/data/kana_data.json", "w", encoding="utf-8") as f:
    json.dump(all_entries, f, ensure_ascii=False, indent=2)

print(f"Wrote {len(all_entries)} entries ({hira_count} hiragana, {kata_count} katakana)")
