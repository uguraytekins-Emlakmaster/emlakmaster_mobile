import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/features/auth/domain/permissions/feature_permission.dart';
import 'package:emlakmaster_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:emlakmaster_mobile/features/resurrection_engine/presentation/providers/resurrection_queue_provider.dart';
import 'package:emlakmaster_mobile/features/war_room/presentation/widgets/war_room_command_center.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/widgets/unauthorized_screen.dart';

/// Role-Based War Room: aktif çağrılar, sıcak fırsatlar, gecikmiş görevler, yüksek değerli lead'ler, danışman durumu.
class WarRoomPage extends ConsumerWidget {
  const WarRoomPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roleAsync = ref.watch(displayRoleProvider);
    return roleAsync.when(
      loading: () => const Scaffold(
        backgroundColor: Color(0xFF0D1117),
        body: Center(child: CircularProgressIndicator(color: Color(0xFF00FF41))),
      ),
      error: (_, __) => const UnauthorizedScreen(message: 'Rol yüklenemedi.'),
      data: (role) {
        if (!FeaturePermission.canViewWarRoom(role)) {
          return const UnauthorizedScreen(
            message: 'War Room ekranına sadece yönetici ve operasyon erişebilir.',
          );
        }
        return _WarRoomBody();
      },
    );
  }
}

class _WarRoomBody extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: DesignTokens.backgroundDark,
      body: Column(
        children: [
          Expanded(child: WarRoomCommandCenter()),
          _ResurrectionStrip(),
        ],
      ),
    );
  }
}

class _ResurrectionStrip extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resurrectionAsync = ref.watch(resurrectionQueueProvider);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: DesignTokens.space4, vertical: DesignTokens.space2),
      decoration: BoxDecoration(
        color: DesignTokens.surfaceDark,
        border: Border(top: BorderSide(color: DesignTokens.borderDark)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(title: 'Yeniden kazanım kuyruğu', icon: Icons.replay_rounded),
          const SizedBox(height: 8),
          resurrectionAsync.when(
            data: (items) {
              if (items.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text('7+ gün sessiz lead yok.', style: TextStyle(color: DesignTokens.textSecondaryDark, fontSize: 12)),
                );
              }
              return SizedBox(
                height: 44,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: items.take(10).length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, i) {
                    final e = items[i];
                    return ActionChip(
                      avatar: const Icon(Icons.person_outline_rounded, size: 18, color: DesignTokens.primary),
                      label: Text('${e.customerName ?? e.customerId} • ${e.daysSilent ?? 0}g', style: const TextStyle(fontSize: 11)),
                      onPressed: () {},
                      backgroundColor: DesignTokens.surfaceDarkElevated,
                      side: BorderSide(color: DesignTokens.borderDark),
                    );
                  },
                ),
              );
            },
            loading: () => const SizedBox(height: 36, child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: DesignTokens.primary))),
            error: (_, __) => const Text('Kuyruk yüklenemedi.', style: TextStyle(color: DesignTokens.danger, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.icon});
  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: DesignTokens.space2),
      child: Row(
        children: [
          Icon(icon, size: 20, color: DesignTokens.primary),
          const SizedBox(width: DesignTokens.space2),
          Text(title, style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

