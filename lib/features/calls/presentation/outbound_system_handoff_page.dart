import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emlakmaster_mobile/core/logging/app_logger.dart';
import 'package:emlakmaster_mobile/core/phone/outbound_phone_dial.dart';
import 'package:emlakmaster_mobile/core/resilience/safe_operation.dart';
import 'package:emlakmaster_mobile/core/services/analytics_service.dart';
import 'package:emlakmaster_mobile/core/services/firestore_service.dart';
import 'package:emlakmaster_mobile/core/analytics/analytics_events.dart';
import 'package:emlakmaster_mobile/features/calls/data/call_local_hive_store.dart';
import 'package:emlakmaster_mobile/features/calls/data/post_call_capture_draft.dart';
import 'package:emlakmaster_mobile/features/monetization/presentation/widgets/upgrade_bottom_sheet.dart';
import 'package:emlakmaster_mobile/features/monetization/services/usage_service.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/providers/post_call_capture_provider.dart';
import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:emlakmaster_mobile/features/crm_customers/presentation/providers/customer_entity_provider.dart';
import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Gerçek GSM: sistem telefon uygulamasına devretmeden önce kısa hazırlık + CRM oturumu.
class OutboundSystemHandoffPage extends ConsumerStatefulWidget {
  const OutboundSystemHandoffPage({
    super.key,
    this.customerId,
    this.phone,
    required this.startedFromScreen,
  });

  final String? customerId;
  final String? phone;
  final String startedFromScreen;

  @override
  ConsumerState<OutboundSystemHandoffPage> createState() =>
      _OutboundSystemHandoffPageState();
}

class _OutboundSystemHandoffPageState
    extends ConsumerState<OutboundSystemHandoffPage> {
  bool _started = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _run());
  }

  void _logOutboundHandoffFailure(Object e, StackTrace st) {
    AppLogger.e(
        'createOutboundCallHandoffSession failed (GSM handoff continues)',
        e,
        st);
    if (kDebugMode) {
      debugPrint('[OutboundHandoff] ${e.runtimeType}: $e');
      if (e is FirebaseException) {
        debugPrint(
            '[OutboundHandoff] Firebase code=${e.code} message=${e.message}');
      }
      if (e is StateError) {
        debugPrint('[OutboundHandoff] StateError: ${e.message}');
      }
    }
  }

  Future<void> _run() async {
    if (_started) return;
    _started = true;

    final router = GoRouter.of(context);

    try {
      final phoneFromExtra = widget.phone?.trim();
      String? resolved = phoneFromExtra;

      if (resolved == null || resolved.isEmpty) {
        final cid = widget.customerId;
        if (cid != null && cid.isNotEmpty) {
          final ent = await ref.read(customerEntityByIdProvider(cid).future);
          resolved = ent?.primaryPhone?.trim();
        }
      }

      if (resolved == null || resolved.isEmpty) {
        if (!mounted) return;
        _snackAndPop(router, 'Bu müşteri için kayıtlı telefon bulunamadı.');
        return;
      }

      if (!OutboundPhoneDial.isLikelyCallablePhone(resolved)) {
        if (!mounted) return;
        _snackAndPop(router,
            'Geçerli bir telefon numarası değil. Numarayı kontrol edin.');
        return;
      }

      final phone = resolved;

      final uid = ref.read(currentUserProvider).valueOrNull?.uid;
      if (uid == null || uid.isEmpty) {
        if (!mounted) return;
        _snackAndPop(router, 'Oturum bulunamadı. Giriş yapıp tekrar deneyin.');
        return;
      }

      final usageService = ref.read(usageServiceProvider);
      await usageService.warmUp();
      final canTrackCall = usageService.canUseCallRecording();
      if (canTrackCall) {
        await usageService.incrementCallUsage();
      } else {
        AnalyticsService.instance.logEvent(
          AnalyticsEvents.limitReachedCall,
          {AnalyticsEvents.paramFeature: 'call_recording'},
        );
      }

      await FirestoreService.ensureInitialized();

      final createdAtMs = DateTime.now().millisecondsSinceEpoch;
      final localRecordId = '${PostCallCaptureDraft.localPrefix}$createdAtMs';

      if (canTrackCall) {
        await CallLocalHiveStore.instance.ensureInit();
        await CallLocalHiveStore.instance.insertCallStart(
          agentId: uid,
          localId: localRecordId,
          phoneNumber: phone,
          createdAtMs: createdAtMs,
          customerId: widget.customerId,
          startedFromScreen: widget.startedFromScreen,
        );
      }

      String? sessionId;
      var crmSessionOk = false;
      if (canTrackCall) {
        try {
          await runWithResilience(
            ref: ref as Ref<Object?>,
            () async {
              sessionId =
                  await FirestoreService.createOutboundCallHandoffSession(
                advisorId: uid,
                customerId: widget.customerId,
                phoneNumber: phone,
                startedFromScreen: widget.startedFromScreen,
              );
            },
          );
          crmSessionOk = sessionId != null && sessionId!.isNotEmpty;
        } catch (e, st) {
          _logOutboundHandoffFailure(e, st);
          sessionId = null;
          crmSessionOk = false;
        }
      }

      if (crmSessionOk && sessionId != null && sessionId!.isNotEmpty) {
        await CallLocalHiveStore.instance.linkFirestoreSession(
          agentId: uid,
          localId: localRecordId,
          firestoreDocumentId: sessionId!,
        );
      }

      final localHandoffId = sessionId ?? localRecordId;

      final ok = await OutboundPhoneDial.launchDial(phone);
      if (!mounted) return;

      if (!ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Telefon uygulaması açılamadı. Numarayı kontrol edin veya tekrar deneyin.',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
        router.pop();
        return;
      }

      if (!canTrackCall) {
        await showUpgradeBottomSheet(
          context,
          feature: 'call_recording',
        );
        if (!mounted) return;
        router.pop();
        return;
      }

      if (!crmSessionOk && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'CRM çağrı oturumu açılamadı; arama yine de başlatıldı. '
              'Görüşmeden sonra hızlı kayıtla CRM\'e ekleyebilirsiniz.',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }

      final captureNotifier = ref.read(postCallCaptureProvider.notifier);
      router.pop();

      unawaited(
        captureNotifier.beginHandoff(
          PostCallCaptureDraft(
            localRecordId: localRecordId,
            callSessionId: localHandoffId,
            crmSessionTracked: crmSessionOk,
            customerId: widget.customerId,
            phone: phone,
            startedFromScreen: widget.startedFromScreen,
            createdAtMs: createdAtMs,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            FirestoreService.userFacingErrorMessage(e),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      router.pop();
    }
  }

  void _snackAndPop(GoRouter router, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
    router.pop();
  }

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    return Scaffold(
      backgroundColor: ext.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: ext.accent, strokeWidth: 2),
              const SizedBox(height: 24),
              Text(
                'Telefon uygulamasına hazırlanıyor…',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: ext.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Gerçek görüşme cihazınızın telefon uygulamasında açılacak.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: ext.textSecondary,
                      height: 1.35,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
