import 'dart:io';
import 'dart:ui' as ui;

import 'package:emlakmaster_mobile/core/copy/product_labels.dart';
import 'package:emlakmaster_mobile/core/layout/adaptive_shell_scaffold.dart';
import 'package:emlakmaster_mobile/core/theme/app_theme.dart';
import 'package:emlakmaster_mobile/features/tasks/presentation/models/task_list_row_snapshot.dart';
import 'package:emlakmaster_mobile/features/tasks/presentation/utils/task_list_filter.dart';
import 'package:emlakmaster_mobile/features/tasks/presentation/widgets/consultant_tasks_chrome.dart';
import 'package:emlakmaster_mobile/features/tasks/presentation/widgets/task_card.dart';
import 'package:emlakmaster_mobile/features/tasks/presentation/widgets/task_list_row_quick_actions.dart';
import 'package:emlakmaster_mobile/widgets/premium/premium_bottom_nav_dock.dart';
import 'package:emlakmaster_mobile/widgets/premium/premium_ui_kit.dart';
import 'package:emlakmaster_mobile/widgets/premium/v2/premium_shell_chrome.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _proofDir = 'build/screenshots/screen4_tasks';
const _size = Size(390, 844);
const _pixelRatio = 3.0;

Future<void> _savePng(WidgetTester tester, Key key, String name) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(find.byKey(key));
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: _pixelRatio);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    expect(bytes, isNotNull);
    final dir = Directory(_proofDir);
    if (!dir.existsSync()) dir.createSync(recursive: true);
    final path = '$_proofDir/$name';
    await File(path).writeAsBytes(bytes!.buffer.asUint8List());
    expect(File(path).lengthSync(), greaterThan(800));
  });
}

Future<void> _pumpFrame(
  WidgetTester tester, {
  required Key captureKey,
  required Widget child,
  double height = 520,
}) async {
  tester.view.physicalSize = _size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.dark(),
      home: MediaQuery(
        data: MediaQueryData(
          size: _size,
          padding: const EdgeInsets.only(top: 47, bottom: 34),
        ),
        child: Material(
          color: const Color(0xFF0A0E1A),
          child: Center(
            child: SizedBox(
              width: _size.width,
              height: height,
              child: RepaintBoundary(
                key: captureKey,
                child: child,
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

TaskListRowSnapshot _row(TaskDueStatus status, {String label = 'Bugün'}) =>
    TaskListRowSnapshot(
      dueStatus: status,
      dueLabel: label,
      hasRecurrence: status == TaskDueStatus.upcoming,
      recurrenceLabel: status == TaskDueStatus.upcoming ? 'Her hafta' : null,
    );

Widget _taskCard({
  required String title,
  required TaskDueStatus status,
  bool done = false,
  String? customerId,
}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: TaskCard(
      taskId: 'proof_${title.hashCode}',
      title: title,
      done: done,
      row: _row(status, label: status == TaskDueStatus.overdue ? '2 gün gecikti' : 'Bugün'),
      customerId: customerId,
      onComplete: () {},
      onPostpone: done ? null : () {},
      onOpenCustomer: customerId != null ? () {} : null,
      onEdit: () {},
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('01 — header summary filters proof', (tester) async {
    const key = Key('proof_header');
    await _pumpFrame(
      tester,
      captureKey: key,
      height: 248,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const PremiumTasksPageHeader(
            title: 'Görevlerim',
            subtitle: 'Ajanda, takip ve hatırlatmalar — tek ekran.',
          ),
          PremiumTasksSummaryStrip(
            summary: const TaskListSummary(
              open: 5,
              today: 2,
              overdue: 1,
              upcoming: 2,
              completed: 4,
              total: 9,
            ),
          ),
          PremiumTaskFilterStrip(
            selected: TaskListFilter.today,
            onSelected: (_) {},
          ),
        ],
      ),
    );
    await _savePng(tester, key, '01_header_summary_filters.png');
    expect(find.text('Görevlerim'), findsOneWidget);
    expect(find.text('Bugün'), findsWidgets);
    expect(find.text('DEV'), findsNothing);
  });

  testWidgets('02 — task list rows proof', (tester) async {
    const key = Key('proof_rows');
    await _pumpFrame(
      tester,
      captureKey: key,
      height: 520,
      child: ProviderScope(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _taskCard(
                title: 'Müşteriyi ara — Ayşe Demir',
                status: TaskDueStatus.today,
                customerId: 'c1',
              ),
              _taskCard(
                title: 'Portföy sunumu hazırla',
                status: TaskDueStatus.overdue,
              ),
              _taskCard(
                title: 'Sözleşme takibi',
                status: TaskDueStatus.upcoming,
                customerId: 'c2',
              ),
              _taskCard(
                title: 'Haftalık rapor',
                status: TaskDueStatus.completed,
                done: true,
              ),
            ],
          ),
        ),
      ),
    );
    await _savePng(tester, key, '02_task_list_rows.png');
    expect(find.text('Müşteriyi ara — Ayşe Demir'), findsOneWidget);
  });

  testWidgets('03 — task actions proof', (tester) async {
    const key = Key('proof_actions');
    await _pumpFrame(
      tester,
      captureKey: key,
      height: 160,
      child: ProviderScope(
        child: _taskCard(
          title: 'Takip araması — Mehmet Kaya',
          status: TaskDueStatus.today,
          customerId: 'c3',
        ),
      ),
    );
    await _savePng(tester, key, '03_task_actions.png');
    expect(find.byType(TaskListRowQuickActions), findsOneWidget);
    expect(find.byIcon(Icons.check_circle_outline_rounded), findsOneWidget);
    expect(find.byIcon(Icons.snooze_rounded), findsOneWidget);
  });

  testWidgets('04 — empty state proof', (tester) async {
    const key = Key('proof_empty');
    await _pumpFrame(
      tester,
      captureKey: key,
      height: 420,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const PremiumTasksPageHeader(
              title: ProductLabels.myTasks,
              subtitle: 'Ajanda, takip ve hatırlatmalar — tek ekran.',
            ),
            PremiumTasksSummaryStrip(summary: TaskListSummary.empty),
            PremiumEmptyState(
              icon: Icons.task_alt_rounded,
              title: 'Henüz görev yok',
              subtitle: 'Takip ve hatırlatmalarınız burada görünür.',
              actionLabel: 'İlk görevi ekle',
              onAction: () {},
            ),
          ],
        ),
      ),
    );
    await _savePng(tester, key, '04_empty_state.png');
    expect(find.text('Henüz görev yok'), findsOneWidget);
  });

  testWidgets('05 — bottom nav safe area proof', (tester) async {
    const key = Key('proof_nav');
    await _pumpFrame(
      tester,
      captureKey: key,
      height: _size.height,
      child: Scaffold(
        backgroundColor: const Color(0xFF0A0E1A),
        body: const PremiumShellBackdrop(
          child: PremiumTasksPageHeader(
            title: ProductLabels.myTasks,
            subtitle: 'Ajanda, takip ve hatırlatmalar — tek ekran.',
          ),
        ),
        bottomNavigationBar: PremiumBottomNavDock(
          items: const [
            AdaptiveNavItem(
              Icons.space_dashboard_rounded,
              ProductLabels.consultantHome,
            ),
            AdaptiveNavItem(Icons.call_rounded, ProductLabels.myCalls),
            AdaptiveNavItem(Icons.people_rounded, ProductLabels.myCustomers),
            AdaptiveNavItem(Icons.task_alt_rounded, ProductLabels.myTasks),
            AdaptiveNavItem(Icons.apps_rounded, ProductLabels.consultantMore),
          ],
          selectedIndex: 3,
          onTap: (_) {},
        ),
      ),
    );
    await _savePng(tester, key, '05_bottom_nav_safe_area.png');
    expect(find.text(ProductLabels.myTasks), findsWidgets);
  });
}
