import 'package:emlakmaster_mobile/core/branding/brand_emblem.dart';
import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/app_typography.dart';
import 'package:emlakmaster_mobile/features/messages/presentation/consultant_messages_tokens.dart';
import 'package:emlakmaster_mobile/features/messages/presentation/utils/message_conversation_list_filter.dart';
import 'package:emlakmaster_mobile/screens/consultant_dashboard/widgets/consultant_dashboard_surface.dart';
import 'package:emlakmaster_mobile/widgets/premium/premium_ui_kit.dart';
import 'package:flutter/material.dart';

class PremiumMessagesPageHeader extends StatelessWidget {
  const PremiumMessagesPageHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.actions = const [],
    this.showPreviewBadge = true,
  });

  final String title;
  final String subtitle;
  final List<Widget> actions;
  final bool showPreviewBadge;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        ConsultantMessagesTokens.horizontal,
        ConsultantMessagesTokens.topInset + 4,
        ConsultantMessagesTokens.horizontal,
        ConsultantMessagesTokens.headerBottomGap,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PremiumHeaderNavBar(),
          Row(
        children: [
          const BrandEmblem(
            variant: BrandEmblemVariant.mini,
            size: ConsultantMessagesTokens.headerEmblemSize,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: AppTypography.pageHeading(context).copyWith(
                    fontSize: ConsultantMessagesTokens.headerTitleSize,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                    height: 1.05,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTypography.meta(context).copyWith(
                    color: ext.textSecondary.withValues(alpha: 0.88),
                    fontSize: ConsultantMessagesTokens.headerSubtitleSize,
                    fontWeight: FontWeight.w500,
                    height: 1.1,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (showPreviewBadge) ...[
            const SizedBox(width: 6),
            PremiumStatusPill(
              label: 'Önizleme',
              color: ext.warning,
              outlined: true,
            ),
          ],
          ...actions,
            ],
          ),
        ],
      ),
    );
  }
}

class PremiumMessagesSummaryStrip extends StatelessWidget {
  const PremiumMessagesSummaryStrip({super.key, required this.summary});

  final MessageListSummary summary;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    final cells = <(String, String, Color)>[
      (summary.totalConversations.toString(), 'Toplam', ext.accent),
      (summary.unread.toString(), 'Okunmamış', ext.warning),
      (summary.liveChannels.toString(), 'Canlı kanal', ext.success),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        ConsultantMessagesTokens.horizontal,
        ConsultantMessagesTokens.chromeGap / 2,
        ConsultantMessagesTokens.horizontal,
        ConsultantMessagesTokens.chromeGap,
      ),
      child: ConsultantDashboardExecutiveSurface(
        ambientStrength: 0.72,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: SizedBox(
          height: ConsultantMessagesTokens.summaryStripHeight - 16,
          child: Row(
            children: [
              for (var i = 0; i < cells.length; i++) ...[
                if (i > 0)
                  Container(
                    width: 1,
                    height: 28,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    color: ext.border.withValues(alpha: 0.35),
                  ),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        cells[i].$1,
                        style: AppTypography.metricValue(context).copyWith(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: cells[i].$3,
                          height: 1,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        cells[i].$2,
                        style: TextStyle(
                          color: ext.textTertiary,
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          height: 1,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class PremiumMessagesStatusBanner extends StatelessWidget {
  const PremiumMessagesStatusBanner({
    super.key,
    required this.message,
    required this.icon,
    this.onDismiss,
    this.actionLabel,
    this.onAction,
  });

  final String message;
  final IconData icon;
  final VoidCallback? onDismiss;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        ConsultantMessagesTokens.horizontal,
        0,
        ConsultantMessagesTokens.horizontal,
        ConsultantMessagesTokens.chromeGap,
      ),
      child: ConsultantDashboardExecutiveSurface(
        ambientStrength: 0.7,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: ext.warning),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: ext.textSecondary,
                  fontSize: 11.5,
                  height: 1.3,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              TextButton(
                onPressed: onAction,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  actionLabel!,
                  style: TextStyle(
                    color: ext.accent,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
            if (onDismiss != null)
              IconButton(
                onPressed: onDismiss,
                icon: Icon(Icons.close_rounded, size: 18, color: ext.textTertiary),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              ),
          ],
        ),
      ),
    );
  }
}

class PremiumMessageSearchRow extends StatelessWidget {
  const PremiumMessageSearchRow({
    super.key,
    required this.controller,
    required this.hintText,
  });

  final TextEditingController controller;
  final String hintText;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        ConsultantMessagesTokens.horizontal,
        0,
        ConsultantMessagesTokens.horizontal,
        ConsultantMessagesTokens.chromeGap / 2,
      ),
      child: ConsultantDashboardExecutiveSurface(
        ambientStrength: 0.75,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: SizedBox(
          height: ConsultantMessagesTokens.searchBarHeight,
          child: PremiumSearchBar(
            controller: controller,
            hintText: hintText,
            compact: true,
          ),
        ),
      ),
    );
  }
}

class PremiumMessageFilterStrip extends StatelessWidget {
  const PremiumMessageFilterStrip({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final MessagePlatformFilter selected;
  final ValueChanged<MessagePlatformFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        ConsultantMessagesTokens.horizontal,
        0,
        ConsultantMessagesTokens.horizontal,
        ConsultantMessagesTokens.sectionGap,
      ),
      child: ConsultantDashboardExecutiveSurface(
        ambientStrength: 0.72,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: ClipRect(
          child: SizedBox(
            height: ConsultantMessagesTokens.filterStripHeight,
            child: ScrollConfiguration(
              behavior: ScrollConfiguration.of(context).copyWith(
                scrollbars: false,
                overscroll: false,
              ),
              child: ListView.separated(
                key: const Key('message_filter_strip_scroll'),
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(
                  parent: ClampingScrollPhysics(),
                ),
                clipBehavior: Clip.none,
                cacheExtent: 360,
                padding: const EdgeInsets.only(right: 4),
                itemCount: MessagePlatformFilter.values.length,
                separatorBuilder: (_, __) => const SizedBox(width: 6),
                itemBuilder: (context, index) {
                  final filter = MessagePlatformFilter.values[index];
                  return PremiumFilterChip(
                    label: filter.label,
                    selected: selected == filter,
                    onTap: () => onSelected(filter),
                    dense: true,
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
