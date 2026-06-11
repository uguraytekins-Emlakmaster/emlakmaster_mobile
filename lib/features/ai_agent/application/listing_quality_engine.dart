import '../domain/axion_agent_enums.dart';
import '../domain/axion_agent_models.dart';
import '../domain/axion_agent_policy.dart';

/// Eksik portföy bilgisi tespiti.
///
/// Sahte kalite skoru YOK — yalnızca eksik alan sayımı ve net eylem.
abstract final class ListingQualityEngine {
  static List<AxionAgentSuggestion> analyze({
    required List<AxionListingSnapshot> listings,
    required DateTime now,
  }) {
    final suggestions = <AxionAgentSuggestion>[];

    for (final l
        in listings.take(AxionAgentPolicy.maxInputSnapshotCap)) {
      final missing = <String>[
        if (l.price == null) 'fiyat',
        if (!l.hasLocation) 'konum',
        if (!l.hasCoverImage) 'kapak görseli',
        if ((l.propertyType ?? '').trim().isEmpty) 'mülk tipi',
        if (l.roomCount == null) 'oda sayısı',
        if ((l.description ?? '').trim().length < 20) 'açıklama',
        if (!l.hasOwnerContact) 'sahip/iletişim',
        if ((l.status ?? '').trim().isEmpty) 'durum',
      ];
      if (missing.isEmpty) continue;

      final title = switch (missing.first) {
        'fiyat' => 'Portföy fiyat bilgisini tamamla',
        'kapak görseli' => 'Kapak görseli eksik',
        'konum' => 'Konum bilgisi eksik',
        'açıklama' => 'Açıklama zayıf / eksik',
        _ => 'Eksik portföy bilgisini tamamla',
      };

      suggestions.add(AxionAgentSuggestion(
        id: 'listing-quality-${l.id}',
        title: title,
        description:
            '${l.title.isEmpty ? 'Portföy' : l.title}: ${missing.length} eksik alan (${missing.join(', ')}).',
        reason: 'Eksik bilgi, portföyün eşleşme ve sunum kalitesini düşürür.',
        sourceType: AxionAgentSourceType.rules,
        confidence: AxionAgentConfidence.high,
        urgency: missing.contains('fiyat') || missing.length >= 4
            ? AxionAgentUrgency.medium
            : AxionAgentUrgency.low,
        actionType: AxionAgentActionType.completeListingInfo,
        recommendedAction: AxionRecommendedAction(
          type: AxionAgentActionType.completeListingInfo,
          title: 'Portföyü düzenle',
          requiresApproval: true,
          payload: {'listingId': l.id, 'missing': missing},
        ),
        targetType: 'listing',
        targetId: l.id,
        createdAt: now,
        expiresAt: now.add(AxionAgentPolicy.suggestionTtl),
        missingData: missing,
        evidence: ['Eksik alan sayısı: ${missing.length}'],
      ));
    }

    return suggestions;
  }
}
