/// Açık sohbet kanalı — aynı kanalda FCM ön plan bildirimini bastırmak için.
class TeamChatPresence {
  TeamChatPresence._();

  static String? _officeId;
  static String? _channelId;

  static void setActive({
    required String officeId,
    required String channelId,
  }) {
    _officeId = officeId;
    _channelId = channelId;
  }

  static void clearActive() {
    _officeId = null;
    _channelId = null;
  }

  static bool isViewing({
    required String officeId,
    required String channelId,
  }) {
    return _officeId == officeId && _channelId == channelId;
  }
}
