import 'package:emlakmaster_mobile/core/services/app_lifecycle_power_service.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;

/// "The Sovereign Arc" – çok şeffaf Antique Gold mühür.
/// Web/desktop: imleç hareketine ters yönde hafif dönüş (hafif, jet hızlı).
/// Mobil: statik mühür (kuş gibi hafif — Listener yok).
/// Batarya tasarrufu / arka plan: statik.
class SovereignArcWatermark extends StatefulWidget {
  const SovereignArcWatermark({super.key, required this.child});

  final Widget child;

  /// Geniş ekran veya pointer var: kinetik mühür. Dar ekran / mobil: statik.
  static bool get _useKinetic {
    if (AppLifecyclePowerService.shouldReduceMotion) return false;
    if (kIsWeb) return true;
    switch (defaultTargetPlatform) {
      case TargetPlatform.windows:
      case TargetPlatform.macOS:
      case TargetPlatform.linux:
        return true;
      case TargetPlatform.android:
      case TargetPlatform.iOS:
      case TargetPlatform.fuchsia:
        return false;
    }
  }

  @override
  State<SovereignArcWatermark> createState() => _SovereignArcWatermarkState();
}

class _SovereignArcWatermarkState extends State<SovereignArcWatermark> {
  Offset _pointer = Offset.zero;
  Size _size = Size.zero;

  double get _angle {
    if (_size.width <= 0 || _size.height <= 0) return 0;
    final cx = _size.width / 2;
    final cy = _size.height / 2;
    final dx = _pointer.dx - cx;
    final dy = _pointer.dy - cy;
    final base = (dx * 0.00008 + dy * 0.00006).clamp(-0.12, 0.12);
    return -base;
  }

  @override
  Widget build(BuildContext context) {
    final useKinetic = SovereignArcWatermark._useKinetic;
    return LayoutBuilder(
      builder: (context, constraints) {
        _size = Size(constraints.maxWidth, constraints.maxHeight);
        final arcWidget = RepaintBoundary(
          child: IgnorePointer(
            child: Transform.rotate(
              angle: useKinetic ? _angle : 0,
              child: CustomPaint(
                painter: _SovereignArcPainter(),
                size: _size,
              ),
            ),
          ),
        );
        final stack = Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(child: arcWidget),
            widget.child,
          ],
        );
    if (!useKinetic) {
          return stack;
        }
        return Listener(
          onPointerMove: (e) => setState(() => _pointer = e.localPosition),
          onPointerHover: (e) => setState(() => _pointer = e.localPosition),
          child: stack,
        );
      },
    );
  }
}

class _SovereignArcPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.longestSide * 0.52;
    final paint = Paint()
      ..color = DesignTokens.antiqueGold.withOpacity(0.03)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    // Yay: üst-orta kısımda "taç" benzeri arc
    final path = Path()
      ..addArc(
        Rect.fromCircle(center: center, radius: radius),
        -0.45 * 3.14159,
        1.35 * 3.14159,
      );
    canvas.drawPath(path, paint);

    // İkinci iç arc (derinlik)
    final inner = Paint()
      ..color = DesignTokens.antiqueGold.withOpacity(0.02)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    canvas.drawPath(
      Path()
        ..addArc(
          Rect.fromCircle(center: center, radius: radius * 0.7),
          -0.3 * 3.14159,
          1.1 * 3.14159,
        ),
      inner,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
