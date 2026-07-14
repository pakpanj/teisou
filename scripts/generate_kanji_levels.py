import json

# Metadata for the 5 JLPT kanji levels (Batch 7). `available` levels have a
# real dataset in kanji_data.json; the rest are placeholders so the level
# picker can show them with a "Segera" badge instead of omitting them.
# Re-run this script after authoring a new level's kanji to flip its
# `available` flag and fill in the real `kanjiCount`.
#
# Each tuple: (id, name, available, kanjiCount)
LEVELS = [
    ("N5", "N5", True, 39),
    ("N4", "N4", False, None),
    ("N3", "N3", False, None),
    ("N2", "N2", False, None),
    ("N1", "N1", False, None),
]


def build_entries():
    entries = []
    for level_id, name, available, kanji_count in LEVELS:
        entry = {
            "id": level_id,
            "name": name,
            "available": available,
        }
        if kanji_count is not None:
            entry["kanjiCount"] = kanji_count
        entries.append(entry)
    return entries


def main():
    data = build_entries()
    with open("assets/data/kanji/_levels.json", "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
    available = sum(1 for e in data if e["available"])
    print(f"Wrote {len(data)} levels ({available} available, {len(data) - available} segera).")


if __name__ == "__main__":
    main()
