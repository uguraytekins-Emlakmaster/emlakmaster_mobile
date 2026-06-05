// ignore_for_file: prefer_const_constructors

import 'dart:io';
import 'dart:ui' as ui;

import 'package:emlakmaster_mobile/core/theme/app_theme.dart';
import 'package:emlakmaster_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:emlakmaster_mobile/features/client_portal/presentation/engagement/client_engagement_snapshot.dart';
import 'package:emlakmaster_mobile/features/client_portal/presentation/engagement/client_engagement_types.dart';
import 'package:emlakmaster_mobile/features/client_portal/presentation/engagement/providers/client_engagement_provider.dart';
import 'package:emlakmaster_mobile/features/client_portal/presentation/engagement/widgets/client_engagement_surface.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _proofDir = 'build/screenshots/screen20_client_activity';
const _phone = Size(390, 844);
const _boundary = Key('engagement_proof');

ClientEngagementSnapshot _full() => computeClientEngagementSnapshot(
      signedIn: true,
      displayName: 'Ada',
      previewPortfolioCount: 8,
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
  required ClientEngagementSnapshot snapshot,
  Size size = _phone,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        currentUserProvider.overrideWith((ref) => Stream.value(null)),
        clientEngagementSnapshotProvider
            .overrideWith((ref) => AsyncValue.data(snapshot)),
      ],
      child: MaterialApp(
        theme: AppTheme.light(),
        home: RepaintBoundary(
          key: _boundary,
          child: const Scaffold(body: ClientEngagementSurface()),
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

  testWidgets('02 activity rows proof', (tester) async {
    await _pump(tester, snapshot: _full());
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -220));
    await tester.pump();
    await _savePng(tester, '02_activity_rows.png');
  });

  testWidgets('03 actions proof', (tester) async {
    await _pump(tester, snapshot: _full());
    await tester.tap(find.byIcon(Icons.more_horiz_rounded).first);
    await tester.pumpAndSettle();
    await _savePng(tester, '03_actions.png');
  });

  testWidgets('04 empty or partial state proof', (tester) async {
    // Dürüst kısmi durum: "İlgi geçmişi henüz sunucuda tutulmuyor" şeridi.
    await _pump(tester, snapshot: _full());
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -520));
    await tester.pump();
    await _savePng(tester, '04_empty_or_partial_state.png');
  });

  testWidgets('05 bottom safe area proof', (tester) async {
    await _pump(tester, snapshot: _full());
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -1200));
    await tester.pump();
    await _savePng(tester, '05_bottom_safe_area.png');
  });
}
