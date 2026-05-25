import 'package:emlakmaster_mobile/core/theme/app_theme.dart';
import 'package:emlakmaster_mobile/features/campaigns/presentation/pages/bulk_campaign_page.dart';
import 'package:emlakmaster_mobile/features/campaigns/presentation/providers/bulk_campaign_providers.dart';
import 'package:emlakmaster_mobile/shared/models/customer_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('BulkCampaignPage builds without Riverpod dispose crash', (tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          bulkCampaignSegmentProvider.overrideWith(
            (ref) => Stream.value(
              const BulkCampaignSegment(name: 'Test', customers: []),
            ),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.dark(),
          home: const BulkCampaignPage(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('DEV'), findsNothing);
    expect(find.byType(BulkCampaignPage), findsOneWidget);
  });

  testWidgets('BulkCampaignPage filter chip tap does not throw', (tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          bulkCampaignSegmentProvider.overrideWith(
            (ref) => Stream.value(
              BulkCampaignSegment(
                name: 'Test',
                customers: [
                  CustomerEntity(
                    id: 'c1',
                    fullName: 'Test',
                    primaryPhone: '+905551112233',
                    leadTemperature: 0.8,
                    createdAt: DateTime(2024),
                    updatedAt: DateTime(2024),
                  ),
                ],
              ),
            ),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.dark(),
          home: const BulkCampaignPage(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    await tester.tap(find.text('Son 30 günde çağrı yapıldı'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(BulkCampaignPage), findsOneWidget);
  });
}
