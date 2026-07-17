# Generates assets/data/kaiwa_data.json + assets/data/kaiwa/_categories.json
# for the Kaiwa module, mirroring generate_particle_seed.py's shape:
# hand-authored Python tuples -> JSON matching the Dart fromJson schema.
#
# Line tuple shapes:
#   NPC line:  ("npc", id_suffix, speaker, japanese, romaji, translation)
#     -> rendered as just an image + a speak button, no visible text.
#   User turn: ("user", id_suffix, [option_tuple, ...])
#     option_tuple: (japanese, romaji, translation, is_correct, expression_tag_or_None)
#     -> the learner taps one of these; there is no typing or speech
#        input anymore (that was the source of the crashes this module
#        used to have — see CLAUDE.md). Exactly one option per turn has
#        is_correct=True; the rest are hand-authored plausible-but-wrong
#        distractors, same "author explicitly, don't derive" reasoning as
#        ClozeExample's before/after split.
#
# Entry tuple: (id_suffix, title, description, [line_tuple, ...])
#
# NPC lines get an imagePath of the form
# "kaiwa_images/{category}/{entry_id}_{line_suffix}.png" — Firebase
# Storage paths that don't have real images uploaded yet, same gap
# already documented for Kotoba's vocab illustrations (KaiwaImage falls
# back to a placeholder gracefully, same as KotobaImage).
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
             "Salam kenal. Saya Yuki."),
            ("user", "2", [
                ("はじめまして。ブディです。よろしくお願いします。",
                 "Hajimemashite. Budi desu. Yoroshiku onegaishimasu.",
                 "Salam kenal. Saya Budi. Mohon bantuannya.", True, "sopan"),
                ("さようなら。", "Sayounara.", "Selamat tinggal.", False, None),
                ("いただきます。", "Itadakimasu.", "Selamat makan.", False, None),
            ]),
            ("npc", "3", "Yuki", "よろしくお願いします！ブディさんは学生ですか。",
             "Yoroshiku onegaishimasu! Budi-san wa gakusei desu ka.",
             "Senang berkenalan! Budi apakah kamu pelajar?"),
            ("user", "4", [
                ("はい、学生です。", "Hai, gakusei desu.", "Ya, saya pelajar.", True, None),
                ("猫が好きです。", "Neko ga suki desu.", "Saya suka kucing.", False, None),
                ("学校はどこですか。", "Gakkou wa doko desu ka.", "Di mana sekolahnya?", False, None),
            ]),
            ("npc", "5", "Yuki", "そうですか！日本語の勉強、頑張ってくださいね。",
             "Sou desu ka! Nihongo no benkyou, ganbatte kudasai ne.",
             "Begitu ya! Semangat belajar bahasa Jepangnya ya."),
            ("user", "6", [
                ("頑張ります！", "Ganbarimasu!", "Saya akan berusaha!", True, "semangat"),
                ("すみません。", "Sumimasen.", "Maaf/permisi.", False, None),
                ("いいえ、違います。", "Iie, chigaimasu.", "Bukan, itu salah.", False, None),
            ]),
            ("npc", "7", "Yuki", "それでは、また今度ね！", "Sore dewa, mata kondo ne!",
             "Kalau begitu, sampai jumpa lagi ya!"),
        ],
    ),
    (
        "sapa_pagi_hari",
        "Menyapa di Pagi Hari",
        "Pak Tanaka, tetanggamu, menyapamu di pagi hari sebelum berangkat sekolah.",
        [
            ("npc", "1", "Pak Tanaka", "おはようございます。今日もいい天気ですね。",
             "Ohayou gozaimasu. Kyou mo ii tenki desu ne.",
             "Selamat pagi. Hari ini cuacanya bagus juga ya."),
            ("user", "2", [
                ("おはようございます。", "Ohayou gozaimasu.", "Selamat pagi.", True, None),
                ("おやすみなさい。", "Oyasumi nasai.", "Selamat malam (sebelum tidur).", False, None),
                ("こんばんは。", "Konbanwa.", "Selamat malam.", False, None),
            ]),
            ("npc", "3", "Pak Tanaka", "これから学校ですか。", "Kore kara gakkou desu ka.",
             "Mau berangkat sekolah sekarang?"),
            ("user", "4", [
                ("はい、そうです。", "Hai, sou desu.", "Ya, benar.", True, None),
                ("いいえ、家にいます。", "Iie, ie ni imasu.", "Tidak, saya di rumah.", False, None),
                ("何ですか。", "Nan desu ka.", "Apa?", False, None),
            ]),
            ("npc", "5", "Pak Tanaka", "気をつけて行ってらっしゃい。",
             "Ki wo tsukete itterasshai.", "Hati-hati, selamat berangkat."),
            ("user", "6", [
                ("行ってきます。", "Itte kimasu.", "Saya berangkat (akan kembali).", True, None),
                ("ただいま。", "Tadaima.", "Saya pulang.", False, None),
                ("おかえりなさい。", "Okaerinasai.", "Selamat datang kembali.", False, None),
            ]),
        ],
    ),
    (
        "tanya_asal_negara",
        "Menanyakan Asal Negara",
        "Sari bertanya tentang asal negaramu dan makanan favorit di sana.",
        [
            ("npc", "1", "Sari", "ブディさんはどこの国から来ましたか。",
             "Budi-san wa doko no kuni kara kimashita ka.",
             "Budi berasal dari negara mana?"),
            ("user", "2", [
                ("インドネシアから来ました。", "Indonesia kara kimashita.",
                 "Saya datang dari Indonesia.", True, None),
                ("二十歳です。", "Hatachi desu.", "Saya berusia 20 tahun.", False, None),
                ("元気です。", "Genki desu.", "Saya baik-baik saja.", False, None),
            ]),
            ("npc", "3", "Sari", "そうなんですね！インドネシア料理は好きですか。",
             "Sou nan desu ne! Indonesia ryouri wa suki desu ka.",
             "Oh begitu! Apakah kamu suka masakan Indonesia?"),
            ("user", "4", [
                ("はい、好きです。", "Hai, suki desu.", "Ya, saya suka.", True, "senang"),
                ("いいえ、忙しいです。", "Iie, isogashii desu.", "Tidak, saya sibuk.", False, None),
                ("分かりません。", "Wakarimasen.", "Saya tidak mengerti.", False, None),
            ]),
            ("npc", "5", "Sari", "私も食べてみたいです！", "Watashi mo tabete mitai desu!",
             "Saya juga ingin coba makan itu!"),
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
             "Selamat datang! Sudah menentukan pesanan?"),
            ("user", "2", [
                ("ラーメンをお願いします。", "Raamen wo onegaishimasu.",
                 "Tolong pesanan ramen.", True, "sopan"),
                ("トイレはどこですか。", "Toire wa doko desu ka.", "Di mana toilet?", False, None),
                ("いくらですか。", "Ikura desu ka.", "Berapa harganya?", False, None),
            ]),
            ("npc", "3", "Pelayan", "かしこまりました。お飲み物はいかがですか。",
             "Kashikomarimashita. Onomimono wa ikaga desu ka.",
             "Baik. Bagaimana dengan minumannya?"),
            ("user", "4", [
                ("お水で大丈夫です。", "Omizu de daijoubu desu.",
                 "Air putih saja, tidak apa-apa.", True, None),
                ("ラーメンをお願いします。", "Raamen wo onegaishimasu.",
                 "Tolong pesanan ramen.", False, None),
                ("美味しいです。", "Oishii desu.", "Enak.", False, None),
            ]),
            ("npc", "5", "Pelayan", "少々お待ちください。", "Shoushou omachi kudasai.",
             "Mohon tunggu sebentar."),
        ],
    ),
    (
        "minta_bill",
        "Meminta Bill / Membayar",
        "Kamu selesai makan dan ingin membayar.",
        [
            ("user", "1", [
                ("すみません、お会計をお願いします。", "Sumimasen, okaikei wo onegaishimasu.",
                 "Permisi, tolong bill-nya.", True, "sopan"),
                ("いただきます。", "Itadakimasu.", "Selamat makan.", False, None),
                ("ごちそうさまでした。", "Gochisousama deshita.",
                 "Terima kasih atas makanannya.", False, None),
            ]),
            ("npc", "2", "Pelayan", "はい、少々お待ちください。", "Hai, shoushou omachi kudasai.",
             "Baik, mohon tunggu sebentar."),
            ("npc", "3", "Pelayan", "お待たせしました。1,200円になります。",
             "Omataseshimashita. Sen nihyaku en ni narimasu.",
             "Maaf menunggu. Totalnya 1.200 yen."),
            ("user", "4", [
                ("カードでお願いします。", "Kaado de onegaishimasu.",
                 "Tolong dengan kartu.", True, None),
                ("現金がありません。", "Genkin ga arimasen.",
                 "Saya tidak punya uang tunai.", False, None),
                ("おいしかったです。", "Oishikatta desu.", "Tadi enak.", False, None),
            ]),
            ("npc", "5", "Pelayan", "かしこまりました。ありがとうございました。",
             "Kashikomarimashita. Arigatou gozaimashita.",
             "Baik. Terima kasih banyak."),
        ],
    ),
    (
        "menu_rekomendasi",
        "Menanyakan Menu Rekomendasi",
        "Kamu bingung mau pesan apa dan bertanya rekomendasi ke pelayan.",
        [
            ("user", "1", [
                ("おすすめは何ですか。", "Osusume wa nan desu ka.",
                 "Apa yang direkomendasikan?", True, None),
                ("これは何ですか。", "Kore wa nan desu ka.", "Ini apa?", False, None),
                ("何時に開きますか。", "Nanji ni akimasu ka.", "Jam berapa buka?", False, None),
            ]),
            ("npc", "2", "Pelayan", "カレーが人気です。", "Kare ga ninki desu.",
             "Kari sedang populer."),
            ("user", "3", [
                ("それにします。", "Sore ni shimasu.", "Kalau begitu saya pesan itu.", True, None),
                ("それは要りません。", "Sore wa irimasen.", "Saya tidak butuh itu.", False, None),
                ("いつ来ますか。", "Itsu kimasu ka.", "Kapan datang?", False, None),
            ]),
            ("npc", "4", "Pelayan", "かしこまりました！", "Kashikomarimashita!", "Baik!"),
        ],
    ),
]

ENTRIES_BY_CATEGORY = {
    "perkenalan": PERKENALAN_ENTRIES,
    "restoran": RESTORAN_ENTRIES,
}


def build_line(raw, category, entry_id):
    if raw[0] == "npc":
        _, suffix, speaker, japanese, romaji, translation = raw
        return {
            "id": suffix,
            "speaker": speaker,
            "isUserTurn": False,
            "npcLine": {
                "japanese": japanese,
                "romaji": romaji,
                "translation": translation,
            },
            "imagePath": f"kaiwa_images/{category}/{entry_id}_{suffix}.png",
        }
    _, suffix, options = raw
    correct_count = sum(1 for o in options if o[3])
    assert correct_count == 1, (
        f"{entry_id}/{suffix}: exactly one option must be correct, found {correct_count}"
    )
    assert len(options) >= 2, f"{entry_id}/{suffix}: need at least 2 options"
    return {
        "id": suffix,
        "speaker": "Anda",
        "isUserTurn": True,
        "options": [
            {
                "japanese": japanese,
                "romaji": romaji,
                "translation": translation,
                "isCorrect": is_correct,
                "expressionTag": expression_tag,
            }
            for japanese, romaji, translation, is_correct, expression_tag in options
        ],
    }


def build_entries(entries, category, titles):
    assert [e[1] for e in entries] == titles, (
        f"{category}: authored titles don't match the locked list, in order"
    )
    result = []
    for id_suffix, title, description, lines in entries:
        entry_id = f"kaiwa_{id_suffix}"
        result.append({
            "id": entry_id,
            "title": title,
            "category": category,
            "description": description,
            "lines": [build_line(line, category, entry_id) for line in lines],
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
