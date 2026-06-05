import 'package:emlakmaster_mobile/core/theme/app_theme.dart';
import 'package:emlakmaster_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:emlakmaster_mobile/features/client_portal/presentation/requests/request_center_snapshot.dart';
import 'package:emlakmaster_mobile/features/client_portal/presentation/requests/providers/request_center_provider.dart';
import 'package:emlakmaster_mobile/features/client_portal/presentation/requests/widgets/request_center_chrome.dart';
import 'package:emlakmaster_mobile/features/client_portal/presentation/requests/widgets/request_center_surface.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pumpAt(WidgetTester tester, Size size,
    {bool signedIn = true}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        currentUserProvider.overrideWith((ref) => Stream.value(null)),
        requestCenterSnapshotProvider.overrideWith(
          (ref) => AsyncValue.data(
            computeRequestCenterSnapshot(
              signedIn: signedIn,
              displayName: signedIn ? 'Ada' : null,
            ),
          ),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.light(),
        home: const Scaffold(body: RequestCenterSurface()),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  const profiles = <String, Size>{
    'iPhone SE': Size(320, 568),
    'iPhone 14/15': Size(390, 844),
    'iPhone Pro Max': Size(430, 932),
    'Android compact': Size(360, 740),
    'Android normal': Size(412, 915),
    'tablet': Size(768, 1024),
    'macOS window': Size(1024, 768),
  };

  profiles.forEach((name, size) {
    testWidgets('overflow yok — $name', (tester) async {
      await _pumpAt(tester, size);
      expect(tester.takeException(), isNull);
    });
  });

  testWidgets('dar ekranda başlık + durum chip taşmaz', (tester) async {
    await _pumpAt(tester, const Size(320, 700));
    expect(find.text('Danışmana ulaş'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('filtre seçimi (Yakında) listeyi daraltır', (tester) async {
    await _pumpAt(tester, const Size(390, 844));
    // 'Yakında' birden fazla yerde (özet + durum çipi) görünür; yalnızca
    // filtre şeridindeki çipi hedefle.
    await tester.tap(
      find.descendant(
        of: find.byType(RequestCenterFilterStrip),
        matching: find.text('Yakında'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Talep oluştur'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('signedOut profilde de overflow yok', (tester) async {
    await _pumpAt(tester, const Size(360, 640), signedIn: false);
    expect(tester.takeException(), isNull);
  });
}
