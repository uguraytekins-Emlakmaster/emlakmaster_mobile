import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:emlakmaster_mobile/widgets/dashboard_notifications_sheet.dart';
import 'package:emlakmaster_mobile/widgets/revenue_leak_tracker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DashboardTopAppBar extends ConsumerWidget {
  const DashboardTopAppBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = ref.watch(currentUserProvider.select((a) => a.valueOrNull?.uid ?? ''));
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              const CircleAvatar(
                radius: 18,
                backgroundColor: DesignTokens.surfaceDark,
                child: Icon(Icons.apartment_rounded, color: DesignTokens.antiqueGold),
              ),
              const SizedBox(width: 10),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Rainbow Gayrimenkul',
                    style: TextStyle(
                      color: DesignTokens.textPrimaryDark,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                  ),
                  Text(
                    'EmlakMaster Agent Assistant',
                    style: TextStyle(color: DesignTokens.textTertiaryDark, fontSize: 12),
                  ),
                ],
              ),
              const Spacer(),
              IconButton(
                tooltip: 'Bildirimler',
                icon: const Icon(Icons.notifications_none_rounded, color: DesignTokens.textPrimaryDark),
                onPressed: () => showDashboardNotificationsSheet(context, uid: uid),
              ),
              const SizedBox(width: 4),
              const CircleAvatar(
                radius: 16,
                backgroundColor: DesignTokens.surfaceDark,
              ),
            ],
          ),
        ),
        const RevenueLeakTracker(),
      ],
    );
  }
}
