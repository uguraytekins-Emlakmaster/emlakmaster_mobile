import 'package:emlakmaster_mobile/core/navigation/main_shell_shortcut_provider.dart';
import 'package:emlakmaster_mobile/core/router/app_router.dart';
import 'package:emlakmaster_mobile/screens/admin_shell_nav.dart';
import 'package:emlakmaster_mobile/screens/command_center_shell_entry_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AdminShellNav.isOffShellRoute', () {
    test('admin and command-center routes are off-shell', () {
      expect(AdminShellNav.isOffShellRoute('/admin/teams'), isTrue);
      expect(AdminShellNav.isOffShellRoute('/admin/teams/t1'), isTrue);
      expect(AdminShellNav.isOffShellRoute(AppRouter.routeCommandCenter), isTrue);
      expect(AdminShellNav.isOffShellRoute(AppRouter.routeHome), isFalse);
    });
  });

  testWidgets('goToCommandCenterTab enqueues shortcut when shell nav absent',
      (tester) async {
    late List<MainShellShortcutCommand> shortcuts;

    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, __) => const Scaffold(body: Text('home')),
        ),
        GoRoute(
          path: '/admin/teams',
          builder: (_, __) => const Scaffold(body: Text('teams')),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          mainShellShortcutProvider.overrideWith(
            (ref) => _RecordingShortcutQueue(
              onChange: (s) => shortcuts = s,
            ),
          ),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    router.go('/admin/teams');
    await tester.pumpAndSettle();
    expect(find.text('teams'), findsOneWidget);

    AdminShellNav.goToCommandCenterTab(
      tester.element(find.text('teams')),
    );
    await tester.pumpAndSettle();

    expect(router.routeInformationProvider.value.uri.path, '/');
    expect(
      shortcuts.any((c) => c.shortcut == MainShellShortcut.openCallsTab),
      isTrue,
    );
  });

  testWidgets('goToCommandCenterTab uses shell tab when already on home shell',
      (tester) async {
    var jumpedTo = -1;

    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, __) => AdminShellNav(
            goToTab: (i) => jumpedTo = i,
            tabIndexFor: (key) => key == 'commandCenter' ? 3 : -1,
            child: const Scaffold(body: Text('home')),
          ),
        ),
        GoRoute(
          path: '/admin/teams',
          builder: (_, __) => const Scaffold(body: Text('teams')),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    AdminShellNav.goToCommandCenterTab(
      tester.element(find.text('home')),
    );
    await tester.pumpAndSettle();

    expect(jumpedTo, 3);
    expect(router.routeInformationProvider.value.uri.path, '/');
  });

  testWidgets('goToCommandCenterTab from nested route never calls goToTab alone',
      (tester) async {
    var jumpedTo = -1;

    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, __) => AdminShellNav(
            goToTab: (i) => jumpedTo = i,
            tabIndexFor: (key) => key == 'commandCenter' ? 3 : -1,
            child: const Scaffold(body: Text('home')),
          ),
        ),
        GoRoute(
          path: '/admin/teams',
          builder: (_, __) => AdminShellNav(
            goToTab: (i) => jumpedTo = i,
            tabIndexFor: (key) => key == 'commandCenter' ? 3 : -1,
            child: const Scaffold(body: Text('teams')),
          ),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    router.go('/admin/teams');
    await tester.pumpAndSettle();

    AdminShellNav.goToCommandCenterTab(
      tester.element(find.text('teams')),
    );
    await tester.pumpAndSettle();

    expect(router.routeInformationProvider.value.uri.path, '/');
    expect(jumpedTo, -1);
  });

  testWidgets('/command-center route redirects to home with shortcut',
      (tester) async {
    late List<MainShellShortcutCommand> shortcuts;

    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, __) => const Scaffold(body: Text('home')),
        ),
        GoRoute(
          path: AppRouter.routeCommandCenter,
          builder: (_, __) => const CommandCenterShellEntryPage(),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          mainShellShortcutProvider.overrideWith(
            (ref) => _RecordingShortcutQueue(
              onChange: (s) => shortcuts = s,
            ),
          ),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    router.go(AppRouter.routeCommandCenter);
    await tester.pump();
    await tester.pump();

    expect(router.routeInformationProvider.value.uri.path, '/');
    expect(
      shortcuts.any((c) => c.shortcut == MainShellShortcut.openCallsTab),
      isTrue,
    );
  });
}

class _RecordingShortcutQueue extends MainShellShortcutQueueNotifier {
  _RecordingShortcutQueue({required this.onChange}) : super() {
    onChange(state);
  }

  final void Function(List<MainShellShortcutCommand> state) onChange;

  @override
  void enqueue(MainShellShortcut shortcut) {
    super.enqueue(shortcut);
    onChange(state);
  }
}
