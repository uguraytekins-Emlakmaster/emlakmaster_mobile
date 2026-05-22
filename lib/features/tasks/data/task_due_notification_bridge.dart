import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emlakmaster_mobile/core/navigation/main_shell_shortcut_provider.dart';
import 'package:emlakmaster_mobile/core/router/app_router.dart';
import 'package:emlakmaster_mobile/core/services/settings_service.dart';
import 'package:emlakmaster_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:emlakmaster_mobile/features/tasks/data/task_due_local_notifications.dart';
import 'package:emlakmaster_mobile/features/tasks/presentation/providers/advisor_tasks_display_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Açık görevlerde bugün/gecikmiş vade → tek özet bildirim.
class TaskDueNotificationBridge {
  TaskDueNotificationBridge._();

  static final Set<String> _notifiedTaskIds = <String>{};
  static bool _primed = false;
  static WidgetRef? _hostRef;
  static ProviderSubscription? _userSub;
  static ProviderSubscription? _tasksSub;

  static void attach(WidgetRef ref) {
    _hostRef = ref;
    TaskDueLocalNotifications.instance.onTap = (taskId, customerId) {
      final host = _hostRef;
      if (host == null) return;
      final router = host.read(AppRouter.goRouterProvider);
      if (customerId != null && customerId.isNotEmpty) {
        router.push('/customer/$customerId');
      } else {
        host.read(mainShellShortcutProvider.notifier).enqueue(
              MainShellShortcut.openTasksTab,
            );
        router.go(AppRouter.routeHome);
      }
    };

    _userSub?.close();
    _tasksSub?.close();
    _notifiedTaskIds.clear();
    _primed = false;

    _userSub = ref.listenManual(currentUserProvider, (previous, next) {
      _tasksSub?.close();
      _tasksSub = null;
      _notifiedTaskIds.clear();
      _primed = false;

      final uid = next.valueOrNull?.uid;
      if (uid == null || uid.isEmpty) return;

      _tasksSub = ref.listenManual(
        advisorTasksDisplayProvider(uid),
        (prev, nextTasks) => unawaited(_onTasks(nextTasks)),
      );
    });
  }

  static Future<void> _onTasks(
    AsyncValue<List<QueryDocumentSnapshot<Map<String, dynamic>>>> next,
  ) async {
    final docs = next.valueOrNull;
    if (docs == null) return;

    if (!_primed) {
      _primed = true;
      for (final d in docs) {
        _notifiedTaskIds.add(d.id);
      }
      return;
    }

    final enabled = await SettingsService.instance.getNotificationsEnabled();
    if (!enabled) return;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    for (final doc in docs) {
      if (_notifiedTaskIds.contains(doc.id)) continue;
      final data = doc.data();
      if (data['done'] == true) {
        _notifiedTaskIds.add(doc.id);
        continue;
      }
      final dueAt = (data['dueAt'] as Timestamp?)?.toDate();
      if (dueAt == null) continue;
      final dueDay = DateTime(dueAt.year, dueAt.month, dueAt.day);
      final overdue = dueDay.isBefore(today);
      final dueToday = dueDay == today;
      if (!overdue && !dueToday) continue;

      _notifiedTaskIds.add(doc.id);
      final title = data['title'] as String? ?? 'Görev';
      await TaskDueLocalNotifications.instance.showTaskDue(
        notificationId: doc.id.hashCode & 0x7fffffff,
        title: overdue ? 'Gecikmiş görev' : 'Bugün vadesi dolan görev',
        body: title,
        taskId: doc.id,
        customerId: data['customerId'] as String?,
      );
      break;
    }
  }
}
