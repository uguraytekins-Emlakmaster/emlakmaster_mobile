// Müşterilerim workspace — yalnızca GERÇEK CRM sinyalleri: gerçek müşteri
// kayıtları (ad/telefon/e-posta), kural tabanlı (deterministik, LLM değil)
// sıcaklık bandı, gerçek son etkileşim/güncelleme tarihi ve kayıt bütünlüğü.
// Uydurma CRM skoru, sahte AI lead sıralaması, icat edilmiş temas geçmişi veya
// gerçek olmayan "geciken SLA" GÖSTERİLMEZ. Sunucuda tutulmayan sinyaller
// dürüstçe işaretlenir veya sessizce atlanır.

import 'package:emlakmaster_mobile/features/crm_customers/domain/customer_heat_score.dart';

/// Yatay filtreler — yalnızca grounded kategoriler. Tür filtreleri (Konut/Arsa)
/// listede tipli gerçek veri olmadığı için bilinçle gösterilmez. "Geciken" diye
/// gerçek bir SLA alanı olmadığından "Temas gerekli" (durağan temas) dürüst
/// karşılığı kullanılır.
enum CustomerWorkspaceFilter {
  all,
  hot,
  warm,
  cold,
  today,
  fresh,
  needsContact,
  partial,
}

extension CustomerWorkspaceFilterLabel on CustomerWorkspaceFilter {
  String get label => switch (this) {
        CustomerWorkspaceFilter.all => 'Tümü',
        CustomerWorkspaceFilter.hot => 'Sıcak',
        CustomerWorkspaceFilter.warm => 'Ilık',
        CustomerWorkspaceFilter.cold => 'Soğuk',
        CustomerWorkspaceFilter.today => 'Bugün',
        CustomerWorkspaceFilter.fresh => 'Yeni',
        CustomerWorkspaceFilter.needsContact => 'Temas gerekli',
        CustomerWorkspaceFilter.partial => 'Kısmi',
      };
}

/// Renk tonu — widget katmanında tema rengine eşlenir.
enum CustomerTone { hot, warm, cool, cold, attention, partial, fresh, neutral }

/// Önceden hesaplanmış satır görünümü. Tüm gösterim metni snapshot katmanında
/// üretilir; build() içinde format/hesap yapılmaz.
class CustomerRowView {
  const CustomerRowView({
    required this.id,
    required this.name,
    required this.initial,
    required this.contactLine,
    required this.heatLevel,
    required this.heatLabel,
    required this.heatScore,
    required this.heatReason,
    required this.lastContactLabel,
    required this.lastContactColorType,
    required this.contextLine,
    required this.nextActionLabel,
    required this.tone,
    required this.isHot,
    required this.isWarm,
    required this.isCold,
    required this.isToday,
    required this.isFresh,
    required this.needsContact,
    required this.isPartial,
    required this.partialNote,
    required this.callablePhone,
    required this.phone,
    required this.hasPhone,
    required this.hasEmail,
    required this.syncRisk,
    required this.isDemo,
    required this.sortRank,
    required this.searchText,
  });

  final String id;
  final String name;
  final String initial;

  /// Telefon veya e-posta (gerçek) — yoksa dürüst yer tutucu.
  final String contactLine;

  final CustomerHeatLevel heatLevel;
  final String heatLabel;
  final int heatScore;

  /// Kısa kural tabanlı sıcaklık gerekçesi (LLM değil).
  final String heatReason;

  /// Son etkileşim/güncelleme etiketi (Az önce/Bugün/…); gerçek tarihten.
  final String lastContactLabel;
  final int lastContactColorType;

  /// Tek satır bağlam (sonraki adım veya sıcaklık gerekçesi).
  final String contextLine;

  /// Gerçek `nextSuggestedAction` varsa; yoksa boş (uydurma adım yok).
  final String nextActionLabel;

  final CustomerTone tone;

  final bool isHot;
  final bool isWarm;
  final bool isCold;

  /// Bugün kaydedilen son aktivite (etkileşim/güncelleme).
  final bool isToday;

  /// Son 7 günde oluşturulmuş kayıt.
  final bool isFresh;

  /// ≥14 gündür kayıtlı aktivite yok (durağan temas — dürüst proxy).
  final bool needsContact;

  /// Ad veya iletişim bilgisi eksik kayıt.
  final bool isPartial;
  final String partialNote;

  final bool callablePhone;
  final String? phone;
  final bool hasPhone;
  final bool hasEmail;

  final bool syncRisk;
  final bool isDemo;

  /// Düşük = daha öncelikli (dikkat-önce sıralama).
  final int sortRank;

  final String searchText;
}

/// Özet şeridi — yalnızca gerçek sayımlar; uydurma KPI yok.
class CustomerWorkspaceSummary {
  const CustomerWorkspaceSummary({
    required this.active,
    required this.hot,
    required this.needsContact,
    required this.partial,
    required this.today,
  });

  final int active;
  final int hot;
  final int needsContact;
  final int partial;
  final int today;

  static const empty = CustomerWorkspaceSummary(
    active: 0,
    hot: 0,
    needsContact: 0,
    partial: 0,
    today: 0,
  );
}

class CustomerWorkspaceSnapshot {
  const CustomerWorkspaceSnapshot({
    required this.rows,
    required this.summary,
    required this.coverageNote,
    required this.isEmpty,
    this.hasMore = false,
    this.uid = '',
  });

  /// Dikkat-önce sıralı tam liste (sıcak/temas gerekli üstte).
  final List<CustomerRowView> rows;
  final CustomerWorkspaceSummary summary;
  final String coverageNote;
  final bool isEmpty;

  /// Sayfalama — sunucuda daha fazla kayıt var mı (gerçek `hasMore`).
  final bool hasMore;
  final String uid;

  CustomerWorkspaceSnapshot copyWith({bool? hasMore, String? uid}) {
    return CustomerWorkspaceSnapshot(
      rows: rows,
      summary: summary,
      coverageNote: coverageNote,
      isEmpty: isEmpty,
      hasMore: hasMore ?? this.hasMore,
      uid: uid ?? this.uid,
    );
  }
}

/// Saf/test edilebilir giriş DTO'su — Firebase/Firestore tipleri compute'a sızmaz.
class CustomerWorkspaceInput {
  const CustomerWorkspaceInput({
    required this.id,
    this.name,
    this.phone,
    this.email,
    required this.heatLevel,
    required this.heatScore,
    required this.heatReason,
    required this.lastInteractionAt,
    required this.createdAt,
    required this.updatedAt,
    this.nextSuggestedAction,
    required this.callablePhone,
    required this.syncRisk,
    required this.isDemo,
  });

  final String id;
  final String? name;
  final String? phone;
  final String? email;
  final CustomerHeatLevel heatLevel;
  final int heatScore;
  final String heatReason;
  final DateTime? lastInteractionAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? nextSuggestedAction;
  final bool callablePhone;
  final bool syncRisk;
  final bool isDemo;
}
