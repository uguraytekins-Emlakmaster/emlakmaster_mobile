import 'package:emlakmaster_mobile/shared/widgets/error_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('ErrorState shows message and no button when onRetry is null', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ErrorState(message: 'Test hata mesajı'),
        ),
      ),
    );
    expect(find.text('Test hata mesajı'), findsOneWidget);
    expect(find.text('Tekrar Dene'), findsNothing);
  });

  testWidgets('ErrorState shows Tekrar Dene button when onRetry is provided', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ErrorState(
            message: 'Hata',
            onRetry: () {},
          ),
        ),
      ),
    );
    expect(find.text('Tekrar Dene'), findsOneWidget);
  });
}
