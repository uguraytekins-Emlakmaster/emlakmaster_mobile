import 'package:emlakmaster_mobile/core/theme/app_theme.dart';
import 'package:emlakmaster_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:emlakmaster_mobile/features/dashboard/presentation/providers/broker_dashboard_kpi_providers.dart';
import 'package:emlakmaster_mobile/features/resurrection_engine/presentation/providers/resurrection_queue_provider.dart';
import 'package:emlakmaster_mobile/screens/consultant_dashboard/widgets/consultant_dashboard_action_anchor.dart';
import 'package:emlakmaster_mobile/screens/consultant_dashboard/widgets/consultant_dashboard_hero_card.dart';
import 'package:emlakmaster_mobile/screens/consultant_dashboard/widgets/consultant_dashboard_kpi_bento.dart';
import 'package:emlakmaster_mobile/screens/consultant_dashboard/widgets/consultant_dashboard_quick_nav.dart';
import 'package:emlakmaster_mobile/screens/consultant_dashboard/widgets/consultant_dashboard_section_header.dart';
import 'package:emlakmaster_mobile/screens/consultant_dashboard/consultant_dashboard_tokens.dart';
import 'package:emlakmaster_mobile/screens/providers/consultant_dashboard_kpi_providers.dart';
import 'package:emlakmaster_mobile/widgets/premium/premium_bottom_nav_dock.dart';
import 'package:emlakmaster_mobile/core/layout/adaptive_shell_scaffold.dart';
import 'package:emlakmaster_mobile/core/copy/product_labels.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Device profiles for Phase A.3 overflow zero policy.
const _profiles = <({String name, Size size, double textScale, EdgeInsets padding})>[
  (name: 'iPhone SE', size: Size(320, 568), textScale: 1.0, padding: EdgeInsets.zero),
  (
    name: 'iPhone 14',
    size: Size(390, 844),
    textScale: 1.0,
    padding: EdgeInsets.only(bottom: 34),
  ),
  (
    name: 'iPhone 15 Pro',
    size: Size(393, 852),
    textScale: 1.15,
    padding: EdgeInsets.only(bottom: 34),
  ),
  (
    name: 'Android compact',
    size: Size(360, 640),
    textScale: 1.0,
    padding: EdgeInsets.only(bottom: 24),
  ),
  (
    name: 'Android normal',
    size: Size(412, 915),
    textScale: 1.0,
    padding: EdgeInsets.only(bottom: 28),
  ),
  (
    name: 'macOS windowed',
    size: Size(1280, 800),
    textScale: 1.0,
    padding: EdgeInsets.zero,
  ),
  (
    name: 'iPad tablet',
    size: Size(834, 1194),
    textScale: 1.0,
    padding: EdgeInsets.only(bottom: 20),
  ),
  (
    name: 'large tablet',
    size: Size(1024, 1366),
    textScale: 1.1,
    padding: EdgeInsets.only(bottom: 20),
  ),
];

List<Override> _dashboardOverrides() => [
  currentUserProvider.overrideWith((ref) => Stream.value(null)),
  todayCallsCountProvider.overrideWith((ref) => Stream.value(0)),
  advisorOpenTasksCountProvider.overrideWith(
    (ref, uid) => Stream.value(uid.isEmpty ? 0 : 6),
  ),
  advisorPipelineCountProvider.overrideWith(
    (ref, uid) => Stream.value(uid.isEmpty ? 0 : 1),
  ),
  agentWeeklyCallCountProvider.overrideWith(
    (ref, uid) => Stream.value(uid.isEmpty ? 0 : 3),
  ),
  resurrectionQueueProvider.overrideWith((ref) => Stream.value([])),
];

Future<void> _pumpCockpit(
  WidgetTester tester, {
  required Size size,
  required double textScale,
  required EdgeInsets padding,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: _dashboardOverrides(),
      child: MaterialApp(
        theme: AppTheme.dark(),
        home: MediaQuery(
          data: MediaQueryData(
            size: size,
            textScaler: TextScaler.linear(textScale),
            padding: padding,
          ),
          child: Scaffold(
            body: SafeArea(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: ConsultantDashboardTokens.horizontal,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: const [
                      ConsultantDashboardHeroCard(
                        greeting: 'Günaydın, Test',
                      ),
                      SizedBox(height: ConsultantDashboardTokens.sectionGap),
                      ConsultantDashboardSectionHeader(
                        label: 'Günün özeti',
                        subtitle: 'Canlı KPI ve haftalık tempo',
                        icon: Icons.insights_rounded,
                      ),
                      ConsultantDashboardKpiBento(),
                      SizedBox(height: ConsultantDashboardTokens.sectionGap),
                      ConsultantDashboardSectionHeader(
                        label: 'Hızlı erişim',
                        subtitle: 'Tek dokunuşla geçiş',
                        icon: Icons.bolt_rounded,
                      ),
                      ConsultantDashboardQuickNavGrid(),
                      SizedBox(height: ConsultantDashboardTokens.blockGap),
                      ConsultantDashboardActionAnchor(),
                    ],
                  ),
                ),
              ),
            ),
            bottomNavigationBar: PremiumBottomNavDock(
              items: const [
                AdaptiveNavItem(
                  Icons.space_dashboard_rounded,
                  ProductLabels.consultantHome,
                ),
                AdaptiveNavItem(Icons.call_rounded, ProductLabels.myCalls),
                AdaptiveNavItem(Icons.people_rounded, ProductLabels.myCustomers),
                AdaptiveNavItem(Icons.task_alt_rounded, ProductLabels.myTasks),
                AdaptiveNavItem(Icons.apps_rounded, ProductLabels.consultantMore),
              ],
              selectedIndex: 0,
              onTap: (_) {},
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  group('Consultant Dashboard Phase A.3 overflow zero', () {
    for (final profile in _profiles) {
      testWidgets('cockpit + dock · ${profile.name}', (tester) async {
        await _pumpCockpit(
          tester,
          size: profile.size,
          textScale: profile.textScale,
          padding: profile.padding,
        );
        expect(tester.takeException(), isNull);
        expect(find.byType(ConsultantDashboardHeroCard), findsOneWidget);
        expect(find.byType(ConsultantDashboardKpiBento), findsOneWidget);
        expect(find.byType(PremiumBottomNavDock), findsOneWidget);
        expect(find.textContaining('FIGMA'), findsNothing);
        expect(find.textContaining('phase_a'), findsNothing);
        expect(find.textContaining('UI v2 active'), findsNothing);
      });
    }

    testWidgets('dock each tab selected · iPhone 14', (tester) async {
      const size = Size(390, 844);
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      const items = [
        AdaptiveNavItem(Icons.space_dashboard_rounded, ProductLabels.consultantHome),
        AdaptiveNavItem(Icons.call_rounded, ProductLabels.myCalls),
        AdaptiveNavItem(Icons.people_rounded, ProductLabels.myCustomers),
        AdaptiveNavItem(Icons.task_alt_rounded, ProductLabels.myTasks),
        AdaptiveNavItem(Icons.apps_rounded, ProductLabels.consultantMore),
      ];

      for (var i = 0; i < items.length; i++) {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.dark(),
            home: MediaQuery(
              data: MediaQueryData(
                size: size,
                padding: const EdgeInsets.only(bottom: 34),
              ),
              child: Scaffold(
                bottomNavigationBar: PremiumBottomNavDock(
                  items: items,
                  selectedIndex: i,
                  onTap: (_) {},
                ),
              ),
            ),
          ),
        );
        await tester.pump();
        expect(tester.takeException(), isNull);
      }
    });
  });
}
