"""
apply_dokkai_meaning_en.py

Reads dokkai_meaning_en.py's DOKKAI_MEANING_EN and patches the English
fields into assets/data/dokkai_data.json: DokkaiPassage.titleEn/
passageTranslationEn.

Two content kinds share one dict, disambiguated by key suffix:
    "{id}|title"               -> entry['titleEn']
    "{id}|passageTranslation"  -> entry['passageTranslationEn']

Mirrors apply_kaiwa_meaning_en.py's shape. Never touches any other
field. Safe to re-run. Must be re-run after generate_dokkai_seed.py
regenerates the dataset.

Cara pakai:
    python scripts/apply_dokkai_meaning_en.py
"""

import json
import os
import sys

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
REPO_ROOT = os.path.dirname(SCRIPT_DIR)
DATA_PATH = os.path.join(REPO_ROOT, "assets", "data", "dokkai_data.json")

sys.path.insert(0, SCRIPT_DIR)
from dokkai_meaning_en import DOKKAI_MEANING_EN  # noqa: E402


def main() -> None:
    with open(DATA_PATH, encoding="utf-8") as f:
        entries = json.load(f)

    slots = {}
    for entry in entries:
        slots[f"{entry['id']}|title"] = entry
        slots[f"{entry['id']}|passageTranslation"] = entry

    unknown = [key for key in DOKKAI_MEANING_EN if key not in slots]
    for key in unknown:
        print(f"[!] key tidak ditemukan di dataset: {key}")

    patched = 0
    for key, english in DOKKAI_MEANING_EN.items():
        target = slots.get(key)
        if target is None:
            continue
        if key.endswith("|title"):
            target["titleEn"] = english
        else:
            target["passageTranslationEn"] = english
        patched += 1

    with open(DATA_PATH, "w", encoding="utf-8") as f:
        json.dump(entries, f, ensure_ascii=False, indent=2)
        f.write("\n")

    def has_en(key: str, target: dict) -> bool:
        if key.endswith("|title"):
            return bool(target.get("titleEn"))
        return bool(target.get("passageTranslationEn"))

    total = len(slots)
    have = sum(1 for key, target in slots.items() if has_en(key, target))
    print(f"[ok] dokkai fields: patched {patched}, {have}/{total} sudah ada English")

    kinds = {"title": [0, 0], "passageTranslation": [0, 0]}
    for key, target in slots.items():
        kind = "title" if key.endswith("|title") else "passageTranslation"
        kinds[kind][1] += 1
        if has_en(key, target):
            kinds[kind][0] += 1
    for kind, (done, count) in kinds.items():
        print(f"     {kind}: {done}/{count}")

    if unknown:
        raise SystemExit(f"{len(unknown)} key di DOKKAI_MEANING_EN tidak ada di dataset")


if __name__ == "__main__":
    main()
