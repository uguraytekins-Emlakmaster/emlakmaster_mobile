import 'dart:async';

import 'package:emlakmaster_mobile/core/firebase/user_facing_firebase_message.dart';
import 'package:emlakmaster_mobile/core/branding/brand_emblem.dart';
import 'package:emlakmaster_mobile/core/copy/product_labels.dart';
import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/app_typography.dart';
import 'package:emlakmaster_mobile/core/constants/app_constants.dart';
import 'package:emlakmaster_mobile/core/l10n/app_localizations.dart';
import 'package:emlakmaster_mobile/core/providers/firebase_storage_availability_provider.dart';
import 'package:emlakmaster_mobile/core/providers/settings_provider.dart';
import 'package:emlakmaster_mobile/core/services/firebase_storage_availability.dart';
import 'package:emlakmaster_mobile/core/widgets/app_toaster.dart';
import 'package:emlakmaster_mobile/core/services/auth_logout_coordinator.dart';
import 'package:emlakmaster_mobile/core/services/logout_flow_tracer.dart';
import 'package:emlakmaster_mobile/core/services/onboarding_store.dart';
import 'package:emlakmaster_mobile/core/services/settings_service.dart';
import 'package:emlakmaster_mobile/features/analytics/presentation/providers/investment_opportunity_providers.dart';
import 'package:emlakmaster_mobile/features/market_settings/domain/entities/market_settings_entity.dart';
import 'package:emlakmaster_mobile/features/auth/domain/entities/app_role.dart';
import 'package:emlakmaster_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:emlakmaster_mobile/features/listing_display/presentation/widgets/listing_display_settings_section.dart';
import 'package:emlakmaster_mobile/features/monetization/presentation/providers/usage_providers.dart';
import 'package:emlakmaster_mobile/features/monetization/presentation/widgets/ai_usage_indicator.dart';
import 'package:emlakmaster_mobile/features/monetization/presentation/widgets/upgrade_bottom_sheet.dart';
import 'package:emlakmaster_mobile/features/auth/domain/permissions/feature_permission.dart';
import 'package:emlakmaster_mobile/core/router/app_router.dart';
import 'package:emlakmaster_mobile/features/external_integrations/presentation/platform_setup_wizard_args.dart';
import 'package:emlakmaster_mobile/features/settings/presentation/providers/feature_flags_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:emlakmaster_mobile/features/profile/presentation/widgets/profile_avatar.dart';
import 'package:emlakmaster_mobile/features/profile/presentation/widgets/profile_avatar_crop_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'package:emlakmaster_mobile/features/profile/data/profile_avatar_service.dart';
import 'package:emlakmaster_mobile/widgets/test_role_switch_sheet.dart';
import 'package:emlakmaster_mobile/widgets/premium_bottom_sheet_shell.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../../../widgets/premium/premium_ui_kit.dart';
import '../../../../screens/placeholder_pages.dart'
    show NotificationsSection, ThemeSection;

/// Ayarlar: Hesap → Plan → Bildirim → Görünüm → Dil → İlanlar → Entegrasyonlar → Gelişmiş (katlanır).
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).valueOrNull;
    final role = ref.watch(displayRoleOrNullProvider) ?? AppRole.guest;
    final realRole = ref.watch(currentRoleOrNullProvider) ?? AppRole.guest;
    final canSwitchRole = kDebugMode &&
        (realRole == AppRole.superAdmin || realRole == AppRole.brokerOwner);
    final override = ref.watch(overrideRoleProvider);
    final preferConsultant = ref.watch(preferredConsultantPanelProvider);
    final isAdmin = FeaturePermission.seesAdminPanel(realRole);
    final canManagePlatformIntegrations =
        ref.watch(canManagePlatformIntegrationsProvider);
    final flagsAsync = ref.watch(featureFlagsProvider);
    final usage = ref.watch(usageTrackerProvider);

    final l10n = AppLocalizations.of(context);
    final localeState = ref.watch(localeProvider);
    final theme = Theme.of(context);

    final ext = AppThemeExtension.of(context);
    return Scaffold(
      backgroundColor: ext.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            DesignTokens.space5,
            DesignTokens.space3,
            DesignTokens.space5,
            DesignTokens.space8,
          ),
          children: [
            PremiumPageHeader(
              title: l10n.t('title_settings'),
              subtitle: 'Sisteminizi dilediğiniz gibi yönetin.',
            ),
            const PremiumSectionHeader(
              label: 'Hesap Alanı',
              icon: Icons.person_rounded,
            ),
            _sectionCard(
              context,
              children: [
                if (user != null) ...[
                  ListTile(
                    leading: _SettingsProfileAvatar(
                      uid: user.uid,
                      fallbackText: user.displayName ?? user.email ?? '',
                    ),
                    title: Text(
                      user.email ?? 'Giriş yapılmış',
                      style: TextStyle(
                          color: theme.colorScheme.onSurface,
                          fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      'Rol: ${override?.label ?? role.label}',
                      style: TextStyle(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.7),
                          fontSize: 12),
                    ),
                    trailing: const ExcludeSemantics(
                      child: Opacity(
                        opacity: 0.48,
                        child: BrandEmblem(
                          variant: BrandEmblemVariant.mini,
                          size: 26,
                        ),
                      ),
                    ),
                  ),
                  Divider(
                      height: 1,
                      color: theme.dividerColor.withValues(alpha: 0.5)),
                  _AvatarSettingsRow(userId: user.uid),
                ],
                if (isAdmin) ...[
                  Divider(
                      height: 1,
                      color: theme.dividerColor.withValues(alpha: 0.5)),
                  ListTile(
                    leading: Icon(
                      Icons.dashboard_rounded,
                      color: preferConsultant != true
                          ? AppThemeExtension.of(context).accent
                          : theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                    title: Text(ProductLabels.managerWorkspace,
                        style: TextStyle(color: theme.colorScheme.onSurface)),
                    trailing: preferConsultant != true
                        ? Icon(Icons.check_rounded,
                            color: AppThemeExtension.of(context).accent)
                        : null,
                    onTap: () => ref
                        .read(preferredConsultantPanelProvider.notifier)
                        .state = false,
                  ),
                  ListTile(
                    leading: Icon(
                      Icons.person_rounded,
                      color: preferConsultant == true
                          ? AppThemeExtension.of(context).accent
                          : theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                    title: Text(ProductLabels.consultantWorkspace,
                        style: TextStyle(color: theme.colorScheme.onSurface)),
                    trailing: preferConsultant == true
                        ? Icon(Icons.check_rounded,
                            color: AppThemeExtension.of(context).accent)
                        : null,
                    onTap: () => ref
                        .read(preferredConsultantPanelProvider.notifier)
                        .state = true,
                  ),
                ],
                if (user != null) ...[
                  Divider(
                      height: 1,
                      color: theme.dividerColor.withValues(alpha: 0.5)),
                  ListTile(
                    leading: Icon(Icons.logout_rounded,
                        color: AppThemeExtension.of(context).danger),
                    title: Text('Çıkış yap',
                        style: TextStyle(color: theme.colorScheme.onSurface)),
                    onTap: () {
                      LogoutFlowTracer.step('LOGOUT_FLOW', 'tap settings');
                      unawaited(
                        AuthLogoutCoordinator.signOut(
                          ref,
                          source: 'settings',
                        ),
                      );
                    },
                  ),
                ],
              ],
            ),
            const SizedBox(height: DesignTokens.space6),
            const _SectionHeader(
              title: 'Plan & Üyelik',
              icon: Icons.workspace_premium_rounded,
            ),
            _sectionCard(
              context,
              children: [
                ListTile(
                  leading: Icon(
                    usage.isPro ? Icons.verified_rounded : Icons.bolt_rounded,
                    color: AppThemeExtension.of(context).accent,
                  ),
                  title: Text(
                    usage.isPro ? 'PRO üyelik açık' : 'Temel Plan',
                    style: TextStyle(
                      color: theme.colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    usage.isPro
                        ? 'Sınırsız akıllı öneri ve gelişmiş içgörüler hazır.'
                        : 'Arama ve müşteri akışı sınırsız. Akıllı öneriler ayda 20 hakla devam eder.',
                    style: TextStyle(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      fontSize: 12,
                    ),
                  ),
                  trailing: usage.isPro
                      ? Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppThemeExtension.of(context)
                                .success
                                .withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            'PRO',
                            style: TextStyle(
                              color: AppThemeExtension.of(context).success,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        )
                      : Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color:
                                AppThemeExtension.of(context).surfaceElevated,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                                color:
                                    theme.dividerColor.withValues(alpha: 0.5)),
                          ),
                          child: Text(
                            'Temel',
                            style: TextStyle(
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.75),
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                ),
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: AiUsageIndicator(compact: true),
                ),
                if (!usage.isPro) ...[
                  Divider(
                      height: 1,
                      color: theme.dividerColor.withValues(alpha: 0.5)),
                  ListTile(
                    leading: Icon(
                      Icons.auto_awesome_rounded,
                      color: AppThemeExtension.of(context).accent,
                    ),
                    title: Text(
                      'Pro\u2019yu keşfet',
                      style: TextStyle(color: theme.colorScheme.onSurface),
                    ),
                    subtitle: Text(
                      'Sınırsız akıllı öneri, daha derin müşteri içgörüsü ve daha güçlü satış yönlendirmesi.',
                      style: TextStyle(
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.7),
                        fontSize: 11,
                      ),
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => showUpgradeBottomSheet(
                      context,
                      feature: 'revenue_insights',
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: DesignTokens.space6),
            const _SectionHeader(
                title: 'Çağrılar', icon: Icons.call_rounded),
            _sectionCard(
              context,
              children: [
                ListTile(
                  leading: Icon(Icons.call_made_rounded,
                      color: AppThemeExtension.of(context).accent, size: 22),
                  title: Text(ProductLabels.myCalls,
                      style: TextStyle(
                          color: theme.colorScheme.onSurface,
                          fontWeight: FontWeight.w500)),
                  subtitle: Text(
                    'Danışman alanındaki çağrılar, toplu mesaj ve Android telefon geçmişi eşlemesi.',
                    style: TextStyle(
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.7),
                        fontSize: 11),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.push(AppRouter.routeConsultantCalls),
                ),
              ],
            ),
            const SizedBox(height: DesignTokens.space6),
            _SectionHeader(
                title: l10n.t('section_notifications'),
                icon: Icons.notifications_rounded),
            _sectionCard(
              context,
              children: const [
                NotificationsSection(embedInParentCard: true),
              ],
            ),
            const SizedBox(height: DesignTokens.space6),
            _SectionHeader(
                title: l10n.t('section_appearance'),
                icon: Icons.palette_rounded),
            flagsAsync.when(
              data: (flags) => _sectionCard(
                context,
                children: [
                  const ThemeSection(embedInParentCard: true),
                  Divider(
                      height: 1,
                      color: theme.dividerColor.withValues(alpha: 0.45)),
                  _SettingSwitch(
                    title: l10n.t('compact_dashboard'),
                    subtitle: l10n.t('compact_dashboard_sub'),
                    icon: Icons.dashboard_customize_rounded,
                    value: flags[AppConstants.keyCompactDashboard] ?? false,
                    onChanged: (v) => ref
                        .read(featureFlagsProvider.notifier)
                        .setFlag(AppConstants.keyCompactDashboard, v),
                  ),
                  Divider(
                      height: 1,
                      color: theme.dividerColor.withValues(alpha: 0.45)),
                  _SettingSwitch(
                    title: l10n.t('power_saver'),
                    subtitle: l10n.t('power_saver_sub'),
                    icon: Icons.battery_saver_rounded,
                    value: flags[AppConstants.keyPowerSaver] ?? false,
                    onChanged: (v) => ref
                        .read(featureFlagsProvider.notifier)
                        .setFlag(AppConstants.keyPowerSaver, v),
                  ),
                ],
              ),
              loading: () => _sectionCard(
                context,
                children: const [
                  ThemeSection(embedInParentCard: true),
                ],
              ),
              error: (_, __) => _sectionCard(
                context,
                children: const [
                  ThemeSection(embedInParentCard: true),
                ],
              ),
            ),
            const SizedBox(height: DesignTokens.space6),
            _SectionHeader(
                title: l10n.t('section_language'),
                icon: Icons.language_rounded),
            _sectionCard(
              context,
              children: [
                ListTile(
                  leading: Icon(Icons.translate_rounded,
                      color: AppThemeExtension.of(context).accent, size: 22),
                  title: Text('Dil',
                      style: TextStyle(
                          color: theme.colorScheme.onSurface,
                          fontWeight: FontWeight.w500)),
                  subtitle: Text(
                    l10n.t(AppLocalizations.languageCodeToLabelKey[
                            localeState.valueOrNull?.languageCode ?? 'tr'] ??
                        'language_turkish'),
                    style: TextStyle(
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.7),
                        fontSize: 12),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _openLanguageSelector(context, ref),
                ),
              ],
            ),
            const SizedBox(height: DesignTokens.space6),
            const _SectionHeader(
                title: 'İlanlar & Ofis', icon: Icons.apartment_rounded),
            _sectionCard(
              context,
              children: [
                const ListingDisplaySettingsSection(
                    embeddedInSettingsHub: true),
              ],
            ),
            const SizedBox(height: DesignTokens.space6),
            _SectionHeader(
              title: canManagePlatformIntegrations
                  ? l10n.t('settings_section_platform_integrations_manager')
                  : 'Eşleştirme & Entegrasyonlar',
              icon: Icons.hub_rounded,
            ),
            flagsAsync.when(
              data: (flags) => _sectionCard(
                context,
                children: [
                  if (flags[AppConstants.keyFeatureExternalIntegrations] ??
                      true) ...[
                    if (!canManagePlatformIntegrations) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                        child: Text(
                          l10n.t('integration_connections_read_only_notice'),
                          style: TextStyle(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.75),
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                      ),
                      ListTile(
                        leading: Icon(Icons.collections_bookmark_outlined,
                            color: theme.colorScheme.primary),
                        title: Text(l10n.t('my_external_listings_title'),
                            style:
                                TextStyle(color: theme.colorScheme.onSurface)),
                        subtitle: Text(
                          l10n.t('my_external_listings_settings_sub'),
                          style: TextStyle(
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.65),
                              fontSize: 12),
                        ),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () =>
                            context.push(AppRouter.routeMyExternalListings),
                      ),
                    ] else ...[
                      ListTile(
                        leading: Icon(Icons.hub_rounded,
                            color: theme.colorScheme.primary),
                        title: Text(
                            l10n.t('settings_platform_connections_tile'),
                            style:
                                TextStyle(color: theme.colorScheme.onSurface)),
                        subtitle: Text(
                          l10n.t('settings_platform_connections_tile_sub'),
                          style: TextStyle(
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.65),
                              fontSize: 12),
                        ),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () =>
                            context.push(AppRouter.routeConnectedAccounts),
                      ),
                      ListTile(
                        leading: Icon(Icons.auto_fix_high_outlined,
                            color: theme.colorScheme.primary),
                        title: const Text('Kanal kurulum akışı'),
                        subtitle: Text(
                          'Resmi entegrasyon hazırlığı, aktarım anahtarı ve toplu veri akışı',
                          style: TextStyle(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.65),
                            fontSize: 12,
                          ),
                        ),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => context.push(
                          AppRouter.routePlatformSetupWizard,
                          extra: const PlatformSetupWizardArgs(),
                        ),
                      ),
                      ListTile(
                        leading: Icon(Icons.upload_file_outlined,
                            color: theme.colorScheme.primary),
                        title: const Text('Toplu ilan aktarımı'),
                        subtitle: Text(
                          'Bağlantı, dosya ve aktarım geçmişi',
                          style: TextStyle(
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.65),
                              fontSize: 12),
                        ),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => context.push(AppRouter.routeImportHub),
                      ),
                      ListTile(
                        leading: Icon(Icons.history_rounded,
                            color: theme.colorScheme.primary),
                        title: const Text('Aktarım geçmişi'),
                        subtitle: Text(
                          'Görev durumu ve işlem kayıtları',
                          style: TextStyle(
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.65),
                              fontSize: 12),
                        ),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => context.push(AppRouter.routeImportHistory),
                      ),
                      ListTile(
                        leading: Icon(Icons.collections_bookmark_rounded,
                            color: theme.colorScheme.primary),
                        title: Text(l10n.t('my_external_listings_title'),
                            style:
                                TextStyle(color: theme.colorScheme.onSurface)),
                        subtitle: Text(
                          l10n.t('my_external_listings_settings_sub'),
                          style: TextStyle(
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.65),
                              fontSize: 12),
                        ),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () =>
                            context.push(AppRouter.routeMyExternalListings),
                      ),
                    ],
                  ] else
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                      child: Text(
                        'Harici platformlar kapalı. Açmak için Gelişmiş özellikler bölümünü kullanın.',
                        style: TextStyle(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.7),
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                    ),
                ],
              ),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            const SizedBox(height: DesignTokens.space6),
            const _SectionHeader(
                title: 'Yatırım & Piyasa', icon: Icons.show_chart_rounded),
            _sectionCard(
              context,
              children: const [
                _FavoriteInvestRegionTile(),
              ],
            ),
            const SizedBox(height: DesignTokens.space6),
            _SettingsAdvancedSection(
              sectionCard: (children) => _sectionCard(context, children: children),
              l10n: l10n,
            ),
            const SizedBox(height: DesignTokens.space6),
            const _SectionHeader(
                title: 'Hakkında', icon: Icons.info_outline_rounded),
            _sectionCard(
              context,
              children: const [
                EmlakMasterProductIdentityCard(),
              ],
            ),
            if (canSwitchRole || kDebugMode) ...[
              const SizedBox(height: DesignTokens.space6),
              Padding(
                padding: const EdgeInsets.only(bottom: DesignTokens.space2),
                child: Row(
                  children: [
                    Icon(Icons.science_outlined,
                        size: 16,
                        color: AppThemeExtension.of(context).textTertiary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'GELİŞMİŞ / TEST',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: AppThemeExtension.of(context).textTertiary,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.05,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              _sectionCard(
                context,
                muted: true,
                children: [
                  if (canSwitchRole)
                    ListTile(
                      leading: Icon(Icons.swap_horiz_rounded,
                          color: AppThemeExtension.of(context).accent),
                      title: Text(
                        override != null
                            ? 'Rol: ${override.label} (geri al)'
                            : 'Rol değiştir (test)',
                        style: TextStyle(color: theme.colorScheme.onSurface),
                      ),
                      subtitle: Text(
                        'Yalnızca görünüm modu; üretim hesabını değiştirmez.',
                        style: TextStyle(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.55),
                            fontSize: 11),
                      ),
                      onTap: () => _showRoleSwitcher(context, ref, override),
                    ),
                  if (kDebugMode)
                    ListTile(
                      leading: Icon(Icons.slideshow_outlined,
                          color: AppThemeExtension.of(context).accent),
                      title: Text(
                        'Tanıtımı yeniden göster',
                        style: TextStyle(color: theme.colorScheme.onSurface),
                      ),
                      subtitle: Text(
                        'İlk açılış slaytlarını tekrar açar (yalnızca debug).',
                        style: TextStyle(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.55),
                          fontSize: 11,
                        ),
                      ),
                      onTap: () async {
                        await OnboardingStore.instance.resetForTesting();
                        if (!context.mounted) return;
                        context.go(AppRouter.routeOnboarding);
                      },
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _openLanguageSelector(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final ext = AppThemeExtension.of(context);
    final l10n = AppLocalizations.of(context);
    final current = ref.read(localeProvider).valueOrNull;
    final sheetH = MediaQuery.sizeOf(context).height * 0.52;

    showPremiumModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const PremiumBottomSheetHandle(),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  DesignTokens.space5,
                  DesignTokens.space2,
                  DesignTokens.space4,
                  DesignTokens.space3,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.translate_outlined,
                      size: DesignTokens.iconLg,
                      color: ext.accent.withValues(alpha: 0.5),
                    ),
                    const SizedBox(width: DesignTokens.space3),
                    Expanded(
                      child: PremiumSheetHeader(
                        compact: true,
                        title: l10n.t('section_language'),
                        subtitle: 'Uygulama dili',
                      ),
                    ),
                    IconButton(
                      tooltip: 'Kapat',
                      style: IconButton.styleFrom(
                        foregroundColor: ext.textTertiary,
                      ),
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: sheetH,
                child: ListView.separated(
                  itemCount: AppLocalizations.supportedLocales.length,
                  separatorBuilder: (_, __) => Divider(
                    height: 1,
                    color: theme.dividerColor.withValues(alpha: 0.5),
                  ),
                  itemBuilder: (context, i) {
                    final loc = AppLocalizations.supportedLocales[i];
                    final labelKey = AppLocalizations
                            .languageCodeToLabelKey[loc.languageCode] ??
                        loc.languageCode;
                    final label = l10n.t(labelKey);
                    final selected = current?.languageCode == loc.languageCode;
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: DesignTokens.space5,
                        vertical: DesignTokens.space1,
                      ),
                      minLeadingWidth: 40,
                      leading: Icon(
                        Icons.language_outlined,
                        color: ext.textSecondary,
                        size: DesignTokens.iconMd,
                      ),
                      title: Text(
                        label,
                        style: TextStyle(
                          color: theme.colorScheme.onSurface,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      trailing: selected
                          ? Icon(
                              Icons.check_rounded,
                              color: ext.accent,
                              size: DesignTokens.iconMd,
                            )
                          : null,
                      onTap: () async {
                        await ref.read(localeProvider.notifier).setLocale(loc);
                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showRoleSwitcher(
      BuildContext context, WidgetRef ref, AppRole? currentOverride) {
    showTestRoleSwitchSheet(context, ref, currentOverride);
  }

  Widget _sectionCard(BuildContext context,
      {required List<Widget> children, bool muted = false}) {
    final ext = AppThemeExtension.of(context);
    return DecoratedBox(
      decoration: ext.premiumSurfaceDecoration(
        goldBorder: !muted,
        baseColor: muted
            ? ext.surfaceElevated.withValues(alpha: 0.88)
            : ext.surfaceElevated,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }
}

typedef _SettingsSectionCardBuilder = Widget Function(List<Widget> children);

/// Ürün bayrakları ve çağrı akışı — varsayılan kapalı, isteyen açar.
class _SettingsAdvancedSection extends ConsumerWidget {
  const _SettingsAdvancedSection({
    required this.sectionCard,
    required this.l10n,
  });

  final _SettingsSectionCardBuilder sectionCard;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final ext = AppThemeExtension.of(context);
    final flagsAsync = ref.watch(featureFlagsProvider);

    return flagsAsync.when(
      data: (flags) => sectionCard([
        Theme(
          data: theme.copyWith(
              dividerColor: theme.dividerColor.withValues(alpha: 0.35)),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(horizontal: 8),
            childrenPadding: EdgeInsets.zero,
            leading: Icon(Icons.tune_rounded, color: ext.accent, size: 22),
            iconColor: ext.accent,
            collapsedIconColor: ext.textTertiary,
            title: Text(
              l10n.t('settings_advanced_title'),
              style: AppTypography.bodyStrong(context),
            ),
                subtitle: Text(
                  l10n.t('settings_advanced_sub'),
                  style: AppTypography.meta(context),
                ),
                children: [
                  _AdvancedFlagGroup(
                    label: 'Ürün görünümü',
                    children: [
                      _SettingSwitch(
                        title: 'Odaklı V1 (önerilen)',
                        subtitle:
                            'Komuta Odası ve Ekonomi sekmeleri gizlenir; çekirdek akış kalır.',
                        icon: Icons.bolt_outlined,
                        value: flags[AppConstants.keyV1LeanProduct] ?? true,
                        onChanged: (v) => ref
                            .read(featureFlagsProvider.notifier)
                            .setFlag(AppConstants.keyV1LeanProduct, v),
                      ),
                      _SettingSwitch(
                        title: 'KPI çubuğu',
                        subtitle: 'Özet ekranın üstündeki hızlı göstergeler',
                        icon: Icons.bar_chart_rounded,
                        value: flags[AppConstants.keyFeatureKpiBar] ?? true,
                        onChanged: (v) => ref
                            .read(featureFlagsProvider.notifier)
                            .setFlag(AppConstants.keyFeatureKpiBar, v),
                      ),
                      _SettingSwitch(
                        title: ProductLabels.warRoom,
                        subtitle: 'Ofis ritmi, hedefler ve öncelikli alanlar',
                        icon: Icons.military_tech_rounded,
                        value: flags[AppConstants.keyFeatureWarRoom] ?? true,
                        onChanged: (v) => ref
                            .read(featureFlagsProvider.notifier)
                            .setFlag(AppConstants.keyFeatureWarRoom, v),
                      ),
                      _SettingSwitch(
                        title: ProductLabels.callCenter,
                        subtitle: 'Tüm çağrılar ve operasyon görünümü',
                        icon: Icons.call_merge_rounded,
                        value: flags[AppConstants.keyFeatureCommandCenter] ?? true,
                        onChanged: (v) => ref
                            .read(featureFlagsProvider.notifier)
                            .setFlag(AppConstants.keyFeatureCommandCenter, v),
                      ),
                      _SettingSwitch(
                        title: 'Günlük özet',
                        subtitle: 'Günün özeti paneli',
                        icon: Icons.today_rounded,
                        value: flags[AppConstants.keyFeatureDailyBrief] ?? true,
                        onChanged: (v) => ref
                            .read(featureFlagsProvider.notifier)
                            .setFlag(AppConstants.keyFeatureDailyBrief, v),
                      ),
                      _SettingSwitch(
                        title: 'Pipeline',
                        subtitle: 'Kanban ve aşama takibi',
                        icon: Icons.account_tree_rounded,
                        value: flags[AppConstants.keyFeaturePipeline] ?? true,
                        onChanged: (v) => ref
                            .read(featureFlagsProvider.notifier)
                            .setFlag(AppConstants.keyFeaturePipeline, v),
                      ),
                      _SettingSwitch(
                        title: 'Yatırımcı istihbaratı',
                        subtitle: 'Fırsat radarı ve yatırım panelleri',
                        icon: Icons.savings_rounded,
                        value: flags[AppConstants.keyFeatureInvestorIntelligence] ??
                            true,
                        onChanged: (v) => ref
                            .read(featureFlagsProvider.notifier)
                            .setFlag(
                                AppConstants.keyFeatureInvestorIntelligence, v),
                      ),
                      _SettingSwitch(
                        title: 'Görevler',
                        subtitle: 'Takip ve hatırlatmalar',
                        icon: Icons.task_alt_rounded,
                        value: flags[AppConstants.keyFeatureTasks] ?? true,
                        onChanged: (v) => ref
                            .read(featureFlagsProvider.notifier)
                            .setFlag(AppConstants.keyFeatureTasks, v),
                      ),
                      _SettingSwitch(
                        title: 'Bildirim merkezi',
                        subtitle: 'Tüm bildirimler tek ekranda',
                        icon: Icons.notifications_rounded,
                        value:
                            flags[AppConstants.keyFeatureNotificationsCenter] ??
                                true,
                        onChanged: (v) => ref
                            .read(featureFlagsProvider.notifier)
                            .setFlag(
                                AppConstants.keyFeatureNotificationsCenter, v),
                      ),
                    ],
                  ),
                  _AdvancedFlagGroup(
                    label: 'Çağrı & kayıt',
                    children: [
                      _SettingSwitch(
                        title: 'Sesli müşteri akışı',
                        subtitle: 'Eller serbest kullanım ve sesli yönlendirme',
                        icon: Icons.mic_rounded,
                        value: flags[AppConstants.keyFeatureVoiceCrm] ?? true,
                        onChanged: (v) => ref
                            .read(featureFlagsProvider.notifier)
                            .setFlag(AppConstants.keyFeatureVoiceCrm, v),
                      ),
                      _SettingSwitch(
                        title: 'Çağrı özeti',
                        subtitle: 'Arama sonrası akıllı özet',
                        icon: Icons.summarize_rounded,
                        value: flags[AppConstants.keyFeatureCallSummary] ?? true,
                        onChanged: (v) => ref
                            .read(featureFlagsProvider.notifier)
                            .setFlag(AppConstants.keyFeatureCallSummary, v),
                      ),
                      _SettingSwitch(
                        title: 'Rehbere / uygulamaya kaydet',
                        subtitle: 'Arama sonrası rehber ve müşteri kaydı',
                        icon: Icons.contact_phone_rounded,
                        value: flags[AppConstants.keyFeatureContactSave] ?? true,
                        onChanged: (v) => ref
                            .read(featureFlagsProvider.notifier)
                            .setFlag(AppConstants.keyFeatureContactSave, v),
                      ),
                    ],
                  ),
                  _AdvancedFlagGroup(
                    label: 'Entegrasyon & piyasa',
                    children: [
                      _SettingSwitch(
                        title: 'Market Pulse',
                        subtitle: 'Son ilanlar ve harici kaynaklar',
                        icon: Icons.trending_up_rounded,
                        value: flags[AppConstants.keyFeatureMarketPulse] ?? true,
                        onChanged: (v) => ref
                            .read(featureFlagsProvider.notifier)
                            .setFlag(AppConstants.keyFeatureMarketPulse, v),
                      ),
                      _SettingSwitch(
                        title: 'Portföy eşleştirme',
                        subtitle: 'Müşteri–ilan eşleşme önerisi',
                        icon: Icons.auto_awesome_rounded,
                        value:
                            flags[AppConstants.keyFeaturePortfolioMatch] ?? true,
                        onChanged: (v) => ref
                            .read(featureFlagsProvider.notifier)
                            .setFlag(AppConstants.keyFeaturePortfolioMatch, v),
                      ),
                      _SettingSwitch(
                        title: 'Harici platform entegrasyonları',
                        subtitle:
                            'Sahibinden / Hepsiemlak / Emlakjet bağlı hesaplar',
                        icon: Icons.hub_rounded,
                        value: flags[AppConstants.keyFeatureExternalIntegrations] ??
                            true,
                        onChanged: (v) => ref
                            .read(featureFlagsProvider.notifier)
                            .setFlag(
                                AppConstants.keyFeatureExternalIntegrations, v),
                      ),
                    ],
                  ),
            ],
          ),
        ),
      ]),
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _AdvancedFlagGroup extends StatelessWidget {
  const _AdvancedFlagGroup({required this.label, required this.children});

  final String label;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: ext.textTertiary,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.35,
                ),
          ),
        ),
        ...children,
      ],
    );
  }
}

/// Fırsat Endeksi / Rainbow kartı için takip edilen Diyarbakır ilçesi.
class _FavoriteInvestRegionTile extends ConsumerStatefulWidget {
  const _FavoriteInvestRegionTile();

  @override
  ConsumerState<_FavoriteInvestRegionTile> createState() =>
      _FavoriteInvestRegionTileState();
}

class _FavoriteInvestRegionTileState
    extends ConsumerState<_FavoriteInvestRegionTile> {
  String? _value;

  static const _options = <MapEntry<String, String>>[
    MapEntry(MarketSettingsEntity.regionKayapinar, 'Kayapınar'),
    MapEntry(MarketSettingsEntity.regionBaglar, 'Bağlar'),
    MapEntry(MarketSettingsEntity.regionYenisehir, 'Yenişehir'),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final id = await SettingsService.instance.getFavoriteInvestRegionId();
    if (mounted) setState(() => _value = id);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ids = _options.map((e) => e.key).toSet();
    final raw = _value ?? AppConstants.defaultFavoriteInvestRegionId;
    final v =
        ids.contains(raw) ? raw : AppConstants.defaultFavoriteInvestRegionId;
    return ListTile(
      leading: Icon(Icons.location_city_rounded,
          color: AppThemeExtension.of(context).accent, size: 22),
      title: Text(
        'Fırsat Endeksi bölgesi',
        style: TextStyle(
            color: theme.colorScheme.onSurface, fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        'Komuta Merkezi içindeki yatırım iştahı özeti bu ilçeye göre hesaplanır.',
        style: TextStyle(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
          fontSize: 11,
        ),
      ),
      trailing: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: v,
          isDense: true,
          dropdownColor: theme.cardTheme.color ?? theme.colorScheme.surface,
          style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 13),
          items: _options
              .map(
                (e) => DropdownMenuItem<String>(
                  value: e.key,
                  child: Text(e.value),
                ),
              )
              .toList(),
          onChanged: (next) async {
            if (next == null) return;
            await SettingsService.instance.setFavoriteInvestRegionId(next);
            ref.invalidate(favoriteInvestRegionIdProvider);
            if (mounted) setState(() => _value = next);
          },
        ),
      ),
    );
  }
}

class _AvatarSettingsRow extends ConsumerStatefulWidget {
  const _AvatarSettingsRow({required this.userId});
  final String userId;

  @override
  ConsumerState<_AvatarSettingsRow> createState() => _AvatarSettingsRowState();
}

class _AvatarSettingsRowState extends ConsumerState<_AvatarSettingsRow> {
  bool _loading = false;

  Future<void> _pickAndUpload() async {
    if (_loading) return;
    final storageAsync = ref.read(firebaseStorageAvailableProvider);
    final storageOk = storageAsync.maybeWhen(
      data: (ok) => ok,
      orElse: () => true,
    );
    if (!storageOk) {
      AppToaster.warning(
          context, FirebaseStorageAvailability.unavailableMessage);
      return;
    }
    final picker = ImagePicker();
    final xFile =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 92);
    if (xFile == null) return;
    final rawBytes = await xFile.readAsBytes();
    if (!mounted) return;
    final cropped = await Navigator.of(context).push<Uint8List?>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (ctx) => ProfileAvatarCropScreen(imageBytes: rawBytes),
      ),
    );
    if (cropped == null || !mounted) return;

    setState(() => _loading = true);
    try {
      final result = await ProfileAvatarService.instance.uploadAvatarFromBytes(
        uid: widget.userId,
        bytes: cropped,
      );
      if (!mounted) return;
      if (result != null && result.downloadUrl.isNotEmpty) {
        ref.invalidate(userDocStreamProvider(widget.userId));
        AppToaster.success(context, 'Profil fotoğrafı güncellendi.');
      } else {
        AppToaster.warning(
          context,
          'Profil fotoğrafı yüklenemedi. Mevcut fotoğrafınız korundu.',
        );
      }
    } catch (e) {
      if (mounted) {
        AppToaster.error(
            context, userFacingErrorMessage(e, context: 'settings_avatar'));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _removeAvatar() async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      await ProfileAvatarService.instance.deleteAvatar(uid: widget.userId);
      if (mounted) {
        AppToaster.success(context, 'Profil fotoğrafı kaldırıldı.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final storageAsync = ref.watch(firebaseStorageAvailableProvider);
    final showInactiveHint = storageAsync.maybeWhen(
      data: (ok) => !ok,
      orElse: () => false,
    );
    final canPickPhoto = !_loading &&
        storageAsync.maybeWhen(
          data: (ok) => ok,
          orElse: () => true,
        );
    final showChecking = storageAsync.isLoading;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.photo_camera_rounded,
                  color: AppThemeExtension.of(context).accent, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Profil fotoğrafı',
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.w500,
                      fontSize: 13),
                ),
              ),
              TextButton(
                onPressed: canPickPhoto ? _pickAndUpload : null,
                child: Text(_loading ? 'Yükleniyor…' : 'Fotoğraf seç'),
              ),
              const SizedBox(width: 4),
              TextButton(
                onPressed: _loading ? null : _removeAvatar,
                child: const Text('Kaldır'),
              ),
            ],
          ),
          if (showChecking) ...[
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.only(left: 28),
              child: Text(
                'Depolama durumu kontrol ediliyor…',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.5),
                  fontSize: 11,
                ),
              ),
            ),
          ] else if (showInactiveHint) ...[
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.only(left: 28),
              child: Text(
                FirebaseStorageAvailability.unavailableMessage,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.65),
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Yalnızca avatar URL değişince yeniden çizer; tüm Ayarlar listesini değil.
class _SettingsProfileAvatar extends ConsumerWidget {
  const _SettingsProfileAvatar({
    required this.uid,
    required this.fallbackText,
  });

  final String uid;
  final String fallbackText;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final imageUrl = ref.watch(
      userDocStreamProvider(uid).select((a) => a.valueOrNull?.avatarUrl),
    );
    return ProfileAvatar(
      size: 44,
      imageUrl: imageUrl,
      fallbackText: fallbackText,
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.icon});

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    return Padding(
      padding: const EdgeInsets.only(
          bottom: DesignTokens.space2, top: DesignTokens.space1),
      child: Row(
        children: [
          Icon(icon, size: 17, color: ext.accent.withValues(alpha: 0.9)),
          const SizedBox(width: DesignTokens.space2),
          Expanded(
            child: Text(
              title,
              style: AppTypography.cardHeading(context).copyWith(
                color: ext.textSecondary,
                fontWeight: FontWeight.w700,
                fontSize: DesignTokens.fontSizeLg,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingSwitch extends StatelessWidget {
  const _SettingSwitch({
    required this.title,
    this.subtitle,
    required this.icon,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String? subtitle;
  final IconData icon;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      secondary:
          Icon(icon, color: AppThemeExtension.of(context).accent, size: 22),
      title: Text(title, style: AppTypography.bodyStrong(context)),
      subtitle: subtitle != null
          ? Text(subtitle!, style: AppTypography.meta(context))
          : null,
      value: value,
      activeThumbColor: AppThemeExtension.of(context).accent,
      onChanged: (v) => onChanged(v),
    );
  }
}
