import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/features/crm_customers/domain/customer_next_best_action.dart';
import 'package:emlakmaster_mobile/features/crm_customers/presentation/providers/customer_insight_provider.dart';
import 'package:emlakmaster_mobile/features/crm_customers/presentation/utils/customer_detail_actions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Özet sekmesi: önerilen aksiyonu tek dokunuşla uygular.
class CustomerNextBestActionButton extends ConsumerWidget {
  const CustomerNextBestActionButton({super.key, required this.customerId});

  final String customerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ext = AppThemeExtension.of(context);
    final async = ref.watch(customerInsightProvider(customerId));
    return async.when(
      data: (insight) {
        final code = insight.nextBest.code;
        if (code == NextBestActionCode.nurture_sequence ||
            code == NextBestActionCode.wait_and_watch) {
          return const SizedBox.shrink();
        }
        return Padding(
          padding: const EdgeInsets.only(bottom: DesignTokens.space4),
          child: FilledButton.icon(
            onPressed: () => CustomerDetailActions.runNextBest(
              context,
              ref,
              customerId: customerId,
              code: code,
            ),
            icon: const Icon(Icons.bolt_rounded, size: 20),
            label: Text(insight.nextBest.labelTr),
            style: FilledButton.styleFrom(
              backgroundColor: ext.accent,
              foregroundColor: ext.onBrand,
              minimumSize: const Size(double.infinity, 44),
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
