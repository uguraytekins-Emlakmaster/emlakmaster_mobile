import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emlakmaster_mobile/core/constants/app_constants.dart';
import 'package:emlakmaster_mobile/core/services/firestore_service.dart';

/// Yüksek getirili ilan eklendiğinde VIP yatırımcılara bildirim yazar.
/// FCM ile gönderim için Cloud Function tetiklenebilir; bu servis Firestore notifications dokümanlarını oluşturur.
class VipNotificationService {
  VipNotificationService._();
  static final VipNotificationService instance = VipNotificationService._();

  /// [listingId], [listingTitle], [investmentScore] ile VIP kullanıcılara bildirim dokümanı ekler.
  /// VIP: customers koleksiyonunda is_vip_investor=true ve investment_alert_enabled=true olanların assignedAgentId (veya ilgili user id) listesi kullanılır.
  Future<void> notifyVipInvestors({
    required String listingId,
    required String listingTitle,
    double? investmentScore,
    String? regionName,
  }) async {
    await FirestoreService.ensureInitialized();
    final firestore = FirebaseFirestore.instance;

    final vipSnapshot = await firestore
        .collection(AppConstants.colCustomers)
        .where('is_vip_investor', isEqualTo: true)
        .where('investment_alert_enabled', isEqualTo: true)
        .limit(50)
        .get();

    final userIds = <String>{};
    for (final doc in vipSnapshot.docs) {
      final data = doc.data();
      final advisorId = data['assignedAgentId'] as String? ?? data['assigned_agent_id'] as String?;
      if (advisorId != null && advisorId.isNotEmpty) {
        userIds.add(advisorId);
      }
    }

    final col = firestore.collection(AppConstants.colNotifications);
    final body = 'Yüksek getiri potansiyelli ilan: $listingTitle'
        '${regionName != null ? ' • $regionName' : ''}'
        '${investmentScore != null ? ' • Skor: ${(investmentScore * 100).toInt()}%' : ''}';

    for (final userId in userIds) {
      try {
        await col.add({
          'userId': userId,
          'type': 'investment_radar',
          'title': 'Yatırım Radarı',
          'body': body,
          'data': {
            'listingId': listingId,
            'listingTitle': listingTitle,
            'investmentScore': investmentScore,
            'regionName': regionName,
          },
          'read': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      } catch (_) {
        // Bir kullanıcıya yazılamazsa diğerlerine devam et (self-healing).
      }
    }
  }
}
