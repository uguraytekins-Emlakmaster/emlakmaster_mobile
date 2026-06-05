import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/features/admin_baglantilar/presentation/admin_baglantilar_tokens.dart';
import 'package:emlakmaster_mobile/features/admin_baglantilar/presentation/utils/baglantilar_types.dart';
import 'package:flutter/material.dart';

class BaglantilarRow extends StatelessWidget {
  const BaglantilarRow({
    super.key,
    required this.viewModel,
    required this.onTap,
    required this.onDetail,
    this.onOpen,
    this.onConnect,
    this.onConfigure,
    this.onImport,
    this.onRetry,
    this.onOfficeAdmin,
  });

  final BaglantiRowViewModel viewModel;
  final VoidCallback onTap;
  final VoidCallback onDetail;
  final VoidCallback? onOpen;
  final VoidCallback? onConnect;
  final VoidCallback? onConfigure;
  final VoidCallback? onImport;
  final VoidCallback? onRetry;
  final VoidCallback? onOfficeAdmin;

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
              AdminBaglantilarTokens.horizontal,
              0,
              AdminBaglantilarTokens.horizontal,
              AdminBaglantilarTokens.moduleGap,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            constraints: const BoxConstraints(
              minHeight: AdminBaglantilarTokens.rowMinHeight,
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
                _PlatformIcon(tone: tone),
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
                              viewModel.platformName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: ext.textPrimary,
                                fontSize: AdminBaglantilarTokens.rowTitleSize,
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
                                label: viewModel.statusLabel,
                                color: tone,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        viewModel.detailLine.isNotEmpty
                            ? '${viewModel.providerLine} · ${viewModel.detailLine}'
                            : viewModel.providerLine,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: ext.textSecondary.withValues(alpha: 0.92),
                          fontSize: AdminBaglantilarTokens.rowMetaSize,
                          height: 1.15,
                        ),
                      ),
                      if (viewModel.needsAdmin ||
                          viewModel.capabilityPills.isNotEmpty) ...[
                        const SizedBox(height: 5),
                        Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          children: [
                            if (viewModel.needsAdmin)
                              _CapabilityPill(
                                label: 'Admin gerekli',
                                tone: ext.info,
                              ),
                            for (final pill in viewModel.capabilityPills)
                              _CapabilityPill(label: pill),
                          ],
                        ),
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
            case 'open':
              onOpen?.call();
            case 'connect':
              onConnect?.call();
            case 'configure':
              onConfigure?.call();
            case 'import':
              onImport?.call();
            case 'retry':
              onRetry?.call();
            case 'office':
              onOfficeAdmin?.call();
          }
        });
      },
      itemBuilder: (context) => [
        const PopupMenuItem(value: 'detail', child: Text('Detay')),
        if (onOpen != null && viewModel.canImport)
          const PopupMenuItem(value: 'open', child: Text('Aç')),
        if (onConnect != null && viewModel.canConnect)
          const PopupMenuItem(value: 'connect', child: Text('Bağlan')),
        if (onConfigure != null && viewModel.canConfigure)
          const PopupMenuItem(value: 'configure', child: Text('Yapılandır')),
        if (onImport != null && viewModel.canImport)
          const PopupMenuItem(value: 'import', child: Text('İçe aktar')),
        if (onRetry != null && viewModel.canRetry)
          const PopupMenuItem(value: 'retry', child: Text('Yeniden dene')),
        if (onOfficeAdmin != null)
          const PopupMenuItem(value: 'office', child: Text('Ofis Masasına git')),
      ],
    );
  }
}

Color _toneColor(AppThemeExtension ext, BaglantiTone tone) {
  return switch (tone) {
    BaglantiTone.info => ext.info,
    BaglantiTone.success => ext.success,
    BaglantiTone.warning => ext.warning,
    BaglantiTone.danger => ext.danger,
    BaglantiTone.neutral => ext.textTertiary,
  };
}

class _PlatformIcon extends StatelessWidget {
  const _PlatformIcon({required this.tone});

  final Color tone;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: AdminBaglantilarTokens.rowIconSize,
      height: AdminBaglantilarTokens.rowIconSize,
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(Icons.hub_outlined, color: tone, size: 18),
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
          fontSize: AdminBaglantilarTokens.rowChipSize,
          fontWeight: FontWeight.w700,
          height: 1,
        ),
      ),
    );
  }
}

class _CapabilityPill extends StatelessWidget {
  const _CapabilityPill({required this.label, this.tone});

  final String label;
  final Color? tone;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    final color = tone ?? ext.textTertiary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: tone != null
            ? tone!.withValues(alpha: 0.12)
            : ext.surfaceElevated.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: tone != null
              ? tone!.withValues(alpha: 0.3)
              : ext.border.withValues(alpha: 0.3),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: AdminBaglantilarTokens.rowChipSize,
          fontWeight: FontWeight.w600,
          height: 1,
        ),
      ),
    );
  }
}
