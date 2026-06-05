import 'package:emlakmaster_mobile/features/campaigns/presentation/providers/bulk_campaign_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('bulkCampaignFiltersProvider updates via notifier without crash', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final notifier = container.read(bulkCampaignFiltersProvider.notifier);
    notifier.apply(
      const BulkCampaignFilters(
        minBudgetMillions: 2,
        maxBudgetMillions: 8,
        minLeadTemperature: 0.5,
        requireRecentInteraction: false,
        requireNoRecentInteraction: true,
        regionQuery: 'Maslak',
      ),
    );

    final state = container.read(bulkCampaignFiltersProvider);
    expect(state.minBudgetMillions, 2);
    expect(state.regionQuery, 'Maslak');
  });

  test('bulkCampaignMessageProvider updates via notifier', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container.read(bulkCampaignMessageProvider.notifier).setMessage('Test mesaj');
    expect(container.read(bulkCampaignMessageProvider), 'Test mesaj');
  });
}
