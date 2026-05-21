import 'package:emlakmaster_mobile/core/navigation/app_back_dispatcher.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  testWidgets('popRoute pops go_router stack', (tester) async {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, __) => const Scaffold(body: Text('home')),
          routes: [
            GoRoute(
              path: 'child',
              builder: (_, __) => const Scaffold(body: Text('child')),
            ),
          ],
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    router.push('/child');
    await tester.pumpAndSettle();

    final ctx = tester.element(find.text('child'));
    expect(AppBackDispatcher.canPopRoute(ctx), isTrue);
    expect(AppBackDispatcher.popRoute(ctx), isTrue);
    await tester.pumpAndSettle();
    expect(find.text('home'), findsOneWidget);
  });

  testWidgets('popRoute pops Navigator.push overlay', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (homeContext) {
            return Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(homeContext).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const Scaffold(
                          body: Text('overlay'),
                        ),
                      ),
                    );
                  },
                  child: const Text('open'),
                ),
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    final overlayCtx = tester.element(find.text('overlay'));
    expect(AppBackDispatcher.canPopRoute(overlayCtx), isTrue);
    expect(AppBackDispatcher.popRoute(overlayCtx), isTrue);
    await tester.pumpAndSettle();
    expect(find.text('open'), findsOneWidget);
  });
}
