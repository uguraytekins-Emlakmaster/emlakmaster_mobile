import 'package:emlakmaster_mobile/core/branding/brand_emblem.dart';
import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/app_typography.dart';
import 'package:emlakmaster_mobile/features/admin_baglantilar/presentation/admin_baglantilar_tokens.dart';
import 'package:emlakmaster_mobile/features/admin_baglantilar/presentation/utils/baglantilar_types.dart';
import 'package:emlakmaster_mobile/features/dashboard/presentation/admin_command/admin_command_tokens.dart';
import 'package:emlakmaster_mobile/features/dashboard/presentation/admin_command/widgets/admin_command_chrome.dart';
import 'package:emlakmaster_mobile/screens/consultant_dashboard/widgets/consultant_dashboard_surface.dart';
import 'package:emlakmaster_mobile/widgets/premium/premium_navigation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

String turkishBaglantiSectionUpper(String label) {
  const map = {
    'i': 'İ',
    'ı': 'I',
    'ş': 'Ş',
    'ğ': 'Ğ',
    'ü': 'Ü',
    'ö': 'Ö',
    'ç': 'Ç',
  };
  return label
      .split(' ')
      .map((w) {
        if (w.isEmpty) return w;
        final first = w[0];
        final upper = map[first] ?? first.toUpperCase();
        return '$upper${w.substring(1)}';
      })
      .join(' ')
      .toUpperCase();
}

class PremiumBaglantilarHeader extends StatelessWidget {
  const PremiumBaglantilarHeader({
    super.key,
    this.actions = const [],
    this.coverageNote = '',
  });

  final List<Widget> actions;
  final String coverageNote;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    final today = DateFormat('d MMM').format(DateTime.now());
    final m = AdminCommandTokens.headerMetrics(context);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        m.horizontal,
        m.topInset,
        m.horizontal,
        m.bottomGap,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 2),
                child: PremiumNavLeading(),
              ),
              SizedBox(width: m.titleGap - 4),
              _BaglantiHeaderEmblem(size: m.emblemSize, pad: m.emblemPad),
              SizedBox(width: m.titleGap),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(top: m.emblemPad * 0.15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bağlantılar',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.pageHeading(context).copyWith(
                          fontSize: m.titleSize,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.35,
                          height: 1.04,
                        ),
                      ),
                      SizedBox(height: m.titleToSubtitleGap),
                      Text(
                        'Platform durumu ve ofis entegrasyon kontrolü',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.meta(context).copyWith(
                          color: ext.textSecondary.withValues(alpha: 0.92),
                          fontSize: m.subtitleSize,
                          fontWeight: FontWeight.w600,
                          height: 1.18,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                    decoration: BoxDecoration(
                      color: ext.surfaceElevated.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(12),
                      border:
                          Border.all(color: ext.border.withValues(alpha: 0.38)),
                    ),
                    child: Text(
                      today,
                      style: TextStyle(
                        color: ext.textSecondary,
                        fontSize: m.dateFontSize,
                        fontWeight: FontWeight.w800,
                        height: 1,
                      ),
                    ),
                  ),
                  if (actions.isNotEmpty) ...[
                    SizedBox(height: m.controlRailGap),
                    Row(mainAxisSize: MainAxisSize.min, children: actions),
                  ],
                ],
              ),
            ],
          ),
          SizedBox(height: m.honestyTopGap),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
              color: ext.info.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: ext.info.withValues(alpha: 0.36)),
            ),
            child: Text(
              coverageNote.isNotEmpty
                  ? coverageNote
                  : 'Yalnızca gerçek platform kurulum kayıtlarından türetilen durumlar gösterilir.',
              style: TextStyle(
                color: ext.textSecondary.withValues(alpha: 0.94),
                fontSize: AdminCommandTokens.honestyNoteSize,
                fontWeight: FontWeight.w700,
                height: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BaglantiHeaderEmblem extends StatelessWidget {
  const _BaglantiHeaderEmblem({required this.size, required this.pad});

  final double size;
  final double pad;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    return Container(
      padding: EdgeInsets.all(pad),
      decoration: BoxDecoration(
        color: ext.surfaceElevated.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ext.accent.withValues(alpha: 0.22)),
      ),
      child: BrandEmblem(variant: BrandEmblemVariant.mini, size: size),
    );
  }
}

class BaglantilarSummaryStripView extends StatelessWidget {
  const BaglantilarSummaryStripView({super.key, required this.summary});

  final BaglantilarSummary summary;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    final typography = AdminCommandTokens.stripTypography(context);
    // Önceliğe göre sıralı aday metrikler; dar ekranlarda yoğunluğu korumak
    // için en fazla 5 hücre gösterilir (Screen 12–17 ritmi).
    final candidates = <(String, String, Color)>[
      if (summary.intervention > 0)
        (summary.intervention.toString(), 'Müdahale', ext.danger),
      if (summary.connected > 0)
        (summary.connected.toString(), 'Bağlı', ext.success),
      if (summary.ready > 0)
        (summary.ready.toString(), 'Hazır', ext.success),
      if (summary.setupRequired > 0)
        (summary.setupRequired.toString(), 'Kurulum', ext.warning),
      if (summary.syncSupported > 0)
        (summary.syncSupported.toString(), 'Sync', ext.accent),
      if (summary.previewOnly > 0)
        (summary.previewOnly.toString(), 'Önizleme', ext.info),
      if (summary.adminRequired > 0)
        (summary.adminRequired.toString(), 'Admin', ext.info),
    ];
    final cells = candidates.take(5).toList(growable: false);

    final body = cells.isEmpty
        ? SizedBox(
            height: AdminCommandTokens.summaryStripHeight,
            child: Center(
              child: Text(
                summary.total > 0
                    ? '${summary.total} platform · özet metrik yok'
                    : 'Özet metrik için platform kaydı bekleniyor',
                style: TextStyle(
                  color: ext.textSecondary,
                  fontSize: typography.labelSize,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          )
        : SizedBox(
            height: AdminCommandTokens.summaryStripHeight,
            child: Row(
              children: [
                for (var i = 0; i < cells.length; i++) ...[
                  if (i > 0)
                    Container(
                      width: 1,
                      height: typography.dividerHeight,
                      color: ext.border.withValues(alpha: 0.28),
                    ),
                  Expanded(
                    child: ExecutiveMetricStripCell(
                      value: cells[i].$1,
                      label: cells[i].$2,
                      color: cells[i].$3,
                    ),
                  ),
                ],
              ],
            ),
          );

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AdminBaglantilarTokens.horizontal,
        AdminBaglantilarTokens.chromeGap / 2,
        AdminBaglantilarTokens.horizontal,
        AdminBaglantilarTokens.chromeGap,
      ),
      child: ConsultantDashboardExecutiveSurface(
        ambientStrength: 0.68,
        child: body,
      ),
    );
  }
}

class BaglantilarQuickRoutes extends StatelessWidget {
  const BaglantilarQuickRoutes({
    super.key,
    required this.onSetupWizard,
    required this.onImport,
    required this.onOfficeAdmin,
    required this.onAudit,
    required this.onMyListings,
  });

  final VoidCallback onSetupWizard;
  final VoidCallback onImport;
  final VoidCallback onOfficeAdmin;
  final VoidCallback onAudit;
  final VoidCallback onMyListings;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AdminBaglantilarTokens.horizontal,
        0,
        AdminBaglantilarTokens.horizontal,
        AdminBaglantilarTokens.moduleGap,
      ),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          _QuickChip(
            label: 'Kurulum sihirbazı',
            icon: Icons.tune_rounded,
            onTap: onSetupWizard,
          ),
          _QuickChip(
            label: 'İçe aktarma',
            icon: Icons.upload_file_rounded,
            onTap: onImport,
          ),
          _QuickChip(
            label: 'İlanlarım',
            icon: Icons.format_list_bulleted_rounded,
            onTap: onMyListings,
          ),
          _QuickChip(
            label: 'Ofis Masası',
            icon: Icons.apartment_outlined,
            onTap: onOfficeAdmin,
          ),
          _QuickChip(
            label: 'İşlem kayıtları',
            icon: Icons.receipt_long_rounded,
            onTap: onAudit,
          ),
          Text(
            'Hızlı geçiş',
            style: TextStyle(
              color: ext.textTertiary,
              fontSize: AdminBaglantilarTokens.rowChipSize,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickChip extends StatelessWidget {
  const _QuickChip({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    return Material(
      color: ext.surfaceElevated.withValues(alpha: 0.55),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: ext.accent),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  color: ext.textSecondary,
                  fontSize: AdminBaglantilarTokens.rowChipSize,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class BaglantilarCompactSearch extends StatelessWidget {
  const BaglantilarCompactSearch({
    super.key,
    required this.hintText,
    required this.onChanged,
  });

  final String hintText;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AdminBaglantilarTokens.horizontal,
        0,
        AdminBaglantilarTokens.horizontal,
        AdminBaglantilarTokens.moduleGap,
      ),
      child: SizedBox(
        height: AdminBaglantilarTokens.searchHeight,
        child: TextField(
          onChanged: onChanged,
          style: TextStyle(
            color: ext.textPrimary,
            fontSize: AdminBaglantilarTokens.rowMetaSize,
            height: 1.2,
          ),
          decoration: InputDecoration(
            isDense: true,
            hintText: hintText,
            hintStyle: TextStyle(
              color: ext.textTertiary,
              fontSize: AdminBaglantilarTokens.rowMetaSize,
            ),
            prefixIcon: Icon(
              Icons.search_rounded,
              size: 18,
              color: ext.textTertiary,
            ),
            prefixIconConstraints: const BoxConstraints(minWidth: 36),
            filled: true,
            fillColor: ext.surfaceElevated.withValues(alpha: 0.55),
            contentPadding: const EdgeInsets.symmetric(horizontal: 8),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: ext.border.withValues(alpha: 0.35)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: ext.border.withValues(alpha: 0.35)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: ext.accent.withValues(alpha: 0.65)),
            ),
          ),
        ),
      ),
    );
  }
}

class BaglantilarFilterStrip extends StatelessWidget {
  const BaglantilarFilterStrip({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final BaglantilarFilter selected;
  final ValueChanged<BaglantilarFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        0,
        0,
        0,
        AdminBaglantilarTokens.moduleGap,
      ),
      child: SizedBox(
        height: AdminBaglantilarTokens.filterChipHeight,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(
            horizontal: AdminBaglantilarTokens.horizontal,
          ),
          itemCount: BaglantilarFilter.values.length,
          separatorBuilder: (_, __) => const SizedBox(width: 6),
          itemBuilder: (context, index) {
            final filter = BaglantilarFilter.values[index];
            final isActive = filter == selected;
            return _FilterChipItem(
              label: filter.label,
              active: isActive,
              accent: ext.accent,
              onTap: () => onSelected(filter),
            );
          },
        ),
      ),
    );
  }
}

class _FilterChipItem extends StatelessWidget {
  const _FilterChipItem({
    required this.label,
    required this.active,
    required this.accent,
    required this.onTap,
  });

  final String label;
  final bool active;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    return Material(
      color: active
          ? accent.withValues(alpha: 0.18)
          : ext.surfaceElevated.withValues(alpha: 0.5),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: active
                  ? accent.withValues(alpha: 0.6)
                  : ext.border.withValues(alpha: 0.3),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: active ? accent : ext.textSecondary,
              fontSize: 11.5,
              fontWeight: active ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class BaglantilarSectionHeader extends StatelessWidget {
  const BaglantilarSectionHeader({
    super.key,
    required this.title,
    this.count,
    this.note,
  });

  final String title;
  final int? count;
  final String? note;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AdminBaglantilarTokens.horizontal,
        AdminBaglantilarTokens.sectionGap,
        AdminBaglantilarTokens.horizontal,
        AdminBaglantilarTokens.moduleGap,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                turkishBaglantiSectionUpper(title),
                style: TextStyle(
                  color: ext.textSecondary,
                  fontSize: AdminBaglantilarTokens.rowChipSize,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                ),
              ),
              if (count != null) ...[
                const SizedBox(width: 6),
                Text(
                  count.toString(),
                  style: TextStyle(
                    color: ext.textTertiary,
                    fontSize: AdminBaglantilarTokens.rowChipSize,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ],
          ),
          if (note != null && note!.isNotEmpty) ...[
            const SizedBox(height: 3),
            Text(
              note!,
              style: TextStyle(
                color: ext.textTertiary,
                fontSize: AdminBaglantilarTokens.rowChipSize,
                fontWeight: FontWeight.w600,
                height: 1.25,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class BaglantilarInlineEmpty extends StatelessWidget {
  const BaglantilarInlineEmpty({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AdminBaglantilarTokens.horizontal,
        0,
        AdminBaglantilarTokens.horizontal,
        AdminBaglantilarTokens.moduleGap,
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: ext.surfaceElevated.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: ext.border.withValues(alpha: 0.28)),
        ),
        child: Text(
          message,
          style: TextStyle(
            color: ext.textSecondary,
            fontSize: AdminBaglantilarTokens.rowMetaSize,
            height: 1.3,
          ),
        ),
      ),
    );
  }
}

class BaglantilarEmptyState extends StatelessWidget {
  const BaglantilarEmptyState({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.hub_outlined,
    this.actionLabel,
    this.onAction,
    this.onRetry,
  });

  final String title;
  final String message;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: ext.textTertiary),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: ext.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: ext.textSecondary,
                fontSize: AdminBaglantilarTokens.rowMetaSize + 1,
                height: 1.35,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              TextButton(onPressed: onRetry, child: const Text('Yeniden dene')),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 8),
              TextButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}
