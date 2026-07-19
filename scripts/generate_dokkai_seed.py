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

from dokkai_lists import LEVEL_META, N5_TITLES

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


def main():
    all_entries = build_entries(N5_ENTRIES, "n5", N5_TITLES)

    ids = [e["id"] for e in all_entries]
    assert len(ids) == len(set(ids)), "duplicate dokkai entry ids"

    with open("assets/data/dokkai_data.json", "w", encoding="utf-8") as f:
        json.dump(all_entries, f, ensure_ascii=False, indent=2)

    levels = []
    for key, (name, available) in LEVEL_META.items():
        count = len(all_entries) if key == "n5" else None
        levels.append({
            "id": name,
            "name": name,
            "available": available,
            "passageCount": count,
        })

    with open("assets/data/dokkai/_levels.json", "w", encoding="utf-8") as f:
        json.dump(levels, f, ensure_ascii=False, indent=2)

    print(f"Total: {len(all_entries)} dokkai passages, N5 only")


if __name__ == "__main__":
    main()
