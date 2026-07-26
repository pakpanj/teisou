"""
apply_kaiwa_meaning_en.py

Reads kaiwa_meaning_en.py's KAIWA_MEANING_EN and patches the English
fields into assets/data/kaiwa_data.json: KaiwaEntry.titleEn/descriptionEn,
KaiwaLine.npcLine.translationEn, KaiwaAnswerOption.translationEn.

Four content kinds share one dict, disambiguated by key suffix:
    "{entry_id}|title"              -> entry['titleEn']
    "{entry_id}|description"        -> entry['descriptionEn']
    "{entry_id}|{line_id}|npc"      -> line['npcLine']['translationEn']
    "{entry_id}|{line_id}|opt{i}"   -> line['options'][i]['translationEn']

line_id is unique within its own entry (not globally), so it must always
be paired with entry_id - verified once for the whole dataset (no entry
repeats a line id). opt{i} is the option's 0-based index within its own
line's options list, which is stable because options are never reordered
after authoring (only shuffled at render time in a copy).

Mirrors apply_kanji_word_meaning_en.py's shape. Never touches any other
field. Safe to re-run. Must be re-run after generate_kaiwa_seed.py
regenerates the dataset.

Cara pakai:
    python scripts/apply_kaiwa_meaning_en.py
"""

import json
import os
import sys

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
REPO_ROOT = os.path.dirname(SCRIPT_DIR)
DATA_PATH = os.path.join(REPO_ROOT, "assets", "data", "kaiwa_data.json")

sys.path.insert(0, SCRIPT_DIR)
from kaiwa_meaning_en import KAIWA_MEANING_EN  # noqa: E402


def main() -> None:
    with open(DATA_PATH, encoding="utf-8") as f:
        entries = json.load(f)

    slots = {}
    for entry in entries:
        slots[f"{entry['id']}|title"] = entry
        slots[f"{entry['id']}|description"] = entry
        for line in entry.get("lines", []):
            if line.get("npcLine") is not None:
                slots[f"{entry['id']}|{line['id']}|npc"] = line["npcLine"]
            for i, opt in enumerate(line.get("options", [])):
                slots[f"{entry['id']}|{line['id']}|opt{i}"] = opt

    unknown = [key for key in KAIWA_MEANING_EN if key not in slots]
    for key in unknown:
        print(f"[!] key tidak ditemukan di dataset: {key}")

    patched = 0
    for key, english in KAIWA_MEANING_EN.items():
        target = slots.get(key)
        if target is None:
            continue
        if key.endswith("|title"):
            target["titleEn"] = english
        elif key.endswith("|description"):
            target["descriptionEn"] = english
        else:
            target["translationEn"] = english
        patched += 1

    with open(DATA_PATH, "w", encoding="utf-8") as f:
        json.dump(entries, f, ensure_ascii=False, indent=2)
        f.write("\n")

    def has_en(key: str, target: dict) -> bool:
        if key.endswith("|title"):
            return bool(target.get("titleEn"))
        if key.endswith("|description"):
            return bool(target.get("descriptionEn"))
        return bool(target.get("translationEn"))

    total = len(slots)
    have = sum(1 for key, target in slots.items() if has_en(key, target))
    print(f"[ok] kaiwa fields: patched {patched}, {have}/{total} sudah ada English")

    kinds = {"title": [0, 0], "description": [0, 0], "npc": [0, 0], "opt": [0, 0]}
    for key, target in slots.items():
        if key.endswith("|title"):
            kind = "title"
        elif key.endswith("|description"):
            kind = "description"
        elif key.endswith("|npc"):
            kind = "npc"
        else:
            kind = "opt"
        kinds[kind][1] += 1
        if has_en(key, target):
            kinds[kind][0] += 1
    for kind, (done, count) in kinds.items():
        print(f"     {kind}: {done}/{count}")

    if unknown:
        raise SystemExit(f"{len(unknown)} key di KAIWA_MEANING_EN tidak ada di dataset")


if __name__ == "__main__":
    main()
