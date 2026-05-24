import 'package:emlakmaster_mobile/core/copy/product_labels.dart';
import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/l10n/app_localizations.dart';
import 'package:emlakmaster_mobile/core/router/app_router.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/core/theme/premium/premium_theme_extension.dart';
import 'package:emlakmaster_mobile/shared/widgets/empty_state.dart';
import 'package:emlakmaster_mobile/widgets/premium/premium_ui_kit.dart';
import 'package:emlakmaster_mobile/widgets/premium/v2/premium_shell_chrome.dart';
import 'package:go_router/go_router.dart';
import 'package:emlakmaster_mobile/core/performance/shell_screen_ready_tracker.dart';
import 'package:emlakmaster_mobile/features/resurrection_engine/presentation/providers/resurrection_queue_provider.dart';
import 'package:emlakmaster_mobile/features/resurrection_engine/presentation/widgets/resurrection_lead_topic_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emlakmaster_mobile/core/feedback/app_feedback.dart';

/// Danışman paneli – Takip: sessiz lead listesi (7/14/30+ gün), yeniden kazanım kuyruğu.
class ConsultantResurrectionPage extends ConsumerWidget {
  const ConsultantResurrectionPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ShellScreenReadyListener(
      screenName: 'follow_up',
      provider: resurrectionQueueProvider,
      itemCount: (v) => (v as List).length,
      child: const _FollowUpBody(),
    );
  }
}

class _FollowUpBody extends ConsumerWidget {
  const _FollowUpBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ext = AppThemeExtension.of(context);
    final premium = PremiumThemeExtension.of(context);
    final resurrectionAsync = ref.watch(resurrectionQueueProvider);
    return PremiumShellBackdrop(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const PremiumPageHeader(
                title: ProductLabels.followUp,
                subtitle: 'Sessiz lead’ler — yeniden temas fırsatları.',
              ),
              Expanded(
                child: resurrectionAsync.when(
                  data: (items) {
                    if (items.isEmpty) {
                      final l10n = AppLocalizations.of(context);
                      return Center(
                        child: EmptyState(
                          premiumVisual: true,
                          icon: Icons.track_changes_rounded,
                          title: l10n.t('empty_followup_title'),
                          subtitle: l10n.t('empty_followup_sub'),
                          actionLabel: l10n.t('empty_followup_cta'),
                          onAction: () => context.push(
                            AppRouter.routeCall,
                            extra: const {
                              'startedFromScreen': 'consultant_resurrection',
                            },
                          ),
                        ),
                      );
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(
                        DesignTokens.space5,
                        0,
                        DesignTokens.space5,
                        DesignTokens.space6,
                      ),
                      itemCount: items.length,
                      cacheExtent: 300,
                      itemBuilder: (context, index) {
                        final e = items[index];
                        final name = e.customerName ?? e.customerId;
                        final days = e.daysSilent ?? 0;
                        return Padding(
                          padding: const EdgeInsets.only(
                            bottom: DesignTokens.space2,
                          ),
                          child: PremiumSurfaceCard(
                            onTap: () {
                              AppFeedback.lightImpact();
                              showResurrectionLeadTopicSheet(
                                context,
                                topicTitle: ProductLabels.followUp,
                                item: e,
                              );
                            },
                            padding: const EdgeInsets.all(DesignTokens.space4),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: premium.champagneGold
                                        .withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(
                                      DesignTokens.radiusSm,
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.person_outline_rounded,
                                    color: premium.champagneGold,
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: DesignTokens.space3),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        name,
                                        style: TextStyle(
                                          color: ext.textPrimary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        '$days gün sessiz',
                                        style: TextStyle(
                                          color: ext.textSecondary,
                                          fontSize: DesignTokens.fontSizeSm,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.chevron_right_rounded,
                                  size: 20,
                                  color: premium.champagneGoldMuted,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                  loading: () => Center(
                    child: CircularProgressIndicator(
                      color: premium.champagneGold,
                    ),
                  ),
                  error: (e, _) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.error_outline_rounded,
                            size: 48,
                            color: ext.danger,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Liste yüklenemedi.',
                            style: TextStyle(color: ext.textSecondary),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 20),
                          FilledButton.icon(
                            onPressed: () =>
                                ref.invalidate(resurrectionQueueProvider),
                            icon: const Icon(Icons.refresh_rounded, size: 20),
                            label: const Text('Tekrar dene'),
                            style: FilledButton.styleFrom(
                              backgroundColor: premium.champagneGold,
                              foregroundColor: ext.onBrand,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
