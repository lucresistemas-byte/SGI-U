import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'auth_event.dart';
import 'auth_state.dart';
import '../../services/api_service.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final ApiService _apiService = ApiService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  static const String _tokenKey = 'jwt_token';

  AuthBloc() : super(AuthInitial()) {
    on<CheckAuthStatus>(_onCheckAuthStatus);
    on<LoginRequested>(_onLoginRequested);
    on<LogoutRequested>(_onLogoutRequested);
  }

  Future<void> _onCheckAuthStatus(
      CheckAuthStatus event, Emitter<AuthState> emit) async {
    String? token;
    try {
      token = await _storage.read(key: _tokenKey);
    } catch (_) {
      // Sin keyring disponible: no se puede conservar la sesión.
      token = null;
    }

    if (token == null || token.isEmpty) {
      emit(Unauthenticated());
      return;
    }

    _apiService.setAuthToken(token);

    // Validamos el token contra el backend en lugar de confiar solo en que
    // exista. Un JWT caducado o inválido borra la sesión y vuelve al login.
    bool isValid = false;
    try {
      isValid = await _apiService.validateToken();
    } catch (_) {
      // Backend inalcanzable: no confirmamos la sesión, volvemos al login.
      isValid = false;
    }

    if (isValid) {
      emit(Authenticated(token));
    } else {
      await _storage.delete(key: _tokenKey);
      _apiService.clearAuthToken();
      emit(Unauthenticated());
    }
  }

  Future<void> _onLoginRequested(
      LoginRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final response = await _apiService.login(event.username, event.password);
      
      // CORRECCIÓN: Usamos 'token' porque así aparece en el JSON de respuesta del servidor
      final token = response['token']; 
      
      if (token != null && token.isNotEmpty) {
        await _storage.write(key: _tokenKey, value: token);
        _apiService.setAuthToken(token);
        emit(Authenticated(token));
      } else {
        emit(const AuthError('Token no recibido del servidor'));
      }
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onLogoutRequested(
      LogoutRequested event, Emitter<AuthState> emit) async {
    await _storage.delete(key: _tokenKey);
    _apiService.clearAuthToken();
    emit(Unauthenticated());
  }
}