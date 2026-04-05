import 'package:emlakmaster_mobile/core/l10n/app_localizations.dart';
import 'package:emlakmaster_mobile/core/router/app_router.dart';
import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/app_surfaces.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/features/external_integrations/application/integration_capability_registry.dart';
import 'package:emlakmaster_mobile/features/external_integrations/application/integration_provider.dart';
import 'package:emlakmaster_mobile/features/external_integrations/domain/external_connection_entity.dart';
import 'package:emlakmaster_mobile/features/external_integrations/domain/integration_platform_id.dart';
import 'package:emlakmaster_mobile/features/external_integrations/presentation/providers/external_integrations_providers.dart';
import 'package:emlakmaster_mobile/features/external_integrations/presentation/widgets/integration_hero_header.dart';
import 'package:emlakmaster_mobile/features/external_integrations/presentation/widgets/integration_list_shimmer.dart';
import 'package:emlakmaster_mobile/shared/widgets/app_back_button.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
/// Eski hub — [ConnectedPlatformsPage] kullanılır (`/settings/connected-accounts`).
@Deprecated('Use ConnectedPlatformsPage (Phase 1.4)')
class ConnectedAccountsPage extends ConsumerWidget {
  const ConnectedAccountsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ext = AppThemeExtension.of(context);
    final l10n = AppLocalizations.of(context);
    final async = ref.watch(externalConnectionsProvider);
    return Scaffold(
      backgroundColor: ext.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
                child: Row(
                  children: [
                    if (context.canPop()) const AppBackButton(),
                    Expanded(
                      child: Text(
                        'Harici platform hesapları',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: ext.foreground,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: IntegrationHeroHeader(
                title: l10n.t('listings_tab_my_external'),
                subtitle:
                    'Resmi OAuth ve canlı API henüz tam üretimde değil. Bu ekran geçmiş akıştır; '
                    'güncel bağlantı durumu «Bağlı platformlar» hub’ındaki gerçek durum etiketlerine bakın. '
                    'Senkron ilanlar yalnızca canlı entegrasyon açıldığında üretim güvencesi taşır.',
                icon: Icons.link_rounded,
                trailing: Wrap(
                  spacing: 8,
                  children: [
                    TextButton(
                      onPressed: () {
                        HapticFeedback.selectionClick();
                        context.push(AppRouter.routeImportHub);
                      },
                      child: const Text('İçe aktarma'),
                    ),
                    TextButton(
                      onPressed: () {
                        HapticFeedback.selectionClick();
                        context.push(AppRouter.routeMyExternalListings);
                      },
                      child: Text(l10n.t('my_external_listings_title')),
                    ),
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: DesignTokens.space2)),
            async.when(
              data: (connections) {
                if (connections.isEmpty) {
                  return SliverToBoxAdapter(
                    child: _EmptyConnections(
                      onConnect: (platform) => _onConnectTap(context, platform),
                    ),
                  );
                }
                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final c = connections[index];
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                        child: _ConnectionCard(
                          entity: c,
                          onSync: () => _onSyncTap(context, c.platform),
                        ),
                      );
                    },
                    childCount: connections.length,
                  ),
                );
              },
              loading: () => const SliverToBoxAdapter(
                child: IntegrationListShimmer(itemCount: 3),
              ),
              error: (e, _) => SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Bağlantılar yüklenemedi: $e\n\nFirestore kurallarında `external_connections` için okuma tanımlı olmalı.',
                    style: TextStyle(color: ext.danger),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(DesignTokens.space4),
                child: _AvailablePlatformsRow(
                  existing: async.valueOrNull ?? const [],
                  onConnect: (platform) => _onConnectTap(context, platform),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
      ),
    );
  }

  static Future<void> _onConnectTap(BuildContext context, IntegrationPlatformId platform) async {
    HapticFeedback.lightImpact();
    final adapter = IntegrationProvider.adapterFor(platform);
    final result = await adapter.connect();
    if (!context.mounted) return;
    result.when(
      success: (_) {},
      unsupported: (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${platform.displayName}: bağlantı sihirbazı hazırlanıyor. Şu an için OAuth tamamlanmadı.',
              style: const TextStyle(fontSize: 13),
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      failure: (code, msg) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg ?? code.name),
            backgroundColor: AppThemeExtension.of(context).danger,
          ),
        );
      },
    );
  }

  static Future<void> _onSyncTap(BuildContext context, IntegrationPlatformId platform) async {
    HapticFeedback.lightImpact();
    final adapter = IntegrationProvider.adapterFor(platform);
    final result = await adapter.syncListings('');
    if (!context.mounted) return;
    result.when(
      success: (_) {},
      unsupported: (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Senkronizasyon sunucu tarafında etkinleştirilecek.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      failure: (code, msg) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg ?? code.name)),
        );
      },
    );
  }
}

class _EmptyConnections extends StatelessWidget {
  const _EmptyConnections({required this.onConnect});

  final void Function(IntegrationPlatformId) onConnect;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    return Padding(
      padding: const EdgeInsets.all(DesignTokens.space6),
      child: Column(
        children: [
          Icon(Icons.link_off_rounded, size: 56, color: ext.foregroundMuted),
          const SizedBox(height: DesignTokens.space2),
          Text(
            'Henüz bağlı hesap yok',
            style: TextStyle(
              color: ext.foreground,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Aşağıdan bir platform seçerek bağlamayı deneyin.',
            textAlign: TextAlign.center,
            style: TextStyle(color: ext.foregroundSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _ConnectionCard extends StatelessWidget {
  const _ConnectionCard({
    required this.entity,
    required this.onSync,
  });

  final ExternalConnectionEntity entity;
  final VoidCallback onSync;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    final caps = entity.capabilitySnapshot;
    return Container(
      decoration: AppSurfaces.cardLevel2(context),
      padding: AppSurfaces.paddingCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _PlatformBadge(platform: entity.platform),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  entity.accountDisplayName ?? entity.externalAccountId,
                  style: TextStyle(
                    color: ext.foreground,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              _StatusChip(status: entity.connectionStatus),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Son senkron: ${_fmt(entity.lastSyncedAt)}',
            style: TextStyle(color: ext.foregroundSecondary, fontSize: 12),
          ),
          if (entity.lastError != null) ...[
            const SizedBox(height: 6),
            Text(
              entity.lastError!,
              style: TextStyle(color: ext.danger, fontSize: 12),
            ),
          ],
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              if (caps.canImportListings) const _CapChip(label: 'İlan içe aktarma'),
              if (caps.canReadMessages) const _CapChip(label: 'Mesajlar'),
              if (!caps.canUpdatePrice)
                const _CapChip(label: 'Fiyat güncelleme: desteklenmiyor', muted: true),
            ],
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: onSync,
            icon: const Icon(Icons.sync_rounded, size: 18),
            label: const Text('Senkronize et'),
          ),
        ],
      ),
    );
  }

  String _fmt(DateTime? t) =>
      t == null ? '—' : '${t.day.toString().padLeft(2, '0')}.${t.month.toString().padLeft(2, '0')}.${t.year} ${t.hour}:${t.minute.toString().padLeft(2, '0')}';
}

class _PlatformBadge extends StatelessWidget {
  const _PlatformBadge({required this.platform});

  final IntegrationPlatformId platform;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: ext.brandPrimary.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        platform.displayName,
        style: TextStyle(
          color: ext.brandPrimary,
          fontWeight: FontWeight.w700,
          fontSize: 11,
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    Color bg;
    Color fg;
    switch (status) {
      case 'connected':
        bg = ext.success.withValues(alpha: 0.25);
        fg = ext.success;
        break;
      case 'needs_reauth':
        bg = ext.warning.withValues(alpha: 0.25);
        fg = ext.warning;
        break;
      case 'limited':
        bg = ext.brandPrimary.withValues(alpha: 0.2);
        fg = ext.brandPrimary;
        break;
      default:
        bg = ext.foregroundMuted.withValues(alpha: 0.2);
        fg = ext.foregroundSecondary;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _CapChip extends StatelessWidget {
  const _CapChip({required this.label, this.muted = false});

  final String label;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: ext.border.withValues(alpha: 0.6)),
        borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: muted ? ext.foregroundMuted : ext.foregroundSecondary,
          fontSize: 10,
        ),
      ),
    );
  }
}

class _AvailablePlatformsRow extends StatelessWidget {
  const _AvailablePlatformsRow({
    required this.existing,
    required this.onConnect,
  });

  final List<ExternalConnectionEntity> existing;
  final void Function(IntegrationPlatformId) onConnect;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Platformlar',
          style: TextStyle(
            color: ext.foreground,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 10),
        ...IntegrationCapabilityRegistry.supportedPlatforms.map((p) {
          final has = existing.any((e) => e.platform == p);
          final caps = IntegrationCapabilityRegistry.forPlatform(p);
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: has ? null : () => onConnect(p),
                borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
                child: Container(
                  padding: AppSurfaces.paddingCard,
                  decoration: AppSurfaces.cardLevel1(context),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              p.displayName,
                              style: TextStyle(
                                color: ext.foreground,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              has
                                  ? 'Bu platform için kayıt mevcut'
                                  : 'Bağlan — ${caps.canImportListings ? "ilan içe aktarım planlanıyor" : "sınırlı"}',
                              style: TextStyle(
                                color: ext.foregroundSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (!has)
                        Icon(Icons.chevron_right_rounded, color: ext.foregroundMuted),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}
