import 'package:emlakmaster_mobile/core/theme/app_theme.dart';
import 'package:emlakmaster_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:emlakmaster_mobile/features/client_portal/presentation/account/account_snapshot.dart';
import 'package:emlakmaster_mobile/features/client_portal/presentation/account/account_types.dart';
import 'package:emlakmaster_mobile/features/client_portal/presentation/account/providers/account_provider.dart';
import 'package:emlakmaster_mobile/features/client_portal/presentation/account/widgets/account_chrome.dart';
import 'package:emlakmaster_mobile/features/client_portal/presentation/account/widgets/account_surface.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

AccountSnapshot _snap({bool signedIn = true}) => computeAccountSnapshot(
      signedIn: signedIn,
      email: signedIn ? 'cokuzunbiradres.musteri@example-domain.com' : null,
      displayName: signedIn ? 'Ayşegül Çağlayangil Yıldırımoğlu' : null,
      phone: signedIn ? '+90 555 111 22 33' : null,
      memberSinceLabel: signedIn ? '15.01.2024' : null,
      emailVerified: signedIn,
      appVersion: '1.0.0',
    );

Future<void> _pumpAt(WidgetTester tester, Size size,
    {bool signedIn = true}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        currentUserProvider.overrideWith((ref) => Stream.value(null)),
        accountSnapshotProvider.overrideWithValue(
          AsyncValue.data(_snap(signedIn: signedIn)),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.light(),
        home: const Scaffold(body: AccountSurface()),
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

  testWidgets('uzun e-posta/ad + durum çipi dar ekranda taşmaz',
      (tester) async {
    await _pumpAt(tester, const Size(320, 700));
    expect(find.text('E-posta'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('kategori filtresi (Gizlilik) listeyi daraltır', (tester) async {
    // Geniş viewport: 6 yatay filtre çipi de görünür/oluşturulur (390'da
    // 'Gizlilik' tembel ListView'de ekran dışı kalıp dokunulamaz).
    await _pumpAt(tester, const Size(768, 1024));
    await tester.tap(
      find.descendant(
        of: find.byType(AccountFilterStrip),
        matching: find.text('Gizlilik'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('KVKK & Gizlilik'), findsOneWidget);
    // Hesap bölümü satırı (E-posta) artık görünmemeli.
    expect(find.text('E-posta'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('signedOut profilde de overflow yok', (tester) async {
    await _pumpAt(tester, const Size(360, 640), signedIn: false);
    expect(tester.takeException(), isNull);
  });
}
