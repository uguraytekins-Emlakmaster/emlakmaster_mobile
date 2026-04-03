import 'package:emlakmaster_mobile/features/calls/domain/post_call_ai_enrichment_input.dart';

/// Maliyet kontrolü: uzak model çağrıları için merkezi kapı (heuristic → cache → gate → model).
///
/// İlkeler: ekran açılışına göre otomatik model yok; düşük değer / tekrar girdide uzak çağrı yok;
/// başarılı uzak sonuçlar [markPostCallRemoteSuccess] / [markCampaignRemoteSuccess] ile dedupe’ye yazılır.
abstract final class AiGate {
  AiGate._();

  static const Duration _postCallDedupeTtl = Duration(minutes: 3);
  static const Duration _campaignCooldown = Duration(seconds: 45);

  /// Özet + transkript birleşik karakter eşiği (anlamsız kısa girdide uzak model atlanır).
  static const int minCharsForPostCallRemote = 24;

  /// Çok kısa arama (yanlış numara) — uzak zenginleştirme genelde değer üretmez.
  static const int minCallDurationSecForRemote = 12;

  static final Map<int, DateTime> _postCallSuccessAt = {};
  static final Map<int, DateTime> _campaignSuccessAt = {};
  static final Map<int, String> _campaignLastText = {};

  static int _combinedHash(PostCallAiEnrichmentInput input) {
    final s = input.summaryForCrm.trim();
    final t = input.transcriptRaw?.trim() ?? '';
    return Object.hash(s.hashCode, t.hashCode);
  }

  static int _campaignHash(String currentMessage, int customerCount, int phoneCount) {
    return Object.hash(currentMessage.hashCode, customerCount, phoneCount);
  }

  /// Post-call [enrichPostCallSummary] uzak çağrısı yapılsın mı?
  ///
  /// [featureCallSummaryEnabled]: Ayarlardan `feature_call_summary`.
  static bool allowPostCallRemote({
    required PostCallAiEnrichmentInput input,
    required bool featureCallSummaryEnabled,
    int? callDurationSec,
  }) {
    if (!featureCallSummaryEnabled) return false;

    if (callDurationSec != null && callDurationSec > 0 && callDurationSec < minCallDurationSecForRemote) {
      return false;
    }

    final ctx = input.enrichmentContextText.trim();
    if (ctx.length < minCharsForPostCallRemote) return false;

    final h = _combinedHash(input);
    final now = DateTime.now();
    _postCallSuccessAt.removeWhere((_, t) => now.difference(t) > _postCallDedupeTtl);
    final prev = _postCallSuccessAt[h];
    if (prev != null && now.difference(prev) < _postCallDedupeTtl) {
      return false;
    }
    return true;
  }

  /// Başarılı uzak sonuç sonrası dedupe anahtarı yazılır.
  static void markPostCallRemoteSuccess(PostCallAiEnrichmentInput input) {
    _postCallSuccessAt[_combinedHash(input)] = DateTime.now();
  }

  /// Toplu kampanya [generateBulkCampaignMessage] uzak çağrısı yapılsın mı?
  static bool allowCampaignRemote({
    required String currentMessage,
    required int segmentCustomerCount,
    required int segmentPhoneCount,
  }) {
    if (segmentPhoneCount < 1) return false;

    final h = _campaignHash(currentMessage, segmentCustomerCount, segmentPhoneCount);
    final now = DateTime.now();
    _campaignSuccessAt.removeWhere((_, t) => now.difference(t) > _campaignCooldown);
    final prev = _campaignSuccessAt[h];
    if (prev != null && now.difference(prev) < _campaignCooldown) {
      return false;
    }
    return true;
  }

  static void markCampaignRemoteSuccess({
    required String currentMessage,
    required int segmentCustomerCount,
    required int segmentPhoneCount,
    required String suggestedText,
  }) {
    final h = _campaignHash(currentMessage, segmentCustomerCount, segmentPhoneCount);
    _campaignSuccessAt[h] = DateTime.now();
    _campaignLastText[h] = suggestedText;
  }

  static String? cachedCampaignSuggestion({
    required String currentMessage,
    required int segmentCustomerCount,
    required int segmentPhoneCount,
  }) {
    final h = _campaignHash(currentMessage, segmentCustomerCount, segmentPhoneCount);
    return _campaignLastText[h];
  }

  /// Test / bellek temizliği.
  static void clearCachesForTests() {
    _postCallSuccessAt.clear();
    _campaignSuccessAt.clear();
    _campaignLastText.clear();
  }
}
