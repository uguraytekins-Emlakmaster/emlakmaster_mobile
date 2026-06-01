import 'package:emlakmaster_mobile/core/feedback/app_feedback.dart';
import 'package:emlakmaster_mobile/core/navigation/main_shell_shortcut_provider.dart';
import 'package:emlakmaster_mobile/core/router/app_router.dart';
import 'package:emlakmaster_mobile/core/utils/sms_launcher.dart';
import 'package:emlakmaster_mobile/core/utils/whatsapp_launcher.dart';
import 'package:emlakmaster_mobile/features/calls/application/start_crm_outbound_call.dart';
import 'package:emlakmaster_mobile/features/crm_customers/presentation/providers/customer_entity_provider.dart';
import 'package:emlakmaster_mobile/features/tasks/presentation/consultant_task_flows.dart';
import 'package:emlakmaster_mobile/features/tasks/presentation/providers/advisor_tasks_display_provider.dart';
import 'package:emlakmaster_mobile/features/tasks/presentation/providers/advisor_tasks_stream_provider.dart';
import 'package:emlakmaster_mobile/features/tasks/presentation/workspace/tasks_workspace_types.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

abstract final class TasksWorkspaceActions {
  TasksWorkspaceActions._();

  static void _snack(BuildContext context, String message) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  static void refresh(WidgetRef ref, String uid) {
    ref.invalidate(advisorTasksStreamProvider(uid));
    ref.invalidate(advisorTasksStaleCacheProvider(uid));
  }

  static void showAddTask(BuildContext context, WidgetRef ref, String uid) {
    ConsultantTaskFlows.showAddTaskDialog(context, ref, uid);
  }

  static void showRecurring(BuildContext context, WidgetRef ref, String uid) {
    ConsultantTaskFlows.showRecurringTasksSheet(context, ref, uid);
  }

  static void openDetail(
    BuildContext context,
    WidgetRef ref,
    String uid,
    TaskRowView row,
  ) {
    ConsultantTaskFlows.showTaskDetailSheet(
      context,
      ref: ref,
      uid: uid,
      id: row.id,
      data: row.rawData,
      onToggleDone: () => toggleDone(context, ref, row, !row.done),
      onDelete: () => ConsultantTaskFlows.confirmDeleteTask(
        context,
        row.id,
        row.title,
      ),
    );
  }

  static Future<void> toggleDone(
    BuildContext context,
    WidgetRef ref,
    TaskRowView row,
    bool done,
  ) async {
    await ConsultantTaskFlows.toggleDone(
      context,
      ref,
      row.id,
      row.rawData,
      done,
    );
  }

  static Future<void> postpone(
    BuildContext context,
    TaskRowView row,
  ) async {
    await ConsultantTaskFlows.postponeTask(
      context,
      id: row.id,
      data: row.rawData,
    );
  }

  static void openCustomer(BuildContext context, TaskRowView row) {
    final id = row.customerId?.trim();
    if (id == null || id.isEmpty) {
      _snack(context, 'Bu görevde bağlı müşteri kaydı yok.');
      return;
    }
    AppFeedback.selectionClick();
    context.push(AppRouter.routeCustomerDetail.replaceFirst(':id', id));
  }

  static Future<void> call(
    BuildContext context,
    WidgetRef ref,
    TaskRowView row,
  ) async {
    final phone = await _resolvePhone(ref, row);
    if (phone == null || phone.isEmpty) {
      _snack(context, 'Aranabilir telefon numarası yok.');
      return;
    }
    AppFeedback.mediumImpact();
    startCrmOutboundCall(
      context,
      phone: phone,
      customerId: row.customerId,
      startedFromScreen: 'consultant_tasks_workspace',
    );
  }

  static Future<void> message(
    BuildContext context,
    WidgetRef ref,
    TaskRowView row,
  ) async {
    final phone = await _resolvePhone(ref, row);
    if (phone == null || phone.isEmpty) {
      _snack(context, 'Mesaj için telefon numarası yok.');
      return;
    }
    AppFeedback.lightImpact();
    final ok = await SmsLauncher.openBulkSms([phone]);
    if (!context.mounted) return;
    if (!ok) _snack(context, 'Mesaj uygulaması açılamadı.');
  }

  static Future<void> whatsapp(
    BuildContext context,
    WidgetRef ref,
    TaskRowView row,
  ) async {
    final phone = await _resolvePhone(ref, row);
    if (phone == null || phone.isEmpty) {
      _snack(context, 'WhatsApp için telefon numarası yok.');
      return;
    }
    AppFeedback.lightImpact();
    final ok = await WhatsAppLauncher.openChat(phone);
    if (!context.mounted) return;
    if (!ok) _snack(context, 'WhatsApp açılamadı.');
  }

  static void goToFollowUp(BuildContext context, WidgetRef ref) {
    AppFeedback.selectionClick();
    ref
        .read(mainShellShortcutProvider.notifier)
        .enqueue(MainShellShortcut.openFollowUpTab);
    context.go(AppRouter.routeHome);
  }

  static Future<String?> _resolvePhone(WidgetRef ref, TaskRowView row) async {
    if (row.phone != null && row.phone!.isNotEmpty && row.callablePhone) {
      return row.phone;
    }
    final cid = row.customerId?.trim();
    if (cid == null || cid.isEmpty) return null;
    final entity = ref.read(customerEntityByIdProvider(cid)).valueOrNull;
    final phone = entity?.primaryPhone?.trim();
    if (phone != null && phone.isNotEmpty) return phone;
    return null;
  }

  static void showActionSheet(
    BuildContext context,
    WidgetRef ref,
    String uid,
    TaskRowView row,
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
                  row.title,
                  style: Theme.of(ctx)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Text('Durum: ${row.statusLabel}',
                    style: Theme.of(ctx).textTheme.bodySmall),
                if (row.contextLine.isNotEmpty)
                  Text('Bağlam: ${row.contextLine}',
                      style: Theme.of(ctx).textTheme.bodySmall),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    TextButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        openDetail(context, ref, uid, row);
                      },
                      icon: const Icon(Icons.open_in_new_rounded, size: 18),
                      label: const Text('Detay'),
                    ),
                    if (!row.done)
                      TextButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          toggleDone(context, ref, row, true);
                        },
                        icon: const Icon(Icons.check_circle_outline, size: 18),
                        label: const Text('Tamamla'),
                      ),
                    if (row.customerId != null && row.customerId!.isNotEmpty)
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
                        goToFollowUp(context, ref);
                      },
                      icon: const Icon(Icons.track_changes_rounded, size: 18),
                      label: const Text('Takibe git'),
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
