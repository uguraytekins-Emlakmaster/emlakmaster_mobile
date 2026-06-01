import 'package:emlakmaster_mobile/core/theme/app_theme.dart';
import 'package:emlakmaster_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:emlakmaster_mobile/features/consultant_daily/presentation/providers/consultant_daily_provider.dart';
import 'package:emlakmaster_mobile/features/consultant_daily/presentation/widgets/consultant_daily_chrome.dart';
import 'package:emlakmaster_mobile/features/consultant_daily/presentation/widgets/consultant_daily_surface.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '_daily_test_fixtures.dart';

const _devices = <String, Size>{
  'iPhone SE': Size(320, 568),
  'iPhone 14/15': Size(390, 844),
  'iPhone 15 Pro Max': Size(430, 932),
  'Android compact': Size(360, 640),
  'Android normal': Size(412, 915),
  'Tablet': Size(820, 1180),
  'macOS window': Size(1024, 768),
};

Future<void> _pumpAt(
  WidgetTester tester,
  Size size,
) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        currentUserProvider.overrideWith((ref) => Stream.value(null)),
        consultantDailySnapshotProvider
            .overrideWith((ref) => AsyncValue.data(dailyFixtureSnapshot())),
      ],
      child: MaterialApp(
        theme: AppTheme.light(),
        home: const Scaffold(body: ConsultantDailySurface()),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final entry in _devices.entries) {
    testWidgets('Benim Günüm zero overflow · ${entry.key}', (tester) async {
      await _pumpAt(tester, entry.value);
      expect(tester.takeException(), isNull);
      // Liste boyunca kaydırarak tüm satır/şeritleri zorla.
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -600));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('filtre seçimi listeyi daraltır', (tester) async {
    await _pumpAt(tester, const Size(390, 844));
    final chip = find.descendant(
      of: find.byType(ConsultantDailyFilterStrip),
      matching: find.text('Görev'),
    );
    expect(chip, findsOneWidget);
    await tester.tap(chip);
    await tester.pump();
    expect(tester.takeException(), isNull);
    // Bölüm başlığı Türkçe büyük harfe çevrilir.
    expect(find.text('SONUÇLAR'), findsOneWidget);
  });

  testWidgets('boş durum dürüst mesaj gösterir', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserProvider.overrideWith((ref) => Stream.value(null)),
          consultantDailySnapshotProvider
              .overrideWith((ref) => AsyncValue.data(dailyEmptySnapshot())),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const Scaffold(body: ConsultantDailySurface()),
        ),
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.textContaining('acil bir baskı yok'), findsOneWidget);
  });
}
