import 'package:emlakmaster_mobile/core/feedback/app_feedback.dart';
import 'package:emlakmaster_mobile/core/navigation/main_shell_shortcut_provider.dart';
import 'package:emlakmaster_mobile/core/navigation/shell_navigator.dart';
import 'package:emlakmaster_mobile/core/utils/sms_launcher.dart';
import 'package:emlakmaster_mobile/features/resurrection_engine/presentation/providers/resurrection_queue_provider.dart';
import 'package:emlakmaster_mobile/features/resurrection_engine/presentation/utils/follow_up_list_actions.dart';
import 'package:emlakmaster_mobile/features/resurrection_engine/presentation/workspace/follow_up_workspace_types.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Takiplerim workspace aksiyonları — mevcut takip akışları korunur.
abstract final class FollowUpWorkspaceActions {
  FollowUpWorkspaceActions._();

  static void _snack(BuildContext context, String message) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  static void refresh(WidgetRef ref) {
    ref.invalidate(resurrectionQueueProvider);
  }

  static void openDetail(BuildContext context, FollowUpRowView row) {
    FollowUpListActions.openDetail(context, item: row.item);
  }

  static void openCustomer(BuildContext context, FollowUpRowView row) {
    FollowUpListActions.openCustomer(context, row.item);
  }

  static void call(BuildContext context, FollowUpRowView row) {
    FollowUpListActions.launchCall(context, row.item);
  }

  static Future<void> message(BuildContext context, FollowUpRowView row) async {
    final phone = row.item.primaryPhone?.trim();
    if (phone == null || phone.isEmpty) {
      _snack(context, 'Mesaj için telefon numarası yok.');
      return;
    }
    AppFeedback.lightImpact();
    final ok = await SmsLauncher.openBulkSms([phone]);
    if (!context.mounted) return;
    if (!ok) _snack(context, 'Mesaj uygulaması açılamadı.');
  }

  static Future<void> whatsapp(BuildContext context, FollowUpRowView row) async {
    FollowUpListActions.launchWhatsApp(context, row.item);
  }

  /// Operasyonel kapanış — görev kaydı oluşturur (sunucuda ayrı “tamamlandı” yok).
  static Future<void> complete(
    BuildContext context,
    WidgetRef ref,
    FollowUpRowView row,
  ) async {
    await FollowUpListActions.createTask(
      context,
      ref,
      row.item,
      title: 'Takip tamamlandı: ${row.displayName}',
      dueIn: const Duration(hours: 1),
    );
  }

  static Future<void> snooze(
    BuildContext context,
    WidgetRef ref,
    FollowUpRowView row,
  ) async {
    await FollowUpListActions.snooze(context, ref, row.item);
  }

  static void goToTasks(BuildContext context) {
    AppFeedback.selectionClick();
    ShellNavigator.goToShortcut(context, MainShellShortcut.openTasksTab);
  }

  static void showActionSheet(
    BuildContext context,
    WidgetRef ref,
    FollowUpRowView row,
  ) {
    AppFeedback.selectionClick();
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        final bottom = MediaQuery.paddingOf(ctx).bottom;
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(20, 8, 20, 16 + bottom),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  row.displayName,
                  style: Theme.of(ctx)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Text('Durum: ${row.statusLabel}',
                    style: Theme.of(ctx).textTheme.bodySmall),
                Text(row.lastContactLabel,
                    style: Theme.of(ctx).textTheme.bodySmall),
                if (row.contextLine.isNotEmpty)
                  Text('Bağlam: ${row.contextLine}',
                      style: Theme.of(ctx).textTheme.bodySmall),
                const SizedBox(height: 12),
                Text(
                  'Kuyruk ≥7 gün sessiz müşterilerden türetilir; “tamamlandı” '
                  'ayrı alan değil — görev kaydı operasyonel işarettir.',
                  style: Theme.of(ctx)
                      .textTheme
                      .bodySmall
                      ?.copyWith(fontStyle: FontStyle.italic),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    TextButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        openDetail(context, row);
                      },
                      icon: const Icon(Icons.open_in_new_rounded, size: 18),
                      label: const Text('Detay'),
                    ),
                    if (row.callablePhone)
                      TextButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          call(context, row);
                        },
                        icon: const Icon(Icons.call_rounded, size: 18),
                        label: const Text('Ara'),
                      ),
                    TextButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        complete(context, ref, row);
                      },
                      icon: const Icon(Icons.check_circle_outline, size: 18),
                      label: const Text('Tamamla'),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        openCustomer(context, row);
                      },
                      icon: const Icon(Icons.person_rounded, size: 18),
                      label: const Text('Müşteriye git'),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        goToTasks(context);
                      },
                      icon: const Icon(Icons.task_alt_rounded, size: 18),
                      label: const Text('Göreve git'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
