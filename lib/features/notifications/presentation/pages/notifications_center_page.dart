import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emlakmaster_mobile/core/services/firestore_service.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/shared/widgets/empty_state.dart';
import 'package:emlakmaster_mobile/shared/widgets/emlak_app_bar.dart';
import 'package:emlakmaster_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Bildirim merkezi: in-app bildirimler, boş durumlar [EmptyState] ile hizalı.
class NotificationsCenterPage extends ConsumerWidget {
  const NotificationsCenterPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid =
        ref.watch(currentUserProvider.select((v) => v.valueOrNull?.uid ?? ''));
    final ext = AppThemeExtension.of(context);
    return Scaffold(
      backgroundColor: ext.background,
      appBar: emlakAppBar(
        context,
        backgroundColor: ext.background,
        foregroundColor: ext.textPrimary,
        title: const Text(
          'Bildirimler',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
      ),
      body: uid.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(DesignTokens.space6),
                child: EmptyState(
                  icon: Icons.notifications_none_rounded,
                  title: 'Giriş gerekli',
                  subtitle: 'Bildirimleri görmek için oturum açın.',
                  grouped: true,
                  premiumVisual: true,
                ),
              ),
            )
          : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirestoreService.notificationsByUserStream(uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 32,
                          height: 32,
                          child: CircularProgressIndicator(
                            color: ext.accent,
                            strokeWidth: 2,
                          ),
                        ),
                        const SizedBox(height: DesignTokens.space4),
                        Text(
                          'Bildirimler yükleniyor…',
                          style: TextStyle(
                            color: ext.textSecondary,
                            fontSize: DesignTokens.fontSizeSm,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(DesignTokens.space6),
                      child: EmptyState(
                        icon: Icons.notifications_none_rounded,
                        title: 'Henüz bildirim yok',
                        subtitle:
                            'Lead, görev ve güncellemeler burada özetlenir.',
                        grouped: true,
                        premiumVisual: true,
                      ),
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: DesignTokens.space5,
                    vertical: DesignTokens.space4,
                  ),
                  itemCount: docs.length,
                  cacheExtent: 300,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final d = doc.data();
                    final title = d['title'] as String? ?? 'Bildirim';
                    final body = d['body'] as String? ?? '';
                    final createdAt = (d['createdAt'] as Timestamp?)?.toDate();
                    final read = d['read'] == true;
                    return _NotificationCard(
                      title: title,
                      body: body,
                      createdAt: createdAt,
                      read: read,
                    );
                  },
                );
              },
            ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({
    required this.title,
    required this.body,
    this.createdAt,
    this.read = false,
  });

  final String title;
  final String body;
  final DateTime? createdAt;
  final bool read;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: DesignTokens.space3),
      padding: const EdgeInsets.all(DesignTokens.space4),
      decoration: BoxDecoration(
        color: read ? ext.surface : ext.surface.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
        border: Border.all(
          color: read ? ext.border : ext.accent.withValues(alpha: 0.3),
          width: read ? 1 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: ext.accent.withValues(alpha: read ? 0 : 0.08),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(DesignTokens.space2),
                decoration: BoxDecoration(
                  color: ext.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
                ),
                child: Icon(
                  Icons.campaign_outlined,
                  size: DesignTokens.iconMd,
                  color: read ? ext.textSecondary : ext.accent,
                ),
              ),
              const SizedBox(width: DesignTokens.space3),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: ext.textPrimary,
                    fontWeight: read ? FontWeight.w500 : FontWeight.w700,
                    fontSize: DesignTokens.fontSizeMd,
                  ),
                ),
              ),
              if (createdAt != null)
                Text(
                  '${createdAt!.day}.${createdAt!.month}',
                  style: TextStyle(
                    color: ext.textTertiary,
                    fontSize: DesignTokens.fontSizeXs,
                  ),
                ),
            ],
          ),
          if (body.isNotEmpty) ...[
            const SizedBox(height: DesignTokens.space2),
            Text(
              body,
              style: TextStyle(
                color: ext.textSecondary,
                fontSize: DesignTokens.fontSizeSm,
                height: 1.4,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}
