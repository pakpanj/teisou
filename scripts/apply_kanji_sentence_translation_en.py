"""
apply_kanji_sentence_translation_en.py

Reads kanji_sentence_translation_en.py's KANJI_SENTENCE_TRANSLATION_EN
and patches KanjiEntry.sentenceExamples[i].translationEn into
assets/data/kanji_data.json.

Keyed by "{kanji_id}|se{i}" (0-based index within that kanji's own
sentenceExamples list). Mirrors apply_bunpou_meaning_en.py's se{i}
handling and apply_kanji_word_meaning_en.py's overall shape. Never
touches any other field. Safe to re-run. Must be re-run after
generate_kanji_seed.py regenerates the dataset.

Cara pakai:
    python scripts/apply_kanji_sentence_translation_en.py
"""

import json
import os
import sys

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
REPO_ROOT = os.path.dirname(SCRIPT_DIR)
DATA_PATH = os.path.join(REPO_ROOT, "assets", "data", "kanji_data.json")

sys.path.insert(0, SCRIPT_DIR)
from kanji_sentence_translation_en import KANJI_SENTENCE_TRANSLATION_EN  # noqa: E402


def main() -> None:
    with open(DATA_PATH, encoding="utf-8") as f:
        entries = json.load(f)

    slots = {}
    entry_by_id = {e["id"]: e for e in entries}
    for entry in entries:
        for i, se in enumerate(entry.get("sentenceExamples", [])):
            slots[f"{entry['id']}|se{i}"] = se

    unknown = [key for key in KANJI_SENTENCE_TRANSLATION_EN if key not in slots]
    for key in unknown:
        print(f"[!] key tidak ditemukan di dataset: {key}")

    patched = 0
    for key, english in KANJI_SENTENCE_TRANSLATION_EN.items():
        target = slots.get(key)
        if target is None:
            continue
        target["translationEn"] = english
        patched += 1

    with open(DATA_PATH, "w", encoding="utf-8") as f:
        json.dump(entries, f, ensure_ascii=False, indent=2)
        f.write("\n")

    total = len(slots)
    have = sum(1 for target in slots.values() if target.get("translationEn"))
    print(f"[ok] kanji sentence examples: patched {patched}, {have}/{total} sudah ada English")

    by_level = {}
    for entry in entries:
        lvl = entry["jlptLevel"]
        for se in entry.get("sentenceExamples", []):
            counts = by_level.setdefault(lvl, [0, 0])
            counts[1] += 1
            if se.get("translationEn"):
                counts[0] += 1
    for lvl in sorted(by_level):
        done, count = by_level[lvl]
        print(f"     {lvl}: {done}/{count}")

    if unknown:
        raise SystemExit(f"{len(unknown)} key di KANJI_SENTENCE_TRANSLATION_EN tidak ada di dataset")


if __name__ == "__main__":
    main()
