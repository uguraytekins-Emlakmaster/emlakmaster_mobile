import 'package:emlakmaster_mobile/core/theme/app_theme.dart';
import 'package:emlakmaster_mobile/features/resurrection_engine/presentation/utils/follow_up_list_filter.dart';
import 'package:emlakmaster_mobile/features/resurrection_engine/presentation/widgets/consultant_follow_up_chrome.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('filter strip scrolls horizontally without overflow', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        home: Scaffold(
          body: PremiumFollowUpFilterStrip(
            selected: FollowUpListFilter.all,
            onSelected: (_) {},
          ),
        ),
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('follow_up_filter_strip_scroll')), findsOneWidget);

    await tester.drag(
      find.byKey(const Key('follow_up_filter_strip_scroll')),
      const Offset(-420, 0),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
