import 'package:emlakmaster_mobile/core/theme/app_theme.dart';
import 'package:emlakmaster_mobile/features/crm_customers/domain/customer_heat_score.dart';
import 'package:emlakmaster_mobile/features/resurrection_engine/domain/entities/resurrection_segment.dart';
import 'package:emlakmaster_mobile/features/resurrection_engine/presentation/workspace/follow_up_workspace_snapshot.dart';
import 'package:emlakmaster_mobile/features/resurrection_engine/presentation/workspace/follow_up_workspace_types.dart';
import 'package:emlakmaster_mobile/features/resurrection_engine/presentation/workspace/widgets/follow_up_workspace_chrome.dart';
import 'package:emlakmaster_mobile/features/resurrection_engine/presentation/workspace/widgets/follow_up_workspace_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _profiles = <({String name, Size size})>[
  (name: 'iPhone SE', size: Size(320, 568)),
  (name: 'iPhone 14', size: Size(390, 844)),
  (name: 'Android compact', size: Size(360, 640)),
  (name: 'macOS', size: Size(1280, 800)),
];

FollowUpRowView _row() {
  final snap = computeFollowUpWorkspaceSnapshot(
    [
      ResurrectionQueueItem(
        customerId: 'c1',
        customerName:
            'Uzun müşteri adı — portföy takibi ve geri dönüş görüşmesi',
        primaryPhone: '+905551111111',
        segment: ResurrectionSegment.silent14,
        daysSilent: 14,
        heatLevel: CustomerHeatLevel.warm,
        nextSuggestedAction: 'Fiyat görüşmesi için geri ara',
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
          body: FollowUpWorkspaceRow(
            row: _row(),
            onTap: () {},
            onCall: () {},
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
    final snap = computeFollowUpWorkspaceSnapshot(
      [
        ResurrectionQueueItem(
          customerId: 'a',
          customerName: 'Ada',
          daysSilent: 7,
          segment: ResurrectionSegment.silent7,
        ),
      ],
      now: DateTime(2024, 6, 15),
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        home: Scaffold(
          body: FollowUpWorkspaceSummaryStrip(summary: snap.summary),
        ),
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
