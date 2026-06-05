import 'dart:io';
import 'dart:ui' as ui;

import 'package:emlakmaster_mobile/core/copy/product_labels.dart';
import 'package:emlakmaster_mobile/core/theme/app_theme.dart';
import 'package:emlakmaster_mobile/features/dashboard/presentation/admin_command/admin_command_tokens.dart';
import 'package:emlakmaster_mobile/features/dashboard/presentation/admin_command/widgets/admin_command_chrome.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

const _proofDir = 'build/screenshots/screen9_admin';

Future<void> _savePng(WidgetTester tester, Key key, String name) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(find.byKey(key));
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

Widget _headerWithActions() {
  return PremiumAdminCommandHeader(
    title: ProductLabels.managerHome,
    subtitle: 'Ofis sağlığı · ekip aktivitesi · operasyon kontrolü',
    actions: [
      CircleAvatar(
        radius: AdminCommandTokens.headerAvatarSize / 2,
        backgroundColor: const Color(0xFF2A3144),
        child: Icon(
          Icons.person_rounded,
          size: AdminCommandTokens.headerAvatarSize * 0.52,
          color: Colors.white70,
        ),
      ),
      IconButton(
        padding: EdgeInsets.zero,
        constraints: BoxConstraints(
          minWidth: AdminCommandTokens.headerActionTap,
          minHeight: AdminCommandTokens.headerActionTap,
        ),
        icon: Icon(
          Icons.notifications_outlined,
          size: AdminCommandTokens.headerActionIconSize,
          color: Colors.white70,
        ),
        onPressed: () {},
      ),
    ],
  );
}

Future<void> _pumpHeader(
  WidgetTester tester, {
  required Key captureKey,
  required Size size,
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
          child: SizedBox(
            width: size.width,
            height: size.height,
            child: Stack(
              children: [
                Positioned(
                  top: 47,
                  left: 0,
                  right: 0,
                  child: RepaintBoundary(
                    key: captureKey,
                    child: _headerWithActions(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('header mobile hardening proof · 390', (tester) async {
    const key = Key('header_390');
    const size = Size(390, 844);
    await _pumpHeader(tester, captureKey: key, size: size);

    final box = tester.renderObject<RenderBox>(
      find.byType(PremiumAdminCommandHeader),
    );
    final height = box.size.height;
    expect(height, greaterThan(96));
    expect(height, lessThan(138));
    expect(tester.takeException(), isNull);

    await _savePng(tester, key, '06_header_mobile_hardening_390.png');
  });

  testWidgets('header mobile hardening proof · 430', (tester) async {
    const key = Key('header_430');
    const size = Size(430, 932);
    await _pumpHeader(tester, captureKey: key, size: size);
    expect(tester.takeException(), isNull);
    await _savePng(tester, key, '06_header_mobile_hardening_430.png');
  });
}
