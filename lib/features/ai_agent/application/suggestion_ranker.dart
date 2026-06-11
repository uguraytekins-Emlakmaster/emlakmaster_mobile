import '../domain/axion_agent_enums.dart';
import '../domain/axion_agent_models.dart';
import '../domain/axion_agent_policy.dart';

/// Hızlı sıralama motoru — tek sort, sınırlı çıktı.
///
/// Sıralama önceliği:
/// 1. Aciliyet  2. Son tarihe yakınlık  3. Eylenebilirlik  4. Tazelik
abstract final class SuggestionRanker {
  static List<AxionAgentSuggestion> rank(
    List<AxionAgentSuggestion> input, {
    int cap = AxionAgentPolicy.maxConsultantSuggestions,
  }) {
    if (input.isEmpty) return const [];
    final sorted = [...input]..sort(_compare);
    return sorted.length <= cap
        ? sorted
        : sorted.sublist(0, cap);
  }

  static int _compare(AxionAgentSuggestion a, AxionAgentSuggestion b) {
    // 1) Aciliyet (yüksek önce)
    final u = b.urgency.weight.compareTo(a.urgency.weight);
    if (u != 0) return u;

    // 2) Eylenebilirlik: somut eylem önerisi olan önce
    final actA = a.actionType != AxionAgentActionType.noAction ? 1 : 0;
    final actB = b.actionType != AxionAgentActionType.noAction ? 1 : 0;
    if (actA != actB) return actB.compareTo(actA);

    // 3) Güven (yüksek önce)
    final c = b.confidence.index.compareTo(a.confidence.index);
    if (c != 0) return c;

    // 4) Tazelik (yeni önce)
    return b.createdAt.compareTo(a.createdAt);
  }
}
