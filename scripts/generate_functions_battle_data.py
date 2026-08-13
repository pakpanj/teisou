"""Copies/derives the datasets the battle Cloud Functions
(functions/battle_scoring.js, functions/battle_matchmaking.js) need,
from the same source files the Flutter app itself bundles — see
NOTES_CARD_GAME_MODE.md's "Detail penilaian Cloud Function" ("salinan
dataset bacaan ... ikut dibundel ke folder functions/, dari sumber yang
sama dengan yang dipakai aplikasi Flutter").

Must be re-run whenever assets/data/kana_data.json or
assets/data/kanji_data.json regenerates, or the Cloud Functions' answer
key / deck pools silently drift from what the app actually teaches —
the same re-run discipline this project already applies to every other
generated-from-source-of-truth file.

Run from the repo root: `python scripts/generate_functions_battle_data.py`
"""

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
KANA_SRC = ROOT / "assets" / "data" / "kana_data.json"
KANJI_SRC = ROOT / "assets" / "data" / "kanji_data.json"
OUT_DIR = ROOT / "functions" / "data"


def main():
    OUT_DIR.mkdir(parents=True, exist_ok=True)

    # Kana: copied whole (id/character/romaji/type/row) — only ~70KB, and
    # the Cloud Function's romaji converter needs every character->romaji
    # mapping, the same shape RomajiConverter.dart builds from
    # KanaRepository.getAll().
    kana = json.loads(KANA_SRC.read_text(encoding="utf-8"))
    (OUT_DIR / "kana_data.json").write_text(
        json.dumps(kana, ensure_ascii=False, indent=2), encoding="utf-8"
    )

    # Kanji: trimmed to exactly what scoring needs — one romaji reading
    # per "{kanjiId}|{word}" key, the same key shape
    # battle_deck_builder.dart's buildDeckIds/resolveCard already use.
    # Not the full 3.3MB dataset (meanings, sentence examples, stroke
    # data, etc. are all irrelevant to scoring an already-known cardId).
    kanji = json.loads(KANJI_SRC.read_text(encoding="utf-8"))
    readings = {}
    # cardId ("{kanjiId}|{word}") grouped by JLPT level — what
    # battle_matchmaking.js's own deck builder needs to replicate
    # battle_deck_builder.dart's _kanjiWordIds pool-by-tier logic
    # server-side. A separate file rather than folding jlptLevel into
    # kanji_word_readings.json's existing flat {cardId: reading} shape,
    # so battle_scoring.js's own reading lookup (its only consumer)
    # doesn't need touching.
    ids_by_level = {"n5": [], "n4": [], "n3": [], "n2": [], "n1": []}
    for entry in kanji:
        if entry.get("placeholder"):
            continue
        kanji_id = entry["id"]
        level_key = entry.get("jlptLevel", "").lower()
        for word_example in entry.get("wordExamples", []):
            key = f"{kanji_id}|{word_example['word']}"
            readings[key] = word_example["reading"]
            if level_key in ids_by_level:
                ids_by_level[level_key].append(key)
    (OUT_DIR / "kanji_word_readings.json").write_text(
        json.dumps(readings, ensure_ascii=False, indent=2, sort_keys=True),
        encoding="utf-8",
    )
    (OUT_DIR / "kanji_ids_by_level.json").write_text(
        json.dumps(ids_by_level, ensure_ascii=False, indent=2, sort_keys=True),
        encoding="utf-8",
    )

    print(f"kana_data.json: {len(kana)} entries")
    print(f"kanji_word_readings.json: {len(readings)} entries")
    for level, ids in ids_by_level.items():
        print(f"kanji_ids_by_level.json[{level}]: {len(ids)} entries")


if __name__ == "__main__":
    main()
