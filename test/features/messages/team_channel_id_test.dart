import 'package:emlakmaster_mobile/features/messages/domain/team_channel_id.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('teamDirectChannelId is stable regardless of argument order', () {
    expect(
      teamDirectChannelId('user_b', 'user_a'),
      teamDirectChannelId('user_a', 'user_b'),
    );
    expect(
      teamDirectChannelId('user_a', 'user_b'),
      'direct_user_a_user_b',
    );
  });
}
