"""
apply_kotoba_example_translation_en.py

Reads kotoba_example_translation_en.py's KOTOBA_EXAMPLE_TRANSLATION_EN
and patches the English field into every assets/data/kotoba/*.json
category file (excluding _categories.json): the single
sentenceExamples[0].translationEn per word.

Key format: plain word id -> translationEn.

Never touches any other field (meaning/meaningEn stay managed by
kotoba_meaning_en.py + apply_kotoba_meaning_en.py). Safe to re-run.
Must be re-run after any generate_kotoba_*.py script regenerates a
category file.

Cara pakai:
    python scripts/apply_kotoba_example_translation_en.py
"""

import glob
import json
import os
import sys

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
REPO_ROOT = os.path.dirname(SCRIPT_DIR)
DATA_DIR = os.path.join(REPO_ROOT, "assets", "data", "kotoba")

sys.path.insert(0, SCRIPT_DIR)
from kotoba_example_translation_en import (  # noqa: E402
    KOTOBA_EXAMPLE_TRANSLATION_EN,
)


def main() -> None:
    files = sorted(
        f
        for f in glob.glob(os.path.join(DATA_DIR, "*.json"))
        if "_categories" not in os.path.basename(f)
    )

    slots = {}
    file_data = {}
    for path in files:
        with open(path, encoding="utf-8") as f:
            entries = json.load(f)
        file_data[path] = entries
        for entry in entries:
            examples = entry.get("sentenceExamples", [])
            if examples:
                slots[entry["id"]] = examples[0]

    unknown = [key for key in KOTOBA_EXAMPLE_TRANSLATION_EN if key not in slots]
    for key in unknown:
        print(f"[!] key tidak ditemukan di dataset: {key}")

    patched = 0
    for key, english in KOTOBA_EXAMPLE_TRANSLATION_EN.items():
        target = slots.get(key)
        if target is None:
            continue
        target["translationEn"] = english
        patched += 1

    for path, entries in file_data.items():
        with open(path, "w", encoding="utf-8") as f:
            json.dump(entries, f, ensure_ascii=False, indent=2)
            f.write("\n")

    total = len(slots)
    have = sum(1 for se in slots.values() if se.get("translationEn"))
    print(f"[ok] kotoba example fields: patched {patched}, {have}/{total} sudah ada English")

    if unknown:
        raise SystemExit(
            f"{len(unknown)} key di KOTOBA_EXAMPLE_TRANSLATION_EN tidak ada di dataset"
        )


if __name__ == "__main__":
    main()
