# Generates assets/data/dictionary_data.json for the comprehensive
# search-only dictionary (DictionaryWord), from the locked word list in
# dictionary_word_lists.py. Ids are assigned sequentially here
# (dict_00001, dict_00002, ...) rather than hand-authored in the word
# list, so future batches can just be appended without id bookkeeping.
#
# Run from repo root: python scripts/generate_dictionary_seed.py

import json

from dictionary_word_lists import ALL_WORDS


def build_entries(words):
    result = []
    for i, (kanji, reading, meaning, example_ja, example_tr) in enumerate(
        words, start=1
    ):
        result.append(
            {
                "id": f"dict_{i:05d}",
                "kanji": kanji,
                "reading": reading,
                "meaning": meaning,
                "example": {
                    "japanese": example_ja,
                    "translation": example_tr,
                },
            }
        )
    return result


def main():
    entries = build_entries(ALL_WORDS)

    ids = [e["id"] for e in entries]
    assert len(ids) == len(set(ids)), "duplicate dictionary entry ids"

    for e in entries:
        assert e["reading"], f"{e['id']}: missing reading"
        assert e["meaning"], f"{e['id']}: missing meaning"
        assert e["example"]["japanese"], f"{e['id']}: missing example japanese"
        assert e["example"]["translation"], f"{e['id']}: missing example translation"

    with open("assets/data/dictionary_data.json", "w", encoding="utf-8") as f:
        json.dump(entries, f, ensure_ascii=False, indent=2)

    print(f"Total: {len(entries)} dictionary words")


if __name__ == "__main__":
    main()
