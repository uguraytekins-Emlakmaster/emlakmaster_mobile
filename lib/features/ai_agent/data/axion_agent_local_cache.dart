import '../domain/axion_agent_policy.dart';

/// Bellek içi, TTL'li, LRU benzeri yerel önbellek (V1).
///
/// Disk/Firestore yazımı YOK — sıfır maliyet, sıfır ağ.
/// Kalıcı önbellek ileride mevcut mimari izin verirse eklenebilir.
class AxionAgentLocalCache {
  AxionAgentLocalCache({
    this.maxEntries = AxionAgentPolicy.maxCacheEntries,
    this.ttl = AxionAgentPolicy.cacheTtl,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final int maxEntries;
  final Duration ttl;
  final DateTime Function() _clock;

  final _entries = <String, _CacheEntry>{};

  T? get<T>(String key) {
    final entry = _entries[key];
    if (entry == null) return null;
    if (_clock().isAfter(entry.expiresAt)) {
      _entries.remove(key);
      return null;
    }
    // LRU: erişilen anahtarı sona taşı.
    _entries.remove(key);
    _entries[key] = entry;
    return entry.value as T?;
  }

  void put(String key, Object value) {
    _entries.remove(key);
    if (_entries.length >= maxEntries) {
      // En eski (ilk) girişi at.
      _entries.remove(_entries.keys.first);
    }
    _entries[key] = _CacheEntry(value, _clock().add(ttl));
  }

  bool contains(String key) => get<Object>(key) != null;

  void invalidate(String key) => _entries.remove(key);

  void clear() => _entries.clear();

  int get length => _entries.length;
}

class _CacheEntry {
  _CacheEntry(this.value, this.expiresAt);
  final Object value;
  final DateTime expiresAt;
}
