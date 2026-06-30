import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emlakmaster_mobile/core/logging/app_logger.dart';
import 'package:emlakmaster_mobile/core/services/firestore_service.dart';
import 'package:emlakmaster_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:emlakmaster_mobile/features/calls/application/call_capture_audit_service.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/providers/consultant_calls_provider.dart';
import 'package:emlakmaster_mobile/features/contact_save/data/save_contact_service.dart';
import 'package:emlakmaster_mobile/features/contact_save/domain/contact_save_request.dart';
import 'package:emlakmaster_mobile/features/crm_customers/presentation/providers/customer_list_stream_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/axion_call_log_auto_sync.dart';
import '../../data/axion_capture_dismiss_store.dart';
import '../../data/axion_capture_notification.dart';
import '../../data/axion_pending_capture_store.dart';
import '../../data/axion_post_call_watcher.dart';
import '../../domain/axion_phone_matcher.dart';
import '../../domain/axion_uncaptured_number.dart';
import '../providers/axion_agent_providers.dart';
import 'axion_capture_popup.dart';

/// Kayıtsız numara pop-up'ını yöneten görünmez host (danışman kabuğunda).
///
/// - Açılışta ve uygulama öne geldiğinde sessiz çağrı günlüğü senkronu
///   dener (Android, izin verilmişse, 15 dk kısıtlı) — numara kaçmaz.
/// - Çağrı bitişini ANLIK izler: uygulama öndeyse pop-up, arka plandaysa
///   aksiyonlu bildirim (uygulamaya girmeden kaydetme).
/// - Bildirimden yapılan/yarım kalan kayıtları açılışta sessizce tamamlar.
/// - Aday provider'ı dinler; aday geldiğinde pop-up'ı BİR kez gösterir.
/// - Üst üste dialog açmaz; kapatma sonrası bir sonraki adaya geçebilir.
class AxionCapturePopupHost extends ConsumerStatefulWidget {
  const AxionCapturePopupHost({super.key});

  @override
  ConsumerState<AxionCapturePopupHost> createState() =>
      _AxionCapturePopupHostState();
}

class _AxionCapturePopupHostState extends ConsumerState<AxionCapturePopupHost>
    with WidgetsBindingObserver {
  static const String _legacyNumberKey = 'axion_native_capture_number';
  static const String _legacyAtKey = 'axion_native_capture_at';
  static const String _nativeQueueKey = 'axion_native_capture_queue_v1';
  static const String _autoTaskKey = 'axion_autofollowup_by_key_v1';
  static const String _dedupeLastRunKey = 'axion_calls_dedupe_last_run_v1';

  final Set<String> _shownThisSession = {};
  bool _dialogVisible = false;
  bool _processingPending = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeAutoSync();
      _startPostCallWatcher();
      unawaited(_consumeNativeCandidate());
      unawaited(_processPendingCaptures());
      unawaited(_maybeRunDuplicateBackfill());
    });
  }

  @override
  void dispose() {
    AxionPostCallWatcher.instance.stop();
    AxionCaptureNotification.instance.onOpenCapture = null;
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _maybeAutoSync();
      unawaited(_consumeNativeCandidate());
      unawaited(_processPendingCaptures());
    }
  }

  void _maybeAutoSync() {
    if (!mounted) return;
    final uid = ref.read(currentUserProvider).valueOrNull?.uid ?? '';
    // Beklemeden tetikle; servis kendi kısıtlarını uygular.
    AxionCallLogAutoSync.instance.maybeSync(uid);
  }

  /// Çağrı bitişi izleyicisi: numara kayıtsızsa anında öneri.
  void _startPostCallWatcher() {
    AxionPostCallWatcher.instance.start(
      advisorId: () => ref.read(currentUserProvider).valueOrNull?.uid ?? '',
      knownPhoneKeys: () {
        final customers =
            ref.read(customerListForAgentProvider).valueOrNull?.entities ??
                const [];
        return AxionPhoneMatcher.buildKnownSet(
          [for (final c in customers) c.primaryPhone],
        );
      },
      onForegroundCandidate: _showPostCallCandidate,
    );
    // Bildirim gövdesine dokunuldu → uygulama açıldı → aynı pop-up.
    AxionCaptureNotification.instance.onOpenCapture = _showPostCallCandidate;
  }

  /// Az önce biten çağrı için doğrudan pop-up (Firestore turunu beklemez).
  void _showPostCallCandidate(String rawNumber, String? contactName) {
    if (!mounted || _dialogVisible) return;
    final key = AxionPhoneMatcher.normalize(rawNumber);
    final candidate = AxionUncapturedNumber(
      normalizedKey: key,
      displayNumber: rawNumber,
      contactName: contactName,
      callCount: 1,
      missedCount: 0,
      lastCallAt: DateTime.now(),
      lastCallWasMissed: false,
      callDocIds: const [],
    );
    _shownThisSession.add(key);
    unawaited(
      CallCaptureAuditService.instance.logEvent(
        event: 'capture_candidate_popup',
        advisorId: ref.read(currentUserProvider).valueOrNull?.uid,
        phoneRaw: rawNumber,
        phoneKey: key,
        extra: {'contactName': contactName ?? ''},
      ),
    );
    unawaited(_ensureAutoFollowUpTask(rawNumber, key));
    _dialogVisible = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) {
        _dialogVisible = false;
        return;
      }
      try {
        await showAxionCapturePopup(context, ref, candidate);
      } finally {
        _dialogVisible = false;
      }
    });
  }

  /// Native Android receiver tarafından bırakılan aday numarayı tüketir.
  /// Uygulama öldüyken gelen çağrılarda da öneri kaçmaz.
  Future<void> _consumeNativeCandidate() async {
    try {
      if (_dialogVisible) return;
      final prefs = await SharedPreferences.getInstance();
      final candidates = <({String raw, int atMs})>[];

      // Yeni native queue formatı (çoklu çağrı adayı kaybolmaz).
      final rawQueue = prefs.getString(_nativeQueueKey);
      if (rawQueue != null && rawQueue.isNotEmpty) {
        try {
          final decoded = jsonDecode(rawQueue) as List<dynamic>;
          for (final e in decoded) {
            if (e is! Map<String, dynamic>) continue;
            final raw = (e['number'] as String? ?? '').trim();
            final atMs = e['at'] is int ? e['at'] as int : null;
            if (raw.isEmpty || atMs == null) continue;
            candidates.add((raw: raw, atMs: atMs));
          }
        } catch (_) {
          // Bozuk kuyruk sessizce sıfırlanır.
        }
      }

      // Geriye dönük uyumluluk (tek değerli eski format).
      final legacyRaw = prefs.getString(_legacyNumberKey)?.trim();
      final legacyAt = prefs.getInt(_legacyAtKey);
      if (legacyRaw != null && legacyRaw.isNotEmpty && legacyAt != null) {
        candidates.add((raw: legacyRaw, atMs: legacyAt));
      }
      await prefs.remove(_legacyNumberKey);
      await prefs.remove(_legacyAtKey);

      if (candidates.isEmpty) return;
      candidates.sort((a, b) => b.atMs.compareTo(a.atMs)); // en yeni önce

      final nowMs = DateTime.now().millisecondsSinceEpoch;
      final remaining = <Map<String, dynamic>>[];
      String? pickedRaw;

      final customers =
          ref.read(customerListForAgentProvider).valueOrNull?.entities ?? const [];
      final known =
          AxionPhoneMatcher.buildKnownSet([for (final c in customers) c.primaryPhone]);

      for (final c in candidates) {
        final age = nowMs - c.atMs;
        if (age > const Duration(hours: 6).inMilliseconds) continue;

        final key = AxionPhoneMatcher.normalize(c.raw);
        if (!AxionPhoneMatcher.isMeaningful(key)) continue;
        if (_shownThisSession.contains(key)) continue;
        if (known.contains(key)) continue;
        final suppressed = await AxionCaptureDismissStore.instance.isSuppressed(key);
        if (suppressed) continue;

        if (pickedRaw == null) {
          pickedRaw = c.raw;
        } else {
          remaining.add({'number': c.raw, 'at': c.atMs});
        }
      }

      if (remaining.isEmpty) {
        await prefs.remove(_nativeQueueKey);
      } else {
        await prefs.setString(_nativeQueueKey, jsonEncode(remaining));
      }

      if (pickedRaw != null) _showPostCallCandidate(pickedRaw, null);
      if (pickedRaw != null) {
        final key = AxionPhoneMatcher.normalize(pickedRaw);
        unawaited(
          CallCaptureAuditService.instance.logEvent(
            event: 'capture_candidate_native_queue_consumed',
            advisorId: ref.read(currentUserProvider).valueOrNull?.uid,
            phoneRaw: pickedRaw,
            phoneKey: key,
            extra: {'remaining': remaining.length},
          ),
        );
      }
    } catch (e, st) {
      AppLogger.e('AxionCapturePopupHost._consumeNativeCandidate', e, st);
    }
  }

  /// Bildirimden başlatılıp tamamlanamayan kayıtları ve bekleyen çağrı
  /// bağlamalarını sessizce bitirir — veri kaybı imkânsız.
  Future<void> _processPendingCaptures() async {
    if (_processingPending) return;
    _processingPending = true;
    try {
      final uid = ref.read(currentUserProvider).valueOrNull?.uid ?? '';
      if (uid.isEmpty) return;

      final saves = await AxionPendingCaptureStore.instance.takeSaves();
      for (final s in saves) {
        final customerId = await SaveContactService.instance.saveToApp(
          ContactSaveRequest(fullName: s.name, primaryPhone: s.phone),
          assignedAgentId: uid,
          source: 'axion_agent_bildirim',
        );
        final key = AxionPhoneMatcher.normalize(s.phone);
        if (customerId == null) {
          // Hâlâ yazılamadı (ör. offline) — kuyruğa geri koy.
          await AxionPendingCaptureStore.instance
              .enqueueSave(name: s.name, phone: s.phone);
        } else {
          await AxionCaptureDismissStore.instance.clear(key);
          await AxionPendingCaptureStore.instance
              .enqueueLink(normalizedKey: key, customerId: customerId);
          unawaited(
            CallCaptureAuditService.instance.logEvent(
              event: 'capture_pending_saved_to_app',
              advisorId: uid,
              phoneRaw: s.phone,
              phoneKey: key,
              extra: {'customerId': customerId},
            ),
          );
        }
      }

      final links = await AxionPendingCaptureStore.instance.takeLinks();
      if (links.isNotEmpty) await _linkPendingCalls(links);
      if (saves.isNotEmpty || links.isNotEmpty) {
        ref.invalidate(consultantCallsStreamProvider);
      }
    } catch (e, st) {
      AppLogger.e('AxionCapturePopupHost._processPendingCaptures', e, st);
    } finally {
      _processingPending = false;
    }
  }

  Future<void> _ensureAutoFollowUpTask(String rawNumber, String key) async {
    try {
      final uid = ref.read(currentUserProvider).valueOrNull?.uid ?? '';
      if (uid.isEmpty) return;
      final prefs = await SharedPreferences.getInstance();
      final rawMap = prefs.getString(_autoTaskKey);
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      final map = <String, int>{};
      if (rawMap != null && rawMap.isNotEmpty) {
        final decoded = jsonDecode(rawMap);
        if (decoded is Map<String, dynamic>) {
          for (final e in decoded.entries) {
            if (e.value is int) map[e.key] = e.value as int;
          }
        }
      }
      // Aynı numara için 6 saat içinde tekrar görev üretme.
      final last = map[key];
      if (last != null && (nowMs - last) < const Duration(hours: 6).inMilliseconds) {
        return;
      }
      map.removeWhere(
        (_, v) => (nowMs - v) > const Duration(days: 3).inMilliseconds,
      );
      map[key] = nowMs;
      await prefs.setString(_autoTaskKey, jsonEncode(map));

      await FirestoreService.setTask({
        'advisorId': uid,
        'title': 'Geri dönüş: $rawNumber',
        'customerId': '',
        'callPhoneKey': key,
        'autoFollowUp': true,
        'done': false,
        'dueAt': Timestamp.fromDate(DateTime.now().add(const Duration(hours: 2))),
      });
      unawaited(
        CallCaptureAuditService.instance.logEvent(
          event: 'capture_auto_followup_task_created',
          advisorId: uid,
          phoneRaw: rawNumber,
          phoneKey: key,
        ),
      );
    } catch (e, st) {
      AppLogger.e('AxionCapturePopupHost._ensureAutoFollowUpTask', e, st);
    }
  }

  Future<void> _maybeRunDuplicateBackfill() async {
    try {
      final uid = ref.read(currentUserProvider).valueOrNull?.uid ?? '';
      if (uid.isEmpty) return;
      final prefs = await SharedPreferences.getInstance();
      final last = prefs.getInt(_dedupeLastRunKey) ?? 0;
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      if (nowMs - last < const Duration(hours: 24).inMilliseconds) return;
      final merged =
          await FirestoreService.normalizeAndDeduplicateRecentCallsForAdvisor(uid);
      await prefs.setInt(_dedupeLastRunKey, nowMs);
      if (merged > 0) {
        ref.invalidate(consultantCallsStreamProvider);
      }
      unawaited(
        CallCaptureAuditService.instance.logEvent(
          event: 'capture_dedupe_backfill_run',
          advisorId: uid,
          extra: {'merged': merged},
        ),
      );
    } catch (e, st) {
      AppLogger.e('AxionCapturePopupHost._maybeRunDuplicateBackfill', e, st);
    }
  }

  /// Bildirimden kaydedilen müşterilere çağrı geçmişini bağlar.
  Future<void> _linkPendingCalls(Map<String, String> links) async {
    final docs =
        ref.read(consultantCallsStreamProvider).valueOrNull?.docs ?? const [];
    if (docs.isEmpty) {
      // Stream henüz akmadı — bağlama bir sonraki açılışa kalsın.
      for (final e in links.entries) {
        await AxionPendingCaptureStore.instance
            .enqueueLink(normalizedKey: e.key, customerId: e.value);
      }
      return;
    }
    for (final e in links.entries) {
      final ids = <String>[];
      for (final d in docs) {
        final data = d.data();
        final existing = data['customerId'] as String? ?? '';
        if (existing.isNotEmpty) continue;
        final phone =
            data['phoneNumber'] as String? ?? data['phone'] as String? ?? '';
        if (phone.isEmpty) continue;
        if (AxionPhoneMatcher.normalize(phone) != e.key) continue;
        ids.add(d.id);
        if (ids.length >= 20) break;
      }
      if (ids.isEmpty) continue;
      try {
        await FirestoreService.linkCallsToCustomer(
          callDocIds: ids,
          customerId: e.value,
        );
      } catch (err, st) {
        AppLogger.e('AxionCapturePopupHost._linkPendingCalls', err, st);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(axionCapturePopupCandidateProvider, (prev, next) {
      final candidate = next.valueOrNull;
      if (candidate == null) return;
      if (_dialogVisible) return;
      if (_shownThisSession.contains(candidate.normalizedKey)) return;

      _shownThisSession.add(candidate.normalizedKey);
      _dialogVisible = true;
      // Frame ortasında dialog açmamak için bir sonraki frame'e ertele.
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) {
          _dialogVisible = false;
          return;
        }
        try {
          await showAxionCapturePopup(context, ref, candidate);
        } finally {
          _dialogVisible = false;
        }
      });
    });
    return const SizedBox.shrink();
  }
}
