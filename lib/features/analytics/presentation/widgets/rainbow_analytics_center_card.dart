import 'package:emlakmaster_mobile/core/intelligence/intelligence_providers.dart';
import 'package:emlakmaster_mobile/core/router/app_router.dart';
import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/app_typography.dart';
import 'package:emlakmaster_mobile/core/theme/dashboard_layout_tokens.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/features/analytics/presentation/providers/investment_opportunity_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';

/// Dashboard giriş kartı — fazlar (iskelet / canlı / önbellek / düşük güvenilirlik / hata),
/// tam kart shimmer yok; içerik her zaman kasıtlı.
class RainbowAnalyticsCenterCard extends ConsumerWidget {
  /// [paddedContentWidth]: [px] sonrası yatay içerik genişliği verilirse iç [LayoutBuilder]
  /// atlanır (scroll + iç içe layout assert riskini azaltır).
  const RainbowAnalyticsCenterCard({super.key, this.paddedContentWidth});

  final double? paddedContentWidth;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ext = AppThemeExtension.of(context);
    final theme = Theme.of(context);
    final ui = ref.watch(analyticsCenterCardUiProvider);

    final radius = BorderRadius.circular(DashboardLayoutTokens.radiusCardL);
    return Semantics(
      button: true,
      label: 'Analitik merkezi — bölge ve yatırım içgörüsüne git',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: radius,
          splashColor: ext.accent.withValues(alpha: 0.1),
          onTap: () => context.push(AppRouter.routeRainbowAnalytics),
          child: RepaintBoundary(
            child: Container(
              width: double.infinity,
              decoration: ext.premiumSurfaceDecoration(
                goldBorder: true,
                radius: DashboardLayoutTokens.radiusCardL,
              ),
              child: ClipRRect(
                borderRadius: radius,
                child: Stack(
                  children: [
                    Positioned(
                      left: 0,
                      right: 0,
                      top: 0,
                      height: 3,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              ext.accent.withValues(alpha: 0.9),
                              ext.accent.withValues(alpha: 0.1),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        DesignTokens.space5,
                        DesignTokens.space5 + 4,
                        DesignTokens.space5,
                        DesignTokens.space5,
                      ),
                      child: _RainbowCardInnerRow(
                        ui: ui,
                        ext: ext,
                        theme: theme,
                        ref: ref,
                        precomputedInnerMaxWidth: paddedContentWidth != null
                            ? paddedContentWidth! - 2 * DesignTokens.space5
                            : null,
                      ),
                    ),
                  ],
                ),
              ),
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

class _RainbowCardInnerRow extends StatelessWidget {
  const _RainbowCardInnerRow({
    required this.ui,
    required this.ext,
    required this.theme,
    required this.ref,
    this.precomputedInnerMaxWidth,
  });

  final AnalyticsCenterCardUi ui;
  final AppThemeExtension ext;
  final ThemeData theme;
  final WidgetRef ref;
  final double? precomputedInnerMaxWidth;

  Widget _row(BuildContext context, bool narrow) {
    final titleSize =
        narrow ? DesignTokens.fontSizeMd : DesignTokens.fontSizeLg;
    final iconSize = narrow ? 26.0 : 30.0;
    final iconPad = narrow ? 11.0 : 14.0;
    final phase = _PhaseChip(
      phase: ui.phase,
      ext: ext,
      theme: theme,
    );
    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Analitik merkezi',
          style: AppTypography.cardHeading(context).copyWith(
            color: ext.textPrimary,
            fontSize: titleSize,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Bölge talebi ve yatırım ufkunu aç',
          style: AppTypography.meta(context).copyWith(
            color: ext.textTertiary,
            fontWeight: FontWeight.w600,
          ),
          maxLines: narrow ? 2 : 1,
          overflow: TextOverflow.ellipsis,
        ),
        SizedBox(height: narrow ? DesignTokens.space2 : DesignTokens.space3),
        if (narrow) ...[
          Text(
            'Rainbow Intelligence',
            style: theme.textTheme.titleSmall?.copyWith(
              color: ext.accent,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.1,
              fontSize: DesignTokens.fontSizeSm + 1,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: DesignTokens.space2),
          Align(
            alignment: Alignment.centerLeft,
            child: phase,
          ),
        ] else
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  'Rainbow Intelligence',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: ext.accent,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.12,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              phase,
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
            onRetry: () => RainbowAnalyticsCenterCard._retry(ref),
          ),
        ),
      ],
    );
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          label: 'Analitik merkezi simgesi',
          excludeSemantics: true,
          child: Container(
            padding: EdgeInsets.all(iconPad),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: ext.accent.withValues(alpha: 0.5)),
              color: ext.accent.withValues(alpha: 0.08),
            ),
            child:
                Icon(Icons.insights_rounded, color: ext.accent, size: iconSize),
          ),
        ),
        const SizedBox(width: DesignTokens.space4),
        Expanded(child: body),
        Semantics(
          label: 'Detaya git',
          excludeSemantics: true,
          child: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Icon(
              Icons.chevron_right_rounded,
              color: ext.accent.withValues(alpha: 0.85),
              size: narrow ? 22 : 26,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final pre = precomputedInnerMaxWidth;
    if (pre != null) {
      return _row(context, pre < 340);
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        return _row(context, constraints.maxWidth < 340);
      },
    );
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
        return Semantics(
          label: 'Veri durumu yükleniyor',
          child: const SizedBox(
            width: 36,
            height: 22,
          ),
        );
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
        label = 'Genel profil';
        bg = ext.textTertiary.withValues(alpha: 0.28);
        fg = ext.textSecondary;
      case AnalyticsCenterCardPhase.error:
        label = 'Hata';
        bg = ext.danger.withValues(alpha: 0.14);
        fg = ext.danger;
    }

    return Semantics(
      label: 'Veri durumu: $label',
      child: Padding(
        padding: const EdgeInsets.only(left: DesignTokens.space2),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          constraints: const BoxConstraints(minHeight: 28),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(DesignTokens.radiusPill),
            border: Border.all(color: fg.withValues(alpha: 0.35)),
          ),
          alignment: Alignment.center,
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
