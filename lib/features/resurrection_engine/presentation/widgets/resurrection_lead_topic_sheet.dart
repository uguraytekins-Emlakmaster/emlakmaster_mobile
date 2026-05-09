import 'package:emlakmaster_mobile/core/router/app_router.dart';
import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/app_typography.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/features/resurrection_engine/domain/entities/resurrection_segment.dart';
import 'package:emlakmaster_mobile/widgets/premium_bottom_sheet_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

/// Konu başlığına göre yeniden kazanım / sessiz lead paneli (tam sayfa yönlendirme yerine).
/// [topicTitle]: ekranın konusu — örn. "Takip listesi", "Fırsat radarı", "Yeniden kazanım kuyruğu".
void showResurrectionLeadTopicSheet(
  BuildContext context, {
  required String topicTitle,
  required ResurrectionQueueItem item,
}) {
  final ext = AppThemeExtension.of(context);
  final fg = ext.textPrimary;
  final muted = ext.textSecondary;

  final draft = item.suggestedMessagePlaceholder ??
      'Merhaba, sizin için uygun yeni seçeneklerimiz var. Müsait olduğunuzda görüşelim.';

  final meta = StringBuffer('${item.daysSilent ?? 0} gün sessiz');
  if (item.segment != null) {
    meta.write(' · ${item.segment!.label}');
  }

  showPremiumModalBottomSheet<void>(
    context: context,
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          DesignTokens.space5,
          DesignTokens.space2,
          DesignTokens.space5,
          MediaQuery.paddingOf(ctx).bottom + DesignTokens.space5,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            const PremiumBottomSheetHandle(),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.auto_awesome_outlined,
                  size: DesignTokens.iconLg,
                  color: ext.accent.withValues(alpha: 0.5),
                ),
                const SizedBox(width: DesignTokens.space3),
                Expanded(
                  child: PremiumSheetHeader(
                    compact: true,
                    title: item.customerName ?? item.customerId,
                    subtitle: '$topicTitle · $meta',
                  ),
                ),
                IconButton(
                  tooltip: 'Kapat',
                  style: IconButton.styleFrom(
                    foregroundColor: ext.textTertiary,
                  ),
                  onPressed: () => Navigator.pop(ctx),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            if (item.primaryPhone != null && item.primaryPhone!.isNotEmpty) ...[
              const SizedBox(height: DesignTokens.space2),
              Text(
                item.primaryPhone!,
                style: AppTypography.bodyStrong(context).copyWith(
                  color: muted,
                  fontSize: DesignTokens.fontSizeBase,
                ),
              ),
            ],
            const SizedBox(height: DesignTokens.space5),
            Text(
              'Önerilen mesaj taslağı',
              style: AppTypography.cardHeading(context).copyWith(
                fontSize: DesignTokens.fontSizeSm,
                color: fg,
              ),
            ),
            const SizedBox(height: DesignTokens.space2),
            DecoratedBox(
              decoration: BoxDecoration(
                color: ext.surfaceElevated.withValues(alpha: 0.65),
                borderRadius: BorderRadius.circular(DesignTokens.radiusControl),
                border: Border.all(color: ext.border.withValues(alpha: 0.4)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(DesignTokens.space4),
                child: Text(
                  draft,
                  style: AppTypography.body(context).copyWith(
                    height: 1.45,
                    fontSize: DesignTokens.fontSizeSm,
                  ),
                ),
              ),
            ),
            const SizedBox(height: DesignTokens.space4),
            OutlinedButton.icon(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: draft));
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(
                      content: const Text('Taslak panoya kopyalandı'),
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: ext.accent,
                    ),
                  );
                }
              },
              icon: Icon(Icons.copy_rounded,
                  size: DesignTokens.iconMd, color: fg),
              label: Text('Taslağı kopyala', style: TextStyle(color: fg)),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(DesignTokens.radiusControl),
                ),
                side: BorderSide(color: ext.borderSubtle),
              ),
            ),
            const SizedBox(height: DesignTokens.space3),
            FilledButton.icon(
              onPressed: () {
                Navigator.pop(ctx);
                HapticFeedback.mediumImpact();
                context.push(
                  AppRouter.routeCall,
                  extra: {
                    'customerId': item.customerId,
                    if (item.primaryPhone != null) 'phone': item.primaryPhone,
                    'startedFromScreen': 'resurrection_topic',
                  },
                );
              },
              icon: Icon(
                Icons.phone_in_talk_rounded,
                size: DesignTokens.iconMd,
                color: ext.onBrand,
              ),
              label: const Text('Telefon ile ara'),
              style: FilledButton.styleFrom(
                backgroundColor: ext.accent,
                foregroundColor: ext.onBrand,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(DesignTokens.radiusControl),
                ),
              ),
            ),
            const SizedBox(height: DesignTokens.space2),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                context.push(
                  AppRouter.routeCustomerDetail
                      .replaceFirst(':id', item.customerId),
                );
              },
              child: Text(
                'Müşteri kartını aç',
                style: AppTypography.bodyStrong(context).copyWith(
                  color: ext.accent,
                  fontSize: DesignTokens.fontSizeSm,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
