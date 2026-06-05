import 'package:emlakmaster_mobile/core/theme/app_theme.dart';
import 'package:emlakmaster_mobile/features/tasks/presentation/models/task_list_row_snapshot.dart';
import 'package:emlakmaster_mobile/features/tasks/presentation/utils/task_list_filter.dart';
import 'package:emlakmaster_mobile/features/tasks/presentation/widgets/consultant_tasks_chrome.dart';
import 'package:emlakmaster_mobile/features/tasks/presentation/widgets/task_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _profiles = <({String name, Size size, double textScale})>[
  (name: 'iPhone SE', size: Size(320, 568), textScale: 1.0),
  (name: 'iPhone 14', size: Size(390, 844), textScale: 1.0),
  (name: 'iPhone 15 Pro', size: Size(393, 852), textScale: 1.15),
  (name: 'Android compact', size: Size(360, 640), textScale: 1.0),
  (name: 'Android normal', size: Size(412, 915), textScale: 1.0),
  (name: 'macOS windowed', size: Size(1280, 800), textScale: 1.0),
  (name: 'iPad tablet', size: Size(834, 1194), textScale: 1.0),
  (name: 'large tablet', size: Size(1024, 1366), textScale: 1.1),
];

TaskListRowSnapshot _row(TaskDueStatus status) => TaskListRowSnapshot(
      dueStatus: status,
      dueLabel: 'Bugün',
      hasRecurrence: false,
    );

Future<void> _pumpChrome(WidgetTester tester, Size size, double textScale) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        theme: AppTheme.dark(),
        home: MediaQuery(
          data: MediaQueryData(
            size: size,
            textScaler: TextScaler.linear(textScale),
            padding: EdgeInsets.only(bottom: size.height > 700 ? 34 : 0),
          ),
          child: Scaffold(
            body: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const PremiumTasksPageHeader(
                    title: 'Görevlerim',
                    subtitle: 'Ajanda, takip ve hatırlatmalar — tek ekran.',
                  ),
                  PremiumTasksSummaryStrip(
                    summary: const TaskListSummary(
                      open: 4,
                      today: 2,
                      overdue: 1,
                      upcoming: 1,
                      completed: 3,
                      total: 7,
                    ),
                  ),
                  PremiumTaskFilterStrip(
                    selected: TaskListFilter.today,
                    onSelected: (_) {},
                  ),
                  TaskCard(
                    taskId: 't1',
                    title: 'Müşteriyi ara — Ayşe Demir',
                    done: false,
                    row: _row(TaskDueStatus.today),
                    customerId: 'c1',
                    onComplete: () {},
                    onPostpone: () {},
                    onOpenCustomer: () {},
                    onEdit: () {},
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
}

void main() {
  group('Consultant Tasks Phase C overflow zero', () {
    for (final profile in _profiles) {
      testWidgets('chrome + dense row · ${profile.name}', (tester) async {
        await _pumpChrome(tester, profile.size, profile.textScale);
        expect(tester.takeException(), isNull);
      });
    }
  });
}
