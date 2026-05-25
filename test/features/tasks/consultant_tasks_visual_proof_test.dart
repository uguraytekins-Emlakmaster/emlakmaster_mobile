import 'dart:io';
import 'dart:ui' as ui;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emlakmaster_mobile/core/copy/product_labels.dart';
import 'package:emlakmaster_mobile/core/layout/adaptive_shell_scaffold.dart';
import 'package:emlakmaster_mobile/core/l10n/app_localizations.dart';
import 'package:emlakmaster_mobile/core/theme/app_theme.dart';
import 'package:emlakmaster_mobile/core/theme/dashboard_layout_tokens.dart';
import 'package:emlakmaster_mobile/features/crm_customers/presentation/providers/customer_entity_provider.dart';
import 'package:emlakmaster_mobile/features/tasks/presentation/consultant_tasks_tokens.dart';
import 'package:emlakmaster_mobile/features/tasks/presentation/models/task_list_row_snapshot.dart';
import 'package:emlakmaster_mobile/features/tasks/presentation/utils/task_list_filter.dart';
import 'package:emlakmaster_mobile/features/tasks/presentation/widgets/consultant_tasks_chrome.dart';
import 'package:emlakmaster_mobile/features/tasks/presentation/widgets/task_card.dart';
import 'package:emlakmaster_mobile/features/tasks/presentation/widgets/task_list_row_quick_actions.dart';
import 'package:emlakmaster_mobile/shared/models/customer_models.dart';
import 'package:emlakmaster_mobile/widgets/premium/premium_ui_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_query_document_snapshot.dart';

const _proofDir = 'build/screenshots/screen4_tasks';
const _phoneSize = Size(390, 844);
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
  Size size = _phoneSize,
  double? height,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.dark(),
      home: MediaQuery(
        data: MediaQueryData(
          size: size,
          padding: const EdgeInsets.only(top: 47, bottom: 34),
        ),
        child: Material(
          color: const Color(0xFF0A0E1A),
          child: Center(
            child: SizedBox(
              width: size.width,
              height: height ?? size.height,
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

List<QueryDocumentSnapshot<Map<String, dynamic>>> _proofTaskDocs() {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  return [
    fakeQueryDocumentSnapshot('t1', {
      'title': 'Müşteriyi ara — Ayşe Demir',
      'done': false,
      'dueAt': Timestamp.fromDate(today),
      'customerId': 'c1',
      'advisorId': 'proof_advisor',
    }),
    fakeQueryDocumentSnapshot('t2', {
      'title': 'Portföy sunumu hazırla',
      'done': false,
      'dueAt': Timestamp.fromDate(today.subtract(const Duration(days: 2))),
      'advisorId': 'proof_advisor',
    }),
    fakeQueryDocumentSnapshot('t3', {
      'title': 'Sözleşme takibi',
      'done': false,
      'dueAt': Timestamp.fromDate(today.add(const Duration(days: 4))),
      'customerId': 'c2',
      'recurrence': 'weekly',
      'advisorId': 'proof_advisor',
    }),
    fakeQueryDocumentSnapshot('t4', {
      'title': 'Haftalık rapor gönder',
      'done': true,
      'dueAt': Timestamp.fromDate(today.subtract(const Duration(days: 1))),
      'advisorId': 'proof_advisor',
    }),
  ];
}

CustomerEntity _customer(String id, String name) => CustomerEntity(
      id: id,
      fullName: name,
      primaryPhone: '+905321112233',
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 6, 1),
    );

Widget _customerOverrides({required Widget child}) {
  return ProviderScope(
    overrides: [
      customerEntityByIdProvider.overrideWith((ref, id) {
        return Stream.value(switch (id) {
          'c1' => _customer('c1', 'Ayşe Demir'),
          'c2' => _customer('c2', 'Mehmet Kaya'),
          'c3' => _customer('c3', 'Zeynep Arslan'),
          _ => _customer(id, 'Müşteri'),
        });
      }),
    ],
    child: child,
  );
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
  String dueLabel = 'Bugün',
}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: TaskCard(
      taskId: 'proof_${title.hashCode}',
      title: title,
      done: done,
      row: _row(status, label: dueLabel),
      customerId: customerId,
      onComplete: () {},
      onPostpone: done ? null : () {},
      onOpenCustomer: customerId != null ? () {} : null,
      onEdit: () {},
    ),
  );
}

Widget _consultantShellDock({required int selectedIndex, required Widget body}) {
  return Scaffold(
    backgroundColor: const Color(0xFF0A0E1A),
    body: body,
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
      selectedIndex: selectedIndex,
      onTap: (_) {},
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('01 — header summary filters proof', (tester) async {
    const key = Key('proof_header');
    final docs = _proofTaskDocs();
    final summary = computeTaskListSummary(docs, DateTime.now());

    await _pumpFrame(
      tester,
      captureKey: key,
      size: const Size(520, 844),
      height: 272,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const PremiumTasksPageHeader(
            title: 'Görevlerim',
            subtitle: 'Ajanda, takip ve hatırlatmalar — tek ekran.',
          ),
          PremiumTasksSummaryStrip(summary: summary),
          PremiumTaskFilterStrip(
            selected: TaskListFilter.today,
            onSelected: (_) {},
          ),
        ],
      ),
    );
    await _savePng(tester, key, '01_header_summary_filters.png');
    for (final f in TaskListFilter.values) {
      expect(find.text(f.label), findsWidgets);
    }
    expect(find.byType(PremiumTaskFilterStrip), findsOneWidget);
    expect(find.text('Görevlerim'), findsOneWidget);
    expect(find.text('DEV'), findsNothing);
    expect(summary.open, greaterThan(0));
  });

  testWidgets('02 — task list rows proof', (tester) async {
    const key = Key('proof_rows');
    await _pumpFrame(
      tester,
      captureKey: key,
      height: 540,
      child: _customerOverrides(
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
                dueLabel: '2 gün gecikti',
              ),
              _taskCard(
                title: 'Sözleşme takibi',
                status: TaskDueStatus.upcoming,
                customerId: 'c2',
                dueLabel: '4 gün içinde',
              ),
              _taskCard(
                title: 'Haftalık rapor gönder',
                status: TaskDueStatus.completed,
                done: true,
                dueLabel: 'Tamamlandı',
              ),
            ],
          ),
        ),
      ),
    );
    await _savePng(tester, key, '02_task_list_rows.png');
    expect(find.text('Müşteriyi ara — Ayşe Demir'), findsOneWidget);
    expect(find.text('Geciken'), findsWidgets);
    expect(find.text('Ayşe Demir'), findsOneWidget);
    expect(find.text('DEV'), findsNothing);
  });

  testWidgets('03 — task actions proof', (tester) async {
    const key = Key('proof_actions');
    await _pumpFrame(
      tester,
      captureKey: key,
      height: 172,
      child: _customerOverrides(
        child: _taskCard(
          title: 'Takip araması — Zeynep Arslan',
          status: TaskDueStatus.today,
          customerId: 'c3',
        ),
      ),
    );
    await _savePng(tester, key, '03_task_actions.png');
    expect(find.byType(TaskListRowQuickActions), findsOneWidget);
    expect(find.byIcon(Icons.check_circle_outline_rounded), findsOneWidget);
    expect(find.byIcon(Icons.snooze_rounded), findsOneWidget);
    expect(find.byIcon(Icons.person_outline_rounded), findsOneWidget);
    expect(find.byIcon(Icons.edit_outlined), findsOneWidget);
    expect(find.text('Zeynep Arslan'), findsOneWidget);
    expect(find.text('DEV'), findsNothing);
  });

  testWidgets('04 — empty state proof', (tester) async {
    const key = Key('proof_empty');
    await _pumpFrame(
      tester,
      captureKey: key,
      height: 500,
      child: SingleChildScrollView(
        child: Builder(
          builder: (context) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const PremiumTasksPageHeader(
                title: ProductLabels.myTasks,
                subtitle: 'Ajanda, takip ve hatırlatmalar — tek ekran.',
              ),
              const PremiumTasksSummaryStrip(summary: TaskListSummary.empty),
              PremiumEmptyState(
                icon: Icons.task_alt_rounded,
                title: AppLocalizations.of(context).t('empty_tasks'),
                subtitle: AppLocalizations.of(context).t('empty_tasks_sub'),
                actionLabel: AppLocalizations.of(context).t('empty_tasks_cta'),
                onAction: () {},
              ),
            ],
          ),
        ),
      ),
    );
    await _savePng(tester, key, '04_empty_state.png');
    expect(find.text('DEV'), findsNothing);
  });

  testWidgets('05 — bottom nav safe area proof', (tester) async {
    const key = Key('proof_nav');
    final docs = _proofTaskDocs();
  final today = DateTime.now();
    final summary = computeTaskListSummary(docs, today);

    await _pumpFrame(
      tester,
      captureKey: key,
      height: 640,
      child: _customerOverrides(
        child: _consultantShellDock(
          selectedIndex: 3,
          body: Builder(
            builder: (context) {
              final bottomInset =
                  DashboardLayoutTokens.contentScrollBottomInset(context);
              return ListView(
                padding: EdgeInsets.only(
                  left: ConsultantTasksTokens.horizontal,
                  right: ConsultantTasksTokens.horizontal,
                  bottom: bottomInset + 88,
                ),
                children: [
                  const PremiumTasksPageHeader(
                    title: ProductLabels.myTasks,
                    subtitle: 'Ajanda, takip ve hatırlatmalar — tek ekran.',
                  ),
                  PremiumTasksSummaryStrip(summary: summary),
                  PremiumTaskFilterStrip(
                    selected: TaskListFilter.all,
                    onSelected: (_) {},
                  ),
                  _taskCard(
                    title: 'Müşteriyi ara — Ayşe Demir',
                    status: TaskDueStatus.today,
                    customerId: 'c1',
                  ),
                  _taskCard(
                    title: 'Portföy sunumu hazırla',
                    status: TaskDueStatus.overdue,
                    dueLabel: '2 gün gecikti',
                  ),
                  _taskCard(
                    title: 'Sözleşme takibi',
                    status: TaskDueStatus.upcoming,
                    customerId: 'c2',
                    dueLabel: '4 gün içinde',
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
    await _savePng(tester, key, '05_bottom_nav_safe_area.png');
    expect(find.text(ProductLabels.myTasks), findsWidgets);
    expect(find.text('Müşteriyi ara — Ayşe Demir'), findsOneWidget);
    expect(find.text('DEV'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
