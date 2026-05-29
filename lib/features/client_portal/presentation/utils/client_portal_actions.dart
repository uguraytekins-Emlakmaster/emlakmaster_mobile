import 'package:emlakmaster_mobile/core/feedback/app_feedback.dart';
import 'package:emlakmaster_mobile/core/navigation/main_shell_shortcut_provider.dart';
import 'package:emlakmaster_mobile/core/theme/premium/premium_theme_extension.dart';
import 'package:emlakmaster_mobile/features/client_portal/presentation/data/client_portal_preview_catalog.dart';
import 'package:emlakmaster_mobile/widgets/premium/premium_action_feedback.dart';
import 'package:emlakmaster_mobile/widgets/premium_bottom_sheet_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

abstract final class ClientPortalActions {
  ClientPortalActions._();

  static void inspectPreview(BuildContext context, ClientPortalPreviewListing listing) {
    AppFeedback.lightImpact();
    showPremiumModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const PremiumBottomSheetHandle(),
              Text(
                listing.title,
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
              ),
              const SizedBox(height: 8),
              Text('${listing.priceLabel}\n${listing.location}\n${listing.features}'),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white12),
                ),
                child: const Text(
                  'Önizleme ilanı — canlı portföy bağlantısı henüz aktif değil. '
                  'Danışmanınız gerçek ilanları paylaştığında burada görünecek.',
                  style: TextStyle(fontSize: 12, height: 1.35),
                ),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Kapat'),
              ),
            ],
          ),
        );
      },
    );
  }

  static void favoritePreview(BuildContext context) {
    AppFeedback.selectionClick();
    showPremiumActionFeedback(
      context,
      title: 'Favori kaydı yakında',
      message:
          'Favori ilan kaydı henüz aktif değil. Şimdilik önizleme portföyünü inceleyebilir veya mesaj sekmesinden danışmanınıza ulaşabilirsiniz.',
      useSheet: false,
    );
  }

  static void appointmentPreview(BuildContext context) {
    AppFeedback.selectionClick();
    showPremiumActionFeedback(
      context,
      title: 'Randevu talebi yakında',
      message:
          'Uygulama içi randevu talebi henüz aktif değil. Mesajlar sekmesinden iletişime geçebilirsiniz.',
      useSheet: false,
    );
  }

  static void openMessages(WidgetRef ref) {
    AppFeedback.selectionClick();
    ref
        .read(mainShellShortcutProvider.notifier)
        .enqueue(MainShellShortcut.openMessagesTab);
  }

  static Future<void> shareListing(
    BuildContext context,
    ClientPortalPreviewListing listing,
  ) async {
    AppFeedback.lightImpact();
    final text = [
      listing.title,
      listing.location,
      listing.priceLabel,
      listing.features,
      '(Önizleme portföy — Emlak Master)',
    ].join('\n');
    await Clipboard.setData(ClipboardData(text: text));
    if (!context.mounted) return;
    final premium = PremiumThemeExtension.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'İlan metni panoya kopyalandı — WhatsApp veya SMS ile paylaşabilirsiniz.',
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: premium.champagneGold,
      ),
    );
  }

  static void advisorRequestPreview(BuildContext context) {
    AppFeedback.mediumImpact();
    showPremiumActionFeedback(
      context,
      title: 'Talep iletimi yakında',
      message:
          'Danışmana otomatik talep iletimi henüz aktif değil. Mesajlar sekmesinden doğrudan iletişime geçebilirsiniz.',
      useSheet: false,
    );
  }
}
