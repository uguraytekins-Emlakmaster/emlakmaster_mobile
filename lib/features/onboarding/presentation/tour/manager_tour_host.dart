import 'package:emlakmaster_mobile/core/services/onboarding_store.dart';
import 'package:emlakmaster_mobile/features/onboarding/presentation/tour/coach_mark_tour.dart';
import 'package:emlakmaster_mobile/features/onboarding/presentation/tour/manager_tour_providers.dart';
import 'package:emlakmaster_mobile/features/onboarding/presentation/tour/manager_tour_steps.dart';
import 'package:emlakmaster_mobile/screens/admin_shell_nav.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Yönetici kabuğunda her zaman ağaçta kalan tur tetikleyici.
///
/// Tek bir sekmeye bağlı değildir; bu sayede otomatik ilk-giriş turu ve
/// Ayarlar'dan "Turu tekrar göster" sinyali aktif sekme ne olursa olsun
/// çalışır. Sekme geçişini [AdminShellNav] üzerinden yapar (kök Overlay'e
/// dokunmaz). Sekme indeksleri özellik bayraklarına göre dinamik olduğundan
/// adımlar [AdminShellNav.tabIndexFor] ile sekme anahtarından çözülür.
class ManagerTourHost extends ConsumerStatefulWidget {
  const ManagerTourHost({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<ManagerTourHost> createState() => _ManagerTourHostState();
}

class _ManagerTourHostState extends ConsumerState<ManagerTourHost> {
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
    if (OnboardingStore.instance.managerTourCompletedSync) return;
    // İlk iniş ekranının (Komuta Merkezi) yerleşmesi için kısa nefes payı.
    Future<void>.delayed(const Duration(milliseconds: 650), () {
      if (!mounted) return;
      if (OnboardingStore.instance.managerTourCompletedSync) return;
      _startTour();
    });
  }

  void _startTour() {
    if (CoachMarkTour.isShowing) return;
    if (!mounted) return;
    final nav = AdminShellNav.maybeOf(context);
    if (nav == null) return;
    int tabIndexForKey(String key) => nav.tabIndexFor?.call(key) ?? -1;
    CoachMarkTour.show(
      context,
      steps: buildManagerTourSteps(tabIndexForKey),
      goToTab: (pageIndex) => nav.goToTab(pageIndex),
      onCompleted: () {
        OnboardingStore.instance.setManagerTourCompleted();
        // Tur Komuta Merkezi'nde başladığı yere geri döner.
        if (mounted) nav.goToTab(0);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<int>(managerTourReplayProvider, (prev, next) {
      if (prev == null || next == prev) return;
      if (!mounted) return;
      _startTour();
    });
    return widget.child;
  }
}
