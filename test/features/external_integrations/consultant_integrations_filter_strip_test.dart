import 'package:emlakmaster_mobile/core/theme/app_theme.dart';
import 'package:emlakmaster_mobile/features/external_integrations/presentation/utils/integration_center_filter.dart';
import 'package:emlakmaster_mobile/features/external_integrations/presentation/widgets/consultant_integrations_chrome.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('filter strip scrolls horizontally without overflow', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        home: Scaffold(
          body: PremiumIntegrationsFilterStrip(
            selected: IntegrationCenterFilter.all,
            onSelected: (_) {},
          ),
        ),
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('integration_filter_strip_scroll')), findsOneWidget);

    await tester.drag(
      find.byKey(const Key('integration_filter_strip_scroll')),
      const Offset(-420, 0),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
