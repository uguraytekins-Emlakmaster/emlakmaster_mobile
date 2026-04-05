import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'dart:async' show unawaited;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../logging/app_logger.dart';
import '../deep_linking/pending_deep_link_store.dart';
import '../../features/office/domain/office_exception.dart';
import '../../features/office/presentation/utils/office_error_ui.dart';
import '../widgets/app_loading.dart';
import '../services/analytics_service.dart';
import '../services/auth_service.dart';
import '../services/onboarding_store.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/auth/presentation/pages/role_selection_page.dart';
import '../../screens/onboarding_page.dart';
import '../../features/auth/domain/permissions/feature_permission.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/calls/call_screen.dart';
import '../../features/calls/post_call_wizard.dart';
import '../../features/calls/presentation/pages/consultant_calls_page.dart';
import '../../screens/consultant_resurrection_page.dart';
import '../../core/lazy/deferred_dashboard_pages.dart';
import '../../features/crm_customers/presentation/pages/customer_detail_page.dart';
import '../../features/notifications/presentation/pages/notifications_center_page.dart';
import '../../features/campaigns/presentation/pages/bulk_campaign_page.dart';
import '../../features/pipeline/presentation/pages/pipeline_kanban_page.dart';
import '../../screens/listing_detail_page.dart';
import '../../screens/role_based_shell.dart';
import '../../features/analytics/presentation/pages/intel_report_history_page.dart';
import '../../features/analytics/presentation/pages/rainbow_analytics_center_page.dart';
import '../../features/region_demand_map/presentation/pages/region_insight_page.dart';
import '../../features/external_integrations/presentation/pages/connected_platforms_page.dart';
import '../../features/external_integrations/presentation/pages/my_external_listings_page.dart';
import '../../features/listing_import/presentation/pages/import_history_page.dart';
import '../../features/listing_import/presentation/pages/import_hub_page.dart';
import '../../features/listing_import/presentation/pages/my_listings_page.dart';
import '../../features/messages/presentation/pages/message_center_page.dart';
import '../../features/messages/presentation/pages/message_thread_page.dart';
import '../../features/workspace/presentation/pages/workspace_setup_page.dart';
import '../../features/office/presentation/pages/create_office_invite_page.dart';
import '../../features/office/presentation/pages/create_office_page.dart';
import '../../features/office/presentation/pages/join_office_page.dart';
import '../../features/office/presentation/pages/office_admin_page.dart';
import '../../features/office/presentation/pages/office_gate_page.dart';
import '../../features/office/presentation/pages/office_recovery_page.dart';
import '../intelligence/region_heatmap_defaults.dart';
/// go_router ile merkezi routing. Login router içinde; beyaz ekran önlenir.
class AppRouter {
  AppRouter._();

  static const String routeLogin = '/login';
  static const String routeRegister = '/register';
  static const String routeOnboarding = '/onboarding';
  /// İlk giriş: ofis oluştur / katıl + isteğe bağlı platform.
  static const String routeWorkspaceSetup = '/workspace-setup';
  /// Çok kiracılı: ofis yokken merkezi kapı.
  static const String routeOfficeGate = '/office';
  static const String routeOfficeCreate = '/office/create';
  static const String routeOfficeJoin = '/office/join';
  static const String routeOfficeInviteCreate = '/office/invite/create';
  /// Üyelik / işaretçi tutarsızlığı, askı, davet tamamlanmadı.
  static const String routeOfficeRecovery = '/office/recovery';
  /// Üye ve davet yönetimi (owner / admin / manager).
  static const String routeOfficeAdmin = '/office/admin';
  /// Birleşik mesaj merkezi (platform API’leri bağlanınca dolar).
  static const String routeMessageCenter = '/messages';
  static const String routeMessageThread = '/messages/thread';

  static bool _isStaffOnlyPath(String path) {
    return path == routeCall ||
        path.startsWith('$routeCall/') ||
        path == routeCommandCenter ||
        path == routeWarRoom ||
        path == routeBrokerCommand ||
        path == routePipeline ||
        path == routeResurrection ||
        path == routeNotifications ||
        path.startsWith('/customer/');
  }

  static String _userFriendlyErrorMessage(Object? error) {
    if (error == null) return 'Sayfa yüklenemedi.';
    final s = error.toString();
    if (s.contains('permission-denied') || s.contains('Permission')) {
      return 'Bu sayfaya erişim yetkiniz yok.';
    }
    if (s.contains('unavailable') || s.contains('network')) {
      return 'Bağlantı kurulamadı. İnterneti kontrol edip tekrar deneyin.';
    }
    if (s.contains('not-found') || s.contains('404')) {
      return 'Sayfa bulunamadı.';
    }
    return 'Bir hata oluştu. Lütfen ana sayfaya dönüp tekrar deneyin.';
  }

  // Tüm route sabitleri aşağıda tek yerde. Yeni path eklerken mutlaka bu listeye + routes[] içine GoRoute ekleyin.
  static const String routeHome = '/';
  static const String routeRoleSelection = '/role-selection';
  static const String routeCall = '/call';
  static const String routeCallSummary = '/call/summary';
  static const String routeConsultantCalls = '/consultant/calls';
  static const String routeResurrection = '/resurrection';
  static const String routeCommandCenter = '/command-center';
  static const String routeWarRoom = '/war-room';
  static const String routeBrokerCommand = '/broker-command';
  static const String routeCustomerDetail = '/customer/:id';
  static const String routeListingDetail = '/listing/:id';
  static const String routePipeline = '/pipeline';
  static const String routeNotifications = '/notifications';
  static const String routeBulkCampaign = '/campaigns/bulk';
  static const String routeRainbowAnalytics = '/rainbow-analytics';
  static const String routeRainbowIntelHistory = '/rainbow-intel-history';
  /// Market Pulse bölge kartı → harita / özet (`:regionId` = örn. kayapinar).
  static const String routeRegionInsight = '/region-insight/:regionId';
  static const String routeConnectedAccounts = '/settings/connected-accounts';
  /// Harici platformlardan senkron ilanlar («Benim ilanlarım»).
  static const String routeMyExternalListings = '/listings/my-external';
  /// Mağaza toplu içe aktarma (dosya birincil; URL deneysel).
  static const String routeImportHub = '/settings/import-engine';
  static const String routeImportHistory = '/settings/import-history';
  /// İçe aktarılan ilanlar (yerel motor — Phase 1.5).
  static const String routeMyListings = '/listings/my-imported';

  static String regionInsightPath(String regionId) =>
      '/region-insight/${Uri.encodeComponent(regionId)}';

  /// Platform bağlantısı / içe aktarma motoru — yalnızca manager-tier (router + UI).
  static bool isManagerOnlyIntegrationPath(String path) {
    return path == routeConnectedAccounts ||
        path == routeImportHub ||
        path == routeImportHistory;
  }

  static GoRouter create(Ref ref, Listenable refreshListenable) {
    return GoRouter(
      initialLocation: routeLogin,
      debugLogDiagnostics: kDebugMode,
      refreshListenable: refreshListenable,
      observers: [_AnalyticsRouteObserver()],
      redirect: (context, state) {
        try {
          final user = ref.read(currentUserProvider).valueOrNull;
          final path = state.uri.path;
          final needsRole = ref.read(needsRoleSelectionProvider);
          final needsOffice = ref.read(needsOfficeSetupProvider);
          final needsOfficeRecovery = ref.read(needsOfficeRecoveryProvider);
          if (user != null && needsRole) {
            final wsDone = OnboardingStore.instance.workspaceSetupCompletedSync;
            if (!wsDone && path != routeWorkspaceSetup) return routeWorkspaceSetup;
            if (wsDone && path == routeWorkspaceSetup) return routeRoleSelection;
            if (wsDone) {
              const allowWhileNeedsRole = <String>{
                routeRoleSelection,
                routeMyExternalListings,
                routeMyListings,
                routeMessageCenter,
                routeMessageThread,
              };
              if (!allowWhileNeedsRole.contains(path)) {
                return routeRoleSelection;
              }
            }
          }
          if (user != null && !needsRole && needsOffice) {
            const allowWhileNeedsOffice = <String>{
              routeOfficeGate,
              routeOfficeCreate,
              routeOfficeJoin,
            };
            if (!allowWhileNeedsOffice.contains(path)) {
              return routeOfficeGate;
            }
            return null;
          }
          if (user != null && !needsRole && !needsOffice && needsOfficeRecovery) {
            const allowWhileRecovery = <String>{
              routeOfficeRecovery,
              routeOfficeGate,
              routeOfficeCreate,
              routeOfficeJoin,
              routeOfficeInviteCreate,
              routeOfficeAdmin,
              routeMyExternalListings,
              routeMyListings,
              routeMessageCenter,
              routeMessageThread,
            };
            if (!allowWhileRecovery.contains(path)) {
              return routeOfficeRecovery;
            }
            return null;
          }
          if (user != null && !needsRole && !needsOffice && !needsOfficeRecovery) {
            const officeSetupPaths = <String>{
              routeOfficeGate,
              routeOfficeCreate,
              routeOfficeJoin,
            };
            if (officeSetupPaths.contains(path)) {
              return routeHome;
            }
            if (!ref.read(userDocBootstrapPendingProvider)) {
              final role = ref.read(currentRoleOrNullProvider);
              if (role != null &&
                  isManagerOnlyIntegrationPath(path) &&
                  !FeaturePermission.canManagePlatformIntegrations(role)) {
                return routeHome;
              }
            }
          }
          if (user != null &&
              (path == routeLogin || path == routeOnboarding || path == routeRegister)) {
            if (needsRole) {
              if (!OnboardingStore.instance.workspaceSetupCompletedSync) return routeWorkspaceSetup;
              return routeRoleSelection;
            }
            if (needsOffice) return routeOfficeGate;
            if (needsOfficeRecovery) return routeOfficeRecovery;
            return routeHome;
          }
          if (user != null && path == routeRoleSelection && !needsRole) {
            if (needsOffice) return routeOfficeGate;
            if (needsOfficeRecovery) return routeOfficeRecovery;
            return routeHome;
          }
          if (user == null && path == routeOnboarding) return null;
          if (user == null && path == routeLogin && !OnboardingStore.instance.completedSync) return routeOnboarding;
          if (user == null &&
              path != routeLogin &&
              path != routeOnboarding &&
              path != routeRegister) {
            if (path.startsWith('/region-insight')) {
              unawaited(PendingDeepLinkStore.save(path));
            }
            return routeLogin;
          }
          final role = ref.read(displayRoleOrNullProvider);
          if (user != null && role != null && role.isClientTier && _isStaffOnlyPath(path)) return routeHome;
          return null;
        } catch (e, st) {
          AppLogger.e('GoRouter redirect', e, st);
          return routeLogin;
        }
      },
      errorBuilder: (context, state) => _ErrorFallbackScreen(
        message: _userFriendlyErrorMessage(state.error),
      ),
      routes: [
        GoRoute(
          path: routeOnboarding,
          pageBuilder: (context, state) => NoTransitionPage(
            key: state.pageKey,
            name: state.matchedLocation,
            child: const OnboardingPage(),
          ),
        ),
        GoRoute(
          path: routeLogin,
          pageBuilder: (context, state) => NoTransitionPage(
            key: state.pageKey,
            name: state.matchedLocation,
            child: const LoginPage(),
          ),
        ),
        GoRoute(
          path: routeRegister,
          pageBuilder: (context, state) => MaterialPage<void>(
            key: state.pageKey,
            name: state.matchedLocation,
            child: const RegisterPage(),
          ),
        ),
        GoRoute(
          path: routeWorkspaceSetup,
          pageBuilder: (context, state) => CustomTransitionPage<void>(
            key: state.pageKey,
            name: state.matchedLocation,
            child: const WorkspaceSetupPage(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) =>
                FadeTransition(opacity: animation, child: child),
          ),
        ),
        GoRoute(
          path: routeOfficeGate,
          pageBuilder: (context, state) => NoTransitionPage(
            key: state.pageKey,
            name: state.matchedLocation,
            child: const OfficeGatePage(),
          ),
        ),
        GoRoute(
          path: routeOfficeCreate,
          pageBuilder: (context, state) => CustomTransitionPage<void>(
            key: state.pageKey,
            name: state.matchedLocation,
            child: const CreateOfficePage(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) =>
                FadeTransition(opacity: animation, child: child),
          ),
        ),
        GoRoute(
          path: routeOfficeJoin,
          pageBuilder: (context, state) => CustomTransitionPage<void>(
            key: state.pageKey,
            name: state.matchedLocation,
            child: const JoinOfficePage(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) =>
                FadeTransition(opacity: animation, child: child),
          ),
        ),
        GoRoute(
          path: routeOfficeInviteCreate,
          pageBuilder: (context, state) => CustomTransitionPage<void>(
            key: state.pageKey,
            name: state.matchedLocation,
            child: const CreateOfficeInvitePage(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) =>
                FadeTransition(opacity: animation, child: child),
          ),
        ),
        GoRoute(
          path: routeOfficeRecovery,
          pageBuilder: (context, state) => CustomTransitionPage<void>(
            key: state.pageKey,
            name: state.matchedLocation,
            child: const OfficeRecoveryPage(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) =>
                FadeTransition(opacity: animation, child: child),
          ),
        ),
        GoRoute(
          path: routeOfficeAdmin,
          pageBuilder: (context, state) => CustomTransitionPage<void>(
            key: state.pageKey,
            name: state.matchedLocation,
            child: const OfficeAdminPage(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) =>
                FadeTransition(opacity: animation, child: child),
          ),
        ),
        GoRoute(
          path: routeMessageCenter,
          pageBuilder: (context, state) => CustomTransitionPage<void>(
            key: state.pageKey,
            name: state.matchedLocation,
            child: const MessageCenterPage(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) =>
                FadeTransition(opacity: animation, child: child),
          ),
        ),
        GoRoute(
          path: routeMessageThread,
          pageBuilder: (context, state) {
            final extra = state.extra as Map<String, dynamic>? ?? {};
            return CustomTransitionPage<void>(
              key: state.pageKey,
              name: state.matchedLocation,
              child: MessageThreadPage(
                customerName: extra['customerName'] as String? ?? 'Müşteri',
                listingRef: extra['listingRef'] as String? ?? '—',
                platformLabel: extra['platformLabel'] as String? ?? '',
              ),
              transitionsBuilder: (context, animation, secondaryAnimation, child) =>
                  FadeTransition(opacity: animation, child: child),
            );
          },
        ),
        GoRoute(
          path: routeRoleSelection,
          pageBuilder: (context, state) => NoTransitionPage(
            key: state.pageKey,
            name: state.matchedLocation,
            child: const RoleSelectionPage(),
          ),
        ),
        GoRoute(
          path: routeHome,
          pageBuilder: (context, state) => NoTransitionPage(
            key: state.pageKey,
            name: state.matchedLocation,
            child: const _AuthShell(child: RoleBasedShellSelector()),
          ),
        ),
        GoRoute(
          path: routeCall,
          pageBuilder: (context, state) {
            final extra = state.extra as Map<String, dynamic>?;
            return CustomTransitionPage<void>(
              key: state.pageKey,
              name: state.matchedLocation,
              child: CallScreen(
                customerId: extra?['customerId'] as String?,
                phone: extra?['phone'] as String?,
              ),
              transitionsBuilder: (context, animation, secondaryAnimation, child) =>
                  FadeTransition(opacity: animation, child: child),
            );
          },
        ),
        GoRoute(
          path: routeCallSummary,
          pageBuilder: (context, state) {
            final extra = state.extra as Map<String, dynamic>?;
            return CustomTransitionPage<void>(
              key: state.pageKey,
              name: state.matchedLocation,
              child: PostCallWizardScreen(
                callDurationSec: extra?['durationSec'] as int?,
                callOutcome: extra?['outcome'] as String?,
                linkedCustomerId: extra?['customerId'] as String?,
              ),
              transitionsBuilder: (context, animation, secondaryAnimation, child) =>
                  FadeTransition(opacity: animation, child: child),
            );
          },
        ),
        GoRoute(
          path: routeConsultantCalls,
          pageBuilder: (context, state) => CustomTransitionPage<void>(
            key: state.pageKey,
            name: state.matchedLocation,
            child: const ConsultantCallsPage(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) =>
                FadeTransition(opacity: animation, child: child),
          ),
        ),
        GoRoute(
          path: routeResurrection,
          pageBuilder: (context, state) => CustomTransitionPage<void>(
            key: state.pageKey,
            name: state.matchedLocation,
            child: const ConsultantResurrectionPage(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) =>
                FadeTransition(opacity: animation, child: child),
          ),
        ),
        GoRoute(
          path: routeCommandCenter,
          pageBuilder: (context, state) => CustomTransitionPage<void>(
            key: state.pageKey,
            name: state.matchedLocation,
            child: const LazyCommandCenterPage(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) =>
                FadeTransition(opacity: animation, child: child),
          ),
        ),
        GoRoute(
          path: routeWarRoom,
          pageBuilder: (context, state) => CustomTransitionPage<void>(
            key: state.pageKey,
            name: state.matchedLocation,
            child: const LazyWarRoomPage(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) =>
                FadeTransition(opacity: animation, child: child),
          ),
        ),
        GoRoute(
          path: routeBrokerCommand,
          pageBuilder: (context, state) => CustomTransitionPage<void>(
            key: state.pageKey,
            name: state.matchedLocation,
            child: const LazyBrokerCommandPage(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) =>
                FadeTransition(opacity: animation, child: child),
          ),
        ),
        GoRoute(
          path: routeCustomerDetail,
          pageBuilder: (context, state) {
            final id = state.pathParameters['id'] ?? '';
            return CustomTransitionPage<void>(
              key: state.pageKey,
              name: state.matchedLocation,
              child: CustomerDetailPage(customerId: id),
              transitionsBuilder: (context, animation, secondaryAnimation, child) =>
                  FadeTransition(opacity: animation, child: child),
            );
          },
        ),
        GoRoute(
          path: routeListingDetail,
          pageBuilder: (context, state) {
            final id = state.pathParameters['id'] ?? '';
            return CustomTransitionPage<void>(
              key: state.pageKey,
              name: state.matchedLocation,
              child: ListingDetailPage(listingId: id),
              transitionsBuilder: (context, animation, secondaryAnimation, child) =>
                  FadeTransition(opacity: animation, child: child),
            );
          },
        ),
        GoRoute(
          path: routePipeline,
          pageBuilder: (context, state) => CustomTransitionPage<void>(
            key: state.pageKey,
            name: state.matchedLocation,
            child: const PipelineKanbanPage(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) =>
                FadeTransition(opacity: animation, child: child),
          ),
        ),
        GoRoute(
          path: routeNotifications,
          pageBuilder: (context, state) => CustomTransitionPage<void>(
            key: state.pageKey,
            name: state.matchedLocation,
            child: const NotificationsCenterPage(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) =>
                FadeTransition(opacity: animation, child: child),
          ),
        ),
        GoRoute(
          path: routeBulkCampaign,
          pageBuilder: (context, state) => CustomTransitionPage<void>(
            key: state.pageKey,
            name: state.matchedLocation,
            child: const BulkCampaignPage(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) =>
                FadeTransition(opacity: animation, child: child),
          ),
        ),
        GoRoute(
          path: routeRainbowAnalytics,
          pageBuilder: (context, state) {
            final listingId = state.uri.queryParameters['listingId'];
            return CustomTransitionPage<void>(
              key: state.pageKey,
              name: state.matchedLocation,
              child: RainbowAnalyticsCenterPage(prefillListingId: listingId),
              transitionsBuilder: (context, animation, secondaryAnimation, child) =>
                  FadeTransition(opacity: animation, child: child),
            );
          },
        ),
        GoRoute(
          path: routeRainbowIntelHistory,
          pageBuilder: (context, state) => CustomTransitionPage<void>(
            key: state.pageKey,
            name: state.matchedLocation,
            child: const IntelReportHistoryPage(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) =>
                FadeTransition(opacity: animation, child: child),
          ),
        ),
        GoRoute(
          path: routeRegionInsight,
          pageBuilder: (context, state) {
            final id = state.pathParameters['regionId'] ?? '';
            final region = resolveRegionHeatmapForRoute(
              regionId: id,
              extra: state.extra,
            );
            return CustomTransitionPage<void>(
              key: state.pageKey,
              name: state.matchedLocation,
              child: RegionInsightPage(region: region),
              transitionsBuilder: (context, animation, secondaryAnimation, child) =>
                  FadeTransition(opacity: animation, child: child),
            );
          },
        ),
        GoRoute(
          path: routeConnectedAccounts,
          pageBuilder: (context, state) => CustomTransitionPage<void>(
            key: state.pageKey,
            name: state.matchedLocation,
            child: const ConnectedPlatformsPage(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) =>
                FadeTransition(opacity: animation, child: child),
          ),
        ),
        GoRoute(
          path: routeMyExternalListings,
          pageBuilder: (context, state) => CustomTransitionPage<void>(
            key: state.pageKey,
            name: state.matchedLocation,
            child: const MyExternalListingsPage(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) =>
                FadeTransition(opacity: animation, child: child),
          ),
        ),
        GoRoute(
          path: routeMyListings,
          pageBuilder: (context, state) {
            final extra = state.extra as Map<String, dynamic>?;
            final taskId = extra?['importTaskId'] as String?;
            return CustomTransitionPage<void>(
              key: state.pageKey,
              name: state.matchedLocation,
              child: MyListingsPage(initialImportTaskId: taskId),
              transitionsBuilder: (context, animation, secondaryAnimation, child) =>
                  FadeTransition(opacity: animation, child: child),
            );
          },
        ),
        GoRoute(
          path: routeImportHub,
          pageBuilder: (context, state) => CustomTransitionPage<void>(
            key: state.pageKey,
            name: state.matchedLocation,
            child: const ImportHubPage(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) =>
                FadeTransition(opacity: animation, child: child),
          ),
        ),
        GoRoute(
          path: routeImportHistory,
          pageBuilder: (context, state) => CustomTransitionPage<void>(
            key: state.pageKey,
            name: state.matchedLocation,
            child: const ImportHistoryPage(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) =>
                FadeTransition(opacity: animation, child: child),
          ),
        ),
      ],
    );
  }

  static final goRouterProvider = Provider<GoRouter>((ref) {
    final refresh = ValueNotifier(0);
    // Redirect kararları currentUser + role/doc durumuna bağlı.
    // Role yüklenirken (users/{uid} doc yokken) `needsRoleSelectionProvider` değişir;
    // bu değişim için refresh tetiklenmezse yanlış route'ta kalınabiliyor.
    ref.listen(currentUserProvider, (_, __) => refresh.value++);
    ref.listen(needsRoleSelectionProvider, (_, __) => refresh.value++);
    ref.listen(needsOfficeSetupProvider, (_, __) => refresh.value++);
    ref.listen(needsOfficeRecoveryProvider, (_, __) => refresh.value++);
    ref.listen(primaryMembershipProvider, (_, __) => refresh.value++);
    ref.listen(officeAccessStateProvider, (_, __) => refresh.value++);
    return AppRouter.create(ref, refresh);
  });
}

/// Giriş yapılmış kullanıcı için: rol yüklenene kadar loading, sonra child.
class _AuthShell extends ConsumerWidget {
  const _AuthShell({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roleAsync = ref.watch(currentRoleProvider);
    return roleAsync.when(
      loading: () => const _RouteLoadingScreen(),
      error: (e, _) {
        final uid = ref.watch(currentUserProvider).valueOrNull?.uid;
        if (uid == null || uid.isEmpty) {
          return const _RouteLoadingScreen();
        }
        return _HomeShellRoleErrorScreen(uid: uid, error: e);
      },
      data: (_) => child,
    );
  }
}

/// Ana shell: Firestore users/{uid} dinlenemezse (permission-denied, ağ vb.) sonsuz yüklemede kalmayı önler.
class _HomeShellRoleErrorScreen extends ConsumerWidget {
  const _HomeShellRoleErrorScreen({required this.uid, required this.error});

  final String uid;
  final Object error;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = officeErrorUserMessage(error);
    final detail = error is OfficeException ? null : error.toString();

    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    return Scaffold(
      backgroundColor: AppThemeExtension.of(context).background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline_rounded, size: 64, color: AppThemeExtension.of(context).accent),
              const SizedBox(height: 24),
              Text(
                text,
                textAlign: TextAlign.center,
                style: TextStyle(color: onSurface.withValues(alpha: 0.9), fontSize: 16),
              ),
              if (detail != null) ...[
                const SizedBox(height: 12),
                Text(
                  detail,
                  textAlign: TextAlign.center,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: onSurface.withValues(alpha: 0.55), fontSize: 11),
                ),
              ],
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: () {
                  ref.invalidate(userDocStreamProvider(uid));
                },
                icon: const Icon(Icons.refresh_rounded, size: 20),
                label: const Text('Tekrar dene'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppThemeExtension.of(context).accent,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () async {
                  await AuthService.instance.signOut();
                },
                icon: const Icon(Icons.logout_rounded, size: 20),
                label: const Text('Çıkış yap'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: onSurface.withValues(alpha: 0.9),
                  side: BorderSide(color: onSurface.withValues(alpha: 0.4)),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RouteLoadingScreen extends StatelessWidget {
  const _RouteLoadingScreen();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: AppThemeExtension.of(context).background,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AppLoading(),
            const SizedBox(height: 24),
            Text(
              'Yükleniyor...',
              style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.9), fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnalyticsRouteObserver extends NavigatorObserver {
  void _debugLog(String action, Route<dynamic>? route) {
    if (!kDebugMode) return;
    final n = route?.settings.name;
    AppLogger.nav(
      '$action ${n != null && n.isNotEmpty ? n : route?.settings.arguments ?? route.runtimeType}',
    );
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    try {
      _debugLog('push', route);
      final name = route.settings.name;
      if (name != null && name.isNotEmpty) {
        AnalyticsService.instance.logScreenView(screenName: name);
      }
    } catch (e, st) {
      AppLogger.e('RouteObserver.didPush', e, st);
    }
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    try {
      _debugLog('pop', route);
    } catch (e, st) {
      AppLogger.e('RouteObserver.didPop', e, st);
    }
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    try {
      _debugLog('replace', newRoute);
    } catch (e, st) {
      AppLogger.e('RouteObserver.didReplace', e, st);
    }
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didRemove(route, previousRoute);
    try {
      _debugLog('remove', route);
    } catch (e, st) {
      AppLogger.e('RouteObserver.didRemove', e, st);
    }
  }
}

class _ErrorFallbackScreen extends StatelessWidget {
  const _ErrorFallbackScreen({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    return Scaffold(
      backgroundColor: AppThemeExtension.of(context).background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 64,
                color: AppThemeExtension.of(context).accent,
              ),
              const SizedBox(height: 24),
              Text(
                'Bir şeyler ters gitti',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Lütfen tekrar deneyin veya ana sayfaya dönün.',
                textAlign: TextAlign.center,
                style: TextStyle(color: onSurface.withValues(alpha: 0.9), fontSize: 14),
              ),
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: () => context.go(AppRouter.routeHome),
                icon: const Icon(Icons.home_rounded),
                label: const Text('Ana Sayfaya Dön'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppThemeExtension.of(context).accent,
                  foregroundColor: AppThemeExtension.of(context).onBrand,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
