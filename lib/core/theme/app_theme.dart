import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:conectenis_app/core/theme/app_colors.dart';
import 'package:conectenis_app/core/theme/app_radii.dart';
import 'package:conectenis_app/core/theme/app_shadows.dart';
import 'package:conectenis_app/core/theme/app_tokens.dart';

abstract final class AppTheme {
  static ThemeData get dark => _buildTheme(
        brightness: Brightness.dark,
        background: AppColors.background,
        surface: AppColors.surface,
        surfaceRaised: AppColors.surfaceRaised,
        border: AppColors.border,
        textPrimary: AppColors.textPrimaryDark,
        textMuted: AppColors.textMutedDark,
        textDisabled: AppColors.textDisabledDark,
        linkAccent: AppColors.linkAccentDark,
        navBg: AppColors.surface,
      );

  static ThemeData get light => _buildTheme(
        brightness: Brightness.light,
        background: AppColors.backgroundLight,
        surface: AppColors.surfaceLight,
        surfaceRaised: AppColors.surfaceRaisedLight,
        border: AppColors.borderLight,
        textPrimary: AppColors.textPrimaryLight,
        textMuted: AppColors.textMutedLight,
        textDisabled: AppColors.textDisabledLight,
        linkAccent: AppColors.linkAccentLight,
        navBg: AppColors.surfaceLight,
      );

  static ThemeData _buildTheme({
    required Brightness brightness,
    required Color background,
    required Color surface,
    required Color surfaceRaised,
    required Color border,
    required Color textPrimary,
    required Color textMuted,
    required Color textDisabled,
    required Color linkAccent,
    required Color navBg,
  }) {
    final isDark = brightness == Brightness.dark;
    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      extensions: <ThemeExtension<dynamic>>[
        isDark ? AppTokens.dark : AppTokens.light,
      ],
      scaffoldBackgroundColor: background,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: AppColors.primary,
        onPrimary: AppColors.onPrimary,
        primaryContainer: AppColors.primaryHover,
        onPrimaryContainer: AppColors.onPrimary,
        secondary: AppColors.navy,
        onSecondary: AppColors.primary,
        surface: surface,
        onSurface: textPrimary,
        error: AppColors.error,
        onError: AppColors.white,
        outline: border,
        outlineVariant: border.withValues(alpha: 0.6),
        surfaceContainerHighest: surfaceRaised,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: true,
      ),
      textTheme: GoogleFonts.archivoTextTheme(
        _textTheme(textPrimary, textMuted, textDisabled, linkAccent),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: navBg,
        indicatorColor: AppColors.primary.withValues(alpha: 0.2),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            color: selected ? AppColors.navSelected : AppColors.navUnselected,
            fontSize: 11,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? AppColors.navSelected : AppColors.navUnselected,
          );
        }),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceRaised,
        labelStyle: TextStyle(color: textMuted),
        hintStyle: TextStyle(color: textMuted),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: _primaryButtonStyle(isDark),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          disabledForegroundColor: AppColors.disabledFg,
          side: const BorderSide(color: AppColors.primary),
          disabledBackgroundColor: AppColors.disabledBg,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.md),
          ),
          textStyle:
              const TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.5),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: textMuted,
          disabledForegroundColor: textDisabled,
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.lg),
          side: BorderSide(color: border, width: 1),
        ),
      ),
      dividerColor: border,
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: AppColors.primary),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: surface,
        contentTextStyle: TextStyle(color: textPrimary),
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          side: BorderSide(color: border),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        elevation: 4,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surfaceRaised,
        selectedColor: AppColors.chipSelectedBg,
        disabledColor: AppColors.disabledBg,
        labelStyle: TextStyle(color: textMuted),
        secondaryLabelStyle: TextStyle(color: textPrimary),
        side: BorderSide(color: border),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.sm),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.lg)),
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: AppColors.primary,
        textColor: textPrimary,
      ),
    );
    return base;
  }

  static TextTheme _textTheme(
    Color textPrimary,
    Color textMuted,
    Color textDisabled,
    Color linkAccent,
  ) {
    return TextTheme(
      displayLarge: TextStyle(color: textPrimary, fontWeight: FontWeight.w900),
      displayMedium: TextStyle(color: textPrimary, fontWeight: FontWeight.w800),
      displaySmall: TextStyle(color: textPrimary, fontWeight: FontWeight.w800),
      headlineLarge: TextStyle(
          color: textPrimary, fontWeight: FontWeight.w900, letterSpacing: -0.5),
      headlineMedium: TextStyle(
          color: textPrimary, fontWeight: FontWeight.w900, letterSpacing: -0.5),
      headlineSmall: TextStyle(
          color: textPrimary, fontWeight: FontWeight.w800, letterSpacing: -0.3),
      titleLarge: TextStyle(color: textPrimary, fontWeight: FontWeight.w800),
      titleMedium: TextStyle(color: textPrimary, fontWeight: FontWeight.w600),
      titleSmall: TextStyle(color: textPrimary, fontWeight: FontWeight.w600),
      bodyLarge: TextStyle(color: textPrimary),
      bodyMedium: TextStyle(color: textPrimary),
      bodySmall: TextStyle(color: textMuted),
      labelLarge: TextStyle(color: textPrimary, fontWeight: FontWeight.w600),
      labelMedium: TextStyle(color: textMuted),
      labelSmall: TextStyle(color: textMuted, fontSize: 11),
    ).apply(
      bodyColor: textPrimary,
      displayColor: textPrimary,
    );
  }

  static ButtonStyle _primaryButtonStyle(bool isDark) {
    return ButtonStyle(
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) return AppColors.disabledBg;
        if (states.contains(WidgetState.pressed)) return AppColors.primaryPressed;
        if (states.contains(WidgetState.hovered)) return AppColors.primaryHover;
        return AppColors.primary;
      }),
      foregroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) return AppColors.disabledFg;
        if (states.contains(WidgetState.pressed)) return AppColors.white;
        return AppColors.onPrimary;
      }),
      padding: WidgetStateProperty.all(
        const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      ),
      shape: WidgetStateProperty.all(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.md)),
      ),
      textStyle: WidgetStateProperty.all(
        const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.8),
      ),
      elevation: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) return 0;
        return 0;
      }),
      shadowColor: WidgetStateProperty.all(AppColors.navyDeep.withValues(alpha: 0)),
      overlayColor: WidgetStateProperty.all(
        AppColors.primaryPressed.withValues(alpha: 0.12),
      ),
    );
  }

  /// Wraps a primary CTA with the signature lime glow (use on one CTA per screen).
  static BoxDecoration primaryCtaDecoration({bool glow = true}) {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(AppRadii.md),
      boxShadow: glow ? AppShadows.limeGlow : null,
    );
  }
}
