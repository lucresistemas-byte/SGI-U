import 'package:flutter_bloc/flutter_bloc.dart';
import 'auth_event.dart';
import 'auth_state.dart';
import '../../services/api_service.dart';
import '../../services/discovery_service.dart';
import '../../services/storage_service.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final ApiService _apiService = ApiService();
  final StorageService _storageService = StorageService();

  AuthBloc() : super(AuthInitial()) {
    on<CheckAuthStatus>(_onCheckAuthStatus);
    on<LoginRequested>(_onLoginRequested);
    on<LogoutRequested>(_onLogoutRequested);
  }

  Future<void> _onCheckAuthStatus(
      CheckAuthStatus event, Emitter<AuthState> emit) async {
    final token = await _storageService.getToken();
    if (token != null && token.isNotEmpty) {
      emit(Authenticated(token));
      _apiService.setAuthToken(token);
    } else {
      emit(Unauthenticated());
    }
  }

  Future<void> _onLoginRequested(
      LoginRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final response = await _apiService.login(event.username, event.password);
      
      final token = response['token']; 
      
      if (token != null && token.isNotEmpty) {
        await _storageService.saveToken(token);
        _apiService.setAuthToken(token);
        
        // L4.1 & L6.2: Save the current backend URL after successful login
        // Only save if URL is valid (non-null, non-empty)
        final currentUrl = _apiService.baseUrl;
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
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onLogoutRequested(
      LogoutRequested event, Emitter<AuthState> emit) async {
    await _storageService.deleteToken();
    _apiService.clearAuthToken();
    emit(Unauthenticated());
  }
}