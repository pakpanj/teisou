"""Generates the monochrome Android status-bar notification icon for
non-chat notifications (ic_notification_app.png) at every required
density — a flat white silhouette of the app's own mascot, derived from
its alpha channel, on transparent.

**Why this exists, and why it's separate from ic_notification.png.** That
one is a generic chat-bubble shape, used for chat/clan-message pushes —
confirmed fine by the user for that specific case. Anything else (system
announcements, and whatever future feature writes to `users/{uid}/
notifications` next) should read as *this app's own* notification, not a
generic bubble — same reasoning `generate_app_icon.py` already used for
the launcher icon: the mascot IS the app's visual identity, so silhouetting
it is more "our app" than any generic bell/star glyph would be.

Derived from `happy.png`, the same mood `generate_app_icon.py` defaults to
for the launcher icon, so both "this app's" icons draw from the same pose.
Everywhere the mascot's alpha channel exceeds the threshold becomes solid
white; everywhere else stays transparent — Android force-flattens color
anyway, so thresholding the source art directly (rather than trying to
preserve any shading) is the honest way to get a clean status-bar glyph
instead of a muddy one.
"""

import os

from PIL import Image

SIZES = {
    "mdpi": 24,
    "hdpi": 36,
    "xhdpi": 48,
    "xxhdpi": 72,
    "xxxhdpi": 96,
}

REPO_ROOT = r"C:\Users\LENOVO\teisou"
SOURCE = os.path.join(REPO_ROOT, "assets", "mascot", "happy.png")
ALPHA_THRESHOLD = 60

mascot = Image.open(SOURCE).convert("RGBA")
alpha = mascot.split()[3]

# Silhouette at source resolution: white wherever the mascot has real
# coverage, fully transparent elsewhere.
silhouette = Image.new("RGBA", mascot.size, (0, 0, 0, 0))
mask = alpha.point(lambda a: 255 if a > ALPHA_THRESHOLD else 0)
white = Image.new("RGBA", mascot.size, (255, 255, 255, 255))
silhouette = Image.composite(white, silhouette, mask)

# Crop to the silhouette's own bounding box so it isn't a tiny shape lost
# in a mostly-empty square once resized down to 24px.
bbox = silhouette.getbbox()
if bbox:
    silhouette = silhouette.crop(bbox)

for density, size in SIZES.items():
    # Leave a small margin, same proportion ic_notification.png uses.
    target = round(size * 0.82)
    scale = target / max(silhouette.width, silhouette.height)
    resized = silhouette.resize(
        (max(1, round(silhouette.width * scale)), max(1, round(silhouette.height * scale))),
        Image.LANCZOS,
    )
    canvas = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    canvas.paste(
        resized,
        ((size - resized.width) // 2, (size - resized.height) // 2),
        resized,
    )

    out_dir = os.path.join(
        REPO_ROOT, "android", "app", "src", "main", "res", f"drawable-{density}"
    )
    os.makedirs(out_dir, exist_ok=True)
    out_path = os.path.join(out_dir, "ic_notification_app.png")
    canvas.save(out_path)
    print(f"{density}: {out_path} ({size}x{size})")
