Per-mood mascot art, one PNG per value of MascotMood
(lib/core/widgets/mascot_widget.dart) named {mood}.png.

Deliberately no list of mood names here. This file carried one, it went
stale the moment twelve moods were added, and a stale list is worse than
no list — scripts/prepare_mascot.py made the same mistake and rejected
every new mood until it was changed to read the enum directly. Read the
enum; it is the only copy.

Generated from the prompts in scripts/mascot_prompts.md and keyed with
scripts/prepare_mascot.py, which cuts the flat magenta background those
prompts ask for. Never ask a generator for transparency — it draws the
checkerboard as pixels and ships it.

Until a file exists, MascotWidget falls back to that mood's emoji, so the
set can be filled in one drawing at a time without breaking a screen.
test/mascot_art_test.dart fails on a missing file, on two moods sharing
one image, and on a file left behind by a renamed mood.
