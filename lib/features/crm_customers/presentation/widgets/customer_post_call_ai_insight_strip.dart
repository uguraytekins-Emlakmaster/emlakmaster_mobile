import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/features/calls/domain/post_call_ai_enrichment.dart';
import 'package:emlakmaster_mobile/features/crm_customers/presentation/providers/customer_entity_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Müşteri detay: son çağrıya ilişkin destekleyici içgörü (deterministik motoru değiştirmez).
class CustomerPostCallAiInsightStrip extends ConsumerWidget {
  const CustomerPostCallAiInsightStrip({super.key, required this.customerId});

  final String customerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ext = AppThemeExtension.of(context);
    final async = ref.watch(customerEntityByIdProvider(customerId));
    return async.when(
      data: (entity) {
        final ai = entity?.lastCallAiEnrichment;
        if (ai == null) return const SizedBox.shrink();
        final badge = ai.source == PostCallAiEnrichmentSource.cloud ? 'AI destekli' : 'Hızlı okuma';
        return Padding(
          padding: const EdgeInsets.only(bottom: DesignTokens.space4),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
              color: ext.surfaceElevated,
              border: Border.all(color: ext.accent.withValues(alpha: 0.28)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.auto_awesome_rounded, size: 18, color: ext.accent),
                    const SizedBox(width: 8),
                    Text(
                      'Görüşme içgörüsü',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: ext.textSecondary,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        color: ext.accent.withValues(alpha: 0.12),
                      ),
                      child: Text(
                        badge,
                        style: TextStyle(
                          color: ext.accent,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  ai.aiSummaryShortTr,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: ext.textPrimary,
                        height: 1.35,
                      ),
                ),
                const SizedBox(height: 8),
                _t(context, ext, 'Ton', ai.aiCustomerMoodTr),
                _t(context, ext, 'İtiraz', ai.aiObjectionTypeTr),
                _t(context, ext, 'Takip', ai.aiFollowUpStyleTr),
                _t(context, ext, 'Not', ai.aiBrokerNoteTr),
              ],
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _t(BuildContext context, AppThemeExtension ext, String label, String value) {
    if (value.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: RichText(
        text: TextSpan(
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: ext.textTertiary,
                height: 1.3,
              ),
          children: [
            TextSpan(text: '$label · ', style: TextStyle(fontWeight: FontWeight.w700, color: ext.textSecondary)),
            TextSpan(text: value, style: TextStyle(color: ext.textTertiary, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}
