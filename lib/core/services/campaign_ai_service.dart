import 'package:cloud_functions/cloud_functions.dart';

import '../../features/campaigns/presentation/pages/bulk_campaign_page.dart';

/// Toplu kampanya metin önerileri için AI servis katmanı.
class CampaignAiService {
  CampaignAiService._();

  /// Firebase Cloud Functions üzerinden kampanya metni üretir.
  /// Backend tarafında `generateBulkCampaignMessage` callable fonksiyonu beklenir.
  static Future<String> suggestMessageForSegment({
    required BulkCampaignSegment segment,
    required String currentMessage,
  }) async {
    final functions = FirebaseFunctions.instanceFor(region: 'europe-west1');
    final callable = functions.httpsCallable('generateBulkCampaignMessage');
    final response = await callable.call<Map<String, dynamic>>({
      'currentMessage': currentMessage,
      'stats': {
        'totalCustomers': segment.customers.length,
        'phoneCount': segment.activePhonesCount,
      },
      'sampleCustomers': segment.customers.take(5).map((c) {
        return {
          'fullName': c.fullName,
          'primaryPhone': c.primaryPhone,
          'budgetMin': c.budgetMin,
          'budgetMax': c.budgetMax,
          'regions': c.regionPreferences,
          'leadTemperature': c.leadTemperature,
          'lastInteractionAt': c.lastInteractionAt?.toIso8601String(),
        };
      }).toList(),
    });
    final data = response.data;
    final text = data['message'] as String? ?? data['text'] as String?;
    if (text == null || text.trim().isEmpty) {
      throw Exception('Boş yanıt döndü');
    }
    return text.trim();
  }
}

