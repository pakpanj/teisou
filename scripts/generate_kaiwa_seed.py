# Generates assets/data/kaiwa_data.json + assets/data/kaiwa/_categories.json
# for the Kaiwa module, mirroring generate_particle_seed.py's shape:
# hand-authored Python tuples -> JSON matching the Dart fromJson schema.
#
# Line tuple shapes:
#   NPC line:  ("npc", id_suffix, speaker, japanese, romaji, translation, note_or_None)
#   User turn: ("user", id_suffix, prompt_hint, [answer_tuple, ...], note_or_None)
#     answer_tuple: (japanese, romaji, translation, variants_list, expression_tag_or_None)
#
# Entry tuple: (id_suffix, title, description, [line_tuple, ...])
#
# expression_tag values used here come from
# lib/core/constants/kaiwa_expressions.dart's kaiwaExpressionEmoji map —
# keep the two in sync if a new tag is introduced.

import json

from kaiwa_lists import AVAILABLE_CATEGORIES, CATEGORY_META, PLANNED_CATEGORIES

PERKENALAN_ENTRIES = [
    (
        "kenalan_teman_baru",
        "Berkenalan dengan Teman Baru",
        "Yuki menyapa dan berkenalan denganmu untuk pertama kalinya.",
        [
            ("npc", "1", "Yuki", "はじめまして。ゆきです。", "Hajimemashite. Yuki desu.",
             "Salam kenal. Saya Yuki.",
             "はじめまして dipakai khusus saat bertemu seseorang untuk pertama kali."),
            ("user", "2", "Balas salam ini dan sebutkan namamu (Budi)", [
                ("はじめまして。ブディです。よろしくお願いします。",
                 "Hajimemashite. Budi desu. Yoroshiku onegaishimasu.",
                 "Salam kenal. Saya Budi. Mohon bantuannya.",
                 ["はじめまして、ブディです。よろしくお願いします。"],
                 "sopan"),
                ("はじめまして。ブディです。",
                 "Hajimemashite. Budi desu.",
                 "Salam kenal. Saya Budi.",
                 ["はじめまして、ブディです。"],
                 None),
            ], None),
            ("npc", "3", "Yuki", "よろしくお願いします！ブディさんは学生ですか。",
             "Yoroshiku onegaishimasu! Budi-san wa gakusei desu ka.",
             "Senang berkenalan! Budi apakah kamu pelajar?", None),
            ("user", "4", "Jawab bahwa kamu pelajar (gakusei)", [
                ("はい、学生です。", "Hai, gakusei desu.", "Ya, saya pelajar.",
                 ["学生です。", "はい学生です。"], None),
            ], None),
            ("npc", "5", "Yuki", "そうですか！日本語の勉強、頑張ってくださいね。",
             "Sou desu ka! Nihongo no benkyou, ganbatte kudasai ne.",
             "Begitu ya! Semangat belajar bahasa Jepangnya ya.", None),
            ("user", "6", "Balas dengan semangat bahwa kamu akan berusaha", [
                ("頑張ります！", "Ganbarimasu!", "Saya akan berusaha!",
                 ["頑張ります。", "はい、頑張ります。"], "semangat"),
            ], "頑張ります adalah ungkapan umum untuk menunjukkan semangat/tekad, "
               "sering dipakai saat menerima dukungan atau memulai sesuatu."),
            ("npc", "7", "Yuki", "それでは、また今度ね！", "Sore dewa, mata kondo ne!",
             "Kalau begitu, sampai jumpa lagi ya!", None),
        ],
    ),
    (
        "sapa_pagi_hari",
        "Menyapa di Pagi Hari",
        "Pak Tanaka, tetanggamu, menyapamu di pagi hari sebelum berangkat sekolah.",
        [
            ("npc", "1", "Pak Tanaka", "おはようございます。今日もいい天気ですね。",
             "Ohayou gozaimasu. Kyou mo ii tenki desu ne.",
             "Selamat pagi. Hari ini cuacanya bagus juga ya.", None),
            ("user", "2", "Balas salam pagi ini", [
                ("おはようございます。", "Ohayou gozaimasu.", "Selamat pagi.",
                 ["おはようございます!"], None),
            ], None),
            ("npc", "3", "Pak Tanaka", "これから学校ですか。", "Kore kara gakkou desu ka.",
             "Mau berangkat sekolah sekarang?", None),
            ("user", "4", "Jawab iya, benar", [
                ("はい、そうです。", "Hai, sou desu.", "Ya, benar.",
                 ["はい。", "そうです。"], None),
            ], None),
            ("npc", "5", "Pak Tanaka", "気をつけて行ってらっしゃい。",
             "Ki wo tsukete itterasshai.", "Hati-hati, selamat berangkat.", None),
            ("user", "6", "Balas dengan ungkapan saat berangkat dari rumah", [
                ("行ってきます。", "Itte kimasu.", "Saya berangkat (akan kembali).",
                 [], None),
            ], "行ってきます diucapkan orang yang akan keluar rumah; "
               "dijawab lawan bicara dengan 行ってらっしゃい."),
        ],
    ),
    (
        "tanya_asal_negara",
        "Menanyakan Asal Negara",
        "Sari bertanya tentang asal negaramu dan makanan favorit di sana.",
        [
            ("npc", "1", "Sari", "ブディさんはどこの国から来ましたか。",
             "Budi-san wa doko no kuni kara kimashita ka.",
             "Budi berasal dari negara mana?", None),
            ("user", "2", "Jawab bahwa kamu datang dari Indonesia", [
                ("インドネシアから来ました。", "Indonesia kara kimashita.",
                 "Saya datang dari Indonesia.",
                 ["インドネシアです。", "インドネシア出身です。"], None),
            ], None),
            ("npc", "3", "Sari", "そうなんですね！インドネシア料理は好きですか。",
             "Sou nan desu ne! Indonesia ryouri wa suki desu ka.",
             "Oh begitu! Apakah kamu suka masakan Indonesia?", None),
            ("user", "4", "Jawab bahwa kamu suka", [
                ("はい、好きです。", "Hai, suki desu.", "Ya, saya suka.",
                 ["好きです。"], "senang"),
            ], None),
            ("npc", "5", "Sari", "私も食べてみたいです！", "Watashi mo tabete mitai desu!",
             "Saya juga ingin coba makan itu!", None),
        ],
    ),
]

RESTORAN_ENTRIES = [
    (
        "pesan_makanan",
        "Memesan Makanan di Restoran",
        "Kamu memesan makanan dan minuman ke pelayan restoran.",
        [
            ("npc", "1", "Pelayan", "いらっしゃいませ！ご注文はお決まりですか。",
             "Irasshaimase! Gochuumon wa okimari desu ka.",
             "Selamat datang! Sudah menentukan pesanan?", None),
            ("user", "2", "Pesan ramen", [
                ("ラーメンをお願いします。", "Raamen wo onegaishimasu.",
                 "Tolong pesanan ramen.",
                 ["ラーメンをください。", "ラーメンお願いします。"], "sopan"),
            ], None),
            ("npc", "3", "Pelayan", "かしこまりました。お飲み物はいかがですか。",
             "Kashikomarimashita. Onomimono wa ikaga desu ka.",
             "Baik. Bagaimana dengan minumannya?", None),
            ("user", "4", "Jawab air putih saja, tidak apa-apa", [
                ("お水で大丈夫です。", "Omizu de daijoubu desu.",
                 "Air putih saja, tidak apa-apa.",
                 ["水で大丈夫です。", "お水をお願いします。"], None),
            ], None),
            ("npc", "5", "Pelayan", "少々お待ちください。", "Shoushou omachi kudasai.",
             "Mohon tunggu sebentar.", None),
        ],
    ),
    (
        "minta_bill",
        "Meminta Bill / Membayar",
        "Kamu selesai makan dan ingin membayar.",
        [
            ("user", "1", "Panggil pelayan dan minta bill", [
                ("すみません、お会計をお願いします。", "Sumimasen, okaikei wo onegaishimasu.",
                 "Permisi, tolong bill-nya.",
                 ["お会計お願いします。", "すみません、会計お願いします。"], "sopan"),
            ], None),
            ("npc", "2", "Pelayan", "はい、少々お待ちください。", "Hai, shoushou omachi kudasai.",
             "Baik, mohon tunggu sebentar.", None),
            ("npc", "3", "Pelayan", "お待たせしました。1,200円になります。",
             "Omataseshimashita. Sen nihyaku en ni narimasu.",
             "Maaf menunggu. Totalnya 1.200 yen.", None),
            ("user", "4", "Bilang kamu akan bayar dengan kartu", [
                ("カードでお願いします。", "Kaado de onegaishimasu.",
                 "Tolong dengan kartu.",
                 ["カードで払います。"], None),
            ], None),
            ("npc", "5", "Pelayan", "かしこまりました。ありがとうございました。",
             "Kashikomarimashita. Arigatou gozaimashita.",
             "Baik. Terima kasih banyak.", None),
        ],
    ),
    (
        "menu_rekomendasi",
        "Menanyakan Menu Rekomendasi",
        "Kamu bingung mau pesan apa dan bertanya rekomendasi ke pelayan.",
        [
            ("user", "1", "Tanyakan apa yang direkomendasikan", [
                ("おすすめは何ですか。", "Osusume wa nan desu ka.",
                 "Apa yang direkomendasikan?",
                 ["おすすめは何ですか?", "何がおすすめですか。"], None),
            ], None),
            ("npc", "2", "Pelayan", "カレーが人気です。", "Kare ga ninki desu.",
             "Kari sedang populer.", None),
            ("user", "3", "Bilang kalau begitu kamu mau pesan itu", [
                ("それにします。", "Sore ni shimasu.", "Kalau begitu saya pesan itu.",
                 ["それをお願いします。"], None),
            ], None),
            ("npc", "4", "Pelayan", "かしこまりました！", "Kashikomarimashita!",
             "Baik!", None),
        ],
    ),
]

ENTRIES_BY_CATEGORY = {
    "perkenalan": PERKENALAN_ENTRIES,
    "restoran": RESTORAN_ENTRIES,
}


def build_line(raw):
    if raw[0] == "npc":
        _, suffix, speaker, japanese, romaji, translation, note = raw
        return {
            "id": f"{suffix}",
            "speaker": speaker,
            "isUserTurn": False,
            "npcLine": {
                "japanese": japanese,
                "romaji": romaji,
                "translation": translation,
            },
            "note": note,
        }
    _, suffix, prompt_hint, answers, note = raw
    return {
        "id": f"{suffix}",
        "speaker": "Anda",
        "isUserTurn": True,
        "promptHint": prompt_hint,
        "acceptedAnswers": [
            {
                "japanese": japanese,
                "romaji": romaji,
                "translation": translation,
                "variants": variants,
                "expressionTag": expression_tag,
            }
            for japanese, romaji, translation, variants, expression_tag in answers
        ],
        "note": note,
    }


def build_entries(entries, category, titles):
    assert [e[1] for e in entries] == titles, (
        f"{category}: authored titles don't match the locked list, in order"
    )
    result = []
    for id_suffix, title, description, lines in entries:
        result.append({
            "id": f"kaiwa_{id_suffix}",
            "title": title,
            "category": category,
            "description": description,
            "lines": [build_line(line) for line in lines],
        })
    return result


def main():
    all_entries = []
    for category, titles in AVAILABLE_CATEGORIES.items():
        entries = ENTRIES_BY_CATEGORY[category]
        built = build_entries(entries, category, titles)
        all_entries.extend(built)
        print(f"{category}: {len(built)} dialogues (of {len(titles)} locked)")

    with open("assets/data/kaiwa_data.json", "w", encoding="utf-8") as f:
        json.dump(all_entries, f, ensure_ascii=False, indent=2)

    categories = []
    for category_id, titles in AVAILABLE_CATEGORIES.items():
        name, icon = CATEGORY_META[category_id]
        categories.append({
            "id": category_id,
            "name": name,
            "icon": icon,
            "available": True,
            "dialogueCount": len(titles),
        })
    for category_id, name, icon in PLANNED_CATEGORIES:
        categories.append({
            "id": category_id,
            "name": name,
            "icon": icon,
            "available": False,
            "dialogueCount": None,
        })

    with open("assets/data/kaiwa/_categories.json", "w", encoding="utf-8") as f:
        json.dump(categories, f, ensure_ascii=False, indent=2)

    print(f"Total: {len(all_entries)} dialogues, {len(categories)} categories")


if __name__ == "__main__":
    main()
