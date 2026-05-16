import 'package:emlakmaster_mobile/features/auth/data/user_repository.dart';

/// Ekip listesi için kullanıcı profilleri — tekrarlayan `getUserDoc` çağrılarını azaltır.
class UserProfileCache {
  UserProfileCache._();

  static final UserProfileCache instance = UserProfileCache._();

  static const Duration _ttl = Duration(minutes: 12);
  static const int _maxEntries = 256;
  static const int _fetchChunkSize = 24;

  final Map<String, _Entry> _cache = {};

  Future<Map<String, UserDoc?>> getMany(Iterable<String> uids) async {
    final unique = uids.toSet().toList();
    if (unique.isEmpty) return const {};

    final now = DateTime.now();
    final result = <String, UserDoc?>{};
    final missing = <String>[];

    for (final uid in unique) {
      final entry = _cache[uid];
      if (entry != null && now.difference(entry.fetchedAt) < _ttl) {
        result[uid] = entry.doc;
      } else {
        missing.add(uid);
      }
    }

    for (var i = 0; i < missing.length; i += _fetchChunkSize) {
      final chunk = missing.skip(i).take(_fetchChunkSize).toList();
      final docs = await Future.wait(chunk.map(UserRepository.getUserDoc));
      for (var j = 0; j < chunk.length; j++) {
        _put(chunk[j], docs[j]);
        result[chunk[j]] = docs[j];
      }
    }

    _evictIfNeeded();
    return result;
  }

  void invalidate(String uid) => _cache.remove(uid);

  void clear() => _cache.clear();

  void _put(String uid, UserDoc? doc) {
    _cache[uid] = _Entry(doc: doc, fetchedAt: DateTime.now());
  }

  void _evictIfNeeded() {
    if (_cache.length <= _maxEntries) return;
    final sorted = _cache.entries.toList()
      ..sort((a, b) => a.value.fetchedAt.compareTo(b.value.fetchedAt));
    final removeCount = _cache.length - _maxEntries;
    for (var i = 0; i < removeCount; i++) {
      _cache.remove(sorted[i].key);
    }
  }
}

class _Entry {
  _Entry({required this.doc, required this.fetchedAt});

  final UserDoc? doc;
  final DateTime fetchedAt;
}
