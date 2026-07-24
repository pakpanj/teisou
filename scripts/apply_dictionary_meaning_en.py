"""
apply_dictionary_meaning_en.py

Reads dictionary_meaning_en.py's MEANING_EN dict and patches `meaningEn`
into the matching entries of assets/data/dictionary_data.json. Mirrors
apply_kotoba_meaning_en.py exactly — same locked-list + applier split, so
translations live in one authored file and never get hand-edited into the
generated JSON.

Never touches any other field. Safe to re-run (idempotent). Must be re-run
after generate_dictionary_seed.py regenerates the dataset, since that
generator knows nothing about meaningEn.

Cara pakai:
    python scripts/apply_dictionary_meaning_en.py
"""

import json
import os
import sys

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
REPO_ROOT = os.path.dirname(SCRIPT_DIR)
DATA_PATH = os.path.join(REPO_ROOT, "assets", "data", "dictionary_data.json")

sys.path.insert(0, SCRIPT_DIR)
from dictionary_meaning_en import MEANING_EN  # noqa: E402


def main() -> None:
    with open(DATA_PATH, encoding="utf-8") as f:
        entries = json.load(f)

    by_id = {e["id"]: e for e in entries}
    missing_ids = [wid for wid in MEANING_EN if wid not in by_id]
    for wid in missing_ids:
        print(f"[!] id tidak ditemukan di dataset: {wid}")

    patched = 0
    for wid, english in MEANING_EN.items():
        entry = by_id.get(wid)
        if entry is None:
            continue
        entry["meaningEn"] = english
        patched += 1

    with open(DATA_PATH, "w", encoding="utf-8") as f:
        json.dump(entries, f, ensure_ascii=False, indent=2)
        f.write("\n")

    total = len(entries)
    have = sum(1 for e in entries if e.get("meaningEn"))
    print(f"[ok] dictionary: patched {patched} kata, {have}/{total} total sudah ada meaningEn")
    if have < total:
        pending = [e["id"] for e in entries if not e.get("meaningEn")]
        print(f"     belum diterjemahkan: {len(pending)} (mulai dari {pending[0]})")
    if missing_ids:
        raise SystemExit(f"{len(missing_ids)} id di MEANING_EN tidak ada di dataset")


if __name__ == "__main__":
    main()
