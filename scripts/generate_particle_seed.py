import json

from particle_lists import AKHIR_KALIMAT_PARTICLES, KASUS_PARTICLES, KETERANGAN_PARTICLES

# Seed data for the Partikel module.
#
# Each particle tuple: (id_suffix, particle, particle_romaji, overview,
#                       similar_particles, functions)
# similar_particles: list of other entries' id_suffix (without the
#                     "particle_" prefix) that are easily confused with
#                     this one, e.g. "de" for the に entry.
# functions: list of (func_id, title, explanation, formation,
#                      sentence_examples, cloze_examples) — one tuple per
#                      distinct grammatical function this particle serves.
# sentence_examples: list of (japanese, romaji, translation) — shown in
#                     the notes/encyclopedia display.
# cloze_examples: list of (sentence_before, sentence_after, answer, romaji,
#                  translation) — feeds the mini-game question pool.
#                  sentence_before/after are the text split around the
#                  particle being blanked out; answer is the particle text
#                  that correctly fills the blank (should equal the
#                  entry's own `particle`, since a cloze belongs to one
#                  specific particle's function).

KASUS_ENTRIES = [
    ("ga", "が", "ga",
     "Partikel yang menandai subjek kalimat, baik untuk memperkenalkan "
     "informasi baru maupun sebagai objek kata kerja perasaan/kemampuan "
     "tertentu.",
     ["wa"],
     [
        ("subject", "Menandai subjek kalimat (terutama informasi baru)",
         "が menandai subjek kalimat, terutama saat subjek itu adalah "
         "informasi baru yang belum disebutkan sebelumnya, atau saat "
         "secara spesifik mengidentifikasi SIAPA/APA yang melakukan "
         "sesuatu (menjawab pertanyaan seperti 'siapa yang ~?'). Berbeda "
         "dengan は yang menandai topik yang sudah diketahui/dibicarakan, "
         "が menyoroti subjek itu sendiri.",
         "Kata benda + が + kata kerja/kata sifat",
         [
            ("猫が窓の外にいます。", "Neko ga mado no soto ni imasu.", "Ada kucing di luar jendela."),
            ("だれが来ましたか。", "Dare ga kimashita ka.", "Siapa yang datang?"),
            ("雨が降っています。", "Ame ga futte imasu.", "Hujan sedang turun."),
         ],
         [
            ("猫", "窓の外にいます。", "が", "Neko ga mado no soto ni imasu.", "Ada kucing di luar jendela."),
         ]),
        ("feeling_ability", "Objek kata kerja/kata sifat perasaan, kemampuan, dan keinginan",
         "が juga menandai objek pada kata kerja/kata sifat tertentu yang "
         "mengekspresikan perasaan, kemampuan, atau keinginan, seperti "
         "わかる (mengerti), できる (bisa), ほしい (ingin benda), 好き/嫌い "
         "(suka/tidak suka), dan 上手/下手 (pandai/tidak pandai) — "
         "meskipun secara makna terasa seperti 'objek', partikel yang "
         "dipakai tetap が, bukan を.",
         "Kata benda + が + わかる/できる/ほしい/好き/嫌い/上手/下手",
         [
            ("日本語が分かります。", "Nihongo ga wakarimasu.", "Saya mengerti bahasa Jepang."),
            ("水がほしいです。", "Mizu ga hoshii desu.", "Saya ingin air."),
            ("彼女は歌が上手です。", "Kanojo wa uta ga jouzu desu.", "Dia pandai menyanyi."),
         ],
         [
            ("日本語", "分かります。", "が", "Nihongo ga wakarimasu.", "Saya mengerti bahasa Jepang."),
         ]),
     ]),
    ("o", "を", "o",
     "Partikel yang menandai objek langsung dari kata kerja transitif, dan "
     "juga tempat yang dilalui atau ditinggalkan dalam gerakan.",
     [],
     [
        ("direct_object", "Menandai objek langsung",
         "を menandai objek langsung dari kata kerja transitif — benda "
         "yang menerima aksi kata kerja secara langsung.",
         "Kata benda + を + kata kerja transitif",
         [
            ("本を読みます。", "Hon o yomimasu.", "Saya membaca buku."),
            ("コーヒーを飲みます。", "Koohii o nomimasu.", "Saya minum kopi."),
            ("宿題をします。", "Shukudai o shimasu.", "Saya mengerjakan PR."),
         ],
         [
            ("本", "読みます。", "を", "Hon o yomimasu.", "Saya membaca buku."),
         ]),
        ("path", "Tempat yang dilalui atau ditinggalkan (gerakan)",
         "を juga menandai tempat yang dilalui atau ditinggalkan saat "
         "bergerak — dipakai dengan kata kerja seperti 出る (keluar), 降りる "
         "(turun), 歩く (berjalan), 渡る (menyeberang), dan 通る (melewati).",
         "Kata benda (tempat) + を + 出る/降りる/歩く/渡る/通る",
         [
            ("家を出ます。", "Ie o demasu.", "Saya keluar dari rumah."),
            ("橋を渡ります。", "Hashi o watarimasu.", "Saya menyeberangi jembatan."),
            ("バスを降ります。", "Basu o orimasu.", "Saya turun dari bus."),
         ],
         [
            ("橋", "渡ります。", "を", "Hashi o watarimasu.", "Saya menyeberangi jembatan."),
         ]),
     ]),
    ("ni", "に", "ni",
     "Salah satu partikel paling serbaguna dalam bahasa Jepang — menandai "
     "lokasi keberadaan, arah tujuan, waktu spesifik, penerima, dan agen "
     "dalam kalimat pasif, tergantung konteks kata kerjanya.",
     ["de", "e"],
     [
        ("location", "Lokasi keberadaan",
         "に menandai lokasi tempat sesuatu/seseorang berada, dipakai "
         "bersama kata kerja keberadaan seperti いる (untuk makhluk hidup) "
         "dan ある (untuk benda mati), serta 住む (tinggal).",
         "Kata benda (tempat) + に + いる/ある/住む",
         [
            ("東京に住んでいます。", "Tokyo ni sunde imasu.", "Saya tinggal di Tokyo."),
            ("机の上に本があります。", "Tsukue no ue ni hon ga arimasu.", "Ada buku di atas meja."),
            ("公園に猫がいます。", "Kouen ni neko ga imasu.", "Ada kucing di taman."),
         ],
         [
            ("東京", "住んでいます。", "に", "Tokyo ni sunde imasu.", "Saya tinggal di Tokyo."),
         ]),
        ("direction", "Arah/tujuan gerakan",
         "に menandai tujuan gerakan, dipakai dengan kata kerja gerak "
         "seperti 行く (pergi), 来る (datang), dan 帰る (pulang). へ sering "
         "bisa dipakai secara bergantian di sini dengan arti yang sama "
         "persis, terutama untuk menekankan arah perjalanan.",
         "Kata benda (tempat) + に + 行く/来る/帰る",
         [
            ("学校に行きます。", "Gakkou ni ikimasu.", "Saya pergi ke sekolah."),
            ("友達が家に来ます。", "Tomodachi ga ie ni kimasu.", "Teman saya datang ke rumah."),
            ("7時に家に帰ります。", "Shichi-ji ni ie ni kaerimasu.", "Saya pulang ke rumah jam 7."),
         ],
         # Sengaja TANPA cloze_examples: に dan へ benar-benar bisa saling
         # menggantikan di sini dengan arti yang identik (学校に行きます =
         # 学校へ行きます), jadi soal pilihan-ganda apa pun di sini berisiko
         # py dua jawaban yang sama-sama benar tergantung distractor mana
         # yang muncul. Cakupan cloze に tetap terjaga lewat 4 fungsi
         # lainnya (location/time/recipient/passive_agent) yang semuanya
         # unik, tidak tumpang tindih dengan partikel Kasus lain.
         []),
        ("time", "Waktu spesifik",
         "に menandai titik waktu yang spesifik — jam, hari, tanggal, "
         "tahun. Tidak dipakai untuk kata keterangan waktu relatif seperti "
         "今日 (hari ini), 明日 (besok), atau きのう (kemarin), yang "
         "berdiri sendiri tanpa partikel.",
         "Waktu (jam/hari/tanggal) + に + kata kerja",
         [
            ("7時に起きます。", "Shichi-ji ni okimasu.", "Saya bangun jam 7."),
            ("月曜日に試験があります。", "Getsuyoubi ni shiken ga arimasu.", "Ada ujian hari Senin."),
            ("2010年に生まれました。", "Nisen-juu-nen ni umaremashita.", "Saya lahir tahun 2010."),
         ],
         [
            ("7時", "起きます。", "に", "Shichi-ji ni okimasu.", "Saya bangun jam 7."),
         ]),
        ("recipient", "Penerima / objek tidak langsung",
         "に menandai penerima suatu aksi — orang yang dituju oleh kata "
         "kerja seperti あげる (memberi), もらう (menerima dari), 言う "
         "(berkata kepada), dan 送る (mengirim).",
         "Kata benda (orang) + に + あげる/もらう/言う/送る",
         [
            ("友達に手紙を書きます。", "Tomodachi ni tegami o kakimasu.", "Saya menulis surat untuk teman."),
            ("先生にプレゼントをあげました。", "Sensei ni purezento o agemashita.", "Saya memberi hadiah kepada guru."),
            ("母に電話します。", "Haha ni denwa shimasu.", "Saya menelepon ibu."),
         ],
         [
            ("母", "電話します。", "に", "Haha ni denwa shimasu.", "Saya menelepon ibu."),
         ]),
        ("passive_agent", "Agen dalam kalimat pasif",
         "に menandai pelaku/agen dalam kalimat pasif — siapa yang "
         "melakukan aksi terhadap subjek kalimat.",
         "Kata benda (pelaku) + に + kata kerja bentuk pasif (~られる/~れる)",
         [
            ("先生に褒められました。", "Sensei ni homeraremashita.", "Saya dipuji oleh guru."),
            ("犬に噛まれました。", "Inu ni kamaremashita.", "Saya digigit anjing."),
            ("兄に本を取られました。", "Ani ni toraremashita.", "Buku saya diambil oleh kakak laki-laki."),
         ],
         [
            ("先生", "褒められました。", "に", "Sensei ni homeraremashita.", "Saya dipuji oleh guru."),
         ]),
     ]),
    ("de", "で", "de",
     "Partikel yang menandai lokasi terjadinya suatu aksi, alat/cara "
     "melakukan sesuatu, sebab, atau batas cakupan/jumlah total — berbeda "
     "dari に yang menandai lokasi keberadaan (bukan aksi).",
     ["ni"],
     [
        ("location_action", "Lokasi terjadinya aksi",
         "で menandai tempat berlangsungnya suatu aksi/kegiatan — berbeda "
         "dengan に yang menandai lokasi keberadaan pasif (dengan いる/ "
         "ある), で dipakai dengan kata kerja aksi seperti 勉強する "
         "(belajar), 働く (bekerja), dan 遊ぶ (bermain).",
         "Kata benda (tempat) + で + kata kerja aksi",
         [
            ("図書館で勉強します。", "Toshokan de benkyou shimasu.", "Saya belajar di perpustakaan."),
            ("公園で遊びます。", "Kouen de asobimasu.", "Saya bermain di taman."),
            ("会社で働いています。", "Kaisha de hataraite imasu.", "Saya bekerja di kantor."),
         ],
         [
            ("図書館", "勉強します。", "で", "Toshokan de benkyou shimasu.", "Saya belajar di perpustakaan."),
         ]),
        ("means", "Alat/cara/metode",
         "で menandai alat, cara, atau metode melakukan sesuatu.",
         "Kata benda (alat) + で + kata kerja",
         [
            ("バスで行きます。", "Basu de ikimasu.", "Saya pergi naik bus."),
            ("ペンで書きます。", "Pen de kakimasu.", "Saya menulis dengan pena."),
            ("箸で食べます。", "Hashi de tabemasu.", "Saya makan dengan sumpit."),
         ],
         [
            ("ペン", "書きます。", "で", "Pen de kakimasu.", "Saya menulis dengan pena."),
         ]),
        ("cause", "Sebab/alasan",
         "で menandai sebab atau alasan suatu kejadian, terutama untuk "
         "sebab yang berupa kata benda tunggal (bukan kalimat penuh — "
         "untuk itu dipakai から/ので).",
         "Kata benda (sebab) + で + kata kerja/kata sifat",
         [
            ("病気で休みました。", "Byouki de yasumimashita.", "Saya libur karena sakit."),
            ("台風で電車が止まりました。", "Taifuu de densha ga tomarimashita.", "Kereta berhenti karena topan."),
            ("事故で道が込んでいます。", "Jiko de michi ga konde imasu.", "Jalan macet karena kecelakaan."),
         ],
         [
            ("病気", "休みました。", "で", "Byouki de yasumimashita.", "Saya libur karena sakit."),
         ]),
        ("scope_total", "Batas cakupan atau jumlah total",
         "で juga menandai batas cakupan (dalam kurun waktu tertentu) atau "
         "jumlah total keseluruhan — pola tetap seperti 全部で (semuanya "
         "berjumlah), 一人で (sendirian), dan N日で (dalam N hari).",
         "Kata benda (jumlah/durasi) + で + kata kerja/kata sifat",
         [
            ("全部で1000円です。", "Zenbu de sen-en desu.", "Semuanya berjumlah 1000 yen."),
            ("3日で終わります。", "Mikka de owarimasu.", "Selesai dalam 3 hari."),
            ("一人で行きます。", "Hitori de ikimasu.", "Saya pergi sendirian."),
         ],
         [
            ("全部", "1000円です。", "で", "Zenbu de sen-en desu.", "Semuanya berjumlah 1000 yen."),
         ]),
     ]),
    ("to", "と", "to",
     "Partikel yang menandai orang yang menyertai suatu aksi ('bersama'), "
     "kutipan langsung/tidak langsung, penghubung kata benda ('dan', "
     "daftar lengkap), dan syarat otomatis.",
     ["ya"],
     [
        ("with", "'Bersama' (partikel komitatif)",
         "と menandai orang yang menyertai/melakukan sesuatu bersama "
         "subjek.",
         "Kata benda (orang) + と + kata kerja",
         [
            ("友達と映画を見ます。", "Tomodachi to eiga o mimasu.", "Saya menonton film dengan teman."),
            ("家族と旅行します。", "Kazoku to ryokou shimasu.", "Saya bepergian bersama keluarga."),
            ("彼と話しました。", "Kare to hanashimashita.", "Saya berbicara dengannya."),
         ],
         [
            ("友達", "映画を見ます。", "と", "Tomodachi to eiga o mimasu.", "Saya menonton film dengan teman."),
         ]),
        ("quotative", "Penanda kutipan ('bahwa ~')",
         "と menandai isi kutipan langsung atau tidak langsung, dipakai "
         "sebelum kata kerja seperti 言う (berkata), 思う (berpikir), dan "
         "聞く (mendengar).",
         "Kalimat + と + 言う/思う/聞く",
         [
            ("明日雨が降ると思います。", "Ashita ame ga furu to omoimasu.", "Saya pikir besok akan hujan."),
            ("彼は「行く」と言いました。", "Kare wa “iku” to iimashita.", "Dia berkata, “Saya akan pergi.”"),
            ("パーティーがあると聞きました。", "Paatii ga aru to kikimashita.", "Saya dengar ada pesta."),
         ],
         [
            ("明日雨が降る", "思います。", "と", "Ashita ame ga furu to omoimasu.", "Saya pikir besok akan hujan."),
         ]),
        ("listing", "Menghubungkan kata benda ('dan', daftar lengkap)",
         "と menghubungkan dua kata benda atau lebih sebagai daftar "
         "LENGKAP (semua item disebutkan) — berbeda dengan や yang "
         "menyiratkan daftar SEBAGIAN (masih ada item lain yang tidak "
         "disebutkan).",
         "Kata benda A + と + Kata benda B",
         [
            ("りんごとバナナを買いました。", "Ringo to banana o kaimashita.", "Saya membeli apel dan pisang."),
            ("父と母がいます。", "Chichi to haha ga imasu.", "Ada ayah dan ibu saya."),
            ("犬と猫を飼っています。", "Inu to neko o katte imasu.", "Saya memelihara anjing dan kucing."),
         ],
         [
            ("りんご", "バナナを買いました。", "と", "Ringo to banana o kaimashita.", "Saya membeli apel dan pisang."),
         ]),
        ("conditional", "Syarat otomatis ('kalau...maka pasti')",
         "と menyatakan syarat yang hasilnya otomatis/pasti terjadi — "
         "cocok untuk hukum alam, kebiasaan, atau petunjuk arah, tapi "
         "TIDAK bisa dipakai untuk ajakan, perintah, atau permintaan di "
         "bagian akibatnya.",
         "Kata kerja/kata sifat bentuk kamus + と + akibat",
         [
            ("春になると桜が咲きます。", "Haru ni naru to sakura ga sakimasu.", "Kalau musim semi tiba, sakura mekar."),
            ("このボタンを押すとドアが開きます。", "Kono botan o osu to doa ga akimasu.", "Kalau tombol ini ditekan, pintu terbuka."),
            ("右に曲がると駅があります。", "Migi ni magaru to eki ga arimasu.", "Kalau belok kanan, ada stasiun."),
         ],
         [
            ("春になる", "桜が咲きます。", "と", "Haru ni naru to sakura ga sakimasu.", "Kalau musim semi tiba, sakura mekar."),
         ]),
     ]),
    ("e", "へ", "e",
     "Partikel arah yang menekankan arah perjalanan menuju suatu tempat — "
     "mirip dengan fungsi arah に, tapi へ terasa lebih menekankan ARAH "
     "perjalanan daripada TITIK TUJUAN spesifik, dan umum dipakai di "
     "alamat surat.",
     ["ni"],
     [
        ("direction", "Arah tujuan (menekankan arah perjalanan)",
         "へ menandai arah tujuan gerakan, dengan penekanan pada ARAH "
         "perjalanan itu sendiri, bukan titik tujuan yang spesifik. Dalam "
         "banyak kalimat sehari-hari へ bisa saling menggantikan dengan "
         "fungsi arah に dengan arti yang identik — perbedaannya jauh "
         "lebih terasa dalam gaya bahasa formal/tulisan (mis. alamat "
         "surat, 'Kepada Yth ~へ') daripada dalam percakapan biasa.",
         "Kata benda (tempat) + へ + kata kerja gerak",
         [
            ("東京へ行きます。", "Tokyo e ikimasu.", "Saya pergi ke arah Tokyo."),
            ("田中さんへ", "Tanaka-san e", "Kepada Yth. Tanaka (pembukaan surat)"),
            ("南へ進みます。", "Minami e susumimasu.", "Saya maju ke arah selatan."),
         ],
         # Sengaja TANPA cloze_examples — alasan yang sama seperti に's
         # direction function di atas: に dan へ benar-benar interchangeable
         # di sini, jadi tidak ada cara membuat soal pilihan-ganda yang adil
         # (jawabannya bisa dobel-benar tergantung distractor mana yang
         # muncul secara acak). へ tetap py konten catatan yang lengkap dan
         # nyata di sini — hanya tidak berkontribusi ke pool soal kuis.
         []),
     ]),
    ("kara", "から", "kara",
     "Partikel yang menandai titik awal (tempat atau waktu), sebab/alasan, "
     "atau bahan asal saat wujud aslinya berubah total.",
     ["made"],
     [
        ("starting_point", "Titik awal (tempat/waktu)",
         "から menandai titik awal — bisa berupa tempat (dari mana "
         "perjalanan dimulai) atau waktu (kapan sesuatu mulai "
         "berlangsung). Sering berpasangan dengan まで untuk menandai "
         "titik akhir.",
         "Kata benda (tempat/waktu) + から (+ まで)",
         [
            ("家から駅まで歩きます。", "Ie kara eki made arukimasu.", "Saya berjalan dari rumah ke stasiun."),
            ("9時から始まります。", "Ku-ji kara hajimarimasu.", "Dimulai dari jam 9."),
            ("来週から仕事です。", "Raishuu kara shigoto desu.", "Mulai minggu depan saya bekerja."),
         ],
         [
            ("9時", "始まります。", "から", "Ku-ji kara hajimarimasu.", "Dimulai dari jam 9."),
         ]),
        ("reason", "Sebab/alasan (setelah klausa)",
         "から menandai sebab/alasan, dipakai setelah klausa lengkap (kata "
         "kerja/kata sifat bentuk biasa atau sopan) — berbeda dengan で "
         "yang hanya bisa dipakai setelah kata benda tunggal sebagai "
         "sebab.",
         "Klausa (bentuk biasa/sopan) + から + akibat",
         [
            ("疲れたから、休みます。", "Tsukareta kara, yasumimasu.", "Karena lelah, saya istirahat."),
            ("時間がないから、急ぎましょう。", "Jikan ga nai kara, isogimashou.", "Karena tidak ada waktu, ayo bergegas."),
            ("危ないから、気をつけてください。", "Abunai kara, ki o tsukete kudasai.", "Karena berbahaya, tolong hati-hati."),
         ],
         [
            ("疲れた", "、休みます。", "から", "Tsukareta kara, yasumimasu.", "Karena lelah, saya istirahat."),
         ]),
        ("material_source", "Bahan asal (berubah wujud)",
         "から menandai bahan asal ketika wujud aslinya berubah total "
         "menjadi sesuatu yang berbeda — berbeda dengan で yang dipakai "
         "untuk bahan yang wujud aslinya masih terlihat/dikenali.",
         "Kata benda (bahan) + から + kata kerja (membuat)",
         [
            ("米から酒を作ります。", "Kome kara sake o tsukurimasu.", "Sake dibuat dari beras."),
            ("ぶどうからワインができます。", "Budou kara wain ga dekimasu.", "Anggur menjadi wine."),
            ("牛乳からチーズを作ります。", "Gyuunyuu kara chiizu o tsukurimasu.", "Keju dibuat dari susu."),
         ],
         [
            ("米", "酒を作ります。", "から", "Kome kara sake o tsukurimasu.", "Sake dibuat dari beras."),
         ]),
     ]),
    ("made", "まで", "made",
     "Partikel yang menandai titik akhir (tempat atau waktu) — pasangan "
     "alami dari から.",
     ["kara"],
     [
        ("ending_point", "Titik akhir (tempat/waktu)",
         "まで menandai titik akhir — tempat tujuan akhir perjalanan, atau "
         "waktu berakhirnya sesuatu. Sering berpasangan dengan から.",
         "Kata benda (tempat/waktu) + まで",
         [
            ("駅まで歩きます。", "Eki made arukimasu.", "Saya berjalan sampai stasiun."),
            ("5時まで働きます。", "Go-ji made hatarakimasu.", "Saya bekerja sampai jam 5."),
            ("夏休みまであと1週間です。", "Natsuyasumi made ato isshuukan desu.", "Tinggal 1 minggu lagi sampai libur musim panas."),
         ],
         [
            ("5時", "働きます。", "まで", "Go-ji made hatarakimasu.", "Saya bekerja sampai jam 5."),
         ]),
     ]),
    ("no", "の", "no",
     "Partikel serbaguna yang menghubungkan dua kata benda (kepemilikan/"
     "deskripsi), menggantikan kata benda yang sudah jelas dari konteks, "
     "dan berfungsi sebagai partikel tanya kasual di akhir kalimat.",
     [],
     [
        ("possessive", "Kepemilikan / menghubungkan kata benda",
         "の menghubungkan dua kata benda, biasanya menyatakan kepemilikan "
         "(kata benda A milik/terkait kata benda B) atau deskripsi (kata "
         "benda A adalah jenis/kategori dari kata benda B).",
         "Kata benda A + の + Kata benda B",
         [
            ("これは私の本です。", "Kore wa watashi no hon desu.", "Ini buku saya."),
            ("日本語の先生です。", "Nihongo no sensei desu.", "Saya guru bahasa Jepang."),
            ("大学の図書館は大きいです。", "Daigaku no toshokan wa ookii desu.", "Perpustakaan universitas itu besar."),
         ],
         [
            ("これは私", "本です。", "の", "Kore wa watashi no hon desu.", "Ini buku saya."),
         ]),
        ("nominalizer", "Menggantikan kata benda ('yang ~')",
         "の menggantikan kata benda yang sudah jelas dari konteks, mirip "
         "'yang ~' dalam Bahasa Indonesia — dipakai setelah kata sifat "
         "atau frasa deskriptif untuk menghindari pengulangan kata benda.",
         "Kata sifat/frasa + の",
         [
            ("赤いのをください。", "Akai no o kudasai.", "Tolong berikan yang merah."),
            ("これは私のです。", "Kore wa watashi no desu.", "Ini milik saya."),
            ("大きいのが好きです。", "Ookii no ga suki desu.", "Saya suka yang besar."),
         ],
         [
            ("赤い", "をください。", "の", "Akai no o kudasai.", "Tolong berikan yang merah."),
         ]),
        ("casual_question", "Partikel tanya kasual di akhir kalimat",
         "の di akhir kalimat (dengan intonasi naik) berfungsi sebagai "
         "partikel tanya kasual, mirip fungsi か tapi lebih santai dan "
         "sering dipakai dalam percakapan sehari-hari, terutama oleh "
         "perempuan atau dalam suasana akrab.",
         "Kata kerja/kata sifat bentuk biasa + の？",
         [
            ("どこ行くの？", "Doko iku no?", "Mau pergi ke mana?"),
            ("何を食べているの？", "Nani o tabete iru no?", "Sedang makan apa?"),
            ("元気なの？", "Genki na no?", "Kamu baik-baik saja?"),
         ],
         [
            ("どこ行く", "？", "の", "Doko iku no?", "Mau pergi ke mana?"),
         ]),
     ]),
]

KETERANGAN_ENTRIES = [
    ("wa", "は", "wa",
     "Partikel yang menandai topik kalimat (apa yang sedang dibicarakan), "
     "dan juga dipakai untuk menyatakan kontras antara dua hal.",
     ["ga"],
     [
        ("topic", "Menandai topik kalimat",
         "は menandai topik kalimat — hal yang sedang dibicarakan, "
         "biasanya informasi yang sudah diketahui/disebutkan sebelumnya. "
         "Berbeda dengan が yang menyoroti SUBJEK (sering info baru), は "
         "menyoroti APA yang sedang dibahas.",
         "Kata benda + は + predikat",
         [
            ("私は学生です。", "Watashi wa gakusei desu.", "Saya adalah mahasiswa."),
            ("これは本です。", "Kore wa hon desu.", "Ini adalah buku."),
            ("東京は大きい都市です。", "Tokyo wa ookii toshi desu.", "Tokyo adalah kota besar."),
         ],
         [
            ("私", "学生です。", "は", "Watashi wa gakusei desu.", "Saya adalah mahasiswa."),
         ]),
        ("contrast", "Menyatakan kontras",
         "は juga dipakai untuk menekankan kontras antara dua hal, "
         "biasanya dengan menyebutkan kedua sisinya dalam satu kalimat "
         "atau kalimat berurutan.",
         "Kata benda A + は + ..., kata benda B + は + ... (berlawanan)",
         [
            ("魚は好きですが、肉は嫌いです。", "Sakana wa suki desu ga, niku wa kirai desu.", "Saya suka ikan, tapi tidak suka daging."),
            ("英語は話せますが、フランス語は話せません。", "Eigo wa hanasemasu ga, furansugo wa hanasemasen.", "Saya bisa bicara bahasa Inggris, tapi tidak bisa bahasa Prancis."),
            ("今日は寒いですが、明日は暖かいでしょう。", "Kyou wa samui desu ga, ashita wa atatakai deshou.", "Hari ini dingin, tapi besok mungkin hangat."),
         ],
         [
            ("魚", "好きですが、肉は嫌いです。", "は", "Sakana wa suki desu ga, niku wa kirai desu.", "Saya suka ikan, tapi tidak suka daging."),
         ]),
     ]),
    ("mo", "も", "mo",
     "Partikel yang berarti 'juga', menekankan jumlah yang mengejutkan "
     "banyak, atau (dengan kata tanya + bentuk negatif) menyatakan "
     "'tidak satupun'.",
     [],
     [
        ("also", "'Juga' (menambahkan hal yang sama)",
         "も menggantikan は/が/を untuk menyatakan 'juga' — subjek/topik "
         "ini pun sama seperti yang disebutkan sebelumnya.",
         "Kata benda + も + predikat (menggantikan は/が/を)",
         [
            ("私も学生です。", "Watashi mo gakusei desu.", "Saya juga mahasiswa."),
            ("彼も来ます。", "Kare mo kimasu.", "Dia juga akan datang."),
            ("これもおいしいです。", "Kore mo oishii desu.", "Ini juga enak."),
         ],
         [
            ("私", "学生です。", "も", "Watashi mo gakusei desu.", "Saya juga mahasiswa."),
         ]),
        ("emphasis_quantity", "Menekankan jumlah/derajat yang mengejutkan",
         "も setelah angka/jumlah menekankan bahwa jumlah itu terasa "
         "besar/mengejutkan bagi pembicara — mirip 'sampai' atau 'lho' "
         "dalam Bahasa Indonesia.",
         "Angka/jumlah + も + predikat",
         [
            ("3時間も待ちました。", "San-jikan mo machimashita.", "Saya menunggu sampai 3 jam lho."),
            ("10個も食べました。", "Jukko mo tabemashita.", "Saya makan sampai 10 buah lho."),
            ("1万円もしました。", "Ichiman-en mo shimashita.", "Harganya sampai 10 ribu yen lho."),
         ],
         [
            ("3時間", "待ちました。", "も", "San-jikan mo machimashita.", "Saya menunggu sampai 3 jam lho."),
         ]),
        ("double_negative", "'Tidak satupun' (kata tanya + も + negatif)",
         "Kata tanya (だれ/なに/どこ) + も, diikuti bentuk negatif, "
         "menyatakan peniadaan total — 'tidak satupun/tidak sama sekali'.",
         "Kata tanya + も + kata kerja bentuk negatif",
         [
            ("誰も来ませんでした。", "Dare mo kimasen deshita.", "Tidak ada satupun yang datang."),
            ("何も食べませんでした。", "Nani mo tabemasen deshita.", "Saya tidak makan apa-apa."),
            ("どこも行きませんでした。", "Doko mo ikimasen deshita.", "Saya tidak pergi ke mana-mana."),
         ],
         [
            ("誰", "来ませんでした。", "も", "Dare mo kimasen deshita.", "Tidak ada satupun yang datang."),
         ]),
     ]),
    ("shika", "しか", "shika",
     "Partikel 'hanya' yang wajib diikuti bentuk negatif, memberi kesan "
     "'hanya ~ (dan itu kurang/tidak cukup)'.",
     ["dake"],
     [
        ("only_negative", "'Hanya' (wajib bentuk negatif)",
         "しか selalu diikuti predikat bentuk negatif, memberi nuansa "
         "bahwa jumlah/pilihan itu terasa kurang atau tidak memadai — "
         "berbeda dengan だけ yang netral dan bisa dipakai di kalimat "
         "positif maupun negatif.",
         "Kata benda + しか + kata kerja/kata sifat bentuk negatif",
         [
            ("1000円しかありません。", "Sen-en shika arimasen.", "Saya hanya punya 1000 yen (dan itu kurang)."),
            ("これしか分かりません。", "Kore shika wakarimasen.", "Saya hanya mengerti ini (yang lain tidak)."),
            ("野菜しか食べません。", "Yasai shika tabemasen.", "Saya hanya makan sayur (tidak yang lain)."),
         ],
         [
            ("1000円", "ありません。", "しか", "Sen-en shika arimasen.", "Saya hanya punya 1000 yen (dan itu kurang)."),
         ]),
     ]),
    ("dake", "だけ", "dake",
     "Partikel 'hanya' yang netral — bisa dipakai di kalimat positif "
     "maupun negatif, tanpa kesan kurang seperti しか.",
     ["shika"],
     [
        ("only_neutral", "'Hanya' (netral)",
         "だけ menyatakan 'hanya/cuma' secara netral, tanpa nuansa "
         "kekurangan seperti しか — bisa dipakai bebas di kalimat positif "
         "maupun negatif.",
         "Kata benda + だけ + predikat",
         [
            ("これだけでいいです。", "Kore dake de ii desu.", "Cukup hanya ini saja."),
            ("土曜日だけ休みです。", "Doyoubi dake yasumi desu.", "Hanya hari Sabtu saya libur."),
            ("少しだけ食べました。", "Sukoshi dake tabemashita.", "Saya makan sedikit saja."),
         ],
         [
            ("土曜日", "休みです。", "だけ", "Doyoubi dake yasumi desu.", "Hanya hari Sabtu saya libur."),
         ]),
     ]),
    ("kurai", "くらい", "kurai",
     "Partikel yang menandai perkiraan jumlah atau derajat ('kira-kira') "
     "— juga sering diucapkan/ditulis ぐらい, terutama setelah kata "
     "berakhiran bunyi bersuara.",
     [],
     [
        ("approximation", "Perkiraan jumlah/derajat",
         "くらい (atau ぐらい) menandai bahwa jumlah/waktu yang disebutkan "
         "adalah perkiraan, bukan angka pasti.",
         "Jumlah/waktu + くらい",
         [
            ("10分くらい待ちました。", "Juppun kurai machimashita.", "Saya menunggu sekitar 10 menit."),
            ("1時間くらいかかります。", "Ichi-jikan kurai kakarimasu.", "Kira-kira memakan waktu 1 jam."),
            ("100人くらい来ました。", "Hyaku-nin kurai kimashita.", "Sekitar 100 orang datang."),
         ],
         [
            ("10分", "待ちました。", "くらい", "Juppun kurai machimashita.", "Saya menunggu sekitar 10 menit."),
         ]),
     ]),
    ("bakari", "ばかり", "bakari",
     "Partikel yang menekankan proporsi berlebihan ('melulu, hanya itu "
     "saja') dengan nuansa agak negatif, atau (setelah kata kerja bentuk "
     "~た) menyatakan aksi yang baru saja selesai.",
     [],
     [
        ("excessive_proportion", "'Melulu' (proporsi berlebihan)",
         "ばかり menekankan bahwa seseorang melakukan/memakai sesuatu "
         "secara berlebihan atau terus-menerus, biasanya dengan nuansa "
         "agak mengkritik.",
         "Kata benda + ばかり + kata kerja",
         [
            ("彼はゲームばかりしています。", "Kare wa geemu bakari shite imasu.", "Dia melulu main game saja."),
            ("お菓子ばかり食べないでください。", "Okashi bakari tabenaide kudasai.", "Tolong jangan makan camilan melulu."),
            ("文句ばかり言っています。", "Monku bakari itte imasu.", "Dia melulu mengeluh saja."),
         ],
         [
            ("彼はゲーム", "しています。", "ばかり", "Kare wa geemu bakari shite imasu.", "Dia melulu main game saja."),
         ]),
        ("just_happened", "'Baru saja' (V-た + ばかり)",
         "Kata kerja bentuk ~た + ばかり menyatakan bahwa suatu aksi baru "
         "saja selesai dilakukan.",
         "Kata kerja bentuk ~た + ばかり",
         [
            ("今来たばかりです。", "Ima kita bakari desu.", "Saya baru saja datang."),
            ("さっき起きたばかりです。", "Sakki okita bakari desu.", "Saya baru saja bangun tidur."),
            ("この本は買ったばかりです。", "Kono hon wa katta bakari desu.", "Buku ini baru saja saya beli."),
         ],
         [
            ("今来た", "です。", "ばかり", "Ima kita bakari desu.", "Saya baru saja datang."),
         ]),
     ]),
    ("demo", "でも", "demo",
     "Partikel yang menekankan contoh ekstrem ('bahkan') atau menawarkan "
     "salah satu dari beberapa pilihan yang tidak disebutkan secara "
     "spesifik ('~atau semacamnya'). Berbeda dari kata sambung でも "
     "('tetapi') yang berdiri sendiri di awal kalimat — itu bukan "
     "partikel, jadi tidak dibahas di sini.",
     [],
     [
        ("even", "'Bahkan' (menekankan contoh ekstrem)",
         "Kata benda + でも menekankan bahwa contoh yang disebutkan adalah "
         "kasus ekstrem — kalau itu saja berlaku, hal lain pasti juga "
         "berlaku.",
         "Kata benda + でも + predikat",
         [
            ("子供でもできます。", "Kodomo demo dekimasu.", "Bahkan anak kecil pun bisa."),
            ("先生でも分からないことがあります。", "Sensei demo wakaranai koto ga arimasu.", "Bahkan guru pun ada yang tidak dimengerti."),
            ("私でも間違えることがあります。", "Watashi demo machigaeru koto ga arimasu.", "Bahkan saya pun kadang salah."),
         ],
         [
            ("子供", "できます。", "でも", "Kodomo demo dekimasu.", "Bahkan anak kecil pun bisa."),
         ]),
        ("or_something", "'~atau semacamnya' (menawarkan salah satu pilihan)",
         "Kata benda + でも menawarkan satu contoh sebagai salah satu dari "
         "beberapa pilihan yang tidak disebutkan secara spesifik, sering "
         "dipakai untuk mengajak dengan santai.",
         "Kata benda + でも + ajakan",
         [
            ("お茶でも飲みませんか。", "Ocha demo nomimasen ka.", "Mau minum teh atau semacamnya?"),
            ("映画でも見に行きましょう。", "Eiga demo mi ni ikimashou.", "Ayo nonton film atau semacamnya."),
            ("音楽でも聞きながら休みます。", "Ongaku demo kikinagara yasumimasu.", "Saya istirahat sambil dengar musik atau semacamnya."),
         ],
         [
            ("お茶", "飲みませんか。", "でも", "Ocha demo nomimasen ka.", "Mau minum teh atau semacamnya?"),
         ]),
     ]),
    ("ya", "や", "ya",
     "Partikel yang menghubungkan kata benda sebagai daftar SEBAGIAN "
     "(tidak lengkap, mengisyaratkan masih ada item lain) — pasangan "
     "kontras dari と yang menyiratkan daftar lengkap.",
     ["to"],
     [
        ("partial_listing", "'Dan' (daftar sebagian, tidak lengkap)",
         "や menghubungkan kata benda sebagai contoh yang mewakili — "
         "menyiratkan masih ada item lain yang tidak disebutkan, berbeda "
         "dengan と yang menyiratkan semua item sudah disebutkan.",
         "Kata benda A + や + Kata benda B (+ など)",
         [
            ("机の上に本やノートがあります。", "Tsukue no ue ni hon ya nooto ga arimasu.", "Di atas meja ada buku, buku catatan, dan lain-lain."),
            ("りんごやバナナが好きです。", "Ringo ya banana ga suki desu.", "Saya suka apel, pisang, dan sejenisnya."),
            ("犬や猫が公園にいます。", "Inu ya neko ga kouen ni imasu.", "Ada anjing, kucing, dan lain-lain di taman."),
         ],
         [
            ("机の上に本", "ノートがあります。", "や", "Tsukue no ue ni hon ya nooto ga arimasu.", "Di atas meja ada buku, buku catatan, dan lain-lain."),
         ]),
     ]),
]

# Note on cloze_examples across this category: most sentence-final
# particles here (わ/ぞ/ぜ/さ, and な's second sense) distinguish
# themselves mainly by SPEAKER REGISTER (feminine/masculine/casual), not
# by a translatable difference in propositional meaning — Indonesian has
# no equivalent gendered sentence-final markers, so a fill-in-the-blank
# question there could have no single defensible correct answer among
# same-category distractors (see に/へ's identical reasoning in
# KASUS_ENTRIES above). Those functions keep full sentenceExamples for the
# notes screen but deliberately carry no clozeExamples. Only functions
# where the correct particle is grammatically/syntactically forced (か's
# question and 'or' senses; な's prohibition sense — imperative mood
# genuinely excludes every other particle here; ね/よ's distinct
# agreement-seeking vs informing nuance, captured in the Indonesian
# translation's own wording) contribute cloze questions.
AKHIR_KALIMAT_ENTRIES = [
    ("ka", "か", "ka",
     "Partikel tanya di akhir kalimat (register netral/formal), dan juga "
     "partikel 'atau' saat menyebutkan pilihan.",
     ["to", "ya"],
     [
        ("question", "Partikel tanya formal di akhir kalimat",
         "か di akhir kalimat menandai kalimat tanya, baik pertanyaan "
         "ya/tidak maupun pertanyaan dengan kata tanya — register netral, "
         "cocok dipakai ke siapa saja.",
         "Kata kerja/kata sifat bentuk sopan + か",
         [
            ("元気ですか。", "Genki desu ka.", "Apa kabar?"),
            ("これは何ですか。", "Kore wa nan desu ka.", "Ini apa?"),
            ("明日来ますか。", "Ashita kimasu ka.", "Apakah besok kamu datang?"),
         ],
         [
            ("元気です", "。", "か", "Genki desu ka.", "Apa kabar?"),
            ("これは何です", "。", "か", "Kore wa nan desu ka.", "Ini apa?"),
         ]),
        ("or", "'~atau ~' (menyebutkan pilihan)",
         "か di antara dua kata benda/klausa menyatakan pilihan 'atau'.",
         "Kata benda A + か + Kata benda B",
         [
            ("犬か猫を飼いたいです。", "Inu ka neko o kaitai desu.", "Saya ingin memelihara anjing atau kucing."),
            ("コーヒーか紅茶をください。", "Koohii ka koucha o kudasai.", "Tolong berikan kopi atau teh."),
            ("土曜日か日曜日に行きます。", "Doyoubi ka nichiyoubi ni ikimasu.", "Saya akan pergi hari Sabtu atau Minggu."),
         ],
         [
            ("犬", "猫を飼いたいです。", "か", "Inu ka neko o kaitai desu.", "Saya ingin memelihara anjing atau kucing."),
            ("コーヒー", "紅茶をください。", "か", "Koohii ka koucha o kudasai.", "Tolong berikan kopi atau teh."),
         ]),
     ]),
    ("ne", "ね", "ne",
     "Partikel yang meminta persetujuan atau konfirmasi dari lawan bicara "
     "— mirip 'ya, kan?' dalam Bahasa Indonesia.",
     ["yo"],
     [
        ("agreement", "Meminta persetujuan/konfirmasi",
         "ね di akhir kalimat mengundang lawan bicara untuk setuju atau "
         "mengonfirmasi, sering dipakai saat berbagi perasaan/pengamatan "
         "yang sama.",
         "Kata kerja/kata sifat + ね",
         [
            ("いい天気ですね。", "Ii tenki desu ne.", "Cuacanya bagus, ya kan?"),
            ("この曲、いいですね。", "Kono kyoku, ii desu ne.", "Lagu ini bagus, ya kan?"),
            ("疲れましたね。", "Tsukaremashita ne.", "Capek ya, kan?"),
         ],
         [
            ("いい天気です", "。", "ね", "Ii tenki desu ne.", "Cuacanya bagus, ya kan?"),
            ("疲れました", "。", "ね", "Tsukaremashita ne.", "Capek ya, kan?"),
         ]),
     ]),
    ("yo", "よ", "yo",
     "Partikel yang menegaskan atau memberi tahu informasi, terutama hal "
     "yang mungkin belum diketahui lawan bicara — mirip '...lho!' dalam "
     "Bahasa Indonesia.",
     ["ne"],
     [
        ("informing", "Menegaskan/memberi tahu informasi baru",
         "よ di akhir kalimat menekankan bahwa pembicara memberi tahu "
         "sesuatu yang mungkin belum diketahui lawan bicara — berbeda "
         "dengan ね yang mengundang persetujuan atas hal yang SUDAH sama-"
         "sama diketahui.",
         "Kata kerja/kata sifat + よ",
         [
            ("もう7時ですよ。", "Mou shichi-ji desu yo.", "Sudah jam 7, lho!"),
            ("このお店、おいしいですよ。", "Kono omise, oishii desu yo.", "Restoran ini enak, lho!"),
            ("危ないですよ。", "Abunai desu yo.", "Itu berbahaya, lho!"),
         ],
         [
            ("もう7時です", "。", "よ", "Mou shichi-ji desu yo.", "Sudah jam 7, lho!"),
            ("危ないです", "。", "よ", "Abunai desu yo.", "Itu berbahaya, lho!"),
         ]),
     ]),
    ("na", "な", "na",
     "Partikel larangan kasual/blak-blakan (kata kerja bentuk kamus + な), "
     "dan juga penegasan kasual bernuansa maskulin mirip ね/よ tapi lebih "
     "blak-blakan.",
     ["zo", "ze"],
     [
        ("prohibition", "Larangan kasual ('jangan ~!')",
         "Kata kerja bentuk kamus + な adalah larangan langsung dan "
         "blak-blakan — jauh lebih kasar daripada ~ないでください, cocok "
         "dipakai ke teman akrab atau situasi mendesak, bukan ke orang "
         "yang dihormati.",
         "Kata kerja bentuk kamus + な",
         [
            ("心配するな。", "Shinpai suru na.", "Jangan khawatir!"),
            ("行くな。", "Iku na.", "Jangan pergi!"),
            ("触るな。", "Sawaru na.", "Jangan sentuh!"),
         ],
         [
            ("心配する", "。", "な", "Shinpai suru na.", "Jangan khawatir!"),
            ("触る", "。", "な", "Sawaru na.", "Jangan sentuh!"),
         ]),
        ("casual_emphasis", "Penegasan kasual bernuansa maskulin",
         "な juga bisa menegaskan perasaan pembicara sendiri, mirip fungsi "
         "ね tapi terasa lebih blak-blakan/maskulin — pemilihan な di sini "
         "murni soal register bicara (bukan perbedaan makna yang bisa "
         "diterjemahkan), jadi fungsi ini tidak dipakai untuk soal kuis.",
         "Kata kerja/kata sifat bentuk biasa + な",
         [
            ("疲れたな。", "Tsukareta na.", "Capek juga ya."),
            ("よく降るな。", "Yoku furu na.", "Hujan deras juga ya."),
            ("懐かしいな。", "Natsukashii na.", "Bikin kangen juga ya."),
         ],
         []),
     ]),
    ("wa2", "わ", "wa",
     "Partikel penegasan lembut yang secara tradisional diasosiasikan "
     "dengan gaya bicara feminin.",
     [],
     [
        ("feminine_emphasis", "Penegasan lembut, gaya bicara feminin",
         "わ di akhir kalimat memberi kesan penegasan yang lembut, secara "
         "tradisional diasosiasikan dengan gaya bicara perempuan. Karena "
         "yang membedakannya murni register/gender pembicara (bukan "
         "makna kalimat), fungsi ini tidak dipakai untuk soal kuis — tidak "
         "ada cara menerjemahkannya secara berbeda dari padanan netral "
         "seperti よ/ね.",
         "Kata kerja/kata sifat + わ",
         [
            ("素敵だわ。", "Suteki da wa.", "Bagus banget deh."),
            ("もう帰るわ。", "Mou kaeru wa.", "Aku pulang duluan deh."),
            ("私もそう思うわ。", "Watashi mo sou omou wa.", "Aku juga berpikir begitu deh."),
         ],
         []),
     ]),
    ("zo", "ぞ", "zo",
     "Partikel penegasan kuat bernuansa maskulin dan kasar, sering dipakai "
     "untuk diri sendiri atau ke teman akrab.",
     ["ze"],
     [
        ("masculine_emphasis", "Penegasan kuat, gaya bicara maskulin",
         "ぞ di akhir kalimat menegaskan sesuatu dengan kuat, bernuansa "
         "kasar/maskulin — umum dipakai saat berbicara pada diri sendiri "
         "(mis. menyemangati diri) atau ke teman sangat akrab. Sama "
         "seperti わ, pembedanya murni register pembicara, jadi fungsi ini "
         "tidak dipakai untuk soal kuis.",
         "Kata kerja bentuk biasa + ぞ",
         [
            ("行くぞ！", "Iku zo!", "Ayo pergi!"),
            ("よし、やるぞ！", "Yoshi, yaru zo!", "Baik, ayo kita kerjakan!"),
            ("負けないぞ。", "Makenai zo.", "Aku tidak akan kalah!"),
         ],
         []),
     ]),
    ("ze", "ぜ", "ze",
     "Partikel penegasan santai bernuansa maskulin, mirip ぞ tapi terasa "
     "sedikit lebih santai/ramah, umum dipakai ke teman akrab.",
     ["zo"],
     [
        ("casual_masculine_emphasis", "Penegasan santai, gaya bicara maskulin kasual",
         "ぜ menegaskan sesuatu dengan nada santai dan akrab, bernuansa "
         "maskulin tapi lebih ramah/kurang kasar dibanding ぞ — umum "
         "dipakai saat mengajak teman dekat. Pembedanya murni register "
         "pembicara, jadi fungsi ini tidak dipakai untuk soal kuis.",
         "Kata kerja bentuk biasa + ぜ",
         [
            ("頑張ろうぜ！", "Ganbarou ze!", "Ayo semangat!"),
            ("行こうぜ。", "Ikou ze.", "Ayo kita pergi."),
            ("楽しもうぜ！", "Tanoshimou ze!", "Ayo kita nikmati!"),
         ],
         []),
     ]),
    ("sa", "さ", "sa",
     "Partikel penegasan santai/kasual, sering bernuansa maskulin, "
     "menegaskan sesuatu seolah sudah jelas/wajar.",
     ["zo", "ze"],
     [
        ("casual_assertion", "Penegasan santai, menegaskan hal yang sudah jelas",
         "さ di akhir kalimat menegaskan sesuatu dengan nada santai, "
         "seolah hal itu sudah jelas/wajar dan tidak perlu dipikirkan "
         "berlebihan. Pembedanya murni register pembicara, jadi fungsi "
         "ini tidak dipakai untuk soal kuis.",
         "Kata kerja/kata sifat bentuk biasa + さ",
         [
            ("大丈夫さ。", "Daijoubu sa.", "Tenang aja, gak apa-apa kok."),
            ("簡単さ。", "Kantan sa.", "Gampang kok."),
            ("そんなものさ。", "Sonna mono sa.", "Begitulah adanya."),
         ],
         []),
     ]),
]


def build_entries(entries, category):
    result = []
    for suffix, particle, romaji, overview, similar, functions in entries:
        result.append({
            "id": f"particle_{suffix}",
            "particle": particle,
            "particleRomaji": romaji,
            "category": category,
            "overview": overview,
            "similarParticles": [f"particle_{s}" for s in similar],
            "functions": [
                {
                    "id": f"{suffix}_{func_id}",
                    "title": title,
                    "explanation": explanation,
                    "formation": formation,
                    "sentenceExamples": [
                        {"japanese": jp, "romaji": ro, "translation": tr}
                        for jp, ro, tr in sentence_examples
                    ],
                    "clozeExamples": [
                        {
                            "sentenceBefore": before,
                            "sentenceAfter": after,
                            "answer": answer,
                            "romaji": ro,
                            "translation": tr,
                        }
                        for before, after, answer, ro, tr in cloze_examples
                    ],
                }
                for func_id, title, explanation, formation, sentence_examples, cloze_examples in functions
            ],
        })
    return result


def main():
    kasus = build_entries(KASUS_ENTRIES, "kasus")
    keterangan = build_entries(KETERANGAN_ENTRIES, "keterangan")
    akhir_kalimat = build_entries(AKHIR_KALIMAT_ENTRIES, "akhir_kalimat")
    data = kasus + keterangan + akhir_kalimat

    with open("assets/data/particle_data.json", "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=2)

    categories = [
        {
            "id": "kasus",
            "name": "Partikel Kasus",
            "nameEn": "Case Particles",
            "icon": "格",
            "available": True,
            "particleCount": len(KASUS_ENTRIES),
        },
        {
            "id": "keterangan",
            "name": "Partikel Keterangan",
            "nameEn": "Adverbial Particles",
            "icon": "副",
            "available": True,
            "particleCount": len(KETERANGAN_ENTRIES),
        },
        {
            "id": "akhir_kalimat",
            "name": "Partikel Akhir Kalimat",
            "nameEn": "Sentence-Final Particles",
            "icon": "終",
            "available": True,
            "particleCount": len(AKHIR_KALIMAT_ENTRIES),
        },
    ]
    with open("assets/data/particle/_categories.json", "w", encoding="utf-8") as f:
        json.dump(categories, f, ensure_ascii=False, indent=2)

    print(
        f"Wrote {len(data)} particle entries "
        f"({len(KASUS_ENTRIES)} Kasus (of {len(KASUS_PARTICLES)} locked) + "
        f"{len(KETERANGAN_ENTRIES)} Keterangan (of {len(KETERANGAN_PARTICLES)} locked) + "
        f"{len(AKHIR_KALIMAT_ENTRIES)} Akhir Kalimat (of {len(AKHIR_KALIMAT_PARTICLES)} locked))."
    )


if __name__ == "__main__":
    main()
