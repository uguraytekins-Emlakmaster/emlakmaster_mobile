import 'package:emlakmaster_mobile/core/navigation/main_shell_shortcut_provider.dart';
import 'package:emlakmaster_mobile/core/navigation/shell_navigator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

GoRouter _router({required String initialLocation}) {
  return GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const Scaffold(
          body: Center(child: Text('HOME_SHELL')),
        ),
      ),
      GoRoute(
        path: '/start',
        builder: (context, state) => Scaffold(
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ElevatedButton(
                  onPressed: () => ShellNavigator.goToShortcut(
                    context,
                    MainShellShortcut.openCallsTab,
                  ),
                  child: const Text('go-shortcut'),
                ),
                ElevatedButton(
                  onPressed: () => ShellNavigator.openGuardedRoute(
                    context,
                    route: '/target',
                    allowed: false,
                    deniedMessage: 'erisim-yok',
                  ),
                  child: const Text('guard-denied'),
                ),
                ElevatedButton(
                  onPressed: () => ShellNavigator.openGuardedRoute(
                    context,
                    route: '/target',
                    allowed: true,
                  ),
                  child: const Text('guard-allowed'),
                ),
              ],
            ),
          ),
        ),
      ),
      GoRoute(
        path: '/target',
        builder: (context, state) => const Scaffold(
          body: Center(child: Text('TARGET_PAGE')),
        ),
      ),
    ],
  );
}

Future<void> _pump(WidgetTester tester, ProviderContainer container,
    GoRouter router) async {
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('goToShortcut kabuk dışından enqueue eder ve ana kabuğa döner',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await _pump(tester, container, _router(initialLocation: '/start'));

    expect(find.text('go-shortcut'), findsOneWidget);

    await tester.tap(find.text('go-shortcut'));
    await tester.pumpAndSettle();

    // Kuyruğa kısayol eklendi.
    final queue = container.read(mainShellShortcutProvider);
    expect(queue, isNotEmpty);
    expect(queue.last.shortcut, MainShellShortcut.openCallsTab);

    // Ana kabuğa dönüldü.
    expect(find.text('HOME_SHELL'), findsOneWidget);
  });

  testWidgets('goToShortcut zaten ana kabuktayken yalnızca enqueue eder',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    // Ana kabukta bir tetikleyici barındır.
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => ShellNavigator.goToShortcut(
                  context,
                  MainShellShortcut.openTasksTab,
                ),
                child: const Text('home-go'),
              ),
            ),
          ),
        ),
      ],
    );
    await _pump(tester, container, router);

    await tester.tap(find.text('home-go'));
    await tester.pumpAndSettle();

    final queue = container.read(mainShellShortcutProvider);
    expect(queue, isNotEmpty);
    expect(queue.last.shortcut, MainShellShortcut.openTasksTab);
    // Hâlâ ana kabukta — gereksiz route churn yok.
    expect(find.text('home-go'), findsOneWidget);
  });

  testWidgets('openGuardedRoute izin yoksa rota açmaz, dürüst geri bildirim verir',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await _pump(tester, container, _router(initialLocation: '/start'));

    await tester.tap(find.text('guard-denied'));
    await tester.pump(); // snackbar göster

    expect(find.text('erisim-yok'), findsOneWidget);
    // Navigasyon olmadı.
    expect(find.text('TARGET_PAGE'), findsNothing);
    expect(find.text('guard-denied'), findsOneWidget);
  });

  testWidgets('openGuardedRoute izin varsa rotayı açar', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await _pump(tester, container, _router(initialLocation: '/start'));

    await tester.tap(find.text('guard-allowed'));
    await tester.pumpAndSettle();

    expect(find.text('TARGET_PAGE'), findsOneWidget);
  });
}
