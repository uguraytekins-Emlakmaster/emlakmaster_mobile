import 'dart:async';

import 'package:emlakmaster_mobile/core/platform/io_platform_stub.dart'
    if (dart.library.io) 'dart:io' as io;

import 'package:emlakmaster_mobile/core/logging/app_logger.dart';
import 'package:emlakmaster_mobile/core/services/settings_service.dart';
import 'package:emlakmaster_mobile/features/calls/data/device_call_log_sync_service.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/widgets.dart' show AppLifecycleState, WidgetsBinding;
import 'package:phone_state/phone_state.dart';

import '../domain/axion_phone_matcher.dart';
import 'axion_capture_dismiss_store.dart';
import 'axion_capture_notification.dart';
import 'axion_device_contact_directory.dart';

/// Çağrı bitişini ANINDA yakalar (Android) ve numara CRM'de kayıtlı
/// değilse kaydetme önerir:
/// - Uygulama öndeyse → premium kayıt pop-up'ı (host callback'i).
/// - Arka plandaysa → aksiyonlu sistem bildirimi (uygulamaya girmeden
///   isim yazıp kaydetme).
///
/// Kurallar:
/// - Yalnızca Android; izin İSTEMEZ (READ_PHONE_STATE verilmemişse
///   akış sessizce devre dışı kalır, mevcut açılış senkronu çalışmaya
///   devam eder).
/// - Bildirim ayarlarına saygılıdır (ana anahtar + Axion Agent kategorisi
///   + sessiz saatler).
/// - Aynı numara için 30 dk içinde en fazla bir öneri (oturum içi).
/// - Snöz/yoksay edilen numaralar önerilmez.
class AxionPostCallWatcher {
  AxionPostCallWatcher._();
  static final AxionPostCallWatcher instance = AxionPostCallWatcher._();

  static const Duration _perNumberThrottle = Duration(minutes: 30);

  /// Çağrı bitti → çağrı günlüğüne yazılması için kısa bekleme.
  static const Duration _callLogSettle = Duration(seconds: 2);

  StreamSubscription<PhoneState>? _sub;
  String? _activeNumber;
  bool _sawActiveCall = false;
  final Map<String, DateTime> _recentlySuggested = {};

  String Function()? _advisorId;
  Set<String> Function()? _knownPhoneKeys;
  void Function(String rawNumber, String? contactName)? _onForegroundCandidate;

  bool get _supported => !kIsWeb && io.Platform.isAndroid;

  /// Host (danışman kabuğu) tarafından başlatılır.
  void start({
    required String Function() advisorId,
    required Set<String> Function() knownPhoneKeys,
    required void Function(String rawNumber, String? contactName)
        onForegroundCandidate,
  }) {
    if (!_supported) return;
    _advisorId = advisorId;
    _knownPhoneKeys = knownPhoneKeys;
    _onForegroundCandidate = onForegroundCandidate;
    if (_sub != null) return;
    try {
      _sub = PhoneState.stream.listen(
        _onPhoneState,
        onError: (Object e) {
          // İzin yoksa platform hata verebilir — akış sessizce kapanır.
          AppLogger.e('AxionPostCallWatcher stream', e);
          stop();
        },
      );
    } catch (e, st) {
      AppLogger.e('AxionPostCallWatcher start', e, st);
    }
  }

  void stop() {
    _sub?.cancel();
    _sub = null;
    _activeNumber = null;
    _sawActiveCall = false;
  }

  void _onPhoneState(PhoneState state) {
    switch (state.status) {
      case PhoneStateStatus.CALL_INCOMING:
      case PhoneStateStatus.CALL_OUTGOING:
      case PhoneStateStatus.CALL_STARTED:
        _sawActiveCall = true;
        final n = state.number?.trim();
        if (n != null && n.isNotEmpty) _activeNumber = n;
      case PhoneStateStatus.CALL_ENDED:
        final number = state.number?.trim().isNotEmpty == true
            ? state.number!.trim()
            : _activeNumber;
        final hadCall = _sawActiveCall;
        _activeNumber = null;
        _sawActiveCall = false;
        if (!hadCall || number == null || number.isEmpty) return;
        unawaited(_handleCallEnded(number));
      case PhoneStateStatus.NOTHING:
        break;
    }
  }

  Future<void> _handleCallEnded(String rawNumber) async {
    try {
      final key = AxionPhoneMatcher.normalize(rawNumber);
      if (!AxionPhoneMatcher.isMeaningful(key)) return;

      // Oturum içi tekrar koruması (aynı numara art arda aranabilir).
      final now = DateTime.now();
      final last = _recentlySuggested[key];
      if (last != null && now.difference(last) < _perNumberThrottle) return;

      // CRM'de zaten kayıtlı mı?
      final known = _knownPhoneKeys?.call() ?? const <String>{};
      if (known.contains(key)) return;

      // Snöz / yoksay edilmiş mi?
      if (await AxionCaptureDismissStore.instance.isSuppressed(key)) return;

      // Bildirim ayarları (ana anahtar + Axion Agent kategorisi + sessiz saat).
      final allowed =
          await SettingsService.instance.isNotificationAllowed('agent');
      if (!allowed) return;

      _recentlySuggested[key] = now;

      // Çağrı günlüğü yazılsın; sonra sessiz senkron (izin İSTEMEDEN).
      await Future<void>.delayed(_callLogSettle);
      final advisorId = _advisorId?.call() ?? '';
      if (advisorId.isNotEmpty &&
          await DeviceCallLogSyncService.instance.hasCallLogPermission()) {
        unawaited(
          DeviceCallLogSyncService.instance
              .syncCallLogToFirestore(advisorId)
              .catchError((Object _) => DeviceCallLogSyncResult.error),
        );
      }

      // Rehberde kayıtlı isim (varsa) — uydurma isim asla üretilmez.
      final names =
          await AxionDeviceContactDirectory.instance.namesByPhoneKey();
      final contactName = names[key];

      final lifecycle = WidgetsBinding.instance.lifecycleState;
      if (lifecycle == AppLifecycleState.resumed) {
        _onForegroundCandidate?.call(rawNumber, contactName);
      } else {
        await AxionCaptureNotification.instance.showQuickSave(
          rawNumber: rawNumber,
          contactName: contactName,
        );
      }
    } catch (e, st) {
      AppLogger.e('AxionPostCallWatcher._handleCallEnded', e, st);
    }
  }
}
