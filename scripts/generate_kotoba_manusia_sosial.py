import json

# Kotoba vocab — grup "Manusia & Sosial" (Batch 7).
# Same per-entry registers approach as the other Batch 7 scripts.
#
# agama_budaya needs extra care: entries are kept factual and neutral
# (naming a religion, or a plain "Saya beragama X" self-statement, or a
# well-documented demographic fact like Bali's Hindu majority) — no claims
# about doctrine or practice for any specific religion, so nothing here
# reads as favoring or characterizing one over another.
#
# keluarga_hubungan uses the humble/own-family terms (chichi/haha, not
# otousan/okaasan) since that's the standard N5 starting point, and each
# meaning is annotated "(kata sendiri)" so it doesn't read as the only way
# to say "father"/"mother" in Japanese.
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
    "profesi": [
        ("sensei", "先生", "せんせい", "sensei", "guru/dosen", "N5", "noun", "先生", "sensei", "先生", "sensei", [
            ("先生に質問します。", "Sensei ni shitsumon shimasu.", "Saya bertanya kepada guru."),
        ]),
        ("gakusei", "学生", "がくせい", "gakusei", "siswa/mahasiswa", "N5", "noun", "学生", "gakusei", "学生", "gakusei", [
            ("私は学生です。", "Watashi wa gakusei desu.", "Saya seorang siswa."),
        ]),
        ("kaishain", "会社員", "かいしゃいん", "kaishain", "karyawan perusahaan", "N4", "noun", "会社員", "kaishain", "会社員", "kaishain", [
            ("父は会社員です。", "Chichi wa kaishain desu.", "Ayah saya karyawan perusahaan."),
        ]),
        ("keisatsukan", "警察官", "けいさつかん", "keisatsukan", "polisi", "N4", "noun", "警察官", "keisatsukan", "警察官", "keisatsukan", [
            ("警察官が交通整理をします。", "Keisatsukan ga koutsuu seiri o shimasu.", "Polisi mengatur lalu lintas."),
        ]),
        ("shouboushi", "消防士", "しょうぼうし", "shouboushi", "pemadam kebakaran", "N3", "noun", "消防士", "shouboushi", "消防士", "shouboushi", [
            ("消防士は勇敢です。", "Shouboushi wa yuukan desu.", "Pemadam kebakaran itu berani."),
        ]),
        ("ryourinin", "料理人", "りょうりにん", "ryourinin", "koki/juru masak", "N3", "noun", "料理人", "ryourinin", "料理人", "ryourinin", [
            ("料理人は料理を作ります。", "Ryourinin wa ryouri o tsukurimasu.", "Koki membuat masakan."),
        ]),
        ("bengoshi", "弁護士", "べんごし", "bengoshi", "pengacara", "N3", "noun", "弁護士", "bengoshi", "弁護士", "bengoshi", [
            ("弁護士に相談します。", "Bengoshi ni soudan shimasu.", "Saya berkonsultasi dengan pengacara."),
        ]),
        ("enjinia", None, "エンジニア", "enjinia", "insinyur/engineer", "N3", "noun", "エンジニア", "enjinia", "エンジニア", "enjinia", [
            ("彼はエンジニアです。", "Kare wa enjinia desu.", "Dia seorang insinyur."),
        ]),
        ("nouka", "農家", "のうか", "nouka", "petani", "N3", "noun", "農家", "nouka", "農家", "nouka", [
            ("農家は野菜を育てます。", "Nouka wa yasai o sodatemasu.", "Petani menanam sayuran."),
        ]),
        ("untenshu", "運転手", "うんてんしゅ", "untenshu", "supir", "N3", "noun", "運転手", "untenshu", "運転手", "untenshu", [
            ("バスの運転手です。", "Basu no untenshu desu.", "Dia supir bus."),
        ]),
        ("shufu", "主婦", "しゅふ", "shufu", "ibu rumah tangga", "N3", "noun", "主婦", "shufu", "主婦", "shufu", [
            ("母は主婦です。", "Haha wa shufu desu.", "Ibu saya adalah ibu rumah tangga."),
        ]),
        ("kashu", "歌手", "かしゅ", "kashu", "penyanyi", "N3", "noun", "歌手", "kashu", "歌手", "kashu", [
            ("彼女は有名な歌手です。", "Kanojo wa yuumei na kashu desu.", "Dia penyanyi terkenal."),
        ]),
        # N1/N2 addition (2026-07-20, fourth batch): pure-kanji career-
        # related abstract nouns, for Kombinasi Kanji pool depth.
        ("juuji", "従事", "じゅうじ", "juuji", "menekuni (pekerjaan)", "N1", "noun", "従事", "juuji", "従事", "juuji", [
            ("農業に従事しています。", "Nougyou ni juuji shite imasu.", "Saya menekuni bidang pertanian."),
        ]),
        ("tekisei", "適性", "てきせい", "tekisei", "bakat/kesesuaian (profesi)", "N2", "noun", "適性", "tekisei", "適性", "tekisei", [
            ("この仕事に適性があります。", "Kono shigoto ni tekisei ga arimasu.", "Saya punya bakat untuk pekerjaan ini."),
        ]),
        ("tenshoku", "転職", "てんしょく", "tenshoku", "pindah kerja/ganti profesi", "N2", "noun", "転職", "tenshoku", "転職", "tenshoku", [
            ("来月転職します。", "Raigetsu tenshoku shimasu.", "Bulan depan saya pindah kerja."),
        ]),
        ("kengyou", "兼業", "けんぎょう", "kengyou", "pekerjaan sampingan", "N1", "noun", "兼業", "kengyou", "兼業", "kengyou", [
            ("農家と兼業しています。", "Nouka to kengyou shite imasu.", "Saya menjalankan usaha sampingan sebagai petani."),
        ]),
        # N2/N3 addition (2026-07-20, eleventh batch): more concrete
        # profession nouns, for Kombinasi Kanji pool depth.
        ("tsuuyaku", "通訳", "つうやく", "tsuuyaku", "juru bahasa/penerjemah lisan", "N2", "noun", "通訳", "tsuuyaku", "通訳", "tsuuyaku", [
            ("彼女は通訳をしています。", "Kanojo wa tsuuyaku o shite imasu.", "Dia bekerja sebagai juru bahasa."),
        ]),
        ("juui", "獣医", "じゅうい", "juui", "dokter hewan", "N2", "noun", "獣医", "juui", "獣医", "juui", [
            ("獣医に犬を診てもらいます。", "Juui ni inu o mite moraimasu.", "Saya membawa anjing ke dokter hewan."),
        ]),
        ("biyoushi", "美容師", "びようし", "biyoushi", "penata rambut", "N3", "noun", "美容師", "biyoushi", "美容師", "biyoushi", [
            ("美容師に髪を切ってもらいます。", "Biyoushi ni kami o kitte moraimasu.", "Saya minta penata rambut memotong rambut saya."),
        ]),
        ("kisha", "記者", "きしゃ", "kisha", "wartawan", "N3", "noun", "記者", "kisha", "記者", "kisha", [
            ("記者が質問をします。", "Kisha ga shitsumon o shimasu.", "Wartawan mengajukan pertanyaan."),
        ]),
        ("gaka", "画家", "がか", "gaka", "pelukis", "N3", "noun", "画家", "gaka", "画家", "gaka", [
            ("彼は有名な画家です。", "Kare wa yuumei na gaka desu.", "Dia pelukis terkenal."),
        ]),
        ("ishi", "医師", "いし", "ishi", "dokter (istilah formal)", "N3", "noun", "医師", "ishi", "医師", "ishi", [
            ("医師に相談します。", "Ishi ni soudan shimasu.", "Saya berkonsultasi dengan dokter."),
        ]),
        # N3/N4 addition (2026-07-20, twelfth batch): more concrete
        # profession nouns, for Kombinasi Kanji pool depth.
        ("koumuin", "公務員", "こうむいん", "koumuin", "pegawai negeri", "N3", "noun", "公務員", "koumuin", "公務員", "koumuin", [
            ("兄は公務員です。", "Ani wa koumuin desu.", "Kakak laki-laki saya seorang pegawai negeri."),
        ]),
        ("kyoushi", "教師", "きょうし", "kyoushi", "guru/pengajar (istilah profesi)", "N4", "noun", "教師", "kyoushi", "教師", "kyoushi", [
            ("彼女は教師です。", "Kanojo wa kyoushi desu.", "Dia seorang guru."),
        ]),
        ("kaikeishi", "会計士", "かいけいし", "kaikeishi", "akuntan", "N2", "noun", "会計士", "kaikeishi", "会計士", "kaikeishi", [
            ("彼は会計士として働いています。", "Kare wa kaikeishi to shite hataraite imasu.", "Dia bekerja sebagai akuntan."),
        ]),
        ("yakuzaishi", "薬剤師", "やくざいし", "yakuzaishi", "apoteker", "N1", "noun", "薬剤師", "yakuzaishi", "薬剤師", "yakuzaishi", [
            ("薬剤師に薬について聞きます。", "Yakuzaishi ni kusuri ni tsuite kikimasu.", "Saya menanyakan obat kepada apoteker."),
        ]),
        ("kachou", "課長", "かちょう", "kachou", "kepala bagian", "N2", "noun", "課長", "kachou", "課長", "kachou", [
            ("課長に報告します。", "Kachou ni houkoku shimasu.", "Saya melapor ke kepala bagian."),
        ]),
        ("keikan", "警官", "けいかん", "keikan", "polisi (istilah sapaan)", "N2", "noun", "警官", "keikan", "警官", "keikan", [
            ("警官に聞きました。", "Keikan ni kikimashita.", "Bertanya pada pak polisi. (Gelar) (お巡りさんmenyapa.C)"),
        ]),
        ("keisatsu", "警察", "けいさつ", "keisatsu", "kepolisian (institusi)", "N2", "noun", "警察", "keisatsu", "警察", "keisatsu", [
            ("警察を呼びます。", "Keisatsu o yobimasu.", "Memanggil kepolisian. (isntitusi)"),
        ]),
        ("sakusha", "作者", "さくしゃ", "sakusha", "pengarang", "N2", "noun", "作者", "sakusha", "作者", "sakusha", [
            ("作者の名前を書きます。", "Sakusha no namae o kakimasu.", "Menulis nama pengarang."),
        ]),
        ("sakka", "作家", "さっか", "sakka", "penulis", "N2", "noun", "作家", "sakka", "作家", "sakka", [
            ("彼は有名な作家です。", "Kare wa yuumei na sakka desu.", "Dia penulis terkenal."),
        ]),
        ("shichou", "市長", "しちょう", "shichou", "wali kota", "N2", "noun", "市長", "shichou", "市長", "shichou", [
            ("市長が来ました。", "Shichou ga kimashita.", "Wali kota datang."),
        ]),
        ("tenchou", "店長", "てんちょう", "tenchou", "kepala toko", "N2", "noun", "店長", "tenchou", "店長", "tenchou", [
            ("店長に相談しました。", "Tenchou ni soudan shimashita.", "Saya berkonsultasi dengan kepala toko."),
        ]),
        ("nougyou", "農業", "のうぎょう", "nougyou", "pertanian", "N2", "noun", "農業", "nougyou", "農業", "nougyou", [
            ("祖父は農業をしています。", "Sofu wa nougyou o shite imasu.", "Kakek bekerja di bidang pertanian."),
        ]),
    ],
    "keluarga_hubungan": [
        ("kazoku", "家族", "かぞく", "kazoku", "keluarga", "N5", "noun", "家族", "kazoku", "家族", "kazoku", [
            ("家族と住んでいます。", "Kazoku to sunde imasu.", "Saya tinggal dengan keluarga."),
        ]),
        ("chichi", "父", "ちち", "chichi", "ayah (kata sendiri)", "N5", "noun", "父", "chichi", "父", "chichi", [
            ("父は医者です。", "Chichi wa isha desu.", "Ayah saya seorang dokter."),
        ]),
        ("haha", "母", "はは", "haha", "ibu (kata sendiri)", "N5", "noun", "母", "haha", "母", "haha", [
            ("母は料理が上手です。", "Haha wa ryouri ga jouzu desu.", "Ibu saya jago memasak."),
        ]),
        ("ani", "兄", "あに", "ani", "kakak laki-laki (kata sendiri)", "N5", "noun", "兄", "ani", "兄", "ani", [
            ("兄は大学生です。", "Ani wa daigakusei desu.", "Kakak laki-laki saya mahasiswa."),
        ]),
        ("ane", "姉", "あね", "ane", "kakak perempuan (kata sendiri)", "N5", "noun", "姉", "ane", "姉", "ane", [
            ("姉は看護師です。", "Ane wa kangoshi desu.", "Kakak perempuan saya perawat."),
        ]),
        ("otouto", "弟", "おとうと", "otouto", "adik laki-laki", "N5", "noun", "弟", "otouto", "弟", "otouto", [
            ("弟は高校生です。", "Otouto wa koukousei desu.", "Adik laki-laki saya siswa SMA."),
        ]),
        ("imouto", "妹", "いもうと", "imouto", "adik perempuan", "N5", "noun", "妹", "imouto", "妹", "imouto", [
            ("妹は中学生です。", "Imouto wa chuugakusei desu.", "Adik perempuan saya siswa SMP."),
        ]),
        ("sofu", "祖父", "そふ", "sofu", "kakek (kata sendiri)", "N4", "noun", "祖父", "sofu", "祖父", "sofu", [
            ("祖父は元気です。", "Sofu wa genki desu.", "Kakek saya sehat."),
        ]),
        ("sobo", "祖母", "そぼ", "sobo", "nenek (kata sendiri)", "N4", "noun", "祖母", "sobo", "祖母", "sobo", [
            ("祖母は優しいです。", "Sobo wa yasashii desu.", "Nenek saya baik hati."),
        ]),
        ("musuko", "息子", "むすこ", "musuko", "anak laki-laki (kata sendiri)", "N4", "noun", "息子", "musuko", "息子", "musuko", [
            ("息子は五歳です。", "Musuko wa gosai desu.", "Anak laki-laki saya berusia 5 tahun."),
        ]),
        ("musume", "娘", "むすめ", "musume", "anak perempuan (kata sendiri)", "N4", "noun", "娘", "musume", "娘", "musume", [
            ("娘は学生です。", "Musume wa gakusei desu.", "Anak perempuan saya seorang pelajar."),
        ]),
        ("tomodachi", "友達", "ともだち", "tomodachi", "teman", "N5", "noun", "友達", "tomodachi", "友達", "tomodachi", [
            ("友達と遊びます。", "Tomodachi to asobimasu.", "Saya bermain dengan teman."),
        ]),
        ("koibito", "恋人", "こいびと", "koibito", "kekasih/pacar", "N4", "noun", "恋人", "koibito", "恋人", "koibito", [
            ("恋人にプレゼントをあげます。", "Koibito ni purezento o agemasu.", "Saya memberi hadiah untuk kekasih."),
        ]),
        ("fuufu", "夫婦", "ふうふ", "fuufu", "pasangan suami istri", "N3", "noun", "夫婦", "fuufu", "夫婦", "fuufu", [
            ("二人は夫婦です。", "Futari wa fuufu desu.", "Mereka berdua adalah pasangan suami istri."),
        ]),
        # N1/N2 addition (2026-07-20, fourth batch): pure-kanji relationship
        # nouns, for Kombinasi Kanji pool depth.
        ("soen", "疎遠", "そえん", "soen", "keterasingan/jarang berhubungan", "N1", "noun", "疎遠", "soen", "疎遠", "soen", [
            ("最近、彼とは疎遠になりました。", "Saikin, kare to wa soen ni narimashita.", "Belakangan ini, saya jadi jarang berhubungan dengannya."),
        ]),
        ("wakai", "和解", "わかい", "wakai", "berdamai/rekonsiliasi", "N2", "noun", "和解", "wakai", "和解", "wakai", [
            ("兄弟はようやく和解しました。", "Kyoudai wa youyaku wakai shimashita.", "Kakak beradik itu akhirnya berdamai."),
        ]),
        ("danzetsu", "断絶", "だんぜつ", "danzetsu", "keterputusan (hubungan)", "N1", "noun", "断絶", "danzetsu", "断絶", "danzetsu", [
            ("親子関係が断絶しました。", "Oyako kankei ga danzetsu shimashita.", "Hubungan orang tua-anak itu terputus."),
        ]),
        # N5 addition prompted by the same compound-pool gap noted in
        # scripts/generate_kotoba_waktu_angka.py's hari_bulan addition —
        # these are the general (non-"kata sendiri") sibling/parent/age
        # terms, distinct from 兄/姉/弟/妹 above which are specifically
        # how you refer to your OWN siblings.
        ("kyoudai", "兄弟", "きょうだい", "kyoudai", "saudara kandung (kakak-adik)", "N5", "noun", "兄弟", "kyoudai", "兄弟", "kyoudai", [
            ("兄弟は何人いますか。", "Kyoudai wa nan-nin imasu ka.", "Ada berapa saudara kandung?"),
        ]),
        ("shimai", "姉妹", "しまい", "shimai", "saudari perempuan (kakak-adik)", "N5", "noun", "姉妹", "shimai", "姉妹", "shimai", [
            ("姉妹で買い物に行きます。", "Shimai de kaimono ni ikimasu.", "Kami bersaudari pergi berbelanja."),
        ]),
        ("ryoushin", "両親", "りょうしん", "ryoushin", "kedua orang tua", "N5", "noun", "両親", "ryoushin", "両親", "ryoushin", [
            ("両親と話します。", "Ryoushin to hanashimasu.", "Saya berbicara dengan kedua orang tua saya."),
        ]),
        ("kodomo", "子供", "こども", "kodomo", "anak (secara umum)", "N5", "noun", "子供", "kodomo", "子供", "kodomo", [
            ("子供が公園で遊びます。", "Kodomo ga kouen de asobimasu.", "Anak-anak bermain di taman."),
        ]),
        ("otona", "大人", "おとな", "otona", "orang dewasa", "N5", "noun", "大人", "otona", "大人", "otona", [
            ("大人になりました。", "Otona ni narimashita.", "Saya sudah menjadi dewasa."),
        ]),
        # N1/N2 addition (2026-07-20, twelfth batch): extended-family/
        # relationship nouns, for Kombinasi Kanji pool depth.
        ("shinseki", "親戚", "しんせき", "shinseki", "kerabat/saudara jauh", "N2", "noun", "親戚", "shinseki", "親戚", "shinseki", [
            ("お正月に親戚が集まります。", "Oshougatsu ni shinseki ga atsumarimasu.", "Kerabat berkumpul saat Tahun Baru."),
        ]),
        ("haiguusha", "配偶者", "はいぐうしゃ", "haiguusha", "pasangan (suami/istri, istilah hukum)", "N1", "noun", "配偶者", "haiguusha", "配偶者", "haiguusha", [
            ("配偶者の名前を記入してください。", "Haiguusha no namae o kinyuu shite kudasai.", "Tolong isi nama pasangan Anda."),
        ]),
        ("ketsuen", "血縁", "けつえん", "ketsuen", "hubungan darah", "N1", "noun", "血縁", "ketsuen", "血縁", "ketsuen", [
            ("二人には血縁関係があります。", "Futari ni wa ketsuen kankei ga arimasu.", "Kedua orang itu memiliki hubungan darah."),
        ]),
        ("dokushin", "独身", "どくしん", "dokushin", "belum menikah/single", "N2", "noun", "独身", "dokushin", "独身", "dokushin", [
            ("彼はまだ独身です。", "Kare wa mada dokushin desu.", "Dia masih belum menikah."),
        ]),
        ("oyako", "親子", "おやこ", "oyako", "orang tua dan anak", "N2", "noun", "親子", "oyako", "親子", "oyako", [
            ("親子で来ました。", "Oyako de kimashita.", "Datang bersama orang tua dan anak."),
        ]),
        ("katei", "家庭", "かてい", "katei", "keluarga/rumah tangga", "N2", "noun", "家庭", "katei", "家庭", "katei", [
            ("家庭を大切にします。", "Katei o taisetsu ni shimasu.", "Saya menghargai keluarga."),
        ]),
        ("kekkon", "結婚", "けっこん", "kekkon", "pernikahan", "N2", "noun", "結婚", "kekkon", "結婚", "kekkon", [
            ("来年結婚します。", "Rainen kekkon shimasu.", "Tahun depan menikah."),
        ]),
        ("jikka", "実家", "じっか", "jikka", "rumah orang tua", "N2", "noun", "実家", "jikka", "実家", "jikka", [
            ("実家に帰ります。", "Jikka ni kaerimasu.", "Pulang ke rumah orang tua."),
        ]),
        ("tanjou", "誕生", "たんじょう", "tanjou", "kelahiran", "N2", "noun", "誕生", "tanjou", "誕生", "tanjou", [
            ("子どもが誕生しました。", "Kodomo ga tanjou shimashita.", "Bayi lahir. (Kelahiran resmi/peristiwa penting)"),
        ]),
        ("nakama", "仲間", "なかま", "nakama", "teman/rekan satu kelompok", "N2", "noun", "仲間", "nakama", "仲間", "nakama", [
            ("仲間と協力します。", "Nakama to kyouryoku shimasu.", "Saya bekerja sama dengan teman satu tim."),
        ]),
        ("yakuwari", "役割", "やくわり", "yakuwari", "peran/tugas", "N2", "noun", "役割", "yakuwari", "役割", "yakuwari", [
            ("両親の役割はたいせつです。", "Ryoushin no yakuwari wa taisetsu desu.", "Peran orang tua penting."),
        ]),
        ("yuujou", "友情", "ゆうじょう", "yuujou", "persahabatan", "N2", "noun", "友情", "yuujou", "友情", "yuujou", [
            ("彼との友情は大切です。", "Kare to no yuujou wa taisetsu desu.", "Persahabatan dengannya penting. (hub persahabantan)"),
        ]),
        ("yuujin", "友人", "ゆうじん", "yuujin", "teman (istilah formal)", "N2", "noun", "友人", "yuujin", "友人", "yuujin", [
            ("友人に会いました。", "Yuujin ni aimashita.", "Saya bertemu teman. (saat pidato,tulisan dll)"),
        ]),
        ("wakamono", "若者", "わかもの", "wakamono", "anak muda", "N2", "noun", "若者", "wakamono", "若者", "wakamono", [
            ("若者が増えています。", "Wakamono ga fuete imasu.", "Anak muda bertambah."),
        ]),
        ("sofubo", "祖父母", "そふぼ", "sofubo", "kakek dan nenek", "N2", "noun", "祖父母", "sofubo", "祖父母", "sofubo", [
            ("祖父母は田舎に住んでいます。", "Sofubo wa inaka ni sunde imasu.", "Kakek nenek tinggal di desa."),
        ]),
        ("aishou", "相性", "あいしょう", "aishou", "kecocokan (antar orang)", "N2", "noun", "相性", "aishou", "相性", "aishou", [
            ("この二人は相性がいい。", "Kono futari wa aishou ga ii.", "Kedua orang ini cocok satu sama lain."),
        ]),
        ("ikuji", "育児", "いくじ", "ikuji", "mengurus anak", "N2", "noun", "育児", "ikuji", "育児", "ikuji", [
            ("彼女は育児に忙しい。", "Kanojo wa ikuji ni isogashii.", "Dia sibuk mengurus anak. (bayi / anak kecil)"),
        ]),
    ],
    "pakaian_aksesori": [
        ("fuku", "服", "ふく", "fuku", "baju/pakaian", "N5", "noun", "服", "fuku", "服", "fuku", [
            ("服を着ます。", "Fuku o kimasu.", "Saya memakai baju."),
        ]),
        ("shatsu", None, "シャツ", "shatsu", "kemeja/shirt", "N4", "noun", "シャツ", "shatsu", "シャツ", "shatsu", [
            ("シャツを着ます。", "Shatsu o kimasu.", "Saya memakai kemeja."),
        ]),
        ("zubon", None, "ズボン", "zubon", "celana panjang", "N4", "noun", "ズボン", "zubon", "ズボン", "zubon", [
            ("ズボンを履きます。", "Zubon o hakimasu.", "Saya memakai celana panjang."),
        ]),
        ("sukaato", None, "スカート", "sukaato", "rok", "N4", "noun", "スカート", "sukaato", "スカート", "sukaato", [
            ("スカートを履きます。", "Sukaato o hakimasu.", "Saya memakai rok."),
        ]),
        ("kutsu", "靴", "くつ", "kutsu", "sepatu", "N5", "noun", "靴", "kutsu", "靴", "kutsu", [
            ("靴を履きます。", "Kutsu o hakimasu.", "Saya memakai sepatu."),
        ]),
        ("boushi", "帽子", "ぼうし", "boushi", "topi", "N4", "noun", "帽子", "boushi", "帽子", "boushi", [
            ("帽子をかぶります。", "Boushi o kaburimasu.", "Saya memakai topi."),
        ]),
        ("megane", "眼鏡", "めがね", "megane", "kacamata", "N4", "noun", "眼鏡", "megane", "眼鏡", "megane", [
            ("眼鏡をかけます。", "Megane o kakemasu.", "Saya memakai kacamata."),
        ]),
        ("tokei", "時計", "とけい", "tokei", "jam (tangan)", "N5", "noun", "時計", "tokei", "時計", "tokei", [
            ("時計をつけます。", "Tokei o tsukemasu.", "Saya memakai jam tangan."),
        ]),
        ("baggu", None, "バッグ", "baggu", "tas", "N4", "noun", "バッグ", "baggu", "バッグ", "baggu", [
            ("バッグを持ちます。", "Baggu o mochimasu.", "Saya membawa tas."),
        ]),
        ("yubiwa", "指輪", "ゆびわ", "yubiwa", "cincin", "N3", "noun", "指輪", "yubiwa", "指輪", "yubiwa", [
            ("指輪をつけます。", "Yubiwa o tsukemasu.", "Saya memakai cincin."),
        ]),
        ("nekutai", None, "ネクタイ", "nekutai", "dasi", "N3", "noun", "ネクタイ", "nekutai", "ネクタイ", "nekutai", [
            ("ネクタイを締めます。", "Nekutai o shimemasu.", "Saya memakai dasi."),
        ]),
        ("kimono", "着物", "きもの", "kimono", "kimono (pakaian tradisional Jepang)", "N3", "noun", "着物", "kimono", "着物", "kimono", [
            ("着物を着ます。", "Kimono o kimasu.", "Saya memakai kimono."),
        ]),
        # N5 addition, same compound-pool gap as noted above.
        ("saifu", "財布", "さいふ", "saifu", "dompet", "N5", "noun", "財布", "saifu", "財布", "saifu", [
            ("財布を忘れました。", "Saifu o wasuremashita.", "Saya lupa membawa dompet."),
        ]),
        ("kutsushita", "靴下", "くつした", "kutsushita", "kaus kaki", "N5", "noun", "靴下", "kutsushita", "靴下", "kutsushita", [
            ("靴下を履きます。", "Kutsushita o hakimasu.", "Saya memakai kaus kaki."),
        ]),
        ("youfuku", "洋服", "ようふく", "youfuku", "baju (bergaya barat)", "N5", "noun", "洋服", "youfuku", "洋服", "youfuku", [
            ("洋服を買います。", "Youfuku o kaimasu.", "Saya membeli baju."),
        ]),
        ("tebukuro", "手袋", "てぶくろ", "tebukuro", "sarung tangan", "N3", "noun", "手袋", "tebukuro", "手袋", "tebukuro", [
            ("手袋をはめます。", "Tebukuro o hamemasu.", "Saya memakai sarung tangan."),
        ]),
        ("seifuku", "制服", "せいふく", "seifuku", "seragam", "N2", "noun", "制服", "seifuku", "制服", "seifuku", [
            ("学校の制服を着ます。", "Gakkou no seifuku o kimasu.", "Memakai seragam sekolah."),
        ]),
        ("fukusou", "服装", "ふくそう", "fukusou", "pakaian/penampilan", "N2", "noun", "服装", "fukusou", "服装", "fukusou", [
            ("服装に気をつけてください。", "Fukusou ni ki o tsukete kudasai.", "Tolong perhatikan pakaian. (tampilan, outfit)"),
        ]),
        ("furugi", "古着", "ふるぎ", "furugi", "baju bekas", "N2", "noun", "古着", "furugi", "古着", "furugi", [
            ("古着を買いました。", "Furugi o kaimashita.", "Saya membeli baju bekas."),
        ]),
        ("udedokei", "腕時計", "うでどけい", "udedokei", "jam tangan", "N2", "noun", "腕時計", "udedokei", "腕時計", "udedokei", [
            ("腕時計を買いました。", "Udedokei o kaimashita.", "Saya membeli jam tangan."),
        ]),
        ("ishou", "衣装", "いしょう", "ishou", "kostum", "N2", "noun", "衣装", "ishou", "衣装", "ishou", [
            ("祭りの衣装を着ました。", "Matsuri no ishou o kimashita.", "Saya memakai kostum festival. (untuk pertunjukan)"),
        ]),
    ],
    "hobi_aktivitas": [
        ("shumi", "趣味", "しゅみ", "shumi", "hobi", "N4", "noun", "趣味", "shumi", "趣味", "shumi", [
            ("趣味は何ですか。", "Shumi wa nan desu ka.", "Apa hobimu?"),
        ]),
        ("dokusho", "読書", "どくしょ", "dokusho", "membaca buku", "N4", "noun", "読書", "dokusho", "読書", "dokusho", [
            ("読書が好きです。", "Dokusho ga suki desu.", "Saya suka membaca buku."),
        ]),
        ("ongaku", "音楽", "おんがく", "ongaku", "musik", "N5", "noun", "音楽", "ongaku", "音楽", "ongaku", [
            ("音楽を聴きます。", "Ongaku o kikimasu.", "Saya mendengarkan musik."),
        ]),
        ("eiga", "映画", "えいが", "eiga", "film", "N5", "noun", "映画", "eiga", "映画", "eiga", [
            ("映画を見ます。", "Eiga o mimasu.", "Saya menonton film."),
        ]),
        ("ryokou", "旅行", "りょこう", "ryokou", "bepergian/traveling", "N4", "noun", "旅行", "ryokou", "旅行", "ryokou", [
            ("旅行が好きです。", "Ryokou ga suki desu.", "Saya suka bepergian."),
        ]),
        ("shashin", "写真", "しゃしん", "shashin", "foto/fotografi", "N4", "noun", "写真", "shashin", "写真", "shashin", [
            ("写真を撮ります。", "Shashin o torimasu.", "Saya memotret."),
        ]),
        ("e", "絵", "え", "e", "gambar/lukisan", "N4", "noun", "絵", "e", "絵", "e", [
            ("絵を描きます。", "E o kakimasu.", "Saya menggambar."),
        ]),
        ("gaadeningu", None, "ガーデニング", "gaadeningu", "berkebun", "N3", "noun", "ガーデニング", "gaadeningu", "ガーデニング", "gaadeningu", [
            ("ガーデニングが趣味です。", "Gaadeningu ga shumi desu.", "Berkebun adalah hobi saya."),
        ]),
        ("ryouri", "料理", "りょうり", "ryouri", "memasak (sebagai hobi)", "N4", "noun", "料理", "ryouri", "料理", "ryouri", [
            ("料理をするのが好きです。", "Ryouri o suru no ga suki desu.", "Saya suka memasak."),
        ]),
        ("geemu", None, "ゲーム", "geemu", "permainan/game", "N4", "noun", "ゲーム", "geemu", "ゲーム", "geemu", [
            ("ゲームをします。", "Geemu o shimasu.", "Saya bermain game."),
        ]),
        ("dansu", None, "ダンス", "dansu", "menari/dance", "N3", "noun", "ダンス", "dansu", "ダンス", "dansu", [
            ("ダンスを習っています。", "Dansu o naratte imasu.", "Saya sedang belajar menari."),
        ]),
        ("kyanpu", None, "キャンプ", "kyanpu", "berkemah/camping", "N3", "noun", "キャンプ", "kyanpu", "キャンプ", "kyanpu", [
            ("キャンプに行きます。", "Kyanpu ni ikimasu.", "Saya pergi berkemah."),
        ]),
        # N5 addition, same compound-pool gap noted above — everyday
        # household activities, verb-derived nouns like ryouri/dokusho
        # above rather than a new word type.
        ("sentaku", "洗濯", "せんたく", "sentaku", "mencuci baju", "N5", "noun", "洗濯", "sentaku", "洗濯", "sentaku", [
            ("洗濯をします。", "Sentaku o shimasu.", "Saya mencuci baju."),
        ]),
        ("souji", "掃除", "そうじ", "souji", "membersihkan/bersih-bersih", "N5", "noun", "掃除", "souji", "掃除", "souji", [
            ("部屋を掃除します。", "Heya o souji shimasu.", "Saya membersihkan kamar."),
        ]),
        ("kaimono", "買物", "かいもの", "kaimono", "berbelanja", "N5", "noun", "買物", "kaimono", "買物", "kaimono", [
            ("買物に行きます。", "Kaimono ni ikimasu.", "Saya pergi berbelanja."),
        ]),
        ("sanpo", "散歩", "さんぽ", "sanpo", "jalan-jalan santai", "N5", "noun", "散歩", "sanpo", "散歩", "sanpo", [
            ("公園を散歩します。", "Kouen o sanpo shimasu.", "Saya jalan-jalan santai di taman."),
        ]),
        # N1/N2 addition (2026-07-20, fourth batch): pure-kanji hobby-
        # related abstract nouns, for Kombinasi Kanji pool depth.
        ("bottou", "没頭", "ぼっとう", "bottou", "keasyikan/tenggelam (dalam kegiatan)", "N1", "noun", "没頭", "bottou", "没頭", "bottou", [
            ("趣味に没頭しています。", "Shumi ni bottou shite imasu.", "Saya tenggelam dalam hobi saya."),
        ]),
        ("netchuu", "熱中", "ねっちゅう", "netchuu", "antusiasme/keasyikan", "N2", "noun", "熱中", "netchuu", "熱中", "netchuu", [
            ("ゲームに熱中しています。", "Geemu ni netchuu shite imasu.", "Saya sangat antusias dengan game."),
        ]),
        ("juujitsu", "充実", "じゅうじつ", "juujitsu", "kepuasan/terpenuhi (kegiatan)", "N2", "noun", "充実", "juujitsu", "充実", "juujitsu", [
            ("毎日充実しています。", "Mainichi juujitsu shite imasu.", "Setiap hari terasa memuaskan."),
        ]),
        ("hassan", "発散", "はっさん", "hassan", "pelampiasan/pelepasan (stres)", "N1", "noun", "発散", "hassan", "発散", "hassan", [
            ("運動でストレスを発散します。", "Undou de sutoresu o hassan shimasu.", "Saya melampiaskan stres lewat olahraga."),
        ]),
        ("ensou", "演奏", "えんそう", "ensou", "permainan musik/pertunjukan", "N2", "noun", "演奏", "ensou", "演奏", "ensou", [
            ("ピアノを演奏します。", "Piano o ensou shimasu.", "Memainkan piano. (pertunjukkan)"),
        ]),
        ("kaiga", "絵画", "かいが", "kaiga", "lukisan", "N2", "noun", "絵画", "kaiga", "絵画", "kaiga", [
            ("絵画を見に行きます。", "Kaiga o mi ni ikimasu.", "Pergi melihat lukisan. (lukisan seni, artistik)"),
        ]),
        ("katsudou", "活動", "かつどう", "katsudou", "kegiatan", "N2", "noun", "活動", "katsudou", "活動", "katsudou", [
            ("ボランティア活動をしている。", "Borantia katsudou o shite iru.", "Saya melakukan kegiatan relawan."),
        ]),
        ("kankou", "観光", "かんこう", "kankou", "wisata", "N2", "noun", "観光", "kankou", "観光", "kankou", [
            ("京都を観光します。", "Kyouto o kankou shimasu.", "Berwisata di Kyoto."),
        ]),
        ("gaishoku", "外食", "がいしょく", "gaishoku", "makan di luar", "N2", "noun", "外食", "gaishoku", "外食", "gaishoku", [
            ("今日は外食します。", "Kyou wa gaishoku shimasu.", "Hari ini makan di luar."),
        ]),
        ("gakki", "楽器", "がっき", "gakki", "alat musik", "N2", "noun", "楽器", "gakki", "楽器", "gakki", [
            ("楽器を練習します。", "Gakki o renshuu shimasu.", "Berlatih alat musik."),
        ]),
        ("geijutsu", "芸術", "げいじゅつ", "geijutsu", "seni", "N2", "noun", "芸術", "geijutsu", "芸術", "geijutsu", [
            ("芸術に興味があります。", "Geijutsu ni kyoumi ga arimasu.", "Tertarik pada seni. (seni pertunjukan/ hiburan)"),
        ]),
        ("sakuhin", "作品", "さくひん", "sakuhin", "karya", "N2", "noun", "作品", "sakuhin", "作品", "sakuhin", [
            ("この作品は有名です。", "Kono sakuhin wa yuumei desu.", "Karya ini terkenal."),
        ]),
        ("ryuukou", "流行", "りゅうこう", "ryuukou", "tren/mode", "N2", "noun", "流行", "ryuukou", "流行", "ryuukou", [
            ("この服が流行しています。", "Kono fuku ga ryuukou shite imasu.", "Baju ini sedang tren. (Hits biasanya waktunya sebentar)"),
        ]),
    ],
    "agama_budaya": [
        ("shuukyou", "宗教", "しゅうきょう", "shuukyou", "agama", "N3", "noun", "宗教", "shuukyou", "宗教", "shuukyou", [
            ("宗教について話します。", "Shuukyou ni tsuite hanashimasu.", "Saya berbicara tentang agama."),
        ]),
        ("bukkyou", "仏教", "ぶっきょう", "bukkyou", "agama Buddha", "N3", "noun", "仏教", "bukkyou", "仏教", "bukkyou", [
            ("私は仏教です。", "Watashi wa bukkyou desu.", "Saya beragama Buddha."),
        ]),
        ("shintou", "神道", "しんとう", "shintou", "Shinto (agama asli Jepang)", "N2", "noun", "神道", "shintou", "神道", "shintou", [
            ("神道は日本の伝統的な宗教です。", "Shintou wa Nihon no dentouteki na shuukyou desu.", "Shinto adalah agama tradisional Jepang."),
        ]),
        ("isuramukyou", "イスラム教", "いすらむきょう", "isuramukyou", "agama Islam", "N3", "noun", "イスラム教", "isuramukyou", "イスラム教", "isuramukyou", [
            ("私はイスラム教です。", "Watashi wa isuramukyou desu.", "Saya beragama Islam."),
        ]),
        ("kirisutokyou", "キリスト教", "きりすときょう", "kirisutokyou", "agama Kristen", "N3", "noun", "キリスト教", "kirisutokyou", "キリスト教", "kirisutokyou", [
            ("私はキリスト教です。", "Watashi wa kirisutokyou desu.", "Saya beragama Kristen."),
        ]),
        ("hinduukyou", "ヒンドゥー教", "ひんどぅーきょう", "hinduukyou", "agama Hindu", "N2", "noun", "ヒンドゥー教", "hinduukyou", "ヒンドゥー教", "hinduukyou", [
            ("バリではヒンドゥー教が多いです。", "Bari de wa hinduukyou ga ooi desu.", "Di Bali, agama Hindu banyak dianut."),
        ]),
        ("matsuri", "祭り", "まつり", "matsuri", "festival/perayaan tradisional", "N3", "noun", "祭り", "matsuri", "祭り", "matsuri", [
            ("夏に祭りがあります。", "Natsu ni matsuri ga arimasu.", "Ada festival di musim panas."),
        ]),
        ("dentou", "伝統", "でんとう", "dentou", "tradisi", "N3", "noun", "伝統", "dentou", "伝統", "dentou", [
            ("日本の伝統を学びます。", "Nihon no dentou o manabimasu.", "Saya belajar tradisi Jepang."),
        ]),
        ("bunka", "文化", "ぶんか", "bunka", "budaya", "N4", "noun", "文化", "bunka", "文化", "bunka", [
            ("日本の文化に興味があります。", "Nihon no bunka ni kyoumi ga arimasu.", "Saya tertarik pada budaya Jepang."),
        ]),
        ("reihai", "礼拝", "れいはい", "reihai", "ibadah/sembahyang", "N2", "noun", "礼拝", "reihai", "礼拝", "reihai", [
            ("礼拝に行きます。", "Reihai ni ikimasu.", "Saya pergi beribadah."),
        ]),
        # N1/N2 addition (2026-07-20, fourth batch): kept to the same
        # neutral, factual register as the rest of this category (see the
        # CLAUDE.md note on agama_budaya) — general concepts, no claim
        # about any specific religion's doctrine or practice.
        ("keishou", "継承", "けいしょう", "keishou", "pewarisan (tradisi/budaya)", "N1", "noun", "継承", "keishou", "継承", "keishou", [
            ("伝統文化を継承します。", "Dentou bunka o keishou shimasu.", "Kami mewariskan budaya tradisional."),
        ]),
        ("gishiki", "儀式", "ぎしき", "gishiki", "upacara/ritual", "N2", "noun", "儀式", "gishiki", "儀式", "gishiki", [
            ("結婚の儀式を行います。", "Kekkon no gishiki o okonaimasu.", "Kami melaksanakan upacara pernikahan."),
        ]),
        ("shinkou", "信仰", "しんこう", "shinkou", "keyakinan/keimanan", "N2", "noun", "信仰", "shinkou", "信仰", "shinkou", [
            ("信仰は人それぞれです。", "Shinkou wa hito sorezore desu.", "Keyakinan itu berbeda-beda pada setiap orang."),
        ]),
        # N4 addition (2026-07-20, thirteenth batch): neutral culture noun,
        # same register discipline as the rest of this category.
        ("shuukan", "習慣", "しゅうかん", "shuukan", "kebiasaan/adat", "N4", "noun", "習慣", "shuukan", "習慣", "shuukan", [
            ("毎朝運動する習慣があります。", "Maiasa undou suru shuukan ga arimasu.", "Saya punya kebiasaan berolahraga setiap pagi."),
        ]),
    ],
    "perayaan_haribesar": [
        ("oshougatsu", "お正月", "おしょうがつ", "oshougatsu", "Tahun Baru (Jepang)", "N4", "noun", "お正月", "oshougatsu", "お正月", "oshougatsu", [
            ("お正月に家族と過ごします。", "Oshougatsu ni kazoku to sugoshimasu.", "Saya menghabiskan Tahun Baru dengan keluarga."),
        ]),
        ("tanjoubi", "誕生日", "たんじょうび", "tanjoubi", "ulang tahun", "N5", "noun", "誕生日", "tanjoubi", "誕生日", "tanjoubi", [
            ("誕生日おめでとう。", "Tanjoubi omedetou.", "Selamat ulang tahun."),
        ]),
        ("kurisumasu", None, "クリスマス", "kurisumasu", "Natal", "N4", "noun", "クリスマス", "kurisumasu", "クリスマス", "kurisumasu", [
            ("クリスマスを祝います。", "Kurisumasu o iwaimasu.", "Saya merayakan Natal."),
        ]),
        ("hinamatsuri", "雛祭り", "ひなまつり", "hinamatsuri", "Hina Matsuri (festival boneka, 3 Maret)", "N2", "noun", "雛祭り", "hinamatsuri", "雛祭り", "hinamatsuri", [
            ("3月3日はひな祭りです。", "Sangatsu mikka wa hinamatsuri desu.", "3 Maret adalah Hina Matsuri."),
        ]),
        ("tanabata", "七夕", "たなばた", "tanabata", "Tanabata (festival bintang, 7 Juli)", "N2", "noun", "七夕", "tanabata", "七夕", "tanabata", [
            ("七夕に願い事をします。", "Tanabata ni negaigoto o shimasu.", "Saat Tanabata, saya membuat permohonan."),
        ]),
        ("obon", "お盆", "おぼん", "obon", "Obon (festival arwah leluhur)", "N2", "noun", "お盆", "obon", "お盆", "obon", [
            ("お盆に田舎に帰ります。", "Obon ni inaka ni kaerimasu.", "Saat Obon, saya pulang kampung."),
        ]),
        ("kekkonshiki", "結婚式", "けっこんしき", "kekkonshiki", "pernikahan/pesta pernikahan", "N3", "noun", "結婚式", "kekkonshiki", "結婚式", "kekkonshiki", [
            ("結婚式に招待されました。", "Kekkonshiki ni shoutai saremashita.", "Saya diundang ke pernikahan."),
        ]),
        ("oiwai", "お祝い", "おいわい", "oiwai", "perayaan/selamat", "N3", "noun", "お祝い", "oiwai", "お祝い", "oiwai", [
            ("お祝いのプレゼントを買います。", "Oiwai no purezento o kaimasu.", "Saya membeli hadiah perayaan."),
        ]),
        ("hanabi", "花火", "はなび", "hanabi", "kembang api", "N3", "noun", "花火", "hanabi", "花火", "hanabi", [
            ("夏に花火を見ます。", "Natsu ni hanabi o mimasu.", "Saya menonton kembang api di musim panas."),
        ]),
        ("ramadan", None, "ラマダン", "ramadan", "Ramadan (bulan puasa)", "N2", "noun", "ラマダン", "ramadan", "ラマダン", "ramadan", [
            ("ラマダン中は断食します。", "Ramadan-chuu wa danjiki shimasu.", "Selama Ramadan, orang berpuasa."),
        ]),
        ("barentaindee", None, "バレンタインデー", "barentaindee", "Hari Valentine", "N3", "noun", "バレンタインデー", "barentaindee", "バレンタインデー", "barentaindee", [
            ("バレンタインデーにチョコレートをあげます。", "Barentaindee ni chokoreeto o agemasu.", "Saat Hari Valentine, saya memberi cokelat."),
        ]),
        # N1 addition (2026-07-20, fifth batch): pure-kanji celebration
        # noun, for Kombinasi Kanji pool depth.
        ("shukuga", "祝賀", "しゅくが", "shukuga", "perayaan/ucapan selamat (formal)", "N1", "noun", "祝賀", "shukuga", "祝賀", "shukuga", [
            ("創立百周年の祝賀会が開かれました。", "Souritsu hyakushuunen no shukugakai ga hirakaremashita.", "Perayaan seratus tahun pendirian diadakan."),
        ]),
        # N2/N3 addition (2026-07-20, thirteenth batch): more everyday
        # celebration/milestone nouns, for Kombinasi Kanji pool depth.
        ("kinenbi", "記念日", "きねんび", "kinenbi", "hari peringatan/anniversary", "N3", "noun", "記念日", "kinenbi", "記念日", "kinenbi", [
            ("結婚記念日をお祝いします。", "Kekkon kinenbi o oiwai shimasu.", "Kami merayakan hari peringatan pernikahan."),
        ]),
        ("seijinshiki", "成人式", "せいじんしき", "seijinshiki", "upacara kedewasaan", "N2", "noun", "成人式", "seijinshiki", "成人式", "seijinshiki", [
            ("来年、成人式に出ます。", "Rainen, seijinshiki ni demasu.", "Tahun depan, saya akan mengikuti upacara kedewasaan."),
        ]),
        ("kinen", "記念", "きねん", "kinen", "kenangan/peringatan", "N2", "noun", "記念", "kinen", "記念", "kinen", [
            ("記念写真を撮ります。", "Kinen shashin o torimasu.", "Mengambil foto kenangan."),
        ]),
        ("shoutai", "招待", "しょうたい", "shoutai", "undangan", "N2", "noun", "招待", "shoutai", "招待", "shoutai", [
            ("パーティーに招待されました。", "Paatii ni shoutai saremashita.", "Diundang ke pesta."),
        ]),
    ],
    # New category (2026-07-20, sixth batch), added specifically to keep
    # growing Kanji Kombinasi's pool without forcing abstract N1-N3 nouns
    # into concrete real-world categories (fish, fruits, colors, etc.)
    # where they'd be a poor thematic fit — general/abstract concept words
    # that don't belong to a specific everyday-life domain live here
    # instead. All 51 entries are pure 2-kanji compounds, cross-checked
    # against the rest of the 614-word dataset for kanji-string overlap
    # (zero hits) before authoring.
    "konsep_umum": [
        ("gainen", "概念", "がいねん", "gainen", "konsep", "N1", "noun", "概念", "gainen", "概念", "gainen", [
            ("この概念を理解するのは難しいです。", "Kono gainen o rikai suru no wa muzukashii desu.", "Sulit memahami konsep ini."),
        ]),
        ("keikou", "傾向", "けいこう", "keikou", "kecenderungan", "N1", "noun", "傾向", "keikou", "傾向", "keikou", [
            ("最近、若者の傾向が変わってきました。", "Saikin, wakamono no keikou ga kawatte kimashita.", "Belakangan ini, kecenderungan anak muda mulai berubah."),
        ]),
        ("yokuatsu", "抑圧", "よくあつ", "yokuatsu", "penindasan", "N1", "noun", "抑圧", "yokuatsu", "抑圧", "yokuatsu", [
            ("長年の抑圧から解放されました。", "Naganen no yokuatsu kara kaihou saremashita.", "Saya dibebaskan dari penindasan bertahun-tahun."),
        ]),
        ("haijo", "排除", "はいじょ", "haijo", "pengecualian/penyingkiran", "N1", "noun", "排除", "haijo", "排除", "haijo", [
            ("不正な行為を排除します。", "Fusei na koui o haijo shimasu.", "Kami menyingkirkan tindakan curang."),
        ]),
        ("zenin", "是認", "ぜにん", "zenin", "pengakuan/persetujuan", "N1", "noun", "是認", "zenin", "是認", "zenin", [
            ("その意見は広く是認されています。", "Sono iken wa hiroku zenin sarete imasu.", "Pendapat itu diakui secara luas."),
        ]),
        ("dashin", "打診", "だしん", "dashin", "menjajaki (secara halus)", "N1", "noun", "打診", "dashin", "打診", "dashin", [
            ("転勤の可能性を打診されました。", "Tenkin no kanousei o dashin saremashita.", "Saya ditanya secara halus soal kemungkinan pindah kerja."),
        ]),
        ("hamon", "波紋", "はもん", "hamon", "riak/dampak (kiasan)", "N1", "noun", "波紋", "hamon", "波紋", "hamon", [
            ("その発言が波紋を広げました。", "Sono hatsugen ga hamon o hirogemashita.", "Pernyataan itu menimbulkan dampak luas."),
        ]),
        ("kinkou", "均衡", "きんこう", "kinkou", "keseimbangan", "N1", "noun", "均衡", "kinkou", "均衡", "kinkou", [
            ("収入と支出の均衡を保ちます。", "Shuunyuu to shishutsu no kinkou o tamochimasu.", "Saya menjaga keseimbangan pendapatan dan pengeluaran."),
        ]),
        ("taitou", "台頭", "たいとう", "taitou", "kebangkitan (kekuatan baru)", "N1", "noun", "台頭", "taitou", "台頭", "taitou", [
            ("新しい勢力が台頭しています。", "Atarashii seiryoku ga taitou shite imasu.", "Kekuatan baru sedang bangkit."),
        ]),
        ("senzai", "潜在", "せんざい", "senzai", "potensi tersembunyi", "N1", "noun", "潜在", "senzai", "潜在", "senzai", [
            ("彼には潜在的な才能があります。", "Kare ni wa senzaiteki na sainou ga arimasu.", "Dia punya bakat tersembunyi."),
        ]),
        ("kencho", "顕著", "けんちょ", "kencho", "jelas/mencolok", "N1", "adjective", "顕著", "kencho", "顕著", "kencho", [
            ("効果が顕著に現れました。", "Kouka ga kencho ni arawaremashita.", "Efeknya terlihat jelas/mencolok."),
        ]),
        ("kinpaku", "緊迫", "きんぱく", "kinpaku", "ketegangan (situasi)", "N1", "noun", "緊迫", "kinpaku", "緊迫", "kinpaku", [
            ("現場は緊迫した状況です。", "Genba wa kinpaku shita joukyou desu.", "Situasi di lapangan sedang tegang."),
        ]),
        ("sakkaku", "錯覚", "さっかく", "sakkaku", "ilusi/salah persepsi", "N1", "noun", "錯覚", "sakkaku", "錯覚", "sakkaku", [
            ("それは目の錯覚です。", "Sore wa me no sakkaku desu.", "Itu ilusi mata."),
        ]),
        ("douin", "動員", "どういん", "douin", "mobilisasi", "N1", "noun", "動員", "douin", "動員", "douin", [
            ("多くの人が動員されました。", "Ooku no hito ga douin saremashita.", "Banyak orang dimobilisasi."),
        ]),
        ("nankou", "難航", "なんこう", "nankou", "kesulitan (proses/negosiasi)", "N1", "noun", "難航", "nankou", "難航", "nankou", [
            ("交渉は難航しています。", "Koushou wa nankou shite imasu.", "Negosiasi sedang mengalami kesulitan."),
        ]),
        ("kanshou", "干渉", "かんしょう", "kanshou", "campur tangan/interferensi", "N1", "noun", "干渉", "kanshou", "干渉", "kanshou", [
            ("他人の生活に干渉しないでください。", "Tanin no seikatsu ni kanshou shinaide kudasai.", "Tolong jangan campur tangan dalam kehidupan orang lain."),
        ]),
        ("tousei", "統制", "とうせい", "tousei", "kontrol/pengaturan (ketat)", "N1", "noun", "統制", "tousei", "統制", "tousei", [
            ("情報が統制されています。", "Jouhou ga tousei sarete imasu.", "Informasi sedang dikontrol."),
        ]),
        ("bokumetsu", "撲滅", "ぼくめつ", "bokumetsu", "pemberantasan", "N1", "noun", "撲滅", "bokumetsu", "撲滅", "bokumetsu", [
            ("この病気の撲滅を目指します。", "Kono byouki no bokumetsu o mezashimasu.", "Kami bertujuan memberantas penyakit ini."),
        ]),
        ("kokufuku", "克服", "こくふく", "kokufuku", "mengatasi (kesulitan)", "N1", "noun", "克服", "kokufuku", "克服", "kokufuku", [
            ("困難を克服しました。", "Konnan o kokufuku shimashita.", "Saya mengatasi kesulitan."),
        ]),
        ("hoshou", "補償", "ほしょう", "hoshou", "kompensasi/ganti rugi", "N1", "noun", "補償", "hoshou", "補償", "hoshou", [
            ("損害の補償を求めます。", "Songai no hoshou o motomemasu.", "Saya meminta kompensasi kerugian."),
        ]),
        ("soshi", "阻止", "そし", "soshi", "menghalangi/mencegah", "N1", "noun", "阻止", "soshi", "阻止", "soshi", [
            ("計画の実行を阻止しました。", "Keikaku no jikkou o soshi shimashita.", "Kami menghalangi pelaksanaan rencana itu."),
        ]),
        ("eikyou", "影響", "えいきょう", "eikyou", "pengaruh/dampak", "N2", "noun", "影響", "eikyou", "影響", "eikyou", [
            ("天気が体調に影響します。", "Tenki ga taichou ni eikyou shimasu.", "Cuaca berpengaruh pada kondisi tubuh."),
        ]),
        ("hatten", "発展", "はってん", "hatten", "perkembangan", "N2", "noun", "発展", "hatten", "発展", "hatten", [
            ("この地域は急速に発展しています。", "Kono chiiki wa kyuusoku ni hatten shite imasu.", "Daerah ini berkembang dengan cepat."),
        ]),
        ("handan", "判断", "はんだん", "handan", "penilaian/keputusan", "N2", "noun", "判断", "handan", "判断", "handan", [
            ("自分で判断してください。", "Jibun de handan shite kudasai.", "Tolong buat keputusan sendiri."),
        ]),
        ("souzou", "想像", "そうぞう", "souzou", "imajinasi/bayangan", "N2", "noun", "想像", "souzou", "想像", "souzou", [
            ("将来を想像してみます。", "Shourai o souzou shite mimasu.", "Saya mencoba membayangkan masa depan."),
        ]),
        ("kansha", "感謝", "かんしゃ", "kansha", "rasa terima kasih", "N2", "noun", "感謝", "kansha", "感謝", "kansha", [
            ("皆さんに感謝しています。", "Minasan ni kansha shite imasu.", "Saya berterima kasih pada semua orang."),
        ]),
        ("kitai", "期待", "きたい", "kitai", "harapan/ekspektasi", "N2", "noun", "期待", "kitai", "期待", "kitai", [
            ("あなたの成功を期待しています。", "Anata no seikou o kitai shite imasu.", "Saya berharap Anda berhasil."),
        ]),
        ("ketsudan", "決断", "けつだん", "ketsudan", "keputusan (tegas)", "N2", "noun", "決断", "ketsudan", "決断", "ketsudan", [
            ("重要な決断をしました。", "Juuyou na ketsudan o shimashita.", "Saya membuat keputusan penting."),
        ]),
        ("jitsugen", "実現", "じつげん", "jitsugen", "terwujud/realisasi", "N2", "noun", "実現", "jitsugen", "実現", "jitsugen", [
            ("夢がついに実現しました。", "Yume ga tsui ni jitsugen shimashita.", "Impian itu akhirnya terwujud."),
        ]),
        ("kouka", "効果", "こうか", "kouka", "efek/dampak", "N2", "noun", "効果", "kouka", "効果", "kouka", [
            ("この薬は効果があります。", "Kono kusuri wa kouka ga arimasu.", "Obat ini punya efek."),
        ]),
        ("gen'in", "原因", "げんいん", "gen'in", "penyebab", "N2", "noun", "原因", "gen'in", "原因", "gen'in", [
            ("事故の原因を調べます。", "Jiko no gen'in o shirabemasu.", "Kami menyelidiki penyebab kecelakaan."),
        ]),
        ("kekka", "結果", "けっか", "kekka", "hasil", "N2", "noun", "結果", "kekka", "結果", "kekka", [
            ("テストの結果が出ました。", "Tesuto no kekka ga demashita.", "Hasil tes sudah keluar."),
        ]),
        ("shuchou", "主張", "しゅちょう", "shuchou", "klaim/pendapat (tegas)", "N2", "noun", "主張", "shuchou", "主張", "shuchou", [
            ("自分の意見を主張します。", "Jibun no iken o shuchou shimasu.", "Saya menegaskan pendapat saya sendiri."),
        ]),
        ("hansei", "反省", "はんせい", "hansei", "introspeksi/refleksi diri", "N2", "noun", "反省", "hansei", "反省", "hansei", [
            ("自分の行動を反省します。", "Jibun no koudou o hansei shimasu.", "Saya merefleksikan tindakan saya sendiri."),
        ]),
        ("rikai", "理解", "りかい", "rikai", "pemahaman", "N2", "noun", "理解", "rikai", "理解", "rikai", [
            ("その説明で理解できました。", "Sono setsumei de rikai dekimashita.", "Saya jadi paham dengan penjelasan itu."),
        ]),
        ("gokai", "誤解", "ごかい", "gokai", "kesalahpahaman", "N2", "noun", "誤解", "gokai", "誤解", "gokai", [
            ("誤解を解きたいです。", "Gokai o tokitai desu.", "Saya ingin meluruskan kesalahpahaman."),
        ]),
        ("taiou", "対応", "たいおう", "taiou", "respons/penanganan", "N2", "noun", "対応", "taiou", "対応", "taiou", [
            ("迅速に対応します。", "Jinsoku ni taiou shimasu.", "Kami merespons dengan cepat."),
        ]),
        ("taisaku", "対策", "たいさく", "taisaku", "langkah penanggulangan", "N2", "noun", "対策", "taisaku", "対策", "taisaku", [
            ("台風の対策をします。", "Taifuu no taisaku o shimasu.", "Kami menyiapkan langkah penanggulangan topan."),
        ]),
        ("kentou", "検討", "けんとう", "kentou", "pertimbangan/kajian", "N2", "noun", "検討", "kentou", "検討", "kentou", [
            ("その案を検討しています。", "Sono an o kentou shite imasu.", "Kami sedang mempertimbangkan usulan itu."),
        ]),
        ("kaizen", "改善", "かいぜん", "kaizen", "perbaikan", "N2", "noun", "改善", "kaizen", "改善", "kaizen", [
            ("サービスを改善します。", "Saabisu o kaizen shimasu.", "Kami memperbaiki layanan."),
        ]),
        ("hyouka", "評価", "ひょうか", "hyouka", "penilaian/evaluasi", "N2", "noun", "評価", "hyouka", "評価", "hyouka", [
            ("彼の仕事は高く評価されています。", "Kare no shigoto wa takaku hyouka sarete imasu.", "Pekerjaannya dinilai tinggi."),
        ]),
        ("sanka", "参加", "さんか", "sanka", "partisipasi", "N3", "noun", "参加", "sanka", "参加", "sanka", [
            ("パーティーに参加します。", "Paatii ni sanka shimasu.", "Saya berpartisipasi dalam pesta."),
        ]),
        ("junbi", "準備", "じゅんび", "junbi", "persiapan", "N3", "noun", "準備", "junbi", "準備", "junbi", [
            ("旅行の準備をします。", "Ryokou no junbi o shimasu.", "Saya mempersiapkan perjalanan."),
        ]),
        ("setsumei", "説明", "せつめい", "setsumei", "penjelasan", "N3", "noun", "説明", "setsumei", "説明", "setsumei", [
            ("詳しく説明してください。", "Kuwashiku setsumei shite kudasai.", "Tolong jelaskan secara rinci."),
        ]),
        ("shitsumon", "質問", "しつもん", "shitsumon", "pertanyaan", "N3", "noun", "質問", "shitsumon", "質問", "shitsumon", [
            ("質問があります。", "Shitsumon ga arimasu.", "Saya punya pertanyaan."),
        ]),
        ("renshuu", "練習", "れんしゅう", "renshuu", "latihan", "N3", "noun", "練習", "renshuu", "練習", "renshuu", [
            ("毎日ピアノを練習します。", "Mainichi piano o renshuu shimasu.", "Saya berlatih piano setiap hari."),
        ]),
        ("seikou", "成功", "せいこう", "seikou", "keberhasilan", "N3", "noun", "成功", "seikou", "成功", "seikou", [
            ("プロジェクトが成功しました。", "Purojekuto ga seikou shimashita.", "Proyek itu berhasil."),
        ]),
        ("shippai", "失敗", "しっぱい", "shippai", "kegagalan", "N3", "noun", "失敗", "shippai", "失敗", "shippai", [
            ("実験は失敗しました。", "Jikken wa shippai shimashita.", "Eksperimen itu gagal."),
        ]),
        ("keiken", "経験", "けいけん", "keiken", "pengalaman", "N3", "noun", "経験", "keiken", "経験", "keiken", [
            ("貴重な経験をしました。", "Kichou na keiken o shimashita.", "Saya mendapat pengalaman berharga."),
        ]),
        ("yotei", "予定", "よてい", "yotei", "rencana/jadwal", "N3", "noun", "予定", "yotei", "予定", "yotei", [
            ("明日の予定を確認します。", "Ashita no yotei o kakunin shimasu.", "Saya memeriksa jadwal besok."),
        ]),
        ("tsugou", "都合", "つごう", "tsugou", "keadaan/kenyamanan (waktu)", "N3", "noun", "都合", "tsugou", "都合", "tsugou", [
            ("都合がいい時間を教えてください。", "Tsugou ga ii jikan o oshiete kudasai.", "Tolong beri tahu waktu yang cocok untuk Anda."),
        ]),
        # Second addition (2026-07-20, seventh batch): another 46 pure
        # 2-kanji general nouns, this time spanning legal/administrative,
        # economics/finance, psychology/cognition, politics/society, and
        # communication vocabulary — same rule as the first 51: nothing
        # here is tied to a specific real-world domain the other 45
        # categories already cover. Cross-checked against the whole
        # dataset for kanji-string overlap before authoring (zero hits).
        ("kenri", "権利", "けんり", "kenri", "hak", "N3", "noun", "権利", "kenri", "権利", "kenri", [
            ("自由に発言する権利があります。", "Jiyuu ni hatsugen suru kenri ga arimasu.", "Ada hak untuk berbicara bebas."),
        ]),
        ("gimu", "義務", "ぎむ", "gimu", "kewajiban", "N3", "noun", "義務", "gimu", "義務", "gimu", [
            ("税金を払う義務があります。", "Zeikin o harau gimu ga arimasu.", "Ada kewajiban membayar pajak."),
        ]),
        ("keiyaku", "契約", "けいやく", "keiyaku", "kontrak", "N3", "noun", "契約", "keiyaku", "契約", "keiyaku", [
            ("契約を結びました。", "Keiyaku o musubimashita.", "Kami membuat kontrak."),
        ]),
        ("kisoku", "規則", "きそく", "kisoku", "peraturan", "N3", "noun", "規則", "kisoku", "規則", "kisoku", [
            ("学校の規則を守ります。", "Gakkou no kisoku o mamorimasu.", "Saya mematuhi peraturan sekolah."),
        ]),
        ("ihan", "違反", "いはん", "ihan", "pelanggaran", "N2", "noun", "違反", "ihan", "違反", "ihan", [
            ("交通違反をしました。", "Koutsuu ihan o shimashita.", "Saya melakukan pelanggaran lalu lintas."),
        ]),
        ("bakkin", "罰金", "ばっきん", "bakkin", "denda", "N2", "noun", "罰金", "bakkin", "罰金", "bakkin", [
            ("罰金を払いました。", "Bakkin o haraimashita.", "Saya membayar denda."),
        ]),
        ("soshou", "訴訟", "そしょう", "soshou", "tuntutan hukum/litigasi", "N1", "noun", "訴訟", "soshou", "訴訟", "soshou", [
            ("その件で訴訟を起こしました。", "Sono ken de soshou o okoshimashita.", "Saya mengajukan tuntutan hukum atas kasus itu."),
        ]),
        ("saiban", "裁判", "さいばん", "saiban", "persidangan", "N2", "noun", "裁判", "saiban", "裁判", "saiban", [
            ("裁判が始まりました。", "Saiban ga hajimarimashita.", "Persidangan telah dimulai."),
        ]),
        ("bensai", "弁済", "べんさい", "bensai", "pelunasan (utang)", "N1", "noun", "弁済", "bensai", "弁済", "bensai", [
            ("借金を弁済しました。", "Shakkin o bensai shimashita.", "Saya melunasi utang."),
        ]),
        ("juyou", "需要", "じゅよう", "juyou", "permintaan (ekonomi)", "N2", "noun", "需要", "juyou", "需要", "juyou", [
            ("この商品は需要が高いです。", "Kono shouhin wa juyou ga takai desu.", "Produk ini permintaannya tinggi."),
        ]),
        ("kyoukyuu", "供給", "きょうきゅう", "kyoukyuu", "penawaran/pasokan (ekonomi)", "N2", "noun", "供給", "kyoukyuu", "供給", "kyoukyuu", [
            ("電力を供給します。", "Denryoku o kyoukyuu shimasu.", "Kami menyediakan pasokan listrik."),
        ]),
        ("shouhi", "消費", "しょうひ", "shouhi", "konsumsi", "N3", "noun", "消費", "shouhi", "消費", "shouhi", [
            ("電気を消費します。", "Denki o shouhi shimasu.", "Kami mengonsumsi listrik."),
        ]),
        ("chochiku", "貯蓄", "ちょちく", "chochiku", "tabungan", "N2", "noun", "貯蓄", "chochiku", "貯蓄", "chochiku", [
            ("将来のために貯蓄します。", "Shourai no tame ni chochiku shimasu.", "Saya menabung untuk masa depan."),
        ]),
        ("toushi", "投資", "とうし", "toushi", "investasi", "N3", "noun", "投資", "toushi", "投資", "toushi", [
            ("株に投資しました。", "Kabu ni toushi shimashita.", "Saya berinvestasi saham."),
        ]),
        ("fusai", "負債", "ふさい", "fusai", "utang/kewajiban finansial", "N1", "noun", "負債", "fusai", "負債", "fusai", [
            ("会社は多額の負債を抱えています。", "Kaisha wa tagaku no fusai o kakaete imasu.", "Perusahaan itu menanggung utang besar."),
        ]),
        ("shisan", "資産", "しさん", "shisan", "aset/kekayaan", "N2", "noun", "資産", "shisan", "資産", "shisan", [
            ("資産を管理します。", "Shisan o kanri shimasu.", "Saya mengelola aset."),
        ]),
        ("keiki", "景気", "けいき", "keiki", "kondisi ekonomi", "N2", "noun", "景気", "keiki", "景気", "keiki", [
            ("景気が回復しています。", "Keiki ga kaifuku shite imasu.", "Kondisi ekonomi sedang membaik."),
        ]),
        ("bukka", "物価", "ぶっか", "bukka", "harga barang (umum)", "N3", "noun", "物価", "bukka", "物価", "bukka", [
            ("物価が上がりました。", "Bukka ga agarimashita.", "Harga barang naik."),
        ]),
        ("kawase", "為替", "かわせ", "kawase", "nilai tukar", "N1", "noun", "為替", "kawase", "為替", "kawase", [
            ("為替レートが変動しています。", "Kawase reeto ga hendou shite imasu.", "Kurs nilai tukar sedang berfluktuasi."),
        ]),
        ("ishiki", "意識", "いしき", "ishiki", "kesadaran", "N2", "noun", "意識", "ishiki", "意識", "ishiki", [
            ("環境問題への意識が高まっています。", "Kankyou mondai e no ishiki ga takamatte imasu.", "Kesadaran akan isu lingkungan meningkat."),
        ]),
        ("muishiki", "無意識", "むいしき", "muishiki", "ketidaksadaran", "N1", "noun", "無意識", "muishiki", "無意識", "muishiki", [
            ("無意識にそう言ってしまいました。", "Muishiki ni sou itte shimaimashita.", "Saya mengatakannya tanpa sadar."),
        ]),
        ("kioku", "記憶", "きおく", "kioku", "ingatan", "N3", "noun", "記憶", "kioku", "記憶", "kioku", [
            ("その日の記憶が鮮明です。", "Sono hi no kioku ga senmei desu.", "Ingatan hari itu masih jelas."),
        ]),
        ("ninshiki", "認識", "にんしき", "ninshiki", "pengenalan/kesadaran akan sesuatu", "N2", "noun", "認識", "ninshiki", "認識", "ninshiki", [
            ("問題を認識しています。", "Mondai o ninshiki shite imasu.", "Saya menyadari masalahnya."),
        ]),
        ("chokkan", "直感", "ちょっかん", "chokkan", "intuisi", "N1", "noun", "直感", "chokkan", "直感", "chokkan", [
            ("直感で決めました。", "Chokkan de kimemashita.", "Saya memutuskan dengan intuisi."),
        ]),
        ("honnou", "本能", "ほんのう", "honnou", "insting", "N1", "noun", "本能", "honnou", "本能", "honnou", [
            ("動物の本能です。", "Doubutsu no honnou desu.", "Itu insting hewan."),
        ]),
        ("iyoku", "意欲", "いよく", "iyoku", "motivasi/semangat", "N2", "noun", "意欲", "iyoku", "意欲", "iyoku", [
            ("仕事への意欲が湧いてきました。", "Shigoto e no iyoku ga waite kimashita.", "Motivasi untuk bekerja mulai muncul."),
        ]),
        ("shoudou", "衝動", "しょうどう", "shoudou", "impuls/dorongan", "N1", "noun", "衝動", "shoudou", "衝動", "shoudou", [
            ("衝動買いをしてしまいました。", "Shoudougai o shite shimaimashita.", "Saya jadi belanja secara impulsif."),
        ]),
        ("seisaku", "政策", "せいさく", "seisaku", "kebijakan", "N2", "noun", "政策", "seisaku", "政策", "seisaku", [
            ("新しい政策が発表されました。", "Atarashii seisaku ga happyou saremashita.", "Kebijakan baru telah diumumkan."),
        ]),
        ("seido", "制度", "せいど", "seido", "sistem/institusi", "N2", "noun", "制度", "seido", "制度", "seido", [
            ("この制度は複雑です。", "Kono seido wa fukuzatsu desu.", "Sistem ini rumit."),
        ]),
        ("senkyo", "選挙", "せんきょ", "senkyo", "pemilu", "N3", "noun", "選挙", "senkyo", "選挙", "senkyo", [
            ("来月選挙があります。", "Raigetsu senkyo ga arimasu.", "Bulan depan ada pemilu."),
        ]),
        ("kenryoku", "権力", "けんりょく", "kenryoku", "kekuasaan", "N2", "noun", "権力", "kenryoku", "権力", "kenryoku", [
            ("権力を乱用しないでください。", "Kenryoku o ran'you shinaide kudasai.", "Tolong jangan menyalahgunakan kekuasaan."),
        ]),
        ("byoudou", "平等", "びょうどう", "byoudou", "kesetaraan", "N3", "noun", "平等", "byoudou", "平等", "byoudou", [
            ("みんな平等であるべきです。", "Minna byoudou de aru beki desu.", "Semua orang seharusnya setara."),
        ]),
        ("kakusa", "格差", "かくさ", "kakusa", "kesenjangan (sosial/ekonomi)", "N1", "noun", "格差", "kakusa", "格差", "kakusa", [
            ("経済格差が広がっています。", "Keizai kakusa ga hirogatte imasu.", "Kesenjangan ekonomi semakin melebar."),
        ]),
        ("sabetsu", "差別", "さべつ", "sabetsu", "diskriminasi", "N2", "noun", "差別", "sabetsu", "差別", "sabetsu", [
            ("差別をなくしたいです。", "Sabetsu o nakushitai desu.", "Saya ingin menghapuskan diskriminasi."),
        ]),
        ("hyougen", "表現", "ひょうげん", "hyougen", "ekspresi/ungkapan", "N3", "noun", "表現", "hyougen", "表現", "hyougen", [
            ("自分の気持ちを表現します。", "Jibun no kimochi o hyougen shimasu.", "Saya mengekspresikan perasaan saya sendiri."),
        ]),
        ("hatsugen", "発言", "はつげん", "hatsugen", "pernyataan/ucapan", "N2", "noun", "発言", "hatsugen", "発言", "hatsugen", [
            ("その発言に驚きました。", "Sono hatsugen ni odorokimashita.", "Saya terkejut dengan pernyataan itu."),
        ]),
        ("giron", "議論", "ぎろん", "giron", "diskusi/perdebatan", "N3", "noun", "議論", "giron", "議論", "giron", [
            ("その問題について議論します。", "Sono mondai ni tsuite giron shimasu.", "Kami mendiskusikan masalah itu."),
        ]),
        ("ito", "意図", "いと", "ito", "maksud/niat", "N2", "noun", "意図", "ito", "意図", "ito", [
            ("彼の意図が分かりません。", "Kare no ito ga wakarimasen.", "Saya tidak paham maksudnya."),
        ]),
        ("aimai", "曖昧", "あいまい", "aimai", "ambigu/samar", "N3", "adjective", "曖昧", "aimai", "曖昧", "aimai", [
            ("曖昧な返事をしました。", "Aimai na henji o shimashita.", "Saya memberi jawaban yang ambigu."),
        ]),
        ("shinpo", "進歩", "しんぽ", "shinpo", "kemajuan", "N3", "noun", "進歩", "shinpo", "進歩", "shinpo", [
            ("技術が進歩しました。", "Gijutsu ga shinpo shimashita.", "Teknologi mengalami kemajuan."),
        ]),
        ("junkan", "循環", "じゅんかん", "junkan", "siklus/sirkulasi", "N2", "noun", "循環", "junkan", "循環", "junkan", [
            ("血液が循環します。", "Ketsueki ga junkan shimasu.", "Darah bersirkulasi."),
        ]),
        ("jizoku", "持続", "じぞく", "jizoku", "keberlanjutan", "N2", "noun", "持続", "jizoku", "持続", "jizoku", [
            ("効果が持続します。", "Kouka ga jizoku shimasu.", "Efeknya berlangsung terus."),
        ]),
        ("iji", "維持", "いじ", "iji", "pemeliharaan/menjaga", "N2", "noun", "維持", "iji", "維持", "iji", [
            ("健康を維持します。", "Kenkou o iji shimasu.", "Saya menjaga kesehatan."),
        ]),
        ("tekiou", "適応", "てきおう", "tekiou", "adaptasi", "N2", "noun", "適応", "tekiou", "適応", "tekiou", [
            ("新しい環境に適応します。", "Atarashii kankyou ni tekiou shimasu.", "Saya beradaptasi dengan lingkungan baru."),
        ]),
        ("houritsu", "法律", "ほうりつ", "houritsu", "hukum/undang-undang", "N4", "noun", "法律", "houritsu", "法律", "houritsu", [
            ("法律を守ります。", "Houritsu o mamorimasu.", "Saya mematuhi hukum."),
        ]),
        ("henka", "変化", "へんか", "henka", "perubahan", "N3", "noun", "変化", "henka", "変化", "henka", [
            ("季節の変化を感じます。", "Kisetsu no henka o kanjimasu.", "Saya merasakan perubahan musim."),
        ]),
        # Third addition (2026-07-20, eighth batch): 39 more pure 2-kanji
        # general nouns — science/method, human development, communication/
        # reasoning, process/degree, environment, learning, and
        # interpersonal-dynamics vocabulary, none overlapping the other
        # 750 words in the dataset (checked before authoring, including a
        # reading-collision check against konsep_umum's own existing
        # entries specifically, since e.g. 契機/keiki would have collided
        # with the already-added 景気/keiki — dropped for that reason).
        ("genshou", "現象", "げんしょう", "genshou", "fenomena", "N2", "noun", "現象", "genshou", "現象", "genshou", [
            ("これは自然現象です。", "Kore wa shizen genshou desu.", "Ini adalah fenomena alam."),
        ]),
        ("genri", "原理", "げんり", "genri", "prinsip (ilmiah)", "N1", "noun", "原理", "genri", "原理", "genri", [
            ("この機械の原理を説明します。", "Kono kikai no genri o setsumei shimasu.", "Saya menjelaskan prinsip kerja mesin ini."),
        ]),
        ("housoku", "法則", "ほうそく", "housoku", "hukum (alam/ilmiah)", "N1", "noun", "法則", "housoku", "法則", "housoku", [
            ("自然の法則には逆らえません。", "Shizen no housoku ni wa sakaraemasen.", "Tidak bisa melawan hukum alam."),
        ]),
        ("jikken", "実験", "じっけん", "jikken", "eksperimen", "N3", "noun", "実験", "jikken", "実験", "jikken", [
            ("新しい実験を行います。", "Atarashii jikken o okonaimasu.", "Kami melakukan eksperimen baru."),
        ]),
        ("kansatsu", "観察", "かんさつ", "kansatsu", "pengamatan", "N2", "noun", "観察", "kansatsu", "観察", "kansatsu", [
            ("植物の成長を観察します。", "Shokubutsu no seichou o kansatsu shimasu.", "Saya mengamati pertumbuhan tanaman."),
        ]),
        ("bunseki", "分析", "ぶんせき", "bunseki", "analisis", "N2", "noun", "分析", "bunseki", "分析", "bunseki", [
            ("データを分析します。", "Deeta o bunseki shimasu.", "Saya menganalisis data."),
        ]),
        ("kenshou", "検証", "けんしょう", "kenshou", "verifikasi", "N1", "noun", "検証", "kenshou", "検証", "kenshou", [
            ("仮説を検証します。", "Kasetsu o kenshou shimasu.", "Kami memverifikasi hipotesis."),
        ]),
        ("shoumei", "証明", "しょうめい", "shoumei", "pembuktian", "N2", "noun", "証明", "shoumei", "証明", "shoumei", [
            ("自分の無実を証明します。", "Jibun no mujitsu o shoumei shimasu.", "Saya membuktikan ketidakbersalahan saya sendiri."),
        ]),
        ("seichou", "成長", "せいちょう", "seichou", "pertumbuhan", "N3", "noun", "成長", "seichou", "成長", "seichou", [
            ("子供の成長は早いです。", "Kodomo no seichou wa hayai desu.", "Pertumbuhan anak itu cepat."),
        ]),
        ("hattatsu", "発達", "はったつ", "hattatsu", "perkembangan (anak/kemampuan)", "N2", "noun", "発達", "hattatsu", "発達", "hattatsu", [
            ("科学技術が発達しました。", "Kagaku gijutsu ga hattatsu shimashita.", "Teknologi sains berkembang."),
        ]),
        ("seijuku", "成熟", "せいじゅく", "seijuku", "kematangan/kedewasaan", "N1", "noun", "成熟", "seijuku", "成熟", "seijuku", [
            ("考え方が成熟してきました。", "Kangaekata ga seijuku shite kimashita.", "Cara berpikirnya mulai matang."),
        ]),
        ("koujou", "向上", "こうじょう", "koujou", "peningkatan (kemampuan)", "N2", "noun", "向上", "koujou", "向上", "koujou", [
            ("技術の向上を目指します。", "Gijutsu no koujou o mezashimasu.", "Kami bertujuan meningkatkan keterampilan."),
        ]),
        ("shukan", "主観", "しゅかん", "shukan", "subjektivitas", "N1", "noun", "主観", "shukan", "主観", "shukan", [
            ("それはあなたの主観です。", "Sore wa anata no shukan desu.", "Itu subjektivitas Anda sendiri."),
        ]),
        ("kyakkan", "客観", "きゃっかん", "kyakkan", "objektivitas", "N1", "noun", "客観", "kyakkan", "客観", "kyakkan", [
            ("客観的に見てください。", "Kyakkanteki ni mite kudasai.", "Tolong lihat secara objektif."),
        ]),
        ("kenkai", "見解", "けんかい", "kenkai", "pandangan/opini (formal)", "N1", "noun", "見解", "kenkai", "見解", "kenkai", [
            ("専門家の見解を聞きます。", "Senmonka no kenkai o kikimasu.", "Saya mendengar pandangan dari ahli."),
        ]),
        ("ronri", "論理", "ろんり", "ronri", "logika", "N2", "noun", "論理", "ronri", "論理", "ronri", [
            ("彼の論理は分かりやすいです。", "Kare no ronri wa wakariyasui desu.", "Logikanya mudah dipahami."),
        ]),
        ("mujun", "矛盾", "むじゅん", "mujun", "kontradiksi", "N1", "noun", "矛盾", "mujun", "矛盾", "mujun", [
            ("その説明には矛盾があります。", "Sono setsumei ni wa mujun ga arimasu.", "Penjelasan itu mengandung kontradiksi."),
        ]),
        ("katei", "過程", "かてい", "katei", "proses", "N2", "noun", "過程", "katei", "過程", "katei", [
            ("成功までの過程が大事です。", "Seikou made no katei ga daiji desu.", "Proses menuju keberhasilan itu penting."),
        ]),
        ("dankai", "段階", "だんかい", "dankai", "tahap", "N2", "noun", "段階", "dankai", "段階", "dankai", [
            ("計画は次の段階に進みました。", "Keikaku wa tsugi no dankai ni susumimashita.", "Rencana itu maju ke tahap berikutnya."),
        ]),
        ("keika", "経過", "けいか", "keika", "berlalunya waktu/perkembangan", "N2", "noun", "経過", "keika", "経過", "keika", [
            ("手術後の経過は順調です。", "Shujutsu-go no keika wa junchou desu.", "Perkembangan pascaoperasi berjalan lancar."),
        ]),
        ("keizoku", "継続", "けいぞく", "keizoku", "kelanjutan", "N2", "noun", "継続", "keizoku", "継続", "keizoku", [
            ("この活動を継続します。", "Kono katsudou o keizoku shimasu.", "Kami melanjutkan kegiatan ini."),
        ]),
        ("teido", "程度", "ていど", "teido", "tingkat/derajat", "N3", "noun", "程度", "teido", "程度", "teido", [
            ("ある程度は理解しています。", "Aru teido wa rikai shite imasu.", "Saya memahami sampai tingkat tertentu."),
        ]),
        ("wariai", "割合", "わりあい", "wariai", "proporsi/rasio", "N2", "noun", "割合", "wariai", "割合", "wariai", [
            ("賛成の割合が増えました。", "Sansei no wariai ga fuemashita.", "Proporsi yang setuju meningkat."),
        ]),
        ("hikaku", "比較", "ひかく", "hikaku", "perbandingan", "N3", "noun", "比較", "hikaku", "比較", "hikaku", [
            ("二つの商品を比較します。", "Futatsu no shouhin o hikaku shimasu.", "Saya membandingkan dua produk."),
        ]),
        ("hindo", "頻度", "ひんど", "hindo", "frekuensi", "N1", "noun", "頻度", "hindo", "頻度", "hindo", [
            ("会議の頻度が増えました。", "Kaigi no hindo ga fuemashita.", "Frekuensi rapat meningkat."),
        ]),
        ("kankyou", "環境", "かんきょう", "kankyou", "lingkungan", "N4", "noun", "環境", "kankyou", "環境", "kankyou", [
            ("自然環境を守ります。", "Shizen kankyou o mamorimasu.", "Kami menjaga lingkungan alam."),
        ]),
        ("osen", "汚染", "おせん", "osen", "polusi/pencemaran", "N2", "noun", "汚染", "osen", "汚染", "osen", [
            ("海の汚染が深刻です。", "Umi no osen ga shinkoku desu.", "Pencemaran laut sangat serius."),
        ]),
        ("hogo", "保護", "ほご", "hogo", "perlindungan", "N3", "noun", "保護", "hogo", "保護", "hogo", [
            ("動物を保護します。", "Doubutsu o hogo shimasu.", "Kami melindungi hewan."),
        ]),
        ("shigen", "資源", "しげん", "shigen", "sumber daya", "N2", "noun", "資源", "shigen", "資源", "shigen", [
            ("資源を大切に使います。", "Shigen o taisetsu ni tsukaimasu.", "Kami menggunakan sumber daya dengan hati-hati."),
        ]),
        ("setsuyaku", "節約", "せつやく", "setsuyaku", "penghematan", "N3", "noun", "節約", "setsuyaku", "節約", "setsuyaku", [
            ("電気を節約します。", "Denki o setsuyaku shimasu.", "Kami menghemat listrik."),
        ]),
        ("kyouyou", "教養", "きょうよう", "kyouyou", "wawasan/pengetahuan umum (budaya)", "N1", "noun", "教養", "kyouyou", "教養", "kyouyou", [
            ("教養を身につけます。", "Kyouyou o mi ni tsukemasu.", "Saya menambah wawasan."),
        ]),
        ("chishiki", "知識", "ちしき", "chishiki", "pengetahuan", "N3", "noun", "知識", "chishiki", "知識", "chishiki", [
            ("専門知識が必要です。", "Senmon chishiki ga hitsuyou desu.", "Diperlukan pengetahuan khusus."),
        ]),
        ("shuutoku", "習得", "しゅうとく", "shuutoku", "penguasaan (keterampilan)", "N1", "noun", "習得", "shuutoku", "習得", "shuutoku", [
            ("新しい技術を習得します。", "Atarashii gijutsu o shuutoku shimasu.", "Saya menguasai teknologi baru."),
        ]),
        ("kyoukun", "教訓", "きょうくん", "kyoukun", "pelajaran (hikmah)", "N2", "noun", "教訓", "kyoukun", "教訓", "kyoukun", [
            ("失敗から教訓を得ました。", "Shippai kara kyoukun o emashita.", "Saya mendapat pelajaran dari kegagalan."),
        ]),
        ("shinrai", "信頼", "しんらい", "shinrai", "kepercayaan", "N3", "noun", "信頼", "shinrai", "信頼", "shinrai", [
            ("彼を信頼しています。", "Kare o shinrai shite imasu.", "Saya mempercayainya."),
        ]),
        ("kyouryoku", "協力", "きょうりょく", "kyouryoku", "kerja sama", "N3", "noun", "協力", "kyouryoku", "協力", "kyouryoku", [
            ("皆で協力します。", "Minna de kyouryoku shimasu.", "Kita semua bekerja sama."),
        ]),
        ("tairitsu", "対立", "たいりつ", "tairitsu", "konflik/pertentangan", "N2", "noun", "対立", "tairitsu", "対立", "tairitsu", [
            ("意見の対立がありました。", "Iken no tairitsu ga arimashita.", "Ada perbedaan pendapat yang bertentangan."),
        ]),
        ("renkei", "連携", "れんけい", "renkei", "kolaborasi/koordinasi", "N1", "noun", "連携", "renkei", "連携", "renkei", [
            ("他部署と連携します。", "Ta busho to renkei shimasu.", "Kami berkoordinasi dengan departemen lain."),
        ]),
        ("kouryuu", "交流", "こうりゅう", "kouryuu", "pertukaran/interaksi", "N3", "noun", "交流", "kouryuu", "交流", "kouryuu", [
            ("異文化交流をします。", "Ibunka kouryuu o shimasu.", "Kami melakukan pertukaran budaya."),
        ]),
        # Fourth addition (2026-07-20, ninth batch): 32 more pure 2-3 kanji
        # general nouns — safety/risk, quality/value assessment, change/
        # transformation, necessity/possibility, achievement, rhetoric, and
        # emotion vocabulary, none overlapping the other 750+ words in the
        # dataset and no reading collisions within konsep_umum itself
        # (checked before authoring, same discipline as the eighth batch's
        # 契機/景気 catch).
        ("anzen", "安全", "あんぜん", "anzen", "keamanan", "N4", "noun", "安全", "anzen", "安全", "anzen", [
            ("安全を確認します。", "Anzen o kakunin shimasu.", "Saya memastikan keamanannya."),
        ]),
        ("keikai", "警戒", "けいかい", "keikai", "kewaspadaan", "N1", "noun", "警戒", "keikai", "警戒", "keikai", [
            ("警戒を強めます。", "Keikai o tsuyomemasu.", "Kami memperketat kewaspadaan."),
        ]),
        ("boushi2", "防止", "ぼうし", "boushi", "pencegahan", "N2", "noun", "防止", "boushi", "防止", "boushi", [
            ("事故防止に努めます。", "Jiko boushi ni tsutomemasu.", "Kami berupaya mencegah kecelakaan."),
        ]),
        ("kiki", "危機", "きき", "kiki", "krisis", "N2", "noun", "危機", "kiki", "危機", "kiki", [
            ("経済危機が起こりました。", "Keizai kiki ga okorimashita.", "Terjadi krisis ekonomi."),
        ]),
        ("chian", "治安", "ちあん", "chian", "keamanan masyarakat", "N1", "noun", "治安", "chian", "治安", "chian", [
            ("この町は治安がいいです。", "Kono machi wa chian ga ii desu.", "Keamanan di kota ini bagus."),
        ]),
        ("hinshitsu", "品質", "ひんしつ", "hinshitsu", "kualitas (barang)", "N2", "noun", "品質", "hinshitsu", "品質", "hinshitsu", [
            ("品質を管理します。", "Hinshitsu o kanri shimasu.", "Kami mengelola kualitas."),
        ]),
        ("kachi", "価値", "かち", "kachi", "nilai", "N3", "noun", "価値", "kachi", "価値", "kachi", [
            ("この本には価値があります。", "Kono hon ni wa kachi ga arimasu.", "Buku ini memiliki nilai."),
        ]),
        ("kijun", "基準", "きじゅん", "kijun", "standar/kriteria", "N2", "noun", "基準", "kijun", "基準", "kijun", [
            ("評価の基準を決めます。", "Hyouka no kijun o kimemasu.", "Kami menentukan kriteria penilaian."),
        ]),
        ("suijun", "水準", "すいじゅん", "suijun", "tingkat/standar (mutu)", "N1", "noun", "水準", "suijun", "水準", "suijun", [
            ("生活水準が上がりました。", "Seikatsu suijun ga agarimashita.", "Standar hidup meningkat."),
        ]),
        ("shinraisei", "信頼性", "しんらいせい", "shinraisei", "keandalan/reliabilitas", "N1", "noun", "信頼性", "shinraisei", "信頼性", "shinraisei", [
            ("データの信頼性を確認します。", "Deeta no shinraisei o kakunin shimasu.", "Saya memastikan keandalan data."),
        ]),
        ("henkaku", "変革", "へんかく", "henkaku", "reformasi/perubahan besar", "N1", "noun", "変革", "henkaku", "変革", "henkaku", [
            ("組織の変革を進めます。", "Soshiki no henkaku o susumemasu.", "Kami melanjutkan reformasi organisasi."),
        ]),
        ("tenkan", "転換", "てんかん", "tenkan", "peralihan/konversi", "N1", "noun", "転換", "tenkan", "転換", "tenkan", [
            ("方針を転換します。", "Houshin o tenkan shimasu.", "Kami mengalihkan kebijakan."),
        ]),
        ("kaikaku", "改革", "かいかく", "kaikaku", "reformasi", "N2", "noun", "改革", "kaikaku", "改革", "kaikaku", [
            ("教育改革が行われました。", "Kyouiku kaikaku ga okonawaremashita.", "Reformasi pendidikan dilaksanakan."),
        ]),
        ("kakumei", "革命", "かくめい", "kakumei", "revolusi", "N2", "noun", "革命", "kakumei", "革命", "kakumei", [
            ("技術革命が起こりました。", "Gijutsu kakumei ga okorimashita.", "Terjadi revolusi teknologi."),
        ]),
        ("yochi", "余地", "よち", "yochi", "ruang (untuk kemungkinan)", "N1", "noun", "余地", "yochi", "余地", "yochi", [
            ("改善の余地があります。", "Kaizen no yochi ga arimasu.", "Masih ada ruang untuk perbaikan."),
        ]),
        ("fukaketsu", "不可欠", "ふかけつ", "fukaketsu", "esensial/tak tergantikan", "N1", "adjective", "不可欠", "fukaketsu", "不可欠", "fukaketsu", [
            ("水は生活に不可欠です。", "Mizu wa seikatsu ni fukaketsu desu.", "Air esensial untuk kehidupan."),
        ]),
        ("tassei", "達成", "たっせい", "tassei", "pencapaian", "N2", "noun", "達成", "tassei", "達成", "tassei", [
            ("目標を達成しました。", "Mokuhyou o tassei shimashita.", "Saya mencapai target."),
        ]),
        ("toutatsu", "到達", "とうたつ", "toutatsu", "mencapai (tujuan)", "N2", "noun", "到達", "toutatsu", "到達", "toutatsu", [
            ("頂上に到達しました。", "Choujou ni toutatsu shimashita.", "Kami mencapai puncak."),
        ]),
        ("kakutoku", "獲得", "かくとく", "kakutoku", "memperoleh/meraih", "N2", "noun", "獲得", "kakutoku", "獲得", "kakutoku", [
            ("金メダルを獲得しました。", "Kin medaru o kakutoku shimashita.", "Saya meraih medali emas."),
        ]),
        ("settoku", "説得", "せっとく", "settoku", "persuasi", "N2", "noun", "説得", "settoku", "説得", "settoku", [
            ("彼を説得しました。", "Kare o settoku shimashita.", "Saya membujuknya."),
        ]),
        ("hanron", "反論", "はんろん", "hanron", "sanggahan/bantahan", "N1", "noun", "反論", "hanron", "反論", "hanron", [
            ("彼の意見に反論します。", "Kare no iken ni hanron shimasu.", "Saya menyanggah pendapatnya."),
        ]),
        ("kyouchou", "強調", "きょうちょう", "kyouchou", "penekanan (dalam bicara)", "N2", "noun", "強調", "kyouchou", "強調", "kyouchou", [
            ("重要性を強調します。", "Juuyousei o kyouchou shimasu.", "Saya menekankan pentingnya hal itu."),
        ]),
        ("anji", "暗示", "あんじ", "anji", "isyarat/sugesti", "N1", "noun", "暗示", "anji", "暗示", "anji", [
            ("彼の言葉には暗示がありました。", "Kare no kotoba ni wa anji ga arimashita.", "Kata-katanya mengandung sugesti."),
        ]),
        ("zetsubou", "絶望", "ぜつぼう", "zetsubou", "keputusasaan", "N2", "noun", "絶望", "zetsubou", "絶望", "zetsubou", [
            ("彼は絶望していました。", "Kare wa zetsubou shite imashita.", "Dia sedang putus asa."),
        ]),
        ("kibou", "希望", "きぼう", "kibou", "harapan", "N3", "noun", "希望", "kibou", "希望", "kibou", [
            ("将来に希望を持っています。", "Shourai ni kibou o motte imasu.", "Saya memiliki harapan untuk masa depan."),
        ]),
        ("manzoku", "満足", "まんぞく", "manzoku", "kepuasan", "N3", "noun", "満足", "manzoku", "満足", "manzoku", [
            ("結果に満足しています。", "Kekka ni manzoku shite imasu.", "Saya puas dengan hasilnya."),
        ]),
        ("fuman", "不満", "ふまん", "fuman", "ketidakpuasan", "N2", "noun", "不満", "fuman", "不満", "fuman", [
            ("彼は不満を言いました。", "Kare wa fuman o iimashita.", "Dia menyampaikan ketidakpuasannya."),
        ]),
        ("tokuchou", "特徴", "とくちょう", "tokuchou", "karakteristik/ciri khas", "N3", "noun", "特徴", "tokuchou", "特徴", "tokuchou", [
            ("この製品の特徴を説明します。", "Kono seihin no tokuchou o setsumei shimasu.", "Saya menjelaskan ciri khas produk ini."),
        ]),
        ("youso", "要素", "ようそ", "youso", "elemen/faktor", "N2", "noun", "要素", "youso", "要素", "youso", [
            ("成功の要素は何ですか。", "Seikou no youso wa nan desu ka.", "Apa saja faktor keberhasilan?"),
        ]),
        ("youin", "要因", "よういん", "youin", "faktor penyebab", "N1", "noun", "要因", "youin", "要因", "youin", [
            ("失敗の要因を分析します。", "Shippai no youin o bunseki shimasu.", "Saya menganalisis faktor penyebab kegagalan."),
        ]),
        ("shudan", "手段", "しゅだん", "shudan", "cara/sarana", "N2", "noun", "手段", "shudan", "手段", "shudan", [
            ("目的のためには手段を選びません。", "Mokuteki no tame ni wa shudan o erabimasen.", "Demi tujuan, dia tidak memilih-milih cara."),
        ]),
        ("houshin", "方針", "ほうしん", "houshin", "kebijakan arah/pedoman", "N1", "noun", "方針", "houshin", "方針", "houshin", [
            ("会社の方針に従います。", "Kaisha no houshin ni shitagaimasu.", "Saya mengikuti kebijakan perusahaan."),
        ]),
        ("aizu", "合図", "あいず", "aizu", "tanda/sinyal", "N2", "noun", "合図", "aizu", "合図", "aizu", [
            ("合図をしてください。", "Aizu o shite kudasai.", "Tolong beri tanda. (aba2, suara,gerakan, hitungan)"),
        ]),
        ("igai", "以外", "いがい", "igai", "selain", "N2", "noun", "以外", "igai", "以外", "igai", [
            ("日曜日以外働きます。", "Nichiyoubi igai hatarakimasu.", "Saya bekerja selain hari Minggu."),
        ]),
        ("ichiryuu", "一流", "いちりゅう", "ichiryuu", "kelas satu/papan atas", "N2", "noun", "一流", "ichiryuu", "一流", "ichiryuu", [
            ("一流の会社です。", "Ichiryuu no kaisha desu.", "Perusahaan kelas satu."),
        ]),
        ("ippan", "一般", "いっぱん", "ippan", "umum", "N2", "noun", "一般", "ippan", "一般", "ippan", [
            ("一般の人も参加できます。", "Ippan no hito mo sanka dekimasu.", "Orang umum juga bisa ikut. (umum, biasanya)"),
        ]),
        ("idou", "移動", "いどう", "idou", "berpindah", "N2", "noun", "移動", "idou", "移動", "idou", [
            ("部屋を移動します。", "Heya o idou shimasu.", "Pindah ruangan."),
        ]),
        ("uchuu", "宇宙", "うちゅう", "uchuu", "alam semesta/luar angkasa", "N2", "noun", "宇宙", "uchuu", "宇宙", "uchuu", [
            ("宇宙に興味があります。", "Uchuu ni kyoumi ga arimasu.", "Saya tertarik pada luar angkasa."),
        ]),
        ("enryo", "遠慮", "えんりょ", "enryo", "sungkan/segan", "N2", "noun", "遠慮", "enryo", "遠慮", "enryo", [
            ("遠慮しないでください。", "Enryo shinaide kudasai.", "Jangan sungkan."),
        ]),
        ("oozei", "大勢", "おおぜい", "oozei", "banyak orang", "N2", "noun", "大勢", "oozei", "大勢", "oozei", [
            ("大勢の人がいます。", "Oozei no hito ga imasu.", "Ada banyak orang. (hanya orang)"),
        ]),
        ("kaiin", "会員", "かいいん", "kaiin", "anggota", "N2", "noun", "会員", "kaiin", "会員", "kaiin", [
            ("会員になりました。", "Kaiin ni narimashita.", "Menjadi anggota."),
        ]),
        ("kaiketsu", "解決", "かいけつ", "kaiketsu", "penyelesaian", "N2", "noun", "解決", "kaiketsu", "解決", "kaiketsu", [
            ("問題を解決しました。", "Mondai o kaiketsu shimashita.", "Masalah sudah diselesaikan."),
        ]),
        ("kaishuu", "回収", "かいしゅう", "kaishuu", "pengumpulan", "N2", "noun", "回収", "kaishuu", "回収", "kaishuu", [
            ("ゴミを回収します。", "Gomi o kaishuu shimasu.", "Mengumpulkan sampah. (Oleh petugas)"),
        ]),
        ("kaishi", "開始", "かいし", "kaishi", "permulaan", "N2", "noun", "開始", "kaishi", "開始", "kaishi", [
            ("作業を開始します。", "Sagyou o kaishi shimasu.", "Memulai pekerjaan."),
        ]),
        ("kaisuu", "回数", "かいすう", "kaisuu", "jumlah kali/frekuensi", "N2", "noun", "回数", "kaisuu", "回数", "kaisuu", [
            ("回数が増えました。", "Kaisuu ga fuemashita.", "Jumlah kali bertambah. (frekuensi)"),
        ]),
        ("kaisetsu", "解説", "かいせつ", "kaisetsu", "penjelasan", "N2", "noun", "解説", "kaisetsu", "解説", "kaisetsu", [
            ("先生が解説します。", "Sensei ga kaisetsu shimasu.", "Guru menjelaskan. (materi, aturan, hal)"),
        ]),
        ("kakaku", "価格", "かかく", "kakaku", "harga", "N2", "noun", "価格", "kakaku", "価格", "kakaku", [
            ("価格が高いです。", "Kakaku ga takai desu.", "Harganya mahal. (industri, ekonomi, laporan)"),
        ]),
        ("kakunin", "確認", "かくにん", "kakunin", "konfirmasi", "N2", "noun", "確認", "kakunin", "確認", "kakunin", [
            ("もう一度確認してください。", "Mou ichido kakunin shite kudasai.", "Tolong periksa sekali lagi."),
        ]),
        ("kankyaku", "観客", "かんきゃく", "kankyaku", "penonton", "N2", "noun", "観客", "kankyaku", "観客", "kankyaku", [
            ("観客が多いです。", "Kankyaku ga ooi desu.", "Penontonnya banyak. (konser,pertandingan)"),
        ]),
        ("kankei", "関係", "かんけい", "kankei", "hubungan", "N2", "noun", "関係", "kankei", "関係", "kankei", [
            ("仕事に関係があります。", "Shigoto ni kankei ga arimasu.", "Ada hubungan dengan pekerjaan."),
        ]),
        ("kangei", "歓迎", "かんげい", "kangei", "sambutan/penyambutan", "N2", "noun", "歓迎", "kangei", "歓迎", "kangei", [
            ("皆さんを歓迎します。", "Minasan o kangei shimasu.", "Kami menyambut kalian."),
        ]),
        ("kansei", "完成", "かんせい", "kansei", "penyelesaian (hasil)", "N2", "noun", "完成", "kansei", "完成", "kansei", [
            ("レポートが完成しました。", "Repooto ga kansei shimashita.", "Laporan sudah selesai. (sudah hasilnya)"),
        ]),
        ("gaishutsu", "外出", "がいしゅつ", "gaishutsu", "keluar rumah", "N2", "noun", "外出", "gaishutsu", "外出", "gaishutsu", [
            ("これから外出します。", "Korekara gaishutsu shimasu.", "Saya akan keluar. (resmi,formal,laporan)"),
        ]),
        ("kitaku", "帰宅", "きたく", "kitaku", "pulang ke rumah", "N2", "noun", "帰宅", "kitaku", "帰宅", "kitaku", [
            ("10時に帰宅しました。", "Juji ni kitaku shimashita.", "Saya pulang ke rumah jam 10."),
        ]),
        ("kyousou", "競争", "きょうそう", "kyousou", "persaingan", "N2", "noun", "競争", "kyousou", "競争", "kyousou", [
            ("激しい競争があります。", "Hageshii kyousou ga arimasu.", "Ada persaingan ketat."),
        ]),
        ("kyoutsuu", "共通", "きょうつう", "kyoutsuu", "kesamaan/umum", "N2", "noun", "共通", "kyoutsuu", "共通", "kyoutsuu", [
            ("共通の趣味があります。", "Kyoutsuu no shumi ga arimasu.", "Punya hobi yang sama. (tidak harus identik, ada persamaan)"),
        ]),
        ("kiroku", "記録", "きろく", "kiroku", "catatan/rekor", "N2", "noun", "記録", "kiroku", "記録", "kiroku", [
            ("記録を取ります。", "Kiroku o torimasu.", "Mencatat / mengambil data. (dengan catatan)"),
        ]),
        ("kufuu", "工夫", "くふう", "kufuu", "cara praktis/strategi", "N2", "noun", "工夫", "kufuu", "工夫", "kufuu", [
            ("作業を工夫します。", "Sagyou o kufuu shimasu.", "Mencari cara agar kerja lebih efisien. (cara praktis, strategi)"),
        ]),
        ("kubetsu", "区別", "くべつ", "kubetsu", "perbedaan", "N2", "noun", "区別", "kubetsu", "区別", "kubetsu", [
            ("二つを区別してください。", "Futatsu o kubetsu shite kudasai.", "Tolong bedakan keduanya. (kategori, perbedaan)"),
        ]),
        ("kunren", "訓練", "くんれん", "kunren", "latihan", "N2", "noun", "訓練", "kunren", "訓練", "kunren", [
            ("毎日訓練します。", "Mainichi kunren shimasu.", "Latihan setiap hari. (pelatihan serius, profesi)"),
        ]),
        ("guuzen", "偶然", "ぐうぜん", "guuzen", "kebetulan", "N2", "noun", "偶然", "guuzen", "偶然", "guuzen", [
            ("偶然会いました。", "Guuzen aimashita.", "Bertemu secara kebetulan."),
        ]),
        ("keikaku", "計画", "けいかく", "keikaku", "rencana", "N2", "noun", "計画", "keikaku", "計画", "keikaku", [
            ("計画を立てます。", "Keikaku o tatemasu.", "Membuat rencana."),
        ]),
        ("kekkyoku", "結局", "けっきょく", "kekkyoku", "akhirnya", "N2", "noun", "結局", "kekkyoku", "結局", "kekkyoku", [
            ("結局行きませんでした。", "Kekkyoku ikimasen deshita.", "Akhirnya tidak jadi pergi."),
        ]),
        ("kekkou", "結構", "けっこう", "kekkou", "cukup/baiklah", "N2", "noun", "結構", "kekkou", "結構", "kekkou", [
            ("それで結構です。", "Sore de kekkou desu.", "Itu sudah cukup / tidak apa-apa."),
        ]),
        ("ketten", "欠点", "けってん", "ketten", "kekurangan", "N2", "noun", "欠点", "ketten", "欠点", "ketten", [
            ("彼の欠点を知っています。", "Kare no ketten o shitte imasu.", "Saya tahu kekurangannya."),
        ]),
        ("koukan", "交換", "こうかん", "koukan", "penggantian/tukar", "N2", "noun", "交換", "koukan", "交換", "koukan", [
            ("部品を交換します。", "Buhin o koukan shimasu.", "Mengganti komponen."),
        ]),
        ("koukyou", "公共", "こうきょう", "koukyou", "publik/umum", "N2", "noun", "公共", "koukyou", "公共", "koukyou", [
            ("公共の場所です。", "Koukyou no basho desu.", "Tempat umum. (publik, fasum)"),
        ]),
        ("koudou", "行動", "こうどう", "koudou", "tindakan", "N2", "noun", "行動", "koudou", "行動", "koudou", [
            ("すぐ行動してください。", "Sugu koudou shite kudasai.", "Segera bertindak. (tindakan, perilaku)"),
        ]),
        ("kojin", "個人", "こじん", "kojin", "pribadi/perseorangan", "N2", "noun", "個人", "kojin", "個人", "kojin", [
            ("個人情報を守ります。", "Kojin jouhou o mamorimasu.", "Melindungi data pribadi."),
        ]),
        ("goukei", "合計", "ごうけい", "goukei", "total/jumlah keseluruhan", "N2", "noun", "合計", "goukei", "合計", "goukei", [
            ("合計を計算します。", "Goukei o keisan shimasu.", "Menghitung total."),
        ]),
        ("saishuu", "最終", "さいしゅう", "saishuu", "terakhir", "N2", "noun", "最終", "saishuu", "最終", "saishuu", [
            ("最終電車に乗ります。", "Saishuu densha ni norimasu.", "Naik kereta terakhir."),
        ]),
        ("saisho", "最初", "さいしょ", "saisho", "pertama/awal", "N2", "noun", "最初", "saisho", "最初", "saisho", [
            ("最初に自己紹介します。", "Saisho ni jiko shoukai shimasu.", "Pertama saya perkenalan diri."),
        ]),
        ("sansei", "賛成", "さんせい", "sansei", "persetujuan", "N2", "noun", "賛成", "sansei", "賛成", "sansei", [
            ("私は賛成です。", "Watashi wa sansei desu.", "Saya setuju."),
        ]),
        ("zairyou", "材料", "ざいりょう", "zairyou", "bahan", "N2", "noun", "材料", "zairyou", "材料", "zairyou", [
            ("材料を準備します。", "Zairyou o junbi shimasu.", "Menyiapkan bahan. (masakan, bangunan, kerajianan)"),
        ]),
        ("shizen", "自然", "しぜん", "shizen", "alam", "N2", "noun", "自然", "shizen", "自然", "shizen", [
            ("自然が豊ゆたかです。", "Shizen ga yutaka desu.", "Alamnya kaya."),
        ]),
        ("shitei", "指定", "してい", "shitei", "penentuan (waktu)", "N2", "noun", "指定", "shitei", "指定", "shitei", [
            ("時間を指定してください。", "Jikan o shitei shite kudasai.", "Tolong tentukan waktunya."),
        ]),
        ("shimei", "氏名", "しめい", "shimei", "nama lengkap", "N2", "noun", "氏名", "shimei", "氏名", "shimei", [
            ("氏名を書いてください。", "Shimei o kaite kudasai.", "Tolong tulis nama lengkap."),
        ]),
        ("shuuchuu", "集中", "しゅうちゅう", "shuuchuu", "fokus/konsentrasi", "N2", "noun", "集中", "shuuchuu", "集中", "shuuchuu", [
            ("勉強に集中します。", "Benkyou ni shuuchuu shimasu.", "Fokus belajar."),
        ]),
        ("shuuryou", "終了", "しゅうりょう", "shuuryou", "berakhir/selesai", "N2", "noun", "終了", "shuuryou", "終了", "shuuryou", [
            ("会議が終了しました。", "Kaigi ga shuuryou shimashita.", "Rapat selesai."),
        ]),
        ("shurui", "種類", "しゅるい", "shurui", "jenis", "N2", "noun", "種類", "shurui", "種類", "shurui", [
            ("種類が多いです。", "Shurui ga ooi desu.", "Jenisnya banyak."),
        ]),
        ("shiyou", "使用", "しよう", "shiyou", "penggunaan", "N2", "noun", "使用", "shiyou", "使用", "shiyou", [
            ("この機械を使用します。", "Kono kikai o shiyou shimasu.", "Menggunakan mesin ini."),
        ]),
        ("shoukai", "紹介", "しょうかい", "shoukai", "perkenalan", "N2", "noun", "紹介", "shoukai", "紹介", "shoukai", [
            ("友達を紹介します。", "Tomodachi o shoukai shimasu.", "Memperkenalkan teman."),
        ]),
        ("shourai", "将来", "しょうらい", "shourai", "masa depan", "N2", "noun", "将来", "shourai", "将来", "shourai", [
            ("将来日本で働きたいです。", "Shourai Nihon de hatarakitai desu.", "Ingin bekerja di Jepang di masa depan."),
        ]),
        ("shinkou", "進行", "しんこう", "shinkou", "berlangsungnya (proses)", "N2", "noun", "進行", "shinkou", "進行", "shinkou", [
            ("会議が進行しています。", "Kaigi ga shinkou shite imasu.", "Rapat sedang berlangsung. (jalannya suatu proses, kondisi)"),
        ]),
        ("shinrin", "森林", "しんりん", "shinrin", "hutan", "N2", "noun", "森林", "shinrin", "森林", "shinrin", [
            ("森林を守りましょう。", "Shinrin o mamorimashou.", "Mari melindungi hutan."),
        ]),
        ("jiken", "事件", "じけん", "jiken", "kejadian/insiden", "N2", "noun", "事件", "jiken", "事件", "jiken", [
            ("大きな事件がありました。", "Ookina jiken ga arimashita.", "Ada kejadian besar."),
        ]),
        ("jisan", "持参", "じさん", "jisan", "membawa (barang)", "N2", "noun", "持参", "jisan", "持参", "jisan", [
            ("パスポートを持参してください。", "Pasupooto o jisan shite kudasai.", "Harap membawa paspor. (pengumuman)"),
        ]),
        ("jijou", "事情", "じじょう", "jijou", "keadaan/situasi", "N2", "noun", "事情", "jijou", "事情", "jijou", [
            ("事情を説明します。", "Jijou o setsumei shimasu.", "Menjelaskan keadaan/alasan."),
        ]),
        ("jikkou", "実行", "じっこう", "jikkou", "pelaksanaan", "N2", "noun", "実行", "jikkou", "実行", "jikkou", [
            ("計画を実行します。", "Keikaku o jikkou shimasu.", "Melaksanakan rencana. (menjalankan)"),
        ]),
        ("jitsuyou", "実用", "じつよう", "jitsuyou", "kepraktisan", "N2", "noun", "実用", "jitsuyou", "実用", "jitsuyou", [
            ("実用的な道具です。", "Jitsuyouteki na dougu desu.", "Alat yang praktis/berguna. (keperaktisannya bermanfaat)"),
        ]),
        ("jitsuryoku", "実力", "じつりょく", "jitsuryoku", "kemampuan (nyata)", "N2", "noun", "実力", "jitsuryoku", "実力", "jitsuryoku", [
            ("実力を伸ばします。", "Jitsuryoku o nobashimasu.", "Meningkatkan kemampuan. (Skill sebenarnya)"),
        ]),
        ("junban", "順番", "じゅんばん", "junban", "urutan", "N2", "noun", "順番", "junban", "順番", "junban", [
            ("順番を守ってください。", "Junban o mamotte kudasai.", "Tolong patuhi urutan."),
        ]),
        ("joutai", "状態", "じょうたい", "joutai", "kondisi/keadaan", "N2", "noun", "状態", "joutai", "状態", "joutai", [
            ("機械の状態を確認します。", "Kikai no joutai o kakunin shimasu.", "Mengecek kondisi mesin."),
        ]),
        ("joudan", "冗談", "じょうだん", "joudan", "candaan/lelucon", "N2", "noun", "冗談", "joudan", "冗談", "joudan", [
            ("冗談ですよ。", "Joudan desu yo.", "Itu hanya bercanda."),
        ]),
        ("josei", "女性", "じょせい", "josei", "perempuan", "N2", "noun", "女性", "josei", "女性", "josei", [
            ("女性が多いです。", "Josei ga ooi desu.", "Banyak perempuan."),
        ]),
        ("jinsei", "人生", "じんせい", "jinsei", "kehidupan", "N2", "noun", "人生", "jinsei", "人生", "jinsei", [
            ("人生は一度だけです。", "Jinsei wa ichido dake desu.", "Hidup hanya sekali."),
        ]),
        ("seigen", "制限", "せいげん", "seigen", "pembatasan", "N2", "noun", "制限", "seigen", "制限", "seigen", [
            ("時間を制限します。", "Jikan o seigen shimasu.", "Membatasi waktu. (batasan, limit kemampuan/aturan)"),
        ]),
        ("zenin2", "全員", "ぜんいん", "zenin", "semua orang", "N2", "noun", "全員", "zenin", "全員", "zenin", [
            ("全員集まってください。", "Zen'in atsumatte kudasai.", "Semua orang harap berkumpul."),
        ]),
        ("soutou", "相当", "そうとう", "soutou", "cukup/sangat (tingkat)", "N2", "noun", "相当", "soutou", "相当", "soutou", [
            ("N2の文字語彙は相当難しいです。", "N2 no mojigoi wa soutou muzukashii desu.", "Mojigoi N2 Cukup/sangat sulit. (Naik level kesulitannya)"),
        ]),
        ("souryou", "送料", "そうりょう", "souryou", "ongkos kirim", "N2", "noun", "送料", "souryou", "送料", "souryou", [
            ("送料は無料です。", "Souryou wa muryou desu.", "Ongkir gratis."),
        ]),
        ("zouka", "増加", "ぞうか", "zouka", "peningkatan (jumlah)", "N2", "noun", "増加", "zouka", "増加", "zouka", [
            ("人口が増加しています。", "Jinkou ga zouka shite imasu.", "Populasi meningkat."),
        ]),
        ("tairyou", "大量", "たいりょう", "tairyou", "jumlah besar", "N2", "noun", "大量", "tairyou", "大量", "tairyou", [
            ("大量に水を使います。", "Tairyou ni mizu o tsukaimasu.", "Menggunakan air dalam jumlah besar."),
        ]),
        ("daikin", "代金", "だいきん", "daikin", "biaya/pembayaran", "N2", "noun", "代金", "daikin", "代金", "daikin", [
            ("代金を払います。", "Daikin o haraimasu.", "Membayar biaya."),
        ]),
        ("dantai", "団体", "だんたい", "dantai", "rombongan/kelompok", "N2", "noun", "団体", "dantai", "団体", "dantai", [
            ("団体で旅行します。", "Dantai de ryokou shimasu.", "Bepergian secara rombongan."),
        ]),
        ("chuumon", "注文", "ちゅうもん", "chuumon", "pemesanan", "N2", "noun", "注文", "chuumon", "注文", "chuumon", [
            ("料理を注文します。", "Ryouri o chuumon shimasu.", "Memesan makanan."),
        ]),
        ("choushi", "調子", "ちょうし", "choushi", "kondisi (tubuh/keadaan)", "N2", "noun", "調子", "choushi", "調子", "choushi", [
            ("調子がいいです。", "Choushi ga ii desu.", "Kondisinya baik."),
        ]),
        ("teika", "低下", "ていか", "teika", "penurunan", "N2", "noun", "低下", "teika", "低下", "teika", [
            ("気温が低下しました。", "Kion ga teika shimashita.", "Suhu menurun."),
        ]),
        ("dengon", "伝言", "でんごん", "dengon", "pesan (titipan)", "N2", "noun", "伝言", "dengon", "伝言", "dengon", [
            ("伝言をお願いします。", "Dengon o onegai shimasu.", "Tolong sampaikan pesan."),
        ]),
        ("dokuritsu", "独立", "どくりつ", "dokuritsu", "kemandirian", "N2", "noun", "独立", "dokuritsu", "独立", "dokuritsu", [
            ("将来独立したいです。", "Shourai dokuritsu shitai desu.", "Saya ingin mandiri/berbisnis sendiri di masa depan."),
        ]),
        ("doryoku", "努力", "どりょく", "doryoku", "usaha keras", "N2", "noun", "努力", "doryoku", "努力", "doryoku", [
            ("合格のために努力します。", "Goukaku no tame ni doryoku shimasu.", "Saya berusaha keras untuk lulus."),
        ]),
        ("naiyou", "内容", "ないよう", "naiyou", "isi/konten", "N2", "noun", "内容", "naiyou", "内容", "naiyou", [
            ("内容を確認してください。", "Naiyou o kakunin shite kudasai.", "Tolong periksa isinya. (inti / konten penjelasan)"),
        ]),
        ("nakami", "中身", "なかみ", "nakami", "isi (di dalam sesuatu)", "N2", "noun", "中身", "nakami", "中身", "nakami", [
            ("箱の中身は何ですか。", "Hako no nakami wa nan desu ka.", "Apa isi kotaknya? (barang dalam suatu wadah)"),
        ]),
        ("nimotsu", "荷物", "にもつ", "nimotsu", "barang bawaan", "N2", "noun", "荷物", "nimotsu", "荷物", "nimotsu", [
            ("荷物を持ちます。", "Nimotsu o mochimasu.", "Saya membawa barang."),
        ]),
        ("ninki", "人気", "にんき", "ninki", "popularitas", "N2", "noun", "人気", "ninki", "人気", "ninki", [
            ("この店は人気があります。", "Kono mise wa ninki ga arimasu.", "Toko ini populer. (Banyak yg suka)"),
        ]),
        ("ningen", "人間", "にんげん", "ningen", "manusia", "N2", "noun", "人間", "ningen", "人間", "ningen", [
            ("人間は考える生き物です。", "Ningen wa kangaeru ikimono desu.", "Manusia adalah makhluk yang berpikir."),
        ]),
        ("nedan", "値段", "ねだん", "nedan", "harga", "N2", "noun", "値段", "nedan", "値段", "nedan", [
            ("値段が高いです。", "Nedan ga takai desu.", "Harganya mahal."),
        ]),
        ("nebou", "寝坊", "ねぼう", "nebou", "bangun kesiangan", "N2", "noun", "寝坊", "nebou", "寝坊", "nebou", [
            ("今朝寝坊しました。", "Kesa nebou shimashita.", "Tadi pagi saya bangun kesiangan."),
        ]),
        ("nenrei", "年齢", "ねんれい", "nenrei", "usia", "N2", "noun", "年齢", "nenrei", "年齢", "nenrei", [
            ("年齢を書いてください。", "Nenrei o kaite kudasai.", "Silakan tulis usia."),
        ]),
        ("hassei", "発生", "はっせい", "hassei", "terjadinya (sesuatu)", "N2", "noun", "発生", "hassei", "発生", "hassei", [
            ("事故が発生しました。", "Jiko ga hassei shimashita.", "Terjadi kecelakaan.(Berkembang/proses jadi kecelakaan)"),
        ]),
        ("hijou", "非常", "ひじょう", "hijou", "sangat (tingkat tinggi)", "N2", "noun", "非常", "hijou", "非常", "hijou", [
            ("非常に寒いです。", "Hijou ni samui desu.", "Sangat dingin."),
        ]),
        ("hitei", "否定", "ひてい", "hitei", "penyangkalan", "N2", "noun", "否定", "hitei", "否定", "hitei", [
            ("彼は事実を否定しました。", "Kare wa jijitsu o hitei shimashita.", "Dia menyangkal fakta."),
        ]),
        ("himitsu", "秘密", "ひみつ", "himitsu", "rahasia", "N2", "noun", "秘密", "himitsu", "秘密", "himitsu", [
            ("これは秘密です。", "Kore wa himitsu desu.", "Ini rahasia."),
        ]),
        ("hyoumen", "表面", "ひょうめん", "hyoumen", "permukaan", "N2", "noun", "表面", "hyoumen", "表面", "hyoumen", [
            ("表面を触らないでください。", "Hyoumen o sawaranaide kudasai.", "Tolong jangan sentuh permukaannya."),
        ]),
        ("fusoku", "不足", "ふそく", "fusoku", "kekurangan", "N2", "noun", "不足", "fusoku", "不足", "fusoku", [
            ("水が不足しています。", "Mizu ga fusoku shite imasu.", "Air sedang kekurangan."),
        ]),
        ("bubun", "部分", "ぶぶん", "bubun", "bagian", "N2", "noun", "部分", "bubun", "部分", "bubun", [
            ("この部分を直してください。", "Kono bubun o naoshite kudasai.", "Tolong perbaiki bagian ini."),
        ]),
        ("bunrui", "分類", "ぶんるい", "bunrui", "pengelompokan", "N2", "noun", "分類", "bunrui", "分類", "bunrui", [
            ("ゴミを分類します。", "Gomi o bunrui shimasu.", "Mengelompokkan sampah. (Berdasarkan jenisnya)"),
        ]),
        ("houhou", "方法", "ほうほう", "houhou", "cara/metode", "N2", "noun", "方法", "houhou", "方法", "houhou", [
            ("いい方法を考えます。", "Ii houhou o kangaemasu.", "Memikirkan cara yang baik."),
        ]),
        ("hontou", "本当", "ほんとう", "hontou", "benar/sungguh", "N2", "noun", "本当", "hontou", "本当", "hontou", [
            ("本当ですか。", "Hontou desu ka.", "Benarkah?"),
        ]),
        ("mikata", "見方", "みかた", "mikata", "cara pandang", "N2", "noun", "見方", "mikata", "見方", "mikata", [
            ("考え方の見方が違います。", "Kangaekata no mikata ga chigaimasu.", "Cara pandang pemikirannya berbeda."),
        ]),
        ("mihon", "見本", "みほん", "mihon", "contoh/sampel", "N2", "noun", "見本", "mihon", "見本", "mihon", [
            ("見本を見せてください。", "Mihon o misete kudasai.", "Tolong tunjukkan contoh/sampel."),
        ]),
        ("muryou", "無料", "むりょう", "muryou", "gratis", "N2", "noun", "無料", "muryou", "無料", "muryou", [
            ("このサービスは無料です。", "Kono saabisu wa muryou desu.", "Layanan ini gratis."),
        ]),
        ("mokuhyou", "目標", "もくひょう", "mokuhyou", "target/sasaran", "N2", "noun", "目標", "mokuhyou", "目標", "mokuhyou", [
            ("目標を決めました。", "Mokuhyou o kimemashita.", "Saya menetapkan target."),
        ]),
        ("yuuryou", "有料", "ゆうりょう", "yuuryou", "berbayar", "N2", "noun", "有料", "yuuryou", "有料", "yuuryou", [
            ("ここから先は有料です。", "Koko kara saki wa yuuryou desu.", "Dari sini berbayar."),
        ]),
        ("yosou", "予想", "よそう", "yosou", "prediksi/perkiraan", "N2", "noun", "予想", "yosou", "予想", "yosou", [
            ("結果を予想します。", "Kekka o yosou shimasu.", "Memprediksi hasil."),
        ]),
        ("ryoukin", "料金", "りょうきん", "ryoukin", "biaya/tarif", "N2", "noun", "料金", "ryoukin", "料金", "ryoukin", [
            ("料金を払ってください。", "Ryoukin o haratte kudasai.", "Tolong bayar biayanya."),
        ]),
        ("rusu", "留守", "るす", "rusu", "rumah kosong/tidak ada orang", "N2", "noun", "留守", "rusu", "留守", "rusu", [
            ("今、家は留守です。", "Ima, ie wa rusu desu.", "Sekarang rumah kosong."),
        ]),
        ("waribiki", "割引", "わりびき", "waribiki", "diskon/potongan harga", "N2", "noun", "割引", "waribiki", "割引", "waribiki", [
            ("商品を割引します。", "Shouhin o waribiki shimasu.", "Barang didiskon."),
        ]),
        ("sassoku", "早速", "さっそく", "sassoku", "segera", "N2", "noun", "早速", "sassoku", "早速", "sassoku", [
            ("早速やってみます。", "Sassoku yatte mimasu.", "Saya akan segera mencobanya."),
        ]),
        ("tashou", "多少", "たしょう", "tashou", "sedikit/agak", "N2", "noun", "多少", "tashou", "多少", "tashou", [
            ("多少時間があります。", "Tashou jikan ga arimasu.", "Ada sedikit waktu. (sedikit, beberapa, agak)"),
        ]),
        ("touzen", "当然", "とうぜん", "touzen", "wajar/sudah sepantasnya", "N2", "noun", "当然", "touzen", "当然", "touzen", [
            ("当然の結果です。", "Touzen no kekka desu.", "Ini hasil yang wajar. (sudah sewajarnya / tentu saja)"),
        ]),
        ("totsuzen", "突然", "とつぜん", "totsuzen", "tiba-tiba", "N2", "noun", "突然", "totsuzen", "突然", "totsuzen", [
            ("突然雨が降りました。", "Totsuzen ame ga furimashita.", "Tiba-tiba hujan turun. (Mendadak, dramatis, naratif)"),
        ]),
        ("fudan", "普段", "ふだん", "fudan", "biasanya", "N2", "noun", "普段", "fudan", "普段", "fudan", [
            ("普段は忙しいです。", "Fudan wa isogashii desu.", "Biasanya saya sibuk. (kebiasaan atau rutinitas)"),
        ]),
        ("aiyou", "愛用", "あいよう", "aiyou", "kesukaan memakai (favorit)", "N2", "noun", "愛用", "aiyou", "愛用", "aiyou", [
            ("このペンを長く愛用しています。", "Kono pen o nagaku aiyou shite imasu.", "Saya sudah lama memakai pena ini. menggunkan sbg favorit"),
        ]),
        ("antei", "安定", "あんてい", "antei", "kestabilan", "N2", "noun", "安定", "antei", "安定", "antei", [
            ("生活が安定してきました。", "Seikatsu ga antei shite kimashita.", "Kehidupan mulai stabil."),
        ]),
        ("igi", "意義", "いぎ", "igi", "makna penting", "N2", "noun", "意義", "igi", "意義", "igi", [
            ("この仕事には大きな意義がある。", "Kono shigoto ni wa ookina igi ga aru.", "Pekerjaan ini memiliki makna besar. (Arti penting)"),
        ]),
        ("ikou", "移行", "いこう", "ikou", "peralihan (sistem)", "N2", "noun", "移行", "ikou", "移行", "ikou", [
            ("新しい制度に移行します。", "Atarashii seido ni ikou shimasu.", "Beralih ke sistem baru."),
        ]),
        ("ijou", "異常", "いじょう", "ijou", "keanehan/kelainan", "N2", "noun", "異常", "ijou", "異常", "ijou", [
            ("機械に異常があります。", "Kikai ni ijou ga arimasu.", "Ada keanehan pada mesin."),
        ]),
        # Moved here from perasaan_emosi: 意思 (ishi, "niat/maksud") is a
        # genuine reading collision with perasaan_emosi's own 意志 (ishi,
        # "kemauan/tekad") - different category avoids two identical-
        # reading options ever appearing together in the same quiz pool.
        ("ishi", "意思", "いし", "ishi", "niat/maksud", "N2", "noun", "意思", "ishi", "意思", "ishi", [
            ("自分の意思を伝えてください。", "Jibun no ishi o tsutaete kudasai.", "Tolong sampaikan kehendakmu."),
        ]),
        # Moved here from perasaan_emosi: 関心 (kanshin, "minat") is a
        # genuine reading collision with perasaan_emosi's own 感心
        # (kanshin, "kekaguman") - different category avoids two
        # identical-reading options in the same quiz pool.
        ("kanshin", "関心", "かんしん", "kanshin", "minat/ketertarikan", "N2", "noun", "関心", "kanshin", "関心", "kanshin", [
            ("日本文化に関心があります。", "Nihon bunka ni kanshin ga arimasu.", "Saya tertarik pada budaya Jepang."),
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
