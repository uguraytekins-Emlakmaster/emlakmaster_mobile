import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'dart:math' as math;

import 'package:emlakmaster_mobile/core/intelligence/intelligence_score_models.dart';
import 'package:emlakmaster_mobile/core/intelligence/region_heatmap_defaults.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/shared/widgets/skeleton_loader.dart';
import 'package:flutter/material.dart';
export 'package:emlakmaster_mobile/core/intelligence/region_heatmap_defaults.dart'
    show marketPulseDefaultRegionScores;

/// Market Pulse — karşılaştırmalı bölge analizi: yatay kompakt kartlar + mini grafik.
class MarketPulseRegionComparisonStrip extends StatelessWidget {
  const MarketPulseRegionComparisonStrip({
    super.key,
    required this.regions,
    this.onRegionTap,
  });

  final List<RegionHeatmapScore> regions;
  final ValueChanged<RegionHeatmapScore>? onRegionTap;

  /// Yükleme iskeleti — üç kart genişliği.
  static Widget skeleton(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final border = isDark ? AppThemeExtension.of(context).border : AppThemeExtension.of(context).border;
    return Row(
      children: List.generate(
        3,
        (i) => Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: i < 2 ? 8 : 0),
            child: Container(
              height: 128,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
                border: Border.all(color: border.withValues(alpha: 0.35)),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonLoader(
                    width: 72,
                    height: 12,
                    borderRadius: BorderRadius.all(Radius.circular(4)),
                  ),
                  SizedBox(height: 8),
                  SkeletonLoader(
                    width: 48,
                    height: 10,
                    borderRadius: BorderRadius.all(Radius.circular(4)),
                  ),
                  Spacer(),
                  SkeletonLoader(
                    width: double.infinity,
                    height: 36,
                    borderRadius: BorderRadius.all(Radius.circular(6)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final list = regions.isEmpty ? marketPulseDefaultRegionScores : regions.take(3).toList();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < list.length; i++)
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: i < list.length - 1 ? 8 : 0),
              child: _RegionComparisonCard(
                region: list[i],
                onTap: onRegionTap != null ? () => onRegionTap!(list[i]) : null,
              ),
            ),
          ),
      ],
    );
  }
}

class _RegionComparisonCard extends StatelessWidget {
  const _RegionComparisonCard({
    required this.region,
    this.onTap,
  });

  final RegionHeatmapScore region;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textPrimary = isDark ? AppThemeExtension.of(context).textPrimary : AppThemeExtension.of(context).textPrimary;
    final textSecondary = isDark ? AppThemeExtension.of(context).textSecondary : AppThemeExtension.of(context).textSecondary;
    final textTertiary = isDark ? AppThemeExtension.of(context).textTertiary : AppThemeExtension.of(context).textTertiary;
    final border = isDark ? AppThemeExtension.of(context).border : AppThemeExtension.of(context).border;
    final pct = (region.demandScore * 100).clamp(0, 100).round();
    final range = region.budgetSegment ?? '—';
    final demand = region.demandScore.clamp(0.0, 1.0);
    final hotMarket = demand >= 0.55;

    final child = Container(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: isDark ? 0.08 : 0.85),
            Colors.white.withValues(alpha: isDark ? 0.02 : 0.45),
            AppThemeExtension.of(context).accent.withValues(alpha: isDark ? 0.07 : 0.12),
          ],
          stops: const [0.0, 0.55, 1.0],
        ),
        border: Border.all(color: border.withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Tooltip(
                message: hotMarket ? 'Sıcak pazar' : 'Durgun segment',
                child: Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(top: 2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: hotMarket ? AppThemeExtension.of(context).success : AppThemeExtension.of(context).warning,
                    boxShadow: [
                      BoxShadow(
                        color: (hotMarket ? AppThemeExtension.of(context).success : AppThemeExtension.of(context).warning)
                            .withValues(alpha: 0.45),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  region.regionName,
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            range,
            style: TextStyle(
              color: textTertiary,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Text(
                '%$pct',
                style: TextStyle(
                  color: region.demandScore >= 0.7 ? const Color(0xFF66BB6A) : textSecondary,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              const Spacer(),
              SizedBox(
                width: 40,
                height: 28,
                child: CustomPaint(
                  painter: _DominanceArcPainter(
                    fill: region.demandScore.clamp(0.0, 1.0),
                    trackColor: textTertiary.withValues(alpha: 0.25),
                    valueColor: AppThemeExtension.of(context).accent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          _HeatmapDemandBar(
            demand: demand,
            trackColor: textTertiary.withValues(alpha: 0.22),
          ),
          const SizedBox(height: 4),
          SizedBox(
            height: 22,
            width: double.infinity,
            child: CustomPaint(
              painter: _SparklinePainter(
                demandScore: region.demandScore.clamp(0.0, 1.0),
                lineColor: region.demandScore >= 0.7
                    ? const Color(0xFF43A047)
                    : AppThemeExtension.of(context).accent.withValues(alpha: 0.9),
                fillColor: (region.demandScore >= 0.7
                        ? const Color(0xFF43A047)
                        : AppThemeExtension.of(context).accent)
                    .withValues(alpha: 0.12),
              ),
            ),
          ),
        ],
      ),
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
        splashColor: AppThemeExtension.of(context).accent.withValues(alpha: 0.12),
        highlightColor: AppThemeExtension.of(context).accent.withValues(alpha: 0.06),
        child: Semantics(
          label:
              '${region.regionName}, fiyat bandı $range, talep yüzde $pct, ${hotMarket ? "sıcak" : "durgun"} pazar',
          button: onTap != null,
          child: child,
        ),
      ),
    );
  }
}

/// Talep skorunu milisaniyede okunur kılan ince ilerleme çubuğu (sarı → yeşil).
class _HeatmapDemandBar extends StatelessWidget {
  const _HeatmapDemandBar({
    required this.demand,
    required this.trackColor,
  });

  final double demand;
  final Color trackColor;

  @override
  Widget build(BuildContext context) {
    final raw = demand.isFinite ? demand : 0.0;
    final v = raw.clamp(0.0, 1.0);
    return Semantics(
      label: 'Talep doluluk yüzde ${(v * 100).round()}',
      child: SizedBox(
        height: 6,
        width: double.infinity,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(DesignTokens.radiusXs),
          child: Stack(
            fit: StackFit.expand,
            children: [
              ColoredBox(color: trackColor),
              Align(
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: v,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppThemeExtension.of(context).warning.withValues(alpha: 0.95),
                          AppThemeExtension.of(context).success.withValues(alpha: 0.92),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Yarım daire üzerinde talep oranı (pazar baskınlığı göstergesi).
class _DominanceArcPainter extends CustomPainter {
  _DominanceArcPainter({
    required this.fill,
    required this.trackColor,
    required this.valueColor,
  });

  final double fill;
  final Color trackColor;
  final Color valueColor;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 2, size.width, size.height * 2);
    const start = math.pi;
    const sweepTrack = math.pi;
    final sweepValue = sweepTrack * fill;

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final valuePaint = Paint()
      ..color = valueColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, start, sweepTrack, false, trackPaint);
    canvas.drawArc(rect, start, sweepValue, false, valuePaint);
  }

  @override
  bool shouldRepaint(covariant _DominanceArcPainter oldDelegate) {
    return oldDelegate.fill != fill ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.valueColor != valueColor;
  }
}

/// Hafif trend çizgisi (talep skoruna göre şekillenen mini seri).
class _SparklinePainter extends CustomPainter {
  _SparklinePainter({
    required this.demandScore,
    required this.lineColor,
    required this.fillColor,
  });

  final double demandScore;
  final Color lineColor;
  final Color fillColor;

  @override
  void paint(Canvas canvas, Size size) {
    const n = 6;
    final path = Path();
    final fillPath = Path();
    final w = size.width;
    final h = size.height;
    final base = 0.35 + 0.45 * demandScore;

    final points = <Offset>[];
    for (var i = 0; i < n; i++) {
      final t = i / (n - 1);
      final wave = 0.08 * math.sin(t * math.pi * 1.5 + demandScore * 3);
      final yNorm = (base + wave + 0.06 * math.sin(t * math.pi * 2.2)).clamp(0.15, 0.92);
      final x = w * t;
      final y = h * yNorm;
      points.add(Offset(x, y));
    }

    path.moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }

    fillPath.addPath(path, Offset.zero);
    fillPath.lineTo(w, h);
    fillPath.lineTo(0, h);
    fillPath.close();

    final fillPaint = Paint()..color = fillColor;
    canvas.drawPath(fillPath, fillPaint);

    final linePaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) {
    return oldDelegate.demandScore != demandScore ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.fillColor != fillColor;
  }
}
