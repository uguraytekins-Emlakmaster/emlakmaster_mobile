import 'package:emlakmaster_mobile/core/onboarding/tour_target.dart';
import 'package:emlakmaster_mobile/core/theme/app_theme.dart';
import 'package:emlakmaster_mobile/features/onboarding/presentation/tour/coach_mark_tour.dart';
import 'package:emlakmaster_mobile/features/onboarding/presentation/tour/consultant_tour_steps.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Tur, hedef çözümünü kademeli zamanlayıcılarla yapar; pumpAndSettle bu
/// boşluklarda erken "settle" sayabildiği için sahte saati elle ilerletiriz.
Future<void> settleTour(WidgetTester tester) async {
  for (var i = 0; i < 32; i++) {
    await tester.pump(const Duration(milliseconds: 80));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(CoachMarkTour.dismiss);

  Widget harness({
    required List<TourTargetId> presentTargets,
    required List<CoachMarkStep> steps,
    required void Function(int) onCompleted,
    void Function(int pageIndex)? goToTab,
    ValueNotifier<List<TourTargetId>>? dynamicTargets,
  }) {
    Widget targetBox(TourTargetId id) => TourTarget(
          id: id,
          child: Container(height: 80, color: Colors.blue),
        );
    return MaterialApp(
      theme: AppTheme.light(),
      home: Builder(
        builder: (context) => Scaffold(
          body: Column(
            children: [
              if (dynamicTargets != null)
                ValueListenableBuilder<List<TourTargetId>>(
                  valueListenable: dynamicTargets,
                  builder: (_, ids, __) => Column(
                    children: ids.map(targetBox).toList(),
                  ),
                )
              else
                ...presentTargets.map(targetBox),
              ElevatedButton(
                onPressed: () => CoachMarkTour.show(
                  context,
                  steps: steps,
                  goToTab: goToTab ?? (_) {},
                  onCompleted: () => onCompleted(1),
                ),
                child: const Text('start-tour'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  CoachMarkStep step(TourTargetId id, String title, {int? tabIndex}) =>
      CoachMarkStep(
        targetId: id,
        icon: Icons.dashboard_rounded,
        title: title,
        body: '$title gövdesi.',
        tabIndex: tabIndex,
      );

  testWidgets('çok adımlı ilerleme: İleri ile sonraki, Bitir ile kapanır',
      (tester) async {
    var completed = 0;
    await tester.pumpWidget(
      harness(
        presentTargets: const [
          TourTargetId.gunumCommandDeck,
          TourTargetId.gunumQuickAccess,
        ],
        steps: [
          step(TourTargetId.gunumCommandDeck, 'Komuta merkezi'),
          step(TourTargetId.gunumQuickAccess, 'Hızlı erişim'),
        ],
        onCompleted: (v) => completed += v,
      ),
    );

    await tester.tap(find.text('start-tour'));
    await settleTour(tester);

    expect(find.text('TUR · ADIM 1'), findsOneWidget);
    expect(find.text('Komuta merkezi'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'İleri'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'İleri'));
    await settleTour(tester);

    expect(find.text('TUR · ADIM 2'), findsOneWidget);
    expect(find.text('Hızlı erişim'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Bitir'));
    await settleTour(tester);

    expect(find.text('Hızlı erişim'), findsNothing);
    expect(completed, 1);
    expect(CoachMarkTour.isShowing, isFalse);
  });

  testWidgets('Atla turu kapatır ve tamamlandı sayılır', (tester) async {
    var completed = 0;
    await tester.pumpWidget(
      harness(
        presentTargets: const [TourTargetId.gunumCommandDeck],
        steps: [step(TourTargetId.gunumCommandDeck, 'Komuta merkezi')],
        onCompleted: (v) => completed += v,
      ),
    );

    await tester.tap(find.text('start-tour'));
    await settleTour(tester);
    expect(find.text('Komuta merkezi'), findsOneWidget);

    // Kalıcı (üst sağ) "Atla" her durumda erişilebilir.
    await tester.tap(find.text('Atla').first);
    await settleTour(tester);

    expect(find.text('Komuta merkezi'), findsNothing);
    expect(completed, 1);
    expect(CoachMarkTour.isShowing, isFalse);
  });

  testWidgets('hiçbir hedef yoksa tur açılmaz ama tamamlandı çağrılır',
      (tester) async {
    var completed = 0;
    await tester.pumpWidget(
      harness(
        presentTargets: const [],
        steps: [step(TourTargetId.settingsHeader, 'Yok')],
        onCompleted: (v) => completed += v,
      ),
    );

    await tester.tap(find.text('start-tour'));
    await settleTour(tester);

    expect(find.text('Yok'), findsNothing);
    expect(completed, 1);
    expect(CoachMarkTour.isShowing, isFalse);
  });

  testWidgets('ortadaki hedef yoksa o adım zarifçe atlanır', (tester) async {
    var completed = 0;
    await tester.pumpWidget(
      harness(
        presentTargets: const [
          TourTargetId.gunumCommandDeck,
          TourTargetId.gunumQuickAccess,
        ],
        steps: [
          step(TourTargetId.gunumCommandDeck, 'Birinci'),
          step(TourTargetId.callsHeader, 'Eksik'), // ekranda yok → atlanır
          step(TourTargetId.gunumQuickAccess, 'Üçüncü'),
        ],
        onCompleted: (v) => completed += v,
      ),
    );

    await tester.tap(find.text('start-tour'));
    await settleTour(tester);
    expect(find.text('Birinci'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'İleri'));
    await settleTour(tester);

    // İkinci (eksik) atlandı → doğrudan üçüncü; son adım olduğu için "Bitir".
    expect(find.text('Eksik'), findsNothing);
    expect(find.text('Üçüncü'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Bitir'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Bitir'));
    await settleTour(tester);
    expect(completed, 1);
  });

  testWidgets('sekme geçişi: goToTab çağrılınca hedef belirir ve gösterilir',
      (tester) async {
    var completed = 0;
    final visible =
        ValueNotifier<List<TourTargetId>>([TourTargetId.gunumCommandDeck]);
    final tabCalls = <int>[];

    await tester.pumpWidget(
      harness(
        presentTargets: const [],
        dynamicTargets: visible,
        goToTab: (pageIndex) {
          tabCalls.add(pageIndex);
          // İkinci sekmeye geçiş hedefi ağaca ekler.
          if (pageIndex == 3) {
            visible.value = [
              TourTargetId.gunumCommandDeck,
              TourTargetId.customersHeader,
            ];
          }
        },
        steps: [
          step(TourTargetId.gunumCommandDeck, 'Günüm', tabIndex: 0),
          step(TourTargetId.customersHeader, 'Müşteriler', tabIndex: 3),
        ],
        onCompleted: (v) => completed += v,
      ),
    );

    await tester.tap(find.text('start-tour'));
    await settleTour(tester);
    expect(find.text('Günüm'), findsOneWidget);
    expect(tabCalls, contains(0));

    await tester.tap(find.widgetWithText(FilledButton, 'İleri'));
    await settleTour(tester);

    expect(tabCalls, contains(3));
    expect(find.text('Müşteriler'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Bitir'));
    await settleTour(tester);
    expect(completed, 1);
    expect(CoachMarkTour.isShowing, isFalse);

    visible.dispose();
  });

  test('kapsamlı tur adım listesi tüm ana ekranları içerir', () {
    final steps = buildConsultantTourSteps();
    final ids = steps.map((s) => s.targetId).toSet();
    expect(steps.length, greaterThanOrEqualTo(6));
    expect(ids, contains(TourTargetId.gunumCommandDeck));
    expect(ids, contains(TourTargetId.customersHeader));
    expect(ids, contains(TourTargetId.callsHeader));
    expect(ids, contains(TourTargetId.tasksHeader));
    expect(ids, contains(TourTargetId.messagesHeader));
    expect(ids, contains(TourTargetId.settingsHeader));
  });
}
