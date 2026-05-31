import 'package:emlakmaster_mobile/core/branding/brand_emblem.dart';
import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/app_typography.dart';
import 'package:emlakmaster_mobile/features/admin_ofis_masasi/presentation/admin_ofis_masasi_tokens.dart';
import 'package:emlakmaster_mobile/features/admin_ofis_masasi/presentation/utils/ofis_masasi_types.dart';
import 'package:emlakmaster_mobile/features/dashboard/presentation/admin_command/admin_command_tokens.dart';
import 'package:emlakmaster_mobile/features/dashboard/presentation/admin_command/widgets/admin_command_chrome.dart';
import 'package:emlakmaster_mobile/screens/consultant_dashboard/widgets/consultant_dashboard_surface.dart';
import 'package:emlakmaster_mobile/widgets/premium/premium_navigation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

String turkishOfisSectionUpper(String label) {
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

class PremiumOfisMasasiHeader extends StatelessWidget {
  const PremiumOfisMasasiHeader({
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
              _OfisHeaderEmblem(size: m.emblemSize, pad: m.emblemPad),
              SizedBox(width: m.titleGap),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(top: m.emblemPad * 0.15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ofis Masası',
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
                        'Ofis durumu, üyeler ve bağlantılar',
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
                  : 'Yalnızca gerçek ofis verisi gösterilir; canlı senkron veya onboarding iddiası yok.',
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

class _OfisHeaderEmblem extends StatelessWidget {
  const _OfisHeaderEmblem({required this.size, required this.pad});

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

class OfisMasasiSummaryStripView extends StatelessWidget {
  const OfisMasasiSummaryStripView({super.key, required this.summary});

  final OfisMasasiSummary summary;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    final typography = AdminCommandTokens.stripTypography(context);
    final cells = <(String, String, Color)>[
      if (summary.activeMembers > 0)
        (summary.activeMembers.toString(), 'Aktif üye', ext.accent),
      if (summary.pendingInvites > 0)
        (summary.pendingInvites.toString(), 'Bekleyen davet', ext.info),
      if (summary.suspendedMembers > 0)
        (summary.suspendedMembers.toString(), 'Askıda', ext.warning),
      if (summary.connectionsKnown && summary.totalConnections > 0)
        (
          '${summary.connectionsReady}/${summary.totalConnections}',
          'Bağlantı hazır',
          summary.connectionsReady > 0 ? ext.success : ext.warning,
        ),
      if (summary.interventionCount > 0)
        (summary.interventionCount.toString(), 'Müdahale', ext.danger),
    ];

    final body = cells.isEmpty
        ? SizedBox(
            height: AdminCommandTokens.summaryStripHeight,
            child: Center(
              child: Text(
                summary.totalMembers + summary.totalInvites > 0
                    ? '${summary.totalMembers + summary.totalInvites} kayıt · özet metrik yok'
                    : 'Özet metrik için kayıt bekleniyor',
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
        AdminOfisMasasiTokens.horizontal,
        AdminOfisMasasiTokens.chromeGap / 2,
        AdminOfisMasasiTokens.horizontal,
        AdminOfisMasasiTokens.chromeGap,
      ),
      child: ConsultantDashboardExecutiveSurface(
        ambientStrength: 0.68,
        child: body,
      ),
    );
  }
}

class OfisMasasiQuickRoutes extends StatelessWidget {
  const OfisMasasiQuickRoutes({
    super.key,
    required this.onCreateInvite,
    required this.onUyelikler,
    required this.onKadro,
    required this.onTeams,
    required this.onConnections,
  });

  final VoidCallback onCreateInvite;
  final VoidCallback onUyelikler;
  final VoidCallback onKadro;
  final VoidCallback onTeams;
  final VoidCallback onConnections;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AdminOfisMasasiTokens.horizontal,
        0,
        AdminOfisMasasiTokens.horizontal,
        AdminOfisMasasiTokens.moduleGap,
      ),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          _QuickChip(
            label: 'Yeni davet',
            icon: Icons.person_add_alt_1_rounded,
            onTap: onCreateInvite,
          ),
          _QuickChip(
            label: 'Üyelikler',
            icon: Icons.badge_outlined,
            onTap: onUyelikler,
          ),
          _QuickChip(
            label: 'Kadro',
            icon: Icons.groups_rounded,
            onTap: onKadro,
          ),
          _QuickChip(
            label: 'Ekipler',
            icon: Icons.group_work_rounded,
            onTap: onTeams,
          ),
          _QuickChip(
            label: 'Bağlantılar',
            icon: Icons.hub_outlined,
            onTap: onConnections,
          ),
          Text(
            'Hızlı geçiş',
            style: TextStyle(
              color: ext.textTertiary,
              fontSize: AdminOfisMasasiTokens.rowChipSize,
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
                  fontSize: AdminOfisMasasiTokens.rowChipSize,
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

class OfisMasasiCompactSearch extends StatelessWidget {
  const OfisMasasiCompactSearch({
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
        AdminOfisMasasiTokens.horizontal,
        0,
        AdminOfisMasasiTokens.horizontal,
        AdminOfisMasasiTokens.moduleGap,
      ),
      child: SizedBox(
        height: AdminOfisMasasiTokens.searchHeight,
        child: TextField(
          onChanged: onChanged,
          style: TextStyle(
            color: ext.textPrimary,
            fontSize: AdminOfisMasasiTokens.rowMetaSize,
            height: 1.2,
          ),
          decoration: InputDecoration(
            isDense: true,
            hintText: hintText,
            hintStyle: TextStyle(
              color: ext.textTertiary,
              fontSize: AdminOfisMasasiTokens.rowMetaSize,
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

class OfisMasasiSectionHeader extends StatelessWidget {
  const OfisMasasiSectionHeader({
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
        AdminOfisMasasiTokens.horizontal,
        AdminOfisMasasiTokens.sectionGap,
        AdminOfisMasasiTokens.horizontal,
        AdminOfisMasasiTokens.moduleGap,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                turkishOfisSectionUpper(title),
                style: TextStyle(
                  color: ext.textSecondary,
                  fontSize: AdminOfisMasasiTokens.rowChipSize,
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
                    fontSize: AdminOfisMasasiTokens.rowChipSize,
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
                fontSize: AdminOfisMasasiTokens.rowChipSize,
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

class OfisMasasiInlineEmpty extends StatelessWidget {
  const OfisMasasiInlineEmpty({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AdminOfisMasasiTokens.horizontal,
        0,
        AdminOfisMasasiTokens.horizontal,
        AdminOfisMasasiTokens.moduleGap,
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
            fontSize: AdminOfisMasasiTokens.rowMetaSize,
            height: 1.3,
          ),
        ),
      ),
    );
  }
}

class OfisMasasiEmptyState extends StatelessWidget {
  const OfisMasasiEmptyState({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.apartment_rounded,
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
                fontSize: AdminOfisMasasiTokens.rowMetaSize + 1,
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
