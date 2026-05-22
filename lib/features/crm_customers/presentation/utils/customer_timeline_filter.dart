import 'package:emlakmaster_mobile/features/crm_customers/presentation/models/customer_timeline_row.dart';
import 'package:emlakmaster_mobile/features/customer_timeline/domain/entities/timeline_item.dart';

/// Akış sekmesi zaman çizelgesi filtresi.
enum CustomerTimelineFilter {
  all,
  note,
  offer,
  visit,
  call,
}

extension CustomerTimelineFilterLabels on CustomerTimelineFilter {
  String get labelTr {
    switch (this) {
      case CustomerTimelineFilter.all:
        return 'Tümü';
      case CustomerTimelineFilter.note:
        return 'Not';
      case CustomerTimelineFilter.offer:
        return 'Teklif';
      case CustomerTimelineFilter.visit:
        return 'Ziyaret';
      case CustomerTimelineFilter.call:
        return 'Çağrı';
    }
  }
}

abstract final class CustomerTimelineFilterLogic {
  CustomerTimelineFilterLogic._();

  static bool matches(CustomerTimelineRow row, CustomerTimelineFilter filter) {
    switch (filter) {
      case CustomerTimelineFilter.all:
        return true;
      case CustomerTimelineFilter.note:
        return row.type == TimelineItemType.note;
      case CustomerTimelineFilter.offer:
        return row.type == TimelineItemType.offer;
      case CustomerTimelineFilter.visit:
        return row.type == TimelineItemType.visit;
      case CustomerTimelineFilter.call:
        return row.type == TimelineItemType.call ||
            row.type == TimelineItemType.callSummary;
    }
  }
}
