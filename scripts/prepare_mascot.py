"""
prepare_mascot.py

Turns raw generated mascot images into the transparent PNGs
`MascotWidget` expects at `assets/mascot/{mood}.png`.

**Why this exists.** Image generators mostly cannot emit a real alpha
channel. Ask one for a transparent background and it will usually *draw*
the grey checkerboard that represents transparency, as pixels, so the file
looks right in a preview and ships a checkerboard into the app. Gemini
did exactly that on the first attempt here.

So the reliable route is the opposite: generate the character on a flat,
saturated colour that appears nowhere in the artwork, and cut that colour
out afterwards — which is a solved problem, unlike asking a model to
produce alpha. Magenta is the default because the mascot is a white cat
on a pastel palette, so nothing in the art can be mistaken for it.

Cara pakai:
    python scripts/prepare_mascot.py raw/happy.png happy
    python scripts/prepare_mascot.py raw/*.png            # nama dari nama berkas

Optional: --bg RRGGBB to key a different colour, --tolerance N to widen
the match on a background that generated unevenly.
"""

import argparse
import os
import sys

try:
    from PIL import Image
except ImportError:
    sys.exit("Pillow is required: python -m pip install Pillow")

MOODS = {"happy", "excited", "sleepy", "proud", "sad", "cheering"}

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT_DIR = os.path.join(REPO, "assets", "mascot")

# The mascot is drawn at up to 140dp and screens run to 3x, so 512 leaves
# headroom without carrying a needlessly large bitmap into the APK.
TARGET = 512


def key_out(image, bg, tolerance):
    """Makes every pixel near `bg` transparent, and softens the edge.

    A hard threshold alone leaves a fringe of background colour on the
    antialiased outline, which reads as a coloured halo once the art sits
    on a dark background — the exact failure the dark-mode audit was about.
    So pixels near the boundary get partial alpha instead of a binary
    keep/drop.
    """
    image = image.convert("RGBA")
    pixels = image.load()
    width, height = image.size
    br, bg_, bb = bg

    # Beyond this the pixel is certainly artwork; below `tolerance` it is
    # certainly background; between the two it is an antialiased edge.
    soft = tolerance * 2

    for y in range(height):
        for x in range(width):
            r, g, b, a = pixels[x, y]
            distance = abs(r - br) + abs(g - bg_) + abs(b - bb)
            if distance <= tolerance:
                pixels[x, y] = (r, g, b, 0)
            elif distance < soft:
                fade = (distance - tolerance) / (soft - tolerance)
                pixels[x, y] = (r, g, b, int(a * fade))
    return image


def trim_and_fit(image):
    """Centres the character in a square canvas at [TARGET].

    Generated framing is never consistent, and the widget scales whatever
    it is given — so without this, one mood arrives noticeably larger than
    the next and the mascot appears to change size as its mood changes.
    Trimming to the actual artwork and re-centring makes every mood match.
    """
    bounds = image.getbbox()
    if bounds:
        image = image.crop(bounds)

    # Fit inside 85% of the canvas, leaving the margin the widget's circular
    # slot needs so the character never touches the edge.
    inner = int(TARGET * 0.85)
    image.thumbnail((inner, inner), Image.LANCZOS)

    canvas = Image.new("RGBA", (TARGET, TARGET), (0, 0, 0, 0))
    canvas.paste(
        image,
        ((TARGET - image.width) // 2, (TARGET - image.height) // 2),
    )
    return canvas


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("inputs", nargs="+", help="raw generated image(s)")
    parser.add_argument(
        "mood",
        nargs="?",
        help="mood name; omit to take it from each filename",
    )
    parser.add_argument("--bg", default="FF00FF", help="background hex to key out")
    parser.add_argument("--tolerance", type=int, default=90)
    args = parser.parse_args()

    bg = tuple(int(args.bg[i:i + 2], 16) for i in (0, 2, 4))
    os.makedirs(OUT_DIR, exist_ok=True)

    for path in args.inputs:
        mood = args.mood or os.path.splitext(os.path.basename(path))[0].lower()
        if mood not in MOODS:
            sys.exit(
                'unknown mood "%s" — expected one of: %s'
                % (mood, ", ".join(sorted(MOODS)))
            )

        image = trim_and_fit(key_out(Image.open(path), bg, args.tolerance))
        out = os.path.join(OUT_DIR, "%s.png" % mood)
        image.save(out)

        # A character that survives keying as almost nothing means the
        # background colour was wrong — better to say so than to write a
        # near-empty file the app will silently render as a blank mascot.
        opaque = sum(1 for p in image.getdata() if p[3] > 200)
        share = opaque / (TARGET * TARGET)
        note = "  <-- suspiciously empty, wrong --bg?" if share < 0.05 else ""
        print("[ok] %-9s -> %s  (%.0f%% opaque)%s" % (mood, out, share * 100, note))


if __name__ == "__main__":
    main()
