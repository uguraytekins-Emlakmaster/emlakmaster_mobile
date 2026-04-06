import 'dart:convert';

import 'package:emlakmaster_mobile/core/constants/app_constants.dart';
import 'package:emlakmaster_mobile/features/calls/data/post_call_capture_draft.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Kullanıcı başına tek bekleyen hızlı kayıt taslağı (offline güvenli).
class PostCallCaptureStore {
  PostCallCaptureStore._();

  static String _keyForUser(String userId) =>
      '${AppConstants.keyPostCallCaptureDraftV1}_$userId';

  static Future<PostCallCaptureDraft?> load(String userId) async {
    if (userId.isEmpty) return null;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyForUser(userId));
    return PostCallCaptureDraft.tryFromJson(raw);
  }

  static Future<void> save(String userId, PostCallCaptureDraft draft) async {
    if (userId.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _keyForUser(userId),
      jsonEncode(draft.toJson()),
    );
  }

  static Future<void> clear(String userId) async {
    if (userId.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyForUser(userId));
  }
}
