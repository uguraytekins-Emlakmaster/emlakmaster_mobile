import 'dart:async';

import 'package:emlakmaster_mobile/core/logging/app_logger.dart';
import 'package:emlakmaster_mobile/core/services/firestore_service.dart';
import 'package:emlakmaster_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/providers/consultant_calls_provider.dart';
import 'package:emlakmaster_mobile/features/contact_save/data/save_contact_service.dart';
import 'package:emlakmaster_mobile/features/contact_save/domain/contact_save_request.dart';
import 'package:emlakmaster_mobile/features/crm_customers/presentation/providers/customer_list_stream_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
      unawaited(_processPendingCaptures());
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
