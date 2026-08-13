"""Copies/derives the two datasets the battle-scoring Cloud Function
(functions/battle_scoring.js) needs, from the same source files the
Flutter app itself bundles — see NOTES_CARD_GAME_MODE.md's "Detail
penilaian Cloud Function" ("salinan dataset bacaan ... ikut dibundel ke
folder functions/, dari sumber yang sama dengan yang dipakai aplikasi
Flutter").

Must be re-run whenever assets/data/kana_data.json or
assets/data/kanji_data.json regenerates, or the Cloud Function's answer
key silently drifts from what the app actually teaches — the same
re-run discipline this project already applies to every other
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
    for entry in kanji:
        if entry.get("placeholder"):
            continue
        kanji_id = entry["id"]
        for word_example in entry.get("wordExamples", []):
            key = f"{kanji_id}|{word_example['word']}"
            readings[key] = word_example["reading"]
    (OUT_DIR / "kanji_word_readings.json").write_text(
        json.dumps(readings, ensure_ascii=False, indent=2, sort_keys=True),
        encoding="utf-8",
    )

    print(f"kana_data.json: {len(kana)} entries")
    print(f"kanji_word_readings.json: {len(readings)} entries")


if __name__ == "__main__":
    main()
