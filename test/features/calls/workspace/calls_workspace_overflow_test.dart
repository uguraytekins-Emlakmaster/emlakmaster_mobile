import 'package:emlakmaster_mobile/core/theme/app_theme.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/workspace/calls_workspace_snapshot.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/workspace/calls_workspace_types.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/workspace/widgets/calls_workspace_chrome.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/workspace/widgets/calls_workspace_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _profiles = <({String name, Size size})>[
  (name: 'iPhone SE', size: Size(320, 568)),
  (name: 'iPhone 14', size: Size(390, 844)),
  (name: 'Android compact', size: Size(360, 640)),
  (name: 'Android normal', size: Size(412, 915)),
  (name: 'macOS windowed', size: Size(1280, 800)),
  (name: 'iPad tablet', size: Size(834, 1194)),
];

CallsWorkspaceSnapshot _snapshot() {
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
        createdAt: now.subtract(const Duration(days: 2)),
        isHandoffPending: false,
        hasCaptureCompleted: true,
        isLocalDraft: false,
      ),
    ],
    now: now,
  );
}

Future<void> _pumpRow(WidgetTester tester, CallRowView row, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.dark(),
      home: MediaQuery(
        data: MediaQueryData(
          size: size,
          textScaler: TextScaler.linear(1.0),
        ),
        child: Scaffold(
          body: SingleChildScrollView(
            child: CallsWorkspaceRow(
              row: row,
              onTap: () {},
              onCall: () {},
              onMenu: (_) {},
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final snap = _snapshot();

  for (final p in _profiles) {
    testWidgets('row overflow — ${p.name}', (tester) async {
      await _pumpRow(tester, snap.rows.first, p.size);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('summary strip taşma yok', (tester) async {
    for (final p in _profiles) {
      tester.view.physicalSize = p.size;
      tester.view.devicePixelRatio = 1;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark(),
          home: MediaQuery(
            data: MediaQueryData(size: p.size),
            child: Scaffold(
              body: CallsWorkspaceSummaryStrip(summary: _snapshot().summary),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('filter strip yatay kaydırma', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        home: const Scaffold(
          body: CallsWorkspaceFilterStrip(
            selected: CallsWorkspaceFilter.all,
            onSelected: _noop,
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Tümü'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

void _noop(CallsWorkspaceFilter _) {}
