import 'package:emlakmaster_mobile/core/l10n/app_localizations.dart';
import 'package:emlakmaster_mobile/core/router/app_router.dart';
import 'package:emlakmaster_mobile/core/services/login_entry_store.dart';
import 'package:emlakmaster_mobile/core/services/onboarding_store.dart';
import 'package:emlakmaster_mobile/core/theme/app_theme.dart';
import 'package:emlakmaster_mobile/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('OnboardingPage', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await OnboardingStore.instance.resetForTesting();
      await LoginEntryStore.instance.clearPersona();
    });

    Widget buildHarness(GoRouter router) {
      return MaterialApp.router(
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        locale: const Locale('tr'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          AppLocalizationsDelegate(),
        ],
        routerConfig: router,
      );
    }

    Future<void> pumpOnboarding(WidgetTester tester, GoRouter router) async {
      tester.view.physicalSize = const Size(390, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(buildHarness(router));
      await tester.pumpAndSettle();
    }

    testWidgets('shows first slide and advances with İleri', (
      WidgetTester tester,
    ) async {
      final router = GoRouter(
        initialLocation: '/onboarding',
        routes: [
          GoRoute(
            path: '/onboarding',
            builder: (_, __) => const OnboardingPage(),
          ),
          GoRoute(
            path: AppRouter.routeLogin,
            builder: (_, __) =>
                const Scaffold(body: Center(child: Text('login-destination'))),
          ),
        ],
      );

      await pumpOnboarding(tester, router);

      final l10n = AppLocalizations(const Locale('tr'));
      expect(find.text(l10n.t('onboarding_welcome_title')), findsOneWidget);
      expect(find.text(l10n.t('onboarding_next')), findsOneWidget);

      await tester.tap(find.text(l10n.t('onboarding_next')));
      await tester.pumpAndSettle();

      expect(find.text(l10n.t('onboarding_platform_title')), findsOneWidget);
    });

    testWidgets('finish requires persona on last slide', (
      WidgetTester tester,
    ) async {
      final router = GoRouter(
        initialLocation: '/onboarding',
        routes: [
          GoRoute(
            path: '/onboarding',
            builder: (_, __) => const OnboardingPage(initialPage: 5),
          ),
          GoRoute(
            path: AppRouter.routeLogin,
            builder: (_, __) =>
                const Scaffold(body: Center(child: Text('login-destination'))),
          ),
        ],
      );

      await pumpOnboarding(tester, router);

      final l10n = AppLocalizations(const Locale('tr'));

      await tester.tap(find.text(l10n.t('onboarding_finish')));
      await tester.pumpAndSettle();

      expect(find.text(l10n.t('onboarding_persona_required')), findsOneWidget);
      expect(find.text('login-destination'), findsNothing);

      await tester.tap(find.text('Yönetici'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.t('onboarding_finish')));
      await tester.pumpAndSettle();

      expect(find.text('login-destination'), findsOneWidget);
    });
  });
}
