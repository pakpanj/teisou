import json
import shutil
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
KANJIVG_DIR = Path(
    r"C:\Users\LENOVO\AppData\Local\Temp\claude\C--Users-LENOVO-teisou"
    r"\4c67f556-e465-4cee-898a-abba726d8b50\scratchpad\kanjivg\kanji"
)
DATA_PATH = ROOT / "assets" / "data" / "kana_data.json"
SVG_ROOT = ROOT / "assets" / "svg"

data = json.loads(DATA_PATH.read_text(encoding="utf-8"))

missing = []
copied = 0

for entry in data:
    char = entry["character"]
    romaji = entry["romaji"]
    kana_type = entry["type"]
    codepoint = ord(char)
    filename = f"{codepoint:05x}.svg"
    src = KANJIVG_DIR / filename
    dest_dir = SVG_ROOT / kana_type
    dest_dir.mkdir(parents=True, exist_ok=True)
    dest = dest_dir / f"{romaji}.svg"

    if not src.exists():
        missing.append((kana_type, romaji, char, filename))
        continue

    shutil.copyfile(src, dest)
    copied += 1

print(f"Copied {copied}/{len(data)} SVGs")
if missing:
    print(f"Missing {len(missing)}:")
    for kana_type, romaji, char, filename in missing:
        print(f"  {kana_type}/{romaji} ({char}) -> {filename}")
