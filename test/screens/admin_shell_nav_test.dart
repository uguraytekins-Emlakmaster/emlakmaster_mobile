import 'package:emlakmaster_mobile/core/navigation/main_shell_shortcut_provider.dart';
import 'package:emlakmaster_mobile/core/router/app_router.dart';
import 'package:emlakmaster_mobile/screens/admin_shell_nav.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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

  testWidgets('goToCommandCenterTab uses shell tab when AdminShellNav present',
      (tester) async {
    var jumpedTo = -1;

    await tester.pumpWidget(
      MaterialApp(
        home: AdminShellNav(
          goToTab: (i) => jumpedTo = i,
          tabIndexFor: (key) => key == 'commandCenter' ? 3 : -1,
          child: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () => AdminShellNav.goToCommandCenterTab(context),
                child: const Text('go'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();

    expect(jumpedTo, 3);
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
