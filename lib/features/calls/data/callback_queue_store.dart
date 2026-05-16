import 'package:emlakmaster_mobile/core/constants/app_constants.dart';
import 'package:emlakmaster_mobile/features/calls/domain/callback_queue_item.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Kullanıcı başına hafif geri arama kuyruğu (en fazla [maxItems]).
class CallbackQueueStore {
  CallbackQueueStore._();

  static const int maxItems = 40;

  static String _key(String userId) =>
      '${AppConstants.keyPostCallCaptureDraftV1}_callback_queue_$userId';

  static Future<List<CallbackQueueItem>> load(String userId) async {
    if (userId.isEmpty) return const [];
    final prefs = await SharedPreferences.getInstance();
    return CallbackQueueItem.listFromJsonString(prefs.getString(_key(userId)));
  }

  static Future<void> save(String userId, List<CallbackQueueItem> items) async {
    if (userId.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final trimmed = items.where((e) => !e.completed).take(maxItems).toList()
      ..sort((a, b) => a.dueAtMs.compareTo(b.dueAtMs));
    await prefs.setString(
      _key(userId),
      CallbackQueueItem.listToJsonString(trimmed),
    );
  }
}
