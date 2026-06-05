import 'package:emlakmaster_mobile/features/crm_customers/domain/customer_heat_score.dart';
import 'package:emlakmaster_mobile/features/resurrection_engine/domain/entities/resurrection_segment.dart';

/// Takip Merkezi filtre şeridi — yalnızca gerçek kuyruk alanları.
enum FollowUpListFilter {
  all,
  today,
  overdue,
  callback,
  cold,
  hot,
  opportunity,
}

extension FollowUpListFilterLabels on FollowUpListFilter {
  String get label => switch (this) {
        FollowUpListFilter.all => 'Tümü',
        FollowUpListFilter.today => 'Bugün',
        FollowUpListFilter.overdue => 'Geciken',
        FollowUpListFilter.callback => 'Aranacak',
        FollowUpListFilter.cold => 'Soğuk',
        FollowUpListFilter.hot => 'Sıcak',
        FollowUpListFilter.opportunity => 'Fırsat',
      };
}

class FollowUpListSummary {
  const FollowUpListSummary({
    required this.todayFollowUp,
    required this.overdue,
    required this.callback,
    required this.coldLeads,
    required this.opportunity,
  });

  final int todayFollowUp;
  final int overdue;
  final int callback;
  final int coldLeads;
  final int opportunity;

  static const empty = FollowUpListSummary(
    todayFollowUp: 0,
    overdue: 0,
    callback: 0,
    coldLeads: 0,
    opportunity: 0,
  );
}

bool followUpItemIsCold(ResurrectionQueueItem item) {
  final heat = item.heatLevel;
  if (heat == null) {
    return item.segment == ResurrectionSegment.silent30;
  }
  return heat == CustomerHeatLevel.cold || heat == CustomerHeatLevel.cool;
}

bool followUpItemIsHot(ResurrectionQueueItem item) {
  final heat = item.heatLevel;
  if (heat == null) return false;
  return heat == CustomerHeatLevel.hot || heat == CustomerHeatLevel.warm;
}

bool followUpItemHasOpportunity(ResurrectionQueueItem item) {
  final action = item.nextSuggestedAction?.trim();
  return action != null && action.isNotEmpty;
}

bool followUpItemMatchesSearch(ResurrectionQueueItem item, String query) {
  if (query.isEmpty) return true;
  final q = query.toLowerCase();
  bool hit(String? s) => s != null && s.toLowerCase().contains(q);
  return hit(item.customerName) ||
      hit(item.primaryPhone) ||
      hit(item.customerId) ||
      hit(item.lastCallSummary) ||
      hit(item.nextSuggestedAction) ||
      hit(item.segment?.label);
}

bool matchesFollowUpListFilter(
  ResurrectionQueueItem item,
  FollowUpListFilter filter,
  String searchQuery,
) {
  if (!followUpItemMatchesSearch(item, searchQuery)) return false;
  return switch (filter) {
    FollowUpListFilter.all => true,
    FollowUpListFilter.today =>
      item.segment == ResurrectionSegment.silent7,
    FollowUpListFilter.overdue => (item.daysSilent ?? 0) >= 14,
    FollowUpListFilter.callback => item.hasCallablePhone,
    FollowUpListFilter.cold => followUpItemIsCold(item),
    FollowUpListFilter.hot => followUpItemIsHot(item),
    FollowUpListFilter.opportunity => followUpItemHasOpportunity(item),
  };
}

FollowUpListSummary computeFollowUpListSummary(
  Iterable<ResurrectionQueueItem> items,
) {
  var today = 0;
  var overdue = 0;
  var callback = 0;
  var cold = 0;
  var opportunity = 0;

  for (final item in items) {
    if (item.segment == ResurrectionSegment.silent7) today++;
    if ((item.daysSilent ?? 0) >= 14) overdue++;
    if (item.hasCallablePhone) callback++;
    if (followUpItemIsCold(item)) cold++;
    if (followUpItemHasOpportunity(item)) opportunity++;
  }

  return FollowUpListSummary(
    todayFollowUp: today,
    overdue: overdue,
    callback: callback,
    coldLeads: cold,
    opportunity: opportunity,
  );
}

bool followUpRowNeedsUrgentEmphasis(ResurrectionQueueItem item) {
  if ((item.daysSilent ?? 0) >= 30) return true;
  if (item.heatLevel == CustomerHeatLevel.hot) return true;
  return item.segment == ResurrectionSegment.silent30;
}
