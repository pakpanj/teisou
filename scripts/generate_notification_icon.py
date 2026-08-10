"""Generates the monochrome Android status-bar notification icon
(ic_notification.png) at every required density — a plain white chat
bubble with a small tail on transparent, following Android's own
guideline that a status-bar icon must be a flat white silhouette
(anything with color/gradient gets force-flattened by the system anyway,
often ugly). The app's full-color launcher icon was being reused for
this before, which is exactly what that guideline warns against.
"""

import os

from PIL import Image, ImageDraw

SIZES = {
    "mdpi": 24,
    "hdpi": 36,
    "xhdpi": 48,
    "xxhdpi": 72,
    "xxxhdpi": 96,
}

REPO_ROOT = r"C:\Users\LENOVO\teisou"

for density, size in SIZES.items():
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    margin = size * 0.14
    left = margin
    top = margin
    right = size - margin
    bubble_h = (right - left) * 0.72
    bottom = top + bubble_h
    radius = bubble_h * 0.32

    draw.rounded_rectangle(
        [left, top, right, bottom], radius=radius, fill=(255, 255, 255, 255)
    )

    tail_w = size * 0.17
    tail_h = size * 0.16
    tail_x = left + (right - left) * 0.18
    draw.polygon(
        [
            (tail_x, bottom - size * 0.02),
            (tail_x + tail_w, bottom - size * 0.02),
            (tail_x, bottom + tail_h),
        ],
        fill=(255, 255, 255, 255),
    )

    out_dir = os.path.join(
        REPO_ROOT, "android", "app", "src", "main", "res", f"drawable-{density}"
    )
    os.makedirs(out_dir, exist_ok=True)
    out_path = os.path.join(out_dir, "ic_notification.png")
    img.save(out_path)
    print(f"{density}: {out_path} ({size}x{size})")
