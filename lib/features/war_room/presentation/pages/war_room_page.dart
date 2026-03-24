import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/features/resurrection_engine/presentation/widgets/resurrection_lead_topic_sheet.dart';
import 'package:emlakmaster_mobile/features/auth/domain/permissions/feature_permission.dart';
import 'package:emlakmaster_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:emlakmaster_mobile/features/resurrection_engine/presentation/providers/resurrection_queue_provider.dart';
import 'package:emlakmaster_mobile/features/war_room/presentation/widgets/war_room_command_center.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/widgets/unauthorized_screen.dart';
/// Role-Based War Room: aktif çağrılar, sıcak fırsatlar, gecikmiş görevler, yüksek değerli lead'ler, danışman durumu.
class WarRoomPage extends ConsumerWidget {
  const WarRoomPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roleAsync = ref.watch(displayRoleProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final loadingBg = isDark ? AppThemeExtension.of(context).background : AppThemeExtension.of(context).background;
    return roleAsync.when(
      loading: () => Scaffold(
        backgroundColor: loadingBg,
        body: Center(child: CircularProgressIndicator(color: AppThemeExtension.of(context).accent)),
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bg = isDark ? AppThemeExtension.of(context).background : AppThemeExtension.of(context).background;
    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            const Expanded(child: WarRoomCommandCenter()),
            _ResurrectionStrip(),
          ],
        ),
      ),
    );
  }
}

class _ResurrectionStrip extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surface = isDark ? AppThemeExtension.of(context).surface : AppThemeExtension.of(context).surface;
    final border = isDark ? AppThemeExtension.of(context).border : AppThemeExtension.of(context).border;
    final textSecondary = isDark ? AppThemeExtension.of(context).textSecondary : AppThemeExtension.of(context).textSecondary;
    final resurrectionAsync = ref.watch(resurrectionQueueProvider);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: DesignTokens.space4, vertical: DesignTokens.space2),
      decoration: BoxDecoration(
        color: surface,
        border: Border(top: BorderSide(color: border)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(title: 'Yeniden kazanım kuyruğu', icon: Icons.replay_rounded),
          const SizedBox(height: 8),
          resurrectionAsync.when(
            data: (items) {
              final elevated = isDark ? AppThemeExtension.of(context).surfaceElevated : AppThemeExtension.of(context).surfaceElevated;
              if (items.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text('7+ gün sessiz lead yok.', style: TextStyle(color: textSecondary, fontSize: 12)),
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
                      avatar: Icon(Icons.person_outline_rounded, size: 18, color: AppThemeExtension.of(context).accent),
                      label: Text('${e.customerName ?? e.customerId} • ${e.daysSilent ?? 0}g', style: const TextStyle(fontSize: 11)),
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        showResurrectionLeadTopicSheet(
                          context,
                          topicTitle: 'Yeniden kazanım kuyruğu',
                          item: e,
                        );
                      },
                      backgroundColor: elevated,
                      side: BorderSide(color: border),
                    );
                  },
                ),
              );
            },
            loading: () => SizedBox(height: 36, child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppThemeExtension.of(context).accent))),
            error: (_, __) => Text('Kuyruk yüklenemedi.', style: TextStyle(color: AppThemeExtension.of(context).danger, fontSize: 12)),
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
          Icon(icon, size: 20, color: AppThemeExtension.of(context).accent),
          const SizedBox(width: DesignTokens.space2),
          Text(title, style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

