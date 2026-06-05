import 'package:emlakmaster_mobile/features/crm_customers/presentation/workspace/widgets/customer_workspace_surface.dart';
import 'package:emlakmaster_mobile/widgets/premium/v2/premium_shell_chrome.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Müşterilerim — danışman CRM workspace (Screen 25). Consultant shell index 3
/// ('customers'). Premium, dürüst, hızlı operasyonel müşteri çalışma alanı:
/// gerçek müşteri kayıtları, kural tabanlı (LLM değil) sıcaklık, gerçek son
/// temas ve dikkat-önce sıralama. Veri katmanı, detay rotası, çağrı/mesaj ve
/// görev/takip akışları korunur; uydurma CRM skoru/eşleşmesi gösterilmez.
class CustomerListPage extends ConsumerWidget {
  const CustomerListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const PremiumShellBackdrop(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: CustomerWorkspaceSurface(),
        ),
      ),
    );
  }
}
