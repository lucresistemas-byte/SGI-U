import 'package:equatable/equatable.dart';

abstract class AuthState extends Equatable {
  const AuthState();
  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class Authenticated extends AuthState {
  final String token;
  const Authenticated(this.token);
  @override
  List<Object?> get props => [token];
}

/// Sin sesión. [sesionVencida] es true cuando se llegó acá porque el backend
/// rechazó el token (401), para que LoginScreen avise al usuario.
class Unauthenticated extends AuthState {
  final bool sesionVencida;
  const Unauthenticated({this.sesionVencida = false});
  @override
  List<Object?> get props => [sesionVencida];
}

class AuthError extends AuthState {
  final String message;
  const AuthError(this.message);
  @override
  List<Object?> get props => [message];
}