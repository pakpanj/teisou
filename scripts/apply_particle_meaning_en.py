"""
apply_particle_meaning_en.py

Reads particle_meaning_en.py's PARTICLE_MEANING_EN and patches the English
fields into assets/data/particle_data.json: ParticleEntry.overviewEn,
ParticleFunction.titleEn/explanationEn, SentenceExample.translationEn,
ClozeExample.translationEn.

Five content kinds share one dict, disambiguated by key suffix:
    "{entry_id}|overview"                  -> entry['overviewEn']
    "{entry_id}|{function_id}|title"       -> function['titleEn']
    "{entry_id}|{function_id}|explanation" -> function['explanationEn']
    "{entry_id}|{function_id}|se{i}"       -> sentenceExamples[i]['translationEn']
    "{entry_id}|{function_id}|cloze{i}"    -> clozeExamples[i]['translationEn']

function_id is unique within its own entry (not globally), so it must
always be paired with entry_id. se{i}/cloze{i} are 0-based indices within
their own function's example list, stable since examples are never
reordered after authoring.

Mirrors apply_kaiwa_meaning_en.py's shape. Never touches any other field.
Safe to re-run. Must be re-run after generate_particle_seed.py
regenerates the dataset.

Cara pakai:
    python scripts/apply_particle_meaning_en.py
"""

import json
import os
import sys

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
REPO_ROOT = os.path.dirname(SCRIPT_DIR)
DATA_PATH = os.path.join(REPO_ROOT, "assets", "data", "particle_data.json")

sys.path.insert(0, SCRIPT_DIR)
from particle_meaning_en import PARTICLE_MEANING_EN  # noqa: E402


def main() -> None:
    with open(DATA_PATH, encoding="utf-8") as f:
        entries = json.load(f)

    slots = {}
    for entry in entries:
        slots[f"{entry['id']}|overview"] = entry
        for fn in entry.get("functions", []):
            slots[f"{entry['id']}|{fn['id']}|title"] = fn
            slots[f"{entry['id']}|{fn['id']}|explanation"] = fn
            for i, se in enumerate(fn.get("sentenceExamples", [])):
                slots[f"{entry['id']}|{fn['id']}|se{i}"] = se
            for i, ce in enumerate(fn.get("clozeExamples", [])):
                slots[f"{entry['id']}|{fn['id']}|cloze{i}"] = ce

    unknown = [key for key in PARTICLE_MEANING_EN if key not in slots]
    for key in unknown:
        print(f"[!] key tidak ditemukan di dataset: {key}")

    def kind_of(key: str) -> str:
        if key.endswith("|overview"):
            return "overview"
        if key.endswith("|title"):
            return "title"
        if key.endswith("|explanation"):
            return "explanation"
        if key.rsplit("|", 1)[-1].startswith("se"):
            return "se"
        return "cloze"

    patched = 0
    for key, english in PARTICLE_MEANING_EN.items():
        target = slots.get(key)
        if target is None:
            continue
        kind = kind_of(key)
        if kind == "overview":
            target["overviewEn"] = english
        elif kind == "title":
            target["titleEn"] = english
        elif kind == "explanation":
            target["explanationEn"] = english
        else:
            target["translationEn"] = english
        patched += 1

    with open(DATA_PATH, "w", encoding="utf-8") as f:
        json.dump(entries, f, ensure_ascii=False, indent=2)
        f.write("\n")

    def has_en(key: str, target: dict) -> bool:
        kind = kind_of(key)
        if kind == "overview":
            return bool(target.get("overviewEn"))
        if kind == "title":
            return bool(target.get("titleEn"))
        if kind == "explanation":
            return bool(target.get("explanationEn"))
        return bool(target.get("translationEn"))

    total = len(slots)
    have = sum(1 for key, target in slots.items() if has_en(key, target))
    print(f"[ok] particle fields: patched {patched}, {have}/{total} sudah ada English")

    kinds = {
        "overview": [0, 0],
        "title": [0, 0],
        "explanation": [0, 0],
        "se": [0, 0],
        "cloze": [0, 0],
    }
    for key, target in slots.items():
        kind = kind_of(key)
        kinds[kind][1] += 1
        if has_en(key, target):
            kinds[kind][0] += 1
    for kind, (done, count) in kinds.items():
        print(f"     {kind}: {done}/{count}")

    if unknown:
        raise SystemExit(f"{len(unknown)} key di PARTICLE_MEANING_EN tidak ada di dataset")


if __name__ == "__main__":
    main()
