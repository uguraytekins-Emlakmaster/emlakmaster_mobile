import 'dart:async';

import 'package:emlakmaster_mobile/core/router/app_router.dart';
import 'package:emlakmaster_mobile/core/services/settings_service.dart';
import 'package:emlakmaster_mobile/features/auth/domain/entities/app_role.dart';
import 'package:emlakmaster_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:emlakmaster_mobile/features/crm_customers/domain/execution_reminder.dart';
import 'package:emlakmaster_mobile/features/dashboard/data/execution_reminder_local_notifications.dart';
import 'package:emlakmaster_mobile/features/dashboard/presentation/providers/execution_reminders_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Dashboard hatırlatıcıları → yerel bildirim (yeni kritik/yüksek satır).
class ExecutionReminderNotificationBridge {
  ExecutionReminderNotificationBridge._();

  static final Set<String> _deliveredKeys = <String>{};
  static bool _primed = false;
  static WidgetRef? _hostRef;
  static ProviderSubscription? _userSub;
  static ProviderSubscription<AsyncValue<List<ExecutionReminderItem>>>?
      _consultantSub;
  static ProviderSubscription<AsyncValue<List<ExecutionReminderItem>>>?
      _brokerSub;

  static void attach(WidgetRef ref) {
    _hostRef = ref;
    ExecutionReminderLocalNotifications.instance.onTapCustomer =
        (customerId) {
      final host = _hostRef;
      if (host == null) return;
      host.read(AppRouter.goRouterProvider).push('/customer/$customerId');
    };

    _userSub?.close();
    _consultantSub?.close();
    _brokerSub?.close();
    _deliveredKeys.clear();
    _primed = false;

    _userSub = ref.listenManual(currentUserProvider, (previous, next) {
      _consultantSub?.close();
      _brokerSub?.close();
      _consultantSub = null;
      _brokerSub = null;
      _deliveredKeys.clear();
      _primed = false;

      final uid = next.valueOrNull?.uid;
      if (uid == null || uid.isEmpty) return;

      final role = ref.read(displayRoleOrNullProvider) ?? AppRole.guest;
      if (role.isManagerTier) {
        _brokerSub = ref.listenManual(
          brokerExecutionRemindersProvider,
          (prev, nextReminders) =>
              unawaited(_onReminders(nextReminders)),
        );
      } else {
        _consultantSub = ref.listenManual(
          consultantExecutionRemindersProvider,
          (prev, nextReminders) =>
              unawaited(_onReminders(nextReminders)),
        );
      }
    });
  }

  static Future<void> _onReminders(
    AsyncValue<List<ExecutionReminderItem>> next,
  ) async {
    final items = next.valueOrNull;
    if (items == null) return;

    if (!_primed) {
      _primed = true;
      for (final r in items) {
        _deliveredKeys.add(r.dedupeKey);
      }
      return;
    }

    final allowed =
        await SettingsService.instance.isNotificationAllowed('tasks');
    if (!allowed) return;

    for (final r in items) {
      if (_deliveredKeys.contains(r.dedupeKey)) continue;
      _deliveredKeys.add(r.dedupeKey);
      if (r.reminderPriority == ExecutionReminderPriority.medium) continue;

      final name = r.customerName?.trim().isNotEmpty == true
          ? r.customerName!.trim()
          : 'Müşteri';
      await ExecutionReminderLocalNotifications.instance.showSummary(
        notificationId: r.dedupeKey.hashCode & 0x7fffffff,
        title: r.reminderPriority == ExecutionReminderPriority.critical
            ? 'Acil: $name'
            : 'Öncelik: $name',
        body: r.reminderTitleTr,
        customerId: r.relatedCustomerId,
      );
      break;
    }
  }
}
