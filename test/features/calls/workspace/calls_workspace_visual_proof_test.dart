import 'dart:io';
import 'dart:ui' as ui;

import 'package:emlakmaster_mobile/core/navigation/shell_tab_back_host.dart';
import 'package:emlakmaster_mobile/core/theme/app_theme.dart';
import 'package:emlakmaster_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/workspace/calls_workspace_snapshot.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/workspace/calls_workspace_types.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/workspace/providers/calls_workspace_provider.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/workspace/widgets/calls_workspace_row.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/workspace/widgets/calls_workspace_surface.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _proofDir = 'build/screenshots/screen26_consultant_calls';
const _phone = Size(390, 844);
const _boundary = Key('calls_workspace_proof');

CallsWorkspaceSnapshot _fullSnapshot() {
  final now = DateTime(2024, 6, 15, 12);
  return computeCallsWorkspaceSnapshot(
    [
      CallWorkspaceInput(
        recordKey: 'fs_1',
        sourceKind: 'firestore',
        firestoreDocId: 'd1',
        rawPhone: '+905321112233',
        customerId: 'c1',
        customerFullName: 'Ahmet Yılmaz',
        isIncoming: false,
        durationSec: 95,
        outcomeCode: 'callback_scheduled',
        outcomeLabel: 'Tekrar aranacak',
        createdAt: now.subtract(const Duration(hours: 1)),
        isHandoffPending: false,
        hasCaptureCompleted: true,
        isLocalDraft: false,
      ),
      CallWorkspaceInput(
        recordKey: 'fs_2',
        sourceKind: 'firestore',
        firestoreDocId: 'd2',
        rawPhone: '+905559998877',
        contactDisplayName: 'Ayşe Demir',
        isIncoming: true,
        durationSec: 45,
        outcomeCode: 'reached',
        outcomeLabel: 'Ulaşıldı',
        createdAt: now.subtract(const Duration(hours: 5)),
        isHandoffPending: false,
        hasCaptureCompleted: true,
        isLocalDraft: false,
      ),
      CallWorkspaceInput(
        recordKey: 'fs_3',
        sourceKind: 'firestore',
        firestoreDocId: 'd3',
        rawPhone: '+905331234567',
        isIncoming: false,
        outcomeCode: 'missed',
        outcomeLabel: 'Cevapsız',
        createdAt: now.subtract(const Duration(days: 1)),
        isHandoffPending: false,
        hasCaptureCompleted: true,
        isLocalDraft: false,
      ),
    ],
    now: now,
  );
}

CallsWorkspaceSnapshot _emptySnapshot() =>
    computeCallsWorkspaceSnapshot([], now: DateTime(2024, 6, 15));

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
  required CallsWorkspaceSnapshot snapshot,
}) async {
  tester.view.physicalSize = _phone;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        currentUserProvider.overrideWith((ref) => Stream.value(null)),
        callsWorkspaceSnapshotProvider.overrideWithValue(
          AsyncValue.data(snapshot),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.dark(),
        home: const RepaintBoundary(
          key: _boundary,
          child: ShellTabBackHost(
            pageIndex: 2,
            child: Scaffold(body: CallsWorkspaceSurface()),
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

  testWidgets('02 call rows proof', (tester) async {
    await _pump(tester, snapshot: _fullSnapshot());
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -200));
    await tester.pump();
    await _savePng(tester, '02_call_rows.png');
  });

  testWidgets('03 actions proof (aksiyon menüsü)', (tester) async {
    await _pump(tester, snapshot: _fullSnapshot());
    await tester.tap(find.byType(PopupMenuButton<CallRowMenu>).first);
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
