import 'package:emlakmaster_mobile/features/messages/domain/team_channel_entity.dart';
import 'package:emlakmaster_mobile/features/messages/domain/team_channel_type.dart';
import 'package:emlakmaster_mobile/features/messages/domain/team_chat_inbox_item.dart';
import 'package:emlakmaster_mobile/features/messages/presentation/utils/message_conversation_list_filter.dart';
import 'package:emlakmaster_mobile/features/office/domain/membership_status.dart';
import 'package:emlakmaster_mobile/features/office/domain/office_membership_entity.dart';
import 'package:emlakmaster_mobile/features/office/domain/office_role.dart';
import 'package:emlakmaster_mobile/features/messages/presentation/providers/team_chat_providers.dart';
import 'package:flutter_test/flutter_test.dart';

OfficeMembership _membership(String uid) => OfficeMembership(
      id: 'm_$uid',
      officeId: 'office1',
      userId: uid,
      role: OfficeRole.consultant,
      status: MembershipStatus.active,
      joinedAt: DateTime(2024, 1, 1),
    );

void main() {
  group('buildTeamConversationItems', () {
    test('includes general and direct with preview', () {
      final items = buildTeamConversationItems(
        officeId: 'office1',
        currentUserId: 'u1',
        channels: [
          TeamChannel(
            id: 'dm1',
            officeId: 'office1',
            type: TeamChannelType.direct,
            participantIds: ['u1', 'u2'],
            lastMessageText: 'Merhaba',
            lastMessageAt: DateTime(2024, 6, 1),
          ),
        ],
        members: [
          TeamMemberProfile(membership: _membership('u2')),
        ],
        inbox: const [],
      );
      expect(items.any((i) => i.kind == MessageConversationKind.general), isTrue);
      expect(items.any((i) => i.preview == 'Merhaba'), isTrue);
    });
  });

  group('computeMessageListSummary', () {
    test('unread from inbox only', () {
      final items = buildTeamConversationItems(
        officeId: 'office1',
        currentUserId: 'u1',
        channels: const [],
        members: const [],
        inbox: const [],
      );
      final summary = computeMessageListSummary(
        items: items,
        inbox: [
          const TeamChatInboxItem(
            id: '1',
            recipientId: 'u1',
            senderId: 'u2',
            officeId: 'office1',
            channelId: 'ch1',
            title: 'T',
            subtitle: '',
            body: 'b',
            read: false,
          ),
        ],
      );
      expect(summary.unread, 1);
    });
  });

  group('external filter honesty', () {
    test('no external items in team builder', () {
      final items = buildTeamConversationItems(
        officeId: 'office1',
        currentUserId: 'u1',
        channels: const [],
        members: const [],
        inbox: const [],
      );
      expect(
        items.every((i) => i.surface == MessageConversationSurface.teamLive),
        isTrue,
      );
    });
  });
}
