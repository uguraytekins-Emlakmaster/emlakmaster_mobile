import 'package:emlakmaster_mobile/core/branding/brand_emblem.dart';
import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/services/firestore_service.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/features/auth/data/user_repository.dart';
import 'package:emlakmaster_mobile/features/auth/domain/entities/app_role.dart';
import 'package:emlakmaster_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
/// İlk girişte kullanıcı henüz Firestore'da yoksa gösterilir.
/// Broker, Gayrimenkul Yatırım Uzmanı, Ofis Müdürü, Danışman vb. seçeneklerinden biri seçilir ve users doc oluşturulur.
class RoleSelectionPage extends ConsumerStatefulWidget {
  const RoleSelectionPage({super.key});

  @override
  ConsumerState<RoleSelectionPage> createState() => _RoleSelectionPageState();
}

class _RoleSelectionPageState extends ConsumerState<RoleSelectionPage> {
  bool _submitting = false;
  String? _error;
  bool _checkedInvite = false;
  bool _inviteCheckScheduled = false;

  /// Davet varsa rol ve ekip atanır, ana sayfaya yönlendirilir.
  Future<void> _checkAndApplyInvite() async {
    final user = ref.read(currentUserProvider).valueOrNull;
    if (user == null || user.email == null || user.email!.trim().isEmpty) {
      if (mounted) setState(() => _checkedInvite = true);
      return;
    }
    final invite = await FirestoreService.getInviteByEmail(user.email!);
    if (invite == null) {
      if (mounted) setState(() => _checkedInvite = true);
      return;
    }
    setState(() => _submitting = true);
    try {
      final String? teamId = invite.teamId;
      String? managerId;
      if (teamId != null && teamId.isNotEmpty) {
        final team = await FirestoreService.teamDocStream(teamId).first;
        managerId = team?.managerId;
      }
      await UserRepository.setUserDoc(
        uid: user.uid,
        role: invite.role,
        name: user.displayName,
        email: user.email,
        teamId: teamId,
        managerId: managerId,
      );
      if (teamId != null && teamId.isNotEmpty) {
        await FirestoreService.assignAgentToTeam(user.uid, teamId);
      }
      await FirestoreService.deleteInvite(invite.id);
      ref.invalidate(userDocStreamProvider(user.uid));
      if (mounted) context.go(AppRouter.routeHome);
    } catch (e) {
      if (mounted) {
        setState(() {
          _submitting = false;
          _checkedInvite = true;
          _error = 'Davet uygulanamadı. Rolü elle seçebilirsiniz.';
        });
      }
    }
  }

  /// Giriş türü seçenekleri (client ve guest hariç; ilk kullanıcı için super_admin eklenir).
  static List<AppRole> _selectableRoles(bool includeSuperAdmin) {
    final list = AppRole.values
        .where((r) => r != AppRole.client && r != AppRole.guest)
        .toList();
    if (includeSuperAdmin) return list;
    return list.where((r) => r != AppRole.superAdmin).toList();
  }

  Future<void> _onRoleSelected(AppRole role) async {
    final user = ref.read(currentUserProvider).valueOrNull;
    if (user == null) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await UserRepository.setUserDoc(
        uid: user.uid,
        role: role.id,
        name: user.displayName,
        email: user.email,
      );
      ref.invalidate(userDocStreamProvider(user.uid));
      HapticFeedback.mediumImpact();
      if (mounted) context.go(AppRouter.routeHome);
    } catch (e) {
      if (mounted) {
        setState(() {
          _submitting = false;
          _error = 'Rol kaydedilemedi. Tekrar deneyin.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider).valueOrNull;
    final hasAnyUserAsync = ref.watch(hasAnyUserProvider);

    if (user == null) {
      final ext = AppThemeExtension.of(context);
      return Scaffold(
        backgroundColor: ext.background,
        body: Center(child: CircularProgressIndicator(color: ext.accent)),
      );
    }

    if (!_checkedInvite) {
      if (!_inviteCheckScheduled) {
        _inviteCheckScheduled = true;
        WidgetsBinding.instance.addPostFrameCallback((_) => _checkAndApplyInvite());
      }
      final ext = AppThemeExtension.of(context);
      return Scaffold(
        backgroundColor: ext.background,
        body: Center(child: CircularProgressIndicator(color: ext.accent)),
      );
    }

    final includeSuperAdmin = hasAnyUserAsync.valueOrNull == false;
    final roles = _selectableRoles(includeSuperAdmin);

    final ext = AppThemeExtension.of(context);
    return Scaffold(
      backgroundColor: ext.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Center(
                      child: BrandEmblem(
                        variant: BrandEmblemVariant.mini,
                        size: 64,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Hoş geldiniz',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: ext.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Nasıl giriş yapmak istiyorsunuz? Seçtiğiniz rol panele ve yetkilere yansır.',
                      style: TextStyle(
                        color: ext.textSecondary,
                        fontSize: 14,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final role = roles[index];
                    final isBroker = role == AppRole.brokerOwner;
                    final isInvestor = role == AppRole.financeInvestor ||
                        role == AppRole.investorPortal;
                    final isManager = role == AppRole.officeManager ||
                        role == AppRole.teamLead ||
                        role == AppRole.generalManager ||
                        role == AppRole.operations;
                    String subtitle = '';
                    if (isBroker) subtitle = 'Şirket sahibi, tüm yetkiler';
                    if (isInvestor) subtitle = 'Gayrimenkul yatırım uzmanı, portföy takibi';
                    if (isManager) subtitle = 'Yönetici, ekip ve çağrı merkezi';
                    if (role == AppRole.agent) subtitle = 'Danışman, müşteri ve ilan yönetimi';
                    if (role == AppRole.superAdmin) subtitle = 'Kurulum yöneticisi, tüm sistem';

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _RoleCard(
                        label: role.label,
                        subtitle: subtitle.isEmpty ? role.label : subtitle,
                        icon: _iconForRole(role),
                        onTap: _submitting
                            ? null
                            : () => _onRoleSelected(role),
                      ),
                    );
                  },
                  childCount: roles.length,
                ),
              ),
            ),
            if (_error != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                  child: Text(
                    _error!,
                    style: TextStyle(
                      color: ext.danger,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            if (_submitting)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: ext.accent,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  IconData _iconForRole(AppRole role) {
    switch (role) {
      case AppRole.superAdmin:
        return Icons.admin_panel_settings_rounded;
      case AppRole.brokerOwner:
        return Icons.business_center_rounded;
      case AppRole.generalManager:
        return Icons.badge_rounded;
      case AppRole.officeManager:
        return Icons.manage_accounts_rounded;
      case AppRole.teamLead:
        return Icons.groups_rounded;
      case AppRole.agent:
        return Icons.person_rounded;
      case AppRole.operations:
        return Icons.headset_mic_rounded;
      case AppRole.financeInvestor:
        return Icons.trending_up_rounded;
      case AppRole.investorPortal:
        return Icons.savings_rounded;
      default:
        return Icons.person_rounded;
    }
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.label,
    required this.subtitle,
    required this.icon,
    this.onTap,
  });

  final String label;
  final String subtitle;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    return Material(
      color: ext.card,
      borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: ext.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                ),
                child: Icon(icon, color: ext.accent, size: 26),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        color: ext.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: ext.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (onTap != null)
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: ext.textTertiary,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Koleksiyonda en az bir kullanıcı var mı? (İlk kullanıcı = super_admin seçeneği göster.)
final hasAnyUserProvider = FutureProvider.autoDispose<bool>((ref) {
  return UserRepository.hasAnyUser();
});
