import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:emlakmaster_mobile/shared/models/customer_models.dart';

/// Firestore müşteri dokümanı → CustomerEntity. Tekil doküman veya sorgu sonucu için kullanılır.
class CustomerMapper {
  CustomerMapper._();

  static DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    if (v is Timestamp) return v.toDate();
    if (v is DateTime) return v;
    return null;
  }

  /// Tek müşteri dokümanından entity üretir. Doküman yoksa null.
  static CustomerEntity? fromDoc(DocumentSnapshot<Map<String, dynamic>>? snapshot) {
    if (snapshot == null || !snapshot.exists || snapshot.data() == null) return null;
    final data = snapshot.data()!;
    final id = snapshot.id;
    final updatedAt = _parseDate(data['updatedAt']) ?? DateTime.now();
    final createdAt = _parseDate(data['createdAt']) ?? updatedAt;
    final fullName = data['fullName'] as String? ??
        data['customerIntent'] as String? ??
        'Müşteri';
    final regionRaw = data['regionPreferences'] ?? data['preferredRegions'];
    final regionList = regionRaw is List
        ? regionRaw.map((e) => e.toString()).toList()
        : <String>[];
    return CustomerEntity(
      id: id,
      fullName: fullName.isEmpty ? 'İsimsiz' : fullName,
      primaryPhone: data['primaryPhone'] as String? ?? data['phone'] as String?,
      email: data['email'] as String?,
      assignedAdvisorId: data['assignedAgentId'] as String?,
      nextSuggestedAction: data['lastNextStepSuggestion'] as String?,
      lastInteractionAt: _parseDate(data['lastInteractionAt']) ?? updatedAt,
      regionPreferences: List<String>.from(regionList),
      callsCount: data['callsCount'] as int? ?? 0,
      visitsCount: data['visitsCount'] as int? ?? 0,
      offersCount: data['offersCount'] as int? ?? 0,
      budgetMin: (data['budgetMin'] as num?)?.toDouble(),
      budgetMax: (data['budgetMax'] as num?)?.toDouble(),
      leadTemperature: (data['leadTemperature'] as num?)?.toDouble(),
      voiceNoteSummary: data['voice_note_summary'] as String? ?? data['voiceNoteSummary'] as String?,
      voiceNoteSummaryUpdatedAt: _parseDate(data['voice_note_summary_updated_at'] ?? data['voiceNoteSummaryUpdatedAt']),
      isVipInvestor: data['is_vip_investor'] as bool? ?? data['isVipInvestor'] as bool? ?? false,
      investmentAlertEnabled: data['investment_alert_enabled'] as bool? ?? data['investmentAlertEnabled'] as bool? ?? false,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
