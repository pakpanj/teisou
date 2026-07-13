import json

# Kotoba vocab — grup "Manusia & Sosial" (Batch 7).
# Same per-entry registers approach as the other Batch 7 scripts.
#
# agama_budaya needs extra care: entries are kept factual and neutral
# (naming a religion, or a plain "Saya beragama X" self-statement, or a
# well-documented demographic fact like Bali's Hindu majority) — no claims
# about doctrine or practice for any specific religion, so nothing here
# reads as favoring or characterizing one over another.
#
# keluarga_hubungan uses the humble/own-family terms (chichi/haha, not
# otousan/okaasan) since that's the standard N5 starting point, and each
# meaning is annotated "(kata sendiri)" so it doesn't read as the only way
# to say "father"/"mother" in Japanese.
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
    "profesi": [
        ("sensei", "先生", "せんせい", "sensei", "guru/dosen", "N5", "noun", "先生", "sensei", "先生", "sensei", [
            ("先生に質問します。", "Sensei ni shitsumon shimasu.", "Saya bertanya kepada guru."),
        ]),
        ("gakusei", "学生", "がくせい", "gakusei", "siswa/mahasiswa", "N5", "noun", "学生", "gakusei", "学生", "gakusei", [
            ("私は学生です。", "Watashi wa gakusei desu.", "Saya seorang siswa."),
        ]),
        ("kaishain", "会社員", "かいしゃいん", "kaishain", "karyawan perusahaan", "N4", "noun", "会社員", "kaishain", "会社員", "kaishain", [
            ("父は会社員です。", "Chichi wa kaishain desu.", "Ayah saya karyawan perusahaan."),
        ]),
        ("keisatsukan", "警察官", "けいさつかん", "keisatsukan", "polisi", "N4", "noun", "警察官", "keisatsukan", "警察官", "keisatsukan", [
            ("警察官が交通整理をします。", "Keisatsukan ga koutsuu seiri o shimasu.", "Polisi mengatur lalu lintas."),
        ]),
        ("shouboushi", "消防士", "しょうぼうし", "shouboushi", "pemadam kebakaran", "N3", "noun", "消防士", "shouboushi", "消防士", "shouboushi", [
            ("消防士は勇敢です。", "Shouboushi wa yuukan desu.", "Pemadam kebakaran itu berani."),
        ]),
        ("ryourinin", "料理人", "りょうりにん", "ryourinin", "koki/juru masak", "N3", "noun", "料理人", "ryourinin", "料理人", "ryourinin", [
            ("料理人は料理を作ります。", "Ryourinin wa ryouri o tsukurimasu.", "Koki membuat masakan."),
        ]),
        ("bengoshi", "弁護士", "べんごし", "bengoshi", "pengacara", "N3", "noun", "弁護士", "bengoshi", "弁護士", "bengoshi", [
            ("弁護士に相談します。", "Bengoshi ni soudan shimasu.", "Saya berkonsultasi dengan pengacara."),
        ]),
        ("enjinia", None, "エンジニア", "enjinia", "insinyur/engineer", "N3", "noun", "エンジニア", "enjinia", "エンジニア", "enjinia", [
            ("彼はエンジニアです。", "Kare wa enjinia desu.", "Dia seorang insinyur."),
        ]),
        ("nouka", "農家", "のうか", "nouka", "petani", "N3", "noun", "農家", "nouka", "農家", "nouka", [
            ("農家は野菜を育てます。", "Nouka wa yasai o sodatemasu.", "Petani menanam sayuran."),
        ]),
        ("untenshu", "運転手", "うんてんしゅ", "untenshu", "supir", "N3", "noun", "運転手", "untenshu", "運転手", "untenshu", [
            ("バスの運転手です。", "Basu no untenshu desu.", "Dia supir bus."),
        ]),
        ("shufu", "主婦", "しゅふ", "shufu", "ibu rumah tangga", "N3", "noun", "主婦", "shufu", "主婦", "shufu", [
            ("母は主婦です。", "Haha wa shufu desu.", "Ibu saya adalah ibu rumah tangga."),
        ]),
        ("kashu", "歌手", "かしゅ", "kashu", "penyanyi", "N3", "noun", "歌手", "kashu", "歌手", "kashu", [
            ("彼女は有名な歌手です。", "Kanojo wa yuumei na kashu desu.", "Dia penyanyi terkenal."),
        ]),
    ],
    "keluarga_hubungan": [
        ("kazoku", "家族", "かぞく", "kazoku", "keluarga", "N5", "noun", "家族", "kazoku", "家族", "kazoku", [
            ("家族と住んでいます。", "Kazoku to sunde imasu.", "Saya tinggal dengan keluarga."),
        ]),
        ("chichi", "父", "ちち", "chichi", "ayah (kata sendiri)", "N5", "noun", "父", "chichi", "父", "chichi", [
            ("父は医者です。", "Chichi wa isha desu.", "Ayah saya seorang dokter."),
        ]),
        ("haha", "母", "はは", "haha", "ibu (kata sendiri)", "N5", "noun", "母", "haha", "母", "haha", [
            ("母は料理が上手です。", "Haha wa ryouri ga jouzu desu.", "Ibu saya jago memasak."),
        ]),
        ("ani", "兄", "あに", "ani", "kakak laki-laki (kata sendiri)", "N5", "noun", "兄", "ani", "兄", "ani", [
            ("兄は大学生です。", "Ani wa daigakusei desu.", "Kakak laki-laki saya mahasiswa."),
        ]),
        ("ane", "姉", "あね", "ane", "kakak perempuan (kata sendiri)", "N5", "noun", "姉", "ane", "姉", "ane", [
            ("姉は看護師です。", "Ane wa kangoshi desu.", "Kakak perempuan saya perawat."),
        ]),
        ("otouto", "弟", "おとうと", "otouto", "adik laki-laki", "N5", "noun", "弟", "otouto", "弟", "otouto", [
            ("弟は高校生です。", "Otouto wa koukousei desu.", "Adik laki-laki saya siswa SMA."),
        ]),
        ("imouto", "妹", "いもうと", "imouto", "adik perempuan", "N5", "noun", "妹", "imouto", "妹", "imouto", [
            ("妹は中学生です。", "Imouto wa chuugakusei desu.", "Adik perempuan saya siswa SMP."),
        ]),
        ("sofu", "祖父", "そふ", "sofu", "kakek (kata sendiri)", "N4", "noun", "祖父", "sofu", "祖父", "sofu", [
            ("祖父は元気です。", "Sofu wa genki desu.", "Kakek saya sehat."),
        ]),
        ("sobo", "祖母", "そぼ", "sobo", "nenek (kata sendiri)", "N4", "noun", "祖母", "sobo", "祖母", "sobo", [
            ("祖母は優しいです。", "Sobo wa yasashii desu.", "Nenek saya baik hati."),
        ]),
        ("musuko", "息子", "むすこ", "musuko", "anak laki-laki (kata sendiri)", "N4", "noun", "息子", "musuko", "息子", "musuko", [
            ("息子は五歳です。", "Musuko wa gosai desu.", "Anak laki-laki saya berusia 5 tahun."),
        ]),
        ("musume", "娘", "むすめ", "musume", "anak perempuan (kata sendiri)", "N4", "noun", "娘", "musume", "娘", "musume", [
            ("娘は学生です。", "Musume wa gakusei desu.", "Anak perempuan saya seorang pelajar."),
        ]),
        ("tomodachi", "友達", "ともだち", "tomodachi", "teman", "N5", "noun", "友達", "tomodachi", "友達", "tomodachi", [
            ("友達と遊びます。", "Tomodachi to asobimasu.", "Saya bermain dengan teman."),
        ]),
        ("koibito", "恋人", "こいびと", "koibito", "kekasih/pacar", "N4", "noun", "恋人", "koibito", "恋人", "koibito", [
            ("恋人にプレゼントをあげます。", "Koibito ni purezento o agemasu.", "Saya memberi hadiah untuk kekasih."),
        ]),
        ("fuufu", "夫婦", "ふうふ", "fuufu", "pasangan suami istri", "N3", "noun", "夫婦", "fuufu", "夫婦", "fuufu", [
            ("二人は夫婦です。", "Futari wa fuufu desu.", "Mereka berdua adalah pasangan suami istri."),
        ]),
    ],
    "pakaian_aksesori": [
        ("fuku", "服", "ふく", "fuku", "baju/pakaian", "N5", "noun", "服", "fuku", "服", "fuku", [
            ("服を着ます。", "Fuku o kimasu.", "Saya memakai baju."),
        ]),
        ("shatsu", None, "シャツ", "shatsu", "kemeja/shirt", "N4", "noun", "シャツ", "shatsu", "シャツ", "shatsu", [
            ("シャツを着ます。", "Shatsu o kimasu.", "Saya memakai kemeja."),
        ]),
        ("zubon", None, "ズボン", "zubon", "celana panjang", "N4", "noun", "ズボン", "zubon", "ズボン", "zubon", [
            ("ズボンを履きます。", "Zubon o hakimasu.", "Saya memakai celana panjang."),
        ]),
        ("sukaato", None, "スカート", "sukaato", "rok", "N4", "noun", "スカート", "sukaato", "スカート", "sukaato", [
            ("スカートを履きます。", "Sukaato o hakimasu.", "Saya memakai rok."),
        ]),
        ("kutsu", "靴", "くつ", "kutsu", "sepatu", "N5", "noun", "靴", "kutsu", "靴", "kutsu", [
            ("靴を履きます。", "Kutsu o hakimasu.", "Saya memakai sepatu."),
        ]),
        ("boushi", "帽子", "ぼうし", "boushi", "topi", "N4", "noun", "帽子", "boushi", "帽子", "boushi", [
            ("帽子をかぶります。", "Boushi o kaburimasu.", "Saya memakai topi."),
        ]),
        ("megane", "眼鏡", "めがね", "megane", "kacamata", "N4", "noun", "眼鏡", "megane", "眼鏡", "megane", [
            ("眼鏡をかけます。", "Megane o kakemasu.", "Saya memakai kacamata."),
        ]),
        ("tokei", "時計", "とけい", "tokei", "jam (tangan)", "N5", "noun", "時計", "tokei", "時計", "tokei", [
            ("時計をつけます。", "Tokei o tsukemasu.", "Saya memakai jam tangan."),
        ]),
        ("baggu", None, "バッグ", "baggu", "tas", "N4", "noun", "バッグ", "baggu", "バッグ", "baggu", [
            ("バッグを持ちます。", "Baggu o mochimasu.", "Saya membawa tas."),
        ]),
        ("yubiwa", "指輪", "ゆびわ", "yubiwa", "cincin", "N3", "noun", "指輪", "yubiwa", "指輪", "yubiwa", [
            ("指輪をつけます。", "Yubiwa o tsukemasu.", "Saya memakai cincin."),
        ]),
        ("nekutai", None, "ネクタイ", "nekutai", "dasi", "N3", "noun", "ネクタイ", "nekutai", "ネクタイ", "nekutai", [
            ("ネクタイを締めます。", "Nekutai o shimemasu.", "Saya memakai dasi."),
        ]),
        ("kimono", "着物", "きもの", "kimono", "kimono (pakaian tradisional Jepang)", "N3", "noun", "着物", "kimono", "着物", "kimono", [
            ("着物を着ます。", "Kimono o kimasu.", "Saya memakai kimono."),
        ]),
    ],
    "hobi_aktivitas": [
        ("shumi", "趣味", "しゅみ", "shumi", "hobi", "N4", "noun", "趣味", "shumi", "趣味", "shumi", [
            ("趣味は何ですか。", "Shumi wa nan desu ka.", "Apa hobimu?"),
        ]),
        ("dokusho", "読書", "どくしょ", "dokusho", "membaca buku", "N4", "noun", "読書", "dokusho", "読書", "dokusho", [
            ("読書が好きです。", "Dokusho ga suki desu.", "Saya suka membaca buku."),
        ]),
        ("ongaku", "音楽", "おんがく", "ongaku", "musik", "N5", "noun", "音楽", "ongaku", "音楽", "ongaku", [
            ("音楽を聴きます。", "Ongaku o kikimasu.", "Saya mendengarkan musik."),
        ]),
        ("eiga", "映画", "えいが", "eiga", "film", "N5", "noun", "映画", "eiga", "映画", "eiga", [
            ("映画を見ます。", "Eiga o mimasu.", "Saya menonton film."),
        ]),
        ("ryokou", "旅行", "りょこう", "ryokou", "bepergian/traveling", "N4", "noun", "旅行", "ryokou", "旅行", "ryokou", [
            ("旅行が好きです。", "Ryokou ga suki desu.", "Saya suka bepergian."),
        ]),
        ("shashin", "写真", "しゃしん", "shashin", "foto/fotografi", "N4", "noun", "写真", "shashin", "写真", "shashin", [
            ("写真を撮ります。", "Shashin o torimasu.", "Saya memotret."),
        ]),
        ("e", "絵", "え", "e", "gambar/lukisan", "N4", "noun", "絵", "e", "絵", "e", [
            ("絵を描きます。", "E o kakimasu.", "Saya menggambar."),
        ]),
        ("gaadeningu", None, "ガーデニング", "gaadeningu", "berkebun", "N3", "noun", "ガーデニング", "gaadeningu", "ガーデニング", "gaadeningu", [
            ("ガーデニングが趣味です。", "Gaadeningu ga shumi desu.", "Berkebun adalah hobi saya."),
        ]),
        ("ryouri", "料理", "りょうり", "ryouri", "memasak (sebagai hobi)", "N4", "noun", "料理", "ryouri", "料理", "ryouri", [
            ("料理をするのが好きです。", "Ryouri o suru no ga suki desu.", "Saya suka memasak."),
        ]),
        ("geemu", None, "ゲーム", "geemu", "permainan/game", "N4", "noun", "ゲーム", "geemu", "ゲーム", "geemu", [
            ("ゲームをします。", "Geemu o shimasu.", "Saya bermain game."),
        ]),
        ("dansu", None, "ダンス", "dansu", "menari/dance", "N3", "noun", "ダンス", "dansu", "ダンス", "dansu", [
            ("ダンスを習っています。", "Dansu o naratte imasu.", "Saya sedang belajar menari."),
        ]),
        ("kyanpu", None, "キャンプ", "kyanpu", "berkemah/camping", "N3", "noun", "キャンプ", "kyanpu", "キャンプ", "kyanpu", [
            ("キャンプに行きます。", "Kyanpu ni ikimasu.", "Saya pergi berkemah."),
        ]),
    ],
    "agama_budaya": [
        ("shuukyou", "宗教", "しゅうきょう", "shuukyou", "agama", "N3", "noun", "宗教", "shuukyou", "宗教", "shuukyou", [
            ("宗教について話します。", "Shuukyou ni tsuite hanashimasu.", "Saya berbicara tentang agama."),
        ]),
        ("bukkyou", "仏教", "ぶっきょう", "bukkyou", "agama Buddha", "N3", "noun", "仏教", "bukkyou", "仏教", "bukkyou", [
            ("私は仏教です。", "Watashi wa bukkyou desu.", "Saya beragama Buddha."),
        ]),
        ("shintou", "神道", "しんとう", "shintou", "Shinto (agama asli Jepang)", "N2", "noun", "神道", "shintou", "神道", "shintou", [
            ("神道は日本の伝統的な宗教です。", "Shintou wa Nihon no dentouteki na shuukyou desu.", "Shinto adalah agama tradisional Jepang."),
        ]),
        ("isuramukyou", "イスラム教", "いすらむきょう", "isuramukyou", "agama Islam", "N3", "noun", "イスラム教", "isuramukyou", "イスラム教", "isuramukyou", [
            ("私はイスラム教です。", "Watashi wa isuramukyou desu.", "Saya beragama Islam."),
        ]),
        ("kirisutokyou", "キリスト教", "きりすときょう", "kirisutokyou", "agama Kristen", "N3", "noun", "キリスト教", "kirisutokyou", "キリスト教", "kirisutokyou", [
            ("私はキリスト教です。", "Watashi wa kirisutokyou desu.", "Saya beragama Kristen."),
        ]),
        ("hinduukyou", "ヒンドゥー教", "ひんどぅーきょう", "hinduukyou", "agama Hindu", "N2", "noun", "ヒンドゥー教", "hinduukyou", "ヒンドゥー教", "hinduukyou", [
            ("バリではヒンドゥー教が多いです。", "Bari de wa hinduukyou ga ooi desu.", "Di Bali, agama Hindu banyak dianut."),
        ]),
        ("matsuri", "祭り", "まつり", "matsuri", "festival/perayaan tradisional", "N3", "noun", "祭り", "matsuri", "祭り", "matsuri", [
            ("夏に祭りがあります。", "Natsu ni matsuri ga arimasu.", "Ada festival di musim panas."),
        ]),
        ("dentou", "伝統", "でんとう", "dentou", "tradisi", "N3", "noun", "伝統", "dentou", "伝統", "dentou", [
            ("日本の伝統を学びます。", "Nihon no dentou o manabimasu.", "Saya belajar tradisi Jepang."),
        ]),
        ("bunka", "文化", "ぶんか", "bunka", "budaya", "N4", "noun", "文化", "bunka", "文化", "bunka", [
            ("日本の文化に興味があります。", "Nihon no bunka ni kyoumi ga arimasu.", "Saya tertarik pada budaya Jepang."),
        ]),
        ("reihai", "礼拝", "れいはい", "reihai", "ibadah/sembahyang", "N2", "noun", "礼拝", "reihai", "礼拝", "reihai", [
            ("礼拝に行きます。", "Reihai ni ikimasu.", "Saya pergi beribadah."),
        ]),
    ],
    "perayaan_haribesar": [
        ("oshougatsu", "お正月", "おしょうがつ", "oshougatsu", "Tahun Baru (Jepang)", "N4", "noun", "お正月", "oshougatsu", "お正月", "oshougatsu", [
            ("お正月に家族と過ごします。", "Oshougatsu ni kazoku to sugoshimasu.", "Saya menghabiskan Tahun Baru dengan keluarga."),
        ]),
        ("tanjoubi", "誕生日", "たんじょうび", "tanjoubi", "ulang tahun", "N5", "noun", "誕生日", "tanjoubi", "誕生日", "tanjoubi", [
            ("誕生日おめでとう。", "Tanjoubi omedetou.", "Selamat ulang tahun."),
        ]),
        ("kurisumasu", None, "クリスマス", "kurisumasu", "Natal", "N4", "noun", "クリスマス", "kurisumasu", "クリスマス", "kurisumasu", [
            ("クリスマスを祝います。", "Kurisumasu o iwaimasu.", "Saya merayakan Natal."),
        ]),
        ("hinamatsuri", "雛祭り", "ひなまつり", "hinamatsuri", "Hina Matsuri (festival boneka, 3 Maret)", "N2", "noun", "雛祭り", "hinamatsuri", "雛祭り", "hinamatsuri", [
            ("3月3日はひな祭りです。", "Sangatsu mikka wa hinamatsuri desu.", "3 Maret adalah Hina Matsuri."),
        ]),
        ("tanabata", "七夕", "たなばた", "tanabata", "Tanabata (festival bintang, 7 Juli)", "N2", "noun", "七夕", "tanabata", "七夕", "tanabata", [
            ("七夕に願い事をします。", "Tanabata ni negaigoto o shimasu.", "Saat Tanabata, saya membuat permohonan."),
        ]),
        ("obon", "お盆", "おぼん", "obon", "Obon (festival arwah leluhur)", "N2", "noun", "お盆", "obon", "お盆", "obon", [
            ("お盆に田舎に帰ります。", "Obon ni inaka ni kaerimasu.", "Saat Obon, saya pulang kampung."),
        ]),
        ("kekkonshiki", "結婚式", "けっこんしき", "kekkonshiki", "pernikahan/pesta pernikahan", "N3", "noun", "結婚式", "kekkonshiki", "結婚式", "kekkonshiki", [
            ("結婚式に招待されました。", "Kekkonshiki ni shoutai saremashita.", "Saya diundang ke pernikahan."),
        ]),
        ("oiwai", "お祝い", "おいわい", "oiwai", "perayaan/selamat", "N3", "noun", "お祝い", "oiwai", "お祝い", "oiwai", [
            ("お祝いのプレゼントを買います。", "Oiwai no purezento o kaimasu.", "Saya membeli hadiah perayaan."),
        ]),
        ("hanabi", "花火", "はなび", "hanabi", "kembang api", "N3", "noun", "花火", "hanabi", "花火", "hanabi", [
            ("夏に花火を見ます。", "Natsu ni hanabi o mimasu.", "Saya menonton kembang api di musim panas."),
        ]),
        ("ramadan", None, "ラマダン", "ramadan", "Ramadan (bulan puasa)", "N2", "noun", "ラマダン", "ramadan", "ラマダン", "ramadan", [
            ("ラマダン中は断食します。", "Ramadan-chuu wa danjiki shimasu.", "Selama Ramadan, orang berpuasa."),
        ]),
        ("barentaindee", None, "バレンタインデー", "barentaindee", "Hari Valentine", "N3", "noun", "バレンタインデー", "barentaindee", "バレンタインデー", "barentaindee", [
            ("バレンタインデーにチョコレートをあげます。", "Barentaindee ni chokoreeto o agemasu.", "Saat Hari Valentine, saya memberi cokelat."),
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
