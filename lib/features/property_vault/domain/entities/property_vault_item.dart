import 'package:equatable/equatable.dart';

/// Mülk Sağlık Karnesi: tek bir kayıt (tadilat faturası, eski fotoğraf, DASK raporu vb.).
class PropertyVaultItem with EquatableMixin {
  const PropertyVaultItem({
    required this.id,
    required this.listingId,
    required this.type,
    this.title,
    this.description,
    this.attachmentUrl,
    this.occurredAt,
    this.createdAt,
  });

  final String id;
  final String listingId;
  final PropertyVaultItemType type;
  final String? title;
  final String? description;
  final String? attachmentUrl;
  final DateTime? occurredAt;
  final DateTime? createdAt;

  @override
  List<Object?> get props => [id, listingId, type];
}

enum PropertyVaultItemType {
  renovationInvoice('renovation_invoice', 'Tadilat faturası'),
  pastPhoto('past_photo', 'Eski fotoğraf'),
  technicalReport('technical_report', 'Teknik rapor (DASK/deprem)'),
  other('other', 'Diğer');

  const PropertyVaultItemType(this.id, this.label);
  final String id;
  final String label;
}
