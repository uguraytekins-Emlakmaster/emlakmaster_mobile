import 'package:flutter/material.dart';

/// Hafif KPI sparkline — liste içinde değil, sabit kartlarda kullanın.
class PremiumSparkline extends StatelessWidget {
  const PremiumSparkline({
    super.key,
    required this.values,
    required this.color,
    this.height = 28,
    this.strokeWidth = 1.6,
    this.showFill = false,
    this.showGrid = false,
  });

  final List<double> values;
  final Color color;
  final double height;
  final double strokeWidth;
  final bool showFill;
  final bool showGrid;

  @override
  Widget build(BuildContext context) {
    if (values.length < 2) {
      return SizedBox(height: height);
    }
    return RepaintBoundary(
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: CustomPaint(
          painter: _PremiumSparklinePainter(
            values: values,
            color: color,
            strokeWidth: strokeWidth,
            showFill: showFill,
            showGrid: showGrid,
          ),
        ),
      ),
    );
  }
}

class _PremiumSparklinePainter extends CustomPainter {
  _PremiumSparklinePainter({
    required this.values,
    required this.color,
    required this.strokeWidth,
    this.showFill = false,
    this.showGrid = false,
  });

  final List<double> values;
  final Color color;
  final double strokeWidth;
  final bool showFill;
  final bool showGrid;

  Path _buildPath(Size size) {
    final minV = values.reduce((a, b) => a < b ? a : b);
    final maxV = values.reduce((a, b) => a > b ? a : b);
    final range = (maxV - minV).abs() < 0.001 ? 1.0 : maxV - minV;
    final path = Path();
    for (var i = 0; i < values.length; i++) {
      final x = size.width * (i / (values.length - 1));
      final y = size.height - ((values[i] - minV) / range) * size.height;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (showGrid) {
      final gridPaint = Paint()
        ..color = color.withValues(alpha: 0.08)
        ..strokeWidth = 1;
      for (var i = 1; i < 4; i++) {
        final y = size.height * (i / 4);
        canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
      }
    }

    final minV = values.reduce((a, b) => a < b ? a : b);
    final maxV = values.reduce((a, b) => a > b ? a : b);
    final range = (maxV - minV).abs() < 0.001 ? 1.0 : maxV - minV;

    if (showFill) {
      final fillPath = _buildPath(size)
        ..lineTo(size.width, size.height)
        ..lineTo(0, size.height)
        ..close();
      final fillPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            color.withValues(alpha: 0.28),
            color.withValues(alpha: 0.02),
          ],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
      canvas.drawPath(fillPath, fillPaint);
    }

    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(_buildPath(size), paint);

    // Live endpoint dot
    final lastI = values.length - 1;
    final lx = size.width;
    final ly = size.height -
        ((values[lastI] - minV) / range) * size.height;
    canvas.drawCircle(
      Offset(lx, ly),
      strokeWidth + 1.2,
      Paint()..color = color,
    );
    canvas.drawCircle(
      Offset(lx, ly),
      strokeWidth + 3,
      Paint()..color = color.withValues(alpha: 0.22),
    );
  }

  @override
  bool shouldRepaint(covariant _PremiumSparklinePainter oldDelegate) {
    return oldDelegate.values != values ||
        oldDelegate.color != color ||
        oldDelegate.showFill != showFill ||
        oldDelegate.showGrid != showGrid;
  }
}
