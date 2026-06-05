import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/features/admin_raporlar/presentation/admin_raporlar_tokens.dart';
import 'package:emlakmaster_mobile/features/admin_raporlar/presentation/utils/raporlar_types.dart';
import 'package:flutter/material.dart';

class RaporlarRow extends StatelessWidget {
  const RaporlarRow({
    super.key,
    required this.entry,
    required this.onTap,
    required this.onDetail,
  });

  final RaporEntryViewModel entry;
  final VoidCallback onTap;
  final VoidCallback onDetail;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    final tone = _toneColor(ext, entry.tone);
    final emphasize = entry.needsAction;

    return RepaintBoundary(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            margin: const EdgeInsets.fromLTRB(
              AdminRaporlarTokens.horizontal,
              0,
              AdminRaporlarTokens.horizontal,
              AdminRaporlarTokens.moduleGap,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            constraints: const BoxConstraints(
              minHeight: AdminRaporlarTokens.rowMinHeight,
            ),
            decoration: BoxDecoration(
              color: emphasize
                  ? tone.withValues(alpha: 0.07)
                  : ext.surfaceElevated.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: emphasize
                    ? tone.withValues(alpha: 0.28)
                    : ext.border.withValues(alpha: 0.32),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _KategoriIcon(entry: entry, tone: tone),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Text(
                              entry.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: ext.textPrimary,
                                fontSize: AdminRaporlarTokens.rowTitleSize,
                                fontWeight: FontWeight.w700,
                                height: 1.1,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            flex: 2,
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: _StatusChip(
                                label: entry.readinessLabel,
                                color: tone,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        entry.scope,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: ext.textSecondary.withValues(alpha: 0.92),
                          fontSize: AdminRaporlarTokens.rowMetaSize,
                          fontWeight: FontWeight.w600,
                          height: 1.15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        entry.description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: ext.textTertiary,
                          fontSize: AdminRaporlarTokens.rowChipSize,
                          height: 1.15,
                        ),
                      ),
                      if (entry.attentionLabel != null) ...[
                        const SizedBox(height: 5),
                        _AttentionPill(label: entry.attentionLabel!, tone: tone),
                      ],
                    ],
                  ),
                ),
                _menu(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _menu(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    return PopupMenuButton<String>(
      icon: Icon(Icons.more_horiz_rounded, color: ext.textSecondary, size: 20),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
      onSelected: (value) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          switch (value) {
            case 'open':
              onTap();
            case 'detail':
              onDetail();
          }
        });
      },
      itemBuilder: (context) => const [
        PopupMenuItem(value: 'open', child: Text('Aç')),
        PopupMenuItem(value: 'detail', child: Text('Detay')),
      ],
    );
  }
}

Color _toneColor(AppThemeExtension ext, RaporTone tone) {
  return switch (tone) {
    RaporTone.info => ext.info,
    RaporTone.success => ext.success,
    RaporTone.warning => ext.warning,
    RaporTone.danger => ext.danger,
    RaporTone.neutral => ext.textTertiary,
  };
}

IconData _iconFor(RaporEntryViewModel entry) {
  if (entry.id == 'komuta_odasi') return Icons.military_tech_rounded;
  if (entry.id == 'komuta_merkezi') return Icons.phone_callback_rounded;
  return switch (entry.kategori) {
    RaporKategori.kadro => Icons.groups_rounded,
    RaporKategori.ekip => Icons.group_work_rounded,
    RaporKategori.audit => Icons.history_rounded,
    RaporKategori.uyelik => Icons.badge_outlined,
    RaporKategori.ofis => Icons.apartment_outlined,
    RaporKategori.baglanti => Icons.hub_outlined,
    RaporKategori.komuta => Icons.dashboard_rounded,
  };
}

class _KategoriIcon extends StatelessWidget {
  const _KategoriIcon({required this.entry, required this.tone});

  final RaporEntryViewModel entry;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: AdminRaporlarTokens.rowIconSize,
      height: AdminRaporlarTokens.rowIconSize,
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(_iconFor(entry), color: tone, size: 18),
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
        maxLines: 1,
        softWrap: false,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: color,
          fontSize: AdminRaporlarTokens.rowChipSize,
          fontWeight: FontWeight.w700,
          height: 1,
        ),
      ),
    );
  }
}

class _AttentionPill extends StatelessWidget {
  const _AttentionPill({required this.label, required this.tone});

  final String label;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: tone.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.priority_high_rounded, color: tone, size: 11),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              color: tone,
              fontSize: AdminRaporlarTokens.rowChipSize,
              fontWeight: FontWeight.w700,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}
