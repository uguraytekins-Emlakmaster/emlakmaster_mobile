import 'package:emlakmaster_mobile/core/router/app_router.dart';
import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/app_typography.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/core/widgets/pressable_scale_button.dart';
import 'package:emlakmaster_mobile/shared/widgets/empty_state.dart';
import 'package:emlakmaster_mobile/widgets/premium_bottom_sheet_shell.dart';
import 'package:emlakmaster_mobile/features/notifications/presentation/providers/user_notifications_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Üst bardaki bildirim ikonu: konu = bildirimler → kısa önizleme paneli (tam sayfa değil).
void showDashboardNotificationsSheet(BuildContext context, {required String uid}) {
  final rootContext = context;

  showPremiumDraggableBottomSheet<void>(
    context: context,
    initialChildSize: 0.45,
    maxChildSize: 0.85,
    builder: (ctx, scroll) {
      final ext = AppThemeExtension.of(ctx);
      final fg = ext.textPrimary;

      return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const PremiumBottomSheetHandle(),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  DesignTokens.space5,
                  DesignTokens.space2,
                  DesignTokens.space4,
                  DesignTokens.space3,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.notifications_outlined,
                      size: DesignTokens.iconLg,
                      color: ext.accent.withValues(alpha: 0.5),
                    ),
                    const SizedBox(width: DesignTokens.space3),
                    const Expanded(
                      child: PremiumSheetHeader(
                        compact: true,
                        title: 'Bildirimler',
                        subtitle: 'Son güncellemeler',
                      ),
                    ),
                    IconButton(
                      tooltip: 'Kapat',
                      style: IconButton.styleFrom(
                        foregroundColor: ext.textTertiary,
                      ),
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: uid.isEmpty
                    ? CustomScrollView(
                        controller: scroll,
                        slivers: const [
                          SliverFillRemaining(
                            hasScrollBody: false,
                            child: EmptyState(
                              icon: Icons.notifications_outlined,
                              title: 'Giriş gerekli',
                              subtitle:
                                  'Bildirimleri görmek için oturum açın. Özetler hesabınıza bağlıdır.',
                              compact: true,
                              grouped: true,
                            ),
                          ),
                        ],
                      )
                    : _DashboardNotificationsList(
                        uid: uid,
                        scrollController: scroll,
                        fg: fg,
                      ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  DesignTokens.space5,
                  DesignTokens.space2,
                  DesignTokens.space5,
                  MediaQuery.paddingOf(ctx).bottom + DesignTokens.space4,
                ),
                child: PressableScaleButton(
                  child: FilledButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      rootContext.push(AppRouter.routeNotifications);
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: ext.accent,
                      foregroundColor: ext.onBrand,
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(DesignTokens.radiusControl),
                      ),
                    ),
                    child: const Text('Bildirim merkezi'),
                  ),
                ),
              ),
            ],
          );
    },
  );
}

class _DashboardNotificationsList extends ConsumerWidget {
  const _DashboardNotificationsList({
    required this.uid,
    required this.scrollController,
    required this.fg,
  });

  final String uid;
  final ScrollController scrollController;
  final Color fg;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ext = AppThemeExtension.of(context);
    final notificationsAsync = ref.watch(userNotificationsDisplayProvider(uid));

    if (notificationsAsync.isLoading && !notificationsAsync.hasValue) {
      return CustomScrollView(
        controller: scrollController,
        slivers: [
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  color: ext.accent,
                  strokeWidth: 2,
                ),
              ),
            ),
          ),
        ],
      );
    }

    final docs = notificationsAsync.valueOrNull ?? [];
    if (docs.isEmpty) {
      return CustomScrollView(
        controller: scrollController,
        slivers: const [
          SliverFillRemaining(
            hasScrollBody: false,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: DesignTokens.space4),
              child: EmptyState(
                icon: Icons.notifications_none_rounded,
                title: 'Henüz bildirim yok',
                subtitle: 'Lead ve görev bildirimleri burada özetlenir.',
                compact: true,
                grouped: true,
              ),
            ),
          ),
        ],
      );
    }

    final take = docs.length > 8 ? 8 : docs.length;
    return ListView.separated(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(
        DesignTokens.space4,
        0,
        DesignTokens.space4,
        DesignTokens.space3,
      ),
      itemCount: take,
      separatorBuilder: (_, __) => Divider(
        height: 1,
        thickness: 1,
        color: ext.border.withValues(alpha: 0.35),
      ),
      itemBuilder: (_, i) {
        final d = docs[i].data();
        final title =
            d['title'] as String? ?? d['body'] as String? ?? 'Bildirim';
        final body = d['body'] as String? ?? '';
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(
            vertical: DesignTokens.space2,
            horizontal: DesignTokens.space2,
          ),
          minLeadingWidth: 40,
          leading: Icon(
            Icons.notifications_outlined,
            size: DesignTokens.iconMd,
            color: ext.textSecondary,
          ),
          title: Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.bodyStrong(context).copyWith(
              fontSize: DesignTokens.fontSizeBase,
              color: fg,
            ),
          ),
          subtitle: body.isNotEmpty
              ? Text(
                  body,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.body(context).copyWith(
                    fontSize: DesignTokens.fontSizeSm,
                    color: ext.textSecondary,
                  ),
                )
              : null,
        );
      },
    );
  }
}
