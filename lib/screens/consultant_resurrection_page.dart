import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/l10n/app_localizations.dart';
import 'package:emlakmaster_mobile/core/router/app_router.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/shared/widgets/emlak_app_bar.dart';
import 'package:emlakmaster_mobile/shared/widgets/empty_state.dart';
import 'package:go_router/go_router.dart';
import 'package:emlakmaster_mobile/features/resurrection_engine/presentation/providers/resurrection_queue_provider.dart';
import 'package:emlakmaster_mobile/features/resurrection_engine/presentation/widgets/resurrection_lead_topic_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
/// Danışman paneli – Takip: sessiz lead listesi (7/14/30+ gün), yeniden kazanım kuyruğu.
class ConsultantResurrectionPage extends ConsumerWidget {
  const ConsultantResurrectionPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bg = isDark ? AppThemeExtension.of(context).background : AppThemeExtension.of(context).background;
    final fg = isDark ? AppThemeExtension.of(context).textPrimary : AppThemeExtension.of(context).textPrimary;
    final surface = isDark ? AppThemeExtension.of(context).surface : AppThemeExtension.of(context).surface;
    final border = isDark ? AppThemeExtension.of(context).border : AppThemeExtension.of(context).border;
    final textSecondary = isDark ? AppThemeExtension.of(context).textSecondary : AppThemeExtension.of(context).textSecondary;
    final textTertiary = isDark ? AppThemeExtension.of(context).textTertiary : AppThemeExtension.of(context).textTertiary;
    final resurrectionAsync = ref.watch(resurrectionQueueProvider);
    return Scaffold(
      backgroundColor: bg,
      appBar: emlakAppBar(
        context,
        backgroundColor: theme.appBarTheme.backgroundColor ?? bg,
        foregroundColor: theme.appBarTheme.foregroundColor ?? fg,
        title: const Text('Takip listesi'),
      ),
      body: resurrectionAsync.when(
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
                onAction: () => context.push(AppRouter.routeCall),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(DesignTokens.space4),
            itemCount: items.length,
            cacheExtent: 300,
            itemBuilder: (context, index) {
              final e = items[index];
              final name = e.customerName ?? e.customerId;
              final days = e.daysSilent ?? 0;
              return Container(
                margin: const EdgeInsets.only(bottom: DesignTokens.space2),
                padding: const EdgeInsets.all(DesignTokens.space4),
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                  border: Border.all(color: border),
                ),
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppThemeExtension.of(context).accent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
                    ),
                    child: Icon(
                      Icons.person_outline_rounded,
                      color: AppThemeExtension.of(context).accent,
                      size: 22,
                    ),
                  ),
                  title: Text(
                    name,
                    style: TextStyle(
                      color: fg,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    '$days gün sessiz',
                    style: TextStyle(
                      color: textSecondary,
                      fontSize: DesignTokens.fontSizeSm,
                    ),
                  ),
                  trailing: Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: textTertiary,
                  ),
                  onTap: () {
                    HapticFeedback.lightImpact();
                    showResurrectionLeadTopicSheet(
                      context,
                      topicTitle: 'Takip listesi',
                      item: e,
                    );
                  },
                ),
              );
            },
          );
        },
        loading: () => Center(
          child: CircularProgressIndicator(color: AppThemeExtension.of(context).accent),
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
                  color: AppThemeExtension.of(context).danger,
                ),
                const SizedBox(height: 16),
                Text(
                  'Liste yüklenemedi.',
                  style: TextStyle(color: textSecondary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: () => ref.invalidate(resurrectionQueueProvider),
                  icon: const Icon(Icons.refresh_rounded, size: 20),
                  label: const Text('Tekrar dene'),
                  style: FilledButton.styleFrom(backgroundColor: AppThemeExtension.of(context).accent),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
