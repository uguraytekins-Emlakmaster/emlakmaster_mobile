import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:emlakmaster_mobile/core/logging/app_logger.dart';
import 'package:emlakmaster_mobile/core/services/firestore_service.dart';
import 'package:emlakmaster_mobile/core/services/settings_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart'
    show kDebugMode, kIsWeb, defaultTargetPlatform, TargetPlatform;

/// FCM push bildirimleri: izin, token, arka plan işleyici, token'ı Firestore'a yazma.
/// Ayarlarda bildirimler kapalıysa izin istenmez ve token güncellenmez.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  AppLogger.i('FCM background', 'message: ${message.messageId}');
}

class PushNotificationService {
  PushNotificationService._();
  static final PushNotificationService instance = PushNotificationService._();

  late final FirebaseMessaging _messaging;
  bool _initialized = false;

  bool get isInitialized => _initialized;

  /// Uygulama başlarken bir kez çağrılır. Arka plan handler'ı kaydeder.
  /// [setForegroundNotificationPresentationOptions] ağır olabildiği için ilk frame'den
  /// sonra tamamlanır — aksi halde iOS'ta uzun süre beyaz LaunchScreen kalır.
  Future<void> initialize() async {
    if (_initialized) return;
    try {
      if (Firebase.apps.isEmpty) return;
      _messaging = FirebaseMessaging.instance;
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
      _initialized = true;
      // İlk boyamayı bekletmemek için sunum seçeneklerini ertele.
      Future<void>.microtask(() async {
        try {
          await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
            alert: true,
            badge: true,
            sound: true,
          );
        } catch (e, st) {
          AppLogger.e('FCM foreground presentation options', e, st);
        }
      });
    } catch (e, st) {
      AppLogger.e('FCM init', e, st);
    }
  }

  /// Bildirim izni iste (iOS/Android). Ayarlarda kapalıysa false döner.
  Future<bool> requestPermissionIfEnabled() async {
    if (!_initialized || Firebase.apps.isEmpty) return false;
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

  /// iOS'ta APNs token FCM'den önce gelmeli; aksi halde getToken() Xcode'da
  /// "Declining request for FCM Token since no APNS Token specified" log üretir.
  Future<String?> _waitForApnsToken({int maxAttempts = 12, Duration step = const Duration(milliseconds: 200)}) async {
    for (var i = 0; i < maxAttempts; i++) {
      final t = await _messaging.getAPNSToken();
      if (t != null && t.isNotEmpty) return t;
      await Future<void>.delayed(step);
    }
    return null;
  }

  /// FCM token al ve [userId] varsa Firestore'da users/{userId}/fcmToken güncelle.
  /// macOS ve web'de APNS/registration yok; sessizce atlanır.
  Future<void> refreshTokenAndSaveToFirestore(String? userId) async {
    if (!_initialized || Firebase.apps.isEmpty) return;
    if (userId == null || userId.isEmpty) return;
    if (kIsWeb || defaultTargetPlatform == TargetPlatform.macOS) return;
    final enabled = await SettingsService.instance.getNotificationsEnabled();
    if (!enabled) return;
    try {
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        final apns = await _waitForApnsToken();
        if (apns == null) {
          if (kDebugMode) {
            AppLogger.i(
              'FCM: APNS token yok; getToken atlandı (Simülatör, izin kapalı veya '
              'Push Notification capability eksik olabilir — beklenen durum olabilir).',
            );
          }
          return;
        }
      }
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
    if (Firebase.apps.isEmpty) return;
    FirebaseMessaging.onMessage.listen(handler);
  }

  /// Bildirime tıklanınca açılacak sayfayı yönetmek için (router ile kullanılabilir).
  void setMessageOpenedHandler(void Function(RemoteMessage message) handler) {
    if (Firebase.apps.isEmpty) return;
    FirebaseMessaging.onMessageOpenedApp.listen(handler);
  }

  /// Token yenilendiğinde Firestore'u güncellemek için dinleyici.
  void onTokenRefresh(void Function(String token) onToken) {
    if (!_initialized || Firebase.apps.isEmpty) return;
    _messaging.onTokenRefresh.listen(onToken);
  }
}
