import 'package:equatable/equatable.dart';

/// Lead/Customer için stratejik alanlar (Hands-Free CRM, VIP Investor).
class LeadStrategicFields with EquatableMixin {
  const LeadStrategicFields({
    this.voiceNoteSummary,
    this.voiceNoteSummaryUpdatedAt,
    this.isVipInvestor = false,
    this.investmentAlertEnabled = false,
  });

  final String? voiceNoteSummary;
  final DateTime? voiceNoteSummaryUpdatedAt;
  final bool isVipInvestor;
  final bool investmentAlertEnabled;

  @override
  List<Object?> get props => [voiceNoteSummary, voiceNoteSummaryUpdatedAt, isVipInvestor, investmentAlertEnabled];
}
