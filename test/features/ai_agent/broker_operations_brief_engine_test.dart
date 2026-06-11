import 'package:emlakmaster_mobile/features/ai_agent/application/broker_operations_brief_engine.dart';
import 'package:emlakmaster_mobile/features/ai_agent/domain/axion_agent_enums.dart';
import 'package:emlakmaster_mobile/features/ai_agent/domain/axion_agent_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 6, 11, 8);

  group('BrokerOperationsBriefEngine', () {
    test('yalnızca gerçek sayımlar döner', () {
      final ctx = AxionAgentContext(
        userId: 'admin1',
        role: 'broker',
        workspaceId: 'w1',
        now: now,
        customerSnapshots: [
          AxionCustomerSnapshot(
            id: 'c1',
            name: 'Sıcak Müşteri',
            phone: '555',
            temperature: AxionCustomerTemperature.hot,
            lastContactAt: now.subtract(const Duration(days: 1)),
          ),
        ],
        taskSnapshots: [
          AxionTaskSnapshot(
            id: 't1',
            title: 'Geciken',
            dueAt: now.subtract(const Duration(days: 3)),
          ),
          AxionTaskSnapshot(
            id: 't2',
            title: 'Bugün',
            dueAt: now.add(const Duration(hours: 4)),
          ),
        ],
      );
      final brief = BrokerOperationsBriefEngine.generate(ctx);

      expect(brief.realCounts.overdueTasks, 1);
      expect(brief.realCounts.tasksDueToday, 1);
      expect(brief.realCounts.hotCustomersWaiting, 1);
      expect(brief.workspaceId, 'w1');
    });

    test('sahte trend / tahmin içermez; dürüstlük notu vardır', () {
      final ctx = AxionAgentContext(
        userId: 'admin1',
        role: 'broker',
        workspaceId: 'w1',
        now: now,
      );
      final brief = BrokerOperationsBriefEngine.generate(ctx);
      expect(brief.honestyNote, 'Bu özet mevcut kayıtlarla sınırlıdır.');
      // Boş veride dikkat alanı üretilmez (sahte içgörü yok).
      expect(brief.attentionAreas, isEmpty);
    });

    test('dikkat alanlarını gerçek sayımlardan belirler', () {
      final ctx = AxionAgentContext(
        userId: 'admin1',
        role: 'broker',
        workspaceId: 'w1',
        now: now,
        customerSnapshots: const [
          AxionCustomerSnapshot(
            id: 'c1',
            name: 'Hot',
            phone: '555',
            temperature: AxionCustomerTemperature.hot,
          ),
        ],
        taskSnapshots: [
          AxionTaskSnapshot(
            id: 't1',
            title: 'Geciken',
            dueAt: now.subtract(const Duration(days: 5)),
          ),
        ],
      );
      final brief = BrokerOperationsBriefEngine.generate(ctx);
      final titles = brief.attentionAreas.map((s) => s.title).toList();
      expect(titles, contains('Takip bekleyen sıcak müşteriler'));
      expect(titles, contains('Geciken görev yoğunluğu'));
      expect(brief.suggestedReviews, isNotEmpty);
    });

    test('boş veriyi çökmeden işler ve eksik veri notları üretir', () {
      final ctx = AxionAgentContext(
        userId: 'admin1',
        role: 'admin',
        workspaceId: 'w1',
        now: now,
      );
      final brief = BrokerOperationsBriefEngine.generate(ctx);
      expect(brief.realCounts.overdueTasks, 0);
      expect(brief.incompleteDataNotes, isNotEmpty);
      expect(
        brief.incompleteDataNotes,
        contains('Müşteri verisi bulunamadı.'),
      );
    });
  });
}
