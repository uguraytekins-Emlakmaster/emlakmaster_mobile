import 'package:emlakmaster_mobile/core/branding/brand_emblem.dart';
import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/features/tasks/presentation/consultant_tasks_tokens.dart';
import 'package:emlakmaster_mobile/features/tasks/presentation/workspace/tasks_workspace_types.dart';
import 'package:emlakmaster_mobile/screens/consultant_dashboard/widgets/consultant_dashboard_surface.dart';
import 'package:emlakmaster_mobile/widgets/premium/premium_ui_kit.dart';
import 'package:flutter/material.dart';

Color taskToneColor(AppThemeExtension ext, TaskTone tone) {
  return switch (tone) {
    TaskTone.overdue => ext.danger,
    TaskTone.today => ext.warning,
    TaskTone.upcoming => ext.info,
    TaskTone.completed => ext.textTertiary,
    TaskTone.partial => ext.textTertiary,
    TaskTone.matched => ext.success,
    TaskTone.neutral => ext.textTertiary,
  };
}

class TasksWorkspaceHeader extends StatelessWidget {
  const TasksWorkspaceHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.dateChipLabel,
    this.coverageNote,
    this.actions = const [],
  });

  final String title;
  final String subtitle;
  final String? dateChipLabel;
  final String? coverageNote;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        ConsultantTasksTokens.horizontal,
        ConsultantTasksTokens.topInset + 4,
        ConsultantTasksTokens.horizontal,
        ConsultantTasksTokens.headerBottomGap,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const BrandEmblem(
                variant: BrandEmblemVariant.mini,
                size: ConsultantTasksTokens.headerEmblemSize,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: ext.textPrimary,
                        fontSize: ConsultantTasksTokens.headerTitleSize,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                        height: 1.05,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: ext.textSecondary.withValues(alpha: 0.88),
                        fontSize: ConsultantTasksTokens.headerSubtitleSize,
                        fontWeight: FontWeight.w500,
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
              if (dateChipLabel != null && dateChipLabel!.isNotEmpty) ...[
                const SizedBox(width: 6),
                _DateChip(label: dateChipLabel!),
              ],
              ...actions,
            ],
          ),
          if (coverageNote != null && coverageNote!.isNotEmpty) ...[
            const SizedBox(height: 8),
            _HonestyNote(message: coverageNote!),
          ],
        ],
      ),
    );
  }
}

class _DateChip extends StatelessWidget {
  const _DateChip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: ext.accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: ext.accent.withValues(alpha: 0.28)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: ext.accent,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _HonestyNote extends StatelessWidget {
  const _HonestyNote({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
      decoration: BoxDecoration(
        color: ext.surface.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ext.border.withValues(alpha: 0.28)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.shield_outlined, size: 14, color: ext.textTertiary),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: ext.textSecondary,
                fontSize: 10.5,
                height: 1.3,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class TasksWorkspaceSummaryStrip extends StatelessWidget {
  const TasksWorkspaceSummaryStrip({super.key, required this.summary});

  final TasksWorkspaceSummary summary;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    final cells = <(String, String, Color)>[
      ('${summary.active}', 'Aktif', ext.accent),
      ('${summary.overdue}', 'Geciken', ext.danger),
      ('${summary.today}', 'Bugün', ext.warning),
      ('${summary.matched}', 'Müşteri', ext.success),
      if (summary.partial > 0)
        ('${summary.partial}', 'Kısmi', ext.textTertiary),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        ConsultantTasksTokens.horizontal,
        0,
        ConsultantTasksTokens.horizontal,
        ConsultantTasksTokens.sectionGap,
      ),
      child: Row(
        children: [
          for (var i = 0; i < cells.length; i++) ...[
            if (i > 0) const SizedBox(width: 6),
            Expanded(
              child: _SummaryCell(
                value: cells[i].$1,
                label: cells[i].$2,
                color: cells[i].$3,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SummaryCell extends StatelessWidget {
  const _SummaryCell({
    required this.value,
    required this.label,
    required this.color,
  });

  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      decoration: BoxDecoration(
        color: ext.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ext.border.withValues(alpha: 0.28)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 15,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: ext.textSecondary,
              fontSize: 9.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class TasksWorkspaceSearchRow extends StatelessWidget {
  const TasksWorkspaceSearchRow({
    super.key,
    required this.controller,
    required this.focusNode,
    this.hintText = 'Görev başlığı veya müşteri ara…',
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String hintText;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        ConsultantTasksTokens.horizontal,
        ConsultantTasksTokens.chromeGap,
        ConsultantTasksTokens.horizontal,
        ConsultantTasksTokens.chromeGap,
      ),
      child: ConsultantDashboardExecutiveSurface(
        ambientStrength: 0.72,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        child: SizedBox(
          height: ConsultantTasksTokens.searchBarHeight,
          child: PremiumSearchBar(
            controller: controller,
            focusNode: focusNode,
            hintText: hintText,
            compact: true,
          ),
        ),
      ),
    );
  }
}

class TasksWorkspaceFilterStrip extends StatelessWidget {
  const TasksWorkspaceFilterStrip({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final TasksWorkspaceFilter selected;
  final ValueChanged<TasksWorkspaceFilter> onSelected;

  static const _filters = TasksWorkspaceFilter.values;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    return SizedBox(
      height: ConsultantTasksTokens.filterStripHeight + 8,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: ConsultantTasksTokens.horizontal,
        ),
        itemCount: _filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (context, index) {
          final f = _filters[index];
          final isSelected = f == selected;
          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => onSelected(f),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: isSelected
                      ? ext.accent.withValues(alpha: 0.18)
                      : ext.surface.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? ext.accent.withValues(alpha: 0.45)
                        : ext.border.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  f.label,
                  style: TextStyle(
                    color: isSelected ? ext.accent : ext.textSecondary,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class TasksWorkspaceSectionHeader extends StatelessWidget {
  const TasksWorkspaceSectionHeader({
    super.key,
    required this.label,
    this.secondary,
  });

  final String label;
  final String? secondary;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        ConsultantTasksTokens.horizontal,
        4,
        ConsultantTasksTokens.horizontal,
        6,
      ),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              color: ext.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (secondary != null) ...[
            const Spacer(),
            Text(
              secondary!,
              style: TextStyle(
                color: ext.textTertiary,
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class TasksWorkspaceInlineNote extends StatelessWidget {
  const TasksWorkspaceInlineNote({
    super.key,
    required this.icon,
    required this.message,
  });

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        ConsultantTasksTokens.horizontal,
        16,
        ConsultantTasksTokens.horizontal,
        8,
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: ext.textTertiary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: ext.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
