import 'dart:io';
import 'dart:ui' as ui;

import 'package:emlakmaster_mobile/core/copy/product_labels.dart';
import 'package:emlakmaster_mobile/core/layout/adaptive_shell_scaffold.dart';
import 'package:emlakmaster_mobile/core/theme/app_theme.dart';
import 'package:emlakmaster_mobile/core/theme/dashboard_layout_tokens.dart';
import 'package:emlakmaster_mobile/features/crm_customers/domain/customer_heat_score.dart';
import 'package:emlakmaster_mobile/features/crm_customers/presentation/models/customer_list_page_data.dart';
import 'package:emlakmaster_mobile/features/crm_customers/presentation/models/customer_list_row_snapshot.dart';
import 'package:emlakmaster_mobile/features/crm_customers/presentation/pages/customer_list_page.dart';
import 'package:emlakmaster_mobile/features/crm_customers/presentation/providers/customer_list_stream_provider.dart';
import 'package:emlakmaster_mobile/features/crm_customers/presentation/providers/sync_delayed_risk_customer_ids_provider.dart';
import 'package:emlakmaster_mobile/features/crm_customers/presentation/utils/customer_list_heat_filter.dart';
import 'package:emlakmaster_mobile/features/crm_customers/presentation/widgets/consultant_customers_chrome.dart';
import 'package:emlakmaster_mobile/features/crm_customers/presentation/widgets/customer_card.dart';
import 'package:emlakmaster_mobile/features/revenue_engine/presentation/providers/revenue_engine_providers.dart';
import 'package:emlakmaster_mobile/shared/widgets/empty_state.dart';
import 'package:emlakmaster_mobile/shared/models/customer_models.dart';
import 'package:emlakmaster_mobile/widgets/premium/premium_bottom_nav_dock.dart';
import 'package:emlakmaster_mobile/widgets/premium/v2/premium_shell_chrome.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:emlakmaster_mobile/features/auth/presentation/providers/auth_provider.dart';

const _proofDir = 'build/screenshots/screen3_customers';
const _size = Size(390, 844);
const _pixelRatio = 3.0;

/// Danışman paneli müşteri sekmesi — gerçek [CustomerListPage] proof harness.
class _ProofAuthUser implements User {
  _ProofAuthUser(this.uid);
  @override
  final String uid;
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

List<CustomerEntity> _proofEntities() => [
      _entity('Ahmet Yılmaz', '+905321112233', 0.82),
      _entity('Ayşe Demir', '+905559998877', 0.55),
      _entity('Mehmet Kaya', '+905331234567', 0.18),
      _entity('Zeynep Arslan', '+905447766554', 0.71),
    ];

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

Widget _customersPageHarness({required CustomerListPageData pageData}) {
  return ProviderScope(
    overrides: [
      currentUserProvider.overrideWith(
        (ref) => Stream<User?>.value(_ProofAuthUser('proof_advisor')),
      ),
      customerListForAgentProvider.overrideWith(
        (ref) => Stream.value(pageData),
      ),
      syncDelayedRiskCustomerIdsProvider.overrideWith((ref) => const {}),
      customerRevenueSignalsMapProvider.overrideWith((ref) => const {}),
      displayRoleOrNullProvider.overrideWith((ref) => null),
    ],
    child: MaterialApp(
      theme: AppTheme.dark(),
      home: MediaQuery(
        data: const MediaQueryData(
          size: _size,
          padding: EdgeInsets.only(top: 47, bottom: 34),
        ),
        child: PremiumShellBackdrop(
          child: const CustomerListPage(),
        ),
      ),
    ),
  );
}

/// Danışman shell alt menüsü — Günüm, Çağrılarım, Müşterilerim, Görevlerim, Daha Fazla.
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

CustomerEntity _entity(String name, String phone, double temp) => CustomerEntity(
      id: 'proof_${name.hashCode}',
      fullName: name,
      primaryPhone: phone,
      leadTemperature: temp,
      lastInteractionAt: DateTime.now().subtract(const Duration(days: 2)),
      nextSuggestedAction: 'Tekrar ara',
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 6, 1),
    );

CustomerListRowSnapshot _row({CustomerHeatLevel level = CustomerHeatLevel.hot}) {
  return CustomerListRowSnapshot(
    crmHeat: CustomerHeatSnapshot(
      heatScore: level == CustomerHeatLevel.hot ? 82 : 48,
      heatLevel: level,
      heatReasonSummary: 'Son temas ve görev sinyali',
    ),
    showBrokerAlert: false,
    syncDelayedRisk: false,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('01 — header search filters proof', (tester) async {
    const key = Key('proof_header');
    final searchController = TextEditingController();
    addTearDown(searchController.dispose);

    await _pumpFrame(
      tester,
      captureKey: key,
      height: 268,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const PremiumCustomersPageHeader(
            title: 'Müşterilerim',
            subtitle: 'İlişki portföyü — arama, sıcaklık ve hızlı aksiyon.',
          ),
          PremiumCustomerSearchRow(
            controller: searchController,
            hintText: 'Telefon, isim veya e-posta ara…',
          ),
          PremiumCustomerHeatFilterStrip(
            selected: CustomerListHeatFilter.warm,
            onSelected: (_) {},
          ),
        ],
      ),
    );
    await _savePng(tester, key, '01_header_search_filters.png');
    expect(find.text('DEV'), findsNothing);
    expect(find.text('Müşterilerim'), findsOneWidget);
    expect(find.byType(PremiumCustomerHeatFilterStrip), findsOneWidget);
  });

  testWidgets('02 — customer list rows proof', (tester) async {
    const key = Key('proof_rows');
    final entities = _proofEntities();

    await _pumpFrame(
      tester,
      captureKey: key,
      height: 480,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < entities.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: CustomerCard(
                customer: entities[i],
                row: CustomerListRowSnapshot(
                  crmHeat: computeCustomerHeat(entities[i]),
                  showBrokerAlert: i == 1,
                  syncDelayedRisk: i == 2,
                ),
                onTap: () {},
                onCall: () {},
                onMessage: () {},
                onWhatsApp: () {},
                onOpenDetail: () {},
              ),
            ),
        ],
      ),
    );
    await _savePng(tester, key, '02_customer_list_rows.png');
    expect(find.text('Ahmet Yılmaz'), findsOneWidget);
    expect(find.text('Ayşe Demir'), findsOneWidget);
    expect(find.text('DEV'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('03 — customer actions proof', (tester) async {
    const key = Key('proof_actions');
    await _pumpFrame(
      tester,
      captureKey: key,
      height: 168,
      child: CustomerCard(
        customer: _entity('Aksiyon Demo', '+905551112233', 0.82),
        row: _row(),
        onTap: () {},
        onCall: () {},
        onMessage: () {},
        onWhatsApp: () {},
        onOpenDetail: () {},
      ),
    );
    await _savePng(tester, key, '03_customer_actions.png');
    expect(find.byIcon(Icons.call_rounded), findsWidgets);
    expect(find.byIcon(Icons.sms_rounded), findsWidgets);
    expect(find.byIcon(Icons.chat_rounded), findsWidgets);
    expect(find.byIcon(Icons.chevron_right_rounded), findsWidgets);
    expect(find.text('Aksiyon Demo'), findsOneWidget);
    expect(find.text('DEV'), findsNothing);
  });

  testWidgets('04 — empty state proof', (tester) async {
    const key = Key('proof_empty');
    await _pumpFrame(
      tester,
      captureKey: key,
      height: 360,
      child: const EmptyState(
        premiumVisual: true,
        grouped: true,
        anchorAboveCenter: true,
        icon: Icons.people_rounded,
        title: 'Henüz müşteri yok',
        subtitle: 'İlk kişiyle CRM portföyün burada canlanır.',
      ),
    );
    await _savePng(tester, key, '04_empty_state.png');
  });

  testWidgets('05 — bottom nav safe area proof', (tester) async {
    const key = Key('proof_nav');
    final entities = _proofEntities();
    await _pumpFrame(
      tester,
      captureKey: key,
      height: 620,
      child: _consultantShellDock(
        selectedIndex: 2,
        body: Builder(
          builder: (context) {
            final bottomInset =
                DashboardLayoutTokens.contentScrollBottomInset(context);
            return ListView(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                bottom: bottomInset + 72,
              ),
              children: [
                const PremiumCustomersPageHeader(
                  title: 'Müşterilerim',
                  subtitle: 'İlişki portföyü — arama ve sıcaklık.',
                ),
                for (final e in entities)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: CustomerCard(
                      customer: e,
                      row: CustomerListRowSnapshot(
                        crmHeat: computeCustomerHeat(e),
                        showBrokerAlert: false,
                        syncDelayedRisk: false,
                      ),
                      onTap: () {},
                      onCall: () {},
                      onMessage: () {},
                      onWhatsApp: () {},
                      onOpenDetail: () {},
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
    await _savePng(tester, key, '05_bottom_nav_safe_area.png');
    expect(find.text(ProductLabels.myCustomers), findsWidgets);
    expect(find.text('DEV'), findsNothing);
    expect(tester.takeException(), isNull);
  });

}
