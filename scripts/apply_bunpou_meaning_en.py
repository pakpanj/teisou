"""
apply_bunpou_meaning_en.py

Reads bunpou_meaning_en.py's BUNPOU_MEANING_EN and patches the
English fields into assets/data/bunpou_data.json:
BunpouEntry.meaningEn/formationEn/usageNotesEn,
SentenceExample.translationEn.

Four content kinds share one dict, disambiguated by key suffix:
    "{id}|meaning"     -> entry['meaningEn']
    "{id}|formation"   -> entry['formationEn']
    "{id}|usageNotes"  -> entry['usageNotesEn']
    "{id}|se{i}"       -> entry['sentenceExamples'][i]['translationEn']

se{i} is the example's 0-based index within its own entry's
sentenceExamples list, stable since examples are never reordered
after authoring.

Mirrors apply_kaiwa_meaning_en.py's shape. Never touches any other
field. Safe to re-run. Must be re-run after generate_bunpou_seed.py
regenerates the dataset.

Cara pakai:
    python scripts/apply_bunpou_meaning_en.py
"""

import json
import os
import sys

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
REPO_ROOT = os.path.dirname(SCRIPT_DIR)
DATA_PATH = os.path.join(REPO_ROOT, "assets", "data", "bunpou_data.json")

sys.path.insert(0, SCRIPT_DIR)
from bunpou_meaning_en import BUNPOU_MEANING_EN  # noqa: E402


def main() -> None:
    with open(DATA_PATH, encoding="utf-8") as f:
        entries = json.load(f)

    slots = {}
    for entry in entries:
        slots[f"{entry['id']}|meaning"] = entry
        slots[f"{entry['id']}|formation"] = entry
        slots[f"{entry['id']}|usageNotes"] = entry
        for i, se in enumerate(entry.get("sentenceExamples", [])):
            slots[f"{entry['id']}|se{i}"] = se

    unknown = [key for key in BUNPOU_MEANING_EN if key not in slots]
    for key in unknown:
        print(f"[!] key tidak ditemukan di dataset: {key}")

    def kind_of(key: str) -> str:
        if key.endswith("|meaning"):
            return "meaning"
        if key.endswith("|formation"):
            return "formation"
        if key.endswith("|usageNotes"):
            return "usageNotes"
        return "se"

    patched = 0
    for key, english in BUNPOU_MEANING_EN.items():
        target = slots.get(key)
        if target is None:
            continue
        kind = kind_of(key)
        if kind == "meaning":
            target["meaningEn"] = english
        elif kind == "formation":
            target["formationEn"] = english
        elif kind == "usageNotes":
            target["usageNotesEn"] = english
        else:
            target["translationEn"] = english
        patched += 1

    with open(DATA_PATH, "w", encoding="utf-8") as f:
        json.dump(entries, f, ensure_ascii=False, indent=2)
        f.write("\n")

    def has_en(key: str, target: dict) -> bool:
        kind = kind_of(key)
        if kind == "meaning":
            return bool(target.get("meaningEn"))
        if kind == "formation":
            return bool(target.get("formationEn"))
        if kind == "usageNotes":
            return bool(target.get("usageNotesEn"))
        return bool(target.get("translationEn"))

    total = len(slots)
    have = sum(1 for key, target in slots.items() if has_en(key, target))
    print(f"[ok] bunpou fields: patched {patched}, {have}/{total} sudah ada English")

    kinds = {"meaning": [0, 0], "formation": [0, 0], "usageNotes": [0, 0], "se": [0, 0]}
    for key, target in slots.items():
        kind = kind_of(key)
        kinds[kind][1] += 1
        if has_en(key, target):
            kinds[kind][0] += 1
    for kind, (done, count) in kinds.items():
        print(f"     {kind}: {done}/{count}")

    if unknown:
        raise SystemExit(f"{len(unknown)} key di BUNPOU_MEANING_EN tidak ada di dataset")


if __name__ == "__main__":
    main()
