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

N4_ENTRIES = []
N3_ENTRIES = []
N2_ENTRIES = []
N1_ENTRIES = []


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
        qs = []
        for j, (prompt, options, correct) in enumerate(questions):
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
