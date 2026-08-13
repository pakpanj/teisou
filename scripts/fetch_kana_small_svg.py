"""Fetch KanjiVG stroke-order SVGs for the six small kana: ゃゅょ ャュョ.

These are the second half of every youon. Until now a youon entry pointed
its `svgAsset` at the base consonant's file and stopped there, so きょ drew
き and the ょ was simply never shown -- the flashcard animated three strokes
where the mora actually has six. See SVG_ASSET_OVERRIDE in
generate_kana_data.py, whose comment recorded the reasoning: KanjiVG has no
single combined-stroke file for a two-codepoint glyph.

That is true and stays true. What it missed is that each half exists on its
own, so the pair can be fetched separately and drawn side by side. This
script fetches the small halves; generate_kana_data.py now emits
`svgAssetSecondary` pointing at them.

KanjiVG (https://github.com/KanjiVG/kanjivg) is CC BY-SA licensed -- the
same source already used for the base kana, the dakuten rows and the whole
kanji dataset; attribution is on the About screen.

Safe to re-run: it only writes files that are missing from disk.
"""

import io
import ssl
import sys
import urllib.request
import zipfile
from pathlib import Path

ZIP_URL = "https://github.com/KanjiVG/kanjivg/archive/refs/heads/master.zip"

# (codepoint, script folder, output name). The output names follow the
# existing romaji convention in assets/svg/{type}/ rather than KanjiVG's
# hex filenames, so every kana asset in the app is named the same way.
WANTED = [
    (0x3083, "hiragana", "small_ya"),
    (0x3085, "hiragana", "small_yu"),
    (0x3087, "hiragana", "small_yo"),
    (0x30E3, "katakana", "small_ya"),
    (0x30E5, "katakana", "small_yu"),
    (0x30E7, "katakana", "small_yo"),
]

ASSET_ROOT = Path(__file__).resolve().parent.parent / "assets" / "svg"


def _ssl_context() -> ssl.SSLContext:
    # Same fallback the sibling fetch scripts use: the Python that ends up
    # on PATH here ships no CA bundle, so a plain default context fails
    # verification against GitHub.
    try:
        import certifi

        return ssl.create_default_context(cafile=certifi.where())
    except ImportError:
        return ssl.create_default_context()


def download_zip() -> bytes:
    print(f"Downloading {ZIP_URL} ...")
    request = urllib.request.Request(
        ZIP_URL, headers={"User-Agent": "teisou-kana-master"}
    )
    with urllib.request.urlopen(request, context=_ssl_context()) as response:
        return response.read()


def main() -> int:
    missing = [w for w in WANTED if not (ASSET_ROOT / w[1] / f"{w[2]}.svg").exists()]
    if not missing:
        print("All six small-kana SVGs already present, nothing to do.")
        return 0

    print(f"{len(missing)} missing, fetching.")
    zip_bytes = download_zip()
    written = 0
    with zipfile.ZipFile(io.BytesIO(zip_bytes)) as archive:
        names = {Path(n).name: n for n in archive.namelist() if n.endswith(".svg")}
        for codepoint, script, out_name in missing:
            source = f"{codepoint:05x}.svg"
            if source not in names:
                print(f"  MISSING in KanjiVG: {source} ({out_name})")
                continue
            target = ASSET_ROOT / script / f"{out_name}.svg"
            target.write_bytes(archive.read(names[source]))
            print(f"  {source} -> {target.relative_to(ASSET_ROOT.parent.parent)}")
            written += 1

    print(f"Wrote {written} file(s).")
    return 0 if written == len(missing) else 1


if __name__ == "__main__":
    sys.exit(main())
