import 'dart:async';

import 'package:emlakmaster_mobile/core/logging/app_logger.dart';
import 'package:emlakmaster_mobile/core/providers/settings_provider.dart';
import 'package:emlakmaster_mobile/core/router/app_router.dart';
import 'package:emlakmaster_mobile/core/services/firestore_service.dart';
import 'package:emlakmaster_mobile/core/services/push_notification_service.dart';
import 'package:emlakmaster_mobile/core/services/settings_service.dart';
import 'package:emlakmaster_mobile/core/services/onboarding_store.dart';
import 'package:emlakmaster_mobile/core/cache/app_cache_service.dart';
import 'package:emlakmaster_mobile/core/services/sync_manager.dart';
import 'package:emlakmaster_mobile/core/theme/app_theme.dart';
import 'package:emlakmaster_mobile/core/widgets/command_palette.dart';
import 'package:emlakmaster_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> main() async {
  // ensureInitialized ve runApp aynı zone'da olmalı (zone mismatch hatası önlemi)
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    try {
      await FirestoreService.ensureInitialized();
      FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
      await PushNotificationService.instance.initialize();
    } catch (e, st) {
      AppLogger.e('Firebase init error', e, st);
    }

    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      final isOverflow = details.toString().contains('overflowed');
      if (!isOverflow) {
        AppLogger.e('FlutterError', details.exception, details.stack);
        FirebaseCrashlytics.instance.recordFlutterFatalError(details);
      }
    };

    await _runApp();
  }, (Object error, StackTrace stack) {
    AppLogger.e('Zone error (async)', error, stack);
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
  });
}

Future<void> _runApp() async {

  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Material(
      color: const Color(0xFF0D1117),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Color(0xFF00FF41), size: 48),
              const SizedBox(height: 16),
              const Text(
                'Widget hatası',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(
                details.exceptionAsString(),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
                maxLines: 5,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  };

  // Ağır init'leri ilk frame sonrasına ertele — uygulama anında açılsın (No-Lag Rule).
  final themeIndex = await SettingsService.instance.getThemeModeIndex();
  runApp(
    ProviderScope(
      overrides: [
        initialThemeModeIndexProvider.overrideWithValue(themeIndex),
      ],
      child: const EmlakMasterApp(),
    ),
  );
}

class EmlakMasterApp extends ConsumerStatefulWidget {
  const EmlakMasterApp({super.key});

  @override
  ConsumerState<EmlakMasterApp> createState() => _EmlakMasterAppState();
}

class _EmlakMasterAppState extends ConsumerState<EmlakMasterApp> {
  static bool _deferredInitDone = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _runDeferredInit());
  }

  static Future<void> _runDeferredInit() async {
    if (_deferredInitDone) return;
    _deferredInitDone = true;
    try {
      SyncManager.init();
    } catch (e, st) {
      AppLogger.e('SyncManager init error', e, st);
    }
    try {
      await OnboardingStore.instance.warmUp();
    } catch (e, st) {
      AppLogger.e('OnboardingStore warmUp error', e, st);
    }
    // Hive cache: ağır işlem ilk frame sonrası
    try {
      await AppCacheService.instance.ensureInit();
    } catch (e, st) {
      AppLogger.e('AppCacheService init error', e, st);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(currentUserProvider, (_, next) {
      final uid = next.valueOrNull?.uid;
      if (uid != null && uid.isNotEmpty) {
        PushNotificationService.instance.requestPermissionIfEnabled().then((_) {
          PushNotificationService.instance.refreshTokenAndSaveToFirestore(uid);
        });
      }
    });
    final router = ref.watch(AppRouter.goRouterProvider);
    final themeMode = ref.watch(themeModeProvider);
    return MaterialApp.router(
      title: 'EmlakMaster',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      routerConfig: router,
      builder: (context, child) {
          // Arka plan her zaman tam ekran koyu; child null olsa bile beyaz görünmez.
          return Shortcuts(
            shortcuts: const <ShortcutActivator, Intent>{
              SingleActivator(LogicalKeyboardKey.keyK, meta: true):
                  _OpenCommandPaletteIntent(),
            },
            child: Actions(
              actions: <Type, Action<Intent>>{
                _OpenCommandPaletteIntent: CallbackAction<_OpenCommandPaletteIntent>(
                  onInvoke: (_) {
                    CommandPalette.show(context);
                    return null;
                  },
                ),
              },
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ColoredBox(
                    color: Theme.of(context).scaffoldBackgroundColor,
                  ),
                  if (child != null) child,
                ],
              ),
            ),
          );
        },
    );
  }
}

class _OpenCommandPaletteIntent extends Intent {
  const _OpenCommandPaletteIntent();
}
