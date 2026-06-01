import 'dart:io';
import 'dart:ui' as ui;

import 'package:emlakmaster_mobile/core/theme/app_theme.dart';
import 'package:emlakmaster_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:emlakmaster_mobile/features/consultant_daily/presentation/providers/consultant_daily_provider.dart';
import 'package:emlakmaster_mobile/features/consultant_daily/presentation/utils/consultant_daily_types.dart';
import 'package:emlakmaster_mobile/features/consultant_daily/presentation/widgets/consultant_daily_surface.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '_daily_test_fixtures.dart';

const _proofDir = 'build/screenshots/screen21_visual_spectacle_final';
const _phone = Size(390, 844);
const _boundary = Key('daily_cockpit_proof');

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
  required ConsultantDailySnapshot snapshot,
  Size size = _phone,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        currentUserProvider.overrideWith((ref) => Stream.value(null)),
        consultantDailySnapshotProvider
            .overrideWith((ref) => AsyncValue.data(snapshot)),
      ],
      child: MaterialApp(
        theme: AppTheme.light(),
        home: RepaintBoundary(
          key: _boundary,
          child: const Scaffold(body: ConsultantDailySurface()),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('01 header hero proof', (tester) async {
    await _pump(tester, snapshot: dailyFixtureSnapshot());
    await _savePng(tester, '01_header_hero.png');
  });

  testWidgets('02 summary filters proof', (tester) async {
    await _pump(tester, snapshot: dailyFixtureSnapshot());
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -140));
    await tester.pump();
    await _savePng(tester, '02_summary_filters.png');
  });

  testWidgets('03 priority rows proof', (tester) async {
    await _pump(tester, snapshot: dailyFixtureSnapshot());
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -360));
    await tester.pump();
    await _savePng(tester, '03_priority_rows.png');
  });

  testWidgets('04 low pressure or empty proof', (tester) async {
    await _pump(tester, snapshot: dailyEmptySnapshot());
    await _savePng(tester, '04_low_pressure_or_empty.png');
  });

  testWidgets('05 bottom safe area proof', (tester) async {
    await _pump(tester, snapshot: dailyFixtureSnapshot());
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -1600));
    await tester.pump();
    await _savePng(tester, '05_bottom_safe_area.png');
  });
}
