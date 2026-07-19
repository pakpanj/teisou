# Generates assets/data/dokkai_data.json + assets/data/dokkai/_levels.json
# for Dokkai (reading comprehension, inside Ujian), mirroring
# generate_kaiwa_seed.py's shape: hand-authored Python tuples -> JSON
# matching the Dart fromJson schema.
#
# Entry tuple: (id_suffix, title, passage_japanese, passage_translation,
#               [question_tuple, ...])
# Question tuple: (prompt, [option, ...], correct_index)
#
# Run from repo root: python scripts/generate_dokkai_seed.py

import json

from dokkai_lists import (
    LEVEL_META,
    N1_TITLES,
    N2_TITLES,
    N3_TITLES,
    N4_TITLES,
    N5_TITLES,
)

N5_ENTRIES = [
    (
        "surat_sahabat_pena",
        "Surat dari Sahabat Pena",
        "はじめまして。わたしはメアリーです。アメリカから来ました。今、"
        "日本語を勉強しています。わたしの趣味は料理と読書です。週末はよく"
        "公園を散歩します。日本に行ったことがありません。いつか行きたい"
        "です。どうぞよろしくお願いします。",
        "Salam kenal. Saya Mary. Saya berasal dari Amerika. Sekarang saya "
        "sedang belajar bahasa Jepang. Hobi saya adalah memasak dan "
        "membaca. Di akhir pekan saya sering jalan-jalan di taman. Saya "
        "belum pernah pergi ke Jepang. Suatu hari saya ingin pergi. Mohon "
        "bantuannya.",
        [
            (
                "メアリーさんはどこから来ましたか。",
                ["アメリカ", "日本", "イギリス", "中国"],
                0,
            ),
            (
                "メアリーさんの趣味は何ですか。",
                ["料理と読書", "サッカーと水泳", "音楽と映画", "旅行と写真"],
                0,
            ),
            (
                "メアリーさんは日本に行ったことがありますか。",
                ["いいえ、ありません", "はい、あります", "わかりません", "三回行きました"],
                0,
            ),
        ],
    ),
    (
        "papan_pengumuman_sekolah",
        "Papan Pengumuman di Sekolah",
        "来週の月曜日は運動会です。朝八時に学校に来てください。お弁当を"
        "持ってきてください。雨の日は運動会がありません。その時は火曜日に"
        "します。",
        "Minggu depan hari Senin ada acara olahraga. Silakan datang ke "
        "sekolah jam 8 pagi. Silakan bawa bekal makan siang. Jika hujan, "
        "acara olahraga tidak diadakan. Pada saat itu akan diadakan hari "
        "Selasa.",
        [
            (
                "運動会は何曜日ですか。",
                ["月曜日", "火曜日", "水曜日", "日曜日"],
                0,
            ),
            (
                "何時に学校に来ますか。",
                ["朝八時", "朝七時", "昼十二時", "夕方五時"],
                0,
            ),
            (
                "雨が降ったら、運動会はいつしますか。",
                ["火曜日", "水曜日", "来週の月曜日", "中止です"],
                0,
            ),
        ],
    ),
    (
        "jadwal_harian_yuki",
        "Jadwal Harian Yuki",
        "ゆきさんは毎朝六時半に起きます。七時にご飯を食べます。八時に家を"
        "出て、学校へ行きます。授業は九時から三時までです。放課後、図書館"
        "で勉強します。家に帰ってから、晩ご飯を食べて、宿題をします。十時"
        "に寝ます。",
        "Yuki bangun jam 6.30 setiap pagi. Jam 7 dia makan. Jam 8 dia "
        "keluar rumah dan pergi ke sekolah. Pelajaran dari jam 9 sampai "
        "jam 3. Setelah pulang sekolah, dia belajar di perpustakaan. "
        "Setelah pulang ke rumah, dia makan malam dan mengerjakan PR. Dia "
        "tidur jam 10.",
        [
            (
                "ゆきさんは何時に起きますか。",
                ["六時半", "七時", "六時", "八時"],
                0,
            ),
            (
                "放課後、ゆきさんはどこで勉強しますか。",
                ["図書館", "教室", "家", "公園"],
                0,
            ),
            (
                "ゆきさんは何時に寝ますか。",
                ["十時", "九時", "十一時", "十二時"],
                0,
            ),
        ],
    ),
    (
        "memo_okaasan",
        "Memo dari Ibu",
        "ゆうたへ　今日、お母さんは仕事で遅くなります。冷蔵庫にカレーが"
        "あります。温めて食べてください。八時までに帰ります。宿題を忘れ"
        "ないでね。　お母さんより",
        "Untuk Yuta. Hari ini Ibu pulang telat karena kerja. Ada kari di "
        "kulkas. Tolong dihangatkan dan dimakan. Ibu akan pulang sebelum "
        "jam 8. Jangan lupa PR-nya ya. Dari Ibu.",
        [
            ("冷蔵庫に何がありますか。", ["カレー", "ラーメン", "寿司", "サラダ"], 0),
            ("お母さんは何時までに帰りますか。", ["八時", "七時", "九時", "六時"], 0),
            ("ゆうたは何を忘れてはいけませんか。", ["宿題", "傘", "財布", "携帯電話"], 0),
        ],
    ),
    (
        "tenki_yohou",
        "Ramalan Cuaca Hari Ini",
        "今日の天気を伝えます。朝は曇りです。昼から雨が降ります。午後"
        "三時ごろ、雨が一番強くなります。夜は晴れる予定です。傘を持って"
        "出かけてください。",
        "Berikut ramalan cuaca hari ini. Pagi hari berawan. Mulai siang "
        "hujan turun. Sekitar jam 3 sore, hujan paling deras. Malam hari "
        "diperkirakan cerah. Silakan bawa payung saat keluar.",
        [
            ("朝の天気はどうですか。", ["曇り", "雨", "晴れ", "雪"], 0),
            ("雨が一番強くなるのはいつですか。", ["午後三時ごろ", "朝", "夜", "昼十二時"], 0),
            ("出かける時、何を持って行ったほうがいいですか。", ["傘", "帽子", "眼鏡", "かばん"], 0),
        ],
    ),
    (
        "annai_toshokan",
        "Aturan Perpustakaan",
        "図書館のお知らせです。本は二週間借りることができます。一人"
        "五冊まで借りられます。図書館の中で食べたり飲んだりしないで"
        "ください。携帯電話は使わないでください。",
        "Pengumuman perpustakaan. Buku bisa dipinjam selama dua minggu. "
        "Satu orang bisa meminjam maksimal lima buku. Tolong jangan makan "
        "atau minum di dalam perpustakaan. Tolong jangan menggunakan "
        "telepon genggam.",
        [
            ("本は何週間借りることができますか。", ["二週間", "一週間", "三週間", "一か月"], 0),
            ("一人何冊まで借りられますか。", ["五冊", "三冊", "十冊", "二冊"], 0),
            ("図書館の中でしてはいけないことは何ですか。", ["食べること", "本を読むこと", "勉強すること", "座ること"], 0),
        ],
    ),
    (
        "shinbun_kokoku",
        "Iklan Lowongan Kerja Paruh Waktu",
        "アルバイト募集。近くのカフェで働きませんか。時間は午後五時から"
        "九時までです。週に二回から働くことができます。経験は必要"
        "ありません。興味がある人は、店に電話してください。",
        "Lowongan kerja paruh waktu. Mau bekerja di kafe dekat sini? Jam "
        "kerja dari jam 5 sore sampai jam 9 malam. Bisa bekerja mulai dua "
        "kali seminggu. Tidak perlu pengalaman. Yang tertarik, silakan "
        "telepon ke toko.",
        [
            ("アルバイトの時間は何時からですか。", ["午後五時", "午前五時", "午後三時", "午後七時"], 0),
            ("週に何回から働くことができますか。", ["二回", "一回", "五回", "毎日"], 0),
            ("このアルバイトに経験は必要ですか。", ["必要ありません", "とても必要です", "三年必要です", "分かりません"], 0),
        ],
    ),
    (
        "ryokou_annai",
        "Rencana Perjalanan Kelas",
        "来月、クラスで京都へ旅行に行きます。バスで行きます。朝七時に"
        "学校に集まってください。お弁当とお金を持ってきてください。写真"
        "もたくさん撮りましょう。",
        "Bulan depan, kelas kita akan pergi berwisata ke Kyoto. Kita akan "
        "pergi naik bus. Silakan berkumpul di sekolah jam 7 pagi. Silakan "
        "bawa bekal dan uang. Mari kita juga foto banyak-banyak.",
        [
            ("どこへ旅行に行きますか。", ["京都", "大阪", "東京", "北海道"], 0),
            ("何で行きますか。", ["バス", "電車", "飛行機", "自転車"], 0),
            ("何時に学校に集まりますか。", ["朝七時", "朝八時", "朝六時", "昼十二時"], 0),
        ],
    ),
    (
        "resutoran_menu_annai",
        "Pengumuman Menu Baru Restoran",
        "当店に新しいメニューができました。今月から、ラーメンとカレーが"
        "食べられます。ラーメンは七百円、カレーは六百円です。土曜日と"
        "日曜日は百円安くなります。ぜひ来てください。",
        "Restoran kami punya menu baru. Mulai bulan ini, tersedia ramen "
        "dan kari. Ramen 700 yen, kari 600 yen. Sabtu dan Minggu jadi 100 "
        "yen lebih murah. Silakan datang ya.",
        [
            ("新しいメニューは何ですか。", ["ラーメンとカレー", "寿司とうどん", "パンとケーキ", "魚と肉"], 0),
            ("ラーメンはいくらですか。", ["七百円", "六百円", "八百円", "五百円"], 0),
            ("いつ安くなりますか。", ["土曜日と日曜日", "月曜日", "毎日", "金曜日"], 0),
        ],
    ),
    (
        "tomodachi_no_tegami",
        "Surat dari Teman Lama",
        "久しぶり。元気ですか。私は先月、新しい町に引っ越しました。新しい"
        "家は駅から近くて、とても便利です。まだ友達が少ないので、少し"
        "寂しいです。今度、遊びに来てください。",
        "Sudah lama tidak berjumpa. Apa kabar? Saya bulan lalu pindah ke "
        "kota baru. Rumah baru dekat dari stasiun, sangat praktis. Karena "
        "teman masih sedikit, agak kesepian. Lain kali, silakan main ke "
        "sini.",
        [
            ("いつ新しい町に引っ越しましたか。", ["先月", "今週", "去年", "昨日"], 0),
            ("新しい家はどこから近いですか。", ["駅", "学校", "公園", "病院"], 0),
            ("手紙を書いた人はどうして少し寂しいですか。", ["友達が少ないから", "仕事が忙しいから", "家が古いから", "お金がないから"], 0),
        ],
    ),
    (
        "eki_annai",
        "Pengumuman di Stasiun",
        "お知らせします。事故のため、電車が二十分遅れています。次の電車"
        "は十時十分に来ます。急いでいる方は、バスをご利用ください。ご"
        "迷惑をおかけして、申し訳ございません。",
        "Pengumuman. Karena ada kecelakaan, kereta terlambat dua puluh "
        "menit. Kereta berikutnya akan datang jam 10.10. Bagi yang sedang "
        "terburu-buru, silakan gunakan bus. Mohon maaf atas "
        "ketidaknyamanannya.",
        [
            ("どうして電車が遅れていますか。", ["事故のため", "雨のため", "台風のため", "工事のため"], 0),
            ("電車はどのくらい遅れていますか。", ["二十分", "十分", "三十分", "一時間"], 0),
            ("急いでいる人はどうしたらいいですか。", ["バスを利用する", "走る", "タクシーを呼ぶ", "待つだけ"], 0),
        ],
    ),
    (
        "kurasu_annai",
        "Pengumuman Kelas Tambahan",
        "テストの点数が低かった学生のために、来週から補習を始めます。"
        "火曜日と木曜日の放課後、教室で行います。参加したい人は、先生に"
        "伝えてください。",
        "Untuk siswa yang nilai ujiannya rendah, mulai minggu depan akan "
        "diadakan kelas tambahan. Diadakan di ruang kelas setelah pulang "
        "sekolah pada hari Selasa dan Kamis. Yang ingin ikut, silakan "
        "sampaikan ke guru.",
        [
            ("補習はいつから始まりますか。", ["来週", "今週", "来月", "明日"], 0),
            ("補習は何曜日にありますか。", ["火曜日と木曜日", "月曜日と水曜日", "土曜日", "毎日"], 0),
            ("参加したい人はどうしますか。", ["先生に伝える", "何もしなくていい", "学校に電話する", "手紙を書く"], 0),
        ],
    ),
    (
        "nikki_ichinichi",
        "Buku Harian Tanaka",
        "今日は日曜日でした。朝、公園を散歩しました。天気がよくて、"
        "気持ちがよかったです。昼にラーメンを食べました。午後は部屋を"
        "掃除しました。夜は本を読んで、早く寝ました。",
        "Hari ini hari Minggu. Pagi hari, saya jalan-jalan di taman. "
        "Cuacanya bagus, perasaan jadi enak. Siang saya makan ramen. Sore "
        "saya membersihkan kamar. Malam saya membaca buku dan tidur lebih "
        "awal.",
        [
            ("今日は何曜日でしたか。", ["日曜日", "月曜日", "土曜日", "金曜日"], 0),
            ("昼に何を食べましたか。", ["ラーメン", "カレー", "寿司", "パン"], 0),
            ("午後は何をしましたか。", ["部屋を掃除しました", "本を読みました", "買い物しました", "泳ぎました"], 0),
        ],
    ),
    (
        "kouen_kisoku",
        "Peraturan Taman Kota",
        "この公園を気持ちよく使うために、お願いがあります。ゴミは持ち"
        "帰ってください。犬の散歩をする時は、リードをつけてください。夜"
        "十時から朝六時までは入れません。",
        "Untuk menggunakan taman ini dengan nyaman, ada permintaan. Tolong "
        "bawa pulang sampah Anda. Saat mengajak anjing jalan-jalan, tolong "
        "pakai tali pengikat. Tidak boleh masuk dari jam 10 malam sampai "
        "jam 6 pagi.",
        [
            ("ゴミはどうしますか。", ["持ち帰ります", "公園に捨てます", "燃やします", "埋めます"], 0),
            ("犬の散歩をする時、何が必要ですか。", ["リード", "帽子", "傘", "かばん"], 0),
            ("何時から公園に入れませんか。", ["夜十時", "夜九時", "夜十一時", "夜八時"], 0),
        ],
    ),
    (
        "hikkoshi_annai",
        "Pengumuman Pindah Rumah",
        "来月十日に、隣の部屋に新しい人が引っ越してきます。その日は朝"
        "からトラックが来て、少しうるさいかもしれません。ご理解を"
        "お願いします。",
        "Tanggal 10 bulan depan, orang baru akan pindah ke kamar sebelah. "
        "Pada hari itu truk akan datang dari pagi, mungkin agak berisik. "
        "Mohon pengertiannya.",
        [
            ("いつ新しい人が引っ越してきますか。", ["来月十日", "今月十日", "来週", "明日"], 0),
            ("その日、何が来ますか。", ["トラック", "タクシー", "バス", "電車"], 0),
            ("どうしてうるさいかもしれませんか。", ["トラックが来るから", "音楽をかけるから", "工事があるから", "パーティーがあるから"], 0),
        ],
    ),
    (
        "byouin_uketsuke",
        "Jam Buka Rumah Sakit",
        "この病院は月曜日から金曜日まで、朝九時から夕方六時まで開いて"
        "います。土曜日は昼十二時までです。日曜日と祝日は休みです。急な"
        "時は、救急に電話してください。",
        "Rumah sakit ini buka dari hari Senin sampai Jumat, jam 9 pagi "
        "sampai jam 6 sore. Hari Sabtu sampai jam 12 siang. Hari Minggu "
        "dan hari libur tutup. Kalau ada keadaan darurat, silakan telepon "
        "ke gawat darurat.",
        [
            ("月曜日から金曜日まで、何時まで開いていますか。", ["夕方六時", "昼十二時", "夜九時", "朝十時"], 0),
            ("土曜日は何時まで開いていますか。", ["昼十二時", "夕方六時", "朝九時", "夜八時"], 0),
            ("日曜日、この病院は開いていますか。", ["いいえ、休みです", "はい、開いています", "昼だけ開いています", "分かりません"], 0),
        ],
    ),
    (
        "paatii_shoutai",
        "Undangan Pesta Ulang Tahun",
        "来週の土曜日、私の誕生日パーティーをします。場所は私の家です。"
        "時間は午後六時からです。プレゼントは要りません。楽しい話を"
        "たくさん持ってきてください。",
        "Sabtu depan, saya akan mengadakan pesta ulang tahun. Tempatnya di "
        "rumah saya. Waktunya mulai jam 6 sore. Tidak perlu hadiah. "
        "Silakan bawa banyak cerita seru.",
        [
            ("パーティーはいつですか。", ["来週の土曜日", "今週の日曜日", "来月", "明日"], 0),
            ("パーティーはどこでしますか。", ["私の家", "レストラン", "学校", "公園"], 0),
            ("何が要りませんか。", ["プレゼント", "時間", "楽しい話", "招待状"], 0),
        ],
    ),
    (
        "supa_seru",
        "Diskon Supermarket Akhir Pekan",
        "今週の土曜日と日曜日、当店はセールをします。野菜と果物は二十"
        "パーセント安くなります。肉と魚は十パーセント安くなります。ぜひ"
        "この機会にお越しください。",
        "Sabtu dan Minggu minggu ini, toko kami mengadakan obral. Sayuran "
        "dan buah menjadi 20 persen lebih murah. Daging dan ikan menjadi "
        "10 persen lebih murah. Silakan datang di kesempatan ini.",
        [
            ("セールはいつですか。", ["土曜日と日曜日", "月曜日", "毎日", "金曜日だけ"], 0),
            ("野菜は何パーセント安くなりますか。", ["二十パーセント", "十パーセント", "三十パーセント", "五十パーセント"], 0),
            ("肉は何パーセント安くなりますか。", ["十パーセント", "二十パーセント", "三十パーセント", "安くなりません"], 0),
        ],
    ),
    (
        "kazoku_ryokou",
        "Liburan Keluarga ke Laut",
        "夏休みに、家族で海へ行きました。電車とバスで三時間かかりました。"
        "海はとてもきれいでした。泳いだり、砂で遊んだりしました。夜は"
        "花火を見ました。とても楽しかったです。",
        "Saat liburan musim panas, saya pergi ke laut bersama keluarga. "
        "Butuh waktu tiga jam naik kereta dan bus. Lautnya sangat indah. "
        "Kami berenang dan bermain pasir. Malamnya kami melihat kembang "
        "api. Sangat menyenangkan.",
        [
            ("どうやって海へ行きましたか。", ["電車とバス", "車", "飛行機", "自転車"], 0),
            ("海までどのくらいかかりましたか。", ["三時間", "一時間", "五時間", "三十分"], 0),
            ("夜は何をしましたか。", ["花火を見ました", "買い物しました", "寝ました", "料理しました"], 0),
        ],
    ),
    (
        "gakkou_koushi",
        "Perubahan Jadwal Sekolah",
        "来週月曜日、先生の会議があるため、授業は午前中だけです。午後は"
        "学生は家に帰ることができます。火曜日からはいつも通りの時間割"
        "です。",
        "Senin depan, karena ada rapat guru, pelajaran hanya sampai siang. "
        "Sore siswa boleh pulang ke rumah. Mulai hari Selasa jadwal "
        "seperti biasa.",
        [
            ("どうして授業は午前中だけですか。", ["先生の会議があるから", "台風が来るから", "祝日だから", "テストがあるから"], 0),
            ("午後、学生はどうしますか。", ["家に帰ることができます", "補習があります", "掃除します", "部活をします"], 0),
            ("火曜日はいつも通りですか。", ["はい、いつも通りです", "いいえ、休みです", "午前中だけです", "分かりません"], 0),
        ],
    ),
    (
        "ryouri_kyoushitsu",
        "Pengumuman Kelas Memasak",
        "来週の土曜日、料理教室があります。参加したい人は、金曜日までに"
        "先生に伝えてください。エプロンを持ってきてください。材料費は"
        "五百円です。",
        "Sabtu depan, ada kelas memasak. Yang ingin ikut, silakan "
        "sampaikan ke guru sampai hari Jumat. Silakan bawa apron. Biaya "
        "bahan 500 yen.",
        [
            ("いつ料理教室がありますか。", ["来週の土曜日", "今週の金曜日", "明日", "来月"], 0),
            ("何を持ってきますか。", ["エプロン", "お弁当", "傘", "本"], 0),
            ("材料費はいくらですか。", ["五百円", "千円", "三百円", "無料"], 0),
        ],
    ),
    (
        "sukuuru_basu",
        "Jadwal Bus Sekolah",
        "スクールバスの時間が変わりました。朝は七時半に出発します。帰りは"
        "三時半です。雨の日は少し遅れることがあります。",
        "Jam bus sekolah berubah. Pagi berangkat jam 7.30. Pulang jam "
        "3.30. Saat hujan, kadang agak terlambat.",
        [
            ("朝、バスは何時に出発しますか。", ["七時半", "七時", "八時", "六時半"], 0),
            ("帰りのバスは何時ですか。", ["三時半", "四時", "二時半", "五時"], 0),
            ("雨の日はどうなることがありますか。", ["少し遅れる", "とても早く来る", "来ない", "変わらない"], 0),
        ],
    ),
    (
        "kansha_tegami",
        "Surat Terima Kasih ke Guru",
        "先生、一年間ありがとうございました。先生の授業はいつも楽しかった"
        "です。分からないことがある時、いつも優しく教えてくれました。"
        "来年もお元気で。",
        "Guru, terima kasih selama satu tahun ini. Pelajaran guru selalu "
        "menyenangkan. Saat ada yang tidak dimengerti, guru selalu "
        "mengajari dengan ramah. Semoga sehat terus tahun depan.",
        [
            ("この手紙は誰に書きましたか。", ["先生", "友達", "家族", "医者"], 0),
            ("先生の授業はどうでしたか。", ["いつも楽しかった", "つまらなかった", "難しすぎた", "短すぎた"], 0),
            ("分からないことがある時、先生はどうしてくれましたか。", ["優しく教えてくれた", "何も教えなかった", "怒った", "無視した"], 0),
        ],
    ),
    (
        "yobou_sesshu",
        "Pengumuman Vaksinasi di Sekolah",
        "来月十日、学校で予防接種を行います。忘れずに、接種の同意書を"
        "持ってきてください。体調が悪い人は、その日に受けることが"
        "できません。",
        "Tanggal 10 bulan depan, akan dilakukan vaksinasi di sekolah. "
        "Jangan lupa membawa surat persetujuan vaksinasi. Yang sedang "
        "tidak sehat, tidak bisa divaksin hari itu.",
        [
            ("予防接種はいつ行いますか。", ["来月十日", "今月", "来週", "明日"], 0),
            ("何を忘れずに持ってきますか。", ["同意書", "お弁当", "お金", "本"], 0),
            ("体調が悪い人はどうなりますか。", ["その日に受けられない", "早く受けられる", "二回受ける", "関係ない"], 0),
        ],
    ),
    (
        "gakkou_pikunikku",
        "Cerita Piknik Sekolah",
        "先週、学校で公園にピクニックに行きました。天気がとてもよくて、"
        "みんなでお弁当を食べました。その後、鬼ごっこをして遊びました。"
        "とても楽しい一日でした。",
        "Minggu lalu, sekolah kami pergi piknik ke taman. Cuacanya "
        "sangat bagus, semua makan bekal bersama. Setelah itu, kami "
        "bermain kejar-kejaran. Hari yang sangat menyenangkan.",
        [
            ("どこにピクニックに行きましたか。", ["公園", "海", "山", "動物園"], 0),
            ("みんなで何を食べましたか。", ["お弁当", "ラーメン", "パン", "お菓子"], 0),
            ("その後、何をして遊びましたか。", ["鬼ごっこ", "サッカー", "野球", "水泳"], 0),
        ],
    ),
    (
        "puuru_kisoku",
        "Aturan Kolam Renang",
        "プールを使う前に、シャワーを浴びてください。プールの中を走っては"
        "いけません。飲み物やお菓子を持って入らないでください。子供は"
        "必ず大人と一緒に入ってください。",
        "Sebelum menggunakan kolam renang, tolong mandi shower dulu. "
        "Tidak boleh berlari di dalam kolam. Jangan bawa minuman atau "
        "camilan masuk. Anak-anak harus selalu masuk bersama orang "
        "dewasa.",
        [
            ("プールを使う前に何をしますか。", ["シャワーを浴びる", "準備運動をする", "着替える", "待つ"], 0),
            ("プールの中で何をしてはいけませんか。", ["走ること", "泳ぐこと", "話すこと", "見ること"], 0),
            ("子供はどうやって入りますか。", ["大人と一緒に", "一人で", "友達とだけ", "何も条件はない"], 0),
        ],
    ),
    (
        "kantin_menyu",
        "Menu Kantin Sekolah",
        "今月のカンティンの新しいメニューです。月曜日はカレーライス、"
        "火曜日はラーメンです。全部三百円です。デザートは百円で買うことが"
        "できます。",
        "Ini menu baru kantin bulan ini. Senin nasi kari, Selasa ramen. "
        "Semuanya 300 yen. Makanan penutup bisa dibeli dengan 100 yen.",
        [
            ("月曜日のメニューは何ですか。", ["カレーライス", "ラーメン", "うどん", "寿司"], 0),
            ("メニューはいくらですか。", ["三百円", "五百円", "二百円", "千円"], 0),
            ("デザートはいくらですか。", ["百円", "三百円", "無料", "五十円"], 0),
        ],
    ),
    (
        "e_konkuuru",
        "Pengumuman Lomba Menggambar",
        "今年の絵のコンクールのテーマは「私の家族」です。参加したい人は、"
        "来週の金曜日までに絵を先生に出してください。一番いい絵を描いた"
        "人には、賞状がもらえます。",
        "Tema lomba menggambar tahun ini adalah 'Keluargaku'. Yang ingin "
        "ikut, silakan serahkan gambar ke guru sampai Jumat depan. Yang "
        "menggambar paling bagus akan mendapat piagam.",
        [
            ("今年のテーマは何ですか。", ["私の家族", "私の夢", "動物", "季節"], 0),
            ("いつまでに絵を出しますか。", ["来週の金曜日", "今日", "来月", "明日"], 0),
            ("一番いい絵を描いた人には何がもらえますか。", ["賞状", "お金", "本", "ノート"], 0),
        ],
    ),
    (
        "tooi_machi_tomodachi",
        "Surat untuk Sahabat di Kota Lain",
        "元気ですか。私は元気です。新しい学校にも慣れました。友達も"
        "少しずつできています。今度の夏休みに、そちらへ遊びに行っても"
        "いいですか。返事を待っています。",
        "Apa kabar? Saya baik-baik saja. Sudah terbiasa dengan sekolah "
        "baru juga. Teman juga sedikit demi sedikit bertambah. Liburan "
        "musim panas nanti, boleh saya main ke sana? Menunggu balasannya.",
        [
            ("新しい学校について、この人はどうですか。", ["慣れました", "まだ慣れていません", "好きではありません", "分かりません"], 0),
            ("いつ遊びに行きたいと言っていますか。", ["今度の夏休み", "来週", "冬休み", "今日"], 0),
            ("この人は何を待っていますか。", ["返事", "お金", "プレゼント", "電話"], 0),
        ],
    ),
    (
        "haisha_yotei",
        "Jadwal Kunjungan Dokter Gigi",
        "来週の水曜日、午後三時に歯医者の予約があります。学校が終わって"
        "から、一人で行くことができますか。もし難しければ、お母さんが"
        "迎えに行きます。",
        "Rabu depan, jam 3 sore ada janji ke dokter gigi. Setelah "
        "sekolah selesai, bisakah kamu pergi sendiri? Kalau susah, ibu "
        "akan menjemput.",
        [
            ("歯医者の予約はいつですか。", ["来週の水曜日、午後三時", "今週の月曜日", "明日", "来月"], 0),
            ("学校が終わってから、どうしますか。", ["一人で行けるか聞かれている", "必ず一人で行く", "絶対に迎えに来てもらう", "行かない"], 0),
            ("難しければ誰が迎えに行きますか。", ["お母さん", "お父さん", "先生", "友達"], 0),
        ],
    ),
    (
        "eakon_shuuri",
        "Pengumuman Perbaikan AC di Kelas",
        "教室のエアコンが壊れたので、来週修理します。修理の間、少し暑い"
        "かもしれません。水筒を持ってきて、水分をよく取ってください。",
        "AC di kelas rusak, jadi minggu depan akan diperbaiki. Selama "
        "perbaikan, mungkin agak panas. Silakan bawa botol minum dan "
        "minum air yang cukup.",
        [
            ("どうして修理しますか。", ["エアコンが壊れたから", "汚れたから", "古いから", "誰かが壊したから"], 0),
            ("修理の間、教室はどうなるかもしれませんか。", ["少し暑い", "とても寒い", "暗い", "うるさい"], 0),
            ("何を持ってきますか。", ["水筒", "傘", "扇風機", "上着"], 0),
        ],
    ),
    (
        "oya_tetsudai",
        "Cerita Membantu Orang Tua di Rumah",
        "毎週日曜日、私は家の掃除を手伝います。お皿を洗ったり、洗濯物を"
        "たたんだりします。最初は大変でしたが、今は上手にできるように"
        "なりました。母はいつも喜んでくれます。",
        "Setiap hari Minggu, saya membantu bersih-bersih rumah. Saya "
        "mencuci piring dan melipat cucian. Awalnya berat, tapi sekarang "
        "jadi bisa melakukannya dengan baik. Ibu selalu senang.",
        [
            ("いつ家の掃除を手伝いますか。", ["毎週日曜日", "毎日", "土曜日だけ", "平日"], 0),
            ("何をしますか。", ["お皿を洗ったり洗濯物をたたんだりする", "料理を作る", "買い物する", "庭の手入れをする"], 0),
            ("母はどう思っていますか。", ["喜んでくれる", "怒っている", "何も言わない", "心配している"], 0),
        ],
    ),
    (
        "konpyuutaa_kisoku",
        "Aturan Menggunakan Komputer di Sekolah",
        "コンピューター室を使う時は、飲食禁止です。使い終わったら、必ず"
        "電源を切ってください。分からないことがあれば、先生に聞いて"
        "ください。個人的なゲームはしないでください。",
        "Saat menggunakan ruang komputer, dilarang makan minum. Setelah "
        "selesai digunakan, pastikan matikan daya. Jika ada yang tidak "
        "dimengerti, silakan tanya guru. Jangan bermain game pribadi.",
        [
            ("コンピューター室で何が禁止ですか。", ["飲食", "会話", "質問", "座ること"], 0),
            ("使い終わったら何をしますか。", ["電源を切る", "ドアを閉める", "掃除する", "記録を書く"], 0),
            ("何をしてはいけませんか。", ["個人的なゲーム", "宿題", "調べ物", "タイピング練習"], 0),
        ],
    ),
    (
        "bazaa_annai",
        "Pengumuman Bazar Sekolah",
        "来月、学校でバザーを行います。使わなくなったおもちゃや本を"
        "持ってきてください。売れたお金は、図書館の本を買うために使い"
        "ます。ぜひ参加してください。",
        "Bulan depan, akan diadakan bazar di sekolah. Silakan bawa "
        "mainan atau buku yang sudah tidak dipakai. Uang hasil penjualan "
        "akan digunakan untuk membeli buku perpustakaan. Silakan ikut "
        "berpartisipasi.",
        [
            ("バザーはいつ行いますか。", ["来月", "今週", "明日", "来年"], 0),
            ("何を持ってきますか。", ["使わなくなったおもちゃや本", "お金", "新しい服", "食べ物"], 0),
            ("売れたお金は何に使いますか。", ["図書館の本を買うため", "先生の給料", "学校の修理", "パーティー"], 0),
        ],
    ),
    (
        "kazoku_pikunikku_shoutai",
        "Surat Undangan Piknik Keluarga",
        "今度の日曜日、公園で家族みんなでピクニックをしませんか。お弁当は"
        "私が作ります。飲み物とレジャーシートを持ってきてください。天気が"
        "悪ければ、来週にします。",
        "Minggu depan ini, bagaimana kalau kita piknik sekeluarga di "
        "taman? Bekalnya akan saya buat. Silakan bawa minuman dan tikar. "
        "Kalau cuaca buruk, akan diadakan minggu depan.",
        [
            ("誰がお弁当を作りますか。", ["手紙を書いた人", "母", "父", "誰も作らない"], 0),
            ("何を持ってきますか。", ["飲み物とレジャーシート", "お金", "おもちゃ", "傘"], 0),
            ("天気が悪ければどうしますか。", ["来週にする", "中止にする", "家でする", "別の場所でする"], 0),
        ],
    ),
    (
        "sakkaa_bu_renshuu",
        "Jadwal Latihan Klub Sepak Bola",
        "サッカー部の練習は、月曜日、水曜日、金曜日の放課後です。雨の日は"
        "体育館で練習します。次の試合は来月三日です。みんな、頑張って"
        "練習しましょう。",
        "Latihan klub sepak bola pada hari Senin, Rabu, Jumat setelah "
        "pulang sekolah. Saat hujan, latihan di gedung olahraga. "
        "Pertandingan berikutnya tanggal 3 bulan depan. Ayo kita "
        "berlatih dengan semangat.",
        [
            ("練習は何曜日ですか。", ["月、水、金曜日", "火、木曜日", "毎日", "週末だけ"], 0),
            ("雨の日はどこで練習しますか。", ["体育館", "教室", "公園", "家"], 0),
            ("次の試合はいつですか。", ["来月三日", "今週末", "明日", "来年"], 0),
        ],
    ),
    (
        "haha_purezento",
        "Cerita Membeli Hadiah untuk Ibu",
        "来週は母の日です。お小遣いを貯めて、母に花を買おうと思って"
        "います。花屋で一番きれいな花を選びたいです。母がきっと喜んで"
        "くれると思います。",
        "Minggu depan adalah hari ibu. Saya berencana menabung uang "
        "jajan untuk membelikan bunga untuk ibu. Saya ingin memilih "
        "bunga paling cantik di toko bunga. Saya pikir ibu pasti akan "
        "senang.",
        [
            ("来週は何の日ですか。", ["母の日", "父の日", "誕生日", "子供の日"], 0),
            ("何を貯めていますか。", ["お小遣い", "おもちゃ", "本", "切手"], 0),
            ("どこで花を選びたいですか。", ["花屋", "スーパー", "学校", "公園"], 0),
        ],
    ),
    (
        "gakkou_yasumi_oshirase",
        "Pengumuman Libur Sekolah",
        "来週の月曜日は祝日のため、学校は休みです。宿題を忘れずにやって"
        "ください。火曜日から、いつも通り授業があります。",
        "Senin depan libur nasional, jadi sekolah libur. Jangan lupa "
        "kerjakan PR. Mulai hari Selasa, pelajaran seperti biasa.",
        [
            ("どうして学校は休みですか。", ["祝日のため", "台風のため", "先生の会議のため", "テストのため"], 0),
            ("何を忘れずにやりますか。", ["宿題", "掃除", "買い物", "手紙"], 0),
            ("火曜日はどうなりますか。", ["いつも通り授業がある", "休み", "午前中だけ", "分からない"], 0),
        ],
    ),
    (
        "gurupu_benkyou",
        "Cerita Belajar Kelompok",
        "昨日、友達の家でグループ勉強をしました。四人で数学の宿題を"
        "しました。分からない問題は、みんなで一緒に考えました。一人で"
        "勉強するより、楽しくて分かりやすかったです。",
        "Kemarin, saya belajar kelompok di rumah teman. Empat orang "
        "mengerjakan PR matematika. Soal yang tidak dimengerti, kami "
        "pikirkan bersama-sama. Dibanding belajar sendiri, ini lebih "
        "menyenangkan dan mudah dipahami.",
        [
            ("何人でグループ勉強をしましたか。", ["四人", "二人", "三人", "五人"], 0),
            ("何の宿題をしましたか。", ["数学", "国語", "英語", "理科"], 0),
            ("一人で勉強するより、どうでしたか。", ["楽しくて分かりやすかった", "つまらなかった", "難しかった", "同じだった"], 0),
        ],
    ),
    (
        "bijutsu_tenrankai",
        "Pengumuman Pameran Seni Sekolah",
        "来月、学校で美術展覧会があります。みんなが描いた絵や作った"
        "作品を、体育館に飾ります。保護者の方もぜひ見に来てください。"
        "入場は無料です。",
        "Bulan depan, ada pameran seni di sekolah. Lukisan dan karya "
        "yang dibuat semua orang akan dipajang di gedung olahraga. Orang "
        "tua juga silakan datang untuk melihat. Masuknya gratis.",
        [
            ("美術展覧会はどこでありますか。", ["体育館", "教室", "図書館", "公園"], 0),
            ("何が飾られますか。", ["絵や作品", "写真だけ", "本", "おもちゃ"], 0),
            ("入場料はいくらですか。", ["無料", "百円", "五百円", "千円"], 0),
        ],
    ),
    (
        "toire_shuuri",
        "Pengumuman Perbaikan Toilet Sekolah",
        "来週、二階のトイレを修理します。その間、一階のトイレを使って"
        "ください。ご迷惑をおかけしますが、よろしくお願いします。",
        "Minggu depan, toilet lantai dua akan diperbaiki. Selama itu, "
        "silakan gunakan toilet lantai satu. Mohon maaf atas "
        "ketidaknyamanannya.",
        [
            ("何を修理しますか。", ["二階のトイレ", "一階のトイレ", "教室", "体育館"], 0),
            ("その間、どこのトイレを使いますか。", ["一階", "三階", "隣の学校", "使えない"], 0),
            ("これはどんな文章ですか。", ["お知らせ", "苦情", "招待", "質問"], 0),
        ],
    ),
    (
        "hanabi_taikai",
        "Cerita Menonton Kembang Api",
        "先週末、家族で花火大会に行きました。とても大きくて、きれいな"
        "花火でした。人がたくさんいて、少し疲れましたが、楽しい思い出に"
        "なりました。",
        "Akhir pekan lalu, saya pergi ke festival kembang api bersama "
        "keluarga. Kembang apinya sangat besar dan indah. Banyak orang, "
        "jadi agak lelah, tapi menjadi kenangan yang menyenangkan.",
        [
            ("いつ花火大会に行きましたか。", ["先週末", "今週末", "昨日", "来週"], 0),
            ("花火はどうでしたか。", ["大きくてきれい", "小さかった", "見えなかった", "つまらなかった"], 0),
            ("どうして少し疲れましたか。", ["人がたくさんいたから", "歩きすぎたから", "暑かったから", "眠かったから"], 0),
        ],
    ),
    (
        "kesseki_renraku",
        "Surat Meminta Izin Tidak Masuk Sekolah",
        "先生、息子が熱を出したので、今日は学校を休ませます。病院に連れて"
        "行く予定です。宿題は明日持って行かせます。よろしくお願いいたし"
        "ます。",
        "Guru, karena anak laki-laki saya demam, hari ini saya izinkan "
        "tidak masuk sekolah. Berencana membawanya ke rumah sakit. "
        "PR-nya akan dibawa besok. Mohon bantuannya.",
        [
            ("どうして学校を休みますか。", ["熱を出したから", "旅行に行くから", "寝坊したから", "疲れたから"], 0),
            ("どこに連れて行く予定ですか。", ["病院", "学校", "公園", "祖母の家"], 0),
            ("宿題はいつ持って行きますか。", ["明日", "今日", "来週", "分からない"], 0),
        ],
    ),
    (
        "ongaku_shitsu_kisoku",
        "Aturan Ruang Musik",
        "音楽室では、楽器を大切に使ってください。使い終わったら、元の"
        "場所に戻してください。飲み物を持って入ってはいけません。",
        "Di ruang musik, tolong gunakan alat musik dengan hati-hati. "
        "Setelah selesai digunakan, kembalikan ke tempat semula. Tidak "
        "boleh membawa minuman masuk.",
        [
            ("楽器はどう使いますか。", ["大切に", "自由に", "使わない", "貸し借りする"], 0),
            ("使い終わったらどうしますか。", ["元の場所に戻す", "持って帰る", "そのままにする", "先生に渡す"], 0),
            ("何を持って入ってはいけませんか。", ["飲み物", "楽譜", "かばん", "教科書"], 0),
        ],
    ),
    (
        "kimatsu_shiken_nittei",
        "Jadwal Ujian Akhir Semester",
        "期末試験は来月十五日から十九日までです。国語と数学は十五日、"
        "英語と理科は十六日にあります。試験の準備をしっかりしてくだ"
        "さい。",
        "Ujian akhir semester dari tanggal 15 sampai 19 bulan depan. "
        "Bahasa Jepang dan matematika tanggal 15, bahasa Inggris dan "
        "IPA tanggal 16. Silakan persiapkan ujian dengan baik.",
        [
            ("期末試験はいつからですか。", ["来月十五日", "今月十五日", "来週", "明日"], 0),
            ("国語のテストはいつですか。", ["十五日", "十六日", "十七日", "十八日"], 0),
            ("英語のテストはいつですか。", ["十六日", "十五日", "十七日", "十九日"], 0),
        ],
    ),
    (
        "okashi_zukuri",
        "Cerita Membuat Kue Bersama Teman",
        "昨日、友達とクッキーを作りました。初めてでしたが、思ったより"
        "上手にできました。焼きたてのクッキーはとても美味しかったです。"
        "また作りたいです。",
        "Kemarin, saya membuat kukis bersama teman. Ini pertama kali, "
        "tapi hasilnya lebih baik dari yang saya kira. Kukis yang baru "
        "dipanggang sangat enak. Saya ingin membuat lagi.",
        [
            ("何を作りましたか。", ["クッキー", "ケーキ", "パン", "プリン"], 0),
            ("初めてでしたが、どうでしたか。", ["思ったより上手にできた", "全然できなかった", "難しすぎた", "失敗した"], 0),
            ("この人はどう思っていますか。", ["また作りたい", "もう作りたくない", "つまらなかった", "難しかった"], 0),
        ],
    ),
    (
        "kenketsu_annai",
        "Pengumuman Donor Darah",
        "来週の火曜日、学校の体育館で献血ができます。十六歳以上の人が"
        "参加できます。興味がある人は、保健室の先生に聞いてください。",
        "Selasa depan, bisa donor darah di gedung olahraga sekolah. "
        "Orang berusia 16 tahun ke atas bisa ikut. Yang tertarik, "
        "silakan tanya guru UKS.",
        [
            ("いつ献血ができますか。", ["来週の火曜日", "今週", "明日", "来月"], 0),
            ("どこで献血ができますか。", ["体育館", "教室", "保健室", "図書館"], 0),
            ("何歳以上の人が参加できますか。", ["十六歳以上", "十八歳以上", "十五歳以上", "二十歳以上"], 0),
        ],
    ),
    (
        "ryou_asagohan",
        "Menu Sarapan di Asrama",
        "寮の朝ご飯は、朝六時半から八時までです。パンとご飯、両方選ぶ"
        "ことができます。卵やサラダも一緒に食べられます。",
        "Sarapan di asrama dari jam 6.30 sampai jam 8 pagi. Bisa memilih "
        "roti atau nasi, keduanya tersedia. Telur dan salad juga bisa "
        "dimakan bersama.",
        [
            ("朝ご飯は何時から何時までですか。", ["六時半から八時", "七時から九時", "六時から七時", "五時から七時"], 0),
            ("何を選ぶことができますか。", ["パンとご飯", "パンだけ", "ご飯だけ", "何も選べない"], 0),
            ("他に何が食べられますか。", ["卵やサラダ", "肉だけ", "デザート", "何もない"], 0),
        ],
    ),
    (
        "ane_ouen_tegami",
        "Surat untuk Kakak yang Kuliah",
        "お姉ちゃん、大学生活はどうですか。勉強も一人暮らしも大変だと"
        "思いますが、頑張ってください。今度の休みに、家族みんなで会いに"
        "行こうと思っています。",
        "Kak, bagaimana kehidupan kuliah? Saya pikir belajar dan hidup "
        "sendiri itu berat, tapi semangat ya. Liburan berikutnya, kami "
        "berencana pergi menemuimu sekeluarga.",
        [
            ("この手紙は誰に書きましたか。", ["大学生の姉", "弟", "友達", "先生"], 0),
            ("大学生活について、どう言っていますか。", ["大変だと思う", "簡単だと思う", "つまらないと思う", "分からない"], 0),
            ("今度の休みに何をする予定ですか。", ["家族みんなで会いに行く", "電話する", "手紙を書く", "何もしない"], 0),
        ],
    ),
    (
        "kurasu_gae_oshirase",
        "Pengumuman Perpindahan Kelas",
        "来月から、クラス替えがあります。新しいクラスは、来週の金曜日に"
        "発表されます。友達と離れても、また新しい友達を作りましょう。",
        "Mulai bulan depan, ada pergantian kelas. Kelas baru akan "
        "diumumkan Jumat depan. Meskipun berpisah dengan teman, ayo buat "
        "teman baru lagi.",
        [
            ("いつクラス替えがありますか。", ["来月から", "今月", "来週", "今日"], 0),
            ("新しいクラスはいつ発表されますか。", ["来週の金曜日", "今日", "来月末", "分からない"], 0),
            ("この文章は何を勧めていますか。", ["新しい友達を作ること", "転校すること", "勉強すること", "休むこと"], 0),
        ],
    ),
    (
        "guraundo_shuuri",
        "Pengumuman Perbaikan Lapangan Sekolah",
        "来月、運動場を修理します。修理の間、体育の授業は体育館で行い"
        "ます。ボール遊びは公園でしてください。ご協力をお願いします。",
        "Bulan depan, lapangan sekolah akan diperbaiki. Selama "
        "perbaikan, pelajaran olahraga dilakukan di gedung olahraga. "
        "Bermain bola silakan di taman. Mohon kerja samanya.",
        [
            ("何を修理しますか。", ["運動場", "体育館", "教室", "プール"], 0),
            ("体育の授業はどこで行いますか。", ["体育館", "教室", "公園", "図書館"], 0),
            ("ボール遊びはどこでしますか。", ["公園", "教室", "廊下", "家"], 0),
        ],
    ),
    (
        "doubutsuen_pikunikku",
        "Cerita Piknik ke Kebun Binatang",
        "先週、クラスで動物園に行きました。象やライオンを近くで見ること"
        "ができました。お弁当を食べた後、パンダも見ました。とても楽しい"
        "遠足でした。",
        "Minggu lalu, kelas kami pergi ke kebun binatang. Kami bisa "
        "melihat gajah dan singa dari dekat. Setelah makan bekal, kami "
        "juga melihat panda. Piknik yang sangat menyenangkan.",
        [
            ("どこに行きましたか。", ["動物園", "水族館", "遊園地", "博物館"], 0),
            ("何を近くで見ることができましたか。", ["象やライオン", "魚", "鳥だけ", "虫"], 0),
            ("お弁当を食べた後、何を見ましたか。", ["パンダ", "キリン", "猿", "熊"], 0),
        ],
    ),
    (
        "tanjoubi_iwai_tegami",
        "Surat Ucapan Selamat Ulang Tahun untuk Teman",
        "誕生日おめでとう！今年もたくさん遊ぼうね。プレゼントを用意した"
        "から、今度会う時に渡すね。素敵な一年になりますように。",
        "Selamat ulang tahun! Tahun ini juga ayo banyak main. Aku "
        "sudah siapkan hadiah, akan kuberikan saat kita bertemu lagi. "
        "Semoga tahun ini menjadi tahun yang indah.",
        [
            ("この手紙は何のための手紙ですか。", ["誕生日のお祝い", "お礼", "お詫び", "お知らせ"], 0),
            ("プレゼントはいつ渡しますか。", ["今度会う時", "今日", "来年", "分からない"], 0),
            ("何を願っていますか。", ["素敵な一年になること", "早く会うこと", "プレゼントをもらうこと", "何も願っていない"], 0),
        ],
    ),
    (
        "toshokan_konpyuutaa_kisoku",
        "Aturan Ruang Komputer Perpustakaan Kota",
        "図書館のコンピューターは、一人一時間まで使うことができます。"
        "使う前に、受付で名前を書いてください。印刷は一枚十円です。",
        "Komputer di perpustakaan bisa digunakan maksimal satu jam per "
        "orang. Sebelum menggunakan, tolong tulis nama di meja "
        "resepsionis. Cetak dokumen 10 yen per lembar.",
        [
            ("一人何時間まで使うことができますか。", ["一時間", "二時間", "三十分", "三時間"], 0),
            ("使う前に何をしますか。", ["受付で名前を書く", "お金を払う", "予約する", "何もしない"], 0),
            ("印刷はいくらですか。", ["一枚十円", "一枚五円", "無料", "一枚五十円"], 0),
        ],
    ),
    (
        "bouizukatsudou_nittei",
        "Jadwal Kegiatan Pramuka",
        "ボーイスカウトの活動は、毎月第二土曜日にあります。キャンプの"
        "練習や、テントの立て方を学びます。参加したい人は、リーダーに"
        "連絡してください。",
        "Kegiatan pramuka pada hari Sabtu kedua setiap bulan. Kami "
        "belajar latihan berkemah dan cara mendirikan tenda. Yang ingin "
        "ikut, silakan hubungi ketua.",
        [
            ("活動はいつありますか。", ["毎月第二土曜日", "毎週日曜日", "毎日", "毎月最初の月曜日"], 0),
            ("何を学びますか。", ["キャンプの練習やテントの立て方", "料理", "音楽", "絵画"], 0),
            ("参加したい人はどうしますか。", ["リーダーに連絡する", "学校に行く", "何もしない", "親に聞く"], 0),
        ],
    ),
    (
        "imouto_benkyou_tetsudai",
        "Cerita Membantu Adik Belajar",
        "妹が算数の宿題で困っていたので、一緒に勉強しました。分からない"
        "問題を丁寧に説明したら、妹は分かるようになりました。「お兄ちゃん"
        "ありがとう」と言われて、嬉しかったです。",
        "Karena adik perempuan kesulitan dengan PR matematika, saya "
        "belajar bersamanya. Setelah menjelaskan soal yang sulit dengan "
        "cermat, adik jadi mengerti. Saat dikatakan 'Terima kasih Kak', "
        "saya senang.",
        [
            ("妹は何で困っていましたか。", ["算数の宿題", "国語の宿題", "体育", "音楽"], 0),
            ("どうやって説明しましたか。", ["丁寧に", "適当に", "急いで", "冷たく"], 0),
            ("何と言われて嬉しかったですか。", ["お兄ちゃんありがとう", "さようなら", "ごめんなさい", "また明日"], 0),
        ],
    ),
    (
        "koukan_ryuugaku_boshuu",
        "Pengumuman Pertukaran Pelajar",
        "来年、オーストラリアへの交換留学生を募集します。期間は三か月"
        "です。興味がある人は、来月末までに応募書類を提出してください。",
        "Tahun depan, kami merekrut pelajar pertukaran ke Australia. "
        "Periodenya tiga bulan. Yang tertarik, silakan serahkan formulir "
        "pendaftaran sampai akhir bulan depan.",
        [
            ("どこへの交換留学ですか。", ["オーストラリア", "アメリカ", "イギリス", "カナダ"], 0),
            ("期間はどのくらいですか。", ["三か月", "一か月", "半年", "一年"], 0),
            ("いつまでに書類を出しますか。", ["来月末まで", "今週まで", "明日まで", "来年まで"], 0),
        ],
    ),
    (
        "kodomo_no_hi_menyu",
        "Menu Spesial Hari Anak",
        "五月五日は子供の日です。学校の給食は、いつもより豪華なメニュー"
        "になります。今年は、ハンバーグとケーキが出るそうです。楽しみ"
        "ですね。",
        "Tanggal 5 Mei adalah Hari Anak. Makan siang sekolah menunya "
        "lebih mewah dari biasanya. Tahun ini, katanya akan ada hamburg "
        "steak dan kue. Menyenangkan ya.",
        [
            ("子供の日はいつですか。", ["五月五日", "五月一日", "四月五日", "六月五日"], 0),
            ("給食はいつもよりどうなりますか。", ["豪華になる", "少なくなる", "変わらない", "質素になる"], 0),
            ("今年、何が出るそうですか。", ["ハンバーグとケーキ", "カレーとサラダ", "ラーメンとフルーツ", "寿司とスープ"], 0),
        ],
    ),
    (
        "sensei_ayamari_tegami",
        "Surat Permintaan Maaf ke Guru",
        "先生、宿題を忘れてしまって、すみませんでした。次からは、寝る前"
        "に必ず確認します。今日中に必ず提出します。よろしくお願いします。",
        "Guru, maaf saya lupa membawa PR. Mulai sekarang, saya akan "
        "selalu memeriksa sebelum tidur. Hari ini pasti akan saya "
        "serahkan. Mohon bantuannya.",
        [
            ("何を忘れましたか。", ["宿題", "教科書", "傘", "弁当"], 0),
            ("次からどうしますか。", ["寝る前に必ず確認する", "何もしない", "友達に頼む", "諦める"], 0),
            ("いつ提出しますか。", ["今日中に", "明日", "来週", "分からない"], 0),
        ],
    ),
    (
        "toshokan_kyuujitsu_kaikan",
        "Pengumuman Perpustakaan Buka di Hari Libur",
        "今週の祝日、図書館は特別に開いています。時間は朝十時から午後"
        "四時までです。夏休みの読書感想文のために、ぜひ利用してください。",
        "Hari libur minggu ini, perpustakaan buka secara khusus. Jam "
        "dari 10 pagi sampai jam 4 sore. Silakan manfaatkan untuk "
        "laporan buku liburan musim panas.",
        [
            ("今週の祝日、図書館はどうなっていますか。", ["特別に開いている", "休みです", "いつも通り", "分からない"], 0),
            ("何時から何時までですか。", ["朝十時から午後四時", "朝九時から午後五時", "朝八時から正午", "昼から夜まで"], 0),
            ("何のために利用を勧めていますか。", ["読書感想文", "宿題全般", "遊び", "勉強会"], 0),
        ],
    ),
    (
        "toshokan_shuuri_oshirase",
        "Pengumuman Perbaikan Perpustakaan Sekolah",
        "来週の月曜日から水曜日まで、図書館は工事のため使えません。"
        "本を借りたい人は、今週中に借りてください。返却は木曜日から"
        "大丈夫です。質問がある人は先生に聞いてください。",
        "Dari hari Senin sampai Rabu minggu depan, perpustakaan tidak "
        "bisa digunakan karena ada perbaikan. Yang ingin meminjam "
        "buku, silakan pinjam dalam minggu ini. Pengembalian bisa "
        "dilakukan mulai hari Kamis. Yang punya pertanyaan, silakan "
        "tanya guru.",
        [
            ("図書館はいつから使えませんか。", ["来週の月曜日から", "今週の月曜日から", "来月から", "木曜日から"], 0),
            ("本を借りたい人はいつまでに借りますか。", ["今週中", "来週中", "来月中", "今日中"], 0),
            ("返却はいつから大丈夫ですか。", ["木曜日から", "月曜日から", "火曜日から", "水曜日から"], 0),
        ],
    ),
    (
        "hakubutsukan_kengaku_yotei",
        "Jadwal Kunjungan Museum",
        "来月、クラスで博物館へ行きます。集合は九時に学校の前です。"
        "バスで行きますので、お弁当を持ってきてください。博物館の"
        "中では大きい声で話さないでください。",
        "Bulan depan, kelas kami akan pergi ke museum. Berkumpul jam "
        "sembilan di depan sekolah. Karena naik bus, tolong bawa bekal "
        "makan siang. Di dalam museum, jangan berbicara dengan suara "
        "keras.",
        [
            ("集合はどこですか。", ["学校の前", "博物館の前", "駅の前", "公園の前"], 0),
            ("何を持ってきますか。", ["お弁当", "傘", "本", "カメラ"], 0),
            ("博物館の中で何をしてはいけませんか。", ["大きい声で話すこと", "写真を撮ること", "歩くこと", "座ること"], 0),
        ],
    ),
    (
        "atarashii_sensei_tegami",
        "Surat untuk Guru Baru",
        "新しい先生へ。四月から私たちのクラスの先生になってくれて、"
        "ありがとうございます。私たちのクラスは元気で、サッカーが"
        "好きな人が多いです。一緒に楽しく勉強しましょう。",
        "Kepada guru baru. Terima kasih sudah menjadi guru kelas kami "
        "mulai bulan April. Kelas kami penuh semangat, dan banyak yang "
        "suka sepak bola. Mari belajar dengan senang bersama-sama.",
        [
            ("いつから新しい先生になりましたか。", ["四月から", "一月から", "九月から", "十二月から"], 0),
            ("クラスの人は何が好きな人が多いですか。", ["サッカー", "野球", "水泳", "音楽"], 0),
            ("この手紙は誰に書きましたか。", ["新しい先生", "古い先生", "校長先生", "友達"], 0),
        ],
    ),
    (
        "tokubetsu_hiruhan_menu",
        "Menu Makan Siang Spesial",
        "今日の給食は特別メニューです。カレーライスとサラダとフルーツ"
        "があります。デザートはアイスクリームです。楽しみにしてくだ"
        "さい。",
        "Makan siang hari ini adalah menu spesial. Ada nasi kari, "
        "salad, dan buah. Makanan penutupnya es krim. Silakan "
        "nantikan.",
        [
            ("今日の給食は何がありますか。", ["カレーライスとサラダとフルーツ", "ラーメンとぎょうざ", "パンとスープ", "おにぎりと魚"], 0),
            ("デザートは何ですか。", ["アイスクリーム", "ケーキ", "プリン", "ゼリー"], 0),
            ("今日の給食はどんな給食ですか。", ["特別メニュー", "いつもと同じメニュー", "少ないメニュー", "新しいメニュー"], 0),
        ],
    ),
    (
        "undoukai_taikai_oshirase",
        "Pengumuman Kompetisi Olahraga",
        "来週の土曜日に運動会があります。雨の場合は、日曜日になりま"
        "す。お弁当と水を持ってきてください。応援も頑張りましょう。",
        "Hari Sabtu minggu depan ada pertandingan olahraga. Jika hujan, "
        "akan dipindah ke hari Minggu. Tolong bawa bekal dan air "
        "minum. Mari bersemangat mendukung juga.",
        [
            ("運動会はいつですか。", ["来週の土曜日", "来週の日曜日", "今週の土曜日", "来月の土曜日"], 0),
            ("雨の場合はどうなりますか。", ["日曜日になる", "中止になる", "来月になる", "変わらない"], 0),
            ("何を持ってきますか。", ["お弁当と水", "傘とかさ", "本とペン", "お金だけ"], 0),
        ],
    ),
    (
        "kouen_souji_tetsudai",
        "Cerita Membantu Membersihkan Taman",
        "日曜日、私は近くの公園で掃除を手伝いました。ゴミを拾ったり、"
        "花に水をあげたりしました。みんなで働いたので、公園がきれい"
        "になりました。とても気持ちがよかったです。",
        "Hari Minggu, saya membantu bersih-bersih di taman dekat "
        "rumah. Saya memungut sampah dan menyiram bunga. Karena semua "
        "bekerja bersama, taman jadi bersih. Rasanya sangat "
        "menyenangkan.",
        [
            ("いつ公園の掃除をしましたか。", ["日曜日", "土曜日", "月曜日", "金曜日"], 0),
            ("何をしましたか。", ["ゴミを拾ったり花に水をあげたりした", "本を読んだ", "遊んだだけ", "寝ていた"], 0),
            ("公園はどうなりましたか。", ["きれいになった", "汚くなった", "変わらなかった", "閉まった"], 0),
        ],
    ),
    (
        "ongaku_renshuu_jikanwari",
        "Jadwal Praktik Musik",
        "音楽クラブの練習は火曜日と木曜日の放課後です。場所は音楽室"
        "です。楽器を忘れないでください。発表会は来月の十五日です。",
        "Latihan klub musik adalah hari Selasa dan Kamis setelah pulang "
        "sekolah. Tempatnya di ruang musik. Jangan lupa membawa alat "
        "musik. Konsernya bulan depan tanggal lima belas.",
        [
            ("練習はいつですか。", ["火曜日と木曜日", "月曜日と水曜日", "土曜日と日曜日", "毎日"], 0),
            ("練習の場所はどこですか。", ["音楽室", "体育館", "教室", "公園"], 0),
            ("発表会はいつですか。", ["来月の十五日", "今月の十五日", "来週の十五日", "来年の十五日"], 0),
        ],
    ),
    (
        "toshokan_ikkou_oshirase",
        "Pengumuman Perpindahan Perpustakaan",
        "学校の図書館は来月、二階から一階に引っ越します。引っ越しの"
        "間、図書館は三日間使えません。本を読みたい人は、教室で読ん"
        "でください。",
        "Perpustakaan sekolah bulan depan akan pindah dari lantai dua "
        "ke lantai satu. Selama pindahan, perpustakaan tidak bisa "
        "digunakan selama tiga hari. Yang ingin membaca buku, silakan "
        "membaca di kelas.",
        [
            ("図書館はどこからどこに引っ越しますか。", ["二階から一階", "一階から二階", "三階から一階", "一階から三階"], 0),
            ("引っ越しの間、図書館は何日間使えませんか。", ["三日間", "一日間", "五日間", "一週間"], 0),
            ("本を読みたい人はどこで読みますか。", ["教室", "体育館", "公園", "家"], 0),
        ],
    ),
    (
        "sotsugyou_oiwai_tegami",
        "Surat Ucapan Selamat Kelulusan",
        "卒業おめでとうございます。六年間、一緒に勉強できて楽しかった"
        "です。中学校でも頑張ってください。時々、遊びに来てください"
        "ね。",
        "Selamat atas kelulusannya. Selama enam tahun, senang sekali "
        "bisa belajar bersama. Semoga semangat juga di SMP. Sesekali, "
        "mainlah ke sini ya.",
        [
            ("何年間一緒に勉強しましたか。", ["六年間", "三年間", "一年間", "十年間"], 0),
            ("これからどこで頑張りますか。", ["中学校", "小学校", "高校", "大学"], 0),
            ("何をお願いしていますか。", ["時々遊びに来ること", "毎日来ること", "勉強すること", "働くこと"], 0),
        ],
    ),
    (
        "ichiba_kaimono_chichi",
        "Cerita Belanja di Pasar bersama Ayah",
        "土曜日の朝、父と市場へ買い物に行きました。新鮮な魚と野菜を"
        "買いました。市場はとてもにぎやかで、いろいろな声が聞こえま"
        "した。楽しい時間でした。",
        "Sabtu pagi, saya pergi belanja ke pasar bersama ayah. Kami "
        "membeli ikan dan sayur yang segar. Pasar sangat ramai, dan "
        "terdengar berbagai suara. Waktu yang menyenangkan.",
        [
            ("誰と市場へ行きましたか。", ["父", "母", "兄", "友達"], 0),
            ("何を買いましたか。", ["新鮮な魚と野菜", "肉と果物", "パンと牛乳", "お菓子"], 0),
            ("市場はどんな様子でしたか。", ["とてもにぎやか", "静か", "誰もいない", "暗い"], 0),
        ],
    ),
]

N4_ENTRIES = [
    (
        "mensetsu_kekka",
        "Hasil Wawancara Kerja",
        "田中様　先日は面接に来ていただき、ありがとうございました。とても"
        "良い印象を持ちました。来週の月曜日から働いていただけますか。詳しい"
        "ことは電話でお伝えします。何か質問があれば、いつでもご連絡くだ"
        "さい。",
        "Yth. Tanaka. Terima kasih sudah datang wawancara beberapa hari "
        "lalu. Kami mendapat kesan yang sangat baik. Bisakah Anda mulai "
        "bekerja hari Senin minggu depan? Detailnya akan kami sampaikan "
        "lewat telepon. Jika ada pertanyaan, silakan hubungi kapan saja.",
        [
            ("いつから働くことができますか。", ["来週の月曜日", "今日", "来月", "明日"], 0),
            ("詳しいことはどうやって伝えられますか。", ["電話で", "メールで", "手紙で", "直接会って"], 0),
            ("質問がある時、どうすればいいですか。", ["いつでも連絡する", "来週まで待つ", "何もしない", "面接に来る"], 0),
        ],
    ),
    (
        "taifuu_keikai",
        "Peringatan Topan",
        "明日、大きな台風が来ると言われています。学校は休みになるかも"
        "しれません。強い風で物が飛ぶことがあるので、外に出ない方が"
        "いいです。窓もしっかり閉めてください。もし停電したら、懐中電灯を"
        "使ってください。",
        "Dikatakan besok akan datang topan besar. Sekolah mungkin akan "
        "diliburkan. Karena angin kencang bisa membuat benda-benda "
        "beterbangan, sebaiknya jangan keluar rumah. Tolong tutup jendela "
        "dengan rapat. Kalau listrik padam, gunakan senter.",
        [
            ("明日、何が来ると言われていますか。", ["大きな台風", "大雨", "地震", "大雪"], 0),
            ("どうして外に出ない方がいいですか。", ["強い風で物が飛ぶことがあるから", "寒いから", "人が多いから", "店が閉まるから"], 0),
            ("停電したら何を使いますか。", ["懐中電灯", "ろうそく", "スマホ", "ラジオ"], 0),
        ],
    ),
    (
        "resutoran_review",
        "Ulasan Restoran",
        "先週、新しくできたイタリアレストランに行ってきました。パスタが"
        "とても美味しかったです。店員さんも親切で、気持ちよく食事が"
        "できました。ただ、値段が少し高いと感じました。また行きたいと"
        "思っていますが、特別な日に行こうと思います。",
        "Minggu lalu saya pergi ke restoran Italia yang baru buka. "
        "Pastanya sangat enak. Pelayannya juga ramah, jadi bisa makan "
        "dengan nyaman. Hanya saja, saya merasa harganya agak mahal. Saya "
        "ingin pergi lagi, tapi berpikir akan pergi di hari yang spesial.",
        [
            ("このレストランは何料理の店ですか。", ["イタリア料理", "日本料理", "中華料理", "フランス料理"], 0),
            ("この人はレストランについてどう思いましたか。", ["値段が少し高い", "とても安い", "店員が不親切", "料理がまずい"], 0),
            ("いつまた行こうと思っていますか。", ["特別な日", "明日", "毎週", "二度と行かない"], 0),
        ],
    ),
    (
        "ryokou_burogu",
        "Blog Perjalanan",
        "北海道旅行から帰ってきました。雪がたくさん降っていて、とても"
        "きれいでした。温泉に入ったら、体がぽかぽか温まりました。地元の"
        "魚もとても美味しくて、たくさん食べてしまいました。来年もまた"
        "行きたいと思います。",
        "Saya baru pulang dari perjalanan ke Hokkaido. Salju turun banyak "
        "dan sangat indah. Setelah masuk onsen, badan jadi hangat. Ikan "
        "lokalnya juga sangat enak, sampai saya makan banyak sekali. Saya "
        "ingin pergi lagi tahun depan.",
        [
            ("どこへ旅行に行きましたか。", ["北海道", "沖縄", "東京", "京都"], 0),
            ("温泉に入ったらどうなりましたか。", ["体が温まりました", "疲れました", "眠くなりました", "寒くなりました"], 0),
            ("何をたくさん食べましたか。", ["地元の魚", "肉", "野菜", "お菓子"], 0),
        ],
    ),
    (
        "iken_essay",
        "Esai Pendapat tentang Media Sosial",
        "最近、SNSを使う人がとても多くなりました。友達と簡単に連絡できる"
        "ので便利です。しかし、SNSを見すぎると、時間がなくなってしまう"
        "こともあります。私は一日一時間だけSNSを見ることに決めました。"
        "おかげで、他のことをする時間が増えました。",
        "Belakangan ini, banyak sekali orang yang menggunakan media "
        "sosial. Karena bisa dengan mudah berhubungan dengan teman, itu "
        "praktis. Tapi, kalau terlalu banyak melihat media sosial, kadang "
        "waktu jadi habis. Saya memutuskan hanya melihat media sosial satu "
        "jam sehari. Berkatnya, waktu untuk hal lain jadi bertambah.",
        [
            ("SNSのいいところは何ですか。", ["友達と簡単に連絡できること", "お金がかかること", "時間が減ること", "難しいこと"], 0),
            ("この人は一日どのくらいSNSを見ますか。", ["一時間", "三時間", "五時間", "見ません"], 0),
            ("SNSの時間を決めた結果、どうなりましたか。", ["他のことをする時間が増えました", "友達が減りました", "眠れなくなりました", "何も変わりませんでした"], 0),
        ],
    ),
    (
        "seihin_hyouka",
        "Ulasan Produk",
        "先月買った掃除機について書きます。とても軽くて、使いやすいです。"
        "音も静かなので、夜でも使うことができます。ただ、値段が高かった"
        "ので、買うかどうか迷いました。でも、買ってよかったと思って"
        "います。",
        "Saya menulis tentang penyedot debu yang saya beli bulan lalu. "
        "Sangat ringan dan mudah digunakan. Suaranya juga tenang, jadi "
        "bisa dipakai bahkan di malam hari. Hanya saja, karena harganya "
        "mahal, saya sempat ragu untuk membeli. Tapi, saya merasa senang "
        "sudah membelinya.",
        [
            ("この掃除機はどんな掃除機ですか。", ["軽くて使いやすい", "重くて使いにくい", "音がうるさい", "安い"], 0),
            ("どうして買うかどうか迷いましたか。", ["値段が高かったから", "色が嫌いだったから", "大きすぎたから", "友達が反対したから"], 0),
            ("今、この人はどう思っていますか。", ["買ってよかった", "買わなければよかった", "まだ迷っている", "後悔している"], 0),
        ],
    ),
    (
        "kujou_tegami",
        "Surat Keluhan",
        "先日、そちらのホテルに泊まりました。部屋はきれいでしたが、隣の"
        "部屋の音がとてもうるさくて、よく眠れませんでした。次に泊まる時"
        "は、静かな部屋にしていただけますか。よろしくお願いいたします。",
        "Beberapa hari lalu, saya menginap di hotel Anda. Kamarnya "
        "bersih, tapi suara dari kamar sebelah sangat berisik, jadi saya "
        "tidak bisa tidur nyenyak. Saat menginap lagi lain kali, bisakah "
        "diberikan kamar yang tenang? Mohon bantuannya.",
        [
            ("部屋についてどう書いてありますか。", ["きれいだった", "汚かった", "狭かった", "暗かった"], 0),
            ("どうしてよく眠れませんでしたか。", ["隣の部屋の音がうるさかったから", "暑かったから", "ベッドが硬かったから", "光が明るかったから"], 0),
            ("次に何をお願いしていますか。", ["静かな部屋", "広い部屋", "安い部屋", "高い部屋"], 0),
        ],
    ),
    (
        "shoutaijou_henji",
        "Balasan Undangan",
        "ご招待ありがとうございます。ぜひ結婚式に出席させていただきます。"
        "何か手伝えることがあれば、遠慮なく言ってください。当日を楽しみに"
        "しています。もし料理にアレルギーがある人がいれば、事前に教えて"
        "ください。",
        "Terima kasih atas undangannya. Saya dengan senang hati akan "
        "hadir di pernikahan. Kalau ada yang bisa saya bantu, jangan "
        "sungkan untuk memberi tahu. Saya menantikan hari itu. Jika ada "
        "yang alergi terhadap makanan, tolong beri tahu sebelumnya.",
        [
            ("この人は何に出席しますか。", ["結婚式", "誕生日会", "卒業式", "送別会"], 0),
            ("この人は何をすると言っていますか。", ["手伝う", "料理を作る", "写真を撮る", "スピーチをする"], 0),
            ("何を事前に教えてほしいと言っていますか。", ["料理のアレルギー", "服の色", "車で来るかどうか", "到着時間"], 0),
        ],
    ),
    (
        "hikkoshi_oshirase",
        "Pengumuman Pindah Alamat",
        "この度、事務所を移転することになりました。新しい住所は、来月"
        "一日から使えます。電話番号は変わりません。移転の間、少しの間、"
        "連絡が遅くなることがあります。ご迷惑をおかけしますが、よろしく"
        "お願いいたします。",
        "Kali ini, kantor kami akan pindah. Alamat baru bisa digunakan "
        "mulai tanggal 1 bulan depan. Nomor telepon tidak berubah. Selama "
        "masa pindahan, mungkin balasan agak lambat sebentar. Mohon maaf "
        "atas ketidaknyamanannya, mohon bantuannya.",
        [
            ("何が変わりますか。", ["住所", "電話番号", "会社の名前", "社長"], 0),
            ("新しい住所はいつから使えますか。", ["来月一日から", "今日から", "来週から", "今月末から"], 0),
            ("移転の間、何が起こるかもしれませんか。", ["連絡が遅くなる", "電話が使えなくなる", "会社が休みになる", "値段が上がる"], 0),
        ],
    ),
    (
        "kenkou_kiji",
        "Artikel Tips Kesehatan",
        "健康のために、毎日少しでも運動することが大切だと言われています。"
        "忙しくて時間がない人は、階段を使ったり、少し遠くまで歩いたり"
        "するだけでもいいそうです。また、よく寝ることも健康にとって"
        "重要です。",
        "Untuk kesehatan, dikatakan penting untuk berolahraga sedikit "
        "setiap hari. Bagi yang sibuk dan tidak punya waktu, katanya "
        "cukup dengan naik tangga atau berjalan sedikit lebih jauh saja. "
        "Selain itu, tidur yang cukup juga penting untuk kesehatan.",
        [
            ("健康のために何が大切だと言われていますか。", ["毎日少しでも運動すること", "たくさん食べること", "毎日甘い物を食べること", "一日中寝ること"], 0),
            ("忙しい人は何をすればいいですか。", ["階段を使ったり歩いたりする", "ジムに行く", "運動しなくていい", "薬を飲む"], 0),
            ("健康にとって他に何が重要ですか。", ["よく寝ること", "たくさん働くこと", "テレビを見ること", "買い物すること"], 0),
        ],
    ),
    (
        "toshokan_open",
        "Pengumuman Perpustakaan Baru Dibuka",
        "来月、駅の近くに新しい図書館ができます。開館時間は朝九時から夜"
        "八時までです。子供のための絵本コーナーもあります。誰でも無料で"
        "利用することができます。ぜひ一度、来てみてください。",
        "Bulan depan, perpustakaan baru akan dibuka dekat stasiun. Jam "
        "bukanya dari jam 9 pagi sampai jam 8 malam. Ada juga sudut buku "
        "bergambar untuk anak-anak. Siapa saja bisa menggunakannya secara "
        "gratis. Silakan datang sekali ke sana.",
        [
            ("新しい図書館はどこにできますか。", ["駅の近く", "学校の隣", "公園の中", "病院の前"], 0),
            ("開館時間は何時までですか。", ["夜八時", "夜六時", "夜十時", "夕方五時"], 0),
            ("利用するのにお金がかかりますか。", ["いいえ、無料です", "はい、少しかかります", "はい、高いです", "分かりません"], 0),
        ],
    ),
    (
        "kantan_reshipi",
        "Resep Sederhana",
        "簡単な卵焼きの作り方を紹介します。まず、卵を二つ割って、よく"
        "混ぜます。次に、フライパンに油を入れて温めます。卵を入れたら、"
        "弱火でゆっくり焼いてください。焦げないように気をつけましょう。",
        "Saya perkenalkan cara membuat telur dadar sederhana. Pertama, "
        "pecahkan dua butir telur dan aduk rata. Selanjutnya, panaskan "
        "minyak di wajan. Setelah memasukkan telur, masak perlahan dengan "
        "api kecil. Hati-hati agar tidak gosong.",
        [
            ("卵をいくつ使いますか。", ["二つ", "一つ", "三つ", "四つ"], 0),
            ("フライパンに何を入れて温めますか。", ["油", "水", "塩", "砂糖"], 0),
            ("どんな火で焼きますか。", ["弱火", "強火", "中火", "火を使わない"], 0),
        ],
    ),
    (
        "shigoto_hajimete",
        "Pengalaman Hari Pertama Kerja",
        "今日は初めての出勤日でした。緊張して、朝早く起きてしまいました。"
        "会社に着いたら、同僚がやさしく声をかけてくれました。仕事はまだ"
        "よく分かりませんが、少しずつ覚えていきたいと思います。",
        "Hari ini adalah hari pertama saya masuk kerja. Karena gugup, "
        "saya bangun terlalu pagi. Setelah sampai di kantor, rekan kerja "
        "menyapa saya dengan ramah. Saya belum begitu paham pekerjaannya, "
        "tapi ingin belajar sedikit demi sedikit.",
        [
            ("どうして朝早く起きてしまいましたか。", ["緊張していたから", "目覚まし時計が壊れていたから", "用事があったから", "眠れなかったから"], 0),
            ("会社に着いたら、誰が声をかけてくれましたか。", ["同僚", "家族", "先生", "友達"], 0),
            ("この人は仕事についてどう思っていますか。", ["少しずつ覚えていきたい", "もう全部分かる", "すぐ辞めたい", "とても簡単だ"], 0),
        ],
    ),
    (
        "densha_norikata",
        "Panduan Naik Kereta",
        "初めて日本の電車に乗る人のために説明します。まず、切符を買うか、"
        "ICカードを用意してください。ホームに入る時は、改札で切符を"
        "通します。電車を降りる駅を間違えないように、駅名をよく見て"
        "ください。",
        "Saya jelaskan untuk orang yang baru pertama kali naik kereta di "
        "Jepang. Pertama, silakan beli tiket atau siapkan kartu IC. Saat "
        "masuk peron, lewatkan tiket di gerbang tiket. Agar tidak salah "
        "turun di stasiun, tolong lihat baik-baik nama stasiunnya.",
        [
            ("電車に乗る前に何を用意しますか。", ["切符かICカード", "傘", "お弁当", "地図"], 0),
            ("ホームに入る時、何をしますか。", ["改札で切符を通す", "お金を払う", "荷物を預ける", "走る"], 0),
            ("何に気をつけますか。", ["降りる駅を間違えないこと", "電車の色", "席の場所", "時間"], 0),
        ],
    ),
    (
        "gengo_kouza",
        "Iklan Kursus Bahasa",
        "英会話を学びたい人を募集しています。初心者から上級者まで、"
        "レベルに合わせたクラスがあります。授業は週に二回、夜七時から"
        "始まります。先生は全員経験豊かなので、安心して学ぶことが"
        "できます。",
        "Kami sedang mencari orang yang ingin belajar percakapan bahasa "
        "Inggris. Ada kelas sesuai level, dari pemula sampai mahir. "
        "Kelasnya dua kali seminggu, dimulai jam 7 malam. Semua guru "
        "berpengalaman, jadi bisa belajar dengan tenang.",
        [
            ("何のクラスですか。", ["英会話", "日本語", "数学", "料理"], 0),
            ("授業は週に何回ありますか。", ["二回", "一回", "三回", "毎日"], 0),
            ("先生についてどう書いてありますか。", ["経験豊かだ", "初めての先生だ", "厳しい", "若い"], 0),
        ],
    ),
    (
        "yoyaku_kakunin",
        "Email Konfirmasi Reservasi",
        "この度はご予約いただき、ありがとうございます。ご予約日は来週の"
        "金曜日、午後七時からです。人数は四名様で承っております。もし"
        "変更やキャンセルがある場合は、前日までにご連絡ください。",
        "Terima kasih atas reservasi Anda kali ini. Tanggal reservasi "
        "Anda adalah hari Jumat depan, mulai jam 7 malam. Kami menerima "
        "untuk 4 orang. Jika ada perubahan atau pembatalan, silakan "
        "hubungi kami sampai sehari sebelumnya.",
        [
            ("予約はいつですか。", ["来週の金曜日", "今週の月曜日", "明日", "来月"], 0),
            ("何名で予約しましたか。", ["四名", "二名", "三名", "五名"], 0),
            ("変更がある場合、いつまでに連絡しますか。", ["前日まで", "当日でもいい", "一週間前まで", "連絡しなくていい"], 0),
        ],
    ),
    (
        "shumi_burogu",
        "Blog tentang Hobi Baru",
        "最近、写真を撮ることが好きになりました。休みの日に、いろいろな"
        "場所へ行って写真を撮っています。まだ上手ではありませんが、"
        "少しずつカメラの使い方が分かってきました。これからも続けて"
        "いきたいです。",
        "Belakangan ini, saya jadi suka memotret. Di hari libur, saya "
        "pergi ke berbagai tempat untuk memotret. Belum begitu mahir, "
        "tapi sedikit demi sedikit mulai paham cara menggunakan kamera. "
        "Saya ingin terus melanjutkannya ke depannya.",
        [
            ("この人は最近何が好きになりましたか。", ["写真を撮ること", "料理をすること", "本を読むこと", "歌うこと"], 0),
            ("いつ写真を撮りに行きますか。", ["休みの日", "平日", "毎朝", "仕事の後"], 0),
            ("この人はカメラの使い方についてどう言っていますか。", ["少しずつ分かってきた", "全然分からない", "もう完璧だ", "難しすぎる"], 0),
        ],
    ),
    (
        "douro_kouji",
        "Pengumuman Perbaikan Jalan",
        "来週から、駅前の道路で工事を行います。工事の間、道が狭くなり"
        "ますので、車を運転する方はお気をつけください。歩く人のための"
        "道は別に用意されています。ご不便をおかけしますが、よろしく"
        "お願いします。",
        "Mulai minggu depan, akan ada perbaikan di jalan depan stasiun. "
        "Selama perbaikan, jalan akan menyempit, jadi bagi yang "
        "mengendarai mobil harap berhati-hati. Jalan untuk pejalan kaki "
        "disiapkan secara terpisah. Mohon maaf atas ketidaknyamanannya, "
        "mohon bantuannya.",
        [
            ("どこで工事が行われますか。", ["駅前の道路", "学校の中", "公園", "病院"], 0),
            ("工事の間、道はどうなりますか。", ["狭くなります", "広くなります", "閉まります", "きれいになります"], 0),
            ("歩く人のためにどうなっていますか。", ["別の道が用意されている", "道がない", "工事に参加する", "何もない"], 0),
        ],
    ),
    (
        "ryuugaku_tegami",
        "Surat dari Anak yang Kuliah di Luar Negeri",
        "お父さん、お母さん、元気ですか。こちらの生活にもだいぶ慣れて"
        "きました。最初は言葉が分からなくて大変でしたが、友達がたくさん"
        "できて、毎日楽しいです。今度の休みには、日本に帰るつもりです。"
        "会えるのを楽しみにしています。",
        "Ayah, Ibu, apa kabar? Saya sudah lumayan terbiasa dengan "
        "kehidupan di sini. Awalnya sulit karena tidak mengerti bahasa, "
        "tapi sekarang punya banyak teman, dan setiap hari menyenangkan. "
        "Liburan berikutnya, saya berencana pulang ke Jepang. Saya "
        "menantikan bisa bertemu.",
        [
            ("最初、何が大変でしたか。", ["言葉が分からなかったこと", "お金がなかったこと", "病気になったこと", "一人だったこと"], 0),
            ("今の生活はどうですか。", ["毎日楽しい", "とても寂しい", "大変だ", "つまらない"], 0),
            ("今度の休み、この人は何をするつもりですか。", ["日本に帰る", "旅行に行く", "働く", "学校を辞める"], 0),
        ],
    ),
    (
        "undou_kouka",
        "Artikel tentang Manfaat Olahraga",
        "毎日少し運動をすることで、体だけでなく気持ちも元気になると言わ"
        "れています。忙しい人でも、朝に軽く体を動かすだけで、一日を"
        "気持ちよく始めることができるそうです。無理をせず、自分に合った"
        "運動を見つけることが大切です。",
        "Dikatakan bahwa dengan berolahraga sedikit setiap hari, bukan "
        "hanya tubuh, tapi perasaan juga menjadi lebih semangat. Bahkan "
        "orang yang sibuk pun, katanya cukup menggerakkan tubuh ringan di "
        "pagi hari, bisa memulai hari dengan perasaan yang baik. Penting "
        "untuk menemukan olahraga yang cocok tanpa memaksakan diri.",
        [
            ("毎日運動をすると何が元気になりますか。", ["体と気持ち", "体だけ", "お金", "仕事"], 0),
            ("忙しい人はいつ運動すればいいですか。", ["朝、軽く", "夜遅く", "週末だけ", "運動しなくていい"], 0),
            ("何が大切だと書いてありますか。", ["自分に合った運動を見つけること", "毎日長時間運動すること", "一番難しい運動をすること", "友達と同じ運動をすること"], 0),
        ],
    ),
    (
        "hon_ten_waribiki",
        "Pengumuman Diskon Toko Buku",
        "今週末、当店では本を買うと十パーセント割引になります。学生証を"
        "見せると、さらに五パーセント安くなります。この機会にぜひ"
        "お越しください。",
        "Akhir pekan ini, jika membeli buku di toko kami, dapat diskon "
        "10 persen. Jika menunjukkan kartu pelajar, jadi lebih murah 5 "
        "persen lagi. Silakan datang di kesempatan ini.",
        [
            ("今週末、何を買うと安くなりますか。", ["本", "文房具", "雑誌", "CD"], 0),
            ("学生証を見せるとどうなりますか。", ["さらに五パーセント安くなる", "何もない", "本がもらえる", "ポイントがつく"], 0),
            ("割引は何パーセントですか。", ["十パーセント", "二十パーセント", "五パーセント", "三十パーセント"], 0),
        ],
    ),
    (
        "sobo_ryouri",
        "Belajar Memasak dari Nenek",
        "先週、祖母の家に行って、伝統的な料理の作り方を教えてもらった。"
        "祖母の手つきはとても速くて、驚いた。私も練習すれば、いつか同じ"
        "ように作れるようになりたいと思う。",
        "Minggu lalu saya pergi ke rumah nenek dan diajari cara membuat "
        "masakan tradisional. Gerakan tangan nenek sangat cepat, saya "
        "terkejut. Saya berpikir jika saya berlatih, suatu hari saya "
        "ingin bisa membuatnya dengan cara yang sama.",
        [
            ("誰に料理を教えてもらいましたか。", ["祖母", "母", "姉", "先生"], 0),
            ("祖母の手つきはどうでしたか。", ["とても速かった", "遅かった", "普通だった", "分からない"], 0),
            ("この人はどうなりたいと思っていますか。", ["同じように作れるようになりたい", "料理をやめたい", "もっと簡単な料理をしたい", "何も思っていない"], 0),
        ],
    ),
    (
        "kyuuka_shinsei",
        "Email Permintaan Cuti Kerja",
        "課長、来週の水曜日、家族の用事のため、休みをいただきたいと"
        "思います。仕事はできるだけ火曜日までに終わらせるつもりです。"
        "ご確認よろしくお願いいたします。",
        "Pak Kepala Bagian, Rabu depan, karena ada urusan keluarga, saya "
        "ingin izin cuti. Pekerjaan akan saya usahakan selesai sampai "
        "Selasa. Mohon konfirmasinya.",
        [
            ("いつ休みたいと言っていますか。", ["来週の水曜日", "今週の月曜日", "明日", "来月"], 0),
            ("どうして休みたいのですか。", ["家族の用事のため", "病気のため", "旅行のため", "疲れたため"], 0),
            ("仕事はいつまでに終わらせるつもりですか。", ["火曜日まで", "水曜日まで", "木曜日まで", "今日中"], 0),
        ],
    ),
    (
        "chokin_shuukan",
        "Artikel tentang Kebiasaan Menabung",
        "毎月給料が入ったら、まず一定の金額を貯金に回すという人が増えて"
        "いる。残ったお金で生活する方法は、無理なく貯金を続けられると"
        "言われている。小さな習慣が、将来の安心につながるようだ。",
        "Semakin banyak orang yang setiap bulan begitu gaji masuk, "
        "langsung menyisihkan jumlah tertentu untuk ditabung terlebih "
        "dahulu. Cara hidup dengan sisa uang dikatakan bisa melanjutkan "
        "tabungan tanpa memaksakan diri. Kebiasaan kecil sepertinya "
        "berujung pada rasa aman di masa depan.",
        [
            ("増えている人はどうしていますか。", ["給料が入ったらまず貯金に回す", "全部使ってしまう", "貯金しない", "お金を借りる"], 0),
            ("残ったお金でどうしますか。", ["生活する", "旅行する", "貯金する", "何もしない"], 0),
            ("小さな習慣は何につながりますか。", ["将来の安心", "すぐの豊かさ", "有名になること", "何も変わらない"], 0),
        ],
    ),
    (
        "atarashii_machi_burogu",
        "Blog tentang Adaptasi di Kota Baru",
        "新しい町に引っ越してきて、三か月が経った。最初は道も分からず、"
        "不安なことが多かった。しかし、近所の人たちが親切に教えてくれて、"
        "少しずつ生活しやすくなってきた。",
        "Sudah tiga bulan sejak pindah ke kota baru. Awalnya jalan pun "
        "tidak tahu, banyak hal yang membuat cemas. Namun, orang-orang "
        "di sekitar dengan ramah memberi tahu, dan sedikit demi sedikit "
        "kehidupan menjadi lebih mudah.",
        [
            ("引っ越してきてどのくらい経ちましたか。", ["三か月", "一か月", "半年", "一年"], 0),
            ("最初、この人はどうでしたか。", ["不安なことが多かった", "とても楽しかった", "何も感じなかった", "忙しかった"], 0),
            ("どうして生活しやすくなってきましたか。", ["近所の人が親切に教えてくれたから", "お金が増えたから", "仕事を辞めたから", "引っ越したから"], 0),
        ],
    ),
    (
        "kurabu_taikai",
        "Surat Pengunduran Diri dari Klub",
        "部長へ　長い間お世話になりました。勉強に集中したいので、テニス"
        "部をやめることにしました。今まで教えてくれたことに感謝して"
        "います。皆さんの活躍を応援しています。",
        "Kepada ketua klub. Terima kasih atas bimbingan selama ini. "
        "Karena ingin fokus belajar, saya memutuskan berhenti dari klub "
        "tenis. Saya berterima kasih atas semua yang telah diajarkan. "
        "Saya akan mendukung kesuksesan kalian semua.",
        [
            ("どうしてクラブをやめますか。", ["勉強に集中したいから", "怪我をしたから", "つまらないから", "忙しいから"], 0),
            ("何部をやめますか。", ["テニス部", "サッカー部", "野球部", "音楽部"], 0),
            ("この手紙で何を伝えていますか。", ["感謝", "怒り", "悲しみ", "心配"], 0),
        ],
    ),
    (
        "apuri_hyouka",
        "Ulasan Aplikasi Belajar Bahasa",
        "この語学学習アプリを三か月使っています。毎日少しずつ勉強できる"
        "ので、続けやすいです。発音の練習機能も便利です。ただ、無料版では"
        "使える機能が少ないのが残念です。",
        "Saya menggunakan aplikasi belajar bahasa ini selama tiga "
        "bulan. Karena bisa belajar sedikit demi sedikit setiap hari, "
        "mudah dilanjutkan. Fitur latihan pengucapan juga praktis. Hanya "
        "saja, sayangnya fitur yang bisa digunakan di versi gratis "
        "sedikit.",
        [
            ("このアプリをどのくらい使っていますか。", ["三か月", "一か月", "半年", "一年"], 0),
            ("このアプリのいいところは何ですか。", ["毎日少しずつ勉強できること", "無料なこと", "有名なこと", "簡単すぎること"], 0),
            ("何が残念だと言っていますか。", ["無料版の機能が少ないこと", "デザインが悪いこと", "音が出ないこと", "遅いこと"], 0),
        ],
    ),
    (
        "shuugyou_jikan_henkou",
        "Pengumuman Perubahan Jam Kerja",
        "来月から、会社の勤務時間が変わります。新しい時間は、朝九時から"
        "夕方五時までです。今までより三十分早く終わります。詳しいことは、"
        "総務部にお問い合わせください。",
        "Mulai bulan depan, jam kerja perusahaan berubah. Jam baru "
        "adalah dari jam 9 pagi sampai jam 5 sore. Selesai 30 menit "
        "lebih awal dari sebelumnya. Untuk detail, silakan tanyakan ke "
        "departemen umum.",
        [
            ("新しい勤務時間はいつからですか。", ["朝九時から夕方五時", "朝八時から夕方五時", "朝九時から夕方六時", "朝十時から夕方六時"], 0),
            ("今までよりどのくらい早く終わりますか。", ["三十分", "一時間", "十五分", "二時間"], 0),
            ("詳しいことはどこに聞きますか。", ["総務部", "人事部", "営業部", "経理部"], 0),
        ],
    ),
    (
        "hikouki_hajimete",
        "Pengalaman Pertama Kali Naik Pesawat",
        "先週、初めて飛行機に乗った。とても緊張したが、客室乗務員が"
        "優しく案内してくれて、安心した。窓から見える景色がとても"
        "美しくて、感動した。また乗りたいと思う。",
        "Minggu lalu, saya naik pesawat untuk pertama kalinya. Sangat "
        "gugup, tapi pramugari memandu dengan ramah, jadi saya jadi "
        "tenang. Pemandangan yang terlihat dari jendela sangat indah, "
        "saya terkesan. Saya ingin naik lagi.",
        [
            ("いつ初めて飛行機に乗りましたか。", ["先週", "今週", "去年", "昨日"], 0),
            ("誰が優しく案内してくれましたか。", ["客室乗務員", "運転手", "先生", "家族"], 0),
            ("窓から見える景色はどうでしたか。", ["とても美しかった", "何も見えなかった", "怖かった", "つまらなかった"], 0),
        ],
    ),
    (
        "shokubutsu_sewa",
        "Panduan Merawat Tanaman",
        "観葉植物を育てる時は、水のやりすぎに気をつけてください。土が"
        "乾いてから水をあげるのが基本です。日光が強すぎる場所も、植物に"
        "とってよくありません。",
        "Saat merawat tanaman hias, tolong berhati-hati jangan terlalu "
        "banyak menyiram air. Dasarnya adalah memberi air setelah "
        "tanahnya kering. Tempat dengan sinar matahari yang terlalu kuat "
        "juga tidak baik untuk tanaman.",
        [
            ("何に気をつけますか。", ["水のやりすぎ", "肥料のやりすぎ", "場所", "温度"], 0),
            ("いつ水をあげますか。", ["土が乾いてから", "毎日", "一週間に一回", "土が濡れている時"], 0),
            ("どんな場所がよくありませんか。", ["日光が強すぎる場所", "暗い場所", "暖かい場所", "涼しい場所"], 0),
        ],
    ),
    (
        "suimin_shuukan",
        "Artikel tentang Kebiasaan Tidur yang Baik",
        "よく眠るためには、寝る前にスマートフォンを見ないほうがいいと"
        "言われている。画面の光が脳を刺激し、眠りにくくなるからだ。寝る"
        "前は、静かな音楽を聞くのがおすすめだ。",
        "Untuk tidur nyenyak, dikatakan lebih baik tidak melihat "
        "smartphone sebelum tidur. Karena cahaya layar merangsang otak "
        "dan membuat sulit tidur. Sebelum tidur, disarankan mendengarkan "
        "musik yang tenang.",
        [
            ("よく眠るために何をしないほうがいいですか。", ["寝る前にスマートフォンを見ること", "運動すること", "音楽を聞くこと", "本を読むこと"], 0),
            ("どうしてスマートフォンがよくないですか。", ["画面の光が脳を刺激するから", "高いから", "重いから", "音がするから"], 0),
            ("寝る前に何がおすすめですか。", ["静かな音楽を聞くこと", "運動すること", "テレビを見ること", "食事をすること"], 0),
        ],
    ),
    (
        "shoushin_oiwai",
        "Email Ucapan Selamat Promosi",
        "昇進おめでとうございます。日頃の努力が認められて、本当に"
        "よかったですね。新しい役職でも、これまでのように頑張って"
        "ください。今度、お祝いにご飯を食べに行きましょう。",
        "Selamat atas promosinya. Bagus sekali usaha sehari-hari "
        "diakui. Di posisi baru pun, tolong tetap semangat seperti "
        "sebelumnya. Lain kali, ayo makan bersama untuk merayakan.",
        [
            ("この手紙は何についてですか。", ["昇進のお祝い", "転職のお祝い", "誕生日のお祝い", "結婚のお祝い"], 0),
            ("何が認められましたか。", ["日頃の努力", "お金", "運", "見た目"], 0),
            ("今度、何をしようと誘っていますか。", ["お祝いにご飯を食べに行くこと", "旅行に行くこと", "映画を見ること", "買い物すること"], 0),
        ],
    ),
    (
        "gaadeningu_burogu",
        "Blog tentang Mencoba Hobi Berkebun",
        "最近、ベランダで野菜を育て始めた。トマトとバジルを植えている。"
        "毎日水をあげるのが楽しみになった。収穫できたら、自分で作った"
        "野菜を料理に使いたいと思っている。",
        "Belakangan ini, saya mulai menanam sayuran di balkon. Saya "
        "menanam tomat dan kemangi. Menyiram air setiap hari jadi "
        "kesenangan tersendiri. Kalau bisa panen, saya ingin menggunakan "
        "sayuran buatan sendiri untuk masakan.",
        [
            ("どこで野菜を育て始めましたか。", ["ベランダ", "庭", "畑", "屋上"], 0),
            ("何を植えていますか。", ["トマトとバジル", "きゅうりとにんじん", "いちごとりんご", "米と麦"], 0),
            ("収穫できたら何をしたいですか。", ["料理に使いたい", "売りたい", "誰かにあげたい", "写真を撮りたい"], 0),
        ],
    ),
    (
        "erebeetaa_shuuri",
        "Pengumuman Perbaikan Lift",
        "来週の月曜日から水曜日まで、エレベーターの点検を行います。その"
        "間、エレベーターは使えません。階段をご利用ください。ご不便を"
        "おかけしますが、よろしくお願いいたします。",
        "Mulai Senin depan sampai Rabu, akan dilakukan pemeriksaan "
        "lift. Selama itu, lift tidak bisa digunakan. Silakan gunakan "
        "tangga. Mohon maaf atas ketidaknyamanannya.",
        [
            ("いつエレベーターの点検を行いますか。", ["来週の月曜日から水曜日", "今週末", "明日だけ", "来月"], 0),
            ("その間、何を使いますか。", ["階段", "別のエレベーター", "エスカレーター", "何も使わない"], 0),
            ("この文章の目的は何ですか。", ["点検のお知らせ", "苦情", "質問", "招待"], 0),
        ],
    ),
    (
        "ayamari_tegami",
        "Surat Permintaan Maaf ke Teman",
        "昨日は、約束の時間に遅れてしまって、本当にごめんなさい。急な"
        "用事があって、連絡もできませんでした。今度会う時は、必ず時間を"
        "守ります。許してもらえますか。",
        "Kemarin, saya benar-benar minta maaf karena terlambat dari "
        "waktu yang dijanjikan. Ada urusan mendadak, sampai tidak bisa "
        "menghubungi juga. Saat bertemu lagi nanti, saya pasti akan "
        "tepat waktu. Bisakah kamu memaafkan?",
        [
            ("どうして遅れましたか。", ["急な用事があったから", "寝坊したから", "道が混んでいたから", "忘れていたから"], 0),
            ("どうして連絡できませんでしたか。", ["急な用事があったから", "携帯電話がなかったから", "忙しかったから", "分からない"], 0),
            ("今度会う時、何を約束していますか。", ["必ず時間を守ること", "プレゼントをあげること", "早く来ること", "電話すること"], 0),
        ],
    ),
    (
        "atarashii_kankouchi",
        "Ulasan Tempat Wisata Baru",
        "先月オープンした新しい観光スポットに行ってきた。景色がとても"
        "美しく、写真をたくさん撮った。ただ、人気があるので、週末は"
        "とても混雑すると聞いた。平日に行くのがおすすめだ。",
        "Saya pergi ke tempat wisata baru yang dibuka bulan lalu. "
        "Pemandangannya sangat indah, saya memotret banyak foto. Hanya "
        "saja, karena populer, saya dengar akhir pekan sangat ramai. "
        "Disarankan pergi di hari kerja.",
        [
            ("この観光スポットはいつオープンしましたか。", ["先月", "今月", "去年", "今週"], 0),
            ("この人は何をたくさんしましたか。", ["写真を撮ること", "買い物", "食事", "睡眠"], 0),
            ("いつ行くのがおすすめですか。", ["平日", "週末", "祝日", "夜"], 0),
        ],
    ),
    (
        "setsuyaku_houhou",
        "Artikel tentang Cara Menghemat Uang",
        "毎日のコーヒーを家で作ることで、月に約五千円節約できるという"
        "計算がある。小さな出費を見直すだけでも、一年間で大きな金額に"
        "なることがある。無理のない範囲で始めてみるといいだろう。",
        "Ada perhitungan bahwa dengan membuat kopi sendiri di rumah "
        "setiap hari, bisa menghemat sekitar 5000 yen per bulan. Hanya "
        "dengan meninjau ulang pengeluaran kecil pun, dalam setahun bisa "
        "menjadi jumlah yang besar. Sebaiknya coba mulai dalam batas "
        "yang tidak memaksakan diri.",
        [
            ("家でコーヒーを作ると、月にどのくらい節約できますか。", ["約五千円", "約一万円", "約千円", "約三千円"], 0),
            ("小さな出費を見直すと、一年間でどうなりますか。", ["大きな金額になる", "何も変わらない", "逆に増える", "分からない"], 0),
            ("どんな範囲で始めるといいですか。", ["無理のない範囲", "できるだけ多く", "すぐに全部", "難しい範囲"], 0),
        ],
    ),
    (
        "tonari_tetsudai",
        "Cerita Membantu Tetangga",
        "隣に住むおばあさんが、重い荷物を持っているのを見かけて、"
        "手伝った。とても喜んでくれて、お礼にお菓子をもらった。小さな"
        "ことでも、誰かの役に立てるのはうれしい。",
        "Saya melihat nenek yang tinggal di sebelah membawa barang "
        "berat, lalu saya bantu. Beliau sangat senang, dan sebagai balas "
        "budi saya diberi camilan. Meskipun hal kecil, senang bisa "
        "berguna bagi orang lain.",
        [
            ("誰を手伝いましたか。", ["隣に住むおばあさん", "母", "友達", "先生"], 0),
            ("何を持っているのを見かけましたか。", ["重い荷物", "傘", "本", "買い物袋だけ軽いもの"], 0),
            ("お礼に何をもらいましたか。", ["お菓子", "お金", "花", "手紙"], 0),
        ],
    ),
    (
        "sentakuki_kyoudou",
        "Panduan Menggunakan Mesin Cuci Umum",
        "共同の洗濯機を使う時は、時間を守ってください。一回の使用は"
        "一時間までです。使い終わったら、すぐに洗濯物を取り出してくだ"
        "さい。他の人が待っていることがあります。",
        "Saat menggunakan mesin cuci bersama, tolong patuhi waktunya. "
        "Satu kali pemakaian maksimal satu jam. Setelah selesai "
        "digunakan, segera keluarkan cuciannya. Kadang ada orang lain "
        "yang menunggu.",
        [
            ("一回の使用は何時間までですか。", ["一時間", "二時間", "三十分", "三時間"], 0),
            ("使い終わったら何をしますか。", ["すぐに洗濯物を取り出す", "そのままにする", "掃除する", "電源を切らない"], 0),
            ("どうしてすぐに取り出しますか。", ["他の人が待っていることがあるから", "洗濯物が汚れるから", "機械が壊れるから", "ルールだから"], 0),
        ],
    ),
    (
        "kurabu_boshuu",
        "Pengumuman Perekrutan Anggota Klub",
        "写真部では、新しいメンバーを募集しています。カメラを持って"
        "いなくても大丈夫です。撮影が好きな人、興味がある人は、ぜひ"
        "見学に来てください。毎週木曜日に活動しています。",
        "Klub fotografi sedang merekrut anggota baru. Meskipun tidak "
        "punya kamera juga tidak apa-apa. Yang suka memotret, yang "
        "tertarik, silakan datang untuk melihat-lihat. Kegiatan setiap "
        "hari Kamis.",
        [
            ("何部が新しいメンバーを募集していますか。", ["写真部", "美術部", "音楽部", "演劇部"], 0),
            ("カメラを持っていないと参加できませんか。", ["いいえ、大丈夫です", "はい、必要です", "分からない", "借りなければならない"], 0),
            ("活動は何曜日ですか。", ["毎週木曜日", "毎週月曜日", "週末だけ", "毎日"], 0),
        ],
    ),
    (
        "onrain_kouza_hyouka",
        "Ulasan Kursus Online",
        "オンラインの英語コースを二か月受けました。自分のペースで勉強"
        "できるのがよかったです。先生の説明も分かりやすかったです。"
        "ただ、時々インターネットの接続が悪くなるのが困りました。",
        "Saya mengikuti kursus bahasa Inggris online selama dua bulan. "
        "Yang bagus adalah bisa belajar dengan kecepatan sendiri. "
        "Penjelasan gurunya juga mudah dipahami. Hanya saja, kadang "
        "koneksi internet yang buruk membuat repot.",
        [
            ("何のコースを受けましたか。", ["オンラインの英語コース", "対面の英語コース", "日本語コース", "料理コース"], 0),
            ("このコースのいいところは何ですか。", ["自分のペースで勉強できること", "無料なこと", "短いこと", "簡単すぎること"], 0),
            ("何が困りましたか。", ["インターネットの接続が悪くなること", "先生が厳しいこと", "高いこと", "難しすぎること"], 0),
        ],
    ),
    (
        "asagohan_kouka",
        "Artikel tentang Manfaat Sarapan",
        "朝ご飯をしっかり食べると、午前中の集中力が上がると言われて"
        "いる。忙しくて時間がない人も、バナナやヨーグルトなど、簡単な"
        "ものだけでも食べたほうがいい。",
        "Dikatakan jika sarapan dengan baik, konsentrasi di pagi hari "
        "meningkat. Bahkan orang yang sibuk dan tidak punya waktu pun, "
        "sebaiknya makan hal sederhana seperti pisang atau yoghurt.",
        [
            ("朝ご飯をしっかり食べると何が上がりますか。", ["午前中の集中力", "体重", "お金", "疲労"], 0),
            ("忙しい人は何を食べたほうがいいですか。", ["バナナやヨーグルトなど簡単なもの", "何も食べない", "とても重い食事", "お菓子だけ"], 0),
            ("この文章のテーマは何ですか。", ["朝ご飯の大切さ", "昼ご飯の大切さ", "運動の大切さ", "睡眠の大切さ"], 0),
        ],
    ),
    (
        "gaikokugo_burogu",
        "Blog tentang Belajar Bahasa Asing",
        "去年から韓国語を勉強している。最初は文字を覚えるのが大変だった"
        "が、今は簡単な会話ができるようになった。ドラマを字幕なしで"
        "見られる日が来るのが楽しみだ。",
        "Sejak tahun lalu saya belajar bahasa Korea. Awalnya menghafal "
        "hurufnya berat, tapi sekarang sudah bisa melakukan percakapan "
        "sederhana. Saya menantikan hari bisa menonton drama tanpa "
        "subtitle.",
        [
            ("いつから韓国語を勉強していますか。", ["去年から", "今年から", "先月から", "子供の時から"], 0),
            ("最初、何が大変でしたか。", ["文字を覚えること", "発音", "文法", "単語"], 0),
            ("この人は何を楽しみにしていますか。", ["字幕なしでドラマを見られる日", "韓国に行く日", "試験に合格する日", "友達ができる日"], 0),
        ],
    ),
    (
        "chuumon_kakunin_meeru",
        "Email Konfirmasi Pesanan Online",
        "ご注文ありがとうございます。商品は三日以内に発送する予定です。"
        "配送状況は、メールでお知らせします。何か問題があれば、お気軽に"
        "お問い合わせください。",
        "Terima kasih atas pesanannya. Barang direncanakan dikirim "
        "dalam 3 hari. Status pengiriman akan diberitahukan lewat "
        "email. Jika ada masalah, silakan hubungi kami.",
        [
            ("商品はいつ発送する予定ですか。", ["三日以内", "今日中", "一週間後", "一か月後"], 0),
            ("配送状況はどう知らされますか。", ["メールで", "電話で", "手紙で", "SNSで"], 0),
            ("問題があればどうしますか。", ["気軽に問い合わせる", "何もしない", "返品する", "待つだけ"], 0),
        ],
    ),
    (
        "arubaito_taiken",
        "Pengalaman Bekerja Paruh Waktu",
        "大学生になってから、カフェでアルバイトを始めた。最初はお客さん"
        "とうまく話せず緊張したが、今では笑顔で接客できるようになった。"
        "社会経験として、とても勉強になっている。",
        "Sejak menjadi mahasiswa, saya mulai kerja paruh waktu di kafe. "
        "Awalnya gugup karena tidak bisa berbicara dengan baik dengan "
        "pelanggan, tapi sekarang sudah bisa melayani dengan senyum. "
        "Sebagai pengalaman sosial, ini menjadi pembelajaran yang "
        "berharga.",
        [
            ("どこでアルバイトを始めましたか。", ["カフェ", "レストラン", "コンビニ", "本屋"], 0),
            ("最初、どうでしたか。", ["緊張した", "楽しかっただけ", "簡単だった", "何も感じなかった"], 0),
            ("今はどうなりましたか。", ["笑顔で接客できるようになった", "まだ緊張している", "辞めたいと思っている", "何も変わらない"], 0),
        ],
    ),
    (
        "shokudou_menyu_henkou",
        "Pengumuman Perubahan Menu Kantin Kantor",
        "来月から、社員食堂のメニューが新しくなります。健康を考えて、"
        "野菜料理を増やします。ご意見やご要望があれば、総務部までお知らせ"
        "ください。",
        "Mulai bulan depan, menu kantin karyawan diperbarui. Dengan "
        "memperhatikan kesehatan, masakan sayuran ditambah. Jika ada "
        "pendapat atau permintaan, silakan beri tahu departemen umum.",
        [
            ("何が新しくなりますか。", ["社員食堂のメニュー", "食堂の場所", "食堂の時間", "食堂の値段"], 0),
            ("何を増やしますか。", ["野菜料理", "肉料理", "デザート", "揚げ物"], 0),
            ("意見があればどうしますか。", ["総務部に知らせる", "何もしない", "食堂の人に直接言う", "我慢する"], 0),
        ],
    ),
    (
        "kyuujin_toiawase",
        "Surat Permohonan Informasi Lowongan Kerja",
        "貴社のホームページで求人を拝見しました。営業職に興味があるの"
        "ですが、詳しい仕事内容を教えていただけますでしょうか。お忙しい"
        "ところ恐縮ですが、よろしくお願いいたします。",
        "Saya melihat lowongan kerja di situs web perusahaan Anda. "
        "Saya tertarik pada posisi sales, bisakah dijelaskan detail "
        "pekerjaannya? Meskipun sedang sibuk, mohon bantuannya.",
        [
            ("どこで求人を見ましたか。", ["ホームページ", "新聞", "雑誌", "友達から"], 0),
            ("何の職種に興味がありますか。", ["営業職", "事務職", "技術職", "販売職"], 0),
            ("何を教えてほしいと言っていますか。", ["詳しい仕事内容", "給料", "会社の場所", "社長の名前"], 0),
        ],
    ),
    (
        "gomi_risaikuru",
        "Panduan Daur Ulang Sampah",
        "ペットボトルは、ラベルとキャップを外してから捨ててください。"
        "燃えるゴミと燃えないゴミは、別の袋に入れてください。分別の"
        "ルールを守ることが、環境を守ることにつながります。",
        "Botol PET, tolong buang setelah melepas label dan tutupnya. "
        "Sampah yang bisa dibakar dan tidak bisa dibakar, tolong "
        "masukkan ke kantong yang berbeda. Mematuhi aturan pemilahan "
        "berkontribusi pada menjaga lingkungan.",
        [
            ("ペットボトルを捨てる前に何をしますか。", ["ラベルとキャップを外す", "洗う", "潰す", "切る"], 0),
            ("燃えるゴミと燃えないゴミはどうしますか。", ["別の袋に入れる", "同じ袋に入れる", "捨てない", "燃やす"], 0),
            ("分別のルールを守ると何につながりますか。", ["環境を守ること", "お金を節約すること", "時間を節約すること", "何も起きない"], 0),
        ],
    ),
    (
        "asa_undou_shuukan",
        "Artikel tentang Kebiasaan Berolahraga Pagi",
        "朝、軽い運動をすると、一日を元気に過ごせると言われている。"
        "ジョギングやストレッチなど、無理のない範囲で始めるのがいい"
        "だろう。習慣にするまで少し時間がかかるかもしれない。",
        "Dikatakan jika berolahraga ringan di pagi hari, bisa menjalani "
        "hari dengan semangat. Sebaiknya mulai dengan jogging atau "
        "peregangan, dalam batas yang tidak memaksakan diri. Mungkin "
        "butuh sedikit waktu sampai menjadi kebiasaan.",
        [
            ("朝、軽い運動をするとどうなると言われていますか。", ["一日を元気に過ごせる", "すぐに疲れる", "眠くなる", "何も変わらない"], 0),
            ("何から始めるのがいいですか。", ["ジョギングやストレッチ", "激しい運動", "長時間の運動", "何もしない"], 0),
            ("習慣にするまでどうですか。", ["少し時間がかかるかもしれない", "すぐにできる", "一日でできる", "不可能だ"], 0),
        ],
    ),
    (
        "heya_katazuke_burogu",
        "Blog tentang Merapikan Rumah",
        "週末、部屋の片付けをした。使わない物をたくさん処分したら、"
        "部屋がすっきりして、気持ちも軽くなった。物が少ないと、掃除も"
        "楽になることが分かった。",
        "Akhir pekan, saya merapikan kamar. Setelah membuang banyak "
        "barang yang tidak dipakai, kamar jadi rapi, dan perasaan juga "
        "menjadi ringan. Saya jadi tahu bahwa jika barang sedikit, "
        "membersihkan juga jadi mudah.",
        [
            ("いつ部屋の片付けをしましたか。", ["週末", "平日", "毎日", "今朝"], 0),
            ("何をたくさん処分しましたか。", ["使わない物", "大切な物", "新しい物", "高い物"], 0),
            ("物が少ないと何が楽になると分かりましたか。", ["掃除", "料理", "買い物", "仕事"], 0),
        ],
    ),
    (
        "reshipi_burogu",
        "Blog tentang Mencoba Resep Baru",
        "先週、新しいレシピに挑戦してみた。タイ料理のグリーンカレーだ。"
        "スパイスの調整が難しかったが、思ったより美味しくできた。次は"
        "別のタイ料理にも挑戦したい。",
        "Minggu lalu, saya coba resep baru. Kari hijau masakan "
        "Thailand. Pengaturan bumbunya sulit, tapi hasilnya lebih enak "
        "dari yang saya duga. Selanjutnya saya ingin mencoba masakan "
        "Thailand lainnya.",
        [
            ("何のレシピに挑戦しましたか。", ["タイ料理のグリーンカレー", "和食", "イタリア料理", "中華料理"], 0),
            ("何が難しかったですか。", ["スパイスの調整", "材料を買うこと", "時間", "火加減"], 0),
            ("この人はこれから何をしたいですか。", ["別のタイ料理に挑戦したい", "料理をやめたい", "同じ料理を作りたい", "分からない"], 0),
        ],
    ),
    (
        "jikan_kanri_hou",
        "Artikel tentang Cara Mengatur Waktu",
        "一日のスケジュールを紙に書き出すことで、時間を有効に使えるよう"
        "になると言われている。優先順位をつけて、重要なことから取り組む"
        "のがコツだ。小さな習慣が、大きな成果につながる。",
        "Dikatakan bahwa dengan menuliskan jadwal harian di kertas, "
        "kita bisa menggunakan waktu secara efektif. Triknya adalah "
        "membuat prioritas dan mengerjakan hal penting terlebih dahulu. "
        "Kebiasaan kecil mengarah pada hasil besar.",
        [
            ("何をすると時間を有効に使えるようになりますか。", ["スケジュールを紙に書き出すこと", "早起きすること", "携帯を見ないこと", "何もしないこと"], 0),
            ("コツは何ですか。", ["優先順位をつけること", "全部同時にすること", "何も考えないこと", "後回しにすること"], 0),
            ("小さな習慣は何につながりますか。", ["大きな成果", "小さな成果だけ", "疲れ", "何も変わらないこと"], 0),
        ],
    ),
    (
        "hikkoshi_tetsudai_orei",
        "Surat Ucapan Terima Kasih atas Bantuan Pindahan",
        "先日は、引っ越しを手伝ってくれて本当にありがとう。おかげで一日"
        "で全部終わりました。今度、お礼にご飯をごちそうします。またゆっ"
        "くり遊びに来てください。",
        "Beberapa hari lalu, terima kasih banyak sudah membantu "
        "pindahan. Berkatmu semuanya selesai dalam satu hari. Lain kali, "
        "aku akan traktir makan sebagai balas budi. Silakan main lagi "
        "santai.",
        [
            ("何を手伝ってもらいましたか。", ["引っ越し", "掃除", "料理", "買い物"], 0),
            ("おかげでどうなりましたか。", ["一日で全部終わった", "三日かかった", "終わらなかった", "大変だった"], 0),
            ("お礼に何をすると言っていますか。", ["ご飯をごちそうする", "プレゼントをあげる", "手紙を書く", "何もしない"], 0),
        ],
    ),
    (
        "kaigi_risendaa",
        "Email Pengingat Rapat",
        "明日の会議についてお知らせします。時間は午後二時から、場所は"
        "三階の会議室です。資料は事前にお読みいただき、ご意見をご準備"
        "ください。",
        "Ini pemberitahuan tentang rapat besok. Waktu mulai jam 2 "
        "siang, tempat di ruang rapat lantai 3. Mohon baca dokumen "
        "terlebih dahulu dan siapkan pendapat Anda.",
        [
            ("会議はいつですか。", ["明日の午後二時から", "今日の午前中", "来週", "今夜"], 0),
            ("会議はどこでありますか。", ["三階の会議室", "一階のロビー", "屋上", "二階の教室"], 0),
            ("何を準備しますか。", ["資料を読んで意見を準備する", "お金", "昼食", "プレゼン用のパソコンだけ"], 0),
        ],
    ),
    (
        "baiku_menkyo",
        "Cerita Belajar Mengendarai Sepeda Motor",
        "先月からバイクの免許を取るために、教習所に通っている。最初は"
        "バランスを取るのが難しかったが、練習を重ねるうちに慣れてきた。"
        "来月、試験を受ける予定だ。",
        "Sejak bulan lalu, saya pergi ke sekolah mengemudi untuk "
        "mendapatkan SIM motor. Awalnya sulit menjaga keseimbangan, tapi "
        "seiring berlatih, saya mulai terbiasa. Bulan depan, saya "
        "berencana ikut ujian.",
        [
            ("いつから教習所に通っていますか。", ["先月から", "今月から", "去年から", "今週から"], 0),
            ("最初、何が難しかったですか。", ["バランスを取ること", "お金を払うこと", "場所を見つけること", "時間を作ること"], 0),
            ("いつ試験を受ける予定ですか。", ["来月", "今月", "来週", "今日"], 0),
        ],
    ),
    (
        "kaiin_kaado_koushin",
        "Pengumuman Perpanjangan Masa Berlaku Kartu Anggota",
        "会員カードの有効期限が近づいています。更新するには、店頭で"
        "手続きが必要です。更新すると、次の一年間、割引サービスをご利用"
        "いただけます。",
        "Masa berlaku kartu anggota Anda hampir habis. Untuk "
        "memperpanjang, perlu prosedur di toko. Setelah diperpanjang, "
        "Anda bisa menggunakan layanan diskon untuk satu tahun "
        "berikutnya.",
        [
            ("何が近づいていますか。", ["会員カードの有効期限", "セールの終わり", "誕生日", "休みの日"], 0),
            ("更新するにはどうしますか。", ["店頭で手続きする", "電話する", "メールする", "何もしなくていい"], 0),
            ("更新すると何が利用できますか。", ["割引サービス", "無料の商品", "新しいカード", "ポイント二倍"], 0),
        ],
    ),
    (
        "kakeibo_apuri_hyouka",
        "Ulasan Aplikasi Pengatur Keuangan",
        "家計簿アプリを使い始めて三か月になる。レシートを撮影するだけで"
        "自動的に記録されるので、とても便利だ。自分がどこにお金を使い"
        "すぎているかが、はっきり分かるようになった。",
        "Sudah tiga bulan saya mulai menggunakan aplikasi pencatat "
        "keuangan. Karena hanya dengan memotret struk secara otomatis "
        "tercatat, sangat praktis. Saya jadi bisa dengan jelas "
        "mengetahui di mana saya terlalu banyak menghabiskan uang.",
        [
            ("どのくらいこのアプリを使っていますか。", ["三か月", "一か月", "半年", "一年"], 0),
            ("どうやって記録されますか。", ["レシートを撮影するだけで自動的に", "手で入力して", "銀行に行って", "何もしなくても"], 0),
            ("何がはっきり分かるようになりましたか。", ["お金を使いすぎている場所", "貯金額", "収入", "将来の計画"], 0),
        ],
    ),
    (
        "eigakan_burogu",
        "Blog tentang Menonton Film di Bioskop",
        "久しぶりに映画館で映画を見た。大きなスクリーンと迫力のある音響"
        "で、家で見るのとは全く違う体験だった。ポップコーンを食べながら"
        "見るのも、映画館ならではの楽しみだ。",
        "Setelah lama tidak menonton, saya menonton film di bioskop. "
        "Dengan layar besar dan suara yang berdaya, itu pengalaman yang "
        "sama sekali berbeda dari menonton di rumah. Makan popcorn "
        "sambil menonton juga kesenangan khas bioskop.",
        [
            ("どこで映画を見ましたか。", ["映画館", "家", "友達の家", "公園"], 0),
            ("家で見るのと何が違いましたか。", ["大きなスクリーンと迫力のある音響", "値段", "時間", "内容"], 0),
            ("何を食べながら見ましたか。", ["ポップコーン", "お寿司", "パン", "アイス"], 0),
        ],
    ),
    (
        "dokusho_kouka",
        "Artikel tentang Manfaat Membaca Buku",
        "読書は、知識を増やすだけでなく、想像力やストレス解消にも役立つ"
        "と言われている。一日十分でも本を読む時間を作ることで、日々の"
        "生活が豊かになるかもしれない。",
        "Dikatakan bahwa membaca buku bukan hanya menambah "
        "pengetahuan, tapi juga membantu imajinasi dan mengurangi "
        "stres. Dengan meluangkan waktu membaca buku bahkan sepuluh "
        "menit sehari, kehidupan sehari-hari mungkin bisa menjadi lebih "
        "kaya.",
        [
            ("読書は知識を増やす他に何に役立ちますか。", ["想像力やストレス解消", "お金を稼ぐこと", "体力", "人脈"], 0),
            ("一日どのくらい本を読むといいですか。", ["十分でも", "三時間", "一時間", "五分"], 0),
            ("読書の時間を作ると何になるかもしれませんか。", ["日々の生活が豊かになる", "忙しくなる", "疲れる", "つまらなくなる"], 0),
        ],
    ),
    (
        "kaisha_basu_henkou",
        "Pengumuman Penggantian Jadwal Bus Kantor",
        "来月から、通勤バスの時刻表が変わります。朝は今より十五分早く"
        "出発します。新しい時刻表は、来週社内メールで送りますので、"
        "ご確認ください。",
        "Mulai bulan depan, jadwal bus komuter berubah. Pagi berangkat "
        "15 menit lebih awal dari sekarang. Jadwal baru akan dikirim "
        "lewat email internal minggu depan, mohon dicek.",
        [
            ("何が変わりますか。", ["通勤バスの時刻表", "会社の場所", "給料", "休みの日"], 0),
            ("朝はどうなりますか。", ["今より十五分早く出発する", "今より十五分遅く出発する", "変わらない", "なくなる"], 0),
            ("新しい時刻表はどうやって知らされますか。", ["社内メール", "電話", "掲示板", "直接会って"], 0),
        ],
    ),
    (
        "shashin_shumi_burogu",
        "Blog tentang Belajar Fotografi",
        "最近、写真の趣味を始めました。スマートフォンでも、きれいな"
        "写真が撮れることに驚きました。先輩に写真の撮り方を教えて"
        "もらって、少しずつ上手になっています。もっと練習すれば、"
        "きっといい写真が撮れるようになると思います。",
        "Belakangan ini, saya mulai hobi fotografi. Saya terkejut "
        "bahwa dengan smartphone pun bisa mengambil foto yang bagus. "
        "Saya diajari cara memotret oleh senior, dan sedikit demi "
        "sedikit menjadi lebih mahir. Saya pikir jika lebih banyak "
        "berlatih, pasti bisa mengambil foto yang bagus.",
        [
            ("筆者は最近何を始めましたか。", ["写真の趣味", "料理の趣味", "音楽の趣味", "スポーツの趣味"], 0),
            ("何に驚きましたか。", ["スマートフォンでもきれいな写真が撮れること", "カメラが高いこと", "写真が難しいこと", "誰も写真を撮らないこと"], 0),
            ("誰に写真の撮り方を教えてもらいましたか。", ["先輩", "先生", "家族", "友達"], 0),
        ],
    ),
    (
        "neru_mae_dokusho_shuukan",
        "Artikel tentang Kebiasaan Membaca sebelum Tidur",
        "寝る前にスマートフォンを見る代わりに、本を読む人が増えている"
        "そうだ。画面の光は目や脳を刺激するため、眠りにくくなると"
        "言われている。一方、紙の本を読めば、リラックスして眠りに"
        "つきやすくなるという。",
        "Dikatakan bahwa semakin banyak orang yang membaca buku "
        "sebagai pengganti melihat smartphone sebelum tidur. Katanya "
        "cahaya layar merangsang mata dan otak, sehingga menjadi susah "
        "tidur. Di sisi lain, jika membaca buku kertas, bisa lebih "
        "rileks dan mudah tertidur.",
        [
            ("寝る前に何をする人が増えていますか。", ["本を読む", "運動をする", "食べる", "テレビを見る"], 0),
            ("画面の光は何をしにくくすると言われていますか。", ["眠る", "勉強する", "食べる", "話す"], 0),
            ("紙の本を読むとどうなりますか。", ["リラックスして眠りにつきやすくなる", "もっと目が疲れる", "眠れなくなる", "何も変わらない"], 0),
        ],
    ),
    (
        "shokuba_suisen_irai_mail",
        "Email Permintaan Rekomendasi Kerja",
        "田中様。お世話になっております。突然のお願いで申し訳ござい"
        "ませんが、転職のため、推薦状を書いていただけないでしょうか。"
        "もしお引き受けいただければ、必要な書類をお送りいたします。"
        "よろしくお願いいたします。",
        "Kepada Bapak/Ibu Tanaka. Terima kasih atas bantuannya selama "
        "ini. Mohon maaf atas permintaan yang mendadak ini, tetapi "
        "untuk pindah kerja, bolehkah saya minta ditulis surat "
        "rekomendasi? Jika berkenan, saya akan mengirimkan dokumen "
        "yang diperlukan. Mohon bantuannya.",
        [
            ("何のためにお願いしていますか。", ["転職のため", "結婚のため", "留学のため", "入学のため"], 0),
            ("何を書いてほしいとお願いしていますか。", ["推薦状", "履歴書", "契約書", "報告書"], 0),
            ("引き受けてもらったら、次に何をしますか。", ["必要な書類を送る", "お金を払う", "電話をする", "会いに行く"], 0),
        ],
    ),
    (
        "shinsetsu_cafe_report",
        "Ulasan Kafe Baru di Kota",
        "先週、駅前に新しくできたカフェに行ってみた。店内は明るく、"
        "窓が大きいので日差しが気持ちいい。コーヒーの香りも良く、"
        "店員さんも親切だった。値段は少し高いが、また行きたいと思う。",
        "Minggu lalu, saya mencoba pergi ke kafe yang baru dibuka di "
        "depan stasiun. Bagian dalam toko terang, dan karena "
        "jendelanya besar, sinar mataharinya nyaman. Aroma kopinya "
        "juga bagus, dan pelayannya juga ramah. Harganya sedikit "
        "mahal, tapi saya ingin pergi lagi.",
        [
            ("いつカフェに行きましたか。", ["先週", "昨日", "今朝", "来週"], 0),
            ("店内はどんな様子でしたか。", ["明るく日差しが気持ちいい", "暗くて狭い", "うるさい", "汚い"], 0),
            ("値段についてどう思っていますか。", ["少し高い", "とても安い", "ちょうどいい", "分からない"], 0),
        ],
    ),
    (
        "setsuden_katsuyou_guide",
        "Panduan Menghemat Listrik di Rumah",
        "夏の電気代を減らすために、いくつかの方法がある。エアコンの"
        "温度を一度上げるだけでも、電気代はかなり変わる。使わない"
        "部屋の電気を消すことも忘れないようにしよう。小さな工夫が"
        "大きな節約になる。",
        "Untuk mengurangi biaya listrik musim panas, ada beberapa "
        "cara. Hanya dengan menaikkan suhu AC satu derajat saja, "
        "biaya listrik bisa banyak berubah. Jangan lupa juga untuk "
        "mematikan lampu di ruangan yang tidak digunakan. Usaha kecil "
        "bisa menjadi penghematan besar.",
        [
            ("何を減らすための方法が紹介されていますか。", ["夏の電気代", "水道代", "食費", "交通費"], 0),
            ("エアコンの温度をどうすると電気代が変わりますか。", ["一度上げる", "一度下げる", "消す", "変えない"], 0),
            ("何を忘れないようにと言っていますか。", ["使わない部屋の電気を消すこと", "エアコンをつけっぱなしにすること", "窓を開けること", "水を使うこと"], 0),
        ],
    ),
    (
        "doukyuukai_shoutai_tegami",
        "Surat Undangan Reuni Sekolah",
        "皆様お元気でしょうか。卒業してから十年になりますね。久しぶり"
        "に同級生で集まりませんか。日時は来月の第二土曜日、場所は"
        "当時よく行った駅前のレストランを予定しています。参加できる"
        "方は、返信をお願いします。",
        "Apa kabar kalian semua? Sudah sepuluh tahun sejak lulus ya. "
        "Bagaimana kalau kita berkumpul lagi sebagai teman seangkatan "
        "setelah lama tidak bertemu? Tanggal dan waktunya direncanakan "
        "hari Sabtu kedua bulan depan, tempatnya restoran depan "
        "stasiun yang dulu sering kita datangi. Yang bisa hadir, mohon "
        "membalas.",
        [
            ("卒業してから何年になりますか。", ["十年", "五年", "二十年", "三年"], 0),
            ("場所はどこを予定していますか。", ["当時よく行った駅前のレストラン", "新しいホテル", "学校", "公園"], 0),
            ("参加できる人は何をお願いされていますか。", ["返信", "電話", "訪問", "支払い"], 0),
        ],
    ),
    (
        "aruku_koto_kouka_kiji",
        "Artikel tentang Manfaat Berjalan Kaki",
        "毎日少し歩くだけで、健康に良い影響があるという研究結果が"
        "出ている。特別な運動をしなくても、通勤や買い物のときに歩く"
        "距離を増やすだけで十分効果があるそうだ。忙しい人でも、始め"
        "やすい健康法と言えるだろう。",
        "Ada hasil penelitian yang menunjukkan bahwa hanya dengan "
        "berjalan sedikit setiap hari, ada dampak baik bagi kesehatan. "
        "Katanya meski tanpa olahraga khusus, cukup dengan menambah "
        "jarak berjalan saat berangkat kerja atau belanja saja sudah "
        "cukup efektif. Bisa dikatakan ini metode kesehatan yang mudah "
        "dimulai bahkan oleh orang sibuk.",
        [
            ("何をするだけで健康に良い影響がありますか。", ["毎日少し歩くこと", "特別な運動をすること", "食事を減らすこと", "早く寝ること"], 0),
            ("通勤や買い物のときに何をすればいいですか。", ["歩く距離を増やす", "車を使う", "急いで歩く", "歩かない"], 0),
            ("この健康法はどんな人に向いていますか。", ["忙しい人", "運動が得意な人だけ", "若い人だけ", "お金持ちの人だけ"], 0),
        ],
    ),
    (
        "apaato_hikkoshi_taiken",
        "Pengalaman Pindah ke Apartemen Baru",
        "先月、新しいアパートに引っ越した。前の部屋より少し狭いが、"
        "駅から近くて便利だ。近所の人にも会ったら挨拶するようにして"
        "いる。新しい生活に少しずつ慣れてきた気がする。",
        "Bulan lalu, saya pindah ke apartemen baru. Lebih sempit "
        "sedikit dari kamar sebelumnya, tapi dekat dari stasiun dan "
        "praktis. Saya juga membiasakan diri menyapa jika bertemu "
        "tetangga. Rasanya saya sedikit demi sedikit mulai terbiasa "
        "dengan kehidupan baru.",
        [
            ("新しい部屋は前の部屋と比べてどうですか。", ["少し狭いが駅から近い", "広くて駅から遠い", "同じ広さ", "もっと高い"], 0),
            ("近所の人に会ったら何をしますか。", ["挨拶する", "何もしない", "話しかけない", "逃げる"], 0),
            ("筆者は今の生活についてどう感じていますか。", ["少しずつ慣れてきた", "全く慣れない", "すぐに嫌になった", "前の方がよかった"], 0),
        ],
    ),
    (
        "nihon_ryouri_manabu_burogu",
        "Blog tentang Belajar Memasak Masakan Jepang",
        "日本料理に興味があって、最近、味噌汁の作り方を習い始めた。"
        "最初は出汁の取り方が難しかったが、動画を見ながら何度も練習"
        "した。今では家族に「おいしい」と言ってもらえるようになった。",
        "Karena tertarik dengan masakan Jepang, belakangan ini saya "
        "mulai belajar cara membuat sup miso. Awalnya cara membuat "
        "dashi itu sulit, tapi saya berlatih berkali-kali sambil "
        "menonton video. Sekarang saya sudah bisa dibilang \"enak\" "
        "oleh keluarga.",
        [
            ("最近、何を習い始めましたか。", ["味噌汁の作り方", "寿司の作り方", "天ぷらの作り方", "ラーメンの作り方"], 0),
            ("最初は何が難しかったですか。", ["出汁の取り方", "味噌を選ぶこと", "野菜を切ること", "火を使うこと"], 0),
            ("今、家族に何と言われますか。", ["おいしい", "まずい", "もう作らないで", "もっと簡単に"], 0),
        ],
    ),
    (
        "shiei_basu_route_henkou",
        "Pengumuman Perubahan Rute Bus Kota",
        "来月一日から、道路工事のため、市営バスの一部の路線が変更に"
        "なります。駅前から病院へ行くバスは、別の道を通ることになり"
        "ます。詳しい時刻表は、市役所のホームページで確認してくださ"
        "い。",
        "Mulai tanggal satu bulan depan, karena perbaikan jalan, "
        "sebagian rute bus kota akan berubah. Bus dari depan stasiun "
        "ke rumah sakit akan melewati jalan lain. Untuk jadwal detail, "
        "silakan cek di halaman web balai kota.",
        [
            ("なぜバスの路線が変更になりますか。", ["道路工事のため", "事故のため", "雪のため", "予算がないため"], 0),
            ("どのバスが別の道を通りますか。", ["駅前から病院へ行くバス", "駅前から学校へ行くバス", "空港行きのバス", "全てのバス"], 0),
            ("詳しい時刻表はどこで確認できますか。", ["市役所のホームページ", "駅の窓口", "バスの中", "新聞"], 0),
        ],
    ),
]

N3_ENTRIES = [
    (
        "shinbun_kiji_kankyou",
        "Artikel Koran tentang Lingkungan",
        "近年、プラスチックごみの問題が深刻になっている。海の生き物が"
        "プラスチックを食べてしまうことも多く、大きな問題として取り"
        "上げられている。これを解決するために、多くの国でプラスチック"
        "製品の使用を減らす取り組みが進められている。",
        "Belakangan ini, masalah sampah plastik menjadi semakin serius. "
        "Banyak makhluk laut yang sampai memakan plastik, sehingga hal "
        "ini diangkat sebagai masalah besar. Untuk menyelesaikan hal ini, "
        "banyak negara yang sedang menjalankan upaya mengurangi "
        "penggunaan produk plastik.",
        [
            ("何が深刻な問題になっていますか。", ["プラスチックごみ", "大気汚染", "水不足", "森林伐採"], 0),
            ("海の生き物はプラスチックをどうしてしまいますか。", ["食べてしまう", "運んでしまう", "集めてしまう", "壊してしまう"], 0),
            ("多くの国は何をしていますか。", ["プラスチック製品の使用を減らす取り組み", "海をきれいにする祭り", "プラスチックを作る工場を増やすこと", "何もしていない"], 0),
        ],
    ),
    (
        "shokuba_memo",
        "Memo Tempat Kerja tentang Perubahan Sistem",
        "来月から、社内のシステムが新しくなることになりました。それに"
        "伴い、パスワードも変更しなければなりません。分からないことが"
        "あれば、情報システム部に問い合わせてください。研修も予定されて"
        "いるので、必ず参加してください。",
        "Mulai bulan depan, sistem internal perusahaan akan diperbarui. "
        "Seiring dengan itu, kata sandi juga harus diubah. Jika ada yang "
        "tidak dimengerti, silakan tanyakan ke departemen sistem "
        "informasi. Pelatihan juga direncanakan, jadi pastikan untuk ikut "
        "serta.",
        [
            ("来月から何が変わりますか。", ["社内のシステム", "会社の場所", "給料の日", "休みの日"], 0),
            ("何をしなければなりませんか。", ["パスワードを変更する", "荷物をまとめる", "制服を買う", "早く出勤する"], 0),
            ("分からないことがあれば、どこに聞きますか。", ["情報システム部", "人事部", "営業部", "経理部"], 0),
        ],
    ),
    (
        "bunka_hikaku",
        "Esai Perbandingan Budaya",
        "日本とインドネシアでは、お辞儀とあいさつの仕方が違う。日本人は"
        "お辞儀をすることが多いが、インドネシア人は握手をすることが"
        "多い。どちらも相手を尊重する気持ちを表しているという点では"
        "同じである。文化の違いを知ることは、お互いを理解する上でとても"
        "大切だと思う。",
        "Di Jepang dan Indonesia, cara membungkuk dan menyapa itu "
        "berbeda. Orang Jepang sering membungkuk, sedangkan orang "
        "Indonesia sering berjabat tangan. Namun keduanya sama dalam hal "
        "mengekspresikan rasa hormat kepada lawan bicara. Saya pikir "
        "mengetahui perbedaan budaya itu sangat penting dalam memahami "
        "satu sama lain.",
        [
            ("日本人は何をすることが多いですか。", ["お辞儀", "握手", "ハグ", "キス"], 0),
            ("インドネシア人は何をすることが多いですか。", ["握手", "お辞儀", "会釈", "何もしない"], 0),
            ("この文章によると、両方に共通していることは何ですか。", ["相手を尊重する気持ちを表すこと", "同じ言葉を使うこと", "同じ服を着ること", "同じ食べ物を食べること"], 0),
        ],
    ),
    (
        "setsumeisho_bunshou",
        "Petunjuk Penggunaan Alat",
        "この機械を使う前に、必ず取扱説明書をお読みください。電源を入れる"
        "際は、コンセントがしっかり差し込まれていることを確認してくだ"
        "さい。異常な音がした場合は、すぐに電源を切り、修理を依頼して"
        "ください。子供の手が届かない場所で保管してください。",
        "Sebelum menggunakan mesin ini, harap baca buku petunjuk terlebih "
        "dahulu. Saat menyalakan daya, pastikan colokan sudah tertancap "
        "dengan kuat. Jika terdengar suara aneh, segera matikan daya dan "
        "minta perbaikan. Simpan di tempat yang tidak terjangkau tangan "
        "anak-anak.",
        [
            ("機械を使う前に何をしなければなりませんか。", ["取扱説明書を読む", "お金を払う", "電話をかける", "掃除をする"], 0),
            ("異常な音がしたら、まず何をしますか。", ["電源を切る", "もっと使う", "音を大きくする", "無視する"], 0),
            ("どこに保管しますか。", ["子供の手が届かない場所", "台所", "玄関", "外"], 0),
        ],
    ),
    (
        "kankyou_ishiki",
        "Esai Kesadaran Lingkungan",
        "私は最近、マイバッグを持ち歩くようにしている。レジ袋をもらわない"
        "ことで、少しでもごみを減らせるからだ。一人一人の小さな行動が"
        "集まれば、大きな変化につながるはずだと信じている。これからも、"
        "できることから続けていきたい。",
        "Belakangan ini saya membiasakan diri membawa tas belanja "
        "sendiri. Karena dengan tidak menerima kantong plastik, saya bisa "
        "mengurangi sampah sedikit demi sedikit. Saya percaya jika "
        "tindakan kecil dari setiap orang terkumpul, itu akan mengarah "
        "pada perubahan besar. Ke depannya, saya ingin terus melanjutkan "
        "hal-hal yang bisa saya lakukan.",
        [
            ("この人は何を持ち歩くようにしていますか。", ["マイバッグ", "水筒", "傘", "本"], 0),
            ("どうしてマイバッグを持ち歩いていますか。", ["ごみを減らせるから", "安いから", "かわいいから", "軽いから"], 0),
            ("この人はどう信じていますか。", ["小さな行動が大きな変化につながる", "一人では何もできない", "政府だけが変えられる", "変化は起きない"], 0),
        ],
    ),
    (
        "iryou_kiji",
        "Artikel Kesehatan",
        "睡眠不足は、体だけでなく心にも悪い影響を与えることが分かって"
        "いる。十分な睡眠を取ることで、集中力が上がり、仕事の効率も"
        "良くなる。専門家は、毎日同じ時間に寝て、同じ時間に起きることを"
        "勧めている。",
        "Diketahui bahwa kurang tidur memberikan dampak buruk bukan "
        "hanya pada tubuh, tapi juga pada pikiran. Dengan tidur yang "
        "cukup, konsentrasi meningkat dan efisiensi kerja juga menjadi "
        "lebih baik. Para ahli menganjurkan untuk tidur dan bangun di jam "
        "yang sama setiap hari.",
        [
            ("睡眠不足は何に悪い影響を与えますか。", ["体と心", "体だけ", "心だけ", "お金"], 0),
            ("十分な睡眠を取るとどうなりますか。", ["集中力が上がる", "太る", "疲れる", "眠くなる"], 0),
            ("専門家は何を勧めていますか。", ["毎日同じ時間に寝て起きること", "昼寝をすること", "寝る前に運動すること", "遅くまで起きていること"], 0),
        ],
    ),
    (
        "gijutsu_toreando",
        "Artikel Tren Teknologi",
        "人工知能の技術は、私たちの生活のさまざまな場面で使われるように"
        "なった。例えば、スマートフォンの音声アシスタントや、車の自動"
        "運転技術がその例である。便利になる一方で、仕事が減るのでは"
        "ないかという心配の声もある。",
        "Teknologi kecerdasan buatan sudah mulai digunakan dalam "
        "berbagai aspek kehidupan kita. Contohnya adalah asisten suara di "
        "smartphone dan teknologi mengemudi otomatis mobil. Di satu sisi "
        "menjadi lebih praktis, tapi juga ada suara kekhawatiran bahwa "
        "pekerjaan mungkin akan berkurang.",
        [
            ("人工知能の例として何が挙げられていますか。", ["音声アシスタントと自動運転技術", "テレビとラジオ", "本と新聞", "電話とファックス"], 0),
            ("人工知能が便利になる一方で、何が心配されていますか。", ["仕事が減ること", "値段が高いこと", "使い方が難しいこと", "音がうるさいこと"], 0),
            ("この文章のテーマは何ですか。", ["人工知能技術", "環境問題", "健康法", "旅行"], 0),
        ],
    ),
    (
        "rekishi_bunshou",
        "Teks Sejarah Singkat",
        "江戸時代、日本は長い間、外国との貿易を制限していた。この政策は"
        "「鎖国」と呼ばれている。しかし、完全に閉ざされていたわけでは"
        "なく、一部の国とは貿易を続けていた。この時代に、日本独自の文化"
        "が大きく発展したと言われている。",
        "Pada zaman Edo, Jepang membatasi perdagangan dengan luar negeri "
        "untuk waktu yang lama. Kebijakan ini disebut 'sakoku' (isolasi "
        "negara). Namun, bukan berarti benar-benar tertutup sepenuhnya, "
        "karena perdagangan dengan sebagian negara tetap dilanjutkan. "
        "Dikatakan bahwa pada masa ini, budaya khas Jepang berkembang "
        "pesat.",
        [
            ("江戸時代の政策は何と呼ばれていますか。", ["鎖国", "開国", "維新", "幕府"], 0),
            ("この政策の間、貿易は完全になくなりましたか。", ["いいえ、一部の国とは続けていた", "はい、完全になくなった", "分からない", "増えた"], 0),
            ("この時代に何が大きく発展しましたか。", ["日本独自の文化", "外国の技術", "貿易の量", "人口"], 0),
        ],
    ),
    (
        "shigoto_kaigi_memo",
        "Memo Rapat Kerja",
        "本日の会議で、次のプロジェクトについて話し合った。予算が限られて"
        "いるため、優先順位をつけることになった。まず、最も重要な部分"
        "から進めることが決まった。詳しいスケジュールは、来週までに"
        "各自で確認しておいてほしい。",
        "Dalam rapat hari ini, kami membahas proyek berikutnya. Karena "
        "anggaran terbatas, diputuskan untuk membuat prioritas. "
        "Diputuskan untuk memulai dari bagian yang paling penting "
        "terlebih dahulu. Jadwal detailnya diharapkan untuk dicek "
        "masing-masing sampai minggu depan.",
        [
            ("どうして優先順位をつけることになりましたか。", ["予算が限られているから", "時間がないから", "人が足りないから", "場所がないから"], 0),
            ("何から進めることが決まりましたか。", ["最も重要な部分", "一番簡単な部分", "一番安い部分", "ランダムな部分"], 0),
            ("何をいつまでに確認しますか。", ["詳しいスケジュールを来週まで", "予算を今日中に", "参加者リストを明日まで", "場所を今週末まで"], 0),
        ],
    ),
    (
        "kokusai_koryuu",
        "Cerita Pertukaran Budaya Internasional",
        "大学で留学生と交流するイベントに参加した。さまざまな国から来た"
        "学生と話すことで、自分の知らなかった文化や考え方に触れることが"
        "できた。言葉が完全に通じなくても、笑顔で話せば気持ちは伝わると"
        "いうことを実感した。",
        "Saya mengikuti acara pertukaran budaya dengan mahasiswa "
        "internasional di kampus. Dengan berbicara dengan mahasiswa dari "
        "berbagai negara, saya bisa menyentuh budaya dan cara berpikir "
        "yang belum saya ketahui sebelumnya. Saya merasakan bahwa "
        "meskipun bahasanya tidak sepenuhnya nyambung, jika berbicara "
        "dengan senyuman, perasaan bisa tersampaikan.",
        [
            ("この人はどんなイベントに参加しましたか。", ["留学生と交流するイベント", "スポーツ大会", "就職説明会", "料理教室"], 0),
            ("このイベントで何に触れることができましたか。", ["知らなかった文化や考え方", "新しい料理のレシピ", "新しい技術", "新しい音楽"], 0),
            ("この人は何を実感しましたか。", ["笑顔で話せば気持ちは伝わる", "言葉が完全に必要", "一人でいる方がいい", "留学は難しい"], 0),
        ],
    ),
    (
        "shokuseikatsu_kiji",
        "Artikel tentang Kebiasaan Makan Sehat",
        "健康的な食生活を送るためには、バランスの良い食事を心がけることが"
        "重要である。特に、野菜や果物を積極的に取り入れることで、体に"
        "必要な栄養を効率よく摂取することができる。また、食べる時間帯にも"
        "気をつけるべきだと言われている。",
        "Untuk menjalani pola makan yang sehat, penting untuk "
        "memperhatikan makanan yang seimbang. Terutama, dengan aktif "
        "mengonsumsi sayur dan buah, kita bisa mendapatkan nutrisi yang "
        "dibutuhkan tubuh secara efisien. Selain itu, dikatakan juga "
        "perlu memperhatikan waktu makan.",
        [
            ("健康的な食生活のために何が重要ですか。", ["バランスの良い食事", "高い食べ物", "少ない食事", "一種類だけの食事"], 0),
            ("何を積極的に取り入れるといいですか。", ["野菜や果物", "お菓子", "肉だけ", "揚げ物"], 0),
            ("他に何に気をつけるべきですか。", ["食べる時間帯", "食べる場所", "食器の色", "一緒に食べる人"], 0),
        ],
    ),
    (
        "kisetsu_henka_essei",
        "Esai tentang Perubahan Musim",
        "季節が変わるたびに、自然の色や匂いが少しずつ変化していくことに"
        "気づく。特に、春から夏へ移り変わる時期は、新しい命の力強さを"
        "感じさせてくれる。忙しい日々の中でも、こうした季節の変化に目を"
        "向ける余裕を持ちたいと思う。",
        "Setiap kali musim berganti, saya menyadari warna dan aroma alam "
        "berubah sedikit demi sedikit. Terutama, masa peralihan dari "
        "musim semi ke musim panas membuat saya merasakan kekuatan "
        "kehidupan baru. Bahkan di tengah hari-hari yang sibuk, saya "
        "ingin memiliki kelonggaran untuk memperhatikan perubahan musim "
        "seperti ini.",
        [
            ("季節が変わるたびに何に気づきますか。", ["自然の色や匂いの変化", "人の性格", "お金の価値", "時間の速さ"], 0),
            ("どの時期が特に力強さを感じさせますか。", ["春から夏へ移り変わる時期", "夏から秋", "秋から冬", "冬から春"], 0),
            ("筆者は何を持ちたいと思っていますか。", ["季節の変化に目を向ける余裕", "もっとお金", "もっと友達", "もっと休み"], 0),
        ],
    ),
    (
        "bijinesu_manaa",
        "Panduan Etika Bisnis di Jepang",
        "日本のビジネスの場では、名刺の交換の仕方にもマナーがある。名刺は"
        "両手で渡し、相手の名刺も両手で受け取るのが一般的である。また、"
        "受け取った名刺をすぐにしまうのではなく、しばらく机の上に置いて"
        "おくことも礼儀とされている。",
        "Dalam dunia bisnis Jepang, ada etika dalam cara bertukar kartu "
        "nama. Umumnya, kartu nama diberikan dengan dua tangan, dan "
        "kartu nama lawan bicara juga diterima dengan dua tangan. Selain "
        "itu, tidak langsung menyimpan kartu nama yang diterima, "
        "melainkan meletakkannya di atas meja untuk sementara waktu juga "
        "dianggap sebagai sopan santun.",
        [
            ("名刺はどうやって渡しますか。", ["両手で", "片手で", "投げて", "口で"], 0),
            ("受け取った名刺はすぐにどうしますか。", ["しばらく机の上に置く", "すぐにしまう", "捨てる", "相手に返す"], 0),
            ("この文章のテーマは何ですか。", ["名刺交換のマナー", "服装のマナー", "食事のマナー", "電話のマナー"], 0),
        ],
    ),
    (
        "toshi_hatten",
        "Artikel tentang Perkembangan Kota",
        "この十年間で、この町は大きく変わった。以前は田んぼが広がって"
        "いた場所に、今では高いビルが立ち並んでいる。便利になった一方"
        "で、昔ながらの静かな風景が失われたことを寂しく思う人も少なく"
        "ない。",
        "Dalam sepuluh tahun terakhir, kota ini berubah besar-besaran. "
        "Tempat yang dulunya membentang sawah, kini berjejer gedung-"
        "gedung tinggi. Meskipun jadi lebih praktis, tidak sedikit orang "
        "yang merasa sedih karena pemandangan tenang seperti dulu "
        "hilang.",
        [
            ("この十年間で町はどう変わりましたか。", ["大きく変わった", "何も変わらなかった", "小さくなった", "人が減った"], 0),
            ("以前、その場所には何が広がっていましたか。", ["田んぼ", "海", "山", "森"], 0),
            ("便利になった一方で、何を寂しく思う人がいますか。", ["静かな風景が失われたこと", "物価が上がったこと", "人が増えたこと", "店が減ったこと"], 0),
        ],
    ),
    (
        "borantia_taiken",
        "Pengalaman Kegiatan Sukarelawan",
        "先週、地域の清掃ボランティアに参加した。初めは面倒だと思って"
        "いたが、実際にやってみると、地域の人々と交流する良い機会に"
        "なった。小さな活動でも、続けることで町がきれいになっていくのを"
        "実感し、やりがいを感じた。",
        "Minggu lalu saya mengikuti kegiatan sukarelawan membersihkan "
        "lingkungan. Awalnya saya pikir merepotkan, tapi setelah benar-"
        "benar mencobanya, itu menjadi kesempatan baik untuk berinteraksi "
        "dengan warga sekitar. Meskipun kegiatan kecil, saya merasakan "
        "kepuasan karena menyadari kota menjadi bersih dengan "
        "melanjutkannya.",
        [
            ("先週、何に参加しましたか。", ["地域の清掃ボランティア", "スポーツ大会", "料理教室", "音楽会"], 0),
            ("初め、この人はどう思っていましたか。", ["面倒だと思っていた", "とても楽しみだった", "興味がなかった", "怖かった"], 0),
            ("実際にやってみて、何を実感しましたか。", ["町がきれいになっていくこと", "お金がもらえること", "有名になること", "疲れるだけ"], 0),
        ],
    ),
    (
        "media_hikaku",
        "Perbandingan Media Tradisional dan Digital",
        "新聞やテレビといった従来のメディアに加えて、インターネットを"
        "通じた情報発信が急速に広まっている。若い世代を中心に、ニュース"
        "をスマートフォンで読む人が増えている一方、高齢者の間では、"
        "依然として新聞やテレビが主な情報源となっている。",
        "Selain media konvensional seperti koran dan televisi, "
        "penyebaran informasi melalui internet berkembang pesat. Di "
        "kalangan generasi muda, orang yang membaca berita lewat "
        "smartphone semakin bertambah, sementara di kalangan lansia, "
        "koran dan televisi tetap menjadi sumber informasi utama.",
        [
            ("何が急速に広まっていますか。", ["インターネットを通じた情報発信", "新聞の読者", "テレビの視聴時間", "手紙の数"], 0),
            ("若い世代はどうやってニュースを読むことが多いですか。", ["スマートフォン", "新聞", "ラジオ", "雑誌"], 0),
            ("高齢者の主な情報源は何ですか。", ["新聞やテレビ", "インターネット", "スマートフォン", "SNS"], 0),
        ],
    ),
    (
        "yuujou_essei",
        "Esai tentang Persahabatan",
        "長い間連絡を取っていなかった友人から、久しぶりに電話がかかって"
        "きた。時間が経っていても、話し始めるとすぐに昔と同じような"
        "雰囲気に戻れることに驚いた。本当の友情とは、時間や距離に関係"
        "なく続くものなのかもしれないと感じた。",
        "Teman yang sudah lama tidak dihubungi tiba-tiba menelepon "
        "setelah sekian lama. Meskipun waktu telah berlalu, saya kaget "
        "karena begitu mulai berbicara, langsung bisa kembali ke suasana "
        "yang sama seperti dulu. Saya merasa bahwa persahabatan sejati "
        "mungkin adalah sesuatu yang berlanjut tanpa peduli waktu atau "
        "jarak.",
        [
            ("誰から電話がかかってきましたか。", ["長い間連絡を取っていなかった友人", "家族", "会社の同僚", "知らない人"], 0),
            ("話し始めて、この人はどう感じましたか。", ["すぐに昔と同じ雰囲気に戻れた", "全然話が合わなかった", "気まずかった", "何も感じなかった"], 0),
            ("筆者は本当の友情について、どう感じましたか。", ["時間や距離に関係なく続くもの", "すぐに終わるもの", "お金が必要なもの", "難しいもの"], 0),
        ],
    ),
    (
        "kinkyuu_taiou",
        "Panduan Prosedur Darurat",
        "地震が起きた時は、まず自分の身の安全を確保することが最優先で"
        "ある。丈夫な机の下に隠れるなどして、落下物から身を守って"
        "ほしい。揺れが収まったら、火の元を確認し、慌てずに避難場所へ"
        "移動すること。",
        "Saat gempa bumi terjadi, prioritas utama adalah memastikan "
        "keselamatan diri sendiri terlebih dahulu. Tolong lindungi diri "
        "dari benda jatuh, misalnya dengan bersembunyi di bawah meja "
        "yang kokoh. Setelah guncangan mereda, periksa sumber api dan "
        "pindah ke tempat evakuasi tanpa panik.",
        [
            ("地震が起きた時、まず何を確保しますか。", ["自分の身の安全", "お金", "食べ物", "携帯電話"], 0),
            ("落下物から身を守るために何をしますか。", ["丈夫な机の下に隠れる", "外に走って出る", "窓を開ける", "大声を出す"], 0),
            ("揺れが収まったら何を確認しますか。", ["火の元", "テレビ", "電話", "冷蔵庫"], 0),
        ],
    ),
    (
        "kankou_toreando",
        "Artikel tentang Tren Pariwisata",
        "近年、有名な観光地だけでなく、地元の人しか知らないような場所を"
        "訪れる旅行者が増えている。SNSの普及により、こうした「隠れた"
        "名所」の情報が簡単に共有されるようになったことが背景にある"
        "ようだ。",
        "Belakangan ini, bukan hanya tempat wisata terkenal, semakin "
        "banyak wisatawan yang mengunjungi tempat yang hanya diketahui "
        "warga lokal. Latar belakangnya tampaknya karena dengan "
        "menyebarnya media sosial, informasi tentang 'tempat "
        "tersembunyi' seperti ini menjadi mudah dibagikan.",
        [
            ("最近、旅行者はどんな場所を訪れることが増えていますか。", ["地元の人しか知らない場所", "有名な観光地だけ", "外国だけ", "テーマパークだけ"], 0),
            ("この背景には何がありますか。", ["SNSの普及", "テレビ番組", "政府の宣伝", "交通機関の発達"], 0),
            ("このような場所は何と呼ばれていますか。", ["隠れた名所", "有名スポット", "定番の観光地", "危険な場所"], 0),
        ],
    ),
    (
        "shippai_kokufuku",
        "Cerita tentang Mengatasi Kegagalan",
        "大きなプロジェクトで失敗した時、しばらく立ち直れないほど落ち"
        "込んだ。しかし、上司が「失敗は次への準備だ」と声をかけてくれた"
        "ことで、少しずつ前向きになれた。あの経験があったからこそ、今の"
        "自分があると思っている。",
        "Saat gagal dalam proyek besar, saya terpuruk sampai hampir "
        "tidak bisa bangkit untuk sementara waktu. Namun, karena atasan "
        "menyapa saya dengan berkata 'kegagalan adalah persiapan untuk "
        "selanjutnya,' saya bisa berpikir positif sedikit demi sedikit. "
        "Saya berpikir justru karena pengalaman itulah, ada diri saya "
        "yang sekarang.",
        [
            ("何が起きた時、落ち込みましたか。", ["大きなプロジェクトで失敗した時", "病気になった時", "遅刻した時", "お金をなくした時"], 0),
            ("誰が声をかけてくれましたか。", ["上司", "家族", "友達", "先生"], 0),
            ("上司は何と言いましたか。", ["失敗は次への準備だ", "失敗は絶対ダメだ", "もう諦めろ", "気にしなくていい"], 0),
        ],
    ),
    (
        "shokuhin_haiki",
        "Artikel tentang Sampah Makanan",
        "日本では、まだ食べられる食品が大量に捨てられているという問題が"
        "ある。この「食品ロス」を減らすために、賞味期限が近い商品を安く"
        "売る店が増えている。一人一人の意識が、この問題の解決につながる"
        "だろう。",
        "Di Jepang, ada masalah di mana bahan makanan yang masih bisa "
        "dimakan dibuang dalam jumlah besar. Untuk mengurangi 'food "
        "loss' ini, semakin banyak toko yang menjual murah barang yang "
        "mendekati tanggal kedaluwarsa. Kesadaran setiap individu akan "
        "mengarah pada penyelesaian masalah ini.",
        [
            ("日本にはどんな問題がありますか。", ["食べられる食品が捨てられること", "食品が足りないこと", "食品が高いこと", "食品が少ないこと"], 0),
            ("何を減らすために店が努力していますか。", ["食品ロス", "値段", "種類", "量"], 0),
            ("何がこの問題の解決につながりますか。", ["一人一人の意識", "政府だけの対策", "店の努力だけ", "何もしないこと"], 0),
        ],
    ),
    (
        "dokusho_shuukan_essei",
        "Esai tentang Kebiasaan Membaca",
        "子供の頃、寝る前に必ず本を読む習慣があった。その習慣は大人に"
        "なった今も続いている。忙しい毎日の中で、本を読む時間は、心を"
        "落ち着かせる大切なひとときになっている。",
        "Sejak kecil, saya memiliki kebiasaan selalu membaca buku "
        "sebelum tidur. Kebiasaan itu berlanjut hingga sekarang setelah "
        "dewasa. Di tengah hari-hari yang sibuk, waktu membaca buku "
        "menjadi momen penting untuk menenangkan hati.",
        [
            ("子供の頃、いつ本を読む習慣がありましたか。", ["寝る前", "朝起きてすぐ", "学校で", "食事の後"], 0),
            ("その習慣は今もどうですか。", ["続いている", "なくなった", "減った", "忘れた"], 0),
            ("本を読む時間は筆者にとって何ですか。", ["心を落ち着かせる大切なひととき", "無駄な時間", "仕事の時間", "つまらない時間"], 0),
        ],
    ),
    (
        "koukyou_koutsuu_manaa",
        "Panduan Etika di Transportasi Umum",
        "電車やバスの中では、大きな声で話すことは控えるべきである。また、"
        "優先席の近くでは、携帯電話の電源を切ることが求められている。"
        "周りの人への配慮が、快適な公共交通機関の利用につながる。",
        "Di dalam kereta atau bus, sebaiknya menghindari berbicara "
        "dengan suara keras. Selain itu, di dekat kursi prioritas, "
        "dituntut untuk mematikan ponsel. Kepedulian terhadap orang di "
        "sekitar akan mengarah pada penggunaan transportasi umum yang "
        "nyaman.",
        [
            ("電車やバスの中で何を控えるべきですか。", ["大きな声で話すこと", "座ること", "立つこと", "本を読むこと"], 0),
            ("優先席の近くで何が求められていますか。", ["携帯電話の電源を切ること", "席を譲ること", "静かに座ること", "荷物を置くこと"], 0),
            ("何が快適な利用につながりますか。", ["周りの人への配慮", "早く乗ること", "大きな荷物", "大きな声"], 0),
        ],
    ),
    (
        "hataraki_kata_henka",
        "Artikel tentang Perubahan Pola Kerja",
        "テレワークの普及により、働く場所や時間に対する考え方が大きく"
        "変わってきた。オフィスに通勤する必要がなくなったことで、地方に"
        "住みながら都市部の会社で働く人も増えている。",
        "Dengan menyebarnya kerja jarak jauh, pandangan terhadap tempat "
        "dan waktu bekerja berubah besar. Dengan tidak perlunya lagi "
        "pergi ke kantor, semakin banyak juga orang yang bekerja di "
        "perusahaan kota besar sambil tinggal di daerah.",
        [
            ("何の普及により考え方が変わりましたか。", ["テレワーク", "車", "インターネット速度", "給料"], 0),
            ("オフィスに通勤する必要がなくなって、何が増えましたか。", ["地方に住みながら都市部の会社で働く人", "失業者", "学生", "旅行者"], 0),
            ("この文章のテーマは何ですか。", ["働き方の変化", "給料の変化", "教育の変化", "交通の変化"], 0),
        ],
    ),
    (
        "kazoku_dentou",
        "Esai tentang Menjaga Tradisi Keluarga",
        "毎年お正月には、祖母が作るおせち料理を家族全員で食べるのが我が"
        "家の伝統である。忙しさを理由に簡略化する家庭も増えているという"
        "が、この伝統だけは大切に続けていきたいと思っている。",
        "Setiap tahun baru, tradisi keluarga kami adalah makan masakan "
        "osechi buatan nenek bersama seluruh keluarga. Dikatakan semakin "
        "banyak keluarga yang menyederhanakannya dengan alasan "
        "kesibukan, tapi saya ingin terus menjaga tradisi ini dengan "
        "baik.",
        [
            ("我が家の伝統は何ですか。", ["おせち料理を家族全員で食べること", "旅行に行くこと", "プレゼントを交換すること", "神社に行くこと"], 0),
            ("誰がおせち料理を作りますか。", ["祖母", "母", "父", "筆者自身"], 0),
            ("筆者はこの伝統をどうしたいと思っていますか。", ["大切に続けていきたい", "やめたい", "簡略化したい", "忘れたい"], 0),
        ],
    ),
    (
        "intaanshippu_taiken",
        "Cerita Pengalaman Magang",
        "大学三年生の時、二週間の企業インターンシップに参加した。実際の"
        "仕事を体験することで、教科書だけでは分からない多くのことを"
        "学んだ。将来の仕事を考える上で、貴重な経験になった。",
        "Saat semester tiga kuliah, saya mengikuti magang perusahaan "
        "selama dua minggu. Dengan mengalami pekerjaan sesungguhnya, "
        "saya belajar banyak hal yang tidak bisa dipahami hanya dari "
        "buku teks. Ini menjadi pengalaman berharga dalam memikirkan "
        "pekerjaan masa depan.",
        [
            ("いつインターンシップに参加しましたか。", ["大学三年生の時", "高校生の時", "大学一年生の時", "卒業後"], 0),
            ("インターンシップはどのくらいの期間でしたか。", ["二週間", "一週間", "一か月", "三日間"], 0),
            ("この経験は筆者にとって何になりましたか。", ["貴重な経験", "無駄な時間", "つまらない経験", "大変なだけの経験"], 0),
        ],
    ),
    (
        "sns_wakamono",
        "Artikel tentang Media Sosial dan Remaja",
        "十代の若者の多くがSNSを日常的に利用している。友人とのつながりを"
        "保つ手段として便利である一方、他人と自分を比べて落ち込んで"
        "しまうという声も少なくない。使い方について、家庭での話し合いが"
        "必要だとされている。",
        "Banyak remaja usia belasan tahun menggunakan media sosial "
        "sehari-hari. Di satu sisi praktis sebagai sarana menjaga "
        "hubungan dengan teman, tidak sedikit juga suara yang mengatakan "
        "menjadi murung karena membandingkan diri dengan orang lain. "
        "Dikatakan perlu ada diskusi di rumah tentang cara "
        "penggunaannya.",
        [
            ("十代の若者はSNSをどう利用していますか。", ["日常的に利用している", "ほとんど利用しない", "禁止されている", "週に一回だけ"], 0),
            ("SNSの便利な点は何ですか。", ["友人とのつながりを保つ手段", "お金を稼ぐ手段", "勉強の手段", "運動の手段"], 0),
            ("何が必要だとされていますか。", ["家庭での話し合い", "もっと多くのSNS", "学校での禁止", "政府の規制"], 0),
        ],
    ),
    (
        "kasai_hinan",
        "Petunjuk Prosedur Evakuasi Kebakaran",
        "火事が発生したら、まず大声で周りに知らせてください。エレベー"
        "ターは使わず、階段を使って避難してください。煙が多い場合は、"
        "姿勢を低くして進むことが大切です。",
        "Jika kebakaran terjadi, pertama-tama beritahu sekitar dengan "
        "suara keras. Jangan gunakan lift, evakuasi menggunakan tangga. "
        "Jika banyak asap, penting untuk merunduk rendah saat bergerak.",
        [
            ("火事が発生したら、まず何をしますか。", ["大声で周りに知らせる", "逃げる", "消火器を使う", "電話する"], 0),
            ("避難する時、何を使ってはいけませんか。", ["エレベーター", "階段", "ドア", "窓"], 0),
            ("煙が多い場合、どうしますか。", ["姿勢を低くして進む", "立って走る", "止まる", "大声を出す"], 0),
        ],
    ),
    (
        "shumi_taisetsu",
        "Esai tentang Pentingnya Hobi",
        "仕事だけの生活を送っていると、いつの間にか心が疲れてしまうこと"
        "がある。仕事とは関係のない趣味を持つことで、気分転換ができ、"
        "結果的に仕事にもいい影響を与えるのではないかと思う。",
        "Jika menjalani kehidupan yang hanya berisi pekerjaan, tanpa "
        "disadari hati bisa menjadi lelah. Saya berpikir dengan memiliki "
        "hobi yang tidak berhubungan dengan pekerjaan, bisa menyegarkan "
        "pikiran, dan akhirnya memberikan pengaruh baik juga pada "
        "pekerjaan.",
        [
            ("仕事だけの生活を送っていると、何が起こることがありますか。", ["心が疲れてしまうこと", "お金が増えること", "健康になること", "友達が増えること"], 0),
            ("趣味を持つと何ができますか。", ["気分転換", "お金を稼ぐこと", "仕事を辞めること", "有名になること"], 0),
            ("趣味は結果的に何にいい影響を与えますか。", ["仕事", "健康だけ", "家族だけ", "何も影響しない"], 0),
        ],
    ),
    (
        "onrain_shoppingu",
        "Artikel tentang Perkembangan Belanja Online",
        "インターネットショッピングの普及により、店に行かなくても欲しい"
        "商品が手に入るようになった。便利になった反面、実際に商品を見て"
        "選べないため、届いてからイメージと違うと感じることもあるようだ。",
        "Dengan menyebarnya belanja internet, kita bisa mendapatkan "
        "barang yang diinginkan tanpa perlu pergi ke toko. Di sisi lain "
        "menjadi praktis, tapi karena tidak bisa melihat dan memilih "
        "barang secara langsung, tampaknya ada juga yang merasa berbeda "
        "dari bayangan setelah barang tiba.",
        [
            ("インターネットショッピングの普及で何が可能になりましたか。", ["店に行かなくても商品が手に入ること", "商品が安くなること", "すぐに届くこと", "返品が簡単なこと"], 0),
            ("便利になった反面、何が起こることがありますか。", ["イメージと違うと感じること", "商品がなくなること", "店が減ること", "値段が上がること"], 0),
            ("この文章のテーマは何ですか。", ["インターネットショッピング", "実店舗の魅力", "配達サービス", "商品の品質"], 0),
        ],
    ),
    (
        "kodomo_oshieru_taiken",
        "Cerita Pengalaman Mengajar Anak",
        "地域の子供たちに勉強を教えるボランティアを始めた。最初はうまく"
        "教えられず、悩むことも多かった。しかし、子供が「分かった」と"
        "笑顔を見せてくれた時、この活動を続けてよかったと心から思った。",
        "Saya mulai kegiatan sukarelawan mengajar pelajaran kepada "
        "anak-anak di lingkungan sekitar. Awalnya tidak bisa mengajar "
        "dengan baik, sering khawatir juga. Namun, saat anak menunjukkan "
        "senyum sambil berkata 'saya mengerti', saya benar-benar "
        "berpikir bagus telah melanjutkan kegiatan ini.",
        [
            ("何のボランティアを始めましたか。", ["子供に勉強を教えること", "清掃活動", "献血", "動物の世話"], 0),
            ("最初、この人はどうでしたか。", ["うまく教えられず悩むことが多かった", "すぐに上手にできた", "楽しかっただけ", "何も感じなかった"], 0),
            ("何が心からよかったと思わせましたか。", ["子供の「分かった」という笑顔", "お金がもらえたこと", "有名になったこと", "楽だったこと"], 0),
        ],
    ),
    (
        "henka_taiou",
        "Esai tentang Menghadapi Perubahan",
        "人生には、予期せぬ変化がつきものである。変化を恐れて何もしない"
        "より、それを受け入れて前向きに対応する姿勢のほうが、結果的に"
        "良い方向に進むことが多いように思う。",
        "Perubahan yang tidak terduga adalah hal yang tak terpisahkan "
        "dari kehidupan. Dibandingkan takut akan perubahan dan tidak "
        "melakukan apa-apa, saya rasa sikap menerimanya dan merespons "
        "secara positif lebih sering membawa ke arah yang baik pada "
        "akhirnya.",
        [
            ("人生にはどんなことがつきものですか。", ["予期せぬ変化", "安定した生活", "お金の問題", "健康の問題"], 0),
            ("変化を恐れて何もしないのと、受け入れるのと、どちらがいいと述べていますか。", ["受け入れること", "何もしないこと", "どちらも同じ", "分からない"], 0),
            ("前向きに対応すると、どうなることが多いですか。", ["結果的に良い方向に進む", "何も変わらない", "悪い方向に進む", "疲れるだけ"], 0),
        ],
    ),
    (
        "mizu_hozen",
        "Artikel tentang Konservasi Air",
        "世界的に水不足が深刻化する地域が増えている。日本は水資源に"
        "恵まれているといわれるが、それでも一人一人が節水を意識する"
        "ことは大切である。歯磨きの時に水を出しっぱなしにしないなど、"
        "小さな心がけが重要だ。",
        "Secara global, semakin banyak wilayah yang mengalami "
        "kekurangan air yang serius. Jepang dikatakan diberkahi sumber "
        "daya air, tetapi tetap penting bagi setiap individu untuk sadar "
        "menghemat air. Hal kecil seperti tidak membiarkan air mengalir "
        "terus saat menyikat gigi itu penting.",
        [
            ("世界的にどんな地域が増えていますか。", ["水不足が深刻化する地域", "水が豊富な地域", "人口が減る地域", "開発が進む地域"], 0),
            ("日本の水資源についてどう言われていますか。", ["恵まれている", "不足している", "汚染されている", "分からない"], 0),
            ("何が重要だと述べられていますか。", ["小さな心がけ", "大きな政策だけ", "節水しないこと", "何もしないこと"], 0),
        ],
    ),
    (
        "bijinesu_meeru",
        "Panduan Menulis Email Bisnis",
        "ビジネスメールを書く時は、まず用件を簡潔に伝えることが大切で"
        "ある。件名は内容が一目で分かるようにし、本文は丁寧な言葉遣いを"
        "心がける。長すぎるメールは、相手の負担になることもある。",
        "Saat menulis email bisnis, penting untuk pertama-tama "
        "menyampaikan urusan secara ringkas. Subjek dibuat agar isinya "
        "bisa dipahami sekali lihat, isi email diusahakan menggunakan "
        "kata-kata yang sopan. Email yang terlalu panjang bisa menjadi "
        "beban bagi lawan bicara.",
        [
            ("ビジネスメールで何が大切ですか。", ["用件を簡潔に伝えること", "長く書くこと", "面白く書くこと", "早く送ること"], 0),
            ("件名はどうしますか。", ["内容が一目で分かるようにする", "短くしない", "空欄にする", "面白くする"], 0),
            ("長すぎるメールはどうなることがありますか。", ["相手の負担になる", "読みやすくなる", "早く返事が来る", "何も変わらない"], 0),
        ],
    ),
    (
        "passhon_hakken",
        "Esai tentang Menemukan Passion",
        "何年も自分が本当にやりたいことが分からず、悩んでいた。しかし、"
        "様々な経験を積む中で、少しずつ自分の興味の方向性が見えてきた。"
        "焦らず色々なことに挑戦することが、本当の情熱を見つける近道な"
        "のかもしれない。",
        "Selama bertahun-tahun saya bingung, tidak tahu apa yang "
        "benar-benar ingin saya lakukan. Namun, di tengah mengumpulkan "
        "berbagai pengalaman, arah minat saya sedikit demi sedikit mulai "
        "terlihat. Mencoba berbagai hal tanpa terburu-buru mungkin "
        "adalah jalan pintas untuk menemukan passion sejati.",
        [
            ("何年も何が分からず悩んでいましたか。", ["自分が本当にやりたいこと", "お金の使い方", "住む場所", "友達の作り方"], 0),
            ("どうやって興味の方向性が見えてきましたか。", ["様々な経験を積む中で", "一人で考えて", "本を読んで", "誰かに聞いて"], 0),
            ("本当の情熱を見つける近道は何かもしれませんか。", ["焦らず色々なことに挑戦すること", "すぐに一つに決めること", "何もしないこと", "他人の真似をすること"], 0),
        ],
    ),
    (
        "rimooto_waaku_toreando",
        "Artikel tentang Tren Kerja Remote",
        "リモートワークを導入する企業が増える中、社員同士のコミュニケー"
        "ション不足が新たな課題として浮上している。オンライン会議だけ"
        "では伝わりにくい情報もあり、対面での交流の重要性が改めて見直"
        "されている。",
        "Di tengah semakin banyaknya perusahaan yang menerapkan kerja "
        "jarak jauh, kekurangan komunikasi antar karyawan muncul sebagai "
        "tantangan baru. Ada juga informasi yang sulit tersampaikan "
        "hanya lewat rapat online, sehingga pentingnya interaksi tatap "
        "muka ditinjau kembali.",
        [
            ("リモートワークが増えると、何が新たな課題になっていますか。", ["社員同士のコミュニケーション不足", "給料の問題", "通勤時間", "オフィスの家賃"], 0),
            ("オンライン会議だけでは何が起こりますか。", ["伝わりにくい情報がある", "全て完璧に伝わる", "会議が短くなる", "参加者が減る"], 0),
            ("何の重要性が見直されていますか。", ["対面での交流", "オンライン会議", "リモートワーク", "メールでの連絡"], 0),
        ],
    ),
    (
        "tenkou_taiken",
        "Cerita Pengalaman Pindah Sekolah",
        "中学二年生の時、父の転勤で転校することになった。新しい学校に"
        "なじめるか、とても不安だった。しかし、クラスメートが温かく"
        "迎えてくれて、思っていたよりずっと早く友達ができた。",
        "Saat kelas dua SMP, saya harus pindah sekolah karena "
        "pemindahan kerja ayah. Saya sangat cemas apakah bisa "
        "beradaptasi dengan sekolah baru. Namun, teman sekelas menyambut "
        "dengan hangat, dan saya mendapat teman jauh lebih cepat dari "
        "yang saya pikirkan.",
        [
            ("どうして転校することになりましたか。", ["父の転勤", "引っ越したかったから", "いじめ", "病気"], 0),
            ("転校前、この人はどう感じていましたか。", ["とても不安だった", "とても楽しみだった", "何も感じなかった", "怒っていた"], 0),
            ("実際にはどうでしたか。", ["思っていたより早く友達ができた", "友達が全くできなかった", "とても大変だった", "学校が嫌いになった"], 0),
        ],
    ),
    (
        "jikan_taisetsu",
        "Esai tentang Menghargai Waktu",
        "若い頃は、時間は無限にあるものだと錯覚していた。しかし、大切な"
        "人を失う経験をしてから、限られた時間をいかに大切に使うかを常に"
        "意識するようになった。一日一日を丁寧に生きたいと思う。",
        "Saat masih muda, saya salah mengira bahwa waktu itu tak "
        "terbatas. Namun, setelah mengalami kehilangan orang yang "
        "berharga, saya menjadi selalu menyadari bagaimana menggunakan "
        "waktu yang terbatas dengan baik. Saya ingin menjalani setiap "
        "hari dengan cermat.",
        [
            ("若い頃、時間についてどう思っていましたか。", ["無限にあると錯覚していた", "限られていると分かっていた", "気にしなかった", "早すぎると思っていた"], 0),
            ("何がきっかけで時間の大切さに気づきましたか。", ["大切な人を失う経験", "病気", "旅行", "仕事の失敗"], 0),
            ("筆者は今、どう生きたいと思っていますか。", ["一日一日を丁寧に", "もっと急いで", "昔のように", "何も考えずに"], 0),
        ],
    ),
    (
        "koukyou_koutsuu_hatten",
        "Artikel tentang Perkembangan Transportasi Umum",
        "都市部を中心に、公共交通機関の利便性が年々向上している。新しい"
        "路線の開通や、乗り換えをスムーズにする工夫により、車を持たなく"
        "ても不便を感じにくい環境が整いつつある。",
        "Terutama di daerah perkotaan, kenyamanan transportasi umum "
        "meningkat setiap tahun. Dengan dibukanya jalur baru dan upaya "
        "untuk memperlancar perpindahan moda, lingkungan yang tidak "
        "membuat orang merasa tidak nyaman meskipun tidak punya mobil "
        "mulai terbentuk.",
        [
            ("公共交通機関の利便性はどうなっていますか。", ["年々向上している", "悪化している", "変わらない", "分からない"], 0),
            ("何によって乗り換えがスムーズになっていますか。", ["工夫", "値段の値下げ", "人口減少", "天気"], 0),
            ("車を持たなくてもどうなりつつありますか。", ["不便を感じにくい", "もっと不便になる", "生活できない", "関係ない"], 0),
        ],
    ),
    (
        "tanin_shippai_manabu",
        "Esai tentang Belajar dari Kegagalan Orang Lain",
        "自分の失敗から学ぶことはもちろん大切だが、他人の失敗談を聞く"
        "ことからも多くを学べると気づいた。先輩の失敗を知ることで、"
        "同じ間違いを避けられることがある。素直に耳を傾ける姿勢を"
        "持ちたい。",
        "Belajar dari kegagalan diri sendiri tentu penting, tapi saya "
        "menyadari bahwa kita juga bisa belajar banyak dari mendengarkan "
        "cerita kegagalan orang lain. Dengan mengetahui kegagalan "
        "senior, kita bisa menghindari kesalahan yang sama. Saya ingin "
        "memiliki sikap mendengarkan dengan rendah hati.",
        [
            ("何から学ぶことができると気づきましたか。", ["他人の失敗談", "自分の成功談", "テレビ番組", "学校の授業だけ"], 0),
            ("先輩の失敗を知ることで何ができますか。", ["同じ間違いを避けること", "もっと失敗すること", "何も変わらない", "先輩を批判すること"], 0),
            ("筆者はどんな姿勢を持ちたいと思っていますか。", ["素直に耳を傾ける姿勢", "誰の話も聞かない姿勢", "批判的な姿勢", "無関心な姿勢"], 0),
        ],
    ),
    (
        "shokuhin_anzen",
        "Artikel tentang Keamanan Pangan",
        "食品の安全性に対する消費者の関心が高まっている。生産者は、"
        "農薬の使用量を減らしたり、栽培過程を公開したりするなど、透明性"
        "を高める取り組みを進めている。信頼を得るためには、正直な情報"
        "公開が欠かせない。",
        "Perhatian konsumen terhadap keamanan pangan semakin "
        "meningkat. Produsen sedang menjalankan upaya untuk "
        "meningkatkan transparansi, seperti mengurangi penggunaan "
        "pestisida atau membuka proses budidaya. Untuk mendapatkan "
        "kepercayaan, keterbukaan informasi yang jujur itu tak "
        "terpisahkan.",
        [
            ("何に対する消費者の関心が高まっていますか。", ["食品の安全性", "食品の値段", "食品の量", "食品の見た目"], 0),
            ("生産者は何をしていますか。", ["透明性を高める取り組み", "値段を上げること", "生産量を減らすこと", "何もしないこと"], 0),
            ("信頼を得るために何が欠かせませんか。", ["正直な情報公開", "広告", "安い値段", "早い配達"], 0),
        ],
    ),
    (
        "sensei_kansha_essei",
        "Esai tentang Menghargai Guru",
        "学生時代、厳しく指導してくれた先生の存在を、社会人になった今、"
        "心から感謝している。当時は反発することもあったが、あの厳しさ"
        "は、私の将来を思ってのものだったのだと、今なら分かる。",
        "Guru yang membimbing dengan ketat saat masa sekolah, sekarang "
        "setelah menjadi pekerja, saya berterima kasih dari lubuk "
        "hati. Saat itu terkadang menolak, tetapi sekarang saya "
        "mengerti bahwa kekerasan itu adalah karena memikirkan masa "
        "depan saya.",
        [
            ("筆者は誰に心から感謝していますか。", ["厳しく指導してくれた先生", "両親", "友達", "上司"], 0),
            ("当時、筆者はどうでしたか。", ["反発することもあった", "いつも感謝していた", "何も感じなかった", "先生が嫌いだった"], 0),
            ("今、筆者は先生の厳しさをどう理解していますか。", ["将来を思ってのものだった", "意味がなかった", "間違っていた", "分からない"], 0),
        ],
    ),
    (
        "mensetsu_manaa",
        "Panduan Etika Wawancara Kerja",
        "面接では、第一印象がとても重要である。時間に余裕を持って到着"
        "し、明るい表情で挨拶することが大切だ。また、質問には正直に、"
        "かつ簡潔に答える姿勢が評価されやすい。",
        "Dalam wawancara kerja, kesan pertama sangat penting. Penting "
        "untuk tiba dengan waktu yang cukup dan menyapa dengan ekspresi "
        "cerah. Selain itu, sikap menjawab pertanyaan dengan jujur dan "
        "ringkas cenderung dinilai baik.",
        [
            ("面接で何が重要ですか。", ["第一印象", "服の値段", "髪型だけ", "声の大きさだけ"], 0),
            ("どうやって到着しますか。", ["時間に余裕を持って", "ぎりぎりに", "少し遅れて", "早すぎるくらい"], 0),
            ("質問にはどう答えるといいですか。", ["正直に簡潔に", "長く詳しく", "曖昧に", "質問を無視して"], 0),
        ],
    ),
    (
        "jizoku_kanou_shouhi",
        "Artikel tentang Tren Konsumsi Berkelanjutan",
        "環境への配慮から、長く使えるものを選ぶ消費者が増えている。"
        "安さだけを重視するのではなく、品質や修理のしやすさを基準に"
        "商品を選ぶ動きが、若い世代を中心に広がっている。",
        "Karena kepedulian terhadap lingkungan, semakin banyak "
        "konsumen yang memilih barang yang bisa dipakai lama. Gerakan "
        "memilih produk berdasarkan kualitas dan kemudahan perbaikan, "
        "bukan hanya mementingkan harga murah, sedang menyebar terutama "
        "di kalangan generasi muda.",
        [
            ("環境への配慮から、消費者は何を選ぶようになっていますか。", ["長く使えるもの", "一番安いもの", "一番新しいもの", "一番大きいもの"], 0),
            ("何を基準に商品を選ぶ動きが広がっていますか。", ["品質や修理のしやすさ", "値段の安さだけ", "ブランド名だけ", "デザインだけ"], 0),
            ("この動きは主にどの世代に広がっていますか。", ["若い世代", "高齢者", "子供", "全世代同じ"], 0),
        ],
    ),
    (
        "saigai_borantia_taiken",
        "Pengalaman Menjadi Relawan Bencana",
        "地震の被災地でボランティア活動に参加した。がれきの撤去や物資"
        "の配布を手伝った。現地の人々の悲しみに触れる一方、助け合う"
        "人々の強さにも心を打たれた。",
        "Saya berpartisipasi dalam kegiatan sukarelawan di daerah "
        "terdampak gempa. Saya membantu penyingkiran puing dan "
        "distribusi bantuan. Di satu sisi menyentuh kesedihan penduduk "
        "setempat, tapi juga tersentuh oleh kekuatan orang-orang yang "
        "saling membantu.",
        [
            ("どこでボランティア活動をしましたか。", ["地震の被災地", "病院", "学校", "会社"], 0),
            ("何を手伝いましたか。", ["がれきの撤去や物資の配布", "料理", "医療", "教育"], 0),
            ("筆者は何に心を打たれましたか。", ["助け合う人々の強さ", "お金の力", "政府の対応", "天気"], 0),
        ],
    ),
    (
        "kokoro_kenkou",
        "Esai tentang Menjaga Kesehatan Mental",
        "体の健康と同じように、心の健康も日頃から気にかけることが大切"
        "である。無理をせず、疲れたら休むこと、そして誰かに悩みを話す"
        "ことも、心の健康を保つ上で有効だと言われている。",
        "Sama seperti kesehatan tubuh, penting untuk sehari-hari "
        "memperhatikan kesehatan mental juga. Dikatakan bahwa tidak "
        "memaksakan diri, beristirahat saat lelah, dan menceritakan "
        "kekhawatiran pada seseorang juga efektif untuk menjaga "
        "kesehatan mental.",
        [
            ("体の健康と同じように何が大切ですか。", ["心の健康", "お金の管理", "仕事の効率", "人間関係"], 0),
            ("疲れたらどうしますか。", ["休む", "無理をする", "我慢する", "何もしない"], 0),
            ("心の健康を保つために何が有効ですか。", ["誰かに悩みを話すこと", "一人で抱え込むこと", "忘れること", "無視すること"], 0),
        ],
    ),
    (
        "media_yoron",
        "Artikel tentang Dampak Media terhadap Opini Publik",
        "テレビやインターネットの報道は、人々の意見形成に大きな影響を"
        "与える。同じ出来事でも、伝え方によって受け手の印象は大きく"
        "変わる。情報を鵜呑みにせず、多角的に判断する力が求められて"
        "いる。",
        "Pemberitaan televisi dan internet memberikan pengaruh besar "
        "pada pembentukan opini masyarakat. Bahkan untuk peristiwa yang "
        "sama, kesan penerima bisa sangat berubah tergantung cara "
        "penyampaiannya. Dituntut kemampuan untuk tidak menelan "
        "mentah-mentah informasi, dan menilai secara multi-sudut "
        "pandang.",
        [
            ("テレビやインターネットの報道は何に影響を与えますか。", ["人々の意見形成", "天気", "経済だけ", "スポーツの結果"], 0),
            ("同じ出来事でも何によって印象が変わりますか。", ["伝え方", "時間", "場所", "人数"], 0),
            ("何が求められていますか。", ["多角的に判断する力", "全てを信じる力", "何も考えない力", "情報を無視する力"], 0),
        ],
    ),
    (
        "mensetsu_taisaku",
        "Petunjuk Menghadapi Wawancara Kerja",
        "面接前には、その会社についてよく調べておくことが大切だ。自己"
        "紹介やよく聞かれる質問への答えを準備しておくと、当日落ち着いて"
        "話すことができる。緊張は誰にでもあるものなので、恐れる必要は"
        "ない。",
        "Sebelum wawancara, penting untuk meneliti perusahaan tersebut "
        "dengan baik. Jika mempersiapkan perkenalan diri dan jawaban "
        "untuk pertanyaan yang sering ditanyakan, di hari H bisa "
        "berbicara dengan tenang. Kegugupan adalah hal yang dimiliki "
        "setiap orang, jadi tidak perlu ditakuti.",
        [
            ("面接前に何をしておくことが大切ですか。", ["会社についてよく調べること", "新しい服を買うこと", "早く寝ること", "何もしないこと"], 0),
            ("何を準備しておくといいですか。", ["自己紹介やよく聞かれる質問への答え", "プレゼント", "履歴書の写真だけ", "交通費"], 0),
            ("緊張についてどう述べられていますか。", ["誰にでもあるもの", "悪いことだけ", "避けられるもの", "珍しいもの"], 0),
        ],
    ),
    (
        "shoujiki_kachi",
        "Esai tentang Nilai Kejujuran",
        "小さな嘘でも、積み重なると信頼を大きく損なうことになる。正直で"
        "いることは時に勇気がいるが、長い目で見れば、それが人間関係を"
        "築く上で最も確実な方法なのだと思う。",
        "Meskipun kebohongan kecil, jika terakumulasi bisa merusak "
        "kepercayaan secara besar. Menjadi jujur terkadang membutuhkan "
        "keberanian, tetapi dalam jangka panjang, saya pikir itu adalah "
        "cara paling pasti dalam membangun hubungan antarmanusia.",
        [
            ("小さな嘘でも積み重なるとどうなりますか。", ["信頼を大きく損なう", "何も起こらない", "関係が良くなる", "忘れられる"], 0),
            ("正直でいることには何が必要な時がありますか。", ["勇気", "お金", "時間だけ", "才能"], 0),
            ("長い目で見ると、正直さは何において確実な方法ですか。", ["人間関係を築くこと", "お金を稼ぐこと", "有名になること", "成功すること"], 0),
        ],
    ),
    (
        "furiiransu_toreando",
        "Artikel tentang Tren Kerja Freelance",
        "会社に所属せず、フリーランスとして働く人が増えている。自由な"
        "働き方ができる一方、収入が不安定になりやすいという課題もある。"
        "自己管理能力が、フリーランスとして成功するための鍵となる。",
        "Semakin banyak orang yang bekerja sebagai freelancer tanpa "
        "terikat perusahaan. Di satu sisi bisa bekerja dengan bebas, "
        "tapi ada juga tantangan pendapatan yang mudah menjadi tidak "
        "stabil. Kemampuan manajemen diri menjadi kunci untuk sukses "
        "sebagai freelancer.",
        [
            ("会社に所属せず、どんな人が増えていますか。", ["フリーランスとして働く人", "転職する人", "起業する人", "退職する人"], 0),
            ("フリーランスの課題は何ですか。", ["収入が不安定になりやすいこと", "自由がないこと", "人と会えないこと", "難しすぎること"], 0),
            ("何がフリーランスとして成功するための鍵ですか。", ["自己管理能力", "学歴", "人脈だけ", "運"], 0),
        ],
    ),
    (
        "shokuba_sns_manaa",
        "Artikel tentang Etika Penggunaan Media Sosial di Tempat Kerja",
        "職場での出来事をSNSに投稿する際は、注意が必要である。同僚や"
        "取引先の情報を無断で公開してしまうと、信頼関係を損なう恐れが"
        "ある。公私の境界線を意識することが、社会人としての基本的な"
        "マナーだと言えるだろう。",
        "Saat memposting kejadian di tempat kerja ke media sosial, "
        "diperlukan kehati-hatian. Jika mempublikasikan informasi rekan "
        "kerja atau mitra bisnis tanpa izin, ada risiko merusak "
        "hubungan kepercayaan. Bisa dikatakan menyadari batas antara "
        "urusan pribadi dan pekerjaan adalah etika dasar sebagai "
        "pekerja.",
        [
            ("何を投稿する際に注意が必要ですか。", ["職場での出来事", "個人的な趣味", "天気", "料理"], 0),
            ("無断で情報を公開すると何の恐れがありますか。", ["信頼関係を損なうこと", "お金がかかること", "有名になること", "何も起きないこと"], 0),
            ("何が社会人としての基本的なマナーですか。", ["公私の境界線を意識すること", "SNSを使わないこと", "全てを公開すること", "何も投稿しないこと"], 0),
        ],
    ),
    (
        "jinsei_baransu_essei",
        "Esai tentang Menemukan Keseimbangan Hidup",
        "仕事に全力を注ぐことも大切だが、家族や友人と過ごす時間、そして"
        "自分自身をケアする時間も同じくらい大切だ。何か一つに偏るので"
        "はなく、様々な要素のバランスを取ることが、長期的な幸福につな"
        "がるのだと思う。",
        "Mencurahkan seluruh tenaga pada pekerjaan itu penting, tetapi "
        "waktu bersama keluarga dan teman, serta waktu untuk merawat "
        "diri sendiri juga sama pentingnya. Saya pikir bukan condong "
        "pada satu hal saja, tetapi menyeimbangkan berbagai elemen "
        "itulah yang mengarah pada kebahagiaan jangka panjang.",
        [
            ("仕事以外に何が大切だと述べられていますか。", ["家族や友人と過ごす時間と自分自身をケアする時間", "お金だけ", "趣味だけ", "何もない"], 0),
            ("何をすることが長期的な幸福につながりますか。", ["様々な要素のバランスを取ること", "仕事だけに集中すること", "一つのことだけに偏ること", "何もしないこと"], 0),
            ("この文章のテーマは何ですか。", ["人生のバランス", "仕事の効率", "お金の管理", "健康法"], 0),
        ],
    ),
    (
        "ryuugaku_taiken",
        "Cerita Pengalaman Belajar di Luar Negeri",
        "大学時代、一年間アメリカに留学した。最初は文化の違いに戸惑う"
        "ことも多かったが、様々な国の友人ができ、視野が大きく広がった。"
        "あの経験がなければ、今の自分はいなかったと思う。",
        "Saat kuliah, saya belajar di Amerika selama satu tahun. "
        "Awalnya sering bingung dengan perbedaan budaya, tapi saya "
        "mendapat teman dari berbagai negara, dan wawasan saya sangat "
        "meluas. Saya pikir tanpa pengalaman itu, tidak akan ada diri "
        "saya yang sekarang.",
        [
            ("いつアメリカに留学しましたか。", ["大学時代", "高校時代", "社会人になってから", "子供の時"], 0),
            ("留学期間はどのくらいでしたか。", ["一年間", "半年", "三か月", "二年間"], 0),
            ("この経験は筆者にとってどうでしたか。", ["今の自分につながる大切な経験", "無駄な経験", "大変なだけの経験", "忘れたい経験"], 0),
        ],
    ),
    (
        "ryokou_yosan_keikaku",
        "Panduan Merencanakan Anggaran Perjalanan",
        "旅行を計画する際は、まず全体の予算を決めることが大切だ。交通費、"
        "宿泊費、食費など、項目ごとに大まかな金額を割り振っておくと、"
        "旅行中にお金の心配をせずに楽しむことができる。",
        "Saat merencanakan perjalanan, penting untuk pertama-tama "
        "menentukan anggaran keseluruhan. Jika mengalokasikan jumlah "
        "kasar per kategori, seperti biaya transportasi, penginapan, "
        "dan makan, kita bisa menikmati perjalanan tanpa khawatir soal "
        "uang.",
        [
            ("旅行を計画する際、まず何が大切ですか。", ["全体の予算を決めること", "ホテルを予約すること", "服を準備すること", "友達を誘うこと"], 0),
            ("何ごとに金額を割り振りますか。", ["項目ごと", "日ごと", "人数ごと", "場所ごと"], 0),
            ("予算を決めておくと、旅行中どうなりますか。", ["お金の心配をせずに楽しめる", "もっと心配になる", "つまらなくなる", "何も変わらない"], 0),
        ],
    ),
    (
        "jizoku_kanou_kaimono",
        "Artikel tentang Tren Belanja Berkelanjutan",
        "使い捨て製品を避け、繰り返し使えるものを選ぶ消費者が増えて"
        "いる。マイボトルやマイバッグの利用が広がっているのも、その一例"
        "だ。小さな選択の積み重ねが、大きな環境保護につながると考えられ"
        "ている。",
        "Semakin banyak konsumen yang menghindari produk sekali pakai "
        "dan memilih barang yang bisa dipakai berulang kali. Meluasnya "
        "penggunaan botol minum dan tas sendiri juga salah satu "
        "contohnya. Diyakini akumulasi pilihan-pilihan kecil mengarah "
        "pada perlindungan lingkungan yang besar.",
        [
            ("消費者はどんなものを選ぶ傾向にありますか。", ["繰り返し使えるもの", "使い捨て製品", "一番安いもの", "一番新しいもの"], 0),
            ("その一例として何が挙げられていますか。", ["マイボトルやマイバッグの利用", "車の購入", "旅行", "貯金"], 0),
            ("小さな選択の積み重ねは何につながると考えられていますか。", ["大きな環境保護", "お金の節約だけ", "時間の節約", "何も変わらないこと"], 0),
        ],
    ),
    (
        "hihan_taiou_essei",
        "Esai tentang Menghadapi Kritik",
        "批判を受けると、つい落ち込んでしまいがちだが、その中には自分を"
        "成長させるヒントが隠れていることも多い。感情的に反発する前に、"
        "一度冷静に受け止めてみることが、建設的な対応につながるのでは"
        "ないだろうか。",
        "Saat menerima kritik, kita cenderung menjadi murung, tetapi "
        "di dalamnya sering tersembunyi petunjuk untuk mengembangkan "
        "diri sendiri. Bukankah mencoba menerimanya dengan tenang "
        "sekali sebelum bereaksi secara emosional, akan mengarah pada "
        "respons yang konstruktif?",
        [
            ("批判を受けるとどうなりがちですか。", ["落ち込んでしまいがち", "すぐに喜ぶ", "何も感じない", "無視する"], 0),
            ("批判の中に何が隠れていることが多いですか。", ["自分を成長させるヒント", "悪意だけ", "何の意味もないもの", "お金の価値"], 0),
            ("何が建設的な対応につながりますか。", ["冷静に受け止めること", "感情的に反発すること", "完全に無視すること", "すぐに謝ること"], 0),
        ],
    ),
    (
        "hoken_seikyuu_tetsuzuki",
        "Petunjuk Prosedur Pengajuan Klaim Asuransi",
        "事故が起きた場合、まず保険会社に連絡してください。その後、"
        "必要な書類を準備し、指定の窓口に提出します。手続きが完了する"
        "まで、一週間から二週間ほどかかることがあります。",
        "Jika terjadi kecelakaan, pertama-tama hubungi perusahaan "
        "asuransi. Setelah itu, siapkan dokumen yang diperlukan dan "
        "serahkan ke loket yang ditentukan. Sampai prosedur selesai, "
        "mungkin butuh waktu sekitar satu sampai dua minggu.",
        [
            ("事故が起きた場合、まず何をしますか。", ["保険会社に連絡する", "警察に電話する", "病院に行く", "何もしない"], 0),
            ("その後、何をしますか。", ["必要な書類を準備し提出する", "待つだけ", "何もしない", "すぐにお金をもらう"], 0),
            ("手続きにどのくらいかかることがありますか。", ["一週間から二週間ほど", "一日", "一か月以上", "すぐに"], 0),
        ],
    ),
    (
        "toshi_seikatsu_henka",
        "Artikel tentang Perubahan Gaya Hidup Perkotaan",
        "都市部では、コンパクトな生活空間を好む人が増えている。広い家"
        "よりも、駅から近く便利な場所に住むことを重視する傾向が強まって"
        "いるようだ。ライフスタイルの多様化が、住宅選びの基準にも影響を"
        "与えている。",
        "Di daerah perkotaan, semakin banyak orang yang menyukai ruang "
        "hidup yang kompak. Tampaknya kecenderungan mementingkan "
        "tinggal di tempat yang praktis dan dekat stasiun, dibandingkan "
        "rumah yang luas, semakin menguat. Diversifikasi gaya hidup "
        "juga memberikan pengaruh pada kriteria pemilihan tempat "
        "tinggal.",
        [
            ("都市部で何を好む人が増えていますか。", ["コンパクトな生活空間", "広い家", "田舎の生活", "大きな庭"], 0),
            ("何を重視する傾向が強まっていますか。", ["駅から近く便利な場所", "家の広さ", "家の値段の高さ", "家の古さ"], 0),
            ("何が住宅選びの基準に影響を与えていますか。", ["ライフスタイルの多様化", "政府の政策", "気候変動", "人口減少"], 0),
        ],
    ),
    (
        "mentaa_taiken",
        "Cerita Pengalaman Menjadi Mentor",
        "会社で新入社員のメンターを任された。最初は自分に務まるか不安"
        "だったが、相手の話をよく聞くことを心がけたら、少しずつ信頼"
        "関係が築けるようになった。教える側にも、多くの学びがあること"
        "に気づいた。",
        "Di perusahaan, saya dipercayakan menjadi mentor karyawan "
        "baru. Awalnya cemas apakah saya bisa menjalankannya, tapi "
        "setelah berusaha mendengarkan cerita lawan bicara dengan baik, "
        "sedikit demi sedikit saya bisa membangun hubungan kepercayaan. "
        "Saya menyadari bahwa pihak yang mengajar pun mendapat banyak "
        "pembelajaran.",
        [
            ("会社で何を任されましたか。", ["新入社員のメンター", "部長の仕事", "営業", "経理"], 0),
            ("最初、どうでしたか。", ["自分に務まるか不安だった", "とても自信があった", "楽しかっただけ", "興味がなかった"], 0),
            ("何を心がけましたか。", ["相手の話をよく聞くこと", "厳しく指導すること", "何も教えないこと", "早く終わらせること"], 0),
        ],
    ),
    (
        "seikou_teigi_wakamono",
        "Esai tentang Arti Kesuksesan bagi Generasi Muda",
        "かつて成功とは、大企業に就職し、出世することだと考えられて"
        "いた。しかし今の若い世代にとって、成功の定義はより多様化して"
        "いる。自分らしく生きることそのものを、成功と捉える人が増えて"
        "いるようだ。",
        "Dulu kesuksesan dianggap sebagai bekerja di perusahaan besar "
        "dan naik jabatan. Namun bagi generasi muda sekarang, definisi "
        "kesuksesan menjadi lebih beragam. Tampaknya semakin banyak "
        "orang yang menganggap hidup sesuai diri sendiri itu sendiri "
        "sebagai kesuksesan.",
        [
            ("かつて成功とは何だと考えられていましたか。", ["大企業に就職し出世すること", "自分らしく生きること", "お金を稼ぐこと", "有名になること"], 0),
            ("今の若い世代にとって、成功の定義はどうなっていますか。", ["より多様化している", "変わらない", "より画一的になっている", "なくなっている"], 0),
            ("何を成功と捉える人が増えていますか。", ["自分らしく生きることそのもの", "大企業への就職だけ", "お金を稼ぐことだけ", "出世することだけ"], 0),
        ],
    ),
    (
        "telework_hatten_kiji",
        "Artikel tentang Perkembangan Kerja Jarak Jauh",
        "テレワークが普及したことで、通勤時間がなくなり、自分の時間を"
        "有効に使えるようになった人が多い。一方で、同僚とのコミュニ"
        "ケーション不足に悩まされる人も少なくないわけで、企業側も"
        "新しい工夫を求められている。",
        "Dengan menyebarnya kerja jarak jauh, banyak orang yang waktu "
        "perjalanannya hilang dan bisa memakai waktunya sendiri "
        "dengan efektif. Di sisi lain, tidak sedikit juga orang yang "
        "direpotkan oleh kurangnya komunikasi dengan rekan kerja, "
        "sehingga perusahaan juga dituntut untuk mencari inovasi "
        "baru.",
        [
            ("テレワークが普及して何がなくなりましたか。", ["通勤時間", "仕事", "給料", "休日"], 0),
            ("一部の人は何に悩まされていますか。", ["同僚とのコミュニケーション不足", "給料の低さ", "通勤時間の長さ", "仕事の少なさ"], 0),
            ("企業側は何を求められていますか。", ["新しい工夫", "給料の削減", "テレワークの廃止", "残業の増加"], 0),
        ],
    ),
    (
        "shiken_puresshaa_essay",
        "Esai tentang Menghadapi Tekanan Ujian",
        "試験が近づくと、多くの学生がプレッシャーに押しつぶされそうに"
        "なる。しかし、完璧を求めすぎるあまり、逆に力を発揮できなく"
        "なることもあるわけだ。適度な息抜きをしながら、自分のペース"
        "を保つことが大切だと思う。",
        "Ketika ujian mendekat, banyak siswa yang hampir tertekan oleh "
        "tekanan. Namun, karena terlalu menuntut kesempurnaan, "
        "terkadang justru menjadi tidak bisa mengeluarkan "
        "kemampuannya. Saya pikir penting untuk menjaga ritme sendiri "
        "sambil sesekali beristirahat secukupnya.",
        [
            ("試験が近づくと学生はどうなりますか。", ["プレッシャーに押しつぶされそうになる", "もっと元気になる", "勉強しなくなる", "遊びたくなる"], 0),
            ("完璧を求めすぎるとどうなることがありますか。", ["力を発揮できなくなる", "もっと成功する", "楽になる", "何も変わらない"], 0),
            ("筆者は何が大切だと思っていますか。", ["適度な息抜きをしながら自分のペースを保つこと", "休まず勉強し続けること", "完璧を目指すこと", "競争すること"], 0),
        ],
    ),
    (
        "gakkyuu_iinchou_taiken",
        "Cerita Pengalaman Menjadi Ketua Kelas",
        "クラスの委員長に選ばれたとき、正直気が重かった。しかし、みん"
        "なの意見をまとめる中で、自分にも思っていた以上のリーダー"
        "シップがあることに気づかされた。この経験を通して、少し自分"
        "に自信が持てるようになった。",
        "Ketika terpilih menjadi ketua kelas, sejujurnya hati saya "
        "berat. Namun, dalam proses merangkum pendapat semua orang, "
        "saya disadarkan bahwa saya memiliki jiwa kepemimpinan yang "
        "lebih dari yang saya kira. Melalui pengalaman ini, saya jadi "
        "sedikit lebih percaya diri.",
        [
            ("委員長に選ばれたとき、筆者はどう感じましたか。", ["気が重かった", "うれしかった", "何も感じなかった", "怒った"], 0),
            ("何をする中で自分のリーダーシップに気づきましたか。", ["みんなの意見をまとめること", "一人で決めること", "先生に相談すること", "何もしないこと"], 0),
            ("この経験を通してどうなりましたか。", ["少し自信が持てるようになった", "もっと不安になった", "委員長を辞めたくなった", "何も変わらなかった"], 0),
        ],
    ),
    (
        "sns_riyou_manaa_guide",
        "Panduan Etika Menggunakan Media Sosial",
        "SNSに投稿する前に、その内容が誰かを傷つけないか、一度立ち"
        "止まって考えることが求められる。何気ない一言が、思いもよら"
        "ない形で拡散されてしまうこともあるわけで、慎重な発信が必要"
        "だ。",
        "Sebelum memposting di media sosial, dituntut untuk sejenak "
        "berhenti dan memikirkan apakah kontennya bisa melukai "
        "seseorang. Satu kata yang tidak disengaja pun bisa tersebar "
        "dalam bentuk yang tak terduga, sehingga diperlukan pengiriman "
        "informasi yang hati-hati.",
        [
            ("SNSに投稿する前に何が求められますか。", ["立ち止まって考えること", "すぐに投稿すること", "誰かに聞くこと", "何も考えないこと"], 0),
            ("何気ない一言はどうなることがありますか。", ["思いもよらない形で拡散される", "誰にも見られない", "すぐに消える", "無視される"], 0),
            ("この文章は何が必要だと言っていますか。", ["慎重な発信", "たくさんの投稿", "早い投稿", "匿名の投稿"], 0),
        ],
    ),
    (
        "kankyou_shouhi_trend_kiji",
        "Artikel tentang Tren Konsumsi Ramah Lingkungan",
        "環境への配慮から、必要な分だけ買う消費スタイルを選ぶ人が"
        "増えている。過剰包装を避けたり、詰め替え用の商品を選んだり"
        "することも、その一環だ。小さな選択の積み重ねが、社会全体を"
        "変えることになるのだろう。",
        "Karena kepedulian pada lingkungan, semakin banyak orang yang "
        "memilih gaya konsumsi membeli seperlunya saja. Menghindari "
        "kemasan berlebihan atau memilih produk isi ulang juga menjadi "
        "bagian dari itu. Akumulasi pilihan-pilihan kecil itu mungkin "
        "akan mengubah seluruh masyarakat.",
        [
            ("なぜ必要な分だけ買う人が増えていますか。", ["環境への配慮から", "お金がないから", "流行だから", "店が少ないから"], 0),
            ("その一環として何をする人がいますか。", ["過剰包装を避けたり詰め替え用商品を選んだりする", "たくさん買う", "高い商品だけ買う", "何も買わない"], 0),
            ("小さな選択の積み重ねはどうなると言っていますか。", ["社会全体を変えることになる", "何も変わらない", "経済を悪化させる", "無意味になる"], 0),
        ],
    ),
    (
        "kazoku_communication_essay",
        "Esai tentang Pentingnya Komunikasi Keluarga",
        "忙しい毎日の中で、家族との会話が減ってしまうことがある。しか"
        "し、たとえ短い時間でも、顔を合わせて話すことには大きな意味"
        "があるわけだ。ちょっとした会話の積み重ねが、家族の絆を支え"
        "ているのだと思う。",
        "Di tengah kesibukan sehari-hari, terkadang percakapan dengan "
        "keluarga berkurang. Namun, bahkan dalam waktu singkat "
        "sekalipun, berbicara dengan bertatap muka memiliki makna "
        "besar. Saya pikir akumulasi obrolan kecil itulah yang "
        "menopang ikatan keluarga.",
        [
            ("忙しい毎日の中で何が減ってしまうことがありますか。", ["家族との会話", "仕事", "お金", "睡眠時間"], 0),
            ("短い時間でも顔を合わせて話すことには何がありますか。", ["大きな意味", "意味がないこと", "面倒なこと", "無駄なこと"], 0),
            ("筆者は何が家族の絆を支えていると思っていますか。", ["ちょっとした会話の積み重ね", "お金", "一緒に住むことだけ", "プレゼント"], 0),
        ],
    ),
    (
        "shougakukin_shinsei_tetsuzuki",
        "Petunjuk Prosedur Pengajuan Beasiswa",
        "奨学金を申請する場合、まず必要な書類をそろえることになる。"
        "成績証明書と申請書、それに家庭の収入を証明する書類が求めら"
        "れる。締め切りに遅れると受け付けてもらえないので、早めの"
        "準備が欠かせない。",
        "Jika mengajukan beasiswa, pertama-tama harus mengumpulkan "
        "dokumen yang diperlukan. Diperlukan surat keterangan nilai, "
        "formulir pengajuan, dan dokumen yang membuktikan penghasilan "
        "keluarga. Jika terlambat dari batas waktu, tidak akan "
        "diterima, jadi persiapan sejak dini tidak bisa dihindari.",
        [
            ("奨学金を申請する場合、まず何をしますか。", ["必要な書類をそろえる", "面接を受ける", "お金を払う", "学校を変える"], 0),
            ("どんな書類が求められますか。", ["成績証明書と申請書、収入を証明する書類", "パスポートだけ", "写真だけ", "何もいらない"], 0),
            ("締め切りに遅れるとどうなりますか。", ["受け付けてもらえない", "自動的に延長される", "罰金を払う", "もう一度申請できる"], 0),
        ],
    ),
    (
        "kaimono_shuukan_henka_kiji",
        "Artikel tentang Perubahan Kebiasaan Belanja",
        "インターネットショッピングの普及により、実店舗に足を運ばなく"
        "ても買い物ができるようになった。その反面、実際に商品を見て"
        "選ぶ楽しさが失われつつあると感じる人もいるわけで、両方の"
        "良さを求める動きも出てきている。",
        "Dengan meluasnya belanja internet, orang bisa berbelanja "
        "tanpa harus pergi ke toko fisik. Di sisi lain, ada juga orang "
        "yang merasa kesenangan melihat dan memilih barang secara "
        "langsung mulai hilang, sehingga muncul juga gerakan yang "
        "mencari kebaikan dari keduanya.",
        [
            ("インターネットショッピングの普及で何が可能になりましたか。", ["実店舗に足を運ばなくても買い物ができること", "もっと高く買うこと", "店員と話すこと", "返品できないこと"], 0),
            ("何が失われつつあると感じる人がいますか。", ["実際に商品を見て選ぶ楽しさ", "お金", "時間", "健康"], 0),
            ("どんな動きが出てきていますか。", ["両方の良さを求める動き", "実店舗をなくす動き", "ネット通販をやめる動き", "何もしない動き"], 0),
        ],
    ),
    (
        "benkyou_iyoku_hakken_essay",
        "Esai tentang Menemukan Motivasi Belajar",
        "なぜ勉強するのかという問いに、明確な答えを持てずにいた時期"
        "があった。しかし、興味のある分野に出会ってからは、勉強する"
        "ことが苦ではなくなった。誰かに言われてやるのではなく、自分"
        "から学びたいと思えることが、何より大切なのだと気づかされ"
        "た。",
        "Ada masa ketika saya tidak bisa memiliki jawaban jelas atas "
        "pertanyaan mengapa belajar. Namun, setelah bertemu dengan "
        "bidang yang menarik minat saya, belajar tidak lagi terasa "
        "menyakitkan. Saya disadarkan bahwa yang paling penting "
        "bukanlah melakukannya karena disuruh orang lain, melainkan "
        "bisa berpikir ingin belajar dari diri sendiri.",
        [
            ("筆者はどんな時期がありましたか。", ["なぜ勉強するのか明確な答えを持てない時期", "毎日楽しく勉強する時期", "全く勉強しない時期", "勉強が簡単だった時期"], 0),
            ("何に出会ってから勉強が苦ではなくなりましたか。", ["興味のある分野", "新しい先生", "高い成績", "友達"], 0),
            ("筆者は何が何より大切だと気づきましたか。", ["自分から学びたいと思えること", "成績が良いこと", "誰かに褒められること", "早く終わらせること"], 0),
        ],
    ),
    (
        "gaikoku_kigyou_hataraku_taiken",
        "Cerita Pengalaman Bekerja di Perusahaan Asing",
        "外国企業で働くことになって、最初は文化の違いに戸惑うことば"
        "かりだった。会議での発言の仕方も、日本の職場とはかなり違っ"
        "たわけだ。しかし、慣れてくるにつれて、はっきりと意見を言う"
        "習慣が自分にも身についてきたように思う。",
        "Setelah harus bekerja di perusahaan asing, awalnya saya "
        "selalu bingung dengan perbedaan budaya. Cara berbicara dalam "
        "rapat pun cukup berbeda dari tempat kerja Jepang. Namun, "
        "seiring terbiasa, saya merasa kebiasaan menyampaikan pendapat "
        "dengan jelas juga mulai melekat pada diri saya.",
        [
            ("最初、筆者はどうでしたか。", ["文化の違いに戸惑うことばかりだった", "すぐに慣れた", "何も感じなかった", "嫌になってやめた"], 0),
            ("会議での発言の仕方は何と違いましたか。", ["日本の職場", "学校", "家庭", "前の会社"], 0),
            ("慣れてくるにつれて、筆者にはどんな習慣が身についてきましたか。", ["はっきりと意見を言う習慣", "黙っている習慣", "遅刻する習慣", "何もしない習慣"], 0),
        ],
    ),
]

N2_ENTRIES = [
    (
        "keiei_houkoku",
        "Laporan Manajemen Perusahaan",
        "今年度、当社の売り上げは前年に比べて増加した。これは、新しい"
        "商品の開発をきっかけに、若い世代の顧客が増えたことが大きな要因"
        "である。しかし、原材料費の上昇にもかかわらず、価格をあまり"
        "上げられなかったため、利益率はそれほど伸びていない。",
        "Tahun fiskal ini, penjualan perusahaan kami meningkat dibanding "
        "tahun lalu. Faktor besarnya adalah bertambahnya pelanggan "
        "generasi muda, dipicu oleh pengembangan produk baru. Namun, "
        "meskipun biaya bahan baku naik, karena kami tidak bisa banyak "
        "menaikkan harga, margin keuntungan tidak begitu meningkat.",
        [
            ("売り上げが増加したきっかけは何ですか。", ["新しい商品の開発", "広告を増やしたこと", "店を増やしたこと", "値段を下げたこと"], 0),
            ("利益率があまり伸びなかった理由は何ですか。", ["価格をあまり上げられなかったから", "顧客が減ったから", "商品が売れなかったから", "社員が辞めたから"], 0),
            ("原材料費はどうなりましたか。", ["上昇した", "下がった", "変わらなかった", "なくなった"], 0),
        ],
    ),
    (
        "shakai_ronsetsu",
        "Editorial Sosial",
        "働き方改革が進む中、労働時間は以前に比べて短くなったという"
        "ものの、実際には仕事量が減っていないという声も多い。企業は、"
        "労働時間の管理だけでなく、業務内容そのものを見直す必要がある"
        "のではないだろうか。",
        "Di tengah kemajuan reformasi gaya kerja, meskipun jam kerja "
        "dikatakan lebih pendek dibanding sebelumnya, banyak juga suara "
        "yang mengatakan bahwa beban kerja sebenarnya tidak berkurang. "
        "Bukankah perusahaan perlu meninjau ulang bukan hanya manajemen "
        "jam kerja, tapi juga isi pekerjaan itu sendiri?",
        [
            ("労働時間はどうなったと言われていますか。", ["短くなった", "長くなった", "変わらない", "なくなった"], 0),
            ("実際にはどんな声が多いですか。", ["仕事量が減っていない", "給料が増えた", "休みが増えた", "満足している"], 0),
            ("筆者は企業に何が必要だと考えていますか。", ["業務内容そのものを見直すこと", "労働時間を増やすこと", "社員を減らすこと", "給料を下げること"], 0),
        ],
    ),
    (
        "kagaku_setsumei",
        "Penjelasan Ilmiah",
        "地球温暖化は、気温の上昇だけでなく、生態系全体に大きな影響を"
        "及ぼしている。海水温の上昇に応じて、多くの海の生物が生息地を"
        "移動せざるを得なくなっている。この変化は、私たちの食生活にも"
        "影響を与える可能性がある。",
        "Pemanasan global memberikan dampak besar bukan hanya pada "
        "kenaikan suhu, tapi pada seluruh ekosistem. Sesuai dengan "
        "naiknya suhu air laut, banyak makhluk laut terpaksa berpindah "
        "habitat. Perubahan ini berpotensi mempengaruhi pola makan kita "
        "juga.",
        [
            ("地球温暖化は何に影響を及ぼしていますか。", ["生態系全体", "気温だけ", "海の色", "空の色"], 0),
            ("海水温の上昇に応じて、海の生物はどうなっていますか。", ["生息地を移動せざるを得ない", "数が増えている", "何も変わらない", "大きくなっている"], 0),
            ("この変化は何に影響を与える可能性がありますか。", ["私たちの食生活", "交通", "教育", "スポーツ"], 0),
        ],
    ),
    (
        "jinsei_esse",
        "Esai tentang Karier dan Kehidupan",
        "三十歳を迎えたことをきっかけに、これまでの人生を振り返って"
        "みた。仕事において多くの失敗を経験したが、それらは今の自分に"
        "とって貴重な学びとなっている。若いうちの失敗は恥ずかしいもので"
        "はなく、むしろ成長の証だと思うようになった。",
        "Dipicu oleh memasuki usia tiga puluh, saya mencoba merenungkan "
        "kembali kehidupan saya selama ini. Dalam pekerjaan, saya "
        "mengalami banyak kegagalan, tetapi hal-hal itu menjadi "
        "pembelajaran berharga bagi diri saya sekarang. Saya menjadi "
        "berpikir bahwa kegagalan di usia muda bukanlah hal yang "
        "memalukan, melainkan bukti pertumbuhan.",
        [
            ("何をきっかけに人生を振り返りましたか。", ["三十歳を迎えたこと", "結婚したこと", "転職したこと", "病気になったこと"], 0),
            ("仕事での失敗は今の自分にとって何になっていますか。", ["貴重な学び", "後悔", "恥", "無駄なこと"], 0),
            ("若いうちの失敗をどう考えるようになりましたか。", ["成長の証", "恥ずかしいもの", "避けるべきもの", "無意味なもの"], 0),
        ],
    ),
    (
        "keizai_nyuusu",
        "Berita Ekonomi",
        "先月発表された経済指標によると、消費者の支出は増加傾向にあると"
        "いう。物価の上昇にもかかわらず、消費が伸びているのは、将来への"
        "期待感が高まっているためだと分析されている。専門家は、この"
        "傾向がしばらく続くと予測している。",
        "Menurut indikator ekonomi yang diumumkan bulan lalu, "
        "pengeluaran konsumen dikatakan cenderung meningkat. Meskipun "
        "harga barang naik, konsumsi yang meningkat dianalisis karena "
        "harapan terhadap masa depan yang semakin tinggi. Para ahli "
        "memperkirakan tren ini akan berlanjut untuk sementara waktu.",
        [
            ("消費者の支出はどんな傾向にありますか。", ["増加傾向", "減少傾向", "変わらない", "なくなる"], 0),
            ("消費が伸びている理由は何だと分析されていますか。", ["将来への期待感が高まっているから", "物価が下がったから", "給料が上がったから", "税金が減ったから"], 0),
            ("専門家はこの傾向についてどう予測していますか。", ["しばらく続く", "すぐ終わる", "逆転する", "分からない"], 0),
        ],
    ),
    (
        "bunka_bunseki",
        "Analisis Budaya",
        "近年、日本のアニメや漫画は世界中で人気を集めている。その人気は、"
        "単なる娯楽としてだけでなく、日本文化を世界に広める役割も果たして"
        "いるといえる。一方で、作品の一部の表現が誤解を招く可能性も"
        "指摘されている。",
        "Belakangan ini, anime dan manga Jepang mendapatkan popularitas "
        "di seluruh dunia. Popularitas itu bisa dikatakan bukan hanya "
        "sebagai hiburan semata, tapi juga berperan menyebarkan budaya "
        "Jepang ke dunia. Di sisi lain, ada juga yang menunjukkan bahwa "
        "sebagian ekspresi dalam karya bisa menimbulkan kesalahpahaman.",
        [
            ("日本のアニメや漫画は世界でどうなっていますか。", ["人気を集めている", "人気がなくなっている", "禁止されている", "知られていない"], 0),
            ("その人気はどんな役割を果たしていますか。", ["日本文化を世界に広める役割", "お金を稼ぐだけの役割", "教育の役割", "何の役割もない"], 0),
            ("一方で何が指摘されていますか。", ["表現が誤解を招く可能性", "値段が高すぎること", "質が低いこと", "人気がなくなること"], 0),
        ],
    ),
    (
        "shokugyou_kaihatsu",
        "Pengembangan Karier",
        "終身雇用が一般的だった時代は終わりつつあり、転職はもはや珍しい"
        "ことではなくなった。自分のスキルに応じて、より良い環境を求めて"
        "転職する人が増えている反面、一つの会社で長く働くことの価値を"
        "見直す動きもある。",
        "Era di mana pekerjaan seumur hidup itu umum sudah mulai "
        "berakhir, dan pindah kerja bukan lagi hal yang aneh. Meskipun "
        "jumlah orang yang pindah kerja mencari lingkungan lebih baik "
        "sesuai keahliannya bertambah, di sisi lain ada juga gerakan "
        "untuk meninjau kembali nilai bekerja lama di satu perusahaan.",
        [
            ("終身雇用が一般的だった時代はどうなっていますか。", ["終わりつつある", "続いている", "始まったばかり", "関係ない"], 0),
            ("転職する人が増えている理由は何ですか。", ["より良い環境を求めて", "お金がないから", "友達がいないから", "家が遠いから"], 0),
            ("一方で、どんな動きがありますか。", ["長く働くことの価値を見直す動き", "転職をやめさせる動き", "給料を下げる動き", "会社を減らす動き"], 0),
        ],
    ),
    (
        "iryou_seisaku",
        "Kebijakan Medis",
        "高齢化が進むにつれ、医療費の負担が社会全体の課題となっている。"
        "政府は、予防医療を推進することで、将来的な医療費の増加を抑え"
        "ようとしている。しかし、予防医療の効果が現れるまでには時間が"
        "かかるため、即効性を期待するのは難しい。",
        "Seiring berkembangnya penuaan populasi, beban biaya medis "
        "menjadi tantangan bagi seluruh masyarakat. Pemerintah berusaha "
        "menekan kenaikan biaya medis di masa depan dengan mendorong "
        "pengobatan preventif. Namun, karena efek pengobatan preventif "
        "membutuhkan waktu untuk muncul, sulit untuk mengharapkan hasil "
        "instan.",
        [
            ("高齢化が進むと、何が社会全体の課題になりますか。", ["医療費の負担", "交通の問題", "教育の問題", "住宅の問題"], 0),
            ("政府は何を推進していますか。", ["予防医療", "新しい薬の開発", "病院の建設", "保険料の値上げ"], 0),
            ("予防医療について、何が難しいと言われていますか。", ["即効性を期待すること", "お金がかかりすぎること", "誰も興味がないこと", "効果がまったくないこと"], 0),
        ],
    ),
    (
        "kigyou_senryaku",
        "Strategi Perusahaan",
        "グローバル化が進む中、多くの企業は海外市場への進出を積極的に"
        "検討している。ただし、文化や商習慣の違いにより、思うように事業"
        "が進まないケースも少なくない。現地の状況を十分に理解した上で"
        "戦略を立てることが求められている。",
        "Di tengah kemajuan globalisasi, banyak perusahaan yang secara "
        "aktif mempertimbangkan ekspansi ke pasar luar negeri. Namun, "
        "karena perbedaan budaya dan kebiasaan bisnis, tidak sedikit "
        "kasus di mana bisnis tidak berjalan sesuai harapan. Dituntut "
        "untuk menyusun strategi setelah cukup memahami kondisi "
        "setempat.",
        [
            ("多くの企業は何を検討していますか。", ["海外市場への進出", "国内市場からの撤退", "社員の削減", "給料の値上げ"], 0),
            ("どうして事業が思うように進まないケースがありますか。", ["文化や商習慣の違い", "お金がないから", "社員が少ないから", "技術が古いから"], 0),
            ("何が求められていますか。", ["現地の状況を理解した上で戦略を立てること", "とにかく早く進出すること", "現地の言葉を覚えないこと", "本社と同じやり方をすること"], 0),
        ],
    ),
    (
        "kyouiku_ronbun",
        "Esai tentang Pendidikan",
        "オンライン教育の普及により、場所を問わず学べる環境が整いつつ"
        "ある。これは学習の機会を広げるという点で意義深い反面、直接の"
        "対面授業に比べて、集中力を保つのが難しいという課題も浮き彫りに"
        "なっている。",
        "Dengan menyebarnya pendidikan online, lingkungan untuk belajar "
        "tanpa batas tempat mulai terbentuk. Ini bermakna dalam hal "
        "memperluas kesempatan belajar, namun di sisi lain, muncul juga "
        "tantangan bahwa mempertahankan konsentrasi lebih sulit "
        "dibandingkan kelas tatap muka langsung.",
        [
            ("オンライン教育の普及で何が整いつつありますか。", ["場所を問わず学べる環境", "高い給料", "新しい建物", "交通機関"], 0),
            ("オンライン教育はどんな点で意義深いですか。", ["学習の機会を広げること", "値段が安いこと", "簡単なこと", "早く終わること"], 0),
            ("どんな課題が浮き彫りになっていますか。", ["集中力を保つのが難しいこと", "先生が足りないこと", "教科書が高いこと", "時間が短すぎること"], 0),
        ],
    ),
    (
        "shijou_chousa",
        "Laporan Riset Pasar",
        "今回の市場調査において、二十代から三十代の消費者は、価格よりも"
        "商品の背景にあるストーリーを重視する傾向が明らかになった。この"
        "結果を踏まえ、単に安さを訴求するのではなく、ブランドの価値観を"
        "伝える戦略が求められている。",
        "Dalam riset pasar kali ini, terungkap bahwa konsumen usia 20-an "
        "hingga 30-an cenderung mementingkan cerita di balik produk "
        "dibandingkan harga. Berdasarkan hasil ini, dituntut strategi "
        "yang menyampaikan nilai brand, bukan sekadar menonjolkan "
        "kemurahan harga.",
        [
            ("どの世代の消費者について調査しましたか。", ["二十代から三十代", "十代", "四十代から五十代", "全世代"], 0),
            ("消費者は何を重視する傾向がありますか。", ["商品の背景にあるストーリー", "価格の安さ", "デザインだけ", "有名なブランド名"], 0),
            ("この結果から、どんな戦略が求められていますか。", ["ブランドの価値観を伝える戦略", "とにかく安くする戦略", "広告を増やす戦略", "店舗を減らす戦略"], 0),
        ],
    ),
    (
        "kodomo_kyouiku_ronsetsu",
        "Editorial tentang Pendidikan Anak",
        "子供の自主性を育てるためには、失敗を恐れずに挑戦できる環境を"
        "用意することが欠かせない。親がすべてを先回りして手助けするので"
        "はなく、時には見守る姿勢も必要だろう。過保護は、かえって子供の"
        "成長を妨げる可能性がある。",
        "Untuk menumbuhkan kemandirian anak, penting untuk menyiapkan "
        "lingkungan yang memungkinkan mereka mencoba tanpa takut gagal. "
        "Orang tua tidak selalu membantu terlebih dahulu untuk semuanya, "
        "tetapi terkadang sikap mengawasi dari jauh juga diperlukan. "
        "Terlalu melindungi justru bisa menghambat pertumbuhan anak.",
        [
            ("子供の自主性を育てるために何が欠かせませんか。", ["失敗を恐れずに挑戦できる環境", "高価なおもちゃ", "たくさんの宿題", "厳しいルール"], 0),
            ("親にはどんな姿勢も必要だと言っていますか。", ["見守る姿勢", "常に手助けする姿勢", "無関心な姿勢", "厳しく叱る姿勢"], 0),
            ("過保護はどんな可能性がありますか。", ["子供の成長を妨げること", "子供を賢くすること", "子供を幸せにすること", "何も変わらないこと"], 0),
        ],
    ),
    (
        "kankyou_gijutsu",
        "Artikel tentang Inovasi Teknologi Ramah Lingkungan",
        "太陽光発電の技術は年々進歩しており、以前に比べて発電効率が大幅に"
        "向上した。それに伴い、導入コストも下がってきている。今後、こう"
        "した再生可能エネルギー技術の普及が、環境問題の解決に大きく貢献"
        "することが期待されている。",
        "Teknologi pembangkit listrik tenaga surya berkembang setiap "
        "tahun, efisiensi pembangkitannya meningkat pesat dibanding "
        "sebelumnya. Seiring dengan itu, biaya pemasangan juga mulai "
        "turun. Ke depannya, diharapkan penyebaran teknologi energi "
        "terbarukan seperti ini berkontribusi besar dalam menyelesaikan "
        "masalah lingkungan.",
        [
            ("太陽光発電の技術はどうなっていますか。", ["年々進歩している", "進歩が止まった", "使われなくなった", "昔と変わらない"], 0),
            ("発電効率が上がると、コストはどうなりましたか。", ["下がってきている", "上がっている", "変わらない", "分からない"], 0),
            ("何が環境問題の解決に貢献すると期待されていますか。", ["再生可能エネルギー技術の普及", "石油の使用増加", "人口の減少", "都市の拡大"], 0),
        ],
    ),
    (
        "waaku_raifu_baransu",
        "Esai tentang Keseimbangan Kerja dan Kehidupan",
        "仕事に情熱を注ぐことは大切だが、それによってプライベートの時間が"
        "犠牲になってしまっては本末転倒である。効率よく働き、限られた"
        "時間の中で成果を出す力こそが、これからの時代に求められる能力で"
        "はないだろうか。",
        "Mencurahkan semangat pada pekerjaan itu penting, tetapi jika "
        "waktu pribadi menjadi korban karena itu, itu adalah kebalikan "
        "dari yang seharusnya. Bukankah kemampuan untuk bekerja secara "
        "efisien dan menghasilkan hasil dalam waktu yang terbatas adalah "
        "kemampuan yang dibutuhkan di era mendatang?",
        [
            ("何が大切だと述べられていますか。", ["仕事に情熱を注ぐこと", "プライベートを完全に犠牲にすること", "仕事を辞めること", "お金を稼がないこと"], 0),
            ("プライベートの時間が犠牲になることを筆者はどう表現していますか。", ["本末転倒", "当然のこと", "理想的なこと", "簡単なこと"], 0),
            ("これからの時代に求められる能力とは何ですか。", ["限られた時間の中で成果を出す力", "長時間働く力", "お金を稼ぐ力だけ", "何もしない力"], 0),
        ],
    ),
    (
        "shouhisha_toreando",
        "Analisis Tren Konsumen",
        "近年、モノを所有することよりも、体験を重視する消費者が増えて"
        "いる。旅行やイベントへの支出が伸びている一方、物品の購入は伸び"
        "悩んでいるというデータもある。この傾向は、特に若い世代において"
        "顕著に見られる。",
        "Belakangan ini, semakin banyak konsumen yang lebih mementingkan "
        "pengalaman daripada memiliki barang. Ada data yang menunjukkan "
        "bahwa pengeluaran untuk perjalanan dan acara meningkat, "
        "sementara pembelian barang cenderung stagnan. Tren ini terlihat "
        "sangat menonjol terutama di kalangan generasi muda.",
        [
            ("最近、消費者は何を重視するようになっていますか。", ["体験", "モノの所有", "値段の安さ", "ブランド名"], 0),
            ("何への支出が伸びていますか。", ["旅行やイベント", "家具", "電化製品", "服だけ"], 0),
            ("この傾向はどの世代に顕著ですか。", ["若い世代", "高齢者", "全世代同じ", "子供だけ"], 0),
        ],
    ),
    (
        "bunka_gaikou",
        "Artikel tentang Diplomasi Budaya",
        "文化交流は、国と国との関係を深める上で重要な役割を果たしている。"
        "政治的な対立があったとしても、映画や音楽、料理といった文化を"
        "通じた交流は、人々の心の距離を縮める力を持っているといえる"
        "だろう。",
        "Pertukaran budaya memainkan peran penting dalam memperdalam "
        "hubungan antarnegara. Meskipun ada konflik politik, bisa "
        "dikatakan bahwa pertukaran melalui budaya seperti film, musik, "
        "dan masakan memiliki kekuatan untuk mempersempit jarak hati "
        "antarmanusia.",
        [
            ("文化交流はどんな役割を果たしていますか。", ["国と国との関係を深める役割", "経済を発展させる役割", "戦争を起こす役割", "何の役割もない"], 0),
            ("文化交流の例として何が挙げられていますか。", ["映画や音楽、料理", "政治の会議", "軍事訓練", "経済制裁"], 0),
            ("文化を通じた交流はどんな力を持っていますか。", ["人々の心の距離を縮める力", "対立を深める力", "何も変えない力", "お金を作る力"], 0),
        ],
    ),
    (
        "kazoku_isan",
        "Esai tentang Warisan Keluarga",
        "祖父が遺してくれた古い時計を、今も大切に使っている。動くたびに、"
        "祖父と過ごした時間が思い出される。物としての価値はそれほど高く"
        "ないかもしれないが、私にとっては何にも代えがたい宝物である。",
        "Jam tua yang ditinggalkan kakek, masih saya gunakan dengan "
        "hati-hati sampai sekarang. Setiap kali berjalan, saya teringat "
        "waktu yang saya habiskan bersama kakek. Sebagai barang, nilainya "
        "mungkin tidak begitu tinggi, tetapi bagi saya, itu adalah harta "
        "yang tak tergantikan oleh apa pun.",
        [
            ("祖父は何を遺してくれましたか。", ["古い時計", "お金", "家", "本"], 0),
            ("時計が動くたびに、何が思い出されますか。", ["祖父と過ごした時間", "学校生活", "旅行の思い出", "仕事のこと"], 0),
            ("筆者にとって、この時計はどんな存在ですか。", ["何にも代えがたい宝物", "ただの古い物", "邪魔な物", "売りたい物"], 0),
        ],
    ),
    (
        "jinkou_henka_houkoku",
        "Laporan tentang Perubahan Demografi",
        "少子化が進む中、地方都市では人口減少が特に深刻な問題となって"
        "いる。若者の都市部への流出も一因とされており、地域経済の維持が"
        "困難になりつつある自治体も少なくない。抜本的な対策が急がれて"
        "いる。",
        "Di tengah penurunan angka kelahiran, penurunan populasi menjadi "
        "masalah yang sangat serius terutama di kota-kota daerah. "
        "Perpindahan anak muda ke wilayah perkotaan juga dianggap "
        "sebagai salah satu penyebabnya, dan tidak sedikit pemerintah "
        "daerah yang mulai kesulitan mempertahankan ekonomi wilayahnya. "
        "Langkah-langkah fundamental sangat mendesak diperlukan.",
        [
            ("地方都市で特に深刻な問題は何ですか。", ["人口減少", "交通渋滞", "環境汚染", "物価上昇"], 0),
            ("一因とされているのは何ですか。", ["若者の都市部への流出", "高齢者の増加", "出生率の上昇", "外国人の増加"], 0),
            ("何が急がれていますか。", ["抜本的な対策", "都市部の開発", "若者の教育", "観光の促進"], 0),
        ],
    ),
    (
        "gurobaru_rinri",
        "Artikel tentang Etika Bisnis Global",
        "グローバル企業には、利益の追求だけでなく、社会的責任を果たす"
        "ことも強く求められるようになった。労働環境や環境保護への配慮が"
        "不十分な企業は、消費者からの信頼を失うリスクを負うことになる。",
        "Perusahaan global kini dituntut kuat bukan hanya mengejar "
        "keuntungan, tapi juga memenuhi tanggung jawab sosial. "
        "Perusahaan yang kurang memperhatikan lingkungan kerja dan "
        "perlindungan lingkungan hidup, akan menanggung risiko "
        "kehilangan kepercayaan dari konsumen.",
        [
            ("グローバル企業に何が求められるようになりましたか。", ["社会的責任を果たすこと", "利益だけを追求すること", "従業員を減らすこと", "広告を増やすこと"], 0),
            ("何への配慮が不十分だとリスクがありますか。", ["労働環境や環境保護", "商品のデザイン", "価格設定", "店舗の場所"], 0),
            ("そのリスクとは何ですか。", ["消費者からの信頼を失うこと", "利益が増えること", "従業員が増えること", "株価が上がること"], 0),
        ],
    ),
    (
        "seikou_teigi",
        "Esai tentang Definisi Kesuksesan",
        "若い頃は、成功とは高い地位やお金を得ることだと信じていた。しかし、"
        "年を重ねるにつれ、日々の小さな幸せを大切にできることこそが、"
        "真の成功なのではないかと考えるようになった。人それぞれ、成功の"
        "形は異なるのだろう。",
        "Saat masih muda, saya percaya bahwa kesuksesan adalah "
        "mendapatkan posisi tinggi atau uang. Namun, seiring "
        "bertambahnya usia, saya mulai berpikir bahwa bisa menghargai "
        "kebahagiaan kecil sehari-hari itulah kesuksesan yang "
        "sebenarnya. Mungkin bentuk kesuksesan berbeda-beda bagi setiap "
        "orang.",
        [
            ("若い頃、筆者は成功をどう考えていましたか。", ["高い地位やお金を得ること", "家族を持つこと", "有名になること", "旅行すること"], 0),
            ("年を重ねて、何が真の成功だと考えるようになりましたか。", ["日々の小さな幸せを大切にできること", "もっとお金を稼ぐこと", "もっと働くこと", "有名になること"], 0),
            ("筆者は成功についてどう思っていますか。", ["人それぞれ形が異なる", "誰にとっても同じだ", "お金だけが基準だ", "意味がない"], 0),
        ],
    ),
    (
        "kikou_kiki_houkoku",
        "Laporan tentang Krisis Iklim",
        "近年の異常気象は、単なる自然現象では片付けられないレベルに達して"
        "いる。専門家の間では、この傾向が今後も続くことはほぼ確実視されて"
        "おり、各国が協調して対策を講じない限り、事態はさらに悪化すると"
        "みられている。",
        "Cuaca ekstrem belakangan ini telah mencapai tingkat yang "
        "tidak bisa lagi dianggap sekadar fenomena alam biasa. Di "
        "kalangan para ahli, tren ini hampir dipastikan akan terus "
        "berlanjut ke depannya, dan diperkirakan situasi akan semakin "
        "memburuk kecuali negara-negara mengambil langkah bersama-sama.",
        [
            ("近年の異常気象はどんなレベルに達していますか。", ["自然現象では片付けられないレベル", "心配のいらないレベル", "昔と同じレベル", "減少しているレベル"], 0),
            ("専門家はこの傾向についてどう見ていますか。", ["今後も続くことがほぼ確実", "すぐに終わる", "分からない", "良くなる"], 0),
            ("事態が悪化しないために何が必要ですか。", ["各国の協調した対策", "一国だけの対策", "何もしないこと", "個人の努力だけ"], 0),
        ],
    ),
    (
        "nenkin_kaikaku",
        "Editorial tentang Reformasi Sistem Pensiun",
        "少子高齢化が進む中、現行の年金制度をこのまま維持することは困難で"
        "あるとの見方が強まっている。将来世代への負担を軽減するためにも、"
        "抜本的な制度改革が避けて通れない課題となっている。",
        "Di tengah kemajuan penurunan angka kelahiran dan penuaan "
        "populasi, pandangan bahwa mempertahankan sistem pensiun saat "
        "ini apa adanya sulit dilakukan semakin menguat. Untuk "
        "mengurangi beban bagi generasi masa depan, reformasi sistem "
        "yang fundamental menjadi tantangan yang tidak bisa dihindari.",
        [
            ("何が進む中、年金制度の維持が困難だとされていますか。", ["少子高齢化", "経済成長", "人口増加", "技術革新"], 0),
            ("何を軽減するために改革が必要ですか。", ["将来世代への負担", "現在の税金", "政府の支出", "企業の利益"], 0),
            ("どんな課題が避けて通れませんか。", ["抜本的な制度改革", "現状維持", "制度の廃止", "何もしないこと"], 0),
        ],
    ),
    (
        "sedai_kachikan",
        "Analisis tentang Pergeseran Nilai Generasi",
        "かつては終身雇用や年功序列が当然視されていたが、若い世代を中心に、"
        "そうした価値観は薄れつつある。個人の成長やワークライフバランスを"
        "重視する傾向が強まっており、企業側の対応も求められている。",
        "Dulu pekerjaan seumur hidup dan sistem senioritas dianggap "
        "wajar, tetapi terutama di kalangan generasi muda, nilai-nilai "
        "seperti itu mulai memudar. Kecenderungan mementingkan "
        "pertumbuhan individu dan keseimbangan kerja-hidup semakin "
        "kuat, dan respons dari pihak perusahaan juga dituntut.",
        [
            ("かつて何が当然視されていましたか。", ["終身雇用や年功序列", "転職", "個人主義", "リモートワーク"], 0),
            ("若い世代はどんな傾向が強まっていますか。", ["個人の成長やワークライフバランスを重視すること", "終身雇用を重視すること", "お金だけを重視すること", "何も重視しないこと"], 0),
            ("企業側に何が求められていますか。", ["対応", "何もしないこと", "給料の削減", "昔のやり方の維持"], 0),
        ],
    ),
    (
        "ai_rinri",
        "Esai tentang Etika Kecerdasan Buatan",
        "AI技術が生活のあらゆる場面に浸透するにつれ、その判断の公平性や"
        "透明性が問われるようになってきた。便利さを享受する一方で、AIに"
        "全てを委ねることのリスクについても、社会全体で議論を深める必要が"
        "あるだろう。",
        "Seiring teknologi AI menyusup ke segala aspek kehidupan, "
        "keadilan dan transparansi keputusannya mulai dipertanyakan. "
        "Sambil menikmati kepraktisannya, masyarakat secara keseluruhan "
        "juga perlu memperdalam diskusi tentang risiko menyerahkan "
        "segalanya pada AI.",
        [
            ("AI技術が浸透するにつれ、何が問われるようになりましたか。", ["判断の公平性や透明性", "値段の安さ", "デザイン", "スピードだけ"], 0),
            ("何について社会全体で議論を深める必要がありますか。", ["AIに全てを委ねることのリスク", "AIの禁止", "AIの値段", "AIの歴史"], 0),
            ("この文章のテーマは何ですか。", ["AIの倫理", "AIの技術的な仕組み", "AIの歴史", "AIの値段"], 0),
        ],
    ),
    (
        "keizai_kakusa",
        "Artikel tentang Ketimpangan Ekonomi",
        "経済成長が続く一方で、富の分配における格差は拡大し続けていると"
        "の指摘がある。一部の富裕層に富が集中する構造は、社会の分断を"
        "招きかねないとして、再分配政策の強化を求める声が高まっている。",
        "Di satu sisi pertumbuhan ekonomi terus berlanjut, tetapi ada "
        "yang menunjukkan bahwa kesenjangan dalam distribusi kekayaan "
        "terus melebar. Struktur di mana kekayaan terkonsentrasi pada "
        "sebagian kelompok kaya, dianggap bisa memicu perpecahan "
        "sosial, sehingga suara yang menuntut penguatan kebijakan "
        "redistribusi semakin menguat.",
        [
            ("経済成長が続く一方で、何が拡大していますか。", ["富の分配における格差", "教育の質", "人口", "平均寿命"], 0),
            ("富が集中する構造は何を招きかねませんか。", ["社会の分断", "経済成長", "平等", "何も起きない"], 0),
            ("何を求める声が高まっていますか。", ["再分配政策の強化", "富の集中", "税金の削減", "何もしないこと"], 0),
        ],
    ),
    (
        "iryou_kakushin",
        "Laporan tentang Inovasi Medis",
        "遺伝子解析技術の進歩により、個人の体質に合わせた治療法を選択"
        "できる時代が近づいている。従来の画一的な治療法と比較して、副"
        "作用を抑えつつ高い効果を期待できる点が注目を集めている。",
        "Dengan kemajuan teknologi analisis genetik, era di mana kita "
        "bisa memilih metode pengobatan yang sesuai dengan konstitusi "
        "tubuh masing-masing individu semakin mendekat. Dibandingkan "
        "metode pengobatan seragam konvensional, hal yang menarik "
        "perhatian adalah bisa menekan efek samping sambil mengharapkan "
        "efektivitas yang tinggi.",
        [
            ("何の進歩により新しい治療の時代が近づいていますか。", ["遺伝子解析技術", "手術技術", "薬の値段", "病院の数"], 0),
            ("新しい治療法は何に合わせて選択できますか。", ["個人の体質", "病院の場所", "患者の年齢だけ", "保険の種類"], 0),
            ("何が注目を集めていますか。", ["副作用を抑えつつ高い効果が期待できる点", "値段の安さ", "治療期間の短さ", "手続きの簡単さ"], 0),
        ],
    ),
    (
        "hodou_jiyuu",
        "Editorial tentang Kebebasan Pers",
        "健全な民主主義社会を維持する上で、報道の自由は不可欠な要素で"
        "ある。しかし、経済的な圧力や政治的な介入により、その独立性が"
        "脅かされているケースも世界各地で報告されている。",
        "Dalam mempertahankan masyarakat demokratis yang sehat, "
        "kebebasan pers adalah elemen yang tak terpisahkan. Namun, "
        "kasus di mana independensinya terancam oleh tekanan ekonomi "
        "atau intervensi politik juga dilaporkan di berbagai belahan "
        "dunia.",
        [
            ("何が民主主義社会の維持に不可欠ですか。", ["報道の自由", "経済成長", "軍事力", "人口増加"], 0),
            ("何が報道の独立性を脅かしていますか。", ["経済的な圧力や政治的な介入", "技術の進歩", "読者の減少", "天候"], 0),
            ("このケースはどこで報告されていますか。", ["世界各地", "日本だけ", "特定の一国", "どこでもない"], 0),
        ],
    ),
    (
        "chiteki_isan",
        "Esai tentang Warisan Intelektual",
        "先人たちが積み重ねてきた知識や技術は、次の世代へと受け継がれる"
        "ことで初めて価値を持ち続ける。それを単に保存するだけでなく、"
        "時代に合わせて発展させていく努力もまた、私たちの世代に課された"
        "使命であろう。",
        "Pengetahuan dan teknologi yang telah dikumpulkan oleh para "
        "pendahulu, baru bisa terus memiliki nilai jika diwariskan ke "
        "generasi berikutnya. Bukan hanya sekadar melestarikannya, "
        "upaya untuk mengembangkannya sesuai zaman juga merupakan misi "
        "yang dibebankan pada generasi kita.",
        [
            ("先人たちの知識や技術はどうすると価値を持ち続けますか。", ["次の世代へ受け継がれること", "隠しておくこと", "忘れられること", "一人が独占すること"], 0),
            ("単に保存するだけでなく、何が必要ですか。", ["時代に合わせて発展させる努力", "完全に変えること", "何もしないこと", "すぐに捨てること"], 0),
            ("これは誰に課された使命だとされていますか。", ["私たちの世代", "先人たちだけ", "政府だけ", "誰も課されていない"], 0),
        ],
    ),
    (
        "kazoku_kouzou_henka",
        "Analisis tentang Perubahan Struktur Keluarga",
        "核家族化や単身世帯の増加により、従来の大家族を前提とした社会"
        "制度が実情に合わなくなってきている。多様化する家族の形に対応"
        "した、柔軟な支援制度の構築が急務となっている。",
        "Dengan meningkatnya keluarga inti dan rumah tangga lajang, "
        "sistem sosial yang mengasumsikan keluarga besar konvensional "
        "mulai tidak sesuai dengan kondisi nyata. Pembangunan sistem "
        "dukungan yang fleksibel, yang merespons bentuk keluarga yang "
        "semakin beragam, menjadi tugas mendesak.",
        [
            ("何の増加により社会制度が実情に合わなくなっていますか。", ["核家族化や単身世帯", "大家族", "出生率", "結婚率"], 0),
            ("従来の社会制度は何を前提としていましたか。", ["大家族", "核家族", "単身世帯", "国際結婚"], 0),
            ("何が急務とされていますか。", ["柔軟な支援制度の構築", "大家族への回帰", "制度の廃止", "何もしないこと"], 0),
        ],
    ),
    (
        "keizai_gaikou",
        "Artikel tentang Diplomasi Ekonomi",
        "資源に乏しい国にとって、他国との経済的な結びつきを強化すること"
        "は、安定した発展のために欠かせない戦略である。貿易協定の締結"
        "は、単なる経済活動にとどまらず、外交関係全体にも大きな影響を"
        "及ぼす。",
        "Bagi negara yang miskin sumber daya, memperkuat hubungan "
        "ekonomi dengan negara lain adalah strategi yang tak "
        "terpisahkan untuk perkembangan yang stabil. Penandatanganan "
        "perjanjian perdagangan tidak berhenti pada sekadar kegiatan "
        "ekonomi, tetapi juga memberikan pengaruh besar pada "
        "keseluruhan hubungan diplomatik.",
        [
            ("資源に乏しい国にとって何が欠かせない戦略ですか。", ["他国との経済的な結びつきの強化", "軍事力の増強", "人口増加", "資源の独占"], 0),
            ("貿易協定の締結は何にとどまりませんか。", ["単なる経済活動", "外交関係", "国際関係", "貿易額"], 0),
            ("貿易協定は何に大きな影響を及ぼしますか。", ["外交関係全体", "天気", "教育制度", "文化だけ"], 0),
        ],
    ),
    (
        "dejitaru_puraibashii",
        "Esai tentang Batas Privasi Digital",
        "スマートフォンの普及により、私たちの行動データは日々収集され"
        "続けている。便利なサービスを受ける代償として、どこまで個人"
        "情報の提供を許容すべきか、その境界線は今なお議論の余地を残して"
        "いる。",
        "Dengan menyebarnya smartphone, data perilaku kita terus "
        "dikumpulkan setiap hari. Sebagai imbalan menerima layanan yang "
        "praktis, sejauh mana kita seharusnya mengizinkan pemberian "
        "informasi pribadi, batasnya masih menyisakan ruang diskusi "
        "hingga kini.",
        [
            ("スマートフォンの普及により何が収集され続けていますか。", ["私たちの行動データ", "お金", "時間", "電池"], 0),
            ("便利なサービスを受ける代償として何が問題になっていますか。", ["個人情報の提供をどこまで許容すべきか", "サービスの値段", "電池の消費", "通信速度"], 0),
            ("この境界線について、現状はどうですか。", ["議論の余地を残している", "完全に決まっている", "誰も気にしていない", "法律で禁止されている"], 0),
        ],
    ),
    (
        "chiiki_saisei",
        "Laporan tentang Revitalisasi Daerah",
        "人口減少に悩む地方自治体の中には、移住者への支援策を充実させる"
        "ことで、地域の活性化に成功している例もある。仕事の紹介だけで"
        "なく、住居や子育て支援など、総合的なサポート体制の整備が鍵と"
        "なっているようだ。",
        "Di antara pemerintah daerah yang khawatir akan penurunan "
        "populasi, ada juga contoh yang berhasil merevitalisasi daerah "
        "dengan memperkaya kebijakan dukungan bagi pendatang. Bukan "
        "hanya pengenalan pekerjaan, tampaknya kunci utamanya adalah "
        "pembangunan sistem dukungan menyeluruh seperti perumahan dan "
        "dukungan pengasuhan anak.",
        [
            ("何に悩む地方自治体がありますか。", ["人口減少", "人口増加", "財政の余裕", "交通の便利さ"], 0),
            ("何によって地域の活性化に成功した例がありますか。", ["移住者への支援策の充実", "税金の増税", "人口の減少", "何もしないこと"], 0),
            ("何が鍵となっているようですか。", ["総合的なサポート体制の整備", "仕事の紹介だけ", "お金の配布だけ", "広告"], 0),
        ],
    ),
    (
        "shokuba_danjo_byoudou",
        "Editorial tentang Kesetaraan Gender di Tempat Kerja",
        "管理職に占める女性の割合は依然として低い水準にとどまっている。"
        "能力に応じた公正な評価が行われる職場環境を整備することが、真の"
        "意味での男女平等の実現につながるはずである。",
        "Proporsi perempuan dalam posisi manajerial masih tetap berada "
        "pada tingkat yang rendah. Membangun lingkungan kerja di mana "
        "penilaian yang adil dilakukan sesuai kemampuan seharusnya "
        "mengarah pada realisasi kesetaraan gender dalam arti yang "
        "sebenarnya.",
        [
            ("管理職に占める女性の割合はどうですか。", ["依然として低い水準", "十分に高い", "男性より高い", "分からない"], 0),
            ("何が真の男女平等の実現につながるはずですか。", ["公正な評価が行われる職場環境", "女性だけを優遇すること", "何もしないこと", "男性を減らすこと"], 0),
            ("この文章のテーマは何ですか。", ["職場の男女平等", "給料の問題", "労働時間", "転職"], 0),
        ],
    ),
    (
        "minimarizumu_tetsugaku",
        "Esai tentang Filosofi Minimalisme",
        "物を減らし、本当に必要なものだけで暮らすミニマリズムという考え"
        "方が注目を集めている。所有物を減らすことで、掃除や管理の手間が"
        "省けるだけでなく、何に価値を置くべきかを見つめ直すきっかけにも"
        "なるという。",
        "Konsep minimalisme, yaitu mengurangi barang dan hidup hanya "
        "dengan yang benar-benar diperlukan, sedang menarik perhatian. "
        "Dikatakan dengan mengurangi barang milik, bukan hanya "
        "menghemat usaha membersihkan dan mengelola, tapi juga menjadi "
        "kesempatan untuk merenungkan kembali apa yang seharusnya "
        "dinilai penting.",
        [
            ("ミニマリズムとはどんな考え方ですか。", ["本当に必要なものだけで暮らすこと", "できるだけ多く物を持つこと", "高級品だけを持つこと", "何も持たないこと"], 0),
            ("所有物を減らすと何が省けますか。", ["掃除や管理の手間", "お金", "時間だけ", "友達"], 0),
            ("ミニマリズムは何を見つめ直すきっかけになりますか。", ["何に価値を置くべきか", "お金の使い方だけ", "仕事の仕方", "人間関係だけ"], 0),
        ],
    ),
    (
        "roudouryoku_fusoku",
        "Artikel tentang Krisis Tenaga Kerja",
        "少子高齢化に伴う労働力不足は、多くの業界で深刻な経営課題となって"
        "いる。外国人労働者の受け入れ拡大や、AI・ロボットの導入による"
        "自動化が、その解決策として注目されている。",
        "Kekurangan tenaga kerja akibat penurunan angka kelahiran dan "
        "penuaan populasi menjadi tantangan manajemen yang serius di "
        "banyak industri. Perluasan penerimaan pekerja asing dan "
        "otomatisasi melalui penerapan AI dan robot sedang menarik "
        "perhatian sebagai solusinya.",
        [
            ("労働力不足は何に伴って起きていますか。", ["少子高齢化", "経済成長", "技術の停滞", "人口増加"], 0),
            ("労働力不足はどんな課題となっていますか。", ["深刻な経営課題", "小さな問題", "個人の問題", "一時的な問題"], 0),
            ("解決策として何が注目されていますか。", ["外国人労働者の受け入れとAI・ロボットの導入", "給料の削減", "労働時間の増加", "何もしないこと"], 0),
        ],
    ),
    (
        "kankou_kougai",
        "Analisis tentang Dampak Pariwisata Berlebihan",
        "観光客の急増により、一部の人気観光地では、交通渋滞やゴミ問題"
        "など、地域住民の生活に支障をきたす事態が発生している。観光に"
        "よる経済効果と、住民の生活の質のバランスをどう取るかが課題と"
        "なっている。",
        "Dengan lonjakan wisatawan, di sebagian tempat wisata populer, "
        "terjadi situasi yang mengganggu kehidupan warga setempat, "
        "seperti kemacetan lalu lintas dan masalah sampah. Bagaimana "
        "menyeimbangkan efek ekonomi dari pariwisata dengan kualitas "
        "hidup warga menjadi tantangan.",
        [
            ("観光客の急増により何が発生していますか。", ["交通渋滞やゴミ問題", "経済発展だけ", "人口増加", "環境改善"], 0),
            ("これは誰の生活に支障をきたしていますか。", ["地域住民", "観光客", "政府", "企業"], 0),
            ("何が課題となっていますか。", ["経済効果と生活の質のバランス", "観光客を増やすこと", "観光地を減らすこと", "何もしないこと"], 0),
        ],
    ),
    (
        "ie_no_imi",
        "Esai tentang Makna Rumah",
        "家とは単に眠る場所ではなく、一日の疲れを癒し、明日への活力を"
        "得るための大切な空間である。忙しい現代社会において、心から"
        "安らげる場所を持つことの意味は、これまで以上に大きくなって"
        "いるように思う。",
        "Rumah bukan sekadar tempat tidur, tetapi ruang penting untuk "
        "menyembuhkan kelelahan sehari-hari dan mendapatkan vitalitas "
        "untuk esok. Dalam masyarakat modern yang sibuk, saya rasa "
        "makna memiliki tempat untuk beristirahat dengan sepenuh hati "
        "menjadi lebih besar dari sebelumnya.",
        [
            ("筆者にとって家とは何ですか。", ["単に眠る場所ではなく大切な空間", "ただの建物", "投資の対象", "見せびらかすためのもの"], 0),
            ("家は何を得るための空間ですか。", ["明日への活力", "お金", "名声", "人脈"], 0),
            ("心から安らげる場所を持つことの意味はどうなっていますか。", ["これまで以上に大きくなっている", "小さくなっている", "変わらない", "なくなっている"], 0),
        ],
    ),
    (
        "sumaato_shiti",
        "Laporan tentang Perkembangan Kota Pintar",
        "IoT技術を活用したスマートシティの構想が、世界各地で進められて"
        "いる。交通、エネルギー、防犯といった都市機能をデータで連携させ"
        "ることで、より効率的で快適な都市生活の実現が目指されている。",
        "Konsep smart city yang memanfaatkan teknologi IoT sedang "
        "dikembangkan di berbagai belahan dunia. Dengan menghubungkan "
        "fungsi kota seperti transportasi, energi, dan keamanan melalui "
        "data, tujuannya adalah mewujudkan kehidupan kota yang lebih "
        "efisien dan nyaman.",
        [
            ("スマートシティは何を活用した構想ですか。", ["IoT技術", "5G技術だけ", "ロボット技術", "宇宙技術"], 0),
            ("何をデータで連携させますか。", ["交通、エネルギー、防犯といった都市機能", "人口統計だけ", "天気予報", "音楽"], 0),
            ("何の実現が目指されていますか。", ["効率的で快適な都市生活", "人口の増加", "観光客の増加", "税収の増加"], 0),
        ],
    ),
    (
        "koutou_kyouiku_kaikaku",
        "Editorial tentang Reformasi Pendidikan Tinggi",
        "急速に変化する社会に対応できる人材を育成するため、大学教育の"
        "あり方が改めて問われている。知識の詰め込みだけでなく、実践的な"
        "問題解決能力を養うカリキュラムへの転換が求められている。",
        "Untuk mendidik sumber daya manusia yang bisa merespons "
        "masyarakat yang berubah dengan cepat, cara pendidikan "
        "universitas kembali dipertanyakan. Dituntut transisi ke "
        "kurikulum yang menumbuhkan kemampuan pemecahan masalah "
        "praktis, bukan hanya menjejalkan pengetahuan.",
        [
            ("何に対応できる人材を育成する必要がありますか。", ["急速に変化する社会", "昔ながらの社会", "特定の業界だけ", "一つの国だけ"], 0),
            ("大学教育に何が求められていますか。", ["実践的な問題解決能力を養うカリキュラム", "知識の詰め込みだけ", "授業料の値上げ", "学生数の削減"], 0),
            ("この文章のテーマは何ですか。", ["大学教育改革", "高校教育", "就職活動", "奨学金"], 0),
        ],
    ),
    (
        "dentou_gendai_baransu",
        "Esai tentang Menyeimbangkan Tradisi dan Modernitas",
        "伝統を守ることと、時代に合わせて変化することは、一見矛盾する"
        "ように思えるが、実際には両立可能なはずである。本質的な価値を"
        "保ちながら、表現方法を現代に合わせて工夫することこそ、真の"
        "継承と言えるのではないだろうか。",
        "Menjaga tradisi dan berubah sesuai zaman sekilas tampak "
        "bertentangan, tetapi sebenarnya seharusnya bisa berjalan "
        "berdampingan. Bukankah justru dengan mempertahankan nilai "
        "esensial sambil menyesuaikan cara ekspresi dengan zaman "
        "modern, itulah yang bisa disebut pewarisan sejati?",
        [
            ("伝統を守ることと変化することは、一見どう見えますか。", ["矛盾するように見える", "全く同じに見える", "無関係に見える", "簡単に見える"], 0),
            ("筆者は実際にはどうだと考えていますか。", ["両立可能なはず", "両立は不可能", "伝統だけが重要", "変化だけが重要"], 0),
            ("何が真の継承と言えるかもしれませんか。", ["本質的な価値を保ちながら表現方法を工夫すること", "何も変えないこと", "全て新しくすること", "伝統を捨てること"], 0),
        ],
    ),
    (
        "shinrai_kiki",
        "Editorial tentang Krisis Kepercayaan Institusi",
        "近年、政府や大企業に対する国民の信頼が低下しているとの調査"
        "結果が相次いでいる。不祥事が発覚するたびに、その傾向は強まる"
        "一方だ。信頼を回復するには、透明性の高い情報公開と、誠実な"
        "対応の積み重ねが不可欠である。",
        "Belakangan ini, hasil survei berturut-turut menunjukkan "
        "kepercayaan masyarakat terhadap pemerintah dan perusahaan "
        "besar menurun. Setiap kali skandal terungkap, tren itu semakin "
        "menguat. Untuk memulihkan kepercayaan, keterbukaan informasi "
        "yang tinggi dan akumulasi respons yang tulus itu tak "
        "terpisahkan.",
        [
            ("何が低下していると調査結果が示していますか。", ["政府や大企業への国民の信頼", "経済成長率", "人口", "平均寿命"], 0),
            ("この傾向はどんな時に強まりますか。", ["不祥事が発覚するたび", "選挙の時", "毎年同じように", "景気が良い時"], 0),
            ("信頼を回復するために何が不可欠ですか。", ["透明性の高い情報公開と誠実な対応", "広告を増やすこと", "値段を下げること", "何もしないこと"], 0),
        ],
    ),
    (
        "dejitaru_shouhi_koudou",
        "Analisis tentang Perubahan Perilaku Konsumen Digital",
        "スマートフォンの普及に伴い、消費者の購買行動は大きく変化した。"
        "店舗で商品を確認し、価格をオンラインで比較してから購入すると"
        "いう行動が一般化している。企業は、この変化に対応したマーケ"
        "ティング戦略の構築を迫られている。",
        "Seiring menyebarnya smartphone, perilaku pembelian konsumen "
        "berubah besar. Perilaku memeriksa barang di toko, lalu "
        "membandingkan harga secara online sebelum membeli menjadi "
        "umum. Perusahaan dituntut untuk membangun strategi pemasaran "
        "yang merespons perubahan ini.",
        [
            ("スマートフォンの普及に伴い何が変化しましたか。", ["消費者の購買行動", "商品の値段", "店舗の数", "従業員の数"], 0),
            ("どんな行動が一般化していますか。", ["店舗で確認しオンラインで比較してから購入すること", "店舗だけで買うこと", "オンラインだけで買うこと", "何も比較しないこと"], 0),
            ("企業は何を迫られていますか。", ["新しいマーケティング戦略の構築", "店舗を減らすこと", "価格を上げること", "何もしないこと"], 0),
        ],
    ),
    (
        "kigyou_shakai_sekinin",
        "Esai tentang Tanggung Jawab Sosial Perusahaan",
        "企業の存在意義は、利益の追求だけにとどまらない時代になった。"
        "環境保護や地域社会への貢献など、社会的責任を果たす姿勢が、"
        "消費者からの支持を得る上でも重要な要素となっている。",
        "Era di mana makna keberadaan perusahaan tidak berhenti hanya "
        "pada mengejar keuntungan telah tiba. Sikap memenuhi tanggung "
        "jawab sosial, seperti perlindungan lingkungan dan kontribusi "
        "pada masyarakat lokal, menjadi elemen penting juga dalam "
        "mendapatkan dukungan dari konsumen.",
        [
            ("企業の存在意義は何にとどまらなくなりましたか。", ["利益の追求だけ", "社会貢献だけ", "環境保護だけ", "何もない"], 0),
            ("社会的責任の例として何が挙げられていますか。", ["環境保護や地域社会への貢献", "広告と宣伝", "給料の値上げ", "新製品の開発"], 0),
            ("社会的責任を果たすことは何を得る上で重要ですか。", ["消費者からの支持", "政府からの補助金", "従業員の給料", "株価だけ"], 0),
        ],
    ),
    (
        "baiotekunorojii_rinri",
        "Artikel tentang Dilema Etika Bioteknologi",
        "遺伝子編集技術の発展は、病気の治療に大きな可能性をもたらす"
        "一方、生命の設計そのものに人間が介入することへの倫理的な懸念"
        "も指摘されている。技術の可能性と倫理的な境界線について、社会"
        "全体での議論が求められている。",
        "Perkembangan teknologi rekayasa genetik membawa kemungkinan "
        "besar bagi pengobatan penyakit, tetapi di sisi lain "
        "kekhawatiran etis tentang intervensi manusia terhadap "
        "rancangan kehidupan itu sendiri juga ditunjukkan. Diperlukan "
        "diskusi seluruh masyarakat tentang kemungkinan teknologi dan "
        "batas etika.",
        [
            ("遺伝子編集技術は何に大きな可能性をもたらしますか。", ["病気の治療", "経済成長", "教育", "スポーツ"], 0),
            ("何への倫理的な懸念が指摘されていますか。", ["生命の設計への人間の介入", "技術の値段", "研究の速さ", "研究者の数"], 0),
            ("何が求められていますか。", ["社会全体での議論", "技術の即座の禁止", "無制限の使用", "何もしないこと"], 0),
        ],
    ),
    (
        "seizougyou_henkaku",
        "Laporan tentang Transformasi Industri Manufaktur",
        "製造業においては、ロボットやAIの導入による自動化が急速に進んで"
        "いる。人手不足の解消につながる一方、従来の職を失う労働者への"
        "支援策も同時に検討する必要があるだろう。",
        "Dalam industri manufaktur, otomatisasi melalui penerapan "
        "robot dan AI berkembang pesat. Di satu sisi mengarah pada "
        "penyelesaian kekurangan tenaga kerja, tetapi kebijakan "
        "dukungan bagi pekerja yang kehilangan pekerjaan konvensional "
        "juga perlu dipertimbangkan secara bersamaan.",
        [
            ("製造業で何が急速に進んでいますか。", ["ロボットやAIの導入による自動化", "人手不足", "生産量の減少", "輸出の減少"], 0),
            ("この自動化は何につながりますか。", ["人手不足の解消", "人手不足の悪化", "何も変わらないこと", "生産の停止"], 0),
            ("同時に何を検討する必要がありますか。", ["職を失う労働者への支援策", "給料の削減", "会社の閉鎖", "何もしないこと"], 0),
        ],
    ),
    (
        "yoron_bunretsu",
        "Editorial tentang Polarisasi Opini Publik",
        "SNSの普及により、自分と似た意見ばかりに触れる環境が生まれ"
        "やすくなった。その結果、異なる意見への理解が乏しくなり、社会の"
        "分断が深まっているとの指摘がある。多様な視点に触れる努力が、"
        "これまで以上に必要とされている。",
        "Dengan menyebarnya media sosial, lingkungan yang mudah hanya "
        "bersentuhan dengan pendapat yang mirip dengan diri sendiri "
        "jadi mudah terbentuk. Akibatnya, ada yang menunjukkan bahwa "
        "pemahaman terhadap pendapat yang berbeda menjadi kurang, dan "
        "perpecahan sosial semakin dalam. Upaya untuk bersentuhan "
        "dengan berbagai sudut pandang dibutuhkan lebih dari "
        "sebelumnya.",
        [
            ("SNSの普及により何が生まれやすくなりましたか。", ["自分と似た意見ばかりに触れる環境", "多様な意見に触れる環境", "情報が少ない環境", "何も変わらない環境"], 0),
            ("その結果、何が深まっているとの指摘がありますか。", ["社会の分断", "社会の統一", "経済成長", "教育の質"], 0),
            ("何がこれまで以上に必要とされていますか。", ["多様な視点に触れる努力", "SNSをやめること", "意見を言わないこと", "何もしないこと"], 0),
        ],
    ),
    (
        "gurobaruka_tekiou",
        "Esai tentang Adaptasi Terhadap Globalisasi",
        "グローバル化が進む中、異文化を理解し、柔軟に対応する力がます"
        "ます求められている。自国の文化に誇りを持ちつつも、他者の価値"
        "観を尊重する姿勢こそが、真の国際人の条件なのではないだろうか。",
        "Di tengah kemajuan globalisasi, kemampuan memahami budaya "
        "asing dan merespons secara fleksibel semakin dituntut. "
        "Bukankah sikap menghormati nilai-nilai orang lain sambil "
        "tetap bangga dengan budaya negeri sendiri adalah syarat orang "
        "internasional sejati?",
        [
            ("グローバル化が進む中、何が求められていますか。", ["異文化を理解し柔軟に対応する力", "自国の文化を捨てること", "他国を批判する力", "何もしないこと"], 0),
            ("筆者は何を持ちつつ他者を尊重すべきだと考えていますか。", ["自国の文化への誇り", "お金", "権力", "名声"], 0),
            ("何が真の国際人の条件かもしれませんか。", ["他者の価値観を尊重する姿勢", "外国語が話せること", "海外に住んだ経験", "高い学歴"], 0),
        ],
    ),
    (
        "saisei_enerugii_mirai",
        "Artikel tentang Masa Depan Energi Terbarukan",
        "再生可能エネルギーのコストは技術革新により年々低下しており、"
        "化石燃料との価格差が縮まりつつある。今後、蓄電技術がさらに"
        "進歩すれば、エネルギー供給における再生可能エネルギーの割合は"
        "飛躍的に高まるとみられている。",
        "Biaya energi terbarukan menurun setiap tahun berkat inovasi "
        "teknologi, dan selisih harga dengan bahan bakar fosil semakin "
        "menyempit. Ke depannya, jika teknologi penyimpanan listrik "
        "semakin maju, diperkirakan proporsi energi terbarukan dalam "
        "pasokan energi akan meningkat drastis.",
        [
            ("再生可能エネルギーのコストはどうなっていますか。", ["年々低下している", "年々上昇している", "変わらない", "分からない"], 0),
            ("化石燃料との価格差はどうなりつつありますか。", ["縮まりつつある", "広がりつつある", "変わらない", "なくなった"], 0),
            ("何がさらに進歩すれば、再生可能エネルギーの割合が高まるとみられていますか。", ["蓄電技術", "化石燃料の技術", "輸送技術", "農業技術"], 0),
        ],
    ),
    (
        "career_sedai_henka",
        "Analisis tentang Perubahan Preferensi Karier Generasi Muda",
        "若い世代の間では、大企業への就職よりも、自分の価値観に合った"
        "働き方を重視する傾向が強まっている。安定よりもやりがいを求める"
        "姿勢は、従来の就職活動のあり方にも変化をもたらしつつある。",
        "Di kalangan generasi muda, kecenderungan mementingkan cara "
        "kerja yang sesuai dengan nilai diri sendiri, dibandingkan "
        "bekerja di perusahaan besar, semakin menguat. Sikap mencari "
        "makna dibandingkan stabilitas mulai membawa perubahan pada "
        "cara kegiatan mencari kerja konvensional.",
        [
            ("若い世代は何を重視する傾向が強まっていますか。", ["自分の価値観に合った働き方", "大企業への就職だけ", "給料の高さだけ", "安定だけ"], 0),
            ("若い世代は安定より何を求めていますか。", ["やりがい", "お金", "地位", "名声"], 0),
            ("この傾向は何にもたらしつつありますか。", ["従来の就職活動のあり方の変化", "就職活動の終わり", "大企業の消滅", "何も変わらないこと"], 0),
        ],
    ),
    (
        "hataraku_imi_gendai",
        "Esai tentang Makna Kerja dalam Kehidupan Modern",
        "働くことの意味は、単に生活費を稼ぐためだけではなくなりつつ"
        "ある。自己実現や社会とのつながりを求めて働く人が増える中、"
        "仕事に何を求めるかという問いは、より個人的で多様なものになって"
        "きている。",
        "Makna bekerja mulai bukan lagi sekadar untuk mencari nafkah. "
        "Di tengah semakin banyaknya orang yang bekerja untuk mencari "
        "aktualisasi diri dan koneksi dengan masyarakat, pertanyaan "
        "tentang apa yang dicari dalam pekerjaan menjadi lebih pribadi "
        "dan beragam.",
        [
            ("働くことの意味は何だけではなくなりつつありますか。", ["生活費を稼ぐこと", "自己実現", "社会とのつながり", "やりがい"], 0),
            ("何を求めて働く人が増えていますか。", ["自己実現や社会とのつながり", "お金だけ", "地位だけ", "名声だけ"], 0),
            ("仕事に何を求めるかという問いはどうなってきていますか。", ["より個人的で多様なもの", "より画一的なもの", "単純なもの", "意味のないもの"], 0),
        ],
    ),
    (
        "toshi_juutaku_kiki",
        "Editorial tentang Krisis Perumahan Perkotaan",
        "大都市における住宅価格の高騰が、若い世代の生活を圧迫している。"
        "賃金の伸びが物価上昇に追いつかない中、住宅取得はますます遠い"
        "夢になりつつある。政府による住宅政策の抜本的な見直しが急務で"
        "あろう。",
        "Lonjakan harga perumahan di kota besar menekan kehidupan "
        "generasi muda. Di tengah pertumbuhan upah yang tidak mengejar "
        "kenaikan harga barang, kepemilikan rumah semakin menjadi mimpi "
        "yang jauh. Peninjauan ulang kebijakan perumahan pemerintah "
        "secara fundamental adalah tugas mendesak.",
        [
            ("何が若い世代の生活を圧迫していますか。", ["大都市における住宅価格の高騰", "教育費", "医療費", "食費"], 0),
            ("賃金の伸びはどうですか。", ["物価上昇に追いついていない", "物価上昇を上回っている", "変わらない", "分からない"], 0),
            ("何が急務とされていますか。", ["住宅政策の抜本的な見直し", "賃金の削減", "物価の上昇", "何もしないこと"], 0),
        ],
    ),
    (
        "roudouryoku_idou_henka",
        "Analisis tentang Perubahan Pola Migrasi Tenaga Kerja",
        "国境を越えた労働力の移動は、経済のグローバル化とともに活発化"
        "している。優秀な人材を求める国々の間で、獲得競争が激化する"
        "一方、送り出す国では頭脳流出という課題も浮上している。",
        "Perpindahan tenaga kerja lintas batas semakin aktif seiring "
        "globalisasi ekonomi. Di antara negara-negara yang mencari "
        "talenta unggul, persaingan perebutan semakin sengit, sementara "
        "di negara pengirim, tantangan brain drain juga muncul.",
        [
            ("何が経済のグローバル化とともに活発化していますか。", ["国境を越えた労働力の移動", "貿易額", "人口増加", "観光"], 0),
            ("国々の間で何が激化していますか。", ["優秀な人材の獲得競争", "貿易戦争", "軍事競争", "価格競争"], 0),
            ("送り出す国ではどんな課題が浮上していますか。", ["頭脳流出", "人口過多", "失業率の低下", "経済成長"], 0),
        ],
    ),
    (
        "iryou_gijutsu_dilenma",
        "Esai tentang Dilema Kemajuan Teknologi Medis",
        "医療技術の進歩により、以前は治療できなかった病気も治せるように"
        "なった。しかし、高度な医療にかかる費用は高額であり、誰もが"
        "平等にその恩恵を受けられるわけではないという現実もある。技術"
        "の進歩と公平性の両立が問われている。",
        "Berkat kemajuan teknologi medis, penyakit yang dulu tidak "
        "bisa diobati kini bisa disembuhkan. Namun, ada juga realita "
        "bahwa biaya pengobatan canggih itu mahal, dan tidak semua "
        "orang bisa mendapat manfaatnya secara setara. Keseimbangan "
        "antara kemajuan teknologi dan keadilan dipertanyakan.",
        [
            ("医療技術の進歩により何が可能になりましたか。", ["以前は治療できなかった病気を治せること", "病気がなくなること", "医療費が無料になること", "医者が不要になること"], 0),
            ("高度な医療にかかる費用はどうですか。", ["高額である", "無料である", "安い", "分からない"], 0),
            ("何が問われていますか。", ["技術の進歩と公平性の両立", "技術の停止", "医療の完全な無料化", "何もしないこと"], 0),
        ],
    ),
    (
        "dejitaru_tsuuka_kisei",
        "Artikel tentang Tantangan Regulasi Mata Uang Digital",
        "暗号資産の取引が広がる中、各国政府は規制のあり方に頭を悩ませて"
        "いる。イノベーションを阻害せずに、投資家保護や金融システムの"
        "安定をどう図るか。バランスの取れた規制の構築が世界的な課題と"
        "なっている。",
        "Di tengah meluasnya transaksi aset kripto, pemerintah "
        "berbagai negara pusing memikirkan bentuk regulasi. Bagaimana "
        "mengupayakan perlindungan investor dan stabilitas sistem "
        "keuangan tanpa menghambat inovasi? Pembangunan regulasi yang "
        "seimbang menjadi tantangan global.",
        [
            ("何が広がる中、政府は頭を悩ませていますか。", ["暗号資産の取引", "株式取引", "不動産取引", "外国為替取引"], 0),
            ("政府は何をどう図るか悩んでいますか。", ["投資家保護や金融システムの安定", "経済成長だけ", "税収の増加だけ", "何もしないこと"], 0),
            ("何が世界的な課題となっていますか。", ["バランスの取れた規制の構築", "暗号資産の禁止", "無制限の取引の許可", "何もしないこと"], 0),
        ],
    ),
    (
        "wakamono_toushi_koudou",
        "Laporan tentang Perubahan Perilaku Investasi Generasi Muda",
        "従来、投資は一部の富裕層のものというイメージが強かったが、"
        "スマートフォンアプリの普及により、若い世代が少額から投資を"
        "始めるケースが急増している。金融リテラシー教育の重要性も、"
        "これに伴い高まっている。",
        "Sebelumnya, investasi memiliki citra kuat sebagai milik "
        "sebagian kelompok kaya, tetapi dengan menyebarnya aplikasi "
        "smartphone, kasus generasi muda mulai berinvestasi dari jumlah "
        "kecil meningkat pesat. Seiring dengan ini, pentingnya "
        "pendidikan literasi keuangan juga meningkat.",
        [
            ("従来、投資はどんなイメージが強かったですか。", ["一部の富裕層のもの", "誰でもできるもの", "危険なだけのもの", "意味のないもの"], 0),
            ("何の普及により若い世代の投資が増えていますか。", ["スマートフォンアプリ", "銀行の窓口", "新聞広告", "テレビCM"], 0),
            ("これに伴い何の重要性が高まっていますか。", ["金融リテラシー教育", "貯金の重要性だけ", "消費の重要性", "何も重要ではないこと"], 0),
        ],
    ),
    (
        "iryou_seido_futan",
        "Editorial tentang Beban Sistem Kesehatan Masyarakat",
        "高齢化の進行により、医療保険制度が支える給付と負担のバランスが"
        "崩れつつある。現役世代への負担集中を避けつつ、持続可能な制度を"
        "いかに構築するかが、喫緊の政策課題となっている。",
        "Dengan kemajuan penuaan populasi, keseimbangan antara "
        "tunjangan dan beban yang ditopang sistem asuransi kesehatan "
        "mulai runtuh. Bagaimana membangun sistem yang berkelanjutan "
        "sambil menghindari konsentrasi beban pada generasi aktif "
        "kerja, menjadi tantangan kebijakan yang mendesak.",
        [
            ("高齢化の進行により何が崩れつつありますか。", ["給付と負担のバランス", "人口", "経済成長", "教育制度"], 0),
            ("何への負担集中を避ける必要がありますか。", ["現役世代", "高齢者", "子供", "外国人"], 0),
            ("何が喫緊の政策課題となっていますか。", ["持続可能な制度の構築", "医療費の完全無料化", "保険制度の廃止", "何もしないこと"], 0),
        ],
    ),
    (
        "sedaikan_sekinin",
        "Esai tentang Tanggung Jawab Antar Generasi",
        "現在の世代が享受している豊かさは、将来世代からの前借りである"
        "側面も否定できない。環境問題や財政赤字など、次世代に先送りして"
        "いる課題に、今を生きる私たちはどう向き合うべきなのだろうか。",
        "Tidak bisa dipungkiri bahwa kemakmuran yang dinikmati generasi "
        "saat ini juga memiliki sisi sebagai pinjaman dari generasi "
        "masa depan. Bagaimana seharusnya kita yang hidup sekarang "
        "menghadapi tantangan yang ditunda ke generasi berikutnya, "
        "seperti masalah lingkungan dan defisit fiskal?",
        [
            ("現在の世代が享受している豊かさは、何の側面がありますか。", ["将来世代からの前借り", "完全に自分たちだけのもの", "何の問題もないもの", "過去世代への恩返し"], 0),
            ("次世代に先送りしている課題の例として何が挙げられていますか。", ["環境問題や財政赤字", "教育問題だけ", "交通問題", "娯楽の不足"], 0),
            ("筆者は何を問いかけていますか。", ["これらの課題にどう向き合うべきか", "誰が悪いか", "いつ解決するか", "なぜ問題になったか"], 0),
        ],
    ),
    (
        "jidouka_koyou_eikyou",
        "Artikel tentang Dampak Otomatisasi terhadap Pasar Kerja",
        "AIやロボットによる自動化は、定型的な業務を中心に雇用を代替し"
        "つつある。一方で、新しい技術に対応できる人材への需要は高まって"
        "おり、労働市場の二極化が進んでいるとの指摘もある。",
        "Otomatisasi oleh AI dan robot menggantikan lapangan kerja, "
        "terutama pekerjaan rutin. Di sisi lain, permintaan terhadap "
        "sumber daya manusia yang bisa merespons teknologi baru "
        "meningkat, dan ada juga yang menunjukkan bahwa polarisasi "
        "pasar tenaga kerja sedang berlangsung.",
        [
            ("AIやロボットによる自動化は何を代替しつつありますか。", ["定型的な業務を中心とした雇用", "全ての仕事", "経営者の仕事だけ", "何も代替していない"], 0),
            ("何への需要が高まっていますか。", ["新しい技術に対応できる人材", "単純労働者", "経営者だけ", "ロボットだけ"], 0),
            ("何が進んでいるとの指摘がありますか。", ["労働市場の二極化", "労働市場の均一化", "失業率の低下", "賃金の平等化"], 0),
        ],
    ),
    (
        "kagaku_shinrai_kiki",
        "Analisis tentang Krisis Kepercayaan pada Sains",
        "インターネット上に誤った情報が氾濫する中、科学的根拠に基づいた"
        "知見への不信感を抱く人々も増えている。専門家は、分かりやすい"
        "言葉で情報発信することの重要性を、改めて認識する必要があるだろ"
        "う。",
        "Di tengah membanjirnya informasi yang salah di internet, "
        "semakin banyak juga orang yang menaruh ketidakpercayaan "
        "terhadap pengetahuan berbasis bukti ilmiah. Para ahli perlu "
        "kembali menyadari pentingnya menyebarkan informasi dengan "
        "bahasa yang mudah dipahami.",
        [
            ("インターネット上に何が氾濫していますか。", ["誤った情報", "正確な情報だけ", "科学的な情報だけ", "何もない"], 0),
            ("何を抱く人々が増えていますか。", ["科学的根拠に基づいた知見への不信感", "科学への信頼", "政府への信頼", "メディアへの信頼"], 0),
            ("専門家は何の重要性を認識する必要がありますか。", ["分かりやすい言葉で情報発信すること", "難しい言葉を使うこと", "情報を隠すこと", "何もしないこと"], 0),
        ],
    ),
    (
        "komyuniti_dejitaru_jidai",
        "Esai tentang Definisi Komunitas di Era Digital",
        "かつて地縁や血縁によって形成されていたコミュニティは、インター"
        "ネットの発達により、共通の興味関心を軸にしたものへと変化しつつ"
        "ある。物理的な距離を超えたつながりが、現代人の孤独感を和らげる"
        "一助となっているのかもしれない。",
        "Komunitas yang dulu terbentuk berdasarkan hubungan geografis "
        "atau darah, dengan perkembangan internet, mulai berubah "
        "menjadi yang berbasis pada minat bersama. Koneksi yang "
        "melampaui jarak fisik mungkin menjadi salah satu bantuan "
        "meredakan rasa kesepian manusia modern.",
        [
            ("かつてコミュニティは何によって形成されていましたか。", ["地縁や血縁", "インターネット", "共通の趣味だけ", "会社"], 0),
            ("インターネットの発達により、コミュニティはどう変化していますか。", ["共通の興味関心を軸にしたものへ", "完全になくなりつつある", "変わらない", "より地縁に基づくものへ"], 0),
            ("何が現代人の孤独感を和らげる一助になっているかもしれませんか。", ["物理的な距離を超えたつながり", "お金", "仕事", "何もない"], 0),
        ],
    ),
    (
        "kagaku_kenkyuu_rinri_essay",
        "Esai tentang Etika Penelitian Ilmiah",
        "科学研究が急速に進歩しているにもかかわらず、その倫理的な"
        "枠組みの整備は後手に回っているのが現状だ。研究者個人の良心"
        "に委ねるだけでなく、社会全体で議論を重ね、合意を形成してい"
        "く必要があるだろう。",
        "Meskipun penelitian ilmiah berkembang pesat, kenyataannya "
        "penataan kerangka etikanya tertinggal. Tidak cukup hanya "
        "diserahkan pada hati nurani masing-masing peneliti, perlu "
        "ada diskusi berulang di seluruh masyarakat untuk membentuk "
        "kesepakatan.",
        [
            ("科学研究についてどんな現状が指摘されていますか。", ["進歩に対して倫理的枠組みの整備が遅れていること", "研究が全く進んでいないこと", "倫理が完璧に整っていること", "誰も研究していないこと"], 0),
            ("何に委ねるだけでは不十分だと述べられていますか。", ["研究者個人の良心", "政府の規制だけ", "お金だけ", "時間だけ"], 0),
            ("筆者は何が必要だと考えていますか。", ["社会全体での議論と合意形成", "研究の即時停止", "個人の自由な判断だけ", "何もしないこと"], 0),
        ],
    ),
    (
        "zeisei_kaikaku_kiji",
        "Artikel tentang Reformasi Sistem Pajak",
        "税制改革をきっかけに、所得格差の是正が期待されている。しか"
        "し、増税は国民生活への負担を伴うため、慎重な制度設計が求め"
        "られる。公平性と経済活力の両立をいかに図るかが、今後の課題"
        "であろう。",
        "Dengan reformasi pajak sebagai pemicu, diharapkan ada koreksi "
        "kesenjangan pendapatan. Namun, karena kenaikan pajak membawa "
        "beban bagi kehidupan rakyat, diperlukan perancangan sistem "
        "yang hati-hati. Bagaimana mengupayakan keseimbangan antara "
        "keadilan dan vitalitas ekonomi akan menjadi tantangan ke "
        "depan.",
        [
            ("何をきっかけに所得格差の是正が期待されていますか。", ["税制改革", "経済成長", "人口増加", "技術革新"], 0),
            ("増税は何を伴いますか。", ["国民生活への負担", "経済の急成長", "失業率の低下", "物価の下落"], 0),
            ("今後の課題として何が挙げられていますか。", ["公平性と経済活力の両立", "増税の即時中止", "減税だけの実施", "何もしないこと"], 0),
        ],
    ),
    (
        "sns_minshushugi_eikyou_bunseki",
        "Analisis tentang Dampak Media Sosial pada Demokrasi",
        "SNSの普及により、市民が政治的意見を発信しやすくなったにも"
        "かかわらず、分断を助長する側面も指摘されている。アルゴリズ"
        "ムが似た意見ばかりを表示することで、異なる立場への理解が"
        "失われつつあるのではないかという懸念がある。",
        "Meskipun dengan meluasnya media sosial, warga menjadi lebih "
        "mudah menyampaikan pendapat politik, sisi yang mendorong "
        "perpecahan juga ditunjukkan. Ada kekhawatiran bahwa dengan "
        "algoritma yang hanya menampilkan pendapat serupa, pemahaman "
        "terhadap posisi yang berbeda mungkin mulai hilang.",
        [
            ("SNSの普及により市民は何がしやすくなりましたか。", ["政治的意見の発信", "投票", "選挙運動だけ", "会議への参加"], 0),
            ("一方で何が指摘されていますか。", ["分断を助長する側面", "経済成長への貢献", "教育の向上", "犯罪の減少"], 0),
            ("どんな懸念が示されていますか。", ["異なる立場への理解が失われつつあること", "SNSがなくなること", "誰も政治に興味がないこと", "選挙がなくなること"], 0),
        ],
    ),
    (
        "energy_shouhi_henka_report",
        "Laporan tentang Perubahan Pola Konsumsi Energi",
        "再生可能エネルギーの導入が進んでいるにもかかわらず、全体の"
        "エネルギー消費量は依然として増加傾向にある。省エネ技術の"
        "普及をきっかけに、消費構造そのものを見直す動きが今後さらに"
        "求められるだろう。",
        "Meskipun pengenalan energi terbarukan berkembang, jumlah "
        "konsumsi energi secara keseluruhan masih cenderung "
        "meningkat. Dengan meluasnya teknologi hemat energi sebagai "
        "pemicu, gerakan untuk meninjau ulang struktur konsumsi itu "
        "sendiri akan semakin dibutuhkan ke depannya.",
        [
            ("再生可能エネルギーの導入が進んでいるのに、何は増加傾向にありますか。", ["全体のエネルギー消費量", "再生可能エネルギーの割合だけ", "人口", "失業率"], 0),
            ("何をきっかけに消費構造を見直す動きが求められていますか。", ["省エネ技術の普及", "エネルギー価格の下落", "人口減少", "戦争"], 0),
            ("今後さらに求められることは何ですか。", ["消費構造そのものを見直す動き", "エネルギー消費の完全停止", "再生可能エネルギーの廃止", "何もしないこと"], 0),
        ],
    ),
    (
        "seiji_fushin_kiki_editorial",
        "Editorial tentang Krisis Kepercayaan Politik",
        "度重なる不祥事にもかかわらず、抜本的な改革が進まない現状に、"
        "国民の政治への不信感は募る一方である。透明性の確保と説明"
        "責任の徹底こそが、信頼回復への第一歩となるのではないだろう"
        "か。",
        "Meskipun ada skandal berulang kali, dalam kondisi reformasi "
        "mendasar tidak berjalan, rasa ketidakpercayaan rakyat "
        "terhadap politik terus memuncak. Bukankah kepastian "
        "transparansi dan penegakan akuntabilitas justru menjadi "
        "langkah pertama menuju pemulihan kepercayaan?",
        [
            ("何にもかかわらず抜本的な改革が進みませんか。", ["度重なる不祥事", "国民の支持", "経済成長", "国際的な圧力"], 0),
            ("国民の政治への不信感はどうなっていますか。", ["募る一方", "減っている", "変わらない", "なくなった"], 0),
            ("筆者は何が信頼回復への第一歩だと考えていますか。", ["透明性の確保と説明責任の徹底", "選挙の廃止", "政治家の増員", "何もしないこと"], 0),
        ],
    ),
    (
        "hyougen_jiyuu_genkai_essay",
        "Esai tentang Batas Kebebasan Berekspresi",
        "表現の自由は民主主義社会の根幹をなす権利であるにもかかわら"
        "ず、他者への誹謗中傷を助長する場合には、一定の制約もやむを"
        "得ないという議論がある。自由と責任のバランスをどう取るかは、"
        "簡単には答えの出ない問題だ。",
        "Meskipun kebebasan berekspresi adalah hak yang menjadi dasar "
        "masyarakat demokratis, ada juga diskusi bahwa jika mendorong "
        "fitnah terhadap orang lain, pembatasan tertentu juga tidak "
        "bisa dihindari. Bagaimana menyeimbangkan kebebasan dan "
        "tanggung jawab adalah masalah yang tidak mudah dijawab.",
        [
            ("表現の自由はどんな権利ですか。", ["民主主義社会の根幹をなす権利", "無制限の権利", "不要な権利", "新しい権利"], 0),
            ("どんな場合に制約もやむを得ないという議論がありますか。", ["他者への誹謗中傷を助長する場合", "政治を批判する場合", "芸術を表現する場合", "意見を言う場合全て"], 0),
            ("筆者はどんな問題だと述べていますか。", ["簡単には答えの出ない問題", "すぐに解決できる問題", "存在しない問題", "誰も気にしない問題"], 0),
        ],
    ),
    (
        "imin_tougou_kadai_kiji",
        "Artikel tentang Tantangan Integrasi Imigran",
        "労働力不足をきっかけに移民の受け入れが拡大しているにもかか"
        "わらず、言語や文化の壁により、社会への統合が十分に進んでい"
        "ない地域も少なくない。行政による支援体制の充実が急がれる。",
        "Meskipun penerimaan imigran meluas dengan kekurangan tenaga "
        "kerja sebagai pemicu, tidak sedikit daerah di mana integrasi "
        "ke masyarakat belum cukup berjalan karena hambatan bahasa "
        "dan budaya. Peningkatan sistem dukungan oleh pemerintah "
        "sangat mendesak.",
        [
            ("何をきっかけに移民の受け入れが拡大していますか。", ["労働力不足", "人口の増加", "経済の停滞", "戦争"], 0),
            ("何が社会への統合を妨げていますか。", ["言語や文化の壁", "経済的な豊かさ", "教育制度", "気候"], 0),
            ("何が急がれると述べられていますか。", ["行政による支援体制の充実", "移民の受け入れ停止", "言語教育の廃止", "何もしないこと"], 0),
        ],
    ),
    (
        "sedai_kachikan_henka_z",
        "Analisis tentang Perubahan Nilai Kerja Generasi Z",
        "Z世代は、給与の高さよりも仕事のやりがいや働きやすさを重視す"
        "る傾向が強いと言われる。終身雇用が当たり前だった時代とは"
        "異なり、転職をキャリアアップの手段として捉える価値観が広が"
        "りつつある。",
        "Generasi Z dikatakan memiliki kecenderungan kuat untuk lebih "
        "mementingkan makna dan kemudahan bekerja daripada tingginya "
        "gaji. Berbeda dari zaman ketika kerja seumur hidup adalah "
        "hal biasa, nilai yang memandang pindah kerja sebagai sarana "
        "pengembangan karier mulai meluas.",
        [
            ("Z世代は何を重視する傾向が強いですか。", ["仕事のやりがいや働きやすさ", "給与の高さだけ", "会社の規模だけ", "地位だけ"], 0),
            ("終身雇用が当たり前だった時代と比べてどう違いますか。", ["転職をキャリアアップの手段として捉える", "一つの会社に一生いる", "仕事をしない", "給料だけを重視する"], 0),
            ("どんな価値観が広がりつつありますか。", ["転職をキャリアアップの手段として捉える価値観", "転職を恥だと考える価値観", "仕事を軽視する価値観", "何も変わらない価値観"], 0),
        ],
    ),
    (
        "online_kyouiku_kakushin_report",
        "Laporan tentang Inovasi dalam Pendidikan Daring",
        "パンデミックをきっかけにオンライン教育が急速に普及したにも"
        "かかわらず、地域や家庭間のデジタル格差が新たな課題として"
        "浮上している。誰もが平等に学べる環境をどう整えるかが、今後"
        "の教育政策の焦点となるだろう。",
        "Meskipun pendidikan daring menyebar pesat dengan pandemi "
        "sebagai pemicu, kesenjangan digital antar daerah dan "
        "keluarga muncul sebagai tantangan baru. Bagaimana "
        "menciptakan lingkungan di mana semua orang bisa belajar "
        "secara setara akan menjadi fokus kebijakan pendidikan ke "
        "depan.",
        [
            ("何をきっかけにオンライン教育が急速に普及しましたか。", ["パンデミック", "技術革新だけ", "政府の命令だけ", "学校の増加"], 0),
            ("新たな課題として何が浮上していますか。", ["地域や家庭間のデジタル格差", "教師の不足だけ", "予算の不足だけ", "生徒の減少"], 0),
            ("今後の教育政策の焦点は何になるでしょうか。", ["誰もが平等に学べる環境の整備", "オンライン教育の廃止", "対面授業だけへの回帰", "何もしないこと"], 0),
        ],
    ),
    (
        "puraibashii_anzen_dilenma_essay",
        "Esai tentang Dilema Privasi dan Keamanan",
        "監視カメラの設置が犯罪抑止に一定の効果を上げているにもかか"
        "わらず、個人のプライバシーが侵害されているという批判も根強"
        "い。安全と自由という、時に相反する価値のバランスをどう取る"
        "かが問われている。",
        "Meskipun pemasangan kamera pengawas menunjukkan efek "
        "tertentu dalam mencegah kejahatan, kritik bahwa privasi "
        "pribadi dilanggar juga kuat bertahan. Dipertanyakan "
        "bagaimana menyeimbangkan nilai keamanan dan kebebasan yang "
        "terkadang saling bertentangan.",
        [
            ("監視カメラの設置は何に効果を上げていますか。", ["犯罪抑止", "経済成長", "教育の向上", "人口増加"], 0),
            ("どんな批判が根強くありますか。", ["個人のプライバシーが侵害されているという批判", "カメラが足りないという批判", "犯罪が増えたという批判", "効果がないという批判"], 0),
            ("何が問われていますか。", ["安全と自由のバランス", "カメラの価格", "犯罪者の権利だけ", "警察の人数"], 0),
        ],
    ),
]

N1_ENTRIES = [
    (
        "soushitsu_essei",
        "Esai tentang Kehilangan",
        "母を亡くしてから一年が経った。悲しみは時とともに薄れるものだと"
        "言われていたが、ふとした瞬間に涙があふれ、いまだに母の不在を"
        "実感せずにはいられない。しかし、母が遺してくれた言葉の数々は、"
        "今も私の心を支え続けている。喪失とは、決して忘れることでは"
        "なく、共に生き続けることなのかもしれない。",
        "Sudah setahun sejak ibu saya meninggal. Dikatakan bahwa "
        "kesedihan akan memudar seiring waktu, tapi di saat-saat tak "
        "terduga air mata mengalir, dan hingga kini saya tak bisa tidak "
        "merasakan ketiadaan ibu. Namun, kata-kata yang ditinggalkan ibu "
        "masih terus menopang hati saya hingga sekarang. Kehilangan "
        "mungkin bukan berarti melupakan, melainkan terus hidup bersama.",
        [
            ("母を亡くしてからどのくらい経ちましたか。", ["一年", "半年", "三年", "一か月"], 0),
            ("筆者は今も何を実感せずにはいられませんか。", ["母の不在", "母の元気な姿", "母の若さ", "母の声"], 0),
            ("筆者にとって喪失とはどういうことかもしれませんか。", ["共に生き続けること", "完全に忘れること", "悲しみ続けること", "何も感じないこと"], 0),
        ],
    ),
    (
        "jikan_no_mujou",
        "Esai tentang Ketidakkekalan Waktu",
        "桜の花が散る様子を見るたびに、時の流れの儚さを感じずにはいら"
        "れない。美しいものほど、その瞬間は短い。だからこそ、私たちは今"
        "この瞬間を大切にすべく、日々を丁寧に生きる必要があるのでは"
        "ないだろうか。永遠に続くものなど、この世には存在しないの"
        "だから。",
        "Setiap kali melihat bunga sakura berguguran, saya tak bisa "
        "tidak merasakan kefanaan aliran waktu. Semakin indah sesuatu, "
        "semakin singkat momennya. Justru karena itulah, bukankah kita "
        "perlu menjalani hari-hari dengan cermat demi menghargai momen "
        "ini? Karena tidak ada yang abadi selamanya di dunia ini.",
        [
            ("筆者は桜が散る様子を見るたびに何を感じますか。", ["時の流れの儚さ", "喜び", "怒り", "退屈さ"], 0),
            ("美しいものについて、筆者はどう述べていますか。", ["その瞬間は短い", "ずっと続く", "誰も気づかない", "価値がない"], 0),
            ("筆者は私たちが何をすべきだと考えていますか。", ["今この瞬間を大切にすること", "未来だけを考えること", "過去を忘れること", "何もしないこと"], 0),
        ],
    ),
    (
        "shakai_hihyou",
        "Kritik Sosial",
        "情報が氾濫する現代社会において、真実と虚偽を見分けることは、"
        "以前にも増して困難になっている。人々はまるで正しい情報である"
        "かのように言わんばかりに、根拠のない噂を拡散させてしまう。この"
        "状況を憂うがゆえに、私たちには情報を批判的に読み解く力が求め"
        "られているのである。",
        "Dalam masyarakat modern di mana informasi membanjir, "
        "membedakan kebenaran dan kepalsuan menjadi lebih sulit dari "
        "sebelumnya. Orang-orang menyebarkan rumor tanpa dasar seolah-"
        "olah mengatakan itu adalah informasi yang benar. Karena "
        "mengkhawatirkan situasi ini, kita dituntut memiliki kemampuan "
        "membaca informasi secara kritis.",
        [
            ("現代社会で何が困難になっていますか。", ["真実と虚偽を見分けること", "お金を稼ぐこと", "友達を作ること", "仕事を見つけること"], 0),
            ("人々はどのように根拠のない噂を扱っていますか。", ["まるで正しい情報であるかのように拡散させる", "すぐに否定する", "無視する", "警察に報告する"], 0),
            ("筆者が求めていることは何ですか。", ["情報を批判的に読み解く力", "もっと多くの情報", "政府の規制", "テレビの禁止"], 0),
        ],
    ),
    (
        "shokugyou_shoukai",
        "Surat Formal Perkenalan Bisnis",
        "拝啓　時下ますますご清栄のこととお慶び申し上げます。この度、"
        "弊社は新事業を開始する運びとなりました。つきましては、ご多忙の"
        "ところ誠に恐縮ではございますが、一度お目にかかり、詳細をご説明"
        "させていただければ幸いに存じます。何卒よろしくお願い申し"
        "上げます。",
        "Salam hormat. Semoga Anda senantiasa dalam keadaan sejahtera. "
        "Kali ini, perusahaan kami akan memulai usaha baru. Sehubungan "
        "dengan itu, meskipun sangat menyadari kesibukan Anda, kami akan "
        "senang jika bisa bertemu sekali untuk menjelaskan detailnya. "
        "Mohon bantuannya.",
        [
            ("この手紙は何について書かれていますか。", ["新事業の開始", "会社の閉鎖", "社員の退職", "商品の値上げ"], 0),
            ("筆者は何をお願いしていますか。", ["一度会って説明する機会", "お金を貸すこと", "商品を買うこと", "仕事を紹介すること"], 0),
            ("この手紙の文体はどんな特徴がありますか。", ["とても丁寧な敬語", "カジュアルな話し言葉", "短い命令文", "若者言葉"], 0),
        ],
    ),
    (
        "jiritsu_no_katei",
        "Esai tentang Proses Kemandirian",
        "親元を離れて一人暮らしを始めた当初は、心細さに押しつぶされ"
        "そうになった。しかし、失敗を重ねながらも一つ一つ乗り越えて"
        "いくうちに、いつしか自分自身の足で立っているという実感を得るに"
        "至った。自立とは、誰の助けも借りないことではなく、助けを受け"
        "入れる強さを持つことなのかもしれない。",
        "Saat pertama kali mulai hidup sendiri setelah meninggalkan "
        "rumah orang tua, saya hampir tertindih oleh perasaan cemas. "
        "Namun, sambil terus mengalami kegagalan demi kegagalan dan "
        "mengatasinya satu per satu, entah kapan saya sampai pada "
        "perasaan bahwa saya berdiri dengan kaki saya sendiri. "
        "Kemandirian mungkin bukan berarti tidak meminjam bantuan siapa "
        "pun, melainkan memiliki kekuatan untuk menerima bantuan.",
        [
            ("一人暮らしを始めた当初、筆者はどう感じましたか。", ["心細さに押しつぶされそうになった", "とても楽しかった", "何も感じなかった", "すぐに慣れた"], 0),
            ("筆者はどうやって実感を得るに至りましたか。", ["失敗を重ねながら乗り越えていくこと", "すぐに成功したこと", "誰にも頼らなかったこと", "何もしなかったこと"], 0),
            ("筆者にとって自立とは何かもしれませんか。", ["助けを受け入れる強さを持つこと", "誰の助けも借りないこと", "一人でいること", "お金を稼ぐこと"], 0),
        ],
    ),
    (
        "rekishi_kousatsu",
        "Kajian Sejarah Mendalam",
        "戦争を経験した世代が年々少なくなる中、その記憶をいかに次世代へ"
        "継承していくかが問われている。当事者の証言に耳を傾けることの"
        "重要性は言うまでもないが、それだけに頼るのではなく、多角的な"
        "視点から歴史を検証する姿勢もまた不可欠であろう。",
        "Di tengah semakin berkurangnya generasi yang mengalami perang "
        "setiap tahun, muncul pertanyaan bagaimana mewariskan ingatan "
        "tersebut ke generasi berikutnya. Pentingnya mendengarkan "
        "kesaksian dari pihak yang terlibat langsung tidak perlu "
        "diragukan lagi, namun tidak hanya bergantung pada itu saja, "
        "sikap untuk memverifikasi sejarah dari berbagai sudut pandang "
        "juga tak terelakkan penting.",
        [
            ("何が年々少なくなっていますか。", ["戦争を経験した世代", "若い世代", "人口", "学校の数"], 0),
            ("何が問われていますか。", ["記憶をいかに次世代へ継承するか", "戦争をどう終わらせるか", "お金をどう使うか", "誰が悪いか"], 0),
            ("筆者はどんな姿勢が不可欠だと考えていますか。", ["多角的な視点から歴史を検証する姿勢", "一つの意見だけを信じる姿勢", "過去を忘れる姿勢", "誰も批判しない姿勢"], 0),
        ],
    ),
    (
        "jiko_kanryou",
        "Refleksi tentang Pemaafan Diri",
        "過去の過ちを悔やみ続けることに、一体何の意味があるのだろうか。"
        "自分を責め続けるあまり、前に進む力さえ失いかけていた。ある日、"
        "友人の何気ない一言によって、過ちを認めた上で自分を許すことこ"
        "そが、真に成長するための第一歩なのだと気づかされた。",
        "Sebenarnya apa artinya terus menyesali kesalahan masa lalu? "
        "Karena terlalu menyalahkan diri sendiri, saya bahkan hampir "
        "kehilangan kekuatan untuk maju. Suatu hari, melalui sepatah "
        "kata sederhana dari seorang teman, saya disadarkan bahwa "
        "mengakui kesalahan sambil memaafkan diri sendiri adalah langkah "
        "pertama untuk benar-benar bertumbuh.",
        [
            ("筆者は何をし続けていましたか。", ["自分を責め続けること", "友達を責めること", "何もしないこと", "過去を忘れること"], 0),
            ("筆者は何を失いかけていましたか。", ["前に進む力", "お金", "友達", "仕事"], 0),
            ("筆者は何が真に成長するための第一歩だと気づきましたか。", ["過ちを認めた上で自分を許すこと", "二度と失敗しないこと", "誰も信じないこと", "完璧を目指すこと"], 0),
        ],
    ),
    (
        "kagaku_tetsugaku",
        "Diskusi Filosofis tentang Etika Sains",
        "科学技術の進歩は人類に多大な恩恵をもたらしてきた一方で、その"
        "利用の仕方いかんによっては、取り返しのつかない事態を招きかね"
        "ない。技術そのものに善悪はないが、それを扱う人間の倫理観こそが"
        "問われるべきであろう。",
        "Sementara kemajuan teknologi sains telah membawa manfaat besar "
        "bagi umat manusia, tergantung cara penggunaannya, bisa saja "
        "memicu situasi yang tidak dapat dipulihkan. Teknologi itu "
        "sendiri tidak memiliki baik atau buruk, tetapi justru pandangan "
        "etis manusia yang menanganinyalah yang seharusnya dipertanyakan.",
        [
            ("科学技術の進歩は何をもたらしてきましたか。", ["多大な恩恵", "何もない", "不幸だけ", "混乱だけ"], 0),
            ("何によっては取り返しのつかない事態を招きかねませんか。", ["利用の仕方", "発見の速さ", "お金の量", "研究者の数"], 0),
            ("筆者は何が問われるべきだと考えていますか。", ["人間の倫理観", "技術の値段", "政府の政策", "教育のレベル"], 0),
        ],
    ),
    (
        "geijutsu_hyouron",
        "Kritik Seni Sastra",
        "この小説は、登場人物の心理描写の緻密さにおいて、他の追随を"
        "許さない完成度を誇っている。読み進めるうちに、まるで自分自身が"
        "その場にいるかのような感覚に陥り、読み終えた後もしばらくその"
        "余韻に浸らずにはいられなかった。",
        "Novel ini membanggakan tingkat kesempurnaan yang tak "
        "tertandingi dalam hal ketelitian penggambaran psikologi "
        "tokohnya. Seiring membaca, saya jatuh ke dalam perasaan "
        "seolah-olah saya sendiri berada di tempat itu, dan bahkan "
        "setelah selesai membaca, saya tak bisa tidak larut dalam gaung "
        "perasaannya untuk sementara waktu.",
        [
            ("この小説は何において優れた完成度を持っていますか。", ["登場人物の心理描写", "物語の長さ", "表紙のデザイン", "値段の安さ"], 0),
            ("読んでいる間、筆者はどんな感覚に陥りましたか。", ["自分自身がその場にいるかのような感覚", "とても退屈な感覚", "眠くなる感覚", "怒りの感覚"], 0),
            ("読み終えた後、筆者はどうなりましたか。", ["余韻に浸らずにはいられなかった", "すぐに忘れた", "別の本を読み始めた", "何も感じなかった"], 0),
        ],
    ),
    (
        "shakai_henka_kousatsu",
        "Kajian Perubahan Sosial",
        "少子高齢化が進む日本社会において、従来の価値観のままでは立ち"
        "行かない領域が増えつつある。変化を恐れるあまり現状維持に固執"
        "するのではなく、時代の要請に応じて柔軟に制度を見直していく"
        "姿勢こそが、今後ますます求められるのではないだろうか。",
        "Dalam masyarakat Jepang yang mengalami penurunan angka "
        "kelahiran dan penuaan populasi, semakin banyak bidang yang "
        "tidak bisa bertahan dengan nilai-nilai konvensional. Bukankah "
        "sikap untuk secara fleksibel meninjau ulang sistem sesuai "
        "tuntutan zaman, alih-alih terlalu takut akan perubahan dan "
        "bersikeras mempertahankan status quo, yang akan semakin "
        "dibutuhkan ke depannya?",
        [
            ("日本社会で何が進んでいますか。", ["少子高齢化", "人口増加", "経済成長", "都市化"], 0),
            ("何が増えつつありますか。", ["従来の価値観では立ち行かない領域", "若者の数", "仕事の種類", "休みの日数"], 0),
            ("筆者は今後何が求められると考えていますか。", ["柔軟に制度を見直していく姿勢", "現状維持に固執する姿勢", "変化を完全に止めること", "過去に戻ること"], 0),
        ],
    ),
    (
        "jiyuu_no_imi",
        "Esai tentang Makna Kebebasan",
        "自由とは何かを追求すればするほど、その定義の曖昧さに気づかされる。"
        "何ものにも縛られないことを自由と呼ぶ人もいれば、責任を全うした"
        "上で得られる境地こそが真の自由だと説く者もいる。容易に答えの出"
        "ない問いであるがゆえに、人は生涯をかけてそれを探求し続けるのか"
        "もしれない。",
        "Semakin saya mengejar apa itu kebebasan, semakin saya "
        "disadarkan akan ambiguitas definisinya. Ada yang menyebut "
        "kebebasan sebagai tidak terikat oleh apa pun, ada pula yang "
        "berpendapat bahwa keadaan yang diperoleh setelah memenuhi "
        "tanggung jawab itulah kebebasan sejati. Justru karena ini "
        "pertanyaan yang tidak mudah dijawab, mungkin manusia terus "
        "mencarinya seumur hidup.",
        [
            ("自由を追求すればするほど何に気づかされますか。", ["定義の曖昧さ", "お金の大切さ", "時間の速さ", "友情の価値"], 0),
            ("ある人にとって自由とは何ですか。", ["何ものにも縛られないこと", "責任を全うすること", "お金を持つこと", "有名になること"], 0),
            ("別の考え方では、真の自由とは何ですか。", ["責任を全うした上で得られる境地", "完全な孤独", "経済的な成功", "他人からの評価"], 0),
        ],
    ),
    (
        "ushinawareta_isan",
        "Refleksi tentang Warisan Budaya yang Hilang",
        "古い町並みが次々と取り壊され、近代的な建物に姿を変えていく様子を"
        "目の当たりにするたび、言いようのない喪失感に襲われる。効率や"
        "利便性を追求するあまり、先人たちが築き上げてきた文化的財産を"
        "軽視してはいないだろうか。開発と保存のバランスを、今一度真剣に"
        "考える必要があるのではないかと痛感する。",
        "Setiap kali menyaksikan bangunan kota lama dirobohkan satu per "
        "satu dan berubah menjadi bangunan modern, saya diserang rasa "
        "kehilangan yang tak terungkapkan. Bukankah kita terlalu "
        "mengejar efisiensi dan kepraktisan sehingga meremehkan warisan "
        "budaya yang dibangun oleh para pendahulu? Saya sangat menyadari "
        "perlunya memikirkan kembali dengan serius keseimbangan antara "
        "pembangunan dan pelestarian.",
        [
            ("筆者は何を目の当たりにしていますか。", ["古い町並みが取り壊される様子", "新しい町並みが作られる喜び", "人口が増える様子", "自然が回復する様子"], 0),
            ("筆者はどんな感情に襲われますか。", ["言いようのない喪失感", "大きな喜び", "強い怒り", "安心感"], 0),
            ("筆者は何を真剣に考える必要があると述べていますか。", ["開発と保存のバランス", "開発をすべて止めること", "保存をすべてやめること", "何もしないこと"], 0),
        ],
    ),
    (
        "shouhi_shakai_hihan",
        "Kritik tentang Konsumerisme Modern",
        "次々と新しい商品が生み出され、消費を煽られる現代社会において、"
        "私たちは本当に必要なものと、単に欲望を刺激されて欲しくなった"
        "だけのものとを見分ける力を失いつつあるのではないか。物にあふれた"
        "生活が、必ずしも心の豊かさを意味するとは限らないということを、"
        "私たちは今一度思い出すべきであろう。",
        "Dalam masyarakat modern di mana produk baru diciptakan secara "
        "terus-menerus dan konsumsi terus didorong, bukankah kita mulai "
        "kehilangan kemampuan untuk membedakan antara apa yang benar-"
        "benar kita butuhkan dan apa yang hanya diinginkan karena "
        "keinginan yang terstimulasi? Kita seharusnya mengingat kembali "
        "bahwa kehidupan yang berlimpah barang tidak selalu berarti "
        "kekayaan hati.",
        [
            ("現代社会で私たちが失いつつある力は何ですか。", ["本当に必要なものを見分ける力", "お金を稼ぐ力", "商品を作る力", "話す力"], 0),
            ("筆者は物にあふれた生活について、どう述べていますか。", ["心の豊かさを意味するとは限らない", "必ず心を豊かにする", "何の意味もない", "誰にとっても幸せだ"], 0),
            ("筆者は何を思い出すべきだと考えていますか。", ["物と心の豊かさの違い", "もっと消費すべきこと", "商品の値段", "広告の力"], 0),
        ],
    ),
    (
        "shizen_to_ningen",
        "Diskusi tentang Hubungan Manusia dan Alam",
        "人間は長らく、自然を征服し、利用する対象としてのみ捉えてきた"
        "側面がある。しかし、度重なる自然災害を経験する中で、人間もまた"
        "自然の一部に過ぎないという謙虚な認識を取り戻しつつあるように"
        "思われる。自然と共生する道を模索することこそ、これからの人類に"
        "課せられた責務ではないだろうか。",
        "Manusia telah lama memandang alam hanya sebagai objek untuk "
        "ditaklukkan dan dimanfaatkan. Namun, di tengah mengalami "
        "bencana alam yang berulang kali, tampaknya manusia mulai "
        "mendapatkan kembali kesadaran rendah hati bahwa manusia juga "
        "hanyalah bagian dari alam. Bukankah mencari jalan untuk hidup "
        "berdampingan dengan alam adalah tanggung jawab yang dibebankan "
        "pada umat manusia ke depannya?",
        [
            ("人間は長らく自然をどう捉えてきましたか。", ["征服し利用する対象", "神聖なもの", "恐れるべきもの", "無関係なもの"], 0),
            ("度重なる自然災害を経験して、人間はどんな認識を取り戻しつつありますか。", ["自然の一部に過ぎないという謙虚な認識", "自然を完全に支配できるという自信", "自然への無関心", "自然への恐怖だけ"], 0),
            ("筆者は何が人類に課せられた責務だと考えていますか。", ["自然と共生する道を模索すること", "自然を完全に征服すること", "自然から離れること", "何もしないこと"], 0),
        ],
    ),
    (
        "gengo_aidentiti",
        "Diskusi tentang Bahasa dan Identitas",
        "母語とは、単なるコミュニケーションの道具にとどまらず、自己の"
        "アイデンティティを形成する根幹をなすものである。異なる文化圏で"
        "暮らす中で母語を失いかけた経験を持つ者ほど、その重みを痛感する"
        "のかもしれない。言葉を守ることは、自分自身を守ることに他なら"
        "ないのである。",
        "Bahasa ibu bukan sekadar alat komunikasi semata, tetapi menjadi "
        "dasar yang membentuk identitas diri. Mereka yang memiliki "
        "pengalaman hampir kehilangan bahasa ibunya saat tinggal di "
        "lingkungan budaya yang berbeda mungkin lebih menyadari betapa "
        "beratnya hal itu. Menjaga bahasa tidak lain adalah menjaga diri "
        "sendiri.",
        [
            ("母語とは何にとどまらないものですか。", ["単なるコミュニケーションの道具", "アイデンティティの根幹", "文化の一部", "教育の手段"], 0),
            ("誰がその重みを痛感するかもしれませんか。", ["母語を失いかけた経験を持つ者", "母語しか話せない者", "外国語が得意な者", "教師"], 0),
            ("言葉を守ることは何に他なりませんか。", ["自分自身を守ること", "お金を守ること", "家族を守ること", "国を守ること"], 0),
        ],
    ),
    (
        "jinsei_no_tabi",
        "Refleksi tentang Perjalanan Hidup",
        "振り返れば、人生とは予測不可能な出来事の連続であった。計画通りに"
        "進んだことなど、むしろ少なかったように思う。しかし、その予測でき"
        "なさこそが、人生に彩りを与えてくれていたのではないかと、今に"
        "なって思う。不確実性を恐れるのではなく、受け入れる姿勢が、豊かな"
        "人生につながるのかもしれない。",
        "Jika saya renungkan, hidup adalah rangkaian peristiwa yang tak "
        "terduga. Saya pikir hal-hal yang berjalan sesuai rencana justru "
        "sedikit. Namun, saya sekarang berpikir bahwa justru "
        "ketidakterprediksian itulah yang memberi warna pada kehidupan. "
        "Sikap menerima ketidakpastian, bukan menakutinya, mungkin akan "
        "mengarah pada kehidupan yang kaya.",
        [
            ("筆者は人生をどう振り返っていますか。", ["予測不可能な出来事の連続", "計画通りに進んだもの", "単調なもの", "簡単なもの"], 0),
            ("筆者は何が人生に彩りを与えたと考えていますか。", ["予測できなさ", "計画性", "お金", "他人からの評価"], 0),
            ("筆者はどんな姿勢が豊かな人生につながると考えていますか。", ["不確実性を受け入れる姿勢", "不確実性を避ける姿勢", "完璧な計画を立てる姿勢", "何も考えない姿勢"], 0),
        ],
    ),
    (
        "chinmoku_no_chie",
        "Esai tentang Keheningan dan Kebijaksanaan",
        "言葉を発することよりも、沈黙を保つことの方が難しい場面が人生には"
        "多々ある。すべてを語らずとも伝わるものがあるという事実に、若い"
        "頃の私は気づいていなかった。年齢を重ねた今だからこそ、沈黙の中に"
        "宿る豊かな意味を感じ取れるようになったのかもしれない。",
        "Dalam hidup, ada banyak momen di mana menjaga keheningan lebih "
        "sulit daripada mengeluarkan kata-kata. Dulu saat masih muda, "
        "saya tidak menyadari fakta bahwa ada hal yang tersampaikan "
        "tanpa harus diucapkan semuanya. Mungkin justru karena sekarang "
        "usia saya sudah bertambah, saya bisa merasakan makna kaya yang "
        "bersemayam dalam keheningan.",
        [
            ("人生において何の方が難しい場面が多いですか。", ["沈黙を保つこと", "言葉を発すること", "歩くこと", "食べること"], 0),
            ("若い頃、筆者は何に気づいていませんでしたか。", ["すべてを語らずとも伝わるものがあること", "言葉の大切さ", "お金の価値", "時間の速さ"], 0),
            ("年齢を重ねた今、筆者は何を感じ取れるようになりましたか。", ["沈黙の中に宿る豊かな意味", "言葉の無意味さ", "若さの価値", "孤独の辛さ"], 0),
        ],
    ),
    (
        "koten_hihyou",
        "Kritik Sastra Klasik",
        "この古典作品が数百年の時を経てもなお読み継がれている理由は、"
        "人間の本質を鋭く捉えた普遍性にあると言えよう。時代背景こそ"
        "異なれど、登場人物たちが抱える葛藤や苦悩は、現代を生きる私たちの"
        "心にも深く響くものがある。",
        "Alasan mengapa karya klasik ini masih terus dibaca meskipun "
        "sudah melewati ratusan tahun bisa dikatakan terletak pada "
        "universalitasnya yang menangkap esensi manusia secara tajam. "
        "Meskipun latar belakang zamannya berbeda, konflik dan "
        "penderitaan yang dialami para tokoh juga bergema dalam hati "
        "kita yang hidup di zaman modern.",
        [
            ("この古典作品が読み継がれている理由は何だと言われていますか。", ["人間の本質を捉えた普遍性", "面白い挿絵", "短い文章", "有名な作者"], 0),
            ("時代背景はどうですか。", ["異なる", "同じ", "分からない", "関係ない"], 0),
            ("登場人物たちの葛藤や苦悩は、現代の私たちにどう響きますか。", ["深く響く", "全く響かない", "少しだけ響く", "意味がない"], 0),
        ],
    ),
    (
        "genjitsu_to_gensou",
        "Esai tentang Batas Antara Realita dan Ilusi",
        "夢と現実の境界線が曖昧になる瞬間を、誰もが一度は経験したことが"
        "あるのではないだろうか。テクノロジーの発展により、仮想現実と"
        "現実世界の境目はますます不明瞭になりつつある。何が真実で何が"
        "虚構であるかを見極める力は、今後さらに重要性を増していくに違い"
        "ない。",
        "Bukankah setiap orang setidaknya pernah mengalami momen di mana "
        "batas antara mimpi dan realita menjadi kabur? Dengan "
        "perkembangan teknologi, batas antara realitas virtual dan dunia "
        "nyata semakin tidak jelas. Kemampuan untuk membedakan apa yang "
        "benar dan apa yang fiktif pasti akan semakin penting ke "
        "depannya.",
        [
            ("誰もが一度は経験したことがあるのは何ですか。", ["夢と現実の境界線が曖昧になる瞬間", "完全な現実", "完全な夢", "何も感じないこと"], 0),
            ("テクノロジーの発展により何が起きていますか。", ["仮想現実と現実世界の境目が不明瞭になる", "現実がなくなる", "夢がなくなる", "何も変わらない"], 0),
            ("今後何がさらに重要になると述べられていますか。", ["真実と虚構を見極める力", "お金を稼ぐ力", "技術を作る力", "忘れる力"], 0),
        ],
    ),
    (
        "seishi_no_tetsugaku",
        "Refleksi Filosofis tentang Kematian dan Kehidupan",
        "死を意識することなくして、生を真に実感することはできないのかも"
        "しれない。限りある時間だからこそ、一瞬一瞬が尊いものとして輝きを"
        "放つのである。死を忌避すべきものとしてではなく、生の一部として"
        "受け入れる時、人は初めて、今このときを精一杯生きようとする覚悟を"
        "持てるのではないだろうか。",
        "Mungkin kita tidak bisa benar-benar merasakan kehidupan tanpa "
        "menyadari kematian. Justru karena waktu yang terbatas, setiap "
        "momen memancarkan kilau sebagai sesuatu yang berharga. Ketika "
        "manusia menerima kematian bukan sebagai sesuatu yang harus "
        "dihindari, melainkan sebagai bagian dari kehidupan, mungkin "
        "saat itulah untuk pertama kalinya seseorang bisa memiliki tekad "
        "untuk menjalani saat ini sepenuh hati.",
        [
            ("筆者は何を意識することが生を実感するために必要だと述べていますか。", ["死", "お金", "名声", "若さ"], 0),
            ("限りある時間だからこそ、何が輝きを放ちますか。", ["一瞬一瞬", "過去の思い出", "未来の計画", "他人の人生"], 0),
            ("死をどう受け入れる時、人は覚悟を持てますか。", ["生の一部として", "完全に忌避すべきものとして", "恐れるべきものとして", "無視すべきものとして"], 0),
        ],
    ),
    (
        "machi_no_imi",
        "Esai tentang Arti Menunggu",
        "誰かを待つという行為には、単なる時間の経過以上の意味が込められて"
        "いるように思われてならない。待つことに耐えかねる瞬間もあるが、"
        "その苦しみこそが、再会の喜びを何倍にも増幅させるのではないだろ"
        "うか。効率ばかりが重視される現代において、待つことの美学を見つめ"
        "直す価値はあるはずだ。",
        "Saya tidak bisa tidak merasa bahwa tindakan menunggu seseorang "
        "mengandung makna lebih dari sekadar berlalunya waktu. Ada "
        "momen di mana sulit menahan penantian, tetapi bukankah justru "
        "penderitaan itulah yang melipatgandakan kegembiraan pertemuan "
        "kembali? Dalam era modern di mana efisiensi selalu diutamakan, "
        "seharusnya ada nilai dalam merenungkan kembali estetika "
        "menunggu.",
        [
            ("待つという行為には何が込められていると筆者は感じていますか。", ["単なる時間の経過以上の意味", "何の意味もないこと", "苦痛だけ", "無駄な時間"], 0),
            ("待つことの苦しみは何を増幅させるかもしれませんか。", ["再会の喜び", "悲しみ", "怒り", "疲労"], 0),
            ("現代において何を見つめ直す価値があるとされていますか。", ["待つことの美学", "効率の追求", "スピードの重要性", "便利さ"], 0),
        ],
    ),
    (
        "yoru_no_shizukesa",
        "Refleksi tentang Kesenyapan Kota Malam",
        "深夜、人通りの絶えた街を歩いていると、昼間の喧騒が嘘のように"
        "静まり返っている。この静寂の中でこそ、日中は聞こえてこなかった"
        "自分自身の内なる声に、ようやく耳を傾けられるような気がする。"
        "都市の喧噪から離れた瞬間に、初めて自分と向き合えるのかもしれ"
        "ない。",
        "Larut malam, saat berjalan di jalanan yang sudah sepi dari "
        "lalu lalang orang, keramaian siang hari seolah bohong, begitu "
        "sunyi senyap. Justru dalam keheningan inilah, saya merasa "
        "akhirnya bisa mendengarkan suara batin diri sendiri yang tidak "
        "terdengar di siang hari. Mungkin justru di saat menjauh dari "
        "hiruk pikuk kota, untuk pertama kalinya kita bisa menghadapi "
        "diri sendiri.",
        [
            ("深夜の街はどうなっていますか。", ["昼間の喧騒が嘘のように静まり返っている", "昼間よりにぎやかになる", "何も変わらない", "危険になる"], 0),
            ("この静寂の中で、筆者は何に耳を傾けられる気がしますか。", ["自分自身の内なる声", "他人の声", "音楽", "何も聞こえない"], 0),
            ("何から離れた瞬間に自分と向き合えるかもしれませんか。", ["都市の喧噪", "家族", "仕事", "過去"], 0),
        ],
    ),
    (
        "supiido_bunka_hihan",
        "Kritik tentang Budaya Kecepatan Modern",
        "何事も迅速な結果を求める現代の風潮において、じっくりと時間を"
        "かけて物事に取り組む姿勢は、ともすれば非効率的だと切り捨てられ"
        "かねない。しかし、拙速に得られた成果には、往々にして脆さが"
        "つきまとうものである。真に価値あるものは、時間という試練を"
        "経てこそ、初めて磨き上げられるのではないだろうか。",
        "Dalam tren modern di mana segala sesuatu menuntut hasil yang "
        "cepat, sikap mengerjakan sesuatu dengan cermat dan memakan "
        "waktu, kalau tidak hati-hati, bisa saja dianggap tidak efisien "
        "dan dibuang begitu saja. Namun, hasil yang diperoleh secara "
        "tergesa-gesa seringkali membawa kerapuhan. Bukankah sesuatu "
        "yang benar-benar bernilai baru bisa terasah setelah melalui "
        "ujian waktu?",
        [
            ("現代の風潮では何が求められていますか。", ["迅速な結果", "じっくりとした取り組み", "静けさ", "過去への回帰"], 0),
            ("拙速に得られた成果には何がつきまといますか。", ["脆さ", "確実性", "高い価値", "永続性"], 0),
            ("真に価値あるものは何を経て磨き上げられますか。", ["時間という試練", "速さ", "お金", "運"], 0),
        ],
    ),
    (
        "mienai_isan",
        "Esai tentang Warisan Leluhur yang Tak Terlihat",
        "祖先から受け継いだものは、目に見える財産や家屋だけではない。"
        "困難に直面した時にどう振る舞うべきかという知恵や、他者への"
        "思いやりの心もまた、脈々と受け継がれてきた無形の遺産である。"
        "私たちは、これらを次世代へと確実に手渡す責任を負っているので"
        "ある。",
        "Apa yang diwariskan dari leluhur bukan hanya harta atau rumah "
        "yang terlihat mata. Kebijaksanaan tentang bagaimana seharusnya "
        "bersikap saat menghadapi kesulitan, dan hati kepedulian "
        "terhadap orang lain, juga merupakan warisan tak berwujud yang "
        "telah diwariskan turun-temurun. Kita memikul tanggung jawab "
        "untuk menyerahkan hal-hal ini dengan pasti kepada generasi "
        "berikutnya.",
        [
            ("祖先から受け継いだものは何だけではありませんか。", ["目に見える財産や家屋", "知恵", "思いやりの心", "無形の遺産"], 0),
            ("無形の遺産の例として何が挙げられていますか。", ["困難に直面した時の知恵と思いやりの心", "お金と土地", "名誉と地位", "技術と知識だけ"], 0),
            ("私たちはどんな責任を負っていますか。", ["これらを次世代へ手渡す責任", "財産を増やす責任", "全てを忘れる責任", "何もしない責任"], 0),
        ],
    ),
    (
        "shinjitsu_tetsugaku",
        "Diskusi Filosofis tentang Kebenaran",
        "絶対的な真実というものが、果たしてこの世に存在するのだろうか。"
        "人は皆、自らの経験というフィルターを通してしか物事を認識できない"
        "以上、真実とは常に主観性を帯びたものにならざるを得ないのかも"
        "しれない。それでもなお、真実を追い求める営みそのものに、人間"
        "存在の意義が見出せるように思う。",
        "Apakah kebenaran absolut sebenarnya ada di dunia ini? Karena "
        "manusia hanya bisa mengenali sesuatu melalui filter "
        "pengalamannya sendiri, kebenaran mungkin tak terelakkan selalu "
        "mengandung subjektivitas. Meski begitu, saya rasa makna "
        "keberadaan manusia bisa ditemukan justru dalam upaya mengejar "
        "kebenaran itu sendiri.",
        [
            ("筆者は絶対的な真実についてどう問いかけていますか。", ["果たして存在するのだろうか", "確実に存在する", "全く存在しない", "誰にでも分かる"], 0),
            ("真実は何にならざるを得ないかもしれませんか。", ["主観性を帯びたもの", "完全に客観的なもの", "変わらないもの", "誰にでも同じもの"], 0),
            ("人間存在の意義は何に見出せるように思われますか。", ["真実を追い求める営みそのもの", "真実を見つけること自体", "お金を稼ぐこと", "他人を助けること"], 0),
        ],
    ),
    (
        "kokyou_akogare",
        "Refleksi tentang Kerinduan akan Tempat Asal",
        "都会での生活が長くなるにつれ、ふとした瞬間に故郷の風景が脳裏を"
        "よぎることが増えた。あの頃は当たり前だと思っていた景色が、今と"
        "なっては何にも代えがたい懐かしさを伴って心に迫ってくる。人は、"
        "失って初めてその価値に気づくものなのかもしれない。",
        "Seiring bertambah lamanya kehidupan di kota, semakin sering "
        "pemandangan kampung halaman melintas di benak dalam sekejap. "
        "Pemandangan yang dulu dianggap biasa saja, kini datang "
        "mendekati hati dengan kerinduan yang tak tergantikan. Manusia "
        "mungkin baru menyadari nilainya setelah kehilangan.",
        [
            ("都会での生活が長くなるにつれ、何が増えましたか。", ["故郷の風景が脳裏をよぎること", "故郷を忘れること", "都会が好きになること", "何も変わらないこと"], 0),
            ("あの頃当たり前だと思っていた景色は、今どうなっていますか。", ["懐かしさを伴って心に迫ってくる", "完全に忘れられている", "嫌いになっている", "何も感じない"], 0),
            ("筆者は人間についてどう考えていますか。", ["失って初めて価値に気づくもの", "最初から全てに気づくもの", "何も気づかないもの", "価値を気にしないもの"], 0),
        ],
    ),
    (
        "ai_gimu_kyoukai",
        "Esai tentang Batas Antara Cinta dan Kewajiban",
        "家族の介護に携わる中で、愛情と義務感の境界線が次第に曖昧になって"
        "いく自分に気づいた。純粋な愛情だけで続けられるほど、現実は甘く"
        "ない。それでも、義務感だけでは決して生まれ得ない優しさが、確かに"
        "そこには存在していた。",
        "Di tengah terlibat dalam merawat keluarga, saya menyadari diri "
        "sendiri di mana batas antara cinta dan rasa kewajiban semakin "
        "lama semakin kabur. Kenyataannya tidak semanis itu untuk bisa "
        "dilanjutkan hanya dengan cinta murni. Meski begitu, ada "
        "kelembutan yang tidak akan pernah lahir hanya dari rasa "
        "kewajiban, yang memang ada di sana.",
        [
            ("家族の介護に携わる中で、筆者は何に気づきましたか。", ["愛情と義務感の境界線が曖昧になっていくこと", "介護が簡単なこと", "家族が嫌いになったこと", "何も感じないこと"], 0),
            ("現実は何ほど甘くありませんか。", ["純粋な愛情だけで続けられるほど", "とても厳しいほど", "全く甘くないほど", "分からないほど"], 0),
            ("義務感だけでは何が生まれ得ませんか。", ["優しさ", "お金", "時間", "疲労"], 0),
        ],
    ),
    (
        "rekishi_katari",
        "Kritik Sastra tentang Narasi Sejarah",
        "歴史とは、勝者によって都合よく編纂されてきた側面があることを、"
        "私たちは常に意識しておく必要がある。一つの出来事にも、語る者の"
        "立場によって幾通りもの解釈が存在し得るのであり、単一の物語を"
        "鵜呑みにする危うさを自覚すべきであろう。",
        "Kita perlu selalu menyadari bahwa sejarah memiliki sisi yang "
        "disusun secara menguntungkan oleh pihak yang menang. Bahkan "
        "satu peristiwa pun, bisa memiliki berbagai interpretasi "
        "tergantung posisi si penutur, dan kita seharusnya menyadari "
        "bahaya menelan mentah-mentah satu narasi tunggal.",
        [
            ("歴史にはどんな側面がありますか。", ["勝者によって都合よく編纂されてきた側面", "完全に客観的な側面", "誰にでも同じに見える側面", "変わらない側面"], 0),
            ("一つの出来事には何が存在し得ますか。", ["幾通りもの解釈", "一つの真実だけ", "何の意味もないもの", "誰も知らない事実"], 0),
            ("私たちは何を自覚すべきですか。", ["単一の物語を鵜呑みにする危うさ", "歴史を学ぶ必要がないこと", "全ての歴史が正しいこと", "歴史は変えられないこと"], 0),
        ],
    ),
    (
        "henka_kyoufu",
        "Esai tentang Ketakutan Menghadapi Perubahan",
        "人はなぜ、変化をこれほどまでに恐れるのだろうか。既知のものに"
        "しがみつく安心感は理解できるが、その執着ゆえに、新たな可能性を"
        "自らの手で閉ざしてしまっているとしたら、それは何とも皮肉な"
        "ことである。恐怖を乗り越えた先にこそ、真の成長があるのだと"
        "信じたい。",
        "Mengapa manusia begitu takut akan perubahan? Rasa aman "
        "berpegang pada hal yang sudah diketahui bisa dipahami, tapi "
        "jika karena keterikatan itu, kita menutup kemungkinan baru "
        "dengan tangan sendiri, itu suatu ironi yang luar biasa. Saya "
        "ingin percaya bahwa pertumbuhan sejati ada di seberang setelah "
        "mengatasi ketakutan.",
        [
            ("筆者は人が何を恐れると問いかけていますか。", ["変化", "成功", "お金", "孤独"], 0),
            ("執着ゆえに何を自らの手で閉ざしてしまうことがありますか。", ["新たな可能性", "過去の記憶", "お金", "友情"], 0),
            ("筆者は何が真の成長だと信じたいと述べていますか。", ["恐怖を乗り越えた先にあるもの", "変化を避けること", "安心感を保つこと", "何もしないこと"], 0),
        ],
    ),
    (
        "wakare_imi",
        "Refleksi tentang Makna Sebuah Perpisahan",
        "別れとは、必ずしも終わりを意味するものではないのかもしれない。"
        "物理的な距離が生まれたとしても、共に過ごした時間の中で育まれた"
        "絆は、形を変えながらも確かに存在し続ける。むしろ、別れがあった"
        "からこそ、その関係の尊さに気づけることもあるのだろう。",
        "Perpisahan mungkin tidak selalu berarti akhir. Meskipun jarak "
        "fisik tercipta, ikatan yang dipupuk dalam waktu yang "
        "dihabiskan bersama tetap terus ada meski berubah bentuk. "
        "Justru mungkin karena ada perpisahan, kita bisa menyadari "
        "betapa berharganya hubungan itu.",
        [
            ("筆者は別れについて、必ずしも何を意味しないかもしれないと述べていますか。", ["終わり", "始まり", "悲しみ", "喜び"], 0),
            ("共に過ごした時間の中で育まれた絆は、どうなりますか。", ["形を変えながらも存在し続ける", "完全に消える", "すぐに忘れられる", "意味を失う"], 0),
            ("別れがあったからこそ、何に気づけることがありますか。", ["その関係の尊さ", "お金の大切さ", "時間の速さ", "孤独の辛さ"], 0),
        ],
    ),
    (
        "geijutsu_rinri",
        "Diskusi tentang Etika dalam Seni",
        "表現の自由は尊重されるべきであるが、それが他者への配慮を欠いた"
        "免罪符になってはならない。芸術家には、自らの表現がもたらしうる"
        "影響について、常に自覚的であることが求められるのではないだろう"
        "か。自由と責任は、表裏一体の関係にあるのである。",
        "Kebebasan berekspresi harus dihormati, tetapi itu tidak boleh "
        "menjadi surat izin yang kurang mempertimbangkan orang lain. "
        "Bukankah seniman dituntut untuk selalu menyadari dampak yang "
        "bisa ditimbulkan oleh ekspresinya sendiri? Kebebasan dan "
        "tanggung jawab berada dalam hubungan yang tak terpisahkan, "
        "seperti dua sisi mata uang.",
        [
            ("表現の自由は何になってはなりませんか。", ["他者への配慮を欠いた免罪符", "尊重されるべきもの", "芸術の基本", "大切な権利"], 0),
            ("芸術家に何が求められるのではないかと述べられていますか。", ["自らの表現の影響について自覚的であること", "表現を完全に自由にすること", "表現をやめること", "他人の意見を無視すること"], 0),
            ("自由と責任はどんな関係にありますか。", ["表裏一体の関係", "全く無関係", "対立する関係", "どちらか一方だけの関係"], 0),
        ],
    ),
    (
        "kitai_omomi",
        "Esai tentang Beban Ekspektasi Sosial",
        "周囲からの期待に応えようとするあまり、本来の自分を見失って"
        "しまう瞬間がある。他者の評価を気にすることは人間である以上避け"
        "られないが、それに人生の舵取りを完全に委ねてしまっては、本末"
        "転倒であろう。自分自身の声に、もっと耳を傾けるべきなのかも"
        "しれない。",
        "Ada momen di mana karena terlalu berusaha memenuhi ekspektasi "
        "dari sekitar, kita kehilangan diri sendiri yang sebenarnya. "
        "Mempedulikan penilaian orang lain tidak terelakkan selama "
        "masih manusia, tapi jika kita menyerahkan kendali hidup "
        "sepenuhnya pada itu, itu adalah kebalikan dari yang "
        "seharusnya. Mungkin kita seharusnya lebih mendengarkan suara "
        "diri sendiri.",
        [
            ("何に応えようとするあまり、本来の自分を見失いますか。", ["周囲からの期待", "自分の欲望", "お金の必要", "時間の制約"], 0),
            ("他者の評価を気にすることはどうですか。", ["人間である以上避けられない", "完全に避けられる", "意味がない", "悪いことだけ"], 0),
            ("筆者は何をすべきかもしれないと考えていますか。", ["自分自身の声にもっと耳を傾けること", "他人の期待に完全に従うこと", "全てを無視すること", "何も考えないこと"], 0),
        ],
    ),
    (
        "kodoku_imi",
        "Refleksi tentang Kesendirian yang Bermakna",
        "孤独は、しばしば忌避すべきものとして語られる。しかし、他者との"
        "関わりから一時的に離れ、自己と静かに向き合う時間もまた、人生に"
        "は不可欠なのではないだろうか。真に豊かな孤独は、寂しさとは似て"
        "非なるものである。",
        "Kesendirian seringkali dibicarakan sebagai sesuatu yang harus "
        "dihindari. Namun, bukankah waktu untuk sementara menjauh dari "
        "keterlibatan dengan orang lain dan menghadapi diri sendiri "
        "dengan tenang juga tak terpisahkan dari kehidupan? Kesendirian "
        "yang benar-benar kaya itu mirip tapi berbeda dari kesepian.",
        [
            ("孤独はしばしばどう語られますか。", ["忌避すべきもの", "求めるべきもの", "素晴らしいもの", "誰にでも必要なもの"], 0),
            ("何が人生には不可欠かもしれないと述べられていますか。", ["自己と静かに向き合う時間", "常に他者といること", "お金を稼ぐこと", "忙しくすること"], 0),
            ("真に豊かな孤独と寂しさの関係はどうですか。", ["似て非なるもの", "全く同じもの", "完全に反対のもの", "無関係なもの"], 0),
        ],
    ),
    (
        "gengo_kindaika",
        "Kritik tentang Modernisasi Bahasa",
        "時代とともに言葉が変化していくことは自然な現象であるが、その"
        "変化の速度があまりに急激であることに、一抹の不安を覚える。古い"
        "言葉の中に宿っていた繊細な感情表現が、簡略化の波の中で失われつ"
        "つあるのではないかと危惧している。",
        "Bahasa berubah seiring zaman adalah fenomena yang alami, "
        "tetapi saya merasakan sedikit kecemasan karena kecepatan "
        "perubahan itu begitu drastis. Saya khawatir ekspresi emosi "
        "yang halus yang bersemayam dalam kata-kata lama mulai hilang "
        "dalam gelombang penyederhanaan.",
        [
            ("言葉が変化していくことについて、筆者はどう考えていますか。", ["自然な現象だが速度に不安を覚える", "全く問題ない", "悪いことでしかない", "良いことでしかない"], 0),
            ("古い言葉の中に何が宿っていましたか。", ["繊細な感情表現", "間違った表現", "使いにくさ", "複雑さだけ"], 0),
            ("筆者は何を危惧していますか。", ["繊細な感情表現が失われつつあること", "言葉が増えすぎること", "誰も言葉を使わなくなること", "新しい言葉が生まれないこと"], 0),
        ],
    ),
    (
        "sedai_toraumaisan",
        "Esai tentang Warisan Trauma Antar Generasi",
        "親の世代が経験した苦しみは、直接語られずとも、無意識のうちに"
        "子の世代へと影響を及ぼすことがあるという。この目に見えない連鎖"
        "を断ち切るためには、まず自らの家族の歴史と真摯に向き合う勇気が"
        "必要なのかもしれない。",
        "Dikatakan bahwa penderitaan yang dialami generasi orang tua, "
        "meskipun tidak diceritakan secara langsung, terkadang tanpa "
        "disadari memberikan pengaruh pada generasi anak. Untuk memutus "
        "rantai yang tak terlihat ini, mungkin diperlukan keberanian "
        "untuk pertama-tama menghadapi sejarah keluarga sendiri dengan "
        "sungguh-sungguh.",
        [
            ("親の世代が経験した苦しみは、どう子の世代に影響しますか。", ["直接語られずとも無意識のうちに", "常に直接語られて", "全く影響しない", "すぐに忘れられて"], 0),
            ("この連鎖を断ち切るために何が必要かもしれませんか。", ["自らの家族の歴史と向き合う勇気", "全てを忘れること", "家族と縁を切ること", "何もしないこと"], 0),
            ("この文章のテーマは何ですか。", ["世代間トラウマ", "経済的な連鎖", "教育の連鎖", "健康の連鎖"], 0),
        ],
    ),
    (
        "jikan_kioku_tetsugaku",
        "Diskusi Filosofis tentang Waktu dan Ingatan",
        "記憶とは、過去の出来事をそのまま保存したものではなく、現在の"
        "視点によって絶えず再構築され続けているものなのかもしれない。"
        "私たちが「思い出」と呼ぶものは、いわば現在の自分が作り上げた、"
        "一種の物語なのである。",
        "Ingatan mungkin bukan sesuatu yang menyimpan peristiwa masa "
        "lalu apa adanya, melainkan sesuatu yang terus-menerus "
        "direkonstruksi ulang dari sudut pandang saat ini. Apa yang "
        "kita sebut 'kenangan' adalah semacam narasi yang dibangun oleh "
        "diri kita di masa sekarang.",
        [
            ("記憶とは何ではないかもしれませんか。", ["過去の出来事をそのまま保存したもの", "現在の視点で再構築されるもの", "一種の物語", "変化するもの"], 0),
            ("記憶は何によって絶えず再構築され続けていますか。", ["現在の視点", "過去の視点", "他人の視点", "未来の視点"], 0),
            ("私たちが「思い出」と呼ぶものは何だとされていますか。", ["現在の自分が作り上げた物語", "完全に客観的な記録", "変わらない事実", "他人が作ったもの"], 0),
        ],
    ),
    (
        "jibunrashisa_yuuki",
        "Refleksi tentang Keberanian Menjadi Diri Sendiri",
        "周囲と異なる意見を持つことに、長い間恐怖を感じていた。しかし、"
        "他人の顔色をうかがい続ける生き方に疲れ果てた時、ようやく自分ら"
        "しくあることの尊さに気づいた。同調圧力に屈しない勇気こそ、真の"
        "自由への第一歩なのかもしれない。",
        "Saya lama merasa takut memiliki pendapat yang berbeda dari "
        "sekitar. Namun, ketika lelah terus-menerus melihat wajah orang "
        "lain, akhirnya saya menyadari betapa berharganya menjadi diri "
        "sendiri. Keberanian untuk tidak tunduk pada tekanan "
        "konformitas mungkin adalah langkah pertama menuju kebebasan "
        "sejati.",
        [
            ("筆者は長い間何に恐怖を感じていましたか。", ["周囲と異なる意見を持つこと", "一人でいること", "失敗すること", "変化すること"], 0),
            ("何に疲れ果てた時、自分らしさに気づきましたか。", ["他人の顔色をうかがい続ける生き方", "仕事をすること", "勉強すること", "人と話すこと"], 0),
            ("何が真の自由への第一歩かもしれませんか。", ["同調圧力に屈しない勇気", "他人に従うこと", "完全に孤立すること", "何も言わないこと"], 0),
        ],
    ),
    (
        "kouhuku_paradokkusu",
        "Esai tentang Paradoks Kebahagiaan",
        "幸福を直接追い求めれば追い求めるほど、それは手からすり抜けて"
        "いくように感じられる。むしろ、目の前の物事に没頭し、他者のため"
        "に尽力する中で、気づけば幸福が静かに寄り添っていた、というのが"
        "実情に近いのかもしれない。",
        "Semakin langsung kita mengejar kebahagiaan, semakin terasa "
        "lolos dari tangan. Justru mungkin yang lebih mendekati "
        "kenyataan adalah, ketika tenggelam dalam hal di depan mata dan "
        "berusaha demi orang lain, tanpa disadari kebahagiaan diam-diam "
        "sudah mendekat.",
        [
            ("幸福を直接追い求めるとどう感じられますか。", ["手からすり抜けていくように感じられる", "すぐに手に入るように感じられる", "簡単に感じられる", "何も感じない"], 0),
            ("何をする中で幸福が寄り添っていることがありますか。", ["目の前の物事に没頭し他者のために尽力すること", "幸福だけを考え続けること", "何もしないこと", "お金を稼ぐことだけ"], 0),
            ("この文章のテーマは何ですか。", ["幸福のパラドックス", "お金と幸福の関係", "仕事と幸福の関係", "健康と幸福の関係"], 0),
        ],
    ),
    (
        "jaanarizumu_kyakkansei",
        "Kritik tentang Objektivitas dalam Jurnalisme",
        "完全に客観的な報道など、そもそも存在し得ないのかもしれない。"
        "何を取り上げ、何を取り上げないかという選択自体に、既に主観が"
        "介在しているからである。だからこそ、受け手側もまた、批判的な"
        "視点を持って情報に接する姿勢が求められるのである。",
        "Pemberitaan yang sepenuhnya objektif, sejak awal mungkin "
        "tidak mungkin ada. Karena dalam pilihan apa yang diangkat dan "
        "apa yang tidak diangkat pun, subjektivitas sudah ikut campur. "
        "Justru karena itulah, pihak penerima juga dituntut untuk "
        "memiliki sikap kritis dalam menghadapi informasi.",
        [
            ("筆者は何が存在し得ないかもしれないと述べていますか。", ["完全に客観的な報道", "全ての報道", "主観的な報道", "誤った報道"], 0),
            ("何にすでに主観が介在していますか。", ["何を取り上げ何を取り上げないかという選択", "記事の長さ", "発行時間", "使用する紙"], 0),
            ("受け手側に何が求められていますか。", ["批判的な視点を持って情報に接する姿勢", "全てを信じる姿勢", "情報を無視する姿勢", "何も考えない姿勢"], 0),
        ],
    ),
    (
        "shippitsu_tabi_kessho",
        "Refleksi Penutup tentang Perjalanan Menulis",
        "文章を書くという行為は、自分自身の内面と向き合う旅のようなもの"
        "だと、改めて実感している。書き始めた当初は思いもよらなかった"
        "発見が、筆を進めるうちに次々と現れる。この旅に終わりはなく、"
        "これからも言葉を紡ぎ続けていきたいと思う。",
        "Saya kembali merasakan bahwa tindakan menulis adalah semacam "
        "perjalanan menghadapi batin diri sendiri. Penemuan yang tidak "
        "terpikirkan saat pertama kali mulai menulis, muncul satu demi "
        "satu seiring pena bergerak. Perjalanan ini tidak berakhir, dan "
        "saya ingin terus merangkai kata-kata ke depannya.",
        [
            ("文章を書くという行為は何のようなものだと実感していますか。", ["自分自身の内面と向き合う旅", "単なる作業", "簡単なこと", "誰にでもできる簡単な仕事"], 0),
            ("書き始めた当初、何が次々と現れましたか。", ["思いもよらなかった発見", "予想していた結果", "失敗だけ", "後悔だけ"], 0),
            ("筆者はこれからどうしたいと思っていますか。", ["言葉を紡ぎ続けたい", "書くのをやめたい", "他のことをしたい", "分からない"], 0),
        ],
    ),
    (
        "fukanzen_utsukushisa",
        "Esai tentang Keindahan Ketidaksempurnaan",
        "金継ぎという日本の伝統技法がある。割れた陶器を、金で装飾し"
        "ながら修復する技術だ。傷や欠けを隠すのではなく、むしろそれを"
        "美として昇華させるこの発想に、完璧さだけを追い求めがちな現代"
        "人が学ぶべきものがあるように思えてならない。",
        "Ada teknik tradisional Jepang bernama kintsugi. Ini adalah "
        "teknik memperbaiki keramik yang pecah sambil menghiasnya "
        "dengan emas. Dalam gagasan ini, bukan menyembunyikan luka atau "
        "kekurangan, melainkan justru mengangkatnya menjadi keindahan, "
        "saya tak bisa tidak merasa ada sesuatu yang harus dipelajari "
        "oleh manusia modern yang cenderung hanya mengejar "
        "kesempurnaan.",
        [
            ("金継ぎとはどんな技術ですか。", ["割れた陶器を金で装飾しながら修復する技術", "新しい陶器を作る技術", "陶器を壊す技術", "陶器を売る技術"], 0),
            ("金継ぎは傷や欠けをどう扱いますか。", ["美として昇華させる", "完全に隠す", "無視する", "恥じる"], 0),
            ("筆者は現代人が何を学ぶべきだと感じていますか。", ["完璧さだけを追い求めない発想", "もっと完璧を目指すこと", "伝統を捨てること", "何も学ぶ必要はないこと"], 0),
        ],
    ),
    (
        "kazoku_rekishi_omoni",
        "Refleksi tentang Beban Sejarah Keluarga",
        "自分の家系に連なる過去の出来事を知った時、それを背負って生きる"
        "ことの重さに戸惑いを覚えた。しかし、過去は変えられずとも、それ"
        "をどう受け止め、未来にどうつなげるかは、自分自身の手に委ねられ"
        "ているのだと、次第に思えるようになった。",
        "Saat mengetahui peristiwa masa lalu yang terkait dengan garis "
        "keluarga saya, saya merasa bingung akan beratnya hidup "
        "memikul hal itu. Namun, meskipun masa lalu tidak bisa diubah, "
        "saya perlahan mulai berpikir bahwa bagaimana menerimanya dan "
        "menghubungkannya dengan masa depan itu ada di tangan diri "
        "saya sendiri.",
        [
            ("何を知った時、戸惑いを覚えましたか。", ["自分の家系に連なる過去の出来事", "新しい仕事", "将来の計画", "友人の秘密"], 0),
            ("筆者は最初、何に戸惑いましたか。", ["それを背負って生きることの重さ", "お金の問題", "健康の問題", "時間の問題"], 0),
            ("筆者は次第に何を自分の手に委ねられていると思うようになりましたか。", ["それをどう受け止め未来につなげるか", "過去を変えること", "全てを忘れること", "誰かに任せること"], 0),
        ],
    ),
    (
        "jiyuu_ishi_tetsugaku",
        "Diskusi Filosofis tentang Kehendak Bebas",
        "私たちの選択は、本当に自らの自由意志によるものなのだろうか。"
        "あるいは、遺伝や環境によって、ある程度あらかじめ決定づけられて"
        "いるのだろうか。この問いに明確な答えはないが、少なくとも、自ら"
        "の選択に責任を持とうとする姿勢そのものに、人間の尊厳が宿って"
        "いるように思う。",
        "Apakah pilihan kita benar-benar berasal dari kehendak bebas "
        "diri sendiri? Ataukah, sampai batas tertentu sudah ditentukan "
        "sebelumnya oleh genetika atau lingkungan? Tidak ada jawaban "
        "jelas untuk pertanyaan ini, tetapi setidaknya, saya rasa "
        "martabat manusia bersemayam dalam sikap untuk bertanggung "
        "jawab atas pilihan sendiri.",
        [
            ("筆者は私たちの選択について何を問いかけていますか。", ["本当に自由意志によるものか", "常に正しいかどうか", "誰が決めるべきか", "いつ決めるべきか"], 0),
            ("この問いに明確な答えはありますか。", ["ない", "ある", "すぐに分かる", "誰にでも同じ"], 0),
            ("人間の尊厳は何に宿っているように思われますか。", ["自らの選択に責任を持とうとする姿勢", "完璧な答えを持つこと", "常に正しい選択をすること", "他人に従うこと"], 0),
        ],
    ),
    (
        "otona_imi",
        "Esai tentang Arti Menjadi Dewasa",
        "子供の頃、大人になるとは、何でも自分の思い通りにできるように"
        "なることだと思っていた。しかし実際には、自分の思い通りになら"
        "ないことを受け入れ、それでもなお前に進み続ける力を持つこと"
        "こそが、大人であることの本質なのだと今は思う。",
        "Saat kecil, saya berpikir menjadi dewasa berarti bisa "
        "melakukan apa pun sesuai kemauan sendiri. Namun sebenarnya, "
        "sekarang saya berpikir bahwa esensi menjadi dewasa adalah "
        "justru memiliki kekuatan untuk menerima hal-hal yang tidak "
        "sesuai kemauan sendiri, dan tetap terus maju.",
        [
            ("子供の頃、大人になるとは何だと思っていましたか。", ["何でも思い通りにできるようになること", "責任を持つこと", "お金を稼ぐこと", "結婚すること"], 0),
            ("今、筆者は大人であることの本質は何だと思っていますか。", ["思い通りにならないことを受け入れ前に進む力", "何でも思い通りにする力", "お金を稼ぐ力", "他人を従わせる力"], 0),
            ("この文章のテーマは何ですか。", ["大人になることの意味", "子供時代の思い出", "仕事の意味", "家族の絆"], 0),
        ],
    ),
    (
        "hikaku_bunka_hihan",
        "Kritik tentang Budaya Perbandingan Sosial",
        "他者と自分を比べることは、成長の原動力にもなり得るが、行き"
        "過ぎれば自己肯定感を蝕む諸刃の剣である。SNSが日常に浸透した"
        "現代において、他人の輝かしい一面ばかりが目に入りやすい環境が、"
        "この危うさをいっそう助長しているように思われる。",
        "Membandingkan diri dengan orang lain bisa menjadi pendorong "
        "pertumbuhan, tetapi jika berlebihan, itu adalah pedang bermata "
        "dua yang menggerogoti rasa percaya diri. Dalam era modern di "
        "mana media sosial telah menyusup ke keseharian, lingkungan "
        "yang mudah membuat kita hanya melihat sisi cemerlang orang "
        "lain saja tampaknya semakin memperburuk bahaya ini.",
        [
            ("他者と自分を比べることは何になり得ますか。", ["成長の原動力", "常に悪いこと", "意味のないこと", "お金の源"], 0),
            ("行き過ぎるとそれは何になりますか。", ["自己肯定感を蝕む諸刃の剣", "完全に良いもの", "何の影響もないもの", "幸福の源"], 0),
            ("何がこの危うさを助長していますか。", ["SNSが日常に浸透した環境", "学校教育", "家族関係", "経済状況"], 0),
        ],
    ),
    (
        "kikoenai_koe",
        "Refleksi tentang Suara yang Tak Terdengar",
        "声高に主張する者の言葉ばかりが取り上げられがちな社会において、"
        "沈黙を選ばざるを得なかった人々の声なき声に、私たちはどれほど"
        "耳を傾けられているだろうか。語られなかった言葉の中にこそ、"
        "真実の一端が隠れていることもあるはずだ。",
        "Dalam masyarakat di mana kata-kata dari mereka yang bersuara "
        "lantang cenderung selalu diangkat, seberapa besar kita bisa "
        "mendengarkan suara tanpa suara dari orang-orang yang terpaksa "
        "memilih diam? Justru dalam kata-kata yang tidak terucapkan "
        "itulah mungkin ada sepotong kebenaran yang tersembunyi.",
        [
            ("どんな者の言葉が取り上げられがちですか。", ["声高に主張する者", "沈黙を選ぶ者", "全ての人", "誰も取り上げられない"], 0),
            ("筆者は誰の声に耳を傾けるべきだと問いかけていますか。", ["沈黙を選ばざるを得なかった人々", "有名な人々", "声高な人々だけ", "誰の声も不要"], 0),
            ("何の中に真実の一端が隠れていることがありますか。", ["語られなかった言葉", "声高な主張", "ニュース報道", "統計データ"], 0),
        ],
    ),
    (
        "konnan_taikyuu",
        "Esai tentang Ketahanan dalam Kesulitan",
        "人生において困難は避けられないものであるが、それにどう向き"
        "合うかによって、その後の人生の色合いは大きく変わる。逆境その"
        "ものを消し去ることはできなくとも、それを乗り越える中で培わ"
        "れる強さこそが、何よりの財産になるのではないだろうか。",
        "Kesulitan dalam hidup tidak bisa dihindari, tetapi bagaimana "
        "menghadapinya sangat mengubah warna kehidupan selanjutnya. "
        "Meskipun kesulitan itu sendiri tidak bisa dihapus, bukankah "
        "kekuatan yang dipupuk saat mengatasinya justru menjadi harta "
        "yang paling berharga?",
        [
            ("人生において何は避けられませんか。", ["困難", "幸福", "お金", "成功"], 0),
            ("その後の人生の色合いは何によって変わりますか。", ["困難にどう向き合うか", "生まれた場所", "運", "他人の意見"], 0),
            ("何が何よりの財産になるかもしれませんか。", ["逆境を乗り越える中で培われる強さ", "お金", "名声", "逆境がないこと"], 0),
        ],
    ),
    (
        "ningen_chishiki_genkai",
        "Diskusi tentang Batas Pengetahuan Manusia",
        "科学技術がどれほど発展しようとも、私たち人間が理解できる範囲"
        "には限界がある。分かったつもりになることの危うさを自覚し、"
        "常に謙虚な姿勢で未知に向き合い続けることこそが、真の知性の証"
        "なのかもしれない。",
        "Sebanyak apa pun teknologi sains berkembang, ada batas pada "
        "apa yang bisa dipahami oleh kita manusia. Menyadari bahaya "
        "merasa sudah mengerti, dan terus menghadapi hal yang belum "
        "diketahui dengan sikap rendah hati, mungkin itulah bukti "
        "kecerdasan sejati.",
        [
            ("科学技術がどれほど発展しても、何がありますか。", ["人間が理解できる範囲の限界", "無限の可能性", "完璧な理解", "何の限界もないこと"], 0),
            ("筆者は何の危うさを自覚すべきだと述べていますか。", ["分かったつもりになること", "学ぶこと", "質問すること", "謙虚になること"], 0),
            ("何が真の知性の証かもしれませんか。", ["謙虚な姿勢で未知に向き合い続けること", "全てを知っていると主張すること", "学ぶのをやめること", "他人を批判すること"], 0),
        ],
    ),
    (
        "nokosu_ato",
        "Refleksi tentang Jejak yang Ditinggalkan",
        "自分がこの世を去った後、何が残るのだろうかと、ふと考えること"
        "がある。財産でも名声でもなく、誰かの心に灯した小さな温かさ"
        "こそが、本当の意味で後世に受け継がれていくものなのかもしれ"
        "ないと、近頃は思うようになった。",
        "Terkadang saya tiba-tiba memikirkan apa yang akan tersisa "
        "setelah saya meninggalkan dunia ini. Belakangan ini saya mulai "
        "berpikir bahwa bukan harta atau nama besar, melainkan "
        "kehangatan kecil yang dinyalakan di hati seseorang, mungkin "
        "itulah yang benar-benar diwariskan ke generasi mendatang.",
        [
            ("筆者は何についてふと考えることがありますか。", ["自分が去った後に何が残るか", "お金の使い方", "仕事の成功", "旅行の計画"], 0),
            ("筆者は何が後世に受け継がれるかもしれないと思うようになりましたか。", ["誰かの心に灯した小さな温かさ", "財産", "名声", "地位"], 0),
            ("この文章のテーマは何ですか。", ["人生で残すもの", "お金の管理", "仕事の目標", "健康法"], 0),
        ],
    ),
    (
        "imi_tankyuu_shuuketsu",
        "Esai Penutup tentang Perjalanan Mencari Makna",
        "人生の意味を求める旅に、明確な終着点はないのかもしれない。"
        "それでもなお、問い続けること自体に価値があるのだと、これまで"
        "の歩みを振り返って強く感じる。答えが見つからなくとも、探し"
        "続ける限り、人は前を向いて生きられるのだと信じている。",
        "Mungkin tidak ada titik akhir yang jelas dalam perjalanan "
        "mencari makna hidup. Meski begitu, saat merenungkan kembali "
        "perjalanan selama ini, saya merasa kuat bahwa nilai justru "
        "ada dalam tindakan terus bertanya itu sendiri. Saya percaya "
        "bahwa meskipun jawaban tidak ditemukan, selama terus mencari, "
        "manusia bisa hidup menghadap ke depan.",
        [
            ("人生の意味を求める旅には何がないかもしれませんか。", ["明確な終着点", "価値", "意味", "始まり"], 0),
            ("筆者は何自体に価値があると強く感じていますか。", ["問い続けること", "答えを見つけること", "旅を終えること", "諦めること"], 0),
            ("筆者は何を信じていますか。", ["探し続ける限り前を向いて生きられること", "すぐに答えが見つかること", "諦めるべきこと", "意味などないこと"], 0),
        ],
    ),
    (
        "seijou_kyouki_kyoukai",
        "Esai tentang Ambang Batas Antara Kewarasan dan Kegilaan",
        "正気と狂気を分かつ境界線は、実のところ驚くほど曖昧である。"
        "ある時代・ある社会で狂気とされたものが、別の文脈では単なる"
        "個性、あるいは先見の明として扱われることも少なくない。この"
        "境界線が誰によって、何のために引かれてきたのかを問い直さず"
        "にはいられない。",
        "Garis batas yang memisahkan kewarasan dan kegilaan, "
        "sebenarnya, mengejutkan betapa kaburnya. Sesuatu yang "
        "dianggap gila pada suatu zaman atau masyarakat tertentu, "
        "tidak jarang diperlakukan sebagai sekadar keunikan pribadi, "
        "atau bahkan sebagai wawasan yang jauh ke depan dalam konteks "
        "lain. Saya tidak bisa menahan diri untuk mempertanyakan "
        "kembali oleh siapa dan untuk apa garis batas ini ditarik.",
        [
            ("正気と狂気を分かつ境界線は実際どうですか。", ["驚くほど曖昧である", "非常に明確である", "科学的に定義されている", "誰にでも同じである"], 0),
            ("ある時代の狂気は、別の文脈で何として扱われることがありますか。", ["個性や先見の明", "常に病気", "常に犯罪", "何も変わらないもの"], 0),
            ("筆者は何を問い直さずにはいられませんか。", ["境界線が誰によって何のために引かれてきたか", "狂気の治療法", "正気の定義だけ", "誰が正しいか"], 0),
        ],
    ),
    (
        "kioku_mujou",
        "Refleksi tentang Kefanaan Kenangan",
        "記憶とは固定されたものではなく、思い出すたびに少しずつ書き"
        "換えられていく、儚く流動的なものだ。かつて確かにそこにあった"
        "はずの光景が、年月を経るごとに輪郭を失っていく様を見るにつけ、"
        "人は記憶の無常さにたえず向き合わされる。",
        "Kenangan bukanlah sesuatu yang tetap, melainkan sesuatu yang "
        "fana dan mengalir, yang sedikit demi sedikit ditulis ulang "
        "setiap kali diingat kembali. Setiap kali melihat bagaimana "
        "pemandangan yang dulu pasti ada di sana kehilangan konturnya "
        "seiring berjalannya waktu, manusia terus-menerus dihadapkan "
        "pada kefanaan kenangan.",
        [
            ("記憶とはどのようなものだと述べられていますか。", ["儚く流動的なもの", "永久に固定されたもの", "常に正確なもの", "誰にとっても同じもの"], 0),
            ("光景は年月を経るごとにどうなっていきますか。", ["輪郭を失っていく", "より鮮明になる", "変わらない", "消えることはない"], 0),
            ("人は何にたえず向き合わされますか。", ["記憶の無常さ", "記憶の正確さ", "記憶の永続性", "記憶の欠如"], 0),
        ],
    ),
    (
        "kutsuu_imi_tetsugaku",
        "Diskusi Filosofis tentang Makna Penderitaan",
        "苦痛そのものに意味などなく、それにどう意味を与えるかは各人に"
        "委ねられている、という立場がある一方、苦痛の経験こそが人格を"
        "深めるのだという見方も根強い。いずれにせよ、苦痛を単なる除去"
        "すべき対象としてのみ捉える態度には、疑問を呈さざるを得ない。",
        "Ada pandangan bahwa penderitaan itu sendiri tidak memiliki "
        "makna, dan bagaimana memberinya makna diserahkan pada "
        "masing-masing individu, sementara pandangan bahwa justru "
        "pengalaman penderitaanlah yang memperdalam kepribadian juga "
        "kuat bertahan. Bagaimanapun, sikap yang hanya memandang "
        "penderitaan sebagai objek yang harus disingkirkan begitu "
        "saja, mau tidak mau menimbulkan keraguan.",
        [
            ("苦痛そのものについて、どんな立場がありますか。", ["意味などなく各人が意味を与えるという立場", "誰にとっても同じ意味を持つという立場", "常に無意味だという立場", "常に罰であるという立場"], 0),
            ("もう一つの見方では、苦痛の経験は何をすると考えられていますか。", ["人格を深める", "人格を破壊するだけ", "何の影響もない", "常に避けるべきもの"], 0),
            ("筆者はどんな態度に疑問を呈しますか。", ["苦痛を単なる除去すべき対象としてのみ捉える態度", "苦痛を受け入れる態度", "苦痛について語る態度", "苦痛を研究する態度"], 0),
        ],
    ),
    (
        "bunmei_shinpo_hiniku",
        "Esai tentang Ironi Kemajuan Peradaban",
        "文明は絶えず進歩してきたはずなのに、人々の抱える不安や孤独は"
        "一向に減る気配を見せない。便利さの追求が、皮肉にも人間らしい"
        "つながりを希薄化させてきたのではないかという疑念を、拭い去る"
        "ことができない。",
        "Meskipun peradaban seharusnya terus maju, kecemasan dan "
        "kesepian yang ditanggung manusia sama sekali tidak "
        "menunjukkan tanda-tanda berkurang. Saya tidak bisa menghapus "
        "kecurigaan bahwa pengejaran kenyamanan, secara ironis, "
        "justru telah menipiskan hubungan manusiawi.",
        [
            ("文明は絶えず進歩してきたはずなのに、何が減る気配を見せませんか。", ["人々の抱える不安や孤独", "便利さ", "技術の発展", "人口"], 0),
            ("便利さの追求は、皮肉にも何をさせてきたのではないかと疑われていますか。", ["人間らしいつながりを希薄化させること", "人間関係を深めること", "不安をなくすこと", "孤独をなくすこと"], 0),
            ("筆者はどんな疑念を拭い去ることができませんか。", ["便利さの追求がつながりを希薄化させたという疑念", "文明が進歩していないという疑念", "技術が危険だという疑念", "誰も幸せではないという疑念"], 0),
        ],
    ),
    (
        "sentaku_sensei",
        "Kritik tentang Tirani Pilihan dalam Masyarakat Modern",
        "選択肢の多さは自由の証だと信じられてきたが、過剰な選択肢は"
        "むしろ人を疲弊させ、決断を先延ばしにさせる要因ともなり得る。"
        "自由であることの代償として、選ぶことそのものが一種の重荷と"
        "化しつつある現状を、看過するわけにはいかない。",
        "Banyaknya pilihan dipercaya sebagai bukti kebebasan, tetapi "
        "pilihan yang berlebihan justru bisa melelahkan orang dan "
        "menjadi faktor yang menunda-nunda keputusan. Kondisi saat "
        "ini di mana memilih itu sendiri berubah menjadi semacam "
        "beban, sebagai harga dari kebebasan, tidak bisa dibiarkan "
        "begitu saja.",
        [
            ("選択肢の多さは何の証だと信じられてきましたか。", ["自由の証", "不自由の証", "貧しさの証", "豊かさの証だけ"], 0),
            ("過剰な選択肢は人に何をさせる要因となり得ますか。", ["決断を先延ばしにすること", "即座に決断すること", "何も選ばないこと", "常に満足すること"], 0),
            ("何が一種の重荷と化しつつありますか。", ["選ぶことそのもの", "自由がないこと", "選択肢が少ないこと", "決断を早めること"], 0),
        ],
    ),
    (
        "kotoba_kanjou_kyori",
        "Refleksi tentang Jarak Antara Kata dan Perasaan",
        "どれほど言葉を尽くしても、内面にある感情を完全に伝えきること"
        "はできない。言語化された瞬間、感情はすでに本来の姿から幾分か"
        "変質してしまっているのだ。この埋めがたい隔たりを前に、人は"
        "沈黙の意味を改めて考えさせられる。",
        "Betapapun banyak kata yang digunakan, perasaan yang ada di "
        "dalam diri tidak dapat disampaikan sepenuhnya. Pada saat "
        "dibahasakan, perasaan itu sudah berubah sedikit dari "
        "bentuk aslinya. Dihadapkan pada jarak yang sulit diisi ini, "
        "manusia kembali dibuat memikirkan makna keheningan.",
        [
            ("どれほど言葉を尽くしても何ができませんか。", ["内面にある感情を完全に伝えきること", "何も伝えられないこと", "言葉を選ぶこと", "沈黙すること"], 0),
            ("言語化された瞬間、感情はどうなってしまいますか。", ["本来の姿から幾分か変質してしまう", "完全に正確になる", "何も変わらない", "消えてしまう"], 0),
            ("人はこの隔たりを前に何を改めて考えさせられますか。", ["沈黙の意味", "言葉の正確さ", "感情の強さ", "会話の重要性だけ"], 0),
        ],
    ),
    (
        "jiyuu_shibari_paradokkusu",
        "Esai tentang Paradoks Kebebasan dan Keterikatan",
        "何にも縛られない自由を追い求めた末に、人はしばしば根無し草の"
        "ような虚しさに直面する。真の自由とは、何かに深く結びつくこと"
        "を通じてしか得られないものなのかもしれないという逆説に、"
        "向き合わざるを得ない。",
        "Setelah mengejar kebebasan yang tidak terikat oleh apa pun, "
        "manusia sering menghadapi kehampaan seperti rumput yang "
        "tak berakar. Mau tidak mau harus menghadapi paradoks bahwa "
        "kebebasan sejati mungkin hanya bisa diperoleh melalui "
        "keterikatan mendalam pada sesuatu.",
        [
            ("何にも縛られない自由を追い求めた末に、人はしばしば何に直面しますか。", ["根無し草のような虚しさ", "完全な満足", "経済的な成功", "他者からの尊敬"], 0),
            ("真の自由とは何を通じてしか得られないかもしれませんか。", ["何かに深く結びつくこと", "何にも結びつかないこと", "お金を稼ぐこと", "一人で生きること"], 0),
            ("筆者はどんな逆説に向き合わざるを得ませんか。", ["自由が結びつきを通じてしか得られないという逆説", "自由が簡単に得られるという逆説", "誰も自由を求めていないという逆説", "自由に意味がないという逆説"], 0),
        ],
    ),
    (
        "kyoukan_doujou_kyoukai",
        "Diskusi tentang Batas Antara Empati dan Simpati",
        "他者の痛みに共感することと、単に同情することの間には、案外"
        "大きな隔たりがある。同情が時として相手を見下す視線を含みうる"
        "のに対し、真の共感は相手と同じ地平に立つことを要求する、はる"
        "かに困難な営みなのである。",
        "Antara berempati dengan rasa sakit orang lain dan sekadar "
        "bersimpati, ternyata ada jarak yang cukup besar. Sementara "
        "simpati terkadang bisa mengandung pandangan merendahkan "
        "pihak lain, empati sejati menuntut berdiri pada tingkat "
        "yang sama dengan lawan bicara — sebuah usaha yang jauh "
        "lebih sulit.",
        [
            ("共感することと同情することの間には何がありますか。", ["案外大きな隔たり", "全く違いがないこと", "小さな違いだけ", "常に同じ結果"], 0),
            ("同情は時として何を含みうりますか。", ["相手を見下す視線", "深い理解", "対等な立場", "尊敬の念だけ"], 0),
            ("真の共感は何を要求しますか。", ["相手と同じ地平に立つこと", "相手を見下すこと", "何もしないこと", "距離を置くこと"], 0),
        ],
    ),
    (
        "nozomarezaru_isan",
        "Refleksi tentang Warisan yang Tak Diminta",
        "私たちは、選んだ覚えのない多くのものを、先人から受け継いで"
        "生きている。それは文化や言語である場合もあれば、未解決の対立"
        "や偏見である場合もある。望まれざる遺産にどう向き合うかもまた、"
        "一つの世代の責務なのだろう。",
        "Kita hidup dengan mewarisi banyak hal dari pendahulu yang "
        "tidak pernah kita pilih sendiri. Itu bisa berupa budaya dan "
        "bahasa, tetapi bisa juga berupa konflik dan prasangka yang "
        "belum terselesaikan. Bagaimana menghadapi warisan yang tak "
        "diminta ini pun mungkin merupakan tanggung jawab satu "
        "generasi.",
        [
            ("私たちは何を先人から受け継いで生きていますか。", ["選んだ覚えのない多くのもの", "自分で選んだものだけ", "何も受け継いでいない", "お金だけ"], 0),
            ("望まれざる遺産の例として何が挙げられていますか。", ["未解決の対立や偏見", "全ての文化的成果", "経済的な豊かさだけ", "技術の進歩だけ"], 0),
            ("筆者は何が一つの世代の責務だと述べていますか。", ["望まれざる遺産にどう向き合うか", "遺産を全て拒否すること", "遺産を無視すること", "遺産を売ること"], 0),
        ],
    ),
    (
        "kako_wakai_shuuketsu",
        "Esai Akhir tentang Rekonsiliasi dengan Masa Lalu",
        "過去との和解とは、起きた出来事を美化することでも、なかった"
        "ことにすることでもない。ただ、それが確かに起きたのだと静かに"
        "認め、その上でなお前へ進むことを選び取る、地道な営みなので"
        "ある。この道のりに、近道は存在しない。",
        "Rekonsiliasi dengan masa lalu bukanlah memperindah kejadian "
        "yang telah terjadi, juga bukan menganggapnya tidak pernah "
        "ada. Itu hanyalah usaha yang tekun — mengakui dengan tenang "
        "bahwa hal itu memang telah terjadi, dan tetap memilih untuk "
        "melangkah maju setelahnya. Tidak ada jalan pintas dalam "
        "perjalanan ini.",
        [
            ("過去との和解とは何をすることではありませんか。", ["出来事を美化すること、なかったことにすること", "静かに認めること", "前へ進むこと", "地道に努力すること"], 0),
            ("過去との和解では、何を静かに認めることが求められますか。", ["それが確かに起きたということ", "それが起きなかったということ", "誰が悪いかということ", "何も認める必要がないこと"], 0),
            ("この道のりについて筆者は何と述べていますか。", ["近道は存在しない", "簡単に終わる", "誰にでもできる", "必要のないものだ"], 0),
        ],
    ),
    (
        "chinmoku_imi_kaiwa_reflection",
        "Refleksi tentang Makna Keheningan dalam Percakapan",
        "会話における沈黙は、しばしば気まずさの象徴として扱われるが、"
        "本当にそうだろうか。言葉を発さずとも、互いの存在を静かに"
        "受け止め合う時間にこそ、深い信頼が宿っているのではないかと"
        "考えずにはいられない。",
        "Keheningan dalam percakapan sering diperlakukan sebagai "
        "simbol kecanggungan, tetapi benarkah demikian? Saya tidak "
        "bisa menahan diri untuk berpikir bahwa justru di dalam waktu "
        "di mana keberadaan satu sama lain diterima dengan tenang "
        "tanpa mengucapkan kata-kata itulah kepercayaan yang mendalam "
        "bersemayam.",
        [
            ("会話における沈黙は、しばしば何の象徴として扱われますか。", ["気まずさ", "信頼", "喜び", "怒り"], 0),
            ("筆者は何を考えずにはいられませんか。", ["沈黙の時間にこそ深い信頼が宿っているのではないかということ", "沈黙は常に悪いということ", "会話は不要だということ", "言葉が最も重要だということ"], 0),
            ("筆者はどんな時間に信頼が宿ると考えていますか。", ["互いの存在を静かに受け止め合う時間", "たくさん話す時間", "一人でいる時間", "争う時間"], 0),
        ],
    ),
    (
        "rekishi_shougen_omoni_essay",
        "Esai tentang Beban Menjadi Saksi Sejarah",
        "ある出来事を直接経験した者には、それを語り継ぐという重い"
        "責務が課される。その記憶がどれほど耐えがたいものであっても、"
        "証言することをやめてしまえば、真実は静かに風化してしまう"
        "だろう。",
        "Orang yang mengalami langsung suatu peristiwa dibebani "
        "tanggung jawab berat untuk menceritakannya secara "
        "turun-temurun. Betapapun sulit ditahannya kenangan itu, jika "
        "berhenti bersaksi, kebenaran akan diam-diam terkikis oleh "
        "waktu.",
        [
            ("ある出来事を直接経験した者には何が課されますか。", ["それを語り継ぐという重い責務", "忘れる権利", "報酬", "休息"], 0),
            ("記憶がどれほど耐えがたくても、何をやめてはいけませんか。", ["証言すること", "生きること", "働くこと", "話すこと全般"], 0),
            ("証言をやめてしまうと、真実はどうなりますか。", ["静かに風化してしまう", "より明確になる", "保存される", "広まる"], 0),
        ],
    ),
    (
        "dourikan_kyoukai_tetsugaku",
        "Diskusi Filosofis tentang Batas Moralitas",
        "道徳的に正しいとされる行為の境界線は、時代や文化によって"
        "揺れ動くものであり、絶対的な基準を求めること自体に無理が"
        "あるのかもしれない。それでもなお、人はよりよい選択を模索"
        "せずにはいられない存在なのだ。",
        "Garis batas tindakan yang dianggap benar secara moral "
        "bergeser sesuai zaman dan budaya, dan mungkin memang tidak "
        "masuk akal untuk mencari standar yang absolut itu sendiri. "
        "Meski begitu, manusia adalah makhluk yang tidak bisa menahan "
        "diri untuk terus mencari pilihan yang lebih baik.",
        [
            ("道徳的に正しいとされる行為の境界線はどのようなものですか。", ["時代や文化によって揺れ動くもの", "絶対に変わらないもの", "誰にとっても同じもの", "科学的に証明できるもの"], 0),
            ("何を求めること自体に無理があるかもしれませんか。", ["絶対的な基準", "相対的な基準", "道徳そのもの", "文化の違い"], 0),
            ("人はどんな存在だと述べられていますか。", ["よりよい選択を模索せずにはいられない存在", "何も考えない存在", "常に間違える存在", "選択をしない存在"], 0),
        ],
    ),
    (
        "kanzensei_bigaku_hihyou",
        "Kritik tentang Estetika Kesempurnaan",
        "完璧であることを美とする価値観は、時に見る者を息苦しくさせ"
        "る。むしろ、わずかな歪みや不揃いさゆえに生まれる独特の趣に"
        "こそ、真の美が宿っているのではないだろうか。",
        "Nilai yang menganggap kesempurnaan sebagai keindahan "
        "terkadang membuat sesak napas orang yang melihatnya. Bukankah "
        "justru karena sedikit distorsi dan ketidakteraturan itulah, "
        "cita rasa unik yang lahir darinya adalah tempat bersemayamnya "
        "keindahan sejati?",
        [
            ("完璧であることを美とする価値観は、時に見る者にどんな影響を与えますか。", ["息苦しくさせる", "安心させる", "喜ばせるだけ", "無関心にする"], 0),
            ("何ゆえに独特の趣が生まれると述べられていますか。", ["わずかな歪みや不揃いさ", "完全な対称性", "高い技術力だけ", "高価な材料"], 0),
            ("筆者は真の美がどこに宿ると考えていますか。", ["わずかな歪みや不揃いさゆえに生まれる趣", "完璧さの中", "高価なものの中", "誰もが認めるものの中"], 0),
        ],
    ),
    (
        "furusato_imi_hourou_reflection",
        "Refleksi tentang Arti Rumah bagi Perantau",
        "故郷を離れて久しい者にとって、「家」という言葉が指す場所は、"
        "もはや一つの土地には収まらない。それゆえ、帰る場所を失った"
        "寂しさと、どこにでも根を張れる自由とを、同時に抱えながら"
        "生きることになるのだろう。",
        "Bagi orang yang sudah lama meninggalkan kampung halaman, "
        "tempat yang ditunjuk oleh kata \"rumah\" tidak lagi terkumpul "
        "dalam satu tanah. Oleh karena itu, mungkin ia hidup dengan "
        "membawa sekaligus kesepian karena kehilangan tempat pulang, "
        "dan kebebasan untuk bisa berakar di mana saja.",
        [
            ("故郷を離れて久しい者にとって、「家」はどんな場所ですか。", ["もはや一つの土地には収まらない場所", "故郷だけを指す場所", "存在しない場所", "常に同じ場所"], 0),
            ("何ゆえに二つのものを同時に抱えて生きることになりますか。", ["家という言葉が一つの土地に収まらないこと", "お金がないこと", "仕事がないこと", "家族がいないこと"], 0),
            ("二つのものとは何と何ですか。", ["帰る場所を失った寂しさと、どこにでも根を張れる自由", "お金と時間", "仕事と休息", "過去と未来だけ"], 0),
        ],
    ),
    (
        "kagaku_shinpo_hiniku_n1",
        "Esai tentang Ironi Kemajuan Ilmu Pengetahuan",
        "科学技術は人類に多くの恩恵をもたらしてきたにもかかわらず、"
        "その進歩ゆえに新たな不安や脅威が生み出されてきたこともまた"
        "事実だ。知ることは常に、失うことと表裏一体なのかもしれない。",
        "Meskipun teknologi ilmiah telah membawa banyak manfaat bagi "
        "umat manusia, fakta bahwa karena kemajuannya itulah "
        "kecemasan dan ancaman baru diciptakan juga merupakan "
        "kenyataan. Mengetahui mungkin selalu merupakan dua sisi mata "
        "uang yang sama dengan kehilangan.",
        [
            ("科学技術は人類に何をもたらしてきましたか。", ["多くの恩恵", "何ももたらさなかったこと", "不幸だけ", "停滞"], 0),
            ("何ゆえに新たな不安や脅威が生み出されてきましたか。", ["科学技術の進歩", "人口の減少", "経済の停滞", "戦争"], 0),
            ("筆者は知ることと何が表裏一体かもしれないと述べていますか。", ["失うこと", "得ること全般", "忘れること", "話すこと"], 0),
        ],
    ),
    (
        "geijutsu_jinsei_kyoukai_discussion",
        "Diskusi tentang Batas Antara Seni dan Kehidupan",
        "芸術とは日常から切り離された特別なものだと考えられがちだが、"
        "むしろ、ありふれた日々の営みの中にこそ、芸術の萌芽が潜んで"
        "いるのではないか。この境界を明確に引くことに、どれほどの"
        "意味があるのだろうか。",
        "Seni cenderung dianggap sebagai sesuatu yang istimewa dan "
        "terpisah dari keseharian, tetapi bukankah justru di dalam "
        "kegiatan sehari-hari yang biasa itulah benih seni "
        "tersembunyi? Seberapa besar makna yang ada dalam menarik "
        "batas ini secara jelas?",
        [
            ("芸術とはどんなものだと考えられがちですか。", ["日常から切り離された特別なもの", "誰にでもできる簡単なもの", "無意味なもの", "日常そのもの"], 0),
            ("筆者は芸術の萌芽がどこに潜んでいると考えていますか。", ["ありふれた日々の営みの中", "特別な場所だけ", "美術館の中だけ", "芸術家の頭の中だけ"], 0),
            ("筆者は何を問いかけていますか。", ["芸術と日常の境界を明確に引くことの意味", "芸術の値段", "芸術家の数", "美術館の役割"], 0),
        ],
    ),
    (
        "kotoba_isan_iwarezaru_reflection",
        "Refleksi tentang Warisan Kata-kata yang Tak Terucap",
        "語られなかった言葉、伝えられなかった思いは、消えてなくなる"
        "わけではない。むしろ、沈黙のまま次の世代へと受け継がれ、"
        "形を変えて現れることがあるように思えてならない。",
        "Kata-kata yang tidak diucapkan, perasaan yang tidak "
        "disampaikan, bukan berarti hilang lenyap. Justru, saya "
        "merasa tidak bisa menahan diri untuk berpikir bahwa hal itu "
        "terkadang diwariskan ke generasi berikutnya dalam keheningan, "
        "dan muncul dengan bentuk yang berubah.",
        [
            ("語られなかった言葉はどうなりますか。", ["消えてなくなるわけではない", "完全に消える", "すぐに忘れられる", "何の影響もない"], 0),
            ("語られなかった思いはどのように次の世代へ受け継がれますか。", ["沈黙のまま形を変えて", "はっきりとした言葉で", "本として", "歌として"], 0),
            ("筆者はどう思えてなりませんか。", ["沈黙のまま受け継がれ形を変えて現れること", "言葉は全て消えること", "誰も気にしないこと", "伝える必要はないこと"], 0),
        ],
    ),
    (
        "soushitsu_tsuyosa_kokoro_essay",
        "Esai tentang Ketahanan Jiwa dalam Kehilangan",
        "大きな喪失を経験した後、以前と全く同じ自分に戻ることはでき"
        "ない。それでも、失ったものの重さゆえに、かえって残された"
        "ものの尊さに気づかされることがある。悲しみは、人を弱くする"
        "だけのものではないのかもしれない。",
        "Setelah mengalami kehilangan besar, tidak mungkin kembali "
        "menjadi diri yang sama persis seperti sebelumnya. Namun "
        "demikian, justru karena beratnya apa yang hilang, terkadang "
        "kita disadarkan akan berharganya apa yang tersisa. Kesedihan "
        "mungkin bukan hanya sesuatu yang melemahkan manusia.",
        [
            ("大きな喪失を経験した後、どうなりますか。", ["以前と全く同じ自分には戻れない", "すぐに元通りになる", "何も変わらない", "もっと幸せになる"], 0),
            ("失ったものの重さゆえに、何に気づかされることがありますか。", ["残されたものの尊さ", "失ったものの価値のなさ", "悲しみの無意味さ", "何も気づかないこと"], 0),
            ("筆者は悲しみについてどう考えていますか。", ["人を弱くするだけのものではないかもしれない", "人を必ず弱くする", "何の意味もない", "避けるべきものだ"], 0),
        ],
    ),
    (
        "kojin_seikou_shinwa_hihyou",
        "Kritik tentang Mitos Kesuksesan Individual",
        "成功は個人の努力のみによってもたらされるという神話は、根強"
        "く社会に浸透している。しかし、その裏には、家庭環境や運、"
        "他者の支えといった見えにくい要素が数多く存在することを、"
        "忘れるわけにはいかない。",
        "Mitos bahwa kesuksesan hanya dibawa oleh usaha individu telah "
        "meresap kuat dalam masyarakat. Namun, di baliknya, tidak "
        "boleh dilupakan bahwa ada banyak faktor yang sulit terlihat "
        "seperti lingkungan keluarga, keberuntungan, dan dukungan "
        "orang lain.",
        [
            ("社会に根強く浸透している神話とは何ですか。", ["成功は個人の努力のみによってもたらされるという神話", "成功は運だけで決まるという神話", "誰も成功できないという神話", "努力は無意味だという神話"], 0),
            ("その神話の裏には何が存在しますか。", ["家庭環境や運、他者の支えといった見えにくい要素", "努力の量だけ", "才能だけ", "お金だけ"], 0),
            ("筆者は何を忘れるわけにはいかないと述べていますか。", ["見えにくい要素が数多く存在すること", "努力が不要だということ", "運が全てだということ", "個人の努力は無意味だということ"], 0),
        ],
    ),
]


def build_entries(entries, level_key, titles):
    assert [e[1] for e in entries] == titles, (
        f"{level_key}: authored titles don't match the locked list, in order"
    )
    result = []
    for id_suffix, title, passage_ja, passage_tr, questions in entries:
        entry_id = f"dokkai_{id_suffix}"
        built_questions = []
        for i, (prompt, options, correct_index) in enumerate(questions):
            assert 0 <= correct_index < len(options), (
                f"{entry_id}/{i}: correct_index out of range"
            )
            assert len(options) >= 2, f"{entry_id}/{i}: need at least 2 options"
            built_questions.append({
                "id": f"{entry_id}_q{i}",
                "prompt": prompt,
                "options": options,
                "correctIndex": correct_index,
            })
        result.append({
            "id": entry_id,
            "title": title,
            "jlptLevel": level_key.upper(),
            "passageJapanese": passage_ja,
            "passageTranslation": passage_tr,
            "questions": built_questions,
        })
    return result


LEVEL_ENTRIES = {
    "n5": (N5_ENTRIES, N5_TITLES),
    "n4": (N4_ENTRIES, N4_TITLES),
    "n3": (N3_ENTRIES, N3_TITLES),
    "n2": (N2_ENTRIES, N2_TITLES),
    "n1": (N1_ENTRIES, N1_TITLES),
}


def main():
    all_entries = []
    counts = {}
    for key in LEVEL_META:
        entries, titles = LEVEL_ENTRIES[key]
        built = build_entries(entries, key, titles)
        all_entries.extend(built)
        counts[key] = len(built)

    ids = [e["id"] for e in all_entries]
    assert len(ids) == len(set(ids)), "duplicate dokkai entry ids"

    with open("assets/data/dokkai_data.json", "w", encoding="utf-8") as f:
        json.dump(all_entries, f, ensure_ascii=False, indent=2)

    levels = []
    for key, (name, available) in LEVEL_META.items():
        levels.append({
            "id": name,
            "name": name,
            "available": available,
            "passageCount": counts[key] if counts[key] > 0 else None,
        })

    with open("assets/data/dokkai/_levels.json", "w", encoding="utf-8") as f:
        json.dump(levels, f, ensure_ascii=False, indent=2)

    per_level = ", ".join(f"{k.upper()}={v}" for k, v in counts.items())
    print(f"Total: {len(all_entries)} dokkai passages ({per_level})")


if __name__ == "__main__":
    main()
