import 'package:emlakmaster_mobile/features/ai_agent/application/heuristic_task_engine.dart';
import 'package:emlakmaster_mobile/features/ai_agent/domain/axion_agent_enums.dart';
import 'package:emlakmaster_mobile/features/ai_agent/domain/axion_agent_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 6, 11, 12);

  AxionAgentContext ctx({
    List<AxionCustomerSnapshot> customers = const [],
    List<AxionTaskSnapshot> tasks = const [],
    List<AxionCallSnapshot> calls = const [],
  }) {
    return AxionAgentContext(
      userId: 'u1',
      role: 'consultant',
      workspaceId: 'w1',
      now: now,
      customerSnapshots: customers,
      taskSnapshots: tasks,
      callSnapshots: calls,
    );
  }

  group('HeuristicTaskEngine', () {
    test('geciken görev önerisi üretir; 7+ gün kritik', () {
      final result = ctx(tasks: [
        AxionTaskSnapshot(
          id: 't1',
          title: 'Müşteriyi ara',
          dueAt: now.subtract(const Duration(days: 8)),
        ),
        AxionTaskSnapshot(
          id: 't2',
          title: 'Dosya hazırla',
          dueAt: now.subtract(const Duration(hours: 60)),
        ),
      ]);
      final suggestions = HeuristicTaskEngine.generate(result);

      final critical =
          suggestions.firstWhere((s) => s.targetId == 't1');
      expect(critical.urgency, AxionAgentUrgency.critical);
      expect(critical.title, 'Geciken görevi tamamla');
      expect(critical.reason, 'Bu görev zamanında tamamlanmamış.');

      final high = suggestions.firstWhere((s) => s.targetId == 't2');
      expect(high.urgency, AxionAgentUrgency.high);
    });

    test('sessiz sıcak müşteri yüksek aciliyetli öneri üretir', () {
      final suggestions = HeuristicTaskEngine.generate(ctx(customers: [
        AxionCustomerSnapshot(
          id: 'c1',
          name: 'Ali Veli',
          phone: '5551112233',
          region: 'Kadıköy',
          budgetMin: 1000000,
          propertyType: 'daire',
          intent: 'satılık',
          temperature: AxionCustomerTemperature.hot,
          lastContactAt: now.subtract(const Duration(days: 5)),
        ),
      ]));

      final silent = suggestions.firstWhere((s) => s.id == 'silent-c1');
      expect(silent.urgency, AxionAgentUrgency.high);
      expect(silent.sourceType, AxionAgentSourceType.rules);
      expect(silent.evidence, isNotEmpty);
    });

    test('cevapsız arama + takip görevi yok → geri dönüş önerisi', () {
      final suggestions = HeuristicTaskEngine.generate(ctx(
        customers: const [
          AxionCustomerSnapshot(id: 'c1', name: 'Ayşe', phone: '555'),
        ],
        calls: [
          AxionCallSnapshot(
            id: 'call1',
            customerId: 'c1',
            isMissedOrNoAnswer: true,
            at: now.subtract(const Duration(hours: 2)),
          ),
        ],
      ));

      final cb = suggestions.firstWhere((s) => s.id == 'missed-call-c1');
      expect(cb.actionType, AxionAgentActionType.callCustomer);
      expect(cb.urgency, AxionAgentUrgency.high); // aynı gün
      expect(cb.recommendedAction?.requiresApproval, isTrue);
    });

    test('eksik alan önerisi missingData listeler ve dürüstlük notu taşır',
        () {
      final suggestions = HeuristicTaskEngine.generate(ctx(customers: const [
        AxionCustomerSnapshot(id: 'c1', name: 'Mehmet'),
      ]));

      final missing =
          suggestions.firstWhere((s) => s.id == 'missing-data-c1');
      expect(missing.missingData, containsAll(['bütçe', 'bölge', 'telefon']));
      expect(missing.honestyNote, isNotNull);
      expect(missing.actionType, AxionAgentActionType.updateCustomerInfo);
    });

    test('aynı müşteri + aynı eylem türü için tekrar öneri üretmez', () {
      final suggestions = HeuristicTaskEngine.generate(ctx(customers: [
        AxionCustomerSnapshot(
          id: 'c1',
          name: 'Ali',
          temperature: AxionCustomerTemperature.hot,
          lastContactAt: now.subtract(const Duration(days: 30)),
        ),
      ]));

      final keys = suggestions.map((s) => s.dedupeKey).toList();
      expect(keys.toSet().length, keys.length,
          reason: 'dedupeKey çakışması olmamalı');
    });

    test('veri yoksa öneri üretmez (sahte veri yok)', () {
      expect(HeuristicTaskEngine.generate(ctx()), isEmpty);
    });
  });
}
