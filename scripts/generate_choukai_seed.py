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
# N2 moves into workplace, public-announcement and news registers, and
# starts asking what a speaker *concluded* or *decided* rather than what
# was literally said — the shift the real N2 paper makes.
N2_ENTRIES = [
    (
        "rute_bus",
        "Pengumuman Perubahan Rute Bus",
        "女：ご利用のお客様にお知らせいたします。来月一日より、五番系統の経路が"
        "一部変更となります。市役所前を経由せず、中央病院を通る経路に変わります。"
        "所要時間はこれまでより五分ほど短縮される見込みです。"
        "なお、運賃の変更はございません。",
        "Wanita: Pemberitahuan bagi para pengguna. Mulai tanggal satu bulan depan, "
        "rute jalur nomor lima berubah sebagian. Tidak lagi melewati depan balai "
        "kota, melainkan melalui Rumah Sakit Pusat. Waktu tempuh diperkirakan "
        "berkurang sekitar lima menit. Adapun tarif tidak berubah.",
        [
            ("経路はどう変わりますか。",
             ["市役所前を通るようになる", "中央病院を通るようになる",
              "駅を通らなくなる", "変更はない"], 1),
            ("運賃はどうなりますか。",
             ["高くなる", "安くなる", "変わらない", "来月決まる"], 2),
        ],
    ),
    (
        "evaluasi_proyek",
        "Rapat Evaluasi Proyek",
        "男：今回の企画、売上は目標に届きませんでした。"
        "女：ただ、若い層の反応は想定以上でしたよね。"
        "男：ええ。数字だけ見れば失敗ですが、次につながる材料は得られたと思います。"
        "女：では、方向性は維持したまま、宣伝の方法を見直すということで。"
        "男：はい、その線で進めましょう。",
        "Pria: Untuk proyek kali ini, penjualan tidak mencapai target. "
        "Wanita: Tapi respons kalangan muda melebihi perkiraan, kan. "
        "Pria: Ya. Kalau hanya melihat angka ini kegagalan, tapi saya rasa kita "
        "dapat bahan untuk langkah berikutnya. "
        "Wanita: Kalau begitu, arah tetap dipertahankan, cara promosinya ditinjau ulang. "
        "Pria: Ya, mari lanjut dengan garis itu.",
        [
            ("二人は今回の企画をどう評価していますか。",
             ["完全な失敗", "数字は届かないが収穫はあった",
              "目標を大きく超えた", "評価できない"], 1),
            ("次に何を変えますか。",
             ["企画の方向性", "宣伝の方法", "担当者", "価格"], 1),
        ],
    ),
    (
        "keluhan_pelanggan",
        "Menanggapi Keluhan Pelanggan",
        "女：先ほどのお客様、かなりお怒りでしたね。"
        "男：ええ。ただ、話を伺うと、対応が遅かったことより、"
        "連絡がなかったことに不満を持たれていたようです。"
        "女：確かに、途中経過をお伝えしていませんでした。"
        "男：今後は、解決前でも状況をこまめにお知らせするようにしましょう。",
        "Wanita: Pelanggan tadi cukup marah, ya. "
        "Pria: Ya. Tapi setelah mendengarkan, tampaknya beliau tidak puas bukan "
        "karena penanganannya lambat, melainkan karena tidak ada kabar. "
        "Wanita: Benar, kita tidak menyampaikan perkembangannya. "
        "Pria: Ke depan, mari kabari situasinya secara berkala meski belum selesai.",
        [
            ("お客様は何に一番不満でしたか。",
             ["対応が遅かったこと", "連絡がなかったこと",
              "値段が高かったこと", "態度が悪かったこと"], 1),
            ("これからどうしますか。",
             ["対応を速くする", "解決前でも状況を知らせる",
              "担当者を替える", "返金する"], 1),
        ],
    ),
    (
        "kerja_jarak_jauh",
        "Kebijakan Kerja Jarak Jauh",
        "男：在宅勤務、続けたほうがいいと思いますか。"
        "女：全面的に戻すのは現実的ではないでしょう。"
        "ただ、新人の育成という点では、対面のほうが明らかに効率がいい。"
        "男：では、週の半分は出社という形が妥当でしょうか。"
        "女：そのあたりが落としどころだと思います。",
        "Pria: Menurut Anda kerja dari rumah sebaiknya dilanjutkan? "
        "Wanita: Mengembalikan sepenuhnya rasanya tidak realistis. "
        "Namun dari sisi pembinaan karyawan baru, tatap muka jelas lebih efisien. "
        "Pria: Kalau begitu, setengah minggu masuk kantor apakah wajar? "
        "Wanita: Saya rasa di sekitar situlah titik temunya.",
        [
            ("女の人の意見はどれですか。",
             ["全面的に在宅にする", "全面的に出社に戻す",
              "半分ずつが妥当", "決められない"], 2),
            ("対面が有利なのはどんな点ですか。",
             ["費用", "新人の育成", "会議の速さ", "顧客対応"], 1),
        ],
    ),
    (
        "hasil_survei",
        "Presentasi Hasil Survei",
        "女：調査の結果をご報告します。利用者の満足度は昨年より三ポイント上昇しました。"
        "一方、二十代の回答だけを見ると、わずかに低下しています。"
        "自由記述では、操作が分かりにくいという指摘が最も多く見られました。"
        "改善の優先順位は、この点に置くべきだと考えます。",
        "Wanita: Saya laporkan hasil survei. Tingkat kepuasan pengguna naik tiga "
        "poin dibanding tahun lalu. Sebaliknya, jika hanya melihat responden usia "
        "dua puluhan, justru turun sedikit. Pada isian bebas, keluhan paling banyak "
        "adalah pengoperasian yang sulit dipahami. Saya rasa prioritas perbaikan "
        "harus diletakkan pada titik ini.",
        [
            ("二十代の満足度はどうでしたか。",
             ["三ポイント上がった", "少し下がった", "変わらなかった", "大きく上がった"], 1),
            ("何を優先して改善しますか。",
             ["価格", "操作の分かりやすさ", "宣伝", "対応の速さ"], 1),
        ],
    ),
    (
        "negosiasi_tenggat",
        "Negosiasi Tenggat Waktu",
        "男：納期を一週間延ばしていただくことはできませんか。"
        "女：うちも先方との約束がありますので、一週間は厳しいですね。"
        "男：では、三日ではいかがでしょう。"
        "女：三日でしたら、なんとか調整できると思います。"
        "ただし、それ以上は難しいとお考えください。",
        "Pria: Bisakah tenggat diperpanjang satu minggu? "
        "Wanita: Kami juga punya janji dengan pihak sana, jadi satu minggu berat. "
        "Pria: Kalau tiga hari bagaimana? "
        "Wanita: Kalau tiga hari, rasanya bisa diatur. "
        "Namun mohon dipahami lebih dari itu sulit.",
        [
            ("納期は何日延びますか。", ["三日", "五日", "一週間", "延びない"], 0),
            ("女の人の立場はどうですか。",
             ["自由に決められる", "先方との約束がある",
              "延長に反対している", "興味がない"], 1),
        ],
    ),
    (
        "pindah_karier",
        "Wawancara tentang Pindah Karier",
        "女：長年勤めた会社を辞めるのは、迷いませんでしたか。"
        "男：正直、給料のことを考えると不安はありました。"
        "ただ、このまま定年まで同じ仕事を続ける自分を想像したときに、"
        "後悔するほうが怖いと感じたんです。"
        "女：決め手はご自身の気持ちだったんですね。",
        "Wanita: Meninggalkan perusahaan tempat Anda lama bekerja, tidak ragu? "
        "Pria: Terus terang, memikirkan gaji ada rasa cemas. "
        "Tapi ketika membayangkan diri saya terus mengerjakan hal yang sama sampai "
        "pensiun, saya merasa lebih takut menyesal. "
        "Wanita: Jadi penentunya adalah perasaan Anda sendiri.",
        [
            ("男の人が転職を決めた理由は何ですか。",
             ["給料が上がるから", "後悔するほうが怖かったから",
              "会社が倒産したから", "家族に言われたから"], 1),
            ("男の人の不安は何でしたか。",
             ["人間関係", "収入", "住む場所", "健康"], 1),
        ],
    ),
    (
        "prosedur_asuransi",
        "Penjelasan Prosedur Asuransi",
        "男：保険金の請求には、まず所定の用紙をご提出いただきます。"
        "その際、医師の診断書を添えてください。"
        "書類がそろってから、審査に通常二週間ほどかかります。"
        "不備があった場合は、その都度ご連絡いたしますので、"
        "審査期間はさらに延びることになります。",
        "Pria: Untuk klaim asuransi, pertama serahkan formulir yang ditentukan. "
        "Saat itu, mohon lampirkan surat keterangan dokter. "
        "Setelah dokumen lengkap, penelaahan biasanya memakan sekitar dua minggu. "
        "Jika ada kekurangan, kami akan menghubungi setiap kali, sehingga masa "
        "penelaahan akan bertambah lama.",
        [
            ("用紙と一緒に何が必要ですか。",
             ["領収書", "医師の診断書", "身分証明書", "写真"], 1),
            ("不備があるとどうなりますか。",
             ["請求が無効になる", "審査期間が延びる",
              "手数料がかかる", "すぐ支払われる"], 1),
        ],
    ),
    (
        "cuaca_ekstrem",
        "Laporan Cuaca Ekstrem",
        "女：今夜から明日未明にかけて、記録的な大雨が予想されます。"
        "特に山沿いの地域では、土砂災害の危険が高まる見込みです。"
        "河川の増水も懸念されますので、川の近くにお住まいの方は"
        "早めの避難をご検討ください。不要不急の外出はお控えください。",
        "Wanita: Dari malam ini hingga dini hari besok, diperkirakan hujan sangat "
        "lebat yang memecahkan rekor. Terutama di wilayah sepanjang pegunungan, "
        "bahaya tanah longsor diperkirakan meningkat. Kenaikan air sungai juga "
        "dikhawatirkan, jadi warga yang tinggal di dekat sungai mohon "
        "mempertimbangkan mengungsi lebih awal. Hindari bepergian yang tidak mendesak.",
        [
            ("どの地域が特に危険ですか。",
             ["海の近く", "山沿い", "都市の中心", "駅の周辺"], 1),
            ("川の近くの人はどうするべきですか。",
             ["家にとどまる", "早めに避難する", "水を用意する", "窓を閉める"], 1),
        ],
    ),
    (
        "rencana_keuangan",
        "Konsultasi Rencana Keuangan",
        "男：老後に向けて、何から始めればいいでしょうか。"
        "女：まず、毎月の支出を把握することです。"
        "投資の話はその後で構いません。"
        "男：やはり貯金より投資のほうがいいのでしょうか。"
        "女：どちらが良いかではなく、目的と期間によって選ぶものです。",
        "Pria: Untuk masa tua, sebaiknya mulai dari mana? "
        "Wanita: Pertama, pahami pengeluaran bulanan Anda. "
        "Soal investasi bisa setelah itu. "
        "Pria: Apakah investasi memang lebih baik daripada menabung? "
        "Wanita: Bukan soal mana yang lebih baik, melainkan dipilih menurut tujuan "
        "dan jangka waktunya.",
        [
            ("女の人は最初に何をすすめましたか。",
             ["投資を始める", "支出を把握する", "保険に入る", "銀行を変える"], 1),
            ("投資と貯金について女の人はどう言っていますか。",
             ["投資のほうが良い", "貯金のほうが良い",
              "目的と期間で選ぶ", "どちらも必要ない"], 2),
        ],
    ),
    (
        "ulasan_buku",
        "Ulasan Buku di Radio",
        "女：今週ご紹介する一冊は、地方の食文化を追った記録です。"
        "文章は決して読みやすいとは言えません。"
        "しかし、著者が十年かけて集めた聞き書きの厚みは、"
        "他の本では味わえないものがあります。"
        "手軽さを求める方には向きませんが、腰を据えて読む価値はあります。",
        "Wanita: Satu buku yang saya perkenalkan minggu ini adalah catatan yang "
        "menelusuri budaya kuliner daerah. Tulisannya sama sekali tidak bisa "
        "dibilang mudah dibaca. Namun ketebalan hasil wawancara yang dikumpulkan "
        "penulis selama sepuluh tahun punya sesuatu yang tidak bisa dirasakan di "
        "buku lain. Tidak cocok bagi yang mencari bacaan ringan, tapi layak dibaca "
        "dengan serius.",
        [
            ("この本の文章はどうですか。",
             ["とても読みやすい", "読みやすいとは言えない",
              "短くて簡単", "写真が中心"], 1),
            ("どんな人に向いていますか。",
             ["手軽さを求める人", "じっくり読む人", "子ども", "料理を作る人"], 1),
        ],
    ),
    (
        "alasan_penundaan",
        "Menjelaskan Alasan Penundaan",
        "男：開催を延期することになった経緯をご説明します。"
        "当初は会場の都合が理由だと考えておりましたが、"
        "実際には出演者の日程調整がつかなかったことが決定的でした。"
        "会場は確保できていましたので、その点は問題ではありません。",
        "Pria: Saya jelaskan latar belakang keputusan menunda penyelenggaraan. "
        "Semula kami mengira alasannya adalah kondisi tempat, tetapi sebenarnya "
        "yang menentukan adalah tidak tercapainya penyesuaian jadwal para pengisi "
        "acara. Tempat sudah berhasil diamankan, jadi hal itu bukan masalah.",
        [
            ("延期の決定的な理由は何でしたか。",
             ["会場が取れなかった", "出演者の日程が合わなかった",
              "参加者が少なかった", "天気が悪かった"], 1),
            ("会場についてはどうでしたか。",
             ["確保できていた", "確保できなかった", "変更した", "まだ探している"], 0),
        ],
    ),
    (
        "daur_ulang",
        "Program Daur Ulang Lingkungan",
        "女：分別の徹底を呼びかけていますが、なかなか浸透しませんね。"
        "男：ルールが細かすぎるという声もあります。"
        "女：ただ、簡単にすれば再利用できる資源が減ってしまう。"
        "男：住民説明会を増やして、理由まで伝えることが先だと思います。",
        "Wanita: Kami mengimbau pemilahan yang ketat, tapi sulit meresap ya. "
        "Pria: Ada juga suara yang bilang aturannya terlalu rinci. "
        "Wanita: Tapi kalau disederhanakan, sumber daya yang bisa didaur ulang berkurang. "
        "Pria: Menurut saya yang didahulukan adalah memperbanyak sosialisasi warga "
        "dan menyampaikan sampai ke alasannya.",
        [
            ("男の人は何をすべきだと言っていますか。",
             ["ルールを簡単にする", "説明会を増やして理由を伝える",
              "罰金を取る", "分別をやめる"], 1),
            ("ルールを簡単にすると何が起きますか。",
             ["費用が増える", "再利用できる資源が減る",
              "住民が怒る", "何も変わらない"], 1),
        ],
    ),
    (
        "keselamatan_kerja",
        "Pengarahan Keselamatan Kerja",
        "男：作業前の点検を必ず行ってください。"
        "特に、高所での作業では、命綱の取り付けを二人で確認することが原則です。"
        "一人での確認は認められません。"
        "また、体調がすぐれない場合は、無理をせず申し出てください。"
        "作業を止める判断は、誰が行っても構いません。",
        "Pria: Mohon selalu lakukan pemeriksaan sebelum bekerja. "
        "Khususnya untuk pekerjaan di ketinggian, prinsipnya pemasangan tali "
        "pengaman diperiksa oleh dua orang. Pemeriksaan seorang diri tidak diizinkan. "
        "Selain itu, jika kondisi badan kurang baik, jangan memaksakan diri, laporkan. "
        "Keputusan menghentikan pekerjaan boleh diambil oleh siapa pun.",
        [
            ("命綱の確認は何人で行いますか。",
             ["一人", "二人", "三人", "決まりはない"], 1),
            ("作業を止める判断はだれができますか。",
             ["責任者だけ", "誰でもできる", "二人以上のとき", "医師だけ"], 1),
        ],
    ),
    (
        "kritik_atasan",
        "Menanggapi Kritik Atasan",
        "女：さっき部長に指摘されたこと、落ち込んでる。"
        "男：内容は厳しかったけど、人格を否定されたわけじゃないよ。"
        "女：そうだけど、みんなの前で言われたのがつらくて。"
        "男：その点は確かに配慮が足りなかったと思う。"
        "でも、指摘そのものは的を射ていたんじゃないかな。",
        "Wanita: Soal yang ditegur manajer tadi, saya jadi murung. "
        "Pria: Isinya memang keras, tapi bukan berarti kepribadianmu disangkal. "
        "Wanita: Iya sih, tapi berat karena dikatakan di depan semua orang. "
        "Pria: Untuk hal itu memang saya rasa kurang pertimbangan. "
        "Tapi tegurannya sendiri bukankah tepat sasaran?",
        [
            ("男の人は指摘の内容についてどう思っていますか。",
             ["間違っている", "的を射ている", "どうでもいい", "厳しすぎる"], 1),
            ("男の人が問題だと認めたのはどの点ですか。",
             ["指摘の内容", "みんなの前で言ったこと",
              "部長の態度全体", "女の人の仕事"], 1),
        ],
    ),
    (
        "penarikan_produk",
        "Pengumuman Penarikan Produk",
        "女：このたび、一部の商品に不具合が見つかりましたのでお知らせいたします。"
        "対象となるのは、三月から五月までに製造されたものです。"
        "健康への影響は確認されておりませんが、念のため使用を中止し、"
        "お手元の品をご返送ください。送料は当社が負担いたします。",
        "Wanita: Kali ini kami umumkan bahwa ditemukan cacat pada sebagian produk. "
        "Yang menjadi sasaran adalah yang diproduksi antara Maret hingga Mei. "
        "Dampak terhadap kesehatan belum terkonfirmasi, namun demi kehati-hatian "
        "mohon hentikan pemakaian dan kembalikan barang yang ada pada Anda. "
        "Ongkos kirim ditanggung perusahaan kami.",
        [
            ("対象の商品はいつ作られたものですか。",
             ["一月から三月", "三月から五月", "五月から七月", "全部"], 1),
            ("送料はだれが払いますか。",
             ["客", "会社", "半分ずつ", "店"], 1),
        ],
    ),
    (
        "renovasi_gedung",
        "Rencana Renovasi Gedung",
        "男：改修工事の期間中、業務はどうなりますか。"
        "女：全面的に休むのではなく、階ごとに順番に進める予定です。"
        "男：では、利用者への影響は限定的ということですね。"
        "女：ええ。ただ、エレベーターが一基使えなくなる期間があるため、"
        "混雑が予想されます。",
        "Pria: Selama masa renovasi, bagaimana dengan operasional? "
        "Wanita: Bukan berhenti total, rencananya dikerjakan bergiliran per lantai. "
        "Pria: Jadi dampak ke pengguna terbatas ya. "
        "Wanita: Ya. Hanya saja, ada periode satu lift tidak bisa dipakai, "
        "sehingga diperkirakan padat.",
        [
            ("工事はどのように行いますか。",
             ["全面的に休む", "階ごとに順番に", "夜だけ", "一気に終わらせる"], 1),
            ("何が問題になりそうですか。",
             ["騒音", "エレベーターの混雑", "費用", "駐車場"], 1),
        ],
    ),
    (
        "petani_lokal",
        "Wawancara Petani Lokal",
        "女：後継者不足が言われていますが、実感はありますか。"
        "男：ええ。ただ、若い人が来ないというより、"
        "来ても続けられる仕組みがないことが問題だと思っています。"
        "収入が安定しなければ、いくら意欲があっても難しい。"
        "女：受け入れる側の準備が問われているということですね。",
        "Wanita: Katanya kekurangan penerus, apakah Anda merasakannya? "
        "Pria: Ya. Tapi menurut saya masalahnya bukan anak muda tidak datang, "
        "melainkan tidak ada sistem yang membuat mereka bisa bertahan setelah datang. "
        "Kalau pendapatan tidak stabil, sekuat apa pun niatnya tetap sulit. "
        "Wanita: Jadi yang dipertanyakan adalah kesiapan pihak yang menerima.",
        [
            ("男の人が考える問題は何ですか。",
             ["若い人が来ないこと", "来ても続けられる仕組みがないこと",
              "土地が足りないこと", "技術がないこと"], 1),
            ("何が安定しないと難しいですか。",
             ["天気", "収入", "人間関係", "設備"], 1),
        ],
    ),
    (
        "sistem_antrean",
        "Perubahan Sistem Antrean",
        "男：受付方法が変わったそうですね。"
        "女：はい。これまでは並んでいただいていましたが、"
        "今後は番号札をお取りいただく形になります。"
        "男：待ち時間は短くなりますか。"
        "女：待ち時間そのものは変わりません。"
        "ただ、席を離れてお待ちいただけるようになります。",
        "Pria: Katanya cara pendaftaran berubah. "
        "Wanita: Ya. Selama ini Anda mengantre berdiri, mulai sekarang menjadi "
        "mengambil nomor antrean. "
        "Pria: Apakah waktu tunggu jadi lebih singkat? "
        "Wanita: Waktu tunggunya sendiri tidak berubah. "
        "Hanya saja, Anda bisa menunggu sambil meninggalkan tempat duduk.",
        [
            ("待ち時間はどうなりますか。",
             ["短くなる", "長くなる", "変わらない", "予約制になる"], 2),
            ("新しい方法の利点は何ですか。",
             ["料金が安い", "席を離れて待てる", "予約できる", "優先される"], 1),
        ],
    ),
    (
        "anggaran_tahunan",
        "Diskusi Anggaran Tahunan",
        "女：来年度の予算ですが、広報費を削るという案が出ています。"
        "男：短期的には効果が見えにくい費用ですからね。"
        "女：ただ、削った翌年に問い合わせが激減した例もあります。"
        "男：であれば、一律に削るのではなく、"
        "効果が測れるものを残す形が現実的でしょう。",
        "Wanita: Soal anggaran tahun depan, muncul usulan memangkas biaya humas. "
        "Pria: Memang biaya yang efeknya sulit terlihat dalam jangka pendek. "
        "Wanita: Tapi ada juga contoh di mana setahun setelah dipangkas, "
        "pertanyaan masuk anjlok drastis. "
        "Pria: Kalau begitu, bukan memangkas rata, tapi menyisakan yang efeknya "
        "terukur rasanya lebih realistis.",
        [
            ("男の人の提案はどれですか。",
             ["広報費を全部削る", "効果が測れるものを残す",
              "予算を増やす", "来年決める"], 1),
            ("削った場合、過去に何が起きましたか。",
             ["売上が上がった", "問い合わせが激減した",
              "何も起きなかった", "費用が増えた"], 1),
        ],
    ),
]

# N1 uses lecture, interview and panel registers, and asks for the
# speaker's underlying position or the argument's structure — the level
# where "what was said" and "what was meant" come apart.
N1_ENTRIES = [
    (
        "demografi",
        "Kuliah tentang Perubahan Demografi",
        "男：人口減少をめぐる議論は、しばしば労働力の不足に集中しがちです。"
        "しかし、真に検討すべきは、社会の前提そのものが揺らいでいる点でしょう。"
        "たとえば、右肩上がりの成長を前提に設計された制度は、"
        "人口が縮小する局面では機能しにくい。"
        "数を補うことばかりを論じても、制度の設計思想を見直さなければ、"
        "同じ問題が形を変えて現れるだけです。",
        "Pria: Perdebatan seputar penurunan populasi kerap terpusat pada kekurangan "
        "tenaga kerja. Namun yang sesungguhnya perlu ditelaah adalah goyahnya premis "
        "masyarakat itu sendiri. Misalnya, sistem yang dirancang dengan premis "
        "pertumbuhan yang terus menanjak sulit berfungsi pada fase populasi menyusut. "
        "Sebanyak apa pun kita membahas soal menambal jumlah, jika filosofi rancangan "
        "sistemnya tidak ditinjau ulang, masalah yang sama hanya akan muncul dalam "
        "bentuk lain.",
        [
            ("話し手が最も重要だと考えているのは何ですか。",
             ["労働力を増やすこと", "制度の設計思想を見直すこと",
              "出生率を上げること", "移民を受け入れること"], 1),
            ("話し手は現在の議論をどう見ていますか。",
             ["十分である", "論点が偏っている",
              "早すぎる", "終わっている"], 1),
        ],
    ),
    (
        "kecerdasan_buatan",
        "Debat soal Kecerdasan Buatan",
        "女：技術の進歩を止めることはできません。規制よりも活用を急ぐべきです。"
        "男：私は逆に、急ぐことのほうが危ういと考えます。"
        "問題は技術そのものではなく、責任の所在が曖昧なまま普及することです。"
        "女：しかし、慎重になりすぎて機会を失う損失も無視できないでしょう。"
        "男：それは承知の上です。ただ、失敗の代償が個人に降りかかる構造は"
        "先に正すべきだと申し上げている。",
        "Wanita: Kemajuan teknologi tidak bisa dihentikan. Daripada regulasi, "
        "pemanfaatannya harus dipercepat. "
        "Pria: Saya justru menganggap tergesa-gesa itulah yang berbahaya. "
        "Masalahnya bukan teknologinya, melainkan penyebarannya sementara letak "
        "tanggung jawab masih kabur. "
        "Wanita: Tapi kerugian karena kehilangan kesempatan akibat terlalu hati-hati "
        "juga tidak bisa diabaikan. "
        "Pria: Itu saya pahami. Hanya saja saya menyatakan bahwa struktur di mana "
        "harga kegagalan jatuh ke individu harus dibereskan lebih dulu.",
        [
            ("男の人が問題視しているのは何ですか。",
             ["技術そのもの", "責任の所在が曖昧なこと",
              "普及の速さだけ", "費用"], 1),
            ("二人の意見の違いはどこにありますか。",
             ["技術の価値", "何を優先して整えるか",
              "規制の内容", "対象となる分野"], 1),
        ],
    ),
    (
        "kebijakan_pendidikan",
        "Ulasan Kebijakan Pendidikan",
        "女：今回の改革は、評価方法の多様化をうたっています。"
        "理念としては歓迎すべきものです。"
        "ただ、現場の教員数が変わらないまま評価項目だけが増えれば、"
        "結局は形式的な処理に陥りかねません。"
        "理念の正しさと、それを支える条件の整備は、別の問題として論じる必要があります。",
        "Wanita: Reformasi kali ini mengusung diversifikasi metode penilaian. "
        "Sebagai gagasan, itu patut disambut. "
        "Namun jika jumlah guru di lapangan tidak berubah sementara butir penilaian "
        "bertambah, ujungnya bisa jatuh menjadi pemrosesan yang formalitas belaka. "
        "Kebenaran gagasan dan penyiapan syarat yang menopangnya perlu dibahas "
        "sebagai dua hal yang berbeda.",
        [
            ("話し手は改革の理念をどう評価していますか。",
             ["間違っている", "歓迎すべきである",
              "判断できない", "時代遅れである"], 1),
            ("話し手が懸念しているのは何ですか。",
             ["理念が誤っていること", "条件が整わないまま項目が増えること",
              "教員の反対", "費用の増加"], 1),
        ],
    ),
    (
        "peneliti_iklim",
        "Wawancara Peneliti Iklim",
        "男：予測の不確実性を理由に対策を先延ばしする議論をどうご覧になりますか。"
        "女：不確実であることと、何も分からないことは同義ではありません。"
        "幅を持った予測であっても、取るべき方向は十分に示されています。"
        "むしろ、確実になるまで待つという姿勢自体が、"
        "選択肢を狭めていくという点を見落としてはならないでしょう。",
        "Pria: Bagaimana Anda memandang argumen yang menunda penanggulangan dengan "
        "alasan ketidakpastian prediksi? "
        "Wanita: Tidak pasti dan tidak tahu apa-apa bukanlah hal yang sama. "
        "Sekalipun prediksinya berupa rentang, arah yang harus diambil sudah cukup "
        "ditunjukkan. Justru sikap menunggu sampai pasti itu sendiri, kita tidak "
        "boleh mengabaikan bahwa ia mempersempit pilihan.",
        [
            ("女の人の主張はどれですか。",
             ["予測が確実になるまで待つべきだ", "不確実でも方向は示されている",
              "予測は役に立たない", "対策は不要である"], 1),
            ("待つ姿勢の問題点は何だと言っていますか。",
             ["費用が増える", "選択肢が狭まる",
              "信頼を失う", "研究が止まる"], 1),
        ],
    ),
    (
        "tren_konsumsi",
        "Analisis Tren Konsumsi",
        "男：所有から利用へ、という言葉が広く使われています。"
        "ただ、統計を見ると、全世代で一様に進んでいるわけではない。"
        "特に地方では、移動手段の制約から所有の優位は依然として大きい。"
        "都市部の現象を全体の潮流と読み替えることには、慎重であるべきです。",
        "Pria: Ungkapan dari memiliki ke memakai dipakai secara luas. "
        "Namun jika melihat statistik, pergeseran itu tidak berlangsung seragam di "
        "semua generasi. Khususnya di daerah, karena keterbatasan sarana transportasi, "
        "keunggulan memiliki masih besar. Kita harus berhati-hati membaca fenomena "
        "perkotaan sebagai arus keseluruhan.",
        [
            ("話し手は何に注意を促していますか。",
             ["統計が古いこと", "都市部の現象を全体と見なすこと",
              "所有が消えること", "地方の人口減少"], 1),
            ("地方で所有が優位な理由は何ですか。",
             ["価格が安いから", "移動手段の制約があるから",
              "習慣が古いから", "情報が少ないから"], 1),
        ],
    ),
    (
        "etika_jurnalistik",
        "Diskusi Etika Jurnalistik",
        "女：速報性を重んじるあまり、確認が後回しになる例が目立ちます。"
        "男：ただ、遅らせれば正確になるという単純な話でもない。"
        "女：もちろんです。問題は、誤りが判明したあとの扱いでしょう。"
        "訂正が元の記事と同じ重さで届かなければ、"
        "読者の理解は最初の印象のまま残ってしまう。",
        "Wanita: Karena terlalu mementingkan kecepatan, contoh di mana verifikasi "
        "dikesampingkan makin menonjol. "
        "Pria: Tapi bukan berarti sesederhana menunda lalu jadi akurat. "
        "Wanita: Tentu saja. Masalahnya adalah penanganan setelah kekeliruan diketahui. "
        "Jika ralat tidak sampai dengan bobot yang sama seperti artikel aslinya, "
        "pemahaman pembaca akan tertinggal pada kesan pertama.",
        [
            ("女の人が最も問題視しているのは何ですか。",
             ["速報を出すこと", "訂正が十分に届かないこと",
              "記者の数", "読者の態度"], 1),
            ("男の人はどんな指摘をしましたか。",
             ["遅らせれば正確になるとは限らない", "速報をやめるべきだ",
              "訂正は不要だ", "読者に責任がある"], 0),
        ],
    ),
    (
        "memori_kolektif",
        "Ceramah tentang Memori Kolektif",
        "男：ある出来事がどう記憶されるかは、起きた事実だけで決まるわけではありません。"
        "誰がそれを語り継ぐ立場にあったかが、輪郭を形づくります。"
        "記録が残っているから記憶されるのではなく、"
        "記憶しようとする力が働いた結果として記録が残る。"
        "この順序を取り違えると、沈黙している領域を見落とすことになります。",
        "Pria: Bagaimana suatu peristiwa diingat tidak ditentukan hanya oleh fakta "
        "yang terjadi. Siapa yang berada pada posisi mewariskan ceritanya itulah yang "
        "membentuk garis besarnya. Bukan karena catatan tersisa lalu diingat, "
        "melainkan catatan tersisa sebagai hasil bekerjanya daya untuk mengingat. "
        "Jika urutan ini tertukar, kita akan melewatkan wilayah yang membisu.",
        [
            ("話し手の主張はどれですか。",
             ["記録があるから記憶される", "記憶しようとする力が記録を残す",
              "事実だけが重要である", "記憶は個人のものである"], 1),
            ("順序を取り違えるとどうなりますか。",
             ["記録が失われる", "沈黙している領域を見落とす",
              "事実が変わる", "議論が終わる"], 1),
        ],
    ),
    (
        "pelestarian_warisan",
        "Perdebatan Pelestarian Warisan",
        "女：建物を当時のまま残すことが保存だと考えられがちです。"
        "男：しかし、使われなくなった建物は急速に傷みます。"
        "女：ええ。ですから、用途を変えてでも使い続けるほうが、"
        "結果として長く残ることがある。"
        "男：保存と活用を対立させる見方こそ、"
        "見直されるべきなのかもしれません。",
        "Wanita: Kerap dianggap bahwa melestarikan berarti membiarkan bangunan tetap "
        "seperti aslinya. "
        "Pria: Padahal bangunan yang tidak lagi dipakai rusak dengan cepat. "
        "Wanita: Ya. Karena itu, terus memakainya meski dengan mengubah fungsi "
        "kadang justru membuatnya bertahan lebih lama. "
        "Pria: Justru cara pandang yang mempertentangkan pelestarian dan pemanfaatan "
        "itulah yang mungkin perlu ditinjau ulang.",
        [
            ("二人の結論はどれですか。",
             ["当時のまま残すべきだ", "保存と活用は対立しない",
              "建物は壊すべきだ", "結論は出ていない"], 1),
            ("使われない建物はどうなりますか。",
             ["価値が上がる", "急速に傷む", "変わらない", "安全になる"], 1),
        ],
    ),
    (
        "ekonomi_triwulan",
        "Laporan Ekonomi Triwulan",
        "女：今期の成長率は前期を上回りました。"
        "ただし、内訳を見ると、伸びの大半は一時的な要因によるものです。"
        "設備投資は横ばいにとどまり、企業の先行き判断は依然として慎重です。"
        "数字の改善をそのまま基調の転換と受け取るのは、時期尚早でしょう。",
        "Wanita: Tingkat pertumbuhan periode ini melampaui periode sebelumnya. "
        "Namun jika dilihat rinciannya, sebagian besar kenaikan berasal dari faktor "
        "sementara. Investasi peralatan hanya mendatar, dan penilaian perusahaan "
        "terhadap prospek masih berhati-hati. Menerima perbaikan angka begitu saja "
        "sebagai pembalikan tren rasanya masih terlalu dini.",
        [
            ("成長の主な要因は何ですか。",
             ["設備投資", "一時的な要因", "輸出", "消費の拡大"], 1),
            ("話し手の判断はどれですか。",
             ["基調が転換した", "転換と見るのは早い",
              "悪化している", "判断できない"], 1),
        ],
    ),
    (
        "sutradara_film",
        "Wawancara Sutradara Film",
        "男：観客に分かりやすく伝えることを意識されますか。"
        "女：分かりやすさを目的にすると、作品が説明に寄っていくんです。"
        "私はむしろ、見終わったあとに残る違和感を大切にしたい。"
        "その場で理解されなくても、何年か経って腑に落ちることがある。"
        "そういう時間の幅を持てるのが映像の強みだと思っています。",
        "Pria: Apakah Anda memikirkan penyampaian yang mudah dipahami penonton? "
        "Wanita: Kalau kemudahan dijadikan tujuan, karyanya jadi condong ke penjelasan. "
        "Saya justru ingin menjaga rasa janggal yang tersisa setelah menonton. "
        "Meski tidak dipahami saat itu juga, beberapa tahun kemudian bisa saja mengena. "
        "Bisa memiliki rentang waktu seperti itulah yang saya anggap kekuatan film.",
        [
            ("女の人は分かりやすさをどう考えていますか。",
             ["最も重要である", "目的にすると説明的になる",
              "全く不要である", "観客が決めること"], 1),
            ("女の人が大切にしているのは何ですか。",
             ["すぐ理解されること", "あとに残る違和感",
              "興行成績", "批評家の評価"], 1),
        ],
    ),
    (
        "bahasa_punah",
        "Kuliah tentang Bahasa yang Punah",
        "男：言語が消えるとき、失われるのは単語の一覧ではありません。"
        "その言語でしか区別されてこなかった世界の切り分け方が消えるのです。"
        "翻訳できる部分だけを移し替えて保存したと考えるなら、"
        "それは記録であって継承ではない。"
        "話者の生活の中で使われ続けることと、"
        "資料として残ることは、まったく別の事柄です。",
        "Pria: Ketika sebuah bahasa lenyap, yang hilang bukanlah daftar kosakata. "
        "Yang lenyap adalah cara memilah dunia yang selama ini hanya dibedakan dalam "
        "bahasa itu. Jika kita menganggap telah melestarikan dengan memindahkan hanya "
        "bagian yang bisa diterjemahkan, itu adalah pencatatan, bukan pewarisan. "
        "Terus dipakai dalam kehidupan penuturnya dan tersisa sebagai bahan dokumentasi "
        "adalah dua hal yang sama sekali berbeda.",
        [
            ("話し手によると、言語が消えると何が失われますか。",
             ["単語の一覧", "世界の切り分け方", "文字", "音の記録"], 1),
            ("記録と継承の違いは何ですか。",
             ["費用がかかるかどうか", "生活の中で使われ続けるかどうか",
              "誰が行うか", "量の多さ"], 1),
        ],
    ),
    (
        "reformasi_hukum",
        "Diskusi Reformasi Hukum",
        "女：条文を細かくすれば公正になる、という前提には疑問があります。"
        "男：解釈の余地を残すと、恣意的な運用を招くという指摘もありますが。"
        "女：ええ。ただ、想定外の事例が必ず生じる以上、"
        "余地をなくすことは不可能です。"
        "重要なのは、判断の理由が公開され、検証できることではないでしょうか。",
        "Wanita: Saya meragukan premis bahwa merinci pasal akan membuatnya adil. "
        "Pria: Ada juga yang menunjukkan bahwa menyisakan ruang tafsir mengundang "
        "penerapan yang sewenang-wenang. "
        "Wanita: Ya. Tapi selama kasus di luar dugaan pasti muncul, menghapus ruang "
        "itu mustahil. Yang penting bukankah alasan putusannya dipublikasikan dan "
        "dapat diperiksa?",
        [
            ("女の人が最も重視しているのは何ですか。",
             ["条文を細かくすること", "判断の理由が検証できること",
              "解釈をなくすこと", "罰を重くすること"], 1),
            ("女の人はなぜ余地をなくせないと言いますか。",
             ["費用がかかるから", "想定外の事例が必ず生じるから",
              "国民が反対するから", "前例がないから"], 1),
        ],
    ),
    (
        "konsumen_digital",
        "Analisis Perilaku Konsumen Digital",
        "男：選択肢が増えれば満足度も上がると考えられてきました。"
        "しかし実際には、比較に費やす労力が増えるほど、"
        "決定後の満足は下がる傾向が見られます。"
        "つまり、豊富さそのものが価値なのではなく、"
        "選び終えられる設計になっているかどうかが問われている。",
        "Pria: Selama ini dianggap bahwa bertambahnya pilihan menaikkan kepuasan. "
        "Namun kenyataannya, makin besar tenaga yang dihabiskan untuk membandingkan, "
        "makin terlihat kecenderungan kepuasan setelah memutuskan justru menurun. "
        "Artinya, bukan kelimpahan itu sendiri yang bernilai, melainkan yang "
        "dipertanyakan adalah apakah rancangannya memungkinkan orang selesai memilih.",
        [
            ("話し手の結論はどれですか。",
             ["選択肢は多いほどよい", "選び終えられる設計が重要",
              "選択肢をなくすべき", "価格が最も重要"], 1),
            ("比較の労力が増えると何が起きますか。",
             ["満足が上がる", "満足が下がる", "購入が増える", "変化はない"], 1),
        ],
    ),
    (
        "arsitektur_kota",
        "Ceramah tentang Arsitektur Kota",
        "女：広場をつくれば人が集まる、という発想は素朴すぎます。"
        "人が滞在するかどうかを決めるのは、面積ではなく、"
        "腰を下ろせる場所が影の中にあるかといった、きわめて具体的な条件です。"
        "設計図の上で美しい空間が、実際には誰にも使われないという例は"
        "枚挙にいとまがありません。",
        "Wanita: Gagasan bahwa membuat alun-alun akan mengumpulkan orang terlalu naif. "
        "Yang menentukan orang betah atau tidak bukanlah luasnya, melainkan syarat "
        "yang sangat konkret seperti apakah ada tempat duduk yang berada di bawah "
        "bayangan. Contoh ruang yang indah di atas gambar rancangan tapi nyatanya "
        "tidak dipakai siapa pun tak terhitung banyaknya.",
        [
            ("人の滞在を決めるのは何だと言っていますか。",
             ["広さ", "具体的な条件", "デザインの美しさ", "費用"], 1),
            ("話し手は設計図中心の発想をどう見ていますか。",
             ["正しい", "不十分である", "新しい", "費用が高い"], 1),
        ],
    ),
    (
        "sumber_energi",
        "Perdebatan Sumber Energi",
        "男：安定供給を重視するなら、選択肢を絞るべきではありません。"
        "女：ただ、分散させれば安心という発想も危うい。"
        "それぞれの供給網が同じ弱点を抱えていれば、"
        "数を増やしても同時に止まります。"
        "男：確かに、独立性の低い分散は分散とは言えませんね。",
        "Pria: Kalau mementingkan pasokan yang stabil, seharusnya pilihan tidak "
        "dipersempit. "
        "Wanita: Namun gagasan bahwa menyebarkan berarti aman juga berbahaya. "
        "Jika masing-masing jaringan pasokan menyimpan kelemahan yang sama, "
        "sebanyak apa pun jumlahnya akan berhenti bersamaan. "
        "Pria: Benar, penyebaran yang rendah kemandiriannya memang tidak bisa "
        "disebut penyebaran.",
        [
            ("女の人が指摘した危険は何ですか。",
             ["選択肢が少ないこと", "供給網が同じ弱点を持つこと",
              "費用が高いこと", "技術が古いこと"], 1),
            ("二人が最終的に一致したのはどの点ですか。",
             ["数を増やせばよい", "独立性が伴わない分散は意味が薄い",
              "一つに絞るべき", "議論を続ける"], 1),
        ],
    ),
    (
        "penulis_veteran",
        "Wawancara Penulis Veteran",
        "女：長く書き続けてこられた原動力は何でしょうか。"
        "男：書きたいことがあるから書く、という段階はとうに過ぎました。"
        "今は、書かないと分からないから書いている。"
        "考えがまとまってから書くのではなく、"
        "書くことでしか届かない場所があると知ってしまったんです。",
        "Wanita: Apa yang menjadi tenaga penggerak Anda terus menulis sekian lama? "
        "Pria: Tahap menulis karena ada yang ingin ditulis sudah lama saya lewati. "
        "Sekarang saya menulis karena kalau tidak menulis saya tidak mengerti. "
        "Bukan menulis setelah pikiran tersusun, melainkan saya terlanjur tahu bahwa "
        "ada tempat yang hanya bisa dicapai dengan menulis.",
        [
            ("男の人は今なぜ書いていますか。",
             ["書きたいことがあるから", "書かないと分からないから",
              "頼まれるから", "生活のため"], 1),
            ("男の人の考え方はどれですか。",
             ["考えをまとめてから書く", "書くことで初めて届く場所がある",
              "書くことに意味はない", "才能が全てである"], 1),
        ],
    ),
    (
        "dampak_otomatisasi",
        "Kajian Dampak Otomatisasi",
        "男：自動化によって職が失われるという議論は繰り返されてきました。"
        "しかし歴史を振り返れば、消えたのは職業というより、"
        "職業を構成していた作業の束です。"
        "残された作業と新たに生じた作業がどう再編されるか、"
        "そこに関与できるかどうかが、影響の大きさを左右してきました。",
        "Pria: Perdebatan bahwa otomatisasi menghilangkan pekerjaan telah berulang. "
        "Namun jika menengok sejarah, yang lenyap lebih tepat bukan profesinya, "
        "melainkan kumpulan tugas yang menyusun profesi itu. Bagaimana tugas yang "
        "tersisa dan tugas yang baru muncul disusun ulang, dan bisa-tidaknya seseorang "
        "terlibat di situ, itulah yang selama ini menentukan besarnya dampak.",
        [
            ("話し手によると、実際に消えるのは何ですか。",
             ["職業そのもの", "作業の束", "企業", "技能"], 1),
            ("影響の大きさを左右するのは何ですか。",
             ["技術の速さ", "再編に関与できるかどうか",
              "政府の政策", "教育の年数"], 1),
        ],
    ),
    (
        "kesehatan_masyarakat",
        "Diskusi Kesehatan Masyarakat",
        "女：個人の心がけを説く啓発は、一定の効果はあります。"
        "男：ただ、行動を変えられる余裕がある層にしか届かないという限界もある。"
        "女：ええ。労働時間や食品価格といった条件を動かさずに"
        "意識だけを問うのは、責任の置き場所を誤っているとも言えます。"
        "男：構造に触れない啓発は、格差を広げかねません。",
        "Wanita: Kampanye yang menyerukan kesadaran pribadi memang punya efek tertentu. "
        "Pria: Tapi ada juga batasnya, ia hanya sampai pada lapisan yang punya kelonggaran "
        "untuk mengubah perilaku. "
        "Wanita: Ya. Menuntut kesadaran saja tanpa menggerakkan syarat seperti jam kerja "
        "dan harga pangan bisa dibilang salah menempatkan tanggung jawab. "
        "Pria: Kampanye yang tidak menyentuh struktur berpotensi melebarkan kesenjangan.",
        [
            ("二人の共通した見方はどれですか。",
             ["啓発だけで十分である", "構造に触れない啓発には限界がある",
              "啓発は無意味である", "個人の責任が全てである"], 1),
            ("啓発が届きにくいのはどんな層ですか。",
             ["情報を持たない層", "行動を変える余裕がない層",
              "高齢の層", "都市の層"], 1),
        ],
    ),
    (
        "seni_kontemporer",
        "Ceramah tentang Seni Kontemporer",
        "男：難解だと言われる作品の多くは、"
        "実は答えを隠しているわけではありません。"
        "答えという形式そのものを前提にしていないのです。"
        "何を意味するのかと問い続ける限り、"
        "その問いに合う答えがないという事実だけが返ってくる。"
        "問いの立て方を変えることが、鑑賞の入口になります。",
        "Pria: Sebagian besar karya yang disebut sulit dipahami sebenarnya bukan "
        "menyembunyikan jawaban. Karya itu memang tidak berangkat dari bentuk yang "
        "bernama jawaban. Selama kita terus bertanya apa maknanya, yang kembali hanyalah "
        "kenyataan bahwa tidak ada jawaban yang cocok dengan pertanyaan itu. "
        "Mengubah cara menyusun pertanyaan itulah yang menjadi pintu masuk menikmatinya.",
        [
            ("話し手によると、難解な作品の特徴は何ですか。",
             ["答えを隠している", "答えという形式を前提にしていない",
              "技術が高い", "説明が長い"], 1),
            ("鑑賞の入口は何だと言っていますか。",
             ["解説を読むこと", "問いの立て方を変えること",
              "何度も見ること", "作者に聞くこと"], 1),
        ],
    ),
    (
        "kebijakan_transportasi",
        "Analisis Kebijakan Transportasi",
        "女：道路を広げれば渋滞が緩和するという想定は、"
        "しばしば裏切られてきました。"
        "容量が増えると、それまで移動を控えていた需要が現れるためです。"
        "男：つまり、渋滞は供給不足ではなく、"
        "価格づけの問題だという見方もできますね。"
        "女：ええ。何を無料で提供しているのかを問い直す必要があります。",
        "Wanita: Asumsi bahwa memperlebar jalan akan meredakan kemacetan kerap "
        "dikhianati kenyataan. Sebab ketika kapasitas bertambah, muncul permintaan "
        "yang selama ini menahan diri bepergian. "
        "Pria: Artinya, bisa juga dipandang bahwa kemacetan bukan soal kekurangan "
        "pasokan, melainkan soal penetapan harga. "
        "Wanita: Ya. Perlu dipertanyakan ulang apa yang selama ini kita sediakan gratis.",
        [
            ("道路を広げるとなぜ渋滞が残りますか。",
             ["工事が長引くから", "控えていた需要が現れるから",
              "車が大きくなるから", "人口が増えるから"], 1),
            ("二人はどんな見方を示しましたか。",
             ["供給を増やすべきだ", "価格づけの問題として捉える",
              "道路を減らすべきだ", "結論は出ない"], 1),
        ],
    ),
]


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
