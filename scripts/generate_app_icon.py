"""
generate_app_icon.py

Builds the launcher icon for both platforms from the mascot artwork.

**Why this exists.** The project shipped with Flutter's own blue logo as
its launcher icon — the default from `flutter create`, untouched since the
day the project was made. Play accepts it; Apple has rejected apps for
placeholder assets; and either way it is the first thing anyone sees.

Deliberately a script rather than a checked-in set of PNGs, and rather
than the `flutter_launcher_icons` package. Both platforms need the same
character at fifteen-odd sizes, and derived files that nobody can
regenerate are the ones that go stale — the day the mascot art changes,
this is one command instead of an afternoon in an image editor. Adding a
package for it would also mean a generation step that has to run on the
build machine.

Cara pakai:
    python scripts/generate_app_icon.py
    python scripts/generate_app_icon.py --mood cheering
"""

import argparse
import os
import sys

try:
    from PIL import Image, ImageDraw, ImageFilter
except ImportError:
    sys.exit("Pillow is required: python -m pip install Pillow")

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

# AppColors.primaryCoral. Read off the palette rather than eyeballed, so
# the icon and the app's own chrome cannot drift apart.
CORAL = (0xF4, 0x66, 0x7A)
CORAL_DEEP = (0xD9, 0x4A, 0x62)

# Android launcher sizes, and the 108dp adaptive-icon canvas beside them.
ANDROID = {
    "mdpi": (48, 108),
    "hdpi": (72, 162),
    "xhdpi": (96, 216),
    "xxhdpi": (144, 324),
    "xxxhdpi": (192, 432),
}

# Exactly the filenames Runner's AppIcon.appiconset already lists. Writing
# a set it does not expect leaves Xcode complaining about missing images
# while the extra files sit there unused.
IOS = {
    "Icon-App-20x20@1x.png": 20,
    "Icon-App-20x20@2x.png": 40,
    "Icon-App-20x20@3x.png": 60,
    "Icon-App-29x29@1x.png": 29,
    "Icon-App-29x29@2x.png": 58,
    "Icon-App-29x29@3x.png": 87,
    "Icon-App-40x40@1x.png": 40,
    "Icon-App-40x40@2x.png": 80,
    "Icon-App-40x40@3x.png": 120,
    "Icon-App-60x60@2x.png": 120,
    "Icon-App-60x60@3x.png": 180,
    "Icon-App-76x76@1x.png": 76,
    "Icon-App-76x76@2x.png": 152,
    "Icon-App-83.5x83.5@2x.png": 167,
    "Icon-App-1024x1024@1x.png": 1024,
}


def background(size):
    """A soft vertical wash rather than a flat fill.

    Flat colour reads as unfinished next to the rounded, shaded style of
    everything else in the app; a gentle gradient costs nothing and looks
    deliberate at 48px as well as at 1024px.
    """
    canvas = Image.new("RGB", (size, size), CORAL)
    draw = ImageDraw.Draw(canvas)
    for y in range(size):
        blend = y / max(1, size - 1)
        draw.line(
            [(0, y), (size, y)],
            fill=tuple(
                round(CORAL[i] + (CORAL_DEEP[i] - CORAL[i]) * blend)
                for i in range(3)
            ),
        )
    return canvas


def place_mascot(canvas, mascot, coverage, lift=0.0):
    """Centres the character on `canvas` at `coverage` of its width."""
    size = canvas.size[0]
    # resize, not thumbnail. thumbnail only ever shrinks, so a 512px
    # source asked for 820px came back at 512 — the first run of this
    # produced an icon with the cat filling half the frame and a sea of
    # coral around it, which looked like a mistake rather than a design.
    target = max(1, round(size * coverage))
    scale = target / max(mascot.width, mascot.height)
    art = mascot.resize(
        (max(1, round(mascot.width * scale)), max(1, round(mascot.height * scale))),
        Image.LANCZOS,
    )

    # A shadow under the feet, the same trick the in-app mascot uses: it
    # stops the character reading as a sticker pasted on a colour.
    shadow = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    ellipse = ImageDraw.Draw(shadow)
    width = art.width * 0.62
    height = max(2, art.height * 0.07)
    cx = size / 2
    cy = (size + art.height) / 2 - height - size * lift
    ellipse.ellipse(
        [cx - width / 2, cy - height / 2, cx + width / 2, cy + height / 2],
        fill=(80, 40, 60, 70),
    )
    shadow = shadow.filter(ImageFilter.GaussianBlur(max(1, size * 0.012)))
    canvas = Image.alpha_composite(canvas.convert("RGBA"), shadow)

    canvas.paste(
        art,
        ((size - art.width) // 2, (size - art.height) // 2 - round(size * lift)),
        art,
    )
    return canvas


def write(image, path):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    image.save(path)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--mood", default="happy", help="which mascot pose")
    args = parser.parse_args()

    source = os.path.join(REPO, "assets", "mascot", "%s.png" % args.mood)
    if not os.path.exists(source):
        sys.exit("no mascot art at %s" % source)
    mascot = Image.open(source).convert("RGBA")

    # --- Android: the square legacy icon every launcher can draw --------
    for density, (legacy, adaptive) in ANDROID.items():
        icon = place_mascot(background(legacy), mascot, 0.88, lift=0.02)
        write(
            icon.convert("RGB"),
            os.path.join(
                REPO, "android/app/src/main/res/mipmap-%s/ic_launcher.png" % density
            ),
        )

        # --- and the adaptive pair Android 8+ actually uses -------------
        #
        # The launcher crops these to whatever shape the device prefers —
        # circle, squircle, teardrop — and only the middle 66% is
        # guaranteed to survive. Hence the much smaller coverage here: a
        # character sized like the legacy icon would come back with its
        # ears and feet cropped off on a round-icon launcher.
        write(
            background(adaptive).convert("RGB"),
            os.path.join(
                REPO,
                "android/app/src/main/res/mipmap-%s/ic_launcher_background.png"
                % density,
            ),
        )
        foreground = Image.new("RGBA", (adaptive, adaptive), (0, 0, 0, 0))
        foreground = place_mascot(foreground, mascot, 0.62, lift=0.02)
        write(
            foreground,
            os.path.join(
                REPO,
                "android/app/src/main/res/mipmap-%s/ic_launcher_foreground.png"
                % density,
            ),
        )

    # --- iOS: flattened, because the App Store rejects transparency ----
    for filename, size in IOS.items():
        icon = place_mascot(background(size), mascot, 0.90, lift=0.02).convert("RGB")
        write(
            icon,
            os.path.join(
                REPO,
                "ios/Runner/Assets.xcassets/AppIcon.appiconset",
                filename,
            ),
        )

    print("wrote %d Android densities and %d iOS sizes from %s"
          % (len(ANDROID), len(IOS), os.path.basename(source)))


if __name__ == "__main__":
    main()
