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


def detect_background(image):
    """Reads the background colour off the image's own border.

    Generated backgrounds are never the exact hex that was asked for, and
    they are not even uniform: the six mascot images came back ranging from
    #F002DC to #F906EE, drifting by up to 28 within a single image. A fixed
    key colour leaves magenta specks behind on the ones that drifted
    furthest, so each image reports its own.

    The median rather than the mean, because a paw or an ear touching the
    border would drag an average toward the artwork and pull the key colour
    away from the background it is meant to remove.
    """
    image = image.convert("RGB")
    width, height = image.size
    step = max(1, min(width, height) // 128)

    samples = []
    for x in range(0, width, step):
        samples.append(image.getpixel((x, 1)))
        samples.append(image.getpixel((x, height - 2)))
    for y in range(0, height, step):
        samples.append(image.getpixel((1, y)))
        samples.append(image.getpixel((width - 2, y)))

    channels = [sorted(c[i] for c in samples) for i in range(3)]
    return tuple(channel[len(channel) // 2] for channel in channels)


def key_out(image, bg, tolerance):
    """Removes `bg`, recovering the true colour of every edge pixel.

    Lowering alpha on edge pixels is not enough on its own, and getting
    that wrong is subtle. An antialiased outline pixel is a *mixture* of
    artwork and background, so making it half-transparent while keeping its
    mixed RGB leaves the background's colour in it. Against white nobody
    notices; against a dark screen it reads as a coloured halo tracing the
    character. A first version of this script did exactly that and left
    266-536 magenta pixels around each mood.

    So each edge pixel is unmixed instead. The observed colour is
    `C = a*F + (1-a)*B` for foreground F over background B, which gives
    `F = (C - (1-a)*B) / a` — the artwork's own colour, with the magenta
    taken back out.
    """
    image = image.convert("RGBA")
    pixels = image.load()
    width, height = image.size
    br, bg_, bb = bg

    # Below `tolerance` the pixel is background; above `soft` it is
    # artwork; between the two it is a mixture to be unmixed.
    soft = tolerance * 2
    span = soft - tolerance

    for y in range(height):
        for x in range(width):
            r, g, b, a = pixels[x, y]
            distance = abs(r - br) + abs(g - bg_) + abs(b - bb)

            if distance <= tolerance:
                pixels[x, y] = (0, 0, 0, 0)
                continue
            if distance >= soft:
                continue

            alpha = (distance - tolerance) / span
            # Below this the division blows tiny rounding errors up into
            # wild colours, and the pixel is nearly invisible anyway.
            if alpha < 0.08:
                pixels[x, y] = (0, 0, 0, 0)
                continue

            unmixed = []
            for channel, back in ((r, br), (g, bg_), (b, bb)):
                value = (channel - (1 - alpha) * back) / alpha
                unmixed.append(int(max(0, min(255, value))))
            pixels[x, y] = (unmixed[0], unmixed[1], unmixed[2],
                            int(a * alpha))
    return image


def keep_main_subject(image, keep_ratio=0.05):
    """Drops stray islands, keeping the character and anything sizeable.

    Generators like to scatter decorations — the mascot set came back with
    little violet sparkles floating in the background, in a colour close
    enough to the artwork to survive keying. They do two kinds of damage:
    they show as debris beside the mascot, and because they sit far from
    the character they inflate the bounding box, so trimming shrinks the
    character to make room for a speck in the corner.

    Anything at least `keep_ratio` of the largest region survives, rather
    than only the single biggest, so a genuinely detached piece of artwork
    is not thrown away with the specks.
    """
    image = image.convert("RGBA")
    width, height = image.size
    alpha = image.split()[3].load()

    labels = [0] * (width * height)
    sizes = [0]

    for start in range(width * height):
        if labels[start] or alpha[start % width, start // width] <= 24:
            continue
        label = len(sizes)
        stack = [start]
        labels[start] = label
        count = 0
        while stack:
            index = stack.pop()
            count += 1
            x, y = index % width, index // width
            for nx, ny in ((x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)):
                if 0 <= nx < width and 0 <= ny < height:
                    neighbour = ny * width + nx
                    if not labels[neighbour] and alpha[nx, ny] > 24:
                        labels[neighbour] = label
                        stack.append(neighbour)
        sizes.append(count)

    if len(sizes) <= 1:
        return image

    threshold = max(sizes) * keep_ratio
    doomed = {i for i, size in enumerate(sizes) if i and size < threshold}
    if not doomed:
        return image

    pixels = image.load()
    for index, label in enumerate(labels):
        if label in doomed:
            pixels[index % width, index // width] = (0, 0, 0, 0)
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
        mood = args.mood or os.path.splitext(os.path.basename(path))[0].lower()
        if mood not in MOODS:
            sys.exit(
                'unknown mood "%s" — expected one of: %s'
                % (mood, ", ".join(sorted(MOODS)))
            )

        source = Image.open(path)
        bg = fixed_bg or detect_background(source)
        image = trim_and_fit(
            keep_main_subject(key_out(source, bg, args.tolerance))
        )
        out = os.path.join(OUT_DIR, "%s.png" % mood)
        image.save(out)

        # A character that survives keying as almost nothing means the
        # background colour was wrong — better to say so than to write a
        # near-empty file the app will silently render as a blank mascot.
        opaque = sum(1 for p in image.getdata() if p[3] > 200)
        share = opaque / (TARGET * TARGET)
        note = "  <-- suspiciously empty, wrong --bg?" if share < 0.05 else ""
        print(
            "[ok] %-9s bg=#%02X%02X%02X -> %s  (%.0f%% opaque)%s"
            % (mood, bg[0], bg[1], bg[2], out, share * 100, note)
        )


if __name__ == "__main__":
    main()
