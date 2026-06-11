import 'package:emlakmaster_mobile/features/ai_agent/application/axion_agent_gate.dart';
import 'package:emlakmaster_mobile/features/ai_agent/domain/axion_agent_enums.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AxionAgentGate', () {
    test('cloud kapalı: freeRules modunda kaynak asla cloud/paid olmaz', () {
      final d = AxionAgentGate.decide(
        operation: AxionAgentOperation.generateSuggestions,
        role: 'consultant',
        mode: AxionAgentMode.freeRules,
      );
      expect(d.allowed, isTrue);
      expect(d.requiresPaidProvider, isFalse);
      expect(d.requiresNetwork, isFalse);
      expect(
        d.sourceType,
        anyOf(
          AxionAgentSourceType.rules,
          AxionAgentSourceType.template,
          AxionAgentSourceType.cache,
        ),
      );
    });

    test('otomatik mesaj gönderimi her modda engellenir', () {
      for (final mode in AxionAgentMode.values) {
        final d = AxionAgentGate.decide(
          operation: AxionAgentOperation.autoSendMessage,
          role: 'admin',
          mode: mode,
        );
        expect(d.allowed, isFalse, reason: 'mode=$mode');
        expect(d.blockedReason, isNotNull);
      }
    });

    test('müşteri silme engellenir', () {
      final d = AxionAgentGate.decide(
        operation: AxionAgentOperation.deleteCustomer,
        role: 'admin',
        mode: AxionAgentMode.freeRules,
      );
      expect(d.allowed, isFalse);
    });

    test('otomatik görev kapatma ve toplu dış mesaj engellenir', () {
      for (final op in [
        AxionAgentOperation.autoCloseTask,
        AxionAgentOperation.bulkExternalMessage,
        AxionAgentOperation.fakePerformanceAnalysis,
      ]) {
        final d = AxionAgentGate.decide(
          operation: op,
          role: 'broker',
          mode: AxionAgentMode.freeRules,
        );
        expect(d.allowed, isFalse, reason: 'op=$op');
      }
    });

    test('freeRules: mesaj taslağı template kaynaklı döner', () {
      final d = AxionAgentGate.decide(
        operation: AxionAgentOperation.generateMessageDraft,
        role: 'consultant',
        mode: AxionAgentMode.freeRules,
      );
      expect(d.allowed, isTrue);
      expect(d.sourceType, AxionAgentSourceType.template);
    });

    test('cache hit: cache kaynaklı izin', () {
      final d = AxionAgentGate.decide(
        operation: AxionAgentOperation.generateSuggestions,
        role: 'consultant',
        mode: AxionAgentMode.freeRules,
        cacheHit: true,
      );
      expect(d.allowed, isTrue);
      expect(d.useCache, isTrue);
      expect(d.sourceType, AxionAgentSourceType.cache);
    });

    test('yetki hatası: danışman broker brief üretemez', () {
      final d = AxionAgentGate.decide(
        operation: AxionAgentOperation.generateBrokerBrief,
        role: 'consultant',
        mode: AxionAgentMode.freeRules,
      );
      expect(d.allowed, isFalse);
      expect(d.blockedReason, isNotNull);
    });

    test('broker rolü brief üretebilir', () {
      final d = AxionAgentGate.decide(
        operation: AxionAgentOperation.generateBrokerBrief,
        role: 'broker',
        mode: AxionAgentMode.freeRules,
      );
      expect(d.allowed, isTrue);
    });

    test('mod off: üretim yok', () {
      final d = AxionAgentGate.decide(
        operation: AxionAgentOperation.generateSuggestions,
        role: 'consultant',
        mode: AxionAgentMode.off,
      );
      expect(d.allowed, isFalse);
    });

    test('uygulanmamış modlar dürüst fallback notu döner', () {
      final d = AxionAgentGate.decide(
        operation: AxionAgentOperation.generateSuggestions,
        role: 'consultant',
        mode: AxionAgentMode.cloud,
      );
      expect(d.allowed, isTrue);
      expect(d.sourceType, AxionAgentSourceType.rules);
      expect(d.reason, contains('kural tabanlı'));
    });
  });
}
