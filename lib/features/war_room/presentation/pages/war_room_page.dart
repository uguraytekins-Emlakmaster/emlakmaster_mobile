import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/app_typography.dart';
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
import 'package:emlakmaster_mobile/core/feedback/app_feedback.dart';

/// Role-Based War Room: aktif çağrılar, sıcak fırsatlar, gecikmiş görevler, yüksek değerli lead'ler, danışman durumu.
class WarRoomPage extends ConsumerWidget {
  const WarRoomPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roleAsync = ref.watch(displayRoleProvider);
    final ext = AppThemeExtension.of(context);
    return roleAsync.when(
      loading: () => Scaffold(
        backgroundColor: ext.background,
        body: Center(child: CircularProgressIndicator(color: ext.accent)),
      ),
      error: (_, __) => const UnauthorizedScreen(
        message: 'Yetki bilgisi alınamadı.',
      ),
      data: (role) {
        if (!FeaturePermission.canViewWarRoom(role)) {
          return const UnauthorizedScreen(
            message: 'Bu alan yalnızca yönetim ve operasyon ekipleri içindir.',
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
    final bg = AppThemeExtension.of(context).background;
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
    final ext = AppThemeExtension.of(context);
    final surface = ext.surface;
    final border = ext.border;
    final resurrectionAsync = ref.watch(resurrectionQueueProvider);
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.space4, vertical: DesignTokens.space2),
      decoration: BoxDecoration(
        color: surface,
        border: Border(top: BorderSide(color: border.withValues(alpha: 0.45))),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(
            title: 'Geri kazanım sırası',
            icon: Icons.replay_rounded,
          ),
          const SizedBox(height: 8),
          resurrectionAsync.when(
            data: (items) {
              final elevated = ext.surfaceElevated;
              if (items.isEmpty) {
                return Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: DesignTokens.space2),
                  child: Text(
                    'Şu an öne çekilecek sessiz müşteri görünmüyor.',
                    style: AppTypography.body(context).copyWith(
                      fontSize: DesignTokens.fontSizeXs,
                    ),
                  ),
                );
              }
              return SizedBox(
                height: 44,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: items.take(10).length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(width: DesignTokens.space2),
                  itemBuilder: (context, i) {
                    final e = items[i];
                    return ActionChip(
                      avatar: Icon(
                        Icons.person_outline_rounded,
                        size: DesignTokens.iconSm,
                        color: ext.accent,
                      ),
                      label: Text(
                        '${e.customerName ?? e.customerId} · ${e.daysSilent ?? 0}g',
                        style: TextStyle(
                          fontSize: DesignTokens.fontSizeXs,
                          color: ext.textPrimary,
                        ),
                      ),
                      onPressed: () {
                        AppFeedback.lightImpact();
                        showResurrectionLeadTopicSheet(
                          context,
                          topicTitle: 'Geri kazanım sırası',
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
            loading: () => SizedBox(
              height: 36,
              child: Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: ext.accent,
                ),
              ),
            ),
            error: (_, __) => Text(
              'Sıra yüklenemedi',
              style: AppTypography.body(context).copyWith(
                color: ext.danger,
                fontSize: DesignTokens.fontSizeXs,
              ),
            ),
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
    final ext = AppThemeExtension.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: DesignTokens.space2),
      child: Row(
        children: [
          Icon(icon,
              size: DesignTokens.iconMd,
              color: ext.accent.withValues(alpha: 0.85)),
          const SizedBox(width: DesignTokens.space2),
          Text(
            title,
            style: AppTypography.metricLabel(context).copyWith(
              color: ext.textPrimary,
              fontSize: DesignTokens.fontSizeSm,
            ),
          ),
        ],
      ),
    );
  }
}
