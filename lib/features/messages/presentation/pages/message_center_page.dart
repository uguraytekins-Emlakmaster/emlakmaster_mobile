import 'package:emlakmaster_mobile/core/router/app_router.dart';
import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/shared/widgets/app_back_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

/// Birleşik gelen kutusu — platform OAuth tamamlanınca doldurulacak; şimdilik premium iskelet + örnek.
class MessageCenterPage extends StatelessWidget {
  const MessageCenterPage({super.key});

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);

    return Scaffold(
      backgroundColor: ext.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 16, 12),
                child: Row(
                  children: [
                    if (context.canPop()) const AppBackButton(),
                    Expanded(
                      child: Text(
                        'Mesaj merkezi',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: ext.foreground,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                            ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: ext.danger.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
                        border: Border.all(color: ext.danger.withValues(alpha: 0.35)),
                      ),
                      child: Text(
                        'Önizleme',
                        style: TextStyle(
                          color: ext.danger.withValues(alpha: 0.95),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.all(DesignTokens.space4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
                    color: ext.surfaceElevated,
                    border: Border.all(color: ext.border.withValues(alpha: 0.55)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline_rounded, color: ext.foregroundMuted, size: 22),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Harici platform mesajları OAuth ve sunucu köprüsü tamamlandığında burada birleşecek. '
                          'Şimdilik salt okunur önizleme gösterilir; uygulama içinden yanıt gönderilmez.',
                          style: TextStyle(color: ext.foregroundSecondary, height: 1.4, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 20)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'ÖRNEK KONUŞMA',
                  style: TextStyle(
                    color: ext.foregroundMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                  ),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 10)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _ConversationRow(
                  unread: 2,
                  customerName: 'Ayşe Yılmaz',
                  listingRef: '3+1 · Kayapınar',
                  platform: 'Sahibinden',
                  preview: 'Merhaba, ilanınız hâlâ güncel mi?',
                  timeLabel: '12:40',
                  onTap: () {
                    HapticFeedback.lightImpact();
                    context.push(
                      AppRouter.routeMessageThread,
                      extra: <String, dynamic>{
                        'customerName': 'Ayşe Yılmaz',
                        'listingRef': '3+1 · Kayapınar',
                        'platformLabel': 'Sahibinden',
                      },
                    );
                  },
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }
}

class _ConversationRow extends StatelessWidget {
  const _ConversationRow({
    required this.unread,
    required this.customerName,
    required this.listingRef,
    required this.platform,
    required this.preview,
    required this.timeLabel,
    required this.onTap,
  });

  final int unread;
  final String customerName;
  final String listingRef;
  final String platform;
  final String preview;
  final String timeLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
            color: ext.surfaceElevated,
            border: Border.all(color: ext.border.withValues(alpha: 0.45)),
            boxShadow: [
              BoxShadow(
                color: ext.shadowColor.withValues(alpha: 0.2),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          padding: const EdgeInsets.all(DesignTokens.space4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: scheme.primary.withValues(alpha: 0.15),
                child: Text(
                  customerName.isNotEmpty ? customerName[0].toUpperCase() : '?',
                  style: TextStyle(
                    color: scheme.primary,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            customerName,
                            style: TextStyle(
                              color: ext.foreground,
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          timeLabel,
                          style: TextStyle(color: ext.foregroundMuted, fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        _MiniChip(icon: Icons.home_work_outlined, label: listingRef),
                        _MiniChip(icon: Icons.hub_outlined, label: platform),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      preview,
                      style: TextStyle(color: ext.foregroundSecondary, fontSize: 14, height: 1.35),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (unread > 0) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: scheme.primary,
                    borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
                  ),
                  child: Text(
                    '$unread',
                    style: TextStyle(
                      color: ext.onBrand,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
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

class _MiniChip extends StatelessWidget {
  const _MiniChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: ext.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: ext.border.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: ext.foregroundMuted),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(color: ext.foregroundSecondary, fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
