import 'package:emlakmaster_mobile/core/navigation/main_shell_shortcut_provider.dart';
import 'package:emlakmaster_mobile/core/router/app_router.dart';
import 'package:emlakmaster_mobile/core/theme/premium/premium_theme_extension.dart';
import 'package:emlakmaster_mobile/widgets/premium/v2/premium_shell_chrome.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// `/command-center` rotası — yönetici kabuğu sekmesine yönlendirir.
///
/// Tek başına [CommandCenterPage] açmak kabuk dışında kırık UI üretir
/// (filtre paneli görünür, içerik boş/kilitli). Her zaman ana kabuk +
/// [MainShellShortcut.openCallsTab] kullanılır.
class CommandCenterShellEntryPage extends ConsumerStatefulWidget {
  const CommandCenterShellEntryPage({super.key});

  @override
  ConsumerState<CommandCenterShellEntryPage> createState() =>
      _CommandCenterShellEntryPageState();
}

class _CommandCenterShellEntryPageState
    extends ConsumerState<CommandCenterShellEntryPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _redirectToShellTab());
  }

  void _redirectToShellTab() {
    if (!mounted) return;
    ref
        .read(mainShellShortcutProvider.notifier)
        .enqueue(MainShellShortcut.openCallsTab);
    context.go(AppRouter.routeHome);
  }

  @override
  Widget build(BuildContext context) {
    final premium = PremiumThemeExtension.of(context);
    return PremiumShellBackdrop(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: CircularProgressIndicator(color: premium.champagneGold),
        ),
      ),
    );
  }
}
