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
                        ref.read(mainShellShortcutProvider.notifier).state =
                            MainShellShortcut.openCustomersTab;
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

    expect(find.text('Müşteriler'), findsOneWidget);
    expect(find.text('İlanlar'), findsOneWidget);
    expect(find.text('Çağrılar'), findsOneWidget);
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
