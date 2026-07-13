import json

# Kotoba vocab — kategori "Ikan" (Batch 6 Fase 1).
#
# Untuk kata benda konkret seperti nama ikan, kata itu sendiri umumnya TIDAK
# berubah bentuk antara casual/formal/keigo (beda dengan salam/ekspresi di
# Batch 4) — kesopanan ada di kalimatnya (~です/~ます vs bentuk kamus),
# bukan di kata bendanya. `_plain_registers()` merefleksikan itu apa adanya
# alih-alih mengarang bentuk keigo yang tidak nyata dipakai.
#
# Each tuple:
# (id_suffix, kanji, hiragana, romaji, meaning, jlptLevel, examples)
# examples: list of (japanese, romaji, translation)

IMAGE_CATEGORY = "ikan"


def _plain_registers(word, romaji):
    return {
        "casual": f"{word} ({romaji})",
        "formal": f"{word} ({romaji}) — kesopanan ada di kalimat, mis. '~を食べます'",
        "keigo": f"{word} ({romaji}) — tidak ada bentuk keigo khusus untuk nama ikan",
    }


IKAN = [
    ("maguro", "鮪", "まぐろ", "maguro", "tuna", "N4", [
        ("まぐろを食べます。", "Maguro o tabemasu.", "Saya makan tuna."),
    ]),
    ("sake", "鮭", "さけ", "sake", "salmon", "N4", [
        ("鮭は魚です。", "Sake wa sakana desu.", "Salmon adalah ikan."),
    ]),
    ("tai", "鯛", "たい", "tai", "ikan kakap merah (sea bream)", "N4", [
        ("鯛はお祝いの魚です。", "Tai wa oiwai no sakana desu.", "Kakap merah adalah ikan untuk perayaan."),
    ]),
    ("unagi", "鰻", "うなぎ", "unagi", "belut", "N4", [
        ("夏はうなぎを食べます。", "Natsu wa unagi o tabemasu.", "Di musim panas, orang makan belut."),
    ]),
    ("iwashi", "鰯", "いわし", "iwashi", "ikan sarden", "N3", [
        ("いわしは安いです。", "Iwashi wa yasui desu.", "Ikan sarden itu murah."),
    ]),
    ("saba", "鯖", "さば", "saba", "ikan makarel", "N3", [
        ("さばを焼きました。", "Saba o yakimashita.", "Saya memanggang ikan makarel."),
    ]),
    ("katsuo", "鰹", "かつお", "katsuo", "ikan cakalang (bonito)", "N3", [
        ("かつおのお刺身が好きです。", "Katsuo no osashimi ga suki desu.", "Saya suka sashimi cakalang."),
    ]),
    ("fugu", "河豚", "ふぐ", "fugu", "ikan buntal (fugu)", "N3", [
        ("ふぐは高いですが、おいしいです。", "Fugu wa takai desu ga, oishii desu.", "Ikan buntal mahal, tapi enak."),
    ]),
]


def build_entries():
    entries = []
    for suffix, kanji, hiragana, romaji, meaning, level, examples in IKAN:
        entry_id = f"kotoba_{IMAGE_CATEGORY}_{suffix}"
        entries.append({
            "id": entry_id,
            "word": hiragana,
            "kanji": kanji,
            "reading": hiragana,
            "romaji": romaji,
            "meaning": meaning,
            "jlptLevel": level,
            "category": IMAGE_CATEGORY,
            "wordType": "noun",
            "registers": _plain_registers(hiragana, romaji),
            "sentenceExamples": [
                {"japanese": jp, "romaji": ro, "translation": tr}
                for jp, ro, tr in examples
            ],
            "imagePath": f"kotoba_images/{IMAGE_CATEGORY}/{entry_id}.png",
        })
    return entries


def main():
    data = build_entries()
    with open("assets/data/kotoba/ikan.json", "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
    print(f"Wrote {len(data)} entries to assets/data/kotoba/ikan.json")


if __name__ == "__main__":
    main()
