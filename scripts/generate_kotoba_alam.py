import json

# Kotoba vocab — sisa 9 kategori grup "Alam & Lingkungan" (Batch 6 Fase 1).
# Kata benda konkret (nama hewan/tumbuhan/gejala alam) tidak berubah bentuk
# antara casual/formal/keigo — sama seperti alasan di generate_kotoba_ikan.py.
# `_plain_registers()` merefleksikan itu apa adanya per kategori.
#
# Each tuple: (id_suffix, kanji_or_None, hiragana, romaji, meaning, jlptLevel, examples)
# examples: list of (japanese, romaji, translation) — satu contoh per kata,
# prioritas akurasi: hanya kata yang yakin 100% benar yang dimasukkan.


def _plain_registers(word, romaji, noun_label):
    return {
        "casual": f"{word} ({romaji})",
        "formal": f"{word} ({romaji}) — kesopanan ada di kalimat, mis. '~です' / '~があります'",
        "keigo": f"{word} ({romaji}) — tidak ada bentuk keigo khusus untuk {noun_label}",
    }


# category_id -> (icon-ish noun label for registers text, word list)
CATEGORIES = {
    "hewan_darat": ("nama hewan darat", [
        ("inu", "犬", "いぬ", "inu", "anjing", "N5", [
            ("犬が好きです。", "Inu ga suki desu.", "Saya suka anjing."),
        ]),
        ("neko", "猫", "ねこ", "neko", "kucing", "N5", [
            ("猫はかわいいです。", "Neko wa kawaii desu.", "Kucing itu lucu."),
        ]),
        ("usagi", None, "うさぎ", "usagi", "kelinci", "N4", [
            ("うさぎは耳が長いです。", "Usagi wa mimi ga nagai desu.", "Kelinci telinganya panjang."),
        ]),
        ("zou", "象", "ぞう", "zou", "gajah", "N4", [
            ("象は大きいです。", "Zou wa ookii desu.", "Gajah itu besar."),
        ]),
        ("raion", None, "ライオン", "raion", "singa", "N4", [
            ("ライオンは強いです。", "Raion wa tsuyoi desu.", "Singa itu kuat."),
        ]),
        ("tora", "虎", "とら", "tora", "harimau", "N3", [
            ("虎は森にいます。", "Tora wa mori ni imasu.", "Harimau ada di hutan."),
        ]),
        ("kuma", "熊", "くま", "kuma", "beruang", "N3", [
            ("熊に注意してください。", "Kuma ni chuui shite kudasai.", "Tolong hati-hati terhadap beruang."),
        ]),
        ("saru", "猿", "さる", "saru", "monyet", "N3", [
            ("猿が木に登ります。", "Saru ga ki ni noborimasu.", "Monyet memanjat pohon."),
        ]),
        ("uma", "馬", "うま", "uma", "kuda", "N4", [
            ("牧場に馬がいます。", "Bokujou ni uma ga imasu.", "Ada kuda di peternakan."),
        ]),
        ("ushi", "牛", "うし", "ushi", "sapi", "N4", [
            ("牧場に牛がいます。", "Bokujou ni ushi ga imasu.", "Ada sapi di peternakan."),
        ]),
        ("buta", "豚", "ぶた", "buta", "babi", "N4", [
            ("牧場に豚がいます。", "Bokujou ni buta ga imasu.", "Ada babi di peternakan."),
        ]),
        ("hitsuji", "羊", "ひつじ", "hitsuji", "domba", "N3", [
            ("羊の毛は白いです。", "Hitsuji no ke wa shiroi desu.", "Bulu domba berwarna putih."),
        ]),
        ("panda", None, "パンダ", "panda", "panda", "N5", [
            ("パンダが好きです。", "Panda ga suki desu.", "Saya suka panda."),
        ]),
        ("kirin", None, "キリン", "kirin", "jerapah", "N4", [
            ("キリンは首が長いです。", "Kirin wa kubi ga nagai desu.", "Jerapah lehernya panjang."),
        ]),
        ("nezumi", None, "ねずみ", "nezumi", "tikus", "N4", [
            ("家にねずみがいます。", "Ie ni nezumi ga imasu.", "Ada tikus di rumah."),
        ]),
        ("shika", "鹿", "しか", "shika", "rusa", "N3", [
            ("公園に鹿がいます。", "Kouen ni shika ga imasu.", "Ada rusa di taman."),
        ]),
        ("koala", None, "コアラ", "koala", "koala", "N5", [
            ("コアラはかわいいです。", "Koala wa kawaii desu.", "Koala itu lucu."),
        ]),
        ("kame", "亀", "かめ", "kame", "kura-kura", "N3", [
            ("亀はゆっくり歩きます。", "Kame wa yukkuri arukimasu.", "Kura-kura berjalan pelan."),
        ]),
        ("hebi", "蛇", "へび", "hebi", "ular", "N3", [
            ("蛇は怖いです。", "Hebi wa kowai desu.", "Ular itu menakutkan."),
        ]),
        ("kaeru", "蛙", "かえる", "kaeru", "katak", "N3", [
            ("田んぼに蛙がいます。", "Tanbo ni kaeru ga imasu.", "Ada katak di sawah."),
        ]),
        ("risu", None, "リス", "risu", "tupai", "N3", [
            ("木にリスがいます。", "Ki ni risu ga imasu.", "Ada tupai di pohon."),
        ]),
        ("ookami", "狼", "おおかみ", "ookami", "serigala", "N2", [
            ("狼は森にいます。", "Ookami wa mori ni imasu.", "Serigala ada di hutan."),
        ]),
    ]),
    "burung": ("nama burung", [
        ("tori", "鳥", "とり", "tori", "burung", "N5", [
            ("鳥が空を飛びます。", "Tori ga sora o tobimasu.", "Burung terbang di langit."),
        ]),
        ("niwatori", "鶏", "にわとり", "niwatori", "ayam", "N4", [
            ("庭に鶏がいます。", "Niwa ni niwatori ga imasu.", "Ada ayam di halaman."),
        ]),
        ("ahiru", None, "アヒル", "ahiru", "bebek", "N4", [
            ("池にアヒルがいます。", "Ike ni ahiru ga imasu.", "Ada bebek di kolam."),
        ]),
        ("suzume", "雀", "すずめ", "suzume", "burung pipit", "N3", [
            ("雀が木にいます。", "Suzume ga ki ni imasu.", "Ada burung pipit di pohon."),
        ]),
        ("karasu", None, "からす", "karasu", "burung gagak", "N3", [
            ("カラスは黒いです。", "Karasu wa kuroi desu.", "Burung gagak berwarna hitam."),
        ]),
        ("hato", "鳩", "はと", "hato", "burung merpati", "N3", [
            ("公園に鳩がいます。", "Kouen ni hato ga imasu.", "Ada burung merpati di taman."),
        ]),
        ("tsuru", "鶴", "つる", "tsuru", "burung bangau", "N3", [
            ("折り紙で鶴を作ります。", "Origami de tsuru o tsukurimasu.", "Saya membuat burung bangau dari origami."),
        ]),
        ("fukurou", None, "ふくろう", "fukurou", "burung hantu", "N3", [
            ("ふくろうは夜に活動します。", "Fukurou wa yoru ni katsudou shimasu.", "Burung hantu aktif di malam hari."),
        ]),
        ("taka", "鷹", "たか", "taka", "burung elang", "N3", [
            ("鷹は空を飛びます。", "Taka wa sora o tobimasu.", "Elang terbang di langit."),
        ]),
        ("pengin", None, "ペンギン", "pengin", "penguin", "N5", [
            ("ペンギンは飛べません。", "Pengin wa tobemasen.", "Penguin tidak bisa terbang."),
        ]),
        ("hakuchou", "白鳥", "はくちょう", "hakuchou", "burung angsa", "N3", [
            ("白鳥は白いです。", "Hakuchou wa shiroi desu.", "Burung angsa berwarna putih."),
        ]),
        ("kiji", "雉", "きじ", "kiji", "burung pegar (burung nasional Jepang)", "N2", [
            ("雉は日本の国鳥です。", "Kiji wa Nihon no kokuchou desu.", "Burung pegar adalah burung nasional Jepang."),
        ]),
        ("inko", None, "インコ", "inko", "burung parkit", "N3", [
            ("インコを飼っています。", "Inko o katte imasu.", "Saya memelihara burung parkit."),
        ]),
    ]),
    "serangga": ("nama serangga", [
        ("mushi", "虫", "むし", "mushi", "serangga", "N5", [
            ("虫が好きではありません。", "Mushi ga suki de wa arimasen.", "Saya tidak suka serangga."),
        ]),
        ("chou", "蝶", "ちょう", "chou", "kupu-kupu", "N3", [
            ("花に蝶がいます。", "Hana ni chou ga imasu.", "Ada kupu-kupu di bunga."),
        ]),
        ("hachi", "蜂", "はち", "hachi", "lebah", "N3", [
            ("蜂に刺されました。", "Hachi ni sasaremashita.", "Saya disengat lebah."),
        ]),
        ("ari", None, "あり", "ari", "semut", "N3", [
            ("ありは小さいです。", "Ari wa chiisai desu.", "Semut itu kecil."),
        ]),
        ("ka", "蚊", "か", "ka", "nyamuk", "N3", [
            ("蚊に刺されました。", "Ka ni sasaremashita.", "Saya digigit nyamuk."),
        ]),
        ("hae", None, "はえ", "hae", "lalat", "N3", [
            ("はえがうるさいです。", "Hae ga urusai desu.", "Lalat itu berisik."),
        ]),
        ("kumo", None, "くも", "kumo", "laba-laba", "N3", [
            ("部屋にくもがいます。", "Heya ni kumo ga imasu.", "Ada laba-laba di kamar."),
        ]),
        ("tonbo", None, "とんぼ", "tonbo", "capung", "N2", [
            ("とんぼが飛んでいます。", "Tonbo ga tonde imasu.", "Capung sedang terbang."),
        ]),
        ("semi", "蝉", "せみ", "semi", "tonggeret (cicada)", "N2", [
            ("夏になるとせみが鳴きます。", "Natsu ni naru to semi ga nakimasu.", "Saat musim panas tiba, tonggeret bersuara."),
        ]),
        ("kabutomushi", None, "かぶとむし", "kabutomushi", "kumbang badak", "N3", [
            ("男の子はかぶとむしが好きです。", "Otoko no ko wa kabutomushi ga suki desu.", "Anak laki-laki suka kumbang badak."),
        ]),
        ("tentoumushi", None, "てんとうむし", "tentoumushi", "kepik (ladybug)", "N3", [
            ("てんとうむしは赤いです。", "Tentoumushi wa akai desu.", "Kepik itu berwarna merah."),
        ]),
        ("batta", None, "ばった", "batta", "belalang", "N3", [
            ("バッタが跳びます。", "Batta ga tobimasu.", "Belalang melompat."),
        ]),
        ("kuwagata", None, "くわがた", "kuwagata", "kumbang tanduk rusa (stag beetle)", "N3", [
            ("クワガタを捕まえました。", "Kuwagata o tsukamaemashita.", "Saya menangkap kumbang tanduk rusa."),
        ]),
    ]),
    "pohon": ("nama pohon", [
        ("ki", "木", "き", "ki", "pohon", "N5", [
            ("木の下で休みます。", "Ki no shita de yasumimasu.", "Saya beristirahat di bawah pohon."),
        ]),
        ("sakura", "桜", "さくら", "sakura", "pohon sakura", "N4", [
            ("桜がきれいです。", "Sakura ga kirei desu.", "Bunga sakura itu indah."),
        ]),
        ("matsu", "松", "まつ", "matsu", "pohon pinus", "N3", [
            ("庭に松があります。", "Niwa ni matsu ga arimasu.", "Ada pohon pinus di halaman."),
        ]),
        ("take", "竹", "たけ", "take", "bambu", "N3", [
            ("竹はまっすぐです。", "Take wa massugu desu.", "Bambu itu lurus."),
        ]),
        ("momiji", "紅葉", "もみじ", "momiji", "pohon maple (momiji)", "N3", [
            ("秋にもみじが赤くなります。", "Aki ni momiji ga akaku narimasu.", "Di musim gugur, daun momiji menjadi merah."),
        ]),
        ("yashi", "椰子", "やし", "yashi", "pohon kelapa/palem", "N2", [
            ("海に椰子の木があります。", "Umi ni yashi no ki ga arimasu.", "Ada pohon kelapa di pantai."),
        ]),
        ("ichou", "銀杏", "いちょう", "ichou", "pohon ginkgo", "N2", [
            ("いちょうの葉は黄色いです。", "Ichou no ha wa kiiroi desu.", "Daun ginkgo berwarna kuning."),
        ]),
        ("sugi", "杉", "すぎ", "sugi", "pohon cemara Jepang (cedar)", "N2", [
            ("山に杉がたくさんあります。", "Yama ni sugi ga takusan arimasu.", "Ada banyak pohon cemara Jepang di gunung."),
        ]),
    ]),
    "bunga_tanaman": ("nama bunga atau tanaman", [
        ("hana", "花", "はな", "hana", "bunga", "N5", [
            ("花が咲きます。", "Hana ga sakimasu.", "Bunga mekar."),
        ]),
        ("bara", None, "バラ", "bara", "bunga mawar", "N3", [
            ("庭にバラがあります。", "Niwa ni bara ga arimasu.", "Ada bunga mawar di halaman."),
        ]),
        ("yuri", None, "ゆり", "yuri", "bunga lili", "N2", [
            ("ゆりはいい香りです。", "Yuri wa ii kaori desu.", "Bunga lili baunya harum."),
        ]),
        ("himawari", None, "ひまわり", "himawari", "bunga matahari", "N3", [
            ("夏にひまわりが咲きます。", "Natsu ni himawari ga sakimasu.", "Bunga matahari mekar di musim panas."),
        ]),
        ("tanpopo", None, "たんぽぽ", "tanpopo", "bunga dandelion", "N2", [
            ("たんぽぽは黄色いです。", "Tanpopo wa kiiroi desu.", "Bunga dandelion berwarna kuning."),
        ]),
        ("ajisai", None, "あじさい", "ajisai", "bunga hydrangea", "N2", [
            ("梅雨にあじさいが咲きます。", "Tsuyu ni ajisai ga sakimasu.", "Bunga hydrangea mekar di musim hujan."),
        ]),
        ("sumire", None, "すみれ", "sumire", "bunga violet", "N2", [
            ("すみれは紫色です。", "Sumire wa murasakiiro desu.", "Bunga violet berwarna ungu."),
        ]),
        ("ume", "梅", "うめ", "ume", "bunga/pohon plum (ume)", "N3", [
            ("梅の花が咲きました。", "Ume no hana ga sakimashita.", "Bunga plum sudah mekar."),
        ]),
        ("shokubutsu", "植物", "しょくぶつ", "shokubutsu", "tanaman/tumbuhan", "N4", [
            ("植物を育てます。", "Shokubutsu o sodatemasu.", "Saya merawat tanaman."),
        ]),
    ]),
    "buah": ("nama buah", [
        ("ringo", None, "りんご", "ringo", "apel", "N5", [
            ("りんごを食べます。", "Ringo o tabemasu.", "Saya makan apel."),
        ]),
        ("banana", None, "バナナ", "banana", "pisang", "N5", [
            ("バナナが好きです。", "Banana ga suki desu.", "Saya suka pisang."),
        ]),
        ("mikan", None, "みかん", "mikan", "jeruk mandarin", "N4", [
            ("冬にみかんを食べます。", "Fuyu ni mikan o tabemasu.", "Di musim dingin, saya makan jeruk mandarin."),
        ]),
        ("budou", None, "ぶどう", "budou", "anggur", "N4", [
            ("ぶどうは甘いです。", "Budou wa amai desu.", "Anggur itu manis."),
        ]),
        ("momo", "桃", "もも", "momo", "buah persik", "N3", [
            ("桃はジューシーです。", "Momo wa juushii desu.", "Buah persik itu berair (juicy)."),
        ]),
        ("suika", None, "すいか", "suika", "semangka", "N3", [
            ("夏にすいかを食べます。", "Natsu ni suika o tabemasu.", "Di musim panas, saya makan semangka."),
        ]),
        ("ichigo", None, "いちご", "ichigo", "stroberi", "N4", [
            ("いちごが好きです。", "Ichigo ga suki desu.", "Saya suka stroberi."),
        ]),
        ("nashi", "梨", "なし", "nashi", "buah pir (pir Asia)", "N3", [
            ("梨は水分が多いです。", "Nashi wa suibun ga ooi desu.", "Buah pir banyak mengandung air."),
        ]),
        ("kaki", "柿", "かき", "kaki", "buah kesemek (persimmon)", "N2", [
            ("秋に柿を食べます。", "Aki ni kaki o tabemasu.", "Di musim gugur, saya makan buah kesemek."),
        ]),
        ("remon", None, "レモン", "remon", "lemon", "N4", [
            ("レモンは酸っぱいです。", "Remon wa suppai desu.", "Lemon itu asam."),
        ]),
        ("meron", None, "メロン", "meron", "melon", "N4", [
            ("メロンは高いです。", "Meron wa takai desu.", "Melon itu mahal."),
        ]),
        ("papaiya", None, "パパイヤ", "papaiya", "pepaya", "N3", [
            ("パパイヤは甘いです。", "Papaiya wa amai desu.", "Pepaya itu manis."),
        ]),
        ("anzu", "杏", "あんず", "anzu", "buah aprikot", "N2", [
            ("あんずジャムを作ります。", "Anzu jamu o tsukurimasu.", "Saya membuat selai aprikot."),
        ]),
        ("sakuranbo", None, "さくらんぼ", "sakuranbo", "buah ceri", "N3", [
            ("さくらんぼは小さいです。", "Sakuranbo wa chiisai desu.", "Buah ceri itu kecil."),
        ]),
    ]),
    "sayuran": ("nama sayuran", [
        ("yasai", "野菜", "やさい", "yasai", "sayuran (umum)", "N5", [
            ("野菜を食べましょう。", "Yasai o tabemashou.", "Ayo makan sayur."),
        ]),
        ("ninjin", "人参", "にんじん", "ninjin", "wortel", "N4", [
            ("にんじんは体にいいです。", "Ninjin wa karada ni ii desu.", "Wortel baik untuk tubuh."),
        ]),
        ("jagaimo", None, "じゃがいも", "jagaimo", "kentang", "N4", [
            ("じゃがいもを買いました。", "Jagaimo o kaimashita.", "Saya membeli kentang."),
        ]),
        ("tamanegi", None, "たまねぎ", "tamanegi", "bawang bombai", "N3", [
            ("たまねぎを切ります。", "Tamanegi o kirimasu.", "Saya memotong bawang bombai."),
        ]),
        ("kyabetsu", None, "キャベツ", "kyabetsu", "kubis", "N4", [
            ("キャベツはサラダに入れます。", "Kyabetsu wa sarada ni iremasu.", "Kubis dimasukkan ke dalam salad."),
        ]),
        ("tomato", None, "トマト", "tomato", "tomat", "N5", [
            ("トマトは赤いです。", "Tomato wa akai desu.", "Tomat berwarna merah."),
        ]),
        ("kyuuri", None, "きゅうり", "kyuuri", "timun", "N3", [
            ("きゅうりのサラダを作ります。", "Kyuuri no sarada o tsukurimasu.", "Saya membuat salad timun."),
        ]),
        ("nasu", None, "なす", "nasu", "terong", "N3", [
            ("なすを焼きます。", "Nasu o yakimasu.", "Saya memanggang terong."),
        ]),
        ("daikon", "大根", "だいこん", "daikon", "lobak putih", "N3", [
            ("大根のスープを作ります。", "Daikon no suupu o tsukurimasu.", "Saya membuat sup lobak."),
        ]),
        ("hourensou", None, "ほうれんそう", "hourensou", "bayam", "N3", [
            ("ほうれんそうは鉄分が多いです。", "Hourensou wa tetsubun ga ooi desu.", "Bayam banyak mengandung zat besi."),
        ]),
        ("piiman", None, "ピーマン", "piiman", "paprika hijau", "N4", [
            ("ピーマンは苦いです。", "Piiman wa nigai desu.", "Paprika hijau itu pahit."),
        ]),
        ("renkon", None, "れんこん", "renkon", "akar teratai", "N2", [
            ("れんこんを食べます。", "Renkon o tabemasu.", "Saya makan akar teratai."),
        ]),
        ("negi", None, "ねぎ", "negi", "daun bawang", "N3", [
            ("ねぎを切ります。", "Negi o kirimasu.", "Saya memotong daun bawang."),
        ]),
        ("ninniku", None, "にんにく", "ninniku", "bawang putih", "N3", [
            ("料理ににんにくを入れます。", "Ryouri ni ninniku o iremasu.", "Saya memasukkan bawang putih ke masakan."),
        ]),
    ]),
    "cuaca": ("istilah cuaca", [
        ("tenki", "天気", "てんき", "tenki", "cuaca", "N5", [
            ("今日は天気がいいです。", "Kyou wa tenki ga ii desu.", "Hari ini cuacanya bagus."),
        ]),
        ("hare", "晴れ", "はれ", "hare", "cerah", "N4", [
            ("明日は晴れです。", "Ashita wa hare desu.", "Besok cuacanya cerah."),
        ]),
        ("ame", "雨", "あめ", "ame", "hujan", "N5", [
            ("雨が降っています。", "Ame ga futte imasu.", "Sedang turun hujan."),
        ]),
        ("kumori", "曇り", "くもり", "kumori", "mendung/berawan", "N4", [
            ("今日は曇りです。", "Kyou wa kumori desu.", "Hari ini mendung."),
        ]),
        ("yuki", "雪", "ゆき", "yuki", "salju", "N4", [
            ("冬に雪が降ります。", "Fuyu ni yuki ga furimasu.", "Di musim dingin, salju turun."),
        ]),
        ("kaze", "風", "かぜ", "kaze", "angin", "N5", [
            ("強い風が吹いています。", "Tsuyoi kaze ga fuite imasu.", "Angin kencang sedang bertiup."),
        ]),
        ("kaminari", "雷", "かみなり", "kaminari", "petir/guntur", "N3", [
            ("雷が鳴っています。", "Kaminari ga natte imasu.", "Petir sedang menggelegar."),
        ]),
        ("kiri", "霧", "きり", "kiri", "kabut", "N3", [
            ("今朝は霧が深いです。", "Kesa wa kiri ga fukai desu.", "Pagi ini kabutnya tebal."),
        ]),
        ("taifuu", "台風", "たいふう", "taifuu", "topan/badai", "N3", [
            ("台風が来ています。", "Taifuu ga kite imasu.", "Topan sedang datang."),
        ]),
        ("niji", "虹", "にじ", "niji", "pelangi", "N3", [
            ("空に虹が出ました。", "Sora ni niji ga demashita.", "Pelangi muncul di langit."),
        ]),
        ("tsuyu", "梅雨", "つゆ", "tsuyu", "musim hujan (Jepang)", "N3", [
            ("六月はつゆです。", "Rokugatsu wa tsuyu desu.", "Bulan Juni adalah musim hujan."),
        ]),
        ("hyou", "雹", "ひょう", "hyou", "hujan es (hail)", "N2", [
            ("雹が降りました。", "Hyou ga furimashita.", "Hujan es turun."),
        ]),
    ]),
    "bencana_alam": ("istilah bencana alam", [
        ("jishin", "地震", "じしん", "jishin", "gempa bumi", "N4", [
            ("昨日地震がありました。", "Kinou jishin ga arimashita.", "Kemarin ada gempa bumi."),
        ]),
        ("tsunami", "津波", "つなみ", "tsunami", "tsunami", "N3", [
            ("地震の後、津波が来ました。", "Jishin no ato, tsunami ga kimashita.", "Setelah gempa, tsunami datang."),
        ]),
        ("kouzui", "洪水", "こうずい", "kouzui", "banjir", "N3", [
            ("大雨で洪水になりました。", "Ooame de kouzui ni narimashita.", "Karena hujan deras, terjadi banjir."),
        ]),
        ("kaji", "火事", "かじ", "kaji", "kebakaran", "N3", [
            ("近くで火事がありました。", "Chikaku de kaji ga arimashita.", "Ada kebakaran di dekat sini."),
        ]),
        ("funka", "噴火", "ふんか", "funka", "letusan gunung berapi", "N2", [
            ("火山が噴火しました。", "Kazan ga funka shimashita.", "Gunung berapi meletus."),
        ]),
        ("teiden", "停電", "ていでん", "teiden", "pemadaman listrik", "N2", [
            ("台風で停電しました。", "Taifuu de teiden shimashita.", "Karena topan, listrik padam."),
        ]),
        ("kazan", "火山", "かざん", "kazan", "gunung berapi", "N3", [
            ("日本には火山が多いです。", "Nihon ni wa kazan ga ooi desu.", "Di Jepang ada banyak gunung berapi."),
        ]),
        ("hinan", "避難", "ひなん", "hinan", "evakuasi/mengungsi", "N2", [
            ("地震の時は避難してください。", "Jishin no toki wa hinan shite kudasai.", "Saat gempa, tolong mengungsi."),
        ]),
        ("arashi", "嵐", "あらし", "arashi", "badai", "N3", [
            ("今夜は嵐になります。", "Kon'ya wa arashi ni narimasu.", "Malam ini akan ada badai."),
        ]),
        ("bousai", "防災", "ぼうさい", "bousai", "mitigasi bencana", "N2", [
            ("学校で防災訓練をします。", "Gakkou de bousai kunren o shimasu.", "Di sekolah kami melakukan latihan mitigasi bencana."),
        ]),
        ("hinanjo", "避難所", "ひなんじょ", "hinanjo", "tempat pengungsian", "N2", [
            ("避難所に行きます。", "Hinanjo ni ikimasu.", "Saya pergi ke tempat pengungsian."),
        ]),
    ]),
}


def build_entries(category_id, noun_label, words):
    entries = []
    for suffix, kanji, hiragana, romaji, meaning, level, examples in words:
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
            "wordType": "noun",
            "registers": _plain_registers(hiragana, romaji, noun_label),
            "sentenceExamples": [
                {"japanese": jp, "romaji": ro, "translation": tr}
                for jp, ro, tr in examples
            ],
            "imagePath": f"kotoba_images/{category_id}/{entry_id}.png",
        })
    return entries


def main():
    total = 0
    for category_id, (noun_label, words) in CATEGORIES.items():
        data = build_entries(category_id, noun_label, words)
        path = f"assets/data/kotoba/{category_id}.json"
        with open(path, "w", encoding="utf-8") as f:
            json.dump(data, f, ensure_ascii=False, indent=2)
        print(f"Wrote {len(data)} entries to {path}")
        total += len(data)
    print(f"Total (excl. ikan): {total}")


if __name__ == "__main__":
    main()
