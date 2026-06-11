import 'package:emlakmaster_mobile/features/ai_agent/application/consultant_daily_plan_engine.dart';
import 'package:emlakmaster_mobile/features/ai_agent/domain/axion_agent_enums.dart';
import 'package:emlakmaster_mobile/features/ai_agent/domain/axion_agent_models.dart';
import 'package:emlakmaster_mobile/features/ai_agent/domain/axion_agent_policy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 6, 11, 9);

  group('ConsultantDailyPlanEngine', () {
    test('kritik geciken görevler öncelik listesinin başındadır', () {
      final ctx = AxionAgentContext(
        userId: 'u1',
        role: 'consultant',
        workspaceId: 'w1',
        now: now,
        customerSnapshots: const [
          AxionCustomerSnapshot(id: 'c1', name: 'Düşük', phone: '1'),
        ],
        taskSnapshots: [
          AxionTaskSnapshot(
            id: 't-critical',
            title: 'Kritik görev',
            dueAt: now.subtract(const Duration(days: 10)),
          ),
        ],
      );
      final plan = ConsultantDailyPlanEngine.generate(ctx);

      expect(plan.topPriorities, isNotEmpty);
      expect(plan.topPriorities.first.urgency, AxionAgentUrgency.critical);
      expect(plan.topPriorities.first.targetId, 't-critical');
    });

    test('öncelikler en fazla 5 ile sınırlıdır', () {
      final ctx = AxionAgentContext(
        userId: 'u1',
        role: 'consultant',
        workspaceId: 'w1',
        now: now,
        taskSnapshots: [
          for (var i = 0; i < 15; i++)
            AxionTaskSnapshot(
              id: 't$i',
              title: 'Görev $i',
              dueAt: now.subtract(const Duration(days: 3)),
            ),
        ],
      );
      final plan = ConsultantDailyPlanEngine.generate(ctx);
      expect(
        plan.topPriorities.length,
        lessThanOrEqualTo(AxionAgentPolicy.maxDailyPlanTopPriorities),
      );
    });

    test('kısmi veri varsa dürüstlük notu içerir', () {
      final ctx = AxionAgentContext(
        userId: 'u1',
        role: 'consultant',
        workspaceId: 'w1',
        now: now,
        customerSnapshots: const [
          AxionCustomerSnapshot(id: 'c1', name: 'Eksik Veri'),
        ],
      );
      final plan = ConsultantDailyPlanEngine.generate(ctx);
      expect(plan.honestyNote, AxionAgentPolicy.partialDataNote);
    });

    test('sahte üretkenlik skoru içermez (model alanı yok)', () {
      final ctx = AxionAgentContext(
        userId: 'u1',
        role: 'consultant',
        workspaceId: 'w1',
        now: now,
      );
      final plan = ConsultantDailyPlanEngine.generate(ctx);
      // Plan yalnızca gerçek öneri listeleri ve dürüstlük notu taşır.
      expect(plan.isEmpty, isTrue);
      expect(plan.consultantId, 'u1');
      expect(plan.generatedAt, now);
    });

    test('geri dönülecek müşteriler için mesaj taslağı üretir', () {
      final ctx = AxionAgentContext(
        userId: 'u1',
        role: 'consultant',
        workspaceId: 'w1',
        now: now,
        customerSnapshots: [
          AxionCustomerSnapshot(
            id: 'c1',
            name: 'Ali',
            phone: '555',
            region: 'Moda',
            temperature: AxionCustomerTemperature.hot,
            lastContactAt: now.subtract(const Duration(days: 6)),
          ),
        ],
      );
      final plan = ConsultantDailyPlanEngine.generate(ctx);
      expect(plan.customersToCall, isNotEmpty);
      expect(plan.messageDrafts, isNotEmpty);
      expect(plan.messageDrafts.first.requiresReview, isTrue);
    });
  });
}
