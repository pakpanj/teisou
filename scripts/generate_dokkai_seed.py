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
