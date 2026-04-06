import 'package:emlakmaster_mobile/core/firebase/user_facing_firebase_message.dart';
import 'package:emlakmaster_mobile/core/branding/brand_emblem.dart';
import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/constants/app_constants.dart';
import 'package:emlakmaster_mobile/core/l10n/app_localizations.dart';
import 'package:emlakmaster_mobile/core/providers/firebase_storage_availability_provider.dart';
import 'package:emlakmaster_mobile/core/providers/settings_provider.dart';
import 'package:emlakmaster_mobile/core/services/firebase_storage_availability.dart';
import 'package:emlakmaster_mobile/core/widgets/app_toaster.dart';
import 'package:emlakmaster_mobile/core/services/auth_service.dart';
import 'package:emlakmaster_mobile/core/services/settings_service.dart';
import 'package:emlakmaster_mobile/features/analytics/presentation/providers/investment_opportunity_providers.dart';
import 'package:emlakmaster_mobile/features/market_settings/domain/entities/market_settings_entity.dart';
import 'package:emlakmaster_mobile/features/auth/domain/entities/app_role.dart';
import 'package:emlakmaster_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:emlakmaster_mobile/features/auth/data/user_repository.dart';
import 'package:emlakmaster_mobile/features/listing_display/presentation/widgets/listing_display_settings_section.dart';
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
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../../../shared/widgets/emlak_app_bar.dart';
import '../../../../screens/placeholder_pages.dart' show NotificationsSection, ThemeSection;

/// Ayarlar: bilgi mimarisi — Hesap → İletişim → Çağrı & CRM → … → Gelişmiş/Test (ayrık).
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
    final canBecomeAdmin = user != null &&
        (realRole == AppRole.agent || realRole == AppRole.guest);
    final canManagePlatformIntegrations = ref.watch(canManagePlatformIntegrationsProvider);
    final flagsAsync = ref.watch(featureFlagsProvider);

    final l10n = AppLocalizations.of(context);
    final localeState = ref.watch(localeProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: emlakAppBar(
        context,
        title: Text(l10n.t('title_settings')),
        backgroundColor: theme.appBarTheme.backgroundColor ?? theme.scaffoldBackgroundColor,
        foregroundColor: theme.appBarTheme.foregroundColor ?? theme.colorScheme.onSurface,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            DesignTokens.space5,
            DesignTokens.space3,
            DesignTokens.space5,
            DesignTokens.space8,
          ),
          children: [
            const _SectionHeader(title: 'Hesap', icon: Icons.person_rounded),
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
                      style: TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      'Rol: ${override?.label ?? role.label}',
                      style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.7), fontSize: 12),
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
                  Divider(height: 1, color: theme.dividerColor.withValues(alpha: 0.5)),
                  _AvatarSettingsRow(userId: user.uid),
                ],
                if (canBecomeAdmin) ...[
                  Divider(height: 1, color: theme.dividerColor.withValues(alpha: 0.5)),
                  ListTile(
                    leading: Icon(Icons.admin_panel_settings_rounded, color: AppThemeExtension.of(context).accent),
                    title: Text('Yönetici yetkisi al', style: TextStyle(color: theme.colorScheme.onSurface)),
                    subtitle: Text(
                      'Firestore\'da rolünüz broker_owner olarak güncellenir.',
                      style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.7), fontSize: 11),
                    ),
                    onTap: () async {
                      try {
                        await UserRepository.setUserDoc(
                          uid: user.uid,
                          role: 'broker_owner',
                          name: user.displayName,
                          email: user.email,
                        );
                        ref.invalidate(userDocStreamProvider(user.uid));
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('Yönetici yetkisi verildi. Panel yenileniyor...'),
                              backgroundColor: AppThemeExtension.of(context).accent,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(userFacingErrorMessage(e, context: 'settings_admin_role')),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
                  ),
                ],
                if (isAdmin) ...[
                  Divider(height: 1, color: theme.dividerColor.withValues(alpha: 0.5)),
                  ListTile(
                    leading: Icon(
                      Icons.dashboard_rounded,
                      color: preferConsultant != true ? AppThemeExtension.of(context).accent : theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                    title: Text('Yönetici paneli', style: TextStyle(color: theme.colorScheme.onSurface)),
                    trailing: preferConsultant != true
                        ? Icon(Icons.check_rounded, color: AppThemeExtension.of(context).accent)
                        : null,
                    onTap: () => ref.read(preferredConsultantPanelProvider.notifier).state = false,
                  ),
                  ListTile(
                    leading: Icon(
                      Icons.person_rounded,
                      color: preferConsultant == true ? AppThemeExtension.of(context).accent : theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                    title: Text('Danışman paneli', style: TextStyle(color: theme.colorScheme.onSurface)),
                    trailing: preferConsultant == true
                        ? Icon(Icons.check_rounded, color: AppThemeExtension.of(context).accent)
                        : null,
                    onTap: () => ref.read(preferredConsultantPanelProvider.notifier).state = true,
                  ),
                ],
                if (user != null) ...[
                  Divider(height: 1, color: theme.dividerColor.withValues(alpha: 0.5)),
                  ListTile(
                    leading: Icon(Icons.logout_rounded, color: AppThemeExtension.of(context).danger),
                    title: Text('Çıkış yap', style: TextStyle(color: theme.colorScheme.onSurface)),
                    onTap: () => AuthService.instance.signOut(),
                  ),
                ],
              ],
            ),
            const SizedBox(height: DesignTokens.space6),
            const _SectionHeader(title: 'İletişim', icon: Icons.forum_rounded),
            _sectionCard(
              context,
              children: [
                ListTile(
                  leading: Icon(Icons.chat_bubble_outline_rounded, color: theme.colorScheme.primary),
                  title: Text('Mesaj merkezi', style: TextStyle(color: theme.colorScheme.onSurface)),
                  subtitle: Text(
                    'Birleşik gelen kutusu — platform bağlantısı sonrası',
                    style: TextStyle(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                      fontSize: 12,
                    ),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.push(AppRouter.routeMessageCenter),
                ),
              ],
            ),
            const SizedBox(height: DesignTokens.space6),
            const _SectionHeader(title: 'Çağrı & CRM', icon: Icons.call_rounded),
            _sectionCard(
              context,
              children: [
                ListTile(
                  leading: Icon(Icons.call_made_rounded, color: AppThemeExtension.of(context).accent, size: 22),
                  title: Text('Tüm Çağrılar', style: TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.w500)),
                  subtitle: Text(
                    'Danışman paneli → Çağrılar: kendi çağrılarınız, CSV export, toplu SMS. Android\'de telefon günlüğü senkronu.',
                    style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.7), fontSize: 11),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.push(AppRouter.routeConsultantCalls),
                ),
              ],
            ),
            const SizedBox(height: 12),
            flagsAsync.when(
              data: (flags) => _sectionCard(
                context,
                children: [
                  _SettingSwitch(
                    title: 'Sesli CRM (Magic Call)',
                    subtitle: 'Sesli komut ve hands-free',
                    icon: Icons.mic_rounded,
                    value: flags[AppConstants.keyFeatureVoiceCrm] ?? true,
                    onChanged: (v) =>
                        ref.read(featureFlagsProvider.notifier).setFlag(AppConstants.keyFeatureVoiceCrm, v),
                  ),
                  Divider(height: 1, color: theme.dividerColor.withValues(alpha: 0.45)),
                  _SettingSwitch(
                    title: 'Çağrı özeti (AI)',
                    subtitle: 'Arama sonrası otomatik özet',
                    icon: Icons.summarize_rounded,
                    value: flags[AppConstants.keyFeatureCallSummary] ?? true,
                    onChanged: (v) =>
                        ref.read(featureFlagsProvider.notifier).setFlag(AppConstants.keyFeatureCallSummary, v),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Arama sonrası kayıt',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: AppThemeExtension.of(context).textTertiary,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.35,
                        ),
                      ),
                    ),
                  ),
                  _SettingSwitch(
                    title: 'Rehbere / uygulamaya kaydet',
                    subtitle: 'Arama sonrası rehber ve müşteri kaydı',
                    icon: Icons.contact_phone_rounded,
                    value: flags[AppConstants.keyFeatureContactSave] ?? true,
                    onChanged: (v) =>
                        ref.read(featureFlagsProvider.notifier).setFlag(AppConstants.keyFeatureContactSave, v),
                  ),
                ],
              ),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            const SizedBox(height: DesignTokens.space6),
            _SectionHeader(title: l10n.t('section_notifications'), icon: Icons.notifications_rounded),
            flagsAsync.when(
              data: (flags) => _sectionCard(
                context,
                children: [
                  const NotificationsSection(embedInParentCard: true),
                  Divider(height: 1, color: theme.dividerColor.withValues(alpha: 0.45)),
                  _SettingSwitch(
                    title: l10n.t('push_notifications'),
                    subtitle: l10n.t('push_notifications_sub'),
                    icon: Icons.notifications_active_rounded,
                    value: flags[AppConstants.keyFeaturePushNotifications] ?? true,
                    onChanged: (v) =>
                        ref.read(featureFlagsProvider.notifier).setFlag(AppConstants.keyFeaturePushNotifications, v),
                  ),
                ],
              ),
              loading: () => _sectionCard(
                context,
                children: const [
                  NotificationsSection(embedInParentCard: true),
                ],
              ),
              error: (_, __) => _sectionCard(
                context,
                children: const [
                  NotificationsSection(embedInParentCard: true),
                ],
              ),
            ),
            const SizedBox(height: DesignTokens.space6),
            _SectionHeader(title: l10n.t('section_appearance'), icon: Icons.palette_rounded),
            flagsAsync.when(
              data: (flags) => _sectionCard(
                context,
                children: [
                  const ThemeSection(embedInParentCard: true),
                  Divider(height: 1, color: theme.dividerColor.withValues(alpha: 0.45)),
                  _SettingSwitch(
                    title: l10n.t('compact_dashboard'),
                    subtitle: l10n.t('compact_dashboard_sub'),
                    icon: Icons.dashboard_customize_rounded,
                    value: flags[AppConstants.keyCompactDashboard] ?? false,
                    onChanged: (v) =>
                        ref.read(featureFlagsProvider.notifier).setFlag(AppConstants.keyCompactDashboard, v),
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
            const _SectionHeader(title: 'Performans', icon: Icons.speed_rounded),
            flagsAsync.when(
              data: (flags) => _sectionCard(
                context,
                children: [
                  _SettingSwitch(
                    title: l10n.t('power_saver'),
                    subtitle: l10n.t('power_saver_sub'),
                    icon: Icons.battery_saver_rounded,
                    value: flags[AppConstants.keyPowerSaver] ?? false,
                    onChanged: (v) =>
                        ref.read(featureFlagsProvider.notifier).setFlag(AppConstants.keyPowerSaver, v),
                  ),
                  _SettingSwitch(
                    title: 'Titreşim (haptic)',
                    subtitle: 'Butonlarda dokunsal geri bildirim',
                    icon: Icons.vibration_rounded,
                    value: flags[AppConstants.keyHapticFeedback] ?? true,
                    onChanged: (v) =>
                        ref.read(featureFlagsProvider.notifier).setFlag(AppConstants.keyHapticFeedback, v),
                  ),
                  _SettingSwitch(
                    title: 'Ses efektleri',
                    subtitle: 'Bildirim ve onay sesleri',
                    icon: Icons.volume_up_rounded,
                    value: flags[AppConstants.keySoundEffects] ?? false,
                    onChanged: (v) =>
                        ref.read(featureFlagsProvider.notifier).setFlag(AppConstants.keySoundEffects, v),
                  ),
                ],
              ),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            const SizedBox(height: DesignTokens.space6),
            _SectionHeader(title: l10n.t('section_language'), icon: Icons.language_rounded),
            _sectionCard(
              context,
              children: [
                ListTile(
                  leading: Icon(Icons.translate_rounded, color: AppThemeExtension.of(context).accent, size: 22),
                  title: Text('Dil', style: TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.w500)),
                  subtitle: Text(
                    l10n.t(AppLocalizations.languageCodeToLabelKey[localeState.valueOrNull?.languageCode ?? 'tr'] ??
                        'language_turkish'),
                    style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.7), fontSize: 12),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _openLanguageSelector(context, ref),
                ),
              ],
            ),
            const SizedBox(height: DesignTokens.space6),
            const _SectionHeader(title: 'İlanlar & Ofis', icon: Icons.apartment_rounded),
            _sectionCard(
              context,
              children: [
                const ListingDisplaySettingsSection(embeddedInSettingsHub: true),
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
              data: (flags) => _sectionCard(context,
                children: [
                  _SettingSwitch(
                    title: 'Market Pulse',
                    subtitle: 'Son ilanlar ve harici kaynaklar',
                    icon: Icons.trending_up_rounded,
                    value: flags[AppConstants.keyFeatureMarketPulse] ?? true,
                    onChanged: (v) =>
                        ref.read(featureFlagsProvider.notifier).setFlag(
                            AppConstants.keyFeatureMarketPulse, v),
                  ),
                  _SettingSwitch(
                    title: 'Portföy eşleştirme',
                    subtitle: 'Müşteri–ilan eşleşme önerisi',
                    icon: Icons.auto_awesome_rounded,
                    value: flags[AppConstants.keyFeaturePortfolioMatch] ?? true,
                    onChanged: (v) =>
                        ref.read(featureFlagsProvider.notifier).setFlag(
                            AppConstants.keyFeaturePortfolioMatch, v),
                  ),
                  _SettingSwitch(
                    title: 'Harici platform entegrasyonları',
                    subtitle: 'Sahibinden / Hepsiemlak / Emlakjet bağlı hesaplar',
                    icon: Icons.hub_rounded,
                    value: flags[AppConstants.keyFeatureExternalIntegrations] ?? true,
                    onChanged: (v) =>
                        ref.read(featureFlagsProvider.notifier).setFlag(
                            AppConstants.keyFeatureExternalIntegrations, v),
                  ),
                  if (flags[AppConstants.keyFeatureExternalIntegrations] ?? true) ...[
                    if (!canManagePlatformIntegrations) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                        child: Text(
                          l10n.t('integration_connections_read_only_notice'),
                          style: TextStyle(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                      ),
                      ListTile(
                        leading: Icon(Icons.collections_bookmark_outlined, color: theme.colorScheme.primary),
                        title: Text(l10n.t('my_external_listings_title'), style: TextStyle(color: theme.colorScheme.onSurface)),
                        subtitle: Text(
                          l10n.t('my_external_listings_settings_sub'),
                          style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.65), fontSize: 12),
                        ),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => context.push(AppRouter.routeMyExternalListings),
                      ),
                    ] else ...[
                      ListTile(
                        leading: Icon(Icons.hub_rounded, color: theme.colorScheme.primary),
                        title: Text(l10n.t('settings_platform_connections_tile'), style: TextStyle(color: theme.colorScheme.onSurface)),
                        subtitle: Text(
                          l10n.t('settings_platform_connections_tile_sub'),
                          style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.65), fontSize: 12),
                        ),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => context.push(AppRouter.routeConnectedAccounts),
                      ),
                      ListTile(
                        leading: Icon(Icons.auto_fix_high_outlined, color: theme.colorScheme.primary),
                        title: const Text('Platform kurulum sihirbazı'),
                        subtitle: Text(
                          'Resmi entegrasyon hazırlığı, transfer anahtarı, dosya ile toplu içe aktarma',
                          style: TextStyle(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
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
                        leading: Icon(Icons.upload_file_outlined, color: theme.colorScheme.primary),
                        title: const Text('Mağaza toplu içe aktarma'),
                        subtitle: Text(
                          'URL, dosya ve içe aktarma geçmişi',
                          style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.65), fontSize: 12),
                        ),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => context.push(AppRouter.routeImportHub),
                      ),
                      ListTile(
                        leading: Icon(Icons.history_rounded, color: theme.colorScheme.primary),
                        title: const Text('İçe aktarma geçmişi'),
                        subtitle: Text(
                          'Görev durumu ve loglar',
                          style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.65), fontSize: 12),
                        ),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => context.push(AppRouter.routeImportHistory),
                      ),
                      ListTile(
                        leading: Icon(Icons.collections_bookmark_rounded, color: theme.colorScheme.primary),
                        title: Text(l10n.t('my_external_listings_title'), style: TextStyle(color: theme.colorScheme.onSurface)),
                        subtitle: Text(
                          l10n.t('my_external_listings_settings_sub'),
                          style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.65), fontSize: 12),
                        ),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => context.push(AppRouter.routeMyExternalListings),
                      ),
                    ],
                  ],
                ],
              ),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 24),
            const _SectionHeader(title: 'Ürün & odak', icon: Icons.center_focus_strong_outlined),
            flagsAsync.when(
              data: (flags) => _sectionCard(
                context,
                children: [
                  _SettingSwitch(
                    title: 'Odaklı V1 (önerilen)',
                    subtitle:
                        'Açıkken: War Room ve Ekonomi sekmeleri ile ikincil analitik panelleri gizlenir; çekirdek CRM akışları kalır. Kapatınca tam özellik seti.',
                    icon: Icons.bolt_outlined,
                    value: flags[AppConstants.keyV1LeanProduct] ?? true,
                    onChanged: (v) =>
                        ref.read(featureFlagsProvider.notifier).setFlag(AppConstants.keyV1LeanProduct, v),
                  ),
                ],
              ),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            const SizedBox(height: DesignTokens.space6),
            const _SectionHeader(title: 'War Room & Raporlar', icon: Icons.analytics_rounded),
            flagsAsync.when(
              data: (flags) => _sectionCard(context,
                children: [
                  _SettingSwitch(
                    title: 'KPI çubuğu',
                    subtitle: 'Dashboard üst KPI göstergeleri',
                    icon: Icons.bar_chart_rounded,
                    value: flags[AppConstants.keyFeatureKpiBar] ?? true,
                    onChanged: (v) =>
                        ref.read(featureFlagsProvider.notifier).setFlag(
                            AppConstants.keyFeatureKpiBar, v),
                  ),
                  _SettingSwitch(
                    title: 'War Room',
                    subtitle: 'Ofis lider tablosu ve hedefler',
                    icon: Icons.military_tech_rounded,
                    value: flags[AppConstants.keyFeatureWarRoom] ?? true,
                    onChanged: (v) =>
                        ref.read(featureFlagsProvider.notifier).setFlag(
                            AppConstants.keyFeatureWarRoom, v),
                  ),
                  _SettingSwitch(
                    title: 'Çağrı Merkezi',
                    subtitle: 'Tüm çağrılar ve operasyon',
                    icon: Icons.call_merge_rounded,
                    value: flags[AppConstants.keyFeatureCommandCenter] ?? true,
                    onChanged: (v) =>
                        ref.read(featureFlagsProvider.notifier).setFlag(
                            AppConstants.keyFeatureCommandCenter, v),
                  ),
                  _SettingSwitch(
                    title: 'Günlük özet',
                    subtitle: 'Daily Brief paneli',
                    icon: Icons.today_rounded,
                    value: flags[AppConstants.keyFeatureDailyBrief] ?? true,
                    onChanged: (v) =>
                        ref.read(featureFlagsProvider.notifier).setFlag(
                            AppConstants.keyFeatureDailyBrief, v),
                  ),
                  _SettingSwitch(
                    title: 'Pipeline',
                    subtitle: 'Kanban ve aşama takibi',
                    icon: Icons.account_tree_rounded,
                    value: flags[AppConstants.keyFeaturePipeline] ?? true,
                    onChanged: (v) =>
                        ref.read(featureFlagsProvider.notifier).setFlag(
                            AppConstants.keyFeaturePipeline, v),
                  ),
                  _SettingSwitch(
                    title: 'Yatırımcı istihbaratı',
                    subtitle: 'Fırsat radarı ve yatırım panelleri',
                    icon: Icons.savings_rounded,
                    value: flags[AppConstants.keyFeatureInvestorIntelligence] ?? true,
                    onChanged: (v) =>
                        ref.read(featureFlagsProvider.notifier).setFlag(
                            AppConstants.keyFeatureInvestorIntelligence, v),
                  ),
                  _SettingSwitch(
                    title: 'Görevler',
                    subtitle: 'Takip ve hatırlatmalar',
                    icon: Icons.task_alt_rounded,
                    value: flags[AppConstants.keyFeatureTasks] ?? true,
                    onChanged: (v) =>
                        ref.read(featureFlagsProvider.notifier).setFlag(
                            AppConstants.keyFeatureTasks, v),
                  ),
                  _SettingSwitch(
                    title: 'Bildirim merkezi',
                    subtitle: 'Tüm bildirimler tek ekranda',
                    icon: Icons.notifications_rounded,
                    value: flags[AppConstants.keyFeatureNotificationsCenter] ?? true,
                    onChanged: (v) =>
                        ref.read(featureFlagsProvider.notifier).setFlag(
                            AppConstants.keyFeatureNotificationsCenter, v),
                  ),
                ],
              ),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            const SizedBox(height: DesignTokens.space6),
            const _SectionHeader(title: 'Yatırım & Piyasa', icon: Icons.show_chart_rounded),
            _sectionCard(
              context,
              children: const [
                _FavoriteInvestRegionTile(),
              ],
            ),
            const SizedBox(height: 24),
            const _SectionHeader(title: 'Gizlilik & Veri', icon: Icons.privacy_tip_rounded),
            flagsAsync.when(
              data: (flags) => _sectionCard(context,
                children: [
                  _SettingSwitch(
                    title: 'Analytics',
                    subtitle: 'Kullanım istatistikleri (anonim)',
                    icon: Icons.insights_rounded,
                    value: flags[AppConstants.keyFeatureAnalytics] ?? true,
                    onChanged: (v) =>
                        ref.read(featureFlagsProvider.notifier).setFlag(
                            AppConstants.keyFeatureAnalytics, v),
                  ),
                  _SettingSwitch(
                    title: 'Hata raporlama',
                    subtitle: 'Çökme raporları geliştiriciye gider',
                    icon: Icons.bug_report_rounded,
                    value: flags[AppConstants.keyFeatureCrashlytics] ?? true,
                    onChanged: (v) =>
                        ref.read(featureFlagsProvider.notifier).setFlag(
                            AppConstants.keyFeatureCrashlytics, v),
                  ),
                ],
              ),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            const SizedBox(height: DesignTokens.space6),
            const _SectionHeader(title: 'Hakkında', icon: Icons.info_outline_rounded),
            _sectionCard(
              context,
              children: const [
                EmlakMasterProductIdentityCard(),
              ],
            ),
            if (canSwitchRole) ...[
              const SizedBox(height: DesignTokens.space6),
              Padding(
                padding: const EdgeInsets.only(bottom: DesignTokens.space2),
                child: Row(
                  children: [
                    Icon(Icons.science_outlined, size: 16, color: AppThemeExtension.of(context).textTertiary),
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
                  ListTile(
                    leading: Icon(Icons.swap_horiz_rounded, color: AppThemeExtension.of(context).accent),
                    title: Text(
                      override != null ? 'Rol: ${override.label} (geri al)' : 'Rol değiştir (test)',
                      style: TextStyle(color: theme.colorScheme.onSurface),
                    ),
                    subtitle: Text(
                      'Yalnızca görünüm modu; üretim hesabını değiştirmez.',
                      style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.55), fontSize: 11),
                    ),
                    onTap: () => _showRoleSwitcher(context, ref, override),
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

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: ext.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(DesignTokens.radiusSheet)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  children: [
                    Text(
                      l10n.t('section_language'),
                      style: TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.w600, fontSize: 16),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: Icon(Icons.close_rounded, color: theme.colorScheme.onSurface.withValues(alpha: 0.65)),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: sheetH,
                child: ListView.separated(
                  itemCount: AppLocalizations.supportedLocales.length,
                  separatorBuilder: (_, __) => Divider(height: 1, color: theme.dividerColor.withValues(alpha: 0.5)),
                  itemBuilder: (context, i) {
                    final loc = AppLocalizations.supportedLocales[i];
                    final labelKey =
                        AppLocalizations.languageCodeToLabelKey[loc.languageCode] ?? loc.languageCode;
                    final label = l10n.t(labelKey);
                    final selected = current?.languageCode == loc.languageCode;
                    return ListTile(
                      leading: Icon(Icons.translate_rounded, color: ext.accent, size: 22),
                      title: Text(
                        label,
                        style: TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.w500),
                      ),
                      trailing: selected ? Icon(Icons.check_rounded, color: ext.accent) : null,
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

  void _showRoleSwitcher(BuildContext context, WidgetRef ref, AppRole? currentOverride) {
    showTestRoleSwitchSheet(context, ref, currentOverride);
  }

  Widget _sectionCard(BuildContext context, {required List<Widget> children, bool muted = false}) {
    final ext = AppThemeExtension.of(context);
    return Container(
      decoration: BoxDecoration(
        color: muted ? ext.surfaceElevated.withValues(alpha: 0.88) : ext.surfaceElevated,
        borderRadius: BorderRadius.circular(DesignTokens.radiusCardSecondary),
        border: Border.all(color: ext.border.withValues(alpha: muted ? 0.35 : 0.45)),
        boxShadow: [
          BoxShadow(
            color: ext.shadowColor.withValues(alpha: muted ? 0.06 : 0.12),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
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

class _FavoriteInvestRegionTileState extends ConsumerState<_FavoriteInvestRegionTile> {
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
    final v = ids.contains(raw) ? raw : AppConstants.defaultFavoriteInvestRegionId;
    return ListTile(
      leading: Icon(Icons.location_city_rounded, color: AppThemeExtension.of(context).accent, size: 22),
      title: Text(
        'Fırsat Endeksi bölgesi',
        style: TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        'Dashboard’daki yatırım iştahı özeti bu ilçeye göre hesaplanır.',
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
      AppToaster.warning(context, FirebaseStorageAvailability.unavailableMessage);
      return;
    }
    final picker = ImagePicker();
    final xFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 92);
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
        AppToaster.error(context, userFacingErrorMessage(e, context: 'settings_avatar'));
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
              Icon(Icons.photo_camera_rounded, color: AppThemeExtension.of(context).accent, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Profil fotoğrafı',
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.w500, fontSize: 13),
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
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
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
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.65),
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
      padding: const EdgeInsets.only(bottom: DesignTokens.space2, top: DesignTokens.space1),
      child: Row(
        children: [
          Icon(icon, size: 17, color: ext.accent.withValues(alpha: 0.9)),
          const SizedBox(width: DesignTokens.space2),
          Expanded(
            child: Text(
              title.toUpperCase(),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: ext.textSecondary,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
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
      secondary: Icon(icon, color: AppThemeExtension.of(context).accent, size: 22),
      title: Text(title, style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.w500)),
      subtitle: subtitle != null
          ? Text(subtitle!, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7), fontSize: 11))
          : null,
      value: value,
      activeThumbColor: AppThemeExtension.of(context).accent,
      onChanged: (v) => onChanged(v),
    );
  }
}
