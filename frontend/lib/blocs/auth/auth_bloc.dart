import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'auth_event.dart';
import 'auth_state.dart';
import '../../repositories/auth_repository.dart';
import '../../services/api_service.dart';
import '../../services/discovery_service.dart';
import '../../services/storage_service.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;
  final StorageService _storageService;

  AuthBloc({required AuthRepository authRepository, StorageService? storageService})
      : _authRepository = authRepository,
        _storageService = storageService ?? StorageService(),
        super(AuthInitial()) {
    on<CheckAuthStatus>(_onCheckAuthStatus);
    on<LoginRequested>(_onLoginRequested);
    on<LogoutRequested>(_onLogoutRequested);
    on<SessionExpired>(_onSessionExpired);

    // Sesión expirada: el interceptor 401 de ApiService avisa a este bloc.
    ApiService().onSessionExpired = () {
      if (!isClosed) add(SessionExpired());
    };
  }

  Future<void> _onCheckAuthStatus(
      CheckAuthStatus event, Emitter<AuthState> emit) async {
    final token = await _storageService.getToken();
    if (token != null && token.isNotEmpty) {
      if (_isTokenExpired(token)) {
        await _storageService.deleteToken();
        _authRepository.clearAuthToken();
        emit(Unauthenticated());
        return;
      }
      emit(Authenticated(token));
      _authRepository.setAuthToken(token);
    } else {
      emit(Unauthenticated());
    }
  }

  static bool _isTokenExpired(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return false;
      final normalized = base64Url.normalize(parts[1]);
      final payloadString = utf8.decode(base64Url.decode(normalized));
      final payload = jsonDecode(payloadString);
      if (payload is Map && payload.containsKey('exp')) {
        final exp = payload['exp'];
        if (exp is int) {
          final expiryDate = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
          return DateTime.now().isAfter(expiryDate);
        }
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<void> _onLoginRequested(
      LoginRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final response = await _authRepository.login(event.username, event.password);
      
      final token = response['token']; 
      
      if (token != null && token.isNotEmpty) {
        await _storageService.saveToken(token);
        _authRepository.setAuthToken(token);
        
        // L4.1 & L6.2: Save the current backend URL after successful login
        // Only save if URL is valid (non-null, non-empty)
        final currentUrl = _authRepository.baseUrl;
        if (currentUrl.isNotEmpty) {
          await _storageService.saveBackendUrl(currentUrl);
        }

        // L4.1: Save the mDNS service name associated with the backend so the
        // app can remember/reconnect to the same service on next launch.
        await _storageService.saveBackendServiceName(DiscoveryService.serviceType);
        
        emit(Authenticated(token));
      } else {
        emit(const AuthError('Token no recibido del servidor'));
      }
    } catch (e) {
      final message = e.toString();
      if (message.contains('Credenciales incorrectas')) {
        emit(const AuthError('Credenciales incorrectas'));
      } else if (message.startsWith('Exception: ')) {
        emit(AuthError(message.substring('Exception: '.length)));
      } else {
        emit(const AuthError('Error inesperado. Intente nuevamente'));
      }
    }
  }

  Future<void> _onLogoutRequested(
      LogoutRequested event, Emitter<AuthState> emit) async {
    await _storageService.deleteToken();
    _authRepository.clearAuthToken();
    emit(Unauthenticated());
  }

  /// Sesión expirada (401 en endpoints): limpia credenciales y muestra el
  /// login con el aviso. AuthError redirige a LoginScreen (ver StartupDecider).
  Future<void> _onSessionExpired(
      SessionExpired event, Emitter<AuthState> emit) async {
    await _storageService.deleteToken();
    _authRepository.clearAuthToken();
    emit(const AuthError('Su sesión ha expirado. Vuelva a iniciar sesión.'));
  }
}