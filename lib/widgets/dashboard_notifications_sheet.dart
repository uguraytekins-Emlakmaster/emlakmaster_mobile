import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emlakmaster_mobile/core/router/app_router.dart';
import 'package:emlakmaster_mobile/core/services/firestore_service.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
/// Üst bardaki bildirim ikonu: konu = bildirimler → kısa önizleme paneli (tam sayfa değil).
void showDashboardNotificationsSheet(BuildContext context, {required String uid}) {
  final theme = Theme.of(context);
  final isDark = theme.brightness == Brightness.dark;
  final surface = isDark ? AppThemeExtension.of(context).surface : AppThemeExtension.of(context).surface;
  final fg = theme.colorScheme.onSurface;

  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(DesignTokens.radiusLg)),
    ),
    builder: (ctx) {
      return DraggableScrollableSheet(
        initialChildSize: 0.45,
        minChildSize: 0.3,
        maxChildSize: 0.85,
        expand: false,
        builder: (_, scroll) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 12, 8),
                child: Row(
                  children: [
                    Icon(Icons.notifications_active_rounded, color: AppThemeExtension.of(context).accent, size: 22),
                    const SizedBox(width: 10),
                    Text(
                      'Bildirimler',
                      style: TextStyle(
                        color: fg,
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: Icon(Icons.close_rounded, color: fg.withValues(alpha: 0.6)),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Son güncellemeler',
                  style: TextStyle(color: fg.withValues(alpha: 0.55), fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: uid.isEmpty
                    ? Center(
                        child: Text(
                          'Bildirimler için giriş yapın.',
                          style: TextStyle(color: fg.withValues(alpha: 0.7)),
                        ),
                      )
                    : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                        stream: FirestoreService.notificationsByUserStream(uid),
                        builder: (context, snap) {
                          if (snap.connectionState == ConnectionState.waiting && !snap.hasData) {
                            return Center(
                              child: CircularProgressIndicator(color: AppThemeExtension.of(context).accent, strokeWidth: 2),
                            );
                          }
                          final docs = snap.data?.docs ?? [];
                          if (docs.isEmpty) {
                            return ListView(
                              controller: scroll,
                              padding: const EdgeInsets.all(24),
                              children: [
                                Icon(Icons.notifications_none_rounded, size: 48, color: fg.withValues(alpha: 0.25)),
                                const SizedBox(height: 12),
                                Text(
                                  'Henüz bildirim yok',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: fg, fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Lead ve görev bildirimleri burada özetlenir.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: fg.withValues(alpha: 0.65), fontSize: 13),
                                ),
                              ],
                            );
                          }
                          final take = docs.length > 8 ? 8 : docs.length;
                          return ListView.builder(
                            controller: scroll,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: take,
                            itemBuilder: (_, i) {
                              final d = docs[i].data();
                              final title = d['title'] as String? ?? d['body'] as String? ?? 'Bildirim';
                              final body = d['body'] as String? ?? '';
                              return ListTile(
                                contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                                leading: Icon(Icons.circle_notifications_rounded, color: AppThemeExtension.of(context).accent, size: 22),
                                title: Text(title, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: fg, fontWeight: FontWeight.w600, fontSize: 14)),
                                subtitle: body.isNotEmpty
                                    ? Text(body, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: fg.withValues(alpha: 0.65), fontSize: 12))
                                    : null,
                              );
                            },
                          );
                        },
                      ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(20, 8, 20, MediaQuery.paddingOf(ctx).bottom + 16),
                child: FilledButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    context.push(AppRouter.routeNotifications);
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: AppThemeExtension.of(context).accent,
                    foregroundColor: AppThemeExtension.of(context).onBrand,
                    minimumSize: const Size(double.infinity, 48),
                  ),
                  child: const Text('Tüm bildirim merkezi'),
                ),
              ),
            ],
          );
        },
      );
    },
  );
}
