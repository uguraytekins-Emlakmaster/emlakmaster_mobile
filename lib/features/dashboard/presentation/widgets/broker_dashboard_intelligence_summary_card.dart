import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
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
        if (!lines.hasAny) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(bottom: DesignTokens.space5),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  ext.surfaceElevated,
                  ext.surface.withValues(alpha: 0.94),
                ],
              ),
              border: Border.all(color: ext.accent.withValues(alpha: 0.42)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.14),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.hub_outlined, size: 20, color: ext.accent),
                    const SizedBox(width: 8),
                    Text(
                      'Operasyon özeti',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: ext.textPrimary,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.2,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
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
              'Operasyon özeti yüklenemedi.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: ext.textTertiary,
                  ),
            ),
          ),
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
        Icon(icon, size: 16, color: ext.accent.withValues(alpha: 0.92)),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: ext.textTertiary,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.35,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                text,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: ext.textSecondary,
                      height: 1.38,
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
