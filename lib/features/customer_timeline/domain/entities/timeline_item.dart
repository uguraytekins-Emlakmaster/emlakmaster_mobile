import 'package:equatable/equatable.dart';

/// Müşteri timeline öğe tipi (Customer Memory Timeline).
enum TimelineItemType {
  call('call'),
  callSummary('call_summary'),
  note('note'),
  task('task'),
  offer('offer'),
  visit('visit'),
  document('document'),
  notification('notification'),
  aiInsight('ai_insight');

  const TimelineItemType(this.id);
  final String id;
}

/// Tekil timeline kaydı; pagination ve filtre ile kullanılır.
class TimelineItemEntity with EquatableMixin {
  const TimelineItemEntity({
    required this.id,
    required this.type,
    this.title,
    this.subtitle,
    this.payload,
    required this.createdAt,
  });

  final String id;
  final TimelineItemType type;
  final String? title;
  final String? subtitle;
  final Map<String, dynamic>? payload;
  final DateTime createdAt;

  @override
  List<Object?> get props => [id, type, createdAt];
}
