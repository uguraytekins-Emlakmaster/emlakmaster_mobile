import 'package:emlakmaster_mobile/core/theme/app_theme.dart';
import 'package:emlakmaster_mobile/features/client_portal/presentation/pages/client_portal_messages_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('no overflow on iPhone SE — messages wow', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        home: const ClientPortalMessagesPage(),
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.text('Mesajlar'), findsOneWidget);
  });
}
