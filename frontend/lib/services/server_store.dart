import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Entrada de la caché del backend (C.3.9): URL + momento de guardado.
class ServerCacheEntry {
  final String url;
  final DateTime savedAt;

  const ServerCacheEntry({required this.url, required this.savedAt});
}

/// C.3.9: persiste la URL del backend con un timestamp para poder aplicar
/// una política de TTL antes de confiar en la caché.
class ServerStore {
  static const String _cacheKey = 'server_cache';

  /// Tiempo máximo de confianza en la URL persistida.
  static const Duration defaultTtl = Duration(hours: 24);

  final FlutterSecureStorage _storage;
  final DateTime Function() _now;

  ServerStore({FlutterSecureStorage? storage, DateTime Function()? now})
      : _storage = storage ?? const FlutterSecureStorage(),
        _now = now ?? DateTime.now;

  /// Lee la caché. Devuelve null si no existe o si el dato está corrupto.
  Future<ServerCacheEntry?> read() async {
    try {
      final raw = await _storage.read(key: _cacheKey);
      if (raw == null || raw.isEmpty) return null;

      final decoded = jsonDecode(raw);
      if (decoded is! Map || decoded['url'] is! String) return null;
      if ((decoded['url'] as String).isEmpty) return null;

      final savedAt = DateTime.tryParse('${decoded['savedAt']}');
      if (savedAt == null) return null;

      return ServerCacheEntry(url: decoded['url'] as String, savedAt: savedAt);
    } catch (_) {
      // JSON corrupto u otro error: tratar como sin caché.
      return null;
    }
  }

  /// Guarda [url] junto con el timestamp actual.
  Future<void> save(String url) async {
    final entry = ServerCacheEntry(url: url, savedAt: _now());
    await _storage.write(
      key: _cacheKey,
      value: jsonEncode({
        'url': entry.url,
        'savedAt': entry.savedAt.toIso8601String(),
      }),
    );
  }

  /// true solo si [entry] existe y tiene menos de [ttl] de antigüedad.
  bool isFresh(ServerCacheEntry? entry, {Duration ttl = defaultTtl}) {
    if (entry == null) return false;
    return _now().difference(entry.savedAt) < ttl;
  }

  Future<void> clear() => _storage.delete(key: _cacheKey);
}
