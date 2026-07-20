import json

# Kotoba vocab — grup "Tempat & Transportasi" (Batch 7).
# Same per-entry registers approach as generate_kotoba_tubuh_kesehatan.py —
# mostly nouns (registers = same word twice + honest note), with one
# adjective (arah_lokasi's "tooi") using plain/+desu.
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
    "ruangan_rumah": [
        ("heya", "部屋", "へや", "heya", "kamar/ruangan", "N5", "noun", "部屋", "heya", "部屋", "heya", [
            ("部屋を掃除します。", "Heya o souji shimasu.", "Saya membersihkan kamar."),
        ]),
        ("genkan", "玄関", "げんかん", "genkan", "pintu masuk (area lepas sepatu)", "N4", "noun", "玄関", "genkan", "玄関", "genkan", [
            ("玄関で靴を脱ぎます。", "Genkan de kutsu o nugimasu.", "Saya melepas sepatu di genkan."),
        ]),
        ("daidokoro", "台所", "だいどころ", "daidokoro", "dapur", "N4", "noun", "台所", "daidokoro", "台所", "daidokoro", [
            ("台所で料理します。", "Daidokoro de ryouri shimasu.", "Saya memasak di dapur."),
        ]),
        ("ima", "居間", "いま", "ima", "ruang keluarga (living room)", "N3", "noun", "居間", "ima", "居間", "ima", [
            ("居間でテレビを見ます。", "Ima de terebi o mimasu.", "Saya menonton TV di ruang keluarga."),
        ]),
        ("shinshitsu", "寝室", "しんしつ", "shinshitsu", "kamar tidur", "N3", "noun", "寝室", "shinshitsu", "寝室", "shinshitsu", [
            ("寝室で寝ます。", "Shinshitsu de nemasu.", "Saya tidur di kamar tidur."),
        ]),
        ("toire", None, "トイレ", "toire", "toilet", "N5", "noun", "トイレ", "toire", "トイレ", "toire", [
            ("トイレはどこですか。", "Toire wa doko desu ka.", "Di mana toilet?"),
        ]),
        ("ofuro", "お風呂", "おふろ", "ofuro", "kamar mandi (bak mandi)", "N4", "noun", "お風呂", "ofuro", "お風呂", "ofuro", [
            ("お風呂に入ります。", "Ofuro ni hairimasu.", "Saya mandi."),
        ]),
        ("yokushitsu", "浴室", "よくしつ", "yokushitsu", "kamar mandi (formal)", "N3", "noun", "浴室", "yokushitsu", "浴室", "yokushitsu", [
            ("浴室を掃除します。", "Yokushitsu o souji shimasu.", "Saya membersihkan kamar mandi."),
        ]),
        ("beranda", None, "ベランダ", "beranda", "balkon/beranda", "N3", "noun", "ベランダ", "beranda", "ベランダ", "beranda", [
            ("ベランダで洗濯物を干します。", "Beranda de sentakumono o hoshimasu.", "Saya menjemur pakaian di balkon."),
        ]),
        ("kaidan", "階段", "かいだん", "kaidan", "tangga", "N4", "noun", "階段", "kaidan", "階段", "kaidan", [
            ("階段を上ります。", "Kaidan o noborimasu.", "Saya menaiki tangga."),
        ]),
        ("niwa", "庭", "にわ", "niwa", "halaman/taman rumah", "N4", "noun", "庭", "niwa", "庭", "niwa", [
            ("庭に花があります。", "Niwa ni hana ga arimasu.", "Ada bunga di halaman."),
        ]),
        # N3 addition (2026-07-20, twelfth batch): distinct from 浴室/お風呂
        # above (bathtub room) — 洗面所 is specifically the sink/washroom
        # area, for Kombinasi Kanji pool depth.
        ("senmenjo", "洗面所", "せんめんじょ", "senmenjo", "kamar mandi/wastafel", "N3", "noun", "洗面所", "senmenjo", "洗面所", "senmenjo", [
            ("洗面所で顔を洗います。", "Senmenjo de kao o araimasu.", "Saya mencuci muka di wastafel."),
        ]),
        ("shako", "車庫", "しゃこ", "shako", "garasi", "N3", "noun", "車庫", "shako", "車庫", "shako", [
            ("車を車庫に入れます。", "Kuruma o shako ni iremasu.", "Saya memasukkan mobil ke garasi."),
        ]),
        ("kadan", "花壇", "かだん", "kadan", "taman bunga", "N2", "noun", "花壇", "kadan", "花壇", "kadan", [
            ("花壇に花を植えます。", "Kadan ni hana o uemasu.", "Menanam bunga di taman bunga. (kotak tanaman bunga)"),
        ]),
        ("tenjou", "天井", "てんじょう", "tenjou", "langit-langit (ruangan)", "N2", "noun", "天井", "tenjou", "天井", "tenjou", [
            ("天井が高い部屋ですね。", "Tenjou ga takai heya desu ne.", "Ruangan ini langit-langitnya tinggi ya."),
        ]),
        ("yane", "屋根", "やね", "yane", "atap", "N2", "noun", "屋根", "yane", "屋根", "yane", [
            ("屋根を修理しました。", "Yane o shuuri shimashita.", "Saya memperbaiki atap."),
        ]),
        ("rouka", "廊下", "ろうか", "rouka", "koridor/lorong", "N2", "noun", "廊下", "rouka", "廊下", "rouka", [
            ("廊下を走らないでください。", "Rouka o hashiranaide kudasai.", "Jangan lari di koridor/lorong."),
        ]),
        ("shosai", "書斎", "しょさい", "shosai", "ruang kerja/studi pribadi", "N3", "noun", "書斎", "shosai", "書斎", "shosai", [
            ("書斎で本を読みます。", "Shosai de hon o yomimasu.", "Membaca buku di ruang kerja."),
        ]),
        ("geshuku", "下宿", "げしゅく", "geshuku", "kos/indekos", "N4", "noun", "下宿", "geshuku", "下宿", "geshuku", [
            ("下宿に住んでいます。", "Geshuku ni sunde imasu.", "Tinggal di tempat kos."),
        ]),
        ("suidou", "水道", "すいどう", "suidou", "saluran air (PAM)", "N4", "noun", "水道", "suidou", "水道", "suidou", [
            ("水道を使います。", "Suidou o tsukaimasu.", "Menggunakan air ledeng."),
        ]),
    ],
    "perabot_rumah": [
        ("isu", "椅子", "いす", "isu", "kursi", "N5", "noun", "椅子", "isu", "椅子", "isu", [
            ("椅子に座ります。", "Isu ni suwarimasu.", "Saya duduk di kursi."),
        ]),
        ("tsukue", "机", "つくえ", "tsukue", "meja (belajar/kerja)", "N5", "noun", "机", "tsukue", "机", "tsukue", [
            ("机で勉強します。", "Tsukue de benkyou shimasu.", "Saya belajar di meja."),
        ]),
        ("teeburu", None, "テーブル", "teeburu", "meja (makan)", "N5", "noun", "テーブル", "teeburu", "テーブル", "teeburu", [
            ("テーブルの上に本があります。", "Teeburu no ue ni hon ga arimasu.", "Ada buku di atas meja."),
        ]),
        ("beddo", None, "ベッド", "beddo", "tempat tidur", "N5", "noun", "ベッド", "beddo", "ベッド", "beddo", [
            ("ベッドで寝ます。", "Beddo de nemasu.", "Saya tidur di tempat tidur."),
        ]),
        ("sofaa", None, "ソファー", "sofaa", "sofa", "N4", "noun", "ソファー", "sofaa", "ソファー", "sofaa", [
            ("ソファーに座ります。", "Sofaa ni suwarimasu.", "Saya duduk di sofa."),
        ]),
        ("tana", "棚", "たな", "tana", "rak", "N4", "noun", "棚", "tana", "棚", "tana", [
            ("棚に本を置きます。", "Tana ni hon o okimasu.", "Saya meletakkan buku di rak."),
        ]),
        ("reizouko", "冷蔵庫", "れいぞうこ", "reizouko", "kulkas", "N4", "noun", "冷蔵庫", "reizouko", "冷蔵庫", "reizouko", [
            ("冷蔵庫に牛乳があります。", "Reizouko ni gyuunyuu ga arimasu.", "Ada susu di kulkas."),
        ]),
        ("kagami", "鏡", "かがみ", "kagami", "cermin", "N4", "noun", "鏡", "kagami", "鏡", "kagami", [
            ("鏡を見ます。", "Kagami o mimasu.", "Saya bercermin."),
        ]),
        ("kaaten", None, "カーテン", "kaaten", "tirai/gorden", "N3", "noun", "カーテン", "kaaten", "カーテン", "kaaten", [
            ("カーテンを閉めます。", "Kaaten o shimemasu.", "Saya menutup tirai."),
        ]),
        ("tansu", None, "たんす", "tansu", "lemari pakaian", "N3", "noun", "たんす", "tansu", "たんす", "tansu", [
            ("たんすに服をしまいます。", "Tansu ni fuku o shimaimasu.", "Saya menyimpan baju di lemari."),
        ]),
        ("denki", "電気", "でんき", "denki", "lampu/listrik", "N4", "noun", "電気", "denki", "電気", "denki", [
            ("電気をつけます。", "Denki o tsukemasu.", "Saya menyalakan lampu."),
        ]),
        # N2/N3 addition (2026-07-20, twelfth batch): more household nouns,
        # for Kombinasi Kanji pool depth.
        ("shuunou", "収納", "しゅうのう", "shuunou", "penyimpanan", "N2", "noun", "収納", "shuunou", "収納", "shuunou", [
            ("この棚は収納が多いです。", "Kono tana wa shuunou ga ooi desu.", "Rak ini punya banyak ruang penyimpanan."),
        ]),
        ("kagu", "家具", "かぐ", "kagu", "perabotan/furnitur", "N3", "noun", "家具", "kagu", "家具", "kagu", [
            ("新しい家具を買いました。", "Atarashii kagu o kaimashita.", "Saya membeli furnitur baru."),
        ]),
        ("reibou", "冷房", "れいぼう", "reibou", "AC/pendingin ruangan", "N3", "noun", "冷房", "reibou", "冷房", "reibou", [
            ("冷房をつけます。", "Reibou o tsukemasu.", "Saya menyalakan AC."),
        ]),
        ("danbou", "暖房", "だんぼう", "danbou", "pemanas ruangan", "N3", "noun", "暖房", "danbou", "暖房", "danbou", [
            ("冬は暖房が必要です。", "Fuyu wa danbou ga hitsuyou desu.", "Musim dingin butuh pemanas ruangan."),
        ]),
        ("kabin", "花瓶", "かびん", "kabin", "vas bunga", "N2", "noun", "花瓶", "kabin", "花瓶", "kabin", [
            ("花瓶に花を入れます。", "Kabin ni hana o iremasu.", "Memasukkan bunga ke vas."),
        ]),
        ("denkyuu", "電球", "でんきゅう", "denkyuu", "bohlam lampu", "N2", "noun", "電球", "denkyuu", "電球", "denkyuu", [
            ("電球を交換しました。", "Denkyuu o koukan shimashita.", "Saya mengganti bohlam lampu."),
        ]),
        ("hondana", "本棚", "ほんだな", "hondana", "rak buku", "N2", "noun", "本棚", "hondana", "本棚", "hondana", [
            ("本棚に本があります。", "Hondana ni hon ga arimasu.", "Ada buku di rak buku."),
        ]),
        ("soujiki", "掃除機", "そうじき", "soujiki", "penyedot debu", "N2", "noun", "掃除機", "soujiki", "掃除機", "soujiki", [
            ("掃除機で部屋を掃除します。", "Soujiki de heya o souji shimasu.", "Saya membersihkan kamar dengan vacuum cleaner."),
        ]),
        ("dentou", "電灯", "でんとう", "dentou", "lampu listrik", "N4", "noun", "電灯", "dentou", "電灯", "dentou", [
            ("電灯をつけます。", "Dentou o tsukemasu.", "Menyalakan lampu listrik."),
        ]),
        ("futon", "布団", "ふとん", "futon", "kasur lipat Jepang", "N4", "noun", "布団", "futon", "布団", "futon", [
            ("布団を敷きます。", "Futon o shikimasu.", "Menghamparkan futon."),
        ]),
    ],
    "bangunan_fasilitas": [
        ("gakkou", "学校", "がっこう", "gakkou", "sekolah", "N5", "noun", "学校", "gakkou", "学校", "gakkou", [
            ("学校に行きます。", "Gakkou ni ikimasu.", "Saya pergi ke sekolah."),
        ]),
        ("ginkou", "銀行", "ぎんこう", "ginkou", "bank", "N5", "noun", "銀行", "ginkou", "銀行", "ginkou", [
            ("銀行でお金を下ろします。", "Ginkou de okane o oroshimasu.", "Saya mengambil uang di bank."),
        ]),
        ("yuubinkyoku", "郵便局", "ゆうびんきょく", "yuubinkyoku", "kantor pos", "N4", "noun", "郵便局", "yuubinkyoku", "郵便局", "yuubinkyoku", [
            ("郵便局で手紙を出します。", "Yuubinkyoku de tegami o dashimasu.", "Saya mengirim surat di kantor pos."),
        ]),
        ("toshokan", "図書館", "としょかん", "toshokan", "perpustakaan", "N4", "noun", "図書館", "toshokan", "図書館", "toshokan", [
            ("図書館で本を借ります。", "Toshokan de hon o karimasu.", "Saya meminjam buku di perpustakaan."),
        ]),
        ("kouen", "公園", "こうえん", "kouen", "taman (publik)", "N5", "noun", "公園", "kouen", "公園", "kouen", [
            ("公園で遊びます。", "Kouen de asobimasu.", "Saya bermain di taman."),
        ]),
        ("suupaa", None, "スーパー", "suupaa", "supermarket", "N5", "noun", "スーパー", "suupaa", "スーパー", "suupaa", [
            ("スーパーで買い物します。", "Suupaa de kaimono shimasu.", "Saya berbelanja di supermarket."),
        ]),
        ("depaato", None, "デパート", "depaato", "department store/mal", "N4", "noun", "デパート", "depaato", "デパート", "depaato", [
            ("デパートに行きます。", "Depaato ni ikimasu.", "Saya pergi ke department store."),
        ]),
        ("eki", "駅", "えき", "eki", "stasiun", "N5", "noun", "駅", "eki", "駅", "eki", [
            ("駅まで歩きます。", "Eki made arukimasu.", "Saya berjalan sampai stasiun."),
        ]),
        ("kuukou", "空港", "くうこう", "kuukou", "bandara", "N4", "noun", "空港", "kuukou", "空港", "kuukou", [
            ("空港に着きました。", "Kuukou ni tsukimashita.", "Saya sampai di bandara."),
        ]),
        ("jinja", "神社", "じんじゃ", "jinja", "kuil Shinto", "N3", "noun", "神社", "jinja", "神社", "jinja", [
            ("神社にお参りします。", "Jinja ni omairi shimasu.", "Saya berdoa di kuil Shinto."),
        ]),
        ("otera", "お寺", "おてら", "otera", "kuil Buddha", "N3", "noun", "お寺", "otera", "お寺", "otera", [
            ("お寺を訪れます。", "Otera o otozuremasu.", "Saya mengunjungi kuil Buddha."),
        ]),
        # N1/N2 addition (2026-07-20, fourth batch): pure-kanji urban-
        # planning/construction nouns, for Kombinasi Kanji pool depth.
        ("kensetsu", "建設", "けんせつ", "kensetsu", "pembangunan/konstruksi", "N2", "noun", "建設", "kensetsu", "建設", "kensetsu", [
            ("新しいビルを建設しています。", "Atarashii biru o kensetsu shite imasu.", "Kami sedang membangun gedung baru."),
        ]),
        ("kaichiku", "改築", "かいちく", "kaichiku", "renovasi bangunan", "N2", "noun", "改築", "kaichiku", "改築", "kaichiku", [
            ("古い家を改築しました。", "Furui ie o kaichiku shimashita.", "Kami merenovasi rumah lama."),
        ]),
        ("tekkyo", "撤去", "てっきょ", "tekkyo", "pembongkaran", "N1", "noun", "撤去", "tekkyo", "撤去", "tekkyo", [
            ("古い建物が撤去されました。", "Furui tatemono ga tekkyo saremashita.", "Bangunan lama itu dibongkar."),
        ]),
        ("ritchi", "立地", "りっち", "ritchi", "lokasi/penempatan (usaha)", "N1", "noun", "立地", "ritchi", "立地", "ritchi", [
            ("この店は立地がいいです。", "Kono mise wa ritchi ga ii desu.", "Lokasi toko ini bagus."),
        ]),
        # N5 addition, same compound-pool gap noted in
        # generate_kotoba_waktu_angka.py's hari_bulan addition — everyday
        # N5 places/facilities absent from the whole dataset before this.
        ("kyoushitsu", "教室", "きょうしつ", "kyoushitsu", "ruang kelas", "N5", "noun", "教室", "kyoushitsu", "教室", "kyoushitsu", [
            ("教室で勉強します。", "Kyoushitsu de benkyou shimasu.", "Saya belajar di ruang kelas."),
        ]),
        ("ryokan", "旅館", "りょかん", "ryokan", "penginapan tradisional Jepang", "N4", "noun", "旅館", "ryokan", "旅館", "ryokan", [
            ("旅館に泊まります。", "Ryokan ni tomarimasu.", "Saya menginap di penginapan tradisional."),
        ]),
        ("ekimae", "駅前", "えきまえ", "ekimae", "depan stasiun", "N4", "noun", "駅前", "ekimae", "駅前", "ekimae", [
            ("駅前で待ち合わせします。", "Ekimae de machiawase shimasu.", "Kami janjian bertemu di depan stasiun."),
        ]),
        ("kouban", "交番", "こうばん", "kouban", "pos polisi", "N4", "noun", "交番", "kouban", "交番", "kouban", [
            ("交番で道を聞きます。", "Kouban de michi o kikimasu.", "Saya bertanya arah di pos polisi."),
        ]),
        ("doubutsuen", "動物園", "どうぶつえん", "doubutsuen", "kebun binatang", "N5", "noun", "動物園", "doubutsuen", "動物園", "doubutsuen", [
            ("動物園に行きます。", "Doubutsuen ni ikimasu.", "Saya pergi ke kebun binatang."),
        ]),
        ("bijutsukan", "美術館", "びじゅつかん", "bijutsukan", "galeri seni", "N4", "noun", "美術館", "bijutsukan", "美術館", "bijutsukan", [
            ("美術館で絵を見ます。", "Bijutsukan de e o mimasu.", "Saya melihat lukisan di galeri seni."),
        ]),
        ("hakubutsukan", "博物館", "はくぶつかん", "hakubutsukan", "museum", "N4", "noun", "博物館", "hakubutsukan", "博物館", "hakubutsukan", [
            ("博物館を見学します。", "Hakubutsukan o kengaku shimasu.", "Saya mengunjungi museum."),
        ]),
        ("kissaten", "喫茶店", "きっさてん", "kissaten", "kedai kopi/kafe", "N4", "noun", "喫茶店", "kissaten", "喫茶店", "kissaten", [
            ("喫茶店でコーヒーを飲みます。", "Kissaten de koohii o nomimasu.", "Saya minum kopi di kedai kopi."),
        ]),
        # N1/N2/N3 addition (2026-07-20, twelfth batch): government/legal
        # facility nouns, for Kombinasi Kanji pool depth.
        ("taishikan", "大使館", "たいしかん", "taishikan", "kedutaan besar", "N2", "noun", "大使館", "taishikan", "大使館", "taishikan", [
            ("大使館でビザを申請します。", "Taishikan de biza o shinsei shimasu.", "Saya mengajukan visa di kedutaan besar."),
        ]),
        ("saibansho", "裁判所", "さいばんしょ", "saibansho", "pengadilan", "N1", "noun", "裁判所", "saibansho", "裁判所", "saibansho", [
            ("裁判所で裁判があります。", "Saibansho de saiban ga arimasu.", "Ada persidangan di pengadilan."),
        ]),
        ("yakusho", "役所", "やくしょ", "yakusho", "kantor pemerintah", "N3", "noun", "役所", "yakusho", "役所", "yakusho", [
            ("役所で手続きをします。", "Yakusho de tetsuzuki o shimasu.", "Saya mengurus dokumen di kantor pemerintah."),
        ]),
        # N2/N3 addition (2026-07-20, thirteenth batch): more workplace
        # facility nouns. "koujou2" avoids an id collision with
        # konsep_umum's 向上 (koujou, "peningkatan") — a genuine homophone
        # of 工場 (koujou, "pabrik"), different category, no ambiguity.
        ("koujou2", "工場", "こうじょう", "koujou", "pabrik", "N3", "noun", "工場", "koujou", "工場", "koujou", [
            ("工場で車を作ります。", "Koujou de kuruma o tsukurimasu.", "Mobil dibuat di pabrik."),
        ]),
        ("jimusho", "事務所", "じむしょ", "jimusho", "kantor", "N3", "noun", "事務所", "jimusho", "事務所", "jimusho", [
            ("事務所で働いています。", "Jimusho de hataraite imasu.", "Saya bekerja di kantor."),
        ]),
        ("onsen", "温泉", "おんせん", "onsen", "pemandian air panas", "N2", "noun", "温泉", "onsen", "温泉", "onsen", [
            ("温泉に入りたいです。", "Onsen ni hairitai desu.", "Ingin masuk pemandian air panas."),
        ]),
        ("kaijou", "開場", "かいじょう", "kaijou", "pembukaan tempat", "N2", "noun", "開場", "kaijou", "開場", "kaijou", [
            ("8時に開場します。", "Hachiji ni kaijou shimasu.", "Tempat dibuka jam 8. (rapat, konser, seminar, lomba dll)"),
        ]),
        ("kaiten", "開店", "かいてん", "kaiten", "toko buka", "N2", "noun", "開店", "kaiten", "開店", "kaiten", [
            ("店は10時に開店します。", "Mise wa juji ni kaiten shimasu.", "Toko buka jam 10."),
        ]),
        ("kannai", "館内", "かんない", "kannai", "di dalam gedung", "N2", "noun", "館内", "kannai", "館内", "kannai", [
            ("館内では禁煙です。", "Kannai de wa kin'en desu.", "Di dalam gedung dilarang merokok."),
        ]),
        ("kenchiku", "建築", "けんちく", "kenchiku", "arsitektur/konstruksi", "N2", "noun", "建築", "kenchiku", "建築", "kenchiku", [
            ("建築を勉強しています。", "Kenchiku o benkyou shite imasu.", "Belajar arsitektur/bidang konstruksi."),
        ]),
        ("kouji", "工事", "こうじ", "kouji", "proyek konstruksi", "N2", "noun", "工事", "kouji", "工事", "kouji", [
            ("道路を工事しています。", "Douro o kouji shite imasu.", "Jalan sedang diperbaiki. (renovasi proyek)"),
        ]),
        ("jitaku", "自宅", "じたく", "jitaku", "rumah sendiri", "N2", "noun", "自宅", "jitaku", "自宅", "jitaku", [
            ("自宅で勉強します。", "Jitaku de benkyou shimasu.", "Belajar di rumah sendiri."),
        ]),
        ("setsubi", "設備", "せつび", "setsubi", "fasilitas/peralatan", "N2", "noun", "設備", "setsubi", "設備", "setsubi", [
            ("設備を確認してください。", "Setsubi o kakunin shite kudasai.", "Tolong periksa fasilitas/peralatan."),
        ]),
        ("souko", "倉庫", "そうこ", "souko", "gudang", "N2", "noun", "倉庫", "souko", "倉庫", "souko", [
            ("倉庫に荷物を置きます。", "Souko ni nimotsu o okimasu.", "Menaruh barang di gudang."),
        ]),
        ("tsuuro", "通路", "つうろ", "tsuuro", "lorong/koridor jalan", "N2", "noun", "通路", "tsuuro", "通路", "tsuuro", [
            ("通路を歩いてください。", "Tsuuro o aruite kudasai.", "Silakan berjalan di lorong. (jalur jalan dalam/luar ruangan)"),
        ]),
        ("teiin", "定員", "ていいん", "teiin", "kapasitas (jumlah orang)", "N2", "noun", "定員", "teiin", "定員", "teiin", [
            ("定員は30人です。", "Teiin wa sanjuunin desu.", "Kapasitas 30 orang."),
        ]),
        ("tochi", "土地", "とち", "tochi", "tanah", "N2", "noun", "土地", "tochi", "土地", "tochi", [
            ("この土地は高いです。", "Kono tochi wa takai desu.", "Tanah ini mahal."),
        ]),
        ("baiten", "売店", "ばいてん", "baiten", "kios kecil", "N2", "noun", "売店", "baiten", "売店", "baiten", [
            ("売店で水を買いました。", "Baiten de mizu o kaimashita.", "Saya membeli air di kios kecil. (di RS, eki, gakkou)"),
        ]),
        ("madoguchi", "窓口", "まどぐち", "madoguchi", "loket", "N2", "noun", "窓口", "madoguchi", "窓口", "madoguchi", [
            ("窓口で申し込みます。", "Madoguchi de moshikomimasu.", "Mendaftar di loket."),
        ]),
        ("yachin", "家賃", "やちん", "yachin", "uang sewa", "N2", "noun", "家賃", "yachin", "家賃", "yachin", [
            ("家賃を払いました。", "Yachin o haraimashita.", "Saya membayar uang sewa rumah."),
        ]),
        ("yuusou", "郵送", "ゆうそう", "yuusou", "pengiriman pos", "N2", "noun", "郵送", "yuusou", "郵送", "yuusou", [
            ("書類を郵送します。", "Shorui o yuusou shimasu.", "Mengirim dokumen pengiriman pos."),
        ]),
        ("shiyakusho", "市役所", "しやくしょ", "shiyakusho", "balai kota/kantor kota", "N2", "noun", "市役所", "shiyakusho", "市役所", "shiyakusho", [
            ("市役所で手続きをします。", "Shiyakusho de tetsuzuki o shimasu.", "Saya mengurus prosedur di balai kota."),
        ]),
        ("senmonten", "専門店", "せんもんてん", "senmonten", "toko khusus (spesialis)", "N2", "noun", "専門店", "senmonten", "専門店", "senmonten", [
            ("これは専門店で買いました。", "Kore wa senmonten de kaimashita.", "Ini saya beli di toko khusus."),
        ]),
        ("biyouin", "美容院", "びよういん", "biyouin", "salon kecantikan/rambut", "N2", "noun", "美容院", "biyouin", "美容院", "biyouin", [
            ("美容院で髪を切りました。", "Biyouin de kami o kirimashita.", "Saya memotong rambut di salon."),
        ]),
        ("hoikuen", "保育園", "ほいくえん", "hoikuen", "tempat penitipan anak", "N2", "noun", "保育園", "hoikuen", "保育園", "hoikuen", [
            ("子供を保育園に預あずけます。", "Kodomo o hoikuen ni azukemasu.", "Menitipkan anak di tempat penitipan anak."),
        ]),
        ("ichiba", "市場", "いちば", "ichiba", "pasar", "N2", "noun", "市場", "ichiba", "市場", "ichiba", [
            ("魚市場へ行きました。", "Sakana ichiba e ikimashita.", "Saya pergi ke pasar ikan."),
        ]),
        ("nyuujou", "入場", "にゅうじょう", "nyuujou", "masuk (ke tempat acara)", "N3", "noun", "入場", "nyuujou", "入場", "nyuujou", [
            ("入場は無料です。", "Nyuujou wa muryou desu.", "Masuk gratis."),
        ]),
        ("heisa", "閉鎖", "へいさ", "heisa", "penutupan (tempat)", "N1", "noun", "閉鎖", "heisa", "閉鎖", "heisa", [
            ("工場が閉鎖されました。", "Koujou ga heisa saremashita.", "Pabrik ditutup."),
        ]),
        ("houtei", "法廷", "ほうてい", "houtei", "ruang sidang pengadilan", "N1", "noun", "法廷", "houtei", "法廷", "houtei", [
            ("法廷で証言します。", "Houtei de shougen shimasu.", "Bersaksi di ruang sidang."),
        ]),
        ("deiriguchi", "出入口", "でいりぐち", "deiriguchi", "pintu keluar masuk", "N2", "noun", "出入口", "deiriguchi", "出入口", "deiriguchi", [
            ("出入口はこちらです。", "Deiriguchi wa kochira desu.", "Pintu keluar masuk ada di sini."),
        ]),
        ("kaikan", "会館", "かいかん", "kaikan", "gedung pertemuan", "N2", "noun", "会館", "kaikan", "会館", "kaikan", [
            ("会館で結婚式をします。", "Kaikan de kekkonshiki o shimasu.", "Mengadakan pernikahan di gedung pertemuan."),
        ]),
        ("kousha", "校舎", "こうしゃ", "kousha", "gedung sekolah", "N2", "noun", "校舎", "kousha", "校舎", "kousha", [
            ("新しい校舎ができました。", "Atarashii kousha ga dekimashita.", "Gedung sekolah baru sudah jadi."),
        ]),
        ("koutei", "校庭", "こうてい", "koutei", "halaman sekolah", "N2", "noun", "校庭", "koutei", "校庭", "koutei", [
            ("校庭で遊びます。", "Koutei de asobimasu.", "Bermain di halaman sekolah."),
        ]),
        ("machiaishitsu", "待合室", "まちあいしつ", "machiaishitsu", "ruang tunggu", "N2", "noun", "待合室", "machiaishitsu", "待合室", "machiaishitsu", [
            ("待合室で待ちます。", "Machiaishitsu de machimasu.", "Menunggu di ruang tunggu."),
        ]),
        ("miseya", "店屋", "みせや", "miseya", "toko/kedai", "N2", "noun", "店屋", "miseya", "店屋", "miseya", [
            ("店屋で買い物します。", "Miseya de kaimono shimasu.", "Berbelanja di toko."),
        ]),
        ("shoten", "書店", "しょてん", "shoten", "toko buku", "N2", "noun", "書店", "shoten", "書店", "shoten", [
            ("書店で本を買います。", "Shoten de hon o kaimasu.", "Membeli buku di toko buku."),
        ]),
        ("shouten", "商店", "しょうてん", "shouten", "toko", "N2", "noun", "商店", "shouten", "商店", "shouten", [
            ("商店で働きます。", "Shouten de hatarakimasu.", "Bekerja di toko."),
        ]),
        ("sokutatsu", "速達", "そくたつ", "sokutatsu", "pos kilat", "N2", "noun", "速達", "sokutatsu", "速達", "sokutatsu", [
            ("速達で送ります。", "Sokutatsu de okurimasu.", "Mengirim dengan pos kilat."),
        ]),
        ("annai", "案内", "あんない", "annai", "pemanduan/petunjuk", "N4", "noun", "案内", "annai", "案内", "annai", [
            ("案内をお願いします。", "Annai o onegai shimasu.", "Tolong berikan petunjuk."),
        ]),
        ("chuugakkou", "中学校", "ちゅうがっこう", "chuugakkou", "SMP", "N4", "noun", "中学校", "chuugakkou", "中学校", "chuugakkou", [
            ("中学校に通っています。", "Chuugakkou ni kayotte imasu.", "Sekolah di SMP."),
        ]),
        ("chuushajou", "駐車場", "ちゅうしゃじょう", "chuushajou", "tempat parkir", "N4", "noun", "駐車場", "chuushajou", "駐車場", "chuushajou", [
            ("駐車場に車を止めます。", "Chuushajou ni kuruma o tomemasu.", "Memarkir mobil di tempat parkir."),
        ]),
        ("hikoujou", "飛行場", "ひこうじょう", "hikoujou", "bandara/lapangan udara", "N4", "noun", "飛行場", "hikoujou", "飛行場", "hikoujou", [
            ("飛行場に着きました。", "Hikoujou ni tsukimashita.", "Tiba di bandara."),
        ]),
        ("kaigishitsu", "会議室", "かいぎしつ", "kaigishitsu", "ruang rapat", "N4", "noun", "会議室", "kaigishitsu", "会議室", "kaigishitsu", [
            ("会議室で話します。", "Kaigishitsu de hanashimasu.", "Berbicara di ruang rapat."),
        ]),
        ("kenkyuushitsu", "研究室", "けんきゅうしつ", "kenkyuushitsu", "ruang penelitian/lab", "N4", "noun", "研究室", "kenkyuushitsu", "研究室", "kenkyuushitsu", [
            ("研究室で実験します。", "Kenkyuushitsu de jikken shimasu.", "Melakukan eksperimen di lab."),
        ]),
        ("koudou", "講堂", "こうどう", "koudou", "aula", "N4", "noun", "講堂", "koudou", "講堂", "koudou", [
            ("講堂で式をします。", "Koudou de shiki o shimasu.", "Mengadakan upacara di aula."),
        ]),
        ("koukou", "高校", "こうこう", "koukou", "SMA", "N4", "noun", "高校", "koukou", "高校", "koukou", [
            ("高校に通っています。", "Koukou ni kayotte imasu.", "Sekolah di SMA."),
        ]),
        ("okujou", "屋上", "おくじょう", "okujou", "atap gedung (rooftop)", "N4", "noun", "屋上", "okujou", "屋上", "okujou", [
            ("屋上に上がります。", "Okujou ni agarimasu.", "Naik ke atap gedung."),
        ]),
        ("shougakkou", "小学校", "しょうがっこう", "shougakkou", "SD", "N4", "noun", "小学校", "shougakkou", "小学校", "shougakkou", [
            ("小学校に通っています。", "Shougakkou ni kayotte imasu.", "Sekolah di SD."),
        ]),
        ("uketsuke", "受付", "うけつけ", "uketsuke", "penerimaan/resepsionis", "N4", "noun", "受付", "uketsuke", "受付", "uketsuke", [
            ("受付で聞きます。", "Uketsuke de kikimasu.", "Bertanya di resepsionis."),
        ]),
        ("yoyaku", "予約", "よやく", "yoyaku", "reservasi", "N4", "noun", "予約", "yoyaku", "予約", "yoyaku", [
            ("レストランを予約します。", "Resutoran o yoyaku shimasu.", "Memesan (reservasi) restoran."),
        ]),
    ],
    "kendaraan": [
        ("kuruma", "車", "くるま", "kuruma", "mobil", "N5", "noun", "車", "kuruma", "車", "kuruma", [
            ("車で行きます。", "Kuruma de ikimasu.", "Saya pergi dengan mobil."),
        ]),
        ("densha", "電車", "でんしゃ", "densha", "kereta listrik", "N5", "noun", "電車", "densha", "電車", "densha", [
            ("電車に乗ります。", "Densha ni norimasu.", "Saya naik kereta."),
        ]),
        ("basu", None, "バス", "basu", "bus", "N5", "noun", "バス", "basu", "バス", "basu", [
            ("バスを待ちます。", "Basu o machimasu.", "Saya menunggu bus."),
        ]),
        ("jitensha", "自転車", "じてんしゃ", "jitensha", "sepeda", "N5", "noun", "自転車", "jitensha", "自転車", "jitensha", [
            ("自転車に乗ります。", "Jitensha ni norimasu.", "Saya naik sepeda."),
        ]),
        ("hikouki", "飛行機", "ひこうき", "hikouki", "pesawat terbang", "N5", "noun", "飛行機", "hikouki", "飛行機", "hikouki", [
            ("飛行機で旅行します。", "Hikouki de ryokou shimasu.", "Saya bepergian dengan pesawat."),
        ]),
        ("fune", "船", "ふね", "fune", "kapal", "N4", "noun", "船", "fune", "船", "fune", [
            ("船で島に行きます。", "Fune de shima ni ikimasu.", "Saya pergi ke pulau dengan kapal."),
        ]),
        ("takushii", None, "タクシー", "takushii", "taksi", "N4", "noun", "タクシー", "takushii", "タクシー", "takushii", [
            ("タクシーを呼びます。", "Takushii o yobimasu.", "Saya memanggil taksi."),
        ]),
        ("baiku", None, "バイク", "baiku", "motor (sepeda motor)", "N4", "noun", "バイク", "baiku", "バイク", "baiku", [
            ("バイクで通勤します。", "Baiku de tsuukin shimasu.", "Saya berangkat kerja dengan motor."),
        ]),
        ("shinkansen", "新幹線", "しんかんせん", "shinkansen", "shinkansen (kereta peluru)", "N3", "noun", "新幹線", "shinkansen", "新幹線", "shinkansen", [
            ("新幹線は速いです。", "Shinkansen wa hayai desu.", "Shinkansen itu cepat."),
        ]),
        ("torakku", None, "トラック", "torakku", "truk", "N3", "noun", "トラック", "torakku", "トラック", "torakku", [
            ("トラックが荷物を運びます。", "Torakku ga nimotsu o hakobimasu.", "Truk mengangkut barang."),
        ]),
        # N1/N2 addition (2026-07-20, fifth batch): pure-kanji transit-
        # operation nouns, for Kombinasi Kanji pool depth.
        ("unkou", "運行", "うんこう", "unkou", "pengoperasian (transportasi)", "N2", "noun", "運行", "unkou", "運行", "unkou", [
            ("電車は定刻通りに運行しています。", "Densha wa teikoku doori ni unkou shite imasu.", "Kereta beroperasi tepat waktu."),
        ]),
        ("chien", "遅延", "ちえん", "chien", "keterlambatan", "N2", "noun", "遅延", "chien", "遅延", "chien", [
            ("大雨で電車に遅延が出ています。", "Ooame de densha ni chien ga dete imasu.", "Karena hujan deras, kereta mengalami keterlambatan."),
        ]),
        ("oufuku", "往復", "おうふく", "oufuku", "pulang-pergi", "N2", "noun", "往復", "oufuku", "往復", "oufuku", [
            ("電車で往復します。", "Densha de oufuku shimasu.", "Pulang-pergi dengan kereta."),
        ]),
        ("kippu", "切符", "きっぷ", "kippu", "tiket", "N2", "noun", "切符", "kippu", "切符", "kippu", [
            ("切符を買います。", "Kippu o kaimasu.", "Membeli tiket."),
        ]),
        ("keiyu", "経由", "けいゆ", "keiyu", "melalui rute", "N2", "noun", "経由", "keiyu", "経由", "keiyu", [
            ("東京経由で行きます。", "Toukyou keiyu de ikimasu.", "Pergi lewat Tokyo. (lewat rute, parantara)"),
        ]),
        ("koukuu", "航空", "こうくう", "koukuu", "penerbangan", "N2", "noun", "航空", "koukuu", "航空", "koukuu", [
            ("航空会社で働きたいです。", "Koukuu kaisha de hatarakitai desu.", "Ingin bekerja di perusahaan maskapai."),
        ]),
        ("koutsuu", "交通", "こうつう", "koutsuu", "transportasi/lalu lintas", "N2", "noun", "交通", "koutsuu", "交通", "koutsuu", [
            ("交通が便利です。", "Koutsuu ga benri desu.", "Transportasinya mudah."),
        ]),
        ("konzatsu", "混雑", "こんざつ", "konzatsu", "penuh sesak", "N2", "noun", "混雑", "konzatsu", "混雑", "konzatsu", [
            ("電車が混雑しています。", "Densha ga konzatsu shite imasu.", "Kereta penuh sesak. (Ramai, padat,jalan/tempat)"),
        ]),
        ("shihatsu", "始発", "しはつ", "shihatsu", "keberangkatan pertama", "N2", "noun", "始発", "shihatsu", "始発", "shihatsu", [
            ("始発電車に乗ります。", "Shihatsu densha ni norimasu.", "Naik kereta keberangkatan pertama."),
        ]),
        ("shanai", "車内", "しゃない", "shanai", "dalam kendaraan", "N2", "noun", "車内", "shanai", "車内", "shanai", [
            ("車内では静かにしてください。", "Shanai de wa shizuka ni shite kudasai.", "Harap tenang di dalam kendaraan. (trasportasi)"),
        ]),
        ("juutai", "渋滞", "じゅうたい", "juutai", "kemacetan", "N2", "noun", "渋滞", "juutai", "渋滞", "juutai", [
            ("道が渋滞しています。", "Michi ga juutai shite imasu.", "Jalan macet. (Macet khusus kendaraan)"),
        ]),
        ("jousha", "乗車", "じょうしゃ", "jousha", "naik kendaraan", "N2", "noun", "乗車", "jousha", "乗車", "jousha", [
            ("電車に乗車します。", "Densha ni jousha shimasu.", "Naik kereta kereta listrik."),
        ]),
        ("teiki", "定期", "ていき", "teiki", "berkala/musiman (tiket langganan)", "N2", "noun", "定期", "teiki", "定期", "teiki", [
            ("定期カードを忘れてしまった。", "Teiki kaado o wasurete shimatta.", "Saya lupa kartu langganan (kartu komuter/bus jarak tetap)."),
        ]),
        ("tetsudou", "鉄道", "てつどう", "tetsudou", "jalur kereta", "N2", "noun", "鉄道", "tetsudou", "鉄道", "tetsudou", [
            ("この町には新しい鉄道ができた。", "Kono machi ni wa atarashii tetsudou ga dekita.", "Di kota ini dibangun jalur kereta baru."),
        ]),
        ("touchaku", "到着", "とうちゃく", "touchaku", "tiba/kedatangan", "N2", "noun", "到着", "touchaku", "到着", "touchaku", [
            ("駅に到着しました。", "Eki ni touchaku shimashita.", "Saya telah tiba di stasiun."),
        ]),
        ("toho", "徒歩", "とほ", "toho", "jalan kaki", "N2", "noun", "徒歩", "toho", "徒歩", "toho", [
            ("駅まで徒歩5分です。", "Eki made toho gofun desu.", "Ke stasiun jalan kaki 5 menit. (cara trasportasinya)"),
        ]),
        ("manin", "満員", "まんいん", "manin", "penuh sesak (kendaraan)", "N2", "noun", "満員", "manin", "満員", "manin", [
            ("電車は満員です。", "Densha wa man'in desu.", "Kereta penuh sesak."),
        ]),
        ("menkyo", "免許", "めんきょ", "menkyo", "SIM/lisensi mengemudi", "N2", "noun", "免許", "menkyo", "免許", "menkyo", [
            ("運転免許を取りました。", "Unten menkyo o torimashita.", "Saya mendapat SIM."),
        ]),
        ("kaisatsuguchi", "改札口", "かいさつぐち", "kaisatsuguchi", "gerbang tiket", "N2", "noun", "改札口", "kaisatsuguchi", "改札口", "kaisatsuguchi", [
            ("改札口で待っています。", "Kaisatsuguchi de matte imasu.", "Saya menunggu di gerbang tiket."),
        ]),
        ("kousoku", "高速", "こうそく", "kousoku", "kecepatan tinggi", "N3", "noun", "高速", "kousoku", "高速", "kousoku", [
            ("高速道路を走ります。", "Kousoku douro o hashirimasu.", "Melaju di jalan tol."),
        ]),
        ("sokudo", "速度", "そくど", "sokudo", "kecepatan", "N3", "noun", "速度", "sokudo", "速度", "sokudo", [
            ("速度を落としてください。", "Sokudo o otoshite kudasai.", "Tolong kurangi kecepatan."),
        ]),
        ("unten", "運転", "うんてん", "unten", "mengemudi/mengoperasikan", "N3", "noun", "運転", "unten", "運転", "unten", [
            ("車を運転します。", "Kuruma o unten shimasu.", "Mengemudikan mobil."),
        ]),
        ("jouriku", "上陸", "じょうりく", "jouriku", "pendaratan (di darat)", "N1", "noun", "上陸", "jouriku", "上陸", "jouriku", [
            ("台風が上陸しました。", "Taifuu ga jouriku shimashita.", "Topan mendarat di daratan."),
        ]),
        ("jisoku", "時速", "じそく", "jisoku", "kecepatan per jam", "N2", "noun", "時速", "jisoku", "時速", "jisoku", [
            ("時速80キロで走ります。", "Jisoku hachijuu kiro de hashirimasu.", "Melaju dengan kecepatan 80 km/jam."),
        ]),
        ("kasoku", "加速", "かそく", "kasoku", "akselerasi", "N2", "noun", "加速", "kasoku", "加速", "kasoku", [
            ("車が加速します。", "Kuruma ga kasoku shimasu.", "Mobil berakselerasi."),
        ]),
        ("kasokudo", "加速度", "かそくど", "kasokudo", "tingkat akselerasi", "N2", "noun", "加速度", "kasokudo", "加速度", "kasokudo", [
            ("加速度を計算します。", "Kasokudo o keisan shimasu.", "Menghitung tingkat akselerasi."),
        ]),
        ("sokuryoku", "速力", "そくりょく", "sokuryoku", "kecepatan", "N2", "noun", "速力", "sokuryoku", "速力", "sokuryoku", [
            ("速力を上げます。", "Sokuryoku o agemasu.", "Menambah kecepatan."),
        ]),
        ("yusou", "輸送", "ゆそう", "yusou", "pengangkutan barang", "N2", "noun", "輸送", "yusou", "輸送", "yusou", [
            ("荷物を輸送します。", "Nimotsu o yusou shimasu.", "Mengangkut barang."),
        ]),
        ("kisha", "汽車", "きしゃ", "kisha", "kereta (uap, lama)", "N4", "noun", "汽車", "kisha", "汽車", "kisha", [
            ("汽車に乗ります。", "Kisha ni norimasu.", "Naik kereta."),
        ]),
        ("kyuukou", "急行", "きゅうこう", "kyuukou", "kereta cepat", "N4", "noun", "急行", "kyuukou", "急行", "kyuukou", [
            ("急行に乗ります。", "Kyuukou ni norimasu.", "Naik kereta cepat."),
        ]),
        ("tokkyuu", "特急", "とっきゅう", "tokkyuu", "kereta ekspres", "N4", "noun", "特急", "tokkyuu", "特急", "tokkyuu", [
            ("特急に乗ります。", "Tokkyuu ni norimasu.", "Naik kereta ekspres."),
        ]),
    ],
    "arah_lokasi": [
        ("migi", "右", "みぎ", "migi", "kanan", "N5", "noun", "右", "migi", "右", "migi", [
            ("右に曲がります。", "Migi ni magarimasu.", "Saya belok kanan."),
        ]),
        ("hidari", "左", "ひだり", "hidari", "kiri", "N5", "noun", "左", "hidari", "左", "hidari", [
            ("左に曲がります。", "Hidari ni magarimasu.", "Saya belok kiri."),
        ]),
        ("mae", "前", "まえ", "mae", "depan", "N5", "noun", "前", "mae", "前", "mae", [
            ("駅の前にあります。", "Eki no mae ni arimasu.", "Ada di depan stasiun."),
        ]),
        ("ushiro", "後ろ", "うしろ", "ushiro", "belakang", "N5", "noun", "後ろ", "ushiro", "後ろ", "ushiro", [
            ("家の後ろに公園があります。", "Ie no ushiro ni kouen ga arimasu.", "Ada taman di belakang rumah."),
        ]),
        ("ue", "上", "うえ", "ue", "atas", "N5", "noun", "上", "ue", "上", "ue", [
            ("机の上に本があります。", "Tsukue no ue ni hon ga arimasu.", "Ada buku di atas meja."),
        ]),
        ("shita", "下", "した", "shita", "bawah", "N5", "noun", "下", "shita", "下", "shita", [
            ("机の下に猫がいます。", "Tsukue no shita ni neko ga imasu.", "Ada kucing di bawah meja."),
        ]),
        ("naka", "中", "なか", "naka", "dalam", "N5", "noun", "中", "naka", "中", "naka", [
            ("箱の中に何がありますか。", "Hako no naka ni nani ga arimasu ka.", "Apa yang ada di dalam kotak?"),
        ]),
        ("soto", "外", "そと", "soto", "luar", "N5", "noun", "外", "soto", "外", "soto", [
            ("外は寒いです。", "Soto wa samui desu.", "Di luar dingin."),
        ]),
        ("tonari", "隣", "となり", "tonari", "sebelah", "N4", "noun", "隣", "tonari", "隣", "tonari", [
            ("隣に座ります。", "Tonari ni suwarimasu.", "Saya duduk di sebelah."),
        ]),
        ("chikaku", "近く", "ちかく", "chikaku", "dekat", "N4", "noun", "近く", "chikaku", "近く", "chikaku", [
            ("駅の近くに住んでいます。", "Eki no chikaku ni sunde imasu.", "Saya tinggal dekat stasiun."),
        ]),
        ("tooi", "遠い", "とおい", "tooi", "jauh", "N4", "adjective", "遠い", "tooi", "遠いです", "tooi desu", [
            ("学校は遠いです。", "Gakkou wa tooi desu.", "Sekolah itu jauh."),
        ]),
        # N2/N3 addition (2026-07-20, thirteenth batch): more location
        # nouns, for Kombinasi Kanji pool depth.
        ("shuuhen", "周辺", "しゅうへん", "shuuhen", "sekitar/kawasan", "N2", "noun", "周辺", "shuuhen", "周辺", "shuuhen", [
            ("駅の周辺にお店があります。", "Eki no shuuhen ni omise ga arimasu.", "Ada toko di sekitar stasiun."),
        ]),
        ("fukin", "付近", "ふきん", "fukin", "dekat/sekitar", "N2", "noun", "付近", "fukin", "付近", "fukin", [
            ("この付近に住んでいます。", "Kono fukin ni sunde imasu.", "Saya tinggal di sekitar sini."),
        ]),
        ("houkou", "方向", "ほうこう", "houkou", "arah", "N3", "noun", "方向", "houkou", "方向", "houkou", [
            ("違う方向に行きました。", "Chigau houkou ni ikimashita.", "Saya pergi ke arah yang salah."),
        ]),
        ("chuushin", "中心", "ちゅうしん", "chuushin", "pusat/tengah", "N3", "noun", "中心", "chuushin", "中心", "chuushin", [
            ("町の中心に公園があります。", "Machi no chuushin ni kouen ga arimasu.", "Ada taman di pusat kota."),
        ]),
        ("ichi", "位置", "いち", "ichi", "posisi/lokasi", "N2", "noun", "位置", "ichi", "位置", "ichi", [
            ("位置を確認します。", "Ichi o kakunin shimasu.", "Mengecek posisi."),
        ]),
        ("uchigawa", "内側", "うちがわ", "uchigawa", "sisi dalam", "N2", "noun", "内側", "uchigawa", "内側", "uchigawa", [
            ("ドアの内側に立ってください。", "Doa no uchigawa ni tatte kudasai.", "Berdiri di bagian dalam pintu."),
        ]),
        ("kitagawa", "北側", "きたがわ", "kitagawa", "sisi utara", "N2", "noun", "北側", "kitagawa", "北側", "kitagawa", [
            ("北側の部屋は寒いです。", "Kitagawa no heya wa samui desu.", "Ruangan sisi utara dingin."),
        ]),
        ("kyori", "距離", "きょり", "kyori", "jarak", "N2", "noun", "距離", "kyori", "距離", "kyori", [
            ("距離が遠いです。", "Kyori ga tooi desu.", "Jaraknya jauh."),
        ]),
        ("kinjo", "近所", "きんじょ", "kinjo", "sekitar rumah/tetangga", "N2", "noun", "近所", "kinjo", "近所", "kinjo", [
            ("近所にスーパーがあります。", "Kinjo ni suupaa ga arimasu.", "Ada supermarket di dekat rumah. (satu lingkungan)"),
        ]),
        ("keshiki", "景色", "けしき", "keshiki", "pemandangan", "N2", "noun", "景色", "keshiki", "景色", "keshiki", [
            ("景色がきれいです。", "Keshiki ga kirei desu.", "Pemandangannya indah."),
        ]),
        ("kouhou", "後方", "こうほう", "kouhou", "arah belakang", "N2", "noun", "後方", "kouhou", "後方", "kouhou", [
            ("後方に下がってください。", "Kouhou ni sagatte kudasai.", "Silakan mundur ke arah belakang."),
        ]),
        ("shoumen", "正面", "しょうめん", "shoumen", "bagian depan", "N2", "noun", "正面", "shoumen", "正面", "shoumen", [
            ("正面から入ってください。", "Shoumen kara haitte kudasai.", "Silakan masuk dari depan."),
        ]),
        ("sotogawa", "外側", "そとがわ", "sotogawa", "sisi luar", "N2", "noun", "外側", "sotogawa", "外側", "sotogawa", [
            ("外側を見てください。", "Sotogawa o mite kudasai.", "Lihat bagian luar."),
        ]),
        ("chika", "地下", "ちか", "chika", "bawah tanah", "N2", "noun", "地下", "chika", "地下", "chika", [
            ("地下に駐車場があります。", "Chika ni chuushajou ga arimasu.", "Ada parkiran di bawah tanah."),
        ]),
        ("choujou", "頂上", "ちょうじょう", "choujou", "puncak", "N2", "noun", "頂上", "choujou", "頂上", "choujou", [
            ("山の頂上に着きました。", "Yama no choujou ni tsukimashita.", "Sampai di puncak gunung."),
        ]),
        ("tochuu", "途中", "とちゅう", "tochuu", "di tengah perjalanan", "N2", "noun", "途中", "tochuu", "途中", "tochuu", [
            ("学校の途中で友達に会った。", "Gakkou no tochuu de tomodachi ni atta.", "Di perjalanan ke sekolah saya bertemu teman."),
        ]),
        ("hodou", "歩道", "ほどう", "hodou", "trotoar", "N2", "noun", "歩道", "hodou", "歩道", "hodou", [
            ("歩道を歩いてください。", "Hodou o aruite kudasai.", "Tolong berjalan di trotoar."),
        ]),
        ("chiheisen", "地平線", "ちへいせん", "chiheisen", "garis horizon", "N3", "noun", "地平線", "chiheisen", "地平線", "chiheisen", [
            ("地平線に夕日が見えます。", "Chiheisen ni yuuhi ga miemasu.", "Matahari terbenam terlihat di garis horizon."),
        ]),
        ("sayuu", "左右", "さゆう", "sayuu", "kiri dan kanan", "N3", "noun", "左右", "sayuu", "左右", "sayuu", [
            ("左右を確認します。", "Sayuu o kakunin shimasu.", "Memeriksa kiri dan kanan."),
        ]),
        ("genchi", "現地", "げんち", "genchi", "lokasi setempat", "N1", "noun", "現地", "genchi", "現地", "genchi", [
            ("現地に到着しました。", "Genchi ni touchaku shimashita.", "Tiba di lokasi setempat."),
        ]),
        ("haigo", "背後", "はいご", "haigo", "di balik/belakang", "N1", "noun", "背後", "haigo", "背後", "haigo", [
            ("背後に隠れます。", "Haigo ni kakuremasu.", "Bersembunyi di belakang."),
        ]),
        ("jimoto", "地元", "じもと", "jimoto", "daerah asal/setempat", "N1", "noun", "地元", "jimoto", "地元", "jimoto", [
            ("地元に帰ります。", "Jimoto ni kaerimasu.", "Pulang ke daerah asal."),
        ]),
        ("hantou", "半島", "はんとう", "hantou", "semenanjung", "N2", "noun", "半島", "hantou", "半島", "hantou", [
            ("半島を旅行します。", "Hantou o ryokou shimasu.", "Bepergian ke semenanjung."),
        ]),
        ("namiki", "並木", "なみき", "namiki", "deretan pohon", "N2", "noun", "並木", "namiki", "並木", "namiki", [
            ("並木道を歩きます。", "Namikimichi o arukimasu.", "Berjalan di jalan berderet pohon."),
        ]),
        ("sekidou", "赤道", "せきどう", "sekidou", "garis khatulistiwa", "N2", "noun", "赤道", "sekidou", "赤道", "sekidou", [
            ("赤道を通過します。", "Sekidou o tsuuka shimasu.", "Melintasi garis khatulistiwa."),
        ]),
        ("basho", "場所", "ばしょ", "basho", "tempat/lokasi", "N4", "noun", "場所", "basho", "場所", "basho", [
            ("集合場所を確認します。", "Shuugou basho o kakunin shimasu.", "Memeriksa tempat berkumpul."),
        ]),
        ("kaigan", "海岸", "かいがん", "kaigan", "pantai", "N4", "noun", "海岸", "kaigan", "海岸", "kaigan", [
            ("海岸を歩きます。", "Kaigan o arukimasu.", "Berjalan di pantai."),
        ]),
        ("kaijou", "会場", "かいじょう", "kaijou", "tempat acara", "N4", "noun", "会場", "kaijou", "会場", "kaijou", [
            ("会場に到着しました。", "Kaijou ni touchaku shimashita.", "Tiba di tempat acara."),
        ]),
        ("kougai", "郊外", "こうがい", "kougai", "pinggiran kota", "N4", "noun", "郊外", "kougai", "郊外", "kougai", [
            ("郊外に住んでいます。", "Kougai ni sunde imasu.", "Tinggal di pinggiran kota."),
        ]),
    ],
    "negara_kota": [
        ("nihon", "日本", "にほん", "nihon", "Jepang", "N5", "noun", "日本", "nihon", "日本", "nihon", [
            ("日本に住んでいます。", "Nihon ni sunde imasu.", "Saya tinggal di Jepang."),
        ]),
        ("indoneshia", None, "インドネシア", "indoneshia", "Indonesia", "N5", "noun", "インドネシア", "indoneshia", "インドネシア", "indoneshia", [
            ("インドネシア出身です。", "Indoneshia shusshin desu.", "Saya berasal dari Indonesia."),
        ]),
        ("amerika", None, "アメリカ", "amerika", "Amerika", "N5", "noun", "アメリカ", "amerika", "アメリカ", "amerika", [
            ("アメリカに行きたいです。", "Amerika ni ikitai desu.", "Saya ingin pergi ke Amerika."),
        ]),
        ("chuugoku", "中国", "ちゅうごく", "chuugoku", "Tiongkok (China)", "N5", "noun", "中国", "chuugoku", "中国", "chuugoku", [
            ("中国は大きいです。", "Chuugoku wa ookii desu.", "Tiongkok itu luas."),
        ]),
        ("kankoku", "韓国", "かんこく", "kankoku", "Korea Selatan", "N5", "noun", "韓国", "kankoku", "韓国", "kankoku", [
            ("韓国に旅行します。", "Kankoku ni ryokou shimasu.", "Saya bepergian ke Korea."),
        ]),
        ("tai", None, "タイ", "tai", "Thailand", "N4", "noun", "タイ", "tai", "タイ", "tai", [
            ("タイ料理が好きです。", "Tai ryouri ga suki desu.", "Saya suka masakan Thailand."),
        ]),
        ("toukyou", "東京", "とうきょう", "toukyou", "Tokyo", "N5", "noun", "東京", "toukyou", "東京", "toukyou", [
            ("東京は日本の首都です。", "Toukyou wa Nihon no shuto desu.", "Tokyo adalah ibu kota Jepang."),
        ]),
        ("oosaka", "大阪", "おおさか", "oosaka", "Osaka", "N4", "noun", "大阪", "oosaka", "大阪", "oosaka", [
            ("大阪に行きました。", "Oosaka ni ikimashita.", "Saya pergi ke Osaka."),
        ]),
        ("jakaruta", None, "ジャカルタ", "jakaruta", "Jakarta", "N4", "noun", "ジャカルタ", "jakaruta", "ジャカルタ", "jakaruta", [
            ("ジャカルタに住んでいます。", "Jakaruta ni sunde imasu.", "Saya tinggal di Jakarta."),
        ]),
        ("bari", None, "バリ", "bari", "Bali", "N4", "noun", "バリ", "bari", "バリ", "bari", [
            ("バリ島は有名です。", "Bari-tou wa yuumei desu.", "Pulau Bali itu terkenal."),
        ]),
        ("kyouto", "京都", "きょうと", "kyouto", "Kyoto", "N3", "noun", "京都", "kyouto", "京都", "kyouto", [
            ("京都には神社がたくさんあります。", "Kyouto ni wa jinja ga takusan arimasu.", "Di Kyoto ada banyak kuil Shinto."),
        ]),
        # N5 addition, same compound-pool gap noted above.
        ("gaikoku", "外国", "がいこく", "gaikoku", "negara asing/luar negeri", "N5", "noun", "外国", "gaikoku", "外国", "gaikoku", [
            ("外国に住みたいです。", "Gaikoku ni sumitai desu.", "Saya ingin tinggal di luar negeri."),
        ]),
        ("gaikokujin", "外国人", "がいこくじん", "gaikokujin", "orang asing/warga negara asing", "N5", "noun", "外国人", "gaikokujin", "外国人", "gaikokujin", [
            ("この町には外国人が多いです。", "Kono machi ni wa gaikokujin ga ooi desu.", "Di kota ini banyak orang asing."),
        ]),
        ("chuugokugo", "中国語", "ちゅうごくご", "chuugokugo", "bahasa Mandarin", "N5", "noun", "中国語", "chuugokugo", "中国語", "chuugokugo", [
            ("中国語を勉強しています。", "Chuugokugo o benkyou shite imasu.", "Saya sedang belajar bahasa Mandarin."),
        ]),
        # N3/N4 addition (2026-07-20, thirteenth batch): more country/city
        # nouns, for Kombinasi Kanji pool depth.
        ("taiwan", "台湾", "たいわん", "taiwan", "Taiwan", "N4", "noun", "台湾", "taiwan", "台湾", "taiwan", [
            ("台湾に旅行します。", "Taiwan ni ryokou shimasu.", "Saya bepergian ke Taiwan."),
        ]),
        ("nagoya", "名古屋", "なごや", "nagoya", "Nagoya", "N3", "noun", "名古屋", "nagoya", "名古屋", "nagoya", [
            ("名古屋で働いています。", "Nagoya de hataraite imasu.", "Saya bekerja di Nagoya."),
        ]),
        ("inaka", "田舎", "いなか", "inaka", "desa/kampung", "N2", "noun", "田舎", "inaka", "田舎", "inaka", [
            ("田舎で育ちました。", "Inaka de sodachimashita.", "tumbuh besar di desa. (kk.pasif)"),
        ]),
        ("kakuchi", "各地", "かくち", "kakuchi", "berbagai daerah", "N2", "noun", "各地", "kakuchi", "各地", "kakuchi", [
            ("各地で地震が起きています。", "Kakuchi de jishin ga okite imasu.", "Gempa terjadi di berbagai daerah."),
        ]),
        ("kakkoku", "各国", "かっこく", "kakkoku", "berbagai negara", "N2", "noun", "各国", "kakkoku", "各国", "kakkoku", [
            ("各国の文化を学びます。", "Kakkoku no bunka o manabimasu.", "Mempelajari budaya berbagai negara. (setiap negara)"),
        ]),
        ("kikoku", "帰国", "きこく", "kikoku", "pulang ke negara asal", "N2", "noun", "帰国", "kikoku", "帰国", "kikoku", [
            ("来年帰国します。", "Rainen kikoku shimasu.", "Tahun depan pulang ke negara asal."),
        ]),
        ("kokusai", "国際", "こくさい", "kokusai", "internasional", "N2", "noun", "国際", "kokusai", "国際", "kokusai", [
            ("国際会議に参加します。", "Kokusai kaigi ni sanka shimasu.", "Mengikuti konferensi pertemuan internasional."),
        ]),
        ("shimin", "市民", "しみん", "shimin", "warga kota", "N2", "noun", "市民", "shimin", "市民", "shimin", [
            ("市民が集まっています。", "Shimin ga atsumatte imasu.", "Warga kota berkumpul."),
        ]),
        ("shusshin", "出身", "しゅっしん", "shusshin", "asal (daerah/negara)", "N2", "noun", "出身", "shusshin", "出身", "shusshin", [
            ("私はインドネシア出身です。", "Watashi wa Indoneshia shusshin desu.", "Saya berasal dari Indonesia. (daerah, negara,sekolah)"),
        ]),
        ("taizai", "滞在", "たいざい", "taizai", "tinggal sementara", "N2", "noun", "滞在", "taizai", "滞在", "taizai", [
            ("日本に3か月滞在します。", "Nihon ni sankagetsu taizai shimasu.", "Tinggal di Jepang 3 bulan. (Tinggal sementara)"),
        ]),
        ("tokai", "都会", "とかい", "tokai", "kota besar/metropolitan", "N2", "noun", "都会", "tokai", "都会", "tokai", [
            ("都会で働きたいです。", "Tokai de hatarakitai desu.", "Saya ingin bekerja di kota besar. (metropolitan)"),
        ]),
        ("ijuu", "移住", "いじゅう", "ijuu", "pindah tinggal (menetap)", "N2", "noun", "移住", "ijuu", "移住", "ijuu", [
            ("彼は外国に移住しました。", "Kare wa gaikoku ni ijuu shimashita.", "Dia pindah tinggal ke luar negeri. (Pindah menetap lama)"),
        ]),
        ("gaikou", "外交", "がいこう", "gaikou", "diplomasi", "N3", "noun", "外交", "gaikou", "外交", "gaikou", [
            ("外交関係を築きます。", "Gaikou kankei o kizukimasu.", "Membangun hubungan diplomatik."),
        ]),
        ("gikai", "議会", "ぎかい", "gikai", "parlemen/dewan", "N3", "noun", "議会", "gikai", "議会", "gikai", [
            ("議会で審議します。", "Gikai de shingi shimasu.", "Dibahas di parlemen."),
        ]),
        ("kaigai", "海外", "かいがい", "kaigai", "luar negeri", "N3", "noun", "海外", "kaigai", "海外", "kaigai", [
            ("海外に住みたいです。", "Kaigai ni sumitai desu.", "Saya ingin tinggal di luar negeri."),
        ]),
        ("kokka", "国家", "こっか", "kokka", "negara (bangsa)", "N3", "noun", "国家", "kokka", "国家", "kokka", [
            ("国家の代表です。", "Kokka no daihyou desu.", "Perwakilan negara."),
        ]),
        ("kokkai", "国会", "こっかい", "kokkai", "parlemen nasional", "N3", "noun", "国会", "kokkai", "国会", "kokkai", [
            ("国会で決定します。", "Kokkai de kettei shimasu.", "Diputuskan di parlemen."),
        ]),
        ("kokkyou", "国境", "こっきょう", "kokkyou", "perbatasan negara", "N3", "noun", "国境", "kokkyou", "国境", "kokkyou", [
            ("国境を越えます。", "Kokkyou o koemasu.", "Melintasi perbatasan negara."),
        ]),
        ("kokumin", "国民", "こくみん", "kokumin", "rakyat/warga negara", "N3", "noun", "国民", "kokumin", "国民", "kokumin", [
            ("国民の声を聞きます。", "Kokumin no koe o kikimasu.", "Mendengarkan suara rakyat."),
        ]),
        ("zenkoku", "全国", "ぜんこく", "zenkoku", "seluruh negeri", "N3", "noun", "全国", "zenkoku", "全国", "zenkoku", [
            ("全国で販売します。", "Zenkoku de hanbai shimasu.", "Dijual di seluruh negeri."),
        ]),
        ("dokusai", "独裁", "どくさい", "dokusai", "kediktatoran", "N1", "noun", "独裁", "dokusai", "独裁", "dokusai", [
            ("独裁政権が続いています。", "Dokusai seiken ga tsuzuite imasu.", "Rezim diktator masih berlanjut."),
        ]),
        ("doumei", "同盟", "どうめい", "doumei", "aliansi", "N1", "noun", "同盟", "doumei", "同盟", "doumei", [
            ("同盟を結びます。", "Doumei o musubimasu.", "Membentuk aliansi."),
        ]),
        ("fuhai", "腐敗", "ふはい", "fuhai", "korupsi/pembusukan", "N1", "noun", "腐敗", "fuhai", "腐敗", "fuhai", [
            ("政治の腐敗を批判します。", "Seiji no fuhai o hihan shimasu.", "Mengkritik korupsi politik."),
        ]),
        ("funsou", "紛争", "ふんそう", "funsou", "konflik/perselisihan", "N1", "noun", "紛争", "funsou", "紛争", "funsou", [
            ("国際紛争が続いています。", "Kokusai funsou ga tsuzuite imasu.", "Konflik internasional masih berlanjut."),
        ]),
        ("fuusa", "封鎖", "ふうさ", "fuusa", "blokade/penutupan", "N1", "noun", "封鎖", "fuusa", "封鎖", "fuusa", [
            ("道路を封鎖します。", "Douro o fuusa shimasu.", "Menutup jalan."),
        ]),
        ("gunji", "軍事", "ぐんじ", "gunji", "urusan militer", "N1", "noun", "軍事", "gunji", "軍事", "gunji", [
            ("軍事力を強化します。", "Gunjiryoku o kyouka shimasu.", "Memperkuat kekuatan militer."),
        ]),
        ("haishi", "廃止", "はいし", "haishi", "penghapusan (aturan)", "N1", "noun", "廃止", "haishi", "廃止", "haishi", [
            ("制度を廃止します。", "Seido o haishi shimasu.", "Menghapus sistem."),
        ]),
        ("hanei", "繁栄", "はんえい", "hanei", "kemakmuran", "N1", "noun", "繁栄", "hanei", "繁栄", "hanei", [
            ("国が繁栄しています。", "Kuni ga han'ei shite imasu.", "Negara berkembang makmur."),
        ]),
        ("hanran", "反乱", "はんらん", "hanran", "pemberontakan", "N1", "noun", "反乱", "hanran", "反乱", "hanran", [
            ("反乱が起こりました。", "Hanran ga okorimashita.", "Pemberontakan terjadi."),
        ]),
        ("imin", "移民", "いみん", "imin", "imigran/imigrasi", "N1", "noun", "移民", "imin", "移民", "imin", [
            ("移民が増えています。", "Imin ga fuete imasu.", "Jumlah imigran bertambah."),
        ]),
        ("jousei", "情勢", "じょうせい", "jousei", "keadaan/situasi", "N1", "noun", "情勢", "jousei", "情勢", "jousei", [
            ("政治情勢が不安定です。", "Seiji jousei ga fuantei desu.", "Situasi politik tidak stabil."),
        ]),
        ("kainyuu", "介入", "かいにゅう", "kainyuu", "intervensi", "N1", "noun", "介入", "kainyuu", "介入", "kainyuu", [
            ("政府が介入します。", "Seifu ga kainyuu shimasu.", "Pemerintah melakukan intervensi."),
        ]),
        ("kokuou", "国王", "こくおう", "kokuou", "raja", "N2", "noun", "国王", "kokuou", "国王", "kokuou", [
            ("国王が訪問します。", "Kokuou ga houmon shimasu.", "Raja berkunjung."),
        ]),
        ("kokuritsu", "国立", "こくりつ", "kokuritsu", "negeri (nasional)", "N2", "noun", "国立", "kokuritsu", "国立", "kokuritsu", [
            ("国立大学に入学します。", "Kokuritsu daigaku ni nyuugaku shimasu.", "Masuk universitas negeri."),
        ]),
        ("kokuseki", "国籍", "こくせき", "kokuseki", "kewarganegaraan", "N2", "noun", "国籍", "kokuseki", "国籍", "kokuseki", [
            ("国籍を取得します。", "Kokuseki o shutoku shimasu.", "Memperoleh kewarganegaraan."),
        ]),
        ("touyou", "東洋", "とうよう", "touyou", "Timur (Asia)", "N2", "noun", "東洋", "touyou", "東洋", "touyou", [
            ("東洋の文化を学びます。", "Touyou no bunka o manabimasu.", "Belajar budaya Timur."),
        ]),
        ("jinkou", "人口", "じんこう", "jinkou", "populasi", "N4", "noun", "人口", "jinkou", "人口", "jinkou", [
            ("人口が増えています。", "Jinkou ga fuete imasu.", "Populasi bertambah."),
        ]),
        ("seiji", "政治", "せいじ", "seiji", "politik", "N4", "noun", "政治", "seiji", "政治", "seiji", [
            ("政治に興味があります。", "Seiji ni kyoumi ga arimasu.", "Tertarik pada politik."),
        ]),
        ("seiyou", "西洋", "せいよう", "seiyou", "Barat (dunia)", "N4", "noun", "西洋", "seiyou", "西洋", "seiyou", [
            ("西洋の文化を学びます。", "Seiyou no bunka o manabimasu.", "Belajar budaya Barat."),
        ]),
        ("sekai", "世界", "せかい", "sekai", "dunia", "N4", "noun", "世界", "sekai", "世界", "sekai", [
            ("世界を旅行します。", "Sekai o ryokou shimasu.", "Bepergian keliling dunia."),
        ]),
        ("sensou", "戦争", "せんそう", "sensou", "perang", "N4", "noun", "戦争", "sensou", "戦争", "sensou", [
            ("戦争が終わりました。", "Sensou ga owarimashita.", "Perang telah berakhir."),
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
