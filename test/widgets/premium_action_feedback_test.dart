import 'package:emlakmaster_mobile/core/theme/app_theme.dart';
import 'package:emlakmaster_mobile/widgets/premium/premium_action_feedback.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('showPremiumComingSoon presents sheet without throwing', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () async {
                  await showPremiumComingSoon(
                    context,
                    title: 'Test özelliği',
                  );
                },
                child: const Text('Aç'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Aç'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(tester.takeException(), isNull);
    expect(find.byType(ModalBarrier), findsOneWidget);
  });
}
