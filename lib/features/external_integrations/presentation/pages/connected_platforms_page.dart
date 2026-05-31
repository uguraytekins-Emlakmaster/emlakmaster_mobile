import 'package:emlakmaster_mobile/features/admin_baglantilar/presentation/widgets/baglantilar_command_surface.dart';
import 'package:emlakmaster_mobile/widgets/premium/v2/premium_shell_chrome.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Bağlantılar — platform durumu ve ofis entegrasyon kontrol yüzeyi (Screen 18).
/// Rota kimliği korunur: `/settings/connected-accounts` (manager-tier guard router'da).
class ConnectedPlatformsPage extends ConsumerStatefulWidget {
  const ConnectedPlatformsPage({super.key});

  @override
  ConsumerState<ConnectedPlatformsPage> createState() =>
      _ConnectedPlatformsPageState();
}

class _ConnectedPlatformsPageState extends ConsumerState<ConnectedPlatformsPage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return const PremiumShellBackdrop(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: BaglantilarCommandSurface(),
        ),
      ),
    );
  }
}
