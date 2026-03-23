import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/shared/widgets/emlak_app_bar.dart';
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
    final bg = isDark ? DesignTokens.backgroundDark : DesignTokens.backgroundLight;
    final fg = isDark ? DesignTokens.textPrimaryDark : DesignTokens.textPrimaryLight;
    final surface = isDark ? DesignTokens.surfaceDark : DesignTokens.surfaceLight;
    final border = isDark ? DesignTokens.borderDark : DesignTokens.borderLight;
    final textSecondary = isDark ? DesignTokens.textSecondaryDark : DesignTokens.textSecondaryLight;
    final textTertiary = isDark ? DesignTokens.textTertiaryDark : DesignTokens.textTertiaryLight;
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
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.check_circle_outline_rounded,
                    size: 64,
                    color: DesignTokens.primary.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: DesignTokens.space4),
                  Text(
                    'Şu an takip edilecek lead yok',
                    style: TextStyle(
                      color: textSecondary,
                      fontSize: DesignTokens.fontSizeMd,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      '7 gün ve üzeri sessiz kalan müşteriler burada listelenir.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: textTertiary,
                        fontSize: DesignTokens.fontSizeSm,
                      ),
                    ),
                  ),
                ],
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
                      color: DesignTokens.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
                    ),
                    child: const Icon(
                      Icons.person_outline_rounded,
                      color: DesignTokens.primary,
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
        loading: () => const Center(
          child: CircularProgressIndicator(color: DesignTokens.primary),
        ),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  size: 48,
                  color: DesignTokens.danger,
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
                  style: FilledButton.styleFrom(backgroundColor: DesignTokens.primary),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
