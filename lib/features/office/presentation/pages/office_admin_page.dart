import 'package:emlakmaster_mobile/core/router/app_router.dart';
import 'package:emlakmaster_mobile/features/admin_ofis_masasi/presentation/widgets/ofis_masasi_chrome.dart';
import 'package:emlakmaster_mobile/features/admin_ofis_masasi/presentation/widgets/ofis_masasi_command_surface.dart';
import 'package:emlakmaster_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:emlakmaster_mobile/features/office/domain/membership_status.dart';
import 'package:emlakmaster_mobile/features/office/domain/office_role.dart';
import 'package:emlakmaster_mobile/widgets/premium/v2/premium_shell_chrome.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Ofis Masası — ofis durumu, üyeler, davetler ve platform bağlantıları (Screen 17).
/// Rota kimliği korunur: `/office/admin`.
class OfficeAdminPage extends ConsumerWidget {
  const OfficeAdminPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).valueOrNull;
    final doc = user != null
        ? ref.watch(userDocStreamProvider(user.uid)).valueOrNull
        : null;
    final oid = doc?.officeId;
    final mem = ref.watch(primaryMembershipProvider).valueOrNull;
    final canAdmin = mem != null &&
        mem.status == MembershipStatus.active &&
        (mem.role == OfficeRole.owner ||
            mem.role == OfficeRole.admin ||
            mem.role == OfficeRole.manager);

    if (oid == null || oid.isEmpty) {
      return PremiumShellBackdrop(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: OfisMasasiEmptyState(
              icon: Icons.apartment_outlined,
              title: 'Ofis bağlantısı gerekiyor',
              message:
                  'Ofis masasını açmak için önce bir ofise bağlanın.',
              actionLabel: 'Ofis alanına git',
              onAction: () => context.push(AppRouter.routeOfficeGate),
            ),
          ),
        ),
      );
    }

    if (!canAdmin) {
      return const PremiumShellBackdrop(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: OfisMasasiEmptyState(
              icon: Icons.lock_outline_rounded,
              title: 'Bu alan için yetki gerekiyor',
              message:
                  'Yalnızca ofis sahibi, yönetici veya müdür ofis masasını yönetebilir.',
            ),
          ),
        ),
      );
    }

    return PremiumShellBackdrop(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: OfisMasasiCommandSurface(officeId: oid),
      ),
    );
  }
}
