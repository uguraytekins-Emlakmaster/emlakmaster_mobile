import 'dart:io';
import 'dart:ui' as ui;

import 'package:emlakmaster_mobile/core/copy/product_labels.dart';
import 'package:emlakmaster_mobile/core/layout/adaptive_shell_scaffold.dart';
import 'package:emlakmaster_mobile/core/theme/app_theme.dart';
import 'package:emlakmaster_mobile/core/theme/dashboard_layout_tokens.dart';
import 'package:emlakmaster_mobile/features/crm_customers/domain/customer_heat_score.dart';
import 'package:emlakmaster_mobile/features/crm_customers/presentation/models/customer_list_row_snapshot.dart';
import 'package:emlakmaster_mobile/features/crm_customers/presentation/utils/customer_list_heat_filter.dart';
import 'package:emlakmaster_mobile/features/crm_customers/presentation/widgets/consultant_customers_chrome.dart';
import 'package:emlakmaster_mobile/features/crm_customers/presentation/widgets/customer_card.dart';
import 'package:emlakmaster_mobile/shared/widgets/empty_state.dart';
import 'package:emlakmaster_mobile/shared/models/customer_models.dart';
import 'package:emlakmaster_mobile/widgets/premium/premium_bottom_nav_dock.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

const _proofDir = 'build/screenshots/screen3_customers';
const _size = Size(390, 844);

Future<void> _savePng(WidgetTester tester, Key key, String name) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(find.byKey(key));
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 2);
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
  await tester.pump(const Duration(milliseconds: 120));
}

CustomerEntity _entity(String name) => CustomerEntity(
      id: 'proof_$name',
      fullName: name,
      primaryPhone: '+905551112233',
      lastInteractionAt: DateTime.now().subtract(const Duration(days: 1)),
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
      height: 240,
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
  });

  testWidgets('02 — customer list rows proof', (tester) async {
    const key = Key('proof_rows');
    final names = ['Ahmet Yılmaz', 'Ayşe Demir', 'Mehmet Kaya'];

    await _pumpFrame(
      tester,
      captureKey: key,
      height: 420,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < names.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: CustomerCard(
                customer: _entity(names[i]),
                row: _row(
                  level: i == 0
                      ? CustomerHeatLevel.hot
                      : i == 1
                          ? CustomerHeatLevel.warm
                          : CustomerHeatLevel.cool,
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
    expect(tester.takeException(), isNull);
  });

  testWidgets('03 — customer actions proof', (tester) async {
    const key = Key('proof_actions');
    await _pumpFrame(
      tester,
      captureKey: key,
      height: 120,
      child: CustomerCard(
        customer: _entity('Aksiyon Demo'),
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
    await _pumpFrame(
      tester,
      captureKey: key,
      height: 560,
      child: Scaffold(
        backgroundColor: const Color(0xFF0A0E1A),
        body: Builder(
          builder: (context) {
            final bottomInset =
                DashboardLayoutTokens.contentScrollBottomInset(context);
            return ListView(
              padding: EdgeInsets.only(bottom: bottomInset),
              children: List.generate(
                5,
                (i) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: CustomerCard(
                    customer: _entity('Kayıt ${i + 1}'),
                    row: _row(),
                    onTap: () {},
                    onCall: () {},
                    onMessage: () {},
                    onWhatsApp: () {},
                    onOpenDetail: () {},
                  ),
                ),
              ),
            );
          },
        ),
        bottomNavigationBar: PremiumBottomNavDock(
          items: const [
            AdaptiveNavItem(
              Icons.space_dashboard_rounded,
              ProductLabels.consultantHome,
            ),
            AdaptiveNavItem(Icons.chat_bubble_rounded, 'Mesajlar'),
            AdaptiveNavItem(Icons.call_rounded, ProductLabels.myCalls),
            AdaptiveNavItem(Icons.people_rounded, ProductLabels.myCustomers),
            AdaptiveNavItem(Icons.apps_rounded, ProductLabels.consultantMore),
          ],
          selectedIndex: 3,
          onTap: (_) {},
        ),
      ),
    );
    await _savePng(tester, key, '05_bottom_nav_safe_area.png');
    expect(tester.takeException(), isNull);
  });
}
