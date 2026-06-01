// ignore_for_file: prefer_const_constructors

import 'dart:io';
import 'dart:ui' as ui;

import 'package:emlakmaster_mobile/core/theme/app_theme.dart';
import 'package:emlakmaster_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:emlakmaster_mobile/features/client_portal/presentation/requests/request_center_snapshot.dart';
import 'package:emlakmaster_mobile/features/client_portal/presentation/requests/request_center_types.dart';
import 'package:emlakmaster_mobile/features/client_portal/presentation/requests/providers/request_center_provider.dart';
import 'package:emlakmaster_mobile/features/client_portal/presentation/requests/widgets/request_center_surface.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _proofDir = 'build/screenshots/screen23_client_requests';
const _phone = Size(390, 844);
const _boundary = Key('request_center_proof');

RequestCenterSnapshot _full() => computeRequestCenterSnapshot(
      signedIn: true,
      displayName: 'Ada',
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
  required RequestCenterSnapshot snapshot,
  Size size = _phone,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        currentUserProvider.overrideWith((ref) => Stream.value(null)),
        requestCenterSnapshotProvider
            .overrideWith((ref) => AsyncValue.data(snapshot)),
      ],
      child: MaterialApp(
        theme: AppTheme.light(),
        home: RepaintBoundary(
          key: _boundary,
          child: const Scaffold(body: RequestCenterSurface()),
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

  testWidgets('02 request rows proof', (tester) async {
    await _pump(tester, snapshot: _full());
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -180));
    await tester.pump();
    await _savePng(tester, '02_request_rows.png');
  });

  testWidgets('03 actions proof', (tester) async {
    await _pump(tester, snapshot: _full());
    await tester.tap(find.byIcon(Icons.more_horiz_rounded).first);
    await tester.pumpAndSettle();
    await _savePng(tester, '03_actions.png');
  });

  testWidgets('04 empty or partial state proof', (tester) async {
    // Dürüst kısmi durum: "Kayıtlı talepler henüz sunucuda tutulmuyor" şeridi.
    await _pump(tester, snapshot: _full());
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -420));
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
