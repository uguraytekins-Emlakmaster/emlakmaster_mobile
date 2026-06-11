import 'dart:io';
import 'dart:ui' as ui;

import 'package:emlakmaster_mobile/core/copy/product_labels.dart';
import 'package:emlakmaster_mobile/core/theme/app_theme.dart';
import 'package:emlakmaster_mobile/core/widgets/command_palette.dart';
import 'package:emlakmaster_mobile/features/auth/domain/entities/app_role.dart';
import 'package:emlakmaster_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _proofDir = 'build/screenshots/screen22_navigation';
const _phone = Size(390, 844);
const _boundary = Key('palette_proof');

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

Future<void> _openPalette(
  WidgetTester tester, {
  required AppRole role,
  String? query,
  Size size = _phone,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        currentUserProvider.overrideWith((ref) => Stream.value(null)),
        displayRoleOrNullProvider.overrideWithValue(role),
      ],
      child: MaterialApp(
        theme: AppTheme.light(),
        builder: (context, child) =>
            RepaintBoundary(key: _boundary, child: child),
        home: Scaffold(
          body: Center(
            child: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => CommandPalette.show(context),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();

  if (query != null) {
    await tester.enterText(find.byType(TextField), query);
    await tester.pumpAndSettle();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('01 admin komut yüzeyi — gerçek rotalar', (tester) async {
    await _openPalette(tester, role: AppRole.brokerOwner);
    // Admin yüzeyleri görünür.
    expect(find.text(ProductLabels.officeDesk), findsOneWidget);
    expect(find.text(ProductLabels.warRoom), findsOneWidget);
    expect(find.text(ProductLabels.callCenter), findsOneWidget);
    // Müşteri/danışman sekmesi yok.
    expect(find.text(ProductLabels.favorites), findsNothing);
    await _savePng(tester, '01_command_surface_or_routes.png');
  });

  testWidgets('02 danışman kısayolları', (tester) async {
    await _openPalette(tester, role: AppRole.agent);
    expect(find.text(ProductLabels.myCustomers), findsOneWidget);
    expect(find.text(ProductLabels.myCalls), findsOneWidget);
    // Admin alanı yok (dürüst omission).
    expect(find.text(ProductLabels.officeDesk), findsNothing);
    expect(find.text(ProductLabels.warRoom), findsNothing);
    await _savePng(tester, '02_actions_or_shortcuts.png');
  });

  testWidgets('04 boş / eşleşmesiz durum', (tester) async {
    // Guest rolü: müşteri arama yetkisi yok → sorgu eşleşmeyince tertemiz boş
    // (canlı müşteri sorgusu tetiklenmez).
    await _openPalette(tester, role: AppRole.guest, query: 'zzzz_yok');
    expect(find.text(ProductLabels.officeDesk), findsNothing);
    await _savePng(tester, '04_empty_or_no_access_state.png');
  });

  testWidgets('05 alt güvenli alan', (tester) async {
    await _openPalette(tester, role: AppRole.brokerOwner);
    expect(find.text(ProductLabels.settings), findsOneWidget);
    await _savePng(tester, '05_bottom_safe_area.png');
  });
}
