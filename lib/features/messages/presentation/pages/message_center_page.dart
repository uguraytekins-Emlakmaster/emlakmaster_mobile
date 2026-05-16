import 'package:emlakmaster_mobile/core/copy/product_labels.dart';
import 'package:emlakmaster_mobile/core/feedback/app_feedback.dart';
import 'package:emlakmaster_mobile/core/router/app_router.dart';
import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:emlakmaster_mobile/features/messages/data/team_chat_repository.dart';
import 'package:emlakmaster_mobile/features/messages/domain/team_channel_entity.dart';
import 'package:emlakmaster_mobile/features/messages/domain/team_channel_id.dart';
import 'package:emlakmaster_mobile/features/messages/domain/team_channel_type.dart';
import 'package:emlakmaster_mobile/features/messages/presentation/providers/team_chat_providers.dart';
import 'package:emlakmaster_mobile/features/office/domain/office_role.dart';
import 'package:emlakmaster_mobile/shared/widgets/app_back_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
/// Mesaj merkezi — ofis ekibi ile anlık sohbet; harici platformlar sonra eklenecek.
class MessageCenterPage extends ConsumerStatefulWidget {
  const MessageCenterPage({super.key});

  @override
  ConsumerState<MessageCenterPage> createState() => _MessageCenterPageState();
}

class _MessageCenterPageState extends ConsumerState<MessageCenterPage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final ext = AppThemeExtension.of(context);
    final officeId = ref.watch(teamChatOfficeIdProvider);
    final uid = ref.watch(currentUserProvider).valueOrNull?.uid;

    ref.listen(teamGeneralChannelReadyProvider, (_, __) {});

    if (officeId == null || uid == null) {
      return Scaffold(
        backgroundColor: ext.background,
        body: SafeArea(
          child: Column(
            children: [
              _header(context, ext),
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'Ekip mesajlaşması için önce bir ofise bağlanmanız gerekir.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: ext.foregroundSecondary, height: 1.4),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final channelsAsync = ref.watch(teamChannelsProvider);
    final membersAsync = ref.watch(officeTeamMemberProfilesProvider);

    return Scaffold(
      backgroundColor: ext.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _header(context, ext)),
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: _InfoBanner(
                  icon: Icons.groups_rounded,
                  text:
                      'Ofis ekibinizle anlık mesajlaşın. Mesajlar Firestore üzerinden canlı senkronize edilir.',
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                child: Text(
                  'GENEL',
                  style: TextStyle(
                    color: ext.foregroundMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _ConversationRow(
                  title: 'Genel sohbet',
                  subtitle: 'Tüm ofis',
                  preview: 'Ofis duyuruları ve hızlı koordinasyon',
                  icon: Icons.campaign_rounded,
                  onTap: () => _openChannel(
                    context,
                    ref,
                    officeId: officeId,
                    channelId: kTeamGeneralChannelId,
                    title: 'Genel sohbet',
                    subtitle: 'Tüm ofis',
                    ensure: () => TeamChatRepository.ensureGeneralChannel(officeId),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                child: Text(
                  'EKİP ÜYELERİ',
                  style: TextStyle(
                    color: ext.foregroundMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                  ),
                ),
              ),
            ),
            membersAsync.when(
              loading: () => const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
              error: (e, _) => SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text('Ekip listesi yüklenemedi: $e',
                      style: TextStyle(color: ext.danger)),
                ),
              ),
              data: (members) {
                if (members.isEmpty) {
                  return SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        'Aktif başka ekip üyesi yok.',
                        style: TextStyle(color: ext.foregroundMuted, fontSize: 13),
                      ),
                    ),
                  );
                }
                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final profile = members[index];
                      final roleLabel = _officeRoleLabel(profile.membership.role);
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                        child: _ConversationRow(
                          title: profile.displayName,
                          subtitle: roleLabel,
                          preview: 'Birebir mesaj başlat',
                          icon: Icons.person_rounded,
                          imageUrl: profile.avatarUrl,
                          onTap: () => _openDirect(
                            context,
                            ref,
                            officeId: officeId,
                            currentUserId: uid,
                            otherUserId: profile.membership.userId,
                            title: profile.displayName,
                            subtitle: roleLabel,
                          ),
                        ),
                      );
                    },
                    childCount: members.length,
                  ),
                );
              },
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Text(
                  'SON KONUŞMALAR',
                  style: TextStyle(
                    color: ext.foregroundMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                  ),
                ),
              ),
            ),
            channelsAsync.when(
              loading: () => const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
              error: (e, _) => SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text('Konuşmalar yüklenemedi: $e',
                      style: TextStyle(color: ext.danger)),
                ),
              ),
              data: (channels) {
                final direct = channels
                    .where((c) => c.type == TeamChannelType.direct)
                    .where((c) => (c.lastMessageText ?? '').isNotEmpty)
                    .toList();
                if (direct.isEmpty) {
                  return SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                      child: Text(
                        'Henüz birebir mesaj yok.',
                        style: TextStyle(color: ext.foregroundMuted, fontSize: 13),
                      ),
                    ),
                  );
                }
                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final channel = direct[index];
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                        child: _ChannelRow(
                          channel: channel,
                          currentUserId: uid,
                          membersAsync: membersAsync,
                          onTap: () => _openExistingChannel(
                            context,
                            channel: channel,
                            currentUserId: uid,
                            membersAsync: membersAsync,
                          ),
                        ),
                      );
                    },
                    childCount: direct.length,
                  ),
                );
              },
            ),
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(20, 24, 20, 32),
                child: _InfoBanner(
                  icon: Icons.hub_outlined,
                  muted: true,
                  text:
                      'Sahibinden ve diğer platform mesajları sonraki aşamada buraya eklenecek.',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header(BuildContext context, AppThemeExtension ext) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 12),
      child: Row(
        children: [
          if (context.canPop()) const AppBackButton(),
          Expanded(
            child: Text(
              ProductLabels.messageCenter,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: ext.foreground,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  static Future<void> _openChannel(
    BuildContext context,
    WidgetRef ref, {
    required String officeId,
    required String channelId,
    required String title,
    required String subtitle,
    required Future<void> Function() ensure,
  }) async {
    AppFeedback.lightImpact();
    try {
      await ensure();
      if (!context.mounted) return;
      context.push(
        AppRouter.routeMessageThread,
        extra: <String, dynamic>{
          'officeId': officeId,
          'channelId': channelId,
          'title': title,
          'subtitle': subtitle,
        },
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sohbet açılamadı: $e')),
        );
      }
    }
  }

  static Future<void> _openDirect(
    BuildContext context,
    WidgetRef ref, {
    required String officeId,
    required String currentUserId,
    required String otherUserId,
    required String title,
    required String subtitle,
  }) async {
    await _openChannel(
      context,
      ref,
      officeId: officeId,
      channelId: teamDirectChannelId(currentUserId, otherUserId),
      title: title,
      subtitle: subtitle,
      ensure: () => TeamChatRepository.ensureDirectChannel(
        officeId: officeId,
        currentUserId: currentUserId,
        otherUserId: otherUserId,
      ),
    );
  }

  static void _openExistingChannel(
    BuildContext context, {
    required TeamChannel channel,
    required String currentUserId,
    required AsyncValue<List<TeamMemberProfile>> membersAsync,
  }) {
    AppFeedback.lightImpact();
    final otherId = channel.participantIds
        .where((id) => id != currentUserId)
        .cast<String?>()
        .firstOrNull;
    var title = channel.title ?? 'Sohbet';
    var subtitle = 'Birebir';
    if (otherId != null && membersAsync.hasValue) {
      final match = membersAsync.value!
          .where((p) => p.membership.userId == otherId)
          .firstOrNull;
      if (match != null) {
        title = match.displayName;
        subtitle = _officeRoleLabel(match.membership.role);
      }
    }
    context.push(
      AppRouter.routeMessageThread,
      extra: <String, dynamic>{
        'officeId': channel.officeId,
        'channelId': channel.id,
        'title': title,
        'subtitle': subtitle,
      },
    );
  }
}

String _officeRoleLabel(OfficeRole role) {
  switch (role) {
    case OfficeRole.owner:
      return 'Sahip';
    case OfficeRole.admin:
      return 'Yönetici';
    case OfficeRole.manager:
      return 'Müdür';
    case OfficeRole.consultant:
      return 'Danışman';
  }
}

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull {
    final it = iterator;
    if (it.moveNext()) return it.current;
    return null;
  }
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({
    required this.icon,
    required this.text,
    this.muted = false,
  });

  final IconData icon;
  final String text;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    return Container(
      padding: const EdgeInsets.all(DesignTokens.space4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
        color: muted ? ext.surface : ext.surfaceElevated,
        border: Border.all(color: ext.border.withValues(alpha: 0.55)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: ext.foregroundMuted, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: ext.foregroundSecondary,
                height: 1.4,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConversationRow extends StatelessWidget {
  const _ConversationRow({
    required this.title,
    required this.subtitle,
    required this.preview,
    required this.icon,
    required this.onTap,
    this.imageUrl,
  });

  final String title;
  final String subtitle;
  final String preview;
  final IconData icon;
  final VoidCallback onTap;
  final String? imageUrl;

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
          ),
          padding: const EdgeInsets.all(DesignTokens.space4),
          child: Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: scheme.primary.withValues(alpha: 0.15),
                backgroundImage:
                    imageUrl != null && imageUrl!.isNotEmpty ? NetworkImage(imageUrl!) : null,
                child: imageUrl == null || imageUrl!.isEmpty
                    ? Icon(icon, color: scheme.primary)
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: ext.foreground,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(color: ext.foregroundMuted, fontSize: 12),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      preview,
                      style: TextStyle(
                        color: ext.foregroundSecondary,
                        fontSize: 13,
                        height: 1.35,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: ext.foregroundMuted),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChannelRow extends StatelessWidget {
  const _ChannelRow({
    required this.channel,
    required this.currentUserId,
    required this.membersAsync,
    required this.onTap,
  });

  final TeamChannel channel;
  final String currentUserId;
  final AsyncValue<List<TeamMemberProfile>> membersAsync;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final otherId = channel.participantIds
        .where((id) => id != currentUserId)
        .cast<String?>()
        .firstOrNull;
    var title = 'Sohbet';
    var subtitle = '';
    if (otherId != null && membersAsync.hasValue) {
      final match = membersAsync.value!
          .where((p) => p.membership.userId == otherId)
          .firstOrNull;
      if (match != null) {
        title = match.displayName;
        subtitle = _officeRoleLabel(match.membership.role);
      }
    }
    final preview = channel.lastMessageText ?? '';
    return _ConversationRow(
      title: title,
      subtitle: subtitle,
      preview: preview.isEmpty ? 'Mesaj yok' : preview,
      icon: Icons.chat_bubble_outline_rounded,
      onTap: onTap,
    );
  }
}
