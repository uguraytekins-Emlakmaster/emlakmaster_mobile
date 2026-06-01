import 'package:emlakmaster_mobile/core/feedback/app_feedback.dart';
import 'package:emlakmaster_mobile/core/navigation/main_shell_shortcut_provider.dart';
import 'package:emlakmaster_mobile/core/navigation/shell_navigator.dart';
import 'package:emlakmaster_mobile/core/router/app_router.dart';
import 'package:emlakmaster_mobile/core/utils/sms_launcher.dart';
import 'package:emlakmaster_mobile/core/utils/whatsapp_launcher.dart';
import 'package:emlakmaster_mobile/features/calls/application/start_crm_outbound_call.dart';
import 'package:emlakmaster_mobile/features/crm_customers/presentation/detail_workspace/customer_detail_workspace_types.dart';
import 'package:emlakmaster_mobile/features/crm_customers/presentation/providers/customer_entity_provider.dart';
import 'package:emlakmaster_mobile/features/crm_customers/presentation/utils/customer_crm_refresh.dart';
import 'package:emlakmaster_mobile/features/crm_customers/presentation/widgets/customer_edit_sheet.dart';
import 'package:emlakmaster_mobile/features/smart_matching_engine/presentation/providers/portfolio_match_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

abstract final class CustomerDetailWorkspaceActions {
  CustomerDetailWorkspaceActions._();

  static void _snack(BuildContext context, String message) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  static void refresh(WidgetRef ref, String customerId) {
    ref.invalidate(customerEntityByIdProvider(customerId));
    ref.invalidate(topMatchedListingsForCustomerProvider(customerId));
    invalidateCustomerCrmCascade(ref, customerId);
  }

  static void edit(
    BuildContext context,
    WidgetRef ref,
    CustomerDetailWorkspaceSnapshot snapshot,
  ) {
    final entity =
        ref.read(customerEntityByIdProvider(snapshot.customerId)).valueOrNull;
    if (entity == null) {
      _snack(context, 'Müşteri kaydı yüklenemedi.');
      return;
    }
    showCustomerEditSheet(
      context,
      ref,
      customerId: snapshot.customerId,
      entity: entity,
    );
  }

  static void call(
    BuildContext context,
    CustomerDetailWorkspaceSnapshot snapshot,
  ) {
    final phone = snapshot.phone;
    if (!snapshot.callablePhone || phone == null || phone.isEmpty) {
      _snack(context, 'Aranabilir telefon numarası yok.');
      return;
    }
    AppFeedback.mediumImpact();
    startCrmOutboundCall(
      context,
      phone: phone,
      customerId: snapshot.customerId,
      startedFromScreen: 'customer_detail_workspace',
    );
  }

  static Future<void> message(
    BuildContext context,
    CustomerDetailWorkspaceSnapshot snapshot,
  ) async {
    final phone = snapshot.phone;
    if (!snapshot.callablePhone || phone == null || phone.isEmpty) {
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
    CustomerDetailWorkspaceSnapshot snapshot,
  ) async {
    final phone = snapshot.phone;
    if (!snapshot.callablePhone || phone == null || phone.isEmpty) {
      _snack(context, 'WhatsApp için telefon numarası yok.');
      return;
    }
    AppFeedback.lightImpact();
    final ok = await WhatsAppLauncher.openChat(phone);
    if (!context.mounted) return;
    if (!ok) _snack(context, 'WhatsApp açılamadı.');
  }

  static void goToTasks(BuildContext context) {
    AppFeedback.selectionClick();
    ShellNavigator.goToShortcut(context, MainShellShortcut.openTasksTab);
  }

  static void goToFollowUp(BuildContext context) {
    AppFeedback.selectionClick();
    ShellNavigator.goToShortcut(context, MainShellShortcut.openFollowUpTab);
  }

  static void goToPortfolio(BuildContext context) {
    AppFeedback.selectionClick();
    ShellNavigator.goToShortcut(context, MainShellShortcut.openListingsTab);
  }

  static void openListing(BuildContext context, String listingId) {
    if (listingId.isEmpty) return;
    AppFeedback.selectionClick();
    context.push(AppRouter.routeListingDetail.replaceFirst(':id', listingId));
  }

  static void handleQuickAction(
    BuildContext context,
    WidgetRef ref,
    CustomerDetailWorkspaceSnapshot snapshot,
    CustomerDetailQuickAction action,
  ) {
    switch (action) {
      case CustomerDetailQuickAction.call:
        call(context, snapshot);
      case CustomerDetailQuickAction.message:
        message(context, snapshot);
      case CustomerDetailQuickAction.whatsapp:
        whatsapp(context, snapshot);
      case CustomerDetailQuickAction.tasks:
        goToTasks(context);
      case CustomerDetailQuickAction.followUp:
        goToFollowUp(context);
      case CustomerDetailQuickAction.portfolio:
        goToPortfolio(context);
    }
  }

  static void showActionSheet(
    BuildContext context,
    WidgetRef ref,
    CustomerDetailWorkspaceSnapshot snapshot,
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
                  snapshot.displayName,
                  style: Theme.of(ctx)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                if (snapshot.nextActionLabel.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    snapshot.nextActionLabel,
                    style: Theme.of(ctx).textTheme.bodySmall,
                  ),
                ],
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    if (snapshot.callablePhone)
                      TextButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          call(context, snapshot);
                        },
                        icon: const Icon(Icons.call_rounded, size: 18),
                        label: const Text('Ara'),
                      ),
                    TextButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        edit(context, ref, snapshot);
                      },
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: const Text('Düzenle'),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        goToTasks(context);
                      },
                      icon: const Icon(Icons.task_alt_rounded, size: 18),
                      label: const Text('Göreve git'),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        goToFollowUp(context);
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
