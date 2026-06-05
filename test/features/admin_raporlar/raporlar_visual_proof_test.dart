// ignore_for_file: prefer_const_constructors

import 'dart:io';
import 'dart:ui' as ui;

import 'package:emlakmaster_mobile/core/theme/app_theme.dart';
import 'package:emlakmaster_mobile/features/admin_raporlar/presentation/providers/raporlar_snapshot_provider.dart';
import 'package:emlakmaster_mobile/features/admin_raporlar/presentation/utils/raporlar_snapshot.dart';
import 'package:emlakmaster_mobile/features/admin_raporlar/presentation/utils/raporlar_types.dart';
import 'package:emlakmaster_mobile/features/admin_raporlar/presentation/widgets/raporlar_command_surface.dart';
import 'package:emlakmaster_mobile/features/auth/domain/entities/app_role.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _proofDir = 'build/screenshots/screen19_reports_hub';
const _phone = Size(390, 844);
const _boundary = Key('reports_proof');

RaporlarSnapshot _full() => computeRaporlarSnapshot(
      role: AppRole.brokerOwner,
      signals: const RaporlarGroundedSignals(
        teamsCount: 6,
        officeKnown: true,
        officePendingInvites: 4,
        officeIntervention: 2,
        connectionKnown: true,
        connectionIntervention: 1,
        connectionReady: 3,
      ),
    );

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
  required RaporlarSnapshot snapshot,
  Size size = _phone,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        raporlarSnapshotProvider
            .overrideWith((ref) => AsyncValue.data(snapshot)),
      ],
      child: MaterialApp(
        theme: AppTheme.light(),
        home: RepaintBoundary(
          key: _boundary,
          child: const Scaffold(body: RaporlarCommandSurface()),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('01 header summary filters proof', (tester) async {
    await _pump(tester, snapshot: _full());
    await _savePng(tester, '01_header_summary_filters.png');
  });

  testWidgets('02 report rows proof', (tester) async {
    await _pump(tester, snapshot: _full());
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -260));
    await tester.pump();
    await _savePng(tester, '02_report_rows.png');
  });

  testWidgets('03 actions proof', (tester) async {
    await _pump(tester, snapshot: _full());
    await tester.tap(find.byIcon(Icons.more_horiz_rounded).first);
    await tester.pumpAndSettle();
    await _savePng(tester, '03_actions.png');
  });

  testWidgets('04 empty or partial state proof', (tester) async {
    await _pump(
      tester,
      snapshot: computeRaporlarSnapshot(role: AppRole.guest),
    );
    await _savePng(tester, '04_empty_or_partial_state.png');
  });

  testWidgets('05 bottom safe area proof', (tester) async {
    await _pump(tester, snapshot: _full());
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -1200));
    await tester.pump();
    await _savePng(tester, '05_bottom_safe_area.png');
  });
}
