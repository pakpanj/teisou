"""
apply_kanji_word_meaning_en.py

Reads kanji_word_meaning_en.py's WORD_MEANING_EN and patches `meaningEn`
into each kanji's wordExamples inside assets/data/kanji_data.json.

Keyed by "{kanji_id}|{word}" because the same compound word can appear
under more than one kanji (e.g. 大雪 under both 大 and 雪), and the same
kanji never repeats a word within its own example list — so this pair is
unique and readable, unlike a bare positional index that would silently
shift if an example is ever inserted.

Mirrors apply_kotoba_meaning_en.py / apply_dictionary_meaning_en.py.
Never touches any other field. Safe to re-run. Must be re-run after
generate_kanji_seed.py regenerates the dataset (alongside
split_kanji_meanings_en.py).

Cara pakai:
    python scripts/apply_kanji_word_meaning_en.py
"""

import json
import os
import sys

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
REPO_ROOT = os.path.dirname(SCRIPT_DIR)
DATA_PATH = os.path.join(REPO_ROOT, "assets", "data", "kanji_data.json")

sys.path.insert(0, SCRIPT_DIR)
from kanji_word_meaning_en import WORD_MEANING_EN  # noqa: E402


def main() -> None:
    with open(DATA_PATH, encoding="utf-8") as f:
        entries = json.load(f)

    slots = {}
    for entry in entries:
        for example in entry.get("wordExamples", []):
            slots[f"{entry['id']}|{example['word']}"] = example

    unknown = [key for key in WORD_MEANING_EN if key not in slots]
    for key in unknown:
        print(f"[!] key tidak ditemukan di dataset: {key}")

    patched = 0
    for key, english in WORD_MEANING_EN.items():
        example = slots.get(key)
        if example is None:
            continue
        example["meaningEn"] = english
        patched += 1

    with open(DATA_PATH, "w", encoding="utf-8") as f:
        json.dump(entries, f, ensure_ascii=False, indent=2)
        f.write("\n")

    total = len(slots)
    have = sum(1 for e in slots.values() if e.get("meaningEn"))
    print(f"[ok] kanji word examples: patched {patched}, {have}/{total} sudah ada meaningEn")

    by_level = {}
    for entry in entries:
        level = entry["jlptLevel"]
        done = sum(1 for e in entry.get("wordExamples", []) if e.get("meaningEn"))
        count = len(entry.get("wordExamples", []))
        prev_done, prev_total = by_level.get(level, (0, 0))
        by_level[level] = (prev_done + done, prev_total + count)
    for level in ("N5", "N4", "N3", "N2", "N1"):
        done, count = by_level.get(level, (0, 0))
        print(f"     {level}: {done}/{count}")

    if unknown:
        raise SystemExit(f"{len(unknown)} key di WORD_MEANING_EN tidak ada di dataset")


if __name__ == "__main__":
    main()
