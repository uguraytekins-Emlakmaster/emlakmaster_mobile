import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/features/crm_customers/domain/customer_timeline_intelligence.dart';
import 'package:emlakmaster_mobile/features/crm_customers/presentation/providers/customer_insight_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Üç satırlık canlı özet: son temas → şimdi → sonraki (detay bloklarını silmez).
class CustomerTimelineIntelligenceStrip extends ConsumerWidget {
  const CustomerTimelineIntelligenceStrip({super.key, required this.customerId});

  final String customerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ext = AppThemeExtension.of(context);
    final async = ref.watch(customerInsightProvider(customerId));
    return async.when(
      data: (insight) {
        final lines = buildCustomerTimelineIntelligenceLines(insight);
        if (!lines.hasAny) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(bottom: DesignTokens.space4),
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
                  ext.surface.withValues(alpha: 0.92),
                ],
              ),
              border: Border.all(color: ext.accent.withValues(alpha: 0.35)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.hub_rounded, size: 18, color: ext.accent),
                    const SizedBox(width: 8),
                    Text(
                      'Müşteri özeti',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: ext.textPrimary,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.3,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (lines.recentTouchpointLine != null &&
                    lines.recentTouchpointLine!.trim().isNotEmpty)
                  _TimelineRow(
                    icon: Icons.schedule_rounded,
                    label: 'Son',
                    text: lines.recentTouchpointLine!,
                    ext: ext,
                  ),
                if (lines.currentStatusLine != null &&
                    lines.currentStatusLine!.trim().isNotEmpty) ...[
                  if (lines.recentTouchpointLine != null &&
                      lines.recentTouchpointLine!.trim().isNotEmpty)
                    const SizedBox(height: 8),
                  _TimelineRow(
                    icon: Icons.bolt_rounded,
                    label: 'Şimdi',
                    text: lines.currentStatusLine!,
                    ext: ext,
                  ),
                ],
                if (lines.nextActionLine != null &&
                    lines.nextActionLine!.trim().isNotEmpty) ...[
                  if ((lines.recentTouchpointLine != null &&
                          lines.recentTouchpointLine!.trim().isNotEmpty) ||
                      (lines.currentStatusLine != null &&
                          lines.currentStatusLine!.trim().isNotEmpty))
                    const SizedBox(height: 8),
                  _TimelineRow(
                    icon: Icons.arrow_circle_right_outlined,
                    label: 'Sonraki',
                    text: lines.nextActionLine!,
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
            padding: const EdgeInsets.only(bottom: DesignTokens.space4),
            child: Text(
              'Müşteri özeti yüklenemedi.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: ext.textTertiary,
                    height: 1.35,
                  ),
            ),
          ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({
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
        Icon(icon, size: 16, color: ext.accent.withValues(alpha: 0.9)),
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
                      letterSpacing: 0.4,
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
