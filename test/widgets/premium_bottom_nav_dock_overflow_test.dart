import 'package:emlakmaster_mobile/core/copy/product_labels.dart';
import 'package:emlakmaster_mobile/core/layout/adaptive_shell_scaffold.dart';
import 'package:emlakmaster_mobile/core/theme/app_theme.dart';
import 'package:emlakmaster_mobile/widgets/premium/premium_bottom_nav_dock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final consultantNavItems = ConsultantShellPage_navItemsForTest();

  Future<void> pumpDock(
    WidgetTester tester, {
    required Size size,
    required double textScale,
    int selectedIndex = 0,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        home: MediaQuery(
          data: MediaQueryData(
            size: size,
            textScaler: TextScaler.linear(textScale),
            padding: EdgeInsets.only(bottom: size.height > 700 ? 34 : 0),
          ),
          child: Scaffold(
            body: const SizedBox.expand(),
            bottomNavigationBar: PremiumBottomNavDock(
              items: consultantNavItems,
              selectedIndex: selectedIndex,
              onTap: (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
  }

  group('PremiumBottomNavDock overflow audit', () {
    testWidgets('iPhone SE width · textScale 1.0', (tester) async {
      await pumpDock(
        tester,
        size: const Size(320, 568),
        textScale: 1.0,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('iPhone 14 width · textScale 1.0', (tester) async {
      await pumpDock(
        tester,
        size: const Size(390, 844),
        textScale: 1.0,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('iPhone 14 Pro Max · textScale 1.3', (tester) async {
      await pumpDock(
        tester,
        size: const Size(428, 926),
        textScale: 1.3,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('large phone · textScale 1.5', (tester) async {
      await pumpDock(
        tester,
        size: const Size(428, 926),
        textScale: 1.5,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('Android compact · textScale 1.0', (tester) async {
      await pumpDock(
        tester,
        size: const Size(360, 640),
        textScale: 1.0,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('Android normal · textScale 1.0', (tester) async {
      await pumpDock(
        tester,
        size: const Size(412, 915),
        textScale: 1.0,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('macOS window width · textScale 1.0', (tester) async {
      await pumpDock(
        tester,
        size: const Size(1280, 800),
        textScale: 1.0,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('iPad tablet · textScale 1.0', (tester) async {
      await pumpDock(
        tester,
        size: const Size(834, 1194),
        textScale: 1.0,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('large tablet · textScale 1.15', (tester) async {
      await pumpDock(
        tester,
        size: const Size(1024, 1366),
        textScale: 1.15,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('each tab selected · no overflow', (tester) async {
      for (var i = 0; i < consultantNavItems.length; i++) {
        await pumpDock(
          tester,
          size: const Size(390, 844),
          textScale: 1.2,
          selectedIndex: i,
        );
        expect(tester.takeException(), isNull);
      }
    });
  });
}

/// Mirrors [ConsultantShellPage] nav labels without importing shell (avoids heavy deps).
List<AdaptiveNavItem> ConsultantShellPage_navItemsForTest() => const [
  AdaptiveNavItem(Icons.space_dashboard_rounded, ProductLabels.consultantHome),
  AdaptiveNavItem(Icons.call_rounded, ProductLabels.myCalls),
  AdaptiveNavItem(Icons.people_rounded, ProductLabels.myCustomers),
  AdaptiveNavItem(Icons.task_alt_rounded, ProductLabels.myTasks),
  AdaptiveNavItem(Icons.apps_rounded, ProductLabels.consultantMore),
];
