"""
prepare_premium_icons.py

Turns the raw generated Premium-redesign icon badges into the
transparent PNGs the app expects at `assets/premium_icons/{name}.png`.

Same magenta-keying technique as `prepare_mascot.py` (see that file's
own doc comment for the full reasoning) — this script just points it at
a different, fixed set of names instead of the mascot's mood enum, since
these six images aren't mascot art at all: 4 feature badges (skin,
kanji, kaiwa, no-ads) and 2 plan chests (free, premium) for the redesigned
Premium screen.

Cara pakai:
    python scripts/prepare_premium_icons.py "C:/Teisou asset/premium_icons/"*.png
    python scripts/prepare_premium_icons.py raw/icon_skin.png icon_skin
"""

import argparse
import os
import sys

try:
    from PIL import Image
except ImportError:
    sys.exit("Pillow is required: python -m pip install Pillow")

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from prepare_mascot import detect_background, key_out, keep_main_subject, trim_and_fit  # noqa: E402

ICON_NAMES = {
    "icon_skin",
    "icon_kanji",
    "icon_kaiwa",
    "icon_noads",
    "chest_free",
    "chest_premium",
}

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT_DIR = os.path.join(REPO, "assets", "premium_icons")

# These render small (badge-sized, ~56-96dp) — 512 is the same target
# `prepare_mascot.py` uses, kept for consistency rather than shaved down;
# a single flat PNG at this size costs nothing worth optimising for.
TARGET = 512


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("inputs", nargs="+", help="raw generated image(s)")
    parser.add_argument(
        "name", nargs="?", help="icon name; omit to take it from each filename"
    )
    parser.add_argument(
        "--bg",
        default="auto",
        help="background hex, or 'auto' to read it off each image's border",
    )
    parser.add_argument("--tolerance", type=int, default=90)
    args = parser.parse_args()

    fixed_bg = None
    if args.bg != "auto":
        fixed_bg = tuple(int(args.bg[i:i + 2], 16) for i in (0, 2, 4))
    os.makedirs(OUT_DIR, exist_ok=True)

    for path in args.inputs:
        name = args.name or os.path.splitext(os.path.basename(path))[0].lower()
        if name not in ICON_NAMES:
            sys.exit(
                'unknown icon "%s" — expected one of: %s'
                % (name, ", ".join(sorted(ICON_NAMES)))
            )

        source = Image.open(path)
        bg = fixed_bg or detect_background(source)
        # `trim_and_fit` is reused straight from `prepare_mascot.py`; it
        # fits to that module's own `TARGET` (512), which happens to
        # match this file's [TARGET] too, so no adjustment is needed.
        image = trim_and_fit(
            keep_main_subject(key_out(source, bg, args.tolerance)),
        )
        out = os.path.join(OUT_DIR, "%s.png" % name)
        image.save(out)

        opaque = sum(1 for p in image.getdata() if p[3] > 200)
        share = opaque / (image.width * image.height)
        note = "  <-- suspiciously empty, wrong --bg?" if share < 0.05 else ""
        print(
            "[ok] %-14s bg=#%02X%02X%02X -> %s  (%.0f%% opaque)%s"
            % (name, bg[0], bg[1], bg[2], out, share * 100, note)
        )


if __name__ == "__main__":
    main()
