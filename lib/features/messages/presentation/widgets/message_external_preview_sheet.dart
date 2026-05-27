import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/premium/premium_theme_extension.dart';
import 'package:emlakmaster_mobile/features/messages/presentation/utils/message_conversation_list_filter.dart';
import 'package:emlakmaster_mobile/widgets/premium_bottom_sheet_shell.dart';
import 'package:flutter/material.dart';

/// Harici kanal — gönderim bağlı değil; sahte mesaj yok.
Future<void> showMessageExternalPreviewSheet(
  BuildContext context, {
  required MessagePlatformFilter filter,
  VoidCallback? onConnectChannel,
}) {
  return showPremiumScrollableBottomSheet<void>(
    context: context,
    maxHeightFactor: 0.55,
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const PremiumBottomSheetHandle(),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                filter.label,
                style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ),
          ),
          _MessageExternalPreviewBody(
            filter: filter,
            onConnectChannel: onConnectChannel,
          ),
        ],
      ),
    ),
  );
}

class _MessageExternalPreviewBody extends StatelessWidget {
  const _MessageExternalPreviewBody({
    required this.filter,
    this.onConnectChannel,
  });

  final MessagePlatformFilter filter;
  final VoidCallback? onConnectChannel;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    final premium = PremiumThemeExtension.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: ext.warning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: ext.warning.withValues(alpha: 0.35)),
            ),
            child: Row(
              children: [
                Icon(Icons.visibility_outlined, color: ext.warning, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Önizleme modu — ${filter.label} gönderimi bağlı değil.',
                    style: TextStyle(
                      color: ext.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Mesaj gönderimi için kanal bağlantısı gerekli.',
            style: TextStyle(color: ext.textSecondary, height: 1.4, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(
            'Bu kanal için gönderim altyapısı hazırlanıyor. Ekip sohbeti (Tümü) canlıdır ve mesaj gönderebilirsiniz.',
            style: TextStyle(color: ext.textTertiary, height: 1.4, fontSize: 13),
          ),
          const SizedBox(height: 20),
          if (onConnectChannel != null)
            FilledButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                onConnectChannel!();
              },
              icon: const Icon(Icons.hub_outlined),
              label: const Text('Kanal bağla'),
              style: FilledButton.styleFrom(
                backgroundColor: premium.champagneGold,
                foregroundColor: ext.onBrand,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
        ],
      ),
    );
  }
}
