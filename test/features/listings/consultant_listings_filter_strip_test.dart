import 'package:emlakmaster_mobile/core/theme/app_theme.dart';
import 'package:emlakmaster_mobile/features/listings/presentation/utils/listing_list_filter.dart';
import 'package:emlakmaster_mobile/features/listings/presentation/widgets/consultant_listings_chrome.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _compactWidths = <({String name, double width})>[
  (name: 'iPhone 14', width: 390),
  (name: 'Android normal', width: 430),
];

const _scrollKey = Key('listing_filter_strip_scroll');

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
          body: PremiumListingFilterStrip(
            selected: ListingListFilter.all,
            onSelected: (_) {},
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('PremiumListingFilterStrip compact widths', () {
    for (final profile in _compactWidths) {
      testWidgets(
        '${profile.name} (${profile.width.toInt()}px) — Dikkat reachable via scroll',
        (tester) async {
          await _pumpStrip(tester, profile.width);
          expect(tester.takeException(), isNull);

          await tester.drag(find.byKey(_scrollKey), const Offset(-420, 0));
          await tester.pumpAndSettle();

          expect(find.text('Dikkat'), findsOneWidget);
          final rect = tester.getRect(find.text('Dikkat'));
          expect(rect.right, lessThanOrEqualTo(profile.width));
          expect(rect.left, greaterThanOrEqualTo(0));
        },
      );

      testWidgets(
        '${profile.name} (${profile.width.toInt()}px) — no overflow',
        (tester) async {
          await _pumpStrip(tester, profile.width);
          expect(tester.takeException(), isNull);
        },
      );
    }
  });
}
