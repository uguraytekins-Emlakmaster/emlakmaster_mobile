import 'package:emlakmaster_mobile/core/copy/product_labels.dart';
import 'package:emlakmaster_mobile/core/layout/adaptive_shell_scaffold.dart';
import 'package:emlakmaster_mobile/core/navigation/main_shell_shortcut_provider.dart';
import 'package:emlakmaster_mobile/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('navPageIndices shortcuts reach pages outside bottom nav', (
    WidgetTester tester,
  ) async {
    const pages = [
      Text('Günüm'),
      Text('Mesajlar'),
      Text('Çağrılar'),
      Text('Müşteriler'),
      Text('İlanlar'),
      Text('Takip'),
      Text('Görevler'),
      Text('Ayarlar'),
    ];

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.light(),
          home: AdaptiveShellScaffold(
            navItems: const [
              AdaptiveNavItem(Icons.space_dashboard_rounded, 'Günüm'),
              AdaptiveNavItem(Icons.call_rounded, 'Çağrılar'),
              AdaptiveNavItem(Icons.people_rounded, 'Müşteriler'),
              AdaptiveNavItem(Icons.task_alt_rounded, 'Görevler'),
              AdaptiveNavItem(Icons.apps_rounded, ProductLabels.consultantMore),
            ],
            navPageIndices: const [0, 2, 3, 6, kShellNavMoreMenu],
            pages: pages,
            tabIds: const [
              'summary',
              'messages',
              'calls',
              'customers',
              'listings',
              'follow_up',
              'tasks',
              'settings',
            ],
            shortcutMap: const {
              MainShellShortcut.openMessageCenterTab: 1,
              MainShellShortcut.openListingsTab: 4,
            },
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump();

    expect(find.text('Günüm'), findsWidgets);

    final context = tester.element(find.byType(AdaptiveShellScaffold));
    ProviderScope.containerOf(context)
        .read(mainShellShortcutProvider.notifier)
        .enqueue(MainShellShortcut.openMessageCenterTab);
    await tester.pump();
    await tester.pump();

    expect(find.text('Mesajlar'), findsOneWidget);
  });
}
