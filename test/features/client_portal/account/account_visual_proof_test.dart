import 'dart:io';
import 'dart:ui' as ui;

import 'package:emlakmaster_mobile/core/theme/app_theme.dart';
import 'package:emlakmaster_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:emlakmaster_mobile/features/client_portal/presentation/account/account_snapshot.dart';
import 'package:emlakmaster_mobile/features/client_portal/presentation/account/account_types.dart';
import 'package:emlakmaster_mobile/features/client_portal/presentation/account/providers/account_provider.dart';
import 'package:emlakmaster_mobile/features/client_portal/presentation/account/widgets/account_row.dart';
import 'package:emlakmaster_mobile/features/client_portal/presentation/account/widgets/account_surface.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _proofDir = 'build/screenshots/screen24_client_profile';
const _phone = Size(390, 844);
const _boundary = Key('account_proof');

AccountSnapshot _full() => computeAccountSnapshot(
      signedIn: true,
      email: 'musteri@example.com',
      displayName: 'Ada Yılmaz',
      phone: '+90 555 111 22 33',
      memberSinceLabel: '15.01.2024',
      emailVerified: true,
      appVersion: '1.0.0',
    );

AccountSnapshot _signedOut() => computeAccountSnapshot(
      signedIn: false,
      emailVerified: false,
      appVersion: '1.0.0',
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
  required AccountSnapshot snapshot,
  Size size = _phone,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        currentUserProvider.overrideWith((ref) => Stream.value(null)),
        accountSnapshotProvider.overrideWithValue(AsyncValue.data(snapshot)),
      ],
      child: MaterialApp(
        theme: AppTheme.light(),
        home: const RepaintBoundary(
          key: _boundary,
          child: Scaffold(body: AccountSurface()),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('01 header summary sections proof', (tester) async {
    await _pump(tester, snapshot: _full());
    await _savePng(tester, '01_header_summary_sections.png');
  });

  testWidgets('02 profile rows proof', (tester) async {
    await _pump(tester, snapshot: _full());
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -220));
    await tester.pump();
    await _savePng(tester, '02_profile_rows.png');
  });

  testWidgets('03 actions proof (detay sheet)', (tester) async {
    await _pump(tester, snapshot: _full());
    await tester.tap(find.byType(AccountRow).first);
    await tester.pumpAndSettle();
    await _savePng(tester, '03_actions.png');
  });

  testWidgets('04 empty or partial state proof', (tester) async {
    // Oturumsuz: bloklu hesap + dürüst yer tutucular.
    await _pump(tester, snapshot: _signedOut());
    await _savePng(tester, '04_empty_or_partial_state.png');
  });

  testWidgets('05 bottom safe area proof', (tester) async {
    await _pump(tester, snapshot: _full());
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -1400));
    await tester.pump();
    await _savePng(tester, '05_bottom_safe_area.png');
  });
}
