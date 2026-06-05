import 'dart:io';
import 'dart:ui' as ui;

import 'package:emlakmaster_mobile/core/navigation/shell_tab_back_host.dart';
import 'package:emlakmaster_mobile/core/theme/app_theme.dart';
import 'package:emlakmaster_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:emlakmaster_mobile/features/tasks/presentation/workspace/tasks_workspace_snapshot.dart';
import 'package:emlakmaster_mobile/features/tasks/presentation/workspace/tasks_workspace_types.dart';
import 'package:emlakmaster_mobile/features/tasks/presentation/workspace/providers/tasks_workspace_provider.dart';
import 'package:emlakmaster_mobile/features/tasks/presentation/workspace/widgets/tasks_workspace_row.dart';
import 'package:emlakmaster_mobile/features/tasks/presentation/workspace/widgets/tasks_workspace_surface.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _ProofAuthUser implements User {
  _ProofAuthUser(this.uid);
  @override
  final String uid;
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

const _proofDir = 'build/screenshots/screen27_consultant_tasks';
const _phone = Size(390, 844);
const _boundary = Key('tasks_workspace_proof');

TasksWorkspaceSnapshot _fullSnapshot() {
  final now = DateTime(2024, 6, 15, 12);
  return computeTasksWorkspaceSnapshot(
    [
      TaskWorkspaceInput(
        id: 't1',
        title: 'Müşteriyi geri ara',
        done: false,
        dueAt: now.subtract(const Duration(days: 1)),
        customerId: 'c1',
        customerName: 'Ahmet Yılmaz',
        callablePhone: true,
        rawData: {
          'title': 'Müşteriyi geri ara',
          'done': false,
          'customerId': 'c1',
        },
      ),
      TaskWorkspaceInput(
        id: 't2',
        title: 'Teklif gönder',
        done: false,
        dueAt: now,
        customerId: 'c2',
        customerName: 'Ayşe Demir',
        callablePhone: false,
        rawData: {'title': 'Teklif gönder', 'done': false},
      ),
      TaskWorkspaceInput(
        id: 't3',
        title: 'Portföy güncelle',
        done: false,
        dueAt: now.add(const Duration(days: 3)),
        callablePhone: false,
        rawData: {'title': 'Portföy güncelle', 'done': false},
      ),
    ],
    now: now,
  );
}

TasksWorkspaceSnapshot _emptySnapshot() =>
    computeTasksWorkspaceSnapshot([], now: DateTime(2024, 6, 15));

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
  required TasksWorkspaceSnapshot snapshot,
}) async {
  tester.view.physicalSize = _phone;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        currentUserProvider.overrideWith(
          (ref) => Stream.value(_ProofAuthUser('test-uid')),
        ),
        tasksWorkspaceSnapshotProvider.overrideWithValue(
          AsyncValue.data(snapshot.copyWith(uid: 'test-uid')),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.dark(),
        home: const RepaintBoundary(
          key: _boundary,
          child: ShellTabBackHost(
            pageIndex: 6,
            child: Scaffold(body: TasksWorkspaceSurface()),
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

  testWidgets('02 task rows proof', (tester) async {
    await _pump(tester, snapshot: _fullSnapshot());
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -220));
    await tester.pump();
    await _savePng(tester, '02_task_rows.png');
  });

  testWidgets('03 actions proof', (tester) async {
    await _pump(tester, snapshot: _fullSnapshot());
    await tester.tap(find.byType(PopupMenuButton<TaskRowMenu>).first);
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
