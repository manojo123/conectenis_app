import 'package:flutter/material.dart';

/// Elevation and glow shadows from the ConecTenis Color System.
abstract final class AppShadows {
  /// Cards, modals — black depth shadow (never colored).
  static const depth = [
    BoxShadow(
      color: Color(0x73000000),
      blurRadius: 24,
      offset: Offset(0, 8),
    ),
  ];

  /// Primary CTA only — lime glow, use sparingly.
  static const limeGlow = [
    BoxShadow(
      color: Color(0x4DA6CE39),
      blurRadius: 20,
      offset: Offset(0, 6),
    ),
  ];

  /// Focus ring for inputs and interactive elements.
  static const focusRing = [
    BoxShadow(
      color: Color(0x33A6CE39),
      blurRadius: 0,
      spreadRadius: 3,
    ),
  ];
}
