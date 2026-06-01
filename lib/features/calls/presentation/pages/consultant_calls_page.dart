import 'package:emlakmaster_mobile/features/calls/presentation/workspace/widgets/calls_workspace_surface.dart';
import 'package:emlakmaster_mobile/widgets/premium/v2/premium_shell_chrome.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Çağrılarım — danışman çağrı workspace (Screen 26). Consultant shell index 2
/// ('calls'). Premium, dürüst, hızlı operasyonel çağrı çalışma alanı: gerçek
/// CRM kayıtları, gerçek müşteri eşleşmesi, grounded filtreler ve dikkat-önce
/// sıralama. Veri katmanı, detay rotası, outbound çağrı/mesaj ve görev/takip
/// akışları korunur; uydurma KPI veya AI skoru gösterilmez.
class ConsultantCallsPage extends ConsumerWidget {
  const ConsultantCallsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const PremiumShellBackdrop(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: CallsWorkspaceSurface(),
        ),
      ),
    );
  }
}
