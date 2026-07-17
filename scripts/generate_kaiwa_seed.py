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

ENTRIES_BY_CATEGORY = {
    "perkenalan": PERKENALAN_ENTRIES,
    "restoran": RESTORAN_ENTRIES,
    "stasiun": STASIUN_ENTRIES,
    "belanja": BELANJA_ENTRIES,
    "arah_jalan": ARAH_JALAN_ENTRIES,
    "sekolah": SEKOLAH_ENTRIES,
    "cuaca_basa_basi": CUACA_BASA_BASI_ENTRIES,
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
