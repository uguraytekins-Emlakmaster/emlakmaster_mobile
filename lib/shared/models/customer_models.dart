import 'package:equatable/equatable.dart';

/// Müşteri türü (enum zaten == ve hashCode sağlar; Equatable kullanılmaz)
enum CustomerType {
  residential('residential', 'Oturumluk'),
  investment('investment', 'Yatırım'),
  rental('rental', 'Kiralık'),
  commercial('commercial', 'Ticari'),
  land('land', 'Arsa');

  const CustomerType(this.id, this.label);
  final String id;
  final String label;
}

/// Yaşam döngüsü aşaması
enum LifecycleStage {
  lead('lead', 'Lead'),
  qualified('qualified', 'Nitelenmiş'),
  proposal('proposal', 'Teklif'),
  negotiation('negotiation', 'Pazarlık'),
  closedWon('closed_won', 'Kazanıldı'),
  closedLost('closed_lost', 'Kaybedildi'),
  reactivation('reactivation', 'Yeniden kazanım');

  const LifecycleStage(this.id, this.label);
  final String id;
  final String label;
}

/// Müşteri entity (domain).
class CustomerEntity with EquatableMixin {
  const CustomerEntity({
    required this.id,
    this.fullName,
    this.primaryPhone,
    this.email,
    this.source,
    this.assignedAdvisorId,
    this.customerType,
    this.budgetMin,
    this.budgetMax,
    this.regionPreferences = const [],
    this.leadTemperature,
    this.lifecycleStage,
    this.lastInteractionAt,
    this.nextSuggestedAction,
    this.tags = const [],
    this.callsCount = 0,
    this.visitsCount = 0,
    this.offersCount = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String? fullName;
  final String? primaryPhone;
  final String? email;
  final String? source;
  final String? assignedAdvisorId;
  final CustomerType? customerType;
  final double? budgetMin;
  final double? budgetMax;
  final List<String> regionPreferences;
  final double? leadTemperature;
  final LifecycleStage? lifecycleStage;
  final DateTime? lastInteractionAt;
  final String? nextSuggestedAction;
  final List<String> tags;
  final int callsCount;
  final int visitsCount;
  final int offersCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  @override
  List<Object?> get props => [id, updatedAt];
}
