import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emlakmaster_mobile/core/feedback/app_feedback.dart';
import 'package:emlakmaster_mobile/core/firebase/user_facing_firebase_message.dart';
import 'package:emlakmaster_mobile/core/navigation/main_shell_shortcut_provider.dart';
import 'package:emlakmaster_mobile/core/navigation/shell_navigator.dart';
import 'package:emlakmaster_mobile/core/platform/io_platform_stub.dart'
    if (dart.library.io) 'dart:io' as io;
import 'package:emlakmaster_mobile/core/router/app_router.dart';
import 'package:emlakmaster_mobile/core/services/firestore_service.dart';
import 'package:emlakmaster_mobile/core/utils/sms_launcher.dart';
import 'package:emlakmaster_mobile/core/utils/whatsapp_launcher.dart';
import 'package:emlakmaster_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:emlakmaster_mobile/features/calls/application/call_record_detail_navigation.dart';
import 'package:emlakmaster_mobile/features/calls/application/start_crm_outbound_call.dart';
import 'package:emlakmaster_mobile/features/calls/data/device_call_log_sync_service.dart'
    show DeviceCallLogSyncResult, DeviceCallLogSyncService;
import 'package:emlakmaster_mobile/features/calls/presentation/providers/consultant_calls_extra_page_provider.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/providers/consultant_calls_provider.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/providers/local_call_records_provider.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/workspace/calls_workspace_types.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Çağrılarım workspace aksiyonları — her görünür aksiyon gerçek hedefe gider.
abstract final class CallsWorkspaceActions {
  CallsWorkspaceActions._();

  static void _snack(BuildContext context, String message) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  static void openDetail(BuildContext context, CallRowView row) {
    AppFeedback.selectionClick();
    CallRecordDetailNavigation.openSummary(
      context,
      firestoreDocId: row.firestoreDocId,
      onFallback: () {
        if (!context.mounted) return;
        _snack(
          context,
          row.isLocalDraft
              ? 'Kayıt henüz senkronize olmadı — tamamlandığında detay açılır.'
              : 'Bu kayıt için detay bulunamadı.',
        );
      },
    );
  }

  static void call(BuildContext context, CallRowView row) {
    if (!row.callablePhone || row.rawPhone.isEmpty) {
      _snack(context, 'Aranabilir telefon numarası yok.');
      return;
    }
    AppFeedback.mediumImpact();
    startCrmOutboundCall(
      context,
      phone: row.rawPhone,
      customerId: row.customerId,
      startedFromScreen: 'consultant_calls_workspace',
    );
  }

  static Future<void> message(BuildContext context, CallRowView row) async {
    if (!row.callablePhone || row.rawPhone.isEmpty) {
      _snack(context, 'Mesaj için telefon numarası yok.');
      return;
    }
    AppFeedback.lightImpact();
    final ok = await SmsLauncher.openBulkSms([row.rawPhone]);
    if (!context.mounted) return;
    if (!ok) _snack(context, 'Mesaj uygulaması açılamadı.');
  }

  static Future<void> whatsapp(BuildContext context, CallRowView row) async {
    if (!row.callablePhone || row.rawPhone.isEmpty) {
      _snack(context, 'WhatsApp için telefon numarası yok.');
      return;
    }
    AppFeedback.lightImpact();
    final ok = await WhatsAppLauncher.openChat(row.rawPhone);
    if (!context.mounted) return;
    if (!ok) _snack(context, 'WhatsApp açılamadı.');
  }

  static void openCustomer(BuildContext context, CallRowView row) {
    final id = row.customerId?.trim();
    if (id == null || id.isEmpty) {
      _snack(context, 'Bu arama için eşleşmiş müşteri kaydı yok.');
      return;
    }
    AppFeedback.selectionClick();
    context.push(AppRouter.routeCustomerDetail.replaceFirst(':id', id));
  }

  static void goToTasks(BuildContext context) {
    AppFeedback.selectionClick();
    ShellNavigator.goToShortcut(context, MainShellShortcut.openTasksTab);
  }

  static Future<void> addToFollowUp(
    BuildContext context,
    WidgetRef ref,
    CallRowView row,
  ) async {
    final uid = ref.read(currentUserProvider).valueOrNull?.uid ?? '';
    if (uid.isEmpty) {
      _snack(context, 'Oturum bulunamadı.');
      return;
    }
    AppFeedback.mediumImpact();
    try {
      await FirestoreService.setTask({
        'advisorId': uid,
        if (row.customerId != null && row.customerId!.isNotEmpty)
          'customerId': row.customerId,
        'title': 'Geri dön: ${row.title}',
        'dueAt': Timestamp.fromDate(DateTime.now().add(const Duration(days: 1))),
        'done': false,
      });
      if (!context.mounted) return;
      _snack(context, 'Takip listesine eklendi (Görevler\'de görünür).');
    } on FirebaseException catch (e) {
      if (!context.mounted) return;
      _snack(context, userFacingErrorMessage(e, context: 'call_followup'));
    } on StateError catch (e) {
      if (!context.mounted) return;
      _snack(context, userFacingErrorMessage(e, context: 'call_followup'));
    }
  }

  static void refresh(WidgetRef ref) {
    ref.invalidate(consultantCallsStreamProvider);
    ref.invalidate(localCallRecordsStreamProvider);
  }

  static Future<void> refreshWithDeviceSync(
    BuildContext context,
    WidgetRef ref,
  ) async {
    refresh(ref);
    if (io.Platform.isAndroid) {
      await syncDeviceCallLog(context, ref);
    }
  }

  static Future<void> syncDeviceCallLog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final uid = ref.read(currentUserProvider).valueOrNull?.uid ?? '';
    if (uid.isEmpty) {
      _snack(context, 'Oturum açık değil.');
      return;
    }
    if (!io.Platform.isAndroid) {
      _snack(
        context,
        'Telefon arama geçmişi yalnızca Android\'de desteklenir. '
        'iOS\'ta yalnızca uygulama içi görüşmeler listelenir.',
      );
      return;
    }
    AppFeedback.lightImpact();
    final result =
        await DeviceCallLogSyncService.instance.syncCallLogToFirestore(uid);
    if (!context.mounted) return;
    refresh(ref);
    final message = switch (result) {
      DeviceCallLogSyncResult.success =>
        'Telefon arama geçmişi içe aktarıldı.',
      DeviceCallLogSyncResult.permissionDenied =>
        'Arama geçmişi izni verilmedi.',
      DeviceCallLogSyncResult.permissionPermanentlyDenied =>
        'Arama geçmişi izni kapalı — Ayarlardan açın.',
      DeviceCallLogSyncResult.notSupported =>
        'Bu cihazda telefon geçmişi içe aktarımı desteklenmiyor.',
      DeviceCallLogSyncResult.error =>
        'İçe aktarma başarısız — tekrar deneyin.',
    };
    _snack(context, message);
  }

  static void loadMore(WidgetRef ref, String uid) {
    if (uid.isEmpty) return;
    AppFeedback.lightImpact();
    ref.read(consultantCallsExtraPageProvider(uid).notifier).loadMore(uid);
  }

  static void showDetailSheet(
    BuildContext context,
    WidgetRef ref,
    CallRowView row,
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
                  row.title,
                  style: Theme.of(ctx)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                _DetailLine(label: 'Yön / süre', value: row.directionDuration),
                _DetailLine(label: 'Sonuç', value: row.outcomeLabel),
                _DetailLine(label: 'Zaman', value: row.timestampLabel),
                if (row.phoneLine.isNotEmpty)
                  _DetailLine(label: 'Telefon', value: row.phoneLine),
                if (row.contextLine.isNotEmpty)
                  _DetailLine(label: 'Bağlam', value: row.contextLine),
                if (row.isPartial && row.partialNote.isNotEmpty)
                  _DetailLine(label: 'Kayıt', value: row.partialNote),
                const SizedBox(height: 12),
                Text(
                  'Cevapsız yalnızca kayıtlı sonuç kodlarından gösterilir. '
                  'iOS sistem günlüğü okunamaz; uydurma KPI yok.',
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
                        openDetail(context, row);
                      },
                      icon: const Icon(Icons.open_in_new_rounded, size: 18),
                      label: const Text('Detay'),
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
                    if (row.customerId != null && row.customerId!.isNotEmpty)
                      TextButton.icon(
                        onPressed: () {
                          Navigator.of(ctx).pop();
                          openCustomer(context, row);
                        },
                        icon: const Icon(Icons.person_rounded, size: 18),
                        label: const Text('Müşteriye git'),
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
