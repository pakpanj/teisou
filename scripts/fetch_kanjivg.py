"""Fetch KanjiVG stroke-order SVGs for the Batch 7 N5+N4 character set.

KanjiVG (https://github.com/KanjiVG/kanjivg) is CC BY-SA licensed — see the
attribution note added to the app's About/Settings screen alongside this.

Downloads the repo as a single zip (much faster and more reliable than one
HTTP request per character for ~240 files) and extracts only the SVGs this
app actually needs into assets/kanjivg/{unicode_hex}.svg, named to match
KanjiVG's own convention so KanjiEntry.svgAsset paths need no translation
layer.

Re-run any time kanji_char_lists.py's N5_CHARACTERS/N4_CHARACTERS grows.
"""

import io
import ssl
import sys
import urllib.request
import zipfile
from pathlib import Path

from kanji_char_lists import N4_CHARACTERS, N5_CHARACTERS

ROOT = Path(__file__).resolve().parent.parent
DEST_DIR = ROOT / "assets" / "kanjivg"
ZIP_URL = "https://github.com/KanjiVG/kanjivg/archive/refs/heads/master.zip"
ZIP_ENTRY_PREFIX = "kanjivg-master/kanji/"


def codepoint_hex(char: str) -> str:
    return f"{ord(char):05x}"


def _ssl_context() -> ssl.SSLContext:
    # This Python distribution doesn't wire its default SSL context up to a
    # CA bundle, so urlopen fails cert verification even for a normal
    # GitHub download. Use certifi's bundle explicitly rather than
    # disabling verification.
    try:
        import certifi

        return ssl.create_default_context(cafile=certifi.where())
    except ImportError:
        return ssl.create_default_context()


def download_zip() -> bytes:
    print(f"Downloading {ZIP_URL} ...")
    req = urllib.request.Request(ZIP_URL, headers={"User-Agent": "teisou-kanji-fetch"})
    with urllib.request.urlopen(req, timeout=120, context=_ssl_context()) as resp:
        data = resp.read()
    print(f"Downloaded {len(data) / 1_000_000:.1f} MB")
    return data


def extract_needed(zip_bytes: bytes, characters: list[str]) -> tuple[int, list[str]]:
    DEST_DIR.mkdir(parents=True, exist_ok=True)
    copied = 0
    missing = []

    with zipfile.ZipFile(io.BytesIO(zip_bytes)) as zf:
        names = set(zf.namelist())
        for char in characters:
            hex_code = codepoint_hex(char)
            entry = f"{ZIP_ENTRY_PREFIX}{hex_code}.svg"
            dest = DEST_DIR / f"{hex_code}.svg"
            if entry not in names:
                missing.append(f"{char} (U+{hex_code})")
                continue
            dest.write_bytes(zf.read(entry))
            copied += 1

    return copied, missing


def main():
    characters = sorted(set(N5_CHARACTERS) | set(N4_CHARACTERS))
    print(f"Fetching SVGs for {len(characters)} unique kanji (N5+N4)...")

    zip_bytes = download_zip()
    copied, missing = extract_needed(zip_bytes, characters)

    print(f"\nCopied {copied}/{len(characters)} SVGs to {DEST_DIR}")
    if missing:
        print(f"Missing {len(missing)}:")
        for m in missing:
            print(f"  {m}")
        sys.exit(1)


if __name__ == "__main__":
    main()
