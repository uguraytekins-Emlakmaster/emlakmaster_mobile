import 'package:emlakmaster_mobile/features/messages/domain/team_channel_entity.dart';
import 'package:emlakmaster_mobile/features/messages/domain/team_channel_id.dart';
import 'package:emlakmaster_mobile/features/messages/domain/team_channel_type.dart';
import 'package:emlakmaster_mobile/features/messages/domain/team_chat_inbox_item.dart';
import 'package:emlakmaster_mobile/features/messages/presentation/providers/team_chat_providers.dart';
import 'package:emlakmaster_mobile/features/office/domain/office_role.dart';

/// Platform filtre şeridi — harici kanallar önizleme; ekip sohbeti yalnızca Tümü.
enum MessagePlatformFilter {
  all,
  whatsapp,
  instagram,
  email,
  messenger,
  phone,
}

extension MessagePlatformFilterLabels on MessagePlatformFilter {
  String get label => switch (this) {
        MessagePlatformFilter.all => 'Tümü',
        MessagePlatformFilter.whatsapp => 'WhatsApp',
        MessagePlatformFilter.instagram => 'Instagram',
        MessagePlatformFilter.email => 'E-posta',
        MessagePlatformFilter.messenger => 'Messenger',
        MessagePlatformFilter.phone => 'Arama',
      };

  bool get isExternalOnly => this != MessagePlatformFilter.all;
}

enum MessageConversationSurface {
  /// Firestore ekip sohbeti — gönderim canlı.
  teamLive,

  /// Harici kanal — bağlantı / altyapı hazır değil.
  externalPreview,
}

enum MessageConversationKind {
  general,
  direct,
  memberStart,
}

/// Mesaj merkezi satır modeli — sahte harici konuşma yok.
class MessageConversationListItem {
  const MessageConversationListItem({
    required this.id,
    required this.kind,
    required this.surface,
    required this.title,
    required this.subtitle,
    required this.preview,
    this.lastMessageAt,
    this.unreadCount = 0,
    this.otherUserId,
    this.channelId,
    this.avatarUrl,
    this.officeId,
  });

  final String id;
  final MessageConversationKind kind;
  final MessageConversationSurface surface;
  final String title;
  final String subtitle;
  final String preview;
  final DateTime? lastMessageAt;
  final int unreadCount;
  final String? otherUserId;
  final String? channelId;
  final String? avatarUrl;
  final String? officeId;

  bool get isTeamLive => surface == MessageConversationSurface.teamLive;
}

class MessageListSummary {
  const MessageListSummary({
    required this.totalConversations,
    required this.unread,
    required this.liveChannels,
  });

  final int totalConversations;
  final int unread;
  final int liveChannels;

  static const empty = MessageListSummary(
    totalConversations: 0,
    unread: 0,
    liveChannels: 0,
  );
}

MessageListSummary computeMessageListSummary({
  required List<MessageConversationListItem> items,
  required List<TeamChatInboxItem> inbox,
}) {
  final teamItems =
      items.where((i) => i.surface == MessageConversationSurface.teamLive);
  final directWithPreview = teamItems
      .where((i) => i.kind == MessageConversationKind.direct)
      .where((i) => i.preview.isNotEmpty && i.preview != 'Birebir mesaj başlat')
      .length;
  final total = directWithPreview + 1;
  final unread = inbox.where((e) => !e.read).length;
  return MessageListSummary(
    totalConversations: total,
    unread: unread,
    liveChannels: 1,
  );
}

int unreadCountForChannel(String channelId, List<TeamChatInboxItem> inbox) {
  return inbox
      .where((e) => e.channelId == channelId && !e.read)
      .length;
}

List<MessageConversationListItem> buildTeamConversationItems({
  required String officeId,
  required String currentUserId,
  required List<TeamChannel> channels,
  required List<TeamMemberProfile> members,
  required List<TeamChatInboxItem> inbox,
}) {
  final out = <MessageConversationListItem>[
    MessageConversationListItem(
      id: 'general',
      kind: MessageConversationKind.general,
      surface: MessageConversationSurface.teamLive,
      title: 'Genel sohbet',
      subtitle: 'Tüm ofis',
      preview: 'Ofis duyuruları ve hızlı koordinasyon',
      channelId: kTeamGeneralChannelId,
      officeId: officeId,
      unreadCount: unreadCountForChannel(kTeamGeneralChannelId, inbox),
    ),
  ];

  final directByOther = <String, TeamChannel>{};
  for (final c in channels) {
    if (c.type != TeamChannelType.direct) continue;
    final other = c.participantIds
        .where((id) => id != currentUserId)
        .cast<String?>()
        .firstOrNull;
    if (other != null) directByOther[other] = c;
  }

  for (final channel in directByOther.values) {
    if ((channel.lastMessageText ?? '').isEmpty) continue;
    final otherId = channel.participantIds
        .where((id) => id != currentUserId)
        .cast<String?>()
        .firstOrNull;
    final profile = otherId == null
        ? null
        : members.where((m) => m.membership.userId == otherId).firstOrNull;
    out.add(
      MessageConversationListItem(
        id: 'ch_${channel.id}',
        kind: MessageConversationKind.direct,
        surface: MessageConversationSurface.teamLive,
        title: profile?.displayName ?? channel.title ?? 'Sohbet',
        subtitle: profile != null
            ? officeRoleLabel(profile.membership.role)
            : 'Birebir',
        preview: channel.lastMessageText ?? '',
        lastMessageAt: channel.lastMessageAt,
        unreadCount: unreadCountForChannel(channel.id, inbox),
        otherUserId: otherId,
        channelId: channel.id,
        avatarUrl: profile?.avatarUrl,
        officeId: officeId,
      ),
    );
  }

  out.sort((a, b) {
    if (a.kind == MessageConversationKind.general) return -1;
    if (b.kind == MessageConversationKind.general) return 1;
    final at = a.lastMessageAt;
    final bt = b.lastMessageAt;
    if (at == null && bt == null) return 0;
    if (at == null) return 1;
    if (bt == null) return -1;
    return bt.compareTo(at);
  });

  for (final profile in members) {
    final uid = profile.membership.userId;
    if (directByOther.containsKey(uid)) continue;
    out.add(
      MessageConversationListItem(
        id: 'member_$uid',
        kind: MessageConversationKind.memberStart,
        surface: MessageConversationSurface.teamLive,
        title: profile.displayName,
        subtitle: officeRoleLabel(profile.membership.role),
        preview: 'Birebir mesaj başlat',
        otherUserId: uid,
        channelId: teamDirectChannelId(currentUserId, uid),
        avatarUrl: profile.avatarUrl,
        officeId: officeId,
      ),
    );
  }

  return out;
}

bool matchesMessageSearch(MessageConversationListItem item, String query) {
  if (query.isEmpty) return true;
  final q = query.toLowerCase();
  bool hit(String? s) => s != null && s.toLowerCase().contains(q);
  return hit(item.title) ||
      hit(item.subtitle) ||
      hit(item.preview);
}

List<MessageConversationListItem> filterTeamConversations(
  List<MessageConversationListItem> items,
  String searchQuery,
) {
  return items
      .where((i) => matchesMessageSearch(i, searchQuery))
      .toList(growable: false);
}

String officeRoleLabel(OfficeRole role) {
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
