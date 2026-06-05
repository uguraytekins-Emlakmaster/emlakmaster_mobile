import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emlakmaster_mobile/core/feedback/app_feedback.dart';
import 'package:emlakmaster_mobile/core/firebase/user_facing_firebase_message.dart';
import 'package:emlakmaster_mobile/core/navigation/shell_navigator.dart';
import 'package:emlakmaster_mobile/core/navigation/main_shell_shortcut_provider.dart';
import 'package:emlakmaster_mobile/core/router/app_router.dart';
import 'package:emlakmaster_mobile/core/services/firestore_service.dart';
import 'package:emlakmaster_mobile/core/utils/sms_launcher.dart';
import 'package:emlakmaster_mobile/core/utils/whatsapp_launcher.dart';
import 'package:emlakmaster_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:emlakmaster_mobile/features/calls/application/start_crm_outbound_call.dart';
import 'package:emlakmaster_mobile/features/contact_save/presentation/widgets/save_contact_sheet.dart';
import 'package:emlakmaster_mobile/features/crm_customers/presentation/providers/customer_list_extra_page_provider.dart';
import 'package:emlakmaster_mobile/features/crm_customers/presentation/providers/customer_list_stream_provider.dart';
import 'package:emlakmaster_mobile/features/crm_customers/presentation/utils/customer_crm_refresh.dart';
import 'package:emlakmaster_mobile/features/crm_customers/presentation/workspace/customer_workspace_types.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Müşterilerim workspace aksiyonları — her görünür aksiyon gerçek bir hedefe
/// gider (dead button yok). Mevcut akışlar korunur: detay rotası, CRM çağrısı,
/// SMS/WhatsApp, görev/takip oluşturma, müşteri ekleme, sayfalama, yenileme.
abstract final class CustomerWorkspaceActions {
  CustomerWorkspaceActions._();

  static void _snack(BuildContext context, String message) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  static void openDetail(
    BuildContext context,
    WidgetRef ref,
    CustomerRowView row,
  ) {
    if (row.isDemo) {
      _snack(
        context,
        'Demo kayıt — gerçek müşteri için arama yapın veya müşteri oluşturun.',
      );
      return;
    }
    AppFeedback.selectionClick();
    context
        .push(AppRouter.routeCustomerDetail.replaceFirst(':id', row.id))
        .then((_) {
      if (context.mounted) invalidateCustomerCrmCascade(ref, row.id);
    });
  }

  static void call(BuildContext context, CustomerRowView row) {
    final phone = row.phone;
    if (!row.callablePhone || phone == null || phone.isEmpty) {
      _snack(context, 'Aranabilir telefon numarası yok.');
      return;
    }
    AppFeedback.mediumImpact();
    startCrmOutboundCall(
      context,
      phone: phone,
      customerId: row.id,
      startedFromScreen: 'consultant_customers_workspace',
    );
  }

  static Future<void> message(BuildContext context, CustomerRowView row) async {
    final phone = row.phone;
    if (!row.callablePhone || phone == null || phone.isEmpty) {
      _snack(context, 'Mesaj için telefon numarası yok.');
      return;
    }
    AppFeedback.lightImpact();
    final ok = await SmsLauncher.openBulkSms([phone]);
    if (!context.mounted) return;
    if (!ok) _snack(context, 'Mesaj uygulaması açılamadı.');
  }

  static Future<void> whatsapp(BuildContext context, CustomerRowView row) async {
    final phone = row.phone;
    if (!row.callablePhone || phone == null || phone.isEmpty) {
      _snack(context, 'WhatsApp için telefon numarası yok.');
      return;
    }
    AppFeedback.lightImpact();
    final ok = await WhatsAppLauncher.openChat(phone);
    if (!context.mounted) return;
    if (!ok) _snack(context, 'WhatsApp açılamadı.');
  }

  /// Görevler sekmesine git (kabuk dışından da güvenli).
  static void goToTasks(BuildContext context) {
    AppFeedback.selectionClick();
    ShellNavigator.goToShortcut(context, MainShellShortcut.openTasksTab);
  }

  /// Tek müşteriyi takip görevine ekle (Görevler'de görünür).
  static Future<void> addToFollowUp(
    BuildContext context,
    WidgetRef ref,
    CustomerRowView row,
  ) async {
    if (row.isDemo) {
      _snack(context, 'Demo kayıt takip listesine eklenmez.');
      return;
    }
    final uid = ref.read(currentUserProvider).valueOrNull?.uid ?? '';
    if (uid.isEmpty) {
      _snack(context, 'Oturum bulunamadı.');
      return;
    }
    AppFeedback.mediumImpact();
    try {
      await FirestoreService.setTask({
        'advisorId': uid,
        'customerId': row.id,
        'title': 'Takip et: ${row.name}',
        'dueAt': Timestamp.fromDate(DateTime.now().add(const Duration(days: 3))),
        'done': false,
      });
      if (!context.mounted) return;
      _snack(context, 'Takip listesine eklendi (Görevler\'de görünür).');
    } on FirebaseException catch (e) {
      if (!context.mounted) return;
      _snack(context, userFacingErrorMessage(e, context: 'customer_followup'));
    } on StateError catch (e) {
      if (!context.mounted) return;
      _snack(context, userFacingErrorMessage(e, context: 'customer_followup'));
    }
  }

  static void addCustomer(BuildContext context, {String? source}) {
    AppFeedback.lightImpact();
    showSaveContactSheet(context, source: source ?? 'crm_workspace');
  }

  static void refresh(WidgetRef ref) {
    final uid = ref.read(currentUserProvider).valueOrNull?.uid ?? '';
    if (uid.isNotEmpty) {
      ref.invalidate(customerListExtraPageProvider(uid));
    }
    ref.invalidate(customerListForAgentProvider);
  }

  static void loadMore(WidgetRef ref, String uid) {
    if (uid.isEmpty) return;
    AppFeedback.lightImpact();
    ref.read(customerListExtraPageProvider(uid).notifier).loadMore(uid);
  }

  static void showDetailSheet(
    BuildContext context,
    WidgetRef ref,
    CustomerRowView row,
  ) {
    AppFeedback.selectionClick();
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
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
                  row.name,
                  style: Theme.of(ctx)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                _DetailLine(label: 'İletişim', value: row.contactLine),
                _DetailLine(
                  label: 'Sıcaklık',
                  value: '${row.heatLabel} · ${row.heatScore}',
                ),
                _DetailLine(label: 'Son temas', value: row.lastContactLabel),
                if (row.contextLine.isNotEmpty)
                  _DetailLine(label: 'Bağlam', value: row.contextLine),
                if (row.isPartial && row.partialNote.isNotEmpty)
                  _DetailLine(label: 'Kayıt', value: row.partialNote),
                const SizedBox(height: 12),
                Text(
                  'Sıcaklık kural tabanlı hesaplanır (yapay zekâ değil); son '
                  'temas gerçek kayıt aktivitesini yansıtır. Uydurma skor yok.',
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
                        Navigator.of(ctx).pop();
                        openDetail(context, ref, row);
                      },
                      icon: const Icon(Icons.open_in_new_rounded, size: 18),
                      label: const Text('Aç'),
                    ),
                    if (row.callablePhone)
                      TextButton.icon(
                        onPressed: () {
                          Navigator.of(ctx).pop();
                          call(context, row);
                        },
                        icon: const Icon(Icons.call_rounded, size: 18),
                        label: const Text('Ara'),
                      ),
                    TextButton.icon(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        addToFollowUp(context, ref, row);
                      },
                      icon: const Icon(Icons.playlist_add_rounded, size: 18),
                      label: const Text('Takibe ekle'),
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
