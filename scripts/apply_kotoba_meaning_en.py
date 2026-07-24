"""
apply_kotoba_meaning_en.py

Reads kotoba_meaning_en.py's MEANING_EN dict and patches `meaningEn` into
the matching entries of each category's assets/data/kotoba/{id}.json.
Never touches any other field. Safe to re-run (idempotent — just
overwrites meaningEn with whatever's currently in the dict).

Cara pakai:
    python scripts/apply_kotoba_meaning_en.py             # semua kategori di dict
    python scripts/apply_kotoba_meaning_en.py ikan bentuk  # kategori tertentu saja
"""

import json
import os
import sys

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
REPO_ROOT = os.path.dirname(SCRIPT_DIR)
KOTOBA_DIR = os.path.join(REPO_ROOT, "assets", "data", "kotoba")

sys.path.insert(0, SCRIPT_DIR)
from kotoba_meaning_en import MEANING_EN  # noqa: E402


def apply_category(category_id: str, translations: dict[str, str]) -> tuple[int, int]:
    path = os.path.join(KOTOBA_DIR, f"{category_id}.json")
    if not os.path.exists(path):
        print(f"[!] {category_id}: file tidak ditemukan di {path}, dilewati")
        return (0, 0)

    with open(path, encoding="utf-8") as f:
        data = json.load(f)

    ids_in_file = {e["id"] for e in data}
    unknown_ids = set(translations) - ids_in_file
    if unknown_ids:
        print(f"[!] {category_id}: id di MEANING_EN tapi tidak ada di file: {sorted(unknown_ids)}")

    patched = 0
    for entry in data:
        if entry["id"] in translations:
            entry["meaningEn"] = translations[entry["id"]]
            patched += 1

    with open(path, "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
        f.write("\n")

    total = len(data)
    missing = total - sum(1 for e in data if "meaningEn" in e)
    print(f"[ok] {category_id}: patched {patched} kata, {total - missing}/{total} total sudah ada meaningEn")
    return (patched, total)


def main():
    targets = sys.argv[1:] if len(sys.argv) > 1 else list(MEANING_EN.keys())
    unknown = [t for t in targets if t not in MEANING_EN]
    if unknown:
        print(f"Kategori tidak ada di MEANING_EN: {unknown}")
        sys.exit(1)

    grand_patched = 0
    grand_total_translated = 0
    for cid in targets:
        patched, _ = apply_category(cid, MEANING_EN[cid])
        grand_patched += patched

    for cid, translations in MEANING_EN.items():
        grand_total_translated += len(translations)

    print(f"\nSelesai. {grand_patched} kata dipatch kali ini.")
    print(f"Total kata dengan meaningEn di seluruh MEANING_EN: {grand_total_translated}")


if __name__ == "__main__":
    main()
