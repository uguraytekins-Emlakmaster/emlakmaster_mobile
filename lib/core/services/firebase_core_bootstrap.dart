import 'dart:async';

import 'package:emlakmaster_mobile/core/logging/app_logger.dart';
import 'package:emlakmaster_mobile/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart'
    show debugPrint, kDebugMode, kIsWeb, defaultTargetPlatform, TargetPlatform;

/// Firebase Core — tek giriş noktası. Auth/Firestore çağrıları önce [ensureReady] bekler.
class FirebaseCoreBootstrap {
  FirebaseCoreBootstrap._();

  static final FirebaseCoreBootstrap instance = FirebaseCoreBootstrap._();

  Future<void>? _ongoing;

  /// [main] — UI'yi bloklamadan arka planda başlat.
  void scheduleBackgroundInit() {
    unawaited(
      ensureReady().catchError((Object e, StackTrace st) {
        AppLogger.e('Firebase init (background)', e, st);
      }),
    );
  }

  /// Auth ve Firestore öncesi: hazır olana kadar bekler (paylaşılan future).
  Future<void> ensureReady({
    Duration timeout = const Duration(seconds: 20),
  }) async {
    if (Firebase.apps.isNotEmpty) return;

    try {
      _ongoing ??= _initialize();
      await _ongoing!.timeout(
        timeout,
        onTimeout: () => throw FirebaseException(
          plugin: 'firebase_core',
          code: 'timeout',
          message:
              'Bağlantı hazırlanırken zaman aşımı oluştu. Ağınızı kontrol edip tekrar deneyin.',
        ),
      );
    } catch (e, st) {
      _ongoing = null;
      if (Firebase.apps.isEmpty) {
        AppLogger.e('FirebaseCoreBootstrap.ensureReady', e, st);
      }
      rethrow;
    }

    if (Firebase.apps.isEmpty) {
      throw FirebaseException(
        plugin: 'firebase_core',
        code: 'no-app',
        message:
            'Firebase başlatılamadı. Uygulamayı kapatıp açın veya ağ bağlantınızı kontrol edin.',
      );
    }
  }

  Future<void> _initialize() async {
    if (Firebase.apps.isNotEmpty) return;

    final isAppleNative = !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.iOS ||
            defaultTargetPlatform == TargetPlatform.macOS);

    if (isAppleNative) {
      try {
        await _initializeWithRetry(() => Firebase.initializeApp());
      } catch (e, st) {
        AppLogger.e('Firebase init error (plist first)', e, st);
      }

      if (Firebase.apps.isEmpty) {
        try {
          await _initializeWithRetry(
            () => Firebase.initializeApp(
              options: DefaultFirebaseOptions.currentPlatform,
            ),
          );
        } on FirebaseException catch (e) {
          if (e.code == 'duplicate-app') {
            if (kDebugMode) {
              debugPrint('Firebase: [DEFAULT] zaten mevcut, devam ediliyor.');
            }
          } else {
            AppLogger.e(
              'Firebase init error (options after plist)',
              e,
              e.stackTrace,
            );
            rethrow;
          }
        }
      }
    } else {
      try {
        await _initializeWithRetry(
          () => Firebase.initializeApp(
            options: DefaultFirebaseOptions.currentPlatform,
          ),
        );
      } on FirebaseException catch (e) {
        if (e.code == 'duplicate-app') {
          if (kDebugMode) {
            debugPrint('Firebase: [DEFAULT] zaten mevcut, devam ediliyor.');
          }
        } else {
          AppLogger.e('Firebase init error (options)', e, e.stackTrace);
          rethrow;
        }
      }

      if (Firebase.apps.isEmpty) {
        try {
          await _initializeWithRetry(() => Firebase.initializeApp());
        } catch (e, st) {
          AppLogger.e('Firebase init error (default fallback)', e, st);
        }
      }
    }
  }

  Future<void> _initializeWithRetry(
    Future<FirebaseApp> Function() initCall,
  ) async {
    const maxAttempts = 5;
    for (var i = 0; i < maxAttempts; i++) {
      try {
        await initCall();
        return;
      } on FirebaseException catch (e) {
        final isDuplicate = e.code == 'duplicate-app';
        final isNotInitialized = e.code == 'not-initialized';
        if (isDuplicate) return;
        if (!isNotInitialized || i == maxAttempts - 1) rethrow;
        await Future<void>.delayed(Duration(milliseconds: 100 * (i + 1)));
      }
    }
  }
}
