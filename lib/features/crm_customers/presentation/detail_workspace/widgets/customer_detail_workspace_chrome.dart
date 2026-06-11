import 'package:emlakmaster_mobile/core/branding/brand_emblem.dart';
import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/features/crm_customers/presentation/consultant_customers_tokens.dart';
import 'package:emlakmaster_mobile/features/crm_customers/presentation/detail_workspace/customer_detail_workspace_types.dart';
import 'package:emlakmaster_mobile/widgets/premium/premium_navigation.dart';
import 'package:flutter/material.dart';
import 'package:emlakmaster_mobile/shared/widgets/dismissible_honesty_note.dart';

class CustomerDetailWorkspaceHeader extends StatelessWidget {
  const CustomerDetailWorkspaceHeader({
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
        ConsultantCustomersTokens.horizontal,
        ConsultantCustomersTokens.topInset + 4,
        ConsultantCustomersTokens.horizontal,
        ConsultantCustomersTokens.headerBottomGap,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PremiumHeaderNavBar(),
          Row(
            children: [
              const BrandEmblem(
                variant: BrandEmblemVariant.mini,
                size: ConsultantCustomersTokens.headerEmblemSize,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: ext.textPrimary,
                        fontSize: ConsultantCustomersTokens.headerTitleSize,
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
                        fontSize: ConsultantCustomersTokens.headerSubtitleSize,
                        fontWeight: FontWeight.w500,
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
              prefsKey: 'honesty_note_customer_detail_v1',
            ),
          ],
        ],
      ),
    );
  }
}

class CustomerDetailWorkspaceSummaryStrip extends StatelessWidget {
  const CustomerDetailWorkspaceSummaryStrip({super.key, required this.summary});

  final CustomerDetailWorkspaceSummary summary;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    final cells = <(String, String, Color)>[
      (summary.lastContact, 'Son temas', ext.accent),
      ('${summary.activeTasks}', 'Aktif görev', ext.warning),
      if (summary.activeFollowUp > 0)
        ('${summary.activeFollowUp}', 'Takip', ext.danger),
      if (summary.callRelation > 0)
        ('${summary.callRelation}', 'Çağrı', ext.info),
      if (summary.isPartial) ('!', 'Kısmi', ext.textTertiary),
      if (summary.portfolioCount > 0)
        ('${summary.portfolioCount}', 'Portföy', ext.success),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        ConsultantCustomersTokens.horizontal,
        0,
        ConsultantCustomersTokens.horizontal,
        ConsultantCustomersTokens.sectionGap,
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

class CustomerDetailQuickActionsRow extends StatelessWidget {
  const CustomerDetailQuickActionsRow({
    super.key,
    required this.actions,
    required this.onAction,
  });

  final List<CustomerDetailQuickAction> actions;
  final ValueChanged<CustomerDetailQuickAction> onAction;

  @override
  Widget build(BuildContext context) {
    if (actions.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        ConsultantCustomersTokens.horizontal,
        0,
        ConsultantCustomersTokens.horizontal,
        ConsultantCustomersTokens.chromeGap,
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final a in actions) ...[
              _QuickChip(
                label: _label(a),
                icon: _icon(a),
                onTap: () => onAction(a),
              ),
              const SizedBox(width: 6),
            ],
          ],
        ),
      ),
    );
  }

  static String _label(CustomerDetailQuickAction a) => switch (a) {
        CustomerDetailQuickAction.call => 'Ara',
        CustomerDetailQuickAction.message => 'Mesaj',
        CustomerDetailQuickAction.whatsapp => 'WhatsApp',
        CustomerDetailQuickAction.tasks => 'Göreve git',
        CustomerDetailQuickAction.followUp => 'Takibe git',
        CustomerDetailQuickAction.portfolio => 'Portföye git',
      };

  static IconData _icon(CustomerDetailQuickAction a) => switch (a) {
        CustomerDetailQuickAction.call => Icons.call_rounded,
        CustomerDetailQuickAction.message => Icons.sms_rounded,
        CustomerDetailQuickAction.whatsapp => Icons.chat_rounded,
        CustomerDetailQuickAction.tasks => Icons.task_alt_rounded,
        CustomerDetailQuickAction.followUp => Icons.track_changes_rounded,
        CustomerDetailQuickAction.portfolio => Icons.home_work_outlined,
      };
}

class CustomerDetailSectionHeader extends StatelessWidget {
  const CustomerDetailSectionHeader({
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
        ConsultantCustomersTokens.horizontal,
        8,
        ConsultantCustomersTokens.horizontal,
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
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
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
              fontSize: 13,
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
              fontSize: 9,
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
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: ext.surface.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: ext.border.withValues(alpha: 0.32)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: ext.accent),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: ext.textPrimary,
                  fontSize: 11,
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
