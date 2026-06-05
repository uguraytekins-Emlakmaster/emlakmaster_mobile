import 'package:emlakmaster_mobile/features/tasks/presentation/workspace/widgets/tasks_workspace_surface.dart';
import 'package:emlakmaster_mobile/widgets/premium/v2/premium_shell_chrome.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Görevlerim — danışman görev workspace (Screen 27). Consultant shell index 6
/// ('tasks'). Premium, dürüst, hızlı operasyonel görev çalışma alanı: gerçek
/// Firestore görevleri, kural tabanlı öncelik (geciken/bugün), müşteri bağlantısı.
/// CRUD, tekrar eden görev ve takip akışları korunur; uydurma verimlilik skoru yok.
class TasksPage extends ConsumerWidget {
  const TasksPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const PremiumShellBackdrop(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: TasksWorkspaceSurface(),
        ),
      ),
    );
  }
}
