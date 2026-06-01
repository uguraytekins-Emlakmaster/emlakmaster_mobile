import 'package:emlakmaster_mobile/core/performance/shell_screen_ready_tracker.dart';
import 'package:emlakmaster_mobile/features/crm_customers/presentation/detail_workspace/customer_detail_workspace_types.dart';
import 'package:emlakmaster_mobile/features/crm_customers/presentation/detail_workspace/providers/customer_detail_workspace_provider.dart';
import 'package:emlakmaster_mobile/features/crm_customers/presentation/detail_workspace/widgets/customer_detail_workspace_surface.dart';
import 'package:emlakmaster_mobile/widgets/premium/v2/premium_shell_chrome.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Müşteri detay — danışman CRM workspace (Screen 30). Route: `/customer/:id`.
/// Premium, dürüst, hızlı tek müşteri operasyon yüzeyi; uydurma CRM skoru yok.
class CustomerDetailPage extends ConsumerWidget {
  const CustomerDetailPage({super.key, required this.customerId});

  final String customerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PremiumShellBackdrop(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: ShellScreenReadyListener(
          screenName: 'customer_detail',
          provider: customerDetailWorkspaceSnapshotProvider(customerId),
          itemCount: (v) =>
              (v as CustomerDetailWorkspaceSnapshot).sections.length,
          child: SafeArea(
            child: CustomerDetailWorkspaceSurface(customerId: customerId),
          ),
        ),
      ),
    );
  }
}
