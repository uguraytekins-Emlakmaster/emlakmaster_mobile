import 'package:emlakmaster_mobile/core/theme/app_theme.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/widgets/call_identity_quick_actions_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  testWidgets(
    'call identity quick actions sheet has no overflow on small screen',
    (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 568));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp.router(
            theme: AppTheme.dark(),
            routerConfig: GoRouter(
              routes: [
                GoRoute(
                  path: '/',
                  builder: (context, state) => Scaffold(
                    body: Center(
                      child: TextButton(
                        onPressed: () => showCallIdentityQuickActionsSheet(
                          context,
                          rawPhone: '+905361234567',
                          displayLabel: 'Test Kişi',
                          firestoreCallDocId: 'call_doc_1',
                        ),
                        child: const Text('Aç'),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      await tester.tap(find.text('Aç'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('CRM\'de Ara'), findsOneWidget);
      expect(find.text('Geri arama kuyruğu'), findsOneWidget);
      expect(find.text('Görüşme ekranı'), findsOneWidget);
    },
  );

  testWidgets(
    'call identity quick actions sheet tolerates large text scale',
    (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 568));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(1.3)),
          child: ProviderScope(
            child: MaterialApp.router(
              theme: AppTheme.dark(),
              routerConfig: GoRouter(
                routes: [
                  GoRoute(
                    path: '/',
                    builder: (context, state) => Scaffold(
                      body: Center(
                        child: TextButton(
                          onPressed: () => showCallIdentityQuickActionsSheet(
                            context,
                            rawPhone: '+905361234567',
                            displayLabel: 'Test Kişi',
                            firestoreCallDocId: 'call_doc_1',
                          ),
                          child: const Text('Aç'),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Aç'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('CRM\'de Ara'), findsOneWidget);
    },
  );
}
