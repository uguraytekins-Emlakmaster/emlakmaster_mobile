import 'package:emlakmaster_mobile/core/navigation/shell_tab_back_host.dart';
import 'package:emlakmaster_mobile/core/theme/app_theme.dart';
import 'package:emlakmaster_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:emlakmaster_mobile/features/crm_customers/domain/customer_heat_score.dart';
import 'package:emlakmaster_mobile/features/crm_customers/presentation/workspace/customer_workspace_snapshot.dart';
import 'package:emlakmaster_mobile/features/crm_customers/presentation/workspace/customer_workspace_types.dart';
import 'package:emlakmaster_mobile/features/crm_customers/presentation/workspace/providers/customer_workspace_provider.dart';
import 'package:emlakmaster_mobile/features/crm_customers/presentation/workspace/widgets/customer_workspace_chrome.dart';
import 'package:emlakmaster_mobile/features/crm_customers/presentation/workspace/widgets/customer_workspace_surface.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

CustomerWorkspaceSnapshot _overflowSnapshot() {
  final now = DateTime(2024, 6, 15);
  return computeCustomerWorkspaceSnapshot(
    [
      CustomerWorkspaceInput(
        id: 'long',
        name: 'Ayşegül Çağlayangil Yıldırımoğlu',
        phone: '+90 532 111 22 33',
        email: 'cokuzunbiradres.musteri@example-domain.com',
        heatLevel: CustomerHeatLevel.hot,
        heatScore: 82,
        heatReason: 'Yüksek ilgi · acil takip',
        lastInteractionAt: now.subtract(const Duration(days: 1)),
        createdAt: DateTime(2024, 1, 1),
        updatedAt: now.subtract(const Duration(days: 1)),
        nextSuggestedAction: 'Tekrar ara ve randevu teyit et',
        callablePhone: true,
        syncRisk: false,
        isDemo: false,
      ),
    ],
    now: now,
  );
}

Future<void> _pumpAt(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        currentUserProvider.overrideWith((ref) => Stream.value(null)),
        customerWorkspaceSnapshotProvider.overrideWithValue(
          AsyncValue.data(_overflowSnapshot()),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.dark(),
        home: const ShellTabBackHost(
          pageIndex: 3,
          child: Scaffold(body: CustomerWorkspaceSurface()),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  const profiles = <String, Size>{
    'iPhone SE': Size(320, 568),
    'iPhone 14/15': Size(390, 844),
    'iPhone Pro Max': Size(430, 932),
    'Android compact': Size(360, 740),
    'Android normal': Size(412, 915),
    'tablet': Size(768, 1024),
    'macOS window': Size(1024, 768),
  };

  profiles.forEach((name, size) {
    testWidgets('overflow yok — $name', (tester) async {
      await _pumpAt(tester, size);
      expect(tester.takeException(), isNull);
    });
  });

  testWidgets('uzun isim + filtre çipi dar ekranda taşmaz', (tester) async {
    await _pumpAt(tester, const Size(320, 700));
    expect(find.text('Ayşegül Çağlayangil Yıldırımoğlu'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('kategori filtresi (Sıcak) geniş viewport', (tester) async {
    await _pumpAt(tester, const Size(768, 1024));
    await tester.tap(
      find.descendant(
        of: find.byType(CustomerWorkspaceFilterStrip),
        matching: find.text('Sıcak'),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
