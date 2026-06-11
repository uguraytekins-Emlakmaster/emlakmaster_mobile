import 'package:emlakmaster_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/axion_call_log_auto_sync.dart';
import '../providers/axion_agent_providers.dart';
import 'axion_capture_popup.dart';

/// Kayıtsız numara pop-up'ını yöneten görünmez host (danışman kabuğunda).
///
/// - Açılışta ve uygulama öne geldiğinde sessiz çağrı günlüğü senkronu
///   dener (Android, izin verilmişse, 15 dk kısıtlı) — numara kaçmaz.
/// - Aday provider'ı dinler; aday geldiğinde pop-up'ı BİR kez gösterir.
/// - Aynı numara için oturum başına tek gösterim (snöz/yoksay kalıcıdır).
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeAutoSync());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _maybeAutoSync();
  }

  void _maybeAutoSync() {
    if (!mounted) return;
    final uid = ref.read(currentUserProvider).valueOrNull?.uid ?? '';
    // Beklemeden tetikle; servis kendi kısıtlarını uygular.
    AxionCallLogAutoSync.instance.maybeSync(uid);
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
        if (!mounted) return;
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
