import 'dart:io';
import 'dart:ui' as ui;

import 'package:emlakmaster_mobile/core/navigation/shell_tab_back_host.dart';
import 'package:emlakmaster_mobile/core/theme/app_theme.dart';
import 'package:emlakmaster_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:emlakmaster_mobile/features/crm_customers/domain/customer_heat_score.dart';
import 'package:emlakmaster_mobile/features/crm_customers/presentation/workspace/customer_workspace_snapshot.dart';
import 'package:emlakmaster_mobile/features/crm_customers/presentation/workspace/customer_workspace_types.dart';
import 'package:emlakmaster_mobile/features/crm_customers/presentation/workspace/providers/customer_workspace_provider.dart';
import 'package:emlakmaster_mobile/features/crm_customers/presentation/workspace/widgets/customer_workspace_row.dart';
import 'package:emlakmaster_mobile/features/crm_customers/presentation/workspace/widgets/customer_workspace_surface.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _proofDir = 'build/screenshots/screen25_consultant_customers';
const _phone = Size(390, 844);
const _boundary = Key('customer_workspace_proof');

CustomerWorkspaceSnapshot _fullSnapshot() {
  final now = DateTime(2024, 6, 15, 12);
  return computeCustomerWorkspaceSnapshot(
    [
      CustomerWorkspaceInput(
        id: 'c1',
        name: 'Ahmet Yılmaz',
        phone: '+905321112233',
        heatLevel: CustomerHeatLevel.hot,
        heatScore: 82,
        heatReason: 'Yüksek ilgi · son temas yakın',
        lastInteractionAt: now.subtract(const Duration(days: 1)),
        createdAt: DateTime(2024, 1, 1),
        updatedAt: now.subtract(const Duration(days: 1)),
        nextSuggestedAction: 'Tekrar ara',
        callablePhone: true,
        syncRisk: false,
        isDemo: false,
      ),
      CustomerWorkspaceInput(
        id: 'c2',
        name: 'Ayşe Demir',
        phone: '+905559998877',
        heatLevel: CustomerHeatLevel.warm,
        heatScore: 55,
        heatReason: 'Takip için uygun',
        lastInteractionAt: now.subtract(const Duration(days: 5)),
        createdAt: DateTime(2024, 3, 1),
        updatedAt: now.subtract(const Duration(days: 5)),
        callablePhone: true,
        syncRisk: true,
        isDemo: false,
      ),
      CustomerWorkspaceInput(
        id: 'c3',
        name: 'Mehmet Kaya',
        phone: '+905331234567',
        heatLevel: CustomerHeatLevel.cold,
        heatScore: 12,
        heatReason: 'Henüz yeterli sinyal yok',
        lastInteractionAt: now.subtract(const Duration(days: 20)),
        createdAt: DateTime(2024, 2, 1),
        updatedAt: now.subtract(const Duration(days: 20)),
        callablePhone: true,
        syncRisk: false,
        isDemo: false,
      ),
    ],
    now: now,
  );
}

CustomerWorkspaceSnapshot _emptySnapshot() =>
    computeCustomerWorkspaceSnapshot([], now: DateTime(2024, 6, 15));

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
  required CustomerWorkspaceSnapshot snapshot,
}) async {
  tester.view.physicalSize = _phone;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        currentUserProvider.overrideWith((ref) => Stream.value(null)),
        customerWorkspaceSnapshotProvider.overrideWithValue(
          AsyncValue.data(snapshot),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.dark(),
        home: const RepaintBoundary(
          key: _boundary,
          child: ShellTabBackHost(
            pageIndex: 3,
            child: Scaffold(body: CustomerWorkspaceSurface()),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('01 header summary filters proof', (tester) async {
    await _pump(tester, snapshot: _fullSnapshot());
    await _savePng(tester, '01_header_summary_filters.png');
  });

  testWidgets('02 customer rows proof', (tester) async {
    await _pump(tester, snapshot: _fullSnapshot());
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -180));
    await tester.pump();
    await _savePng(tester, '02_customer_rows.png');
  });

  testWidgets('03 actions proof (aksiyon menüsü)', (tester) async {
    await _pump(tester, snapshot: _fullSnapshot());
    await tester.tap(find.byType(PopupMenuButton<CustomerRowMenu>).first);
    await tester.pumpAndSettle();
    await _savePng(tester, '03_actions.png');
  });

  testWidgets('04 empty or partial state proof', (tester) async {
    await _pump(tester, snapshot: _emptySnapshot());
    await _savePng(tester, '04_empty_or_partial_state.png');
  });

  testWidgets('05 bottom safe area proof', (tester) async {
    await _pump(tester, snapshot: _fullSnapshot());
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -1200));
    await tester.pump();
    await _savePng(tester, '05_bottom_safe_area.png');
  });
}
