import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sgi_u_frontend/blocs/pos_bloc.dart';
import 'package:sgi_u_frontend/blocs/pos_event.dart';
import 'package:sgi_u_frontend/main.dart';
import 'package:sgi_u_frontend/repositories/auth_repository.dart';
import 'package:sgi_u_frontend/screens/login_screen.dart';
import 'package:sgi_u_frontend/services/api_service.dart';
import 'package:sgi_u_frontend/navigation/app_shell.dart';
import 'package:sgi_u_frontend/navigation/seccion.dart';

/// Flujo de navegación de sesión (login, logout, sesión vencida) sobre la app
/// real (MyApp + AuthBloc + StartupDecider + AppShell + SideMenu). Solo se
/// simulan el repositorio de auth, la API del POS (sin red) y el contenido de
/// las secciones.

class _MockAuthRepository extends Mock implements AuthRepository {}

class _MockPosApi extends Mock implements PosApi {}

/// AppShell real con el contenido de cada sección reemplazado por un texto
/// (sin red).
Widget _seccionFalsa(Seccion seccion) => Text('SECCION ${seccion.name}');

/// JWT sin firma válida, pero con `exp` legible por AuthBloc._isTokenExpired.
String _jwt({required Duration expiraEn}) {
  String b64(Map<String, dynamic> m) =>
      base64Url.encode(utf8.encode(jsonEncode(m))).replaceAll('=', '');
  final exp = DateTime.now().add(expiraEn).millisecondsSinceEpoch ~/ 1000;
  return '${b64({'alg': 'HS256'})}.${b64({'sub': 'admin', 'exp': exp})}.firma';
}

final _principal = find.byType(AppShell);
final _botonLogin = find.widgetWithText(ElevatedButton, 'Iniciar sesión');

void main() {
  late _MockAuthRepository repo;
  late _MockPosApi posApi;

  setUp(() {
    posApi = _MockPosApi();
    when(() => posApi.getProducts()).thenAnswer((_) async => [
          {
            'codigo': 'P1',
            'nombre': 'Café',
            'precioUnitario': 150.0,
            'stockActual': 10,
            'activo': true,
          }
        ]);
    repo = _MockAuthRepository();
    when(() => repo.login(any(), any()))
        .thenAnswer((_) async => {'token': _jwt(expiraEn: const Duration(hours: 1))});
    when(() => repo.baseUrl).thenReturn('http://localhost:3000');
    FlutterSecureStorage.setMockInitialValues({});
  });

  Future<void> arrancar(WidgetTester tester) async {
    // Ancho de escritorio: AppShell muestra el SideMenu fijo.
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(MyApp(
      authRepository: repo,
      posApi: posApi,
      pantallaPrincipal: const AppShell(construirSeccion: _seccionFalsa),
    ));
    await tester.pumpAndSettle();
  }

  Future<void> ingresar(WidgetTester tester) async {
    await tester.enterText(find.byType(TextFormField).at(0), 'admin');
    await tester.enterText(find.byType(TextFormField).at(1), 'admin123');
    await tester.tap(_botonLogin);
    await tester.pumpAndSettle();
  }

  PosBloc posBloc(WidgetTester tester) =>
      BlocProvider.of<PosBloc>(tester.element(find.byType(Navigator)));

  Future<void> agregarAlCarrito(WidgetTester tester) async {
    posBloc(tester).add(const LoadProducts());
    await tester.pumpAndSettle();
    posBloc(tester).add(const AddToCart('P1', 2));
    await tester.pumpAndSettle();
    expect(posBloc(tester).state.cart['P1']?.cantidad, 2);
  }

  Future<void> cerrarSesion(WidgetTester tester) async {
    await tester.tap(find.text('Cerrar Sesión'));
    await tester.pumpAndSettle();
  }

  testWidgets('primer arranque: login correcto llega a la pantalla principal',
      (tester) async {
    await arrancar(tester);
    expect(find.byType(LoginScreen), findsOneWidget);

    await ingresar(tester);

    expect(_principal, findsOneWidget);
    expect(find.byType(LoginScreen), findsNothing);
  });

  testWidgets('cerrar sesión -> login -> reingresar llega a la pantalla principal',
      (tester) async {
    await arrancar(tester);
    await ingresar(tester);

    await cerrarSesion(tester);
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.text(mensajeSesionVencida), findsNothing);

    await ingresar(tester);
    expect(_principal, findsOneWidget);
  });

  testWidgets('cerrar sesión desde otra sección también permite reingresar',
      (tester) async {
    await arrancar(tester);
    await ingresar(tester);
    await tester.tap(find.text(Seccion.pedidos.etiqueta));
    await tester.pumpAndSettle();
    expect(find.text('SECCION pedidos'), findsOneWidget);

    await cerrarSesion(tester);
    expect(find.byType(LoginScreen), findsOneWidget);

    await ingresar(tester);
    expect(_principal, findsOneWidget);
  });

  testWidgets(
      'sesión vencida (401) -> login con aviso una sola vez -> reingreso OK',
      (tester) async {
    await arrancar(tester);
    await ingresar(tester);

    // Lo que hace el interceptor de ApiService ante un 401.
    ApiService().onSessionExpired!.call();
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.text(mensajeSesionVencida), findsOneWidget);

    await ingresar(tester);
    expect(_principal, findsOneWidget);
  });

  testWidgets('después de cerrar sesión, "atrás" no vuelve a la app',
      (tester) async {
    await arrancar(tester);
    await ingresar(tester);
    await cerrarSesion(tester);

    expect(navigatorKey.currentState!.canPop(), isFalse);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(_principal, findsNothing);
  });

  testWidgets('arranque con token guardado válido entra directo',
      (tester) async {
    FlutterSecureStorage.setMockInitialValues(
        {'jwt_token': _jwt(expiraEn: const Duration(hours: 1))});

    await arrancar(tester);

    expect(_principal, findsOneWidget);
    expect(find.byType(LoginScreen), findsNothing);
    verifyNever(() => repo.login(any(), any()));
  });

  testWidgets('cerrar sesión vacía el carrito del POS', (tester) async {
    await arrancar(tester);
    await ingresar(tester);
    await agregarAlCarrito(tester);

    await cerrarSesion(tester);

    expect(posBloc(tester).state.cart, isEmpty);
  });

  testWidgets('sesión vencida -> reingreso conserva el carrito del POS',
      (tester) async {
    await arrancar(tester);
    await ingresar(tester);
    await agregarAlCarrito(tester);

    ApiService().onSessionExpired!.call();
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);

    await ingresar(tester);
    expect(_principal, findsOneWidget);
    expect(posBloc(tester).state.cart['P1']?.cantidad, 2);
  });

  group('Enter en el formulario de login', () {
    final usuario = find.byType(TextFormField).at(0);
    final contrasena = find.byType(TextFormField).at(1);

    testWidgets('Enter en Contraseña inicia sesión', (tester) async {
      await arrancar(tester);
      await tester.enterText(usuario, 'admin');
      await tester.enterText(contrasena, 'admin123');

      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(_principal, findsOneWidget);
      verify(() => repo.login('admin', 'admin123')).called(1);
    });

    testWidgets('Enter en Usuario con Contraseña vacía pasa el foco, no inicia',
        (tester) async {
      await arrancar(tester);
      await tester.enterText(usuario, 'admin');

      await tester.testTextInput.receiveAction(TextInputAction.next);
      await tester.pumpAndSettle();

      verifyNever(() => repo.login(any(), any()));
      final campo = tester.widget<EditableText>(
          find.descendant(of: contrasena, matching: find.byType(EditableText)));
      expect(campo.focusNode.hasFocus, isTrue);
    });

    testWidgets('Enter en Usuario con Contraseña completa inicia sesión',
        (tester) async {
      await arrancar(tester);
      await tester.enterText(contrasena, 'admin123');
      await tester.enterText(usuario, 'admin');

      await tester.testTextInput.receiveAction(TextInputAction.next);
      await tester.pumpAndSettle();

      expect(_principal, findsOneWidget);
    });
  });
}
