import json

from kanji_char_lists import N1_CHARACTERS, N2_CHARACTERS, N3_CHARACTERS

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
    # --- Batch B: 使作思知持遊働走泳飛送教習覚忘決別変始終開閉集動 (24) ---
    ("tsukau", "使", ["シ"], ["つか-う"], ["menggunakan", "use"], 8, "人", [
        ("使う", "tsukau", "menggunakan"),
        ("使用", "shiyou", "penggunaan"),
        ("大使", "taishi", "duta besar"),
    ], [
        ("辞書を使います。", "Jisho o tsukaimasu.", "Saya menggunakan kamus."),
        ("このパソコンは使用禁止です。", "Kono pasokon wa shiyou kinshi desu.", "Komputer ini dilarang digunakan."),
    ]),
    ("tsukuru", "作", ["サク", "サ"], ["つく-る"], ["membuat", "make"], 7, "人", [
        ("作る", "tsukuru", "membuat"),
        ("作文", "sakubun", "karangan"),
        ("作品", "sakuhin", "karya"),
    ], [
        ("料理を作ります。", "Ryouri o tsukurimasu.", "Saya membuat masakan."),
        ("この作品は美しいです。", "Kono sakuhin wa utsukushii desu.", "Karya ini indah."),
    ]),
    ("omou", "思", ["シ"], ["おも-う"], ["berpikir", "think"], 9, "心", [
        ("思う", "omou", "berpikir"),
        ("思い出", "omoide", "kenangan"),
        ("意思", "ishi", "maksud/kehendak"),
    ], [
        ("そう思います。", "Sou omoimasu.", "Saya pikir begitu."),
        ("いい思い出になりました。", "Ii omoide ni narimashita.", "Menjadi kenangan yang indah."),
    ]),
    ("shiru", "知", ["チ"], ["し-る"], ["tahu", "mengetahui", "know"], 8, "矢", [
        ("知る", "shiru", "mengetahui"),
        ("知識", "chishiki", "pengetahuan"),
        ("知らせる", "shiraseru", "memberitahu"),
    ], [
        ("その話は知っています。", "Sono hanashi wa shitte imasu.", "Saya tahu cerita itu."),
        ("結果を知らせてください。", "Kekka o shirasete kudasai.", "Tolong beritahu hasilnya."),
    ]),
    ("motsu", "持", ["ジ"], ["も-つ"], ["memegang", "membawa", "hold", "have"], 9, "手", [
        ("持つ", "motsu", "memegang/membawa"),
        ("気持ち", "kimochi", "perasaan"),
        ("持ち物", "mochimono", "barang bawaan"),
    ], [
        ("かばんを持っています。", "Kaban o motte imasu.", "Saya membawa tas."),
        ("今日の気持ちはどうですか。", "Kyou no kimochi wa dou desu ka.", "Bagaimana perasaan Anda hari ini?"),
    ]),
    ("asobu", "遊", ["ユウ"], ["あそ-ぶ"], ["bermain", "play"], 12, "辶", [
        ("遊ぶ", "asobu", "bermain"),
        ("遊園地", "yuuenchi", "taman hiburan"),
        ("遊び", "asobi", "permainan"),
    ], [
        ("公園で遊びます。", "Kouen de asobimasu.", "Saya bermain di taman."),
        ("遊園地に行きたいです。", "Yuuenchi ni ikitai desu.", "Saya ingin pergi ke taman hiburan."),
    ]),
    ("hataraku", "働", ["ドウ"], ["はたら-く"], ["bekerja", "work"], 13, "人", [
        ("働く", "hataraku", "bekerja"),
        ("労働", "roudou", "tenaga kerja"),
        ("共働き", "tomobataraki", "suami istri sama-sama bekerja"),
    ], [
        ("銀行で働いています。", "Ginkou de hataraite imasu.", "Saya bekerja di bank."),
        ("両親は共働きです。", "Ryoushin wa tomobataraki desu.", "Orang tua saya sama-sama bekerja."),
    ]),
    ("hashiru", "走", ["ソウ"], ["はし-る"], ["berlari", "run"], 7, "走", [
        ("走る", "hashiru", "berlari"),
        ("競走", "kyousou", "lomba lari"),
        ("走者", "sousha", "pelari"),
    ], [
        ("毎朝走ります。", "Maiasa hashirimasu.", "Setiap pagi saya berlari."),
        ("彼は速く走ります。", "Kare wa hayaku hashirimasu.", "Dia berlari cepat."),
    ]),
    ("oyogu", "泳", ["エイ"], ["およ-ぐ"], ["berenang", "swim"], 8, "水", [
        ("泳ぐ", "oyogu", "berenang"),
        ("水泳", "suiei", "renang"),
        ("平泳ぎ", "hiraoyogi", "gaya dada"),
    ], [
        ("海で泳ぎます。", "Umi de oyogimasu.", "Saya berenang di laut."),
        ("水泳が得意です。", "Suiei ga tokui desu.", "Saya jago berenang."),
    ]),
    ("tobu", "飛", ["ヒ"], ["と-ぶ"], ["terbang", "fly"], 9, "飛", [
        ("飛ぶ", "tobu", "terbang"),
        ("飛行機", "hikouki", "pesawat terbang"),
        ("飛行場", "hikoujou", "lapangan terbang"),
    ], [
        ("鳥が空を飛んでいます。", "Tori ga sora o tonde imasu.", "Burung terbang di langit."),
        ("飛行機でアメリカへ行きます。", "Hikouki de Amerika e ikimasu.", "Saya pergi ke Amerika naik pesawat."),
    ]),
    ("okuru", "送", ["ソウ"], ["おく-る"], ["mengirim", "mengantar", "send"], 9, "辶", [
        ("送る", "okuru", "mengirim/mengantar"),
        ("送料", "souryou", "biaya kirim"),
        ("見送る", "miokuru", "mengantar kepergian"),
    ], [
        ("手紙を送ります。", "Tegami o okurimasu.", "Saya mengirim surat."),
        ("駅まで送ります。", "Eki made okurimasu.", "Saya akan mengantar Anda sampai stasiun."),
    ]),
    ("oshieru", "教", ["キョウ"], ["おし-える", "おそ-わる"], ["mengajar", "teach"], 11, "攵", [
        ("教える", "oshieru", "mengajar"),
        ("教室", "kyoushitsu", "ruang kelas"),
        ("教育", "kyouiku", "pendidikan"),
    ], [
        ("日本語を教えています。", "Nihongo o oshiete imasu.", "Saya mengajar bahasa Jepang."),
        ("教室はどこですか。", "Kyoushitsu wa doko desu ka.", "Di mana ruang kelas?"),
    ]),
    ("narau", "習", ["シュウ"], ["なら-う"], ["berlatih", "belajar", "practice", "learn"], 11, "羽", [
        ("習う", "narau", "belajar/berlatih"),
        ("練習", "renshuu", "latihan"),
        ("予習", "yoshuu", "belajar sebelum kelas"),
    ], [
        ("ピアノを習っています。", "Piano o naratte imasu.", "Saya belajar piano."),
        ("毎日漢字を練習します。", "Mainichi kanji o renshuu shimasu.", "Setiap hari saya berlatih kanji."),
    ]),
    ("oboeru", "覚", ["カク"], ["おぼ-える", "さ-める"], ["mengingat", "remember"], 12, "見", [
        ("覚える", "oboeru", "mengingat/menghafal"),
        ("覚えている", "oboeteiru", "ingat"),
        ("目覚める", "mezameru", "terbangun"),
    ], [
        ("単語を覚えます。", "Tango o oboemasu.", "Saya menghafal kosakata."),
        ("その日のことをよく覚えています。", "Sono hi no koto o yoku oboete imasu.", "Saya masih ingat betul hari itu."),
    ]),
    ("wasureru", "忘", ["ボウ"], ["わす-れる"], ["melupakan", "forget"], 7, "心", [
        ("忘れる", "wasureru", "melupakan"),
        ("忘れ物", "wasuremono", "barang tertinggal"),
        ("物忘れ", "monowasure", "pelupa"),
    ], [
        ("名前を忘れました。", "Namae o wasuremashita.", "Saya lupa namanya."),
        ("傘を忘れ物しました。", "Kasa o wasuremono shimashita.", "Saya meninggalkan payung."),
    ]),
    ("kimeru", "決", ["ケツ"], ["き-める", "き-まる"], ["memutuskan", "decide"], 7, "水", [
        ("決める", "kimeru", "memutuskan"),
        ("決定", "kettei", "keputusan"),
        ("決して", "kesshite", "sama sekali (tidak)"),
    ], [
        ("行き先を決めました。", "Ikisaki o kimemashita.", "Saya sudah memutuskan tujuan perjalanan."),
        ("決して諦めません。", "Kesshite akiramemasen.", "Saya tidak akan pernah menyerah."),
    ]),
    ("wakareru", "別", ["ベツ"], ["わか-れる"], ["berpisah", "terpisah", "separate"], 7, "刂", [
        ("別れる", "wakareru", "berpisah"),
        ("別に", "betsuni", "tidak terlalu/khususnya tidak"),
        ("特別", "tokubetsu", "istimewa"),
    ], [
        ("駅で友達と別れました。", "Eki de tomodachi to wakaremashita.", "Saya berpisah dengan teman di stasiun."),
        ("これは特別なプレゼントです。", "Kore wa tokubetsu na purezento desu.", "Ini hadiah yang istimewa."),
    ]),
    ("kawaru", "変", ["ヘン"], ["か-わる", "か-える"], ["berubah", "aneh", "change", "strange"], 9, "夂", [
        ("変わる", "kawaru", "berubah"),
        ("変える", "kaeru", "mengubah"),
        ("大変", "taihen", "berat/sangat"),
    ], [
        ("天気が変わりました。", "Tenki ga kawarimashita.", "Cuaca berubah."),
        ("今日は大変でした。", "Kyou wa taihen deshita.", "Hari ini berat/melelahkan."),
    ]),
    ("hajimeru", "始", ["シ"], ["はじ-める", "はじ-まる"], ["memulai", "begin", "start"], 8, "女", [
        ("始める", "hajimeru", "memulai"),
        ("始まる", "hajimaru", "dimulai"),
        ("開始", "kaishi", "permulaan"),
    ], [
        ("授業を始めます。", "Jugyou o hajimemasu.", "Saya memulai pelajaran."),
        ("映画は七時に始まります。", "Eiga wa shichiji ni hajimarimasu.", "Film dimulai jam tujuh."),
    ]),
    ("owaru", "終", ["シュウ"], ["お-わる", "お-える"], ["berakhir", "end", "finish"], 11, "糸", [
        ("終わる", "owaru", "berakhir"),
        ("終電", "shuuden", "kereta terakhir"),
        ("最終", "saishuu", "terakhir"),
    ], [
        ("仕事が終わりました。", "Shigoto ga owarimashita.", "Pekerjaan sudah selesai."),
        ("終電に乗り遅れました。", "Shuuden ni noriokuremashita.", "Saya ketinggalan kereta terakhir."),
    ]),
    ("hiraku", "開", ["カイ"], ["ひら-く", "あ-ける"], ["membuka", "open"], 12, "門", [
        ("開く", "hiraku", "membuka"),
        ("開ける", "akeru", "membuka"),
        ("開店", "kaiten", "buka toko"),
    ], [
        ("窓を開けてください。", "Mado o akete kudasai.", "Tolong buka jendela."),
        ("店は十時に開店します。", "Mise wa juuji ni kaiten shimasu.", "Toko buka jam sepuluh."),
    ]),
    ("shimeru", "閉", ["ヘイ"], ["と-じる", "し-める"], ["menutup", "close"], 11, "門", [
        ("閉じる", "tojiru", "menutup"),
        ("閉める", "shimeru", "menutup"),
        ("閉店", "heiten", "tutup toko"),
    ], [
        ("本を閉じてください。", "Hon o tojite kudasai.", "Tolong tutup buku."),
        ("店は九時に閉店します。", "Mise wa kuji ni heiten shimasu.", "Toko tutup jam sembilan."),
    ]),
    ("atsumaru", "集", ["シュウ"], ["あつ-まる", "あつ-める"], ["berkumpul", "mengumpulkan", "gather"], 12, "隹", [
        ("集まる", "atsumaru", "berkumpul"),
        ("集める", "atsumeru", "mengumpulkan"),
        ("集合", "shuugou", "berkumpul/pertemuan"),
    ], [
        ("公園に集まりましょう。", "Kouen ni atsumarimashou.", "Ayo berkumpul di taman."),
        ("切手を集めています。", "Kitte o atsumete imasu.", "Saya mengumpulkan perangko."),
    ]),
    ("ugoku", "動", ["ドウ"], ["うご-く"], ["bergerak", "move"], 11, "力", [
        ("動く", "ugoku", "bergerak"),
        ("運動", "undou", "olahraga"),
        ("自動", "jidou", "otomatis"),
    ], [
        ("車が動きません。", "Kuruma ga ugokimasen.", "Mobilnya tidak bisa bergerak."),
        ("毎日運動します。", "Mainichi undou shimasu.", "Setiap hari saya berolahraga."),
    ]),
    # --- Batch C: 早遅強弱重軽暗明深浅太細図意味配方仕室乗降通 (22) ---
    ("hayai", "早", ["ソウ", "サッ"], ["はや-い"], ["awal", "cepat", "early", "fast"], 6, "日", [
        ("早い", "hayai", "awal/cepat"),
        ("早朝", "souchou", "pagi-pagi buta"),
        ("早く", "hayaku", "cepat/segera"),
    ], [
        ("今日は早く起きました。", "Kyou wa hayaku okimashita.", "Hari ini saya bangun pagi-pagi."),
        ("早朝に散歩します。", "Souchou ni sanpo shimasu.", "Saya berjalan-jalan pagi-pagi buta."),
    ]),
    ("osoi", "遅", ["チ"], ["おそ-い", "おく-れる"], ["lambat", "terlambat", "late", "slow"], 12, "辶", [
        ("遅い", "osoi", "lambat/terlambat"),
        ("遅れる", "okureru", "terlambat"),
        ("遅刻", "chikoku", "keterlambatan"),
    ], [
        ("バスが遅れています。", "Basu ga okurete imasu.", "Bisnya terlambat."),
        ("学校に遅刻しました。", "Gakkou ni chikoku shimashita.", "Saya terlambat ke sekolah."),
    ]),
    ("tsuyoi", "強", ["キョウ", "ゴウ"], ["つよ-い", "し-いる"], ["kuat", "strong"], 11, "弓", [
        ("強い", "tsuyoi", "kuat"),
        ("勉強", "benkyou", "belajar"),
        ("強調", "kyouchou", "penekanan"),
    ], [
        ("彼は強いです。", "Kare wa tsuyoi desu.", "Dia kuat."),
        ("毎日日本語を勉強します。", "Mainichi nihongo o benkyou shimasu.", "Setiap hari saya belajar bahasa Jepang."),
    ]),
    ("yowai", "弱", ["ジャク"], ["よわ-い"], ["lemah", "weak"], 10, "弓", [
        ("弱い", "yowai", "lemah"),
        ("弱点", "jakuten", "kelemahan"),
        ("弱虫", "yowamushi", "pengecut"),
    ], [
        ("体が弱いです。", "Karada ga yowai desu.", "Badannya lemah."),
        ("彼の弱点は何ですか。", "Kare no jakuten wa nan desu ka.", "Apa kelemahannya?"),
    ]),
    ("omoi", "重", ["ジュウ", "チョウ"], ["おも-い", "かさ-なる"], ["berat", "heavy"], 9, "里", [
        ("重い", "omoi", "berat"),
        ("重要", "juuyou", "penting"),
        ("体重", "taijuu", "berat badan"),
    ], [
        ("このかばんは重いです。", "Kono kaban wa omoi desu.", "Tas ini berat."),
        ("これは重要な問題です。", "Kore wa juuyou na mondai desu.", "Ini masalah penting."),
    ]),
    ("karui", "軽", ["ケイ"], ["かる-い"], ["ringan", "light"], 12, "車", [
        ("軽い", "karui", "ringan"),
        ("軽食", "keishoku", "makanan ringan"),
        ("気軽", "kigaru", "santai/tanpa beban"),
    ], [
        ("このかばんは軽いです。", "Kono kaban wa karui desu.", "Tas ini ringan."),
        ("軽食を食べましょう。", "Keishoku o tabemashou.", "Ayo makan makanan ringan."),
    ]),
    ("kurai", "暗", ["アン"], ["くら-い"], ["gelap", "dark"], 13, "日", [
        ("暗い", "kurai", "gelap"),
        ("暗記", "anki", "menghafal"),
        ("真っ暗", "makkura", "gelap gulita"),
    ], [
        ("部屋が暗いです。", "Heya ga kurai desu.", "Kamarnya gelap."),
        ("単語を暗記します。", "Tango o anki shimasu.", "Saya menghafal kosakata."),
    ]),
    ("akarui", "明", ["メイ", "ミョウ"], ["あか-るい", "あ-ける"], ["terang", "bright", "clear"], 8, "日", [
        ("明るい", "akarui", "terang/ceria"),
        ("説明", "setsumei", "penjelasan"),
        ("明日", "ashita", "besok"),
    ], [
        ("この部屋は明るいです。", "Kono heya wa akarui desu.", "Kamar ini terang."),
        ("もう一度説明してください。", "Mou ichido setsumei shite kudasai.", "Tolong jelaskan sekali lagi."),
    ]),
    ("fukai", "深", ["シン"], ["ふか-い"], ["dalam", "deep"], 11, "水", [
        ("深い", "fukai", "dalam"),
        ("深夜", "shin'ya", "tengah malam"),
        ("深呼吸", "shinkokyuu", "napas dalam"),
    ], [
        ("この川は深いです。", "Kono kawa wa fukai desu.", "Sungai ini dalam."),
        ("深夜まで働きました。", "Shin'ya made hatarakimashita.", "Saya bekerja sampai tengah malam."),
    ]),
    ("asai", "浅", ["セン"], ["あさ-い"], ["dangkal", "shallow"], 9, "水", [
        ("浅い", "asai", "dangkal"),
        ("浅瀬", "asase", "perairan dangkal"),
        ("経験が浅い", "keiken ga asai", "pengalaman minim"),
    ], [
        ("この川は浅いです。", "Kono kawa wa asai desu.", "Sungai ini dangkal."),
        ("彼はまだ経験が浅いです。", "Kare wa mada keiken ga asai desu.", "Pengalamannya masih minim."),
    ]),
    ("futoi", "太", ["タイ", "タ"], ["ふと-い", "ふと-る"], ["gemuk", "tebal", "fat", "thick"], 4, "大", [
        ("太い", "futoi", "tebal/gemuk"),
        ("太る", "futoru", "menjadi gemuk"),
        ("丸太", "maruta", "batang kayu"),
    ], [
        ("この木は太いです。", "Kono ki wa futoi desu.", "Pohon ini besar/tebal."),
        ("最近太りました。", "Saikin futorimashita.", "Akhir-akhir ini saya menjadi gemuk."),
    ]),
    ("hosoi", "細", ["サイ"], ["ほそ-い", "こま-かい"], ["kurus", "tipis", "rinci", "thin", "detailed"], 11, "糸", [
        ("細い", "hosoi", "kurus/tipis"),
        ("細かい", "komakai", "rinci/kecil-kecil"),
        ("詳細", "shousai", "rincian"),
    ], [
        ("この道は細いです。", "Kono michi wa hosoi desu.", "Jalan ini sempit."),
        ("細かく説明してください。", "Komakaku setsumei shite kudasai.", "Tolong jelaskan secara rinci."),
    ]),
    ("zu", "図", ["ズ", "ト"], ["はか-る"], ["gambar", "diagram", "map"], 7, "囗", [
        ("図書館", "toshokan", "perpustakaan"),
        ("地図", "chizu", "peta"),
        ("図", "zu", "gambar/diagram"),
    ], [
        ("図書館で勉強します。", "Toshokan de benkyou shimasu.", "Saya belajar di perpustakaan."),
        ("地図を見てください。", "Chizu o mite kudasai.", "Tolong lihat peta."),
    ]),
    ("i2", "意", ["イ"], [], ["maksud", "pikiran", "meaning", "intention"], 13, "心", [
        ("意味", "imi", "arti/makna"),
        ("意見", "iken", "pendapat"),
        ("注意", "chuui", "perhatian"),
    ], [
        ("この言葉の意味は何ですか。", "Kono kotoba no imi wa nan desu ka.", "Apa arti kata ini?"),
        ("注意してください。", "Chuui shite kudasai.", "Tolong berhati-hati."),
    ]),
    ("aji", "味", ["ミ"], ["あじ", "あじ-わう"], ["rasa", "taste", "flavor"], 8, "口", [
        ("味", "aji", "rasa"),
        ("意味", "imi", "arti"),
        ("趣味", "shumi", "hobi"),
    ], [
        ("この料理は味がいいです。", "Kono ryouri wa aji ga ii desu.", "Masakan ini rasanya enak."),
        ("趣味は何ですか。", "Shumi wa nan desu ka.", "Apa hobi Anda?"),
    ]),
    ("kubaru", "配", ["ハイ"], ["くば-る"], ["membagikan", "distribute"], 10, "酉", [
        ("配る", "kubaru", "membagikan"),
        ("心配", "shinpai", "khawatir"),
        ("宅配", "takuhai", "pengiriman ke rumah"),
    ], [
        ("プリントを配ります。", "Purinto o kubarimasu.", "Saya membagikan lembar cetak."),
        ("心配しないでください。", "Shinpai shinaide kudasai.", "Tolong jangan khawatir."),
    ]),
    ("kata2", "方", ["ホウ"], ["かた"], ["arah", "cara", "orang (sopan)", "direction", "method"], 4, "方", [
        ("方法", "houhou", "metode/cara"),
        ("使い方", "tsukaikata", "cara pakai"),
        ("あの方", "ano kata", "orang itu (sopan)"),
    ], [
        ("使い方を教えてください。", "Tsukaikata o oshiete kudasai.", "Tolong ajarkan cara pakainya."),
        ("この方法は簡単です。", "Kono houhou wa kantan desu.", "Metode ini mudah."),
    ]),
    ("shi2", "仕", ["シ"], ["つか-える"], ["melayani", "bekerja", "serve", "work"], 5, "人", [
        ("仕事", "shigoto", "pekerjaan"),
        ("仕方", "shikata", "cara"),
        ("仕える", "tsukaeru", "mengabdi"),
    ], [
        ("仕事は楽しいです。", "Shigoto wa tanoshii desu.", "Pekerjaan itu menyenangkan."),
        ("仕方がありません。", "Shikata ga arimasen.", "Tidak ada cara lain."),
    ]),
    ("shitsu", "室", ["シツ"], ["むろ"], ["kamar", "ruangan", "room"], 9, "宀", [
        ("教室", "kyoushitsu", "ruang kelas"),
        ("図書室", "toshoshitsu", "ruang perpustakaan"),
        ("室内", "shitsunai", "dalam ruangan"),
    ], [
        ("教室で勉強します。", "Kyoushitsu de benkyou shimasu.", "Saya belajar di ruang kelas."),
        ("室内は暖かいです。", "Shitsunai wa atatakai desu.", "Di dalam ruangan hangat."),
    ]),
    ("noru", "乗", ["ジョウ"], ["の-る"], ["menaiki", "ride"], 9, "ノ", [
        ("乗る", "noru", "menaiki"),
        ("乗客", "joukyaku", "penumpang"),
        ("乗り物", "norimono", "kendaraan"),
    ], [
        ("バスに乗ります。", "Basu ni norimasu.", "Saya naik bis."),
        ("乗り物が好きです。", "Norimono ga suki desu.", "Saya suka kendaraan."),
    ]),
    ("oriru", "降", ["コウ"], ["お-りる", "ふ-る"], ["turun", "hujan turun", "descend", "fall"], 10, "阝", [
        ("降りる", "oriru", "turun"),
        ("降る", "furu", "turun (hujan/salju)"),
        ("乗降", "joukou", "naik-turun"),
    ], [
        ("次の駅で降ります。", "Tsugi no eki de orimasu.", "Saya turun di stasiun berikutnya."),
        ("雨が降っています。", "Ame ga futte imasu.", "Sedang turun hujan."),
    ]),
    ("tooru", "通", ["ツウ"], ["とお-る", "かよ-う"], ["melewati", "berlalu-lalang", "pass", "commute"], 10, "辶", [
        ("通る", "tooru", "melewati"),
        ("通学", "tsuugaku", "pergi-pulang sekolah"),
        ("交通", "koutsuu", "lalu lintas/transportasi"),
    ], [
        ("この道を通ります。", "Kono michi o toorimasu.", "Saya melewati jalan ini."),
        ("交通が便利です。", "Koutsuu ga benri desu.", "Transportasinya praktis."),
    ]),
    # --- Batch D: 好嫌楽赤青黒昔特急有無全部近遠実然究研理科屋 (22) ---
    ("suki2", "好", ["コウ"], ["す-く", "この-む"], ["suka", "like"], 6, "女", [
        ("好き", "suki", "suka"),
        ("好物", "koubutsu", "makanan favorit"),
        ("大好き", "daisuki", "sangat suka"),
    ], [
        ("音楽が好きです。", "Ongaku ga suki desu.", "Saya suka musik."),
        ("これは私の大好物です。", "Kore wa watashi no daikoubutsu desu.", "Ini makanan favorit saya."),
    ]),
    ("kirai", "嫌", ["ケン", "ゲン"], ["きら-う", "いや"], ["benci", "tidak suka", "dislike", "hate"], 13, "女", [
        ("嫌い", "kirai", "tidak suka/benci"),
        ("嫌がる", "iyagaru", "enggan"),
        ("機嫌", "kigen", "suasana hati"),
    ], [
        ("野菜が嫌いです。", "Yasai ga kirai desu.", "Saya tidak suka sayur."),
        ("今日は機嫌がいいです。", "Kyou wa kigen ga ii desu.", "Hari ini suasana hatinya bagus."),
    ]),
    ("tanoshii", "楽", ["ラク", "ガク"], ["たの-しい", "たの-しむ"], ["menyenangkan", "mudah", "musik", "fun", "easy"], 13, "木", [
        ("楽しい", "tanoshii", "menyenangkan"),
        ("音楽", "ongaku", "musik"),
        ("楽", "raku", "mudah/nyaman"),
    ], [
        ("旅行は楽しかったです。", "Ryokou wa tanoshikatta desu.", "Perjalanannya menyenangkan."),
        ("この仕事は楽です。", "Kono shigoto wa raku desu.", "Pekerjaan ini mudah."),
    ]),
    ("aka2", "赤", ["セキ", "シャク"], ["あか", "あか-い"], ["merah", "red"], 7, "赤", [
        ("赤い", "akai", "merah"),
        ("赤", "aka", "warna merah"),
        ("赤ちゃん", "akachan", "bayi"),
    ], [
        ("このりんごは赤いです。", "Kono ringo wa akai desu.", "Apel ini merah."),
        ("赤ちゃんがかわいいです。", "Akachan ga kawaii desu.", "Bayinya lucu."),
    ]),
    ("ao", "青", ["セイ", "ショウ"], ["あお", "あお-い"], ["biru", "hijau", "blue", "green"], 8, "青", [
        ("青い", "aoi", "biru"),
        ("青空", "aozora", "langit biru"),
        ("青年", "seinen", "pemuda"),
    ], [
        ("空が青いです。", "Sora ga aoi desu.", "Langit biru."),
        ("青空が気持ちいいです。", "Aozora ga kimochi ii desu.", "Langit biru terasa menyenangkan."),
    ]),
    ("kuro", "黒", ["コク"], ["くろ", "くろ-い"], ["hitam", "black"], 11, "黒", [
        ("黒い", "kuroi", "hitam"),
        ("黒板", "kokuban", "papan tulis"),
        ("黒字", "kuroji", "untung/surplus"),
    ], [
        ("髪が黒いです。", "Kami ga kuroi desu.", "Rambutnya hitam."),
        ("黒板を見てください。", "Kokuban o mite kudasai.", "Tolong lihat papan tulis."),
    ]),
    ("mukashi", "昔", ["セキ", "シャク"], ["むかし"], ["dahulu", "zaman dulu", "long ago"], 8, "日", [
        ("昔", "mukashi", "dahulu"),
        ("昔話", "mukashibanashi", "cerita rakyat"),
        ("大昔", "oomukashi", "zaman purba"),
    ], [
        ("昔、ここに川がありました。", "Mukashi, koko ni kawa ga arimashita.", "Dulu, di sini ada sungai."),
        ("昔話を読みました。", "Mukashibanashi o yomimashita.", "Saya membaca cerita rakyat."),
    ]),
    ("toku", "特", ["トク"], [], ["khusus", "istimewa", "special"], 10, "牛", [
        ("特に", "tokuni", "khususnya"),
        ("特別", "tokubetsu", "istimewa"),
        ("特急", "tokkyuu", "kereta ekspres"),
    ], [
        ("特に問題ありません。", "Tokuni mondai arimasen.", "Tidak ada masalah khususnya."),
        ("特急に乗りました。", "Tokkyuu ni norimashita.", "Saya naik kereta ekspres."),
    ]),
    ("isogu", "急", ["キュウ"], ["いそ-ぐ"], ["mendadak", "buru-buru", "urgent", "hurry"], 9, "心", [
        ("急ぐ", "isogu", "buru-buru"),
        ("急に", "kyuuni", "mendadak"),
        ("特急", "tokkyuu", "kereta ekspres"),
    ], [
        ("急いでください。", "Isoide kudasai.", "Tolong buru-buru."),
        ("急に雨が降ってきました。", "Kyuuni ame ga futte kimashita.", "Tiba-tiba turun hujan."),
    ]),
    ("aru", "有", ["ユウ", "ウ"], ["あ-る"], ["ada", "memiliki", "exist", "have"], 6, "月", [
        ("有名", "yuumei", "terkenal"),
        ("有る", "aru", "ada/memiliki"),
        ("有名人", "yuumeijin", "orang terkenal"),
    ], [
        ("彼は有名な作家です。", "Kare wa yuumei na sakka desu.", "Dia penulis terkenal."),
        ("このホテルはプールが有ります。", "Kono hoteru wa puuru ga arimasu.", "Hotel ini ada kolam renangnya."),
    ]),
    ("nai2", "無", ["ム", "ブ"], ["な-い"], ["tidak ada", "tanpa", "none", "without"], 12, "火", [
        ("無い", "nai", "tidak ada"),
        ("無料", "muryou", "gratis"),
        ("無理", "muri", "tidak mungkin/memaksakan"),
    ], [
        ("お金が無いです。", "Okane ga nai desu.", "Tidak ada uang."),
        ("このイベントは無料です。", "Kono ibento wa muryou desu.", "Acara ini gratis."),
    ]),
    ("zen2", "全", ["ゼン"], ["まった-く", "すべ-て"], ["seluruh", "semua", "all", "whole"], 6, "入", [
        ("全部", "zenbu", "semuanya"),
        ("全然", "zenzen", "sama sekali"),
        ("全国", "zenkoku", "seluruh negeri"),
    ], [
        ("全部食べました。", "Zenbu tabemashita.", "Saya makan semuanya."),
        ("全然分かりません。", "Zenzen wakarimasen.", "Sama sekali tidak mengerti."),
    ]),
    ("bu", "部", ["ブ"], [], ["bagian", "departemen", "part", "section"], 11, "阝", [
        ("部屋", "heya", "kamar"),
        ("全部", "zenbu", "semuanya"),
        ("部長", "buchou", "kepala departemen"),
    ], [
        ("部屋を掃除します。", "Heya o souji shimasu.", "Saya membersihkan kamar."),
        ("彼は営業部の部長です。", "Kare wa eigyoubu no buchou desu.", "Dia kepala departemen penjualan."),
    ]),
    ("chikai", "近", ["キン"], ["ちか-い"], ["dekat", "near", "close"], 7, "辶", [
        ("近い", "chikai", "dekat"),
        ("近く", "chikaku", "di dekat"),
        ("最近", "saikin", "akhir-akhir ini"),
    ], [
        ("駅は近いです。", "Eki wa chikai desu.", "Stasiunnya dekat."),
        ("最近忙しいです。", "Saikin isogashii desu.", "Akhir-akhir ini sibuk."),
    ]),
    ("tooi", "遠", ["エン", "オン"], ["とお-い"], ["jauh", "far"], 13, "辶", [
        ("遠い", "tooi", "jauh"),
        ("遠足", "ensoku", "tamasya/darmawisata"),
        ("遠慮", "enryo", "sungkan/segan"),
    ], [
        ("学校は遠いです。", "Gakkou wa tooi desu.", "Sekolahnya jauh."),
        ("明日、遠足があります。", "Ashita, ensoku ga arimasu.", "Besok ada tamasya."),
    ]),
    ("mi2", "実", ["ジツ"], ["み", "みの-る"], ["nyata", "buah", "kenyataan", "reality", "fruit"], 8, "宀", [
        ("実は", "jitsuwa", "sebenarnya"),
        ("実際", "jissai", "kenyataan"),
        ("事実", "jijitsu", "fakta"),
    ], [
        ("実は、明日休みます。", "Jitsuwa, ashita yasumimasu.", "Sebenarnya, besok saya libur."),
        ("それは事実です。", "Sore wa jijitsu desu.", "Itu fakta."),
    ]),
    ("zen3", "然", ["ゼン", "ネン"], [], ["begitu", "demikian", "so", "thus"], 12, "火", [
        ("全然", "zenzen", "sama sekali"),
        ("自然", "shizen", "alam"),
        ("当然", "touzen", "tentu saja"),
    ], [
        ("自然が好きです。", "Shizen ga suki desu.", "Saya suka alam."),
        ("それは当然です。", "Sore wa touzen desu.", "Itu sudah tentu."),
    ]),
    ("kyuu2", "究", ["キュウ"], ["きわ-める"], ["meneliti", "menyelidiki", "research", "investigate"], 7, "穴", [
        ("研究", "kenkyuu", "penelitian"),
        ("研究者", "kenkyuusha", "peneliti"),
        ("追究", "tsuikyuu", "penyelidikan mendalam"),
    ], [
        ("大学で研究しています。", "Daigaku de kenkyuu shite imasu.", "Saya melakukan penelitian di universitas."),
        ("彼は有名な研究者です。", "Kare wa yuumei na kenkyuusha desu.", "Dia peneliti terkenal."),
    ]),
    ("ken2", "研", ["ケン"], ["と-ぐ"], ["mengasah", "meneliti", "sharpen", "study"], 9, "石", [
        ("研究", "kenkyuu", "penelitian"),
        ("研修", "kenshuu", "pelatihan"),
        ("研究室", "kenkyuushitsu", "laboratorium/ruang riset"),
    ], [
        ("新入社員は研修を受けます。", "Shinnyuu shain wa kenshuu o ukemasu.", "Karyawan baru mengikuti pelatihan."),
        ("研究室で実験します。", "Kenkyuushitsu de jikken shimasu.", "Saya melakukan eksperimen di laboratorium."),
    ]),
    ("ri2", "理", ["リ"], [], ["alasan", "logika", "reason", "logic", "principle"], 11, "玉", [
        ("料理", "ryouri", "masakan"),
        ("理由", "riyuu", "alasan"),
        ("理解", "rikai", "pemahaman"),
    ], [
        ("理由を教えてください。", "Riyuu o oshiete kudasai.", "Tolong beritahu alasannya."),
        ("よく理解できました。", "Yoku rikai dekimashita.", "Saya bisa memahami dengan baik."),
    ]),
    ("ka2", "科", ["カ"], [], ["jurusan", "mata pelajaran", "department", "subject"], 9, "禾", [
        ("教科書", "kyoukasho", "buku pelajaran"),
        ("科学", "kagaku", "ilmu pengetahuan"),
        ("内科", "naika", "penyakit dalam"),
    ], [
        ("科学が好きです。", "Kagaku ga suki desu.", "Saya suka ilmu pengetahuan."),
        ("教科書を忘れました。", "Kyoukasho o wasuremashita.", "Saya lupa membawa buku pelajaran."),
    ]),
    ("ya2", "屋", ["オク"], ["や"], ["toko", "atap", "rumah", "shop", "roof"], 9, "尸", [
        ("屋根", "yane", "atap"),
        ("八百屋", "yaoya", "toko sayur"),
        ("部屋", "heya", "kamar"),
    ], [
        ("屋根の上に猫がいます。", "Yane no ue ni neko ga imasu.", "Ada kucing di atas atap."),
        ("八百屋で野菜を買いました。", "Yaoya de yasai o kaimashita.", "Saya membeli sayur di toko sayur."),
    ]),
    # --- Batch E: 台所業界計画品建起寝着洗続若忙漢進戻育服由自 (22) ---
    ("dai2", "台", ["ダイ", "タイ"], [], ["dudukan", "platform", "alas"], 5, "口", [
        ("台所", "daidokoro", "dapur"),
        ("一台", "ichidai", "satu unit (mesin)"),
        ("台風", "taifuu", "topan"),
    ], [
        ("台所で料理をします。", "Daidokoro de ryouri o shimasu.", "Saya memasak di dapur."),
        ("車が一台あります。", "Kuruma ga ichidai arimasu.", "Ada satu mobil."),
    ]),
    ("tokoro", "所", ["ショ"], ["ところ"], ["tempat", "place"], 8, "戸", [
        ("所", "tokoro", "tempat"),
        ("場所", "basho", "lokasi"),
        ("台所", "daidokoro", "dapur"),
    ], [
        ("ここはいい所です。", "Koko wa ii tokoro desu.", "Di sini tempat yang bagus."),
        ("集合場所はどこですか。", "Shuugou basho wa doko desu ka.", "Di mana tempat berkumpul?"),
    ]),
    ("gyou", "業", ["ギョウ", "ゴウ"], ["わざ"], ["usaha", "pekerjaan", "business", "work", "industry"], 13, "木", [
        ("授業", "jugyou", "pelajaran"),
        ("卒業", "sotsugyou", "kelulusan"),
        ("職業", "shokugyou", "pekerjaan/profesi"),
    ], [
        ("授業に遅れました。", "Jugyou ni okuremashita.", "Saya terlambat pelajaran."),
        ("来年卒業します。", "Rainen sotsugyou shimasu.", "Tahun depan saya lulus."),
    ]),
    ("kai2", "界", ["カイ"], [], ["dunia", "batas", "world", "boundary"], 9, "田", [
        ("世界", "sekai", "dunia"),
        ("業界", "gyoukai", "industri/dunia usaha"),
        ("限界", "genkai", "batas"),
    ], [
        ("世界を旅行したいです。", "Sekai o ryokou shitai desu.", "Saya ingin bepergian ke seluruh dunia."),
        ("私の忍耐は限界です。", "Watashi no nintai wa genkai desu.", "Kesabaran saya sudah mencapai batas."),
    ]),
    ("kei2", "計", ["ケイ"], ["はか-る"], ["mengukur", "merencanakan", "measure", "plan"], 9, "言", [
        ("時計", "tokei", "jam"),
        ("計画", "keikaku", "rencana"),
        ("合計", "goukei", "jumlah total"),
    ], [
        ("時計を見てください。", "Tokei o mite kudasai.", "Tolong lihat jam."),
        ("旅行の計画を立てます。", "Ryokou no keikaku o tatemasu.", "Saya membuat rencana perjalanan."),
    ]),
    ("ga2", "画", ["ガ", "カク"], [], ["gambar", "lukisan", "rencana", "picture", "plan"], 8, "田", [
        ("映画", "eiga", "film"),
        ("計画", "keikaku", "rencana"),
        ("絵画", "kaiga", "lukisan"),
    ], [
        ("映画を見ましょう。", "Eiga o mimashou.", "Ayo menonton film."),
        ("この絵画は美しいです。", "Kono kaiga wa utsukushii desu.", "Lukisan ini indah."),
    ]),
    ("hin", "品", ["ヒン"], ["しな"], ["barang", "produk", "goods", "item", "product"], 9, "口", [
        ("品物", "shinamono", "barang"),
        ("作品", "sakuhin", "karya"),
        ("商品", "shouhin", "produk"),
    ], [
        ("この品物はいくらですか。", "Kono shinamono wa ikura desu ka.", "Berapa harga barang ini?"),
        ("新しい商品が出ました。", "Atarashii shouhin ga demashita.", "Produk baru sudah keluar."),
    ]),
    ("tateru", "建", ["ケン", "コン"], ["た-てる", "た-つ"], ["membangun", "build", "construct"], 9, "廴", [
        ("建てる", "tateru", "membangun"),
        ("建物", "tatemono", "bangunan"),
        ("建設", "kensetsu", "konstruksi"),
    ], [
        ("新しい家を建てます。", "Atarashii ie o tatemasu.", "Saya membangun rumah baru."),
        ("あの建物は高いです。", "Ano tatemono wa takai desu.", "Bangunan itu tinggi."),
    ]),
    ("okiru", "起", ["キ"], ["お-きる", "お-こる"], ["bangun", "terjadi", "rise", "get up", "occur"], 10, "走", [
        ("起きる", "okiru", "bangun"),
        ("起こる", "okoru", "terjadi"),
        ("早起き", "hayaoki", "bangun pagi"),
    ], [
        ("六時に起きます。", "Rokuji ni okimasu.", "Saya bangun jam enam."),
        ("事故が起こりました。", "Jiko ga okorimashita.", "Kecelakaan terjadi."),
    ]),
    ("neru", "寝", ["シン"], ["ね-る"], ["tidur", "sleep"], 13, "宀", [
        ("寝る", "neru", "tidur"),
        ("寝室", "shinshitsu", "kamar tidur"),
        ("昼寝", "hirune", "tidur siang"),
    ], [
        ("十時に寝ます。", "Juuji ni nemasu.", "Saya tidur jam sepuluh."),
        ("昼寝をしました。", "Hirune o shimashita.", "Saya tidur siang."),
    ]),
    ("kiru2", "着", ["チャク", "ジャク"], ["き-る", "つ-く"], ["memakai", "tiba", "wear", "arrive"], 12, "目", [
        ("着る", "kiru", "memakai (baju)"),
        ("到着", "touchaku", "kedatangan"),
        ("着く", "tsuku", "tiba"),
    ], [
        ("コートを着ます。", "Kooto o kimasu.", "Saya memakai mantel."),
        ("駅に着きました。", "Eki ni tsukimashita.", "Saya sudah tiba di stasiun."),
    ]),
    ("arau", "洗", ["セン"], ["あら-う"], ["mencuci", "wash"], 9, "水", [
        ("洗う", "arau", "mencuci"),
        ("洗濯", "sentaku", "cucian"),
        ("洗面所", "senmenjo", "tempat cuci muka/toilet"),
    ], [
        ("手を洗います。", "Te o araimasu.", "Saya mencuci tangan."),
        ("毎日洗濯をします。", "Mainichi sentaku o shimasu.", "Setiap hari saya mencuci baju."),
    ]),
    ("tsuzuku", "続", ["ゾク"], ["つづ-く", "つづ-ける"], ["berlanjut", "melanjutkan", "continue"], 13, "糸", [
        ("続く", "tsuzuku", "berlanjut"),
        ("続ける", "tsuzukeru", "melanjutkan"),
        ("継続", "keizoku", "kelanjutan"),
    ], [
        ("雨が続いています。", "Ame ga tsuzuite imasu.", "Hujan masih berlanjut."),
        ("勉強を続けます。", "Benkyou o tsuzukemasu.", "Saya akan melanjutkan belajar."),
    ]),
    ("wakai", "若", ["ジャク", "ニャク"], ["わか-い"], ["muda", "young"], 8, "艹", [
        ("若い", "wakai", "muda"),
        ("若者", "wakamono", "anak muda"),
        ("若干", "jakkan", "sedikit/agak"),
    ], [
        ("彼女は若いです。", "Kanojo wa wakai desu.", "Dia masih muda."),
        ("若者に人気の店です。", "Wakamono ni ninki no mise desu.", "Toko yang populer di kalangan anak muda."),
    ]),
    ("isogashii2", "忙", ["ボウ"], ["いそが-しい"], ["sibuk", "busy"], 6, "心", [
        ("忙しい", "isogashii", "sibuk"),
        ("大忙し", "ooisogashi", "sangat sibuk"),
        ("忙しさ", "isogashisa", "kesibukan"),
    ], [
        ("今週は忙しいです。", "Konshuu wa isogashii desu.", "Minggu ini sibuk."),
        ("最近大忙しです。", "Saikin ooisogashi desu.", "Akhir-akhir ini sangat sibuk."),
    ]),
    ("kan2", "漢", ["カン"], [], ["Tiongkok (kuno)", "Han", "China (ancient)"], 13, "水", [
        ("漢字", "kanji", "kanji"),
        ("漢方", "kanpou", "pengobatan tradisional Tiongkok"),
        ("漢語", "kango", "kata serapan Tiongkok"),
    ], [
        ("漢字を勉強します。", "Kanji o benkyou shimasu.", "Saya belajar kanji."),
        ("漢方薬を飲みました。", "Kanpouyaku o nomimashita.", "Saya minum obat tradisional Tiongkok."),
    ]),
    ("susumu", "進", ["シン"], ["すす-む", "すす-める"], ["maju", "advance", "proceed"], 11, "辶", [
        ("進む", "susumu", "maju"),
        ("進歩", "shinpo", "kemajuan"),
        ("前進", "zenshin", "maju ke depan"),
    ], [
        ("前に進んでください。", "Mae ni susunde kudasai.", "Tolong maju ke depan."),
        ("技術が進歩しました。", "Gijutsu ga shinpo shimashita.", "Teknologi mengalami kemajuan."),
    ]),
    ("modoru", "戻", ["レイ"], ["もど-る", "もど-す"], ["kembali", "return"], 7, "戸", [
        ("戻る", "modoru", "kembali"),
        ("戻す", "modosu", "mengembalikan"),
        ("払い戻し", "haraimodoshi", "pengembalian uang"),
    ], [
        ("家に戻ります。", "Ie ni modorimasu.", "Saya kembali ke rumah."),
        ("本を棚に戻してください。", "Hon o tana ni modoshite kudasai.", "Tolong kembalikan buku ke rak."),
    ]),
    ("sodatsu", "育", ["イク"], ["そだ-つ", "そだ-てる"], ["membesarkan", "tumbuh", "raise", "grow"], 8, "月", [
        ("育てる", "sodateru", "membesarkan"),
        ("教育", "kyouiku", "pendidikan"),
        ("体育", "taiiku", "olahraga"),
    ], [
        ("子供を育てています。", "Kodomo o sodatete imasu.", "Saya membesarkan anak."),
        ("教育は大切です。", "Kyouiku wa taisetsu desu.", "Pendidikan itu penting."),
    ]),
    ("fuku2", "服", ["フク"], [], ["pakaian", "clothes"], 8, "月", [
        ("服", "fuku", "pakaian"),
        ("洋服", "youfuku", "pakaian barat"),
        ("制服", "seifuku", "seragam"),
    ], [
        ("新しい服を買いました。", "Atarashii fuku o kaimashita.", "Saya membeli baju baru."),
        ("学校の制服を着ます。", "Gakkou no seifuku o kimasu.", "Saya memakai seragam sekolah."),
    ]),
    ("yu2", "由", ["ユ", "ユウ", "ユイ"], ["よし"], ["alasan", "sebab", "reason", "cause"], 5, "田", [
        ("理由", "riyuu", "alasan"),
        ("自由", "jiyuu", "kebebasan"),
        ("由来", "yurai", "asal-usul"),
    ], [
        ("理由を説明してください。", "Riyuu o setsumei shite kudasai.", "Tolong jelaskan alasannya."),
        ("自由な時間が欲しいです。", "Jiyuu na jikan ga hoshii desu.", "Saya ingin waktu bebas."),
    ]),
    ("jibun", "自", ["ジ", "シ"], ["みずか-ら"], ["diri sendiri", "self"], 6, "自", [
        ("自分", "jibun", "diri sendiri"),
        ("自由", "jiyuu", "kebebasan"),
        ("自動車", "jidousha", "mobil"),
    ], [
        ("自分で作りました。", "Jibun de tsukurimashita.", "Saya membuatnya sendiri."),
        ("自動車を運転します。", "Jidousha o unten shimasu.", "Saya mengemudikan mobil."),
    ]),
    # --- Batch F: 利用悲族的表現在合悪苦感質問題例返答正様困 (21) ---
    ("ri3", "利", ["リ"], ["き-く"], ["untung", "manfaat", "profit", "advantage", "benefit"], 7, "刂", [
        ("便利", "benri", "praktis"),
        ("利用", "riyou", "pemanfaatan"),
        ("利益", "rieki", "keuntungan"),
    ], [
        ("この道具は便利です。", "Kono dougu wa benri desu.", "Alat ini praktis."),
        ("図書館を利用します。", "Toshokan o riyou shimasu.", "Saya memanfaatkan perpustakaan."),
    ]),
    ("you3", "用", ["ヨウ"], ["もち-いる"], ["menggunakan", "urusan", "use", "business", "task"], 5, "用", [
        ("使用", "shiyou", "penggunaan"),
        ("利用", "riyou", "pemanfaatan"),
        ("用事", "youji", "urusan"),
    ], [
        ("このパソコンを使用します。", "Kono pasokon o shiyou shimasu.", "Saya menggunakan komputer ini."),
        ("今日は用事があります。", "Kyou wa youji ga arimasu.", "Hari ini saya ada urusan."),
    ]),
    ("kanashii", "悲", ["ヒ"], ["かな-しい"], ["sedih", "sad"], 12, "心", [
        ("悲しい", "kanashii", "sedih"),
        ("悲しみ", "kanashimi", "kesedihan"),
        ("悲劇", "higeki", "tragedi"),
    ], [
        ("そのニュースを聞いて悲しいです。", "Sono nyuusu o kiite kanashii desu.", "Saya sedih mendengar berita itu."),
        ("これは悲しい映画です。", "Kore wa kanashii eiga desu.", "Ini film yang sedih."),
    ]),
    ("zoku2", "族", ["ゾク"], [], ["keluarga", "suku", "clan", "family", "tribe"], 11, "方", [
        ("家族", "kazoku", "keluarga"),
        ("民族", "minzoku", "suku bangsa"),
        ("親族", "shinzoku", "kerabat"),
    ], [
        ("家族と旅行しました。", "Kazoku to ryokou shimashita.", "Saya bepergian bersama keluarga."),
        ("多くの民族がいます。", "Ooku no minzoku ga imasu.", "Ada banyak suku bangsa."),
    ]),
    ("teki", "的", ["テキ"], ["まと"], ["sasaran", "-seperti", "target", "-like"], 8, "白", [
        ("目的", "mokuteki", "tujuan"),
        ("一般的", "ippanteki", "umum"),
        ("的", "mato", "sasaran"),
    ], [
        ("旅行の目的は何ですか。", "Ryokou no mokuteki wa nan desu ka.", "Apa tujuan perjalanan Anda?"),
        ("それは一般的な考え方です。", "Sore wa ippanteki na kangaekata desu.", "Itu cara berpikir yang umum."),
    ]),
    ("arawasu", "表", ["ヒョウ"], ["おもて", "あらわ-す"], ["permukaan", "tabel", "menyatakan", "surface", "table"], 8, "衣", [
        ("表す", "arawasu", "menyatakan"),
        ("表", "hyou", "tabel"),
        ("発表", "happyou", "presentasi"),
    ], [
        ("気持ちを表します。", "Kimochi o arawashimasu.", "Saya menyatakan perasaan."),
        ("明日、発表があります。", "Ashita, happyou ga arimasu.", "Besok ada presentasi."),
    ]),
    ("arawareru", "現", ["ゲン"], ["あらわ-れる", "あらわ-す"], ["muncul", "sekarang", "appear", "present", "current"], 11, "玉", [
        ("現れる", "arawareru", "muncul"),
        ("現在", "genzai", "saat ini"),
        ("表現", "hyougen", "ekspresi"),
    ], [
        ("突然、猫が現れました。", "Totsuzen, neko ga arawaremashita.", "Tiba-tiba, seekor kucing muncul."),
        ("現在、東京に住んでいます。", "Genzai, Toukyou ni sunde imasu.", "Saat ini, saya tinggal di Tokyo."),
    ]),
    ("zai", "在", ["ザイ"], ["あ-る"], ["berada", "ada", "exist", "be present"], 6, "土", [
        ("現在", "genzai", "saat ini"),
        ("存在", "sonzai", "keberadaan"),
        ("在学", "zaigaku", "sedang bersekolah"),
    ], [
        ("現在、大学生です。", "Genzai, daigakusei desu.", "Saat ini, saya mahasiswa."),
        ("彼の存在を知りませんでした。", "Kare no sonzai o shirimasen deshita.", "Saya tidak tahu keberadaannya."),
    ]),
    ("au2", "合", ["ゴウ", "ガッ"], ["あ-う", "あ-わせる"], ["cocok", "menggabungkan", "fit", "match", "combine"], 6, "口", [
        ("合う", "au", "cocok"),
        ("合わせる", "awaseru", "menggabungkan"),
        ("都合", "tsugou", "kondisi/kesempatan"),
    ], [
        ("このサイズは合いません。", "Kono saizu wa aimasen.", "Ukuran ini tidak cocok."),
        ("ご都合はいかがですか。", "Gotsugou wa ikaga desu ka.", "Bagaimana kondisi/kesempatan Anda?"),
    ]),
    ("warui", "悪", ["アク", "オ"], ["わる-い"], ["buruk", "jahat", "bad", "evil"], 11, "心", [
        ("悪い", "warui", "buruk/jahat"),
        ("悪天候", "akutenkou", "cuaca buruk"),
        ("意地悪", "ijiwaru", "jahil/jahat"),
    ], [
        ("天気が悪いです。", "Tenki ga warui desu.", "Cuacanya buruk."),
        ("それは意地悪です。", "Sore wa ijiwaru desu.", "Itu jahil."),
    ]),
    ("kurushii", "苦", ["ク"], ["くる-しい", "にが-い"], ["pahit", "menderita", "susah", "bitter", "suffer"], 8, "艹", [
        ("苦しい", "kurushii", "menderita/sulit"),
        ("苦い", "nigai", "pahit"),
        ("苦手", "nigate", "tidak jago/kurang suka"),
    ], [
        ("数学が苦手です。", "Suugaku ga nigate desu.", "Saya tidak jago matematika."),
        ("この薬は苦いです。", "Kono kusuri wa nigai desu.", "Obat ini pahit."),
    ]),
    ("kan3", "感", ["カン"], [], ["merasa", "perasaan", "feel", "feeling", "sense"], 13, "心", [
        ("感じる", "kanjiru", "merasakan"),
        ("感動", "kandou", "terharu/tersentuh"),
        ("感謝", "kansha", "rasa terima kasih"),
    ], [
        ("寒さを感じます。", "Samusa o kanjimasu.", "Saya merasa dingin."),
        ("その映画に感動しました。", "Sono eiga ni kandou shimashita.", "Saya terharu dengan film itu."),
    ]),
    ("shitsu2", "質", ["シツ", "シチ", "チ"], [], ["kualitas", "sifat", "quality", "nature", "substance"], 15, "貝", [
        ("質問", "shitsumon", "pertanyaan"),
        ("品質", "hinshitsu", "kualitas"),
        ("性質", "seishitsu", "sifat"),
    ], [
        ("質問があります。", "Shitsumon ga arimasu.", "Saya ada pertanyaan."),
        ("この製品は品質がいいです。", "Kono seihin wa hinshitsu ga ii desu.", "Produk ini kualitasnya bagus."),
    ]),
    ("mon2", "問", ["モン"], ["と-う"], ["bertanya", "ask", "question"], 11, "口", [
        ("質問", "shitsumon", "pertanyaan"),
        ("問題", "mondai", "masalah/soal"),
        ("問う", "tou", "bertanya"),
    ], [
        ("質問してもいいですか。", "Shitsumon shite mo ii desu ka.", "Boleh saya bertanya?"),
        ("この問題は難しいです。", "Kono mondai wa muzukashii desu.", "Soal ini sulit."),
    ]),
    ("dai3", "題", ["ダイ"], [], ["judul", "topik", "title", "topic", "subject"], 18, "頁", [
        ("問題", "mondai", "masalah/soal"),
        ("宿題", "shukudai", "pekerjaan rumah"),
        ("話題", "wadai", "topik pembicaraan"),
    ], [
        ("宿題を忘れました。", "Shukudai o wasuremashita.", "Saya lupa mengerjakan PR."),
        ("面白い話題ですね。", "Omoshiroi wadai desu ne.", "Topik yang menarik ya."),
    ]),
    ("rei2", "例", ["レイ"], ["たと-える"], ["contoh", "example"], 8, "人", [
        ("例えば", "tatoeba", "misalnya"),
        ("例", "rei", "contoh"),
        ("実例", "jitsurei", "contoh nyata"),
    ], [
        ("例えば、りんごやみかんが好きです。", "Tatoeba, ringo ya mikan ga suki desu.", "Misalnya, saya suka apel dan jeruk."),
        ("具体的な例を教えてください。", "Gutaiteki na rei o oshiete kudasai.", "Tolong beri contoh konkret."),
    ]),
    ("kaesu", "返", ["ヘン"], ["かえ-す", "かえ-る"], ["mengembalikan", "return", "give back"], 7, "辶", [
        ("返す", "kaesu", "mengembalikan"),
        ("返事", "henji", "balasan"),
        ("返答", "hentou", "jawaban"),
    ], [
        ("本を返します。", "Hon o kaeshimasu.", "Saya mengembalikan buku."),
        ("まだ返事がありません。", "Mada henji ga arimasen.", "Belum ada balasan."),
    ]),
    ("kotaeru", "答", ["トウ"], ["こた-える"], ["menjawab", "jawaban", "answer"], 12, "竹", [
        ("答える", "kotaeru", "menjawab"),
        ("答え", "kotae", "jawaban"),
        ("返答", "hentou", "jawaban"),
    ], [
        ("質問に答えます。", "Shitsumon ni kotaemasu.", "Saya menjawab pertanyaan."),
        ("答えが分かりません。", "Kotae ga wakarimasen.", "Saya tidak tahu jawabannya."),
    ]),
    ("tadashii", "正", ["セイ", "ショウ"], ["ただ-しい", "まさ"], ["benar", "correct", "right"], 5, "止", [
        ("正しい", "tadashii", "benar"),
        ("正月", "shougatsu", "tahun baru"),
        ("正直", "shoujiki", "jujur"),
    ], [
        ("あなたの答えは正しいです。", "Anata no kotae wa tadashii desu.", "Jawaban Anda benar."),
        ("正直に話してください。", "Shoujiki ni hanashite kudasai.", "Tolong bicara dengan jujur."),
    ]),
    ("sama", "様", ["ヨウ"], ["さま"], ["cara", "rupa", "Tuan/Nyonya (sopan)", "manner", "way"], 14, "木", [
        ("皆様", "minasama", "semua (sopan)"),
        ("様子", "yousu", "keadaan"),
        ("同様", "douyou", "sama saja"),
    ], [
        ("皆様、こんにちは。", "Minasama, konnichiwa.", "Semuanya, halo."),
        ("彼の様子がおかしいです。", "Kare no yousu ga okashii desu.", "Keadaan dia aneh."),
    ]),
    ("komaru", "困", ["コン"], ["こま-る"], ["kesulitan", "bingung", "troubled", "in difficulty"], 7, "囗", [
        ("困る", "komaru", "kesulitan/bingung"),
        ("困難", "konnan", "kesulitan"),
        ("貧困", "hinkon", "kemiskinan"),
    ], [
        ("お金がなくて困っています。", "Okane ga nakute komatte imasu.", "Saya kesulitan karena tidak punya uang."),
        ("これは困難な問題です。", "Kore wa konnan na mondai desu.", "Ini masalah yang sulit."),
    ]),
]

# N3 (Batch 9). N3_CHARACTERS in kanji_char_lists.py locks the full 315-kanji
# scope up front (same pattern as N5+N4); content below is authored
# incrementally in batches against that list — this is Batch A (22 kanji),
# not the complete set. Suffixes carry an "_n3" tag since a few of these
# characters' natural romaji readings (e.g. "sen" for both 選 and 戦) would
# otherwise collide with suffixes already used in N5_KANJI/N4_KANJI.
N3_KANJI = [
    ("sei_n3", "政", ["セイ", "ショウ"], ["まつりごと"], ["politik", "pemerintahan", "politics", "government"], 9, "攵", [
        ("政治", "seiji", "politik"),
        ("政府", "seifu", "pemerintah"),
        ("行政", "gyousei", "administrasi"),
    ], [
        ("彼は政治に興味があります。", "Kare wa seiji ni kyoumi ga arimasu.", "Dia tertarik pada politik."),
        ("政府は新しい法律を作りました。", "Seifu wa atarashii houritsu o tsukurimashita.", "Pemerintah membuat undang-undang baru."),
    ]),
    ("gi_n3", "議", ["ギ"], [], ["musyawarah", "diskusi", "deliberation", "discussion"], 20, "言", [
        ("会議", "kaigi", "rapat"),
        ("議論", "giron", "diskusi/perdebatan"),
        ("議員", "giin", "anggota dewan"),
    ], [
        ("明日、大切な会議があります。", "Ashita, taisetsu na kaigi ga arimasu.", "Besok ada rapat penting."),
        ("この問題について議論しましょう。", "Kono mondai ni tsuite giron shimashou.", "Ayo kita diskusikan masalah ini."),
    ]),
    ("min_n3", "民", ["ミン"], ["たみ"], ["rakyat", "bangsa", "people", "nation"], 5, "氏", [
        ("国民", "kokumin", "warga negara"),
        ("民間", "minkan", "swasta/sipil"),
        ("市民", "shimin", "warga kota"),
    ], [
        ("国民の意見を聞くことが大切です。", "Kokumin no iken o kiku koto ga taisetsu desu.", "Penting untuk mendengarkan pendapat rakyat."),
        ("彼女はこの町の市民です。", "Kanojo wa kono machi no shimin desu.", "Dia adalah warga kota ini."),
    ]),
    ("ren_n3", "連", ["レン"], ["つら-なる", "つら-ねる", "つ-れる"], ["menghubungkan", "membawa serta", "connect", "take along"], 10, "辶", [
        ("連絡", "renraku", "kontak/menghubungi"),
        ("連休", "renkyuu", "libur panjang"),
        ("連れる", "tsureru", "membawa (seseorang)"),
    ], [
        ("後で連絡します。", "Atode renraku shimasu.", "Saya akan menghubungi Anda nanti."),
        ("来週は三連休です。", "Raishuu wa san-renkyuu desu.", "Minggu depan libur tiga hari berturut-turut."),
    ]),
    ("tai_n3", "対", ["タイ", "ツイ"], [], ["lawan", "terhadap", "versus", "opposite"], 7, "寸", [
        ("反対", "hantai", "menentang/berlawanan"),
        ("絶対", "zettai", "mutlak/pasti"),
        ("対応", "taiou", "menangani/merespons"),
    ], [
        ("私はその意見に反対です。", "Watashi wa sono iken ni hantai desu.", "Saya menentang pendapat itu."),
        ("これは絶対に必要です。", "Kore wa zettai ni hitsuyou desu.", "Ini pasti diperlukan."),
    ]),
    ("shi_n3", "市", ["シ"], ["いち"], ["kota", "pasar", "city", "market"], 5, "巾", [
        ("市場", "ichiba", "pasar"),
        ("市民", "shimin", "warga kota"),
        ("都市", "toshi", "kota besar"),
    ], [
        ("毎朝市場で野菜を買います。", "Maiasa ichiba de yasai o kaimasu.", "Setiap pagi saya membeli sayur di pasar."),
        ("東京は大きい都市です。", "Toukyou wa ookii toshi desu.", "Tokyo adalah kota besar."),
    ]),
    ("nai_n3", "内", ["ナイ", "ダイ"], ["うち"], ["dalam", "di antara", "inside", "within"], 4, "冂", [
        ("内容", "naiyou", "isi/konten"),
        ("案内", "annai", "panduan/pemandu"),
        ("家内", "kanai", "istri (saya)"),
    ], [
        ("この本の内容は面白いです。", "Kono hon no naiyou wa omoshiroi desu.", "Isi buku ini menarik."),
        ("駅まで案内してください。", "Eki made annai shite kudasai.", "Tolong tunjukkan jalan ke stasiun."),
    ]),
    ("sou_n3", "相", ["ソウ", "ショウ"], ["あい"], ["saling", "bersama", "mutual", "each other"], 9, "目", [
        ("相談", "soudan", "konsultasi"),
        ("相手", "aite", "lawan bicara/partner"),
        ("首相", "shushou", "perdana menteri"),
    ], [
        ("先生に相談しました。", "Sensei ni soudan shimashita.", "Saya berkonsultasi dengan guru."),
        ("彼は私の話し相手です。", "Kare wa watashi no hanashiaite desu.", "Dia adalah teman bicara saya."),
    ]),
    ("tei_n3", "定", ["テイ", "ジョウ"], ["さだ-める", "さだ-まる"], ["menetapkan", "memutuskan", "determine", "fix"], 8, "宀", [
        ("予定", "yotei", "jadwal/rencana"),
        ("決定", "kettei", "keputusan"),
        ("安定", "antei", "stabil"),
    ], [
        ("明日の予定は何ですか。", "Ashita no yotei wa nan desu ka.", "Apa rencana Anda besok?"),
        ("会議の日程が決定しました。", "Kaigi no nittei ga kettei shimashita.", "Jadwal rapat sudah diputuskan."),
    ]),
    ("kai_n3", "回", ["カイ", "エ"], ["まわ-る", "まわ-す"], ["kali", "putaran", "times", "round"], 6, "囗", [
        ("今回", "konkai", "kali ini"),
        ("回る", "mawaru", "berputar"),
        ("一回", "ikkai", "satu kali"),
    ], [
        ("今回は特別なイベントです。", "Konkai wa tokubetsu na ibento desu.", "Kali ini acara spesial."),
        ("一回だけ試してみます。", "Ikkai dake tameshite mimasu.", "Saya akan coba satu kali saja."),
    ]),
    ("sen_n3", "選", ["セン"], ["えら-ぶ"], ["memilih", "seleksi", "select", "choose"], 15, "辶", [
        ("選挙", "senkyo", "pemilihan umum"),
        ("選ぶ", "erabu", "memilih"),
        ("選手", "senshu", "atlet"),
    ], [
        ("好きな色を選んでください。", "Suki na iro o erande kudasai.", "Silakan pilih warna favorit Anda."),
        ("来月、選挙があります。", "Raigetsu, senkyo ga arimasu.", "Bulan depan ada pemilihan umum."),
    ]),
    ("bei_n3", "米", ["ベイ", "マイ"], ["こめ"], ["beras", "Amerika", "rice", "USA"], 6, "米", [
        ("米", "kome", "beras"),
        ("米国", "beikoku", "Amerika Serikat"),
        ("玄米", "genmai", "beras merah"),
    ], [
        ("この田んぼで米を作っています。", "Kono tanbo de kome o tsukutte imasu.", "Di sawah ini menanam padi/beras."),
        ("彼は米国で働いています。", "Kare wa beikoku de hataraite imasu.", "Dia bekerja di Amerika Serikat."),
    ]),
    ("kan_n3", "関", ["カン"], ["せき", "かか-わる"], ["hubungan", "berkaitan", "connection", "involve"], 14, "門", [
        ("関係", "kankei", "hubungan"),
        ("関する", "kansuru", "berkaitan dengan"),
        ("玄関", "genkan", "pintu masuk rumah"),
    ], [
        ("二人はいい関係です。", "Futari wa ii kankei desu.", "Hubungan mereka berdua baik."),
        ("この本は歴史に関する内容です。", "Kono hon wa rekishi ni kansuru naiyou desu.", "Buku ini berisi tentang sejarah."),
    ]),
    ("sen2_n3", "戦", ["セン"], ["いくさ", "たたか-う"], ["perang", "pertandingan", "war", "battle/match"], 13, "戈", [
        ("戦争", "sensou", "perang"),
        ("戦う", "tatakau", "bertarung/bertanding"),
        ("挑戦", "chousen", "tantangan"),
    ], [
        ("戦争は悲しいことです。", "Sensou wa kanashii koto desu.", "Perang adalah hal yang menyedihkan."),
        ("新しいことに挑戦したいです。", "Atarashii koto ni chousen shitai desu.", "Saya ingin menantang diri dengan hal baru."),
    ]),
    ("kei_n3", "経", ["ケイ", "キョウ"], ["へ-る"], ["melewati", "pengalaman", "pass through", "experience"], 11, "糸", [
        ("経験", "keiken", "pengalaman"),
        ("経済", "keizai", "ekonomi"),
        ("経つ", "tatsu", "berlalu (waktu)"),
    ], [
        ("いい経験になりました。", "Ii keiken ni narimashita.", "Ini menjadi pengalaman yang baik."),
        ("大学で経済を勉強しています。", "Daigaku de keizai o benkyou shite imasu.", "Saya belajar ekonomi di universitas."),
    ]),
    ("sai_n3", "最", ["サイ"], ["もっと-も"], ["paling", "ter-", "most", "utmost"], 12, "日", [
        ("最初", "saisho", "pertama/awal"),
        ("最後", "saigo", "terakhir"),
        ("最近", "saikin", "belakangan ini"),
    ], [
        ("最初に自己紹介をします。", "Saisho ni jikoshoukai o shimasu.", "Pertama-tama saya akan memperkenalkan diri."),
        ("最近、忙しいです。", "Saikin, isogashii desu.", "Belakangan ini saya sibuk."),
    ]),
    ("chou_n3", "調", ["チョウ"], ["しら-べる", "ととの-う"], ["memeriksa", "menyelidiki", "investigate", "tune"], 15, "言", [
        ("調べる", "shiraberu", "memeriksa/menyelidiki"),
        ("調子", "choushi", "kondisi"),
        ("調理", "chouri", "memasak"),
    ], [
        ("図書館で調べます。", "Toshokan de shirabemasu.", "Saya akan memeriksa di perpustakaan."),
        ("今日は体の調子がいいです。", "Kyou wa karada no choushi ga ii desu.", "Kondisi tubuh saya hari ini baik."),
    ]),
    ("ka_n3", "化", ["カ", "ケ"], ["ば-ける"], ["perubahan", "-isasi", "change", "-ization"], 4, "匕", [
        ("変化", "henka", "perubahan"),
        ("文化", "bunka", "budaya"),
        ("化粧", "keshou", "riasan"),
    ], [
        ("天気が急に変化しました。", "Tenki ga kyuu ni henka shimashita.", "Cuaca berubah tiba-tiba."),
        ("日本の文化に興味があります。", "Nihon no bunka ni kyoumi ga arimasu.", "Saya tertarik pada budaya Jepang."),
    ]),
    ("tou_n3", "当", ["トウ"], ["あ-たる", "あ-てる"], ["mengenai", "tepat", "hit", "appropriate"], 6, "小", [
        ("本当", "hontou", "benar/sungguh"),
        ("当たる", "ataru", "kena/mengenai"),
        ("担当", "tantou", "penanggung jawab"),
    ], [
        ("それは本当ですか。", "Sore wa hontou desu ka.", "Apakah itu benar?"),
        ("天気予報が当たりました。", "Tenki yohou ga atarimashita.", "Ramalan cuaca itu tepat."),
    ]),
    ("yaku_n3", "約", ["ヤク"], [], ["janji", "kira-kira", "promise", "approximately"], 9, "糸", [
        ("約束", "yakusoku", "janji"),
        ("予約", "yoyaku", "reservasi"),
        ("約", "yaku", "kira-kira/sekitar"),
    ], [
        ("友達と約束しました。", "Tomodachi to yakusoku shimashita.", "Saya membuat janji dengan teman."),
        ("レストランを予約しました。", "Resutoran o yoyaku shimashita.", "Saya sudah reservasi restoran."),
    ]),
    ("shu_n3", "首", ["シュ"], ["くび"], ["leher", "kepala (pemimpin)", "neck"], 9, "首", [
        ("首", "kubi", "leher"),
        ("首相", "shushou", "perdana menteri"),
        ("首都", "shuto", "ibu kota"),
    ], [
        ("首が痛いです。", "Kubi ga itai desu.", "Leher saya sakit."),
        ("ジャカルタはインドネシアの首都です。", "Jakaruta wa Indoneshia no shuto desu.", "Jakarta adalah ibu kota Indonesia."),
    ]),
    ("hou_n3", "法", ["ホウ", "ハッ"], [], ["hukum", "metode", "law", "method"], 8, "氵", [
        ("方法", "houhou", "cara/metode"),
        ("法律", "houritsu", "hukum/undang-undang"),
        ("文法", "bunpou", "tata bahasa"),
    ], [
        ("いい方法を考えましょう。", "Ii houhou o kangaemashou.", "Ayo pikirkan cara yang baik."),
        ("この法律は難しいです。", "Kono houritsu wa muzukashii desu.", "Undang-undang ini sulit."),
    ]),
    # --- Batch B: 性要制治務成期取都和機平加受数記初指権支産点 (22) ---
    ("sei2_n3", "性", ["セイ", "ショウ"], ["さが"], ["sifat", "jenis kelamin", "nature", "gender"], 8, "忄", [
        ("性格", "seikaku", "kepribadian"),
        ("女性", "josei", "wanita"),
        ("可能性", "kanousei", "kemungkinan"),
    ], [
        ("彼の性格はとても優しいです。", "Kare no seikaku wa totemo yasashii desu.", "Kepribadiannya sangat baik hati."),
        ("この計画には可能性があります。", "Kono keikaku ni wa kanousei ga arimasu.", "Rencana ini memiliki kemungkinan berhasil."),
    ]),
    ("you_n3", "要", ["ヨウ"], ["い-る"], ["perlu", "penting", "need", "main point"], 9, "覀", [
        ("必要", "hitsuyou", "diperlukan"),
        ("重要", "juuyou", "penting"),
        ("要素", "youso", "elemen/unsur"),
    ], [
        ("このプロジェクトにはお金が必要です。", "Kono purojekuto ni wa okane ga hitsuyou desu.", "Proyek ini memerlukan uang."),
        ("健康はとても重要です。", "Kenkou wa totemo juuyou desu.", "Kesehatan sangat penting."),
    ]),
    ("sei3_n3", "制", ["セイ"], [], ["sistem", "aturan", "system", "rule"], 8, "刂", [
        ("制度", "seido", "sistem"),
        ("制服", "seifuku", "seragam"),
        ("制作", "seisaku", "produksi/pembuatan"),
    ], [
        ("この学校の制度は厳しいです。", "Kono gakkou no seido wa kibishii desu.", "Sistem sekolah ini ketat."),
        ("学生は制服を着ます。", "Gakusei wa seifuku o kimasu.", "Siswa memakai seragam."),
    ]),
    ("ji_n3", "治", ["ジ", "チ"], ["おさ-める", "なお-る"], ["mengobati", "memerintah", "cure", "govern"], 8, "氵", [
        ("政治", "seiji", "politik"),
        ("治る", "naoru", "sembuh"),
        ("治療", "chiryou", "pengobatan"),
    ], [
        ("政治のニュースを見ます。", "Seiji no nyuusu o mimasu.", "Saya menonton berita politik."),
        ("風邪が治りました。", "Kaze ga naorimashita.", "Pilek saya sudah sembuh."),
    ]),
    ("mu_n3", "務", ["ム"], ["つと-める"], ["tugas", "kewajiban", "task", "duty"], 11, "力", [
        ("事務所", "jimusho", "kantor"),
        ("義務", "gimu", "kewajiban"),
        ("勤務", "kinmu", "bekerja/dinas"),
    ], [
        ("事務所で働いています。", "Jimusho de hataraite imasu.", "Saya bekerja di kantor."),
        ("税金を払うのは国民の義務です。", "Zeikin o harau no wa kokumin no gimu desu.", "Membayar pajak adalah kewajiban warga negara."),
    ]),
    ("sei4_n3", "成", ["セイ", "ジョウ"], ["な-る"], ["menjadi", "tercapai", "become", "accomplish"], 6, "戈", [
        ("成功", "seikou", "kesuksesan"),
        ("成長", "seichou", "pertumbuhan"),
        ("完成", "kansei", "penyelesaian"),
    ], [
        ("彼のビジネスは成功しました。", "Kare no bijinesu wa seikou shimashita.", "Bisnisnya sukses."),
        ("子供はすぐに成長します。", "Kodomo wa sugu ni seichou shimasu.", "Anak-anak cepat tumbuh."),
    ]),
    ("ki_n3", "期", ["キ", "ゴ"], [], ["periode", "jangka waktu", "period", "term"], 12, "月", [
        ("時期", "jiki", "waktu/periode"),
        ("期間", "kikan", "jangka waktu"),
        ("期待", "kitai", "harapan/ekspektasi"),
    ], [
        ("今は忙しい時期です。", "Ima wa isogashii jiki desu.", "Sekarang adalah waktu yang sibuk."),
        ("期待しています。", "Kitai shite imasu.", "Saya berharap/menantikan."),
    ]),
    ("shu2_n3", "取", ["シュ"], ["と-る"], ["mengambil", "take", "fetch"], 8, "又", [
        ("取る", "toru", "mengambil"),
        ("受け取る", "uketoru", "menerima"),
        ("取材", "shuzai", "peliputan"),
    ], [
        ("棚から本を取ってください。", "Tana kara hon o totte kudasai.", "Tolong ambilkan buku dari rak."),
        ("荷物を受け取りました。", "Nimotsu o uketorimashita.", "Saya sudah menerima barangnya."),
    ]),
    ("to_n3", "都", ["ト", "ツ"], ["みやこ"], ["ibu kota", "kota besar", "capital", "metropolis"], 11, "阝", [
        ("都会", "tokai", "kota besar"),
        ("都市", "toshi", "kota"),
        ("京都", "kyouto", "Kyoto"),
    ], [
        ("東京は大きい都会です。", "Toukyou wa ookii tokai desu.", "Tokyo adalah kota besar."),
        ("京都へ旅行しました。", "Kyouto e ryokou shimashita.", "Saya bepergian ke Kyoto."),
    ]),
    ("wa_n3", "和", ["ワ", "オ", "カ"], ["なご-む", "やわ-らぐ"], ["harmoni", "gaya Jepang", "harmony", "Japanese style"], 8, "禾", [
        ("平和", "heiwa", "perdamaian"),
        ("和食", "washoku", "masakan Jepang"),
        ("昭和", "shouwa", "era Showa"),
    ], [
        ("世界の平和を願います。", "Sekai no heiwa o negaimasu.", "Saya berharap perdamaian dunia."),
        ("和食が好きです。", "Washoku ga suki desu.", "Saya suka masakan Jepang."),
    ]),
    ("ki2_n3", "機", ["キ"], ["はた"], ["mesin", "kesempatan", "machine", "opportunity"], 16, "木", [
        ("機会", "kikai", "kesempatan"),
        ("飛行機", "hikouki", "pesawat terbang"),
        ("機能", "kinou", "fungsi"),
    ], [
        ("いい機会だと思います。", "Ii kikai da to omoimasu.", "Saya pikir ini kesempatan yang bagus."),
        ("飛行機で日本へ行きます。", "Hikouki de Nihon e ikimasu.", "Saya pergi ke Jepang naik pesawat."),
    ]),
    ("hei_n3", "平", ["ヘイ", "ビョウ"], ["たい-ら", "ひら"], ["rata", "damai", "flat", "peace"], 5, "干", [
        ("平和", "heiwa", "perdamaian"),
        ("平日", "heijitsu", "hari kerja"),
        ("平気", "heiki", "tidak masalah/santai"),
    ], [
        ("平日は仕事があります。", "Heijitsu wa shigoto ga arimasu.", "Hari kerja saya ada pekerjaan."),
        ("大丈夫、平気です。", "Daijoubu, heiki desu.", "Tidak apa-apa, saya baik-baik saja."),
    ]),
    ("ka2_n3", "加", ["カ"], ["くわ-える", "くわ-わる"], ["menambahkan", "bergabung", "add", "join"], 5, "力", [
        ("参加", "sanka", "partisipasi"),
        ("加える", "kuwaeru", "menambahkan"),
        ("増加", "zouka", "peningkatan"),
    ], [
        ("パーティーに参加します。", "Paatii ni sanka shimasu.", "Saya akan berpartisipasi dalam pesta."),
        ("砂糖を加えてください。", "Satou o kuwaete kudasai.", "Tolong tambahkan gula."),
    ]),
    ("ju_n3", "受", ["ジュ"], ["う-ける"], ["menerima", "accept", "receive"], 8, "又", [
        ("受ける", "ukeru", "menerima"),
        ("受付", "uketsuke", "resepsionis"),
        ("受験", "juken", "ujian masuk"),
    ], [
        ("テストを受けます。", "Tesuto o ukemasu.", "Saya akan mengikuti tes."),
        ("受付はあちらです。", "Uketsuke wa achira desu.", "Resepsionis ada di sebelah sana."),
    ]),
    ("suu_n3", "数", ["スウ"], ["かず", "かぞ-える"], ["angka", "jumlah", "number", "count"], 13, "攵", [
        ("数字", "suuji", "angka"),
        ("数える", "kazoeru", "menghitung"),
        ("人数", "ninzuu", "jumlah orang"),
    ], [
        ("この数字は間違っています。", "Kono suuji wa machigatte imasu.", "Angka ini salah."),
        ("一から十まで数えました。", "Ichi kara juu made kazoemashita.", "Saya menghitung dari satu sampai sepuluh."),
    ]),
    ("ki3_n3", "記", ["キ"], ["しる-す"], ["mencatat", "menulis", "record", "note"], 10, "言", [
        ("日記", "nikki", "buku harian"),
        ("記録", "kiroku", "rekaman/catatan"),
        ("記憶", "kioku", "ingatan"),
    ], [
        ("毎日日記を書いています。", "Mainichi nikki o kaite imasu.", "Setiap hari saya menulis buku harian."),
        ("新しい記録を作りました。", "Atarashii kiroku o tsukurimashita.", "Saya membuat rekor baru."),
    ]),
    ("sho_n3", "初", ["ショ"], ["はじ-め", "はつ"], ["pertama", "awal", "first", "beginning"], 7, "刀", [
        ("最初", "saisho", "pertama/awal"),
        ("初めて", "hajimete", "untuk pertama kalinya"),
        ("初日", "shonichi", "hari pertama"),
    ], [
        ("初めて日本へ行きました。", "Hajimete Nihon e ikimashita.", "Saya pergi ke Jepang untuk pertama kalinya."),
        ("今日は仕事の初日です。", "Kyou wa shigoto no shonichi desu.", "Hari ini adalah hari pertama kerja."),
    ]),
    ("shi2_n3", "指", ["シ"], ["ゆび", "さ-す"], ["jari", "menunjuk", "finger", "point"], 9, "扌", [
        ("指", "yubi", "jari"),
        ("指す", "sasu", "menunjuk"),
        ("指輪", "yubiwa", "cincin"),
    ], [
        ("指が痛いです。", "Yubi ga itai desu.", "Jari saya sakit."),
        ("あの人を指してください。", "Ano hito o sashite kudasai.", "Tolong tunjuk orang itu."),
    ]),
    ("ken_n3", "権", ["ケン", "ゴン"], [], ["hak", "wewenang", "rights", "authority"], 15, "木", [
        ("権利", "kenri", "hak"),
        ("人権", "jinken", "hak asasi manusia"),
        ("選挙権", "senkyoken", "hak pilih"),
    ], [
        ("全ての人に人権があります。", "Subete no hito ni jinken ga arimasu.", "Semua orang memiliki hak asasi manusia."),
        ("選挙権は18歳からです。", "Senkyoken wa juuhassai kara desu.", "Hak pilih berlaku mulai usia 18 tahun."),
    ]),
    ("shi3_n3", "支", ["シ"], ["ささ-える"], ["mendukung", "cabang", "support", "branch"], 4, "支", [
        ("支える", "sasaeru", "mendukung"),
        ("支店", "shiten", "cabang toko"),
        ("支持", "shiji", "dukungan"),
    ], [
        ("家族が私を支えてくれます。", "Kazoku ga watashi o sasaete kuremasu.", "Keluarga saya mendukung saya."),
        ("この会社には支店が多いです。", "Kono kaisha ni wa shiten ga ooi desu.", "Perusahaan ini memiliki banyak cabang."),
    ]),
    ("san_n3", "産", ["サン"], ["う-む", "う-まれる"], ["produksi", "melahirkan", "produce", "give birth"], 11, "生", [
        ("出産", "shussan", "melahirkan"),
        ("生産", "seisan", "produksi"),
        ("特産", "tokusan", "produk khas daerah"),
    ], [
        ("妻が来月出産します。", "Tsuma ga raigetsu shussan shimasu.", "Istri saya akan melahirkan bulan depan."),
        ("この工場は車を生産しています。", "Kono koujou wa kuruma o seisan shite imasu.", "Pabrik ini memproduksi mobil."),
    ]),
    ("ten_n3", "点", ["テン"], [], ["titik", "nilai", "point", "score"], 9, "灬", [
        ("点数", "tensuu", "nilai/skor"),
        ("弱点", "jakuten", "kelemahan"),
        ("句点", "kuten", "tanda titik"),
    ], [
        ("テストの点数は良かったです。", "Tesuto no tensuu wa yokatta desu.", "Nilai tes saya bagus."),
        ("誰にでも弱点があります。", "Dare ni demo jakuten ga arimasu.", "Setiap orang punya kelemahan."),
    ]),
    # --- Batch C: 報済活原共得解交資予向際勝面告反判認参組信件 (22) ---
    ("hou2_n3", "報", ["ホウ"], ["むく-いる"], ["laporan", "balasan", "report", "news"], 12, "土", [
        ("情報", "jouhou", "informasi"),
        ("天気予報", "tenki yohou", "ramalan cuaca"),
        ("報告", "houkoku", "laporan"),
    ], [
        ("新しい情報を教えてください。", "Atarashii jouhou o oshiete kudasai.", "Tolong beri tahu informasi terbaru."),
        ("上司に報告しました。", "Joushi ni houkoku shimashita.", "Saya sudah melaporkan kepada atasan."),
    ]),
    ("sai2_n3", "済", ["サイ"], ["す-む"], ["selesai", "cukup", "finish", "complete"], 11, "氵", [
        ("経済", "keizai", "ekonomi"),
        ("済む", "sumu", "selesai"),
        ("返済", "hensai", "pembayaran kembali"),
    ], [
        ("仕事が済みました。", "Shigoto ga sumimashita.", "Pekerjaan sudah selesai."),
        ("経済のニュースを読みます。", "Keizai no nyuusu o yomimasu.", "Saya membaca berita ekonomi."),
    ]),
    ("katsu_n3", "活", ["カツ"], ["い-きる"], ["hidup", "aktif", "lively", "active"], 9, "氵", [
        ("生活", "seikatsu", "kehidupan"),
        ("活動", "katsudou", "kegiatan"),
        ("活気", "kakki", "semangat/keramaian"),
    ], [
        ("日本での生活は楽しいです。", "Nihon de no seikatsu wa tanoshii desu.", "Kehidupan di Jepang menyenangkan."),
        ("クラブ活動に参加しています。", "Kurabu katsudou ni sanka shite imasu.", "Saya ikut kegiatan klub."),
    ]),
    ("gen_n3", "原", ["ゲン"], ["はら"], ["asal", "ladang", "original", "field"], 10, "厂", [
        ("原因", "gen'in", "penyebab"),
        ("原稿", "genkou", "naskah"),
        ("草原", "sougen", "padang rumput"),
    ], [
        ("事故の原因を調べています。", "Jiko no gen'in o shirabete imasu.", "Saya sedang menyelidiki penyebab kecelakaan."),
        ("草原で馬が走っています。", "Sougen de uma ga hashitte imasu.", "Kuda berlari di padang rumput."),
    ]),
    ("kyou_n3", "共", ["キョウ"], ["とも"], ["bersama", "keduanya", "together", "both"], 6, "八", [
        ("共に", "tomoni", "bersama-sama"),
        ("共通", "kyoutsuu", "kesamaan/umum"),
        ("公共", "koukyou", "publik/umum"),
    ], [
        ("家族と共に暮らしています。", "Kazoku to tomoni kurashite imasu.", "Saya tinggal bersama keluarga."),
        ("これは私たちの共通の趣味です。", "Kore wa watashitachi no kyoutsuu no shumi desu.", "Ini adalah hobi yang sama-sama kita sukai."),
    ]),
    ("toku_n3", "得", ["トク"], ["え-る"], ["mendapat", "untung", "gain", "profit"], 11, "彳", [
        ("得る", "eru", "mendapatkan"),
        ("説得", "settoku", "membujuk/persuasi"),
        ("得意", "tokui", "mahir/andalan"),
    ], [
        ("いい経験を得ました。", "Ii keiken o emashita.", "Saya mendapatkan pengalaman yang baik."),
        ("料理が得意です。", "Ryouri ga tokui desu.", "Saya mahir memasak."),
    ]),
    ("kai2_n3", "解", ["カイ", "ゲ"], ["と-く", "わか-る"], ["memahami", "menguraikan", "understand", "solve"], 13, "角", [
        ("理解", "rikai", "pemahaman"),
        ("解決", "kaiketsu", "penyelesaian"),
        ("解く", "toku", "memecahkan/melepaskan"),
    ], [
        ("先生の説明を理解しました。", "Sensei no setsumei o rikai shimashita.", "Saya memahami penjelasan guru."),
        ("問題が解決しました。", "Mondai ga kaiketsu shimashita.", "Masalahnya sudah terselesaikan."),
    ]),
    ("kou_n3", "交", ["コウ"], ["まじ-わる", "か-う"], ["bergaul", "bertukar", "mingle", "exchange"], 6, "亠", [
        ("交通", "koutsuu", "lalu lintas"),
        ("交換", "koukan", "pertukaran"),
        ("交流", "kouryuu", "pertukaran budaya/interaksi"),
    ], [
        ("この道は交通量が多いです。", "Kono michi wa koutsuuryou ga ooi desu.", "Jalan ini banyak lalu lintasnya."),
        ("意見を交換しましょう。", "Iken o koukan shimashou.", "Ayo tukar pendapat."),
    ]),
    ("shi4_n3", "資", ["シ"], [], ["modal", "sumber daya", "assets", "capital"], 13, "貝", [
        ("資料", "shiryou", "materi/dokumen"),
        ("資金", "shikin", "dana"),
        ("投資", "toushi", "investasi"),
    ], [
        ("会議の資料を準備しました。", "Kaigi no shiryou o junbi shimashita.", "Saya menyiapkan materi rapat."),
        ("新しい事業に投資します。", "Atarashii jigyou ni toushi shimasu.", "Saya akan berinvestasi pada bisnis baru."),
    ]),
    ("yo_n3", "予", ["ヨ"], ["あらかじ-め"], ["sebelumnya", "sebelum-", "beforehand", "pre-"], 4, "亅", [
        ("予定", "yotei", "rencana"),
        ("予約", "yoyaku", "reservasi"),
        ("予習", "yoshuu", "belajar sebelum kelas"),
    ], [
        ("明日の予定を確認します。", "Ashita no yotei o kakunin shimasu.", "Saya akan cek rencana besok."),
        ("レストランを予約しました。", "Resutoran o yoyaku shimashita.", "Saya sudah reservasi restoran."),
    ]),
    ("kou2_n3", "向", ["コウ"], ["む-く", "む-かう"], ["menghadap", "arah", "face", "direction"], 6, "口", [
        ("方向", "houkou", "arah"),
        ("向かう", "mukau", "menuju"),
        ("向こう", "mukou", "seberang/sana"),
    ], [
        ("駅の方向がわかりません。", "Eki no houkou ga wakarimasen.", "Saya tidak tahu arah ke stasiun."),
        ("会社に向かっています。", "Kaisha ni mukatte imasu.", "Saya sedang menuju kantor."),
    ]),
    ("sai3_n3", "際", ["サイ"], ["きわ"], ["saat", "kesempatan", "occasion", "when"], 14, "阝", [
        ("実際", "jissai", "kenyataan/sebenarnya"),
        ("国際", "kokusai", "internasional"),
        ("際に", "sai ni", "pada saat"),
    ], [
        ("実際はもっと難しいです。", "Jissai wa motto muzukashii desu.", "Sebenarnya lebih sulit lagi."),
        ("これは国際会議です。", "Kore wa kokusai kaigi desu.", "Ini adalah konferensi internasional."),
    ]),
    ("shou_n3", "勝", ["ショウ"], ["か-つ"], ["menang", "kemenangan", "victory", "win"], 12, "力", [
        ("勝つ", "katsu", "menang"),
        ("優勝", "yuushou", "juara"),
        ("勝利", "shouri", "kemenangan"),
    ], [
        ("試合に勝ちました。", "Shiai ni kachimashita.", "Saya menang dalam pertandingan."),
        ("彼らのチームが優勝しました。", "Karera no chiimu ga yuushou shimashita.", "Tim mereka menjadi juara."),
    ]),
    ("men_n3", "面", ["メン"], ["おも", "おもて"], ["wajah", "permukaan", "face", "surface"], 9, "面", [
        ("面白い", "omoshiroi", "menarik"),
        ("場面", "bamen", "adegan"),
        ("面接", "mensetsu", "wawancara"),
    ], [
        ("この映画はとても面白いです。", "Kono eiga wa totemo omoshiroi desu.", "Film ini sangat menarik."),
        ("明日、面接があります。", "Ashita, mensetsu ga arimasu.", "Besok ada wawancara."),
    ]),
    ("koku_n3", "告", ["コク"], ["つ-げる"], ["memberitahu", "mengumumkan", "tell", "announce"], 7, "口", [
        ("報告", "houkoku", "laporan"),
        ("広告", "koukoku", "iklan"),
        ("告白", "kokuhaku", "pengakuan/menyatakan cinta"),
    ], [
        ("結果を報告してください。", "Kekka o houkoku shite kudasai.", "Tolong laporkan hasilnya."),
        ("テレビで広告を見ました。", "Terebi de koukoku o mimashita.", "Saya melihat iklan di TV."),
    ]),
    ("han_n3", "反", ["ハン", "タン"], ["そ-る"], ["lawan", "anti-", "opposite", "anti-"], 4, "又", [
        ("反対", "hantai", "berlawanan"),
        ("反応", "hannou", "reaksi"),
        ("反省", "hansei", "introspeksi"),
    ], [
        ("彼の意見に反対です。", "Kare no iken ni hantai desu.", "Saya tidak setuju dengan pendapatnya."),
        ("自分の失敗を反省します。", "Jibun no shippai o hansei shimasu.", "Saya merenungkan kesalahan saya sendiri."),
    ]),
    ("han2_n3", "判", ["ハン", "バン"], ["わか-る"], ["keputusan", "penilaian", "judgement", "seal"], 7, "刂", [
        ("判断", "handan", "keputusan/penilaian"),
        ("裁判", "saiban", "persidangan"),
        ("評判", "hyouban", "reputasi"),
    ], [
        ("自分で判断してください。", "Jibun de handan shite kudasai.", "Tolong putuskan sendiri."),
        ("このレストランは評判がいいです。", "Kono resutoran wa hyouban ga ii desu.", "Restoran ini reputasinya bagus."),
    ]),
    ("nin_n3", "認", ["ニン"], ["みと-める"], ["mengakui", "mengenali", "acknowledge", "recognize"], 14, "言", [
        ("確認", "kakunin", "konfirmasi"),
        ("認める", "mitomeru", "mengakui"),
        ("承認", "shounin", "persetujuan"),
    ], [
        ("予約を確認してください。", "Yoyaku o kakunin shite kudasai.", "Tolong konfirmasi reservasinya."),
        ("彼は自分の間違いを認めました。", "Kare wa jibun no machigai o mitomemashita.", "Dia mengakui kesalahannya sendiri."),
    ]),
    ("san2_n3", "参", ["サン"], ["まい-る"], ["pergi (sopan)", "ikut serta", "go (humble)", "visit"], 8, "厶", [
        ("参加", "sanka", "partisipasi"),
        ("参考", "sankou", "referensi"),
        ("参る", "mairu", "pergi/datang (bentuk sopan)"),
    ], [
        ("イベントに参加します。", "Ibento ni sanka shimasu.", "Saya akan ikut serta dalam acara."),
        ("この本を参考にしました。", "Kono hon o sankou ni shimashita.", "Saya menjadikan buku ini sebagai referensi."),
    ]),
    ("so_n3", "組", ["ソ"], ["く-む"], ["kelompok", "menyusun", "group", "assemble"], 11, "糸", [
        ("番組", "bangumi", "acara TV"),
        ("組む", "kumu", "menyusun/bergabung"),
        ("組織", "soshiki", "organisasi"),
    ], [
        ("このテレビ番組が好きです。", "Kono terebi bangumi ga suki desu.", "Saya suka acara TV ini."),
        ("チームを組みました。", "Chiimu o kumimashita.", "Kami membentuk tim."),
    ]),
    ("shin_n3", "信", ["シン"], [], ["percaya", "kepercayaan", "faith", "trust"], 9, "亻", [
        ("信じる", "shinjiru", "percaya"),
        ("自信", "jishin", "percaya diri"),
        ("信頼", "shinrai", "kepercayaan"),
    ], [
        ("彼を信じています。", "Kare o shinjite imasu.", "Saya percaya padanya."),
        ("もっと自信を持ってください。", "Motto jishin o motte kudasai.", "Tolong lebih percaya diri."),
    ]),
    ("ken2_n3", "件", ["ケン"], ["くだん"], ["perkara", "hal", "case", "matter"], 6, "亻", [
        ("事件", "jiken", "insiden/kasus"),
        ("用件", "youken", "urusan/keperluan"),
        ("条件", "jouken", "syarat"),
    ], [
        ("大きい事件がありました。", "Ookii jiken ga arimashita.", "Ada insiden besar."),
        ("ご用件は何ですか。", "Goyouken wa nan desu ka.", "Ada keperluan apa?"),
    ]),
    # --- Batch D: 側任引求次昨論官増係情投示打直両式確果容必演 (22) ---
    ("soku_n3", "側", ["ソク"], ["かわ", "がわ"], ["sisi", "samping", "side"], 11, "亻", [
        ("右側", "migigawa", "sisi kanan"),
        ("側面", "sokumen", "sisi/aspek"),
        ("内側", "uchigawa", "sisi dalam"),
    ], [
        ("右側に郵便局があります。", "Migigawa ni yuubinkyoku ga arimasu.", "Ada kantor pos di sisi kanan."),
        ("箱の内側を見てください。", "Hako no uchigawa o mite kudasai.", "Tolong lihat bagian dalam kotak."),
    ]),
    ("nin2_n3", "任", ["ニン"], ["まか-せる"], ["tanggung jawab", "mempercayakan", "responsibility", "entrust"], 6, "亻", [
        ("責任", "sekinin", "tanggung jawab"),
        ("任せる", "makaseru", "mempercayakan"),
        ("主任", "shunin", "kepala/penanggung jawab"),
    ], [
        ("これは私の責任です。", "Kore wa watashi no sekinin desu.", "Ini adalah tanggung jawab saya."),
        ("この仕事を任せます。", "Kono shigoto o makasemasu.", "Saya percayakan pekerjaan ini kepada Anda."),
    ]),
    ("in_n3", "引", ["イン"], ["ひ-く"], ["menarik", "pull", "tug"], 4, "弓", [
        ("引く", "hiku", "menarik"),
        ("割引", "waribiki", "diskon"),
        ("引っ越し", "hikkoshi", "pindah rumah"),
    ], [
        ("ドアを引いてください。", "Doa o hiite kudasai.", "Tolong tarik pintunya."),
        ("この店は割引があります。", "Kono mise wa waribiki ga arimasu.", "Toko ini ada diskon."),
    ]),
    ("kyuu_n3", "求", ["キュウ"], ["もと-める"], ["meminta", "membutuhkan", "request", "require"], 7, "水", [
        ("要求", "youkyuu", "permintaan/tuntutan"),
        ("求める", "motomeru", "mencari/meminta"),
        ("求人", "kyuujin", "lowongan kerja"),
    ], [
        ("助けを求めています。", "Tasuke o motomete imasu.", "Saya sedang meminta bantuan."),
        ("この会社は求人を出しています。", "Kono kaisha wa kyuujin o dashite imasu.", "Perusahaan ini membuka lowongan kerja."),
    ]),
    ("ji2_n3", "次", ["ジ", "シ"], ["つぎ", "つ-ぐ"], ["berikutnya", "next", "following"], 6, "欠", [
        ("次に", "tsugi ni", "selanjutnya"),
        ("次回", "jikai", "kali berikutnya"),
        ("目次", "mokuji", "daftar isi"),
    ], [
        ("次に何をしますか。", "Tsugi ni nani o shimasu ka.", "Selanjutnya kita mau apa?"),
        ("次回もよろしくお願いします。", "Jikai mo yoroshiku onegaishimasu.", "Sampai jumpa di kesempatan berikutnya."),
    ]),
    ("saku_n3", "昨", ["サク"], [], ["kemarin", "sebelumnya", "yesterday", "previous"], 9, "日", [
        ("昨日", "kinou", "kemarin"),
        ("昨年", "sakunen", "tahun lalu"),
        ("昨夜", "sakuya", "tadi malam"),
    ], [
        ("昨日は雨でした。", "Kinou wa ame deshita.", "Kemarin hujan."),
        ("昨年、日本へ行きました。", "Sakunen, Nihon e ikimashita.", "Tahun lalu saya pergi ke Jepang."),
    ]),
    ("ron_n3", "論", ["ロン"], [], ["argumen", "diskusi", "argument", "discourse"], 15, "言", [
        ("議論", "giron", "diskusi/perdebatan"),
        ("論文", "ronbun", "makalah/skripsi"),
        ("結論", "ketsuron", "kesimpulan"),
    ], [
        ("卒業論文を書いています。", "Sotsugyou ronbun o kaite imasu.", "Saya sedang menulis skripsi."),
        ("結論はまだ出ていません。", "Ketsuron wa mada dete imasen.", "Kesimpulannya belum keluar."),
    ]),
    ("kan2_n3", "官", ["カン"], [], ["pejabat", "pemerintahan", "official", "government"], 8, "宀", [
        ("警官", "keikan", "polisi"),
        ("官庁", "kanchou", "instansi pemerintah"),
        ("外交官", "gaikoukan", "diplomat"),
    ], [
        ("警官に道を聞きました。", "Keikan ni michi o kikimashita.", "Saya bertanya jalan kepada polisi."),
        ("彼は外交官です。", "Kare wa gaikoukan desu.", "Dia adalah seorang diplomat."),
    ]),
    ("zou_n3", "増", ["ゾウ"], ["ま-す", "ふ-える"], ["meningkat", "menambah", "increase", "add"], 14, "土", [
        ("増える", "fueru", "bertambah"),
        ("増加", "zouka", "peningkatan"),
        ("増やす", "fuyasu", "menambahkan"),
    ], [
        ("最近、観光客が増えました。", "Saikin, kankoukyaku ga fuemashita.", "Belakangan ini wisatawan bertambah."),
        ("貯金を増やしたいです。", "Chokin o fuyashitai desu.", "Saya ingin menambah tabungan."),
    ]),
    ("kei2_n3", "係", ["ケイ"], ["かか-る", "かかり"], ["petugas", "hubungan", "person in charge", "connection"], 9, "亻", [
        ("関係", "kankei", "hubungan"),
        ("係員", "kakariin", "petugas"),
        ("受付係", "uketsukegakari", "petugas resepsionis"),
    ], [
        ("二人はいい関係です。", "Futari wa ii kankei desu.", "Hubungan mereka baik."),
        ("係員に聞いてください。", "Kakariin ni kiite kudasai.", "Tolong tanyakan pada petugas."),
    ]),
    ("jou_n3", "情", ["ジョウ", "セイ"], ["なさ-け"], ["perasaan", "emosi", "feeling", "emotion"], 11, "忄", [
        ("感情", "kanjou", "emosi/perasaan"),
        ("情報", "jouhou", "informasi"),
        ("友情", "yuujou", "persahabatan"),
    ], [
        ("彼女は感情を表に出しません。", "Kanojo wa kanjou o omote ni dashimasen.", "Dia tidak menunjukkan emosinya."),
        ("二人の友情は続いています。", "Futari no yuujou wa tsuzuite imasu.", "Persahabatan mereka berdua masih berlanjut."),
    ]),
    ("tou2_n3", "投", ["トウ"], ["な-げる"], ["melempar", "berinvestasi", "throw", "invest"], 7, "扌", [
        ("投げる", "nageru", "melempar"),
        ("投資", "toushi", "investasi"),
        ("投票", "touhyou", "voting/pemungutan suara"),
    ], [
        ("ボールを投げてください。", "Booru o nagete kudasai.", "Tolong lempar bolanya."),
        ("選挙で投票しました。", "Senkyo de touhyou shimashita.", "Saya sudah memberikan suara di pemilu."),
    ]),
    ("ji3_n3", "示", ["ジ", "シ"], ["しめ-す"], ["menunjukkan", "show", "indicate"], 5, "示", [
        ("指示", "shiji", "instruksi"),
        ("示す", "shimesu", "menunjukkan"),
        ("展示", "tenji", "pameran"),
    ], [
        ("先生の指示に従ってください。", "Sensei no shiji ni shitagatte kudasai.", "Tolong ikuti instruksi guru."),
        ("美術館で絵画を展示しています。", "Bijutsukan de kaiga o tenji shite imasu.", "Museum seni memamerkan lukisan."),
    ]),
    ("da_n3", "打", ["ダ"], ["う-つ"], ["memukul", "strike", "hit"], 5, "扌", [
        ("打つ", "utsu", "memukul"),
        ("打撃", "dageki", "pukulan/dampak"),
        ("打ち合わせ", "uchiawase", "rapat/pertemuan"),
    ], [
        ("ボールを打ちました。", "Booru o uchimashita.", "Saya memukul bola."),
        ("明日、打ち合わせがあります。", "Ashita, uchiawase ga arimasu.", "Besok ada rapat."),
    ]),
    ("choku_n3", "直", ["チョク", "ジキ"], ["なお-す", "ただ-ちに"], ["langsung", "memperbaiki", "direct", "fix"], 8, "目", [
        ("直す", "naosu", "memperbaiki"),
        ("正直", "shoujiki", "jujur"),
        ("直接", "chokusetsu", "langsung"),
    ], [
        ("壊れた時計を直しました。", "Kowareta tokei o naoshimashita.", "Saya memperbaiki jam yang rusak."),
        ("正直に話してください。", "Shoujiki ni hanashite kudasai.", "Tolong bicara dengan jujur."),
    ]),
    ("ryou_n3", "両", ["リョウ"], [], ["keduanya", "both"], 6, "一", [
        ("両方", "ryouhou", "keduanya"),
        ("両親", "ryoushin", "orang tua"),
        ("両手", "ryoute", "kedua tangan"),
    ], [
        ("両方とも好きです。", "Ryouhou tomo suki desu.", "Saya suka keduanya."),
        ("両親に会いに行きます。", "Ryoushin ni ai ni ikimasu.", "Saya akan menemui orang tua saya."),
    ]),
    ("shiki_n3", "式", ["シキ"], [], ["upacara", "gaya", "ceremony", "style"], 6, "弋", [
        ("結婚式", "kekkonshiki", "upacara pernikahan"),
        ("卒業式", "sotsugyoushiki", "upacara kelulusan"),
        ("方式", "houshiki", "metode/cara"),
    ], [
        ("来月、結婚式があります。", "Raigetsu, kekkonshiki ga arimasu.", "Bulan depan ada upacara pernikahan."),
        ("卒業式で泣きました。", "Sotsugyoushiki de nakimashita.", "Saya menangis di upacara kelulusan."),
    ]),
    ("kaku_n3", "確", ["カク"], ["たし-か", "たし-かめる"], ["memastikan", "pasti", "confirm", "certain"], 15, "石", [
        ("確認", "kakunin", "konfirmasi"),
        ("確かに", "tashika ni", "memang benar"),
        ("正確", "seikaku", "akurat/tepat"),
    ], [
        ("もう一度確認してください。", "Mou ichido kakunin shite kudasai.", "Tolong konfirmasi sekali lagi."),
        ("正確な時間を教えてください。", "Seikaku na jikan o oshiete kudasai.", "Tolong beri tahu waktu yang tepat."),
    ]),
    ("ka3_n3", "果", ["カ"], ["は-たす", "は-てる"], ["buah", "hasil", "fruit", "result"], 8, "木", [
        ("結果", "kekka", "hasil"),
        ("果物", "kudamono", "buah-buahan"),
        ("効果", "kouka", "efek"),
    ], [
        ("テストの結果はどうでしたか。", "Tesuto no kekka wa dou deshita ka.", "Bagaimana hasil tesnya?"),
        ("果物が好きです。", "Kudamono ga suki desu.", "Saya suka buah-buahan."),
    ]),
    ("you2_n3", "容", ["ヨウ"], [], ["isi", "wadah", "content", "contain"], 10, "宀", [
        ("内容", "naiyou", "isi/konten"),
        ("容器", "youki", "wadah"),
        ("美容院", "biyouin", "salon kecantikan"),
    ], [
        ("この本の内容は面白いです。", "Kono hon no naiyou wa omoshiroi desu.", "Isi buku ini menarik."),
        ("美容院で髪を切りました。", "Biyouin de kami o kirimashita.", "Saya memotong rambut di salon."),
    ]),
    ("hitsu_n3", "必", ["ヒツ"], ["かなら-ず"], ["pasti", "harus", "certainly", "invariably"], 5, "心", [
        ("必要", "hitsuyou", "diperlukan"),
        ("必ず", "kanarazu", "pasti/tanpa gagal"),
        ("必死", "hisshi", "sekuat tenaga"),
    ], [
        ("これは必要な書類です。", "Kore wa hitsuyou na shorui desu.", "Ini adalah dokumen yang diperlukan."),
        ("必ず約束を守ります。", "Kanarazu yakusoku o mamorimasu.", "Saya pasti akan menepati janji."),
    ]),
    ("en_n3", "演", ["エン"], [], ["pertunjukan", "akting", "performance", "act"], 14, "氵", [
        ("演技", "engi", "akting"),
        ("講演", "kouen", "ceramah/kuliah umum"),
        ("出演", "shutsuen", "tampil/berperan"),
    ], [
        ("彼女の演技はすばらしいです。", "Kanojo no engi wa subarashii desu.", "Aktingnya luar biasa."),
        ("有名な俳優がこの映画に出演しています。", "Yuumei na haiyuu ga kono eiga ni shutsuen shite imasu.", "Aktor terkenal berperan dalam film ini."),
    ]),
    # --- Batch E: 歳争談能位置流格疑過局放常状球職与供役構割費 (22) ---
    ("sai4_n3", "歳", ["サイ", "セイ"], ["とし"], ["usia", "tahun", "age", "years old"], 13, "止", [
        ("二十歳", "hatachi", "usia 20 tahun"),
        ("お歳暮", "oseibo", "hadiah akhir tahun"),
        ("歳月", "saigetsu", "waktu yang berlalu"),
    ], [
        ("今年、二十歳になりました。", "Kotoshi, hatachi ni narimashita.", "Tahun ini saya berusia 20 tahun."),
        ("歳月が流れました。", "Saigetsu ga nagaremashita.", "Waktu telah berlalu."),
    ]),
    ("sou2_n3", "争", ["ソウ"], ["あらそ-う"], ["berselisih", "bersaing", "dispute", "compete"], 6, "亅", [
        ("戦争", "sensou", "perang"),
        ("争う", "arasou", "berselisih/bersaing"),
        ("競争", "kyousou", "kompetisi"),
    ], [
        ("兄弟でよく争います。", "Kyoudai de yoku arasoimasu.", "Saudara-saudara sering berselisih."),
        ("会社間で競争があります。", "Kaisha kan de kyousou ga arimasu.", "Ada kompetisi antar perusahaan."),
    ]),
    ("dan_n3", "談", ["ダン"], [], ["berbicara", "diskusi", "talk", "discuss"], 15, "言", [
        ("相談", "soudan", "konsultasi"),
        ("会談", "kaidan", "pertemuan/perundingan"),
        ("冗談", "joudan", "lelucon"),
    ], [
        ("先生に相談しました。", "Sensei ni soudan shimashita.", "Saya berkonsultasi dengan guru."),
        ("それは冗談です。", "Sore wa joudan desu.", "Itu hanya lelucon."),
    ]),
    ("nou_n3", "能", ["ノウ"], [], ["kemampuan", "bakat", "ability", "talent"], 10, "月", [
        ("可能", "kanou", "mungkin"),
        ("能力", "nouryoku", "kemampuan"),
        ("才能", "sainou", "bakat"),
    ], [
        ("それは可能です。", "Sore wa kanou desu.", "Itu mungkin bisa dilakukan."),
        ("彼は音楽の才能があります。", "Kare wa ongaku no sainou ga arimasu.", "Dia memiliki bakat musik."),
    ]),
    ("i_n3", "位", ["イ"], ["くらい"], ["peringkat", "tingkat", "rank", "grade"], 7, "亻", [
        ("一位", "ichii", "peringkat pertama"),
        ("地位", "chii", "status/kedudukan"),
        ("単位", "tan'i", "unit/satuan (SKS)"),
    ], [
        ("テストで一位になりました。", "Tesuto de ichii ni narimashita.", "Saya mendapat peringkat pertama di tes."),
        ("大学で単位を取りました。", "Daigaku de tan'i o torimashita.", "Saya mengambil SKS di universitas."),
    ]),
    ("chi_n3", "置", ["チ"], ["お-く"], ["meletakkan", "menempatkan", "place", "put"], 13, "罒", [
        ("置く", "oku", "meletakkan"),
        ("位置", "ichi", "posisi/lokasi"),
        ("装置", "souchi", "perangkat/alat"),
    ], [
        ("机の上に本を置きました。", "Tsukue no ue ni hon o okimashita.", "Saya meletakkan buku di atas meja."),
        ("この店の位置がわかりません。", "Kono mise no ichi ga wakarimasen.", "Saya tidak tahu lokasi toko ini."),
    ]),
    ("ryuu_n3", "流", ["リュウ", "ル"], ["なが-れる"], ["aliran", "gaya", "flow", "style"], 10, "氵", [
        ("流れる", "nagareru", "mengalir"),
        ("交流", "kouryuu", "interaksi/pertukaran"),
        ("流行", "ryuukou", "tren/mode"),
    ], [
        ("川の水が流れています。", "Kawa no mizu ga nagarete imasu.", "Air sungai mengalir."),
        ("今、これが流行しています。", "Ima, kore ga ryuukou shite imasu.", "Sekarang ini sedang tren."),
    ]),
    ("kaku2_n3", "格", ["カク", "コウ"], [], ["status", "karakter", "status", "character"], 10, "木", [
        ("性格", "seikaku", "kepribadian"),
        ("価格", "kakaku", "harga"),
        ("合格", "goukaku", "lulus (ujian)"),
    ], [
        ("この商品の価格は高いです。", "Kono shouhin no kakaku wa takai desu.", "Harga produk ini mahal."),
        ("テストに合格しました。", "Tesuto ni goukaku shimashita.", "Saya lulus tes."),
    ]),
    ("gi2_n3", "疑", ["ギ"], ["うたが-う"], ["ragu", "curiga", "doubt", "suspect"], 14, "疋", [
        ("疑う", "utagau", "meragukan/mencurigai"),
        ("質疑", "shitsugi", "tanya jawab"),
        ("疑問", "gimon", "pertanyaan/keraguan"),
    ], [
        ("彼のことを疑っています。", "Kare no koto o utagatte imasu.", "Saya mencurigai dia."),
        ("疑問があれば聞いてください。", "Gimon ga areba kiite kudasai.", "Jika ada pertanyaan, silakan tanya."),
    ]),
    ("ka4_n3", "過", ["カ"], ["す-ぎる", "あやま-ち"], ["berlebihan", "melewati", "exceed", "pass"], 12, "辶", [
        ("過ぎる", "sugiru", "melewati/berlebihan"),
        ("過去", "kako", "masa lalu"),
        ("通過", "tsuuka", "melewati/lolos"),
    ], [
        ("もう九時を過ぎました。", "Mou kuji o sugimashita.", "Sudah lewat jam sembilan."),
        ("過去のことは忘れましょう。", "Kako no koto wa wasuremashou.", "Ayo lupakan masa lalu."),
    ]),
    ("kyoku_n3", "局", ["キョク"], [], ["kantor", "biro", "bureau", "office"], 7, "尸", [
        ("郵便局", "yuubinkyoku", "kantor pos"),
        ("薬局", "yakkyoku", "apotek"),
        ("結局", "kekkyoku", "akhirnya"),
    ], [
        ("郵便局で切手を買いました。", "Yuubinkyoku de kitte o kaimashita.", "Saya membeli perangko di kantor pos."),
        ("結局、行きませんでした。", "Kekkyoku, ikimasen deshita.", "Akhirnya, saya tidak pergi."),
    ]),
    ("hou3_n3", "放", ["ホウ"], ["はな-す"], ["melepaskan", "menyiarkan", "release", "broadcast"], 8, "攵", [
        ("放送", "housou", "siaran"),
        ("放す", "hanasu", "melepaskan"),
        ("解放", "kaihou", "pembebasan"),
    ], [
        ("テレビの放送を見ます。", "Terebi no housou o mimasu.", "Saya menonton siaran TV."),
        ("鳥を放しました。", "Tori o hanashimashita.", "Saya melepaskan burung."),
    ]),
    ("jou2_n3", "常", ["ジョウ"], ["つね"], ["biasa", "normal", "usual", "ordinary"], 11, "巾", [
        ("日常", "nichijou", "sehari-hari"),
        ("非常に", "hijou ni", "sangat"),
        ("正常", "seijou", "normal"),
    ], [
        ("日常生活は忙しいです。", "Nichijou seikatsu wa isogashii desu.", "Kehidupan sehari-hari sibuk."),
        ("この料理は非常においしいです。", "Kono ryouri wa hijou ni oishii desu.", "Masakan ini sangat enak."),
    ]),
    ("jou3_n3", "状", ["ジョウ"], [], ["kondisi", "keadaan", "condition", "state"], 7, "犬", [
        ("状態", "joutai", "kondisi/keadaan"),
        ("年賀状", "nengajou", "kartu ucapan tahun baru"),
        ("招待状", "shoutaijou", "kartu undangan"),
    ], [
        ("今の状態はどうですか。", "Ima no joutai wa dou desu ka.", "Bagaimana kondisi sekarang?"),
        ("招待状をもらいました。", "Shoutaijou o moraimashita.", "Saya menerima kartu undangan."),
    ]),
    ("kyuu2_n3", "球", ["キュウ"], ["たま"], ["bola", "bulat", "ball", "sphere"], 11, "玉", [
        ("野球", "yakyuu", "bisbol"),
        ("地球", "chikyuu", "bumi"),
        ("電球", "denkyuu", "bola lampu"),
    ], [
        ("野球が好きです。", "Yakyuu ga suki desu.", "Saya suka bisbol."),
        ("地球は丸いです。", "Chikyuu wa marui desu.", "Bumi berbentuk bulat."),
    ]),
    ("shoku_n3", "職", ["ショク"], [], ["pekerjaan", "jabatan", "occupation", "job"], 18, "耳", [
        ("就職", "shuushoku", "mendapatkan pekerjaan"),
        ("職業", "shokugyou", "profesi"),
        ("職場", "shokuba", "tempat kerja"),
    ], [
        ("来年、就職します。", "Rainen, shuushoku shimasu.", "Tahun depan saya akan mulai bekerja."),
        ("職場はどこですか。", "Shokuba wa doko desu ka.", "Di mana tempat kerja Anda?"),
    ]),
    ("yo2_n3", "与", ["ヨ"], ["あた-える"], ["memberikan", "berpartisipasi", "give", "grant"], 3, "一", [
        ("与える", "ataeru", "memberikan"),
        ("参与", "san'yo", "partisipasi/keikutsertaan"),
        ("給与", "kyuuyo", "gaji"),
    ], [
        ("子供にお菓子を与えました。", "Kodomo ni okashi o ataemashita.", "Saya memberikan permen kepada anak."),
        ("今月の給与をもらいました。", "Kongetsu no kyuuyo o moraimashita.", "Saya menerima gaji bulan ini."),
    ]),
    ("kyou2_n3", "供", ["キョウ"], ["そな-える", "とも"], ["menyediakan", "menawarkan", "provide", "offer"], 8, "亻", [
        ("子供", "kodomo", "anak"),
        ("提供", "teikyou", "penyediaan"),
        ("供給", "kyoukyuu", "pasokan"),
    ], [
        ("子供が公園で遊んでいます。", "Kodomo ga kouen de asonde imasu.", "Anak-anak bermain di taman."),
        ("情報を提供します。", "Jouhou o teikyou shimasu.", "Saya akan menyediakan informasi."),
    ]),
    ("yaku2_n3", "役", ["ヤク", "エキ"], [], ["peran", "tugas", "role", "duty"], 7, "彳", [
        ("役に立つ", "yaku ni tatsu", "berguna"),
        ("役者", "yakusha", "aktor"),
        ("役所", "yakusho", "kantor pemerintahan"),
    ], [
        ("この本は役に立ちます。", "Kono hon wa yaku ni tachimasu.", "Buku ini berguna."),
        ("市役所へ行きました。", "Shiyakusho e ikimashita.", "Saya pergi ke kantor balai kota."),
    ]),
    ("kou3_n3", "構", ["コウ"], ["かま-える"], ["membangun", "struktur", "construct", "structure"], 14, "木", [
        ("構造", "kouzou", "struktur"),
        ("構成", "kousei", "komposisi"),
        ("結構", "kekkou", "cukup baik/tidak perlu"),
    ], [
        ("この建物の構造は複雑です。", "Kono tatemono no kouzou wa fukuzatsu desu.", "Struktur gedung ini rumit."),
        ("もう結構です。", "Mou kekkou desu.", "Sudah cukup, terima kasih."),
    ]),
    ("katsu2_n3", "割", ["カツ"], ["わ-る", "わり"], ["membagi", "memotong", "divide", "cut"], 12, "刂", [
        ("割る", "waru", "membagi/memecahkan"),
        ("役割", "yakuwari", "peran"),
        ("割合", "wariai", "proporsi/rasio"),
    ], [
        ("グラスを割ってしまいました。", "Gurasu o watte shimaimashita.", "Saya tidak sengaja memecahkan gelas."),
        ("自分の役割を果たします。", "Jibun no yakuwari o hatashimasu.", "Saya akan menjalankan peran saya."),
    ]),
    ("hi_n3", "費", ["ヒ"], ["つい-やす"], ["biaya", "pengeluaran", "expense", "cost"], 12, "貝", [
        ("費用", "hiyou", "biaya"),
        ("食費", "shokuhi", "biaya makan"),
        ("消費", "shouhi", "konsumsi"),
    ], [
        ("旅行の費用はいくらですか。", "Ryokou no hiyou wa ikura desu ka.", "Berapa biaya perjalanannya?"),
        ("毎月の食費を計算します。", "Maitsuki no shokuhi o keisan shimasu.", "Saya menghitung biaya makan setiap bulan."),
    ]),
    # --- Batch F: 付説難優夫収断違消神番規術備宅害警席訪残想念 (22) ---
    ("fu_n3", "付", ["フ"], ["つ-ける"], ["melekatkan", "menempel", "attach", "append"], 5, "亻", [
        ("付ける", "tsukeru", "menempelkan/memasang"),
        ("気付く", "kizuku", "menyadari"),
        ("受付", "uketsuke", "resepsionis"),
    ], [
        ("名前を付けました。", "Namae o tsukemashita.", "Saya memberikan nama."),
        ("間違いに気付きました。", "Machigai ni kizukimashita.", "Saya menyadari kesalahannya."),
    ]),
    ("setsu_n3", "説", ["セツ", "ゼイ"], ["と-く"], ["teori", "penjelasan", "theory", "explanation"], 14, "言", [
        ("説明", "setsumei", "penjelasan"),
        ("小説", "shousetsu", "novel"),
        ("伝説", "densetsu", "legenda"),
    ], [
        ("もう一度説明してください。", "Mou ichido setsumei shite kudasai.", "Tolong jelaskan sekali lagi."),
        ("この小説はおもしろいです。", "Kono shousetsu wa omoshiroi desu.", "Novel ini menarik."),
    ]),
    ("nan_n3", "難", ["ナン"], ["むずか-しい", "かた-い"], ["sulit", "susah", "difficult", "hard"], 18, "隹", [
        ("難しい", "muzukashii", "sulit"),
        ("困難", "konnan", "kesulitan"),
        ("避難", "hinan", "evakuasi"),
    ], [
        ("このテストは難しいです。", "Kono tesuto wa muzukashii desu.", "Tes ini sulit."),
        ("地震で避難しました。", "Jishin de hinan shimashita.", "Kami mengungsi karena gempa."),
    ]),
    ("yuu_n3", "優", ["ユウ"], ["やさ-しい", "すぐ-れる"], ["lembut", "unggul", "gentle", "superior"], 17, "亻", [
        ("優しい", "yasashii", "baik hati/lembut"),
        ("優勝", "yuushou", "juara"),
        ("優先", "yuusen", "prioritas"),
    ], [
        ("彼女はとても優しいです。", "Kanojo wa totemo yasashii desu.", "Dia sangat baik hati."),
        ("安全を優先してください。", "Anzen o yuusen shite kudasai.", "Tolong utamakan keselamatan."),
    ]),
    ("fu2_n3", "夫", ["フ"], ["おっと"], ["suami", "husband"], 4, "大", [
        ("夫", "otto", "suami"),
        ("夫婦", "fuufu", "pasangan suami istri"),
        ("大丈夫", "daijoubu", "tidak apa-apa/baik-baik saja"),
    ], [
        ("私の夫は医者です。", "Watashi no otto wa isha desu.", "Suami saya adalah dokter."),
        ("大丈夫ですか。", "Daijoubu desu ka.", "Apakah Anda baik-baik saja?"),
    ]),
    ("shuu_n3", "収", ["シュウ"], ["おさ-める"], ["mendapat", "memperoleh", "obtain", "income"], 4, "又", [
        ("収入", "shuunyuu", "pendapatan"),
        ("収める", "osameru", "menyimpan/menerima"),
        ("領収書", "ryoushuusho", "kwitansi"),
    ], [
        ("毎月の収入はいくらですか。", "Maitsuki no shuunyuu wa ikura desu ka.", "Berapa pendapatan bulanan Anda?"),
        ("領収書をください。", "Ryoushuusho o kudasai.", "Tolong berikan kwitansinya."),
    ]),
    ("dan2_n3", "断", ["ダン"], ["ことわ-る", "た-つ"], ["menolak", "memutuskan", "refuse", "decide"], 11, "斤", [
        ("断る", "kotowaru", "menolak"),
        ("判断", "handan", "keputusan"),
        ("油断", "yudan", "lengah"),
    ], [
        ("誘いを断りました。", "Sasoi o kotowarimashita.", "Saya menolak ajakan itu."),
        ("油断しないでください。", "Yudan shinaide kudasai.", "Jangan lengah."),
    ]),
    ("i2_n3", "違", ["イ"], ["ちが-う"], ["berbeda", "salah", "differ", "wrong"], 13, "辶", [
        ("違う", "chigau", "berbeda/salah"),
        ("間違い", "machigai", "kesalahan"),
        ("違反", "ihan", "pelanggaran"),
    ], [
        ("それは違います。", "Sore wa chigaimasu.", "Itu salah/berbeda."),
        ("間違いを直してください。", "Machigai o naoshite kudasai.", "Tolong perbaiki kesalahannya."),
    ]),
    ("shou2_n3", "消", ["ショウ"], ["き-える", "け-す"], ["memadamkan", "menghapus", "extinguish", "erase"], 10, "氵", [
        ("消す", "kesu", "memadamkan/menghapus"),
        ("消える", "kieru", "padam/hilang"),
        ("消費", "shouhi", "konsumsi"),
    ], [
        ("電気を消してください。", "Denki o keshite kudasai.", "Tolong matikan lampunya."),
        ("火が消えました。", "Hi ga kiemashita.", "Apinya padam."),
    ]),
    ("shin2_n3", "神", ["シン", "ジン"], ["かみ"], ["dewa", "roh", "god", "spirit"], 9, "礻", [
        ("神様", "kamisama", "dewa/Tuhan"),
        ("神社", "jinja", "kuil Shinto"),
        ("精神", "seishin", "jiwa/mental"),
    ], [
        ("神社にお参りしました。", "Jinja ni omairi shimashita.", "Saya berdoa di kuil."),
        ("精神的に疲れました。", "Seishinteki ni tsukaremashita.", "Saya lelah secara mental."),
    ]),
    ("ban_n3", "番", ["バン"], [], ["nomor", "giliran", "number", "turn"], 12, "田", [
        ("番号", "bangou", "nomor"),
        ("一番", "ichiban", "nomor satu/paling"),
        ("番組", "bangumi", "acara TV"),
    ], [
        ("電話番号を教えてください。", "Denwa bangou o oshiete kudasai.", "Tolong beri tahu nomor telepon Anda."),
        ("これが一番好きです。", "Kore ga ichiban suki desu.", "Ini yang paling saya suka."),
    ]),
    ("ki4_n3", "規", ["キ"], [], ["standar", "aturan", "standard", "rule"], 11, "見", [
        ("規則", "kisoku", "aturan"),
        ("規模", "kibo", "skala"),
        ("新規", "shinki", "baru"),
    ], [
        ("学校の規則を守ってください。", "Gakkou no kisoku o mamotte kudasai.", "Tolong patuhi aturan sekolah."),
        ("このプロジェクトは規模が大きいです。", "Kono purojekuto wa kibo ga ookii desu.", "Proyek ini skalanya besar."),
    ]),
    ("jutsu_n3", "術", ["ジュツ"], [], ["teknik", "seni", "technique", "art"], 11, "行", [
        ("技術", "gijutsu", "teknologi/teknik"),
        ("手術", "shujutsu", "operasi bedah"),
        ("美術", "bijutsu", "seni rupa"),
    ], [
        ("この技術はすごいです。", "Kono gijutsu wa sugoi desu.", "Teknologi ini luar biasa."),
        ("来週、手術を受けます。", "Raishuu, shujutsu o ukemasu.", "Minggu depan saya akan menjalani operasi."),
    ]),
    ("bi_n3", "備", ["ビ"], ["そな-える"], ["mempersiapkan", "melengkapi", "prepare", "equip"], 12, "亻", [
        ("準備", "junbi", "persiapan"),
        ("備える", "sonaeru", "mempersiapkan"),
        ("設備", "setsubi", "fasilitas"),
    ], [
        ("旅行の準備をしています。", "Ryokou no junbi o shite imasu.", "Saya sedang mempersiapkan perjalanan."),
        ("この部屋の設備は新しいです。", "Kono heya no setsubi wa atarashii desu.", "Fasilitas kamar ini baru."),
    ]),
    ("taku_n3", "宅", ["タク"], [], ["rumah", "kediaman", "home", "residence"], 6, "宀", [
        ("自宅", "jitaku", "rumah sendiri"),
        ("お宅", "otaku", "rumah Anda"),
        ("宅配", "takuhai", "pengiriman ke rumah"),
    ], [
        ("自宅で仕事をしています。", "Jitaku de shigoto o shite imasu.", "Saya bekerja di rumah."),
        ("宅配便が届きました。", "Takuhaibin ga todokimashita.", "Paket pengiriman sudah sampai."),
    ]),
    ("gai_n3", "害", ["ガイ"], [], ["bahaya", "kerugian", "harm", "damage"], 10, "宀", [
        ("被害", "higai", "kerusakan/korban"),
        ("公害", "kougai", "polusi"),
        ("害虫", "gaichuu", "hama"),
    ], [
        ("台風で大きい被害がありました。", "Taifuu de ookii higai ga arimashita.", "Ada kerusakan besar akibat topan."),
        ("公害を減らしましょう。", "Kougai o herashimashou.", "Ayo kurangi polusi."),
    ]),
    ("kei3_n3", "警", ["ケイ"], ["いまし-める"], ["memperingatkan", "berjaga", "warn", "police"], 19, "言", [
        ("警察", "keisatsu", "polisi"),
        ("警告", "keikoku", "peringatan"),
        ("警備", "keibi", "keamanan/pengawalan"),
    ], [
        ("警察に電話しました。", "Keisatsu ni denwa shimashita.", "Saya menelepon polisi."),
        ("危険だという警告がありました。", "Kiken da to iu keikoku ga arimashita.", "Ada peringatan bahwa ini berbahaya."),
    ]),
    ("seki_n3", "席", ["セキ"], [], ["kursi", "tempat duduk", "seat"], 10, "巾", [
        ("出席", "shusseki", "hadir"),
        ("座席", "zaseki", "tempat duduk"),
        ("欠席", "kesseki", "tidak hadir"),
    ], [
        ("この席は空いていますか。", "Kono seki wa aite imasu ka.", "Apakah kursi ini kosong?"),
        ("会議に出席します。", "Kaigi ni shusseki shimasu.", "Saya akan menghadiri rapat."),
    ]),
    ("hou4_n3", "訪", ["ホウ"], ["おとず-れる", "たず-ねる"], ["mengunjungi", "visit", "call on"], 11, "言", [
        ("訪れる", "otozureru", "mengunjungi"),
        ("訪問", "houmon", "kunjungan"),
        ("来訪", "raihou", "kunjungan/tamu"),
    ], [
        ("友達の家を訪れました。", "Tomodachi no ie o otozuremashita.", "Saya mengunjungi rumah teman."),
        ("明日、先生を訪問します。", "Ashita, sensei o houmon shimasu.", "Besok saya akan mengunjungi guru."),
    ]),
    ("zan_n3", "残", ["ザン"], ["のこ-る", "のこ-す"], ["tersisa", "meninggalkan", "remain", "leave"], 10, "歹", [
        ("残る", "nokoru", "tersisa"),
        ("残念", "zannen", "sayang sekali"),
        ("残業", "zangyou", "lembur"),
    ], [
        ("まだご飯が残っています。", "Mada gohan ga nokotte imasu.", "Masih ada nasi tersisa."),
        ("今日は残業しなければなりません。", "Kyou wa zangyou shinakereba narimasen.", "Hari ini saya harus lembur."),
    ]),
    ("sou3_n3", "想", ["ソウ"], ["おも-う"], ["ide", "pemikiran", "idea", "thought"], 13, "心", [
        ("予想", "yosou", "prediksi/perkiraan"),
        ("理想", "risou", "ideal"),
        ("感想", "kansou", "kesan/pendapat"),
    ], [
        ("私の予想は当たりました。", "Watashi no yosou wa atarimashita.", "Prediksi saya benar."),
        ("この映画の感想を教えてください。", "Kono eiga no kansou o oshiete kudasai.", "Tolong beri tahu kesan Anda tentang film ini."),
    ]),
    ("nen_n3", "念", ["ネン"], [], ["pikiran", "perhatian", "thought", "attention"], 8, "心", [
        ("残念", "zannen", "sayang sekali"),
        ("記念", "kinen", "kenangan/peringatan"),
        ("念のため", "nen no tame", "untuk berjaga-jaga"),
    ], [
        ("残念ですが、行けません。", "Zannen desu ga, ikemasen.", "Sayang sekali, saya tidak bisa pergi."),
        ("これは記念写真です。", "Kore wa kinen shashin desu.", "Ini adalah foto kenangan."),
    ]),
    # --- Batch G: 助労限追商葉伝形景落退負渡失差末守種美命福望 (22) ---
    ("jo_n3", "助", ["ジョ"], ["たす-ける", "たす-かる"], ["membantu", "menolong", "help", "assist"], 7, "力", [
        ("助ける", "tasukeru", "menolong"),
        ("助手", "joshu", "asisten"),
        ("援助", "enjo", "bantuan"),
    ], [
        ("困っている人を助けました。", "Komatte iru hito o tasukemashita.", "Saya menolong orang yang kesulitan."),
        ("彼は先生の助手です。", "Kare wa sensei no joshu desu.", "Dia adalah asisten guru."),
    ]),
    ("rou_n3", "労", ["ロウ"], [], ["kerja keras", "jerih payah", "labor", "toil"], 7, "力", [
        ("苦労", "kurou", "kesulitan/jerih payah"),
        ("労働", "roudou", "tenaga kerja"),
        ("疲労", "hirou", "kelelahan"),
    ], [
        ("子育ては苦労が多いです。", "Kosodate wa kurou ga ooi desu.", "Membesarkan anak banyak jerih payahnya."),
        ("労働時間が長いです。", "Roudou jikan ga nagai desu.", "Jam kerjanya panjang."),
    ]),
    ("gen2_n3", "限", ["ゲン"], ["かぎ-る"], ["batas", "membatasi", "limit", "restrict"], 9, "阝", [
        ("限る", "kagiru", "membatasi"),
        ("制限", "seigen", "batasan"),
        ("期限", "kigen", "batas waktu"),
    ], [
        ("参加人数を限ります。", "Sanka ninzuu o kagirimasu.", "Kami membatasi jumlah peserta."),
        ("レポートの期限はいつですか。", "Repooto no kigen wa itsu desu ka.", "Kapan batas waktu laporannya?"),
    ]),
    ("tsui_n3", "追", ["ツイ"], ["お-う"], ["mengejar", "chase", "pursue"], 9, "辶", [
        ("追う", "ou", "mengejar"),
        ("追加", "tsuika", "tambahan"),
        ("追跡", "tsuiseki", "pelacakan/pengejaran"),
    ], [
        ("犬が猫を追っています。", "Inu ga neko o otte imasu.", "Anjing mengejar kucing."),
        ("メニューに追加してください。", "Menyuu ni tsuika shite kudasai.", "Tolong tambahkan ke menu."),
    ]),
    ("shou3_n3", "商", ["ショウ"], ["あきな-う"], ["perdagangan", "toko", "trade", "commerce"], 11, "口", [
        ("商品", "shouhin", "produk/barang"),
        ("商店", "shouten", "toko"),
        ("商売", "shoubai", "bisnis/dagang"),
    ], [
        ("この商品は人気があります。", "Kono shouhin wa ninki ga arimasu.", "Produk ini populer."),
        ("商売がうまくいっています。", "Shoubai ga umaku itte imasu.", "Bisnisnya berjalan lancar."),
    ]),
    ("you3_n3", "葉", ["ヨウ"], ["は"], ["daun", "leaf"], 12, "艹", [
        ("葉っぱ", "happa", "daun"),
        ("紅葉", "kouyou", "daun musim gugur"),
        ("言葉", "kotoba", "kata/bahasa"),
    ], [
        ("秋に紅葉がきれいです。", "Aki ni kouyou ga kirei desu.", "Musim gugur, daun-daun berwarnanya indah."),
        ("この言葉の意味がわかりません。", "Kono kotoba no imi ga wakarimasen.", "Saya tidak mengerti arti kata ini."),
    ]),
    ("den_n3", "伝", ["デン"], ["つた-わる", "つた-える"], ["menyampaikan", "tradisi", "transmit", "tradition"], 6, "亻", [
        ("伝える", "tsutaeru", "menyampaikan"),
        ("伝統", "dentou", "tradisi"),
        ("手伝う", "tetsudau", "membantu"),
    ], [
        ("よろしくお伝えください。", "Yoroshiku otsutae kudasai.", "Tolong sampaikan salam saya."),
        ("この祭りは古い伝統です。", "Kono matsuri wa furui dentou desu.", "Festival ini adalah tradisi lama."),
    ]),
    ("kei4_n3", "形", ["ケイ", "ギョウ"], ["かた", "かたち"], ["bentuk", "wujud", "shape", "form"], 7, "彡", [
        ("形", "katachi", "bentuk"),
        ("人形", "ningyou", "boneka"),
        ("形容詞", "keiyoushi", "kata sifat"),
    ], [
        ("このケーキの形はかわいいです。", "Kono keeki no katachi wa kawaii desu.", "Bentuk kue ini lucu."),
        ("娘に人形を買いました。", "Musume ni ningyou o kaimashita.", "Saya membelikan boneka untuk anak perempuan saya."),
    ]),
    ("kei5_n3", "景", ["ケイ"], [], ["pemandangan", "scenery", "view"], 12, "日", [
        ("景色", "keshiki", "pemandangan"),
        ("風景", "fuukei", "lanskap"),
        ("光景", "koukei", "adegan/pemandangan"),
    ], [
        ("山の景色がきれいです。", "Yama no keshiki ga kirei desu.", "Pemandangan gunung indah."),
        ("すばらしい風景を見ました。", "Subarashii fuukei o mimashita.", "Saya melihat lanskap yang indah."),
    ]),
    ("raku_n3", "落", ["ラク"], ["お-ちる", "お-とす"], ["jatuh", "gugur", "fall", "drop"], 12, "艹", [
        ("落ちる", "ochiru", "jatuh"),
        ("落とす", "otosu", "menjatuhkan"),
        ("下落", "geraku", "penurunan (harga)"),
    ], [
        ("財布を落としました。", "Saifu o otoshimashita.", "Saya menjatuhkan dompet."),
        ("葉が落ちています。", "Ha ga ochite imasu.", "Daun-daun berguguran."),
    ]),
    ("tai2_n3", "退", ["タイ"], ["しりぞ-く"], ["mundur", "keluar", "retreat", "withdraw"], 9, "辶", [
        ("退院", "taiin", "keluar dari rumah sakit"),
        ("引退", "intai", "pensiun"),
        ("退屈", "taikutsu", "membosankan"),
    ], [
        ("来週、退院します。", "Raishuu, taiin shimasu.", "Minggu depan saya keluar dari rumah sakit."),
        ("この映画は退屈です。", "Kono eiga wa taikutsu desu.", "Film ini membosankan."),
    ]),
    ("fu3_n3", "負", ["フ"], ["ま-ける", "お-う"], ["kalah", "menanggung", "lose", "bear"], 9, "貝", [
        ("負ける", "makeru", "kalah"),
        ("自負", "jifu", "kebanggaan diri"),
        ("負担", "futan", "beban"),
    ], [
        ("試合に負けました。", "Shiai ni makemashita.", "Saya kalah dalam pertandingan."),
        ("家族に負担をかけたくないです。", "Kazoku ni futan o kaketakunai desu.", "Saya tidak ingin membebani keluarga."),
    ]),
    ("to2_n3", "渡", ["ト"], ["わた-る", "わた-す"], ["menyeberang", "menyerahkan", "cross", "hand over"], 12, "氵", [
        ("渡る", "wataru", "menyeberang"),
        ("渡す", "watasu", "menyerahkan"),
        ("海外渡航", "kaigai tokou", "perjalanan ke luar negeri"),
    ], [
        ("橋を渡りました。", "Hashi o watarimashita.", "Saya menyeberangi jembatan."),
        ("これを渡してください。", "Kore o watashite kudasai.", "Tolong serahkan ini."),
    ]),
    ("shitsu_n3", "失", ["シツ"], ["うしな-う"], ["kehilangan", "kesalahan", "lose", "error"], 5, "大", [
        ("失う", "ushinau", "kehilangan"),
        ("失敗", "shippai", "kegagalan"),
        ("失礼", "shitsurei", "permisi/maaf"),
    ], [
        ("お金を失いました。", "Okane o ushinaimashita.", "Saya kehilangan uang."),
        ("失礼します。", "Shitsurei shimasu.", "Permisi (saya undur diri)."),
    ]),
    ("sa_n3", "差", ["サ"], ["さ-す"], ["perbedaan", "selisih", "difference", "gap"], 10, "工", [
        ("差", "sa", "perbedaan/selisih"),
        ("時差", "jisa", "perbedaan waktu"),
        ("差別", "sabetsu", "diskriminasi"),
    ], [
        ("二つの値段の差は大きいです。", "Futatsu no nedan no sa wa ookii desu.", "Selisih harga keduanya besar."),
        ("日本とインドネシアには時差があります。", "Nihon to Indoneshia ni wa jisa ga arimasu.", "Ada perbedaan waktu antara Jepang dan Indonesia."),
    ]),
    ("matsu_n3", "末", ["マツ", "バツ"], ["すえ"], ["akhir", "ujung", "end", "close"], 5, "木", [
        ("週末", "shuumatsu", "akhir pekan"),
        ("月末", "getsumatsu", "akhir bulan"),
        ("結末", "ketsumatsu", "akhir cerita"),
    ], [
        ("週末は何をしますか。", "Shuumatsu wa nani o shimasu ka.", "Apa yang Anda lakukan di akhir pekan?"),
        ("この物語の結末が知りたいです。", "Kono monogatari no ketsumatsu ga shiritai desu.", "Saya ingin tahu akhir dari cerita ini."),
    ]),
    ("shu3_n3", "守", ["シュ", "ス"], ["まも-る"], ["menjaga", "melindungi", "protect", "guard"], 6, "宀", [
        ("守る", "mamoru", "menjaga/melindungi"),
        ("留守", "rusu", "tidak di rumah"),
        ("保守", "hoshu", "konservatif/perawatan"),
    ], [
        ("約束を守ります。", "Yakusoku o mamorimasu.", "Saya akan menepati janji."),
        ("母は留守です。", "Haha wa rusu desu.", "Ibu sedang tidak di rumah."),
    ]),
    ("shu4_n3", "種", ["シュ"], ["たね"], ["jenis", "biji", "kind", "seed"], 14, "禾", [
        ("種類", "shurui", "jenis"),
        ("種", "tane", "biji"),
        ("人種", "jinshu", "ras"),
    ], [
        ("いろいろな種類の花があります。", "Iroiro na shurui no hana ga arimasu.", "Ada berbagai jenis bunga."),
        ("花の種を植えました。", "Hana no tane o uemashita.", "Saya menanam biji bunga."),
    ]),
    ("bi2_n3", "美", ["ビ"], ["うつく-しい"], ["indah", "cantik", "beauty", "beautiful"], 9, "羊", [
        ("美しい", "utsukushii", "indah"),
        ("美術館", "bijutsukan", "museum seni"),
        ("美容院", "biyouin", "salon kecantikan"),
    ], [
        ("美しい景色ですね。", "Utsukushii keshiki desu ne.", "Pemandangan yang indah, ya."),
        ("週末、美術館へ行きます。", "Shuumatsu, bijutsukan e ikimasu.", "Akhir pekan saya akan pergi ke museum seni."),
    ]),
    ("mei_n3", "命", ["メイ", "ミョウ"], ["いのち"], ["nyawa", "perintah", "life", "command"], 8, "口", [
        ("命", "inochi", "nyawa"),
        ("生命", "seimei", "kehidupan"),
        ("命令", "meirei", "perintah"),
    ], [
        ("命を大切にしてください。", "Inochi o taisetsu ni shite kudasai.", "Tolong hargai nyawa Anda."),
        ("上司の命令に従います。", "Joushi no meirei ni shitagaimasu.", "Saya mengikuti perintah atasan."),
    ]),
    ("fuku_n3", "福", ["フク"], [], ["berkah", "keberuntungan", "blessing", "fortune"], 13, "礻", [
        ("幸福", "koufuku", "kebahagiaan"),
        ("福祉", "fukushi", "kesejahteraan"),
        ("祝福", "shukufuku", "berkah/ucapan selamat"),
    ], [
        ("家族の幸福を願っています。", "Kazoku no koufuku o negatte imasu.", "Saya berharap kebahagiaan untuk keluarga."),
        ("結婚を祝福します。", "Kekkon o shukufuku shimasu.", "Saya mengucapkan selamat atas pernikahannya."),
    ]),
    ("bou_n3", "望", ["ボウ", "モウ"], ["のぞ-む"], ["harapan", "hasrat", "hope", "wish"], 11, "月", [
        ("希望", "kibou", "harapan"),
        ("望む", "nozomu", "mengharapkan"),
        ("展望", "tenbou", "pemandangan/prospek"),
    ], [
        ("将来への希望を持っています。", "Shourai e no kibou o motte imasu.", "Saya memiliki harapan untuk masa depan."),
        ("幸せを望んでいます。", "Shiawase o nozonde imasu.", "Saya mengharapkan kebahagiaan."),
    ]),
    # --- Batch H: 非観察段横申財港識呼達良候程満敗値突路積他処 (22) ---
    ("hi2_n3", "非", ["ヒ"], ["あら-ず"], ["bukan", "tidak", "un-", "non-"], 8, "非", [
        ("非常に", "hijou ni", "sangat"),
        ("非常口", "hijouguchi", "pintu darurat"),
        ("非公開", "hikoukai", "tidak dipublikasikan"),
    ], [
        ("この料理は非常においしいです。", "Kono ryouri wa hijou ni oishii desu.", "Masakan ini sangat enak."),
        ("非常口はあちらです。", "Hijouguchi wa achira desu.", "Pintu darurat ada di sana."),
    ]),
    ("kan3_n3", "観", ["カン"], ["み-る"], ["pandangan", "menonton", "view", "watch"], 18, "見", [
        ("観光", "kankou", "wisata"),
        ("観察", "kansatsu", "observasi"),
        ("観客", "kankyaku", "penonton"),
    ], [
        ("京都で観光しました。", "Kyouto de kankou shimashita.", "Saya berwisata di Kyoto."),
        ("昆虫を観察しています。", "Konchuu o kansatsu shite imasu.", "Saya mengamati serangga."),
    ]),
    ("satsu_n3", "察", ["サツ"], [], ["menduga", "memeriksa", "guess", "inspect"], 14, "宀", [
        ("警察", "keisatsu", "polisi"),
        ("観察", "kansatsu", "observasi"),
        ("察する", "sassuru", "menduga/memahami"),
    ], [
        ("警察に届けました。", "Keisatsu ni todokemashita.", "Saya melaporkan ke polisi."),
        ("彼の気持ちを察しました。", "Kare no kimochi o sasshimashita.", "Saya memahami perasaannya."),
    ]),
    ("dan3_n3", "段", ["ダン"], [], ["tingkat", "tangga", "grade", "step"], 9, "殳", [
        ("階段", "kaidan", "tangga"),
        ("値段", "nedan", "harga"),
        ("手段", "shudan", "cara/sarana"),
    ], [
        ("階段を上ってください。", "Kaidan o nobotte kudasai.", "Tolong naik tangga."),
        ("この靴の値段はいくらですか。", "Kono kutsu no nedan wa ikura desu ka.", "Berapa harga sepatu ini?"),
    ]),
    ("ou_n3", "横", ["オウ"], ["よこ"], ["samping", "horizontal", "side", "horizontal"], 15, "木", [
        ("横", "yoko", "samping"),
        ("横断歩道", "oudanhodou", "zebra cross"),
        ("横浜", "Yokohama", "Yokohama"),
    ], [
        ("私の横に座ってください。", "Watashi no yoko ni suwatte kudasai.", "Tolong duduk di samping saya."),
        ("横断歩道を渡りましょう。", "Oudanhodou o watarimashou.", "Ayo menyeberang di zebra cross."),
    ]),
    ("shin3_n3", "申", ["シン"], ["もう-す"], ["mengatakan (sopan)", "say (humble)"], 5, "田", [
        ("申す", "mousu", "mengatakan, bentuk sopan"),
        ("申し込む", "moushikomu", "mendaftar"),
        ("申請", "shinsei", "permohonan"),
    ], [
        ("田中と申します。", "Tanaka to moushimasu.", "Nama saya Tanaka (sopan)."),
        ("ビザを申請しました。", "Biza o shinsei shimashita.", "Saya mengajukan permohonan visa."),
    ]),
    ("zai_n3", "財", ["ザイ", "サイ"], [], ["harta", "kekayaan", "wealth", "property"], 10, "貝", [
        ("財布", "saifu", "dompet"),
        ("財産", "zaisan", "harta/kekayaan"),
        ("財政", "zaisei", "keuangan"),
    ], [
        ("財布をなくしました。", "Saifu o nakushimashita.", "Saya kehilangan dompet."),
        ("彼は財産がたくさんあります。", "Kare wa zaisan ga takusan arimasu.", "Dia memiliki banyak harta."),
    ]),
    ("kou4_n3", "港", ["コウ"], ["みなと"], ["pelabuhan", "harbor", "port"], 12, "氵", [
        ("港", "minato", "pelabuhan"),
        ("空港", "kuukou", "bandara"),
        ("香港", "honkon", "Hong Kong"),
    ], [
        ("港に船が着きました。", "Minato ni fune ga tsukimashita.", "Kapal tiba di pelabuhan."),
        ("空港まで送ります。", "Kuukou made okurimasu.", "Saya akan mengantar Anda ke bandara."),
    ]),
    ("shiki2_n3", "識", ["シキ"], [], ["pengetahuan", "kesadaran", "knowledge", "consciousness"], 19, "言", [
        ("意識", "ishiki", "kesadaran"),
        ("知識", "chishiki", "pengetahuan"),
        ("常識", "joushiki", "akal sehat"),
    ], [
        ("事故で意識を失いました。", "Jiko de ishiki o ushinaimashita.", "Dia kehilangan kesadaran karena kecelakaan."),
        ("それは常識です。", "Sore wa joushiki desu.", "Itu adalah akal sehat/hal yang wajar."),
    ]),
    ("ko2_n3", "呼", ["コ"], ["よ-ぶ"], ["memanggil", "call", "invite"], 8, "口", [
        ("呼ぶ", "yobu", "memanggil"),
        ("呼吸", "kokyuu", "pernapasan"),
        ("呼び出す", "yobidasu", "memanggil keluar"),
    ], [
        ("タクシーを呼びました。", "Takushii o yobimashita.", "Saya memanggil taksi."),
        ("深く呼吸してください。", "Fukaku kokyuu shite kudasai.", "Tolong bernapas dalam-dalam."),
    ]),
    ("tatsu_n3", "達", ["タツ"], [], ["mencapai", "tercapai", "reach", "attain"], 12, "辶", [
        ("友達", "tomodachi", "teman"),
        ("達成", "tassei", "pencapaian"),
        ("発達", "hattatsu", "perkembangan"),
    ], [
        ("友達と映画を見ました。", "Tomodachi to eiga o mimashita.", "Saya menonton film dengan teman."),
        ("目標を達成しました。", "Mokuhyou o tassei shimashita.", "Saya mencapai target."),
    ]),
    ("ryou2_n3", "良", ["リョウ"], ["よ-い"], ["baik", "bagus", "good"], 7, "艮", [
        ("良い", "yoi", "baik"),
        ("良心", "ryoushin", "hati nurani"),
        ("改良", "kairyou", "perbaikan"),
    ], [
        ("これは良い考えです。", "Kore wa yoi kangae desu.", "Ini adalah ide yang bagus."),
        ("製品を改良しました。", "Seihin o kairyou shimashita.", "Kami memperbaiki produknya."),
    ]),
    ("kou5_n3", "候", ["コウ"], ["そうろう"], ["musim", "iklim", "climate", "season"], 10, "亻", [
        ("気候", "kikou", "iklim"),
        ("候補", "kouho", "kandidat"),
        ("天候", "tenkou", "cuaca"),
    ], [
        ("この地域の気候は暖かいです。", "Kono chiiki no kikou wa atatakai desu.", "Iklim daerah ini hangat."),
        ("彼は次の選挙の候補です。", "Kare wa tsugi no senkyo no kouho desu.", "Dia adalah kandidat untuk pemilu berikutnya."),
    ]),
    ("tei2_n3", "程", ["テイ"], ["ほど"], ["derajat", "tingkat", "extent", "degree"], 12, "禾", [
        ("程度", "teido", "tingkat/derajat"),
        ("先程", "sakihodo", "tadi/barusan"),
        ("過程", "katei", "proses"),
    ], [
        ("どの程度かかりますか。", "Dono teido kakarimasu ka.", "Kira-kira berapa lama/banyak?"),
        ("先程、電話がありました。", "Sakihodo, denwa ga arimashita.", "Tadi ada telepon."),
    ]),
    ("man_n3", "満", ["マン"], ["み-ちる"], ["penuh", "cukup", "full", "enough"], 12, "氵", [
        ("満足", "manzoku", "kepuasan"),
        ("満員", "man'in", "penuh/tidak ada tempat"),
        ("不満", "fuman", "ketidakpuasan"),
    ], [
        ("結果に満足しています。", "Kekka ni manzoku shite imasu.", "Saya puas dengan hasilnya."),
        ("電車は満員でした。", "Densha wa man'in deshita.", "Keretanya penuh sesak."),
    ]),
    ("hai_n3", "敗", ["ハイ"], ["やぶ-れる"], ["kegagalan", "kekalahan", "failure", "defeat"], 11, "貝", [
        ("失敗", "shippai", "kegagalan"),
        ("敗北", "haiboku", "kekalahan"),
        ("勝敗", "shouhai", "menang kalah"),
    ], [
        ("失敗から学びます。", "Shippai kara manabimasu.", "Saya belajar dari kegagalan."),
        ("試合の勝敗が決まりました。", "Shiai no shouhai ga kimarimashita.", "Menang-kalah pertandingan sudah ditentukan."),
    ]),
    ("chi2_n3", "値", ["チ"], ["ね", "あたい"], ["harga", "nilai", "price", "value"], 10, "亻", [
        ("値段", "nedan", "harga"),
        ("価値", "kachi", "nilai"),
        ("数値", "suuchi", "nilai numerik"),
    ], [
        ("この本の値段は高いです。", "Kono hon no nedan wa takai desu.", "Harga buku ini mahal."),
        ("この経験には価値があります。", "Kono keiken ni wa kachi ga arimasu.", "Pengalaman ini berharga."),
    ]),
    ("totsu_n3", "突", ["トツ"], ["つ-く"], ["menusuk", "tiba-tiba", "stab", "sudden"], 8, "穴", [
        ("突然", "totsuzen", "tiba-tiba"),
        ("衝突", "shoutotsu", "tabrakan"),
        ("突く", "tsuku", "menusuk"),
    ], [
        ("突然雨が降ってきました。", "Totsuzen ame ga futte kimashita.", "Tiba-tiba hujan turun."),
        ("車が衝突しました。", "Kuruma ga shoutotsu shimashita.", "Mobil bertabrakan."),
    ]),
    ("ro_n3", "路", ["ロ"], [], ["jalan", "rute", "road", "route"], 13, "足", [
        ("道路", "douro", "jalan raya"),
        ("通路", "tsuuro", "gang/lorong"),
        ("線路", "senro", "rel kereta"),
    ], [
        ("この道路は広いです。", "Kono douro wa hiroi desu.", "Jalan raya ini lebar."),
        ("線路の近くに住んでいます。", "Senro no chikaku ni sunde imasu.", "Saya tinggal dekat rel kereta."),
    ]),
    ("seki2_n3", "積", ["セキ"], ["つ-む", "つ-もる"], ["menumpuk", "volume", "pile up", "accumulate"], 16, "禾", [
        ("積む", "tsumu", "menumpuk"),
        ("面積", "menseki", "luas area"),
        ("積極的", "sekkyokuteki", "aktif/proaktif"),
    ], [
        ("トラックに荷物を積みました。", "Torakku ni nimotsu o tsumimashita.", "Saya menumpuk barang di truk."),
        ("この部屋の面積は広いです。", "Kono heya no menseki wa hiroi desu.", "Luas kamar ini besar."),
    ]),
    ("ta_n3", "他", ["タ"], ["ほか"], ["lain", "yang lain", "other"], 5, "亻", [
        ("その他", "sono hoka", "selain itu"),
        ("他人", "tanin", "orang lain"),
        ("他国", "takoku", "negara lain"),
    ], [
        ("他に質問がありますか。", "Hoka ni shitsumon ga arimasu ka.", "Ada pertanyaan lain?"),
        ("他人に迷惑をかけないでください。", "Tanin ni meiwaku o kakenaide kudasai.", "Jangan mengganggu orang lain."),
    ]),
    ("sho2_n3", "処", ["ショ"], [], ["mengurus", "menangani", "handle", "deal with"], 5, "几", [
        ("処理", "shori", "penanganan"),
        ("対処", "taisho", "mengatasi"),
        ("処方箋", "shohousen", "resep obat"),
    ], [
        ("このデータを処理してください。", "Kono deeta o shori shite kudasai.", "Tolong proses data ini."),
        ("問題に対処しました。", "Mondai ni taisho shimashita.", "Saya sudah mengatasi masalahnya."),
    ]),
    # --- Batch I: 客否師登易速存殺号単座破除完責捕危給迎園具辞 (22) ---
    ("kyaku_n3", "客", ["キャク", "カク"], [], ["tamu", "pelanggan", "guest", "customer"], 9, "宀", [
        ("お客さん", "okyakusan", "pelanggan/tamu"),
        ("観光客", "kankoukyaku", "wisatawan"),
        ("乗客", "joukyaku", "penumpang"),
    ], [
        ("お客さんが来ました。", "Okyakusan ga kimashita.", "Tamu sudah datang."),
        ("この電車は乗客が多いです。", "Kono densha wa joukyaku ga ooi desu.", "Kereta ini banyak penumpangnya."),
    ]),
    ("hi3_n3", "否", ["ヒ"], ["いな"], ["menyangkal", "menolak", "deny", "no"], 7, "口", [
        ("否定", "hitei", "penyangkalan"),
        ("拒否", "kyohi", "penolakan"),
        ("賛否", "sanpi", "setuju atau tidak"),
    ], [
        ("彼はその話を否定しました。", "Kare wa sono hanashi o hitei shimashita.", "Dia menyangkal cerita itu."),
        ("提案は拒否されました。", "Teian wa kyohi saremashita.", "Usulannya ditolak."),
    ]),
    ("shi5_n3", "師", ["シ"], [], ["guru", "ahli", "teacher", "expert"], 10, "巾", [
        ("医師", "ishi", "dokter"),
        ("教師", "kyoushi", "guru"),
        ("美容師", "biyoushi", "penata rambut"),
    ], [
        ("兄は医師です。", "Ani wa ishi desu.", "Kakak laki-laki saya adalah dokter."),
        ("彼女は英語の教師です。", "Kanojo wa eigo no kyoushi desu.", "Dia adalah guru bahasa Inggris."),
    ]),
    ("tou3_n3", "登", ["トウ", "ト"], ["のぼ-る"], ["mendaki", "naik", "climb", "ascend"], 12, "癶", [
        ("登る", "noboru", "mendaki"),
        ("登山", "tozan", "pendakian gunung"),
        ("登録", "touroku", "registrasi"),
    ], [
        ("富士山に登りたいです。", "Fujisan ni noboritai desu.", "Saya ingin mendaki Gunung Fuji."),
        ("このアプリに登録しました。", "Kono apuri ni touroku shimashita.", "Saya mendaftar di aplikasi ini."),
    ]),
    ("eki_n3", "易", ["エキ", "イ"], ["やさ-しい"], ["mudah", "sederhana", "easy", "simple"], 8, "日", [
        ("容易", "youi", "mudah"),
        ("貿易", "boueki", "perdagangan"),
        ("安易", "an'i", "gampang/sembarangan"),
    ], [
        ("この問題は容易です。", "Kono mondai wa youi desu.", "Soal ini mudah."),
        ("日本は貿易が盛んです。", "Nihon wa boueki ga sakan desu.", "Jepang giat dalam perdagangan."),
    ]),
    ("soku2_n3", "速", ["ソク"], ["はや-い"], ["cepat", "quick", "fast"], 10, "辶", [
        ("速い", "hayai", "cepat"),
        ("速度", "sokudo", "kecepatan"),
        ("高速道路", "kousoku douro", "jalan tol"),
    ], [
        ("新幹線は速いです。", "Shinkansen wa hayai desu.", "Shinkansen cepat."),
        ("車の速度を落としてください。", "Kuruma no sokudo o otoshite kudasai.", "Tolong kurangi kecepatan mobil."),
    ]),
    ("son_n3", "存", ["ソン", "ゾン"], [], ["ada", "berpikir", "exist", "believe"], 6, "子", [
        ("存在", "sonzai", "keberadaan"),
        ("存じる", "zonjiru", "mengetahui, bentuk sopan"),
        ("保存", "hozon", "penyimpanan"),
    ], [
        ("幽霊の存在を信じますか。", "Yuurei no sonzai o shinjimasu ka.", "Apakah Anda percaya keberadaan hantu?"),
        ("データを保存してください。", "Deeta o hozon shite kudasai.", "Tolong simpan datanya."),
    ]),
    ("satsu2_n3", "殺", ["サツ"], ["ころ-す"], ["membunuh", "kill"], 10, "殳", [
        ("殺す", "korosu", "membunuh"),
        ("自殺", "jisatsu", "bunuh diri"),
        ("忙殺", "bousatsu", "sangat sibuk"),
    ], [
        ("虫を殺さないでください。", "Mushi o korosanaide kudasai.", "Tolong jangan bunuh serangganya."),
        ("彼は仕事に忙殺されています。", "Kare wa shigoto ni bousatsu sarete imasu.", "Dia sangat sibuk dengan pekerjaan."),
    ]),
    ("gou_n3", "号", ["ゴウ"], [], ["nomor", "edisi", "number", "issue"], 5, "口", [
        ("番号", "bangou", "nomor"),
        ("信号", "shingou", "lampu lalu lintas"),
        ("号室", "goushitsu", "nomor kamar"),
    ], [
        ("信号が赤です。", "Shingou ga aka desu.", "Lampu lalu lintasnya merah."),
        ("部屋の号室は何番ですか。", "Heya no goushitsu wa nanban desu ka.", "Nomor kamarnya berapa?"),
    ]),
    ("tan_n3", "単", ["タン"], [], ["sederhana", "tunggal", "simple", "single"], 9, "十", [
        ("簡単", "kantan", "sederhana/mudah"),
        ("単語", "tango", "kosakata"),
        ("単純", "tanjun", "simpel"),
    ], [
        ("この料理は簡単です。", "Kono ryouri wa kantan desu.", "Masakan ini mudah."),
        ("毎日単語を覚えます。", "Mainichi tango o oboemasu.", "Setiap hari saya menghafal kosakata."),
    ]),
    ("za_n3", "座", ["ザ"], ["すわ-る"], ["duduk", "tempat duduk", "sit", "seat"], 10, "广", [
        ("座る", "suwaru", "duduk"),
        ("座席", "zaseki", "tempat duduk"),
        ("銀座", "Ginza", "Ginza"),
    ], [
        ("どうぞ座ってください。", "Douzo suwatte kudasai.", "Silakan duduk."),
        ("座席を予約しました。", "Zaseki o yoyaku shimashita.", "Saya sudah memesan tempat duduk."),
    ]),
    ("ha_n3", "破", ["ハ"], ["やぶ-る"], ["merobek", "menghancurkan", "tear", "destroy"], 10, "石", [
        ("破る", "yaburu", "merobek/melanggar"),
        ("破壊", "hakai", "kehancuran"),
        ("突破", "toppa", "menembus/terobosan"),
    ], [
        ("紙を破りました。", "Kami o yaburimashita.", "Saya merobek kertas."),
        ("台風で建物が破壊されました。", "Taifuu de tatemono ga hakai saremashita.", "Bangunan hancur karena topan."),
    ]),
    ("jo2_n3", "除", ["ジョ"], ["のぞ-く"], ["menghilangkan", "mengecualikan", "remove", "exclude"], 10, "阝", [
        ("除く", "nozoku", "menghilangkan/mengecualikan"),
        ("掃除", "souji", "membersihkan"),
        ("解除", "kaijo", "pembatalan/pencabutan"),
    ], [
        ("毎週、部屋を掃除します。", "Maishuu, heya o souji shimasu.", "Setiap minggu saya membersihkan kamar."),
        ("警報が解除されました。", "Keihou ga kaijo saremashita.", "Peringatan sudah dicabut."),
    ]),
    ("kan4_n3", "完", ["カン"], [], ["sempurna", "selesai", "complete", "perfect"], 7, "宀", [
        ("完成", "kansei", "penyelesaian"),
        ("完全", "kanzen", "sempurna"),
        ("未完成", "mikansei", "belum selesai"),
    ], [
        ("作品が完成しました。", "Sakuhin ga kansei shimashita.", "Karyanya sudah selesai."),
        ("完全に理解しました。", "Kanzen ni rikai shimashita.", "Saya benar-benar mengerti."),
    ]),
    ("seki3_n3", "責", ["セキ"], ["せ-める"], ["menyalahkan", "tanggung jawab", "blame", "responsibility"], 11, "貝", [
        ("責任", "sekinin", "tanggung jawab"),
        ("責める", "semeru", "menyalahkan"),
        ("自責", "jiseki", "menyalahkan diri sendiri"),
    ], [
        ("これは私の責任です。", "Kore wa watashi no sekinin desu.", "Ini adalah tanggung jawab saya."),
        ("自分を責めないでください。", "Jibun o semenaide kudasai.", "Jangan menyalahkan diri sendiri."),
    ]),
    ("ho_n3", "捕", ["ホ"], ["と-らえる", "つか-まえる"], ["menangkap", "catch", "capture"], 10, "扌", [
        ("捕まえる", "tsukamaeru", "menangkap"),
        ("逮捕", "taiho", "penangkapan"),
        ("捕まる", "tsukamaru", "tertangkap"),
    ], [
        ("警察が犯人を捕まえました。", "Keisatsu ga hannin o tsukamaemashita.", "Polisi menangkap pelaku."),
        ("泥棒が逮捕されました。", "Dorobou ga taiho saremashita.", "Pencuri itu ditangkap."),
    ]),
    ("ki5_n3", "危", ["キ"], ["あぶ-ない"], ["berbahaya", "dangerous"], 6, "匚", [
        ("危ない", "abunai", "berbahaya"),
        ("危険", "kiken", "bahaya"),
        ("危機", "kiki", "krisis"),
    ], [
        ("このプールは危ないです。", "Kono puuru wa abunai desu.", "Kolam renang ini berbahaya."),
        ("危険なので気をつけてください。", "Kiken na node ki o tsukete kudasai.", "Berbahaya, jadi harap hati-hati."),
    ]),
    ("kyuu3_n3", "給", ["キュウ"], [], ["gaji", "memberi", "salary", "supply"], 12, "糸", [
        ("給料", "kyuuryou", "gaji"),
        ("給食", "kyuushoku", "makan siang sekolah"),
        ("支給", "shikyuu", "pemberian tunjangan"),
    ], [
        ("今月の給料をもらいました。", "Kongetsu no kyuuryou o moraimashita.", "Saya menerima gaji bulan ini."),
        ("学校で給食を食べます。", "Gakkou de kyuushoku o tabemasu.", "Saya makan makan siang sekolah di sekolah."),
    ]),
    ("gei_n3", "迎", ["ゲイ"], ["むか-える"], ["menyambut", "menjemput", "welcome", "greet"], 7, "辶", [
        ("迎える", "mukaeru", "menyambut/menjemput"),
        ("歓迎", "kangei", "penyambutan"),
        ("送迎", "sougei", "antar-jemput"),
    ], [
        ("駅まで迎えに行きます。", "Eki made mukae ni ikimasu.", "Saya akan menjemput ke stasiun."),
        ("皆さんを歓迎します。", "Minasan o kangei shimasu.", "Kami menyambut kalian semua."),
    ]),
    ("en2_n3", "園", ["エン"], [], ["taman", "kebun", "park", "garden"], 13, "囗", [
        ("公園", "kouen", "taman"),
        ("幼稚園", "youchien", "TK"),
        ("動物園", "doubutsuen", "kebun binatang"),
    ], [
        ("子供たちが公園で遊んでいます。", "Kodomotachi ga kouen de asonde imasu.", "Anak-anak bermain di taman."),
        ("週末、動物園へ行きました。", "Shuumatsu, doubutsuen e ikimashita.", "Akhir pekan saya pergi ke kebun binatang."),
    ]),
    ("gu_n3", "具", ["グ"], [], ["alat", "perlengkapan", "tool", "equipment"], 8, "八", [
        ("道具", "dougu", "alat"),
        ("家具", "kagu", "furnitur"),
        ("文房具", "bunbougu", "alat tulis"),
    ], [
        ("この道具は便利です。", "Kono dougu wa benri desu.", "Alat ini praktis."),
        ("新しい家具を買いました。", "Atarashii kagu o kaimashita.", "Saya membeli furnitur baru."),
    ]),
    ("ji4_n3", "辞", ["ジ"], ["や-める"], ["mengundurkan diri", "kata", "resign", "word"], 13, "舌", [
        ("辞書", "jisho", "kamus"),
        ("辞める", "yameru", "mengundurkan diri"),
        ("辞退", "jitai", "menolak dengan sopan"),
    ], [
        ("辞書で言葉を調べます。", "Jisho de kotoba o shirabemasu.", "Saya mencari kata di kamus."),
        ("会社を辞めました。", "Kaisha o yamemashita.", "Saya berhenti dari perusahaan."),
    ]),
    # --- Batch J: 因馬愛富彼未舞亡冷適婦寄込類余王妻背熱宿薬険 (22) ---
    ("in2_n3", "因", ["イン"], ["よ-る"], ["penyebab", "faktor", "cause", "factor"], 6, "囗", [
        ("原因", "gen'in", "penyebab"),
        ("因る", "yoru", "disebabkan oleh"),
        ("要因", "youin", "faktor"),
    ], [
        ("事故の原因は何ですか。", "Jiko no gen'in wa nan desu ka.", "Apa penyebab kecelakaannya?"),
        ("成功の要因を分析します。", "Seikou no youin o bunseki shimasu.", "Saya menganalisis faktor kesuksesan."),
    ]),
    ("ba_n3", "馬", ["バ"], ["うま"], ["kuda", "horse"], 10, "馬", [
        ("馬", "uma", "kuda"),
        ("競馬", "keiba", "pacuan kuda"),
        ("乗馬", "jouba", "menunggang kuda"),
    ], [
        ("馬に乗ったことがありますか。", "Uma ni notta koto ga arimasu ka.", "Pernahkah Anda menunggang kuda?"),
        ("週末、競馬を見ました。", "Shuumatsu, keiba o mimashita.", "Akhir pekan saya menonton pacuan kuda."),
    ]),
    ("ai_n3", "愛", ["アイ"], [], ["cinta", "kasih sayang", "love", "affection"], 13, "心", [
        ("愛", "ai", "cinta"),
        ("愛する", "aisuru", "mencintai"),
        ("恋愛", "ren'ai", "percintaan"),
    ], [
        ("家族を愛しています。", "Kazoku o aishite imasu.", "Saya menyayangi keluarga saya."),
        ("恋愛映画が好きです。", "Ren'ai eiga ga suki desu.", "Saya suka film percintaan."),
    ]),
    ("fu4_n3", "富", ["フ"], ["と-む"], ["kekayaan", "kaya", "wealth", "rich"], 12, "宀", [
        ("豊富", "houfu", "melimpah"),
        ("富士山", "Fujisan", "Gunung Fuji"),
        ("富む", "tomu", "kaya akan"),
    ], [
        ("この国は資源が豊富です。", "Kono kuni wa shigen ga houfu desu.", "Negara ini kaya akan sumber daya."),
        ("富士山は日本一高い山です。", "Fujisan wa Nihon ichi takai yama desu.", "Gunung Fuji adalah gunung tertinggi di Jepang."),
    ]),
    ("hi4_n3", "彼", ["ヒ"], ["かれ"], ["dia (laki-laki)", "itu", "he", "that"], 8, "彳", [
        ("彼", "kare", "dia (laki-laki)"),
        ("彼女", "kanojo", "dia (perempuan)/pacar"),
        ("彼氏", "kareshi", "pacar (laki-laki)"),
    ], [
        ("彼は学生です。", "Kare wa gakusei desu.", "Dia adalah siswa."),
        ("彼氏はいますか。", "Kareshi wa imasu ka.", "Apakah Anda punya pacar?"),
    ]),
    ("mi_n3", "未", ["ミ"], ["いま-だ"], ["belum", "tidak", "not yet", "un-"], 5, "木", [
        ("未来", "mirai", "masa depan"),
        ("未成年", "miseinen", "di bawah umur"),
        ("未定", "mitei", "belum ditentukan"),
    ], [
        ("未来のことを考えています。", "Mirai no koto o kangaete imasu.", "Saya sedang memikirkan tentang masa depan."),
        ("予定はまだ未定です。", "Yotei wa mada mitei desu.", "Jadwalnya masih belum ditentukan."),
    ]),
    ("bu_n3", "舞", ["ブ"], ["ま-う"], ["menari", "dance"], 15, "舛", [
        ("舞台", "butai", "panggung"),
        ("舞う", "mau", "menari"),
        ("歌舞伎", "kabuki", "kabuki"),
    ], [
        ("舞台で歌います。", "Butai de utaimasu.", "Saya bernyanyi di panggung."),
        ("歌舞伎を見たことがあります。", "Kabuki o mita koto ga arimasu.", "Saya pernah menonton kabuki."),
    ]),
    ("bou2_n3", "亡", ["ボウ"], ["な-い"], ["meninggal", "hilang", "deceased", "die"], 3, "亠", [
        ("死亡", "shibou", "kematian"),
        ("亡くなる", "nakunaru", "meninggal dunia"),
        ("亡命", "boumei", "pengasingan diri"),
    ], [
        ("祖父が亡くなりました。", "Sofu ga nakunarimashita.", "Kakek saya meninggal dunia."),
        ("事故で死亡者が出ました。", "Jiko de shibousha ga demashita.", "Ada korban jiwa akibat kecelakaan."),
    ]),
    ("rei_n3", "冷", ["レイ"], ["つめ-たい", "ひ-える"], ["dingin", "sejuk", "cold", "cool"], 7, "冫", [
        ("冷たい", "tsumetai", "dingin"),
        ("冷蔵庫", "reizouko", "kulkas"),
        ("冷える", "hieru", "menjadi dingin"),
    ], [
        ("水が冷たいです。", "Mizu ga tsumetai desu.", "Airnya dingin."),
        ("冷蔵庫に牛乳があります。", "Reizouko ni gyuunyuu ga arimasu.", "Ada susu di kulkas."),
    ]),
    ("teki_n3", "適", ["テキ"], [], ["cocok", "sesuai", "suitable", "fit"], 14, "辶", [
        ("適当", "tekitou", "sembarangan/cukup pantas"),
        ("快適", "kaiteki", "nyaman"),
        ("適切", "tekisetsu", "tepat"),
    ], [
        ("適当に選んでください。", "Tekitou ni erande kudasai.", "Tolong pilih sesuka Anda."),
        ("このホテルは快適です。", "Kono hoteru wa kaiteki desu.", "Hotel ini nyaman."),
    ]),
    ("fu5_n3", "婦", ["フ"], [], ["wanita", "istri", "woman", "wife"], 11, "女", [
        ("主婦", "shufu", "ibu rumah tangga"),
        ("夫婦", "fuufu", "pasangan suami istri"),
        ("婦人", "fujin", "wanita"),
    ], [
        ("母は主婦です。", "Haha wa shufu desu.", "Ibu saya adalah ibu rumah tangga."),
        ("あの夫婦は仲がいいです。", "Ano fuufu wa naka ga ii desu.", "Pasangan suami istri itu akur."),
    ]),
    ("ki6_n3", "寄", ["キ"], ["よ-る"], ["mendekat", "mampir", "approach", "drop by"], 11, "宀", [
        ("寄る", "yoru", "mampir/mendekat"),
        ("寄付", "kifu", "donasi"),
        ("最寄り", "moyori", "terdekat"),
    ], [
        ("帰りにスーパーに寄ります。", "Kaeri ni suupaa ni yorimasu.", "Saya akan mampir ke supermarket saat pulang."),
        ("慈善団体に寄付しました。", "Jizen dantai ni kifu shimashita.", "Saya berdonasi ke organisasi amal."),
    ]),
    ("komi_n3", "込", [], ["こ-む", "こ-める"], ["ramai", "termasuk", "crowded", "included"], 5, "辶", [
        ("込む", "komu", "ramai/padat"),
        ("申し込む", "moushikomu", "mendaftar"),
        ("税込み", "zeikomi", "sudah termasuk pajak"),
    ], [
        ("電車が込んでいます。", "Densha ga konde imasu.", "Keretanya padat."),
        ("このコースに申し込みました。", "Kono koosu ni moushikomimashita.", "Saya mendaftar untuk kursus ini."),
    ]),
    ("rui_n3", "類", ["ルイ"], ["たぐ-い"], ["jenis", "macam", "kind", "sort"], 18, "頁", [
        ("種類", "shurui", "jenis"),
        ("書類", "shorui", "dokumen"),
        ("人類", "jinrui", "umat manusia"),
    ], [
        ("この書類にサインしてください。", "Kono shorui ni sain shite kudasai.", "Tolong tanda tangani dokumen ini."),
        ("人類の歴史は長いです。", "Jinrui no rekishi wa nagai desu.", "Sejarah umat manusia panjang."),
    ]),
    ("yo3_n3", "余", ["ヨ"], ["あま-る"], ["berlebih", "sisa", "surplus", "remainder"], 7, "人", [
        ("余る", "amaru", "tersisa/berlebih"),
        ("余裕", "yoyuu", "keleluasaan/waktu senggang"),
        ("余計", "yokei", "berlebihan/tidak perlu"),
    ], [
        ("時間が余っています。", "Jikan ga amatte imasu.", "Waktunya masih tersisa."),
        ("余裕を持って行動します。", "Yoyuu o motte koudou shimasu.", "Saya bertindak dengan tenang/santai."),
    ]),
    ("ou2_n3", "王", ["オウ"], [], ["raja", "king"], 4, "玉", [
        ("王様", "ousama", "raja"),
        ("女王", "joou", "ratu"),
        ("王国", "oukoku", "kerajaan"),
    ], [
        ("昔、この国に王様がいました。", "Mukashi, kono kuni ni ousama ga imashita.", "Dahulu, negara ini memiliki raja."),
        ("あの国は小さい王国です。", "Ano kuni wa chiisai oukoku desu.", "Negara itu adalah kerajaan kecil."),
    ]),
    ("sai5_n3", "妻", ["サイ"], ["つま"], ["istri", "wife"], 8, "女", [
        ("妻", "tsuma", "istri (saya)"),
        ("夫妻", "fusai", "suami istri"),
        ("人妻", "hitozuma", "istri orang"),
    ], [
        ("私の妻は看護師です。", "Watashi no tsuma wa kangoshi desu.", "Istri saya adalah perawat."),
        ("ご夫妻はお元気ですか。", "Gofusai wa ogenki desu ka.", "Apakah Bapak dan Ibu sehat?"),
    ]),
    ("hai2_n3", "背", ["ハイ"], ["せ", "そむ-く"], ["punggung", "tinggi badan", "back", "height"], 9, "肉", [
        ("背が高い", "se ga takai", "tinggi badan"),
        ("背中", "senaka", "punggung"),
        ("背景", "haikei", "latar belakang"),
    ], [
        ("彼は背が高いです。", "Kare wa se ga takai desu.", "Dia tinggi."),
        ("この写真の背景がきれいです。", "Kono shashin no haikei ga kirei desu.", "Latar belakang foto ini indah."),
    ]),
    ("netsu_n3", "熱", ["ネツ"], ["あつ-い"], ["panas", "demam", "heat", "fever"], 15, "灬", [
        ("熱", "netsu", "demam/panas"),
        ("熱心", "nesshin", "antusias/tekun"),
        ("情熱", "jounetsu", "gairah"),
    ], [
        ("熱があります。", "Netsu ga arimasu.", "Saya demam."),
        ("彼は勉強に熱心です。", "Kare wa benkyou ni nesshin desu.", "Dia tekun belajar."),
    ]),
    ("shuku_n3", "宿", ["シュク"], ["やど"], ["penginapan", "tempat tinggal", "lodging", "inn"], 11, "宀", [
        ("宿題", "shukudai", "PR"),
        ("宿泊", "shukuhaku", "menginap"),
        ("民宿", "minshuku", "penginapan keluarga"),
    ], [
        ("宿題を終わらせました。", "Shukudai o owarasemashita.", "Saya sudah menyelesaikan PR."),
        ("温泉旅館に宿泊しました。", "Onsen ryokan ni shukuhaku shimashita.", "Saya menginap di penginapan sumber air panas."),
    ]),
    ("yaku3_n3", "薬", ["ヤク"], ["くすり"], ["obat", "medicine"], 16, "艹", [
        ("薬", "kusuri", "obat"),
        ("薬局", "yakkyoku", "apotek"),
        ("薬剤師", "yakuzaishi", "apoteker"),
    ], [
        ("薬を飲んでください。", "Kusuri o nonde kudasai.", "Tolong minum obatnya."),
        ("薬局で薬を買いました。", "Yakkyoku de kusuri o kaimashita.", "Saya membeli obat di apotek."),
    ]),
    ("ken3_n3", "険", ["ケン"], ["けわ-しい"], ["curam", "berbahaya", "steep", "risky"], 11, "阝", [
        ("危険", "kiken", "bahaya"),
        ("保険", "hoken", "asuransi"),
        ("冒険", "bouken", "petualangan"),
    ], [
        ("危険な場所に行かないでください。", "Kiken na basho ni ikanaide kudasai.", "Jangan pergi ke tempat berbahaya."),
        ("健康保険に入っています。", "Kenkou hoken ni haitte imasu.", "Saya memiliki asuransi kesehatan."),
    ]),
    # --- Batch K: 頼船途許抜便留罪努精散静婚喜浮絶幸押倒等老曲 (22) ---
    ("rai_n3", "頼", ["ライ"], ["たの-む", "たよ-る"], ["mempercayai", "meminta", "trust", "request"], 16, "頁", [
        ("頼む", "tanomu", "meminta tolong"),
        ("信頼", "shinrai", "kepercayaan"),
        ("依頼", "irai", "permintaan/pesanan"),
    ], [
        ("友達に手伝いを頼みました。", "Tomodachi ni tetsudai o tanomimashita.", "Saya meminta bantuan teman."),
        ("彼を信頼しています。", "Kare o shinrai shite imasu.", "Saya mempercayai dia."),
    ]),
    ("sen3_n3", "船", ["セン"], ["ふね"], ["kapal", "perahu", "ship", "boat"], 11, "舟", [
        ("船", "fune", "kapal"),
        ("船員", "sen'in", "awak kapal"),
        ("漁船", "gyosen", "kapal nelayan"),
    ], [
        ("船で島へ行きます。", "Fune de shima e ikimasu.", "Saya pergi ke pulau naik kapal."),
        ("父は船員です。", "Chichi wa sen'in desu.", "Ayah saya adalah awak kapal."),
    ]),
    ("to3_n3", "途", ["ト"], [], ["jalan", "rute", "route", "way"], 10, "辶", [
        ("途中", "tochuu", "di tengah jalan"),
        ("前途", "zento", "masa depan"),
        ("使途", "shito", "penggunaan (dana)"),
    ], [
        ("途中でコンビニに寄りました。", "Tochuu de konbini ni yorimashita.", "Saya mampir ke minimarket di tengah jalan."),
        ("彼女の前途は明るいです。", "Kanojo no zento wa akarui desu.", "Masa depannya cerah."),
    ]),
    ("kyo_n3", "許", ["キョ"], ["ゆる-す"], ["mengizinkan", "permit", "allow"], 11, "言", [
        ("許す", "yurusu", "mengizinkan/memaafkan"),
        ("許可", "kyoka", "izin"),
        ("免許", "menkyo", "SIM/lisensi"),
    ], [
        ("遅刻を許してください。", "Chikoku o yurushite kudasai.", "Tolong maafkan keterlambatan saya."),
        ("運転免許を取りました。", "Unten menkyo o torimashita.", "Saya sudah mendapatkan SIM."),
    ]),
    ("batsu_n3", "抜", ["バツ"], ["ぬ-く"], ["mencabut", "melewati", "pull out", "extract"], 7, "扌", [
        ("抜く", "nuku", "mencabut"),
        ("追い抜く", "oinuku", "menyalip"),
        ("抜群", "batsugun", "luar biasa/istimewa"),
    ], [
        ("歯を抜きました。", "Ha o nukimashita.", "Saya mencabut gigi."),
        ("彼は成績が抜群です。", "Kare wa seiseki ga batsugun desu.", "Nilainya luar biasa bagus."),
    ]),
    ("ben_n3", "便", ["ベン", "ビン"], ["たよ-り"], ["kenyamanan", "surat", "convenience", "mail"], 9, "亻", [
        ("便利", "benri", "praktis"),
        ("郵便", "yuubin", "pos"),
        ("航空便", "koukuubin", "surat udara/paket udara"),
    ], [
        ("このアプリはとても便利です。", "Kono apuri wa totemo benri desu.", "Aplikasi ini sangat praktis."),
        ("郵便局へ行きます。", "Yuubinkyoku e ikimasu.", "Saya pergi ke kantor pos."),
    ]),
    ("ryuu2_n3", "留", ["リュウ", "ル"], ["と-める", "と-まる"], ["menahan", "tetap", "detain", "stay"], 10, "田", [
        ("留学", "ryuugaku", "belajar di luar negeri"),
        ("留守", "rusu", "tidak di rumah"),
        ("留める", "tomeru", "menahan/mengencangkan"),
    ], [
        ("アメリカに留学したいです。", "Amerika ni ryuugaku shitai desu.", "Saya ingin belajar di Amerika."),
        ("今、母は留守です。", "Ima, haha wa rusu desu.", "Sekarang ibu sedang tidak di rumah."),
    ]),
    ("zai2_n3", "罪", ["ザイ"], ["つみ"], ["dosa", "kejahatan", "sin", "crime"], 13, "罒", [
        ("犯罪", "hanzai", "kejahatan"),
        ("罪", "tsumi", "dosa"),
        ("無罪", "muzai", "tidak bersalah"),
    ], [
        ("犯罪を防ぎましょう。", "Hanzai o fusegimashou.", "Ayo cegah kejahatan."),
        ("彼は無罪でした。", "Kare wa muzai deshita.", "Dia tidak bersalah."),
    ]),
    ("do_n3", "努", ["ド"], ["つと-める"], ["berusaha", "bekerja keras", "endeavor", "strive"], 7, "力", [
        ("努力", "doryoku", "usaha"),
        ("努める", "tsutomeru", "berusaha keras"),
        ("努力家", "doryokuka", "orang yang gigih/pekerja keras"),
    ], [
        ("合格するために努力します。", "Goukaku suru tame ni doryoku shimasu.", "Saya akan berusaha keras untuk lulus."),
        ("彼はいつも努力しています。", "Kare wa itsumo doryoku shite imasu.", "Dia selalu berusaha keras."),
    ]),
    ("sei5_n3", "精", ["セイ", "ショウ"], [], ["semangat", "teliti", "spirit", "precise"], 14, "米", [
        ("精神", "seishin", "jiwa/mental"),
        ("精一杯", "seiippai", "sekuat tenaga"),
        ("精密", "seimitsu", "presisi"),
    ], [
        ("精神的に強くなりたいです。", "Seishinteki ni tsuyoku naritai desu.", "Saya ingin menjadi kuat secara mental."),
        ("精一杯頑張ります。", "Seiippai ganbarimasu.", "Saya akan berusaha sekuat tenaga."),
    ]),
    ("san3_n3", "散", ["サン"], ["ち-る"], ["berserakan", "menyebar", "scatter", "disperse"], 12, "攵", [
        ("散歩", "sanpo", "jalan-jalan"),
        ("散る", "chiru", "berguguran/tersebar"),
        ("解散", "kaisan", "pembubaran"),
    ], [
        ("毎朝、公園を散歩します。", "Maiasa, kouen o sanpo shimasu.", "Setiap pagi saya jalan-jalan di taman."),
        ("桜の花が散っています。", "Sakura no hana ga chitte imasu.", "Bunga sakura berguguran."),
    ]),
    ("sei6_n3", "静", ["セイ", "ジョウ"], ["しず-か"], ["tenang", "sunyi", "quiet", "calm"], 14, "青", [
        ("静かな", "shizuka na", "tenang"),
        ("静止", "seishi", "diam/statis"),
        ("冷静", "reisei", "tenang/tidak panik"),
    ], [
        ("図書館は静かです。", "Toshokan wa shizuka desu.", "Perpustakaan tenang."),
        ("冷静に考えてください。", "Reisei ni kangaete kudasai.", "Tolong berpikir dengan tenang."),
    ]),
    ("kon_n3", "婚", ["コン"], [], ["pernikahan", "marriage"], 11, "女", [
        ("結婚", "kekkon", "pernikahan"),
        ("婚約", "kon'yaku", "pertunangan"),
        ("離婚", "rikon", "perceraian"),
    ], [
        ("来年、結婚します。", "Rainen, kekkon shimasu.", "Tahun depan saya akan menikah."),
        ("二人は婚約しました。", "Futari wa kon'yaku shimashita.", "Mereka berdua bertunangan."),
    ]),
    ("ki7_n3", "喜", ["キ"], ["よろこ-ぶ"], ["bergembira", "senang", "rejoice", "delight"], 12, "口", [
        ("喜ぶ", "yorokobu", "bergembira"),
        ("喜び", "yorokobi", "kegembiraan"),
        ("大喜び", "ooyorokobi", "sangat senang"),
    ], [
        ("合格を聞いて喜びました。", "Goukaku o kiite yorokobimashita.", "Saya senang mendengar kelulusannya."),
        ("彼女は大喜びでした。", "Kanojo wa ooyorokobi deshita.", "Dia sangat senang."),
    ]),
    ("fu6_n3", "浮", ["フ"], ["う-く", "う-かぶ"], ["mengapung", "melayang", "float", "rise"], 10, "氵", [
        ("浮く", "uku", "mengapung"),
        ("浮かぶ", "ukabu", "muncul/mengapung"),
        ("浮気", "uwaki", "selingkuh"),
    ], [
        ("木の葉が水に浮いています。", "Ki no ha ga mizu ni uite imasu.", "Daun mengapung di air."),
        ("いいアイデアが浮かびました。", "Ii aidea ga ukabimashita.", "Ide bagus muncul di pikiran saya."),
    ]),
    ("zetsu_n3", "絶", ["ゼツ"], ["た-える"], ["putus", "mutlak", "sever", "absolute"], 12, "糸", [
        ("絶対", "zettai", "mutlak/pasti"),
        ("絶好", "zekkou", "sangat baik/ideal"),
        ("絶える", "taeru", "terputus/berakhir"),
    ], [
        ("これは絶対に必要です。", "Kore wa zettai ni hitsuyou desu.", "Ini pasti diperlukan."),
        ("今日は絶好の天気です。", "Kyou wa zekkou no tenki desu.", "Hari ini cuacanya sangat baik."),
    ]),
    ("kou6_n3", "幸", ["コウ"], ["しあわ-せ", "さいわ-い"], ["bahagia", "beruntung", "happy", "fortunate"], 8, "干", [
        ("幸せ", "shiawase", "bahagia"),
        ("幸福", "koufuku", "kebahagiaan"),
        ("不幸", "fukou", "malang/sial"),
    ], [
        ("今、とても幸せです。", "Ima, totemo shiawase desu.", "Sekarang saya sangat bahagia."),
        ("それは不幸な出来事でした。", "Sore wa fukou na dekigoto deshita.", "Itu adalah kejadian yang malang."),
    ]),
    ("ou3_n3", "押", ["オウ"], ["お-す"], ["mendorong", "menekan", "push", "press"], 8, "扌", [
        ("押す", "osu", "mendorong/menekan"),
        ("押入れ", "oshiire", "lemari built-in"),
        ("押収", "oshuu", "penyitaan"),
    ], [
        ("このボタンを押してください。", "Kono botan o oshite kudasai.", "Tolong tekan tombol ini."),
        ("布団を押入れにしまいました。", "Futon o oshiire ni shimaimashita.", "Saya menyimpan futon di lemari built-in."),
    ]),
    ("tou4_n3", "倒", ["トウ"], ["たお-れる", "たお-す"], ["jatuh", "runtuh", "fall", "collapse"], 10, "亻", [
        ("倒れる", "taoreru", "jatuh/roboh"),
        ("倒す", "taosu", "menjatuhkan/mengalahkan"),
        ("面倒", "mendou", "merepotkan"),
    ], [
        ("木が倒れました。", "Ki ga taoremashita.", "Pohonnya tumbang."),
        ("この作業は面倒です。", "Kono sagyou wa mendou desu.", "Pekerjaan ini merepotkan."),
    ]),
    ("tou5_n3", "等", ["トウ"], ["ひと-しい", "など"], ["dan lain-lain", "setara", "etc.", "equal"], 12, "竹", [
        ("等しい", "hitoshii", "setara/sama"),
        ("平等", "byoudou", "kesetaraan"),
        ("一等", "ittou", "kelas satu/juara pertama"),
    ], [
        ("みんな平等です。", "Minna byoudou desu.", "Semua orang setara."),
        ("コンテストで一等を取りました。", "Kontesuto de ittou o torimashita.", "Saya mendapat juara pertama di kontes."),
    ]),
    ("rou2_n3", "老", ["ロウ"], ["お-いる"], ["tua", "lanjut usia", "old", "aged"], 6, "老", [
        ("老人", "roujin", "orang tua/lansia"),
        ("老後", "rougo", "masa tua"),
        ("老化", "rouka", "penuaan"),
    ], [
        ("老人ホームで働いています。", "Roujin hoomu de hataraite imasu.", "Saya bekerja di panti jompo."),
        ("老後の生活を考えます。", "Rougo no seikatsu o kangaemasu.", "Saya memikirkan kehidupan di masa tua."),
    ]),
    ("kyoku2_n3", "曲", ["キョク"], ["ま-がる"], ["lagu", "membengkokkan", "song", "bend"], 6, "曰", [
        ("曲", "kyoku", "lagu"),
        ("曲がる", "magaru", "berbelok"),
        ("作曲", "sakkyoku", "menggubah lagu"),
    ], [
        ("この曲が好きです。", "Kono kyoku ga suki desu.", "Saya suka lagu ini."),
        ("次の角を右に曲がってください。", "Tsugi no kado o migi ni magatte kudasai.", "Tolong belok kanan di tikungan berikutnya."),
    ]),
    # --- Batch L: 払庭徒勤居雑招欠更刻賛抱犯恐息願絵越欲痛笑互 (22) ---
    ("futsu_n3", "払", ["フツ"], ["はら-う"], ["membayar", "menyapu", "pay", "clear"], 5, "扌", [
        ("払う", "harau", "membayar"),
        ("支払い", "shiharai", "pembayaran"),
        ("現金払い", "genkin barai", "pembayaran tunai"),
    ], [
        ("レジでお金を払いました。", "Reji de okane o haraimashita.", "Saya membayar uang di kasir."),
        ("支払いはカードでお願いします。", "Shiharai wa kaado de onegaishimasu.", "Tolong pembayaran dengan kartu."),
    ]),
    ("tei3_n3", "庭", ["テイ"], ["にわ"], ["taman", "halaman", "garden", "yard"], 10, "广", [
        ("庭", "niwa", "taman/halaman"),
        ("家庭", "katei", "rumah tangga/keluarga"),
        ("校庭", "koutei", "halaman sekolah"),
    ], [
        ("庭に花を植えました。", "Niwa ni hana o uemashita.", "Saya menanam bunga di halaman."),
        ("家庭で日本語を練習します。", "Katei de nihongo o renshuu shimasu.", "Saya berlatih bahasa Jepang di rumah."),
    ]),
    ("to4_n3", "徒", ["ト"], [], ["murid", "sia-sia", "pupil", "futile"], 10, "彳", [
        ("生徒", "seito", "murid"),
        ("徒歩", "toho", "jalan kaki"),
        ("徒然", "tsurezure", "iseng/bosan"),
    ], [
        ("この学校には生徒が多いです。", "Kono gakkou ni wa seito ga ooi desu.", "Sekolah ini banyak muridnya."),
        ("駅まで徒歩で行きます。", "Eki made toho de ikimasu.", "Saya pergi ke stasiun dengan jalan kaki."),
    ]),
    ("kin_n3", "勤", ["キン", "ゴン"], ["つと-める"], ["bekerja", "rajin", "work", "diligent"], 12, "力", [
        ("勤める", "tsutomeru", "bekerja di"),
        ("通勤", "tsuukin", "commuting/pergi kerja"),
        ("勤務", "kinmu", "dinas/tugas kerja"),
    ], [
        ("銀行に勤めています。", "Ginkou ni tsutomete imasu.", "Saya bekerja di bank."),
        ("毎日電車で通勤します。", "Mainichi densha de tsuukin shimasu.", "Setiap hari saya pergi kerja naik kereta."),
    ]),
    ("kyo2_n3", "居", ["キョ"], ["い-る"], ["tinggal", "berada", "reside", "be"], 8, "尸", [
        ("居る", "iru", "berada/tinggal"),
        ("住居", "juukyo", "tempat tinggal"),
        ("居間", "ima", "ruang keluarga"),
    ], [
        ("家族と居間でテレビを見ます。", "Kazoku to ima de terebi o mimasu.", "Saya menonton TV di ruang keluarga bersama keluarga."),
        ("新しい住居を探しています。", "Atarashii juukyo o sagashite imasu.", "Saya sedang mencari tempat tinggal baru."),
    ]),
    ("zatsu_n3", "雑", ["ザツ", "ゾウ"], [], ["campur aduk", "beragam", "miscellaneous", "mixed"], 14, "隹", [
        ("雑誌", "zasshi", "majalah"),
        ("複雑", "fukuzatsu", "rumit"),
        ("雑談", "zatsudan", "obrolan santai"),
    ], [
        ("雑誌を読んでいます。", "Zasshi o yonde imasu.", "Saya sedang membaca majalah."),
        ("この問題は複雑です。", "Kono mondai wa fukuzatsu desu.", "Masalah ini rumit."),
    ]),
    ("shou4_n3", "招", ["ショウ"], ["まね-く"], ["mengundang", "invite", "beckon"], 8, "扌", [
        ("招待", "shoutai", "undangan"),
        ("招く", "maneku", "mengundang"),
        ("招待状", "shoutaijou", "kartu undangan"),
    ], [
        ("パーティーに招待されました。", "Paatii ni shoutai saremashita.", "Saya diundang ke pesta."),
        ("誤解を招くかもしれません。", "Gokai o maneku kamoshiremasen.", "Ini mungkin mengundang kesalahpahaman."),
    ]),
    ("ketsu_n3", "欠", ["ケツ"], ["か-ける"], ["kurang", "tidak hadir", "lack", "absent"], 4, "欠", [
        ("欠席", "kesseki", "tidak hadir"),
        ("欠点", "ketten", "kekurangan"),
        ("欠ける", "kakeru", "kurang/pecah"),
    ], [
        ("昨日、学校を欠席しました。", "Kinou, gakkou o kesseki shimashita.", "Kemarin saya tidak masuk sekolah."),
        ("誰にでも欠点があります。", "Dare ni demo ketten ga arimasu.", "Setiap orang punya kekurangan."),
    ]),
    ("kou7_n3", "更", ["コウ"], ["さら", "さら-に", "ふ-ける"], ["lebih lagi", "mengubah", "further", "renew"], 7, "曰", [
        ("変更", "henkou", "perubahan"),
        ("更に", "sarani", "lebih lanjut/lagi"),
        ("更新", "koushin", "pembaruan"),
    ], [
        ("予定を変更しました。", "Yotei o henkou shimashita.", "Saya mengubah jadwal."),
        ("パスポートを更新しました。", "Pasupooto o koushin shimashita.", "Saya memperbarui paspor."),
    ]),
    ("koku2_n3", "刻", ["コク"], ["きざ-む"], ["mengukir", "waktu", "engrave", "time"], 8, "刂", [
        ("時刻", "jikoku", "waktu/jam"),
        ("深刻", "shinkoku", "serius"),
        ("刻む", "kizamu", "mengukir/mencincang"),
    ], [
        ("電車の時刻を調べます。", "Densha no jikoku o shirabemasu.", "Saya memeriksa waktu kereta."),
        ("これは深刻な問題です。", "Kore wa shinkoku na mondai desu.", "Ini adalah masalah yang serius."),
    ]),
    ("san4_n3", "賛", ["サン"], [], ["setuju", "memuji", "approve", "praise"], 15, "貝", [
        ("賛成", "sansei", "setuju"),
        ("賞賛", "shousan", "pujian"),
        ("協賛", "kyousan", "sponsor/dukungan"),
    ], [
        ("その意見に賛成です。", "Sono iken ni sansei desu.", "Saya setuju dengan pendapat itu."),
        ("彼の努力は賞賛に値します。", "Kare no doryoku wa shousan ni atai shimasu.", "Usahanya layak dipuji."),
    ]),
    ("hou5_n3", "抱", ["ホウ"], ["だ-く", "いだ-く"], ["memeluk", "embrace", "hug"], 8, "扌", [
        ("抱く", "daku", "memeluk"),
        ("抱える", "kakaeru", "memegang/menanggung"),
        ("辛抱", "shinbou", "kesabaran"),
    ], [
        ("赤ちゃんを抱きました。", "Akachan o dakimashita.", "Saya memeluk bayi."),
        ("悩みを抱えています。", "Nayami o kakaete imasu.", "Saya sedang memiliki masalah/kekhawatiran."),
    ]),
    ("han3_n3", "犯", ["ハン"], ["おか-す"], ["kejahatan", "melanggar", "crime", "commit"], 5, "犭", [
        ("犯人", "hannin", "pelaku"),
        ("犯罪", "hanzai", "kejahatan"),
        ("犯す", "okasu", "melakukan (kesalahan/kejahatan)"),
    ], [
        ("犯人が捕まりました。", "Hannin ga tsukamarimashita.", "Pelakunya tertangkap."),
        ("大きい間違いを犯しました。", "Ookii machigai o okashimashita.", "Saya melakukan kesalahan besar."),
    ]),
    ("kyou3_n3", "恐", ["キョウ"], ["おそ-れる", "こわ-い"], ["takut", "khawatir", "fear", "dread"], 10, "心", [
        ("恐い", "kowai", "menakutkan"),
        ("恐ろしい", "osoroshii", "mengerikan"),
        ("恐竜", "kyouryuu", "dinosaurus"),
    ], [
        ("このお化け屋敷は恐いです。", "Kono obakeyashiki wa kowai desu.", "Rumah hantu ini menakutkan."),
        ("恐竜の骨を見ました。", "Kyouryuu no hone o mimashita.", "Saya melihat tulang dinosaurus."),
    ]),
    ("soku3_n3", "息", ["ソク"], ["いき"], ["napas", "anak laki-laki", "breath", "son"], 10, "心", [
        ("息", "iki", "napas"),
        ("息子", "musuko", "anak laki-laki"),
        ("休息", "kyuusoku", "istirahat"),
    ], [
        ("深く息を吸ってください。", "Fukaku iki o sutte kudasai.", "Tolong tarik napas dalam-dalam."),
        ("少し休息が必要です。", "Sukoshi kyuusoku ga hitsuyou desu.", "Saya butuh sedikit istirahat."),
    ]),
    ("gan_n3", "願", ["ガン"], ["ねが-う"], ["berharap", "memohon", "wish", "request"], 19, "頁", [
        ("願う", "negau", "berharap/memohon"),
        ("お願い", "onegai", "permintaan/tolong"),
        ("願書", "gansho", "formulir permohonan"),
    ], [
        ("幸せを願っています。", "Shiawase o negatte imasu.", "Saya berharap kebahagiaan."),
        ("お願いがあります。", "Onegai ga arimasu.", "Saya punya permintaan."),
    ]),
    ("kai3_n3", "絵", ["カイ", "エ"], [], ["gambar", "lukisan", "picture", "painting"], 12, "糸", [
        ("絵", "e", "gambar/lukisan"),
        ("絵本", "ehon", "buku bergambar"),
        ("絵画", "kaiga", "lukisan"),
    ], [
        ("娘に絵本を読みました。", "Musume ni ehon o yomimashita.", "Saya membacakan buku bergambar untuk anak perempuan saya."),
        ("美術館で絵画を見ました。", "Bijutsukan de kaiga o mimashita.", "Saya melihat lukisan di museum seni."),
    ]),
    ("etsu_n3", "越", ["エツ"], ["こ-える", "こ-す"], ["melewati", "melebihi", "cross over", "exceed"], 12, "走", [
        ("越える", "koeru", "melewati"),
        ("引っ越し", "hikkoshi", "pindah rumah"),
        ("追い越す", "oikosu", "menyalip"),
    ], [
        ("山を越えて村に着きました。", "Yama o koete mura ni tsukimashita.", "Saya melewati gunung dan tiba di desa."),
        ("来月、引っ越しします。", "Raigetsu, hikkoshi shimasu.", "Bulan depan saya akan pindah rumah."),
    ]),
    ("yoku_n3", "欲", ["ヨク"], ["ほ-しい"], ["hasrat", "keinginan", "desire", "greed"], 11, "欠", [
        ("欲しい", "hoshii", "ingin/menginginkan"),
        ("意欲", "iyoku", "motivasi/semangat"),
        ("食欲", "shokuyoku", "nafsu makan"),
    ], [
        ("新しいパソコンが欲しいです。", "Atarashii pasokon ga hoshii desu.", "Saya ingin komputer baru."),
        ("最近、食欲がありません。", "Saikin, shokuyoku ga arimasen.", "Belakangan ini saya tidak nafsu makan."),
    ]),
    ("tsuu_n3", "痛", ["ツウ"], ["いた-い"], ["sakit", "nyeri", "pain", "hurt"], 12, "疒", [
        ("痛い", "itai", "sakit"),
        ("頭痛", "zutsuu", "sakit kepala"),
        ("苦痛", "kutsuu", "penderitaan"),
    ], [
        ("お腹が痛いです。", "Onaka ga itai desu.", "Perut saya sakit."),
        ("頭痛がひどいです。", "Zutsuu ga hidoi desu.", "Sakit kepala saya parah."),
    ]),
    ("shou5_n3", "笑", ["ショウ"], ["わら-う", "え-む"], ["tertawa", "tersenyum", "laugh", "smile"], 10, "竹", [
        ("笑う", "warau", "tertawa"),
        ("微笑む", "hohoemu", "tersenyum"),
        ("笑顔", "egao", "wajah tersenyum"),
    ], [
        ("彼はいつも笑っています。", "Kare wa itsumo waratte imasu.", "Dia selalu tertawa."),
        ("彼女の笑顔が好きです。", "Kanojo no egao ga suki desu.", "Saya suka senyumnya."),
    ]),
    ("go_n3", "互", ["ゴ"], ["たが-い"], ["saling", "timbal balik", "mutually", "each other"], 4, "二", [
        ("お互い", "otagai", "satu sama lain"),
        ("互いに", "tagai ni", "saling"),
        ("相互", "sougo", "timbal balik"),
    ], [
        ("お互いに助け合いましょう。", "Otagai ni tasukeaimashou.", "Ayo saling membantu."),
        ("相互理解が大切です。", "Sougo rikai ga taisetsu desu.", "Saling memahami itu penting."),
    ]),
    # --- Batch M: 束似列探逃迷夢君緒折草暮酒晴掛到盗吸陽御歯吹 (22) ---
    ("soku4_n3", "束", ["ソク"], ["たば"], ["ikatan", "bundel", "bundle", "sheaf"], 7, "木", [
        ("約束", "yakusoku", "janji"),
        ("束", "taba", "ikatan"),
        ("花束", "hanataba", "buket bunga"),
    ], [
        ("友達と約束しました。", "Tomodachi to yakusoku shimashita.", "Saya membuat janji dengan teman."),
        ("花束をもらいました。", "Hanataba o moraimashita.", "Saya menerima buket bunga."),
    ]),
    ("ji5_n3", "似", ["ジ"], ["に-る"], ["mirip", "menyerupai", "resemble", "similar"], 7, "亻", [
        ("似ている", "niteiru", "mirip"),
        ("類似", "ruiji", "kesamaan"),
        ("真似", "mane", "meniru"),
    ], [
        ("彼は父親に似ています。", "Kare wa chichioya ni nite imasu.", "Dia mirip dengan ayahnya."),
        ("友達の真似をしました。", "Tomodachi no mane o shimashita.", "Saya meniru teman saya."),
    ]),
    ("retsu_n3", "列", ["レツ"], [], ["baris", "deret", "row", "line"], 6, "刂", [
        ("列", "retsu", "baris/antrean"),
        ("行列", "gyouretsu", "antrean panjang"),
        ("列車", "ressha", "kereta api"),
    ], [
        ("列に並んでください。", "Retsu ni narande kudasai.", "Tolong berbaris di antrean."),
        ("人気店の前に行列ができています。", "Ninkiten no mae ni gyouretsu ga dekite imasu.", "Ada antrean panjang di depan toko populer."),
    ]),
    ("tan2_n3", "探", ["タン"], ["さが-す", "さぐ-る"], ["mencari", "search", "look for"], 11, "扌", [
        ("探す", "sagasu", "mencari"),
        ("探検", "tanken", "eksplorasi"),
        ("探偵", "tantei", "detektif"),
    ], [
        ("鍵を探しています。", "Kagi o sagashite imasu.", "Saya sedang mencari kunci."),
        ("探偵の映画が好きです。", "Tantei no eiga ga suki desu.", "Saya suka film detektif."),
    ]),
    ("tou6_n3", "逃", ["トウ"], ["に-げる", "のが-す"], ["melarikan diri", "menghindar", "escape", "flee"], 9, "辶", [
        ("逃げる", "nigeru", "melarikan diri"),
        ("逃避", "touhi", "penghindaran"),
        ("見逃す", "minogasu", "melewatkan"),
    ], [
        ("犬が逃げました。", "Inu ga nigemashita.", "Anjingnya kabur."),
        ("大事なニュースを見逃しました。", "Daiji na nyuusu o minogashimashita.", "Saya melewatkan berita penting."),
    ]),
    ("mei2_n3", "迷", ["メイ"], ["まよ-う"], ["bingung", "tersesat", "confused", "lost"], 9, "辶", [
        ("迷う", "mayou", "bingung/tersesat"),
        ("迷子", "maigo", "anak hilang"),
        ("迷惑", "meiwaku", "gangguan/kerepotan"),
    ], [
        ("どちらを選ぶか迷っています。", "Dochira o erabu ka mayotte imasu.", "Saya bingung mana yang harus dipilih."),
        ("ご迷惑をおかけしました。", "Gomeiwaku o okake shimashita.", "Maaf telah merepotkan Anda."),
    ]),
    ("mu2_n3", "夢", ["ム"], ["ゆめ"], ["mimpi", "cita-cita", "dream", "vision"], 13, "夕", [
        ("夢", "yume", "mimpi"),
        ("夢見る", "yumemiru", "bermimpi"),
        ("悪夢", "akumu", "mimpi buruk"),
    ], [
        ("昨夜、変な夢を見ました。", "Sakuya, hen na yume o mimashita.", "Tadi malam saya bermimpi aneh."),
        ("私の夢は医者になることです。", "Watashi no yume wa isha ni naru koto desu.", "Cita-cita saya adalah menjadi dokter."),
    ]),
    ("kun_n3", "君", ["クン"], ["きみ"], ["kamu (akrab)", "you (familiar)"], 7, "口", [
        ("君", "kimi", "kamu, akrab"),
        ("君主", "kunshu", "raja/penguasa"),
        ("諸君", "shokun", "semua/hadirin"),
    ], [
        ("君の名前は何ですか。", "Kimi no namae wa nan desu ka.", "Siapa namamu?"),
        ("田中君、こっちに来て。", "Tanaka-kun, kocchi ni kite.", "Tanaka, kemarilah."),
    ]),
    ("sho3_n3", "緒", ["ショ", "チョ"], ["お"], ["awal", "tali", "beginning", "cord"], 14, "糸", [
        ("一緒に", "issho ni", "bersama-sama"),
        ("緒", "o", "tali"),
        ("情緒", "jousho", "suasana/emosi"),
    ], [
        ("一緒に映画を見ましょう。", "Issho ni eiga o mimashou.", "Ayo menonton film bersama."),
        ("この町は情緒があります。", "Kono machi wa jousho ga arimasu.", "Kota ini memiliki suasana yang khas."),
    ]),
    ("setsu2_n3", "折", ["セツ"], ["お-る", "お-れる"], ["melipat", "mematahkan", "fold", "break"], 7, "扌", [
        ("折る", "oru", "melipat/mematahkan"),
        ("骨折", "kossetsu", "patah tulang"),
        ("折り紙", "origami", "origami"),
    ], [
        ("紙を半分に折りました。", "Kami o hanbun ni orimashita.", "Saya melipat kertas menjadi dua."),
        ("足を骨折しました。", "Ashi o kossetsu shimashita.", "Kaki saya patah tulang."),
    ]),
    ("sou4_n3", "草", ["ソウ"], ["くさ"], ["rumput", "grass"], 9, "艹", [
        ("草", "kusa", "rumput"),
        ("草原", "sougen", "padang rumput"),
        ("雑草", "zassou", "gulma"),
    ], [
        ("庭の草を刈りました。", "Niwa no kusa o karimashita.", "Saya memotong rumput di halaman."),
        ("雑草がたくさん生えています。", "Zassou ga takusan haete imasu.", "Banyak gulma yang tumbuh."),
    ]),
    ("bo_n3", "暮", ["ボ"], ["く-れる", "く-らす"], ["mencari nafkah", "menjalani hidup", "livelihood", "live"], 14, "日", [
        ("暮らす", "kurasu", "menjalani hidup"),
        ("暮れる", "kureru", "senja/berakhir"),
        ("夕暮れ", "yuugure", "senja"),
    ], [
        ("家族と幸せに暮らしています。", "Kazoku to shiawase ni kurashite imasu.", "Saya hidup bahagia bersama keluarga."),
        ("夕暮れの空がきれいです。", "Yuugure no sora ga kirei desu.", "Langit senja indah."),
    ]),
    ("shu5_n3", "酒", ["シュ"], ["さけ"], ["arak", "minuman keras", "sake", "alcohol"], 10, "氵", [
        ("お酒", "osake", "minuman keras"),
        ("酒屋", "sakaya", "toko minuman keras"),
        ("日本酒", "nihonshu", "sake Jepang"),
    ], [
        ("お酒は飲みません。", "Osake wa nomimasen.", "Saya tidak minum minuman keras."),
        ("日本酒を試してみました。", "Nihonshu o tameshite mimashita.", "Saya mencoba sake Jepang."),
    ]),
    ("sei7_n3", "晴", ["セイ"], ["は-れる"], ["cerah", "clear (weather)"], 12, "日", [
        ("晴れ", "hare", "cerah"),
        ("晴れる", "hareru", "menjadi cerah"),
        ("快晴", "kaisei", "cerah sekali"),
    ], [
        ("明日は晴れるでしょう。", "Ashita wa hareru deshou.", "Besok mungkin akan cerah."),
        ("今日は快晴です。", "Kyou wa kaisei desu.", "Hari ini cuacanya sangat cerah."),
    ]),
    ("kai4_n3", "掛", ["カイ"], ["か-ける", "か-かる"], ["menggantung", "menelepon", "hang", "call"], 11, "扌", [
        ("掛ける", "kakeru", "menggantung/mengenakan"),
        ("電話を掛ける", "denwa o kakeru", "menelepon"),
        ("心掛け", "kokorogake", "sikap/perhatian"),
    ], [
        ("壁に絵を掛けました。", "Kabe ni e o kakemashita.", "Saya menggantung lukisan di dinding."),
        ("友達に電話を掛けました。", "Tomodachi ni denwa o kakemashita.", "Saya menelepon teman."),
    ]),
    ("tou7_n3", "到", ["トウ"], ["いた-る"], ["tiba", "mencapai", "arrive", "reach"], 8, "刂", [
        ("到着", "touchaku", "kedatangan"),
        ("到達", "toutatsu", "mencapai"),
        ("殺到", "sattou", "berbondong-bondong"),
    ], [
        ("飛行機が到着しました。", "Hikouki ga touchaku shimashita.", "Pesawatnya sudah tiba."),
        ("頂上に到達しました。", "Choujou ni toutatsu shimashita.", "Kami mencapai puncak."),
    ]),
    ("tou8_n3", "盗", ["トウ"], ["ぬす-む"], ["mencuri", "steal"], 11, "皿", [
        ("盗む", "nusumu", "mencuri"),
        ("盗難", "tounan", "pencurian"),
        ("強盗", "goutou", "perampokan"),
    ], [
        ("財布を盗まれました。", "Saifu o nusumaremashita.", "Dompet saya dicuri."),
        ("この地域は盗難が多いです。", "Kono chiiki wa tounan ga ooi desu.", "Daerah ini banyak pencurian."),
    ]),
    ("kyuu4_n3", "吸", ["キュウ"], ["す-う"], ["menghisap", "menghirup", "suck", "inhale"], 6, "口", [
        ("吸う", "suu", "menghirup/menghisap"),
        ("呼吸", "kokyuu", "pernapasan"),
        ("吸収", "kyuushuu", "penyerapan"),
    ], [
        ("新鮮な空気を吸いました。", "Shinsen na kuuki o suimashita.", "Saya menghirup udara segar."),
        ("植物は水を吸収します。", "Shokubutsu wa mizu o kyuushuu shimasu.", "Tumbuhan menyerap air."),
    ]),
    ("you4_n3", "陽", ["ヨウ"], [], ["matahari", "positif", "sun", "positive"], 12, "阝", [
        ("太陽", "taiyou", "matahari"),
        ("陽気", "youki", "ceria/cerah"),
        ("陽性", "yousei", "positif (hasil tes)"),
    ], [
        ("太陽が眩しいです。", "Taiyou ga mabushii desu.", "Mataharinya silau."),
        ("彼はいつも陽気です。", "Kare wa itsumo youki desu.", "Dia selalu ceria."),
    ]),
    ("go2_n3", "御", ["ギョ", "ゴ"], ["おん-", "お-"], ["hormat (awalan)", "honorable prefix"], 12, "彳", [
        ("御飯", "gohan", "nasi"),
        ("御礼", "orei", "ucapan terima kasih"),
        ("制御", "seigyo", "kontrol"),
    ], [
        ("御飯を食べましょう。", "Gohan o tabemashou.", "Ayo makan nasi."),
        ("機械を制御します。", "Kikai o seigyo shimasu.", "Saya mengontrol mesin."),
    ]),
    ("shi6_n3", "歯", ["シ"], ["は"], ["gigi", "tooth"], 12, "歯", [
        ("歯", "ha", "gigi"),
        ("歯医者", "haisha", "dokter gigi"),
        ("歯磨き", "hamigaki", "menyikat gigi"),
    ], [
        ("歯が痛いです。", "Ha ga itai desu.", "Gigi saya sakit."),
        ("毎日歯磨きをします。", "Mainichi hamigaki o shimasu.", "Setiap hari saya menyikat gigi."),
    ]),
    ("sui_n3", "吹", ["スイ"], ["ふ-く"], ["meniup", "berhembus", "blow"], 7, "口", [
        ("風が吹く", "kaze ga fuku", "angin bertiup"),
        ("吹雪", "fubuki", "badai salju"),
        ("吹く", "fuku", "meniup"),
    ], [
        ("強い風が吹いています。", "Tsuyoi kaze ga fuite imasu.", "Angin kencang sedang bertiup."),
        ("冬に吹雪が来ます。", "Fuyu ni fubuki ga kimasu.", "Badai salju datang di musim dingin."),
    ]),
    # --- Batch N: 娘誤慣礼窓貧怒祖杯疲皆鳴腹煙眠怖耳頂箱晩寒髪 (22) ---
    ("jou4_n3", "娘", ["ジョウ"], ["むすめ"], ["anak perempuan", "gadis", "daughter", "girl"], 10, "女", [
        ("娘", "musume", "anak perempuan"),
        ("娘さん", "musumesan", "anak perempuan orang lain"),
        ("一人娘", "hitorimusume", "anak perempuan tunggal"),
    ], [
        ("私の娘は五歳です。", "Watashi no musume wa gosai desu.", "Anak perempuan saya berusia lima tahun."),
        ("お宅の娘さんはおいくつですか。", "Otaku no musumesan wa oikutsu desu ka.", "Berapa usia anak perempuan Anda?"),
    ]),
    ("go3_n3", "誤", ["ゴ"], ["あやま-る"], ["kesalahan", "salah", "mistake", "error"], 14, "言", [
        ("誤解", "gokai", "kesalahpahaman"),
        ("誤り", "ayamari", "kesalahan"),
        ("誤る", "ayamaru", "salah/keliru"),
    ], [
        ("誤解しないでください。", "Gokai shinaide kudasai.", "Jangan salah paham."),
        ("私の誤りを直しました。", "Watashi no ayamari o naoshimashita.", "Saya memperbaiki kesalahan saya."),
    ]),
    ("kan5_n3", "慣", ["カン"], ["な-れる", "な-らす"], ["terbiasa", "kebiasaan", "accustomed", "used to"], 14, "忄", [
        ("慣れる", "nareru", "terbiasa"),
        ("習慣", "shuukan", "kebiasaan"),
        ("慣習", "kanshuu", "adat/tradisi"),
    ], [
        ("新しい仕事に慣れました。", "Atarashii shigoto ni naremashita.", "Saya sudah terbiasa dengan pekerjaan baru."),
        ("早起きの習慣があります。", "Hayaoki no shuukan ga arimasu.", "Saya punya kebiasaan bangun pagi."),
    ]),
    ("rei2_n3", "礼", ["レイ", "ライ"], [], ["hormat", "terima kasih", "bow", "thanks"], 5, "礻", [
        ("お礼", "orei", "ucapan terima kasih"),
        ("礼儀", "reigi", "sopan santun"),
        ("失礼", "shitsurei", "permisi/maaf"),
    ], [
        ("お礼を言いたいです。", "Orei o iitai desu.", "Saya ingin mengucapkan terima kasih."),
        ("礼儀正しい人です。", "Reigi tadashii hito desu.", "Dia orang yang sopan."),
    ]),
    ("sou5_n3", "窓", ["ソウ"], ["まど"], ["jendela", "window"], 11, "穴", [
        ("窓", "mado", "jendela"),
        ("窓口", "madoguchi", "loket"),
        ("同窓会", "dousoukai", "reuni alumni"),
    ], [
        ("窓を開けてください。", "Mado o akete kudasai.", "Tolong buka jendelanya."),
        ("銀行の窓口で手続きをしました。", "Ginkou no madoguchi de tetsuzuki o shimashita.", "Saya mengurus proses di loket bank."),
    ]),
    ("hin_n3", "貧", ["ヒン", "ビン"], ["まず-しい"], ["miskin", "kemiskinan", "poor", "poverty"], 11, "貝", [
        ("貧しい", "mazushii", "miskin"),
        ("貧困", "hinkon", "kemiskinan"),
        ("貧血", "hinketsu", "anemia"),
    ], [
        ("昔は貧しかったです。", "Mukashi wa mazushikatta desu.", "Dahulu saya miskin."),
        ("世界の貧困を減らしたいです。", "Sekai no hinkon o herashitai desu.", "Saya ingin mengurangi kemiskinan dunia."),
    ]),
    ("do2_n3", "怒", ["ド"], ["おこ-る", "いか-る"], ["marah", "angry"], 9, "心", [
        ("怒る", "okoru", "marah"),
        ("怒り", "ikari", "kemarahan"),
        ("怒鳴る", "donaru", "membentak"),
    ], [
        ("母に怒られました。", "Haha ni okoraremashita.", "Saya dimarahi ibu."),
        ("彼は怒鳴りました。", "Kare wa donarimashita.", "Dia membentak."),
    ]),
    ("so2_n3", "祖", ["ソ"], [], ["leluhur", "nenek moyang", "ancestor"], 9, "礻", [
        ("祖父", "sofu", "kakek"),
        ("祖母", "sobo", "nenek"),
        ("先祖", "senzo", "leluhur"),
    ], [
        ("祖父は九十歳です。", "Sofu wa kyuujussai desu.", "Kakek saya berusia 90 tahun."),
        ("先祖のお墓参りをしました。", "Senzo no ohakamairi o shimashita.", "Saya berziarah ke makam leluhur."),
    ]),
    ("hai3_n3", "杯", ["ハイ"], ["さかずき"], ["gelas", "cangkir (penghitung)", "cupful", "glass"], 8, "木", [
        ("一杯", "ippai", "satu gelas/penuh"),
        ("乾杯", "kanpai", "bersulang"),
        ("祝杯", "shukuhai", "gelas untuk merayakan"),
    ], [
        ("コーヒーを一杯ください。", "Koohii o ippai kudasai.", "Tolong satu gelas kopi."),
        ("乾杯しましょう。", "Kanpai shimashou.", "Ayo bersulang."),
    ]),
    ("hi5_n3", "疲", ["ヒ"], ["つか-れる"], ["lelah", "capek", "tired", "exhausted"], 10, "疒", [
        ("疲れる", "tsukareru", "lelah"),
        ("疲労", "hirou", "kelelahan"),
        ("疲れ", "tsukare", "rasa lelah"),
    ], [
        ("今日はとても疲れました。", "Kyou wa totemo tsukaremashita.", "Hari ini saya sangat lelah."),
        ("疲労が溜まっています。", "Hirou ga tamatte imasu.", "Kelelahan sudah menumpuk."),
    ]),
    ("kai5_n3", "皆", ["カイ"], ["みな"], ["semua", "everyone", "all"], 9, "白", [
        ("皆さん", "minasan", "semuanya/hadirin"),
        ("皆", "mina", "semua"),
        ("皆無", "kaimu", "sama sekali tidak ada"),
    ], [
        ("皆さん、こんにちは。", "Minasan, konnichiwa.", "Halo semuanya."),
        ("皆で一緒に頑張りましょう。", "Mina de issho ni ganbarimashou.", "Ayo kita semua berusaha bersama."),
    ]),
    ("mei3_n3", "鳴", ["メイ"], ["な-く", "な-る"], ["berbunyi", "berkicau", "chirp", "sound"], 14, "鳥", [
        ("鳴る", "naru", "berbunyi"),
        ("鳴く", "naku", "berkicau/menggonggong"),
        ("悲鳴", "himei", "jeritan"),
    ], [
        ("電話が鳴っています。", "Denwa ga natte imasu.", "Teleponnya berbunyi."),
        ("鳥が鳴いています。", "Tori ga naite imasu.", "Burung sedang berkicau."),
    ]),
    ("fuku2_n3", "腹", ["フク"], ["はら"], ["perut", "stomach", "belly"], 13, "月", [
        ("お腹", "onaka", "perut"),
        ("腹が立つ", "hara ga tatsu", "marah"),
        ("空腹", "kuufuku", "lapar"),
    ], [
        ("お腹が空きました。", "Onaka ga sukimashita.", "Saya lapar."),
        ("その話を聞いて腹が立ちました。", "Sono hanashi o kiite hara ga tachimashita.", "Saya marah mendengar cerita itu."),
    ]),
    ("en3_n3", "煙", ["エン"], ["けむり", "けむ-る"], ["asap", "smoke"], 13, "火", [
        ("煙", "kemuri", "asap"),
        ("煙草", "tabako", "rokok"),
        ("禁煙", "kin'en", "dilarang merokok"),
    ], [
        ("煙が出ています。", "Kemuri ga dete imasu.", "Ada asap keluar."),
        ("この店は禁煙です。", "Kono mise wa kin'en desu.", "Toko ini dilarang merokok."),
    ]),
    ("min2_n3", "眠", ["ミン"], ["ねむ-る", "ねむ-い"], ["tidur", "mengantuk", "sleep", "sleepy"], 10, "目", [
        ("眠る", "nemuru", "tidur"),
        ("眠い", "nemui", "mengantuk"),
        ("睡眠", "suimin", "tidur/istirahat"),
    ], [
        ("よく眠れませんでした。", "Yoku nemuremasen deshita.", "Saya tidak bisa tidur nyenyak."),
        ("十分な睡眠を取ってください。", "Juubun na suimin o totte kudasai.", "Tolong tidur yang cukup."),
    ]),
    ("fu7_n3", "怖", ["フ"], ["こわ-い"], ["takut", "menakutkan", "scary", "afraid"], 8, "忄", [
        ("怖い", "kowai", "menakutkan/takut"),
        ("怖がる", "kowagaru", "merasa takut"),
        ("恐怖", "kyoufu", "ketakutan"),
    ], [
        ("一人で怖いです。", "Hitori de kowai desu.", "Saya takut sendirian."),
        ("彼女は高い所を怖がります。", "Kanojo wa takai tokoro o kowagarimasu.", "Dia takut tempat tinggi."),
    ]),
    ("ji6_n3", "耳", ["ジ"], ["みみ"], ["telinga", "ear"], 6, "耳", [
        ("耳", "mimi", "telinga"),
        ("耳鼻科", "jibika", "THT/telinga hidung tenggorokan"),
        ("初耳", "hatsumimi", "baru pertama kali dengar"),
    ], [
        ("耳が痛いです。", "Mimi ga itai desu.", "Telinga saya sakit."),
        ("それは初耳です。", "Sore wa hatsumimi desu.", "Itu baru pertama kali saya dengar."),
    ]),
    ("chou2_n3", "頂", ["チョウ"], ["いただ-く"], ["menerima (sopan)", "puncak", "receive (humble)", "top"], 11, "頁", [
        ("頂く", "itadaku", "menerima, bentuk sopan"),
        ("頂上", "choujou", "puncak"),
        ("山頂", "sanchou", "puncak gunung"),
    ], [
        ("プレゼントを頂きました。", "Purezento o itadakimashita.", "Saya menerima hadiah (sopan)."),
        ("山の頂上に着きました。", "Yama no choujou ni tsukimashita.", "Saya tiba di puncak gunung."),
    ]),
    ("sou6_n3", "箱", ["ソウ"], ["はこ"], ["kotak", "peti", "box", "case"], 15, "竹", [
        ("箱", "hako", "kotak"),
        ("本箱", "honbako", "rak buku"),
        ("ゴミ箱", "gomibako", "tempat sampah"),
    ], [
        ("この箱は重いです。", "Kono hako wa omoi desu.", "Kotak ini berat."),
        ("ゴミ箱にゴミを捨ててください。", "Gomibako ni gomi o sutete kudasai.", "Tolong buang sampah di tempat sampah."),
    ]),
    ("ban2_n3", "晩", ["バン"], [], ["malam", "night", "evening"], 12, "日", [
        ("今晩", "konban", "malam ini"),
        ("晩ご飯", "bangohan", "makan malam"),
        ("毎晩", "maiban", "setiap malam"),
    ], [
        ("今晩、何を食べますか。", "Konban, nani o tabemasu ka.", "Malam ini mau makan apa?"),
        ("毎晩、日記を書きます。", "Maiban, nikki o kakimasu.", "Setiap malam saya menulis buku harian."),
    ]),
    ("kan6_n3", "寒", ["カン"], ["さむ-い"], ["dingin", "cold"], 12, "宀", [
        ("寒い", "samui", "dingin"),
        ("寒さ", "samusa", "hawa dingin"),
        ("悪寒", "okan", "menggigil"),
    ], [
        ("今日はとても寒いです。", "Kyou wa totemo samui desu.", "Hari ini sangat dingin."),
        ("冬の寒さが苦手です。", "Fuyu no samusa ga nigate desu.", "Saya tidak tahan dengan dinginnya musim salju."),
    ]),
    ("hatsu_n3", "髪", ["ハツ"], ["かみ"], ["rambut", "hair"], 14, "髟", [
        ("髪", "kami", "rambut"),
        ("髪型", "kamigata", "gaya rambut"),
        ("白髪", "shiraga", "uban"),
    ], [
        ("髪を切りました。", "Kami o kirimashita.", "Saya memotong rambut."),
        ("祖父は白髪です。", "Sofu wa shiraga desu.", "Kakek saya beruban."),
    ]),
    # --- Batch O (final): 才靴恥偶偉猫幾 (7) — completes all 315 locked N3 kanji ---
    ("sai6_n3", "才", ["サイ"], [], ["bakat", "usia (tahun)", "talent", "years old"], 3, "手", [
        ("天才", "tensai", "jenius"),
        ("才能", "sainou", "bakat"),
        ("二十才", "nijussai", "usia 20 tahun"),
    ], [
        ("彼は音楽の天才です。", "Kare wa ongaku no tensai desu.", "Dia jenius musik."),
        ("彼女には絵の才能があります。", "Kanojo ni wa e no sainou ga arimasu.", "Dia memiliki bakat melukis."),
    ]),
    ("ka5_n3", "靴", ["カ"], ["くつ"], ["sepatu", "shoes"], 13, "革", [
        ("靴", "kutsu", "sepatu"),
        ("靴下", "kutsushita", "kaus kaki"),
        ("運動靴", "undougutsu", "sepatu olahraga"),
    ], [
        ("新しい靴を買いました。", "Atarashii kutsu o kaimashita.", "Saya membeli sepatu baru."),
        ("靴下を履いてください。", "Kutsushita o haite kudasai.", "Tolong pakai kaus kaki."),
    ]),
    ("chi3_n3", "恥", ["チ"], ["は-じる", "はじ"], ["malu", "aib", "shame", "embarrassment"], 10, "心", [
        ("恥ずかしい", "hazukashii", "malu"),
        ("恥", "haji", "rasa malu"),
        ("恥じる", "hajiru", "merasa malu"),
    ], [
        ("人前で転んで恥ずかしかったです。", "Hitomae de koronde hazukashikatta desu.", "Saya malu karena jatuh di depan orang."),
        ("彼は自分の失敗を恥じています。", "Kare wa jibun no shippai o hajite imasu.", "Dia merasa malu atas kegagalannya sendiri."),
    ]),
    ("guu_n3", "偶", ["グウ"], [], ["kebetulan", "pasangan", "accidental", "couple"], 11, "亻", [
        ("偶然", "guuzen", "kebetulan"),
        ("偶数", "guusuu", "bilangan genap"),
        ("配偶者", "haiguusha", "pasangan/suami-istri"),
    ], [
        ("駅で偶然、友達に会いました。", "Eki de guuzen, tomodachi ni aimashita.", "Saya kebetulan bertemu teman di stasiun."),
        ("四は偶数です。", "Yon wa guusuu desu.", "Empat adalah bilangan genap."),
    ]),
    ("i3_n3", "偉", ["イ"], ["えら-い"], ["hebat", "mengagumkan", "great", "admirable"], 12, "亻", [
        ("偉い", "erai", "hebat"),
        ("偉大", "idai", "agung/luar biasa"),
        ("偉人", "ijin", "orang hebat/tokoh besar"),
    ], [
        ("あなたは本当に偉いですね。", "Anata wa hontou ni erai desu ne.", "Anda benar-benar hebat, ya."),
        ("彼は歴史上の偉人です。", "Kare wa rekishijou no ijin desu.", "Dia adalah tokoh besar dalam sejarah."),
    ]),
    ("byou_n3", "猫", ["ビョウ"], ["ねこ"], ["kucing", "cat"], 11, "犭", [
        ("猫", "neko", "kucing"),
        ("子猫", "koneko", "anak kucing"),
        ("猫舌", "nekojita", "sensitif terhadap makanan panas"),
    ], [
        ("猫を飼っています。", "Neko o katte imasu.", "Saya memelihara kucing."),
        ("子猫がかわいいです。", "Koneko ga kawaii desu.", "Anak kucingnya lucu."),
    ]),
    ("ki8_n3", "幾", ["キ"], ["いく-つ"], ["berapa", "beberapa", "how many", "several"], 12, "幺", [
        ("幾つ", "ikutsu", "berapa/beberapa"),
        ("幾ら", "ikura", "berapa (harga)"),
        ("幾何学", "kikagaku", "geometri"),
    ], [
        ("りんごは幾つありますか。", "Ringo wa ikutsu arimasu ka.", "Ada berapa apel?"),
        ("これは幾らですか。", "Kore wa ikura desu ka.", "Ini berapa harganya?"),
    ]),
]

# Batch-authored against the locked N2_CHARACTERS list (367 kanji), same
# process as N3_KANJI above: build_n2_entries() mirrors build_n3_entries().
N2_KANJI = [
    ("tou_n2", "党", ["トウ"], [], ["partai", "golongan", "party"], 10, "儿", [
        ("政党", "seitou", "partai politik"),
        ("党員", "touin", "anggota partai"),
        ("野党", "yatou", "partai oposisi"),
    ], [
        ("彼は野党の議員です。", "Kare wa yatou no giin desu.", "Dia adalah anggota parlemen partai oposisi."),
        ("政党に入りました。", "Seitou ni hairimashita.", "Saya bergabung dengan partai politik."),
    ]),
    ("kyou_n2", "協", ["キョウ"], [], ["kerja sama", "bekerja sama", "cooperate"], 8, "十", [
        ("協力", "kyouryoku", "kerja sama"),
        ("協会", "kyoukai", "asosiasi/perkumpulan"),
        ("協定", "kyoutei", "perjanjian"),
    ], [
        ("みんなで協力しましょう。", "Minna de kyouryoku shimashou.", "Mari kita bekerja sama."),
        ("協会に参加しました。", "Kyoukai ni sanka shimashita.", "Saya bergabung dengan asosiasi."),
    ]),
    ("sou_n2", "総", ["ソウ"], [], ["keseluruhan", "umum", "general"], 14, "糸", [
        ("総理", "souri", "perdana menteri"),
        ("総合", "sougou", "keseluruhan/komprehensif"),
        ("総額", "sougaku", "jumlah total"),
    ], [
        ("総理大臣が話しました。", "Souri daijin ga hanashimashita.", "Perdana menteri berbicara."),
        ("総額を確認してください。", "Sougaku o kakunin shite kudasai.", "Tolong periksa jumlah totalnya."),
    ]),
    ("ku_n2", "区", ["ク"], [], ["distrik", "wilayah", "ward"], 4, "匚", [
        ("地区", "chiku", "wilayah/distrik"),
        ("区役所", "kuyakusho", "kantor distrik"),
        ("区別", "kubetsu", "perbedaan/pembedaan"),
    ], [
        ("この地区は静かです。", "Kono chiku wa shizuka desu.", "Distrik ini tenang."),
        ("区役所で手続きをしました。", "Kuyakusho de tetsuzuki o shimashita.", "Saya mengurus dokumen di kantor distrik."),
    ]),
    ("ryou_n2", "領", ["リョウ"], [], ["wilayah", "memimpin", "territory"], 14, "頁", [
        ("大統領", "daitouryou", "presiden"),
        ("領土", "ryoudo", "wilayah/teritori"),
        ("領収書", "ryoushuusho", "kwitansi"),
    ], [
        ("大統領が演説しました。", "Daitouryou ga enzetsu shimashita.", "Presiden berpidato."),
        ("領収書をください。", "Ryoushuusho o kudasai.", "Tolong berikan kwitansi."),
    ]),
    ("ken_n2", "県", ["ケン"], [], ["prefektur", "prefecture"], 9, "目", [
        ("県庁", "kenchou", "kantor prefektur"),
        ("県民", "kenmin", "penduduk prefektur"),
        ("他県", "taken", "prefektur lain"),
    ], [
        ("私は千葉県に住んでいます。", "Watashi wa Chiba-ken ni sunde imasu.", "Saya tinggal di Prefektur Chiba."),
        ("県庁は駅の近くです。", "Kenchou wa eki no chikaku desu.", "Kantor prefektur dekat stasiun."),
    ]),
    ("setsu_n2", "設", ["セツ"], ["もう-ける"], ["mendirikan", "membangun", "establish"], 11, "言", [
        ("設備", "setsubi", "fasilitas"),
        ("設計", "sekkei", "desain/perancangan"),
        ("建設", "kensetsu", "konstruksi/pembangunan"),
    ], [
        ("この建物は設備が新しいです。", "Kono tatemono wa setsubi ga atarashii desu.", "Bangunan ini fasilitasnya baru."),
        ("新しいビルを建設しています。", "Atarashii biru o kensetsu shite imasu.", "Sedang membangun gedung baru."),
    ]),
    ("ho_n2", "保", ["ホ"], ["たも-つ"], ["menjaga", "mempertahankan", "protect"], 9, "人", [
        ("保険", "hoken", "asuransi"),
        ("保存", "hozon", "penyimpanan/pengawetan"),
        ("保育園", "hoikuen", "taman kanak-kanak/penitipan anak"),
    ], [
        ("健康保険に入っています。", "Kenkou hoken ni haitte imasu.", "Saya memiliki asuransi kesehatan."),
        ("食べ物を保存します。", "Tabemono o hozon shimasu.", "Menyimpan makanan."),
    ]),
    ("kai_n2", "改", ["カイ"], ["あらた-める"], ["mereformasi", "memperbaiki", "reform"], 7, "攵", [
        ("改善", "kaizen", "perbaikan/peningkatan"),
        ("改札口", "kaisatsuguchi", "gerbang tiket"),
        ("改正", "kaisei", "revisi/amandemen"),
    ], [
        ("サービスを改善しました。", "Sabisu o kaizen shimashita.", "Kami memperbaiki layanan."),
        ("改札口で待っています。", "Kaisatsuguchi de matte imasu.", "Saya menunggu di gerbang tiket."),
    ]),
    ("dai_n2", "第", ["ダイ"], [], ["ke- (awalan urutan)", "ordinal prefix"], 11, "竹", [
        ("第一", "daiichi", "yang pertama"),
        ("第二", "daini", "yang kedua"),
        ("第三者", "daisansha", "pihak ketiga"),
    ], [
        ("これは第一の目標です。", "Kore wa daiichi no mokuhyou desu.", "Ini adalah tujuan pertama."),
        ("第三者に相談しました。", "Daisansha ni soudan shimashita.", "Saya berkonsultasi dengan pihak ketiga."),
    ]),
    ("ketsu_n2", "結", ["ケツ"], ["むす-ぶ"], ["mengikat", "menyimpulkan", "conclude"], 12, "糸", [
        ("結婚", "kekkon", "pernikahan"),
        ("結果", "kekka", "hasil"),
        ("結論", "ketsuron", "kesimpulan"),
    ], [
        ("来年結婚します。", "Rainen kekkon shimasu.", "Tahun depan saya akan menikah."),
        ("テストの結果を見ました。", "Tesuto no kekka o mimashita.", "Saya melihat hasil tes."),
    ]),
    ("ha_n2", "派", ["ハ"], [], ["golongan", "aliran", "faction"], 9, "水", [
        ("立派", "rippa", "hebat/luar biasa"),
        ("派手", "hade", "mencolok/flamboyan"),
        ("派遣", "haken", "pengiriman (tenaga kerja)"),
    ], [
        ("彼は立派な人です。", "Kare wa rippa na hito desu.", "Dia orang yang hebat."),
        ("その服は派手です。", "Sono fuku wa hade desu.", "Baju itu mencolok."),
    ]),
    ("fu_n2", "府", ["フ"], [], ["pemerintah", "prefektur perkotaan", "government"], 8, "广", [
        ("政府", "seifu", "pemerintah"),
        ("大阪府", "Oosaka-fu", "Prefektur Osaka"),
        ("府庁", "fuchou", "kantor prefektur (Osaka/Kyoto)"),
    ], [
        ("政府が発表しました。", "Seifu ga happyou shimashita.", "Pemerintah mengumumkan."),
        ("大阪府に住んでいます。", "Oosaka-fu ni sunde imasu.", "Saya tinggal di Prefektur Osaka."),
    ]),
    ("sa_n2", "査", ["サ"], [], ["memeriksa", "menyelidiki", "investigate"], 9, "木", [
        ("調査", "chousa", "investigasi/survei"),
        ("検査", "kensa", "pemeriksaan/inspeksi"),
        ("査定", "satei", "penilaian"),
    ], [
        ("会社が調査をしました。", "Kaisha ga chousa o shimashita.", "Perusahaan melakukan survei."),
        ("健康を検査しました。", "Kenkou o kensa shimashita.", "Memeriksa kesehatan."),
    ]),
    ("i_n2", "委", ["イ"], ["ゆだ-ねる"], ["mempercayakan", "menitipkan", "entrust"], 8, "女", [
        ("委員会", "iinkai", "komite"),
        ("委員", "iin", "anggota komite"),
        ("委託", "itaku", "konsinyasi/dipercayakan"),
    ], [
        ("委員会に参加しました。", "Iinkai ni sanka shimashita.", "Saya bergabung dengan komite."),
        ("彼は学級委員です。", "Kare wa gakkyuu iin desu.", "Dia adalah ketua kelas."),
    ]),
    ("gun_n2", "軍", ["グン"], [], ["militer", "tentara", "military"], 9, "車", [
        ("軍隊", "guntai", "angkatan bersenjata"),
        ("陸軍", "rikugun", "angkatan darat"),
        ("海軍", "kaigun", "angkatan laut"),
    ], [
        ("軍隊が訓練しています。", "Guntai ga kunren shite imasu.", "Angkatan bersenjata sedang berlatih."),
        ("彼は海軍にいました。", "Kare wa kaigun ni imashita.", "Dia dulu di angkatan laut."),
    ]),
    ("an_n2", "案", ["アン"], [], ["rencana", "proposal", "gagasan"], 10, "木", [
        ("案内", "annai", "panduan/pemandu"),
        ("提案", "teian", "proposal/usulan"),
        ("案外", "angai", "di luar dugaan"),
    ], [
        ("駅まで案内します。", "Eki made annai shimasu.", "Saya akan memandu Anda ke stasiun."),
        ("新しい案を提案しました。", "Atarashii an o teian shimashita.", "Saya mengusulkan rencana baru."),
    ]),
    ("saku_n2", "策", ["サク"], [], ["kebijakan", "strategi", "policy"], 12, "竹", [
        ("政策", "seisaku", "kebijakan"),
        ("対策", "taisaku", "tindakan pencegahan/langkah"),
        ("解決策", "kaiketsusaku", "solusi"),
    ], [
        ("政府は新しい政策を発表しました。", "Seifu wa atarashii seisaku o happyou shimashita.", "Pemerintah mengumumkan kebijakan baru."),
        ("台風の対策をしました。", "Taifuu no taisaku o shimashita.", "Saya mengambil langkah pencegahan untuk topan."),
    ]),
    ("dan_n2", "団", ["ダン"], [], ["kelompok", "organisasi", "group"], 6, "囗", [
        ("団体", "dantai", "kelompok/organisasi"),
        ("集団", "shuudan", "kerumunan/kelompok"),
        ("団地", "danchi", "kompleks perumahan"),
    ], [
        ("団体で旅行しました。", "Dantai de ryokou shimashita.", "Saya bepergian bersama kelompok."),
        ("大きい集団を見ました。", "Ookii shuudan o mimashita.", "Saya melihat kerumunan besar."),
    ]),
    ("kaku_n2", "各", ["カク"], ["おのおの"], ["masing-masing", "setiap", "each"], 6, "口", [
        ("各地", "kakuchi", "berbagai tempat"),
        ("各国", "kakkoku", "setiap negara"),
        ("各自", "kakuji", "masing-masing individu"),
    ], [
        ("各地で雨が降っています。", "Kakuchi de ame ga futte imasu.", "Hujan turun di berbagai tempat."),
        ("各自で準備してください。", "Kakuji de junbi shite kudasai.", "Tolong siapkan sendiri-sendiri."),
    ]),
    ("tou2_n2", "島", ["トウ"], ["しま"], ["pulau", "island"], 10, "山", [
        ("島国", "shimaguni", "negara kepulauan"),
        ("半島", "hantou", "semenanjung"),
        ("離島", "ritou", "pulau terpencil"),
    ], [
        ("日本は島国です。", "Nihon wa shimaguni desu.", "Jepang adalah negara kepulauan."),
        ("半島を旅行しました。", "Hantou o ryokou shimashita.", "Saya bepergian ke semenanjung."),
    ]),
    ("kaku2_n2", "革", ["カク"], ["かわ"], ["kulit (bahan)", "reformasi", "leather"], 9, "革", [
        ("革命", "kakumei", "revolusi"),
        ("改革", "kaikaku", "reformasi"),
        ("革靴", "kawagutsu", "sepatu kulit"),
    ], [
        ("フランス革命を勉強しています。", "Furansu kakumei o benkyou shite imasu.", "Saya belajar tentang Revolusi Prancis."),
        ("革靴を買いました。", "Kawagutsu o kaimashita.", "Saya membeli sepatu kulit."),
    ]),
    ("sei2_n2", "勢", ["セイ"], ["いきお-い"], ["kekuatan", "momentum", "semangat"], 13, "力", [
        ("勢い", "ikioi", "momentum/semangat"),
        ("大勢", "oozei", "banyak orang/kerumunan"),
        ("姿勢", "shisei", "postur/sikap"),
    ], [
        ("彼は勢いよく走りました。", "Kare wa ikioi yoku hashirimashita.", "Dia berlari dengan penuh semangat."),
        ("大勢の人が集まりました。", "Oozei no hito ga atsumarimashita.", "Banyak orang berkumpul."),
    ]),
    ("gen_n2", "減", ["ゲン"], ["へ-る", "へ-らす"], ["berkurang", "mengurangi", "decrease"], 12, "水", [
        ("減少", "genshou", "penurunan"),
        ("加減", "kagen", "penyesuaian/tingkat"),
        ("減量", "genryou", "penurunan berat badan"),
    ], [
        ("人口が減少しています。", "Jinkou ga genshou shite imasu.", "Populasi menurun."),
        ("体重が減りました。", "Taijuu ga herimashita.", "Berat badan saya berkurang."),
    ]),
    ("sai_n2", "再", ["サイ"], ["ふたた-び"], ["lagi", "kembali", "again"], 6, "冂", [
        ("再来週", "sarainshuu", "dua minggu lagi"),
        ("再開", "saikai", "dibuka kembali"),
        ("再度", "saido", "sekali lagi"),
    ], [
        ("会議は来週再開します。", "Kaigi wa raishuu saikai shimasu.", "Rapat akan dibuka kembali minggu depan."),
        ("再度確認してください。", "Saido kakunin shite kudasai.", "Tolong periksa sekali lagi."),
    ]),
    ("zei_n2", "税", ["ゼイ"], [], ["pajak", "tax"], 12, "禾", [
        ("税金", "zeikin", "pajak"),
        ("消費税", "shouhizei", "pajak konsumsi"),
        ("税関", "zeikan", "bea cukai"),
    ], [
        ("消費税が上がりました。", "Shouhizei ga agarimashita.", "Pajak konsumsi naik."),
        ("税関で荷物を調べられました。", "Zeikan de nimotsu o shirabemashita.", "Barang saya diperiksa di bea cukai."),
    ]),
    ("ei_n2", "営", ["エイ"], ["いとな-む"], ["mengelola", "menjalankan usaha", "operate"], 12, "火", [
        ("営業", "eigyou", "operasional bisnis"),
        ("経営", "keiei", "manajemen"),
        ("営業時間", "eigyou jikan", "jam operasional"),
    ], [
        ("この店は10時から営業します。", "Kono mise wa juuji kara eigyou shimasu.", "Toko ini buka mulai jam 10."),
        ("彼は会社を経営しています。", "Kare wa kaisha o keiei shite imasu.", "Dia mengelola perusahaan."),
    ]),
    ("hi_n2", "比", ["ヒ"], ["くら-べる"], ["membandingkan", "rasio", "compare"], 4, "比", [
        ("比較", "hikaku", "perbandingan"),
        ("比率", "hiritsu", "rasio"),
        ("比べる", "kuraberu", "membandingkan"),
    ], [
        ("二つを比較しました。", "Futatsu o hikaku shimashita.", "Saya membandingkan dua hal."),
        ("兄と比べられます。", "Ani to kuraberaremasu.", "Saya sering dibandingkan dengan kakak laki-laki."),
    ]),
    ("bou_n2", "防", ["ボウ"], ["ふせ-ぐ"], ["mencegah", "mempertahankan", "prevent"], 7, "阜", [
        ("予防", "yobou", "pencegahan"),
        ("防止", "boushi", "pencegahan"),
        ("消防車", "shoubousha", "mobil pemadam kebakaran"),
    ], [
        ("風邪を予防しましょう。", "Kaze o yobou shimashou.", "Mari mencegah flu."),
        ("消防車が来ました。", "Shoubousha ga kimashita.", "Mobil pemadam kebakaran datang."),
    ]),
    ("ho2_n2", "補", ["ホ"], ["おぎな-う"], ["melengkapi", "menambah", "supplement"], 12, "衣", [
        ("補習", "hoshuu", "kelas tambahan"),
        ("補助", "hojo", "bantuan/subsidi"),
        ("候補", "kouho", "kandidat"),
    ], [
        ("補習を受けています。", "Hoshuu o ukete imasu.", "Saya mengikuti kelas tambahan."),
        ("彼は候補に選ばれました。", "Kare wa kouho ni erabaremashita.", "Dia terpilih sebagai kandidat."),
    ]),
    ("kyou2_n2", "境", ["キョウ"], ["さかい"], ["batas", "perbatasan", "border"], 14, "土", [
        ("環境", "kankyou", "lingkungan"),
        ("国境", "kokkyou", "perbatasan negara"),
        ("境界", "kyoukai", "batas"),
    ], [
        ("環境を守りましょう。", "Kankyou o mamorimashou.", "Mari kita jaga lingkungan."),
        ("国境を越えました。", "Kokkyou o koemashita.", "Saya melewati perbatasan negara."),
    ]),
    ("dou_n2", "導", ["ドウ"], ["みちび-く"], ["membimbing", "memandu", "guide"], 15, "寸", [
        ("指導", "shidou", "bimbingan"),
        ("導入", "dounyuu", "pengenalan/pengantar"),
        ("誘導", "yuudou", "panduan/pengarahan"),
    ], [
        ("先生が指導してくれました。", "Sensei ga shidou shite kuremashita.", "Guru membimbing saya."),
        ("新しいシステムを導入しました。", "Atarashii shisutemu o dounyuu shimashita.", "Kami memperkenalkan sistem baru."),
    ]),
    ("fuku_n2", "副", ["フク"], [], ["wakil", "sekunder", "vice"], 11, "刀", [
        ("副業", "fukugyou", "pekerjaan sampingan"),
        ("副社長", "fukushachou", "wakil direktur"),
        ("副作用", "fukusayou", "efek samping"),
    ], [
        ("副業をしています。", "Fukugyou o shite imasu.", "Saya melakukan pekerjaan sampingan."),
        ("この薬には副作用があります。", "Kono kusuri ni wa fukusayou ga arimasu.", "Obat ini memiliki efek samping."),
    ]),
    ("san_n2", "算", ["サン"], [], ["menghitung", "calculate"], 14, "竹", [
        ("計算", "keisan", "perhitungan"),
        ("予算", "yosan", "anggaran"),
        ("算数", "sansuu", "matematika (SD)"),
    ], [
        ("計算が苦手です。", "Keisan ga nigate desu.", "Saya tidak pandai berhitung."),
        ("予算を決めました。", "Yosan o kimemashita.", "Kami menetapkan anggaran."),
    ]),
    ("yu_n2", "輸", ["ユ"], [], ["mengangkut", "transportasi", "transport"], 16, "車", [
        ("輸出", "yushutsu", "ekspor"),
        ("輸入", "yunyuu", "impor"),
        ("輸送", "yusou", "pengangkutan"),
    ], [
        ("日本は車を輸出しています。", "Nihon wa kuruma o yushutsu shite imasu.", "Jepang mengekspor mobil."),
        ("果物を輸入しました。", "Kudamono o yunyuu shimashita.", "Kami mengimpor buah-buahan."),
    ]),
    ("jutsu_n2", "述", ["ジュツ"], ["の-べる"], ["menyatakan", "menyebutkan", "state"], 8, "辵", [
        ("述べる", "noberu", "menyatakan"),
        ("記述", "kijutsu", "deskripsi/uraian"),
        ("前述", "zenjutsu", "disebutkan sebelumnya"),
    ], [
        ("意見を述べました。", "Iken o nobemashita.", "Saya menyatakan pendapat."),
        ("前述の通りです。", "Zenjutsu no toori desu.", "Seperti yang disebutkan sebelumnya."),
    ]),
    ("sen_n2", "線", ["セン"], [], ["garis", "line"], 15, "糸", [
        ("直線", "chokusen", "garis lurus"),
        ("新幹線", "shinkansen", "kereta peluru"),
        ("線路", "senro", "rel kereta"),
    ], [
        ("新幹線に乗りました。", "Shinkansen ni norimashita.", "Saya naik kereta peluru."),
        ("線路を渡らないでください。", "Senro o wataranaide kudasai.", "Jangan menyeberangi rel kereta."),
    ]),
    ("nou_n2", "農", ["ノウ"], [], ["pertanian", "agriculture"], 13, "辰", [
        ("農業", "nougyou", "pertanian"),
        ("農家", "nouka", "petani/rumah tangga petani"),
        ("農民", "noumin", "petani"),
    ], [
        ("彼は農業をしています。", "Kare wa nougyou o shite imasu.", "Dia bertani."),
        ("農家で育ちました。", "Nouka de sodachimashita.", "Saya dibesarkan di keluarga petani."),
    ]),
    ("shuu_n2", "州", ["シュウ"], [], ["negara bagian", "provinsi", "state"], 6, "巛", [
        ("九州", "Kyuushuu", "Kyushu"),
        ("州立", "shuuritsu", "milik negara bagian"),
        ("本州", "Honshuu", "Honshu"),
    ], [
        ("九州へ旅行しました。", "Kyuushuu e ryokou shimashita.", "Saya bepergian ke Kyushu."),
        ("本州は日本で一番大きい島です。", "Honshuu wa Nihon de ichiban ookii shima desu.", "Honshu adalah pulau terbesar di Jepang."),
    ]),
    ("bu_n2", "武", ["ブ"], [], ["militer", "bela diri", "martial"], 8, "止", [
        ("武士", "bushi", "samurai"),
        ("武道", "budou", "seni bela diri"),
        ("武器", "buki", "senjata"),
    ], [
        ("武士の歴史を勉強しています。", "Bushi no rekishi o benkyou shite imasu.", "Saya belajar sejarah samurai."),
        ("武道を習っています。", "Budou o naratte imasu.", "Saya belajar bela diri."),
    ]),
    ("shou4_n2", "象", ["ショウ", "ゾウ"], [], ["gajah", "simbol", "elephant"], 12, "豕", [
        ("象", "zou", "gajah"),
        ("印象", "inshou", "kesan"),
        ("対象", "taishou", "target/objek"),
    ], [
        ("動物園で象を見ました。", "Doubutsuen de zou o mimashita.", "Saya melihat gajah di kebun binatang."),
        ("良い印象を持ちました。", "Yoi inshou o mochimashita.", "Saya mendapat kesan yang baik."),
    ]),
    ("iki_n2", "域", ["イキ"], [], ["wilayah", "area", "region"], 11, "土", [
        ("地域", "chiiki", "wilayah/daerah"),
        ("区域", "kuiki", "area/zona"),
        ("領域", "ryouiki", "ranah/domain"),
    ], [
        ("この地域は静かです。", "Kono chiiki wa shizuka desu.", "Wilayah ini tenang."),
        ("専門の領域を勉強しています。", "Senmon no ryouiki o benkyou shite imasu.", "Saya mempelajari ranah keahlian saya."),
    ]),
    ("gaku_n2", "額", ["ガク"], ["ひたい"], ["jumlah", "bingkai", "amount"], 18, "頁", [
        ("金額", "kingaku", "jumlah uang"),
        ("額縁", "gakubuchi", "bingkai foto"),
        ("額", "hitai", "dahi"),
    ], [
        ("金額を確認してください。", "Kingaku o kakunin shite kudasai.", "Tolong periksa jumlah uangnya."),
        ("写真を額縁に入れました。", "Shashin o gakubuchi ni iremashita.", "Saya memasukkan foto ke dalam bingkai."),
    ]),
    ("ou3_n2", "欧", ["オウ"], [], ["Eropa", "Europe"], 8, "欠", [
        ("欧州", "oushuu", "Eropa"),
        ("西欧", "seiou", "Eropa Barat"),
        ("欧米", "oubei", "Eropa dan Amerika"),
    ], [
        ("欧州を旅行したいです。", "Oushuu o ryokou shitai desu.", "Saya ingin bepergian ke Eropa."),
        ("欧米の文化に興味があります。", "Oubei no bunka ni kyoumi ga arimasu.", "Saya tertarik dengan budaya Eropa dan Amerika."),
    ]),
    ("tan_n2", "担", ["タン"], ["かつ-ぐ", "にな-う"], ["memikul", "bertanggung jawab", "carry"], 8, "手", [
        ("担当", "tantou", "penanggung jawab"),
        ("負担", "futan", "beban"),
        ("担任", "tannin", "wali kelas"),
    ], [
        ("彼が担当です。", "Kare ga tantou desu.", "Dia yang bertanggung jawab."),
        ("負担が大きいです。", "Futan ga ookii desu.", "Bebannya besar."),
    ]),
    ("jun_n2", "準", ["ジュン"], [], ["standar", "semi-"], 13, "水", [
        ("準備", "junbi", "persiapan"),
        ("基準", "kijun", "standar/kriteria"),
        ("水準", "suijun", "tingkat/level"),
    ], [
        ("準備ができました。", "Junbi ga dekimashita.", "Persiapan sudah selesai."),
        ("基準を決めましょう。", "Kijun o kimemashou.", "Mari kita tetapkan standar."),
    ]),
    ("shou_n2", "賞", ["ショウ"], [], ["hadiah", "penghargaan", "prize"], 15, "貝", [
        ("賞金", "shoukin", "uang hadiah"),
        ("受賞", "jushou", "menerima penghargaan"),
        ("賞品", "shouhin", "hadiah barang"),
    ], [
        ("彼は賞金をもらいました。", "Kare wa shoukin o moraimashita.", "Dia mendapat uang hadiah."),
        ("賞を受賞しました。", "Shou o jushou shimashita.", "Saya menerima penghargaan."),
    ]),
    ("hen_n2", "辺", ["ヘン"], ["あた-り", "べ"], ["sekitar", "sisi", "vicinity"], 5, "辵", [
        ("周辺", "shuuhen", "sekitar/sekeliling"),
        ("この辺", "kono hen", "sekitar sini"),
        ("海辺", "umibe", "tepi pantai"),
    ], [
        ("この辺にコンビニがありますか。", "Kono hen ni konbini ga arimasu ka.", "Apakah ada minimarket di sekitar sini?"),
        ("海辺を散歩しました。", "Umibe o sanpo shimashita.", "Saya jalan-jalan di tepi pantai."),
    ]),
    ("zou_n2", "造", ["ゾウ"], ["つく-る"], ["membuat", "menciptakan", "create"], 10, "辵", [
        ("製造", "seizou", "manufaktur"),
        ("造船", "zousen", "pembuatan kapal"),
        ("人造", "jinzou", "buatan manusia/sintetis"),
    ], [
        ("この工場で車を製造します。", "Kono koujou de kuruma o seizou shimasu.", "Mobil diproduksi di pabrik ini."),
        ("造船業で働いています。", "Zousengyou de hataraite imasu.", "Saya bekerja di industri pembuatan kapal."),
    ]),
    ("hi2_n2", "被", ["ヒ"], ["こうむ-る"], ["menderita", "menerima (pasif)", "suffer"], 10, "衣", [
        ("被害", "higai", "kerugian/kerusakan"),
        ("被災者", "hisaisha", "korban bencana"),
        ("被験者", "hikensha", "subjek penelitian"),
    ], [
        ("台風で被害がありました。", "Taifuu de higai ga arimashita.", "Ada kerusakan akibat topan."),
        ("被災者を助けました。", "Hisaisha o tasukemashita.", "Kami membantu korban bencana."),
    ]),
    ("gi_n2", "技", ["ギ"], ["わざ"], ["keterampilan", "teknik", "skill"], 7, "手", [
        ("技術", "gijutsu", "teknologi/teknik"),
        ("特技", "tokugi", "keahlian khusus"),
        ("演技", "engi", "akting/performa"),
    ], [
        ("技術が進歩しました。", "Gijutsu ga shinpo shimashita.", "Teknologi berkembang."),
        ("彼の演技は素晴らしいです。", "Kare no engi wa subarashii desu.", "Aktingnya luar biasa."),
    ]),
    ("tei_n2", "低", ["テイ"], ["ひく-い"], ["rendah", "low"], 7, "人", [
        ("低い", "hikui", "rendah"),
        ("最低", "saitei", "minimum/paling rendah"),
        ("低下", "teika", "penurunan"),
    ], [
        ("気温が低いです。", "Kion ga hikui desu.", "Suhunya rendah."),
        ("最低の点数でした。", "Saitei no tensuu deshita.", "Itu adalah nilai terendah."),
    ]),
    ("fuku2_n2", "復", ["フク"], [], ["memulihkan", "kembali", "restore"], 12, "彳", [
        ("回復", "kaifuku", "pemulihan"),
        ("復習", "fukushuu", "pengulangan pelajaran"),
        ("復活", "fukkatsu", "kebangkitan"),
    ], [
        ("病気から回復しました。", "Byouki kara kaifuku shimashita.", "Saya pulih dari sakit."),
        ("毎日復習しています。", "Mainichi fukushuu shite imasu.", "Saya mengulang pelajaran setiap hari."),
    ]),
    ("i2_n2", "移", ["イ"], ["うつ-る", "うつ-す"], ["berpindah", "memindahkan", "move"], 11, "禾", [
        ("移動", "idou", "perpindahan"),
        ("移民", "imin", "imigran"),
        ("移す", "utsusu", "memindahkan"),
    ], [
        ("電車で移動しました。", "Densha de idou shimashita.", "Saya berpindah dengan kereta."),
        ("彼は移民です。", "Kare wa imin desu.", "Dia adalah imigran."),
    ]),
    ("ko_n2", "個", ["コ"], [], ["individu", "kata bantu bilangan", "individual"], 10, "人", [
        ("個人", "kojin", "individu"),
        ("個性", "kosei", "kepribadian"),
        ("三個", "sanko", "tiga buah"),
    ], [
        ("個人の意見です。", "Kojin no iken desu.", "Ini pendapat pribadi."),
        ("りんごを三個買いました。", "Ringo o sanko kaimashita.", "Saya membeli tiga buah apel."),
    ]),
    ("mon_n2", "門", ["モン"], ["かど"], ["gerbang", "pintu", "gate"], 8, "門", [
        ("専門", "senmon", "spesialisasi"),
        ("校門", "koumon", "gerbang sekolah"),
        ("門", "kado", "gerbang"),
    ], [
        ("私の専門は経済学です。", "Watashi no senmon wa keizaigaku desu.", "Spesialisasi saya adalah ekonomi."),
        ("校門の前で待っています。", "Koumon no mae de matte imasu.", "Saya menunggu di depan gerbang sekolah."),
    ]),
    ("ka_n2", "課", ["カ"], [], ["pelajaran", "seksi", "lesson"], 15, "言", [
        ("課題", "kadai", "tugas"),
        ("課長", "kachou", "kepala seksi"),
        ("第一課", "daiikka", "pelajaran pertama"),
    ], [
        ("課題を提出しました。", "Kadai o teishutsu shimashita.", "Saya menyerahkan tugas."),
        ("彼は課長です。", "Kare wa kachou desu.", "Dia adalah kepala seksi."),
    ]),
    ("nou2_n2", "脳", ["ノウ"], [], ["otak", "brain"], 11, "肉", [
        ("頭脳", "zunou", "otak/kecerdasan"),
        ("脳", "nou", "otak"),
        ("首脳", "shunou", "pemimpin negara"),
    ], [
        ("脳を鍛えましょう。", "Nou o kitaemashou.", "Mari kita latih otak."),
        ("首脳会談が行われました。", "Shunou kaidan ga okonawaremashita.", "Pertemuan puncak diadakan."),
    ]),
    ("kyoku_n2", "極", ["キョク"], ["きわ-める"], ["ekstrem", "kutub", "extreme"], 12, "木", [
        ("極端", "kyokutan", "ekstrem"),
        ("北極", "hokkyoku", "Kutub Utara"),
        ("積極的", "sekkyokuteki", "proaktif/positif"),
    ], [
        ("それは極端な意見です。", "Sore wa kyokutan na iken desu.", "Itu pendapat yang ekstrem."),
        ("積極的に参加しました。", "Sekkyokuteki ni sanka shimashita.", "Saya berpartisipasi secara proaktif."),
    ]),
    ("gan_n2", "含", ["ガン"], ["ふく-む"], ["mengandung", "termasuk", "contain"], 7, "口", [
        ("含む", "fukumu", "mengandung/termasuk"),
        ("含まれる", "fukumareru", "termasuk (pasif)"),
        ("含有", "ganyuu", "kandungan"),
    ], [
        ("税金が含まれています。", "Zeikin ga fukumarete imasu.", "Pajak sudah termasuk."),
        ("この飲み物は砂糖を含みます。", "Kono nomimono wa satou o fukumimasu.", "Minuman ini mengandung gula."),
    ]),
    ("zou2_n2", "蔵", ["ゾウ"], ["くら"], ["menyimpan", "gudang", "storage"], 15, "艸", [
        ("冷蔵庫", "reizouko", "kulkas"),
        ("貯蔵", "chozou", "penyimpanan"),
        ("蔵", "kura", "gudang tradisional"),
    ], [
        ("冷蔵庫に牛乳があります。", "Reizouko ni gyuunyuu ga arimasu.", "Ada susu di kulkas."),
        ("米を貯蔵しています。", "Kome o chozou shite imasu.", "Kami menyimpan beras."),
    ]),
    ("ryou2_n2", "量", ["リョウ"], [], ["jumlah", "kuantitas", "amount"], 12, "里", [
        ("量", "ryou", "jumlah"),
        ("大量", "tairyou", "jumlah besar"),
        ("重量", "juuryou", "berat"),
    ], [
        ("大量の雨が降りました。", "Tairyou no ame ga furimashita.", "Hujan turun dalam jumlah besar."),
        ("重量を測りました。", "Juuryou o hakarimashita.", "Saya mengukur beratnya."),
    ]),
    ("kei_n2", "型", ["ケイ"], ["かた"], ["tipe", "model", "type"], 9, "土", [
        ("型", "kata", "tipe/pola"),
        ("大型", "ougata", "ukuran besar"),
        ("血液型", "ketsuekigata", "golongan darah"),
    ], [
        ("私の血液型はA型です。", "Watashi no ketsuekigata wa A-gata desu.", "Golongan darah saya adalah A."),
        ("大型のトラックです。", "Ougata no torakku desu.", "Itu truk berukuran besar."),
    ]),
    ("kyou3_n2", "況", ["キョウ"], [], ["situasi", "kondisi", "situation"], 8, "水", [
        ("状況", "joukyou", "situasi"),
        ("近況", "kinkyou", "kabar terkini"),
        ("不況", "fukyou", "resesi"),
    ], [
        ("状況を説明してください。", "Joukyou o setsumei shite kudasai.", "Tolong jelaskan situasinya."),
        ("近況を教えてください。", "Kinkyou o oshiete kudasai.", "Tolong beri tahu kabar terbarumu."),
    ]),
    ("shin_n2", "針", ["シン"], ["はり"], ["jarum", "needle"], 10, "金", [
        ("針", "hari", "jarum"),
        ("方針", "houshin", "kebijakan/arah"),
        ("時計の針", "tokei no hari", "jarum jam"),
    ], [
        ("針で服を縫いました。", "Hari de fuku o nuimashita.", "Saya menjahit baju dengan jarum."),
        ("新しい方針を決めました。", "Atarashii houshin o kimemashita.", "Kami menetapkan kebijakan baru."),
    ]),
    ("sen2_n2", "専", ["セン"], ["もっぱ-ら"], ["khusus", "mengkhususkan", "exclusive"], 9, "寸", [
        ("専攻", "senkou", "jurusan/spesialisasi studi"),
        ("専業主婦", "sengyou shufu", "ibu rumah tangga penuh waktu"),
        ("専用", "senyou", "khusus/eksklusif"),
    ], [
        ("大学で経済学を専攻しています。", "Daigaku de keizaigaku o senkou shite imasu.", "Saya mengambil jurusan ekonomi di universitas."),
        ("これは女性専用です。", "Kore wa josei senyou desu.", "Ini khusus untuk wanita."),
    ]),
    ("koku_n2", "谷", ["コク"], ["たに"], ["lembah", "valley"], 7, "谷", [
        ("谷", "tani", "lembah"),
        ("渋谷", "Shibuya", "nama tempat di Tokyo"),
        ("谷間", "tanima", "celah lembah"),
    ], [
        ("谷を歩きました。", "Tani o arukimashita.", "Saya berjalan melewati lembah."),
        ("渋谷で買い物をしました。", "Shibuya de kaimono o shimashita.", "Saya berbelanja di Shibuya."),
    ]),
    ("shi_n2", "史", ["シ"], [], ["sejarah", "history"], 5, "口", [
        ("歴史", "rekishi", "sejarah"),
        ("史上", "shijou", "dalam sejarah"),
        ("日本史", "nihonshi", "sejarah Jepang"),
    ], [
        ("歴史を勉強しています。", "Rekishi o benkyou shite imasu.", "Saya belajar sejarah."),
        ("これは史上最高の記録です。", "Kore wa shijou saikou no kiroku desu.", "Ini adalah rekor terbaik dalam sejarah."),
    ]),
    ("kai2_n2", "階", ["カイ"], [], ["lantai (tingkat)", "tangga", "floor"], 12, "阜", [
        ("二階", "nikai", "lantai dua"),
        ("階段", "kaidan", "tangga"),
        ("段階", "dankai", "tahap"),
    ], [
        ("二階に上がってください。", "Nikai ni agatte kudasai.", "Silakan naik ke lantai dua."),
        ("階段を使いましょう。", "Kaidan o tsukaimashou.", "Mari gunakan tangga."),
    ]),
    ("kan_n2", "管", ["カン"], ["くだ"], ["pipa", "mengelola", "manage"], 14, "竹", [
        ("管理", "kanri", "manajemen"),
        ("血管", "kekkan", "pembuluh darah"),
        ("管", "kuda", "pipa/tabung"),
    ], [
        ("会社を管理しています。", "Kaisha o kanri shite imasu.", "Saya mengelola perusahaan."),
        ("血管が細いです。", "Kekkan ga hosoi desu.", "Pembuluh darahnya tipis."),
    ]),
    ("hei_n2", "兵", ["ヘイ"], [], ["prajurit", "tentara", "soldier"], 7, "八", [
        ("兵士", "heishi", "prajurit"),
        ("兵隊", "heitai", "tentara"),
        ("兵器", "heiki", "senjata"),
    ], [
        ("兵士が行進しています。", "Heishi ga koushin shite imasu.", "Prajurit sedang berbaris."),
        ("兵器を廃止しましょう。", "Heiki o haishi shimashou.", "Mari kita hapuskan senjata."),
    ]),
    ("setsu2_n2", "接", ["セツ"], ["つ-ぐ"], ["menghubungkan", "kontak", "contact"], 11, "手", [
        ("接続", "setsuzoku", "koneksi"),
        ("直接", "chokusetsu", "langsung"),
        ("面接", "mensetsu", "wawancara"),
    ], [
        ("インターネットに接続しました。", "Intaanetto ni setsuzoku shimashita.", "Saya terhubung ke internet."),
        ("明日面接があります。", "Ashita mensetsu ga arimasu.", "Besok ada wawancara."),
    ]),
    ("kou_n2", "効", ["コウ"], ["き-く"], ["efek", "berkhasiat", "effect"], 8, "力", [
        ("効果", "kouka", "efek"),
        ("有効", "yuukou", "valid/efektif"),
        ("効く", "kiku", "berkhasiat/manjur"),
    ], [
        ("この薬は効果があります。", "Kono kusuri wa kouka ga arimasu.", "Obat ini berkhasiat."),
        ("このチケットは有効です。", "Kono chiketto wa yuukou desu.", "Tiket ini masih berlaku."),
    ]),
    ("gan2_n2", "丸", ["ガン"], ["まる", "まる-い"], ["bulat", "lingkaran", "round"], 3, "丶", [
        ("丸い", "marui", "bulat"),
        ("丸ごと", "marugoto", "secara keseluruhan"),
        ("日の丸", "hinomaru", "bendera Jepang"),
    ], [
        ("丸いテーブルです。", "Marui teeburu desu.", "Itu adalah meja bulat."),
        ("日の丸を見ました。", "Hinomaru o mimashita.", "Saya melihat bendera Jepang."),
    ]),
    ("wan_n2", "湾", ["ワン"], [], ["teluk", "bay"], 12, "水", [
        ("台湾", "Taiwan", "Taiwan"),
        ("湾岸", "wangan", "pesisir teluk"),
        ("東京湾", "Toukyou-wan", "Teluk Tokyo"),
    ], [
        ("台湾へ旅行しました。", "Taiwan e ryokou shimashita.", "Saya bepergian ke Taiwan."),
        ("東京湾を見ました。", "Toukyou-wan o mimashita.", "Saya melihat Teluk Tokyo."),
    ]),
    ("roku_n2", "録", ["ロク"], [], ["mencatat", "merekam", "record"], 16, "金", [
        ("記録", "kiroku", "rekaman/catatan"),
        ("録音", "rokuon", "rekaman suara"),
        ("登録", "touroku", "pendaftaran"),
    ], [
        ("新記録を作りました。", "Shin kiroku o tsukurimashita.", "Saya membuat rekor baru."),
        ("会員登録をしました。", "Kaiin touroku o shimashita.", "Saya mendaftar sebagai anggota."),
    ]),
    ("shou2_n2", "省", ["ショウ", "セイ"], ["かえり-みる", "はぶ-く"], ["kementerian", "merenungkan", "menghemat"], 9, "目", [
        ("反省", "hansei", "refleksi diri"),
        ("外務省", "gaimushou", "Kementerian Luar Negeri"),
        ("省略", "shouryaku", "penyingkatan"),
    ], [
        ("自分の行動を反省しました。", "Jibun no koudou o hansei shimashita.", "Saya merefleksikan tindakan saya sendiri."),
        ("外務省で働いています。", "Gaimushou de hataraite imasu.", "Saya bekerja di Kementerian Luar Negeri."),
    ]),
    ("kyuu_n2", "旧", ["キュウ"], [], ["lama", "dahulu", "former"], 5, "日", [
        ("旧友", "kyuuyuu", "teman lama"),
        ("旧式", "kyuushiki", "model lama"),
        ("旧正月", "kyuu shougatsu", "tahun baru imlek"),
    ], [
        ("旧友に会いました。", "Kyuuyuu ni aimashita.", "Saya bertemu teman lama."),
        ("旧正月を祝います。", "Kyuu shougatsu o iwaimasu.", "Kami merayakan tahun baru imlek."),
    ]),
    ("kyou4_n2", "橋", ["キョウ"], ["はし"], ["jembatan", "bridge"], 16, "木", [
        ("橋", "hashi", "jembatan"),
        ("大橋", "oohashi", "jembatan besar"),
        ("陸橋", "rikkyou", "jembatan penyeberangan"),
    ], [
        ("橋を渡りました。", "Hashi o watarimashita.", "Saya menyeberangi jembatan."),
        ("大きい橋が見えます。", "Ookii hashi ga miemasu.", "Terlihat jembatan besar."),
    ]),
    ("gan3_n2", "岸", ["ガン"], ["きし"], ["pantai", "tepi", "shore"], 8, "山", [
        ("海岸", "kaigan", "pantai"),
        ("岸", "kishi", "tepi/pesisir"),
        ("対岸", "taigan", "seberang sungai/pantai"),
    ], [
        ("海岸を歩きました。", "Kaigan o arukimashita.", "Saya berjalan di pantai."),
        ("対岸に渡りました。", "Taigan ni watarimashita.", "Saya menyeberang ke seberang."),
    ]),
    ("shuu2_n2", "周", ["シュウ"], [], ["sekeliling", "lingkar", "circumference"], 8, "口", [
        ("周囲", "shuui", "sekeliling"),
        ("一周", "isshuu", "satu putaran"),
        ("周期", "shuuki", "siklus/periode"),
    ], [
        ("公園を一周しました。", "Kouen o isshuu shimashita.", "Saya mengelilingi taman satu putaran."),
        ("周囲を見回しました。", "Shuui o mimawashimashita.", "Saya melihat sekeliling."),
    ]),
    ("zai_n2", "材", ["ザイ"], [], ["bahan", "material"], 7, "木", [
        ("材料", "zairyou", "bahan"),
        ("木材", "mokuzai", "kayu"),
        ("人材", "jinzai", "sumber daya manusia"),
    ], [
        ("料理の材料を買いました。", "Ryouri no zairyou o kaimashita.", "Saya membeli bahan masakan."),
        ("人材を育てています。", "Jinzai o sodatete imasu.", "Kami mengembangkan sumber daya manusia."),
    ]),
    ("ko2_n2", "戸", ["コ"], ["と"], ["pintu", "rumah tangga", "door"], 4, "戸", [
        ("戸", "to", "pintu"),
        ("戸建て", "kodate", "rumah tapak"),
        ("神戸", "Koube", "Kobe"),
    ], [
        ("戸を閉めてください。", "To o shimete kudasai.", "Tolong tutup pintunya."),
        ("神戸に住んでいます。", "Koube ni sunde imasu.", "Saya tinggal di Kobe."),
    ]),
    ("ou2_n2", "央", ["オウ"], [], ["pusat", "tengah", "center"], 5, "大", [
        ("中央", "chuuou", "pusat/tengah"),
        ("中央線", "Chuou-sen", "Jalur Chuo"),
        ("中央銀行", "chuuou ginkou", "bank sentral"),
    ], [
        ("中央駅で降りました。", "Chuuou eki de orimashita.", "Saya turun di stasiun pusat."),
        ("中央線に乗りました。", "Chuuou-sen ni norimashita.", "Saya naik Jalur Chuo."),
    ]),
    ("ken2_n2", "券", ["ケン"], [], ["tiket", "sertifikat", "ticket"], 8, "刀", [
        ("券", "ken", "tiket"),
        ("商品券", "shouhinken", "voucher belanja"),
        ("入場券", "nyuujouken", "tiket masuk"),
    ], [
        ("商品券をもらいました。", "Shouhinken o moraimashita.", "Saya mendapat voucher belanja."),
        ("入場券を買いました。", "Nyuujouken o kaimashita.", "Saya membeli tiket masuk."),
    ]),
    ("hen2_n2", "編", ["ヘン"], ["あ-む"], ["menyusun", "merajut", "compile"], 15, "糸", [
        ("編集", "henshuu", "penyuntingan"),
        ("編む", "amu", "merajut"),
        ("長編", "chouhen", "karya panjang"),
    ], [
        ("雑誌を編集しています。", "Zasshi o henshuu shite imasu.", "Saya menyunting majalah."),
        ("セーターを編みました。", "Seetaa o amimashita.", "Saya merajut sweater."),
    ]),
    ("sou2_n2", "捜", ["ソウ"], ["さが-す"], ["mencari", "search"], 10, "手", [
        ("捜査", "sousa", "investigasi/penyelidikan"),
        ("捜索", "sousaku", "pencarian"),
        ("捜す", "sagasu", "mencari"),
    ], [
        ("警察が捜査しています。", "Keisatsu ga sousa shite imasu.", "Polisi sedang menyelidiki."),
        ("犯人を捜索しています。", "Hannin o sousaku shite imasu.", "Mereka mencari pelaku."),
    ]),
    ("chiku_n2", "竹", ["チク"], ["たけ"], ["bambu", "bamboo"], 6, "竹", [
        ("竹", "take", "bambu"),
        ("竹林", "chikurin", "hutan bambu"),
        ("竹の子", "takenoko", "rebung"),
    ], [
        ("竹林を歩きました。", "Chikurin o arukimashita.", "Saya berjalan melewati hutan bambu."),
        ("竹の子を食べました。", "Takenoko o tabemashita.", "Saya makan rebung."),
    ]),
    ("chou_n2", "超", ["チョウ"], ["こ-える", "こ-す"], ["melebihi", "super-", "exceed"], 12, "走", [
        ("超える", "koeru", "melebihi"),
        ("超過", "chouka", "kelebihan"),
        ("超人", "choujin", "manusia super"),
    ], [
        ("予算を超えました。", "Yosan o koemashita.", "Melebihi anggaran."),
        ("時間を超過しました。", "Jikan o chouka shimashita.", "Waktu terlampaui."),
    ]),
    ("hei2_n2", "並", ["ヘイ"], ["なみ", "なら-ぶ"], ["berjajar", "biasa", "ordinary"], 8, "一", [
        ("並ぶ", "narabu", "berbaris/berjajar"),
        ("並木", "namiki", "pohon jalan"),
        ("並行", "heikou", "paralel"),
    ], [
        ("人々が並んでいます。", "Hitobito ga narande imasu.", "Orang-orang sedang berbaris."),
        ("並木道を歩きました。", "Namiki michi o arukimashita.", "Saya berjalan di jalan berpohon."),
    ]),
    ("ryou3_n2", "療", ["リョウ"], [], ["pengobatan", "medical treatment"], 17, "疒", [
        ("治療", "chiryou", "pengobatan"),
        ("医療", "iryou", "layanan medis"),
        ("療養", "ryouyou", "perawatan/pemulihan"),
    ], [
        ("治療を受けました。", "Chiryou o ukemashita.", "Saya menerima pengobatan."),
        ("医療費が高いです。", "Iryouhi ga takai desu.", "Biaya medis mahal."),
    ]),
    ("sai2_n2", "採", ["サイ"], ["と-る"], ["mengambil", "mengadopsi", "adopt"], 11, "手", [
        ("採用", "saiyou", "perekrutan"),
        ("採点", "saiten", "penilaian"),
        ("採取", "saishu", "pengumpulan"),
    ], [
        ("新入社員を採用しました。", "Shinnyuu shain o saiyou shimashita.", "Kami merekrut karyawan baru."),
        ("テストを採点しています。", "Tesuto o saiten shite imasu.", "Saya sedang menilai tes."),
    ]),
    ("kyou5_n2", "競", ["キョウ", "ケイ"], ["きそ-う", "せ-る"], ["berkompetisi", "compete"], 20, "立", [
        ("競争", "kyousou", "kompetisi"),
        ("競技", "kyougi", "pertandingan"),
        ("競馬", "keiba", "pacuan kuda"),
    ], [
        ("競争が激しいです。", "Kyousou ga hageshii desu.", "Kompetisinya ketat."),
        ("競技に参加しました。", "Kyougi ni sanka shimashita.", "Saya berpartisipasi dalam pertandingan."),
    ]),
    ("kai3_n2", "介", ["カイ"], [], ["perantara", "mediate"], 4, "人", [
        ("紹介", "shoukai", "perkenalan"),
        ("介護", "kaigo", "perawatan lansia"),
        ("仲介", "chuukai", "perantara"),
    ], [
        ("友達を紹介します。", "Tomodachi o shoukai shimasu.", "Saya akan memperkenalkan teman saya."),
        ("介護の仕事をしています。", "Kaigo no shigoto o shite imasu.", "Saya bekerja di bidang perawatan lansia."),
    ]),
    ("kon_n2", "根", ["コン"], ["ね"], ["akar", "root"], 10, "木", [
        ("根", "ne", "akar"),
        ("根本", "konpon", "dasar/fundamental"),
        ("屋根", "yane", "atap"),
    ], [
        ("木の根が見えます。", "Ki no ne ga miemasu.", "Terlihat akar pohon."),
        ("屋根の上に猫がいます。", "Yane no ue ni neko ga imasu.", "Ada kucing di atas atap."),
    ]),
    ("han_n2", "販", ["ハン"], [], ["menjual", "sell"], 11, "貝", [
        ("販売", "hanbai", "penjualan"),
        ("販売員", "hanbaiin", "staf penjualan"),
        ("市販", "shihan", "dijual di pasaran"),
    ], [
        ("新製品を販売しています。", "Shinseihin o hanbai shite imasu.", "Kami menjual produk baru."),
        ("これは市販の薬です。", "Kore wa shihan no kusuri desu.", "Ini obat yang dijual bebas."),
    ]),
    ("reki_n2", "歴", ["レキ"], [], ["sejarah", "riwayat", "history"], 14, "止", [
        ("歴史", "rekishi", "sejarah"),
        ("経歴", "keireki", "riwayat karir"),
        ("履歴書", "rirekisho", "CV/resume"),
    ], [
        ("履歴書を書きました。", "Rirekisho o kakimashita.", "Saya menulis CV."),
        ("彼の経歴は素晴らしいです。", "Kare no keireki wa subarashii desu.", "Riwayat karirnya luar biasa."),
    ]),
    ("shou5_n2", "将", ["ショウ"], [], ["jenderal", "pemimpin", "general"], 10, "寸", [
        ("将来", "shourai", "masa depan"),
        ("将軍", "shougun", "shogun/jenderal"),
        ("主将", "shushou", "kapten tim"),
    ], [
        ("将来の夢は何ですか。", "Shourai no yume wa nan desu ka.", "Apa mimpi masa depanmu?"),
        ("彼はチームの主将です。", "Kare wa chiimu no shushou desu.", "Dia adalah kapten tim."),
    ]),
    ("fuku3_n2", "幅", ["フク"], ["はば"], ["lebar", "width"], 12, "巾", [
        ("幅", "haba", "lebar"),
        ("大幅", "oohaba", "secara signifikan"),
        ("幅広い", "habahiroi", "luas/lebar"),
    ], [
        ("この道は幅が広いです。", "Kono michi wa haba ga hiroi desu.", "Jalan ini lebar."),
        ("大幅に値上がりしました。", "Oohaba ni neagari shimashita.", "Harga naik secara signifikan."),
    ]),
    ("han2_n2", "般", ["ハン"], [], ["umum", "segala macam", "general"], 10, "舟", [
        ("一般", "ippan", "umum"),
        ("全般", "zenpan", "keseluruhan"),
        ("一般的", "ippanteki", "secara umum"),
    ], [
        ("これは一般的な意見です。", "Kore wa ippanteki na iken desu.", "Ini adalah pendapat umum."),
        ("全般的に良かったです。", "Zenpanteki ni yokatta desu.", "Secara keseluruhan bagus."),
    ]),
    ("bou2_n2", "貿", ["ボウ"], [], ["perdagangan", "trade"], 12, "貝", [
        ("貿易", "boueki", "perdagangan"),
        ("貿易会社", "boueki gaisha", "perusahaan dagang"),
        ("貿易風", "boueki fuu", "angin pasat"),
    ], [
        ("貿易の仕事をしています。", "Boueki no shigoto o shite imasu.", "Saya bekerja di bidang perdagangan."),
        ("貿易会社に勤めています。", "Boueki gaisha ni tsutomete imasu.", "Saya bekerja di perusahaan dagang."),
    ]),
    ("kou2_n2", "講", ["コウ"], [], ["kuliah", "ceramah", "lecture"], 17, "言", [
        ("講義", "kougi", "kuliah"),
        ("講演", "kouen", "ceramah"),
        ("講師", "koushi", "dosen/pengajar"),
    ], [
        ("大学で講義を受けています。", "Daigaku de kougi o ukete imasu.", "Saya mengikuti kuliah di universitas."),
        ("講演を聞きました。", "Kouen o kikimashita.", "Saya mendengarkan ceramah."),
    ]),
    ("sou3_n2", "装", ["ソウ"], ["よそお-う"], ["berpakaian", "melengkapi", "equip"], 12, "衣", [
        ("服装", "fukusou", "pakaian"),
        ("装置", "souchi", "perangkat/peralatan"),
        ("衣装", "ishou", "kostum"),
    ], [
        ("服装に気をつけてください。", "Fukusou ni ki o tsukete kudasai.", "Perhatikan pakaian Anda."),
        ("新しい装置を買いました。", "Atarashii souchi o kaimashita.", "Saya membeli perangkat baru."),
    ]),
    ("sho_n2", "諸", ["ショ"], [], ["berbagai", "various"], 15, "言", [
        ("諸国", "shokoku", "berbagai negara"),
        ("諸問題", "shomondai", "berbagai masalah"),
        ("諸島", "shotou", "kepulauan"),
    ], [
        ("諸国を訪問しました。", "Shokoku o houmon shimashita.", "Saya mengunjungi berbagai negara."),
        ("諸問題を解決しました。", "Shomondai o kaiketsu shimashita.", "Saya menyelesaikan berbagai masalah."),
    ]),
    ("geki_n2", "劇", ["ゲキ"], [], ["drama", "pertunjukan", "play"], 15, "刀", [
        ("劇場", "gekijou", "teater"),
        ("演劇", "engeki", "drama/teater"),
        ("劇的", "gekiteki", "dramatis"),
    ], [
        ("劇場で映画を見ました。", "Gekijou de eiga o mimashita.", "Saya menonton film di teater."),
        ("演劇部に入っています。", "Engekibu ni haitte imasu.", "Saya bergabung dengan klub drama."),
    ]),
    ("ka2_n2", "河", ["カ"], ["かわ"], ["sungai", "river"], 8, "水", [
        ("河川", "kasen", "sungai-sungai"),
        ("銀河", "ginga", "galaksi"),
        ("河口", "kakou", "muara sungai"),
    ], [
        ("河川が氾濫しました。", "Kasen ga hanran shimashita.", "Sungai meluap."),
        ("銀河を見ました。", "Ginga o mimashita.", "Saya melihat galaksi."),
    ]),
    ("kou3_n2", "航", ["コウ"], [], ["berlayar", "navigasi", "navigate"], 10, "舟", [
        ("航空", "koukuu", "penerbangan"),
        ("航海", "koukai", "pelayaran"),
        ("運航", "unkou", "operasi penerbangan/pelayaran"),
    ], [
        ("航空会社で働いています。", "Koukuu gaisha de hataraite imasu.", "Saya bekerja di maskapai penerbangan."),
        ("船が航海しています。", "Fune ga koukai shite imasu.", "Kapal sedang berlayar."),
    ]),
    ("tetsu_n2", "鉄", ["テツ"], [], ["besi", "iron"], 13, "金", [
        ("地下鉄", "chikatetsu", "kereta bawah tanah"),
        ("鉄道", "tetsudou", "kereta api"),
        ("鉄", "tetsu", "besi"),
    ], [
        ("地下鉄で行きます。", "Chikatetsu de ikimasu.", "Saya pergi dengan kereta bawah tanah."),
        ("鉄道が便利です。", "Tetsudou ga benri desu.", "Kereta api itu praktis."),
    ]),
    ("ji_n2", "児", ["ジ"], [], ["anak", "child"], 7, "儿", [
        ("児童", "jidou", "anak-anak"),
        ("幼児", "youji", "balita"),
        ("育児", "ikuji", "pengasuhan anak"),
    ], [
        ("児童のための本です。", "Jidou no tame no hon desu.", "Ini buku untuk anak-anak."),
        ("育児は大変です。", "Ikuji wa taihen desu.", "Mengasuh anak itu berat."),
    ]),
    ("kin_n2", "禁", ["キン"], [], ["melarang", "prohibit"], 13, "示", [
        ("禁止", "kinshi", "larangan"),
        ("禁煙", "kin'en", "dilarang merokok"),
        ("禁物", "kinmotsu", "pantangan"),
    ], [
        ("駐車禁止です。", "Chuusha kinshi desu.", "Dilarang parkir."),
        ("ここは禁煙です。", "Koko wa kin'en desu.", "Di sini dilarang merokok."),
    ]),
    ("in_n2", "印", ["イン"], ["しるし"], ["cap", "tanda", "seal"], 6, "卩", [
        ("印鑑", "inkan", "stempel/cap"),
        ("目印", "mejirushi", "penanda"),
        ("印刷", "insatsu", "percetakan"),
    ], [
        ("印鑑を押してください。", "Inkan o oshite kudasai.", "Tolong bubuhkan cap."),
        ("書類を印刷しました。", "Shorui o insatsu shimashita.", "Saya mencetak dokumen."),
    ]),
    ("gyaku_n2", "逆", ["ギャク"], ["さか", "さか-らう"], ["kebalikan", "terbalik", "reverse"], 9, "辵", [
        ("逆に", "gyaku ni", "sebaliknya"),
        ("逆転", "gyakuten", "pembalikan"),
        ("逆方向", "gyaku houkou", "arah berlawanan"),
    ], [
        ("逆に考えてみましょう。", "Gyaku ni kangaete mimashou.", "Mari coba pikirkan sebaliknya."),
        ("試合で逆転しました。", "Shiai de gyakuten shimashita.", "Kami membalikkan keadaan dalam pertandingan."),
    ]),
    ("kan2_n2", "換", ["カン"], ["か-える", "か-わる"], ["menukar", "exchange"], 12, "手", [
        ("交換", "koukan", "pertukaran"),
        ("転換", "tenkan", "konversi/perubahan"),
        ("換気", "kanki", "ventilasi"),
    ], [
        ("意見を交換しました。", "Iken o koukan shimashita.", "Kami bertukar pendapat."),
        ("部屋を換気しています。", "Heya o kanki shite imasu.", "Saya memventilasi ruangan."),
    ]),
    ("kyuu2_n2", "久", ["キュウ", "ク"], ["ひさ-しい"], ["lama (waktu)", "long time"], 3, "丿", [
        ("久しぶり", "hisashiburi", "sudah lama"),
        ("永久", "eikyuu", "abadi/kekal"),
        ("久しい", "hisashii", "sudah lama"),
    ], [
        ("久しぶりですね。", "Hisashiburi desu ne.", "Sudah lama tidak bertemu ya."),
        ("永久に忘れません。", "Eikyuu ni wasuremasen.", "Saya tidak akan pernah lupa."),
    ]),
    ("tan2_n2", "短", ["タン"], ["みじか-い"], ["pendek", "short"], 12, "矢", [
        ("短い", "mijikai", "pendek"),
        ("短期", "tanki", "jangka pendek"),
        ("短所", "tansho", "kekurangan"),
    ], [
        ("髪が短いです。", "Kami ga mijikai desu.", "Rambutnya pendek."),
        ("短期のアルバイトです。", "Tanki no arubaito desu.", "Ini pekerjaan paruh waktu jangka pendek."),
    ]),
    ("yu2_n2", "油", ["ユ"], ["あぶら"], ["minyak", "oil"], 8, "水", [
        ("石油", "sekiyu", "minyak bumi"),
        ("油", "abura", "minyak"),
        ("醤油", "shouyu", "kecap asin"),
    ], [
        ("石油の値段が上がりました。", "Sekiyu no nedan ga agarimashita.", "Harga minyak bumi naik."),
        ("醤油をかけました。", "Shouyu o kakemashita.", "Saya menuangkan kecap asin."),
    ]),
    ("bou3_n2", "暴", ["ボウ"], ["あば-れる"], ["kekerasan", "ganas", "violent"], 15, "日", [
        ("暴力", "bouryoku", "kekerasan"),
        ("暴風", "boufuu", "angin kencang"),
        ("乱暴", "ranbou", "kasar/brutal"),
    ], [
        ("暴力はいけません。", "Bouryoku wa ikemasen.", "Kekerasan tidak boleh dilakukan."),
        ("暴風で木が倒れました。", "Boufuu de ki ga taoremashita.", "Pohon tumbang karena angin kencang."),
    ]),
    ("rin_n2", "輪", ["リン"], ["わ"], ["roda", "lingkaran", "wheel"], 15, "車", [
        ("輪", "wa", "lingkaran/cincin"),
        ("車輪", "sharin", "roda"),
        ("指輪", "yubiwa", "cincin"),
    ], [
        ("指輪をもらいました。", "Yubiwa o moraimashita.", "Saya menerima cincin."),
        ("車輪が壊れました。", "Sharin ga kowaremashita.", "Rodanya rusak."),
    ]),
    ("sen3_n2", "占", ["セン"], ["し-める", "うらな-う"], ["menempati", "meramal", "occupy"], 5, "卜", [
        ("占める", "shimeru", "menempati"),
        ("占い", "uranai", "ramalan"),
        ("独占", "dokusen", "monopoli"),
    ], [
        ("大きい部分を占めています。", "Ookii bubun o shimete imasu.", "Menempati bagian yang besar."),
        ("占いを信じますか。", "Uranai o shinjimasu ka.", "Apakah kamu percaya ramalan?"),
    ]),
    ("shoku_n2", "植", ["ショク"], ["う-える"], ["menanam", "plant"], 12, "木", [
        ("植物", "shokubutsu", "tumbuhan"),
        ("植える", "ueru", "menanam"),
        ("田植え", "taue", "menanam padi"),
    ], [
        ("植物を育てています。", "Shokubutsu o sodatete imasu.", "Saya membudidayakan tumbuhan."),
        ("木を植えました。", "Ki o uemashita.", "Saya menanam pohon."),
    ]),
    ("sei_n2", "清", ["セイ"], ["きよ-い"], ["bersih", "murni", "clean"], 11, "水", [
        ("清潔", "seiketsu", "bersih/higienis"),
        ("清書", "seisho", "salinan bersih"),
        ("清い", "kiyoi", "murni/bersih"),
    ], [
        ("部屋を清潔にしています。", "Heya o seiketsu ni shite imasu.", "Saya menjaga kamar tetap bersih."),
        ("清い川が流れています。", "Kiyoi kawa ga nagarete imasu.", "Sungai yang jernih mengalir."),
    ]),
    ("bai_n2", "倍", ["バイ"], [], ["kali lipat", "times/double"], 10, "人", [
        ("二倍", "nibai", "dua kali lipat"),
        ("倍増", "baizou", "dua kali lipat/berlipat ganda"),
        ("何倍", "nanbai", "berapa kali lipat"),
    ], [
        ("値段が二倍になりました。", "Nedan ga nibai ni narimashita.", "Harganya menjadi dua kali lipat."),
        ("売り上げが倍増しました。", "Uriage ga baizou shimashita.", "Penjualan berlipat ganda."),
    ]),
    ("kin2_n2", "均", ["キン"], [], ["rata", "seimbang", "even"], 7, "土", [
        ("平均", "heikin", "rata-rata"),
        ("均等", "kintou", "sama rata"),
        ("均一", "kin'itsu", "seragam"),
    ], [
        ("平均点は80点です。", "Heikinten wa hachijutten desu.", "Nilai rata-rata adalah 80."),
        ("均等に分けました。", "Kintou ni wakemashita.", "Saya membagi rata."),
    ]),
    ("oku_n2", "億", ["オク"], [], ["seratus juta", "hundred million"], 15, "人", [
        ("一億", "ichioku", "seratus juta"),
        ("億万長者", "okumanchouja", "miliuner"),
        ("数億", "suuoku", "beberapa ratus juta"),
    ], [
        ("日本の人口は一億人以上です。", "Nihon no jinkou wa ichioku nin ijou desu.", "Populasi Jepang lebih dari seratus juta."),
        ("彼は億万長者です。", "Kare wa okumanchouja desu.", "Dia adalah miliuner."),
    ]),
    ("atsu_n2", "圧", ["アツ"], [], ["tekanan", "pressure"], 5, "土", [
        ("圧力", "atsuryoku", "tekanan"),
        ("気圧", "kiatsu", "tekanan udara"),
        ("血圧", "ketsuatsu", "tekanan darah"),
    ], [
        ("圧力を感じています。", "Atsuryoku o kanjite imasu.", "Saya merasakan tekanan."),
        ("血圧を測りました。", "Ketsuatsu o hakarimashita.", "Saya mengukur tekanan darah."),
    ]),
    ("gei_n2", "芸", ["ゲイ"], [], ["seni", "pertunjukan", "art"], 7, "艸", [
        ("芸術", "geijutsu", "seni"),
        ("芸能人", "geinoujin", "selebriti"),
        ("文芸", "bungei", "sastra dan seni"),
    ], [
        ("芸術に興味があります。", "Geijutsu ni kyoumi ga arimasu.", "Saya tertarik dengan seni."),
        ("芸能人に会いました。", "Geinoujin ni aimashita.", "Saya bertemu selebriti."),
    ]),
    ("sho2_n2", "署", ["ショ"], [], ["kantor", "menandatangani", "office"], 13, "网", [
        ("警察署", "keisatsusho", "kantor polisi"),
        ("署名", "shomei", "tanda tangan"),
        ("消防署", "shoubousho", "kantor pemadam kebakaran"),
    ], [
        ("警察署に行きました。", "Keisatsusho ni ikimashita.", "Saya pergi ke kantor polisi."),
        ("ここに署名してください。", "Koko ni shomei shite kudasai.", "Tolong tanda tangan di sini."),
    ]),
    ("shin2_n2", "伸", ["シン"], ["の-びる", "の-ばす"], ["memanjang", "meregang", "extend"], 7, "人", [
        ("伸びる", "nobiru", "memanjang/berkembang"),
        ("伸ばす", "nobasu", "memperpanjang"),
        ("伸縮", "shinshuku", "elastisitas"),
    ], [
        ("髪が伸びました。", "Kami ga nobimashita.", "Rambut saya memanjang."),
        ("手を伸ばしてください。", "Te o nobashite kudasai.", "Tolong rentangkan tangan."),
    ]),
    ("tei2_n2", "停", ["テイ"], [], ["berhenti", "stop"], 11, "人", [
        ("停止", "teishi", "berhenti"),
        ("バス停", "basutei", "halte bus"),
        ("停電", "teiden", "mati listrik"),
    ], [
        ("車が停止しました。", "Kuruma ga teishi shimashita.", "Mobilnya berhenti."),
        ("停電になりました。", "Teiden ni narimashita.", "Listrik padam."),
    ]),
    ("baku_n2", "爆", ["バク"], [], ["meledak", "explode"], 19, "火", [
        ("爆発", "bakuhatsu", "ledakan"),
        ("爆弾", "bakudan", "bom"),
        ("原爆", "genbaku", "bom atom"),
    ], [
        ("爆発が起きました。", "Bakuhatsu ga okimashita.", "Terjadi ledakan."),
        ("原爆について学びました。", "Genbaku ni tsuite manabimashita.", "Saya belajar tentang bom atom."),
    ]),
    ("riku_n2", "陸", ["リク"], [], ["daratan", "land"], 11, "阜", [
        ("大陸", "tairiku", "benua"),
        ("陸上", "rikujou", "atletik/di darat"),
        ("着陸", "chakuriku", "pendaratan"),
    ], [
        ("アジアは大陸です。", "Ajia wa tairiku desu.", "Asia adalah benua."),
        ("飛行機が着陸しました。", "Hikouki ga chakuriku shimashita.", "Pesawat mendarat."),
    ]),
    ("gyoku_n2", "玉", ["ギョク"], ["たま"], ["permata", "bola", "jewel"], 5, "玉", [
        ("玉", "tama", "bola/permata"),
        ("目玉", "medama", "bola mata"),
        ("十円玉", "juuendama", "koin 10 yen"),
    ], [
        ("目玉焼きを作りました。", "Medamayaki o tsukurimashita.", "Saya membuat telur mata sapi."),
        ("十円玉を落としました。", "Juuendama o otoshimashita.", "Saya menjatuhkan koin 10 yen."),
    ]),
    ("ha2_n2", "波", ["ハ"], ["なみ"], ["gelombang", "ombak", "wave"], 8, "水", [
        ("波", "nami", "ombak"),
        ("電波", "denpa", "gelombang elektromagnetik"),
        ("津波", "tsunami", "tsunami"),
    ], [
        ("波が高いです。", "Nami ga takai desu.", "Ombaknya tinggi."),
        ("津波が来ました。", "Tsunami ga kimashita.", "Tsunami datang."),
    ]),
    ("tai_n2", "帯", ["タイ"], ["おび"], ["sabuk", "zona", "belt"], 10, "巾", [
        ("温帯", "ontai", "zona iklim sedang"),
        ("携帯電話", "keitai denwa", "ponsel"),
        ("帯", "obi", "sabuk/obi"),
    ], [
        ("携帯電話を忘れました。", "Keitai denwa o wasuremashita.", "Saya lupa membawa ponsel."),
        ("着物の帯を締めました。", "Kimono no obi o shimemashita.", "Saya mengikat obi kimono."),
    ]),
    ("en_n2", "延", ["エン"], ["の-びる", "の-ばす"], ["memperpanjang", "menunda", "postpone"], 8, "廴", [
        ("延長", "enchou", "perpanjangan"),
        ("延期", "enki", "penundaan"),
        ("延びる", "nobiru", "ditunda/diperpanjang"),
    ], [
        ("試合が延長になりました。", "Shiai ga enchou ni narimashita.", "Pertandingan diperpanjang."),
        ("会議が延期されました。", "Kaigi ga enki saremashita.", "Rapat ditunda."),
    ]),
    ("u_n2", "羽", ["ウ"], ["は", "はね"], ["bulu", "sayap", "feather"], 6, "羽", [
        ("羽", "hane", "bulu/sayap"),
        ("羽田", "Haneda", "Bandara Haneda"),
        ("一羽", "ichiwa", "satu ekor (burung)"),
    ], [
        ("鳥の羽が落ちました。", "Tori no hane ga ochimashita.", "Bulu burung jatuh."),
        ("羽田空港に着きました。", "Haneda kuukou ni tsukimashita.", "Saya tiba di Bandara Haneda."),
    ]),
    ("ko3_n2", "固", ["コ"], ["かた-い", "かた-める"], ["keras", "padat", "solid"], 8, "囗", [
        ("固い", "katai", "keras"),
        ("固定", "kotei", "tetap/fixed"),
        ("固まる", "katamaru", "mengeras"),
    ], [
        ("このパンは固いです。", "Kono pan wa katai desu.", "Roti ini keras."),
        ("カメラを固定しました。", "Kamera o kotei shimashita.", "Saya memasang kamera secara tetap."),
    ]),
    ("soku_n2", "則", ["ソク"], [], ["aturan", "rule"], 9, "刀", [
        ("規則", "kisoku", "peraturan"),
        ("原則", "gensoku", "prinsip"),
        ("法則", "housoku", "hukum/aturan"),
    ], [
        ("規則を守りましょう。", "Kisoku o mamorimashou.", "Mari kita patuhi peraturan."),
        ("これは原則です。", "Kore wa gensoku desu.", "Ini adalah prinsip."),
    ]),
    ("ran_n2", "乱", ["ラン"], ["みだ-れる", "みだ-す"], ["kekacauan", "disorder"], 7, "乙", [
        ("混乱", "konran", "kebingungan/kekacauan"),
        ("乱れる", "midareru", "menjadi kacau"),
        ("反乱", "hanran", "pemberontakan"),
    ], [
        ("交通が混乱しています。", "Koutsuu ga konran shite imasu.", "Lalu lintas kacau."),
        ("髪が乱れています。", "Kami ga midarete imasu.", "Rambutnya berantakan."),
    ]),
    ("fu2_n2", "普", ["フ"], [], ["umum", "general"], 12, "日", [
        ("普通", "futsuu", "biasa/umum"),
        ("普段", "fudan", "biasanya/sehari-hari"),
        ("普及", "fukyuu", "penyebaran/popularisasi"),
    ], [
        ("普通の日です。", "Futsuu no hi desu.", "Ini hari biasa."),
        ("普段は電車で通勤します。", "Fudan wa densha de tsuukin shimasu.", "Biasanya saya berangkat kerja dengan kereta."),
    ]),
    ("soku2_n2", "測", ["ソク"], ["はか-る"], ["mengukur", "measure"], 12, "水", [
        ("測定", "sokutei", "pengukuran"),
        ("予測", "yosoku", "prediksi"),
        ("観測", "kansoku", "pengamatan"),
    ], [
        ("温度を測定しました。", "Ondo o sokutei shimashita.", "Saya mengukur suhu."),
        ("天気を予測します。", "Tenki o yosoku shimasu.", "Memprediksi cuaca."),
    ]),
    ("hou_n2", "豊", ["ホウ"], ["ゆた-か"], ["berlimpah", "subur", "abundant"], 13, "豆", [
        ("豊か", "yutaka", "berlimpah/makmur"),
        ("豊富", "houfu", "melimpah"),
        ("豊作", "housaku", "panen berlimpah"),
    ], [
        ("自然が豊かです。", "Shizen ga yutaka desu.", "Alamnya melimpah."),
        ("経験が豊富です。", "Keiken ga houfu desu.", "Pengalamannya melimpah."),
    ]),
    ("kou4_n2", "厚", ["コウ"], ["あつ-い"], ["tebal", "thick"], 9, "厂", [
        ("厚い", "atsui", "tebal"),
        ("厚生労働省", "kouseiroudoushou", "Kementerian Kesehatan dan Tenaga Kerja"),
        ("温厚", "onkou", "ramah/berhati lembut"),
    ], [
        ("厚い本を読みました。", "Atsui hon o yomimashita.", "Saya membaca buku yang tebal."),
        ("彼は温厚な人です。", "Kare wa onkou na hito desu.", "Dia orang yang ramah."),
    ]),
    ("rei_n2", "齢", ["レイ"], [], ["usia", "age"], 17, "歯", [
        ("年齢", "nenrei", "usia"),
        ("高齢者", "koureisha", "lansia"),
        ("適齢期", "tekireiki", "usia yang tepat"),
    ], [
        ("年齢を教えてください。", "Nenrei o oshiete kudasai.", "Tolong beri tahu usia Anda."),
        ("高齢者が増えています。", "Koureisha ga fuete imasu.", "Jumlah lansia meningkat."),
    ]),
    ("i3_n2", "囲", ["イ"], ["かこ-む", "かこ-う"], ["mengelilingi", "surround"], 7, "囗", [
        ("周囲", "shuui", "sekeliling"),
        ("範囲", "han'i", "cakupan/jangkauan"),
        ("囲む", "kakomu", "mengelilingi"),
    ], [
        ("範囲を確認してください。", "Han'i o kakunin shite kudasai.", "Tolong periksa cakupannya."),
        ("家族に囲まれています。", "Kazoku ni kakomarete imasu.", "Saya dikelilingi keluarga."),
    ]),
    ("sotsu_n2", "卒", ["ソツ"], [], ["lulus", "graduate"], 8, "十", [
        ("卒業", "sotsugyou", "kelulusan"),
        ("卒業式", "sotsugyoushiki", "upacara kelulusan"),
        ("新卒", "shinsotsu", "lulusan baru"),
    ], [
        ("来年卒業します。", "Rainen sotsugyou shimasu.", "Tahun depan saya lulus."),
        ("卒業式に出席しました。", "Sotsugyoushiki ni shusseki shimashita.", "Saya menghadiri upacara kelulusan."),
    ]),
    ("ryaku_n2", "略", ["リャク"], [], ["menyingkat", "menghilangkan", "abbreviate"], 11, "田", [
        ("省略", "shouryaku", "penyingkatan"),
        ("略語", "ryakugo", "singkatan"),
        ("戦略", "senryaku", "strategi"),
    ], [
        ("略語を使いました。", "Ryakugo o tsukaimashita.", "Saya menggunakan singkatan."),
        ("新しい戦略を考えました。", "Atarashii senryaku o kangaemashita.", "Saya memikirkan strategi baru."),
    ]),
    ("shou6_n2", "承", ["ショウ"], ["うけたまわ-る"], ["menyetujui", "mewarisi", "consent"], 8, "手", [
        ("承知", "shouchi", "memahami/menyetujui"),
        ("了承", "ryoushou", "persetujuan"),
        ("承認", "shounin", "persetujuan resmi"),
    ], [
        ("承知しました。", "Shouchi shimashita.", "Saya mengerti/setuju."),
        ("計画が承認されました。", "Keikaku ga shounin saremashita.", "Rencana telah disetujui."),
    ]),
    ("jun2_n2", "順", ["ジュン"], [], ["urutan", "order/sequence"], 12, "頁", [
        ("順番", "junban", "giliran/urutan"),
        ("手順", "tejun", "prosedur"),
        ("順調", "junchou", "lancar"),
    ], [
        ("順番を待ってください。", "Junban o matte kudasai.", "Tolong tunggu giliran Anda."),
        ("仕事は順調です。", "Shigoto wa junchou desu.", "Pekerjaan berjalan lancar."),
    ]),
    ("gan4_n2", "岩", ["ガン"], ["いわ"], ["batu karang", "rock"], 8, "山", [
        ("岩", "iwa", "batu karang"),
        ("岩石", "ganseki", "batuan"),
        ("溶岩", "yougan", "lava"),
    ], [
        ("大きい岩がありました。", "Ookii iwa ga arimashita.", "Ada batu besar."),
        ("溶岩が流れています。", "Yougan ga nagarete imasu.", "Lava mengalir."),
    ]),
    ("ren_n2", "練", ["レン"], ["ね-る"], ["berlatih", "practice"], 14, "糸", [
        ("練習", "renshuu", "latihan"),
        ("訓練", "kunren", "pelatihan"),
        ("洗練", "senren", "kecanggihan"),
    ], [
        ("毎日練習しています。", "Mainichi renshuu shite imasu.", "Saya berlatih setiap hari."),
        ("訓練を受けました。", "Kunren o ukemashita.", "Saya menerima pelatihan."),
    ]),
    ("ryou4_n2", "了", ["リョウ"], [], ["selesai", "memahami", "complete"], 2, "亅", [
        ("終了", "shuuryou", "selesai"),
        ("了解", "ryoukai", "mengerti/paham"),
        ("完了", "kanryou", "selesai/tuntas"),
    ], [
        ("会議が終了しました。", "Kaigi ga shuuryou shimashita.", "Rapat telah selesai."),
        ("了解しました。", "Ryoukai shimashita.", "Saya mengerti."),
    ]),
    ("chou2_n2", "庁", ["チョウ"], [], ["kantor pemerintah", "government office"], 5, "广", [
        ("県庁", "kenchou", "kantor prefektur"),
        ("気象庁", "kishouchou", "Badan Meteorologi"),
        ("警視庁", "keishichou", "Kepolisian Metropolitan Tokyo"),
    ], [
        ("気象庁が発表しました。", "Kishouchou ga happyou shimashita.", "Badan Meteorologi mengumumkan."),
        ("警視庁に行きました。", "Keishichou ni ikimashita.", "Saya pergi ke Kepolisian Metropolitan Tokyo."),
    ]),
    ("jou_n2", "城", ["ジョウ"], ["しろ"], ["kastil", "istana", "castle"], 9, "土", [
        ("城", "shiro", "kastil"),
        ("大阪城", "Oosakajou", "Kastil Osaka"),
        ("城下町", "joukamachi", "kota di sekitar kastil"),
    ], [
        ("大阪城を見学しました。", "Oosakajou o kengaku shimashita.", "Saya mengunjungi Kastil Osaka."),
        ("美しい城がありました。", "Utsukushii shiro ga arimashita.", "Ada kastil yang indah."),
    ]),
    ("kan3_n2", "患", ["カン"], ["わずら-う"], ["menderita (penyakit)", "suffer"], 11, "心", [
        ("患者", "kanja", "pasien"),
        ("疾患", "shikkan", "penyakit"),
        ("患う", "wazurau", "menderita sakit"),
    ], [
        ("患者が病院にいます。", "Kanja ga byouin ni imasu.", "Pasien ada di rumah sakit."),
        ("心臓の疾患があります。", "Shinzou no shikkan ga arimasu.", "Ada penyakit jantung."),
    ]),
    ("sou4_n2", "層", ["ソウ"], [], ["lapisan", "layer"], 14, "尸", [
        ("層", "sou", "lapisan"),
        ("若年層", "jakunensou", "kalangan muda"),
        ("高層ビル", "kousou biru", "gedung bertingkat tinggi"),
    ], [
        ("高層ビルが建ちました。", "Kousou biru ga tachimashita.", "Gedung bertingkat tinggi dibangun."),
        ("若年層に人気があります。", "Jakunensou ni ninki ga arimasu.", "Populer di kalangan muda."),
    ]),
    ("han3_n2", "版", ["ハン"], [], ["edisi", "cetakan", "edition"], 8, "片", [
        ("出版", "shuppan", "penerbitan"),
        ("版画", "hanga", "seni cetak"),
        ("初版", "shohan", "edisi pertama"),
    ], [
        ("本を出版しました。", "Hon o shuppan shimashita.", "Saya menerbitkan buku."),
        ("版画を作りました。", "Hanga o tsukurimashita.", "Saya membuat seni cetak."),
    ]),
    ("rei2_n2", "令", ["レイ"], [], ["perintah", "order"], 5, "人", [
        ("命令", "meirei", "perintah"),
        ("法令", "hourei", "undang-undang"),
        ("令和", "Reiwa", "era Reiwa"),
    ], [
        ("命令に従いました。", "Meirei ni shitagaimashita.", "Saya mematuhi perintah."),
        ("令和時代に生まれました。", "Reiwa jidai ni umaremashita.", "Saya lahir di era Reiwa."),
    ]),
    ("kaku3_n2", "角", ["カク"], ["かど", "つの"], ["sudut", "tanduk", "angle"], 7, "角", [
        ("三角形", "sankakkei", "segitiga"),
        ("角", "kado", "sudut/pojok"),
        ("曲がり角", "magarikado", "tikungan"),
    ], [
        ("三角形を描きました。", "Sankakkei o kakimashita.", "Saya menggambar segitiga."),
        ("曲がり角で待っています。", "Magarikado de matte imasu.", "Saya menunggu di tikungan."),
    ]),
    ("raku_n2", "絡", ["ラク"], ["から-む"], ["melibatkan", "kontak", "entangle"], 12, "糸", [
        ("連絡", "renraku", "kontak/komunikasi"),
        ("絡む", "karamu", "terjerat/terlibat"),
        ("絡み合う", "karamiau", "saling terjalin"),
    ], [
        ("連絡してください。", "Renraku shite kudasai.", "Tolong hubungi saya."),
        ("糸が絡んでいます。", "Ito ga karande imasu.", "Benangnya kusut."),
    ]),
    ("son_n2", "損", ["ソン"], ["そこ-なう"], ["kerugian", "kerusakan", "loss"], 13, "手", [
        ("損害", "songai", "kerugian"),
        ("損する", "sonsuru", "merugi"),
        ("破損", "hason", "kerusakan"),
    ], [
        ("損害を受けました。", "Songai o ukemashita.", "Kami mengalami kerugian."),
        ("商品が破損しています。", "Shouhin ga hason shite imasu.", "Produknya rusak."),
    ]),
    ("bo_n2", "募", ["ボ"], ["つの-る"], ["merekrut", "mengumpulkan", "recruit"], 12, "力", [
        ("募集", "boshuu", "perekrutan"),
        ("応募", "oubo", "melamar/mendaftar"),
        ("募金", "bokin", "penggalangan dana"),
    ], [
        ("新入社員を募集しています。", "Shinnyuu shain o boshuu shite imasu.", "Kami merekrut karyawan baru."),
        ("そのイベントに応募しました。", "Sono ibento ni oubo shimashita.", "Saya mendaftar untuk acara itu."),
    ]),
    ("ri_n2", "裏", ["リ"], ["うら"], ["bagian belakang", "back"], 13, "衣", [
        ("裏", "ura", "bagian belakang"),
        ("裏庭", "uraniwa", "halaman belakang"),
        ("裏切る", "uragiru", "mengkhianati"),
    ], [
        ("裏庭で遊びました。", "Uraniwa de asobimashita.", "Saya bermain di halaman belakang."),
        ("紙の裏に書きました。", "Kami no ura ni kakimashita.", "Saya menulis di bagian belakang kertas."),
    ]),
    ("butsu_n2", "仏", ["ブツ"], ["ほとけ"], ["Buddha"], 4, "人", [
        ("仏教", "bukkyou", "agama Buddha"),
        ("大仏", "daibutsu", "patung Buddha besar"),
        ("仏様", "hotoke-sama", "Buddha"),
    ], [
        ("仏教を勉強しています。", "Bukkyou o benkyou shite imasu.", "Saya belajar agama Buddha."),
        ("大仏を見に行きました。", "Daibutsu o mi ni ikimashita.", "Saya pergi melihat patung Buddha besar."),
    ]),
    ("seki_n2", "績", ["セキ"], [], ["prestasi", "achievement"], 17, "糸", [
        ("成績", "seiseki", "nilai/prestasi"),
        ("業績", "gyouseki", "kinerja/prestasi bisnis"),
        ("実績", "jisseki", "rekam jejak"),
    ], [
        ("成績が良かったです。", "Seiseki ga yokatta desu.", "Nilainya bagus."),
        ("会社の業績が伸びました。", "Kaisha no gyouseki ga nobimashita.", "Kinerja perusahaan meningkat."),
    ]),
    ("chiku2_n2", "築", ["チク"], ["きず-く"], ["membangun", "build"], 16, "竹", [
        ("建築", "kenchiku", "arsitektur"),
        ("築く", "kizuku", "membangun"),
        ("新築", "shinchiku", "bangunan baru"),
    ], [
        ("建築家になりたいです。", "Kenchikuka ni naritai desu.", "Saya ingin menjadi arsitek."),
        ("新築の家を買いました。", "Shinchiku no ie o kaimashita.", "Saya membeli rumah baru."),
    ]),
    ("ka3_n2", "貨", ["カ"], [], ["barang", "mata uang", "goods"], 11, "貝", [
        ("貨物", "kamotsu", "kargo"),
        ("通貨", "tsuuka", "mata uang"),
        ("硬貨", "kouka", "koin"),
    ], [
        ("貨物列車が通りました。", "Kamotsu ressha ga toorimashita.", "Kereta kargo lewat."),
        ("通貨を両替しました。", "Tsuuka o ryougae shimashita.", "Saya menukar mata uang."),
    ]),
    ("kon2_n2", "混", ["コン"], ["ま-じる", "ま-ぜる"], ["mencampur", "mix"], 11, "水", [
        ("混雑", "konzatsu", "keramaian/kepadatan"),
        ("混ぜる", "mazeru", "mencampur"),
        ("混乱", "konran", "kekacauan"),
    ], [
        ("電車が混雑しています。", "Densha ga konzatsu shite imasu.", "Keretanya penuh sesak."),
        ("材料を混ぜてください。", "Zairyou o mazete kudasai.", "Tolong campurkan bahan-bahannya."),
    ]),
    ("shou7_n2", "昇", ["ショウ"], ["のぼ-る"], ["naik", "rise"], 8, "日", [
        ("上昇", "joushou", "kenaikan"),
        ("昇進", "shoushin", "promosi"),
        ("昇る", "noboru", "naik/terbit"),
    ], [
        ("気温が上昇しています。", "Kion ga joushou shite imasu.", "Suhu naik."),
        ("彼は昇進しました。", "Kare wa shoushin shimashita.", "Dia dipromosikan."),
    ]),
    ("chi_n2", "池", ["チ"], ["いけ"], ["kolam", "pond"], 6, "水", [
        ("池", "ike", "kolam"),
        ("電池", "denchi", "baterai"),
        ("貯水池", "chosuichi", "waduk"),
    ], [
        ("池で魚を見ました。", "Ike de sakana o mimashita.", "Saya melihat ikan di kolam."),
        ("電池を交換しました。", "Denchi o koukan shimashita.", "Saya mengganti baterai."),
    ]),
    ("ketsu2_n2", "血", ["ケツ"], ["ち"], ["darah", "blood"], 6, "血", [
        ("血液", "ketsueki", "darah"),
        ("血", "chi", "darah"),
        ("出血", "shukketsu", "pendarahan"),
    ], [
        ("血液検査をしました。", "Ketsueki kensa o shimashita.", "Saya melakukan tes darah."),
        ("手から血が出ています。", "Te kara chi ga dete imasu.", "Darah keluar dari tangan."),
    ]),
    ("on_n2", "温", ["オン"], ["あたた-かい", "あたた-める"], ["hangat", "warm"], 12, "水", [
        ("温度", "ondo", "suhu"),
        ("温泉", "onsen", "sumber air panas"),
        ("気温", "kion", "suhu udara"),
    ], [
        ("温泉に入りました。", "Onsen ni hairimashita.", "Saya berendam di sumber air panas."),
        ("気温が高いです。", "Kion ga takai desu.", "Suhu udaranya tinggi."),
    ]),
    ("ki_n2", "季", ["キ"], [], ["musim", "season"], 8, "子", [
        ("季節", "kisetsu", "musim"),
        ("四季", "shiki", "empat musim"),
        ("季刊", "kikan", "terbitan musiman"),
    ], [
        ("日本には四季があります。", "Nihon ni wa shiki ga arimasu.", "Jepang memiliki empat musim."),
        ("季節が変わりました。", "Kisetsu ga kawarimashita.", "Musimnya berganti."),
    ]),
    ("sei3_n2", "星", ["セイ"], ["ほし"], ["bintang", "star"], 9, "日", [
        ("星", "hoshi", "bintang"),
        ("火星", "kasei", "planet Mars"),
        ("星座", "seiza", "rasi bintang"),
    ], [
        ("星がきれいです。", "Hoshi ga kirei desu.", "Bintangnya indah."),
        ("火星について学びました。", "Kasei ni tsuite manabimashita.", "Saya belajar tentang Mars."),
    ]),
    ("ei2_n2", "永", ["エイ"], ["なが-い"], ["abadi", "kekal", "eternal"], 5, "水", [
        ("永遠", "eien", "keabadian"),
        ("永久", "eikyuu", "abadi/kekal"),
        ("永住", "eijuu", "tinggal permanen"),
    ], [
        ("永遠の愛を誓いました。", "Eien no ai o chikaimashita.", "Saya bersumpah cinta abadi."),
        ("日本に永住しています。", "Nihon ni eijuu shite imasu.", "Saya tinggal permanen di Jepang."),
    ]),
    ("cho_n2", "著", ["チョ"], ["いちじる-しい", "あらわ-す"], ["menulis", "terkenal", "notable"], 11, "艸", [
        ("著者", "chosha", "penulis"),
        ("著しい", "ichijirushii", "mencolok/luar biasa"),
        ("著書", "chosho", "karya tulis"),
    ], [
        ("この本の著者は有名です。", "Kono hon no chosha wa yuumei desu.", "Penulis buku ini terkenal."),
        ("著しい進歩がありました。", "Ichijirushii shinpo ga arimashita.", "Ada kemajuan yang mencolok."),
    ]),
    ("shi2_n2", "誌", ["シ"], [], ["majalah", "jurnal", "journal"], 14, "言", [
        ("雑誌", "zasshi", "majalah"),
        ("日誌", "nisshi", "catatan harian/logbook"),
        ("誌上", "shijou", "dalam majalah/publikasi"),
    ], [
        ("雑誌を読んでいます。", "Zasshi o yonde imasu.", "Saya membaca majalah."),
        ("日誌をつけています。", "Nisshi o tsukete imasu.", "Saya menulis catatan harian."),
    ]),
    ("ko4_n2", "庫", ["コ"], [], ["gudang", "storehouse"], 10, "广", [
        ("倉庫", "souko", "gudang"),
        ("冷蔵庫", "reizouko", "kulkas"),
        ("車庫", "shako", "garasi mobil"),
    ], [
        ("倉庫に荷物があります。", "Souko ni nimotsu ga arimasu.", "Ada barang di gudang."),
        ("車庫に車を止めました。", "Shako ni kuruma o tomemashita.", "Saya memarkir mobil di garasi."),
    ]),
    ("kan4_n2", "刊", ["カン"], [], ["menerbitkan", "publish"], 5, "刀", [
        ("刊行", "kankou", "penerbitan"),
        ("週刊誌", "shuukanshi", "majalah mingguan"),
        ("月刊", "gekkan", "bulanan (terbitan)"),
    ], [
        ("新しい本が刊行されました。", "Atarashii hon ga kankou saremashita.", "Buku baru diterbitkan."),
        ("週刊誌を買いました。", "Shuukanshi o kaimashita.", "Saya membeli majalah mingguan."),
    ]),
    ("zou3_n2", "像", ["ゾウ"], [], ["gambaran", "patung", "statue"], 14, "人", [
        ("想像", "souzou", "imajinasi"),
        ("映像", "eizou", "gambar/rekaman video"),
        ("銅像", "douzou", "patung perunggu"),
    ], [
        ("想像してみてください。", "Souzou shite mite kudasai.", "Coba bayangkan."),
        ("映像がきれいです。", "Eizou ga kirei desu.", "Rekamannya bagus."),
    ]),
    ("kou5_n2", "香", ["コウ", "キョウ"], ["かお-り", "かお-る"], ["aroma", "wangi", "fragrance"], 9, "香", [
        ("香り", "kaori", "aroma"),
        ("香水", "kousui", "parfum"),
        ("線香", "senkou", "dupa"),
    ], [
        ("いい香りがします。", "Ii kaori ga shimasu.", "Aromanya enak."),
        ("香水をつけました。", "Kousui o tsukemashita.", "Saya memakai parfum."),
    ]),
    ("han4_n2", "坂", ["ハン"], ["さか"], ["lereng", "tanjakan", "slope"], 7, "土", [
        ("坂", "saka", "lereng"),
        ("坂道", "sakamichi", "jalan menanjak"),
        ("下り坂", "kudarizaka", "jalan menurun"),
    ], [
        ("坂道を上りました。", "Sakamichi o noborimashita.", "Saya mendaki jalan menanjak."),
        ("下り坂で自転車が速くなりました。", "Kudarizaka de jitensha ga hayaku narimashita.", "Sepeda menjadi cepat di jalan menurun."),
    ]),
    ("tei3_n2", "底", ["テイ"], ["そこ"], ["dasar", "bawah", "bottom"], 8, "广", [
        ("底", "soko", "dasar"),
        ("徹底", "tettei", "menyeluruh/tuntas"),
        ("海底", "kaitei", "dasar laut"),
    ], [
        ("靴の底が破れました。", "Kutsu no soko ga yaburemashita.", "Alas sepatunya robek."),
        ("海底を探検しました。", "Kaitei o tanken shimashita.", "Saya menjelajahi dasar laut."),
    ]),
    ("fu3_n2", "布", ["フ"], ["ぬの"], ["kain", "cloth"], 5, "巾", [
        ("布", "nuno", "kain"),
        ("財布", "saifu", "dompet"),
        ("毛布", "moufu", "selimut"),
    ], [
        ("財布を忘れました。", "Saifu o wasuremashita.", "Saya lupa membawa dompet."),
        ("毛布を使いました。", "Moufu o tsukaimashita.", "Saya menggunakan selimut."),
    ]),
    ("ji2_n2", "寺", ["ジ"], ["てら"], ["kuil (Buddha)", "temple"], 6, "寸", [
        ("寺", "tera", "kuil"),
        ("お寺", "o-tera", "kuil"),
        ("寺院", "jiin", "kuil/wihara"),
    ], [
        ("お寺に行きました。", "O-tera ni ikimashita.", "Saya pergi ke kuil."),
        ("古い寺院を訪ねました。", "Furui jiin o tazunemashita.", "Saya mengunjungi kuil tua."),
    ]),
    ("u2_n2", "宇", ["ウ"], [], ["alam semesta", "universe"], 6, "宀", [
        ("宇宙", "uchuu", "alam semesta"),
        ("宇宙人", "uchuujin", "alien"),
        ("宇宙船", "uchuusen", "pesawat luar angkasa"),
    ], [
        ("宇宙について興味があります。", "Uchuu ni tsuite kyoumi ga arimasu.", "Saya tertarik dengan alam semesta."),
        ("宇宙船を見ました。", "Uchuusen o mimashita.", "Saya melihat pesawat luar angkasa."),
    ]),
    ("kyo_n2", "巨", ["キョ"], [], ["raksasa", "besar", "giant"], 5, "工", [
        ("巨大", "kyodai", "sangat besar"),
        ("巨人", "kyojin", "raksasa"),
        ("巨額", "kyogaku", "jumlah besar"),
    ], [
        ("巨大なビルです。", "Kyodai na biru desu.", "Itu gedung yang sangat besar."),
        ("巨額の資金が必要です。", "Kyogaku no shikin ga hitsuyou desu.", "Diperlukan dana dalam jumlah besar."),
    ]),
    ("shin3_n2", "震", ["シン"], ["ふる-える"], ["gempa", "gemetar", "earthquake"], 15, "雨", [
        ("地震", "jishin", "gempa bumi"),
        ("震える", "furueru", "gemetar"),
        ("震度", "shindo", "skala intensitas gempa"),
    ], [
        ("地震がありました。", "Jishin ga arimashita.", "Ada gempa bumi."),
        ("寒さで震えています。", "Samusa de furuete imasu.", "Menggigil karena dingin."),
    ]),
    ("ki2_n2", "希", ["キ"], [], ["harapan", "langka", "hope"], 7, "巾", [
        ("希望", "kibou", "harapan"),
        ("希少", "kishou", "langka"),
        ("希薄", "kihaku", "tipis/encer"),
    ], [
        ("希望を持ちましょう。", "Kibou o mochimashou.", "Mari kita punya harapan."),
        ("これは希少な本です。", "Kore wa kishou na hon desu.", "Ini buku langka."),
    ]),
    ("shoku2_n2", "触", ["ショク"], ["さわ-る", "ふ-れる"], ["menyentuh", "touch"], 13, "角", [
        ("接触", "sesshoku", "kontak/persentuhan"),
        ("触る", "sawaru", "menyentuh"),
        ("触れる", "fureru", "menyentuh/menyinggung"),
    ], [
        ("商品に触らないでください。", "Shouhin ni sawaranaide kudasai.", "Jangan menyentuh barang dagangan."),
        ("人と接触しました。", "Hito to sesshoku shimashita.", "Saya melakukan kontak dengan orang."),
    ]),
    ("i4_n2", "依", ["イ", "エ"], [], ["bergantung", "depend"], 8, "人", [
        ("依頼", "irai", "permintaan"),
        ("依然として", "izen toshite", "masih tetap"),
        ("依存", "izon", "ketergantungan"),
    ], [
        ("仕事を依頼しました。", "Shigoto o irai shimashita.", "Saya meminta pekerjaan."),
        ("スマホに依存しています。", "Sumaho ni izon shite imasu.", "Saya bergantung pada smartphone."),
    ]),
    ("seki2_n2", "籍", ["セキ"], [], ["pendaftaran", "kewarganegaraan", "register"], 20, "竹", [
        ("国籍", "kokuseki", "kewarganegaraan"),
        ("戸籍", "koseki", "akta keluarga/catatan sipil"),
        ("書籍", "shoseki", "buku/publikasi"),
    ], [
        ("国籍を教えてください。", "Kokuseki o oshiete kudasai.", "Tolong beri tahu kewarganegaraan Anda."),
        ("書籍を購入しました。", "Shoseki o kounyuu shimashita.", "Saya membeli buku."),
    ]),
    ("o_n2", "汚", ["オ"], ["きたな-い", "よご-す", "よご-れる"], ["kotor", "dirty"], 6, "水", [
        ("汚い", "kitanai", "kotor"),
        ("汚染", "osen", "polusi"),
        ("汚れる", "yogoreru", "menjadi kotor"),
    ], [
        ("部屋が汚いです。", "Heya ga kitanai desu.", "Kamarnya kotor."),
        ("川が汚染されています。", "Kawa ga osen sarete imasu.", "Sungainya tercemar."),
    ]),
    ("mai_n2", "枚", ["マイ"], [], ["kata bantu bilangan (benda datar)", "counter"], 8, "木", [
        ("一枚", "ichimai", "satu lembar"),
        ("枚数", "maisuu", "jumlah lembar"),
        ("何枚", "nanmai", "berapa lembar"),
    ], [
        ("紙を一枚ください。", "Kami o ichimai kudasai.", "Tolong berikan satu lembar kertas."),
        ("何枚必要ですか。", "Nanmai hitsuyou desu ka.", "Berapa lembar yang dibutuhkan?"),
    ]),
    ("fuku4_n2", "複", ["フク"], [], ["ganda", "majemuk", "duplicate"], 14, "衣", [
        ("複数", "fukusuu", "jamak/beberapa"),
        ("複雑", "fukuzatsu", "rumit"),
        ("複製", "fukusei", "duplikat/replika"),
    ], [
        ("複数の意見がありました。", "Fukusuu no iken ga arimashita.", "Ada beberapa pendapat."),
        ("この問題は複雑です。", "Kono mondai wa fukuzatsu desu.", "Masalah ini rumit."),
    ]),
    ("yuu_n2", "郵", ["ユウ"], [], ["pos", "surat", "mail"], 11, "邑", [
        ("郵便", "yuubin", "pos"),
        ("郵便局", "yuubinkyoku", "kantor pos"),
        ("郵便番号", "yuubin bangou", "kode pos"),
    ], [
        ("郵便局に行きました。", "Yuubinkyoku ni ikimashita.", "Saya pergi ke kantor pos."),
        ("郵便番号を書いてください。", "Yuubin bangou o kaite kudasai.", "Tolong tulis kode pos."),
    ]),
    ("chuu_n2", "仲", ["チュウ"], ["なか"], ["hubungan", "di antara", "relationship"], 6, "人", [
        ("仲間", "nakama", "teman/rekan"),
        ("仲良し", "nakayoshi", "akrab"),
        ("仲介", "chuukai", "perantara"),
    ], [
        ("仲間と一緒に行きました。", "Nakama to issho ni ikimashita.", "Saya pergi bersama teman-teman."),
        ("彼らは仲良しです。", "Karera wa nakayoshi desu.", "Mereka akrab."),
    ]),
    ("ei3_n2", "栄", ["エイ"], ["さか-える", "は-え"], ["kemakmuran", "kejayaan", "prosper"], 9, "木", [
        ("栄養", "eiyou", "nutrisi"),
        ("繁栄", "han'ei", "kemakmuran"),
        ("光栄", "kouei", "kehormatan"),
    ], [
        ("栄養のバランスが大切です。", "Eiyou no baransu ga taisetsu desu.", "Keseimbangan nutrisi itu penting."),
        ("お会いできて光栄です。", "O-ai dekite kouei desu.", "Suatu kehormatan bisa bertemu Anda."),
    ]),
    ("satsu_n2", "札", ["サツ"], ["ふだ"], ["uang kertas", "label", "bill"], 5, "木", [
        ("千円札", "sen'en satsu", "uang kertas 1000 yen"),
        ("名札", "nafuda", "label nama"),
        ("表札", "hyousatsu", "papan nama rumah"),
    ], [
        ("千円札を出しました。", "Sen'en satsu o dashimashita.", "Saya mengeluarkan uang kertas 1000 yen."),
        ("名札をつけてください。", "Nafuda o tsukete kudasai.", "Tolong pakai label nama."),
    ]),
    ("han5_n2", "板", ["ハン", "バン"], ["いた"], ["papan", "board"], 8, "木", [
        ("黒板", "kokuban", "papan tulis"),
        ("板", "ita", "papan"),
        ("看板", "kanban", "papan reklame/tanda"),
    ], [
        ("黒板に書いてください。", "Kokuban ni kaite kudasai.", "Tolong tulis di papan tulis."),
        ("看板を見ました。", "Kanban o mimashita.", "Saya melihat papan reklame."),
    ]),
    ("kotsu_n2", "骨", ["コツ"], ["ほね"], ["tulang", "bone"], 10, "骨", [
        ("骨", "hone", "tulang"),
        ("骨折", "kossetsu", "patah tulang"),
        ("骨組み", "honegumi", "kerangka/struktur"),
    ], [
        ("骨を折りました。", "Hone o orimashita.", "Saya patah tulang."),
        ("骨折で入院しました。", "Kossetsu de nyuuin shimashita.", "Saya dirawat di rumah sakit karena patah tulang."),
    ]),
    ("kei2_n2", "傾", ["ケイ"], ["かたむ-く", "かたむ-ける"], ["miring", "condong", "incline"], 13, "人", [
        ("傾向", "keikou", "kecenderungan"),
        ("傾く", "katamuku", "miring"),
        ("傾ける", "katamukeru", "memiringkan"),
    ], [
        ("最近の傾向です。", "Saikin no keikou desu.", "Ini kecenderungan terkini."),
        ("塔が傾いています。", "Tou ga katamuite imasu.", "Menaranya miring."),
    ]),
    ("todoke_n2", "届", [], ["とど-く", "とど-ける"], ["sampai", "mengantarkan", "reach"], 8, "尸", [
        ("届く", "todoku", "sampai/terjangkau"),
        ("届ける", "todokeru", "mengantarkan"),
        ("届け出", "todokede", "laporan/pemberitahuan resmi"),
    ], [
        ("荷物が届きました。", "Nimotsu ga todokimashita.", "Paket sudah sampai."),
        ("手紙を届けました。", "Tegami o todokemashita.", "Saya mengantarkan surat."),
    ]),
    ("kan5_n2", "巻", ["カン"], ["ま-く", "まき"], ["jilid", "menggulung", "roll"], 9, "己", [
        ("巻く", "maku", "menggulung"),
        ("第一巻", "daiikkan", "jilid pertama"),
        ("巻き込む", "makikomu", "melibatkan/menyeret"),
    ], [
        ("包帯を巻きました。", "Houtai o makimashita.", "Saya membalut perban."),
        ("第一巻を読みました。", "Daiikkan o yomimashita.", "Saya membaca jilid pertama."),
    ]),
    ("nen_n2", "燃", ["ネン"], ["も-える", "も-やす"], ["terbakar", "burn"], 16, "火", [
        ("燃える", "moeru", "terbakar"),
        ("燃料", "nenryou", "bahan bakar"),
        ("燃やす", "moyasu", "membakar"),
    ], [
        ("火が燃えています。", "Hi ga moete imasu.", "Api sedang menyala."),
        ("燃料を入れました。", "Nenryou o iremashita.", "Saya mengisi bahan bakar."),
    ]),
    ("seki3_n2", "跡", ["セキ"], ["あと"], ["jejak", "bekas", "trace"], 13, "足", [
        ("跡", "ato", "jejak/bekas"),
        ("遺跡", "iseki", "situs bersejarah/reruntuhan"),
        ("足跡", "ashiato", "jejak kaki"),
    ], [
        ("遺跡を見学しました。", "Iseki o kengaku shimashita.", "Saya mengunjungi situs bersejarah."),
        ("足跡が残っています。", "Ashiato ga nokotte imasu.", "Jejak kaki masih tersisa."),
    ]),
    ("hou2_n2", "包", ["ホウ"], ["つつ-む"], ["membungkus", "wrap"], 5, "勹", [
        ("包む", "tsutsumu", "membungkus"),
        ("包装", "housou", "pembungkusan"),
        ("包丁", "houchou", "pisau dapur"),
    ], [
        ("プレゼントを包みました。", "Purezento o tsutsumimashita.", "Saya membungkus hadiah."),
        ("包丁で野菜を切りました。", "Houchou de yasai o kirimashita.", "Saya memotong sayuran dengan pisau dapur."),
    ]),
    ("chuu2_n2", "駐", ["チュウ"], [], ["berhenti", "parkir", "park"], 15, "馬", [
        ("駐車", "chuusha", "parkir"),
        ("駐車場", "chuushajou", "tempat parkir"),
        ("駐在", "chuuzai", "ditugaskan/berkedudukan"),
    ], [
        ("ここに駐車しないでください。", "Koko ni chuusha shinaide kudasai.", "Jangan parkir di sini."),
        ("駐車場を探しています。", "Chuushajou o sagashite imasu.", "Saya mencari tempat parkir."),
    ]),
    ("shou8_n2", "紹", ["ショウ"], [], ["memperkenalkan", "introduce"], 11, "糸", [
        ("自己紹介", "jikoshoukai", "perkenalan diri"),
        ("紹介状", "shoukaijou", "surat pengantar/rekomendasi"),
        ("紹介", "shoukai", "perkenalan"),
    ], [
        ("自己紹介をしました。", "Jikoshoukai o shimashita.", "Saya memperkenalkan diri."),
        ("紹介状を書いてもらいました。", "Shoukaijou o kaite moraimashita.", "Saya diberi surat pengantar."),
    ]),
    ("ko5_n2", "雇", ["コ"], ["やと-う"], ["mempekerjakan", "employ"], 12, "隹", [
        ("雇用", "koyou", "ketenagakerjaan"),
        ("雇う", "yatou", "mempekerjakan"),
        ("解雇", "kaiko", "pemecatan"),
    ], [
        ("新しい社員を雇いました。", "Atarashii shain o yatoimashita.", "Kami mempekerjakan karyawan baru."),
        ("雇用が増えています。", "Koyou ga fuete imasu.", "Lapangan kerja meningkat."),
    ]),
    ("tai2_n2", "替", ["タイ"], ["か-える", "か-わる"], ["menggantikan", "menukar", "exchange"], 12, "日", [
        ("両替", "ryougae", "penukaran uang"),
        ("着替える", "kigaeru", "berganti pakaian"),
        ("為替", "kawase", "nilai tukar/wesel"),
    ], [
        ("両替をしたいです。", "Ryougae o shitai desu.", "Saya ingin menukar uang."),
        ("服を着替えました。", "Fuku o kigaemashita.", "Saya berganti pakaian."),
    ]),
    ("yo_n2", "預", ["ヨ"], ["あず-ける", "あず-かる"], ["menitipkan", "menyimpan (uang)", "deposit"], 13, "頁", [
        ("預金", "yokin", "tabungan"),
        ("預ける", "azukeru", "menitipkan"),
        ("預かる", "azukaru", "menerima titipan"),
    ], [
        ("銀行に預金しています。", "Ginkou ni yokin shite imasu.", "Saya menabung di bank."),
        ("荷物を預けました。", "Nimotsu o azukemashita.", "Saya menitipkan barang."),
    ]),
    ("shou9_n2", "焼", ["ショウ"], ["や-く", "や-ける"], ["membakar", "memanggang", "burn"], 12, "火", [
        ("焼く", "yaku", "membakar/memanggang"),
        ("焼肉", "yakiniku", "daging panggang"),
        ("全焼", "zenshou", "terbakar habis"),
    ], [
        ("肉を焼きました。", "Niku o yakimashita.", "Saya memanggang daging."),
        ("焼肉を食べに行きましょう。", "Yakiniku o tabe ni ikimashou.", "Ayo pergi makan yakiniku."),
    ]),
    ("kan6_n2", "簡", ["カン"], [], ["sederhana", "simple"], 18, "竹", [
        ("簡単", "kantan", "sederhana/mudah"),
        ("簡単に", "kantan ni", "dengan mudah"),
        ("簡略化", "kanryakuka", "penyederhanaan"),
    ], [
        ("この料理は簡単です。", "Kono ryouri wa kantan desu.", "Masakan ini sederhana."),
        ("簡単に説明します。", "Kantan ni setsumei shimasu.", "Saya akan jelaskan dengan mudah."),
    ]),
    ("shou10_n2", "章", ["ショウ"], [], ["bab", "lambang", "chapter"], 11, "立", [
        ("第一章", "daiisshou", "bab pertama"),
        ("文章", "bunshou", "karangan/kalimat"),
        ("校章", "koushou", "lambang sekolah"),
    ], [
        ("第一章を読みました。", "Daiisshou o yomimashita.", "Saya membaca bab pertama."),
        ("文章を書きました。", "Bunshou o kakimashita.", "Saya menulis karangan."),
    ]),
    ("zou4_n2", "臓", ["ゾウ"], [], ["organ dalam", "internal organ"], 19, "肉", [
        ("心臓", "shinzou", "jantung"),
        ("内臓", "naizou", "organ dalam"),
        ("肝臓", "kanzou", "hati/liver"),
    ], [
        ("心臓がドキドキしています。", "Shinzou ga dokidoki shite imasu.", "Jantung berdebar-debar."),
        ("肝臓の検査をしました。", "Kanzou no kensa o shimashita.", "Saya melakukan pemeriksaan hati."),
    ]),
    ("ritsu_n2", "律", ["リツ"], [], ["hukum", "ritme", "law"], 9, "彳", [
        ("法律", "houritsu", "hukum"),
        ("規律", "kiritsu", "disiplin/aturan"),
        ("自律", "jiritsu", "otonomi diri"),
    ], [
        ("法律を守りましょう。", "Houritsu o mamorimashou.", "Mari kita patuhi hukum."),
        ("規律を大切にしています。", "Kiritsu o taisetsu ni shite imasu.", "Saya menghargai disiplin."),
    ]),
    ("zou5_n2", "贈", ["ゾウ"], ["おく-る"], ["menghadiahkan", "gift"], 18, "貝", [
        ("贈り物", "okurimono", "hadiah"),
        ("贈る", "okuru", "menghadiahkan"),
        ("寄贈", "kizou", "donasi/sumbangan"),
    ], [
        ("贈り物をもらいました。", "Okurimono o moraimashita.", "Saya menerima hadiah."),
        ("本を寄贈しました。", "Hon o kizou shimashita.", "Saya menyumbangkan buku."),
    ]),
    ("shou11_n2", "照", ["ショウ"], ["て-る", "て-らす"], ["menyinari", "illuminate"], 13, "火", [
        ("照明", "shoumei", "pencahayaan"),
        ("対照", "taishou", "kontras/perbandingan"),
        ("照れる", "tereru", "malu-malu"),
    ], [
        ("照明をつけてください。", "Shoumei o tsukete kudasai.", "Tolong nyalakan lampu."),
        ("彼は照れています。", "Kare wa terete imasu.", "Dia malu-malu."),
    ]),
    ("haku_n2", "薄", ["ハク"], ["うす-い"], ["tipis", "thin"], 16, "艸", [
        ("薄い", "usui", "tipis"),
        ("薄暗い", "usugurai", "remang-remang"),
        ("薄着", "usugi", "pakaian tipis"),
    ], [
        ("この本は薄いです。", "Kono hon wa usui desu.", "Buku ini tipis."),
        ("薄暗い部屋です。", "Usugurai heya desu.", "Ruangan yang remang-remang."),
    ]),
    ("gun2_n2", "群", ["グン"], ["む-れる", "むら"], ["kelompok", "kerumunan", "group"], 13, "羊", [
        ("群れ", "mure", "kawanan"),
        ("群衆", "gunshuu", "kerumunan"),
        ("大群", "taigun", "kawanan besar"),
    ], [
        ("鳥の群れを見ました。", "Tori no mure o mimashita.", "Saya melihat kawanan burung."),
        ("群衆が集まりました。", "Gunshuu ga atsumarimashita.", "Kerumunan berkumpul."),
    ]),
    ("byou_n2", "秒", ["ビョウ"], [], ["detik", "second"], 9, "禾", [
        ("秒", "byou", "detik"),
        ("一秒", "ichibyou", "satu detik"),
        ("秒速", "byousoku", "kecepatan per detik"),
    ], [
        ("十秒待ってください。", "Juubyou matte kudasai.", "Tolong tunggu sepuluh detik."),
        ("秒速で計算します。", "Byousoku de keisan shimasu.", "Menghitung dengan kecepatan per detik."),
    ]),
    ("ou4_n2", "奥", ["オウ"], ["おく"], ["bagian dalam", "interior"], 12, "大", [
        ("奥", "oku", "bagian dalam"),
        ("奥さん", "okusan", "istri (orang lain)"),
        ("山奥", "yamaoku", "pedalaman gunung"),
    ], [
        ("部屋の奥に座ってください。", "Heya no oku ni suwatte kudasai.", "Tolong duduk di bagian dalam ruangan."),
        ("山奥に住んでいます。", "Yamaoku ni sunde imasu.", "Saya tinggal di pedalaman gunung."),
    ]),
    ("kitsu_n2", "詰", ["キツ"], ["つ-める", "つ-まる"], ["mengemas", "memadatkan", "pack"], 13, "言", [
        ("詰める", "tsumeru", "mengemas/memadatkan"),
        ("缶詰", "kanzume", "makanan kaleng"),
        ("詰まる", "tsumaru", "tersumbat"),
    ], [
        ("荷物を詰めました。", "Nimotsu o tsumemashita.", "Saya mengemas barang."),
        ("缶詰を買いました。", "Kanzume o kaimashita.", "Saya membeli makanan kaleng."),
    ]),
    ("sou5_n2", "双", ["ソウ"], [], ["pasangan", "kembar", "pair"], 4, "又", [
        ("双子", "futago", "anak kembar"),
        ("双方", "souhou", "kedua belah pihak"),
        ("双眼鏡", "sougankyou", "teropong"),
    ], [
        ("双子が生まれました。", "Futago ga umaremashita.", "Anak kembar lahir."),
        ("双方の意見を聞きました。", "Souhou no iken o kikimashita.", "Saya mendengar pendapat kedua belah pihak."),
    ]),
    ("shi3_n2", "刺", ["シ"], ["さ-す"], ["menusuk", "stab"], 8, "刀", [
        ("刺す", "sasu", "menusuk"),
        ("名刺", "meishi", "kartu nama"),
        ("刺激", "shigeki", "stimulasi/rangsangan"),
    ], [
        ("蚊に刺されました。", "Ka ni sasaremashita.", "Saya digigit nyamuk."),
        ("名刺をください。", "Meishi o kudasai.", "Tolong berikan kartu nama Anda."),
    ]),
    ("jun3_n2", "純", ["ジュン"], [], ["murni", "pure"], 10, "糸", [
        ("純粋", "junsui", "murni"),
        ("単純", "tanjun", "sederhana"),
        ("純白", "junpaku", "putih murni"),
    ], [
        ("純粋な気持ちです。", "Junsui na kimochi desu.", "Ini perasaan yang murni."),
        ("単純な問題です。", "Tanjun na mondai desu.", "Ini masalah yang sederhana."),
    ]),
    ("yoku_n2", "翌", ["ヨク"], [], ["berikutnya", "the following"], 11, "羽", [
        ("翌日", "yokujitsu", "hari berikutnya"),
        ("翌年", "yokunen", "tahun berikutnya"),
        ("翌朝", "yokuasa", "pagi berikutnya"),
    ], [
        ("翌日出発しました。", "Yokujitsu shuppatsu shimashita.", "Saya berangkat pada hari berikutnya."),
        ("翌年また来ます。", "Yokunen mata kimasu.", "Saya akan datang lagi tahun berikutnya."),
    ]),
    ("kai4_n2", "快", ["カイ"], ["こころよ-い"], ["menyenangkan", "pleasant"], 7, "心", [
        ("快適", "kaiteki", "nyaman"),
        ("快晴", "kaisei", "cuaca cerah"),
        ("全快", "zenkai", "sembuh total"),
    ], [
        ("快適な部屋です。", "Kaiteki na heya desu.", "Ini kamar yang nyaman."),
        ("今日は快晴です。", "Kyou wa kaisei desu.", "Hari ini cuacanya cerah."),
    ]),
    ("hen3_n2", "片", ["ヘン"], ["かた"], ["sepotong", "sebelah", "fragment"], 4, "片", [
        ("片方", "katahou", "salah satu sisi"),
        ("片付ける", "katazukeru", "membereskan"),
        ("破片", "hahen", "pecahan"),
    ], [
        ("片方の靴がありません。", "Katahou no kutsu ga arimasen.", "Sebelah sepatunya tidak ada."),
        ("部屋を片付けました。", "Heya o katazukemashita.", "Saya membereskan kamar."),
    ]),
    ("kei3_n2", "敬", ["ケイ"], ["うやま-う"], ["menghormati", "respect"], 12, "攴", [
        ("尊敬", "sonkei", "menghormati"),
        ("敬語", "keigo", "bahasa hormat"),
        ("敬意", "keii", "rasa hormat"),
    ], [
        ("先生を尊敬しています。", "Sensei o sonkei shite imasu.", "Saya menghormati guru."),
        ("敬語を勉強しています。", "Keigo o benkyou shite imasu.", "Saya belajar bahasa hormat."),
    ]),
    ("nou3_n2", "悩", ["ノウ"], ["なや-む", "なや-ます"], ["khawatir", "bermasalah", "worry"], 10, "心", [
        ("悩む", "nayamu", "khawatir/bimbang"),
        ("悩み", "nayami", "kekhawatiran/masalah"),
        ("苦悩", "kunou", "penderitaan"),
    ], [
        ("将来について悩んでいます。", "Shourai ni tsuite nayande imasu.", "Saya khawatir tentang masa depan."),
        ("悩みを相談しました。", "Nayami o soudan shimashita.", "Saya berkonsultasi tentang masalah saya."),
    ]),
    ("sen4_n2", "泉", ["セン"], ["いずみ"], ["mata air", "spring"], 9, "水", [
        ("温泉", "onsen", "sumber air panas"),
        ("泉", "izumi", "mata air"),
        ("源泉", "gensen", "sumber"),
    ], [
        ("泉が湧いています。", "Izumi ga waite imasu.", "Mata air memancar."),
        ("源泉を訪ねました。", "Gensen o tazunemashita.", "Saya mengunjungi sumbernya."),
    ]),
    ("hi3_n2", "皮", ["ヒ"], ["かわ"], ["kulit", "skin"], 5, "皮", [
        ("皮", "kawa", "kulit"),
        ("皮膚", "hifu", "kulit tubuh"),
        ("毛皮", "kegawa", "bulu binatang"),
    ], [
        ("りんごの皮をむきました。", "Ringo no kawa o mukimashita.", "Saya mengupas kulit apel."),
        ("皮膚科に行きました。", "Hifuka ni ikimashita.", "Saya pergi ke dokter kulit."),
    ]),
    ("gyo_n2", "漁", ["ギョ", "リョウ"], [], ["memancing", "menangkap ikan", "fishing"], 14, "水", [
        ("漁業", "gyogyou", "industri perikanan"),
        ("漁師", "ryoushi", "nelayan"),
        ("漁港", "gyokou", "pelabuhan perikanan"),
    ], [
        ("漁業が盛んです。", "Gyogyou ga sakan desu.", "Industri perikanan berkembang pesat."),
        ("彼は漁師です。", "Kare wa ryoushi desu.", "Dia adalah nelayan."),
    ]),
    ("kou6_n2", "荒", ["コウ"], ["あら-い", "あ-れる"], ["kasar", "liar", "rough"], 9, "艸", [
        ("荒い", "arai", "kasar"),
        ("荒れる", "areru", "menjadi kasar/rusak"),
        ("荒野", "kouya", "padang gurun/belantara"),
    ], [
        ("波が荒いです。", "Nami ga arai desu.", "Ombaknya ganas."),
        ("天気が荒れています。", "Tenki ga arete imasu.", "Cuacanya buruk."),
    ]),
    ("cho2_n2", "貯", ["チョ"], [], ["menyimpan", "save"], 12, "貝", [
        ("貯金", "chokin", "tabungan"),
        ("貯蔵", "chozou", "penyimpanan"),
        ("貯水池", "chosuichi", "waduk"),
    ], [
        ("毎月貯金しています。", "Maitsuki chokin shite imasu.", "Saya menabung setiap bulan."),
        ("貯金が増えました。", "Chokin ga fuemashita.", "Tabungan saya bertambah."),
    ]),
    ("kou7_n2", "硬", ["コウ"], ["かた-い"], ["keras (fisik)", "hard"], 12, "石", [
        ("硬い", "katai", "keras"),
        ("硬貨", "kouka", "koin"),
        ("硬直", "kouchoku", "kaku"),
    ], [
        ("この石は硬いです。", "Kono ishi wa katai desu.", "Batu ini keras."),
        ("硬貨を入れてください。", "Kouka o irete kudasai.", "Tolong masukkan koin."),
    ]),
    ("mai2_n2", "埋", ["マイ"], ["う-める", "う-まる"], ["mengubur", "menimbun", "bury"], 10, "土", [
        ("埋める", "umeru", "mengubur/mengisi"),
        ("埋まる", "umaru", "terkubur/terisi"),
        ("埋め立て", "umetate", "reklamasi"),
    ], [
        ("宝物を埋めました。", "Takaramono o umemashita.", "Saya mengubur harta karun."),
        ("穴が埋まりました。", "Ana ga umarimashita.", "Lubangnya sudah tertutup."),
    ]),
    ("chuu3_n2", "柱", ["チュウ"], ["はしら"], ["tiang", "pillar"], 9, "木", [
        ("柱", "hashira", "tiang"),
        ("電柱", "denchuu", "tiang listrik"),
        ("大黒柱", "daikokubashira", "tiang utama/tulang punggung keluarga"),
    ], [
        ("柱にもたれました。", "Hashira ni motaremashita.", "Saya bersandar di tiang."),
        ("電柱が倒れました。", "Denchuu ga taoremashita.", "Tiang listrik roboh."),
    ]),
    ("sai3_n2", "祭", ["サイ"], ["まつ-り"], ["festival"], 11, "示", [
        ("祭り", "matsuri", "festival"),
        ("文化祭", "bunkasai", "festival budaya"),
        ("祭日", "saijitsu", "hari libur nasional"),
    ], [
        ("夏祭りに行きました。", "Natsu matsuri ni ikimashita.", "Saya pergi ke festival musim panas."),
        ("文化祭が楽しかったです。", "Bunkasai ga tanoshikatta desu.", "Festival budaya menyenangkan."),
    ]),
    ("tai3_n2", "袋", ["タイ"], ["ふくろ"], ["kantong", "bag"], 11, "衣", [
        ("袋", "fukuro", "kantong"),
        ("手袋", "tebukuro", "sarung tangan"),
        ("紙袋", "kamibukuro", "kantong kertas"),
    ], [
        ("袋に入れてください。", "Fukuro ni irete kudasai.", "Tolong masukkan ke dalam kantong."),
        ("手袋をしました。", "Tebukuro o shimashita.", "Saya memakai sarung tangan."),
    ]),
    ("hitsu_n2", "筆", ["ヒツ"], ["ふで"], ["kuas tulis", "pena", "brush"], 12, "竹", [
        ("筆", "fude", "kuas tulis"),
        ("鉛筆", "enpitsu", "pensil"),
        ("筆記", "hikki", "tulisan/pencatatan"),
    ], [
        ("筆で書きました。", "Fude de kakimashita.", "Saya menulis dengan kuas."),
        ("鉛筆を貸してください。", "Enpitsu o kashite kudasai.", "Tolong pinjamkan pensil."),
    ]),
    ("kun_n2", "訓", ["クン"], [], ["petunjuk", "bacaan (kun)", "instruction"], 10, "言", [
        ("訓練", "kunren", "pelatihan"),
        ("教訓", "kyoukun", "pelajaran hidup"),
        ("訓読み", "kunyomi", "bacaan kun"),
    ], [
        ("教訓を得ました。", "Kyoukun o emashita.", "Saya mendapat pelajaran hidup."),
        ("訓読みを覚えました。", "Kunyomi o oboemashita.", "Saya menghafal bacaan kun."),
    ]),
    ("yoku2_n2", "浴", ["ヨク"], ["あ-びる"], ["mandi", "bathe"], 10, "水", [
        ("浴びる", "abiru", "mandi/menyiram"),
        ("入浴", "nyuuyoku", "mandi"),
        ("浴衣", "yukata", "yukata"),
    ], [
        ("シャワーを浴びました。", "Shawaa o abimashita.", "Saya mandi shower."),
        ("浴衣を着ました。", "Yukata o kimashita.", "Saya memakai yukata."),
    ]),
    ("dou2_n2", "童", ["ドウ"], ["わらべ"], ["anak-anak", "child"], 12, "立", [
        ("童話", "douwa", "dongeng anak"),
        ("児童", "jidou", "anak-anak"),
        ("童謡", "douyou", "lagu anak"),
    ], [
        ("童話を読みました。", "Douwa o yomimashita.", "Saya membaca dongeng anak."),
        ("童謡を歌いました。", "Douyou o utaimashita.", "Saya menyanyikan lagu anak."),
    ]),
    ("hou3_n2", "宝", ["ホウ"], ["たから"], ["harta karun", "treasure"], 8, "宀", [
        ("宝物", "takaramono", "harta karun"),
        ("宝石", "houseki", "permata"),
        ("国宝", "kokuhou", "harta nasional"),
    ], [
        ("宝物を見つけました。", "Takaramono o mitsukemashita.", "Saya menemukan harta karun."),
        ("宝石を買いました。", "Houseki o kaimashita.", "Saya membeli permata."),
    ]),
    ("fuu_n2", "封", ["フウ", "ホウ"], [], ["menyegel", "seal"], 9, "寸", [
        ("封筒", "fuutou", "amplop"),
        ("封印", "fuuin", "penyegelan"),
        ("封鎖", "fuusa", "penutupan/blokade"),
    ], [
        ("封筒に手紙を入れました。", "Fuutou ni tegami o iremashita.", "Saya memasukkan surat ke dalam amplop."),
        ("道路が封鎖されました。", "Douro ga fuusa saremashita.", "Jalan ditutup."),
    ]),
    ("kyou6_n2", "胸", ["キョウ"], ["むね"], ["dada", "chest"], 10, "肉", [
        ("胸", "mune", "dada"),
        ("胸元", "munamoto", "bagian atas dada"),
        ("度胸", "dokyou", "keberanian"),
    ], [
        ("胸が痛いです。", "Mune ga itai desu.", "Dadanya sakit."),
        ("度胸がありますね。", "Dokyou ga arimasu ne.", "Kamu berani ya."),
    ]),
    ("sha_n2", "砂", ["サ", "シャ"], ["すな"], ["pasir", "sand"], 9, "石", [
        ("砂", "suna", "pasir"),
        ("砂漠", "sabaku", "gurun"),
        ("砂糖", "satou", "gula"),
    ], [
        ("砂浜を歩きました。", "Sunahama o arukimashita.", "Saya berjalan di pantai berpasir."),
        ("砂糖を入れますか。", "Satou o iremasu ka.", "Apakah mau ditambahkan gula?"),
    ]),
    ("en2_n2", "塩", ["エン"], ["しお"], ["garam", "salt"], 13, "土", [
        ("塩", "shio", "garam"),
        ("塩分", "enbun", "kadar garam"),
        ("食塩", "shokuen", "garam dapur"),
    ], [
        ("塩を入れました。", "Shio o iremashita.", "Saya menambahkan garam."),
        ("塩分を控えています。", "Enbun o hikaete imasu.", "Saya membatasi kadar garam."),
    ]),
    ("ken3_n2", "賢", ["ケン"], ["かしこ-い"], ["bijaksana", "wise"], 16, "貝", [
        ("賢い", "kashikoi", "pintar/bijaksana"),
        ("賢明", "kenmei", "bijaksana"),
        ("賢者", "kenja", "orang bijak"),
    ], [
        ("彼は賢い子供です。", "Kare wa kashikoi kodomo desu.", "Dia anak yang pintar."),
        ("賢明な判断です。", "Kenmei na handan desu.", "Itu keputusan yang bijaksana."),
    ]),
    ("wan2_n2", "腕", ["ワン"], ["うで"], ["lengan", "arm"], 12, "肉", [
        ("腕", "ude", "lengan"),
        ("腕時計", "udedokei", "jam tangan"),
        ("腕前", "udemae", "keterampilan"),
    ], [
        ("腕が痛いです。", "Ude ga itai desu.", "Lengannya sakit."),
        ("腕時計をつけています。", "Udedokei o tsukete imasu.", "Saya memakai jam tangan."),
    ]),
    ("chou3_n2", "兆", ["チョウ"], ["きざ-し"], ["pertanda", "triliun", "sign"], 6, "儿", [
        ("兆候", "choukou", "tanda/gejala"),
        ("予兆", "yochou", "firasat"),
        ("一兆", "icchou", "satu triliun"),
    ], [
        ("病気の兆候があります。", "Byouki no choukou ga arimasu.", "Ada tanda-tanda penyakit."),
        ("一兆円の予算です。", "Icchouen no yosan desu.", "Anggarannya satu triliun yen."),
    ]),
    ("shou12_n2", "床", ["ショウ"], ["とこ", "ゆか"], ["lantai", "floor"], 7, "广", [
        ("床", "yuka", "lantai"),
        ("床屋", "tokoya", "tukang cukur"),
        ("起床", "kishou", "bangun tidur"),
    ], [
        ("床を掃除しました。", "Yuka o souji shimashita.", "Saya membersihkan lantai."),
        ("6時に起床します。", "Rokuji ni kishou shimasu.", "Saya bangun tidur jam 6."),
    ]),
    ("mou_n2", "毛", ["モウ"], ["け"], ["rambut", "bulu", "hair"], 4, "毛", [
        ("毛", "ke", "rambut/bulu"),
        ("毛布", "moufu", "selimut"),
        ("毛糸", "keito", "benang wol"),
    ], [
        ("猫の毛が抜けています。", "Neko no ke ga nukete imasu.", "Bulu kucing rontok."),
        ("毛糸で編みました。", "Keito de amimashita.", "Saya merajut dengan benang wol."),
    ]),
    ("ryoku_n2", "緑", ["リョク"], ["みどり"], ["hijau", "green"], 14, "糸", [
        ("緑", "midori", "hijau"),
        ("緑茶", "ryokucha", "teh hijau"),
        ("新緑", "shinryoku", "dedaunan hijau segar"),
    ], [
        ("緑茶を飲みました。", "Ryokucha o nomimashita.", "Saya minum teh hijau."),
        ("山が緑です。", "Yama ga midori desu.", "Gunungnya hijau."),
    ]),
    ("son2_n2", "尊", ["ソン"], ["とうと-い", "たっと-い"], ["menghormati", "mulia", "revere"], 12, "寸", [
        ("尊敬", "sonkei", "menghormati"),
        ("尊重", "sonchou", "menghargai"),
        ("自尊心", "jisonshin", "harga diri"),
    ], [
        ("意見を尊重します。", "Iken o sonchou shimasu.", "Saya menghargai pendapat."),
        ("自尊心が高いです。", "Jisonshin ga takai desu.", "Harga dirinya tinggi."),
    ]),
    ("shuku_n2", "祝", ["シュク"], ["いわ-う"], ["merayakan", "celebrate"], 9, "示", [
        ("祝う", "iwau", "merayakan"),
        ("祝日", "shukujitsu", "hari libur nasional"),
        ("祝賀", "shukuga", "perayaan"),
    ], [
        ("誕生日を祝いました。", "Tanjoubi o iwaimashita.", "Saya merayakan ulang tahun."),
        ("明日は祝日です。", "Ashita wa shukujitsu desu.", "Besok adalah hari libur nasional."),
    ]),
    ("juu_n2", "柔", ["ジュウ"], ["やわ-らかい"], ["lembut", "soft"], 9, "木", [
        ("柔らかい", "yawarakai", "lembut"),
        ("柔道", "juudou", "judo"),
        ("柔軟", "juunan", "fleksibel"),
    ], [
        ("このパンは柔らかいです。", "Kono pan wa yawarakai desu.", "Roti ini lembut."),
        ("柔道を習っています。", "Juudou o naratte imasu.", "Saya belajar judo."),
    ]),
    ("den_n2", "殿", ["デン"], ["との"], ["istana", "gelar hormat", "palace"], 13, "殳", [
        ("御殿", "goten", "istana"),
        ("殿様", "tonosama", "tuan feodal"),
        ("殿方", "tonogata", "tuan-tuan (formal)"),
    ], [
        ("御殿を見学しました。", "Goten o kengaku shimashita.", "Saya mengunjungi istana."),
        ("殿様の時代でした。", "Tonosama no jidai deshita.", "Itu adalah era para tuan feodal."),
    ]),
    ("nou4_n2", "濃", ["ノウ"], ["こ-い"], ["pekat", "thick"], 16, "水", [
        ("濃い", "koi", "pekat/kental"),
        ("濃度", "noudo", "konsentrasi"),
        ("濃厚", "noukou", "kental/pekat"),
    ], [
        ("このコーヒーは濃いです。", "Kono koohii wa koi desu.", "Kopi ini pekat."),
        ("濃度を測りました。", "Noudo o hakarimashita.", "Saya mengukur konsentrasinya."),
    ]),
    ("eki_n2", "液", ["エキ"], [], ["cairan", "liquid"], 11, "水", [
        ("液体", "ekitai", "cairan"),
        ("血液", "ketsueki", "darah"),
        ("液晶", "ekishou", "LCD/kristal cair"),
    ], [
        ("液体を混ぜました。", "Ekitai o mazemashita.", "Saya mencampur cairan."),
        ("液晶テレビを買いました。", "Ekishou terebi o kaimashita.", "Saya membeli TV LCD."),
    ]),
    ("i5_n2", "衣", ["イ"], ["ころも"], ["pakaian", "clothing"], 6, "衣", [
        ("衣服", "ifuku", "pakaian"),
        ("衣装", "ishou", "kostum"),
        ("衣類", "irui", "pakaian/busana"),
    ], [
        ("衣服を洗濯しました。", "Ifuku o sentaku shimashita.", "Saya mencuci pakaian."),
        ("衣類を整理しました。", "Irui o seiri shimashita.", "Saya merapikan pakaian."),
    ]),
    ("ken4_n2", "肩", ["ケン"], ["かた"], ["bahu", "shoulder"], 8, "肉", [
        ("肩", "kata", "bahu"),
        ("肩こり", "katakori", "pegal bahu"),
        ("肩幅", "katahaba", "lebar bahu"),
    ], [
        ("肩が痛いです。", "Kata ga itai desu.", "Bahunya sakit."),
        ("肩こりがひどいです。", "Katakori ga hidoi desu.", "Pegal bahunya parah."),
    ]),
    ("rei3_n2", "零", ["レイ"], [], ["nol", "zero"], 13, "雨", [
        ("零度", "reido", "nol derajat"),
        ("零点", "reiten", "nol poin"),
        ("零細企業", "reisai kigyou", "usaha kecil"),
    ], [
        ("気温は零度です。", "Kion wa reido desu.", "Suhunya nol derajat."),
        ("零細企業を経営しています。", "Reisai kigyou o keiei shite imasu.", "Saya mengelola usaha kecil."),
    ]),
    ("you_n2", "幼", ["ヨウ"], ["おさな-い"], ["muda", "kanak-kanak", "young"], 5, "幺", [
        ("幼稚園", "youchien", "taman kanak-kanak"),
        ("幼児", "youji", "balita"),
        ("幼い", "osanai", "masih kecil/kekanak-kanakan"),
    ], [
        ("幼稚園に通っています。", "Youchien ni kayotte imasu.", "Saya bersekolah di TK."),
        ("幼い頃を思い出しました。", "Osanai koro o omoidashimashita.", "Saya teringat masa kecil."),
    ]),
    ("ka4_n2", "荷", ["カ"], ["に"], ["muatan", "beban", "load"], 10, "艸", [
        ("荷物", "nimotsu", "barang bawaan"),
        ("荷", "ni", "muatan"),
        ("出荷", "shukka", "pengiriman"),
    ], [
        ("荷物を運びました。", "Nimotsu o hakobimashita.", "Saya membawa barang."),
        ("商品を出荷しました。", "Shouhin o shukka shimashita.", "Kami mengirimkan produk."),
    ]),
    ("haku2_n2", "泊", ["ハク"], ["と-まる", "と-める"], ["menginap", "stay overnight"], 8, "水", [
        ("宿泊", "shukuhaku", "menginap"),
        ("一泊", "ippaku", "satu malam"),
        ("泊まる", "tomaru", "menginap"),
    ], [
        ("ホテルに宿泊しました。", "Hoteru ni shukuhaku shimashita.", "Saya menginap di hotel."),
        ("一泊二日の旅行です。", "Ippaku futsuka no ryokou desu.", "Perjalanan dua hari satu malam."),
    ]),
    ("kou8_n2", "黄", ["コウ", "オウ"], ["き"], ["kuning", "yellow"], 11, "黄", [
        ("黄色", "kiiro", "warna kuning"),
        ("黄金", "ougon", "emas"),
        ("卵黄", "ran'ou", "kuning telur"),
    ], [
        ("黄色い花です。", "Kiiroi hana desu.", "Bunga berwarna kuning."),
        ("黄金の像です。", "Ougon no zou desu.", "Itu patung emas."),
    ]),
    ("kan7_n2", "甘", ["カン"], ["あま-い"], ["manis", "sweet"], 5, "甘", [
        ("甘い", "amai", "manis"),
        ("甘やかす", "amayakasu", "memanjakan"),
        ("甘口", "amakuchi", "rasa manis/ringan"),
    ], [
        ("このケーキは甘いです。", "Kono keeki wa amai desu.", "Kue ini manis."),
        ("子供を甘やかさないでください。", "Kodomo o amayakasanaide kudasai.", "Jangan memanjakan anak."),
    ]),
    ("shin4_n2", "臣", ["シン", "ジン"], [], ["pejabat", "abdi", "retainer"], 7, "臣", [
        ("大臣", "daijin", "menteri"),
        ("家臣", "kashin", "pengikut/vasal"),
        ("臣民", "shinmin", "rakyat (kekaisaran)"),
    ], [
        ("総理大臣が話しました。", "Souri daijin ga hanashimashita.", "Perdana menteri berbicara."),
        ("大臣に任命されました。", "Daijin ni ninmei saremashita.", "Ditunjuk sebagai menteri."),
    ]),
    ("sou6_n2", "掃", ["ソウ"], ["は-く"], ["menyapu", "sweep"], 11, "手", [
        ("掃除", "souji", "membersihkan"),
        ("掃除機", "soujiki", "penyedot debu"),
        ("一掃", "issou", "membersihkan total"),
    ], [
        ("部屋を掃除しました。", "Heya o souji shimashita.", "Saya membersihkan kamar."),
        ("掃除機を使いました。", "Soujiki o tsukaimashita.", "Saya menggunakan penyedot debu."),
    ]),
    ("un_n2", "雲", ["ウン"], ["くも"], ["awan", "cloud"], 12, "雨", [
        ("雲", "kumo", "awan"),
        ("雨雲", "amagumo", "awan hujan"),
        ("雲海", "unkai", "lautan awan"),
    ], [
        ("空に雲があります。", "Sora ni kumo ga arimasu.", "Ada awan di langit."),
        ("雨雲が近づいています。", "Amagumo ga chikazuite imasu.", "Awan hujan mendekat."),
    ]),
    ("kutsu_n2", "掘", ["クツ"], ["ほ-る"], ["menggali", "dig"], 11, "手", [
        ("掘る", "horu", "menggali"),
        ("発掘", "hakkutsu", "penggalian/ekskavasi"),
        ("採掘", "saikutsu", "penambangan"),
    ], [
        ("穴を掘りました。", "Ana o horimashita.", "Saya menggali lubang."),
        ("遺跡を発掘しています。", "Iseki o hakkutsu shite imasu.", "Mereka menggali situs bersejarah."),
    ]),
    ("sha2_n2", "捨", ["シャ"], ["す-てる"], ["membuang", "discard"], 11, "手", [
        ("捨てる", "suteru", "membuang"),
        ("見捨てる", "misuteru", "meninggalkan/mengabaikan"),
        ("取捨選択", "shusha sentaku", "seleksi/memilah"),
    ], [
        ("ゴミを捨てました。", "Gomi o sutemashita.", "Saya membuang sampah."),
        ("彼を見捨てないでください。", "Kare o misutenaide kudasai.", "Jangan tinggalkan dia."),
    ]),
    ("nan_n2", "軟", ["ナン"], ["やわ-らか"], ["lunak", "lentur", "soft"], 11, "車", [
        ("柔軟", "juunan", "fleksibel"),
        ("軟らかい", "yawarakai", "lunak"),
        ("軟弱", "nanjaku", "lemah"),
    ], [
        ("柔軟に対応しました。", "Juunan ni taiou shimashita.", "Kami menanggapi dengan fleksibel."),
        ("軟らかい肉です。", "Yawarakai niku desu.", "Daging yang empuk."),
    ]),
    ("chin_n2", "沈", ["チン"], ["しず-む", "しず-める"], ["tenggelam", "sink"], 7, "水", [
        ("沈む", "shizumu", "tenggelam"),
        ("沈黙", "chinmoku", "diam/keheningan"),
        ("沈没", "chinbotsu", "tenggelam (kapal)"),
    ], [
        ("太陽が沈みました。", "Taiyou ga shizumimashita.", "Matahari terbenam."),
        ("船が沈没しました。", "Fune ga chinbotsu shimashita.", "Kapal tenggelam."),
    ]),
    ("tou4_n2", "凍", ["トウ"], ["こお-る", "こご-える"], ["membeku", "freeze"], 10, "冫", [
        ("冷凍", "reitou", "pembekuan"),
        ("凍る", "kooru", "membeku"),
        ("凍結", "touketsu", "pembekuan/beku"),
    ], [
        ("肉を冷凍しました。", "Niku o reitou shimashita.", "Saya membekukan daging."),
        ("道が凍っています。", "Michi ga kootte imasu.", "Jalannya membeku/licin karena es."),
    ]),
    ("nyuu_n2", "乳", ["ニュウ"], ["ちち", "ち"], ["susu", "milk"], 8, "乙", [
        ("牛乳", "gyuunyuu", "susu sapi"),
        ("乳製品", "nyuuseihin", "produk susu"),
        ("母乳", "bonyuu", "ASI"),
    ], [
        ("牛乳を飲みました。", "Gyuunyuu o nomimashita.", "Saya minum susu."),
        ("乳製品が好きです。", "Nyuuseihin ga suki desu.", "Saya suka produk susu."),
    ]),
    ("ren2_n2", "恋", ["レン"], ["こい", "こ-う"], ["cinta (romantis)", "love"], 10, "心", [
        ("恋", "koi", "cinta"),
        ("恋人", "koibito", "kekasih"),
        ("失恋", "shitsuren", "patah hati"),
    ], [
        ("彼女に恋をしました。", "Kanojo ni koi o shimashita.", "Saya jatuh cinta padanya."),
        ("恋人と旅行しました。", "Koibito to ryokou shimashita.", "Saya bepergian dengan kekasih."),
    ]),
    ("kou9_n2", "紅", ["コウ"], ["べに", "くれない"], ["merah tua", "crimson"], 9, "糸", [
        ("紅茶", "koucha", "teh hitam"),
        ("口紅", "kuchibeni", "lipstik"),
        ("紅葉", "kouyou", "dedaunan musim gugur"),
    ], [
        ("紅茶を飲みました。", "Koucha o nomimashita.", "Saya minum teh hitam."),
        ("紅葉がきれいです。", "Kouyou ga kirei desu.", "Dedaunan musim gugurnya indah."),
    ]),
    ("kou10_n2", "郊", ["コウ"], [], ["pinggiran kota", "outskirts"], 9, "邑", [
        ("郊外", "kougai", "pinggiran kota"),
        ("近郊", "kinkou", "sekitar kota"),
        ("近郊農業", "kinkou nougyou", "pertanian pinggiran kota"),
    ], [
        ("郊外に住んでいます。", "Kougai ni sunde imasu.", "Saya tinggal di pinggiran kota."),
        ("近郊の農家を訪ねました。", "Kinkou no nouka o tazunemashita.", "Saya mengunjungi petani di sekitar kota."),
    ]),
    ("you2_n2", "腰", ["ヨウ"], ["こし"], ["pinggang", "waist"], 13, "肉", [
        ("腰", "koshi", "pinggang"),
        ("腰痛", "youtsuu", "sakit pinggang"),
        ("腰掛ける", "koshikakeru", "duduk"),
    ], [
        ("腰が痛いです。", "Koshi ga itai desu.", "Pinggangnya sakit."),
        ("椅子に腰掛けました。", "Isu ni koshikakemashita.", "Saya duduk di kursi."),
    ]),
    ("tan3_n2", "炭", ["タン"], ["すみ"], ["arang", "charcoal"], 9, "火", [
        ("炭", "sumi", "arang"),
        ("炭素", "tanso", "karbon"),
        ("木炭", "mokutan", "arang kayu"),
    ], [
        ("炭で焼きました。", "Sumi de yakimashita.", "Saya memanggang dengan arang."),
        ("炭素排出量を減らしましょう。", "Tanso haishutsuryou o herashimashou.", "Mari kurangi emisi karbon."),
    ]),
    ("you3_n2", "踊", ["ヨウ"], ["おど-る"], ["menari", "dance"], 14, "足", [
        ("踊る", "odoru", "menari"),
        ("踊り", "odori", "tarian"),
        ("盆踊り", "bon odori", "tarian Bon"),
    ], [
        ("一緒に踊りましょう。", "Issho ni odorimashou.", "Ayo menari bersama."),
        ("盆踊りに参加しました。", "Bon odori ni sanka shimashita.", "Saya berpartisipasi dalam tarian Bon."),
    ]),
    ("satsu2_n2", "冊", ["サツ"], [], ["kata bantu bilangan buku", "jilid", "volume"], 5, "冂", [
        ("一冊", "issatsu", "satu buku"),
        ("冊子", "sasshi", "buklet/pamflet"),
        ("別冊", "bessatsu", "edisi terpisah"),
    ], [
        ("本を一冊買いました。", "Hon o issatsu kaimashita.", "Saya membeli satu buku."),
        ("冊子を配りました。", "Sasshi o kubarimashita.", "Saya membagikan buklet."),
    ]),
    ("yuu2_n2", "勇", ["ユウ"], ["いさ-ましい"], ["berani", "brave"], 9, "力", [
        ("勇気", "yuuki", "keberanian"),
        ("勇敢", "yuukan", "gagah berani"),
        ("勇者", "yuusha", "pahlawan/pemberani"),
    ], [
        ("勇気を出しました。", "Yuuki o dashimashita.", "Saya memberanikan diri."),
        ("勇敢な人です。", "Yuukan na hito desu.", "Dia orang yang gagah berani."),
    ]),
    ("kai5_n2", "械", ["カイ"], [], ["mesin", "alat", "machine"], 11, "木", [
        ("機械", "kikai", "mesin"),
        ("器械", "kikai", "alat/instrumen"),
        ("機械化", "kikaika", "mekanisasi"),
    ], [
        ("機械が壊れました。", "Kikai ga kowaremashita.", "Mesinnya rusak."),
        ("工場を機械化しました。", "Koujou o kikaika shimashita.", "Kami memekanisasi pabrik."),
    ]),
    ("sai4_n2", "菜", ["サイ"], ["な"], ["sayuran", "vegetable"], 11, "艸", [
        ("野菜", "yasai", "sayuran"),
        ("菜食", "saishoku", "vegetarian"),
        ("白菜", "hakusai", "sawi putih"),
    ], [
        ("野菜を食べましょう。", "Yasai o tabemashou.", "Ayo makan sayuran."),
        ("白菜を買いました。", "Hakusai o kaimashita.", "Saya membeli sawi putih."),
    ]),
    ("chin2_n2", "珍", ["チン"], ["めずら-しい"], ["langka", "aneh", "rare"], 9, "玉", [
        ("珍しい", "mezurashii", "langka/jarang"),
        ("珍味", "chinmi", "makanan lezat langka"),
        ("珍客", "chinkyaku", "tamu tak terduga"),
    ], [
        ("これは珍しい本です。", "Kore wa mezurashii hon desu.", "Ini buku yang langka."),
        ("珍味を食べました。", "Chinmi o tabemashita.", "Saya makan makanan lezat langka."),
    ]),
    ("ran2_n2", "卵", ["ラン"], ["たまご"], ["telur", "egg"], 7, "卩", [
        ("卵", "tamago", "telur"),
        ("卵子", "ranshi", "sel telur"),
        ("産卵", "sanran", "bertelur"),
    ], [
        ("卵を買いました。", "Tamago o kaimashita.", "Saya membeli telur."),
        ("魚が産卵しました。", "Sakana ga sanran shimashita.", "Ikan bertelur."),
    ]),
    ("ko6_n2", "湖", ["コ"], ["みずうみ"], ["danau", "lake"], 12, "水", [
        ("湖", "mizuumi", "danau"),
        ("湖畔", "kohan", "tepi danau"),
        ("琵琶湖", "Biwako", "Danau Biwa"),
    ], [
        ("湖で泳ぎました。", "Mizuumi de oyogimashita.", "Saya berenang di danau."),
        ("琵琶湖を見学しました。", "Biwako o kengaku shimashita.", "Saya mengunjungi Danau Biwa."),
    ]),
    ("kitsu2_n2", "喫", ["キツ"], [], ["menghisap", "menghirup", "smoke"], 12, "口", [
        ("喫煙", "kitsuen", "merokok"),
        ("喫茶店", "kissaten", "kedai kopi"),
        ("満喫", "mankitsu", "menikmati sepenuhnya"),
    ], [
        ("喫煙は禁止です。", "Kitsuen wa kinshi desu.", "Merokok dilarang."),
        ("喫茶店でコーヒーを飲みました。", "Kissaten de koohii o nomimashita.", "Saya minum kopi di kedai kopi."),
    ]),
    ("kan8_n2", "干", ["カン"], ["ひ-る", "ほ-す"], ["kering", "mengeringkan", "dry"], 3, "干", [
        ("干す", "hosu", "menjemur"),
        ("干物", "himono", "ikan asin kering"),
        ("干ばつ", "kanbatsu", "kekeringan"),
    ], [
        ("洗濯物を干しました。", "Sentakumono o hoshimashita.", "Saya menjemur cucian."),
        ("干物を食べました。", "Himono o tabemashita.", "Saya makan ikan asin kering."),
    ]),
    ("chuu4_n2", "虫", ["チュウ"], ["むし"], ["serangga", "insect"], 6, "虫", [
        ("虫", "mushi", "serangga"),
        ("昆虫", "konchuu", "serangga (istilah biologi)"),
        ("虫歯", "mushiba", "gigi berlubang"),
    ], [
        ("虫を見つけました。", "Mushi o mitsukemashita.", "Saya menemukan serangga."),
        ("虫歯があります。", "Mushiba ga arimasu.", "Ada gigi berlubang."),
    ]),
    ("satsu3_n2", "刷", ["サツ"], ["す-る"], ["mencetak", "print"], 8, "刀", [
        ("印刷", "insatsu", "percetakan"),
        ("刷る", "suru", "mencetak"),
        ("増刷", "zousatsu", "cetak ulang"),
    ], [
        ("本を印刷しました。", "Hon o insatsu shimashita.", "Saya mencetak buku."),
        ("増刷が決まりました。", "Zousatsu ga kimarimashita.", "Cetak ulang sudah diputuskan."),
    ]),
    ("tou5_n2", "湯", ["トウ"], ["ゆ"], ["air panas", "hot water"], 12, "水", [
        ("お湯", "o-yu", "air panas"),
        ("銭湯", "sentou", "pemandian umum"),
        ("湯気", "yuge", "uap panas"),
    ], [
        ("お湯を沸かしました。", "O-yu o wakashimashita.", "Saya merebus air."),
        ("銭湯に行きました。", "Sentou ni ikimashita.", "Saya pergi ke pemandian umum."),
    ]),
    ("you4_n2", "溶", ["ヨウ"], ["と-ける", "と-かす"], ["melebur", "larut", "melt"], 13, "水", [
        ("溶ける", "tokeru", "meleleh/larut"),
        ("溶岩", "yougan", "lava"),
        ("溶接", "yousetsu", "pengelasan"),
    ], [
        ("氷が溶けました。", "Koori ga tokemashita.", "Esnya mencair."),
        ("鉄を溶接しました。", "Tetsu o yousetsu shimashita.", "Saya mengelas besi."),
    ]),
    ("kou11_n2", "鉱", ["コウ"], [], ["bijih", "mineral", "ore"], 13, "金", [
        ("鉱山", "kouzan", "tambang"),
        ("鉱物", "koubutsu", "mineral"),
        ("鉄鉱石", "tekkouseki", "bijih besi"),
    ], [
        ("鉱山で働いています。", "Kouzan de hataraite imasu.", "Saya bekerja di tambang."),
        ("鉱物を採集しました。", "Koubutsu o saishuu shimashita.", "Saya mengumpulkan mineral."),
    ]),
    ("rui_n2", "涙", ["ルイ"], ["なみだ"], ["air mata", "tear"], 10, "水", [
        ("涙", "namida", "air mata"),
        ("感涙", "kanrui", "terharu sampai menangis"),
        ("涙声", "namidagoe", "suara terisak"),
    ], [
        ("涙が出ました。", "Namida ga demashita.", "Air mata keluar."),
        ("感動して涙が出ました。", "Kandou shite namida ga demashita.", "Saya terharu sampai menangis."),
    ]),
    ("hitsu2_n2", "匹", ["ヒツ"], ["ひき"], ["kata bantu bilangan hewan kecil", "counter"], 4, "匸", [
        ("一匹", "ippiki", "satu ekor"),
        ("匹敵", "hitteki", "sebanding"),
        ("何匹", "nanbiki", "berapa ekor"),
    ], [
        ("猫が一匹います。", "Neko ga ippiki imasu.", "Ada satu ekor kucing."),
        ("犬が何匹いますか。", "Inu ga nanbiki imasu ka.", "Ada berapa ekor anjing?"),
    ]),
    ("son3_n2", "孫", ["ソン"], ["まご"], ["cucu", "grandchild"], 10, "子", [
        ("孫", "mago", "cucu"),
        ("子孫", "shison", "keturunan"),
        ("初孫", "uimago", "cucu pertama"),
    ], [
        ("孫が生まれました。", "Mago ga umaremashita.", "Cucu saya lahir."),
        ("子孫に伝えたいです。", "Shison ni tsutaetai desu.", "Saya ingin mewariskan kepada keturunan."),
    ]),
    ("ei4_n2", "鋭", ["エイ"], ["するど-い"], ["tajam", "sharp"], 15, "金", [
        ("鋭い", "surudoi", "tajam"),
        ("鋭利", "eiri", "tajam/runcing"),
        ("鋭角", "eikaku", "sudut lancip"),
    ], [
        ("鋭いナイフです。", "Surudoi naifu desu.", "Itu pisau yang tajam."),
        ("鋭い意見です。", "Surudoi iken desu.", "Itu pendapat yang tajam."),
    ]),
    ("shi4_n2", "枝", ["シ"], ["えだ"], ["cabang", "ranting", "branch"], 8, "木", [
        ("枝", "eda", "cabang/ranting"),
        ("枝分かれ", "edawakare", "percabangan"),
        ("小枝", "koeda", "ranting kecil"),
    ], [
        ("木の枝が折れました。", "Ki no eda ga oremashita.", "Ranting pohon patah."),
        ("小枝を拾いました。", "Koeda o hiroimashita.", "Saya memungut ranting kecil."),
    ]),
    ("to_n2", "塗", ["ト"], ["ぬ-る"], ["mengecat", "melapisi", "paint"], 13, "土", [
        ("塗る", "nuru", "mengecat/mengoleskan"),
        ("塗装", "tosou", "pengecatan"),
        ("塗料", "toryou", "cat"),
    ], [
        ("壁を塗りました。", "Kabe o nurimashita.", "Saya mengecat dinding."),
        ("塗料を買いました。", "Toryou o kaimashita.", "Saya membeli cat."),
    ]),
    ("ken5_n2", "軒", ["ケン"], ["のき"], ["kata bantu bilangan rumah", "eaves"], 10, "車", [
        ("一軒", "ikken", "satu rumah"),
        ("軒下", "nokishita", "di bawah atap teras"),
        ("軒並み", "nokinami", "deretan rumah"),
    ], [
        ("一軒家に住んでいます。", "Ikken'ya ni sunde imasu.", "Saya tinggal di rumah tunggal."),
        ("軒下で雨宿りしました。", "Nokishita de amayadori shimashita.", "Saya berteduh dari hujan di bawah atap teras."),
    ]),
    ("doku_n2", "毒", ["ドク"], [], ["racun", "poison"], 8, "毋", [
        ("毒", "doku", "racun"),
        ("中毒", "chuudoku", "kecanduan/keracunan"),
        ("毒蛇", "dokuhebi", "ular berbisa"),
    ], [
        ("毒を飲んではいけません。", "Doku o nonde wa ikemasen.", "Jangan meminum racun."),
        ("スマホ中毒です。", "Sumaho chuudoku desu.", "Saya kecanduan smartphone."),
    ]),
    ("kyou7_n2", "叫", ["キョウ"], ["さけ-ぶ"], ["berteriak", "shout"], 6, "口", [
        ("叫ぶ", "sakebu", "berteriak"),
        ("絶叫", "zekkyou", "teriakan keras"),
        ("叫び声", "sakebigoe", "suara teriakan"),
    ], [
        ("大きな声で叫びました。", "Ookina koe de sakebimashita.", "Saya berteriak dengan suara keras."),
        ("絶叫マシンに乗りました。", "Zekkyou mashin ni norimashita.", "Saya naik wahana yang bikin berteriak."),
    ]),
    ("hai_n2", "拝", ["ハイ"], ["おが-む"], ["sembah", "dengan hormat", "worship"], 8, "手", [
        ("拝む", "ogamu", "menyembah"),
        ("参拝", "sanpai", "sembahyang di kuil"),
        ("拝見", "haiken", "melihat (bentuk hormat)"),
    ], [
        ("神社で拝みました。", "Jinja de ogamimashita.", "Saya berdoa di kuil."),
        ("資料を拝見しました。", "Shiryou o haiken shimashita.", "Saya melihat dokumennya (dengan hormat)."),
    ]),
    ("hyou_n2", "氷", ["ヒョウ"], ["こおり"], ["es", "ice"], 5, "水", [
        ("氷", "koori", "es"),
        ("氷山", "hyouzan", "gunung es"),
        ("氷点下", "hyoutenka", "di bawah titik beku"),
    ], [
        ("氷が溶けました。", "Koori ga tokemashita.", "Esnya mencair."),
        ("氷点下になりました。", "Hyoutenka ni narimashita.", "Suhu turun di bawah titik beku."),
    ]),
    ("kan9_n2", "乾", ["カン"], ["かわ-く", "かわ-かす"], ["kering", "dry"], 11, "乙", [
        ("乾燥", "kansou", "kekeringan/pengeringan"),
        ("乾杯", "kanpai", "bersulang"),
        ("乾く", "kawaku", "mengering"),
    ], [
        ("空気が乾燥しています。", "Kuuki ga kansou shite imasu.", "Udaranya kering."),
        ("乾杯しましょう。", "Kanpai shimashou.", "Mari bersulang."),
    ]),
    ("bou4_n2", "棒", ["ボウ"], [], ["tongkat", "stick"], 12, "木", [
        ("棒", "bou", "tongkat"),
        ("泥棒", "dorobou", "pencuri"),
        ("棒グラフ", "bou gurafu", "grafik batang"),
    ], [
        ("棒で叩きました。", "Bou de tatakimashita.", "Saya memukul dengan tongkat."),
        ("泥棒に注意してください。", "Dorobou ni chuui shite kudasai.", "Waspada terhadap pencuri."),
    ]),
    ("ki3_n2", "祈", ["キ"], ["いの-る"], ["berdoa", "pray"], 8, "示", [
        ("祈る", "inoru", "berdoa"),
        ("祈り", "inori", "doa"),
        ("祈願", "kigan", "permohonan/doa"),
    ], [
        ("平和を祈ります。", "Heiwa o inorimasu.", "Saya berdoa untuk perdamaian."),
        ("合格を祈願しました。", "Goukaku o kigan shimashita.", "Saya berdoa agar lulus."),
    ]),
    ("shuu3_n2", "拾", ["シュウ"], ["ひろ-う"], ["memungut", "pick up"], 9, "手", [
        ("拾う", "hirou", "memungut"),
        ("拾得物", "shuutokubutsu", "barang temuan"),
        ("収拾", "shuushuu", "penyelesaian/pengendalian"),
    ], [
        ("ゴミを拾いました。", "Gomi o hiroimashita.", "Saya memungut sampah."),
        ("事態を収拾しました。", "Jitai o shuushuu shimashita.", "Saya mengendalikan situasi."),
    ]),
    ("fun_n2", "粉", ["フン"], ["こな", "こ"], ["tepung", "bubuk", "powder"], 10, "米", [
        ("粉", "kona", "tepung/bubuk"),
        ("小麦粉", "komugiko", "tepung terigu"),
        ("花粉", "kafun", "serbuk sari"),
    ], [
        ("小麦粉を買いました。", "Komugiko o kaimashita.", "Saya membeli tepung terigu."),
        ("花粉症です。", "Kafunshou desu.", "Saya alergi serbuk sari."),
    ]),
    ("shi5_n2", "糸", ["シ"], ["いと"], ["benang", "thread"], 6, "糸", [
        ("糸", "ito", "benang"),
        ("毛糸", "keito", "benang wol"),
        ("糸口", "itoguchi", "petunjuk/titik awal"),
    ], [
        ("糸で縫いました。", "Ito de nuimashita.", "Saya menjahit dengan benang."),
        ("解決の糸口を見つけました。", "Kaiketsu no itoguchi o mitsukemashita.", "Saya menemukan titik awal solusi."),
    ]),
    ("men_n2", "綿", ["メン"], ["わた"], ["kapas", "cotton"], 14, "糸", [
        ("綿", "wata", "kapas"),
        ("綿花", "menka", "kapas (tanaman)"),
        ("木綿", "momen", "katun"),
    ], [
        ("綿のシャツです。", "Men no shatsu desu.", "Ini kemeja katun."),
        ("綿花を栽培しています。", "Menka o saibai shite imasu.", "Kami membudidayakan kapas."),
    ]),
    ("kan10_n2", "汗", ["カン"], ["あせ"], ["keringat", "sweat"], 6, "水", [
        ("汗", "ase", "keringat"),
        ("汗をかく", "ase o kaku", "berkeringat"),
        ("発汗", "hakkan", "berkeringat"),
    ], [
        ("汗をかきました。", "Ase o kakimashita.", "Saya berkeringat."),
        ("運動で発汗しました。", "Undou de hakkan shimashita.", "Saya berkeringat karena olahraga."),
    ]),
    ("dou3_n2", "銅", ["ドウ"], [], ["tembaga", "copper"], 14, "金", [
        ("銅", "dou", "tembaga"),
        ("銅像", "douzou", "patung perunggu"),
        ("青銅", "seidou", "perunggu"),
    ], [
        ("銅でできています。", "Dou de dekite imasu.", "Terbuat dari tembaga."),
        ("青銅器時代について学びました。", "Seidouki jidai ni tsuite manabimashita.", "Saya belajar tentang zaman perunggu."),
    ]),
    ("shitsu_n2", "湿", ["シツ"], ["しめ-る", "しめ-す"], ["lembab", "moist"], 12, "水", [
        ("湿度", "shitsudo", "kelembaban"),
        ("湿気", "shikke", "kelembaban udara"),
        ("湿る", "shimeru", "menjadi lembab"),
    ], [
        ("湿度が高いです。", "Shitsudo ga takai desu.", "Kelembabannya tinggi."),
        ("湿気が多いです。", "Shikke ga ooi desu.", "Udaranya lembab."),
    ]),
    ("bin_n2", "瓶", ["ヘイ", "ビン"], [], ["botol", "bottle"], 11, "瓦", [
        ("瓶", "bin", "botol"),
        ("花瓶", "kabin", "vas bunga"),
        ("空き瓶", "akibin", "botol kosong"),
    ], [
        ("瓶に水を入れました。", "Bin ni mizu o iremashita.", "Saya mengisi botol dengan air."),
        ("花瓶に花を飾りました。", "Kabin ni hana o kazarimashita.", "Saya menghias vas dengan bunga."),
    ]),
    ("saku2_n2", "咲", [], ["さ-く"], ["mekar", "bloom"], 9, "口", [
        ("咲く", "saku", "mekar"),
        ("遅咲き", "osozaki", "mekar terlambat"),
        ("早咲き", "hayazaki", "mekar awal"),
    ], [
        ("桜が咲きました。", "Sakura ga sakimashita.", "Bunga sakura mekar."),
        ("遅咲きの梅です。", "Osozaki no ume desu.", "Ini bunga plum yang mekar terlambat."),
    ]),
    ("shou13_n2", "召", ["ショウ"], [], ["memanggil", "summon"], 5, "口", [
        ("召集", "shoushuu", "pemanggilan/mobilisasi"),
        ("召還", "shoukan", "pemanggilan kembali"),
        ("召し上がる", "meshiagaru", "memakan (bentuk hormat)"),
    ], [
        ("議会が召集されました。", "Gikai ga shoushuu saremashita.", "Parlemen dipanggil untuk bersidang."),
        ("どうぞ召し上がってください。", "Douzo meshiagatte kudasai.", "Silakan dinikmati (makan)."),
    ]),
    ("kan11_n2", "缶", ["カン"], [], ["kaleng", "can"], 6, "缶", [
        ("缶", "kan", "kaleng"),
        ("缶詰", "kanzume", "makanan kaleng"),
        ("空き缶", "akikan", "kaleng kosong"),
    ], [
        ("缶を開けました。", "Kan o akemashita.", "Saya membuka kaleng."),
        ("空き缶を捨てました。", "Akikan o sutemashita.", "Saya membuang kaleng kosong."),
    ]),
    ("seki4_n2", "隻", ["セキ"], [], ["kata bantu bilangan kapal", "counter"], 10, "隹", [
        ("一隻", "isseki", "satu kapal"),
        ("船隻", "senseki", "jumlah kapal"),
        ("数隻", "suuseki", "beberapa kapal"),
    ], [
        ("船が一隻見えます。", "Fune ga isseki miemasu.", "Terlihat satu kapal."),
        ("数隻の船が港にいます。", "Suuseki no fune ga minato ni imasu.", "Beberapa kapal ada di pelabuhan."),
    ]),
    ("shi6_n2", "脂", ["シ"], ["あぶら"], ["lemak", "fat"], 10, "肉", [
        ("脂肪", "shibou", "lemak"),
        ("脂", "abura", "lemak/minyak"),
        ("皮脂", "hishi", "minyak kulit"),
    ], [
        ("脂肪を減らしたいです。", "Shibou o herashitai desu.", "Saya ingin mengurangi lemak."),
        ("この魚は脂がのっています。", "Kono sakana wa abura ga notte imasu.", "Ikan ini berlemak/gurih."),
    ]),
    ("jou2_n2", "蒸", ["ジョウ"], ["む-す", "む-れる"], ["mengukus", "steam"], 13, "艸", [
        ("蒸す", "musu", "mengukus"),
        ("蒸気", "jouki", "uap"),
        ("蒸発", "jouhatsu", "penguapan"),
    ], [
        ("野菜を蒸しました。", "Yasai o mushimashita.", "Saya mengukus sayuran."),
        ("水が蒸発しました。", "Mizu ga jouhatsu shimashita.", "Air menguap."),
    ]),
    ("hada_n2", "肌", [], ["はだ"], ["kulit", "skin"], 6, "肉", [
        ("肌", "hada", "kulit"),
        ("肌触り", "hadazawari", "tekstur kulit/sentuhan"),
        ("素肌", "suhada", "kulit polos"),
    ], [
        ("肌がきれいです。", "Hada ga kirei desu.", "Kulitnya bagus."),
        ("肌触りが良いです。", "Hadazawari ga ii desu.", "Teksturnya lembut di kulit."),
    ]),
    ("kou12_n2", "耕", ["コウ"], ["たがや-す"], ["mengolah tanah", "cultivate"], 10, "耒", [
        ("耕す", "tagayasu", "mengolah tanah"),
        ("耕作", "kousaku", "penggarapan"),
        ("農耕", "noukou", "pertanian"),
    ], [
        ("畑を耕しました。", "Hatake o tagayashimashita.", "Saya mengolah ladang."),
        ("農耕文化について学びました。", "Noukou bunka ni tsuite manabimashita.", "Saya belajar tentang budaya agraris."),
    ]),
    ("don_n2", "鈍", ["ドン"], ["にぶ-い"], ["tumpul", "lamban", "dull"], 12, "金", [
        ("鈍い", "nibui", "tumpul/lamban"),
        ("鈍感", "donkan", "tidak peka"),
        ("鈍化", "donka", "perlambatan"),
    ], [
        ("反応が鈍いです。", "Hannou ga nibui desu.", "Reaksinya lamban."),
        ("彼は鈍感です。", "Kare wa donkan desu.", "Dia tidak peka."),
    ]),
    ("dei_n2", "泥", ["デイ"], ["どろ"], ["lumpur", "mud"], 8, "水", [
        ("泥", "doro", "lumpur"),
        ("泥棒", "dorobou", "pencuri"),
        ("泥だらけ", "dorodarake", "penuh lumpur"),
    ], [
        ("泥で汚れました。", "Doro de yogoremashita.", "Kotor karena lumpur."),
        ("靴が泥だらけです。", "Kutsu ga dorodarake desu.", "Sepatunya penuh lumpur."),
    ]),
    ("guu_n2", "隅", ["グウ"], ["すみ"], ["sudut", "pojok", "corner"], 12, "阜", [
        ("隅", "sumi", "sudut/pojok"),
        ("片隅", "katasumi", "sudut kecil"),
        ("隅々", "sumizumi", "setiap sudut"),
    ], [
        ("部屋の隅にあります。", "Heya no sumi ni arimasu.", "Ada di sudut ruangan."),
        ("隅々まで掃除しました。", "Sumizumi made souji shimashita.", "Saya membersihkan sampai ke setiap sudut."),
    ]),
    ("tou6_n2", "灯", ["トウ"], ["ひ"], ["lampu", "cahaya", "light"], 6, "火", [
        ("電灯", "dentou", "lampu listrik"),
        ("灯台", "toudai", "mercusuar"),
        ("灯り", "akari", "cahaya"),
    ], [
        ("電灯をつけました。", "Dentou o tsukemashita.", "Saya menyalakan lampu."),
        ("灯台が見えます。", "Toudai ga miemasu.", "Terlihat mercusuar."),
    ]),
    ("shin5_n2", "辛", ["シン"], ["から-い", "つら-い"], ["pedas", "berat/menyakitkan", "spicy"], 7, "辛", [
        ("辛い", "karai", "pedas"),
        ("辛口", "karakuchi", "rasa pedas"),
        ("香辛料", "koushinryou", "rempah-rempah"),
    ], [
        ("このカレーは辛いです。", "Kono karee wa karai desu.", "Kari ini pedas."),
        ("辛い経験でした。", "Tsurai keiken deshita.", "Itu pengalaman yang berat."),
    ]),
    ("ma_n2", "磨", ["マ"], ["みが-く"], ["mengasah", "menggosok", "polish"], 16, "石", [
        ("磨く", "migaku", "menggosok/mengasah"),
        ("歯磨き", "hamigaki", "menggosok gigi"),
        ("研磨", "kenma", "pengasahan"),
    ], [
        ("歯を磨きました。", "Ha o migakimashita.", "Saya menggosok gigi."),
        ("技術を磨いています。", "Gijutsu o migaite imasu.", "Saya mengasah keterampilan."),
    ]),
    ("baku2_n2", "麦", ["バク"], ["むぎ"], ["gandum", "wheat"], 7, "麦", [
        ("麦", "mugi", "gandum"),
        ("小麦", "komugi", "gandum"),
        ("麦茶", "mugicha", "teh barley"),
    ], [
        ("麦畑があります。", "Mugibatake ga arimasu.", "Ada ladang gandum."),
        ("麦茶を飲みました。", "Mugicha o nomimashita.", "Saya minum teh barley."),
    ]),
    ("sei4_n2", "姓", ["セイ", "ショウ"], [], ["marga", "nama keluarga", "surname"], 8, "女", [
        ("姓", "sei", "marga"),
        ("姓名", "seimei", "nama lengkap"),
        ("旧姓", "kyuusei", "nama marga lama"),
    ], [
        ("姓名を書いてください。", "Seimei o kaite kudasai.", "Tolong tulis nama lengkap Anda."),
        ("旧姓を使っています。", "Kyuusei o tsukatte imasu.", "Saya menggunakan nama marga lama."),
    ]),
    ("tou7_n2", "筒", ["トウ"], ["つつ"], ["tabung", "tube"], 12, "竹", [
        ("筒", "tsutsu", "tabung"),
        ("封筒", "fuutou", "amplop"),
        ("水筒", "suitou", "botol minum"),
    ], [
        ("水筒を持って行きました。", "Suitou o motte ikimashita.", "Saya membawa botol minum."),
        ("筒に入れました。", "Tsutsu ni iremashita.", "Saya memasukkan ke dalam tabung."),
    ]),
    ("bi_n2", "鼻", ["ビ"], ["はな"], ["hidung", "nose"], 14, "鼻", [
        ("鼻", "hana", "hidung"),
        ("鼻水", "hanamizu", "ingus"),
        ("鼻血", "hanaji", "mimisan"),
    ], [
        ("鼻が高いです。", "Hana ga takai desu.", "Hidungnya mancung."),
        ("鼻水が出ます。", "Hanamizu ga demasu.", "Ingusnya keluar."),
    ]),
    ("ryuu_n2", "粒", ["リュウ"], ["つぶ"], ["butir", "grain"], 11, "米", [
        ("粒", "tsubu", "butir"),
        ("一粒", "hitotsubu", "satu butir"),
        ("粒子", "ryuushi", "partikel"),
    ], [
        ("米粒を数えました。", "Kometsubu o kazoemashita.", "Saya menghitung butir beras."),
        ("粒子が見えます。", "Ryuushi ga miemasu.", "Partikelnya terlihat."),
    ]),
    ("shi7_n2", "詞", ["シ"], [], ["kata", "kelas kata", "word"], 12, "言", [
        ("名詞", "meishi", "kata benda"),
        ("動詞", "doushi", "kata kerja"),
        ("歌詞", "kashi", "lirik lagu"),
    ], [
        ("名詞を覚えました。", "Meishi o oboemashita.", "Saya menghafal kata benda."),
        ("歌詞を書きました。", "Kashi o kakimashita.", "Saya menulis lirik lagu."),
    ]),
    ("i6_n2", "胃", ["イ"], [], ["lambung", "stomach"], 9, "肉", [
        ("胃", "i", "lambung"),
        ("胃痛", "itsuu", "sakit perut/lambung"),
        ("胃薬", "igusuri", "obat lambung"),
    ], [
        ("胃が痛いです。", "I ga itai desu.", "Lambungnya sakit."),
        ("胃薬を飲みました。", "Igusuri o nomimashita.", "Saya minum obat lambung."),
    ]),
    ("jou3_n2", "畳", ["ジョウ"], ["たたみ", "たた-む"], ["tikar tatami", "tatami mat"], 12, "田", [
        ("畳", "tatami", "tikar tatami"),
        ("畳む", "tatamu", "melipat"),
        ("六畳間", "rokujouma", "kamar 6 tatami"),
    ], [
        ("畳の部屋です。", "Tatami no heya desu.", "Ini ruangan bertatami."),
        ("洗濯物を畳みました。", "Sentakumono o tatamimashita.", "Saya melipat cucian."),
    ]),
    ("ki4_n2", "机", ["キ"], ["つくえ"], ["meja", "desk"], 6, "木", [
        ("机", "tsukue", "meja"),
        ("机上", "kijou", "di atas meja/teoritis"),
        ("勉強机", "benkyou tsukue", "meja belajar"),
    ], [
        ("机の上に本があります。", "Tsukue no ue ni hon ga arimasu.", "Ada buku di atas meja."),
        ("勉強机を買いました。", "Benkyou tsukue o kaimashita.", "Saya membeli meja belajar."),
    ]),
    ("fu4_n2", "膚", ["フ"], [], ["kulit (tubuh)", "skin"], 15, "肉", [
        ("皮膚", "hifu", "kulit"),
        ("皮膚科", "hifuka", "dokter kulit"),
        ("完膚なきまで", "kanpu naki made", "habis-habisan"),
    ], [
        ("皮膚が敏感です。", "Hifu ga binkan desu.", "Kulitnya sensitif."),
        ("完膚なきまで負けました。", "Kanpu naki made makemashita.", "Kalah habis-habisan."),
    ]),
    ("taku_n2", "濯", ["タク"], [], ["mencuci", "wash"], 17, "水", [
        ("洗濯", "sentaku", "mencuci baju"),
        ("洗濯機", "sentakuki", "mesin cuci"),
        ("洗濯物", "sentakumono", "cucian"),
    ], [
        ("洗濯機を使いました。", "Sentakuki o tsukaimashita.", "Saya menggunakan mesin cuci."),
        ("洗濯物を干しました。", "Sentakumono o hoshimashita.", "Saya menjemur cucian."),
    ]),
    ("tou8_n2", "塔", ["トウ"], [], ["menara", "tower"], 12, "土", [
        ("塔", "tou", "menara"),
        ("五重塔", "gojuunotou", "pagoda lima tingkat"),
        ("管制塔", "kanseitou", "menara kontrol"),
    ], [
        ("五重塔を見学しました。", "Gojuunotou o kengaku shimashita.", "Saya mengunjungi pagoda lima tingkat."),
        ("管制塔から指示がありました。", "Kanseitou kara shiji ga arimashita.", "Ada instruksi dari menara kontrol."),
    ]),
    ("futsu_n2", "沸", ["フツ"], ["わ-く", "わ-かす"], ["mendidih", "boil"], 8, "水", [
        ("沸騰", "futtou", "mendidih"),
        ("沸く", "waku", "mendidih"),
        ("沸かす", "wakasu", "merebus/mendidihkan"),
    ], [
        ("お湯が沸騰しました。", "O-yu ga futtou shimashita.", "Air mendidih."),
        ("やかんでお湯を沸かしました。", "Yakan de o-yu o wakashimashita.", "Saya merebus air dengan ketel."),
    ]),
    ("kai6_n2", "灰", ["カイ"], ["はい"], ["abu", "ash"], 6, "火", [
        ("灰", "hai", "abu"),
        ("灰色", "haiiro", "warna abu-abu"),
        ("灰皿", "haizara", "asbak"),
    ], [
        ("灰色の空です。", "Haiiro no sora desu.", "Langitnya berwarna abu-abu."),
        ("灰皿を片付けました。", "Haizara o katazukemashita.", "Saya membereskan asbak."),
    ]),
    ("ka5_n2", "菓", ["カ"], [], ["kue", "manisan", "confectionery"], 11, "艸", [
        ("菓子", "kashi", "kue/manisan"),
        ("和菓子", "wagashi", "kue tradisional Jepang"),
        ("洋菓子", "yougashi", "kue ala barat"),
    ], [
        ("菓子を食べました。", "Kashi o tabemashita.", "Saya makan kue."),
        ("和菓子が好きです。", "Wagashi ga suki desu.", "Saya suka kue tradisional Jepang."),
    ]),
    ("bou5_n2", "帽", ["ボウ"], [], ["topi", "hat"], 12, "巾", [
        ("帽子", "boushi", "topi"),
        ("麦わら帽子", "mugiwara boushi", "topi jerami"),
        ("脱帽", "datsubou", "melepas topi/mengakui kekalahan"),
    ], [
        ("帽子をかぶりました。", "Boushi o kaburimashita.", "Saya memakai topi."),
        ("彼の実力に脱帽です。", "Kare no jitsuryoku ni datsubou desu.", "Saya mengakui kehebatannya."),
    ]),
    ("ko7_n2", "枯", ["コ"], ["か-れる", "か-らす"], ["layu", "mati (tumbuhan)", "wither"], 9, "木", [
        ("枯れる", "kareru", "layu/mati"),
        ("枯葉", "kareha", "daun kering"),
        ("枯渇", "kokatsu", "kekeringan/kehabisan"),
    ], [
        ("花が枯れました。", "Hana ga karemashita.", "Bunganya layu."),
        ("資源が枯渇しています。", "Shigen ga kokatsu shite imasu.", "Sumber daya menipis."),
    ]),
    ("ryou5_n2", "涼", ["リョウ"], ["すず-しい"], ["sejuk", "cool"], 11, "水", [
        ("涼しい", "suzushii", "sejuk"),
        ("涼風", "ryoufuu", "angin sejuk"),
        ("納涼", "nouryou", "menikmati kesejukan"),
    ], [
        ("今日は涼しいです。", "Kyou wa suzushii desu.", "Hari ini sejuk."),
        ("涼風が吹いています。", "Ryoufuu ga fuite imasu.", "Angin sejuk bertiup."),
    ]),
    ("shuu4_n2", "舟", ["シュウ"], ["ふね"], ["perahu kecil", "small boat"], 6, "舟", [
        ("舟", "fune", "perahu"),
        ("舟遊び", "funaasobi", "bermain perahu"),
        ("小舟", "kobune", "perahu kecil"),
    ], [
        ("舟に乗りました。", "Fune ni norimashita.", "Saya naik perahu."),
        ("小舟で川を渡りました。", "Kobune de kawa o watarimashita.", "Saya menyeberangi sungai dengan perahu kecil."),
    ]),
    ("kai7_n2", "貝", [], ["かい"], ["kerang", "shellfish"], 7, "貝", [
        ("貝", "kai", "kerang"),
        ("貝殻", "kaigara", "cangkang kerang"),
        ("二枚貝", "nimaigai", "kerang berkatup dua"),
    ], [
        ("貝を拾いました。", "Kai o hiroimashita.", "Saya memungut kerang."),
        ("貝殻を集めています。", "Kaigara o atsumete imasu.", "Saya mengumpulkan cangkang kerang."),
    ]),
    ("fu5_n2", "符", ["フ"], [], ["simbol", "tanda", "token"], 11, "竹", [
        ("符号", "fugou", "kode/simbol"),
        ("音符", "onpu", "not musik"),
        ("切符", "kippu", "tiket"),
    ], [
        ("切符を買いました。", "Kippu o kaimashita.", "Saya membeli tiket."),
        ("音符を読めます。", "Onpu o yomemasu.", "Saya bisa membaca not musik."),
    ]),
    ("zou6_n2", "憎", ["ゾウ"], ["にく-む", "にく-い"], ["membenci", "hate"], 14, "心", [
        ("憎む", "nikumu", "membenci"),
        ("憎い", "nikui", "dibenci/menyebalkan"),
        ("愛憎", "aizou", "cinta dan benci"),
    ], [
        ("彼を憎んでいません。", "Kare o nikunde imasen.", "Saya tidak membencinya."),
        ("愛憎が入り混じっています。", "Aizou ga irimajitte imasu.", "Cinta dan benci bercampur."),
    ]),
    ("sara_n2", "皿", [], ["さら"], ["piring", "plate"], 5, "皿", [
        ("皿", "sara", "piring"),
        ("灰皿", "haizara", "asbak"),
        ("皿洗い", "sara arai", "mencuci piring"),
    ], [
        ("皿を洗いました。", "Sara o araimashita.", "Saya mencuci piring."),
        ("大きい皿がほしいです。", "Ookii sara ga hoshii desu.", "Saya ingin piring besar."),
    ]),
    ("kou13_n2", "肯", ["コウ"], [], ["mengiyakan", "menyetujui", "affirm"], 8, "肉", [
        ("肯定", "koutei", "afirmasi/persetujuan"),
        ("首肯", "shukou", "mengangguk setuju"),
        ("肯定的", "kouteiteki", "positif"),
    ], [
        ("肯定的に考えましょう。", "Kouteiteki ni kangaemashou.", "Mari berpikir positif."),
        ("提案に首肯しました。", "Teian ni shukou shimashita.", "Saya mengangguk setuju pada usulan itu."),
    ]),
    ("sou7_n2", "燥", ["ソウ"], [], ["kering", "dry"], 17, "火", [
        ("乾燥", "kansou", "kekeringan/pengeringan"),
        ("乾燥機", "kansouki", "mesin pengering"),
        ("焦燥", "shousou", "kegelisahan"),
    ], [
        ("肌が乾燥しています。", "Hada ga kansou shite imasu.", "Kulitnya kering."),
        ("乾燥機を使いました。", "Kansouki o tsukaimashita.", "Saya menggunakan mesin pengering."),
    ]),
    ("chiku3_n2", "畜", ["チク"], [], ["ternak", "livestock"], 10, "田", [
        ("家畜", "kachiku", "ternak"),
        ("畜産", "chikusan", "peternakan"),
        ("牧畜", "bokuchiku", "penggembalaan ternak"),
    ], [
        ("家畜を育てています。", "Kachiku o sodatete imasu.", "Saya memelihara ternak."),
        ("畜産業で働いています。", "Chikusangyou de hataraite imasu.", "Saya bekerja di industri peternakan."),
    ]),
    ("bou6_n2", "坊", ["ボウ"], [], ["anak laki-laki", "biksu", "boy"], 7, "土", [
        ("坊主", "bouzu", "biksu/botak"),
        ("坊っちゃん", "botchan", "anak laki-laki tuan"),
        ("赤ん坊", "akanbou", "bayi"),
    ], [
        ("赤ん坊が生まれました。", "Akanbou ga umaremashita.", "Bayinya lahir."),
        ("お坊さんに会いました。", "O-bou-san ni aimashita.", "Saya bertemu biksu."),
    ]),
    ("kyou8_n2", "挟", ["キョウ"], ["はさ-む", "はさ-まる"], ["menjepit", "menyisipkan", "insert"], 9, "手", [
        ("挟む", "hasamu", "menjepit/menyisipkan"),
        ("挟まる", "hasamaru", "terjepit"),
        ("板挟み", "itabasami", "terjepit di antara dua pihak"),
    ], [
        ("パンに具を挟みました。", "Pan ni gu o hasamimashita.", "Saya menyisipkan isian ke roti."),
        ("ドアに指が挟まりました。", "Doa ni yubi ga hasamarimashita.", "Jari saya terjepit di pintu."),
    ]),
    ("don2_n2", "曇", ["ドン"], ["くも-る"], ["berawan", "mendung", "cloudy"], 16, "日", [
        ("曇り", "kumori", "mendung"),
        ("曇る", "kumoru", "menjadi mendung"),
        ("曇天", "donten", "langit mendung"),
    ], [
        ("今日は曇りです。", "Kyou wa kumori desu.", "Hari ini mendung."),
        ("空が曇ってきました。", "Sora ga kumotte kimashita.", "Langit mulai mendung."),
    ]),
    ("teki_n2", "滴", ["テキ"], ["しずく", "したた-る"], ["tetes", "drop"], 14, "水", [
        ("一滴", "itteki", "satu tetes"),
        ("水滴", "suiteki", "tetesan air"),
        ("滴る", "shitataru", "menetes"),
    ], [
        ("水滴が落ちました。", "Suiteki ga ochimashita.", "Tetesan air jatuh."),
        ("一滴も残っていません。", "Itteki mo nokotte imasen.", "Tidak setetes pun tersisa."),
    ]),
    ("shi8_n2", "伺", ["シ"], ["うかが-う"], ["bertanya (bentuk hormat)", "berkunjung", "ask humbly"], 7, "人", [
        ("伺う", "ukagau", "berkunjung/bertanya secara hormat"),
        ("伺い", "ukagai", "permintaan/pertanyaan formal"),
        ("伺候", "shikou", "menghadap/melayani"),
    ], [
        ("明日お伺いします。", "Ashita o-ukagai shimasu.", "Besok saya akan berkunjung (dengan hormat)."),
        ("ご意見を伺いました。", "Go-iken o ukagaimashita.", "Saya menanyakan pendapat Anda (dengan hormat)."),
    ]),
]

# Batch-authored against the locked N1_CHARACTERS list (1503 kanji, by far
# the largest level), same process as N2_KANJI/N3_KANJI above:
# build_n1_entries() mirrors build_n2_entries(). Authored in the same
# frequency order jlptsensei.com provides, so the most common/useful N1
# kanji get real content first.
N1_KANJI = [
    ("shi_n1", "氏", ["シ"], ["うじ"], ["marga", "gelar hormat Tuan", "surname"], 4, "氏", [
        ("氏名", "shimei", "nama lengkap"),
        ("山田氏", "Yamada-shi", "Tuan Yamada"),
        ("氏", "uji", "marga/klan"),
    ], [
        ("氏名を書いてください。", "Shimei o kaite kudasai.", "Tolong tulis nama lengkap Anda."),
        ("山田氏が到着しました。", "Yamada-shi ga touchaku shimashita.", "Tuan Yamada telah tiba."),
    ]),
    ("tou_n1", "統", ["トウ"], ["す-べる"], ["memerintah", "menyatukan", "govern"], 12, "糸", [
        ("統一", "touitsu", "penyatuan"),
        ("伝統", "dentou", "tradisi"),
        ("統計", "toukei", "statistik"),
    ], [
        ("国を統一しました。", "Kuni o touitsu shimashita.", "Menyatukan negara."),
        ("伝統を守っています。", "Dentou o mamotte imasu.", "Menjaga tradisi."),
    ]),
    ("ki_n1", "基", ["キ"], ["もと", "もとい"], ["dasar", "base"], 11, "土", [
        ("基本", "kihon", "dasar"),
        ("基礎", "kiso", "fondasi"),
        ("基準", "kijun", "standar"),
    ], [
        ("基本を勉強しています。", "Kihon o benkyou shite imasu.", "Saya belajar dasar-dasarnya."),
        ("基礎を固めましょう。", "Kiso o katamemashou.", "Mari kita perkuat fondasinya."),
    ]),
    ("ka_n1", "価", ["カ"], ["あたい"], ["nilai", "harga", "value"], 8, "人", [
        ("価格", "kakaku", "harga"),
        ("価値", "kachi", "nilai"),
        ("評価", "hyouka", "evaluasi/penilaian"),
    ], [
        ("価格が上がりました。", "Kakaku ga agarimashita.", "Harganya naik."),
        ("高い評価を受けました。", "Takai hyouka o ukemashita.", "Mendapat penilaian tinggi."),
    ]),
    ("tei_n1", "提", ["テイ"], ["さ-げる"], ["mengajukan", "present"], 12, "手", [
        ("提案", "teian", "proposal"),
        ("提出", "teishutsu", "penyerahan"),
        ("前提", "zentei", "prasyarat/premis"),
    ], [
        ("レポートを提出しました。", "Repooto o teishutsu shimashita.", "Saya menyerahkan laporan."),
        ("前提が間違っています。", "Zentei ga machigatte imasu.", "Premisnya salah."),
    ]),
    ("kyo_n1", "挙", ["キョ"], ["あ-げる", "あ-がる"], ["mengangkat", "melaksanakan", "raise"], 10, "手", [
        ("選挙", "senkyo", "pemilihan umum"),
        ("挙げる", "ageru", "mengangkat"),
        ("挙式", "kyoshiki", "upacara (pernikahan)"),
    ], [
        ("選挙に行きました。", "Senkyo ni ikimashita.", "Saya pergi memilih."),
        ("手を挙げてください。", "Te o agete kudasai.", "Tolong angkat tangan."),
    ]),
    ("ou_n1", "応", ["オウ"], ["こた-える"], ["menanggapi", "respond"], 7, "心", [
        ("対応", "taiou", "penanganan/respons"),
        ("応援", "ouen", "dukungan/semangat"),
        ("反応", "hannou", "reaksi"),
    ], [
        ("対応してもらいました。", "Taiou shite moraimashita.", "Saya ditangani dengan baik."),
        ("応援しています。", "Ouen shite imasu.", "Saya mendukung."),
    ]),
    ("ki2_n1", "企", ["キ"], [], ["merencanakan", "plan"], 6, "人", [
        ("企業", "kigyou", "perusahaan"),
        ("企画", "kikaku", "perencanaan"),
        ("企業家", "kigyouka", "pengusaha"),
    ], [
        ("企業で働いています。", "Kigyou de hataraite imasu.", "Saya bekerja di perusahaan."),
        ("新しい企画を考えました。", "Atarashii kikaku o kangaemashita.", "Saya memikirkan rencana baru."),
    ]),
    ("ken_n1", "検", ["ケン"], [], ["memeriksa", "inspect"], 12, "木", [
        ("検査", "kensa", "pemeriksaan"),
        ("検討", "kentou", "pertimbangan"),
        ("点検", "tenken", "inspeksi"),
    ], [
        ("検討してください。", "Kentou shite kudasai.", "Tolong pertimbangkan."),
        ("車を点検しました。", "Kuruma o tenken shimashita.", "Saya memeriksa mobil."),
    ]),
    ("tou2_n1", "藤", ["トウ"], ["ふじ"], ["bunga wisteria", "wisteria"], 18, "艸", [
        ("藤", "fuji", "wisteria"),
        ("藤色", "fujiiro", "warna ungu wisteria"),
        ("葛藤", "kattou", "konflik batin"),
    ], [
        ("藤の花がきれいです。", "Fuji no hana ga kirei desu.", "Bunga wisterianya indah."),
        ("葛藤を感じています。", "Kattou o kanjite imasu.", "Saya merasakan konflik batin."),
    ]),
    ("taku_n1", "沢", ["タク"], ["さわ"], ["rawa", "berlimpah", "swamp"], 7, "水", [
        ("沢山", "takusan", "banyak"),
        ("沢", "sawa", "rawa/lembah kecil"),
        ("贅沢", "zeitaku", "kemewahan"),
    ], [
        ("沢山食べました。", "Takusan tabemashita.", "Saya makan banyak."),
        ("贅沢な生活です。", "Zeitaku na seikatsu desu.", "Ini kehidupan yang mewah."),
    ]),
    ("sai_n1", "裁", ["サイ"], ["さば-く", "た-つ"], ["mengadili", "memotong kain", "judge"], 12, "衣", [
        ("裁判", "saiban", "persidangan"),
        ("裁判所", "saibansho", "pengadilan"),
        ("裁縫", "saihou", "menjahit"),
    ], [
        ("裁判所に行きました。", "Saibansho ni ikimashita.", "Saya pergi ke pengadilan."),
        ("裁縫が得意です。", "Saihou ga tokui desu.", "Saya pandai menjahit."),
    ]),
    ("shou_n1", "証", ["ショウ"], [], ["bukti", "proof"], 12, "言", [
        ("証明", "shoumei", "pembuktian"),
        ("証拠", "shouko", "bukti"),
        ("保証", "hoshou", "jaminan"),
    ], [
        ("身分を証明してください。", "Mibun o shoumei shite kudasai.", "Tolong buktikan identitas Anda."),
        ("証拠があります。", "Shouko ga arimasu.", "Ada buktinya."),
    ]),
    ("en_n1", "援", ["エン"], [], ["membantu", "assist"], 12, "手", [
        ("応援", "ouen", "dukungan"),
        ("援助", "enjo", "bantuan"),
        ("支援", "shien", "dukungan/support"),
    ], [
        ("援助を受けました。", "Enjo o ukemashita.", "Saya menerima bantuan."),
        ("被災者を支援しています。", "Hisaisha o shien shite imasu.", "Kami mendukung korban bencana."),
    ]),
    ("ka2_n1", "可", ["カ"], [], ["diizinkan", "memungkinkan", "permit"], 5, "口", [
        ("可能", "kanou", "memungkinkan"),
        ("許可", "kyoka", "izin"),
        ("不可能", "fukanou", "tidak mungkin"),
    ], [
        ("それは可能です。", "Sore wa kanou desu.", "Itu memungkinkan."),
        ("許可をもらいました。", "Kyoka o moraimashita.", "Saya mendapat izin."),
    ]),
    ("shi2_n1", "施", ["シ"], ["ほどこ-す"], ["melaksanakan", "conduct"], 9, "方", [
        ("実施", "jisshi", "pelaksanaan"),
        ("施設", "shisetsu", "fasilitas"),
        ("施す", "hodokosu", "memberikan/melaksanakan"),
    ], [
        ("実施されました。", "Jisshi saremashita.", "Sudah dilaksanakan."),
        ("施設を利用しました。", "Shisetsu o riyou shimashita.", "Saya menggunakan fasilitas."),
    ]),
    ("sei_n1", "井", ["セイ"], ["い"], ["sumur", "well"], 4, "二", [
        ("井戸", "ido", "sumur"),
        ("天井", "tenjou", "langit-langit"),
        ("福井", "Fukui", "nama prefektur"),
    ], [
        ("井戸から水を汲みました。", "Ido kara mizu o kumimashita.", "Saya mengambil air dari sumur."),
        ("天井が高いです。", "Tenjou ga takai desu.", "Langit-langitnya tinggi."),
    ]),
    ("go_n1", "護", ["ゴ"], [], ["melindungi", "protect"], 20, "言", [
        ("保護", "hogo", "perlindungan"),
        ("介護", "kaigo", "perawatan lansia"),
        ("弁護士", "bengoshi", "pengacara"),
    ], [
        ("動物を保護しています。", "Doubutsu o hogo shite imasu.", "Kami melindungi hewan."),
        ("弁護士に相談しました。", "Bengoshi ni soudan shimashita.", "Saya berkonsultasi dengan pengacara."),
    ]),
    ("ten_n1", "展", ["テン"], [], ["memamerkan", "berkembang", "exhibit"], 10, "尸", [
        ("展覧会", "tenrankai", "pameran"),
        ("発展", "hatten", "perkembangan"),
        ("展開", "tenkai", "perkembangan/penyebaran"),
    ], [
        ("展覧会を見に行きました。", "Tenrankai o mi ni ikimashita.", "Saya pergi melihat pameran."),
        ("経済が発展しています。", "Keizai ga hatten shite imasu.", "Ekonomi berkembang."),
    ]),
    ("tai_n1", "態", ["タイ"], [], ["keadaan", "state"], 14, "心", [
        ("状態", "joutai", "kondisi/keadaan"),
        ("態度", "taido", "sikap"),
        ("事態", "jitai", "situasi"),
    ], [
        ("健康状態はいいです。", "Kenkou joutai wa ii desu.", "Kondisi kesehatannya baik."),
        ("彼の態度が悪いです。", "Kare no taido ga warui desu.", "Sikapnya buruk."),
    ]),
    ("sen_n1", "鮮", ["セン"], ["あざ-やか"], ["segar", "fresh"], 17, "魚", [
        ("新鮮", "shinsen", "segar"),
        ("鮮やか", "azayaka", "cerah/jelas"),
        ("朝鮮", "Chousen", "Korea (historis)"),
    ], [
        ("新鮮な野菜です。", "Shinsen na yasai desu.", "Ini sayuran segar."),
        ("鮮やかな色です。", "Azayaka na iro desu.", "Warna yang cerah."),
    ]),
    ("shi3_n1", "視", ["シ"], [], ["melihat", "memandang", "see"], 11, "見", [
        ("視力", "shiryoku", "penglihatan"),
        ("無視", "mushi", "mengabaikan"),
        ("視点", "shiten", "sudut pandang"),
    ], [
        ("視力が悪くなりました。", "Shiryoku ga waruku narimashita.", "Penglihatan saya memburuk."),
        ("彼を無視しないでください。", "Kare o mushi shinaide kudasai.", "Jangan abaikan dia."),
    ]),
    ("jou_n1", "条", ["ジョウ"], [], ["pasal", "garis", "article"], 7, "木", [
        ("条件", "jouken", "syarat"),
        ("条約", "jouyaku", "perjanjian"),
        ("第一条", "dai ichi jou", "pasal pertama"),
    ], [
        ("条件を満たしました。", "Jouken o mitashimashita.", "Saya memenuhi syarat."),
        ("条約を結びました。", "Jouyaku o musubimashita.", "Kami menandatangani perjanjian."),
    ]),
    ("kan_n1", "幹", ["カン"], ["みき"], ["batang pohon", "inti", "trunk"], 13, "干", [
        ("幹部", "kanbu", "eksekutif/pimpinan"),
        ("新幹線", "shinkansen", "kereta peluru"),
        ("幹事", "kanji", "koordinator acara"),
    ], [
        ("会社の幹部です。", "Kaisha no kanbu desu.", "Dia eksekutif perusahaan."),
        ("幹事を任されました。", "Kanji o makasaremashita.", "Saya dipercaya jadi koordinator."),
    ]),
    ("doku_n1", "独", ["ドク"], ["ひと-り"], ["sendiri", "alone"], 9, "犬", [
        ("独立", "dokuritsu", "kemerdekaan/independensi"),
        ("独身", "dokushin", "lajang"),
        ("独特", "dokutoku", "unik/khas"),
    ], [
        ("独立記念日です。", "Dokuritsu kinenbi desu.", "Ini hari kemerdekaan."),
        ("彼は独身です。", "Kare wa dokushin desu.", "Dia lajang."),
    ]),
    ("kyuu_n1", "宮", ["キュウ", "グウ"], ["みや"], ["istana", "kuil", "palace"], 10, "宀", [
        ("宮殿", "kyuuden", "istana"),
        ("神宮", "jinguu", "kuil besar"),
        ("子宮", "shikyuu", "rahim"),
    ], [
        ("宮殿を見学しました。", "Kyuuden o kengaku shimashita.", "Saya mengunjungi istana."),
        ("明治神宮に行きました。", "Meiji Jinguu ni ikimashita.", "Saya pergi ke Kuil Meiji."),
    ]),
    ("ritsu_n1", "率", ["リツ", "ソツ"], ["ひき-いる"], ["tingkat/rasio", "memimpin", "rate"], 11, "玄", [
        ("比率", "hiritsu", "rasio"),
        ("効率", "kouritsu", "efisiensi"),
        ("率いる", "hikiiru", "memimpin"),
    ], [
        ("効率が良いです。", "Kouritsu ga ii desu.", "Efisiensinya bagus."),
        ("チームを率いています。", "Chiimu o hikiite imasu.", "Saya memimpin tim."),
    ]),
    ("ei_n1", "衛", ["エイ"], [], ["menjaga", "guard"], 16, "行", [
        ("衛生", "eisei", "higiene/kesehatan"),
        ("護衛", "goei", "pengawalan"),
        ("衛星", "eisei", "satelit"),
    ], [
        ("衛生に気をつけています。", "Eisei ni ki o tsukete imasu.", "Saya menjaga kebersihan."),
        ("衛星を打ち上げました。", "Eisei o uchiagemashita.", "Mereka meluncurkan satelit."),
    ]),
    ("chou_n1", "張", ["チョウ"], ["は-る"], ["meregang", "stretch"], 11, "弓", [
        ("主張", "shuchou", "klaim/pendapat"),
        ("緊張", "kinchou", "ketegangan/gugup"),
        ("張る", "haru", "meregang/memasang"),
    ], [
        ("自分の意見を主張しました。", "Jibun no iken o shuchou shimashita.", "Saya menyatakan pendapat sendiri."),
        ("緊張しています。", "Kinchou shite imasu.", "Saya gugup."),
    ]),
    ("kan2_n1", "監", ["カン"], [], ["mengawasi", "supervise"], 15, "皿", [
        ("監督", "kantoku", "pengawas/sutradara"),
        ("監視", "kanshi", "pengawasan"),
        ("監督者", "kantokusha", "supervisor"),
    ], [
        ("映画の監督です。", "Eiga no kantoku desu.", "Dia sutradara film."),
        ("常に監視されています。", "Tsuneni kanshi sarete imasu.", "Selalu diawasi."),
    ]),
    ("kan3_n1", "環", ["カン"], [], ["cincin", "mengelilingi", "ring"], 17, "玉", [
        ("環境", "kankyou", "lingkungan"),
        ("循環", "junkan", "sirkulasi"),
        ("一環", "ikkan", "bagian dari suatu rangkaian"),
    ], [
        ("血液が循環しています。", "Ketsueki ga junkan shite imasu.", "Darah bersirkulasi."),
        ("計画の一環です。", "Keikaku no ikkan desu.", "Ini bagian dari rencana."),
    ]),
    ("shin_n1", "審", ["シン"], [], ["memeriksa", "examine"], 15, "宀", [
        ("審査", "shinsa", "penilaian/seleksi"),
        ("審判", "shinpan", "wasit"),
        ("不審", "fushin", "mencurigakan"),
    ], [
        ("審査に合格しました。", "Shinsa ni goukaku shimashita.", "Saya lulus seleksi."),
        ("審判が笛を吹きました。", "Shinpan ga fue o fukimashita.", "Wasit meniup peluit."),
    ]),
    ("gi_n1", "義", ["ギ"], [], ["keadilan", "makna", "justice"], 13, "羊", [
        ("意義", "igi", "makna/signifikansi"),
        ("主義", "shugi", "paham/prinsip"),
        ("正義", "seigi", "keadilan"),
    ], [
        ("この仕事には意義があります。", "Kono shigoto ni wa igi ga arimasu.", "Pekerjaan ini bermakna."),
        ("正義を守ります。", "Seigi o mamorimasu.", "Saya menjaga keadilan."),
    ]),
    ("so_n1", "訴", ["ソ"], ["うった-える"], ["menuntut", "mengadukan", "sue"], 12, "言", [
        ("訴える", "uttaeru", "menuntut/mengadukan"),
        ("訴訟", "soshou", "tuntutan hukum"),
        ("告訴", "kokuso", "tuntutan pidana"),
    ], [
        ("裁判所に訴えました。", "Saibansho ni uttaemashita.", "Saya mengajukan tuntutan ke pengadilan."),
        ("訴訟を起こしました。", "Soshou o okoshimashita.", "Saya mengajukan gugatan."),
    ]),
    ("kabu_n1", "株", [], ["かぶ"], ["saham", "tunggul pohon", "stock"], 10, "木", [
        ("株", "kabu", "saham"),
        ("株式会社", "kabushiki gaisha", "perseroan terbatas"),
        ("株価", "kabuka", "harga saham"),
    ], [
        ("株を買いました。", "Kabu o kaimashita.", "Saya membeli saham."),
        ("株価が下がりました。", "Kabuka ga sagarimashita.", "Harga saham turun."),
    ]),
    ("shi4_n1", "姿", ["シ"], ["すがた"], ["penampilan", "sosok", "figure"], 9, "女", [
        ("姿", "sugata", "sosok/penampilan"),
        ("姿勢", "shisei", "postur"),
        ("容姿", "youshi", "penampilan fisik"),
    ], [
        ("彼の姿が見えません。", "Kare no sugata ga miemasen.", "Sosoknya tidak terlihat."),
        ("容姿を気にしています。", "Youshi o ki ni shite imasu.", "Saya khawatir tentang penampilan."),
    ]),
    ("kaku_n1", "閣", ["カク"], [], ["kabinet", "paviliun", "cabinet"], 14, "門", [
        ("内閣", "naikaku", "kabinet"),
        ("天守閣", "tenshukaku", "menara utama kastil"),
        ("閣僚", "kakuryou", "menteri kabinet"),
    ], [
        ("内閣が発表しました。", "Naikaku ga happyou shimashita.", "Kabinet mengumumkan."),
        ("天守閣に登りました。", "Tenshukaku ni noborimashita.", "Saya naik ke menara kastil."),
    ]),
    ("kan4_n1", "韓", ["カン"], [], ["Korea"], 18, "韋", [
        ("韓国", "Kankoku", "Korea Selatan"),
        ("韓国語", "Kankokugo", "bahasa Korea"),
        ("日韓", "Nikkan", "Jepang-Korea"),
    ], [
        ("韓国へ旅行しました。", "Kankoku e ryokou shimashita.", "Saya bepergian ke Korea."),
        ("韓国語を勉強しています。", "Kankokugo o benkyou shite imasu.", "Saya belajar bahasa Korea."),
    ]),
    ("shuu_n1", "衆", ["シュウ", "シュ"], [], ["massa", "kerumunan", "masses"], 12, "血", [
        ("大衆", "taishuu", "masyarakat umum"),
        ("衆議院", "shuugiin", "Majelis Rendah"),
        ("観衆", "kanshuu", "penonton"),
    ], [
        ("大衆に人気があります。", "Taishuu ni ninki ga arimasu.", "Populer di kalangan masyarakat umum."),
        ("観衆が拍手しました。", "Kanshuu ga hakushu shimashita.", "Penonton bertepuk tangan."),
    ]),
    ("hyou_n1", "評", ["ヒョウ"], [], ["menilai", "evaluate"], 12, "言", [
        ("評価", "hyouka", "evaluasi"),
        ("批評", "hihyou", "kritik"),
        ("評判", "hyouban", "reputasi"),
    ], [
        ("批評を受けました。", "Hihyou o ukemashita.", "Saya menerima kritik."),
        ("評判がいいです。", "Hyouban ga ii desu.", "Reputasinya bagus."),
    ]),
    ("oka_n1", "岡", [], ["おか"], ["bukit", "hill"], 8, "山", [
        ("岡", "oka", "bukit"),
        ("静岡", "Shizuoka", "nama prefektur"),
        ("福岡", "Fukuoka", "nama prefektur"),
    ], [
        ("静岡へ旅行しました。", "Shizuoka e ryokou shimashita.", "Saya bepergian ke Shizuoka."),
        ("福岡出身です。", "Fukuoka shusshin desu.", "Saya berasal dari Fukuoka."),
    ]),
    ("ei2_n1", "影", ["エイ"], ["かげ"], ["bayangan", "shadow"], 15, "彡", [
        ("影", "kage", "bayangan"),
        ("影響", "eikyou", "pengaruh"),
        ("撮影", "satsuei", "pengambilan foto/gambar"),
    ], [
        ("影が長いです。", "Kage ga nagai desu.", "Bayangannya panjang."),
        ("影響を受けました。", "Eikyou o ukemashita.", "Saya terpengaruh."),
    ]),
    ("shou2_n1", "松", ["ショウ"], ["まつ"], ["pohon pinus", "pine tree"], 8, "木", [
        ("松", "matsu", "pohon pinus"),
        ("松の木", "matsu no ki", "pohon pinus"),
        ("松島", "Matsushima", "nama tempat"),
    ], [
        ("松の木があります。", "Matsu no ki ga arimasu.", "Ada pohon pinus."),
        ("松島を観光しました。", "Matsushima o kankou shimashita.", "Saya berwisata ke Matsushima."),
    ]),
    ("geki_n1", "撃", ["ゲキ"], ["う-つ"], ["menyerang", "strike"], 15, "手", [
        ("攻撃", "kougeki", "serangan"),
        ("衝撃", "shougeki", "kejutan/dampak"),
        ("撃つ", "utsu", "menembak"),
    ], [
        ("攻撃されました。", "Kougeki saremashita.", "Diserang."),
        ("衝撃を受けました。", "Shougeki o ukemashita.", "Saya terkejut."),
    ]),
    ("sa_n1", "佐", ["サ"], [], ["membantu", "assist"], 7, "人", [
        ("佐藤", "Satou", "nama keluarga"),
        ("大佐", "taisa", "kolonel"),
        ("補佐", "hosa", "asisten"),
    ], [
        ("佐藤さんに会いました。", "Satou-san ni aimashita.", "Saya bertemu dengan Pak/Bu Satou."),
        ("補佐をしています。", "Hosa o shite imasu.", "Saya menjadi asisten."),
    ]),
    ("kaku2_n1", "核", ["カク"], [], ["inti", "nucleus"], 10, "木", [
        ("核心", "kakushin", "inti masalah"),
        ("核家族", "kaku kazoku", "keluarga inti"),
        ("原子核", "genshikaku", "inti atom"),
    ], [
        ("核心に触れました。", "Kakushin ni furemashita.", "Menyentuh inti masalah."),
        ("核家族が増えています。", "Kaku kazoku ga fuete imasu.", "Keluarga inti semakin banyak."),
    ]),
    ("sei2_n1", "整", ["セイ"], ["ととの-える", "ととの-う"], ["merapikan", "arrange"], 16, "攴", [
        ("整理", "seiri", "pengaturan/perapian"),
        ("調整", "chousei", "penyesuaian"),
        ("整える", "totonoeru", "merapikan"),
    ], [
        ("部屋を整理しました。", "Heya o seiri shimashita.", "Saya merapikan kamar."),
        ("スケジュールを調整しました。", "Sukejuuru o chousei shimashita.", "Saya menyesuaikan jadwal."),
    ]),
    ("yuu_n1", "融", ["ユウ"], [], ["melebur", "keuangan", "melt/finance"], 16, "虫", [
        ("金融", "kinyuu", "keuangan"),
        ("融資", "yuushi", "pembiayaan"),
        ("融合", "yuugou", "peleburan/fusi"),
    ], [
        ("金融業界で働いています。", "Kinyuu gyoukai de hataraite imasu.", "Saya bekerja di industri keuangan."),
        ("融資を受けました。", "Yuushi o ukemashita.", "Saya menerima pembiayaan."),
    ]),
    ("sei3_n1", "製", ["セイ"], [], ["membuat", "produk", "manufacture"], 14, "衣", [
        ("製品", "seihin", "produk"),
        ("製造", "seizou", "manufaktur"),
        ("日本製", "Nihon-sei", "buatan Jepang"),
    ], [
        ("新しい製品です。", "Atarashii seihin desu.", "Ini produk baru."),
        ("これは日本製です。", "Kore wa Nihon-sei desu.", "Ini buatan Jepang."),
    ]),
    ("hyou2_n1", "票", ["ヒョウ"], [], ["suara pemilihan", "tiket", "vote"], 11, "示", [
        ("投票", "touhyou", "pemungutan suara"),
        ("伝票", "denpyou", "slip/nota"),
        ("票", "hyou", "suara"),
    ], [
        ("投票に行きました。", "Touhyou ni ikimashita.", "Saya pergi memberikan suara."),
        ("伝票を書きました。", "Denpyou o kakimashita.", "Saya menulis nota."),
    ]),
    ("shou3_n1", "渉", ["ショウ"], [], ["berunding", "negotiate"], 11, "水", [
        ("交渉", "koushou", "negosiasi"),
        ("渉外", "shougai", "hubungan masyarakat/luar"),
        ("干渉", "kanshou", "campur tangan"),
    ], [
        ("交渉が成功しました。", "Koushou ga seikou shimashita.", "Negosiasi berhasil."),
        ("干渉しないでください。", "Kanshou shinaide kudasai.", "Tolong jangan ikut campur."),
    ]),
    ("kyou_n1", "響", ["キョウ"], ["ひび-く"], ["bergema", "berdampak", "echo"], 20, "音", [
        ("影響", "eikyou", "pengaruh"),
        ("響く", "hibiku", "bergema/terdengar"),
        ("音響", "onkyou", "akustik"),
    ], [
        ("音が響いています。", "Oto ga hibiite imasu.", "Suaranya bergema."),
        ("音響設備がいいです。", "Onkyou setsubi ga ii desu.", "Peralatan akustiknya bagus."),
    ]),
    ("sui_n1", "推", ["スイ"], ["お-す"], ["menyimpulkan", "merekomendasikan", "infer"], 11, "手", [
        ("推薦", "suisen", "rekomendasi"),
        ("推理", "suiri", "deduksi/penalaran"),
        ("推測", "suisoku", "dugaan"),
    ], [
        ("大学に推薦されました。", "Daigaku ni suisen saremashita.", "Saya direkomendasikan ke universitas."),
        ("推理小説が好きです。", "Suiri shousetsu ga suki desu.", "Saya suka novel detektif."),
    ]),
    ("sei4_n1", "請", ["セイ", "シン"], ["こ-う"], ["meminta", "request"], 15, "言", [
        ("要請", "yousei", "permintaan/permohonan"),
        ("申請", "shinsei", "aplikasi/permohonan"),
        ("請求書", "seikyuusho", "tagihan"),
    ], [
        ("支援を要請しました。", "Shien o yousei shimashita.", "Saya meminta bantuan."),
        ("申請書を提出しました。", "Shinseisho o teishutsu shimashita.", "Saya menyerahkan formulir aplikasi."),
    ]),
    ("ki3_n1", "器", ["キ"], ["うつわ"], ["wadah", "organ", "container"], 15, "口", [
        ("器", "utsuwa", "wadah"),
        ("楽器", "gakki", "alat musik"),
        ("容器", "youki", "wadah/kontainer"),
    ], [
        ("楽器を演奏しました。", "Gakki o ensou shimashita.", "Saya memainkan alat musik."),
        ("容器に入れました。", "Youki ni iremashita.", "Saya masukkan ke dalam wadah."),
    ]),
    ("shi5_n1", "士", ["シ"], [], ["prajurit", "profesional", "warrior"], 3, "士", [
        ("兵士", "heishi", "prajurit"),
        ("弁護士", "bengoshi", "pengacara"),
        ("博士", "hakase", "doktor/PhD"),
    ], [
        ("博士号を取りました。", "Hakase-gou o torimashita.", "Saya meraih gelar doktor."),
        ("弁護士に相談しました。", "Bengoshi ni soudan shimashita.", "Saya berkonsultasi dengan pengacara."),
    ]),
    ("tou3_n1", "討", ["トウ"], ["う-つ"], ["menyerang", "mendiskusikan", "attack"], 10, "言", [
        ("検討", "kentou", "pertimbangan"),
        ("討論", "touron", "debat"),
        ("討議", "tougi", "diskusi"),
    ], [
        ("討論をしました。", "Touron o shimashita.", "Kami berdebat."),
        ("討議が続いています。", "Tougi ga tsuzuite imasu.", "Diskusinya berlanjut."),
    ]),
    ("kou_n1", "攻", ["コウ"], ["せ-める"], ["menyerang", "attack"], 7, "攴", [
        ("攻撃", "kougeki", "serangan"),
        ("専攻", "senkou", "jurusan"),
        ("攻める", "semeru", "menyerang"),
    ], [
        ("敵を攻めました。", "Teki o sememashita.", "Menyerang musuh."),
        ("専攻を決めました。", "Senkou o kimemashita.", "Saya menentukan jurusan."),
    ]),
    ("saki_n1", "崎", [], ["さき"], ["tanjung", "cape"], 11, "山", [
        ("長崎", "Nagasaki", "nama kota"),
        ("宮崎", "Miyazaki", "nama prefektur"),
        ("崎", "saki", "tanjung"),
    ], [
        ("長崎へ旅行しました。", "Nagasaki e ryokou shimashita.", "Saya bepergian ke Nagasaki."),
        ("宮崎出身です。", "Miyazaki shusshin desu.", "Saya berasal dari Miyazaki."),
    ]),
    ("toku_n1", "督", ["トク"], [], ["mengawasi", "supervise"], 13, "目", [
        ("監督", "kantoku", "pengawas/sutradara"),
        ("総督", "soutoku", "gubernur jenderal"),
        ("督促", "tokusoku", "tagihan/peringatan"),
    ], [
        ("監督に選ばれました。", "Kantoku ni erabaremashita.", "Terpilih jadi sutradara."),
        ("督促状が届きました。", "Tokusokujou ga todokimashita.", "Surat peringatan datang."),
    ]),
    ("ju_n1", "授", ["ジュ"], ["さず-ける"], ["mengajar", "memberikan", "instruct"], 11, "手", [
        ("授業", "jugyou", "pelajaran/kelas"),
        ("教授", "kyouju", "profesor"),
        ("授与", "juyo", "penganugerahan"),
    ], [
        ("授業を受けています。", "Jugyou o ukete imasu.", "Saya mengikuti pelajaran."),
        ("教授に相談しました。", "Kyouju ni soudan shimashita.", "Saya berkonsultasi dengan profesor."),
    ]),
    ("sai2_n1", "催", ["サイ"], ["もよお-す"], ["menyelenggarakan", "hold event"], 13, "人", [
        ("開催", "kaisai", "penyelenggaraan"),
        ("主催", "shusai", "penyelenggara"),
        ("催促", "saisoku", "desakan"),
    ], [
        ("イベントが開催されました。", "Ibento ga kaisai saremashita.", "Acara diselenggarakan."),
        ("主催者に感謝します。", "Shusaisha ni kansha shimasu.", "Saya berterima kasih pada penyelenggara."),
    ]),
    ("kyuu2_n1", "及", ["キュウ"], ["およ-ぶ", "およ-び"], ["mencapai", "dan", "reach"], 3, "又", [
        ("及ぶ", "oyobu", "mencapai"),
        ("普及", "fukyuu", "penyebaran/popularisasi"),
        ("言及", "genkyuu", "penyebutan/referensi"),
    ], [
        ("影響が及びました。", "Eikyou ga oyobimashita.", "Pengaruhnya sampai."),
        ("その問題に言及しました。", "Sono mondai ni genkyuu shimashita.", "Saya menyebutkan masalah itu."),
    ]),
    ("ken2_n1", "憲", ["ケン"], [], ["konstitusi", "constitution"], 16, "心", [
        ("憲法", "kenpou", "konstitusi/UUD"),
        ("憲章", "kenshou", "piagam"),
        ("立憲", "rikken", "konstitusional"),
    ], [
        ("憲法を守りましょう。", "Kenpou o mamorimashou.", "Mari kita patuhi konstitusi."),
        ("憲章に署名しました。", "Kenshou ni shomei shimashita.", "Saya menandatangani piagam."),
    ]),
    ("ri_n1", "離", ["リ"], ["はな-れる", "はな-す"], ["berpisah", "separate"], 18, "隹", [
        ("離婚", "rikon", "perceraian"),
        ("距離", "kyori", "jarak"),
        ("離れる", "hanareru", "berpisah/menjauh"),
    ], [
        ("離婚しました。", "Rikon shimashita.", "Bercerai."),
        ("距離が遠いです。", "Kyori ga tooi desu.", "Jaraknya jauh."),
    ]),
    ("geki2_n1", "激", ["ゲキ"], ["はげ-しい"], ["hebat", "keras", "intense"], 16, "水", [
        ("激しい", "hageshii", "hebat/keras"),
        ("刺激", "shigeki", "stimulasi"),
        ("感激", "kangeki", "sangat terharu"),
    ], [
        ("激しい雨が降っています。", "Hageshii ame ga futte imasu.", "Hujan turun dengan lebat."),
        ("感激しました。", "Kangeki shimashita.", "Saya sangat terharu."),
    ]),
    ("teki_n1", "摘", ["テキ"], ["つ-む"], ["memetik", "pick"], 14, "手", [
        ("指摘", "shiteki", "menunjukkan/mengkritik"),
        ("摘む", "tsumu", "memetik"),
        ("摘出", "tekishutsu", "pengangkatan (medis)"),
    ], [
        ("問題を指摘しました。", "Mondai o shiteki shimashita.", "Saya menunjukkan masalahnya."),
        ("花を摘みました。", "Hana o tsumimashita.", "Saya memetik bunga."),
    ]),
    ("kei_n1", "系", ["ケイ"], [], ["sistem", "garis keturunan", "system"], 7, "糸", [
        ("体系", "taikei", "sistem"),
        ("系統", "keitou", "garis keturunan/silsilah"),
        ("日系", "nikkei", "keturunan Jepang"),
    ], [
        ("体系的に学びました。", "Taikeiteki ni manabimashita.", "Saya belajar secara sistematis."),
        ("日系企業で働いています。", "Nikkei kigyou de hataraite imasu.", "Saya bekerja di perusahaan Jepang."),
    ]),
    ("hi_n1", "批", ["ヒ"], [], ["mengkritik", "criticize"], 7, "手", [
        ("批判", "hihan", "kritik"),
        ("批評", "hihyou", "kritik"),
        ("批准", "hijun", "ratifikasi"),
    ], [
        ("批判を受けました。", "Hihan o ukemashita.", "Saya menerima kritik."),
        ("条約を批准しました。", "Jouyaku o hijun shimashita.", "Meratifikasi perjanjian."),
    ]),
    ("rou_n1", "郎", ["ロウ"], [], ["laki-laki", "man"], 9, "邑", [
        ("太郎", "Tarou", "nama pria umum"),
        ("新郎", "shinrou", "mempelai pria"),
        ("野郎", "yarou", "cowok (kasar)"),
    ], [
        ("太郎という名前です。", "Tarou to iu namae desu.", "Namanya Tarou."),
        ("新郎新婦です。", "Shinrou shinpu desu.", "Ini mempelai pria dan wanita."),
    ]),
    ("ken3_n1", "健", ["ケン"], ["すこ-やか"], ["sehat", "healthy"], 11, "人", [
        ("健康", "kenkou", "kesehatan"),
        ("健全", "kenzen", "sehat/wajar"),
        ("保健室", "hokenshitsu", "ruang UKS"),
    ], [
        ("健康に気をつけています。", "Kenkou ni ki o tsukete imasu.", "Saya menjaga kesehatan."),
        ("保健室に行きました。", "Hokenshitsu ni ikimashita.", "Saya pergi ke ruang UKS."),
    ]),
    ("juu_n1", "従", ["ジュウ"], ["したが-う"], ["mengikuti", "follow"], 10, "彳", [
        ("従う", "shitagau", "mengikuti/patuh"),
        ("従業員", "juugyouin", "karyawan"),
        ("服従", "fukujuu", "kepatuhan"),
    ], [
        ("規則に従います。", "Kisoku ni shitagaimasu.", "Saya mengikuti aturan."),
        ("従業員が多いです。", "Juugyouin ga ooi desu.", "Karyawannya banyak."),
    ]),
    ("shuu2_n1", "修", ["シュウ"], ["おさ-める"], ["mempelajari", "memperbaiki", "study"], 10, "人", [
        ("修理", "shuuri", "perbaikan"),
        ("修正", "shuusei", "koreksi"),
        ("修学旅行", "shuugaku ryokou", "karyawisata sekolah"),
    ], [
        ("車を修理しました。", "Kuruma o shuuri shimashita.", "Saya memperbaiki mobil."),
        ("修学旅行に行きました。", "Shuugaku ryokou ni ikimashita.", "Saya pergi karyawisata sekolah."),
    ]),
    ("tai2_n1", "隊", ["タイ"], [], ["pasukan", "regu", "corps"], 12, "阜", [
        ("軍隊", "guntai", "angkatan bersenjata"),
        ("部隊", "butai", "unit militer"),
        ("隊員", "taiin", "anggota regu"),
    ], [
        ("部隊が出動しました。", "Butai ga shutsudou shimashita.", "Unit militer berangkat."),
        ("隊員として働いています。", "Taiin toshite hataraite imasu.", "Saya bekerja sebagai anggota regu."),
    ]),
    ("shoku_n1", "織", ["シキ", "ショク"], ["お-る"], ["menenun", "weave"], 18, "糸", [
        ("組織", "soshiki", "organisasi"),
        ("織物", "orimono", "tekstil/kain tenun"),
        ("織る", "oru", "menenun"),
    ], [
        ("組織を作りました。", "Soshiki o tsukurimashita.", "Saya membuat organisasi."),
        ("織物を作っています。", "Orimono o tsukutte imasu.", "Saya membuat tekstil."),
    ]),
    ("kaku3_n1", "拡", ["カク"], [], ["memperluas", "expand"], 8, "手", [
        ("拡大", "kakudai", "perluasan/pembesaran"),
        ("拡張", "kakuchou", "ekspansi"),
        ("拡散", "kakusan", "penyebaran/difusi"),
    ], [
        ("写真を拡大しました。", "Shashin o kakudai shimashita.", "Saya memperbesar foto."),
        ("事業を拡張しました。", "Jigyou o kakuchou shimashita.", "Saya mengekspansi bisnis."),
    ]),
    ("ko_n1", "故", ["コ"], ["ゆえ"], ["alasan", "almarhum", "reason"], 9, "攴", [
        ("事故", "jiko", "kecelakaan"),
        ("故障", "koshou", "kerusakan"),
        ("故人", "kojin", "almarhum"),
    ], [
        ("交通事故がありました。", "Koutsuu jiko ga arimashita.", "Ada kecelakaan lalu lintas."),
        ("機械が故障しました。", "Kikai ga koshou shimashita.", "Mesinnya rusak."),
    ]),
    ("shin2_n1", "振", ["シン"], ["ふ-る", "ふ-るう"], ["mengibaskan", "bergetar", "shake"], 10, "手", [
        ("振る", "furu", "mengibaskan"),
        ("振動", "shindou", "getaran"),
        ("不振", "fushin", "kelesuan/kemunduran"),
    ], [
        ("手を振りました。", "Te o furimashita.", "Saya melambaikan tangan."),
        ("携帯が振動しています。", "Keitai ga shindou shite imasu.", "Ponselnya bergetar."),
    ]),
    ("ben_n1", "弁", ["ベン"], [], ["katup", "dialek", "kelopak", "valve"], 5, "廾", [
        ("弁護士", "bengoshi", "pengacara"),
        ("弁当", "bentou", "bekal makan siang"),
        ("弁明", "benmei", "pembelaan/penjelasan"),
    ], [
        ("弁当を作りました。", "Bentou o tsukurimashita.", "Saya membuat bekal."),
        ("弁明する機会がありました。", "Benmei suru kikai ga arimashita.", "Ada kesempatan untuk membela diri."),
    ]),
    ("shuu3_n1", "就", ["シュウ"], ["つ-く"], ["menduduki posisi", "take up"], 12, "尢", [
        ("就職", "shushoku", "mendapatkan pekerjaan"),
        ("就任", "shunin", "menjabat"),
        ("就く", "tsuku", "menduduki (posisi)"),
    ], [
        ("就職活動をしています。", "Shuushoku katsudou o shite imasu.", "Saya sedang mencari kerja."),
        ("社長に就任しました。", "Shachou ni shunin shimashita.", "Dia menjabat sebagai direktur."),
    ]),
    ("i_n1", "異", ["イ"], ["こと-なる"], ["berbeda", "different"], 11, "田", [
        ("異なる", "kotonaru", "berbeda"),
        ("異常", "ijou", "tidak normal"),
        ("異文化", "ibunka", "budaya asing"),
    ], [
        ("意見が異なります。", "Iken ga kotonarimasu.", "Pendapatnya berbeda."),
        ("異常気象です。", "Ijou kishou desu.", "Ini cuaca yang tidak normal."),
    ]),
    ("ken4_n1", "献", ["ケン", "コン"], [], ["mempersembahkan", "offer"], 13, "犬", [
        ("貢献", "koken", "kontribusi"),
        ("献立", "kondate", "menu"),
        ("文献", "bunken", "literatur/referensi"),
    ], [
        ("社会に貢献したいです。", "Shakai ni kouken shitai desu.", "Saya ingin berkontribusi pada masyarakat."),
        ("文献を調べました。", "Bunken o shirabemashita.", "Saya meneliti literatur."),
    ]),
    ("gen_n1", "厳", ["ゲン"], ["きび-しい", "おごそ-か"], ["ketat", "strict"], 17, "厂", [
        ("厳しい", "kibishii", "ketat/keras"),
        ("厳重", "genjuu", "ketat/strict"),
        ("厳格", "genkaku", "disiplin/tegas"),
    ], [
        ("先生は厳しいです。", "Sensei wa kibishii desu.", "Gurunya ketat."),
        ("厳重に管理されています。", "Genjuu ni kanri sarete imasu.", "Dikelola dengan ketat."),
    ]),
    ("i2_n1", "維", ["イ"], [], ["serat", "mempertahankan", "fiber"], 14, "糸", [
        ("維持", "iji", "pemeliharaan"),
        ("繊維", "sen'i", "serat/tekstil"),
        ("維新", "ishin", "restorasi (era Meiji)"),
    ], [
        ("健康を維持しています。", "Kenkou o iji shite imasu.", "Saya menjaga kesehatan."),
        ("明治維新について学びました。", "Meiji ishin ni tsuite manabimashita.", "Saya belajar tentang Restorasi Meiji."),
    ]),
    ("hin_n1", "浜", ["ヒン"], ["はま"], ["pantai", "beach"], 10, "水", [
        ("浜辺", "hamabe", "tepi pantai"),
        ("横浜", "Yokohama", "nama kota"),
        ("海浜", "kaihin", "tepi laut"),
    ], [
        ("浜辺を散歩しました。", "Hamabe o sanpo shimashita.", "Saya jalan-jalan di tepi pantai."),
        ("横浜に住んでいます。", "Yokohama ni sunde imasu.", "Saya tinggal di Yokohama."),
    ]),
    ("i3_n1", "遺", ["イ"], [], ["peninggalan", "legacy"], 15, "辵", [
        ("遺跡", "iseki", "situs bersejarah"),
        ("遺産", "isan", "warisan"),
        ("遺伝", "iden", "keturunan genetik"),
    ], [
        ("世界遺産を訪ねました。", "Sekai isan o tazunemashita.", "Saya mengunjungi warisan dunia."),
        ("遺伝子について学びました。", "Idenshi ni tsuite manabimashita.", "Saya belajar tentang gen."),
    ]),
    ("rui_n1", "塁", ["ルイ"], [], ["base bisbol", "markas", "rampart"], 12, "土", [
        ("塁", "rui", "base"),
        ("一塁", "ichirui", "base pertama"),
        ("満塁", "manrui", "bases loaded"),
    ], [
        ("一塁に走りました。", "Ichirui ni hashirimashita.", "Saya berlari ke base pertama."),
        ("満塁ホームランです。", "Manrui hoomuran desu.", "Ini home run bases loaded."),
    ]),
    ("hou_n1", "邦", ["ホウ"], [], ["negara", "nation"], 7, "邑", [
        ("邦人", "houjin", "warga negara Jepang di luar negeri"),
        ("連邦", "renpou", "federasi"),
        ("異邦人", "ihoujin", "orang asing"),
    ], [
        ("邦人が保護されました。", "Houjin ga hogo saremashita.", "Warga negara Jepang dilindungi."),
        ("連邦政府です。", "Renpou seifu desu.", "Ini pemerintah federal."),
    ]),
    ("so2_n1", "素", ["ソ"], [], ["unsur", "murni/polos", "element"], 10, "糸", [
        ("素晴らしい", "subarashii", "luar biasa"),
        ("要素", "youso", "elemen"),
        ("素材", "sozai", "bahan/material"),
    ], [
        ("素晴らしい景色です。", "Subarashii keshiki desu.", "Pemandangan yang luar biasa."),
        ("重要な要素です。", "Juuyou na youso desu.", "Ini elemen penting."),
    ]),
    ("ken5_n1", "遣", ["ケン"], ["つか-う", "つか-わす"], ["mengutus", "dispatch"], 13, "辵", [
        ("派遣", "haken", "pengiriman tenaga kerja"),
        ("遣唐使", "kentoushi", "utusan ke Tang"),
        ("気遣い", "kizukai", "perhatian/kepedulian"),
    ], [
        ("派遣社員です。", "Haken shain desu.", "Dia karyawan kontrak/outsource."),
        ("気遣いをありがとうございます。", "Kizukai o arigatou gozaimasu.", "Terima kasih atas perhatiannya."),
    ]),
    ("kou2_n1", "抗", ["コウ"], [], ["melawan", "resist"], 7, "手", [
        ("抵抗", "teikou", "perlawanan"),
        ("反抗", "hankou", "pemberontakan"),
        ("抗議", "kougi", "protes"),
    ], [
        ("抵抗しました。", "Teikou shimashita.", "Saya melawan."),
        ("抗議デモが行われました。", "Kougi demo ga okonawaremashita.", "Demo protes dilakukan."),
    ]),
    ("mo_n1", "模", ["モ", "ボ"], [], ["model", "meniru", "imitate"], 14, "木", [
        ("模範", "mohan", "teladan"),
        ("模様", "moyou", "pola/motif"),
        ("規模", "kibo", "skala"),
    ], [
        ("模範的な生徒です。", "Mohanteki na seito desu.", "Dia siswa teladan."),
        ("大きい規模の会社です。", "Ookii kibo no kaisha desu.", "Perusahaan berskala besar."),
    ]),
    ("yuu2_n1", "雄", ["ユウ"], ["お", "おす"], ["jantan", "pahlawan", "hero"], 12, "隹", [
        ("英雄", "eiyuu", "pahlawan"),
        ("雄大", "yuudai", "megah/agung"),
        ("雌雄", "shiyuu", "jantan dan betina"),
    ], [
        ("彼は英雄です。", "Kare wa eiyuu desu.", "Dia adalah pahlawan."),
        ("雄大な景色です。", "Yuudai na keshiki desu.", "Pemandangan yang megah."),
    ]),
    ("eki_n1", "益", ["エキ", "ヤク"], [], ["keuntungan", "profit"], 10, "皿", [
        ("利益", "rieki", "keuntungan"),
        ("有益", "yuueki", "bermanfaat"),
        ("公益", "koueki", "kepentingan umum"),
    ], [
        ("利益を得ました。", "Rieki o emashita.", "Mendapat keuntungan."),
        ("有益な情報です。", "Yuueki na jouhou desu.", "Ini informasi yang bermanfaat."),
    ]),
    ("kin_n1", "緊", ["キン"], [], ["tegang", "mendesak", "urgent"], 15, "糸", [
        ("緊張", "kinchou", "ketegangan"),
        ("緊急", "kinkyuu", "darurat"),
        ("緊密", "kinmitsu", "erat"),
    ], [
        ("緊急事態です。", "Kinkyuu jitai desu.", "Ini keadaan darurat."),
        ("緊密な関係です。", "Kinmitsu na kankei desu.", "Ini hubungan yang erat."),
    ]),
    ("hyou3_n1", "標", ["ヒョウ"], [], ["tanda", "mark"], 15, "木", [
        ("目標", "mokuhyou", "target"),
        ("標準", "hyoujun", "standar"),
        ("標識", "hyoushiki", "rambu"),
    ], [
        ("目標を達成しました。", "Mokuhyou o tassei shimashita.", "Saya mencapai target."),
        ("標識を見ました。", "Hyoushiki o mimashita.", "Saya melihat rambu."),
    ]),
    ("sen2_n1", "宣", ["セン"], [], ["mengumumkan", "declare"], 9, "宀", [
        ("宣伝", "senden", "promosi"),
        ("宣言", "sengen", "deklarasi"),
        ("宣告", "senkoku", "vonis/putusan"),
    ], [
        ("商品を宣伝しています。", "Shouhin o senden shite imasu.", "Mempromosikan produk."),
        ("独立を宣言しました。", "Dokuritsu o sengen shimashita.", "Mendeklarasikan kemerdekaan."),
    ]),
    ("shou4_n1", "昭", ["ショウ"], [], ["terang (nama era)", "bright"], 9, "日", [
        ("昭和", "Shouwa", "era Shouwa"),
        ("昭和時代", "Shouwa jidai", "era Shouwa"),
        ("昭和生まれ", "Shouwa umare", "lahir di era Shouwa"),
    ], [
        ("昭和時代に生まれました。", "Shouwa jidai ni umaremashita.", "Saya lahir di era Shouwa."),
        ("昭和の文化が好きです。", "Shouwa no bunka ga suki desu.", "Saya suka budaya era Shouwa."),
    ]),
    ("hai_n1", "廃", ["ハイ"], ["すた-れる"], ["menghapuskan", "abolish"], 12, "广", [
        ("廃止", "haishi", "penghapusan"),
        ("廃棄", "haiki", "pembuangan"),
        ("廃墟", "haikyo", "reruntuhan"),
    ], [
        ("制度が廃止されました。", "Seido ga haishi saremashita.", "Sistemnya dihapuskan."),
        ("廃棄物を処理しました。", "Haikibutsu o shori shimashita.", "Saya mengolah limbah."),
    ]),
    ("i4_n1", "伊", ["イ"], [], ["Italia (singkatan)", "Italy"], 6, "人", [
        ("伊藤", "Itou", "nama keluarga"),
        ("伊豆", "Izu", "nama tempat"),
        ("伊達", "Date", "nama keluarga/tempat"),
    ], [
        ("伊藤さんに会いました。", "Itou-san ni aimashita.", "Saya bertemu Pak/Bu Itou."),
        ("伊豆へ旅行しました。", "Izu e ryokou shimashita.", "Saya bepergian ke Izu."),
    ]),
    ("kou3_n1", "江", ["コウ"], ["え"], ["teluk kecil", "sungai", "inlet"], 6, "水", [
        ("江戸", "Edo", "nama lama Tokyo"),
        ("入り江", "irie", "teluk kecil"),
        ("長江", "Choukou", "Sungai Yangtze"),
    ], [
        ("江戸時代について学びました。", "Edo jidai ni tsuite manabimashita.", "Saya belajar tentang era Edo."),
        ("入り江が美しいです。", "Irie ga utsukushii desu.", "Teluknya indah."),
    ]),
    ("ryou_n1", "僚", ["リョウ"], [], ["rekan kerja", "pejabat", "colleague"], 14, "人", [
        ("同僚", "douryou", "rekan kerja"),
        ("閣僚", "kakuryou", "menteri kabinet"),
        ("官僚", "kanryou", "birokrat"),
    ], [
        ("同僚と話しました。", "Douryou to hanashimashita.", "Saya berbicara dengan rekan kerja."),
        ("官僚制度です。", "Kanryou seido desu.", "Ini sistem birokrasi."),
    ]),
    ("kichi_n1", "吉", ["キチ", "キツ"], [], ["keberuntungan", "luck"], 6, "口", [
        ("大吉", "daikichi", "keberuntungan besar"),
        ("不吉", "fukitsu", "sial"),
        ("吉日", "kichijitsu", "hari baik"),
    ], [
        ("おみくじで大吉が出ました。", "Omikuji de daikichi ga demashita.", "Saya mendapat ramalan keberuntungan besar."),
        ("吉日に結婚しました。", "Kichijitsu ni kekkon shimashita.", "Menikah di hari baik."),
    ]),
    ("sei5_n1", "盛", ["セイ", "ジョウ"], ["も-る", "さか-ん"], ["berkembang", "menumpuk", "prosper"], 11, "皿", [
        ("盛んな", "sakan na", "berkembang pesat"),
        ("盛り上がる", "moriagaru", "semakin ramai/seru"),
        ("繁盛", "hanjou", "kemakmuran/laris"),
    ], [
        ("スポーツが盛んです。", "Supootsu ga sakan desu.", "Olahraga berkembang pesat."),
        ("お店が繁盛しています。", "O-mise ga hanjou shite imasu.", "Tokonya laris."),
    ]),
    ("kou4_n1", "皇", ["コウ", "オウ"], [], ["kaisar", "emperor"], 9, "白", [
        ("天皇", "tennou", "Kaisar Jepang"),
        ("皇后", "kougou", "permaisuri"),
        ("皇室", "koushitsu", "keluarga kekaisaran"),
    ], [
        ("天皇陛下です。", "Tennou heika desu.", "Ini Yang Mulia Kaisar."),
        ("皇室について学びました。", "Koushitsu ni tsuite manabimashita.", "Saya belajar tentang keluarga kekaisaran."),
    ]),
    ("rin_n1", "臨", ["リン"], ["のぞ-む"], ["menghadapi", "face"], 18, "臣", [
        ("臨時", "rinji", "sementara"),
        ("臨む", "nozomu", "menghadapi"),
        ("臨場感", "rinjoukan", "rasa kehadiran/realisme"),
    ], [
        ("臨時休業です。", "Rinji kyuugyou desu.", "Ini tutup sementara."),
        ("試合に臨みます。", "Shiai ni nozomimasu.", "Menghadapi pertandingan."),
    ]),
    ("tou4_n1", "踏", ["トウ"], ["ふ-む"], ["menginjak", "step"], 15, "足", [
        ("踏む", "fumu", "menginjak"),
        ("踏切", "fumikiri", "perlintasan kereta"),
        ("踏襲", "toushuu", "mengikuti tradisi/cara lama"),
    ], [
        ("足を踏まれました。", "Ashi o fumaremashita.", "Kaki saya terinjak."),
        ("踏切で待ちました。", "Fumikiri de machimashita.", "Saya menunggu di perlintasan kereta."),
    ]),
    ("kai_n1", "壊", ["カイ"], ["こわ-す", "こわ-れる"], ["menghancurkan", "break"], 16, "土", [
        ("壊す", "kowasu", "merusak"),
        ("破壊", "hakai", "kehancuran"),
        ("崩壊", "houkai", "keruntuhan"),
    ], [
        ("おもちゃを壊しました。", "Omocha o kowashimashita.", "Saya merusak mainan."),
        ("建物が崩壊しました。", "Tatemono ga houkai shimashita.", "Bangunan runtuh."),
    ]),
    ("sai3_n1", "債", ["サイ"], [], ["hutang", "obligasi", "debt"], 13, "人", [
        ("負債", "fusai", "hutang"),
        ("債権", "saiken", "piutang/hak tagih"),
        ("国債", "kokusai", "obligasi negara"),
    ], [
        ("負債が増えました。", "Fusai ga fuemashita.", "Hutangnya bertambah."),
        ("国債を買いました。", "Kokusai o kaimashita.", "Saya membeli obligasi negara."),
    ]),
    ("kou5_n1", "興", ["コウ", "キョウ"], ["おこ-る", "おこ-す"], ["minat", "membangun", "interest"], 16, "臼", [
        ("興味", "kyoumi", "minat"),
        ("復興", "fukkou", "pemulihan"),
        ("興奮", "koufun", "kegembiraan/kegairahan"),
    ], [
        ("音楽に興味があります。", "Ongaku ni kyoumi ga arimasu.", "Saya tertarik dengan musik."),
        ("地域が復興しました。", "Chiiki ga fukkou shimashita.", "Daerahnya pulih."),
    ]),
    ("gen2_n1", "源", ["ゲン"], ["みなもと"], ["sumber", "source"], 13, "水", [
        ("資源", "shigen", "sumber daya"),
        ("源", "minamoto", "sumber/asal"),
        ("起源", "kigen", "asal usul"),
    ], [
        ("資源が豊富です。", "Shigen ga houfu desu.", "Sumber dayanya melimpah."),
        ("起源を調べました。", "Kigen o shirabemashita.", "Saya menyelidiki asal usulnya."),
    ]),
    ("gi2_n1", "儀", ["ギ"], [], ["upacara", "aturan", "ceremony"], 15, "人", [
        ("儀式", "gishiki", "upacara"),
        ("礼儀", "reigi", "sopan santun"),
        ("行儀", "gyougi", "tata krama"),
    ], [
        ("儀式が行われました。", "Gishiki ga okonawaremashita.", "Upacara dilaksanakan."),
        ("礼儀正しいです。", "Reigi tadashii desu.", "Sopan santun."),
    ]),
    ("sou_n1", "創", ["ソウ"], ["つく-る", "きず"], ["menciptakan", "luka", "create"], 12, "刀", [
        ("創造", "souzou", "kreasi"),
        ("創立", "souritsu", "pendirian"),
        ("創作", "sousaku", "karya kreatif"),
    ], [
        ("創造力が豊かです。", "Souzouryoku ga yutaka desu.", "Daya kreativitasnya kaya."),
        ("会社を創立しました。", "Kaisha o souritsu shimashita.", "Mendirikan perusahaan."),
    ]),
    ("shou5_n1", "障", ["ショウ"], ["さわ-る"], ["rintangan", "obstacle"], 14, "阜", [
        ("障害", "shougai", "hambatan/disabilitas"),
        ("故障", "koshou", "kerusakan"),
        ("保障", "hoshou", "jaminan"),
    ], [
        ("障害を乗り越えました。", "Shougai o norikoemashita.", "Saya mengatasi hambatan."),
        ("社会保障です。", "Shakai hoshou desu.", "Ini jaminan sosial."),
    ]),
    ("kei2_n1", "継", ["ケイ"], ["つ-ぐ"], ["mewarisi", "melanjutkan", "inherit"], 13, "糸", [
        ("継続", "keizoku", "kelanjutan"),
        ("継承", "keishou", "pewarisan"),
        ("中継", "chuukei", "siaran langsung/relay"),
    ], [
        ("継続して努力します。", "Keizoku shite doryoku shimasu.", "Terus berusaha."),
        ("生中継です。", "Nama chuukei desu.", "Ini siaran langsung."),
    ]),
    ("kin2_n1", "筋", ["キン"], ["すじ"], ["otot", "garis", "muscle"], 12, "竹", [
        ("筋肉", "kinniku", "otot"),
        ("筋道", "sujimichi", "alur logika"),
        ("鉄筋", "tekkin", "rangka besi"),
    ], [
        ("筋肉を鍛えています。", "Kinniku o kitaete imasu.", "Saya melatih otot."),
        ("筋道を立てて説明しました。", "Sujimichi o tatete setsumei shimashita.", "Menjelaskan secara logis."),
    ]),
    ("nerau_n1", "狙", [], ["ねら-う"], ["membidik", "aim"], 8, "犬", [
        ("狙う", "nerau", "membidik/menargetkan"),
        ("狙い", "nerai", "target/tujuan"),
        ("狙撃", "sogeki", "penembakan jitu"),
    ], [
        ("目標を狙っています。", "Mokuhyou o neratte imasu.", "Saya menargetkan tujuan."),
        ("狙撃されました。", "Sogeki saremashita.", "Ditembak jitu."),
    ]),
    ("tou5_n1", "闘", ["トウ"], ["たたか-う"], ["bertarung", "fight"], 18, "門", [
        ("闘う", "tatakau", "bertarung"),
        ("戦闘", "sentou", "pertempuran"),
        ("格闘技", "kakutougi", "olahraga bela diri"),
    ], [
        ("病気と闘っています。", "Byouki to tatakatte imasu.", "Saya berjuang melawan penyakit."),
        ("格闘技を習っています。", "Kakutougi o naratte imasu.", "Saya belajar bela diri."),
    ]),
    ("sou2_n1", "葬", ["ソウ"], ["ほうむ-る"], ["pemakaman", "funeral"], 12, "艸", [
        ("葬式", "soushiki", "upacara pemakaman"),
        ("葬儀", "sougi", "pemakaman"),
        ("火葬", "kasou", "kremasi"),
    ], [
        ("葬式に参加しました。", "Soushiki ni sanka shimashita.", "Saya menghadiri upacara pemakaman."),
        ("火葬されました。", "Kasou saremashita.", "Dikremasi."),
    ]),
    ("hi2_n1", "避", ["ヒ"], ["さ-ける"], ["menghindari", "avoid"], 16, "辵", [
        ("避ける", "sakeru", "menghindari"),
        ("避難", "hinan", "evakuasi"),
        ("回避", "kaihi", "penghindaran"),
    ], [
        ("危険を避けました。", "Kiken o sakemashita.", "Saya menghindari bahaya."),
        ("避難してください。", "Hinan shite kudasai.", "Tolong mengungsi."),
    ]),
    ("shi6_n1", "司", ["シ"], [], ["mengelola", "manage"], 5, "口", [
        ("司会", "shikai", "pembawa acara"),
        ("上司", "joushi", "atasan"),
        ("司法", "shihou", "yudisial/peradilan"),
    ], [
        ("司会をしています。", "Shikai o shite imasu.", "Saya menjadi pembawa acara."),
        ("上司に相談しました。", "Joushi ni soudan shimashita.", "Saya berkonsultasi dengan atasan."),
    ]),
    ("kou6_n1", "康", ["コウ"], [], ["sehat", "healthy"], 11, "广", [
        ("健康", "kenkou", "kesehatan"),
        ("健康的", "kenkouteki", "sehat/menyehatkan"),
        ("小康", "shoukou", "keadaan stabil sementara"),
    ], [
        ("健康的な食事です。", "Kenkouteki na shokuji desu.", "Ini makanan yang menyehatkan."),
        ("小康状態です。", "Shoukou joutai desu.", "Kondisinya stabil sementara."),
    ]),
    ("zen_n1", "善", ["ゼン"], ["よ-い"], ["kebajikan", "virtuous"], 12, "口", [
        ("改善", "kaizen", "perbaikan"),
        ("善良", "zenryou", "baik hati"),
        ("慈善", "jizen", "amal"),
    ], [
        ("善良な人です。", "Zenryou na hito desu.", "Dia orang yang baik hati."),
        ("慈善活動をしています。", "Jizen katsudou o shite imasu.", "Saya melakukan kegiatan amal."),
    ]),
    ("tai3_n1", "逮", ["タイ"], [], ["menangkap", "arrest"], 11, "辵", [
        ("逮捕", "taiho", "penangkapan"),
        ("逮捕状", "taihojou", "surat perintah penangkapan"),
        ("逮捕者", "taihosha", "orang yang ditangkap"),
    ], [
        ("犯人が逮捕されました。", "Hannin ga taiho saremashita.", "Pelaku ditangkap."),
        ("逮捕状が出ました。", "Taihojou ga demashita.", "Surat perintah penangkapan dikeluarkan."),
    ]),
    ("haku_n1", "迫", ["ハク"], ["せま-る"], ["mendesak", "press"], 8, "辵", [
        ("迫る", "semaru", "mendesak/mendekat"),
        ("迫力", "hakuryoku", "daya tarik/kekuatan"),
        ("圧迫", "appaku", "tekanan"),
    ], [
        ("締め切りが迫っています。", "Shimekiri ga sematte imasu.", "Tenggat waktu semakin dekat."),
        ("迫力がある映画です。", "Hakuryoku ga aru eiga desu.", "Ini film yang punya daya tarik kuat."),
    ]),
    ("waku_n1", "惑", ["ワク"], ["まど-う"], ["bingung", "confuse"], 12, "心", [
        ("迷惑", "meiwaku", "gangguan/kerepotan"),
        ("惑星", "wakusei", "planet"),
        ("誘惑", "yuuwaku", "godaan"),
    ], [
        ("迷惑をかけました。", "Meiwaku o kakemashita.", "Saya merepotkan."),
        ("誘惑に負けました。", "Yuuwaku ni makemashita.", "Saya kalah dari godaan."),
    ]),
    ("hou2_n1", "崩", ["ホウ"], ["くず-れる", "くず-す"], ["runtuh", "collapse"], 11, "山", [
        ("崩れる", "kuzureru", "runtuh"),
        ("崩壊", "houkai", "keruntuhan"),
        ("山崩れ", "yamakuzure", "tanah longsor"),
    ], [
        ("建物が崩れました。", "Tatemono ga kuzuremashita.", "Bangunannya runtuh."),
        ("山崩れが起きました。", "Yamakuzure ga okimashita.", "Terjadi tanah longsor."),
    ]),
    ("ki4_n1", "紀", ["キ"], [], ["era", "catatan sejarah", "chronicle"], 9, "糸", [
        ("世紀", "seiki", "abad"),
        ("紀元", "kigen", "era/kalender"),
        ("紀行", "kikou", "catatan perjalanan"),
    ], [
        ("21世紀です。", "Nijuuisseiki desu.", "Ini abad ke-21."),
        ("紀行文を書きました。", "Kikoubun o kakimashita.", "Saya menulis catatan perjalanan."),
    ]),
    ("chou2_n1", "聴", ["チョウ"], ["き-く"], ["mendengarkan", "listen"], 17, "耳", [
        ("聴く", "kiku", "mendengarkan"),
        ("聴衆", "choushuu", "hadirin/pendengar"),
        ("視聴率", "shichouritsu", "rating tayangan"),
    ], [
        ("音楽を聴いています。", "Ongaku o kiite imasu.", "Saya mendengarkan musik."),
        ("視聴率が高いです。", "Shichouritsu ga takai desu.", "Ratingnya tinggi."),
    ]),
    ("datsu_n1", "脱", ["ダツ"], ["ぬ-ぐ", "ぬ-げる"], ["melepaskan", "escape"], 11, "肉", [
        ("脱ぐ", "nugu", "melepas (pakaian)"),
        ("脱出", "dasshutsu", "pelarian"),
        ("脱退", "dattai", "pengunduran diri"),
    ], [
        ("靴を脱ぎました。", "Kutsu o nugimashita.", "Saya melepas sepatu."),
        ("危機から脱出しました。", "Kiki kara dasshutsu shimashita.", "Saya lolos dari krisis."),
    ]),
    ("kyuu3_n1", "級", ["キュウ"], [], ["kelas", "tingkat", "class"], 9, "糸", [
        ("級", "kyuu", "tingkat"),
        ("上級", "joukyuu", "tingkat lanjut"),
        ("高級", "koukyuu", "kelas atas/mewah"),
    ], [
        ("上級コースです。", "Joukyuu koosu desu.", "Ini kelas tingkat lanjut."),
        ("高級レストランです。", "Koukyuu resutoran desu.", "Ini restoran mewah."),
    ]),
    ("haku2_n1", "博", ["ハク"], [], ["luas", "gelar doktor", "extensive"], 12, "十", [
        ("博士", "hakase", "doktor"),
        ("博物館", "hakubutsukan", "museum"),
        ("博覧会", "hakurankai", "pameran/expo"),
    ], [
        ("博物館に行きました。", "Hakubutsukan ni ikimashita.", "Saya pergi ke museum."),
        ("博覧会が開催されました。", "Hakurankai ga kaisai saremashita.", "Expo diselenggarakan."),
    ]),
    ("tei2_n1", "締", ["テイ"], ["し-まる", "し-める"], ["mengencangkan", "menyimpulkan", "tighten"], 15, "糸", [
        ("締める", "shimeru", "mengencangkan"),
        ("締結", "teiketsu", "penandatanganan perjanjian"),
        ("締め切り", "shimekiri", "tenggat waktu"),
    ], [
        ("ベルトを締めました。", "Beruto o shimemashita.", "Saya mengencangkan sabuk."),
        ("締め切りに間に合いました。", "Shimekiri ni maniaimashita.", "Berhasil memenuhi tenggat waktu."),
    ]),
    ("kyuu4_n1", "救", ["キュウ"], ["すく-う"], ["menyelamatkan", "save"], 11, "攴", [
        ("救助", "kyuujo", "penyelamatan"),
        ("救急車", "kyuukyuusha", "ambulans"),
        ("救う", "sukuu", "menyelamatkan"),
    ], [
        ("救助されました。", "Kyuujo saremashita.", "Diselamatkan."),
        ("救急車を呼びました。", "Kyuukyuusha o yobimashita.", "Saya memanggil ambulans."),
    ]),
    ("shitsu_n1", "執", ["シツ"], ["と-る"], ["melaksanakan", "hold"], 11, "土", [
        ("執筆", "shippitsu", "penulisan"),
        ("執行", "shikkou", "pelaksanaan"),
        ("固執", "koshitsu", "keras kepala/ngotot"),
    ], [
        ("本を執筆しています。", "Hon o shippitsu shite imasu.", "Saya sedang menulis buku."),
        ("意見に固執しています。", "Iken ni koshitsu shite imasu.", "Ngotot pada pendapatnya."),
    ]),
    ("bou_n1", "房", ["ボウ"], ["ふさ"], ["kamar", "rumbai", "room"], 8, "戸", [
        ("冷房", "reibou", "AC/pendingin ruangan"),
        ("暖房", "danbou", "pemanas ruangan"),
        ("房", "fusa", "rumbai/jumbai"),
    ], [
        ("冷房をつけました。", "Reibou o tsukemashita.", "Saya menyalakan AC."),
        ("暖房が必要です。", "Danbou ga hitsuyou desu.", "Perlu pemanas ruangan."),
    ]),
    ("tetsu_n1", "撤", ["テツ"], [], ["menarik diri", "withdraw"], 15, "手", [
        ("撤退", "tettai", "penarikan diri/mundur"),
        ("撤回", "tekkai", "penarikan kembali"),
        ("撤去", "tekkyo", "pembongkaran/penghapusan"),
    ], [
        ("軍が撤退しました。", "Gun ga tettai shimashita.", "Militer mundur."),
        ("発言を撤回しました。", "Hatsugen o tekkai shimashita.", "Saya menarik kembali pernyataan."),
    ]),
    ("saku_n1", "削", ["サク"], ["けず-る"], ["memotong", "cut"], 9, "刀", [
        ("削除", "sakujo", "penghapusan"),
        ("削減", "sakugen", "pengurangan"),
        ("削る", "kezuru", "mengasah/memotong"),
    ], [
        ("データを削除しました。", "Deeta o sakujo shimashita.", "Saya menghapus data."),
        ("コストを削減しました。", "Kosuto o sakugen shimashita.", "Saya mengurangi biaya."),
    ]),
    ("mitsu_n1", "密", ["ミツ"], [], ["rapat", "rahasia", "secret"], 11, "宀", [
        ("秘密", "himitsu", "rahasia"),
        ("密接", "missetsu", "erat"),
        ("密度", "mitsudo", "kepadatan"),
    ], [
        ("秘密を守りました。", "Himitsu o mamorimashita.", "Saya menjaga rahasia."),
        ("人口密度が高いです。", "Jinkou mitsudo ga takai desu.", "Kepadatan penduduknya tinggi."),
    ]),
    ("so3_n1", "措", ["ソ"], [], ["mengambil langkah", "take measures"], 11, "手", [
        ("措置", "sochi", "tindakan/langkah"),
        ("応急措置", "oukyuu sochi", "tindakan darurat"),
        ("緊急措置", "kinkyuu sochi", "tindakan darurat"),
    ], [
        ("適切な措置を取りました。", "Tekisetsu na sochi o torimashita.", "Mengambil tindakan yang tepat."),
        ("応急措置をしました。", "Oukyuu sochi o shimashita.", "Melakukan pertolongan pertama."),
    ]),
    ("shi7_n1", "志", ["シ"], ["こころざ-す"], ["cita-cita", "aspiration"], 7, "心", [
        ("意志", "ishi", "kemauan/tekad"),
        ("志望", "shibou", "harapan/aspirasi"),
        ("同志", "doushi", "kamerad/sekutu"),
    ], [
        ("強い意志があります。", "Tsuyoi ishi ga arimasu.", "Saya punya tekad yang kuat."),
        ("志望校です。", "Shiboukou desu.", "Ini sekolah yang saya inginkan."),
    ]),
    ("sai4_n1", "載", ["サイ"], ["の-せる", "の-る"], ["memuat", "publish"], 13, "車", [
        ("掲載", "keisai", "publikasi/pemuatan"),
        ("記載", "kisai", "pencatatan"),
        ("満載", "mansai", "penuh muatan"),
    ], [
        ("雑誌に掲載されました。", "Zasshi ni keisai saremashita.", "Dimuat di majalah."),
        ("記載されている情報です。", "Kisai sarete iru jouhou desu.", "Informasi yang tercatat."),
    ]),
    ("jin_n1", "陣", ["ジン"], [], ["markas", "formasi", "camp"], 10, "阜", [
        ("陣営", "jin'ei", "kubu/kamp"),
        ("布陣", "fujin", "formasi/susunan"),
        ("陣痛", "jintsuu", "kontraksi persalinan"),
    ], [
        ("敵の陣営です。", "Teki no jin'ei desu.", "Ini kubu musuh."),
        ("陣痛が始まりました。", "Jintsuu ga hajimarimashita.", "Kontraksi persalinan dimulai."),
    ]),
    ("ga_n1", "我", ["ガ"], ["われ", "わ"], ["diri sendiri", "saya", "self"], 7, "戈", [
        ("我々", "wareware", "kami/kita"),
        ("我慢", "gaman", "kesabaran/menahan diri"),
        ("自我", "jiga", "ego/diri"),
    ], [
        ("我々は頑張ります。", "Wareware wa ganbarimasu.", "Kami akan berusaha."),
        ("我慢しています。", "Gaman shite imasu.", "Saya menahan diri."),
    ]),
    ("i5_n1", "為", ["イ"], ["ため", "な-す"], ["demi", "tindakan", "for the sake of"], 9, "火", [
        ("為に", "tame ni", "demi/untuk"),
        ("行為", "koui", "perbuatan"),
        ("人為的", "jin'iteki", "buatan manusia"),
    ], [
        ("家族の為に働いています。", "Kazoku no tame ni hataraite imasu.", "Saya bekerja demi keluarga."),
        ("危険な行為です。", "Kiken na koui desu.", "Ini perbuatan yang berbahaya."),
    ]),
    ("yoku_n1", "抑", ["ヨク"], ["おさ-える"], ["menekan", "suppress"], 7, "手", [
        ("抑える", "osaeru", "menekan/mengendalikan"),
        ("抑制", "yokusei", "penekanan/kontrol"),
        ("抑圧", "yokuatsu", "penindasan"),
    ], [
        ("感情を抑えました。", "Kanjou o osaemashita.", "Saya menahan emosi."),
        ("抑制が必要です。", "Yokusei ga hitsuyou desu.", "Perlu pengendalian."),
    ]),
    ("maku_n1", "幕", ["マク", "バク"], [], ["tirai", "babak", "curtain"], 13, "巾", [
        ("幕", "maku", "tirai/babak"),
        ("開幕", "kaimaku", "pembukaan acara"),
        ("幕府", "bakufu", "pemerintahan shogun"),
    ], [
        ("幕が開きました。", "Maku ga hirakimashita.", "Tirai terbuka."),
        ("江戸幕府について学びました。", "Edo bakufu ni tsuite manabimashita.", "Saya belajar tentang keshogunan Edo."),
    ]),
    ("sen3_n1", "染", ["セン"], ["そ-める", "そ-まる"], ["mewarnai", "dye"], 9, "木", [
        ("染める", "someru", "mewarnai"),
        ("汚染", "osen", "polusi"),
        ("染色", "senshoku", "pewarnaan"),
    ], [
        ("髪を染めました。", "Kami o somemashita.", "Saya mewarnai rambut."),
        ("染色技術です。", "Senshoku gijutsu desu.", "Ini teknik pewarnaan."),
    ]),
    ("na_n1", "奈", ["ナ"], [], ["komponen nama tempat", "name component"], 8, "大", [
        ("奈良", "Nara", "nama prefektur"),
        ("神奈川", "Kanagawa", "nama prefektur"),
        ("奈落", "naraku", "neraka/jurang"),
    ], [
        ("奈良へ旅行しました。", "Nara e ryokou shimashita.", "Saya bepergian ke Nara."),
        ("神奈川に住んでいます。", "Kanagawa ni sunde imasu.", "Saya tinggal di Kanagawa."),
    ]),
    ("shou6_n1", "傷", ["ショウ"], ["きず"], ["luka", "wound"], 13, "人", [
        ("傷", "kizu", "luka"),
        ("負傷", "fushou", "cedera"),
        ("傷つく", "kizutsuku", "terluka"),
    ], [
        ("傷ができました。", "Kizu ga dekimashita.", "Ada luka."),
        ("負傷しました。", "Fushou shimashita.", "Saya cedera."),
    ]),
    ("taku2_n1", "択", ["タク"], [], ["memilih", "choose"], 7, "手", [
        ("選択", "sentaku", "pilihan"),
        ("択一", "takuitsu", "pilih satu"),
        ("二者択一", "nisha takuitsu", "memilih satu dari dua"),
    ], [
        ("選択肢があります。", "Sentakushi ga arimasu.", "Ada pilihan."),
        ("二者択一です。", "Nisha takuitsu desu.", "Ini pilihan satu dari dua."),
    ]),
    ("shuu4_n1", "秀", ["シュウ"], ["ひい-でる"], ["unggul", "excellent"], 7, "禾", [
        ("優秀", "yuushuu", "unggul"),
        ("秀才", "shuusai", "orang jenius/berbakat"),
        ("秀でる", "hiideru", "unggul/menonjol"),
    ], [
        ("優秀な成績です。", "Yuushuu na seiseki desu.", "Ini nilai yang unggul."),
        ("秀才です。", "Shuusai desu.", "Dia orang yang berbakat."),
    ]),
    ("chou3_n1", "徴", ["チョウ"], [], ["tanda", "memungut", "sign"], 14, "彳", [
        ("特徴", "tokuchou", "ciri khas"),
        ("徴収", "choushuu", "pemungutan"),
        ("象徴", "shouchou", "simbol"),
    ], [
        ("特徴があります。", "Tokuchou ga arimasu.", "Ada ciri khasnya."),
        ("税金を徴収します。", "Zeikin o choushuu shimasu.", "Memungut pajak."),
    ]),
    ("dan_n1", "弾", ["ダン"], ["たま", "ひ-く", "はず-む"], ["peluru", "memainkan alat musik", "bullet"], 12, "弓", [
        ("弾丸", "dangan", "peluru"),
        ("爆弾", "bakudan", "bom"),
        ("弾く", "hiku", "memainkan alat musik petik"),
    ], [
        ("弾丸のようです。", "Dangan no you desu.", "Seperti peluru."),
        ("ピアノを弾きます。", "Piano o hikimasu.", "Saya bermain piano."),
    ]),
    ("shou7_n1", "償", ["ショウ"], ["つぐな-う"], ["mengganti rugi", "compensate"], 17, "人", [
        ("賠償", "baishou", "ganti rugi"),
        ("補償", "hoshou", "kompensasi"),
        ("弁償", "bensho", "ganti rugi"),
    ], [
        ("賠償金を払いました。", "Baishoukin o haraimashita.", "Saya membayar ganti rugi."),
        ("補償を受けました。", "Hoshou o ukemashita.", "Saya menerima kompensasi."),
    ]),
    ("kou7_n1", "功", ["コウ"], [], ["prestasi", "achievement"], 5, "力", [
        ("成功", "seikou", "keberhasilan"),
        ("功績", "kouseki", "jasa/prestasi"),
        ("功労", "kourou", "jasa/kontribusi"),
    ], [
        ("事業が成功しました。", "Jigyou ga seikou shimashita.", "Bisnisnya berhasil."),
        ("功績を称えました。", "Kouseki o tataemashita.", "Menghargai jasanya."),
    ]),
    ("kyo2_n1", "拠", ["キョ"], [], ["dasar", "base"], 8, "手", [
        ("根拠", "konkyo", "dasar/alasan"),
        ("拠点", "kyoten", "basis operasi"),
        ("証拠", "shouko", "bukti"),
    ], [
        ("根拠がありません。", "Konkyo ga arimasen.", "Tidak ada dasarnya."),
        ("拠点を移しました。", "Kyoten o utsushimashita.", "Memindahkan basis operasi."),
    ]),
    ("hi3_n1", "秘", ["ヒ"], ["ひ-める"], ["rahasia", "secret"], 10, "禾", [
        ("秘密", "himitsu", "rahasia"),
        ("秘書", "hisho", "sekretaris"),
        ("神秘", "shinpi", "misteri"),
    ], [
        ("秘書として働いています。", "Hisho toshite hataraite imasu.", "Saya bekerja sebagai sekretaris."),
        ("神秘的な場所です。", "Shinpiteki na basho desu.", "Ini tempat yang misterius."),
    ]),
    ("kyo3_n1", "拒", ["キョ"], ["こば-む"], ["menolak", "refuse"], 8, "手", [
        ("拒否", "kyohi", "penolakan"),
        ("拒む", "kobamu", "menolak"),
        ("拒絶", "kyozetsu", "penolakan keras"),
    ], [
        ("提案を拒否しました。", "Teian o kyohi shimashita.", "Menolak proposal."),
        ("拒絶反応です。", "Kyozetsu hannou desu.", "Ini reaksi penolakan."),
    ]),
    ("kei3_n1", "刑", ["ケイ"], [], ["hukuman", "punishment"], 6, "刀", [
        ("刑事", "keiji", "detektif/pidana"),
        ("刑罰", "keibatsu", "hukuman"),
        ("死刑", "shikei", "hukuman mati"),
    ], [
        ("刑事に話を聞かれました。", "Keiji ni hanashi o kikaremashita.", "Ditanyai oleh detektif."),
        ("死刑制度についてです。", "Shikei seido ni tsuite desu.", "Ini tentang sistem hukuman mati."),
    ]),
    ("tsuka_n1", "塚", [], ["つか"], ["gundukan tanah", "mound"], 12, "土", [
        ("貝塚", "kaizuka", "gundukan kerang (arkeologi)"),
        ("一里塚", "ichirizuka", "tonggak jarak"),
        ("塚", "tsuka", "gundukan/makam kecil"),
    ], [
        ("貝塚を発見しました。", "Kaizuka o hakken shimashita.", "Menemukan gundukan kerang."),
        ("塚があります。", "Tsuka ga arimasu.", "Ada gundukan."),
    ]),
    ("chi_n1", "致", ["チ"], ["いた-す"], ["menyebabkan", "sepenuhnya", "cause"], 10, "至", [
        ("一致", "icchi", "kesesuaian/kecocokan"),
        ("致命的", "chimeiteki", "fatal"),
        ("誘致", "yuuchi", "menarik investasi"),
    ], [
        ("意見が一致しました。", "Iken ga icchi shimashita.", "Pendapatnya sesuai."),
        ("致命的なミスです。", "Chimeiteki na misu desu.", "Ini kesalahan fatal."),
    ]),
    ("kuru_n1", "繰", [], ["く-る"], ["menggulung", "mengulang", "reel"], 19, "糸", [
        ("繰り返す", "kurikaesu", "mengulangi"),
        ("繰り上げる", "kuriageru", "memajukan jadwal"),
        ("繰り出す", "kuridasu", "keluar beramai-ramai"),
    ], [
        ("何度も繰り返しました。", "Nando mo kurikaeshimashita.", "Saya mengulanginya berkali-kali."),
        ("予定を繰り上げました。", "Yotei o kuriagemashita.", "Saya memajukan jadwal."),
    ]),
    ("bi_n1", "尾", ["ビ"], ["お"], ["ekor", "tail"], 7, "尸", [
        ("尾", "o", "ekor"),
        ("尻尾", "shippo", "ekor"),
        ("語尾", "gobi", "akhiran kata"),
    ], [
        ("犬の尾を触りました。", "Inu no o o sawarimashita.", "Saya menyentuh ekor anjing."),
        ("語尾を上げます。", "Gobi o agemasu.", "Menaikkan nada di akhir kata."),
    ]),
    ("byou_n1", "描", ["ビョウ"], ["えが-く", "か-く"], ["menggambar", "draw"], 11, "手", [
        ("描く", "egaku", "menggambar"),
        ("描写", "byousha", "penggambaran"),
        ("素描", "sobyou", "sketsa"),
    ], [
        ("絵を描きました。", "E o egakimashita.", "Saya menggambar."),
        ("詳しく描写しました。", "Kuwashiku byousha shimashita.", "Menggambarkan secara detail."),
    ]),
    ("rei_n1", "鈴", ["レイ", "リン"], ["すず"], ["lonceng", "bell"], 13, "金", [
        ("鈴", "suzu", "lonceng"),
        ("鈴木", "Suzuki", "nama keluarga"),
        ("風鈴", "fuurin", "lonceng angin"),
    ], [
        ("鈴の音が聞こえます。", "Suzu no oto ga kikoemasu.", "Terdengar suara lonceng."),
        ("風鈴を飾りました。", "Fuurin o kazarimashita.", "Saya menghias lonceng angin."),
    ]),
    ("ban_n1", "盤", ["バン"], [], ["papan", "piringan", "board"], 15, "皿", [
        ("基盤", "kiban", "fondasi/basis"),
        ("盤石", "banjaku", "sangat kokoh"),
        ("円盤", "enban", "cakram/piringan"),
    ], [
        ("経済基盤です。", "Keizai kiban desu.", "Ini fondasi ekonomi."),
        ("円盤投げの選手です。", "Enban nage no senshu desu.", "Dia atlet lempar cakram."),
    ]),
    ("kou8_n1", "項", ["コウ"], [], ["pasal", "item", "clause"], 12, "頁", [
        ("項目", "koumoku", "item"),
        ("事項", "jikou", "hal/perkara"),
        ("要項", "youkou", "garis besar/petunjuk"),
    ], [
        ("項目を確認しました。", "Koumoku o kakunin shimashita.", "Saya memeriksa item."),
        ("注意事項です。", "Chuui jikou desu.", "Ini hal yang perlu diperhatikan."),
    ]),
    ("sou3_n1", "喪", ["ソウ"], ["も"], ["berkabung", "mourning"], 12, "口", [
        ("喪失", "soushitsu", "kehilangan"),
        ("喪服", "mofuku", "pakaian berkabung"),
        ("喪中", "mochuu", "masa berkabung"),
    ], [
        ("自信を喪失しました。", "Jishin o soushitsu shimashita.", "Saya kehilangan kepercayaan diri."),
        ("喪服を着ました。", "Mofuku o kimashita.", "Saya memakai pakaian berkabung."),
    ]),
    ("han_n1", "伴", ["ハン", "バン"], ["ともな-う"], ["menyertai", "accompany"], 7, "人", [
        ("伴う", "tomonau", "menyertai/disertai"),
        ("同伴", "douhan", "ditemani"),
        ("伴奏", "bansou", "iringan musik"),
    ], [
        ("リスクを伴います。", "Risuku o tomonaimasu.", "Disertai risiko."),
        ("ピアノの伴奏です。", "Piano no bansou desu.", "Ini iringan piano."),
    ]),
    ("you_n1", "養", ["ヨウ"], ["やしな-う"], ["memelihara", "nurture"], 15, "食", [
        ("養う", "yashinau", "memelihara/menafkahi"),
        ("栄養", "eiyou", "nutrisi"),
        ("教養", "kyouyou", "wawasan/edukasi"),
    ], [
        ("家族を養っています。", "Kazoku o yashinatte imasu.", "Saya menafkahi keluarga."),
        ("教養がある人です。", "Kyouyou ga aru hito desu.", "Dia orang yang berwawasan."),
    ]),
    ("ken6_n1", "懸", ["ケン"], ["か-ける", "か-かる"], ["menggantungkan", "hang"], 20, "心", [
        ("懸命", "kenmei", "sekuat tenaga"),
        ("懸念", "kenen", "kekhawatiran"),
        ("懸賞", "kenshou", "hadiah undian"),
    ], [
        ("懸命に頑張りました。", "Kenmei ni ganbarimashita.", "Berusaha sekuat tenaga."),
        ("懸念があります。", "Kenen ga arimasu.", "Ada kekhawatiran."),
    ]),
    ("gai_n1", "街", ["ガイ"], ["まち"], ["kota", "jalan", "town"], 12, "行", [
        ("街", "machi", "kota"),
        ("商店街", "shoutengai", "area pertokoan"),
        ("街灯", "gaitou", "lampu jalan"),
    ], [
        ("街を歩きました。", "Machi o arukimashita.", "Saya berjalan di kota."),
        ("商店街で買い物をしました。", "Shoutengai de kaimono o shimashita.", "Saya berbelanja di area pertokoan."),
    ]),
    ("kei4_n1", "契", ["ケイ"], ["ちぎ-る"], ["janji", "pledge"], 9, "大", [
        ("契約", "keiyaku", "kontrak"),
        ("契機", "keiki", "momen penting/pemicu"),
        ("契約書", "keiyakusho", "dokumen kontrak"),
    ], [
        ("契約を結びました。", "Keiyaku o musubimashita.", "Menandatangani kontrak."),
        ("契約書にサインしました。", "Keiyakusho ni sain shimashita.", "Menandatangani dokumen kontrak."),
    ]),
    ("kei5_n1", "掲", ["ケイ"], ["かか-げる"], ["memasang", "memuat", "post"], 11, "手", [
        ("掲示", "keiji", "pengumuman"),
        ("掲載", "keisai", "publikasi"),
        ("掲げる", "kakageru", "mengangkat/menampilkan"),
    ], [
        ("掲示板を見ました。", "Keijiban o mimashita.", "Saya melihat papan pengumuman."),
        ("目標を掲げました。", "Mokuhyou o kakagemashita.", "Menetapkan tujuan."),
    ]),
    ("yaku_n1", "躍", ["ヤク"], ["おど-る"], ["melompat", "aktif", "leap"], 21, "足", [
        ("活躍", "katsuyaku", "aktivitas/kiprah"),
        ("躍動", "yakudou", "dinamisme"),
        ("飛躍", "hiyaku", "lompatan kemajuan"),
    ], [
        ("大いに活躍しました。", "Ooi ni katsuyaku shimashita.", "Sangat berkiprah/aktif."),
        ("飛躍的に成長しました。", "Hiyakuteki ni seichou shimashita.", "Tumbuh secara pesat."),
    ]),
    ("ki5_n1", "棄", ["キ"], [], ["membuang", "meninggalkan", "abandon"], 13, "木", [
        ("放棄", "houki", "pelepasan/pengunduran"),
        ("廃棄", "haiki", "pembuangan"),
        ("棄権", "kiken", "mengundurkan diri dari kompetisi"),
    ], [
        ("権利を放棄しました。", "Kenri o houki shimashita.", "Saya melepaskan hak."),
        ("試合を棄権しました。", "Shiai o kiken shimashita.", "Saya mengundurkan diri dari pertandingan."),
    ]),
    ("tei3_n1", "邸", ["テイ"], [], ["kediaman", "residence"], 8, "邑", [
        ("邸宅", "teitaku", "kediaman mewah"),
        ("私邸", "shitei", "kediaman pribadi"),
        ("官邸", "kantei", "kediaman resmi pejabat"),
    ], [
        ("大きい邸宅です。", "Ookii teitaku desu.", "Ini kediaman mewah yang besar."),
        ("首相官邸です。", "Shushou kantei desu.", "Ini kediaman resmi perdana menteri."),
    ]),
    ("shuku_n1", "縮", ["シュク"], ["ちぢ-む", "ちぢ-める"], ["menyusut", "shrink"], 17, "糸", [
        ("縮小", "shukushou", "pengecilan/penyusutan"),
        ("短縮", "tanshuku", "pemendekan"),
        ("縮む", "chijimu", "menyusut"),
    ], [
        ("予算を縮小しました。", "Yosan o shukushou shimashita.", "Mengurangi anggaran."),
        ("時間を短縮しました。", "Jikan o tanshuku shimashita.", "Mempersingkat waktu."),
    ]),
    ("kan11_n1", "還", ["カン"], [], ["kembali", "return"], 16, "辵", [
        ("返還", "henkan", "pengembalian"),
        ("帰還", "kikan", "kepulangan"),
        ("生還", "seikan", "selamat kembali"),
    ], [
        ("土地を返還しました。", "Tochi o henkan shimashita.", "Mengembalikan tanah."),
        ("無事に帰還しました。", "Buji ni kikan shimashita.", "Kembali dengan selamat."),
    ]),
    ("zoku_n1", "属", ["ゾク"], [], ["termasuk", "belong"], 12, "尸", [
        ("所属", "shozoku", "keanggotaan/afiliasi"),
        ("属する", "zokusuru", "termasuk/berada di bawah"),
        ("金属", "kinzoku", "logam"),
    ], [
        ("どこに所属していますか。", "Doko ni shozoku shite imasu ka.", "Anda berafiliasi di mana?"),
        ("金属でできています。", "Kinzoku de dekite imasu.", "Terbuat dari logam."),
    ]),
    ("ryo_n1", "慮", ["リョ"], [], ["mempertimbangkan", "consider"], 15, "心", [
        ("考慮", "kouryo", "pertimbangan"),
        ("配慮", "hairyo", "perhatian/kepedulian"),
        ("遠慮", "enryo", "sungkan/menahan diri"),
    ], [
        ("考慮してください。", "Kouryo shite kudasai.", "Tolong pertimbangkan."),
        ("遠慮しないでください。", "Enryo shinaide kudasai.", "Jangan sungkan."),
    ]),
    ("waku2_n1", "枠", [], ["わく"], ["bingkai", "kerangka", "frame"], 8, "木", [
        ("枠", "waku", "bingkai/kerangka"),
        ("枠組み", "wakugumi", "kerangka kerja"),
        ("窓枠", "madowaku", "bingkai jendela"),
    ], [
        ("予算の枠内で行います。", "Yosan no wakunai de okonaimasu.", "Dilakukan dalam batas anggaran."),
        ("窓枠を修理しました。", "Madowaku o shuuri shimashita.", "Memperbaiki bingkai jendela."),
    ]),
    ("kei6_n1", "恵", ["ケイ", "エ"], ["めぐ-む"], ["berkah", "kebijaksanaan", "blessing"], 10, "心", [
        ("恵む", "megumu", "memberi berkah/sedekah"),
        ("知恵", "chie", "kebijaksanaan"),
        ("恩恵", "onkei", "anugerah/manfaat"),
    ], [
        ("知恵を貸してください。", "Chie o kashite kudasai.", "Tolong berikan saran."),
        ("恩恵を受けました。", "Onkei o ukemashita.", "Menerima anugerah."),
    ]),
    ("ro_n1", "露", ["ロ", "ロウ"], ["つゆ"], ["embun", "mengekspos", "dew"], 21, "雨", [
        ("露出", "roshutsu", "paparan/eksposur"),
        ("露天", "roten", "terbuka tanpa atap"),
        ("朝露", "asatsuyu", "embun pagi"),
    ], [
        ("肌の露出が多いです。", "Hada no roshutsu ga ooi desu.", "Banyak kulit yang terekspos."),
        ("朝露が輝いています。", "Asatsuyu ga kagayaite imasu.", "Embun pagi berkilau."),
    ]),
    ("oki_n1", "沖", ["チュウ"], ["おき"], ["lepas pantai", "offshore"], 7, "水", [
        ("沖縄", "Okinawa", "nama prefektur"),
        ("沖", "oki", "lepas pantai"),
        ("沖合", "okiai", "di lepas pantai"),
    ], [
        ("沖縄へ旅行しました。", "Okinawa e ryokou shimashita.", "Saya bepergian ke Okinawa."),
        ("沖に船が見えます。", "Oki ni fune ga miemasu.", "Terlihat kapal di lepas pantai."),
    ]),
    ("kan12_n1", "緩", ["カン"], ["ゆる-い", "ゆる-む"], ["longgar", "loose"], 15, "糸", [
        ("緩い", "yurui", "longgar"),
        ("緩和", "kanwa", "pelonggaran/mitigasi"),
        ("緩やか", "yuruyaka", "landai/perlahan"),
    ], [
        ("ズボンが緩いです。", "Zubon ga yurui desu.", "Celananya longgar."),
        ("規制を緩和しました。", "Kisei o kanwa shimashita.", "Melonggarkan regulasi."),
    ]),
    ("setsu_n1", "節", ["セツ"], ["ふし"], ["musim", "ruas", "season"], 13, "竹", [
        ("季節", "kisetsu", "musim"),
        ("節約", "setsuyaku", "penghematan"),
        ("関節", "kansetsu", "sendi"),
    ], [
        ("節約しています。", "Setsuyaku shite imasu.", "Saya berhemat."),
        ("関節が痛いです。", "Kansetsu ga itai desu.", "Sendinya sakit."),
    ]),
    ("ju2_n1", "需", ["ジュ"], [], ["permintaan", "demand"], 14, "雨", [
        ("需要", "juyou", "permintaan"),
        ("必需品", "hitsujuhin", "kebutuhan pokok"),
        ("内需", "naiju", "permintaan domestik"),
    ], [
        ("需要が増えています。", "Juyou ga fuete imasu.", "Permintaannya meningkat."),
        ("必需品を買いました。", "Hitsujuhin o kaimashita.", "Saya membeli kebutuhan pokok."),
    ]),
    ("sha_n1", "射", ["シャ"], ["い-る"], ["menembak", "shoot"], 10, "寸", [
        ("注射", "chuusha", "suntikan"),
        ("発射", "hassha", "peluncuran"),
        ("反射", "hansha", "refleksi/pantulan"),
    ], [
        ("注射をしました。", "Chuusha o shimashita.", "Saya disuntik."),
        ("ロケットが発射されました。", "Roketto ga hassha saremashita.", "Roket diluncurkan."),
    ]),
    ("kou9_n1", "購", ["コウ"], [], ["membeli", "purchase"], 17, "貝", [
        ("購入", "kounyuu", "pembelian"),
        ("購買", "koubai", "pembelian"),
        ("購読", "koudoku", "berlangganan"),
    ], [
        ("新車を購入しました。", "Shinsha o kounyuu shimashita.", "Saya membeli mobil baru."),
        ("雑誌を購読しています。", "Zasshi o koudoku shite imasu.", "Saya berlangganan majalah."),
    ]),
    ("ki6_n1", "揮", ["キ"], [], ["mengerahkan", "wield"], 12, "手", [
        ("発揮", "hakki", "menunjukkan kemampuan"),
        ("指揮", "shiki", "komando/dirigen"),
        ("指揮者", "shikisha", "konduktor"),
    ], [
        ("実力を発揮しました。", "Jitsuryoku o hakki shimashita.", "Menunjukkan kemampuan sesungguhnya."),
        ("指揮者が指導しました。", "Shikisha ga shidou shimashita.", "Konduktor memberi arahan."),
    ]),
    ("juu2_n1", "充", ["ジュウ"], ["あ-てる"], ["mengisi", "fill"], 6, "儿", [
        ("充実", "juujitsu", "memuaskan/lengkap"),
        ("充電", "juuden", "pengisian daya"),
        ("補充", "hojuu", "penambahan/pengisian ulang"),
    ], [
        ("充実した生活です。", "Juujitsu shita seikatsu desu.", "Ini kehidupan yang memuaskan."),
        ("スマホを充電しました。", "Sumaho o juuden shimashita.", "Saya mengisi daya ponsel."),
    ]),
    ("kou10_n1", "貢", ["コウ"], ["みつ-ぐ"], ["berkontribusi", "tribute"], 10, "貝", [
        ("貢献", "kouken", "kontribusi"),
        ("年貢", "nengu", "pajak tahunan (historis)"),
        ("貢ぐ", "mitsugu", "memberi upeti/mendanai"),
    ], [
        ("会社に貢献しています。", "Kaisha ni kouken shite imasu.", "Berkontribusi pada perusahaan."),
        ("年貢を納めました。", "Nengu o osamemashita.", "Membayar pajak tahunan."),
    ]),
    ("ka3_n1", "鹿", ["ロク"], ["しか"], ["rusa", "deer"], 11, "鹿", [
        ("鹿", "shika", "rusa"),
        ("鹿児島", "Kagoshima", "nama prefektur"),
        ("馬鹿", "baka", "bodoh"),
    ], [
        ("鹿を見ました。", "Shika o mimashita.", "Saya melihat rusa."),
        ("鹿児島へ旅行しました。", "Kagoshima e ryokou shimashita.", "Saya bepergian ke Kagoshima."),
    ]),
    ("kyaku_n1", "却", ["キャク"], [], ["menolak", "reject"], 7, "卩", [
        ("却下", "kyakka", "penolakan"),
        ("返却", "henkyaku", "pengembalian"),
        ("冷却", "reikyaku", "pendinginan"),
    ], [
        ("申請が却下されました。", "Shinsei ga kyakka saremashita.", "Aplikasi ditolak."),
        ("本を返却しました。", "Hon o henkyaku shimashita.", "Saya mengembalikan buku."),
    ]),
    ("tan_n1", "端", ["タン"], ["はし", "はた", "は"], ["ujung", "edge"], 14, "立", [
        ("端", "hashi", "ujung"),
        ("極端", "kyokutan", "ekstrem"),
        ("端末", "tanmatsu", "terminal/perangkat"),
    ], [
        ("道の端を歩きました。", "Michi no hashi o arukimashita.", "Saya berjalan di ujung jalan."),
        ("端末を使いました。", "Tanmatsu o tsukaimashita.", "Saya menggunakan perangkat terminal."),
    ]),
    ("chin_n1", "賃", ["チン"], [], ["upah", "ongkos", "wage"], 13, "貝", [
        ("賃金", "chingin", "upah"),
        ("家賃", "yachin", "sewa rumah"),
        ("運賃", "unchin", "ongkos transportasi"),
    ], [
        ("賃金が上がりました。", "Chingin ga agarimashita.", "Upahnya naik."),
        ("家賃を払いました。", "Yachin o haraimashita.", "Saya membayar sewa."),
    ]),
    ("kaku4_n1", "獲", ["カク"], ["え-る"], ["memperoleh", "capture"], 16, "犬", [
        ("獲得", "kakutoku", "perolehan"),
        ("捕獲", "hokaku", "penangkapan"),
        ("獲物", "emono", "mangsa/hasil buruan"),
    ], [
        ("金メダルを獲得しました。", "Kin medaru o kakutoku shimashita.", "Meraih medali emas."),
        ("獲物を捕まえました。", "Emono o tsukamaemashita.", "Menangkap mangsa."),
    ]),
    ("gun_n1", "郡", ["グン"], [], ["distrik", "county"], 10, "邑", [
        ("郡部", "gunbu", "wilayah kabupaten"),
        ("郡", "gun", "distrik/kabupaten"),
        ("郡山", "Koriyama", "nama kota"),
    ], [
        ("郡部に住んでいます。", "Gunbu ni sunde imasu.", "Saya tinggal di daerah kabupaten."),
        ("郡山市出身です。", "Koriyama-shi shusshin desu.", "Saya berasal dari kota Koriyama."),
    ]),
    ("hei_n1", "併", ["ヘイ"], ["あわ-せる"], ["menggabungkan", "combine"], 8, "人", [
        ("合併", "gappei", "penggabungan/merger"),
        ("併用", "heiyou", "penggunaan bersama"),
        ("併設", "heisetsu", "didirikan bersama"),
    ], [
        ("会社が合併しました。", "Kaisha ga gappei shimashita.", "Perusahaan melakukan merger."),
        ("薬を併用しないでください。", "Kusuri o heiyou shinaide kudasai.", "Jangan menggunakan obat bersamaan."),
    ]),
    ("tetsu2_n1", "徹", ["テツ"], [], ["menyeluruh", "thorough"], 15, "彳", [
        ("徹底", "tettei", "menyeluruh/tuntas"),
        ("徹夜", "tetsuya", "begadang semalaman"),
        ("貫徹", "kantetsu", "mewujudkan sepenuhnya"),
    ], [
        ("徹夜で勉強しました。", "Tetsuya de benkyou shimashita.", "Saya belajar begadang semalaman."),
        ("目標を貫徹しました。", "Mokuhyou o kantetsu shimashita.", "Mewujudkan tujuan sepenuhnya."),
    ]),
    ("ki7_n1", "貴", ["キ"], ["とうと-い", "たっと-い"], ["berharga", "mulia", "precious"], 12, "貝", [
        ("貴重", "kichou", "berharga"),
        ("貴族", "kizoku", "bangsawan"),
        ("貴社", "kisha", "perusahaan Anda (formal)"),
    ], [
        ("貴重な経験でした。", "Kichou na keiken deshita.", "Itu pengalaman yang berharga."),
        ("貴族の生活です。", "Kizoku no seikatsu desu.", "Ini kehidupan bangsawan."),
    ]),
    ("saki2_n1", "埼", [], ["さき"], ["tanjung", "cape"], 11, "土", [
        ("埼玉", "Saitama", "nama prefektur"),
        ("埼玉県", "Saitama-ken", "Prefektur Saitama"),
        ("埼玉県民", "Saitama kenmin", "penduduk Prefektur Saitama"),
    ], [
        ("埼玉県に住んでいます。", "Saitama-ken ni sunde imasu.", "Saya tinggal di Prefektur Saitama."),
        ("埼玉県民です。", "Saitama kenmin desu.", "Saya penduduk Prefektur Saitama."),
    ]),
    ("shou8_n1", "衝", ["ショウ"], [], ["bertabrakan", "penting", "collide"], 15, "行", [
        ("衝突", "shoutotsu", "tabrakan"),
        ("衝撃", "shougeki", "kejutan/dampak"),
        ("要衝", "youshou", "posisi strategis"),
    ], [
        ("車が衝突しました。", "Kuruma ga shoutotsu shimashita.", "Mobil bertabrakan."),
        ("要衝の地です。", "Youshou no chi desu.", "Ini lokasi strategis."),
    ]),
    ("shou9_n1", "焦", ["ショウ"], ["こ-げる", "あせ-る"], ["gosong", "gelisah", "burn"], 12, "火", [
        ("焦げる", "kogeru", "gosong"),
        ("焦る", "aseru", "gelisah/terburu-buru"),
        ("焦点", "shouten", "titik fokus"),
    ], [
        ("パンが焦げました。", "Pan ga kogemashita.", "Rotinya gosong."),
        ("焦らないでください。", "Aseranaide kudasai.", "Jangan terburu-buru."),
    ]),
    ("datsu2_n1", "奪", ["ダツ"], ["うば-う"], ["merampas", "steal"], 14, "大", [
        ("奪う", "ubau", "merampas"),
        ("略奪", "ryakudatsu", "penjarahan"),
        ("争奪", "soudatsu", "perebutan"),
    ], [
        ("財布を奪われました。", "Saifu o ubawaremashita.", "Dompet saya dirampas."),
        ("優勝を争奪しました。", "Yuushou o soudatsu shimashita.", "Memperebutkan gelar juara."),
    ]),
    ("sai5_n1", "災", ["サイ"], ["わざわ-い"], ["bencana", "disaster"], 7, "火", [
        ("災害", "saigai", "bencana"),
        ("火災", "kasai", "kebakaran"),
        ("天災", "tensai", "bencana alam"),
    ], [
        ("災害に備えましょう。", "Saigai ni sonaemashou.", "Mari bersiap menghadapi bencana."),
        ("火災が発生しました。", "Kasai ga hassei shimashita.", "Terjadi kebakaran."),
    ]),
    ("ho_n1", "浦", ["ホ"], ["うら"], ["teluk", "bay"], 10, "水", [
        ("浦", "ura", "teluk kecil"),
        ("三浦", "Miura", "nama tempat"),
        ("浦島太郎", "Urashima Tarou", "tokoh dongeng"),
    ], [
        ("浦で釣りをしました。", "Ura de tsuri o shimashita.", "Saya memancing di teluk."),
        ("浦島太郎の話です。", "Urashima Tarou no hanashi desu.", "Ini cerita Urashima Tarou."),
    ]),
    ("seki_n1", "析", ["セキ"], [], ["menganalisis", "analyze"], 8, "木", [
        ("分析", "bunseki", "analisis"),
        ("解析", "kaiseki", "analisis/parsing"),
        ("データ分析", "deeta bunseki", "analisis data"),
    ], [
        ("データを分析しました。", "Deeta o bunseki shimashita.", "Saya menganalisis data."),
        ("解析結果です。", "Kaiseki kekka desu.", "Ini hasil analisis."),
    ]),
    ("jou2_n1", "譲", ["ジョウ"], ["ゆず-る"], ["mengalah", "menyerahkan", "yield"], 20, "言", [
        ("譲る", "yuzuru", "mengalah/memberikan"),
        ("譲渡", "jouto", "transfer/pengalihan"),
        ("謙譲語", "kenjougo", "bahasa merendah"),
    ], [
        ("席を譲りました。", "Seki o yuzurimashita.", "Saya memberikan tempat duduk."),
        ("財産を譲渡しました。", "Zaisan o jouto shimashita.", "Mengalihkan harta."),
    ]),
    ("shou10_n1", "称", ["ショウ"], [], ["menyebut", "memuji", "name"], 10, "禾", [
        ("名称", "meishou", "nama resmi"),
        ("称賛", "shousan", "pujian"),
        ("対称", "taishou", "simetri"),
    ], [
        ("正式な名称です。", "Seishiki na meishou desu.", "Ini nama resminya."),
        ("称賛を受けました。", "Shousan o ukemashita.", "Menerima pujian."),
    ]),
    ("nou_n1", "納", ["ノウ"], ["おさ-める"], ["membayar", "menyimpan", "pay"], 10, "糸", [
        ("納税", "nouzei", "pembayaran pajak"),
        ("納得", "nattoku", "pemahaman/persetujuan"),
        ("収納", "shuunou", "penyimpanan"),
    ], [
        ("納税しました。", "Nouzei shimashita.", "Saya membayar pajak."),
        ("納得しました。", "Nattoku shimashita.", "Saya mengerti/setuju."),
    ]),
    ("ju3_n1", "樹", ["ジュ"], ["き"], ["pohon", "tree"], 16, "木", [
        ("樹木", "jumoku", "pohon"),
        ("街路樹", "gairoju", "pohon pinggir jalan"),
        ("樹立", "juritsu", "mendirikan/mencetak rekor"),
    ], [
        ("樹木が多いです。", "Jumoku ga ooi desu.", "Banyak pohon."),
        ("新記録を樹立しました。", "Shin kiroku o juritsu shimashita.", "Mencetak rekor baru."),
    ]),
    ("chou4_n1", "挑", ["チョウ"], ["いど-む"], ["menantang", "challenge"], 9, "手", [
        ("挑戦", "chousen", "tantangan"),
        ("挑む", "idomu", "menantang"),
        ("挑発", "chouhatsu", "provokasi"),
    ], [
        ("新しいことに挑戦しました。", "Atarashii koto ni chousen shimashita.", "Saya menantang hal baru."),
        ("挑発しないでください。", "Chouhatsu shinaide kudasai.", "Jangan memprovokasi."),
    ]),
    ("yuu3_n1", "誘", ["ユウ"], ["さそ-う"], ["mengundang", "invite"], 14, "言", [
        ("誘う", "sasou", "mengajak"),
        ("誘惑", "yuuwaku", "godaan"),
        ("勧誘", "kan'yuu", "ajakan/promosi"),
    ], [
        ("友達を誘いました。", "Tomodachi o sasoimashita.", "Saya mengajak teman."),
        ("勧誘されました。", "Kan'yuu saremashita.", "Saya diajak/dipromosikan."),
    ]),
    ("fun_n1", "紛", ["フン"], ["まぎ-れる"], ["kacau", "sengketa", "confuse"], 10, "糸", [
        ("紛争", "funsou", "konflik/sengketa"),
        ("紛失", "funshitsu", "kehilangan"),
        ("紛らわしい", "magirawashii", "membingungkan"),
    ], [
        ("紛争が続いています。", "Funsou ga tsuzuite imasu.", "Konfliknya berlanjut."),
        ("パスポートを紛失しました。", "Pasupooto o funshitsu shimashita.", "Saya kehilangan paspor."),
    ]),
    ("shi8_n1", "至", ["シ"], ["いた-る"], ["mencapai", "sangat", "arrive"], 6, "至", [
        ("至る", "itaru", "mencapai/menuju"),
        ("至急", "shikyuu", "segera/mendesak"),
        ("必至", "hisshi", "pasti terjadi"),
    ], [
        ("結論に至りました。", "Ketsuron ni itarimashita.", "Mencapai kesimpulan."),
        ("至急対応してください。", "Shikyuu taiou shite kudasai.", "Tolong tangani segera."),
    ]),
    ("shuu5_n1", "宗", ["シュウ", "ソウ"], [], ["agama", "aliran", "religion"], 8, "宀", [
        ("宗教", "shuukyou", "agama"),
        ("宗派", "shuuha", "sekte/aliran"),
        ("改宗", "kaishuu", "konversi agama"),
    ], [
        ("宗教に興味があります。", "Shuukyou ni kyoumi ga arimasu.", "Saya tertarik dengan agama."),
        ("宗派が違います。", "Shuuha ga chigaimasu.", "Alirannya berbeda."),
    ]),
    ("soku_n1", "促", ["ソク"], ["うなが-す"], ["mendorong", "urge"], 9, "人", [
        ("促す", "unagasu", "mendorong/menganjurkan"),
        ("催促", "saisoku", "desakan"),
        ("促進", "sokushin", "promosi/pendorongan"),
    ], [
        ("行動を促しました。", "Koudou o unagashimashita.", "Mendorong tindakan."),
        ("経済を促進しました。", "Keizai o sokushin shimashita.", "Mendorong ekonomi."),
    ]),
    ("shin3_n1", "慎", ["シン"], ["つつし-む"], ["berhati-hati", "prudent"], 13, "心", [
        ("慎重", "shinchou", "hati-hati/cermat"),
        ("慎む", "tsutsushimu", "menahan diri/berhati-hati"),
        ("不謹慎", "fukinshin", "tidak sopan/ceroboh"),
    ], [
        ("慎重に考えました。", "Shinchou ni kangaemashita.", "Berpikir dengan hati-hati."),
        ("言葉を慎みました。", "Kotoba o tsutsushimimashita.", "Menahan diri dalam berkata."),
    ]),
    ("kou11_n1", "控", ["コウ"], ["ひか-える"], ["menahan diri", "mencatat", "refrain"], 11, "手", [
        ("控える", "hikaeru", "menahan diri/mencatat"),
        ("控除", "koujo", "potongan/deduksi"),
        ("控室", "hikaeshitsu", "ruang tunggu"),
    ], [
        ("塩分を控えています。", "Enbun o hikaete imasu.", "Saya membatasi garam."),
        ("税金の控除です。", "Zeikin no koujo desu.", "Ini potongan pajak."),
    ]),
    ("chi2_n1", "智", ["チ"], [], ["kebijaksanaan", "wisdom"], 12, "日", [
        ("智恵", "chie", "kebijaksanaan"),
        ("機智", "kichi", "kecerdikan"),
        ("理智", "richi", "akal sehat/rasionalitas"),
    ], [
        ("智恵を絞りました。", "Chie o shiborimashita.", "Memeras otak/berpikir keras."),
        ("機智に富んだ人です。", "Kichi ni tonda hito desu.", "Dia orang yang cerdik."),
    ]),
    ("aku_n1", "握", ["アク"], ["にぎ-る"], ["menggenggam", "grip"], 12, "手", [
        ("握る", "nigiru", "menggenggam"),
        ("握手", "akushu", "jabat tangan"),
        ("掌握", "shouaku", "penguasaan"),
    ], [
        ("手を握りました。", "Te o nigirimashita.", "Saya menggenggam tangan."),
        ("握手しましょう。", "Akushu shimashou.", "Mari bersalaman."),
    ]),
    ("chuu_n1", "宙", ["チュウ"], [], ["angkasa", "space"], 8, "宀", [
        ("宇宙", "uchuu", "alam semesta"),
        ("宙返り", "chuugaeri", "salto"),
        ("宙に浮く", "chuu ni uku", "mengambang di udara"),
    ], [
        ("宇宙飛行士になりたいです。", "Uchuu hikoushi ni naritai desu.", "Saya ingin menjadi astronot."),
        ("宙返りをしました。", "Chuugaeri o shimashita.", "Melakukan salto."),
    ]),
    ("shun_n1", "俊", ["シュン"], [], ["berbakat", "talented"], 9, "人", [
        ("俊敏", "shunbin", "gesit/cekatan"),
        ("俊才", "shunsai", "orang berbakat"),
        ("俊足", "shunsoku", "kaki cepat/pelari cepat"),
    ], [
        ("俊敏に動きました。", "Shunbin ni ugokimashita.", "Bergerak dengan gesit."),
        ("俊足の選手です。", "Shunsoku no senshu desu.", "Dia atlet yang cepat."),
    ]),
    ("sen4_n1", "銭", ["セン"], ["ぜに"], ["uang receh", "coin"], 14, "金", [
        ("金銭", "kinsen", "uang"),
        ("銭湯", "sentou", "pemandian umum"),
        ("小銭", "kozeni", "uang receh"),
    ], [
        ("金銭問題です。", "Kinsen mondai desu.", "Ini masalah uang."),
        ("小銭がありません。", "Kozeni ga arimasen.", "Tidak ada uang receh."),
    ]),
    ("juu3_n1", "渋", ["ジュウ"], ["しぶ-い", "しぶ-る"], ["sepat", "enggan", "astringent"], 11, "水", [
        ("渋滞", "juutai", "kemacetan"),
        ("渋い", "shibui", "sepat/keren dengan gaya klasik"),
        ("渋谷", "Shibuya", "nama tempat"),
    ], [
        ("渋滞に巻き込まれました。", "Juutai ni makikomaremashita.", "Terjebak macet."),
        ("渋谷で会いましょう。", "Shibuya de aimashou.", "Ayo bertemu di Shibuya."),
    ]),
    ("juu4_n1", "銃", ["ジュウ"], [], ["senapan", "gun"], 14, "金", [
        ("銃", "juu", "senjata api"),
        ("拳銃", "kenjuu", "pistol"),
        ("銃声", "juusei", "suara tembakan"),
    ], [
        ("銃を持っています。", "Juu o motte imasu.", "Dia memegang senjata."),
        ("銃声が聞こえました。", "Juusei ga kikoemashita.", "Terdengar suara tembakan."),
    ]),
    ("sou4_n1", "操", ["ソウ"], ["あやつ-る", "みさお"], ["mengoperasikan", "operate"], 16, "手", [
        ("操作", "sousa", "pengoperasian"),
        ("体操", "taisou", "senam"),
        ("操る", "ayatsuru", "memanipulasi/mengendalikan"),
    ], [
        ("機械を操作しました。", "Kikai o sousa shimashita.", "Mengoperasikan mesin."),
        ("体操をしました。", "Taisou o shimashita.", "Melakukan senam."),
    ]),
    ("kei7_n1", "携", ["ケイ"], ["たずさ-える", "たずさ-わる"], ["membawa", "carry"], 13, "手", [
        ("携帯", "keitai", "membawa/ponsel"),
        ("携わる", "tazusawaru", "terlibat dalam"),
        ("連携", "renkei", "kerjasama/koordinasi"),
    ], [
        ("携帯電話を持っています。", "Keitai denwa o motte imasu.", "Saya membawa ponsel."),
        ("連携して働きます。", "Renkei shite hatarakimasu.", "Bekerja secara berkoordinasi."),
    ]),
    ("shin4_n1", "診", ["シン"], ["み-る"], ["mendiagnosis", "diagnose"], 12, "言", [
        ("診察", "shinsatsu", "pemeriksaan medis"),
        ("診断", "shindan", "diagnosis"),
        ("受診", "jushin", "menjalani pemeriksaan"),
    ], [
        ("診察を受けました。", "Shinsatsu o ukemashita.", "Saya menjalani pemeriksaan."),
        ("診断結果です。", "Shindan kekka desu.", "Ini hasil diagnosis."),
    ]),
    ("taku3_n1", "託", ["タク"], [], ["mempercayakan", "entrust"], 10, "言", [
        ("委託", "itaku", "konsinyasi/dipercayakan"),
        ("信託", "shintaku", "kepercayaan/trust"),
        ("託児所", "takujisho", "tempat penitipan anak"),
    ], [
        ("業務を委託しました。", "Gyoumu o itaku shimashita.", "Mempercayakan tugas."),
        ("託児所に預けました。", "Takujisho ni azukemashita.", "Menitipkan di tempat penitipan anak."),
    ]),
    ("satsu_n1", "撮", ["サツ"], ["と-る"], ["memotret", "photograph"], 15, "手", [
        ("撮影", "satsuei", "pengambilan foto/gambar"),
        ("撮る", "toru", "memotret"),
        ("空撮", "kuusatsu", "foto udara"),
    ], [
        ("写真を撮りました。", "Shashin o torimashita.", "Saya mengambil foto."),
        ("空撮映像です。", "Kuusatsu eizou desu.", "Ini rekaman foto udara."),
    ]),
    ("tan2_n1", "誕", ["タン"], [], ["kelahiran", "birth"], 15, "言", [
        ("誕生", "tanjou", "kelahiran"),
        ("誕生日", "tanjoubi", "ulang tahun"),
        ("生誕", "seitan", "kelahiran (formal)"),
    ], [
        ("誕生日おめでとう。", "Tanjoubi omedetou.", "Selamat ulang tahun."),
        ("生誕100年です。", "Seitan hyakunen desu.", "Ini 100 tahun kelahirannya."),
    ]),
    ("shin5_n1", "侵", ["シン"], ["おか-す"], ["menyerbu", "invade"], 9, "人", [
        ("侵略", "shinryaku", "invasi"),
        ("侵入", "shinnyuu", "penyusupan"),
        ("侵害", "shingai", "pelanggaran hak"),
    ], [
        ("領土を侵略しました。", "Ryodo o shinryaku shimashita.", "Menginvasi wilayah."),
        ("不法侵入です。", "Fuhou shinnyuu desu.", "Ini penyusupan ilegal."),
    ]),
    ("katsu_n1", "括", ["カツ"], ["くく-る"], ["mengikat", "meringkas", "bracket"], 9, "手", [
        ("括弧", "kakko", "tanda kurung"),
        ("一括", "ikkatsu", "sekaligus/gabungan"),
        ("総括", "soukatsu", "kesimpulan menyeluruh"),
    ], [
        ("括弧をつけました。", "Kakko o tsukemashita.", "Saya menambahkan tanda kurung."),
        ("一括払いです。", "Ikkatsu barai desu.", "Ini pembayaran sekaligus."),
    ]),
    ("sha2_n1", "謝", ["シャ"], ["あやま-る"], ["berterima kasih", "minta maaf", "thank"], 17, "言", [
        ("感謝", "kansha", "rasa terima kasih"),
        ("謝罪", "shazai", "permintaan maaf"),
        ("謝る", "ayamaru", "meminta maaf"),
    ], [
        ("感謝しています。", "Kansha shite imasu.", "Saya berterima kasih."),
        ("謝罪しました。", "Shazai shimashita.", "Saya meminta maaf."),
    ]),
    ("kou12_n1", "孝", ["コウ"], [], ["bakti kepada orang tua", "filial piety"], 7, "子", [
        ("親孝行", "oyakoukou", "bakti kepada orang tua"),
        ("孝行", "koukou", "bakti"),
        ("忠孝", "chuukou", "kesetiaan dan bakti"),
    ], [
        ("親孝行をしています。", "Oyakoukou o shite imasu.", "Saya berbakti kepada orang tua."),
        ("孝行息子です。", "Koukou musuko desu.", "Dia anak yang berbakti."),
    ]),
    ("ku_n1", "駆", ["ク"], ["か-ける", "か-る"], ["berlari kencang", "drive"], 14, "馬", [
        ("駆ける", "kakeru", "berlari"),
        ("駆使", "kushi", "menguasai dengan mahir"),
        ("先駆者", "senkusha", "pelopor"),
    ], [
        ("全力で駆けました。", "Zenryoku de kakemashita.", "Berlari sekuat tenaga."),
        ("先駆者です。", "Senkusha desu.", "Dia seorang pelopor."),
    ]),
    ("tou6_n1", "透", ["トウ"], ["す-く", "す-ける"], ["transparan", "transparent"], 10, "辵", [
        ("透明", "toumei", "transparan"),
        ("透ける", "sukeru", "tembus pandang"),
        ("浸透", "shintou", "penetrasi/peresapan"),
    ], [
        ("透明な水です。", "Toumei na mizu desu.", "Ini air yang jernih."),
        ("文化が浸透しました。", "Bunka ga shintou shimashita.", "Budaya meresap."),
    ]),
    ("shin6_n1", "津", ["シン"], ["つ"], ["pelabuhan", "harbor"], 9, "水", [
        ("津波", "tsunami", "tsunami"),
        ("興味津々", "kyoumi shinshin", "sangat tertarik"),
        ("津", "Tsu", "nama kota/prefektur"),
    ], [
        ("興味津々です。", "Kyoumi shinshin desu.", "Sangat tertarik."),
        ("津市に住んでいます。", "Tsu-shi ni sunde imasu.", "Saya tinggal di kota Tsu."),
    ]),
    ("heki_n1", "壁", ["ヘキ"], ["かべ"], ["dinding", "wall"], 16, "土", [
        ("壁", "kabe", "dinding"),
        ("壁紙", "kabegami", "wallpaper"),
        ("岸壁", "ganpeki", "dermaga/tebing pelabuhan"),
    ], [
        ("壁に絵を飾りました。", "Kabe ni e o kazarimashita.", "Menghias dinding dengan lukisan."),
        ("壁紙を変えました。", "Kabegami o kaemashita.", "Mengganti wallpaper."),
    ]),
    ("tou7_n1", "稲", ["トウ"], ["いね", "いな"], ["padi", "rice plant"], 14, "禾", [
        ("稲", "ine", "padi"),
        ("稲作", "inasaku", "budidaya padi"),
        ("稲妻", "inazuma", "kilat"),
    ], [
        ("稲を育てています。", "Ine o sodatete imasu.", "Menanam padi."),
        ("稲妻が光りました。", "Inazuma ga hikarimashita.", "Kilat menyambar."),
    ]),
    ("ka4_n1", "仮", ["カ"], ["かり"], ["sementara", "temporary", "false"], 6, "人", [
        ("仮定", "katei", "asumsi"),
        ("仮面", "kamen", "topeng"),
        ("仮の", "kari no", "sementara"),
    ], [
        ("仮定してみましょう。", "Katei shite mimashou.", "Mari kita asumsikan."),
        ("仮面をつけました。", "Kamen o tsukemashita.", "Memakai topeng."),
    ]),
    ("retsu_n1", "裂", ["レツ"], ["さ-く", "さ-ける"], ["merobek", "tear", "split"], 12, "衣", [
        ("分裂", "bunretsu", "perpecahan"),
        ("裂く", "saku", "merobek"),
        ("破裂", "haretsu", "meledak/pecah"),
    ], [
        ("意見が分裂しました。", "Iken ga bunretsu shimashita.", "Pendapat terpecah."),
        ("風船が破裂しました。", "Fuusen ga haretsu shimashita.", "Balon meledak."),
    ]),
    ("bin2_n1", "敏", ["ビン"], [], ["gesit", "quick", "agile"], 10, "攴", [
        ("敏感", "binkan", "sensitif"),
        ("過敏", "kabin", "terlalu sensitif"),
        ("敏捷", "binshou", "gesit/lincah"),
    ], [
        ("肌が敏感です。", "Hada ga binkan desu.", "Kulit sensitif."),
        ("過敏に反応しました。", "Kabin ni hannou shimashita.", "Bereaksi terlalu sensitif."),
    ]),
    ("ze_n1", "是", ["ゼ"], [], ["benar", "righteousness", "this"], 9, "日", [
        ("是非", "zehi", "pasti/tolong"),
        ("是正", "zesei", "koreksi/perbaikan"),
        ("国是", "kokuze", "kebijakan nasional"),
    ], [
        ("是非来てください。", "Zehi kite kudasai.", "Tolong datang ya."),
        ("制度を是正しました。", "Seido o zesei shimashita.", "Memperbaiki sistem."),
    ]),
    ("hai2_n1", "排", ["ハイ"], [], ["menolak", "mengeluarkan", "expel"], 11, "手", [
        ("排除", "haijo", "menyingkirkan"),
        ("排気", "haiki", "pembuangan gas"),
        ("排水", "haisui", "drainase"),
    ], [
        ("障害を排除しました。", "Shougai o haijo shimashita.", "Menyingkirkan rintangan."),
        ("排気ガスです。", "Haiki gasu desu.", "Ini gas buang."),
    ]),
    ("yuu4_n1", "裕", ["ユウ"], [], ["berkecukupan", "abundant", "affluent"], 12, "衣", [
        ("余裕", "yoyo", "kelonggaran/kelapangan"),
        ("裕福", "yuufuku", "kaya raya"),
        ("富裕", "fuyuu", "kemakmuran"),
    ], [
        ("時間に余裕があります。", "Jikan ni yoyo ga arimasu.", "Ada kelonggaran waktu."),
        ("裕福な家庭です。", "Yuufuku na katei desu.", "Keluarga yang kaya."),
    ]),
    ("ken7_n1", "堅", ["ケン"], ["かた-い"], ["keras", "kokoh", "hard", "solid"], 12, "土", [
        ("堅い", "katai", "keras/kokoh"),
        ("堅実", "kenjitsu", "kokoh/dapat diandalkan"),
        ("中堅", "chuuken", "inti/menengah"),
    ], [
        ("堅い木材です。", "Katai mokuzai desu.", "Ini kayu yang keras."),
        ("堅実な計画です。", "Kenjitsu na keikaku desu.", "Ini rencana yang kokoh."),
    ]),
    ("yaku2_n1", "訳", ["ヤク"], ["わけ"], ["terjemahan", "alasan", "translation"], 11, "言", [
        ("翻訳", "honyaku", "terjemahan"),
        ("訳", "wake", "alasan"),
        ("通訳", "tsuuyaku", "interpreter"),
    ], [
        ("本を翻訳しました。", "Hon o honyaku shimashita.", "Menerjemahkan buku."),
        ("訳がわかりません。", "Wake ga wakarimasen.", "Saya tidak mengerti alasannya."),
    ]),
    ("shi9_n1", "芝", ["シ"], ["しば"], ["rumput", "lawn"], 6, "艸", [
        ("芝生", "shibafu", "halaman rumput"),
        ("芝居", "shibai", "drama/sandiwara"),
        ("芝刈り", "shibakari", "memotong rumput"),
    ], [
        ("芝生に座りました。", "Shibafu ni suwarimashita.", "Duduk di halaman rumput."),
        ("芝居を見ました。", "Shibai o mimashita.", "Menonton sandiwara."),
    ]),
    ("kou13_n1", "綱", ["コウ"], ["つな"], ["tali besar", "rope"], 14, "糸", [
        ("綱", "tsuna", "tali besar"),
        ("横綱", "yokozuna", "juara sumo tertinggi"),
        ("要綱", "youkou", "garis besar/pedoman"),
    ], [
        ("綱を引きました。", "Tsuna o hikimashita.", "Menarik tali."),
        ("横綱になりました。", "Yokozuna ni narimashita.", "Menjadi yokozuna."),
    ]),
    ("ten2_n1", "典", ["テン"], [], ["kitab", "upacara", "code", "ceremony"], 8, "八", [
        ("辞典", "jiten", "kamus"),
        ("古典", "koten", "klasik"),
        ("式典", "shikiten", "upacara"),
    ], [
        ("辞典で調べました。", "Jiten de shirabemashita.", "Memeriksa di kamus."),
        ("式典に出席しました。", "Shikiten ni shusseki shimashita.", "Menghadiri upacara."),
    ]),
    ("ga2_n1", "賀", ["ガ"], [], ["perayaan", "celebration"], 12, "貝", [
        ("年賀状", "nengajou", "kartu tahun baru"),
        ("祝賀", "shukuga", "perayaan"),
        ("賀正", "gashou", "selamat tahun baru"),
    ], [
        ("年賀状を書きました。", "Nengajou o kakimashita.", "Menulis kartu tahun baru."),
        ("祝賀会がありました。", "Shukugakai ga arimashita.", "Ada pesta perayaan."),
    ]),
    ("atsukau_n1", "扱", [], ["あつか-う"], ["menangani", "handle", "treat"], 6, "手", [
        ("扱う", "atsukau", "menangani"),
        ("取扱", "toriatsukai", "penanganan"),
        ("客扱い", "kyakuatsukai", "pelayanan pelanggan"),
    ], [
        ("荷物を扱いました。", "Nimotsu o atsukaimashita.", "Menangani barang."),
        ("取扱説明書です。", "Toriatsukai setsumeisho desu.", "Ini buku petunjuk."),
    ]),
    ("ko2_n1", "顧", ["コ"], ["かえり-みる"], ["menoleh kembali", "look back", "consider"], 21, "頁", [
        ("顧客", "kokyaku", "pelanggan"),
        ("回顧", "kaiko", "kenangan/retrospeksi"),
        ("顧問", "komon", "penasihat"),
    ], [
        ("顧客が満足しています。", "Kokyaku ga manzoku shite imasu.", "Pelanggan puas."),
        ("顧問に相談しました。", "Komon ni soudan shimashita.", "Berkonsultasi dengan penasihat."),
    ]),
    ("kou14_n1", "弘", ["コウ"], [], ["luas", "wide", "spread"], 5, "弓", [
        ("弘法", "kouhou", "penyebaran ajaran agama"),
        ("弘める", "hiromeru", "menyebarluaskan"),
        ("弘大", "koudai", "sangat luas"),
    ], [
        ("教えを弘めました。", "Oshie o hiromemashita.", "Menyebarluaskan ajaran."),
        ("弘大な計画です。", "Koudai na keikaku desu.", "Rencana yang sangat luas."),
    ]),
    ("kan13_n1", "看", ["カン"], [], ["mengawasi", "watch over"], 9, "目", [
        ("看護師", "kangoshi", "perawat"),
        ("看板", "kanban", "papan nama/plang"),
        ("看病", "kanbyou", "merawat orang sakit"),
    ], [
        ("看護師になりました。", "Kangoshi ni narimashita.", "Menjadi perawat."),
        ("看板を見ました。", "Kanban o mimashita.", "Melihat papan nama."),
    ]),
    ("shou11_n1", "訟", ["ショウ"], [], ["gugatan", "lawsuit"], 11, "言", [
        ("訴訟", "soshou", "tuntutan hukum/gugatan"),
        ("争訟", "sousho", "perselisihan hukum"),
        ("訟廷", "shoutei", "pengadilan"),
    ], [
        ("訴訟を起こしました。", "Soshou o okoshimashita.", "Mengajukan gugatan."),
        ("争訟が続いています。", "Sousho ga tsuzuite imasu.", "Perselisihan hukum berlanjut."),
    ]),
    ("kai2_n1", "戒", ["カイ"], ["いまし-める"], ["memperingatkan", "warn", "commandment"], 7, "戈", [
        ("警戒", "keikai", "kewaspadaan"),
        ("戒める", "imashimeru", "memperingatkan"),
        ("戒律", "kairitsu", "ajaran/perintah agama"),
    ], [
        ("警戒しています。", "Keikai shite imasu.", "Sedang waspada."),
        ("戒律を守りました。", "Kairitsu o mamorimashita.", "Menaati ajaran agama."),
    ]),
    ("shi10_n1", "祉", ["シ"], [], ["kesejahteraan", "happiness", "welfare"], 8, "示", [
        ("福祉", "fukushi", "kesejahteraan sosial"),
        ("福祉施設", "fukushi shisetsu", "fasilitas kesejahteraan"),
        ("社会福祉", "shakai fukushi", "kesejahteraan sosial"),
    ], [
        ("福祉施設で働いています。", "Fukushi shisetsu de hataraite imasu.", "Bekerja di fasilitas kesejahteraan."),
        ("社会福祉が大切です。", "Shakai fukushi ga taisetsu desu.", "Kesejahteraan sosial itu penting."),
    ]),
    ("yo_n1", "誉", ["ヨ"], ["ほま-れ"], ["kehormatan", "honor", "praise"], 13, "言", [
        ("名誉", "meiyo", "kehormatan"),
        ("栄誉", "eiyo", "kemuliaan"),
        ("誉れ", "homare", "kehormatan/kebanggaan"),
    ], [
        ("名誉を守りました。", "Meiyo o mamorimashita.", "Menjaga kehormatan."),
        ("栄誉ある賞です。", "Eiyo aru shou desu.", "Ini penghargaan yang mulia."),
    ]),
    ("kan14_n1", "歓", ["カン"], [], ["kegembiraan", "joy", "welcome"], 15, "欠", [
        ("歓迎", "kangei", "penyambutan"),
        ("歓声", "kansei", "sorak-sorai"),
        ("歓喜", "kanki", "kegembiraan besar"),
    ], [
        ("歓迎会がありました。", "Kangeikai ga arimashita.", "Ada acara penyambutan."),
        ("歓声を上げました。", "Kansei o agemashita.", "Bersorak-sorai."),
    ]),
    ("sou5_n1", "奏", ["ソウ"], ["かな-でる"], ["memainkan musik", "play music", "report"], 9, "大", [
        ("演奏", "ensou", "pertunjukan musik"),
        ("奏でる", "kanaderu", "memainkan musik"),
        ("伴奏", "bansou", "iringan musik"),
    ], [
        ("ピアノを演奏しました。", "Piano o ensou shimashita.", "Memainkan piano."),
        ("伴奏をお願いします。", "Bansou o onegaishimasu.", "Tolong iringi."),
    ]),
    ("kan15_n1", "勧", ["カン"], ["すす-める"], ["menganjurkan", "recommend"], 13, "力", [
        ("勧める", "susumeru", "menganjurkan"),
        ("勧誘", "kanyuu", "ajakan/rekrutmen"),
        ("勧告", "kankoku", "imbauan"),
    ], [
        ("本を勧めました。", "Hon o susumemashita.", "Menganjurkan buku."),
        ("勧誘を断りました。", "Kanyuu o kotowarimashita.", "Menolak ajakan."),
    ]),
    ("sou6_n1", "騒", ["ソウ"], ["さわ-ぐ"], ["keributan", "noise", "disturbance"], 18, "馬", [
        ("騒ぐ", "sawagu", "ribut"),
        ("騒音", "souon", "kebisingan"),
        ("騒動", "soudou", "kekacauan"),
    ], [
        ("子供が騒いでいます。", "Kodomo ga sawaide imasu.", "Anak-anak ribut."),
        ("騒音問題です。", "Souon mondai desu.", "Ini masalah kebisingan."),
    ]),
    ("batsu_n1", "閥", ["バツ"], [], ["golongan", "faksi", "clique", "faction"], 14, "門", [
        ("派閥", "habatsu", "faksi"),
        ("財閥", "zaibatsu", "konglomerat"),
        ("学閥", "gakubatsu", "kelompok alumni"),
    ], [
        ("派閥争いです。", "Habatsu arasoi desu.", "Ini perselisihan faksi."),
        ("財閥系企業です。", "Zaibatsu-kei kigyou desu.", "Ini perusahaan grup konglomerat."),
    ]),
    ("kou15_n1", "甲", ["コウ"], [], ["kelas pertama", "cangkang", "shell", "armor"], 5, "田", [
        ("甲乙", "kouotsu", "urutan pertama-kedua"),
        ("甲羅", "koura", "cangkang kura-kura/kepiting"),
        ("甲板", "kanpan", "dek kapal"),
    ], [
        ("甲乙つけがたいです。", "Kouotsu tsukegatai desu.", "Sulit dibedakan mana yang lebih baik."),
        ("甲板に立ちました。", "Kanpan ni tachimashita.", "Berdiri di dek kapal."),
    ]),
    ("jou3_n1", "縄", ["ジョウ"], ["なわ"], ["tali", "rope"], 15, "糸", [
        ("縄", "nawa", "tali"),
        ("沖縄", "Okinawa", "nama tempat"),
        ("縄跳び", "nawatobi", "lompat tali"),
    ], [
        ("縄で縛りました。", "Nawa de shibarimashita.", "Mengikat dengan tali."),
        ("沖縄に旅行しました。", "Okinawa ni ryokou shimashita.", "Berlibur ke Okinawa."),
    ]),
    ("kyou2_n1", "郷", ["キョウ"], [], ["kampung halaman", "hometown"], 11, "邑", [
        ("故郷", "kokyou", "kampung halaman"),
        ("郷土", "kyoudo", "daerah asal"),
        ("帰郷", "kikyou", "pulang kampung"),
    ], [
        ("故郷を思い出しました。", "Kokyou o omoidashimashita.", "Teringat kampung halaman."),
        ("帰郷しました。", "Kikyou shimashita.", "Pulang kampung."),
    ]),
    ("you2_n1", "揺", ["ヨウ"], ["ゆ-れる", "ゆ-する", "ゆ-らぐ"], ["bergoyang", "shake"], 12, "手", [
        ("揺れる", "yureru", "bergoyang"),
        ("動揺", "douyou", "kegelisahan"),
        ("揺らぐ", "yuragu", "goyah"),
    ], [
        ("地震で揺れました。", "Jishin de yuremashita.", "Bergoyang karena gempa."),
        ("動揺しています。", "Douyou shite imasu.", "Sedang gelisah."),
    ]),
    ("men_n1", "免", ["メン"], ["まぬか-れる"], ["dibebaskan", "exempt"], 8, "儿", [
        ("免除", "menjo", "pembebasan"),
        ("免許", "menkyo", "izin/lisensi"),
        ("免税", "menzei", "bebas pajak"),
    ], [
        ("学費が免除されました。", "Gakuhi ga menjo saremashita.", "Biaya sekolah dibebaskan."),
        ("運転免許を取りました。", "Unten menkyo o torimashita.", "Mendapatkan SIM."),
    ]),
    ("ki8_n1", "既", ["キ"], ["すで-に"], ["sudah", "already"], 10, "无", [
        ("既に", "sude ni", "sudah"),
        ("既存", "kison", "yang sudah ada"),
        ("既婚", "kikon", "sudah menikah"),
    ], [
        ("既に終わりました。", "Sude ni owarimashita.", "Sudah selesai."),
        ("既婚者です。", "Kikonsha desu.", "Dia sudah menikah."),
    ]),
    ("sen5_n1", "薦", ["セン"], ["すす-める"], ["merekomendasikan", "recommend"], 16, "艸", [
        ("推薦", "suisen", "rekomendasi"),
        ("薦める", "susumeru", "merekomendasikan"),
        ("自薦", "jisen", "merekomendasikan diri sendiri"),
    ], [
        ("推薦状を書きました。", "Suisenjou o kakimashita.", "Menulis surat rekomendasi."),
        ("本を薦めました。", "Hon o susumemashita.", "Merekomendasikan buku."),
    ]),
    ("rin2_n1", "隣", ["リン"], ["とな-り", "とな-る"], ["tetangga", "neighbor"], 16, "阜", [
        ("隣", "tonari", "sebelah"),
        ("隣人", "rinjin", "tetangga"),
        ("近隣", "kinrin", "sekitar/tetangga dekat"),
    ], [
        ("隣に座りました。", "Tonari ni suwarimashita.", "Duduk di sebelah."),
        ("隣人と話しました。", "Rinjin to hanashimashita.", "Berbicara dengan tetangga."),
    ]),
    ("ka5_n1", "華", ["カ"], ["はな"], ["keindahan", "kemegahan", "flower", "splendor"], 10, "艸", [
        ("華やか", "hanayaka", "meriah/gemerlap"),
        ("中華", "chuuka", "masakan Tiongkok"),
        ("豪華", "gouka", "mewah"),
    ], [
        ("華やかなパーティーです。", "Hanayaka na paatii desu.", "Ini pesta yang meriah."),
        ("豪華なホテルです。", "Gouka na hoteru desu.", "Ini hotel yang mewah."),
    ]),
    ("han2_n1", "範", ["ハン"], [], ["contoh", "teladan", "model", "example"], 15, "竹", [
        ("模範", "mohan", "teladan"),
        ("範囲", "han-i", "ruang lingkup"),
        ("規範", "kihan", "norma"),
    ], [
        ("模範的な学生です。", "Mohanteki na gakusei desu.", "Dia siswa teladan."),
        ("範囲が広いです。", "Han-i ga hiroi desu.", "Ruang lingkupnya luas."),
    ]),
    ("in_n1", "隠", ["イン"], ["かく-す", "かく-れる"], ["menyembunyikan", "hide"], 14, "阜", [
        ("隠す", "kakusu", "menyembunyikan"),
        ("隠れる", "kakureru", "bersembunyi"),
        ("隠居", "inkyo", "pensiun/mengasingkan diri"),
    ], [
        ("秘密を隠しました。", "Himitsu o kakushimashita.", "Menyembunyikan rahasia."),
        ("木の後ろに隠れました。", "Ki no ushiro ni kakuremashita.", "Bersembunyi di balik pohon."),
    ]),
    ("toku2_n1", "徳", ["トク"], [], ["kebajikan", "virtue"], 14, "彳", [
        ("道徳", "doutoku", "moral"),
        ("徳", "toku", "kebajikan"),
        ("人徳", "jintoku", "kebajikan pribadi"),
    ], [
        ("道徳を教えました。", "Doutoku o oshiemashita.", "Mengajarkan moral."),
        ("人徳のある人です。", "Jintoku no aru hito desu.", "Dia orang yang berbudi."),
    ]),
    ("tetsu3_n1", "哲", ["テツ"], [], ["filsafat", "philosophy", "wisdom"], 10, "口", [
        ("哲学", "tetsugaku", "filsafat"),
        ("哲人", "tetsujin", "orang bijak"),
        ("先哲", "sentetsu", "orang bijak terdahulu"),
    ], [
        ("哲学を学んでいます。", "Tetsugaku o manande imasu.", "Belajar filsafat."),
        ("哲人のような人です。", "Tetsujin no you na hito desu.", "Dia seperti orang bijak."),
    ]),
    ("sugi_n1", "杉", [], ["すぎ"], ["pohon cemara Jepang", "cedar"], 7, "木", [
        ("杉", "sugi", "pohon cedar Jepang"),
        ("杉並木", "suginamiki", "deretan pohon cedar"),
        ("杉板", "sugiita", "papan kayu cedar"),
    ], [
        ("杉の木を植えました。", "Sugi no ki o uemashita.", "Menanam pohon cedar."),
        ("杉並木を歩きました。", "Suginamiki o arukimashita.", "Berjalan di deretan pohon cedar."),
    ]),
    ("ri2_n1", "里", ["リ"], ["さと"], ["desa", "village"], 7, "里", [
        ("里", "sato", "desa/kampung"),
        ("郷里", "kyouri", "kampung halaman"),
        ("里帰り", "satogaeri", "pulang kampung"),
    ], [
        ("里に帰りました。", "Sato ni kaerimashita.", "Pulang ke kampung."),
        ("里帰りをしました。", "Satogaeri o shimashita.", "Pulang ke rumah orang tua."),
    ]),
    ("shaku_n1", "釈", ["シャク"], [], ["menjelaskan", "membebaskan", "explain", "release"], 11, "釆", [
        ("解釈", "kaishaku", "interpretasi"),
        ("釈放", "shakuhou", "pembebasan"),
        ("会釈", "eshaku", "anggukan hormat"),
    ], [
        ("解釈が違います。", "Kaishaku ga chigaimasu.", "Interpretasinya berbeda."),
        ("釈放されました。", "Shakuhou saremashita.", "Dibebaskan."),
    ]),
    ("ko3_n1", "己", ["コ", "キ"], ["おのれ"], ["diri sendiri", "self"], 3, "己", [
        ("自己", "jiko", "diri sendiri"),
        ("利己的", "rikoteki", "egois"),
        ("知己", "chiki", "sahabat karib"),
    ], [
        ("自己紹介をしました。", "Jiko shoukai o shimashita.", "Memperkenalkan diri."),
        ("利己的な人です。", "Rikoteki na hito desu.", "Dia orang yang egois."),
    ]),
    ("da_n1", "妥", ["ダ"], [], ["sesuai", "compromise", "appropriate"], 7, "女", [
        ("妥当", "datou", "wajar/sesuai"),
        ("妥協", "dakyou", "kompromi"),
        ("妥結", "daketsu", "kesepakatan"),
    ], [
        ("妥当な判断です。", "Datou na handan desu.", "Ini keputusan yang wajar."),
        ("妥協しました。", "Dakyou shimashita.", "Berkompromi."),
    ]),
    ("i6_n1", "威", ["イ"], [], ["wibawa", "authority", "dignity"], 9, "女", [
        ("威厳", "igen", "kewibawaan"),
        ("権威", "ken-i", "otoritas"),
        ("脅威", "kyoui", "ancaman"),
    ], [
        ("威厳がある人です。", "Igen ga aru hito desu.", "Dia orang yang berwibawa."),
        ("権威のある学者です。", "Ken-i no aru gakusha desu.", "Dia ilmuwan yang berotoritas."),
    ]),
    ("gou_n1", "豪", ["ゴウ"], [], ["mewah", "hebat", "grand", "luxurious"], 14, "豕", [
        ("豪華", "gouka", "mewah"),
        ("豪雨", "gouu", "hujan lebat"),
        ("豪快", "goukai", "gagah/tangkas"),
    ], [
        ("豪雨が降りました。", "Gouu ga furimashita.", "Hujan lebat turun."),
        ("豪快な性格です。", "Goukai na seikaku desu.", "Kepribadian yang gagah."),
    ]),
    ("kuma_n1", "熊", [], ["くま"], ["beruang", "bear"], 14, "火", [
        ("熊", "kuma", "beruang"),
        ("熊本", "Kumamoto", "nama tempat"),
        ("白熊", "shirokuma", "beruang kutub"),
    ], [
        ("熊を見ました。", "Kuma o mimashita.", "Melihat beruang."),
        ("熊本に行きました。", "Kumamoto ni ikimashita.", "Pergi ke Kumamoto."),
    ]),
    ("tai4_n1", "滞", ["タイ"], ["とどこお-る"], ["tertunda", "stagnate", "delay"], 13, "水", [
        ("渋滞", "juutai", "kemacetan"),
        ("滞在", "taizai", "tinggal sementara"),
        ("滞る", "todokooru", "tertunda"),
    ], [
        ("交通渋滞です。", "Koutsuu juutai desu.", "Ini kemacetan lalu lintas."),
        ("東京に滞在しました。", "Tokyo ni taizai shimashita.", "Tinggal sementara di Tokyo."),
    ]),
    ("bi2_n1", "微", ["ビ"], [], ["kecil", "sedikit", "minute", "slight"], 13, "彳", [
        ("微妙", "bimyou", "halus/rumit"),
        ("微笑", "bishou", "senyuman"),
        ("微生物", "biseibutsu", "mikroorganisme"),
    ], [
        ("微妙な問題です。", "Bimyou na mondai desu.", "Ini masalah yang rumit."),
        ("微笑んでいます。", "Hohoende imasu.", "Tersenyum tipis."),
    ]),
    ("ryuu_n1", "隆", ["リュウ"], [], ["makmur", "prosperous"], 11, "阜", [
        ("隆盛", "ryuusei", "kemakmuran"),
        ("隆起", "ryuuki", "pengangkatan/elevasi"),
        ("興隆", "kouryuu", "kebangkitan"),
    ], [
        ("隆盛を極めました。", "Ryuusei o kiwamemashita.", "Mencapai puncak kemakmuran."),
        ("地面が隆起しました。", "Jimen ga ryuuki shimashita.", "Tanah terangkat."),
    ]),
    ("shou12_n1", "症", ["ショウ"], [], ["gejala", "symptom"], 10, "疒", [
        ("症状", "shoujou", "gejala"),
        ("炎症", "enshou", "peradangan"),
        ("重症", "juushou", "sakit parah"),
    ], [
        ("症状が出ました。", "Shoujou ga demashita.", "Gejala muncul."),
        ("重症です。", "Juushou desu.", "Sakit parah."),
    ]),
    ("zan_n1", "暫", ["ザン"], [], ["sementara", "temporary"], 15, "日", [
        ("暫定", "zantei", "sementara"),
        ("暫時", "zanji", "sebentar"),
        ("暫く", "shibaraku", "sebentar/beberapa waktu"),
    ], [
        ("暫定的な措置です。", "Zanteiteki na sochi desu.", "Ini tindakan sementara."),
        ("暫くお待ちください。", "Shibaraku omachi kudasai.", "Mohon tunggu sebentar."),
    ]),
    ("chuu2_n1", "忠", ["チュウ"], [], ["kesetiaan", "loyalty"], 8, "心", [
        ("忠実", "chuujitsu", "setia"),
        ("忠告", "chuukoku", "nasihat"),
        ("忠誠", "chuusei", "kesetiaan"),
    ], [
        ("忠実な部下です。", "Chuujitsu na buka desu.", "Bawahan yang setia."),
        ("忠告を聞きました。", "Chuukoku o kikimashita.", "Mendengarkan nasihat."),
    ]),
    ("sou7_n1", "倉", ["ソウ"], ["くら"], ["gudang", "warehouse"], 10, "人", [
        ("倉庫", "souko", "gudang"),
        ("倉", "kura", "gudang"),
        ("穀倉", "kokusou", "lumbung padi"),
    ], [
        ("倉庫に保管しました。", "Souko ni hokan shimashita.", "Disimpan di gudang."),
        ("米を倉に入れました。", "Kome o kura ni iremashita.", "Menyimpan beras di gudang."),
    ]),
    ("hiko_n1", "彦", ["ゲン"], ["ひこ"], ["sebutan pria dalam nama", "handsome man"], 9, "彡", [
        ("彦星", "hikoboshi", "bintang Altair/tokoh legenda Tanabata"),
        ("若彦", "wakahiko", "contoh nama pria muda"),
        ("彦", "hiko", "akhiran nama pria"),
    ], [
        ("彦星の伝説です。", "Hikoboshi no densetsu desu.", "Ini legenda Hikoboshi."),
        ("彦という名前は男性によく使われます。", "Hiko to iu namae wa dansei ni yoku tsukawaremasu.", "Nama \"hiko\" sering dipakai untuk pria."),
    ]),
    ("kan16_n1", "肝", ["カン"], ["きも"], ["hati organ", "liver"], 7, "肉", [
        ("肝臓", "kanzou", "hati/liver"),
        ("肝心", "kanjin", "penting/inti"),
        ("肝っ玉", "kimottama", "keberanian"),
    ], [
        ("肝臓が悪いです。", "Kanzou ga warui desu.", "Livernya bermasalah."),
        ("肝心な点です。", "Kanjin na ten desu.", "Ini poin yang penting."),
    ]),
    ("kan17_n1", "喚", ["カン"], [], ["berteriak", "memanggil", "shout", "summon"], 12, "口", [
        ("喚起", "kanki", "membangkitkan"),
        ("召喚", "shoukan", "panggilan/summon"),
        ("叫喚", "kyoukan", "teriakan"),
    ], [
        ("注意を喚起しました。", "Chuui o kanki shimashita.", "Membangkitkan perhatian."),
        ("召喚状が来ました。", "Shoukanjou ga kimashita.", "Surat panggilan datang."),
    ]),
    ("en2_n1", "沿", ["エン"], ["そ-う"], ["menyusuri", "along"], 8, "水", [
        ("沿う", "sou", "menyusuri"),
        ("沿線", "ensen", "sepanjang jalur"),
        ("沿岸", "engan", "pesisir"),
    ], [
        ("川に沿って歩きました。", "Kawa ni sotte arukimashita.", "Berjalan menyusuri sungai."),
        ("沿岸警備隊です。", "Engan keibitai desu.", "Ini penjaga pantai."),
    ]),
    ("myou_n1", "妙", ["ミョウ"], ["たえ"], ["aneh", "menakjubkan", "strange", "exquisite"], 7, "女", [
        ("妙な", "myou na", "aneh"),
        ("巧妙", "koumyou", "cerdik/licik"),
        ("微妙", "bimyou", "halus/rumit"),
    ], [
        ("妙な音がしました。", "Myou na oto ga shimashita.", "Terdengar suara yang aneh."),
        ("巧妙な手口です。", "Koumyou na teguchi desu.", "Ini modus yang cerdik."),
    ]),
    ("shou13_n1", "唱", ["ショウ"], ["とな-える"], ["menyanyikan", "mengusulkan", "chant", "advocate"], 11, "口", [
        ("合唱", "gasshou", "paduan suara"),
        ("唱える", "tonaeru", "mengucapkan/mengusulkan"),
        ("提唱", "teishou", "usulan"),
    ], [
        ("合唱コンクールです。", "Gasshou konkuuru desu.", "Ini kompetisi paduan suara."),
        ("新しい説を唱えました。", "Atarashii setsu o tonaemashita.", "Mengusulkan teori baru."),
    ]),
    ("a_n1", "阿", ["ア"], [], ["partikel nama", "menjilat", "flatter"], 8, "阜", [
        ("阿吽", "aun", "harmoni/serasi"),
        ("阿呆", "ahou", "bodoh"),
        ("阿弥陀", "Amida", "nama Buddha"),
    ], [
        ("阿吽の呼吸です。", "Aun no kokyuu desu.", "Ini adalah keselarasan sempurna."),
        ("阿呆なことを言うな。", "Ahou na koto o iu na.", "Jangan bicara bodoh."),
    ]),
    ("saku2_n1", "索", ["サク"], [], ["mencari", "tali", "search", "rope"], 10, "糸", [
        ("検索", "kensaku", "pencarian"),
        ("索引", "sakuin", "indeks"),
        ("模索", "mosaku", "meraba-raba/mencoba"),
    ], [
        ("インターネットで検索しました。", "Intaanetto de kensaku shimashita.", "Mencari di internet."),
        ("解決策を模索しています。", "Kaiketsusaku o mosaku shite imasu.", "Mencari solusi."),
    ]),
    ("sei6_n1", "誠", ["セイ"], ["まこと"], ["ketulusan", "sincerity"], 13, "言", [
        ("誠実", "seijitsu", "tulus/jujur"),
        ("誠意", "seii", "ketulusan hati"),
        ("忠誠", "chuusei", "kesetiaan"),
    ], [
        ("誠実な人です。", "Seijitsu na hito desu.", "Dia orang yang tulus."),
        ("誠意を見せました。", "Seii o misemashita.", "Menunjukkan ketulusan hati."),
    ]),
    ("shuu6_n1", "襲", ["シュウ"], ["おそ-う"], ["menyerang", "attack", "inherit"], 22, "衣", [
        ("襲う", "osou", "menyerang"),
        ("襲撃", "shuugeki", "serangan"),
        ("世襲", "seshuu", "pewarisan turun-temurun"),
    ], [
        ("熊に襲われました。", "Kuma ni osowaremashita.", "Diserang beruang."),
        ("襲撃事件です。", "Shuugeki jiken desu.", "Ini kasus penyerangan."),
    ]),
    ("kon_n1", "懇", ["コン"], ["ねんご-ろ"], ["ramah", "tulus", "sincere", "cordial"], 17, "心", [
        ("懇親会", "konshinkai", "acara keakraban"),
        ("懇談", "kondan", "obrolan akrab"),
        ("懇切", "konsetsu", "sangat ramah/teliti"),
    ], [
        ("懇親会に参加しました。", "Konshinkai ni sanka shimashita.", "Mengikuti acara keakraban."),
        ("懇切な説明です。", "Konsetsu na setsumei desu.", "Ini penjelasan yang sangat teliti."),
    ]),
    ("hai3_n1", "俳", ["ハイ"], [], ["aktor", "haiku", "actor"], 10, "人", [
        ("俳優", "haiyuu", "aktor"),
        ("俳句", "haiku", "puisi haiku"),
        ("俳人", "haijin", "penyair haiku"),
    ], [
        ("俳優になりました。", "Haiyuu ni narimashita.", "Menjadi aktor."),
        ("俳句を詠みました。", "Haiku o yomimashita.", "Menggubah haiku."),
    ]),
    ("gara_n1", "柄", ["ヘイ"], ["がら", "え"], ["corak", "gagang", "pattern", "handle"], 9, "木", [
        ("柄", "gara", "corak/motif"),
        ("人柄", "hitogara", "kepribadian"),
        ("間柄", "aidagara", "hubungan"),
    ], [
        ("きれいな柄です。", "Kirei na gara desu.", "Ini corak yang cantik."),
        ("人柄がいいです。", "Hitogara ga ii desu.", "Kepribadiannya baik."),
    ]),
    ("kyou3_n1", "驚", ["キョウ"], ["おどろ-く"], ["terkejut", "surprise"], 22, "馬", [
        ("驚く", "odoroku", "terkejut"),
        ("驚異", "kyoui", "keajaiban"),
        ("驚愕", "kyougaku", "keterkejutan besar"),
    ], [
        ("とても驚きました。", "Totemo odorokimashita.", "Sangat terkejut."),
        ("驚異的な記録です。", "Kyoiteki na kiroku desu.", "Ini rekor yang menakjubkan."),
    ]),
    ("ma_n1", "麻", ["マ"], ["あさ"], ["rami", "hemp"], 11, "麻", [
        ("麻", "asa", "rami"),
        ("麻酔", "masui", "anestesi"),
        ("麻薬", "mayaku", "narkoba"),
    ], [
        ("麻の服です。", "Asa no fuku desu.", "Ini pakaian dari rami."),
        ("麻酔をかけました。", "Masui o kakemashita.", "Diberikan anestesi."),
    ]),
    ("ri3_n1", "李", ["リ"], ["すもも"], ["buah plum", "plum"], 7, "木", [
        ("李", "sumomo", "buah plum"),
        ("行李", "kouri", "kotak anyaman/koper"),
        ("李朝", "richou", "Dinasti Yi Korea"),
    ], [
        ("李を食べました。", "Sumomo o tabemashita.", "Makan buah plum."),
        ("李朝の歴史です。", "Richou no rekishi desu.", "Ini sejarah Dinasti Yi."),
    ]),
    ("kou16_n1", "浩", ["コウ"], [], ["luas (nama)", "vast"], 10, "水", [
        ("浩然", "kouzen", "luas dan bebas"),
        ("浩大", "koudai", "sangat luas"),
        ("浩瀚", "koukan", "sangat luas/tebal (buku)"),
    ], [
        ("浩然の気です。", "Kouzen no ki desu.", "Ini semangat yang luas dan bebas."),
        ("浩大な計画です。", "Koudai na keikaku desu.", "Rencana yang sangat luas."),
    ]),
    ("zai_n1", "剤", ["ザイ"], [], ["obat", "bahan", "medicine", "agent"], 10, "刀", [
        ("薬剤", "yakuzai", "obat"),
        ("洗剤", "senzai", "deterjen"),
        ("錠剤", "jouzai", "tablet obat"),
    ], [
        ("洗剤を使いました。", "Senzai o tsukaimashita.", "Menggunakan deterjen."),
        ("錠剤を飲みました。", "Jouzai o nomimashita.", "Minum tablet obat."),
    ]),
    ("se_n1", "瀬", [], ["せ"], ["arus dangkal", "shallows", "rapids"], 19, "水", [
        ("瀬戸物", "setomono", "keramik"),
        ("瀬戸内海", "Setonaikai", "Laut Pedalaman Seto"),
        ("浅瀬", "asase", "perairan dangkal"),
    ], [
        ("瀬戸内海を旅行しました。", "Setonaikai o ryokou shimashita.", "Berlibur ke Laut Pedalaman Seto."),
        ("浅瀬で泳ぎました。", "Asase de oyogimashita.", "Berenang di perairan dangkal."),
    ]),
    ("shu_n1", "趣", ["シュ"], ["おもむき"], ["selera", "esensi", "gist", "taste"], 15, "走", [
        ("趣味", "shumi", "hobi"),
        ("趣旨", "shushi", "maksud/tujuan"),
        ("趣", "omomuki", "suasana/nuansa"),
    ], [
        ("趣味は読書です。", "Shumi wa dokusho desu.", "Hobi saya membaca."),
        ("趣旨を説明しました。", "Shushi o setsumei shimashita.", "Menjelaskan maksudnya."),
    ]),
    ("kan18_n1", "陥", ["カン"], ["おちい-る", "おとしい-れる"], ["terjerumus", "fall into", "cave in"], 10, "阜", [
        ("陥る", "ochiiru", "terjerumus"),
        ("欠陥", "kekkan", "cacat"),
        ("陥落", "kanraku", "jatuh/runtuh"),
    ], [
        ("危機に陥りました。", "Kiki ni ochiirimashita.", "Terjerumus dalam krisis."),
        ("欠陥商品です。", "Kekkan shouhin desu.", "Ini produk cacat."),
    ]),
    ("sai6_n1", "斎", ["サイ"], [], ["penyucian", "ruang belajar", "purification", "study"], 11, "斉", [
        ("書斎", "shosai", "ruang kerja/studi"),
        ("斎場", "saijou", "tempat upacara pemakaman"),
        ("潔斎", "kessai", "penyucian diri"),
    ], [
        ("書斎で勉強しています。", "Shosai de benkyou shite imasu.", "Belajar di ruang kerja."),
        ("斎場に行きました。", "Saijou ni ikimashita.", "Pergi ke tempat pemakaman."),
    ]),
    ("kan19_n1", "貫", ["カン"], ["つらぬ-く"], ["menembus", "penetrate"], 11, "貝", [
        ("貫く", "tsuranuku", "menembus"),
        ("一貫", "ikkan", "konsisten"),
        ("貫通", "kantsuu", "tembus"),
    ], [
        ("意志を貫きました。", "Ishi o tsuranukimashita.", "Mempertahankan tekad."),
        ("一貫した方針です。", "Ikkanshita houshin desu.", "Ini kebijakan yang konsisten."),
    ]),
    ("sen6_n1", "仙", ["セン"], [], ["pertapa sakti", "hermit", "immortal"], 5, "人", [
        ("仙人", "sennin", "pertapa sakti"),
        ("水仙", "suisen", "bunga narsis"),
        ("仙台", "Sendai", "nama kota"),
    ], [
        ("仙人のような生活です。", "Sennin no you na seikatsu desu.", "Kehidupan seperti pertapa sakti."),
        ("仙台に住んでいます。", "Sendai ni sunde imasu.", "Tinggal di Sendai."),
    ]),
    ("i7_n1", "慰", ["イ"], ["なぐさ-める"], ["menghibur", "comfort", "console"], 15, "心", [
        ("慰める", "nagusameru", "menghibur"),
        ("慰安", "ian", "penghiburan"),
        ("慰労", "irou", "penghargaan atas jerih payah"),
    ], [
        ("友達を慰めました。", "Tomodachi o nagusamemashita.", "Menghibur teman."),
        ("慰労会がありました。", "Irou-kai ga arimashita.", "Ada acara penghargaan jerih payah."),
    ]),
    ("jo_n1", "序", ["ジョ"], [], ["urutan", "kata pengantar", "preface", "order"], 7, "广", [
        ("順序", "junjo", "urutan"),
        ("序文", "jobun", "kata pengantar"),
        ("秩序", "chitsujo", "ketertiban"),
    ], [
        ("順序を守りました。", "Junjo o mamorimashita.", "Menjaga urutan."),
        ("秩序を保っています。", "Chitsujo o tamotte imasu.", "Menjaga ketertiban."),
    ]),
    ("jun_n1", "旬", ["ジュン"], ["しゅん"], ["masa sepuluh hari", "musim", "season"], 6, "日", [
        ("旬", "shun", "musim panen terbaik"),
        ("上旬", "joujun", "awal bulan"),
        ("中旬", "chuujun", "pertengahan bulan"),
    ], [
        ("今が旬です。", "Ima ga shun desu.", "Sekarang musimnya."),
        ("上旬に行きます。", "Joujun ni ikimasu.", "Pergi di awal bulan."),
    ]),
    ("ken8_n1", "兼", ["ケン"], ["か-ねる"], ["merangkap", "concurrent"], 10, "八", [
        ("兼ねる", "kaneru", "merangkap"),
        ("兼任", "kennin", "merangkap jabatan"),
        ("兼業", "kengyou", "pekerjaan sampingan"),
    ], [
        ("部長を兼ねています。", "Buchou o kanete imasu.", "Merangkap sebagai kepala departemen."),
        ("兼業農家です。", "Kengyou nouka desu.", "Ini petani dengan pekerjaan sampingan."),
    ]),
    ("sei7_n1", "聖", ["セイ"], [], ["suci", "sacred", "holy"], 13, "耳", [
        ("聖書", "seisho", "kitab suci"),
        ("神聖", "shinsei", "kesucian"),
        ("聖人", "seijin", "orang suci"),
    ], [
        ("聖書を読みました。", "Seisho o yomimashita.", "Membaca kitab suci."),
        ("神聖な場所です。", "Shinsei na basho desu.", "Ini tempat yang suci."),
    ]),
    ("shi11_n1", "旨", ["シ"], ["むね", "うま-い"], ["maksud", "lezat", "purport", "delicious"], 6, "日", [
        ("趣旨", "shushi", "maksud/tujuan"),
        ("旨い", "umai", "lezat"),
        ("要旨", "youshi", "ringkasan"),
    ], [
        ("旨い料理です。", "Umai ryouri desu.", "Ini masakan yang lezat."),
        ("要旨をまとめました。", "Youshi o matomemashita.", "Merangkum intinya."),
    ]),
    ("soku2_n1", "即", ["ソク"], ["すなわ-ち"], ["langsung", "immediate"], 7, "卩", [
        ("即座に", "sokuza ni", "seketika"),
        ("即決", "sokketsu", "keputusan cepat"),
        ("即興", "sokkyou", "improvisasi"),
    ], [
        ("即座に対応しました。", "Sokuza ni taiou shimashita.", "Merespons seketika."),
        ("即興で演奏しました。", "Sokkyou de ensou shimashita.", "Memainkan musik secara improvisasi."),
    ]),
    ("ryuu2_n1", "柳", ["リュウ"], ["やなぎ"], ["pohon willow", "willow"], 9, "木", [
        ("柳", "yanagi", "pohon willow"),
        ("柳腰", "yanagigoshi", "pinggang ramping"),
        ("川柳", "senryuu", "puisi satir pendek"),
    ], [
        ("柳の木があります。", "Yanagi no ki ga arimasu.", "Ada pohon willow."),
        ("川柳を詠みました。", "Senryuu o yomimashita.", "Menggubah senryu."),
    ]),
    ("sha3_n1", "舎", ["シャ"], [], ["bangunan", "cottage", "building"], 8, "舌", [
        ("校舎", "kousha", "gedung sekolah"),
        ("田舎", "inaka", "pedesaan"),
        ("宿舎", "shukusha", "asrama/penginapan"),
    ], [
        ("校舎が新しいです。", "Kousha ga atarashii desu.", "Gedung sekolahnya baru."),
        ("田舎に住んでいます。", "Inaka ni sunde imasu.", "Tinggal di pedesaan."),
    ]),
    ("gi3_n1", "偽", ["ギ"], ["いつわ-る", "にせ"], ["palsu", "false", "fake"], 11, "人", [
        ("偽物", "nisemono", "barang palsu"),
        ("偽善", "gizen", "kemunafikan"),
        ("偽造", "gizou", "pemalsuan"),
    ], [
        ("偽物を買ってしまいました。", "Nisemono o katte shimaimashita.", "Terlanjur membeli barang palsu."),
        ("偽造事件です。", "Gizou jiken desu.", "Ini kasus pemalsuan."),
    ]),
    ("kaku5_n1", "較", ["カク"], [], ["membandingkan", "compare"], 13, "車", [
        ("比較", "hikaku", "perbandingan"),
        ("較差", "kakusa", "selisih"),
        ("比較的", "hikakuteki", "relatif"),
    ], [
        ("価格を比較しました。", "Kakaku o hikaku shimashita.", "Membandingkan harga."),
        ("比較的簡単です。", "Hikakuteki kantan desu.", "Relatif mudah."),
    ]),
    ("ha_n1", "覇", ["ハ"], [], ["hegemoni", "supremacy"], 19, "西", [
        ("覇権", "haken", "hegemoni"),
        ("制覇", "seiha", "penaklukan/menjuarai"),
        ("連覇", "renpa", "juara beruntun"),
    ], [
        ("覇権を握りました。", "Haken o nigirimashita.", "Memegang hegemoni."),
        ("大会を制覇しました。", "Taikai o seiha shimashita.", "Menjuarai turnamen."),
    ]),
    ("hatake_n1", "畑", [], ["はたけ"], ["ladang", "field"], 9, "田", [
        ("畑", "hatake", "ladang"),
        ("畑仕事", "hatakeshigoto", "pekerjaan ladang"),
        ("花畑", "hanabatake", "ladang bunga"),
    ], [
        ("畑で野菜を作っています。", "Hatake de yasai o tsukutte imasu.", "Menanam sayuran di ladang."),
        ("花畑がきれいです。", "Hanabatake ga kirei desu.", "Ladang bunga itu indah."),
    ]),
    ("shou14_n1", "詳", ["ショウ"], ["くわ-しい"], ["rinci", "detailed"], 13, "言", [
        ("詳しい", "kuwashii", "rinci/detail"),
        ("詳細", "shousai", "rincian"),
        ("詳報", "shouhou", "laporan rinci"),
    ], [
        ("詳しく説明しました。", "Kuwashiku setsumei shimashita.", "Menjelaskan secara rinci."),
        ("詳細をご覧ください。", "Shousai o goran kudasai.", "Silakan lihat rinciannya."),
    ]),
    ("tei4_n1", "抵", ["テイ"], [], ["menahan", "melawan", "resist"], 8, "手", [
        ("抵抗", "teikou", "perlawanan"),
        ("抵当", "teitou", "jaminan/hipotek"),
        ("大抵", "taitei", "kebanyakan/biasanya"),
    ], [
        ("抵抗しました。", "Teikou shimashita.", "Melakukan perlawanan."),
        ("大抵は家にいます。", "Taitei wa ie ni imasu.", "Biasanya di rumah."),
    ]),
    ("kyou4_n1", "脅", ["キョウ"], ["おびや-かす", "おど-す"], ["mengancam", "threaten"], 10, "肉", [
        ("脅す", "odosu", "mengancam"),
        ("脅威", "kyoui", "ancaman"),
        ("脅迫", "kyouhaku", "intimidasi"),
    ], [
        ("脅されました。", "Odosaremashita.", "Diancam."),
        ("脅迫状が届きました。", "Kyouhakujou ga todokimashita.", "Surat ancaman diterima."),
    ]),
    ("mo2_n1", "茂", ["モ"], ["しげ-る"], ["rimbun", "lush", "thick growth"], 8, "艸", [
        ("茂る", "shigeru", "tumbuh rimbun"),
        ("繁茂", "hanmo", "pertumbuhan lebat"),
        ("茂み", "shigemi", "semak-semak"),
    ], [
        ("木が茂っています。", "Ki ga shigette imasu.", "Pohonnya tumbuh rimbun."),
        ("茂みに隠れました。", "Shigemi ni kakuremashita.", "Bersembunyi di semak-semak."),
    ]),
    ("gi4_n1", "犠", ["ギ"], [], ["pengorbanan", "sacrifice"], 17, "牛", [
        ("犠牲", "gisei", "pengorbanan"),
        ("犠牲者", "giseisha", "korban"),
        ("犠牲的", "giseiteki", "penuh pengorbanan"),
    ], [
        ("犠牲を払いました。", "Gisei o haraimashita.", "Memberikan pengorbanan."),
        ("犠牲者が出ました。", "Giseisha ga demashita.", "Ada korban."),
    ]),
    ("ki9_n1", "旗", ["キ"], ["はた"], ["bendera", "flag"], 14, "方", [
        ("旗", "hata", "bendera"),
        ("国旗", "kokki", "bendera negara"),
        ("旗手", "kishu", "pembawa bendera"),
    ], [
        ("旗を振りました。", "Hata o furimashita.", "Mengibarkan bendera."),
        ("国旗を掲げました。", "Kokki o kakagemashita.", "Mengibarkan bendera negara."),
    ]),
    ("kyo4_n1", "距", ["キョ"], [], ["jarak", "distance"], 12, "足", [
        ("距離", "kyori", "jarak"),
        ("短距離", "tankyori", "jarak pendek"),
        ("長距離", "choukyori", "jarak jauh"),
    ], [
        ("距離が遠いです。", "Kyori ga tooi desu.", "Jaraknya jauh."),
        ("長距離を走りました。", "Choukyori o hashirimashita.", "Berlari jarak jauh."),
    ]),
    ("ga3_n1", "雅", ["ガ"], [], ["anggun", "elegant"], 13, "隹", [
        ("優雅", "yuuga", "anggun"),
        ("雅楽", "gagaku", "musik istana kuno Jepang"),
        ("雅号", "gagou", "nama pena"),
    ], [
        ("優雅な生活です。", "Yuuga na seikatsu desu.", "Kehidupan yang anggun."),
        ("雅楽を聞きました。", "Gagaku o kikimashita.", "Mendengarkan gagaku."),
    ]),
    ("shoku2_n1", "飾", ["ショク"], ["かざ-る"], ["menghias", "decorate"], 13, "食", [
        ("飾る", "kazaru", "menghias"),
        ("装飾", "soushoku", "dekorasi"),
        ("服飾", "fukushoku", "fesyen/pakaian"),
    ], [
        ("部屋を飾りました。", "Heya o kazarimashita.", "Menghias kamar."),
        ("装飾品です。", "Soushokuhin desu.", "Ini barang dekorasi."),
    ]),
    ("mou_n1", "網", ["モウ"], ["あみ"], ["jaring", "net"], 14, "糸", [
        ("網", "ami", "jaring"),
        ("網羅", "moura", "mencakup semua"),
        ("交通網", "koutsuumou", "jaringan transportasi"),
    ], [
        ("網で魚を捕りました。", "Ami de sakana o torimashita.", "Menangkap ikan dengan jaring."),
        ("交通網が発達しています。", "Koutsuumou ga hattatsu shite imasu.", "Jaringan transportasinya berkembang."),
    ]),
    ("ryuu3_n1", "竜", ["リュウ"], ["たつ"], ["naga", "dragon"], 10, "竜", [
        ("竜", "ryuu", "naga"),
        ("恐竜", "kyouryuu", "dinosaurus"),
        ("竜巻", "tatsumaki", "tornado"),
    ], [
        ("恐竜の骨です。", "Kyouryuu no hone desu.", "Ini tulang dinosaurus."),
        ("竜巻が発生しました。", "Tatsumaki ga hassei shimashita.", "Tornado terjadi."),
    ]),
    ("shi12_n1", "詩", ["シ"], [], ["puisi", "poem"], 13, "言", [
        ("詩", "shi", "puisi"),
        ("詩人", "shijin", "penyair"),
        ("漢詩", "kanshi", "puisi klasik Tiongkok"),
    ], [
        ("詩を書きました。", "Shi o kakimashita.", "Menulis puisi."),
        ("詩人になりたいです。", "Shijin ni naritai desu.", "Ingin menjadi penyair."),
    ]),
    ("han3_n1", "繁", ["ハン"], [], ["makmur", "sering", "prosperous", "frequent"], 16, "糸", [
        ("繁栄", "han-ei", "kemakmuran"),
        ("頻繁", "hinpan", "sering"),
        ("繁盛", "hanjou", "ramai/laris"),
    ], [
        ("繁栄しています。", "Han-ei shite imasu.", "Sedang makmur."),
        ("商売が繁盛しています。", "Shoubai ga hanjou shite imasu.", "Bisnisnya laris."),
    ]),
    ("yoku2_n1", "翼", ["ヨク"], ["つばさ"], ["sayap", "wing"], 17, "羽", [
        ("翼", "tsubasa", "sayap"),
        ("主翼", "shuyoku", "sayap utama pesawat"),
        ("左翼", "sayoku", "sayap kiri"),
    ], [
        ("鳥が翼を広げました。", "Tori ga tsubasa o hirogemashita.", "Burung merentangkan sayap."),
        ("左翼の政治家です。", "Sayoku no seijika desu.", "Ini politisi sayap kiri."),
    ]),
    ("ibara_n1", "茨", [], ["いばら"], ["duri", "thorn"], 9, "艸", [
        ("茨", "ibara", "tanaman berduri"),
        ("茨城県", "Ibaraki-ken", "Prefektur Ibaraki"),
        ("茨の道", "ibara no michi", "jalan berduri/sulit"),
    ], [
        ("茨城県に住んでいます。", "Ibaraki-ken ni sunde imasu.", "Tinggal di Prefektur Ibaraki."),
        ("茨の道を歩みました。", "Ibara no michi o ayumimashita.", "Menjalani jalan yang sulit."),
    ]),
    ("kata_n1", "潟", [], ["かた"], ["laguna", "lagoon"], 15, "水", [
        ("新潟", "Niigata", "nama prefektur"),
        ("干潟", "higata", "dataran lumpur pasang surut"),
        ("潟湖", "sekiko", "laguna"),
    ], [
        ("新潟に旅行しました。", "Niigata ni ryokou shimashita.", "Berlibur ke Niigata."),
        ("干潟で貝を採りました。", "Higata de kai o torimashita.", "Mengambil kerang di dataran lumpur."),
    ]),
    ("teki2_n1", "敵", ["テキ"], ["かたき"], ["musuh", "enemy"], 15, "攴", [
        ("敵", "teki", "musuh"),
        ("敵対", "tekitai", "permusuhan"),
        ("素敵", "suteki", "indah/keren"),
    ], [
        ("敵に勝ちました。", "Teki ni kachimashita.", "Mengalahkan musuh."),
        ("敵対関係です。", "Tekitai kankei desu.", "Ini hubungan bermusuhan."),
    ]),
    ("mi_n1", "魅", ["ミ"], [], ["pesona", "charm", "fascinate"], 15, "鬼", [
        ("魅力", "miryoku", "daya tarik"),
        ("魅了", "miryou", "memesona"),
        ("魅惑", "miwaku", "pesona"),
    ], [
        ("魅力的な人です。", "Miryokuteki na hito desu.", "Dia orang yang menarik."),
        ("観客を魅了しました。", "Kankyaku o miryou shimashita.", "Memukau penonton."),
    ]),
    ("sei8_n1", "斉", ["セイ"], [], ["seragam", "bersama", "uniform", "together"], 8, "斉", [
        ("一斉に", "issei ni", "serentak"),
        ("斉唱", "seishou", "menyanyi bersama"),
        ("斉藤", "Saitou", "contoh nama keluarga"),
    ], [
        ("一斉に立ち上がりました。", "Issei ni tachiagarimashita.", "Berdiri serentak."),
        ("斉唱しました。", "Seishou shimashita.", "Menyanyi bersama."),
    ]),
    ("fu_n1", "敷", ["フ"], ["し-く"], ["menghamparkan", "spread", "lay out"], 15, "攴", [
        ("敷く", "shiku", "menghamparkan"),
        ("敷地", "shikichi", "lahan/tapak"),
        ("座敷", "zashiki", "ruang tatami"),
    ], [
        ("布団を敷きました。", "Futon o shikimashita.", "Menghamparkan futon."),
        ("敷地が広いです。", "Shikichi ga hiroi desu.", "Lahannya luas."),
    ]),
    ("you3_n1", "擁", ["ヨウ"], [], ["mendukung", "memeluk", "embrace", "support"], 16, "手", [
        ("擁護", "yougo", "perlindungan"),
        ("擁立", "youritsu", "mendukung sebagai calon"),
        ("抱擁", "houyou", "pelukan"),
    ], [
        ("人権を擁護しました。", "Jinken o yougo shimashita.", "Melindungi hak asasi."),
        ("抱擁しました。", "Houyou shimashita.", "Berpelukan."),
    ]),
    ("ken9_n1", "圏", ["ケン"], [], ["wilayah", "zona", "sphere", "zone"], 12, "囗", [
        ("首都圏", "shutoken", "wilayah metropolitan"),
        ("圏内", "kennai", "di dalam zona"),
        ("北極圏", "hokkyokuken", "lingkar Arktik"),
    ], [
        ("首都圏に住んでいます。", "Shutoken ni sunde imasu.", "Tinggal di wilayah metropolitan."),
        ("圏内に入りました。", "Kennai ni hairimashita.", "Masuk ke dalam zona."),
    ]),
    ("san_n1", "酸", ["サン"], ["す-い"], ["asam", "acid", "sour"], 14, "酉", [
        ("酸素", "sanso", "oksigen"),
        ("酸っぱい", "suppai", "asam"),
        ("塩酸", "ensan", "asam klorida"),
    ], [
        ("酸素が必要です。", "Sanso ga hitsuyou desu.", "Oksigen diperlukan."),
        ("酸っぱい果物です。", "Suppai kudamono desu.", "Ini buah yang asam."),
    ]),
    ("batsu2_n1", "罰", ["バツ"], ["ばち"], ["hukuman", "punishment"], 14, "网", [
        ("罰", "batsu", "hukuman"),
        ("罰金", "bakkin", "denda"),
        ("処罰", "shobatsu", "hukuman"),
    ], [
        ("罰を受けました。", "Batsu o ukemashita.", "Menerima hukuman."),
        ("罰金を払いました。", "Bakkin o haraimashita.", "Membayar denda."),
    ]),
    ("metsu_n1", "滅", ["メツ"], ["ほろ-びる", "ほろ-ぼす"], ["hancur", "musnah", "destroy", "perish"], 13, "水", [
        ("滅びる", "horobiru", "musnah"),
        ("消滅", "shoumetsu", "lenyap"),
        ("全滅", "zenmetsu", "kehancuran total"),
    ], [
        ("国が滅びました。", "Kuni ga horobimashita.", "Negara itu musnah."),
        ("全滅しました。", "Zenmetsu shimashita.", "Hancur total."),
    ]),
    ("so4_n1", "礎", ["ソ"], ["いしずえ"], ["fondasi", "foundation stone"], 18, "石", [
        ("基礎", "kiso", "dasar"),
        ("礎石", "soseki", "batu fondasi"),
        ("礎", "ishizue", "fondasi"),
    ], [
        ("基礎を学びました。", "Kiso o manabimashita.", "Mempelajari dasar."),
        ("礎石を築きました。", "Soseki o kizukimashita.", "Membangun batu fondasi."),
    ]),
    ("fu2_n1", "腐", ["フ"], ["くさ-る"], ["membusuk", "rot", "decay"], 14, "肉", [
        ("腐る", "kusaru", "membusuk"),
        ("豆腐", "toufu", "tahu"),
        ("腐敗", "fuhai", "pembusukan/korupsi"),
    ], [
        ("食べ物が腐りました。", "Tabemono ga kusarimashita.", "Makanan membusuk."),
        ("豆腐を食べました。", "Toufu o tabemashita.", "Makan tahu."),
    ]),
    ("kyaku2_n1", "脚", ["キャク"], ["あし"], ["kaki", "leg"], 11, "肉", [
        ("脚", "ashi", "kaki"),
        ("脚本", "kyakuhon", "naskah"),
        ("脚立", "kyatatsu", "tangga lipat"),
    ], [
        ("脚が痛いです。", "Ashi ga itai desu.", "Kaki sakit."),
        ("脚本を書きました。", "Kyakuhon o kakimashita.", "Menulis naskah."),
    ]),
    ("ryou2_n1", "菱", ["リョウ"], ["ひし"], ["bentuk belah ketupat", "water chestnut", "diamond shape"], 11, "艸", [
        ("菱形", "hishigata", "bentuk belah ketupat"),
        ("三菱", "Mitsubishi", "nama perusahaan"),
        ("菱餅", "hishimochi", "kue mochi berbentuk belah ketupat"),
    ], [
        ("菱形の模様です。", "Hishigata no moyou desu.", "Ini pola belah ketupat."),
        ("三菱の車です。", "Mitsubishi no kuruma desu.", "Ini mobil Mitsubishi."),
    ]),
    ("chou5_n1", "潮", ["チョウ"], ["しお"], ["pasang surut", "tide"], 15, "水", [
        ("潮", "shio", "air pasang"),
        ("干潮", "kanchou", "air surut"),
        ("風潮", "fuuchou", "tren/kecenderungan"),
    ], [
        ("潮が満ちてきました。", "Shio ga michite kimashita.", "Air pasang naik."),
        ("時代の風潮です。", "Jidai no fuuchou desu.", "Ini tren zaman."),
    ]),
    ("bai_n1", "梅", ["バイ"], ["うめ"], ["pohon plum Jepang", "plum"], 10, "木", [
        ("梅", "ume", "plum Jepang"),
        ("梅雨", "tsuyu", "musim hujan"),
        ("梅干し", "umeboshi", "plum asin"),
    ], [
        ("梅の花が咲きました。", "Ume no hana ga sakimashita.", "Bunga plum mekar."),
        ("梅干しを食べました。", "Umeboshi o tabemashita.", "Makan plum asin."),
    ]),
    ("jin2_n1", "尽", ["ジン"], ["つ-くす", "つ-きる"], ["habis", "mengerahkan", "exhaust", "utmost"], 6, "尸", [
        ("尽くす", "tsukusu", "mengerahkan"),
        ("尽きる", "tsukiru", "habis"),
        ("理不尽", "rifujin", "tidak masuk akal"),
    ], [
        ("全力を尽くしました。", "Zenryoku o tsukushimashita.", "Mengerahkan seluruh kekuatan."),
        ("理不尽な要求です。", "Rifujin na youkyuu desu.", "Ini permintaan yang tidak masuk akal."),
    ]),
    ("boku_n1", "僕", ["ボク"], ["しもべ"], ["saya (pria)", "pelayan", "servant"], 14, "人", [
        ("僕", "boku", "saya (untuk pria)"),
        ("公僕", "koubuku", "pelayan publik"),
        ("下僕", "geboku", "pelayan"),
    ], [
        ("僕は学生です。", "Boku wa gakusei desu.", "Saya seorang pelajar."),
        ("公僕として働いています。", "Koubuku toshite hataraite imasu.", "Bekerja sebagai pelayan publik."),
    ]),
    ("ou2_n1", "桜", ["オウ"], ["さくら"], ["bunga sakura", "cherry blossom"], 10, "木", [
        ("桜", "sakura", "bunga sakura"),
        ("桜前線", "sakurazensen", "garis depan mekarnya sakura"),
        ("夜桜", "yozakura", "sakura malam hari"),
    ], [
        ("桜が咲きました。", "Sakura ga sakimashita.", "Sakura mekar."),
        ("夜桜を見ました。", "Yozakura o mimashita.", "Melihat sakura malam hari."),
    ]),
    ("katsu2_n1", "滑", ["カツ"], ["すべ-る", "なめ-らか"], ["licin", "slide", "smooth"], 13, "水", [
        ("滑る", "suberu", "tergelincir"),
        ("滑らか", "nameraka", "halus/licin"),
        ("円滑", "enkatsu", "lancar"),
    ], [
        ("道が滑ります。", "Michi ga suberimasu.", "Jalannya licin."),
        ("円滑に進みました。", "Enkatsu ni susumimashita.", "Berjalan dengan lancar."),
    ]),
    ("ko4_n1", "孤", ["コ"], [], ["sendirian", "alone", "isolated"], 9, "子", [
        ("孤独", "kodoku", "kesepian"),
        ("孤立", "koritsu", "terisolasi"),
        ("孤児", "koji", "anak yatim piatu"),
    ], [
        ("孤独を感じました。", "Kodoku o kanjimashita.", "Merasa kesepian."),
        ("孤立してしまいました。", "Koritsu shite shimaimashita.", "Menjadi terisolasi."),
    ]),
    ("ki10_n1", "煕", ["キ"], [], ["cerah/makmur (arkais)", "nama dalam Kaisar Kangxi"], 13, "火", [
        ("康煕帝", "Koki-tei", "Kaisar Kangxi Tiongkok"),
        ("康煕字典", "Koki-jiten", "Kamus Kangxi"),
        ("煕", "ki", "cerah (makna arkais)"),
    ], [
        ("康煕帝は清の皇帝です。", "Koki-tei wa Shin no koutei desu.", "Kaisar Kangxi adalah kaisar Dinasti Qing."),
        ("康煕字典を調べました。", "Koki-jiten o shirabemashita.", "Memeriksa Kamus Kangxi."),
    ]),
    ("en3_n1", "炎", ["エン"], ["ほのお"], ["api", "radang", "flame", "inflammation"], 8, "火", [
        ("炎", "honoo", "api/nyala"),
        ("炎症", "enshou", "peradangan"),
        ("肺炎", "haien", "pneumonia"),
    ], [
        ("炎が燃えています。", "Honoo ga moete imasu.", "Api sedang menyala."),
        ("肺炎になりました。", "Haien ni narimashita.", "Terkena pneumonia."),
    ]),
    ("bai2_n1", "賠", ["バイ"], [], ["mengganti rugi", "compensate"], 15, "貝", [
        ("賠償", "baishou", "ganti rugi"),
        ("損害賠償", "songai baishou", "ganti rugi kerusakan"),
        ("賠償金", "baishoukin", "uang ganti rugi"),
    ], [
        ("損害賠償を求めました。", "Songai baishou o motomemashita.", "Menuntut ganti rugi."),
        ("賠償金を払いました。", "Baishoukin o haraimashita.", "Membayar uang ganti rugi."),
    ]),
    ("ku2_n1", "句", ["ク"], [], ["frasa", "bait", "phrase", "verse"], 5, "口", [
        ("俳句", "haiku", "puisi haiku"),
        ("文句", "monku", "keluhan"),
        ("語句", "goku", "kosakata/frasa"),
    ], [
        ("文句を言いました。", "Monku o iimashita.", "Mengeluh."),
        ("語句を確認しました。", "Goku o kakunin shimashita.", "Memeriksa kosakata."),
    ]),
    ("ju4_n1", "寿", ["ジュ"], ["ことぶき"], ["umur panjang", "selamat", "longevity"], 7, "寸", [
        ("長寿", "chouju", "umur panjang"),
        ("寿命", "jumyou", "masa hidup"),
        ("寿司", "sushi", "sushi"),
    ], [
        ("長寿を願います。", "Chouju o negaimasu.", "Berharap umur panjang."),
        ("寿司を食べました。", "Sushi o tabemashita.", "Makan sushi."),
    ]),
    ("kou17_n1", "鋼", ["コウ"], ["はがね"], ["baja", "steel"], 16, "金", [
        ("鋼鉄", "koutetsu", "baja"),
        ("鋼", "hagane", "baja"),
        ("鉄鋼", "tekkou", "industri baja"),
    ], [
        ("鋼鉄でできています。", "Koutetsu de dekite imasu.", "Terbuat dari baja."),
        ("鉄鋼業です。", "Tekkougyou desu.", "Ini industri baja."),
    ]),
    ("gan_n1", "頑", ["ガン"], [], ["keras kepala", "stubborn"], 13, "頁", [
        ("頑固", "ganko", "keras kepala"),
        ("頑張る", "ganbaru", "berjuang keras"),
        ("頑丈", "ganjou", "kokoh"),
    ], [
        ("頑固な性格です。", "Ganko na seikaku desu.", "Kepribadian yang keras kepala."),
        ("頑張りました。", "Ganbarimashita.", "Berjuang keras."),
    ]),
    ("sa2_n1", "鎖", ["サ"], ["くさり"], ["rantai", "chain"], 18, "金", [
        ("鎖", "kusari", "rantai"),
        ("鎖国", "sakoku", "isolasi negara"),
        ("連鎖", "rensa", "rangkaian"),
    ], [
        ("鎖でつなぎました。", "Kusari de tsunagimashita.", "Menyambungkan dengan rantai."),
        ("鎖国時代です。", "Sakoku jidai desu.", "Ini era isolasi negara."),
    ]),
    ("sai7_n1", "彩", ["サイ"], ["いろど-る"], ["warna", "ragam", "color", "variety"], 11, "彡", [
        ("彩る", "irodoru", "mewarnai"),
        ("色彩", "shikisai", "warna"),
        ("多彩", "tasai", "beragam"),
    ], [
        ("花で彩りました。", "Hana de irodorimashita.", "Mewarnai dengan bunga."),
        ("多彩なイベントです。", "Tasai na ibento desu.", "Ini acara yang beragam."),
    ]),
    ("ma2_n1", "摩", ["マ"], [], ["gesekan", "rub", "friction"], 15, "手", [
        ("摩擦", "masatsu", "gesekan"),
        ("摩耗", "mamou", "keausan"),
        ("摩天楼", "matenrou", "pencakar langit"),
    ], [
        ("摩擦が生じました。", "Masatsu ga shoujimashita.", "Terjadi gesekan."),
        ("摩天楼が見えます。", "Matenrou ga miemasu.", "Terlihat pencakar langit."),
    ]),
    ("rei2_n1", "励", ["レイ"], ["はげ-む", "はげ-ます"], ["mendorong semangat", "encourage", "strive"], 7, "力", [
        ("励む", "hagemu", "berusaha keras"),
        ("激励", "gekirei", "dorongan semangat"),
        ("励ます", "hagemasu", "menyemangati"),
    ], [
        ("勉強に励んでいます。", "Benkyou ni hagende imasu.", "Berusaha keras belajar."),
        ("友達を励ましました。", "Tomodachi o hagemashimashita.", "Menyemangati teman."),
    ]),
    ("juu5_n1", "縦", ["ジュウ"], ["たて"], ["vertikal", "vertical"], 16, "糸", [
        ("縦", "tate", "vertikal"),
        ("縦断", "juudan", "melintasi secara vertikal"),
        ("縦横", "juuou", "panjang dan lebar"),
    ], [
        ("縦に並べました。", "Tate ni narabemashita.", "Disusun secara vertikal."),
        ("縦断しました。", "Juudan shimashita.", "Melintasi secara vertikal."),
    ]),
    ("ki11_n1", "輝", ["キ"], ["かがや-く"], ["bersinar", "shine", "radiate"], 15, "車", [
        ("輝く", "kagayaku", "bersinar"),
        ("輝き", "kagayaki", "kilauan"),
        ("光輝", "koki", "kecemerlangan"),
    ], [
        ("星が輝いています。", "Hoshi ga kagayaite imasu.", "Bintang bersinar."),
        ("輝きを放っています。", "Kagayaki o hanatte imasu.", "Memancarkan kilauan."),
    ]),
    ("chiku_n1", "蓄", ["チク"], ["たくわ-える"], ["menyimpan", "store", "accumulate"], 13, "艸", [
        ("蓄える", "takuwaeru", "menyimpan"),
        ("貯蓄", "chochiku", "tabungan"),
        ("蓄積", "chikuseki", "akumulasi"),
    ], [
        ("お金を蓄えました。", "Okane o takuwaemashita.", "Menyimpan uang."),
        ("貯蓄をしています。", "Chochiku o shite imasu.", "Sedang menabung."),
    ]),
    ("jiku_n1", "軸", ["ジク"], [], ["poros", "axis"], 12, "車", [
        ("軸", "jiku", "poros"),
        ("地軸", "chijiku", "poros bumi"),
        ("主軸", "shujiku", "poros utama"),
    ], [
        ("軸がぶれています。", "Jiku ga burete imasu.", "Porosnya goyah."),
        ("地軸が傾いています。", "Chijiku ga katamuite imasu.", "Poros bumi miring."),
    ]),
    ("jun2_n1", "巡", ["ジュン"], ["めぐ-る"], ["berkeliling", "patrol", "tour"], 6, "巛", [
        ("巡る", "meguru", "berkeliling"),
        ("巡回", "junkai", "patroli"),
        ("巡礼", "junrei", "ziarah"),
    ], [
        ("街を巡りました。", "Machi o megurimashita.", "Berkeliling kota."),
        ("巡礼の旅です。", "Junrei no tabi desu.", "Ini perjalanan ziarah."),
    ]),
    ("ka6_n1", "稼", ["カ"], ["かせ-ぐ"], ["mencari nafkah", "earn"], 15, "禾", [
        ("稼ぐ", "kasegu", "mencari nafkah"),
        ("稼働", "kadou", "operasional/beroperasi"),
        ("共稼ぎ", "tomokasegi", "suami istri bekerja"),
    ], [
        ("お金を稼ぎました。", "Okane o kasegimashita.", "Mencari nafkah."),
        ("工場が稼働しています。", "Koujou ga kadou shite imasu.", "Pabrik sedang beroperasi."),
    ]),
    ("shun2_n1", "瞬", ["シュン"], ["またた-く"], ["sekejap", "instant"], 18, "目", [
        ("瞬間", "shunkan", "momen/sekejap"),
        ("瞬く", "matataku", "berkedip"),
        ("一瞬", "isshun", "sesaat"),
    ], [
        ("瞬間を捉えました。", "Shunkan o toraemashita.", "Menangkap momen."),
        ("一瞬で終わりました。", "Isshun de owarimashita.", "Berakhir dalam sekejap."),
    ]),
    ("hou3_n1", "砲", ["ホウ"], [], ["meriam", "cannon", "gun"], 10, "石", [
        ("大砲", "taihou", "meriam"),
        ("砲撃", "hougeki", "tembakan meriam"),
        ("鉄砲", "teppou", "senjata api"),
    ], [
        ("大砲を撃ちました。", "Taihou o uchimashita.", "Menembakkan meriam."),
        ("鉄砲を持っています。", "Teppou o motte imasu.", "Membawa senjata api."),
    ]),
    ("fun2_n1", "噴", ["フン"], ["ふ-く"], ["menyembur", "spout", "erupt"], 15, "口", [
        ("噴火", "funka", "letusan gunung berapi"),
        ("噴水", "funsui", "air mancur"),
        ("噴出", "funshutsu", "semburan"),
    ], [
        ("火山が噴火しました。", "Kazan ga funka shimashita.", "Gunung berapi meletus."),
        ("噴水がきれいです。", "Funsui ga kirei desu.", "Air mancurnya indah."),
    ]),
    ("ko5_n1", "誇", ["コ"], ["ほこ-る"], ["bangga", "pride", "boast"], 13, "言", [
        ("誇る", "hokoru", "bangga"),
        ("誇り", "hokori", "kebanggaan"),
        ("誇張", "kochou", "melebih-lebihkan"),
    ], [
        ("実績を誇りました。", "Jisseki o hokorimashita.", "Bangga dengan prestasi."),
        ("誇張しないでください。", "Kochou shinaide kudasai.", "Jangan melebih-lebihkan."),
    ]),
    ("shou15_n1", "祥", ["ショウ"], [], ["keberuntungan", "auspicious"], 10, "示", [
        ("発祥", "hasshou", "asal-usul"),
        ("吉祥", "kisshou", "pertanda baik"),
        ("不祥事", "fushouji", "skandal"),
    ], [
        ("文明発祥の地です。", "Bunmei hasshou no chi desu.", "Ini tempat asal-usul peradaban."),
        ("不祥事が起きました。", "Fushouji ga okimashita.", "Skandal terjadi."),
    ]),
    ("sei9_n1", "牲", ["セイ"], [], ["kurban", "sacrifice"], 9, "牛", [
        ("牲畜", "seichiku", "hewan ternak/kurban"),
        ("犠牲", "gisei", "pengorbanan"),
        ("犠牲者", "giseisha", "korban"),
    ], [
        ("牲畜を育てています。", "Seichiku o sodatete imasu.", "Memelihara hewan ternak."),
        ("犠牲を払いました。", "Gisei o haraimashita.", "Memberikan pengorbanan."),
    ]),
    ("chitsu_n1", "秩", ["チツ"], [], ["ketertiban", "order"], 10, "禾", [
        ("秩序", "chitsujo", "ketertiban"),
        ("秩父", "Chichibu", "nama tempat"),
        ("無秩序", "muchitsujo", "kekacauan"),
    ], [
        ("秩序を守りました。", "Chitsujo o mamorimashita.", "Menjaga ketertiban."),
        ("無秩序な状態です。", "Muchitsujo na joutai desu.", "Ini keadaan yang kacau."),
    ]),
    ("tei5_n1", "帝", ["テイ"], [], ["kaisar", "emperor"], 9, "巾", [
        ("皇帝", "koutei", "kaisar"),
        ("帝国", "teikoku", "kekaisaran"),
        ("帝王", "teiou", "raja/kaisar"),
    ], [
        ("皇帝になりました。", "Koutei ni narimashita.", "Menjadi kaisar."),
        ("帝国が滅びました。", "Teikoku ga horobimashita.", "Kekaisaran itu runtuh."),
    ]),
    ("kou18_n1", "宏", ["コウ"], [], ["luas (nama)", "vast"], 7, "宀", [
        ("宏大", "koudai", "sangat luas"),
        ("宏壮", "kousou", "megah dan luas"),
        ("宏遠", "kouen", "jauh dan luas"),
    ], [
        ("宏大な土地です。", "Koudai na tochi desu.", "Ini tanah yang sangat luas."),
        ("宏壮な建物です。", "Kousou na tatemono desu.", "Ini bangunan yang megah."),
    ]),
    ("sa3_n1", "唆", ["サ"], ["そそのか-す"], ["menghasut", "instigate"], 10, "口", [
        ("唆す", "sosonokasu", "menghasut"),
        ("教唆", "kyousa", "penghasutan"),
        ("示唆", "shisa", "isyarat/indikasi"),
    ], [
        ("犯罪を唆しました。", "Hanzai o sosonokashimashita.", "Menghasut kejahatan."),
        ("示唆に富んでいます。", "Shisa ni tonde imasu.", "Penuh dengan indikasi."),
    ]),
    ("so5_n1", "阻", ["ソ"], ["はば-む"], ["menghalangi", "obstruct"], 8, "阜", [
        ("阻止", "soshi", "menghalangi"),
        ("阻む", "habamu", "menghalangi"),
        ("阻害", "sogai", "hambatan"),
    ], [
        ("計画を阻止しました。", "Keikaku o soshi shimashita.", "Menghalangi rencana."),
        ("成長を阻害しています。", "Seichou o sogai shite imasu.", "Menghambat pertumbuhan."),
    ]),
    ("tai5_n1", "泰", ["タイ"], [], ["tenteram", "agung", "peaceful", "grand"], 10, "水", [
        ("泰然", "taizen", "tenang"),
        ("安泰", "antai", "aman dan tenteram"),
        ("泰斗", "taito", "tokoh terkemuka"),
    ], [
        ("泰然としています。", "Taizen to shite imasu.", "Tetap tenang."),
        ("国家安泰を願います。", "Kokka antai o negaimasu.", "Berharap negara aman dan tenteram."),
    ]),
    ("wai_n1", "賄", ["ワイ"], ["まかな-う"], ["menyuap", "menyediakan", "bribe", "provide"], 13, "貝", [
        ("賄賂", "wairo", "suap"),
        ("賄う", "makanau", "menyediakan/mencukupi"),
        ("収賄", "shuuwai", "menerima suap"),
    ], [
        ("賄賂を渡しました。", "Wairo o watashimashita.", "Memberikan suap."),
        ("費用を賄いました。", "Hiyou o makanaimashita.", "Mencukupi biaya."),
    ]),
    ("boku2_n1", "撲", ["ボク"], [], ["memukul", "beat", "strike"], 15, "手", [
        ("相撲", "sumou", "sumo"),
        ("撲滅", "bokumetsu", "pemberantasan"),
        ("打撲", "daboku", "memar/benturan"),
    ], [
        ("相撲を見ました。", "Sumou o mimashita.", "Menonton sumo."),
        ("犯罪を撲滅しました。", "Hanzai o bokumetsu shimashita.", "Memberantas kejahatan."),
    ]),
    ("hori_n1", "堀", [], ["ほり"], ["parit", "moat", "ditch"], 11, "土", [
        ("堀", "hori", "parit"),
        ("堀端", "horibata", "tepi parit"),
        ("内堀", "uchibori", "parit dalam kastil"),
    ], [
        ("城の堀です。", "Shiro no hori desu.", "Ini parit kastil."),
        ("内堀を歩きました。", "Uchibori o arukimashita.", "Berjalan di sekitar parit dalam."),
    ]),
    ("kiku_n1", "菊", ["キク"], [], ["bunga krisan", "chrysanthemum"], 11, "艸", [
        ("菊", "kiku", "bunga krisan"),
        ("菊花", "kikka", "bunga krisan"),
        ("野菊", "nogiku", "krisan liar"),
    ], [
        ("菊の花が咲きました。", "Kiku no hana ga sakimashita.", "Bunga krisan mekar."),
        ("菊花展です。", "Kikkaten desu.", "Ini pameran bunga krisan."),
    ]),
    ("kou19_n1", "絞", ["コウ"], ["しぼ-る"], ["memeras", "mempersempit", "wring", "narrow down"], 12, "糸", [
        ("絞る", "shiboru", "memeras"),
        ("絞殺", "kousatsu", "mencekik"),
        ("絞り込む", "shiborikomu", "mempersempit"),
    ], [
        ("タオルを絞りました。", "Taoru o shiborimashita.", "Memeras handuk."),
        ("候補を絞り込みました。", "Kouho o shiborikomimashita.", "Mempersempit kandidat."),
    ]),
    ("en4_n1", "縁", ["エン"], ["ふち", "えん"], ["tepi", "jodoh", "takdir", "edge", "fate"], 15, "糸", [
        ("縁", "en", "jodoh/takdir"),
        ("縁側", "engawa", "teras kayu Jepang"),
        ("縁起", "engi", "pertanda"),
    ], [
        ("縁があります。", "En ga arimasu.", "Ada jodoh/takdir."),
        ("縁側でお茶を飲みました。", "Engawa de ocha o nomimashita.", "Minum teh di teras."),
    ]),
    ("yui_n1", "唯", ["ユイ"], ["ただ"], ["hanya", "only"], 11, "口", [
        ("唯一", "yuiitsu", "satu-satunya"),
        ("唯物論", "yuibutsuron", "materialisme"),
        ("唯々諾々", "iidakudaku", "patuh tanpa bantahan"),
    ], [
        ("唯一の方法です。", "Yuiitsu no houhou desu.", "Ini satu-satunya cara."),
        ("唯物論を学びました。", "Yuibutsuron o manabimashita.", "Mempelajari materialisme."),
    ]),
    ("bou2_n1", "膨", ["ボウ"], ["ふく-らむ", "ふく-れる"], ["mengembang", "swell", "expand"], 16, "肉", [
        ("膨らむ", "fukuramu", "mengembang"),
        ("膨張", "bouchou", "ekspansi"),
        ("膨大", "boudai", "sangat besar"),
    ], [
        ("風船が膨らみました。", "Fuusen ga fukuramimashita.", "Balon mengembang."),
        ("膨大な量です。", "Boudai na ryou desu.", "Jumlah yang sangat besar."),
    ]),
    ("tai6_n1", "耐", ["タイ"], ["た-える"], ["bertahan", "endure"], 9, "而", [
        ("耐える", "taeru", "bertahan"),
        ("耐久", "taikyuu", "daya tahan"),
        ("忍耐", "nintai", "kesabaran"),
    ], [
        ("痛みに耐えました。", "Itami ni taemashita.", "Bertahan dari rasa sakit."),
        ("忍耐が必要です。", "Nintai ga hitsuyou desu.", "Kesabaran diperlukan."),
    ]),
    ("juku_n1", "塾", ["ジュク"], [], ["bimbingan belajar", "cram school"], 14, "土", [
        ("塾", "juku", "bimbingan belajar"),
        ("塾生", "jukusei", "siswa bimbel"),
        ("学習塾", "gakushuujuku", "bimbingan belajar"),
    ], [
        ("塾に通っています。", "Juku ni kayotte imasu.", "Mengikuti bimbingan belajar."),
        ("学習塾で勉強しました。", "Gakushuujuku de benkyou shimashita.", "Belajar di bimbingan belajar."),
    ]),
    ("rou2_n1", "漏", ["ロウ"], ["も-る", "も-れる", "も-らす"], ["bocor", "leak"], 14, "水", [
        ("漏れる", "moreru", "bocor"),
        ("漏水", "rousui", "kebocoran air"),
        ("情報漏洩", "jouhou rouei", "kebocoran informasi"),
    ], [
        ("水が漏れています。", "Mizu ga morete imasu.", "Air bocor."),
        ("情報漏洩が発生しました。", "Jouhou rouei ga hassei shimashita.", "Terjadi kebocoran informasi."),
    ]),
    ("kei8_n1", "慶", ["ケイ"], [], ["perayaan", "celebration"], 15, "心", [
        ("慶祝", "keishuku", "perayaan"),
        ("慶事", "keiji", "acara bahagia"),
        ("慶応", "Keiou", "nama era/universitas"),
    ], [
        ("慶事がありました。", "Keiji ga arimashita.", "Ada acara bahagia."),
        ("慶応大学です。", "Keiou daigaku desu.", "Ini Universitas Keio."),
    ]),
    ("mou2_n1", "猛", ["モウ"], [], ["ganas", "fierce"], 11, "犬", [
        ("猛烈", "mouretsu", "sangat hebat/dahsyat"),
        ("猛獣", "moujuu", "binatang buas"),
        ("勇猛", "yuumou", "berani dan gagah"),
    ], [
        ("猛烈な雨です。", "Mouretsu na ame desu.", "Ini hujan yang sangat lebat."),
        ("猛獣に注意してください。", "Moujuu ni chuui shite kudasai.", "Waspadalah terhadap binatang buas."),
    ]),
    ("hou4_n1", "芳", ["ホウ"], ["かんば-しい", "かぐわ-しい"], ["harum", "fragrant"], 7, "艸", [
        ("芳香", "houkou", "keharuman"),
        ("芳名", "houmei", "nama terhormat"),
        ("芳しい", "kanbashii", "harum"),
    ], [
        ("芳香が漂っています。", "Houkou ga tadayotte imasu.", "Keharuman menyebar."),
        ("芳名帳に記入しました。", "Houmeichou ni kinyuu shimashita.", "Menulis di buku tamu."),
    ]),
    ("chou6_n1", "懲", ["チョウ"], ["こ-りる", "こ-らす"], ["menghukum", "punish", "deter"], 18, "心", [
        ("懲役", "choueki", "hukuman penjara"),
        ("懲罰", "choubatsu", "hukuman"),
        ("懲りる", "koriru", "jera"),
    ], [
        ("懲役刑を受けました。", "Choueki-kei o ukemashita.", "Menerima hukuman penjara."),
        ("もう懲りました。", "Mou korimashita.", "Sudah jera."),
    ]),
    ("ken10_n1", "剣", ["ケン"], ["つるぎ"], ["pedang", "sword"], 10, "刀", [
        ("剣", "tsurugi", "pedang"),
        ("剣道", "kendou", "kendo"),
        ("真剣", "shinken", "serius"),
    ], [
        ("剣道を習っています。", "Kendou o naratte imasu.", "Belajar kendo."),
        ("真剣に考えました。", "Shinken ni kangaemashita.", "Berpikir dengan serius."),
    ]),
    ("horo_n1", "幌", [], ["ほろ"], ["kap kendaraan", "canopy", "hood"], 13, "巾", [
        ("幌", "horo", "kap kendaraan"),
        ("幌馬車", "horobasha", "kereta kuda beratap"),
        ("札幌", "Sapporo", "nama kota"),
    ], [
        ("幌馬車に乗りました。", "Horobasha ni norimashita.", "Naik kereta kuda beratap."),
        ("札幌に住んでいます。", "Sapporo ni sunde imasu.", "Tinggal di Sapporo."),
    ]),
    ("shou16_n1", "彰", ["ショウ"], [], ["menonjolkan", "menghargai", "manifest", "honor"], 14, "彡", [
        ("表彰", "hyoushou", "penghargaan"),
        ("顕彰", "kenshou", "memberi penghargaan"),
        ("彰徳", "shoutoku", "menghormati kebajikan"),
    ], [
        ("表彰されました。", "Hyoushou saremashita.", "Diberi penghargaan."),
        ("顕彰式です。", "Kenshoushiki desu.", "Ini upacara pemberian penghargaan."),
    ]),
    ("ki12_n1", "棋", ["キ"], [], ["catur", "permainan papan", "chess", "board game"], 12, "木", [
        ("将棋", "shougi", "catur Jepang"),
        ("棋士", "kishi", "pemain profesional shogi"),
        ("棋院", "kiin", "sekolah/institut permainan papan"),
    ], [
        ("将棋を指しました。", "Shougi o sashimashita.", "Bermain shogi."),
        ("棋士になりました。", "Kishi ni narimashita.", "Menjadi pemain shogi profesional."),
    ]),
    ("chou7_n1", "丁", ["チョウ", "テイ"], [], ["blok jalan", "genap", "street block"], 2, "一", [
        ("丁目", "choume", "blok/distrik"),
        ("一丁", "icchou", "satu unit/blok"),
        ("丁寧", "teinei", "sopan/hati-hati"),
    ], [
        ("一丁目に住んでいます。", "Icchoume ni sunde imasu.", "Tinggal di blok satu."),
        ("丁寧に説明しました。", "Teinei ni setsumei shimashita.", "Menjelaskan dengan sopan."),
    ]),
    ("kou20_n1", "恒", ["コウ"], [], ["tetap", "konstan", "constant"], 9, "心", [
        ("恒星", "kousei", "bintang tetap"),
        ("恒久", "koukyuu", "permanen/abadi"),
        ("恒例", "kourei", "kebiasaan tahunan"),
    ], [
        ("恒星を観測しました。", "Kousei o kansoku shimashita.", "Mengamati bintang."),
        ("恒久平和を願います。", "Koukyuu heiwa o negaimasu.", "Berharap perdamaian abadi."),
    ]),
    ("you4_n1", "揚", ["ヨウ"], ["あ-げる", "あ-がる"], ["mengangkat", "menggoreng", "raise", "fry"], 12, "手", [
        ("揚げる", "ageru", "menggoreng"),
        ("揚力", "youryoku", "gaya angkat"),
        ("高揚", "kouyou", "semangat yang meningkat"),
    ], [
        ("天ぷらを揚げました。", "Tenpura o agemashita.", "Menggoreng tempura."),
        ("士気が高揚しました。", "Shiki ga kouyou shimashita.", "Semangat meningkat."),
    ]),
    ("bou3_n1", "冒", ["ボウ"], ["おか-す"], ["berani menghadapi risiko", "risk", "brave"], 9, "冂", [
        ("冒険", "bouken", "petualangan"),
        ("冒頭", "boutou", "awal/pembukaan"),
        ("冒す", "okasu", "mengambil risiko"),
    ], [
        ("冒険に出かけました。", "Bouken ni dekakemashita.", "Pergi bertualang."),
        ("冒頭で説明しました。", "Boutou de setsumei shimashita.", "Menjelaskan di awal."),
    ]),
    ("shi13_n1", "之", ["シ"], ["の", "これ"], ["partikel kepemilikan klasik", "of", "this"], 3, "丿", [
        ("之繞", "shinnyou", "nama radikal 辵"),
        ("右之助", "Unosuke", "contoh nama pria"),
        ("之", "kore", "partikel klasik dari/ini"),
    ], [
        ("之は昔の言い方です。", "Kore wa mukashi no iikata desu.", "Ini cara bicara zaman dahulu."),
        ("之繞という部首があります。", "Shinnyou to iu bushu ga arimasu.", "Ada radikal bernama shinnyou."),
    ]),
    ("sou8_n1", "曽", ["ソウ"], ["かつ-て"], ["pernah", "once", "former"], 11, "日", [
        ("曽て", "katsute", "pernah/dahulu"),
        ("曽祖父", "sousofu", "kakek buyut"),
        ("未曽有", "mizou", "belum pernah terjadi"),
    ], [
        ("曽てここに住んでいました。", "Katsute koko ni sunde imashita.", "Dulu tinggal di sini."),
        ("未曽有の災害です。", "Mizou no saigai desu.", "Ini bencana yang belum pernah terjadi."),
    ]),
    ("rin3_n1", "倫", ["リン"], [], ["etika", "ethics"], 10, "人", [
        ("倫理", "rinri", "etika"),
        ("人倫", "jinrin", "moralitas manusia"),
        ("不倫", "furin", "perselingkuhan"),
    ], [
        ("倫理を学びました。", "Rinri o manabimashita.", "Mempelajari etika."),
        ("不倫は許されません。", "Furin wa yurusaremasen.", "Perselingkuhan tidak dapat dimaafkan."),
    ]),
    ("chin2_n1", "陳", ["チン"], [], ["menyatakan", "usang", "state", "old"], 11, "阜", [
        ("陳列", "chinretsu", "pemajangan"),
        ("陳謝", "chinsha", "permintaan maaf resmi"),
        ("陳腐", "chinpu", "basi/klise"),
    ], [
        ("商品を陳列しました。", "Shouhin o chinretsu shimashita.", "Memajang barang."),
        ("陳腐な表現です。", "Chinpu na hyougen desu.", "Ini ungkapan yang klise."),
    ]),
    ("oku_n1", "憶", ["オク"], [], ["mengingat", "recollect"], 16, "心", [
        ("記憶", "kioku", "ingatan"),
        ("憶測", "okusoku", "spekulasi/dugaan"),
        ("追憶", "tsuioku", "kenangan"),
    ], [
        ("記憶があります。", "Kioku ga arimasu.", "Ada ingatan."),
        ("憶測にすぎません。", "Okusoku ni sugimasen.", "Hanya spekulasi."),
    ]),
    ("sen7_n1", "潜", ["セン"], ["ひそ-む", "もぐ-る"], ["menyelam", "tersembunyi", "submerge", "hidden"], 15, "水", [
        ("潜る", "moguru", "menyelam"),
        ("潜在", "senzai", "laten/tersembunyi"),
        ("潜水艦", "sensuikan", "kapal selam"),
    ], [
        ("海に潜りました。", "Umi ni mogurimashita.", "Menyelam di laut."),
        ("潜在能力があります。", "Senzai nouryoku ga arimasu.", "Memiliki potensi tersembunyi."),
    ]),
    ("ri4_n1", "梨", ["リ"], ["なし"], ["buah pir", "pear"], 11, "木", [
        ("梨", "nashi", "buah pir"),
        ("山梨", "Yamanashi", "nama prefektur"),
        ("梨園", "rien", "kebun pir/dunia kabuki"),
    ], [
        ("梨を食べました。", "Nashi o tabemashita.", "Makan buah pir."),
        ("山梨県に行きました。", "Yamanashi-ken ni ikimashita.", "Pergi ke Prefektur Yamanashi."),
    ]),
    ("jin3_n1", "仁", ["ジン"], [], ["kebajikan", "benevolence"], 4, "人", [
        ("仁", "jin", "kebajikan/cinta kasih"),
        ("仁義", "jingi", "kebajikan dan keadilan"),
        ("仁愛", "jin-ai", "kasih sayang"),
    ], [
        ("仁の心を持っています。", "Jin no kokoro o motte imasu.", "Memiliki hati yang penuh kebajikan."),
        ("仁義を重んじます。", "Jingi o omonjimasu.", "Menghargai kebajikan dan keadilan."),
    ]),
    ("koku_n1", "克", ["コク"], [], ["mengatasi", "overcome"], 7, "儿", [
        ("克服", "kokufuku", "mengatasi"),
        ("克己", "kokki", "disiplin diri"),
        ("相克", "soukoku", "konflik/pertentangan"),
    ], [
        ("困難を克服しました。", "Konnan o kokufuku shimashita.", "Mengatasi kesulitan."),
        ("克己心が大切です。", "Kokkishin ga taisetsu desu.", "Disiplin diri itu penting."),
    ]),
    ("gaku_n1", "岳", ["ガク"], ["たけ"], ["gunung/puncak", "mountain peak"], 8, "山", [
        ("山岳", "sangaku", "pegunungan"),
        ("岳父", "gakufu", "mertua laki-laki"),
        ("岳", "take", "puncak gunung"),
    ], [
        ("山岳地帯です。", "Sangaku chitai desu.", "Ini wilayah pegunungan."),
        ("岳父に会いました。", "Gakufu ni aimashita.", "Bertemu mertua laki-laki."),
    ]),
    ("gai2_n1", "概", ["ガイ"], [], ["garis besar", "outline", "approximate"], 14, "木", [
        ("概要", "gaiyou", "ringkasan"),
        ("概念", "gainen", "konsep"),
        ("大概", "taigai", "sebagian besar"),
    ], [
        ("概要を説明しました。", "Gaiyou o setsumei shimashita.", "Menjelaskan ringkasan."),
        ("概念を理解しました。", "Gainen o rikai shimashita.", "Memahami konsep."),
    ]),
    ("kou21_n1", "拘", ["コウ"], [], ["menahan", "terikat", "detain", "adhere"], 8, "手", [
        ("拘束", "kousoku", "penahanan"),
        ("拘置所", "kouchisho", "tempat penahanan"),
        ("拘る", "kodawaru", "mementingkan/terikat pada"),
    ], [
        ("拘束されました。", "Kousoku saremashita.", "Ditahan."),
        ("味に拘っています。", "Aji ni kodawatte imasu.", "Sangat memperhatikan rasa."),
    ]),
    ("bo_n1", "墓", ["ボ"], ["はか"], ["makam", "grave"], 13, "土", [
        ("墓", "haka", "makam"),
        ("墓地", "bochi", "pemakaman"),
        ("墓参り", "hakamairi", "ziarah kubur"),
    ], [
        ("墓参りに行きました。", "Hakamairi ni ikimashita.", "Pergi ziarah kubur."),
        ("墓地で花を供えました。", "Bochi de hana o sonaemashita.", "Menaruh bunga di pemakaman."),
    ]),
    ("moku_n1", "黙", ["モク"], ["だま-る"], ["diam", "silent"], 15, "黒", [
        ("黙る", "damaru", "diam"),
        ("沈黙", "chinmoku", "keheningan"),
        ("黙認", "mokunin", "membiarkan/mengizinkan diam-diam"),
    ], [
        ("黙っていました。", "Damatte imashita.", "Diam saja."),
        ("沈黙が続きました。", "Chinmoku ga tsuzukimashita.", "Keheningan berlanjut."),
    ]),
    ("su_n1", "須", ["ス"], [], ["harus", "must", "necessary"], 12, "頁", [
        ("必須", "hissu", "wajib/harus"),
        ("須要", "shuyou", "keperluan penting"),
        ("須らく", "subekaraku", "seharusnya"),
    ], [
        ("必須科目です。", "Hissu kamoku desu.", "Ini mata pelajaran wajib."),
        ("須らく努力すべきです。", "Subekaraku doryoku subeki desu.", "Seharusnya berusaha."),
    ]),
    ("hen_n1", "偏", ["ヘン"], ["かたよ-る"], ["bias", "one-sided"], 11, "人", [
        ("偏る", "katayoru", "bias/condong"),
        ("偏見", "henken", "prasangka"),
        ("偏差値", "hensachi", "nilai standar deviasi"),
    ], [
        ("意見が偏っています。", "Iken ga katayotte imasu.", "Pendapatnya bias."),
        ("偏見を持たないでください。", "Henken o motanaide kudasai.", "Jangan berprasangka."),
    ]),
    ("fun3_n1", "雰", ["フン"], [], ["suasana", "atmosphere"], 12, "雨", [
        ("雰囲気", "fun-iki", "suasana"),
        ("好雰囲気", "kou fun-iki", "suasana baik"),
        ("雰囲気作り", "fun-iki zukuri", "menciptakan suasana"),
    ], [
        ("いい雰囲気です。", "Ii fun-iki desu.", "Suasananya bagus."),
        ("雰囲気作りが上手です。", "Fun-iki zukuri ga jouzu desu.", "Pandai menciptakan suasana."),
    ]),
    ("guu_n1", "遇", ["グウ"], [], ["memperlakukan", "bertemu", "treat", "encounter"], 12, "辵", [
        ("待遇", "taiguu", "perlakuan/tunjangan"),
        ("遭遇", "souguu", "perjumpaan tak terduga"),
        ("境遇", "kyouguu", "keadaan/situasi hidup"),
    ], [
        ("待遇が良いです。", "Taiguu ga ii desu.", "Perlakuannya baik."),
        ("偶然遭遇しました。", "Guuzen souguu shimashita.", "Bertemu secara kebetulan."),
    ]),
    ("shi14_n1", "諮", ["シ"], ["はか-る"], ["berkonsultasi", "consult"], 16, "言", [
        ("諮問", "shimon", "konsultasi resmi"),
        ("諮る", "hakaru", "berkonsultasi"),
        ("諮問機関", "shimonkikan", "badan penasihat"),
    ], [
        ("諮問委員会です。", "Shimon iinkai desu.", "Ini komite penasihat."),
        ("専門家に諮りました。", "Senmonka ni hakarimashita.", "Berkonsultasi dengan ahli."),
    ]),
    ("kyou5_n1", "狭", ["キョウ"], ["せま-い"], ["sempit", "narrow"], 9, "犬", [
        ("狭い", "semai", "sempit"),
        ("狭める", "sebameru", "mempersempit"),
        ("偏狭", "henkyou", "sempit pikiran"),
    ], [
        ("部屋が狭いです。", "Heya ga semai desu.", "Kamarnya sempit."),
        ("視野を狭めました。", "Shiya o sebamemashita.", "Mempersempit pandangan."),
    ]),
    ("taku4_n1", "卓", ["タク"], [], ["meja", "unggul", "table", "excellent"], 8, "十", [
        ("食卓", "shokutaku", "meja makan"),
        ("卓越", "takuetsu", "keunggulan"),
        ("卓球", "takkyuu", "tenis meja"),
    ], [
        ("食卓を囲みました。", "Shokutaku o kakomimashita.", "Berkumpul di meja makan."),
        ("卓球をしています。", "Takkyuu o shite imasu.", "Bermain tenis meja."),
    ]),
    ("ki13_n1", "亀", ["キ"], ["かめ"], ["kura-kura", "turtle"], 11, "亀", [
        ("亀", "kame", "kura-kura"),
        ("亀裂", "kiretsu", "retakan"),
        ("海亀", "umigame", "penyu laut"),
    ], [
        ("亀を飼っています。", "Kame o katte imasu.", "Memelihara kura-kura."),
        ("壁に亀裂が入りました。", "Kabe ni kiretsu ga hairimashita.", "Dinding retak."),
    ]),
    ("ryou3_n1", "糧", ["リョウ"], ["かて"], ["bahan makanan", "provisions", "food"], 18, "米", [
        ("食糧", "shokuryou", "bahan pangan"),
        ("糧食", "ryoushoku", "perbekalan makanan"),
        ("心の糧", "kokoro no kate", "santapan rohani"),
    ], [
        ("食糧を備蓄しました。", "Shokuryou o bichiku shimashita.", "Menyimpan bahan pangan."),
        ("心の糧になりました。", "Kokoro no kate ni narimashita.", "Menjadi santapan rohani."),
    ]),
    ("kaji_n1", "梶", [], ["かじ"], ["kemudi", "rudder", "helm"], 11, "木", [
        ("梶", "kaji", "kemudi"),
        ("梶取り", "kajitori", "pengemudian kapal"),
        ("梶原", "Kajiwara", "contoh nama keluarga"),
    ], [
        ("梶を握りました。", "Kaji o nigirimashita.", "Memegang kemudi."),
        ("梶原さんに会いました。", "Kajiwara-san ni aimashita.", "Bertemu dengan Kajiwara."),
    ]),
    ("bo2_n1", "簿", ["ボ"], [], ["buku catatan", "register", "ledger"], 19, "竹", [
        ("帳簿", "choubo", "buku besar"),
        ("名簿", "meibo", "daftar nama"),
        ("家計簿", "kakeibo", "buku catatan keuangan rumah tangga"),
    ], [
        ("帳簿をつけました。", "Choubo o tsukemashita.", "Mencatat pembukuan."),
        ("家計簿をつけています。", "Kakeibo o tsukete imasu.", "Mencatat keuangan rumah tangga."),
    ]),
    ("ro2_n1", "炉", ["ロ"], [], ["perapian", "tungku", "furnace", "hearth"], 8, "火", [
        ("炉", "ro", "tungku"),
        ("暖炉", "danro", "perapian"),
        ("原子炉", "genshiro", "reaktor nuklir"),
    ], [
        ("暖炉で暖まりました。", "Danro de atatamarimashita.", "Menghangatkan diri dengan perapian."),
        ("原子炉が稼働しています。", "Genshiro ga kadou shite imasu.", "Reaktor nuklir sedang beroperasi."),
    ]),
    ("boku3_n1", "牧", ["ボク"], ["まき"], ["penggembalaan", "pasture", "graze"], 8, "牛", [
        ("牧場", "bokujou", "peternakan"),
        ("牧師", "bokushi", "pendeta"),
        ("牧草", "bokusou", "rumput ternak"),
    ], [
        ("牧場で働いています。", "Bokujou de hataraite imasu.", "Bekerja di peternakan."),
        ("牧師になりました。", "Bokushi ni narimashita.", "Menjadi pendeta."),
    ]),
    ("shu2_n1", "殊", ["シュ"], ["こと"], ["khusus", "special"], 10, "歹", [
        ("特殊", "tokushu", "khusus"),
        ("殊に", "koto ni", "terutama"),
        ("殊勝", "shushou", "terpuji"),
    ], [
        ("特殊な状況です。", "Tokushu na joukyou desu.", "Ini situasi khusus."),
        ("殊に注意してください。", "Koto ni chuui shite kudasai.", "Terutama hati-hatilah."),
    ]),
    ("shoku3_n1", "殖", ["ショク"], ["ふ-える", "ふ-やす"], ["berkembang biak", "increase", "breed"], 12, "歹", [
        ("増殖", "zoushoku", "perkembangbiakan"),
        ("殖える", "fueru", "bertambah"),
        ("養殖", "youshoku", "budidaya"),
    ], [
        ("細胞が増殖しました。", "Saibou ga zoushoku shimashita.", "Sel berkembang biak."),
        ("魚の養殖をしています。", "Sakana no youshoku o shite imasu.", "Melakukan budidaya ikan."),
    ]),
    ("kan20_n1", "艦", ["カン"], [], ["kapal perang", "warship"], 21, "舟", [
        ("軍艦", "gunkan", "kapal perang"),
        ("艦隊", "kantai", "armada"),
        ("潜水艦", "sensuikan", "kapal selam"),
    ], [
        ("軍艦を見ました。", "Gunkan o mimashita.", "Melihat kapal perang."),
        ("艦隊が出航しました。", "Kantai ga shukkou shimashita.", "Armada berlayar."),
    ]),
    ("hai4_n1", "輩", ["ハイ"], [], ["sesama", "golongan", "colleague", "fellow"], 15, "車", [
        ("先輩", "senpai", "senior"),
        ("後輩", "kouhai", "junior"),
        ("若輩", "jakuhai", "orang muda/pemula"),
    ], [
        ("先輩に相談しました。", "Senpai ni soudan shimashita.", "Berkonsultasi dengan senior."),
        ("後輩を指導しています。", "Kouhai o shidou shite imasu.", "Membimbing junior."),
    ]),
    ("ketsu_n1", "穴", ["ケツ"], ["あな"], ["lubang", "hole"], 5, "穴", [
        ("穴", "ana", "lubang"),
        ("穴場", "anaba", "tempat tersembunyi yang bagus"),
        ("墓穴", "boketsu", "lubang kubur"),
    ], [
        ("穴を掘りました。", "Ana o horimashita.", "Menggali lubang."),
        ("穴場のレストランです。", "Anaba no resutoran desu.", "Ini restoran tersembunyi yang bagus."),
    ]),
    ("ki14_n1", "奇", ["キ"], [], ["aneh", "strange"], 8, "大", [
        ("奇妙", "kimyou", "aneh"),
        ("奇跡", "kiseki", "keajaiban"),
        ("好奇心", "koukishin", "rasa ingin tahu"),
    ], [
        ("奇妙な出来事です。", "Kimyou na dekigoto desu.", "Ini kejadian yang aneh."),
        ("奇跡が起きました。", "Kiseki ga okimashita.", "Keajaiban terjadi."),
    ]),
    ("man_n1", "慢", ["マン"], [], ["sombong", "lamban", "arrogant", "slow"], 14, "心", [
        ("我慢", "gaman", "menahan diri/bersabar"),
        ("傲慢", "gouman", "sombong"),
        ("慢性", "mansei", "kronis"),
    ], [
        ("我慢しました。", "Gaman shimashita.", "Menahan diri."),
        ("慢性的な病気です。", "Manseiteki na byouki desu.", "Ini penyakit kronis."),
    ]),
    ("tsuru_n1", "鶴", [], ["つる"], ["burung bangau", "crane"], 21, "鳥", [
        ("鶴", "tsuru", "burung bangau"),
        ("折り鶴", "orizuru", "bangau lipat kertas"),
        ("千羽鶴", "senbazuru", "seribu bangau kertas"),
    ], [
        ("鶴を折りました。", "Tsuru o orimashita.", "Melipat bangau kertas."),
        ("千羽鶴を作りました。", "Senbazuru o tsukurimashita.", "Membuat seribu bangau kertas."),
    ]),
    ("bou4_n1", "謀", ["ボウ"], ["はか-る"], ["merencanakan (licik)", "scheme", "plot"], 16, "言", [
        ("陰謀", "inbou", "konspirasi"),
        ("謀反", "muhon", "pemberontakan"),
        ("参謀", "sanbou", "staf ahli strategi"),
    ], [
        ("陰謀を企てました。", "Inbou o kuwadatemashita.", "Merencanakan konspirasi."),
        ("参謀として働いています。", "Sanbou toshite hataraite imasu.", "Bekerja sebagai staf ahli strategi."),
    ]),
    ("dan2_n1", "暖", ["ダン"], ["あたた-かい", "あたた-める"], ["hangat", "warm"], 13, "日", [
        ("暖かい", "atatakai", "hangat"),
        ("暖房", "danbou", "pemanas ruangan"),
        ("温暖", "ondan", "hangat/mild"),
    ], [
        ("今日は暖かいです。", "Kyou wa atatakai desu.", "Hari ini hangat."),
        ("暖房をつけました。", "Danbou o tsukemashita.", "Menyalakan pemanas ruangan."),
    ]),
    ("shou17_n1", "昌", ["ショウ"], [], ["makmur", "prosperous"], 8, "日", [
        ("昌盛", "shousei", "kemakmuran"),
        ("隆昌", "ryuushou", "kemakmuran besar"),
        ("繁昌", "hanjou", "kemakmuran/ramai"),
    ], [
        ("商売繁昌を願います。", "Shoubai hanjou o negaimasu.", "Berharap bisnis makmur."),
        ("隆昌の時代でした。", "Ryuushou no jidai deshita.", "Ini adalah era kemakmuran."),
    ]),
    ("haku3_n1", "拍", ["ハク"], [], ["tepuk", "ketukan", "clap", "beat"], 8, "手", [
        ("拍手", "hakushu", "tepuk tangan"),
        ("拍子", "hyoushi", "ketukan/irama"),
        ("脈拍", "myakuhaku", "denyut nadi"),
    ], [
        ("拍手をしました。", "Hakushu o shimashita.", "Bertepuk tangan."),
        ("脈拍を測りました。", "Myakuhaku o hakarimashita.", "Mengukur denyut nadi."),
    ]),
    ("rou3_n1", "朗", ["ロウ"], ["ほが-らか"], ["ceria", "cheerful", "clear"], 10, "月", [
        ("明朗", "meirou", "ceria/terang"),
        ("朗らか", "hogaraka", "ceria"),
        ("朗読", "roudoku", "membaca dengan lantang"),
    ], [
        ("明朗な性格です。", "Meirou na seikaku desu.", "Kepribadian yang ceria."),
        ("詩を朗読しました。", "Shi o roudoku shimashita.", "Membacakan puisi dengan lantang."),
    ]),
    ("jou4_n1", "丈", ["ジョウ"], ["たけ"], ["tinggi", "ukuran", "height", "measure"], 3, "一", [
        ("丈夫", "joubu", "kuat/sehat"),
        ("背丈", "setake", "tinggi badan"),
        ("気丈", "kijou", "tabah"),
    ], [
        ("丈夫な体です。", "Joubu na karada desu.", "Tubuh yang kuat."),
        ("背丈が伸びました。", "Setake ga nobimashita.", "Tinggi badan bertambah."),
    ]),
    ("kan21_n1", "寛", ["カン"], ["ひろ-い"], ["murah hati", "generous", "lenient"], 13, "宀", [
        ("寛大", "kandai", "murah hati"),
        ("寛容", "kanyou", "toleran"),
        ("寛ぐ", "kutsurogu", "bersantai"),
    ], [
        ("寛大な処置です。", "Kandai na shochi desu.", "Ini tindakan yang murah hati."),
        ("寛容な心を持っています。", "Kanyou na kokoro o motte imasu.", "Memiliki hati yang toleran."),
    ]),
    ("fuku_n1", "覆", ["フク"], ["おお-う", "くつがえ-す"], ["menutupi", "membalikkan", "cover", "overturn"], 18, "西", [
        ("覆う", "oou", "menutupi"),
        ("覆面", "fukumen", "topeng penutup wajah"),
        ("転覆", "tenpuku", "terbalik/kudeta"),
    ], [
        ("布で覆いました。", "Nuno de ooimashita.", "Menutupi dengan kain."),
        ("政府が転覆しました。", "Seifu ga tenpuku shimashita.", "Pemerintah digulingkan."),
    ]),
    ("hou5_n1", "胞", ["ホウ"], [], ["sel", "cell", "placenta"], 9, "肉", [
        ("細胞", "saibou", "sel"),
        ("同胞", "doubou", "saudara sebangsa"),
        ("胞子", "houshi", "spora"),
    ], [
        ("細胞を観察しました。", "Saibou o kansatsu shimashita.", "Mengamati sel."),
        ("同胞を助けました。", "Doubou o tasukemashita.", "Membantu saudara sebangsa."),
    ]),
    ("kyuu5_n1", "泣", ["キュウ"], ["な-く"], ["menangis", "cry"], 8, "水", [
        ("泣く", "naku", "menangis"),
        ("泣き声", "nakigoe", "suara tangisan"),
        ("号泣", "goukyuu", "menangis keras"),
    ], [
        ("悲しくて泣きました。", "Kanashikute nakimashita.", "Menangis karena sedih."),
        ("号泣しました。", "Goukyuu shimashita.", "Menangis keras."),
    ]),
    ("kaku6_n1", "隔", ["カク"], ["へだ-てる", "へだ-たる"], ["memisahkan", "separate"], 13, "阜", [
        ("隔てる", "hedateru", "memisahkan"),
        ("間隔", "kankaku", "interval"),
        ("隔離", "kakuri", "isolasi/karantina"),
    ], [
        ("壁で隔てました。", "Kabe de hedatemashita.", "Dipisahkan oleh dinding."),
        ("隔離されました。", "Kakuri saremashita.", "Dikarantina."),
    ]),
    ("jou5_n1", "浄", ["ジョウ"], [], ["suci", "bersih", "pure", "clean"], 9, "水", [
        ("浄化", "jouka", "penyucian"),
        ("浄水", "jousui", "air bersih"),
        ("清浄", "seijou", "kesucian"),
    ], [
        ("水を浄化しました。", "Mizu o jouka shimashita.", "Menyucikan air."),
        ("清浄な空気です。", "Seijou na kuuki desu.", "Ini udara yang bersih."),
    ]),
    ("botsu_n1", "没", ["ボツ"], [], ["tenggelam", "meninggal", "sink", "die"], 7, "水", [
        ("没収", "bosshuu", "penyitaan"),
        ("没頭", "bottou", "tenggelam dalam/fokus"),
        ("病没", "byoubotsu", "meninggal karena sakit"),
    ], [
        ("財産が没収されました。", "Zaisan ga bosshuu saremashita.", "Harta disita."),
        ("仕事に没頭しています。", "Shigoto ni bottou shite imasu.", "Sangat fokus pada pekerjaan."),
    ]),
    ("ka7_n1", "暇", ["カ"], ["ひま"], ["waktu luang", "leisure", "spare time"], 13, "日", [
        ("暇", "hima", "waktu luang"),
        ("休暇", "kyuuka", "cuti"),
        ("暇つぶし", "himatsubushi", "membunuh waktu"),
    ], [
        ("今日は暇です。", "Kyou wa hima desu.", "Hari ini senggang."),
        ("休暇を取りました。", "Kyuuka o torimashita.", "Mengambil cuti."),
    ]),
    ("hai5_n1", "肺", ["ハイ"], [], ["paru-paru", "lung"], 9, "肉", [
        ("肺", "hai", "paru-paru"),
        ("肺炎", "haien", "pneumonia"),
        ("肺活量", "haikatsuryou", "kapasitas paru-paru"),
    ], [
        ("肺が痛いです。", "Hai ga itai desu.", "Paru-paru sakit."),
        ("肺活量を測りました。", "Haikatsuryou o hakarimashita.", "Mengukur kapasitas paru-paru."),
    ]),
    ("tei6_n1", "貞", ["テイ"], [], ["kesetiaan", "chastity", "loyalty"], 9, "貝", [
        ("貞操", "teisou", "kesucian/kesetiaan"),
        ("貞淑", "teishuku", "kesetiaan istri"),
        ("不貞", "futei", "ketidaksetiaan"),
    ], [
        ("貞操を守りました。", "Teisou o mamorimashita.", "Menjaga kesucian/kesetiaan."),
        ("不貞行為です。", "Futei koui desu.", "Ini tindakan tidak setia."),
    ]),
    ("sei10_n1", "靖", ["セイ"], ["やす-んじる"], ["tenteram (nama)", "peaceful"], 13, "青", [
        ("靖国神社", "Yasukuni Jinja", "nama kuil"),
        ("靖んじる", "yasunjiru", "menenangkan"),
        ("靖献", "seiken", "pengabdian setia"),
    ], [
        ("靖国神社を訪れました。", "Yasukuni Jinja o otozuremashita.", "Mengunjungi Kuil Yasukuni."),
        ("国を靖んじました。", "Kuni o yasunjimashita.", "Menenteramkan negara."),
    ]),
    ("kan22_n1", "鑑", ["カン"], ["かんが-みる"], ["cermin", "menilai", "mirror", "appraise"], 23, "金", [
        ("鑑定", "kantei", "penilaian ahli"),
        ("図鑑", "zukan", "buku bergambar/ensiklopedia"),
        ("鑑みる", "kangamiru", "mempertimbangkan"),
    ], [
        ("骨董品を鑑定しました。", "Kottouhin o kantei shimashita.", "Menilai barang antik."),
        ("状況を鑑みて決めました。", "Joukyou o kangamite kimemashita.", "Memutuskan dengan mempertimbangkan situasi."),
    ]),
    ("shi15_n1", "飼", ["シ"], ["か-う"], ["memelihara", "raise", "keep"], 13, "食", [
        ("飼う", "kau", "memelihara"),
        ("飼育", "shiiku", "pemeliharaan"),
        ("飼い主", "kainushi", "pemilik hewan"),
    ], [
        ("犬を飼っています。", "Inu o katte imasu.", "Memelihara anjing."),
        ("飼い主に会いました。", "Kainushi ni aimashita.", "Bertemu pemilik hewan."),
    ]),
    ("in2_n1", "陰", ["イン"], ["かげ"], ["bayangan", "negatif", "shade", "negative"], 11, "阜", [
        ("陰", "kage", "bayangan"),
        ("陰気", "inki", "suram"),
        ("陰謀", "inbou", "konspirasi"),
    ], [
        ("木陰で休みました。", "Kokage de yasumimashita.", "Beristirahat di bawah bayangan pohon."),
        ("陰気な雰囲気です。", "Inki na fun-iki desu.", "Suasana yang suram."),
    ]),
    ("mei_n1", "銘", ["メイ"], [], ["prasasti", "inscription"], 14, "金", [
        ("銘柄", "meigara", "merek"),
        ("感銘", "kanmei", "kesan mendalam"),
        ("座右の銘", "zayuu no mei", "motto hidup"),
    ], [
        ("銘柄を選びました。", "Meigara o erabimashita.", "Memilih merek."),
        ("感銘を受けました。", "Kanmei o ukemashita.", "Mendapat kesan mendalam."),
    ]),
    ("zui_n1", "随", ["ズイ"], [], ["mengikuti", "follow", "accompany"], 12, "阜", [
        ("随分", "zuibun", "cukup/sangat"),
        ("随時", "zuiji", "kapan saja"),
        ("追随", "tsuizui", "mengikuti jejak"),
    ], [
        ("随分上手になりました。", "Zuibun jouzu ni narimashita.", "Menjadi cukup mahir."),
        ("随時受付しています。", "Zuiji uketsuke shite imasu.", "Menerima pendaftaran kapan saja."),
    ]),
    ("retsu2_n1", "烈", ["レツ"], [], ["hebat", "dahsyat", "intense", "fierce"], 10, "火", [
        ("強烈", "kyouretsu", "sangat kuat"),
        ("熱烈", "netsuretsu", "penuh semangat"),
        ("烈火", "rekka", "api yang berkobar"),
    ], [
        ("強烈な印象です。", "Kyouretsu na inshou desu.", "Ini kesan yang sangat kuat."),
        ("熱烈に応援しました。", "Netsuretsu ni ouen shimashita.", "Mendukung dengan penuh semangat."),
    ]),
    ("jin4_n1", "尋", ["ジン"], ["たず-ねる"], ["bertanya", "mencari", "inquire"], 12, "寸", [
        ("尋ねる", "tazuneru", "bertanya"),
        ("尋問", "jinmon", "interogasi"),
        ("尋常", "jinjou", "biasa/normal"),
    ], [
        ("道を尋ねました。", "Michi o tazunemashita.", "Bertanya jalan."),
        ("尋問を受けました。", "Jinmon o ukemashita.", "Menjalani interogasi."),
    ]),
    ("fuchi_n1", "渕", [], ["ふち"], ["lubuk sungai", "deep pool"], 11, "水", [
        ("渕", "fuchi", "lubuk sungai"),
        ("深渕", "shinen", "jurang dalam"),
        ("渕上", "Fuchigami", "contoh nama keluarga"),
    ], [
        ("川の渕で遊びました。", "Kawa no fuchi de asobimashita.", "Bermain di lubuk sungai."),
        ("渕上さんに会いました。", "Fuchigami-san ni aimashita.", "Bertemu dengan Fuchigami."),
    ]),
    ("kou22_n1", "稿", ["コウ"], [], ["naskah", "manuscript", "draft"], 15, "禾", [
        ("原稿", "genkou", "naskah asli"),
        ("草稿", "soukou", "draf kasar"),
        ("投稿", "toukou", "mengirim/posting"),
    ], [
        ("原稿を書きました。", "Genkou o kakimashita.", "Menulis naskah."),
        ("SNSに投稿しました。", "SNS ni toukou shimashita.", "Memposting di media sosial."),
    ]),
    ("tan3_n1", "丹", ["タン"], [], ["merah", "obat mujarab", "red", "cinnabar"], 4, "丶", [
        ("丹念", "tannen", "teliti"),
        ("丹精", "tansei", "kerja keras dengan tulus"),
        ("丹田", "tanden", "titik pusat energi di perut"),
    ], [
        ("丹念に作りました。", "Tannen ni tsukurimashita.", "Dibuat dengan teliti."),
        ("丹精込めて育てました。", "Tansei komete sodatemashita.", "Dirawat dengan sepenuh hati."),
    ]),
    ("kei9_n1", "啓", ["ケイ"], [], ["mencerahkan", "enlighten"], 11, "口", [
        ("啓発", "keihatsu", "pencerahan"),
        ("啓示", "keiji", "wahyu/petunjuk"),
        ("拝啓", "haikei", "salam pembuka surat formal"),
    ], [
        ("自己啓発をしています。", "Jiko keihatsu o shite imasu.", "Melakukan pengembangan diri."),
        ("拝啓、貴社ますますご清栄のことと。", "Haikei, kisha masumasu goseiei no koto to.", "Salam pembuka surat formal."),
    ]),
    ("ya_n1", "也", ["ヤ"], [], ["partikel penegasan klasik", "also"], 3, "乙", [
        ("也", "nari", "partikel penegasan klasik adalah"),
        ("健也", "Kenya", "contoh nama pria"),
        ("也", "ya", "partikel akhir kalimat klasik"),
    ], [
        ("「也」は古典文で使われます。", "\"Ya\" wa koten bun de tsukawaremasu.", "\"Ya\" digunakan dalam teks klasik."),
        ("健也という名前です。", "Kenya to iu namae desu.", "Ini nama \"Kenya\"."),
    ]),
    ("kyuu6_n1", "丘", ["キュウ"], ["おか"], ["bukit", "hill"], 5, "一", [
        ("丘", "oka", "bukit"),
        ("砂丘", "sakyuu", "bukit pasir"),
        ("丘陵", "kyuuryou", "perbukitan"),
    ], [
        ("丘に登りました。", "Oka ni noborimashita.", "Mendaki bukit."),
        ("砂丘を歩きました。", "Sakyuu o arukimashita.", "Berjalan di bukit pasir."),
    ]),
    ("tou8_n1", "棟", ["トウ"], ["むね", "むな"], ["bangunan", "wuwungan", "building", "ridge"], 12, "木", [
        ("病棟", "byoutou", "bangsal rumah sakit"),
        ("棟", "mune", "bubungan atap"),
        ("別棟", "betsutou", "bangunan terpisah"),
    ], [
        ("病棟に入院しました。", "Byoutou ni nyuuin shimashita.", "Dirawat di bangsal rumah sakit."),
        ("別棟に住んでいます。", "Betsutou ni sunde imasu.", "Tinggal di bangunan terpisah."),
    ]),
    ("jou6_n1", "壌", ["ジョウ"], [], ["tanah", "soil"], 16, "土", [
        ("土壌", "dojou", "tanah"),
        ("天壌", "tenjou", "langit dan bumi"),
        ("壌土", "jouto", "tanah subur"),
    ], [
        ("土壌が肥えています。", "Dojou ga koete imasu.", "Tanahnya subur."),
        ("土壌汚染です。", "Dojou osen desu.", "Ini polusi tanah."),
    ]),
    ("man2_n1", "漫", ["マン"], [], ["acak", "lepas", "random", "loose"], 14, "水", [
        ("漫画", "manga", "komik"),
        ("散漫", "sanman", "tidak fokus"),
        ("漫然と", "manzen to", "sembarangan"),
    ], [
        ("漫画を読みました。", "Manga o yomimashita.", "Membaca komik."),
        ("散漫な態度です。", "Sanman na taido desu.", "Ini sikap yang tidak fokus."),
    ]),
    ("gen3_n1", "玄", ["ゲン"], [], ["mendalam", "gelap", "profound", "dark"], 5, "玄", [
        ("玄関", "genkan", "pintu masuk rumah"),
        ("玄米", "genmai", "beras merah"),
        ("玄人", "kurouto", "ahli/profesional"),
    ], [
        ("玄関で靴を脱ぎました。", "Genkan de kutsu o nugimashita.", "Melepas sepatu di pintu masuk."),
        ("玄米を食べています。", "Genmai o tabete imasu.", "Makan beras merah."),
    ]),
    ("nen_n1", "粘", ["ネン"], ["ねば-る"], ["lengket", "sticky"], 11, "米", [
        ("粘る", "nebaru", "lengket/bertahan"),
        ("粘土", "nendo", "tanah liat"),
        ("粘着", "nenchaku", "perekat"),
    ], [
        ("最後まで粘りました。", "Saigo made nebarimashita.", "Bertahan sampai akhir."),
        ("粘土で作りました。", "Nendo de tsukurimashita.", "Dibuat dari tanah liat."),
    ]),
    ("go2_n1", "悟", ["ゴ"], ["さと-る"], ["menyadari", "realize", "enlighten"], 10, "心", [
        ("悟る", "satoru", "menyadari"),
        ("覚悟", "kakugo", "kesiapan mental"),
        ("悟り", "satori", "pencerahan"),
    ], [
        ("真実を悟りました。", "Shinjitsu o satorimashita.", "Menyadari kebenaran."),
        ("覚悟を決めました。", "Kakugo o kimemashita.", "Membulatkan tekad."),
    ]),
    ("ho2_n1", "舗", ["ホ"], [], ["toko", "mengaspal", "shop", "pave"], 15, "舎", [
        ("老舗", "shinise", "toko lama terkenal"),
        ("舗装", "hosou", "pengaspalan"),
        ("店舗", "tenpo", "toko"),
    ], [
        ("老舗のお店です。", "Shinise no omise desu.", "Ini toko lama yang terkenal."),
        ("道路が舗装されました。", "Douro ga housou saremashita.", "Jalan diaspal."),
    ]),
    ("nin_n1", "妊", ["ニン"], [], ["hamil", "pregnant"], 7, "女", [
        ("妊娠", "ninshin", "kehamilan"),
        ("妊婦", "ninpu", "ibu hamil"),
        ("避妊", "hinin", "kontrasepsi"),
    ], [
        ("妊娠しました。", "Ninshin shimashita.", "Hamil."),
        ("妊婦さんです。", "Ninpu-san desu.", "Ini ibu hamil."),
    ]),
    ("juku2_n1", "熟", ["ジュク"], ["う-れる"], ["matang", "ripe", "mature"], 15, "火", [
        ("熟す", "jukusu", "matang"),
        ("成熟", "seijuku", "kedewasaan"),
        ("熟練", "jukuren", "mahir"),
    ], [
        ("果物が熟しました。", "Kudamono ga jukushimashita.", "Buah matang."),
        ("熟練した技術者です。", "Jukuren shita gijutsusha desu.", "Ini teknisi yang mahir."),
    ]),
    ("kyoku_n1", "旭", ["キョク"], ["あさひ"], ["matahari pagi", "morning sun"], 6, "日", [
        ("旭日", "kyokujitsu", "matahari terbit"),
        ("旭", "asahi", "matahari pagi"),
        ("旭川", "Asahikawa", "nama kota"),
    ], [
        ("旭日が昇りました。", "Kyokujitsu ga noborimashita.", "Matahari pagi terbit."),
        ("旭川に住んでいます。", "Asahikawa ni sunde imasu.", "Tinggal di Asahikawa."),
    ]),
    ("on_n1", "恩", ["オン"], [], ["budi baik", "grace", "favor"], 10, "心", [
        ("恩", "on", "budi baik"),
        ("恩恵", "onkei", "manfaat/berkah"),
        ("恩人", "onjin", "orang yang berjasa"),
    ], [
        ("恩を感じています。", "On o kanjite imasu.", "Merasa berhutang budi."),
        ("恩人に感謝しています。", "Onjin ni kansha shite imasu.", "Berterima kasih kepada orang yang berjasa."),
    ]),
    ("tou9_n1", "騰", ["トウ"], [], ["melonjak", "soar", "rise"], 20, "馬", [
        ("高騰", "koutou", "melonjak tinggi"),
        ("沸騰", "futtou", "mendidih"),
        ("騰貴", "touki", "kenaikan harga"),
    ], [
        ("物価が高騰しました。", "Bukka ga koutou shimashita.", "Harga melonjak."),
        ("お湯が沸騰しました。", "Oyu ga futtou shimashita.", "Air mendidih."),
    ]),
    ("ou3_n1", "往", ["オウ"], [], ["pergi", "masa lalu", "go", "past"], 8, "彳", [
        ("往復", "oufuku", "pulang pergi"),
        ("往来", "ourai", "lalu lintas"),
        ("往々にして", "ouou ni shite", "sering kali"),
    ], [
        ("往復切符を買いました。", "Oufuku kippu o kaimashita.", "Membeli tiket pulang pergi."),
        ("往来が激しいです。", "Ourai ga hageshii desu.", "Lalu lintasnya ramai."),
    ]),
    ("tou10_n1", "豆", ["トウ"], ["まめ"], ["kacang", "bean"], 7, "豆", [
        ("豆", "mame", "kacang"),
        ("大豆", "daizu", "kedelai"),
        ("豆腐", "toufu", "tahu"),
    ], [
        ("豆を食べました。", "Mame o tabemashita.", "Makan kacang."),
        ("大豆から作られています。", "Daizu kara tsukurarete imasu.", "Dibuat dari kedelai."),
    ]),
    ("sui2_n1", "遂", ["スイ"], ["と-げる"], ["mencapai", "accomplish"], 12, "辵", [
        ("遂に", "tsui ni", "akhirnya"),
        ("遂げる", "togeru", "mencapai"),
        ("完遂", "kansui", "penyelesaian penuh"),
    ], [
        ("遂に完成しました。", "Tsui ni kansei shimashita.", "Akhirnya selesai."),
        ("目的を遂げました。", "Mokuteki o togemashita.", "Mencapai tujuan."),
    ]),
    ("kyou6_n1", "狂", ["キョウ"], ["くる-う"], ["gila", "crazy"], 7, "犬", [
        ("狂う", "kuruu", "menjadi gila/kacau"),
        ("狂気", "kyouki", "kegilaan"),
        ("熱狂", "nekkyou", "antusiasme membara"),
    ], [
        ("予定が狂いました。", "Yotei ga kuruimashita.", "Rencana kacau."),
        ("熱狂的なファンです。", "Nekkyouteki na fan desu.", "Ini penggemar yang sangat antusias."),
    ]),
    ("tochi_n1", "栃", [], ["とち"], ["pohon buckeye Jepang", "horse chestnut"], 9, "木", [
        ("栃木", "Tochigi", "nama prefektur"),
        ("栃の木", "tochi no ki", "pohon buckeye Jepang"),
        ("栃餅", "tochimochi", "kue mochi dari buckeye"),
    ], [
        ("栃木県に行きました。", "Tochigi-ken ni ikimashita.", "Pergi ke Prefektur Tochigi."),
        ("栃餅を食べました。", "Tochimochi o tabemashita.", "Makan kue mochi buckeye."),
    ]),
    ("ki15_n1", "岐", ["キ"], [], ["percabangan", "branch", "fork"], 7, "山", [
        ("岐路", "kiro", "persimpangan jalan"),
        ("岐阜", "Gifu", "nama prefektur"),
        ("分岐", "bunki", "percabangan"),
    ], [
        ("人生の岐路に立っています。", "Jinsei no kiro ni tatte imasu.", "Berdiri di persimpangan hidup."),
        ("岐阜県に住んでいます。", "Gifu-ken ni sunde imasu.", "Tinggal di Prefektur Gifu."),
    ]),
    ("hei2_n1", "陛", ["ヘイ"], [], ["yang mulia", "majesty"], 10, "阜", [
        ("陛下", "heika", "yang mulia"),
        ("天皇陛下", "Tennou Heika", "Yang Mulia Kaisar"),
        ("両陛下", "ryouheika", "kedua yang mulia"),
    ], [
        ("天皇陛下がいらっしゃいました。", "Tennou Heika ga irasshaimashita.", "Yang Mulia Kaisar datang."),
        ("両陛下にお会いしました。", "Ryouheika ni oai shimashita.", "Bertemu dengan kedua yang mulia."),
    ]),
    ("i8_n1", "緯", ["イ"], [], ["garis lintang", "latitude", "weft"], 16, "糸", [
        ("緯度", "ido", "garis lintang"),
        ("経緯", "keii", "kronologi/detail"),
        ("北緯", "hokui", "lintang utara"),
    ], [
        ("緯度を測定しました。", "Ido o sokutei shimashita.", "Mengukur garis lintang."),
        ("経緯を説明しました。", "Keii o setsumei shimashita.", "Menjelaskan kronologi."),
    ]),
    ("bai3_n1", "培", ["バイ"], ["つちか-う"], ["membudidayakan", "cultivate"], 11, "土", [
        ("培う", "tsuchikau", "membudidayakan/mengembangkan"),
        ("栽培", "saibai", "budidaya"),
        ("培養", "baiyou", "pembiakan/kultur"),
    ], [
        ("力を培いました。", "Chikara o tsuchikaimashita.", "Mengembangkan kekuatan."),
        ("野菜を栽培しています。", "Yasai o saibai shite imasu.", "Membudidayakan sayuran."),
    ]),
    ("sui3_n1", "衰", ["スイ"], ["おとろ-える"], ["melemah", "decline", "weaken"], 10, "衣", [
        ("衰える", "otoroeru", "melemah"),
        ("衰退", "suitai", "kemunduran"),
        ("老衰", "rousui", "kelemahan karena usia tua"),
    ], [
        ("体力が衰えました。", "Tairyoku ga otoroemashita.", "Stamina melemah."),
        ("経済が衰退しています。", "Keizai ga suitai shite imasu.", "Ekonomi mengalami kemunduran."),
    ]),
    ("tei7_n1", "艇", ["テイ"], [], ["perahu", "boat"], 13, "舟", [
        ("艇", "tei", "perahu kecil"),
        ("競艇", "kyoutei", "balap perahu"),
        ("潜水艇", "sensuitei", "kapal selam kecil"),
    ], [
        ("競艇を見ました。", "Kyoutei o mimashita.", "Menonton balap perahu."),
        ("潜水艇に乗りました。", "Sensuitei ni norimashita.", "Naik kapal selam kecil."),
    ]),
    ("kutsu_n1", "屈", ["クツ"], ["かが-む"], ["menekuk", "menyerah", "bend", "yield"], 8, "尸", [
        ("屈伸", "kusshin", "membungkuk dan meregang"),
        ("屈服", "kuppuku", "menyerah"),
        ("理屈", "rikutsu", "alasan/logika"),
    ], [
        ("屈伸運動をしました。", "Kusshin undou o shimashita.", "Melakukan gerakan membungkuk dan meregang."),
        ("理屈っぽいです。", "Rikutsuppoi desu.", "Terlalu suka berargumen."),
    ]),
    ("kei10_n1", "径", ["ケイ"], [], ["diameter", "jalan", "diameter", "path"], 8, "彳", [
        ("直径", "chokkei", "diameter"),
        ("半径", "hankei", "jari-jari"),
        ("口径", "koukei", "kaliber"),
    ], [
        ("直径を測りました。", "Chokkei o hakarimashita.", "Mengukur diameter."),
        ("半径5メートルです。", "Hankei go meetoru desu.", "Jari-jarinya 5 meter."),
    ]),
    ("tan4_n1", "淡", ["タン"], ["あわ-い"], ["tipis", "pudar", "light", "pale"], 11, "水", [
        ("淡い", "awai", "pudar/samar"),
        ("淡水", "tansui", "air tawar"),
        ("冷淡", "reitan", "dingin/acuh"),
    ], [
        ("淡い色です。", "Awai iro desu.", "Ini warna yang pudar."),
        ("淡水魚です。", "Tansuigyo desu.", "Ini ikan air tawar."),
    ]),
    ("chuu3_n1", "抽", ["チュウ"], [], ["mengambil", "menarik", "extract"], 8, "手", [
        ("抽選", "chuusen", "undian"),
        ("抽出", "chuushutsu", "ekstraksi"),
        ("抽象的", "chuushouteki", "abstrak"),
    ], [
        ("抽選に当たりました。", "Chuusen ni atarimashita.", "Menang undian."),
        ("抽象的な概念です。", "Chuushouteki na gainen desu.", "Ini konsep yang abstrak."),
    ]),
    ("hi4_n1", "披", ["ヒ"], [], ["membuka", "mengungkapkan", "open", "disclose"], 8, "手", [
        ("披露", "hirou", "memamerkan/mengumumkan"),
        ("披露宴", "hirouen", "resepsi pernikahan"),
        ("披見", "hiken", "membaca dengan seksama"),
    ], [
        ("結婚披露宴です。", "Kekkon hirouen desu.", "Ini resepsi pernikahan."),
        ("新曲を披露しました。", "Shinkyoku o hirou shimashita.", "Menampilkan lagu baru."),
    ]),
    ("tei8_n1", "廷", ["テイ"], [], ["pengadilan", "istana", "court"], 7, "廴", [
        ("法廷", "houtei", "ruang sidang pengadilan"),
        ("宮廷", "kyuutei", "istana kerajaan"),
        ("出廷", "shuttei", "hadir di pengadilan"),
    ], [
        ("法廷で裁かれました。", "Houtei de sabakaremashita.", "Diadili di pengadilan."),
        ("宮廷生活です。", "Kyuutei seikatsu desu.", "Ini kehidupan istana."),
    ]),
    ("kin3_n1", "錦", ["キン"], ["にしき"], ["kain sutra bermotif", "brocade"], 16, "金", [
        ("錦", "nishiki", "kain sutra bermotif"),
        ("錦絵", "nishikie", "cetakan kayu warna-warni"),
        ("錦鯉", "nishikigoi", "ikan koi"),
    ], [
        ("錦鯉を飼っています。", "Nishikigoi o katte imasu.", "Memelihara ikan koi."),
        ("錦絵を見ました。", "Nishikie o mimashita.", "Melihat cetakan kayu warna-warni."),
    ]),
    ("jun3_n1", "准", ["ジュン"], [], ["setingkat di bawah", "quasi", "associate"], 10, "冫", [
        ("准教授", "junkyouju", "associate professor"),
        ("批准", "hijun", "ratifikasi"),
        ("准将", "junshou", "brigadir jenderal"),
    ], [
        ("准教授になりました。", "Junkyouju ni narimashita.", "Menjadi associate professor."),
        ("条約を批准しました。", "Jouyaku o hijun shimashita.", "Meratifikasi perjanjian."),
    ]),
    ("sho_n1", "暑", ["ショ"], ["あつ-い"], ["panas", "hot"], 12, "日", [
        ("暑い", "atsui", "panas"),
        ("暑さ", "atsusa", "kepanasan"),
        ("残暑", "zansho", "panas sisa musim panas"),
    ], [
        ("今日は暑いです。", "Kyou wa atsui desu.", "Hari ini panas."),
        ("残暑が続いています。", "Zansho ga tsuzuite imasu.", "Panas sisa musim panas masih berlanjut."),
    ]),
    ("iso_n1", "磯", [], ["いそ"], ["pantai berbatu", "rocky shore"], 17, "石", [
        ("磯", "iso", "pantai berbatu"),
        ("磯釣り", "isozuri", "memancing di pantai berbatu"),
        ("磯辺", "isobe", "tepi pantai berbatu"),
    ], [
        ("磯で釣りをしました。", "Iso de tsuri o shimashita.", "Memancing di pantai berbatu."),
        ("磯辺を散歩しました。", "Isobe o sanpo shimashita.", "Berjalan-jalan di tepi pantai berbatu."),
    ]),
    ("shou18_n1", "奨", ["ショウ"], [], ["mendorong", "mendukung", "encourage"], 13, "大", [
        ("奨励", "shourei", "dorongan/anjuran"),
        ("推奨", "suishou", "rekomendasi"),
        ("奨学金", "shougakukin", "beasiswa"),
    ], [
        ("奨学金をもらいました。", "Shougakukin o moraimashita.", "Mendapat beasiswa."),
        ("貯蓄を奨励しています。", "Chochiku o shourei shite imasu.", "Mendorong menabung."),
    ]),
    ("shin7_n1", "浸", ["シン"], ["ひた-す", "ひた-る"], ["merendam", "soak", "permeate"], 10, "水", [
        ("浸す", "hitasu", "merendam"),
        ("浸水", "shinsui", "kebanjiran"),
        ("浸透", "shintou", "penetrasi/peresapan"),
    ], [
        ("水に浸しました。", "Mizu ni hitashimashita.", "Merendam dalam air."),
        ("家が浸水しました。", "Ie ga shinsui shimashita.", "Rumah kebanjiran."),
    ]),
    ("jou7_n1", "剰", ["ジョウ"], [], ["kelebihan", "surplus"], 11, "刀", [
        ("余剰", "yojou", "surplus"),
        ("剰余", "jouyo", "sisa"),
        ("過剰", "kajou", "berlebihan"),
    ], [
        ("余剰生産物です。", "Yojou seisanbutsu desu.", "Ini produk surplus."),
        ("過剰摂取です。", "Kajou sesshu desu.", "Ini konsumsi berlebihan."),
    ]),
    ("tan5_n1", "胆", ["タン"], [], ["kantong empedu", "keberanian", "gallbladder", "courage"], 9, "肉", [
        ("胆嚢", "tannou", "kantong empedu"),
        ("大胆", "daitan", "berani"),
        ("胆力", "tanryoku", "keberanian"),
    ], [
        ("大胆な決断です。", "Daitan na ketsudan desu.", "Ini keputusan yang berani."),
        ("胆力があります。", "Tanryoku ga arimasu.", "Memiliki keberanian."),
    ]),
    ("sen8_n1", "繊", ["セン"], [], ["serat", "fiber"], 17, "糸", [
        ("繊維", "sen-i", "serat"),
        ("繊細", "sensai", "halus/sensitif"),
        ("化繊", "kasen", "serat sintetis"),
    ], [
        ("繊維製品です。", "Sen-i seihin desu.", "Ini produk tekstil."),
        ("繊細な性格です。", "Sensai na seikaku desu.", "Kepribadian yang halus."),
    ]),
    ("koma_n1", "駒", [], ["こま"], ["bidak catur", "kuda kecil", "chess piece", "pony"], 15, "馬", [
        ("駒", "koma", "bidak permainan"),
        ("将棋の駒", "shougi no koma", "bidak shogi"),
        ("持ち駒", "mochigoma", "bidak yang dipegang"),
    ], [
        ("将棋の駒を並べました。", "Shougi no koma o narabemashita.", "Menyusun bidak shogi."),
        ("持ち駒を使いました。", "Mochigoma o tsukaimashita.", "Menggunakan bidak yang dipegang."),
    ]),
    ("kyo5_n1", "虚", ["キョ"], ["むな-しい"], ["kosong", "palsu", "empty", "false"], 11, "虍", [
        ("虚偽", "kyogi", "kebohongan"),
        ("虚無", "kyomu", "kekosongan"),
        ("謙虚", "kenkyo", "rendah hati"),
    ], [
        ("虚偽の報告です。", "Kyogi no houkoku desu.", "Ini laporan bohong."),
        ("謙虚な態度です。", "Kenkyo na taido desu.", "Sikap yang rendah hati."),
    ]),
    ("shi16_n1", "孜", ["シ"], [], ["rajin (arkais)", "diligent"], 7, "子", [
        ("孜々", "shishi", "tekun/rajin"),
        ("孜々努力", "shishi doryoku", "usaha yang tekun terus-menerus"),
        ("孜孜", "shishi", "variasi penulisan tekun/rajin"),
    ], [
        ("孜々として勉学に励みました。", "Shishi to shite bengaku ni hagemimashita.", "Belajar dengan tekun."),
        ("孜々たる努力です。", "Shishitaru doryoku desu.", "Ini usaha yang tekun."),
    ]),
    ("rei3_n1", "霊", ["レイ"], ["たま"], ["roh", "spirit"], 15, "雨", [
        ("霊魂", "reikon", "roh/jiwa"),
        ("幽霊", "yuurei", "hantu"),
        ("精霊", "seirei", "roh/spirit"),
    ], [
        ("幽霊を見ました。", "Yuurei o mimashita.", "Melihat hantu."),
        ("精霊が宿っています。", "Seirei ga yadotte imasu.", "Roh bersemayam."),
    ]),
    ("chou8_n1", "帳", ["チョウ"], [], ["buku catatan", "notebook", "curtain"], 11, "巾", [
        ("手帳", "techou", "buku catatan pribadi"),
        ("帳簿", "choubo", "buku besar"),
        ("蚊帳", "kaya", "kelambu"),
    ], [
        ("手帳に書きました。", "Techou ni kakimashita.", "Menulis di buku catatan."),
        ("蚊帳を吊りました。", "Kaya o tsurimashita.", "Memasang kelambu."),
    ]),
    ("kai3_n1", "悔", ["カイ"], ["く-いる", "くや-む", "くや-しい"], ["menyesal", "regret"], 9, "心", [
        ("後悔", "koukai", "penyesalan"),
        ("悔しい", "kuyashii", "menyesal/kesal"),
        ("悔やむ", "kuyamu", "menyesali"),
    ], [
        ("後悔しています。", "Koukai shite imasu.", "Menyesal."),
        ("悔しい思いをしました。", "Kuyashii omoi o shimashita.", "Merasa kesal."),
    ]),
    ("yu2_n1", "諭", ["ユ"], ["さと-す"], ["menasihati", "admonish", "instruct"], 16, "言", [
        ("諭す", "satosu", "menasihati"),
        ("教諭", "kyouyu", "guru"),
        ("説諭", "setsuyu", "teguran"),
    ], [
        ("子供を諭しました。", "Kodomo o satoshimashita.", "Menasihati anak."),
        ("説諭を受けました。", "Setsuyu o ukemashita.", "Menerima teguran."),
    ]),
    ("san2_n1", "惨", ["サン"], ["みじ-め"], ["mengenaskan", "cruel", "miserable"], 11, "心", [
        ("惨めな", "mijime na", "mengenaskan"),
        ("悲惨", "hisan", "tragis"),
        ("惨事", "sanji", "tragedi"),
    ], [
        ("惨めな結果です。", "Mijime na kekka desu.", "Ini hasil yang mengenaskan."),
        ("悲惨な事故でした。", "Hisan na jiko deshita.", "Ini kecelakaan yang tragis."),
    ]),
    ("gyaku_n1", "虐", ["ギャク"], ["しいた-げる"], ["kejam", "cruel", "abuse"], 9, "虍", [
        ("虐待", "gyakutai", "penganiayaan"),
        ("虐げる", "shiitageru", "menindas"),
        ("残虐", "zangyaku", "kejam"),
    ], [
        ("虐待を受けました。", "Gyakutai o ukemashita.", "Menerima penganiayaan."),
        ("残虐な行為です。", "Zangyaku na koui desu.", "Ini tindakan yang kejam."),
    ]),
    ("hon_n1", "翻", ["ホン"], ["ひるがえ-る"], ["menerjemahkan", "berkibar", "translate", "flutter"], 18, "羽", [
        ("翻訳", "honyaku", "terjemahan"),
        ("翻る", "hirugaeru", "berkibar"),
        ("翻意", "hon-i", "perubahan pikiran"),
    ], [
        ("旗が翻っています。", "Hata ga hirugaette imasu.", "Bendera berkibar."),
        ("翻意しました。", "Hon-i shimashita.", "Mengubah pikiran."),
    ]),
    ("tsui_n1", "墜", ["ツイ"], [], ["jatuh", "fall", "crash"], 15, "土", [
        ("墜落", "tsuiraku", "jatuh/kecelakaan pesawat"),
        ("撃墜", "gekitsui", "menembak jatuh"),
        ("失墜", "shittsui", "jatuh (reputasi)"),
    ], [
        ("飛行機が墜落しました。", "Hikouki ga tsuiraku shimashita.", "Pesawat jatuh."),
        ("信用が失墜しました。", "Shin-you ga shittsui shimashita.", "Kepercayaan jatuh."),
    ]),
    ("shou19_n1", "沼", ["ショウ"], ["ぬま"], ["rawa", "swamp"], 8, "水", [
        ("沼", "numa", "rawa"),
        ("沼地", "numachi", "tanah rawa"),
        ("泥沼", "doronuma", "rawa lumpur/situasi rumit"),
    ], [
        ("沼で釣りをしました。", "Numa de tsuri o shimashita.", "Memancing di rawa."),
        ("泥沼化しています。", "Doronumaka shite imasu.", "Menjadi situasi yang rumit."),
    ]),
    ("kyo6_n1", "据", [], ["す-える", "す-わる"], ["memasang", "install", "set"], 11, "手", [
        ("据える", "sueru", "memasang/menempatkan"),
        ("据え置く", "sueoku", "membiarkan tetap"),
        ("見据える", "misueru", "menatap tajam"),
    ], [
        ("機械を据えました。", "Kikai o suemashita.", "Memasang mesin."),
        ("将来を見据えています。", "Shourai o misuete imasu.", "Menatap masa depan dengan tajam."),
    ]),
    ("hi5_n1", "肥", ["ヒ"], ["こ-える", "こ-やす", "こえ"], ["gemuk", "subur", "fat", "fertile"], 8, "肉", [
        ("肥満", "himan", "obesitas"),
        ("肥料", "hiryou", "pupuk"),
        ("肥える", "koeru", "menjadi gemuk/subur"),
    ], [
        ("肥満に注意してください。", "Himan ni chuui shite kudasai.", "Waspadalah terhadap obesitas."),
        ("肥料をあげました。", "Hiryou o agemashita.", "Memberikan pupuk."),
    ]),
    ("jo2_n1", "徐", ["ジョ"], [], ["perlahan", "gradually"], 10, "彳", [
        ("徐々に", "jojo ni", "secara bertahap"),
        ("徐行", "jokou", "berjalan pelan"),
        ("徐脈", "jomyaku", "denyut jantung lambat"),
    ], [
        ("徐々に良くなりました。", "Jojo ni yoku narimashita.", "Membaik secara bertahap."),
        ("徐行運転してください。", "Jokou unten shite kudasai.", "Berkendaralah dengan pelan."),
    ]),
    ("tou11_n1", "糖", ["トウ"], [], ["gula", "sugar"], 16, "米", [
        ("砂糖", "satou", "gula"),
        ("糖分", "toubun", "kadar gula"),
        ("血糖", "kettou", "gula darah"),
    ], [
        ("砂糖を入れました。", "Satou o iremashita.", "Menambahkan gula."),
        ("血糖値が高いです。", "Kettouchi ga takai desu.", "Kadar gula darahnya tinggi."),
    ]),
    ("tou12_n1", "搭", ["トウ"], [], ["menaiki", "memuat", "board", "load"], 12, "手", [
        ("搭乗", "toujou", "menaiki pesawat"),
        ("搭載", "tousai", "memuat/dilengkapi dengan"),
        ("搭乗券", "toujouken", "boarding pass"),
    ], [
        ("飛行機に搭乗しました。", "Hikouki ni toujou shimashita.", "Menaiki pesawat."),
        ("新機能を搭載しています。", "Shinkinou o tousai shite imasu.", "Dilengkapi dengan fitur baru."),
    ]),
    ("jun4_n1", "盾", ["ジュン"], ["たて"], ["perisai", "shield"], 9, "目", [
        ("盾", "tate", "perisai"),
        ("矛盾", "mujun", "kontradiksi"),
        ("後ろ盾", "ushirodate", "pendukung/backing"),
    ], [
        ("盾を持っています。", "Tate o motte imasu.", "Membawa perisai."),
        ("矛盾しています。", "Mujun shite imasu.", "Ini kontradiktif."),
    ]),
    ("myaku_n1", "脈", ["ミャク"], [], ["denyut", "urat", "pulse", "vein"], 10, "肉", [
        ("脈拍", "myakuhaku", "denyut nadi"),
        ("山脈", "sanmyaku", "pegunungan"),
        ("文脈", "bunmyaku", "konteks"),
    ], [
        ("山脈が見えます。", "Sanmyaku ga miemasu.", "Terlihat pegunungan."),
        ("文脈から判断しました。", "Bunmyaku kara handan shimashita.", "Menilai dari konteks."),
    ]),
    ("taki_n1", "滝", [], ["たき"], ["air terjun", "waterfall"], 13, "水", [
        ("滝", "taki", "air terjun"),
        ("滝つぼ", "takitsubo", "kolam di bawah air terjun"),
        ("男滝", "otaki", "air terjun jantan"),
    ], [
        ("滝を見に行きました。", "Taki o mi ni ikimashita.", "Pergi melihat air terjun."),
        ("滝つぼで泳ぎました。", "Takitsubo de oyogimashita.", "Berenang di kolam air terjun."),
    ]),
    ("ki16_n1", "軌", ["キ"], [], ["jalur", "rel", "track", "rail"], 9, "車", [
        ("軌道", "kidou", "orbit/jalur"),
        ("軌跡", "kiseki", "jejak/lintasan"),
        ("常軌", "jouki", "kebiasaan normal"),
    ], [
        ("軌道に乗りました。", "Kidou ni norimashita.", "Berjalan sesuai rencana."),
        ("軌跡を描きました。", "Kiseki o egakimashita.", "Menggambar lintasan."),
    ]),
    ("hyou4_n1", "俵", ["ヒョウ"], ["たわら"], ["karung jerami", "straw bag"], 10, "人", [
        ("俵", "tawara", "karung jerami"),
        ("土俵", "dohyou", "arena sumo"),
        ("米俵", "komedawara", "karung beras"),
    ], [
        ("土俵に上がりました。", "Dohyou ni agarimashita.", "Naik ke arena sumo."),
        ("米俵を運びました。", "Komedawara o hakobimashita.", "Membawa karung beras."),
    ]),
    ("bou5_n1", "妨", ["ボウ"], ["さまた-げる"], ["menghalangi", "hinder"], 7, "女", [
        ("妨げる", "samatageru", "menghalangi"),
        ("妨害", "bougai", "gangguan"),
        ("妨害電波", "bougai denpa", "gelombang pengganggu"),
    ], [
        ("成長を妨げています。", "Seichou o samatagete imasu.", "Menghalangi pertumbuhan."),
        ("妨害行為です。", "Bougai koui desu.", "Ini tindakan gangguan."),
    ]),
    ("ro3_n1", "盧", ["ロ"], [], ["gubuk (arkais)", "hut"], 16, "皿", [
        ("盧舎那仏", "Rushanabutsu", "nama Buddha Besar Todaiji"),
        ("盧生", "Rosei", "tokoh dalam legenda mimpi bantal kuning"),
        ("盧", "ro", "gubuk sederhana (makna arkais)"),
    ], [
        ("盧舎那仏は奈良の大仏です。", "Rushanabutsu wa Nara no daibutsu desu.", "Rushanabutsu adalah Buddha Besar Nara."),
        ("盧生の夢という故事があります。", "Rosei no yume to iu koji ga arimasu.", "Ada kisah \"mimpi Rosei\"."),
    ]),
    ("satsu2_n1", "擦", ["サツ"], ["す-る", "こす-る"], ["menggosok", "rub", "scrape"], 17, "手", [
        ("擦る", "kosuru", "menggosok"),
        ("摩擦", "masatsu", "gesekan"),
        ("擦り傷", "surikizu", "luka lecet"),
    ], [
        ("手を擦りました。", "Te o kosurimashita.", "Menggosok tangan."),
        ("擦り傷ができました。", "Surikizu ga dekimashita.", "Terkena luka lecet."),
    ]),
    ("gei_n1", "鯨", ["ゲイ"], ["くじら"], ["paus", "whale"], 19, "魚", [
        ("鯨", "kujira", "ikan paus"),
        ("捕鯨", "hogei", "penangkapan paus"),
        ("鯨油", "geiyu", "minyak paus"),
    ], [
        ("鯨を見ました。", "Kujira o mimashita.", "Melihat paus."),
        ("捕鯨反対です。", "Hogei hantai desu.", "Menentang penangkapan paus."),
    ]),
    ("sou9_n1", "荘", ["ソウ"], [], ["vila", "khidmat", "villa", "solemn"], 9, "艸", [
        ("別荘", "bessou", "vila"),
        ("荘厳", "sougon", "agung/khidmat"),
        ("山荘", "sansou", "pondok gunung"),
    ], [
        ("別荘に行きました。", "Bessou ni ikimashita.", "Pergi ke vila."),
        ("荘厳な儀式です。", "Sougon na gishiki desu.", "Ini upacara yang khidmat."),
    ]),
    ("daku_n1", "諾", ["ダク"], [], ["menyetujui", "consent"], 15, "言", [
        ("承諾", "shoudaku", "persetujuan"),
        ("諾否", "dakuhi", "ya atau tidak"),
        ("内諾", "naidaku", "persetujuan informal"),
    ], [
        ("承諾しました。", "Shoudaku shimashita.", "Menyetujui."),
        ("内諾を得ました。", "Naidaku o emashita.", "Mendapat persetujuan informal."),
    ]),
    ("rai_n1", "雷", ["ライ"], ["かみなり"], ["petir", "thunder"], 13, "雨", [
        ("雷", "kaminari", "petir"),
        ("雷雨", "raiu", "hujan petir"),
        ("落雷", "rakurai", "sambaran petir"),
    ], [
        ("雷が鳴りました。", "Kaminari ga narimashita.", "Petir menggelegar."),
        ("落雷がありました。", "Rakurai ga arimashita.", "Ada sambaran petir."),
    ]),
    ("hyou5_n1", "漂", ["ヒョウ"], ["ただよ-う"], ["mengapung", "drift"], 14, "水", [
        ("漂う", "tadayou", "mengapung/mengambang"),
        ("漂流", "hyouryuu", "hanyut"),
        ("漂白", "hyouhaku", "pemutihan"),
    ], [
        ("香りが漂っています。", "Kaori ga tadayotte imasu.", "Aroma mengambang."),
        ("漂流しました。", "Hyouryuu shimashita.", "Terhanyut."),
    ]),
    ("kai4_n1", "懐", ["カイ"], ["ふところ", "なつ-かしい", "なつ-く"], ["pangkuan", "rindu", "bosom", "nostalgia"], 16, "心", [
        ("懐かしい", "natsukashii", "rindu masa lalu"),
        ("懐", "futokoro", "dompet/dada"),
        ("懐中電灯", "kaichuudentou", "senter"),
    ], [
        ("懐かしい思い出です。", "Natsukashii omoide desu.", "Ini kenangan yang dirindukan."),
        ("懐中電灯を持ってきました。", "Kaichuudentou o motte kimashita.", "Membawa senter."),
    ]),
    ("kan23_n1", "勘", ["カン"], [], ["naluri", "intuition"], 11, "力", [
        ("勘", "kan", "naluri/insting"),
        ("勘定", "kanjou", "perhitungan/tagihan"),
        ("勘違い", "kanchigai", "salah paham"),
    ], [
        ("勘が当たりました。", "Kan ga atarimashita.", "Firasat saya benar."),
        ("勘違いしていました。", "Kanchigai shite imashita.", "Salah paham."),
    ]),
    ("sai8_n1", "栽", ["サイ"], [], ["penanaman", "planting"], 10, "木", [
        ("栽培", "saibai", "budidaya"),
        ("盆栽", "bonsai", "bonsai"),
        ("植栽", "shokusai", "penanaman"),
    ], [
        ("盆栽を育てています。", "Bonsai o sodatete imasu.", "Merawat bonsai."),
        ("植栽計画です。", "Shokusai keikaku desu.", "Ini rencana penanaman."),
    ]),
    ("kai5_n1", "拐", ["カイ"], [], ["menculik", "abduct"], 8, "手", [
        ("誘拐", "yuukai", "penculikan"),
        ("拐帯", "kaitai", "penggelapan"),
        ("拐かす", "kadowakasu", "menculik"),
    ], [
        ("誘拐事件です。", "Yuukai jiken desu.", "Ini kasus penculikan."),
        ("子供が拐かされました。", "Kodomo ga kadowakasaremashita.", "Anak diculik."),
    ]),
    ("kasa_n1", "笠", [], ["かさ"], ["topi bambu", "bamboo hat"], 11, "竹", [
        ("笠", "kasa", "topi bambu"),
        ("笠地蔵", "kasajizou", "cerita rakyat Jizo bertopi"),
        ("電笠", "denkasa", "kap lampu"),
    ], [
        ("笠をかぶりました。", "Kasa o kaburimashita.", "Memakai topi bambu."),
        ("笠地蔵の話です。", "Kasajizou no hanashi desu.", "Ini cerita Jizo bertopi."),
    ]),
    ("da2_n1", "駄", ["ダ"], [], ["tak berharga", "worthless", "wooden clog"], 14, "馬", [
        ("無駄", "muda", "sia-sia"),
        ("駄目", "dame", "tidak boleh/gagal"),
        ("下駄", "geta", "sandal kayu Jepang"),
    ], [
        ("無駄にしないでください。", "Muda ni shinaide kudasai.", "Jangan sia-siakan."),
        ("下駄を履きました。", "Geta o hakimashita.", "Memakai sandal kayu."),
    ]),
    ("ten3_n1", "添", ["テン"], ["そ-える", "そ-う"], ["menambahkan", "add", "accompany"], 11, "水", [
        ("添える", "soeru", "menambahkan/melampirkan"),
        ("添付", "tenpu", "lampiran"),
        ("付き添う", "tsukisou", "mendampingi"),
    ], [
        ("手紙を添えました。", "Tegami o soemashita.", "Melampirkan surat."),
        ("ファイルを添付しました。", "Fairu o tenpu shimashita.", "Melampirkan file."),
    ]),
    ("kan24_n1", "冠", ["カン"], ["かんむり"], ["mahkota", "crown"], 9, "冖", [
        ("冠", "kanmuri", "mahkota"),
        ("王冠", "oukan", "mahkota raja"),
        ("栄冠", "eikan", "mahkota kemenangan"),
    ], [
        ("冠をかぶりました。", "Kanmuri o kaburimashita.", "Memakai mahkota."),
        ("栄冠を手にしました。", "Eikan o te ni shimashita.", "Meraih mahkota kemenangan."),
    ]),
    ("sha4_n1", "斜", ["シャ"], ["なな-め"], ["miring", "slanted"], 11, "斗", [
        ("斜め", "naname", "miring"),
        ("傾斜", "keisha", "kemiringan"),
        ("斜線", "shasen", "garis miring"),
    ], [
        ("斜めに切りました。", "Naname ni kirimashita.", "Memotong secara miring."),
        ("傾斜がきついです。", "Keisha ga kitsui desu.", "Kemiringannya curam."),
    ]),
    ("kyou7_n1", "鏡", ["キョウ"], ["かがみ"], ["cermin", "mirror"], 19, "金", [
        ("鏡", "kagami", "cermin"),
        ("眼鏡", "megane", "kacamata"),
        ("望遠鏡", "bouenkyou", "teleskop"),
    ], [
        ("鏡を見ました。", "Kagami o mimashita.", "Melihat cermin."),
        ("眼鏡をかけています。", "Megane o kakete imasu.", "Memakai kacamata."),
    ]),
    ("sou10_n1", "聡", ["ソウ"], ["さと-い"], ["cerdas", "clever"], 14, "耳", [
        ("聡明", "soumei", "cerdas"),
        ("聡い", "satoi", "tajam/cerdas"),
        ("聡一", "Souichi", "contoh nama pria"),
    ], [
        ("聡明な子供です。", "Soumei na kodomo desu.", "Anak yang cerdas."),
        ("聡いお子さんですね。", "Satoi okosan desu ne.", "Anak yang cerdas ya."),
    ]),
    ("rou4_n1", "浪", ["ロウ"], [], ["gelombang", "mengembara", "wave", "wander"], 10, "水", [
        ("浪費", "rouhi", "pemborosan"),
        ("浪人", "rounin", "orang menganggur/samurai tanpa tuan"),
        ("放浪", "hourou", "pengembaraan"),
    ], [
        ("お金を浪費しました。", "Okane o rouhi shimashita.", "Memboroskan uang."),
        ("浪人生です。", "Rounin sei desu.", "Ini siswa yang sedang gap year."),
    ]),
    ("a2_n1", "亜", ["ア"], [], ["sub", "kedua", "sub-", "second"], 7, "二", [
        ("亜熱帯", "anettai", "subtropis"),
        ("亜鉛", "aen", "seng"),
        ("亜細亜", "Ajia", "Asia (penulisan kanji lama)"),
    ], [
        ("亜熱帯気候です。", "Anettai kikou desu.", "Ini iklim subtropis."),
        ("亜鉛不足です。", "Aen busoku desu.", "Ini kekurangan seng."),
    ]),
    ("ran_n1", "覧", ["ラン"], [], ["melihat", "meninjau", "view", "inspect"], 17, "見", [
        ("閲覧", "etsuran", "penelusuran/pembacaan"),
        ("展覧会", "tenrankai", "pameran"),
        ("一覧", "ichiran", "daftar/ringkasan"),
    ], [
        ("閲覧しました。", "Etsuran shimashita.", "Menelusuri."),
        ("展覧会に行きました。", "Tenrankai ni ikimashita.", "Pergi ke pameran."),
    ]),
    ("sa4_n1", "詐", ["サ"], [], ["menipu", "deceive"], 12, "言", [
        ("詐欺", "sagi", "penipuan"),
        ("詐称", "sashou", "klaim palsu"),
        ("詐取", "sashu", "memperoleh dengan tipu daya"),
    ], [
        ("詐欺に遭いました。", "Sagi ni aimashita.", "Menjadi korban penipuan."),
        ("学歴を詐称しました。", "Gakureki o sashou shimashita.", "Memalsukan riwayat pendidikan."),
    ]),
    ("dan3_n1", "壇", ["ダン"], [], ["panggung", "altar", "platform"], 16, "土", [
        ("教壇", "kyoudan", "mimbar guru"),
        ("花壇", "kadan", "taman bunga"),
        ("仏壇", "butsudan", "altar Buddha"),
    ], [
        ("教壇に立ちました。", "Kyoudan ni tachimashita.", "Berdiri di mimbar guru."),
        ("花壇に花を植えました。", "Kadan ni hana o uemashita.", "Menanam bunga di taman bunga."),
    ]),
    ("kun_n1", "勲", ["クン"], [], ["jasa", "meritorious deed"], 15, "力", [
        ("勲章", "kunshou", "medali kehormatan"),
        ("勲功", "kunkou", "jasa besar"),
        ("叙勲", "jokun", "penganugerahan medali"),
    ], [
        ("勲章を授与されました。", "Kunshou o juyo saremashita.", "Dianugerahi medali kehormatan."),
        ("叙勲式です。", "Jokunshiki desu.", "Ini upacara penganugerahan medali."),
    ]),
    ("ma3_n1", "魔", ["マ"], [], ["iblis", "sihir", "demon", "magic"], 21, "鬼", [
        ("魔法", "mahou", "sihir"),
        ("悪魔", "akuma", "setan"),
        ("魔物", "mamono", "monster/iblis"),
    ], [
        ("魔法を使いました。", "Mahou o tsukaimashita.", "Menggunakan sihir."),
        ("悪魔のような人です。", "Akuma no you na hito desu.", "Dia seperti setan."),
    ]),
    ("shuu7_n1", "酬", ["シュウ"], [], ["membalas budi", "reward", "reciprocate"], 13, "酉", [
        ("報酬", "houshuu", "imbalan"),
        ("応酬", "oushuu", "balas-membalas"),
        ("酬いる", "mukuiru", "membalas budi"),
    ], [
        ("報酬をもらいました。", "Houshuu o moraimashita.", "Menerima imbalan."),
        ("応酬が続きました。", "Oushuu ga tsuzukimashita.", "Saling balas terus berlanjut."),
    ]),
    ("shi17_n1", "紫", ["シ"], ["むらさき"], ["ungu", "purple"], 12, "糸", [
        ("紫", "murasaki", "ungu"),
        ("紫外線", "shigaisen", "sinar ultraviolet"),
        ("紫陽花", "ajisai", "bunga hortensia"),
    ], [
        ("紫色が好きです。", "Murasaki iro ga suki desu.", "Suka warna ungu."),
        ("紫外線に注意してください。", "Shigaisen ni chuui shite kudasai.", "Waspadalah terhadap sinar UV."),
    ]),
    ("sho2_n1", "曙", ["ショ"], ["あけぼの"], ["fajar", "dawn"], 17, "日", [
        ("曙", "akebono", "fajar"),
        ("曙光", "shokou", "cahaya fajar"),
        ("曙色", "akeboneiro", "warna fajar"),
    ], [
        ("曙の光が差しました。", "Akebono no hikari ga sashimashita.", "Cahaya fajar bersinar."),
        ("曙光が見えました。", "Shokou ga miemashita.", "Terlihat cahaya fajar."),
    ]),
    ("mon_n1", "紋", ["モン"], [], ["lambang keluarga", "crest", "pattern"], 10, "糸", [
        ("家紋", "kamon", "lambang keluarga"),
        ("指紋", "shimon", "sidik jari"),
        ("紋様", "monyou", "motif/pola"),
    ], [
        ("家紋があります。", "Kamon ga arimasu.", "Memiliki lambang keluarga."),
        ("指紋を採取しました。", "Shimon o saishu shimashita.", "Mengambil sidik jari."),
    ]),
    ("oroshi_n1", "卸", [], ["おろ-す", "おろし"], ["grosir", "wholesale"], 9, "卩", [
        ("卸す", "orosu", "menjual grosir"),
        ("卸売", "oroshiuri", "penjualan grosir"),
        ("卸値", "oroshine", "harga grosir"),
    ], [
        ("卸売業をしています。", "Oroshiuri gyou o shite imasu.", "Bekerja di bidang grosir."),
        ("卸値で買いました。", "Oroshine de kaimashita.", "Membeli dengan harga grosir."),
    ]),
    ("fun4_n1", "奮", ["フン"], ["ふる-う"], ["membangkitkan semangat", "rouse", "exert"], 16, "大", [
        ("奮う", "furuu", "membangkitkan semangat"),
        ("興奮", "koufun", "kegembiraan"),
        ("奮闘", "funtou", "perjuangan keras"),
    ], [
        ("興奮しました。", "Koufun shimashita.", "Bersemangat."),
        ("奮闘しています。", "Funtou shite imasu.", "Berjuang keras."),
    ]),
    ("chou9_n1", "趙", ["チョウ"], [], ["marga/negara Zhao", "Zhao"], 14, "走", [
        ("趙", "Chou", "marga Zhao"),
        ("趙国", "Choukoku", "Negara Zhao zaman Tiongkok kuno"),
        ("趙氏", "Choushi", "marga/keluarga Zhao"),
    ], [
        ("趙という姓の人です。", "Chou to iu sei no hito desu.", "Orang dengan marga Zhao."),
        ("趙国は中国の古代国家です。", "Choukoku wa Chuugoku no kodai kokka desu.", "Negara Zhao adalah negara kuno Tiongkok."),
    ]),
    ("ran2_n1", "欄", ["ラン"], [], ["kolom", "pagar", "column", "railing"], 20, "木", [
        ("欄", "ran", "kolom"),
        ("空欄", "kuuran", "kolom kosong"),
        ("欄干", "rankan", "pagar/pembatas"),
    ], [
        ("欄に記入しました。", "Ran ni kinyuu shimashita.", "Mengisi kolom."),
        ("空欄を埋めてください。", "Kuuran o umete kudasai.", "Isilah kolom kosong."),
    ]),
    ("itsu_n1", "逸", ["イツ"], ["そ-れる"], ["melarikan diri", "unggul", "escape", "excellent"], 11, "辵", [
        ("逸話", "itsuwa", "anekdot"),
        ("秀逸", "shuuitsu", "luar biasa"),
        ("逸脱", "itsudatsu", "penyimpangan"),
    ], [
        ("逸話があります。", "Itsuwa ga arimasu.", "Ada anekdot."),
        ("常識から逸脱しています。", "Joushiki kara itsudatsu shite imasu.", "Menyimpang dari norma umum."),
    ]),
    ("gai3_n1", "涯", ["ガイ"], [], ["batas", "tepi", "shore", "limit"], 11, "水", [
        ("生涯", "shougai", "seumur hidup"),
        ("天涯孤独", "tengai kodoku", "sebatang kara"),
        ("境涯", "kyougai", "keadaan hidup"),
    ], [
        ("生涯忘れません。", "Shougai wasuremasen.", "Tidak akan lupa seumur hidup."),
        ("天涯孤独の身です。", "Tengai kodoku no mi desu.", "Dia sebatang kara."),
    ]),
    ("taku5_n1", "拓", ["タク"], [], ["membuka lahan", "open up", "rubbing"], 8, "手", [
        ("開拓", "kaitaku", "pembukaan lahan/pionir"),
        ("拓本", "takuhon", "cetakan gosokan batu"),
        ("干拓", "kantaku", "reklamasi lahan"),
    ], [
        ("開拓者です。", "Kaitakusha desu.", "Dia seorang pionir."),
        ("干拓地です。", "Kantakuchi desu.", "Ini lahan reklamasi."),
    ]),
    ("gan2_n1", "眼", ["ガン"], ["まなこ"], ["mata", "eye"], 11, "目", [
        ("眼科", "ganka", "oftalmologi"),
        ("眼鏡", "megane", "kacamata"),
        ("近眼", "kingan", "rabun dekat"),
    ], [
        ("眼科に行きました。", "Ganka ni ikimashita.", "Pergi ke dokter mata."),
        ("近眼です。", "Kingan desu.", "Saya rabun jauh."),
    ]),
    ("goku_n1", "獄", ["ゴク"], [], ["penjara", "prison"], 14, "犬", [
        ("地獄", "jigoku", "neraka"),
        ("監獄", "kangoku", "penjara"),
        ("脱獄", "datsugoku", "kabur dari penjara"),
    ], [
        ("地獄のような日々でした。", "Jigoku no you na hibi deshita.", "Hari-hari seperti neraka."),
        ("脱獄しました。", "Datsugoku shimashita.", "Kabur dari penjara."),
    ]),
    ("chiku2_n1", "筑", ["チク"], [], ["membangun (nama tempat)", "build"], 12, "竹", [
        ("筑波", "Tsukuba", "nama kota"),
        ("筑後", "Chikugo", "nama daerah lama"),
        ("筑豊", "Chikuhou", "nama daerah lama"),
    ], [
        ("筑波大学に通っています。", "Tsukuba daigaku ni kayotte imasu.", "Kuliah di Universitas Tsukuba."),
        ("筑後地方です。", "Chikugo chihou desu.", "Ini daerah Chikugo."),
    ]),
    ("shou20_n1", "尚", ["ショウ"], ["なお"], ["masih", "menghargai", "esteem", "still"], 8, "小", [
        ("尚早", "shousou", "terlalu dini"),
        ("高尚", "koushou", "luhur/tinggi"),
        ("尚更", "naosara", "lebih-lebih lagi"),
    ], [
        ("時期尚早です。", "Jiki shousou desu.", "Ini masih terlalu dini."),
        ("高尚な趣味です。", "Koushou na shumi desu.", "Ini hobi yang luhur."),
    ]),
    ("fu3_n1", "阜", ["フ"], [], ["bukit (arkais)", "hill"], 8, "阜", [
        ("岐阜", "Gifu", "nama prefektur"),
        ("阜", "fu", "bukit (arkais)"),
        ("曲阜", "Kyokufu", "kota kelahiran Konfusius di Tiongkok"),
    ], [
        ("岐阜県です。", "Gifu-ken desu.", "Ini Prefektur Gifu."),
        ("曲阜は孔子の故郷です。", "Kyokufu wa Koushi no kokyou desu.", "Qufu adalah kampung halaman Konfusius."),
    ]),
    ("chou10_n1", "彫", ["チョウ"], ["ほ-る"], ["mengukir", "carve", "engrave"], 11, "彡", [
        ("彫る", "horu", "mengukir"),
        ("彫刻", "choukoku", "patung/ukiran"),
        ("彫刻家", "choukokuka", "pematung"),
    ], [
        ("木を彫りました。", "Ki o horimashita.", "Mengukir kayu."),
        ("彫刻家になりました。", "Choukokuka ni narimashita.", "Menjadi pematung."),
    ]),
    ("on2_n1", "穏", ["オン"], ["おだ-やか"], ["tenang", "calm"], 16, "禾", [
        ("穏やか", "odayaka", "tenang"),
        ("平穏", "heion", "tenteram"),
        ("安穏", "annon", "aman dan tenteram"),
    ], [
        ("穏やかな性格です。", "Odayaka na seikaku desu.", "Kepribadian yang tenang."),
        ("平穏な生活です。", "Heion na seikatsu desu.", "Kehidupan yang tenteram."),
    ]),
    ("ken11_n1", "顕", ["ケン"], [], ["menampakkan", "manifest", "reveal"], 18, "頁", [
        ("顕著", "kencho", "mencolok"),
        ("顕微鏡", "kenbikyou", "mikroskop"),
        ("顕彰", "kenshou", "memberi penghargaan"),
    ], [
        ("顕著な変化です。", "Kencho na henka desu.", "Ini perubahan yang mencolok."),
        ("顕微鏡で観察しました。", "Kenbikyou de kansatsu shimashita.", "Mengamati dengan mikroskop."),
    ]),
    ("kou23_n1", "巧", ["コウ"], ["たく-み"], ["mahir", "skillful"], 5, "工", [
        ("巧み", "takumi", "mahir/terampil"),
        ("巧妙", "koumyou", "cerdik"),
        ("技巧", "gikou", "teknik/keterampilan"),
    ], [
        ("巧みな技術です。", "Takumi na gijutsu desu.", "Ini teknik yang mahir."),
        ("技巧を凝らしました。", "Gikou o korashimashita.", "Menggunakan keterampilan yang rumit."),
    ]),
    ("mu_n1", "矛", ["ム"], ["ほこ"], ["tombak", "spear"], 5, "矛", [
        ("矛盾", "mujun", "kontradiksi"),
        ("矛", "hoko", "tombak"),
        ("矛先", "hokosaki", "sasaran/ujung tombak"),
    ], [
        ("矛盾しています。", "Mujun shite imasu.", "Ini kontradiktif."),
        ("矛先を変えました。", "Hokosaki o kaemashita.", "Mengubah sasaran."),
    ]),
    ("kaki_n1", "垣", [], ["かき"], ["pagar", "fence"], 9, "土", [
        ("垣根", "kakine", "pagar"),
        ("石垣", "ishigaki", "pagar batu"),
        ("人垣", "hitogaki", "kerumunan orang"),
    ], [
        ("垣根を作りました。", "Kakine o tsukurimashita.", "Membuat pagar."),
        ("石垣が美しいです。", "Ishigaki ga utsukushii desu.", "Pagar batunya indah."),
    ]),
    ("gi5_n1", "欺", ["ギ"], ["あざむ-く"], ["menipu", "deceive"], 12, "欠", [
        ("詐欺", "sagi", "penipuan"),
        ("欺く", "azamuku", "menipu"),
        ("欺瞞", "giman", "penipuan/tipu daya"),
    ], [
        ("人を欺きました。", "Hito o azamukimashita.", "Menipu orang."),
        ("欺瞞に満ちています。", "Giman ni michite imasu.", "Penuh dengan tipu daya."),
    ]),
    ("chou11_n1", "釣", ["チョウ"], ["つ-る"], ["memancing", "fish"], 11, "金", [
        ("釣る", "tsuru", "memancing"),
        ("釣り", "tsuri", "memancing"),
        ("釣り合う", "tsuriau", "seimbang"),
    ], [
        ("魚を釣りました。", "Sakana o tsurimashita.", "Memancing ikan."),
        ("釣り合いが取れています。", "Tsuriai ga torete imasu.", "Seimbang."),
    ]),
    ("shuu8_n1", "萩", ["シュウ"], ["はぎ"], ["bush clover", "semak clover Jepang"], 12, "艸", [
        ("萩", "hagi", "tanaman bush clover"),
        ("萩市", "Hagi-shi", "nama kota"),
        ("萩焼", "hagiyaki", "keramik Hagi"),
    ], [
        ("萩の花が咲きました。", "Hagi no hana ga sakimashita.", "Bunga bush clover mekar."),
        ("萩焼を買いました。", "Hagiyaki o kaimashita.", "Membeli keramik Hagi."),
    ]),
    ("shou21_n1", "粧", ["ショウ"], [], ["berhias", "makeup", "adorn"], 12, "米", [
        ("化粧", "keshou", "makeup/riasan"),
        ("化粧品", "keshouhin", "kosmetik"),
        ("美粧", "bishou", "kecantikan"),
    ], [
        ("化粧をしました。", "Keshou o shimashita.", "Memakai riasan."),
        ("化粧品を買いました。", "Keshouhin o kaimashita.", "Membeli kosmetik."),
    ]),
    ("katsu3_n1", "葛", ["カツ"], ["くず"], ["kudzu vine", "tanaman kudzu"], 12, "艸", [
        ("葛藤", "kattou", "konflik batin"),
        ("葛", "kuzu", "tanaman kudzu"),
        ("葛餅", "kuzumochi", "kue mochi kudzu"),
    ], [
        ("葛藤しています。", "Kattou shite imasu.", "Mengalami konflik batin."),
        ("葛餅を食べました。", "Kuzumochi o tabemashita.", "Makan kue mochi kudzu."),
    ]),
    ("shuku2_n1", "粛", ["シュク"], [], ["khidmat", "solemn", "quiet"], 11, "聿", [
        ("静粛", "seishuku", "hening/khidmat"),
        ("粛々と", "shukushuku to", "dengan tenang dan khidmat"),
        ("自粛", "jishuku", "menahan diri secara sukarela"),
    ], [
        ("静粛にしてください。", "Seishuku ni shite kudasai.", "Mohon tenang."),
        ("外出を自粛しています。", "Gaishutsu o jishuku shite imasu.", "Menahan diri untuk tidak keluar rumah."),
    ]),
    ("ritsu2_n1", "栗", ["リツ"], ["くり"], ["buah kastanye", "chestnut"], 10, "木", [
        ("栗", "kuri", "buah kastanye"),
        ("栗ご飯", "kurigohan", "nasi kastanye"),
        ("焼き栗", "yakiguri", "kastanye panggang"),
    ], [
        ("栗ご飯を食べました。", "Kurigohan o tabemashita.", "Makan nasi kastanye."),
        ("焼き栗を買いました。", "Yakiguri o kaimashita.", "Membeli kastanye panggang."),
    ]),
    ("gu_n1", "愚", ["グ"], ["おろ-か"], ["bodoh", "foolish"], 13, "心", [
        ("愚か", "oroka", "bodoh"),
        ("愚痴", "guchi", "keluhan"),
        ("愚問", "gumon", "pertanyaan bodoh"),
    ], [
        ("愚かな行動でした。", "Oroka na koudou deshita.", "Ini tindakan yang bodoh."),
        ("愚痴をこぼしました。", "Guchi o koboshimashita.", "Mengeluh."),
    ]),
    ("ka8_n1", "嘉", ["カ"], [], ["memuji", "baik", "praise", "good"], 14, "口", [
        ("嘉する", "kasuru", "memuji"),
        ("嘉納", "kanou", "menerima dengan senang hati"),
        ("嘉例", "karei", "kebiasaan baik"),
    ], [
        ("功績を嘉しました。", "Kouseki o yoshi to shimashita.", "Memuji prestasinya."),
        ("嘉例に従いました。", "Karei ni shitagaimashita.", "Mengikuti kebiasaan baik."),
    ]),
    ("sou11_n1", "遭", ["ソウ"], ["あ-う"], ["mengalami", "bertemu", "encounter"], 14, "辵", [
        ("遭う", "au", "mengalami"),
        ("遭難", "sounan", "kecelakaan/musibah"),
        ("遭遇", "souguu", "perjumpaan tak terduga"),
    ], [
        ("事故に遭いました。", "Jiko ni aimashita.", "Mengalami kecelakaan."),
        ("遭難しました。", "Sounan shimashita.", "Mengalami musibah."),
    ]),
    ("ka9_n1", "架", ["カ"], ["か-ける", "か-かる"], ["menggantung", "kerangka", "frame", "hang"], 9, "木", [
        ("架ける", "kakeru", "menggantungkan/membangun jembatan"),
        ("架空", "kakuu", "fiktif"),
        ("高架", "kouka", "elevasi/jalan layang"),
    ], [
        ("橋を架けました。", "Hashi o kakemashita.", "Membangun jembatan."),
        ("架空の人物です。", "Kakuu no jinbutsu desu.", "Ini tokoh fiktif."),
    ]),
    ("shino_n1", "篠", [], ["しの"], ["bambu kecil", "small bamboo"], 17, "竹", [
        ("篠竹", "shinodake", "bambu kecil"),
        ("篠原", "Shinohara", "contoh nama keluarga"),
        ("篠突く雨", "shinotsuku ame", "hujan lebat seperti tirai bambu"),
    ], [
        ("篠竹が生えています。", "Shinodake ga haete imasu.", "Bambu kecil tumbuh."),
        ("篠突く雨が降りました。", "Shinotsuku ame ga furimashita.", "Hujan turun sangat lebat."),
    ]),
    ("oni_n1", "鬼", ["キ"], ["おに"], ["iblis", "setan Jepang", "demon", "ogre"], 10, "鬼", [
        ("鬼", "oni", "iblis/setan Jepang"),
        ("鬼ごっこ", "onigokko", "permainan kejar-kejaran"),
        ("鬼才", "kisai", "jenius luar biasa"),
    ], [
        ("鬼ごっこをしました。", "Onigokko o shimashita.", "Bermain kejar-kejaran."),
        ("鬼才と呼ばれています。", "Kisai to yobarete imasu.", "Disebut sebagai jenius luar biasa."),
    ]),
    ("sho3_n1", "庶", ["ショ"], [], ["rakyat biasa", "common", "all"], 11, "广", [
        ("庶民", "shomin", "rakyat jelata"),
        ("庶務", "shomu", "urusan umum kantor"),
        ("庶子", "shoshi", "anak di luar nikah"),
    ], [
        ("庶民の生活です。", "Shomin no seikatsu desu.", "Ini kehidupan rakyat jelata."),
        ("庶務を担当しています。", "Shomu o tantou shite imasu.", "Menangani urusan umum kantor."),
    ]),
    ("chi3_n1", "稚", ["チ"], [], ["kekanak-kanakan", "young", "immature"], 13, "禾", [
        ("幼稚", "youchi", "kekanak-kanakan"),
        ("幼稚園", "youchien", "taman kanak-kanak"),
        ("稚魚", "chigyo", "anak ikan"),
    ], [
        ("幼稚な考えです。", "Youchi na kangae desu.", "Ini pikiran yang kekanak-kanakan."),
        ("幼稚園に通っています。", "Youchien ni kayotte imasu.", "Bersekolah di TK."),
    ]),
    ("suga_n1", "菅", ["カン"], ["すげ"], ["rumput sedge", "sedge"], 11, "艸", [
        ("菅", "suge", "rumput sedge"),
        ("菅笠", "sugegasa", "topi anyaman sedge"),
        ("菅原", "Sugawara", "contoh nama keluarga"),
    ], [
        ("菅笠をかぶりました。", "Sugegasa o kaburimashita.", "Memakai topi anyaman sedge."),
        ("菅原道真は有名な学者です。", "Sugawara no Michizane wa yuumei na gakusha desu.", "Sugawara no Michizane adalah ilmuwan terkenal."),
    ]),
    ("ji_n1", "滋", ["ジ"], [], ["menyuburkan", "bergizi", "nourish"], 12, "水", [
        ("滋養", "jiyou", "nutrisi"),
        ("滋賀", "Shiga", "nama prefektur"),
        ("滋味", "jimi", "rasa lezat dan bergizi"),
    ], [
        ("滋養のある食事です。", "Jiyou no aru shokuji desu.", "Ini makanan yang bergizi."),
        ("滋賀県に行きました。", "Shiga-ken ni ikimashita.", "Pergi ke Prefektur Shiga."),
    ]),
    ("gen4_n1", "幻", ["ゲン"], ["まぼろし"], ["khayalan", "illusion"], 4, "幺", [
        ("幻", "maboroshi", "khayalan/ilusi"),
        ("幻想", "gensou", "fantasi"),
        ("幻滅", "genmetsu", "kekecewaan"),
    ], [
        ("幻を見ました。", "Maboroshi o mimashita.", "Melihat khayalan."),
        ("幻滅しました。", "Genmetsu shimashita.", "Kecewa."),
    ]),
    ("ni_n1", "煮", ["シャ"], ["に-る", "に-える"], ["merebus", "boil", "simmer"], 12, "火", [
        ("煮る", "niru", "merebus"),
        ("煮物", "nimono", "masakan rebus"),
        ("雑煮", "zouni", "sup mochi Tahun Baru"),
    ], [
        ("野菜を煮ました。", "Yasai o nimashita.", "Merebus sayuran."),
        ("雑煮を食べました。", "Zouni o tabemashita.", "Makan zouni."),
    ]),
    ("hime_n1", "姫", ["キ"], ["ひめ"], ["putri", "princess"], 10, "女", [
        ("姫", "hime", "putri"),
        ("姫路", "Himeji", "nama kota"),
        ("お姫様", "ohimesama", "tuan putri"),
    ], [
        ("お姫様のようです。", "Ohimesama no you desu.", "Seperti tuan putri."),
        ("姫路城を見ました。", "Himeji-jou o mimashita.", "Melihat Kastil Himeji."),
    ]),
    ("sei11_n1", "誓", ["セイ"], ["ちか-う"], ["bersumpah", "vow"], 14, "言", [
        ("誓う", "chikau", "bersumpah"),
        ("誓約", "seiyaku", "janji/sumpah"),
        ("宣誓", "sensei", "sumpah/deklarasi"),
    ], [
        ("愛を誓いました。", "Ai o chikaimashita.", "Bersumpah setia."),
        ("宣誓しました。", "Sensei shimashita.", "Mengucapkan sumpah."),
    ]),
    ("ha2_n1", "把", ["ハ"], [], ["menggenggam", "grasp"], 7, "手", [
        ("把握", "haaku", "memahami/menguasai"),
        ("把持", "haji", "memegang teguh"),
        ("一把", "ippa", "satu ikat"),
    ], [
        ("状況を把握しました。", "Joukyou o haaku shimashita.", "Memahami situasi."),
        ("一把の稲です。", "Ippa no ine desu.", "Ini satu ikat padi."),
    ]),
    ("sen9_n1", "践", ["セン"], [], ["melaksanakan", "practice", "tread"], 13, "足", [
        ("実践", "jissen", "praktik"),
        ("践む", "fumu", "menginjak"),
        ("実践的", "jissenteki", "praktis"),
    ], [
        ("実践してみましょう。", "Jissen shite mimashou.", "Mari kita praktikkan."),
        ("実践的な方法です。", "Jissenteki na houhou desu.", "Ini metode yang praktis."),
    ]),
    ("tei9_n1", "呈", ["テイ"], [], ["menyajikan", "present", "show"], 7, "口", [
        ("呈する", "teisuru", "menunjukkan/menyajikan"),
        ("進呈", "shintei", "hadiah/pemberian"),
        ("贈呈", "zoutei", "penganugerahan"),
    ], [
        ("症状を呈しています。", "Shoujou o teishite imasu.", "Menunjukkan gejala."),
        ("贈呈式です。", "Zouteishiki desu.", "Ini upacara penganugerahan."),
    ]),
    ("so6_n1", "疎", ["ソ"], ["うと-い", "うと-む"], ["renggang", "distant", "sparse"], 12, "疋", [
        ("疎い", "utoi", "kurang paham"),
        ("疎遠", "soen", "hubungan yang renggang"),
        ("過疎", "kaso", "kepadatan penduduk rendah"),
    ], [
        ("その分野には疎いです。", "Sono bun-ya ni wa utoi desu.", "Saya kurang paham bidang itu."),
        ("疎遠になりました。", "Soen ni narimashita.", "Hubungan menjadi renggang."),
    ]),
    ("gyou_n1", "仰", ["ギョウ"], ["あお-ぐ", "おお-せ"], ["mendongak", "menghormati", "look up", "respect"], 6, "人", [
        ("仰ぐ", "aogu", "mendongak/menghormati"),
        ("信仰", "shinkou", "keyakinan/iman"),
        ("仰天", "gyouten", "sangat terkejut"),
    ], [
        ("空を仰ぎました。", "Sora o aogimashita.", "Mendongak ke langit."),
        ("信仰心があります。", "Shinkoushin ga arimasu.", "Memiliki keyakinan agama."),
    ]),
    ("gou2_n1", "剛", ["ゴウ"], [], ["kuat", "kokoh", "strong", "rigid"], 10, "刀", [
        ("剛健", "gouken", "kuat dan sehat"),
        ("剛速球", "gousokkyuu", "lemparan cepat"),
        ("金剛", "kongou", "sangat keras/berlian"),
    ], [
        ("剛健な体です。", "Gouken na karada desu.", "Tubuh yang kuat dan sehat."),
        ("金剛石のようです。", "Kongouseki no you desu.", "Seperti berlian."),
    ]),
    ("shitsu2_n1", "疾", ["シツ"], [], ["penyakit", "cepat", "disease", "swift"], 10, "疒", [
        ("疾患", "shikkan", "penyakit"),
        ("疾病", "shippei", "penyakit"),
        ("疾走", "shissou", "berlari kencang"),
    ], [
        ("疾患があります。", "Shikkan ga arimasu.", "Memiliki penyakit."),
        ("疾走しました。", "Shissou shimashita.", "Berlari kencang."),
    ]),
    ("sei12_n1", "征", ["セイ"], [], ["menaklukkan", "conquer", "expedition"], 8, "彳", [
        ("征服", "seifuku", "penaklukan"),
        ("遠征", "ensei", "ekspedisi"),
        ("出征", "shussei", "berangkat perang"),
    ], [
        ("世界を征服しました。", "Sekai o seifuku shimashita.", "Menaklukkan dunia."),
        ("遠征に出かけました。", "Ensei ni dekakemashita.", "Berangkat ekspedisi."),
    ]),
    ("sai9_n1", "砕", ["サイ"], ["くだ-く", "くだ-ける"], ["menghancurkan", "crush", "smash"], 9, "石", [
        ("砕く", "kudaku", "menghancurkan"),
        ("粉砕", "funsai", "menghancurkan menjadi bubuk"),
        ("砕石", "saiseki", "batu pecah"),
    ], [
        ("氷を砕きました。", "Koori o kudakimashita.", "Menghancurkan es."),
        ("粉砕しました。", "Funsai shimashita.", "Menghancurkan hingga halus."),
    ]),
    ("you5_n1", "謡", ["ヨウ"], ["うたい", "うた-う"], ["lagu tradisional", "song", "ballad"], 16, "言", [
        ("謡曲", "youkyoku", "lagu Noh"),
        ("童謡", "douyou", "lagu anak-anak"),
        ("民謡", "min-you", "lagu rakyat"),
    ], [
        ("童謡を歌いました。", "Douyou o utaimashita.", "Menyanyikan lagu anak-anak."),
        ("民謡を習っています。", "Min-you o naratte imasu.", "Belajar lagu rakyat."),
    ]),
    ("ka10_n1", "嫁", ["カ"], ["よめ", "とつ-ぐ"], ["pengantin wanita", "bride", "marry"], 13, "女", [
        ("嫁", "yome", "menantu perempuan"),
        ("花嫁", "hanayome", "pengantin wanita"),
        ("嫁ぐ", "totsugu", "menikah (untuk wanita)"),
    ], [
        ("花嫁が美しいです。", "Hanayome ga utsukushii desu.", "Pengantin wanitanya cantik."),
        ("嫁ぎました。", "Totsugimashita.", "Dia (wanita) menikah."),
    ]),
    ("ken12_n1", "謙", ["ケン"], [], ["rendah hati", "humble"], 17, "言", [
        ("謙虚", "kenkyo", "rendah hati"),
        ("謙譲", "kenjou", "kerendahan hati"),
        ("謙遜", "kenson", "merendahkan diri"),
    ], [
        ("謙虚な態度です。", "Kenkyo na taido desu.", "Sikap yang rendah hati."),
        ("謙遜しないでください。", "Kenson shinaide kudasai.", "Jangan terlalu merendahkan diri."),
    ]),
    ("kou24_n1", "后", ["コウ"], [], ["permaisuri", "empress", "queen"], 6, "口", [
        ("皇后", "kougou", "permaisuri"),
        ("王后", "ouou", "permaisuri raja"),
        ("后妃", "kouhi", "permaisuri dan selir"),
    ], [
        ("皇后陛下です。", "Kougou heika desu.", "Ini Yang Mulia Permaisuri."),
        ("后妃の物語です。", "Kouhi no monogatari desu.", "Ini kisah permaisuri dan selir."),
    ]),
    ("tan6_n1", "嘆", ["タン"], ["なげ-く"], ["meratap", "lament", "sigh"], 13, "口", [
        ("嘆く", "nageku", "meratap"),
        ("嘆願", "tangan", "permohonan"),
        ("悲嘆", "hitan", "kesedihan mendalam"),
    ], [
        ("運命を嘆きました。", "Unmei o nagekimashita.", "Meratapi nasib."),
        ("嘆願書を提出しました。", "Tanganjo o teishutsu shimashita.", "Mengajukan surat permohonan."),
    ]),
    ("mata_n1", "俣", [], ["また"], ["percabangan sungai", "fork (river)"], 9, "人", [
        ("俣", "mata", "percabangan sungai"),
        ("二俣", "Futamata", "nama tempat"),
        ("水俣", "Minamata", "nama kota"),
    ], [
        ("二俣川という川があります。", "Futamatagawa to iu kawa ga arimasu.", "Ada sungai bernama Futamata."),
        ("水俣病は有名な公害病です。", "Minamatabyou wa yuumei na kougaibyou desu.", "Penyakit Minamata adalah penyakit polusi terkenal."),
    ]),
    ("kin4_n1", "菌", ["キン"], [], ["bakteri", "jamur", "bacteria", "fungus"], 11, "艸", [
        ("細菌", "saikin", "bakteri"),
        ("菌類", "kinrui", "fungi"),
        ("殺菌", "sakkin", "sterilisasi"),
    ], [
        ("細菌が繁殖しました。", "Saikin ga hanshoku shimashita.", "Bakteri berkembang biak."),
        ("殺菌しました。", "Sakkin shimashita.", "Mensterilkan."),
    ]),
    ("kama_n1", "鎌", [], ["かま"], ["sabit", "sickle"], 18, "金", [
        ("鎌", "kama", "sabit"),
        ("鎌倉", "Kamakura", "nama kota"),
        ("鎌首", "kamakubi", "leher berbentuk sabit"),
    ], [
        ("鎌で刈りました。", "Kama de karimashita.", "Memotong dengan sabit."),
        ("鎌倉に行きました。", "Kamakura ni ikimashita.", "Pergi ke Kamakura."),
    ]),
    ("sou12_n1", "巣", ["ソウ"], ["す"], ["sarang", "nest"], 11, "巛", [
        ("巣", "su", "sarang"),
        ("巣立つ", "sudatsu", "meninggalkan sarang/mandiri"),
        ("病巣", "byousou", "fokus penyakit"),
    ], [
        ("鳥の巣です。", "Tori no su desu.", "Ini sarang burung."),
        ("巣立ちました。", "Sudachimashita.", "Meninggalkan sarang/mandiri."),
    ]),
    ("hin2_n1", "頻", ["ヒン"], [], ["sering", "frequent"], 17, "頁", [
        ("頻繁", "hinpan", "sering"),
        ("頻度", "hindo", "frekuensi"),
        ("頻発", "hinpatsu", "sering terjadi"),
    ], [
        ("頻度が高いです。", "Hindo ga takai desu.", "Frekuensinya tinggi."),
        ("事故が頻発しています。", "Jiko ga hinpatsu shite imasu.", "Kecelakaan sering terjadi."),
    ]),
    ("koto_n1", "琴", ["キン"], ["こと"], ["alat musik koto", "koto"], 12, "玉", [
        ("琴", "koto", "alat musik koto"),
        ("琴線", "kinsen", "senar hati/emosi"),
        ("木琴", "mokkin", "silofon"),
    ], [
        ("琴を弾きました。", "Koto o hikimashita.", "Memainkan koto."),
        ("琴線に触れました。", "Kinsen ni furemashita.", "Menyentuh hati."),
    ]),
    ("han4_n1", "班", ["ハン"], [], ["kelompok", "group", "squad"], 10, "玉", [
        ("班", "han", "kelompok"),
        ("班長", "hanchou", "ketua kelompok"),
        ("救護班", "kyuugohan", "tim penyelamat"),
    ], [
        ("班長になりました。", "Hanchou ni narimashita.", "Menjadi ketua kelompok."),
        ("救護班が来ました。", "Kyuugohan ga kimashita.", "Tim penyelamat datang."),
    ]),
    ("fuchi2_n1", "淵", ["エン"], ["ふち"], ["lubuk", "deep pool"], 12, "水", [
        ("深淵", "shin-en", "jurang dalam"),
        ("淵", "fuchi", "lubuk air"),
        ("淵源", "engen", "akar/sumber asal"),
    ], [
        ("深淵を覗きました。", "Shin-en o nozokimashita.", "Mengintip jurang dalam."),
        ("川の淵で遊びました。", "Kawa no fuchi de asobimashita.", "Bermain di lubuk sungai."),
    ]),
    ("tana_n1", "棚", [], ["たな"], ["rak", "shelf"], 12, "木", [
        ("棚", "tana", "rak"),
        ("本棚", "hondana", "rak buku"),
        ("棚上げ", "tanaage", "penundaan"),
    ], [
        ("本棚に置きました。", "Hondana ni okimashita.", "Meletakkan di rak buku."),
        ("議論を棚上げしました。", "Giron o tanaage shimashita.", "Menunda diskusi."),
    ]),
    ("ketsu2_n1", "潔", ["ケツ"], ["いさぎよ-い"], ["bersih", "clean", "pure"], 15, "水", [
        ("潔白", "keppaku", "bersih dari tuduhan"),
        ("清潔", "seiketsu", "bersih"),
        ("潔い", "isagiyoi", "jantan/tegas"),
    ], [
        ("潔白を証明しました。", "Keppaku o shoumei shimashita.", "Membuktikan tidak bersalah."),
        ("清潔にしています。", "Seiketsu ni shite imasu.", "Menjaga kebersihan."),
    ]),
    ("koku2_n1", "酷", ["コク"], [], ["kejam", "cruel", "severe"], 14, "酉", [
        ("残酷", "zankoku", "kejam"),
        ("酷い", "hidoi", "parah/kejam"),
        ("過酷", "kakoku", "keras/berat"),
    ], [
        ("残酷な仕打ちです。", "Zankoku na shiuchi desu.", "Ini perlakuan yang kejam."),
        ("過酷な環境です。", "Kakoku na kankyou desu.", "Ini lingkungan yang keras."),
    ]),
    ("sai10_n1", "宰", ["サイ"], [], ["memimpin", "govern", "preside"], 10, "宀", [
        ("宰相", "saishou", "perdana menteri"),
        ("主宰", "shusai", "memimpin/mengetuai"),
        ("宰領", "sairyou", "pemimpin"),
    ], [
        ("宰相になりました。", "Saishou ni narimashita.", "Menjadi perdana menteri."),
        ("会を主宰しています。", "Kai o shusai shite imasu.", "Memimpin pertemuan."),
    ]),
    ("rou5_n1", "廊", ["ロウ"], [], ["koridor", "corridor"], 11, "广", [
        ("廊下", "rouka", "koridor"),
        ("回廊", "kairou", "koridor melingkar"),
        ("画廊", "garou", "galeri lukisan"),
    ], [
        ("廊下を歩きました。", "Rouka o arukimashita.", "Berjalan di koridor."),
        ("画廊を訪れました。", "Garou o otozuremashita.", "Mengunjungi galeri lukisan."),
    ]),
    ("jaku_n1", "寂", ["ジャク"], ["さび-しい", "さび-れる"], ["sepi", "loneliness", "quiet"], 11, "宀", [
        ("寂しい", "sabishii", "kesepian"),
        ("静寂", "seijaku", "keheningan"),
        ("閑寂", "kanjaku", "sunyi senyap"),
    ], [
        ("寂しいです。", "Sabishii desu.", "Kesepian."),
        ("静寂に包まれています。", "Seijaku ni tsutsumarete imasu.", "Diselimuti keheningan."),
    ]),
    ("shin8_n1", "辰", ["シン"], ["たつ"], ["naga (shio)", "waktu"], 7, "辰", [
        ("辰", "tatsu", "tahun naga dalam zodiak"),
        ("誕辰", "tanshin", "hari lahir"),
        ("北辰", "hokushin", "bintang utara"),
    ], [
        ("辰年生まれです。", "Tatsudoshi umare desu.", "Lahir di tahun naga."),
        ("北辰を仰ぎました。", "Hokushin o aogimashita.", "Memandang bintang utara."),
    ]),
    ("ka11_n1", "霞", ["カ"], ["かすみ", "かす-む"], ["kabut", "mist", "haze"], 17, "雨", [
        ("霞", "kasumi", "kabut tipis"),
        ("霞む", "kasumu", "berkabut/samar"),
        ("霞ヶ関", "Kasumigaseki", "nama daerah di Tokyo"),
    ], [
        ("霞がかかっています。", "Kasumi ga kakatte imasu.", "Berkabut."),
        ("目が霞んでいます。", "Me ga kasunde imasu.", "Pandangan menjadi kabur."),
    ]),
    ("fuku2_n1", "伏", ["フク"], ["ふ-せる", "ふ-す"], ["menunduk", "tersembunyi", "lie down", "hide"], 6, "人", [
        ("伏せる", "fuseru", "menunduk/menyembunyikan"),
        ("起伏", "kifuku", "naik turun"),
        ("潜伏", "senpuku", "bersembunyi"),
    ], [
        ("顔を伏せました。", "Kao o fusemashita.", "Menunduk."),
        ("起伏が激しいです。", "Kifuku ga hageshii desu.", "Naik turunnya drastis."),
    ]),
    ("haku4_n1", "柏", ["ハク"], ["かしわ"], ["pohon ek Jepang", "oak"], 9, "木", [
        ("柏", "kashiwa", "pohon oak Jepang"),
        ("柏餅", "kashiwamochi", "kue mochi daun oak"),
        ("柏市", "Kashiwa-shi", "nama kota"),
    ], [
        ("柏餅を食べました。", "Kashiwamochi o tabemashita.", "Makan kue mochi daun oak."),
        ("柏市に住んでいます。", "Kashiwa-shi ni sunde imasu.", "Tinggal di kota Kashiwa."),
    ]),
    ("go3_n1", "碁", ["ゴ"], [], ["permainan go", "go (board game)"], 13, "石", [
        ("碁", "go", "permainan go"),
        ("囲碁", "igo", "permainan go"),
        ("碁盤", "goban", "papan go"),
    ], [
        ("碁を打ちました。", "Go o uchimashita.", "Bermain go."),
        ("囲碁教室に通っています。", "Igo kyoushitsu ni kayotte imasu.", "Mengikuti kelas go."),
    ]),
    ("zoku2_n1", "俗", ["ゾク"], [], ["adat", "duniawi", "common", "vulgar"], 9, "人", [
        ("風俗", "fuuzoku", "adat istiadat"),
        ("俗語", "zokugo", "bahasa gaul"),
        ("通俗", "tsuuzoku", "populer/umum"),
    ], [
        ("風俗習慣です。", "Fuuzoku shuukan desu.", "Ini adat istiadat."),
        ("俗語を使いました。", "Zokugo o tsukaimashita.", "Menggunakan bahasa gaul."),
    ]),
    ("baku_n1", "漠", ["バク"], [], ["luas", "samar", "vast", "vague"], 13, "水", [
        ("砂漠", "sabaku", "gurun"),
        ("漠然", "bakuzen", "samar-samar"),
        ("空漠", "kuubaku", "kosong luas"),
    ], [
        ("砂漠を旅しました。", "Sabaku o tabishimashita.", "Berjalan-jalan di gurun."),
        ("漠然とした不安です。", "Bakuzen to shita fuan desu.", "Ini kecemasan yang samar."),
    ]),
    ("ja_n1", "邪", ["ジャ"], [], ["jahat", "evil", "wicked"], 8, "邑", [
        ("邪魔", "jama", "mengganggu"),
        ("邪悪", "jaaku", "jahat"),
        ("邪推", "jasui", "curiga yang tidak berdasar"),
    ], [
        ("邪魔しないでください。", "Jama shinaide kudasai.", "Jangan mengganggu."),
        ("邪悪な計画です。", "Jaaku na keikaku desu.", "Ini rencana yang jahat."),
    ]),
    ("shou22_n1", "晶", ["ショウ"], [], ["kristal", "crystal"], 12, "日", [
        ("結晶", "kesshou", "kristal"),
        ("水晶", "suishou", "kuarsa/kristal batu"),
        ("液晶", "ekishou", "layar kristal cair"),
    ], [
        ("結晶ができました。", "Kesshou ga dekimashita.", "Terbentuk kristal."),
        ("水晶を集めています。", "Suishou o atsumete imasu.", "Mengumpulkan kristal batu."),
    ]),
    ("tsuji_n1", "辻", [], ["つじ"], ["persimpangan jalan", "crossroads"], 6, "辵", [
        ("辻", "tsuji", "persimpangan jalan"),
        ("辻褄", "tsujitsuma", "konsistensi/kecocokan cerita"),
        ("辻斬り", "tsujigiri", "pembunuhan di jalan"),
    ], [
        ("辻で待ち合わせました。", "Tsuji de machiawasemashita.", "Bertemu di persimpangan jalan."),
        ("辻褄が合いません。", "Tsujitsuma ga aimasen.", "Ceritanya tidak konsisten."),
    ]),
    ("boku4_n1", "墨", ["ボク"], ["すみ"], ["tinta", "ink"], 14, "土", [
        ("墨", "sumi", "tinta hitam"),
        ("墨汁", "bokujuu", "tinta cair"),
        ("水墨画", "suibokuga", "lukisan tinta air"),
    ], [
        ("墨で書きました。", "Sumi de kakimashita.", "Menulis dengan tinta."),
        ("水墨画を描きました。", "Suibokuga o egakimashita.", "Melukis lukisan tinta air."),
    ]),
    ("chin3_n1", "鎮", ["チン"], ["しず-める", "しず-まる"], ["menenangkan", "calm", "suppress"], 18, "金", [
        ("鎮める", "shizumeru", "menenangkan"),
        ("鎮圧", "chin-atsu", "penindasan"),
        ("鎮痛剤", "chintsuuzai", "obat pereda nyeri"),
    ], [
        ("怒りを鎮めました。", "Ikari o shizumemashita.", "Menenangkan kemarahan."),
        ("鎮痛剤を飲みました。", "Chintsuuzai o nomimashita.", "Minum obat pereda nyeri."),
    ]),
    ("dou2_n1", "洞", ["ドウ"], ["ほら"], ["gua", "cave", "insight"], 9, "水", [
        ("洞窟", "doukutsu", "gua"),
        ("洞察", "dousatsu", "wawasan/pemahaman mendalam"),
        ("空洞", "kuudou", "rongga"),
    ], [
        ("洞窟を探検しました。", "Doukutsu o tanken shimashita.", "Menjelajahi gua."),
        ("洞察力があります。", "Dousatsuryoku ga arimasu.", "Memiliki daya wawasan."),
    ]),
    ("ri5_n1", "履", ["リ"], ["は-く"], ["alas kaki", "melaksanakan", "footwear"], 15, "尸", [
        ("履く", "haku", "memakai (alas kaki)"),
        ("履歴書", "rirekisho", "CV/riwayat hidup"),
        ("履行", "rikou", "pelaksanaan"),
    ], [
        ("靴を履きました。", "Kutsu o hakimashita.", "Memakai sepatu."),
        ("履歴書を提出しました。", "Rirekisho o teishutsu shimashita.", "Mengirimkan CV."),
    ]),
    ("retsu3_n1", "劣", ["レツ"], ["おと-る"], ["lebih rendah", "inferior"], 6, "力", [
        ("劣る", "otoru", "lebih rendah/kalah"),
        ("劣等感", "rettoukan", "rasa rendah diri"),
        ("優劣", "yuuretsu", "unggul dan kalah"),
    ], [
        ("実力が劣っています。", "Jitsuryoku ga ototte imasu.", "Kemampuannya lebih rendah."),
        ("劣等感を感じています。", "Rettoukan o kanjite imasu.", "Merasa rendah diri."),
    ]),
    ("na2_n1", "那", ["ナ"], [], ["partikel klasik", "what", "that"], 7, "邑", [
        ("刹那", "setsuna", "sekejap"),
        ("那覇", "Naha", "ibu kota Okinawa"),
        ("旦那", "danna", "suami/tuan"),
    ], [
        ("刹那の出来事でした。", "Setsuna no dekigoto deshita.", "Ini kejadian sekejap."),
        ("那覇に住んでいます。", "Naha ni sunde imasu.", "Tinggal di Naha."),
    ]),
    ("ou4_n1", "殴", ["オウ"], ["なぐ-る"], ["memukul", "hit", "strike"], 8, "殳", [
        ("殴る", "naguru", "memukul"),
        ("殴打", "outa", "pukulan"),
        ("殴り合い", "naguriai", "saling pukul"),
    ], [
        ("殴られました。", "Nagurare mashita.", "Dipukul."),
        ("殴打事件です。", "Outa jiken desu.", "Ini kasus pemukulan."),
    ]),
    ("shin9_n1", "娠", ["シン"], [], ["kehamilan", "pregnancy"], 10, "女", [
        ("妊娠中", "ninshinchuu", "sedang hamil"),
        ("妊娠期間", "ninshin kikan", "masa kehamilan"),
        ("妊娠検査", "ninshin kensa", "tes kehamilan"),
    ], [
        ("妊娠中です。", "Ninshinchuu desu.", "Sedang hamil."),
        ("妊娠検査をしました。", "Ninshin kensa o shimashita.", "Melakukan tes kehamilan."),
    ]),
    ("hou6_n1", "奉", ["ホウ"], ["たてまつ-る"], ["mengabdi", "serve", "dedicate"], 8, "大", [
        ("奉仕", "houshi", "pengabdian"),
        ("奉納", "hounou", "persembahan"),
        ("信奉", "shinpou", "kepercayaan/keyakinan"),
    ], [
        ("社会奉仕をしています。", "Shakai houshi o shite imasu.", "Melakukan pengabdian sosial."),
        ("神社に奉納しました。", "Jinja ni hounou shimashita.", "Mempersembahkan di kuil."),
    ]),
    ("yuu5_n1", "憂", ["ユウ"], ["うれ-える", "う-い"], ["khawatir", "worry", "melancholy"], 15, "心", [
        ("憂鬱", "yuuutsu", "depresi/murung"),
        ("憂う", "ureeru", "mengkhawatirkan"),
        ("憂慮", "yuuryo", "kekhawatiran"),
    ], [
        ("憂鬱な気分です。", "Yuuutsu na kibun desu.", "Perasaan yang murung."),
        ("将来を憂えています。", "Shourai o ureete imasu.", "Mengkhawatirkan masa depan."),
    ]),
    ("boku5_n1", "朴", ["ボク"], ["ほお"], ["sederhana", "simple", "plain"], 6, "木", [
        ("素朴", "soboku", "sederhana/polos"),
        ("朴訥", "bokutotsu", "jujur dan tidak banyak bicara"),
        ("純朴", "junboku", "murni dan sederhana"),
    ], [
        ("素朴な人柄です。", "Soboku na hitogara desu.", "Kepribadian yang sederhana."),
        ("純朴な村人です。", "Junboku na murabito desu.", "Penduduk desa yang murni dan sederhana."),
    ]),
    ("tei10_n1", "亭", ["テイ"], [], ["paviliun", "pavilion"], 9, "亠", [
        ("料亭", "ryoutei", "restoran mewah tradisional"),
        ("亭主", "teishu", "suami/tuan rumah"),
        ("旅亭", "ryotei", "penginapan"),
    ], [
        ("料亭で食事をしました。", "Ryoutei de shokuji o shimashita.", "Makan di restoran mewah tradisional."),
        ("亭主が出迎えました。", "Teishu ga demukaemashita.", "Suami menyambut."),
    ]),
    ("jun5_n1", "淳", ["ジュン"], [], ["murni (nama)", "pure", "honest"], 11, "水", [
        ("淳朴", "junboku", "murni dan sederhana"),
        ("淳一", "Jun-ichi", "contoh nama pria"),
        ("清淳", "seijun", "jernih dan murni"),
    ], [
        ("淳朴な人柄です。", "Junboku na hitogara desu.", "Kepribadian yang murni dan sederhana."),
        ("淳一さんに会いました。", "Jun-ichi-san ni aimashita.", "Bertemu dengan Jun-ichi."),
    ]),
    ("ogi_n1", "荻", ["テキ"], ["おぎ"], ["rumput alang-alang", "reed grass"], 10, "艸", [
        ("荻", "ogi", "rumput alang-alang"),
        ("荻窪", "Ogikubo", "nama daerah di Tokyo"),
        ("荻原", "Ogiwara", "contoh nama keluarga"),
    ], [
        ("荻が生い茂っています。", "Ogi ga oishigette imasu.", "Rumput alang-alang tumbuh lebat."),
        ("荻窪に住んでいます。", "Ogikubo ni sunde imasu.", "Tinggal di Ogikubo."),
    ]),
    ("shima_n1", "嶋", [], ["しま"], ["pulau (variant 島)", "island"], 14, "山", [
        ("嶋", "shima", "pulau"),
        ("嶋田", "Shimada", "contoh nama keluarga"),
        ("中嶋", "Nakajima", "contoh nama keluarga"),
    ], [
        ("嶋田さんに会いました。", "Shimada-san ni aimashita.", "Bertemu dengan Shimada."),
        ("中嶋さんは有名な選手です。", "Nakajima-san wa yuumei na senshu desu.", "Nakajima adalah atlet terkenal."),
    ]),
    ("kai6_n1", "怪", ["カイ"], ["あや-しい"], ["mencurigakan", "suspicious", "mysterious"], 8, "心", [
        ("怪しい", "ayashii", "mencurigakan"),
        ("怪我", "kega", "luka/cedera"),
        ("怪物", "kaibutsu", "monster"),
    ], [
        ("怪しい人がいます。", "Ayashii hito ga imasu.", "Ada orang yang mencurigakan."),
        ("怪我をしました。", "Kega o shimashita.", "Terluka."),
    ]),
    ("kyuu7_n1", "鳩", ["キュウ"], ["はと"], ["burung merpati", "pigeon"], 13, "鳥", [
        ("鳩", "hato", "burung merpati"),
        ("鳩胸", "hatomune", "dada burung merpati/menonjol"),
        ("伝書鳩", "denshobato", "merpati pos"),
    ], [
        ("鳩に餌をあげました。", "Hato ni esa o agemashita.", "Memberi makan merpati."),
        ("伝書鳩を飼っています。", "Denshobato o katte imasu.", "Memelihara merpati pos."),
    ]),
    ("shi18_n1", "柴", ["シ"], ["しば"], ["kayu bakar kecil", "brushwood"], 9, "木", [
        ("柴犬", "shibainu", "anjing Shiba"),
        ("柴刈り", "shibakari", "mengumpulkan kayu bakar"),
        ("柴田", "Shibata", "contoh nama keluarga"),
    ], [
        ("柴犬を飼っています。", "Shibainu o katte imasu.", "Memelihara anjing Shiba."),
        ("柴刈りに行きました。", "Shibakari ni ikimashita.", "Pergi mengumpulkan kayu bakar."),
    ]),
    ("sui4_n1", "酔", ["スイ"], ["よ-う"], ["mabuk", "drunk", "intoxicated"], 11, "酉", [
        ("酔う", "you", "mabuk"),
        ("酔っ払い", "yopparai", "orang mabuk"),
        ("麻酔", "masui", "anestesi"),
    ], [
        ("酒に酔いました。", "Sake ni yoimashita.", "Mabuk karena sake."),
        ("酔っ払いがいます。", "Yopparai ga imasu.", "Ada orang mabuk."),
    ]),
    ("seki2_n1", "惜", ["セキ"], ["お-しい", "お-しむ"], ["sayang", "berharga", "regret", "precious"], 11, "心", [
        ("惜しい", "oshii", "sayang sekali"),
        ("惜しむ", "oshimu", "merasa sayang/menyesali"),
        ("哀惜", "aiseki", "kesedihan dan penyesalan"),
    ], [
        ("惜しい結果でした。", "Oshii kekka deshita.", "Ini hasil yang sayang sekali."),
        ("別れを惜しみました。", "Wakare o oshimimashita.", "Merasa sayang berpisah."),
    ]),
    ("kaku7_n1", "穫", ["カク"], [], ["memanen", "harvest"], 18, "禾", [
        ("収穫", "shuukaku", "panen"),
        ("収穫祭", "shuukakusai", "festival panen"),
        ("穫れる", "toreru", "dipanen"),
    ], [
        ("米を収穫しました。", "Kome o shuukaku shimashita.", "Memanen beras."),
        ("収穫祭がありました。", "Shuukakusai ga arimashita.", "Ada festival panen."),
    ]),
    ("ka12_n1", "佳", ["カ"], [], ["indah", "bagus", "beautiful", "excellent"], 8, "人", [
        ("佳作", "kasaku", "karya terpuji"),
        ("佳境", "kakyou", "klimaks/puncak"),
        ("絶佳", "zekka", "sangat indah"),
    ], [
        ("佳作に選ばれました。", "Kasaku ni erabaremashita.", "Terpilih sebagai karya terpuji."),
        ("佳境に入りました。", "Kakyou ni hairimashita.", "Memasuki klimaks."),
    ]),
    ("jun6_n1", "潤", ["ジュン"], ["うるお-う", "うるお-す"], ["lembab", "menguntungkan", "moist", "profit"], 15, "水", [
        ("潤う", "uruou", "menjadi lembab/menguntungkan"),
        ("潤滑油", "junkatsuyu", "minyak pelumas"),
        ("利潤", "rijun", "keuntungan"),
    ], [
        ("肌が潤いました。", "Hada ga uruoimashita.", "Kulit menjadi lembab."),
        ("利潤を追求しています。", "Rijun o tsuikyuu shite imasu.", "Mengejar keuntungan."),
    ]),
    ("tou13_n1", "悼", ["トウ"], ["いた-む"], ["berduka", "mourn"], 11, "心", [
        ("哀悼", "aitou", "belasungkawa"),
        ("悼む", "itamu", "berduka"),
        ("追悼", "tsuitou", "mengenang almarhum"),
    ], [
        ("哀悼の意を表します。", "Aitou no i o hyoushimasu.", "Menyampaikan belasungkawa."),
        ("追悼式です。", "Tsuitoushiki desu.", "Ini upacara peringatan."),
    ]),
    ("bou6_n1", "乏", ["ボウ"], ["とぼ-しい"], ["kekurangan", "scarce"], 4, "丿", [
        ("乏しい", "toboshii", "kekurangan"),
        ("欠乏", "ketsubou", "kekurangan"),
        ("貧乏", "binbou", "miskin"),
    ], [
        ("経験が乏しいです。", "Keiken ga toboshii desu.", "Kurang pengalaman."),
        ("貧乏な生活でした。", "Binbou na seikatsu deshita.", "Ini kehidupan yang miskin."),
    ]),
    ("gai4_n1", "該", ["ガイ"], [], ["yang bersangkutan", "the said", "relevant"], 13, "言", [
        ("該当", "gaitou", "sesuai/relevan"),
        ("該当者", "gaitousha", "orang yang bersangkutan"),
        ("当該", "tougai", "yang bersangkutan"),
    ], [
        ("該当者はいません。", "Gaitousha wa imasen.", "Tidak ada orang yang bersangkutan."),
        ("当該事項です。", "Tougai jikou desu.", "Ini hal yang bersangkutan."),
    ]),
    ("fu4_n1", "赴", ["フ"], ["おもむ-く"], ["pergi menuju", "proceed to"], 9, "走", [
        ("赴く", "omomuku", "pergi menuju"),
        ("赴任", "funin", "penugasan ke tempat baru"),
        ("赴任地", "funinchi", "tempat tugas"),
    ], [
        ("現場に赴きました。", "Genba ni omomukimashita.", "Pergi ke lokasi."),
        ("海外に赴任しました。", "Kaigai ni funin shimashita.", "Ditugaskan ke luar negeri."),
    ]),
    ("sou13_n1", "桑", ["ソウ"], ["くわ"], ["pohon murbei", "mulberry"], 10, "木", [
        ("桑", "kuwa", "pohon murbei"),
        ("桑畑", "kuwabatake", "kebun murbei"),
        ("桑の実", "kuwa no mi", "buah murbei"),
    ], [
        ("桑畑があります。", "Kuwabatake ga arimasu.", "Ada kebun murbei."),
        ("桑の実を食べました。", "Kuwa no mi o tabemashita.", "Makan buah murbei."),
    ]),
    ("kei11_n1", "桂", ["ケイ"], ["かつら"], ["pohon kayu manis", "cinnamon", "laurel"], 10, "木", [
        ("桂", "katsura", "pohon katsura"),
        ("桂皮", "keihi", "kulit kayu manis"),
        ("月桂樹", "gekkeiju", "pohon laurel"),
    ], [
        ("月桂樹の冠です。", "Gekkeiju no kanmuri desu.", "Ini mahkota daun laurel."),
        ("桂皮を使いました。", "Keihi o tsukaimashita.", "Menggunakan kulit kayu manis."),
    ]),
    ("zui2_n1", "髄", ["ズイ"], [], ["sumsum", "marrow"], 19, "骨", [
        ("骨髄", "kotsuzui", "sumsum tulang"),
        ("脊髄", "sekizui", "sumsum tulang belakang"),
        ("精髄", "seizui", "inti sari"),
    ], [
        ("骨髄移植をしました。", "Kotsuzui ishoku o shimashita.", "Melakukan transplantasi sumsum tulang."),
        ("脊髄損傷です。", "Sekizui sonshou desu.", "Ini cedera sumsum tulang belakang."),
    ]),
    ("tora_n1", "虎", ["コ"], ["とら"], ["harimau", "tiger"], 8, "虍", [
        ("虎", "tora", "harimau"),
        ("虎の子", "tora no ko", "harta karun/sangat berharga"),
        ("虎視眈々", "koshitantan", "mengintai dengan waspada"),
    ], [
        ("虎を見ました。", "Tora o mimashita.", "Melihat harimau."),
        ("虎の子の資金です。", "Tora no ko no shikin desu.", "Ini dana yang sangat berharga."),
    ]),
    ("bon_n1", "盆", ["ボン"], [], ["nampan", "festival Obon", "tray"], 9, "皿", [
        ("盆", "bon", "nampan"),
        ("お盆", "obon", "festival Obon"),
        ("盆栽", "bonsai", "bonsai"),
    ], [
        ("お盆に帰省しました。", "Obon ni kisei shimashita.", "Pulang kampung saat Obon."),
        ("盆にお菓子を乗せました。", "Bon ni okashi o nosemashita.", "Meletakkan kue di atas nampan."),
    ]),
    ("shin10_n1", "晋", ["シン"], [], ["nama Dinasti Jin", "advance"], 10, "日", [
        ("晋", "Shin", "nama Dinasti Jin Tiongkok kuno"),
        ("晋太郎", "Shintarou", "contoh nama pria"),
        ("東晋", "Toushin", "Dinasti Jin Timur"),
    ], [
        ("晋の時代です。", "Shin no jidai desu.", "Ini era Dinasti Jin."),
        ("晋太郎という名前です。", "Shintarou to iu namae desu.", "Ini nama Shintaro."),
    ]),
    ("sui5_n1", "穂", ["スイ"], ["ほ"], ["bulir padi", "ear of grain"], 15, "禾", [
        ("穂", "ho", "bulir padi"),
        ("稲穂", "inaho", "bulir padi"),
        ("出穂", "shussui", "munculnya bulir"),
    ], [
        ("稲穂が実りました。", "Inaho ga minorimashita.", "Bulir padi berbuah."),
        ("出穂期です。", "Shussuiki desu.", "Ini musim munculnya bulir."),
    ]),
    ("sou14_n1", "壮", ["ソウ"], [], ["kuat", "megah", "robust", "grand"], 6, "士", [
        ("壮大", "soudai", "megah"),
        ("壮健", "souken", "sehat dan kuat"),
        ("悲壮", "hisou", "tragis dan heroik"),
    ], [
        ("壮大な景色です。", "Soudai na keshiki desu.", "Ini pemandangan yang megah."),
        ("壮健に暮らしています。", "Souken ni kurashite imasu.", "Hidup sehat dan kuat."),
    ]),
    ("tei11_n1", "堤", ["テイ"], ["つつみ"], ["tanggul", "embankment"], 12, "土", [
        ("堤防", "teibou", "tanggul"),
        ("堤", "tsutsumi", "tanggul"),
        ("防波堤", "bouhatei", "pemecah gelombang"),
    ], [
        ("堤防が決壊しました。", "Teibou ga kekkai shimashita.", "Tanggul jebol."),
        ("防波堤で釣りをしました。", "Bouhatei de tsuri o shimashita.", "Memancing di pemecah gelombang."),
    ]),
    ("ki17_n1", "飢", ["キ"], ["う-える"], ["kelaparan", "starve"], 10, "食", [
        ("飢える", "ueru", "kelaparan"),
        ("飢餓", "kiga", "kelaparan"),
        ("飢饉", "kikin", "bencana kelaparan"),
    ], [
        ("飢えています。", "Uete imasu.", "Kelaparan."),
        ("飢饉が発生しました。", "Kikin ga hassei shimashita.", "Bencana kelaparan terjadi."),
    ]),
    ("bou7_n1", "傍", ["ボウ"], ["かたわ-ら"], ["di samping", "beside"], 12, "人", [
        ("傍ら", "katawara", "di samping"),
        ("傍観", "boukan", "menonton tanpa terlibat"),
        ("近傍", "kinbou", "sekitar/tetangga"),
    ], [
        ("傍らに置きました。", "Katawara ni okimashita.", "Meletakkan di samping."),
        ("傍観しているだけです。", "Boukan shite iru dake desu.", "Hanya menonton saja."),
    ]),
    ("eki2_n1", "疫", ["エキ"], [], ["wabah", "epidemic"], 9, "疒", [
        ("疫病", "ekibyou", "wabah penyakit"),
        ("検疫", "ken-eki", "karantina"),
        ("免疫", "men-eki", "kekebalan tubuh"),
    ], [
        ("疫病が流行しました。", "Ekibyou ga ryuukou shimashita.", "Wabah penyakit merebak."),
        ("免疫力を高めましょう。", "Men-ekiryoku o takamemashou.", "Mari tingkatkan kekebalan tubuh."),
    ]),
    ("rui2_n1", "累", ["ルイ"], [], ["bertumpuk", "melibatkan", "accumulate"], 11, "糸", [
        ("累計", "ruikei", "jumlah kumulatif"),
        ("累積", "ruiseki", "akumulasi"),
        ("連累", "renrui", "terlibat/tersangkut"),
    ], [
        ("累計販売数です。", "Ruikei hanbaisuu desu.", "Ini jumlah penjualan kumulatif."),
        ("累積した疲労です。", "Ruiseki shita hirou desu.", "Ini kelelahan yang menumpuk."),
    ]),
    ("chi4_n1", "痴", ["チ"], [], ["bodoh", "tergila-gila", "foolish", "infatuated"], 13, "疒", [
        ("痴漢", "chikan", "pelaku pelecehan seksual"),
        ("音痴", "onchi", "tidak bisa bernyanyi"),
        ("白痴", "hakuchi", "keterbelakangan mental"),
    ], [
        ("痴漢に注意してください。", "Chikan ni chuui shite kudasai.", "Waspadalah terhadap pelaku pelecehan."),
        ("音痴です。", "Onchi desu.", "Saya tidak bisa bernyanyi dengan baik."),
    ]),
    ("han5_n1", "搬", ["ハン"], [], ["mengangkut", "transport"], 13, "手", [
        ("運搬", "unpan", "pengangkutan"),
        ("搬入", "hannyuu", "memasukkan barang"),
        ("搬出", "hanshutsu", "mengeluarkan barang"),
    ], [
        ("荷物を運搬しました。", "Nimotsu o unpan shimashita.", "Mengangkut barang."),
        ("搬入作業です。", "Hannyuu sagyou desu.", "Ini pekerjaan memasukkan barang."),
    ]),
    ("kou25_n1", "晃", ["コウ"], [], ["terang (nama)", "bright"], 10, "日", [
        ("晃一", "Kouichi", "contoh nama pria"),
        ("晃子", "Akiko", "contoh nama wanita"),
        ("光晃", "koukou", "cahaya terang"),
    ], [
        ("晃一さんに会いました。", "Kouichi-san ni aimashita.", "Bertemu dengan Kouichi."),
        ("晃子さんは私の友達です。", "Akiko-san wa watashi no tomodachi desu.", "Akiko adalah teman saya."),
    ]),
    ("yu3_n1", "癒", ["ユ"], ["い-える", "い-やす"], ["menyembuhkan", "heal"], 18, "疒", [
        ("癒える", "ieru", "sembuh"),
        ("治癒", "chiyu", "kesembuhan"),
        ("癒し", "iyashi", "penyembuhan/ketenangan"),
    ], [
        ("傷が癒えました。", "Kizu ga iemashita.", "Luka sembuh."),
        ("癒しの音楽です。", "Iyashi no ongaku desu.", "Ini musik yang menenangkan."),
    ]),
    ("tou14_n1", "桐", ["トウ"], ["きり"], ["pohon paulownia", "paulownia tree"], 10, "木", [
        ("桐", "kiri", "pohon paulownia"),
        ("桐箱", "kiribako", "kotak kayu paulownia"),
        ("桐たんす", "kiritansu", "lemari kayu paulownia"),
    ], [
        ("桐の木があります。", "Kiri no ki ga arimasu.", "Ada pohon paulownia."),
        ("桐箱に入れました。", "Kiribako ni iremashita.", "Dimasukkan ke kotak kayu paulownia."),
    ]),
    ("sun_n1", "寸", ["スン"], [], ["satuan ukur inci", "sedikit", "inch", "little"], 3, "寸", [
        ("寸法", "sunpou", "ukuran"),
        ("一寸", "issun", "sedikit/sejenak"),
        ("原寸", "gensun", "ukuran asli"),
    ], [
        ("寸法を測りました。", "Sunpou o hakarimashita.", "Mengukur ukuran."),
        ("一寸お待ちください。", "Issun omachi kudasai.", "Tunggu sebentar."),
    ]),
    ("kaku8_n1", "郭", ["カク"], [], ["tembok luar", "outer wall", "outline"], 11, "邑", [
        ("輪郭", "rinkaku", "garis besar/kontur"),
        ("城郭", "joukaku", "benteng"),
        ("郭清", "kakusei", "pembersihan"),
    ], [
        ("輪郭がはっきりしています。", "Rinkaku ga hakkiri shite imasu.", "Konturnya jelas."),
        ("城郭都市です。", "Joukaku toshi desu.", "Ini kota berbenteng."),
    ]),
    ("nyou_n1", "尿", ["ニョウ"], [], ["air seni", "urine"], 7, "尸", [
        ("尿", "nyou", "air seni"),
        ("尿意", "nyoui", "keinginan buang air kecil"),
        ("糖尿病", "tounyoubyou", "diabetes"),
    ], [
        ("尿検査をしました。", "Nyou kensa o shimashita.", "Melakukan tes urin."),
        ("糖尿病です。", "Tounyoubyou desu.", "Menderita diabetes."),
    ]),
    ("kyou8_n1", "凶", ["キョウ"], [], ["sial", "kejahatan", "bad luck", "atrocity"], 4, "凵", [
        ("凶悪", "kyouaku", "kejam"),
        ("凶器", "kyouki", "senjata pembunuhan"),
        ("大凶", "daikyou", "sangat sial"),
    ], [
        ("凶悪犯罪です。", "Kyouaku hanzai desu.", "Ini kejahatan yang kejam."),
        ("凶器を持っていました。", "Kyouki o motte imashita.", "Membawa senjata."),
    ]),
    ("to_n1", "吐", ["ト"], ["は-く"], ["memuntahkan", "vomit", "spit"], 6, "口", [
        ("吐く", "haku", "memuntahkan/mengucapkan"),
        ("嘔吐", "outo", "muntah"),
        ("吐息", "toiki", "embusan napas"),
    ], [
        ("気分が悪くて吐きました。", "Kibun ga warukute hakimashita.", "Muntah karena mual."),
        ("ため息を吐きました。", "Tameiki o tsukimashita.", "Menghela napas."),
    ]),
    ("en5_n1", "宴", ["エン"], [], ["pesta", "banquet"], 10, "宀", [
        ("宴会", "enkai", "pesta"),
        ("披露宴", "hirouen", "resepsi pernikahan"),
        ("祝宴", "shukuen", "pesta perayaan"),
    ], [
        ("宴会に参加しました。", "Enkai ni sanka shimashita.", "Menghadiri pesta."),
        ("祝宴が開かれました。", "Shukuen ga hirakaremashita.", "Pesta perayaan diselenggarakan."),
    ]),
    ("you6_n1", "鷹", ["ヨウ"], ["たか"], ["elang", "hawk"], 24, "鳥", [
        ("鷹", "taka", "elang"),
        ("鷹狩り", "takagari", "berburu dengan elang"),
        ("鷹揚", "ouyou", "tenang/berwibawa"),
    ], [
        ("鷹が飛んでいます。", "Taka ga tonde imasu.", "Elang sedang terbang."),
        ("鷹狩りをしました。", "Takagari o shimashita.", "Berburu dengan elang."),
    ]),
    ("hin3_n1", "賓", ["ヒン"], [], ["tamu", "guest", "visitor"], 15, "貝", [
        ("来賓", "raihin", "tamu undangan"),
        ("賓客", "hinkyaku", "tamu kehormatan"),
        ("貴賓", "kihin", "tamu terhormat"),
    ], [
        ("来賓が到着しました。", "Raihin ga touchaku shimashita.", "Tamu undangan tiba."),
        ("貴賓室です。", "Kihinshitsu desu.", "Ini ruang tamu VIP."),
    ]),
    ("ryo2_n1", "虜", ["リョ"], [], ["tawanan", "captive"], 12, "虍", [
        ("捕虜", "horyo", "tawanan perang"),
        ("虜になる", "toriko ni naru", "terpesona"),
        ("虜囚", "ryoshuu", "tawanan"),
    ], [
        ("捕虜になりました。", "Horyo ni narimashita.", "Menjadi tawanan perang."),
        ("美しさの虜になりました。", "Utsukushisa no toriko ni narimashita.", "Terpesona oleh keindahannya."),
    ]),
    ("tou15_n1", "陶", ["トウ"], [], ["keramik", "pottery"], 11, "阜", [
        ("陶器", "touki", "keramik"),
        ("陶芸", "tougei", "seni keramik"),
        ("陶酔", "tousui", "terbuai/terpesona"),
    ], [
        ("陶器を作りました。", "Touki o tsukurimashita.", "Membuat keramik."),
        ("陶芸教室に通っています。", "Tougei kyoushitsu ni kayotte imasu.", "Mengikuti kelas seni keramik."),
    ]),
    ("shou23_n1", "鐘", ["ショウ"], ["かね"], ["lonceng", "bell"], 20, "金", [
        ("鐘", "kane", "lonceng"),
        ("鐘楼", "shourou", "menara lonceng"),
        ("警鐘", "keishou", "lonceng peringatan"),
    ], [
        ("鐘が鳴りました。", "Kane ga narimashita.", "Lonceng berbunyi."),
        ("警鐘を鳴らしました。", "Keishou o narashimashita.", "Membunyikan lonceng peringatan."),
    ]),
    ("kan25_n1", "憾", ["カン"], [], ["penyesalan", "regret"], 16, "心", [
        ("遺憾", "ikan", "disesalkan"),
        ("遺憾の意", "ikan no i", "rasa penyesalan"),
        ("憾みなく", "urami naku", "tanpa penyesalan"),
    ], [
        ("遺憾に思います。", "Ikan ni omoimasu.", "Saya menyesalkan hal ini."),
        ("遺憾の意を表明しました。", "Ikan no i o hyoumei shimashita.", "Menyatakan rasa penyesalan."),
    ]),
    ("ki18_n1", "畿", ["キ"], [], ["wilayah ibu kota", "capital region"], 15, "田", [
        ("近畿", "kinki", "wilayah Kinki"),
        ("畿内", "kinai", "wilayah dalam ibu kota kuno"),
        ("京畿", "keiki", "sekitar ibu kota"),
    ], [
        ("近畿地方です。", "Kinki chihou desu.", "Ini wilayah Kinki."),
        ("畿内に住んでいました。", "Kinai ni sunde imashita.", "Tinggal di wilayah dalam ibu kota kuno."),
    ]),
    ("cho_n1", "猪", ["チョ"], ["いのしし"], ["babi hutan", "wild boar"], 11, "犬", [
        ("猪", "inoshishi", "babi hutan"),
        ("猪突猛進", "chototsumoushin", "maju tanpa berpikir"),
        ("猪肉", "choniku", "daging babi hutan"),
    ], [
        ("猪が出ました。", "Inoshishi ga demashita.", "Babi hutan muncul."),
        ("猪突猛進するタイプです。", "Chototsumoushin suru taipu desu.", "Tipe yang maju tanpa berpikir."),
    ]),
    ("kou26_n1", "紘", ["コウ"], [], ["tali", "luas (nama)", "cord", "vast"], 10, "糸", [
        ("八紘一宇", "hakkouichiu", "istilah delapan penjuru dunia satu atap"),
        ("紘一", "Kouichi", "contoh nama pria"),
        ("紘", "kou", "tali besar (arkais)"),
    ], [
        ("紘一さんに会いました。", "Kouichi-san ni aimashita.", "Bertemu dengan Kouichi."),
        ("八紘一宇という言葉があります。", "Hakkouichiu to iu kotoba ga arimasu.", "Ada istilah \"hakkouichiu\"."),
    ]),
    ("ji2_n1", "磁", ["ジ"], [], ["magnet", "magnetic"], 14, "石", [
        ("磁石", "jishaku", "magnet"),
        ("磁気", "jiki", "magnetisme"),
        ("陶磁器", "toujiki", "keramik dan porselen"),
    ], [
        ("磁石で引き寄せました。", "Jishaku de hikiyosemashita.", "Menarik dengan magnet."),
        ("磁気を帯びています。", "Jiki o obite imasu.", "Bermuatan magnet."),
    ]),
    ("ya2_n1", "弥", ["ビ"], ["いよ-いよ", "や"], ["semakin", "seluruh", "increasingly", "entire"], 8, "弓", [
        ("弥生", "Yayoi", "zaman Yayoi/bulan Maret"),
        ("弥次", "yaji", "olok-olok"),
        ("弥彦", "Yahiko", "nama tempat"),
    ], [
        ("弥生時代です。", "Yayoi jidai desu.", "Ini zaman Yayoi."),
        ("弥生という月です。", "Yayoi to iu tsuki desu.", "Bulan yang disebut Yayoi."),
    ]),
    ("kon2_n1", "昆", ["コン"], [], ["serangga", "kakak", "insect", "elder brother"], 8, "日", [
        ("昆虫", "konchuu", "serangga"),
        ("昆布", "konbu", "rumput laut kombu"),
        ("昆虫採集", "konchuu saishuu", "mengoleksi serangga"),
    ], [
        ("昆虫を観察しました。", "Konchuu o kansatsu shimashita.", "Mengamati serangga."),
        ("昆布だしを使いました。", "Konbu dashi o tsukaimashita.", "Menggunakan kaldu kombu."),
    ]),
    ("so7_n1", "粗", ["ソ"], ["あら-い"], ["kasar", "coarse", "rough"], 11, "米", [
        ("粗い", "arai", "kasar"),
        ("粗末", "somatsu", "sembarangan/murahan"),
        ("粗大ごみ", "sodai gomi", "sampah besar"),
    ], [
        ("粗い作りです。", "Arai tsukuri desu.", "Ini buatan yang kasar."),
        ("粗末に扱わないでください。", "Somatsu ni atsukawanaide kudasai.", "Jangan perlakukan dengan sembarangan."),
    ]),
    ("tei12_n1", "訂", ["テイ"], [], ["mengoreksi", "correct", "revise"], 9, "言", [
        ("訂正", "teisei", "koreksi"),
        ("改訂", "kaitei", "revisi"),
        ("校訂", "koutei", "penyuntingan naskah"),
    ], [
        ("訂正しました。", "Teisei shimashita.", "Melakukan koreksi."),
        ("改訂版です。", "Kaiteiban desu.", "Ini edisi revisi."),
    ]),
    ("ga4_n1", "芽", ["ガ"], ["め"], ["tunas", "sprout", "bud"], 8, "艸", [
        ("芽", "me", "tunas"),
        ("発芽", "hatsuga", "perkecambahan"),
        ("新芽", "shinme", "tunas baru"),
    ], [
        ("芽が出ました。", "Me ga demashita.", "Tunas muncul."),
        ("発芽しました。", "Hatsuga shimashita.", "Berkecambah."),
    ]),
    ("shiri_n1", "尻", [], ["しり"], ["pantat", "buttocks", "bottom"], 5, "尸", [
        ("尻", "shiri", "pantat"),
        ("尻尾", "shippo", "ekor"),
        ("目尻", "mejiri", "sudut mata"),
    ], [
        ("尻尾を振りました。", "Shippo o furimashita.", "Mengibaskan ekor."),
        ("目尻にしわがあります。", "Mejiri ni shiwa ga arimasu.", "Ada kerutan di sudut mata."),
    ]),
    ("shou24_n1", "庄", ["ショウ"], [], ["desa", "perkebunan", "manor", "village"], 6, "广", [
        ("庄屋", "shouya", "kepala desa zaman Edo"),
        ("庄園", "shouen", "perkebunan feodal"),
        ("荘園", "shouen", "perkebunan feodal (variant)"),
    ], [
        ("庄屋を務めました。", "Shouya o tsutomemashita.", "Menjabat sebagai kepala desa."),
        ("庄園制度でした。", "Shouen seido deshita.", "Ini adalah sistem perkebunan feodal."),
    ]),
    ("san3_n1", "傘", ["サン"], ["かさ"], ["payung", "umbrella"], 12, "人", [
        ("傘", "kasa", "payung"),
        ("傘下", "sanka", "di bawah naungan"),
        ("落下傘", "rakkasan", "parasut"),
    ], [
        ("傘を持ってきました。", "Kasa o motte kimashita.", "Membawa payung."),
        ("傘下企業です。", "Sanka kigyou desu.", "Ini perusahaan di bawah naungan."),
    ]),
    ("ton_n1", "敦", ["トン"], [], ["tulus (nama)", "sincere"], 12, "攴", [
        ("敦煌", "Tonkou", "Dunhuang, kota bersejarah Tiongkok"),
        ("敦子", "Atsuko", "contoh nama wanita"),
        ("敦厚", "tonkou", "tulus dan baik hati"),
    ], [
        ("敦煌の壁画は有名です。", "Tonkou no hekiga wa yuumei desu.", "Lukisan dinding Dunhuang terkenal."),
        ("敦子さんに会いました。", "Atsuko-san ni aimashita.", "Bertemu dengan Atsuko."),
    ]),
    ("ki19_n1", "騎", ["キ"], [], ["menunggang", "ride"], 18, "馬", [
        ("騎士", "kishi", "ksatria"),
        ("騎馬", "kiba", "menunggang kuda"),
        ("一騎打ち", "ikkiuchi", "duel satu lawan satu"),
    ], [
        ("騎士になりました。", "Kishi ni narimashita.", "Menjadi ksatria."),
        ("騎馬戦をしました。", "Kibasen o shimashita.", "Melakukan perang kuda-kudaan."),
    ]),
    ("nei_n1", "寧", ["ネイ"], [], ["tenteram", "lebih baik", "peaceful", "rather"], 14, "宀", [
        ("丁寧", "teinei", "sopan/hati-hati"),
        ("安寧", "annei", "ketentraman"),
        ("寧ろ", "mushiro", "lebih baik/justru"),
    ], [
        ("安寧を願います。", "Annei o negaimasu.", "Berharap ketentraman."),
        ("寧ろ良かったです。", "Mushiro yokatta desu.", "Justru itu bagus."),
    ]),
    ("jun7_n1", "循", ["ジュン"], [], ["mematuhi", "follow", "comply"], 12, "彳", [
        ("循環", "junkan", "sirkulasi"),
        ("因循", "injun", "konservatif/pasif"),
        ("循守", "junshu", "mematuhi"),
    ], [
        ("血液循環です。", "Ketsueki junkan desu.", "Ini sirkulasi darah."),
        ("因循な態度です。", "Injun na taido desu.", "Ini sikap yang pasif."),
    ]),
    ("nin2_n1", "忍", ["ニン"], ["しの-ぶ"], ["menahan", "bertahan", "endure", "ninja"], 7, "心", [
        ("忍者", "ninja", "ninja"),
        ("忍耐", "nintai", "kesabaran"),
        ("忍ぶ", "shinobu", "menahan/bersembunyi"),
    ], [
        ("忍者になりたいです。", "Ninja ni naritai desu.", "Ingin menjadi ninja."),
        ("痛みを忍びました。", "Itami o shinobimashita.", "Menahan rasa sakit."),
    ]),
    ("ban2_n1", "磐", ["バン"], ["いわ"], ["batu besar", "large rock"], 15, "石", [
        ("磐石", "banjaku", "kokoh seperti batu karang"),
        ("常磐", "Tokiwa", "nama tempat"),
        ("磐田", "Iwata", "nama kota"),
    ], [
        ("磐石な基盤です。", "Banjaku na kiban desu.", "Ini fondasi yang kokoh."),
        ("磐田市に行きました。", "Iwata-shi ni ikimashita.", "Pergi ke kota Iwata."),
    ]),
    ("tai7_n1", "怠", ["タイ"], ["なま-ける", "おこた-る"], ["malas", "lazy", "neglect"], 9, "心", [
        ("怠ける", "namakeru", "malas"),
        ("怠慢", "taiman", "kelalaian"),
        ("怠る", "okotaru", "mengabaikan"),
    ], [
        ("勉強を怠けました。", "Benkyou o namakemashita.", "Malas belajar."),
        ("業務怠慢です。", "Gyoumu taiman desu.", "Ini kelalaian tugas."),
    ]),
    ("jo3_n1", "如", ["ジョ"], [], ["seperti", "as if", "like"], 6, "女", [
        ("如何", "ikaga", "bagaimana"),
        ("如実", "jojitsu", "sesuai kenyataan"),
        ("突如", "totsujo", "tiba-tiba"),
    ], [
        ("いかがですか。", "Ikaga desu ka.", "Bagaimana kabarnya."),
        ("突如現れました。", "Totsujo arawaremashita.", "Tiba-tiba muncul."),
    ]),
    ("ryou4_n1", "寮", ["リョウ"], [], ["asrama", "dormitory"], 15, "宀", [
        ("寮", "ryou", "asrama"),
        ("学生寮", "gakuseiryou", "asrama mahasiswa"),
        ("寮生", "ryousei", "penghuni asrama"),
    ], [
        ("寮に住んでいます。", "Ryou ni sunde imasu.", "Tinggal di asrama."),
        ("学生寮に入りました。", "Gakuseiryou ni hairimashita.", "Masuk asrama mahasiswa."),
    ]),
    ("yuu6_n1", "祐", ["ユウ"], [], ["bantuan (nama)", "help", "blessing"], 9, "示", [
        ("天祐", "tenyuu", "berkat surga"),
        ("祐一", "Yuuichi", "contoh nama pria"),
        ("祐筆", "yuuhitsu", "sekretaris/juru tulis kuno"),
    ], [
        ("天祐に恵まれました。", "Tenyuu ni megumaremashita.", "Diberkati oleh surga."),
        ("祐一さんに会いました。", "Yuuichi-san ni aimashita.", "Bertemu dengan Yuuichi."),
    ]),
    ("hou7_n1", "鵬", ["ホウ"], [], ["burung raksasa mitologi", "giant mythical bird"], 19, "鳥", [
        ("鵬", "hou", "burung raksasa mitologi Tiongkok"),
        ("大鵬", "Taihou", "nama pegulat sumo legendaris"),
        ("鵬程万里", "houtei banri", "perjalanan yang sangat jauh"),
    ], [
        ("大鵬という力士がいました。", "Taihou to iu rikishi ga imashita.", "Ada pegulat sumo bernama Taiho."),
        ("鵬程万里の旅です。", "Houtei banri no tabi desu.", "Ini perjalanan yang sangat jauh."),
    ]),
    ("en6_n1", "鉛", ["エン"], ["なまり"], ["timbal", "lead (metal)"], 13, "金", [
        ("鉛", "namari", "timbal"),
        ("鉛筆", "enpitsu", "pensil"),
        ("亜鉛", "aen", "seng"),
    ], [
        ("鉛筆で書きました。", "Enpitsu de kakimashita.", "Menulis dengan pensil."),
        ("鉛中毒です。", "Namari chuudoku desu.", "Ini keracunan timbal."),
    ]),
    ("shu3_n1", "珠", ["シュ"], ["たま"], ["mutiara", "pearl", "jewel"], 10, "玉", [
        ("真珠", "shinju", "mutiara"),
        ("珠算", "shuzan", "sempoa"),
        ("数珠", "juzu", "tasbih Buddha"),
    ], [
        ("真珠のネックレスです。", "Shinju no nekkuresu desu.", "Ini kalung mutiara."),
        ("珠算を習っています。", "Shuzan o naratte imasu.", "Belajar sempoa."),
    ]),
    ("gyou2_n1", "凝", ["ギョウ"], ["こ-る", "こ-らす"], ["membeku", "memusatkan", "congeal", "concentrate"], 16, "冫", [
        ("凝る", "koru", "kaku/tergila-gila"),
        ("凝視", "gyoushi", "menatap tajam"),
        ("凝縮", "gyoushuku", "kondensasi"),
    ], [
        ("肩が凝りました。", "Kata ga korimashita.", "Bahu kaku."),
        ("画面を凝視しました。", "Gamen o gyoushi shimashita.", "Menatap tajam ke layar."),
    ]),
    ("byou2_n1", "苗", ["ビョウ"], ["なえ"], ["bibit tanaman", "seedling"], 8, "艸", [
        ("苗", "nae", "bibit"),
        ("苗字", "myouji", "nama keluarga"),
        ("苗床", "naedoko", "tempat pembibitan"),
    ], [
        ("苗を植えました。", "Nae o uemashita.", "Menanam bibit."),
        ("苗字を教えてください。", "Myouji o oshiete kudasai.", "Tolong beritahu nama keluarga Anda."),
    ]),
    ("juu6_n1", "獣", ["ジュウ"], ["けもの"], ["binatang buas", "beast"], 16, "犬", [
        ("獣", "kemono", "binatang buas"),
        ("野獣", "yajuu", "binatang liar"),
        ("獣医", "juui", "dokter hewan"),
    ], [
        ("野獣のような叫び声です。", "Yajuu no you na sakebigoe desu.", "Ini teriakan seperti binatang liar."),
        ("獣医になりました。", "Juui ni narimashita.", "Menjadi dokter hewan."),
    ]),
    ("ai_n1", "哀", ["アイ"], ["あわ-れ"], ["kesedihan", "sorrow", "pity"], 9, "口", [
        ("哀しい", "kanashii", "sedih"),
        ("哀れ", "aware", "kasihan"),
        ("哀愁", "aishuu", "kesedihan/melankolis"),
    ], [
        ("哀れな姿でした。", "Aware na sugata deshita.", "Ini sosok yang menyedihkan."),
        ("哀愁が漂っています。", "Aishuu ga tadayotte imasu.", "Suasana melankolis menyebar."),
    ]),
    ("chou12_n1", "跳", ["チョウ"], ["と-ぶ", "は-ねる"], ["melompat", "jump"], 13, "足", [
        ("跳ぶ", "tobu", "melompat"),
        ("跳躍", "chouyaku", "lompatan"),
        ("跳ね返る", "hanekaeru", "memantul"),
    ], [
        ("高く跳びました。", "Takaku tobimashita.", "Melompat tinggi."),
        ("跳躍力があります。", "Chouyakuryoku ga arimasu.", "Memiliki daya lompat."),
    ]),
    ("shou25_n1", "匠", ["ショウ"], [], ["pengrajin ahli", "craftsman"], 6, "匚", [
        ("匠", "shou", "pengrajin ahli"),
        ("巨匠", "kyoshou", "maestro"),
        ("意匠", "ishou", "desain"),
    ], [
        ("匠の技です。", "Shou no waza desu.", "Ini keterampilan pengrajin ahli."),
        ("巨匠の作品です。", "Kyoshou no sakuhin desu.", "Ini karya maestro."),
    ]),
    ("sui6_n1", "垂", ["スイ"], ["た-れる", "た-らす"], ["menggantung", "hang down", "droop"], 8, "土", [
        ("垂れる", "tareru", "menggantung/menetes"),
        ("垂直", "suichoku", "vertikal"),
        ("懸垂", "kensui", "pull-up"),
    ], [
        ("涙が垂れました。", "Namida ga taremashita.", "Air mata menetes."),
        ("垂直に立てました。", "Suichoku ni tatemashita.", "Berdiri secara vertikal."),
    ]),
    ("ja2_n1", "蛇", ["ジャ"], ["へび"], ["ular", "snake"], 11, "虫", [
        ("蛇", "hebi", "ular"),
        ("蛇口", "jaguchi", "keran air"),
        ("大蛇", "daija", "ular besar"),
    ], [
        ("蛇を見ました。", "Hebi o mimashita.", "Melihat ular."),
        ("蛇口をひねりました。", "Jaguchi o hinerimashita.", "Memutar keran."),
    ]),
    ("chou13_n1", "澄", ["チョウ"], ["す-む", "す-ます"], ["jernih", "clear"], 15, "水", [
        ("澄む", "sumu", "menjadi jernih"),
        ("清澄", "seichou", "jernih"),
        ("上澄み", "uwazumi", "cairan bening di atas"),
    ], [
        ("空気が澄んでいます。", "Kuuki ga sunde imasu.", "Udaranya jernih."),
        ("清澄な水です。", "Seichou na mizu desu.", "Ini air yang jernih."),
    ]),
    ("hou8_n1", "縫", ["ホウ"], ["ぬ-う"], ["menjahit", "sew"], 16, "糸", [
        ("縫う", "nuu", "menjahit"),
        ("裁縫", "saihou", "menjahit"),
        ("縫合", "hougou", "penjahitan luka"),
    ], [
        ("服を縫いました。", "Fuku o nuimashita.", "Menjahit baju."),
        ("傷口を縫合しました。", "Kizuguchi o hougou shimashita.", "Menjahit luka."),
    ]),
    ("sou15_n1", "僧", ["ソウ"], [], ["biksu", "monk"], 13, "人", [
        ("僧侶", "souryo", "biksu"),
        ("僧", "sou", "biksu"),
        ("高僧", "kousou", "biksu agung"),
    ], [
        ("僧侶にお布施をしました。", "Souryo ni ofuse o shimashita.", "Memberikan persembahan kepada biksu."),
        ("高僧の教えです。", "Kousou no oshie desu.", "Ini ajaran biksu agung."),
    ]),
    ("chou14_n1", "眺", ["チョウ"], ["なが-める"], ["memandang", "gaze", "view"], 11, "目", [
        ("眺める", "nagameru", "memandang"),
        ("眺望", "choubou", "pemandangan"),
        ("眺め", "nagame", "pemandangan"),
    ], [
        ("景色を眺めました。", "Keshiki o nagamemashita.", "Memandang pemandangan."),
        ("眺望が素晴らしいです。", "Choubou ga subarashii desu.", "Pemandangannya luar biasa."),
    ]),
    ("tou16_n1", "唐", ["トウ"], ["から"], ["Dinasti Tang", "Tiongkok", "Tang Dynasty", "China"], 10, "口", [
        ("唐辛子", "tougarashi", "cabai"),
        ("唐突", "toutotsu", "tiba-tiba"),
        ("遣唐使", "kentoushi", "utusan ke Dinasti Tang"),
    ], [
        ("唐辛子は辛いです。", "Tougarashi wa karai desu.", "Cabai itu pedas."),
        ("唐突な質問です。", "Toutotsu na shitsumon desu.", "Ini pertanyaan yang tiba-tiba."),
    ]),
    ("kou27_n1", "亘", ["コウ"], ["わた-る"], ["membentang (nama)", "span", "extend"], 6, "二", [
        ("亘る", "wataru", "membentang/meliputi"),
        ("亘理", "Watari", "nama tempat"),
        ("亘一", "Kouichi", "contoh nama pria"),
    ], [
        ("全国に亘る問題です。", "Zenkoku ni wataru mondai desu.", "Ini masalah yang meliputi seluruh negeri."),
        ("亘理町に住んでいます。", "Watari-machi ni sunde imasu.", "Tinggal di kota Watari."),
    ]),
    ("go4_n1", "呉", ["ゴ"], [], ["memberi", "Wu (Tiongkok kuno)", "give"], 7, "口", [
        ("呉服", "gofuku", "kain kimono"),
        ("呉れる", "kureru", "memberi (padaku)"),
        ("呉市", "Kure-shi", "nama kota"),
    ], [
        ("呉服屋に行きました。", "Gofukuya ni ikimashita.", "Pergi ke toko kimono."),
        ("呉市は広島県にあります。", "Kure-shi wa Hiroshima-ken ni arimasu.", "Kota Kure ada di Prefektur Hiroshima."),
    ]),
    ("bon2_n1", "凡", ["ボン"], ["およ-そ"], ["biasa", "ordinary", "all"], 3, "几", [
        ("平凡", "heibon", "biasa saja"),
        ("凡人", "bonjin", "orang biasa"),
        ("凡例", "hanrei", "panduan/legenda"),
    ], [
        ("平凡な生活です。", "Heibon na seikatsu desu.", "Ini kehidupan yang biasa saja."),
        ("凡人には無理です。", "Bonjin ni wa muri desu.", "Bagi orang biasa itu mustahil."),
    ]),
    ("kei12_n1", "憩", ["ケイ"], ["いこ-い", "いこ-う"], ["beristirahat", "rest"], 16, "心", [
        ("休憩", "kyuukei", "istirahat"),
        ("憩い", "ikoi", "kenyamanan/istirahat"),
        ("憩う", "ikou", "beristirahat"),
    ], [
        ("休憩しましょう。", "Kyuukei shimashou.", "Mari kita istirahat."),
        ("憩いの場です。", "Ikoi no ba desu.", "Ini tempat untuk beristirahat."),
    ]),
    ("tei13_n1", "鄭", ["テイ"], [], ["marga Zheng", "Zheng"], 15, "邑", [
        ("鄭", "Tei", "marga Zheng"),
        ("鄭国", "Teikoku", "Negara Zheng zaman Tiongkok kuno"),
        ("鄭重", "teichou", "sopan dan hati-hati"),
    ], [
        ("鄭という姓の人です。", "Tei to iu sei no hito desu.", "Orang dengan marga Zheng."),
        ("鄭重にお断りします。", "Teichou ni okotowari shimasu.", "Menolak dengan sopan."),
    ]),
    ("ro4_n1", "芦", ["ロ"], ["あし"], ["alang-alang", "reed"], 7, "艸", [
        ("芦", "ashi", "tanaman alang-alang"),
        ("芦屋", "Ashiya", "nama kota"),
        ("芦ノ湖", "Ashinoko", "nama danau"),
    ], [
        ("芦が生えています。", "Ashi ga haete imasu.", "Alang-alang tumbuh."),
        ("芦ノ湖に行きました。", "Ashinoko ni ikimashita.", "Pergi ke Danau Ashi."),
    ]),
    ("ryuu4_n1", "龍", ["リュウ"], ["たつ"], ["naga (bentuk tradisional)", "dragon"], 16, "龍", [
        ("龍", "ryuu", "naga (bentuk tradisional)"),
        ("龍神", "ryuujin", "dewa naga"),
        ("龍馬", "Ryouma", "contoh nama pria"),
    ], [
        ("龍神様にお参りしました。", "Ryuujin-sama ni omairi shimashita.", "Berdoa kepada dewa naga."),
        ("坂本龍馬は有名な武士です。", "Sakamoto Ryouma wa yuumei na bushi desu.", "Sakamoto Ryoma adalah samurai terkenal."),
    ]),
    ("en7_n1", "媛", ["エン"], ["ひめ"], ["wanita cantik", "beautiful woman"], 12, "女", [
        ("愛媛", "Ehime", "nama prefektur"),
        ("才媛", "saien", "wanita berbakat"),
        ("媛", "hime", "wanita cantik (arkais)"),
    ], [
        ("愛媛県に行きました。", "Ehime-ken ni ikimashita.", "Pergi ke Prefektur Ehime."),
        ("才媛と呼ばれています。", "Saien to yobarete imasu.", "Disebut sebagai wanita berbakat."),
    ]),
    ("kou28_n1", "溝", ["コウ"], ["みぞ"], ["parit", "ditch", "gap"], 13, "水", [
        ("溝", "mizo", "parit/selokan"),
        ("排水溝", "haisuikou", "saluran pembuangan"),
        ("意見の溝", "iken no mizo", "kesenjangan pendapat"),
    ], [
        ("溝に落ちました。", "Mizo ni ochimashita.", "Jatuh ke parit."),
        ("意見の溝が深まりました。", "Iken no mizo ga fukamarimashita.", "Kesenjangan pendapat semakin dalam."),
    ]),
    ("kyou9_n1", "恭", ["キョウ"], ["うやうや-しい"], ["hormat", "respectful"], 10, "心", [
        ("恭しい", "uyauyashii", "sangat hormat"),
        ("恭賀新年", "kyouga shinnen", "selamat tahun baru (formal)"),
        ("恭順", "kyoujun", "tunduk hormat"),
    ], [
        ("恭しく挨拶しました。", "Uyauyashiku aisatsu shimashita.", "Memberi salam dengan sangat hormat."),
        ("恭賀新年と書きました。", "Kyouga shinnen to kakimashita.", "Menulis \"selamat tahun baru\"."),
    ]),
    ("karu_n1", "刈", [], ["か-る"], ["memotong rumput/rambut", "mow", "cut"], 4, "刀", [
        ("刈る", "karu", "memotong"),
        ("芝刈り", "shibakari", "memotong rumput"),
        ("刈り取る", "karitoru", "memanen/memotong"),
    ], [
        ("髪を刈りました。", "Kami o karimashita.", "Memotong rambut."),
        ("稲を刈り取りました。", "Ine o karitorimashita.", "Memanen padi."),
    ]),
    ("sui7_n1", "睡", ["スイ"], [], ["tidur", "sleep"], 13, "目", [
        ("睡眠", "suimin", "tidur"),
        ("熟睡", "jukusui", "tidur nyenyak"),
        ("睡魔", "suima", "rasa kantuk"),
    ], [
        ("睡眠不足です。", "Suimin busoku desu.", "Kurang tidur."),
        ("熟睡しました。", "Jukusui shimashita.", "Tidur nyenyak."),
    ]),
    ("saku3_n1", "錯", ["サク"], [], ["bercampur", "keliru", "mixed", "confuse"], 16, "金", [
        ("錯覚", "sakkaku", "ilusi/salah persepsi"),
        ("錯誤", "sakugo", "kesalahan"),
        ("交錯", "kousaku", "saling silang"),
    ], [
        ("錯覚を起こしました。", "Sakkaku o okoshimashita.", "Mengalami ilusi."),
        ("試行錯誤しています。", "Shikou sakugo shite imasu.", "Sedang coba-coba."),
    ]),
    ("haku5_n1", "伯", ["ハク"], [], ["paman tertua", "gelar bangsawan", "elder", "count"], 7, "人", [
        ("伯父", "oji", "paman (kakak ayah/ibu)"),
        ("伯母", "oba", "bibi (kakak ayah/ibu)"),
        ("画伯", "gahaku", "maestro lukisan"),
    ], [
        ("伯父に会いました。", "Oji ni aimashita.", "Bertemu paman."),
        ("画伯の作品です。", "Gahaku no sakuhin desu.", "Ini karya maestro lukisan."),
    ]),
    ("sasa_n1", "笹", [], ["ささ"], ["rumput bambu", "bamboo grass"], 11, "竹", [
        ("笹", "sasa", "rumput bambu"),
        ("笹の葉", "sasa no ha", "daun bambu"),
        ("笹寿司", "sasazushi", "sushi daun bambu"),
    ], [
        ("笹の葉で包みました。", "Sasa no ha de tsutsumimashita.", "Dibungkus dengan daun bambu."),
        ("笹寿司を食べました。", "Sasazushi o tabemashita.", "Makan sushi daun bambu."),
    ]),
    ("koku3_n1", "穀", ["コク"], [], ["biji-bijian", "grain"], 14, "禾", [
        ("穀物", "kokumotsu", "biji-bijian"),
        ("雑穀", "zakkoku", "biji-bijian campuran"),
        ("穀倉", "kokusou", "lumbung padi"),
    ], [
        ("穀物を輸入しています。", "Kokumotsu o yunyuu shite imasu.", "Mengimpor biji-bijian."),
        ("雑穀米です。", "Zakkokumai desu.", "Ini nasi biji-bijian campuran."),
    ]),
    ("kaki2_n1", "柿", ["シ"], ["かき"], ["buah kesemek", "persimmon"], 9, "木", [
        ("柿", "kaki", "buah kesemek"),
        ("干し柿", "hoshigaki", "kesemek kering"),
        ("柿の種", "kaki no tane", "camilan kaki no tane"),
    ], [
        ("柿を食べました。", "Kaki o tabemashita.", "Makan buah kesemek."),
        ("干し柿を作りました。", "Hoshigaki o tsukurimashita.", "Membuat kesemek kering."),
    ]),
    ("ryou5_n1", "陵", ["リョウ"], ["みささぎ"], ["makam kerajaan", "bukit", "mausoleum", "hill"], 11, "阜", [
        ("陵", "misasagi", "makam kaisar"),
        ("丘陵", "kyuuryou", "perbukitan"),
        ("御陵", "goryou", "makam kaisar (hormat)"),
    ], [
        ("天皇陵を訪れました。", "Tennou ryou o otozuremashita.", "Mengunjungi makam kaisar."),
        ("御陵の前で祈りました。", "Goryou no mae de inorimashita.", "Berdoa di depan makam kaisar."),
    ]),
    ("mu2_n1", "霧", ["ム"], ["きり"], ["kabut", "fog"], 19, "雨", [
        ("霧", "kiri", "kabut"),
        ("濃霧", "noumu", "kabut tebal"),
        ("霧雨", "kirisame", "gerimis kabut"),
    ], [
        ("霧が出ています。", "Kiri ga dete imasu.", "Ada kabut."),
        ("濃霧注意報です。", "Noumu chuuihou desu.", "Ini peringatan kabut tebal."),
    ]),
    ("kon3_n1", "魂", ["コン"], ["たましい"], ["jiwa", "soul"], 14, "鬼", [
        ("魂", "tamashii", "jiwa"),
        ("魂胆", "kontan", "maksud tersembunyi"),
        ("商魂", "shoukon", "semangat berdagang"),
    ], [
        ("魂を込めました。", "Tamashii o komemashita.", "Mencurahkan jiwa."),
        ("商魂たくましいです。", "Shoukon takumashii desu.", "Semangat berdagangnya kuat."),
    ]),
    ("hei3_n1", "弊", ["ヘイ"], [], ["keburukan", "abuse", "detriment"], 15, "廾", [
        ("弊害", "heigai", "dampak buruk"),
        ("弊社", "heisha", "perusahaan kami (merendah)"),
        ("疲弊", "hihei", "kelelahan/keletihan"),
    ], [
        ("弊害があります。", "Heigai ga arimasu.", "Ada dampak buruk."),
        ("弊社にお越しください。", "Heisha ni okoshi kudasai.", "Silakan datang ke perusahaan kami."),
    ]),
    ("kushiro_n1", "釧", [], ["くしろ"], ["gelang tangan (nama tempat)", "bracelet"], 11, "金", [
        ("釧路", "Kushiro", "nama kota"),
        ("釧", "kushiro", "gelang tangan kuno"),
        ("釧路湿原", "Kushiro shitsugen", "rawa Kushiro"),
    ], [
        ("釧路市に住んでいます。", "Kushiro-shi ni sunde imasu.", "Tinggal di kota Kushiro."),
        ("釧路湿原を訪れました。", "Kushiro shitsugen o otozuremashita.", "Mengunjungi rawa Kushiro."),
    ]),
    ("hi6_n1", "妃", ["ヒ"], [], ["permaisuri", "istri pangeran", "princess", "consort"], 6, "女", [
        ("妃殿下", "hidenka", "Yang Mulia Putri"),
        ("王妃", "ouhi", "permaisuri raja"),
        ("皇太子妃", "koutaishihi", "istri putra mahkota"),
    ], [
        ("妃殿下がいらっしゃいました。", "Hidenka ga irasshaimashita.", "Yang Mulia Putri datang."),
        ("王妃の物語です。", "Ouhi no monogatari desu.", "Ini kisah permaisuri."),
    ]),
    ("haku6_n1", "舶", ["ハク"], [], ["kapal laut", "ocean-going ship"], 11, "舟", [
        ("船舶", "senpaku", "kapal laut"),
        ("舶来品", "hakuraihin", "barang impor"),
        ("舶載", "hakusai", "dimuat kapal"),
    ], [
        ("船舶が入港しました。", "Senpaku ga nyuukou shimashita.", "Kapal laut memasuki pelabuhan."),
        ("舶来品を買いました。", "Hakuraihin o kaimashita.", "Membeli barang impor."),
    ]),
    ("ga5_n1", "餓", ["ガ"], [], ["kelaparan", "starve"], 15, "食", [
        ("餓死", "gashi", "mati kelaparan"),
        ("餓鬼", "gaki", "hantu kelaparan/anak nakal"),
        ("飢餓", "kiga", "kelaparan"),
    ], [
        ("餓死しました。", "Gashi shimashita.", "Mati kelaparan."),
        ("餓鬼のような子供です。", "Gaki no you na kodomo desu.", "Anak yang seperti hantu kelaparan/nakal."),
    ]),
    ("jin5_n1", "腎", ["ジン"], [], ["ginjal", "kidney"], 13, "肉", [
        ("腎臓", "jinzou", "ginjal"),
        ("腎不全", "jinfuzen", "gagal ginjal"),
        ("副腎", "fukujin", "kelenjar adrenal"),
    ], [
        ("腎臓が悪いです。", "Jinzou ga warui desu.", "Ginjalnya bermasalah."),
        ("腎不全と診断されました。", "Jinfuzen to shindan saremashita.", "Didiagnosis gagal ginjal."),
    ]),
    ("kyuu8_n1", "窮", ["キュウ"], ["きわ-める", "きわ-まる"], ["kesulitan", "distress", "exhaust"], 15, "穴", [
        ("窮地", "kyuuchi", "situasi terjepit"),
        ("困窮", "konkyuu", "kemiskinan/kesulitan"),
        ("窮屈", "kyuukutsu", "sempit/kaku"),
    ], [
        ("窮地に立たされました。", "Kyuuchi ni tatasaremashita.", "Terjebak dalam situasi sulit."),
        ("困窮しています。", "Konkyuu shite imasu.", "Mengalami kesulitan."),
    ]),
    ("shou26_n1", "掌", ["ショウ"], ["たなごころ"], ["telapak tangan", "mengelola", "palm", "manage"], 12, "手", [
        ("掌握", "shouaku", "penguasaan"),
        ("車掌", "shashou", "kondektur"),
        ("合掌", "gasshou", "tangan tercakup untuk berdoa"),
    ], [
        ("車掌さんに聞きました。", "Shashou-san ni kikimashita.", "Bertanya kepada kondektur."),
        ("合掌しました。", "Gasshou shimashita.", "Menangkupkan tangan untuk berdoa."),
    ]),
    ("rei4_n1", "麗", ["レイ"], ["うるわ-しい"], ["indah", "beautiful"], 19, "鹿", [
        ("美麗", "birei", "sangat indah"),
        ("華麗", "karei", "gemerlap/anggun"),
        ("麗しい", "uruwashii", "indah/mengagumkan"),
    ], [
        ("華麗な演技でした。", "Karei na engi deshita.", "Ini penampilan yang gemerlap."),
        ("麗しい景色です。", "Uruwashii keshiki desu.", "Ini pemandangan yang indah."),
    ]),
    ("ryou6_n1", "綾", ["リョウ"], ["あや"], ["kain bermotif", "pola", "twill weave", "pattern"], 14, "糸", [
        ("綾", "aya", "pola/motif"),
        ("綾織り", "ayaori", "tenunan kepar"),
        ("綾子", "Ayako", "contoh nama wanita"),
    ], [
        ("綾織りの生地です。", "Ayaori no kiji desu.", "Ini kain tenunan kepar."),
        ("綾子さんに会いました。", "Ayako-san ni aimashita.", "Bertemu dengan Ayako."),
    ]),
    ("shuu9_n1", "臭", ["シュウ"], ["くさ-い", "にお-う"], ["berbau", "smell", "stink"], 9, "自", [
        ("臭い", "kusai", "bau"),
        ("臭う", "niou", "berbau"),
        ("悪臭", "akushuu", "bau busuk"),
    ], [
        ("臭いにおいがします。", "Kusai nioi ga shimasu.", "Ada bau yang busuk."),
        ("悪臭がひどいです。", "Akushuu ga hidoi desu.", "Bau busuknya parah."),
    ]),
    ("fu5_n1", "釜", [], ["かま"], ["kuali", "panci besar", "cauldron", "pot"], 10, "金", [
        ("釜", "kama", "kuali/panci nasi"),
        ("釜飯", "kamameshi", "nasi kuali"),
        ("茶釜", "chagama", "ketel teh"),
    ], [
        ("釜飯を食べました。", "Kamameshi o tabemashita.", "Makan nasi kuali."),
        ("茶釜でお湯を沸かしました。", "Chagama de oyu o wakashimashita.", "Merebus air dengan ketel teh."),
    ]),
    ("etsu_n1", "悦", ["エツ"], [], ["kegembiraan", "joy"], 10, "心", [
        ("悦楽", "etsuraku", "kesenangan"),
        ("満悦", "man-etsu", "sangat puas"),
        ("喜悦", "kietsu", "kegembiraan besar"),
    ], [
        ("満悦の表情です。", "Man-etsu no hyoujou desu.", "Ini ekspresi yang sangat puas."),
        ("喜悦に浸りました。", "Kietsu ni hitarimashita.", "Larut dalam kegembiraan."),
    ]),
    ("ha3_n1", "刃", ["ジン"], ["は"], ["mata pisau", "blade"], 3, "刀", [
        ("刃", "ha", "mata pisau"),
        ("刃物", "hamono", "alat tajam/pisau"),
        ("両刃", "ryouba", "bermata dua"),
    ], [
        ("刃物を扱う時は注意してください。", "Hamono o atsukau toki wa chuui shite kudasai.", "Hati-hati saat menggunakan benda tajam."),
        ("両刃の剣です。", "Ryouba no ken desu.", "Ini pedang bermata dua."),
    ]),
    ("baku2_n1", "縛", ["バク"], ["しば-る"], ["mengikat", "bind", "tie"], 16, "糸", [
        ("縛る", "shibaru", "mengikat"),
        ("束縛", "sokubaku", "pengekangan"),
        ("呪縛", "jubaku", "mantra/keterikatan psikologis"),
    ], [
        ("紐で縛りました。", "Himo de shibarimashita.", "Mengikat dengan tali."),
        ("束縛されたくないです。", "Sokubaku saretakunai desu.", "Tidak ingin dikekang."),
    ]),
    ("reki_n1", "暦", ["レキ"], ["こよみ"], ["kalender", "calendar"], 14, "日", [
        ("暦", "koyomi", "kalender"),
        ("西暦", "seireki", "kalender Masehi"),
        ("旧暦", "kyuureki", "kalender lunar lama"),
    ], [
        ("暦を見ました。", "Koyomi o mimashita.", "Melihat kalender."),
        ("西暦2024年です。", "Seireki nisen nijuuyon-nen desu.", "Ini tahun 2024 Masehi."),
    ]),
    ("gi6_n1", "宜", ["ギ"], [], ["sesuai", "appropriate", "suitable"], 8, "宀", [
        ("宜しく", "yoroshiku", "mohon bantuannya"),
        ("便宜", "bengi", "kenyamanan/kemudahan"),
        ("適宜", "tekigi", "sesuai kebutuhan"),
    ], [
        ("どうぞ宜しくお願いします。", "Douzo yoroshiku onegaishimasu.", "Mohon bantuannya."),
        ("便宜を図りました。", "Bengi o hakarimashita.", "Memberikan kemudahan."),
    ]),
    ("mou3_n1", "盲", ["モウ"], [], ["buta", "blind"], 8, "目", [
        ("盲目", "moumoku", "buta"),
        ("盲点", "mouten", "titik buta"),
        ("色盲", "shikimou", "buta warna"),
    ], [
        ("盲目の音楽家です。", "Moumoku no ongakuka desu.", "Ini musisi yang buta."),
        ("盲点を突かれました。", "Mouten o tsukaremashita.", "Titik butanya tersentuh."),
    ]),
    ("sui8_n1", "粋", ["スイ"], ["いき"], ["keren", "inti", "stylish", "essence"], 10, "米", [
        ("粋な", "iki na", "keren/bergaya"),
        ("純粋", "junsui", "murni"),
        ("抜粋", "bassui", "kutipan"),
    ], [
        ("粋な計らいです。", "Iki na hakarai desu.", "Ini tindakan yang keren."),
        ("純粋な気持ちです。", "Junsui na kimochi desu.", "Ini perasaan yang murni."),
    ]),
    ("joku_n1", "辱", ["ジョク"], ["はずかし-める"], ["mempermalukan", "disgrace"], 10, "辰", [
        ("屈辱", "kutsujoku", "penghinaan"),
        ("侮辱", "bujoku", "hinaan"),
        ("恥辱", "chijoku", "aib/rasa malu"),
    ], [
        ("屈辱を受けました。", "Kutsujoku o ukemashita.", "Menerima penghinaan."),
        ("侮辱されました。", "Bujoku saremashita.", "Dihina."),
    ]),
    ("ki20_n1", "毅", ["キ"], [], ["teguh (nama)", "resolute"], 15, "殳", [
        ("毅然", "kizen", "tegas/teguh"),
        ("剛毅", "gouki", "teguh dan berani"),
        ("毅一", "Kiichi", "contoh nama pria"),
    ], [
        ("毅然とした態度です。", "Kizen to shita taido desu.", "Ini sikap yang tegas."),
        ("剛毅な性格です。", "Gouki na seikaku desu.", "Kepribadian yang teguh dan berani."),
    ]),
    ("katsu4_n1", "轄", ["カツ"], [], ["yurisdiksi", "control", "jurisdiction"], 17, "車", [
        ("管轄", "kankatsu", "yurisdiksi"),
        ("直轄", "chokkatsu", "di bawah kendali langsung"),
        ("統轄", "toukatsu", "pengawasan menyeluruh"),
    ], [
        ("管轄区域です。", "Kankatsu kuiki desu.", "Ini wilayah yurisdiksi."),
        ("直轄地です。", "Chokkatsuchi desu.", "Ini wilayah di bawah kendali langsung."),
    ]),
    ("en8_n1", "猿", ["エン"], ["さる"], ["monyet", "monkey"], 13, "犬", [
        ("猿", "saru", "monyet"),
        ("猿真似", "sarumane", "tiru membabi buta"),
        ("類人猿", "ruijin-en", "kera besar"),
    ], [
        ("猿を見ました。", "Saru o mimashita.", "Melihat monyet."),
        ("猿真似はやめてください。", "Sarumane wa yamete kudasai.", "Jangan meniru membabi buta."),
    ]),
    ("gen5_n1", "弦", ["ゲン"], ["つる"], ["senar", "tali busur", "string", "chord"], 8, "弓", [
        ("弦楽器", "gengakki", "alat musik gesek"),
        ("上弦", "jougen", "bulan sabit awal"),
        ("弦", "tsuru", "tali busur"),
    ], [
        ("弦楽器を演奏しました。", "Gengakki o ensou shimashita.", "Memainkan alat musik gesek."),
        ("上弦の月です。", "Jougen no tsuki desu.", "Ini bulan sabit awal."),
    ]),
    ("shima2_n1", "嶌", [], ["しま"], ["pulau (variant langka)", "island"], 14, "山", [
        ("嶌", "shima", "pulau (variant langka dari 島/嶋)"),
        ("嶌田", "Shimada", "contoh nama keluarga"),
        ("異体字", "itaiji", "karakter varian"),
    ], [
        ("嶌田さんという名字は珍しいです。", "Shimada-san to iu myouji wa mezurashii desu.", "Nama keluarga \"Shimada\" (dengan kanji ini) jarang ditemui."),
        ("これは島の異体字です。", "Kore wa shima no itaiji desu.", "Ini adalah varian karakter dari \"shima\"."),
    ]),
    ("jin6_n1", "稔", ["ジン"], ["みの-る"], ["berbuah (nama)", "ripen"], 13, "禾", [
        ("稔る", "minoru", "berbuah/matang"),
        ("稔", "Minoru", "contoh nama pria"),
        ("豊稔", "hounen", "panen melimpah"),
    ], [
        ("稲が稔りました。", "Ine ga minorimashita.", "Padi berbuah."),
        ("稔さんに会いました。", "Minoru-san ni aimashita.", "Bertemu dengan Minoru."),
    ]),
    ("chitsu2_n1", "窒", ["チツ"], [], ["mati lemas", "nitrogen", "suffocate"], 11, "穴", [
        ("窒息", "chissoku", "mati lemas"),
        ("窒素", "chisso", "nitrogen"),
        ("窒塞", "chissoku", "penyumbatan"),
    ], [
        ("窒息しそうでした。", "Chissoku shisou deshita.", "Hampir mati lemas."),
        ("窒素ガスです。", "Chisso gasu desu.", "Ini gas nitrogen."),
    ]),
    ("sui9_n1", "炊", ["スイ"], ["た-く"], ["menanak nasi", "cook rice"], 8, "火", [
        ("炊く", "taku", "menanak nasi"),
        ("炊飯器", "suihanki", "rice cooker"),
        ("自炊", "jisui", "memasak sendiri"),
    ], [
        ("ご飯を炊きました。", "Gohan o takimashita.", "Menanak nasi."),
        ("炊飯器を使っています。", "Suihanki o tsukatte imasu.", "Menggunakan rice cooker."),
    ]),
    ("kou29_n1", "洪", ["コウ"], [], ["banjir besar", "flood", "vast"], 9, "水", [
        ("洪水", "kouzui", "banjir"),
        ("洪積世", "koushakusei", "zaman Pleistosen"),
        ("洪範", "kouhan", "aturan besar"),
    ], [
        ("洪水が発生しました。", "Kouzui ga hassei shimashita.", "Banjir terjadi."),
        ("洪積世の地層です。", "Koushakusei no chisou desu.", "Ini lapisan tanah zaman Pleistosen."),
    ]),
    ("setsu2_n1", "摂", ["セツ"], [], ["menyerap", "mewakili", "absorb", "act for"], 13, "手", [
        ("摂取", "sesshu", "penyerapan/konsumsi"),
        ("摂政", "sesshou", "wali/bupati"),
        ("摂氏", "sesshi", "Celsius"),
    ], [
        ("栄養を摂取しました。", "Eiyou o sesshu shimashita.", "Mengonsumsi nutrisi."),
        ("摂氏30度です。", "Sesshi sanjuu-do desu.", "Ini 30 derajat Celsius."),
    ]),
    ("hou9_n1", "飽", ["ホウ"], ["あ-きる", "あ-かす"], ["bosan", "satiate", "tired of"], 13, "食", [
        ("飽きる", "akiru", "bosan"),
        ("飽和", "houwa", "kejenuhan"),
        ("食べ飽きる", "tabeakiru", "bosan makan"),
    ], [
        ("もう飽きました。", "Mou akimashita.", "Sudah bosan."),
        ("飽和状態です。", "Houwa joutai desu.", "Ini keadaan jenuh."),
    ]),
    ("kan26_n1", "函", ["カン"], [], ["kotak", "box", "case"], 8, "凵", [
        ("函館", "Hakodate", "nama kota"),
        ("投函", "toukan", "memasukkan surat ke kotak pos"),
        ("石函", "sekikan", "kotak batu"),
    ], [
        ("函館に旅行しました。", "Hakodate ni ryokou shimashita.", "Berlibur ke Hakodate."),
        ("手紙を投函しました。", "Tegami o toukan shimashita.", "Memasukkan surat ke kotak pos."),
    ]),
    ("jou8_n1", "冗", ["ジョウ"], [], ["berlebihan", "redundant"], 4, "冖", [
        ("冗談", "joudan", "lelucon"),
        ("冗長", "jouchou", "bertele-tele"),
        ("冗費", "jouhi", "pengeluaran sia-sia"),
    ], [
        ("冗談を言いました。", "Joudan o iimashita.", "Membuat lelucon."),
        ("冗長な説明です。", "Jouchou na setsumei desu.", "Ini penjelasan yang bertele-tele."),
    ]),
    ("tou17_n1", "桃", ["トウ"], ["もも"], ["buah persik", "peach"], 10, "木", [
        ("桃", "momo", "buah persik"),
        ("桃色", "momoiro", "warna merah muda"),
        ("桃太郎", "Momotarou", "tokoh cerita rakyat"),
    ], [
        ("桃を食べました。", "Momo o tabemashita.", "Makan buah persik."),
        ("桃太郎の話です。", "Momotarou no hanashi desu.", "Ini cerita Momotaro."),
    ]),
    ("shu4_n1", "狩", ["シュ"], ["か-る", "かり"], ["berburu", "hunt"], 9, "犬", [
        ("狩る", "karu", "berburu"),
        ("狩猟", "shuryou", "perburuan"),
        ("紅葉狩り", "momijigari", "melihat dedaunan musim gugur"),
    ], [
        ("鹿を狩りました。", "Shika o karimashita.", "Berburu rusa."),
        ("紅葉狩りに行きました。", "Momijigari ni ikimashita.", "Pergi melihat dedaunan musim gugur."),
    ]),
    ("shu5_n1", "朱", ["シュ"], [], ["merah tua", "vermilion"], 6, "木", [
        ("朱色", "shuiro", "warna merah tua"),
        ("朱肉", "shuniku", "tinta stempel merah"),
        ("朱印", "shuin", "cap merah/stempel kuil"),
    ], [
        ("朱色の鳥居です。", "Shuiro no torii desu.", "Ini gerbang torii berwarna merah tua."),
        ("朱印をいただきました。", "Shuin o itadakimashita.", "Mendapat cap merah."),
    ]),
    ("ka13_n1", "渦", ["カ"], ["うず"], ["pusaran air", "whirlpool"], 12, "水", [
        ("渦", "uzu", "pusaran"),
        ("渦巻き", "uzumaki", "pusaran/spiral"),
        ("戦渦", "senka", "kekacauan perang"),
    ], [
        ("渦ができました。", "Uzu ga dekimashita.", "Terbentuk pusaran."),
        ("渦巻き模様です。", "Uzumaki moyou desu.", "Ini pola spiral."),
    ]),
    ("shin11_n1", "紳", ["シン"], [], ["pria terhormat", "gentleman"], 11, "糸", [
        ("紳士", "shinshi", "pria terhormat/gentleman"),
        ("紳士的", "shinshiteki", "seperti gentleman"),
        ("紳士服", "shinshifuku", "pakaian pria"),
    ], [
        ("紳士的な人です。", "Shinshiteki na hito desu.", "Dia orang yang seperti gentleman."),
        ("紳士服売り場です。", "Shinshifuku uriba desu.", "Ini bagian pakaian pria."),
    ]),
    ("suu_n1", "枢", ["スウ"], [], ["pusat", "poros", "pivot", "center"], 8, "木", [
        ("中枢", "chuusuu", "pusat"),
        ("枢軸", "suujiku", "poros"),
        ("枢要", "suuyou", "sangat penting"),
    ], [
        ("中枢神経です。", "Chuusuu shinkei desu.", "Ini sistem saraf pusat."),
        ("枢軸国です。", "Suujikukoku desu.", "Ini negara poros."),
    ]),
    ("hi7_n1", "碑", ["ヒ"], [], ["batu prasasti", "monument", "stele"], 14, "石", [
        ("石碑", "sekihi", "batu prasasti"),
        ("記念碑", "kinenhi", "monumen peringatan"),
        ("歌碑", "kahi", "prasasti puisi"),
    ], [
        ("石碑が建てられました。", "Sekihi ga tateraremashita.", "Batu prasasti didirikan."),
        ("記念碑を訪れました。", "Kinenhi o otozuremashita.", "Mengunjungi monumen peringatan."),
    ]),
    ("tan7_n1", "鍛", ["タン"], ["きた-える"], ["menempa", "melatih", "forge", "train"], 17, "金", [
        ("鍛える", "kitaeru", "menempa/melatih"),
        ("鍛冶", "kaji", "pandai besi"),
        ("鍛錬", "tanren", "latihan keras"),
    ], [
        ("体を鍛えました。", "Karada o kitaemashita.", "Melatih tubuh."),
        ("鍛冶屋で働いています。", "Kajiya de hataraite imasu.", "Bekerja di bengkel pandai besi."),
    ]),
    ("tou18_n1", "刀", ["トウ"], ["かたな"], ["pedang Jepang", "sword"], 2, "刀", [
        ("刀", "katana", "pedang Jepang"),
        ("日本刀", "nihontou", "pedang Jepang tradisional"),
        ("短刀", "tantou", "pisau pendek"),
    ], [
        ("刀を持っています。", "Katana o motte imasu.", "Membawa pedang."),
        ("日本刀は美しいです。", "Nihontou wa utsukushii desu.", "Pedang Jepang itu indah."),
    ]),
    ("ko6_n1", "鼓", ["コ"], ["つづみ"], ["gendang", "drum"], 13, "鼓", [
        ("太鼓", "taiko", "gendang besar"),
        ("鼓舞", "kobu", "membangkitkan semangat"),
        ("鼓動", "kodou", "detak jantung"),
    ], [
        ("太鼓を叩きました。", "Taiko o tatakimashita.", "Memukul gendang."),
        ("鼓動が速くなりました。", "Kodou ga hayaku narimashita.", "Detak jantung menjadi cepat."),
    ]),
    ("ra_n1", "裸", ["ラ"], ["はだか"], ["telanjang", "naked"], 13, "衣", [
        ("裸", "hadaka", "telanjang"),
        ("裸足", "hadashi", "kaki telanjang"),
        ("全裸", "zenra", "telanjang bulat"),
    ], [
        ("裸足で歩きました。", "Hadashi de arukimashita.", "Berjalan tanpa alas kaki."),
        ("裸で生まれました。", "Hadaka de umaremashita.", "Lahir tanpa busana."),
    ]),
    ("ou5_n1", "鴨", ["オウ"], ["かも"], ["itik liar", "duck"], 16, "鳥", [
        ("鴨", "kamo", "itik liar"),
        ("鴨南蛮", "kamonanban", "mi soba dengan bebek"),
        ("鴨居", "kamoi", "ambang pintu geser"),
    ], [
        ("鴨が泳いでいます。", "Kamo ga oyoide imasu.", "Itik liar sedang berenang."),
        ("鴨南蛮を食べました。", "Kamonanban o tabemashita.", "Makan soba bebek."),
    ]),
    ("yuu7_n1", "猶", ["ユウ"], ["なお"], ["masih", "seperti", "still", "like"], 12, "犬", [
        ("猶予", "yuuyo", "penundaan/grace period"),
        ("猶太", "Yudaya", "transliterasi Yudea"),
        ("過猶不及", "kayuufukyuu", "terlalu banyak sama buruknya dengan kurang"),
    ], [
        ("猶予期間です。", "Yuuyo kikan desu.", "Ini masa tenggang."),
        ("支払いを猶予してもらいました。", "Shiharai o yuuyo shite moraimashita.", "Diberikan penundaan pembayaran."),
    ]),
    ("kai7_n1", "塊", ["カイ"], ["かたまり"], ["gumpalan", "lump", "mass"], 13, "土", [
        ("塊", "katamari", "gumpalan"),
        ("金塊", "kinkai", "batangan emas"),
        ("血塊", "kekkai", "gumpalan darah"),
    ], [
        ("肉の塊です。", "Niku no katamari desu.", "Ini gumpalan daging."),
        ("金塊を発見しました。", "Kinkai o hakken shimashita.", "Menemukan batangan emas."),
    ]),
    ("sen10_n1", "旋", ["セン"], [], ["berputar", "revolve", "turn"], 11, "方", [
        ("旋回", "senkai", "berputar"),
        ("旋律", "senritsu", "melodi"),
        ("凱旋", "gaisen", "kemenangan pulang"),
    ], [
        ("飛行機が旋回しました。", "Hikouki ga senkai shimashita.", "Pesawat berputar."),
        ("美しい旋律です。", "Utsukushii senritsu desu.", "Ini melodi yang indah."),
    ]),
    ("kyuu9_n1", "弓", ["キュウ"], ["ゆみ"], ["busur panah", "bow"], 3, "弓", [
        ("弓", "yumi", "busur"),
        ("弓道", "kyuudou", "seni panahan Jepang"),
        ("弓矢", "yumiya", "busur dan anak panah"),
    ], [
        ("弓道を習っています。", "Kyuudou o naratte imasu.", "Belajar kyudo."),
        ("弓矢で射ました。", "Yumiya de imashita.", "Memanah dengan busur dan anak panah."),
    ]),
    ("hei4_n1", "幣", ["ヘイ"], [], ["mata uang", "persembahan", "currency", "offering"], 15, "巾", [
        ("貨幣", "kahei", "mata uang"),
        ("紙幣", "shihei", "uang kertas"),
        ("御幣", "gohei", "persembahan kertas Shinto"),
    ], [
        ("貨幣制度です。", "Kahei seido desu.", "Ini sistem mata uang."),
        ("紙幣を数えました。", "Shihei o kazoemashita.", "Menghitung uang kertas."),
    ]),
    ("maku2_n1", "膜", ["マク"], [], ["selaput", "membrane"], 14, "肉", [
        ("膜", "maku", "selaput"),
        ("粘膜", "nenmaku", "selaput lendir"),
        ("網膜", "moumaku", "retina"),
    ], [
        ("膜で覆われています。", "Maku de oowarete imasu.", "Ditutupi oleh selaput."),
        ("網膜剥離です。", "Moumaku hakuri desu.", "Ini ablasi retina."),
    ]),
    ("sen11_n1", "扇", ["セン"], ["おうぎ"], ["kipas", "fan"], 10, "戸", [
        ("扇風機", "senpuuki", "kipas angin"),
        ("扇子", "sensu", "kipas lipat"),
        ("扇", "ougi", "kipas"),
    ], [
        ("扇風機をつけました。", "Senpuuki o tsukemashita.", "Menyalakan kipas angin."),
        ("扇子で扇ぎました。", "Sensu de aogimashita.", "Mengipas dengan kipas lipat."),
    ]),
    ("waki_n1", "脇", [], ["わき"], ["samping", "ketiak", "side", "armpit"], 10, "肉", [
        ("脇", "waki", "samping/ketiak"),
        ("脇役", "wakiyaku", "peran pembantu"),
        ("脇道", "wakimichi", "jalan samping"),
    ], [
        ("脇に置きました。", "Waki ni okimashita.", "Meletakkan di samping."),
        ("脇役として出演しました。", "Wakiyaku toshite shutsuen shimashita.", "Berperan sebagai pemeran pembantu."),
    ]),
    ("chou19_n1", "腸", ["チョウ"], [], ["usus", "intestine"], 13, "肉", [
        ("腸", "chou", "usus"),
        ("大腸", "daichou", "usus besar"),
        ("胃腸", "ichou", "lambung dan usus"),
    ], [
        ("腸の調子が悪いです。", "Chou no choushi ga warui desu.", "Kondisi ususnya buruk."),
        ("胃腸薬を飲みました。", "Ichouyaku o nomimashita.", "Minum obat lambung dan usus."),
    ]),
    ("sou16_n1", "槽", ["ソウ"], [], ["bak", "tangki", "tank", "tub"], 15, "木", [
        ("浴槽", "yokusou", "bak mandi"),
        ("水槽", "suisou", "akuarium"),
        ("貯水槽", "chosuisou", "tangki penampung air"),
    ], [
        ("浴槽にお湯を入れました。", "Yokusou ni oyu o iremashita.", "Mengisi bak mandi dengan air panas."),
        ("水槽で魚を飼っています。", "Suisou de sakana o katte imasu.", "Memelihara ikan di akuarium."),
    ]),
    ("nabe_n1", "鍋", [], ["なべ"], ["panci", "hotpot", "pot"], 17, "金", [
        ("鍋", "nabe", "panci/hidangan hotpot"),
        ("鍋料理", "naberyouri", "masakan hotpot"),
        ("土鍋", "donabe", "panci tanah liat"),
    ], [
        ("鍋を食べました。", "Nabe o tabemashita.", "Makan hotpot."),
        ("土鍋で炊きました。", "Donabe de takimashita.", "Memasak dengan panci tanah liat."),
    ]),
    ("ji3_n1", "慈", ["ジ"], ["いつく-しむ"], ["kasih sayang", "mercy", "compassion"], 13, "心", [
        ("慈悲", "jihi", "belas kasihan"),
        ("慈善", "jizen", "amal"),
        ("慈しむ", "itsukushimu", "menyayangi"),
    ], [
        ("慈悲深い人です。", "Jihibukai hito desu.", "Dia orang yang penuh belas kasihan."),
        ("慈善活動をしています。", "Jizen katsudou o shite imasu.", "Melakukan kegiatan amal."),
    ]),
    ("toi_n1", "樋", [], ["とい", "ひ"], ["talang air", "gutter", "pipe"], 15, "木", [
        ("樋", "toi", "talang air"),
        ("雨樋", "amadoi", "talang air hujan"),
        ("樋口", "Higuchi", "contoh nama keluarga"),
    ], [
        ("雨樋が壊れました。", "Amadoi ga kowaremashita.", "Talang air hujan rusak."),
        ("樋口さんに会いました。", "Higuchi-san ni aimashita.", "Bertemu dengan Higuchi."),
    ]),
    ("you7_n1", "楊", ["ヨウ"], [], ["pohon willow (nama)", "willow"], 13, "木", [
        ("楊枝", "youji", "tusuk gigi"),
        ("楊貴妃", "Youkihi", "Yang Guifei, selir terkenal Tiongkok"),
        ("楊", "You", "marga Yang"),
    ], [
        ("楊枝を使いました。", "Youji o tsukaimashita.", "Menggunakan tusuk gigi."),
        ("楊貴妃は美人として有名です。", "Youkihi wa bijin toshite yuumei desu.", "Yang Guifei terkenal karena kecantikannya."),
    ]),
    ("batsu3_n1", "伐", ["バツ"], [], ["menebang", "menyerang", "cut down", "attack"], 6, "人", [
        ("伐採", "bassai", "penebangan"),
        ("討伐", "toubatsu", "penumpasan"),
        ("征伐", "seibatsu", "penaklukan"),
    ], [
        ("森林伐採です。", "Shinrin bassai desu.", "Ini penebangan hutan."),
        ("討伐隊が出発しました。", "Toubatsutai ga shuppatsu shimashita.", "Pasukan penumpasan berangkat."),
    ]),
    ("shun3_n1", "駿", ["シュン"], [], ["kuda cepat", "swift horse"], 17, "馬", [
        ("駿馬", "shunme", "kuda unggul"),
        ("駿河", "Suruga", "nama daerah lama"),
        ("駿足", "shunsoku", "kaki cepat"),
    ], [
        ("駿馬に乗りました。", "Shunme ni norimashita.", "Menunggangi kuda unggul."),
        ("駿河の国です。", "Suruga no kuni desu.", "Ini negeri Suruga."),
    ]),
    ("tsuke_n1", "漬", [], ["つ-ける", "つ-かる"], ["mengasinkan", "merendam", "pickle", "soak"], 14, "水", [
        ("漬ける", "tsukeru", "merendam/mengasinkan"),
        ("漬物", "tsukemono", "acar Jepang"),
        ("塩漬け", "shiozuke", "diasinkan dengan garam"),
    ], [
        ("野菜を漬けました。", "Yasai o tsukemashita.", "Merendam sayuran."),
        ("漬物を食べました。", "Tsukemono o tabemashita.", "Makan acar Jepang."),
    ]),
    ("kyuu10_n1", "糾", ["キュウ"], [], ["menyelidiki", "investigate", "twist"], 9, "糸", [
        ("糾弾", "kyuudan", "kecaman"),
        ("紛糾", "funkyuu", "kekacauan"),
        ("糾明", "kyuumei", "penyelidikan"),
    ], [
        ("糾弾されました。", "Kyuudan saremashita.", "Dikecam."),
        ("議論が紛糾しました。", "Giron ga funkyuu shimashita.", "Diskusi menjadi kacau."),
    ]),
    ("ryou7_n1", "亮", ["リョウ"], [], ["jernih (nama)", "clear", "bright"], 9, "亠", [
        ("亮", "Ryou", "contoh nama pria"),
        ("亮太", "Ryouta", "contoh nama pria"),
        ("明亮", "meiryou", "terang benderang"),
    ], [
        ("亮さんに会いました。", "Ryou-san ni aimashita.", "Bertemu dengan Ryou."),
        ("亮太という名前です。", "Ryouta to iu namae desu.", "Ini nama Ryouta."),
    ]),
    ("fun5_n1", "墳", ["フン"], [], ["makam gundukan", "tomb", "mound"], 15, "土", [
        ("古墳", "kofun", "makam kuno gundukan"),
        ("墳墓", "funbo", "makam"),
        ("墳丘", "funkyuu", "gundukan makam"),
    ], [
        ("古墳を発掘しました。", "Kofun o hakkutsu shimashita.", "Menggali makam kuno."),
        ("墳墓の地です。", "Funbo no chi desu.", "Ini tanah pemakaman."),
    ]),
    ("hyou6_n1", "坪", ["ヒョウ"], ["つぼ"], ["satuan luas Jepang", "unit of area"], 8, "土", [
        ("坪", "tsubo", "satuan luas ~3.3m²"),
        ("建坪", "tatetsubo", "luas bangunan"),
        ("坪数", "tsubosuu", "jumlah tsubo"),
    ], [
        ("100坪の土地です。", "Hyaku-tsubo no tochi desu.", "Ini tanah seluas 100 tsubo."),
        ("建坪を計算しました。", "Tatetsubo o keisan shimashita.", "Menghitung luas bangunan."),
    ]),
    ("kon4_n1", "紺", ["コン"], [], ["biru tua", "dark blue"], 11, "糸", [
        ("紺色", "kon-iro", "warna biru tua"),
        ("紺碧", "konpeki", "biru laut yang dalam"),
        ("濃紺", "noukon", "biru tua pekat"),
    ], [
        ("紺色のスーツです。", "Kon-iro no suutsu desu.", "Ini setelan berwarna biru tua."),
        ("紺碧の海です。", "Konpeki no umi desu.", "Ini laut biru yang dalam."),
    ]),
    ("kou30_n1", "慌", ["コウ"], ["あわ-てる", "あわ-ただしい"], ["panik", "flustered"], 12, "心", [
        ("慌てる", "awateru", "panik"),
        ("慌ただしい", "awatadashii", "terburu-buru"),
        ("恐慌", "kyoukou", "kepanikan besar/depresi ekonomi"),
    ], [
        ("慌てて逃げました。", "Awatete nigemashita.", "Panik dan melarikan diri."),
        ("慌ただしい一日でした。", "Awatadashii ichinichi deshita.", "Ini hari yang terburu-buru."),
    ]),
    ("go5_n1", "娯", ["ゴ"], [], ["hiburan", "amusement", "pleasure"], 10, "女", [
        ("娯楽", "goraku", "hiburan"),
        ("娯楽室", "gorakushitsu", "ruang hiburan"),
        ("娯楽施設", "goraku shisetsu", "fasilitas hiburan"),
    ], [
        ("娯楽施設です。", "Goraku shisetsu desu.", "Ini fasilitas hiburan."),
        ("娯楽が少ないです。", "Goraku ga sukunai desu.", "Hiburannya sedikit."),
    ]),
    ("go6_n1", "吾", ["ゴ"], ["われ", "わ"], ["saya (klasik)", "I", "me"], 7, "口", [
        ("吾輩", "wagahai", "saya (arkais, terkenal dari novel)"),
        ("吾々", "wareware", "kami/kita"),
        ("吾妻", "Azuma", "nama tempat"),
    ], [
        ("吾輩は猫である。", "Wagahai wa neko de aru.", "Aku adalah kucing (judul novel terkenal)."),
        ("吾々の使命です。", "Wareware no shimei desu.", "Ini misi kami."),
    ]),
    ("chin4_n1", "椿", ["チン"], ["つばき"], ["bunga kamelia", "camellia"], 13, "木", [
        ("椿", "tsubaki", "bunga kamelia"),
        ("椿油", "tsubakiabura", "minyak kamelia"),
        ("冬椿", "fuyutsubaki", "kamelia musim dingin"),
    ], [
        ("椿の花が咲きました。", "Tsubaki no hana ga sakimashita.", "Bunga kamelia mekar."),
        ("椿油を使っています。", "Tsubakiabura o tsukatte imasu.", "Menggunakan minyak kamelia."),
    ]),
    ("zetsu_n1", "舌", ["ゼツ"], ["した"], ["lidah", "tongue"], 6, "舌", [
        ("舌", "shita", "lidah"),
        ("舌打ち", "shitauchi", "berdecak"),
        ("毒舌", "dokuzetsu", "lidah beracun/perkataan pedas"),
    ], [
        ("舌を出しました。", "Shita o dashimashita.", "Menjulurkan lidah."),
        ("毒舌家です。", "Dokuzetsuka desu.", "Dia orang yang perkataannya pedas."),
    ]),
    ("ra2_n1", "羅", ["ラ"], [], ["kain tipis", "jaring", "gauze", "net"], 19, "网", [
        ("網羅", "moura", "mencakup semua"),
        ("羅列", "raretsu", "daftar berurutan"),
        ("新羅", "Shiragi", "nama kerajaan kuno Korea"),
    ], [
        ("全項目を網羅しました。", "Zenkoumoku o moura shimashita.", "Mencakup semua item."),
        ("羅列しただけです。", "Raretsu shita dake desu.", "Hanya mendaftarkan saja."),
    ]),
    ("kyou10_n1", "峡", ["キョウ"], [], ["ngarai", "selat", "gorge", "strait"], 9, "山", [
        ("海峡", "kaikyou", "selat"),
        ("峡谷", "kyoukoku", "ngarai"),
        ("地峡", "chikyou", "tanah genting"),
    ], [
        ("海峡を渡りました。", "Kaikyou o watarimashita.", "Menyeberangi selat."),
        ("峡谷を探検しました。", "Kyoukoku o tanken shimashita.", "Menjelajahi ngarai."),
    ]),
    ("hou10_n1", "俸", ["ホウ"], [], ["gaji", "salary"], 10, "人", [
        ("俸給", "houkyuu", "gaji"),
        ("年俸", "nenpou", "gaji tahunan"),
        ("減俸", "genpou", "potongan gaji"),
    ], [
        ("俸給をもらいました。", "Houkyuu o moraimashita.", "Menerima gaji."),
        ("年俸制です。", "Nenpousei desu.", "Ini sistem gaji tahunan."),
    ]),
    ("rin4_n1", "厘", ["リン"], [], ["satuan mata uang lama", "rin"], 9, "厂", [
        ("一分一厘", "ichibu ichirin", "sedikit pun/persis"),
        ("九分九厘", "kubu kurin", "hampir pasti"),
        ("厘毛", "rinmou", "sangat kecil"),
    ], [
        ("九分九厘成功するでしょう。", "Kubu kurin seikou suru deshou.", "Hampir pasti akan berhasil."),
        ("一分一厘違いません。", "Ichibu ichirin chigaimasen.", "Tidak berbeda sedikit pun."),
    ]),
    ("hou11_n1", "峰", ["ホウ"], ["みね"], ["puncak gunung", "peak"], 10, "山", [
        ("峰", "mine", "puncak"),
        ("高峰", "kouhou", "puncak tinggi"),
        ("連峰", "renpou", "rangkaian puncak gunung"),
    ], [
        ("山の峰に登りました。", "Yama no mine ni noborimashita.", "Mendaki puncak gunung."),
        ("連峰が美しいです。", "Renpou ga utsukushii desu.", "Rangkaian puncak gunungnya indah."),
    ]),
    ("kei13_n1", "圭", ["ケイ"], [], ["lempengan giok (nama)", "jade tablet"], 6, "土", [
        ("圭", "Kei", "contoh nama"),
        ("圭角", "keikaku", "sudut tajam (kepribadian keras)"),
        ("圭一", "Keiichi", "contoh nama pria"),
    ], [
        ("圭さんに会いました。", "Kei-san ni aimashita.", "Bertemu dengan Kei."),
        ("圭一という名前です。", "Keiichi to iu namae desu.", "Ini nama Keiichi."),
    ]),
    ("jou9_n1", "醸", ["ジョウ"], ["かも-す"], ["memfermentasi", "brew"], 18, "酉", [
        ("醸造", "jouzou", "fermentasi"),
        ("醸す", "kamosu", "memfermentasi/menimbulkan"),
        ("吟醸酒", "ginjoushu", "sake premium"),
    ], [
        ("醸造所を見学しました。", "Jouzousho o kengaku shimashita.", "Mengunjungi pabrik fermentasi."),
        ("緊張感を醸し出しています。", "Kinchoukan o kamoshidashite imasu.", "Menimbulkan rasa tegang."),
    ]),
    ("ren_n1", "蓮", ["レン"], ["はす"], ["bunga teratai", "lotus"], 13, "艸", [
        ("蓮", "hasu", "bunga teratai"),
        ("蓮の花", "hasu no hana", "bunga teratai"),
        ("蓮根", "renkon", "akar teratai"),
    ], [
        ("蓮の花が咲きました。", "Hasu no hana ga sakimashita.", "Bunga teratai mekar."),
        ("蓮根を食べました。", "Renkon o tabemashita.", "Makan akar teratai."),
    ]),
    ("chou20_n1", "弔", ["チョウ"], ["とむら-う"], ["belasungkawa", "condolence"], 4, "弓", [
        ("弔問", "choumon", "kunjungan belasungkawa"),
        ("弔電", "chouden", "telegram belasungkawa"),
        ("弔辞", "choji", "pidato duka"),
    ], [
        ("弔問に行きました。", "Choumon ni ikimashita.", "Pergi memberikan belasungkawa."),
        ("弔辞を読みました。", "Choji o yomimashita.", "Membacakan pidato duka."),
    ]),
    ("otsu_n1", "乙", ["オツ"], [], ["kedua", "unik", "second", "humorous"], 1, "乙", [
        ("乙", "otsu", "kedua dalam urutan"),
        ("甲乙", "kouotsu", "urutan pertama-kedua"),
        ("乙女", "otome", "gadis muda"),
    ], [
        ("甲乙つけがたいです。", "Kouotsu tsukegatai desu.", "Sulit dibedakan mana yang lebih baik."),
        ("乙女心です。", "Otome gokoro desu.", "Ini perasaan gadis muda."),
    ]),
    ("gu2_n1", "倶", ["グ"], [], ["bersama", "together"], 10, "人", [
        ("倶に", "tomo ni", "bersama"),
        ("倶楽部", "kurabu", "klub"),
        ("不倶戴天", "fugutaiten", "musuh bebuyutan"),
    ], [
        ("倶楽部に入りました。", "Kurabu ni hairimashita.", "Bergabung dengan klub."),
        ("不倶戴天の敵です。", "Fugutaiten no teki desu.", "Ini musuh bebuyutan."),
    ]),
    ("juu7_n1", "汁", ["ジュウ"], ["しる"], ["kuah", "jus", "juice", "soup"], 5, "水", [
        ("汁", "shiru", "kuah"),
        ("味噌汁", "misoshiru", "sup miso"),
        ("果汁", "kajuu", "jus buah"),
    ], [
        ("味噌汁を飲みました。", "Misoshiru o nomimashita.", "Minum sup miso."),
        ("果汁100%です。", "Kajuu hyaku paasento desu.", "Ini jus 100%."),
    ]),
    ("ni2_n1", "尼", ["ニ"], ["あま"], ["biarawati", "nun"], 5, "尸", [
        ("尼", "ama", "biarawati"),
        ("尼僧", "nisou", "biarawati Buddha"),
        ("修道尼", "shuudouni", "biarawati Kristen"),
    ], [
        ("尼になりました。", "Ama ni narimashita.", "Menjadi biarawati."),
        ("尼僧が祈っています。", "Nisou ga inotte imasu.", "Biarawati sedang berdoa."),
    ]),
    ("hen2_n1", "遍", ["ヘン"], [], ["di mana-mana", "kali", "everywhere", "times"], 12, "辵", [
        ("普遍", "fuhen", "universal"),
        ("一遍", "ippen", "satu kali"),
        ("遍歴", "henreki", "pengembaraan"),
    ], [
        ("普遍的な真理です。", "Fuhenteki na shinri desu.", "Ini kebenaran universal."),
        ("遍歴を重ねました。", "Henreki o kasanemashita.", "Menjalani banyak pengembaraan."),
    ]),
    ("sakai_n1", "堺", [], ["さかい"], ["batas (nama kota)", "boundary"], 12, "土", [
        ("堺", "Sakai", "nama kota di Osaka"),
        ("堺市", "Sakai-shi", "Kota Sakai"),
        ("堺筋", "Sakaisuji", "nama jalan di Osaka"),
    ], [
        ("堺市に住んでいます。", "Sakai-shi ni sunde imasu.", "Tinggal di Kota Sakai."),
        ("堺筋を歩きました。", "Sakaisuji o arukimashita.", "Berjalan di jalan Sakaisuji."),
    ]),
    ("kou31_n1", "衡", ["コウ"], [], ["keseimbangan", "balance", "measure"], 16, "行", [
        ("均衡", "kinkou", "keseimbangan"),
        ("平衡", "heikou", "keseimbangan/ekuilibrium"),
        ("度量衡", "doryoukou", "sistem ukuran"),
    ], [
        ("均衡を保っています。", "Kinkou o tamotte imasu.", "Menjaga keseimbangan."),
        ("平衡感覚があります。", "Heikou kankaku ga arimasu.", "Memiliki indera keseimbangan."),
    ]),
    ("hou12_n1", "呆", ["ホウ"], ["あき-れる", "ぼ-ける"], ["tercengang", "pikun", "dumbfounded", "senile"], 7, "口", [
        ("呆れる", "akireru", "tercengang"),
        ("呆然", "bouzen", "terpaku/terkejut"),
        ("阿呆", "ahou", "bodoh"),
    ], [
        ("呆れました。", "Akiremashita.", "Tercengang."),
        ("呆然としています。", "Bouzen to shite imasu.", "Terpaku kaget."),
    ]),
    ("kun2_n1", "薫", ["クン"], ["かお-る"], ["harum", "fragrant"], 16, "艸", [
        ("薫る", "kaoru", "tercium harum"),
        ("薫陶", "kunto", "bimbingan/didikan"),
        ("薫風", "kunpuu", "angin harum musim panas"),
    ], [
        ("花の香りが薫っています。", "Hana no kaori ga kaotte imasu.", "Tercium harum bunga."),
        ("薫陶を受けました。", "Kunto o ukemashita.", "Menerima bimbingan."),
    ]),
    ("ga6_n1", "瓦", ["ガ"], ["かわら"], ["genteng", "roof tile"], 5, "瓦", [
        ("瓦", "kawara", "genteng"),
        ("瓦礫", "gareki", "puing-puing"),
        ("煉瓦", "renga", "batu bata"),
    ], [
        ("瓦屋根です。", "Kawara yane desu.", "Ini atap genteng."),
        ("瓦礫の中から救出されました。", "Gareki no naka kara kyuushutsu saremashita.", "Diselamatkan dari puing-puing."),
    ]),
    ("ryou8_n1", "猟", ["リョウ"], [], ["berburu", "hunting"], 11, "犬", [
        ("狩猟", "shuryou", "perburuan"),
        ("猟師", "ryoushi", "pemburu"),
        ("密猟", "mitsuryou", "perburuan liar"),
    ], [
        ("猟師になりました。", "Ryoushi ni narimashita.", "Menjadi pemburu."),
        ("密猟は禁止されています。", "Mitsuryou wa kinshi sarete imasu.", "Perburuan liar dilarang."),
    ]),
    ("you8_n1", "羊", ["ヨウ"], ["ひつじ"], ["domba", "sheep"], 6, "羊", [
        ("羊", "hitsuji", "domba"),
        ("羊毛", "youmou", "wol"),
        ("山羊", "yagi", "kambing"),
    ], [
        ("羊を育てています。", "Hitsuji o sodatete imasu.", "Memelihara domba."),
        ("羊毛のセーターです。", "Youmou no seetaa desu.", "Ini sweater wol."),
    ]),
    ("kubo_n1", "窪", [], ["くぼ"], ["cekungan", "hollow", "depression"], 11, "穴", [
        ("窪む", "kubomu", "cekung/berlekuk"),
        ("窪地", "kubochi", "tanah cekungan"),
        ("窪み", "kubomi", "lekukan"),
    ], [
        ("地面が窪んでいます。", "Jimen ga kubonde imasu.", "Tanahnya cekung."),
        ("窪地に水が溜まりました。", "Kubochi ni mizu ga tamarimashita.", "Air menggenang di tanah cekungan."),
    ]),
    ("kan27_n1", "款", ["カン"], [], ["pasal", "ketentuan", "article", "section"], 12, "欠", [
        ("定款", "teikan", "anggaran dasar"),
        ("約款", "yakkan", "ketentuan kontrak"),
        ("借款", "shakkan", "pinjaman antarnegara"),
    ], [
        ("定款を作成しました。", "Teikan o sakusei shimashita.", "Membuat anggaran dasar."),
        ("約款を確認してください。", "Yakkan o kakunin shite kudasai.", "Silakan periksa ketentuan kontrak."),
    ]),
    ("etsu2_n1", "閲", ["エツ"], [], ["memeriksa", "inspect", "read"], 15, "門", [
        ("閲覧", "etsuran", "penelusuran/pembacaan"),
        ("検閲", "ken-etsu", "sensor"),
        ("校閲", "kouetsu", "penyuntingan naskah"),
    ], [
        ("検閲されました。", "Ken-etsu saremashita.", "Disensor."),
        ("校閲を担当しています。", "Kouetsu o tantou shite imasu.", "Bertanggung jawab atas penyuntingan naskah."),
    ]),
    ("jaku2_n1", "雀", ["ジャク"], ["すずめ"], ["burung pipit", "sparrow"], 11, "隹", [
        ("雀", "suzume", "burung pipit"),
        ("雀荘", "jansou", "tempat bermain mahjong"),
        ("麻雀", "maajan", "mahjong"),
    ], [
        ("雀が飛んでいます。", "Suzume ga tonde imasu.", "Burung pipit sedang terbang."),
        ("麻雀をしました。", "Maajan o shimashita.", "Bermain mahjong."),
    ]),
    ("tei14_n1", "偵", ["テイ"], [], ["mata-mata", "spy", "detect"], 11, "人", [
        ("偵察", "teisatsu", "pengintaian"),
        ("探偵", "tantei", "detektif"),
        ("密偵", "mittei", "mata-mata rahasia"),
    ], [
        ("偵察に行きました。", "Teisatsu ni ikimashita.", "Pergi mengintai."),
        ("探偵になりたいです。", "Tantei ni naritai desu.", "Ingin menjadi detektif."),
    ]),
    ("katsu5_n1", "喝", ["カツ"], [], ["membentak", "shout", "scold"], 11, "口", [
        ("恐喝", "kyoukatsu", "pemerasan"),
        ("一喝", "ikkatsu", "bentakan keras"),
        ("喝采", "kassai", "tepuk tangan meriah"),
    ], [
        ("恐喝されました。", "Kyoukatsu saremashita.", "Diperas."),
        ("喝采を浴びました。", "Kassai o abimashita.", "Mendapat tepuk tangan meriah."),
    ]),
    ("kan28_n1", "敢", ["カン"], [], ["berani", "dare", "bold"], 12, "攴", [
        ("敢えて", "aete", "dengan sengaja/berani"),
        ("勇敢", "yuukan", "berani"),
        ("果敢", "kakan", "tegas dan berani"),
    ], [
        ("敢えて言います。", "Aete iimasu.", "Dengan sengaja saya katakan."),
        ("勇敢な行動です。", "Yuukan na koudou desu.", "Ini tindakan yang berani."),
    ]),
    ("hatake2_n1", "畠", [], ["はたけ"], ["ladang (variant 畑)", "field"], 11, "田", [
        ("畠", "hatake", "ladang (variant dari 畑)"),
        ("畠山", "Hatakeyama", "contoh nama keluarga"),
        ("畠中", "Hatakenaka", "contoh nama keluarga"),
    ], [
        ("畠山さんに会いました。", "Hatakeyama-san ni aimashita.", "Bertemu dengan Hatakeyama."),
        ("これは畑の異体字です。", "Kore wa hatake no itaiji desu.", "Ini adalah varian karakter dari \"hatake\"."),
    ]),
    ("tai8_n1", "胎", ["タイ"], [], ["kandungan", "womb", "fetus"], 9, "肉", [
        ("胎児", "taiji", "janin"),
        ("母胎", "botai", "rahim ibu"),
        ("胎動", "taidou", "gerakan janin/tanda awal"),
    ], [
        ("胎児が育っています。", "Taiji ga sodatte imasu.", "Janin sedang berkembang."),
        ("変化の胎動を感じます。", "Henka no taidou o kanjimasu.", "Merasakan tanda awal perubahan."),
    ]),
    ("kou32_n1", "酵", ["コウ"], [], ["fermentasi", "enzim", "ferment", "enzyme"], 14, "酉", [
        ("酵素", "kouso", "enzim"),
        ("発酵", "hakkou", "fermentasi"),
        ("酵母", "koubo", "ragi"),
    ], [
        ("酵素を摂取しています。", "Kouso o sesshu shite imasu.", "Mengonsumsi enzim."),
        ("発酵食品です。", "Hakkou shokuhin desu.", "Ini makanan fermentasi."),
    ]),
    ("fun6_n1", "憤", ["フン"], ["いきどお-る"], ["kemarahan", "indignation"], 15, "心", [
        ("憤慨", "fungai", "kemarahan besar"),
        ("憤る", "ikidoru", "marah/geram"),
        ("義憤", "gifun", "kemarahan atas ketidakadilan"),
    ], [
        ("憤慨しています。", "Fungai shite imasu.", "Sangat marah."),
        ("義憤を感じました。", "Gifun o kanjimashita.", "Merasakan kemarahan atas ketidakadilan."),
    ]),
    ("ton2_n1", "豚", ["トン"], ["ぶた"], ["babi", "pig"], 11, "豕", [
        ("豚", "buta", "babi"),
        ("豚肉", "butaniku", "daging babi"),
        ("養豚", "youton", "peternakan babi"),
    ], [
        ("豚肉を食べました。", "Butaniku o tabemashita.", "Makan daging babi."),
        ("養豚場です。", "Youtonjou desu.", "Ini peternakan babi."),
    ]),
    ("sha5_n1", "遮", ["シャ"], ["さえぎ-る"], ["menghalangi", "block", "shield"], 14, "辵", [
        ("遮る", "saegiru", "menghalangi"),
        ("遮断", "shadan", "pemutusan"),
        ("遮光", "shakou", "menghalangi cahaya"),
    ], [
        ("話を遮りました。", "Hanashi o saegirimashita.", "Memotong pembicaraan."),
        ("遮断機が下りました。", "Shadanki ga orimashita.", "Palang perlintasan turun."),
    ]),
    ("hi8_n1", "扉", ["ヒ"], ["とびら"], ["pintu", "door"], 12, "戸", [
        ("扉", "tobira", "pintu"),
        ("門扉", "monpi", "pintu gerbang"),
        ("扉絵", "tobirae", "gambar sampul"),
    ], [
        ("扉を開けました。", "Tobira o akemashita.", "Membuka pintu."),
        ("門扉が閉まっています。", "Monpi ga shimatte imasu.", "Pintu gerbang tertutup."),
    ]),
    ("ryuu5_n1", "硫", ["リュウ"], [], ["belerang", "sulfur"], 12, "石", [
        ("硫黄", "iou", "belerang"),
        ("硫酸", "ryuusan", "asam sulfat"),
        ("硫化水素", "ryuuka suiso", "hidrogen sulfida"),
    ], [
        ("硫黄の匂いがします。", "Iou no nioi ga shimasu.", "Tercium bau belerang."),
        ("硫酸は危険です。", "Ryuusan wa kiken desu.", "Asam sulfat berbahaya."),
    ]),
    ("sha6_n1", "赦", ["シャ"], [], ["pengampunan", "pardon"], 11, "赤", [
        ("容赦", "yousha", "ampun/toleransi"),
        ("恩赦", "onsha", "amnesti"),
        ("赦免", "shamen", "pengampunan"),
    ], [
        ("容赦なく叱られました。", "Yousha naku shikararemashita.", "Dimarahi tanpa ampun."),
        ("恩赦が下されました。", "Onsha ga kudasaremashita.", "Amnesti diberikan."),
    ]),
    ("za_n1", "挫", ["ザ"], [], ["terkilir", "gagal", "sprain", "setback"], 10, "手", [
        ("挫折", "zasetsu", "kegagalan"),
        ("捻挫", "nenza", "keseleo"),
        ("挫傷", "zashou", "memar/luka"),
    ], [
        ("挫折を経験しました。", "Zasetsu o keiken shimashita.", "Mengalami kegagalan."),
        ("足を捻挫しました。", "Ashi o nenza shimashita.", "Kaki terkilir."),
    ]),
    ("setsu3_n1", "窃", ["セツ"], [], ["mencuri", "steal"], 9, "穴", [
        ("窃盗", "settou", "pencurian"),
        ("窃取", "sesshu", "mencuri"),
        ("窃視", "sesshi", "mengintip"),
    ], [
        ("窃盗事件です。", "Settou jiken desu.", "Ini kasus pencurian."),
        ("情報を窃取しました。", "Jouhou o sesshu shimashita.", "Mencuri informasi."),
    ]),
    ("hou13_n1", "泡", ["ホウ"], ["あわ"], ["gelembung", "bubble", "foam"], 8, "水", [
        ("泡", "awa", "busa/gelembung"),
        ("気泡", "kihou", "gelembung udara"),
        ("発泡", "happou", "berbusa/berbuih"),
    ], [
        ("泡が立ちました。", "Awa ga tachimashita.", "Busa terbentuk."),
        ("気泡が入っています。", "Kihou ga haitte imasu.", "Ada gelembung udara di dalamnya."),
    ]),
    ("zui3_n1", "瑞", ["ズイ"], [], ["pertanda baik", "auspicious"], 13, "玉", [
        ("瑞祥", "zuishou", "pertanda baik"),
        ("瑞々しい", "mizumizushii", "segar"),
        ("瑞穂", "Mizuho", "nama tempat/negeri padi"),
    ], [
        ("瑞祥を感じます。", "Zuishou o kanjimasu.", "Merasakan pertanda baik."),
        ("瑞々しい果物です。", "Mizumizushii kudamono desu.", "Ini buah yang segar."),
    ]),
    ("yuu8_n1", "又", ["ユウ"], ["また"], ["lagi", "juga", "again", "also"], 2, "又", [
        ("又は", "mata wa", "atau"),
        ("又聞き", "matagiki", "mendengar dari orang lain"),
        ("又従兄弟", "mataitoko", "sepupu kedua"),
    ], [
        ("電話又はメールで連絡してください。", "Denwa mata wa meeru de renraku shite kudasai.", "Hubungi lewat telepon atau email."),
        ("又聞きの情報です。", "Matagiki no jouhou desu.", "Ini informasi dari orang lain."),
    ]),
    ("gai5_n1", "慨", ["ガイ"], [], ["mengeluh", "lament", "sigh"], 13, "心", [
        ("感慨", "kangai", "perasaan mendalam"),
        ("憤慨", "fungai", "kemarahan besar"),
        ("慨嘆", "gaitan", "keluhan mendalam"),
    ], [
        ("感慨深いです。", "Kangai fukai desu.", "Ini perasaan yang mendalam."),
        ("慨嘆しました。", "Gaitan shimashita.", "Mengeluh dengan mendalam."),
    ]),
    ("bou8_n1", "紡", ["ボウ"], ["つむ-ぐ"], ["memintal", "spin (thread)"], 10, "糸", [
        ("紡ぐ", "tsumugu", "memintal"),
        ("紡績", "bouseki", "pemintalan"),
        ("混紡", "konbou", "campuran serat"),
    ], [
        ("糸を紡ぎました。", "Ito o tsumugimashita.", "Memintal benang."),
        ("紡績工場です。", "Bouseki koujou desu.", "Ini pabrik pemintalan."),
    ]),
    ("kon5_n1", "恨", ["コン"], ["うら-む", "うら-めしい"], ["dendam", "resent", "grudge"], 9, "心", [
        ("恨む", "uramu", "mendendam"),
        ("恨み", "urami", "dendam"),
        ("遺恨", "ikon", "dendam lama"),
    ], [
        ("恨んでいます。", "Urande imasu.", "Mendendam."),
        ("遺恨を残しました。", "Ikon o nokoshimashita.", "Meninggalkan dendam lama."),
    ]),
    ("bou9_n1", "肪", ["ボウ"], [], ["lemak", "fat"], 8, "肉", [
        ("脂肪", "shibou", "lemak"),
        ("脂肪分", "shiboubun", "kadar lemak"),
        ("皮下脂肪", "hika shibou", "lemak di bawah kulit"),
    ], [
        ("脂肪が多いです。", "Shibou ga ooi desu.", "Kadar lemaknya tinggi."),
        ("皮下脂肪を減らしたいです。", "Hika shibou o herashitai desu.", "Ingin mengurangi lemak di bawah kulit."),
    ]),
    ("fu6_n1", "扶", ["フ"], [], ["membantu", "support", "help"], 7, "手", [
        ("扶養", "fuyou", "tanggungan"),
        ("扶助", "fujo", "bantuan"),
        ("扶育", "fuiku", "mengasuh"),
    ], [
        ("扶養家族です。", "Fuyou kazoku desu.", "Ini keluarga yang ditanggung."),
        ("相互扶助です。", "Sougo fujo desu.", "Ini saling membantu."),
    ]),
    ("gi7_n1", "戯", ["ギ"], ["たわむ-れる"], ["bermain-main", "play", "joke"], 15, "戈", [
        ("戯れる", "tawamureru", "bermain-main"),
        ("遊戯", "yuugi", "permainan"),
        ("戯曲", "gikyoku", "naskah drama"),
    ], [
        ("戯れに言いました。", "Tawamure ni iimashita.", "Mengatakannya sebagai gurauan."),
        ("戯曲を書きました。", "Gikyoku o kakimashita.", "Menulis naskah drama."),
    ]),
    ("go7_n1", "伍", ["ゴ"], [], ["kelompok lima", "rank of five", "comrades"], 6, "人", [
        ("落伍", "rakugo", "tertinggal dari kelompok"),
        ("伍長", "gochou", "kopral"),
        ("隊伍", "taigo", "barisan"),
    ], [
        ("落伍しました。", "Rakugo shimashita.", "Tertinggal dari kelompok."),
        ("伍長になりました。", "Gochou ni narimashita.", "Menjadi kopral."),
    ]),
    ("ki21_n1", "忌", ["キ"], ["い-む", "い-まわしい"], ["berkabung", "pantang", "mourning", "taboo"], 7, "心", [
        ("忌み嫌う", "imikirau", "sangat membenci"),
        ("一周忌", "isshuuki", "peringatan setahun kematian"),
        ("禁忌", "kinki", "pantangan"),
    ], [
        ("忌み嫌われています。", "Imikirawarete imasu.", "Sangat dibenci."),
        ("一周忌の法要です。", "Isshuuki no houyou desu.", "Ini upacara peringatan setahun kematian."),
    ]),
    ("daku2_n1", "濁", ["ダク"], ["にご-る", "にご-す"], ["keruh", "muddy", "impure"], 16, "水", [
        ("濁る", "nigoru", "menjadi keruh"),
        ("濁流", "dakuryuu", "arus keruh"),
        ("汚濁", "odaku", "pencemaran"),
    ], [
        ("水が濁っています。", "Mizu ga nigotte imasu.", "Airnya keruh."),
        ("濁流に流されました。", "Dakuryuu ni nagasaremashita.", "Hanyut oleh arus keruh."),
    ]),
    ("hon2_n1", "奔", ["ホン"], [], ["berlari kencang", "run", "rush"], 8, "大", [
        ("奔走", "honsou", "berusaha keras/berlari kesana-kemari"),
        ("出奔", "shuppon", "kabur"),
        ("狂奔", "kyouhon", "berlari dengan panik"),
    ], [
        ("奔走しています。", "Honsou shite imasu.", "Berusaha keras kesana-kemari."),
        ("出奔しました。", "Shuppon shimashita.", "Kabur."),
    ]),
    ("to2_n1", "斗", ["ト"], [], ["gayung", "satuan ukur", "dipper", "measure"], 4, "斗", [
        ("北斗七星", "Hokuto Shichisei", "Rasi Bintang Beruang Besar"),
        ("斗酒", "toshu", "banyak sake"),
        ("漏斗", "routo", "corong"),
    ], [
        ("北斗七星が見えます。", "Hokuto Shichisei ga miemasu.", "Terlihat Rasi Bintang Beruang Besar."),
        ("漏斗を使いました。", "Routo o tsukaimashita.", "Menggunakan corong."),
    ]),
    ("ran3_n1", "蘭", ["ラン"], [], ["anggrek", "orchid"], 19, "艸", [
        ("蘭", "ran", "anggrek"),
        ("蘭学", "rangaku", "ilmu Belanda zaman Edo"),
        ("和蘭", "Oranda", "penulisan kanji Belanda"),
    ], [
        ("蘭の花を育てています。", "Ran no hana o sodatete imasu.", "Memelihara bunga anggrek."),
        ("蘭学を学びました。", "Rangaku o manabimashita.", "Mempelajari ilmu Belanda."),
    ]),
    ("fu7_n1", "蒲", ["フ"], ["がま", "かば"], ["tanaman cattail", "cattail plant"], 13, "艸", [
        ("蒲団", "futon", "kasur futon"),
        ("蒲焼", "kabayaki", "ikan panggang saus (unagi)"),
        ("蒲", "gama", "tanaman cattail"),
    ], [
        ("蒲団で寝ました。", "Futon de nemashita.", "Tidur di futon."),
        ("鰻の蒲焼を食べました。", "Unagi no kabayaki o tabemashita.", "Makan unagi kabayaki."),
    ]),
    ("jin7_n1", "迅", ["ジン"], [], ["cepat", "swift"], 6, "辵", [
        ("迅速", "jinsoku", "cepat"),
        ("疾風迅雷", "shippuu jinrai", "secepat kilat"),
        ("奮迅", "funjin", "bergerak cepat dan gigih"),
    ], [
        ("迅速に対応しました。", "Jinsoku ni taiou shimashita.", "Merespons dengan cepat."),
        ("疾風迅雷の勢いです。", "Shippuu jinrai no ikioi desu.", "Ini momentum secepat kilat."),
    ]),
    ("shou27_n1", "肖", ["ショウ"], [], ["menyerupai", "resemble", "portrait"], 7, "肉", [
        ("肖像", "shouzou", "potret"),
        ("肖像画", "shouzouga", "lukisan potret"),
        ("不肖", "fushou", "tidak layak"),
    ], [
        ("肖像画を描きました。", "Shouzouga o kakimashita.", "Melukis potret."),
        ("不肖の息子です。", "Fushou no musuko desu.", "Saya anak yang tidak layak."),
    ]),
    ("hachi_n1", "鉢", ["ハチ"], [], ["mangkuk", "bowl", "pot"], 13, "金", [
        ("鉢", "hachi", "mangkuk/pot"),
        ("植木鉢", "uekibachi", "pot tanaman"),
        ("鉢巻き", "hachimaki", "ikat kepala"),
    ], [
        ("植木鉢に花を植えました。", "Uekibachi ni hana o uemashita.", "Menanam bunga di pot."),
        ("鉢巻きをしました。", "Hachimaki o shimashita.", "Memakai ikat kepala."),
    ]),
    ("kyuu11_n1", "朽", ["キュウ"], ["く-ちる"], ["lapuk", "decay", "rot"], 6, "木", [
        ("朽ちる", "kuchiru", "lapuk"),
        ("老朽化", "roukyuuka", "penuaan/kerusakan"),
        ("不朽", "fukyuu", "abadi/tidak lapuk"),
    ], [
        ("木が朽ちています。", "Ki ga kuchite imasu.", "Kayu itu lapuk."),
        ("老朽化した建物です。", "Roukyuuka shita tatemono desu.", "Ini bangunan yang sudah tua dan rusak."),
    ]),
    ("kaku9_n1", "殻", ["カク"], ["から"], ["cangkang", "shell"], 11, "殳", [
        ("殻", "kara", "cangkang/kulit"),
        ("地殻", "chikaku", "kerak bumi"),
        ("貝殻", "kaigara", "cangkang kerang"),
    ], [
        ("卵の殻です。", "Tamago no kara desu.", "Ini cangkang telur."),
        ("地殻変動です。", "Chikaku hendou desu.", "Ini pergerakan kerak bumi."),
    ]),
    ("kyou11_n1", "享", ["キョウ"], [], ["menerima", "menikmati", "receive", "enjoy"], 8, "亠", [
        ("享受", "kyouju", "menikmati"),
        ("享楽", "kyouraku", "kesenangan"),
        ("享年", "kyounen", "usia saat meninggal"),
    ], [
        ("自由を享受しています。", "Jiyuu o kyouju shite imasu.", "Menikmati kebebasan."),
        ("享年80歳でした。", "Kyounen hachijussai deshita.", "Meninggal pada usia 80 tahun."),
    ]),
    ("shin12_n1", "秦", ["シン"], ["はた"], ["Dinasti Qin", "Qin (ancient China)"], 10, "禾", [
        ("秦", "Shin", "Dinasti Qin Tiongkok kuno"),
        ("秦始皇帝", "Shin no Shikoutei", "Kaisar Pertama Qin"),
        ("秦氏", "Hata-uji", "klan Hata di Jepang kuno"),
    ], [
        ("秦の始皇帝です。", "Shin no Shikoutei desu.", "Ini Kaisar Pertama Dinasti Qin."),
        ("秦氏という一族がいました。", "Hata-uji to iu ichizoku ga imashita.", "Ada klan bernama Hata."),
    ]),
    ("bou10_n1", "茅", ["ボウ"], ["かや", "ち"], ["rumput alang-alang untuk atap", "cogon grass", "thatch"], 8, "艸", [
        ("茅", "kaya", "rumput untuk atap"),
        ("茅葺き", "kayabuki", "atap jerami"),
        ("茅ヶ崎", "Chigasaki", "nama kota"),
    ], [
        ("茅葺き屋根です。", "Kayabuki yane desu.", "Ini atap jerami."),
        ("茅ヶ崎に住んでいます。", "Chigasaki ni sunde imasu.", "Tinggal di Chigasaki."),
    ]),
    ("han6_n1", "藩", ["ハン"], [], ["wilayah feodal", "feudal domain"], 18, "艸", [
        ("藩", "han", "wilayah feodal"),
        ("藩主", "hanshu", "penguasa domain"),
        ("廃藩置県", "haihan chiken", "penghapusan domain feodal"),
    ], [
        ("藩主になりました。", "Hanshu ni narimashita.", "Menjadi penguasa domain."),
        ("廃藩置県が行われました。", "Haihan chiken ga okonawaremashita.", "Penghapusan domain feodal dilaksanakan."),
    ]),
    ("sha7_n1", "沙", ["サ", "シャ"], [], ["pasir (variant 砂)", "sand"], 7, "水", [
        ("沙漠", "sabaku", "gurun"),
        ("沙汰", "sata", "kabar/berita"),
        ("御無沙汰", "gobusata", "lama tidak berkabar"),
    ], [
        ("御無沙汰しております。", "Gobusata shite orimasu.", "Maaf lama tidak berkabar."),
        ("何の沙汰もありません。", "Nan no sata mo arimasen.", "Tidak ada kabar apapun."),
    ]),
    ("ho3_n1", "輔", ["ホ"], [], ["membantu (nama)", "assist"], 14, "車", [
        ("輔佐", "hosa", "bantuan/pendampingan"),
        ("輔導", "hodou", "bimbingan"),
        ("大輔", "Daisuke", "contoh nama pria"),
    ], [
        ("輔佐を務めました。", "Hosa o tsutomemashita.", "Bertugas sebagai pendamping."),
        ("大輔さんに会いました。", "Daisuke-san ni aimashita.", "Bertemu dengan Daisuke."),
    ]),
    ("bai4_n1", "媒", ["バイ"], [], ["perantara", "mediate", "medium"], 12, "女", [
        ("媒体", "baitai", "media"),
        ("媒介", "baikai", "perantara"),
        ("触媒", "shokubai", "katalis"),
    ], [
        ("媒体を通じて広まりました。", "Baitai o tsuujite hiromarimashita.", "Menyebar melalui media."),
        ("触媒として働きます。", "Shokubai toshite hatarakimasu.", "Bekerja sebagai katalis."),
    ]),
    ("kei14_n1", "鶏", ["ケイ"], ["にわとり"], ["ayam", "chicken"], 19, "鳥", [
        ("鶏", "niwatori", "ayam"),
        ("鶏肉", "keiniku", "daging ayam"),
        ("養鶏", "youkei", "peternakan ayam"),
    ], [
        ("鶏を飼っています。", "Niwatori o katte imasu.", "Memelihara ayam."),
        ("鶏肉を食べました。", "Keiniku o tabemashita.", "Makan daging ayam."),
    ]),
    ("zen2_n1", "禅", ["ゼン"], [], ["Zen", "meditasi"], 13, "示", [
        ("禅", "zen", "Zen"),
        ("座禅", "zazen", "meditasi duduk"),
        ("禅寺", "zendera", "kuil Zen"),
    ], [
        ("座禅を組みました。", "Zazen o kumimashita.", "Melakukan meditasi duduk."),
        ("禅寺を訪れました。", "Zendera o otozuremashita.", "Mengunjungi kuil Zen."),
    ]),
    ("shoku4_n1", "嘱", ["ショク"], [], ["mempercayakan", "entrust"], 15, "口", [
        ("嘱託", "shokutaku", "pegawai kontrak"),
        ("委嘱", "ishoku", "penugasan"),
        ("嘱望", "shokubou", "harapan besar"),
    ], [
        ("嘱託社員です。", "Shokutaku shain desu.", "Ini pegawai kontrak."),
        ("将来を嘱望されています。", "Shourai o shokubou sarete imasu.", "Diharapkan besar untuk masa depannya."),
    ]),
    ("dou3_n1", "胴", ["ドウ"], [], ["badan", "torso"], 10, "肉", [
        ("胴体", "doutai", "badan/torso"),
        ("胴上げ", "douage", "melempar ke udara sebagai perayaan"),
        ("胴回り", "dou mawari", "lingkar pinggang"),
    ], [
        ("胴体着陸をしました。", "Doutai chakuriku o shimashita.", "Mendarat darurat tanpa roda."),
        ("胴上げされました。", "Douage saremashita.", "Dilempar ke udara sebagai perayaan."),
    ]),
    ("haku7_n1", "粕", ["ハク"], ["かす"], ["ampas", "sake lees", "dregs"], 11, "米", [
        ("粕", "kasu", "ampas"),
        ("酒粕", "sakekasu", "ampas sake"),
        ("糟粕", "soukasu", "ampas/sisa"),
    ], [
        ("酒粕を使いました。", "Sakekasu o tsukaimashita.", "Menggunakan ampas sake."),
        ("粕漬けです。", "Kasuzuke desu.", "Ini acar ampas sake."),
    ]),
    ("fu8_n1", "冨", ["フ"], ["とみ"], ["kekayaan (variant 富)", "wealth"], 12, "宀", [
        ("冨", "tomi", "kekayaan"),
        ("冨田", "Tomita", "contoh nama keluarga"),
        ("冨士", "Fuji", "variant penulisan gunung Fuji"),
    ], [
        ("冨田さんに会いました。", "Tomita-san ni aimashita.", "Bertemu dengan Tomita."),
        ("これは富の異体字です。", "Kore wa tomi no itaiji desu.", "Ini adalah varian karakter dari \"tomi\"."),
    ]),
    ("tetsu4_n1", "迭", ["テツ"], [], ["bergantian", "alternate", "replace"], 8, "辵", [
        ("更迭", "koutetsu", "pergantian jabatan"),
        ("迭に", "kawarugawaru", "bergantian"),
        ("迭立", "tetsuritsu", "berdiri bergantian"),
    ], [
        ("大臣が更迭されました。", "Daijin ga koutetsu saremashita.", "Menteri diganti."),
        ("更迭人事です。", "Koutetsu jinji desu.", "Ini pergantian jabatan."),
    ]),
    ("sou17_n1", "挿", ["ソウ"], ["さ-す"], ["menyisipkan", "insert"], 10, "手", [
        ("挿す", "sasu", "menyisipkan/menancapkan"),
        ("挿入", "sounyuu", "penyisipan"),
        ("挿絵", "sashie", "ilustrasi"),
    ], [
        ("花を挿しました。", "Hana o sashimashita.", "Menancapkan bunga."),
        ("挿絵が美しいです。", "Sashie ga utsukushii desu.", "Ilustrasinya indah."),
    ]),
    ("shou28_n1", "湘", ["ショウ"], [], ["nama sungai/tempat", "river name"], 12, "水", [
        ("湘南", "Shounan", "wilayah pesisir Kanagawa"),
        ("湘江", "Shoukou", "nama sungai di Tiongkok"),
        ("湘南海岸", "Shounan kaigan", "pantai Shonan"),
    ], [
        ("湘南に旅行しました。", "Shounan ni ryokou shimashita.", "Berlibur ke Shonan."),
        ("湘南海岸で遊びました。", "Shounan kaigan de asobimashita.", "Bermain di pantai Shonan."),
    ]),
    ("ran4_n1", "嵐", ["ラン"], ["あらし"], ["badai", "storm"], 12, "山", [
        ("嵐", "arashi", "badai"),
        ("砂嵐", "sunaarashi", "badai pasir"),
        ("嵐山", "Arashiyama", "nama tempat wisata di Kyoto"),
    ], [
        ("嵐が来ています。", "Arashi ga kite imasu.", "Badai sedang datang."),
        ("嵐山に行きました。", "Arashiyama ni ikimashita.", "Pergi ke Arashiyama."),
    ]),
    ("tsui2_n1", "椎", ["ツイ"], [], ["ruas tulang belakang", "vertebra", "spine"], 12, "木", [
        ("椎間板", "tsuikanban", "cakram tulang belakang"),
        ("脊椎", "sekitsui", "tulang belakang"),
        ("頸椎", "keitsui", "tulang leher"),
    ], [
        ("椎間板ヘルニアです。", "Tsuikanban herunia desu.", "Ini hernia cakram tulang belakang."),
        ("頸椎を痛めました。", "Keitsui o itamemashita.", "Melukai tulang leher."),
    ]),
    ("nada_n1", "灘", [], ["なだ"], ["laut berombak (nama tempat)", "rough sea", "rapids"], 22, "水", [
        ("灘", "nada", "laut berombak"),
        ("玄界灘", "Genkainada", "nama laut"),
        ("灘区", "Nada-ku", "distrik di Kobe"),
    ], [
        ("玄界灘を渡りました。", "Genkainada o watarimashita.", "Menyeberangi Laut Genkai."),
        ("灘区に住んでいます。", "Nada-ku ni sunde imasu.", "Tinggal di distrik Nada."),
    ]),
    ("en9_n1", "堰", ["エン"], ["せき"], ["bendungan kecil", "weir", "dam"], 12, "土", [
        ("堰", "seki", "bendungan kecil"),
        ("堰き止める", "sekitomeru", "membendung"),
        ("堰堤", "entei", "bendungan"),
    ], [
        ("川に堰を作りました。", "Kawa ni seki o tsukurimashita.", "Membuat bendungan di sungai."),
        ("堰き止められました。", "Sekitomeraremashita.", "Dibendung."),
    ]),
    ("shi19_n1", "獅", ["シ"], [], ["singa", "lion"], 13, "犬", [
        ("獅子", "shishi", "singa"),
        ("獅子座", "shishiza", "rasi bintang Leo"),
        ("獅子舞", "shishimai", "tarian singa"),
    ], [
        ("獅子座生まれです。", "Shishiza umare desu.", "Lahir di bawah rasi Leo."),
        ("獅子舞を見ました。", "Shishimai o mimashita.", "Menonton tarian singa."),
    ]),
    ("kyou12_n1", "姜", ["キョウ"], [], ["jahe (marga)", "ginger (surname)"], 9, "女", [
        ("生姜", "shouga", "jahe"),
        ("姜維", "Kyoui", "nama tokoh sejarah Tiongkok"),
        ("姜", "Kyou", "marga Jiang"),
    ], [
        ("生姜を使いました。", "Shouga o tsukaimashita.", "Menggunakan jahe."),
        ("姜維は三国時代の武将です。", "Kyoui wa Sangoku jidai no bushou desu.", "Jiang Wei adalah jenderal zaman Tiga Negara."),
    ]),
    ("ken13_n1", "絹", ["ケン"], ["きぬ"], ["sutra", "silk"], 13, "糸", [
        ("絹", "kinu", "sutra"),
        ("絹糸", "kenshi", "benang sutra"),
        ("絹織物", "kinuorimono", "kain tenun sutra"),
    ], [
        ("絹の着物です。", "Kinu no kimono desu.", "Ini kimono sutra."),
        ("絹織物を作っています。", "Kinuorimono o tsukutte imasu.", "Membuat kain tenun sutra."),
    ]),
    ("bai5_n1", "陪", ["バイ"], [], ["mendampingi", "accompany", "attend"], 11, "阜", [
        ("陪審員", "baishin-in", "juri"),
        ("陪席", "baiseki", "duduk mendampingi"),
        ("陪同", "baidou", "mendampingi"),
    ], [
        ("陪審員に選ばれました。", "Baishin-in ni erabaremashita.", "Terpilih menjadi juri."),
        ("陪席しました。", "Baiseki shimashita.", "Duduk mendampingi."),
    ]),
    ("bou11_n1", "剖", ["ボウ"], [], ["membedah", "dissect"], 10, "刀", [
        ("解剖", "kaibou", "pembedahan/otopsi"),
        ("解剖学", "kaibougaku", "ilmu anatomi"),
        ("剖検", "boken", "otopsi"),
    ], [
        ("解剖しました。", "Kaibou shimashita.", "Melakukan pembedahan."),
        ("解剖学を学んでいます。", "Kaibougaku o manande imasu.", "Mempelajari ilmu anatomi."),
    ]),
    ("fu9_n1", "譜", ["フ"], [], ["partitur musik", "silsilah", "musical score", "genealogy"], 19, "言", [
        ("楽譜", "gakufu", "partitur musik"),
        ("系譜", "keifu", "silsilah"),
        ("年譜", "nenpu", "kronologi tahunan"),
    ], [
        ("楽譜を読みました。", "Gakufu o yomimashita.", "Membaca partitur musik."),
        ("系譜をたどりました。", "Keifu o tadorimashita.", "Menelusuri silsilah."),
    ]),
    ("iku_n1", "郁", ["イク"], [], ["harum", "berbudaya (nama)", "fragrant", "cultured"], 9, "邑", [
        ("郁郁", "ikuiku", "harum semerbak"),
        ("郁子", "Ikuko", "contoh nama wanita"),
        ("郁夫", "Ikuo", "contoh nama pria"),
    ], [
        ("郁子さんに会いました。", "Ikuko-san ni aimashita.", "Bertemu dengan Ikuko."),
        ("郁夫という名前です。", "Ikuo to iu namae desu.", "Ini nama Ikuo."),
    ]),
    ("yuu9_n1", "悠", ["ユウ"], [], ["santai", "jauh", "leisurely", "distant"], 11, "心", [
        ("悠々", "yuuyuu", "santai/tenang"),
        ("悠久", "yuukyuu", "abadi"),
        ("悠長", "yuuchou", "lamban/santai"),
    ], [
        ("悠々と歩きました。", "Yuuyuu to arukimashita.", "Berjalan dengan santai."),
        ("悠久の歴史です。", "Yuukyuu no rekishi desu.", "Ini sejarah yang abadi."),
    ]),
    ("shuku3_n1", "淑", ["シュク"], [], ["anggun", "virtuous", "graceful"], 11, "水", [
        ("淑女", "shukujo", "wanita anggun"),
        ("貞淑", "teishuku", "kesetiaan istri"),
        ("私淑", "shishuku", "belajar diam-diam dari seseorang"),
    ], [
        ("淑女のようです。", "Shukujo no you desu.", "Seperti wanita anggun."),
        ("私淑している作家です。", "Shishuku shite iru sakka desu.", "Ini penulis yang saya kagumi diam-diam."),
    ]),
    ("han7_n1", "帆", ["ハン"], ["ほ"], ["layar kapal", "sail"], 6, "巾", [
        ("帆", "ho", "layar kapal"),
        ("帆船", "hansen", "kapal layar"),
        ("出帆", "shuppan", "berlayar"),
    ], [
        ("帆を張りました。", "Ho o harimashita.", "Membentangkan layar."),
        ("帆船に乗りました。", "Hansen ni norimashita.", "Naik kapal layar."),
    ]),
    ("gyou3_n1", "暁", ["ギョウ"], ["あかつき"], ["fajar", "dawn"], 12, "日", [
        ("暁", "akatsuki", "fajar"),
        ("暁光", "gyoukou", "cahaya fajar"),
        ("通暁", "tsuugyou", "memahami secara mendalam"),
    ], [
        ("暁に出発しました。", "Akatsuki ni shuppatsu shimashita.", "Berangkat saat fajar."),
        ("その分野に通暁しています。", "Sono bun-ya ni tsuugyou shite imasu.", "Memahami bidang itu secara mendalam."),
    ]),
    ("shuu10_n1", "鷲", ["シュウ"], ["わし"], ["elang besar", "eagle"], 23, "鳥", [
        ("鷲", "washi", "elang besar"),
        ("鷲掴み", "washizukami", "mencengkeram"),
        ("白頭鷲", "hakutouwashi", "elang botak"),
    ], [
        ("鷲が空を飛んでいます。", "Washi ga sora o tonde imasu.", "Elang terbang di langit."),
        ("鷲掴みにしました。", "Washizukami ni shimashita.", "Mencengkeram."),
    ]),
    ("ketsu3_n1", "傑", ["ケツ"], [], ["unggul", "outstanding"], 13, "人", [
        ("傑作", "kessaku", "karya masterpiece"),
        ("傑出", "kesshutsu", "menonjol"),
        ("豪傑", "gouketsu", "pahlawan gagah"),
    ], [
        ("傑作を作りました。", "Kessaku o tsukurimashita.", "Membuat karya masterpiece."),
        ("傑出した才能です。", "Kesshutsu shita sainou desu.", "Ini bakat yang menonjol."),
    ]),
    ("nan_n1", "楠", ["ナン"], ["くすのき"], ["pohon kamper", "camphor tree"], 13, "木", [
        ("楠", "kusunoki", "pohon kamper"),
        ("楠木正成", "Kusunoki Masashige", "tokoh sejarah samurai"),
        ("楠若葉", "kusuwakaba", "daun muda kamper"),
    ], [
        ("楠の木があります。", "Kusunoki no ki ga arimasu.", "Ada pohon kamper."),
        ("楠木正成は有名な武将です。", "Kusunoki Masashige wa yuumei na bushou desu.", "Kusunoki Masashige adalah jenderal terkenal."),
    ]),
    ("teki3_n1", "笛", ["テキ"], ["ふえ"], ["seruling", "flute"], 11, "竹", [
        ("笛", "fue", "seruling"),
        ("口笛", "kuchibue", "siulan"),
        ("汽笛", "kiteki", "sirene kapal/kereta"),
    ], [
        ("笛を吹きました。", "Fue o fukimashita.", "Meniup seruling."),
        ("口笛を吹きました。", "Kuchibue o fukimashita.", "Bersiul."),
    ]),
    ("kai8_n1", "芥", ["カイ"], ["からし"], ["sawi", "mustar", "mustard"], 7, "艸", [
        ("芥子", "karashi", "mustar"),
        ("芥川", "Akutagawa", "contoh nama keluarga"),
        ("塵芥", "jinkai", "sampah/debu"),
    ], [
        ("芥子を塗りました。", "Karashi o nurimashita.", "Mengoleskan mustar."),
        ("芥川龍之介は有名な作家です。", "Akutagawa Ryuunosuke wa yuumei na sakka desu.", "Akutagawa Ryunosuke adalah penulis terkenal."),
    ]),
    ("ki22_n1", "其", ["キ"], ["それ"], ["itu (klasik)", "that"], 8, "八", [
        ("其の", "sono", "itu (klasik)"),
        ("其れ", "sore", "itu (klasik)"),
        ("其の他", "sonota", "lain-lain (formal)"),
    ], [
        ("其の他の項目です。", "Sonota no koumoku desu.", "Ini item lain-lain."),
        ("其れは正しいです。", "Sore wa tadashii desu.", "Itu benar."),
    ]),
    ("rei5_n1", "玲", ["レイ"], [], ["suara jernih (nama)", "clear sound"], 9, "玉", [
        ("玲玲", "reirei", "suara jernih berdenting"),
        ("玲子", "Reiko", "contoh nama wanita"),
        ("玲奈", "Reina", "contoh nama wanita"),
    ], [
        ("玲子さんに会いました。", "Reiko-san ni aimashita.", "Bertemu dengan Reiko."),
        ("玲奈という名前です。", "Reina to iu namae desu.", "Ini nama Reina."),
    ]),
    ("do_n1", "奴", ["ド"], ["やつ"], ["pelayan", "orang (kasar)", "servant"], 5, "女", [
        ("奴隷", "dorei", "budak"),
        ("奴", "yatsu", "orang itu (kasar)"),
        ("守銭奴", "shusendo", "orang pelit"),
    ], [
        ("奴隷制度でした。", "Dorei seido deshita.", "Ini adalah sistem perbudakan."),
        ("あの奴は嘘つきです。", "Ano yatsu wa usotsuki desu.", "Orang itu pembohong."),
    ]),
    ("jou10_n1", "錠", ["ジョウ"], [], ["gembok", "tablet obat", "lock"], 16, "金", [
        ("錠前", "joumae", "gembok"),
        ("手錠", "tejou", "borgol"),
        ("錠剤", "jouzai", "tablet obat"),
    ], [
        ("錠前をかけました。", "Joumae o kakemashita.", "Mengunci gembok."),
        ("手錠をかけられました。", "Tejou o kakeraremashita.", "Diborgol."),
    ]),
    ("ken14_n1", "拳", ["ケン"], ["こぶし"], ["kepalan tangan", "fist"], 10, "手", [
        ("拳", "kobushi", "kepalan tangan"),
        ("拳法", "kenpou", "ilmu bela diri kung fu"),
        ("拳銃", "kenjuu", "pistol"),
    ], [
        ("拳を握りました。", "Kobushi o nigirimashita.", "Mengepalkan tangan."),
        ("拳法を習っています。", "Kenpou o naratte imasu.", "Belajar kung fu."),
    ]),
    ("shou29_n1", "翔", ["ショウ"], ["かけ-る", "と-ぶ"], ["terbang tinggi", "soar", "fly"], 12, "羽", [
        ("飛翔", "hishou", "terbang"),
        ("翔る", "kakeru", "terbang tinggi"),
        ("翔太", "Shouta", "contoh nama pria"),
    ], [
        ("大空を飛翔しました。", "Oozora o hishou shimashita.", "Terbang di langit luas."),
        ("翔太という名前です。", "Shouta to iu namae desu.", "Ini nama Shouta."),
    ]),
    ("sen12_n1", "遷", ["セン"], [], ["berpindah", "move", "transition"], 15, "辵", [
        ("遷都", "sento", "pemindahan ibu kota"),
        ("変遷", "hensen", "perubahan seiring waktu"),
        ("左遷", "sasen", "demosi"),
    ], [
        ("遷都しました。", "Sento shimashita.", "Memindahkan ibu kota."),
        ("時代の変遷です。", "Jidai no hensen desu.", "Ini perubahan zaman."),
    ]),
    ("setsu4_n1", "拙", ["セツ"], ["つたな-い"], ["canggung (merendah)", "clumsy", "humble"], 8, "手", [
        ("拙い", "tsutanai", "canggung/kurang mahir"),
        ("拙者", "sessha", "saya (samurai, merendah)"),
        ("稚拙", "chisetsu", "kekanak-kanakan dan kurang terampil"),
    ], [
        ("拙い文章です。", "Tsutanai bunshou desu.", "Ini tulisan yang canggung."),
        ("稚拙な作品です。", "Chisetsu na sakuhin desu.", "Ini karya yang kurang matang."),
    ]),
    ("ji4_n1", "侍", ["ジ"], ["さむらい"], ["samurai", "serve"], 8, "人", [
        ("侍", "samurai", "samurai"),
        ("侍女", "jijo", "dayang"),
        ("侍従", "jijuu", "pelayan istana"),
    ], [
        ("侍になりました。", "Samurai ni narimashita.", "Menjadi samurai."),
        ("侍女が仕えています。", "Jijo ga tsukaete imasu.", "Dayang melayani."),
    ]),
    ("shaku2_n1", "尺", ["シャク"], [], ["satuan panjang Jepang", "ruler"], 4, "尸", [
        ("尺度", "shakudo", "skala/ukuran"),
        ("尺八", "shakuhachi", "seruling bambu Jepang"),
        ("縮尺", "shukushaku", "skala peta"),
    ], [
        ("尺度が違います。", "Shakudo ga chigaimasu.", "Skalanya berbeda."),
        ("尺八を吹きました。", "Shakuhachi o fukimashita.", "Meniup shakuhachi."),
    ]),
    ("touge_n1", "峠", [], ["とうげ"], ["puncak pendakian gunung", "mountain pass"], 9, "山", [
        ("峠", "touge", "puncak pendakian"),
        ("峠道", "togemichi", "jalan gunung"),
        ("峠を越える", "touge o koeru", "melewati masa sulit"),
    ], [
        ("峠を越えました。", "Touge o koemashita.", "Melewati puncak gunung/masa sulit."),
        ("峠道を歩きました。", "Togemichi o arukimashita.", "Berjalan di jalan gunung."),
    ]),
    ("toku3_n1", "篤", ["トク"], [], ["tulus", "parah (sakit)", "sincere"], 16, "竹", [
        ("篤い", "atsui", "tulus"),
        ("危篤", "kitoku", "kritis (sakit parah)"),
        ("篤志家", "tokushika", "dermawan"),
    ], [
        ("危篤状態です。", "Kitoku joutai desu.", "Ini dalam keadaan kritis."),
        ("篤志家です。", "Tokushika desu.", "Dia seorang dermawan."),
    ]),
    ("chou21_n1", "肇", ["チョウ"], ["はじ-める"], ["memulai (nama)", "begin"], 14, "聿", [
        ("肇", "Hajime", "contoh nama pria"),
        ("肇国", "choukoku", "pendirian negara"),
        ("肇造", "chouzou", "memulai membangun"),
    ], [
        ("肇さんに会いました。", "Hajime-san ni aimashita.", "Bertemu dengan Hajime."),
        ("肇国の精神です。", "Choukoku no seishin desu.", "Ini semangat pendirian negara."),
    ]),
    ("katsu6_n1", "渇", ["カツ"], ["かわ-く"], ["haus", "thirst"], 11, "水", [
        ("渇く", "kawaku", "haus"),
        ("渇望", "katsubou", "kerinduan mendalam"),
        ("枯渇", "kokatsu", "kekeringan/habis"),
    ], [
        ("喉が渇きました。", "Nodo ga kawakimashita.", "Tenggorokan haus."),
        ("平和を渇望しています。", "Heiwa o katsubou shite imasu.", "Sangat merindukan perdamaian."),
    ]),
    ("enoki_n1", "榎", [], ["えのき"], ["pohon enoki", "hackberry tree"], 14, "木", [
        ("榎", "enoki", "pohon enoki"),
        ("榎本", "Enomoto", "contoh nama keluarga"),
        ("榎木", "Enoki", "contoh nama keluarga"),
    ], [
        ("榎の木があります。", "Enoki no ki ga arimasu.", "Ada pohon enoki."),
        ("榎本さんに会いました。", "Enomoto-san ni aimashita.", "Bertemu dengan Enomoto."),
    ]),
    ("ryuu6_n1", "劉", ["リュウ"], [], ["marga Liu", "Liu (Chinese surname)"], 15, "刀", [
        ("劉備", "Ryuubi", "Liu Bei, tokoh Tiga Negara"),
        ("劉邦", "Ryuuhou", "Liu Bang, pendiri Dinasti Han"),
        ("劉", "Ryuu", "marga Liu"),
    ], [
        ("劉備は蜀の皇帝です。", "Ryuubi wa Shoku no koutei desu.", "Liu Bei adalah kaisar Shu."),
        ("劉邦が漢を建国しました。", "Ryuuhou ga Kan o kenkoku shimashita.", "Liu Bang mendirikan Dinasti Han."),
    ]),
    ("han8_n1", "幡", ["ハン"], ["はた"], ["bendera panjang", "banner"], 15, "巾", [
        ("幡", "hata", "bendera panjang"),
        ("八幡", "Hachiman", "dewa perang Shinto/nama tempat"),
        ("幡随院", "Banzuiin", "nama kuil"),
    ], [
        ("八幡神社です。", "Hachiman jinja desu.", "Ini kuil Hachiman."),
        ("幡を立てました。", "Hata o tatemashita.", "Mendirikan bendera panjang."),
    ]),
    ("shu6_n1", "諏", ["シュ"], [], ["berkonsultasi (nama tempat)", "consult"], 15, "言", [
        ("諏訪", "Suwa", "nama kota di Nagano"),
        ("諏訪湖", "Suwa-ko", "Danau Suwa"),
        ("諏訪大社", "Suwa Taisha", "kuil besar Suwa"),
    ], [
        ("諏訪湖に行きました。", "Suwa-ko ni ikimashita.", "Pergi ke Danau Suwa."),
        ("諏訪大社を訪れました。", "Suwa Taisha o otozuremashita.", "Mengunjungi Kuil Suwa."),
    ]),
    ("shuku4_n1", "叔", ["シュク"], [], ["paman/bibi muda", "uncle (younger)", "aunt"], 8, "又", [
        ("叔父", "oji", "paman (adik ayah/ibu)"),
        ("叔母", "oba", "bibi (adik ayah/ibu)"),
        ("叔父さん", "ojisan", "paman (panggilan)"),
    ], [
        ("叔父に会いました。", "Oji ni aimashita.", "Bertemu paman."),
        ("叔母が来ました。", "Oba ga kimashita.", "Bibi datang."),
    ]),
    ("shi20_n1", "雌", ["シ"], ["めす"], ["betina", "female (animal)"], 14, "隹", [
        ("雌", "mesu", "betina"),
        ("雌雄", "shiyuu", "jantan-betina/menang-kalah"),
        ("雌花", "mesubana", "bunga betina"),
    ], [
        ("雌の猫です。", "Mesu no neko desu.", "Ini kucing betina."),
        ("雌雄を決しましょう。", "Shiyuu o kesshimashou.", "Mari kita tentukan menang-kalahnya."),
    ]),
    ("kyou13_n1", "亨", ["キョウ"], ["とお-る"], ["keberhasilan (nama)", "success", "pass through"], 7, "亠", [
        ("亨", "Tooru", "contoh nama pria"),
        ("亨保", "Kyouhou", "era zaman Edo"),
        ("元亨利貞", "genkouritei", "empat kebajikan dalam I Ching"),
    ], [
        ("亨さんに会いました。", "Tooru-san ni aimashita.", "Bertemu dengan Tooru."),
        ("元亨利貞という言葉です。", "Genkouritei to iu kotoba desu.", "Ini istilah dari I Ching."),
    ]),
    ("kan29_n1", "堪", ["カン"], ["た-える"], ["tahan", "mampu", "endure"], 12, "土", [
        ("堪える", "taeru", "menahan/tahan"),
        ("堪能", "tannou", "mahir/puas"),
        ("堪忍", "kannin", "kesabaran/pengampunan"),
    ], [
        ("堪能な英語です。", "Tannou na eigo desu.", "Bahasa Inggris yang mahir."),
        ("堪忍してください。", "Kannin shite kudasai.", "Mohon maafkan."),
    ]),
    ("jo4_n1", "叙", ["ジョ"], [], ["menceritakan", "menganugerahkan", "narrate", "confer"], 9, "又", [
        ("叙述", "jojutsu", "penuturan"),
        ("叙情", "jojou", "lirisisme"),
        ("叙勲", "jokun", "penganugerahan medali"),
    ], [
        ("叙述トリックです。", "Jojutsu torikku desu.", "Ini trik naratif."),
        ("叙情的な詩です。", "Jojouteki na shi desu.", "Ini puisi yang liris."),
    ]),
    ("saku4_n1", "酢", ["サク"], ["す"], ["cuka", "vinegar"], 12, "酉", [
        ("酢", "su", "cuka"),
        ("酢豚", "subuta", "babi asam manis"),
        ("酢の物", "sunomono", "salad cuka Jepang"),
    ], [
        ("酢を入れました。", "Su o iremashita.", "Menambahkan cuka."),
        ("酢豚を作りました。", "Subuta o tsukurimashita.", "Membuat babi asam manis."),
    ]),
    ("gin_n1", "吟", ["ギン"], [], ["mendendangkan", "recite", "chant"], 7, "口", [
        ("吟味", "ginmi", "pemeriksaan seksama"),
        ("吟詠", "gin-ei", "mendeklamasikan puisi"),
        ("詩吟", "shigin", "deklamasi puisi Tiongkok"),
    ], [
        ("吟味しました。", "Ginmi shimashita.", "Memeriksa dengan seksama."),
        ("詩吟を習っています。", "Shigin o naratte imasu.", "Belajar deklamasi puisi."),
    ]),
    ("tei15_n1", "逓", ["テイ"], [], ["bergiliran", "in turn", "relay"], 10, "辵", [
        ("逓信", "teishin", "komunikasi (istilah lama)"),
        ("逓減", "teigen", "berkurang bertahap"),
        ("逓増", "teizou", "bertambah bertahap"),
    ], [
        ("逓信省という機関がありました。", "Teishinshou to iu kikan ga arimashita.", "Ada lembaga bernama Kementerian Komunikasi."),
        ("逓減しています。", "Teigen shite imasu.", "Berkurang secara bertahap."),
    ]),
    ("kon6_n1", "痕", ["コン"], ["あと"], ["bekas", "trace", "mark"], 11, "疒", [
        ("痕跡", "konseki", "jejak/bekas"),
        ("傷痕", "kizuato", "bekas luka"),
        ("血痕", "kekkon", "bekas darah"),
    ], [
        ("痕跡が残っています。", "Konseki ga nokotte imasu.", "Jejaknya masih ada."),
        ("傷痕があります。", "Kizuato ga arimasu.", "Ada bekas luka."),
    ]),
    ("rei6_n1", "嶺", ["レイ"], ["みね"], ["puncak gunung", "peak", "summit"], 17, "山", [
        ("嶺", "mine", "puncak"),
        ("分水嶺", "bunsuirei", "batas pemisah air/titik balik"),
        ("山嶺", "sanrei", "puncak gunung"),
    ], [
        ("分水嶺です。", "Bunsuirei desu.", "Ini titik balik penting."),
        ("山嶺が連なっています。", "Sanrei ga tsuranatte imasu.", "Puncak gunung berjejer."),
    ]),
    ("shuu11_n1", "袖", ["シュウ"], ["そで"], ["lengan baju", "sleeve"], 10, "衣", [
        ("袖", "sode", "lengan baju"),
        ("半袖", "hansode", "lengan pendek"),
        ("振袖", "furisode", "kimono lengan panjang"),
    ], [
        ("袖をまくりました。", "Sode o makurimashita.", "Menggulung lengan baju."),
        ("振袖を着ました。", "Furisode o kimashita.", "Memakai kimono lengan panjang."),
    ]),
    ("jin8_n1", "甚", ["ジン"], ["はなは-だ", "はなは-だしい"], ["sangat", "extremely"], 9, "甘", [
        ("甚だ", "hanahada", "sangat"),
        ("甚だしい", "hanahadashii", "sangat/berlebihan"),
        ("幸甚", "koujin", "sangat beruntung"),
    ], [
        ("甚だ残念です。", "Hanahada zannen desu.", "Sangat disayangkan."),
        ("甚だしい誤解です。", "Hanahadashii gokai desu.", "Ini kesalahpahaman yang berlebihan."),
    ]),
    ("kyou14_n1", "喬", ["キョウ"], ["たかし"], ["tinggi (nama)", "tall"], 12, "口", [
        ("喬木", "kyouboku", "pohon tinggi"),
        ("喬太郎", "Kyoutarou", "contoh nama pria"),
        ("喬", "Takashi", "contoh nama pria"),
    ], [
        ("喬木が生えています。", "Kyouboku ga haete imasu.", "Pohon tinggi tumbuh."),
        ("喬太郎という名前です。", "Kyoutarou to iu namae desu.", "Ini nama Kyoutaro."),
    ]),
    ("sai11_n1", "崔", ["サイ"], [], ["marga Choi/Cui", "Choi (surname)"], 11, "山", [
        ("崔", "Sai", "marga Choi/Cui"),
        ("崔氏", "Saishi", "marga Choi/Cui"),
        ("崔さん", "Sai-san", "panggilan untuk marga Choi"),
    ], [
        ("崔さんという韓国人です。", "Sai-san to iu kankokujin desu.", "Ini orang Korea bermarga Choi."),
        ("崔氏は中国や韓国に多い姓です。", "Saishi wa Chuugoku ya Kankoku ni ooi sei desu.", "Choi/Cui adalah marga yang umum di Tiongkok dan Korea."),
    ]),
    ("you9_n1", "妖", ["ヨウ"], ["あや-しい"], ["menggoda", "gaib", "bewitching", "mysterious"], 7, "女", [
        ("妖精", "yousei", "peri"),
        ("妖怪", "youkai", "monster/hantu Jepang"),
        ("妖艶", "youen", "memesona secara seksi"),
    ], [
        ("妖精のようです。", "Yousei no you desu.", "Seperti peri."),
        ("妖怪が出ました。", "Youkai ga demashita.", "Monster muncul."),
    ]),
    ("bi3_n1", "琵", ["ビ"], [], ["biwa (instrumen)"], 12, "玉", [
        ("琵琶", "biwa", "alat musik biwa"),
        ("琵琶湖", "Biwako", "Danau Biwa"),
        ("琵琶法師", "biwa houshi", "pendongeng biwa buta"),
    ], [
        ("琵琶を弾きました。", "Biwa o hikimashita.", "Memainkan biwa."),
        ("琵琶湖に行きました。", "Biwako ni ikimashita.", "Pergi ke Danau Biwa."),
    ]),
    ("wa_n1", "琶", ["ワ"], [], ["biwa (instrumen)"], 12, "玉", [
        ("琵琶", "biwa", "alat musik tradisional Jepang"),
        ("琵琶湖", "Biwako", "Danau Biwa terbesar di Jepang"),
        ("薩摩琵琶", "Satsuma biwa", "jenis biwa dari Satsuma"),
    ], [
        ("琵琶湖は日本最大の湖です。", "Biwako wa Nihon saidai no mizuumi desu.", "Danau Biwa adalah danau terbesar di Jepang."),
        ("薩摩琵琶を演奏しました。", "Satsuma biwa o ensou shimashita.", "Memainkan biwa Satsuma."),
    ]),
    ("ren2_n1", "聯", ["レン"], [], ["menghubungkan (variant 連)", "connect", "associate"], 17, "耳", [
        ("聯合", "rengou", "gabungan"),
        ("聯盟", "renmei", "liga/aliansi"),
        ("対聯", "tairen", "pasangan kaligrafi Tiongkok"),
    ], [
        ("国際聯盟という組織がありました。", "Kokusai Renmei to iu soshiki ga arimashita.", "Ada organisasi bernama Liga Bangsa-Bangsa."),
        ("対聯を飾りました。", "Tairen o kazarimashita.", "Menghias dengan pasangan kaligrafi."),
    ]),
    ("so8_n1", "蘇", ["ソ"], ["よみがえ-る"], ["bangkit kembali", "revive"], 19, "艸", [
        ("蘇る", "yomigaeru", "bangkit kembali"),
        ("蘇生", "sosei", "kebangkitan/resusitasi"),
        ("耶蘇", "Yaso", "Yesus (ateji lama)"),
    ], [
        ("記憶が蘇りました。", "Kioku ga yomigaerimashita.", "Ingatan bangkit kembali."),
        ("蘇生術を行いました。", "Soseijutsu o okonaimashita.", "Melakukan resusitasi."),
    ]),
    ("an_n1", "闇", ["アン"], ["やみ"], ["kegelapan", "darkness"], 17, "門", [
        ("闇", "yami", "kegelapan"),
        ("闇市", "yamiichi", "pasar gelap"),
        ("暗闇", "kurayami", "kegelapan pekat"),
    ], [
        ("闇に包まれています。", "Yami ni tsutsumarete imasu.", "Diselimuti kegelapan."),
        ("暗闇が怖いです。", "Kurayami ga kowai desu.", "Takut pada kegelapan pekat."),
    ]),
    ("suu2_n1", "崇", ["スウ"], [], ["memuja", "worship", "revere"], 11, "山", [
        ("崇拝", "suuhai", "pemujaan"),
        ("崇高", "suukou", "luhur"),
        ("崇敬", "suukei", "rasa hormat mendalam"),
    ], [
        ("崇拝しています。", "Suuhai shite imasu.", "Memuja."),
        ("崇高な理想です。", "Suukou na risou desu.", "Ini cita-cita yang luhur."),
    ]),
    ("shitsu3_n1", "漆", ["シツ"], ["うるし"], ["pernis Jepang", "lacquer"], 14, "水", [
        ("漆", "urushi", "pernis Jepang"),
        ("漆器", "shikki", "kerajinan pernis"),
        ("漆黒", "shikkoku", "hitam pekat"),
    ], [
        ("漆を塗りました。", "Urushi o nurimashita.", "Mengoleskan pernis."),
        ("漆黒の闇です。", "Shikkoku no yami desu.", "Ini kegelapan hitam pekat."),
    ]),
    ("misaki_n1", "岬", [], ["みさき"], ["tanjung", "cape"], 8, "山", [
        ("岬", "misaki", "tanjung"),
        ("石廊岬", "Irouzaki", "nama tanjung"),
        ("岬巡り", "misakimeguri", "menjelajahi tanjung"),
    ], [
        ("岬に立ちました。", "Misaki ni tachimashita.", "Berdiri di tanjung."),
        ("石廊岬を訪れました。", "Irouzaki o otozuremashita.", "Mengunjungi Tanjung Irou."),
    ]),
    ("heki2_n1", "癖", ["ヘキ"], ["くせ"], ["kebiasaan", "keanehan", "habit", "quirk"], 18, "疒", [
        ("癖", "kuse", "kebiasaan/keanehan"),
        ("口癖", "kuchiguse", "kata-kata favorit"),
        ("潔癖", "keppeki", "sangat bersih/perfeksionis"),
    ], [
        ("癖があります。", "Kuse ga arimasu.", "Punya kebiasaan aneh."),
        ("潔癖症です。", "Keppekishou desu.", "Ini gangguan sangat perfeksionis soal kebersihan."),
    ]),
    ("yu4_n1", "愉", ["ユ"], [], ["menyenangkan", "pleasant"], 12, "心", [
        ("愉快", "yukai", "menyenangkan"),
        ("愉しい", "tanoshii", "senang"),
        ("愉悦", "yuetsu", "kegembiraan"),
    ], [
        ("愉快な人です。", "Yukai na hito desu.", "Dia orang yang menyenangkan."),
        ("愉悦を感じました。", "Yuetsu o kanjimashita.", "Merasakan kegembiraan."),
    ]),
    ("in3_n1", "寅", ["イン"], ["とら"], ["shio macan", "tiger zodiac"], 11, "宀", [
        ("寅", "tora", "tahun macan dalam zodiak"),
        ("寅年", "toradoshi", "tahun macan"),
        ("寅の刻", "tora no koku", "jam macan (waktu kuno)"),
    ], [
        ("寅年生まれです。", "Toradoshi umare desu.", "Lahir di tahun macan."),
        ("寅の刻に起きました。", "Tora no koku ni okimashita.", "Bangun pada jam macan."),
    ]),
    ("soku3_n1", "捉", ["ソク"], ["とら-える"], ["menangkap", "catch", "grasp"], 10, "手", [
        ("捉える", "toraeru", "menangkap/memahami"),
        ("捕捉", "hosoku", "penangkapan/pemahaman"),
        ("把捉", "hasoku", "menggenggam/memahami"),
    ], [
        ("本質を捉えました。", "Honshitsu o toraemashita.", "Menangkap esensinya."),
        ("捕捉しました。", "Hosoku shimashita.", "Menangkap/memahami."),
    ]),
    ("shou30_n1", "礁", ["ショウ"], [], ["karang", "reef"], 17, "石", [
        ("岩礁", "ganshou", "karang batu"),
        ("暗礁", "anshou", "karang tersembunyi"),
        ("サンゴ礁", "sango-shou", "terumbu karang"),
    ], [
        ("岩礁に注意してください。", "Ganshou ni chuui shite kudasai.", "Waspadalah terhadap karang batu."),
        ("サンゴ礁が美しいです。", "Sango-shou ga utsukushii desu.", "Terumbu karangnya indah."),
    ]),
    ("no_n1", "乃", ["ダイ", "ノ"], ["の"], ["partikel klasik dari", "thus", "possessive"], 2, "丿", [
        ("乃ち", "sunawachi", "yaitu/dengan demikian"),
        ("乃至", "naishi", "atau/sampai dengan"),
        ("乃木", "Nogi", "contoh nama keluarga"),
    ], [
        ("乃至10人です。", "Naishi juu-nin desu.", "Sampai dengan 10 orang."),
        ("乃木大将は有名な軍人です。", "Nogi taishou wa yuumei na gunjin desu.", "Jenderal Nogi adalah tentara terkenal."),
    ]),
    ("shuu12_n1", "洲", ["シュウ"], ["す"], ["delta pasir", "benua (variant 州)", "sandbar", "continent"], 9, "水", [
        ("洲", "su", "delta pasir"),
        ("満洲", "Manshuu", "Manchuria"),
        ("欧州", "Oushuu", "Eropa"),
    ], [
        ("満洲という地域がありました。", "Manshuu to iu chiiki ga arimashita.", "Ada wilayah bernama Manchuria."),
        ("欧州を旅行しました。", "Oushuu o ryokou shimashita.", "Berlibur ke Eropa."),
    ]),
    ("ton3_n1", "屯", ["トン"], [], ["berkumpul", "garnisun", "garrison", "gather"], 4, "屮", [
        ("駐屯", "chuuton", "penempatan garnisun"),
        ("屯田兵", "tondenhei", "tentara petani kolonis"),
        ("屯所", "tonsho", "pos jaga"),
    ], [
        ("駐屯地です。", "Chuutonchi desu.", "Ini area garnisun."),
        ("屯田兵として働きました。", "Tondenhei toshite hatarakimashita.", "Bekerja sebagai tentara petani kolonis."),
    ]),
    ("son_n1", "樽", ["ソン"], ["たる"], ["tong kayu", "barrel", "cask"], 16, "木", [
        ("樽", "taru", "tong kayu"),
        ("樽酒", "tarusake", "sake dalam tong"),
        ("一樽", "hitotaru", "satu tong"),
    ], [
        ("樽に入れました。", "Taru ni iremashita.", "Dimasukkan ke dalam tong."),
        ("樽酒を飲みました。", "Tarusake o nomimashita.", "Minum sake dari tong."),
    ]),
    ("ka14_n1", "樺", ["カ"], ["かば"], ["pohon birch", "birch tree"], 14, "木", [
        ("樺", "kaba", "pohon birch"),
        ("白樺", "shirakaba", "birch putih"),
        ("樺太", "Karafuto", "nama pulau Sakhalin"),
    ], [
        ("白樺の木があります。", "Shirakaba no ki ga arimasu.", "Ada pohon birch putih."),
        ("樺太に行きました。", "Karafuto ni ikimashita.", "Pergi ke Sakhalin."),
    ]),
    ("shin13_n1", "槙", [], ["まき"], ["pohon podocarpus (nama)", "podocarpus tree"], 14, "木", [
        ("槙", "maki", "pohon podocarpus"),
        ("槙原", "Makihara", "contoh nama keluarga"),
        ("槙島", "Makishima", "contoh nama keluarga"),
    ], [
        ("槙の木を植えました。", "Maki no ki o uemashita.", "Menanam pohon maki."),
        ("槙原さんに会いました。", "Makihara-san ni aimashita.", "Bertemu dengan Makihara."),
    ]),
    ("satsu3_n1", "薩", ["サツ"], [], ["nama daerah Satsuma", "Satsuma"], 17, "艸", [
        ("薩摩", "Satsuma", "nama daerah lama di Kyushu"),
        ("薩摩藩", "Satsuma-han", "domain feodal Satsuma"),
        ("菩薩", "bosatsu", "bodhisattva"),
    ], [
        ("薩摩藩の出身です。", "Satsuma-han no shusshin desu.", "Berasal dari domain Satsuma."),
        ("菩薩像を見ました。", "Bosatsuzou o mimashita.", "Melihat patung bodhisattva."),
    ]),
    ("in4_n1", "姻", ["イン"], [], ["pernikahan", "marriage"], 9, "女", [
        ("婚姻", "kon-in", "pernikahan"),
        ("姻戚", "inseki", "kerabat melalui pernikahan"),
        ("姻族", "inzoku", "keluarga besan"),
    ], [
        ("婚姻届を出しました。", "Kon-in todoke o dashimashita.", "Mengajukan surat nikah."),
        ("姻戚関係です。", "Inseki kankei desu.", "Ini hubungan kerabat melalui pernikahan."),
    ]),
    ("gan3_n1", "巌", ["ガン"], ["いわお"], ["batu besar (variant 岩)", "large rock"], 20, "山", [
        ("巌", "iwao", "batu besar"),
        ("巌流島", "Ganryuujima", "nama pulau terkenal duel samurai"),
        ("巌窟", "gankutsu", "gua batu"),
    ], [
        ("巌流島で決闘しました。", "Ganryuujima de kettou shimashita.", "Berduel di Pulau Ganryu."),
        ("巌窟王という小説です。", "Gankutsuou to iu shousetsu desu.", "Ini novel \"Count of Monte Cristo\"."),
    ]),
    ("yodo_n1", "淀", [], ["よど"], ["air tergenang", "stagnant water"], 11, "水", [
        ("淀む", "yodomu", "tergenang/macet"),
        ("淀川", "Yodogawa", "nama sungai di Osaka"),
        ("淀み", "yodomi", "genangan"),
    ], [
        ("川が淀んでいます。", "Kawa ga yodonde imasu.", "Sungai tergenang."),
        ("淀川を渡りました。", "Yodogawa o watarimashita.", "Menyeberangi Sungai Yodo."),
    ]),
    ("kouji_n1", "麹", [], ["こうじ"], ["ragi koji", "koji mold"], 16, "麦", [
        ("麹", "kouji", "ragi koji"),
        ("麹町", "Koujimachi", "nama daerah di Tokyo"),
        ("塩麹", "shiokouji", "koji garam"),
    ], [
        ("麹を使いました。", "Kouji o tsukaimashita.", "Menggunakan ragi koji."),
        ("塩麹で漬けました。", "Shiokouji de tsukemashita.", "Merendam dengan koji garam."),
    ]),
    ("kake_n1", "賭", [], ["か-ける"], ["bertaruh", "bet", "gamble"], 16, "貝", [
        ("賭ける", "kakeru", "bertaruh"),
        ("賭博", "tobaku", "perjudian"),
        ("賭け事", "kakegoto", "perjudian"),
    ], [
        ("お金を賭けました。", "Okane o kakemashita.", "Bertaruh uang."),
        ("賭博は違法です。", "Tobaku wa ihou desu.", "Perjudian itu ilegal."),
    ]),
    ("gi8_n1", "擬", ["ギ"], [], ["meniru", "imitate", "quasi"], 17, "手", [
        ("擬態", "gitai", "mimikri"),
        ("模擬", "mogi", "simulasi/tiruan"),
        ("擬人化", "gijinka", "personifikasi"),
    ], [
        ("擬態しています。", "Gitai shite imasu.", "Melakukan mimikri."),
        ("模擬試験を受けました。", "Mogi shiken o ukemashita.", "Mengikuti ujian simulasi."),
    ]),
    ("hei5_n1", "塀", ["ヘイ"], [], ["tembok pembatas", "wall", "fence"], 12, "土", [
        ("塀", "hei", "tembok pembatas"),
        ("板塀", "itabei", "pagar kayu"),
        ("土塀", "dobei", "tembok tanah"),
    ], [
        ("塀を作りました。", "Hei o tsukurimashita.", "Membuat tembok pembatas."),
        ("板塀が壊れました。", "Itabei ga kowaremashita.", "Pagar kayu rusak."),
    ]),
    ("shin14_n1", "唇", ["シン"], ["くちびる"], ["bibir", "lips"], 10, "口", [
        ("唇", "kuchibiru", "bibir"),
        ("上唇", "uwakuchibiru", "bibir atas"),
        ("唇を噛む", "kuchibiru o kamu", "menggigit bibir"),
    ], [
        ("唇が乾いています。", "Kuchibiru ga kawaite imasu.", "Bibirnya kering."),
        ("唇を噛みました。", "Kuchibiru o kamimashita.", "Menggigit bibir."),
    ]),
    ("boku6_n1", "睦", ["ボク"], ["むつ-まじい"], ["akrab", "harmonious"], 13, "目", [
        ("親睦", "shinboku", "keakraban"),
        ("睦まじい", "mutsumajii", "akrab/mesra"),
        ("和睦", "waboku", "perdamaian"),
    ], [
        ("親睦会がありました。", "Shinbokukai ga arimashita.", "Ada acara keakraban."),
        ("睦まじい夫婦です。", "Mutsumajii fuufu desu.", "Ini pasangan yang mesra."),
    ]),
    ("kan30_n1", "閑", ["カン"], [], ["tenang", "senggang", "quiet", "leisure"], 12, "門", [
        ("閑静", "kansei", "tenang"),
        ("閑散", "kansan", "sepi"),
        ("忙中閑", "bouchuukan", "kesibukan di tengah kesibukan"),
    ], [
        ("閑静な住宅街です。", "Kansei na juutakugai desu.", "Ini kawasan perumahan yang tenang."),
        ("閑散としています。", "Kansan to shite imasu.", "Sepi."),
    ]),
    ("ko7_n1", "胡", ["コ"], [], ["bangsa asing kuno", "lada", "barbarian", "pepper"], 9, "肉", [
        ("胡椒", "koshou", "lada"),
        ("胡瓜", "kyuuri", "mentimun"),
        ("胡麻", "goma", "wijen"),
    ], [
        ("胡椒をかけました。", "Koshou o kakemashita.", "Menaburkan lada."),
        ("胡麻油を使いました。", "Goma abura o tsukaimashita.", "Menggunakan minyak wijen."),
    ]),
    ("yuu10_n1", "幽", ["ユウ"], [], ["samar", "hantu", "faint", "ghost"], 9, "幺", [
        ("幽霊", "yuurei", "hantu"),
        ("幽閉", "yuuhei", "pengurungan"),
        ("幽玄", "yuugen", "keindahan misterius"),
    ], [
        ("幽閉されました。", "Yuuhei saremashita.", "Dikurung."),
        ("幽玄な美しさです。", "Yuugen na utsukushisa desu.", "Ini keindahan yang misterius."),
    ]),
    ("shun4_n1", "峻", ["シュン"], [], ["curam", "keras", "steep", "severe"], 10, "山", [
        ("峻厳", "shungen", "keras dan tegas"),
        ("険峻", "kenshun", "curam"),
        ("峻烈", "shunretsu", "sangat keras"),
    ], [
        ("峻厳な態度です。", "Shungen na taido desu.", "Ini sikap yang keras dan tegas."),
        ("険峻な山です。", "Kenshun na yama desu.", "Ini gunung yang curam."),
    ]),
    ("sou18_n1", "曹", ["ソウ"], [], ["sersan", "kelompok", "sergeant", "companion"], 11, "曰", [
        ("曹長", "souchou", "sersan mayor"),
        ("法曹", "housou", "dunia hukum"),
        ("重曹", "juusou", "soda kue"),
    ], [
        ("曹長になりました。", "Souchou ni narimashita.", "Menjadi sersan mayor."),
        ("法曹界で働いています。", "Housoukai de hataraite imasu.", "Bekerja di dunia hukum."),
    ]),
    ("shou31_n1", "哨", ["ショウ"], [], ["penjaga", "sentinel", "whistle"], 10, "口", [
        ("哨戒", "shoukai", "patroli pengawasan"),
        ("歩哨", "hoshou", "penjaga berjalan"),
        ("前哨戦", "zenshousen", "pertempuran pendahuluan"),
    ], [
        ("哨戒任務です。", "Shoukai ninmu desu.", "Ini tugas patroli pengawasan."),
        ("前哨戦が始まりました。", "Zenshousen ga hajimarimashita.", "Pertempuran pendahuluan dimulai."),
    ]),
    ("ei3_n1", "詠", ["エイ"], ["よ-む"], ["mendendangkan puisi", "recite"], 12, "言", [
        ("詠む", "yomu", "mendendangkan puisi"),
        ("詠嘆", "eitan", "kekaguman/keharuan"),
        ("朗詠", "rouei", "mendeklamasikan puisi dengan lantang"),
    ], [
        ("和歌を詠みました。", "Waka o yomimashita.", "Mendendangkan waka."),
        ("詠嘆の声を上げました。", "Eitan no koe o agemashita.", "Mengeluarkan suara kekaguman."),
    ]),
    ("shou32_n1", "炒", ["ショウ"], ["いた-める"], ["menumis", "stir-fry"], 8, "火", [
        ("炒める", "itameru", "menumis"),
        ("炒飯", "chaahan", "nasi goreng"),
        ("炒め物", "itamemono", "masakan tumis"),
    ], [
        ("野菜を炒めました。", "Yasai o itamemashita.", "Menumis sayuran."),
        ("炒飯を作りました。", "Chaahan o tsukurimashita.", "Membuat nasi goreng."),
    ]),
    ("hei6_n1", "屏", ["ヘイ"], [], ["sekat lipat", "screen"], 9, "尸", [
        ("屏風", "byoubu", "sekat lipat Jepang"),
        ("屏障", "heishou", "penghalang"),
        ("屏居", "heikyo", "mengasingkan diri"),
    ], [
        ("屏風を飾りました。", "Byoubu o kazarimashita.", "Menghias dengan sekat lipat."),
        ("美しい屏風です。", "Utsukushii byoubu desu.", "Ini sekat lipat yang indah."),
    ]),
    ("hi9_n1", "卑", ["ヒ"], ["いや-しい"], ["rendah", "hina", "lowly", "vulgar"], 9, "十", [
        ("卑怯", "hikyou", "pengecut"),
        ("卑劣", "hiretsu", "licik"),
        ("卑しい", "iyashii", "hina/rendah"),
    ], [
        ("卑怯な行為です。", "Hikyou na koui desu.", "Ini tindakan pengecut."),
        ("卑劣な手段です。", "Hiretsu na shudan desu.", "Ini cara yang licik."),
    ]),
    ("bu2_n1", "侮", ["ブ"], ["あなど-る"], ["meremehkan", "insult", "despise"], 8, "人", [
        ("侮辱", "bujoku", "hinaan"),
        ("侮る", "anadoru", "meremehkan"),
        ("侮蔑", "bubetsu", "penghinaan"),
    ], [
        ("相手を侮ってはいけません。", "Aite o anadotte wa ikemasen.", "Jangan meremehkan lawan."),
        ("侮蔑的な態度です。", "Bubetsuteki na taido desu.", "Ini sikap yang menghina."),
    ]),
    ("chuu4_n1", "鋳", ["チュウ"], ["い-る"], ["mencor logam", "cast (metal)"], 15, "金", [
        ("鋳造", "chuuzou", "pengecoran"),
        ("鋳物", "imono", "barang cor"),
        ("鋳型", "igata", "cetakan cor"),
    ], [
        ("鋳造技術です。", "Chuuzou gijutsu desu.", "Ini teknik pengecoran."),
        ("鋳物を作りました。", "Imono o tsukurimashita.", "Membuat barang cor."),
    ]),
    ("matsu_n1", "抹", ["マツ"], [], ["menghapus", "bubuk", "wipe", "powder"], 8, "手", [
        ("抹茶", "maccha", "teh matcha"),
        ("抹殺", "massatsu", "penghapusan/pembasmian"),
        ("一抹", "ichimatsu", "secercah"),
    ], [
        ("抹茶を飲みました。", "Maccha o nomimashita.", "Minum teh matcha."),
        ("一抹の不安があります。", "Ichimatsu no fuan ga arimasu.", "Ada secercah kecemasan."),
    ]),
    ("i9_n1", "尉", ["イ"], [], ["perwira militer", "military officer"], 9, "寸", [
        ("大尉", "taii", "kapten (militer)"),
        ("尉官", "ikan", "perwira pertama"),
        ("中尉", "chuui", "letnan"),
    ], [
        ("大尉になりました。", "Taii ni narimashita.", "Menjadi kapten."),
        ("中尉として働いています。", "Chuui toshite hataraite imasu.", "Bekerja sebagai letnan."),
    ]),
    ("ki23_n1", "槻", [], ["つき"], ["pohon zelkova (nama)", "zelkova tree"], 15, "木", [
        ("槻", "tsuki", "pohon zelkova"),
        ("槻の木", "tsuki no ki", "pohon zelkova"),
        ("高槻", "Takatsuki", "nama kota di Osaka"),
    ], [
        ("槻の木があります。", "Tsuki no ki ga arimasu.", "Ada pohon zelkova."),
        ("高槻市に住んでいます。", "Takatsuki-shi ni sunde imasu.", "Tinggal di kota Takatsuki."),
    ]),
    ("rei7_n1", "隷", ["レイ"], [], ["budak", "servant", "slave"], 16, "隶", [
        ("奴隷", "dorei", "budak"),
        ("隷属", "reizoku", "subordinasi"),
        ("隷書", "reisho", "gaya tulisan kaligrafi Tiongkok"),
    ], [
        ("隷属しています。", "Reizoku shite imasu.", "Berada dalam subordinasi."),
        ("隷書で書きました。", "Reisho de kakimashita.", "Menulis dengan gaya kaligrafi reisho."),
    ]),
    ("ka15_n1", "禍", ["カ"], [], ["bencana", "misfortune", "disaster"], 13, "示", [
        ("災禍", "saika", "bencana"),
        ("禍根", "kakon", "akar masalah"),
        ("戦禍", "senka", "bencana perang"),
    ], [
        ("災禍に見舞われました。", "Saika ni mimawaremashita.", "Tertimpa bencana."),
        ("禍根を残しました。", "Kakon o nokoshimashita.", "Meninggalkan akar masalah."),
    ]),
    ("chou22_n1", "蝶", ["チョウ"], [], ["kupu-kupu", "butterfly"], 15, "虫", [
        ("蝶", "chou", "kupu-kupu"),
        ("蝶々", "choucho", "kupu-kupu (informal)"),
        ("蝶ネクタイ", "chou nekutai", "dasi kupu-kupu"),
    ], [
        ("蝶が飛んでいます。", "Chou ga tonde imasu.", "Kupu-kupu sedang terbang."),
        ("蝶ネクタイをつけました。", "Chou nekutai o tsukemashita.", "Memakai dasi kupu-kupu."),
    ]),
    ("raku_n1", "酪", ["ラク"], [], ["produk susu", "dairy"], 13, "酉", [
        ("酪農", "rakunou", "peternakan sapi perah"),
        ("酪農家", "rakunouka", "peternak sapi perah"),
        ("乾酪", "kanraku", "keju"),
    ], [
        ("酪農業をしています。", "Rakunougyou o shite imasu.", "Bekerja di bidang peternakan sapi perah."),
        ("酪農家になりました。", "Rakunouka ni narimashita.", "Menjadi peternak sapi perah."),
    ]),
    ("kei15_n1", "茎", ["ケイ"], ["くき"], ["batang tumbuhan", "stem"], 8, "艸", [
        ("茎", "kuki", "batang"),
        ("地下茎", "chikakei", "rimpang"),
        ("歯茎", "haguki", "gusi"),
    ], [
        ("茎を切りました。", "Kuki o kirimashita.", "Memotong batang."),
        ("歯茎が腫れています。", "Haguki ga harete imasu.", "Gusinya bengkak."),
    ]),
    ("han9_n1", "汎", ["ハン"], [], ["menyeluruh", "pan-", "general"], 6, "水", [
        ("汎用", "han-you", "serba guna"),
        ("汎神論", "hanshinron", "panteisme"),
        ("汎太平洋", "han-taiheiyou", "Pan-Pasifik"),
    ], [
        ("汎用性があります。", "Han-yousei ga arimasu.", "Memiliki keserbagunaan."),
        ("汎太平洋地域です。", "Han-taiheiyou chiiki desu.", "Ini wilayah Pan-Pasifik."),
    ]),
    ("kei16_n1", "頃", ["ケイ"], ["ころ"], ["sekitar waktu", "time", "around"], 11, "頁", [
        ("頃", "koro", "sekitar waktu"),
        ("頃合い", "koroai", "waktu yang tepat"),
        ("日頃", "higoro", "sehari-hari"),
    ], [
        ("三時頃に来ます。", "Sanji-koro ni kimasu.", "Datang sekitar jam tiga."),
        ("日頃から練習しています。", "Higoro kara renshuu shite imasu.", "Berlatih sehari-hari."),
    ]),
    ("sui10_n1", "帥", ["スイ"], [], ["panglima", "commander"], 9, "巾", [
        ("元帥", "gensui", "marsekal/jenderal besar"),
        ("統帥", "tousui", "komando tertinggi"),
        ("総帥", "sousui", "panglima tertinggi"),
    ], [
        ("元帥になりました。", "Gensui ni narimashita.", "Menjadi marsekal."),
        ("統帥権です。", "Tousuiken desu.", "Ini hak komando tertinggi."),
    ]),
    ("ryou9_n1", "梁", ["リョウ"], ["はり"], ["balok penyangga", "beam", "bridge"], 11, "木", [
        ("梁", "hari", "balok penyangga"),
        ("橋梁", "kyouryou", "jembatan"),
        ("上梁", "jouryou", "pemasangan balok atap"),
    ], [
        ("梁が支えています。", "Hari ga sasaete imasu.", "Balok menopang."),
        ("橋梁工事です。", "Kyouryou kouji desu.", "Ini konstruksi jembatan."),
    ]),
    ("sei13_n1", "逝", ["セイ"], ["ゆ-く"], ["meninggal", "pass away"], 10, "辵", [
        ("逝去", "seikyo", "wafat"),
        ("急逝", "kyuusei", "meninggal mendadak"),
        ("長逝", "chousei", "meninggal (formal)"),
    ], [
        ("逝去されました。", "Seikyo saremashita.", "Beliau telah wafat."),
        ("急逝しました。", "Kyuusei shimashita.", "Meninggal mendadak."),
    ]),
    ("ki24_n1", "汽", ["キ"], [], ["uap", "steam"], 6, "水", [
        ("汽車", "kisha", "kereta uap"),
        ("汽船", "kisen", "kapal uap"),
        ("汽笛", "kiteki", "sirene kapal/kereta"),
    ], [
        ("汽車に乗りました。", "Kisha ni norimashita.", "Naik kereta uap."),
        ("汽船で渡りました。", "Kisen de watarimashita.", "Menyeberang dengan kapal uap."),
    ]),
    ("mei2_n1", "謎", ["メイ"], ["なぞ"], ["teka-teki", "mystery", "riddle"], 17, "言", [
        ("謎", "nazo", "teka-teki/misteri"),
        ("謎解き", "nazotoki", "pemecahan teka-teki"),
        ("謎めいた", "nazomeita", "misterius"),
    ], [
        ("謎が解けました。", "Nazo ga tokemashita.", "Teka-teki terpecahkan."),
        ("謎めいた人物です。", "Nazomeita jinbutsu desu.", "Ini sosok yang misterius."),
    ]),
    ("taku6_n1", "琢", ["タク"], [], ["mengasah (nama)", "polish (gem)"], 11, "玉", [
        ("切磋琢磨", "sessa takuma", "saling mengasah diri"),
        ("琢磨", "takuma", "pengasahan/latihan keras"),
        ("琢也", "Takuya", "contoh nama pria"),
    ], [
        ("切磋琢磨しています。", "Sessa takuma shite imasu.", "Saling mengasah diri."),
        ("琢也さんに会いました。", "Takuya-san ni aimashita.", "Bertemu dengan Takuya."),
    ]),
    ("ki25_n1", "箕", ["キ"], ["み"], ["nyiru", "winnowing basket"], 14, "竹", [
        ("箕", "mi", "nyiru"),
        ("箕面", "Minoo", "nama kota di Osaka"),
        ("箕作り", "mizukuri", "pembuatan nyiru"),
    ], [
        ("箕で選別しました。", "Mi de senbetsu shimashita.", "Menyortir dengan nyiru."),
        ("箕面市に行きました。", "Minoo-shi ni ikimashita.", "Pergi ke kota Minoo."),
    ]),
    ("toku4_n1", "匿", ["トク"], [], ["menyembunyikan", "hide", "conceal"], 10, "匚", [
        ("匿名", "tokumei", "anonim"),
        ("隠匿", "intoku", "penyembunyian"),
        ("蔵匿", "zoutoku", "menyembunyikan (istilah hukum)"),
    ], [
        ("匿名で投稿しました。", "Tokumei de toukou shimashita.", "Memposting secara anonim."),
        ("隠匿していました。", "Intoku shite imashita.", "Menyembunyikan."),
    ]),
    ("sou19_n1", "爪", ["ソウ"], ["つめ"], ["kuku", "cakar", "nail", "claw"], 4, "爪", [
        ("爪", "tsume", "kuku"),
        ("爪切り", "tsumekiri", "gunting kuku"),
        ("生爪", "namazume", "kuku hidup"),
    ], [
        ("爪を切りました。", "Tsume o kirimashita.", "Memotong kuku."),
        ("爪切りを使いました。", "Tsumekiri o tsukaimashita.", "Menggunakan gunting kuku."),
    ]),
    ("ha4_n1", "芭", ["ハ"], [], ["pohon pisang (dalam kata majemuk)", "banana plant"], 7, "艸", [
        ("芭蕉", "bashou", "pohon pisang/nama pujangga"),
        ("松尾芭蕉", "Matsuo Bashou", "penyair haiku terkenal"),
        ("芭蕉布", "bashoufu", "kain serat pisang Okinawa"),
    ], [
        ("松尾芭蕉は有名な俳人です。", "Matsuo Bashou wa yuumei na haijin desu.", "Matsuo Basho adalah penyair haiku terkenal."),
        ("芭蕉布で作られています。", "Bashoufu de tsukurarete imasu.", "Dibuat dari kain serat pisang."),
    ]),
    ("tou19_n1", "逗", ["トウ"], [], ["singgah", "stay", "stop over"], 10, "辵", [
        ("逗留", "touryuu", "tinggal sementara"),
        ("逗子", "Zushi", "nama kota di Kanagawa"),
        ("逗子市", "Zushi-shi", "Kota Zushi"),
    ], [
        ("逗留しています。", "Touryuu shite imasu.", "Sedang tinggal sementara."),
        ("逗子市に行きました。", "Zushi-shi ni ikimashita.", "Pergi ke Kota Zushi."),
    ]),
    ("toma_n1", "苫", [], ["とま"], ["tikar jerami", "straw mat"], 8, "艸", [
        ("苫", "toma", "tikar jerami"),
        ("苫小牧", "Tomakomai", "nama kota di Hokkaido"),
        ("苫屋", "tomaya", "gubuk beratap jerami"),
    ], [
        ("苫小牧に住んでいます。", "Tomakomai ni sunde imasu.", "Tinggal di Tomakomai."),
        ("苫で覆いました。", "Toma de ooimashita.", "Menutupi dengan tikar jerami."),
    ]),
    ("ken15_n1", "鍵", ["ケン"], ["かぎ"], ["kunci", "key"], 17, "金", [
        ("鍵", "kagi", "kunci"),
        ("鍵盤", "kenban", "keyboard/tuts"),
        ("合鍵", "aikagi", "kunci duplikat"),
    ], [
        ("鍵をかけました。", "Kagi o kakemashita.", "Mengunci."),
        ("鍵盤楽器です。", "Kenban gakki desu.", "Ini alat musik keyboard."),
    ]),
    ("kin5_n1", "襟", ["キン"], ["えり"], ["kerah baju", "collar"], 18, "衣", [
        ("襟", "eri", "kerah"),
        ("襟元", "erimoto", "area kerah"),
        ("開襟", "kaikin", "kerah terbuka"),
    ], [
        ("襟を正しました。", "Eri o tadashimashita.", "Merapikan kerah/membenahi sikap."),
        ("開襟シャツです。", "Kaikin shatsu desu.", "Ini kemeja berkerah terbuka."),
    ]),
    ("kei17_n1", "蛍", ["ケイ"], ["ほたる"], ["kunang-kunang", "firefly"], 11, "虫", [
        ("蛍", "hotaru", "kunang-kunang"),
        ("蛍光灯", "keikoutou", "lampu neon"),
        ("蛍雪", "keisetsu", "kerja keras belajar"),
    ], [
        ("蛍を見ました。", "Hotaru o mimashita.", "Melihat kunang-kunang."),
        ("蛍光灯をつけました。", "Keikoutou o tsukemashita.", "Menyalakan lampu neon."),
    ]),
    ("yuu11_n1", "楢", [], ["なら"], ["pohon ek Jepang (nama)", "Japanese oak"], 13, "木", [
        ("楢", "nara", "pohon ek Jepang"),
        ("楢山", "Narayama", "nama gunung"),
        ("楢崎", "Narasaki", "contoh nama keluarga"),
    ], [
        ("楢の木があります。", "Nara no ki ga arimasu.", "Ada pohon ek."),
        ("楢山節考という映画です。", "Narayama Bushikou to iu eiga desu.", "Ini film \"Ballad of Narayama\"."),
    ]),
    ("shou33_n1", "蕉", ["ショウ"], [], ["pohon pisang (dalam kata majemuk)", "banana plant"], 15, "艸", [
        ("芭蕉", "bashou", "pohon pisang/nama pujangga"),
        ("蕉風", "shoufuu", "gaya haiku Basho"),
        ("蕉葉", "shouyou", "daun pisang"),
    ], [
        ("蕉風俳句です。", "Shoufuu haiku desu.", "Ini haiku bergaya Basho."),
        ("蕉葉に包みました。", "Shouyou ni tsutsumimashita.", "Dibungkus daun pisang."),
    ]),
    ("kabuto_n1", "兜", [], ["かぶと"], ["helm samurai", "samurai helmet"], 11, "儿", [
        ("兜", "kabuto", "helm samurai"),
        ("兜虫", "kabutomushi", "kumbang badak"),
        ("兜町", "Kabutochou", "distrik keuangan Tokyo"),
    ], [
        ("兜をかぶりました。", "Kabuto o kaburimashita.", "Memakai helm samurai."),
        ("兜虫を捕まえました。", "Kabutomushi o tsukamaemashita.", "Menangkap kumbang badak."),
    ]),
    ("ka16_n1", "寡", ["カ"], [], ["sedikit", "janda", "few", "widow"], 14, "宀", [
        ("寡黙", "kamoku", "pendiam"),
        ("寡婦", "kafu", "janda"),
        ("多寡", "taka", "banyak sedikitnya"),
    ], [
        ("寡黙な人です。", "Kamoku na hito desu.", "Dia orang yang pendiam."),
        ("寡婦になりました。", "Kafu ni narimashita.", "Menjadi janda."),
    ]),
    ("ryuu7_n1", "琉", ["リュウ"], [], ["nama Kepulauan Ryukyu", "Ryukyu"], 11, "玉", [
        ("琉球", "Ryuukyuu", "Kepulauan Ryukyu/Okinawa"),
        ("琉球王国", "Ryuukyuu Oukoku", "Kerajaan Ryukyu"),
        ("琉璃", "ruri", "lapis lazuli"),
    ], [
        ("琉球王国の歴史です。", "Ryuukyuu Oukoku no rekishi desu.", "Ini sejarah Kerajaan Ryukyu."),
        ("琉球料理を食べました。", "Ryuukyuu ryouri o tabemashita.", "Makan masakan Ryukyu."),
    ]),
    ("ri6_n1", "痢", ["リ"], [], ["diare", "diarrhea"], 12, "疒", [
        ("下痢", "geri", "diare"),
        ("赤痢", "sekiri", "disentri"),
        ("疫痢", "ekiri", "disentri epidemi anak"),
    ], [
        ("下痢をしています。", "Geri o shite imasu.", "Sedang diare."),
        ("赤痢にかかりました。", "Sekiri ni kakarimashita.", "Terkena disentri."),
    ]),
    ("you10_n1", "庸", ["ヨウ"], [], ["biasa-biasa saja", "mediocre", "ordinary"], 11, "广", [
        ("中庸", "chuuyou", "jalan tengah"),
        ("凡庸", "bon-you", "biasa-biasa saja"),
        ("庸人", "youjin", "orang biasa"),
    ], [
        ("中庸を保っています。", "Chuuyou o tamotte imasu.", "Menjaga jalan tengah."),
        ("凡庸な作品です。", "Bon-you na sakuhin desu.", "Ini karya yang biasa-biasa saja."),
    ]),
    ("hou14_n1", "朋", ["ホウ"], ["とも"], ["teman", "friend", "companion"], 8, "月", [
        ("朋友", "houyuu", "sahabat"),
        ("朋輩", "houbai", "rekan seangkatan"),
        ("一朋", "ippou", "sesama teman"),
    ], [
        ("朋友との友情です。", "Houyuu to no yuujou desu.", "Ini persahabatan dengan sahabat."),
        ("朋輩と再会しました。", "Houbai to saikai shimashita.", "Bertemu kembali dengan rekan seangkatan."),
    ]),
    ("kou33_n1", "坑", ["コウ"], [], ["lubang tambang", "pit", "mine shaft"], 7, "土", [
        ("炭坑", "tankou", "tambang batu bara"),
        ("坑道", "koudou", "terowongan tambang"),
        ("坑夫", "kouhu", "penambang"),
    ], [
        ("炭坑で働いていました。", "Tankou de hataraite imashita.", "Bekerja di tambang batu bara."),
        ("坑道を歩きました。", "Koudou o arukimashita.", "Berjalan di terowongan tambang."),
    ]),
    ("ko8_n1", "姑", ["コ"], ["しゅうとめ"], ["ibu mertua", "mother-in-law"], 8, "女", [
        ("姑", "shuutome", "ibu mertua"),
        ("姑息", "kosoku", "cara sementara/licik"),
        ("舅姑", "kyuuko", "mertua laki-laki dan perempuan"),
    ], [
        ("姑と同居しています。", "Shuutome to doukyo shite imasu.", "Tinggal bersama ibu mertua."),
        ("姑息な手段です。", "Kosoku na shudan desu.", "Ini cara yang licik."),
    ]),
    ("u_n1", "烏", ["ウ"], ["からす"], ["burung gagak", "crow"], 10, "火", [
        ("烏", "karasu", "burung gagak"),
        ("烏合の衆", "ugou no shuu", "kerumunan tak terorganisir"),
        ("烏龍茶", "uuroncha", "teh oolong"),
    ], [
        ("烏が鳴いています。", "Karasu ga naite imasu.", "Burung gagak berkicau."),
        ("烏龍茶を飲みました。", "Uuroncha o nomimashita.", "Minum teh oolong."),
    ]),
    ("ran5_n1", "藍", ["ラン"], ["あい"], ["nila", "warna indigo", "indigo"], 18, "艸", [
        ("藍", "ai", "warna indigo"),
        ("藍染め", "aizome", "pewarnaan indigo"),
        ("出藍", "shutsuran", "murid melampaui guru"),
    ], [
        ("藍染めの着物です。", "Aizome no kimono desu.", "Ini kimono celup indigo."),
        ("出藍の誉れです。", "Shutsuran no homare desu.", "Ini kebanggaan murid yang melampaui gurunya."),
    ]),
    ("kyou15_n1", "僑", ["キョウ"], [], ["perantau (dalam kata majemuk)", "sojourner"], 14, "人", [
        ("華僑", "kakyou", "diaspora Tionghoa"),
        ("僑胞", "kyouhou", "sesama perantau"),
        ("老華僑", "rou kakyou", "diaspora Tionghoa generasi tua"),
    ], [
        ("華僑の商人です。", "Kakyou no shounin desu.", "Ini pedagang diaspora Tionghoa."),
        ("華僑社会があります。", "Kakyou shakai ga arimasu.", "Ada komunitas diaspora Tionghoa."),
    ]),
    ("zoku3_n1", "賊", ["ゾク"], [], ["pencuri", "pemberontak", "thief", "rebel"], 13, "貝", [
        ("盗賊", "touzoku", "perampok"),
        ("海賊", "kaizoku", "bajak laut"),
        ("賊軍", "zokugun", "pasukan pemberontak"),
    ], [
        ("盗賊に襲われました。", "Touzoku ni osowaremashita.", "Diserang perampok."),
        ("海賊船です。", "Kaizokusen desu.", "Ini kapal bajak laut."),
    ]),
    ("saku5_n1", "搾", ["サク"], ["しぼ-る"], ["memeras", "squeeze"], 13, "手", [
        ("搾る", "shiboru", "memeras"),
        ("搾取", "sakushu", "eksploitasi"),
        ("搾乳", "sakunyuu", "memerah susu"),
    ], [
        ("牛乳を搾りました。", "Gyuunyuu o shiborimashita.", "Memerah susu sapi."),
        ("搾取されています。", "Sakushu sarete imasu.", "Sedang dieksploitasi."),
    ]),
    ("en10_n1", "奄", ["エン"], [], ["tiba-tiba", "menutupi (nama)", "suddenly", "cover"], 8, "大", [
        ("奄美大島", "Amami Oushima", "nama pulau"),
        ("奄然", "enzen", "tiba-tiba"),
        ("奄有", "en-yuu", "menguasai seluruhnya"),
    ], [
        ("奄美大島に旅行しました。", "Amami Oushima ni ryokou shimashita.", "Berlibur ke Pulau Amami Oshima."),
        ("奄美群島です。", "Amami guntou desu.", "Ini Kepulauan Amami."),
    ]),
    ("kyuu12_n1", "臼", ["キュウ"], ["うす"], ["lesung", "mortar"], 6, "臼", [
        ("臼", "usu", "lesung"),
        ("石臼", "ishiusu", "lesung batu"),
        ("脱臼", "dakkyuu", "dislokasi sendi"),
    ], [
        ("臼で挽きました。", "Usu de hikimashita.", "Menggiling dengan lesung."),
        ("肩を脱臼しました。", "Kata o dakkyuu shimashita.", "Bahunya terkilir/dislokasi."),
    ]),
    ("han10_n1", "畔", ["ハン"], [], ["tepi sawah", "tepi danau", "edge of field", "shore"], 10, "田", [
        ("湖畔", "kohan", "tepi danau"),
        ("田畔", "denpan", "pematang sawah"),
        ("河畔", "kahan", "tepi sungai"),
    ], [
        ("湖畔を散歩しました。", "Kohan o sanpo shimashita.", "Berjalan-jalan di tepi danau."),
        ("河畔に座りました。", "Kahan ni suwarimashita.", "Duduk di tepi sungai."),
    ]),
    ("ryou10_n1", "遼", ["リョウ"], [], ["jauh", "Dinasti Liao", "distant"], 15, "辵", [
        ("遼遠", "ryouen", "sangat jauh"),
        ("遼寧", "Ryounei", "Provinsi Liaoning Tiongkok"),
        ("遼", "Ryou", "Dinasti Liao"),
    ], [
        ("遼遠な未来です。", "Ryouen na mirai desu.", "Ini masa depan yang sangat jauh."),
        ("遼寧省に行きました。", "Ryounei-shou ni ikimashita.", "Pergi ke Provinsi Liaoning."),
    ]),
    ("bai6_n1", "唄", ["バイ"], ["うた"], ["lagu tradisional", "song"], 10, "口", [
        ("唄", "uta", "lagu tradisional"),
        ("小唄", "kouta", "lagu pendek tradisional"),
        ("長唄", "nagauta", "lagu panjang tradisional"),
    ], [
        ("唄を歌いました。", "Uta o utaimashita.", "Menyanyikan lagu."),
        ("小唄を習っています。", "Kouta o naratte imasu.", "Belajar lagu pendek tradisional."),
    ]),
    ("kou34_n1", "孔", ["コウ"], [], ["lubang", "Confucius", "hole"], 4, "子", [
        ("孔子", "Koushi", "Confucius"),
        ("気孔", "kikou", "stomata/pori"),
        ("瞳孔", "doukou", "pupil mata"),
    ], [
        ("孔子の教えです。", "Koushi no oshie desu.", "Ini ajaran Konfusius."),
        ("瞳孔が開きました。", "Doukou ga hirakimashita.", "Pupil mata melebar."),
    ]),
    ("kitsu_n1", "橘", ["キツ"], ["たちばな"], ["jeruk mandarin liar (nama)", "mandarin orange"], 16, "木", [
        ("橘", "tachibana", "jeruk mandarin liar"),
        ("橘色", "tachibanairo", "warna oranye jeruk"),
        ("橘さん", "Tachibana-san", "contoh nama keluarga"),
    ], [
        ("橘の実がなりました。", "Tachibana no mi ga narimashita.", "Buah jeruk tachibana berbuah."),
        ("橘さんに会いました。", "Tachibana-san ni aimashita.", "Bertemu dengan Tachibana."),
    ]),
    ("sou20_n1", "漱", ["ソウ"], ["くちすす-ぐ", "うが-い"], ["berkumur", "gargle", "rinse"], 14, "水", [
        ("夏目漱石", "Natsume Souseki", "penulis terkenal"),
        ("漱石", "Souseki", "nama pena"),
        ("漱ぐ", "susugu", "berkumur"),
    ], [
        ("夏目漱石は有名な作家です。", "Natsume Souseki wa yuumei na sakka desu.", "Natsume Soseki adalah penulis terkenal."),
        ("口を漱ぎました。", "Kuchi o susugimashita.", "Berkumur."),
    ]),
    ("ro5_n1", "呂", ["ロ"], [], ["tulang punggung", "bak mandi", "spine"], 7, "口", [
        ("風呂", "furo", "bak mandi/pemandian"),
        ("風呂敷", "furoshiki", "kain pembungkus Jepang"),
        ("語呂合わせ", "goroawase", "permainan kata"),
    ], [
        ("風呂に入りました。", "Furo ni hairimashita.", "Mandi."),
        ("風呂敷で包みました。", "Furoshiki de tsutsumimashita.", "Membungkus dengan furoshiki."),
    ]),
    ("hinoki_n1", "桧", [], ["ひのき"], ["pohon cemara Jepang (variant 檜)", "Japanese cypress"], 11, "木", [
        ("桧", "hinoki", "pohon cemara Jepang"),
        ("桧風呂", "hinokiburo", "bak mandi kayu cemara"),
        ("桧舞台", "hinoki butai", "panggung kehormatan"),
    ], [
        ("桧風呂に入りました。", "Hinokiburo ni hairimashita.", "Mandi di bak kayu cemara."),
        ("桧舞台に立ちました。", "Hinoki butai ni tachimashita.", "Berdiri di panggung kehormatan."),
    ]),
    ("gou3_n1", "拷", ["ゴウ"], [], ["penyiksaan (dalam kata majemuk)", "torture"], 9, "手", [
        ("拷問", "goumon", "penyiksaan"),
        ("拷問室", "goumonshitsu", "ruang penyiksaan"),
        ("拷問具", "goumongu", "alat penyiksaan"),
    ], [
        ("拷問を受けました。", "Goumon o ukemashita.", "Menerima penyiksaan."),
        ("拷問室に入れられました。", "Goumonshitsu ni ireraremashita.", "Dimasukkan ke ruang penyiksaan."),
    ]),
    ("sou21_n1", "宋", ["ソウ"], [], ["Dinasti Song", "Song (Chinese dynasty)"], 7, "宀", [
        ("宋", "Sou", "Dinasti Song"),
        ("北宋", "Hokusou", "Dinasti Song Utara"),
        ("南宋", "Nansou", "Dinasti Song Selatan"),
    ], [
        ("宋の時代です。", "Sou no jidai desu.", "Ini era Dinasti Song."),
        ("北宋の絵画です。", "Hokusou no kaiga desu.", "Ini lukisan Dinasti Song Utara."),
    ]),
    ("jou11_n1", "嬢", ["ジョウ"], [], ["nona", "young lady"], 16, "女", [
        ("お嬢さん", "ojousan", "nona/anak perempuan orang"),
        ("令嬢", "reijou", "putri bangsawan"),
        ("嬢", "jou", "sebutan nona"),
    ], [
        ("お嬢さんですか。", "Ojousan desu ka.", "Apakah ini putri Anda."),
        ("令嬢のようです。", "Reijou no you desu.", "Seperti putri bangsawan."),
    ]),
    ("en11_n1", "苑", ["エン"], ["その"], ["taman", "garden"], 8, "艸", [
        ("苑", "sono", "taman (arkais)"),
        ("学苑", "gakuen", "taman pendidikan"),
        ("御苑", "gyoen", "taman kekaisaran"),
    ], [
        ("新宿御苑を訪れました。", "Shinjuku Gyoen o otozuremashita.", "Mengunjungi Taman Shinjuku Gyoen."),
        ("学苑の一部です。", "Gakuen no ichibu desu.", "Ini bagian dari kampus."),
    ]),
    ("son2_n1", "巽", ["ソン"], ["たつみ"], ["arah tenggara (I Ching, nama)", "southeast"], 12, "己", [
        ("巽", "tatsumi", "arah tenggara"),
        ("巽の方角", "tatsumi no hougaku", "arah tenggara"),
        ("巽風", "sonpuu", "angin dari tenggara"),
    ], [
        ("巽の方角に進みました。", "Tatsumi no hougaku ni susumimashita.", "Bergerak ke arah tenggara."),
        ("巽という地名です。", "Tatsumi to iu chimei desu.", "Ini nama tempat \"Tatsumi\"."),
    ]),
    ("to3_n1", "杜", ["ト"], ["もり"], ["hutan kuil", "grove", "forest"], 7, "木", [
        ("杜", "mori", "hutan kuil"),
        ("杜氏", "touji", "pembuat sake ahli"),
        ("杜の都", "mori no miyako", "kota hutan (julukan Sendai)"),
    ], [
        ("杜の都と呼ばれています。", "Mori no miyako to yobarete imasu.", "Disebut sebagai kota hutan."),
        ("杜氏として働いています。", "Touji toshite hataraite imasu.", "Bekerja sebagai pembuat sake ahli."),
    ]),
    ("kei18_n1", "渓", ["ケイ"], [], ["lembah sungai", "valley stream"], 11, "水", [
        ("渓谷", "keikoku", "ngarai/lembah"),
        ("渓流", "keiryuu", "aliran sungai pegunungan"),
        ("雪渓", "sekkei", "salju abadi di lembah gunung"),
    ], [
        ("渓谷を訪れました。", "Keikoku o otozuremashita.", "Mengunjungi ngarai."),
        ("渓流釣りをしました。", "Keiryuu tsuri o shimashita.", "Memancing di aliran sungai pegunungan."),
    ]),
    ("ou6_n1", "翁", ["オウ"], ["おきな"], ["kakek tua", "old man"], 10, "羽", [
        ("翁", "okina", "kakek tua (kehormatan)"),
        ("老翁", "rouou", "pria tua"),
        ("翁草", "okinagusa", "nama bunga pasque"),
    ], [
        ("翁の教えです。", "Okina no oshie desu.", "Ini ajaran orang tua bijak."),
        ("老翁が座っています。", "Rouou ga suwatte imasu.", "Pria tua sedang duduk."),
    ]),
    ("gei2_n1", "藝", ["ゲイ"], [], ["seni (bentuk tradisional 芸)", "art"], 18, "艸", [
        ("藝術", "geijutsu", "seni (variant tradisional)"),
        ("文藝", "bungei", "sastra"),
        ("演藝", "engei", "pertunjukan seni"),
    ], [
        ("藝術作品です。", "Geijutsu sakuhin desu.", "Ini karya seni."),
        ("文藝雑誌です。", "Bungei zasshi desu.", "Ini majalah sastra."),
    ]),
    ("ren3_n1", "廉", ["レン"], [], ["murah", "jujur", "cheap", "honest"], 13, "广", [
        ("廉価", "renka", "harga murah"),
        ("清廉", "seiren", "jujur dan bersih"),
        ("廉潔", "renketsu", "integritas"),
    ], [
        ("廉価版です。", "Renkaban desu.", "Ini edisi murah."),
        ("清廉な政治家です。", "Seiren na seijika desu.", "Ini politisi yang jujur dan bersih."),
    ]),
    ("ga7_n1", "牙", ["ガ"], ["きば"], ["taring", "fang"], 4, "牙", [
        ("牙", "kiba", "taring"),
        ("象牙", "zouge", "gading gajah"),
        ("牙城", "gajou", "benteng utama"),
    ], [
        ("牙をむきました。", "Kiba o mukimashita.", "Menunjukkan taring."),
        ("象牙の彫刻です。", "Zouge no choukoku desu.", "Ini ukiran gading gajah."),
    ]),
    ("kin6_n1", "謹", ["キン"], ["つつし-む"], ["hormat", "respectful", "discreet"], 17, "言", [
        ("謹んで", "tsutsushinde", "dengan hormat"),
        ("謹賀新年", "kinga shinnen", "selamat tahun baru (formal)"),
        ("謹慎", "kinshin", "penahanan diri/skorsing"),
    ], [
        ("謹んでお祝い申し上げます。", "Tsutsushinde oiwai moushiagemasu.", "Dengan hormat saya ucapkan selamat."),
        ("謹慎処分です。", "Kinshin shobun desu.", "Ini hukuman skorsing."),
    ]),
    ("dou4_n1", "瞳", ["ドウ"], ["ひとみ"], ["manik mata", "pupil"], 17, "目", [
        ("瞳", "hitomi", "manik mata"),
        ("瞳孔", "doukou", "pupil mata"),
        ("黒瞳", "kurohitomi", "mata hitam"),
    ], [
        ("瞳が美しいです。", "Hitomi ga utsukushii desu.", "Manik matanya indah."),
        ("瞳孔が開きました。", "Doukou ga hirakimashita.", "Pupil mata melebar."),
    ]),
    ("yuu12_n1", "湧", ["ユウ"], ["わ-く"], ["memancar", "gush", "well up"], 12, "水", [
        ("湧く", "waku", "memancar/muncul"),
        ("湧水", "yuusui", "mata air"),
        ("湧出", "yuushutsu", "pancaran"),
    ], [
        ("温泉が湧いています。", "Onsen ga waite imasu.", "Air panas memancar."),
        ("湧水を飲みました。", "Yuusui o nomimashita.", "Minum air dari mata air."),
    ]),
    ("kin7_n1", "欣", ["キン"], [], ["gembira (nama)", "joyful"], 8, "欠", [
        ("欣喜雀躍", "kinkijakuyaku", "sangat gembira"),
        ("欣然", "kinzen", "dengan senang hati"),
        ("欣也", "Yoshiya", "contoh nama pria"),
    ], [
        ("欣喜雀躍しました。", "Kinkijakuyaku shimashita.", "Sangat bergembira."),
        ("欣然として応じました。", "Kinzen to shite oujimashita.", "Menerima dengan senang hati."),
    ]),
    ("you11_n1", "窯", ["ヨウ"], ["かま"], ["tungku pembakaran", "kiln"], 15, "穴", [
        ("窯", "kama", "tungku"),
        ("窯元", "kamamoto", "pusat pembuatan keramik"),
        ("窯業", "yougyou", "industri keramik"),
    ], [
        ("窯で焼きました。", "Kama de yakimashita.", "Dibakar di tungku."),
        ("窯元を訪れました。", "Kamamoto o otozuremashita.", "Mengunjungi pusat pembuatan keramik."),
    ]),
    ("hou15_n1", "褒", ["ホウ"], ["ほ-める"], ["memuji", "praise"], 15, "衣", [
        ("褒める", "homeru", "memuji"),
        ("褒美", "houbi", "hadiah"),
        ("褒章", "houshou", "medali penghargaan"),
    ], [
        ("褒められました。", "Homeraremashita.", "Dipuji."),
        ("褒美をもらいました。", "Houbi o moraimashita.", "Mendapat hadiah."),
    ]),
    ("shuu13_n1", "醜", ["シュウ"], ["みにく-い"], ["buruk rupa", "ugly"], 17, "酉", [
        ("醜い", "minikui", "buruk rupa/jelek"),
        ("醜聞", "shuubun", "skandal"),
        ("醜態", "shuutai", "tingkah laku memalukan"),
    ], [
        ("醜い争いです。", "Minikui arasoi desu.", "Ini pertengkaran yang memalukan."),
        ("醜聞が広まりました。", "Shuubun ga hiromarimashita.", "Skandal menyebar."),
    ]),
    ("gi9_n1", "魏", ["ギ"], [], ["Dinasti Wei", "Wei (Chinese dynasty)"], 18, "鬼", [
        ("魏", "Gi", "Negara Wei zaman Tiga Negara"),
        ("魏志倭人伝", "Gishi Wajinden", "catatan tentang Jepang dalam sejarah Wei"),
        ("曹魏", "Sougi", "Wei Cao"),
    ], [
        ("魏志倭人伝という史料です。", "Gishi Wajinden to iu shiryou desu.", "Ini sumber sejarah \"Catatan Wei tentang Wa\"."),
        ("魏の国です。", "Gi no kuni desu.", "Ini Negara Wei."),
    ]),
    ("hen3_n1", "篇", ["ヘン"], [], ["bab", "penghitung buku", "chapter"], 15, "竹", [
        ("一篇", "ippen", "satu karya/bab"),
        ("詩篇", "shihen", "kumpulan puisi/Kitab Mazmur"),
        ("前篇", "zenpen", "bagian pertama"),
    ], [
        ("詩篇を読みました。", "Shihen o yomimashita.", "Membaca Kitab Mazmur."),
        ("前篇と後篇があります。", "Zenpen to kouhen ga arimasu.", "Ada bagian pertama dan kedua."),
    ]),
    ("shou34_n1", "升", ["ショウ"], ["ます"], ["kotak takar", "measuring box"], 4, "十", [
        ("升", "masu", "kotak takar"),
        ("一升瓶", "isshoubin", "botol satu shou"),
        ("升目", "masume", "ukuran/kotak takar"),
    ], [
        ("升で量りました。", "Masu de hakarimashita.", "Mengukur dengan kotak takar."),
        ("一升瓶を買いました。", "Isshoubin o kaimashita.", "Membeli botol satu shou."),
    ]),
    ("shi21_n1", "此", ["シ"], ["これ"], ["ini (klasik)", "this"], 6, "止", [
        ("此の", "kono", "ini (klasik)"),
        ("此処", "koko", "di sini (klasik)"),
        ("此度", "konotabi", "kali ini (formal)"),
    ], [
        ("此度はありがとうございます。", "Konotabi wa arigatou gozaimasu.", "Terima kasih kali ini."),
        ("此の事です。", "Kono koto desu.", "Ini soal ini."),
    ]),
    ("hou16_n1", "峯", ["ホウ"], ["みね"], ["puncak gunung (variant 峰)", "peak"], 10, "山", [
        ("峯", "mine", "puncak"),
        ("峯山", "Mineyama", "nama tempat"),
        ("峯岸", "Minegishi", "contoh nama keluarga"),
    ], [
        ("峯に登りました。", "Mine ni noborimashita.", "Mendaki puncak."),
        ("峯岸さんに会いました。", "Minegishi-san ni aimashita.", "Bertemu dengan Minegishi."),
    ]),
    ("jun8_n1", "殉", ["ジュン"], [], ["mengorbankan nyawa", "die for a cause"], 10, "歹", [
        ("殉職", "junshoku", "gugur dalam tugas"),
        ("殉教", "junkyou", "mati syahid"),
        ("殉死", "junshi", "mati mengikuti tuan"),
    ], [
        ("殉職しました。", "Junshoku shimashita.", "Gugur dalam tugas."),
        ("殉教者です。", "Junkyousha desu.", "Ini martir."),
    ]),
    ("han11_n1", "煩", ["ハン"], ["わずら-う", "わずら-わしい"], ["mengganggu", "annoying", "worry"], 13, "火", [
        ("煩わしい", "wazurawashii", "merepotkan"),
        ("煩悩", "bonnou", "hawa nafsu/keinginan duniawi"),
        ("煩雑", "hanzatsu", "rumit"),
    ], [
        ("煩わしい手続きです。", "Wazurawashii tetsuzuki desu.", "Ini prosedur yang merepotkan."),
        ("煩悩を捨てましょう。", "Bonnou o sutemashou.", "Mari buang hawa nafsu duniawi."),
    ]),
    ("ha5_n1", "巴", ["ハ"], ["ともえ"], ["pola pusaran heraldik", "comma-shaped swirl"], 4, "己", [
        ("巴", "tomoe", "pola pusaran"),
        ("巴投げ", "tomoenage", "teknik judo"),
        ("三つ巴", "mitsudomoe", "tiga pihak bersaing"),
    ], [
        ("巴投げをかけました。", "Tomoenage o kakemashita.", "Melakukan teknik tomoenage."),
        ("三つ巴の戦いです。", "Mitsudomoe no tatakai desu.", "Ini pertarungan tiga pihak."),
    ]),
    ("tei16_n1", "禎", ["テイ"], [], ["keberuntungan (nama)", "good fortune"], 13, "示", [
        ("禎祥", "teishou", "pertanda baik"),
        ("禎子", "Sachiko", "contoh nama wanita"),
        ("禎一", "Teiichi", "contoh nama pria"),
    ], [
        ("禎子さんに会いました。", "Sachiko-san ni aimashita.", "Bertemu dengan Sachiko."),
        ("禎一という名前です。", "Teiichi to iu namae desu.", "Ini nama Teiichi."),
    ]),
    ("chin5_n1", "枕", ["チン"], ["まくら"], ["bantal", "pillow"], 8, "木", [
        ("枕", "makura", "bantal"),
        ("枕元", "makuramoto", "sisi tempat tidur"),
        ("石枕", "ishimakura", "bantal batu"),
    ], [
        ("枕を使いました。", "Makura o tsukaimashita.", "Menggunakan bantal."),
        ("枕元に置きました。", "Makuramoto ni okimashita.", "Meletakkan di sisi tempat tidur."),
    ]),
    ("gai6_n1", "劾", ["ガイ"], [], ["memakzulkan (dalam kata majemuk)", "impeach"], 8, "力", [
        ("弾劾", "dangai", "pemakzulan"),
        ("弾劾裁判", "dangai saiban", "sidang pemakzulan"),
        ("弾劾訴追", "dangai soitsui", "penuntutan pemakzulan"),
    ], [
        ("弾劾されました。", "Dangai saremashita.", "Dimakzulkan."),
        ("弾劾裁判が行われました。", "Dangai saiban ga okonawaremashita.", "Sidang pemakzulan dilaksanakan."),
    ]),
    ("bo3_n1", "菩", ["ボ"], [], ["bodhi (dalam kata majemuk)", "bodhi"], 11, "艸", [
        ("菩薩", "bosatsu", "bodhisattva"),
        ("菩提", "bodai", "pencerahan Buddha"),
        ("菩提樹", "bodaiju", "pohon bodhi"),
    ], [
        ("菩提を弔いました。", "Bodai o tomuraimashita.", "Mendoakan arwah."),
        ("菩提樹の下で瞑想しました。", "Bodaiju no shita de meisou shimashita.", "Bermeditasi di bawah pohon bodhi."),
    ]),
    ("da3_n1", "堕", ["ダ"], [], ["jatuh", "merosot", "fall", "degenerate"], 12, "土", [
        ("堕落", "daraku", "kemerosotan moral"),
        ("堕胎", "datai", "aborsi"),
        ("堕天使", "datenshi", "malaikat jatuh"),
    ], [
        ("堕落した生活です。", "Daraku shita seikatsu desu.", "Ini kehidupan yang merosot."),
        ("堕天使のようです。", "Datenshi no you desu.", "Seperti malaikat jatuh."),
    ]),
    ("don_n1", "丼", [], ["どん"], ["mangkuk nasi berlauk", "rice bowl dish"], 5, "丶", [
        ("丼", "don", "mangkuk nasi berlauk"),
        ("牛丼", "gyuudon", "nasi daging sapi"),
        ("天丼", "tendon", "nasi tempura"),
    ], [
        ("牛丼を食べました。", "Gyuudon o tabemashita.", "Makan gyudon."),
        ("天丼が好きです。", "Tendon ga suki desu.", "Suka tendon."),
    ]),
    ("so9_n1", "租", ["ソ"], [], ["pajak", "tax", "rent"], 10, "禾", [
        ("租税", "sozei", "pajak"),
        ("租借", "soshaku", "konsesi sewa wilayah"),
        ("地租", "chiso", "pajak tanah"),
    ], [
        ("租税を納めました。", "Sozei o osamemashita.", "Membayar pajak."),
        ("租借地でした。", "Soshakuchi deshita.", "Ini adalah wilayah konsesi sewa."),
    ]),
    ("hinoki2_n1", "檜", [], ["ひのき"], ["pohon cemara Jepang", "Japanese cypress"], 17, "木", [
        ("檜", "hinoki", "pohon cemara Jepang"),
        ("檜舞台", "hinoki butai", "panggung kehormatan"),
        ("檜造り", "hinokizukuri", "konstruksi kayu cemara"),
    ], [
        ("檜の香りです。", "Hinoki no kaori desu.", "Ini aroma kayu cemara."),
        ("檜造りの家です。", "Hinokizukuri no ie desu.", "Ini rumah berkonstruksi kayu cemara."),
    ]),
    ("ryou11_n1", "稜", ["リョウ"], [], ["punggungan", "tepi", "ridge", "edge"], 13, "禾", [
        ("稜線", "ryousen", "garis punggungan gunung"),
        ("稜角", "ryoukaku", "sudut tajam"),
        ("丘稜", "kyuuryou", "perbukitan"),
    ], [
        ("稜線を歩きました。", "Ryousen o arukimashita.", "Berjalan di garis punggungan gunung."),
        ("稜角がはっきりしています。", "Ryoukaku ga hakkiri shite imasu.", "Sudutnya jelas."),
    ]),
    ("bou12_n1", "牟", ["ボウ"], [], ["mencari (nama)", "seek"], 6, "牛", [
        ("牟田", "Muta", "contoh nama keluarga"),
        ("釈迦牟尼", "Shakamuni", "Buddha Shakyamuni"),
        ("牟婁", "Muro", "nama daerah lama"),
    ], [
        ("牟田さんに会いました。", "Muta-san ni aimashita.", "Bertemu dengan Muta."),
        ("釈迦牟尼仏です。", "Shakamuni Butsu desu.", "Ini Buddha Shakyamuni."),
    ]),
    ("san4_n1", "桟", ["サン"], [], ["perancah", "dermaga", "scaffold", "pier"], 10, "木", [
        ("桟橋", "sanbashi", "dermaga"),
        ("桟敷", "sajiki", "tempat duduk bertingkat"),
        ("桟道", "sandou", "jalan setapak di tebing"),
    ], [
        ("桟橋に船が着きました。", "Sanbashi ni fune ga tsukimashita.", "Kapal tiba di dermaga."),
        ("桟敷席で見ました。", "Sajikiseki de mimashita.", "Menonton dari tempat duduk bertingkat."),
    ]),
    ("sakaki_n1", "榊", [], ["さかき"], ["pohon suci Shinto", "sacred tree"], 14, "木", [
        ("榊", "sakaki", "pohon suci Shinto"),
        ("榊原", "Sakakibara", "contoh nama keluarga"),
        ("榊立て", "sakakitate", "wadah untuk sakaki"),
    ], [
        ("榊を供えました。", "Sakaki o sonaemashita.", "Mempersembahkan ranting sakaki."),
        ("榊原さんに会いました。", "Sakakibara-san ni aimashita.", "Bertemu dengan Sakakibara."),
    ]),
    ("seki3_n1", "錫", ["セキ"], ["すず"], ["timah", "tin"], 16, "金", [
        ("錫", "suzu", "timah"),
        ("錫杖", "shakujou", "tongkat biksu Buddha"),
        ("錫箔", "sekihaku", "kertas timah"),
    ], [
        ("錫の器です。", "Suzu no utsuwa desu.", "Ini wadah timah."),
        ("錫杖を持っています。", "Shakujou o motte imasu.", "Membawa tongkat biksu."),
    ]),
    ("jin9_n1", "荏", ["ジン"], [], ["tanaman wijen liar (nama tempat)", "sesame plant"], 9, "艸", [
        ("荏苒", "jinzen", "berlalu perlahan"),
        ("荏原", "Ebara", "nama daerah di Tokyo"),
        ("荏胡麻", "egoma", "wijen perilla"),
    ], [
        ("荏原地区に住んでいます。", "Ebara chiku ni sunde imasu.", "Tinggal di daerah Ebara."),
        ("荏胡麻油を使いました。", "Egoma abura o tsukaimashita.", "Menggunakan minyak perilla."),
    ]),
    ("gu3_n1", "惧", ["グ"], [], ["khawatir (dalam kata majemuk)", "fear", "worry"], 11, "心", [
        ("危惧", "kigu", "kekhawatiran"),
        ("危惧種", "kigushu", "spesies terancam"),
        ("惧れ", "osore", "ketakutan"),
    ], [
        ("絶滅危惧種です。", "Zetsumetsu kigushu desu.", "Ini spesies terancam punah."),
        ("危惧しています。", "Kigu shite imasu.", "Mengkhawatirkan."),
    ]),
    ("wa2_n1", "倭", ["ワ"], [], ["sebutan Jepang kuno", "ancient Japan"], 10, "人", [
        ("倭", "Wa", "sebutan Jepang kuno"),
        ("倭国", "Wakoku", "Negeri Wa"),
        ("魏志倭人伝", "Gishi Wajinden", "catatan tentang Jepang dalam sejarah Wei"),
    ], [
        ("倭国という呼び名でした。", "Wakoku to iu yobina deshita.", "Ini disebut sebagai Negeri Wa."),
        ("古代の倭人です。", "Kodai no Wajin desu.", "Ini orang Wa kuno."),
    ]),
    ("sei14_n1", "婿", ["セイ"], ["むこ"], ["menantu laki-laki", "son-in-law", "groom"], 12, "女", [
        ("婿", "muko", "menantu laki-laki"),
        ("花婿", "hanamuko", "pengantin pria"),
        ("婿養子", "mukoyoushi", "menantu yang diadopsi"),
    ], [
        ("婿になりました。", "Muko ni narimashita.", "Menjadi menantu."),
        ("花婿が緊張しています。", "Hanamuko ga kinchou shite imasu.", "Pengantin pria gugup."),
    ]),
    ("bo4_n1", "慕", ["ボ"], ["した-う"], ["merindukan", "yearn for", "adore"], 14, "心", [
        ("慕う", "shitau", "merindukan/mengagumi"),
        ("敬慕", "keibo", "rasa hormat dan kagum"),
        ("追慕", "tsuibo", "mengenang dengan rindu"),
    ], [
        ("先生を慕っています。", "Sensei o shitatte imasu.", "Mengagumi guru."),
        ("敬慕の念です。", "Keibo no nen desu.", "Ini perasaan hormat dan kagum."),
    ]),
    ("byou3_n1", "廟", ["ビョウ"], [], ["kuil leluhur", "shrine", "temple"], 15, "广", [
        ("廟", "byou", "kuil leluhur"),
        ("孔子廟", "Koushibyou", "Kuil Konfusius"),
        ("宗廟", "soubyou", "kuil leluhur kerajaan"),
    ], [
        ("孔子廟を訪れました。", "Koushibyou o otozuremashita.", "Mengunjungi Kuil Konfusius."),
        ("宗廟に参りました。", "Soubyou ni mairimashita.", "Berziarah ke kuil leluhur kerajaan."),
    ]),
    ("chou23_n1", "銚", ["チョウ"], [], ["teko sake (dalam kata majemuk)", "sake pot"], 14, "金", [
        ("銚子", "choushi", "teko sake/nama kota di Chiba"),
        ("銚子市", "Choushi-shi", "Kota Choshi"),
        ("片口銚子", "katakuchi choushi", "teko sake bermoncong"),
    ], [
        ("銚子でお酒を注ぎました。", "Choushi de osake o sosogimashita.", "Menuang sake dengan teko."),
        ("銚子市に行きました。", "Choushi-shi ni ikimashita.", "Pergi ke Kota Choshi."),
    ]),
    ("hi10_n1", "斐", ["ヒ"], [], ["anggun (nama)", "elegant"], 12, "文", [
        ("斐然", "hizen", "cemerlang"),
        ("甲斐", "Kai", "nama daerah lama/berharga"),
        ("斐子", "Ayako", "contoh nama wanita"),
    ], [
        ("甲斐がありました。", "Kai ga arimashita.", "Ada gunanya/berharga."),
        ("甲斐の国です。", "Kai no kuni desu.", "Ini negeri Kai."),
    ]),
    ("hi11_n1", "罷", ["ヒ"], [], ["memberhentikan", "dismiss", "stop"], 15, "网", [
        ("罷免", "himen", "pemecatan"),
        ("罷業", "higyou", "pemogokan kerja"),
        ("罷免権", "himenken", "hak pemecatan"),
    ], [
        ("罷免されました。", "Himen saremashita.", "Dipecat."),
        ("罷業を行いました。", "Higyou o okonaimashita.", "Melakukan pemogokan."),
    ]),
    ("kyou16_n1", "矯", ["キョウ"], ["た-める"], ["meluruskan", "correct", "straighten"], 17, "矢", [
        ("矯正", "kyousei", "koreksi/pelurusan"),
        ("矯める", "tameru", "meluruskan"),
        ("奇矯", "kikyou", "eksentrik"),
    ], [
        ("歯列矯正をしています。", "Shiretsu kyousei o shite imasu.", "Menjalani perawatan kawat gigi."),
        ("性格を矯めました。", "Seikaku o tamemashita.", "Meluruskan karakter."),
    ]),
    ("bou13_n1", "某", ["ボウ"], ["それがし"], ["seseorang (tidak disebutkan)", "certain", "unnamed"], 9, "木", [
        ("某", "bou", "seseorang/tertentu"),
        ("某氏", "boushi", "orang tertentu"),
        ("某日", "boujitsu", "suatu hari"),
    ], [
        ("某氏からの手紙です。", "Boushi kara no tegami desu.", "Ini surat dari seseorang."),
        ("某日のことです。", "Boujitsu no koto desu.", "Ini kejadian pada suatu hari."),
    ]),
    ("shuu14_n1", "囚", ["シュウ"], [], ["tahanan", "prisoner"], 5, "囗", [
        ("囚人", "shuujin", "narapidana"),
        ("死刑囚", "shikeishuu", "terpidana mati"),
        ("囚われる", "torawareru", "tertawan"),
    ], [
        ("囚人になりました。", "Shuujin ni narimashita.", "Menjadi narapidana."),
        ("死刑囚です。", "Shikeishuu desu.", "Ini terpidana mati."),
    ]),
    ("kai9_n1", "魁", ["カイ"], ["さきがけ"], ["perintis", "leader", "pioneer"], 14, "鬼", [
        ("魁", "sakigake", "perintis"),
        ("巨魁", "kyokai", "pemimpin kejahatan besar"),
        ("首魁", "shukai", "pemimpin (kejahatan)"),
    ], [
        ("時代の魁です。", "Jidai no sakigake desu.", "Ini pelopor zaman."),
        ("首魁が逮捕されました。", "Shukai ga taiho saremashita.", "Pemimpin ditangkap."),
    ]),
    ("yabu_n1", "薮", [], ["やぶ"], ["semak belukar (variant 藪)", "thicket", "bush"], 16, "艸", [
        ("薮", "yabu", "semak belukar"),
        ("薮医者", "yabuisha", "dokter tidak becus"),
        ("薮蛇", "yabuhebi", "membuka masalah baru"),
    ], [
        ("薮の中に隠れました。", "Yabu no naka ni kakuremashita.", "Bersembunyi di dalam semak."),
        ("薮蛇になりました。", "Yabuhebi ni narimashita.", "Malah menimbulkan masalah baru."),
    ]),
    ("kou35_n1", "虹", ["コウ"], ["にじ"], ["pelangi", "rainbow"], 9, "虫", [
        ("虹", "niji", "pelangi"),
        ("虹色", "nijiiro", "warna-warni pelangi"),
        ("虹彩", "kousai", "iris mata"),
    ], [
        ("虹が出ました。", "Niji ga demashita.", "Pelangi muncul."),
        ("虹彩認証です。", "Kousai ninshou desu.", "Ini autentikasi iris mata."),
    ]),
    ("kou36_n1", "鴻", ["コウ"], [], ["burung besar (nama)", "large bird", "great"], 17, "鳥", [
        ("鴻毛", "koumou", "bulu angsa/hal remeh"),
        ("鴻恩", "kouon", "budi besar"),
        ("鴻池", "Kounoike", "contoh nama keluarga sejarah"),
    ], [
        ("鴻毛より軽いです。", "Koumou yori karui desu.", "Lebih ringan dari bulu angsa."),
        ("鴻池家という名門です。", "Kounoike-ke to iu meimon desu.", "Ini keluarga terpandang Konoike."),
    ]),
    ("hitsu_n1", "泌", ["ヒツ"], [], ["mengeluarkan cairan", "secrete"], 8, "水", [
        ("分泌", "bunpitsu", "sekresi"),
        ("泌尿器", "hinyouki", "organ urologi"),
        ("分泌物", "bunpitsubutsu", "hasil sekresi"),
    ], [
        ("ホルモンが分泌されました。", "Horumon ga bunpitsu saremashita.", "Hormon disekresikan."),
        ("泌尿器科に行きました。", "Hinyoukika ni ikimashita.", "Pergi ke bagian urologi."),
    ]),
    ("o_n1", "於", ["オ"], ["おい-て"], ["partikel klasik di/pada", "at", "in"], 8, "方", [
        ("於いて", "oite", "di/pada (klasik formal)"),
        ("於是", "oze", "maka (klasik)"),
        ("於ける", "okeru", "di dalam (klasik formal)"),
    ], [
        ("会議に於いて発表しました。", "Kaigi ni oite happyou shimashita.", "Mempresentasikan pada rapat."),
        ("日本に於ける文化です。", "Nihon ni okeru bunka desu.", "Ini budaya di Jepang."),
    ]),
    ("kyuu13_n1", "赳", ["キュウ"], [], ["gagah berani (nama)", "brave"], 9, "走", [
        ("赳々", "kyuukyuu", "gagah perkasa"),
        ("赳夫", "Takeo", "contoh nama pria"),
        ("赳", "Takeshi", "contoh nama pria"),
    ], [
        ("赳々たる武人です。", "Kyuukyuu taru bujin desu.", "Ini prajurit yang gagah perkasa."),
        ("福田赳夫は元首相です。", "Fukuda Takeo wa moto shushou desu.", "Fukuda Takeo adalah mantan perdana menteri."),
    ]),
    ("zen3_n1", "漸", ["ゼン"], ["ようや-く"], ["berangsur-angsur", "gradually"], 14, "水", [
        ("漸く", "youyaku", "akhirnya/berangsur"),
        ("漸進", "zenshin", "kemajuan bertahap"),
        ("漸増", "zenzou", "peningkatan bertahap"),
    ], [
        ("漸く完成しました。", "Youyaku kansei shimashita.", "Akhirnya selesai."),
        ("漸進的な改革です。", "Zenshinteki na kaikaku desu.", "Ini reformasi bertahap."),
    ]),
    ("hou17_n1", "逢", ["ホウ"], ["あ-う"], ["bertemu (variant 会う)", "meet"], 10, "辵", [
        ("逢う", "au", "bertemu"),
        ("逢瀬", "ouse", "pertemuan rahasia kekasih"),
        ("逢引き", "aibiki", "kencan rahasia"),
    ], [
        ("運命的に逢いました。", "Unmeiteki ni aimashita.", "Bertemu secara takdir."),
        ("逢瀬を重ねました。", "Ouse o kasanemashita.", "Berkali-kali bertemu diam-diam."),
    ]),
    ("tako_n1", "凧", [], ["たこ"], ["layang-layang", "kite"], 5, "几", [
        ("凧", "tako", "layang-layang"),
        ("凧揚げ", "takoage", "menerbangkan layang-layang"),
        ("凧糸", "takoito", "benang layang-layang"),
    ], [
        ("凧を揚げました。", "Tako o agemashita.", "Menerbangkan layang-layang."),
        ("凧揚げをしました。", "Takoage o shimashita.", "Bermain layang-layang."),
    ]),
    ("u2_n1", "鵜", [], ["う"], ["burung kormoran", "cormorant"], 18, "鳥", [
        ("鵜", "u", "burung kormoran"),
        ("鵜飼い", "ukai", "memancing dengan kormoran"),
        ("鵜呑み", "unomi", "menelan bulat-bulat/percaya tanpa mikir"),
    ], [
        ("鵜飼いを見ました。", "Ukai o mimashita.", "Menonton pemancingan kormoran."),
        ("鵜呑みにしないでください。", "Unomi ni shinaide kudasai.", "Jangan langsung percaya begitu saja."),
    ]),
    ("an2_n1", "庵", ["アン"], ["いおり"], ["pondok pertapa", "hermitage", "hut"], 11, "广", [
        ("庵", "iori", "pondok"),
        ("芭蕉庵", "Bashouan", "nama pondok Matsuo Basho"),
        ("草庵", "souan", "gubuk sederhana"),
    ], [
        ("庵に住んでいます。", "Iori ni sunde imasu.", "Tinggal di pondok."),
        ("草庵で暮らしています。", "Souan de kurashite imasu.", "Hidup di gubuk sederhana."),
    ]),
    ("zen4_n1", "膳", ["ゼン"], [], ["nampan makan", "meal tray"], 16, "肉", [
        ("膳", "zen", "nampan makan"),
        ("食膳", "shokuzen", "meja makan"),
        ("配膳", "haizen", "penyajian makanan"),
    ], [
        ("膳を用意しました。", "Zen o youi shimashita.", "Menyiapkan nampan makan."),
        ("配膳しました。", "Haizen shimashita.", "Menyajikan makanan."),
    ]),
    ("ka17_n1", "蚊", ["ブン"], ["か"], ["nyamuk", "mosquito"], 10, "虫", [
        ("蚊", "ka", "nyamuk"),
        ("蚊帳", "kaya", "kelambu"),
        ("蚊取り線香", "katorisenkou", "obat nyamuk bakar"),
    ], [
        ("蚊に刺されました。", "Ka ni sasaremashita.", "Digigit nyamuk."),
        ("蚊取り線香を焚きました。", "Katorisenkou o takimashita.", "Membakar obat nyamuk."),
    ]),
    ("ki26_n1", "葵", ["キ"], ["あおい"], ["bunga hollyhock", "hollyhock"], 12, "艸", [
        ("葵", "aoi", "bunga hollyhock"),
        ("葵祭", "Aoi Matsuri", "festival Aoi di Kyoto"),
        ("徳川葵", "Tokugawa Aoi", "lambang keluarga Tokugawa"),
    ], [
        ("葵祭を見ました。", "Aoi Matsuri o mimashita.", "Menonton Festival Aoi."),
        ("徳川葵の紋章です。", "Tokugawa Aoi no monshou desu.", "Ini lambang keluarga Tokugawa."),
    ]),
    ("yaku3_n1", "厄", ["ヤク"], [], ["sial", "misfortune", "calamity"], 4, "厂", [
        ("厄年", "yakudoshi", "tahun sial"),
        ("厄介", "yakkai", "merepotkan"),
        ("災厄", "saiyaku", "malapetaka"),
    ], [
        ("今年は厄年です。", "Kotoshi wa yakudoshi desu.", "Tahun ini adalah tahun sial."),
        ("厄介な問題です。", "Yakkai na mondai desu.", "Ini masalah yang merepotkan."),
    ]),
    ("sou22_n1", "藻", ["ソウ"], ["も"], ["alga", "seaweed"], 19, "艸", [
        ("藻", "mo", "alga"),
        ("海藻", "kaisou", "rumput laut"),
        ("藻類", "souirui", "kelompok alga"),
    ], [
        ("藻が生えています。", "Mo ga haete imasu.", "Alga tumbuh."),
        ("海藻を食べました。", "Kaisou o tabemashita.", "Makan rumput laut."),
    ]),
    ("man3_n1", "萬", ["マン", "バン"], [], ["sepuluh ribu (bentuk tradisional 万)", "ten thousand"], 12, "艸", [
        ("萬歳", "banzai", "hidup!/sepuluh ribu tahun"),
        ("萬葉集", "Man-youshuu", "koleksi puisi Jepang kuno"),
        ("萬年筆", "mannenhitsu", "pena bulu"),
    ], [
        ("萬葉集を学んでいます。", "Man-youshuu o manande imasu.", "Mempelajari Man'yoshu."),
        ("萬歳三唱をしました。", "Banzai sanshou o shimashita.", "Meneriakkan banzai tiga kali."),
    ]),
    ("roku_n1", "禄", ["ロク"], [], ["gaji", "rezeki", "stipend", "fortune"], 12, "示", [
        ("禄高", "rokudaka", "jumlah gaji feodal"),
        ("俸禄", "houroku", "gaji pejabat"),
        ("福禄寿", "Fukurokuju", "dewa keberuntungan Jepang"),
    ], [
        ("禄高が決まりました。", "Rokudaka ga kimarimashita.", "Jumlah gaji feodal ditentukan."),
        ("福禄寿という神様です。", "Fukurokuju to iu kamisama desu.", "Ini dewa Fukurokuju."),
    ]),
    ("mou4_n1", "孟", ["モウ"], [], ["sulung", "Mencius (nama)", "eldest"], 8, "子", [
        ("孟子", "Moushi", "Mencius"),
        ("孟春", "moushun", "awal musim semi"),
        ("孟母三遷", "moubosansen", "tiga kali pindah ibu Mencius"),
    ], [
        ("孟子の教えです。", "Moushi no oshie desu.", "Ini ajaran Mencius."),
        ("孟母三遷という故事です。", "Moubosansen to iu koji desu.", "Ini kisah \"tiga kali pindah ibu Mencius\"."),
    ]),
    ("gan4_n1", "鴈", ["ガン"], ["かり"], ["angsa liar (variant 雁)", "wild goose"], 15, "鳥", [
        ("鴈", "kari", "angsa liar"),
        ("鴈金", "Karigane", "contoh nama"),
        ("鴈治郎", "Ganjirou", "nama panggung aktor kabuki"),
    ], [
        ("鴈が飛んでいます。", "Kari ga tonde imasu.", "Angsa liar sedang terbang."),
        ("鴈治郎という名前の役者です。", "Ganjirou to iu namae no yakusha desu.", "Ini aktor bernama Ganjiro."),
    ]),
    ("rou6_n1", "狼", ["ロウ"], ["おおかみ"], ["serigala", "wolf"], 10, "犬", [
        ("狼", "ookami", "serigala"),
        ("狼狽", "roubai", "kebingungan panik"),
        ("一匹狼", "ippiki ookami", "penyendiri"),
    ], [
        ("狼に注意してください。", "Ookami ni chuui shite kudasai.", "Waspadalah terhadap serigala."),
        ("狼狽しました。", "Roubai shimashita.", "Menjadi bingung panik."),
    ]),
    ("teki4_n1", "嫡", ["テキ"], [], ["pewaris sah", "legitimate heir"], 14, "女", [
        ("嫡子", "chakushi", "anak sulung sah"),
        ("嫡出", "chakushutsu", "kelahiran sah"),
        ("廃嫡", "haichaku", "pencabutan hak waris"),
    ], [
        ("嫡子として生まれました。", "Chakushi toshite umaremashita.", "Lahir sebagai anak sulung sah."),
        ("廃嫡されました。", "Haichaku saremashita.", "Dicabut hak warisnya."),
    ]),
    ("ju5_n1", "呪", ["ジュ"], ["のろ-う", "まじな-う"], ["kutukan", "curse", "spell"], 8, "口", [
        ("呪う", "norou", "mengutuk"),
        ("呪文", "jumon", "mantra"),
        ("呪縛", "jubaku", "mantra/keterikatan psikologis"),
    ], [
        ("呪いをかけました。", "Noroi o kakemashita.", "Memberikan kutukan."),
        ("呪文を唱えました。", "Jumon o tonaemashita.", "Merapal mantra."),
    ]),
    ("zan2_n1", "斬", ["ザン"], ["き-る"], ["membacok", "slash", "cut"], 11, "斤", [
        ("斬る", "kiru", "membacok"),
        ("斬新", "zanshin", "sangat baru/segar"),
        ("斬首", "zanshu", "pemenggalan"),
    ], [
        ("刀で斬りました。", "Katana de kirimashita.", "Membacok dengan pedang."),
        ("斬新なアイデアです。", "Zanshin na aidea desu.", "Ini ide yang sangat segar."),
    ]),
    ("sen13_n1", "尖", ["セン"], ["とが-る"], ["runcing", "sharp", "pointed"], 6, "小", [
        ("尖る", "togaru", "runcing"),
        ("尖端", "sentan", "ujung tajam/mutakhir"),
        ("尖塔", "sentou", "menara runcing"),
    ], [
        ("鉛筆が尖っています。", "Enpitsu ga togatte imasu.", "Pensilnya runcing."),
        ("尖端技術です。", "Sentan gijutsu desu.", "Ini teknologi mutakhir."),
    ]),
    ("gan5_n1", "翫", ["ガン"], [], ["menikmati (kata majemuk)", "enjoy", "toy with"], 13, "羽", [
        ("翫弄", "ganrou", "mempermainkan"),
        ("愛翫", "aigan", "kesayangan"),
        ("翫味", "ganmi", "menikmati rasa"),
    ], [
        ("愛翫動物です。", "Aigan doubutsu desu.", "Ini hewan peliharaan kesayangan."),
        ("翫味しました。", "Ganmi shimashita.", "Menikmati rasanya."),
    ]),
    ("gaku2_n1", "嶽", ["ガク"], ["たけ"], ["puncak gunung (bentuk tradisional 岳)", "mountain peak"], 17, "山", [
        ("嶽", "take", "puncak gunung"),
        ("山嶽", "sangaku", "pegunungan"),
        ("御嶽山", "Ontakesan", "nama gunung"),
    ], [
        ("御嶽山に登りました。", "Ontakesan ni noborimashita.", "Mendaki Gunung Ontake."),
        ("山嶽地帯です。", "Sangaku chitai desu.", "Ini wilayah pegunungan."),
    ]),
    ("gyou4_n1", "尭", ["ギョウ"], [], ["tinggi", "Kaisar Yao (nama)", "high"], 8, "儿", [
        ("尭舜", "Gyoushun", "Kaisar Yao dan Shun, tokoh legendaris Tiongkok"),
        ("尭", "Takashi", "contoh nama pria"),
        ("尭王", "Gyouou", "Raja Yao"),
    ], [
        ("尭舜の時代です。", "Gyoushun no jidai desu.", "Ini era Yao dan Shun."),
        ("尭という名前です。", "Takashi to iu namae desu.", "Ini nama Takashi."),
    ]),
    ("en12_n1", "怨", ["エン"], ["うら-む"], ["dendam", "grudge", "resentment"], 9, "心", [
        ("怨む", "uramu", "mendendam"),
        ("怨恨", "enkon", "dendam"),
        ("怨霊", "onryou", "roh pendendam"),
    ], [
        ("怨恨による犯行です。", "Enkon ni yoru hankou desu.", "Ini kejahatan karena dendam."),
        ("怨霊が出るという噂です。", "Onryou ga deru to iu uwasa desu.", "Ada rumor roh pendendam muncul."),
    ]),
    ("kei19_n1", "卿", ["ケイ"], [], ["gelar bangsawan", "lord", "minister"], 12, "卩", [
        ("卿", "kei", "gelar bangsawan"),
        ("枢機卿", "suukikei", "kardinal"),
        ("公卿", "kugyou", "bangsawan istana"),
    ], [
        ("卿という称号です。", "Kei to iu shougou desu.", "Ini gelar \"kei\"."),
        ("枢機卿になりました。", "Suukikei ni narimashita.", "Menjadi kardinal."),
    ]),
    ("kan31_n1", "串", ["カン"], ["くし"], ["tusuk sate", "skewer"], 7, "丨", [
        ("串", "kushi", "tusuk sate"),
        ("串焼き", "kushiyaki", "sate panggang"),
        ("串カツ", "kushikatsu", "sate goreng tepung"),
    ], [
        ("串焼きを食べました。", "Kushiyaki o tabemashita.", "Makan sate panggang."),
        ("串カツが好きです。", "Kushikatsu ga suki desu.", "Suka kushikatsu."),
    ]),
    ("i10_n1", "已", ["イ"], ["すで-に"], ["sudah (klasik)", "already", "stop"], 3, "己", [
        ("已に", "sude ni", "sudah (classical variant)"),
        ("已む", "yamu", "berhenti (classical variant)"),
        ("已然形", "izenkei", "bentuk perfektif (istilah gramatikal klasik)"),
    ], [
        ("已然形という文法用語です。", "Izenkei to iu bunpou yougo desu.", "Ini istilah gramatikal \"izenkei\"."),
        ("已にやりました。", "Sude ni yarimashita.", "Sudah dilakukan."),
    ]),
    ("kaku10_n1", "嚇", ["カク"], [], ["mengancam (dalam kata majemuk)", "threaten"], 17, "口", [
        ("威嚇", "ikaku", "ancaman/intimidasi"),
        ("嚇怒", "kakudo", "kemarahan besar"),
        ("威嚇射撃", "ikaku shageki", "tembakan peringatan"),
    ], [
        ("威嚇射撃をしました。", "Ikaku shageki o shimashita.", "Melakukan tembakan peringatan."),
        ("威嚇的な態度です。", "Ikakuteki na taido desu.", "Ini sikap yang mengancam."),
    ]),
    ("shi22_n1", "巳", ["シ"], ["み"], ["shio ular", "snake zodiac"], 3, "己", [
        ("巳", "mi", "tahun ular dalam zodiak"),
        ("巳年", "midoshi", "tahun ular"),
        ("上巳", "joushi", "festival Hinamatsuri kuno"),
    ], [
        ("巳年生まれです。", "Midoshi umare desu.", "Lahir di tahun ular."),
        ("上巳の節句です。", "Joushi no sekku desu.", "Ini festival Joshi."),
    ]),
    ("totsu_n1", "凸", ["トツ"], [], ["cembung", "convex", "protruding"], 5, "凵", [
        ("凸レンズ", "totsu renzu", "lensa cembung"),
        ("凹凸", "outotsu", "tidak rata"),
        ("凸版印刷", "toppan insatsu", "cetak relief"),
    ], [
        ("凸レンズを使いました。", "Totsu renzu o tsukaimashita.", "Menggunakan lensa cembung."),
        ("道が凹凸しています。", "Michi ga outotsu shite imasu.", "Jalannya tidak rata."),
    ]),
    ("chou24_n1", "暢", ["チョウ"], [], ["lancar", "smooth", "expressive"], 14, "日", [
        ("流暢", "ryuuchou", "fasih"),
        ("暢気", "nonki", "santai"),
        ("暢達", "choutatsu", "kelancaran"),
    ], [
        ("流暢な英語です。", "Ryuuchou na eigo desu.", "Ini bahasa Inggris yang fasih."),
        ("暢気な性格です。", "Nonki na seikaku desu.", "Kepribadian yang santai."),
    ]),
    ("shu7_n1", "腫", ["シュ"], ["は-れる", "は-らす"], ["bengkak", "swell", "tumor"], 13, "肉", [
        ("腫れる", "hareru", "bengkak"),
        ("腫瘍", "shuyou", "tumor"),
        ("水腫", "suishu", "edema"),
    ], [
        ("足が腫れています。", "Ashi ga harete imasu.", "Kakinya bengkak."),
        ("腫瘍が見つかりました。", "Shuyou ga mitsukarimashita.", "Ditemukan tumor."),
    ]),
    ("zoku4_n1", "粟", ["ゾク"], ["あわ"], ["jewawut", "millet"], 12, "米", [
        ("粟", "awa", "jewawut"),
        ("粟粒", "awatsubu", "butir jewawut/jerawat kecil"),
        ("粟餅", "awamochi", "kue mochi jewawut"),
    ], [
        ("粟を栽培しています。", "Awa o saibai shite imasu.", "Membudidayakan jewawut."),
        ("粟餅を食べました。", "Awamochi o tabemashita.", "Makan kue mochi jewawut."),
    ]),
    ("en13_n1", "燕", ["エン"], ["つばめ"], ["burung layang-layang", "swallow"], 16, "火", [
        ("燕", "tsubame", "burung layang-layang"),
        ("燕尾服", "enbifuku", "jas ekor walet"),
        ("燕京", "Enkyou", "nama lama Beijing"),
    ], [
        ("燕が飛んでいます。", "Tsubame ga tonde imasu.", "Burung layang-layang terbang."),
        ("燕尾服を着ました。", "Enbifuku o kimashita.", "Memakai jas ekor walet."),
    ]),
    ("in5_n1", "韻", ["イン"], [], ["rima", "rhyme", "sound"], 19, "音", [
        ("韻", "in", "rima"),
        ("押韻", "ouin", "berima"),
        ("余韻", "yoin", "gema/kesan yang tersisa"),
    ], [
        ("韻を踏みました。", "In o fumimashita.", "Membuat rima."),
        ("余韻が残りました。", "Yoin ga nokorimashita.", "Kesan masih tersisa."),
    ]),
    ("tei17_n1", "綴", ["テイ"], ["つづ-る", "と-じる"], ["menjilid", "mengeja", "bind", "spell"], 14, "糸", [
        ("綴る", "tsuzuru", "mengeja/merangkai kata"),
        ("綴じる", "tojiru", "menjilid"),
        ("綴り", "tsuzuri", "ejaan"),
    ], [
        ("言葉を綴りました。", "Kotoba o tsuzurimashita.", "Merangkai kata-kata."),
        ("書類を綴じました。", "Shorui o tojimashita.", "Menjilid dokumen."),
    ]),
    ("shoku5_n1", "埴", ["ショク"], ["はに"], ["tanah liat (nama tempat)", "clay"], 10, "土", [
        ("埴輪", "haniwa", "patung tanah liat kuno Jepang"),
        ("埴生", "Hanyuu", "nama tempat"),
        ("埴土", "shokudo", "tanah liat (istilah geologi)"),
    ], [
        ("埴輪を発掘しました。", "Haniwa o hakkutsu shimashita.", "Menggali patung tanah liat haniwa."),
        ("埴生の宿です。", "Hanyuu no yado desu.", "Ini rumah sederhana (dari lagu terkenal)."),
    ]),
    ("sou23_n1", "霜", ["ソウ"], ["しも"], ["embun beku", "frost"], 17, "雨", [
        ("霜", "shimo", "embun beku"),
        ("霜降り", "shimofuri", "marbling daging/embun beku turun"),
        ("初霜", "hatsujimo", "embun beku pertama"),
    ], [
        ("霜が降りました。", "Shimo ga furimashita.", "Embun beku turun."),
        ("霜降り肉です。", "Shimofuri niku desu.", "Ini daging marbling."),
    ]),
    ("hei7_n1", "餅", ["ヘイ"], ["もち"], ["kue beras ketan", "rice cake"], 15, "食", [
        ("餅", "mochi", "kue beras ketan"),
        ("餅つき", "mochitsuki", "menumbuk mochi"),
        ("尻餅", "shirimochi", "jatuh terduduk"),
    ], [
        ("餅を食べました。", "Mochi o tabemashita.", "Makan mochi."),
        ("餅つきをしました。", "Mochitsuki o shimashita.", "Menumbuk mochi."),
    ]),
    ("ro6_n1", "魯", ["ロ"], [], ["Negara Lu", "bodoh", "Lu (ancient Chinese state)"], 15, "魚", [
        ("魯", "Ro", "Negara Lu tempat kelahiran Konfusius"),
        ("魯鈍", "rodon", "tumpul/bodoh"),
        ("魯迅", "Rojin", "Lu Xun, penulis Tiongkok terkenal"),
    ], [
        ("魯という国の出身です。", "Ro to iu kuni no shusshin desu.", "Berasal dari Negara Lu."),
        ("魯迅は有名な作家です。", "Rojin wa yuumei na sakka desu.", "Lu Xun adalah penulis terkenal."),
    ]),
    ("shou35_n1", "硝", ["ショウ"], [], ["nitrat", "kaca (dalam kata majemuk)", "nitrate", "glass"], 12, "石", [
        ("硝酸", "shousan", "asam nitrat"),
        ("硝石", "shouseki", "sendawa"),
        ("硝子", "garasu", "kaca"),
    ], [
        ("硝酸は危険です。", "Shousan wa kiken desu.", "Asam nitrat berbahaya."),
        ("硝子の器です。", "Garasu no utsuwa desu.", "Ini wadah kaca."),
    ]),
    ("bo5_n1", "牡", ["ボ"], ["おす"], ["jantan", "male (animal)"], 7, "牛", [
        ("牡", "osu", "jantan"),
        ("牡丹", "botan", "bunga peony"),
        ("牡蠣", "kaki", "tiram"),
    ], [
        ("牡の猫です。", "Osu no neko desu.", "Ini kucing jantan."),
        ("牡丹の花が咲きました。", "Botan no hana ga sakimashita.", "Bunga peony mekar."),
    ]),
    ("cho2_n1", "箸", ["チョ"], ["はし"], ["sumpit", "chopsticks"], 15, "竹", [
        ("箸", "hashi", "sumpit"),
        ("割り箸", "waribashi", "sumpit sekali pakai"),
        ("箸置き", "hashioki", "sandaran sumpit"),
    ], [
        ("箸を使いました。", "Hashi o tsukaimashita.", "Menggunakan sumpit."),
        ("割り箸をもらいました。", "Waribashi o moraimashita.", "Mendapat sumpit sekali pakai."),
    ]),
    ("choku_n1", "勅", ["チョク"], [], ["dekrit kaisar", "imperial edict"], 9, "力", [
        ("勅令", "chokurei", "dekrit kekaisaran"),
        ("勅使", "chokushi", "utusan kaisar"),
        ("詔勅", "shouchoku", "dekrit kekaisaran resmi"),
    ], [
        ("勅令が出されました。", "Chokurei ga dasaremashita.", "Dekrit kekaisaran dikeluarkan."),
        ("勅使が到着しました。", "Chokushi ga touchaku shimashita.", "Utusan kaisar tiba."),
    ]),
    ("kin8_n1", "芹", ["キン"], ["せり"], ["peterseli Jepang", "Japanese parsley"], 7, "艸", [
        ("芹", "seri", "peterseli Jepang"),
        ("芹摘み", "serizumi", "memetik seri"),
        ("芹沢", "Serizawa", "contoh nama keluarga"),
    ], [
        ("芹を摘みました。", "Seri o tsumimashita.", "Memetik seri."),
        ("芹沢さんに会いました。", "Serizawa-san ni aimashita.", "Bertemu dengan Serizawa."),
    ]),
    ("kyou17_n1", "杏", ["キョウ"], ["あんず"], ["buah aprikot", "apricot"], 7, "木", [
        ("杏", "anzu", "buah aprikot"),
        ("杏仁豆腐", "annindoufu", "puding almond"),
        ("杏林", "kyourin", "dunia kedokteran"),
    ], [
        ("杏を食べました。", "Anzu o tabemashita.", "Makan aprikot."),
        ("杏仁豆腐が好きです。", "Annindoufu ga suki desu.", "Suka puding almond."),
    ]),
    ("ka18_n1", "迦", ["カ"], [], ["istilah Buddhis (dalam kata majemuk)"], 8, "辵", [
        ("釈迦", "Shaka", "Buddha Shakyamuni"),
        ("釈迦牟尼", "Shakamuni", "Buddha Shakyamuni"),
        ("迦葉", "Kashou", "murid Buddha Kashyapa"),
    ], [
        ("釈迦の教えです。", "Shaka no oshie desu.", "Ini ajaran Buddha."),
        ("迦葉尊者です。", "Kashou sonja desu.", "Ini Yang Mulia Kashyapa."),
    ]),
    ("kan32_n1", "棺", ["カン"], [], ["peti mati", "coffin"], 12, "木", [
        ("棺", "kan", "peti mati"),
        ("棺桶", "kan-oke", "peti mati"),
        ("石棺", "sekkan", "sarkofagus batu"),
    ], [
        ("棺に納めました。", "Kan ni osamemashita.", "Dimasukkan ke peti mati."),
        ("石棺が発見されました。", "Sekkan ga hakken saremashita.", "Sarkofagus batu ditemukan."),
    ]),
    ("ju6_n1", "儒", ["ジュ"], [], ["sarjana Konfusius", "Confucian scholar"], 16, "人", [
        ("儒教", "jukyou", "Konfusianisme"),
        ("儒学", "jugaku", "ilmu Konfusius"),
        ("儒者", "jusha", "sarjana Konfusius"),
    ], [
        ("儒教の教えです。", "Jukyou no oshie desu.", "Ini ajaran Konfusianisme."),
        ("儒学を学んでいます。", "Jugaku o manande imasu.", "Mempelajari ilmu Konfusius."),
    ]),
    ("hou18_n1", "鳳", ["ホウ"], [], ["burung phoenix (nama)", "phoenix"], 14, "鳥", [
        ("鳳凰", "houou", "burung phoenix"),
        ("鳳仙花", "housenka", "bunga pacar air"),
        ("鳳来", "Hourai", "nama tempat"),
    ], [
        ("鳳凰が描かれています。", "Houou ga egakarete imasu.", "Burung phoenix digambarkan."),
        ("鳳仙花が咲きました。", "Housenka ga sakimashita.", "Bunga pacar air mekar."),
    ]),
    ("kei20_n1", "馨", ["ケイ"], ["かお-る"], ["harum (nama)", "fragrant"], 20, "香", [
        ("馨しい", "kagubashii", "harum"),
        ("馨", "Kaoru", "contoh nama"),
        ("芳馨", "houkei", "keharuman"),
    ], [
        ("馨さんに会いました。", "Kaoru-san ni aimashita.", "Bertemu dengan Kaoru."),
        ("芳馨が漂っています。", "Houkei ga tadayotte imasu.", "Keharuman menyebar."),
    ]),
    ("han12_n1", "斑", ["ハン"], ["まだら"], ["bercak", "spot", "patch"], 12, "文", [
        ("斑", "madara", "bercak"),
        ("斑点", "hanten", "titik bercak"),
        ("斑猫", "hanmyou", "kumbang tiger"),
    ], [
        ("斑模様です。", "Madara moyou desu.", "Ini pola bercak."),
        ("斑点があります。", "Hanten ga arimasu.", "Ada titik bercak."),
    ]),
    ("in6_n1", "蔭", ["イン"], ["かげ"], ["bayangan (variant 陰)", "shade"], 14, "艸", [
        ("蔭", "kage", "bayangan"),
        ("お蔭様で", "okagesama de", "berkat bantuan Anda"),
        ("木蔭", "kokage", "naungan pohon"),
    ], [
        ("お蔭様で元気です。", "Okagesama de genki desu.", "Berkat bantuan Anda, saya sehat."),
        ("木蔭で休みました。", "Kokage de yasumimashita.", "Beristirahat di naungan pohon."),
    ]),
    ("en14_n1", "焉", ["エン"], [], ["partikel klasik", "how", "thereupon"], 11, "火", [
        ("終焉", "shuuen", "akhir hayat"),
        ("焉んぞ", "izukunzo", "bagaimana mungkin (klasik)"),
        ("於焉", "oen", "klasik"),
    ], [
        ("終焉を迎えました。", "Shuuen o mukaemashita.", "Menyambut akhir hayat."),
        ("焉んぞ知らんや。", "Izukunzo shiran ya.", "Bagaimana mungkin tahu (ungkapan klasik)."),
    ]),
    ("kei21_n1", "慧", ["ケイ", "エ"], [], ["bijaksana", "wise"], 15, "心", [
        ("知慧", "chie", "kebijaksanaan"),
        ("慧眼", "keigan", "mata yang tajam/bijaksana"),
        ("智慧", "chie", "kebijaksanaan Buddhis"),
    ], [
        ("慧眼の持ち主です。", "Keigan no mochinushi desu.", "Dia memiliki mata yang tajam."),
        ("智慧を授かりました。", "Chie o sazukarimashita.", "Diberkati dengan kebijaksanaan."),
    ]),
    ("gi10_n1", "祇", ["ギ"], [], ["dewa bumi (dalam kata majemuk)", "earth deity"], 8, "示", [
        ("神祇", "jingi", "dewa langit dan bumi"),
        ("祇園", "Gion", "distrik terkenal di Kyoto"),
        ("天神地祇", "tenjin chigi", "semua dewa langit dan bumi"),
    ], [
        ("祇園を訪れました。", "Gion o otozuremashita.", "Mengunjungi Gion."),
        ("神祇を祀っています。", "Jingi o matsutte imasu.", "Memuja dewa langit dan bumi."),
    ]),
    ("shi23_n1", "摯", ["シ"], [], ["tulus (dalam kata majemuk)", "sincere"], 15, "手", [
        ("真摯", "shinshi", "tulus dan serius"),
        ("摯実", "shijitsu", "tulus"),
        ("懇摯", "konshi", "sungguh-sungguh"),
    ], [
        ("真摯な態度です。", "Shinshi na taido desu.", "Ini sikap yang tulus dan serius."),
        ("真摯に受け止めました。", "Shinshi ni uketomemashita.", "Menerima dengan sungguh-sungguh."),
    ]),
    ("shuu15_n1", "愁", ["シュウ"], ["うれ-える"], ["kesedihan", "sorrow", "melancholy"], 13, "心", [
        ("哀愁", "aishuu", "kesedihan/melankolis"),
        ("愁い", "urei", "kesedihan"),
        ("郷愁", "kyoushuu", "nostalgia/rindu kampung halaman"),
    ], [
        ("愁いを帯びています。", "Urei o obite imasu.", "Membawa kesedihan."),
        ("郷愁を感じました。", "Kyoushuu o kanjimashita.", "Merasakan nostalgia."),
    ]),
    ("ro7_n1", "鷺", ["ロ"], ["さぎ"], ["burung bangau kuntul", "heron"], 24, "鳥", [
        ("鷺", "sagi", "burung bangau kuntul"),
        ("白鷺", "shirasagi", "bangau putih"),
        ("鷺草", "sagisou", "bunga anggrek bangau"),
    ], [
        ("鷺が飛んでいます。", "Sagi ga tonde imasu.", "Burung bangau kuntul terbang."),
        ("白鷺城です。", "Shirasagijou desu.", "Ini Kastil Bangau Putih (Himeji)."),
    ]),
    ("rou7_n1", "楼", ["ロウ"], [], ["menara", "tower", "turret"], 13, "木", [
        ("楼閣", "roukaku", "menara/istana megah"),
        ("摩天楼", "matenrou", "pencakar langit"),
        ("望楼", "bourou", "menara pengawas"),
    ], [
        ("楼閣が建っています。", "Roukaku ga tatte imasu.", "Menara megah berdiri."),
        ("望楼から眺めました。", "Bourou kara nagamemashita.", "Memandang dari menara pengawas."),
    ]),
    ("hin4_n1", "彬", ["ヒン"], [], ["halus (nama)", "refined"], 11, "彡", [
        ("彬彬", "hinpin", "seimbang antara bentuk dan isi"),
        ("彬", "Akira", "contoh nama pria"),
        ("彬子", "Akiko", "contoh nama wanita"),
    ], [
        ("彬さんに会いました。", "Akira-san ni aimashita.", "Bertemu dengan Akira."),
        ("文質彬彬という言葉です。", "Bunshitsu hinpin to iu kotoba desu.", "Ini istilah \"bunshitsu hinpin\"."),
    ]),
    ("ko9_n1", "袴", ["コ"], ["はかま"], ["celana tradisional Jepang", "hakama"], 11, "衣", [
        ("袴", "hakama", "celana tradisional"),
        ("袴姿", "hakamasugata", "penampilan berpakaian hakama"),
        ("袴田", "Hakamada", "contoh nama keluarga"),
    ], [
        ("袴を着ました。", "Hakama o kimashita.", "Memakai hakama."),
        ("袴姿が凛々しいです。", "Hakamasugata ga ririshii desu.", "Penampilan berhakamanya gagah."),
    ]),
    ("kyou18_n1", "匡", ["キョウ"], [], ["meluruskan (nama)", "correct", "rectify"], 6, "匚", [
        ("匡正", "kyousei", "koreksi"),
        ("匡輔", "kyouho", "membantu meluruskan"),
        ("匡", "Tadasu", "contoh nama pria"),
    ], [
        ("匡正措置です。", "Kyousei sochi desu.", "Ini tindakan korektif."),
        ("匡さんという名前です。", "Tadasu-san to iu namae desu.", "Ini nama Tadasu."),
    ]),
    ("bi4_n1", "眉", ["ビ"], ["まゆ"], ["alis", "eyebrow"], 9, "目", [
        ("眉", "mayu", "alis"),
        ("眉毛", "mayuge", "bulu alis"),
        ("眉間", "miken", "antara alis"),
    ], [
        ("眉をひそめました。", "Mayu o hisomemashita.", "Mengernyitkan alis."),
        ("眉間にしわを寄せました。", "Miken ni shiwa o yosemashita.", "Mengerutkan dahi di antara alis."),
    ]),
    ("kari_n1", "苅", [], ["かり", "か-る"], ["memotong (variant 刈)", "mow"], 8, "艸", [
        ("苅る", "karu", "memotong"),
        ("苅田", "Karita", "contoh nama keluarga"),
        ("苅安", "Kariyasu", "contoh nama tempat"),
    ], [
        ("苅田さんに会いました。", "Karita-san ni aimashita.", "Bertemu dengan Karita."),
        ("稲を苅りました。", "Ine o karimashita.", "Memanen padi."),
    ]),
    ("san5_n1", "讃", ["サン"], [], ["memuji (variant 賛)", "praise"], 22, "言", [
        ("讃岐", "Sanuki", "nama daerah lama di Shikoku"),
        ("讃美歌", "sanbika", "lagu pujian"),
        ("大讃", "daisan", "pujian besar"),
    ], [
        ("讃岐うどんです。", "Sanuki udon desu.", "Ini udon Sanuki."),
        ("讃美歌を歌いました。", "Sanbika o utaimashita.", "Menyanyikan lagu pujian."),
    ]),
    ("in7_n1", "尹", ["イン"], [], ["pejabat pemerintah kuno (nama)", "government official"], 4, "尸", [
        ("尹", "In", "gelar pejabat kuno"),
        ("令尹", "reiin", "perdana menteri kuno Tiongkok"),
        ("京兆尹", "keichouin", "gubernur ibu kota kuno"),
    ], [
        ("尹という官職でした。", "In to iu kanshoku deshita.", "Ini jabatan pemerintahan bernama \"in\"."),
        ("令尹に任命されました。", "Reiin ni ninmei saremashita.", "Diangkat menjadi perdana menteri."),
    ]),
    ("kin9_n1", "欽", ["キン"], [], ["hormat (kekaisaran)", "respectful", "imperial"], 12, "欠", [
        ("欽定", "kintei", "ditetapkan kaisar"),
        ("欽慕", "kinbo", "kekaguman mendalam"),
        ("欽一", "Kin-ichi", "contoh nama pria"),
    ], [
        ("欽定憲法です。", "Kintei kenpou desu.", "Ini konstitusi yang ditetapkan kaisar."),
        ("欽慕の念を抱いています。", "Kinbo no nen o idaite imasu.", "Memiliki kekaguman mendalam."),
    ]),
    ("shin15_n1", "薪", ["シン"], ["たきぎ"], ["kayu bakar", "firewood"], 16, "艸", [
        ("薪", "takigi", "kayu bakar"),
        ("薪割り", "makiwari", "membelah kayu bakar"),
        ("臥薪嘗胆", "gashinshoutan", "menahan kesulitan demi tujuan"),
    ], [
        ("薪を集めました。", "Takigi o atsumemashita.", "Mengumpulkan kayu bakar."),
        ("薪割りをしました。", "Makiwari o shimashita.", "Membelah kayu bakar."),
    ]),
    ("tan8_n1", "湛", ["タン"], ["たた-える"], ["penuh (air)", "full", "calm"], 12, "水", [
        ("湛える", "tataeru", "memenuhi/menampilkan ekspresi"),
        ("湛然", "tanzen", "tenang"),
        ("満々と湛える", "manman to tataeru", "terisi penuh"),
    ], [
        ("水を湛えています。", "Mizu o tataete imasu.", "Terisi penuh air."),
        ("笑みを湛えています。", "Emi o tataete imasu.", "Menampilkan senyuman."),
    ]),
    ("tsui3_n1", "堆", ["タイ"], [], ["menumpuk", "pile up", "heap"], 11, "土", [
        ("堆積", "taiseki", "endapan/akumulasi"),
        ("堆肥", "taihi", "kompos"),
        ("砂堆", "satai", "gundukan pasir"),
    ], [
        ("堆積物です。", "Taisekibutsu desu.", "Ini endapan."),
        ("堆肥を作りました。", "Taihi o tsukurimashita.", "Membuat kompos."),
    ]),
    ("ko10_n1", "狐", ["コ"], ["きつね"], ["rubah", "fox"], 8, "犬", [
        ("狐", "kitsune", "rubah"),
        ("狐火", "kitsunebi", "api rubah (fenomena mistis)"),
        ("狐色", "kitsuneiro", "warna coklat keemasan"),
    ], [
        ("狐を見ました。", "Kitsune o mimashita.", "Melihat rubah."),
        ("狐色に揚げました。", "Kitsuneiro ni agemashita.", "Digoreng hingga coklat keemasan."),
    ]),
    ("katsu7_n1", "褐", ["カツ"], [], ["coklat (dalam kata majemuk)", "brown"], 13, "衣", [
        ("褐色", "kasshoku", "warna coklat"),
        ("褐炭", "kattan", "batu bara coklat/lignit"),
        ("茶褐色", "chakasshoku", "coklat kemerahan"),
    ], [
        ("褐色の肌です。", "Kasshoku no hada desu.", "Ini kulit berwarna coklat."),
        ("褐炭を採掘しています。", "Kattan o saikutsu shite imasu.", "Menambang lignit."),
    ]),
    ("ou7_n1", "鴎", ["オウ"], ["かもめ"], ["burung camar", "seagull"], 15, "鳥", [
        ("鴎", "kamome", "burung camar"),
        ("鴎外", "Ougai", "nama pena penulis Mori Ogai"),
        ("白鴎", "hakuou", "camar putih"),
    ], [
        ("鴎が飛んでいます。", "Kamome ga tonde imasu.", "Burung camar terbang."),
        ("森鴎外は有名な作家です。", "Mori Ougai wa yuumei na sakka desu.", "Mori Ogai adalah penulis terkenal."),
    ]),
    ("shin16_n1", "瀋", ["シン"], [], ["Kota Shenyang", "sari (klasik)"], 18, "水", [
        ("瀋陽", "Shin-you", "Kota Shenyang Tiongkok"),
        ("瀋", "shin", "sari (klasik)"),
        ("瀋水", "shinsui", "cairan sari"),
    ], [
        ("瀋陽に行きました。", "Shin-you ni ikimashita.", "Pergi ke Shenyang."),
        ("瀋陽は中国の都市です。", "Shin-you wa Chuugoku no toshi desu.", "Shenyang adalah kota di Tiongkok."),
    ]),
    ("tei18_n1", "挺", ["テイ"], [], ["penghitung senjata", "mencabut", "counter for guns"], 10, "手", [
        ("一挺", "icchou", "satu pucuk (senjata)"),
        ("挺身", "teishin", "mengorbankan diri"),
        ("抜挺", "bassei", "mencabut"),
    ], [
        ("銃一挺です。", "Juu icchou desu.", "Ini satu pucuk senjata."),
        ("挺身隊でした。", "Teishintai deshita.", "Ini adalah korps pengorbanan diri."),
    ]),
    ("shi24_n1", "賜", ["シ"], ["たまわ-る"], ["menganugerahkan", "grant", "bestow"], 15, "貝", [
        ("賜る", "tamawaru", "dianugerahkan"),
        ("恩賜", "onshi", "anugerah kekaisaran"),
        ("下賜", "kashi", "pemberian dari atasan/kaisar"),
    ], [
        ("賜りました。", "Tamawarimashita.", "Dianugerahkan."),
        ("恩賜の品です。", "Onshi no shina desu.", "Ini barang anugerah kekaisaran."),
    ]),
    ("sa5_n1", "嵯", ["サ"], [], ["gunung terjal (nama tempat)", "rugged mountain"], 13, "山", [
        ("嵯峨", "Saga", "distrik terkenal di Kyoto"),
        ("嵯峨野", "Sagano", "area wisata di Kyoto"),
        ("嵯峨天皇", "Saga Tennou", "Kaisar Saga"),
    ], [
        ("嵯峨野を散策しました。", "Sagano o sansaku shimashita.", "Berjalan-jalan di Sagano."),
        ("嵯峨天皇の時代です。", "Saga Tennou no jidai desu.", "Ini era Kaisar Saga."),
    ]),
    ("gan6_n1", "雁", ["ガン"], ["かり"], ["angsa liar", "wild goose"], 12, "隹", [
        ("雁", "kari", "angsa liar"),
        ("雁行", "gankou", "formasi angsa terbang"),
        ("雁書", "ganshou", "surat (dari legenda angsa pembawa surat)"),
    ], [
        ("雁が飛んでいます。", "Kari ga tonde imasu.", "Angsa liar terbang."),
        ("雁行してきました。", "Gankou shite kimashita.", "Datang dalam formasi angsa."),
    ]),
    ("den_n1", "佃", ["デン"], ["つくだ"], ["sawah garapan (nama tempat)", "cultivated field"], 7, "人", [
        ("佃", "Tsukuda", "nama tempat di Tokyo"),
        ("佃煮", "tsukudani", "makanan awetan rebus kecap"),
        ("佃島", "Tsukudajima", "nama pulau di Tokyo"),
    ], [
        ("佃煮を食べました。", "Tsukudani o tabemashita.", "Makan tsukudani."),
        ("佃島に行きました。", "Tsukudajima ni ikimashita.", "Pergi ke Pulau Tsukuda."),
    ]),
    ("sou24_n1", "綜", ["ソウ"], [], ["menyeluruh (variant 総)", "comprehensive"], 14, "糸", [
        ("綜合", "sougou", "komprehensif"),
        ("綜理", "souri", "pengelolaan menyeluruh"),
        ("綜覧", "souran", "tinjauan menyeluruh"),
    ], [
        ("綜合的な判断です。", "Sougouteki na handan desu.", "Ini keputusan yang komprehensif."),
        ("綜理を担当しています。", "Souri o tantou shite imasu.", "Bertanggung jawab atas pengelolaan menyeluruh."),
    ]),
    ("zen5_n1", "繕", ["ゼン"], ["つくろ-う"], ["memperbaiki", "mend", "repair"], 18, "糸", [
        ("繕う", "tsukurou", "memperbaiki/menambal"),
        ("修繕", "shuuzen", "perbaikan"),
        ("営繕", "eizen", "pemeliharaan bangunan"),
    ], [
        ("服を繕いました。", "Fuku o tsukuroimashita.", "Menambal baju."),
        ("修繕工事です。", "Shuuzen kouji desu.", "Ini pekerjaan perbaikan."),
    ]),
    ("koma2_n1", "狛", [], ["こま"], ["patung anjing singa penjaga kuil", "guardian lion-dog"], 8, "犬", [
        ("狛犬", "komainu", "patung anjing singa penjaga kuil"),
        ("狛江", "Komae", "nama kota di Tokyo"),
        ("狛江市", "Komae-shi", "Kota Komae"),
    ], [
        ("狛犬が守っています。", "Komainu ga mamotte imasu.", "Patung komainu menjaga."),
        ("狛江市に住んでいます。", "Komae-shi ni sunde imasu.", "Tinggal di kota Komae."),
    ]),
    ("ko11_n1", "壷", ["コ"], ["つぼ"], ["guci (variant 壺)", "pot", "jar"], 11, "士", [
        ("壷", "tsubo", "guci"),
        ("骨壷", "kotsutsubo", "guci abu jenazah"),
        ("茶壷", "chatsubo", "guci teh"),
    ], [
        ("壷に入れました。", "Tsubo ni iremashita.", "Dimasukkan ke dalam guci."),
        ("骨壷を持ってきました。", "Kotsutsubo o motte kimashita.", "Membawa guci abu jenazah."),
    ]),
    ("kashi_n1", "橿", [], ["かし"], ["pohon ek (nama tempat)", "oak"], 17, "木", [
        ("橿原", "Kashihara", "nama kota di Nara"),
        ("橿原神宮", "Kashihara Jinguu", "Kuil Kashihara"),
        ("橿の木", "kashi no ki", "pohon ek"),
    ], [
        ("橿原市に行きました。", "Kashihara-shi ni ikimashita.", "Pergi ke kota Kashihara."),
        ("橿原神宮を訪れました。", "Kashihara Jinguu o otozuremashita.", "Mengunjungi Kuil Kashihara."),
    ]),
    ("sen14_n1", "栓", ["セン"], [], ["sumbat", "stopper", "plug"], 10, "木", [
        ("栓", "sen", "sumbat"),
        ("栓抜き", "sennuki", "pembuka botol"),
        ("消火栓", "shoukasen", "hidran kebakaran"),
    ], [
        ("栓を抜きました。", "Sen o nukimashita.", "Mencabut sumbat."),
        ("消火栓があります。", "Shoukasen ga arimasu.", "Ada hidran kebakaran."),
    ]),
    ("sui11_n1", "翠", ["スイ"], [], ["hijau zamrud", "emerald green"], 14, "羽", [
        ("翠玉", "suigyoku", "batu zamrud"),
        ("翠色", "suishoku", "warna hijau zamrud"),
        ("翠緑", "suiryoku", "hijau zamrud tua"),
    ], [
        ("翠玉のネックレスです。", "Suigyoku no nekkuresu desu.", "Ini kalung batu zamrud."),
        ("翠色の湖です。", "Suishoku no mizuumi desu.", "Ini danau berwarna hijau zamrud."),
    ]),
    ("ayu_n1", "鮎", [], ["あゆ"], ["ikan ayu", "sweetfish"], 16, "魚", [
        ("鮎", "ayu", "ikan ayu"),
        ("鮎釣り", "ayuzuri", "memancing ikan ayu"),
        ("若鮎", "wakaayu", "ikan ayu muda"),
    ], [
        ("鮎を釣りました。", "Ayu o tsurimashita.", "Memancing ikan ayu."),
        ("鮎釣りが趣味です。", "Ayuzuri ga shumi desu.", "Hobi memancing ayu."),
    ]),
    ("shin17_n1", "芯", ["シン"], [], ["inti", "core", "wick"], 7, "艸", [
        ("芯", "shin", "inti"),
        ("鉛筆の芯", "enpitsu no shin", "isi pensil"),
        ("芯まで", "shin made", "sampai ke inti"),
    ], [
        ("鉛筆の芯が折れました。", "Enpitsu no shin ga oremashita.", "Isi pensilnya patah."),
        ("芯まで冷えました。", "Shin made hiemashita.", "Dingin sampai ke tulang."),
    ]),
    ("mitsu2_n1", "蜜", ["ミツ"], [], ["madu", "honey", "nectar"], 14, "虫", [
        ("蜜", "mitsu", "madu"),
        ("蜂蜜", "hachimitsu", "madu lebah"),
        ("蜜月", "mitsugetsu", "bulan madu"),
    ], [
        ("蜂蜜を食べました。", "Hachimitsu o tabemashita.", "Makan madu."),
        ("蜜月旅行です。", "Mitsugetsu ryokou desu.", "Ini perjalanan bulan madu."),
    ]),
    ("ha6_n1", "播", ["ハ", "バン"], ["ま-く"], ["menabur", "sow", "spread"], 15, "手", [
        ("播く", "maku", "menabur"),
        ("伝播", "denpa", "penyebaran"),
        ("播種", "hashu", "penyemaian benih"),
    ], [
        ("種を播きました。", "Tane o makimashita.", "Menabur benih."),
        ("情報が伝播しました。", "Jouhou ga denpa shimashita.", "Informasi menyebar."),
    ]),
    ("shin18_n1", "榛", ["シン"], ["はしばみ"], ["pohon hazel (nama)", "hazel tree"], 14, "木", [
        ("榛", "hashibami", "pohon hazel"),
        ("榛名", "Haruna", "nama gunung di Gunma"),
        ("榛原", "Haibara", "nama tempat"),
    ], [
        ("榛名山に登りました。", "Haruna-san ni noborimashita.", "Mendaki Gunung Haruna."),
        ("榛の木があります。", "Hashibami no ki ga arimasu.", "Ada pohon hazel."),
    ]),
    ("ou8_n1", "凹", ["オウ"], ["へこ-む", "くぼ-む"], ["cekung", "concave", "hollow"], 5, "凵", [
        ("凹む", "hekomu", "penyok/cekung"),
        ("凹凸", "outotsu", "tidak rata"),
        ("凹レンズ", "ou renzu", "lensa cekung"),
    ], [
        ("車が凹みました。", "Kuruma ga hekomimashita.", "Mobil penyok."),
        ("凹レンズを使いました。", "Ou renzu o tsukaimashita.", "Menggunakan lensa cekung."),
    ]),
    ("en15_n1", "艶", ["エン"], ["つや"], ["kilau", "romantis", "glossy", "romance"], 19, "色", [
        ("艶", "tsuya", "kilau"),
        ("艶やか", "tsuyayaka", "berkilau/anggun"),
        ("色艶", "irotsuya", "warna dan kilau"),
    ], [
        ("艶のある髪です。", "Tsuya no aru kami desu.", "Ini rambut yang berkilau."),
        ("艶やかな着物です。", "Tsuyayaka na kimono desu.", "Ini kimono yang anggun."),
    ]),
    ("chou25_n1", "帖", ["チョウ", "ジョウ"], [], ["buku catatan (penghitung)", "notebook"], 8, "巾", [
        ("手帖", "techou", "buku catatan"),
        ("一帖", "ichijou", "satu unit tatami/kertas"),
        ("画帖", "gachou", "buku sketsa"),
    ], [
        ("手帖に書きました。", "Techou ni kakimashita.", "Menulis di buku catatan."),
        ("画帖を持っています。", "Gachou o motte imasu.", "Membawa buku sketsa."),
    ]),
    ("tou20_n1", "桶", ["トウ"], ["おけ"], ["ember kayu", "bucket", "tub"], 11, "木", [
        ("桶", "oke", "ember kayu"),
        ("風呂桶", "furooke", "bak mandi kayu"),
        ("棺桶", "kan-oke", "peti mati"),
    ], [
        ("桶に水を入れました。", "Oke ni mizu o iremashita.", "Mengisi air ke ember kayu."),
        ("風呂桶を洗いました。", "Furooke o araimashita.", "Mencuci bak mandi kayu."),
    ]),
    ("sou25_n1", "惣", ["ソウ"], [], ["semua (dalam kata majemuk)", "all", "general"], 12, "心", [
        ("惣菜", "souzai", "lauk siap saji"),
        ("惣領", "souryou", "anak sulung pewaris"),
        ("御惣菜", "osouzai", "lauk siap saji (sopan)"),
    ], [
        ("惣菜を買いました。", "Souzai o kaimashita.", "Membeli lauk siap saji."),
        ("惣領息子です。", "Souryou musuko desu.", "Ini anak sulung pewaris."),
    ]),
    ("ko12_n1", "股", ["コ"], ["また"], ["paha", "selangkangan", "thigh", "crotch"], 8, "肉", [
        ("股", "mata", "selangkangan"),
        ("股関節", "kokansetsu", "sendi panggul"),
        ("内股", "uchimata", "paha dalam"),
    ], [
        ("股関節が痛いです。", "Kokansetsu ga itai desu.", "Sendi panggul sakit."),
        ("内股で歩いています。", "Uchimata de aruite imasu.", "Berjalan dengan gaya paha dalam."),
    ]),
    ("nioi_n1", "匂", [], ["にお-う"], ["bau", "smell"], 4, "勹", [
        ("匂い", "nioi", "bau/aroma"),
        ("匂う", "niou", "berbau"),
        ("匂い袋", "nioibukuro", "kantong wangi"),
    ], [
        ("いい匂いがします。", "Ii nioi ga shimasu.", "Ada aroma yang enak."),
        ("匂い袋を作りました。", "Nioibukuro o tsukurimashita.", "Membuat kantong wangi."),
    ]),
    ("an3_n1", "鞍", ["アン"], ["くら"], ["pelana", "saddle"], 15, "革", [
        ("鞍", "kura", "pelana"),
        ("鞍馬", "Anba", "kuda pelana/nama gunung Kyoto"),
        ("鞍替え", "kuragae", "berganti profesi/pindah haluan"),
    ], [
        ("鞍をつけました。", "Kura o tsukemashita.", "Memasang pelana."),
        ("鞍替えしました。", "Kuragae shimashita.", "Berganti profesi."),
    ]),
    ("chou26_n1", "蔦", ["チョウ"], ["つた"], ["tanaman ivy", "ivy"], 13, "艸", [
        ("蔦", "tsuta", "tanaman ivy"),
        ("蔦の絡まる建物", "tsuta no karamaru tatemono", "bangunan berselimut ivy"),
        ("蔦屋", "Tsutaya", "nama toko/perusahaan terkenal"),
    ], [
        ("蔦が絡んでいます。", "Tsuta ga karande imasu.", "Ivy melilit."),
        ("蔦屋書店に行きました。", "Tsutaya shoten ni ikimashita.", "Pergi ke toko buku Tsutaya."),
    ]),
    ("gan7_n1", "玩", ["ガン"], [], ["mainan", "toy", "play with"], 8, "玉", [
        ("玩具", "gangu", "mainan"),
        ("愛玩", "aigan", "kesayangan"),
        ("玩弄", "ganrou", "mempermainkan"),
    ], [
        ("玩具を買いました。", "Gangu o kaimashita.", "Membeli mainan."),
        ("愛玩動物です。", "Aigan doubutsu desu.", "Ini hewan peliharaan kesayangan."),
    ]),
    ("kaya2_n1", "萱", [], ["かや"], ["alang-alang untuk atap (nama)", "reed", "thatch"], 12, "艸", [
        ("萱", "kaya", "rumput untuk atap"),
        ("萱葺き", "kayabuki", "atap jerami"),
        ("萱野", "Kayano", "contoh nama keluarga"),
    ], [
        ("萱葺き屋根です。", "Kayabuki yane desu.", "Ini atap jerami."),
        ("萱野さんに会いました。", "Kayano-san ni aimashita.", "Bertemu dengan Kayano."),
    ]),
    ("tei19_n1", "梯", ["テイ"], ["はしご"], ["tangga", "ladder"], 11, "木", [
        ("梯子", "hashigo", "tangga"),
        ("階梯", "kaitei", "tahapan/tangga langkah"),
        ("雲梯", "untei", "tangga monyet/alat gantung"),
    ], [
        ("梯子を登りました。", "Hashigo o noborimashita.", "Menaiki tangga."),
        ("階梯を踏みました。", "Kaitei o fumimashita.", "Melalui tahapan."),
    ]),
    ("shizuku_n1", "雫", [], ["しずく"], ["tetesan", "drop"], 11, "雨", [
        ("雫", "shizuku", "tetesan"),
        ("水雫", "mizushizuku", "tetesan air"),
        ("涙の雫", "namida no shizuku", "tetesan air mata"),
    ], [
        ("雫が落ちました。", "Shizuku ga ochimashita.", "Tetesan jatuh."),
        ("涙の雫です。", "Namida no shizuku desu.", "Ini tetesan air mata."),
    ]),
    ("han13_n1", "絆", ["ハン"], ["きずな"], ["ikatan", "bond", "tie"], 11, "糸", [
        ("絆", "kizuna", "ikatan"),
        ("絆創膏", "bansoukou", "plester luka"),
        ("家族の絆", "kazoku no kizuna", "ikatan keluarga"),
    ], [
        ("絆を大切にしています。", "Kizuna o taisetsu ni shite imasu.", "Menghargai ikatan."),
        ("絆創膏を貼りました。", "Bansoukou o harimashita.", "Menempelkan plester."),
    ]),
    ("ren4_n1", "錬", ["レン"], [], ["menempa", "refine", "forge"], 16, "金", [
        ("錬金術", "renkinjutsu", "alkimia"),
        ("鍛錬", "tanren", "latihan keras"),
        ("精錬", "seiren", "pemurnian logam"),
    ], [
        ("錬金術師です。", "Renkinjutsushi desu.", "Ini ahli alkimia."),
        ("精錬所です。", "Seirenjo desu.", "Ini pabrik pemurnian logam."),
    ]),
    ("sou26_n1", "湊", ["ソウ"], ["みなと"], ["pelabuhan (variant 港)", "harbor"], 12, "水", [
        ("湊", "minato", "pelabuhan"),
        ("湊川", "Minatogawa", "nama sungai di Kobe"),
        ("湊町", "Minatomachi", "nama daerah pelabuhan"),
    ], [
        ("湊に船が着きました。", "Minato ni fune ga tsukimashita.", "Kapal tiba di pelabuhan."),
        ("湊川の戦いです。", "Minatogawa no tatakai desu.", "Ini Pertempuran Sungai Minato."),
    ]),
    ("hou19_n1", "蜂", ["ホウ"], ["はち"], ["lebah", "tawon", "bee", "wasp"], 13, "虫", [
        ("蜂", "hachi", "lebah"),
        ("蜂蜜", "hachimitsu", "madu lebah"),
        ("蜂起", "houki", "pemberontakan"),
    ], [
        ("蜂に刺されました。", "Hachi ni sasaremashita.", "Disengat lebah."),
        ("民衆が蜂起しました。", "Minshuu ga houki shimashita.", "Rakyat memberontak."),
    ]),
    ("jun9_n1", "隼", ["ジュン"], ["はやぶさ"], ["elang alap-alap", "falcon"], 10, "隹", [
        ("隼", "hayabusa", "elang alap-alap"),
        ("隼人", "Hayato", "contoh nama pria/nama kuno Kyushu"),
        ("隼型", "hayabusagata", "jenis pesawat tempur"),
    ], [
        ("隼が飛んでいます。", "Hayabusa ga tonde imasu.", "Elang alap-alap terbang."),
        ("隼人さんに会いました。", "Hayato-san ni aimashita.", "Bertemu dengan Hayato."),
    ]),
    ("da4_n1", "舵", ["ダ"], ["かじ"], ["kemudi kapal", "rudder"], 11, "舟", [
        ("舵", "kaji", "kemudi"),
        ("舵取り", "kajitori", "mengemudikan"),
        ("面舵", "omokaji", "kemudi ke kanan"),
    ], [
        ("舵を取りました。", "Kaji o torimashita.", "Mengemudikan kapal."),
        ("舵取りが上手です。", "Kajitori ga jouzu desu.", "Pandai mengemudikan."),
    ]),
    ("sho4_n1", "渚", ["ショ"], ["なぎさ"], ["pantai", "shore", "beach"], 11, "水", [
        ("渚", "nagisa", "pantai"),
        ("渚にて", "nagisa nite", "di pantai (judul karya)"),
        ("遠浅の渚", "toasa no nagisa", "pantai landai"),
    ], [
        ("渚を歩きました。", "Nagisa o arukimashita.", "Berjalan di pantai."),
        ("遠浅の渚です。", "Toasa no nagisa desu.", "Ini pantai landai."),
    ]),
    ("ka19_n1", "珂", ["カ"], [], ["hiasan giok (arkais, nama)", "agate", "jade ornament"], 9, "玉", [
        ("珂", "ka", "hiasan giok (arkais)"),
        ("白珂", "hakka", "giok putih"),
        ("珂玉", "kagyoku", "batu giok hias"),
    ], [
        ("珂という字はまれです。", "Ka to iu ji wa mare desu.", "Karakter \"ka\" ini jarang."),
        ("白珂の飾りです。", "Hakka no kazari desu.", "Ini hiasan giok putih."),
    ]),
    ("kan33_n1", "煥", ["カン"], [], ["berseri (nama)", "brilliant", "radiant"], 13, "火", [
        ("煥発", "kanpatsu", "berseri-seri"),
        ("煥然", "kanzen", "cerah berseri"),
        ("煥乎", "kanko", "cerah gemilang"),
    ], [
        ("才気煥発です。", "Saiki kanpatsu desu.", "Ini bakat yang berseri-seri/menonjol."),
        ("煥然として明るいです。", "Kanzen to shite akarui desu.", "Cerah berseri-seri."),
    ]),
    ("chuu5_n1", "衷", ["チュウ"], [], ["hati nurani", "inner heart", "moderate"], 10, "衣", [
        ("衷心", "chuushin", "hati yang tulus"),
        ("折衷", "setchuu", "kompromi/eklektik"),
        ("苦衷", "kuchuu", "kesulitan batin"),
    ], [
        ("衷心より感謝します。", "Chuushin yori kansha shimasu.", "Berterima kasih dari lubuk hati."),
        ("折衷案です。", "Setchuuan desu.", "Ini rencana kompromi."),
    ]),
    ("chiku3_n1", "逐", ["チク"], [], ["mengejar", "chase", "pursue"], 10, "辵", [
        ("逐一", "chikuichi", "satu per satu"),
        ("逐次", "chikuji", "berurutan"),
        ("駆逐", "kuchiku", "pengusiran/perusak"),
    ], [
        ("逐一報告してください。", "Chikuichi houkoku shite kudasai.", "Tolong laporkan satu per satu."),
        ("駆逐艦です。", "Kuchikukan desu.", "Ini kapal perusak."),
    ]),
    ("seki4_n1", "斥", ["セキ"], [], ["menolak", "reject", "repel"], 5, "斤", [
        ("排斥", "haiseki", "penolakan/boikot"),
        ("斥候", "sekkou", "pengintai"),
        ("斥力", "sekiryoku", "gaya tolak"),
    ], [
        ("排斥運動です。", "Haiseki undou desu.", "Ini gerakan penolakan."),
        ("斥候を送りました。", "Sekkou o okurimashita.", "Mengirim pengintai."),
    ]),
    ("ki27_n1", "稀", ["キ"], ["まれ"], ["langka", "rare"], 12, "禾", [
        ("稀", "mare", "langka"),
        ("稀少", "kishou", "langka/jarang"),
        ("古稀", "koki", "usia 70 tahun"),
    ], [
        ("稀な現象です。", "Mare na genshou desu.", "Ini fenomena yang langka."),
        ("稀少価値があります。", "Kishou kachi ga arimasu.", "Memiliki nilai kelangkaan."),
    ]),
    ("gan8_n1", "癌", ["ガン"], [], ["kanker", "cancer"], 17, "疒", [
        ("癌", "gan", "kanker"),
        ("胃癌", "igan", "kanker lambung"),
        ("癌細胞", "gansaibou", "sel kanker"),
    ], [
        ("癌と診断されました。", "Gan to shindan saremashita.", "Didiagnosis kanker."),
        ("胃癌の手術です。", "Igan no shujutsu desu.", "Ini operasi kanker lambung."),
    ]),
    ("ga8_n1", "峨", ["ガ"], [], ["gunung tinggi (dalam kata majemuk)", "lofty mountain"], 10, "山", [
        ("峨々", "gaga", "terjal berbukit-bukit"),
        ("嵯峨", "Saga", "distrik terkenal di Kyoto"),
        ("峨眉山", "Gabizan", "Gunung Emei Tiongkok"),
    ], [
        ("峨眉山は中国の名山です。", "Gabizan wa Chuugoku no meizan desu.", "Gunung Emei adalah gunung terkenal Tiongkok."),
        ("峨々たる山です。", "Gaga taru yama desu.", "Ini gunung yang terjal."),
    ]),
    ("kyo7_n1", "嘘", ["キョ"], ["うそ"], ["bohong", "lie", "falsehood"], 14, "口", [
        ("嘘", "uso", "kebohongan"),
        ("嘘つき", "usotsuki", "pembohong"),
        ("真っ赤な嘘", "makka na uso", "kebohongan besar"),
    ], [
        ("嘘をつきました。", "Uso o tsukimashita.", "Berbohong."),
        ("嘘つきです。", "Usotsuki desu.", "Dia pembohong."),
    ]),
    ("han14_n1", "旛", ["ハン"], [], ["bendera panjang (nama tempat)", "banner"], 19, "方", [
        ("印旛", "Inba", "nama daerah di Chiba"),
        ("印旛沼", "Inbanuma", "Danau Inba"),
        ("旛", "han", "bendera panjang"),
    ], [
        ("印旛沼に行きました。", "Inbanuma ni ikimashita.", "Pergi ke Danau Inba."),
        ("印旛という地名です。", "Inba to iu chimei desu.", "Ini nama tempat Inba."),
    ]),
    ("rou8_n1", "篭", ["ロウ"], ["かご", "こ-もる"], ["keranjang (variant 籠)", "basket", "cage"], 16, "竹", [
        ("篭", "kago", "keranjang"),
        ("篭もる", "komoru", "mengurung diri"),
        ("灯篭", "tourou", "lentera batu"),
    ], [
        ("篭に入れました。", "Kago ni iremashita.", "Dimasukkan ke keranjang."),
        ("灯篭を灯しました。", "Tourou o tomoshimashita.", "Menyalakan lentera batu."),
    ]),
    ("fu10_n1", "芙", ["フ"], [], ["lotus/hibiscus (dalam kata majemuk)"], 7, "艸", [
        ("芙蓉", "fuyou", "bunga hibiscus"),
        ("芙蓉峰", "fuyouhou", "sebutan puitis Gunung Fuji"),
        ("木芙蓉", "mokufuyou", "hibiscus pohon"),
    ], [
        ("芙蓉の花が咲きました。", "Fuyou no hana ga sakimashita.", "Bunga hibiscus mekar."),
        ("芙蓉峰と呼ばれています。", "Fuyouhou to yobarete imasu.", "Disebut sebagai puncak Fuyo (Gunung Fuji)."),
    ]),
    ("shou36_n1", "詔", ["ショウ"], ["みことのり"], ["dekrit kaisar", "imperial edict"], 12, "言", [
        ("詔書", "shousho", "dekrit tertulis kaisar"),
        ("詔勅", "shouchoku", "dekrit kekaisaran resmi"),
        ("大詔", "taishou", "dekrit agung"),
    ], [
        ("詔書が発布されました。", "Shousho ga happu saremashita.", "Dekrit kaisar diumumkan."),
        ("大詔を賜りました。", "Taishou o tamawarimashita.", "Dianugerahi dekrit agung."),
    ]),
    ("kou37_n1", "皐", ["コウ"], ["さつき"], ["tepi sungai", "bulan Mei (nama)", "riverside"], 11, "白", [
        ("皐月", "satsuki", "bulan Mei (nama klasik)"),
        ("皐", "kou", "tepi sungai (arkais)"),
        ("皐比", "kouhi", "kulit harimau (klasik)"),
    ], [
        ("皐月という月の名前です。", "Satsuki to iu tsuki no namae desu.", "Ini nama bulan \"Satsuki\"."),
        ("皐月賞という競馬レースです。", "Satsuki Shou to iu keiba reesu desu.", "Ini balapan kuda \"Satsuki Sho\"."),
    ]),
    ("suu3_n1", "雛", ["スウ"], ["ひな"], ["anak ayam", "boneka", "chick", "doll"], 18, "隹", [
        ("雛", "hina", "anak ayam/boneka hina"),
        ("雛人形", "hina ningyou", "boneka hina Matsuri"),
        ("雛祭り", "hinamatsuri", "festival boneka Hina"),
    ], [
        ("雛人形を飾りました。", "Hina ningyou o kazarimashita.", "Menghias boneka hina."),
        ("雛祭りを祝いました。", "Hinamatsuri o iwaimashita.", "Merayakan Festival Hina."),
    ]),
    ("shou37_n1", "娼", ["ショウ"], [], ["pelacur (dalam kata majemuk)", "prostitute"], 11, "女", [
        ("娼婦", "shoufu", "pelacur"),
        ("娼館", "shoukan", "rumah bordil"),
        ("私娼", "shishou", "pelacur ilegal"),
    ], [
        ("娼婦を描いた小説です。", "Shoufu o egaita shousetsu desu.", "Ini novel yang menggambarkan pelacur."),
        ("娼館があった地域です。", "Shoukan ga atta chiiki desu.", "Ini daerah yang dulunya ada rumah bordil."),
    ]),
    ("ten4_n1", "篆", ["テン"], [], ["gaya kaligrafi kuno", "seal script"], 15, "竹", [
        ("篆刻", "tenkoku", "ukiran stempel"),
        ("篆書", "tensho", "gaya tulisan segel"),
        ("小篆", "shouten", "gaya segel kecil"),
    ], [
        ("篆刻を習っています。", "Tenkoku o naratte imasu.", "Belajar ukiran stempel."),
        ("篆書で書きました。", "Tensho de kakimashita.", "Menulis dengan gaya segel."),
    ]),
    ("same_n1", "鮫", [], ["さめ"], ["hiu", "shark"], 17, "魚", [
        ("鮫", "same", "hiu"),
        ("鮫肌", "samehada", "kulit kasar seperti kulit hiu"),
        ("人食い鮫", "hitokuizame", "hiu pemakan manusia"),
    ], [
        ("鮫を見ました。", "Same o mimashita.", "Melihat hiu."),
        ("鮫肌になっています。", "Samehada ni natte imasu.", "Kulitnya menjadi kasar."),
    ]),
    ("i11_n1", "椅", ["イ"], [], ["kursi (dalam kata majemuk)", "chair"], 12, "木", [
        ("椅子", "isu", "kursi"),
        ("車椅子", "kurumaisu", "kursi roda"),
        ("椅子取りゲーム", "isutori geemu", "permainan kursi musik"),
    ], [
        ("椅子に座りました。", "Isu ni suwarimashita.", "Duduk di kursi."),
        ("車椅子を使っています。", "Kurumaisu o tsukatte imasu.", "Menggunakan kursi roda."),
    ]),
    ("i12_n1", "惟", ["イ"], ["これ"], ["berpikir (klasik)", "think", "consider"], 11, "心", [
        ("思惟", "shii", "pemikiran/perenungan"),
        ("惟うに", "omouni", "dipikir-pikir (classical)"),
        ("惟一", "Yuiichi", "contoh nama pria"),
    ], [
        ("思惟にふけりました。", "Shii ni fukerimashita.", "Larut dalam perenungan."),
        ("惟一さんに会いました。", "Yuiichi-san ni aimashita.", "Bertemu dengan Yuiichi."),
    ]),
    ("hai6_n1", "牌", ["ハイ"], [], ["keping", "lempengan", "tile", "plate"], 12, "片", [
        ("位牌", "ihai", "tablet arwah leluhur"),
        ("麻雀牌", "maajanpai", "kartu mahjong"),
        ("銘牌", "meihai", "plakat nama"),
    ], [
        ("位牌を祀っています。", "Ihai o matsutte imasu.", "Memuja tablet arwah leluhur."),
        ("麻雀牌で遊びました。", "Maajanpai de asobimashita.", "Bermain dengan kartu mahjong."),
    ]),
    ("tou21_n1", "宕", ["トウ"], [], ["bebas (dalam kata majemuk, nama tempat)", "carefree"], 8, "宀", [
        ("愛宕", "Atago", "nama gunung/distrik terkenal"),
        ("愛宕山", "Atagoyama", "Gunung Atago"),
        ("放宕", "houtou", "bebas tanpa aturan"),
    ], [
        ("愛宕山に登りました。", "Atagoyama ni noborimashita.", "Mendaki Gunung Atago."),
        ("愛宕神社を訪れました。", "Atago Jinja o otozuremashita.", "Mengunjungi Kuil Atago."),
    ]),
    ("ken16_n1", "喧", ["ケン"], [], ["ribut", "noisy", "quarrel"], 12, "口", [
        ("喧嘩", "kenka", "pertengkaran"),
        ("喧噪", "kensou", "kebisingan"),
        ("喧伝", "kenden", "tersebar luas"),
    ], [
        ("喧嘩をしました。", "Kenka o shimashita.", "Bertengkar."),
        ("喧噪から離れました。", "Kensou kara hanaremashita.", "Menjauh dari kebisingan."),
    ]),
    ("yuu13_n1", "佑", ["ユウ"], [], ["membantu (nama)", "help"], 7, "人", [
        ("天佑", "tenyuu", "berkat surga"),
        ("佑筆", "yuuhitsu", "sekretaris"),
        ("佑一", "Yuuichi", "contoh nama pria"),
    ], [
        ("天佑に恵まれました。", "Tenyuu ni megumaremashita.", "Diberkati oleh surga."),
        ("佑一さんに会いました。", "Yuuichi-san ni aimashita.", "Bertemu dengan Yuuichi."),
    ]),
    ("shou38_n1", "蒋", ["ショウ"], [], ["marga Jiang/Chiang", "Chiang (surname)"], 13, "艸", [
        ("蒋介石", "Shou Kaiseki", "Chiang Kai-shek"),
        ("蒋", "Shou", "marga Jiang"),
        ("蒋経国", "Shou Keikoku", "Chiang Ching-kuo"),
    ], [
        ("蒋介石は台湾の指導者でした。", "Shou Kaiseki wa Taiwan no shidousha deshita.", "Chiang Kai-shek adalah pemimpin Taiwan."),
        ("蒋経国はその息子です。", "Shou Keikoku wa sono musuko desu.", "Chiang Ching-kuo adalah putranya."),
    ]),
    ("shou39_n1", "樟", ["ショウ"], ["くす"], ["pohon kamper", "camphor tree"], 15, "木", [
        ("樟脳", "shounou", "kapur barus"),
        ("樟", "kusu", "pohon kamper"),
        ("樟葉", "Kuzuha", "nama tempat"),
    ], [
        ("樟脳を使いました。", "Shounou o tsukaimashita.", "Menggunakan kapur barus."),
        ("樟の木があります。", "Kusu no ki ga arimasu.", "Ada pohon kamper."),
    ]),
    ("you12_n1", "耀", ["ヨウ"], ["かがや-く"], ["bersinar (nama)", "shine"], 20, "羽", [
        ("耀く", "kagayaku", "bersinar"),
        ("光耀", "kouyou", "kecemerlangan"),
        ("耀司", "Youji", "contoh nama pria"),
    ], [
        ("耀司さんに会いました。", "Youji-san ni aimashita.", "Bertemu dengan Youji."),
        ("光耀を放っています。", "Kouyou o hanatte imasu.", "Memancarkan kecemerlangan."),
    ]),
    ("tai9_n1", "黛", ["タイ"], ["まゆずみ"], ["pensil alis (nama)", "eyebrow pencil"], 16, "黒", [
        ("黛", "mayuzumi", "pensil alis tradisional"),
        ("眉黛", "bitai", "alis yang dilukis"),
        ("黛ジュン", "Mayuzumi Jun", "nama penyanyi"),
    ], [
        ("黛を使いました。", "Mayuzumi o tsukaimashita.", "Menggunakan pensil alis tradisional."),
        ("眉黛が美しいです。", "Bitai ga utsukushii desu.", "Alisnya yang terlukis indah."),
    ]),
    ("shitsu4_n1", "叱", ["シツ"], ["しか-る"], ["memarahi", "scold"], 5, "口", [
        ("叱る", "shikaru", "memarahi"),
        ("叱責", "shisseki", "teguran keras"),
        ("叱咤", "shitta", "bentakan/dorongan semangat"),
    ], [
        ("子供を叱りました。", "Kodomo o shikarimashita.", "Memarahi anak."),
        ("叱責されました。", "Shisseki saremashita.", "Ditegur keras."),
    ]),
    ("shitsu5_n1", "櫛", ["シツ"], ["くし"], ["sisir", "comb"], 17, "木", [
        ("櫛", "kushi", "sisir"),
        ("櫛形", "kushigata", "bentuk sisir"),
        ("梳き櫛", "sukigushi", "sisir penata rambut"),
    ], [
        ("櫛で髪をとかしました。", "Kushi de kami o tokashimashita.", "Menyisir rambut dengan sisir."),
        ("櫛形の窓です。", "Kushigata no mado desu.", "Ini jendela berbentuk sisir."),
    ]),
    ("aku2_n1", "渥", ["アク"], [], ["lembab", "murah hati (nama)", "moist", "generous"], 12, "水", [
        ("渥美", "Atsumi", "nama tempat/nama keluarga"),
        ("渥然", "akuzen", "subur"),
        ("優渥", "yuuaku", "murah hati"),
    ], [
        ("渥美半島に行きました。", "Atsumi hantou ni ikimashita.", "Pergi ke Semenanjung Atsumi."),
        ("優渥な待遇です。", "Yuuaku na taiguu desu.", "Ini perlakuan yang murah hati."),
    ]),
    ("ai2_n1", "挨", ["アイ"], [], ["mendekati (dalam kata majemuk)", "approach"], 10, "手", [
        ("挨拶", "aisatsu", "salam/sapaan"),
        ("挨拶状", "aisatsujou", "surat salam"),
        ("御挨拶", "goaisatsu", "salam (sopan)"),
    ], [
        ("挨拶をしました。", "Aisatsu o shimashita.", "Memberi salam."),
        ("挨拶状を送りました。", "Aisatsujou o okurimashita.", "Mengirim surat salam."),
    ]),
    ("shou40_n1", "憧", ["ショウ"], ["あこが-れる"], ["mendambakan", "yearn", "admire"], 15, "心", [
        ("憧れる", "akogareru", "mendambakan"),
        ("憧憬", "doukei", "kekaguman mendalam"),
        ("憧れの的", "akogare no mato", "idola"),
    ], [
        ("憧れています。", "Akogarete imasu.", "Mendambakan."),
        ("憧れの的です。", "Akogare no mato desu.", "Ini idola."),
    ]),
    ("nureru_n1", "濡", ["ジュ"], ["ぬ-れる", "ぬ-らす"], ["basah", "wet"], 17, "水", [
        ("濡れる", "nureru", "basah"),
        ("濡れ衣", "nureginu", "tuduhan palsu"),
        ("濡れ手で粟", "nureteoawa", "untung tanpa usaha"),
    ], [
        ("雨で濡れました。", "Ame de nuremashita.", "Basah karena hujan."),
        ("濡れ衣を着せられました。", "Nureginu o kiseraremashita.", "Dituduh palsu."),
    ]),
    ("sou27_n1", "槍", ["ソウ"], ["やり"], ["tombak", "spear"], 14, "木", [
        ("槍", "yari", "tombak"),
        ("槍投げ", "yarinage", "lempar lembing"),
        ("一本槍", "ipponyari", "mengandalkan satu cara"),
    ], [
        ("槍を持っています。", "Yari o motte imasu.", "Membawa tombak."),
        ("槍投げの選手です。", "Yarinage no senshu desu.", "Ini atlet lempar lembing."),
    ]),
    ("shou41_n1", "宵", ["ショウ"], ["よい"], ["malam awal", "evening"], 10, "宀", [
        ("宵", "yoi", "malam awal"),
        ("宵っ張り", "yoippari", "begadang"),
        ("徹宵", "tesshou", "semalam suntuk"),
    ], [
        ("宵の口です。", "Yoi no kuchi desu.", "Ini masih awal malam."),
        ("宵っ張りです。", "Yoippari desu.", "Suka begadang."),
    ]),
    ("jou12_n1", "襄", ["ジョウ"], [], ["membantu (nama)", "assist", "rise"], 17, "衣", [
        ("襄公", "Jou Kou", "Duke Xiang, tokoh sejarah Tiongkok"),
        ("襄理", "jouri", "asisten manajer"),
        ("新島襄", "Niijima Jou", "pendiri universitas Doshisha"),
    ], [
        ("新島襄は同志社の創立者です。", "Niijima Jou wa Doushisha no souritsusha desu.", "Niijima Jo adalah pendiri Doshisha."),
        ("襄公の時代です。", "Jou Kou no jidai desu.", "Ini era Duke Xiang."),
    ]),
    ("mou5_n1", "妄", ["モウ", "ボウ"], [], ["sembrono", "reckless", "false"], 6, "女", [
        ("妄想", "mousou", "delusi"),
        ("妄言", "bougen", "ucapan sembrono"),
        ("迷妄", "meimou", "kebutaan/delusi"),
    ], [
        ("妄想しています。", "Mousou shite imasu.", "Berdelusi."),
        ("妄言を吐きました。", "Bougen o hakimashita.", "Mengucapkan kata-kata sembrono."),
    ]),
    ("jun10_n1", "惇", ["ジュン"], [], ["tulus (nama)", "sincere"], 11, "心", [
        ("惇", "Atsushi", "contoh nama pria"),
        ("惇朴", "junboku", "tulus dan sederhana"),
        ("惇一", "Jun-ichi", "contoh nama pria"),
    ], [
        ("惇さんに会いました。", "Atsushi-san ni aimashita.", "Bertemu dengan Atsushi."),
        ("惇朴な人柄です。", "Junboku na hitogara desu.", "Kepribadian yang tulus dan sederhana."),
    ]),
    ("tan9_n1", "蛋", ["タン"], [], ["telur (dalam kata majemuk)", "egg"], 11, "虫", [
        ("蛋白質", "tanpakushitsu", "protein"),
        ("蛋白", "tanpaku", "putih telur/protein"),
        ("鶏蛋", "keidan", "telur ayam"),
    ], [
        ("蛋白質を摂取しました。", "Tanpakushitsu o sesshu shimashita.", "Mengonsumsi protein."),
        ("蛋白質が豊富です。", "Tanpakushitsu ga houfu desu.", "Kaya akan protein."),
    ]),
    ("shuu16_n1", "脩", ["シュウ"], [], ["daging kering", "membina diri (nama)", "dried meat"], 11, "肉", [
        ("束脩", "sokushuu", "uang sekolah/hadiah untuk guru"),
        ("脩", "Osamu", "contoh nama pria"),
        ("脩める", "osameru", "membina diri"),
    ], [
        ("束脩を納めました。", "Sokushuu o osamemashita.", "Membayar uang sekolah."),
        ("脩さんに会いました。", "Osamu-san ni aimashita.", "Bertemu dengan Osamu."),
    ]),
    ("toma2_n1", "笘", [], ["とま"], ["nama keluarga langka (variant 苫)"], 11, "竹", [
        ("笘篠", "Tomashino", "contoh nama keluarga langka"),
        ("笘", "toma", "variant tikar jerami (sangat jarang)"),
        ("笘井", "Tomai", "contoh nama keluarga"),
    ], [
        ("笘篠という名字は珍しいです。", "Tomashino to iu myouji wa mezurashii desu.", "Nama keluarga \"Tomashino\" jarang."),
        ("笘という字は稀にしか使われません。", "Toma to iu ji wa mare ni shika tsukawaremasen.", "Karakter \"toma\" ini jarang digunakan."),
    ]),
    ("shishi_n1", "宍", [], ["しし"], ["daging (nama tempat)", "meat"], 8, "宀", [
        ("宍道湖", "Shinjiko", "Danau Shinji di Shimane"),
        ("宍粟", "Shisou", "nama kota di Hyogo"),
        ("宍戸", "Shishido", "contoh nama keluarga"),
    ], [
        ("宍道湖に行きました。", "Shinjiko ni ikimashita.", "Pergi ke Danau Shinji."),
        ("宍戸さんに会いました。", "Shishido-san ni aimashita.", "Bertemu dengan Shishido."),
    ]),
    ("ho4_n1", "甫", ["ホ"], [], ["awal", "agung (nama)", "beginning", "great"], 7, "田", [
        ("甫", "Hajime", "contoh nama pria"),
        ("甫生", "hosei", "istilah klasik"),
        ("台甫", "taiho", "gelar hormat klasik"),
    ], [
        ("甫さんに会いました。", "Hajime-san ni aimashita.", "Bertemu dengan Hajime."),
        ("甫という字は名前によく使われます。", "Ho to iu ji wa namae ni yoku tsukawaremasu.", "Karakter \"ho\" ini sering dipakai dalam nama."),
    ]),
    ("shaku3_n1", "酌", ["シャク"], ["く-む"], ["menuang", "mempertimbangkan", "pour", "consider"], 10, "酉", [
        ("酌む", "kumu", "menuang/mempertimbangkan"),
        ("晩酌", "banshaku", "minum sake malam hari"),
        ("酌量", "shakuryou", "pertimbangan/keringanan"),
    ], [
        ("お酌をしました。", "Oshaku o shimashita.", "Menuangkan minuman."),
        ("情状酌量が認められました。", "Joujou shakuryou ga mitomeraremashita.", "Keringanan hukuman dikabulkan."),
    ]),
    ("san6_n1", "蚕", ["サン"], ["かいこ"], ["ulat sutra", "silkworm"], 10, "虫", [
        ("蚕", "kaiko", "ulat sutra"),
        ("養蚕", "yousan", "budidaya ulat sutra"),
        ("蚕食", "sanshoku", "mencaplok sedikit demi sedikit"),
    ], [
        ("蚕を育てています。", "Kaiko o sodatete imasu.", "Memelihara ulat sutra."),
        ("養蚕業です。", "Yousangyou desu.", "Ini industri budidaya ulat sutra."),
    ]),
    ("gou4_n1", "壕", ["ゴウ"], [], ["parit pertahanan", "trench", "moat"], 17, "土", [
        ("壕", "gou", "parit"),
        ("防空壕", "boukuugou", "bunker perlindungan udara"),
        ("塹壕", "zangou", "parit perang"),
    ], [
        ("壕を掘りました。", "Gou o horimashita.", "Menggali parit."),
        ("防空壕に避難しました。", "Boukuugou ni hinan shimashita.", "Berlindung di bunker."),
    ]),
    ("ki28_n1", "嬉", ["キ"], ["うれ-しい"], ["senang", "happy"], 15, "女", [
        ("嬉しい", "ureshii", "senang"),
        ("嬉々として", "kiki to shite", "dengan gembira"),
        ("嬉遊曲", "kiyuukyoku", "divertimento (istilah musik)"),
    ], [
        ("とても嬉しいです。", "Totemo ureshii desu.", "Sangat senang."),
        ("嬉々として働いています。", "Kiki to shite hataraite imasu.", "Bekerja dengan gembira."),
    ]),
    ("hayasu_n1", "囃", [], ["はや-す"], ["musik pengiring (dalam kata majemuk)", "accompaniment music"], 15, "口", [
        ("囃子", "hayashi", "musik pengiring festival"),
        ("お囃子", "ohayashi", "musik pengiring (sopan)"),
        ("囃し立てる", "hayashitateru", "menyoraki"),
    ], [
        ("祭りの囃子です。", "Matsuri no hayashi desu.", "Ini musik pengiring festival."),
        ("囃し立てました。", "Hayashitatemashita.", "Menyoraki."),
    ]),
    ("sou28_n1", "蒼", ["ソウ"], ["あお-い"], ["biru pucat", "pale blue", "green"], 13, "艸", [
        ("蒼い", "aoi", "pucat kebiruan"),
        ("蒼白", "souhaku", "pucat"),
        ("蒼天", "souten", "langit biru"),
    ], [
        ("顔が蒼白です。", "Kao ga souhaku desu.", "Wajahnya pucat."),
        ("蒼天が広がっています。", "Souten ga hirogatte imasu.", "Langit biru membentang."),
    ]),
    ("ji5_n1", "餌", ["ジ"], ["えさ", "え"], ["umpan", "pakan", "bait", "feed"], 14, "食", [
        ("餌", "esa", "pakan/umpan"),
        ("餌食", "ejiki", "mangsa"),
        ("撒き餌", "makie", "umpan tebar"),
    ], [
        ("餌をあげました。", "Esa o agemashita.", "Memberi pakan."),
        ("餌食になりました。", "Ejiki ni narimashita.", "Menjadi mangsa."),
    ]),
    ("yana_n1", "簗", [], ["やな"], ["bendungan penangkap ikan (nama tempat)", "fish weir"], 17, "竹", [
        ("簗", "yana", "bendungan penangkap ikan"),
        ("簗瀬", "Yanase", "contoh nama keluarga"),
        ("簗場", "yanaba", "tempat bendungan ikan"),
    ], [
        ("簗で魚を捕りました。", "Yana de sakana o torimashita.", "Menangkap ikan dengan bendungan."),
        ("簗瀬さんに会いました。", "Yanase-san ni aimashita.", "Bertemu dengan Yanase."),
    ]),
    ("ji6_n1", "峙", ["ジ"], [], ["berdiri tinggi (dalam kata majemuk)", "stand tall"], 9, "山", [
        ("対峙", "taiji", "berhadapan/konfrontasi"),
        ("峙つ", "sobadatsu", "berdiri menjulang"),
        ("対峙状態", "taiji joutai", "keadaan berhadapan"),
    ], [
        ("対峙しています。", "Taiji shite imasu.", "Sedang berhadapan."),
        ("両軍が対峙しました。", "Ryougun ga taiji shimashita.", "Kedua pasukan berhadapan."),
    ]),
    ("shuku5_n1", "粥", ["シュク"], ["かゆ"], ["bubur nasi", "rice porridge"], 12, "米", [
        ("粥", "kayu", "bubur nasi"),
        ("お粥", "okayu", "bubur nasi (sopan)"),
        ("七草粥", "nanakusagayu", "bubur tujuh rempah"),
    ], [
        ("粥を食べました。", "Kayu o tabemashita.", "Makan bubur."),
        ("七草粥を作りました。", "Nanakusagayu o tsukurimashita.", "Membuat bubur tujuh rempah."),
    ]),
    ("kan34_n1", "舘", ["カン"], ["たて"], ["gedung (variant 館)", "building"], 16, "舎", [
        ("舘", "tate", "gedung"),
        ("舘ひろし", "Tate Hiroshi", "nama aktor"),
        ("舘野", "Tateno", "contoh nama keluarga"),
    ], [
        ("舘ひろしという俳優です。", "Tate Hiroshi to iu haiyuu desu.", "Ini aktor bernama Tate Hiroshi."),
        ("舘という字を使う名字です。", "Tate to iu ji o tsukau myouji desu.", "Ini nama keluarga yang menggunakan karakter \"tate\"."),
    ]),
    ("tetsu5_n1", "銕", ["テツ"], [], ["besi (variant langka 鉄)", "iron"], 14, "金", [
        ("銕", "tetsu", "besi (variant langka)"),
        ("銕野", "Tetsuno", "contoh nama keluarga langka"),
        ("銕造", "Tetsuzou", "contoh nama pria"),
    ], [
        ("銕という字は鉄の異体字です。", "Tetsu to iu ji wa tetsu no itaiji desu.", "Karakter \"tetsu\" ini adalah varian dari \"besi\"."),
        ("銕野さんという名字は珍しいです。", "Tetsuno-san to iu myouji wa mezurashii desu.", "Nama keluarga \"Tetsuno\" jarang."),
    ]),
    ("suu4_n1", "鄒", ["スウ"], [], ["Negara Zou kuno (nama)", "Zou (ancient Chinese state)"], 13, "邑", [
        ("鄒", "Suu", "marga Zou/Negara Zou kuno"),
        ("鄒衍", "Suuen", "filsuf Tiongkok kuno"),
        ("鄒国", "Suukoku", "Negara Zou"),
    ], [
        ("鄒は孟子の故郷です。", "Suu wa Moushi no kokyou desu.", "Zou adalah kampung halaman Mencius."),
        ("鄒衍という思想家です。", "Suuen to iu shisouka desu.", "Ini pemikir bernama Zou Yan."),
    ]),
    ("nina_n1", "蜷", [], ["にな"], ["siput sungai", "river snail"], 13, "虫", [
        ("蜷局", "todoguro", "melingkar seperti ular"),
        ("蜷川", "Ninagawa", "contoh nama keluarga terkenal"),
        ("蜷", "nina", "siput sungai"),
    ], [
        ("蜷川さんという有名な演出家です。", "Ninagawa-san to iu yuumei na enshutsuka desu.", "Ini sutradara terkenal bernama Ninagawa."),
        ("蜷が川にいます。", "Nina ga kawa ni imasu.", "Ada siput sungai di sungai."),
    ]),
    ("ki29_n1", "暉", ["キ"], ["てる"], ["sinar matahari (nama)", "sunlight", "shine"], 13, "日", [
        ("暉", "Teru", "contoh nama pria"),
        ("光暉", "koki", "cahaya terang"),
        ("暉一", "Kiichi", "contoh nama pria"),
    ], [
        ("暉さんに会いました。", "Teru-san ni aimashita.", "Bertemu dengan Teru."),
        ("暉一という名前です。", "Kiichi to iu namae desu.", "Ini nama Kiichi."),
    ]),
    ("hou20_n1", "捧", ["ホウ"], ["ささ-げる"], ["mempersembahkan", "offer", "dedicate"], 11, "手", [
        ("捧げる", "sasageru", "mempersembahkan"),
        ("捧呈", "houtei", "penyerahan hormat"),
        ("両手で捧げる", "ryoute de sasageru", "mempersembahkan dengan kedua tangan"),
    ], [
        ("命を捧げました。", "Inochi o sasagemashita.", "Mengorbankan nyawa."),
        ("花束を捧げました。", "Hanataba o sasagemashita.", "Mempersembahkan buket bunga."),
    ]),
    ("han15_n1", "頒", ["ハン"], [], ["mendistribusikan", "distribute"], 13, "頁", [
        ("頒布", "hanpu", "distribusi"),
        ("頒価", "hanka", "harga distribusi"),
        ("頒賜", "hanshi", "pemberian"),
    ], [
        ("頒布会です。", "Hanpukai desu.", "Ini acara distribusi."),
        ("頒価500円です。", "Hanka gohyaku-en desu.", "Harga distribusinya 500 yen."),
    ]),
    ("shi25_n1", "只", ["シ"], ["ただ"], ["hanya", "gratis", "only", "free"], 5, "口", [
        ("只", "tada", "hanya/gratis"),
        ("只今", "tadaima", "sekarang juga/aku pulang"),
        ("只管", "hitasura", "semata-mata"),
    ], [
        ("只今戻りました。", "Tadaima modorimashita.", "Aku pulang."),
        ("只管努力しました。", "Hitasura doryoku shimashita.", "Berusaha semata-mata."),
    ]),
    ("shi26_n1", "肢", ["シ"], [], ["anggota tubuh", "limb"], 8, "肉", [
        ("四肢", "shishi", "keempat anggota tubuh"),
        ("肢体", "shitai", "tubuh dan anggota badan"),
        ("選択肢", "sentakushi", "pilihan"),
    ], [
        ("四肢を動かしました。", "Shishi o ugokashimashita.", "Menggerakkan keempat anggota tubuh."),
        ("選択肢がたくさんあります。", "Sentakushi ga takusan arimasu.", "Ada banyak pilihan."),
    ]),
    ("sou29_n1", "箏", ["ソウ"], [], ["alat musik koto (variant)", "koto"], 12, "竹", [
        ("箏曲", "soukyoku", "musik koto"),
        ("箏", "sou", "koto"),
        ("箏演奏", "sou ensou", "permainan koto"),
    ], [
        ("箏曲を習っています。", "Soukyoku o naratte imasu.", "Belajar musik koto."),
        ("箏を演奏しました。", "Sou o ensou shimashita.", "Memainkan koto."),
    ]),
    ("dan4_n1", "檀", ["ダン"], [], ["kayu cendana", "altar", "sandalwood"], 17, "木", [
        ("檀家", "danka", "keluarga anggota kuil"),
        ("檀那", "danna", "suami/tuan"),
        ("白檀", "byakudan", "cendana putih"),
    ], [
        ("檀家になりました。", "Danka ni narimashita.", "Menjadi anggota keluarga kuil."),
        ("白檀の香りです。", "Byakudan no kaori desu.", "Ini aroma cendana putih."),
    ]),
    ("koku4_n1", "鵠", ["コク"], ["くぐい"], ["angsa", "sasaran", "swan", "target"], 18, "鳥", [
        ("正鵠", "seikoku", "sasaran tepat/inti masalah"),
        ("鵠", "kugui", "angsa (arkais)"),
        ("鴻鵠", "koukoku", "angsa besar (klasik)"),
    ], [
        ("正鵠を射ています。", "Seikoku o ite imasu.", "Tepat sasaran/mengenai inti."),
        ("鴻鵠の志です。", "Koukoku no kokorozashi desu.", "Ini cita-cita besar."),
    ]),
    ("gai7_n1", "凱", ["ガイ"], [], ["kemenangan", "triumphant"], 12, "几", [
        ("凱旋", "gaisen", "kemenangan pulang"),
        ("凱歌", "gaika", "lagu kemenangan"),
        ("凱風", "gaifuu", "angin selatan musim panas"),
    ], [
        ("凱旋しました。", "Gaisen shimashita.", "Pulang dengan kemenangan."),
        ("凱歌を上げました。", "Gaika o agemashita.", "Menyanyikan lagu kemenangan."),
    ]),
    ("sui12_n1", "彗", ["スイ"], [], ["komet (dalam kata majemuk)", "comet"], 11, "彐", [
        ("彗星", "suisei", "komet"),
        ("彗星のごとく", "suisei no gotoku", "seperti komet/muncul tiba-tiba"),
        ("彗掃", "suisou", "menyapu bersih (klasik)"),
    ], [
        ("彗星が現れました。", "Suisei ga arawaremashita.", "Komet muncul."),
        ("彗星のごとく現れました。", "Suisei no gotoku arawaremashita.", "Muncul seperti komet."),
    ]),
    ("tou22_n1", "謄", ["トウ"], [], ["menyalin", "copy", "transcribe"], 17, "言", [
        ("謄本", "touhon", "salinan resmi"),
        ("謄写", "tousha", "penyalinan"),
        ("戸籍謄本", "koseki touhon", "salinan akta keluarga"),
    ], [
        ("謄本を取りました。", "Touhon o torimashita.", "Mengambil salinan resmi."),
        ("戸籍謄本が必要です。", "Koseki touhon ga hitsuyou desu.", "Diperlukan salinan akta keluarga."),
    ]),
    ("kan35_n1", "諌", ["カン"], ["いさ-める"], ["menasihati (variant 諫)", "admonish"], 15, "言", [
        ("諌める", "isameru", "menasihati"),
        ("諌言", "kangen", "nasihat jujur"),
        ("直諌", "chokkan", "nasihat terus terang"),
    ], [
        ("主君を諌めました。", "Shukun o isamemashita.", "Menasihati tuan."),
        ("諌言を受け入れました。", "Kangen o ukeiremashita.", "Menerima nasihat jujur."),
    ]),
    ("kashi2_n1", "樫", [], ["かし"], ["pohon ek", "oak"], 16, "木", [
        ("樫", "kashi", "pohon ek"),
        ("樫の木", "kashi no ki", "pohon ek"),
        ("樫鳥", "kashidori", "burung jay Eurasia"),
    ], [
        ("樫の木があります。", "Kashi no ki ga arimasu.", "Ada pohon ek."),
        ("樫の家具です。", "Kashi no kagu desu.", "Ini furnitur kayu ek."),
    ]),
    ("uwasa_n1", "噂", [], ["うわさ"], ["gosip", "rumor"], 15, "口", [
        ("噂", "uwasa", "gosip/rumor"),
        ("噂話", "uwasabanashi", "obrolan gosip"),
        ("悪い噂", "warui uwasa", "gosip buruk"),
    ], [
        ("噂を聞きました。", "Uwasa o kikimashita.", "Mendengar gosip."),
        ("噂話が広まりました。", "Uwasabanashi ga hiromarimashita.", "Obrolan gosip menyebar."),
    ]),
    ("seki5_n1", "脊", ["セキ"], [], ["tulang belakang", "spine"], 10, "肉", [
        ("脊椎", "sekitsui", "tulang belakang"),
        ("脊髄", "sekizui", "sumsum tulang belakang"),
        ("脊柱", "sekichuu", "kolom tulang belakang"),
    ], [
        ("脊柱側弯症です。", "Sekichuu sokuwanshou desu.", "Ini skoliosis."),
        ("脊椎を痛めました。", "Sekitsui o itamemashita.", "Melukai tulang belakang."),
    ]),
    ("hin5_n1", "牝", ["ヒン"], ["めす"], ["betina (variant 雌)", "female (animal)"], 6, "牛", [
        ("牝", "mesu", "betina"),
        ("牝馬", "bin-ba", "kuda betina"),
        ("牝牛", "mesushi", "sapi betina"),
    ], [
        ("牝馬レースです。", "Bin-ba reesu desu.", "Ini balapan kuda betina."),
        ("牝牛を飼っています。", "Mesushi o katte imasu.", "Memelihara sapi betina."),
    ]),
    ("shi27_n1", "梓", ["シ"], ["あずさ"], ["pohon catalpa", "menerbitkan (nama)", "catalpa tree"], 11, "木", [
        ("梓", "azusa", "pohon catalpa"),
        ("上梓", "joushi", "penerbitan buku"),
        ("梓弓", "azusayumi", "busur kayu catalpa"),
    ], [
        ("上梓しました。", "Joushi shimashita.", "Menerbitkan buku."),
        ("梓の木があります。", "Azusa no ki ga arimasu.", "Ada pohon catalpa."),
    ]),
    ("raku2_n1", "洛", ["ラク"], [], ["ibu kota (dalam kata majemuk, Kyoto)", "capital city"], 9, "水", [
        ("上洛", "jouraku", "pergi ke ibu kota/Kyoto"),
        ("洛中", "rakuchuu", "dalam kota Kyoto"),
        ("洛陽", "Rakuyou", "Kota Luoyang Tiongkok"),
    ], [
        ("上洛しました。", "Jouraku shimashita.", "Pergi ke Kyoto."),
        ("洛中に住んでいます。", "Rakuchuu ni sunde imasu.", "Tinggal di dalam kota Kyoto."),
    ]),
    ("dai_n1", "醍", ["ダイ", "タイ"], [], ["mentega murni (dalam kata majemuk)", "refined butter"], 16, "酉", [
        ("醍醐味", "daigomi", "kenikmatan sejati"),
        ("醍醐", "Daigo", "distrik di Kyoto/produk susu kuno"),
        ("醍醐天皇", "Daigo Tennou", "Kaisar Daigo"),
    ], [
        ("醍醐味を味わいました。", "Daigomi o ajiwaimashita.", "Merasakan kenikmatan sejati."),
        ("醍醐寺を訪れました。", "Daigoji o otozuremashita.", "Mengunjungi Kuil Daigo."),
    ]),
    ("sai12_n1", "砦", ["サイ"], ["とりで"], ["benteng", "fort"], 11, "石", [
        ("砦", "toride", "benteng"),
        ("山砦", "sansai", "benteng gunung"),
        ("最後の砦", "saigo no toride", "benteng terakhir"),
    ], [
        ("砦を築きました。", "Toride o kizukimashita.", "Membangun benteng."),
        ("最後の砦です。", "Saigo no toride desu.", "Ini benteng terakhir."),
    ]),
    ("chuu6_n1", "丑", ["チュウ"], ["うし"], ["shio kerbau", "ox zodiac"], 4, "一", [
        ("丑", "ushi", "tahun kerbau dalam zodiak"),
        ("丑年", "ushidoshi", "tahun kerbau"),
        ("丑三つ時", "ushimitsudoki", "tengah malam (istilah kuno)"),
    ], [
        ("丑年生まれです。", "Ushidoshi umare desu.", "Lahir di tahun kerbau."),
        ("丑三つ時に起きました。", "Ushimitsudoki ni okimashita.", "Bangun tengah malam."),
    ]),
    ("kotsu_n1", "笏", ["コツ"], ["しゃく"], ["tongkat upacara", "ceremonial baton"], 10, "竹", [
        ("笏", "shaku", "tongkat upacara"),
        ("笏を持つ", "shaku o motsu", "memegang tongkat upacara"),
        ("木笏", "mokushaku", "tongkat kayu"),
    ], [
        ("笏を持っています。", "Shaku o motte imasu.", "Memegang tongkat upacara."),
        ("神主が笏を持ちました。", "Kannushi ga shaku o mochimashita.", "Pendeta Shinto memegang tongkat upacara."),
    ]),
    ("ketsu4_n1", "蕨", ["ケツ"], ["わらび"], ["pakis", "bracken fern"], 15, "艸", [
        ("蕨", "warabi", "pakis"),
        ("蕨餅", "warabimochi", "kue mochi pakis"),
        ("蕨市", "Warabi-shi", "nama kota di Saitama"),
    ], [
        ("蕨餅を食べました。", "Warabimochi o tabemashita.", "Makan kue mochi pakis."),
        ("蕨市に住んでいます。", "Warabi-shi ni sunde imasu.", "Tinggal di kota Warabi."),
    ]),
    ("hanashi_n1", "噺", [], ["はなし"], ["cerita (rakugo)", "story"], 16, "口", [
        ("噺家", "hanashika", "pencerita rakugo"),
        ("人情噺", "ninjoubanashi", "cerita rakugo penuh emosi"),
        ("噺", "hanashi", "cerita"),
    ], [
        ("噺家になりました。", "Hanashika ni narimashita.", "Menjadi pencerita rakugo."),
        ("人情噺を聞きました。", "Ninjoubanashi o kikimashita.", "Mendengarkan cerita rakugo penuh emosi."),
    ]),
    ("jo5_n1", "抒", ["ジョ"], [], ["mengungkapkan (dalam kata majemuk)", "express"], 7, "手", [
        ("抒情", "jojou", "lirisisme"),
        ("抒情詩", "jojoushi", "puisi liris"),
        ("抒情的", "jojouteki", "liris"),
    ], [
        ("抒情詩を書きました。", "Jojoushi o kakimashita.", "Menulis puisi liris."),
        ("抒情的な曲です。", "Jojouteki na kyoku desu.", "Ini lagu yang liris."),
    ]),
    ("shi28_n1", "嗣", ["シ"], [], ["pewaris", "heir", "successor"], 13, "口", [
        ("嗣子", "shishi", "anak pewaris"),
        ("継嗣", "keishi", "penerus"),
        ("皇嗣", "koushi", "pewaris takhta"),
    ], [
        ("嗣子として生まれました。", "Shishi toshite umaremashita.", "Lahir sebagai anak pewaris."),
        ("皇嗣殿下です。", "Koushi denka desu.", "Ini Yang Mulia Putra Mahkota."),
    ]),
    ("wai2_n1", "隈", ["ワイ"], ["くま"], ["bayangan", "sudut tersembunyi", "shade", "nook"], 12, "阜", [
        ("隈", "kuma", "bayangan/kantong mata"),
        ("隈取り", "kumadori", "riasan kabuki"),
        ("隈なく", "kumanaku", "di setiap sudut"),
    ], [
        ("目の下に隈があります。", "Me no shita ni kuma ga arimasu.", "Ada kantong mata."),
        ("隈取りをしました。", "Kumadori o shimashita.", "Menerapkan riasan kabuki."),
    ]),
    ("kyou19_n1", "叶", ["キョウ"], ["かな-う"], ["terkabul", "grant", "fulfill"], 5, "口", [
        ("叶う", "kanau", "terkabul/tercapai"),
        ("叶える", "kanaeru", "mengabulkan"),
        ("願いが叶う", "negai ga kanau", "permohonan terkabul"),
    ], [
        ("夢が叶いました。", "Yume ga kanaimashita.", "Mimpi menjadi kenyataan."),
        ("願いを叶えました。", "Negai o kanaemashita.", "Mengabulkan permohonan."),
    ]),
    ("sei15_n1", "凄", ["セイ"], ["すご-い"], ["hebat", "mengerikan", "terrific", "dreadful"], 10, "冫", [
        ("凄い", "sugoi", "hebat/luar biasa"),
        ("凄惨", "seisan", "mengerikan"),
        ("凄腕", "sugoude", "ahli/jago"),
    ], [
        ("凄い記録です。", "Sugoi kiroku desu.", "Ini rekor yang hebat."),
        ("凄惨な事件でした。", "Seisan na jiken deshita.", "Ini kasus yang mengerikan."),
    ]),
    ("shio_n1", "汐", [], ["しお"], ["air pasang malam (variant 潮)", "evening tide"], 6, "水", [
        ("汐", "shio", "air pasang"),
        ("汐留", "Shiodome", "nama daerah di Tokyo"),
        ("汐風", "shiokaze", "angin laut"),
    ], [
        ("汐留に行きました。", "Shiodome ni ikimashita.", "Pergi ke Shiodome."),
        ("汐風が心地よいです。", "Shiokaze ga kokochiyoi desu.", "Angin lautnya menyenangkan."),
    ]),
    ("ken17_n1", "絢", ["ケン"], ["あや"], ["pola warna-warni (dalam kata majemuk)", "colorful pattern"], 12, "糸", [
        ("絢爛", "kenran", "gemerlap"),
        ("絢子", "Ayako", "contoh nama wanita"),
        ("絢辻", "Ayatsuji", "contoh nama"),
    ], [
        ("絢爛豪華です。", "Kenran gouka desu.", "Ini gemerlap dan mewah."),
        ("絢子さんに会いました。", "Ayako-san ni aimashita.", "Bertemu dengan Ayako."),
    ]),
    ("kou38_n1", "叩", ["コウ"], ["たた-く"], ["memukul", "hit", "strike"], 5, "口", [
        ("叩く", "tataku", "memukul/mengetuk"),
        ("叩き台", "tatakidai", "draf awal"),
        ("叩き売り", "tatakiuri", "jual obral"),
    ], [
        ("ドアを叩きました。", "Doa o tatakimashita.", "Mengetuk pintu."),
        ("叩き台を作りました。", "Tatakidai o tsukurimashita.", "Membuat draf awal."),
    ]),
    ("shitsu6_n1", "嫉", ["シツ"], ["ねた-む"], ["cemburu", "jealous"], 13, "女", [
        ("嫉妬", "shitto", "kecemburuan"),
        ("嫉む", "netamu", "iri hati"),
        ("嫉視", "shisshi", "memandang dengan iri"),
    ], [
        ("嫉妬しています。", "Shitto shite imasu.", "Sedang cemburu."),
        ("嫉んでいます。", "Netande imasu.", "Iri hati."),
    ]),
    ("saku6_n1", "朔", ["サク"], [], ["bulan baru", "utara", "new moon", "north"], 10, "月", [
        ("朔日", "tsuitachi", "tanggal 1"),
        ("朔風", "sakufuu", "angin utara"),
        ("朔望", "sakubou", "siklus bulan baru-purnama"),
    ], [
        ("朔日です。", "Tsuitachi desu.", "Ini tanggal 1."),
        ("朔風が吹いています。", "Sakufuu ga fuite imasu.", "Angin utara bertiup."),
    ]),
    ("sai13_n1", "蔡", ["サイ"], [], ["marga Cai", "Cai (surname)"], 14, "艸", [
        ("蔡", "Sai", "marga Cai"),
        ("蔡倫", "Sairin", "Cai Lun, penemu kertas"),
        ("蔡国", "Saikoku", "Negara Cai kuno"),
    ], [
        ("蔡倫は紙を発明しました。", "Sairin wa kami o hatsumei shimashita.", "Cai Lun menemukan kertas."),
        ("蔡という姓です。", "Sai to iu sei desu.", "Ini marga Cai."),
    ]),
    ("shitsu7_n1", "膝", ["シツ"], ["ひざ"], ["lutut", "knee"], 15, "肉", [
        ("膝", "hiza", "lutut"),
        ("膝小僧", "hizakozou", "lutut (informal)"),
        ("膝枕", "hizamakura", "bantal paha"),
    ], [
        ("膝が痛いです。", "Hiza ga itai desu.", "Lutut sakit."),
        ("膝枕をしました。", "Hizamakura o shimashita.", "Memberikan bantal paha."),
    ]),
    ("shou42_n1", "鍾", ["ショウ"], [], ["berkumpul", "lonceng (nama)", "gather", "bell"], 17, "金", [
        ("鍾乳洞", "shounyoudou", "gua stalaktit"),
        ("鍾愛", "shouai", "kasih sayang mendalam"),
        ("鍾馗", "Shouki", "dewa pengusir setan"),
    ], [
        ("鍾乳洞を探検しました。", "Shounyoudou o tanken shimashita.", "Menjelajahi gua stalaktit."),
        ("鍾馗様です。", "Shouki-sama desu.", "Ini Dewa Shouki."),
    ]),
    ("kyuu14_n1", "仇", ["キュウ"], ["あだ"], ["musuh", "dendam", "enemy", "grudge"], 4, "人", [
        ("仇", "ada", "musuh/dendam"),
        ("仇討ち", "adauchi", "balas dendam"),
        ("仇敵", "kyuuteki", "musuh bebuyutan"),
    ], [
        ("仇を討ちました。", "Ada o uchimashita.", "Membalas dendam."),
        ("仇敵として知られています。", "Kyuuteki toshite shirarete imasu.", "Dikenal sebagai musuh bebuyutan."),
    ]),
    ("ka20_n1", "伽", ["カ"], [], ["menemani (dalam kata majemuk)", "companion", "entertain"], 7, "人", [
        ("御伽話", "otogibanashi", "dongeng"),
        ("伽藍", "garan", "kompleks kuil Buddha"),
        ("夜伽", "yotogi", "menemani malam hari"),
    ], [
        ("御伽話を読みました。", "Otogibanashi o yomimashita.", "Membaca dongeng."),
        ("伽藍を見学しました。", "Garan o kengaku shimashita.", "Mengunjungi kompleks kuil."),
    ]),
    ("i13_n1", "夷", ["イ"], [], ["orang barbar", "barbarian"], 6, "大", [
        ("夷狄", "iteki", "orang barbar"),
        ("蝦夷", "Ezo", "sebutan lama untuk Hokkaido/suku Ainu"),
        ("攘夷", "jouI", "mengusir orang asing"),
    ], [
        ("蝦夷地でした。", "Ezochi deshita.", "Ini adalah tanah Ezo."),
        ("尊皇攘夷という思想です。", "Sonnou jouI to iu shisou desu.", "Ini adalah paham \"hormati kaisar, usir orang asing\"."),
    ]),
    ("shi29_n1", "恣", ["シ"], [], ["sewenang-wenang (dalam kata majemuk)", "self-indulgent"], 10, "心", [
        ("恣意的", "shiiteki", "sewenang-wenang"),
        ("放恣", "houshi", "tidak terkendali"),
        ("恣行", "shikou", "bertindak sewenang-wenang"),
    ], [
        ("恣意的な判断です。", "Shiiteki na handan desu.", "Ini penilaian yang sewenang-wenang."),
        ("恣意的に決めないでください。", "Shiiteki ni kimenaide kudasai.", "Jangan memutuskan secara sewenang-wenang."),
    ]),
    ("mei3_n1", "瞑", ["メイ"], ["つぶ-る"], ["memejamkan mata (dalam kata majemuk)", "close eyes"], 15, "目", [
        ("瞑想", "meisou", "meditasi"),
        ("瞑目", "meimoku", "memejamkan mata/meninggal dengan tenang"),
        ("瞑る", "tsuburu", "memejamkan mata"),
    ], [
        ("瞑想をしています。", "Meisou o shite imasu.", "Sedang bermeditasi."),
        ("瞑目しました。", "Meimoku shimashita.", "Memejamkan mata (meninggal dengan tenang)."),
    ]),
    ("bo6_n1", "畝", ["ボ"], ["うね"], ["bedengan", "satuan luas", "ridge", "are"], 10, "田", [
        ("畝", "une", "bedengan"),
        ("畝織り", "uneori", "tenunan bergaris"),
        ("一畝", "ippo", "satu are (satuan luas)"),
    ], [
        ("畝を作りました。", "Une o tsukurimashita.", "Membuat bedengan."),
        ("畝織りの生地です。", "Uneori no kiji desu.", "Ini kain tenunan bergaris."),
    ]),
    ("shou43_n1", "抄", ["ショウ"], [], ["kutipan", "excerpt", "summary"], 7, "手", [
        ("抄録", "shouroku", "ringkasan"),
        ("抄本", "shouhon", "salinan sebagian"),
        ("抜抄", "basshou", "kutipan terpilih"),
    ], [
        ("抄録を書きました。", "Shouroku o kakimashita.", "Menulis ringkasan."),
        ("戸籍抄本です。", "Koseki shouhon desu.", "Ini salinan sebagian akta keluarga."),
    ]),
    ("kou39_n1", "杭", ["コウ"], ["くい"], ["pancang", "stake", "pile"], 8, "木", [
        ("杭", "kui", "pancang"),
        ("杭打ち", "kuiuchi", "pemancangan"),
        ("橋杭", "hashigui", "tiang pancang jembatan"),
    ], [
        ("杭を打ちました。", "Kui o uchimashita.", "Memancangkan tiang."),
        ("杭打ち工事です。", "Kuiuchi kouji desu.", "Ini pekerjaan pemancangan."),
    ]),
    ("guu2_n1", "寓", ["グウ"], [], ["alegori", "tempat tinggal", "allegory", "dwelling"], 12, "宀", [
        ("寓話", "guuwa", "fabel/alegori"),
        ("寓意", "guui", "makna tersirat"),
        ("寄寓", "kiguu", "menumpang tinggal"),
    ], [
        ("寓話を読みました。", "Guuwa o yomimashita.", "Membaca fabel."),
        ("寓意が込められています。", "Guui ga komerarete imasu.", "Mengandung makna tersirat."),
    ]),
    ("men2_n1", "麺", ["メン"], [], ["mi", "noodle"], 16, "麦", [
        ("麺", "men", "mi"),
        ("麺類", "menrui", "jenis mi"),
        ("麺棒", "menbou", "penggilas adonan"),
    ], [
        ("麺を食べました。", "Men o tabemashita.", "Makan mi."),
        ("麺類が好きです。", "Menrui ga suki desu.", "Suka jenis mi."),
    ]),
    ("tai10_n1", "戴", ["タイ"], [], ["menerima dengan hormat (dalam kata majemuk)", "receive with respect"], 17, "戈", [
        ("戴く", "itadaku", "menerima dengan hormat"),
        ("推戴", "suitai", "mengangkat sebagai pemimpin"),
        ("戴冠式", "taikanshiki", "upacara penobatan"),
    ], [
        ("戴冠式が行われました。", "Taikanshiki ga okonawaremashita.", "Upacara penobatan dilaksanakan."),
        ("推戴されました。", "Suitai saremashita.", "Diangkat sebagai pemimpin."),
    ]),
    ("sou30_n1", "爽", ["ソウ"], ["さわ-やか"], ["segar", "refreshing"], 11, "大", [
        ("爽やか", "sawayaka", "segar/menyegarkan"),
        ("爽快", "soukai", "menyegarkan"),
        ("颯爽", "sassou", "gagah dan segar"),
    ], [
        ("爽やかな朝です。", "Sawayaka na asa desu.", "Ini pagi yang segar."),
        ("爽快な気分です。", "Soukai na kibun desu.", "Ini perasaan yang menyegarkan."),
    ]),
    ("suso_n1", "裾", [], ["すそ"], ["kelim", "hem"], 13, "衣", [
        ("裾", "suso", "kelim"),
        ("裾野", "susono", "kaki gunung/lereng"),
        ("山裾", "yamasuso", "kaki gunung"),
    ], [
        ("裾が長いです。", "Suso ga nagai desu.", "Kelimnya panjang."),
        ("裾野が広がっています。", "Susono ga hirogatte imasu.", "Kaki gunungnya membentang."),
    ]),
    ("rei8_n1", "黎", ["レイ"], [], ["fajar", "banyak (dalam kata majemuk)", "dawn", "multitude"], 15, "黍", [
        ("黎明", "reimei", "fajar"),
        ("黎明期", "reimeiki", "masa awal"),
        ("黎民", "reimin", "rakyat jelata"),
    ], [
        ("黎明期でした。", "Reimeiki deshita.", "Ini adalah masa awal."),
        ("黎明を迎えました。", "Reimei o mukaemashita.", "Menyambut fajar."),
    ]),
    ("da5_n1", "惰", ["ダ"], [], ["malas", "lazy", "inertia"], 12, "心", [
        ("惰性", "dasei", "inersia/kebiasaan"),
        ("怠惰", "taida", "kemalasan"),
        ("惰眠", "damin", "tidur malas-malasan"),
    ], [
        ("惰性で続けています。", "Dasei de tsuzukete imasu.", "Melanjutkan karena kebiasaan/inersia."),
        ("怠惰な生活です。", "Taida na seikatsu desu.", "Ini kehidupan yang malas."),
    ]),
    ("za2_n1", "坐", ["ザ"], ["すわ-る"], ["duduk (variant 座)", "sit"], 7, "土", [
        ("坐る", "suwaru", "duduk"),
        ("坐禅", "zazen", "meditasi duduk"),
        ("正坐", "seiza", "duduk formal"),
    ], [
        ("坐禅を組みました。", "Zazen o kumimashita.", "Melakukan meditasi duduk."),
        ("正坐しました。", "Seiza shimashita.", "Duduk dengan formal."),
    ]),
    ("shin19_n1", "鍼", ["シン"], ["はり"], ["jarum akupuntur", "acupuncture needle"], 17, "金", [
        ("鍼", "hari", "jarum akupuntur"),
        ("鍼灸", "shinkyuu", "akupuntur dan moksibusi"),
        ("鍼治療", "harichiryou", "terapi akupuntur"),
    ], [
        ("鍼を受けました。", "Hari o ukemashita.", "Menjalani akupuntur."),
        ("鍼灸院に行きました。", "Shinkyuuin ni ikimashita.", "Pergi ke klinik akupuntur."),
    ]),
    ("ban3_n1", "蛮", ["バン"], [], ["barbar", "barbarian"], 12, "虫", [
        ("野蛮", "yaban", "biadab"),
        ("蛮行", "bankou", "tindakan biadab"),
        ("南蛮", "nanban", "orang selatan/Eropa"),
    ], [
        ("野蛮な行為です。", "Yaban na koui desu.", "Ini tindakan biadab."),
        ("南蛮貿易でした。", "Nanban boueki deshita.", "Ini perdagangan dengan orang Eropa."),
    ]),
    ("hanawa_n1", "塙", [], ["はなわ"], ["tanah keras (nama keluarga)", "hard ground"], 13, "土", [
        ("塙", "Hanawa", "contoh nama keluarga terkenal"),
        ("塙保己一", "Hanawa Hokiichi", "tokoh sejarah"),
        ("塙田", "Hanawada", "contoh nama tempat"),
    ], [
        ("塙保己一は有名な学者です。", "Hanawa Hokiichi wa yuumei na gakusha desu.", "Hanawa Hokiichi adalah cendekiawan terkenal."),
        ("塙さんに会いました。", "Hanawa-san ni aimashita.", "Bertemu dengan Hanawa."),
    ]),
    ("sae_n1", "冴", [], ["さ-える"], ["jernih", "mahir", "clear", "skillful"], 7, "冫", [
        ("冴える", "saeru", "jernih/tajam pikiran"),
        ("冴え渡る", "saewataru", "sangat jernih"),
        ("冴えない", "saenai", "kurang bersinar/membosankan"),
    ], [
        ("頭が冴えています。", "Atama ga saete imasu.", "Pikirannya jernih."),
        ("冴えない毎日です。", "Saenai mainichi desu.", "Ini hari-hari yang membosankan."),
    ]),
    ("ou9_n1", "旺", ["オウ"], [], ["makmur", "terang", "prosperous", "bright"], 8, "日", [
        ("旺盛", "ousei", "penuh semangat/subur"),
        ("旺文社", "Oubunsha", "nama penerbit"),
        ("旺然", "ouzen", "cemerlang"),
    ], [
        ("食欲が旺盛です。", "Shokuyoku ga ousei desu.", "Nafsu makannya besar."),
        ("旺文社の辞書です。", "Oubunsha no jisho desu.", "Ini kamus terbitan Obunsha."),
    ]),
    ("i14_n1", "葦", ["イ"], ["あし"], ["alang-alang", "reed"], 12, "艸", [
        ("葦", "ashi", "alang-alang"),
        ("葦原", "ashihara", "ladang alang-alang"),
        ("葦笛", "ashibue", "seruling alang-alang"),
    ], [
        ("葦が生えています。", "Ashi ga haete imasu.", "Alang-alang tumbuh."),
        ("葦原が広がっています。", "Ashihara ga hirogatte imasu.", "Ladang alang-alang membentang."),
    ]),
    ("iso2_n1", "礒", [], ["いそ"], ["pantai berbatu (variant 磯, nama keluarga)", "rocky shore"], 18, "石", [
        ("礒", "iso", "pantai berbatu"),
        ("礒野", "Isono", "contoh nama keluarga"),
        ("礒部", "Isobe", "contoh nama keluarga"),
    ], [
        ("礒野さんという名前です。", "Isono-san to iu namae desu.", "Ini nama Isono."),
        ("礒部さんに会いました。", "Isobe-san ni aimashita.", "Bertemu dengan Isobe."),
    ]),
    ("kan36_n1", "咸", ["カン"], [], ["semua (arkais, nama)", "all", "complete"], 9, "口", [
        ("咸鏡道", "Kankyoudou", "provinsi Korea Utara"),
        ("咸陽", "Kan-you", "ibu kota Dinasti Qin kuno"),
        ("咸和", "Kanwa", "nama era historis"),
    ], [
        ("咸陽は秦の都でした。", "Kan-you wa Shin no miyako deshita.", "Xianyang adalah ibu kota Dinasti Qin."),
        ("咸鏡道という地名です。", "Kankyoudou to iu chimei desu.", "Ini nama tempat Hamgyong."),
    ]),
    ("hou21_n1", "萌", ["ホウ"], ["きざ-す", "も-える"], ["bertunas", "sprout", "budding"], 11, "艸", [
        ("萌え", "moe", "bertunas"),
        ("萌芽", "houga", "tunas/awal mula"),
        ("萌黄色", "moegiiro", "warna hijau muda"),
    ], [
        ("萌芽が見られます。", "Houga ga miraremasu.", "Terlihat tunas."),
        ("萌黄色の葉です。", "Moegiiro no ha desu.", "Ini daun berwarna hijau muda."),
    ]),
    ("kyou20_n1", "饗", ["キョウ"], ["あえ"], ["menjamu", "feast", "entertain"], 22, "食", [
        ("饗宴", "kyouen", "jamuan/perjamuan"),
        ("饗応", "kyouou", "menjamu"),
        ("供饗", "kugyou", "sesajen"),
    ], [
        ("饗宴が開かれました。", "Kyouen ga hirakaremashita.", "Jamuan diadakan."),
        ("饗応を受けました。", "Kyouou o ukemashita.", "Dijamu."),
    ]),
    ("wai3_n1", "歪", ["ワイ"], ["ゆが-む", "いびつ"], ["bengkok", "terdistorsi", "distorted"], 9, "一", [
        ("歪む", "yugamu", "bengkok/terdistorsi"),
        ("歪曲", "waikyoku", "distorsi"),
        ("歪み", "yugami", "penyimpangan/distorsi"),
    ], [
        ("顔が歪みました。", "Kao ga yugamimashita.", "Wajahnya berkerut."),
        ("事実を歪曲しました。", "Jijitsu o waikyoku shimashita.", "Mendistorsi fakta."),
    ]),
    ("mei4_n1", "冥", ["メイ", "ミョウ"], [], ["gelap", "alam baka", "dark", "underworld"], 10, "冖", [
        ("冥土", "meido", "alam baka"),
        ("冥福", "meifuku", "kebahagiaan di akhirat"),
        ("冥利", "myouri", "berkah tersembunyi"),
    ], [
        ("冥福を祈ります。", "Meifuku o inorimasu.", "Mendoakan kebahagiaan di akhirat."),
        ("冥利に尽きます。", "Myouri ni tsukimasu.", "Ini berkah yang luar biasa."),
    ]),
    ("shi30_n1", "偲", ["シ"], ["しの-ぶ"], ["mengenang (nama)", "reminisce"], 11, "人", [
        ("偲ぶ", "shinobu", "mengenang"),
        ("偲び会", "shinobikai", "acara mengenang almarhum"),
        ("偲", "Shinobu", "contoh nama"),
    ], [
        ("故人を偲びました。", "Kojin o shinobimashita.", "Mengenang almarhum."),
        ("偲び会を開きました。", "Shinobikai o hirakimashita.", "Mengadakan acara mengenang."),
    ]),
    ("ichi_n1", "壱", ["イチ"], [], ["satu (formal, dokumen)", "one"], 7, "士", [
        ("壱万円", "ichiman-en", "sepuluh ribu yen (formal)"),
        ("壱岐", "Iki", "nama pulau"),
        ("第壱", "dai-ichi", "nomor satu (formal)"),
    ], [
        ("金壱万円也。", "Kin ichiman-en nari.", "Uang sejumlah sepuluh ribu yen (formal)."),
        ("壱岐島に行きました。", "Iki-jima ni ikimashita.", "Pergi ke Pulau Iki."),
    ]),
    ("ru_n1", "瑠", ["ル"], [], ["lapis lazuli (dalam kata majemuk)"], 14, "玉", [
        ("瑠璃", "ruri", "lapis lazuli"),
        ("瑠璃色", "ruriiro", "warna biru lapis lazuli"),
        ("浄瑠璃", "joururi", "teater boneka tradisional Jepang"),
    ], [
        ("瑠璃色の海です。", "Ruriiro no umi desu.", "Ini laut berwarna biru lapis lazuli."),
        ("浄瑠璃を見ました。", "Joururi o mimashita.", "Menonton teater boneka joururi."),
    ]),
    ("kyuu15_n1", "韮", [], ["にら"], ["bawang kucai", "garlic chives"], 17, "韭", [
        ("韮", "nira", "bawang kucai"),
        ("韮山", "Nirayama", "nama tempat di Shizuoka"),
        ("韮崎", "Nirasaki", "nama kota di Yamanashi"),
    ], [
        ("韮を炒めました。", "Nira o itamemashita.", "Menumis bawang kucai."),
        ("韮崎市に行きました。", "Nirasaki-shi ni ikimashita.", "Pergi ke kota Nirasaki."),
    ]),
    ("sou31_n1", "漕", ["ソウ"], ["こ-ぐ"], ["mendayung", "row (boat)"], 14, "水", [
        ("漕ぐ", "kogu", "mendayung"),
        ("競漕", "kyousou", "lomba dayung"),
        ("漕艇", "soutei", "olahraga dayung"),
    ], [
        ("ボートを漕ぎました。", "Booto o kogimashita.", "Mendayung perahu."),
        ("競漕大会です。", "Kyousou taikai desu.", "Ini kompetisi lomba dayung."),
    ]),
    ("sho5_n1", "杵", ["ショ"], ["きね"], ["alu", "pestle"], 8, "木", [
        ("杵", "kine", "alu"),
        ("杵つき", "kinetsuki", "menumbuk dengan alu"),
        ("石杵", "ishikine", "alu batu"),
    ], [
        ("杵で餅をつきました。", "Kine de mochi o tsukimashita.", "Menumbuk mochi dengan alu."),
        ("杵つきの餅です。", "Kinetsuki no mochi desu.", "Ini mochi tumbukan alu."),
    ]),
    ("shou44_n1", "薔", ["ショウ", "シ"], [], ["mawar (dalam kata majemuk)", "rose"], 15, "艸", [
        ("薔薇", "bara", "bunga mawar"),
        ("薔薇色", "barairo", "warna mawar/merah muda"),
        ("野薔薇", "nobara", "mawar liar"),
    ], [
        ("薔薇の花束です。", "Bara no hanataba desu.", "Ini buket bunga mawar."),
        ("薔薇色の人生です。", "Barairo no jinsei desu.", "Ini kehidupan yang cerah."),
    ]),
    ("kou40_n1", "膠", ["コウ"], ["にかわ"], ["lem hewani", "glue"], 15, "肉", [
        ("膠", "nikawa", "lem hewani"),
        ("膠着", "kouchaku", "kebuntuan/kemandekan"),
        ("膠質", "koushitsu", "koloid"),
    ], [
        ("膠着状態です。", "Kouchaku joutai desu.", "Ini keadaan buntu."),
        ("膠で接着しました。", "Nikawa de setchaku shimashita.", "Direkatkan dengan lem hewani."),
    ]),
    ("in8_n1", "允", ["イン"], [], ["menyetujui", "tulus (nama)", "consent", "sincere"], 4, "儿", [
        ("允許", "inkyo", "persetujuan"),
        ("允", "Makoto", "contoh nama pria"),
        ("允恭天皇", "Ingyou Tennou", "Kaisar Ingyo"),
    ], [
        ("允許されました。", "Inkyo saremashita.", "Disetujui."),
        ("允恭天皇の時代です。", "Ingyou Tennou no jidai desu.", "Ini era Kaisar Ingyo."),
    ]),
    ("shin20_n1", "眞", ["シン"], ["まこと"], ["benar (bentuk tradisional 真)", "true"], 10, "目", [
        ("眞", "Makoto", "contoh nama (variant tradisional dari 真)"),
        ("眞紀子", "Makiko", "contoh nama wanita"),
        ("写眞", "shashin", "foto (variant tradisional)"),
    ], [
        ("眞という字は真の異体字です。", "Shin to iu ji wa shin no itaiji desu.", "Karakter ini adalah varian dari \"shin/benar\"."),
        ("眞紀子さんに会いました。", "Makiko-san ni aimashita.", "Bertemu dengan Makiko."),
    ]),
    ("mou6_n1", "蒙", ["モウ"], [], ["bodoh", "Mongolia", "ignorant"], 13, "艸", [
        ("蒙古", "Mouko", "Mongolia"),
        ("啓蒙", "keimou", "pencerahan"),
        ("無知蒙昧", "muchi moumai", "sangat bodoh"),
    ], [
        ("蒙古襲来です。", "Mouko shuurai desu.", "Ini invasi Mongol."),
        ("啓蒙思想です。", "Keimou shisou desu.", "Ini pemikiran pencerahan."),
    ]),
    ("ban4_n1", "蕃", ["バン"], [], ["subur", "asing", "flourish", "foreign"], 15, "艸", [
        ("蕃殖", "hanshoku", "berkembang biak"),
        ("蕃族", "banzoku", "suku asing (istilah lama)"),
        ("蕃社", "bansha", "desa suku asli Taiwan"),
    ], [
        ("蕃殖しました。", "Hanshoku shimashita.", "Berkembang biak."),
        ("蕃族という呼称でした。", "Banzoku to iu koshou deshita.", "Ini sebutan \"suku asing\"."),
    ]),
    ("ton4_n1", "呑", ["ドン"], ["の-む"], ["menelan (variant 飲む)", "swallow"], 7, "口", [
        ("呑む", "nomu", "menelan/minum"),
        ("鵜呑み", "unomi", "menelan bulat-bulat"),
        ("呑気", "nonki", "santai"),
    ], [
        ("呑気な性格です。", "Nonki na seikaku desu.", "Kepribadian yang santai."),
        ("一気に呑みました。", "Ikki ni nomimashita.", "Menenggak sekaligus."),
    ]),
    ("kou41_n1", "侯", ["コウ"], [], ["bangsawan", "marquis", "lord"], 9, "人", [
        ("諸侯", "shokou", "para bangsawan feodal"),
        ("侯爵", "koushaku", "marquis"),
        ("王侯", "ouko", "raja dan bangsawan"),
    ], [
        ("諸侯が集まりました。", "Shokou ga atsumarimashita.", "Para bangsawan berkumpul."),
        ("侯爵になりました。", "Koushaku ni narimashita.", "Menjadi marquis."),
    ]),
    ("tai11_n1", "碓", ["タイ"], ["うす"], ["lesung batu (nama tempat)", "mortar (stone)"], 13, "石", [
        ("碓氷峠", "Usui Touge", "nama tempat terkenal di Nagano"),
        ("碓", "usu", "lesung batu"),
        ("碓井", "Usui", "contoh nama keluarga"),
    ], [
        ("碓氷峠を越えました。", "Usui Touge o koemashita.", "Melewati Pass Usui."),
        ("碓氷峠は有名な峠です。", "Usui Touge wa yuumei na touge desu.", "Pass Usui adalah jalur gunung terkenal."),
    ]),
    ("mei5_n1", "茗", ["メイ"], [], ["teh (dalam kata majemuk, nama)", "tea"], 9, "艸", [
        ("茗荷", "myouga", "jahe mioga"),
        ("茗渓", "Meikei", "nama tempat"),
        ("茗園", "meien", "kebun teh"),
    ], [
        ("茗荷を食べました。", "Myouga o tabemashita.", "Makan mioga."),
        ("茗荷を薬味にしました。", "Myouga o yakumi ni shimashita.", "Menjadikan mioga sebagai bumbu pelengkap."),
    ]),
    ("roku2_n1", "麓", ["ロク"], ["ふもと"], ["kaki gunung", "foot of mountain"], 19, "木", [
        ("麓", "fumoto", "kaki gunung"),
        ("山麓", "sanroku", "kaki gunung (formal)"),
        ("麓村", "fumotomura", "desa kaki gunung"),
    ], [
        ("山の麓に住んでいます。", "Yama no fumoto ni sunde imasu.", "Tinggal di kaki gunung."),
        ("山麓地帯です。", "Sanroku chitai desu.", "Ini wilayah kaki gunung."),
    ]),
    ("hin6_n1", "瀕", ["ヒン"], [], ["di ambang (dalam kata majemuk)", "verge", "brink"], 19, "水", [
        ("瀕死", "hinshi", "sekarat/di ambang kematian"),
        ("瀕する", "hinsuru", "mendekati/berada di ambang"),
        ("瀕海", "hinkai", "dekat laut"),
    ], [
        ("瀕死の重傷でした。", "Hinshi no juushou deshita.", "Ini adalah luka parah yang mengancam jiwa."),
        ("危機に瀕しています。", "Kiki ni hinshite imasu.", "Berada di ambang krisis."),
    ]),
    ("ji7_n1", "蒔", ["ジ"], ["ま-く"], ["menanam", "sow", "plant"], 13, "艸", [
        ("蒔く", "maku", "menanam/menabur"),
        ("蒔絵", "makie", "kerajinan lukis emas Jepang"),
        ("種蒔き", "tanemaki", "menabur benih"),
    ], [
        ("種を蒔きました。", "Tane o makimashita.", "Menabur benih."),
        ("蒔絵の器です。", "Makie no utsuwa desu.", "Ini wadah kerajinan makie."),
    ]),
    ("ri7_n1", "鯉", ["リ"], ["こい"], ["ikan koi", "carp"], 18, "魚", [
        ("鯉", "koi", "ikan koi"),
        ("鯉のぼり", "koinobori", "bendera ikan koi"),
        ("錦鯉", "nishikigoi", "ikan koi"),
    ], [
        ("鯉が泳いでいます。", "Koi ga oyoide imasu.", "Ikan koi berenang."),
        ("鯉のぼりを揚げました。", "Koinobori o agemashita.", "Mengibarkan bendera ikan koi."),
    ]),
    ("ju7_n1", "竪", ["ジュ"], ["たて"], ["vertikal (variant 縦)", "vertical"], 13, "立", [
        ("竪琴", "tategoto", "harpa"),
        ("竪穴", "tateana", "lubang vertikal"),
        ("竪坑", "juukou", "poros tambang vertikal"),
    ], [
        ("竪琴を演奏しました。", "Tategoto o ensou shimashita.", "Memainkan harpa."),
        ("竪穴住居です。", "Tateana juukyo desu.", "Ini rumah lubang vertikal."),
    ]),
    ("ko13_n1", "弧", ["コ"], [], ["busur", "lengkungan", "arc"], 9, "弓", [
        ("弧", "ko", "lengkungan/busur"),
        ("括弧", "kakko", "tanda kurung"),
        ("弧状", "kojou", "berbentuk busur"),
    ], [
        ("弧を描きました。", "Ko o egakimashita.", "Menggambar lengkungan."),
        ("弧状に並んでいます。", "Kojou ni narande imasu.", "Tersusun berbentuk busur."),
    ]),
    ("kei22_n1", "稽", ["ケイ"], [], ["berlatih (dalam kata majemuk)", "consider", "practice"], 15, "禾", [
        ("稽古", "keiko", "latihan (seni tradisional)"),
        ("滑稽", "kokkei", "lucu/komikal"),
        ("稽首", "keishu", "sujud hormat"),
    ], [
        ("稽古をしました。", "Keiko o shimashita.", "Berlatih."),
        ("滑稽な話です。", "Kokkei na hanashi desu.", "Ini cerita yang lucu."),
    ]),
    ("ryuu8_n1", "瘤", ["リュウ"], ["こぶ"], ["benjolan", "lump", "bump"], 15, "疒", [
        ("瘤", "kobu", "benjolan"),
        ("目の上の瘤", "me no ue no kobu", "duri dalam daging"),
        ("木の瘤", "ki no kobu", "benjolan di pohon"),
    ], [
        ("頭に瘤ができました。", "Atama ni kobu ga dekimashita.", "Muncul benjolan di kepala."),
        ("目の上の瘤です。", "Me no ue no kobu desu.", "Ini seperti duri dalam daging."),
    ]),
    ("taku7_n1", "澤", ["タク"], ["さわ"], ["rawa (bentuk tradisional 沢)", "swamp"], 16, "水", [
        ("澤", "sawa", "rawa"),
        ("澤田", "Sawada", "contoh nama keluarga"),
        ("恩澤", "ontaku", "budi baik"),
    ], [
        ("澤田さんに会いました。", "Sawada-san ni aimashita.", "Bertemu dengan Sawada."),
        ("澤という字は沢の異体字です。", "Sawa to iu ji wa sawa no itaiji desu.", "Karakter ini adalah varian dari \"sawa\"."),
    ]),
    ("fu11_n1", "溥", ["フ", "ハク"], [], ["luas (nama)", "wide"], 13, "水", [
        ("溥儀", "Fugi", "Puyi, kaisar terakhir Tiongkok"),
        ("溥", "Hiroshi", "contoh nama pria"),
        ("溥仁", "Fujin", "contoh nama"),
    ], [
        ("溥儀は清朝最後の皇帝です。", "Fugi wa Shinchou saigo no koutei desu.", "Puyi adalah kaisar terakhir Dinasti Qing."),
        ("溥さんという名前です。", "Hiroshi-san to iu namae desu.", "Ini nama Hiroshi."),
    ]),
    ("you13_n1", "遥", ["ヨウ"], ["はる-か"], ["jauh (variant 遙)", "distant"], 12, "辵", [
        ("遥か", "haruka", "jauh"),
        ("遥拝", "youhai", "penghormatan jarak jauh"),
        ("逍遥", "shouyou", "berjalan santai"),
    ], [
        ("遥かな昔です。", "Haruka na mukashi desu.", "Ini masa lampau yang jauh."),
        ("遥拝しました。", "Youhai shimashita.", "Melakukan penghormatan jarak jauh."),
    ]),
    ("shuu17_n1", "蹴", ["シュウ"], ["け-る"], ["menendang", "kick"], 19, "足", [
        ("蹴る", "keru", "menendang"),
        ("蹴飛ばす", "kettobasu", "menendang jauh"),
        ("一蹴", "isshuu", "menolak mentah-mentah"),
    ], [
        ("ボールを蹴りました。", "Booru o kerimashita.", "Menendang bola."),
        ("一蹴されました。", "Isshuu saremashita.", "Ditolak mentah-mentah."),
    ]),
    ("waku3_n1", "或", ["ワク"], ["あ-る"], ["beberapa", "tertentu", "some", "certain"], 8, "戈", [
        ("或る", "aru", "suatu/tertentu"),
        ("或いは", "arui wa", "atau"),
        ("或問", "wakumon", "tanya jawab"),
    ], [
        ("或る日のことでした。", "Aru hi no koto deshita.", "Ini kejadian pada suatu hari."),
        ("或いは正しいかもしれません。", "Arui wa tadashii kamoshiremasen.", "Atau mungkin ini benar."),
    ]),
    ("fu12_n1", "訃", ["フ"], [], ["berita duka (dalam kata majemuk)", "obituary"], 9, "言", [
        ("訃報", "fuhou", "berita duka"),
        ("訃音", "fuin", "kabar duka"),
        ("訃告", "fukoku", "pemberitahuan duka"),
    ], [
        ("訃報が届きました。", "Fuhou ga todokimashita.", "Berita duka diterima."),
        ("訃報を聞いて驚きました。", "Fuhou o kiite odorokimashita.", "Terkejut mendengar berita duka."),
    ]),
    ("ku3_n1", "矩", ["ク"], ["かね"], ["penggaris siku", "carpenter's square", "rule"], 10, "矢", [
        ("矩形", "kukei", "persegi panjang"),
        ("規矩", "kiku", "kaidah/aturan"),
        ("矩尺", "kanejaku", "penggaris siku tukang kayu"),
    ], [
        ("矩形の部屋です。", "Kukei no heya desu.", "Ini kamar berbentuk persegi panjang."),
        ("規矩に従いました。", "Kiku ni shitagaimashita.", "Mengikuti kaidah."),
    ]),
    ("ka21_n1", "厦", ["カ", "ゲ"], [], ["gedung besar (dalam kata majemuk, nama tempat)", "large building"], 12, "厂", [
        ("厦門", "Amoi", "Kota Xiamen Tiongkok"),
        ("大厦", "taika", "gedung besar"),
        ("厦門島", "Amoi-tou", "Pulau Xiamen"),
    ], [
        ("厦門に行きました。", "Amoi ni ikimashita.", "Pergi ke Xiamen."),
        ("厦門は中国の都市です。", "Amoi wa Chuugoku no toshi desu.", "Xiamen adalah kota di Tiongkok."),
    ]),
    ("en16_n1", "冤", ["エン"], [], ["tuduhan palsu (dalam kata majemuk)", "false accusation"], 10, "冖", [
        ("冤罪", "enzai", "tuduhan palsu/kesalahan penuntutan"),
        ("冤枉", "enou", "ketidakadilan"),
        ("雪冤", "setsuen", "membersihkan nama dari tuduhan palsu"),
    ], [
        ("冤罪でした。", "Enzai deshita.", "Ini adalah tuduhan palsu."),
        ("冤罪事件です。", "Enzai jiken desu.", "Ini kasus tuduhan palsu."),
    ]),
    ("haku8_n1", "剥", ["ハク"], ["は-ぐ", "む-く", "は-がれる"], ["mengupas", "peel", "strip"], 10, "刀", [
        ("剥がす", "hagasu", "mengupas/melepas"),
        ("剥製", "hakusei", "taksidermi"),
        ("剥奪", "hakudatsu", "pencabutan hak"),
    ], [
        ("皮を剥きました。", "Kawa o mukimashita.", "Mengupas kulit."),
        ("資格を剥奪されました。", "Shikaku o hakudatsu saremashita.", "Haknya dicabut."),
    ]),
    ("shun5_n1", "舜", ["シュン"], [], ["Kaisar legendaris Shun (nama)", "legendary emperor Shun"], 13, "舛", [
        ("尭舜", "Gyoushun", "Kaisar Yao dan Shun"),
        ("舜", "Shun", "kaisar legendaris Tiongkok"),
        ("舜天", "Shunten", "raja legendaris Okinawa"),
    ], [
        ("舜という聖王がいました。", "Shun to iu seiou ga imashita.", "Ada raja bijak bernama Shun."),
        ("舜天王の伝説です。", "Shunten-ou no densetsu desu.", "Ini legenda Raja Shunten."),
    ]),
    ("kyou21_n1", "侠", ["キョウ"], [], ["kesatria (variant 俠)", "chivalrous"], 8, "人", [
        ("侠客", "kyoukaku", "ksatria pengembara"),
        ("任侠", "ninkyou", "semangat kesatria/yakuza"),
        ("義侠心", "gikyoushin", "jiwa kesatria"),
    ], [
        ("侠客の物語です。", "Kyoukaku no monogatari desu.", "Ini kisah ksatria pengembara."),
        ("義侠心があります。", "Gikyoushin ga arimasu.", "Memiliki jiwa kesatria."),
    ]),
    ("zei_n1", "贅", ["ゼイ"], [], ["mewah (dalam kata majemuk)", "extravagant"], 18, "貝", [
        ("贅沢", "zeitaku", "mewah/boros"),
        ("贅肉", "zeiniku", "lemak berlebih"),
        ("贅言", "zeigen", "kata-kata berlebihan"),
    ], [
        ("贅沢な生活です。", "Zeitaku na seikatsu desu.", "Ini kehidupan yang mewah."),
        ("贅肉がつきました。", "Zeiniku ga tsukimashita.", "Muncul lemak berlebih."),
    ]),
    ("jou13_n1", "杖", ["ジョウ"], ["つえ"], ["tongkat", "cane", "staff"], 7, "木", [
        ("杖", "tsue", "tongkat"),
        ("松葉杖", "matsubazue", "tongkat ketiak/kruk"),
        ("杖術", "joujutsu", "seni bela diri tongkat"),
    ], [
        ("杖をついています。", "Tsue o tsuite imasu.", "Berjalan dengan tongkat."),
        ("松葉杖を使っています。", "Matsubazue o tsukatte imasu.", "Menggunakan kruk."),
    ]),
    ("gai8_n1", "蓋", ["ガイ"], ["ふた"], ["tutup", "lid", "cover"], 13, "艸", [
        ("蓋", "futa", "tutup"),
        ("頭蓋骨", "zugaikotsu", "tengkorak"),
        ("蓋然性", "gaizensei", "probabilitas"),
    ], [
        ("蓋を開けました。", "Futa o akemashita.", "Membuka tutup."),
        ("頭蓋骨を検査しました。", "Zugaikotsu o kensa shimashita.", "Memeriksa tengkorak."),
    ]),
    ("i15_n1", "畏", ["イ"], ["おそ-れる", "かしこ-まる"], ["takut", "hormat", "fear", "awe"], 9, "田", [
        ("畏れる", "osoreru", "takut dengan hormat"),
        ("畏敬", "ikei", "rasa hormat mendalam"),
        ("畏怖", "ifu", "ketakutan penuh hormat"),
    ], [
        ("畏れ多いことです。", "Osoreooi koto desu.", "Ini sesuatu yang membuat segan."),
        ("畏敬の念を抱いています。", "Ikei no nen o idaite imasu.", "Memiliki rasa hormat mendalam."),
    ]),
    ("kou42_n1", "喉", ["コウ"], ["のど"], ["tenggorokan", "throat"], 12, "口", [
        ("喉", "nodo", "tenggorokan"),
        ("喉仏", "nodobotoke", "jakun"),
        ("喉元", "nodomoto", "pangkal tenggorokan"),
    ], [
        ("喉が痛いです。", "Nodo ga itai desu.", "Tenggorokan sakit."),
        ("喉仏が動きました。", "Nodobotoke ga ugokimashita.", "Jakunnya bergerak."),
    ]),
    ("ou10_n1", "汪", ["オウ"], [], ["luas (air, nama)", "vast (water)"], 7, "水", [
        ("汪然", "ouzen", "berlinang air mata"),
        ("汪", "Wang", "marga Tiongkok"),
        ("汪洋", "ouyou", "luas seperti lautan"),
    ], [
        ("汪兆銘という政治家です。", "Ou Choumei to iu seijika desu.", "Ini politisi bernama Wang Jingwei."),
        ("汪洋たる大海です。", "Ouyou taru taikai desu.", "Ini lautan yang luas."),
    ]),
    ("yuu14_n1", "猷", ["ユウ"], [], ["rencana (nama, klasik)", "plan", "way"], 13, "犬", [
        ("猷", "Michi", "contoh nama"),
        ("鴻猷", "kouyuu", "rencana besar"),
        ("遠猷", "enyuu", "rencana jauh"),
    ], [
        ("猷という字は稀に使われます。", "Yuu to iu ji wa mare ni tsukawaremasu.", "Karakter \"yuu\" ini jarang digunakan."),
        ("鴻猷を立てました。", "Kouyuu o tatemashita.", "Menyusun rencana besar."),
    ]),
    ("ei4_n1", "瑛", ["エイ"], [], ["kilau giok (nama)", "luster of jade"], 12, "玉", [
        ("瑛", "Akira", "contoh nama"),
        ("瑛子", "Eiko", "contoh nama wanita"),
        ("瑛太", "Eita", "contoh nama pria"),
    ], [
        ("瑛太という俳優です。", "Eita to iu haiyuu desu.", "Ini aktor bernama Eita."),
        ("瑛子さんに会いました。", "Eiko-san ni aimashita.", "Bertemu dengan Eiko."),
    ]),
    ("sou32_n1", "搜", ["ソウ"], ["さが-す"], ["mencari (bentuk tradisional 捜)", "search"], 12, "手", [
        ("搜査", "sousa", "penyelidikan"),
        ("搜索", "sousaku", "pencarian"),
        ("搜す", "sagasu", "mencari"),
    ], [
        ("搜査を開始しました。", "Sousa o kaishi shimashita.", "Memulai penyelidikan."),
        ("搜索隊が出動しました。", "Sousakutai ga shutsudou shimashita.", "Tim pencari dikerahkan."),
    ]),
    ("man4_n1", "曼", ["マン"], [], ["anggun", "mandala (dalam kata majemuk)", "graceful"], 11, "日", [
        ("曼荼羅", "mandara", "mandala"),
        ("曼珠沙華", "manjushage", "bunga lycoris merah"),
        ("曼陀羅", "mandara", "variant penulisan mandala"),
    ], [
        ("曼荼羅を見ました。", "Mandara o mimashita.", "Melihat mandala."),
        ("曼珠沙華が咲きました。", "Manjushage ga sakimashita.", "Bunga lycoris merah mekar."),
    ]),
    ("fu13_n1", "附", ["フ"], ["つ-く"], ["melampirkan (variant 付)", "attach"], 8, "阜", [
        ("附属", "fuzoku", "afiliasi"),
        ("附録", "furoku", "lampiran"),
        ("寄附", "kifu", "sumbangan"),
    ], [
        ("附属病院です。", "Fuzoku byouin desu.", "Ini rumah sakit afiliasi."),
        ("寄附をしました。", "Kifu o shimashita.", "Menyumbang."),
    ]),
    ("hyou7_n1", "彪", ["ヒョウ"], [], ["corak harimau (nama)", "tiger stripes", "brilliant"], 11, "虍", [
        ("彪", "Takeshi", "contoh nama"),
        ("彪炳", "hyouhei", "bersinar terang"),
        ("彪雄", "Hyouyuu", "contoh nama pria"),
    ], [
        ("彪という名前です。", "Takeshi to iu namae desu.", "Ini nama Takeshi."),
        ("彪炳たる功績です。", "Hyouhei taru kouseki desu.", "Ini prestasi yang bersinar terang."),
    ]),
    ("nen2_n1", "撚", ["ネン"], ["よ-る"], ["memilin", "twist (thread)"], 15, "手", [
        ("撚る", "yoru", "memilin"),
        ("撚糸", "nenshi", "benang pintal"),
        ("縒り", "yori", "pilinan"),
    ], [
        ("糸を撚りました。", "Ito o yorimashita.", "Memilin benang."),
        ("撚糸工場です。", "Nenshi koujou desu.", "Ini pabrik benang pintal."),
    ]),
    ("kamu_n1", "噛", [], ["か-む"], ["menggigit (variant 嚙)", "bite"], 15, "口", [
        ("噛む", "kamu", "menggigit/mengunyah"),
        ("噛み合う", "kamiau", "saling cocok/beradu"),
        ("噛み砕く", "kamikudaku", "mengunyah hancur/menyederhanakan"),
    ], [
        ("よく噛んで食べました。", "Yoku kande tabemashita.", "Makan dengan mengunyah baik-baik."),
        ("意見が噛み合いません。", "Iken ga kamiaimasen.", "Pendapatnya tidak cocok."),
    ]),
    ("bou14_n1", "卯", ["ボウ"], ["う"], ["shio kelinci", "rabbit zodiac"], 5, "卩", [
        ("卯", "u", "tahun kelinci dalam zodiak"),
        ("卯年", "udoshi", "tahun kelinci"),
        ("卯月", "uzuki", "bulan keempat kalender lunar"),
    ], [
        ("卯年生まれです。", "Udoshi umare desu.", "Lahir di tahun kelinci."),
        ("卯月に生まれました。", "Uzuki ni umaremashita.", "Lahir di bulan Uzuki."),
    ]),
    ("masu_n1", "桝", [], ["ます"], ["kotak takar (variant 升)", "measuring box"], 10, "木", [
        ("桝", "masu", "kotak takar"),
        ("桝席", "masuseki", "tempat duduk kotak di sumo"),
        ("桝田", "Masuda", "contoh nama keluarga"),
    ], [
        ("桝席で観戦しました。", "Masuseki de kansen shimashita.", "Menonton dari tempat duduk kotak."),
        ("桝田さんに会いました。", "Masuda-san ni aimashita.", "Bertemu dengan Masuda."),
    ]),
    ("bu3_n1", "撫", ["ブ"], ["な-でる"], ["mengelus", "stroke", "pet"], 15, "手", [
        ("撫でる", "naderu", "mengelus"),
        ("愛撫", "aibu", "belaian"),
        ("撫子", "nadeshiko", "bunga dianthus/wanita Jepang ideal"),
    ], [
        ("頭を撫でました。", "Atama o nademashita.", "Mengelus kepala."),
        ("大和撫子です。", "Yamato nadeshiko desu.", "Ini wanita Jepang ideal."),
    ]),
    ("chou27_n1", "喋", ["チョウ"], ["しゃべ-る"], ["mengobrol", "chat", "talk"], 12, "口", [
        ("喋る", "shaberu", "mengobrol/bicara"),
        ("喋々", "choucho", "banyak bicara"),
        ("お喋り", "oshaberi", "obrolan"),
    ], [
        ("たくさん喋りました。", "Takusan shaberimashita.", "Banyak mengobrol."),
        ("お喋りが好きです。", "Oshaberi ga suki desu.", "Suka mengobrol."),
    ]),
    ("tan10_n1", "但", ["タン"], ["ただ-し"], ["namun", "however", "provided that"], 7, "人", [
        ("但し", "tadashi", "namun/asalkan"),
        ("但し書き", "tadashigaki", "catatan pengecualian"),
        ("但馬", "Tajima", "nama daerah lama di Hyogo"),
    ], [
        ("但し、条件があります。", "Tadashi, jouken ga arimasu.", "Namun, ada syaratnya."),
        ("但し書きを読みました。", "Tadashigaki o yomimashita.", "Membaca catatan pengecualian."),
    ]),
    ("itsu2_n1", "溢", ["イツ"], ["あふ-れる"], ["meluap", "overflow"], 13, "水", [
        ("溢れる", "afureru", "meluap"),
        ("充溢", "juuitsu", "dipenuhi/melimpah"),
        ("溢れ出す", "afuredasu", "mulai meluap"),
    ], [
        ("川が溢れました。", "Kawa ga afuremashita.", "Sungai meluap."),
        ("才能に溢れています。", "Sainou ni afurete imasu.", "Dipenuhi bakat."),
    ]),
    ("katsu8_n1", "闊", ["カツ"], [], ["luas", "wide", "spacious"], 17, "門", [
        ("闊達", "kattatsu", "riang/lapang dada"),
        ("闊歩", "kappo", "berjalan lebar/angkuh"),
        ("迂闊", "ukatsu", "ceroboh"),
    ], [
        ("明朗闊達な性格です。", "Meirou kattatsu na seikaku desu.", "Kepribadian ceria dan lapang dada."),
        ("迂闊なミスでした。", "Ukatsu na misu deshita.", "Itu kesalahan ceroboh."),
    ]),
    ("zou_n1", "藏", ["ゾウ"], ["くら"], ["gudang (bentuk tradisional 蔵)", "storage"], 17, "艸", [
        ("藏書", "zousho", "koleksi buku"),
        ("秘藏", "hizou", "simpanan rahasia"),
        ("貯藏", "chozou", "penyimpanan"),
    ], [
        ("藏書が多いです。", "Zousho ga ooi desu.", "Koleksi bukunya banyak."),
        ("秘藏の品です。", "Hizou no shina desu.", "Ini barang simpanan rahasia."),
    ]),
    ("setsu5_n1", "浙", ["セツ"], [], ["Zhejiang (nama tempat)", "Zhejiang, China"], 10, "水", [
        ("浙江", "Sekkou", "provinsi Zhejiang"),
        ("浙江省", "Sekkou-shou", "Provinsi Zhejiang"),
        ("浙菜", "Sessai", "masakan Zhejiang"),
    ], [
        ("浙江省は中国にあります。", "Sekkou-shou wa Chuugoku ni arimasu.", "Provinsi Zhejiang ada di Tiongkok."),
        ("浙菜が有名です。", "Sessai ga yuumei desu.", "Masakan Zhejiang terkenal."),
    ]),
    ("hou22_n1", "彭", ["ホウ"], [], ["marga Peng (nama)", "surname Peng"], 12, "彡", [
        ("彭", "Hou", "marga Tiongkok (Peng)"),
        ("彭湃", "Houhai", "nama tokoh (Peng Pai)"),
        ("彭城", "Houjou", "nama kota kuno Tiongkok"),
    ], [
        ("彭さんは中国人です。", "Hou-san wa Chuugokujin desu.", "Pak Peng orang Tiongkok."),
        ("彭城という古い都市です。", "Houjou to iu furui toshi desu.", "Ini kota kuno bernama Pengcheng."),
    ]),
    ("tou23_n1", "淘", ["トウ"], [], ["menyaring", "wash", "select"], 11, "水", [
        ("淘汰", "touta", "seleksi alam/eliminasi"),
        ("自然淘汰", "shizen touta", "seleksi alam"),
        ("淘汰される", "touta sareru", "tereliminasi"),
    ], [
        ("自然淘汰が起こりました。", "Shizen touta ga okorimashita.", "Seleksi alam terjadi."),
        ("弱者が淘汰されました。", "Jakusha ga touta saremashita.", "Yang lemah tereliminasi."),
    ]),
    ("tei20_n1", "剃", ["テイ"], ["そ-る"], ["mencukur", "shave"], 9, "刀", [
        ("剃る", "soru", "mencukur"),
        ("剃刀", "kamisori", "pisau cukur"),
        ("剃髪", "teihatsu", "mencukur rambut/menjadi biksu"),
    ], [
        ("ひげを剃りました。", "Hige o sorimashita.", "Mencukur jenggot."),
        ("剃刀で剃りました。", "Kamisori de sorimashita.", "Mencukur dengan pisau cukur."),
    ]),
    ("soroeru_n1", "揃", [], ["そろ-える", "そろ-う"], ["menyelaraskan", "lengkap", "align"], 12, "手", [
        ("揃える", "soroeru", "menyelaraskan/melengkapi"),
        ("揃う", "sorou", "lengkap/seragam"),
        ("3人揃って", "sannin sorotte", "bertiga bersama-sama"),
    ], [
        ("靴を揃えました。", "Kutsu o soroemashita.", "Merapikan sepatu."),
        ("全員揃いました。", "Zen'in soroimashita.", "Semua sudah lengkap."),
    ]),
    ("ki30_n1", "綺", ["キ"], [], ["indah", "beautiful"], 14, "糸", [
        ("綺麗", "kirei", "cantik/bersih"),
        ("綺羅", "kira", "pakaian mewah"),
        ("綺想", "kisou", "ide fantastis"),
    ], [
        ("綺麗な花です。", "Kirei na hana desu.", "Ini bunga yang cantik."),
        ("部屋が綺麗になりました。", "Heya ga kirei ni narimashita.", "Kamarnya jadi bersih."),
    ]),
    ("hai7_n1", "徘", ["ハイ"], [], ["mengembara (dalam 徘徊)", "wander"], 11, "彳", [
        ("徘徊", "haikai", "berkeliaran/mengembara"),
        ("徘徊老人", "haikai roujin", "lansia yang berkeliaran"),
        ("徘徊症", "haikaishou", "gejala berkeliaran"),
    ], [
        ("街を徘徊しています。", "Machi o haikai shite imasu.", "Berkeliaran di kota."),
        ("夜に徘徊する症状です。", "Yoru ni haikai suru shoujou desu.", "Ini gejala berkeliaran di malam hari."),
    ]),
    ("kou43_n1", "巷", ["コウ"], ["ちまた"], ["gang/jalanan", "street", "alley"], 9, "己", [
        ("巷", "chimata", "gang/dunia ramai"),
        ("巷間", "koukan", "di kalangan masyarakat"),
        ("巷説", "kousetsu", "gosip/kabar burung"),
    ], [
        ("巷で噂になっています。", "Chimata de uwasa ni natte imasu.", "Menjadi gosip di kalangan masyarakat."),
        ("巷間の説です。", "Koukan no setsu desu.", "Ini pendapat umum di masyarakat."),
    ]),
    ("kan37_n1", "竿", ["カン"], ["さお"], ["galah", "pole", "rod"], 9, "竹", [
        ("竿", "sao", "galah/tongkat"),
        ("物干し竿", "monohoshizao", "tiang jemuran"),
        ("釣り竿", "tsurizao", "joran pancing"),
    ], [
        ("釣り竿を買いました。", "Tsurizao o kaimashita.", "Membeli joran pancing."),
        ("物干し竿に干しました。", "Monohoshizao ni hoshimashita.", "Menjemur di tiang jemuran."),
    ]),
    ("kai10_n1", "蟹", ["カイ"], ["かに"], ["kepiting", "crab"], 19, "虫", [
        ("蟹", "kani", "kepiting"),
        ("蟹座", "kaniza", "rasi bintang Cancer"),
        ("毛蟹", "kegani", "kepiting berbulu"),
    ], [
        ("蟹を食べました。", "Kani o tabemashita.", "Makan kepiting."),
        ("蟹座生まれです。", "Kaniza umare desu.", "Lahir di rasi Cancer."),
    ]),
    ("u3_n1", "芋", ["ウ"], ["いも"], ["umbi/kentang", "potato", "tuber"], 6, "艸", [
        ("芋", "imo", "umbi-umbian"),
        ("さつま芋", "satsumaimo", "ubi jalar"),
        ("里芋", "satoimo", "talas"),
    ], [
        ("芋を掘りました。", "Imo o horimashita.", "Menggali umbi."),
        ("さつま芋が甘いです。", "Satsumaimo ga amai desu.", "Ubi jalarnya manis."),
    ]),
    ("en17_n1", "袁", ["エン"], [], ["marga Yuan (nama)", "surname Yuan"], 10, "衣", [
        ("袁", "En", "marga Tiongkok (Yuan)"),
        ("袁世凱", "En Seigai", "nama tokoh (Yuan Shikai)"),
        ("袁氏", "Enshi", "klan Yuan"),
    ], [
        ("袁世凱という人物です。", "En Seigai to iu jinbutsu desu.", "Ini tokoh bernama Yuan Shikai."),
        ("袁さんに会いました。", "En-san ni aimashita.", "Bertemu dengan Yuan."),
    ]),
    ("sen15_n1", "舩", ["セン"], ["ふね"], ["kapal (variant 船)", "ship"], 11, "舟", [
        ("舩", "fune", "kapal"),
        ("御舩", "Mifune", "contoh nama keluarga"),
        ("舩橋", "Funabashi", "contoh nama"),
    ], [
        ("舩橋さんに会いました。", "Funabashi-san ni aimashita.", "Bertemu dengan Funabashi."),
        ("三舩敏郎という俳優です。", "Mifune Toshirou to iu haiyuu desu.", "Ini aktor bernama Mifune Toshiro."),
    ]),
    ("shoku6_n1", "拭", ["ショク"], ["ふ-く", "ぬぐ-う"], ["mengelap", "wipe"], 9, "手", [
        ("拭く", "fuku", "mengelap"),
        ("拭う", "nuguu", "mengusap/menghapus"),
        ("払拭", "fusshoku", "menghapus sepenuhnya"),
    ], [
        ("窓を拭きました。", "Mado o fukimashita.", "Mengelap jendela."),
        ("不安を払拭しました。", "Fuan o fusshoku shimashita.", "Menghapus kecemasan sepenuhnya."),
    ]),
    ("sen16_n1", "茜", ["セン"], ["あかね"], ["merah tua", "madder red"], 9, "艸", [
        ("茜色", "akaneiro", "warna merah tua"),
        ("茜", "Akane", "contoh nama wanita"),
        ("茜草", "akanegusa", "tanaman pewarna merah"),
    ], [
        ("茜色の空です。", "Akaneiro no sora desu.", "Ini langit berwarna merah tua."),
        ("茜さんに会いました。", "Akane-san ni aimashita.", "Bertemu dengan Akane."),
    ]),
    ("ryou12_n1", "凌", ["リョウ"], ["しの-ぐ"], ["bertahan/mengatasi", "endure", "surpass"], 10, "冫", [
        ("凌ぐ", "shinogu", "bertahan/mengatasi"),
        ("凌駕", "ryouga", "melampaui"),
        ("凌辱", "ryoujoku", "penghinaan"),
    ], [
        ("苦難を凌ぎました。", "Kunan o shinogimashita.", "Bertahan dari kesulitan."),
        ("先輩を凌駕しました。", "Senpai o ryouga shimashita.", "Melampaui senior."),
    ]),
    ("kyou22_n1", "頬", ["キョウ"], ["ほお", "ほほ"], ["pipi", "cheek"], 16, "頁", [
        ("頬", "hoo", "pipi"),
        ("頬杖", "hoozue", "menopang dagu"),
        ("頬骨", "hoobone", "tulang pipi"),
    ], [
        ("頬が赤くなりました。", "Hoo ga akaku narimashita.", "Pipinya memerah."),
        ("頬杖をついています。", "Hoozue o tsuite imasu.", "Menopang dagu."),
    ]),
    ("chuu7_n1", "厨", ["チュウ"], ["くりや"], ["dapur", "kitchen"], 12, "厂", [
        ("厨房", "chuubou", "dapur restoran"),
        ("厨子", "zushi", "lemari altar Buddha"),
        ("厨芥", "chuukai", "sampah dapur"),
    ], [
        ("厨房で働いています。", "Chuubou de hataraite imasu.", "Bekerja di dapur restoran."),
        ("厨子に仏像があります。", "Zushi ni butsuzou ga arimasu.", "Ada patung Buddha di lemari altar."),
    ]),
    ("sai14_n1", "犀", ["サイ"], [], ["badak", "rhinoceros"], 12, "牛", [
        ("犀", "sai", "badak"),
        ("犀角", "saikaku", "cula badak"),
        ("犀利", "sairi", "tajam/cerdas"),
    ], [
        ("犀を見ました。", "Sai o mimashita.", "Melihat badak."),
        ("犀角は薬用とされました。", "Saikaku wa yakuyou to saremashita.", "Cula badak dianggap sebagai obat."),
    ]),
    ("mino_n1", "簑", [], ["みの"], ["jas hujan jerami (variant 蓑)", "straw raincoat"], 16, "竹", [
        ("簑", "mino", "jas hujan jerami"),
        ("簑虫", "minomushi", "ulat kantong"),
        ("簑笠", "minokasa", "jas hujan jerami dan topi caping"),
    ], [
        ("簑を着ています。", "Mino o kite imasu.", "Mengenakan jas hujan jerami."),
        ("簑虫が木にぶら下がっています。", "Minomushi ga ki ni burasagatte imasu.", "Ulat kantong bergelantungan di pohon."),
    ]),
    ("kou44_n1", "皓", ["コウ"], [], ["putih terang (nama)", "bright white"], 12, "白", [
        ("皓歯", "koushi", "gigi putih"),
        ("皓皓", "koukou", "bersinar terang"),
        ("皓", "Akira", "contoh nama"),
    ], [
        ("皓歯の美人です。", "Koushi no bijin desu.", "Ini wanita cantik bergigi putih."),
        ("皓という名前です。", "Akira to iu namae desu.", "Ini nama Akira."),
    ]),
    ("so10_n1", "甦", ["ソ"], ["よみがえ-る"], ["bangkit kembali (variant 蘇)", "revive"], 12, "生", [
        ("甦る", "yomigaeru", "bangkit kembali/hidup lagi"),
        ("甦生", "kousei", "kebangkitan kembali"),
        ("甦り", "yomigaeri", "kebangkitan"),
    ], [
        ("記憶が甦りました。", "Kioku ga yomigaerimashita.", "Ingatan bangkit kembali."),
        ("街が甦生しました。", "Machi ga kousei shimashita.", "Kota bangkit kembali."),
    ]),
    ("kou45_n1", "洸", ["コウ"], [], ["air berkilau (nama)", "water shimmering"], 9, "水", [
        ("洸", "Hikaru", "contoh nama pria"),
        ("洸洸", "koukou", "gagah berani"),
        ("洸太", "Kouta", "contoh nama pria"),
    ], [
        ("洸太という名前です。", "Kouta to iu namae desu.", "Ini nama Kouta."),
        ("洸という漢字は名前によく使われます。", "Hikaru to iu kanji wa namae ni yoku tsukawaremasu.", "Kanji \"Hikaru\" ini sering dipakai untuk nama."),
    ]),
    ("kyuu16_n1", "毬", ["キュウ"], ["まり"], ["bola (tradisional)", "ball"], 11, "毛", [
        ("毬", "mari", "bola tradisional"),
        ("毬藻", "marimo", "alga bola/marimo"),
        ("毬栗", "igaguri", "kulit berduri buah berangan"),
    ], [
        ("毬で遊びました。", "Mari de asobimashita.", "Bermain dengan bola."),
        ("毬藻を育てています。", "Marimo o sodatete imasu.", "Memelihara marimo."),
    ]),
    ("geki3_n1", "檄", ["ゲキ"], [], ["seruan/manifesto", "call to arms"], 17, "木", [
        ("檄文", "gekibun", "surat seruan"),
        ("檄を飛ばす", "geki o tobasu", "mengeluarkan seruan/menyemangati"),
        ("檄する", "gekisuru", "menyerukan"),
    ], [
        ("檄文を書きました。", "Gekibun o kakimashita.", "Menulis surat seruan."),
        ("選手に檄を飛ばしました。", "Senshu ni geki o tobashimashita.", "Menyemangati para atlet."),
    ]),
    ("you14_n1", "姚", ["ヨウ"], [], ["marga Yao (nama)", "surname Yao"], 9, "女", [
        ("姚", "Yō", "marga Tiongkok (Yao)"),
        ("姚明", "Yō Mei", "nama tokoh (Yao Ming)"),
        ("姚氏", "Youshi", "klan Yao"),
    ], [
        ("姚明という選手です。", "Yō Mei to iu senshu desu.", "Ini atlet bernama Yao Ming."),
        ("姚さんに会いました。", "Yō-san ni aimashita.", "Bertemu dengan Yao."),
    ]),
    ("shitsu8_n1", "蛭", ["シツ"], ["ひる"], ["lintah", "leech"], 11, "虫", [
        ("蛭", "hiru", "lintah"),
        ("蛭子", "Hiruko", "dewa dalam mitologi Jepang"),
        ("山蛭", "yamabiru", "pacet"),
    ], [
        ("蛭に噛まれました。", "Hiru ni kamaremashita.", "Digigit lintah."),
        ("山蛭がいます。", "Yamabiru ga imasu.", "Ada pacet."),
    ]),
    ("ba_n1", "婆", ["バ"], ["ばば", "ばばあ"], ["nenek/wanita tua", "old woman"], 11, "女", [
        ("婆", "baba", "nenek/wanita tua"),
        ("お婆さん", "obaasan", "nenek"),
        ("産婆", "sanba", "bidan tradisional"),
    ], [
        ("お婆さんに会いました。", "Obaasan ni aimashita.", "Bertemu dengan nenek."),
        ("産婆を呼びました。", "Sanba o yobimashita.", "Memanggil bidan."),
    ]),
    ("sou33_n1", "叢", ["ソウ"], ["むら", "くさむら"], ["semak/rumpun", "thicket", "cluster"], 18, "又", [
        ("叢", "kusamura", "semak belukar"),
        ("叢書", "sousho", "seri buku"),
        ("叢生", "sousei", "tumbuh berumpun"),
    ], [
        ("叢の中に隠れました。", "Kusamura no naka ni kakuremashita.", "Bersembunyi di dalam semak."),
        ("叢書が出版されました。", "Sousho ga shuppan saremashita.", "Seri buku diterbitkan."),
    ]),
    ("sugi2_n1", "椙", [], ["すぎ"], ["cemara (kokuji, nama keluarga)", "cedar surname kanji"], 13, "木", [
        ("椙山", "Sugiyama", "contoh nama keluarga"),
        ("椙原", "Sugihara", "contoh nama keluarga"),
        ("椙", "sugi", "cemara"),
    ], [
        ("椙山さんに会いました。", "Sugiyama-san ni aimashita.", "Bertemu dengan Sugiyama."),
        ("椙原さんの家です。", "Sugihara-san no ie desu.", "Ini rumah keluarga Sugihara."),
    ]),
    ("gou5_n1", "轟", ["ゴウ"], ["とどろ-く"], ["bergemuruh", "roar", "rumble"], 21, "車", [
        ("轟く", "todoroku", "bergemuruh/menggema"),
        ("轟音", "gouon", "suara gemuruh"),
        ("轟沈", "gouchin", "tenggelam seketika"),
    ], [
        ("雷が轟きました。", "Kaminari ga todorokimashita.", "Petir bergemuruh."),
        ("轟音が聞こえました。", "Gouon ga kikoemashita.", "Terdengar suara gemuruh."),
    ]),
    ("gan9_n1", "贋", ["ガン"], ["にせ"], ["palsu", "fake", "counterfeit"], 19, "貝", [
        ("贋作", "gansaku", "karya palsu"),
        ("贋物", "nisemono", "barang palsu"),
        ("贋金", "nisegane", "uang palsu"),
    ], [
        ("贋作が発見されました。", "Gansaku ga hakken saremashita.", "Karya palsu ditemukan."),
        ("贋物を買ってしまいました。", "Nisemono o katte shimaimashita.", "Terlanjur membeli barang palsu."),
    ]),
    ("sha8_n1", "洒", ["シャ"], [], ["bersih/lucu (dalam 洒落)", "clean", "witty"], 9, "水", [
        ("洒落", "share", "lelucon/bergaya"),
        ("洒落る", "shareru", "bergaya/berdandan"),
        ("瀟洒", "shousha", "elegan/rapi"),
    ], [
        ("洒落を言いました。", "Share o iimashita.", "Melontarkan lelucon."),
        ("瀟洒な建物です。", "Shousha na tatemono desu.", "Ini bangunan yang elegan."),
    ]),
    ("sei16_n1", "貰", ["セイ"], ["もら-う"], ["menerima", "receive"], 12, "貝", [
        ("貰う", "morau", "menerima"),
        ("貰い物", "moraimono", "barang pemberian"),
        ("貰い泣き", "morainaki", "ikut menangis"),
    ], [
        ("プレゼントを貰いました。", "Purezento o moraimashita.", "Menerima hadiah."),
        ("貰い泣きしてしまいました。", "Morainaki shite shimaimashita.", "Jadi ikut menangis."),
    ]),
    ("cho3_n1", "儲", ["チョ"], ["もう-ける"], ["keuntungan", "profit", "gain"], 18, "人", [
        ("儲ける", "moukeru", "mendapat untung"),
        ("儲かる", "moukaru", "menguntungkan"),
        ("儲け", "mouke", "keuntungan"),
    ], [
        ("商売で儲けました。", "Shoubai de moukemashita.", "Mendapat untung dari bisnis."),
        ("この仕事は儲かります。", "Kono shigoto wa moukarimasu.", "Pekerjaan ini menguntungkan."),
    ]),
    ("hi12_n1", "緋", ["ヒ"], ["あけ"], ["merah tua/merah menyala", "scarlet"], 14, "糸", [
        ("緋色", "hiiro", "warna merah menyala"),
        ("緋鯉", "higoi", "ikan koi merah"),
        ("緋文字", "himonji", "huruf merah"),
    ], [
        ("緋色の着物です。", "Hiiro no kimono desu.", "Ini kimono berwarna merah menyala."),
        ("緋鯉が泳いでいます。", "Higoi ga oyoide imasu.", "Ikan koi merah berenang."),
    ]),
    ("chou28_n1", "諜", ["チョウ"], [], ["mata-mata", "spy", "espionage"], 15, "言", [
        ("諜報", "chouhou", "intelijen/mata-mata"),
        ("諜報員", "chouhouin", "agen intelijen"),
        ("防諜", "bouchou", "kontra-intelijen"),
    ], [
        ("諜報活動をしています。", "Chouhou katsudou o shite imasu.", "Melakukan kegiatan intelijen."),
        ("諜報員として働いています。", "Chouhouin toshite hataraite imasu.", "Bekerja sebagai agen intelijen."),
    ]),
    ("chou29_n1", "鯛", ["チョウ"], ["たい"], ["ikan kakap merah", "sea bream"], 19, "魚", [
        ("鯛", "tai", "ikan kakap merah"),
        ("鯛焼き", "taiyaki", "kue ikan kakap"),
        ("真鯛", "madai", "kakap merah asli"),
    ], [
        ("鯛を食べました。", "Tai o tabemashita.", "Makan ikan kakap merah."),
        ("鯛焼きを買いました。", "Taiyaki o kaimashita.", "Membeli kue ikan."),
    ]),
    ("ryou13_n1", "蓼", ["リョウ"], ["たで"], ["tanaman tade", "smartweed", "knotweed"], 15, "艸", [
        ("蓼", "tade", "tanaman tade"),
        ("蓼食う虫も好き好き", "tade kuu mushi mo sukizuki", "peribahasa: selera berbeda-beda"),
        ("蓼酢", "tadezu", "saus cuka tade"),
    ], [
        ("蓼を育てています。", "Tade o sodatete imasu.", "Menanam tanaman tade."),
        ("蓼酢をつけて食べました。", "Tadezu o tsukete tabemashita.", "Makan dengan saus cuka tade."),
    ]),
    ("ou11_n1", "甕", ["オウ"], ["かめ"], ["tempayan besar", "large jar", "urn"], 18, "瓦", [
        ("甕", "kame", "tempayan besar"),
        ("甕棺", "oukan", "peti mati tempayan"),
        ("甕覗き", "kamenozoki", "warna biru pucat"),
    ], [
        ("甕に水を貯めました。", "Kame ni mizu o tamemashita.", "Menyimpan air di tempayan."),
        ("甕棺が発掘されました。", "Oukan ga hakkutsu saremashita.", "Peti mati tempayan digali."),
    ]),
    ("zen6_n1", "喘", ["ゼン"], ["あえ-ぐ"], ["terengah-engah", "gasp", "pant"], 12, "口", [
        ("喘ぐ", "aegu", "terengah-engah"),
        ("喘息", "zensoku", "asma"),
        ("喘鳴", "zenmei", "suara mengi"),
    ], [
        ("息が喘ぎました。", "Iki ga aegimashita.", "Napas terengah-engah."),
        ("喘息の発作です。", "Zensoku no hossa desu.", "Ini serangan asma."),
    ]),
    ("rei9_n1", "怜", ["レイ"], [], ["cerdas (nama)", "clever", "wise"], 8, "心", [
        ("怜悧", "reiri", "cerdas/pintar"),
        ("怜子", "Reiko", "contoh nama wanita"),
        ("怜", "Rei", "contoh nama"),
    ], [
        ("怜悧な子供です。", "Reiri na kodomo desu.", "Ini anak yang cerdas."),
        ("怜子さんに会いました。", "Reiko-san ni aimashita.", "Bertemu dengan Reiko."),
    ]),
    ("ryuu9_n1", "溜", ["リュウ"], ["た-める", "た-まる"], ["menumpuk", "accumulate", "pool"], 13, "水", [
        ("溜める", "tameru", "mengumpulkan/menabung"),
        ("溜まる", "tamaru", "menumpuk"),
        ("溜息", "tameiki", "helaan nafas"),
    ], [
        ("お金を溜めました。", "Okane o tamemashita.", "Mengumpulkan uang."),
        ("溜息をつきました。", "Tameiki o tsukimashita.", "Menghela nafas."),
    ]),
    ("yuu15_n1", "邑", ["ユウ"], ["むら"], ["desa (klasik)", "town", "village"], 7, "邑", [
        ("邑", "mura", "desa"),
        ("都邑", "toyuu", "kota dan desa"),
        ("邑落", "yuuraku", "permukiman"),
    ], [
        ("邑という古い言葉です。", "Mura to iu furui kotoba desu.", "\"Mura\" ini kata kuno."),
        ("都邑が栄えました。", "Toyuu ga sakaemashita.", "Kota dan desa berkembang."),
    ]),
    ("bou15_n1", "鉾", ["ボウ"], ["ほこ"], ["tombak (variant 矛)", "halberd"], 13, "金", [
        ("鉾", "hoko", "tombak/kereta festival"),
        ("山鉾", "yamahoko", "kereta hias festival Gion"),
        ("鉾先", "hokosaki", "ujung tombak/sasaran kritik"),
    ], [
        ("山鉾が街を巡りました。", "Yamahoko ga machi o megurimashita.", "Kereta hias berkeliling kota."),
        ("鉾先を向けられました。", "Hokosaki o mukeraremashita.", "Menjadi sasaran kritik."),
    ]),
    ("hou23_n1", "倣", ["ホウ"], ["なら-う"], ["meniru", "imitate", "follow example"], 10, "人", [
        ("倣う", "narau", "meniru/mengikuti contoh"),
        ("模倣", "mohou", "imitasi/tiruan"),
        ("前例に倣う", "zenrei ni narau", "mengikuti contoh sebelumnya"),
    ], [
        ("先例に倣いました。", "Zenrei ni naraimashita.", "Mengikuti contoh sebelumnya."),
        ("模倣品を買いました。", "Mohouhin o kaimashita.", "Membeli barang tiruan."),
    ]),
    ("heki3_n1", "碧", ["ヘキ"], ["みどり"], ["hijau giok", "jade green", "blue-green"], 14, "石", [
        ("碧眼", "hekigan", "mata biru"),
        ("碧空", "hekikuu", "langit biru jernih"),
        ("紺碧", "konpeki", "biru tua"),
    ], [
        ("碧眼の外国人です。", "Hekigan no gaikokujin desu.", "Ini orang asing bermata biru."),
        ("紺碧の海です。", "Konpeki no umi desu.", "Ini laut biru tua."),
    ]),
    ("tou24_n1", "燈", ["トウ"], ["ひ"], ["lampu (bentuk tradisional 灯)", "lamp", "light"], 16, "火", [
        ("燈籠", "tourou", "lentera"),
        ("燈台", "toudai", "mercusuar"),
        ("提燈", "chouchin", "lampion"),
    ], [
        ("燈籠が並んでいます。", "Tourou ga narande imasu.", "Lentera berjejer."),
        ("燈台の光が見えます。", "Toudai no hikari ga miemasu.", "Cahaya mercusuar terlihat."),
    ]),
    ("tei21_n1", "諦", ["テイ"], ["あきら-める"], ["menyerah/pasrah", "give up", "resign"], 16, "言", [
        ("諦める", "akirameru", "menyerah"),
        ("諦め", "akirame", "sikap pasrah"),
        ("諦観", "teikan", "pandangan pasrah/menerima kenyataan"),
    ], [
        ("夢を諦めませんでした。", "Yume o akiramemasen deshita.", "Tidak menyerah pada mimpi."),
        ("諦観の境地です。", "Teikan no kyouchi desu.", "Ini keadaan batin yang pasrah."),
    ]),
    ("sen17_n1", "煎", ["セン"], ["い-る"], ["menyangrai", "roast", "fry (dry)"], 13, "火", [
        ("煎る", "iru", "menyangrai"),
        ("煎茶", "sencha", "teh hijau seduh"),
        ("煎餅", "senbei", "kerupuk beras"),
    ], [
        ("豆を煎りました。", "Mame o irimashita.", "Menyangrai kacang."),
        ("煎餅を食べました。", "Senbei o tabemashita.", "Makan kerupuk beras."),
    ]),
    ("ka22_n1", "瓜", ["カ"], ["うり"], ["melon/labu", "melon", "gourd"], 5, "瓜", [
        ("瓜", "uri", "melon/labu"),
        ("西瓜", "suika", "semangka"),
        ("瓜二つ", "uri futatsu", "sangat mirip"),
    ], [
        ("瓜を食べました。", "Uri o tabemashita.", "Makan melon."),
        ("瓜二つの兄弟です。", "Uri futatsu no kyoudai desu.", "Ini saudara yang sangat mirip."),
    ]),
    ("chi5_n1", "緻", ["チ"], [], ["rinci", "fine", "detailed"], 16, "糸", [
        ("緻密", "chimitsu", "rinci/teliti"),
        ("精緻", "seichi", "sangat teliti"),
        ("巧緻", "kouchi", "cerdik dan rinci"),
    ], [
        ("緻密な計画です。", "Chimitsu na keikaku desu.", "Ini rencana yang rinci."),
        ("精緻な作品です。", "Seichi na sakuhin desu.", "Ini karya yang sangat teliti."),
    ]),
    ("ho5_n1", "哺", ["ホ"], [], ["menyusui", "feed", "nurture"], 10, "口", [
        ("哺乳", "honyuu", "menyusui"),
        ("哺乳類", "honyuurui", "mamalia"),
        ("哺育", "hoiku", "membesarkan/menyusui"),
    ], [
        ("哺乳類を研究しています。", "Honyuurui o kenkyuu shite imasu.", "Meneliti mamalia."),
        ("哺乳瓶を買いました。", "Honyuubin o kaimashita.", "Membeli botol susu."),
    ]),
    ("tsuchi_n1", "槌", [], ["つち"], ["palu", "hammer", "mallet"], 14, "木", [
        ("槌", "tsuchi", "palu"),
        ("相槌", "aizuchi", "respon menyetujui dalam percakapan"),
        ("鉄槌", "tettsui", "palu besi/hukuman keras"),
    ], [
        ("槌で叩きました。", "Tsuchi de tatakimashita.", "Memukul dengan palu."),
        ("相槌を打ちました。", "Aizuchi o uchimashita.", "Memberikan respon menyetujui."),
    ]),
    ("taku8_n1", "啄", ["タク"], ["ついば-む"], ["mematuk", "peck"], 10, "口", [
        ("啄む", "tsuibamu", "mematuk"),
        ("啄木鳥", "kitsutsuki", "burung pelatuk"),
        ("一啄", "ittaku", "satu patukan"),
    ], [
        ("鳥が餌を啄みました。", "Tori ga esa o tsuibamimashita.", "Burung mematuk makanan."),
        ("啄木鳥が木を叩いています。", "Kitsutsuki ga ki o tataite imasu.", "Burung pelatuk mematuk pohon."),
    ]),
    ("jou14_n1", "穣", ["ジョウ"], [], ["panen berlimpah (variant 穰)", "abundant harvest"], 18, "禾", [
        ("豊穣", "houjou", "kesuburan/panen melimpah"),
        ("穣", "Minoru", "contoh nama"),
        ("五穀豊穣", "gokoku houjou", "panen lima biji-bijian melimpah"),
    ], [
        ("豊穣な大地です。", "Houjou na daichi desu.", "Ini tanah yang subur."),
        ("五穀豊穣を祈りました。", "Gokoku houjou o inorimashita.", "Berdoa untuk panen melimpah."),
    ]),
    ("shi31_n1", "嗜", ["シ"], ["たしな-む"], ["menikmati/gemar", "have a taste for", "enjoy"], 13, "口", [
        ("嗜む", "tashinamu", "menikmati/gemar"),
        ("嗜好", "shikou", "selera/kegemaran"),
        ("嗜好品", "shikouhin", "barang kesukaan/kegemaran"),
    ], [
        ("酒を嗜みます。", "Sake o tashinamimasu.", "Menikmati sake."),
        ("嗜好品を買いました。", "Shikouhin o kaimashita.", "Membeli barang kesukaan."),
    ]),
    ("kai11_n1", "偕", ["カイ"], [], ["bersama (klasik)", "together"], 11, "人", [
        ("偕老同穴", "kairou douketsu", "hidup bersama sampai tua"),
        ("偕行", "kaikou", "berjalan bersama"),
        ("偕楽", "kairaku", "bersenang-senang bersama"),
    ], [
        ("偕老同穴を誓いました。", "Kairou douketsu o chikaimashita.", "Bersumpah hidup bersama sampai tua."),
        ("偕楽園を訪れました。", "Kairakuen o otozuremashita.", "Mengunjungi Taman Kairakuen."),
    ]),
    ("ba2_n1", "罵", ["バ"], ["ののし-る"], ["memaki", "curse", "abuse"], 15, "网", [
        ("罵る", "nonoshiru", "memaki"),
        ("罵倒", "batou", "makian"),
        ("罵声", "basei", "suara makian"),
    ], [
        ("罵声を浴びせました。", "Basei o abisemashita.", "Melontarkan makian."),
        ("罵倒されました。", "Batou saremashita.", "Dimaki-maki."),
    ]),
    ("yuu16_n1", "酉", ["ユウ"], ["とり"], ["shio ayam", "rooster zodiac"], 7, "酉", [
        ("酉", "tori", "tahun ayam dalam zodiak"),
        ("酉年", "toridoshi", "tahun ayam"),
        ("酉の市", "tori no ichi", "festival pasar ayam"),
    ], [
        ("酉年生まれです。", "Toridoshi umare desu.", "Lahir di tahun ayam."),
        ("酉の市に行きました。", "Tori no ichi ni ikimashita.", "Pergi ke festival pasar ayam."),
    ]),
    ("tei22_n1", "蹄", ["テイ"], ["ひづめ"], ["kuku kaki hewan", "hoof"], 16, "足", [
        ("蹄", "hizume", "kuku kaki hewan"),
        ("馬蹄", "batei", "tapal kuda"),
        ("蹄鉄", "teitetsu", "sepatu kuda/ladam"),
    ], [
        ("馬の蹄を見ました。", "Uma no hizume o mimashita.", "Melihat kuku kaki kuda."),
        ("蹄鉄を打ちました。", "Teitetsu o uchimashita.", "Memasang ladam."),
    ]),
    ("kei23_n1", "頚", ["ケイ"], ["くび"], ["leher (variant 頸)", "neck"], 11, "頁", [
        ("頚椎", "keitsui", "tulang leher"),
        ("頚部", "keibu", "bagian leher"),
        ("頚動脈", "keidoumyaku", "arteri leher/karotis"),
    ], [
        ("頚椎を痛めました。", "Keitsui o itamemashita.", "Cedera tulang leher."),
        ("頚動脈を測りました。", "Keidoumyaku o hakarimashita.", "Mengukur arteri karotis."),
    ]),
    ("hai8_n1", "胚", ["ハイ"], [], ["embrio", "embryo"], 9, "肉", [
        ("胚", "hai", "embrio"),
        ("胚芽", "haiga", "kecambah/lembaga biji"),
        ("胚珠", "haishu", "bakal biji"),
    ], [
        ("胚の研究をしています。", "Hai no kenkyuu o shite imasu.", "Meneliti embrio."),
        ("胚芽米を食べています。", "Haigamai o tabete imasu.", "Makan beras berkecambah."),
    ]),
    ("rou9_n1", "牢", ["ロウ"], [], ["penjara", "prison", "jail"], 7, "牛", [
        ("牢屋", "rouya", "penjara"),
        ("牢獄", "rougoku", "penjara"),
        ("牢固", "rouko", "kokoh/kuat"),
    ], [
        ("牢屋に入れられました。", "Rouya ni ireraremashita.", "Dimasukkan ke penjara."),
        ("牢固たる信念です。", "Rouko taru shinnen desu.", "Ini keyakinan yang kokoh."),
    ]),
    ("fun7_n1", "糞", ["フン"], ["くそ"], ["kotoran/tinja", "excrement", "dung"], 17, "米", [
        ("糞", "kuso", "kotoran/tinja"),
        ("糞尿", "funnyou", "kotoran dan urin"),
        ("牛糞", "gyuufun", "kotoran sapi"),
    ], [
        ("糞尿処理施設です。", "Funnyou shori shisetsu desu.", "Ini fasilitas pengolahan limbah."),
        ("牛糞を肥料にしました。", "Gyuufun o hiryou ni shimashita.", "Menjadikan kotoran sapi sebagai pupuk."),
    ]),
    ("tei23_n1", "悌", ["テイ"], [], ["kasih sayang persaudaraan", "brotherly love", "respect for elders"], 10, "心", [
        ("悌", "tei", "sikap hormat pada yang lebih tua"),
        ("孝悌", "koutei", "bakti dan hormat pada saudara tua"),
        ("悌順", "teijun", "patuh dan penuh hormat"),
    ], [
        ("孝悌の心を大切にします。", "Koutei no kokoro o taisetsu ni shimasu.", "Menghargai sikap bakti dan hormat."),
        ("悌という徳目です。", "Tei to iu tokumoku desu.", "Ini adalah nilai kebajikan \"tei\"."),
    ]),
    ("chou30_n1", "吊", ["チョウ"], ["つ-る"], ["menggantung", "hang", "suspend"], 6, "口", [
        ("吊る", "tsuru", "menggantung"),
        ("吊り橋", "tsuribashi", "jembatan gantung"),
        ("吊革", "tsurikawa", "pegangan gantung di kereta"),
    ], [
        ("吊り橋を渡りました。", "Tsuribashi o watarimashita.", "Menyeberangi jembatan gantung."),
        ("吊革につかまりました。", "Tsurikawa ni tsukamarimashita.", "Berpegangan pada pegangan gantung."),
    ]),
    ("da6_n1", "楕", ["ダ"], [], ["elips", "oval", "ellipse"], 13, "木", [
        ("楕円", "daen", "elips/oval"),
        ("楕円形", "daenkei", "bentuk oval"),
        ("楕円軌道", "daen kidou", "orbit elips"),
    ], [
        ("楕円を描きました。", "Daen o egakimashita.", "Menggambar elips."),
        ("楕円軌道を回っています。", "Daen kidou o mawatte imasu.", "Mengorbit dalam lintasan elips."),
    ]),
    ("kai12_n1", "鮭", ["カイ"], ["さけ", "しゃけ"], ["ikan salmon", "salmon"], 17, "魚", [
        ("鮭", "sake", "ikan salmon"),
        ("鮭の切り身", "sake no kirimi", "potongan salmon"),
        ("塩鮭", "shiojake", "salmon asin"),
    ], [
        ("鮭を焼きました。", "Sake o yakimashita.", "Memanggang salmon."),
        ("塩鮭が好きです。", "Shiojake ga suki desu.", "Suka salmon asin."),
    ]),
    ("kotsu2_n1", "乞", ["コツ"], ["こ-う"], ["memohon/mengemis", "beg"], 3, "乙", [
        ("乞う", "kou", "memohon"),
        ("乞食", "kojiki", "pengemis"),
        ("命乞い", "inochigoi", "memohon nyawa"),
    ], [
        ("許しを乞いました。", "Yurushi o koimashita.", "Memohon maaf."),
        ("命乞いをしました。", "Inochigoi o shimashita.", "Memohon nyawa."),
    ]),
    ("ken18_n1", "倹", ["ケン"], [], ["hemat", "frugal", "thrifty"], 10, "人", [
        ("倹約", "ken'yaku", "penghematan"),
        ("勤倹", "kinken", "rajin dan hemat"),
        ("倹しい", "tsumashii", "sederhana/hemat"),
    ], [
        ("倹約に努めています。", "Ken'yaku ni tsutomete imasu.", "Berusaha berhemat."),
        ("勤倹貯蓄が大切です。", "Kinken chochiku ga taisetsu desu.", "Rajin, hemat, dan menabung itu penting."),
    ]),
    ("kyuu17_n1", "嗅", ["キュウ"], ["か-ぐ"], ["mencium (bau)", "smell"], 13, "口", [
        ("嗅ぐ", "kagu", "mencium bau"),
        ("嗅覚", "kyuukaku", "indra penciuman"),
        ("嗅細胞", "kyuusaibou", "sel penciuman"),
    ], [
        ("匂いを嗅ぎました。", "Nioi o kagimashita.", "Mencium bau."),
        ("嗅覚が鋭いです。", "Kyuukaku ga surudoi desu.", "Indra penciumannya tajam."),
    ]),
    ("wabiru_n1", "詫", [], ["わ-びる"], ["minta maaf (variant 侘)", "apologize"], 13, "言", [
        ("詫びる", "wabiru", "minta maaf"),
        ("お詫び", "owabi", "permintaan maaf"),
        ("詫び状", "wabijou", "surat permintaan maaf"),
    ], [
        ("心から詫びました。", "Kokoro kara wabimashita.", "Minta maaf dengan tulus."),
        ("お詫びを申し上げます。", "Owabi o moushiagemasu.", "Menyampaikan permintaan maaf."),
    ]),
    ("son3_n1", "鱒", ["ソン"], ["ます"], ["ikan trout", "trout"], 23, "魚", [
        ("鱒", "masu", "ikan trout"),
        ("虹鱒", "nijimasu", "ikan trout pelangi"),
        ("鱒寿司", "masuzushi", "sushi trout"),
    ], [
        ("鱒を釣りました。", "Masu o tsurimashita.", "Memancing ikan trout."),
        ("鱒寿司が名物です。", "Masuzushi ga meibutsu desu.", "Sushi trout adalah makanan khas."),
    ]),
    ("betsu_n1", "蔑", ["ベツ"], ["さげす-む"], ["menghina", "despise", "scorn"], 14, "艸", [
        ("蔑む", "sagesumu", "menghina/meremehkan"),
        ("軽蔑", "keibetsu", "penghinaan"),
        ("蔑視", "besshi", "memandang rendah"),
    ], [
        ("人を蔑んではいけません。", "Hito o sagesunde wa ikemasen.", "Jangan menghina orang."),
        ("軽蔑の目で見られました。", "Keibetsu no me de miraremashita.", "Dipandang dengan penghinaan."),
    ]),
    ("tetsu6_n1", "轍", ["テツ"], ["わだち"], ["bekas roda", "wheel track", "rut"], 19, "車", [
        ("轍", "wadachi", "bekas roda"),
        ("前轍を踏む", "zentetsu o fumu", "mengulangi kesalahan sebelumnya"),
        ("轍鮒の急", "tetsubu no kyuu", "keadaan darurat"),
    ], [
        ("轍が残っています。", "Wadachi ga nokotte imasu.", "Bekas roda masih tersisa."),
        ("前轍を踏まないようにします。", "Zentetsu o fumanai you ni shimasu.", "Berusaha tidak mengulangi kesalahan yang sama."),
    ]),
    ("shou45_n1", "醤", ["ショウ"], [], ["kecap/pasta fermentasi", "soy sauce"], 17, "酉", [
        ("醤油", "shouyu", "kecap asin"),
        ("味噌醤油", "miso shouyu", "miso dan kecap"),
        ("醤", "hishio", "pasta fermentasi kuno"),
    ], [
        ("醤油をかけました。", "Shouyu o kakemashita.", "Menuangkan kecap."),
        ("醤油の香りがします。", "Shouyu no kaori ga shimasu.", "Tercium aroma kecap."),
    ]),
    ("horeru_n1", "惚", [], ["ほ-れる", "ぼ-ける"], ["terpesona/tergila-gila", "infatuated", "enchanted"], 11, "心", [
        ("惚れる", "horeru", "jatuh cinta/terpesona"),
        ("惚気る", "norokeru", "membanggakan pasangan"),
        ("惚ける", "bokeru", "pikun/linglung"),
    ], [
        ("一目惚れしました。", "Hitomebore shimashita.", "Jatuh cinta pada pandangan pertama."),
        ("惚けてしまいました。", "Bokete shimaimashita.", "Jadi pikun."),
    ]),
    ("kou46_n1", "廣", ["コウ"], ["ひろ-い"], ["luas (bentuk tradisional 広)", "wide", "vast"], 15, "广", [
        ("廣島", "Hiroshima", "nama kota"),
        ("廣告", "koukoku", "iklan"),
        ("廣場", "koujou", "alun-alun"),
    ], [
        ("廣島に行きました。", "Hiroshima ni ikimashita.", "Pergi ke Hiroshima."),
        ("廣告を出しました。", "Koukoku o dashimashita.", "Memasang iklan."),
    ]),
    ("kou47_n1", "藁", ["コウ"], ["わら"], ["jerami", "straw"], 17, "艸", [
        ("藁", "wara", "jerami"),
        ("藁人形", "waraningyou", "boneka jerami"),
        ("藁にもすがる", "wara ni mo sugaru", "berpegang pada apa saja"),
    ], [
        ("藁で屋根を葺きました。", "Wara de yane o fukimashita.", "Menutup atap dengan jerami."),
        ("溺れる者は藁をもつかむ。", "Oboreru mono wa wara o mo tsukamu.", "Peribahasa: orang yang tenggelam akan meraih jerami sekalipun."),
    ]),
    ("yu5_n1", "柚", ["ユ"], ["ゆず"], ["buah yuzu", "yuzu citrus"], 9, "木", [
        ("柚子", "yuzu", "buah yuzu"),
        ("柚子湯", "yuzuyu", "mandi yuzu"),
        ("柚子胡椒", "yuzukoshou", "sambal yuzu"),
    ], [
        ("柚子湯に入りました。", "Yuzuyu ni hairimashita.", "Berendam air yuzu."),
        ("柚子胡椒をつけました。", "Yuzukoshou o tsukemashita.", "Menambahkan sambal yuzu."),
    ]),
    ("sen18_n1", "舛", ["セン"], [], ["bertentangan (jarang, nama)", "oppose", "differ"], 6, "舛", [
        ("舛添", "Masuzoe", "contoh nama keluarga"),
        ("舛", "masu", "nama karakter"),
        ("舛田", "Masuda", "contoh nama keluarga"),
    ], [
        ("舛添さんという政治家です。", "Masuzoe-san to iu seijika desu.", "Ini politisi bernama Masuzoe."),
        ("舛田さんに会いました。", "Masuda-san ni aimashita.", "Bertemu dengan Masuda."),
    ]),
    ("kou48_n1", "縞", ["コウ"], ["しま"], ["garis-garis/corak belang", "stripe"], 16, "糸", [
        ("縞", "shima", "garis-garis/belang"),
        ("縞模様", "shimamoyou", "motif garis-garis"),
        ("縞馬", "shimauma", "zebra"),
    ], [
        ("縞模様のシャツです。", "Shimamoyou no shatsu desu.", "Ini kemeja bermotif garis-garis."),
        ("縞馬を見ました。", "Shimauma o mimashita.", "Melihat zebra."),
    ]),
    ("ou12_n1", "謳", ["オウ"], ["うた-う"], ["memuji/menyanjung", "sing praises", "extol"], 18, "言", [
        ("謳う", "utau", "memuji/menyanjung dengan kata-kata"),
        ("謳歌", "ouka", "memuji-muji/menikmati sepenuhnya"),
        ("謳い文句", "utaimonku", "slogan/kata-kata promosi"),
    ], [
        ("青春を謳歌しました。", "Seishun o ouka shimashita.", "Menikmati masa muda sepenuhnya."),
        ("謳い文句に惹かれました。", "Utaimonku ni hikaremashita.", "Tertarik oleh slogan."),
    ]),
    ("ki31_n1", "杞", ["キ"], [], ["dahan willow, negara Qi kuno (klasik)", "willow", "state of Qi"], 7, "木", [
        ("杞憂", "kiyuu", "kekhawatiran berlebihan"),
        ("杞", "Ki", "nama negara kuno Tiongkok"),
        ("杞柳", "kiryuu", "pohon willow jenis tertentu"),
    ], [
        ("それは杞憂に過ぎません。", "Sore wa kiyuu ni suginasen.", "Itu hanya kekhawatiran berlebihan."),
        ("杞憂に終わりました。", "Kiyuu ni owarimashita.", "Berakhir hanya sebagai kekhawatiran yang tidak perlu."),
    ]),
    ("rin5_n1", "鱗", ["リン"], ["うろこ"], ["sisik", "scale (fish/reptile)"], 24, "魚", [
        ("鱗", "uroko", "sisik"),
        ("逆鱗", "gekirin", "kemarahan besar"),
        ("片鱗", "henrin", "secuil/sekelumit"),
    ], [
        ("魚の鱗を取りました。", "Sakana no uroko o torimashita.", "Membersihkan sisik ikan."),
        ("逆鱗に触れました。", "Gekirin ni furemashita.", "Membuat marah besar."),
    ]),
    ("ken19_n1", "繭", ["ケン"], ["まゆ"], ["kepompong", "cocoon"], 18, "糸", [
        ("繭", "mayu", "kepompong"),
        ("繭玉", "mayudama", "hiasan kepompong tahun baru"),
        ("繭価", "kenka", "harga kepompong"),
    ], [
        ("蚕が繭を作りました。", "Kaiko ga mayu o tsukurimashita.", "Ulat sutra membuat kepompong."),
        ("繭から絹糸を取ります。", "Mayu kara kinshi o torimasu.", "Mengambil benang sutra dari kepompong."),
    ]),
    ("tei24_n1", "釘", ["テイ"], ["くぎ"], ["paku", "nail"], 10, "金", [
        ("釘", "kugi", "paku"),
        ("釘付け", "kugizuke", "terpaku"),
        ("釘を刺す", "kugi o sasu", "memberi peringatan tegas"),
    ], [
        ("釘を打ちました。", "Kugi o uchimashita.", "Memaku."),
        ("釘を刺しておきました。", "Kugi o sashite okimashita.", "Memberi peringatan tegas terlebih dahulu."),
    ]),
    ("chi6_n1", "弛", ["チ"], ["たる-む", "ゆる-む"], ["kendur/longgar", "slack", "loosen"], 6, "弓", [
        ("弛む", "tarumu", "mengendur"),
        ("弛緩", "shikan", "relaksasi/kendur"),
        ("弛み", "tarumi", "kekendoran"),
    ], [
        ("気が弛んでいます。", "Ki ga tarunde imasu.", "Perhatiannya kendur."),
        ("筋肉が弛緩しました。", "Kinniku ga shikan shimashita.", "Ototnya relaksasi."),
    ]),
    ("ri8_n1", "狸", ["リ"], ["たぬき"], ["tanuki (anjing rakun Jepang)", "raccoon dog"], 10, "犬", [
        ("狸", "tanuki", "tanuki"),
        ("狸寝入り", "tanuki neiri", "pura-pura tidur"),
        ("狸親父", "tanuki oyaji", "orang licik"),
    ], [
        ("狸を見ました。", "Tanuki o mimashita.", "Melihat tanuki."),
        ("狸寝入りをしていました。", "Tanuki neiri o shite imashita.", "Pura-pura tidur."),
    ]),
    ("jin10_n1", "壬", ["ジン"], ["みずのえ"], ["unsur kalender kuno (air)", "9th calendar sign"], 4, "士", [
        ("壬申", "jinshin", "tahun air-monyet"),
        ("壬生", "Mibu", "nama tempat"),
        ("壬年", "jinnen", "tahun bertanda jin"),
    ], [
        ("壬申の乱という戦です。", "Jinshin no ran to iu ikusa desu.", "Ini perang bernama Pemberontakan Jinshin."),
        ("壬生という地名です。", "Mibu to iu chimei desu.", "Ini nama tempat Mibu."),
    ]),
    ("ken20_n1", "硯", ["ケン"], ["すずり"], ["batu tinta", "inkstone"], 12, "石", [
        ("硯", "suzuri", "batu tinta"),
        ("硯箱", "suzuribako", "kotak batu tinta"),
        ("筆硯", "hikken", "kuas dan batu tinta"),
    ], [
        ("硯で墨を磨りました。", "Suzuri de sumi o surimashita.", "Menggosok tinta di batu tinta."),
        ("硯箱を買いました。", "Suzuribako o kaimashita.", "Membeli kotak batu tinta."),
    ]),
]

PLACEHOLDER_COUNTS = {}


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


def build_n3_entries():
    entries = []
    for suffix, char, on, kun, meanings, strokes, radical, word_examples, sentence_examples in N3_KANJI:
        entries.append({
            "id": f"kanji_{suffix}",
            "character": char,
            "jlptLevel": "N3",
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


def build_n2_entries():
    entries = []
    for suffix, char, on, kun, meanings, strokes, radical, word_examples, sentence_examples in N2_KANJI:
        entries.append({
            "id": f"kanji_{suffix}",
            "character": char,
            "jlptLevel": "N2",
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


def build_n1_entries():
    entries = []
    for suffix, char, on, kun, meanings, strokes, radical, word_examples, sentence_examples in N1_KANJI:
        entries.append({
            "id": f"kanji_{suffix}",
            "character": char,
            "jlptLevel": "N1",
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
    data = (
        build_n5_entries()
        + build_n4_entries()
        + build_n3_entries()
        + build_n2_entries()
        + build_n1_entries()
        + build_placeholder_entries()
    )
    with open("assets/data/kanji_data.json", "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
    print(f"Wrote {len(data)} kanji entries ({len(N5_KANJI)} real N5 + "
          f"{len(N4_KANJI)} real N4 + {len(N3_KANJI)} real N3 (of "
          f"{len(N3_CHARACTERS)} locked) + {len(N2_KANJI)} real N2 (of "
          f"{len(N2_CHARACTERS)} locked) + {len(N1_KANJI)} real N1 (of "
          f"{len(N1_CHARACTERS)} locked) + {sum(PLACEHOLDER_COUNTS.values())} placeholders).")


if __name__ == "__main__":
    main()
