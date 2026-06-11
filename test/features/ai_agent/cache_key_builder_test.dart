import 'package:emlakmaster_mobile/features/ai_agent/application/axion_agent_cache_key_builder.dart';
import 'package:emlakmaster_mobile/features/ai_agent/domain/axion_agent_enums.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final updatedAtA = DateTime(2026, 6, 10, 9);
  final updatedAtB = DateTime(2026, 6, 11, 14);

  String build({
    String role = 'consultant',
    AxionAgentMode mode = AxionAgentMode.freeRules,
    List<DateTime?> stamps = const [],
    String locale = 'tr',
  }) {
    return AxionAgentCacheKeyBuilder.build(
      workspaceId: 'w1',
      userId: 'u1',
      role: role,
      operationType: AxionAgentOperation.generateDailyPlan,
      relevantUpdatedAt: stamps,
      mode: mode,
      locale: locale,
    );
  }

  group('AxionAgentCacheKeyBuilder', () {
    test('aynı girdi → aynı anahtar (deterministik)', () {
      final k1 = build(stamps: [updatedAtA]);
      final k2 = build(stamps: [updatedAtA]);
      expect(k1, k2);
    });

    test('updatedAt değişince anahtar değişir', () {
      final k1 = build(stamps: [updatedAtA]);
      final k2 = build(stamps: [updatedAtB]);
      expect(k1, isNot(k2));
    });

    test('updatedAt sırası anahtarı etkilemez', () {
      final k1 = build(stamps: [updatedAtA, updatedAtB]);
      final k2 = build(stamps: [updatedAtB, updatedAtA]);
      expect(k1, k2);
    });

    test('rol değişince anahtar değişir', () {
      expect(build(), isNot(build(role: 'broker')));
    });

    test('mod değişince anahtar değişir', () {
      expect(build(), isNot(build(mode: AxionAgentMode.off)));
    });

    test('locale değişince anahtar değişir', () {
      expect(build(), isNot(build(locale: 'en')));
    });

    test('null updatedAt güvenle işlenir', () {
      final k = build(stamps: [null, updatedAtA]);
      expect(k, isNotEmpty);
    });
  });
}
