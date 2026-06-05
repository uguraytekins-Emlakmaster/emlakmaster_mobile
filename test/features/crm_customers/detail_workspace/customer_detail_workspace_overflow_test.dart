import 'package:emlakmaster_mobile/core/theme/app_theme.dart';
import 'package:emlakmaster_mobile/features/crm_customers/presentation/detail_workspace/customer_detail_workspace_snapshot.dart';
import 'package:emlakmaster_mobile/features/crm_customers/presentation/detail_workspace/customer_detail_workspace_types.dart';
import 'package:emlakmaster_mobile/features/crm_customers/presentation/detail_workspace/widgets/customer_detail_section_card.dart';
import 'package:emlakmaster_mobile/features/crm_customers/presentation/detail_workspace/widgets/customer_detail_workspace_chrome.dart';
import 'package:emlakmaster_mobile/shared/models/customer_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _profiles = <({String name, Size size})>[
  (name: 'iPhone SE', size: Size(320, 568)),
  (name: 'iPhone 14', size: Size(390, 844)),
  (name: 'Android compact', size: Size(360, 640)),
  (name: 'macOS', size: Size(1280, 800)),
];

CustomerDetailWorkspaceSnapshot _snapshot() {
  return computeCustomerDetailWorkspaceSnapshot(
    CustomerDetailWorkspaceInput(
      customerId: 'c1',
      entity: CustomerEntity(
        id: 'c1',
        fullName: 'Uzun müşteri adı — portföy takibi ve geri dönüş',
        primaryPhone: '+905551111111',
        email: 'test@example.com',
        lastInteractionAt: DateTime(2024, 6, 10),
        lastCallSummary: 'Teklif bekliyor, fiyat görüşmesi yapılacak',
        callsCount: 2,
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 6, 15),
      ),
      openTasks: const [
        CustomerDetailLinkedRow(
          id: 't1',
          title: 'Geri ara — teklif takibi',
          statusLabel: 'Geciken',
        ),
      ],
      matchedListings: const [
        CustomerDetailListingRow(
          listingId: 'l1',
          title: 'Satılık daire Kadıköy merkez',
        ),
      ],
      now: DateTime(2024, 6, 15, 12),
    ),
  );
}

Future<void> _pumpChrome(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final snap = _snapshot();
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.dark(),
      home: MediaQuery(
        data: MediaQueryData(size: size),
        child: Scaffold(
          body: Column(
            children: [
              CustomerDetailWorkspaceHeader(
                title: snap.displayName,
                subtitle: snap.identityLine,
              ),
              CustomerDetailWorkspaceSummaryStrip(summary: snap.summary),
              CustomerDetailQuickActionsRow(
                actions: snap.quickActions,
                onAction: (_) {},
              ),
              CustomerDetailSectionCard(section: snap.sections.first),
            ],
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
    testWidgets('overflow — ${p.name}', (tester) async {
      await _pumpChrome(tester, p.size);
      expect(tester.takeException(), isNull);
    });
  }
}
