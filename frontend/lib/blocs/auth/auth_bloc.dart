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
    on<CambiarPasswordRequested>(_onCambiarPasswordRequested);

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
        emit(const Unauthenticated());
        return;
      }
      _authRepository.setAuthToken(token);
      // A2: si el token guardado aún exige el cambio de contraseña, la app
      // vuelve a mostrar la pantalla de cambio antes que el resto.
      if (_requiereCambioPassword(token)) {
        emit(PasswordChangeRequired(token));
        return;
      }
      emit(Authenticated(token));
    } else {
      emit(const Unauthenticated());
    }
  }

  /// A2: lee el reclamo "cambioPassword" del payload del JWT.
  static bool _requiereCambioPassword(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return false;
      final normalized = base64Url.normalize(parts[1]);
      final payloadString = utf8.decode(base64Url.decode(normalized));
      final payload = jsonDecode(payloadString);
      if (payload is Map && payload['cambioPassword'] == true) {
        return true;
      }
      return false;
    } catch (_) {
      return false;
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

        // A2: si el backend pide cambio de contraseña (primer uso con la
        // clave de fábrica), la app muestra la pantalla de cambio antes
        // de entrar al sistema.
        final requiereCambio = response['requiereCambioPassword'] == true;
        if (requiereCambio) {
          emit(PasswordChangeRequired(token));
          return;
        }

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
    emit(const Unauthenticated());
  }

  /// A2: envía el cambio de contraseña y guarda el token nuevo (sin el
  /// reclamo) que devuelve el backend.
  Future<void> _onCambiarPasswordRequested(
      CambiarPasswordRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final response = await _authRepository.cambiarPassword(
          event.passwordActual, event.passwordNueva);
      final token = response['token'];
      if (token == null || token.isEmpty) {
        emit(const AuthError('No se recibió confirmación del servidor'));
        return;
      }
      await _storageService.saveToken(token);
      _authRepository.setAuthToken(token);
      emit(Authenticated(token));
    } catch (e) {
      final message = e.toString().replaceFirst('Exception: ', '');
      emit(AuthError(message.isEmpty ? 'No se pudo cambiar la contraseña' : message));
    }
  }

  /// Sesión expirada (401 en endpoints): limpia credenciales y emite
  /// Unauthenticated con sesionVencida para que LoginScreen muestre el aviso.
  Future<void> _onSessionExpired(
      SessionExpired event, Emitter<AuthState> emit) async {
    await _storageService.deleteToken();
    _authRepository.clearAuthToken();
    emit(const Unauthenticated(sesionVencida: true));
  }
}