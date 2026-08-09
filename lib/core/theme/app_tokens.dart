import 'package:flutter/material.dart';

/// Design tokens from the approved ConecTênis prototype (Claude Design).
///
/// One instance per brightness, registered as a [ThemeExtension] on both
/// [ThemeData]s. Redesigned screens read tokens via `context.t.*` instead of
/// the dark-pinned `AppColors` aliases, so they render correctly in light
/// mode and cross-fade when the theme toggles.
class AppTokens extends ThemeExtension<AppTokens> {
  const AppTokens({
    required this.bg,
    required this.surface,
    required this.surface2,
    required this.border,
    required this.text,
    required this.muted,
    required this.disabled,
    required this.disabledBg,
    required this.inputBg,
    required this.accent,
    required this.accentBright,
    required this.accentPress,
    required this.onAccent,
    required this.accentText,
    required this.success,
    required this.warning,
    required this.error,
    required this.info,
    required this.tintAcc,
    required this.tintSucc,
    required this.tintWarn,
    required this.tintErr,
    required this.tintInfo,
    required this.navBg,
    required this.toastBg,
    required this.toastFg,
    required this.glow,
    required this.shadow,
    required this.mapBg,
    required this.mapStreet,
    required this.mapRoad,
    required this.mapWater,
    required this.mapPark,
    required this.mapLabel,
    required this.mapParkLabel,
  });

  final Color bg;
  final Color surface;
  final Color surface2;
  final Color border;
  final Color text;
  final Color muted;
  final Color disabled;
  final Color disabledBg;
  final Color inputBg;
  final Color accent;
  final Color accentBright;
  final Color accentPress;
  final Color onAccent;

  /// Lime readable as TEXT: lime itself on dark, olive `#6C8A1B` on light.
  /// Lime text on light backgrounds fails contrast (1.8:1), never use it.
  final Color accentText;
  final Color success;
  final Color warning;
  final Color error;
  final Color info;
  final Color tintAcc;
  final Color tintSucc;
  final Color tintWarn;
  final Color tintErr;
  final Color tintInfo;

  /// Translucent chrome behind blur (nav bar, floating pills, pinned bars).
  final Color navBg;
  final Color toastBg;
  final Color toastFg;

  /// Lime glow - ONLY on the single primary CTA of a screen.
  final List<BoxShadow> glow;

  /// Depth shadow for floating cards/sheets (black on dark, navy-tint on light).
  final List<BoxShadow> shadow;

  final Color mapBg;
  final Color mapStreet;
  final Color mapRoad;
  final Color mapWater;
  final Color mapPark;
  final Color mapLabel;
  final Color mapParkLabel;

  static const dark = AppTokens(
    bg: Color(0xFF0F1A38),
    surface: Color(0xFF16244A),
    surface2: Color(0xFF1E3059),
    border: Color(0xFF2A3A66),
    text: Color(0xFFE6EAF2),
    muted: Color(0xFF9AA6CF),
    disabled: Color(0xFF5A6488),
    disabledBg: Color(0xFF26305A),
    inputBg: Color(0xFF1E3059),
    accent: Color(0xFFA6CE39),
    accentBright: Color(0xFFC5E821),
    accentPress: Color(0xFF8AB024),
    onAccent: Color(0xFF0F1A38),
    accentText: Color(0xFFA6CE39),
    success: Color(0xFF3FB66B),
    warning: Color(0xFFE8B931),
    error: Color(0xFFE5484D),
    info: Color(0xFF3E8BE8),
    tintAcc: Color(0x21A6CE39),
    tintSucc: Color(0x263FB66B),
    tintWarn: Color(0x29E8B931),
    tintErr: Color(0x26E5484D),
    tintInfo: Color(0x293E8BE8),
    navBg: Color(0xEB0F1A38),
    toastBg: Color(0xFFE6EAF2),
    toastFg: Color(0xFF0F1A38),
    glow: [BoxShadow(color: Color(0x4DA6CE39), blurRadius: 20, offset: Offset(0, 6))],
    shadow: [BoxShadow(color: Color(0x73000000), blurRadius: 24, offset: Offset(0, 8))],
    mapBg: Color(0xFF0C1630),
    mapStreet: Color(0xFF1B2A50),
    mapRoad: Color(0xFF2A3C66),
    mapWater: Color(0xFF123055),
    mapPark: Color(0xFF12341F),
    mapLabel: Color(0xFF5F6FA0),
    mapParkLabel: Color(0xFF3FA06B),
  );

  static const light = AppTokens(
    bg: Color(0xFFF2F1EC),
    surface: Color(0xFFFFFFFF),
    surface2: Color(0xFFEBEDF3),
    border: Color(0xFFDBDEE8),
    text: Color(0xFF0F1A38),
    muted: Color(0xFF5E6679),
    disabled: Color(0xFFA8AEC0),
    disabledBg: Color(0xFFE4E6EC),
    inputBg: Color(0xFFFFFFFF),
    accent: Color(0xFFA6CE39),
    accentBright: Color(0xFFC5E821),
    accentPress: Color(0xFF8AB024),
    onAccent: Color(0xFF0F1A38),
    accentText: Color(0xFF6C8A1B),
    success: Color(0xFF3FB66B),
    warning: Color(0xFFE8B931),
    error: Color(0xFFE5484D),
    info: Color(0xFF3E8BE8),
    tintAcc: Color(0x21A6CE39),
    tintSucc: Color(0x263FB66B),
    tintWarn: Color(0x29E8B931),
    tintErr: Color(0x26E5484D),
    tintInfo: Color(0x293E8BE8),
    navBg: Color(0xF0FFFFFF),
    toastBg: Color(0xFF0F1A38),
    toastFg: Color(0xFFFFFFFF),
    glow: [BoxShadow(color: Color(0x4DA6CE39), blurRadius: 20, offset: Offset(0, 6))],
    shadow: [BoxShadow(color: Color(0x1F0F1A38), blurRadius: 24, offset: Offset(0, 8))],
    mapBg: Color(0xFFE6E8DE),
    mapStreet: Color(0xFFF7F8F3),
    mapRoad: Color(0xFFFFFFFF),
    mapWater: Color(0xFFAECBE8),
    mapPark: Color(0xFFC2DDB6),
    mapLabel: Color(0xFF8A92A6),
    mapParkLabel: Color(0xFF48814C),
  );

  /// Tint background for a semantic color (status badges, icon tiles).
  Color tintFor(Color color) {
    if (color == success) return tintSucc;
    if (color == warning) return tintWarn;
    if (color == error) return tintErr;
    if (color == info) return tintInfo;
    return tintAcc;
  }

  @override
  AppTokens copyWith({
    Color? bg,
    Color? surface,
    Color? surface2,
    Color? border,
    Color? text,
    Color? muted,
    Color? disabled,
    Color? disabledBg,
    Color? inputBg,
    Color? accent,
    Color? accentBright,
    Color? accentPress,
    Color? onAccent,
    Color? accentText,
    Color? success,
    Color? warning,
    Color? error,
    Color? info,
    Color? tintAcc,
    Color? tintSucc,
    Color? tintWarn,
    Color? tintErr,
    Color? tintInfo,
    Color? navBg,
    Color? toastBg,
    Color? toastFg,
    List<BoxShadow>? glow,
    List<BoxShadow>? shadow,
    Color? mapBg,
    Color? mapStreet,
    Color? mapRoad,
    Color? mapWater,
    Color? mapPark,
    Color? mapLabel,
    Color? mapParkLabel,
  }) {
    return AppTokens(
      bg: bg ?? this.bg,
      surface: surface ?? this.surface,
      surface2: surface2 ?? this.surface2,
      border: border ?? this.border,
      text: text ?? this.text,
      muted: muted ?? this.muted,
      disabled: disabled ?? this.disabled,
      disabledBg: disabledBg ?? this.disabledBg,
      inputBg: inputBg ?? this.inputBg,
      accent: accent ?? this.accent,
      accentBright: accentBright ?? this.accentBright,
      accentPress: accentPress ?? this.accentPress,
      onAccent: onAccent ?? this.onAccent,
      accentText: accentText ?? this.accentText,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      error: error ?? this.error,
      info: info ?? this.info,
      tintAcc: tintAcc ?? this.tintAcc,
      tintSucc: tintSucc ?? this.tintSucc,
      tintWarn: tintWarn ?? this.tintWarn,
      tintErr: tintErr ?? this.tintErr,
      tintInfo: tintInfo ?? this.tintInfo,
      navBg: navBg ?? this.navBg,
      toastBg: toastBg ?? this.toastBg,
      toastFg: toastFg ?? this.toastFg,
      glow: glow ?? this.glow,
      shadow: shadow ?? this.shadow,
      mapBg: mapBg ?? this.mapBg,
      mapStreet: mapStreet ?? this.mapStreet,
      mapRoad: mapRoad ?? this.mapRoad,
      mapWater: mapWater ?? this.mapWater,
      mapPark: mapPark ?? this.mapPark,
      mapLabel: mapLabel ?? this.mapLabel,
      mapParkLabel: mapParkLabel ?? this.mapParkLabel,
    );
  }

  @override
  AppTokens lerp(ThemeExtension<AppTokens>? other, double t) {
    if (other is! AppTokens) return this;
    Color c(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppTokens(
      bg: c(bg, other.bg),
      surface: c(surface, other.surface),
      surface2: c(surface2, other.surface2),
      border: c(border, other.border),
      text: c(text, other.text),
      muted: c(muted, other.muted),
      disabled: c(disabled, other.disabled),
      disabledBg: c(disabledBg, other.disabledBg),
      inputBg: c(inputBg, other.inputBg),
      accent: c(accent, other.accent),
      accentBright: c(accentBright, other.accentBright),
      accentPress: c(accentPress, other.accentPress),
      onAccent: c(onAccent, other.onAccent),
      accentText: c(accentText, other.accentText),
      success: c(success, other.success),
      warning: c(warning, other.warning),
      error: c(error, other.error),
      info: c(info, other.info),
      tintAcc: c(tintAcc, other.tintAcc),
      tintSucc: c(tintSucc, other.tintSucc),
      tintWarn: c(tintWarn, other.tintWarn),
      tintErr: c(tintErr, other.tintErr),
      tintInfo: c(tintInfo, other.tintInfo),
      navBg: c(navBg, other.navBg),
      toastBg: c(toastBg, other.toastBg),
      toastFg: c(toastFg, other.toastFg),
      glow: BoxShadow.lerpList(glow, other.glow, t) ?? glow,
      shadow: BoxShadow.lerpList(shadow, other.shadow, t) ?? shadow,
      mapBg: c(mapBg, other.mapBg),
      mapStreet: c(mapStreet, other.mapStreet),
      mapRoad: c(mapRoad, other.mapRoad),
      mapWater: c(mapWater, other.mapWater),
      mapPark: c(mapPark, other.mapPark),
      mapLabel: c(mapLabel, other.mapLabel),
      mapParkLabel: c(mapParkLabel, other.mapParkLabel),
    );
  }
}

extension AppTokensX on BuildContext {
  /// Prototype design tokens for the active theme: `context.t.surface`.
  AppTokens get t => Theme.of(this).extension<AppTokens>()!;
}
