/// Axion Agent — Zero-Cost Intelligence Engine V1
///
/// Tüm enum'lar deterministik ve UI/network bağımsızdır.
library;

/// Zeka modu. V1'de yalnızca [off] ve [freeRules] aktiftir.
/// [localOnly], [bringYourOwnKey] ve [cloud] mimari olarak hazırdır,
/// uygulanmamıştır — ücretli/ağ tabanlı çağrı YOK.
enum AxionAgentMode {
  off,
  freeRules,
  localOnly,
  bringYourOwnKey,
  cloud;

  /// V1'de gerçekten çalıştırılabilir modlar.
  bool get isImplemented => this == off || this == freeRules;
}

/// Her öneri/çıktı kaynağını dürüstçe etiketler.
enum AxionAgentSourceType {
  rules,
  template,
  cache,
  localModel,
  bringYourOwnKey,
  cloud,
  manual;

  String get label => switch (this) {
        rules => 'Kural tabanlı',
        template => 'Şablon',
        cache => 'Önbellek',
        localModel => 'Yerel model',
        bringYourOwnKey => 'Kendi anahtarın',
        cloud => 'Bulut',
        manual => 'Manuel',
      };
}

/// Güven seviyesi — veri tamlığına dayanır, sahte AI kesinliği DEĞİL.
enum AxionAgentConfidence {
  low,
  medium,
  high;

  String get label => switch (this) {
        low => 'Düşük güven',
        medium => 'Orta güven',
        high => 'Yüksek güven',
      };
}

/// Aciliyet — tamamen kural tabanlı eşiklerle belirlenir.
enum AxionAgentUrgency {
  low,
  medium,
  high,
  critical;

  String get label => switch (this) {
        low => 'Düşük',
        medium => 'Orta',
        high => 'Yüksek',
        critical => 'Kritik',
      };

  /// Sıralama için sayısal ağırlık (yüksek = önce).
  int get weight => index;
}

/// Önerilen eylem türleri. Bilgilendirme dışındaki her eylem onay gerektirir.
enum AxionAgentActionType {
  createTask,
  draftMessage,
  callCustomer,
  updateCustomerInfo,
  scheduleFollowUp,
  reviewPortfolioMatch,
  completeListingInfo,
  reviewMissedCall,
  brokerReview,
  noAction;

  String get label => switch (this) {
        createTask => 'Görev oluştur',
        draftMessage => 'Mesaj taslağı',
        callCustomer => 'Müşteriyi ara',
        updateCustomerInfo => 'Bilgi güncelle',
        scheduleFollowUp => 'Takip planla',
        reviewPortfolioMatch => 'Eşleşmeyi incele',
        completeListingInfo => 'Portföyü tamamla',
        reviewMissedCall => 'Cevapsızı incele',
        brokerReview => 'Yönetici incelemesi',
        noAction => 'Eylem yok',
      };
}

/// Öneri onay yaşam döngüsü.
enum AxionAgentApprovalStatus {
  pending,
  approved,
  rejected,
  applied,
  expired,
}

/// Gate'in karar verdiği işlemler. Engellenen işlemler asla çalışmaz.
enum AxionAgentOperation {
  generateSuggestions,
  generateDailyPlan,
  generateBrokerBrief,
  generateMessageDraft,
  generatePortfolioMatches,
  generateListingQuality,
  applyApprovedAction,
  // Kalıcı olarak engellenen işlemler:
  autoSendMessage,
  deleteCustomer,
  autoCloseTask,
  bulkExternalMessage,
  fakePerformanceAnalysis,
}

/// Mesaj taslağı kanalları.
enum AxionMessageChannel {
  whatsapp,
  sms,
  internal;

  String get label => switch (this) {
        whatsapp => 'WhatsApp',
        sms => 'SMS',
        internal => 'Uygulama içi',
      };

  bool get isExternal => this != internal;
}

/// Mesaj tonu.
enum AxionMessageTone { professional, warm, short, premium }

/// Mesaj şablon kategorileri.
enum AxionMessageTemplateCategory {
  firstFollowUp,
  silentCustomerReactivation,
  portfolioShare,
  appointmentReminder,
  missingBudgetClarification,
  missingRegionClarification,
  thankYouAfterCall,
  noAnswerCallback,
  priceUpdate,
  documentRequest,
  listingInfoShare,
}

/// Müşteri sıcaklık sınıfı (CRM verisinden gelir; motor uydurma sıcaklık üretmez).
enum AxionCustomerTemperature { hot, warm, cold, unknown }

/// Denetim olay türleri.
enum AxionAuditEventType {
  suggestionCreated,
  suggestionViewed,
  suggestionApproved,
  suggestionRejected,
  actionApplied,
  draftGenerated,
  draftEdited,
  draftCopied,
  gateBlockedAction,
}
