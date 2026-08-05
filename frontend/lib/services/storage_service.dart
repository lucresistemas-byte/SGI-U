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
    return _storage.read(key: _backendUrlKey);
  }

  Future<void> saveBackendUrl(String url) async {
    if (url.isEmpty) return; // Don't save empty URLs
    await _storage.write(key: _backendUrlKey, value: url);
  }

  // Backend service name management
  Future<String?> getBackendServiceName() async {
    return _storage.read(key: _backendServiceNameKey);
  }

  Future<void> saveBackendServiceName(String? serviceName) async {
    if (serviceName == null || serviceName.isEmpty) {
      await _storage.delete(key: _backendServiceNameKey);
      return;
    }
    await _storage.write(key: _backendServiceNameKey, value: serviceName);
  }

  // Clear all backend-related data (except token)
  Future<void> clearBackendData() async {
    await _storage.delete(key: _backendUrlKey);
    await _storage.delete(key: _backendServiceNameKey);
  }
}
