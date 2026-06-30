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
import 'package:emlakmaster_mobile/core/feedback/app_feedback.dart';
import 'package:emlakmaster_mobile/core/services/push_notification_service.dart';
import 'package:emlakmaster_mobile/core/services/settings_service.dart';
import 'package:emlakmaster_mobile/core/services/login_entry_store.dart';
import 'package:emlakmaster_mobile/core/services/onboarding_store.dart';
import 'package:emlakmaster_mobile/core/services/startup_role_cache.dart';
import 'package:emlakmaster_mobile/core/cache/app_cache_service.dart';
import 'package:emlakmaster_mobile/core/services/call_record_sync_orchestrator.dart';
import 'package:emlakmaster_mobile/core/services/sync_manager.dart';
import 'package:emlakmaster_mobile/core/widgets/connectivity_banner.dart';
import 'package:emlakmaster_mobile/core/branding/brand_emblem.dart';
import 'package:emlakmaster_mobile/core/performance/startup_perf_markers.dart';
import 'package:emlakmaster_mobile/core/theme/app_theme.dart';
import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/widgets/command_palette.dart';
import 'package:emlakmaster_mobile/core/widgets/startup_recovery_scaffold.dart';
import 'package:emlakmaster_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:emlakmaster_mobile/features/auth/data/user_repository.dart';
import 'package:emlakmaster_mobile/features/auth/domain/entities/app_role.dart';
import 'package:emlakmaster_mobile/features/ai_agent/data/axion_capture_notification.dart';
import 'package:emlakmaster_mobile/features/dashboard/data/execution_reminder_local_notifications.dart';
import 'package:emlakmaster_mobile/features/dashboard/data/execution_reminder_notification_bridge.dart';
import 'package:emlakmaster_mobile/features/tasks/data/task_due_local_notifications.dart';
import 'package:emlakmaster_mobile/features/tasks/data/task_due_notification_bridge.dart';
import 'package:emlakmaster_mobile/core/notifications/crm_push_navigation.dart';
import 'package:emlakmaster_mobile/features/office/domain/office_access_state.dart';
import 'package:emlakmaster_mobile/core/services/firebase_core_bootstrap.dart';
import 'package:emlakmaster_mobile/core/services/logout_flow_tracer.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart'
    show
        debugPrint,
        kDebugMode,
        kIsWeb,
        kReleaseMode;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

bool get _isFlutterTest {
  final bindingName = WidgetsBinding.instance.runtimeType.toString();
  return bindingName.contains('TestWidgetsFlutterBinding') ||
      bindingName.contains('AutomatedTestWidgetsFlutterBinding') ||
      bindingName.contains('LiveTestWidgetsFlutterBinding');
}

Future<void> main() async {
  // ensureInitialized ve runApp aynı zone'da olmalı (zone mismatch hatası önlemi)
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    AppLogger.state('[startup] main entered');
    StartupPerfMarkers.once('main_entered');

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
      // Oturum cache'i (StartupRoleCache) optimistik giriş kararının tek
      // dayanağı: önceki oturumu olan kullanıcıyı login formuna düşürmeden
      // doğrudan ana ekrana almak için kullanılır. Throttle'lı cihazlarda
      // SharedPreferences ilk diskten okuması 350ms'i rahatça aşabildiğinden,
      // bu okumayı ayrı ve daha cömert bir bütçeyle runApp ÖNCESİ bekliyoruz.
      // Aksi halde cache "boş" görünür ve dönen kullanıcıya tekrar giriş
      // ekranı açılır (yaşanan asıl sorun buydu).
      await StartupRoleCache.instance.warmUp().timeout(
        const Duration(seconds: 2),
        onTimeout: () {
          if (kDebugMode) {
            debugPrint(
              'StartupRoleCache warmUp: 2s zaman aşımı; cache hazır değil.',
            );
          }
        },
      );
      // Diğer yerel bayraklar UI'yi bloklamamalı; kısa bütçeyle arka planda.
      await Future.wait([
        OnboardingStore.instance.warmUp(),
        LoginEntryStore.instance.warmUp(),
      ]).timeout(
        const Duration(milliseconds: 350),
        onTimeout: () {
          if (kDebugMode) {
            debugPrint(
              'Startup prefs warmUp: 350ms zaman aşımı; varsayılanlar kullanılacak.',
            );
          }
          return <void>[];
        },
      );
      FirebaseCoreBootstrap.instance.scheduleBackgroundInit();
      AppLogger.state('[startup] bootstrap prefs done; firebase background');
      StartupPerfMarkers.once('bootstrap_parallel_done');
    } catch (e, st) {
      AppLogger.e('Bootstrap prefs init', e, st);
      FirebaseCoreBootstrap.instance.scheduleBackgroundInit();
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
                style: TextStyle(
                    color: ext.textPrimary, fontWeight: FontWeight.w600),
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

  AppLogger.state('[startup] runApp (fast path)');
  StartupPerfMarkers.once('run_app');
  runApp(
    ProviderScope(
      observers: kDebugMode ? [DebugRiverpodObserver()] : null,
      child: const AxionApp(),
    ),
  );
}

class AxionApp extends ConsumerStatefulWidget {
  const AxionApp({super.key});

  @override
  ConsumerState<AxionApp> createState() => _AxionAppState();
}

class _AxionAppState extends ConsumerState<AxionApp> {
  static bool _deferredInitDone = false;
  ProviderSubscription<AsyncValue<User?>>? _authUserSub;
  ProviderSubscription<AsyncValue<UserDoc?>>? _userDocSub;
  ProviderSubscription<AsyncValue<AppRole>>? _roleSub;
  ProviderSubscription<AsyncValue<OfficeAccessState>>? _officeAccessSub;
  ProviderSubscription<bool>? _needsRoleSub;
  ProviderSubscription<bool>? _needsOfficeSub;
  ProviderSubscription<bool>? _needsRecoverySub;
  bool? _lastRouterChildAvailable;

  @override
  void initState() {
    super.initState();
    AppLogger.state('[startup] AxionApp.initState');
    AppLifecyclePowerService.instance.ensureObserved();
    _bindStartupLogging();
    // Emniyet ağı: oturum cache'i runApp öncesi bütçeyi (2s) aşıp geç
    // tamamlanırsa, router ilk değerlendirmede cache'i "boş" görüp login
    // formunu açabilir. warmUp kesin tamamlanınca router'ı tazeleyerek
    // iyimser girişi (önceki oturum -> ana ekran) gecikmeli de olsa devreye
    // alıyoruz; böylece kullanıcı yanlışlıkla giriş ekranında kalmaz.
    StartupRoleCache.instance.warmUp().then((_) {
      if (!mounted) return;
      try {
        ref.read(AppRouter.goRouterProvider).refresh();
      } catch (_) {}
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      StartupPerfMarkers.once('first_frame');
      _runDeferredInit();
      unawaited(_restoreThemeFromDisk(ref));
    });
    if (!_isFlutterTest) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future<void>.delayed(
          const Duration(milliseconds: 450),
          () => RegionDeepLinkBootstrap.attach(ref),
        );
        Future<void>.delayed(
          const Duration(seconds: 2),
          () {
            if (!mounted) return;
            // Sıra ÖNEMLİ: plugin yanıt yönlendirmesini en son initialize
            // eden servis devralır. AxionCaptureNotification en sonda
            // başlatılır ve diğer payload tiplerini ilgili servislere iletir.
            unawaited(() async {
              await ExecutionReminderLocalNotifications.instance
                  .ensureInitialized();
              await TaskDueLocalNotifications.instance.ensureInitialized();
              await AxionCaptureNotification.instance.ensureInitialized();
            }());
            ExecutionReminderNotificationBridge.attach(ref);
            TaskDueNotificationBridge.attach(ref);
            unawaited(CrmPushNavigation.attach(ref));
          },
        );
      });
    }
    // build() içinde ref.listen kullanmak her yeniden çizimde ek yük / çift dinleyici riski taşır.
    _authUserSub = ref.listenManual(currentUserProvider, (prev, next) {
      try {
        final prevUid = prev?.valueOrNull?.uid;
        final uid = next.valueOrNull?.uid;
        if (LogoutFlowTracer.isActive) {
          LogoutFlowTracer.step(
            'AUTH_STATE',
            'currentUserProvider ${prevUid ?? "-"} -> ${uid ?? "-"}',
          );
        }
        if (AppLogger.verboseDiagnosticsEnabled) {
          AppLogger.state(
            '[startup] currentUserProvider ${_describeAsync(next)} uid=${uid ?? "-"}',
          );
          _bindUserDocLogging(uid);
        }
        if (uid != null && uid.isNotEmpty) {
          Future<void>.microtask(
              () => RegionDeepLinkBootstrap.consumePendingAfterAuth(ref));
        }
        if (uid == null || uid.isEmpty) return;
        if (Firebase.apps.isEmpty) return;
        PushNotificationService.instance
            .requestPermissionIfEnabled()
            .then((_) => PushNotificationService.instance
                .refreshTokenAndSaveToFirestore(uid))
            .catchError((Object e, StackTrace st) {
          AppLogger.e('Push init after auth', e, st);
        });
      } catch (e, st) {
        AppLogger.e('currentUserProvider listener', e, st);
      }
    });
  }

  @override
  void dispose() {
    AppLogger.state('[startup] AxionApp.dispose');
    _authUserSub?.close();
    _userDocSub?.close();
    _roleSub?.close();
    _officeAccessSub?.close();
    _needsRoleSub?.close();
    _needsOfficeSub?.close();
    _needsRecoverySub?.close();
    unawaited(RegionDeepLinkBootstrap.dispose());
    AppLifecyclePowerService.instance.removeObserved();
    super.dispose();
  }

  void _bindStartupLogging() {
    if (!AppLogger.verboseDiagnosticsEnabled) return;
    _roleSub = ref.listenManual(currentRoleProvider, (prev, next) {
      AppLogger.state(
        '[startup] currentRoleProvider ${_describeAsync(next)} value=${next.valueOrNull}',
      );
    });
    _officeAccessSub =
        ref.listenManual(officeAccessStateProvider, (prev, next) {
      AppLogger.state(
        '[startup] officeAccessStateProvider ${_describeAsync(next)} value=${next.valueOrNull}',
      );
    });
    _needsRoleSub = ref.listenManual(needsRoleSelectionProvider, (prev, next) {
      AppLogger.state('[startup] needsRoleSelectionProvider=$next');
    });
    _needsOfficeSub = ref.listenManual(needsOfficeSetupProvider, (prev, next) {
      AppLogger.state('[startup] needsOfficeSetupProvider=$next');
    });
    _needsRecoverySub = ref.listenManual(
      needsOfficeRecoveryProvider,
      (prev, next) {
        AppLogger.state('[startup] needsOfficeRecoveryProvider=$next');
      },
    );

    final uid = ref.read(currentUserProvider).valueOrNull?.uid;
    AppLogger.state(
      '[startup] currentUserProvider initial ${_describeAsync(ref.read(currentUserProvider))} uid=${uid ?? "-"}',
    );
    _bindUserDocLogging(uid);
  }

  void _bindUserDocLogging(String? uid) {
    if (!AppLogger.verboseDiagnosticsEnabled) return;
    _userDocSub?.close();
    _userDocSub = null;
    if (uid == null || uid.isEmpty) {
      AppLogger.state('[startup] userDocStreamProvider idle (no uid)');
      return;
    }
    _userDocSub = ref.listenManual(userDocStreamProvider(uid), (prev, next) {
      final doc = next.valueOrNull;
      final officeId = doc?.officeId;
      final role = doc?.role;
      final shortUid = uid.length > 8 ? uid.substring(0, 8) : uid;
      AppLogger.state(
        '[startup] userDocStreamProvider($shortUid) '
        '${_describeAsync(next)} officeId=${officeId ?? "-"} role=${role ?? "-"}',
      );
    });
  }

  String _describeAsync<T>(AsyncValue<T> value) {
    return value.when(
      data: (_) => 'data',
      loading: () => 'loading',
      error: (e, _) => 'error($e)',
    );
  }

  static Future<void> _restoreThemeFromDisk(WidgetRef ref) async {
    try {
      final index = await SettingsService.instance.getThemeModeIndex();
      ref.read(themeModeIndexProvider.notifier).restoreIndex(index);
      AppLogger.state('[startup] themeModeIndex=$index restored post-frame');
    } catch (e, st) {
      AppLogger.e('Theme mode restore (post-frame)', e, st);
    }
  }

  static Future<void> _runDeferredInit() async {
    if (_deferredInitDone) return;
    _deferredInitDone = true;
    AppLogger.state('[startup] deferred init start');
    try {
      Future<void>.delayed(const Duration(milliseconds: 600), () {
        SyncManager.init();
        AppLogger.state('[startup] SyncManager.init done');
      });
    } catch (e, st) {
      AppLogger.e('SyncManager init error', e, st);
    }
    // Hive cache: ağır işlem ilk frame sonrası
    try {
      Future<void>.delayed(
        const Duration(milliseconds: 300),
        () {
          AppLogger.state('[startup] AppCacheService.ensureInit scheduled');
          unawaited(AppCacheService.instance.ensureInit());
        },
      );
    } catch (e, st) {
      AppLogger.e('AppCacheService init error', e, st);
    }
    try {
      configureFirebaseFunctionsForDebug();
      AppLogger.state('[startup] Firebase functions bootstrap configured');
    } catch (e, st) {
      AppLogger.e('Firebase functions bootstrap error', e, st);
    }
    try {
      if (!kIsWeb && Firebase.apps.isNotEmpty) {
        FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
        AppLogger.state('[startup] Crashlytics collection enabled');
      }
    } catch (e, st) {
      AppLogger.e('Crashlytics enable error', e, st);
    }
    try {
      if (!_isFlutterTest) {
        unawaited(AppFeedback.initialize());
        Future<void>.delayed(
          const Duration(seconds: 2),
          () {
            AppLogger.state(
                '[startup] PushNotificationService.initialize scheduled');
            unawaited(PushNotificationService.instance.initialize());
          },
        );
      }
    } catch (e, st) {
      AppLogger.e('Push init defer error', e, st);
    }
    try {
      if (!_isFlutterTest) {
        Future<void>.delayed(const Duration(seconds: 4), () {
          CallRecordSyncOrchestrator.instance.start();
          AppLogger.state('[startup] CallRecordSyncOrchestrator.start (deferred)');
        });
      }
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
    AppLogger.state('[startup] deferred init end');
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(AppRouter.goRouterProvider);
    final locale = ref.watch(localeProvider).valueOrNull ?? const Locale('tr');
    final themeMode = ref.watch(themeModeProvider);
    final userTextScale = ref.watch(textScaleProvider);
    return MaterialApp.router(
      title: 'Axion CRM',
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
        final ext = AppThemeExtension.of(context);
        final isRtl = locale.languageCode == 'ar';
        final content = child != null && isRtl
            ? Directionality(textDirection: TextDirection.rtl, child: child)
            : child;
        if (_lastRouterChildAvailable != (content != null)) {
          _lastRouterChildAvailable = content != null;
          AppLogger.state(
            '[startup] router child ${content != null ? "mounted" : "null"}',
          );
          if (LogoutFlowTracer.isActive) {
            LogoutFlowTracer.step(
              'ROUTER_REDIRECT',
              'materialApp child=${content != null ? "set" : "null"}',
            );
          }
        }

        final signedOut = !kIsWeb &&
            Firebase.apps.isNotEmpty &&
            FirebaseAuth.instance.currentUser == null;

        final shell = Shortcuts(
          shortcuts: const <ShortcutActivator, Intent>{
            SingleActivator(LogicalKeyboardKey.keyK, meta: true):
                _OpenCommandPaletteIntent(),
            SingleActivator(LogicalKeyboardKey.keyK, control: true):
                _OpenCommandPaletteIntent(),
          },
          child: Actions(
            actions: <Type, Action<Intent>>{
              _OpenCommandPaletteIntent:
                  CallbackAction<_OpenCommandPaletteIntent>(
                onInvoke: (_) {
                  // Builder [context] is above [Navigator]; modal APIs need a context
                  // whose ancestors include the root [Overlay] (navigator subtree).
                  final navCtx =
                      router.routerDelegate.navigatorKey.currentContext;
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
                else if (signedOut)
                  // Çıkış sonrası redirect fırtınasında tam ekran spinner donmayı önle.
                  const SizedBox.shrink()
                else
                  // Router henüz sayfa vermeden gösterilen açılış yükleyicisi.
                  // Süresiz spinner YASAK (anayasa: error-resilience): uzun sürerse
                  // [_RootStartupLoader] görünür bir kurtarma/yeniden dene sunar.
                  const _RootStartupLoader(),
                const Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: ConnectivityBanner(),
                ),
                if (!kReleaseMode && isDevMode && showDevUiOverlays)
                  const DevModeBadge(),
              ],
            ),
          ),
        );

        // [child] = router/Navigator subtree (içinde [Overlay]). Bu builder içindeki
        // [Stack] kardeşleri (ör. [DevModeBadge]) Navigator dışında kalır; [Tooltip]
        // veya kök [Overlay] ekleme — "No Overlay widget found" / RawTooltip kırılır.
        //
        // Erişilebilirlik: kullanıcı metin ölçeğini sistem ölçeğiyle birleştir,
        // taşmayı önlemek için 0.85–1.30 arasına sıkıştır (bkz. AppConstants).
        final media = MediaQuery.of(context);
        final systemFactor = media.textScaler.scale(1.0);
        final effectiveFactor =
            (systemFactor * userTextScale).clamp(0.85, 1.30);
        return MediaQuery(
          data: media.copyWith(
            textScaler: TextScaler.linear(effectiveFactor),
          ),
          child: shell,
        );
      },
    );
  }
}

class _OpenCommandPaletteIntent extends Intent {
  const _OpenCommandPaletteIntent();
}

/// Router ilk sayfayı vermeden gösterilen açılış yükleyicisi.
///
/// Anayasa error-resilience: **asla süresiz spinner**. Normal akışta router
/// birkaç yüz ms içinde bir sayfa (login/home) üretir ve bu widget unmount olur.
/// Beklenmedik bir durumda (ör. cihaza özgü ilk-kare/başlatma takılması) içerik
/// gelmezse, kullanıcı sonsuza dek dönen amblemde KALMAZ — görünür bir kurtarma
/// ekranı + "Tekrar dene" sunulur; yeniden deneme Firebase çekirdeğini ve auth
/// akışını tazeler, böylece router hazır olunca yönlendirir.
class _RootStartupLoader extends ConsumerStatefulWidget {
  const _RootStartupLoader();

  @override
  ConsumerState<_RootStartupLoader> createState() => _RootStartupLoaderState();
}

class _RootStartupLoaderState extends ConsumerState<_RootStartupLoader> {
  static const Duration _timeout = Duration(seconds: 12);

  Timer? _timer;
  bool _showRecovery = false;

  @override
  void initState() {
    super.initState();
    _armTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _armTimer() {
    _timer?.cancel();
    _timer = Timer(_timeout, () {
      if (!mounted || _showRecovery) return;
      AppLogger.w('[startup] root loader timeout; showing recovery escape');
      setState(() => _showRecovery = true);
    });
  }

  void _retry() {
    AppLogger.state('[startup] root loader retry requested');
    FirebaseCoreBootstrap.instance.scheduleBackgroundInit();
    ref.invalidate(currentUserProvider);
    setState(() => _showRecovery = false);
    _armTimer();
  }

  @override
  Widget build(BuildContext context) {
    if (_showRecovery) {
      return StartupRecoveryScaffold(
        title: 'Başlatma uzadı',
        message:
            'Uygulama hazırlanırken beklenenden uzun sürdü. Bağlantınızı '
            'kontrol edip yeniden deneyebilirsiniz.',
        onPrimary: _retry,
      );
    }
    final scheme = Theme.of(context).colorScheme;
    return Center(
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
    );
  }
}
