import 'package:emlakmaster_mobile/core/services/firestore_service.dart';
import 'package:emlakmaster_mobile/features/auth/domain/permissions/feature_permission.dart';
import 'package:emlakmaster_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:emlakmaster_mobile/features/resurrection_engine/presentation/providers/resurrection_queue_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/design_tokens.dart';
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
    final resurrectionAsync = ref.watch(resurrectionQueueProvider);
    return Scaffold(
      backgroundColor: DesignTokens.backgroundDark,
      appBar: AppBar(
        title: const Text('War Room'),
        backgroundColor: DesignTokens.backgroundDark,
        foregroundColor: DesignTokens.textPrimaryDark,
        leading: ModalRoute.of(context)?.canPop == true
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => context.pop(),
              )
            : null,
        actions: [
          IconButton(
            icon: const Icon(Icons.call_rounded),
            onPressed: () => context.push('/command-center'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {},
        color: DesignTokens.primary,
        child: ListView(
          padding: const EdgeInsets.all(DesignTokens.space4),
          children: [
            const _SectionTitle(title: 'Bugünün nabzı', icon: Icons.monitor_heart),
            _LiveCallsStrip(),
            const SizedBox(height: DesignTokens.space4),
            const _SectionTitle(title: 'Yeniden kazanım kuyruğu', icon: Icons.replay_rounded),
            resurrectionAsync.when(
              data: (items) {
                if (items.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      '7+ gün sessiz lead yok.',
                      style: TextStyle(color: DesignTokens.textSecondaryDark),
                    ),
                  );
                }
                return Column(
                  children: items.take(10).map((e) => ListTile(
                    leading: const Icon(Icons.person_outline_rounded, color: DesignTokens.primary),
                    title: Text(e.customerName ?? e.customerId, style: const TextStyle(color: Colors.white)),
                    subtitle: Text('${e.daysSilent ?? 0} gün sessiz', style: const TextStyle(color: DesignTokens.textSecondaryDark, fontSize: 12)),
                    trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: DesignTokens.textTertiaryDark),
                    onTap: () {},
                  )).toList(),
                );
              },
              loading: () => const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator(color: DesignTokens.primary))),
              error: (e, _) => const Padding(
                padding: EdgeInsets.all(24),
                child: Text('Kuyruk yüklenemedi.', style: TextStyle(color: DesignTokens.danger)),
              ),
            ),
            const SizedBox(height: DesignTokens.space4),
            const _SectionTitle(title: 'Öncelikli aksiyonlar', icon: Icons.today_rounded),
            const Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Gecikmiş görevler ve at-risk deal\'ler burada listelenecek.',
                style: TextStyle(color: DesignTokens.textSecondaryDark, fontSize: 14),
              ),
            ),
          ],
        ),
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

class _LiveCallsStrip extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: FirestoreService.callsStream(),
      builder: (context, snap) {
        final count = snap.hasData ? snap.data!.docs.length : 0;
        return Container(
          padding: const EdgeInsets.all(DesignTokens.space4),
          decoration: BoxDecoration(
            color: DesignTokens.surfaceDark,
            borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
          ),
          child: Row(
            children: [
              const Icon(Icons.call_rounded, color: DesignTokens.primary, size: 28),
              const SizedBox(width: DesignTokens.space3),
              Text('Son çağrılar: $count kayıt', style: const TextStyle(color: DesignTokens.textPrimaryDark)),
            ],
          ),
        );
      },
    );
  }
}
