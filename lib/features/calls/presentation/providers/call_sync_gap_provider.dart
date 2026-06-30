import 'package:call_log/call_log.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emlakmaster_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/providers/consultant_calls_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Danışman için son 24 saatte cihaz çağrı sayısı ile CRM'e düşen cihaz çağrı
/// sayısı arasındaki fark.
class CallSyncGapSnapshot {
  const CallSyncGapSnapshot({
    required this.deviceCount24h,
    required this.crmDeviceCount24h,
  });

  final int deviceCount24h;
  final int crmDeviceCount24h;

  int get gap => deviceCount24h - crmDeviceCount24h;
  bool get hasGap => gap > 0;
}

final callSyncGapProvider = FutureProvider.autoDispose<CallSyncGapSnapshot?>(
  (ref) async {
    try {
      final uid = ref.watch(
        currentUserProvider.select((a) => a.valueOrNull?.uid ?? ''),
      );
      if (uid.isEmpty) return null;

      // CRM tarafı (mevcut stream verisi): son 24 saatte source=device kayıtları.
      final docs =
          ref.watch(consultantCallsStreamProvider).valueOrNull?.docs ?? const [];
      final cutoffMs =
          DateTime.now().subtract(const Duration(hours: 24)).millisecondsSinceEpoch;
      var crmDevice = 0;
      for (final d in docs) {
        final data = d.data();
        if ((data['source'] as String? ?? '') != 'device') continue;
        final created = data['createdAt'];
        final createdMs = switch (created) {
          final Timestamp ts => ts.millisecondsSinceEpoch,
          _ => null,
        };
        if (createdMs == null || createdMs < cutoffMs) continue;
        crmDevice++;
      }

      // Cihaz tarafı: son 24 saat çağrı günlüğü.
      final entries = await CallLog.query(dateFrom: cutoffMs, durationFrom: 0);
      var device = 0;
      for (final e in entries) {
        final number = e.number?.trim();
        if (number == null || number.isEmpty) continue;
        device++;
      }

      return CallSyncGapSnapshot(deviceCount24h: device, crmDeviceCount24h: crmDevice);
    } catch (_) {
      return null;
    }
  },
);

