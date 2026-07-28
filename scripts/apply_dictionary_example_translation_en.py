"""
apply_dictionary_example_translation_en.py

Reads dictionary_example_translation_en.py's
DICTIONARY_EXAMPLE_TRANSLATION_EN and patches the English field into
assets/data/dictionary_data.json: DictionaryExample.translationEn.

Key format: plain word id -> the example's translationEn.

Never touches any other field (meaning/meaningEn stay managed by
dictionary_meaning_en.py + apply_dictionary_meaning_en.py). Safe to
re-run. Must be re-run after generate_dictionary_seed.py regenerates
the dataset.

Cara pakai:
    python scripts/apply_dictionary_example_translation_en.py
"""

import json
import os
import sys

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
REPO_ROOT = os.path.dirname(SCRIPT_DIR)
DATA_PATH = os.path.join(REPO_ROOT, "assets", "data", "dictionary_data.json")

sys.path.insert(0, SCRIPT_DIR)
from dictionary_example_translation_en import (  # noqa: E402
    DICTIONARY_EXAMPLE_TRANSLATION_EN,
)


def main() -> None:
    with open(DATA_PATH, encoding="utf-8") as f:
        entries = json.load(f)

    slots = {entry["id"]: entry for entry in entries}

    unknown = [key for key in DICTIONARY_EXAMPLE_TRANSLATION_EN if key not in slots]
    for key in unknown:
        print(f"[!] key tidak ditemukan di dataset: {key}")

    patched = 0
    for key, english in DICTIONARY_EXAMPLE_TRANSLATION_EN.items():
        target = slots.get(key)
        if target is None:
            continue
        target["example"]["translationEn"] = english
        patched += 1

    with open(DATA_PATH, "w", encoding="utf-8") as f:
        json.dump(entries, f, ensure_ascii=False, indent=2)
        f.write("\n")

    total = len(slots)
    have = sum(1 for e in entries if e["example"].get("translationEn"))
    print(f"[ok] dictionary example fields: patched {patched}, {have}/{total} sudah ada English")

    if unknown:
        raise SystemExit(
            f"{len(unknown)} key di DICTIONARY_EXAMPLE_TRANSLATION_EN tidak ada di dataset"
        )


if __name__ == "__main__":
    main()
