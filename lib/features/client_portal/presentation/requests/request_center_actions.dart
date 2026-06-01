import 'package:emlakmaster_mobile/core/feedback/app_feedback.dart';
import 'package:emlakmaster_mobile/core/navigation/shell_navigator.dart';
import 'package:emlakmaster_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:emlakmaster_mobile/features/client_portal/presentation/requests/request_center_types.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Talep Merkezi aksiyonları — her görünür aksiyon gerçek bir kabuk sekmesine
/// gider (dead button yok). Kayıtlı talep altyapısı olmayan kanallar detayda
/// dürüstçe açıklanır. Merkezi [ShellNavigator] kabuk dışından çağrılsa da ana
/// kabuğa güvenli döner.
abstract final class RequestCenterActions {
  RequestCenterActions._();

  static void open(
    BuildContext context,
    WidgetRef ref,
    RequestCenterEntry entry,
  ) {
    AppFeedback.selectionClick();
    ShellNavigator.goToShortcut(context, entry.shortcut);
  }

  /// Auth/canlı durumu tazele (retry).
  static void refresh(WidgetRef ref) {
    ref.invalidate(currentUserProvider);
  }

  static void showDetailSheet(
    BuildContext context,
    WidgetRef ref,
    RequestCenterEntry entry,
  ) {
    AppFeedback.selectionClick();
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) {
        final bottom = MediaQuery.paddingOf(ctx).bottom;
        final honest = entry.readiness != RequestReadiness.ready;
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
                _DetailLine(label: 'Tür', value: entry.typeLabel),
                _DetailLine(label: 'Açıklama', value: entry.detail),
                _DetailLine(label: 'Bağlam', value: entry.context),
                _DetailLine(label: 'Durum', value: entry.statusLabel),
                const SizedBox(height: 12),
                Text(
                  honest
                      ? 'Bu adım henüz sunucuda kayıt tutmuyor; uydurma talep '
                          'gösterilmez. İlgili gerçek yüzeye yönlendirilirsiniz.'
                      : 'Bu kanal canlı ve hazır; gerçek yüzeye yönlendirilirsiniz.',
                  style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                        fontStyle: FontStyle.italic,
                      ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      open(context, ref, entry);
                    },
                    icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                    label: Text(entry.actionLabel),
                  ),
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
