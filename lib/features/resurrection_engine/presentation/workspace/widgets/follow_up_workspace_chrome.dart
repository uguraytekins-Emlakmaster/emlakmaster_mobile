import 'package:emlakmaster_mobile/core/branding/brand_emblem.dart';
import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/features/resurrection_engine/presentation/consultant_follow_up_tokens.dart';
import 'package:emlakmaster_mobile/features/resurrection_engine/presentation/workspace/follow_up_workspace_types.dart';
import 'package:emlakmaster_mobile/screens/consultant_dashboard/widgets/consultant_dashboard_surface.dart';
import 'package:emlakmaster_mobile/widgets/premium/premium_ui_kit.dart';
import 'package:flutter/material.dart';
import 'package:emlakmaster_mobile/shared/widgets/dismissible_honesty_note.dart';

Color followUpToneColor(AppThemeExtension ext, FollowUpTone tone) {
  return switch (tone) {
    FollowUpTone.overdue => ext.danger,
    FollowUpTone.today => ext.warning,
    FollowUpTone.hot => ext.danger,
    FollowUpTone.cold => ext.info,
    FollowUpTone.partial => ext.textTertiary,
    FollowUpTone.matched => ext.success,
    FollowUpTone.neutral => ext.textTertiary,
  };
}

class FollowUpWorkspaceHeader extends StatelessWidget {
  const FollowUpWorkspaceHeader({
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
        ConsultantFollowUpTokens.horizontal,
        ConsultantFollowUpTokens.topInset + 4,
        ConsultantFollowUpTokens.horizontal,
        ConsultantFollowUpTokens.headerBottomGap,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PremiumHeaderNavBar(),
          Row(
            children: [
              const BrandEmblem(
                variant: BrandEmblemVariant.mini,
                size: ConsultantFollowUpTokens.headerEmblemSize,
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
                        fontSize: ConsultantFollowUpTokens.headerTitleSize,
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
                        fontSize: ConsultantFollowUpTokens.headerSubtitleSize,
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
            DismissibleHonestyNote(
              message: coverageNote!,
              prefsKey: 'honesty_note_follow_up_v1',
            ),
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

class FollowUpWorkspaceSummaryStrip extends StatelessWidget {
  const FollowUpWorkspaceSummaryStrip({super.key, required this.summary});

  final FollowUpWorkspaceSummary summary;

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
        ConsultantFollowUpTokens.horizontal,
        0,
        ConsultantFollowUpTokens.horizontal,
        ConsultantFollowUpTokens.sectionGap,
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

class FollowUpWorkspaceSearchRow extends StatelessWidget {
  const FollowUpWorkspaceSearchRow({
    super.key,
    required this.controller,
    required this.focusNode,
    this.hintText = 'İsim, telefon veya not ara…',
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String hintText;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        ConsultantFollowUpTokens.horizontal,
        ConsultantFollowUpTokens.chromeGap,
        ConsultantFollowUpTokens.horizontal,
        ConsultantFollowUpTokens.chromeGap,
      ),
      child: ConsultantDashboardExecutiveSurface(
        ambientStrength: 0.72,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        child: SizedBox(
          height: ConsultantFollowUpTokens.searchBarHeight,
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

class FollowUpWorkspaceFilterStrip extends StatelessWidget {
  const FollowUpWorkspaceFilterStrip({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final FollowUpWorkspaceFilter selected;
  final ValueChanged<FollowUpWorkspaceFilter> onSelected;

  static const _filters = FollowUpWorkspaceFilter.values;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    return SizedBox(
      height: ConsultantFollowUpTokens.filterStripHeight + 8,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: ConsultantFollowUpTokens.horizontal,
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

class FollowUpWorkspaceSectionHeader extends StatelessWidget {
  const FollowUpWorkspaceSectionHeader({
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
        ConsultantFollowUpTokens.horizontal,
        4,
        ConsultantFollowUpTokens.horizontal,
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

class FollowUpWorkspaceInlineNote extends StatelessWidget {
  const FollowUpWorkspaceInlineNote({
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
        ConsultantFollowUpTokens.horizontal,
        16,
        ConsultantFollowUpTokens.horizontal,
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
