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
