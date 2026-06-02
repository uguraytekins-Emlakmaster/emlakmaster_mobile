import 'dart:io';
import 'dart:ui' as ui;

import 'package:emlakmaster_mobile/core/copy/product_labels.dart';
import 'package:emlakmaster_mobile/core/layout/adaptive_shell_scaffold.dart';
import 'package:emlakmaster_mobile/core/theme/app_theme.dart';
import 'package:emlakmaster_mobile/features/client_portal/presentation/messages/widgets/client_portal_messages_surface.dart';
import 'package:emlakmaster_mobile/widgets/premium/premium_ui_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

const _proofDir = 'build/screenshots/screen32_messages_wow';
const _phone = Size(390, 844);
const _boundary = Key('messages_wow_proof');

Future<void> _savePng(WidgetTester tester, String name) async {
  final boundary =
      tester.renderObject<RenderRepaintBoundary>(find.byKey(_boundary));
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 3);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    expect(bytes, isNotNull);
    final dir = Directory(_proofDir);
    if (!dir.existsSync()) dir.createSync(recursive: true);
    final path = '$_proofDir/$name';
    await File(path).writeAsBytes(bytes!.buffer.asUint8List());
    expect(File(path).lengthSync(), greaterThan(800));
  });
}

Future<void> _pump(
  WidgetTester tester, {
  Size size = _phone,
  Widget? bottomNav,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.dark(),
      home: MediaQuery(
        data: MediaQueryData(
          size: size,
          padding: const EdgeInsets.only(top: 47, bottom: 34),
        ),
        child: Material(
          color: const Color(0xFF0A0E1A),
          child: RepaintBoundary(
            key: _boundary,
            child: Scaffold(
              backgroundColor: const Color(0xFF0A0E1A),
              body: const SafeArea(child: ClientPortalMessagesSurface()),
              bottomNavigationBar: bottomNav,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

Widget _messagesDock() {
  return PremiumBottomNavDock(
    items: const [
      AdaptiveNavItem(Icons.search_rounded, 'Keşfet'),
      AdaptiveNavItem(Icons.favorite_rounded, ProductLabels.favorites),
      AdaptiveNavItem(Icons.chat_rounded, ProductLabels.messages),
      AdaptiveNavItem(Icons.video_camera_back_rounded, ProductLabels.virtualTour),
      AdaptiveNavItem(Icons.person_rounded, ProductLabels.profile),
    ],
    selectedIndex: 2,
    onTap: (_) {},
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('01 header trust proof', (tester) async {
    await _pump(tester);
    await _savePng(tester, '01_header_trust.png');
    expect(find.text('Mesajlar'), findsOneWidget);
    expect(find.textContaining('GÜVENLİ İLETİŞİM'), findsOneWidget);
  });

  testWidgets('02 channel cards proof', (tester) async {
    await _pump(tester);
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -220));
    await tester.pump();
    await _savePng(tester, '02_channel_cards.png');
    expect(find.text('WhatsApp ile yazın'), findsOneWidget);
    expect(find.text('Önerilen'), findsOneWidget);
  });

  testWidgets('03 actions proof', (tester) async {
    await _pump(tester);
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -340));
    await tester.pump();
    await _savePng(tester, '03_actions.png');
    expect(find.text('Telefon'), findsOneWidget);
    expect(find.text('E-posta'), findsOneWidget);
    expect(find.textContaining('Harici'), findsWidgets);
  });

  testWidgets('04 low data or empty proof', (tester) async {
    await _pump(tester);
    await _savePng(tester, '04_low_data_or_empty.png');
    expect(find.text('—'), findsOneWidget);
    expect(find.textContaining('Geçmiş saklanmaz'), findsWidgets);
  });

  testWidgets('05 bottom safe area proof', (tester) async {
    await _pump(tester, bottomNav: _messagesDock());
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -520));
    await tester.pump();
    await _savePng(tester, '05_bottom_safe_area.png');
    expect(find.text(ProductLabels.messages), findsWidgets);
  });
}
