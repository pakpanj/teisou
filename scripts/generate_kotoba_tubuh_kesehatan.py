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
