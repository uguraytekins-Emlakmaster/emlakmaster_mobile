import '../domain/integration_platform_id.dart';
import '../domain/platform_setup_record.dart';

/// Yerel kurulum kayıtları — ileride `offices/{id}/platform_setups` ile değiştirilebilir.
class PlatformSetupMemoryStore {
  PlatformSetupMemoryStore._();
  static final PlatformSetupMemoryStore instance = PlatformSetupMemoryStore._();

  final Map<String, PlatformSetupRecord> _map = {};

  String _key(String userId, String officeId, IntegrationPlatformId platform) =>
      '$userId|${officeId.isEmpty ? '_' : officeId}|${platform.storageKey}';

  PlatformSetupRecord? get(String userId, String officeId, IntegrationPlatformId platform) {
    return _map[_key(userId, officeId, platform)];
  }

  void upsert(PlatformSetupRecord record) {
    _map[_key(record.ownerUserId, record.officeId, record.platform)] = record;
  }

  void clear(String userId, String officeId, IntegrationPlatformId platform) {
    _map.remove(_key(userId, officeId, platform));
  }
}
