import 'package:firebase_core/firebase_core.dart';
import 'package:emlakmaster_mobile/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    try {
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: 'test-key',
          appId: '1:test:test',
          messagingSenderId: 'test',
          projectId: 'test-project',
          storageBucket: 'test-project.appspot.com',
        ),
      );
    } catch (_) {
      // Zaten başlatılmışsa (örn. başka test) devam et
    }
  });

  testWidgets('App smoke test: launches and shows shell', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: EmlakMasterApp(),
      ),
    );
    await tester.pumpAndSettle(const Duration(seconds: 5));
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
