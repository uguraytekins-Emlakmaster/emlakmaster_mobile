import 'package:emlakmaster_mobile/screens/consultant_shell_nav.dart';
import 'package:emlakmaster_mobile/shared/widgets/app_back_button.dart';
import 'package:emlakmaster_mobile/widgets/premium/premium_navigation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Geri/ana sayfa kromu — mahsur kalma önleme garantileri.
///
/// Mod kuralı:
/// - Yığın varsa (push edilmiş): geri + ana sayfa.
/// - Yığın yok + kabuk dışı (derin link / tam sayfa): yalnızca ana sayfa.
/// - Yığın yok + kabuk kök sekmesi: hiçbir şey (alt gezinme yeterli).
void main() {
  Widget host(Widget child) => MaterialApp(home: child);

  group('PremiumNavLeading', () {
    testWidgets('kabuk dışı kökte yalnızca ana sayfa gösterir', (tester) async {
      await tester.pumpWidget(
        host(
          const Scaffold(
            appBar: PreferredSize(
              preferredSize: Size.fromHeight(56),
              child: SafeArea(child: PremiumNavLeading()),
            ),
            body: SizedBox(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AppBackButton), findsNothing);
      expect(find.byType(PremiumHomeButton), findsOneWidget);
    });

    testWidgets('kabuk kök sekmesinde hiçbir krom göstermez', (tester) async {
      await tester.pumpWidget(
        host(
          ConsultantShellNav(
            goToTab: (_) {},
            child: const Scaffold(
              appBar: PreferredSize(
                preferredSize: Size.fromHeight(56),
                child: SafeArea(child: PremiumNavLeading()),
              ),
              body: SizedBox(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AppBackButton), findsNothing);
      expect(find.byType(PremiumHomeButton), findsNothing);
    });

    testWidgets('push edilen sayfada geri + ana sayfa gösterir', (tester) async {
      await tester.pumpWidget(
        host(
          Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const Scaffold(
                        appBar: PreferredSize(
                          preferredSize: Size.fromHeight(56),
                          child: SafeArea(child: PremiumNavLeading()),
                        ),
                        body: SizedBox(),
                      ),
                    ),
                  ),
                  child: const Text('push'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('push'));
      await tester.pumpAndSettle();

      expect(find.byType(AppBackButton), findsOneWidget);
      expect(find.byType(PremiumHomeButton), findsOneWidget);
    });

    testWidgets('geri butonu özel işleyiciyi tetikler', (tester) async {
      var tapped = 0;
      await tester.pumpWidget(
        host(
          Scaffold(
            appBar: PreferredSize(
              preferredSize: const Size.fromHeight(56),
              child: SafeArea(
                child: AppBackButton(onPressed: () => tapped++),
              ),
            ),
            body: const SizedBox(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(AppBackButton));
      await tester.pump();

      expect(tapped, 1);
    });

    testWidgets('PremiumHeaderNavLeading kök sekmede sıfır yer kaplar',
        (tester) async {
      await tester.pumpWidget(
        host(
          ConsultantShellNav(
            goToTab: (_) {},
            child: const Scaffold(
              body: SafeArea(child: PremiumHeaderNavLeading()),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AppBackButton), findsNothing);
      expect(find.byType(PremiumHomeButton), findsNothing);
    });
  });
}
