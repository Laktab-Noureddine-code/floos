import 'dart:math' as math;

import 'package:floos/core/theme/app_theme.dart';
import 'package:floos/core/widgets/progress.dart';
import 'package:flutter/material.dart';

/// One donut segment.
class DonutSegment {
  const DonutSegment({required this.value, required this.color, this.hatched = false, this.semanticLabel = ''});

  final int value;
  final Color color;
  final bool hatched;
  final String semanticLabel;
}

/// Donut chart (design.md §4.2): 220 diameter, 44 stroke, 4° gaps, rounded
/// segment ends, largest first clockwise from −90°, tap to raise a segment
/// with a black % tooltip. Sweeps in with a 60 ms stagger.
class DonutChart extends StatefulWidget {
  const DonutChart({
    required this.segments,
    required this.center,
    super.key,
    this.selected,
    this.onSelect,
    this.diameter = AppSizes.donutDiameter,
  });

  final List<DonutSegment> segments;
  final Widget center;
  final int? selected;
  final ValueChanged<int?>? onSelect;
  final double diameter;

  @override
  State<DonutChart> createState() => _DonutChartState();
}

class _DonutChartState extends State<DonutChart> with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  Duration get _total =>
      AppMotion.donutSweep + AppMotion.donutStagger * math.max(0, widget.segments.length - 1);

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: _total);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (animationsEnabled(context)) {
      _c.forward(from: 0);
    } else {
      _c.value = 1;
    }
  }

  @override
  void didUpdateWidget(covariant DonutChart old) {
    super.didUpdateWidget(old);
    if (old.segments.length != widget.segments.length ||
        !_sameValues(old.segments, widget.segments)) {
      _c.duration = _total;
      if (animationsEnabled(context)) _c.forward(from: 0);
    }
  }

  bool _sameValues(List<DonutSegment> a, List<DonutSegment> b) {
    for (var i = 0; i < a.length; i++) {
      if (a[i].value != b[i].value) return false;
    }
    return true;
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  int? _hit(Offset local) {
    final size = widget.diameter + AppSizes.donutRaise * 2;
    final center = Offset(size / 2, size / 2);
    final v = local - center;
    final r = v.distance;
    const stroke = AppSizes.donutStroke;
    final radius = widget.diameter / 2 - stroke / 2;
    if ((r - radius).abs() > stroke / 2 + AppSizes.donutRaise) return null;
    var angle = math.atan2(v.dy, v.dx) + math.pi / 2;
    if (angle < 0) angle += 2 * math.pi;
    final total = widget.segments.fold<int>(0, (a, s) => a + s.value);
    if (total <= 0) return null;
    var start = 0.0;
    for (var i = 0; i < widget.segments.length; i++) {
      final sweep = widget.segments[i].value / total * 2 * math.pi;
      if (angle >= start && angle < start + sweep) return i;
      start += sweep;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.diameter + AppSizes.donutRaise * 2;
    return SizedBox.square(
      dimension: size,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapUp: (d) {
          final i = _hit(d.localPosition);
          widget.onSelect?.call(i == widget.selected ? null : i);
        },
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) => CustomPaint(
            painter: _DonutPainter(
              segments: widget.segments,
              selected: widget.selected,
              elapsedMs: _c.value * _total.inMilliseconds,
              diameter: widget.diameter,
              track: context.colors.surfaceMuted,
            ),
            child: Center(child: widget.center),
          ),
        ),
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  _DonutPainter({
    required this.segments,
    required this.selected,
    required this.elapsedMs,
    required this.diameter,
    required this.track,
  });

  final List<DonutSegment> segments;
  final int? selected;
  final double elapsedMs;
  final double diameter;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    const stroke = AppSizes.donutStroke;
    final radius = diameter / 2 - stroke / 2;
    final total = segments.fold<int>(0, (a, s) => a + s.value);
    if (total <= 0) {
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = track
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke,
      );
      return;
    }
    // Rounded ends eat into the gap: gap = 4° + the cap's angular size.
    final capAngle = (stroke / 2) / radius;
    final gap = AppSizes.donutGapDeg * math.pi / 180 + (segments.length > 1 ? 2 * capAngle : 0);
    var start = -math.pi / 2;
    for (var i = 0; i < segments.length; i++) {
      final s = segments[i];
      final fullSweep = s.value / total * 2 * math.pi;
      final segElapsed = elapsedMs - i * AppMotion.donutStagger.inMilliseconds;
      final t = AppMotion.donutCurve.transform((segElapsed / AppMotion.donutSweep.inMilliseconds).clamp(0.0, 1.0));
      final sweep = math.max(0.0, fullSweep - (segments.length > 1 ? gap : 0)) * t;
      final mid = start + fullSweep / 2;
      final raise = i == selected ? AppSizes.donutRaise : 0.0;
      final c = center + Offset(math.cos(mid), math.sin(mid)) * raise;
      final rect = Rect.fromCircle(center: c, radius: radius);
      final a0 = start + (segments.length > 1 ? gap / 2 : 0);
      if (sweep > 0.0001) {
        final paint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..strokeCap = segments.length > 1 ? StrokeCap.round : StrokeCap.butt
          ..color = s.color;
        canvas.drawArc(rect, a0, sweep, false, paint);
        if (s.hatched) _hatch(canvas, rect, a0, sweep, stroke, s.color);
      }
      if (i == selected && t >= 1) _tooltip(canvas, c, radius + stroke / 2, mid, s.value * 100 / total);
      start += fullSweep;
    }
  }

  void _hatch(Canvas canvas, Rect rect, double a0, double sweep, double stroke, Color color) {
    final path = Path()
      ..addArc(rect.inflate(stroke / 2), a0, sweep)
      ..arcTo(rect.deflate(stroke / 2), a0 + sweep, -sweep, false)
      ..close();
    canvas
      ..save()
      ..clipPath(path);
    final p = Paint()
      ..color = AppPalette.onDark.withValues(alpha: 0.7)
      ..strokeWidth = AppSizes.hatchStroke;
    final b = rect.inflate(stroke);
    for (var x = b.left - b.height; x < b.right; x += AppSizes.hatchStroke + AppSizes.hatchGap) {
      canvas.drawLine(Offset(x, b.bottom), Offset(x + b.height, b.top), p);
    }
    canvas.restore();
  }

  void _tooltip(Canvas canvas, Offset c, double outer, double angle, double pct) {
    final pos = c + Offset(math.cos(angle), math.sin(angle)) * outer;
    final tp = TextPainter(
      text: TextSpan(
        text: '${pct.round()}%',
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppPalette.onDark, fontFamily: AppFonts.inter),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final r = RRect.fromRectAndRadius(
      Rect.fromCenter(center: pos, width: tp.width + AppSpace.md, height: tp.height + AppSpace.sm),
      const Radius.circular(AppRadius.full),
    );
    canvas.drawRRect(r, Paint()..color = AppPalette.inverse);
    tp.paint(canvas, pos - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant _DonutPainter old) =>
      old.elapsedMs != elapsedMs || old.selected != selected || old.segments != segments;
}
