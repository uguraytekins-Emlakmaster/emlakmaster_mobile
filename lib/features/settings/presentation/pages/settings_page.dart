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
import 'package:emlakmaster_mobile/features/settings/presentation/providers/feature_flags_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:emlakmaster_mobile/features/profile/presentation/widgets/profile_avatar.dart';
import 'package:image_picker/image_picker.dart';
import 'package:emlakmaster_mobile/core/platform/file_stub.dart'
    if (dart.library.io) 'dart:io' as io;
import 'package:emlakmaster_mobile/features/profile/data/profile_avatar_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../../../shared/widgets/emlak_app_bar.dart';
import '../../../../screens/placeholder_pages.dart' show NotificationsSection, ThemeSection;

/// Kategorize ayarlar: Hesap & Giriş, Görünüm, Bildirimler, Çağrı & CRM, İlanlar, War Room, Ses, Gizlilik, Hakkında.
/// Tüm özellikler açılıp kapatılabilir veya detay sayfasından düzenlenir.
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
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            const _SectionHeader(title: 'Hesap & Giriş', icon: Icons.person_rounded),
            _sectionCard(context,
              children: [
                if (user != null) ...[
                  ListTile(
                    leading: ProfileAvatar(
                      size: 44,
                      imageUrl: ref.watch(userDocStreamProvider(user.uid)).valueOrNull?.avatarUrl,
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
                            SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
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
                if (canSwitchRole) ...[
                  Divider(height: 1, color: theme.dividerColor.withValues(alpha: 0.5)),
                  ListTile(
                    leading: Icon(Icons.swap_horiz_rounded, color: AppThemeExtension.of(context).accent),
                    title: Text(
                      override != null ? 'Rol: ${override.label} (geri al)' : 'Rol değiştir (test)',
                      style: TextStyle(color: theme.colorScheme.onSurface),
                    ),
                    onTap: () => _showRoleSwitcher(context, ref, override),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 24),
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
            const SizedBox(height: 24),
            _SectionHeader(title: l10n.t('section_appearance'), icon: Icons.palette_rounded),
            const ThemeSection(),
            const SizedBox(height: 12),
            flagsAsync.when(
              data: (flags) => _sectionCard(context,
                children: [
                  _SettingSwitch(
                    title: l10n.t('compact_dashboard'),
                    subtitle: l10n.t('compact_dashboard_sub'),
                    icon: Icons.dashboard_customize_rounded,
                    value: flags[AppConstants.keyCompactDashboard] ?? false,
                    onChanged: (v) =>
                        ref.read(featureFlagsProvider.notifier).setFlag(
                            AppConstants.keyCompactDashboard, v),
                  ),
                  _SettingSwitch(
                    title: l10n.t('power_saver'),
                    subtitle: l10n.t('power_saver_sub'),
                    icon: Icons.battery_saver_rounded,
                    value: flags[AppConstants.keyPowerSaver] ?? false,
                    onChanged: (v) =>
                        ref.read(featureFlagsProvider.notifier).setFlag(
                            AppConstants.keyPowerSaver, v),
                  ),
                ],
              ),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 24),
            _SectionHeader(title: l10n.t('section_language'), icon: Icons.language_rounded),
            _sectionCard(context,
              children: [
                for (var i = 0; i < AppLocalizations.supportedLocales.length; i++) ...[
                  if (i > 0) Divider(height: 1, color: theme.dividerColor.withValues(alpha: 0.5)),
                  ListTile(
                    leading: Icon(Icons.translate_rounded, color: AppThemeExtension.of(context).accent, size: 22),
                    title: Text(
                      l10n.t(AppLocalizations.languageCodeToLabelKey[AppLocalizations.supportedLocales[i].languageCode] ?? AppLocalizations.supportedLocales[i].languageCode),
                      style: TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.w500),
                    ),
                    trailing: localeState.valueOrNull?.languageCode == AppLocalizations.supportedLocales[i].languageCode
                        ? Icon(Icons.check_rounded, color: AppThemeExtension.of(context).accent)
                        : null,
                    onTap: () => ref.read(localeProvider.notifier).setLocale(AppLocalizations.supportedLocales[i]),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 24),
            _SectionHeader(title: l10n.t('section_notifications'), icon: Icons.notifications_rounded),
            const NotificationsSection(),
            const SizedBox(height: 12),
            flagsAsync.when(
              data: (flags) => _sectionCard(context,
                children: [
                  _SettingSwitch(
                    title: l10n.t('push_notifications'),
                    subtitle: l10n.t('push_notifications_sub'),
                    icon: Icons.notifications_active_rounded,
                    value: flags[AppConstants.keyFeaturePushNotifications] ?? true,
                    onChanged: (v) =>
                        ref.read(featureFlagsProvider.notifier).setFlag(
                            AppConstants.keyFeaturePushNotifications, v),
                  ),
                ],
              ),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 24),
            const _SectionHeader(title: 'Çağrı & CRM', icon: Icons.call_rounded),
            _sectionCard(context,
              children: [
                ListTile(
                  leading: Icon(Icons.call_made_rounded, color: AppThemeExtension.of(context).accent, size: 22),
                  title: Text('Tüm Çağrılar', style: TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.w500)),
                  subtitle: Text(
                    'Danışman paneli → Çağrılar: kendi çağrılarınız, CSV export, toplu SMS. Android\'de telefon günlüğü senkronu.',
                    style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.7), fontSize: 11),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            flagsAsync.when(
              data: (flags) => _sectionCard(context,
                children: [
                  _SettingSwitch(
                    title: 'Sesli CRM (Magic Call)',
                    subtitle: 'Sesli komut ve hands-free',
                    icon: Icons.mic_rounded,
                    value: flags[AppConstants.keyFeatureVoiceCrm] ?? true,
                    onChanged: (v) =>
                        ref.read(featureFlagsProvider.notifier).setFlag(
                            AppConstants.keyFeatureVoiceCrm, v),
                  ),
                  _SettingSwitch(
                    title: 'Rehbere / uygulamaya kaydet',
                    subtitle: 'Arama sonrası rehber ve müşteri kaydı',
                    icon: Icons.contact_phone_rounded,
                    value: flags[AppConstants.keyFeatureContactSave] ?? true,
                    onChanged: (v) =>
                        ref.read(featureFlagsProvider.notifier).setFlag(
                            AppConstants.keyFeatureContactSave, v),
                  ),
                  _SettingSwitch(
                    title: 'Çağrı özeti (AI)',
                    subtitle: 'Arama sonrası otomatik özet',
                    icon: Icons.summarize_rounded,
                    value: flags[AppConstants.keyFeatureCallSummary] ?? true,
                    onChanged: (v) =>
                        ref.read(featureFlagsProvider.notifier).setFlag(
                            AppConstants.keyFeatureCallSummary, v),
                  ),
                ],
              ),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 24),
            const _SectionHeader(title: 'İlanlar & Eşleştirme', icon: Icons.home_work_rounded),
            const ListingDisplaySettingsSection(),
            const SizedBox(height: 12),
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
                    ListTile(
                      leading: Icon(Icons.link_rounded, color: theme.colorScheme.primary),
                      title: Text('Bağlı hesapları yönet', style: TextStyle(color: theme.colorScheme.onSurface)),
                      subtitle: Text(
                        'Harici ilan hesaplarını bağla veya senkron durumunu gör',
                        style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.65), fontSize: 12),
                      ),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => context.push(AppRouter.routeConnectedAccounts),
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
              ),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 24),
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
            const SizedBox(height: 24),
            const _SectionHeader(title: 'Ses & Erişilebilirlik', icon: Icons.hearing_rounded),
            flagsAsync.when(
              data: (flags) => _sectionCard(context,
                children: [
                  _SettingSwitch(
                    title: 'Titreşim (haptic)',
                    subtitle: 'Butonlarda dokunsal geri bildirim',
                    icon: Icons.vibration_rounded,
                    value: flags[AppConstants.keyHapticFeedback] ?? true,
                    onChanged: (v) =>
                        ref.read(featureFlagsProvider.notifier).setFlag(
                            AppConstants.keyHapticFeedback, v),
                  ),
                  _SettingSwitch(
                    title: 'Ses efektleri',
                    subtitle: 'Bildirim ve onay sesleri',
                    icon: Icons.volume_up_rounded,
                    value: flags[AppConstants.keySoundEffects] ?? false,
                    onChanged: (v) =>
                        ref.read(featureFlagsProvider.notifier).setFlag(
                            AppConstants.keySoundEffects, v),
                  ),
                ],
              ),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 24),
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
            const SizedBox(height: 24),
            const _SectionHeader(title: 'Hakkında', icon: Icons.info_outline_rounded),
            _sectionCard(context,
              children: [
                ListTile(
                  leading: Icon(Icons.phone_android_rounded, color: AppThemeExtension.of(context).accent, size: 22),
                  title: Text(
                    AppConstants.appName,
                    style: TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    '${AppConstants.appShortName} • v${AppConstants.appVersion.split('+').first}',
                    style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.7), fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const _SectionHeader(title: 'Hesap', icon: Icons.logout_rounded),
            _sectionCard(context,
              children: [
                ListTile(
                  leading: Icon(Icons.logout_rounded, color: AppThemeExtension.of(context).danger),
                  title: Text('Çıkış yap', style: TextStyle(color: theme.colorScheme.onSurface)),
                  onTap: () => AuthService.instance.signOut(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showRoleSwitcher(BuildContext context, WidgetRef ref, AppRole? currentOverride) {
    final theme = Theme.of(context);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: theme.colorScheme.surface,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Test için rol seç (sadece görünüm)',
                style: TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.w600),
              ),
            ),
            ...AppRole.values.map((r) {
              return ListTile(
                title: Text(r.label, style: TextStyle(color: theme.colorScheme.onSurface)),
                trailing: currentOverride == r
                    ? Icon(Icons.check_rounded, color: AppThemeExtension.of(context).accent)
                    : null,
                onTap: () {
                  ref.read(overrideRoleProvider.notifier).state =
                      currentOverride == r ? null : r;
                  Navigator.pop(ctx);
                },
              );
            }),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _sectionCard(BuildContext context, {required List<Widget> children}) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(DesignTokens.uiSurfaceRadius),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.5)),
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
    final storageOk = storageAsync.when(
      data: (ok) => ok,
      loading: () => true,
      error: (_, __) => false,
    );
    if (!storageOk) {
      AppToaster.warning(context, FirebaseStorageAvailability.unavailableMessage);
      return;
    }
    final picker = ImagePicker();
    final xFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (xFile == null) return;
    setState(() => _loading = true);
    try {
      final String? url;
      if (kIsWeb) {
        final bytes = await xFile.readAsBytes();
        url = await ProfileAvatarService.instance.uploadAvatarFromBytes(uid: widget.userId, bytes: bytes);
      } else {
        final file = io.File(xFile.path);
        url = await ProfileAvatarService.instance.uploadAvatar(uid: widget.userId, file: file);
      }
      if (!mounted) return;
      if (url != null && url.isNotEmpty) {
        AppToaster.success(context, 'Profil fotoğrafı güncellendi.');
      } else {
        AppToaster.warning(context, FirebaseStorageAvailability.unavailableMessage);
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
    final storageOk = storageAsync.when(
      data: (ok) => ok,
      loading: () => true,
      error: (_, __) => false,
    );
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
                onPressed: (_loading || !storageOk) ? null : _pickAndUpload,
                child: Text(_loading ? 'Yükleniyor…' : 'Fotoğraf seç'),
              ),
              const SizedBox(width: 4),
              TextButton(
                onPressed: _loading ? null : _removeAvatar,
                child: const Text('Kaldır'),
              ),
            ],
          ),
          if (!storageOk) ...[
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


class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.icon});

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
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
