import 'package:emlakmaster_mobile/features/messages/data/team_chat_inbox_repository.dart';
import 'package:emlakmaster_mobile/features/messages/domain/team_chat_inbox_item.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final teamChatInboxProvider =
    StreamProvider.autoDispose.family<List<TeamChatInboxItem>, String>(
  (ref, userId) => TeamChatInboxRepository.watchInbox(userId),
);
