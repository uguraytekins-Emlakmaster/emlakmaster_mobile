import 'axion_agent_models.dart';

/// Denetim kayıt deposu arayüzü.
///
/// V1: backend yazımı riskli olabileceği için yalnızca arayüz + yerel stub
/// (data/axion_agent_audit_repository.dart) sağlanır. Backend implementasyonu
/// ileride güvenli şekilde eklenebilir.
abstract interface class AxionAgentAuditRepository {
  Future<void> record(AxionAuditEvent event);

  /// Son olayları döndürür (yeniden eskiye). Yerel stub bellek içidir.
  Future<List<AxionAuditEvent>> recent({int limit = 50});
}

/// Öneri yaşam döngüsü deposu arayüzü (V1: bellek içi; ileride Firestore).
abstract interface class AxionAgentSuggestionStore {
  Future<void> save(AxionAgentSuggestion suggestion);
  Future<AxionAgentSuggestion?> byId(String id);
  Future<List<AxionAgentSuggestion>> pendingForUser(String userId);
}
