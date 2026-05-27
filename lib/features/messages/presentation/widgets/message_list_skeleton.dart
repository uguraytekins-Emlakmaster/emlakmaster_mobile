import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/core/widgets/shimmer_placeholder.dart';
import 'package:emlakmaster_mobile/features/messages/presentation/consultant_messages_tokens.dart';
import 'package:flutter/material.dart';

class MessageListSkeleton extends StatelessWidget {
  const MessageListSkeleton({super.key, this.itemCount = 5});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        ConsultantMessagesTokens.horizontal,
        0,
        ConsultantMessagesTokens.horizontal,
        ConsultantMessagesTokens.sectionGap,
      ),
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      separatorBuilder: (_, __) => const SizedBox(height: 6),
      itemBuilder: (_, __) => Container(
        height: 76,
        decoration: BoxDecoration(
          color: ext.card.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
          border: Border.all(color: ext.border.withValues(alpha: 0.25)),
        ),
        padding: const EdgeInsets.all(10),
        child: const Row(
          children: [
            ShimmerPlaceholder(width: 44, height: 44),
            SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ShimmerPlaceholder(width: double.infinity, height: 12),
                  SizedBox(height: 6),
                  ShimmerPlaceholder(width: 140, height: 10),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
