import 'package:equatable/equatable.dart';

/// Teklif durumu.
enum OfferStatus {
  draft('draft', 'Taslak'),
  sent('sent', 'Gönderildi'),
  viewed('viewed', 'Görüntülendi'),
  negotiated('negotiated', 'Pazarlık'),
  accepted('accepted', 'Kabul'),
  rejected('rejected', 'Red');

  const OfferStatus(this.id, this.label);
  final String id;
  final String label;

  static OfferStatus fromId(String? id) {
    if (id == null || id.isEmpty) return OfferStatus.draft;
    return OfferStatus.values.firstWhere(
      (e) => e.id == id,
      orElse: () => OfferStatus.draft,
    );
  }
}

/// Teklif entity (One-Click Offer Flow).
class OfferEntity with EquatableMixin {
  const OfferEntity({
    required this.id,
    required this.customerId,
    required this.listingId,
    required this.advisorId,
    this.pipelineItemId,
    this.amount,
    this.currency = 'TRY',
    this.status = OfferStatus.draft,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String customerId;
  final String listingId;
  final String advisorId;
  final String? pipelineItemId;
  final double? amount;
  final String currency;
  final OfferStatus status;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  @override
  List<Object?> get props => [id, status, updatedAt];
}
