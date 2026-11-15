import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:floos/core/l10n/l10n.dart';
import 'package:floos/core/theme/app_theme.dart';
import 'package:floos/core/widgets/progress.dart';
import 'package:flutter/material.dart';

/// One bar group (1–2 bars) on a [BarsChart].
class BarGroup {
  const BarGroup({required this.label, required this.values, this.highlight = false});
  final String label;

  /// Values in minor units (≥ 0).
  final List<int> values;
  final bool highlight;
}

/// Vertical bars, 12 pt wide, top radius 6 (design.md §4.2), with optional
/// net line and limit line. Geometry only (doubles allowed for drawing).
class BarsChart extends StatelessWidget {
  const BarsChart({
    required this.groups,
    required this.colors,
    super.key,
    this.highlightColor,
    this.line,
    this.lineColor,
    this.limits,
    this.limitColor,
    this.height = AppSizes.chartHeight,
    this.semanticLabel,
  });

  final List<BarGroup> groups;

  /// Colour per bar index within a group (non-highlighted).
  final List<Color> colors;
  final Color? highlightColor;

  /// Optional line values (e.g. net cash flow), may be negative.
  final List<int>? line;
  final Color? lineColor;

  /// Optional per-group limit marks (e.g. budget limits).
  final List<int>? limits;
  final Color? limitColor;
  final double height;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) => Semantics(
    label: semanticLabel,
    child: SizedBox(
      height: height,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: animationsEnabled(context) ? 0 : 1, end: 1),
        duration: AppMotion.progress,
        curve: Curves.easeOutCubic,
        builder: (context, t, _) => CustomPaint(
          size: Size.infinite,
          painter: _BarsPainter(
            groups: groups,
            colors: colors,
            highlight: highlightColor,
            line: line,
            lineColor: lineColor ?? context.colors.textPrimary,
            limits: limits,
            limitColor: limitColor ?? context.colors.danger,
            labelStyle: context.text.caption,
            grid: context.colors.border,
            t: t,
          ),
        ),
      ),
    ),
  );
}

class _BarsPainter extends CustomPainter {
  _BarsPainter({
    required this.groups,
    required this.colors,
    required this.highlight,
    required this.line,
    required this.lineColor,
    required this.limits,
    required this.limitColor,
    required this.labelStyle,
    required this.grid,
    required this.t,
  });

  final List<BarGroup> groups;
  final List<Color> colors;
  final Color? highlight;
  final List<int>? line;
  final Color lineColor;
  final List<int>? limits;
  final Color limitColor;
  final TextStyle labelStyle;
  final Color grid;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    if (groups.isEmpty) return;
    const labelH = 20.0;
    final chartH = size.height - labelH;
    final maxV = [
      ...groups.expand((g) => g.values),
      ...?limits,
      ...?line?.map((v) => v.abs()),
      1,
    ].reduce(math.max).toDouble();
    final minLine = line == null || line!.isEmpty ? 0 : math.min(0, line!.reduce(math.min));
    final range = maxV - minLine;
    double y(num v) => chartH - (v - minLine) / range * chartH * 0.92;
    final zeroY = y(0);
    canvas.drawLine(Offset(0, zeroY), Offset(size.width, zeroY), Paint()..color = grid);
    final slot = size.width / groups.length;
    const barW = AppSizes.barWidth;
    for (var i = 0; i < groups.length; i++) {
      final g = groups[i];
      final cx = slot * i + slot / 2;
      final n = g.values.length;
      for (var j = 0; j < n; j++) {
        final x = cx - (n * barW + (n - 1) * 3) / 2 + j * (barW + 3);
        final top = zeroY - (zeroY - y(g.values[j])) * t;
        final color = g.highlight && highlight != null && n == 1 ? highlight! : colors[j % colors.length];
        if (zeroY - top > 0.5) {
          canvas.drawRRect(
            RRect.fromRectAndCorners(
              Rect.fromLTRB(x, top, x + barW, zeroY),
              topLeft: const Radius.circular(AppSizes.barRadius),
              topRight: const Radius.circular(AppSizes.barRadius),
            ),
            Paint()..color = color,
          );
        }
      }
      if (limits != null && i < limits!.length && limits![i] > 0) {
        final ly = y(limits![i]);
        canvas.drawLine(
          Offset(cx - slot * 0.4, ly),
          Offset(cx + slot * 0.4, ly),
          Paint()
            ..color = limitColor
            ..strokeWidth = 2,
        );
      }
      final tp = TextPainter(
        text: TextSpan(text: g.label, style: labelStyle),
        textDirection: TextDirection.ltr,
        maxLines: 1,
        ellipsis: '…',
      )..layout(maxWidth: slot);
      tp.paint(canvas, Offset(cx - tp.width / 2, chartH + 4));
    }
    if (line != null && line!.length == groups.length) {
      final path = Path();
      final dot = Paint()..color = lineColor;
      for (var i = 0; i < line!.length; i++) {
        final p = Offset(slot * i + slot / 2, zeroY - (zeroY - y(line![i])) * t);
        i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
        canvas.drawCircle(p, 3, dot);
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = lineColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BarsPainter old) => old.t != t || old.groups != groups || old.line != line;
}

/// One line series for [LinesChart].
class LineSeries {
  const LineSeries({required this.points, required this.color, this.dashed = false, this.filled = false});

  /// (x, y) where y is in minor units.
  final List<(double, int)> points;
  final Color color;
  final bool dashed;
  final bool filled;
}

/// Line chart built on fl_chart (balances, cumulative spending, goals).
class LinesChart extends StatelessWidget {
  const LinesChart({
    required this.series,
    required this.bottomLabel,
    super.key,
    this.height = AppSizes.chartHeight,
    this.semanticLabel,
    this.maxX,
  });

  final List<LineSeries> series;
  final String Function(double x) bottomLabel;
  final double height;
  final String? semanticLabel;
  final double? maxX;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final all = series.expand((s) => s.points).toList();
    if (all.isEmpty) return SizedBox(height: height);
    final minY = all.map((p) => p.$2).reduce(math.min).toDouble();
    final maxY = all.map((p) => p.$2).reduce(math.max).toDouble();
    final pad = math.max(1.0, (maxY - minY) * 0.1);
    return Semantics(
      label: semanticLabel,
      child: SizedBox(
        height: height,
        child: LineChart(
          duration: animationsEnabled(context) ? AppMotion.progress : Duration.zero,
          LineChartData(
            minY: minY - pad,
            maxY: maxY + pad,
            minX: 0,
            maxX: maxX,
            gridData: FlGridData(
              drawVerticalLine: false,
              getDrawingHorizontalLine: (_) => FlLine(color: c.border, strokeWidth: 1),
            ),
            borderData: FlBorderData(show: false),
            lineTouchData: const LineTouchData(enabled: false),
            titlesData: FlTitlesData(
              leftTitles: const AxisTitles(),
              rightTitles: const AxisTitles(),
              topTitles: const AxisTitles(),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: math.max(1, ((maxX ?? all.map((p) => p.$1).reduce(math.max)) / 5).floorToDouble()),
                  getTitlesWidget: (v, meta) => SideTitleWidget(
                    meta: meta,
                    child: Text(bottomLabel(v), style: context.text.caption.copyWith(fontSize: 11)),
                  ),
                ),
              ),
            ),
            lineBarsData: [
              for (final s in series)
                LineChartBarData(
                  spots: [for (final p in s.points) FlSpot(p.$1, p.$2.toDouble())],
                  color: s.color,
                  barWidth: 2.5,
                  isCurved: !s.dashed,
                  preventCurveOverShooting: true,
                  dashArray: s.dashed ? [6, 4] : null,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(show: s.filled, color: s.color.withValues(alpha: 0.12)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Toggle between a chart and an accessible table (APP_PROMPT §10).
class ChartOrTable extends StatefulWidget {
  const ChartOrTable({required this.chart, required this.rows, super.key});

  final Widget chart;

  /// (label, value) rows for the table view.
  final List<(String, String)> rows;

  @override
  State<ChartOrTable> createState() => _ChartOrTableState();
}

class _ChartOrTableState extends State<ChartOrTable> {
  bool _table = false;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        TextButton.icon(
          onPressed: () => setState(() => _table = !_table),
          icon: Icon(_table ? Icons.bar_chart_rounded : Icons.table_rows_rounded, size: AppSizes.iconGlyphSmall),
          label: Text(_table ? l.a11yViewAsChart : l.a11yViewAsTable, style: context.text.caption),
        ),
        if (_table)
          Column(
            children: [
              for (final r in widget.rows)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpace.xs),
                  child: Row(
                    children: [
                      Expanded(child: Text(r.$1, style: context.text.bodyS)),
                      Text(r.$2, style: context.text.bodyS.copyWith(fontWeight: FontWeight.w600, color: context.colors.textPrimary)),
                    ],
                  ),
                ),
            ],
          )
        else
          widget.chart,
      ],
    );
  }
}
