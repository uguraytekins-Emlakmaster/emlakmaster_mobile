import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/core/theme/premium/premium_theme_extension.dart';
import 'package:emlakmaster_mobile/features/resurrection_engine/domain/entities/resurrection_segment.dart';
import 'package:emlakmaster_mobile/features/resurrection_engine/presentation/consultant_follow_up_tokens.dart';
import 'package:emlakmaster_mobile/features/resurrection_engine/presentation/models/follow_up_row_snapshot.dart';
import 'package:emlakmaster_mobile/features/resurrection_engine/presentation/widgets/follow_up_list_row_quick_actions.dart';
import 'package:flutter/material.dart';

class FollowUpListPremiumTile extends StatelessWidget {
  const FollowUpListPremiumTile({
    super.key,
    required this.item,
    required this.snapshot,
    this.onTap,
    this.onCall,
    this.onWhatsApp,
    this.onOpenCustomer,
    this.onCreateTask,
    this.onSnooze,
    this.onDetail,
  });

  final ResurrectionQueueItem item;
  final FollowUpRowSnapshot snapshot;
  final VoidCallback? onTap;
  final VoidCallback? onCall;
  final VoidCallback? onWhatsApp;
  final VoidCallback? onOpenCustomer;
  final VoidCallback? onCreateTask;
  final VoidCallback? onSnooze;
  final VoidCallback? onDetail;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    final premium = PremiumThemeExtension.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          ConsultantFollowUpTokens.rowPaddingH,
          ConsultantFollowUpTokens.rowPaddingV,
          ConsultantFollowUpTokens.rowPaddingH,
          ConsultantFollowUpTokens.rowPaddingV,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    snapshot.displayName,
                    style: TextStyle(
                      color: ext.textPrimary,
                      fontWeight: FontWeight.w800,
                      fontSize: ConsultantFollowUpTokens.rowTitleSize,
                      letterSpacing: -0.2,
                      height: 1.1,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 4),
                _StatusChip(label: snapshot.urgencyLabel, tone: ext.warning),
                if (snapshot.heatChipLabel != null) ...[
                  const SizedBox(width: 4),
                  _StatusChip(
                    label: snapshot.heatChipLabel!,
                    tone: premium.champagneGold,
                  ),
                ],
              ],
            ),
            const SizedBox(height: 2),
            Text(
              snapshot.phoneLine,
              style: TextStyle(
                color: snapshot.showNoPhoneTag
                    ? ext.textTertiary
                    : ext.textSecondary,
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                height: 1.1,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              snapshot.lastInteractionLine,
              style: TextStyle(
                color: ext.textSecondary,
                fontSize: ConsultantFollowUpTokens.rowMetaSize,
                height: 1.15,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 3),
            Text(
              snapshot.followUpReason,
              style: TextStyle(
                color: ext.textPrimary.withValues(alpha: 0.88),
                fontSize: 11,
                fontWeight: FontWeight.w600,
                height: 1.2,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: [
                _MiniChip(label: snapshot.staleAgeLine, fg: ext.warning),
                if (snapshot.showCallbackTag)
                  _MiniChip(label: 'Geri aranacak', fg: ext.info),
                if (snapshot.showNoPhoneTag)
                  _MiniChip(label: 'Ulaşılamıyor', fg: ext.danger),
                _MiniChip(
                  label: snapshot.linkedStateLabel,
                  fg: ext.textTertiary,
                ),
              ],
            ),
            if (snapshot.metaLine.isNotEmpty) ...[
              const SizedBox(height: 3),
              Text(
                snapshot.metaLine,
                style: TextStyle(
                  color: ext.textTertiary,
                  fontSize: 9.5,
                  height: 1.2,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 2),
            FollowUpListRowQuickActions(
              onCall: onCall,
              onWhatsApp: onWhatsApp,
              onOpenCustomer: onOpenCustomer,
              onCreateTask: onCreateTask,
              onSnooze: onSnooze,
              onDetail: onDetail,
              canCall: snapshot.canCall,
              canWhatsApp: snapshot.canWhatsApp,
              canOpenCustomer: snapshot.canOpenCustomer,
              canCreateTask: snapshot.canCreateTask,
              canSnooze: snapshot.canSnooze,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.tone});

  final String label;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
        border: Border.all(color: tone.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: tone,
          fontSize: ConsultantFollowUpTokens.statusChipFontSize,
          fontWeight: FontWeight.w700,
          height: 1,
        ),
      ),
    );
  }
}

class _MiniChip extends StatelessWidget {
  const _MiniChip({required this.label, required this.fg});

  final String label;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: fg.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontSize: 9,
          fontWeight: FontWeight.w600,
          height: 1,
        ),
      ),
    );
  }
}
