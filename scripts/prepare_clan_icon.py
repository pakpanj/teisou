"""
prepare_clan_icon.py

Turns a raw generated clan-icon image into the PNG `ClanIconArt` expects
at `assets/clan_icons/{id}.png`.

**Same magenta-key approach as `prepare_mascot.py`, for the same reason**:
image generators mostly cannot emit a real alpha channel — ask for a
transparent background and most will *draw* the grey checkerboard as
pixels instead, which looks right in a preview and ships a checkerboard
into the app. So every prompt in `scripts/clan_icon_prompts.md` asks for a
flat magenta `#FF00DC` background instead, keyed out here afterward. The
background-detection and edge-unmixing logic below is a direct copy of
`prepare_mascot.py`'s own (median-of-border-pixels detection, so a
generator that drifts the requested hex still keys out cleanly; alpha
unmixing on edge pixels, not just a hard cutoff, so antialiased edges don't
carry a magenta-tinted halo into the app) — read that script's own doc
comments for the full reasoning if this ever needs changing.

**Simpler than `prepare_mascot.py` in one way**: that script also has to
keep a character's height consistent across a whole set of separately
generated poses. A clan icon is a single self-contained badge design per
image, not a pose in a series, so this only trims to the artwork's own
bounding box and centers it in a square canvas — no cross-image height
normalization needed.

Cara pakai:
    python scripts/prepare_clan_icon.py raw/crest_shield.png crest_shield
    python scripts/prepare_clan_icon.py raw/*.png              # nama dari nama berkas

Optional: --bg RRGGBB to key a different colour, --tolerance N to widen
the match on a background that generated unevenly.
"""

import argparse
import os
import re
import sys

try:
    from PIL import Image
except ImportError:
    sys.exit("Pillow is required: python -m pip install Pillow")

ICON_LIST = os.path.join(
    os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
    "lib", "core", "constants", "clan_icons.dart",
)


def known_icon_ids():
    """Reads preset ids out of `ClanIconPresets.all` — not a hand-kept
    copy, for the same reason `prepare_mascot.py`'s `known_moods()` reads
    the Dart enum directly rather than duplicating it."""
    source = open(ICON_LIST, encoding="utf-8").read()
    return set(re.findall(r"id:\s*'([a-z_]+)'", source))


ICON_IDS = known_icon_ids()

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT_DIR = os.path.join(REPO, "assets", "clan_icons")

# Rendered at up to 40dp in the clan header and 32dp in the settings
# picker, on screens up to 3x — 512 leaves headroom without carrying a
# needlessly large bitmap into the APK, same target size as avatars/mascot.
TARGET = 512
MARGIN = 0.06  # fraction of TARGET left empty on each side


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
            pixels[x, y] = (unmixed[0], unmixed[1], unmixed[2], int(a * alpha))
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
            x, y = index % width, index // width
            r, g, b, _ = pixels[x, y]
            pixels[x, y] = (r, g, b, 0)
    return image


def center_and_pad(image, target, margin):
    bbox = image.getbbox()
    if bbox is None:
        return image.resize((target, target), Image.LANCZOS)
    cropped = image.crop(bbox)

    available = round(target * (1 - 2 * margin))
    scale = available / max(cropped.width, cropped.height)
    resized = cropped.resize(
        (max(1, round(cropped.width * scale)), max(1, round(cropped.height * scale))),
        Image.LANCZOS,
    )

    canvas = Image.new("RGBA", (target, target), (0, 0, 0, 0))
    canvas.paste(
        resized,
        ((target - resized.width) // 2, (target - resized.height) // 2),
        resized,
    )
    return canvas


def process(path, icon_id, bg_hex, tolerance):
    if icon_id not in ICON_IDS:
        sys.exit(
            "'%s' is not a preset id in ClanIconPresets.all (%s)"
            % (icon_id, ICON_LIST)
        )

    image = Image.open(path)
    bg = tuple(int(bg_hex[i:i + 2], 16) for i in (0, 2, 4)) if bg_hex else detect_background(image)
    keyed = key_out(image, bg, tolerance)
    cleaned = keep_main_subject(keyed)
    final = center_and_pad(cleaned, TARGET, MARGIN)

    opaque = sum(1 for a in final.split()[3].getdata() if a > 200)
    ratio = opaque / (TARGET * TARGET)
    if ratio < 0.05:
        print(
            "  warning: only %.1f%% of the canvas is solid — background "
            "colour was probably misdetected, not that the art is bad" % (ratio * 100)
        )

    os.makedirs(OUT_DIR, exist_ok=True)
    out_path = os.path.join(OUT_DIR, "%s.png" % icon_id)
    final.save(out_path)
    print("%s -> %s (bg=%02x%02x%02x)" % (path, out_path, *bg))


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("images", nargs="+")
    parser.add_argument("icon_id", nargs="?", help="only valid with a single image")
    parser.add_argument("--bg", default=None, help="RRGGBB, overrides auto-detection")
    parser.add_argument("--tolerance", type=int, default=40)
    args = parser.parse_args()

    if args.icon_id:
        if len(args.images) != 1:
            sys.exit("an explicit icon_id only works with exactly one image")
        process(args.images[0], args.icon_id, args.bg, args.tolerance)
        return

    for path in args.images:
        icon_id = os.path.splitext(os.path.basename(path))[0]
        process(path, icon_id, args.bg, args.tolerance)


if __name__ == "__main__":
    main()
