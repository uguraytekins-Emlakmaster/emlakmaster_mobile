import 'package:emlakmaster_mobile/core/layout/adaptive_shell_scaffold.dart';
import 'package:emlakmaster_mobile/core/navigation/main_shell_shortcut_provider.dart';
import 'package:emlakmaster_mobile/core/theme/app_theme.dart';
import 'package:emlakmaster_mobile/core/widgets/command_palette.dart';
import 'package:emlakmaster_mobile/features/auth/domain/entities/app_role.dart';
import 'package:emlakmaster_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('AdaptiveShellScaffold reacts to shortcut provider', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          home: Consumer(
            builder: (context, ref, _) {
              return Scaffold(
                body: Column(
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        ref
                            .read(mainShellShortcutProvider.notifier)
                            .enqueue(MainShellShortcut.openCustomersTab);
                      },
                      child: const Text('Jump Customers'),
                    ),
                    const Expanded(
                      child: AdaptiveShellScaffold(
                        navItems: [
                          AdaptiveNavItem(Icons.dashboard_rounded, 'Ana Sayfa'),
                          AdaptiveNavItem(Icons.people_rounded, 'Müşteriler'),
                          AdaptiveNavItem(Icons.settings_rounded, 'Ayarlar'),
                        ],
                        pages: [
                          Center(child: Text('Ana Sayfa İçeriği')),
                          Center(child: Text('Müşteriler İçeriği')),
                          Center(child: Text('Ayarlar İçeriği')),
                        ],
                        shortcutMap: {
                          MainShellShortcut.openHomeTab: 0,
                          MainShellShortcut.openCustomersTab: 1,
                          MainShellShortcut.openAccountTab: 2,
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );

    expect(find.text('Ana Sayfa İçeriği'), findsOneWidget);
    await tester.tap(find.text('Jump Customers'));
    await tester.pumpAndSettle();

    expect(find.text('Müşteriler İçeriği'), findsOneWidget);
  });

  testWidgets('AdaptiveShellScaffold replays queued startup shortcut', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          mainShellShortcutProvider.overrideWith(
            (ref) => MainShellShortcutQueueNotifier(
              initialCommands: const [
                MainShellShortcutCommand(
                  id: 1,
                  shortcut: MainShellShortcut.openCustomersTab,
                ),
              ],
            ),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          home: const AdaptiveShellScaffold(
            navItems: [
              AdaptiveNavItem(Icons.dashboard_rounded, 'Ana Sayfa'),
              AdaptiveNavItem(Icons.people_rounded, 'Müşteriler'),
              AdaptiveNavItem(Icons.settings_rounded, 'Ayarlar'),
            ],
            pages: [
              Center(child: Text('Ana Sayfa İçeriği')),
              Center(child: Text('Müşteriler İçeriği')),
              Center(child: Text('Ayarlar İçeriği')),
            ],
            shortcutMap: {
              MainShellShortcut.openHomeTab: 0,
              MainShellShortcut.openCustomersTab: 1,
              MainShellShortcut.openAccountTab: 2,
            },
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump();

    expect(find.text('Müşteriler İçeriği'), findsOneWidget);
  });

  testWidgets('AdaptiveShellScaffold keeps selected tab by stable identity', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          home: const _DynamicShellHarness(),
        ),
      ),
    );

    expect(find.text('Dashboard İçeriği'), findsOneWidget);

    await tester.tap(find.text('Ayarlar'));
    await tester.pumpAndSettle();
    expect(find.text('Ayarlar İçeriği'), findsOneWidget);

    await tester.tap(find.text('Toggle Extra Tab'));
    await tester.pumpAndSettle();

    expect(find.text('Ayarlar İçeriği'), findsOneWidget);
    expect(find.text('Ekstra İçeriği'), findsNothing);
  });

  testWidgets('Command palette shows consultant actions', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          displayRoleOrNullProvider.overrideWith((ref) => AppRole.agent),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          home: Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: ElevatedButton(
                  onPressed: () => CommandPalette.show(context),
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('Müşterilerim'), findsOneWidget);
    expect(find.text('İlanlar'), findsOneWidget);
    expect(find.text('Çağrılarım'), findsOneWidget);
    expect(find.text('Ofis yönetimi'), findsNothing);
  });

  testWidgets('Command palette shows client actions without staff tabs', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          displayRoleOrNullProvider.overrideWith((ref) => AppRole.client),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          home: Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: ElevatedButton(
                  onPressed: () => CommandPalette.show(context),
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('Favoriler'), findsOneWidget);
    expect(find.text('Mesajlar'), findsOneWidget);
    expect(find.text('Müşteriler'), findsNothing);
    expect(find.text('Ofis yönetimi'), findsNothing);
  });
}

class _DynamicShellHarness extends StatefulWidget {
  const _DynamicShellHarness();

  @override
  State<_DynamicShellHarness> createState() => _DynamicShellHarnessState();
}

class _DynamicShellHarnessState extends State<_DynamicShellHarness> {
  bool _showExtraTab = false;

  @override
  Widget build(BuildContext context) {
    final navItems = <AdaptiveNavItem>[
      const AdaptiveNavItem(Icons.dashboard_rounded, 'Dashboard'),
      if (_showExtraTab) const AdaptiveNavItem(Icons.extension_rounded, 'Ekstra'),
      const AdaptiveNavItem(Icons.settings_rounded, 'Ayarlar'),
    ];
    final pages = <Widget>[
      const Center(child: Text('Dashboard İçeriği')),
      if (_showExtraTab) const Center(child: Text('Ekstra İçeriği')),
      const Center(child: Text('Ayarlar İçeriği')),
    ];
    final tabIds = <Object>[
      'dashboard',
      if (_showExtraTab) 'extra',
      'settings',
    ];

    return Scaffold(
      body: Column(
        children: [
          ElevatedButton(
            onPressed: () => setState(() => _showExtraTab = !_showExtraTab),
            child: const Text('Toggle Extra Tab'),
          ),
          Expanded(
            child: AdaptiveShellScaffold(
              navItems: navItems,
              pages: pages,
              tabIds: tabIds,
              shortcutMap: const {
                MainShellShortcut.openHomeTab: 0,
                MainShellShortcut.openAccountTab: 1,
              },
            ),
          ),
        ],
      ),
    );
  }
}
