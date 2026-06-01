import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/features/crm_customers/presentation/consultant_customers_tokens.dart';
import 'package:emlakmaster_mobile/features/crm_customers/presentation/workspace/customer_workspace_types.dart';
import 'package:emlakmaster_mobile/features/crm_customers/presentation/workspace/widgets/customer_workspace_chrome.dart';
import 'package:flutter/material.dart';

enum CustomerRowMenu { open, call, message, whatsapp, followUp, tasks }

/// Premium müşteri satırı — heat avatar + ad + sıcaklık çipi + son temas +
/// bağlam. Per-row blur yok; RepaintBoundary ile sınırlı yeniden boyama.
class CustomerWorkspaceRow extends StatelessWidget {
  const CustomerWorkspaceRow({
    super.key,
    required this.row,
    required this.onTap,
    required this.onCall,
    required this.onMenu,
  });

  final CustomerRowView row;
  final VoidCallback onTap;
  final VoidCallback? onCall;
  final void Function(CustomerRowMenu) onMenu;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    final tone = customerToneColor(ext, row.tone);

    return RepaintBoundary(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            margin: const EdgeInsets.fromLTRB(
              ConsultantCustomersTokens.horizontal,
              0,
              ConsultantCustomersTokens.horizontal,
              ConsultantCustomersTokens.chromeGap + 2,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
            decoration: BoxDecoration(
              color: ext.surface.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: row.syncRisk
                    ? ext.warning.withValues(alpha: 0.4)
                    : ext.border.withValues(alpha: 0.32),
              ),
            ),
            child: Row(
              children: [
                _HeatAvatar(initial: row.initial, score: row.heatScore, tone: tone),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              row.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: ext.textPrimary,
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                                height: 1.1,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: _HeatChip(label: row.heatLabel, color: tone),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              row.contactLine,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: ext.textSecondary.withValues(alpha: 0.92),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                height: 1.15,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          _LastContact(
                            label: row.lastContactLabel,
                            colorType: row.lastContactColorType,
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          if (row.needsContact)
                            _MicroTag(
                              icon: Icons.schedule_rounded,
                              label: 'Temas gerekli',
                              color: ext.warning,
                            ),
                          if (row.isPartial && row.partialNote.isNotEmpty) ...[
                            if (row.needsContact) const SizedBox(width: 6),
                            _MicroTag(
                              icon: Icons.report_gmailerrorred_rounded,
                              label: row.partialNote,
                              color: ext.textTertiary,
                            ),
                          ],
                          if (!row.needsContact &&
                              !(row.isPartial && row.partialNote.isNotEmpty))
                            Expanded(
                              child: Text(
                                row.contextLine,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: ext.textTertiary,
                                  fontSize: 9.5,
                                  height: 1.15,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                if (onCall != null)
                  _ActionIcon(
                    icon: Icons.call_rounded,
                    color: ext.success,
                    onTap: onCall!,
                    tooltip: 'Ara',
                  ),
                _menu(context, ext),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _menu(BuildContext context, AppThemeExtension ext) {
    return PopupMenuButton<CustomerRowMenu>(
      tooltip: 'Aksiyonlar',
      icon: Icon(Icons.more_vert_rounded,
          color: ext.textTertiary,
          size: ConsultantCustomersTokens.actionIconSize),
      onSelected: onMenu,
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: CustomerRowMenu.open,
          child: _MenuRow(icon: Icons.open_in_new_rounded, label: 'Aç'),
        ),
        if (row.callablePhone)
          const PopupMenuItem(
            value: CustomerRowMenu.call,
            child: _MenuRow(icon: Icons.call_rounded, label: 'Ara'),
          ),
        if (row.callablePhone)
          const PopupMenuItem(
            value: CustomerRowMenu.message,
            child: _MenuRow(icon: Icons.sms_rounded, label: 'Mesaj'),
          ),
        if (row.callablePhone)
          const PopupMenuItem(
            value: CustomerRowMenu.whatsapp,
            child: _MenuRow(icon: Icons.chat_rounded, label: 'WhatsApp'),
          ),
        const PopupMenuItem(
          value: CustomerRowMenu.followUp,
          child: _MenuRow(icon: Icons.playlist_add_rounded, label: 'Takibe ekle'),
        ),
        const PopupMenuItem(
          value: CustomerRowMenu.tasks,
          child: _MenuRow(icon: Icons.task_alt_rounded, label: 'Görevlere git'),
        ),
      ],
    );
  }
}

class _HeatAvatar extends StatelessWidget {
  const _HeatAvatar({
    required this.initial,
    required this.score,
    required this.tone,
  });

  final String initial;
  final int score;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: ConsultantCustomersTokens.rowAvatarSize + 6,
      height: ConsultantCustomersTokens.rowAvatarSize + 6,
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: tone.withValues(alpha: 0.32)),
      ),
      child: Center(
        child: Text(
          initial,
          style: TextStyle(
            color: tone,
            fontWeight: FontWeight.w800,
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}

class _HeatChip extends StatelessWidget {
  const _HeatChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        maxLines: 1,
        softWrap: false,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: color,
          fontSize: 9.5,
          fontWeight: FontWeight.w700,
          height: 1,
        ),
      ),
    );
  }
}

class _LastContact extends StatelessWidget {
  const _LastContact({required this.label, required this.colorType});

  final String label;
  final int colorType;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    final color = switch (colorType) {
      1 => ext.success,
      2 => ext.warning,
      3 => ext.textTertiary,
      _ => ext.textTertiary,
    };
    return Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: color,
        fontSize: 9.5,
        fontWeight: FontWeight.w700,
        height: 1.1,
      ),
    );
  }
}

class _MicroTag extends StatelessWidget {
  const _MicroTag({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Flexible(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 3),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                height: 1.1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionIcon extends StatelessWidget {
  const _ActionIcon({
    required this.icon,
    required this.color,
    required this.onTap,
    required this.tooltip,
  });

  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(9),
        child: SizedBox(
          width: ConsultantCustomersTokens.actionTapSize,
          height: ConsultantCustomersTokens.actionTapSize,
          child: Icon(icon,
              color: color, size: ConsultantCustomersTokens.actionIconSize),
        ),
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18),
        const SizedBox(width: 10),
        Text(label),
      ],
    );
  }
}
