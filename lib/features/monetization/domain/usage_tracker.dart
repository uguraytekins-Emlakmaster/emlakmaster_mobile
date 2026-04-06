import 'package:equatable/equatable.dart';

class UsageTracker extends Equatable {
  const UsageTracker({
    required this.userId,
    required this.aiUsageThisMonth,
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
      aiUsageThisMonth: 0,
      periodStart: DateTime(stamp.year, stamp.month, stamp.day),
      isPro: isPro,
    );
  }

  final String userId;
  final int aiUsageThisMonth;
  final DateTime periodStart;
  final bool isPro;

  bool get isFree => !isPro;

  bool get isAiLimitReached => aiUsageThisMonth >= 20;

  double get aiUsagePercent => aiUsageThisMonth / 20;

  bool get isNearAiLimit => aiUsagePercent >= 0.8;

  UsageTracker copyWith({
    String? userId,
    int? aiUsageThisMonth,
    DateTime? periodStart,
    bool? isPro,
  }) {
    return UsageTracker(
      userId: userId ?? this.userId,
      aiUsageThisMonth: aiUsageThisMonth ?? this.aiUsageThisMonth,
      periodStart: periodStart ?? this.periodStart,
      isPro: isPro ?? this.isPro,
    );
  }

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'aiUsageThisMonth': aiUsageThisMonth,
        'periodStartMs': periodStart.millisecondsSinceEpoch,
        'isPro': isPro,
      };

  static UsageTracker? tryParse(Map<String, dynamic>? raw) {
    if (raw == null) return null;
    final userId = (raw['userId'] as String?)?.trim() ?? '';
    if (userId.isEmpty) return null;
    return UsageTracker(
      userId: userId,
      aiUsageThisMonth: (raw['aiUsageThisMonth'] as num?)?.toInt() ?? 0,
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
        aiUsageThisMonth,
        periodStart,
        isPro,
      ];
}
