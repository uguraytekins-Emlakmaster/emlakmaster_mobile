import 'package:equatable/equatable.dart';

/// Görev durumu.
enum TaskStatus {
  pending('pending', 'Bekliyor'),
  inProgress('in_progress', 'Devam'),
  completed('completed', 'Tamamlandı'),
  cancelled('cancelled', 'İptal');

  const TaskStatus(this.id, this.label);
  final String id;
  final String label;

  static TaskStatus fromId(String? id) {
    if (id == null || id.isEmpty) return TaskStatus.pending;
    return TaskStatus.values.firstWhere(
      (e) => e.id == id,
      orElse: () => TaskStatus.pending,
    );
  }
}

/// Görev entity (automation, follow-up, Magic Follow-Up).
class TaskEntity with EquatableMixin {
  const TaskEntity({
    required this.id,
    this.customerId,
    this.listingId,
    required this.advisorId,
    this.title,
    this.description,
    this.dueAt,
    this.completedAt,
    this.status = TaskStatus.pending,
    this.source, // 'call_summary', 'visit', 'resurrection', 'manual'
    this.sourceId,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String? customerId;
  final String? listingId;
  final String advisorId;
  final String? title;
  final String? description;
  final DateTime? dueAt;
  final DateTime? completedAt;
  final TaskStatus status;
  final String? source;
  final String? sourceId;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isOverdue =>
      dueAt != null && status != TaskStatus.completed && status != TaskStatus.cancelled && dueAt!.isBefore(DateTime.now());

  @override
  List<Object?> get props => [id, status, updatedAt];
}
