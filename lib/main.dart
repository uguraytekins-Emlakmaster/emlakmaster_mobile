import 'dart:async';

import 'package:emlakmaster_mobile/core/l10n/app_localizations.dart';
import 'package:emlakmaster_mobile/core/logging/app_logger.dart';
import 'package:emlakmaster_mobile/core/providers/settings_provider.dart';
import 'package:emlakmaster_mobile/core/router/app_router.dart';
import 'package:emlakmaster_mobile/core/services/app_lifecycle_power_service.dart';
import 'package:emlakmaster_mobile/core/services/firestore_service.dart';
import 'package:emlakmaster_mobile/core/services/push_notification_service.dart';
import 'package:emlakmaster_mobile/core/services/settings_service.dart';
import 'package:emlakmaster_mobile/core/services/onboarding_store.dart';
import 'package:emlakmaster_mobile/core/cache/app_cache_service.dart';
import 'package:emlakmaster_mobile/core/services/sync_manager.dart';
import 'package:emlakmaster_mobile/core/theme/app_theme.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/core/widgets/command_palette.dart';
import 'package:emlakmaster_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:emlakmaster_mobile/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart' show debugPrint, kDebugMode, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> main() async {
  // ensureInitialized ve runApp aynı zone'da olmalı (zone mismatch hatası önlemi)
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    try {
      // Tek noktadan Firebase init; bir plugin önce init etmişse duplicate-app yakala, devam et.
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }
    } on FirebaseException catch (e) {
      if (e.code == 'duplicate-app') {
        if (kDebugMode) debugPrint('Firebase: [DEFAULT] zaten mevcut, devam ediliyor.');
      } else {
        AppLogger.e('Firebase init error', e, e.stackTrace);
      }
    } catch (e, st) {
      AppLogger.e('Firebase init error', e, st);
    }
    try {
      await FirestoreService.ensureInitialized();
      if (!kIsWeb && Firebase.apps.isNotEmpty) {
        FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
      }
      await PushNotificationService.instance.initialize();
    } catch (e, st) {
      AppLogger.e('Firebase init error', e, st);
    }

    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      final isOverflow = details.toString().contains('overflowed');
      if (!isOverflow) {
        AppLogger.e('FlutterError', details.exception, details.stack);
        if (!kIsWeb && Firebase.apps.isNotEmpty) {
          try {
            FirebaseCrashlytics.instance.recordFlutterFatalError(details);
          } catch (_) {}
        }
      }
    };

    await _runApp();
  }, (Object error, StackTrace stack) {
    AppLogger.e('Zone error (async)', error, stack);
    if (!kIsWeb && Firebase.apps.isNotEmpty) {
      try {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      } catch (_) {}
    }
  });
}

Future<void> _runApp() async {

  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Material(
      color: DesignTokens.backgroundDark,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: DesignTokens.antiqueGold, size: 48),
              const SizedBox(height: 16),
              const Text(
                'Widget hatası',
                style: TextStyle(color: DesignTokens.textPrimaryDark, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(
                details.exceptionAsString(),
                textAlign: TextAlign.center,
                style: const TextStyle(color: DesignTokens.textSecondaryDark, fontSize: 12),
                maxLines: 5,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  };

  // Onboarding bayrağı router redirect'ten ÖNCE yüklensin; aksi halde completedSync=false sanılıp
  // her açılışta tanıtım ekranına düşülür.
  try {
    await OnboardingStore.instance.warmUp();
  } catch (e, st) {
    AppLogger.e('OnboardingStore warmUp error (pre-runApp)', e, st);
  }

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
    AppLifecyclePowerService.instance.ensureObserved();
    WidgetsBinding.instance.addPostFrameCallback((_) => _runDeferredInit());
  }

  @override
  void dispose() {
    AppLifecyclePowerService.instance.removeObserved();
    super.dispose();
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
    // Batarya tasarrufu tercihini yükle (animasyonlar buna göre kısılır)
    try {
      AppLifecyclePowerService.powerSaverEnabled =
          await SettingsService.instance.getPowerSaverEnabled();
    } catch (_) {}
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
    final locale = ref.watch(localeProvider).valueOrNull ?? const Locale('tr');
    return ColoredBox(
      color: DesignTokens.backgroundDark,
      child: MaterialApp.router(
      title: 'EmlakMaster',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        AppLocalizationsDelegate(),
      ],
      routerConfig: router,
      builder: (context, child) {
          // Router henüz sayfa vermeden veya tema geç uygulanınca beyaz ekran olmasın.
          final isRtl = locale.languageCode == 'ar';
          final content = child != null && isRtl
              ? Directionality(textDirection: TextDirection.rtl, child: child)
              : child;
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
                  const ColoredBox(color: DesignTokens.backgroundDark),
                  if (content != null)
                    content
                  else
                    const Center(
                      child: SizedBox(
                        width: 32,
                        height: 32,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: DesignTokens.antiqueGold,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _OpenCommandPaletteIntent extends Intent {
  const _OpenCommandPaletteIntent();
}
