import json

# Kotoba vocab — grup "Tubuh & Kesehatan" (Batch 7).
#
# This group mixes nouns, verbs, and adjectives, so registers are built
# per-entry via `_registers(casual_form, casual_romaji, formal_form,
# formal_romaji, noun_label=None)` instead of one type-specific helper:
#   - nouns: casual="X (romaji)", formal same word + honest note about
#     politeness living in the sentence (mirrors generate_kotoba_alam.py)
#   - verbs: casual=dictionary form, formal=~masu form (plain grammar fact)
#   - i-adjectives / na-adjectives / suru-nouns: casual=plain form,
#     formal=plain+desu or +shimasu (also plain grammar fact)
# Keigo is always the honest "no special form" note — the classical
# adjective+gozaimasu conjugation (e.g. 痛うございます) is skipped as too
# easy to get subtly wrong outside the 2-3 textbook-canonical examples.
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
    "anggota_tubuh": [
        ("atama", "頭", "あたま", "atama", "kepala", "N5", "noun", "頭", "atama", "頭", "atama", [
            ("頭が痛いです。", "Atama ga itai desu.", "Kepala saya sakit."),
        ]),
        ("kao", "顔", "かお", "kao", "wajah", "N5", "noun", "顔", "kao", "顔", "kao", [
            ("顔を洗います。", "Kao o araimasu.", "Saya mencuci wajah."),
        ]),
        ("me", "目", "め", "me", "mata", "N5", "noun", "目", "me", "目", "me", [
            ("目が大きいです。", "Me ga ookii desu.", "Matanya besar."),
        ]),
        ("hana", "鼻", "はな", "hana", "hidung", "N5", "noun", "鼻", "hana", "鼻", "hana", [
            ("鼻が高いです。", "Hana ga takai desu.", "Hidungnya mancung."),
        ]),
        ("mimi", "耳", "みみ", "mimi", "telinga", "N5", "noun", "耳", "mimi", "耳", "mimi", [
            ("耳が痛いです。", "Mimi ga itai desu.", "Telinga saya sakit."),
        ]),
        ("kuchi", "口", "くち", "kuchi", "mulut", "N5", "noun", "口", "kuchi", "口", "kuchi", [
            ("口を開けます。", "Kuchi o akemasu.", "Saya membuka mulut."),
        ]),
        ("ha", "歯", "は", "ha", "gigi", "N4", "noun", "歯", "ha", "歯", "ha", [
            ("歯を磨きます。", "Ha o migakimasu.", "Saya menyikat gigi."),
        ]),
        ("te", "手", "て", "te", "tangan", "N5", "noun", "手", "te", "手", "te", [
            ("手を洗います。", "Te o araimasu.", "Saya mencuci tangan."),
        ]),
        ("ashi", "足", "あし", "ashi", "kaki", "N5", "noun", "足", "ashi", "足", "ashi", [
            ("足が痛いです。", "Ashi ga itai desu.", "Kaki saya sakit."),
        ]),
        ("kubi", "首", "くび", "kubi", "leher", "N3", "noun", "首", "kubi", "首", "kubi", [
            ("首が痛いです。", "Kubi ga itai desu.", "Leher saya sakit."),
        ]),
        ("kata", "肩", "かた", "kata", "bahu/pundak", "N3", "noun", "肩", "kata", "肩", "kata", [
            ("肩が凝ります。", "Kata ga korimasu.", "Bahu saya pegal."),
        ]),
        ("onaka", "お腹", "おなか", "onaka", "perut", "N4", "noun", "お腹", "onaka", "お腹", "onaka", [
            ("お腹が痛いです。", "Onaka ga itai desu.", "Perut saya sakit."),
        ]),
        ("senaka", "背中", "せなか", "senaka", "punggung", "N3", "noun", "背中", "senaka", "背中", "senaka", [
            ("背中が痛いです。", "Senaka ga itai desu.", "Punggung saya sakit."),
        ]),
        ("yubi", "指", "ゆび", "yubi", "jari", "N4", "noun", "指", "yubi", "指", "yubi", [
            ("指で指します。", "Yubi de sashimasu.", "Saya menunjuk dengan jari."),
        ]),
        ("kami", "髪", "かみ", "kami", "rambut", "N4", "noun", "髪", "kami", "髪", "kami", [
            ("髪が長いです。", "Kami ga nagai desu.", "Rambutnya panjang."),
        ]),
        ("mune", "胸", "むね", "mune", "dada", "N3", "noun", "胸", "mune", "胸", "mune", [
            ("胸が痛いです。", "Mune ga itai desu.", "Dada saya sakit."),
        ]),
        ("hiza", "膝", "ひざ", "hiza", "lutut", "N3", "noun", "膝", "hiza", "膝", "hiza", [
            ("膝が痛いです。", "Hiza ga itai desu.", "Lutut saya sakit."),
        ]),
        # N1/N2/N3 addition (2026-07-20, twelfth batch): internal-anatomy
        # nouns, for Kombinasi Kanji pool depth.
        ("shinzou", "心臓", "しんぞう", "shinzou", "jantung", "N2", "noun", "心臓", "shinzou", "心臓", "shinzou", [
            ("心臓がドキドキします。", "Shinzou ga dokidoki shimasu.", "Jantung saya berdebar-debar."),
        ]),
        ("naizou", "内臓", "ないぞう", "naizou", "organ dalam", "N1", "noun", "内臓", "naizou", "内臓", "naizou", [
            ("内臓の検査を受けます。", "Naizou no kensa o ukemasu.", "Saya menjalani pemeriksaan organ dalam."),
        ]),
        ("kinniku", "筋肉", "きんにく", "kinniku", "otot", "N3", "noun", "筋肉", "kinniku", "筋肉", "kinniku", [
            ("筋肉を鍛えます。", "Kinniku o kitaemasu.", "Saya melatih otot."),
        ]),
        ("kansetsu", "関節", "かんせつ", "kansetsu", "sendi", "N2", "noun", "関節", "kansetsu", "関節", "kansetsu", [
            ("関節が痛いです。", "Kansetsu ga itai desu.", "Sendi saya sakit."),
        ]),
        ("kekkan", "血管", "けっかん", "kekkan", "pembuluh darah", "N2", "noun", "血管", "kekkan", "血管", "kekkan", [
            ("血管が細くなっています。", "Kekkan ga hosoku natte imasu.", "Pembuluh darahnya menyempit."),
        ]),
        ("kamigata", "髪型", "かみがた", "kamigata", "gaya rambut", "N2", "noun", "髪型", "kamigata", "髪型", "kamigata", [
            ("髪型を変えました。", "Kamigata o kaemashita.", "Saya mengubah gaya rambut."),
        ]),
        ("shisei", "姿勢", "しせい", "shisei", "postur tubuh", "N2", "noun", "姿勢", "shisei", "姿勢", "shisei", [
            ("姿勢を正してください。", "Shisei o tadashite kudasai.", "Tolong perbaiki posisi tubuh. (postur tubuh)"),
        ]),
        ("jintai", "人体", "じんたい", "jintai", "tubuh manusia", "N2", "noun", "人体", "jintai", "人体", "jintai", [
            ("人体の勉強をします。", "Jintai no benkyou o shimasu.", "Belajar tubuh manusia."),
        ]),
        ("ashikoshi", "足腰", "あしこし", "ashikoshi", "kaki dan pinggang", "N2", "noun", "足腰", "ashikoshi", "足腰", "ashikoshi", [
            ("年を取ると足腰が弱くなる。", "Toshi o toru to ashikoshi ga yowaku naru.", "Saat tua, kaki dan pinggang menjadi lemah."),
        ]),
        ("ashimoto", "足元", "あしもと", "ashimoto", "langkah kaki/area bawah kaki", "N2", "noun", "足元", "ashimoto", "足元", "ashimoto", [
            ("足元に気をつけてください。", "Ashimoto ni ki o tsukete kudasai.", "Hati-hati dengan langkah kaki Anda."),
        ]),
        ("shinchou", "身長", "しんちょう", "shinchou", "tinggi badan", "N3", "noun", "身長", "shinchou", "身長", "shinchou", [
            ("身長を測ります。", "Shinchou o hakarimasu.", "Mengukur tinggi badan."),
        ]),
        ("ashiato", "足跡", "あしあと", "ashiato", "jejak kaki", "N2", "noun", "足跡", "ashiato", "足跡", "ashiato", [
            ("雪の上に足跡があります。", "Yuki no ue ni ashiato ga arimasu.", "Ada jejak kaki di atas salju."),
        ]),
        ("shiraga", "白髪", "しらが", "shiraga", "rambut putih", "N2", "noun", "白髪", "shiraga", "白髪", "shiraga", [
            ("白髪が増えました。", "Shiraga ga fuemashita.", "Rambut putih bertambah."),
        ]),
    ],
    "penyakit_gejala": [
        ("kaze", "風邪", "かぜ", "kaze", "flu/masuk angin (common cold)", "N4", "noun", "風邪", "kaze", "風邪", "kaze", [
            ("風邪を引きました。", "Kaze o hikimashita.", "Saya terkena flu."),
        ]),
        ("netsu", "熱", "ねつ", "netsu", "demam", "N4", "noun", "熱", "netsu", "熱", "netsu", [
            ("熱があります。", "Netsu ga arimasu.", "Saya demam."),
        ]),
        ("seki", "咳", "せき", "seki", "batuk", "N3", "noun", "咳", "seki", "咳", "seki", [
            ("咳が出ます。", "Seki ga demasu.", "Saya batuk."),
        ]),
        ("hanamizu", "鼻水", "はなみず", "hanamizu", "ingus/pilek", "N3", "noun", "鼻水", "hanamizu", "鼻水", "hanamizu", [
            ("鼻水が出ます。", "Hanamizu ga demasu.", "Saya pilek."),
        ]),
        ("itai", "痛い", "いたい", "itai", "sakit (nyeri)", "N5", "adjective", "痛い", "itai", "痛いです", "itai desu", [
            ("お腹が痛いです。", "Onaka ga itai desu.", "Perut saya sakit."),
        ]),
        ("kega", "怪我", "けが", "kega", "luka/cedera", "N3", "noun", "怪我", "kega", "怪我", "kega", [
            ("怪我をしました。", "Kega o shimashita.", "Saya terluka."),
        ]),
        ("arerugii", None, "アレルギー", "arerugii", "alergi", "N3", "noun", "アレルギー", "arerugii", "アレルギー", "arerugii", [
            ("アレルギーがあります。", "Arerugii ga arimasu.", "Saya punya alergi."),
        ]),
        ("kafunshou", "花粉症", "かふんしょう", "kafunshou", "alergi serbuk sari (hay fever)", "N2", "noun", "花粉症", "kafunshou", "花粉症", "kafunshou", [
            ("春は花粉症がつらいです。", "Haru wa kafunshou ga tsurai desu.", "Musim semi, alergi serbuk sari itu berat."),
        ]),
        ("geri", "下痢", "げり", "geri", "diare", "N2", "noun", "下痢", "geri", "下痢", "geri", [
            ("下痢になりました。", "Geri ni narimashita.", "Saya terkena diare."),
        ]),
        ("memai", None, "めまい", "memai", "pusing (vertigo)", "N2", "noun", "めまい", "memai", "めまい", "memai", [
            ("めまいがします。", "Memai ga shimasu.", "Saya merasa pusing."),
        ]),
        ("tsukare", "疲れ", "つかれ", "tsukare", "kelelahan", "N3", "noun", "疲れ", "tsukare", "疲れ", "tsukare", [
            ("疲れを感じます。", "Tsukare o kanjimasu.", "Saya merasa lelah."),
        ]),
        # N2/N3 addition (2026-07-20, third batch): pure-kanji medical
        # nouns, for Kombinasi Kanji pool depth.
        ("shindan", "診断", "しんだん", "shindan", "diagnosis", "N2", "noun", "診断", "shindan", "診断", "shindan", [
            ("医者に診断してもらいました。", "Isha ni shindan shite moraimashita.", "Saya didiagnosis oleh dokter."),
        ]),
        ("kansen", "感染", "かんせん", "kansen", "infeksi", "N2", "noun", "感染", "kansen", "感染", "kansen", [
            ("ウイルスに感染しました。", "Uirusu ni kansen shimashita.", "Saya terinfeksi virus."),
        ]),
        ("men'eki", "免疫", "めんえき", "men'eki", "kekebalan/imun", "N2", "noun", "免疫", "men'eki", "免疫", "men'eki", [
            ("免疫力を高めましょう。", "Men'ekiryoku o takamemashou.", "Mari tingkatkan daya tahan tubuh."),
        ]),
        ("shoujou", "症状", "しょうじょう", "shoujou", "gejala", "N3", "noun", "症状", "shoujou", "症状", "shoujou", [
            ("どんな症状がありますか。", "Donna shoujou ga arimasu ka.", "Gejala seperti apa yang Anda rasakan?"),
        ]),
        ("akka", "悪化", "あっか", "akka", "memburuk (kondisi)", "N2", "noun", "悪化", "akka", "悪化", "akka", [
            ("病状が悪化しました。", "Byoujou ga akka shimashita.", "Kondisi penyakitnya memburuk."),
        ]),
        ("kaifuku", "回復", "かいふく", "kaifuku", "pemulihan", "N2", "noun", "回復", "kaifuku", "回復", "kaifuku", [
            ("体調が回復しました。", "Taichou ga kaifuku shimashita.", "Kondisi tubuh saya sudah pulih."),
        ]),
        ("chiryou", "治療", "ちりょう", "chiryou", "pengobatan", "N3", "noun", "治療", "chiryou", "治療", "chiryou", [
            ("病院で治療を受けます。", "Byouin de chiryou o ukemasu.", "Saya menjalani pengobatan di rumah sakit."),
        ]),
        ("yobou", "予防", "よぼう", "yobou", "pencegahan", "N3", "noun", "予防", "yobou", "予防", "yobou", [
            ("手洗いは風邪の予防になります。", "Tearai wa kaze no yobou ni narimasu.", "Cuci tangan adalah pencegahan flu."),
        ]),
        # N2/N3/N4 addition (2026-07-20, eleventh batch): concrete
        # symptom/injury nouns, for Kombinasi Kanji pool depth.
        ("zutsuu", "頭痛", "ずつう", "zutsuu", "sakit kepala", "N3", "noun", "頭痛", "zutsuu", "頭痛", "zutsuu", [
            ("頭痛がします。", "Zutsuu ga shimasu.", "Saya sakit kepala."),
        ]),
        ("fukutsuu", "腹痛", "ふくつう", "fukutsuu", "sakit perut", "N3", "noun", "腹痛", "fukutsuu", "腹痛", "fukutsuu", [
            ("腹痛で学校を休みました。", "Fukutsuu de gakkou o yasumimashita.", "Saya bolos sekolah karena sakit perut."),
        ]),
        ("kossetsu", "骨折", "こっせつ", "kossetsu", "patah tulang", "N2", "noun", "骨折", "kossetsu", "骨折", "kossetsu", [
            ("転んで骨折しました。", "Koronde kossetsu shimashita.", "Saya patah tulang karena jatuh."),
        ]),
        ("shukketsu", "出血", "しゅっけつ", "shukketsu", "pendarahan", "N2", "noun", "出血", "shukketsu", "出血", "shukketsu", [
            ("傷口から出血しています。", "Kizuguchi kara shukketsu shite imasu.", "Luka itu berdarah."),
        ]),
        ("taion", "体温", "たいおん", "taion", "suhu tubuh", "N4", "noun", "体温", "taion", "体温", "taion", [
            ("体温を測ります。", "Taion o hakarimasu.", "Saya mengukur suhu tubuh."),
        ]),
        # N1/N2 addition (2026-07-20, twelfth batch): more medical
        # condition nouns, for Kombinasi Kanji pool depth.
        ("hinketsu", "貧血", "ひんけつ", "hinketsu", "anemia (kurang darah)", "N2", "noun", "貧血", "hinketsu", "貧血", "hinketsu", [
            ("貧血で倒れました。", "Hinketsu de taoremashita.", "Saya pingsan karena anemia."),
        ]),
        ("chuudoku", "中毒", "ちゅうどく", "chuudoku", "keracunan", "N2", "noun", "中毒", "chuudoku", "中毒", "chuudoku", [
            ("食中毒になりました。", "Shoku-chuudoku ni narimashita.", "Saya keracunan makanan."),
        ]),
        ("mahi", "麻痺", "まひ", "mahi", "kelumpuhan/mati rasa", "N1", "noun", "麻痺", "mahi", "麻痺", "mahi", [
            ("手足に麻痺があります。", "Teashi ni mahi ga arimasu.", "Ada kelumpuhan di tangan dan kaki."),
        ]),
        # N2 addition (2026-07-20, thirteenth batch): more everyday
        # medical-condition nouns, for Kombinasi Kanji pool depth.
        ("enshou", "炎症", "えんしょう", "enshou", "peradangan/inflamasi", "N2", "noun", "炎症", "enshou", "炎症", "enshou", [
            ("傷口に炎症が起きています。", "Kizuguchi ni enshou ga okite imasu.", "Terjadi peradangan pada luka itu."),
        ]),
        ("benpi", "便秘", "べんぴ", "benpi", "sembelit", "N2", "noun", "便秘", "benpi", "便秘", "benpi", [
            ("便秘に悩んでいます。", "Benpi ni nayande imasu.", "Saya mengalami sembelit."),
        ]),
        ("shokuyoku", "食欲", "しょくよく", "shokuyoku", "nafsu makan", "N2", "noun", "食欲", "shokuyoku", "食欲", "shokuyoku", [
            ("食欲があります。", "Shokuyoku ga arimasu.", "Nafsu makan ada/baik."),
        ]),
        ("suimin", "睡眠", "すいみん", "suimin", "tidur", "N2", "noun", "睡眠", "suimin", "睡眠", "suimin", [
            ("睡眠が大切です。", "Suimin ga taisetsu desu.", "Waktu Tidur itu penting. (jam tidur, pola tidur)"),
        ]),
        ("mushiba", "虫歯", "むしば", "mushiba", "gigi berlubang", "N2", "noun", "虫歯", "mushiba", "虫歯", "mushiba", [
            ("虫歯が痛いです。", "Mushiba ga itai desu.", "Gigi berlubang sakit."),
        ]),
        ("fushou", "負傷", "ふしょう", "fushou", "luka/cedera", "N1", "noun", "負傷", "fushou", "負傷", "fushou", [
            ("事故で負傷しました。", "Jiko de fushou shimashita.", "Terluka karena kecelakaan."),
        ]),
        ("hirou", "疲労", "ひろう", "hirou", "kelelahan", "N1", "noun", "疲労", "hirou", "疲労", "hirou", [
            ("疲労がたまっています。", "Hirou ga tamatte imasu.", "Kelelahan menumpuk."),
        ]),
        ("guai", "具合", "ぐあい", "guai", "kondisi (kesehatan)", "N4", "noun", "具合", "guai", "具合", "guai", [
            ("具合が悪いです。", "Guai ga warui desu.", "Kondisinya tidak baik (sakit)."),
        ]),
    ],
    "obat_obatan": [
        ("kusuri", "薬", "くすり", "kusuri", "obat", "N4", "noun", "薬", "kusuri", "薬", "kusuri", [
            ("薬を飲みます。", "Kusuri o nomimasu.", "Saya minum obat."),
        ]),
        ("byouin", "病院", "びょういん", "byouin", "rumah sakit", "N5", "noun", "病院", "byouin", "病院", "byouin", [
            ("病院に行きます。", "Byouin ni ikimasu.", "Saya pergi ke rumah sakit."),
        ]),
        ("isha", "医者", "いしゃ", "isha", "dokter", "N5", "noun", "医者", "isha", "医者", "isha", [
            ("医者に診てもらいます。", "Isha ni mite moraimasu.", "Saya diperiksa oleh dokter."),
        ]),
        ("kangoshi", "看護師", "かんごし", "kangoshi", "perawat", "N4", "noun", "看護師", "kangoshi", "看護師", "kangoshi", [
            ("看護師さんが優しいです。", "Kangoshi-san ga yasashii desu.", "Perawatnya baik hati."),
        ]),
        ("yakkyoku", "薬局", "やっきょく", "yakkyoku", "apotek", "N4", "noun", "薬局", "yakkyoku", "薬局", "yakkyoku", [
            ("薬局で薬を買います。", "Yakkyoku de kusuri o kaimasu.", "Saya membeli obat di apotek."),
        ]),
        ("chuusha", "注射", "ちゅうしゃ", "chuusha", "suntikan", "N3", "noun", "注射", "chuusha", "注射", "chuusha", [
            ("注射をします。", "Chuusha o shimasu.", "Saya disuntik."),
        ]),
        ("bansoukou", "絆創膏", "ばんそうこう", "bansoukou", "plester luka (band-aid)", "N2", "noun", "絆創膏", "bansoukou", "絆創膏", "bansoukou", [
            ("絆創膏を貼ります。", "Bansoukou o harimasu.", "Saya menempelkan plester."),
        ]),
        ("taionkei", "体温計", "たいおんけい", "taionkei", "termometer", "N3", "noun", "体温計", "taionkei", "体温計", "taionkei", [
            ("体温計で熱を測ります。", "Taionkei de netsu o hakarimasu.", "Saya mengukur demam dengan termometer."),
        ]),
        ("masuku", None, "マスク", "masuku", "masker", "N4", "noun", "マスク", "masuku", "マスク", "masuku", [
            ("マスクをつけます。", "Masuku o tsukemasu.", "Saya memakai masker."),
        ]),
        ("kenshin", "検診", "けんしん", "kenshin", "pemeriksaan kesehatan", "N2", "noun", "検診", "kenshin", "検診", "kenshin", [
            ("毎年検診を受けます。", "Maitoshi kenshin o ukemasu.", "Saya menjalani pemeriksaan kesehatan setiap tahun."),
        ]),
        # N1/N2 addition (2026-07-20, third batch): pure-kanji pharmacy/
        # treatment nouns, for Kombinasi Kanji pool depth.
        ("shohou", "処方", "しょほう", "shohou", "resep (obat)", "N2", "noun", "処方", "shohou", "処方", "shohou", [
            ("医者が薬を処方しました。", "Isha ga kusuri o shohou shimashita.", "Dokter meresepkan obat."),
        ]),
        ("fukusayou", "副作用", "ふくさよう", "fukusayou", "efek samping", "N2", "noun", "副作用", "fukusayou", "副作用", "fukusayou", [
            ("この薬には副作用があります。", "Kono kusuri ni wa fukusayou ga arimasu.", "Obat ini punya efek samping."),
        ]),
        ("fukuyou", "服用", "ふくよう", "fukuyou", "meminum (obat, formal)", "N1", "noun", "服用", "fukuyou", "服用", "fukuyou", [
            ("食後にこの薬を服用してください。", "Shokugo ni kono kusuri o fukuyou shite kudasai.", "Tolong minum obat ini setelah makan."),
        ]),
        ("masui", "麻酔", "ますい", "masui", "anestesi/bius", "N1", "noun", "麻酔", "masui", "麻酔", "masui", [
            ("手術の前に麻酔をかけます。", "Shujutsu no mae ni masui o kakemasu.", "Sebelum operasi, dilakukan pembiusan."),
        ]),
        # N2 addition (2026-07-20, twelfth batch): more pharmacy/first-aid
        # nouns, for Kombinasi Kanji pool depth.
        ("shoudoku", "消毒", "しょうどく", "shoudoku", "disinfeksi", "N2", "noun", "消毒", "shoudoku", "消毒", "shoudoku", [
            ("傷口を消毒します。", "Kizuguchi o shoudoku shimasu.", "Saya mendisinfeksi luka."),
        ]),
        ("houtai", "包帯", "ほうたい", "houtai", "perban", "N2", "noun", "包帯", "houtai", "包帯", "houtai", [
            ("傷に包帯を巻きます。", "Kizu ni houtai o makimasu.", "Saya membalut luka dengan perban."),
        ]),
        ("jouzai", "錠剤", "じょうざい", "jouzai", "tablet/pil", "N1", "noun", "錠剤", "jouzai", "錠剤", "jouzai", [
            ("この錠剤を一日三回飲みます。", "Kono jouzai o ichinichi sankai nomimasu.", "Saya minum tablet ini tiga kali sehari."),
        ]),
        ("eiyou", "栄養", "えいよう", "eiyou", "gizi/nutrisi", "N2", "noun", "栄養", "eiyou", "栄養", "eiyou", [
            ("栄養をしっかり取ります。", "Eiyou o shikkari torimasu.", "Mengonsumsi nutrisi dengan baik."),
        ]),
        ("kango", "看護", "かんご", "kango", "perawatan (medis)", "N2", "noun", "看護", "kango", "看護", "kango", [
            ("母を看護しています。", "Haha o kango shite imasu.", "Saya merawat ibu."),
        ]),
        ("kenkou", "健康", "けんこう", "kenkou", "kesehatan", "N2", "noun", "健康", "kenkou", "健康", "kenkou", [
            ("健康が大切です。", "Kenkou ga taisetsu desu.", "Kesehatan itu penting."),
        ]),
        ("kensa", "検査", "けんさ", "kensa", "pemeriksaan", "N2", "noun", "検査", "kensa", "検査", "kensa", [
            ("荷物を検査します。", "Nimotsu o kensa shimasu.", "Memeriksa barang. (kesehatan, mesin, kalitas)"),
        ]),
        ("shujutsu", "手術", "しゅじゅつ", "shujutsu", "operasi (medis)", "N2", "noun", "手術", "shujutsu", "手術", "shujutsu", [
            ("手術を受けました。", "Shujutsu o ukemashita.", "Menjalani operasi."),
        ]),
        ("kurumaisu", "車椅子", "くるまいす", "kurumaisu", "kursi roda", "N2", "noun", "車椅子", "kurumaisu", "車椅子", "kurumaisu", [
            ("車椅子を押します。", "Kurumaisu o oshimasu.", "Mendorong kursi roda."),
        ]),
        ("geka", "外科", "げか", "geka", "bedah (bidang medis)", "N2", "noun", "外科", "geka", "外科", "geka", [
            ("外科で手術します。", "Geka de shujutsu shimasu.", "Operasi di bagian bedah."),
        ]),
        ("naika", "内科", "ないか", "naika", "penyakit dalam (bidang medis)", "N2", "noun", "内科", "naika", "内科", "naika", [
            ("内科に行きます。", "Naika ni ikimasu.", "Pergi ke dokter penyakit dalam."),
        ]),
        ("yuketsu", "輸血", "ゆけつ", "yuketsu", "transfusi darah", "N2", "noun", "輸血", "yuketsu", "輸血", "yuketsu", [
            ("輸血を受けます。", "Yuketsu o ukemasu.", "Menerima transfusi darah."),
        ]),
        ("nyuuin", "入院", "にゅういん", "nyuuin", "dirawat di RS", "N4", "noun", "入院", "nyuuin", "入院", "nyuuin", [
            ("入院しました。", "Nyuuin shimashita.", "Dirawat di rumah sakit."),
        ]),
    ],
    "olahraga": [
        ("supootsu", None, "スポーツ", "supootsu", "olahraga", "N5", "noun", "スポーツ", "supootsu", "スポーツ", "supootsu", [
            ("スポーツが好きです。", "Supootsu ga suki desu.", "Saya suka olahraga."),
        ]),
        ("sakkaa", None, "サッカー", "sakkaa", "sepak bola", "N5", "noun", "サッカー", "sakkaa", "サッカー", "sakkaa", [
            ("サッカーをします。", "Sakkaa o shimasu.", "Saya bermain sepak bola."),
        ]),
        ("yakyuu", "野球", "やきゅう", "yakyuu", "bisbol", "N4", "noun", "野球", "yakyuu", "野球", "yakyuu", [
            ("野球を見ます。", "Yakyuu o mimasu.", "Saya menonton bisbol."),
        ]),
        ("basukettobooru", None, "バスケットボール", "basuketto booru", "bola basket", "N4", "noun", "バスケットボール", "basuketto booru", "バスケットボール", "basuketto booru", [
            ("バスケットボールをします。", "Basuketto booru o shimasu.", "Saya bermain bola basket."),
        ]),
        ("suiei", "水泳", "すいえい", "suiei", "renang", "N4", "noun", "水泳", "suiei", "水泳", "suiei", [
            ("水泳が得意です。", "Suiei ga tokui desu.", "Saya jago berenang."),
        ]),
        ("tenisu", None, "テニス", "tenisu", "tenis", "N4", "noun", "テニス", "tenisu", "テニス", "tenisu", [
            ("テニスをします。", "Tenisu o shimasu.", "Saya bermain tenis."),
        ]),
        ("ranningu", None, "ランニング", "ranningu", "lari (running)", "N4", "noun", "ランニング", "ranningu", "ランニング", "ranningu", [
            ("毎朝ランニングをします。", "Maiasa ranningu o shimasu.", "Saya lari setiap pagi."),
        ]),
        ("juudou", "柔道", "じゅうどう", "juudou", "judo", "N3", "noun", "柔道", "juudou", "柔道", "juudou", [
            ("柔道を習っています。", "Juudou o naratte imasu.", "Saya sedang belajar judo."),
        ]),
        ("karate", "空手", "からて", "karate", "karate", "N3", "noun", "空手", "karate", "空手", "karate", [
            ("空手は日本の武道です。", "Karate wa Nihon no budou desu.", "Karate adalah bela diri Jepang."),
        ]),
        ("sumou", "相撲", "すもう", "sumou", "sumo", "N3", "noun", "相撲", "sumou", "相撲", "sumou", [
            ("相撲を見るのが好きです。", "Sumou o miru no ga suki desu.", "Saya suka menonton sumo."),
        ]),
        ("taisou", "体操", "たいそう", "taisou", "senam", "N3", "noun", "体操", "taisou", "体操", "taisou", [
            ("毎朝体操をします。", "Maiasa taisou o shimasu.", "Saya senam setiap pagi."),
        ]),
        ("undou", "運動", "うんどう", "undou", "olahraga/gerak badan", "N4", "noun", "運動", "undou", "運動", "undou", [
            ("運動は健康にいいです。", "Undou wa kenkou ni ii desu.", "Olahraga baik untuk kesehatan."),
        ]),
        # N1/N2 addition (2026-07-20, fifth batch): pure-kanji training/
        # fitness nouns, for Kombinasi Kanji pool depth.
        ("tanren", "鍛錬", "たんれん", "tanren", "penempaan/pelatihan (fisik/mental)", "N1", "noun", "鍛錬", "tanren", "鍛錬", "tanren", [
            ("毎日体を鍛錬しています。", "Mainichi karada o tanren shite imasu.", "Saya melatih tubuh setiap hari."),
        ]),
        ("jikyuuryoku", "持久力", "じきゅうりょく", "jikyuuryoku", "daya tahan (fisik)", "N2", "noun", "持久力", "jikyuuryoku", "持久力", "jikyuuryoku", [
            ("マラソンには持久力が必要です。", "Marason ni wa jikyuuryoku ga hitsuyou desu.", "Maraton membutuhkan daya tahan."),
        ]),
        ("kinryoku", "筋力", "きんりょく", "kinryoku", "kekuatan otot", "N2", "noun", "筋力", "kinryoku", "筋力", "kinryoku", [
            ("筋力トレーニングをします。", "Kinryoku toreeningu o shimasu.", "Saya melakukan latihan kekuatan otot."),
        ]),
        # N2/N3/N4 addition (2026-07-20, eleventh batch): concrete sport/
        # competition nouns, for Kombinasi Kanji pool depth.
        ("takkyuu", "卓球", "たっきゅう", "takkyuu", "tenis meja", "N3", "noun", "卓球", "takkyuu", "卓球", "takkyuu", [
            ("卓球をします。", "Takkyuu o shimasu.", "Saya bermain tenis meja."),
        ]),
        ("rikujou", "陸上", "りくじょう", "rikujou", "atletik", "N3", "noun", "陸上", "rikujou", "陸上", "rikujou", [
            ("陸上部に入っています。", "Rikujou-bu ni haitte imasu.", "Saya ikut klub atletik."),
        ]),
        ("yuushou", "優勝", "ゆうしょう", "yuushou", "juara/kemenangan (kompetisi)", "N2", "noun", "優勝", "yuushou", "優勝", "yuushou", [
            ("大会で優勝しました。", "Taikai de yuushou shimashita.", "Saya juara di kompetisi itu."),
        ]),
        ("shiai", "試合", "しあい", "shiai", "pertandingan", "N4", "noun", "試合", "shiai", "試合", "shiai", [
            ("明日試合があります。", "Ashita shiai ga arimasu.", "Besok ada pertandingan."),
        ]),
        ("senshu", "選手", "せんしゅ", "senshu", "atlet", "N3", "noun", "選手", "senshu", "選手", "senshu", [
            ("彼は有名な選手です。", "Kare wa yuumei na senshu desu.", "Dia atlet terkenal."),
        ]),
        ("kouhan", "後半", "こうはん", "kouhan", "babak kedua", "N2", "noun", "後半", "kouhan", "後半", "kouhan", [
            ("試合の後半が始まりました。", "Shiai no kouhan ga hajimarimashita.", "Babak kedua pertandingan dimulai."),
        ]),
        ("zenhan", "前半", "ぜんはん", "zenhan", "babak pertama", "N2", "noun", "前半", "zenhan", "前半", "zenhan", [
            ("前半は簡単でした。", "Zenhan wa kantan deshita.", "Bagian separoh pertama mudah."),
        ]),
        ("tairyoku", "体力", "たいりょく", "tairyoku", "stamina/daya tahan", "N2", "noun", "体力", "tairyoku", "体力", "tairyoku", [
            ("体力をつけたいです。", "Tairyoku o tsuketai desu.", "Ingin meningkatkan stamina."),
        ]),
        ("tozan", "登山", "とざん", "tozan", "mendaki gunung", "N2", "noun", "登山", "tozan", "登山", "tozan", [
            ("週末に登山します。", "Shuumatsu ni tozan shimasu.", "Akhir pekan saya mendaki gunung."),
        ]),
        ("taikai", "大会", "たいかい", "taikai", "kompetisi/turnamen besar", "N3", "noun", "大会", "taikai", "大会", "taikai", [
            ("大会に出場します。", "Taikai ni shutsujou shimasu.", "Ikut kompetisi."),
        ]),
        ("hitteki", "匹敵", "ひってき", "hitteki", "setanding/sebanding", "N1", "noun", "匹敵", "hitteki", "匹敵", "hitteki", [
            ("彼の実力に匹敵します。", "Kare no jitsuryoku ni hitteki shimasu.", "Setanding dengan kemampuannya."),
        ]),
    ],
    "perasaan_emosi": [
        ("ureshii", "嬉しい", "うれしい", "ureshii", "senang/gembira", "N4", "adjective", "嬉しい", "ureshii", "嬉しいです", "ureshii desu", [
            ("嬉しいです。", "Ureshii desu.", "Saya senang."),
        ]),
        ("kanashii", "悲しい", "かなしい", "kanashii", "sedih", "N4", "adjective", "悲しい", "kanashii", "悲しいです", "kanashii desu", [
            ("悲しいです。", "Kanashii desu.", "Saya sedih."),
        ]),
        ("tanoshii", "楽しい", "たのしい", "tanoshii", "menyenangkan/seru", "N5", "adjective", "楽しい", "tanoshii", "楽しいです", "tanoshii desu", [
            ("楽しいです。", "Tanoshii desu.", "Ini menyenangkan."),
        ]),
        ("okoru", "怒る", "おこる", "okoru", "marah", "N4", "verb", "怒る", "okoru", "怒ります", "okorimasu", [
            ("怒りました。", "Okorimashita.", "Saya marah."),
        ]),
        ("kowai", "怖い", "こわい", "kowai", "takut/menakutkan", "N4", "adjective", "怖い", "kowai", "怖いです", "kowai desu", [
            ("怖いです。", "Kowai desu.", "Saya takut."),
        ]),
        ("shinpai", "心配", "しんぱい", "shinpai", "khawatir/cemas", "N4", "adjective", "心配", "shinpai", "心配です", "shinpai desu", [
            ("心配です。", "Shinpai desu.", "Saya khawatir."),
        ]),
        ("bikkuri", None, "びっくり", "bikkuri", "terkejut", "N4", "verb", "びっくりする", "bikkuri suru", "びっくりします", "bikkuri shimasu", [
            ("びっくりしました。", "Bikkuri shimashita.", "Saya terkejut."),
        ]),
        ("sabishii", "寂しい", "さびしい", "sabishii", "kesepian", "N3", "adjective", "寂しい", "sabishii", "寂しいです", "sabishii desu", [
            ("寂しいです。", "Sabishii desu.", "Saya kesepian."),
        ]),
        ("hazukashii", "恥ずかしい", "はずかしい", "hazukashii", "malu", "N3", "adjective", "恥ずかしい", "hazukashii", "恥ずかしいです", "hazukashii desu", [
            ("恥ずかしいです。", "Hazukashii desu.", "Saya malu."),
        ]),
        ("anshin", "安心", "あんしん", "anshin", "lega/tenang", "N3", "verb", "安心する", "anshin suru", "安心します", "anshin shimasu", [
            ("安心しました。", "Anshin shimashita.", "Saya merasa lega."),
        ]),
        # N1/N2 addition (2026-07-20, third batch): pure-kanji noun-form
        # emotion words, for Kombinasi Kanji pool depth — the emotion words
        # already here are mostly i-adjectives/verbs with okurigana (e.g.
        # 嬉しい, 怒る), which never counted toward the compound pool since
        # they aren't pure kanji strings.
        ("ando", "安堵", "あんど", "ando", "lega (formal)", "N1", "noun", "安堵", "ando", "安堵", "ando", [
            ("無事だと聞いて安堵しました。", "Buji da to kiite ando shimashita.", "Saya lega mendengar dia selamat."),
        ]),
        ("douyou", "動揺", "どうよう", "douyou", "keguncangan/kegelisahan", "N1", "noun", "動揺", "douyou", "動揺", "douyou", [
            ("そのニュースに動揺しました。", "Sono nyuusu ni douyou shimashita.", "Saya terguncang mendengar berita itu."),
        ]),
        ("rakutan", "落胆", "らくたん", "rakutan", "kekecewaan/patah semangat", "N2", "noun", "落胆", "rakutan", "落胆", "rakutan", [
            ("試験に落ちて落胆しました。", "Shiken ni ochite rakutan shimashita.", "Saya kecewa karena gagal ujian."),
        ]),
        ("yuuutsu", "憂鬱", "ゆううつ", "yuuutsu", "murung/suram", "N1", "noun", "憂鬱", "yuuutsu", "憂鬱", "yuuutsu", [
            ("月曜日はいつも憂鬱です。", "Getsuyoubi wa itsumo yuuutsu desu.", "Hari Senin selalu terasa suram."),
        ]),
        ("kanki", "歓喜", "かんき", "kanki", "kegembiraan besar/sukacita", "N1", "noun", "歓喜", "kanki", "歓喜", "kanki", [
            ("優勝の知らせに歓喜しました。", "Yuushou no shirase ni kanki shimashita.", "Kami bersukacita mendengar kabar menang juara."),
        ]),
        # N2/N3 addition (2026-07-20, thirteenth batch): more everyday
        # noun-form emotion words, for Kombinasi Kanji pool depth.
        ("kinchou", "緊張", "きんちょう", "kinchou", "gugup/tegang", "N3", "noun", "緊張", "kinchou", "緊張", "kinchou", [
            ("面接で緊張しました。", "Mensetsu de kinchou shimashita.", "Saya gugup saat wawancara."),
        ]),
        ("koufun", "興奮", "こうふん", "koufun", "semangat/excitement", "N2", "noun", "興奮", "koufun", "興奮", "koufun", [
            ("試合を見て興奮しました。", "Shiai o mite koufun shimashita.", "Saya bersemangat menonton pertandingan."),
        ]),
        ("inshou", "印象", "いんしょう", "inshou", "kesan", "N2", "noun", "印象", "inshou", "印象", "inshou", [
            ("良い印象を受けました。", "Yoi inshou o ukemashita.", "Saya mendapat kesan baik. (Kesan dari sesuatu yg dilihat)"),
        ]),
        ("kangeki", "感激", "かんげき", "kangeki", "keterharuan", "N2", "noun", "感激", "kangeki", "感激", "kangeki", [
            ("とても感激しました。", "Totemo kangeki shimashita.", "Saya sangat terharu. (kesan dapat perlauan baik)"),
        ]),
        ("kanshin", "感心", "かんしん", "kanshin", "kekaguman", "N2", "noun", "感心", "kanshin", "感心", "kanshin", [
            ("彼の努力どりょくに感心しました。", "Kare no doryoku ni kanshin shimashita.", "Saya kagum pada usahanya."),
        ]),
        ("kansou", "感想", "かんそう", "kansou", "kesan/pendapat", "N2", "noun", "感想", "kansou", "感想", "kansou", [
            ("映画の感想を話します。", "Eiga no kansou o hanashimasu.", "Menceritakan kesan film. (kesan yg dirasakan/komentar)"),
        ]),
        ("kandou", "感動", "かんどう", "kandou", "keterharuan/kesan mendalam", "N2", "noun", "感動", "kandou", "感動", "kandou", [
            ("とても感動しました。", "Totemo kandou shimashita.", "Saya sangat terharu. (emosional, perasaan)"),
        ]),
        ("gaman", "我慢", "がまん", "gaman", "kesabaran", "N2", "noun", "我慢", "gaman", "我慢", "gaman", [
            ("少し我慢してください。", "Sukoshi gaman shite kudasai.", "Tolong bersabar sedikit."),
        ]),
        ("kurou", "苦労", "くろう", "kurou", "kesusahan/usaha keras", "N2", "noun", "苦労", "kurou", "苦労", "kurou", [
            ("とても苦労しました。", "Totemo kurou shimashita.", "Saya sangat bersusah payah. (penderitaan usaha, susah)"),
        ]),
        ("jishin", "自信", "じしん", "jishin", "kepercayaan diri", "N2", "noun", "自信", "jishin", "自信", "jishin", [
            ("自信があります。", "Jishin ga arimasu.", "Saya percaya diri."),
        ]),
        ("jiman", "自慢", "じまん", "jiman", "kebanggaan", "N2", "noun", "自慢", "jiman", "自慢", "jiman", [
            ("料理を自慢します。", "Ryouri o jiman shimasu.", "Membanggakan masakan. (+bangga -sombong)"),
        ]),
        ("sonkei", "尊敬", "そんけい", "sonkei", "rasa hormat", "N2", "noun", "尊敬", "sonkei", "尊敬", "sonkei", [
            ("先生を尊敬しています。", "Sensei o sonkei shite imasu.", "Saya menghormati guru."),
        ]),
        ("nattoku", "納得", "なっとく", "nattoku", "pengertian/kepuasan hati", "N2", "noun", "納得", "nattoku", "納得", "nattoku", [
            ("彼の説明に納得しました。", "Kare no setsumei ni nattoku shimashita.", "Saya mengerti penjelasannya. (dan menerima pakai hati)"),
        ]),
        ("monku", "文句", "もんく", "monku", "keluhan/komplain", "N2", "noun", "文句", "monku", "文句", "monku", [
            ("文句を言わないでください。", "Monku o iwanaide kudasai.", "Tolong jangan mengeluh."),
        ]),
        ("aijou", "愛情", "あいじょう", "aijou", "kasih sayang", "N2", "noun", "愛情", "aijou", "愛情", "aijou", [
            ("母は子供に愛情を持っています。", "Haha wa kodomo ni aijou o motte imasu.", "Ibu memiliki kasih sayang kepada anak."),
        ]),
        ("aichaku", "愛着", "あいちゃく", "aichaku", "keterikatan (emosional)", "N2", "noun", "愛着", "aichaku", "愛着", "aichaku", [
            ("この町に愛着があります。", "Kono machi ni aichaku ga arimasu.", "Saya memiliki keterikatan dengan kota ini."),
        ]),
        ("akui", "悪意", "あくい", "akui", "niat jahat", "N2", "noun", "悪意", "akui", "悪意", "akui", [
            ("彼には悪意がありません。", "Kare ni wa akui ga arimasen.", "Dia tidak memiliki niat jahat."),
        ]),
        ("ishi", "意志", "いし", "ishi", "kemauan/tekad", "N2", "noun", "意志", "ishi", "意志", "ishi", [
            ("彼は強い意志を持っています。", "Kare wa tsuyoi ishi o motte imasu.", "Dia memiliki kemauan yang kuat."),
        ]),
        ("miryoku", "魅力", "みりょく", "miryoku", "daya tarik/pesona", "N3", "noun", "魅力", "miryoku", "魅力", "miryoku", [
            ("彼女には魅力があります。", "Kanojo ni wa miryoku ga arimasu.", "Dia memiliki daya tarik."),
        ]),
        ("nesshin", "熱心", "ねっしん", "nesshin", "antusias/tekun", "N3", "noun", "熱心", "nesshin", "熱心", "nesshin", [
            ("熱心に勉強します。", "Nesshin ni benkyou shimasu.", "Belajar dengan tekun."),
        ]),
        ("shigeki", "刺激", "しげき", "shigeki", "stimulus/rangsangan", "N3", "noun", "刺激", "shigeki", "刺激", "shigeki", [
            ("強い刺激を受けました。", "Tsuyoi shigeki o ukemashita.", "Menerima stimulus yang kuat."),
        ]),
        ("waruguchi", "悪口", "わるぐち", "waruguchi", "omongan jelek/fitnah", "N3", "noun", "悪口", "waruguchi", "悪口", "waruguchi", [
            ("悪口を言わないでください。", "Waruguchi o iwanaide kudasai.", "Jangan bicara buruk tentang orang."),
        ]),
        ("binkan", "敏感", "びんかん", "binkan", "sensitif", "N1", "noun", "敏感", "binkan", "敏感", "binkan", [
            ("肌が敏感です。", "Hada ga binkan desu.", "Kulitnya sensitif."),
        ]),
        ("bujoku", "侮辱", "ぶじょく", "bujoku", "penghinaan", "N1", "noun", "侮辱", "bujoku", "侮辱", "bujoku", [
            ("侮辱された気がします。", "Bujoku sareta ki ga shimasu.", "Merasa dihina."),
        ]),
        ("burei", "無礼", "ぶれい", "burei", "tidak sopan", "N1", "noun", "無礼", "burei", "無礼", "burei", [
            ("無礼な態度でした。", "Burei na taido deshita.", "Sikapnya tidak sopan."),
        ]),
        ("daitan", "大胆", "だいたん", "daitan", "berani/nekat", "N1", "noun", "大胆", "daitan", "大胆", "daitan", [
            ("大胆な決断をしました。", "Daitan na ketsudan o shimashita.", "Membuat keputusan yang berani."),
        ]),
        ("dokyou", "度胸", "どきょう", "dokyou", "keberanian/nyali", "N1", "noun", "度胸", "dokyou", "度胸", "dokyou", [
            ("度胸がありますね。", "Dokyou ga arimasu ne.", "Kamu punya nyali ya."),
        ]),
        ("doujou", "同情", "どうじょう", "doujou", "simpati/rasa kasihan", "N1", "noun", "同情", "doujou", "同情", "doujou", [
            ("彼に同情します。", "Kare ni doujou shimasu.", "Saya bersimpati padanya."),
        ]),
        ("fukushuu", "復讐", "ふくしゅう", "fukushuu", "balas dendam", "N1", "noun", "復讐", "fukushuu", "復讐", "fukushuu", [
            ("復讐を計画しています。", "Fukushuu o keikaku shite imasu.", "Merencanakan balas dendam."),
        ]),
        ("hairyo", "配慮", "はいりょ", "hairyo", "pertimbangan/perhatian", "N1", "noun", "配慮", "hairyo", "配慮", "hairyo", [
            ("相手に配慮します。", "Aite ni hairyo shimasu.", "Memberikan perhatian kepada lawan bicara."),
        ]),
        ("henken", "偏見", "へんけん", "henken", "prasangka", "N1", "noun", "偏見", "henken", "偏見", "henken", [
            ("偏見を持たないでください。", "Henken o motanaide kudasai.", "Jangan berprasangka."),
        ]),
        ("himei", "悲鳴", "ひめい", "himei", "jeritan/pekikan", "N1", "noun", "悲鳴", "himei", "悲鳴", "himei", [
            ("悲鳴が聞こえました。", "Himei ga kikoemashita.", "Terdengar jeritan."),
        ]),
        ("hinan", "非難", "ひなん", "hinan", "kritik/celaan", "N1", "noun", "非難", "hinan", "非難", "hinan", [
            ("非難を受けました。", "Hinan o ukemashita.", "Menerima kritik."),
        ]),
        ("hisan", "悲惨", "ひさん", "hisan", "tragis/menyedihkan", "N1", "noun", "悲惨", "hisan", "悲惨", "hisan", [
            ("悲惨な事故でした。", "Hisan na jiko deshita.", "Kecelakaan yang tragis."),
        ]),
        ("honshin", "本心", "ほんしん", "honshin", "perasaan sebenarnya", "N1", "noun", "本心", "honshin", "本心", "honshin", [
            ("本心を話してください。", "Honshin o hanashite kudasai.", "Tolong bicarakan perasaan sebenarnya."),
        ]),
        ("jikaku", "自覚", "じかく", "jikaku", "kesadaran diri", "N1", "noun", "自覚", "jikaku", "自覚", "jikaku", [
            ("責任を自覚します。", "Sekinin o jikaku shimasu.", "Menyadari tanggung jawab."),
        ]),
        ("jounetsu", "情熱", "じょうねつ", "jounetsu", "semangat/passion", "N1", "noun", "情熱", "jounetsu", "情熱", "jounetsu", [
            ("仕事に情熱を持っています。", "Shigoto ni jounetsu o motte imasu.", "Memiliki passion dalam pekerjaan."),
        ]),
        ("kakushin", "確信", "かくしん", "kakushin", "keyakinan penuh", "N1", "noun", "確信", "kakushin", "確信", "kakushin", [
            ("成功を確信しています。", "Seikou o kakushin shite imasu.", "Yakin akan kesuksesan."),
        ]),
        ("ijiwaru", "意地悪", "いじわる", "ijiwaru", "jahat/usil", "N2", "noun", "意地悪", "ijiwaru", "意地悪", "ijiwaru", [
            ("意地悪なことを言わないでください。", "Ijiwaru na koto o iwanaide kudasai.", "Jangan mengatakan hal yang usil."),
        ]),
        ("kenka", "喧嘩", "けんか", "kenka", "bertengkar", "N4", "noun", "喧嘩", "kenka", "喧嘩", "kenka", [
            ("喧嘩をしました。", "Kenka o shimashita.", "Bertengkar."),
        ]),
        ("kibun", "気分", "きぶん", "kibun", "perasaan/mood", "N4", "noun", "気分", "kibun", "気分", "kibun", [
            ("気分がいいです。", "Kibun ga ii desu.", "Perasaan saya baik."),
        ]),
        ("shinsetsu", "親切", "しんせつ", "shinsetsu", "ramah/baik hati", "N4", "noun", "親切", "shinsetsu", "親切", "shinsetsu", [
            ("彼は親切です。", "Kare wa shinsetsu desu.", "Dia baik hati."),
        ]),
        ("teinei", "丁寧", "ていねい", "teinei", "sopan", "N4", "noun", "丁寧", "teinei", "丁寧", "teinei", [
            ("丁寧に話します。", "Teinei ni hanashimasu.", "Berbicara dengan sopan."),
        ]),
        ("zannen", "残念", "ざんねん", "zannen", "sayang/menyesal", "N4", "noun", "残念", "zannen", "残念", "zannen", [
            ("残念です。", "Zannen desu.", "Sayang sekali."),
        ]),
    ],
    "ekspresi_wajah": [
        ("warau", "笑う", "わらう", "warau", "tertawa/tersenyum", "N4", "verb", "笑う", "warau", "笑います", "waraimasu", [
            ("笑います。", "Waraimasu.", "Saya tertawa."),
        ]),
        ("naku", "泣く", "なく", "naku", "menangis", "N4", "verb", "泣く", "naku", "泣きます", "nakimasu", [
            ("泣きます。", "Nakimasu.", "Saya menangis."),
        ]),
        ("hohoemu", "微笑む", "ほほえむ", "hohoemu", "tersenyum (lembut)", "N2", "verb", "微笑む", "hohoemu", "微笑みます", "hohoemimasu", [
            ("微笑みます。", "Hohoemimasu.", "Saya tersenyum."),
        ]),
        ("odoroku", "驚く", "おどろく", "odoroku", "terkejut (raut wajah)", "N3", "verb", "驚く", "odoroku", "驚きます", "odorokimasu", [
            ("驚きました。", "Odorokimashita.", "Saya terkejut."),
        ]),
        ("mabataki", "瞬き", "まばたき", "mabataki", "kedipan mata", "N2", "verb", "瞬きする", "mabataki suru", "瞬きします", "mabataki shimasu", [
            ("瞬きをします。", "Mabataki o shimasu.", "Saya berkedip."),
        ]),
        ("akubi", None, "あくび", "akubi", "menguap", "N2", "verb", "あくびする", "akubi suru", "あくびします", "akubi shimasu", [
            ("あくびをします。", "Akubi o shimasu.", "Saya menguap."),
        ]),
        ("shikameru", None, "しかめる", "shikameru", "mengerutkan wajah (meringis/cemberut)", "N1", "verb", "しかめる", "shikameru", "しかめます", "shikamemasu", [
            ("顔をしかめました。", "Kao o shikamemashita.", "Saya mengerutkan wajah."),
        ]),
        ("mitsumeru", "見つめる", "みつめる", "mitsumeru", "menatap", "N3", "verb", "見つめる", "mitsumeru", "見つめます", "mitsumemasu", [
            ("彼を見つめました。", "Kare o mitsumemashita.", "Saya menatapnya."),
        ]),
        ("egao", "笑顔", "えがお", "egao", "wajah tersenyum", "N2", "noun", "笑顔", "egao", "笑顔", "egao", [
            ("笑顔であいさつします。", "Egao de aisatsu shimasu.", "Menyapa dengan senyum."),
        ]),
        ("bishou", "微笑", "びしょう", "bishou", "senyuman", "N1", "noun", "微笑", "bishou", "微笑", "bishou", [
            ("微笑を浮かべました。", "Bishou o ukabemashita.", "Menampilkan senyuman."),
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
