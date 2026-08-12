import 'dart:async' show Timer;
import 'dart:ui' show PathMetric;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers.dart';
import '../services/kanjivg_parser.dart';
import '../theme/app_palette.dart';

/// Animates a kanji's stroke order from a KanjiVG SVG asset, with
/// play/pause/replay/speed controls and a "show all strokes numbered"
/// static mode.
///
/// Falls back to a plain [character] display when [svgAssetPath] is null
/// or fails to parse (missing asset, malformed SVG) — same fallback
/// philosophy as `KanjiGlyph`.
class StrokeOrderAnimator extends ConsumerStatefulWidget {
  final String character;
  final String? svgAssetPath;
  final double size;

  /// Whether to show the play/replay/numbered buttons and the speed slider.
  ///
  /// Off on the kana flashcard, and not merely to save room: that card
  /// lives inside a [SwipeNavigator], and the speed control is a [Slider] —
  /// two horizontal-drag recognisers competing for the same pointer, which
  /// is exactly the conflict already flagged for the kanji detail screen.
  /// Without controls the animation simply loops on its own, which is what
  /// a one-to-four-stroke kana needs anyway.
  final bool showControls;

  /// How long one stroke takes to draw, before the speed control is applied.
  ///
  /// The kana card asks for a slower pace than the kanji screen's 500ms.
  /// Not a stylistic preference: that screen has a speed slider, so a
  /// learner who finds it too quick can slow it down themselves, while the
  /// kana card deliberately has no controls at all — whatever this is set
  /// to is the only speed a child ever sees there, and a stroke that
  /// finishes in half a second is something to watch rather than something
  /// to follow with a pencil.
  final int msPerStroke;

  /// Whether to draw the panel behind the character.
  ///
  /// On the kanji screen it separates the glyph from a plain background. On
  /// the kana flashcard there is already an illustrated card behind it, and
  /// a second bordered box floating on top of that reads as a seam in the
  /// artwork rather than as a frame.
  final bool showFrame;

  const StrokeOrderAnimator({
    super.key,
    required this.character,
    required this.svgAssetPath,
    this.size = 220,
    this.showControls = true,
    this.msPerStroke = 500,
    this.showFrame = true,
  });

  @override
  ConsumerState<StrokeOrderAnimator> createState() =>
      _StrokeOrderAnimatorState();
}

class _StrokeOrderAnimatorState extends ConsumerState<StrokeOrderAnimator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  KanjiStrokeData? _strokeData;
  bool _loading = true;
  bool _showAllNumbered = false;
  double _speed = 1.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
    _controller.addListener(() {
      setState(() {});
    });
    _controller.addStatusListener(_handleStatusChange);
    _load();
  }

  /// Loops the animation instead of stopping at the last stroke: once it
  /// completes, pause briefly on the finished character (more natural for
  /// repeated practice than snapping straight back to stroke 1), then
  /// restart from the beginning — unless "show all numbered" static mode
  /// was switched on in the meantime, or the widget's gone.
  /// Held as a cancellable [Timer] rather than a bare `Future.delayed`.
  ///
  /// The pause between loops outlives the widget whenever a learner swipes
  /// to the next card mid-cycle, and an uncancellable delay leaves a
  /// callback alive after the screen is gone. The `mounted` check kept that
  /// harmless in the running app, which is why it survived unnoticed — but
  /// the test binding refuses to let a pending timer pass, so this only
  /// surfaced once the animator was first put under a widget test. Same
  /// defect, and same fix, as the one already documented for AppLoading.
  Timer? _loopTimer;

  void _handleStatusChange(AnimationStatus status) {
    if (status != AnimationStatus.completed) return;
    if (_showAllNumbered) return;
    _loopTimer?.cancel();
    _loopTimer = Timer(const Duration(milliseconds: 700), () {
      if (!mounted) return;
      if (_showAllNumbered) return;
      if (_controller.status != AnimationStatus.completed) return;
      _controller.forward(from: 0);
    });
  }

  @override
  void didUpdateWidget(covariant StrokeOrderAnimator oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A speed change has to be applied to the controller by hand: the
    // duration was computed once at load, so without this the new setting
    // would not take effect until the next character.
    if (oldWidget.msPerStroke != widget.msPerStroke) {
      final strokeCount = _strokeData?.strokes.length;
      if (strokeCount != null) _applyDuration(strokeCount);
    }
    if (oldWidget.svgAssetPath != widget.svgAssetPath) {
      _controller.stop();
      _controller.value = 0;
      setState(() {
        _strokeData = null;
        _loading = true;
        _showAllNumbered = false;
      });
      _load();
    }
  }

  Future<void> _load() async {
    final assetPath = widget.svgAssetPath;
    if (assetPath == null) {
      setState(() {
        _loading = false;
      });
      return;
    }
    final data = await KanjiVgParser.parse(assetPath);
    if (!mounted) return;
    setState(() {
      _strokeData = data;
      _loading = false;
    });
    if (data != null) {
      _applyDuration(data.strokes.length);
      _controller.forward(from: 0);
    }
  }

  void _applyDuration(int strokeCount) {
    final ms = (widget.msPerStroke * strokeCount / _speed).round();
    _controller.duration = Duration(milliseconds: ms.clamp(200, 60000));
  }

  void _togglePlayPause() {
    if (_controller.isAnimating) {
      _controller.stop();
    } else if (_controller.value >= 1.0) {
      _controller.forward(from: 0);
    } else {
      _controller.forward();
    }
  }

  void _replay() {
    setState(() {
      _showAllNumbered = false;
    });
    _controller.forward(from: 0);
  }

  void _setSpeed(double speed) {
    setState(() {
      _speed = speed;
    });
    final strokeCount = _strokeData?.strokes.length;
    if (strokeCount != null) _applyDuration(strokeCount);
  }

  void _toggleShowAllNumbered() {
    if (!_showAllNumbered) _controller.stop();
    setState(() {
      _showAllNumbered = !_showAllNumbered;
    });
  }

  @override
  void dispose() {
    _loopTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(appStringsProvider);
    if (_loading) {
      return SizedBox(
        width: widget.size,
        height: widget.size,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    final data = _strokeData;
    if (data == null) {
      return SizedBox(
        width: widget.size,
        height: widget.size,
        child: Center(
          child: Text(
            widget.character,
            style: TextStyle(fontSize: 96, color: context.palette.textNavy),
          ),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: widget.size,
          height: widget.size,
          decoration: widget.showFrame
              ? BoxDecoration(
                  color: context.palette.cardWhite,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: context.palette.textNavy.withValues(alpha: 0.08),
                  ),
                )
              : null,
          child: CustomPaint(
            size: Size(widget.size, widget.size),
            painter: _StrokeOrderPainter(
              data: data,
              progress: _controller.value,
              showAllNumbered: _showAllNumbered,
              guideColor: context.palette.textNavy.withValues(alpha: 0.10),
              strokeColor: context.palette.secondaryBlue,
              numberColor: context.palette.primaryCoral,
              directionColor: context.palette.primaryCoral,
            ),
          ),
        ),
        if (widget.showControls) ...[
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              onPressed: _replay,
              icon: Icon(Icons.replay, color: context.palette.textNavy),
              tooltip: s.replayStrokes,
            ),
            IconButton(
              onPressed: _showAllNumbered ? null : _togglePlayPause,
              icon: Icon(
                _controller.isAnimating
                    ? Icons.pause_circle_filled
                    : Icons.play_circle_fill,
                color: context.palette.secondaryBlue,
                size: 40,
              ),
              tooltip: _controller.isAnimating ? s.pauseStrokes : s.playStrokes,
            ),
            IconButton(
              onPressed: _toggleShowAllNumbered,
              icon: Icon(
                Icons.format_list_numbered,
                color: _showAllNumbered
                    ? context.palette.secondaryBlue
                    : context.palette.textNavy,
              ),
              tooltip: s.showAllStrokesNumbered,
            ),
          ],
        ),
        Row(
          children: [
            Icon(Icons.speed, size: 18, color: context.palette.textNavy),
            Expanded(
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: context.palette.secondaryBlue,
                  thumbColor: context.palette.secondaryBlue,
                  inactiveTrackColor: context.palette.textNavy.withValues(
                    alpha: 0.12,
                  ),
                ),
                child: Slider(
                  value: _speed,
                  min: 0.5,
                  max: 2.0,
                  divisions: 6,
                  label: '${_speed.toStringAsFixed(1)}x',
                  onChanged: _setSpeed,
                ),
              ),
            ),
            SizedBox(
              width: 34,
              child: Text(
                '${_speed.toStringAsFixed(1)}x',
                style: TextStyle(fontSize: 12, color: context.palette.textNavy),
              ),
            ),
          ],
        ),
        ],
      ],
    );
  }
}

class _StrokeOrderPainter extends CustomPainter {
  final KanjiStrokeData data;
  final double progress;
  final bool showAllNumbered;

  /// Painters sit outside the widget tree, so they cannot reach the theme
  /// themselves — the colours are resolved in build and handed over.
  final Color guideColor;
  final Color strokeColor;
  final Color numberColor;

  /// Colour of the start dot and the arrowhead. Deliberately not
  /// [strokeColor]: the cues have to read as annotation on top of the
  /// stroke, not as part of the letter's shape.
  final Color directionColor;

  _StrokeOrderPainter({
    required this.data,
    required this.progress,
    required this.showAllNumbered,
    required this.guideColor,
    required this.strokeColor,
    required this.numberColor,
    required this.directionColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / data.viewBox.width;
    canvas.save();
    canvas.scale(scale, scale);

    final guidePaint = Paint()
      ..color = guideColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    for (final stroke in data.strokes) {
      canvas.drawPath(stroke.path, guidePaint);
    }

    final strokePaint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final strokeCount = data.strokes.length;
    if (showAllNumbered) {
      for (final stroke in data.strokes) {
        canvas.drawPath(stroke.path, strokePaint);
        // Every stroke gets an arrowhead here, so the static mode answers
        // "which way?" for the whole character at once instead of only
        // "in what order?". No start dot: the number already sits at the
        // start, and both together just crowd the same few pixels.
        for (final metric in stroke.path.computeMetrics()) {
          _paintArrowAt(canvas, metric, metric.length);
        }
      }
    } else {
      final cumulative = progress * strokeCount;
      final complete = cumulative.floor().clamp(0, strokeCount);
      final partial = cumulative - complete;

      for (var i = 0; i < complete; i++) {
        canvas.drawPath(data.strokes[i].path, strokePaint);
      }
      if (complete < strokeCount && partial > 0) {
        for (final metric in data.strokes[complete].path.computeMetrics()) {
          final drawn = metric.length * partial;
          canvas.drawPath(metric.extractPath(0, drawn), strokePaint);
          // Where the pen went down, and where it is now. The motion alone
          // shows direction while it plays, but a learner who looks at a
          // paused or half-drawn frame gets nothing from motion — these two
          // cues are what make a still frame readable.
          _paintStartDot(canvas, metric);
          _paintArrowAt(canvas, metric, drawn);
        }
      }
    }

    if (showAllNumbered) {
      for (final stroke in data.strokes) {
        _paintNumber(canvas, stroke);
      }
    }

    canvas.restore();
  }

  /// A filled dot where the stroke begins.
  void _paintStartDot(Canvas canvas, PathMetric metric) {
    final start = metric.getTangentForOffset(0);
    if (start == null) return;
    canvas.drawCircle(
      start.position,
      2.6,
      Paint()
        ..color = directionColor
        ..style = PaintingStyle.fill,
    );
  }

  /// A triangle at [distance] along the stroke, pointing the way the pen is
  /// travelling.
  ///
  /// Built from the tangent's own unit vector rather than from
  /// `Tangent.angle` and a canvas rotation. `angle` is measured with the y
  /// axis flipped relative to canvas coordinates, which is a sign error
  /// waiting to happen and would show up as arrowheads pointing backwards
  /// on exactly half the strokes. The vector needs no such convention.
  ///
  /// Sizes are in KanjiVG's own 109-unit view box, since the canvas is
  /// already scaled by the caller.
  void _paintArrowAt(Canvas canvas, PathMetric metric, double distance) {
    final tangent = metric.getTangentForOffset(distance);
    if (tangent == null) return;

    const length = 8.0;
    const halfWidth = 4.2;
    final tip = tangent.position;
    final along = tangent.vector;
    final back = tip - along * length;
    // Perpendicular to the direction of travel.
    final side = Offset(-along.dy, along.dx) * halfWidth;

    final head = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(back.dx + side.dx, back.dy + side.dy)
      ..lineTo(back.dx - side.dx, back.dy - side.dy)
      ..close();
    canvas.drawPath(
      head,
      Paint()
        ..color = directionColor
        ..style = PaintingStyle.fill,
    );
  }

  void _paintNumber(Canvas canvas, KanjiStroke stroke) {
    final painter = TextPainter(
      text: TextSpan(
        text: '${stroke.number}',
        style: TextStyle(
          color: numberColor,
          fontSize: 8,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(
      canvas,
      stroke.numberPosition - Offset(painter.width / 2, painter.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant _StrokeOrderPainter oldDelegate) {
    return oldDelegate.data != data ||
        oldDelegate.progress != progress ||
        oldDelegate.showAllNumbered != showAllNumbered ||
        oldDelegate.directionColor != directionColor;
  }
}
