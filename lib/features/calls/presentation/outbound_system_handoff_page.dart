import 'package:emlakmaster_mobile/core/constants/app_constants.dart';
import 'package:emlakmaster_mobile/core/phone/outbound_phone_dial.dart';
import 'package:emlakmaster_mobile/core/resilience/safe_operation.dart';
import 'package:emlakmaster_mobile/core/router/app_router.dart';
import 'package:emlakmaster_mobile/core/services/firestore_service.dart';
import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:emlakmaster_mobile/features/crm_customers/presentation/providers/customer_entity_provider.dart';
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

class _OutboundSystemHandoffPageState extends ConsumerState<OutboundSystemHandoffPage> {
  bool _started = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _run());
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
        _snackAndPop(router, 'Geçerli bir telefon numarası değil. Numarayı kontrol edin.');
        return;
      }

      final uid = ref.read(currentUserProvider).valueOrNull?.uid;
      if (uid == null || uid.isEmpty) {
        if (!mounted) return;
        _snackAndPop(router, 'Oturum bulunamadı. Giriş yapıp tekrar deneyin.');
        return;
      }

      String? sessionId;
      try {
        await runWithResilience(
          ref: ref as Ref<Object?>,
          () async {
            sessionId = await FirestoreService.createOutboundCallHandoffSession(
              advisorId: uid,
              customerId: widget.customerId,
              phoneNumber: resolved!,
              startedFromScreen: widget.startedFromScreen,
            );
          },
        );
      } catch (_) {
        if (!mounted) return;
        _snackAndPop(
          router,
          'Çağrı oturumu kaydedilemedi. İnternet bağlantınızı kontrol edip tekrar deneyin.',
        );
        return;
      }

      final ok = await OutboundPhoneDial.launchDial(resolved);
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

      final extra = <String, dynamic>{
        'outcome': AppConstants.callOutcomeSystemHandoff,
        'durationSec': null,
        if (widget.customerId != null && widget.customerId!.isNotEmpty)
          'customerId': widget.customerId,
        'phone': resolved,
        if (sessionId != null && sessionId!.isNotEmpty) 'callSessionId': sessionId,
      };

      router.pop();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        router.push(AppRouter.routeCallSummary, extra: extra);
      });
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
