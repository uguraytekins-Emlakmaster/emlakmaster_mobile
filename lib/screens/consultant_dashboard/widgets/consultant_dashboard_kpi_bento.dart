import 'package:emlakmaster_mobile/core/feedback/app_feedback.dart';
import 'package:emlakmaster_mobile/core/l10n/app_localizations.dart';
import 'package:emlakmaster_mobile/core/navigation/main_shell_shortcut_provider.dart';
import 'package:emlakmaster_mobile/core/router/app_router.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/core/theme/premium/premium_theme_extension.dart';
import 'package:emlakmaster_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:emlakmaster_mobile/screens/providers/consultant_dashboard_kpi_providers.dart';
import 'package:emlakmaster_mobile/widgets/premium/premium_ui_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// 2+1 bento KPI grid — vertical metric cards (executive layout).
class ConsultantDashboardKpiBento extends ConsumerWidget {
  const ConsultantDashboardKpiBento({super.key});

  static const double twoColBreakpoint = 340;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = ref.watch(
      currentUserProvider.select((v) => v.valueOrNull?.uid ?? ''),
    );

    void openCalls() {
      AppFeedback.lightImpact();
      context.push(AppRouter.routeConsultantCalls);
    }

    void openTasks() {
      AppFeedback.lightImpact();
      ref
          .read(mainShellShortcutProvider.notifier)
          .enqueue(MainShellShortcut.openTasksTab);
      context.go(AppRouter.routeHome);
    }

    void openPipeline() {
      AppFeedback.lightImpact();
      context.push(AppRouter.routePipeline);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final useTwoCol = constraints.maxWidth < twoColBreakpoint;
        if (useTwoCol) {
          return Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _CallsMetric(onTap: openCalls, emphasized: true),
                  ),
                  const SizedBox(width: DesignTokens.space2),
                  Expanded(
                    child: _TasksMetric(uid: uid, onTap: openTasks),
                  ),
                ],
              ),
              const SizedBox(height: DesignTokens.space2),
              _PipelineMetric(uid: uid, onTap: openPipeline),
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _CallsMetric(onTap: openCalls, emphasized: true)),
            const SizedBox(width: DesignTokens.space2),
            Expanded(child: _TasksMetric(uid: uid, onTap: openTasks)),
            const SizedBox(width: DesignTokens.space2),
            Expanded(child: _PipelineMetric(uid: uid, onTap: openPipeline)),
          ],
        );
      },
    );
  }
}

class _CallsMetric extends ConsumerWidget {
  const _CallsMetric({required this.onTap, this.emphasized = false});

  final VoidCallback onTap;
  final bool emphasized;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final calls =
        '${ref.watch(todayCallsCountProvider.select((a) => a.valueOrNull ?? 0))}';
    final l10n = AppLocalizations.of(context);
    return PremiumMetricCard(
      icon: Icons.phone_in_talk_rounded,
      label: l10n.t('today_calls'),
      value: calls,
      onTap: onTap,
      iconColor: emphasized
          ? PremiumThemeExtension.of(context).champagneGold
          : null,
    );
  }
}

class _TasksMetric extends ConsumerWidget {
  const _TasksMetric({required this.uid, required this.onTap});

  final String uid;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = uid.isEmpty
        ? '0'
        : '${ref.watch(advisorOpenTasksCountProvider(uid).select((a) => a.valueOrNull ?? 0))}';
    final l10n = AppLocalizations.of(context);
    return PremiumMetricCard(
      icon: Icons.task_alt_rounded,
      label: l10n.t('open_tasks'),
      value: tasks,
      onTap: onTap,
    );
  }
}

class _PipelineMetric extends ConsumerWidget {
  const _PipelineMetric({required this.uid, required this.onTap});

  final String uid;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pipeline = uid.isEmpty
        ? '0'
        : '${ref.watch(advisorPipelineCountProvider(uid).select((a) => a.valueOrNull ?? 0))}';
    final l10n = AppLocalizations.of(context);
    return PremiumMetricCard(
      icon: Icons.account_tree_rounded,
      label: l10n.t('active_pipeline'),
      value: pipeline,
      onTap: onTap,
    );
  }
}
