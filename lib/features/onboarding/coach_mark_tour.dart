import 'package:flutter/material.dart';

import '../../core/theme/app_palette.dart';
import '../../core/widgets/mascot_widget.dart';

/// Marks a widget as something a tour can point at.
///
/// Wrap anything worth explaining and give it an id; a step naming that
/// id will find it wherever it has ended up on screen.
class TutorialTarget extends StatefulWidget {
  const TutorialTarget({super.key, required this.id, required this.child});

  final String id;
  final Widget child;

  @override
  State<TutorialTarget> createState() => _TutorialTargetState();
}

class _TutorialTargetState extends State<TutorialTarget> {
  final _key = GlobalKey();

  @override
  void initState() {
    super.initState();
    TutorialAnchors.register(widget.id, _key);
  }

  @override
  void dispose() {
    TutorialAnchors.unregister(widget.id, _key);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      KeyedSubtree(key: _key, child: widget.child);
}

/// Where the tour finds the things it points at.
///
/// **The position is never stored — only the key is.** Every step asks
/// the live widget where it is at the moment it is shown, so a card that
/// moves, a section that is added above it, or a different screen size
/// changes nothing. That is the whole reason this approach is safe to
/// build on a home screen that is still being added to: the old
/// slideshow tutorial was written precisely because a tour holding
/// coordinates goes quietly wrong the first time the layout shifts.
///
/// A step whose anchor is not mounted is skipped rather than drawn
/// empty, so deleting a card breaks nothing.
class TutorialAnchors {
  TutorialAnchors._();

  static final Map<String, GlobalKey> _keys = {};

  static void register(String id, GlobalKey key) => _keys[id] = key;

  /// Only clears the entry if it still belongs to this widget. Two
  /// screens can hold the same id briefly during a page transition, and
  /// the outgoing one must not wipe the incoming one's key.
  static void unregister(String id, GlobalKey key) {
    if (_keys[id] == key) _keys.remove(id);
  }

  static GlobalKey? keyFor(String id) => _keys[id];

  /// Test seam. Nothing in the app calls this.
  @visibleForTesting
  static void clear() => _keys.clear();
}

/// Marks only the first item of a list.
///
/// A tour that wants to say "tap one of these" needs somewhere to point,
/// and every tile registering the same id would leave the anchor pointing
/// at whichever one happened to build last — in a lazy list, usually one
/// off the bottom of the screen.
Widget anchorFirst(int index, String id, Widget child) =>
    anchorWhen(index == 0, id, child);

/// [anchorFirst] for lists whose "first" is not simply index zero — the
/// first row of the first section of a table, say, or the first card that
/// is still locked.
Widget anchorWhen(bool here, String id, Widget child) =>
    here ? TutorialTarget(id: id, child: child) : child;

/// One thing the mascot points at.
class CoachStep {
  const CoachStep({
    required this.anchorId,
    required this.message,
    required this.mood,
  });

  final String anchorId;
  final String message;
  final MascotMood mood;
}

/// The mascot walking through the real screen, one highlight at a time.
///
/// Shown as a route over the screen it describes, so the screen behind
/// is the real one — the highlight is cut out of the dimming layer and
/// the learner sees the actual card they are about to be told about.
class CoachMarkTour extends StatefulWidget {
  const CoachMarkTour({
    super.key,
    required this.steps,
    required this.nextLabel,
    required this.finishLabel,
    required this.skipLabel,
  });

  final List<CoachStep> steps;
  final String nextLabel;
  final String finishLabel;
  final String skipLabel;

  @override
  State<CoachMarkTour> createState() => _CoachMarkTourState();
}

class _CoachMarkTourState extends State<CoachMarkTour> {
  int _index = 0;
  Rect? _spot;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _locate());
  }

  /// Scrolls the current step's target into view, then measures it.
  Future<void> _locate() async {
    while (_index < widget.steps.length) {
      final key = TutorialAnchors.keyFor(widget.steps[_index].anchorId);
      final before = key?.currentContext;
      // `context.mounted`, not this State's — the anchor belongs to
      // another widget, and a loop that has already awaited once may be
      // holding one that has since left the tree.
      if (before == null || !before.mounted) {
        // The card this step described is not on screen — removed,
        // renamed, or behind a tab. Skip rather than dim the screen
        // around nothing.
        _index++;
        continue;
      }

      if (Scrollable.maybeOf(before) != null) {
        await Scrollable.ensureVisible(
          before,
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOut,
          // Not 0.5: centring pushes a card near the top of a long list
          // under the mascot, which then has nowhere to stand.
          alignment: 0.35,
        );
      }
      if (!mounted) return;

      // Asked for again rather than reused. Scrolling can rebuild a
      // lazily-built target, and the context captured before the await
      // may by then belong to nothing — measuring it would give a
      // position for a widget that is no longer there.
      final target = key?.currentContext;
      if (target == null || !target.mounted) {
        _index++;
        continue;
      }

      final box = target.findRenderObject() as RenderBox?;
      if (box == null || !box.hasSize) {
        _index++;
        continue;
      }
      final origin = box.localToGlobal(Offset.zero);
      setState(() {
        _spot = origin & box.size;
        _ready = true;
      });
      return;
    }
    // Nothing left to point at.
    if (mounted) Navigator.of(context).pop();
  }

  void _next() {
    if (_index >= widget.steps.length - 1) {
      Navigator.of(context).pop();
      return;
    }
    setState(() {
      _index++;
      _ready = false;
    });
    _locate();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final media = MediaQuery.of(context);
    final spot = _spot;

    // Before the first measurement there is nothing to cut a hole
    // around. Dimming the whole screen for a frame reads as a flash, so
    // wait it out invisibly.
    if (!_ready || spot == null) {
      return const SizedBox.shrink();
    }

    final step = widget.steps[_index];
    final isLast = _index == widget.steps.length - 1;

    // The mascot stands wherever there is more room. Below a card near
    // the top, above one near the bottom.
    final roomBelow = media.size.height - spot.bottom;
    final below = roomBelow > 360;
    // Whether skip and the highlight would actually overlap, rather than
    // merely both being near the top: a card just below the app bar was
    // close enough to trip a looser check, and moving skip left there put
    // it on the back button instead.
    final skipClashes = spot
        .inflate(8)
        .overlaps(
          Rect.fromLTWH(media.size.width - 130, media.padding.top, 130, 56),
        );

    return Material(
      type: MaterialType.transparency,
      child: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              // Tapping anywhere advances. A child who does not find the
              // button will still tap the screen.
              onTap: _next,
              child: CustomPaint(
                painter: _SpotlightPainter(
                  spot: spot.inflate(8),
                  highlight: palette.primaryCoral,
                ),
              ),
            ),
          ),
          _StepBadge(number: _index + 1, spot: spot, palette: palette),
          Positioned(
            left: 12,
            right: 12,
            top: below ? spot.bottom + 20 : null,
            bottom: below ? null : media.size.height - spot.top + 20,
            // The bubble absorbs taps that land on it, so the
            // tap-anywhere gesture underneath never sees them — a child
            // who taps the mascot's speech instead of the button gets
            // nothing at all. Same handler, opaque so the padding
            // counts too; the button still wins where it is drawn.
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _next,
              child: _MascotSays(
                mood: step.mood,
                message: step.message,
                palette: palette,
                label: isLast ? widget.finishLabel : widget.nextLabel,
                onNext: _next,
              ),
            ),
          ),
          Positioned(
            top: media.padding.top + 8,
            // Out of the way when the thing being pointed at is in the
            // same corner. The quiz icon every module tour ends on sits
            // exactly here, and skip drawn over its highlight hides the
            // one control the step is about.
            left: skipClashes ? 16 : null,
            right: skipClashes ? null : 16,
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                widget.skipLabel,
                style: TextStyle(color: palette.primaryCoral),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Dims everything except the thing being explained.
class _SpotlightPainter extends CustomPainter {
  const _SpotlightPainter({required this.spot, required this.highlight});

  final Rect spot;
  final Color highlight;

  @override
  void paint(Canvas canvas, Size size) {
    final hole = RRect.fromRectAndRadius(spot, const Radius.circular(18));

    // The dim is one layer with the hole cut out of it, not four
    // rectangles around the target. Four rectangles leave hairline seams
    // at the corners on fractional pixel ratios.
    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(Offset.zero & size),
        Path()..addRRect(hole),
      ),
      Paint()..color = Colors.black.withValues(alpha: 0.72),
    );

    _dashedRRect(
      canvas,
      hole,
      Paint()
        ..color = highlight
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
  }

  /// A dashed outline, walked along the rounded rect's own path so the
  /// dashes follow the corners instead of cutting across them.
  void _dashedRRect(Canvas canvas, RRect rrect, Paint paint) {
    const dash = 12.0;
    const gap = 7.0;
    final path = Path()..addRRect(rrect);
    for (final metric in path.computeMetrics()) {
      var at = 0.0;
      while (at < metric.length) {
        final end = (at + dash).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(at, end), paint);
        at = end + gap;
      }
    }
  }

  @override
  bool shouldRepaint(_SpotlightPainter old) =>
      old.spot != spot || old.highlight != highlight;
}

/// The numbered pill on the corner of the highlight.
class _StepBadge extends StatelessWidget {
  const _StepBadge({
    required this.number,
    required this.spot,
    required this.palette,
  });

  final int number;
  final Rect spot;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      // Clamped to the screen: a target flush with the left edge would
      // otherwise put half the badge off it.
      left: (spot.left - 18).clamp(8.0, MediaQuery.of(context).size.width - 56),
      top: spot.top - 18,
      child: Container(
        width: 38,
        height: 38,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: palette.primaryCoral,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
        ),
        child: Text(
          '$number',
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

/// The mascot and what it is saying about the highlighted thing.
class _MascotSays extends StatelessWidget {
  const _MascotSays({
    required this.mood,
    required this.message,
    required this.palette,
    required this.label,
    required this.onNext,
  });

  final MascotMood mood;
  final String message;
  final AppPalette palette;
  final String label;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        MascotWidget(mood: mood, size: 116, showBackdrop: false),
        const SizedBox(width: 6),
        Expanded(
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            decoration: BoxDecoration(
              color: palette.cardWhite,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: palette.primaryCoral.withValues(alpha: 0.5),
                width: 2,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.4,
                    color: palette.textNavy,
                  ),
                ),
                const SizedBox(height: 8),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: palette.primaryCoral,
                    visualDensity: VisualDensity.compact,
                  ),
                  onPressed: onNext,
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
