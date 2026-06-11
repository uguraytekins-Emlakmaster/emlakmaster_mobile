import 'axion_agent_enums.dart';

/// Axion Agent politika sabitleri — tüm kurallar deterministik ve
/// buradan yapılandırılabilir. Sihirli sayı yok, sahte skor yok.
abstract final class AxionAgentPolicy {
  // --- Sessiz müşteri eşikleri (gün) ---
  static const int hotSilentDays = 3;
  static const int warmSilentDays = 7;
  static const int coldSilentDays = 21;

  // --- Geciken görev eşikleri ---
  static const int overdueHighHours = 48;
  static const int overdueCriticalDays = 7;

  // --- Fırsat eskime eşiği ---
  static const int staleOpportunityDays = 10;

  // --- Cevapsız arama eşiği ---
  static const int missedCallMediumDays = 2;

  // --- Sonuç limitleri (performans: sıralamadan önce kırp) ---
  static const int maxConsultantSuggestions = 20;
  static const int maxDailyPlanTopPriorities = 5;
  static const int maxBrokerAttentionAreas = 10;
  static const int maxPortfolioMatchesPerCustomer = 5;
  static const int maxInputSnapshotCap = 500;

  // --- Öneri geçerlilik süresi ---
  static const Duration suggestionTtl = Duration(hours: 12);

  // --- Önbellek ---
  static const int maxCacheEntries = 64;
  static const Duration cacheTtl = Duration(minutes: 15);

  /// Hiçbir mod/rol altında çalıştırılamayacak işlemler.
  static const Set<AxionAgentOperation> permanentlyBlocked = {
    AxionAgentOperation.autoSendMessage,
    AxionAgentOperation.deleteCustomer,
    AxionAgentOperation.autoCloseTask,
    AxionAgentOperation.bulkExternalMessage,
    AxionAgentOperation.fakePerformanceAnalysis,
  };

  /// Onay gerektiren eylem türleri. [AxionAgentActionType.noAction] hariç
  /// tümü onay ister — bilgilendirme dışındaki hiçbir şey otomatik uygulanmaz.
  static bool requiresApproval(AxionAgentActionType type) =>
      type != AxionAgentActionType.noAction;

  /// V1'de gelişmiş AI gerektiren işlemler için dürüst geri bildirim metni.
  static const String freeModeFallbackNote =
      'Bu işlem gelişmiş AI gerektirebilir. Ücretsiz modda kural tabanlı öneri sunuldu.';

  /// Kısmi veri dürüstlük notları.
  static const String partialDataNote =
      'Veri eksik olduğu için öneri kısmi olabilir.';
  static const String recordsLimitedNote =
      'Bu özet mevcut kayıtlarla sınırlıdır.';
  static const String freeRulesNote =
      'Bu çıktı kural tabanlı ücretsiz modda oluşturuldu.';
  static const String externalSendWarning =
      'Göndermeden önce kontrol edin. Mesaj otomatik gönderilmez.';
}
