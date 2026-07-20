"""One-shot importer: takes the 377 new 2-3-kanji compound words mined from
TANGO N2 (tango_n2_source.json + tango_n2_category_map.py) and splices them
into the right generate_kotoba_*.py script files as new tuples, using the
example sentence + Indonesian meaning already provided by the source book
(lightly cleaned) rather than hand-authoring new ones.

Run from the teisou project root: python scripts/reference/apply_tango_n2.py
"""
import json
import re
import sys

sys.path.insert(0, "scripts/reference")
from tango_n2_category_map import CATEGORY_BY_NUMBER, CATEGORY_TO_SCRIPT  # noqa: E402
from hiragana_romaji import to_romaji  # noqa: E402
from tango_n2_example_romaji import EXAMPLE_ROMAJI_BY_NUMBER  # noqa: E402
from tango_n2_word_meaning import MEANING_BY_NUMBER  # noqa: E402

TWELVE_FIELD_SCRIPTS = {
    "generate_kotoba_waktu_angka.py",
    "generate_kotoba_tempat_transportasi.py",
    "generate_kotoba_manusia_sosial.py",
    "generate_kotoba_pendidikan_pekerjaan.py",
    "generate_kotoba_tubuh_kesehatan.py",
}
SEVEN_FIELD_SCRIPTS = {
    "generate_kotoba_alam.py",
    "generate_kotoba_makanan_minuman.py",
}

# Manual corrections for source-PDF issues caught during extraction review.
READING_FIXES = {
    510: "しんにゅうせい",  # was garbled "新入せい" in the PDF
}
KANJI_PICK = {
    1000: "市場",  # keep full kanji, drop the "/" alt-reading marker
}
READING_PICK = {
    1000: "いちば",  # の"market" (as in 魚市場, fish market) not しじょう (abstract economic market)
}

STRAY_ARTIFACT_PATTERNS = [
    re.compile(r"\bF\.?\s*(?=\()"),  # "F. (...)" / "F (...)" study-note markers
    re.compile(r"\s+F\s+[^\s(]+\s*(?=\(|$)"),  # "F 増える" / "F 夜　" trailing cross-refs
]


def clean_meaning(text):
    for pat in STRAY_ARTIFACT_PATTERNS:
        text = pat.sub(" ", text)
    text = re.sub(r"\s+", " ", text).strip()
    text = text.replace(" .", ".").replace(" )", ")")
    return text


def load_entries():
    tango = json.load(open("scripts/reference/tango_n2_source.json", encoding="utf-8"))
    by_number = {e["number"]: e for e in tango}
    result = []
    for num, category in CATEGORY_BY_NUMBER.items():
        e = by_number[num]
        kanji = KANJI_PICK.get(num, e["kanji"].split("/")[0])
        reading = READING_PICK.get(num, READING_FIXES.get(num, e["reading"].split("/")[0]))
        # Word-level dictionary gloss (short) - NOT the same as the source
        # PDF's own "meaning" column, which is actually the Indonesian
        # translation of the *example sentence* (e.g. "Saya mengubah gaya
        # rambut" for 髪型, not "gaya rambut") - reusing that as this
        # dataset's word-level `meaning` field would put a full sentence
        # where every other entry has a short gloss, so it's authored
        # separately in tango_n2_word_meaning.py instead.
        meaning = MEANING_BY_NUMBER[num]
        example_translation = clean_meaning(e["meaning"])
        example_ja = e["example"]
        romaji = to_romaji(reading)
        result.append({
            "number": num, "category": category, "kanji": kanji,
            "reading": reading, "romaji": romaji, "meaning": meaning,
            "example_ja": example_ja, "example_translation": example_translation,
            "level": "N2",
        })
    return result


def existing_ids_and_kanji():
    import glob
    ids = set()
    kanji = set()
    for f in glob.glob("assets/data/kotoba/*.json"):
        if "_categories" in f:
            continue
        for e in json.load(open(f, encoding="utf-8")):
            ids.add(e["id"])
            if e.get("kanji"):
                kanji.add(e["kanji"])
    return ids, kanji


def build_tuples(entries):
    """Returns dict: category -> list of tuple-literal strings (as Python
    source text), plus resolves id-suffix collisions against the existing
    dataset and within this batch itself."""
    existing_ids, existing_kanji = existing_ids_and_kanji()
    used_suffixes_by_category = {}
    out = {}
    for e in entries:
        cat = e["category"]
        base_suffix = e["romaji"].replace("-", "")
        suffix = base_suffix
        used = used_suffixes_by_category.setdefault(cat, set())
        counter = 2
        candidate_id = f"kotoba_{cat}_{suffix}"
        while suffix in used or candidate_id in existing_ids:
            suffix = f"{base_suffix}{counter}"
            candidate_id = f"kotoba_{cat}_{suffix}"
            counter += 1
        used.add(suffix)

        kanji_lit = json.dumps(e["kanji"], ensure_ascii=False)
        reading_lit = json.dumps(e["reading"], ensure_ascii=False)
        romaji_lit = json.dumps(e["romaji"], ensure_ascii=False)
        meaning_lit = json.dumps(e["meaning"], ensure_ascii=False)
        example_ja_lit = json.dumps(e["example_ja"], ensure_ascii=False)
        example_romaji_lit = json.dumps(EXAMPLE_ROMAJI_BY_NUMBER[e["number"]], ensure_ascii=False)
        example_id_lit = json.dumps(e["example_translation"], ensure_ascii=False)

        script = CATEGORY_TO_SCRIPT[cat]
        if script in TWELVE_FIELD_SCRIPTS:
            tup = (
                f'        ("{suffix}", {kanji_lit}, {reading_lit}, {romaji_lit}, {meaning_lit}, '
                f'"N2", "noun", {kanji_lit}, {romaji_lit}, {kanji_lit}, {romaji_lit}, [\n'
                f'            ({example_ja_lit}, {example_romaji_lit}, {example_id_lit}),\n'
                f'        ]),\n'
            )
        else:
            tup = (
                f'        ("{suffix}", {kanji_lit}, {reading_lit}, {romaji_lit}, {meaning_lit}, "N2", [\n'
                f'            ({example_ja_lit}, {example_romaji_lit}, {example_id_lit}),\n'
                f'        ]),\n'
            )
        out.setdefault(cat, []).append(tup)
    return out


def insert_into_scripts(tuples_by_cat):
    """For each category, find its `"category_id": [` (or `"category_id":
    ("label", "type", [`) block in the owning script file and insert the
    new tuples right before that block's closing line - either `    ],`
    (12-field scripts) or `    ]),` (7-field scripts)."""
    by_script = {}
    for cat, tups in tuples_by_cat.items():
        script = CATEGORY_TO_SCRIPT[cat]
        by_script.setdefault(script, {})[cat] = tups

    for script, cats in by_script.items():
        path = f"scripts/{script}"
        with open(path, encoding="utf-8") as f:
            lines = f.readlines()
        for cat, tups in cats.items():
            start_pat = re.compile(rf'^\s*"{re.escape(cat)}":\s*[\[(]')
            start_idx = next(i for i, l in enumerate(lines) if start_pat.match(l))
            close_pat = re.compile(r"^\s{4}\]\)?,\s*$")
            end_idx = next(i for i in range(start_idx + 1, len(lines)) if close_pat.match(lines[i]))
            insertion = "".join(tups)
            lines[end_idx:end_idx] = [insertion]
        with open(path, "w", encoding="utf-8") as f:
            f.writelines(lines)
        print(f"Updated {path}: inserted into {list(cats.keys())}")


if __name__ == "__main__":
    entries = load_entries()
    print(f"Loaded {len(entries)} entries")
    tuples_by_cat = build_tuples(entries)
    for cat, tups in sorted(tuples_by_cat.items()):
        print(cat, len(tups))
    insert_into_scripts(tuples_by_cat)
