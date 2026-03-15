import 'package:emlakmaster_mobile/shared/widgets/unauthorized_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('UnauthorizedScreen shows message and back button', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: UnauthorizedScreen(
          message: 'Test yetkisiz mesajı',
        ),
      ),
    );
    expect(find.text('Yetkisiz Erişim'), findsOneWidget);
    expect(find.text('Test yetkisiz mesajı'), findsOneWidget);
    expect(find.text('Ana Sayfaya Dön'), findsOneWidget);
  });
}
