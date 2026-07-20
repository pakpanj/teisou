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
