"""
prepare_icons.py

Same magenta-key + trim pipeline as `prepare_mascot.py`, retargeted for the
small icon set in `scripts/icon_asset_prompts.md` — square icon glyphs
that replace the plain-emoji badges on Home's module cards and the XP/
Level card, output to `assets/icons/` instead of `assets/mascot/`.

Deliberately a separate script rather than a shared one: `prepare_mascot.py`
validates its `mood` argument against the `MascotMood` Dart enum, which
has nothing to do with this icon set, and TARGET here is smaller (icons
render at ~44-52dp, not the mascot's up to 140dp).

Cara pakai:
    python scripts/prepare_icons.py "C:/Teisou asset/home_icon/icon_kosakata.png" icon_kosakata
    python scripts/prepare_icons.py "C:/Teisou asset/home_icon/"*.png   # nama dari nama berkas
"""

import argparse
import os
import sys

try:
    from PIL import Image
except ImportError:
    sys.exit("Pillow is required: python -m pip install Pillow")

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT_DIR = os.path.join(REPO, "assets", "icons")

# Icons render at up to ~52dp in the app; 256 leaves headroom for 3x/4x
# screens without carrying a needlessly large bitmap into the APK.
TARGET = 256


def detect_background(image):
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
    image = image.convert("RGBA")
    pixels = image.load()
    width, height = image.size
    br, bg_, bb = bg

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
    bounds = image.getbbox()
    if bounds:
        image = image.crop(bounds)

    inner = int(TARGET * 0.96)
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
        "--name",
        help="output file name (no extension) — only valid with a single input; "
        "omit to take it from each filename",
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

        source = Image.open(path)
        bg = fixed_bg or detect_background(source)
        image = trim_and_fit(
            keep_main_subject(key_out(source, bg, args.tolerance))
        )
        out = os.path.join(OUT_DIR, "%s.png" % name)
        image.save(out)

        opaque = sum(1 for p in image.getdata() if p[3] > 200)
        share = opaque / (TARGET * TARGET)
        note = "  <-- suspiciously empty, wrong --bg?" if share < 0.05 else ""
        print(
            "[ok] %-28s bg=#%02X%02X%02X -> %s  (%.0f%% opaque)%s"
            % (name, bg[0], bg[1], bg[2], out, share * 100, note)
        )


if __name__ == "__main__":
    main()
