import 'package:flutter/animation.dart';

/// Spacing scale (4-pt grid) from design.md §1.3.
abstract final class AppSpace {
  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double x2 = 24;
  static const double x3 = 32;
  static const double x4 = 40;
  static const double x5 = 48;

  /// Screen horizontal padding.
  static const double screen = lg;

  /// Gap between cards in a list.
  static const double cardGap = md;

  /// Section → section gap.
  static const double section = x2;
}

/// Radius scale from design.md §1.4.
abstract final class AppRadius {
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 20;
  static const double xl = 28;
  static const double full = 999;
}

/// Component sizes from design.md §2–§4.
abstract final class AppSizes {
  static const double navHeight = 72;
  static const double fab = 56;
  static const double fabRaise = 20;
  static const double fabBorder = 4;
  static const double fabGlyph = 24;
  static const double iconTile = 40;
  static const double iconTileSmall = 32;
  static const double iconGlyph = 20;
  static const double iconGlyphSmall = 16;
  static const double navIcon = 22;
  static const double circleButton = 40;
  static const double monthPickerHeight = 36;
  static const double segmentedHeight = 44;
  static const double chartToggleHeight = 32;
  static const double chartToggleButton = 28;
  static const double trendChipHeight = 22;
  static const double progressHeight = 8;
  static const double progressKnob = 14;
  static const double progressKnobBorder = 3;
  static const double ring = 44;
  static const double ringStroke = 4;
  static const double insightPillHeight = 48;
  static const double donutDiameter = 220;
  static const double donutStroke = 44;
  static const double donutGapDeg = 4;
  static const double donutCornerRadius = 8;
  static const double donutRaise = 6;
  static const double barWidth = 12;
  static const double barRadius = 6;
  static const double avatar = 44;
  static const double avatarBorder = 2;
  static const double dot = 8;
  static const double dotBorder = 2;
  static const double homeHeaderHeight = 300;
  static const double headerOverlap = 24;
  static const double deltaPillHeight = 26;
  static const double detailsPillHeight = 28;
  static const double moneyCardHeight = 104;
  static const double rowHeight = 52;
  static const double buttonHeight = 52;
  static const double dragHandleWidth = 36;
  static const double dragHandleHeight = 4;
  static const double categoryChipWidth = 64;
  static const double minTouch = 44;
  static const double budgetTileHeight = 72;
  static const double bannerHeight = 36;
  static const double maxContentWidth = 600;
  static const double keypadKeyHeight = 52;
  static const double pinDot = 14;
  static const double pinKey = 72;
  static const double illustration = 160;
  static const double thumbnail = 64;
  static const double chartHeight = 200;
  static const double hatchStroke = 2;
  static const double hatchGap = 4;
  static const double selectedBorder = 2;

  /// Bottom padding for scroll views so the FAB never covers content.
  static const double scrollBottomPadding = navHeight + x4Fab;
  static const double x4Fab = 40;
}

/// Motion durations and curves from design.md §1.7.
abstract final class AppMotion {
  static const Duration tabSwitch = Duration(milliseconds: 200);
  static const Duration donutSweep = Duration(milliseconds: 600);
  static const Duration donutStagger = Duration(milliseconds: 60);
  static const Duration progress = Duration(milliseconds: 500);
  static const Duration segment = Duration(milliseconds: 220);
  static const Duration sheet = Duration(milliseconds: 300);
  static const Duration balance = Duration(milliseconds: 400);
  static const Duration fabPress = Duration(milliseconds: 120);
  static const Duration undo = Duration(seconds: 5);
  static const Duration searchDebounce = Duration(milliseconds: 250);

  static const Curve tabCurve = Curves.easeOut;
  static const Curve donutCurve = Curves.easeOutCubic;
  static const Curve segmentCurve = Curves.easeInOut;
  static const double fabPressScale = 0.92;
}

/// Opacity constants used across components.
abstract final class AppOpacity {
  static const double decimals = 0.5;
  static const double onPurpleFill = 0.18;
  static const double headerLabel = 0.8;
  static const double insightTrailing = 0.7;
  static const double hatch = 0.4;
  static const double ringInner = 0.6;
  static const double darkTint = 0.16;
  static const double disabled = 0.38;
  static const double sheen = 0.10;
}
