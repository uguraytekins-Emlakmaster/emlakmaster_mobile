import 'package:emlakmaster_mobile/core/feedback/app_feedback.dart';
import 'package:emlakmaster_mobile/core/navigation/main_shell_shortcut_provider.dart';
import 'package:emlakmaster_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:emlakmaster_mobile/features/client_portal/presentation/utils/client_portal_filter.dart';
import 'package:emlakmaster_mobile/features/client_portal/presentation/widgets/client_portal_chrome.dart';
import 'package:emlakmaster_mobile/shared/widgets/empty_state.dart';
import 'package:emlakmaster_mobile/widgets/premium/v2/premium_shell_chrome.dart';
import 'package:emlakmaster_mobile/widgets/session_avatar_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Müşteri Favoriler — dürüst boş durum; sahte ilan yok.
class ClientPortalFavoritesPage extends ConsumerWidget {
  const ClientPortalFavoritesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final signedIn = ref.watch(currentUserProvider).valueOrNull != null;
    final summary = computeClientPortalSummary(signedIn: signedIn);

    return PremiumShellBackdrop(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: PremiumClientPortalHeader(
                  title: 'Favorilerim',
                  subtitle: 'Kaydettiğiniz ilanlar · kişisel portföy',
                  actions: signedIn
                      ? const [
                          Padding(
                            padding: EdgeInsets.only(left: 4),
                            child: SessionAvatarButton(size: 38),
                          ),
                        ]
                      : const [],
                ),
              ),
              SliverToBoxAdapter(child: PremiumClientSummaryStrip(summary: summary)),
              const SliverToBoxAdapter(
                child: PremiumClientSectionLabel(
                  label: 'Kayıtlı ilanlar',
                  secondary: 'Favori altyapısı yakında',
                ),
              ),
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: EmptyState(
                    compact: true,
                    grouped: true,
                    premiumVisual: true,
                    icon: Icons.favorite_border_rounded,
                    title: 'Henüz favori ilan yok',
                    subtitle:
                        'Favori kaydı henüz aktif değil. Keşfet sekmesindeki önizleme portföyünü inceleyebilir veya mesaj sekmesinden danışmanınıza ulaşabilirsiniz.',
                    actionLabel: 'Keşfet sekmesine git',
                    onAction: () {
                      AppFeedback.selectionClick();
                      ref
                          .read(mainShellShortcutProvider.notifier)
                          .enqueue(MainShellShortcut.openHomeTab);
                    },
                    outlinedActionLabel: 'Mesaj gönder',
                    onOutlinedAction: () {
                      AppFeedback.selectionClick();
                      ref
                          .read(mainShellShortcutProvider.notifier)
                          .enqueue(MainShellShortcut.openMessagesTab);
                    },
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
