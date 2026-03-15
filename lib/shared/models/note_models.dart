import 'package:equatable/equatable.dart';

/// Not entity (Customer Memory Timeline).
class NoteEntity with EquatableMixin {
  const NoteEntity({
    required this.id,
    this.customerId,
    this.listingId,
    required this.authorId,
    this.content,
    this.isPinned = false,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String? customerId;
  final String? listingId;
  final String authorId;
  final String? content;
  final bool isPinned;
  final DateTime createdAt;
  final DateTime updatedAt;

  @override
  List<Object?> get props => [id, updatedAt];
}
