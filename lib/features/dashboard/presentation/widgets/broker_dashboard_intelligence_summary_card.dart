import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/app_typography.dart';
import 'package:emlakmaster_mobile/core/theme/dashboard_layout_tokens.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/features/dashboard/domain/broker_dashboard_intelligence_summary.dart';
import 'package:emlakmaster_mobile/features/dashboard/presentation/providers/broker_dashboard_intelligence_summary_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Operasyon özeti — detay kartlarının üstünde tek hikâye.
class BrokerDashboardIntelligenceSummaryCard extends ConsumerWidget {
  const BrokerDashboardIntelligenceSummaryCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ext = AppThemeExtension.of(context);
    final async = ref.watch(brokerDashboardIntelligenceSummaryProvider);
    return async.when(
      data: (BrokerDashboardIntelligenceLines lines) {
        if (!lines.hasAny) {
          return Padding(
            padding: const EdgeInsets.only(bottom: DesignTokens.space5),
            child: _CommandCardFrame(
              ext: ext,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _CommandCardHeader(
                    ext: ext,
                    title: 'Ofis komuta özeti',
                    subtitle: 'Sistem kontrolü',
                  ),
                  const SizedBox(height: DesignTokens.space3),
                  Text(
                    'Şu an özet satırı yok; veri akışı izleniyor ve sakin bir tablo görünüyorsunuz. '
                    'Kritik sinyaller oluştuğunda burada tek bakışta listelenir.',
                    style: AppTypography.body(context).copyWith(
                      color: ext.textTertiary,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        return Padding(
          padding: const EdgeInsets.only(bottom: DesignTokens.space5),
          child: _CommandCardFrame(
            ext: ext,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _CommandCardHeader(
                  ext: ext,
                  title: 'Ofis komuta özeti',
                  subtitle: 'Canlı ofis hikâyesi',
                ),
                const SizedBox(height: DesignTokens.space4),
                if (lines.recentLine != null && lines.recentLine!.trim().isNotEmpty)
                  _Row(
                    icon: Icons.update_rounded,
                    label: 'Son',
                    text: lines.recentLine!,
                    ext: ext,
                  ),
                if (lines.criticalLine != null && lines.criticalLine!.trim().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _Row(
                    icon: Icons.warning_amber_rounded,
                    label: 'Kritik',
                    text: lines.criticalLine!,
                    ext: ext,
                  ),
                ],
                if (lines.nextLine != null && lines.nextLine!.trim().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _Row(
                    icon: Icons.arrow_circle_right_outlined,
                    label: 'Sonraki',
                    text: lines.nextLine!,
                    ext: ext,
                  ),
                ],
                if (lines.teamFocusLine != null && lines.teamFocusLine!.trim().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _Row(
                    icon: Icons.groups_rounded,
                    label: 'Takım odağı',
                    text: lines.teamFocusLine!,
                    ext: ext,
                  ),
                ],
              ],
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => Padding(
            padding: const EdgeInsets.only(bottom: DesignTokens.space3),
            child: Text(
              'Komuta özeti şu an yüklenemedi; bir süre sonra yenileyin.',
              style: AppTypography.body(context).copyWith(
                    color: ext.textTertiary,
                  ),
            ),
          ),
    );
  }
}

class _CommandCardFrame extends StatelessWidget {
  const _CommandCardFrame({
    required this.ext,
    required this.child,
  });

  final AppThemeExtension ext;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(DashboardLayoutTokens.radiusCardL);
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: radius,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            ext.surfaceElevated,
            ext.surface.withValues(alpha: 0.92),
          ],
        ),
        border: Border.all(color: ext.accent.withValues(alpha: 0.38)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
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
                      ext.accent.withValues(alpha: 0.85),
                      ext.accent.withValues(alpha: 0.12),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                DesignTokens.space5,
                DesignTokens.space5 + 2,
                DesignTokens.space5,
                DesignTokens.space5,
              ),
              child: child,
            ),
          ],
        ),
      ),
    );
  }
}

class _CommandCardHeader extends StatelessWidget {
  const _CommandCardHeader({
    required this.ext,
    required this.title,
    required this.subtitle,
  });

  final AppThemeExtension ext;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(DesignTokens.space3),
          decoration: BoxDecoration(
            color: ext.accent.withValues(alpha: 0.1),
            borderRadius:
                BorderRadius.circular(DashboardLayoutTokens.radiusCardS),
          ),
          child: Icon(Icons.apartment_rounded,
              size: 22, color: ext.accent),
        ),
        const SizedBox(width: DesignTokens.space3),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTypography.cardHeading(context).copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: AppTypography.meta(context).copyWith(
                  color: ext.textTertiary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.icon,
    required this.label,
    required this.text,
    required this.ext,
  });

  final IconData icon;
  final String label;
  final String text;
  final AppThemeExtension ext;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: ext.accent.withValues(alpha: 0.9)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTypography.metricLabel(context).copyWith(
                  color: ext.textTertiary,
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                text,
                style: AppTypography.body(context).copyWith(
                  color: ext.textSecondary,
                  height: 1.42,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
