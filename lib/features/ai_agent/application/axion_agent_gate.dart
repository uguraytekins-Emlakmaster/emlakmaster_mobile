import '../domain/axion_agent_enums.dart';
import '../domain/axion_agent_models.dart';
import '../domain/axion_agent_policy.dart';

/// Axion Agent Gate — her işlem önce buradan geçer.
///
/// V1 garantileri:
/// - Bulut / ücretli sağlayıcı çağrısı ASLA izinli değil
/// - Kalıcı engelli işlemler (otomatik gönderim, müşteri silme, otomatik
///   görev kapatma, toplu dış mesaj, sahte performans analizi) her modda RED
/// - freeRules modunda yalnızca rules/template/cache kaynakları
abstract final class AxionAgentGate {
  static AxionAgentGateDecision decide({
    required AxionAgentOperation operation,
    required String role,
    required AxionAgentMode mode,
    Set<String> permissions = const {},
    bool hasData = true,
    bool cacheHit = false,
  }) {
    // 1) Kalıcı engeller — mod/rol fark etmez.
    if (AxionAgentPolicy.permanentlyBlocked.contains(operation)) {
      return AxionAgentGateDecision(
        allowed: false,
        sourceType: AxionAgentSourceType.manual,
        reason: 'Bu işlem güvenlik politikası gereği engellenmiştir.',
        blockedReason: switch (operation) {
          AxionAgentOperation.autoSendMessage =>
            'Mesajlar otomatik gönderilemez; kullanıcı onayı zorunludur.',
          AxionAgentOperation.deleteCustomer =>
            'Müşteri silme agent üzerinden yapılamaz.',
          AxionAgentOperation.autoCloseTask =>
            'Görevler otomatik kapatılamaz; onay gerekir.',
          AxionAgentOperation.bulkExternalMessage =>
            'Toplu dış mesaj gönderimi engellidir.',
          AxionAgentOperation.fakePerformanceAnalysis =>
            'Gerçek veriye dayanmayan analiz üretilemez.',
          _ => 'Engellenen işlem.',
        },
      );
    }

    // 2) Mod kapalıysa hiçbir üretim yapılmaz.
    if (mode == AxionAgentMode.off) {
      return const AxionAgentGateDecision(
        allowed: false,
        sourceType: AxionAgentSourceType.manual,
        reason: 'Axion Agent kapalı.',
        blockedReason: 'Agent modu "off" — öneri üretimi devre dışı.',
      );
    }

    // 3) V1'de yalnızca freeRules uygulanmıştır; diğer modlar bulut/yerel
    //    sağlayıcı gerektirir ve henüz yoktur → dürüst fallback.
    if (!mode.isImplemented || mode != AxionAgentMode.freeRules) {
      return const AxionAgentGateDecision(
        allowed: true,
        sourceType: AxionAgentSourceType.rules,
        reason: AxionAgentPolicy.freeModeFallbackNote,
        requiresApproval: true,
      );
    }

    // 4) Rol kontrolü: broker brief yalnızca yönetici katmanı.
    if (operation == AxionAgentOperation.generateBrokerBrief) {
      final managerTier = role == 'manager' ||
          role == 'broker' ||
          role == 'admin' ||
          permissions.contains('broker_brief');
      if (!managerTier) {
        return const AxionAgentGateDecision(
          allowed: false,
          sourceType: AxionAgentSourceType.rules,
          reason: 'Operasyon özeti yönetici rolü gerektirir.',
          blockedReason: 'Yetki yok: broker/admin/manager rolü gerekli.',
        );
      }
    }

    // 5) Veri yoksa üretim izinli ama dürüstlük notu zorunlu (boş durum).
    if (!hasData) {
      return const AxionAgentGateDecision(
        allowed: true,
        sourceType: AxionAgentSourceType.rules,
        reason: 'Veri sınırlı — kısmi/boş sonuç dönecek.',
      );
    }

    // 6) Önbellek isabeti.
    if (cacheHit) {
      return const AxionAgentGateDecision(
        allowed: true,
        sourceType: AxionAgentSourceType.cache,
        reason: 'Aynı veri durumu için önbellekten sunuldu.',
        useCache: true,
      );
    }

    // 7) Normal kural/şablon üretimi.
    final sourceType = operation == AxionAgentOperation.generateMessageDraft
        ? AxionAgentSourceType.template
        : AxionAgentSourceType.rules;
    return AxionAgentGateDecision(
      allowed: true,
      sourceType: sourceType,
      reason: AxionAgentPolicy.freeRulesNote,
      requiresApproval:
          operation == AxionAgentOperation.applyApprovedAction,
    );
  }
}
