import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'dart:async' show unawaited;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../logging/app_logger.dart';
import '../navigation/app_back_dispatcher.dart';
import '../deep_linking/pending_deep_link_store.dart';
import '../router/fast_page_transitions.dart';
import '../services/analytics_service.dart';
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
import '../../features/external_integrations/presentation/pages/platform_setup_wizard_page.dart';
import '../../features/external_integrations/presentation/platform_setup_wizard_args.dart';
import '../../features/external_integrations/presentation/pages/my_external_listings_page.dart';
import '../../features/listing_import/presentation/pages/import_history_page.dart';
import '../../features/listing_import/presentation/pages/import_hub_page.dart';
import '../../features/listing_import/presentation/pages/my_listings_page.dart';
import '../../features/messages/presentation/pages/message_center_page.dart';
import '../../features/messages/presentation/pages/team_thread_page.dart';
import '../../features/workspace/presentation/pages/workspace_setup_page.dart';
import '../../features/office/presentation/pages/create_office_invite_page.dart';
import '../../features/office/presentation/pages/create_office_page.dart';
import '../../features/office/presentation/pages/join_office_page.dart';
import '../../features/office/presentation/pages/office_admin_page.dart';
import '../../features/office/presentation/pages/office_gate_page.dart';
import '../../features/office/presentation/pages/office_recovery_page.dart';
import '../../features/admin_consultants/presentation/pages/admin_consultants_page.dart';
import '../../features/admin_teams/presentation/pages/admin_team_detail_page.dart';
import '../../features/admin_teams/presentation/pages/admin_teams_page.dart';
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
        path.startsWith('/customer/') ||
        path.startsWith('/admin/');
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

  /// Yönetici: resmi entegrasyon / dosya geri dönüş kurulum sihirbazı.
  static const String routePlatformSetupWizard =
      '/settings/platform-setup-wizard';

  /// Harici platformlardan senkron ilanlar («Benim ilanlarım»).
  static const String routeMyExternalListings = '/listings/my-external';

  /// Mağaza toplu içe aktarma (dosya birincil; URL deneysel).
  static const String routeImportHub = '/settings/import-engine';
  static const String routeImportHistory = '/settings/import-history';

  /// İçe aktarılan ilanlar (yerel motor — Phase 1.5).
  static const String routeMyListings = '/listings/my-imported';

  static const String routeAdminConsultants = '/admin/consultants';
  static const String routeAdminTeams = '/admin/teams';
  static const String routeAdminTeamDetail = '/admin/teams/:teamId';

  static String adminTeamDetailPath(String teamId) =>
      '/admin/teams/${Uri.encodeComponent(teamId)}';

  static String regionInsightPath(String regionId) =>
      '/region-insight/${Uri.encodeComponent(regionId)}';

  /// Platform bağlantısı / içe aktarma motoru — yalnızca manager-tier (router + UI).
  static bool isManagerOnlyIntegrationPath(String path) {
    return path == routeConnectedAccounts ||
        path == routePlatformSetupWizard ||
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
          final user = readRouterAuthUser(ref);
          final path = state.uri.path;
          final needsRole = ref.read(needsRoleSelectionProvider);
          final needsOffice = ref.read(needsOfficeSetupProvider);
          final needsOfficeRecovery = ref.read(needsOfficeRecoveryProvider);
          if (user != null && needsRole) {
            final wsDone = OnboardingStore.instance.workspaceSetupCompletedSync;
            if (!wsDone && path != routeWorkspaceSetup) {
              return routeWorkspaceSetup;
            }
            if (wsDone && path == routeWorkspaceSetup) {
              return routeRoleSelection;
            }
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
          if (user != null &&
              !needsRole &&
              !needsOffice &&
              needsOfficeRecovery) {
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
          if (user != null &&
              !needsRole &&
              !needsOffice &&
              !needsOfficeRecovery) {
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
              (path == routeLogin ||
                  path == routeOnboarding ||
                  path == routeRegister)) {
            if (needsRole) {
              if (!OnboardingStore.instance.workspaceSetupCompletedSync) {
                return routeWorkspaceSetup;
              }
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
          if (user == null &&
              path == routeLogin &&
              !OnboardingStore.instance.completedSync) {
            return routeOnboarding;
          }
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
          if (user != null &&
              role != null &&
              role.isClientTier &&
              _isStaffOnlyPath(path)) {
            return routeHome;
          }
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
          pageBuilder: (context, state) => fastFadePage<void>(
            key: state.pageKey,
            name: state.matchedLocation,
            child: const WorkspaceSetupPage(),
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
          pageBuilder: (context, state) => fastFadePage<void>(
            key: state.pageKey,
            name: state.matchedLocation,
            child: const CreateOfficePage(),
          ),
        ),
        GoRoute(
          path: routeOfficeJoin,
          pageBuilder: (context, state) => fastFadePage<void>(
            key: state.pageKey,
            name: state.matchedLocation,
            child: const JoinOfficePage(),
          ),
        ),
        GoRoute(
          path: routeOfficeInviteCreate,
          pageBuilder: (context, state) => fastFadePage<void>(
            key: state.pageKey,
            name: state.matchedLocation,
            child: const CreateOfficeInvitePage(),
          ),
        ),
        GoRoute(
          path: routeOfficeRecovery,
          pageBuilder: (context, state) => fastFadePage<void>(
            key: state.pageKey,
            name: state.matchedLocation,
            child: const OfficeRecoveryPage(),
          ),
        ),
        GoRoute(
          path: routeOfficeAdmin,
          pageBuilder: (context, state) => fastFadePage<void>(
            key: state.pageKey,
            name: state.matchedLocation,
            child: const OfficeAdminPage(),
          ),
        ),
        GoRoute(
          path: routeMessageCenter,
          pageBuilder: (context, state) => fastFadePage<void>(
            key: state.pageKey,
            name: state.matchedLocation,
            child: const MessageCenterPage(),
          ),
        ),
        GoRoute(
          path: routeMessageThread,
          pageBuilder: (context, state) {
            final extra = state.extra as Map<String, dynamic>? ?? {};
            final officeId = extra['officeId'] as String? ?? '';
            final channelId = extra['channelId'] as String? ?? '';
            return fastFadePage<void>(
              key: state.pageKey,
              name: state.matchedLocation,
              child: TeamThreadPage(
                officeId: officeId,
                channelId: channelId,
                title: extra['title'] as String? ?? 'Sohbet',
                subtitle: extra['subtitle'] as String? ?? '',
              ),
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
            return fastFadePage<void>(
              key: state.pageKey,
              name: state.matchedLocation,
              child: CallScreen(
                customerId: extra?['customerId'] as String?,
                phone: extra?['phone'] as String?,
                inAppCrmSession: extra?['inAppCrmSession'] as bool? ?? false,
                startedFromScreen: extra?['startedFromScreen'] as String?,
              ),
            );
          },
        ),
        GoRoute(
          path: routeCallSummary,
          pageBuilder: (context, state) {
            final extra = state.extra as Map<String, dynamic>?;
            return fastFadePage<void>(
              key: state.pageKey,
              name: state.matchedLocation,
              child: PostCallWizardScreen(
                callDurationSec: extra?['durationSec'] as int?,
                callOutcome: extra?['outcome'] as String?,
                linkedCustomerId: extra?['customerId'] as String?,
                phoneNumber: extra?['phone'] as String?,
                callSessionId: extra?['callSessionId'] as String?,
              ),
            );
          },
        ),
        GoRoute(
          path: routeConsultantCalls,
          pageBuilder: (context, state) => fastFadePage<void>(
            key: state.pageKey,
            name: state.matchedLocation,
            child: const ConsultantCallsPage(),
          ),
        ),
        GoRoute(
          path: routeResurrection,
          pageBuilder: (context, state) => fastFadePage<void>(
            key: state.pageKey,
            name: state.matchedLocation,
            child: const ConsultantResurrectionPage(),
          ),
        ),
        GoRoute(
          path: routeCommandCenter,
          pageBuilder: (context, state) => fastFadePage<void>(
            key: state.pageKey,
            name: state.matchedLocation,
            child: const LazyCommandCenterPage(),
          ),
        ),
        GoRoute(
          path: routeWarRoom,
          pageBuilder: (context, state) => fastFadePage<void>(
            key: state.pageKey,
            name: state.matchedLocation,
            child: const LazyWarRoomPage(),
          ),
        ),
        GoRoute(
          path: routeBrokerCommand,
          pageBuilder: (context, state) => fastFadePage<void>(
            key: state.pageKey,
            name: state.matchedLocation,
            child: const LazyBrokerCommandPage(),
          ),
        ),
        GoRoute(
          path: routeCustomerDetail,
          pageBuilder: (context, state) {
            final id = state.pathParameters['id'] ?? '';
            return fastFadePage<void>(
              key: state.pageKey,
              name: state.matchedLocation,
              child: CustomerDetailPage(customerId: id),
            );
          },
        ),
        GoRoute(
          path: routeListingDetail,
          pageBuilder: (context, state) {
            final id = state.pathParameters['id'] ?? '';
            return fastFadePage<void>(
              key: state.pageKey,
              name: state.matchedLocation,
              child: ListingDetailPage(listingId: id),
            );
          },
        ),
        GoRoute(
          path: routePipeline,
          pageBuilder: (context, state) => fastFadePage<void>(
            key: state.pageKey,
            name: state.matchedLocation,
            child: const PipelineKanbanPage(),
          ),
        ),
        GoRoute(
          path: routeNotifications,
          pageBuilder: (context, state) => fastFadePage<void>(
            key: state.pageKey,
            name: state.matchedLocation,
            child: const NotificationsCenterPage(),
          ),
        ),
        GoRoute(
          path: routeBulkCampaign,
          pageBuilder: (context, state) => fastFadePage<void>(
            key: state.pageKey,
            name: state.matchedLocation,
            child: const BulkCampaignPage(),
          ),
        ),
        GoRoute(
          path: routeRainbowAnalytics,
          pageBuilder: (context, state) {
            final listingId = state.uri.queryParameters['listingId'];
            return fastFadePage<void>(
              key: state.pageKey,
              name: state.matchedLocation,
              child: RainbowAnalyticsCenterPage(prefillListingId: listingId),
            );
          },
        ),
        GoRoute(
          path: routeRainbowIntelHistory,
          pageBuilder: (context, state) => fastFadePage<void>(
            key: state.pageKey,
            name: state.matchedLocation,
            child: const IntelReportHistoryPage(),
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
            return fastFadePage<void>(
              key: state.pageKey,
              name: state.matchedLocation,
              child: RegionInsightPage(region: region),
            );
          },
        ),
        GoRoute(
          path: routeConnectedAccounts,
          pageBuilder: (context, state) => fastFadePage<void>(
            key: state.pageKey,
            name: state.matchedLocation,
            child: const ConnectedPlatformsPage(),
          ),
        ),
        GoRoute(
          path: routePlatformSetupWizard,
          pageBuilder: (context, state) {
            final extra = state.extra as PlatformSetupWizardArgs?;
            return fastFadePage<void>(
              key: state.pageKey,
              name: state.matchedLocation,
              child: PlatformSetupWizardPage(
                initialPlatform: extra?.initialPlatform,
                editMode: extra?.editMode ?? false,
              ),
            );
          },
        ),
        GoRoute(
          path: routeMyExternalListings,
          pageBuilder: (context, state) => fastFadePage<void>(
            key: state.pageKey,
            name: state.matchedLocation,
            child: const MyExternalListingsPage(),
          ),
        ),
        GoRoute(
          path: routeMyListings,
          pageBuilder: (context, state) {
            final extra = state.extra as Map<String, dynamic>?;
            final taskId = extra?['importTaskId'] as String?;
            return fastFadePage<void>(
              key: state.pageKey,
              name: state.matchedLocation,
              child: MyListingsPage(initialImportTaskId: taskId),
            );
          },
        ),
        GoRoute(
          path: routeImportHub,
          pageBuilder: (context, state) => fastFadePage<void>(
            key: state.pageKey,
            name: state.matchedLocation,
            child: const ImportHubPage(),
          ),
        ),
        GoRoute(
          path: routeImportHistory,
          pageBuilder: (context, state) => fastFadePage<void>(
            key: state.pageKey,
            name: state.matchedLocation,
            child: const ImportHistoryPage(),
          ),
        ),
        GoRoute(
          path: routeAdminConsultants,
          pageBuilder: (context, state) => fastFadePage<void>(
            key: state.pageKey,
            name: state.matchedLocation,
            child: const AdminConsultantsPage(),
          ),
        ),
        GoRoute(
          path: routeAdminTeams,
          pageBuilder: (context, state) => fastFadePage<void>(
            key: state.pageKey,
            name: state.matchedLocation,
            child: const AdminTeamsPage(),
          ),
        ),
        GoRoute(
          path: routeAdminTeamDetail,
          pageBuilder: (context, state) {
            final teamId = state.pathParameters['teamId'] ?? '';
            return fastFadePage<void>(
              key: state.pageKey,
              name: state.matchedLocation,
              child: AdminTeamDetailPage(teamId: teamId),
            );
          },
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

/// Bootstrap tek katmanda ([RoleBasedShellSelector]); çift “yükleniyor” ekranı yok.
class _AuthShell extends ConsumerWidget {
  const _AuthShell({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) => child;
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
    final canPop = AppBackDispatcher.canPopRoute(context);
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
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: onSurface.withValues(alpha: 0.9), fontSize: 14),
              ),
              const SizedBox(height: 32),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 12,
                runSpacing: 12,
                children: [
                  FilledButton.icon(
                    onPressed: () => context.go(AppRouter.routeHome),
                    icon: const Icon(Icons.home_rounded),
                    label: const Text('Ana Sayfaya Dön'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppThemeExtension.of(context).accent,
                      foregroundColor: AppThemeExtension.of(context).onBrand,
                    ),
                  ),
                  if (canPop)
                    OutlinedButton.icon(
                      onPressed: () => AppBackDispatcher.popRoute(context),
                      icon: const Icon(Icons.arrow_back_rounded),
                      label: const Text('Geri Dön'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
