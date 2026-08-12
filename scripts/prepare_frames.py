"""
prepare_frames.py

Same magenta-key pipeline as `prepare_mascot.py`/`prepare_icons.py`, but for
the reusable module-frame set in `scripts/module_frame_asset_prompts.md`
(bg_module_header, frame_module_title, frame_card_box, frame_mascot_bubble,
frame_level_badge). Deliberately a third script rather than reusing either:
those two force a square TARGET canvas, which is correct for a mascot pose
or an icon glyph but wrong here — several of these frames are meant to
stay non-square (a 900x220 title plaque, a wide card border) and forcing
them onto a square canvas would either crop real content or leave dead
transparent padding on two sides. This script trims to the actual alpha
bounding box and stops there, no re-square, no fixed TARGET.

Cara pakai:
    python scripts/prepare_frames.py "C:/Teisou asset/asset module/frame_card_box.png"
    python scripts/prepare_frames.py "C:/Teisou asset/asset module/"*.png
"""

import os
import sys

try:
    from PIL import Image
except ImportError:
    sys.exit("Pillow is required: python -m pip install Pillow")

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
# Deliberately NOT assets/frames/ — that directory already holds the
# unrelated avatar decoration frames (FramePreset, frame_sakura.png etc.).
OUT_DIR = os.path.join(REPO, "assets", "module_frames")


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


def trim(image, pad=6):
    bounds = image.getbbox()
    if not bounds:
        return image
    left, top, right, bottom = bounds
    left = max(0, left - pad)
    top = max(0, top - pad)
    right = min(image.width, right + pad)
    bottom = min(image.height, bottom + pad)
    return image.crop((left, top, right, bottom))


def main():
    inputs = sys.argv[1:]
    if not inputs:
        sys.exit("usage: prepare_frames.py <input.png> [more.png ...]")

    os.makedirs(OUT_DIR, exist_ok=True)

    for path in inputs:
        name = os.path.splitext(os.path.basename(path))[0].lower()
        source = Image.open(path)
        bg = detect_background(source)
        image = trim(keep_main_subject(key_out(source, bg, 90)))
        out = os.path.join(OUT_DIR, "%s.png" % name)
        image.save(out)

        opaque = sum(1 for p in image.getdata() if p[3] > 200)
        share = opaque / (image.width * image.height)
        note = "  <-- suspiciously empty, wrong bg?" if share < 0.05 else ""
        print(
            "[ok] %-22s bg=#%02X%02X%02X -> %s  %dx%d (%.0f%% opaque)%s"
            % (name, bg[0], bg[1], bg[2], out, image.width, image.height,
               share * 100, note)
        )


if __name__ == "__main__":
    main()
