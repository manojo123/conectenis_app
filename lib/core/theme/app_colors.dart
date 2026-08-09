import 'package:flutter/material.dart';

/// ConectTenis design tokens - ConecTenis Color System (PDF).
abstract final class AppColors {
  // Brand core
  static const primary = Color(0xFFA6CE39);
  static const primaryBright = Color(0xFFC5E821);
  static const primaryHover = Color(0xFFB2D549);
  static const primaryPressed = Color(0xFF8AB024);
  static const onPrimary = Color(0xFF0F1A38);
  static const navy = Color(0xFF1A2A6C);
  static const navyDeep = Color(0xFF0F1A38);
  static const white = Color(0xFFFFFFFF);
  static const cream = Color(0xFFF2F1EC);

  // Dark theme surfaces
  static const background = navyDeep;
  static const surface = Color(0xFF16244A);
  static const surfaceRaised = Color(0xFF1E3059);
  static const border = Color(0xFF2A3A66);

  // Light theme surfaces
  static const backgroundLight = cream;
  static const surfaceLight = white;
  static const surfaceRaisedLight = white;
  static const borderLight = Color(0xFFD8DCE8);

  // Dark theme text
  static const textPrimaryDark = Color(0xFFE6EAF2);
  static const textMutedDark = Color(0xFF9AA6CF);
  static const textDisabledDark = Color(0xFF5A6488);
  static const linkAccentDark = primary;

  // Light theme text
  static const textPrimaryLight = navyDeep;
  static const textMutedLight = Color(0xFF5E6679);
  static const textDisabledLight = Color(0xFFA8AEC0);
  static const linkAccentLight = Color(0xFF6C8A1B);

  // Semantic / status
  static const success = Color(0xFF3FB66B);
  static const warning = Color(0xFFE8B931);
  static const error = Color(0xFFE5484D);
  static const info = Color(0xFF3E8BE8);
  static const disabledBg = Color(0xFF26305A);
  static const disabledFg = textDisabledDark;

  // Effects
  static const focusRing = Color(0x33A6CE39);

  // Interactive (dark theme defaults)
  static const navSelected = primary;
  static const navUnselected = textMutedDark;
  static const chipSelectedBg = surfaceRaised;
  static const chipSelectedFg = primary;
  static const chipUnselectedFg = textMutedDark;
  static const buttonOnLimeBg = navy;
  static const buttonOnLimeFg = primary;

  // Backward-compatible aliases (prefer theme / semantic names in new code)
  static const lime = primary;
  static const limeDark = primaryPressed;
  static const card = surface;
  static const navyDark = navyDeep;
  static const textPrimary = textPrimaryDark;
  static const textSecondary = textMutedDark;
  static const textMuted = textMutedDark;
  static const textOnLime = onPrimary;
  static const borderSubtle = border;
  static const heroOnLime = onPrimary;
}
