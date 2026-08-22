import '../services/api_service.dart';

class AuthRepository {
  final ApiService _apiService;

  AuthRepository({ApiService? apiService}) : _apiService = apiService ?? ApiService();

  Future<Map<String, dynamic>> login(String username, String password) {
    return _apiService.login(username, password);
  }

  void setAuthToken(String token) {
    _apiService.setAuthToken(token);
  }

  void clearAuthToken() {
    _apiService.clearAuthToken();
  }

  String get baseUrl => _apiService.baseUrl;
}
