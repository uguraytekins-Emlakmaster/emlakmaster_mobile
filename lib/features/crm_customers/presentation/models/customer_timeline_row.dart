import 'package:emlakmaster_mobile/features/customer_timeline/domain/entities/timeline_item.dart';

/// Müşteri detay zaman çizelgesi satırı (birleşik stream çıktısı).
class CustomerTimelineRow {
  const CustomerTimelineRow({
    required this.id,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.at,
  });

  final String id;
  final TimelineItemType type;
  final String title;
  final String subtitle;
  final DateTime at;
}
