import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emlakmaster_mobile/core/services/firestore_service.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Bildirim merkezi: in-app bildirimler, champion boş durum.
class NotificationsCenterPage extends ConsumerWidget {
  const NotificationsCenterPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = ref.watch(currentUserProvider.select((v) => v.valueOrNull?.uid ?? ''));
    return Scaffold(
      backgroundColor: DesignTokens.backgroundDark,
      appBar: AppBar(
        backgroundColor: DesignTokens.backgroundDark,
        foregroundColor: DesignTokens.textPrimaryDark,
        elevation: 0,
        title: const Text(
          'Bildirimler',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
      ),
      body: uid.isEmpty
          ? const _ChampionEmptyState(
              icon: Icons.notifications_none_rounded,
              title: 'Giriş yapılmamış',
              subtitle: 'Bildirimleri görmek için giriş yapın.',
            )
          : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirestoreService.notificationsByUserStream(uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData) {
                  return const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 32,
                          height: 32,
                          child: CircularProgressIndicator(
                            color: DesignTokens.primary,
                            strokeWidth: 2,
                          ),
                        ),
                        SizedBox(height: DesignTokens.space4),
                        Text(
                          'Bildirimler yükleniyor...',
                          style: TextStyle(
                            color: DesignTokens.textSecondaryDark,
                            fontSize: DesignTokens.fontSizeSm,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return const _ChampionEmptyState(
                    icon: Icons.notifications_rounded,
                    title: 'Henüz bildirim yok',
                    subtitle:
                        'Sıcak lead, görev hatırlatması ve güncellemeler burada görünecek.',
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: DesignTokens.space6,
                    vertical: DesignTokens.space4,
                  ),
                  itemCount: docs.length,
                  cacheExtent: 300,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final d = doc.data();
                    final title = d['title'] as String? ?? 'Bildirim';
                    final body = d['body'] as String? ?? '';
                    final createdAt =
                        (d['createdAt'] as Timestamp?)?.toDate();
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
    return Container(
      margin: const EdgeInsets.only(bottom: DesignTokens.space3),
      padding: const EdgeInsets.all(DesignTokens.space4),
      decoration: BoxDecoration(
        color: read
            ? DesignTokens.surfaceDark
            : DesignTokens.surfaceDark.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
        border: Border.all(
          color: read
              ? DesignTokens.borderDark
              : DesignTokens.primary.withValues(alpha: 0.3),
          width: read ? 1 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: DesignTokens.primary.withValues(alpha: read ? 0 : 0.08),
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
                  color: DesignTokens.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
                ),
                child: const Icon(
                  Icons.campaign_rounded,
                  size: 18,
                  color: DesignTokens.primary,
                ),
              ),
              const SizedBox(width: DesignTokens.space3),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: DesignTokens.textPrimaryDark,
                    fontWeight: read ? FontWeight.w500 : FontWeight.w700,
                    fontSize: DesignTokens.fontSizeMd,
                  ),
                ),
              ),
              if (createdAt != null)
                Text(
                  '${createdAt!.day}.${createdAt!.month}',
                  style: const TextStyle(
                    color: DesignTokens.textTertiaryDark,
                    fontSize: 11,
                  ),
                ),
            ],
          ),
          if (body.isNotEmpty) ...[
            const SizedBox(height: DesignTokens.space2),
            Text(
              body,
              style: const TextStyle(
                color: DesignTokens.textSecondaryDark,
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

class _ChampionEmptyState extends StatelessWidget {
  const _ChampionEmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.space8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(DesignTokens.space6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    DesignTokens.primary.withValues(alpha: 0.2),
                    DesignTokens.accent.withValues(alpha: 0.1),
                  ],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: DesignTokens.primary.withValues(alpha: 0.2),
                    blurRadius: 24,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                icon,
                size: 56,
                color: DesignTokens.primary.withValues(alpha: 0.9),
              ),
            ),
            const SizedBox(height: DesignTokens.space6),
            Text(
              title,
              style: const TextStyle(
                color: DesignTokens.textPrimaryDark,
                fontWeight: FontWeight.w800,
                fontSize: DesignTokens.fontSizeXl,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: DesignTokens.space2),
            Text(
              subtitle,
              style: const TextStyle(
                color: DesignTokens.textSecondaryDark,
                fontSize: DesignTokens.fontSizeSm,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
