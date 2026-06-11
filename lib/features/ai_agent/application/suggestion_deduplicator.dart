import '../domain/axion_agent_models.dart';

/// Öneri tekilleştirme — aynı hedef + aynı eylem türü tek öneriye iner.
///
/// Çakışmada aciliyeti yüksek olan kazanır.
abstract final class SuggestionDeduplicator {
  static List<AxionAgentSuggestion> dedupe(
    List<AxionAgentSuggestion> input,
  ) {
    final byKey = <String, AxionAgentSuggestion>{};
    for (final s in input) {
      final existing = byKey[s.dedupeKey];
      if (existing == null ||
          s.urgency.weight > existing.urgency.weight) {
        byKey[s.dedupeKey] = s;
      }
    }
    return byKey.values.toList(growable: false);
  }
}
