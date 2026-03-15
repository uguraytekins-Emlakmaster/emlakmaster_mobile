import 'package:equatable/equatable.dart';

/// Çağrı yönü (enum zaten == ve hashCode sağlar)
enum CallDirection {
  incoming('incoming'),
  outgoing('outgoing');

  const CallDirection(this.id);
  final String id;
}

/// Çağrı durumu / sonucu
enum CallOutcome {
  connected('connected'),
  missed('missed'),
  noAnswer('no_answer'),
  busy('busy'),
  failed('failed');

  const CallOutcome(this.id);
  final String id;
}

/// Çağrı entity (domain); Firestore'dan map'lenir.
class CallEntity with EquatableMixin {
  const CallEntity({
    required this.id,
    required this.officeId,
    required this.advisorId,
    this.customerId,
    required this.direction,
    this.phoneNumber,
    required this.startedAt,
    this.connectedAt,
    this.endedAt,
    this.durationSeconds,
    this.outcome,
    this.aiSummaryId,
    this.leadTemperature,
    this.needsReview = false,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String officeId;
  final String advisorId;
  final String? customerId;
  final CallDirection direction;
  final String? phoneNumber;
  final DateTime startedAt;
  final DateTime? connectedAt;
  final DateTime? endedAt;
  final int? durationSeconds;
  final CallOutcome? outcome;
  final String? aiSummaryId;
  final double? leadTemperature;
  final bool needsReview;
  final DateTime createdAt;
  final DateTime updatedAt;

  @override
  List<Object?> get props => [id, startedAt, updatedAt];
}
