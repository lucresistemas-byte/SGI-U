import '../services/api_service.dart';

class AuthRepository {
  final ApiService _apiService;

  AuthRepository({ApiService? apiService}) : _apiService = apiService ?? ApiService();

  Future<Map<String, dynamic>> login(String username, String password) {
    return _apiService.login(username, password);
  }

  /// A2: cambio de contraseña obligatorio; el backend devuelve un token nuevo.
  Future<Map<String, dynamic>> cambiarPassword(
      String passwordActual, String passwordNueva) {
    return _apiService.cambiarPassword(passwordActual, passwordNueva);
  }

  void setAuthToken(String token) {
    _apiService.setAuthToken(token);
  }

  void clearAuthToken() {
    _apiService.clearAuthToken();
  }

  String get baseUrl => _apiService.baseUrl;
}
