import 'package:emlakmaster_mobile/features/messages/data/team_chat_push_navigation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parsePayload accepts team_chat FCM data', () {
    final payload = TeamChatPushNavigation.parsePayload({
      'type': 'team_chat',
      'officeId': 'office1',
      'channelId': 'general',
      'title': 'Genel sohbet',
      'subtitle': 'Ofis',
    });
    expect(payload, isNotNull);
    expect(payload!.officeId, 'office1');
    expect(payload.channelId, 'general');
    expect(payload.title, 'Genel sohbet');
  });

  test('parsePayload rejects unknown type', () {
    expect(
      TeamChatPushNavigation.parsePayload({'type': 'other'}),
      isNull,
    );
  });
}
