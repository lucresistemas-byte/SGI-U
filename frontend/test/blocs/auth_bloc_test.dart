import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sgi_u_frontend/blocs/auth/auth_bloc.dart';
import 'package:sgi_u_frontend/blocs/auth/auth_event.dart';
import 'package:sgi_u_frontend/blocs/auth/auth_state.dart';
import 'package:sgi_u_frontend/repositories/auth_repository.dart';
import 'package:sgi_u_frontend/services/storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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