import 'package:emlakmaster_mobile/core/constants/app_constants.dart';
import 'package:emlakmaster_mobile/features/calls/data/pending_handoff_outbound_item.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Çevrimdışı minimum handoff kayıtları — tekrar çevrimiçi olunca sessiz senkron.
class PendingHandoffOutboundQueue {
  PendingHandoffOutboundQueue._();

  static String _keyForUser(String userId) =>
      '${AppConstants.keyPendingHandoffOutboundQueueV1}_$userId';

  static Future<List<PendingHandoffOutboundItem>> load(String userId) async {
    if (userId.isEmpty) return [];
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyForUser(userId));
    return PendingHandoffOutboundItem.listFromJsonString(raw);
  }

  static Future<void> _save(
    String userId,
    List<PendingHandoffOutboundItem> items,
  ) async {
    if (userId.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    if (items.isEmpty) {
      await prefs.remove(_keyForUser(userId));
    } else {
      await prefs.setString(
        _keyForUser(userId),
        PendingHandoffOutboundItem.encodeList(items),
      );
    }
  }

  /// Aynı [localDraftId] varsa üzerine yazar (çift kayıt yok).
  static Future<void> upsert(PendingHandoffOutboundItem item) async {
    if (item.advisorId.isEmpty) return;
    final list = await load(item.advisorId);
    final next = <PendingHandoffOutboundItem>[
      ...list.where((e) => e.localDraftId != item.localDraftId),
      item,
    ];
    await _save(item.advisorId, next);
  }

  static Future<void> removeByLocalDraftId(
    String userId,
    String localDraftId,
  ) async {
    if (userId.isEmpty || localDraftId.isEmpty) return;
    final list = await load(userId);
    final next = list.where((e) => e.localDraftId != localDraftId).toList();
    await _save(userId, next);
  }

  /// Upsert öncesi tekrar okuma — hızlı kayıt kuyruğu temizlediyse false.
  static Future<bool> containsLocalDraftId(
    String userId,
    String localDraftId,
  ) async {
    if (userId.isEmpty || localDraftId.isEmpty) return false;
    final list = await load(userId);
    return list.any((e) => e.localDraftId == localDraftId);
  }
}
