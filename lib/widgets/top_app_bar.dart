import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/dashboard_layout_tokens.dart';
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
    final uid = ref.watch(currentUserProvider.select((a) => a.valueOrNull?.uid ?? ''));
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            DashboardLayoutTokens.horizontalPadding,
            DashboardLayoutTokens.pageTopInset,
            DashboardLayoutTokens.horizontalPadding,
            8,
          ),
          child: Row(
            children: [
              const SessionAvatarButton(),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Rainbow Gayrimenkul',
                      style: TextStyle(
                        color: ext.textPrimary,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'EmlakMaster Agent Assistant',
                      style: TextStyle(color: ext.textTertiary, fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: 'Bildirimler',
                icon: Icon(Icons.notifications_none_rounded, color: ext.textPrimary),
                onPressed: () => showDashboardNotificationsSheet(context, uid: uid),
              ),
            ],
          ),
        ),
        const RevenueLeakTracker(),
      ],
    );
  }
}
