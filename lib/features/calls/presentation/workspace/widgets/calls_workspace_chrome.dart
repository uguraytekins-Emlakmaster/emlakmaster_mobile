import 'package:emlakmaster_mobile/core/branding/brand_emblem.dart';
import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/consultant_calls_tokens.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/workspace/calls_workspace_types.dart';
import 'package:flutter/material.dart';

Color callToneColor(AppThemeExtension ext, CallTone tone) {
  return switch (tone) {
    CallTone.attention => ext.warning,
    CallTone.callback => ext.warning,
    CallTone.missed => ext.danger,
    CallTone.matched => ext.success,
    CallTone.partial => ext.textTertiary,
    CallTone.local => ext.info,
    CallTone.neutral => ext.textTertiary,
  };
}

/// Executive çağrı başlığı.
class CallsWorkspaceHeader extends StatelessWidget {
  const CallsWorkspaceHeader({
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
        ConsultantCallsTokens.horizontal,
        ConsultantCallsTokens.topInset + 4,
        ConsultantCallsTokens.horizontal,
        ConsultantCallsTokens.headerBottomGap,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              BrandEmblem(
                variant: BrandEmblemVariant.mini,
                size: ConsultantCallsTokens.headerEmblemSize,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: ext.textPrimary,
                        fontSize: ConsultantCallsTokens.headerTitleSize,
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
                        fontSize: ConsultantCallsTokens.headerSubtitleSize,
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

/// Çağrı özet şeridi — yalnızca gerçek sayımlar.
class CallsWorkspaceSummaryStrip extends StatelessWidget {
  const CallsWorkspaceSummaryStrip({super.key, required this.summary});

  final CallsWorkspaceSummary summary;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    final cells = <(String, String, Color)>[
      ('${summary.today}', 'Bugün', ext.accent),
      ('${summary.callback}', 'Geri dön', ext.warning),
      ('${summary.matched}', 'Eşleşen', ext.success),
      ('${summary.partial}', 'Kısmi', ext.textTertiary),
      if (summary.unanswered > 0)
        ('${summary.unanswered}', 'Cevapsız', ext.danger),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        ConsultantCallsTokens.horizontal,
        0,
        ConsultantCallsTokens.horizontal,
        ConsultantCallsTokens.sectionGap,
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
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
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
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}

/// Yatay filtre şeridi.
class CallsWorkspaceFilterStrip extends StatelessWidget {
  const CallsWorkspaceFilterStrip({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final CallsWorkspaceFilter selected;
  final ValueChanged<CallsWorkspaceFilter> onSelected;

  static const _filters = CallsWorkspaceFilter.values;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    return SizedBox(
      height: ConsultantCallsTokens.quickFilterHeight + 4,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: ConsultantCallsTokens.horizontal,
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

class CallsWorkspaceSectionHeader extends StatelessWidget {
  const CallsWorkspaceSectionHeader({
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
        ConsultantCallsTokens.horizontal,
        4,
        ConsultantCallsTokens.horizontal,
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
              letterSpacing: 0.2,
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

class CallsWorkspaceInlineNote extends StatelessWidget {
  const CallsWorkspaceInlineNote({
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
        ConsultantCallsTokens.horizontal,
        16,
        ConsultantCallsTokens.horizontal,
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
