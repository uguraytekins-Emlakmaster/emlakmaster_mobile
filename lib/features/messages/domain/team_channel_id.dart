/// Ofis genel kanalı sabit kimliği.
const String kTeamGeneralChannelId = 'general';

/// İki kullanıcı arası birebir kanal kimliği (sıralı uid).
String teamDirectChannelId(String userIdA, String userIdB) {
  final sorted = [userIdA, userIdB]..sort();
  return 'direct_${sorted[0]}_${sorted[1]}';
}
