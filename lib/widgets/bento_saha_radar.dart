import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emlakmaster_mobile/core/services/app_lifecycle_power_service.dart';
import 'package:emlakmaster_mobile/core/services/firestore_service.dart';
import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:flutter/material.dart';

/// Diyarbakır ilçe adlarına göre sembolik harita üzerinde x,y oranları (0-1).
final Map<String, Offset> _districtPositions = {
  'Bağlar': const Offset(0.25, 0.55),
  'Kayapınar': const Offset(0.72, 0.35),
  'Sur': const Offset(0.5, 0.5),
  'Yenişehir': const Offset(0.45, 0.28),
  'Bismil': const Offset(0.82, 0.75),
  'Çınar': const Offset(0.35, 0.82),
  'Ergani': const Offset(0.18, 0.35),
  'Silvan': const Offset(0.65, 0.62),
  'Kocaköy': const Offset(0.15, 0.5),
  'Çüngüş': const Offset(0.22, 0.88),
};

class BentoSahaRadar extends StatelessWidget {
  /// [outerContentWidth] verildiğinde iç [LayoutBuilder] kullanılmaz (dashboard + scroll
  /// gövdesinde `!_debugDoingThisLayout` riskini azaltır).
  const BentoSahaRadar({
    super.key,
    this.outerContentWidth,
    this.splitWithSibling = false,
    this.siblingRowGap = 0,
  });

  /// [px] içi içerik genişliği (ekran − yatay padding × 2).
  final double? outerContentWidth;

  /// [true]: [Row] içinde eş genişlikte ikinci kartla paylaşılan satır (harita + heatmap yan yana).
  final bool splitWithSibling;

  /// [splitWithSibling] iken iki [Expanded] arası [SizedBox] genişliği.
  final double siblingRowGap;

  static bool _narrowFromOuter({
    required double? outer,
    required bool split,
    required double gap,
  }) {
    if (outer == null) return false;
    if (!split) return outer < 300;
    final cell = ((outer - gap).clamp(0, double.infinity)) / 2;
    return cell < 300;
  }

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirestoreService.agentsStream(),
      builder: (context, snapshot) {
        final agents = snapshot.hasData
            ? snapshot.data!.docs
            : <QueryDocumentSnapshot<Map<String, dynamic>>>[];
        final withLocation = agents.where((d) {
          final data = d.data();
          final city = data['locationCity'] as String?;
          final district = data['locationDistrict'] as String?;
          return (city != null && city.isNotEmpty) ||
              (district != null && district.isNotEmpty);
        }).toList();
        final subtitle = snapshot.hasData
            ? '${withLocation.length} danışman harita üzerinde'
            : 'Yükleniyor...';

        final mapArea = SizedBox(
          height: 160,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
                color: ext.surfaceElevated,
                border: Border.all(color: ext.accent.withValues(alpha: 0.12)),
              ),
              child: snapshot.hasData
                  ? CustomPaint(
                      painter: DiyarbakirMapPainter(
                        agents: withLocation,
                        accent: ext.accent,
                        borderStroke: ext.foreground.withValues(alpha: 0.08),
                        labelMuted: ext.textTertiary.withValues(alpha: 0.25),
                      ),
                    )
                  : Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: ext.accent,
                      ),
                    ),
            ),
          ),
        );

        Widget columnForNarrow(bool narrow) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Saha-Radar',
                  style: TextStyle(
                    color: ext.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  style: TextStyle(color: ext.textTertiary, fontSize: 11),
                ),
                const SizedBox(height: 12),
                if (narrow) ...[
                  mapArea,
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 72,
                    width: double.infinity,
                    child: RepaintBoundary(child: _HeatmapPulseChart()),
                  ),
                ] else
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: mapArea),
                      const SizedBox(width: 10),
                      SizedBox(
                        width: 52,
                        height: 160,
                        child: RepaintBoundary(child: _HeatmapPulseChart()),
                      ),
                    ],
                  ),
              ],
            );

        final resolvedOuter = outerContentWidth;
        final inner = resolvedOuter != null
            ? columnForNarrow(
                _narrowFromOuter(
                  outer: resolvedOuter,
                  split: splitWithSibling,
                  gap: siblingRowGap,
                ),
              )
            : LayoutBuilder(
                builder: (context, constraints) {
                  return columnForNarrow(constraints.maxWidth < 300);
                },
              );

        return Container(
          decoration: ext.surfaceCardDecoration(
            surfaceColor: Color.alphaBlend(
              ext.foreground.withValues(alpha: 0.08),
              ext.surface,
            ),
          ),
          padding: const EdgeInsets.all(20),
          child: inner,
        );
      },
    );
  }
}

class DiyarbakirMapPainter extends CustomPainter {
  DiyarbakirMapPainter({
    required this.agents,
    required this.accent,
    required this.borderStroke,
    required this.labelMuted,
  });

  final List<QueryDocumentSnapshot<Map<String, dynamic>>> agents;
  final Color accent;
  final Color borderStroke;
  final Color labelMuted;

  @override
  void paint(Canvas canvas, Size size) {
    const padding = 12.0;
    final w = size.width - padding * 2;
    final h = size.height - padding * 2;
    const left = padding;
    const top = padding;

    // Sembolik Diyarbakır sınırı (yuvarlatılmış dikdörtgen + Dicle kıvrımı)
    final borderPath = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(left, top, w, h),
        const Radius.circular(20),
      ));
    canvas.drawPath(
      borderPath,
      Paint()
        ..color = borderStroke
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // İlçe isimleri için nokta pozisyonları; konumu olan danışmanları yeşil nokta yap
    const dotRadius = 6.0;
    final greenPaint = Paint()
      ..color = accent
      ..style = PaintingStyle.fill;
    final greenStroke = Paint()
      ..color = accent.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    for (final doc in agents) {
      final data = doc.data();
      final district = (data['locationDistrict'] as String?)?.trim();
      final city = (data['locationCity'] as String?)?.trim();
      if ((district == null || district.isEmpty) &&
          (city == null || city.isEmpty)) {
        continue;
      }

      final key =
          (district != null && district.isNotEmpty) ? district : (city ?? '');
      Offset? pos = _districtPositions[key];
      if (pos == null && key.isNotEmpty) {
        pos = _districtPositions.isNotEmpty
            ? _districtPositions.values.first
            : const Offset(0.5, 0.5);
      }
      if (pos == null) continue;

      final dx = left + w * pos.dx;
      final dy = top + h * pos.dy;
      canvas.drawCircle(Offset(dx, dy), dotRadius, greenStroke);
      canvas.drawCircle(Offset(dx, dy), dotRadius - 1, greenPaint);
    }

    // "Diyarbakır" etiketi
    final textPainter = TextPainter(
      text: TextSpan(
        text: 'Diyarbakır',
        style: TextStyle(
          color: labelMuted,
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(
      canvas,
      Offset(
          left + w - textPainter.width - 8, top + h - textPainter.height - 6),
    );
  }

  @override
  bool shouldRepaint(covariant DiyarbakirMapPainter oldDelegate) {
    return oldDelegate.agents != agents ||
        oldDelegate.accent != accent ||
        oldDelegate.borderStroke != borderStroke ||
        oldDelegate.labelMuted != labelMuted;
  }
}

/// Heatmap Pulse: bölgede arama sıklığı trendi – Antique Gold çizgi grafik.
class _HeatmapPulseChart extends StatefulWidget {
  @override
  State<_HeatmapPulseChart> createState() => _HeatmapPulseChartState();
}

class _HeatmapPulseChartState extends State<_HeatmapPulseChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  static const List<double> _trendValues = [
    0.3,
    0.5,
    0.45,
    0.7,
    0.6,
    0.85,
    0.75,
    0.9,
    0.8
  ];

  void _syncAnimationState() {
    final reduce = AppLifecyclePowerService.shouldReduceMotion;
    if (reduce) {
      _controller.stop();
      _controller.value = 1;
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    AppLifecyclePowerService.isInBackground.addListener(_syncAnimationState);
    _syncAnimationState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncAnimationState();
  }

  @override
  void dispose() {
    AppLifecyclePowerService.isInBackground.removeListener(_syncAnimationState);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Arama',
          style: TextStyle(
            color: ext.accent.withValues(alpha: 0.9),
            fontSize: 9,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Expanded(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return CustomPaint(
                painter: _PulseLinePainter(
                  values: _trendValues,
                  phase: _controller.value * 6.28,
                  lineColor: ext.accent.withValues(alpha: 0.85),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _PulseLinePainter extends CustomPainter {
  _PulseLinePainter({
    required this.values,
    this.phase = 0,
    required this.lineColor,
  });
  final List<double> values;
  final double phase;
  final Color lineColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    final w = size.width;
    final h = size.height;
    final stepX = w / (values.length - 1);
    final path = Path();
    for (var i = 0; i < values.length; i++) {
      final x = i * stepX;
      final y = h - (values[i] * h * 0.85) - 4;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    final paint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _PulseLinePainter oldDelegate) {
    return oldDelegate.values != values ||
        oldDelegate.phase != phase ||
        oldDelegate.lineColor != lineColor;
  }
}
