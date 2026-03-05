import 'dart:convert';
import 'package:hive/hive.dart';

// API cache using Hive.
class ApiCacheService {
  static const String boxName = 'api_cache_box';
  static const String _timestampPrefix = '__ts__';

  static Box? _box;

  // Must be called once at app startup after Hive.initFlutter()
  static Future<void> init() async {
    _box = await Hive.openBox(boxName);
  }

  static Box get _cacheBox {
    assert(_box != null, 'ApiCacheService.init() must be called first');
    return _box!;
  }

  // Stores a JSON-encodable value with an expiry duration.
  static Future<void> put(
    String key,
    dynamic value, {
    Duration ttl = const Duration(minutes: 30),
  }) async {
    final encoded = jsonEncode(value);
    final expiresAt = DateTime.now().add(ttl).millisecondsSinceEpoch;
    await _cacheBox.put(key, encoded);
    await _cacheBox.put('$_timestampPrefix$key', expiresAt);
  }

  /// Retrieves a cached value if it exists and hasn't expired.Returns null if missing or expired.

  static T? get<T>(String key) {
    final raw = _cacheBox.get(key);
    if (raw == null) return null;

    final expiresAt = _cacheBox.get('$_timestampPrefix$key') as int?;
    if (expiresAt == null || DateTime.now().millisecondsSinceEpoch > expiresAt) {
      // Expired — clean up
      _cacheBox.delete(key);
      _cacheBox.delete('$_timestampPrefix$key');
      return null;
    }

    try {
      final decoded = jsonDecode(raw as String);
      return decoded as T;
    } catch (_) {
      return null;
    }
  }

  static bool has(String key) => get(key) != null;

  /// Removes a specific cache entry.
  static Future<void> remove(String key) async {
    await _cacheBox.delete(key);
    await _cacheBox.delete('$_timestampPrefix$key');
  }

  /// Clears all cached data.
  static Future<void> clearAll() async {
    await _cacheBox.clear();
  }
}
