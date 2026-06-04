import 'package:emlakmaster_mobile/core/l10n/app_localizations.dart';
import 'package:emlakmaster_mobile/core/services/onboarding_store.dart';
import 'package:emlakmaster_mobile/features/onboarding/presentation/tour/coach_mark_tour.dart';
import 'package:emlakmaster_mobile/features/onboarding/presentation/tour/consultant_tour_providers.dart';
import 'package:emlakmaster_mobile/features/onboarding/presentation/tour/consultant_tour_steps.dart';
import 'package:emlakmaster_mobile/screens/consultant_shell_nav.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Danışman kabuğunda her zaman ağaçta kalan tur tetikleyici.
///
/// Tek bir sekmeye bağlı değildir; bu sayede otomatik ilk-giriş turu ve
/// Ayarlar'dan "Turu tekrar göster" sinyali aktif sekme ne olursa olsun
/// çalışır. Sekme geçişini [ConsultantShellNav] üzerinden yapar (kök Overlay'e
/// dokunmaz).
class ConsultantTourHost extends ConsumerStatefulWidget {
  const ConsultantTourHost({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<ConsultantTourHost> createState() => _ConsultantTourHostState();
}

class _ConsultantTourHostState extends ConsumerState<ConsultantTourHost> {
  bool _autoChecked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeAutoStart());
  }

  @override
  void dispose() {
    CoachMarkTour.dismiss();
    super.dispose();
  }

  void _maybeAutoStart() {
    if (_autoChecked) return;
    _autoChecked = true;
    if (OnboardingStore.instance.consultantTourCompletedSync) return;
    // İlk iniş ekranının (Günüm) yerleşmesi için kısa nefes payı.
    Future<void>.delayed(const Duration(milliseconds: 650), () {
      if (!mounted) return;
      if (OnboardingStore.instance.consultantTourCompletedSync) return;
      _startTour();
    });
  }

  void _startTour() {
    if (CoachMarkTour.isShowing) return;
    if (!mounted) return;
    CoachMarkTour.show(
      context,
      steps: buildConsultantTourSteps(AppLocalizations.of(context)),
      goToTab: (pageIndex) =>
          ConsultantShellNav.maybeOf(context)?.goToTab(pageIndex),
      onCompleted: () {
        OnboardingStore.instance.setConsultantTourCompleted();
        // Tur Günüm'de başladığı yere geri döner.
        if (mounted) ConsultantShellNav.maybeOf(context)?.goToTab(0);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<int>(consultantTourReplayProvider, (prev, next) {
      if (prev == null || next == prev) return;
      if (!mounted) return;
      _startTour();
    });
    return widget.child;
  }
}
