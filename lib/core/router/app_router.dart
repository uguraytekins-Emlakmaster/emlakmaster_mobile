import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../theme/design_tokens.dart';
import '../widgets/app_loading.dart';
import '../services/analytics_service.dart';
import '../services/onboarding_store.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/auth/presentation/pages/role_selection_page.dart';
import '../../screens/onboarding_page.dart';
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

/// go_router ile merkezi routing. Login router içinde; beyaz ekran önlenir.
class AppRouter {
  AppRouter._();

  static const String routeLogin = '/login';
  static const String routeRegister = '/register';
  static const String routeOnboarding = '/onboarding';

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
          if (user != null && needsRole && path != routeRoleSelection) return routeRoleSelection;
          if (user != null &&
              (path == routeLogin || path == routeOnboarding || path == routeRegister)) {
            return routeHome;
          }
          if (user != null && path == routeRoleSelection && !needsRole) return routeHome;
          if (user == null && path == routeOnboarding) return null;
          if (user == null && path == routeLogin && !OnboardingStore.instance.completedSync) return routeOnboarding;
          if (user == null &&
              path != routeLogin &&
              path != routeOnboarding &&
              path != routeRegister) {
            return routeLogin;
          }
          final role = ref.read(displayRoleOrNullProvider);
          if (user != null && role != null && role.isClientTier && _isStaffOnlyPath(path)) return routeHome;
          return null;
        } catch (_) {
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
      ],
    );
  }

  static final goRouterProvider = Provider<GoRouter>((ref) {
    final refresh = ValueNotifier(0);
    ref.listen(currentUserProvider, (_, __) => refresh.value++);
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
      error: (_, __) => const _RouteLoadingScreen(),
      data: (_) => child,
    );
  }
}

class _RouteLoadingScreen extends StatelessWidget {
  const _RouteLoadingScreen();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: DesignTokens.backgroundDark,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AppLoading(),
            const SizedBox(height: 24),
            Text(
              'Yükleniyor...',
              style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.9), fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnalyticsRouteObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    final name = route.settings.name;
    if (name != null && name.isNotEmpty) {
      AnalyticsService.instance.logScreenView(screenName: name);
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
      backgroundColor: DesignTokens.backgroundDark,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: 64,
                color: DesignTokens.primary,
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
                style: TextStyle(color: onSurface.withOpacity(0.9), fontSize: 14),
              ),
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: () => context.go(AppRouter.routeHome),
                icon: const Icon(Icons.home_rounded),
                label: const Text('Ana Sayfaya Dön'),
                style: FilledButton.styleFrom(
                  backgroundColor: DesignTokens.primary,
                  foregroundColor: DesignTokens.inputTextOnGold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
