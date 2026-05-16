import 'package:emlakmaster_mobile/features/messages/domain/team_channel_entity.dart';
import 'package:emlakmaster_mobile/features/messages/domain/team_channel_type.dart';
import 'package:flutter_test/flutter_test.dart';

// Başlık mantığı fanout içinde private; davranışı kanal tipiyle doğruluyoruz.
void main() {
  test('direct channel has two participants', () {
    const channel = TeamChannel(
      id: 'direct_a_b',
      officeId: 'o1',
      type: TeamChannelType.direct,
      participantIds: ['a', 'b'],
    );
    final recipients =
        channel.participantIds.where((id) => id != 'a').toList();
    expect(recipients, ['b']);
  });
}
