import json

# Kotoba vocab — grup "Pendidikan & Pekerjaan" (Batch 7).
# Same per-entry registers approach as the other Batch 7 scripts.
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
    "alat_tulis_sekolah": [
        ("enpitsu", "鉛筆", "えんぴつ", "enpitsu", "pensil", "N5", "noun", "鉛筆", "enpitsu", "鉛筆", "enpitsu", [
            ("鉛筆で書きます。", "Enpitsu de kakimasu.", "Saya menulis dengan pensil."),
        ]),
        ("keshigomu", None, "けしゴム", "keshigomu", "penghapus", "N4", "noun", "けしゴム", "keshigomu", "けしゴム", "keshigomu", [
            ("消しゴムで消します。", "Keshigomu de keshimasu.", "Saya menghapus dengan penghapus."),
        ]),
        ("nooto", None, "ノート", "nooto", "buku catatan", "N5", "noun", "ノート", "nooto", "ノート", "nooto", [
            ("ノートに書きます。", "Nooto ni kakimasu.", "Saya menulis di buku catatan."),
        ]),
        ("hon", "本", "ほん", "hon", "buku", "N5", "noun", "本", "hon", "本", "hon", [
            ("本を読みます。", "Hon o yomimasu.", "Saya membaca buku."),
        ]),
        ("kaban", "鞄", "かばん", "kaban", "tas sekolah", "N4", "noun", "鞄", "kaban", "鞄", "kaban", [
            ("鞄に本を入れます。", "Kaban ni hon o iremasu.", "Saya memasukkan buku ke tas."),
        ]),
        ("hasami", None, "はさみ", "hasami", "gunting", "N4", "noun", "はさみ", "hasami", "はさみ", "hasami", [
            ("はさみで切ります。", "Hasami de kirimasu.", "Saya memotong dengan gunting."),
        ]),
        ("nori", None, "のり", "nori", "lem", "N3", "noun", "のり", "nori", "のり", "nori", [
            ("のりで貼ります。", "Nori de harimasu.", "Saya menempel dengan lem."),
        ]),
        ("jougi", "定規", "じょうぎ", "jougi", "penggaris", "N3", "noun", "定規", "jougi", "定規", "jougi", [
            ("定規で線を引きます。", "Jougi de sen o hikimasu.", "Saya menggaris dengan penggaris."),
        ]),
        ("pen", None, "ペン", "pen", "pena/pulpen", "N5", "noun", "ペン", "pen", "ペン", "pen", [
            ("ペンで書きます。", "Pen de kakimasu.", "Saya menulis dengan pena."),
        ]),
        ("fude", "筆", "ふで", "fude", "kuas (kaligrafi)", "N3", "noun", "筆", "fude", "筆", "fude", [
            ("筆で書きます。", "Fude de kakimasu.", "Saya menulis dengan kuas."),
        ]),
        ("kokuban", "黒板", "こくばん", "kokuban", "papan tulis", "N4", "noun", "黒板", "kokuban", "黒板", "kokuban", [
            ("黒板に書きます。", "Kokuban ni kakimasu.", "Saya menulis di papan tulis."),
        ]),
        # Addition prompted by the same N5-compound-pool gap noted in
        # scripts/generate_kotoba_waktu_angka.py's hari_bulan addition —
        # these are genuine N5 school-life 2-3 kanji compounds, absent
        # from the dataset before this addition.
        ("kyoukasho", "教科書", "きょうかしょ", "kyoukasho", "buku pelajaran", "N5", "noun", "教科書", "kyoukasho", "教科書", "kyoukasho", [
            ("教科書を忘れました。", "Kyoukasho o wasuremashita.", "Saya lupa membawa buku pelajaran."),
        ]),
        ("jisho", "辞書", "じしょ", "jisho", "kamus", "N5", "noun", "辞書", "jisho", "辞書", "jisho", [
            ("辞書で言葉を調べます。", "Jisho de kotoba o shirabemasu.", "Saya mencari kata di kamus."),
        ]),
        ("shukudai", "宿題", "しゅくだい", "shukudai", "pekerjaan rumah (PR)", "N5", "noun", "宿題", "shukudai", "宿題", "shukudai", [
            ("宿題をやります。", "Shukudai o yarimasu.", "Saya mengerjakan PR."),
        ]),
        ("kanji", "漢字", "かんじ", "kanji", "aksara kanji", "N5", "noun", "漢字", "kanji", "漢字", "kanji", [
            ("漢字を勉強します。", "Kanji o benkyou shimasu.", "Saya belajar kanji."),
        ]),
        ("techou", "手帳", "てちょう", "techou", "buku agenda/catatan", "N2", "noun", "手帳", "techou", "手帳", "techou", [
            ("手帳に予定を書きます。", "Techou ni yotei o kakimasu.", "Saya menulis jadwal di buku agenda."),
        ]),
        ("hyoushi", "表紙", "ひょうし", "hyoushi", "sampul (buku)", "N2", "noun", "表紙", "hyoushi", "表紙", "hyoushi", [
            ("本の表紙がきれいです。", "Hon no hyoushi ga kirei desu.", "Sampul buku indah."),
        ]),
        ("youshi", "用紙", "ようし", "youshi", "kertas formulir", "N2", "noun", "用紙", "youshi", "用紙", "youshi", [
            ("用紙に名前を書いてください。", "Youshi ni namae o kaite kudasai.", "Tolong tulis nama di kertas formulir."),
        ]),
        ("shomotsu", "書物", "しょもつ", "shomotsu", "buku (istilah formal)", "N3", "noun", "書物", "shomotsu", "書物", "shomotsu", [
            ("古い書物を読みます。", "Furui shomotsu o yomimasu.", "Membaca buku kuno."),
        ]),
        ("tosho", "図書", "としょ", "tosho", "buku-buku (koleksi, istilah formal)", "N3", "noun", "図書", "tosho", "図書", "tosho", [
            ("図書を整理します。", "Tosho o seiri shimasu.", "Merapikan buku-buku."),
        ]),
    ],
    "mata_pelajaran": [
        ("kokugo", "国語", "こくご", "kokugo", "bahasa nasional (mapel Jepang)", "N4", "noun", "国語", "kokugo", "国語", "kokugo", [
            ("国語のテストがあります。", "Kokugo no tesuto ga arimasu.", "Ada tes bahasa Jepang."),
        ]),
        ("suugaku", "数学", "すうがく", "suugaku", "matematika", "N4", "noun", "数学", "suugaku", "数学", "suugaku", [
            ("数学は難しいです。", "Suugaku wa muzukashii desu.", "Matematika itu sulit."),
        ]),
        ("rika", "理科", "りか", "rika", "IPA (sains)", "N4", "noun", "理科", "rika", "理科", "rika", [
            ("理科の実験をします。", "Rika no jikken o shimasu.", "Saya melakukan eksperimen IPA."),
        ]),
        ("shakai", "社会", "しゃかい", "shakai", "IPS (sosial)", "N4", "noun", "社会", "shakai", "社会", "shakai", [
            ("社会の授業があります。", "Shakai no jugyou ga arimasu.", "Ada pelajaran IPS."),
        ]),
        ("eigo", "英語", "えいご", "eigo", "bahasa Inggris", "N5", "noun", "英語", "eigo", "英語", "eigo", [
            ("英語を勉強します。", "Eigo o benkyou shimasu.", "Saya belajar bahasa Inggris."),
        ]),
        ("nihongo", "日本語", "にほんご", "nihongo", "bahasa Jepang", "N5", "noun", "日本語", "nihongo", "日本語", "nihongo", [
            ("日本語が好きです。", "Nihongo ga suki desu.", "Saya suka bahasa Jepang."),
        ]),
        ("taiiku", "体育", "たいいく", "taiiku", "olahraga (mapel PE)", "N4", "noun", "体育", "taiiku", "体育", "taiiku", [
            ("体育で走ります。", "Taiiku de hashirimasu.", "Saya lari saat pelajaran olahraga."),
        ]),
        ("bijutsu", "美術", "びじゅつ", "bijutsu", "seni rupa", "N3", "noun", "美術", "bijutsu", "美術", "bijutsu", [
            ("美術の授業で絵を描きます。", "Bijutsu no jugyou de e o kakimasu.", "Saya menggambar di pelajaran seni."),
        ]),
        ("rekishi", "歴史", "れきし", "rekishi", "sejarah", "N3", "noun", "歴史", "rekishi", "歴史", "rekishi", [
            ("歴史を勉強します。", "Rekishi o benkyou shimasu.", "Saya belajar sejarah."),
        ]),
        ("kagaku", "化学", "かがく", "kagaku", "kimia", "N2", "noun", "化学", "kagaku", "化学", "kagaku", [
            ("化学は面白いです。", "Kagaku wa omoshiroi desu.", "Kimia itu menarik."),
        ]),
        # N1/N2 addition (2026-07-20, fourth batch): pure-kanji academic
        # nouns, for Kombinasi Kanji pool depth.
        ("senkou", "専攻", "せんこう", "senkou", "jurusan/spesialisasi (kuliah)", "N2", "noun", "専攻", "senkou", "専攻", "senkou", [
            ("大学で経済学を専攻しています。", "Daigaku de keizaigaku o senkou shite imasu.", "Saya berkuliah jurusan ekonomi."),
        ]),
        ("rishuu", "履修", "りしゅう", "rishuu", "pengambilan mata kuliah", "N1", "noun", "履修", "rishuu", "履修", "rishuu", [
            ("来学期、この科目を履修します。", "Rai gakki, kono kamoku o rishuu shimasu.", "Semester depan, saya akan mengambil mata kuliah ini."),
        ]),
        ("shingaku", "進学", "しんがく", "shingaku", "melanjutkan pendidikan", "N2", "noun", "進学", "shingaku", "進学", "shingaku", [
            ("大学に進学するつもりです。", "Daigaku ni shingaku suru tsumori desu.", "Saya berniat melanjutkan ke perguruan tinggi."),
        ]),
        # N1/N2/N3 addition (2026-07-20, twelfth batch): more academic
        # subject nouns, for Kombinasi Kanji pool depth across N5-N1.
        ("keizai", "経済", "けいざい", "keizai", "ekonomi", "N3", "noun", "経済", "keizai", "経済", "keizai", [
            ("経済を勉強しています。", "Keizai o benkyou shite imasu.", "Saya sedang belajar ekonomi."),
        ]),
        ("butsuri", "物理", "ぶつり", "butsuri", "fisika", "N2", "noun", "物理", "butsuri", "物理", "butsuri", [
            ("物理は難しいです。", "Butsuri wa muzukashii desu.", "Fisika itu sulit."),
        ]),
        ("seibutsu", "生物", "せいぶつ", "seibutsu", "biologi", "N3", "noun", "生物", "seibutsu", "生物", "seibutsu", [
            ("生物の授業が好きです。", "Seibutsu no jugyou ga suki desu.", "Saya suka pelajaran biologi."),
        ]),
        ("chiri", "地理", "ちり", "chiri", "geografi", "N3", "noun", "地理", "chiri", "地理", "chiri", [
            ("地理のテストがあります。", "Chiri no tesuto ga arimasu.", "Ada tes geografi."),
        ]),
        ("rinri", "倫理", "りんり", "rinri", "etika", "N1", "noun", "倫理", "rinri", "倫理", "rinri", [
            ("倫理について議論します。", "Rinri ni tsuite giron shimasu.", "Kami berdiskusi tentang etika."),
        ]),
        ("tetsugaku", "哲学", "てつがく", "tetsugaku", "filsafat", "N1", "noun", "哲学", "tetsugaku", "哲学", "tetsugaku", [
            ("大学で哲学を学びました。", "Daigaku de tetsugaku o manabimashita.", "Saya belajar filsafat di universitas."),
        ]),
        ("kateika", "家庭科", "かていか", "kateika", "tata boga/prakarya", "N4", "noun", "家庭科", "kateika", "家庭科", "kateika", [
            ("家庭科でクッキーを作りました。", "Kateika de kukkii o tsukurimashita.", "Kami membuat kue di pelajaran tata boga."),
        ]),
        ("gakubu", "学部", "がくぶ", "gakubu", "fakultas", "N2", "noun", "学部", "gakubu", "学部", "gakubu", [
            ("経済学部に入ります。", "Keizai gakubu ni hairimasu.", "Masuk fakultas ekonomi."),
        ]),
        ("gakki", "学期", "がっき", "gakki", "semester", "N2", "noun", "学期", "gakki", "学期", "gakki", [
            ("新しい学期が始まります。", "Atarashii gakki ga hajimarimasu.", "Semester baru dimulai."),
        ]),
        ("kiso", "基礎", "きそ", "kiso", "dasar/pondasi", "N2", "noun", "基礎", "kiso", "基礎", "kiso", [
            ("日本語の基礎を勉強します。", "Nihongo no kiso o benkyou shimasu.", "Belajar dasar bahasa Jepang. (pondasi ilmu/skill)"),
        ]),
        ("kihon", "基本", "きほん", "kihon", "dasar/pokok", "N2", "noun", "基本", "kihon", "基本", "kihon", [
            ("基本を覚えてください。", "Kihon o oboete kudasai.", "Tolong hafalkan dasar. (aturan main/ prinsip, konsep)"),
        ]),
        ("gengo", "言語", "げんご", "gengo", "bahasa", "N2", "noun", "言語", "gengo", "言語", "gengo", [
            ("言語を学びます。", "Gengo o manabimasu.", "Mempelajari bahasa."),
        ]),
        ("kouki", "後期", "こうき", "kouki", "semester kedua", "N2", "noun", "後期", "kouki", "後期", "kouki", [
            ("後期が始まりました。", "Kouki ga hajimarimashita.", "Semester kedua dimulai."),
        ]),
        ("kougi", "講義", "こうぎ", "kougi", "kuliah", "N2", "noun", "講義", "kougi", "講義", "kougi", [
            ("大学で講義を受けます。", "Daigaku de kougi o ukemasu.", "Mengikuti kuliah di kampus."),
        ]),
        ("goukaku", "合格", "ごうかく", "goukaku", "kelulusan", "N2", "noun", "合格", "goukaku", "合格", "goukaku", [
            ("試験に合格しました。", "Shiken ni goukaku shimashita.", "Lulus ujian."),
        ]),
        ("sansuu", "算数", "さんすう", "sansuu", "matematika dasar", "N2", "noun", "算数", "sansuu", "算数", "sansuu", [
            ("算数を勉強します。", "Sansuu o benkyou shimasu.", "Belajar matematika dasar. (+-X:)"),
        ]),
        ("shiken", "試験", "しけん", "shiken", "ujian/tes", "N2", "noun", "試験", "shiken", "試験", "shiken", [
            ("明日試験があります。", "Ashita shiken ga arimasu.", "Besok ada ujian."),
        ]),
        ("shidou", "指導", "しどう", "shidou", "bimbingan", "N2", "noun", "指導", "shidou", "指導", "shidou", [
            ("先生が指導します。", "Sensei ga shidou shimasu.", "Guru membimbing."),
        ]),
        ("juken", "受験", "じゅけん", "juken", "mengikuti ujian", "N2", "noun", "受験", "juken", "受験", "juken", [
            ("JLPTを受験します。", "JLPT o juken shimasu.", "mengikuti ujian JLPT"),
        ]),
        ("seikai", "正解", "せいかい", "seikai", "jawaban benar", "N2", "noun", "正解", "seikai", "正解", "seikai", [
            ("正解しました。", "Seikai shimashita.", "Jawabannya benar."),
        ]),
        ("tango", "単語", "たんご", "tango", "kosakata", "N2", "noun", "単語", "tango", "単語", "tango", [
            ("単語を覚えます。", "Tango o oboemasu.", "Menghafal kosakata."),
        ]),
        ("tsuugaku", "通学", "つうがく", "tsuugaku", "pergi ke sekolah (naik kendaraan)", "N2", "noun", "通学", "tsuugaku", "通学", "tsuugaku", [
            ("電車で通学します。", "Densha de tsuugaku shimasu.", "Pergi sekolah naik kereta."),
        ]),
        ("nyuumon", "入門", "にゅうもん", "nyuumon", "pengenalan dasar/perkenalan pelajaran", "N2", "noun", "入門", "nyuumon", "入門", "nyuumon", [
            ("日本語を入門しました。", "Nihongo o nyuumon shimashita.", "Saya mulai belajar dasar bahasa Jepang."),
        ]),
        ("hatsuon", "発音", "はつおん", "hatsuon", "pelafalan", "N2", "noun", "発音", "hatsuon", "発音", "hatsuon", [
            ("発音を練習します。", "Hatsuon o renshuu shimasu.", "Saya melatih pelafalan."),
        ]),
        ("moji", "文字", "もじ", "moji", "huruf/karakter", "N2", "noun", "文字", "moji", "文字", "moji", [
            ("この文字は難しいです。", "Kono moji wa muzukashii desu.", "Huruf ini sulit."),
        ]),
        ("shinnyuusei", "新入生", "しんにゅうせい", "shinnyuusei", "siswa baru", "N2", "noun", "新入生", "shinnyuusei", "新入生", "shinnyuusei", [
            ("新入生を歓迎します。", "Shin'nyuusei o kangei shimasu.", "Kami menyambut siswa baru."),
        ]),
        ("daigakuin", "大学院", "だいがくいん", "daigakuin", "sekolah pascasarjana", "N2", "noun", "大学院", "daigakuin", "大学院", "daigakuin", [
            ("彼は大学院で勉強しています。", "Kare wa daigakuin de benkyou shite imasu.", "Dia belajar di sekolah pascasarjana. 修士課程 S2 博はく士課程 S3"),
        ]),
        ("anki", "暗記", "あんき", "anki", "menghafal", "N3", "noun", "暗記", "anki", "暗記", "anki", [
            ("単語を暗記します。", "Tango o anki shimasu.", "Saya menghafal kosakata."),
        ]),
        ("chuugaku", "中学", "ちゅうがく", "chuugaku", "SMP", "N3", "noun", "中学", "chuugaku", "中学", "chuugaku", [
            ("中学に入学します。", "Chuugaku ni nyuugaku shimasu.", "Saya masuk SMP."),
        ]),
        ("gakumon", "学問", "がくもん", "gakumon", "ilmu pengetahuan", "N3", "noun", "学問", "gakumon", "学問", "gakumon", [
            ("学問を深めます。", "Gakumon o fukamemasu.", "Saya memperdalam ilmu pengetahuan."),
        ]),
        ("gakushuu", "学習", "がくしゅう", "gakushuu", "pembelajaran", "N3", "noun", "学習", "gakushuu", "学習", "gakushuu", [
            ("日本語を学習します。", "Nihongo o gakushuu shimasu.", "Saya belajar bahasa Jepang."),
        ]),
        ("gogaku", "語学", "ごがく", "gogaku", "studi bahasa asing", "N3", "noun", "語学", "gogaku", "語学", "gogaku", [
            ("語学が得意です。", "Gogaku ga tokui desu.", "Saya mahir dalam bahasa asing."),
        ]),
        ("kamoku", "科目", "かもく", "kamoku", "mata pelajaran (kurikulum)", "N3", "noun", "科目", "kamoku", "科目", "kamoku", [
            ("好きな科目は何ですか。", "Sukina kamoku wa nan desu ka.", "Mata pelajaran favoritmu apa?"),
        ]),
        ("ryuugaku", "留学", "りゅうがく", "ryuugaku", "belajar di luar negeri", "N3", "noun", "留学", "ryuugaku", "留学", "ryuugaku", [
            ("アメリカに留学します。", "Amerika ni ryuugaku shimasu.", "Belajar ke Amerika."),
        ]),
        ("shougakukin", "奨学金", "しょうがくきん", "shougakukin", "beasiswa", "N3", "noun", "奨学金", "shougakukin", "奨学金", "shougakukin", [
            ("奨学金をもらいました。", "Shougakukin o moraimashita.", "Menerima beasiswa."),
        ]),
        ("jissen", "実践", "じっせん", "jissen", "praktik (penerapan nyata)", "N1", "noun", "実践", "jissen", "実践", "jissen", [
            ("理論を実践します。", "Riron o jissen shimasu.", "Mempraktikkan teori."),
        ]),
        ("kadai", "課題", "かだい", "kadai", "tugas/isu", "N1", "noun", "課題", "kadai", "課題", "kadai", [
            ("課題を提出します。", "Kadai o teishutsu shimasu.", "Menyerahkan tugas."),
        ]),
    ],
    "pekerjaan_kantor": [
        ("kaisha", "会社", "かいしゃ", "kaisha", "perusahaan/kantor", "N5", "noun", "会社", "kaisha", "会社", "kaisha", [
            ("会社で働きます。", "Kaisha de hatarakimasu.", "Saya bekerja di kantor."),
        ]),
        ("shigoto", "仕事", "しごと", "shigoto", "pekerjaan", "N5", "noun", "仕事", "shigoto", "仕事", "shigoto", [
            ("仕事が忙しいです。", "Shigoto ga isogashii desu.", "Pekerjaan saya sibuk."),
        ]),
        ("kaigi", "会議", "かいぎ", "kaigi", "rapat", "N4", "noun", "会議", "kaigi", "会議", "kaigi", [
            ("会議があります。", "Kaigi ga arimasu.", "Ada rapat."),
        ]),
        ("meishi", "名刺", "めいし", "meishi", "kartu nama", "N3", "noun", "名刺", "meishi", "名刺", "meishi", [
            ("名刺を交換します。", "Meishi o koukan shimasu.", "Saya bertukar kartu nama."),
        ]),
        ("joushi", "上司", "じょうし", "joushi", "atasan/bos", "N3", "noun", "上司", "joushi", "上司", "joushi", [
            ("上司に相談します。", "Joushi ni soudan shimasu.", "Saya berkonsultasi dengan atasan."),
        ]),
        ("buka", "部下", "ぶか", "buka", "bawahan", "N2", "noun", "部下", "buka", "部下", "buka", [
            ("部下に指示します。", "Buka ni shiji shimasu.", "Saya memberi instruksi kepada bawahan."),
        ]),
        ("douryou", "同僚", "どうりょう", "douryou", "rekan kerja", "N3", "noun", "同僚", "douryou", "同僚", "douryou", [
            ("同僚と話します。", "Douryou to hanashimasu.", "Saya berbicara dengan rekan kerja."),
        ]),
        ("kyuuryou", "給料", "きゅうりょう", "kyuuryou", "gaji", "N3", "noun", "給料", "kyuuryou", "給料", "kyuuryou", [
            ("給料をもらいます。", "Kyuuryou o moraimasu.", "Saya menerima gaji."),
        ]),
        ("zangyou", "残業", "ざんぎょう", "zangyou", "lembur", "N3", "noun", "残業", "zangyou", "残業", "zangyou", [
            ("今日は残業します。", "Kyou wa zangyou shimasu.", "Hari ini saya lembur."),
        ]),
        ("kyuujitsu", "休日", "きゅうじつ", "kyuujitsu", "hari libur", "N4", "noun", "休日", "kyuujitsu", "休日", "kyuujitsu", [
            ("休日は家にいます。", "Kyuujitsu wa ie ni imasu.", "Saat hari libur, saya di rumah."),
        ]),
        # N1 addition (2026-07-20): formal/business-register 2-kanji compound
        # nouns, the kind that actually shows up in JLPT N1 vocabulary lists —
        # added specifically so Ujian Kanji's Kombinasi mode has an N1 pool
        # to draw from (see kanji_combo_repository.dart), not just to pad
        # this category. Kept to genuinely workplace/negotiation-flavored
        # words rather than reaching into unrelated N1 vocabulary just to
        # hit a word count.
        ("sokushin", "促進", "そくしん", "sokushin", "mendorong/mempercepat (kemajuan)", "N1", "noun", "促進", "sokushin", "促進", "sokushin", [
            ("販売促進のキャンペーンを行います。", "Hanbai sokushin no kyanpeen o okonaimasu.", "Kami mengadakan kampanye promosi penjualan."),
        ]),
        ("yokusei", "抑制", "よくせい", "yokusei", "penekanan/pengendalian", "N1", "noun", "抑制", "yokusei", "抑制", "yokusei", [
            ("経費の抑制が求められています。", "Keihi no yokusei ga motomerarete imasu.", "Penekanan biaya sedang dituntut."),
        ]),
        ("zesei", "是正", "ぜせい", "zesei", "koreksi/perbaikan", "N1", "noun", "是正", "zesei", "是正", "zesei", [
            ("問題点を是正する必要があります。", "Mondaiten o zesei suru hitsuyou ga arimasu.", "Perlu memperbaiki titik masalahnya."),
        ]),
        ("dakyou", "妥協", "だきょう", "dakyou", "kompromi", "N1", "noun", "妥協", "dakyou", "妥協", "dakyou", [
            ("両者は妥協点を見つけました。", "Ryousha wa dakyouten o mitsukemashita.", "Kedua belah pihak menemukan titik kompromi."),
        ]),
        ("dakai", "打開", "だかい", "dakai", "terobosan", "N1", "noun", "打開", "dakai", "打開", "dakai", [
            ("現状打開のための会議です。", "Genjou dakai no tame no kaigi desu.", "Ini rapat untuk menerobos situasi saat ini."),
        ]),
        ("yuugou", "融合", "ゆうごう", "yuugou", "peleburan/penggabungan", "N1", "noun", "融合", "yuugou", "融合", "yuugou", [
            ("二つの部署が融合しました。", "Futatsu no busho ga yuugou shimashita.", "Dua departemen itu dilebur menjadi satu."),
        ]),
        ("tekkai", "撤回", "てっかい", "tekkai", "penarikan kembali", "N1", "noun", "撤回", "tekkai", "撤回", "tekkai", [
            ("提案を撤回することにしました。", "Teian o tekkai suru koto ni shimashita.", "Kami memutuskan untuk menarik kembali usulan itu."),
        ]),
        ("suikou", "遂行", "すいこう", "suikou", "pelaksanaan", "N1", "noun", "遂行", "suikou", "遂行", "suikou", [
            ("任務を遂行します。", "Ninmu o suikou shimasu.", "Saya akan melaksanakan tugas."),
        ]),
        ("rikou", "履行", "りこう", "rikou", "pemenuhan (kewajiban)", "N1", "noun", "履行", "rikou", "履行", "rikou", [
            ("契約を履行する義務があります。", "Keiyaku o rikou suru gimu ga arimasu.", "Ada kewajiban untuk memenuhi kontrak."),
        ]),
        ("yuuyo", "猶予", "ゆうよ", "yuuyo", "penangguhan", "N1", "noun", "猶予", "yuuyo", "猶予", "yuuyo", [
            ("支払いの猶予をお願いします。", "Shiharai no yuuyo o onegai shimasu.", "Mohon penangguhan pembayaran."),
        ]),
        ("itsudatsu", "逸脱", "いつだつ", "itsudatsu", "penyimpangan", "N1", "noun", "逸脱", "itsudatsu", "逸脱", "itsudatsu", [
            ("規則からの逸脱は許されません。", "Kisoku kara no itsudatsu wa yurusaremasen.", "Penyimpangan dari aturan tidak diizinkan."),
        ]),
        ("choukou", "兆候", "ちょうこう", "choukou", "tanda/gejala", "N1", "noun", "兆候", "choukou", "兆候", "choukou", [
            ("業績回復の兆候が見えます。", "Gyouseki kaifuku no choukou ga miemasu.", "Terlihat tanda-tanda pemulihan kinerja."),
        ]),
        ("heigai", "弊害", "へいがい", "heigai", "dampak buruk", "N1", "noun", "弊害", "heigai", "弊害", "heigai", [
            ("この制度には弊害があります。", "Kono seido ni wa heigai ga arimasu.", "Sistem ini memiliki dampak buruk."),
        ]),
        ("daketsu", "妥結", "だけつ", "daketsu", "kesepakatan (negosiasi)", "N1", "noun", "妥結", "daketsu", "妥結", "daketsu", [
            ("交渉はようやく妥結しました。", "Koushou wa youyaku daketsu shimashita.", "Negosiasi akhirnya mencapai kesepakatan."),
        ]),
        ("sesshou", "折衝", "せっしょう", "sesshou", "negosiasi (alot)", "N1", "noun", "折衝", "sesshou", "折衝", "sesshou", [
            ("取引先と折衝を重ねました。", "Torihikisaki to sesshou o kasanemashita.", "Kami melakukan negosiasi berulang kali dengan mitra bisnis."),
        ]),
        ("shisa", "示唆", "しさ", "shisa", "sindiran/isyarat", "N1", "noun", "示唆", "shisa", "示唆", "shisa", [
            ("上司の言葉には示唆が含まれていました。", "Joushi no kotoba ni wa shisa ga fukumarete imashita.", "Kata-kata atasan mengandung sindiran/petunjuk."),
        ]),
        ("sogai", "疎外", "そがい", "sogai", "pengucilan", "N1", "noun", "疎外", "sogai", "疎外", "sogai", [
            ("新人が疎外感を感じています。", "Shinjin ga sogaikan o kanjite imasu.", "Karyawan baru merasa dikucilkan."),
        ]),
        ("jousei", "醸成", "じょうせい", "jousei", "pembentukan (suasana/situasi)", "N1", "noun", "醸成", "jousei", "醸成", "jousei", [
            ("チームの一体感を醸成します。", "Chiimu no ittaikan o jousei shimasu.", "Kami membangun rasa kebersamaan tim."),
        ]),
        ("hakyuu", "波及", "はきゅう", "hakyuu", "efek berantai/menyebar", "N1", "noun", "波及", "hakyuu", "波及", "hakyuu", [
            ("影響が他の部署にも波及しました。", "Eikyou ga hoka no busho ni mo hakyuu shimashita.", "Dampaknya menyebar ke departemen lain juga."),
        ]),
        ("enkatsu", "円滑", "えんかつ", "enkatsu", "kelancaran", "N1", "adjective", "円滑", "enkatsu", "円滑", "enkatsu", [
            ("業務を円滑に進めます。", "Gyoumu o enkatsu ni susumemasu.", "Kami menjalankan pekerjaan dengan lancar."),
        ]),
        # N2 addition (2026-07-20): common business 2-kanji compounds, added
        # to raise Kanji Kombinasi's N2 pool closer to N5/N4/N3's variety
        # (was 19 words total, thinnest after N1 before this batch).
        ("koushou", "交渉", "こうしょう", "koushou", "negosiasi", "N2", "noun", "交渉", "koushou", "交渉", "koushou", [
            ("取引先と交渉します。", "Torihikisaki to koushou shimasu.", "Saya bernegosiasi dengan mitra bisnis."),
        ]),
        ("teian", "提案", "ていあん", "teian", "usulan/proposal", "N2", "noun", "提案", "teian", "提案", "teian", [
            ("新しい企画を提案しました。", "Atarashii kikaku o teian shimashita.", "Saya mengusulkan rencana baru."),
        ]),
        ("shounin", "承認", "しょうにん", "shounin", "persetujuan", "N2", "noun", "承認", "shounin", "承認", "shounin", [
            ("上司の承認をもらいました。", "Joushi no shounin o moraimashita.", "Saya mendapat persetujuan dari atasan."),
        ]),
        ("shoushin", "昇進", "しょうしん", "shoushin", "kenaikan jabatan/promosi", "N2", "noun", "昇進", "shoushin", "昇進", "shoushin", [
            ("来月、昇進します。", "Raigetsu, shoushin shimasu.", "Bulan depan, saya naik jabatan."),
        ]),
        ("kaiko", "解雇", "かいこ", "kaiko", "pemecatan", "N2", "noun", "解雇", "kaiko", "解雇", "kaiko", [
            ("彼は会社を解雇されました。", "Kare wa kaisha o kaiko saremashita.", "Dia dipecat dari perusahaan."),
        ]),
        ("keiei", "経営", "けいえい", "keiei", "manajemen/pengelolaan (usaha)", "N2", "noun", "経営", "keiei", "経営", "keiei", [
            ("父は会社を経営しています。", "Chichi wa kaisha o keiei shite imasu.", "Ayah saya mengelola sebuah perusahaan."),
        ]),
        ("gyouseki", "業績", "ぎょうせき", "gyouseki", "kinerja/prestasi (perusahaan)", "N2", "noun", "業績", "gyouseki", "業績", "gyouseki", [
            ("今年の業績はよかったです。", "Kotoshi no gyouseki wa yokatta desu.", "Kinerja tahun ini bagus."),
        ]),
        ("akaji", "赤字", "あかじ", "akaji", "defisit/kerugian", "N2", "noun", "赤字", "akaji", "赤字", "akaji", [
            ("今月は赤字になりました。", "Kongetsu wa akaji ni narimashita.", "Bulan ini mengalami defisit."),
        ]),
        ("kuroji", "黒字", "くろじ", "kuroji", "surplus/keuntungan", "N2", "noun", "黒字", "kuroji", "黒字", "kuroji", [
            ("会社は黒字に転換しました。", "Kaisha wa kuroji ni tenkan shimashita.", "Perusahaan itu berbalik meraih keuntungan."),
        ]),
        ("tousan", "倒産", "とうさん", "tousan", "kebangkrutan", "N2", "noun", "倒産", "tousan", "倒産", "tousan", [
            ("その会社は倒産しました。", "Sono kaisha wa tousan shimashita.", "Perusahaan itu bangkrut."),
        ]),
        ("gappei", "合併", "がっぺい", "gappei", "penggabungan/merger", "N2", "noun", "合併", "gappei", "合併", "gappei", [
            ("二つの会社が合併しました。", "Futatsu no kaisha ga gappei shimashita.", "Dua perusahaan itu melakukan merger."),
        ]),
        ("insatsu", "印刷", "いんさつ", "insatsu", "percetakan/cetak", "N2", "noun", "印刷", "insatsu", "印刷", "insatsu", [
            ("資料を印刷します。", "Shiryou o insatsu shimasu.", "Saya mencetak dokumen."),
        ]),
        ("eigyou", "営業", "えいぎょう", "eigyou", "operasi bisnis", "N2", "noun", "営業", "eigyou", "営業", "eigyou", [
            ("会社は9時から営業します。", "Kaisha wa kuji kara eigyou shimasu.", "Perusahaan beroperasi dari jam 9. (usaha berjalan/buka)"),
        ]),
        ("enki", "延期", "えんき", "enki", "penundaan", "N2", "noun", "延期", "enki", "延期", "enki", [
            ("会議は延期になりました。", "Kaigi wa enki ni narimashita.", "Rapat ditunda."),
        ]),
        ("oubo", "応募", "おうぼ", "oubo", "melamar/mendaftar", "N2", "noun", "応募", "oubo", "応募", "oubo", [
            ("仕事に応募しました。", "Shigoto ni oubo shimashita.", "Melamar pekerjaan."),
        ]),
        ("kaikei", "会計", "かいけい", "kaikei", "akuntansi/pembayaran", "N2", "noun", "会計", "kaikei", "会計", "kaikei", [
            ("会計をお願いします。", "Kaikei o onegai shimasu.", "Tolong hitung/pembayaran."),
        ]),
        ("kigyou", "企業", "きぎょう", "kigyou", "perusahaan", "N2", "noun", "企業", "kigyou", "企業", "kigyou", [
            ("日本企業で働きたいです。", "Nihon kigyou de hatarakitai desu.", "Ingin bekerja di perusahaan Jepang."),
        ]),
        ("kigen", "期限", "きげん", "kigen", "batas waktu", "N2", "noun", "期限", "kigen", "期限", "kigen", [
            ("期限を守ってください。", "Kigen o mamotte kudasai.", "Tolong patuhi batas waktu."),
        ]),
        ("kouen", "講演", "こうえん", "kouen", "ceramah/pidato", "N2", "noun", "講演", "kouen", "講演", "kouen", [
            ("先生が講演します。", "Sensei ga kouen shimasu.", "Guru memberi ceramah. (pidato formal informasi 1 arah)"),
        ]),
        ("kougyou", "工業", "こうぎょう", "kougyou", "industri", "N2", "noun", "工業", "kougyou", "工業", "kougyou", [
            ("工業が発展しています。", "Kougyou ga hatten shite imasu.", "Industri berkembang."),
        ]),
        ("sagyou", "作業", "さぎょう", "sagyou", "pekerjaan/tugas", "N2", "noun", "作業", "sagyou", "作業", "sagyou", [
            ("作業を始めます。", "Sagyou o hajimemasu.", "Memulai pekerjaan."),
        ]),
        ("shiji", "指示", "しじ", "shiji", "instruksi", "N2", "noun", "指示", "shiji", "指示", "shiji", [
            ("上司の指示に従います。", "Joushi no shiji ni shitagaimasu.", "Mengikuti instruksi atasan."),
        ]),
        ("shiten", "支店", "してん", "shiten", "kantor cabang", "N2", "noun", "支店", "shiten", "支店", "shiten", [
            ("大阪支店で働いています。", "Oosaka shiten de hataraite imasu.", "Bekerja di kantor cabang Osaka."),
        ]),
        ("shuushoku", "就職", "しゅうしょく", "shuushoku", "mendapat pekerjaan", "N2", "noun", "就職", "shuushoku", "就職", "shuushoku", [
            ("日本で就職したいです。", "Nihon de shuushoku shitai desu.", "Ingin bekerja di Jepang. (dapat kerja, diterima kerja)"),
        ]),
        ("shuunyuu", "収入", "しゅうにゅう", "shuunyuu", "pendapatan", "N2", "noun", "収入", "shuunyuu", "収入", "shuunyuu", [
            ("収入が増えました。", "Shuunyuu ga fuemashita.", "Pendapatan bertambah."),
        ]),
        ("shukkin", "出勤", "しゅっきん", "shukkin", "berangkat kerja", "N2", "noun", "出勤", "shukkin", "出勤", "shukkin", [
            ("毎日8時に出勤します。", "Mainichi hachiji ni shukkin shimasu.", "Berangkat kerja tiap jam 8."),
        ]),
        ("shouhin", "商品", "しょうひん", "shouhin", "barang dagangan", "N2", "noun", "商品", "shouhin", "商品", "shouhin", [
            ("商品を並べます。", "Shouhin o narabemasu.", "Menata barang dagangan."),
        ]),
        ("shorui", "書類", "しょるい", "shorui", "dokumen", "N2", "noun", "書類", "shorui", "書類", "shorui", [
            ("書類を提出します。", "Shorui o teishutsu shimasu.", "Mengumpulkan dokumen."),
        ]),
        ("shiryou", "資料", "しりょう", "shiryou", "materi/bahan referensi", "N2", "noun", "資料", "shiryou", "資料", "shiryou", [
            ("資料を配ります。", "Shiryou o kubarimasu.", "Membagikan materi/dokumen."),
        ]),
        ("shinsei", "申請", "しんせい", "shinsei", "pengajuan (permohonan)", "N2", "noun", "申請", "shinsei", "申請", "shinsei", [
            ("ビザを申請します。", "Biza o shinsei shimasu.", "Mengajukan visa."),
        ]),
        ("jikyuu", "時給", "じきゅう", "jikyuu", "upah per jam", "N2", "noun", "時給", "jikyuu", "時給", "jikyuu", [
            ("時給は1000円です。", "Jikyuu wa senen desu.", "Upah per jam 1000 yen."),
        ]),
        ("jimu", "事務", "じむ", "jimu", "administrasi/tata usaha", "N2", "noun", "事務", "jimu", "事務", "jimu", [
            ("事務の仕事をしています。", "Jimu no shigoto o shite imasu.", "Bekerja bagian administrasi."),
        ]),
        ("seisou", "清掃", "せいそう", "seisou", "pembersihan", "N2", "noun", "清掃", "seisou", "清掃", "seisou", [
            ("毎朝清掃します。", "Maiasa seisou shimasu.", "Membersihkan setiap pagi. (kerjaan, profesi)"),
        ]),
        ("senpai", "先輩", "せんぱい", "senpai", "senior", "N2", "noun", "先輩", "senpai", "先輩", "senpai", [
            ("先輩に聞きます。", "Senpai ni kikimasu.", "Bertanya kepada senior."),
        ]),
        ("senmon", "専門", "せんもん", "senmon", "keahlian/spesialisasi", "N2", "noun", "専門", "senmon", "専門", "senmon", [
            ("日本語が専門です。", "Nihongo ga senmon desu.", "Keahlian saya bahasa Jepang."),
        ]),
        ("daihyou", "代表", "だいひょう", "daihyou", "perwakilan", "N2", "noun", "代表", "daihyou", "代表", "daihyou", [
            ("私が代表です。", "Watashi ga daihyou desu.", "Saya adalah perwakilan."),
        ]),
        ("chikoku", "遅刻", "ちこく", "chikoku", "keterlambatan", "N2", "noun", "遅刻", "chikoku", "遅刻", "chikoku", [
            ("遅刻しました。", "Chikoku shimashita.", "Saya terlambat."),
        ]),
        ("chousa", "調査", "ちょうさ", "chousa", "penelitian/survei", "N2", "noun", "調査", "chousa", "調査", "chousa", [
            ("市場を調査します。", "Shijou o chousa shimasu.", "Meneliti pasar."),
        ]),
        ("tsuukin", "通勤", "つうきん", "tsuukin", "pergi kerja (naik kendaraan)", "N2", "noun", "通勤", "tsuukin", "通勤", "tsuukin", [
            ("バスで通勤します。", "Basu de tsuukin shimasu.", "Pergi kerja naik bus."),
        ]),
        ("tenkin", "転勤", "てんきん", "tenkin", "pindah tugas kerja", "N2", "noun", "転勤", "tenkin", "転勤", "tenkin", [
            ("来月大阪へ転勤します。", "Raigetsu Oosaka e tenkin shimasu.", "Bulan depan saya dipindahtugaskan ke Osaka."),
        ]),
        ("haitatsu", "配達", "はいたつ", "haitatsu", "pengantaran", "N2", "noun", "配達", "haitatsu", "配達", "haitatsu", [
            ("荷物を配達します。", "Nimotsu o haitatsu shimasu.", "Mengantarkan paket. (Delivery)"),
        ]),
        ("hatsubai", "発売", "はつばい", "hatsubai", "peluncuran (produk baru)", "N2", "noun", "発売", "hatsubai", "発売", "hatsubai", [
            ("新商品が発売されました。", "Shin shouhin ga hatsubai saremashita.", "Produk baru telah dirilis."),
        ]),
        ("houkoku", "報告", "ほうこく", "houkoku", "laporan", "N2", "noun", "報告", "houkoku", "報告", "houkoku", [
            ("先生に報告します。", "Sensei ni houkoku shimasu.", "Melapor kepada guru."),
        ]),
        ("houmon", "訪問", "ほうもん", "houmon", "kunjungan (resmi)", "N2", "noun", "訪問", "houmon", "訪問", "houmon", [
            ("会社を訪問しました。", "Kaisha o houmon shimashita.", "Mengunjungi perusahaan. (Kunjungan resmi / bisnis)"),
        ]),
        ("boueki", "貿易", "ぼうえき", "boueki", "perdagangan", "N2", "noun", "貿易", "boueki", "貿易", "boueki", [
            ("日本とインドは貿易をしています。", "Nihon to Indo wa boueki o shite imasu.", "Jepang dan India melakukan perdagangan."),
        ]),
        ("boshuu", "募集", "ぼしゅう", "boshuu", "perekrutan", "N2", "noun", "募集", "boshuu", "募集", "boshuu", [
            ("新しい社員を募集しています。", "Atarashii shain o boshuu shite imasu.", "Sedang merekrut karyawan baru."),
        ]),
        ("meirei", "命令", "めいれい", "meirei", "perintah", "N2", "noun", "命令", "meirei", "命令", "meirei", [
            ("上司が命令しました。", "Joushi ga meirei shimashita.", "Atasan memberi perintah."),
        ]),
        ("mensetsu", "面接", "めんせつ", "mensetsu", "wawancara", "N2", "noun", "面接", "mensetsu", "面接", "mensetsu", [
            ("明日会社の面接があります。", "Ashita kaisha no mensetsu ga arimasu.", "Besok ada wawancara perusahaan."),
        ]),
        ("yunyuu", "輸入", "ゆにゅう", "yunyuu", "impor", "N2", "noun", "輸入", "yunyuu", "輸入", "yunyuu", [
            ("日本は多くの食品を輸入している。", "Nihon wa ooku no shokuhin o yunyuu shite iru.", "Jepang mengimpor banyak makanan."),
        ]),
        ("raiten", "来店", "らいてん", "raiten", "kedatangan ke toko", "N2", "noun", "来店", "raiten", "来店", "raiten", [
            ("多くのお客様が来店しました。", "Ooku no okyakusama ga raiten shimashita.", "Banyak pelanggan datang ke toko."),
        ]),
        ("shouhinmei", "商品名", "しょうひんめい", "shouhinmei", "nama produk", "N2", "noun", "商品名", "shouhinmei", "商品名", "shouhinmei", [
            ("商品名を教えてください。", "Shouhinmei o oshiete kudasai.", "Tolong beri tahu nama produknya."),
        ]),
        ("fudousan", "不動産", "ふどうさん", "fudousan", "properti/real estat", "N2", "noun", "不動産", "fudousan", "不動産", "fudousan", [
            ("不動産の仕事をしています。", "Fudousan no shigoto o shite imasu.", "Bekerja di bidang properti."),
        ]),
        # Moved here from konsep_umum: 減少 (genshou, "penurunan") is a
        # genuine reading collision with konsep_umum's own 現象 (genshou,
        # "fenomena") - different category avoids two identical-reading
        # options ever appearing together in the same quiz pool.
        ("genshou", "減少", "げんしょう", "genshou", "penurunan (jumlah)", "N2", "noun", "減少", "genshou", "減少", "genshou", [
            ("人口が減少しています。", "Jinkou ga genshou shite imasu.", "Populasi menurun."),
        ]),
        ("gichou", "議長", "ぎちょう", "gichou", "ketua rapat/pimpinan sidang", "N3", "noun", "議長", "gichou", "議長", "gichou", [
            ("議長が発言します。", "Gichou ga hatsugen shimasu.", "Ketua rapat berbicara."),
        ]),
        ("hanbai", "販売", "はんばい", "hanbai", "penjualan", "N3", "noun", "販売", "hanbai", "販売", "hanbai", [
            ("商品を販売します。", "Shouhin o hanbai shimasu.", "Menjual barang dagangan."),
        ]),
        ("kaigou", "会合", "かいごう", "kaigou", "pertemuan/rapat", "N3", "noun", "会合", "kaigou", "会合", "kaigou", [
            ("会合に出席します。", "Kaigou ni shusseki shimasu.", "Menghadiri pertemuan."),
        ]),
        ("kinyuu", "記入", "きにゅう", "kinyuu", "mengisi (formulir)", "N3", "noun", "記入", "kinyuu", "記入", "kinyuu", [
            ("名前を記入します。", "Namae o kinyuu shimasu.", "Mengisi nama."),
        ]),
        ("rieki", "利益", "りえき", "rieki", "keuntungan/laba", "N3", "noun", "利益", "rieki", "利益", "rieki", [
            ("利益が増えました。", "Rieki ga fuemashita.", "Keuntungan bertambah."),
        ]),
        ("seihin", "製品", "せいひん", "seihin", "produk (hasil manufaktur)", "N3", "noun", "製品", "seihin", "製品", "seihin", [
            ("新しい製品を作ります。", "Atarashii seihin o tsukurimasu.", "Membuat produk baru."),
        ]),
        ("shihon", "資本", "しほん", "shihon", "modal (dana)", "N3", "noun", "資本", "shihon", "資本", "shihon", [
            ("資本を集めます。", "Shihon o atsumemasu.", "Mengumpulkan modal."),
        ]),
        ("shoubai", "商売", "しょうばい", "shoubai", "perdagangan/bisnis", "N3", "noun", "商売", "shoubai", "商売", "shoubai", [
            ("商売を始めます。", "Shoubai o hajimemasu.", "Mulai berbisnis."),
        ]),
        ("yushutsu", "輸出", "ゆしゅつ", "yushutsu", "ekspor", "N3", "noun", "輸出", "yushutsu", "輸出", "yushutsu", [
            ("車を輸出します。", "Kuruma o yushutsu shimasu.", "Mengekspor mobil."),
        ]),
        ("baishuu", "買収", "ばいしゅう", "baishuu", "akuisisi/pengambilalihan", "N1", "noun", "買収", "baishuu", "買収", "baishuu", [
            ("会社を買収しました。", "Kaisha o baishuu shimashita.", "Mengakuisisi perusahaan."),
        ]),
        ("bengo", "弁護", "べんご", "bengo", "pembelaan (hukum)", "N1", "noun", "弁護", "bengo", "弁護", "bengo", [
            ("弁護士が弁護します。", "Bengoshi ga bengo shimasu.", "Pengacara melakukan pembelaan."),
        ]),
        ("bunsho", "文書", "ぶんしょ", "bunsho", "dokumen", "N1", "noun", "文書", "bunsho", "文書", "bunsho", [
            ("文書を作成します。", "Bunsho o sakusei shimasu.", "Membuat dokumen."),
        ]),
        ("chakushu", "着手", "ちゃくしゅ", "chakushu", "mulai mengerjakan", "N1", "noun", "着手", "chakushu", "着手", "chakushu", [
            ("計画に着手します。", "Keikaku ni chakushu shimasu.", "Mulai mengerjakan rencana."),
        ]),
        ("chingin", "賃金", "ちんぎん", "chingin", "upah", "N1", "noun", "賃金", "chingin", "賃金", "chingin", [
            ("賃金が上がりました。", "Chingin ga agarimashita.", "Upah naik."),
        ]),
        ("choutatsu", "調達", "ちょうたつ", "choutatsu", "pengadaan (dana/barang)", "N1", "noun", "調達", "choutatsu", "調達", "choutatsu", [
            ("資金を調達します。", "Shikin o choutatsu shimasu.", "Mengumpulkan dana."),
        ]),
        ("dokusen", "独占", "どくせん", "dokusen", "monopoli", "N1", "noun", "独占", "dokusen", "独占", "dokusen", [
            ("市場を独占しています。", "Shijou o dokusen shite imasu.", "Memonopoli pasar."),
        ]),
        ("gyoumu", "業務", "ぎょうむ", "gyoumu", "urusan bisnis/tugas kerja", "N1", "noun", "業務", "gyoumu", "業務", "gyoumu", [
            ("業務を分担します。", "Gyoumu o buntan shimasu.", "Membagi tugas kerja."),
        ]),
        ("haichi", "配置", "はいち", "haichi", "penempatan", "N1", "noun", "配置", "haichi", "配置", "haichi", [
            ("社員を配置します。", "Shain o haichi shimasu.", "Menempatkan karyawan."),
        ]),
        ("haken", "派遣", "はけん", "haken", "pengiriman/penugasan (staf)", "N1", "noun", "派遣", "haken", "派遣", "haken", [
            ("社員を派遣します。", "Shain o haken shimasu.", "Mengirim karyawan (ke lokasi tugas)."),
        ]),
        ("hoken", "保険", "ほけん", "hoken", "asuransi", "N1", "noun", "保険", "hoken", "保険", "hoken", [
            ("保険に入ります。", "Hoken ni hairimasu.", "Mengikuti asuransi."),
        ]),
        ("housaku", "方策", "ほうさく", "housaku", "kebijakan/strategi", "N1", "noun", "方策", "housaku", "方策", "housaku", [
            ("新しい方策を考えます。", "Atarashii housaku o kangaemasu.", "Memikirkan strategi baru."),
        ]),
        ("houshuu", "報酬", "ほうしゅう", "houshuu", "imbalan/upah", "N1", "noun", "報酬", "houshuu", "報酬", "houshuu", [
            ("報酬をもらいます。", "Houshuu o moraimasu.", "Menerima imbalan."),
        ]),
        ("jigyou", "事業", "じぎょう", "jigyou", "usaha/bisnis", "N1", "noun", "事業", "jigyou", "事業", "jigyou", [
            ("新しい事業を始めます。", "Atarashii jigyou o hajimemasu.", "Memulai usaha baru."),
        ]),
        ("kabushiki", "株式", "かぶしき", "kabushiki", "saham", "N1", "noun", "株式", "kabushiki", "株式", "kabushiki", [
            ("株式を購入します。", "Kabushiki o kounyuu shimasu.", "Membeli saham."),
        ]),
    ],
    "teknologi_gadget": [
        ("konpyuutaa", None, "コンピューター", "konpyuutaa", "komputer", "N4", "noun", "コンピューター", "konpyuutaa", "コンピューター", "konpyuutaa", [
            ("コンピューターを使います。", "Konpyuutaa o tsukaimasu.", "Saya menggunakan komputer."),
        ]),
        ("sumaho", None, "スマホ", "sumaho", "smartphone (hp pintar)", "N4", "noun", "スマホ", "sumaho", "スマホ", "sumaho", [
            ("スマホで写真を撮ります。", "Sumaho de shashin o torimasu.", "Saya memotret dengan HP."),
        ]),
        ("keitai", "携帯", "けいたい", "keitai", "ponsel (istilah umum)", "N4", "noun", "携帯", "keitai", "携帯", "keitai", [
            ("携帯を忘れました。", "Keitai o wasuremashita.", "Saya lupa membawa ponsel."),
        ]),
        ("intaanetto", None, "インターネット", "intaanetto", "internet", "N4", "noun", "インターネット", "intaanetto", "インターネット", "intaanetto", [
            ("インターネットを使います。", "Intaanetto o tsukaimasu.", "Saya menggunakan internet."),
        ]),
        ("denwa", "電話", "でんわ", "denwa", "telepon", "N5", "noun", "電話", "denwa", "電話", "denwa", [
            ("電話をかけます。", "Denwa o kakemasu.", "Saya menelepon."),
        ]),
        ("meeru", None, "メール", "meeru", "email", "N4", "noun", "メール", "meeru", "メール", "meeru", [
            ("メールを送ります。", "Meeru o okurimasu.", "Saya mengirim email."),
        ]),
        ("apuri", None, "アプリ", "apuri", "aplikasi (app)", "N3", "noun", "アプリ", "apuri", "アプリ", "apuri", [
            ("アプリをダウンロードします。", "Apuri o daunroodo shimasu.", "Saya mengunduh aplikasi."),
        ]),
        ("kamera", None, "カメラ", "kamera", "kamera", "N4", "noun", "カメラ", "kamera", "カメラ", "kamera", [
            ("カメラで撮ります。", "Kamera de torimasu.", "Saya memotret dengan kamera."),
        ]),
        ("juuden", "充電", "じゅうでん", "juuden", "mengisi daya (charge)", "N3", "noun", "充電", "juuden", "充電", "juuden", [
            ("スマホを充電します。", "Sumaho o juuden shimasu.", "Saya mengisi daya HP."),
        ]),
        ("waifai", None, "ワイファイ", "waifai", "wifi", "N4", "noun", "ワイファイ", "waifai", "ワイファイ", "waifai", [
            ("ワイファイに繋げます。", "Waifai ni tsunagemasu.", "Saya menyambungkan ke wifi."),
        ]),
        # N1/N2 addition (2026-07-20, third batch): pure-kanji tech/science
        # nouns, for Kombinasi Kanji pool depth — this category was
        # previously almost all katakana loanwords (no kanji at all), so
        # none of it counted toward the compound pool despite being a
        # natural tech-vocabulary home.
        ("kakushin", "革新", "かくしん", "kakushin", "inovasi/pembaruan", "N1", "noun", "革新", "kakushin", "革新", "kakushin", [
            ("この技術は業界に革新をもたらしました。", "Kono gijutsu wa gyoukai ni kakushin o motarashimashita.", "Teknologi ini membawa inovasi bagi industri."),
        ]),
        ("fukyuu", "普及", "ふきゅう", "fukyuu", "penyebaran/pemasyarakatan (teknologi)", "N1", "noun", "普及", "fukyuu", "普及", "fukyuu", [
            ("スマートフォンが急速に普及しました。", "Sumaatofon ga kyuusoku ni fukyuu shimashita.", "Smartphone menyebar dengan cepat."),
        ]),
        ("shinka", "進化", "しんか", "shinka", "evolusi/perkembangan", "N2", "noun", "進化", "shinka", "進化", "shinka", [
            ("技術は日々進化しています。", "Gijutsu wa hibi shinka shite imasu.", "Teknologi berevolusi setiap hari."),
        ]),
        ("ouyou", "応用", "おうよう", "ouyou", "penerapan/aplikasi (teori)", "N2", "noun", "応用", "ouyou", "応用", "ouyou", [
            ("この理論は実生活に応用できます。", "Kono riron wa jisseikatsu ni ouyou dekimasu.", "Teori ini bisa diterapkan dalam kehidupan sehari-hari."),
        ]),
        ("seimitsu", "精密", "せいみつ", "seimitsu", "presisi/ketelitian", "N1", "noun", "精密", "seimitsu", "精密", "seimitsu", [
            ("精密な機械を作っています。", "Seimitsu na kikai o tsukutte imasu.", "Kami membuat mesin yang presisi."),
        ]),
        ("hanyou", "汎用", "はんよう", "hanyou", "serbaguna (kegunaan umum)", "N1", "noun", "汎用", "hanyou", "汎用", "hanyou", [
            ("これは汎用性の高いソフトです。", "Kore wa hanyousei no takai sofuto desu.", "Ini perangkat lunak yang sangat serbaguna."),
        ]),
        # N2/N3 addition (2026-07-20, eleventh batch): everyday tech-usage
        # nouns (distinct from the abstract N1/N2 pair above), for
        # Kombinasi Kanji pool depth. "kinou" (機能, function) is a real
        # homophone of 昨日 (kinou, "yesterday") in hari_bulan — different
        # category, so no ambiguity for learners, but the id suffix is
        # disambiguated to kinou2 to avoid a duplicate id.
        ("jouhou", "情報", "じょうほう", "jouhou", "informasi", "N3", "noun", "情報", "jouhou", "情報", "jouhou", [
            ("インターネットで情報を調べます。", "Intaanetto de jouhou o shirabemasu.", "Saya mencari informasi di internet."),
        ]),
        ("shori", "処理", "しょり", "shori", "pemrosesan", "N2", "noun", "処理", "shori", "処理", "shori", [
            ("データを処理します。", "Deeta o shori shimasu.", "Saya memproses data."),
        ]),
        ("koushin", "更新", "こうしん", "koushin", "pembaruan (update)", "N2", "noun", "更新", "koushin", "更新", "koushin", [
            ("アプリを更新します。", "Apuri o koushin shimasu.", "Saya memperbarui aplikasi."),
        ]),
        ("setsuzoku", "接続", "せつぞく", "setsuzoku", "koneksi/penyambungan", "N2", "noun", "接続", "setsuzoku", "接続", "setsuzoku", [
            ("ワイファイに接続します。", "Waifai ni setsuzoku shimasu.", "Saya menyambungkan ke wifi."),
        ]),
        ("gamen", "画面", "がめん", "gamen", "layar", "N3", "noun", "画面", "gamen", "画面", "gamen", [
            ("画面が割れました。", "Gamen ga waremashita.", "Layarnya pecah."),
        ]),
        ("kinou2", "機能", "きのう", "kinou", "fungsi", "N3", "noun", "機能", "kinou", "機能", "kinou", [
            ("このアプリには便利な機能があります。", "Kono apuri ni wa benri na kinou ga arimasu.", "Aplikasi ini punya fungsi yang berguna."),
        ]),
        ("sousa", "操作", "そうさ", "sousa", "pengoperasian", "N3", "noun", "操作", "sousa", "操作", "sousa", [
            ("機械を操作します。", "Kikai o sousa shimasu.", "Saya mengoperasikan mesin."),
        ]),
        # N1/N2 addition (2026-07-20, twelfth batch): telecom nouns, for
        # Kombinasi Kanji pool depth.
        ("tsuushin", "通信", "つうしん", "tsuushin", "telekomunikasi", "N2", "noun", "通信", "tsuushin", "通信", "tsuushin", [
            ("通信速度が遅いです。", "Tsuushin sokudo ga osoi desu.", "Kecepatan telekomunikasinya lambat."),
        ]),
        ("tanmatsu", "端末", "たんまつ", "tanmatsu", "terminal/perangkat", "N1", "noun", "端末", "tanmatsu", "端末", "tanmatsu", [
            ("この端末は古いです。", "Kono tanmatsu wa furui desu.", "Perangkat ini sudah tua."),
        ]),
        # N3 addition (2026-07-20, thirteenth batch): more everyday
        # tech-usage nouns, for Kombinasi Kanji pool depth.
        ("kensaku", "検索", "けんさく", "kensaku", "pencarian", "N3", "noun", "検索", "kensaku", "検索", "kensaku", [
            ("インターネットで検索します。", "Intaanetto de kensaku shimasu.", "Saya mencari di internet."),
        ]),
        ("hozon", "保存", "ほぞん", "hozon", "penyimpanan (data)", "N3", "noun", "保存", "hozon", "保存", "hozon", [
            ("ファイルを保存します。", "Fairu o hozon shimasu.", "Saya menyimpan berkas."),
        ]),
        ("kikai", "機械", "きかい", "kikai", "mesin", "N2", "noun", "機械", "kikai", "機械", "kikai", [
            ("機械を操作します。", "Kikai o sousa shimasu.", "Mengoperasikan mesin."),
        ]),
        ("gijutsu", "技術", "ぎじゅつ", "gijutsu", "teknik/keterampilan", "N2", "noun", "技術", "gijutsu", "技術", "gijutsu", [
            ("技術を学びます。", "Gijutsu o manabimasu.", "Mempelajari teknik/keterampilan."),
        ]),
        ("soushin", "送信", "そうしん", "soushin", "pengiriman (data/email)", "N2", "noun", "送信", "soushin", "送信", "soushin", [
            ("メールを送信しました。", "Meeru o soushin shimashita.", "Sudah mengirim email."),
        ]),
        ("nyuuryoku", "入力", "にゅうりょく", "nyuuryoku", "input (data)", "N2", "noun", "入力", "nyuuryoku", "入力", "nyuuryoku", [
            ("パスワードを入力して下さい。", "Pasuwaado o nyuuryoku shite kudasai.", "Silakan masukkan password."),
        ]),
        ("buhin", "部品", "ぶひん", "buhin", "komponen/onderdil", "N2", "noun", "部品", "buhin", "部品", "buhin", [
            ("この部品は必要です。", "Kono buhin wa hitsuyou desu.", "Komponen ini diperlukan."),
        ]),
        ("hatsumei", "発明", "はつめい", "hatsumei", "penemuan (inovasi)", "N3", "noun", "発明", "hatsumei", "発明", "hatsumei", [
            ("新しい機械を発明しました。", "Atarashii kikai o hatsumei shimashita.", "Menemukan mesin baru."),
        ]),
        ("kyouryoku", "強力", "きょうりょく", "kyouryoku", "kuat/tangguh", "N3", "noun", "強力", "kyouryoku", "強力", "kyouryoku", [
            ("強力な機械です。", "Kyouryoku na kikai desu.", "Mesin yang kuat."),
        ]),
        ("gousei", "合成", "ごうせい", "gousei", "sintesis/gabungan", "N1", "noun", "合成", "gousei", "合成", "gousei", [
            ("合成写真を作ります。", "Gousei shashin o tsukurimasu.", "Membuat foto hasil gabungan (edit)."),
        ]),
        ("kaihatsu", "開発", "かいはつ", "kaihatsu", "pengembangan", "N1", "noun", "開発", "kaihatsu", "開発", "kaihatsu", [
            ("新製品を開発します。", "Shin seihin o kaihatsu shimasu.", "Mengembangkan produk baru."),
        ]),
    ],
    "media_hiburan": [
        ("terebi", None, "テレビ", "terebi", "televisi", "N5", "noun", "テレビ", "terebi", "テレビ", "terebi", [
            ("テレビを見ます。", "Terebi o mimasu.", "Saya menonton televisi."),
        ]),
        ("manga", "漫画", "まんが", "manga", "komik (manga)", "N4", "noun", "漫画", "manga", "漫画", "manga", [
            ("漫画を読みます。", "Manga o yomimasu.", "Saya membaca komik."),
        ]),
        ("anime", None, "アニメ", "anime", "animasi (anime)", "N4", "noun", "アニメ", "anime", "アニメ", "anime", [
            ("アニメが好きです。", "Anime ga suki desu.", "Saya suka anime."),
        ]),
        ("shinbun", "新聞", "しんぶん", "shinbun", "koran", "N4", "noun", "新聞", "shinbun", "新聞", "shinbun", [
            ("新聞を読みます。", "Shinbun o yomimasu.", "Saya membaca koran."),
        ]),
        ("zasshi", "雑誌", "ざっし", "zasshi", "majalah", "N4", "noun", "雑誌", "zasshi", "雑誌", "zasshi", [
            ("雑誌を買いました。", "Zasshi o kaimashita.", "Saya membeli majalah."),
        ]),
        ("rajio", None, "ラジオ", "rajio", "radio", "N4", "noun", "ラジオ", "rajio", "ラジオ", "rajio", [
            ("ラジオを聴きます。", "Rajio o kikimasu.", "Saya mendengarkan radio."),
        ]),
        ("nyuusu", None, "ニュース", "nyuusu", "berita", "N4", "noun", "ニュース", "nyuusu", "ニュース", "nyuusu", [
            ("ニュースを見ます。", "Nyuusu o mimasu.", "Saya menonton berita."),
        ]),
        ("dorama", None, "ドラマ", "dorama", "drama (serial TV)", "N3", "noun", "ドラマ", "dorama", "ドラマ", "dorama", [
            ("ドラマを見ます。", "Dorama o mimasu.", "Saya menonton drama."),
        ]),
        ("yuuchuubu", None, "ユーチューブ", "yuuchuubu", "YouTube", "N3", "noun", "ユーチューブ", "yuuchuubu", "ユーチューブ", "yuuchuubu", [
            ("ユーチューブで動画を見ます。", "Yuuchuubu de douga o mimasu.", "Saya menonton video di YouTube."),
        ]),
        ("sns", None, "SNS", "esu-enu-esu", "media sosial", "N3", "noun", "SNS", "esu-enu-esu", "SNS", "esu-enu-esu", [
            ("SNSを使います。", "SNS o tsukaimasu.", "Saya menggunakan media sosial."),
        ]),
        # N1 addition (2026-07-20, second batch): formal journalism/media
        # vocabulary — a second, thematically distinct pool for Kanji
        # Kombinasi's N1 mode beyond pekerjaan_kantor's business register,
        # so N1 exam questions don't all read like the same workplace memo.
        ("ken'etsu", "検閲", "けんえつ", "ken'etsu", "sensor (media/pers)", "N1", "noun", "検閲", "ken'etsu", "検閲", "ken'etsu", [
            ("その国では報道が検閲されています。", "Sono kuni de wa houdou ga ken'etsu sarete imasu.", "Di negara itu, pemberitaan disensor."),
        ]),
        ("netsuzou", "捏造", "ねつぞう", "netsuzou", "pemalsuan/rekayasa (berita)", "N1", "noun", "捏造", "netsuzou", "捏造", "netsuzou", [
            ("その記事は捏造だと分かりました。", "Sono kiji wa netsuzou da to wakarimashita.", "Artikel itu ternyata rekayasa/palsu."),
        ]),
        ("inpei", "隠蔽", "いんぺい", "inpei", "penyembunyian/penutupan (fakta)", "N1", "noun", "隠蔽", "inpei", "隠蔽", "inpei", [
            ("会社は問題を隠蔽していました。", "Kaisha wa mondai o inpei shite imashita.", "Perusahaan itu menutup-nutupi masalahnya."),
        ]),
        ("okusoku", "憶測", "おくそく", "okusoku", "spekulasi/dugaan", "N1", "noun", "憶測", "okusoku", "憶測", "okusoku", [
            ("憶測で記事を書くべきではありません。", "Okusoku de kiji o kaku beki de wa arimasen.", "Tidak seharusnya menulis artikel berdasarkan spekulasi."),
        ]),
        ("rotei", "露呈", "ろてい", "rotei", "terbongkarnya/terungkapnya (kelemahan)", "N1", "noun", "露呈", "rotei", "露呈", "rotei", [
            ("会見で問題点が露呈しました。", "Kaiken de mondaiten ga rotei shimashita.", "Titik masalahnya terungkap dalam konferensi pers."),
        ]),
        # N2/N3 addition (2026-07-20, eleventh batch): everyday broadcast/
        # media-industry nouns, for Kombinasi Kanji pool depth.
        ("koukoku", "広告", "こうこく", "koukoku", "iklan", "N3", "noun", "広告", "koukoku", "広告", "koukoku", [
            ("テレビで広告を見ます。", "Terebi de koukoku o mimasu.", "Saya melihat iklan di televisi."),
        ]),
        ("housou", "放送", "ほうそう", "housou", "siaran", "N3", "noun", "放送", "housou", "放送", "housou", [
            ("この番組は毎週放送されます。", "Kono bangumi wa maishuu housou saremasu.", "Acara ini disiarkan setiap minggu."),
        ]),
        ("haishin", "配信", "はいしん", "haishin", "streaming/distribusi (konten)", "N2", "noun", "配信", "haishin", "配信", "haishin", [
            ("新しいドラマが配信されました。", "Atarashii dorama ga haishin saremashita.", "Drama baru sudah dirilis untuk streaming."),
        ]),
        ("eizou", "映像", "えいぞう", "eizou", "rekaman video/visual", "N2", "noun", "映像", "eizou", "映像", "eizou", [
            ("その映像はとても美しいです。", "Sono eizou wa totemo utsukushii desu.", "Rekaman visual itu sangat indah."),
        ]),
        ("kiji", "記事", "きじ", "kiji", "artikel (berita)", "N2", "noun", "記事", "kiji", "記事", "kiji", [
            ("新聞の記事を読みます。", "Shinbun no kiji o yomimasu.", "Membaca artikel koran."),
        ]),
        ("genkou", "原稿", "げんこう", "genkou", "naskah", "N2", "noun", "原稿", "genkou", "原稿", "genkou", [
            ("原稿を書いています。", "Genkou o kaite imasu.", "Sedang menulis naskah."),
        ]),
        ("senden", "宣伝", "せんでん", "senden", "iklan/promosi", "N2", "noun", "宣伝", "senden", "宣伝", "senden", [
            ("新商品を宣伝します。", "Shin shouhin o senden shimasu.", "Mengiklankan produk baru."),
        ]),
        ("toujou", "登場", "とうじょう", "toujou", "kemunculan/tampil", "N2", "noun", "登場", "toujou", "登場", "toujou", [
            ("先生が教室に登場しました。", "Sensei ga kyoushitsu ni toujou shimashita.", "Guru muncul di kelas. (acara, cerita,film panggung)"),
        ]),
        ("monogatari", "物語", "ものがたり", "monogatari", "cerita/dongeng", "N2", "noun", "物語", "monogatari", "物語", "monogatari", [
            ("面白い物語を読みました。", "Omoshiroi monogatari o yomimashita.", "Saya membaca cerita yang menarik. (Dongeng)"),
        ]),
        ("shuukan", "週刊", "しゅうかん", "shuukan", "terbitan mingguan", "N3", "noun", "週刊", "shuukan", "週刊", "shuukan", [
            ("週刊誌を読みます。", "Shuukanshi o yomimasu.", "Membaca majalah mingguan."),
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
