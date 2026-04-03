import 'package:emlakmaster_mobile/core/intelligence/intelligence_providers.dart';
import 'package:emlakmaster_mobile/core/router/app_router.dart';
import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/features/analytics/presentation/providers/investment_opportunity_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';

/// Dashboard giriş kartı — fazlar (iskelet / canlı / önbellek / düşük güvenilirlik / hata),
/// tam kart shimmer yok; içerik her zaman kasıtlı.
class RainbowAnalyticsCenterCard extends ConsumerWidget {
  const RainbowAnalyticsCenterCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ext = AppThemeExtension.of(context);
    final theme = Theme.of(context);
    final ui = ref.watch(analyticsCenterCardUiProvider);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(DesignTokens.radiusCardSecondary),
        onTap: () => context.push(AppRouter.routeRainbowAnalytics),
        child: RepaintBoundary(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(DesignTokens.space5),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(DesignTokens.radiusCardSecondary),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  ext.surfaceElevated,
                  Color.alphaBlend(
                    ext.foreground.withValues(alpha: 0.03),
                    ext.surface,
                  ),
                ],
              ),
              border: Border.all(color: ext.accent.withValues(alpha: 0.38)),
              boxShadow: [
                BoxShadow(
                  color: ext.shadowColor.withValues(alpha: 0.12),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: ext.accent.withValues(alpha: 0.45)),
                    color: ext.surface.withValues(alpha: 0.65),
                  ),
                  child: Icon(Icons.auto_graph_rounded, color: ext.accent, size: 28),
                ),
                const SizedBox(width: DesignTokens.space4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Rainbow Analytics Center',
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: ext.accent,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.15,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          _PhaseChip(phase: ui.phase, ext: ext, theme: theme),
                        ],
                      ),
                      const SizedBox(height: DesignTokens.space2),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 220),
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeInCubic,
                        child: _SubtitleBlock(
                          key: ValueKey<String>(
                            '${ui.phase}_${ui.pulseLine}_${ui.error?.hashCode ?? 0}',
                          ),
                          ui: ui,
                          ext: ext,
                          theme: theme,
                          onRetry: () => _retry(ref),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    color: ext.accent.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static void _retry(WidgetRef ref) {
    ref.invalidate(favoriteInvestRegionIdProvider);
    ref.invalidate(intelligenceRunTriggerProvider);
  }
}

class _PhaseChip extends StatelessWidget {
  const _PhaseChip({
    required this.phase,
    required this.ext,
    required this.theme,
  });

  final AnalyticsCenterCardPhase phase;
  final AppThemeExtension ext;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    late final String label;
    late final Color bg;
    late final Color fg;
    switch (phase) {
      case AnalyticsCenterCardPhase.loadingSkeleton:
        return const SizedBox.shrink();
      case AnalyticsCenterCardPhase.live:
        label = 'Canlı';
        bg = ext.success.withValues(alpha: 0.14);
        fg = ext.success;
      case AnalyticsCenterCardPhase.stale:
        label = 'Güncelleniyor';
        bg = ext.accent.withValues(alpha: 0.12);
        fg = ext.accent;
      case AnalyticsCenterCardPhase.degraded:
        label = 'Tahmini';
        bg = ext.warning.withValues(alpha: 0.14);
        fg = ext.warning;
      case AnalyticsCenterCardPhase.empty:
        label = 'Varsayılan';
        bg = ext.textTertiary.withValues(alpha: 0.35);
        fg = ext.textSecondary;
      case AnalyticsCenterCardPhase.error:
        label = 'Hata';
        bg = ext.danger.withValues(alpha: 0.14);
        fg = ext.danger;
    }

    return Padding(
      padding: const EdgeInsets.only(left: DesignTokens.space2),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(DesignTokens.radiusPill),
          border: Border.all(color: fg.withValues(alpha: 0.35)),
        ),
        child: Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: fg,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
            fontSize: DesignTokens.fontSizeXs,
          ),
        ),
      ),
    );
  }
}

class _SubtitleBlock extends StatelessWidget {
  const _SubtitleBlock({
    super.key,
    required this.ui,
    required this.ext,
    required this.theme,
    required this.onRetry,
  });

  final AnalyticsCenterCardUi ui;
  final AppThemeExtension ext;
  final ThemeData theme;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (ui.phase == AnalyticsCenterCardPhase.loadingSkeleton) {
      return _PremiumSubtitleSkeleton(ext: ext);
    }

    if (ui.phase == AnalyticsCenterCardPhase.error) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Yatırım endeksi şu an okunamadı. Bağlantıyı kontrol edip tekrar deneyin.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: ext.textSecondary,
              height: 1.35,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: DesignTokens.space2),
          TextButton.icon(
            onPressed: onRetry,
            style: TextButton.styleFrom(
              foregroundColor: ext.accent,
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            icon: Icon(Icons.refresh_rounded, size: 18, color: ext.accent),
            label: Text(
              'Yeniden dene',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: ext.accent,
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          ui.pulseLine,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: ext.textPrimary,
            fontSize: DesignTokens.fontSizeSm,
            height: 1.35,
            fontWeight: FontWeight.w600,
          ),
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
        if (ui.phase == AnalyticsCenterCardPhase.degraded) ...[
          const SizedBox(height: DesignTokens.space1),
          Text(
            'Isı haritası geçici olarak kullanılamıyor; genel bölge tahmini gösteriliyor.',
            style: theme.textTheme.labelSmall?.copyWith(
              color: ext.textTertiary,
              height: 1.3,
            ),
          ),
        ],
        if (ui.phase == AnalyticsCenterCardPhase.empty) ...[
          const SizedBox(height: DesignTokens.space1),
          Text(
            'Bölge verisi henüz gelmedi; genel profil kullanılıyor.',
            style: theme.textTheme.labelSmall?.copyWith(
              color: ext.textTertiary,
              height: 1.3,
            ),
          ),
        ],
      ],
    );
  }
}

/// Sadece alt metin alanı — ince, premium iskelet; kartın kendisi sabit.
class _PremiumSubtitleSkeleton extends StatelessWidget {
  const _PremiumSubtitleSkeleton({required this.ext});

  final AppThemeExtension ext;

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: ext.border.withValues(alpha: 0.45),
      highlightColor: ext.accent.withValues(alpha: 0.18),
      period: const Duration(milliseconds: 1600),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 13,
            width: double.infinity,
            decoration: BoxDecoration(
              color: ext.surfaceElevated,
              borderRadius: BorderRadius.circular(DesignTokens.radiusXs),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            height: 13,
            width: MediaQuery.sizeOf(context).width * 0.42,
            decoration: BoxDecoration(
              color: ext.surfaceElevated,
              borderRadius: BorderRadius.circular(DesignTokens.radiusXs),
            ),
          ),
        ],
      ),
    );
  }
}
