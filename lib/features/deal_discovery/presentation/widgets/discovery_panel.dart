import 'dart:math' as math;

import 'package:emlakmaster_mobile/core/constants/app_constants.dart';
import 'package:emlakmaster_mobile/core/intelligence/intelligence_providers.dart';
import 'package:emlakmaster_mobile/core/intelligence/intelligence_score_models.dart';
import 'package:emlakmaster_mobile/core/router/app_router.dart';
import 'package:emlakmaster_mobile/core/services/app_lifecycle_power_service.dart';
import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/features/auth/domain/permissions/feature_permission.dart';
import 'package:emlakmaster_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:emlakmaster_mobile/shared/widgets/error_state.dart';
import 'package:emlakmaster_mobile/shared/widgets/skeleton_loader.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
/// Dashboard: "Bugün keşfedilen fırsatlar" — geniş başlık, yarım daire skor göstergesi, madde detayları.
class DiscoveryPanel extends ConsumerWidget {
  const DiscoveryPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ext = AppThemeExtension.of(context);
    final role = ref.watch(displayRoleOrNullProvider);
    if (role == null || !FeaturePermission.canViewOpportunityRadar(role)) {
      return const SizedBox.shrink();
    }
    final async = ref.watch(discoveryItemsProvider);
    final minPct = (AppConstants.opportunityRadarMinScore * 100).round();

    return Container(
      padding: const EdgeInsets.fromLTRB(
        DesignTokens.space4,
        DesignTokens.space5,
        DesignTokens.space4,
        DesignTokens.space3,
      ),
      decoration: ext.surfaceCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _DiscoveryHeader(minScorePercent: minPct),
          const SizedBox(height: DesignTokens.space3),
          async.when(
            data: (items) {
              if (items.isEmpty) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        'Bu eşikte fırsat yok. Detay listesinde daha düşük skorluları görebilirsiniz.',
                        style: TextStyle(color: ext.textSecondary, fontSize: 12),
                      ),
                    ),
                    const _OpportunityRadarTeaser(),
                  ],
                );
              }
              return Column(
                children: [
                  _FluidOpportunitiesList(items: items),
                  const SizedBox(height: DesignTokens.space2),
                  const _OpportunityRadarTeaser(),
                ],
              );
            },
            loading: () => Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(
                children: List.generate(
                  3,
                  (_) => const Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        SkeletonLoader(
                          width: 48,
                          height: 32,
                          borderRadius: BorderRadius.all(Radius.circular(8)),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SkeletonLoader(
                                height: 13,
                                width: double.infinity,
                                borderRadius: BorderRadius.all(Radius.circular(4)),
                              ),
                              SizedBox(height: 4),
                              SkeletonLoader(
                                height: 11,
                                width: 100,
                                borderRadius: BorderRadius.all(Radius.circular(4)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            error: (e, _) => ErrorState(
              message: 'Fırsatlar yüklenemedi.',
              onRetry: () => ref.invalidate(discoveryItemsProvider),
            ),
          ),
        ],
      ),
    );
  }
}

/// Genişletilmiş üst alan: çift kıvılcım + başlık + eşik göstergesi (≥80 yarım daire).
class _DiscoveryHeader extends StatelessWidget {
  const _DiscoveryHeader({required this.minScorePercent});

  final int minScorePercent;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    final progress = AppConstants.opportunityRadarMinScore.clamp(0.0, 1.0);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Icon(Icons.auto_awesome_rounded, color: ext.accent, size: 26),
            Transform.translate(
              offset: const Offset(10, -6),
              child: Icon(Icons.auto_awesome_rounded, color: ext.accent, size: 18),
            ),
          ],
        ),
        const SizedBox(width: DesignTokens.space3),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bugün keşfedilen fırsatlar',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: ext.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 17,
                      height: 1.25,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                'Yüksek skor eşiğindeki segmentler',
                style: TextStyle(
                  color: ext.textTertiary,
                  fontSize: 12,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: DesignTokens.space2),
        SemicircleScoreGauge(
          progress: progress,
          label: '$minScorePercent+',
          size: 88,
          trackColor: ext.borderSubtle,
        ),
      ],
    );
  }
}

/// Yarım daire gauge: sarı → yeşil gradient dolgu, merkezde skor etiketi.
class SemicircleScoreGauge extends StatelessWidget {
  const SemicircleScoreGauge({
    super.key,
    required this.progress,
    required this.label,
    this.size = 72,
    this.trackColor,
  });

  final double progress;
  final String label;
  final double size;
  final Color? trackColor;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    final labelSize = size < 60 ? 11.0 : 15.0;
    return SizedBox(
      width: size,
      height: size * 0.62,
      child: CustomPaint(
        painter: _SemicircleGaugePainter(
          progress: progress.clamp(0.0, 1.0),
          trackColor: trackColor ?? ext.borderSubtle,
          warningColor: ext.warning,
          successColor: ext.success,
        ),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Text(
              label,
              style: TextStyle(
                color: ext.success,
                fontSize: labelSize,
                fontWeight: FontWeight.w800,
                height: 1,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SemicircleGaugePainter extends CustomPainter {
  _SemicircleGaugePainter({
    required this.progress,
    required this.trackColor,
    required this.warningColor,
    required this.successColor,
  });

  final double progress;
  final Color trackColor;
  final Color warningColor;
  final Color successColor;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    const stroke = 6.0;
    final center = Offset(w / 2, h);
    final radius = (w - stroke) / 2;
    const startAngle = math.pi;
    const sweep = math.pi;

    final trackPaint = Paint()
      ..color = trackColor.withValues(alpha: 0.65)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweep,
      false,
      trackPaint,
    );

    final prog = progress.clamp(0.0, 1.0);
    if (prog <= 0) return;

    final rect = Rect.fromCircle(center: center, radius: radius);
    final mid = Color.lerp(warningColor, successColor, 0.5)!;
    final grad = SweepGradient(
      startAngle: math.pi,
      colors: [
        warningColor,
        mid,
        successColor,
      ],
    ).createShader(rect);

    final fillPaint = Paint()
      ..shader = grad
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      rect,
      startAngle,
      sweep * prog,
      false,
      fillPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _SemicircleGaugePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.warningColor != warningColor ||
        oldDelegate.successColor != successColor;
  }
}

class _FluidOpportunitiesList extends StatefulWidget {
  const _FluidOpportunitiesList({required this.items});
  final List<DealDiscoveryItem> items;

  @override
  State<_FluidOpportunitiesList> createState() => _FluidOpportunitiesListState();
}

class _FluidOpportunitiesListState extends State<_FluidOpportunitiesList> {
  @override
  Widget build(BuildContext context) {
    final reduceMotion = AppLifecyclePowerService.shouldReduceMotion;
    return Column(
      children: [
        for (var i = 0; i < widget.items.length; i++)
          TweenAnimationBuilder<double>(
            key: ValueKey('${widget.items[i].title}_$i'),
            tween: Tween(begin: 0, end: 1),
            duration: reduceMotion
                ? DesignTokens.durationFast
                : (DesignTokens.durationNormal + Duration(milliseconds: 80 * (i + 1))),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              final opacity = reduceMotion ? 1.0 : value;
              final dy = reduceMotion ? 0.0 : 12 * (1 - value);
              return Opacity(
                opacity: opacity,
                child: Transform.translate(
                  offset: Offset(0, dy),
                  child: child,
                ),
              );
            },
            child: _DiscoveryOpportunityCard(item: widget.items[i]),
          ),
      ],
    );
  }
}

List<String> _bulletsFor(DealDiscoveryItem item) {
  if (item.highlights.isNotEmpty) return item.highlights;
  final pct = (item.score * 100).round();
  return [
    'Skor $pct+ — eşik üstü sinyal',
    'Segment trendiyle uyumlu',
  ];
}

class _DiscoveryOpportunityCard extends StatelessWidget {
  const _DiscoveryOpportunityCard({required this.item});
  final DealDiscoveryItem item;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    final bullets = _bulletsFor(item);

    return Padding(
      padding: const EdgeInsets.only(bottom: DesignTokens.space3),
      child: Container(
        padding: const EdgeInsets.all(DesignTokens.space3),
        decoration: BoxDecoration(
          color: Color.alphaBlend(
            ext.surfaceElevated.withValues(alpha: 0.85),
            ext.surface,
          ),
          borderRadius: BorderRadius.circular(DesignTokens.uiSurfaceRadius),
          border: Border.all(color: ext.success.withValues(alpha: 0.22)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title ?? 'Fırsat',
                    style: TextStyle(
                      color: ext.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (item.subtitle != null && item.subtitle!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      item.subtitle!,
                      style: TextStyle(
                        color: ext.textSecondary,
                        fontSize: 12,
                        height: 1.25,
                      ),
                      maxLines: 2,
                    ),
                  ],
                  const SizedBox(height: 8),
                  ...bullets.map(
                    (line) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '• ',
                            style: TextStyle(
                              color: ext.success,
                              fontSize: 13,
                              height: 1.35,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              line,
                              style: TextStyle(
                                color: ext.textSecondary,
                                fontSize: 12,
                                height: 1.35,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: DesignTokens.space2),
            SemicircleScoreGauge(
              progress: item.score.clamp(0.0, 1.0),
              label: '${(item.score * 100).round()}+',
              size: 52,
              trackColor: ext.borderSubtle,
            ),
          ],
        ),
      ),
    );
  }
}

/// Fırsat radarı / War Room ipucu — kartın altında derin analiz yolu.
class _OpportunityRadarTeaser extends StatelessWidget {
  const _OpportunityRadarTeaser();

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          context.push(AppRouter.routeWarRoom);
        },
        borderRadius: BorderRadius.circular(DesignTokens.uiSurfaceRadius),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.space3,
            vertical: DesignTokens.space3,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(DesignTokens.uiSurfaceRadius),
            border: Border.all(color: ext.success.withValues(alpha: 0.35)),
            gradient: LinearGradient(
              colors: [
                ext.success.withValues(alpha: 0.12),
                ext.surface.withValues(alpha: 0.3),
              ],
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.radar_rounded,
                color: ext.success.withValues(alpha: 0.95),
                size: 22,
              ),
              const SizedBox(width: DesignTokens.space3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Fırsat radarı',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: ext.success,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Lead sıcaklığı, yeniden kazanım ve derin analiz — War Room',
                      style: TextStyle(
                        color: ext.textTertiary.withValues(alpha: 0.95),
                        fontSize: 11,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: ext.success.withValues(alpha: 0.75),
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
