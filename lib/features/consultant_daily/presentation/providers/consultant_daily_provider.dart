import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emlakmaster_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/providers/consultant_calls_provider.dart';
import 'package:emlakmaster_mobile/features/consultant_daily/presentation/utils/consultant_daily_snapshot.dart';
import 'package:emlakmaster_mobile/features/consultant_daily/presentation/utils/consultant_daily_types.dart';
import 'package:emlakmaster_mobile/features/crm_customers/presentation/providers/customer_list_stream_provider.dart';
import 'package:emlakmaster_mobile/features/tasks/presentation/providers/advisor_tasks_stream_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

String _firstName(User? user) {
  final dn = user?.displayName?.trim();
  if (dn != null && dn.isNotEmpty) return dn.split(RegExp(r'\s+')).first;
  final email = user?.email;
  if (email != null && email.contains('@')) return email.split('@').first;
  return '';
}

/// Tek türetilmiş snapshot — görev + atanmış müşteri + bugünkü temas (hepsi
/// danışmana scoped, gerçek). Görevler birincil (loading/error kaynağı);
/// müşteri/çağrı geç gelirse boş varsayılır (ilk boya hızlı kalır).
final consultantDailySnapshotProvider =
    Provider.autoDispose<AsyncValue<ConsultantDailySnapshot>>((ref) {
  final authAsync = ref.watch(currentUserProvider);
  final uid = authAsync.valueOrNull?.uid ?? '';
  final greeting = _firstName(authAsync.valueOrNull);

  if (uid.isEmpty) {
    // Oturum yok / hazır değil → boş ama hatasız.
    return AsyncData(
      ConsultantDailySnapshot(
        entries: const [],
        summary: ConsultantDailySummary.empty,
        greetingName: greeting,
        coverageNote:
            'Oturum bilgisi bekleniyor. Giriş yaptığınızda günlük göreviniz '
            've müşteri baskınız burada görünecek.',
        isEmpty: true,
      ),
    );
  }

  final tasksAsync = ref.watch(advisorTasksStreamProvider(uid));
  final customersAsync = ref.watch(customerListForAgentProvider);
  final callsAsync = ref.watch(consultantCallsStreamProvider);

  return tasksAsync.when(
    loading: () => const AsyncValue.loading(),
    error: (e, st) => AsyncValue.error(e, st),
    data: (taskSnap) {
      final now = DateTime.now();

      final tasks = taskSnap.docs.map((d) {
        final data = d.data();
        final cid = (data['customerId'] as String?)?.trim();
        return DailyTaskInput(
          id: d.id,
          title: (data['title'] as String?)?.trim().isNotEmpty == true
              ? (data['title'] as String).trim()
              : 'Görev',
          done: data['done'] == true,
          customerId: (cid != null && cid.isNotEmpty) ? cid : null,
          dueAt: (data['dueAt'] as Timestamp?)?.toDate() ??
              (data['dueDate'] as Timestamp?)?.toDate(),
        );
      }).toList(growable: false);

      final customers = customersAsync.valueOrNull?.entities ?? const [];

      final callDocs = callsAsync.valueOrNull?.docs ?? const [];
      var todayContacts = 0;
      for (final d in callDocs) {
        final ts = d.data()['createdAt'] as Timestamp?;
        if (ts == null) continue;
        final dt = ts.toDate();
        if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
          todayContacts++;
        }
      }

      return AsyncData(
        computeConsultantDailySnapshot(
          tasks: tasks,
          customers: customers,
          todayContactCount: todayContacts,
          greetingName: greeting,
          now: now,
        ),
      );
    },
  );
});
