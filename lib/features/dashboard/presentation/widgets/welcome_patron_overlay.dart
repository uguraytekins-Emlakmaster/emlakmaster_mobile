import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/logging/app_logger.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../features/auth/domain/entities/app_role.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';

/// İlk kez superAdmin girişinde tek seferlik "Sistemin Temelleri Atıldı" karşılama.
class WelcomePatronOverlay extends ConsumerStatefulWidget {
  const WelcomePatronOverlay({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  ConsumerState<WelcomePatronOverlay> createState() =>
      _WelcomePatronOverlayState();
}

class _WelcomePatronOverlayState extends ConsumerState<WelcomePatronOverlay> {
  bool _alreadyShown = false;
  bool _visible = false;
  ProviderSubscription<bool>? _roleSub;

  @override
  void initState() {
    super.initState();
    AppLogger.state('[overlay][WelcomePatron] mount');
    _roleSub = ref.listenManual<bool>(
      displayRoleOrNullProvider.select((r) => r == AppRole.superAdmin),
      (prev, isSuperAdmin) {
        if (!isSuperAdmin) return;
        _tryShowIfSuperAdmin();
      },
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _tryShowIfSuperAdmin();
    });
  }

  @override
  void dispose() {
    AppLogger.state('[overlay][WelcomePatron] unmount');
    _roleSub?.close();
    super.dispose();
  }

  void _tryShowIfSuperAdmin() {
    if (!mounted || _alreadyShown) return;
    final isSuper = ref.read(
      displayRoleOrNullProvider.select((r) => r == AppRole.superAdmin),
    );
    if (!isSuper) return;
    _alreadyShown = true;
    AppLogger.state('[overlay][WelcomePatron] show');
    setState(() => _visible = true);
  }

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        if (_visible)
          SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Material(
                  color: ext.card.withValues(alpha: 0.96),
                  elevation: 10,
                  borderRadius: BorderRadius.circular(18),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 560),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('🎉', style: TextStyle(fontSize: 24)),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Hos geldin Patron',
                                  style: TextStyle(
                                    color: ext.textPrimary,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              IconButton(
                                onPressed: _dismiss,
                                tooltip: 'Kapat',
                                icon: Icon(
                                  Icons.close_rounded,
                                  color: ext.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            'Sistemin temelleri atildi. Dashboard uzerinden ofis metriklerini, cagri merkezini ve musteri verilerini yonetebilirsin. Ayarlardan rol degistirerek farkli kullanici deneyimlerini test edebilirsin.',
                            style: TextStyle(
                              color: ext.textSecondary,
                              fontSize: 14,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Align(
                            alignment: Alignment.centerRight,
                            child: FilledButton(
                              onPressed: _dismiss,
                              child: const Text('Tamam'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  void _dismiss() {
    if (!_visible) return;
    AppLogger.state('[overlay][WelcomePatron] hide');
    setState(() => _visible = false);
  }
}
