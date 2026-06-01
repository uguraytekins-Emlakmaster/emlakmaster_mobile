import 'package:emlakmaster_mobile/features/calls/domain/post_call_crm_signals.dart';
import 'package:emlakmaster_mobile/features/consultant_daily/presentation/utils/consultant_daily_filter.dart';
import 'package:emlakmaster_mobile/features/consultant_daily/presentation/utils/consultant_daily_snapshot.dart';
import 'package:emlakmaster_mobile/features/consultant_daily/presentation/utils/consultant_daily_types.dart';
import 'package:emlakmaster_mobile/shared/models/customer_models.dart';
import 'package:flutter_test/flutter_test.dart';

CustomerEntity _cust({
  required String id,
  String? name,
  DateTime? lastInteractionAt,
  PostCallCrmSignals? signals,
  int callsCount = 0,
  DateTime? updatedAt,
  String? phone,
}) {
  final now = DateTime.now();
  return CustomerEntity(
    id: id,
    fullName: name,
    primaryPhone: phone,
    lifecycleStage: LifecycleStage.lead,
    lastInteractionAt: lastInteractionAt,
    lastCallSummarySignals: signals,
    callsCount: callsCount,
    createdAt: now.subtract(const Duration(days: 60)),
    updatedAt: updatedAt ?? now,
  );
}

void main() {
  final now = DateTime(2026, 6, 1, 10);
  DateTime daysAgo(int d) => now.subtract(Duration(days: d));

  List<DailyTaskInput> tasks() => [
        DailyTaskInput(
          id: 't_overdue',
          title: 'Geciken arama',
          done: false,
          customerId: null,
          dueAt: daysAgo(2),
        ),
        DailyTaskInput(
          id: 't_today',
          title: 'Bugünkü ziyaret',
          done: false,
          customerId: 'c_link',
          dueAt: DateTime(2026, 6, 1, 8),
        ),
        DailyTaskInput(
          id: 't_upcoming',
          title: 'Yaklaşan teklif',
          done: false,
          customerId: null,
          dueAt: now.add(const Duration(days: 3)),
        ),
        DailyTaskInput(
          id: 't_done',
          title: 'Biten görev',
          done: true,
          customerId: null,
          dueAt: daysAgo(1),
        ),
        DailyTaskInput(
          id: 't_nodue',
          title: 'Vadesiz görev',
          done: false,
          customerId: null,
          dueAt: null,
        ),
      ];

  List<CustomerEntity> customers() => [
        _cust(id: 'A', name: 'Ahmet Stale', lastInteractionAt: daysAgo(40)),
        _cust(id: 'B', name: 'Berk Stale', lastInteractionAt: daysAgo(10)),
        _cust(id: 'C', name: 'Cem Partial', lastInteractionAt: null),
        _cust(
          id: 'D',
          name: 'Deniz Hot',
          lastInteractionAt: daysAgo(2),
          updatedAt: now,
          callsCount: 2,
          phone: '5551112233',
          signals: const PostCallCrmSignals(
            interestLevel: PostCallCrmSignals.interestHigh,
            nextActionHint: 'Acil dön',
            appointmentMentioned: true,
            priceObjection: true,
            followUpUrgency: PostCallCrmSignals.urgencyHigh,
          ),
        ),
        _cust(id: 'E', name: 'Elif Quiet', lastInteractionAt: daysAgo(1)),
      ];

  ConsultantDailySnapshot build() => computeConsultantDailySnapshot(
        tasks: tasks(),
        customers: customers(),
        todayContactCount: 5,
        greetingName: 'Ada',
        now: now,
      );

  group('computeConsultantDailySnapshot', () {
    test('özet yalnızca gerçek/scoped sinyallerden türetilir', () {
      final s = build().summary;
      expect(s.activeTasks, 4); // done hariç
      expect(s.overdue, 3); // 1 geciken görev + 2 geciken takip (A,B)
      expect(s.todayContacts, 5); // scoped çağrı bugün
      expect(s.hotCustomers, 1); // D
      expect(s.customers, 5);
    });

    test('düşük sinyalli güncel müşteri (E) sessizce gizlenir', () {
      final ids = build().entries.map((e) => e.id).toSet();
      expect(ids.contains('cust:E'), isFalse);
      expect(ids.contains('cust:C'), isTrue); // partial dahil
      expect(ids.contains('cust:D'), isTrue); // hot dahil
      expect(ids.contains('follow:A'), isTrue);
      expect(ids.contains('follow:B'), isTrue);
    });

    test('öncelik sıralaması: geciken görev en üstte', () {
      final entries = build().entries;
      expect(entries.first.id, 'task:t_overdue');
      expect(entries.first.isOverdue, isTrue);
    });

    test('partial müşteri dürüst işaretlenir', () {
      final c = build().entries.firstWhere((e) => e.id == 'cust:C');
      expect(c.isPartial, isTrue);
      expect(c.statusLabel, 'Kısmi');
    });

    test('coverage notu performans skorunu reddeder', () {
      expect(build().coverageNote.toLowerCase(), contains('performans skoru'));
    });
  });

  group('filterConsultantDailyEntries', () {
    final entries = build().entries;

    test('görev filtresi', () {
      final r = filterConsultantDailyEntries(entries,
          query: '', filter: ConsultantDailyFilter.task);
      expect(r.length, 4);
      expect(r.every((e) => e.kind == DailyKind.task), isTrue);
    });

    test('takip filtresi', () {
      final r = filterConsultantDailyEntries(entries,
          query: '', filter: ConsultantDailyFilter.followUp);
      expect(r.map((e) => e.id).toSet(), {'follow:A', 'follow:B'});
    });

    test('müşteri filtresi (partial + hot)', () {
      final r = filterConsultantDailyEntries(entries,
          query: '', filter: ConsultantDailyFilter.customer);
      expect(r.map((e) => e.id).toSet(), {'cust:C', 'cust:D'});
    });

    test('bugün filtresi', () {
      final r = filterConsultantDailyEntries(entries,
          query: '', filter: ConsultantDailyFilter.today);
      expect(r.length, 1);
      expect(r.first.id, 'task:t_today');
    });

    test('geciken filtresi (görev + geciken takip)', () {
      final r = filterConsultantDailyEntries(entries,
          query: '', filter: ConsultantDailyFilter.overdue);
      expect(r.map((e) => e.id).toSet(),
          {'task:t_overdue', 'follow:A', 'follow:B'});
    });

    test('öncelikli filtresi', () {
      final r = filterConsultantDailyEntries(entries,
          query: '', filter: ConsultantDailyFilter.priority);
      expect(r.map((e) => e.id).toSet(),
          {'task:t_overdue', 'follow:A', 'cust:D'});
    });

    test('kısmi filtresi', () {
      final r = filterConsultantDailyEntries(entries,
          query: '', filter: ConsultantDailyFilter.partial);
      expect(r.map((e) => e.id).toSet(), {'cust:C'});
    });

    test('arama searchText üzerinden çalışır', () {
      final r = filterConsultantDailyEntries(entries,
          query: 'deniz', filter: ConsultantDailyFilter.all);
      expect(r.length, 1);
      expect(r.first.id, 'cust:D');
    });
  });
}
