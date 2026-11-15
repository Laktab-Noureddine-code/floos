import 'package:floos/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// Font family names bundled as assets (no runtime fetching).
abstract final class AppFonts {
  static const inter = 'Inter';
  static const arabic = 'NotoSansArabic';
  static const List<String> fallback = [arabic];
}

/// Typography tokens from design.md §1.2. All numbers use tabular figures.
@immutable
class FloosText extends ThemeExtension<FloosText> {
  const FloosText({
    required this.displayL,
    required this.displayM,
    required this.titleL,
    required this.titleM,
    required this.amountM,
    required this.bodyM,
    required this.bodyS,
    required this.caption,
    required this.micro,
  });

  factory FloosText.from(FloosColors c) {
    TextStyle base(double size, double line, FontWeight w, double ls) =>
        TextStyle(
          fontFamily: AppFonts.inter,
          fontFamilyFallback: AppFonts.fallback,
          fontSize: size,
          height: line / size,
          fontWeight: w,
          letterSpacing: ls,
          color: c.textPrimary,
          fontFeatures: const [FontFeature.tabularFigures()],
        );
    return FloosText(
      displayL: base(40, 48, FontWeight.w700, -0.5),
      displayM: base(28, 34, FontWeight.w700, -0.5),
      titleL: base(18, 24, FontWeight.w600, -0.2),
      titleM: base(16, 22, FontWeight.w600, -0.2),
      amountM: base(20, 26, FontWeight.w700, 0),
      bodyM: base(15, 20, FontWeight.w600, 0),
      bodyS: base(13, 18, FontWeight.w400, 0).copyWith(color: c.textSecondary),
      caption: base(12, 16, FontWeight.w500, 0).copyWith(color: c.textSecondary),
      micro: base(11, 14, FontWeight.w600, 0),
    );
  }

  final TextStyle displayL;
  final TextStyle displayM;
  final TextStyle titleL;
  final TextStyle titleM;
  final TextStyle amountM;
  final TextStyle bodyM;
  final TextStyle bodyS;
  final TextStyle caption;
  final TextStyle micro;

  @override
  FloosText copyWith() => this;

  @override
  FloosText lerp(ThemeExtension<FloosText>? other, double t) =>
      t < 0.5 ? this : (other as FloosText? ?? this);
}

/// Shadows from design.md §1.5.
@immutable
class FloosShadows extends ThemeExtension<FloosShadows> {
  const FloosShadows({
    required this.card,
    required this.floating,
    required this.fab,
    required this.nav,
  });

  factory FloosShadows.from(FloosColors c) => FloosShadows(
    card: [
      BoxShadow(
        color: c.shadow.withValues(alpha: 0.04),
        offset: const Offset(0, 2),
        blurRadius: 8,
      ),
    ],
    floating: [
      BoxShadow(
        color: c.shadow.withValues(alpha: 0.08),
        offset: const Offset(0, 8),
        blurRadius: 24,
      ),
    ],
    fab: [
      BoxShadow(
        color: c.primary.withValues(alpha: 0.45),
        offset: const Offset(0, 8),
        blurRadius: 20,
      ),
    ],
    nav: [
      BoxShadow(
        color: c.shadow.withValues(alpha: 0.04),
        offset: const Offset(0, -4),
        blurRadius: 16,
      ),
    ],
  );

  final List<BoxShadow> card;
  final List<BoxShadow> floating;
  final List<BoxShadow> fab;
  final List<BoxShadow> nav;

  @override
  FloosShadows copyWith() => this;

  @override
  FloosShadows lerp(ThemeExtension<FloosShadows>? other, double t) =>
      t < 0.5 ? this : (other as FloosShadows? ?? this);
}
