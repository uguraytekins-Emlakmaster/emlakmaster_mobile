import 'package:emlakmaster_mobile/core/branding/brand_emblem.dart';
import 'package:emlakmaster_mobile/core/services/login_entry_store.dart';
import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/services/firestore_service.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/features/auth/data/user_repository.dart';
import 'package:emlakmaster_mobile/features/auth/domain/entities/app_role.dart';
import 'package:emlakmaster_mobile/features/auth/domain/login_entry_persona.dart';
import 'package:emlakmaster_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:emlakmaster_mobile/features/auth/presentation/widgets/auth_entry_persona_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';

/// İlk girişte rol seçimi: önce yönetici / danışman yolu, sonra detay rol.
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
  LoginEntryPersona? _pathPersona;
  bool _pathReady = false;

  @override
  void initState() {
    super.initState();
    _loadPathFromStore();
  }

  Future<void> _loadPathFromStore() async {
    final saved = await LoginEntryStore.instance.loadPersona();
    if (!mounted) return;
    setState(() {
      _pathPersona = saved;
      _pathReady = true;
    });
  }

  Future<void> _onPathSelected(LoginEntryPersona persona) async {
    await LoginEntryStore.instance.setPersona(persona);
    if (!mounted) return;
    setState(() => _pathPersona = persona);
  }

  void _clearPath() {
    setState(() => _pathPersona = null);
  }

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
      _applyPanelPreferenceForRole(AppRole.fromId(invite.role));
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

  static List<AppRole> _selectableRoles(bool includeSuperAdmin) {
    final list = AppRole.values
        .where((r) => r != AppRole.client && r != AppRole.guest)
        .toList();
    if (includeSuperAdmin) return list;
    return list.where((r) => r != AppRole.superAdmin).toList();
  }

  void _applyPanelPreferenceForRole(AppRole role) {
    ref.read(preferredConsultantPanelProvider.notifier).state =
        LoginEntryPersona.fromRole(role) == LoginEntryPersona.consultant;
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
      await LoginEntryStore.instance.setPersona(LoginEntryPersona.fromRole(role));
      _applyPanelPreferenceForRole(role);
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

  static String _subtitleForRole(AppRole role) {
    switch (role) {
      case AppRole.superAdmin:
        return 'Kurulum yöneticisi, tüm sistem';
      case AppRole.brokerOwner:
        return 'Şirket sahibi, tam yetki';
      case AppRole.generalManager:
        return 'Genel yönetim ve strateji';
      case AppRole.officeManager:
        return 'Ofis ve ekip yönetimi';
      case AppRole.teamLead:
        return 'Ekip liderliği ve koordinasyon';
      case AppRole.agent:
        return 'Müşteri, ilan ve görüşme operasyonu';
      case AppRole.operations:
        return 'Çağrı merkezi ve operasyon';
      case AppRole.financeInvestor:
        return 'Yatırım ve portföy takibi';
      case AppRole.investorPortal:
        return 'Yatırımcı portal erişimi';
      default:
        return role.label;
    }
  }

  static IconData _iconForRole(AppRole role) {
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
        return Icons.real_estate_agent_rounded;
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

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider).valueOrNull;
    final hasAnyUserAsync = ref.watch(hasAnyUserProvider);
    final ext = AppThemeExtension.of(context);

    if (user == null || !_pathReady) {
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
      return Scaffold(
        backgroundColor: ext.background,
        body: Center(child: CircularProgressIndicator(color: ext.accent)),
      );
    }

    final includeSuperAdmin = hasAnyUserAsync.valueOrNull == false;
    final allRoles = _selectableRoles(includeSuperAdmin);

    return Scaffold(
      backgroundColor: ext.background,
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              ext.background,
              Color.lerp(
                ext.background,
                _pathPersona == LoginEntryPersona.consultant
                    ? Color.lerp(ext.brandPrimary, ext.info, 0.45)!
                    : ext.brandPrimary,
                _pathPersona == null ? 0.04 : 0.09,
              )!,
            ],
          ),
        ),
        child: SafeArea(
          child: _pathPersona == null
              ? _PathPickerBody(
                  onSelected: _onPathSelected,
                  error: _error,
                )
              : _RoleListBody(
                  persona: _pathPersona!,
                  roles: _pathPersona!.filterSelectableRoles(
                    allRoles,
                    includeSuperAdmin: includeSuperAdmin,
                  ),
                  submitting: _submitting,
                  error: _error,
                  onBack: _clearPath,
                  onRoleSelected: _onRoleSelected,
                  subtitleForRole: _subtitleForRole,
                  iconForRole: _iconForRole,
                ),
        ),
      ),
    );
  }
}

class _PathPickerBody extends StatelessWidget {
  const _PathPickerBody({
    required this.onSelected,
    this.error,
  });

  final ValueChanged<LoginEntryPersona> onSelected;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 8),
            child: Column(
              children: [
                const BrandEmblem(
                  variant: BrandEmblemVariant.mini,
                  size: 72,
                ),
                const SizedBox(height: DesignTokens.space6),
                Text(
                  'Hoş geldiniz',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: ext.textPrimary,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: DesignTokens.space2),
                Text(
                  'Önce giriş türünüzü seçin; ardından size uygun rolü belirleyeceğiz.',
                  style: TextStyle(
                    color: ext.textSecondary,
                    fontSize: DesignTokens.fontSizeMd,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: DesignTokens.space8),
                AuthEntryPersonaSelector(
                  selected: null,
                  onSelected: onSelected,
                ),
              ],
            ),
          ),
        ),
        if (error != null)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              child: Text(
                error!,
                style: TextStyle(color: ext.danger, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}

class _RoleListBody extends StatelessWidget {
  const _RoleListBody({
    required this.persona,
    required this.roles,
    required this.submitting,
    required this.onBack,
    required this.onRoleSelected,
    required this.subtitleForRole,
    required this.iconForRole,
    this.error,
  });

  final LoginEntryPersona persona;
  final List<AppRole> roles;
  final bool submitting;
  final String? error;
  final VoidCallback onBack;
  final void Function(AppRole role) onRoleSelected;
  final String Function(AppRole role) subtitleForRole;
  final IconData Function(AppRole role) iconForRole;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    final accent = persona == LoginEntryPersona.manager
        ? ext.brandPrimary
        : Color.lerp(ext.brandPrimary, ext.info, 0.45)!;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 20, 0),
            child: Row(
              children: [
                IconButton(
                  onPressed: submitting ? null : onBack,
                  icon: Icon(Icons.arrow_back_ios_new_rounded,
                      color: ext.foregroundMuted, size: 20),
                ),
                Expanded(
                  child: Text(
                    persona.rolePathTitle,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: ext.textPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 4, 24, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: DesignTokens.space3,
                    vertical: DesignTokens.space1,
                  ),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(DesignTokens.radiusPill),
                    border: Border.all(color: accent.withValues(alpha: 0.35)),
                  ),
                  child: Text(
                    persona.rolePathSubtitle,
                    style: TextStyle(
                      color: accent,
                      fontSize: DesignTokens.fontSizeSm,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: DesignTokens.space2),
                Text(
                  'Size en yakın rolü seçin. Panel ve yetkiler buna göre açılır.',
                  style: TextStyle(
                    color: ext.textSecondary,
                    fontSize: DesignTokens.fontSizeSm,
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
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _RoleCard(
                    label: role.label,
                    subtitle: subtitleForRole(role),
                    icon: iconForRole(role),
                    accent: accent,
                    onTap: submitting ? null : () => onRoleSelected(role),
                  ),
                );
              },
              childCount: roles.length,
            ),
          ),
        ),
        if (error != null)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
              child: Text(
                error!,
                style: TextStyle(color: ext.danger, fontSize: 13),
              ),
            ),
          ),
        if (submitting)
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
        const SliverToBoxAdapter(child: SizedBox(height: 32)),
      ],
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.accent,
    this.onTap,
  });

  final String label;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    return Material(
      color: ext.card,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
        side: BorderSide(color: ext.border.withValues(alpha: 0.85)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      accent.withValues(alpha: 0.28),
                      accent.withValues(alpha: 0.08),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                ),
                child: Icon(icon, color: accent, size: 28),
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
                        fontSize: DesignTokens.fontSizeMd,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: ext.textSecondary,
                        fontSize: DesignTokens.fontSizeSm,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
              if (onTap != null)
                Icon(
                  Icons.chevron_right_rounded,
                  color: ext.textTertiary,
                  size: 22,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

final hasAnyUserProvider = FutureProvider.autoDispose<bool>((ref) {
  return UserRepository.hasAnyUser();
});
