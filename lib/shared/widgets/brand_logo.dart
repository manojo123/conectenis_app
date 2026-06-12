import 'package:flutter/material.dart';

enum BrandLogoVariant {
  /// Stacked icon + wordmark — login and hero placements.
  squareWithText,

  /// Icon only — compact square mark.
  square,

  /// Horizontal wordmark + icon — app bar and headers.
  horizontal,
}

/// Theme-aware ConecTênis logo from official brand assets.
class BrandLogo extends StatelessWidget {
  const BrandLogo({
    super.key,
    this.variant = BrandLogoVariant.horizontal,
    this.height = 32,
    this.width,
    this.fit = BoxFit.contain,
  });

  final BrandLogoVariant variant;
  final double height;
  final double? width;
  final BoxFit fit;

  static String assetFor({
    required BrandLogoVariant variant,
    required Brightness brightness,
  }) {
    final isDark = brightness == Brightness.dark;
    return switch (variant) {
      BrandLogoVariant.squareWithText =>
        isDark ? 'assets/images/logo_square_dark_text.png' : 'assets/images/logo_square_light_text.png',
      BrandLogoVariant.square =>
        isDark ? 'assets/images/logo_square_dark.png' : 'assets/images/logo_square_light.png',
      BrandLogoVariant.horizontal =>
        isDark ? 'assets/images/logo_horizontal_dark.png' : 'assets/images/logo_horizontal_light.png',
    };
  }

  @override
  Widget build(BuildContext context) {
    final asset = assetFor(
      variant: variant,
      brightness: Theme.of(context).brightness,
    );

    return Image.asset(
      asset,
      height: height,
      width: width,
      fit: fit,
      semanticLabel: 'ConecTênis',
    );
  }
}
