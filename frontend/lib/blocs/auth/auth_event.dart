import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();
  @override
  List<Object?> get props => [];
}

class CheckAuthStatus extends AuthEvent {}

class LoginRequested extends AuthEvent {
  final String username;
  final String password;
  const LoginRequested(this.username, this.password);
  @override
  List<Object?> get props => [username, password];
}

class LogoutRequested extends AuthEvent {}

/// Disparado cuando el backend responde 401 en algún endpoint (token
/// expirado): limpia la sesión y vuelve al login con un aviso.
class SessionExpired extends AuthEvent {}