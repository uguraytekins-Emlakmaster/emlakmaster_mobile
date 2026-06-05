import 'dart:io';
import 'dart:ui' as ui;

import 'package:emlakmaster_mobile/core/navigation/shell_tab_back_host.dart';
import 'package:emlakmaster_mobile/core/theme/app_theme.dart';
import 'package:emlakmaster_mobile/features/crm_customers/domain/customer_heat_score.dart';
import 'package:emlakmaster_mobile/features/resurrection_engine/domain/entities/resurrection_segment.dart';
import 'package:emlakmaster_mobile/features/resurrection_engine/presentation/workspace/follow_up_workspace_snapshot.dart';
import 'package:emlakmaster_mobile/features/resurrection_engine/presentation/workspace/follow_up_workspace_types.dart';
import 'package:emlakmaster_mobile/features/resurrection_engine/presentation/workspace/providers/follow_up_workspace_provider.dart';
import 'package:emlakmaster_mobile/features/resurrection_engine/presentation/workspace/widgets/follow_up_workspace_row.dart';
import 'package:emlakmaster_mobile/features/resurrection_engine/presentation/workspace/widgets/follow_up_workspace_surface.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _proofDir = 'build/screenshots/screen28_consultant_followups';
const _phone = Size(390, 844);
const _boundary = Key('follow_up_workspace_proof');

FollowUpWorkspaceSnapshot _fullSnapshot() {
  final now = DateTime(2024, 6, 15, 12);
  return computeFollowUpWorkspaceSnapshot(
    [
      ResurrectionQueueItem(
        customerId: 'c1',
        customerName: 'Ahmet Yılmaz',
        primaryPhone: '+905551111111',
        segment: ResurrectionSegment.silent14,
        daysSilent: 14,
        lastInteractionAt: now.subtract(const Duration(days: 14)),
        nextSuggestedAction: 'Geri ara',
        heatLevel: CustomerHeatLevel.hot,
      ),
      ResurrectionQueueItem(
        customerId: 'c2',
        customerName: 'Ayşe Demir',
        primaryPhone: '+905552222222',
        segment: ResurrectionSegment.silent7,
        daysSilent: 7,
        lastInteractionAt: now.subtract(const Duration(days: 7)),
        lastCallSummary: 'Teklif bekliyor',
      ),
      ResurrectionQueueItem(
        customerId: 'c3',
        customerName: 'Mehmet Kaya',
        segment: ResurrectionSegment.silent30,
        daysSilent: 32,
        heatLevel: CustomerHeatLevel.cold,
      ),
    ],
    now: now,
  );
}

FollowUpWorkspaceSnapshot _emptySnapshot() =>
    computeFollowUpWorkspaceSnapshot([], now: DateTime(2024, 6, 15));

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
  required FollowUpWorkspaceSnapshot snapshot,
}) async {
  tester.view.physicalSize = _phone;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        followUpWorkspaceSnapshotProvider.overrideWithValue(
          AsyncValue.data(snapshot),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.dark(),
        home: const RepaintBoundary(
          key: _boundary,
          child: ShellTabBackHost(
            pageIndex: 5,
            child: Scaffold(body: FollowUpWorkspaceSurface()),
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

  testWidgets('02 followup rows proof', (tester) async {
    await _pump(tester, snapshot: _fullSnapshot());
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -220));
    await tester.pump();
    await _savePng(tester, '02_followup_rows.png');
  });

  testWidgets('03 actions proof', (tester) async {
    await _pump(tester, snapshot: _fullSnapshot());
    await tester.tap(find.byType(PopupMenuButton<FollowUpRowMenu>).first);
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
