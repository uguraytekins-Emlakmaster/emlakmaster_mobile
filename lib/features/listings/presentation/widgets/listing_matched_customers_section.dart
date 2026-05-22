import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/features/smart_matching_engine/presentation/providers/portfolio_match_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:emlakmaster_mobile/core/feedback/app_feedback.dart';

/// İlan detay — bütçe/bölge uyumlu müşteri önerileri.
class ListingMatchedCustomersSection extends ConsumerWidget {
  const ListingMatchedCustomersSection({super.key, required this.listingId});

  final String listingId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ext = AppThemeExtension.of(context);
    final async = ref.watch(topMatchedCustomersForListingProvider(listingId));

    return async.when(
      data: (matches) {
        if (matches.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Uygun müşteriler',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: ext.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: DesignTokens.space3),
            ...matches.map((m) {
              return Padding(
                padding: const EdgeInsets.only(bottom: DesignTokens.space2),
                child: Material(
                  color: ext.surfaceElevated,
                  borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                  child: InkWell(
                    borderRadius:
                        BorderRadius.circular(DesignTokens.radiusMd),
                    onTap: () {
                      AppFeedback.lightImpact();
                      context.push('/customer/${m.customerId}');
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(DesignTokens.space3),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  m.name,
                                  style: TextStyle(
                                    color: ext.textPrimary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (m.aiExplanation != null &&
                                    m.aiExplanation!.isNotEmpty)
                                  Text(
                                    m.aiExplanation!,
                                    style: TextStyle(
                                      color: ext.textTertiary,
                                      fontSize: 12,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: ext.accent.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${m.score.round()}',
                              style: TextStyle(
                                color: ext.accent,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.chevron_right_rounded,
                            color: ext.textTertiary,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ],
        );
      },
      loading: () => const SizedBox(
        height: 48,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
