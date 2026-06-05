import 'package:emlakmaster_mobile/core/constants/app_constants.dart';
import 'package:emlakmaster_mobile/core/feedback/app_feedback.dart';
import 'package:emlakmaster_mobile/core/navigation/shell_navigator.dart';
import 'package:emlakmaster_mobile/core/services/auth_logout_coordinator.dart';
import 'package:emlakmaster_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:emlakmaster_mobile/features/client_portal/presentation/account/account_types.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Hesabım aksiyonları — her görünür aksiyon gerçek bir hedefe gider (dead
/// button yok). Bilgi satırları dürüst detay sayfası açar; kanal satırları
/// gerçek kabuk sekmesine gider; çıkış gerçek oturum kapatma akışını çalıştırır.
abstract final class AccountActions {
  AccountActions._();

  static Future<void> handle(
    BuildContext context,
    WidgetRef ref,
    AccountEntry entry,
  ) async {
    switch (entry.action) {
      case AccountAction.detail:
        showDetailSheet(context, ref, entry);
      case AccountAction.goMessages:
      case AccountAction.goRequests:
      case AccountAction.goEngagement:
        AppFeedback.selectionClick();
        ShellNavigator.goToShortcut(
          context,
          AccountSnapshot.shortcutFor(entry.action),
        );
      case AccountAction.privacy:
        showPrivacy(context);
      case AccountAction.about:
        showAbout(context);
      case AccountAction.signOut:
        await confirmSignOut(context, ref);
    }
  }

  /// Auth/canlı durumu tazele (retry).
  static void refresh(WidgetRef ref) {
    ref.invalidate(currentUserProvider);
  }

  static void showPrivacy(BuildContext context) {
    AppFeedback.lightImpact();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('KVKK & Gizlilik'),
        content: const SingleChildScrollView(
          child: Text(
            'Kişisel verileriniz yalnızca hizmet sunumu ve yasal yükümlülükler '
            'kapsamında işlenir. Detaylı bilgi için ofisimizle iletişime '
            'geçebilirsiniz.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  static void showAbout(BuildContext context) {
    AppFeedback.selectionClick();
    final version = AppConstants.appVersion.split('+').first;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(AppConstants.appName),
        content: Text(
          'Sürüm $version\n\n'
          'Müşteri portalı — portföy keşfi, iletişim ve hesap yönetimi.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  static Future<void> confirmSignOut(
    BuildContext context,
    WidgetRef ref,
  ) async {
    AppFeedback.mediumImpact();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Çıkış yap'),
        content: const Text('Hesabınızdan çıkış yapmak istiyor musunuz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Vazgeç'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Çıkış yap'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await AuthLogoutCoordinator.signOut(ref);
    }
  }

  static void showDetailSheet(
    BuildContext context,
    WidgetRef ref,
    AccountEntry entry,
  ) {
    AppFeedback.selectionClick();
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) {
        final bottom = MediaQuery.paddingOf(ctx).bottom;
        final honest = entry.readiness != AccountReadiness.ready;
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(20, 8, 20, 16 + bottom),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.title,
                  style: Theme.of(ctx)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                _DetailLine(label: 'Değer', value: entry.value),
                _DetailLine(label: 'Durum', value: entry.statusLabel),
                _DetailLine(label: 'Bağlam', value: entry.context),
                const SizedBox(height: 12),
                Text(
                  honest
                      ? 'Bu alan henüz sunucuda tutulmuyor; uydurma bilgi '
                          'gösterilmez. Eksik bilgiyi danışmanınıza mesajdan '
                          'iletebilirsiniz.'
                      : 'Bu bilgi gerçek hesabınızdan gelir.',
                  style: Theme.of(ctx)
                      .textTheme
                      .bodySmall
                      ?.copyWith(fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _DetailLine extends StatelessWidget {
  const _DetailLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: RichText(
        text: TextSpan(
          style: Theme.of(context).textTheme.bodySmall,
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }
}
