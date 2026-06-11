import 'package:emlakmaster_mobile/core/platform/io_platform_stub.dart'
    if (dart.library.io) 'dart:io' as io;

import 'package:emlakmaster_mobile/core/logging/app_logger.dart';
import 'package:emlakmaster_mobile/features/calls/data/device_call_log_sync_service.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

/// Sessiz, kısıtlı cihaz çağrı günlüğü senkronu.
///
/// Amaç: danışman hiçbir şey yapmasa bile yeni aramalar CRM'e aksın ve
/// Axion Agent kayıtsız numaraları yakalayabilsin.
///
/// Kurallar (pil + gizlilik dostu):
/// - Yalnızca Android; izin DAHA ÖNCE verilmişse çalışır (asla izin sormaz)
/// - 15 dakikada en fazla bir kez (uygulama açılış/öne gelme tetikler)
/// - Hata sessizce loglanır; UI'yı asla bloklamaz
class AxionCallLogAutoSync {
  AxionCallLogAutoSync._();
  static final AxionCallLogAutoSync instance = AxionCallLogAutoSync._();

  static const Duration minInterval = Duration(minutes: 15);

  DateTime? _lastRunAt;
  bool _running = false;

  /// Uygun koşullarda senkron dener; her durumda hızla döner.
  Future<void> maybeSync(String advisorId) async {
    if (advisorId.isEmpty) return;
    if (kIsWeb || !io.Platform.isAndroid) return;
    if (_running) return;

    final now = DateTime.now();
    final last = _lastRunAt;
    if (last != null && now.difference(last) < minInterval) return;

    _running = true;
    _lastRunAt = now;
    try {
      final hasPermission =
          await DeviceCallLogSyncService.instance.hasCallLogPermission();
      if (!hasPermission) return; // İzin isteme — kullanıcı Çağrılar'dan verir.
      await DeviceCallLogSyncService.instance
          .syncCallLogToFirestore(advisorId);
    } catch (e, st) {
      AppLogger.e('AxionCallLogAutoSync', e, st);
    } finally {
      _running = false;
    }
  }
}
