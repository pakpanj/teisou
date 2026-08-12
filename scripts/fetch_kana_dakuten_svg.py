"""Fetch KanjiVG stroke-order SVGs for the new dakuten/handakuten kana
(が/ざ/だ/ば/ぱ rows, both scripts — 50 characters) added alongside the
tenten/maru/youon expansion in generate_kana_data.py.

KanjiVG (https://github.com/KanjiVG/kanjivg) is CC BY-SA licensed — same
source already used for both the base 46+46 kana and the full kanji
dataset; see the attribution note on the About/Settings screen.

Youon (きゃ/しゃ/etc.) needs no fetch here — generate_kana_data.py points
those at their base consonant's already-bundled SVG instead of a fresh
per-combination file (see SVG_ASSET_OVERRIDE there), since a youon glyph
is two Unicode codepoints and KanjiVG has no single combined-stroke file
for it anyway.

Re-run after regenerating kana_data.json if any new single-codepoint kana
is ever added — it only fetches whatever `assets/svg/{type}/{romaji}.svg`
is missing on disk, so it's always safe to re-run.
"""

import io
import json
import ssl
import sys
import urllib.request
import zipfile
from pathlib import Path

sys.stdout.reconfigure(encoding="utf-8")

ROOT = Path(__file__).resolve().parent.parent
DATA_PATH = ROOT / "assets" / "data" / "kana_data.json"
SVG_ROOT = ROOT / "assets" / "svg"
ZIP_URL = "https://github.com/KanjiVG/kanjivg/archive/refs/heads/master.zip"
ZIP_ENTRY_PREFIX = "kanjivg-master/kanji/"


def codepoint_hex(char: str) -> str:
    return f"{ord(char):05x}"


def _ssl_context() -> ssl.SSLContext:
    try:
        import certifi

        return ssl.create_default_context(cafile=certifi.where())
    except ImportError:
        return ssl.create_default_context()


def download_zip() -> bytes:
    print(f"Downloading {ZIP_URL} ...")
    req = urllib.request.Request(ZIP_URL, headers={"User-Agent": "teisou-kana-fetch"})
    with urllib.request.urlopen(req, timeout=120, context=_ssl_context()) as resp:
        data = resp.read()
    print(f"Downloaded {len(data) / 1_000_000:.1f} MB")
    return data


def main():
    entries = json.loads(DATA_PATH.read_text(encoding="utf-8"))

    needed = []
    for e in entries:
        # Youon (character is 2 codepoints, e.g. きゃ) always resolves its
        # svgAsset to a base consonant's file via SVG_ASSET_OVERRIDE, never
        # to a fresh fetch of its own — skip it here so a youon row whose
        # override target (e.g. き) hasn't been fetched *yet* in this same
        # run doesn't get misread as "needs its own KanjiVG lookup" (a
        # 2-character string has no single codepoint to look up at all).
        if len(e["character"]) != 1:
            continue
        dest = ROOT / e["svgAsset"]
        if dest.exists():
            continue
        needed.append((e["character"], e["type"], dest))

    if not needed:
        print("Nothing missing — every kana already has its SVG.")
        return

    print(f"{len(needed)} kana missing an SVG:")
    for char, kana_type, dest in needed:
        print(f"  {kana_type}/{char} -> {dest.relative_to(ROOT)}")

    zip_bytes = download_zip()
    copied = 0
    missing = []
    with zipfile.ZipFile(io.BytesIO(zip_bytes)) as zf:
        names = set(zf.namelist())
        for char, kana_type, dest in needed:
            hex_code = codepoint_hex(char)
            entry = f"{ZIP_ENTRY_PREFIX}{hex_code}.svg"
            if entry not in names:
                missing.append(f"{kana_type}/{char} (U+{hex_code})")
                continue
            dest.parent.mkdir(parents=True, exist_ok=True)
            dest.write_bytes(zf.read(entry))
            copied += 1

    print(f"\nCopied {copied}/{len(needed)} SVGs")
    if missing:
        print(f"Missing {len(missing)}:")
        for m in missing:
            print(f"  {m}")
        sys.exit(1)


if __name__ == "__main__":
    main()
