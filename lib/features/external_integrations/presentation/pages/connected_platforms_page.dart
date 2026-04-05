import 'package:emlakmaster_mobile/core/router/app_router.dart';
import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/features/external_integrations/presentation/providers/connected_platforms_providers.dart';
import 'package:emlakmaster_mobile/features/external_integrations/presentation/widgets/connected_platform_card.dart';
import 'package:emlakmaster_mobile/shared/widgets/app_back_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Phase 1.4 — Bağlı platformlar: premium hub (mock veri; API sonra).
class ConnectedPlatformsPage extends ConsumerWidget {
  const ConnectedPlatformsPage({super.key});

  void _toast(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontSize: 13)),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ext = AppThemeExtension.of(context);
    final platforms = ref.watch(platformListProvider);

    return Scaffold(
      backgroundColor: ext.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
                child: Row(
                  children: [
                    if (context.canPop()) const AppBackButton(),
                    Expanded(
                      child: Text(
                        'Bağlı platformlar',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: ext.foreground,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.4,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                child: Text(
                  'Resmi OAuth ve canlı API bağlantıları henüz üretimde değil. '
                  'Aşağıdaki kartlar arayüz önizlemesi ve yol haritasıdır; '
                  '«Bağlı» veya tam senkron vaadi yoktur. URL içe aktarma deneyseldir — '
                  'güvenilir veri için CSV/JSON veya manuel giriş kullanın.',
                  style: TextStyle(
                    color: ext.foregroundSecondary,
                    fontSize: 13,
                    height: 1.45,
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    TextButton.icon(
                      onPressed: () {
                        HapticFeedback.selectionClick();
                        context.push(AppRouter.routeImportHub);
                      },
                      icon: const Icon(Icons.upload_file_rounded, size: 18),
                      label: const Text(
                        'Mağaza içe aktarma',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        HapticFeedback.selectionClick();
                        context.push(AppRouter.routeMyListings);
                      },
                      icon: const Icon(Icons.library_add_check_rounded, size: 18),
                      label: const Text(
                        'İçe aktarılanlar',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        HapticFeedback.selectionClick();
                        context.push(AppRouter.routeMyExternalListings);
                      },
                      icon: const Icon(Icons.home_work_outlined, size: 18),
                      label: const Text(
                        'Harici ilanlarım',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final p = platforms[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: ConnectedPlatformCard(
                        platform: p,
                        onConnect: () => _toast(
                          context,
                          '${p.name}: bağlantı sihirbazı yakında — tarayıcı / OAuth.',
                        ),
                        onReconnect: () => _toast(
                          context,
                          '${p.name}: oturum yenileme kuyruğa alındı (demo).',
                        ),
                        onSync: () => _toast(
                          context,
                          '${p.name}: senkron isteği gönderildi (demo).',
                        ),
                        onDisconnect: () => _toast(
                          context,
                          '${p.name}: bağlantı kaldırma onaylandı (demo).',
                        ),
                      ),
                    );
                  },
                  childCount: platforms.length,
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: ext.surfaceElevated,
                    borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                    border: Border.all(color: ext.border.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline_rounded, size: 20, color: ext.foregroundMuted),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Veriler şu an örnek senaryodur. Üretimde bağlantı durumu sunucu ve '
                          'tarayıcı uzantısı ile senkronize edilecektir.',
                          style: TextStyle(color: ext.foregroundSecondary, fontSize: 11, height: 1.35),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
