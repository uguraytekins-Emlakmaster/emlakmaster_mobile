import 'package:emlakmaster_mobile/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App smoke test: launches and shows shell', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: EmlakMasterApp(),
      ),
    );
    await tester.pumpAndSettle(const Duration(seconds: 3));
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
