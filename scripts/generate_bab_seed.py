# Generates assets/data/bab_data.json from scripts/bab_lists.py.
#
# Unlike every other generate_*_seed.py in this project, this script
# authors NO new content of its own — it only assembles ordered id-lists
# that reference six *other* already-generated datasets. Its one critical
# job is proving every id it writes actually resolves, since Dart's
# compile-time checking can't catch a typo'd cross-module string id — a
# dangling id here would otherwise become a silently-skipped row at
# runtime (see BabDetailScreen's null-filtering) instead of a build-time
# failure. Run from repo root: python scripts/generate_bab_seed.py

import glob
import json

from bab_lists import N5_CHAPTERS

ALL_CHAPTERS = N5_CHAPTERS  # extend with N4_CHAPTERS etc. as authored


def _ids(path):
    with open(path, encoding="utf-8") as f:
        return {row["id"] for row in json.load(f)}


def _kotoba_ids():
    # Mirrors KotobaRepository.getById's resolution order: the small
    # legacy Batch 4 seed file, plus every per-category file the real
    # 1,682-word vocab module actually lives in.
    ids = _ids("assets/data/kotoba_data.json")
    for path in glob.glob("assets/data/kotoba/*.json"):
        if path.endswith("_categories.json"):
            continue
        ids |= _ids(path)
    return ids


def main():
    kotoba_ids = _kotoba_ids()
    kanji_ids = _ids("assets/data/kanji_data.json")
    bunpou_ids = _ids("assets/data/bunpou_data.json")
    particle_ids = _ids("assets/data/particle_data.json")
    kaiwa_ids = _ids("assets/data/kaiwa_data.json")
    dokkai_ids = _ids("assets/data/dokkai_data.json")

    seen_ids = set()
    seen_orders = set()
    entries = []

    for ch in ALL_CHAPTERS:
        assert ch["id"] not in seen_ids, f"duplicate bab id: {ch['id']}"
        assert ch["order"] not in seen_orders, f"duplicate bab order: {ch['order']}"
        seen_ids.add(ch["id"])
        seen_orders.add(ch["order"])

        for field, pool, name in [
            ("kotoba_ids", kotoba_ids, "kotoba"),
            ("kanji_ids", kanji_ids, "kanji"),
            ("bunpou_ids", bunpou_ids, "bunpou"),
            ("particle_ids", particle_ids, "particle"),
            ("kaiwa_ids", kaiwa_ids, "kaiwa"),
            ("dokkai_ids", dokkai_ids, "dokkai"),
        ]:
            missing = [i for i in ch.get(field, []) if i not in pool]
            assert not missing, f"{ch['id']}: unknown {name} ids {missing}"

        entries.append({
            "id": ch["id"],
            "order": ch["order"],
            "title": ch["title"],
            "titleEn": ch.get("title_en"),
            "description": ch["description"],
            "descriptionEn": ch.get("description_en"),
            "level": ch["level"],
            "kotobaIds": ch.get("kotoba_ids", []),
            "kanjiIds": ch.get("kanji_ids", []),
            "bunpouIds": ch.get("bunpou_ids", []),
            "particleIds": ch.get("particle_ids", []),
            "kaiwaIds": ch.get("kaiwa_ids", []),
            "dokkaiIds": ch.get("dokkai_ids", []),
        })

    assert seen_orders == set(range(1, len(ALL_CHAPTERS) + 1)), (
        "bab order must be contiguous, starting at 1"
    )

    with open("assets/data/bab_data.json", "w", encoding="utf-8") as f:
        json.dump(entries, f, ensure_ascii=False, indent=2)

    print(f"Wrote {len(entries)} Bab chapters (N5: {len(N5_CHAPTERS)}).")


if __name__ == "__main__":
    main()
