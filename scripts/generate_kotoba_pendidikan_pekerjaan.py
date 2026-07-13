import json

# Kotoba vocab — grup "Pendidikan & Pekerjaan" (Batch 7).
# Same per-entry registers approach as the other Batch 7 scripts.
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
    "alat_tulis_sekolah": [
        ("enpitsu", "鉛筆", "えんぴつ", "enpitsu", "pensil", "N5", "noun", "鉛筆", "enpitsu", "鉛筆", "enpitsu", [
            ("鉛筆で書きます。", "Enpitsu de kakimasu.", "Saya menulis dengan pensil."),
        ]),
        ("keshigomu", None, "けしゴム", "keshigomu", "penghapus", "N4", "noun", "けしゴム", "keshigomu", "けしゴム", "keshigomu", [
            ("消しゴムで消します。", "Keshigomu de keshimasu.", "Saya menghapus dengan penghapus."),
        ]),
        ("nooto", None, "ノート", "nooto", "buku catatan", "N5", "noun", "ノート", "nooto", "ノート", "nooto", [
            ("ノートに書きます。", "Nooto ni kakimasu.", "Saya menulis di buku catatan."),
        ]),
        ("hon", "本", "ほん", "hon", "buku", "N5", "noun", "本", "hon", "本", "hon", [
            ("本を読みます。", "Hon o yomimasu.", "Saya membaca buku."),
        ]),
        ("kaban", "鞄", "かばん", "kaban", "tas sekolah", "N4", "noun", "鞄", "kaban", "鞄", "kaban", [
            ("鞄に本を入れます。", "Kaban ni hon o iremasu.", "Saya memasukkan buku ke tas."),
        ]),
        ("hasami", None, "はさみ", "hasami", "gunting", "N4", "noun", "はさみ", "hasami", "はさみ", "hasami", [
            ("はさみで切ります。", "Hasami de kirimasu.", "Saya memotong dengan gunting."),
        ]),
        ("nori", None, "のり", "nori", "lem", "N3", "noun", "のり", "nori", "のり", "nori", [
            ("のりで貼ります。", "Nori de harimasu.", "Saya menempel dengan lem."),
        ]),
        ("jougi", "定規", "じょうぎ", "jougi", "penggaris", "N3", "noun", "定規", "jougi", "定規", "jougi", [
            ("定規で線を引きます。", "Jougi de sen o hikimasu.", "Saya menggaris dengan penggaris."),
        ]),
        ("pen", None, "ペン", "pen", "pena/pulpen", "N5", "noun", "ペン", "pen", "ペン", "pen", [
            ("ペンで書きます。", "Pen de kakimasu.", "Saya menulis dengan pena."),
        ]),
        ("fude", "筆", "ふで", "fude", "kuas (kaligrafi)", "N3", "noun", "筆", "fude", "筆", "fude", [
            ("筆で書きます。", "Fude de kakimasu.", "Saya menulis dengan kuas."),
        ]),
        ("kokuban", "黒板", "こくばん", "kokuban", "papan tulis", "N4", "noun", "黒板", "kokuban", "黒板", "kokuban", [
            ("黒板に書きます。", "Kokuban ni kakimasu.", "Saya menulis di papan tulis."),
        ]),
    ],
    "mata_pelajaran": [
        ("kokugo", "国語", "こくご", "kokugo", "bahasa nasional (mapel Jepang)", "N4", "noun", "国語", "kokugo", "国語", "kokugo", [
            ("国語のテストがあります。", "Kokugo no tesuto ga arimasu.", "Ada tes bahasa Jepang."),
        ]),
        ("suugaku", "数学", "すうがく", "suugaku", "matematika", "N4", "noun", "数学", "suugaku", "数学", "suugaku", [
            ("数学は難しいです。", "Suugaku wa muzukashii desu.", "Matematika itu sulit."),
        ]),
        ("rika", "理科", "りか", "rika", "IPA (sains)", "N4", "noun", "理科", "rika", "理科", "rika", [
            ("理科の実験をします。", "Rika no jikken o shimasu.", "Saya melakukan eksperimen IPA."),
        ]),
        ("shakai", "社会", "しゃかい", "shakai", "IPS (sosial)", "N4", "noun", "社会", "shakai", "社会", "shakai", [
            ("社会の授業があります。", "Shakai no jugyou ga arimasu.", "Ada pelajaran IPS."),
        ]),
        ("eigo", "英語", "えいご", "eigo", "bahasa Inggris", "N5", "noun", "英語", "eigo", "英語", "eigo", [
            ("英語を勉強します。", "Eigo o benkyou shimasu.", "Saya belajar bahasa Inggris."),
        ]),
        ("nihongo", "日本語", "にほんご", "nihongo", "bahasa Jepang", "N5", "noun", "日本語", "nihongo", "日本語", "nihongo", [
            ("日本語が好きです。", "Nihongo ga suki desu.", "Saya suka bahasa Jepang."),
        ]),
        ("taiiku", "体育", "たいいく", "taiiku", "olahraga (mapel PE)", "N4", "noun", "体育", "taiiku", "体育", "taiiku", [
            ("体育で走ります。", "Taiiku de hashirimasu.", "Saya lari saat pelajaran olahraga."),
        ]),
        ("bijutsu", "美術", "びじゅつ", "bijutsu", "seni rupa", "N3", "noun", "美術", "bijutsu", "美術", "bijutsu", [
            ("美術の授業で絵を描きます。", "Bijutsu no jugyou de e o kakimasu.", "Saya menggambar di pelajaran seni."),
        ]),
        ("rekishi", "歴史", "れきし", "rekishi", "sejarah", "N3", "noun", "歴史", "rekishi", "歴史", "rekishi", [
            ("歴史を勉強します。", "Rekishi o benkyou shimasu.", "Saya belajar sejarah."),
        ]),
        ("kagaku", "化学", "かがく", "kagaku", "kimia", "N2", "noun", "化学", "kagaku", "化学", "kagaku", [
            ("化学は面白いです。", "Kagaku wa omoshiroi desu.", "Kimia itu menarik."),
        ]),
    ],
    "pekerjaan_kantor": [
        ("kaisha", "会社", "かいしゃ", "kaisha", "perusahaan/kantor", "N5", "noun", "会社", "kaisha", "会社", "kaisha", [
            ("会社で働きます。", "Kaisha de hatarakimasu.", "Saya bekerja di kantor."),
        ]),
        ("shigoto", "仕事", "しごと", "shigoto", "pekerjaan", "N5", "noun", "仕事", "shigoto", "仕事", "shigoto", [
            ("仕事が忙しいです。", "Shigoto ga isogashii desu.", "Pekerjaan saya sibuk."),
        ]),
        ("kaigi", "会議", "かいぎ", "kaigi", "rapat", "N4", "noun", "会議", "kaigi", "会議", "kaigi", [
            ("会議があります。", "Kaigi ga arimasu.", "Ada rapat."),
        ]),
        ("meishi", "名刺", "めいし", "meishi", "kartu nama", "N3", "noun", "名刺", "meishi", "名刺", "meishi", [
            ("名刺を交換します。", "Meishi o koukan shimasu.", "Saya bertukar kartu nama."),
        ]),
        ("joushi", "上司", "じょうし", "joushi", "atasan/bos", "N3", "noun", "上司", "joushi", "上司", "joushi", [
            ("上司に相談します。", "Joushi ni soudan shimasu.", "Saya berkonsultasi dengan atasan."),
        ]),
        ("buka", "部下", "ぶか", "buka", "bawahan", "N2", "noun", "部下", "buka", "部下", "buka", [
            ("部下に指示します。", "Buka ni shiji shimasu.", "Saya memberi instruksi kepada bawahan."),
        ]),
        ("douryou", "同僚", "どうりょう", "douryou", "rekan kerja", "N3", "noun", "同僚", "douryou", "同僚", "douryou", [
            ("同僚と話します。", "Douryou to hanashimasu.", "Saya berbicara dengan rekan kerja."),
        ]),
        ("kyuuryou", "給料", "きゅうりょう", "kyuuryou", "gaji", "N3", "noun", "給料", "kyuuryou", "給料", "kyuuryou", [
            ("給料をもらいます。", "Kyuuryou o moraimasu.", "Saya menerima gaji."),
        ]),
        ("zangyou", "残業", "ざんぎょう", "zangyou", "lembur", "N3", "noun", "残業", "zangyou", "残業", "zangyou", [
            ("今日は残業します。", "Kyou wa zangyou shimasu.", "Hari ini saya lembur."),
        ]),
        ("kyuujitsu", "休日", "きゅうじつ", "kyuujitsu", "hari libur", "N4", "noun", "休日", "kyuujitsu", "休日", "kyuujitsu", [
            ("休日は家にいます。", "Kyuujitsu wa ie ni imasu.", "Saat hari libur, saya di rumah."),
        ]),
    ],
    "teknologi_gadget": [
        ("konpyuutaa", None, "コンピューター", "konpyuutaa", "komputer", "N4", "noun", "コンピューター", "konpyuutaa", "コンピューター", "konpyuutaa", [
            ("コンピューターを使います。", "Konpyuutaa o tsukaimasu.", "Saya menggunakan komputer."),
        ]),
        ("sumaho", None, "スマホ", "sumaho", "smartphone (hp pintar)", "N4", "noun", "スマホ", "sumaho", "スマホ", "sumaho", [
            ("スマホで写真を撮ります。", "Sumaho de shashin o torimasu.", "Saya memotret dengan HP."),
        ]),
        ("keitai", "携帯", "けいたい", "keitai", "ponsel (istilah umum)", "N4", "noun", "携帯", "keitai", "携帯", "keitai", [
            ("携帯を忘れました。", "Keitai o wasuremashita.", "Saya lupa membawa ponsel."),
        ]),
        ("intaanetto", None, "インターネット", "intaanetto", "internet", "N4", "noun", "インターネット", "intaanetto", "インターネット", "intaanetto", [
            ("インターネットを使います。", "Intaanetto o tsukaimasu.", "Saya menggunakan internet."),
        ]),
        ("denwa", "電話", "でんわ", "denwa", "telepon", "N5", "noun", "電話", "denwa", "電話", "denwa", [
            ("電話をかけます。", "Denwa o kakemasu.", "Saya menelepon."),
        ]),
        ("meeru", None, "メール", "meeru", "email", "N4", "noun", "メール", "meeru", "メール", "meeru", [
            ("メールを送ります。", "Meeru o okurimasu.", "Saya mengirim email."),
        ]),
        ("apuri", None, "アプリ", "apuri", "aplikasi (app)", "N3", "noun", "アプリ", "apuri", "アプリ", "apuri", [
            ("アプリをダウンロードします。", "Apuri o daunroodo shimasu.", "Saya mengunduh aplikasi."),
        ]),
        ("kamera", None, "カメラ", "kamera", "kamera", "N4", "noun", "カメラ", "kamera", "カメラ", "kamera", [
            ("カメラで撮ります。", "Kamera de torimasu.", "Saya memotret dengan kamera."),
        ]),
        ("juuden", "充電", "じゅうでん", "juuden", "mengisi daya (charge)", "N3", "noun", "充電", "juuden", "充電", "juuden", [
            ("スマホを充電します。", "Sumaho o juuden shimasu.", "Saya mengisi daya HP."),
        ]),
        ("waifai", None, "ワイファイ", "waifai", "wifi", "N4", "noun", "ワイファイ", "waifai", "ワイファイ", "waifai", [
            ("ワイファイに繋げます。", "Waifai ni tsunagemasu.", "Saya menyambungkan ke wifi."),
        ]),
    ],
    "media_hiburan": [
        ("terebi", None, "テレビ", "terebi", "televisi", "N5", "noun", "テレビ", "terebi", "テレビ", "terebi", [
            ("テレビを見ます。", "Terebi o mimasu.", "Saya menonton televisi."),
        ]),
        ("manga", "漫画", "まんが", "manga", "komik (manga)", "N4", "noun", "漫画", "manga", "漫画", "manga", [
            ("漫画を読みます。", "Manga o yomimasu.", "Saya membaca komik."),
        ]),
        ("anime", None, "アニメ", "anime", "animasi (anime)", "N4", "noun", "アニメ", "anime", "アニメ", "anime", [
            ("アニメが好きです。", "Anime ga suki desu.", "Saya suka anime."),
        ]),
        ("shinbun", "新聞", "しんぶん", "shinbun", "koran", "N4", "noun", "新聞", "shinbun", "新聞", "shinbun", [
            ("新聞を読みます。", "Shinbun o yomimasu.", "Saya membaca koran."),
        ]),
        ("zasshi", "雑誌", "ざっし", "zasshi", "majalah", "N4", "noun", "雑誌", "zasshi", "雑誌", "zasshi", [
            ("雑誌を買いました。", "Zasshi o kaimashita.", "Saya membeli majalah."),
        ]),
        ("rajio", None, "ラジオ", "rajio", "radio", "N4", "noun", "ラジオ", "rajio", "ラジオ", "rajio", [
            ("ラジオを聴きます。", "Rajio o kikimasu.", "Saya mendengarkan radio."),
        ]),
        ("nyuusu", None, "ニュース", "nyuusu", "berita", "N4", "noun", "ニュース", "nyuusu", "ニュース", "nyuusu", [
            ("ニュースを見ます。", "Nyuusu o mimasu.", "Saya menonton berita."),
        ]),
        ("dorama", None, "ドラマ", "dorama", "drama (serial TV)", "N3", "noun", "ドラマ", "dorama", "ドラマ", "dorama", [
            ("ドラマを見ます。", "Dorama o mimasu.", "Saya menonton drama."),
        ]),
        ("yuuchuubu", None, "ユーチューブ", "yuuchuubu", "YouTube", "N3", "noun", "ユーチューブ", "yuuchuubu", "ユーチューブ", "yuuchuubu", [
            ("ユーチューブで動画を見ます。", "Yuuchuubu de douga o mimasu.", "Saya menonton video di YouTube."),
        ]),
        ("sns", None, "SNS", "esu-enu-esu", "media sosial", "N3", "noun", "SNS", "esu-enu-esu", "SNS", "esu-enu-esu", [
            ("SNSを使います。", "SNS o tsukaimasu.", "Saya menggunakan media sosial."),
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
