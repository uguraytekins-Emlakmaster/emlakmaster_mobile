import 'dart:async';
import 'dart:ui' show PlatformDispatcher;

import 'package:emlakmaster_mobile/core/config/dev_mode_config.dart';
import 'package:emlakmaster_mobile/core/debug/debug_riverpod_observer.dart';
import 'package:emlakmaster_mobile/core/widgets/dev_mode_badge.dart';
import 'package:emlakmaster_mobile/core/deep_linking/region_deep_link_bootstrap.dart';
import 'package:emlakmaster_mobile/core/l10n/app_localizations.dart';
import 'package:emlakmaster_mobile/core/logging/app_logger.dart';
import 'package:emlakmaster_mobile/core/providers/settings_provider.dart';
import 'package:emlakmaster_mobile/core/router/app_router.dart';
import 'package:emlakmaster_mobile/core/services/app_lifecycle_power_service.dart';
import 'package:emlakmaster_mobile/core/services/firebase_functions_bootstrap.dart';
import 'package:emlakmaster_mobile/core/services/firestore_service.dart';
import 'package:emlakmaster_mobile/core/services/push_notification_service.dart';
import 'package:emlakmaster_mobile/core/services/settings_service.dart';
import 'package:emlakmaster_mobile/core/services/onboarding_store.dart';
import 'package:emlakmaster_mobile/core/cache/app_cache_service.dart';
import 'package:emlakmaster_mobile/core/services/call_record_sync_orchestrator.dart';
import 'package:emlakmaster_mobile/core/services/sync_manager.dart';
import 'package:emlakmaster_mobile/core/widgets/connectivity_banner.dart';
import 'package:emlakmaster_mobile/core/branding/brand_emblem.dart';
import 'package:emlakmaster_mobile/core/theme/app_theme.dart';
import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/widgets/command_palette.dart';
import 'package:emlakmaster_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:emlakmaster_mobile/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart'
    show debugPrint, kDebugMode, kIsWeb, kReleaseMode, defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> main() async {
  // ensureInitialized ve runApp aynı zone'da olmalı (zone mismatch hatası önlemi)
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    // Flutter dışı async hatalar (native plugin vb.) — zone ile yakalanmayabilir.
    PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
      AppLogger.e('PlatformDispatcher.onError', error, stack);
      if (!kIsWeb && Firebase.apps.isNotEmpty) {
        try {
          FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
        } catch (_) {}
      }
      return true;
    };

    try {
      // Ağ/Firebase takılırsa sonsuz beyaz LaunchScreen olmasın — süre sonunda runApp yine çalışır.
      await () async {
      // Tek noktadan Firebase init:
      // 1) önce generated options ile init etmeyi dene
      // 2) olmazsa (özellikle iOS native init/response sorunu) plist fallback dene.
      if (Firebase.apps.isEmpty) {
        // iOS'ta önce plist/default config ile dene (options decode tarafı kırılgan olabiliyor).
        final isAppleNative = !kIsWeb &&
            (defaultTargetPlatform == TargetPlatform.iOS ||
                defaultTargetPlatform == TargetPlatform.macOS);

        if (isAppleNative) {
          try {
            await _initializeFirebaseWithRetry(() => Firebase.initializeApp());
          } catch (e, st) {
            AppLogger.e('Firebase init error (plist first)', e, st);
          }

          // Hala yoksa options ile dene.
          if (Firebase.apps.isEmpty) {
            try {
              await _initializeFirebaseWithRetry(
                () => Firebase.initializeApp(
                  options: DefaultFirebaseOptions.currentPlatform,
                ),
              );
            } on FirebaseException catch (e) {
              if (e.code == 'duplicate-app') {
                if (kDebugMode) {
                  debugPrint(
                    'Firebase: [DEFAULT] zaten mevcut, devam ediliyor.',
                  );
                }
              } else {
                AppLogger.e('Firebase init error (options after plist)', e, e.stackTrace);
              }
            } catch (e, st) {
              AppLogger.e('Firebase init error (options after plist)', e, st);
            }
          }
        } else {
          // Diğer platformlarda önce options ile dene, olmazsa default init'e düş.
          try {
            await _initializeFirebaseWithRetry(
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
            }
          } catch (e, st) {
            AppLogger.e('Firebase init error (options)', e, st);
          }

          if (Firebase.apps.isEmpty) {
            try {
              await _initializeFirebaseWithRetry(() => Firebase.initializeApp());
            } catch (e, st) {
              AppLogger.e('Firebase init error (default fallback)', e, st);
            }
          }
        }
      }
      }().timeout(
        const Duration(seconds: 24),
        onTimeout: () {
          if (kDebugMode) {
            debugPrint(
              'Firebase: başlatma 24s içinde tamamlanmadı; uygulama yine de açılacak.',
            );
          }
        },
      );
    } catch (e, st) {
      AppLogger.e('Firebase init error', e, st);
    }
    try {
      await FirestoreService.ensureInitialized();
      configureFirebaseFunctionsForDebug();
      if (!kIsWeb && Firebase.apps.isNotEmpty) {
        FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
        await PushNotificationService.instance.initialize();
      }
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

Future<void> _initializeFirebaseWithRetry(
  Future<FirebaseApp> Function() initCall,
) async {
  const int maxAttempts = 8;
  for (int i = 0; i < maxAttempts; i++) {
    try {
      await initCall();
      return;
    } on FirebaseException catch (e) {
      final isDuplicate = e.code == 'duplicate-app';
      final isNotInitialized = e.code == 'not-initialized';
      if (isDuplicate) return;
      if (!isNotInitialized || i == maxAttempts - 1) rethrow;
      await Future<void>.delayed(Duration(milliseconds: 180 * (i + 1)));
    }
  }
}

Future<void> _runApp() async {

  ErrorWidget.builder = (FlutterErrorDetails details) {
    final ext = AppThemeExtension.dark();
    return Material(
      color: ext.background,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, color: ext.accent, size: 48),
              const SizedBox(height: 16),
              Text(
                'Widget hatası',
                style: TextStyle(color: ext.textPrimary, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(
                details.exceptionAsString(),
                textAlign: TextAlign.center,
                style: TextStyle(color: ext.textSecondary, fontSize: 12),
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
      observers: kDebugMode ? [DebugRiverpodObserver()] : null,
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
    unawaited(RegionDeepLinkBootstrap.attach(ref));
  }

  @override
  void dispose() {
    unawaited(RegionDeepLinkBootstrap.dispose());
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
    try {
      CallRecordSyncOrchestrator.instance.start();
    } catch (e, st) {
      AppLogger.e('CallRecordSyncOrchestrator start error', e, st);
    }
    try {
      PaintingBinding.instance.imageCache.maximumSize = 200;
      PaintingBinding.instance.imageCache.maximumSizeBytes = 150 * 1024 * 1024;
    } catch (e, st) {
      AppLogger.e('ImageCache tuning', e, st);
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
      try {
        final uid = next.valueOrNull?.uid;
        if (uid != null && uid.isNotEmpty) {
          Future<void>.microtask(() => RegionDeepLinkBootstrap.consumePendingAfterAuth(ref));
        }
        if (uid == null || uid.isEmpty) return;
        if (Firebase.apps.isEmpty) return;
        PushNotificationService.instance
            .requestPermissionIfEnabled()
            .then((_) => PushNotificationService.instance.refreshTokenAndSaveToFirestore(uid))
            .catchError((Object e, StackTrace st) {
          AppLogger.e('Push init after auth', e, st);
        });
      } catch (e, st) {
        AppLogger.e('currentUserProvider listener', e, st);
      }
    });
    final router = ref.watch(AppRouter.goRouterProvider);
    final locale = ref.watch(localeProvider).valueOrNull ?? const Locale('tr');
    return MaterialApp.router(
      title: 'Rainbow CRM',
      debugShowCheckedModeBanner: false,
      // Light theme disabled until a proper shared color system exists; force dark only.
      theme: AppTheme.dark(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.dark,
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
        final ext = AppThemeExtension.of(context);
        final scheme = Theme.of(context).colorScheme;
        final isRtl = locale.languageCode == 'ar';
        final content = child != null && isRtl
            ? Directionality(textDirection: TextDirection.rtl, child: child)
            : child;

        final shell = Shortcuts(
          shortcuts: const <ShortcutActivator, Intent>{
            SingleActivator(LogicalKeyboardKey.keyK, meta: true):
                _OpenCommandPaletteIntent(),
          },
          child: Actions(
            actions: <Type, Action<Intent>>{
              _OpenCommandPaletteIntent: CallbackAction<_OpenCommandPaletteIntent>(
                onInvoke: (_) {
                  // Builder [context] is above [Navigator]; modal APIs need a context
                  // whose ancestors include the root [Overlay] (navigator subtree).
                  final navCtx = router.routerDelegate.navigatorKey.currentContext;
                  if (navCtx != null) {
                    CommandPalette.show(navCtx);
                  }
                  return null;
                },
              ),
            },
            child: Stack(
              fit: StackFit.expand,
              children: [
                ColoredBox(color: ext.background),
                if (content != null)
                  content
                else
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const BrandEmblem(
                          variant: BrandEmblemVariant.full,
                          size: 120,
                        ),
                        const SizedBox(height: 28),
                        SizedBox(
                          width: 32,
                          height: 32,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: scheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                const Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: ConnectivityBanner(),
                ),
                if (!kReleaseMode && isDevMode) const DevModeBadge(),
              ],
            ),
          ),
        );

        // [child] = router/Navigator subtree (içinde [Overlay]). Bu builder içindeki
        // [Stack] kardeşleri (ör. [DevModeBadge]) Navigator dışında kalır; [Tooltip]
        // veya kök [Overlay] ekleme — "No Overlay widget found" / RawTooltip kırılır.
        return shell;
      },
    );
  }
}

class _OpenCommandPaletteIntent extends Intent {
  const _OpenCommandPaletteIntent();
}
