import json

# Seed data for the Kanji dictionary (Batch 4, restructured for Batch 7).
#
# Batch 7 split the old flat "one word + one embedded sentence" example
# shape into two separate lists — wordExamples ("contoh kata") and
# sentenceExamples ("contoh kalimat", now with romaji) — matching how
# KanjiEntry.examples is now a *computed* backward-compat getter (pairs
# wordExamples[i] with sentenceExamples[i]) rather than a stored field, so
# `search/kanji_detail_screen.dart` keeps working unchanged.
#
# This pass only *migrates* the 15 existing N5 entries to the new shape
# (added romaji + radical, still one word/one sentence each) to prove the
# schema end-to-end — bringing every N5 kanji up to the Fase 1 minimum of
# 3 word examples / 2 sentence examples happens in the full N5+N4 dataset
# pass (see generate_kanji_n5.py / generate_kanji_n4.py once those land).
#
# Each tuple: (id_suffix, character, onyomi, kunyomi, meanings, strokeCount,
#              radical, word_examples, sentence_examples)
# word_examples: list of (word, reading, meaning)
# sentence_examples: list of (japanese, romaji, translation)
N5_KANJI = [
    ("ichi", "一", ["イチ", "イツ"], ["ひと", "ひと-つ"], ["satu", "one"], 1, "一", [
        ("一つ", "hitotsu", "satu (unit)"),
        ("一月", "ichigatsu", "bulan Januari"),
        ("一人", "hitori", "satu orang/sendirian"),
    ], [
        ("りんごを一つください。", "Ringo o hitotsu kudasai.", "Tolong satu apel."),
        ("一月は寒いです。", "Ichigatsu wa samui desu.", "Bulan Januari dingin."),
    ]),
    ("ni", "二", ["ニ"], ["ふた", "ふた-つ"], ["dua", "two"], 2, "二", [
        ("二つ", "futatsu", "dua (unit)"),
        ("二月", "nigatsu", "bulan Februari"),
        ("二人", "futari", "dua orang"),
    ], [
        ("みかんを二つ買いました。", "Mikan o futatsu kaimashita.", "Saya membeli dua jeruk."),
        ("二月に旅行します。", "Nigatsu ni ryokou shimasu.", "Bulan Februari saya akan bepergian."),
    ]),
    ("san", "三", ["サン"], ["み", "み-つ"], ["tiga", "three"], 3, "一", [
        ("三つ", "mittsu", "tiga (unit)"),
        ("三月", "sangatsu", "bulan Maret"),
        ("三人", "sannin", "tiga orang"),
    ], [
        ("卵を三つ使います。", "Tamago o mittsu tsukaimasu.", "Saya memakai tiga telur."),
        ("三月に卒業します。", "Sangatsu ni sotsugyou shimasu.", "Bulan Maret saya lulus."),
    ]),
    ("yon", "四", ["シ"], ["よ", "よん", "よ-つ"], ["empat", "four"], 5, "囗", [
        ("四月", "shigatsu", "bulan April"),
        ("四人", "yonin", "empat orang"),
        ("四つ", "yottsu", "empat (unit)"),
    ], [
        ("四月に日本へ行きます。", "Shigatsu ni Nihon e ikimasu.", "Saya pergi ke Jepang bulan April."),
        ("家族は四人です。", "Kazoku wa yonin desu.", "Keluarga saya berjumlah empat orang."),
    ]),
    ("go", "五", ["ゴ"], ["いつ", "いつ-つ"], ["lima", "five"], 4, "二", [
        ("五つ", "itsutsu", "lima (unit)"),
        ("五月", "gogatsu", "bulan Mei"),
        ("五人", "gonin", "lima orang"),
    ], [
        ("五つの部屋があります。", "Itsutsu no heya ga arimasu.", "Ada lima kamar."),
        ("五月は暖かいです。", "Gogatsu wa atatakai desu.", "Bulan Mei hangat."),
    ]),
    ("roku", "六", ["ロク"], ["む", "む-つ"], ["enam", "six"], 4, "八", [
        ("六月", "rokugatsu", "bulan Juni"),
        ("六つ", "muttsu", "enam (unit)"),
        ("六人", "rokunin", "enam orang"),
    ], [
        ("六月は雨が多いです。", "Rokugatsu wa ame ga ooi desu.", "Bulan Juni banyak hujan."),
        ("六人で旅行しました。", "Rokunin de ryokou shimashita.", "Kami bepergian berenam."),
    ]),
    ("shichi", "七", ["シチ"], ["なな", "なな-つ"], ["tujuh", "seven"], 2, "一", [
        ("七つ", "nanatsu", "tujuh (unit)"),
        ("七月", "shichigatsu", "bulan Juli"),
        ("七人", "shichinin", "tujuh orang"),
    ], [
        ("七つの星が見えます。", "Nanatsu no hoshi ga miemasu.", "Terlihat tujuh bintang."),
        ("七月に夏休みが始まります。", "Shichigatsu ni natsuyasumi ga hajimarimasu.", "Bulan Juli liburan musim panas dimulai."),
    ]),
    ("hachi", "八", ["ハチ"], ["や", "や-つ"], ["delapan", "eight"], 2, "八", [
        ("八月", "hachigatsu", "bulan Agustus"),
        ("八つ", "yattsu", "delapan (unit)"),
        ("八人", "hachinin", "delapan orang"),
    ], [
        ("八月はとても暑いです。", "Hachigatsu wa totemo atsui desu.", "Bulan Agustus sangat panas."),
        ("八人が参加します。", "Hachinin ga sanka shimasu.", "Delapan orang akan berpartisipasi."),
    ]),
    ("kyuu", "九", ["キュウ", "ク"], ["ここの", "ここの-つ"], ["sembilan", "nine"], 2, "乙", [
        ("九つ", "kokonotsu", "sembilan (unit)"),
        ("九月", "kugatsu", "bulan September"),
        ("九人", "kyuunin", "sembilan orang"),
    ], [
        ("九つの箱があります。", "Kokonotsu no hako ga arimasu.", "Ada sembilan kotak."),
        ("九月に新学期が始まります。", "Kugatsu ni shingakki ga hajimarimasu.", "Bulan September semester baru dimulai."),
    ]),
    ("juu", "十", ["ジュウ"], ["とお"], ["sepuluh", "ten"], 2, "十", [
        ("十日", "tooka", "tanggal sepuluh / sepuluh hari"),
        ("十人", "juunin", "sepuluh orang"),
        ("十月", "juugatsu", "bulan Oktober"),
    ], [
        ("十日に会いましょう。", "Tooka ni aimashou.", "Ayo bertemu tanggal sepuluh."),
        ("十月に文化祭があります。", "Juugatsu ni bunkasai ga arimasu.", "Bulan Oktober ada festival budaya."),
    ]),
    ("hito", "人", ["ジン", "ニン"], ["ひと"], ["orang", "person"], 2, "人", [
        ("日本人", "nihonjin", "orang Jepang"),
        ("一人", "hitori", "satu orang/sendirian"),
        ("人々", "hitobito", "orang-orang"),
    ], [
        ("彼は日本人です。", "Kare wa nihonjin desu.", "Dia orang Jepang."),
        ("教室に一人います。", "Kyoushitsu ni hitori imasu.", "Ada satu orang di kelas."),
    ]),
    ("hi", "日", ["ニチ", "ジツ"], ["ひ", "か"], ["hari", "matahari", "sun/day"], 4, "日", [
        ("日曜日", "nichiyoubi", "hari Minggu"),
        ("毎日", "mainichi", "setiap hari"),
        ("誕生日", "tanjoubi", "hari ulang tahun"),
    ], [
        ("日曜日は休みです。", "Nichiyoubi wa yasumi desu.", "Hari Minggu libur."),
        ("毎日日本語を勉強します。", "Mainichi nihongo o benkyou shimasu.", "Setiap hari saya belajar bahasa Jepang."),
    ]),
    ("tsuki", "月", ["ゲツ", "ガツ"], ["つき"], ["bulan", "moon/month"], 4, "月", [
        ("月曜日", "getsuyoubi", "hari Senin"),
        ("月", "tsuki", "bulan (langit)"),
        ("今月", "kongetsu", "bulan ini"),
    ], [
        ("月曜日から学校です。", "Getsuyoubi kara gakkou desu.", "Sekolah mulai hari Senin."),
        ("今夜、月がきれいです。", "Kon'ya, tsuki ga kirei desu.", "Malam ini, bulan indah."),
    ]),
    ("yama", "山", ["サン"], ["やま"], ["gunung", "mountain"], 3, "山", [
        ("富士山", "fujisan", "Gunung Fuji"),
        ("山", "yama", "gunung"),
        ("登山", "tozan", "mendaki gunung"),
    ], [
        ("富士山はきれいです。", "Fujisan wa kirei desu.", "Gunung Fuji indah."),
        ("週末に山に登ります。", "Shuumatsu ni yama ni noborimasu.", "Akhir pekan saya mendaki gunung."),
    ]),
    ("kawa", "川", ["セン"], ["かわ"], ["sungai", "river"], 3, "川", [
        ("川", "kawa", "sungai"),
        ("小川", "ogawa", "sungai kecil"),
        ("川岸", "kawagishi", "tepi sungai"),
    ], [
        ("川で泳ぎました。", "Kawa de oyogimashita.", "Saya berenang di sungai."),
        ("小川の水はきれいです。", "Ogawa no mizu wa kirei desu.", "Air sungai kecil itu jernih."),
    ]),
    # --- Batch A: 百千万円 + 年時分間週曜今半 + 木林森田火水土空気雨石花 (24) ---
    ("hyaku", "百", ["ヒャク"], [], ["ratus", "hundred"], 6, "白", [
        ("百円", "hyakuen", "seratus yen"),
        ("百人", "hyakunin", "seratus orang"),
        ("百点", "hyakuten", "nilai seratus/nilai sempurna"),
    ], [
        ("このりんごは百円です。", "Kono ringo wa hyakuen desu.", "Apel ini seratus yen."),
        ("テストで百点を取りました。", "Tesuto de hyakuten o torimashita.", "Saya mendapat nilai 100 di tes."),
    ]),
    ("sen", "千", ["セン"], ["ち"], ["ribu", "thousand"], 3, "十", [
        ("千円", "sen'en", "seribu yen"),
        ("千人", "sennin", "seribu orang"),
        ("二千", "nisen", "dua ribu"),
    ], [
        ("このかばんは千円です。", "Kono kaban wa sen'en desu.", "Tas ini seribu yen."),
        ("千人がそのコンサートに来ました。", "Sennin ga sono konsaato ni kimashita.", "Seribu orang datang ke konser itu."),
    ]),
    ("man", "万", ["マン", "バン"], [], ["puluh ribu", "ten thousand"], 3, "一", [
        ("一万円", "ichiman'en", "sepuluh ribu yen"),
        ("万年筆", "mannenhitsu", "pena tinta (fountain pen)"),
        ("十万", "juuman", "seratus ribu"),
    ], [
        ("このパソコンは十万円です。", "Kono pasokon wa juuman'en desu.", "Komputer ini seratus ribu yen."),
        ("誕生日に一万円もらいました。", "Tanjoubi ni ichiman'en moraimashita.", "Saya mendapat sepuluh ribu yen saat ulang tahun."),
    ]),
    ("en", "円", ["エン"], ["まる"], ["yen", "lingkaran/bundar", "circle/round"], 4, "冂", [
        ("円", "en", "yen"),
        ("百円", "hyakuen", "seratus yen"),
        ("千円", "sen'en", "seribu yen"),
    ], [
        ("これは百円です。", "Kore wa hyakuen desu.", "Ini seratus yen."),
        ("千円貸してください。", "Sen'en kashite kudasai.", "Tolong pinjamkan saya seribu yen."),
    ]),
    ("nen", "年", ["ネン"], ["とし"], ["tahun", "year"], 6, "干", [
        ("来年", "rainen", "tahun depan"),
        ("今年", "kotoshi", "tahun ini"),
        ("毎年", "mainen", "setiap tahun"),
    ], [
        ("今年、日本語を勉強します。", "Kotoshi, nihongo o benkyou shimasu.", "Tahun ini, saya belajar bahasa Jepang."),
        ("来年、日本へ行きます。", "Rainen, Nihon e ikimasu.", "Tahun depan, saya akan pergi ke Jepang."),
    ]),
    ("ji", "時", ["ジ"], ["とき"], ["waktu", "jam", "time", "hour"], 10, "日", [
        ("時間", "jikan", "waktu/jam"),
        ("何時", "nanji", "jam berapa"),
        ("時々", "tokidoki", "kadang-kadang"),
    ], [
        ("今何時ですか。", "Ima nanji desu ka.", "Sekarang jam berapa?"),
        ("時々映画を見ます。", "Tokidoki eiga o mimasu.", "Kadang-kadang saya menonton film."),
    ]),
    ("fun", "分", ["フン", "ブン", "ブ"], ["わ-かる", "わ-ける"], ["menit", "bagian", "minute", "part", "understand"], 4, "刀", [
        ("五分", "gofun", "lima menit"),
        ("分かる", "wakaru", "mengerti"),
        ("半分", "hanbun", "setengah"),
    ], [
        ("駅まで五分かかります。", "Eki made gofun kakarimasu.", "Sampai stasiun butuh lima menit."),
        ("この問題が分かりません。", "Kono mondai ga wakarimasen.", "Saya tidak mengerti soal ini."),
    ]),
    ("kan", "間", ["カン", "ケン"], ["あいだ", "ま"], ["antara", "jarak waktu", "between", "interval"], 12, "門", [
        ("時間", "jikan", "waktu"),
        ("間", "aida", "antara/celah"),
        ("一週間", "isshuukan", "satu minggu"),
    ], [
        ("授業は一時間です。", "Jugyou wa ichijikan desu.", "Pelajaran berlangsung satu jam."),
        ("木と木の間に猫がいます。", "Ki to ki no aida ni neko ga imasu.", "Ada kucing di antara pohon-pohon."),
    ]),
    ("shuu", "週", ["シュウ"], [], ["minggu", "week"], 11, "辶", [
        ("今週", "konshuu", "minggu ini"),
        ("来週", "raishuu", "minggu depan"),
        ("毎週", "maishuu", "setiap minggu"),
    ], [
        ("今週は忙しいです。", "Konshuu wa isogashii desu.", "Minggu ini sibuk."),
        ("毎週日曜日に掃除します。", "Maishuu nichiyoubi ni souji shimasu.", "Setiap hari Minggu saya bersih-bersih."),
    ]),
    ("you", "曜", ["ヨウ"], [], ["hari (dalam minggu)", "day of the week"], 18, "日", [
        ("曜日", "youbi", "hari (dalam minggu)"),
        ("月曜日", "getsuyoubi", "hari Senin"),
        ("何曜日", "nanyoubi", "hari apa"),
    ], [
        ("今日は何曜日ですか。", "Kyou wa nanyoubi desu ka.", "Hari ini hari apa?"),
        ("土曜日に友達と遊びます。", "Doyoubi ni tomodachi to asobimasu.", "Hari Sabtu saya bermain dengan teman."),
    ]),
    ("ima", "今", ["コン", "キン"], ["いま"], ["sekarang", "now"], 4, "人", [
        ("今", "ima", "sekarang"),
        ("今日", "kyou", "hari ini"),
        ("今年", "kotoshi", "tahun ini"),
    ], [
        ("今、忙しいです。", "Ima, isogashii desu.", "Sekarang, saya sibuk."),
        ("今日は暑いです。", "Kyou wa atsui desu.", "Hari ini panas."),
    ]),
    ("han", "半", ["ハン"], ["なか-ば"], ["setengah", "half"], 5, "十", [
        ("半分", "hanbun", "setengah"),
        ("一時半", "ichijihan", "jam satu setengah"),
        ("半年", "hantoshi", "setengah tahun"),
    ], [
        ("今、三時半です。", "Ima, sanjihan desu.", "Sekarang jam setengah empat (3:30)."),
        ("りんごを半分食べました。", "Ringo o hanbun tabemashita.", "Saya makan setengah apel."),
    ]),
    ("ki", "木", ["モク", "ボク"], ["き"], ["pohon", "kayu", "tree", "wood"], 4, "木", [
        ("木曜日", "mokuyoubi", "hari Kamis"),
        ("木", "ki", "pohon"),
        ("大木", "taiboku", "pohon besar"),
    ], [
        ("公園に大きい木があります。", "Kouen ni ookii ki ga arimasu.", "Ada pohon besar di taman."),
        ("木曜日に会いましょう。", "Mokuyoubi ni aimashou.", "Ayo bertemu hari Kamis."),
    ]),
    ("hayashi", "林", ["リン"], ["はやし"], ["hutan kecil", "woods", "grove"], 8, "木", [
        ("林", "hayashi", "hutan kecil"),
        ("森林", "shinrin", "hutan"),
        ("山林", "sanrin", "hutan gunung"),
    ], [
        ("林の中を歩きました。", "Hayashi no naka o arukimashita.", "Saya berjalan di dalam hutan kecil."),
        ("この山は森林が多いです。", "Kono yama wa shinrin ga ooi desu.", "Gunung ini banyak hutannya."),
    ]),
    ("mori", "森", ["シン"], ["もり"], ["hutan", "forest"], 12, "木", [
        ("森", "mori", "hutan"),
        ("森林", "shinrin", "hutan"),
        ("深い森", "fukai mori", "hutan yang dalam"),
    ], [
        ("森の中で鳥の声が聞こえます。", "Mori no naka de tori no koe ga kikoemasu.", "Terdengar suara burung di dalam hutan."),
        ("この森はとても静かです。", "Kono mori wa totemo shizuka desu.", "Hutan ini sangat sunyi."),
    ]),
    ("ta", "田", ["デン"], ["た"], ["sawah", "ladang", "rice field"], 5, "田", [
        ("田んぼ", "tanbo", "sawah"),
        ("水田", "suiden", "sawah berair"),
        ("田植え", "taue", "menanam padi"),
    ], [
        ("田んぼで米を作ります。", "Tanbo de kome o tsukurimasu.", "Menanam padi di sawah."),
        ("祖父は田んぼで働いています。", "Sofu wa tanbo de hataraite imasu.", "Kakek saya bekerja di sawah."),
    ]),
    ("hi2", "火", ["カ"], ["ひ"], ["api", "fire"], 4, "火", [
        ("火曜日", "kayoubi", "hari Selasa"),
        ("火", "hi", "api"),
        ("花火", "hanabi", "kembang api"),
    ], [
        ("火曜日に病院へ行きます。", "Kayoubi ni byouin e ikimasu.", "Hari Selasa saya pergi ke rumah sakit."),
        ("夏に花火を見ました。", "Natsu ni hanabi o mimashita.", "Musim panas saya melihat kembang api."),
    ]),
    ("mizu", "水", ["スイ"], ["みず"], ["air", "water"], 4, "水", [
        ("水曜日", "suiyoubi", "hari Rabu"),
        ("水", "mizu", "air"),
        ("水泳", "suiei", "berenang"),
    ], [
        ("水を飲みます。", "Mizu o nomimasu.", "Saya minum air."),
        ("水曜日にテストがあります。", "Suiyoubi ni tesuto ga arimasu.", "Hari Rabu ada tes."),
    ]),
    ("tsuchi", "土", ["ド", "ト"], ["つち"], ["tanah", "bumi", "earth", "soil"], 3, "土", [
        ("土曜日", "doyoubi", "hari Sabtu"),
        ("土", "tsuchi", "tanah"),
        ("土地", "tochi", "lahan/tanah"),
    ], [
        ("土曜日は休みです。", "Doyoubi wa yasumi desu.", "Hari Sabtu libur."),
        ("花に土をあげました。", "Hana ni tsuchi o agemashita.", "Saya memberi tanah untuk bunga."),
    ]),
    ("sora", "空", ["クウ"], ["そら", "から", "あ-く"], ["langit", "kosong", "sky", "empty"], 8, "穴", [
        ("空", "sora", "langit"),
        ("空気", "kuuki", "udara"),
        ("空港", "kuukou", "bandara"),
    ], [
        ("空が青いです。", "Sora ga aoi desu.", "Langit biru."),
        ("空港まで電車で行きます。", "Kuukou made densha de ikimasu.", "Saya pergi ke bandara naik kereta."),
    ]),
    ("ki2", "気", ["キ", "ケ"], [], ["semangat", "udara", "spirit", "energy", "feeling"], 6, "气", [
        ("元気", "genki", "sehat/semangat"),
        ("天気", "tenki", "cuaca"),
        ("気持ち", "kimochi", "perasaan"),
    ], [
        ("元気ですか。", "Genki desu ka.", "Apa kabar?"),
        ("今日の天気はいいです。", "Kyou no tenki wa ii desu.", "Cuaca hari ini bagus."),
    ]),
    ("ame", "雨", ["ウ"], ["あめ"], ["hujan", "rain"], 8, "雨", [
        ("雨", "ame", "hujan"),
        ("大雨", "ooame", "hujan lebat"),
        ("雨天", "uten", "cuaca hujan"),
    ], [
        ("今日は雨です。", "Kyou wa ame desu.", "Hari ini hujan."),
        ("明日は雨が降るでしょう。", "Ashita wa ame ga furu deshou.", "Besok mungkin akan hujan."),
    ]),
    ("ishi", "石", ["セキ", "シャク"], ["いし"], ["batu", "stone"], 5, "石", [
        ("石", "ishi", "batu"),
        ("石鹸", "sekken", "sabun"),
        ("宝石", "houseki", "batu permata"),
    ], [
        ("川で石を拾いました。", "Kawa de ishi o hiroimashita.", "Saya memungut batu di sungai."),
        ("これは宝石です。", "Kore wa houseki desu.", "Ini adalah batu permata."),
    ]),
    ("hana", "花", ["カ"], ["はな"], ["bunga", "flower"], 7, "艹", [
        ("花", "hana", "bunga"),
        ("花見", "hanami", "melihat bunga sakura"),
        ("花瓶", "kabin", "vas bunga"),
    ], [
        ("花がきれいです。", "Hana ga kirei desu.", "Bunganya indah."),
        ("春に花見をします。", "Haru ni hanami o shimasu.", "Musim semi kami melihat bunga sakura."),
    ]),
    # --- Batch B: 子女男名前学生先友私父母 + 目口手足 + 上下中外左右後東西南北
    #     + 行来食飲見聞読書話買売立休入出会 (43) ---
    ("ko", "子", ["シ", "ス"], ["こ"], ["anak", "child"], 3, "子", [
        ("子供", "kodomo", "anak"),
        ("女の子", "onnanoko", "anak perempuan"),
        ("男の子", "otokonoko", "anak laki-laki"),
    ], [
        ("子供が公園で遊んでいます。", "Kodomo ga kouen de asonde imasu.", "Anak-anak bermain di taman."),
        ("この子は私の娘です。", "Kono ko wa watashi no musume desu.", "Anak ini adalah putri saya."),
    ]),
    ("onna", "女", ["ジョ", "ニョ"], ["おんな"], ["perempuan", "wanita", "woman"], 3, "女", [
        ("女性", "josei", "wanita"),
        ("女の子", "onnanoko", "anak perempuan"),
        ("彼女", "kanojo", "dia (perempuan)/pacar"),
    ], [
        ("あの女性は先生です。", "Ano josei wa sensei desu.", "Wanita itu adalah guru."),
        ("彼女はとても優しいです。", "Kanojo wa totemo yasashii desu.", "Dia (perempuan) sangat baik."),
    ]),
    ("otoko", "男", ["ダン", "ナン"], ["おとこ"], ["laki-laki", "pria", "man"], 7, "田", [
        ("男性", "dansei", "pria"),
        ("男の子", "otokonoko", "anak laki-laki"),
        ("長男", "chounan", "anak laki-laki tertua"),
    ], [
        ("あの男性は医者です。", "Ano dansei wa isha desu.", "Pria itu adalah dokter."),
        ("彼は長男です。", "Kare wa chounan desu.", "Dia adalah anak laki-laki tertua."),
    ]),
    ("na", "名", ["メイ", "ミョウ"], ["な"], ["nama", "name"], 6, "口", [
        ("名前", "namae", "nama"),
        ("有名", "yuumei", "terkenal"),
        ("名字", "myouji", "nama keluarga"),
    ], [
        ("お名前は何ですか。", "Onamae wa nan desu ka.", "Siapa nama Anda?"),
        ("彼は有名な歌手です。", "Kare wa yuumei na kashu desu.", "Dia penyanyi terkenal."),
    ]),
    ("mae", "前", ["ゼン"], ["まえ"], ["depan", "sebelum", "front", "before"], 9, "刂", [
        ("名前", "namae", "nama"),
        ("前", "mae", "depan/sebelum"),
        ("午前", "gozen", "pagi/AM"),
    ], [
        ("駅の前で待っています。", "Eki no mae de matte imasu.", "Saya menunggu di depan stasiun."),
        ("午前中に電話します。", "Gozenchuu ni denwa shimasu.", "Saya akan menelepon pada pagi hari."),
    ]),
    ("gaku", "学", ["ガク"], ["まな-ぶ"], ["belajar", "ilmu", "study", "learning"], 8, "子", [
        ("学校", "gakkou", "sekolah"),
        ("学生", "gakusei", "siswa/mahasiswa"),
        ("大学", "daigaku", "universitas"),
    ], [
        ("大学で経済を学んでいます。", "Daigaku de keizai o manande imasu.", "Saya belajar ekonomi di universitas."),
        ("毎日学校へ行きます。", "Mainichi gakkou e ikimasu.", "Setiap hari saya pergi ke sekolah."),
    ]),
    ("sei", "生", ["セイ", "ショウ"], ["い-きる", "う-まれる", "なま"], ["hidup", "lahir", "murni", "life", "birth", "raw"], 5, "生", [
        ("学生", "gakusei", "siswa/mahasiswa"),
        ("先生", "sensei", "guru"),
        ("生まれる", "umareru", "lahir"),
    ], [
        ("私は大学生です。", "Watashi wa daigakusei desu.", "Saya mahasiswa."),
        ("東京で生まれました。", "Toukyou de umaremashita.", "Saya lahir di Tokyo."),
    ]),
    ("saki", "先", ["セン"], ["さき"], ["sebelumnya", "ujung", "terlebih dahulu", "ahead", "previous"], 6, "儿", [
        ("先生", "sensei", "guru"),
        ("先週", "senshuu", "minggu lalu"),
        ("先に", "sakini", "lebih dahulu"),
    ], [
        ("先週、京都へ行きました。", "Senshuu, Kyouto e ikimashita.", "Minggu lalu, saya pergi ke Kyoto."),
        ("お先にどうぞ。", "Osaki ni douzo.", "Silakan duluan."),
    ]),
    ("tomo", "友", ["ユウ"], ["とも"], ["teman", "friend"], 4, "又", [
        ("友達", "tomodachi", "teman"),
        ("親友", "shinyuu", "sahabat"),
        ("友人", "yuujin", "teman (formal)"),
    ], [
        ("友達と映画を見ました。", "Tomodachi to eiga o mimashita.", "Saya menonton film dengan teman."),
        ("彼女は私の親友です。", "Kanojo wa watashi no shinyuu desu.", "Dia adalah sahabat saya."),
    ]),
    ("watashi", "私", ["シ"], ["わたし", "わたくし"], ["saya", "pribadi", "I", "private"], 7, "禾", [
        ("私", "watashi", "saya"),
        ("私立", "shiritsu", "swasta"),
        ("私達", "watashitachi", "kami/kita"),
    ], [
        ("私は学生です。", "Watashi wa gakusei desu.", "Saya adalah siswa."),
        ("私達は友達です。", "Watashitachi wa tomodachi desu.", "Kami adalah teman."),
    ]),
    ("chichi", "父", ["フ"], ["ちち"], ["ayah", "father"], 4, "父", [
        ("父", "chichi", "ayah (saya)"),
        ("お父さん", "otousan", "ayah (umum/panggilan)"),
        ("父親", "chichioya", "ayah"),
    ], [
        ("私の父は医者です。", "Watashi no chichi wa isha desu.", "Ayah saya adalah dokter."),
        ("お父さんは元気ですか。", "Otousan wa genki desu ka.", "Apakah ayah (Anda) sehat?"),
    ]),
    ("haha", "母", ["ボ"], ["はは"], ["ibu", "mother"], 5, "母", [
        ("母", "haha", "ibu (saya)"),
        ("お母さん", "okaasan", "ibu (umum/panggilan)"),
        ("母国", "bokoku", "tanah air"),
    ], [
        ("私の母は料理が上手です。", "Watashi no haha wa ryouri ga jouzu desu.", "Ibu saya pandai memasak."),
        ("お母さんによろしく。", "Okaasan ni yoroshiku.", "Salam untuk ibu (Anda)."),
    ]),
    ("me", "目", ["モク", "ボク"], ["め"], ["mata", "eye"], 5, "目", [
        ("目", "me", "mata"),
        ("目的", "mokuteki", "tujuan"),
        ("一つ目", "hitotsume", "yang pertama"),
    ], [
        ("目が痛いです。", "Me ga itai desu.", "Mata saya sakit."),
        ("旅行の目的は何ですか。", "Ryokou no mokuteki wa nan desu ka.", "Apa tujuan perjalanan Anda?"),
    ]),
    ("kuchi", "口", ["コウ", "ク"], ["くち"], ["mulut", "mouth"], 3, "口", [
        ("口", "kuchi", "mulut"),
        ("入り口", "iriguchi", "pintu masuk"),
        ("人口", "jinkou", "populasi"),
    ], [
        ("口を開けてください。", "Kuchi o akete kudasai.", "Tolong buka mulut Anda."),
        ("この町の人口は多いです。", "Kono machi no jinkou wa ooi desu.", "Populasi kota ini banyak."),
    ]),
    ("te", "手", ["シュ"], ["て"], ["tangan", "hand"], 4, "手", [
        ("手", "te", "tangan"),
        ("上手", "jouzu", "pandai/mahir"),
        ("手紙", "tegami", "surat"),
    ], [
        ("手を洗ってください。", "Te o aratte kudasai.", "Tolong cuci tangan."),
        ("友達に手紙を書きました。", "Tomodachi ni tegami o kakimashita.", "Saya menulis surat untuk teman."),
    ]),
    ("ashi", "足", ["ソク"], ["あし", "た-りる"], ["kaki", "cukup", "foot", "leg", "sufficient"], 7, "足", [
        ("足", "ashi", "kaki"),
        ("足りる", "tariru", "cukup"),
        ("一足", "issoku", "satu pasang (sepatu)"),
    ], [
        ("足が痛いです。", "Ashi ga itai desu.", "Kaki saya sakit."),
        ("お金が足りません。", "Okane ga tarimasen.", "Uangnya tidak cukup."),
    ]),
    ("ue", "上", ["ジョウ"], ["うえ", "あ-げる", "のぼ-る"], ["atas", "naik", "up", "above"], 3, "一", [
        ("上", "ue", "atas"),
        ("上手", "jouzu", "pandai"),
        ("屋上", "okujou", "atap gedung"),
    ], [
        ("机の上に本があります。", "Tsukue no ue ni hon ga arimasu.", "Ada buku di atas meja."),
        ("エレベーターで屋上に行きます。", "Erebeetaa de okujou ni ikimasu.", "Saya pergi ke atap gedung naik lift."),
    ]),
    ("shita", "下", ["カ", "ゲ"], ["した", "さ-げる", "くだ-さる"], ["bawah", "turun", "down", "below"], 3, "一", [
        ("下", "shita", "bawah"),
        ("下手", "heta", "tidak pandai"),
        ("地下", "chika", "bawah tanah"),
    ], [
        ("椅子の下に猫がいます。", "Isu no shita ni neko ga imasu.", "Ada kucing di bawah kursi."),
        ("地下にレストランがあります。", "Chika ni resutoran ga arimasu.", "Ada restoran di bawah tanah."),
    ]),
    ("naka", "中", ["チュウ"], ["なか"], ["tengah", "dalam", "middle", "inside"], 4, "丨", [
        ("中", "naka", "dalam/tengah"),
        ("中国", "chuugoku", "Tiongkok"),
        ("一日中", "ichinichijuu", "sepanjang hari"),
    ], [
        ("かばんの中に本があります。", "Kaban no naka ni hon ga arimasu.", "Ada buku di dalam tas."),
        ("彼は中国語を話します。", "Kare wa chuugokugo o hanashimasu.", "Dia berbicara bahasa Mandarin."),
    ]),
    ("soto", "外", ["ガイ", "ゲ"], ["そと", "ほか"], ["luar", "outside"], 5, "夕", [
        ("外", "soto", "luar"),
        ("外国", "gaikoku", "luar negeri"),
        ("外国人", "gaikokujin", "orang asing"),
    ], [
        ("外は寒いです。", "Soto wa samui desu.", "Di luar dingin."),
        ("彼女は外国人です。", "Kanojo wa gaikokujin desu.", "Dia orang asing."),
    ]),
    ("hidari", "左", ["サ"], ["ひだり"], ["kiri", "left"], 5, "工", [
        ("左", "hidari", "kiri"),
        ("左手", "hidarite", "tangan kiri"),
        ("左側", "hidarigawa", "sisi kiri"),
    ], [
        ("左に曲がってください。", "Hidari ni magatte kudasai.", "Tolong belok kiri."),
        ("銀行は左側にあります。", "Ginkou wa hidarigawa ni arimasu.", "Bank ada di sisi kiri."),
    ]),
    ("migi", "右", ["ウ", "ユウ"], ["みぎ"], ["kanan", "right"], 5, "口", [
        ("右", "migi", "kanan"),
        ("右手", "migite", "tangan kanan"),
        ("右側", "migigawa", "sisi kanan"),
    ], [
        ("右に曲がってください。", "Migi ni magatte kudasai.", "Tolong belok kanan."),
        ("郵便局は右側にあります。", "Yuubinkyoku wa migigawa ni arimasu.", "Kantor pos ada di sisi kanan."),
    ]),
    ("ato", "後", ["ゴ", "コウ"], ["あと", "うし-ろ", "のち"], ["setelah", "belakang", "after", "behind"], 9, "彳", [
        ("後で", "atode", "nanti"),
        ("午後", "gogo", "siang/PM"),
        ("後ろ", "ushiro", "belakang"),
    ], [
        ("後で電話します。", "Atode denwa shimasu.", "Saya akan menelepon nanti."),
        ("午後、会議があります。", "Gogo, kaigi ga arimasu.", "Siang ini ada rapat."),
    ]),
    ("higashi", "東", ["トウ"], ["ひがし"], ["timur", "east"], 8, "木", [
        ("東", "higashi", "timur"),
        ("東京", "toukyou", "Tokyo"),
        ("東口", "higashiguchi", "pintu keluar timur"),
    ], [
        ("太陽は東から昇ります。", "Taiyou wa higashi kara noborimasu.", "Matahari terbit dari timur."),
        ("東京に住んでいます。", "Toukyou ni sunde imasu.", "Saya tinggal di Tokyo."),
    ]),
    ("nishi", "西", ["セイ", "サイ"], ["にし"], ["barat", "west"], 6, "西", [
        ("西", "nishi", "barat"),
        ("西口", "nishiguchi", "pintu keluar barat"),
        ("関西", "kansai", "wilayah Kansai"),
    ], [
        ("太陽は西に沈みます。", "Taiyou wa nishi ni shizumimasu.", "Matahari terbenam ke arah barat."),
        ("関西に旅行しました。", "Kansai ni ryokou shimashita.", "Saya bepergian ke Kansai."),
    ]),
    ("minami", "南", ["ナン"], ["みなみ"], ["selatan", "south"], 9, "十", [
        ("南", "minami", "selatan"),
        ("南口", "minamiguchi", "pintu keluar selatan"),
        ("南国", "nangoku", "negeri tropis"),
    ], [
        ("南へ旅行します。", "Minami e ryokou shimasu.", "Saya bepergian ke selatan."),
        ("南口で待っています。", "Minamiguchi de matte imasu.", "Saya menunggu di pintu keluar selatan."),
    ]),
    ("kita", "北", ["ホク"], ["きた"], ["utara", "north"], 5, "匕", [
        ("北", "kita", "utara"),
        ("北海道", "hokkaidou", "Hokkaido"),
        ("北口", "kitaguchi", "pintu keluar utara"),
    ], [
        ("北海道は寒いです。", "Hokkaidou wa samui desu.", "Hokkaido dingin."),
        ("北口で会いましょう。", "Kitaguchi de aimashou.", "Ayo bertemu di pintu keluar utara."),
    ]),
    ("iku", "行", ["コウ", "ギョウ"], ["い-く", "おこな-う"], ["pergi", "melaksanakan", "go", "carry out"], 6, "行", [
        ("行く", "iku", "pergi"),
        ("銀行", "ginkou", "bank"),
        ("旅行", "ryokou", "perjalanan"),
    ], [
        ("学校へ行きます。", "Gakkou e ikimasu.", "Saya pergi ke sekolah."),
        ("銀行でお金をおろします。", "Ginkou de okane o oroshimasu.", "Saya mengambil uang di bank."),
    ]),
    ("kuru", "来", ["ライ"], ["く-る", "きた-る"], ["datang", "come"], 7, "木", [
        ("来る", "kuru", "datang"),
        ("来年", "rainen", "tahun depan"),
        ("来週", "raishuu", "minggu depan"),
    ], [
        ("友達が家に来ます。", "Tomodachi ga ie ni kimasu.", "Teman saya akan datang ke rumah."),
        ("来週、テストがあります。", "Raishuu, tesuto ga arimasu.", "Minggu depan ada tes."),
    ]),
    ("taberu", "食", ["ショク"], ["た-べる", "く-う"], ["makan", "makanan", "eat", "food"], 9, "食", [
        ("食べる", "taberu", "makan"),
        ("食事", "shokuji", "makan/santap"),
        ("朝食", "choushoku", "sarapan"),
    ], [
        ("朝ごはんを食べました。", "Asagohan o tabemashita.", "Saya sudah makan sarapan."),
        ("家族と食事します。", "Kazoku to shokuji shimasu.", "Saya makan bersama keluarga."),
    ]),
    ("nomu", "飲", ["イン"], ["の-む"], ["minum", "drink"], 12, "食", [
        ("飲む", "nomu", "minum"),
        ("飲み物", "nomimono", "minuman"),
        ("飲食店", "inshokuten", "restoran/kedai makan"),
    ], [
        ("水を飲みます。", "Mizu o nomimasu.", "Saya minum air."),
        ("何か飲み物はいかがですか。", "Nanika nomimono wa ikaga desu ka.", "Mau minum sesuatu?"),
    ]),
    ("miru", "見", ["ケン"], ["み-る", "み-える"], ["melihat", "see", "look"], 7, "見", [
        ("見る", "miru", "melihat"),
        ("見学", "kengaku", "kunjungan belajar"),
        ("意見", "iken", "pendapat"),
    ], [
        ("映画を見ます。", "Eiga o mimasu.", "Saya menonton film."),
        ("あなたの意見を聞きたいです。", "Anata no iken o kikitai desu.", "Saya ingin mendengar pendapat Anda."),
    ]),
    ("kiku", "聞", ["ブン", "モン"], ["き-く", "き-こえる"], ["mendengar", "bertanya", "hear", "ask"], 14, "耳", [
        ("聞く", "kiku", "mendengar/bertanya"),
        ("新聞", "shinbun", "koran"),
        ("聞こえる", "kikoeru", "terdengar"),
    ], [
        ("音楽を聞きます。", "Ongaku o kikimasu.", "Saya mendengarkan musik."),
        ("毎朝新聞を読みます。", "Maiasa shinbun o yomimasu.", "Setiap pagi saya membaca koran."),
    ]),
    ("yomu", "読", ["ドク", "トウ"], ["よ-む"], ["membaca", "read"], 14, "言", [
        ("読む", "yomu", "membaca"),
        ("読書", "dokusho", "membaca buku"),
        ("音読", "ondoku", "membaca nyaring"),
    ], [
        ("本を読みます。", "Hon o yomimasu.", "Saya membaca buku."),
        ("読書が好きです。", "Dokusho ga suki desu.", "Saya suka membaca."),
    ]),
    ("kaku", "書", ["ショ"], ["か-く"], ["menulis", "tulisan", "write", "book"], 10, "曰", [
        ("書く", "kaku", "menulis"),
        ("辞書", "jisho", "kamus"),
        ("図書館", "toshokan", "perpustakaan"),
    ], [
        ("手紙を書きます。", "Tegami o kakimasu.", "Saya menulis surat."),
        ("図書館で勉強します。", "Toshokan de benkyou shimasu.", "Saya belajar di perpustakaan."),
    ]),
    ("hanasu", "話", ["ワ"], ["はな-す", "はなし"], ["berbicara", "cerita", "talk", "story"], 13, "言", [
        ("話す", "hanasu", "berbicara"),
        ("電話", "denwa", "telepon"),
        ("会話", "kaiwa", "percakapan"),
    ], [
        ("日本語を話します。", "Nihongo o hanashimasu.", "Saya berbicara bahasa Jepang."),
        ("友達と電話しました。", "Tomodachi to denwa shimashita.", "Saya menelepon dengan teman."),
    ]),
    ("kau", "買", ["バイ"], ["か-う"], ["membeli", "buy"], 12, "貝", [
        ("買う", "kau", "membeli"),
        ("買い物", "kaimono", "belanja"),
        ("購買", "koubai", "pembelian"),
    ], [
        ("果物を買います。", "Kudamono o kaimasu.", "Saya membeli buah."),
        ("週末に買い物をします。", "Shuumatsu ni kaimono o shimasu.", "Akhir pekan saya berbelanja."),
    ]),
    ("uru", "売", ["バイ"], ["う-る"], ["menjual", "sell"], 7, "士", [
        ("売る", "uru", "menjual"),
        ("発売", "hatsubai", "peluncuran penjualan"),
        ("売店", "baiten", "kios"),
    ], [
        ("この店で野菜を売っています。", "Kono mise de yasai o utte imasu.", "Toko ini menjual sayuran."),
        ("新しい本が発売されました。", "Atarashii hon ga hatsubai saremashita.", "Buku baru sudah dirilis."),
    ]),
    ("tatsu", "立", ["リツ"], ["た-つ", "た-てる"], ["berdiri", "mendirikan", "stand", "establish"], 5, "立", [
        ("立つ", "tatsu", "berdiri"),
        ("国立", "kokuritsu", "negeri"),
        ("立派", "rippa", "megah/hebat"),
    ], [
        ("電車の中で立っています。", "Densha no naka de tatte imasu.", "Saya berdiri di dalam kereta."),
        ("これは国立大学です。", "Kore wa kokuritsu daigaku desu.", "Ini adalah universitas negeri."),
    ]),
    ("yasumu", "休", ["キュウ"], ["やす-む"], ["istirahat", "libur", "rest", "holiday"], 6, "人", [
        ("休む", "yasumu", "beristirahat"),
        ("休み", "yasumi", "libur"),
        ("休日", "kyuujitsu", "hari libur"),
    ], [
        ("今日は家で休みます。", "Kyou wa ie de yasumimasu.", "Hari ini saya beristirahat di rumah."),
        ("夏休みはいつですか。", "Natsuyasumi wa itsu desu ka.", "Kapan libur musim panas?"),
    ]),
    ("hairu", "入", ["ニュウ"], ["い-る", "はい-る"], ["masuk", "enter"], 2, "入", [
        ("入る", "hairu", "masuk"),
        ("入学", "nyuugaku", "masuk sekolah"),
        ("入り口", "iriguchi", "pintu masuk"),
    ], [
        ("部屋に入ります。", "Heya ni hairimasu.", "Saya masuk ke kamar."),
        ("来月、大学に入学します。", "Raigetsu, daigaku ni nyuugaku shimasu.", "Bulan depan, saya masuk universitas."),
    ]),
    ("deru", "出", ["シュツ", "スイ"], ["で-る", "だ-す"], ["keluar", "mengeluarkan", "exit", "go out"], 5, "凵", [
        ("出る", "deru", "keluar"),
        ("出口", "deguchi", "pintu keluar"),
        ("出発", "shuppatsu", "keberangkatan"),
    ], [
        ("七時に家を出ます。", "Shichiji ni ie o demasu.", "Saya keluar rumah jam tujuh."),
        ("出口はどこですか。", "Deguchi wa doko desu ka.", "Di mana pintu keluar?"),
    ]),
    ("au", "会", ["カイ", "エ"], ["あ-う"], ["bertemu", "pertemuan", "meet", "meeting"], 6, "人", [
        ("会う", "au", "bertemu"),
        ("会議", "kaigi", "rapat"),
        ("会社", "kaisha", "perusahaan"),
    ], [
        ("友達に会います。", "Tomodachi ni aimasu.", "Saya bertemu teman."),
        ("父は会社で働いています。", "Chichi wa kaisha de hataraite imasu.", "Ayah saya bekerja di perusahaan."),
    ]),
    # --- Batch C: 校語文字本 + 国町村駅店家 + 大小多少高安新古長白 + 何車電道 (25) ---
    ("kou", "校", ["コウ"], [], ["sekolah", "school"], 10, "木", [
        ("学校", "gakkou", "sekolah"),
        ("校長", "kouchou", "kepala sekolah"),
        ("高校", "koukou", "SMA"),
    ], [
        ("学校は九時に始まります。", "Gakkou wa kuji ni hajimarimasu.", "Sekolah mulai jam sembilan."),
        ("高校で英語を勉強しました。", "Koukou de eigo o benkyou shimashita.", "Saya belajar bahasa Inggris di SMA."),
    ]),
    ("go2", "語", ["ゴ"], ["かた-る"], ["bahasa", "berbicara", "language"], 14, "言", [
        ("日本語", "nihongo", "bahasa Jepang"),
        ("英語", "eigo", "bahasa Inggris"),
        ("単語", "tango", "kosakata"),
    ], [
        ("日本語を勉強しています。", "Nihongo o benkyou shite imasu.", "Saya sedang belajar bahasa Jepang."),
        ("毎日単語を覚えます。", "Mainichi tango o oboemasu.", "Setiap hari saya menghafal kosakata."),
    ]),
    ("bun", "文", ["ブン", "モン"], ["ふみ"], ["kalimat", "tulisan", "sentence", "writing"], 4, "文", [
        ("文章", "bunshou", "tulisan/karangan"),
        ("文法", "bunpou", "tata bahasa"),
        ("作文", "sakubun", "karangan/esai"),
    ], [
        ("文法を勉強します。", "Bunpou o benkyou shimasu.", "Saya belajar tata bahasa."),
        ("作文を書きました。", "Sakubun o kakimashita.", "Saya menulis karangan."),
    ]),
    ("ji2", "字", ["ジ"], ["あざ"], ["huruf", "karakter", "character", "letter"], 6, "子", [
        ("漢字", "kanji", "kanji/karakter Han"),
        ("文字", "moji", "huruf/karakter"),
        ("字", "ji", "huruf"),
    ], [
        ("漢字を勉強しています。", "Kanji o benkyou shite imasu.", "Saya sedang belajar kanji."),
        ("この字は難しいです。", "Kono ji wa muzukashii desu.", "Huruf ini sulit."),
    ]),
    ("hon", "本", ["ホン"], ["もと"], ["buku", "asal", "pokok", "book", "origin"], 5, "木", [
        ("本", "hon", "buku"),
        ("日本", "nihon", "Jepang"),
        ("本当", "hontou", "benar/sungguh"),
    ], [
        ("図書館で本を借りました。", "Toshokan de hon o karimashita.", "Saya meminjam buku di perpustakaan."),
        ("それは本当ですか。", "Sore wa hontou desu ka.", "Apakah itu benar?"),
    ]),
    ("kuni", "国", ["コク"], ["くに"], ["negara", "country"], 8, "囗", [
        ("国", "kuni", "negara"),
        ("外国", "gaikoku", "luar negeri"),
        ("中国", "chuugoku", "Tiongkok"),
    ], [
        ("私の国はインドネシアです。", "Watashi no kuni wa Indoneshia desu.", "Negara saya adalah Indonesia."),
        ("外国へ旅行したいです。", "Gaikoku e ryokou shitai desu.", "Saya ingin bepergian ke luar negeri."),
    ]),
    ("machi", "町", ["チョウ"], ["まち"], ["kota kecil", "town"], 7, "田", [
        ("町", "machi", "kota kecil"),
        ("下町", "shitamachi", "kota bawah/kota tua"),
        ("町長", "chouchou", "kepala kota kecil"),
    ], [
        ("この町は静かです。", "Kono machi wa shizuka desu.", "Kota kecil ini tenang."),
        ("下町を散歩しました。", "Shitamachi o sanpo shimashita.", "Saya berjalan-jalan di kota tua."),
    ]),
    ("mura", "村", ["ソン"], ["むら"], ["desa", "village"], 7, "木", [
        ("村", "mura", "desa"),
        ("農村", "nouson", "desa pertanian"),
        ("村人", "murabito", "penduduk desa"),
    ], [
        ("祖父母は村に住んでいます。", "Sofubo wa mura ni sunde imasu.", "Kakek-nenek saya tinggal di desa."),
        ("この村はとても美しいです。", "Kono mura wa totemo utsukushii desu.", "Desa ini sangat indah."),
    ]),
    ("eki", "駅", ["エキ"], [], ["stasiun", "station"], 14, "馬", [
        ("駅", "eki", "stasiun"),
        ("駅員", "ekiin", "petugas stasiun"),
        ("駅前", "ekimae", "depan stasiun"),
    ], [
        ("駅まで歩きます。", "Eki made arukimasu.", "Saya berjalan kaki sampai stasiun."),
        ("駅前で待ち合わせましょう。", "Ekimae de machiawasemashou.", "Ayo bertemu di depan stasiun."),
    ]),
    ("mise", "店", ["テン"], ["みせ"], ["toko", "shop", "store"], 8, "广", [
        ("店", "mise", "toko"),
        ("店員", "ten'in", "pegawai toko"),
        ("喫茶店", "kissaten", "kedai kopi"),
    ], [
        ("あの店でパンを買いました。", "Ano mise de pan o kaimashita.", "Saya membeli roti di toko itu."),
        ("喫茶店でコーヒーを飲みました。", "Kissaten de koohii o nomimashita.", "Saya minum kopi di kedai kopi."),
    ]),
    ("ie", "家", ["カ", "ケ"], ["いえ", "うち"], ["rumah", "keluarga", "house", "family"], 10, "宀", [
        ("家", "ie", "rumah"),
        ("家族", "kazoku", "keluarga"),
        ("家庭", "katei", "rumah tangga"),
    ], [
        ("家で勉強します。", "Ie de benkyou shimasu.", "Saya belajar di rumah."),
        ("家族と一緒に住んでいます。", "Kazoku to issho ni sunde imasu.", "Saya tinggal bersama keluarga."),
    ]),
    ("ookii", "大", ["ダイ", "タイ"], ["おお", "おお-きい"], ["besar", "big", "large"], 3, "大", [
        ("大きい", "ookii", "besar"),
        ("大学", "daigaku", "universitas"),
        ("大切", "taisetsu", "penting"),
    ], [
        ("この犬は大きいです。", "Kono inu wa ookii desu.", "Anjing ini besar."),
        ("家族は私にとって大切です。", "Kazoku wa watashi ni totte taisetsu desu.", "Keluarga penting bagi saya."),
    ]),
    ("chiisai", "小", ["ショウ"], ["ちい-さい", "こ", "お"], ["kecil", "small"], 3, "小", [
        ("小さい", "chiisai", "kecil"),
        ("小学校", "shougakkou", "SD"),
        ("小説", "shousetsu", "novel"),
    ], [
        ("この部屋は小さいです。", "Kono heya wa chiisai desu.", "Kamar ini kecil."),
        ("小説を読むのが好きです。", "Shousetsu o yomu no ga suki desu.", "Saya suka membaca novel."),
    ]),
    ("ooi", "多", ["タ"], ["おお-い"], ["banyak", "many"], 6, "夕", [
        ("多い", "ooi", "banyak"),
        ("多分", "tabun", "mungkin"),
        ("多数", "tasuu", "banyak jumlah"),
    ], [
        ("この町は人が多いです。", "Kono machi wa hito ga ooi desu.", "Kota ini banyak orangnya."),
        ("多分、明日雨が降ります。", "Tabun, ashita ame ga furimasu.", "Mungkin besok akan hujan."),
    ]),
    ("sukunai", "少", ["ショウ"], ["すく-ない", "すこ-し"], ["sedikit", "few", "little"], 4, "小", [
        ("少ない", "sukunai", "sedikit"),
        ("少し", "sukoshi", "sedikit/agak"),
        ("少年", "shounen", "anak laki-laki/bocah"),
    ], [
        ("お金が少ないです。", "Okane ga sukunai desu.", "Uangnya sedikit."),
        ("少し待ってください。", "Sukoshi matte kudasai.", "Tolong tunggu sebentar."),
    ]),
    ("takai", "高", ["コウ"], ["たか-い"], ["tinggi", "mahal", "tall", "expensive"], 10, "高", [
        ("高い", "takai", "tinggi/mahal"),
        ("高校", "koukou", "SMA"),
        ("高速", "kousoku", "kecepatan tinggi"),
    ], [
        ("この時計は高いです。", "Kono tokei wa takai desu.", "Jam ini mahal."),
        ("高校生です。", "Koukousei desu.", "Saya siswa SMA."),
    ]),
    ("yasui", "安", ["アン"], ["やす-い"], ["murah", "aman", "cheap", "safe"], 6, "宀", [
        ("安い", "yasui", "murah"),
        ("安全", "anzen", "aman"),
        ("不安", "fuan", "khawatir/cemas"),
    ], [
        ("このレストランは安いです。", "Kono resutoran wa yasui desu.", "Restoran ini murah."),
        ("安全運転をしてください。", "Anzen unten o shite kudasai.", "Tolong berkendara dengan aman."),
    ]),
    ("atarashii", "新", ["シン"], ["あたら-しい", "あら-た"], ["baru", "new"], 13, "斤", [
        ("新しい", "atarashii", "baru"),
        ("新聞", "shinbun", "koran"),
        ("新年", "shinnen", "tahun baru"),
    ], [
        ("新しいかばんを買いました。", "Atarashii kaban o kaimashita.", "Saya membeli tas baru."),
        ("新年おめでとうございます。", "Shinnen omedetou gozaimasu.", "Selamat tahun baru."),
    ]),
    ("furui", "古", ["コ"], ["ふる-い"], ["tua", "lama", "old"], 5, "口", [
        ("古い", "furui", "tua/lama"),
        ("中古", "chuuko", "bekas"),
        ("古本", "furuhon", "buku bekas"),
    ], [
        ("これは古い家です。", "Kore wa furui ie desu.", "Ini adalah rumah tua."),
        ("中古の車を買いました。", "Chuuko no kuruma o kaimashita.", "Saya membeli mobil bekas."),
    ]),
    ("nagai", "長", ["チョウ"], ["なが-い"], ["panjang", "kepala/pemimpin", "long", "chief"], 8, "長", [
        ("長い", "nagai", "panjang"),
        ("社長", "shachou", "presiden direktur"),
        ("校長", "kouchou", "kepala sekolah"),
    ], [
        ("髪が長いです。", "Kami ga nagai desu.", "Rambutnya panjang."),
        ("彼は会社の社長です。", "Kare wa kaisha no shachou desu.", "Dia presiden direktur perusahaan."),
    ]),
    ("shiro", "白", ["ハク", "ビャク"], ["しろ", "しろ-い"], ["putih", "white"], 5, "白", [
        ("白い", "shiroi", "putih"),
        ("白", "shiro", "warna putih"),
        ("面白い", "omoshiroi", "menarik/lucu"),
    ], [
        ("雪は白いです。", "Yuki wa shiroi desu.", "Salju berwarna putih."),
        ("この映画は面白いです。", "Kono eiga wa omoshiroi desu.", "Film ini menarik."),
    ]),
    ("nani", "何", ["カ"], ["なに", "なん"], ["apa", "what"], 7, "人", [
        ("何", "nani", "apa"),
        ("何時", "nanji", "jam berapa"),
        ("何人", "nannin", "berapa orang"),
    ], [
        ("これは何ですか。", "Kore wa nan desu ka.", "Ini apa?"),
        ("何時に会いましょうか。", "Nanji ni aimashou ka.", "Jam berapa kita bertemu?"),
    ]),
    ("kuruma", "車", ["シャ"], ["くるま"], ["mobil", "kendaraan", "car", "vehicle"], 7, "車", [
        ("車", "kuruma", "mobil"),
        ("電車", "densha", "kereta listrik"),
        ("自動車", "jidousha", "mobil/kendaraan bermotor"),
    ], [
        ("車で会社に行きます。", "Kuruma de kaisha ni ikimasu.", "Saya pergi ke kantor naik mobil."),
        ("毎日電車に乗ります。", "Mainichi densha ni norimasu.", "Setiap hari saya naik kereta."),
    ]),
    ("den", "電", ["デン"], [], ["listrik", "electricity"], 13, "雨", [
        ("電車", "densha", "kereta listrik"),
        ("電話", "denwa", "telepon"),
        ("電気", "denki", "listrik/lampu"),
    ], [
        ("電気を消してください。", "Denki o keshite kudasai.", "Tolong matikan lampu."),
        ("電話番号を教えてください。", "Denwa bangou o oshiete kudasai.", "Tolong beritahu nomor telepon Anda."),
    ]),
    ("michi", "道", ["ドウ"], ["みち"], ["jalan", "road", "way"], 12, "辶", [
        ("道", "michi", "jalan"),
        ("道路", "douro", "jalan raya"),
        ("北海道", "hokkaidou", "Hokkaido"),
    ], [
        ("この道をまっすぐ行ってください。", "Kono michi o massugu itte kudasai.", "Tolong jalan lurus di jalan ini."),
        ("道路が混んでいます。", "Douro ga konde imasu.", "Jalan raya sedang macet."),
    ]),
]

# N4 kanji (Batch 7 Fase 1 continued). Same tuple shape as N5_KANJI, filled
# incrementally across several commits (see kanji_char_lists.N4_CHARACTERS
# for the full locked 133-character scope this is working through).
N4_KANJI = [
    # --- Batch A: 朝昼夜度 + 雪風音光 + 体心頭病死顔声 + 妹弟兄姉主者員 (22) ---
    ("asa", "朝", ["チョウ"], ["あさ"], ["pagi", "morning"], 12, "月", [
        ("朝", "asa", "pagi"),
        ("朝食", "choushoku", "sarapan"),
        ("毎朝", "maiasa", "setiap pagi"),
    ], [
        ("朝六時に起きます。", "Asa rokuji ni okimasu.", "Saya bangun jam enam pagi."),
        ("毎朝コーヒーを飲みます。", "Maiasa koohii o nomimasu.", "Setiap pagi saya minum kopi."),
    ]),
    ("hiru", "昼", ["チュウ"], ["ひる"], ["siang", "tengah hari", "noon", "daytime"], 9, "日", [
        ("昼", "hiru", "siang"),
        ("昼食", "chuushoku", "makan siang"),
        ("昼休み", "hiruyasumi", "jam istirahat siang"),
    ], [
        ("昼ごはんを食べましょう。", "Hirugohan o tabemashou.", "Ayo makan siang."),
        ("昼休みは十二時からです。", "Hiruyasumi wa juuniji kara desu.", "Istirahat siang mulai jam dua belas."),
    ]),
    ("yoru", "夜", ["ヤ"], ["よる", "よ"], ["malam", "night"], 8, "夕", [
        ("夜", "yoru", "malam"),
        ("今夜", "kon'ya", "malam ini"),
        ("夜中", "yonaka", "tengah malam"),
    ], [
        ("夜は静かです。", "Yoru wa shizuka desu.", "Malam hari sunyi."),
        ("今夜、映画を見ます。", "Kon'ya, eiga o mimasu.", "Malam ini, saya akan menonton film."),
    ]),
    ("do", "度", ["ド", "ト"], ["たび"], ["derajat", "kali (frekuensi)", "degree", "times"], 9, "广", [
        ("今度", "kondo", "kali ini/lain kali"),
        ("一度", "ichido", "satu kali"),
        ("温度", "ondo", "suhu"),
    ], [
        ("今度、一緒に行きましょう。", "Kondo, issho ni ikimashou.", "Lain kali, ayo pergi bersama."),
        ("今日の温度は三十度です。", "Kyou no ondo wa sanjuudo desu.", "Suhu hari ini tiga puluh derajat."),
    ]),
    ("yuki", "雪", ["セツ"], ["ゆき"], ["salju", "snow"], 11, "雨", [
        ("雪", "yuki", "salju"),
        ("大雪", "ooyuki", "salju lebat"),
        ("雪国", "yukiguni", "negeri bersalju"),
    ], [
        ("冬に雪が降ります。", "Fuyu ni yuki ga furimasu.", "Musim dingin turun salju."),
        ("雪国に旅行したいです。", "Yukiguni ni ryokou shitai desu.", "Saya ingin bepergian ke negeri bersalju."),
    ]),
    ("kaze", "風", ["フウ", "フ"], ["かぜ"], ["angin", "wind"], 9, "風", [
        ("風", "kaze", "angin"),
        ("台風", "taifuu", "topan"),
        ("風邪", "kaze", "pilek/masuk angin"),
    ], [
        ("今日は風が強いです。", "Kyou wa kaze ga tsuyoi desu.", "Hari ini anginnya kencang."),
        ("風邪をひきました。", "Kaze o hikimashita.", "Saya masuk angin."),
    ]),
    ("oto", "音", ["オン", "イン"], ["おと", "ね"], ["suara", "bunyi", "sound"], 9, "音", [
        ("音", "oto", "suara/bunyi"),
        ("音楽", "ongaku", "musik"),
        ("発音", "hatsuon", "pengucapan"),
    ], [
        ("変な音が聞こえます。", "Hen na oto ga kikoemasu.", "Terdengar suara aneh."),
        ("音楽を聞くのが好きです。", "Ongaku o kiku no ga suki desu.", "Saya suka mendengarkan musik."),
    ]),
    ("hikari", "光", ["コウ"], ["ひかり", "ひか-る"], ["cahaya", "light"], 6, "儿", [
        ("光", "hikari", "cahaya"),
        ("日光", "nikkou", "sinar matahari"),
        ("光る", "hikaru", "bersinar"),
    ], [
        ("星が光っています。", "Hoshi ga hikatte imasu.", "Bintang-bintang bersinar."),
        ("日光を浴びましょう。", "Nikkou o abimashou.", "Ayo berjemur sinar matahari."),
    ]),
    ("karada", "体", ["タイ"], ["からだ"], ["badan", "tubuh", "body"], 7, "人", [
        ("体", "karada", "tubuh"),
        ("体育", "taiiku", "olahraga/pendidikan jasmani"),
        ("体重", "taijuu", "berat badan"),
    ], [
        ("体に気をつけてください。", "Karada ni ki o tsukete kudasai.", "Tolong jaga kesehatan Anda."),
        ("体育の授業が好きです。", "Taiiku no jugyou ga suki desu.", "Saya suka pelajaran olahraga."),
    ]),
    ("kokoro", "心", ["シン"], ["こころ"], ["hati", "jiwa", "heart", "mind"], 4, "心", [
        ("心", "kokoro", "hati/jiwa"),
        ("心配", "shinpai", "khawatir"),
        ("安心", "anshin", "lega/tenang"),
    ], [
        ("心配しないでください。", "Shinpai shinaide kudasai.", "Tolong jangan khawatir."),
        ("それを聞いて安心しました。", "Sore o kiite anshin shimashita.", "Saya lega mendengarnya."),
    ]),
    ("atama", "頭", ["トウ", "ズ"], ["あたま"], ["kepala", "head"], 16, "頁", [
        ("頭", "atama", "kepala"),
        ("頭痛", "zutsuu", "sakit kepala"),
        ("石頭", "ishiatama", "keras kepala"),
    ], [
        ("頭が痛いです。", "Atama ga itai desu.", "Kepala saya sakit."),
        ("彼は頭がいいです。", "Kare wa atama ga ii desu.", "Dia pintar."),
    ]),
    ("yamai", "病", ["ビョウ"], ["やまい", "や-む"], ["sakit", "penyakit", "illness", "sickness"], 10, "疒", [
        ("病気", "byouki", "sakit/penyakit"),
        ("病院", "byouin", "rumah sakit"),
        ("病人", "byounin", "orang sakit"),
    ], [
        ("病気で学校を休みました。", "Byouki de gakkou o yasumimashita.", "Saya bolos sekolah karena sakit."),
        ("病院へ行きました。", "Byouin e ikimashita.", "Saya pergi ke rumah sakit."),
    ]),
    ("shinu", "死", ["シ"], ["し-ぬ"], ["mati", "meninggal", "death", "die"], 6, "歹", [
        ("死ぬ", "shinu", "mati"),
        ("死", "shi", "kematian"),
        ("必死", "hisshi", "mati-matian/sekuat tenaga"),
    ], [
        ("祖父は去年死にました。", "Sofu wa kyonen shinimashita.", "Kakek saya meninggal tahun lalu."),
        ("必死に勉強しました。", "Hisshi ni benkyou shimashita.", "Saya belajar mati-matian."),
    ]),
    ("kao", "顔", ["ガン"], ["かお"], ["wajah", "muka", "face"], 18, "頁", [
        ("顔", "kao", "wajah"),
        ("笑顔", "egao", "wajah tersenyum"),
        ("顔色", "kaoiro", "raut wajah"),
    ], [
        ("彼女は笑顔がかわいいです。", "Kanojo wa egao ga kawaii desu.", "Senyumnya manis."),
        ("顔を洗ってください。", "Kao o aratte kudasai.", "Tolong cuci muka."),
    ]),
    ("koe", "声", ["セイ"], ["こえ"], ["suara (manusia)", "voice"], 7, "士", [
        ("声", "koe", "suara"),
        ("大声", "oogoe", "suara keras"),
        ("声優", "seiyuu", "pengisi suara"),
    ], [
        ("大きい声で話してください。", "Ookii koe de hanashite kudasai.", "Tolong bicara dengan suara keras."),
        ("いい声ですね。", "Ii koe desu ne.", "Suaranya bagus ya."),
    ]),
    ("imouto", "妹", ["マイ"], ["いもうと"], ["adik perempuan", "younger sister"], 8, "女", [
        ("妹", "imouto", "adik perempuan"),
        ("妹さん", "imoutosan", "adik perempuan (orang lain)"),
        ("姉妹", "shimai", "kakak-adik perempuan"),
    ], [
        ("私には妹がいます。", "Watashi ni wa imouto ga imasu.", "Saya punya adik perempuan."),
        ("姉妹で旅行しました。", "Shimai de ryokou shimashita.", "Kami (kakak-adik perempuan) bepergian bersama."),
    ]),
    ("otouto", "弟", ["テイ", "ダイ"], ["おとうと"], ["adik laki-laki", "younger brother"], 7, "弓", [
        ("弟", "otouto", "adik laki-laki"),
        ("弟さん", "otoutosan", "adik laki-laki (orang lain)"),
        ("兄弟", "kyoudai", "saudara kandung"),
    ], [
        ("弟は高校生です。", "Otouto wa koukousei desu.", "Adik laki-laki saya siswa SMA."),
        ("兄弟は何人いますか。", "Kyoudai wa nannin imasu ka.", "Ada berapa saudara kandung Anda?"),
    ]),
    ("ani", "兄", ["キョウ", "ケイ"], ["あに"], ["kakak laki-laki", "older brother"], 5, "儿", [
        ("兄", "ani", "kakak laki-laki"),
        ("お兄さん", "oniisan", "kakak laki-laki (umum)"),
        ("兄弟", "kyoudai", "saudara kandung"),
    ], [
        ("兄は医者です。", "Ani wa isha desu.", "Kakak laki-laki saya dokter."),
        ("お兄さんは優しいですか。", "Oniisan wa yasashii desu ka.", "Apakah kakak laki-laki Anda baik hati?"),
    ]),
    ("ane", "姉", ["シ"], ["あね"], ["kakak perempuan", "older sister"], 8, "女", [
        ("姉", "ane", "kakak perempuan"),
        ("お姉さん", "oneesan", "kakak perempuan (umum)"),
        ("姉妹", "shimai", "kakak-adik perempuan"),
    ], [
        ("姉は先生です。", "Ane wa sensei desu.", "Kakak perempuan saya guru."),
        ("お姉さんに会いたいです。", "Oneesan ni aitai desu.", "Saya ingin bertemu kakak perempuan Anda."),
    ]),
    ("nushi", "主", ["シュ", "ス"], ["ぬし", "おも"], ["utama", "tuan/pemilik", "main", "master"], 5, "丶", [
        ("主人", "shujin", "suami/tuan rumah"),
        ("主な", "omona", "utama"),
        ("持ち主", "mochinushi", "pemilik"),
    ], [
        ("主な理由は何ですか。", "Omona riyuu wa nan desu ka.", "Apa alasan utamanya?"),
        ("この犬の持ち主は誰ですか。", "Kono inu no mochinushi wa dare desu ka.", "Siapa pemilik anjing ini?"),
    ]),
    ("mono", "者", ["シャ"], ["もの"], ["orang", "person"], 8, "老", [
        ("医者", "isha", "dokter"),
        ("若者", "wakamono", "anak muda"),
        ("学者", "gakusha", "ilmuwan"),
    ], [
        ("彼は有名な学者です。", "Kare wa yuumei na gakusha desu.", "Dia ilmuwan terkenal."),
        ("若者に人気があります。", "Wakamono ni ninki ga arimasu.", "Populer di kalangan anak muda."),
    ]),
    ("in", "員", ["イン"], [], ["anggota", "pegawai", "member", "staff"], 10, "口", [
        ("会社員", "kaishain", "karyawan"),
        ("店員", "ten'in", "pegawai toko"),
        ("会員", "kaiin", "anggota"),
    ], [
        ("父は会社員です。", "Chichi wa kaishain desu.", "Ayah saya karyawan."),
        ("このクラブの会員です。", "Kono kurabu no kaiin desu.", "Saya anggota klub ini."),
    ]),
]

PLACEHOLDER_COUNTS = {"N3": 5, "N2": 5, "N1": 5}


def build_n5_entries():
    entries = []
    for suffix, char, on, kun, meanings, strokes, radical, word_examples, sentence_examples in N5_KANJI:
        entries.append({
            "id": f"kanji_{suffix}",
            "character": char,
            "jlptLevel": "N5",
            "onyomi": on,
            "kunyomi": kun,
            "meanings": meanings,
            "strokeCount": strokes,
            "svgAsset": f"assets/kanjivg/{ord(char):05x}.svg",
            "radical": radical,
            "wordExamples": [
                {"word": word, "reading": reading, "meaning": meaning}
                for word, reading, meaning in word_examples
            ],
            "sentenceExamples": [
                {"japanese": jp, "romaji": ro, "translation": tr}
                for jp, ro, tr in sentence_examples
            ],
            "relatedBunpou": [],
        })
    return entries


def build_n4_entries():
    entries = []
    for suffix, char, on, kun, meanings, strokes, radical, word_examples, sentence_examples in N4_KANJI:
        entries.append({
            "id": f"kanji_{suffix}",
            "character": char,
            "jlptLevel": "N4",
            "onyomi": on,
            "kunyomi": kun,
            "meanings": meanings,
            "strokeCount": strokes,
            "svgAsset": f"assets/kanjivg/{ord(char):05x}.svg",
            "radical": radical,
            "wordExamples": [
                {"word": word, "reading": reading, "meaning": meaning}
                for word, reading, meaning in word_examples
            ],
            "sentenceExamples": [
                {"japanese": jp, "romaji": ro, "translation": tr}
                for jp, ro, tr in sentence_examples
            ],
            "relatedBunpou": [],
        })
    return entries


def build_placeholder_entries():
    entries = []
    for level, count in PLACEHOLDER_COUNTS.items():
        for i in range(1, count + 1):
            entries.append({
                "id": f"kanji_{level.lower()}_placeholder_{i}",
                "character": "",
                "jlptLevel": level,
                "onyomi": [],
                "kunyomi": [],
                "meanings": [],
                "strokeCount": 0,
                "svgAsset": None,
                "radical": None,
                "wordExamples": [],
                "sentenceExamples": [],
                "relatedBunpou": [],
                "placeholder": True,
            })
    return entries


def main():
    data = build_n5_entries() + build_n4_entries() + build_placeholder_entries()
    with open("assets/data/kanji_data.json", "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
    print(f"Wrote {len(data)} kanji entries ({len(N5_KANJI)} real N5 + "
          f"{len(N4_KANJI)} real N4 + {sum(PLACEHOLDER_COUNTS.values())} placeholders).")


if __name__ == "__main__":
    main()
