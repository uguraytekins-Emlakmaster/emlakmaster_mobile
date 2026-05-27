import 'package:emlakmaster_mobile/features/crm_customers/domain/customer_heat_score.dart';
import 'package:equatable/equatable.dart';

/// Sessiz kalma segmenti (Silent Lead Resurrection kuralları).
enum ResurrectionSegment {
  silent7('7_days', 7, '7 gün sessiz'),
  silent14('14_days', 14, '14 gün sessiz'),
  silent30('30_plus_days', 30, '30+ gün sessiz');

  const ResurrectionSegment(this.id, this.daysThreshold, this.label);
  final String id;
  final int daysThreshold;
  final String label;
}

/// Yeniden kazanım kuyruğu öğesi.
class ResurrectionQueueItem with EquatableMixin {
  const ResurrectionQueueItem({
    required this.customerId,
    required this.customerName,
    this.primaryPhone,
    this.segment,
    this.daysSilent,
    this.suggestedMessagePlaceholder,
    this.suggestedListingIds = const [],
    this.lastInteractionAt,
    this.nextSuggestedAction,
    this.lastCallSummary,
    this.heatLevel,
    this.heatScore,
  });

  final String customerId;
  final String? customerName;
  final String? primaryPhone;
  final ResurrectionSegment? segment;
  final int? daysSilent;
  /// Şablon mesaj — AI üretimi değil.
  final String? suggestedMessagePlaceholder;
  final List<String> suggestedListingIds;
  final DateTime? lastInteractionAt;
  final String? nextSuggestedAction;
  final String? lastCallSummary;
  final CustomerHeatLevel? heatLevel;
  final int? heatScore;

  bool get hasCallablePhone =>
      primaryPhone != null && primaryPhone!.trim().isNotEmpty;

  @override
  List<Object?> get props => [customerId, segment, daysSilent];
}
