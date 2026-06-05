import 'package:emlakmaster_mobile/core/theme/app_theme.dart';
import 'package:emlakmaster_mobile/features/messages/presentation/utils/message_conversation_list_filter.dart';
import 'package:emlakmaster_mobile/features/messages/presentation/widgets/consultant_messages_chrome.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _compactWidths = <({String name, double width})>[
  (name: 'iPhone 14', width: 390),
  (name: 'Android normal', width: 430),
];

const _scrollKey = Key('message_filter_strip_scroll');

Future<void> _pumpStrip(WidgetTester tester, double width) async {
  tester.view.physicalSize = Size(width, 844);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.dark(),
      home: MediaQuery(
        data: MediaQueryData(size: Size(width, 844)),
        child: Scaffold(
          body: PremiumMessageFilterStrip(
            selected: MessagePlatformFilter.all,
            onSelected: (_) {},
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('PremiumMessageFilterStrip compact widths', () {
    for (final profile in _compactWidths) {
      testWidgets(
        '${profile.name} — Arama reachable via scroll',
        (tester) async {
          await _pumpStrip(tester, profile.width);
          expect(tester.takeException(), isNull);

          await tester.drag(find.byKey(_scrollKey), const Offset(-480, 0));
          await tester.pumpAndSettle();

          expect(find.text('Arama'), findsOneWidget);
          final rect = tester.getRect(find.text('Arama'));
          expect(rect.right, lessThanOrEqualTo(profile.width));
        },
      );
    }
  });
}
