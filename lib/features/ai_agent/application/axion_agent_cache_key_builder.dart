import '../domain/axion_agent_enums.dart';

/// Deterministik önbellek anahtarı üretici.
///
/// Aynı girdi parmak izi → aynı anahtar → önbellekten sunum.
/// updatedAt değerlerinden herhangi biri değişirse anahtar değişir.
abstract final class AxionAgentCacheKeyBuilder {
  static String build({
    required String workspaceId,
    required String userId,
    required String role,
    required AxionAgentOperation operationType,
    String targetId = '',
    List<DateTime?> relevantUpdatedAt = const [],
    AxionAgentMode mode = AxionAgentMode.freeRules,
    String locale = 'tr',
  }) {
    // updatedAt parmak izi: sıra bağımsız ve deterministik olması için
    // milisaniye değerleri sıralanır.
    final stamps = relevantUpdatedAt
        .map((d) => d?.millisecondsSinceEpoch ?? 0)
        .toList(growable: false)
      ..sort();

    final buffer = StringBuffer()
      ..write(workspaceId)
      ..write('|')
      ..write(userId)
      ..write('|')
      ..write(role)
      ..write('|')
      ..write(operationType.name)
      ..write('|')
      ..write(targetId)
      ..write('|')
      ..write(mode.name)
      ..write('|')
      ..write(locale)
      ..write('|')
      ..write(stamps.join(','));

    return buffer.toString();
  }
}
