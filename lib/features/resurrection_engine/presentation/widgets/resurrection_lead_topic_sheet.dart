import 'package:emlakmaster_mobile/core/router/app_router.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/features/resurrection_engine/domain/entities/resurrection_segment.dart';
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
  final theme = Theme.of(context);
  final isDark = theme.brightness == Brightness.dark;
  final surface = isDark ? DesignTokens.surfaceDark : DesignTokens.surfaceLight;
  final fg = theme.colorScheme.onSurface;
  final muted = fg.withValues(alpha: 0.72);

  final draft = item.suggestedMessagePlaceholder ??
      'Merhaba, sizin için uygun yeni seçeneklerimiz var. Müsait olduğunuzda görüşelim.';

  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(DesignTokens.radiusLg)),
    ),
    builder: (ctx) {
      return SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            left: DesignTokens.space5,
            right: DesignTokens.space5,
            top: DesignTokens.space4,
            bottom: MediaQuery.paddingOf(ctx).bottom + DesignTokens.space4,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: fg.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Text(
                  topicTitle,
                  style: const TextStyle(
                    color: DesignTokens.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  item.customerName ?? item.customerId,
                  style: TextStyle(
                    color: fg,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${item.daysSilent ?? 0} gün sessiz'
                  '${item.segment != null ? ' · ${item.segment!.label}' : ''}',
                  style: TextStyle(color: muted, fontSize: 14),
                ),
                if (item.primaryPhone != null && item.primaryPhone!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    item.primaryPhone!,
                    style: TextStyle(color: muted, fontSize: 13),
                  ),
                ],
                const SizedBox(height: DesignTokens.space5),
                Text(
                  'Önerilen mesaj taslağı',
                  style: TextStyle(color: fg, fontWeight: FontWeight.w700, fontSize: 13),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(DesignTokens.space4),
                  decoration: BoxDecoration(
                    color: fg.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                    border: Border.all(color: fg.withValues(alpha: 0.1)),
                  ),
                  child: Text(draft, style: TextStyle(color: muted, height: 1.45, fontSize: 13)),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: draft));
                    if (ctx.mounted) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(
                          content: Text('Taslak panoya kopyalandı'),
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: DesignTokens.primary,
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.copy_rounded, size: 18),
                  label: const Text('Taslağı kopyala'),
                  style: OutlinedButton.styleFrom(foregroundColor: fg),
                ),
                const SizedBox(height: DesignTokens.space4),
                FilledButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    HapticFeedback.mediumImpact();
                    context.push(
                      AppRouter.routeCall,
                      extra: {
                        'customerId': item.customerId,
                        if (item.primaryPhone != null) 'phone': item.primaryPhone,
                      },
                    );
                  },
                  icon: const Icon(Icons.phone_in_talk_rounded, size: 20),
                  label: const Text('Hemen ara (Magic Call)'),
                  style: FilledButton.styleFrom(
                    backgroundColor: DesignTokens.primary,
                    foregroundColor: DesignTokens.inputTextOnGold,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    context.push(
                      AppRouter.routeCustomerDetail.replaceFirst(':id', item.customerId),
                    );
                  },
                  child: const Text(
                    'Tam müşteri kartını aç',
                    style: TextStyle(color: DesignTokens.primary, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
