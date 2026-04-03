import 'package:cloud_functions/cloud_functions.dart';

import '../ai/ai_gate.dart';
import '../ai/heuristic_campaign_message.dart';

/// Toplu kampanya metin önerileri — [AiGate] ile uzak model sınırlı; şablon geri dönüşü her zaman var.
///
/// [sampleCustomers]: Cloud Function sözleşmesi (en fazla ~5 kayıt).
class CampaignAiService {
  CampaignAiService._();

  /// Firebase Cloud Functions: `generateBulkCampaignMessage`. Kapı reddederse veya hata olursa sezgisel metin.
  static Future<String> suggestMessageForSegment({
    required String currentMessage,
    required int totalCustomers,
    required int phoneCount,
    required List<Map<String, dynamic>> sampleCustomers,
  }) async {
    final n = totalCustomers;

    String fallback() => HeuristicCampaignMessage.build(
          customerCount: n,
          phoneCount: phoneCount,
        );

    if (!AiGate.allowCampaignRemote(
      currentMessage: currentMessage,
      segmentCustomerCount: n,
      segmentPhoneCount: phoneCount,
    )) {
      final cached = AiGate.cachedCampaignSuggestion(
        currentMessage: currentMessage,
        segmentCustomerCount: n,
        segmentPhoneCount: phoneCount,
      );
      if (cached != null && cached.trim().isNotEmpty) return cached.trim();
      return fallback();
    }

    try {
      final functions = FirebaseFunctions.instanceFor(region: 'europe-west1');
      final callable = functions.httpsCallable('generateBulkCampaignMessage');
      final response = await callable.call<Map<String, dynamic>>({
        'currentMessage': currentMessage,
        'stats': {
          'totalCustomers': totalCustomers,
          'phoneCount': phoneCount,
        },
        'sampleCustomers': sampleCustomers,
      });
      final data = response.data;
      final text = data['message'] as String? ?? data['text'] as String?;
      if (text == null || text.trim().isEmpty) {
        return fallback();
      }
      final t = text.trim();
      AiGate.markCampaignRemoteSuccess(
        currentMessage: currentMessage,
        segmentCustomerCount: n,
        segmentPhoneCount: phoneCount,
        suggestedText: t,
      );
      return t;
    } catch (_) {
      return fallback();
    }
  }
}
