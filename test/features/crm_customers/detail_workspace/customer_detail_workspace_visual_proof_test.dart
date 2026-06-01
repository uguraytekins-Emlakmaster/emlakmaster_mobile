import 'dart:io';
import 'dart:ui' as ui;

import 'package:emlakmaster_mobile/core/theme/app_theme.dart';
import 'package:emlakmaster_mobile/features/crm_customers/presentation/detail_workspace/customer_detail_workspace_snapshot.dart';
import 'package:emlakmaster_mobile/features/crm_customers/presentation/detail_workspace/customer_detail_workspace_types.dart';
import 'package:emlakmaster_mobile/features/crm_customers/presentation/detail_workspace/providers/customer_detail_workspace_provider.dart';
import 'package:emlakmaster_mobile/features/crm_customers/presentation/detail_workspace/widgets/customer_detail_workspace_surface.dart';
import 'package:emlakmaster_mobile/features/crm_customers/presentation/pages/customer_detail_page.dart';
import 'package:emlakmaster_mobile/shared/models/customer_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

const _proofDir = 'build/screenshots/screen30_customer_detail';
const _phone = Size(390, 844);
const _boundary = Key('customer_detail_workspace_proof');

CustomerDetailWorkspaceSnapshot _fullSnapshot() {
  return computeCustomerDetailWorkspaceSnapshot(
    CustomerDetailWorkspaceInput(
      customerId: 'c1',
      entity: CustomerEntity(
        id: 'c1',
        fullName: 'Ayşe Demir',
        primaryPhone: '+905552222222',
        email: 'ayse@example.com',
        customerType: CustomerType.residential,
        lifecycleStage: LifecycleStage.qualified,
        lastInteractionAt: DateTime(2024, 6, 8),
        lastCallSummary: 'Portföy ilgisi var',
        nextSuggestedAction: 'Yarın geri ara',
        callsCount: 4,
        regionPreferences: const ['Kadıköy', 'Moda'],
        createdAt: DateTime(2024, 3, 1),
        updatedAt: DateTime(2024, 6, 15),
      ),
      openTasks: const [
        CustomerDetailLinkedRow(
          id: 't1',
          title: 'Teklif gönder',
          statusLabel: 'Bugün',
        ),
        CustomerDetailLinkedRow(
          id: 't2',
          title: 'Randevu hatırlat',
          statusLabel: 'Açık',
        ),
      ],
      matchedListings: const [
        CustomerDetailListingRow(
          listingId: 'l1',
          title: 'Satılık Daire — Moda',
        ),
      ],
      now: DateTime(2024, 6, 15, 12),
    ),
  );
}

CustomerDetailWorkspaceSnapshot _emptySnapshot() =>
    computeCustomerDetailWorkspaceSnapshot(
      CustomerDetailWorkspaceInput(
        customerId: 'missing',
        entity: null,
        now: DateTime(2024, 6, 15),
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
  required CustomerDetailWorkspaceSnapshot snapshot,
}) async {
  tester.view.physicalSize = _phone;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        customerDetailWorkspaceSnapshotProvider('c1').overrideWithValue(
          AsyncValue.data(snapshot),
        ),
      ],
      child: MaterialApp.router(
        theme: AppTheme.dark(),
        routerConfig: GoRouter(
          routes: [
            GoRoute(
              path: '/',
              builder: (_, __) => const RepaintBoundary(
                key: _boundary,
                child: CustomerDetailPage(customerId: 'c1'),
              ),
            ),
          ],
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('01 header summary actions proof', (tester) async {
    await _pump(tester, snapshot: _fullSnapshot());
    await _savePng(tester, '01_header_summary_actions.png');
  });

  testWidgets('02 detail sections proof', (tester) async {
    await _pump(tester, snapshot: _fullSnapshot());
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -280));
    await tester.pump();
    await _savePng(tester, '02_detail_sections.png');
  });

  testWidgets('03 actions proof', (tester) async {
    await _pump(tester, snapshot: _fullSnapshot());
    await tester.tap(find.byTooltip('Detay'));
    await tester.pumpAndSettle();
    await _savePng(tester, '03_actions.png');
  });

  testWidgets('04 empty or partial state proof', (tester) async {
    await _pump(tester, snapshot: _emptySnapshot());
    await _savePng(tester, '04_empty_or_partial_state.png');
  });

  testWidgets('05 bottom safe area proof', (tester) async {
    await _pump(tester, snapshot: _fullSnapshot());
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -900));
    await tester.pump();
    await _savePng(tester, '05_bottom_safe_area.png');
  });
}
