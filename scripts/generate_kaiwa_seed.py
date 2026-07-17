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

from kaiwa_lists import (
    AVAILABLE_CATEGORIES,
    CATEGORY_META,
    LEVEL_META,
    PLANNED_CATEGORIES,
)

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

STASIUN_ENTRIES = [
    (
        "beli_tiket",
        "Membeli Tiket Kereta",
        "Kamu membeli tiket kereta di loket stasiun.",
        [
            ("npc", "1", "Petugas Loket", "いらっしゃいませ。どちらまでですか。",
             "Irasshaimase. Dochira made desu ka.",
             "Selamat datang. Sampai mana?"),
            ("user", "2", [
                ("東京までお願いします。", "Toukyou made onegaishimasu.",
                 "Tolong sampai Tokyo.", True, "sopan"),
                ("東京から来ました。", "Toukyou kara kimashita.",
                 "Saya datang dari Tokyo.", False, None),
                ("今何時ですか。", "Ima nanji desu ka.", "Sekarang jam berapa?", False, None),
            ]),
            ("npc", "3", "Petugas Loket", "片道ですか、往復ですか。",
             "Katamichi desu ka, oufuku desu ka.",
             "Sekali jalan atau pulang-pergi?"),
            ("user", "4", [
                ("往復でお願いします。", "Oufuku de onegaishimasu.",
                 "Pulang-pergi, tolong.", True, None),
                ("大丈夫です。", "Daijoubu desu.", "Tidak apa-apa.", False, None),
                ("分かりません。", "Wakarimasen.", "Saya tidak tahu.", False, None),
            ]),
            ("npc", "5", "Petugas Loket", "かしこまりました。1,500円です。",
             "Kashikomarimashita. Sen gohyaku en desu.",
             "Baik. 1.500 yen."),
        ],
    ),
    (
        "tanya_peron",
        "Menanyakan Peron/Jalur",
        "Kamu bingung mencari peron kereta yang benar di stasiun.",
        [
            ("user", "1", [
                ("すみません、何番線ですか。", "Sumimasen, nanbansen desu ka.",
                 "Permisi, jalur berapa?", True, None),
                ("これは何ですか。", "Kore wa nan desu ka.", "Ini apa?", False, None),
                ("何時に着きますか。", "Nanji ni tsukimasu ka.", "Jam berapa sampai?", False, None),
            ]),
            ("npc", "2", "Petugas Stasiun", "3番線です。", "Sanbansen desu.", "Jalur 3."),
            ("user", "3", [
                ("ありがとうございます。", "Arigatou gozaimasu.", "Terima kasih.", True, None),
                ("すみませんでした。", "Sumimasen deshita.", "Maaf.", False, None),
                ("いいえ、結構です。", "Iie, kekkou desu.", "Tidak, tidak usah.", False, None),
            ]),
            ("npc", "4", "Petugas Stasiun", "どういたしまして。気をつけて。",
             "Dou itashimashite. Ki wo tsukete.", "Sama-sama. Hati-hati."),
        ],
    ),
    (
        "tanya_jadwal",
        "Menanyakan Jadwal Kereta",
        "Kamu ingin tahu kapan kereta berikutnya akan datang.",
        [
            ("npc", "1", "Petugas", "次の電車は10分後です。",
             "Tsugi no densha wa juppun go desu.", "Kereta berikutnya 10 menit lagi."),
            ("user", "2", [
                ("分かりました、ありがとうございます。", "Wakarimashita, arigatou gozaimasu.",
                 "Baik, terima kasih.", True, None),
                ("いいえ、違います。", "Iie, chigaimasu.", "Bukan, itu salah.", False, None),
                ("どこですか。", "Doko desu ka.", "Di mana?", False, None),
            ]),
            ("npc", "3", "Petugas", "待合室でお待ちください。",
             "Machiaishitsu de omachi kudasai.", "Silakan tunggu di ruang tunggu."),
            ("user", "4", [
                ("はい、分かりました。", "Hai, wakarimashita.", "Baik, mengerti.", True, None),
                ("いいえ、急いでいます。", "Iie, isoide imasu.",
                 "Tidak, saya sedang buru-buru.", False, None),
                ("おいしいです。", "Oishii desu.", "Enak.", False, None),
            ]),
        ],
    ),
]

BELANJA_ENTRIES = [
    (
        "tanya_harga",
        "Menanyakan Harga Barang",
        "Kamu bertanya harga sebuah barang di toko.",
        [
            ("user", "1", [
                ("これはいくらですか。", "Kore wa ikura desu ka.",
                 "Ini berapa harganya?", True, None),
                ("これは何ですか。", "Kore wa nan desu ka.", "Ini apa?", False, None),
                ("これをください。", "Kore wo kudasai.", "Tolong ini.", False, None),
            ]),
            ("npc", "2", "Pemilik Toko", "500円です。", "Gohyaku en desu.", "500 yen."),
            ("user", "3", [
                ("じゃあ、これをください。", "Jaa, kore wo kudasai.",
                 "Kalau begitu, saya beli ini.", True, None),
                ("高いですね。さようなら。", "Takai desu ne. Sayounara.",
                 "Mahal ya. Sampai jumpa.", False, None),
                ("何時に閉まりますか。", "Nanji ni shimarimasu ka.",
                 "Jam berapa tutup?", False, None),
            ]),
            ("npc", "4", "Pemilik Toko", "ありがとうございます！", "Arigatou gozaimasu!",
             "Terima kasih!"),
        ],
    ),
    (
        "coba_baju",
        "Mencoba Baju di Toko",
        "Kamu ingin mencoba baju sebelum membeli.",
        [
            ("user", "1", [
                ("これを試着してもいいですか。", "Kore wo shichaku shite mo ii desu ka.",
                 "Boleh saya coba baju ini?", True, "sopan"),
                ("これは私のです。", "Kore wa watashi no desu.",
                 "Ini punya saya.", False, None),
                ("好きじゃないです。", "Suki janai desu.", "Saya tidak suka.", False, None),
            ]),
            ("npc", "2", "Pegawai Toko", "はい、どうぞ。試着室はあちらです。",
             "Hai, douzo. Shichakushitsu wa achira desu.",
             "Ya, silakan. Ruang ganti di sebelah sana."),
            ("user", "3", [
                ("ありがとうございます。", "Arigatou gozaimasu.", "Terima kasih.", True, None),
                ("いいえ、大丈夫です。", "Iie, daijoubu desu.", "Tidak, tidak apa-apa.", False, None),
                ("分かりません。", "Wakarimasen.", "Saya tidak mengerti.", False, None),
            ]),
            ("npc", "4", "Pegawai Toko", "サイズはいかがですか。", "Saizu wa ikaga desu ka.",
             "Bagaimana ukurannya?"),
            ("user", "5", [
                ("ちょうどいいです。", "Choudo ii desu.", "Pas sekali.", True, None),
                ("高いですね。", "Takai desu ne.", "Mahal ya.", False, None),
                ("何色がありますか。", "Nani iro ga arimasu ka.",
                 "Ada warna apa saja?", False, None),
            ]),
            ("npc", "6", "Pegawai Toko", "よかったです！", "Yokatta desu!", "Syukurlah!"),
        ],
    ),
    (
        "bayar_kasir",
        "Membayar di Kasir",
        "Kamu membayar barang belanjaan di kasir.",
        [
            ("npc", "1", "Kasir", "袋は要りますか。", "Fukuro wa irimasu ka.",
             "Perlu kantong plastik?"),
            ("user", "2", [
                ("はい、お願いします。", "Hai, onegaishimasu.", "Ya, tolong.", True, None),
                ("いいえ、これは要りません。", "Iie, kore wa irimasen.",
                 "Tidak, saya tidak butuh ini.", False, None),
                ("何時ですか。", "Nanji desu ka.", "Jam berapa?", False, None),
            ]),
            ("npc", "3", "Kasir", "合計800円です。", "Goukei happyaku en desu.",
             "Totalnya 800 yen."),
            ("user", "4", [
                ("はい、どうぞ。", "Hai, douzo.", "Ini, silakan.", True, None),
                ("いくらですか。", "Ikura desu ka.", "Berapa harganya?", False, None),
                ("おいしいです。", "Oishii desu.", "Enak.", False, None),
            ]),
            ("npc", "5", "Kasir", "ありがとうございました！", "Arigatou gozaimashita!",
             "Terima kasih banyak!"),
        ],
    ),
]

ARAH_JALAN_ENTRIES = [
    (
        "jalan_ke_stasiun",
        "Menanyakan Jalan ke Stasiun",
        "Kamu tersesat dan bertanya arah ke stasiun kepada orang di jalan.",
        [
            ("user", "1", [
                ("すみません、駅はどこですか。", "Sumimasen, eki wa doko desu ka.",
                 "Permisi, di mana stasiun?", True, None),
                ("これは駅ですか。", "Kore wa eki desu ka.", "Ini stasiun?", False, None),
                ("駅が好きです。", "Eki ga suki desu.", "Saya suka stasiun.", False, None),
            ]),
            ("npc", "2", "Orang di Jalan", "まっすぐ行って、右に曲がってください。",
             "Massugu itte, migi ni magatte kudasai.",
             "Jalan lurus, lalu belok kanan."),
            ("user", "3", [
                ("分かりました。ありがとうございます。", "Wakarimashita. Arigatou gozaimasu.",
                 "Mengerti. Terima kasih.", True, None),
                ("いいえ、分かりません。", "Iie, wakarimasen.",
                 "Tidak, saya tidak mengerti.", False, None),
                ("何を食べますか。", "Nani wo tabemasu ka.", "Makan apa?", False, None),
            ]),
            ("npc", "4", "Orang di Jalan", "どういたしまして！", "Dou itashimashite!",
             "Sama-sama!"),
        ],
    ),
    (
        "jalan_ke_toilet",
        "Menanyakan Jalan ke Toilet Umum",
        "Kamu mencari toilet umum di area wisata.",
        [
            ("user", "1", [
                ("すみません、トイレはどこですか。", "Sumimasen, toire wa doko desu ka.",
                 "Permisi, di mana toilet?", True, None),
                ("トイレは嫌いです。", "Toire wa kirai desu.",
                 "Saya tidak suka toilet.", False, None),
                ("何時ですか。", "Nanji desu ka.", "Jam berapa?", False, None),
            ]),
            ("npc", "2", "Petugas", "あそこにあります。", "Asoko ni arimasu.", "Ada di sana."),
            ("user", "3", [
                ("ありがとうございます。", "Arigatou gozaimasu.", "Terima kasih.", True, None),
                ("いいえ、結構です。", "Iie, kekkou desu.", "Tidak, tidak usah.", False, None),
                ("すみませんでした。", "Sumimasen deshita.", "Maaf.", False, None),
            ]),
            ("npc", "4", "Petugas", "どういたしまして。", "Dou itashimashite.", "Sama-sama."),
        ],
    ),
    (
        "tanya_jarak",
        "Menanyakan Jarak Tempuh",
        "Kamu ingin tahu seberapa jauh tempat tujuanmu.",
        [
            ("user", "1", [
                ("ここから遠いですか。", "Koko kara tooi desu ka.",
                 "Apakah jauh dari sini?", True, None),
                ("ここは近いです。", "Koko wa chikai desu.", "Sini dekat.", False, None),
                ("何がありますか。", "Nani ga arimasu ka.", "Ada apa saja?", False, None),
            ]),
            ("npc", "2", "Orang di Jalan", "いいえ、近いですよ。歩いて5分です。",
             "Iie, chikai desu yo. Aruite gofun desu.",
             "Tidak, dekat kok. Jalan kaki 5 menit."),
            ("user", "3", [
                ("そうですか。ありがとうございます。", "Sou desu ka. Arigatou gozaimasu.",
                 "Begitu ya. Terima kasih.", True, None),
                ("とても遠いですね。", "Totemo tooi desu ne.", "Jauh sekali ya.", False, None),
                ("いくらですか。", "Ikura desu ka.", "Berapa harganya?", False, None),
            ]),
            ("npc", "4", "Orang di Jalan", "気をつけて行ってください。",
             "Ki wo tsukete itte kudasai.", "Hati-hati di jalan."),
        ],
    ),
]

SEKOLAH_ENTRIES = [
    (
        "sapa_guru",
        "Menyapa Guru di Kelas",
        "Kamu menyapa gurumu di pagi hari sebelum kelas dimulai.",
        [
            ("npc", "1", "Bu Guru", "おはようございます、皆さん。",
             "Ohayou gozaimasu, minasan.", "Selamat pagi, semuanya."),
            ("user", "2", [
                ("おはようございます、先生。", "Ohayou gozaimasu, sensei.",
                 "Selamat pagi, Bu Guru.", True, None),
                ("こんにちは、先生。", "Konnichiwa, sensei.",
                 "Selamat siang, Bu Guru.", False, None),
                ("さようなら、先生。", "Sayounara, sensei.",
                 "Selamat tinggal, Bu Guru.", False, None),
            ]),
            ("npc", "3", "Bu Guru", "今日も頑張りましょう！", "Kyou mo ganbarimashou!",
             "Ayo semangat hari ini juga!"),
            ("user", "4", [
                ("はい！頑張ります！", "Hai! Ganbarimasu!",
                 "Ya! Saya akan berusaha!", True, "semangat"),
                ("いいえ、疲れました。", "Iie, tsukaremashita.",
                 "Tidak, saya lelah.", False, None),
                ("分かりません。", "Wakarimasen.", "Saya tidak mengerti.", False, None),
            ]),
        ],
    ),
    (
        "tanya_pr",
        "Menanyakan Pekerjaan Rumah (PR)",
        "Kamu bertanya kepada teman tentang PR yang diberikan hari ini.",
        [
            ("user", "1", [
                ("今日の宿題は何ですか。", "Kyou no shukudai wa nan desu ka.",
                 "PR hari ini apa?", True, None),
                ("今日は何曜日ですか。", "Kyou wa nanyoubi desu ka.",
                 "Hari ini hari apa?", False, None),
                ("宿題が好きです。", "Shukudai ga suki desu.",
                 "Saya suka PR.", False, None),
            ]),
            ("npc", "2", "Kenji", "数学のページ10です。", "Suugaku no peeji juu desu.",
             "Matematika halaman 10."),
            ("user", "3", [
                ("分かりました、ありがとう。", "Wakarimashita, arigatou.",
                 "Mengerti, terima kasih.", True, None),
                ("いいえ、違います。", "Iie, chigaimasu.", "Bukan, itu salah.", False, None),
                ("何時ですか。", "Nanji desu ka.", "Jam berapa?", False, None),
            ]),
            ("npc", "4", "Kenji", "どういたしまして。", "Dou itashimashite.", "Sama-sama."),
        ],
    ),
    (
        "pinjam_alat_tulis",
        "Meminjam Alat Tulis",
        "Kamu lupa membawa pensil dan ingin meminjam dari teman.",
        [
            ("user", "1", [
                ("鉛筆を貸してくれますか。", "Enpitsu wo kashite kuremasu ka.",
                 "Bisa pinjamkan pensil?", True, "sopan"),
                ("鉛筆をあげます。", "Enpitsu wo agemasu.",
                 "Saya kasih pensil.", False, None),
                ("鉛筆が嫌いです。", "Enpitsu ga kirai desu.",
                 "Saya tidak suka pensil.", False, None),
            ]),
            ("npc", "2", "Rina", "はい、どうぞ。", "Hai, douzo.", "Ya, silakan."),
            ("user", "3", [
                ("ありがとう！", "Arigatou!", "Terima kasih!", True, None),
                ("いいえ、結構です。", "Iie, kekkou desu.", "Tidak, tidak usah.", False, None),
                ("すみませんでした。", "Sumimasen deshita.", "Maaf.", False, None),
            ]),
            ("npc", "4", "Rina", "どういたしまして。", "Dou itashimashite.", "Sama-sama."),
        ],
    ),
]

CUACA_BASA_BASI_ENTRIES = [
    (
        "bicara_cuaca",
        "Membicarakan Cuaca",
        "Kamu berbincang ringan tentang cuaca dengan tetangga.",
        [
            ("npc", "1", "Bu Sato", "今日は暑いですね。", "Kyou wa atsui desu ne.",
             "Hari ini panas ya."),
            ("user", "2", [
                ("そうですね、とても暑いです。", "Sou desu ne, totemo atsui desu.",
                 "Iya ya, panas sekali.", True, None),
                ("いいえ、寒いです。", "Iie, samui desu.", "Tidak, dingin.", False, None),
                ("何時ですか。", "Nanji desu ka.", "Jam berapa?", False, None),
            ]),
            ("npc", "3", "Bu Sato", "明日は雨だそうですよ。", "Ashita wa ame da sou desu yo.",
             "Katanya besok hujan lho."),
            ("user", "4", [
                ("そうですか。傘を持って行きます。", "Sou desu ka. Kasa wo motte ikimasu.",
                 "Begitu ya. Saya akan bawa payung.", True, None),
                ("いいですね！プールに行きましょう。", "Ii desu ne! Puuru ni ikimashou.",
                 "Bagus! Ayo ke kolam renang.", False, None),
                ("分かりません。", "Wakarimasen.", "Saya tidak mengerti.", False, None),
            ]),
        ],
    ),
    (
        "tanya_akhir_pekan",
        "Menanyakan Kegiatan Akhir Pekan",
        "Temanmu bertanya tentang rencana akhir pekanmu.",
        [
            ("npc", "1", "Haruto", "週末は何をしますか。", "Shuumatsu wa nani wo shimasu ka.",
             "Akhir pekan mau ngapain?"),
            ("user", "2", [
                ("友達と映画を見ます。", "Tomodachi to eiga wo mimasu.",
                 "Nonton film sama teman.", True, None),
                ("明日は月曜日です。", "Ashita wa getsuyoubi desu.",
                 "Besok hari Senin.", False, None),
                ("好きじゃないです。", "Suki janai desu.", "Saya tidak suka.", False, None),
            ]),
            ("npc", "3", "Haruto", "いいですね！楽しんでください。", "Ii desu ne! Tanoshinde kudasai.",
             "Bagus! Semoga senang ya."),
            ("user", "4", [
                ("ありがとう。ハルトさんも楽しんでね。", "Arigatou. Haruto-san mo tanoshinde ne.",
                 "Terima kasih. Haruto juga semoga senang ya.", True, None),
                ("いいえ、疲れました。", "Iie, tsukaremashita.",
                 "Tidak, saya lelah.", False, None),
                ("何ですか。", "Nan desu ka.", "Apa?", False, None),
            ]),
        ],
    ),
    (
        "berpamitan",
        "Berpamitan",
        "Kamu berpamitan dengan teman setelah bertemu di jalan.",
        [
            ("npc", "1", "Aiko", "そろそろ帰ります。またね！", "Sorosoro kaerimasu. Mata ne!",
             "Saya pulang dulu ya. Sampai jumpa!"),
            ("user", "2", [
                ("またね！気をつけて。", "Mata ne! Ki wo tsukete.",
                 "Sampai jumpa! Hati-hati.", True, None),
                ("おはようございます。", "Ohayou gozaimasu.",
                 "Selamat pagi.", False, None),
                ("いただきます。", "Itadakimasu.", "Selamat makan.", False, None),
            ]),
            ("npc", "3", "Aiko", "ありがとう！バイバイ！", "Arigatou! Baibai!",
             "Terima kasih! Dadah!"),
            ("user", "4", [
                ("バイバイ！", "Baibai!", "Dadah!", True, None),
                ("はじめまして。", "Hajimemashite.", "Salam kenal.", False, None),
                ("いいえ、違います。", "Iie, chigaimasu.", "Bukan, itu salah.", False, None),
            ]),
        ],
    ),
]

RUMAH_SAKIT_ENTRIES = [
    (
        "jelaskan_sakit",
        "Menjelaskan Sakit ke Dokter",
        "Kamu merasa tidak enak badan dan pergi ke dokter.",
        [
            ("npc", "1", "Dokter", "どうしましたか。", "Dou shimashita ka.",
             "Ada apa? (keluhannya apa)"),
            ("user", "2", [
                ("頭が痛いです。", "Atama ga itai desu.", "Kepala saya sakit.", True, None),
                ("元気です。", "Genki desu.", "Saya baik-baik saja.", False, None),
                ("お腹が空きました。", "Onaka ga sukimashita.", "Saya lapar.", False, None),
            ]),
            ("npc", "3", "Dokter", "いつから痛いですか。", "Itsu kara itai desu ka.",
             "Sejak kapan sakitnya?"),
            ("user", "4", [
                ("昨日からです。", "Kinou kara desu.", "Sejak kemarin.", True, None),
                ("病院が好きです。", "Byouin ga suki desu.", "Saya suka rumah sakit.", False, None),
                ("大丈夫です。", "Daijoubu desu.", "Tidak apa-apa.", False, None),
            ]),
            ("npc", "5", "Dokter", "分かりました。薬を出しますね。",
             "Wakarimashita. Kusuri wo dashimasu ne.", "Baik. Saya kasih obat ya."),
        ],
    ),
    (
        "janji_temu",
        "Membuat Janji Temu",
        "Kamu menelepon rumah sakit untuk membuat janji temu dengan dokter.",
        [
            ("user", "1", [
                ("予約をしたいです。", "Yoyaku wo shitai desu.",
                 "Saya mau membuat janji temu.", True, None),
                ("予約はいりません。", "Yoyaku wa irimasen.",
                 "Saya tidak butuh janji temu.", False, None),
                ("薬をください。", "Kusuri wo kudasai.", "Tolong obatnya.", False, None),
            ]),
            ("npc", "2", "Resepsionis", "いつがいいですか。", "Itsu ga ii desu ka.",
             "Kapan yang cocok?"),
            ("user", "3", [
                ("明日の午後がいいです。", "Ashita no gogo ga ii desu.",
                 "Besok siang cocok.", True, None),
                ("病院は休みです。", "Byouin wa yasumi desu.", "Rumah sakit libur.", False, None),
                ("分かりません。", "Wakarimasen.", "Saya tidak tahu.", False, None),
            ]),
            ("npc", "4", "Resepsionis", "かしこまりました。お待ちしております。",
             "Kashikomarimashita. Omachi shite orimasu.", "Baik. Kami tunggu ya."),
        ],
    ),
    (
        "beli_obat",
        "Membeli Obat di Apotek",
        "Kamu membeli obat sesuai resep dokter di apotek.",
        [
            ("user", "1", [
                ("この薬をください。", "Kono kusuri wo kudasai.",
                 "Tolong obat ini.", True, None),
                ("この薬は要りません。", "Kono kusuri wa irimasen.",
                 "Saya tidak butuh obat ini.", False, None),
                ("いつ開きますか。", "Itsu akimasu ka.", "Kapan buka?", False, None),
            ]),
            ("npc", "2", "Apoteker", "一日三回飲んでください。",
             "Ichinichi sankai nonde kudasai.", "Minum 3 kali sehari."),
            ("user", "3", [
                ("分かりました、ありがとうございます。", "Wakarimashita, arigatou gozaimasu.",
                 "Baik, terima kasih.", True, None),
                ("いいえ、飲みません。", "Iie, nomimasen.",
                 "Tidak, saya tidak akan minum.", False, None),
                ("高いですね。", "Takai desu ne.", "Mahal ya.", False, None),
            ]),
            ("npc", "4", "Apoteker", "お大事に。", "Odaiji ni.", "Semoga cepat sembuh."),
        ],
    ),
]

HOBI_ENTRIES = [
    (
        "tanya_hobi",
        "Menanyakan Hobi Teman",
        "Rina bertanya tentang hobimu.",
        [
            ("npc", "1", "Rina", "趣味は何ですか。", "Shumi wa nan desu ka.",
             "Hobinya apa?"),
            ("user", "2", [
                ("読書です。", "Dokusho desu.", "Membaca buku.", True, None),
                ("忙しいです。", "Isogashii desu.", "Saya sibuk.", False, None),
                ("学生です。", "Gakusei desu.", "Saya pelajar.", False, None),
            ]),
            ("npc", "3", "Rina", "いいですね！どんな本が好きですか。",
             "Ii desu ne! Donna hon ga suki desu ka.", "Bagus! Suka buku seperti apa?"),
            ("user", "4", [
                ("漫画が好きです。", "Manga ga suki desu.", "Saya suka komik.", True, None),
                ("本は嫌いです。", "Hon wa kirai desu.", "Saya tidak suka buku.", False, None),
                ("何時ですか。", "Nanji desu ka.", "Jam berapa?", False, None),
            ]),
        ],
    ),
    (
        "ajak_bermain",
        "Mengajak Bermain Bersama",
        "Kamu mengajak Kenta bermain bersama.",
        [
            ("user", "1", [
                ("今度一緒に遊びませんか。", "Kondo issho ni asobimasen ka.",
                 "Lain kali main bareng yuk?", True, None),
                ("一人で遊びます。", "Hitori de asobimasu.", "Saya main sendiri.", False, None),
                ("遊びは嫌いです。", "Asobi wa kirai desu.", "Saya tidak suka main.", False, None),
            ]),
            ("npc", "2", "Kenta", "いいですね！何をしますか。",
             "Ii desu ne! Nani wo shimasu ka.", "Boleh! Mau ngapain?"),
            ("user", "3", [
                ("ゲームをしましょう。", "Geemu wo shimashou.", "Ayo main gim.", True, None),
                ("勉強しましょう。", "Benkyou shimashou.", "Ayo belajar.", False, None),
                ("分かりません。", "Wakarimasen.", "Saya tidak tahu.", False, None),
            ]),
            ("npc", "4", "Kenta", "楽しみです！", "Tanoshimi desu!", "Aku menantikannya!"),
        ],
    ),
    (
        "musik_favorit",
        "Membicarakan Musik Favorit",
        "Kamu dan Mika membicarakan musik favorit kalian.",
        [
            ("npc", "1", "Mika", "どんな音楽が好きですか。",
             "Donna ongaku ga suki desu ka.", "Suka musik seperti apa?"),
            ("user", "2", [
                ("J-POPが好きです。", "Jeipoppu ga suki desu.", "Saya suka J-Pop.", True, None),
                ("音楽は聞きません。", "Ongaku wa kikimasen.", "Saya tidak dengar musik.", False, None),
                ("静かです。", "Shizuka desu.", "Tenang/sepi.", False, None),
            ]),
            ("npc", "3", "Mika", "私も好きです！コンサートに行きたいですね。",
             "Watashi mo suki desu! Konsaato ni ikitai desu ne.",
             "Saya juga suka! Pengen nonton konser ya."),
            ("user", "4", [
                ("いいですね、一緒に行きましょう。", "Ii desu ne, issho ni ikimashou.",
                 "Boleh, ayo pergi bareng.", True, None),
                ("コンサートは高いです。行きません。", "Konsaato wa takai desu. Ikimasen.",
                 "Konser mahal. Saya tidak pergi.", False, None),
                ("何ですか。", "Nan desu ka.", "Apa?", False, None),
            ]),
        ],
    ),
]

TELEPON_ENTRIES = [
    (
        "terima_telepon",
        "Menerima Telepon",
        "Tanaka meneleponmu.",
        [
            ("npc", "1", "Tanaka", "もしもし、田中です。", "Moshi moshi, Tanaka desu.",
             "Halo, ini Tanaka."),
            ("user", "2", [
                ("もしもし、ブディです。", "Moshi moshi, Budi desu.",
                 "Halo, ini Budi.", True, None),
                ("さようなら、田中です。", "Sayounara, Tanaka desu.",
                 "Selamat tinggal, ini Tanaka.", False, None),
                ("いただきます。", "Itadakimasu.", "Selamat makan.", False, None),
            ]),
            ("npc", "3", "Tanaka", "今、時間がありますか。", "Ima, jikan ga arimasu ka.",
             "Sekarang ada waktu?"),
            ("user", "4", [
                ("はい、大丈夫です。", "Hai, daijoubu desu.", "Ya, bisa.", True, None),
                ("いいえ、行きません。", "Iie, ikimasen.", "Tidak, saya tidak akan pergi.", False, None),
                ("何時ですか。", "Nanji desu ka.", "Jam berapa?", False, None),
            ]),
        ],
    ),
    (
        "telepon_teman",
        "Menelepon Teman",
        "Kamu menelepon Sari untuk mengajak belajar bersama.",
        [
            ("user", "1", [
                ("もしもし、今大丈夫ですか。", "Moshi moshi, ima daijoubu desu ka.",
                 "Halo, sekarang lagi luang?", True, None),
                ("もしもし、さようなら。", "Moshi moshi, sayounara.",
                 "Halo, selamat tinggal.", False, None),
                ("忙しいですか。", "Isogashii desu ka.", "Apakah sibuk?", False, None),
            ]),
            ("npc", "2", "Sari", "うん、大丈夫だよ。どうしたの？",
             "Un, daijoubu da yo. Doushita no?", "Iya, luang kok. Ada apa?"),
            ("user", "3", [
                ("明日一緒に勉強しませんか。", "Ashita issho ni benkyou shimasen ka.",
                 "Besok belajar bareng yuk?", True, None),
                ("明日休みます。", "Ashita yasumimasu.", "Besok saya libur.", False, None),
                ("何も食べません。", "Nani mo tabemasen.", "Saya tidak makan apa-apa.", False, None),
            ]),
            ("npc", "4", "Sari", "いいよ！何時にする？", "Ii yo! Nanji ni suru?",
             "Boleh! Jam berapa?"),
        ],
    ),
    (
        "tinggalkan_pesan",
        "Meninggalkan Pesan",
        "Orang yang kamu cari sedang tidak ada di tempat.",
        [
            ("npc", "1", "Penerima Telepon", "すみません、今いません。",
             "Sumimasen, ima imasen.", "Maaf, dia sedang tidak ada."),
            ("user", "2", [
                ("では、伝言をお願いできますか。", "Dewa, dengon wo onegai dekimasu ka.",
                 "Kalau begitu, boleh tolong sampaikan pesan?", True, "sopan"),
                ("では、さようなら。", "Dewa, sayounara.",
                 "Kalau begitu, sampai jumpa.", False, None),
                ("いつ帰りますか。", "Itsu kaerimasu ka.", "Kapan pulang?", False, None),
            ]),
            ("npc", "3", "Penerima Telepon", "はい、どうぞ。", "Hai, douzo.", "Ya, silakan."),
            ("user", "4", [
                ("また電話しますと伝えてください。", "Mata denwa shimasu to tsutaete kudasai.",
                 "Tolong sampaikan saya akan telepon lagi.", True, None),
                ("何も伝えないでください。", "Nani mo tsutaenaide kudasai.",
                 "Tolong jangan sampaikan apa-apa.", False, None),
                ("おいしいです。", "Oishii desu.", "Enak.", False, None),
            ]),
        ],
    ),
]

TRANSPORTASI_ENTRIES = [
    (
        "naik_bus",
        "Naik Bus",
        "Kamu memastikan tujuan bus dengan sopirnya.",
        [
            ("user", "1", [
                ("このバスは駅に行きますか。", "Kono basu wa eki ni ikimasu ka.",
                 "Bus ini ke stasiun?", True, None),
                ("このバスは高いです。", "Kono basu wa takai desu.",
                 "Bus ini mahal.", False, None),
                ("バスが好きです。", "Basu ga suki desu.", "Saya suka bus.", False, None),
            ]),
            ("npc", "2", "Sopir Bus", "はい、行きますよ。", "Hai, ikimasu yo.",
             "Ya, ke sana kok."),
            ("user", "3", [
                ("良かったです、ありがとうございます。", "Yokatta desu, arigatou gozaimasu.",
                 "Syukurlah, terima kasih.", True, None),
                ("残念です。", "Zannen desu.", "Sayang sekali.", False, None),
                ("どこですか。", "Doko desu ka.", "Di mana?", False, None),
            ]),
            ("npc", "4", "Sopir Bus", "どういたしまして。", "Dou itashimashite.", "Sama-sama."),
        ],
    ),
    (
        "panggil_taksi",
        "Memanggil Taksi",
        "Kamu meminta resepsionis hotel memanggilkan taksi.",
        [
            ("user", "1", [
                ("タクシーを呼んでもらえますか。", "Takushii wo yonde moraemasu ka.",
                 "Bisa tolong panggilkan taksi?", True, "sopan"),
                ("タクシーは要りません。", "Takushii wa irimasen.",
                 "Saya tidak butuh taksi.", False, None),
                ("バスに乗ります。", "Basu ni norimasu.", "Saya naik bus.", False, None),
            ]),
            ("npc", "2", "Resepsionis Hotel", "はい、少々お待ちください。",
             "Hai, shoushou omachi kudasai.", "Baik, mohon tunggu sebentar."),
            ("user", "3", [
                ("ありがとうございます。", "Arigatou gozaimasu.", "Terima kasih.", True, None),
                ("遅いですね。", "Osoi desu ne.", "Lama ya.", False, None),
                ("いいえ、結構です。", "Iie, kekkou desu.", "Tidak, tidak usah.", False, None),
            ]),
            ("npc", "4", "Resepsionis Hotel", "タクシーが来ました。", "Takushii ga kimashita.",
             "Taksinya sudah datang."),
        ],
    ),
    (
        "tanya_ongkos",
        "Menanyakan Ongkos",
        "Kamu menanyakan ongkos taksi ke sopir.",
        [
            ("user", "1", [
                ("駅までいくらですか。", "Eki made ikura desu ka.",
                 "Sampai stasiun berapa harganya?", True, None),
                ("駅はどこですか。", "Eki wa doko desu ka.", "Di mana stasiun?", False, None),
                ("駅は好きです。", "Eki wa suki desu.", "Saya suka stasiun.", False, None),
            ]),
            ("npc", "2", "Sopir Taksi", "1,000円くらいです。", "Sen en kurai desu.",
             "Sekitar 1.000 yen."),
            ("user", "3", [
                ("分かりました、お願いします。", "Wakarimashita, onegaishimasu.",
                 "Baik, tolong.", True, None),
                ("高すぎます。降ります。", "Takasugimasu. Orimasu.",
                 "Terlalu mahal. Saya turun.", False, None),
                ("いつ着きますか。", "Itsu tsukimasu ka.", "Kapan sampai?", False, None),
            ]),
            ("npc", "4", "Sopir Taksi", "かしこまりました。出発します。",
             "Kashikomarimashita. Shuppatsu shimasu.", "Baik. Kita berangkat."),
        ],
    ),
]

KANTOR_POS_ENTRIES = [
    (
        "kirim_surat",
        "Mengirim Surat",
        "Kamu mengirim surat ke luar negeri lewat kantor pos.",
        [
            ("user", "1", [
                ("この手紙を送りたいです。", "Kono tegami wo okuritai desu.",
                 "Saya mau mengirim surat ini.", True, None),
                ("この手紙は要りません。", "Kono tegami wa irimasen.",
                 "Saya tidak butuh surat ini.", False, None),
                ("手紙が好きです。", "Tegami ga suki desu.", "Saya suka surat.", False, None),
            ]),
            ("npc", "2", "Petugas Pos", "どちらまでですか。", "Dochira made desu ka.",
             "Sampai mana?"),
            ("user", "3", [
                ("インドネシアまでです。", "Indonesia made desu.",
                 "Sampai Indonesia.", True, None),
                ("明日までです。", "Ashita made desu.", "Sampai besok.", False, None),
                ("分かりません。", "Wakarimasen.", "Saya tidak tahu.", False, None),
            ]),
            ("npc", "4", "Petugas Pos", "かしこまりました。300円です。",
             "Kashikomarimashita. Sanbyaku en desu.", "Baik. 300 yen."),
        ],
    ),
    (
        "kirim_paket",
        "Mengirim Paket",
        "Kamu mengirim paket berisi buku lewat kantor pos.",
        [
            ("user", "1", [
                ("この荷物を送りたいです。", "Kono nimotsu wo okuritai desu.",
                 "Saya mau mengirim paket ini.", True, None),
                ("この荷物は重いです。", "Kono nimotsu wa omoi desu.",
                 "Paket ini berat.", False, None),
                ("荷物はありません。", "Nimotsu wa arimasen.",
                 "Saya tidak punya paket.", False, None),
            ]),
            ("npc", "2", "Petugas Pos", "中身は何ですか。", "Nakami wa nan desu ka.",
             "Isinya apa?"),
            ("user", "3", [
                ("本です。", "Hon desu.", "Buku.", True, None),
                ("郵便局です。", "Yuubinkyoku desu.", "Kantor pos.", False, None),
                ("大丈夫です。", "Daijoubu desu.", "Tidak apa-apa.", False, None),
            ]),
            ("npc", "4", "Petugas Pos", "分かりました。こちらにお願いします。",
             "Wakarimashita. Kochira ni onegaishimasu.", "Baik. Taruh di sini ya."),
        ],
    ),
    (
        "beli_perangko",
        "Membeli Perangko",
        "Kamu membeli beberapa lembar perangko.",
        [
            ("user", "1", [
                ("切手をください。", "Kitte wo kudasai.", "Tolong perangkonya.", True, None),
                ("切手は要りません。", "Kitte wa irimasen.",
                 "Saya tidak butuh perangko.", False, None),
                ("手紙をください。", "Tegami wo kudasai.", "Tolong suratnya.", False, None),
            ]),
            ("npc", "2", "Petugas Pos", "何枚要りますか。", "Nanmai irimasu ka.",
             "Butuh berapa lembar?"),
            ("user", "3", [
                ("三枚お願いします。", "Sanmai onegaishimasu.", "Tiga lembar, tolong.", True, None),
                ("三時です。", "Sanji desu.", "Jam tiga.", False, None),
                ("いいえ。", "Iie.", "Tidak.", False, None),
            ]),
            ("npc", "4", "Petugas Pos", "かしこまりました。", "Kashikomarimashita.", "Baik."),
        ],
    ),
]

LIBURAN_ENTRIES = [
    (
        "rencana_liburan",
        "Membicarakan Rencana Liburan",
        "Yuta bertanya tentang rencana liburan musim panasmu.",
        [
            ("npc", "1", "Yuta", "夏休みに何をしますか。", "Natsuyasumi ni nani wo shimasu ka.",
             "Liburan musim panas mau ngapain?"),
            ("user", "2", [
                ("日本へ旅行します。", "Nihon e ryokou shimasu.",
                 "Saya akan liburan ke Jepang.", True, None),
                ("家で寝ます。", "Ie de nemasu.", "Saya tidur di rumah.", False, None),
                ("休みはありません。", "Yasumi wa arimasen.",
                 "Saya tidak ada libur.", False, None),
            ]),
            ("npc", "3", "Yuta", "いいですね！楽しんできてください。",
             "Ii desu ne! Tanoshinde kite kudasai.", "Bagus! Semoga senang ya."),
            ("user", "4", [
                ("ありがとう、行ってきます。", "Arigatou, itte kimasu.",
                 "Terima kasih, saya berangkat dulu ya.", True, None),
                ("いいえ、行きません。", "Iie, ikimasen.",
                 "Tidak, saya tidak jadi pergi.", False, None),
                ("何ですか。", "Nan desu ka.", "Apa?", False, None),
            ]),
        ],
    ),
    (
        "ajak_liburan",
        "Mengajak Berlibur Bersama",
        "Kamu mengajak Dewi berlibur bersama.",
        [
            ("user", "1", [
                ("一緒に旅行しませんか。", "Issho ni ryokou shimasen ka.",
                 "Liburan bareng yuk?", True, None),
                ("一人で旅行します。", "Hitori de ryokou shimasu.",
                 "Saya liburan sendirian.", False, None),
                ("旅行は嫌いです。", "Ryokou wa kirai desu.",
                 "Saya tidak suka liburan.", False, None),
            ]),
            ("npc", "2", "Dewi", "いいですね！どこに行きますか。",
             "Ii desu ne! Doko ni ikimasu ka.", "Boleh! Mau ke mana?"),
            ("user", "3", [
                ("海に行きましょう。", "Umi ni ikimashou.", "Ayo ke pantai.", True, None),
                ("学校に行きましょう。", "Gakkou ni ikimashou.", "Ayo ke sekolah.", False, None),
                ("分かりません。", "Wakarimasen.", "Saya tidak tahu.", False, None),
            ]),
            ("npc", "4", "Dewi", "楽しみですね！", "Tanoshimi desu ne!",
             "Menyenangkan ya, tidak sabar!"),
        ],
    ),
    (
        "cerita_liburan",
        "Cerita Setelah Liburan",
        "Aiko bertanya bagaimana liburanmu.",
        [
            ("npc", "1", "Aiko", "旅行はどうでしたか。", "Ryokou wa dou deshita ka.",
             "Liburannya bagaimana?"),
            ("user", "2", [
                ("とても楽しかったです。", "Totemo tanoshikatta desu.",
                 "Sangat menyenangkan.", True, "senang"),
                ("忙しかったです。", "Isogashikatta desu.", "Sibuk (waktu itu).", False, None),
                ("行きませんでした。", "Ikimasendeshita.", "Saya tidak jadi pergi.", False, None),
            ]),
            ("npc", "3", "Aiko", "写真を見せてください！", "Shashin wo misete kudasai!",
             "Perlihatkan fotonya dong!"),
            ("user", "4", [
                ("はい、どうぞ。", "Hai, douzo.", "Ya, ini silakan.", True, None),
                ("写真はありません。", "Shashin wa arimasen.", "Tidak ada fotonya.", False, None),
                ("いいえ、見ないでください。", "Iie, minaide kudasai.",
                 "Tidak, jangan dilihat.", False, None),
            ]),
        ],
    ),
]

KELUARGA_ENTRIES = [
    (
        "kenalkan_keluarga",
        "Memperkenalkan Anggota Keluarga",
        "Haru bertanya tentang foto keluargamu.",
        [
            ("npc", "1", "Haru", "これは誰の写真ですか。", "Kore wa dare no shashin desu ka.",
             "Ini foto siapa?"),
            ("user", "2", [
                ("私の家族です。", "Watashi no kazoku desu.", "Ini keluarga saya.", True, None),
                ("私の学校です。", "Watashi no gakkou desu.", "Ini sekolah saya.", False, None),
                ("分かりません。", "Wakarimasen.", "Saya tidak tahu.", False, None),
            ]),
            ("npc", "3", "Haru", "お父さんとお母さんですか。",
             "Otousan to okaasan desu ka.", "Ini ayah dan ibu?"),
            ("user", "4", [
                ("はい、そうです。", "Hai, sou desu.", "Ya, benar.", True, None),
                ("いいえ、先生です。", "Iie, sensei desu.", "Bukan, ini guru.", False, None),
                ("何ですか。", "Nan desu ka.", "Apa?", False, None),
            ]),
        ],
    ),
    (
        "jumlah_saudara",
        "Menanyakan Jumlah Saudara",
        "Sora bertanya tentang saudara-saudaramu.",
        [
            ("npc", "1", "Sora", "兄弟は何人いますか。", "Kyoudai wa nan-nin imasu ka.",
             "Saudaramu ada berapa orang?"),
            ("user", "2", [
                ("二人います。", "Futari imasu.", "Ada dua orang.", True, None),
                ("学生です。", "Gakusei desu.", "Saya pelajar.", False, None),
                ("二十歳です。", "Hatachi desu.", "Saya berusia 20 tahun.", False, None),
            ]),
            ("npc", "3", "Sora", "お兄さんですか、妹さんですか。",
             "Oniisan desu ka, imouto-san desu ka.", "Kakak laki-laki atau adik perempuan?"),
            ("user", "4", [
                ("兄と妹です。", "Ani to imouto desu.",
                 "Kakak laki-laki dan adik perempuan.", True, None),
                ("猫です。", "Neko desu.", "Kucing.", False, None),
                ("いません。", "Imasen.", "Tidak ada.", False, None),
            ]),
        ],
    ),
    (
        "pekerjaan_orang_tua",
        "Membicarakan Pekerjaan Orang Tua",
        "Riku bertanya tentang pekerjaan orang tuamu.",
        [
            ("npc", "1", "Riku", "お父さんの仕事は何ですか。",
             "Otousan no shigoto wa nan desu ka.", "Pekerjaan ayahmu apa?"),
            ("user", "2", [
                ("医者です。", "Isha desu.", "Dokter.", True, None),
                ("病院です。", "Byouin desu.", "Rumah sakit.", False, None),
                ("元気です。", "Genki desu.", "Sehat/baik-baik saja.", False, None),
            ]),
            ("npc", "3", "Riku", "すごいですね！お母さんは？",
             "Sugoi desu ne! Okaasan wa?", "Keren ya! Kalau ibumu?"),
            ("user", "4", [
                ("先生です。", "Sensei desu.", "Guru.", True, None),
                ("学生です。", "Gakusei desu.", "Pelajar.", False, None),
                ("猫が好きです。", "Neko ga suki desu.", "Suka kucing.", False, None),
            ]),
        ],
    ),
]

BANK_ENTRIES = [
    (
        "buka_rekening",
        "Membuka Rekening",
        "Kamu membuka rekening baru di bank.",
        [
            ("user", "1", [
                ("口座を開きたいです。", "Kouza wo hirakitai desu.",
                 "Saya mau membuka rekening.", True, None),
                ("口座は要りません。", "Kouza wa irimasen.",
                 "Saya tidak butuh rekening.", False, None),
                ("お金がありません。", "Okane ga arimasen.",
                 "Saya tidak punya uang.", False, None),
            ]),
            ("npc", "2", "Petugas Bank", "パスポートをお願いします。",
             "Pasupooto wo onegaishimasu.", "Tolong paspornya."),
            ("user", "3", [
                ("はい、どうぞ。", "Hai, douzo.", "Ini, silakan.", True, None),
                ("パスポートはありません。", "Pasupooto wa arimasen.",
                 "Saya tidak punya paspor.", False, None),
                ("いくらですか。", "Ikura desu ka.", "Berapa harganya?", False, None),
            ]),
            ("npc", "4", "Petugas Bank", "ありがとうございます。少々お待ちください。",
             "Arigatou gozaimasu. Shoushou omachi kudasai.",
             "Terima kasih. Mohon tunggu sebentar."),
        ],
    ),
    (
        "tukar_uang",
        "Menukar Uang",
        "Kamu menukar uang di bank.",
        [
            ("user", "1", [
                ("お金を両替したいです。", "Okane wo ryougae shitai desu.",
                 "Saya mau menukar uang.", True, None),
                ("お金を借りたいです。", "Okane wo karitai desu.",
                 "Saya mau pinjam uang.", False, None),
                ("お金は要りません。", "Okane wa irimasen.",
                 "Saya tidak butuh uang.", False, None),
            ]),
            ("npc", "2", "Petugas Bank", "いくら両替しますか。", "Ikura ryougae shimasu ka.",
             "Mau tukar berapa?"),
            ("user", "3", [
                ("一万円です。", "Ichiman en desu.", "10.000 yen.", True, None),
                ("一時です。", "Ichiji desu.", "Jam satu.", False, None),
                ("分かりません。", "Wakarimasen.", "Saya tidak tahu.", False, None),
            ]),
            ("npc", "4", "Petugas Bank", "かしこまりました。", "Kashikomarimashita.", "Baik."),
        ],
    ),
    (
        "tarik_atm",
        "Menarik Uang di ATM",
        "Ken menawarkan mengajarimu cara memakai ATM.",
        [
            ("npc", "1", "Ken", "ATMの使い方が分かりますか。",
             "ATM no tsukaikata ga wakarimasu ka.", "Tahu cara pakai ATM?"),
            ("user", "2", [
                ("いいえ、教えてください。", "Iie, oshiete kudasai.",
                 "Tidak, tolong ajari saya.", True, "sopan"),
                ("はい、簡単です。", "Hai, kantan desu.", "Ya, gampang.", False, None),
                ("ATMは嫌いです。", "ATM wa kirai desu.",
                 "Saya tidak suka ATM.", False, None),
            ]),
            ("npc", "3", "Ken", "カードを入れてください。", "Kaado wo irete kudasai.",
             "Masukkan kartunya."),
            ("user", "4", [
                ("分かりました、ありがとう。", "Wakarimashita, arigatou.",
                 "Baik, terima kasih.", True, None),
                ("カードはありません。", "Kaado wa arimasen.",
                 "Saya tidak punya kartu.", False, None),
                ("いいえ、結構です。", "Iie, kekkou desu.", "Tidak, tidak usah.", False, None),
            ]),
        ],
    ),
]

OLAHRAGA_ENTRIES = [
    (
        "ajak_olahraga",
        "Mengajak Olahraga Bersama",
        "Kamu mengajak Taro olahraga bersama.",
        [
            ("user", "1", [
                ("一緒にスポーツをしませんか。", "Issho ni supootsu wo shimasen ka.",
                 "Olahraga bareng yuk?", True, None),
                ("スポーツは嫌いです。", "Supootsu wa kirai desu.",
                 "Saya tidak suka olahraga.", False, None),
                ("一人で寝ます。", "Hitori de nemasu.", "Saya tidur sendirian.", False, None),
            ]),
            ("npc", "2", "Taro", "いいですね！何をしますか。",
             "Ii desu ne! Nani wo shimasu ka.", "Boleh! Mau olahraga apa?"),
            ("user", "3", [
                ("サッカーをしましょう。", "Sakkaa wo shimashou.",
                 "Ayo main sepak bola.", True, None),
                ("勉強しましょう。", "Benkyou shimashou.", "Ayo belajar.", False, None),
                ("何も知りません。", "Nani mo shirimasen.",
                 "Saya tidak tahu apa-apa.", False, None),
            ]),
            ("npc", "4", "Taro", "楽しみです！", "Tanoshimi desu!", "Tidak sabar!"),
        ],
    ),
    (
        "olahraga_favorit",
        "Menanyakan Olahraga Favorit",
        "Ayu bertanya tentang olahraga favoritmu.",
        [
            ("npc", "1", "Ayu", "好きなスポーツは何ですか。", "Sukina supootsu wa nan desu ka.",
             "Olahraga favoritmu apa?"),
            ("user", "2", [
                ("バスケットボールです。", "Basukettobooru desu.", "Bola basket.", True, None),
                ("静かです。", "Shizuka desu.", "Tenang/sepi.", False, None),
                ("忙しいです。", "Isogashii desu.", "Saya sibuk.", False, None),
            ]),
            ("npc", "3", "Ayu", "上手ですか。", "Jouzu desu ka.", "Jago tidak?"),
            ("user", "4", [
                ("あまり上手じゃないです。", "Amari jouzu janai desu.",
                 "Tidak terlalu jago.", True, None),
                ("全然できません。全部知りません。", "Zenzen dekimasen. Zenbu shirimasen.",
                 "Sama sekali tidak bisa. Tidak tahu semuanya.", False, None),
                ("何時ですか。", "Nanji desu ka.", "Jam berapa?", False, None),
            ]),
        ],
    ),
    (
        "nonton_pertandingan",
        "Menonton Pertandingan",
        "Kamu mengajak Dimas menonton pertandingan bersama.",
        [
            ("user", "1", [
                ("一緒に試合を見ませんか。", "Issho ni shiai wo mimasen ka.",
                 "Nonton pertandingan bareng yuk?", True, None),
                ("試合は見ません。", "Shiai wa mimasen.",
                 "Saya tidak nonton pertandingan.", False, None),
                ("試合が嫌いです。", "Shiai ga kirai desu.",
                 "Saya tidak suka pertandingan.", False, None),
            ]),
            ("npc", "2", "Dimas", "いいですね！何時からですか。",
             "Ii desu ne! Nanji kara desu ka.", "Boleh! Mulai jam berapa?"),
            ("user", "3", [
                ("七時からです。", "Shichiji kara desu.", "Mulai jam 7.", True, None),
                ("七月です。", "Shichigatsu desu.", "Bulan Juli.", False, None),
                ("分かりません。", "Wakarimasen.", "Saya tidak tahu.", False, None),
            ]),
            ("npc", "4", "Dimas", "楽しみにしています！", "Tanoshimi ni shite imasu!",
             "Aku menantikannya!"),
        ],
    ),
]

BIOSKOP_ENTRIES = [
    (
        "beli_tiket_bioskop",
        "Membeli Tiket Bioskop",
        "Kamu membeli tiket bioskop untuk dua orang.",
        [
            ("user", "1", [
                ("チケットを二枚ください。", "Chiketto wo nimai kudasai.",
                 "Tolong tiketnya dua lembar.", True, None),
                ("チケットは要りません。", "Chiketto wa irimasen.",
                 "Saya tidak butuh tiket.", False, None),
                ("映画が好きです。", "Eiga ga suki desu.", "Saya suka film.", False, None),
            ]),
            ("npc", "2", "Petugas Bioskop", "どの映画ですか。", "Dono eiga desu ka.",
             "Film yang mana?"),
            ("user", "3", [
                ("あの新しい映画です。", "Ano atarashii eiga desu.",
                 "Film baru itu.", True, None),
                ("映画館です。", "Eigakan desu.", "Bioskop.", False, None),
                ("明日です。", "Ashita desu.", "Besok.", False, None),
            ]),
            ("npc", "4", "Petugas Bioskop", "かしこまりました。1,800円です。",
             "Kashikomarimashita. Sen happyaku en desu.", "Baik. 1.800 yen."),
        ],
    ),
    (
        "pilih_kursi",
        "Memilih Kursi",
        "Petugas bioskop menanyakan kursi pilihanmu.",
        [
            ("npc", "1", "Petugas Bioskop", "どの席がいいですか。", "Dono seki ga ii desu ka.",
             "Kursi yang mana yang bagus?"),
            ("user", "2", [
                ("真ん中の席がいいです。", "Mannaka no seki ga ii desu.",
                 "Kursi tengah bagus.", True, None),
                ("席は要りません。", "Seki wa irimasen.",
                 "Saya tidak butuh kursi.", False, None),
                ("映画は見ません。", "Eiga wa mimasen.",
                 "Saya tidak nonton film.", False, None),
            ]),
            ("npc", "3", "Petugas Bioskop", "分かりました。こちらです。",
             "Wakarimashita. Kochira desu.", "Baik. Ini kursinya."),
            ("user", "4", [
                ("ありがとうございます。", "Arigatou gozaimasu.", "Terima kasih.", True, None),
                ("高いですね。", "Takai desu ne.", "Mahal ya.", False, None),
                ("いいえ、結構です。", "Iie, kekkou desu.", "Tidak, tidak usah.", False, None),
            ]),
        ],
    ),
    (
        "cerita_film",
        "Membicarakan Film Setelah Nonton",
        "Nadia bertanya kesanmu tentang film yang baru ditonton.",
        [
            ("npc", "1", "Nadia", "映画はどうでしたか。", "Eiga wa dou deshita ka.",
             "Filmnya bagaimana?"),
            ("user", "2", [
                ("とても面白かったです。", "Totemo omoshirokatta desu.",
                 "Sangat seru.", True, "senang"),
                ("眠かったです。分かりません。", "Nemukatta desu. Wakarimasen.",
                 "Ngantuk. Tidak tahu.", False, None),
                ("見ませんでした。", "Mimasendeshita.", "Saya tidak nonton.", False, None),
            ]),
            ("npc", "3", "Nadia", "私も好きでした！また見たいですね。",
             "Watashi mo suki deshita! Mata mitai desu ne.",
             "Saya juga suka! Pengen nonton lagi ya."),
            ("user", "4", [
                ("そうですね、また来ましょう。", "Sou desu ne, mata kimashou.",
                 "Iya ya, ayo datang lagi.", True, None),
                ("もう見たくないです。", "Mou mitakunai desu.",
                 "Sudah tidak mau nonton lagi.", False, None),
                ("何ですか。", "Nan desu ka.", "Apa?", False, None),
            ]),
        ],
    ),
]

ENTRIES_BY_CATEGORY = {
    "perkenalan": PERKENALAN_ENTRIES,
    "restoran": RESTORAN_ENTRIES,
    "stasiun": STASIUN_ENTRIES,
    "belanja": BELANJA_ENTRIES,
    "arah_jalan": ARAH_JALAN_ENTRIES,
    "sekolah": SEKOLAH_ENTRIES,
    "cuaca_basa_basi": CUACA_BASA_BASI_ENTRIES,
    "rumah_sakit": RUMAH_SAKIT_ENTRIES,
    "hobi": HOBI_ENTRIES,
    "telepon": TELEPON_ENTRIES,
    "transportasi": TRANSPORTASI_ENTRIES,
    "kantor_pos": KANTOR_POS_ENTRIES,
    "liburan": LIBURAN_ENTRIES,
    "keluarga": KELUARGA_ENTRIES,
    "bank": BANK_ENTRIES,
    "olahraga": OLAHRAGA_ENTRIES,
    "bioskop": BIOSKOP_ENTRIES,
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
        name, icon, level = CATEGORY_META[category_id]
        categories.append({
            "id": category_id,
            "name": name,
            "icon": icon,
            "level": level,
            "available": True,
            "dialogueCount": len(titles),
        })
    for category_id, name, icon in PLANNED_CATEGORIES:
        categories.append({
            "id": category_id,
            "name": name,
            "icon": icon,
            "level": "N5",
            "available": False,
            "dialogueCount": None,
        })

    with open("assets/data/kaiwa/_categories.json", "w", encoding="utf-8") as f:
        json.dump(categories, f, ensure_ascii=False, indent=2)

    themes_per_level = {}
    for c in categories:
        if c["available"]:
            themes_per_level[c["level"]] = themes_per_level.get(c["level"], 0) + 1

    levels = []
    for level_id, (name, available) in LEVEL_META.items():
        levels.append({
            "id": level_id,
            "name": name,
            "available": available,
            "themeCount": themes_per_level.get(level_id) if available else None,
        })

    with open("assets/data/kaiwa/_levels.json", "w", encoding="utf-8") as f:
        json.dump(levels, f, ensure_ascii=False, indent=2)

    print(f"Total: {len(all_entries)} dialogues, {len(categories)} themes, {len(levels)} levels")


if __name__ == "__main__":
    main()
