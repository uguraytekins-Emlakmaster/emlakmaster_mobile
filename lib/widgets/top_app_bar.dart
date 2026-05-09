import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/app_typography.dart';
import 'package:emlakmaster_mobile/core/theme/dashboard_layout_tokens.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:emlakmaster_mobile/widgets/dashboard_notifications_sheet.dart';
import 'package:emlakmaster_mobile/widgets/revenue_leak_tracker.dart';
import 'package:emlakmaster_mobile/widgets/session_avatar_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DashboardTopAppBar extends ConsumerWidget {
  const DashboardTopAppBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ext = AppThemeExtension.of(context);
    final uid =
        ref.watch(currentUserProvider.select((a) => a.valueOrNull?.uid ?? ''));
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            DashboardLayoutTokens.horizontalPadding,
            DashboardLayoutTokens.pageTopInset,
            DashboardLayoutTokens.horizontalPadding,
            DesignTokens.space4,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 2),
                child: SessionAvatarButton(size: 44),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Rainbow Gayrimenkul',
                      style: AppTypography.pageHeading(context).copyWith(
                        fontSize: DesignTokens.fontSizeXl,
                        height: 1.12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: DesignTokens.space2),
                    Text(
                      'Yönetici komuta ekranı · ofis, risk ve performans tek bakışta',
                      style: AppTypography.meta(context).copyWith(
                        color: ext.textTertiary,
                        height: 1.35,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Bildirimler',
                constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                icon: Icon(Icons.notifications_outlined,
                    color: ext.textSecondary, size: 24),
                onPressed: () =>
                    showDashboardNotificationsSheet(context, uid: uid),
              ),
            ],
          ),
        ),
        const RevenueLeakTracker(),
      ],
    );
  }
}
