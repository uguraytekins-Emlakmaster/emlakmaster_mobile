import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/features/calls/domain/post_call_crm_signals.dart';
import 'package:emlakmaster_mobile/features/crm_customers/presentation/providers/customer_entity_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Müşteri detay: `lastCallSummarySignals` varsa kompakt premium blok.
class CustomerLastCallSignalsSection extends ConsumerWidget {
  const CustomerLastCallSignalsSection({super.key, required this.customerId});

  final String customerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ext = AppThemeExtension.of(context);
    final async = ref.watch(customerEntityByIdProvider(customerId));
    return async.when(
      data: (entity) {
        final s = entity?.lastCallSummarySignals;
        if (s == null) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(bottom: DesignTokens.space5),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(DesignTokens.space4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  ext.surfaceElevated,
                  ext.surface,
                ],
              ),
              border: Border.all(
                color: ext.accent.withValues(alpha: 0.28),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.22),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.insights_rounded, size: 20, color: ext.accent),
                    const SizedBox(width: DesignTokens.space2),
                    Expanded(
                      child: Text(
                        'Son Çağrı Sinyalleri',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: ext.textPrimary,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.2,
                            ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: DesignTokens.space3),
                Wrap(
                  spacing: DesignTokens.space2,
                  runSpacing: DesignTokens.space2,
                  children: [
                    _SignalChip(
                      label: 'İlgi',
                      value: postCallInterestLabelTr(s.interestLevel),
                      emphasis: s.interestLevel == PostCallCrmSignals.interestHigh,
                      color: ext.accent,
                      ext: ext,
                    ),
                    _SignalChip(
                      label: 'Takip',
                      value: postCallUrgencyLabelTr(s.followUpUrgency),
                      emphasis: s.followUpUrgency == PostCallCrmSignals.urgencyHigh,
                      color: s.followUpUrgency == PostCallCrmSignals.urgencyHigh
                          ? ext.warning
                          : ext.textSecondary,
                      ext: ext,
                    ),
                    _boolChip(
                      context,
                      ext,
                      'Randevu',
                      s.appointmentMentioned,
                      positiveColor: ext.success,
                    ),
                    _boolChip(
                      context,
                      ext,
                      'Fiyat itirazı',
                      s.priceObjection,
                      positiveColor: ext.warning,
                    ),
                  ],
                ),
                if (s.nextActionHint.isNotEmpty) ...[
                  const SizedBox(height: DesignTokens.space3),
                  Text(
                    s.nextActionHint,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: ext.textSecondary,
                          height: 1.4,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  static Widget _boolChip(
    BuildContext context,
    AppThemeExtension ext,
    String label,
    bool on, {
    required Color positiveColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: ext.surface.withValues(alpha: 0.9),
        border: Border.all(
          color: on ? positiveColor.withValues(alpha: 0.65) : ext.border.withValues(alpha: 0.5),
        ),
      ),
      child: Text(
        '$label · ${on ? 'Evet' : 'Hayır'}',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: on ? positiveColor : ext.textTertiary,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

class _SignalChip extends StatelessWidget {
  const _SignalChip({
    required this.label,
    required this.value,
    required this.emphasis,
    required this.color,
    required this.ext,
  });

  final String label;
  final String value;
  final bool emphasis;
  final Color color;
  final AppThemeExtension ext;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: emphasis ? color.withValues(alpha: 0.14) : ext.surface.withValues(alpha: 0.85),
        border: Border.all(
          color: emphasis ? color.withValues(alpha: 0.45) : ext.border.withValues(alpha: 0.45),
        ),
      ),
      child: Text(
        '$label · $value',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: emphasis ? color : ext.textSecondary,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}
