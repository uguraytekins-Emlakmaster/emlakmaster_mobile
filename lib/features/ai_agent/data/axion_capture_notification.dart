import 'dart:convert';
import 'dart:ui' show DartPluginRegistrant;

import 'package:emlakmaster_mobile/core/logging/app_logger.dart';
import 'package:emlakmaster_mobile/core/services/firestore_service.dart';
import 'package:emlakmaster_mobile/features/dashboard/data/execution_reminder_local_notifications.dart';
import 'package:emlakmaster_mobile/features/tasks/data/task_due_local_notifications.dart';
import 'package:emlakmaster_mobile/firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter/widgets.dart' show WidgetsFlutterBinding;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../domain/axion_phone_matcher.dart';
import 'axion_capture_dismiss_store.dart';
import 'axion_pending_capture_store.dart';

/// Çağrı bitiminde kayıtsız numara için sistem bildirimi (Android).
///
/// "Uygulamaya girmeden kaydet" akışı:
/// - Rehberde isim varsa: tek dokunuş "X olarak kaydet" aksiyonu.
/// - Her durumda: bildirim içine isim yazıp "Kaydet" (RemoteInput) —
///   uygulama hiç açılmadan müşteri CRM'e yazılır.
/// - Bildirime dokunmak uygulamayı açar ve kayıt pop-up'ını gösterir.
///
/// Arka plan kaydı başarısız olursa veri kaybolmaz: bekleyen kuyruğa
/// yazılır, uygulama bir sonraki açılışta sessizce tamamlar.
class AxionCaptureNotification {
  AxionCaptureNotification._();
  static final AxionCaptureNotification instance = AxionCaptureNotification._();

  // v2: özel Axion zil sesi (kanal sesi yalnızca oluşturulurken atanabilir).
  static const String channelId = 'axion_capture_v2';
  static const String statusChannelId = 'axion_capture_status';
  static const String _payloadType = 'axion_capture';
  static const String actionSaveNamed = 'axion_save_named';
  static const String actionSaveInput = 'axion_save_input';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  /// Bildirim gövdesine dokunulunca (uygulama açıldı) çağrılır.
  /// Host bunu kayıt pop-up'ını açmak için kullanır.
  void Function(String rawNumber, String? contactName)? onOpenCapture;

  bool get _supported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// DİKKAT: Bu initialize, plugin'in yanıt yönlendirmesini devralır.
  /// main.dart'ta görev/icra bildirim servislerinden SONRA çağrılır ve
  /// onların payload tiplerini kendi public callback'lerine iletir.
  Future<void> ensureInitialized() async {
    if (_initialized || !_supported) return;
    const initSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _plugin.initialize(
      const InitializationSettings(android: initSettings),
      onDidReceiveNotificationResponse: _onForegroundResponse,
      onDidReceiveBackgroundNotificationResponse:
          axionCaptureNotificationBackgroundHandler,
    );
    // Özel Axion imza sesi: yükselen iki cam nota (res/raw/axion_capture_chime).
    const channel = AndroidNotificationChannel(
      channelId,
      'Kayıtsız numara uyarıları',
      description: 'Çağrı sonrası hızlı müşteri kaydı önerileri',
      importance: Importance.high,
      sound: RawResourceAndroidNotificationSound('axion_capture_chime'),
    );
    // Onay/teslim bildirimleri için sessiz kanal (Android 8+ ses kanal
    // seviyesindedir; aynı kanalda playSound:false yok sayılır).
    const statusChannel = AndroidNotificationChannel(
      statusChannelId,
      'Kayıt durumu',
      description: 'Hızlı kayıt onay ve durum bildirimleri',
      importance: Importance.low,
      playSound: false,
      enableVibration: false,
    );
    // FCM push'ları için varsayılan kanal (AndroidManifest meta-data bu
    // kanalı işaret eder) — imza sesiyle.
    const pushChannel = AndroidNotificationChannel(
      'axion_push_v1',
      'Genel bildirimler',
      description: 'CRM güncellemeleri ve önemli uyarılar',
      importance: Importance.high,
      sound: RawResourceAndroidNotificationSound('axion_capture_chime'),
    );
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    // Eski (varsayılan sesli) kanal kalıntısını temizle.
    await android?.deleteNotificationChannel('axion_capture');
    await android?.createNotificationChannel(channel);
    await android?.createNotificationChannel(statusChannel);
    await android?.createNotificationChannel(pushChannel);
    _initialized = true;
  }

  /// Çağrı bitti, numara CRM'de yok → hızlı kaydet bildirimi.
  Future<void> showQuickSave({
    required String rawNumber,
    String? contactName,
  }) async {
    if (!_supported) return;
    await ensureInitialized();

    final name = (contactName ?? '').trim();
    final hasName = name.isNotEmpty;
    final payload = jsonEncode({
      'type': _payloadType,
      'number': rawNumber,
      if (hasName) 'name': name,
    });

    final actions = <AndroidNotificationAction>[
      if (hasName)
        AndroidNotificationAction(
          actionSaveNamed,
          '"$name" olarak kaydet',
        ),
      const AndroidNotificationAction(
        actionSaveInput,
        'İsim yaz & kaydet',
        inputs: [AndroidNotificationActionInput(label: 'Müşteri adı')],
      ),
    ];

    await _plugin.show(
      _notificationId(rawNumber),
      hasName ? name : rawNumber,
      hasName
          ? '$rawNumber · CRM\'de kayıtlı değil. Tek dokunuşla kaydedin.'
          : 'Bu numara CRM\'de kayıtlı değil. İsim yazıp hemen kaydedin.',
      NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          'Kayıtsız numara uyarıları',
          channelDescription: 'Çağrı sonrası hızlı müşteri kaydı önerileri',
          importance: Importance.high,
          priority: Priority.high,
          category: AndroidNotificationCategory.call,
          actions: actions,
        ),
      ),
      payload: payload,
    );
  }

  /// Onay/teslim bildirimi (sessiz).
  Future<void> _showSilent(String title, String body) async {
    if (!_supported) return;
    await _plugin.show(
      DateTime.now().millisecondsSinceEpoch & 0x3FFFFFFF,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          statusChannelId,
          'Kayıt durumu',
          channelDescription: 'Hızlı kayıt onay ve durum bildirimleri',
          importance: Importance.low,
          priority: Priority.low,
          playSound: false,
          enableVibration: false,
        ),
      ),
    );
  }

  static int _notificationId(String rawNumber) =>
      0x0A700000 | (AxionPhoneMatcher.normalize(rawNumber).hashCode & 0xFFFFF);

  /// Ön plan yanıtları: kendi tipimizi işler, diğer servislerin payload
  /// tiplerini onların public callback'lerine iletir (initialize sırasında
  /// yanıt yönlendirmesi tek noktada toplandığı için).
  void _onForegroundResponse(NotificationResponse response) {
    final raw = response.payload;
    if (raw == null || raw.isEmpty) return;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      switch (map['type'] as String?) {
        case _payloadType:
          final number = map['number'] as String? ?? '';
          if (number.isEmpty) return;
          onOpenCapture?.call(number, map['name'] as String?);
        case 'task_due':
          TaskDueLocalNotifications.instance.onTap?.call(
            map['taskId'] as String? ?? '',
            map['customerId'] as String?,
          );
        case 'execution_reminder':
          final customerId = map['customerId'] as String? ?? '';
          if (customerId.isEmpty) return;
          ExecutionReminderLocalNotifications.instance.onTapCustomer
              ?.call(customerId);
      }
    } catch (e, st) {
      AppLogger.e('AxionCaptureNotification._onForegroundResponse', e, st);
    }
  }
}

/// Bildirim aksiyonu (Hızlı Kaydet) — ayrı arka plan isolate'inde çalışır.
///
/// Uygulama hiç açılmadan müşteri CRM'e yazılır. Başarısızlıkta kayıt
/// bekleyen kuyruğa düşer (veri kaybı imkânsız); uygulama açılınca tamamlanır.
@pragma('vm:entry-point')
Future<void> axionCaptureNotificationBackgroundHandler(
  NotificationResponse response,
) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();

  final raw = response.payload;
  if (raw == null || raw.isEmpty) return;

  String number = '';
  String name = '';
  try {
    final map = jsonDecode(raw) as Map<String, dynamic>;
    if (map['type'] != AxionCaptureNotification._payloadType) return;
    number = (map['number'] as String? ?? '').trim();
    if (number.isEmpty) return;

    final payloadName = (map['name'] as String? ?? '').trim();
    final typedName = (response.input ?? '').trim();
    // İsim önceliği: kullanıcının yazdığı > rehberdeki > numaranın kendisi
    // (uydurma isim asla üretilmez).
    name = typedName.isNotEmpty
        ? typedName
        : (payloadName.isNotEmpty ? payloadName : number);

    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ).catchError((Object e) {
      // duplicate-app: zaten başlatılmış — sorun değil.
      return Firebase.app();
    });

    // Oturum diskte kayıtlı; ilk emisyon null gelebilir — gerçek kullanıcıyı bekle.
    var user = FirebaseAuth.instance.currentUser;
    user ??= await FirebaseAuth.instance
        .authStateChanges()
        .firstWhere((u) => u != null)
        .timeout(const Duration(seconds: 8));
    final uid = user?.uid ?? '';
    if (uid.isEmpty) {
      throw StateError('Oturum geri yüklenemedi');
    }

    final customerId = await FirestoreService.createCustomer(
      assignedAgentId: uid,
      fullName: name,
      primaryPhone: number,
      source: 'axion_agent_bildirim',
    );

    final key = AxionPhoneMatcher.normalize(number);
    await AxionCaptureDismissStore.instance.clear(key);
    // Çağrı geçmişi bağlaması uygulama açılınca yapılır (stream verisi gerekir).
    await AxionPendingCaptureStore.instance.enqueueLink(
      normalizedKey: key,
      customerId: customerId,
    );
    await AxionCaptureNotification.instance
        ._showSilent('Müşteri kaydedildi', '$name · $number CRM\'e eklendi.');
  } catch (e, st) {
    AppLogger.e('axionCaptureNotificationBackgroundHandler', e, st);
    if (number.isNotEmpty) {
      // Veri kaybı yok: uygulama açılınca otomatik kaydedilecek.
      await AxionPendingCaptureStore.instance.enqueueSave(
        name: name.isNotEmpty ? name : number,
        phone: number,
      );
      await AxionCaptureNotification.instance._showSilent(
        'Kayıt bekliyor',
        '$number uygulama açılınca otomatik kaydedilecek.',
      );
    }
  }
}
