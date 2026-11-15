import 'package:floos/core/theme/app_colors.dart';
import 'package:floos/core/theme/app_text.dart';
import 'package:floos/core/theme/tokens.dart';
import 'package:flutter/material.dart';

export 'package:floos/core/theme/app_colors.dart';
export 'package:floos/core/theme/app_text.dart';
export 'package:floos/core/theme/tokens.dart';

/// Builds light and dark [ThemeData] from the design tokens.
abstract final class AppTheme {
  static ThemeData light() => _build(FloosColors.light);
  static ThemeData dark() => _build(FloosColors.dark);

  static ThemeData _build(FloosColors c) {
    final text = FloosText.from(c);
    final shadows = FloosShadows.from(c);
    final scheme = ColorScheme.fromSeed(
      seedColor: c.primary,
      brightness: c.brightness,
    ).copyWith(
      primary: c.primary,
      onPrimary: c.onDark,
      surface: c.surface,
      onSurface: c.textPrimary,
      error: c.expense,
      outline: c.border,
      surfaceContainerHighest: c.surfaceMuted,
    );
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.lg),
    );
    final materialText = TextTheme(
      displayLarge: text.displayL,
      displayMedium: text.displayM,
      titleLarge: text.titleL,
      titleMedium: text.titleM,
      bodyLarge: text.bodyM.copyWith(fontWeight: FontWeight.w400),
      bodyMedium: text.bodyM.copyWith(fontWeight: FontWeight.w400),
      bodySmall: text.bodyS,
      labelLarge: text.bodyM,
      labelMedium: text.caption,
      labelSmall: text.caption,
    );
    return ThemeData(
      useMaterial3: true,
      brightness: c.brightness,
      colorScheme: scheme,
      fontFamily: AppFonts.inter,
      fontFamilyFallback: AppFonts.fallback,
      scaffoldBackgroundColor: c.background,
      canvasColor: c.surface,
      textTheme: materialText,
      extensions: [c, text, shadows],
      appBarTheme: AppBarTheme(
        backgroundColor: c.background,
        surfaceTintColor: Colors.transparent,
        foregroundColor: c.textPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: text.titleL,
      ),
      cardTheme: CardThemeData(
        color: c.surface,
        elevation: 0,
        shape: shape,
        margin: EdgeInsets.zero,
      ),
      dividerTheme: DividerThemeData(color: c.border, thickness: 1, space: 1),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: c.surface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: false,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: c.surface,
        surfaceTintColor: Colors.transparent,
        shape: shape,
        titleTextStyle: text.titleM,
        contentTextStyle: text.bodyS,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: c.inverse,
        contentTextStyle: text.bodyS.copyWith(color: c.onInverse),
        actionTextColor: c.primaryLight,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.surfaceMuted,
        hintStyle: text.bodyS.copyWith(color: c.textTertiary),
        labelStyle: text.bodyS,
        errorStyle: text.caption.copyWith(color: c.expense),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpace.lg,
          vertical: AppSpace.md,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: c.primary, width: AppSizes.selectedBorder),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: c.expense),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? c.onDark : c.surface,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? c.primary : c.surfaceMuted,
        ),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: c.surfaceMuted,
        selectedColor: c.primaryTint,
        labelStyle: text.caption.copyWith(color: c.textPrimary),
        side: BorderSide.none,
        shape: const StadiumBorder(),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: c.primary),
      textSelectionTheme: TextSelectionThemeData(cursorColor: c.primary),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.linux: FadeForwardsPageTransitionsBuilder(),
        },
      ),
    );
  }
}

/// Convenience accessors for design tokens.
extension FloosThemeX on BuildContext {
  FloosColors get colors => Theme.of(this).extension<FloosColors>()!;
  FloosText get text => Theme.of(this).extension<FloosText>()!;
  FloosShadows get shadows => Theme.of(this).extension<FloosShadows>()!;
  Brightness get brightness => Theme.of(this).brightness;
}
