import 'package:emlakmaster_mobile/core/providers/settings_provider.dart';
import 'package:emlakmaster_mobile/core/services/auth_service.dart';
import 'package:emlakmaster_mobile/features/auth/data/user_repository.dart';
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
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.people_rounded,
                size: 64,
                color: Colors.white.withOpacity(0.3),
              ),
              const SizedBox(height: 16),
              Text(
                'Müşteriler',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 8),
              const Text(
                'CRM entegrasyonu ile müşteri listesi burada görünecek.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white54,
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

    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1117),
        foregroundColor: Colors.white,
        title: const Text('Ayarlar'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const Text(
              'Görünüm',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            const _ThemeSection(),
            const SizedBox(height: 24),
            const Text(
              'Bildirimler',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            const _NotificationsSection(),
            const SizedBox(height: 24),
            if (user != null) ...[
              ListTile(
                leading: const CircleAvatar(child: Icon(Icons.person_rounded)),
                title: Text(
                  user.email ?? 'Giriş yapılmış',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  'Rol: ${override?.label ?? role.label}',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ),
              const SizedBox(height: 16),
            ],
            if (canBecomeAdmin) ...[
              const Text(
                'Yetki',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: const Icon(Icons.admin_panel_settings_rounded, color: Color(0xFF00FF41)),
                title: const Text(
                  'Yönetici yetkisi al',
                  style: TextStyle(color: Colors.white),
                ),
                subtitle: const Text(
                  'Firestore\'da rolünüz broker_owner olarak güncellenir; yönetici ve danışman paneline geçebilirsiniz.',
                  style: TextStyle(color: Colors.white54, fontSize: 11),
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
                          backgroundColor: Color(0xFF00FF41),
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
              const Text(
                'Panel görünümü',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: Icon(
                  Icons.dashboard_rounded,
                  color: preferConsultant != true ? const Color(0xFF00FF41) : Colors.white54,
                ),
                title: const Text('Yönetici paneli', style: TextStyle(color: Colors.white)),
                subtitle: const Text(
                  'Dashboard, War Room, Çağrı Merkezi, Ekonomi, Raporlar',
                  style: TextStyle(color: Colors.white54, fontSize: 11),
                ),
                trailing: preferConsultant != true
                    ? const Icon(Icons.check_rounded, color: Color(0xFF00FF41))
                    : null,
                onTap: () {
                  ref.read(preferredConsultantPanelProvider.notifier).state = false;
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.person_rounded,
                  color: preferConsultant == true ? const Color(0xFF00FF41) : Colors.white54,
                ),
                title: const Text('Danışman paneli', style: TextStyle(color: Colors.white)),
                subtitle: const Text(
                  'Özetim, Müşterilerim, İlanlar, Takip, Magic Call',
                  style: TextStyle(color: Colors.white54, fontSize: 11),
                ),
                trailing: preferConsultant == true
                    ? const Icon(Icons.check_rounded, color: Color(0xFF00FF41))
                    : null,
                onTap: () {
                  ref.read(preferredConsultantPanelProvider.notifier).state = true;
                },
              ),
              const SizedBox(height: 24),
            ],
            if (canSwitchRole) ...[
              const Text(
                'Yönetici test',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: const Icon(Icons.swap_horiz_rounded, color: Color(0xFF00FF41)),
                title: Text(
                  override != null
                      ? 'Rol: ${override.label} (geri al)'
                      : 'Rol değiştir (test)',
                  style: const TextStyle(color: Colors.white),
                ),
                onTap: () => _showRoleSwitcher(context, ref, override),
              ),
              const SizedBox(height: 24),
            ],
            const Text(
              'Hesap',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.logout_rounded, color: Color(0xFFE53935)),
              title: const Text('Çıkış yap', style: TextStyle(color: Colors.white)),
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
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF161B22),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Test için rol seç (sadece görünüm)',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white),
              ),
            ),
            ...AppRole.values.map((r) {
              return ListTile(
                title: Text(r.label, style: const TextStyle(color: Colors.white)),
                trailing: currentOverride == r
                    ? const Icon(Icons.check_rounded, color: Color(0xFF00FF41))
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

class _ThemeSection extends ConsumerWidget {
  const _ThemeSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = ref.watch(themeModeIndexProvider);
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          ListTile(
            leading: Icon(
              index == 0 ? Icons.brightness_auto_rounded : (index == 1 ? Icons.light_mode_rounded : Icons.dark_mode_rounded),
              color: const Color(0xFF00FF41),
            ),
            title: const Text('Tema', style: TextStyle(color: Colors.white)),
            subtitle: Text(
              index == 0 ? 'Sistem' : (index == 1 ? 'Açık' : 'Koyu'),
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
            trailing: const Icon(Icons.chevron_right_rounded, color: Colors.white54),
            onTap: () => _showThemePicker(context, ref, index),
          ),
        ],
      ),
    );
  }

  void _showThemePicker(BuildContext context, WidgetRef ref, int currentIndex) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF161B22),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Tema',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16),
              ),
            ),
            ListTile(
              title: const Text('Sistem', style: TextStyle(color: Colors.white)),
              trailing: currentIndex == 0 ? const Icon(Icons.check_rounded, color: Color(0xFF00FF41)) : null,
              onTap: () {
                ref.read(themeModeIndexProvider.notifier).setThemeModeIndex(0);
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              title: const Text('Açık', style: TextStyle(color: Colors.white)),
              trailing: currentIndex == 1 ? const Icon(Icons.check_rounded, color: Color(0xFF00FF41)) : null,
              onTap: () {
                ref.read(themeModeIndexProvider.notifier).setThemeModeIndex(1);
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              title: const Text('Koyu', style: TextStyle(color: Colors.white)),
              trailing: currentIndex == 2 ? const Icon(Icons.check_rounded, color: Color(0xFF00FF41)) : null,
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

class _NotificationsSection extends ConsumerWidget {
  const _NotificationsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncEnabled = ref.watch(notificationsEnabledProvider);
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: asyncEnabled.when(
        loading: () => const ListTile(
          title: Text('Bildirimler', style: TextStyle(color: Colors.white)),
          trailing: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF00FF41))),
        ),
        error: (_, __) => const ListTile(
          title: Text('Bildirimler', style: TextStyle(color: Colors.white)),
          subtitle: Text('Yüklenemedi', style: TextStyle(color: Colors.red, fontSize: 12)),
        ),
        data: (enabled) => SwitchListTile(
          secondary: Icon(
            enabled ? Icons.notifications_active_rounded : Icons.notifications_off_rounded,
            color: const Color(0xFF00FF41),
          ),
          title: const Text('Bildirimler', style: TextStyle(color: Colors.white)),
          subtitle: const Text(
            'Push ve uygulama içi bildirimler',
            style: TextStyle(color: Colors.white54, fontSize: 12),
          ),
          value: enabled,
          activeColor: const Color(0xFF00FF41),
          onChanged: (v) => ref.read(notificationsEnabledProvider.notifier).setEnabled(v),
        ),
      ),
    );
  }
}
