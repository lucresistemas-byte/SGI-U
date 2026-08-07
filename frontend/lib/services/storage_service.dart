import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class StorageService {
  static const String _backendUrlKey = 'backend_url';
  static const String _backendServiceNameKey = 'backend_service_name';
  static const String _tokenKey = 'jwt_token';

  final FlutterSecureStorage _storage;

  StorageService({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  // Token management
  Future<String?> getToken() async {
    return _storage.read(key: _tokenKey);
  }

  Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  Future<void> deleteToken() async {
    await _storage.delete(key: _tokenKey);
  }

  // Backend URL management
  Future<String?> getBackendUrl() async {
    final url = await _storage.read(key: _backendUrlKey);
    // Return null if empty string (treat as not saved)
    return (url != null && url.isNotEmpty) ? url : null;
  }

  /// Saves backend URL only if it's valid (non-null, non-empty after trim).
  /// L6.2: Validation to prevent storing invalid URLs
  Future<void> saveBackendUrl(String? url) async {
    final trimmed = url?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return; // Don't save empty, null or whitespace-only URLs
    }
    await _storage.write(key: _backendUrlKey, value: trimmed);
  }

  // Backend service name management
  Future<String?> getBackendServiceName() async {
    final name = await _storage.read(key: _backendServiceNameKey);
    // Return null if empty string (treat as not saved)
    return (name != null && name.isNotEmpty) ? name : null;
  }

  /// Saves backend service name only if it's valid (non-null, non-empty).
  /// L6.2: Validation to prevent storing invalid service names.
  /// If name is null or empty after trim, deletes the saved value (treat as not available).
  Future<void> saveBackendServiceName(String? serviceName) async {
    final trimmed = serviceName?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      // Delete if invalid instead of saving empty string
      await _storage.delete(key: _backendServiceNameKey);
      return;
    }
    await _storage.write(key: _backendServiceNameKey, value: trimmed);
  }

  // Clear all backend-related data (except token)
  Future<void> clearBackendData() async {
    await _storage.delete(key: _backendUrlKey);
    await _storage.delete(key: _backendServiceNameKey);
  }
}
