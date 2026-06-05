import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/features/admin_islem_kayitlari/presentation/admin_islem_kayitlari_tokens.dart';
import 'package:emlakmaster_mobile/features/admin_islem_kayitlari/presentation/utils/islem_kayitlari_types.dart';
import 'package:flutter/material.dart';

class IslemKayitlariRow extends StatelessWidget {
  const IslemKayitlariRow({
    super.key,
    required this.viewModel,
    required this.onTap,
    required this.onDetail,
    this.onConsultant,
    this.onTeam,
    this.onReports,
    this.onApplyFilter,
  });

  final IslemKayitlariRowViewModel viewModel;
  final VoidCallback onTap;
  final VoidCallback onDetail;
  final VoidCallback? onConsultant;
  final VoidCallback? onTeam;
  final VoidCallback? onReports;
  final VoidCallback? onApplyFilter;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    final emphasize = viewModel.severity == IslemKayitlariSeverity.critical ||
        viewModel.severity == IslemKayitlariSeverity.warning;

    return RepaintBoundary(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            margin: const EdgeInsets.fromLTRB(
              AdminIslemKayitlariTokens.horizontal,
              0,
              AdminIslemKayitlariTokens.horizontal,
              AdminIslemKayitlariTokens.moduleGap,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            constraints: const BoxConstraints(
              minHeight: AdminIslemKayitlariTokens.rowMinHeight,
            ),
            decoration: BoxDecoration(
              color: emphasize
                  ? (viewModel.severity == IslemKayitlariSeverity.critical
                      ? ext.danger.withValues(alpha: 0.07)
                      : ext.warning.withValues(alpha: 0.07))
                  : ext.surfaceElevated.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: emphasize
                    ? (viewModel.severity == IslemKayitlariSeverity.critical
                        ? ext.danger.withValues(alpha: 0.28)
                        : ext.warning.withValues(alpha: 0.28))
                    : ext.border.withValues(alpha: 0.32),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SeverityIcon(severity: viewModel.severity),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              viewModel.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: ext.textPrimary,
                                fontSize: AdminIslemKayitlariTokens.rowTitleSize,
                                fontWeight: FontWeight.w700,
                                height: 1.1,
                              ),
                            ),
                          ),
                          _StatusChip(
                            label: viewModel.categoryLabel,
                            color: ext.accent,
                          ),
                          if (viewModel.hasPartialMetadata)
                            Padding(
                              padding: const EdgeInsets.only(left: 4),
                              child: _StatusChip(
                                label: 'Kısmi',
                                color: ext.textTertiary,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${viewModel.actorLine} · ${viewModel.timestampLabel}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: ext.textSecondary.withValues(alpha: 0.92),
                          fontSize: AdminIslemKayitlariTokens.rowMetaSize,
                          height: 1.15,
                        ),
                      ),
                      if (viewModel.targetLine.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          viewModel.targetLine,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: ext.textTertiary,
                            fontSize: AdminIslemKayitlariTokens.rowChipSize,
                            height: 1.1,
                          ),
                        ),
                      ],
                      if (viewModel.detailLine.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          viewModel.detailLine,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: ext.textTertiary,
                            fontSize: AdminIslemKayitlariTokens.rowChipSize,
                            height: 1.1,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_horiz_rounded,
                    color: ext.textSecondary,
                    size: 20,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                  onSelected: (value) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      switch (value) {
                        case 'open':
                          onTap();
                        case 'detail':
                          onDetail();
                        case 'consultant':
                          onConsultant?.call();
                        case 'team':
                          onTeam?.call();
                        case 'reports':
                          onReports?.call();
                        case 'filter':
                          onApplyFilter?.call();
                      }
                    });
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'open', child: Text('Aç')),
                    const PopupMenuItem(value: 'detail', child: Text('Detay')),
                    if (onConsultant != null)
                      const PopupMenuItem(
                        value: 'consultant',
                        child: Text('İlgili danışmana git'),
                      ),
                    if (onTeam != null)
                      const PopupMenuItem(
                        value: 'team',
                        child: Text('Takıma git'),
                      ),
                    if (onReports != null)
                      const PopupMenuItem(
                        value: 'reports',
                        child: Text('Raporlar'),
                      ),
                    if (onApplyFilter != null)
                      const PopupMenuItem(
                        value: 'filter',
                        child: Text('Filtreyi uygula'),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SeverityIcon extends StatelessWidget {
  const _SeverityIcon({required this.severity});

  final IslemKayitlariSeverity severity;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    final (icon, color) = switch (severity) {
      IslemKayitlariSeverity.critical => (
          Icons.priority_high_rounded,
          ext.danger,
        ),
      IslemKayitlariSeverity.warning => (
          Icons.warning_amber_rounded,
          ext.warning,
        ),
      IslemKayitlariSeverity.info => (
          Icons.history_rounded,
          ext.accent,
        ),
    };

    return Container(
      width: AdminIslemKayitlariTokens.rowIconSize,
      height: AdminIslemKayitlariTokens.rowIconSize,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: color, size: 18),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: AdminIslemKayitlariTokens.rowChipSize,
          fontWeight: FontWeight.w700,
          height: 1,
        ),
      ),
    );
  }
}
