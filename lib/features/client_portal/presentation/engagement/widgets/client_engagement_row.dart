import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/features/client_portal/presentation/client_portal_tokens.dart';
import 'package:emlakmaster_mobile/features/client_portal/presentation/engagement/client_engagement_types.dart';
import 'package:emlakmaster_mobile/features/client_portal/presentation/engagement/widgets/client_engagement_chrome.dart';
import 'package:flutter/material.dart';

class ClientEngagementRow extends StatelessWidget {
  const ClientEngagementRow({
    super.key,
    required this.entry,
    required this.onTap,
    required this.onDetail,
  });

  final ClientEngagementEntry entry;
  final VoidCallback onTap;
  final VoidCallback onDetail;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    final tone = engagementToneColor(ext, entry.tone);

    return RepaintBoundary(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            margin: const EdgeInsets.fromLTRB(
              ClientPortalTokens.horizontal,
              0,
              ClientPortalTokens.horizontal,
              ClientPortalTokens.chromeGap + 3,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
            decoration: BoxDecoration(
              color: ext.surface.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: ext.border.withValues(alpha: 0.3)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _KindIcon(kind: entry.kind, tone: tone),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              entry.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: ext.textPrimary,
                                fontSize: ClientPortalTokens.rowTitleSize,
                                fontWeight: FontWeight.w800,
                                height: 1.1,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: _StatusChip(
                              label: entry.statusLabel,
                              color: tone,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${entry.actionType} · ${entry.detail}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: ext.textSecondary.withValues(alpha: 0.92),
                          fontSize: ClientPortalTokens.rowMetaSize,
                          fontWeight: FontWeight.w600,
                          height: 1.15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        entry.context,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: ext.textTertiary,
                          fontSize: 9.5,
                          height: 1.15,
                        ),
                      ),
                      const SizedBox(height: 7),
                      _NextStep(label: entry.actionLabel, tone: tone),
                    ],
                  ),
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

class _KindIcon extends StatelessWidget {
  const _KindIcon({required this.kind, required this.tone});

  final EngagementKind kind;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    final icon = switch (kind) {
      EngagementKind.discovery => Icons.explore_rounded,
      EngagementKind.favorites => Icons.favorite_rounded,
      EngagementKind.message => Icons.forum_rounded,
      EngagementKind.request => Icons.event_available_rounded,
      EngagementKind.tour => Icons.video_camera_back_rounded,
      EngagementKind.profile => Icons.person_rounded,
    };
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Icon(icon, color: tone, size: 19),
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

class _NextStep extends StatelessWidget {
  const _NextStep({required this.label, required this.tone});

  final String label;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.arrow_forward_rounded, size: 13, color: tone),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: tone,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
        ),
      ],
    );
  }
}
