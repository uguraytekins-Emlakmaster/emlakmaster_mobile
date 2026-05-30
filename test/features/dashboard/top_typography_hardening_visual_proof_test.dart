import 'dart:io';
import 'dart:ui' as ui;

import 'package:emlakmaster_mobile/core/copy/product_labels.dart';
import 'package:emlakmaster_mobile/core/theme/app_theme.dart';
import 'package:emlakmaster_mobile/features/dashboard/presentation/admin_command/admin_command_tokens.dart';
import 'package:emlakmaster_mobile/features/dashboard/presentation/admin_command/utils/admin_office_health_summary.dart';
import 'package:emlakmaster_mobile/features/dashboard/presentation/admin_command/widgets/admin_command_chrome.dart';
import 'package:emlakmaster_mobile/features/war_room/presentation/widgets/war_room_intervention_surface.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

const _proofDir = 'build/screenshots/top_typography_hardening';
const _phone390 = Size(390, 844);
const _phone430 = Size(430, 932);
const _se = Size(320, 568);

const _summary = AdminOfficeHealthSummary(
  activeAdvisors: 5,
  openTasks: 11,
  liveCalls: 2,
  missedCalls: 3,
  officeAlerts: 4,
  escalations: 2,
  criticalEscalations: 1,
  followUpQueue: 6,
  setupPending: 1,
  syncRisk: 2,
);

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

Future<void> _pumpTop(
  WidgetTester tester, {
  required Key captureKey,
  required Widget child,
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
            child: RepaintBoundary(
              key: captureKey,
              child: child,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
}

Widget _adminTopStack() {
  return Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      PremiumAdminCommandHeader(
        title: ProductLabels.managerHome,
        subtitle: 'Ofis sağlığı · ekip aktivitesi · operasyon kontrolü',
        actions: [
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
      ),
      PremiumAdminHealthStrip(summary: _summary),
      PremiumAdminIntelLines(
        recentLine: 'Son 24 saat: 3 yeni müşteri · 2 randevu onayı',
        criticalLine: '1 kritik taşıma bekliyor',
      ),
    ],
  );
}

Widget _warRoomTopStack() {
  return Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const PremiumWarRoomHeader(),
      WarRoomCrisisStrip(summary: _summary),
    ],
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('top typography hardening proofs', () {
    testWidgets('01 admin top · 390', (tester) async {
      const key = Key('admin_top_390');
      await _pumpTop(
        tester,
        captureKey: key,
        child: _adminTopStack(),
        size: _phone390,
      );
      expect(tester.takeException(), isNull);
      await _savePng(tester, key, '01_admin_top_before_after_or_final.png');
    });

    testWidgets('admin top compact widths no overflow', (tester) async {
      for (final size in [_se, _phone390, _phone430]) {
        await _pumpTop(
          tester,
          captureKey: Key('admin_${size.width}'),
          child: _adminTopStack(),
          size: size,
        );
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('02 war room top · 390', (tester) async {
      const key = Key('war_top_390');
      await _pumpTop(
        tester,
        captureKey: key,
        child: _warRoomTopStack(),
        size: _phone390,
      );
      expect(tester.takeException(), isNull);
      await _savePng(tester, key, '02_war_room_top_before_after_or_final.png');
    });

    testWidgets('war room top compact widths no overflow', (tester) async {
      for (final size in [_se, _phone390, _phone430]) {
        await _pumpTop(
          tester,
          captureKey: Key('war_${size.width}'),
          child: _warRoomTopStack(),
          size: size,
        );
        expect(tester.takeException(), isNull);
      }
    });
  });
}
