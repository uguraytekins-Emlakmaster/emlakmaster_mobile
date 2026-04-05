import 'package:emlakmaster_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:emlakmaster_mobile/core/l10n/app_localizations.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/core/router/app_router.dart';
import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/features/external_integrations/domain/integration_platform_id.dart';
import 'package:emlakmaster_mobile/features/external_integrations/presentation/providers/external_integrations_providers.dart';
import 'package:emlakmaster_mobile/features/external_integrations/presentation/widgets/integration_hero_header.dart';
import 'package:emlakmaster_mobile/features/external_integrations/presentation/widgets/integration_list_shimmer.dart';
import 'package:emlakmaster_mobile/features/external_integrations/presentation/widgets/synced_listing_widgets.dart';
import 'package:emlakmaster_mobile/shared/widgets/empty_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Harici senkron ilan listesi gövdesi (sayfa ve İlanlar sekmesi ortak).
class MyExternalListingsInner extends ConsumerStatefulWidget {
  const MyExternalListingsInner({
    super.key,
    this.showHero = true,
    this.showTrailingConnect = true,
  });

  final bool showHero;
  final bool showTrailingConnect;

  @override
  ConsumerState<MyExternalListingsInner> createState() => _MyExternalListingsInnerState();
}

class _MyExternalListingsInnerState extends ConsumerState<MyExternalListingsInner> {
  IntegrationPlatformId? _platformFilter;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    final l10n = AppLocalizations.of(context);
    final async = ref.watch(integrationSyncedListingsProvider);
    final canManage = ref.watch(canManagePlatformIntegrationsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.showHero)
          IntegrationHeroHeader(
            title: l10n.t('listings_tab_my_external'),
            subtitle: l10n.t('my_external_listings_hero_sub'),
            icon: Icons.collections_bookmark_rounded,
            trailing: widget.showTrailingConnect && canManage
                ? TextButton(
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      context.push(AppRouter.routeConnectedAccounts);
                    },
                    child: Text(l10n.t('my_external_listings_connect_cta')),
                  )
                : null,
          ),
        if (!canManage)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
              l10n.t('integration_connections_read_only_notice'),
              style: TextStyle(
                color: ext.foregroundSecondary,
                fontSize: 13,
                height: 1.35,
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                FilterChipIntegration(
                  label: l10n.t('integration_filter_all'),
                  selected: _platformFilter == null,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _platformFilter = null);
                  },
                ),
                const SizedBox(width: 8),
                ...IntegrationPlatformId.values.map(
                  (p) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChipIntegration(
                      label: p.displayName,
                      selected: _platformFilter == p,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _platformFilter = p);
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: async.when(
            data: (raw) {
              final items = _platformFilter == null
                  ? raw
                  : raw.where((e) => e.platform == _platformFilter).toList();
              if (items.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: DesignTokens.space6),
                    child: EmptyState(
                      premiumVisual: true,
                      icon: Icons.cloud_sync_outlined,
                      title: l10n.t('my_external_listings_empty_title'),
                      subtitle: canManage
                          ? l10n.t('my_external_listings_empty_sub')
                          : '${l10n.t('my_external_listings_empty_sub')}\n\n${l10n.t('integration_connections_read_only_notice')}',
                      actionLabel: canManage ? l10n.t('my_external_listings_connect_cta') : null,
                      onAction: canManage
                          ? () => context.push(AppRouter.routeConnectedAccounts)
                          : null,
                    ),
                  ),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(
                  DesignTokens.space4,
                  0,
                  DesignTokens.space4,
                  DesignTokens.space8,
                ),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: SyncedListingCard(entity: items[index]),
                  );
                },
              );
            },
            loading: () => const IntegrationListShimmer(),
            error: (e, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  '${l10n.t('my_external_listings_load_error')}\n$e',
                  style: TextStyle(color: ext.danger),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
