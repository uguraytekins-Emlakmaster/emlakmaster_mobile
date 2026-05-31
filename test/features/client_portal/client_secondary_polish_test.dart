import 'dart:io';
import 'dart:ui' as ui;

import 'package:emlakmaster_mobile/core/copy/product_labels.dart';
import 'package:emlakmaster_mobile/core/layout/adaptive_shell_scaffold.dart';
import 'package:emlakmaster_mobile/core/theme/app_theme.dart';
import 'package:emlakmaster_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:emlakmaster_mobile/features/client_portal/presentation/pages/client_portal_messages_page.dart';
import 'package:emlakmaster_mobile/features/client_portal/presentation/pages/client_portal_profile_page.dart';
import 'package:emlakmaster_mobile/features/client_portal/presentation/pages/client_portal_virtual_tours_page.dart';
import 'package:emlakmaster_mobile/widgets/premium/premium_ui_kit.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _proofDir = 'build/screenshots/client_secondary_polish';
const _phoneSize = Size(390, 844);
const _pixelRatio = 3.0;

Future<void> _savePng(WidgetTester tester, Key key, String name) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(find.byKey(key));
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: _pixelRatio);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    expect(bytes, isNotNull);
    final dir = Directory(_proofDir);
    if (!dir.existsSync()) dir.createSync(recursive: true);
    final path = '$_proofDir/$name';
    await File(path).writeAsBytes(bytes!.buffer.asUint8List());
    expect(File(path).lengthSync(), greaterThan(800));
  });
}

Future<void> _pumpFrame(
  WidgetTester tester, {
  required Key captureKey,
  required Widget child,
  Size size = _phoneSize,
  double? height,
  List<Override>? overrides,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides ?? const [],
      child: MaterialApp(
        theme: AppTheme.dark(),
        home: MediaQuery(
          data: MediaQueryData(
            size: size,
            padding: const EdgeInsets.only(top: 47, bottom: 34),
          ),
          child: Material(
            color: const Color(0xFF0A0E1A),
            child: Center(
              child: SizedBox(
                width: size.width,
                height: height ?? size.height,
                child: RepaintBoundary(
                  key: captureKey,
                  child: child,
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

Widget _clientDock({required Widget body, int selectedIndex = 2}) {
  return Scaffold(
    backgroundColor: const Color(0xFF0A0E1A),
    body: body,
    bottomNavigationBar: PremiumBottomNavDock(
      items: const [
        AdaptiveNavItem(Icons.search_rounded, 'Keşfet'),
        AdaptiveNavItem(Icons.favorite_rounded, ProductLabels.favorites),
        AdaptiveNavItem(Icons.chat_rounded, ProductLabels.messages),
        AdaptiveNavItem(Icons.video_camera_back_rounded, ProductLabels.virtualTour),
        AdaptiveNavItem(Icons.person_rounded, ProductLabels.profile),
      ],
      selectedIndex: selectedIndex,
      onTap: (_) {},
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('01 — messages polished proof', (tester) async {
    const key = Key('proof_messages');
    await _pumpFrame(
      tester,
      captureKey: key,
      height: _phoneSize.height,
      child: const ClientPortalMessagesPage(),
    );
    await _savePng(tester, key, '01_messages_polished.png');
    expect(find.text('İletişim'), findsOneWidget);
    expect(find.text('WhatsApp ile yazın'), findsOneWidget);
    expect(find.text('En hızlı kanal'), findsOneWidget);
  });

  testWidgets('02 — virtual tours polished proof', (tester) async {
    const key = Key('proof_tours');
    await _pumpFrame(
      tester,
      captureKey: key,
      height: _phoneSize.height,
      child: const ClientPortalVirtualToursPage(),
    );
    await _savePng(tester, key, '02_virtual_tours_polished.png');
    expect(find.text('Sanal tur'), findsOneWidget);
    expect(find.text('Örnek daire turu'), findsOneWidget);
    expect(find.textContaining('Harici'), findsWidgets);
  });

  testWidgets('03 — profile polished proof', (tester) async {
    const key = Key('proof_profile');
    await _pumpFrame(
      tester,
      captureKey: key,
      height: _phoneSize.height,
      overrides: [
        currentUserProvider.overrideWith(
          (ref) => Stream.value(
            FakeUser(
              uid: 'u1',
              email: 'musteri@example.com',
              displayName: 'Müşteri Test',
            ),
          ),
        ),
      ],
      child: const ClientPortalProfilePage(),
    );
    await _savePng(tester, key, '03_profile_polished.png');
    expect(find.text('Hesabım'), findsOneWidget);
    expect(find.text('KVKK & Gizlilik'), findsOneWidget);
    expect(find.text('Çıkış yap'), findsOneWidget);
  });

  testWidgets('04 — profile bottom safe area proof', (tester) async {
    const key = Key('proof_profile_dock');
    await _pumpFrame(
      tester,
      captureKey: key,
      height: _phoneSize.height,
      child: _clientDock(
        selectedIndex: 4,
        body: const ClientPortalProfilePage(),
      ),
    );
    await _savePng(tester, key, '04_profile_bottom_safe_area.png');
    expect(find.text('Profil'), findsWidgets);
  });

  testWidgets('no overflow on iPhone SE — secondary screens', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    for (final page in const [
      ClientPortalMessagesPage(),
      ClientPortalVirtualToursPage(),
      ClientPortalProfilePage(),
    ]) {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark(),
          home: ProviderScope(
            overrides: [
              currentUserProvider.overrideWith((ref) => Stream.value(null)),
            ],
            child: page,
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    }
  });
}

class FakeUser implements User {
  FakeUser({required this.uid, this.email, this.displayName});

  @override
  final String uid;

  @override
  final String? email;

  @override
  final String? displayName;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
