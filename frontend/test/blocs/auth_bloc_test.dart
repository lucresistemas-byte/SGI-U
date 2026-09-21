import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sgi_u_frontend/blocs/auth/auth_bloc.dart';
import 'package:sgi_u_frontend/blocs/auth/auth_event.dart';
import 'package:sgi_u_frontend/blocs/auth/auth_state.dart';
import 'package:sgi_u_frontend/repositories/auth_repository.dart';
import 'package:sgi_u_frontend/services/storage_service.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AuthBloc - N1 (bloc_test + mocktail)', () {
    late _MockAuthRepository repo;

    setUp(() {
      repo = _MockAuthRepository();
      FlutterSecureStorage.setMockInitialValues({});
    });

    blocTest<AuthBloc, AuthState>(
      'CheckAuthStatus sin token guardado emite Unauthenticated',
      build: () => AuthBloc(authRepository: repo),
      act: (bloc) => bloc.add(CheckAuthStatus()),
      expect: () => [Unauthenticated()],
    );

    blocTest<AuthBloc, AuthState>(
      'CheckAuthStatus con token guardado emite Authenticated y setea el token',
      build: () {
        FlutterSecureStorage.setMockInitialValues({'jwt_token': 'abc123'});
        return AuthBloc(authRepository: repo);
      },
      act: (bloc) => bloc.add(CheckAuthStatus()),
      expect: () => [const Authenticated('abc123')],
      verify: (_) => verify(() => repo.setAuthToken('abc123')).called(1),
    );

    blocTest<AuthBloc, AuthState>(
      'LoginRequested con credenciales válidas emite Authenticated',
      build: () {
        when(() => repo.login('admin', 'secret'))
            .thenAnswer((_) async => {'token': 'tok123'});
        when(() => repo.baseUrl).thenReturn('http://localhost:3000');
        return AuthBloc(authRepository: repo);
      },
      act: (bloc) => bloc.add(const LoginRequested('admin', 'secret')),
      expect: () => [isA<AuthLoading>(), const Authenticated('tok123')],
    );

    blocTest<AuthBloc, AuthState>(
      'LoginRequested con credenciales inválidas emite AuthError limpio',
      build: () {
        when(() => repo.login('admin', 'wrong'))
            .thenThrow(Exception('Credenciales incorrectas'));
        return AuthBloc(authRepository: repo);
      },
      act: (bloc) => bloc.add(const LoginRequested('admin', 'wrong')),
      expect: () =>
          [isA<AuthLoading>(), const AuthError('Credenciales incorrectas')],
    );

    blocTest<AuthBloc, AuthState>(
      'LoginRequested sin token en la respuesta emite AuthError',
      build: () {
        when(() => repo.login('admin', 'secret'))
            .thenAnswer((_) async => <String, dynamic>{});
        return AuthBloc(authRepository: repo);
      },
      act: (bloc) => bloc.add(const LoginRequested('admin', 'secret')),
      expect: () =>
          [isA<AuthLoading>(), const AuthError('Token no recibido del servidor')],
    );
  });

  test('SessionExpired borra el token y emite AuthError de expiración',
      () async {
    FlutterSecureStorage.setMockInitialValues({'jwt_token': 'abc123'});
    final bloc = AuthBloc(authRepository: AuthRepository());

    final futureState = bloc.stream.firstWhere((s) => s is AuthError);
    bloc.add(SessionExpired());
    final state = await futureState;

    expect(state, isA<AuthError>());
    expect((state as AuthError).message,
        'Su sesión ha expirado. Vuelva a iniciar sesión.');
    expect(await StorageService().getToken(), isNull);

    await bloc.close();
  });

  test('LogoutRequested emite Unauthenticated y borra el token', () async {
    FlutterSecureStorage.setMockInitialValues({'jwt_token': 'abc123'});
    final bloc = AuthBloc(authRepository: AuthRepository());

    final futureState = bloc.stream.firstWhere((s) => s is Unauthenticated);
    bloc.add(LogoutRequested());
    final state = await futureState;

    expect(state, isA<Unauthenticated>());
    expect(await StorageService().getToken(), isNull);

    await bloc.close();
  });
}