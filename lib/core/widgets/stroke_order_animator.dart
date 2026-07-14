import 'package:flutter/material.dart';

import '../services/kanjivg_parser.dart';
import '../theme/app_colors.dart';

/// Animates a kanji's stroke order from a KanjiVG SVG asset, with
/// play/pause/replay/speed controls and a "show all strokes numbered"
/// static mode.
///
/// Falls back to a plain [character] display when [svgAssetPath] is null
/// or fails to parse (missing asset, malformed SVG) — same fallback
/// philosophy as `KanjiGlyph`.
class StrokeOrderAnimator extends StatefulWidget {
  final String character;
  final String? svgAssetPath;
  final double size;

  const StrokeOrderAnimator({
    super.key,
    required this.character,
    required this.svgAssetPath,
    this.size = 220,
  });

  @override
  State<StrokeOrderAnimator> createState() => _StrokeOrderAnimatorState();
}

class _StrokeOrderAnimatorState extends State<StrokeOrderAnimator>
    with SingleTickerProviderStateMixin {
  static const _msPerStroke = 500;

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
    _load();
  }

  @override
  void didUpdateWidget(covariant StrokeOrderAnimator oldWidget) {
    super.didUpdateWidget(oldWidget);
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
    final ms = (_msPerStroke * strokeCount / _speed).round();
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
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
            style: const TextStyle(fontSize: 96, color: AppColors.textNavy),
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
          decoration: BoxDecoration(
            color: AppColors.cardWhite,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.textNavy.withValues(alpha: 0.08)),
          ),
          child: CustomPaint(
            size: Size(widget.size, widget.size),
            painter: _StrokeOrderPainter(
              data: data,
              progress: _controller.value,
              showAllNumbered: _showAllNumbered,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              onPressed: _replay,
              icon: const Icon(Icons.replay, color: AppColors.textNavy),
              tooltip: 'Ulangi',
            ),
            IconButton(
              onPressed: _showAllNumbered ? null : _togglePlayPause,
              icon: Icon(
                _controller.isAnimating ? Icons.pause_circle_filled : Icons.play_circle_fill,
                color: AppColors.secondaryBlue,
                size: 40,
              ),
              tooltip: _controller.isAnimating ? 'Jeda' : 'Putar',
            ),
            IconButton(
              onPressed: _toggleShowAllNumbered,
              icon: Icon(
                Icons.format_list_numbered,
                color: _showAllNumbered ? AppColors.secondaryBlue : AppColors.textNavy,
              ),
              tooltip: 'Tampilkan semua goresan bernomor',
            ),
          ],
        ),
        Row(
          children: [
            const Icon(Icons.speed, size: 18, color: AppColors.textNavy),
            Expanded(
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: AppColors.secondaryBlue,
                  thumbColor: AppColors.secondaryBlue,
                  inactiveTrackColor: AppColors.textNavy.withValues(alpha: 0.12),
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
                style: const TextStyle(fontSize: 12, color: AppColors.textNavy),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StrokeOrderPainter extends CustomPainter {
  final KanjiStrokeData data;
  final double progress;
  final bool showAllNumbered;

  _StrokeOrderPainter({
    required this.data,
    required this.progress,
    required this.showAllNumbered,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / data.viewBox.width;
    canvas.save();
    canvas.scale(scale, scale);

    final guidePaint = Paint()
      ..color = AppColors.textNavy.withValues(alpha: 0.10)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    for (final stroke in data.strokes) {
      canvas.drawPath(stroke.path, guidePaint);
    }

    final strokePaint = Paint()
      ..color = AppColors.secondaryBlue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final strokeCount = data.strokes.length;
    if (showAllNumbered) {
      for (final stroke in data.strokes) {
        canvas.drawPath(stroke.path, strokePaint);
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
          canvas.drawPath(metric.extractPath(0, metric.length * partial), strokePaint);
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

  void _paintNumber(Canvas canvas, KanjiStroke stroke) {
    final painter = TextPainter(
      text: TextSpan(
        text: '${stroke.number}',
        style: const TextStyle(
          color: AppColors.primaryCoral,
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
        oldDelegate.showAllNumbered != showAllNumbered;
  }
}
