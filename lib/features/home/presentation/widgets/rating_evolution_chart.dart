import 'package:flutter/material.dart';
import 'package:conectenis_app/core/theme/app_colors.dart';
import 'package:conectenis_app/features/home/models/dashboard_stats.dart';

class RatingEvolutionChart extends StatelessWidget {
  const RatingEvolutionChart({
    super.key,
    required this.points,
  });

  final List<RatingHistoryPoint> points;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return const SizedBox.shrink();
    }

    final scheme = Theme.of(context).colorScheme;
    final muted = scheme.onSurface.withValues(alpha: 0.7);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Evolução do Rating',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: muted,
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 120,
          width: double.infinity,
          child: CustomPaint(
            painter: _RatingEvolutionPainter(
              points: points,
              labelColor: muted,
              lineColor: AppColors.primary,
              dotBorderColor: scheme.surface,
            ),
            child: Padding(
              padding: const EdgeInsets.only(left: 28, right: 8, top: 8, bottom: 22),
              child: Container(),
            ),
          ),
        ),
      ],
    );
  }
}

class _RatingEvolutionPainter extends CustomPainter {
  _RatingEvolutionPainter({
    required this.points,
    required this.labelColor,
    required this.lineColor,
    required this.dotBorderColor,
  });

  final List<RatingHistoryPoint> points;
  final Color labelColor;
  final Color lineColor;
  final Color dotBorderColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;

    const leftPad = 28.0;
    const bottomPad = 22.0;
    const topPad = 8.0;
    const rightPad = 8.0;

    final chartWidth = size.width - leftPad - rightPad;
    final chartHeight = size.height - topPad - bottomPad;

    final ratings = points.map((p) => p.rating).toList();
    var minY = ratings.reduce((a, b) => a < b ? a : b);
    var maxY = ratings.reduce((a, b) => a > b ? a : b);
    if (minY == maxY) {
      minY -= 0.5;
      maxY += 0.5;
    } else {
      minY -= 0.2;
      maxY += 0.2;
    }

    final gridPaint = Paint()
      ..color = labelColor.withValues(alpha: 0.15)
      ..strokeWidth = 1;
    for (var i = 0; i <= 3; i++) {
      final y = topPad + chartHeight * i / 3;
      canvas.drawLine(Offset(leftPad, y), Offset(size.width - rightPad, y), gridPaint);
    }

    final labelStyle = TextStyle(
      color: labelColor,
      fontSize: 10,
      fontWeight: FontWeight.w500,
    );

    for (var i = 0; i <= 3; i++) {
      final value = maxY - (maxY - minY) * i / 3;
      final y = topPad + chartHeight * i / 3;
      _drawText(canvas, value.toStringAsFixed(1), Offset(0, y - 6), labelStyle);
    }

    final coords = <Offset>[];
    for (var i = 0; i < points.length; i++) {
      final x = leftPad + chartWidth * i / (points.length - 1);
      final normalized = (points[i].rating - minY) / (maxY - minY);
      final y = topPad + chartHeight * (1 - normalized);
      coords.add(Offset(x, y));
    }

    final linePath = Path()..moveTo(coords.first.dx, coords.first.dy);
    for (var i = 1; i < coords.length; i++) {
      final prev = coords[i - 1];
      final curr = coords[i];
      final midX = (prev.dx + curr.dx) / 2;
      linePath.cubicTo(midX, prev.dy, midX, curr.dy, curr.dx, curr.dy);
    }

    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(linePath, linePaint);

    final dotPaint = Paint()..color = lineColor;
    final dotBorder = Paint()
      ..color = dotBorderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    for (final point in coords) {
      canvas.drawCircle(point, 4, dotPaint);
      canvas.drawCircle(point, 4, dotBorder);
    }

    for (var i = 0; i < points.length; i++) {
      final x = leftPad + chartWidth * i / (points.length - 1);
      _drawText(
        canvas,
        points[i].label,
        Offset(x - 10, size.height - 16),
        labelStyle,
      );
    }
  }

  void _drawText(Canvas canvas, String text, Offset offset, TextStyle style) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant _RatingEvolutionPainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.labelColor != labelColor ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.dotBorderColor != dotBorderColor;
  }
}
