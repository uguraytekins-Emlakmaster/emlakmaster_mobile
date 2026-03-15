import 'package:emlakmaster_mobile/features/resurrection_engine/domain/entities/resurrection_segment.dart';
import 'package:emlakmaster_mobile/shared/models/customer_models.dart';

/// Sessiz lead'leri filtreleyip resurrection kuyruğu üretir.
class GetResurrectionQueue {
  static const String suggestedMessagePlaceholder =
      'Size özel yeni bir portföyümüz var. İsterseniz kısa bir görüşme planlayalım.';

  List<ResurrectionQueueItem> call(List<CustomerEntity> customers) {
    final now = DateTime.now();
    final items = <ResurrectionQueueItem>[];
    for (final c in customers) {
      final last = c.lastInteractionAt;
      if (last == null) continue;
      final days = now.difference(last).inDays;
      ResurrectionSegment? segment;
      if (days >= 30) {
        segment = ResurrectionSegment.silent30;
      } else if (days >= 14) {
        segment = ResurrectionSegment.silent14;
      } else if (days >= 7) {
        segment = ResurrectionSegment.silent7;
      } else {
        continue;
      }
      items.add(ResurrectionQueueItem(
        customerId: c.id,
        customerName: c.fullName,
        primaryPhone: c.primaryPhone,
        segment: segment,
        daysSilent: days,
        suggestedMessagePlaceholder: suggestedMessagePlaceholder,
        suggestedListingIds: [],
      ));
    }
    items.sort((a, b) => (b.daysSilent ?? 0).compareTo(a.daysSilent ?? 0));
    return items;
  }
}
