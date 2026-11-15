import 'package:floos/core/theme/tokens.dart';
import 'package:flutter/material.dart';

/// Raw palette from design.md §1.1 and §5. Widgets never use these directly;
/// they read [FloosColors] from the theme.
abstract final class AppPalette {
  static const primary = Color(0xFF9C6CF6);
  static const primaryLight = Color(0xFFB08AFF);
  static const primaryDark = Color(0xFF7C4DE0);
  static const primaryTint = Color(0xFFF4EEFF);
  static const header1 = Color(0xFFA278FE);
  static const header2 = Color(0xFFA47EF5);
  static const header3 = Color(0xFF9271DA);

  static const background = Color(0xFFF5F5F5);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceMuted = Color(0xFFEFEFEF);
  static const border = Color(0xFFEDEDED);
  static const textPrimary = Color(0xFF111111);
  static const textSecondary = Color(0xFF6E6E73);
  static const textTertiary = Color(0xFFA1A1A6);
  static const inverse = Color(0xFF141311);
  static const onDark = Color(0xFFFFFFFF);

  static const expense = Color(0xFFF0384D);
  static const income = Color(0xFF22A55B);
  static const successTint = Color(0xFFE7FFEA);
  static const danger = Color(0xFFFD7150);
  static const dangerTint = Color(0xFFFFF0EB);
  static const warning = Color(0xFFFE9F1C);
  static const warningTint = Color(0xFFFFF4E3);
  static const otherStrong = Color(0xFFD9D9D9);
  static const otherTint = Color(0xFFEBEBEB);

  static const darkBackground = Color(0xFF0E0E10);
  static const darkSurface = Color(0xFF1A1A1D);
  static const darkSurfaceMuted = Color(0xFF26262A);
  static const darkBorder = Color(0xFF2C2C31);
  static const darkTextPrimary = Color(0xFFF5F5F7);
  static const darkTextSecondary = Color(0xFFA1A1A6);
  static const darkTextTertiary = Color(0xFF7C7C82);
  static const darkPrimaryTint = Color(0xFF2B2140);

  static const shadowBase = Color(0xFF111111);
}

/// Category palette (strong + tint) from design.md §1.1.
enum CategoryColor {
  purple(Color(0xFF9C6CF6), Color(0xFFF7F1FB)),
  blue(Color(0xFF229FFC), Color(0xFFE7F5FE)),
  green(Color(0xFF38C775), Color(0xFFE7F4EB)),
  orange(Color(0xFFFE7503), Color(0xFFFFF1E5)),
  coral(Color(0xFFF27255), Color(0xFFFFF0E9)),
  pink(Color(0xFFF0384D), Color(0xFFFFEAEF)),
  slate(Color(0xFF5B6B82), Color(0xFFF1F4F9)),
  grey(Color(0xFFD9D9D9), Color(0xFFEBEBEB));

  CategoryColor(this.strong, this.lightTint);

  final Color strong;
  final Color lightTint;

  /// Tint for the given brightness: light uses the sampled tint, dark uses the
  /// strong colour at 16 % opacity over the surface (design.md §5).
  Color tint(Brightness b) => b == Brightness.light
      ? lightTint
      : Color.alphaBlend(
          strong.withValues(alpha: AppOpacity.darkTint),
          AppPalette.darkSurface,
        );

  static CategoryColor byName(String? name) => CategoryColor.values.firstWhere(
    (c) => c.name == name,
    orElse: () => CategoryColor.purple,
  );
}

/// Semantic colour tokens exposed through the theme.
@immutable
class FloosColors extends ThemeExtension<FloosColors> {
  const FloosColors({
    required this.brightness,
    required this.primary,
    required this.primaryLight,
    required this.primaryDark,
    required this.primaryTint,
    required this.headerGradient,
    required this.fabGradient,
    required this.background,
    required this.surface,
    required this.surfaceMuted,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.inverse,
    required this.onInverse,
    required this.onDark,
    required this.expense,
    required this.income,
    required this.successTint,
    required this.danger,
    required this.dangerTint,
    required this.warning,
    required this.warningTint,
    required this.shadow,
  });

  final Brightness brightness;
  final Color primary;
  final Color primaryLight;
  final Color primaryDark;
  final Color primaryTint;
  final LinearGradient headerGradient;
  final LinearGradient fabGradient;
  final Color background;
  final Color surface;
  final Color surfaceMuted;
  final Color border;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color inverse;
  final Color onInverse;
  final Color onDark;
  final Color expense;
  final Color income;
  final Color successTint;
  final Color danger;
  final Color dangerTint;
  final Color warning;
  final Color warningTint;
  final Color shadow;

  static const light = FloosColors(
    brightness: Brightness.light,
    primary: AppPalette.primary,
    primaryLight: AppPalette.primaryLight,
    primaryDark: AppPalette.primaryDark,
    primaryTint: AppPalette.primaryTint,
    headerGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [AppPalette.header1, AppPalette.header2, AppPalette.header3],
    ),
    fabGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [AppPalette.primaryLight, AppPalette.primary],
    ),
    background: AppPalette.background,
    surface: AppPalette.surface,
    surfaceMuted: AppPalette.surfaceMuted,
    border: AppPalette.border,
    textPrimary: AppPalette.textPrimary,
    textSecondary: AppPalette.textSecondary,
    textTertiary: AppPalette.textTertiary,
    inverse: AppPalette.inverse,
    onInverse: AppPalette.onDark,
    onDark: AppPalette.onDark,
    expense: AppPalette.expense,
    income: AppPalette.income,
    successTint: AppPalette.successTint,
    danger: AppPalette.danger,
    dangerTint: AppPalette.dangerTint,
    warning: AppPalette.warning,
    warningTint: AppPalette.warningTint,
    shadow: AppPalette.shadowBase,
  );

  /// Dark palette (design.md §5): header gradient ~10 % darker.
  static final dark = FloosColors(
    brightness: Brightness.dark,
    primary: AppPalette.primary,
    primaryLight: AppPalette.primaryLight,
    primaryDark: AppPalette.primaryDark,
    primaryTint: AppPalette.darkPrimaryTint,
    headerGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        _darken(AppPalette.header1),
        _darken(AppPalette.header2),
        _darken(AppPalette.header3),
      ],
    ),
    fabGradient: const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [AppPalette.primaryLight, AppPalette.primary],
    ),
    background: AppPalette.darkBackground,
    surface: AppPalette.darkSurface,
    surfaceMuted: AppPalette.darkSurfaceMuted,
    border: AppPalette.darkBorder,
    textPrimary: AppPalette.darkTextPrimary,
    textSecondary: AppPalette.darkTextSecondary,
    textTertiary: AppPalette.darkTextTertiary,
    inverse: AppPalette.surface,
    onInverse: AppPalette.textPrimary,
    onDark: AppPalette.onDark,
    expense: AppPalette.expense,
    income: AppPalette.income,
    successTint: Color.alphaBlend(
      AppPalette.income.withValues(alpha: AppOpacity.darkTint),
      AppPalette.darkSurface,
    ),
    danger: AppPalette.danger,
    dangerTint: Color.alphaBlend(
      AppPalette.danger.withValues(alpha: AppOpacity.darkTint),
      AppPalette.darkSurface,
    ),
    warning: AppPalette.warning,
    warningTint: Color.alphaBlend(
      AppPalette.warning.withValues(alpha: AppOpacity.darkTint),
      AppPalette.darkSurface,
    ),
    shadow: const Color(0xFF000000),
  );

  static Color _darken(Color c) {
    final hsl = HSLColor.fromColor(c);
    return hsl.withLightness((hsl.lightness * 0.9).clamp(0, 1)).toColor();
  }

  /// Tint/strong pair for a category colour in the current brightness.
  Color tintOf(CategoryColor c) => c.tint(brightness);

  @override
  FloosColors copyWith() => this;

  @override
  FloosColors lerp(ThemeExtension<FloosColors>? other, double t) =>
      t < 0.5 ? this : (other as FloosColors? ?? this);
}
