import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emlakmaster_mobile/core/logging/app_logger.dart';
import 'package:emlakmaster_mobile/core/services/firestore_service.dart';
import 'package:emlakmaster_mobile/core/services/settings_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

/// FCM push bildirimleri: izin, token, arka plan işleyici, token'ı Firestore'a yazma.
/// Ayarlarda bildirimler kapalıysa izin istenmez ve token güncellenmez.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  AppLogger.i('FCM background', 'message: ${message.messageId}');
}

class PushNotificationService {
  PushNotificationService._();
  static final PushNotificationService instance = PushNotificationService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  bool _initialized = false;

  bool get isInitialized => _initialized;

  /// Uygulama başlarken bir kez çağrılır. Arka plan handler'ı kaydeder.
  Future<void> initialize() async {
    if (_initialized) return;
    try {
      await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
      _initialized = true;
    } catch (e, st) {
      AppLogger.e('FCM init', e, st);
    }
  }

  /// Bildirim izni iste (iOS/Android). Ayarlarda kapalıysa false döner.
  Future<bool> requestPermissionIfEnabled() async {
    final enabled = await SettingsService.instance.getNotificationsEnabled();
    if (!enabled) return false;
    try {
      final settings = await _messaging.requestPermission(
        
      );
      return settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
    } catch (e, st) {
      AppLogger.e('FCM permission', e, st);
      return false;
    }
  }

  /// FCM token al ve [userId] varsa Firestore'da users/{userId}/fcmToken güncelle.
  Future<void> refreshTokenAndSaveToFirestore(String? userId) async {
    if (userId == null || userId.isEmpty) return;
    final enabled = await SettingsService.instance.getNotificationsEnabled();
    if (!enabled) return;
    try {
      final token = await _messaging.getToken();
      if (token == null) return;
      await FirestoreService.ensureInitialized();
      await FirebaseFirestore.instance.collection('users').doc(userId).set({
        'fcmToken': token,
        'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e, st) {
      AppLogger.e('FCM token save', e, st);
    }
  }

  /// Foreground mesaj dinleyicisi kur (opsiyonel: in-app bildirim göstermek için).
  void setForegroundMessageHandler(void Function(RemoteMessage message) handler) {
    FirebaseMessaging.onMessage.listen(handler);
  }

  /// Bildirime tıklanınca açılacak sayfayı yönetmek için (router ile kullanılabilir).
  void setMessageOpenedHandler(void Function(RemoteMessage message) handler) {
    FirebaseMessaging.onMessageOpenedApp.listen(handler);
  }

  /// Token yenilendiğinde Firestore'u güncellemek için dinleyici.
  void onTokenRefresh(void Function(String token) onToken) {
    _messaging.onTokenRefresh.listen(onToken);
  }
}
