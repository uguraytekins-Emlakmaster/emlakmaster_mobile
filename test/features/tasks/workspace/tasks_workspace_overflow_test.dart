import 'package:emlakmaster_mobile/core/theme/app_theme.dart';
import 'package:emlakmaster_mobile/features/tasks/presentation/workspace/tasks_workspace_snapshot.dart';
import 'package:emlakmaster_mobile/features/tasks/presentation/workspace/tasks_workspace_types.dart';
import 'package:emlakmaster_mobile/features/tasks/presentation/workspace/widgets/tasks_workspace_chrome.dart';
import 'package:emlakmaster_mobile/features/tasks/presentation/workspace/widgets/tasks_workspace_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _profiles = <({String name, Size size})>[
  (name: 'iPhone SE', size: Size(320, 568)),
  (name: 'iPhone 14', size: Size(390, 844)),
  (name: 'Android compact', size: Size(360, 640)),
  (name: 'macOS', size: Size(1280, 800)),
];

TaskRowView _row() {
  final snap = computeTasksWorkspaceSnapshot(
    [
      TaskWorkspaceInput(
        id: 't1',
        title: 'Uzun görev başlığı — müşteri takibi ve teklif hazırlığı',
        done: false,
        dueAt: DateTime(2024, 6, 15),
        customerId: 'c1',
        customerName: 'Ahmet Yılmaz',
        callablePhone: false,
        rawData: const {'title': 'Test', 'done': false},
      ),
    ],
    now: DateTime(2024, 6, 15, 12),
  );
  return snap.rows.first;
}

Future<void> _pumpRow(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.dark(),
      home: MediaQuery(
        data: MediaQueryData(size: size),
        child: Scaffold(
          body: TasksWorkspaceRow(
            row: _row(),
            onTap: () {},
            onComplete: () {},
            onMenu: (_) {},
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final p in _profiles) {
    testWidgets('row overflow — ${p.name}', (tester) async {
      await _pumpRow(tester, p.size);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('summary strip', (tester) async {
    final snap = computeTasksWorkspaceSnapshot(
      [
        TaskWorkspaceInput(
          id: 't1',
          title: 'A',
          done: false,
          dueAt: DateTime(2024, 6, 15),
          callablePhone: false,
          rawData: const {},
        ),
      ],
      now: DateTime(2024, 6, 15),
    );
    tester.view.physicalSize = const Size(320, 568);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        home: Scaffold(
          body: TasksWorkspaceSummaryStrip(summary: snap.summary),
        ),
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
