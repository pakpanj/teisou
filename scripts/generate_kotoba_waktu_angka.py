import json

# Kotoba vocab — grup "Waktu & Angka" (Batch 7, final group).
# Same per-entry registers approach as the other Batch 7 scripts.
#
# hari_bulan is larger (22) than most categories on purpose: days of the
# week and months are small, closed, complete sets (unlike e.g. animals,
# where a subset is a curatorial choice) — learners expect all 7 days and
# all 12 months, not a sample. Month readings include the three standard
# irregulars: 四月=shigatsu (not yongatsu), 七月=shichigatsu (not
# nanagatsu), 九月=kugatsu (not kyuugatsu).
#
# angka_satuan sticks to pure numbers (1-10, 100, 1000, 10000) and skips
# counters/josuushi (mai, hon, hiki...) — those are bound morphemes that
# don't stand alone as words the way every other entry in this dataset
# does, and representing them accurately would need explaining irregular
# counting-sequence readings, which is a deeper grammar topic than this
# category's scope.
#
# warna keeps the real noun/adjective split: akai/aoi/kiiroi/shiroi/kuroi
# are true i-adjectives (the five basic historical colors), the rest
# (midori, chairo, murasaki, pinku, orenji, haiiro) are nouns used with
# no/desu, not aoi-style adjectives — mirroring how they actually behave.
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
    "hari_bulan": [
        ("getsuyoubi", "月曜日", "げつようび", "getsuyoubi", "hari Senin", "N5", "noun", "月曜日", "getsuyoubi", "月曜日", "getsuyoubi", [
            ("月曜日に学校があります。", "Getsuyoubi ni gakkou ga arimasu.", "Hari Senin ada sekolah."),
        ]),
        ("kayoubi", "火曜日", "かようび", "kayoubi", "hari Selasa", "N5", "noun", "火曜日", "kayoubi", "火曜日", "kayoubi", [
            ("火曜日に会議があります。", "Kayoubi ni kaigi ga arimasu.", "Hari Selasa ada rapat."),
        ]),
        ("suiyoubi", "水曜日", "すいようび", "suiyoubi", "hari Rabu", "N5", "noun", "水曜日", "suiyoubi", "水曜日", "suiyoubi", [
            ("水曜日は休みです。", "Suiyoubi wa yasumi desu.", "Hari Rabu libur."),
        ]),
        ("mokuyoubi", "木曜日", "もくようび", "mokuyoubi", "hari Kamis", "N5", "noun", "木曜日", "mokuyoubi", "木曜日", "mokuyoubi", [
            ("木曜日に映画を見ます。", "Mokuyoubi ni eiga o mimasu.", "Hari Kamis saya menonton film."),
        ]),
        ("kinyoubi", "金曜日", "きんようび", "kinyoubi", "hari Jumat", "N5", "noun", "金曜日", "kinyoubi", "金曜日", "kinyoubi", [
            ("金曜日が好きです。", "Kinyoubi ga suki desu.", "Saya suka hari Jumat."),
        ]),
        ("doyoubi", "土曜日", "どようび", "doyoubi", "hari Sabtu", "N5", "noun", "土曜日", "doyoubi", "土曜日", "doyoubi", [
            ("土曜日に買い物します。", "Doyoubi ni kaimono shimasu.", "Hari Sabtu saya berbelanja."),
        ]),
        ("nichiyoubi", "日曜日", "にちようび", "nichiyoubi", "hari Minggu", "N5", "noun", "日曜日", "nichiyoubi", "日曜日", "nichiyoubi", [
            ("日曜日は家族と過ごします。", "Nichiyoubi wa kazoku to sugoshimasu.", "Hari Minggu saya menghabiskan waktu dengan keluarga."),
        ]),
        ("kyou", "今日", "きょう", "kyou", "hari ini", "N5", "noun", "今日", "kyou", "今日", "kyou", [
            ("今日は暑いです。", "Kyou wa atsui desu.", "Hari ini panas."),
        ]),
        ("ashita", "明日", "あした", "ashita", "besok", "N5", "noun", "明日", "ashita", "明日", "ashita", [
            ("明日テストがあります。", "Ashita tesuto ga arimasu.", "Besok ada tes."),
        ]),
        ("kinou", "昨日", "きのう", "kinou", "kemarin", "N5", "noun", "昨日", "kinou", "昨日", "kinou", [
            ("昨日雨でした。", "Kinou ame deshita.", "Kemarin hujan."),
        ]),
        ("ichigatsu", "一月", "いちがつ", "ichigatsu", "bulan Januari", "N5", "noun", "一月", "ichigatsu", "一月", "ichigatsu", [
            ("一月は寒いです。", "Ichigatsu wa samui desu.", "Bulan Januari dingin."),
        ]),
        ("nigatsu", "二月", "にがつ", "nigatsu", "bulan Februari", "N5", "noun", "二月", "nigatsu", "二月", "nigatsu", [
            ("二月は短いです。", "Nigatsu wa mijikai desu.", "Bulan Februari pendek."),
        ]),
        ("sangatsu", "三月", "さんがつ", "sangatsu", "bulan Maret", "N5", "noun", "三月", "sangatsu", "三月", "sangatsu", [
            ("三月に卒業します。", "Sangatsu ni sotsugyou shimasu.", "Saya lulus di bulan Maret."),
        ]),
        ("shigatsu", "四月", "しがつ", "shigatsu", "bulan April", "N5", "noun", "四月", "shigatsu", "四月", "shigatsu", [
            ("四月に学校が始まります。", "Shigatsu ni gakkou ga hajimarimasu.", "Sekolah dimulai bulan April."),
        ]),
        ("gogatsu", "五月", "ごがつ", "gogatsu", "bulan Mei", "N5", "noun", "五月", "gogatsu", "五月", "gogatsu", [
            ("五月は過ごしやすいです。", "Gogatsu wa sugoshiyasui desu.", "Bulan Mei nyaman (cuacanya)."),
        ]),
        ("rokugatsu", "六月", "ろくがつ", "rokugatsu", "bulan Juni", "N5", "noun", "六月", "rokugatsu", "六月", "rokugatsu", [
            ("六月によく雨が降ります。", "Rokugatsu ni yoku ame ga furimasu.", "Bulan Juni sering hujan."),
        ]),
        ("shichigatsu", "七月", "しちがつ", "shichigatsu", "bulan Juli", "N5", "noun", "七月", "shichigatsu", "七月", "shichigatsu", [
            ("七月は暑いです。", "Shichigatsu wa atsui desu.", "Bulan Juli panas."),
        ]),
        ("hachigatsu", "八月", "はちがつ", "hachigatsu", "bulan Agustus", "N5", "noun", "八月", "hachigatsu", "八月", "hachigatsu", [
            ("八月に花火大会があります。", "Hachigatsu ni hanabi taikai ga arimasu.", "Bulan Agustus ada festival kembang api."),
        ]),
        ("kugatsu", "九月", "くがつ", "kugatsu", "bulan September", "N5", "noun", "九月", "kugatsu", "九月", "kugatsu", [
            ("九月に新学期が始まります。", "Kugatsu ni shingakki ga hajimarimasu.", "Semester baru dimulai bulan September."),
        ]),
        ("juugatsu", "十月", "じゅうがつ", "juugatsu", "bulan Oktober", "N5", "noun", "十月", "juugatsu", "十月", "juugatsu", [
            ("十月は涼しいです。", "Juugatsu wa suzushii desu.", "Bulan Oktober sejuk."),
        ]),
        ("juuichigatsu", "十一月", "じゅういちがつ", "juuichigatsu", "bulan November", "N5", "noun", "十一月", "juuichigatsu", "十一月", "juuichigatsu", [
            ("十一月に紅葉が綺麗です。", "Juuichigatsu ni kouyou ga kirei desu.", "Bulan November daun-daun indah warnanya."),
        ]),
        ("juunigatsu", "十二月", "じゅうにがつ", "juunigatsu", "bulan Desember", "N5", "noun", "十二月", "juunigatsu", "十二月", "juunigatsu", [
            ("十二月にクリスマスがあります。", "Juunigatsu ni kurisumasu ga arimasu.", "Ada Natal di bulan Desember."),
        ]),
        # Addition prompted by the user asking why the Kombinasi Kanji
        # exam's N5 compound-word pool was stuck at 53 while N4-N1 kept
        # growing — the answer was that recent batches only added
        # N2/N1-leaning konsep_umum vocabulary, never new N5 words. These
        # 18 are genuine everyday N5 time expressions (relative day/week/
        # month/year words + morning/afternoon + every-day/week/month/
        # year) that are all real 2-3 pure-kanji compounds, thematically
        # exact for this category (relative-time siblings of 今日/明日/
        # 昨日 already above), and were absent from the whole 782-word
        # dataset before this addition (checked before authoring).
        ("ototoi", "一昨日", "おととい", "ototoi", "kemarin lusa", "N5", "noun", "一昨日", "ototoi", "一昨日", "ototoi", [
            ("一昨日、友達に会いました。", "Ototoi, tomodachi ni aimashita.", "Kemarin lusa saya bertemu teman."),
        ]),
        ("asatte", "明後日", "あさって", "asatte", "lusa", "N5", "noun", "明後日", "asatte", "明後日", "asatte", [
            ("明後日、東京に行きます。", "Asatte, Toukyou ni ikimasu.", "Lusa saya pergi ke Tokyo."),
        ]),
        ("konshuu", "今週", "こんしゅう", "konshuu", "minggu ini", "N5", "noun", "今週", "konshuu", "今週", "konshuu", [
            ("今週は忙しいです。", "Konshuu wa isogashii desu.", "Minggu ini sibuk."),
        ]),
        ("kongetsu", "今月", "こんげつ", "kongetsu", "bulan ini", "N5", "noun", "今月", "kongetsu", "今月", "kongetsu", [
            ("今月、誕生日です。", "Kongetsu, tanjoubi desu.", "Bulan ini ulang tahun saya."),
        ]),
        ("kotoshi", "今年", "ことし", "kotoshi", "tahun ini", "N5", "noun", "今年", "kotoshi", "今年", "kotoshi", [
            ("今年、日本へ行きます。", "Kotoshi, Nihon e ikimasu.", "Tahun ini saya pergi ke Jepang."),
        ]),
        ("raishuu", "来週", "らいしゅう", "raishuu", "minggu depan", "N5", "noun", "来週", "raishuu", "来週", "raishuu", [
            ("来週、テストがあります。", "Raishuu, tesuto ga arimasu.", "Minggu depan ada tes."),
        ]),
        ("raigetsu", "来月", "らいげつ", "raigetsu", "bulan depan", "N5", "noun", "来月", "raigetsu", "来月", "raigetsu", [
            ("来月、引っ越しします。", "Raigetsu, hikkoshi shimasu.", "Bulan depan saya pindah rumah."),
        ]),
        ("rainen", "来年", "らいねん", "rainen", "tahun depan", "N5", "noun", "来年", "rainen", "来年", "rainen", [
            ("来年、大学に入ります。", "Rainen, daigaku ni hairimasu.", "Tahun depan saya masuk universitas."),
        ]),
        ("senshuu", "先週", "せんしゅう", "senshuu", "minggu lalu", "N5", "noun", "先週", "senshuu", "先週", "senshuu", [
            ("先週、映画を見ました。", "Senshuu, eiga o mimashita.", "Minggu lalu saya menonton film."),
        ]),
        ("sengetsu", "先月", "せんげつ", "sengetsu", "bulan lalu", "N5", "noun", "先月", "sengetsu", "先月", "sengetsu", [
            ("先月、大阪に行きました。", "Sengetsu, Oosaka ni ikimashita.", "Bulan lalu saya pergi ke Osaka."),
        ]),
        ("kyonen", "去年", "きょねん", "kyonen", "tahun lalu", "N5", "noun", "去年", "kyonen", "去年", "kyonen", [
            ("去年、結婚しました。", "Kyonen, kekkon shimashita.", "Tahun lalu saya menikah."),
        ]),
        ("gozen", "午前", "ごぜん", "gozen", "pagi (sebelum siang)", "N5", "noun", "午前", "gozen", "午前", "gozen", [
            ("午前九時に会議があります。", "Gozen kuji ni kaigi ga arimasu.", "Ada rapat jam 9 pagi."),
        ]),
        ("gogo", "午後", "ごご", "gogo", "siang/sore (setelah siang)", "N5", "noun", "午後", "gogo", "午後", "gogo", [
            ("午後三時に会いましょう。", "Gogo sanji ni aimashou.", "Mari bertemu jam 3 sore."),
        ]),
        ("mainichi", "毎日", "まいにち", "mainichi", "setiap hari", "N5", "noun", "毎日", "mainichi", "毎日", "mainichi", [
            ("毎日、日本語を勉強します。", "Mainichi, nihongo o benkyou shimasu.", "Setiap hari saya belajar bahasa Jepang."),
        ]),
        ("maishuu", "毎週", "まいしゅう", "maishuu", "setiap minggu", "N5", "noun", "毎週", "maishuu", "毎週", "maishuu", [
            ("毎週、公園を走ります。", "Maishuu, kouen o hashirimasu.", "Setiap minggu saya lari di taman."),
        ]),
        ("maitsuki", "毎月", "まいつき", "maitsuki", "setiap bulan", "N5", "noun", "毎月", "maitsuki", "毎月", "maitsuki", [
            ("毎月、本を一冊買います。", "Maitsuki, hon o issatsu kaimasu.", "Setiap bulan saya membeli satu buku."),
        ]),
        ("maitoshi", "毎年", "まいとし", "maitoshi", "setiap tahun", "N5", "noun", "毎年", "maitoshi", "毎年", "maitoshi", [
            ("毎年、家族で旅行します。", "Maitoshi, kazoku de ryokou shimasu.", "Setiap tahun saya bepergian bersama keluarga."),
        ]),
        ("jikan", "時間", "じかん", "jikan", "waktu/jam", "N5", "noun", "時間", "jikan", "時間", "jikan", [
            ("時間がありません。", "Jikan ga arimasen.", "Saya tidak punya waktu."),
        ]),
        ("igo", "以後", "いご", "igo", "sesudah ini", "N2", "noun", "以後", "igo", "以後", "igo", [
            ("今日以後気をつけます。", "Kyou igo ki o tsukemasu.", "Mulai ini hari ini saya akan hati2. (Setelah itu & seterusnya)"),
        ]),
        ("ikou", "以降", "いこう", "ikou", "setelah/sejak", "N2", "noun", "以降", "ikou", "以降", "ikou", [
            ("7時以降は入れません。", "Shichiji ikou wa hairemasen.", "Setelah jam 7 tidak boleh masuk. (batas itu & seterusnya)"),
        ]),
        ("izen", "以前", "いぜん", "izen", "dulu/sebelumnya", "N2", "noun", "以前", "izen", "以前", "izen", [
            ("以前ここに住んでいました。", "Izen koko ni sunde imashita.", "Dulu saya tinggal di sini. (Kronologis waktu)"),
        ]),
        ("inai", "以内", "いない", "inai", "dalam batas", "N2", "noun", "以内", "inai", "以内", "inai", [
            ("10分以内に来てください。", "Juppun inai ni kite kudasai.", "Datang dalam 10 menit. (Batas durasi waktu)"),
        ]),
        ("kako", "過去", "かこ", "kako", "masa lalu", "N2", "noun", "過去", "kako", "過去", "kako", [
            ("過去を忘れません。", "Kako o wasuremasen.", "Saya tidak melupakan masa lalu."),
        ]),
        ("kikan", "期間", "きかん", "kikan", "periode/jangka waktu", "N2", "noun", "期間", "kikan", "期間", "kikan", [
            ("期間は3か月です。", "Kikan wa sankagetsu desu.", "Periode/masanya 3 bulan. (ada batas mulai&akhir)"),
        ]),
        ("sakuya", "昨夜", "さくや", "sakuya", "tadi malam", "N2", "noun", "昨夜", "sakuya", "昨夜", "sakuya", [
            ("昨夜雨が降りました。", "Sakuya ame ga furimashita.", "Tadi malam hujan turun."),
        ]),
        ("shukujitsu", "祝日", "しゅくじつ", "shukujitsu", "hari libur nasional", "N2", "noun", "祝日", "shukujitsu", "祝日", "shukujitsu", [
            ("今日は祝日です。", "Kyou wa shukujitsu desu.", "Hari ini hari libur nasional."),
        ]),
        ("jiki", "時期", "じき", "jiki", "periode/masa", "N2", "noun", "時期", "jiki", "時期", "jiki", [
            ("今は忙しい時期です。", "Ima wa isogashii jiki desu.", "Sekarang masa sibuk. (Priode, timing)"),
        ]),
        ("jikoku", "時刻", "じこく", "jikoku", "jadwal waktu", "N2", "noun", "時刻", "jikoku", "時刻", "jikoku", [
            ("出発時刻を確認します。", "Shuppatsu jikoku o kakunin shimasu.", "Mengecek jadwal waktu keberangkatan."),
        ]),
        ("jidai", "時代", "じだい", "jidai", "zaman", "N2", "noun", "時代", "jidai", "時代", "jidai", [
            ("新しい時代になりました。", "Atarashii jidai ni narimashita.", "Menjadi zaman baru."),
        ]),
        ("senjitsu", "先日", "せんじつ", "senjitsu", "beberapa hari lalu", "N2", "noun", "先日", "senjitsu", "先日", "senjitsu", [
            ("先日お会いしましたね。", "Senjitsu oai shimashita ne.", "Kita bertemu beberapa hari lalu ya."),
        ]),
        ("zengo", "前後", "ぜんご", "zengo", "sekitar/kurang lebih", "N2", "noun", "前後", "zengo", "前後", "zengo", [
            ("10分前後かかります。", "Juppun zengo kakarimasu.", "Butuh waktu Sekitar ±10 menit. (tempat>sebelum&sesudah)"),
        ]),
        ("souchou", "早朝", "そうちょう", "souchou", "pagi sekali/dini hari", "N2", "noun", "早朝", "souchou", "早朝", "souchou", [
            ("早朝に出発します。", "Souchou ni shuppatsu shimasu.", "Berangkat pagi sekali. (Jam 4-6 pagi)"),
        ]),
        ("chuujun", "中旬", "ちゅうじゅん", "chuujun", "pertengahan bulan", "N2", "noun", "中旬", "chuujun", "中旬", "chuujun", [
            ("今月中旬に行きます。", "Kongetsu chuujun ni ikimasu.", "Pergi pertengahan bulan ini."),
        ]),
        ("toujitsu", "当日", "とうじつ", "toujitsu", "hari itu/hari-H", "N2", "noun", "当日", "toujitsu", "当日", "toujitsu", [
            ("当日は雨でした。", "Toujitsu wa ame deshita.", "Pada hari H hujan."),
        ]),
        ("douji", "同時", "どうじ", "douji", "bersamaan/serentak", "N2", "noun", "同時", "douji", "同時", "douji", [
            ("二人は同時に話しました。", "Futari wa douji ni hanashimashita.", "Mereka berbicara bersamaan."),
        ]),
        ("nichiji", "日時", "にちじ", "nichiji", "tanggal dan waktu", "N2", "noun", "日時", "nichiji", "日時", "nichiji", [
            ("面接の日時を教えてください。", "Mensetsu no nichiji o oshiete kudasai.", "Tolong beritahu tanggal dan waktu wawancara."),
        ]),
        ("nichijou", "日常", "にちじょう", "nichijou", "sehari-hari", "N2", "noun", "日常", "nichijou", "日常", "nichijou", [
            ("日常生活が忙しいです。", "Nichijou seikatsu ga isogashii desu.", "Kehidupan sehari-hari saya sibuk."),
        ]),
        ("nittei", "日程", "にってい", "nittei", "jadwal", "N2", "noun", "日程", "nittei", "日程", "nittei", [
            ("日程を確認してください。", "Nittei o kakunin shite kudasai.", "Silakan periksa jadwalnya. (Skala Hari, jadwal susuna acara)"),
        ]),
        ("hiruma", "昼間", "ひるま", "hiruma", "siang hari", "N2", "noun", "昼間", "hiruma", "昼間", "hiruma", [
            ("昼間は仕事をしています。", "Hiruma wa shigoto o shite imasu.", "Siang hari saya bekerja. (Jam 9-17)"),
        ]),
        ("honjitsu", "本日", "ほんじつ", "honjitsu", "hari ini (formal)", "N2", "noun", "本日", "honjitsu", "本日", "honjitsu", [
            ("本日は休みです。", "Honjitsu wa yasumi desu.", "Hari ini libur."),
        ]),
        ("yakan", "夜間", "やかん", "yakan", "malam hari", "N2", "noun", "夜間", "yakan", "夜間", "yakan", [
            ("夜間に働きます。", "Yakan ni hatarakimasu.", "Bekerja pada malam hari. (periode malam)"),
        ]),
        ("yokujitsu", "翌日", "よくじつ", "yokujitsu", "keesokan hari", "N2", "noun", "翌日", "yokujitsu", "翌日", "yokujitsu", [
            ("翌日、結果が出ました。", "Yokujitsu, kekka ga demashita.", "Keesokan hari hasil keluar. (Hari berikutnya)"),
        ]),
        ("choujikan", "長時間", "ちょうじかん", "choujikan", "waktu lama", "N2", "noun", "長時間", "choujikan", "長時間", "choujikan", [
            ("長時間働きました。", "Choujikan hatarakimashita.", "Saya bekerja dalam waktu lama."),
        ]),
        ("ichiji", "一時", "いちじ", "ichiji", "sementara/jam satu", "N3", "noun", "一時", "ichiji", "一時", "ichiji", [
            ("一時的な問題です。", "Ichijiteki na mondai desu.", "Ini masalah sementara."),
        ]),
        ("isshun", "一瞬", "いっしゅん", "isshun", "sekejap", "N3", "noun", "一瞬", "isshun", "一瞬", "isshun", [
            ("一瞬で終わりました。", "Isshun de owarimashita.", "Selesai dalam sekejap."),
        ]),
        ("kongo", "今後", "こんご", "kongo", "mulai sekarang/selanjutnya", "N3", "noun", "今後", "kongo", "今後", "kongo", [
            ("今後気をつけます。", "Kongo ki o tsukemasu.", "Akan lebih berhati-hati mulai sekarang."),
        ]),
        ("konkai", "今回", "こんかい", "konkai", "kali ini", "N3", "noun", "今回", "konkai", "今回", "konkai", [
            ("今回は特別です。", "Konkai wa tokubetsu desu.", "Kali ini istimewa."),
        ]),
        ("shougo", "正午", "しょうご", "shougo", "tengah hari", "N3", "noun", "正午", "shougo", "正午", "shougo", [
            ("正午に会いましょう。", "Shougo ni aimashou.", "Mari bertemu tengah hari."),
        ]),
        ("shuukan", "週間", "しゅうかん", "shuukan", "seminggu (durasi)", "N3", "noun", "週間", "shuukan", "週間", "shuukan", [
            ("一週間旅行します。", "Isshuukan ryokou shimasu.", "Bepergian selama seminggu."),
        ]),
        ("yonaka", "夜中", "よなか", "yonaka", "tengah malam", "N3", "noun", "夜中", "yonaka", "夜中", "yonaka", [
            ("夜中に起きました。", "Yonaka ni okimashita.", "Bangun tengah malam."),
        ]),
        ("ikkoku", "一刻", "いっこく", "ikkoku", "sesaat/sejenak", "N1", "noun", "一刻", "ikkoku", "一刻", "ikkoku", [
            ("一刻も早く来てください。", "Ikkoku mo hayaku kite kudasai.", "Tolong datang secepatnya."),
        ]),
        ("jizen", "事前", "じぜん", "jizen", "sebelumnya/di muka", "N1", "noun", "事前", "jizen", "事前", "jizen", [
            ("事前に予約します。", "Jizen ni yoyaku shimasu.", "Memesan sebelumnya (di muka)."),
        ]),
        ("kondo", "今度", "こんど", "kondo", "kali ini/lain kali", "N4", "noun", "今度", "kondo", "今度", "kondo", [
            ("今度会いましょう。", "Kondo aimashou.", "Mari bertemu lain kali."),
        ]),
        ("konya", "今夜", "こんや", "konya", "malam ini", "N4", "noun", "今夜", "konya", "今夜", "konya", [
            ("今夜は寒いです。", "Kon'ya wa samui desu.", "Malam ini dingin."),
        ]),
        ("saikin", "最近", "さいきん", "saikin", "belakangan ini", "N4", "noun", "最近", "saikin", "最近", "saikin", [
            ("最近忙しいです。", "Saikin isogashii desu.", "Belakangan ini sibuk."),
        ]),
        ("saraigetsu", "再来月", "さらいげつ", "saraigetsu", "bulan depan setelah bulan depan", "N4", "noun", "再来月", "saraigetsu", "再来月", "saraigetsu", [
            ("再来月旅行します。", "Saraigetsu ryokou shimasu.", "Bepergian dua bulan lagi."),
        ]),
        ("saraishuu", "再来週", "さらいしゅう", "saraishuu", "minggu setelah minggu depan", "N4", "noun", "再来週", "saraishuu", "再来週", "saraishuu", [
            ("再来週会います。", "Saraishuu aimasu.", "Bertemu dua minggu lagi."),
        ]),
    ],
    "musim": [
        ("haru", "春", "はる", "haru", "musim semi", "N5", "noun", "春", "haru", "春", "haru", [
            ("春に桜が咲きます。", "Haru ni sakura ga sakimasu.", "Di musim semi, bunga sakura mekar."),
        ]),
        ("natsu", "夏", "なつ", "natsu", "musim panas", "N5", "noun", "夏", "natsu", "夏", "natsu", [
            ("夏は暑いです。", "Natsu wa atsui desu.", "Musim panas itu panas."),
        ]),
        ("aki", "秋", "あき", "aki", "musim gugur", "N5", "noun", "秋", "aki", "秋", "aki", [
            ("秋に紅葉が綺麗です。", "Aki ni kouyou ga kirei desu.", "Di musim gugur, daun berwarna indah."),
        ]),
        ("fuyu", "冬", "ふゆ", "fuyu", "musim dingin", "N5", "noun", "冬", "fuyu", "冬", "fuyu", [
            ("冬は寒いです。", "Fuyu wa samui desu.", "Musim dingin itu dingin."),
        ]),
        ("kisetsu", "季節", "きせつ", "kisetsu", "musim (kata umum)", "N4", "noun", "季節", "kisetsu", "季節", "kisetsu", [
            ("どの季節が好きですか。", "Dono kisetsu ga suki desu ka.", "Musim apa yang kamu suka?"),
        ]),
    ],
    "angka_satuan": [
        ("ichi", "一", "いち", "ichi", "satu (1)", "N5", "noun", "一", "ichi", "一", "ichi", [
            ("答えは一です。", "Kotae wa ichi desu.", "Jawabannya adalah satu."),
        ]),
        ("ni", "二", "に", "ni", "dua (2)", "N5", "noun", "二", "ni", "二", "ni", [
            ("答えは二です。", "Kotae wa ni desu.", "Jawabannya adalah dua."),
        ]),
        ("san", "三", "さん", "san", "tiga (3)", "N5", "noun", "三", "san", "三", "san", [
            ("答えは三です。", "Kotae wa san desu.", "Jawabannya adalah tiga."),
        ]),
        ("yon", "四", "よん", "yon", "empat (4)", "N5", "noun", "四", "yon", "四", "yon", [
            ("答えは四です。", "Kotae wa yon desu.", "Jawabannya adalah empat."),
        ]),
        ("go", "五", "ご", "go", "lima (5)", "N5", "noun", "五", "go", "五", "go", [
            ("答えは五です。", "Kotae wa go desu.", "Jawabannya adalah lima."),
        ]),
        ("roku", "六", "ろく", "roku", "enam (6)", "N5", "noun", "六", "roku", "六", "roku", [
            ("答えは六です。", "Kotae wa roku desu.", "Jawabannya adalah enam."),
        ]),
        ("nana", "七", "なな", "nana", "tujuh (7)", "N5", "noun", "七", "nana", "七", "nana", [
            ("答えは七です。", "Kotae wa nana desu.", "Jawabannya adalah tujuh."),
        ]),
        ("hachi", "八", "はち", "hachi", "delapan (8)", "N5", "noun", "八", "hachi", "八", "hachi", [
            ("答えは八です。", "Kotae wa hachi desu.", "Jawabannya adalah delapan."),
        ]),
        ("kyuu", "九", "きゅう", "kyuu", "sembilan (9)", "N5", "noun", "九", "kyuu", "九", "kyuu", [
            ("答えは九です。", "Kotae wa kyuu desu.", "Jawabannya adalah sembilan."),
        ]),
        ("juu", "十", "じゅう", "juu", "sepuluh (10)", "N5", "noun", "十", "juu", "十", "juu", [
            ("答えは十です。", "Kotae wa juu desu.", "Jawabannya adalah sepuluh."),
        ]),
        ("hyaku", "百", "ひゃく", "hyaku", "seratus (100)", "N4", "noun", "百", "hyaku", "百", "hyaku", [
            ("答えは百です。", "Kotae wa hyaku desu.", "Jawabannya adalah seratus."),
        ]),
        ("sen", "千", "せん", "sen", "seribu (1000)", "N4", "noun", "千", "sen", "千", "sen", [
            ("答えは千です。", "Kotae wa sen desu.", "Jawabannya adalah seribu."),
        ]),
        ("ichiman", "一万", "いちまん", "ichiman", "sepuluh ribu (10.000)", "N3", "noun", "一万", "ichiman", "一万", "ichiman", [
            ("答えは一万です。", "Kotae wa ichiman desu.", "Jawabannya adalah sepuluh ribu."),
        ]),
        ("suuji", "数字", "すうじ", "suuji", "angka/nomor", "N2", "noun", "数字", "suuji", "数字", "suuji", [
            ("数字を書いてください。", "Suuji o kaite kudasai.", "Tolong tulis angka."),
        ]),
        ("ninzuu", "人数", "にんずう", "ninzuu", "jumlah orang", "N2", "noun", "人数", "ninzuu", "人数", "ninzuu", [
            ("人数を数えます。", "Ninzuu o kazoemasu.", "Saya menghitung jumlah orang."),
        ]),
        ("fukusuu", "複数", "ふくすう", "fukusuu", "lebih dari satu/beberapa", "N2", "noun", "複数", "fukusuu", "複数", "fukusuu", [
            ("複数の理由があります。", "Fukusuu no riyuu ga arimasu.", "Ada beberapa alasan. (lebih dari satu, beberapa)"),
        ]),
        ("ninzuubun", "人数分", "にんずうぶん", "ninzuubun", "sesuai jumlah orang", "N2", "noun", "人数分", "ninzuubun", "人数分", "ninzuubun", [
            ("人数分の料理を用意します。", "Ninzuubun no ryouri o youi shimasu.", "Menyiapkan makanan sesuai jumlah orang."),
        ]),
        ("kahansuu", "過半数", "かはんすう", "kahansuu", "lebih dari separuh", "N2", "noun", "過半数", "kahansuu", "過半数", "kahansuu", [
            ("過半数の賛成が必要です。", "Kahansuu no sansei ga hitsuyou desu.", "Diperlukan persetujuan lebih dari separuh."),
        ]),
        ("ijou", "以上", "いじょう", "ijou", "lebih dari", "N4", "noun", "以上", "ijou", "以上", "ijou", [
            ("20歳以上です。", "Nijussai ijou desu.", "Usia 20 tahun ke atas."),
        ]),
        ("ika", "以下", "いか", "ika", "kurang dari/di bawah", "N4", "noun", "以下", "ika", "以下", "ika", [
            ("10人以下です。", "Juunin ika desu.", "Kurang dari 10 orang."),
        ]),
    ],
    "warna": [
        ("akai", "赤い", "あかい", "akai", "merah", "N5", "adjective", "赤い", "akai", "赤いです", "akai desu", [
            ("赤いりんごです。", "Akai ringo desu.", "Ini apel merah."),
        ]),
        ("aoi", "青い", "あおい", "aoi", "biru", "N5", "adjective", "青い", "aoi", "青いです", "aoi desu", [
            ("空は青いです。", "Sora wa aoi desu.", "Langit itu biru."),
        ]),
        ("kiiroi", "黄色い", "きいろい", "kiiroi", "kuning", "N5", "adjective", "黄色い", "kiiroi", "黄色いです", "kiiroi desu", [
            ("バナナは黄色いです。", "Banana wa kiiroi desu.", "Pisang itu kuning."),
        ]),
        ("midori", "緑", "みどり", "midori", "hijau", "N5", "noun", "緑", "midori", "緑です", "midori desu", [
            ("木の葉は緑です。", "Ki no ha wa midori desu.", "Daun pohon berwarna hijau."),
        ]),
        ("shiroi", "白い", "しろい", "shiroi", "putih", "N5", "adjective", "白い", "shiroi", "白いです", "shiroi desu", [
            ("雪は白いです。", "Yuki wa shiroi desu.", "Salju berwarna putih."),
        ]),
        ("kuroi", "黒い", "くろい", "kuroi", "hitam", "N5", "adjective", "黒い", "kuroi", "黒いです", "kuroi desu", [
            ("猫は黒いです。", "Neko wa kuroi desu.", "Kucing itu hitam."),
        ]),
        ("chairo", "茶色", "ちゃいろ", "chairo", "coklat (warna)", "N4", "noun", "茶色", "chairo", "茶色です", "chairo desu", [
            ("犬は茶色です。", "Inu wa chairo desu.", "Anjing itu berwarna coklat."),
        ]),
        ("murasaki", "紫", "むらさき", "murasaki", "ungu", "N3", "noun", "紫", "murasaki", "紫です", "murasaki desu", [
            ("ぶどうは紫です。", "Budou wa murasaki desu.", "Anggur berwarna ungu."),
        ]),
        ("pinku", None, "ピンク", "pinku", "merah muda (pink)", "N4", "noun", "ピンク", "pinku", "ピンクです", "pinku desu", [
            ("桜はピンクです。", "Sakura wa pinku desu.", "Sakura berwarna pink."),
        ]),
        ("orenji", None, "オレンジ", "orenji", "oranye", "N4", "noun", "オレンジ", "orenji", "オレンジです", "orenji desu", [
            ("オレンジ色が好きです。", "Orenji-iro ga suki desu.", "Saya suka warna oranye."),
        ]),
        ("haiiro", "灰色", "はいいろ", "haiiro", "abu-abu", "N3", "noun", "灰色", "haiiro", "灰色です", "haiiro desu", [
            ("空は灰色です。", "Sora wa haiiro desu.", "Langit berwarna abu-abu."),
        ]),
    ],
    "bentuk": [
        ("maru", "丸", "まる", "maru", "lingkaran/bulat", "N4", "noun", "丸", "maru", "丸", "maru", [
            ("丸を描きます。", "Maru o kakimasu.", "Saya menggambar lingkaran."),
        ]),
        ("shikaku", "四角", "しかく", "shikaku", "persegi/kotak", "N4", "noun", "四角", "shikaku", "四角", "shikaku", [
            ("四角を描きます。", "Shikaku o kakimasu.", "Saya menggambar persegi."),
        ]),
        ("sankaku", "三角", "さんかく", "sankaku", "segitiga", "N4", "noun", "三角", "sankaku", "三角", "sankaku", [
            ("三角を描きます。", "Sankaku o kakimasu.", "Saya menggambar segitiga."),
        ]),
        ("hoshi", "星", "ほし", "hoshi", "bintang (bentuk)", "N4", "noun", "星", "hoshi", "星", "hoshi", [
            ("星の形です。", "Hoshi no katachi desu.", "Ini bentuk bintang."),
        ]),
        ("haato", None, "ハート", "haato", "hati (bentuk)", "N3", "noun", "ハート", "haato", "ハート", "haato", [
            ("ハートの形です。", "Haato no katachi desu.", "Ini bentuk hati."),
        ]),
        ("katachi", "形", "かたち", "katachi", "bentuk (kata umum)", "N3", "noun", "形", "katachi", "形", "katachi", [
            ("この形は何ですか。", "Kono katachi wa nan desu ka.", "Bentuk apa ini?"),
        ]),
        ("chouhoukei", "長方形", "ちょうほうけい", "chouhoukei", "persegi panjang", "N2", "noun", "長方形", "chouhoukei", "長方形", "chouhoukei", [
            ("長方形の紙です。", "Chouhoukei no kami desu.", "Ini kertas persegi panjang."),
        ]),
        ("daen", "楕円", "だえん", "daen", "elips", "N2", "noun", "楕円", "daen", "楕円", "daen", [
            ("これは楕円の形です。", "Kore wa daen no katachi desu.", "Ini bentuk elips."),
        ]),
        ("enshuu", "円周", "えんしゅう", "enshuu", "keliling lingkaran", "N2", "noun", "円周", "enshuu", "円周", "enshuu", [
            ("円周を計算します。", "Enshuu o keisan shimasu.", "Menghitung keliling lingkaran."),
        ]),
        ("hankei", "半径", "はんけい", "hankei", "radius", "N2", "noun", "半径", "hankei", "半径", "hankei", [
            ("円の半径を測ります。", "En no hankei o hakarimasu.", "Mengukur radius lingkaran."),
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
