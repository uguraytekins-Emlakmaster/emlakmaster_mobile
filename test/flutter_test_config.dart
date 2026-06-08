import 'dart:async';

import 'package:firebase_core_platform_interface/firebase_core_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

/// Global test bootstrap — `flutter test` her test dosyasından önce çalıştırır.
///
/// Amaç: Firebase'i platform-interface seviyesinde mock'lamak. Böylece
/// [FirebaseCoreBootstrap.ensureReady] `Firebase.apps.isNotEmpty` kontrolünde
/// anında döner; production'daki 20 sn `timeout` Timer'ı testlerde hiç
/// oluşmaz ("A Timer is still pending..." hataları biter) ve pigeon kanal
/// (`channel-error`) gürültüsü test loglarını kirletmez.
///
/// Not: Yalnızca firebase_core mock'lanır; auth/firestore mock'lanmaz —
/// bu, başlatma yarışını çözer ama gerçek backend davranışını taklit etmez.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  FirebasePlatform.instance = _MockFirebaseCorePlatform();
  await testMain();
}

const FirebaseOptions _kTestOptions = FirebaseOptions(
  apiKey: 'test-api-key',
  appId: '1:1234567890:test:abcdef123456',
  messagingSenderId: '1234567890',
  projectId: 'axion-crm-test',
  storageBucket: 'axion-crm-test.appspot.com',
);

class _MockFirebaseApp extends FirebaseAppPlatform with MockPlatformInterfaceMixin {
  _MockFirebaseApp([
    String name = defaultFirebaseAppName,
    FirebaseOptions options = _kTestOptions,
  ]) : super(name, options);
}

class _MockFirebaseCorePlatform extends FirebasePlatform
    with MockPlatformInterfaceMixin {
  final List<FirebaseAppPlatform> _apps = <FirebaseAppPlatform>[
    _MockFirebaseApp(),
  ];

  @override
  List<FirebaseAppPlatform> get apps => List.unmodifiable(_apps);

  @override
  FirebaseAppPlatform app([String name = defaultFirebaseAppName]) {
    return _apps.firstWhere(
      (a) => a.name == name,
      orElse: () => _MockFirebaseApp(name),
    );
  }

  @override
  Future<FirebaseAppPlatform> initializeApp({
    String? name,
    FirebaseOptions? options,
  }) async {
    final appName = name ?? defaultFirebaseAppName;
    final existing = _apps.where((a) => a.name == appName);
    if (existing.isNotEmpty) return existing.first;
    final app = _MockFirebaseApp(appName, options ?? _kTestOptions);
    _apps.add(app);
    return app;
  }
}
