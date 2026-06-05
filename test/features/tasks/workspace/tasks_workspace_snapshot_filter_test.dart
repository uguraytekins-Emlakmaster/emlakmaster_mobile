import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emlakmaster_mobile/features/tasks/presentation/workspace/tasks_workspace_filter.dart';
import 'package:emlakmaster_mobile/features/tasks/presentation/workspace/tasks_workspace_snapshot.dart';
import 'package:emlakmaster_mobile/features/tasks/presentation/workspace/tasks_workspace_types.dart';
import 'package:flutter_test/flutter_test.dart';

final _now = DateTime(2024, 6, 15, 12);

TaskWorkspaceInput _input({
  String id = 't1',
  String title = 'Müşteriyi ara',
  bool done = false,
  DateTime? dueAt,
  String? customerId,
  String? customerName,
}) =>
    TaskWorkspaceInput(
      id: id,
      title: title,
      done: done,
      dueAt: dueAt,
      customerId: customerId,
      customerName: customerName,
      callablePhone: false,
      rawData: {
        'title': title,
        'done': done,
        if (dueAt != null) 'dueAt': Timestamp.fromDate(dueAt),
        if (customerId != null) 'customerId': customerId,
      },
    );

void main() {
  group('computeTasksWorkspaceSnapshot', () {
    test('summary gerçek sayımlar', () {
      final snap = computeTasksWorkspaceSnapshot(
        [
          _input(id: 'active', dueAt: _now.add(const Duration(days: 2))),
          _input(
            id: 'over',
            dueAt: _now.subtract(const Duration(days: 1)),
          ),
          _input(id: 'today', dueAt: _now),
          _input(
            id: 'match',
            customerId: 'c1',
            customerName: 'Ada',
            dueAt: _now,
          ),
          _input(id: 'done', done: true, dueAt: _now),
        ],
        now: _now,
      );
      expect(snap.summary.active, 4);
      expect(snap.summary.overdue, 1);
      expect(snap.summary.today, greaterThanOrEqualTo(1));
      expect(snap.summary.matched, 1);
    });

    test('geciken üst sıralama', () {
      final snap = computeTasksWorkspaceSnapshot(
        [
          _input(id: 'later', dueAt: _now.add(const Duration(days: 3))),
          _input(id: 'over', dueAt: _now.subtract(const Duration(days: 2))),
        ],
        now: _now,
      );
      expect(snap.rows.first.id, 'over');
    });

    test('coverageNote dürüst — AI yok', () {
      final snap = computeTasksWorkspaceSnapshot([_input()], now: _now);
      expect(snap.coverageNote, contains('yapay zekâ'));
    });

    test('kısmi — vade yok', () {
      final snap = computeTasksWorkspaceSnapshot(
        [_input(title: 'X', dueAt: null)],
        now: _now,
      );
      expect(snap.rows.single.isPartial, isTrue);
    });
  });

  group('filterTasksWorkspaceRows', () {
    late TasksWorkspaceSnapshot snap;

    setUp(() {
      snap = computeTasksWorkspaceSnapshot(
        [
          _input(id: 'over', dueAt: _now.subtract(const Duration(days: 1))),
          _input(id: 'today', dueAt: _now),
          _input(id: 'done', done: true, dueAt: _now),
          _input(
            id: 'match',
            customerId: 'c1',
            customerName: 'Ada',
            dueAt: _now.add(const Duration(days: 1)),
          ),
        ],
        now: _now,
      );
    });

    test('geciken filtresi', () {
      final out = filterTasksWorkspaceRows(
        snap.rows,
        filter: TasksWorkspaceFilter.overdue,
      );
      expect(out.map((r) => r.id).toList(), ['over']);
    });

    test('öncelikli = geciken veya bugün', () {
      final out = filterTasksWorkspaceRows(
        snap.rows,
        filter: TasksWorkspaceFilter.priority,
      );
      expect(out.any((r) => r.id == 'over'), isTrue);
      expect(out.any((r) => r.id == 'today'), isTrue);
      expect(out.any((r) => r.id == 'done'), isFalse);
    });

    test('arama', () {
      final out = filterTasksWorkspaceRows(snap.rows, query: 'ada');
      expect(out.single.id, 'match');
    });
  });
}
