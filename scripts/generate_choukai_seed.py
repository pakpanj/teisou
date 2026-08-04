# Generates assets/data/choukai_data.json + assets/data/choukai/_levels.json
# for Choukai (listening comprehension), mirroring generate_dokkai_seed.py:
# hand-authored Python tuples -> JSON matching the Dart fromJson schema.
#
# Clip tuple:     (id_suffix, title, audio_text, audio_translation,
#                  [question_tuple, ...])
# Question tuple: (prompt, [option, ...], correct_index)
#
# audio_text is what TTS speaks. It is never displayed during the exam —
# only played — so it must stand on its own as speech: no parenthetical
# stage directions, no text the ear cannot recover. Speaker turns are
# written as 「A：…」「B：…」 because the TTS reads them naturally as a
# dialogue and the learner needs to hear who is talking.
#
# Run from repo root: python scripts/generate_choukai_seed.py

import json
import re

from choukai_lists import (
    LEVEL_META,
    N1_TITLES,
    N2_TITLES,
    N3_TITLES,
    N4_TITLES,
    N5_TITLES,
)

N5_ENTRIES = [
    (
        "jam_berapa",
        "Jam Berapa Sekarang",
        "男：すみません、今何時ですか。"
        "女：今、三時半です。"
        "男：ありがとうございます。四時にバスが来ますね。"
        "女：はい、あと三十分です。",
        "Pria: Permisi, sekarang jam berapa? "
        "Wanita: Sekarang jam setengah empat. "
        "Pria: Terima kasih. Busnya datang jam empat, ya? "
        "Wanita: Ya, tiga puluh menit lagi.",
        [
            ("今、何時ですか。", ["三時半", "四時", "三時", "四時半"], 0),
            ("バスは何時に来ますか。", ["三時", "三時半", "四時", "四時半"], 2),
        ],
    ),
    (
        "cari_buku",
        "Mencari Buku di Kelas",
        "女：先生、わたしの本がありません。"
        "男：机の上を見ましたか。"
        "女：はい、見ました。ありませんでした。"
        "男：かばんの中は。"
        "女：あ、ありました。すみません。",
        "Wanita: Bu Guru, buku saya tidak ada. "
        "Pria: Sudah lihat di atas meja? "
        "Wanita: Sudah. Tidak ada. "
        "Pria: Di dalam tas? "
        "Wanita: Ah, ada. Maaf.",
        [
            ("本はどこにありましたか。", ["机の上", "かばんの中", "いすの下", "先生の机"], 1),
        ],
    ),
    (
        "sarapan",
        "Sarapan Pagi Ini",
        "男：今朝、何を食べましたか。"
        "女：パンと卵を食べました。"
        "男：牛乳は飲みましたか。"
        "女：いいえ、お茶を飲みました。",
        "Pria: Tadi pagi makan apa? "
        "Wanita: Saya makan roti dan telur. "
        "Pria: Minum susu? "
        "Wanita: Tidak, saya minum teh.",
        [
            ("女の人は何を飲みましたか。", ["牛乳", "お茶", "水", "コーヒー"], 1),
            ("女の人は何を食べましたか。",
             ["パンとご飯", "パンと卵", "卵とご飯", "パンだけ"], 1),
        ],
    ),
    (
        "berapa_harga",
        "Berapa Harganya",
        "女：すみません、このノートはいくらですか。"
        "男：百五十円です。"
        "女：じゃあ、二冊ください。"
        "男：三百円になります。",
        "Wanita: Permisi, buku catatan ini berapa? "
        "Pria: Seratus lima puluh yen. "
        "Wanita: Kalau begitu, minta dua. "
        "Pria: Jadi tiga ratus yen.",
        [
            ("ノートを何冊買いましたか。", ["一冊", "二冊", "三冊", "四冊"], 1),
            ("全部でいくらですか。", ["百五十円", "二百円", "三百円", "三百五十円"], 2),
        ],
    ),
    (
        "ulang_tahun",
        "Hari Apa Ulang Tahunmu",
        "男：誕生日はいつですか。"
        "女：七月十日です。"
        "男：わたしは七月二十日です。近いですね。"
        "女：ほんとうですね。",
        "Pria: Ulang tahunmu kapan? "
        "Wanita: Sepuluh Juli. "
        "Pria: Saya dua puluh Juli. Dekat, ya. "
        "Wanita: Iya, benar.",
        [
            ("女の人の誕生日はいつですか。",
             ["七月十日", "七月二十日", "十月七日", "二十日七月"], 0),
        ],
    ),
    (
        "di_mana_tas",
        "Di Mana Tasnya",
        "女：お母さん、わたしのかばんはどこですか。"
        "男：いすの下にありますよ。"
        "女：いすの下にありません。"
        "男：じゃあ、テーブルの上を見てください。"
        "女：ありました。ありがとう。",
        "Wanita: Ibu, tas saya di mana? "
        "Pria: Ada di bawah kursi. "
        "Wanita: Tidak ada di bawah kursi. "
        "Pria: Kalau begitu, coba lihat di atas meja. "
        "Wanita: Ada. Terima kasih.",
        [
            ("かばんはどこにありましたか。",
             ["いすの下", "テーブルの上", "机の中", "ドアの前"], 1),
        ],
    ),
    (
        "naik_apa",
        "Pergi ke Sekolah Naik Apa",
        "男：毎日、何で学校へ行きますか。"
        "女：自転車で行きます。"
        "男：雨の日も自転車ですか。"
        "女：いいえ、雨の日はバスで行きます。",
        "Pria: Setiap hari ke sekolah naik apa? "
        "Wanita: Naik sepeda. "
        "Pria: Hari hujan juga naik sepeda? "
        "Wanita: Tidak, kalau hujan naik bus.",
        [
            ("雨の日は何で学校へ行きますか。",
             ["自転車", "バス", "電車", "歩いて"], 1),
        ],
    ),
    (
        "cuaca_hari_ini",
        "Cuaca Hari Ini",
        "女：今日は寒いですね。"
        "男：そうですね。昨日は暖かかったですが。"
        "女：明日は雪が降るそうですよ。"
        "男：えっ、本当ですか。",
        "Wanita: Hari ini dingin, ya. "
        "Pria: Iya. Padahal kemarin hangat. "
        "Wanita: Katanya besok akan turun salju. "
        "Pria: Eh, benarkah?",
        [
            ("昨日の天気はどうでしたか。", ["寒かった", "暖かかった", "雪だった", "雨だった"], 1),
            ("明日はどうなりますか。", ["雨が降る", "雪が降る", "暖かくなる", "晴れる"], 1),
        ],
    ),
    (
        "berapa_keluarga",
        "Berapa Orang Keluargamu",
        "男：ご家族は何人ですか。"
        "女：四人です。父と母と弟がいます。"
        "男：お姉さんはいませんか。"
        "女：はい、いません。",
        "Pria: Keluargamu berapa orang? "
        "Wanita: Empat orang. Ada ayah, ibu, dan adik laki-laki. "
        "Pria: Tidak punya kakak perempuan? "
        "Wanita: Tidak punya.",
        [
            ("女の人の家族は何人ですか。", ["三人", "四人", "五人", "六人"], 1),
            ("女の人には誰がいますか。",
             ["姉と弟", "父と母と弟", "父と母と姉", "母と弟だけ"], 1),
        ],
    ),
    (
        "warna_payung",
        "Warna Payung Siapa",
        "女：この赤いかさは誰のですか。"
        "男：わたしのです。"
        "女：じゃあ、青いかさは。"
        "男：それは田中さんのです。",
        "Wanita: Payung merah ini punya siapa? "
        "Pria: Punya saya. "
        "Wanita: Kalau payung biru? "
        "Pria: Itu punya Tanaka.",
        [
            ("青いかさは誰のですか。",
             ["男の人", "女の人", "田中さん", "先生"], 2),
        ],
    ),
    (
        "bertemu_stasiun",
        "Bertemu di Depan Stasiun",
        "男：明日、何時に会いましょうか。"
        "女：十時はどうですか。"
        "男：いいですね。どこで会いますか。"
        "女：駅の前で会いましょう。",
        "Pria: Besok mau bertemu jam berapa? "
        "Wanita: Bagaimana kalau jam sepuluh? "
        "Pria: Boleh. Bertemu di mana? "
        "Wanita: Kita bertemu di depan stasiun.",
        [
            ("二人はどこで会いますか。",
             ["駅の中", "駅の前", "学校の前", "公園"], 1),
            ("何時に会いますか。", ["九時", "十時", "十一時", "十二時"], 1),
        ],
    ),
    (
        "makanan_tidak_suka",
        "Makanan yang Tidak Disukai",
        "女：何か嫌いな食べ物がありますか。"
        "男：はい、にんじんが嫌いです。"
        "女：野菜は全部だめですか。"
        "男：いいえ、トマトは好きです。",
        "Wanita: Ada makanan yang tidak kamu suka? "
        "Pria: Ada, saya tidak suka wortel. "
        "Wanita: Semua sayur tidak bisa? "
        "Pria: Tidak, kalau tomat saya suka.",
        [
            ("男の人が嫌いな食べ物は何ですか。",
             ["トマト", "にんじん", "野菜全部", "何もない"], 1),
        ],
    ),
    (
        "pinjam_pensil",
        "Meminjam Pensil",
        "男：すみません、えんぴつを貸してください。"
        "女：はい、どうぞ。"
        "男：ありがとうございます。あとで返します。"
        "女：ゆっくりでいいですよ。",
        "Pria: Permisi, tolong pinjamkan pensil. "
        "Wanita: Ya, silakan. "
        "Pria: Terima kasih. Nanti saya kembalikan. "
        "Wanita: Santai saja.",
        [
            ("男の人は何を借りましたか。",
             ["ノート", "えんぴつ", "けしゴム", "本"], 1),
        ],
    ),
    (
        "nomor_telepon",
        "Nomor Telepon Teman",
        "女：電話番号を教えてください。"
        "男：はい、ゼロ九ゼロの一二三四の五六七八です。"
        "女：もう一度お願いします。"
        "男：ゼロ九ゼロの一二三四の五六七八です。",
        "Wanita: Tolong beri tahu nomor teleponmu. "
        "Pria: Ya, kosong sembilan kosong, satu dua tiga empat, lima enam "
        "tujuh delapan. "
        "Wanita: Tolong sekali lagi. "
        "Pria: Kosong sembilan kosong, satu dua tiga empat, lima enam tujuh "
        "delapan.",
        [
            ("女の人は何をお願いしましたか。",
             ["番号をもう一度言うこと", "電話をかけること",
              "名前を書くこと", "住所を教えること"], 0),
        ],
    ),
    (
        "hewan_peliharaan",
        "Hewan Peliharaan di Rumah",
        "男：家で何か動物を飼っていますか。"
        "女：はい、猫が二匹います。"
        "男：犬はいませんか。"
        "女：犬はいません。猫だけです。",
        "Pria: Di rumah memelihara hewan? "
        "Wanita: Ya, ada dua ekor kucing. "
        "Pria: Tidak ada anjing? "
        "Wanita: Tidak ada anjing. Hanya kucing.",
        [
            ("女の人は何を飼っていますか。",
             ["犬が二匹", "猫が二匹", "犬と猫", "何もいない"], 1),
        ],
    ),
    (
        "pr_belum_selesai",
        "Pekerjaan Rumah Belum Selesai",
        "女：宿題はもう終わりましたか。"
        "男：いいえ、まだです。"
        "女：いつまでにしなければなりませんか。"
        "男：明日の朝までです。今晩やります。",
        "Wanita: PR-nya sudah selesai? "
        "Pria: Belum. "
        "Wanita: Harus selesai kapan? "
        "Pria: Sampai besok pagi. Nanti malam saya kerjakan.",
        [
            ("男の人はいつ宿題をしますか。",
             ["今朝", "今晩", "明日の朝", "明日の夜"], 1),
        ],
    ),
    (
        "beli_minuman",
        "Membeli Minuman",
        "男：何が飲みたいですか。"
        "女：わたしはジュースがいいです。"
        "男：じゃあ、わたしは水にします。"
        "女：すみません、ジュースを一つと水を一つください。",
        "Pria: Mau minum apa? "
        "Wanita: Saya mau jus. "
        "Pria: Kalau begitu saya pilih air putih. "
        "Wanita: Permisi, minta satu jus dan satu air putih.",
        [
            ("男の人は何を飲みますか。", ["ジュース", "水", "お茶", "牛乳"], 1),
        ],
    ),
    (
        "sakit_perut",
        "Sakit Perut di Sekolah",
        "女：先生、おなかが痛いです。"
        "男：いつからですか。"
        "女：朝からです。"
        "男：じゃあ、保健室へ行きましょう。",
        "Wanita: Bu Guru, perut saya sakit. "
        "Pria: Sejak kapan? "
        "Wanita: Sejak pagi. "
        "Pria: Kalau begitu, ayo ke ruang kesehatan.",
        [
            ("女の人はどこが痛いですか。", ["頭", "おなか", "のど", "足"], 1),
            ("二人はどこへ行きますか。",
             ["教室", "保健室", "病院", "家"], 1),
        ],
    ),
    (
        "rencana_minggu",
        "Rencana Hari Minggu",
        "男：日曜日は何をしますか。"
        "女：友だちと映画を見に行きます。"
        "男：いいですね。何時からですか。"
        "女：午後二時からです。",
        "Pria: Hari Minggu mau apa? "
        "Wanita: Pergi menonton film dengan teman. "
        "Pria: Bagus, ya. Mulai jam berapa? "
        "Wanita: Mulai jam dua siang.",
        [
            ("女の人は日曜日に何をしますか。",
             ["買い物", "映画を見る", "勉強", "散歩"], 1),
            ("何時からですか。", ["午前二時", "午後二時", "午後四時", "午前十時"], 1),
        ],
    ),
    (
        "kelas_mulai",
        "Kelas Dimulai Jam Berapa",
        "女：授業は何時に始まりますか。"
        "男：八時半に始まります。"
        "女：何時に終わりますか。"
        "男：三時に終わります。",
        "Wanita: Pelajaran mulai jam berapa? "
        "Pria: Mulai jam setengah sembilan. "
        "Wanita: Selesai jam berapa? "
        "Pria: Selesai jam tiga.",
        [
            ("授業は何時に始まりますか。",
             ["八時", "八時半", "九時", "九時半"], 1),
        ],
    ),
]

# N4 clips run longer than N5's and mix plain and polite speech, since the
# real N4 paper starts expecting a learner to follow a change of plan
# across several turns rather than catch one stated fact.
N4_ENTRIES = [
    (
        "batal_hujan",
        "Batal Pergi karena Hujan",
        "女：明日の遠足、どうなりましたか。"
        "男：雨が降りそうなので、中止になったそうです。"
        "女：えっ、楽しみにしていたのに。"
        "男：来週の土曜日にするらしいですよ。"
        "女：じゃあ、その日は空けておきます。",
        "Wanita: Bagaimana dengan tamasya besok? "
        "Pria: Katanya dibatalkan karena sepertinya akan hujan. "
        "Wanita: Eh, padahal saya sudah menantikannya. "
        "Pria: Sepertinya akan diadakan Sabtu depan. "
        "Wanita: Kalau begitu, saya kosongkan hari itu.",
        [
            ("遠足はどうなりましたか。",
             ["中止になった", "予定どおり行う", "場所が変わった", "早く始まる"], 0),
            ("遠足はいつになりましたか。",
             ["明日", "今週の土曜日", "来週の土曜日", "来月"], 2),
        ],
    ),
    (
        "salah_halte",
        "Salah Turun Halte",
        "男：あれ、ここはどこだろう。"
        "女：どうかしましたか。"
        "男：一つ前で降りてしまったみたいです。駅はどちらですか。"
        "女：この道をまっすぐ行って、二つ目の角を右です。歩いて十分ぐらいですよ。"
        "男：助かりました。ありがとうございます。",
        "Pria: Lho, ini di mana ya. "
        "Wanita: Ada apa? "
        "Pria: Sepertinya saya turun satu halte lebih awal. Stasiunnya di mana? "
        "Wanita: Lurus terus di jalan ini, lalu di tikungan kedua belok kanan. "
        "Sekitar sepuluh menit jalan kaki. "
        "Pria: Terbantu sekali. Terima kasih.",
        [
            ("男の人はどうして困っていますか。",
             ["切符をなくした", "一つ前で降りた", "道に財布を落とした", "電車が遅れた"], 1),
            ("駅までどのぐらいかかりますか。",
             ["五分ぐらい", "十分ぐらい", "二十分ぐらい", "三十分ぐらい"], 1),
        ],
    ),
    (
        "jaga_adik",
        "Meminta Tolong Menjaga Adik",
        "女：ちょっとお願いがあるんだけど。"
        "男：何。"
        "女：明日の午後、弟を見ていてくれない。買い物に行きたいの。"
        "男：何時から何時まで。"
        "女：二時から四時まで。"
        "男：いいよ。二時に行くね。",
        "Wanita: Ada yang mau saya minta tolong. "
        "Pria: Apa? "
        "Wanita: Besok siang, bisa jagakan adik saya? Saya mau pergi belanja. "
        "Pria: Dari jam berapa sampai jam berapa? "
        "Wanita: Dari jam dua sampai jam empat. "
        "Pria: Boleh. Saya datang jam dua.",
        [
            ("男の人は何をしますか。",
             ["買い物に行く", "弟の世話をする", "料理を作る", "掃除をする"], 1),
            ("何時に行きますか。", ["一時", "二時", "三時", "四時"], 1),
        ],
    ),
    (
        "barang_tertinggal",
        "Barang Tertinggal di Kereta",
        "男：すみません、電車に傘を忘れてしまったんですが。"
        "女：何時ごろの電車ですか。"
        "男：七時半ごろのです。"
        "女：色と形を教えていただけますか。"
        "男：黒くて、長いものです。"
        "女：少々お待ちください。お調べします。",
        "Pria: Permisi, payung saya tertinggal di kereta. "
        "Wanita: Kereta sekitar jam berapa? "
        "Pria: Sekitar jam setengah delapan. "
        "Wanita: Bisa beri tahu warna dan bentuknya? "
        "Pria: Hitam dan panjang. "
        "Wanita: Mohon tunggu sebentar. Saya periksa dulu.",
        [
            ("男の人は何をなくしましたか。", ["かばん", "傘", "財布", "帽子"], 1),
            ("傘はどんな傘ですか。",
             ["黒くて長い", "白くて短い", "黒くて短い", "青くて長い"], 0),
        ],
    ),
    (
        "hadiah_guru",
        "Memilih Hadiah untuk Guru",
        "女：先生へのプレゼント、何がいいと思う。"
        "男：花はどう。"
        "女：去年も花だったよ。"
        "男：じゃあ、みんなで書いたメッセージカードは。"
        "女：それ、いいね。そうしよう。",
        "Wanita: Menurutmu hadiah untuk Bu Guru apa yang bagus? "
        "Pria: Bagaimana kalau bunga? "
        "Wanita: Tahun lalu juga bunga. "
        "Pria: Kalau begitu, kartu ucapan yang ditulis semua orang? "
        "Wanita: Itu bagus. Ayo begitu.",
        [
            ("二人は何をあげることにしましたか。",
             ["花", "メッセージカード", "お菓子", "本"], 1),
            ("どうして花にしませんでしたか。",
             ["高いから", "去年も花だったから", "先生が嫌いだから", "売っていないから"], 1),
        ],
    ),
    (
        "undur_janji",
        "Janji yang Harus Diundur",
        "男：もしもし、今日の約束のことなんですが。"
        "女：はい、六時でしたよね。"
        "男：仕事が終わりそうにないので、七時に変えてもらえませんか。"
        "女：大丈夫ですよ。じゃあ、七時に同じ場所で。"
        "男：すみません、よろしくお願いします。",
        "Pria: Halo, soal janji kita hari ini. "
        "Wanita: Ya, jam enam kan? "
        "Pria: Pekerjaan sepertinya belum akan selesai, bisa diubah jadi jam tujuh? "
        "Wanita: Tidak masalah. Kalau begitu jam tujuh di tempat yang sama. "
        "Pria: Maaf ya, mohon bantuannya.",
        [
            ("約束は何時になりましたか。", ["五時", "六時", "七時", "八時"], 2),
            ("場所はどうなりましたか。",
             ["変わった", "同じ", "まだ決めていない", "駅になった"], 1),
        ],
    ),
    (
        "ke_perpustakaan",
        "Cara ke Perpustakaan Kota",
        "女：市の図書館へはどうやって行きますか。"
        "男：バスが便利ですよ。三番のバスに乗ってください。"
        "女：何番目で降りますか。"
        "男：四つ目です。降りたらすぐ右に見えます。"
        "女：分かりました。ありがとうございます。",
        "Wanita: Bagaimana caranya ke perpustakaan kota? "
        "Pria: Naik bus lebih praktis. Naiklah bus nomor tiga. "
        "Wanita: Turun di pemberhentian ke berapa? "
        "Pria: Yang keempat. Setelah turun, langsung terlihat di sebelah kanan. "
        "Wanita: Baik. Terima kasih.",
        [
            ("何番のバスに乗りますか。", ["一番", "二番", "三番", "四番"], 2),
            ("いくつ目で降りますか。", ["二つ目", "三つ目", "四つ目", "五つ目"], 2),
        ],
    ),
    (
        "lupa_dompet",
        "Lupa Membawa Dompet",
        "男：あっ、財布を家に忘れてきた。"
        "女：えっ、じゃあお昼どうするの。"
        "男：今日は我慢するよ。"
        "女：わたしが貸してあげる。明日返してくれればいいから。"
        "男：ありがとう。助かるよ。",
        "Pria: Ah, dompet saya tertinggal di rumah. "
        "Wanita: Eh, lalu makan siangnya bagaimana? "
        "Pria: Hari ini saya tahan saja. "
        "Wanita: Saya pinjamkan. Kembalikan besok saja. "
        "Pria: Terima kasih. Sangat membantu.",
        [
            ("女の人は何をしますか。",
             ["お金を貸す", "お弁当を作る", "家に取りに行く", "何もしない"], 0),
            ("男の人はいつ返しますか。", ["今日", "明日", "来週", "決めていない"], 1),
        ],
    ),
    (
        "pesan_meja",
        "Memesan Meja di Restoran",
        "女：もしもし、今晩の予約をお願いしたいんですが。"
        "男：何名様ですか。"
        "女：四人です。七時からお願いします。"
        "男：申し訳ありません、七時はいっぱいでして、七時半なら空いております。"
        "女：じゃあ、七時半でお願いします。",
        "Wanita: Halo, saya mau pesan tempat untuk malam ini. "
        "Pria: Untuk berapa orang? "
        "Wanita: Empat orang. Tolong dari jam tujuh. "
        "Pria: Mohon maaf, jam tujuh penuh, kalau setengah delapan masih ada. "
        "Wanita: Kalau begitu, setengah delapan saja.",
        [
            ("予約は何時になりましたか。",
             ["六時半", "七時", "七時半", "八時"], 2),
            ("何人で行きますか。", ["二人", "三人", "四人", "五人"], 2),
        ],
    ),
    (
        "buku_terlambat",
        "Mengembalikan Buku Terlambat",
        "男：すみません、返す日を過ぎてしまいました。"
        "女：何日過ぎましたか。"
        "男：三日です。"
        "女：三日でしたら大丈夫ですよ。次から気をつけてくださいね。"
        "男：はい、すみませんでした。",
        "Pria: Permisi, saya melewati tanggal pengembalian. "
        "Wanita: Lewat berapa hari? "
        "Pria: Tiga hari. "
        "Wanita: Kalau tiga hari tidak apa-apa. Lain kali hati-hati ya. "
        "Pria: Baik, maaf.",
        [
            ("男の人は何日遅れましたか。", ["一日", "二日", "三日", "一週間"], 2),
            ("女の人は何と言いましたか。",
             ["お金を払ってください", "大丈夫です", "もう借りられません", "本を買ってください"], 1),
        ],
    ),
    (
        "kelas_tambahan",
        "Kelas Tambahan Sepulang Sekolah",
        "女：放課後の補習、出る。"
        "男：うん、数学が苦手だから出るつもり。"
        "女：何時からだっけ。"
        "男：四時からで、一時間だって。"
        "女：じゃあ、わたしも行こうかな。",
        "Wanita: Kamu ikut kelas tambahan sepulang sekolah? "
        "Pria: Iya, saya lemah di matematika jadi berniat ikut. "
        "Wanita: Mulai jam berapa ya? "
        "Pria: Katanya dari jam empat, selama satu jam. "
        "Wanita: Kalau begitu saya ikut juga deh.",
        [
            ("補習は何時に終わりますか。", ["四時", "五時", "六時", "七時"], 1),
            ("男の人はどうして出ますか。",
             ["友だちに誘われたから", "数学が苦手だから", "先生に言われたから", "暇だから"], 1),
        ],
    ),
    (
        "jam_buka_toko",
        "Menanyakan Jam Buka Toko",
        "男：そちらは何時まで開いていますか。"
        "女：平日は八時まで、土曜日は六時までです。"
        "男：日曜日は。"
        "女：日曜日はお休みをいただいております。"
        "男：分かりました。土曜日に伺います。",
        "Pria: Toko Anda buka sampai jam berapa? "
        "Wanita: Hari kerja sampai jam delapan, Sabtu sampai jam enam. "
        "Pria: Kalau Minggu? "
        "Wanita: Hari Minggu kami tutup. "
        "Pria: Baik. Saya akan datang hari Sabtu.",
        [
            ("土曜日は何時までですか。", ["五時", "六時", "七時", "八時"], 1),
            ("男の人はいつ行きますか。", ["金曜日", "土曜日", "日曜日", "月曜日"], 1),
        ],
    ),
    (
        "teman_pindah",
        "Teman yang Pindah Sekolah",
        "女：田中さん、来月引っ越すんだって。"
        "男：えっ、本当。どこへ。"
        "女：大阪だって。お父さんの仕事の関係らしいよ。"
        "男：寂しくなるね。"
        "女：うん。みんなで手紙を書かない。",
        "Wanita: Katanya Tanaka bulan depan pindah. "
        "Pria: Eh, benarkah? Ke mana? "
        "Wanita: Katanya ke Osaka. Sepertinya karena pekerjaan ayahnya. "
        "Pria: Jadi sepi ya. "
        "Wanita: Iya. Bagaimana kalau kita semua menulis surat?",
        [
            ("田中さんはどこへ引っ越しますか。",
             ["東京", "大阪", "京都", "名古屋"], 1),
            ("女の人は何をしようと言いましたか。",
             ["写真を撮る", "手紙を書く", "パーティーをする", "プレゼントを買う"], 1),
        ],
    ),
    (
        "bantu_belanja",
        "Membantu Ibu Berbelanja",
        "男：お母さん、何か買ってくるものある。"
        "女：じゃあ、卵と牛乳をお願い。"
        "男：卵はいくつ。"
        "女：十個入りを一つ。牛乳は一本でいいわ。"
        "男：分かった。行ってくる。",
        "Pria: Ibu, ada yang perlu dibeli? "
        "Wanita: Kalau begitu, tolong telur dan susu. "
        "Pria: Telurnya berapa? "
        "Wanita: Satu pak isi sepuluh. Susunya satu botol saja. "
        "Pria: Baik. Saya berangkat.",
        [
            ("男の人は何を買いますか。",
             ["卵とパン", "卵と牛乳", "牛乳とパン", "卵だけ"], 1),
            ("牛乳を何本買いますか。", ["一本", "二本", "三本", "十本"], 0),
        ],
    ),
    (
        "kehujanan",
        "Kehujanan di Tengah Jalan",
        "女：ずぶぬれじゃない。どうしたの。"
        "男：帰る途中で急に降ってきて。"
        "女：傘は持っていなかったの。"
        "男：朝は晴れていたから置いてきちゃった。"
        "女：タオル使って。風邪ひくよ。",
        "Wanita: Kamu basah kuyup. Kenapa? "
        "Pria: Di tengah jalan pulang tiba-tiba hujan. "
        "Wanita: Tidak bawa payung? "
        "Pria: Pagi tadi cerah jadi saya tinggal. "
        "Wanita: Pakai handuk ini. Nanti masuk angin.",
        [
            ("男の人はどうしてぬれましたか。",
             ["川に落ちた", "急に雨が降った", "水をこぼした", "プールに入った"], 1),
            ("どうして傘を持っていませんでしたか。",
             ["なくしたから", "朝は晴れていたから", "重いから", "壊れたから"], 1),
        ],
    ),
    (
        "acara_kelas",
        "Menyiapkan Acara Kelas",
        "男：来週のクラス会、準備はどう。"
        "女：飲み物はもう買ったよ。お菓子はまだ。"
        "男：じゃあ、お菓子はぼくが買っておくよ。"
        "女：助かる。いすを並べるのは当日ね。"
        "男：うん、朝早く行こう。",
        "Pria: Persiapan acara kelas minggu depan bagaimana? "
        "Wanita: Minuman sudah dibeli. Camilan belum. "
        "Pria: Kalau begitu, camilan biar saya yang beli. "
        "Wanita: Terbantu. Menata kursi nanti di hari-H ya. "
        "Pria: Iya, ayo datang pagi-pagi.",
        [
            ("男の人は何を買いますか。",
             ["飲み物", "お菓子", "いす", "何も買わない"], 1),
            ("いすを並べるのはいつですか。",
             ["今日", "明日", "当日", "来月"], 2),
        ],
    ),
    (
        "sepeda_rusak",
        "Sepeda yang Rusak",
        "女：自転車、どうしたの。"
        "男：タイヤがパンクしちゃって。"
        "女：直してもらった。"
        "男：うん、店に持って行ったら、三十分で直してくれた。"
        "女：早くてよかったね。",
        "Wanita: Sepedamu kenapa? "
        "Pria: Bannya bocor. "
        "Wanita: Sudah diperbaiki? "
        "Pria: Sudah, saya bawa ke toko, tiga puluh menit selesai. "
        "Wanita: Untung cepat ya.",
        [
            ("自転車のどこが壊れましたか。",
             ["ブレーキ", "タイヤ", "ライト", "かご"], 1),
            ("直すのにどのぐらいかかりましたか。",
             ["十分", "三十分", "一時間", "一日"], 1),
        ],
    ),
    (
        "pilih_klub",
        "Memilih Klub di Sekolah",
        "男：どの部活に入るか決めた。"
        "女：まだ迷ってる。テニス部と音楽部で。"
        "男：両方見に行った。"
        "女：うん。テニスは毎日で、音楽は週三回なんだって。"
        "男：時間を考えると音楽部かもね。",
        "Pria: Sudah menentukan mau ikut klub apa? "
        "Wanita: Masih bingung. Antara klub tenis dan klub musik. "
        "Pria: Sudah lihat keduanya? "
        "Wanita: Sudah. Katanya tenis setiap hari, musik tiga kali seminggu. "
        "Pria: Kalau mempertimbangkan waktu, mungkin klub musik ya.",
        [
            ("音楽部は週に何回ありますか。",
             ["毎日", "週三回", "週二回", "週一回"], 1),
            ("女の人はどうして迷っていますか。",
             ["友だちがいないから", "時間がかかるから", "お金が高いから", "先生が怖いから"], 1),
        ],
    ),
    (
        "telepon_terlambat",
        "Menelepon karena Terlambat",
        "女：もしもし、すみません、電車が遅れていて。"
        "男：どのぐらい遅れそうですか。"
        "女：十五分ほどです。"
        "男：分かりました。先に始めていますね。"
        "女：はい、お願いします。",
        "Wanita: Halo, maaf, keretanya terlambat. "
        "Pria: Kira-kira terlambat berapa lama? "
        "Wanita: Sekitar lima belas menit. "
        "Pria: Baik. Kami mulai duluan ya. "
        "Wanita: Ya, silakan.",
        [
            ("女の人はどのぐらい遅れますか。",
             ["五分", "十分", "十五分", "三十分"], 2),
            ("男の人は何をしますか。",
             ["待っている", "先に始める", "迎えに行く", "中止する"], 1),
        ],
    ),
    (
        "rencana_piknik",
        "Rencana Piknik Bersama",
        "男：今度の休み、みんなで公園に行かない。"
        "女：いいね。お弁当は持って行く。"
        "男：うん、各自で用意しよう。"
        "女：じゃあ、わたしは飲み物を多めに持って行くね。"
        "男：ありがとう。九時に駅に集まろう。",
        "Pria: Libur nanti, bagaimana kalau kita semua ke taman? "
        "Wanita: Boleh. Bekalnya dibawa? "
        "Pria: Iya, siapkan masing-masing saja. "
        "Wanita: Kalau begitu saya bawa minuman agak banyak. "
        "Pria: Terima kasih. Kita kumpul jam sembilan di stasiun.",
        [
            ("お弁当はどうしますか。",
             ["みんなで作る", "各自で用意する", "店で買う", "持って行かない"], 1),
            ("何時にどこに集まりますか。",
             ["八時に公園", "九時に駅", "九時に公園", "十時に駅"], 1),
        ],
    ),
]

# N3 clips are longer again and ask the learner to infer a reason or a
# speaker's attitude, not just retrieve a stated fact — which is what the
# real N3 paper's 概要理解 (gist) section tests.
N3_ENTRIES = [
    (
        "alasan_jurusan",
        "Alasan Memilih Jurusan",
        "女：どうして経済学部を選んだんですか。"
        "男：最初は法学部を考えていたんですが、社会の仕組みを数字で見るほうが"
        "自分に合っていると気づいて。"
        "女：ご家族は何か言いましたか。"
        "男：父は反対しませんでしたが、就職のことは考えておきなさいと言われました。"
        "女：現実的なアドバイスですね。",
        "Wanita: Kenapa Anda memilih fakultas ekonomi? "
        "Pria: Awalnya saya mempertimbangkan fakultas hukum, tapi saya sadar "
        "melihat struktur masyarakat lewat angka lebih cocok untuk saya. "
        "Wanita: Keluarga Anda berkata apa? "
        "Pria: Ayah tidak menentang, tapi menyuruh saya memikirkan soal pekerjaan. "
        "Wanita: Nasihat yang realistis, ya.",
        [
            ("男の人が経済学部を選んだ理由は何ですか。",
             ["父にすすめられたから", "数字で社会を見るほうが合うと思ったから",
              "法学部に入れなかったから", "就職に有利だから"], 1),
            ("父親はどんな態度でしたか。",
             ["強く反対した", "反対しなかったが注意した", "とても喜んだ", "何も言わなかった"], 1),
        ],
    ),
    (
        "tetangga_berisik",
        "Keluhan tentang Tetangga Berisik",
        "男：最近、眠れていますか。"
        "女：それが、上の階の物音が夜中まで続いて。"
        "男：管理人さんには言いましたか。"
        "女：一度伝えたら少し静かになったんですが、また戻ってしまって。"
        "男：直接言うより、もう一度管理人さんを通したほうがいいと思いますよ。",
        "Pria: Akhir-akhir ini bisa tidur? "
        "Wanita: Masalahnya, suara dari lantai atas berlanjut sampai tengah malam. "
        "Pria: Sudah bilang ke pengelola? "
        "Wanita: Sudah sekali, sempat agak tenang, tapi kembali lagi. "
        "Pria: Daripada bilang langsung, sebaiknya lewat pengelola lagi.",
        [
            ("女の人は何に困っていますか。",
             ["部屋が狭いこと", "上の階の物音", "家賃が高いこと", "隣の人の態度"], 1),
            ("男の人は何をすすめましたか。",
             ["直接文句を言う", "引っ越す", "もう一度管理人に言う", "我慢する"], 2),
        ],
    ),
    (
        "menawar_pasar",
        "Menawar Harga di Pasar",
        "女：この果物、少し安くなりませんか。"
        "男：うーん、これ以上はちょっと。"
        "女：三つ買うので、まとめてお願いできませんか。"
        "男：三つですか。それなら少しだけ勉強しますよ。"
        "女：ありがとうございます。じゃあ三ついただきます。",
        "Wanita: Buah ini bisa sedikit lebih murah? "
        "Pria: Hmm, lebih dari ini agak sulit. "
        "Wanita: Saya beli tiga, bisa dihitung sekaligus? "
        "Pria: Tiga ya. Kalau begitu saya kurangi sedikit. "
        "Wanita: Terima kasih. Kalau begitu saya ambil tiga.",
        [
            ("男の人はどうして値段を下げましたか。",
             ["女の人が常連だから", "三つまとめて買うから", "古い果物だから", "閉店前だから"], 1),
        ],
    ),
    (
        "kesalahpahaman",
        "Kesalahpahaman dengan Teman",
        "男：この間のこと、怒ってる。"
        "女：怒ってはいないよ。ただ、電波が悪くて聞こえなかっただけ。"
        "男：えっ、そうだったの。返事がないから避けられていると思っていた。"
        "女：全然。むしろ心配していたよ。"
        "男：早く言えばよかったな。",
        "Pria: Soal waktu itu, kamu marah? "
        "Wanita: Tidak marah, hanya saja sambungannya buruk jadi tidak terdengar. "
        "Pria: Eh, begitu ya. Karena tidak ada balasan, saya kira dihindari. "
        "Wanita: Sama sekali tidak. Justru saya khawatir. "
        "Pria: Harusnya saya bilang lebih cepat.",
        [
            ("男の人はどう思っていましたか。",
             ["女の人に避けられている", "女の人が忙しい", "女の人が引っ越した", "女の人が怒っている"], 0),
            ("実際の理由は何でしたか。",
             ["女の人が怒っていた", "電話がつながらなかった", "女の人が忘れていた", "男の人の間違い"], 1),
        ],
    ),
    (
        "wawancara_kerja",
        "Wawancara Kerja Paruh Waktu",
        "女：週に何日ぐらい入れますか。"
        "男：平日は授業があるので、土日を中心に週三日ほどです。"
        "女：夕方の時間帯はどうですか。"
        "男：火曜と木曜なら六時以降は大丈夫です。"
        "女：分かりました。ではその条件で調整してみます。",
        "Wanita: Bisa masuk berapa hari seminggu? "
        "Pria: Hari kerja ada kuliah, jadi sekitar tiga hari terutama Sabtu-Minggu. "
        "Wanita: Bagaimana dengan waktu sore? "
        "Pria: Kalau Selasa dan Kamis, setelah jam enam bisa. "
        "Wanita: Baik. Kami akan atur dengan syarat tersebut.",
        [
            ("男の人は週に何日働けますか。",
             ["二日", "三日", "四日", "五日"], 1),
            ("平日はどうして難しいですか。",
             ["遠いから", "授業があるから", "体調が悪いから", "他の仕事があるから"], 1),
        ],
    ),
    (
        "banding_apartemen",
        "Membandingkan Dua Apartemen",
        "男：二つのうち、どちらにするか決めましたか。"
        "女：駅に近いほうは家賃が高くて、静かなほうは駅から遠いんです。"
        "男：毎日通うなら近いほうが楽ですよ。"
        "女：でも、勉強のことを考えると静かなほうが。"
        "男：確かに、そこは譲れませんね。",
        "Pria: Dari dua itu, sudah memutuskan yang mana? "
        "Wanita: Yang dekat stasiun sewanya mahal, yang tenang jauh dari stasiun. "
        "Pria: Kalau bolak-balik tiap hari, yang dekat lebih ringan. "
        "Wanita: Tapi kalau memikirkan belajar, yang tenang. "
        "Pria: Benar juga, yang itu memang tidak bisa dikompromikan.",
        [
            ("女の人が重視しているのは何ですか。",
             ["家賃の安さ", "駅からの近さ", "静かな環境", "部屋の広さ"], 2),
        ],
    ),
    (
        "perubahan_jadwal",
        "Pengumuman Perubahan Jadwal",
        "男：お知らせします。明日の説明会は、会場の都合により時間が変更になりました。"
        "十時開始の予定でしたが、午後一時からとなります。場所の変更はございません。"
        "すでにお申し込みの方には、後ほどメールでご連絡いたします。",
        "Pria: Kami umumkan. Sesi penjelasan besok waktunya berubah karena "
        "kondisi tempat. Semula dijadwalkan mulai jam sepuluh, menjadi mulai "
        "jam satu siang. Tempatnya tidak berubah. Bagi yang sudah mendaftar, "
        "kami akan menghubungi lewat surel nanti.",
        [
            ("説明会は何時からになりましたか。",
             ["十時", "十一時", "午後一時", "午後三時"], 2),
            ("何が変わりましたか。",
             ["場所だけ", "時間だけ", "場所と時間", "内容"], 1),
        ],
    ),
    (
        "minta_maaf",
        "Meminta Maaf atas Kelalaian",
        "女：先日の資料の件、確認が漏れておりました。申し訳ございません。"
        "男：いや、こちらも急に頼んだので。"
        "女：今後は提出前にもう一度見直すようにいたします。"
        "男：そうしていただけると助かります。次からお願いしますね。",
        "Wanita: Soal dokumen tempo hari, saya lalai memeriksanya. Mohon maaf. "
        "Pria: Tidak, saya juga memintanya mendadak. "
        "Wanita: Ke depan saya akan memeriksa ulang sebelum menyerahkan. "
        "Pria: Kalau begitu sangat membantu. Mulai berikutnya ya.",
        [
            ("女の人は何を約束しましたか。",
             ["早く提出すること", "提出前に見直すこと", "他の人に頼むこと", "やり直すこと"], 1),
            ("男の人の態度はどうですか。",
             ["強く怒っている", "責めずに次を求めている", "全く気にしていない", "あきらめている"], 1),
        ],
    ),
    (
        "pilih_liburan",
        "Memilih Tempat Liburan",
        "男：今年の休みはどこへ行こうか。"
        "女：去年は海だったから、今年は山はどう。"
        "男：山もいいけど、子どもが小さいから移動が長いのはね。"
        "女：それもそうね。じゃあ、近くて自然のあるところを探そう。"
        "男：うん、その方向で調べてみるよ。",
        "Pria: Liburan tahun ini mau ke mana? "
        "Wanita: Tahun lalu ke laut, tahun ini bagaimana kalau gunung? "
        "Pria: Gunung juga bagus, tapi anak masih kecil jadi perjalanan panjang agak berat. "
        "Wanita: Benar juga. Kalau begitu cari yang dekat tapi ada alamnya. "
        "Pria: Iya, saya cari ke arah situ.",
        [
            ("どうして山をやめましたか。",
             ["費用が高いから", "移動が長いから", "天気が悪いから", "去年行ったから"], 1),
            ("どんな場所を探しますか。",
             ["遠くて静かな所", "近くて自然のある所", "都会の中", "海の近く"], 1),
        ],
    ),
    (
        "tugas_kelompok",
        "Diskusi Tugas Kelompok",
        "女：発表の担当、どう分けようか。"
        "男：資料作りとしゃべるの、分けたほうがいいと思う。"
        "女：わたし、人前で話すのは苦手だから資料をやろうかな。"
        "男：じゃあ、ぼくが前で話すよ。まとめは二人で確認しよう。"
        "女：うん、それなら安心。",
        "Wanita: Pembagian tugas presentasi bagaimana? "
        "Pria: Menurutku sebaiknya dipisah antara membuat materi dan berbicara. "
        "Wanita: Saya kurang bisa bicara di depan orang, jadi saya ambil materi. "
        "Pria: Kalau begitu saya yang bicara di depan. Kesimpulannya kita cek berdua. "
        "Wanita: Iya, kalau begitu saya tenang.",
        [
            ("女の人は何を担当しますか。",
             ["前で話す", "資料を作る", "両方", "何もしない"], 1),
            ("まとめはどうしますか。",
             ["男の人だけ", "女の人だけ", "二人で確認する", "先生に頼む"], 2),
        ],
    ),
    (
        "kartu_hilang",
        "Mengurus Kartu yang Hilang",
        "男：カードをなくしてしまったんですが。"
        "女：まず、ご利用を止める手続きが必要です。お名前と生年月日をお願いします。"
        "男：はい。再発行にはどのぐらいかかりますか。"
        "女：一週間から十日ほどです。お急ぎでしたら窓口でのお受け取りも可能です。"
        "男：では、窓口でお願いします。",
        "Pria: Kartu saya hilang. "
        "Wanita: Pertama, perlu proses pemblokiran. Mohon nama dan tanggal lahir. "
        "Pria: Baik. Penerbitan ulang butuh berapa lama? "
        "Wanita: Sekitar satu minggu sampai sepuluh hari. Kalau terburu-buru, "
        "bisa juga diambil di loket. "
        "Pria: Kalau begitu, lewat loket saja.",
        [
            ("最初に何をしますか。",
             ["再発行を申し込む", "利用を止める", "警察に行く", "新しい口座を作る"], 1),
            ("男の人はどうやって受け取りますか。",
             ["郵送", "窓口", "家まで配達", "決めていない"], 1),
        ],
    ),
    (
        "menolak_sopan",
        "Menolak Ajakan dengan Sopan",
        "女：今週末の食事会、来られますか。"
        "男：せっかくのお誘いなんですが、その日は家族の用事がありまして。"
        "女：そうですか、残念です。"
        "男：また次の機会にぜひ誘ってください。"
        "女：もちろんです。声をかけますね。",
        "Wanita: Bisa datang ke acara makan akhir pekan ini? "
        "Pria: Sayang sekali ajakannya, tapi hari itu ada urusan keluarga. "
        "Wanita: Begitu ya, sayang sekali. "
        "Pria: Lain kali tolong ajak saya lagi. "
        "Wanita: Tentu. Nanti saya kabari.",
        [
            ("男の人はどうして行けませんか。",
             ["仕事があるから", "家族の用事があるから", "体調が悪いから", "遠いから"], 1),
            ("男の人はどんな気持ちですか。",
             ["もう誘ってほしくない", "次は参加したい", "怒っている", "興味がない"], 1),
        ],
    ),
    (
        "rencana_masa_depan",
        "Membicarakan Rencana Masa Depan",
        "男：卒業したらどうするか、もう決めた。"
        "女：就職するつもりだったんだけど、最近は進学も考えていて。"
        "男：どうして迷ってるの。"
        "女：もう少し専門的に勉強したい気持ちが出てきたの。でも費用のこともあって。"
        "男：焦らずに、両方調べてから決めればいいよ。",
        "Pria: Sudah menentukan mau apa setelah lulus? "
        "Wanita: Awalnya berniat bekerja, tapi belakangan mempertimbangkan lanjut studi. "
        "Pria: Kenapa ragu? "
        "Wanita: Muncul keinginan belajar lebih mendalam. Tapi ada juga soal biaya. "
        "Pria: Jangan terburu-buru, teliti keduanya dulu baru putuskan.",
        [
            ("女の人が迷っている理由は何ですか。",
             ["家族の反対", "勉強したい気持ちと費用", "友だちの意見", "成績が悪いこと"], 1),
            ("男の人は何とアドバイスしましたか。",
             ["すぐ就職する", "急がずに調べる", "進学をやめる", "先生に聞く"], 1),
        ],
    ),
    (
        "komplain_rusak",
        "Komplain Barang Rusak",
        "女：先週届いた品物なんですが、箱を開けたら傷がありまして。"
        "男：ご迷惑をおかけしました。写真をお送りいただけますか。"
        "女：はい、すぐ送ります。交換していただけますか。"
        "男：確認の上、新しいものをお送りします。今の品物は着払いでご返送ください。"
        "女：分かりました。",
        "Wanita: Barang yang datang minggu lalu, waktu kotaknya dibuka ada lecet. "
        "Pria: Mohon maaf atas ketidaknyamanannya. Bisa kirimkan fotonya? "
        "Wanita: Ya, saya kirim sekarang. Bisa ditukar? "
        "Pria: Setelah kami periksa, kami kirimkan yang baru. Barang yang sekarang "
        "mohon dikembalikan dengan ongkos ditanggung kami. "
        "Wanita: Baik.",
        [
            ("女の人は最初に何をしますか。",
             ["品物を送り返す", "写真を送る", "店に行く", "お金を払う"], 1),
            ("返送の費用はだれが払いますか。",
             ["女の人", "店", "半分ずつ", "だれも払わない"], 1),
        ],
    ),
    (
        "cara_pakai_alat",
        "Menjelaskan Cara Memakai Alat",
        "男：この機械、どうやって使うんですか。"
        "女：まず電源を入れて、画面が緑になるまで待ってください。"
        "男：緑になったら。"
        "女：それから紙をここに入れて、青いボタンを押します。"
        "男：赤いボタンは。"
        "女：それは止めるときだけ使ってください。",
        "Pria: Mesin ini cara pakainya bagaimana? "
        "Wanita: Pertama nyalakan, tunggu sampai layarnya hijau. "
        "Pria: Setelah hijau? "
        "Wanita: Lalu masukkan kertas di sini, dan tekan tombol biru. "
        "Pria: Kalau tombol merah? "
        "Wanita: Itu hanya dipakai saat menghentikan.",
        [
            ("紙を入れる前に何をしますか。",
             ["青いボタンを押す", "画面が緑になるまで待つ", "赤いボタンを押す", "電源を切る"], 1),
            ("赤いボタンはいつ使いますか。",
             ["始めるとき", "止めるとき", "紙を入れるとき", "いつでも"], 1),
        ],
    ),
    (
        "kebiasaan_makan",
        "Perubahan Kebiasaan Makan",
        "女：最近、外食が減ったって聞いたけど。"
        "男：うん、自分で作るようになってから、体調がいいんだ。"
        "女：時間かかって大変じゃない。"
        "男：休みの日にまとめて作っておくから、平日は温めるだけ。"
        "女：なるほど、それなら続けられそうね。",
        "Wanita: Katanya belakangan kamu jarang makan di luar. "
        "Pria: Iya, sejak masak sendiri, kondisi badan jadi bagus. "
        "Wanita: Tidak repot karena makan waktu? "
        "Pria: Saya masak sekaligus di hari libur, jadi hari kerja tinggal dihangatkan. "
        "Wanita: Oh begitu, kalau begitu bisa bertahan ya.",
        [
            ("男の人はどうして外食が減りましたか。",
             ["お金がないから", "自分で作ると体調がいいから", "店が遠いから", "味が嫌いだから"], 1),
            ("平日はどうしていますか。",
             ["毎日作る", "温めるだけ", "外で買う", "食べない"], 1),
        ],
    ),
    (
        "pindah_kota",
        "Pindah ke Kota Lain",
        "男：来月から仙台勤務になりました。"
        "女：急ですね。ご家族も一緒に。"
        "男：いえ、子どもの学校のことがあるので、しばらく単身です。"
        "女：それは大変ですね。どのぐらいの予定ですか。"
        "男：二年ほどと聞いています。",
        "Pria: Mulai bulan depan saya ditugaskan di Sendai. "
        "Wanita: Mendadak ya. Keluarga ikut? "
        "Pria: Tidak, karena urusan sekolah anak, untuk sementara saya sendiri. "
        "Wanita: Berat ya. Rencananya berapa lama? "
        "Pria: Saya dengar sekitar dua tahun.",
        [
            ("男の人はどうして一人で行きますか。",
             ["家が狭いから", "子どもの学校があるから", "家族が反対したから", "短い期間だから"], 1),
            ("どのぐらい行きますか。",
             ["半年", "一年", "二年", "三年"], 2),
        ],
    ),
    (
        "syarat_pendaftaran",
        "Menanyakan Syarat Pendaftaran",
        "女：申し込みに必要なものを教えていただけますか。"
        "男：写真が二枚と、身分証明書のコピーが必要です。"
        "女：写真のサイズは決まっていますか。"
        "男：はい、たて四センチ、よこ三センチでお願いします。三か月以内のものです。"
        "女：分かりました。用意します。",
        "Wanita: Bisa beri tahu apa saja yang diperlukan untuk mendaftar? "
        "Pria: Perlu dua lembar foto dan fotokopi kartu identitas. "
        "Wanita: Ukuran fotonya ditentukan? "
        "Pria: Ya, tolong 3 x 4 sentimeter. Yang diambil dalam tiga bulan terakhir. "
        "Wanita: Baik. Saya siapkan.",
        [
            ("写真は何枚必要ですか。", ["一枚", "二枚", "三枚", "四枚"], 1),
            ("写真についての条件は何ですか。",
             ["白黒であること", "三か月以内のもの", "笑顔であること", "大きいもの"], 1),
        ],
    ),
    (
        "atur_waktu",
        "Kesulitan Mengatur Waktu",
        "男：アルバイトと勉強、両立できてる。"
        "女：正直に言うと、あまりうまくいってなくて。"
        "男：どっちを減らすか考えた。"
        "女：バイトを週一回減らそうと思ってる。生活は少し厳しくなるけど。"
        "男：体を壊すよりいいと思うよ。",
        "Pria: Kerja sambilan dan belajar, bisa jalan dua-duanya? "
        "Wanita: Terus terang, tidak terlalu berjalan baik. "
        "Pria: Sudah dipikirkan mau kurangi yang mana? "
        "Wanita: Saya berniat mengurangi kerja satu hari seminggu. Hidup jadi agak ketat sih. "
        "Pria: Lebih baik daripada sampai sakit.",
        [
            ("女の人はどうするつもりですか。",
             ["勉強を減らす", "バイトを週一回減らす", "両方やめる", "何も変えない"], 1),
            ("男の人はどう思っていますか。",
             ["やめるべきではない", "健康のほうが大切", "もっと働くべき", "興味がない"], 1),
        ],
    ),
    (
        "sampaikan_pesan",
        "Menyampaikan Pesan dari Orang Lain",
        "女：山田さんから伝言です。明日の会議、資料を十部用意してほしいとのことです。"
        "男：十部ですね。カラーですか。"
        "女：白黒でいいそうです。それから、開始が三十分早まったそうです。"
        "男：分かりました。九時半ですね。ありがとうございます。",
        "Wanita: Ada pesan dari Yamada. Untuk rapat besok, tolong siapkan sepuluh "
        "eksemplar dokumen. "
        "Pria: Sepuluh ya. Berwarna? "
        "Wanita: Katanya hitam putih saja. Lalu, mulainya dimajukan tiga puluh menit. "
        "Pria: Baik. Jadi jam setengah sepuluh ya. Terima kasih.",
        [
            ("資料は何部必要ですか。", ["五部", "十部", "十五部", "二十部"], 1),
            ("会議は何時に始まりますか。",
             ["九時", "九時半", "十時", "十時半"], 1),
        ],
    ),
]
N2_ENTRIES = []
N1_ENTRIES = []


# Everything the TTS speaks, and every option the learner reads, must be
# Japanese: kana, kanji, Japanese punctuation, digits, spaces. This guard
# exists because a first authoring pass leaked stray Cyrillic and Hangul
# into three clips and one answer option (「связ…いや、connection」,「안…」,
# 「новую…カードを買う」). Nothing downstream would have caught it — the JSON
# was valid, the app rendered it, and the TTS would simply have read
# gibberish aloud to a child.
_JP_OK = re.compile(r'^[　-〿぀-ヿ一-鿿'
                    r'＀-￯0-9\s]*$')


def assert_japanese(text, where):
    assert _JP_OK.match(text), (
        "%s contains non-Japanese characters: %r"
        % (where, sorted({c for c in text if not _JP_OK.match(c)})))


def build(entries, level, titles):
    assert len(entries) == len(titles), (
        "%s: %d clips authored but %d titles locked"
        % (level, len(entries), len(titles))
    )
    out = []
    for i, (suffix, title, audio, translation, questions) in enumerate(entries):
        assert title == titles[i], (
            "%s clip %d: title %r does not match the locked list entry %r"
            % (level, i + 1, title, titles[i])
        )
        assert questions, "%s/%s has no questions" % (level, suffix)
        assert_japanese(audio, "%s/%s audioText" % (level, suffix))
        qs = []
        for j, (prompt, options, correct) in enumerate(questions):
            assert_japanese(prompt, "%s/%s q%d prompt" % (level, suffix, j + 1))
            for opt in options:
                assert_japanese(opt, "%s/%s q%d option %r" % (level, suffix, j + 1, opt))
            assert len(options) >= 2, "%s/%s q%d needs >=2 options" % (level, suffix, j)
            assert len(set(options)) == len(options), (
                "%s/%s q%d has a duplicate option" % (level, suffix, j))
            assert 0 <= correct < len(options), (
                "%s/%s q%d correctIndex out of range" % (level, suffix, j))
            qs.append({
                "id": "choukai_%s_%s_q%d" % (level.lower(), suffix, j + 1),
                "prompt": prompt,
                "options": list(options),
                "correctIndex": correct,
            })
        out.append({
            "id": "choukai_%s_%s" % (level.lower(), suffix),
            "title": title,
            "jlptLevel": level,
            "audioText": audio,
            "audioTranslation": translation,
            "questions": qs,
        })
    return out


def main():
    all_entries = []
    counts = {}
    for level, entries, titles in [
        ("N5", N5_ENTRIES, N5_TITLES),
        ("N4", N4_ENTRIES, N4_TITLES),
        ("N3", N3_ENTRIES, N3_TITLES),
        ("N2", N2_ENTRIES, N2_TITLES),
        ("N1", N1_ENTRIES, N1_TITLES),
    ]:
        built = build(entries, level, titles)
        all_entries += built
        counts[level] = len(built)

    ids = [e["id"] for e in all_entries]
    assert len(set(ids)) == len(ids), "duplicate clip id"
    qids = [q["id"] for e in all_entries for q in e["questions"]]
    assert len(set(qids)) == len(qids), "duplicate question id"

    with open("assets/data/choukai_data.json", "w", encoding="utf-8") as f:
        json.dump(all_entries, f, ensure_ascii=False, indent=2)

    levels = [
        {
            "id": key,
            "name": name,
            "available": counts[key] > 0,
            "clipCount": counts[key] or None,
        }
        for key, name in LEVEL_META
    ]
    with open("assets/data/choukai/_levels.json", "w", encoding="utf-8") as f:
        json.dump(levels, f, ensure_ascii=False, indent=2)

    print("Wrote %d Choukai clips (%s) and %d questions."
          % (len(all_entries),
             ", ".join("%s: %d" % (k, v) for k, v in counts.items()),
             len(qids)))


if __name__ == "__main__":
    main()
