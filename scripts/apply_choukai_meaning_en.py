"""
apply_choukai_meaning_en.py

Reads choukai_meaning_en.py's CHOUKAI_MEANING_EN and patches the English
fields into assets/data/choukai_data.json: ChoukaiClip.titleEn /
audioTranslationEn.

Two content kinds share one dict, disambiguated by key suffix:
    "{id}|title"             -> clip['titleEn']
    "{id}|audioTranslation"  -> clip['audioTranslationEn']

The script itself (audioText) is Japanese and is never translated — it is
the material being tested. The questions and options are Japanese too.

Mirrors apply_dokkai_meaning_en.py exactly. Never touches any other
field. Safe to re-run. **Must be re-run after generate_choukai_seed.py
regenerates the dataset** — regeneration writes the file from
generate_choukai_seed.py alone and drops every English field. That is not
hypothetical: it is exactly how 1,000 already-authored Dokkai
translations ended up absent from the shipped asset, unnoticed, because
nothing tested for them. test/content_localization_test.dart now covers
both modules, so a wipe fails the suite instead of shipping.

Cara pakai:
    python scripts/apply_choukai_meaning_en.py
"""

import json
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from choukai_meaning_en import CHOUKAI_MEANING_EN  # noqa: E402

DATA_PATH = os.path.join(
    os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
    "assets", "data", "choukai_data.json",
)


def main() -> None:
    with open(DATA_PATH, encoding="utf-8") as f:
        entries = json.load(f)

    slots = {}
    for entry in entries:
        slots[f"{entry['id']}|title"] = entry
        slots[f"{entry['id']}|audioTranslation"] = entry

    unknown = [key for key in CHOUKAI_MEANING_EN if key not in slots]
    for key in unknown:
        print(f"[!] key tidak ditemukan di dataset: {key}")

    patched = 0
    for key, english in CHOUKAI_MEANING_EN.items():
        target = slots.get(key)
        if target is None:
            continue
        if key.endswith("|title"):
            target["titleEn"] = english
        else:
            target["audioTranslationEn"] = english
        patched += 1

    with open(DATA_PATH, "w", encoding="utf-8") as f:
        json.dump(entries, f, ensure_ascii=False, indent=2)
        f.write("\n")

    def has_en(key: str, target: dict) -> bool:
        if key.endswith("|title"):
            return bool(target.get("titleEn"))
        return bool(target.get("audioTranslationEn"))

    total = len(slots)
    have = sum(1 for key, target in slots.items() if has_en(key, target))
    print(f"[ok] choukai fields: patched {patched}, {have}/{total} sudah ada English")

    kinds = {"title": [0, 0], "audioTranslation": [0, 0]}
    for key, target in slots.items():
        kind = "title" if key.endswith("|title") else "audioTranslation"
        kinds[kind][1] += 1
        if has_en(key, target):
            kinds[kind][0] += 1
    for kind, (done, count) in kinds.items():
        print(f"     {kind}: {done}/{count}")

    if unknown:
        raise SystemExit(
            f"{len(unknown)} key di CHOUKAI_MEANING_EN tidak ada di dataset")


if __name__ == "__main__":
    main()
