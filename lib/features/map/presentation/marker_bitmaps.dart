import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:conectenis_app/core/theme/app_tokens.dart';
import 'package:conectenis_app/shared/models/player.dart';
import 'package:conectenis_app/shared/widgets/user_avatar.dart';

/// Draws the prototype map pins with dart:ui Canvas — no extra dependencies.
///
/// Player pin: hue-gradient circle with initials and an NTRP chip below.
/// Place pin: rounded square with a lime tennis glyph.
/// Bitmaps are cached per (kind, id, selected, brightness).
abstract final class MarkerBitmaps {
  static final _cache = <String, BitmapDescriptor>{};

  static void clearCache() => _cache.clear();

  static Future<BitmapDescriptor> player({
    required Player p,
    required bool selected,
    required AppTokens t,
    required double dpr,
  }) async {
    final key = 'p:${p.id}:$selected:${t.bg.toARGB32()}';
    final cached = _cache[key];
    if (cached != null) return cached;

    const w = 72.0, h = 78.0;
    final radius = selected ? 25.0 : 22.0;
    final center = Offset(w / 2, 30);

    final descriptor = await _draw(w, h, dpr, (canvas) {
      if (selected) {
        final ring = Paint()
          ..color = t.accent
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3;
        canvas.drawCircle(center, radius + 4, ring);
      }
      // Rim in the map background color, like the prototype's 2.5px border.
      canvas.drawCircle(center, radius + 2.5, Paint()..color = t.bg);

      final gradient = avatarGradientFor(p.id);
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..shader = gradient.createShader(
            Rect.fromCircle(center: center, radius: radius),
          ),
      );

      _paintText(
        canvas,
        text: initialsFor(p.name),
        style: TextStyle(
          color: Colors.white,
          fontSize: selected ? 16 : 14,
          fontWeight: FontWeight.w800,
        ),
        center: center,
      );

      // NTRP chip anchored under the circle.
      final label = p.ntrpRating.toStringAsFixed(1).replaceAll('.', ',');
      final tp = _layoutText(
        label,
        TextStyle(
          color: t.onAccent,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      );
      final chipW = tp.width + 12;
      const chipH = 17.0;
      final chipTop = center.dy + radius - 4;
      final chipRect = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(center.dx, chipTop + chipH / 2),
          width: chipW,
          height: chipH,
        ),
        const Radius.circular(7),
      );
      canvas.drawRRect(
        chipRect.inflate(2),
        Paint()..color = t.bg,
      );
      canvas.drawRRect(chipRect, Paint()..color = t.accent);
      tp.paint(
        canvas,
        Offset(center.dx - tp.width / 2, chipTop + (chipH - tp.height) / 2),
      );
    });

    _cache[key] = descriptor;
    return descriptor;
  }

  static Future<BitmapDescriptor> place({
    required int id,
    required bool selected,
    required AppTokens t,
    required double dpr,
  }) async {
    final key = 'q:$selected:${t.bg.toARGB32()}';
    final cached = _cache[key];
    if (cached != null) return cached;

    const w = 60.0, h = 60.0;
    final size = selected ? 46.0 : 42.0;
    final center = const Offset(w / 2, h / 2);

    final descriptor = await _draw(w, h, dpr, (canvas) {
      final rect = RRect.fromRectAndRadius(
        Rect.fromCenter(center: center, width: size, height: size),
        const Radius.circular(14),
      );
      if (selected) {
        final ring = Paint()
          ..color = t.accent
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3;
        canvas.drawRRect(rect.inflate(4), ring);
      }
      canvas.drawRRect(rect, Paint()..color = t.surface);
      canvas.drawRRect(
        rect,
        Paint()
          ..color = t.accent
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5,
      );

      final icon = Symbols.sports_tennis_rounded;
      _paintText(
        canvas,
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          fontFamily: icon.fontFamily,
          package: icon.fontPackage,
          fontSize: 24,
          color: t.accentText,
          fontVariations: const [ui.FontVariation('FILL', 1)],
        ),
        center: center,
      );
    });

    _cache[key] = descriptor;
    return descriptor;
  }

  static TextPainter _layoutText(String text, TextStyle style) {
    return TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
  }

  static void _paintText(
    Canvas canvas, {
    required String text,
    required TextStyle style,
    required Offset center,
  }) {
    final tp = _layoutText(text, style);
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
  }

  static Future<BitmapDescriptor> _draw(
    double width,
    double height,
    double dpr,
    void Function(Canvas canvas) paint,
  ) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder)..scale(dpr);
    paint(canvas);
    final image = await recorder
        .endRecording()
        .toImage((width * dpr).round(), (height * dpr).round());
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    return BitmapDescriptor.bytes(
      bytes!.buffer.asUint8List(),
      imagePixelRatio: dpr,
    );
  }
}
