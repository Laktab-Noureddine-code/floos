import 'dart:math' as math;

import 'package:floos/core/l10n/l10n.dart';
import 'package:floos/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

/// Whether animations should run (reduced motion respected).
bool animationsEnabled(BuildContext context) => !MediaQuery.disableAnimationsOf(context);

/// Animates 0 → [value] on first build and between values afterwards.
class _AnimatedFraction extends StatelessWidget {
  const _AnimatedFraction({required this.value, required this.builder});

  final double value;
  final Widget Function(double v) builder;

  @override
  Widget build(BuildContext context) {
    if (!animationsEnabled(context)) return builder(value);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value),
      duration: AppMotion.progress,
      curve: Curves.easeOutCubic,
      builder: (_, v, _) => builder(v),
    );
  }
}

/// Height-8 pill progress bar; `hatched` variant for goals (design.md §3.8).
class LinearProgress extends StatelessWidget {
  const LinearProgress({
    required this.value,
    required this.color,
    super.key,
    this.track,
    this.hatched = false,
    this.semanticPercent,
  });

  /// 0…1 (clamped).
  final double value;
  final Color color;
  final Color? track;
  final bool hatched;
  final int? semanticPercent;

  @override
  Widget build(BuildContext context) {
    final v = value.isNaN ? 0.0 : value.clamp(0.0, 1.0);
    final trackColor = track ?? color.withValues(alpha: 0.15);
    final knob = context.colors.surface;
    return Semantics(
      value: context.l10n.a11yProgress(semanticPercent ?? (v * 100).round()),
      child: SizedBox(
        height: hatched ? AppSizes.progressKnob : AppSizes.progressHeight,
        width: double.infinity,
        child: _AnimatedFraction(
          value: v,
          builder: (x) => CustomPaint(
            painter: _BarPainter(value: x, color: color, track: trackColor, hatched: hatched, knob: knob),
          ),
        ),
      ),
    );
  }
}

class _BarPainter extends CustomPainter {
  _BarPainter({
    required this.value,
    required this.color,
    required this.track,
    required this.hatched,
    required this.knob,
  });

  final double value;
  final Color color;
  final Color track;
  final bool hatched;
  final Color knob;

  @override
  void paint(Canvas canvas, Size size) {
    const h = AppSizes.progressHeight;
    final top = (size.height - h) / 2;
    final full = RRect.fromRectAndRadius(Rect.fromLTWH(0, top, size.width, h), const Radius.circular(h / 2));
    canvas.drawRRect(full, Paint()..color = track);
    final w = size.width * value;
    if (hatched && value < 1) {
      // Diagonal stripes on ~25 % of the width right after the fill.
      final hatchW = math.min(size.width * 0.25, size.width - w);
      canvas
        ..save()
        ..clipRRect(full)
        ..clipRect(Rect.fromLTWH(w, top, hatchW, h));
      final p = Paint()
        ..color = color.withValues(alpha: AppOpacity.hatch)
        ..strokeWidth = AppSizes.hatchStroke;
      for (var x = w - h; x < w + hatchW + h; x += AppSizes.hatchStroke + AppSizes.hatchGap) {
        canvas.drawLine(Offset(x, top + h), Offset(x + h, top), p);
      }
      canvas.restore();
    }
    if (w > 0) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(0, top, math.max(w, h), h), const Radius.circular(h / 2)),
        Paint()..color = color,
      );
    }
    if (hatched) {
      final cx = w.clamp(AppSizes.progressKnob / 2, size.width - AppSizes.progressKnob / 2);
      final center = Offset(cx, size.height / 2);
      canvas
        ..drawCircle(center, AppSizes.progressKnob / 2, Paint()..color = knob)
        ..drawCircle(
          center,
          AppSizes.progressKnob / 2 - AppSizes.progressKnobBorder / 2,
          Paint()
            ..color = color
            ..style = PaintingStyle.stroke
            ..strokeWidth = AppSizes.progressKnobBorder,
        );
    }
  }

  @override
  bool shouldRepaint(covariant _BarPainter old) =>
      old.value != value || old.color != color || old.track != track || old.hatched != hatched;
}

/// 44×44 ring with % label (design.md §3.9). [percent] may exceed 100.
class RingProgress extends StatelessWidget {
  const RingProgress({required this.percent, required this.color, super.key, this.size = AppSizes.ring, this.track});

  final int percent;
  final Color color;
  final Color? track;
  final double size;

  @override
  Widget build(BuildContext context) {
    final tint = track ?? color.withValues(alpha: 0.18);
    return Semantics(
      value: context.l10n.a11yProgress(percent),
      child: SizedBox.square(
        dimension: size,
        child: _AnimatedFraction(
          value: (percent / 100).clamp(0.0, 1.0),
          builder: (v) => CustomPaint(
            painter: _RingPainter(value: v, color: color, track: tint),
            child: Center(
              child: FittedBox(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpace.xs + AppSizes.ringStroke),
                  child: Text(
                    '$percent%',
                    style: context.text.micro.copyWith(color: color, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({required this.value, required this.color, required this.track});

  final double value;
  final Color color;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = AppSizes.ringStroke;
    final center = size.center(Offset.zero);
    final radius = size.width / 2 - stroke / 2;
    canvas
      ..drawCircle(center, radius - stroke / 2, Paint()..color = track.withValues(alpha: track.a * AppOpacity.ringInner))
      ..drawCircle(
        center,
        radius,
        Paint()
          ..color = track
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke,
      );
    if (value > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        2 * math.pi * value,
        false,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = stroke,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) => old.value != value || old.color != color;
}
