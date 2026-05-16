import 'package:emlakmaster_mobile/features/messages/domain/team_message_entity.dart';
import 'package:emlakmaster_mobile/features/messages/presentation/providers/team_thread_messages_notifier.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('mergeMessages dedupes by id and sorts newest first', () {
    final older = [
      TeamMessage(
        id: 'a',
        senderId: 'u1',
        text: 'old',
        createdAt: DateTime(2024, 1, 1, 10),
      ),
      TeamMessage(
        id: 'b',
        senderId: 'u2',
        text: 'mid',
        createdAt: DateTime(2024, 1, 2, 10),
      ),
    ];
    final live = [
      TeamMessage(
        id: 'b',
        senderId: 'u2',
        text: 'mid updated',
        createdAt: DateTime(2024, 1, 2, 12),
      ),
      TeamMessage(
        id: 'c',
        senderId: 'u1',
        text: 'new',
        createdAt: DateTime(2024, 1, 3, 10),
      ),
    ];

    final merged = TeamThreadMessagesNotifier.mergeMessages(older, live);
    expect(merged.map((m) => m.id), ['c', 'b', 'a']);
    expect(merged[1].text, 'mid updated');
  });
}
