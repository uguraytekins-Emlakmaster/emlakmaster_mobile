import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/core/providers/settings_provider.dart';
import 'package:emlakmaster_mobile/core/services/auth_service.dart';
import 'package:emlakmaster_mobile/features/auth/data/user_repository.dart';
import 'package:emlakmaster_mobile/features/listing_display/presentation/widgets/listing_display_settings_section.dart';
import 'package:emlakmaster_mobile/features/auth/domain/entities/app_role.dart';
import 'package:emlakmaster_mobile/features/auth/domain/permissions/feature_permission.dart';
import 'package:emlakmaster_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CustomersPlaceholderPage extends StatelessWidget {
  const CustomersPlaceholderPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bg = isDark ? DesignTokens.scaffoldDark : DesignTokens.backgroundLight;
    final onSurface = theme.colorScheme.onSurface;
    final onSurfaceVariant = onSurface.withOpacity(0.7);
    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.people_rounded,
                size: 64,
                color: onSurfaceVariant,
              ),
              const SizedBox(height: 16),
              Text(
                'Müşteriler',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: onSurface,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'CRM entegrasyonu ile müşteri listesi burada görünecek.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: onSurfaceVariant,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SettingsPlaceholderPage extends ConsumerWidget {
  const SettingsPlaceholderPage({super.key});

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

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bg = isDark ? DesignTokens.scaffoldDark : DesignTokens.backgroundLight;
    final onSurface = theme.colorScheme.onSurface;
    final onSurfaceVariant = onSurface.withOpacity(0.7);
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor ?? bg,
        foregroundColor: theme.appBarTheme.foregroundColor ?? onSurface,
        title: const Text('Ayarlar'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              'Görünüm',
              style: TextStyle(
                color: onSurfaceVariant,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            const ThemeSection(),
            const SizedBox(height: 24),
            Text(
              'Bildirimler',
              style: TextStyle(
                color: onSurfaceVariant,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            const NotificationsSection(),
            const SizedBox(height: 24),
            const ListingDisplaySettingsSection(),
            const SizedBox(height: 24),
            if (user != null) ...[
              ListTile(
                leading: const CircleAvatar(child: Icon(Icons.person_rounded)),
                title: Text(
                  user.email ?? 'Giriş yapılmış',
                  style: TextStyle(color: onSurface, fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  'Rol: ${override?.label ?? role.label}',
                  style: TextStyle(color: onSurfaceVariant, fontSize: 12),
                ),
              ),
              const SizedBox(height: 16),
            ],
            if (canBecomeAdmin) ...[
              Text(
                'Yetki',
                style: TextStyle(
                  color: onSurfaceVariant,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: const Icon(Icons.admin_panel_settings_rounded, color: DesignTokens.primary),
                title: Text(
                  'Yönetici yetkisi al',
                  style: TextStyle(color: onSurface),
                ),
                subtitle: Text(
                  'Firestore\'da rolünüz broker_owner olarak güncellenir; yönetici ve danışman paneline geçebilirsiniz.',
                  style: TextStyle(color: onSurfaceVariant, fontSize: 11),
                ),
                onTap: () async {
                  final u = user;
                  try {
                    await UserRepository.setUserDoc(
                      uid: u.uid,
                      role: 'broker_owner',
                      name: u.displayName,
                      email: u.email,
                    );
                    ref.invalidate(userDocStreamProvider(u.uid));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Yönetici yetkisi verildi. Panel yenileniyor...'),
                          backgroundColor: DesignTokens.primary,
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
              const SizedBox(height: 24),
            ],
            if (isAdmin) ...[
              Text(
                'Panel görünümü',
                style: TextStyle(
                  color: onSurfaceVariant,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: Icon(
                  Icons.dashboard_rounded,
                  color: preferConsultant != true ? DesignTokens.primary : onSurfaceVariant,
                ),
                title: Text('Yönetici paneli', style: TextStyle(color: onSurface)),
                subtitle: Text(
                  'Dashboard, War Room, Çağrı Merkezi, Ekonomi, Raporlar',
                  style: TextStyle(color: onSurfaceVariant, fontSize: 11),
                ),
                trailing: preferConsultant != true
                    ? const Icon(Icons.check_rounded, color: DesignTokens.primary)
                    : null,
                onTap: () {
                  ref.read(preferredConsultantPanelProvider.notifier).state = false;
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.person_rounded,
                  color: preferConsultant == true ? DesignTokens.primary : onSurfaceVariant,
                ),
                title: Text('Danışman paneli', style: TextStyle(color: onSurface)),
                subtitle: Text(
                  'Özetim, Müşterilerim, İlanlar, Takip, Magic Call',
                  style: TextStyle(color: onSurfaceVariant, fontSize: 11),
                ),
                trailing: preferConsultant == true
                    ? const Icon(Icons.check_rounded, color: DesignTokens.primary)
                    : null,
                onTap: () {
                  ref.read(preferredConsultantPanelProvider.notifier).state = true;
                },
              ),
              const SizedBox(height: 24),
            ],
            if (canSwitchRole) ...[
              Text(
                'Yönetici test',
                style: TextStyle(
                  color: onSurfaceVariant,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: const Icon(Icons.swap_horiz_rounded, color: DesignTokens.primary),
                title: Text(
                  override != null
                      ? 'Rol: ${override.label} (geri al)'
                      : 'Rol değiştir (test)',
                  style: TextStyle(color: onSurface),
                ),
                onTap: () => _showRoleSwitcher(context, ref, override),
              ),
              const SizedBox(height: 24),
            ],
            Text(
              'Hesap',
              style: TextStyle(
                color: onSurfaceVariant,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.logout_rounded, color: DesignTokens.danger),
              title: Text('Çıkış yap', style: TextStyle(color: onSurface)),
              onTap: () async {
                await AuthService.instance.signOut();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showRoleSwitcher(BuildContext context, WidgetRef ref, AppRole? currentOverride) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final sheetBg = isDark ? DesignTokens.surfaceDarkCard : DesignTokens.surfaceLight;
    final textColor = isDark ? DesignTokens.textPrimaryDark : DesignTokens.textPrimaryLight;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: sheetBg,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Test için rol seç (sadece görünüm)',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(color: textColor),
              ),
            ),
            ...AppRole.values.map((r) {
              return ListTile(
                title: Text(r.label, style: TextStyle(color: textColor)),
                trailing: currentOverride == r
                    ? const Icon(Icons.check_rounded, color: DesignTokens.primary)
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
}

class ThemeSection extends ConsumerWidget {
  const ThemeSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surface = isDark ? DesignTokens.surfaceDarkCard : DesignTokens.surfaceLight;
    final border = isDark ? DesignTokens.borderDark.withOpacity(0.5) : DesignTokens.borderLight;
    final onSurface = theme.colorScheme.onSurface;
    final onSurfaceVariant = onSurface.withOpacity(0.7);
    final index = ref.watch(themeModeIndexProvider);
    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Column(
        children: [
          ListTile(
            leading: Icon(
              index == 0 ? Icons.brightness_auto_rounded : (index == 1 ? Icons.light_mode_rounded : Icons.dark_mode_rounded),
              color: DesignTokens.primary,
            ),
            title: Text('Tema', style: TextStyle(color: onSurface)),
            subtitle: Text(
              index == 0 ? 'Sistem' : (index == 1 ? 'Açık' : 'Koyu'),
              style: TextStyle(color: onSurfaceVariant, fontSize: 12),
            ),
            trailing: Icon(Icons.chevron_right_rounded, color: onSurfaceVariant),
            onTap: () => ThemeSection._showThemePicker(context, ref, currentIndex: index),
          ),
        ],
      ),
    );
  }

  static void _showThemePicker(BuildContext context, WidgetRef ref, {required int currentIndex}) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final sheetBg = isDark ? DesignTokens.surfaceDarkCard : DesignTokens.surfaceLight;
    final textColor = isDark ? DesignTokens.textPrimaryDark : DesignTokens.textPrimaryLight;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: sheetBg,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Tema',
                style: TextStyle(color: textColor, fontWeight: FontWeight.w600, fontSize: 16),
              ),
            ),
            ListTile(
              title: Text('Sistem', style: TextStyle(color: textColor)),
              trailing: currentIndex == 0 ? const Icon(Icons.check_rounded, color: DesignTokens.primary) : null,
              onTap: () {
                ref.read(themeModeIndexProvider.notifier).setThemeModeIndex(0);
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              title: Text('Açık', style: TextStyle(color: textColor)),
              trailing: currentIndex == 1 ? const Icon(Icons.check_rounded, color: DesignTokens.primary) : null,
              onTap: () {
                ref.read(themeModeIndexProvider.notifier).setThemeModeIndex(1);
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              title: Text('Koyu', style: TextStyle(color: textColor)),
              trailing: currentIndex == 2 ? const Icon(Icons.check_rounded, color: DesignTokens.primary) : null,
              onTap: () {
                ref.read(themeModeIndexProvider.notifier).setThemeModeIndex(2);
                Navigator.pop(ctx);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class NotificationsSection extends ConsumerWidget {
  const NotificationsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surface = isDark ? DesignTokens.surfaceDarkCard : DesignTokens.surfaceLight;
    final border = isDark ? DesignTokens.borderDark.withOpacity(0.5) : DesignTokens.borderLight;
    final onSurface = theme.colorScheme.onSurface;
    final onSurfaceVariant = onSurface.withOpacity(0.7);
    final asyncEnabled = ref.watch(notificationsEnabledProvider);
    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: asyncEnabled.when(
        loading: () => ListTile(
          title: Text('Bildirimler', style: TextStyle(color: onSurface)),
          trailing: const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: DesignTokens.primary)),
        ),
        error: (_, __) => ListTile(
          title: Text('Bildirimler', style: TextStyle(color: onSurface)),
          subtitle: const Text('Yüklenemedi', style: TextStyle(color: Colors.red, fontSize: 12)),
        ),
        data: (enabled) => SwitchListTile(
          secondary: Icon(
            enabled ? Icons.notifications_active_rounded : Icons.notifications_off_rounded,
            color: DesignTokens.primary,
          ),
          title: Text('Bildirimler', style: TextStyle(color: onSurface)),
          subtitle: Text(
            'Push ve uygulama içi bildirimler',
            style: TextStyle(color: onSurfaceVariant, fontSize: 12),
          ),
          value: enabled,
          activeColor: DesignTokens.primary,
          onChanged: (v) => ref.read(notificationsEnabledProvider.notifier).setEnabled(v),
        ),
      ),
    );
  }
}
