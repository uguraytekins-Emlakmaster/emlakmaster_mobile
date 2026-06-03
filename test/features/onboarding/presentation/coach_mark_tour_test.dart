import 'package:emlakmaster_mobile/core/theme/app_theme.dart';
import 'package:emlakmaster_mobile/features/onboarding/presentation/tour/coach_mark_tour.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final deckKey = GlobalKey();
  final controlsKey = GlobalKey();

  tearDown(CoachMarkTour.dismiss);

  List<CoachMarkStep> steps() => [
        CoachMarkStep(
          targetKey: deckKey,
          icon: Icons.dashboard_rounded,
          title: 'Komuta merkezi',
          body: 'Günün özeti burada.',
        ),
        CoachMarkStep(
          targetKey: controlsKey,
          icon: Icons.tune_rounded,
          title: 'Arama ve filtre',
          body: 'Hızlıca filtrele.',
        ),
      ];

  testWidgets('tur ilk adımdan başlar ve İleri/Bitir ile ilerler', (
    tester,
  ) async {
    var completed = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Builder(
          builder: (context) => Scaffold(
            body: Column(
              children: [
                Container(key: deckKey, height: 80, color: Colors.blue),
                Container(key: controlsKey, height: 80, color: Colors.green),
                ElevatedButton(
                  onPressed: () => CoachMarkTour.show(
                    context,
                    steps: steps(),
                    onCompleted: () => completed++,
                  ),
                  child: const Text('start-tour'),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('start-tour'));
    await tester.pumpAndSettle();

    expect(find.text('ADIM 1 / 2'), findsOneWidget);
    expect(find.text('Komuta merkezi'), findsOneWidget);

    await tester.tap(find.text('İleri'));
    await tester.pumpAndSettle();

    expect(find.text('ADIM 2 / 2'), findsOneWidget);
    expect(find.text('Arama ve filtre'), findsOneWidget);

    await tester.tap(find.text('Bitir'));
    await tester.pumpAndSettle();

    expect(find.text('Arama ve filtre'), findsNothing);
    expect(completed, 1);
    expect(CoachMarkTour.isShowing, isFalse);
  });

  testWidgets('Atla her adımda turu kapatır ve tamamlandı sayar', (
    tester,
  ) async {
    var completed = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Builder(
          builder: (context) => Scaffold(
            body: Column(
              children: [
                Container(key: deckKey, height: 80, color: Colors.blue),
                Container(key: controlsKey, height: 80, color: Colors.green),
                ElevatedButton(
                  onPressed: () => CoachMarkTour.show(
                    context,
                    steps: steps(),
                    onCompleted: () => completed++,
                  ),
                  child: const Text('start-tour'),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('start-tour'));
    await tester.pumpAndSettle();

    expect(find.text('ADIM 1 / 2'), findsOneWidget);

    await tester.tap(find.text('Atla'));
    await tester.pumpAndSettle();

    expect(find.text('Komuta merkezi'), findsNothing);
    expect(completed, 1);
    expect(CoachMarkTour.isShowing, isFalse);
  });

  testWidgets('görünür hedef yoksa tur açılmaz ama tamamlandı çağrılır', (
    tester,
  ) async {
    var completed = 0;
    final missingKey = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () => CoachMarkTour.show(
                context,
                steps: [
                  CoachMarkStep(
                    targetKey: missingKey,
                    icon: Icons.dashboard_rounded,
                    title: 'Yok',
                    body: 'Hedef ekranda değil.',
                  ),
                ],
                onCompleted: () => completed++,
              ),
              child: const Text('start-tour'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('start-tour'));
    await tester.pumpAndSettle();

    expect(completed, 1);
    expect(CoachMarkTour.isShowing, isFalse);
  });
}
