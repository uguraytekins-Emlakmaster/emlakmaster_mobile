import 'package:equatable/equatable.dart';

/// Hands-Free CRM: ses notundan çıkarılan yapılandırılmış aksiyon.
class VoiceCrmIntent with EquatableMixin {
  const VoiceCrmIntent({
    this.updateLead,
    this.addOffer,
    this.setReminderAt,
    this.rawSummary,
  });

  final String? updateLead;
  final ({String? customerId, double? amount})? addOffer;
  final DateTime? setReminderAt;
  final String? rawSummary;

  @override
  List<Object?> get props => [updateLead, addOffer, setReminderAt, rawSummary];
}
