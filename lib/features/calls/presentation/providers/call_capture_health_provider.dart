import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/providers/consultant_calls_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CallCaptureHealthSnapshot {
  const CallCaptureHealthSnapshot({
    required this.total24h,
    required this.linked24h,
    required this.missedWithoutLink24h,
  });

  final int total24h;
  final int linked24h;
  final int missedWithoutLink24h;

  int get scorePct => total24h == 0 ? 100 : ((linked24h / total24h) * 100).round();
}

final callCaptureHealthProvider = Provider.autoDispose<CallCaptureHealthSnapshot?>(
  (ref) {
    final docs = ref.watch(consultantCallsStreamProvider).valueOrNull?.docs;
    if (docs == null) return null;
    final cutoff = DateTime.now().millisecondsSinceEpoch -
        const Duration(hours: 24).inMilliseconds;
    var total = 0;
    var linked = 0;
    var missedOpen = 0;
    for (final d in docs) {
      final data = d.data();
      final created = data['createdAt'];
      final createdMs = switch (created) {
        final Timestamp ts => ts.millisecondsSinceEpoch,
        _ => null,
      };
      if (createdMs == null || createdMs < cutoff) continue;
      total++;
      final customerId = (data['customerId'] as String? ?? '').trim();
      if (customerId.isNotEmpty) linked++;
      final outcome = (data['outcome'] as String? ?? '').trim();
      if (customerId.isEmpty && outcome == 'missed') missedOpen++;
    }
    return CallCaptureHealthSnapshot(
      total24h: total,
      linked24h: linked,
      missedWithoutLink24h: missedOpen,
    );
  },
);

