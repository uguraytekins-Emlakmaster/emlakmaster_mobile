import 'package:emlakmaster_mobile/core/theme/app_theme.dart';
import 'package:emlakmaster_mobile/shared/widgets/empty_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('EmptyState shows icon, title and optional subtitle and action',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        home: Scaffold(
          body: EmptyState(
            icon: Icons.people_rounded,
            title: 'Müşteri listesi',
            subtitle: 'Henüz kayıt yok.',
            actionLabel: 'Ekle',
            onAction: () {},
          ),
        ),
      ),
    );

    expect(find.text('Müşteri listesi'), findsOneWidget);
    expect(find.text('Henüz kayıt yok.'), findsOneWidget);
    expect(find.byIcon(Icons.people_rounded), findsOneWidget);
    expect(find.text('Ekle'), findsOneWidget);
  });

  testWidgets('EmptyState without subtitle or action', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        home: const Scaffold(
          body: EmptyState(
            icon: Icons.inbox_rounded,
            title: 'Boş',
          ),
        ),
      ),
    );

    expect(find.text('Boş'), findsOneWidget);
    expect(find.byType(FilledButton), findsNothing);
  });
}
