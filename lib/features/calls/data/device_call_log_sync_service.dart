import 'package:emlakmaster_mobile/core/platform/io_platform_stub.dart'
    if (dart.library.io) 'dart:io' as io;

import 'package:call_log/call_log.dart';
import 'package:emlakmaster_mobile/core/services/firestore_service.dart';
import 'package:emlakmaster_mobile/core/analytics/analytics_events.dart';
import 'package:emlakmaster_mobile/core/services/analytics_service.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

/// Cihaz çağrı günlüğü senkronizasyon sonucu.
enum DeviceCallLogSyncResult {
  success,
  permissionDenied,
  permissionPermanentlyDenied,
  notSupported,
  error,
}

/// Cihazdan (normal telefondan) gelen/giden çağrıları Firestore'a yazar.
/// Sadece Android desteklenir; iOS çağrı günlüğü API sunmaz.
class DeviceCallLogSyncService {
  DeviceCallLogSyncService._();
  static final DeviceCallLogSyncService instance = DeviceCallLogSyncService._();

  static const int _maxDaysBack = 90;
  static const int _maxEntries = 500;

  /// Çağrı günlüğü iznini iste (Android: READ_CALL_LOG / READ_PHONE_NUMBERS).
  Future<bool> requestCallLogPermission() async {
    if (!io.Platform.isAndroid) return false;
    final status = await Permission.phone.request();
    return status.isGranted;
  }

  /// İzin verilmiş mi?
  Future<bool> hasCallLogPermission() async {
    if (!io.Platform.isAndroid) return false;
    return (await Permission.phone.status).isGranted;
  }

  /// Cihaz çağrı günlüğünü okuyup danışman için Firestore'a yazar.
  /// [advisorId] giriş yapan kullanıcı uid.
  Future<DeviceCallLogSyncResult> syncCallLogToFirestore(String advisorId) async {
    if (advisorId.isEmpty) return DeviceCallLogSyncResult.error;
    if (!io.Platform.isAndroid) return DeviceCallLogSyncResult.notSupported;

    final hasPermission = await hasCallLogPermission();
    if (!hasPermission) {
      final requested = await requestCallLogPermission();
      if (!requested) {
        final status = await Permission.phone.status;
        AnalyticsService.instance.logEvent(AnalyticsEvents.callsDevicePermissionDenied, {
          AnalyticsEvents.paramPermanently: status.isPermanentlyDenied,
        });
        return status.isPermanentlyDenied
            ? DeviceCallLogSyncResult.permissionPermanentlyDenied
            : DeviceCallLogSyncResult.permissionDenied;
      }
    }

    try {
      final from = DateTime.now().subtract(const Duration(days: _maxDaysBack));
      final fromMs = from.millisecondsSinceEpoch;
      final entries = await CallLog.query(
        dateFrom: fromMs,
        durationFrom: 0,
      );
      int count = 0;
      int taken = 0;
      for (final entry in entries) {
        if (taken >= _maxEntries) break;
        final number = entry.number?.trim();
        if (number == null || number.isEmpty) continue;

        final ts = entry.timestamp ?? 0;
        final durationSec = _parseDuration(entry.duration);
        final direction = _mapCallType(entry.callType);
        final docId = _documentId(ts, number);
        final isMissed = entry.callType == CallType.missed;
        await FirestoreService.setCallRecordFromDevice(
          documentId: docId,
          advisorId: advisorId,
          direction: direction,
          timestampMillis: ts,
          durationSeconds: durationSec,
          phoneNumber: number,
          outcome: isMissed ? 'missed' : 'connected',
        );
        count++;
        taken++;
      }
      if (kDebugMode) debugPrint('DeviceCallLogSync: $count entries synced.');
      AnalyticsService.instance.logEvent(AnalyticsEvents.callsDeviceSyncSuccess, {
        AnalyticsEvents.paramSyncedCount: count,
      });
      return DeviceCallLogSyncResult.success;
    } catch (e, st) {
      if (kDebugMode) debugPrint('DeviceCallLogSync error: $e $st');
      AnalyticsService.instance.logEvent(AnalyticsEvents.callsDeviceSyncError);
      return DeviceCallLogSyncResult.error;
    }
  }

  int? _parseDuration(dynamic duration) {
    if (duration == null) return null;
    if (duration is int) return duration;
    if (duration is String) return int.tryParse(duration);
    return null;
  }

  String _mapCallType(CallType? callType) {
    if (callType == null) return 'outgoing';
    switch (callType) {
      case CallType.incoming:
      case CallType.wifiIncoming:
        return 'incoming';
      case CallType.outgoing:
      case CallType.wifiOutgoing:
        return 'outgoing';
      case CallType.missed:
      case CallType.rejected:
      case CallType.blocked:
        return 'missed';
      default:
        return 'outgoing';
    }
  }

  /// Firestore doc id: tekilleştirme (aynı çağrı tekrar yazılmaz).
  String _documentId(int timestampMillis, String number) {
    final normalized = number.replaceAll(RegExp(r'\D'), '');
    return 'device_${timestampMillis}_${normalized.isEmpty ? "unknown" : normalized}';
  }
}
