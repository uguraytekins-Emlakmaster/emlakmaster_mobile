import 'package:equatable/equatable.dart';

class UsageTracker extends Equatable {
  const UsageTracker({
    required this.userId,
    required this.callsThisMonth,
    required this.aiUsageThisMonth,
    required this.customersTracked,
    required this.periodStart,
    required this.isPro,
  });

  factory UsageTracker.initial({
    required String userId,
    required bool isPro,
    DateTime? now,
  }) {
    final stamp = now ?? DateTime.now();
    return UsageTracker(
      userId: userId,
      callsThisMonth: 0,
      aiUsageThisMonth: 0,
      customersTracked: 0,
      periodStart: DateTime(stamp.year, stamp.month, stamp.day),
      isPro: isPro,
    );
  }

  final String userId;
  final int callsThisMonth;
  final int aiUsageThisMonth;
  final int customersTracked;
  final DateTime periodStart;
  final bool isPro;

  bool get isFree => !isPro;

  bool get isCallLimitReached => callsThisMonth >= 50;
  bool get isAiLimitReached => aiUsageThisMonth >= 10;
  bool get isCustomerLimitReached => customersTracked >= 30;

  double get callUsagePercent => callsThisMonth / 50;
  double get aiUsagePercent => aiUsageThisMonth / 10;
  double get customerUsagePercent => customersTracked / 30;

  bool get isNearCallLimit => callUsagePercent >= 0.8;
  bool get isNearAiLimit => aiUsagePercent >= 0.8;
  bool get isNearCustomerLimit => customerUsagePercent >= 0.8;

  UsageTracker copyWith({
    String? userId,
    int? callsThisMonth,
    int? aiUsageThisMonth,
    int? customersTracked,
    DateTime? periodStart,
    bool? isPro,
  }) {
    return UsageTracker(
      userId: userId ?? this.userId,
      callsThisMonth: callsThisMonth ?? this.callsThisMonth,
      aiUsageThisMonth: aiUsageThisMonth ?? this.aiUsageThisMonth,
      customersTracked: customersTracked ?? this.customersTracked,
      periodStart: periodStart ?? this.periodStart,
      isPro: isPro ?? this.isPro,
    );
  }

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'callsThisMonth': callsThisMonth,
        'aiUsageThisMonth': aiUsageThisMonth,
        'customersTracked': customersTracked,
        'periodStartMs': periodStart.millisecondsSinceEpoch,
        'isPro': isPro,
      };

  static UsageTracker? tryParse(Map<String, dynamic>? raw) {
    if (raw == null) return null;
    final userId = (raw['userId'] as String?)?.trim() ?? '';
    if (userId.isEmpty) return null;
    return UsageTracker(
      userId: userId,
      callsThisMonth: (raw['callsThisMonth'] as num?)?.toInt() ?? 0,
      aiUsageThisMonth: (raw['aiUsageThisMonth'] as num?)?.toInt() ?? 0,
      customersTracked: (raw['customersTracked'] as num?)?.toInt() ?? 0,
      periodStart: DateTime.fromMillisecondsSinceEpoch(
        (raw['periodStartMs'] as num?)?.toInt() ??
            DateTime.now().millisecondsSinceEpoch,
      ),
      isPro: raw['isPro'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [
        userId,
        callsThisMonth,
        aiUsageThisMonth,
        customersTracked,
        periodStart,
        isPro,
      ];
}
