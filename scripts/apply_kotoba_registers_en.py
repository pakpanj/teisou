# Patches KotobaEntry.registers -> registersEn into every
# assets/data/kotoba/{category}.json file, via template substitution
# (see kotoba_registers_note_en.py's docstring for why a template
# approach is safe here instead of translating 5,046 strings by hand).
#
# Safe to re-run; must be re-run after any generate_kotoba_*.py group
# script regenerates a category file (same standing rule as
# apply_kotoba_meaning_en.py / apply_kotoba_example_translation_en.py).
#
# Usage:
#   python scripts/apply_kotoba_registers_en.py --dry-run   # preview only,
#       writes no files, dumps a sample of before/after pairs to
#       scratch_registers_en_preview.txt
#   python scripts/apply_kotoba_registers_en.py              # writes
#       registersEn into every assets/data/kotoba/{category}.json file

import glob
import json
import sys

from kotoba_registers_note_en import NOTE_EN

SEP = " — "  # " — "


def translate_register_value(value):
    if SEP in value:
        prefix, suffix = value.split(SEP, 1)
        if suffix not in NOTE_EN:
            raise KeyError(f"no English translation for note template: {suffix!r}")
        return f"{prefix}{SEP}{NOTE_EN[suffix]}"
    # Pure "{japanese} ({romaji})" with no Indonesian text at all —
    # already language-neutral, so the English value is identical.
    return value


def main():
    dry_run = "--dry-run" in sys.argv
    total_fields = 0
    translated_fields = 0
    files_touched = 0
    samples = []

    for path in sorted(glob.glob("assets/data/kotoba/*.json")):
        if "_categories" in path:
            continue
        data = json.load(open(path, encoding="utf-8"))
        file_changed = False
        for entry in data:
            regs = entry.get("registers", {})
            if not regs:
                continue
            regs_en = {}
            for key, value in regs.items():
                total_fields += 1
                translated = translate_register_value(value)
                regs_en[key] = translated
                if translated != value:
                    translated_fields += 1
                    if len(samples) < 40:
                        samples.append((path, entry["word"], key, value, translated))
            entry["registersEn"] = regs_en
            file_changed = True
        if file_changed:
            files_touched += 1
            if not dry_run:
                with open(path, "w", encoding="utf-8") as f:
                    json.dump(data, f, ensure_ascii=False, indent=2)

    mode = "dry-run" if dry_run else "ok"
    print(
        f"[{mode}] kotoba registers: {files_touched} category files, "
        f"{total_fields} register fields, {translated_fields} with a "
        f"translated note (rest are language-neutral JP+romaji)"
    )

    if dry_run:
        with open("scratch_registers_en_preview.txt", "w", encoding="utf-8") as f:
            for path, word, key, before, after in samples:
                f.write(f"{path} | {word} | {key}\n")
                f.write(f"  before: {before}\n")
                f.write(f"  after:  {after}\n\n")


if __name__ == "__main__":
    main()
