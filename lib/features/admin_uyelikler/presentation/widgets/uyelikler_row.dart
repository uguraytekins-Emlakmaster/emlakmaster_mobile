import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/features/admin_uyelikler/presentation/admin_uyelikler_tokens.dart';
import 'package:emlakmaster_mobile/features/admin_uyelikler/presentation/utils/uyelikler_types.dart';
import 'package:flutter/material.dart';

class UyelikRow extends StatelessWidget {
  const UyelikRow({
    super.key,
    required this.viewModel,
    required this.onTap,
    required this.onDetail,
    this.onCopyCode,
    this.onDeactivate,
    this.onCreateInvite,
    this.onKadro,
    this.onSuspend,
    this.onRemove,
  });

  final UyelikRowViewModel viewModel;
  final VoidCallback onTap;
  final VoidCallback onDetail;
  final VoidCallback? onCopyCode;
  final VoidCallback? onDeactivate;
  final VoidCallback? onCreateInvite;
  final VoidCallback? onKadro;
  final VoidCallback? onSuspend;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    final tone = _toneColor(ext, viewModel.tone);
    final emphasize = viewModel.needsAction;

    return RepaintBoundary(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            margin: const EdgeInsets.fromLTRB(
              AdminUyeliklerTokens.horizontal,
              0,
              AdminUyeliklerTokens.horizontal,
              AdminUyeliklerTokens.moduleGap,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            constraints: const BoxConstraints(
              minHeight: AdminUyeliklerTokens.rowMinHeight,
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
                _KindIcon(kind: viewModel.kind, tone: tone),
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
                                fontSize: AdminUyeliklerTokens.rowTitleSize,
                                fontWeight: FontWeight.w700,
                                height: 1.1,
                              ),
                            ),
                          ),
                          _StatusChip(label: viewModel.statusLabel, color: tone),
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
                        viewModel.subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: ext.textSecondary.withValues(alpha: 0.92),
                          fontSize: AdminUyeliklerTokens.rowMetaSize,
                          height: 1.15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        viewModel.detailLine.isNotEmpty
                            ? '${viewModel.detailLine} · ${viewModel.timestampLabel}'
                            : viewModel.timestampLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: ext.textTertiary,
                          fontSize: AdminUyeliklerTokens.rowChipSize,
                          height: 1.1,
                        ),
                      ),
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
    final isInvite = viewModel.kind == UyelikKind.invite;
    return PopupMenuButton<String>(
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
            case 'detail':
              onDetail();
            case 'copy':
              onCopyCode?.call();
            case 'deactivate':
              onDeactivate?.call();
            case 'create':
              onCreateInvite?.call();
            case 'kadro':
              onKadro?.call();
            case 'suspend':
              onSuspend?.call();
            case 'remove':
              onRemove?.call();
          }
        });
      },
      itemBuilder: (context) => [
        const PopupMenuItem(value: 'detail', child: Text('Detay')),
        if (isInvite) ...[
          if (onCopyCode != null)
            const PopupMenuItem(value: 'copy', child: Text('Kodu kopyala')),
          if (onCreateInvite != null)
            const PopupMenuItem(value: 'create', child: Text('Yeni davet')),
          if (onDeactivate != null && viewModel.isActiveInvite)
            const PopupMenuItem(
              value: 'deactivate',
              child: Text('Pasifleştir'),
            ),
        ] else ...[
          if (onKadro != null)
            const PopupMenuItem(value: 'kadro', child: Text('Kadroya git')),
          if (onSuspend != null && viewModel.canSuspend)
            const PopupMenuItem(value: 'suspend', child: Text('Askıya al')),
          if (onRemove != null && viewModel.canRemove)
            const PopupMenuItem(value: 'remove', child: Text('Kaldır')),
        ],
      ],
    );
  }
}

Color _toneColor(AppThemeExtension ext, UyelikTone tone) {
  return switch (tone) {
    UyelikTone.info => ext.info,
    UyelikTone.success => ext.success,
    UyelikTone.warning => ext.warning,
    UyelikTone.danger => ext.danger,
    UyelikTone.neutral => ext.textTertiary,
  };
}

class _KindIcon extends StatelessWidget {
  const _KindIcon({required this.kind, required this.tone});

  final UyelikKind kind;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    final icon = kind == UyelikKind.invite
        ? Icons.mail_outline_rounded
        : Icons.person_outline_rounded;
    return Container(
      width: AdminUyeliklerTokens.rowIconSize,
      height: AdminUyeliklerTokens.rowIconSize,
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: tone, size: 18),
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
          fontSize: AdminUyeliklerTokens.rowChipSize,
          fontWeight: FontWeight.w700,
          height: 1,
        ),
      ),
    );
  }
}
