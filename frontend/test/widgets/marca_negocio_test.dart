import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:sgi_u_frontend/blocs/auth/auth_bloc.dart';
import 'package:sgi_u_frontend/models/configuracion_negocio.dart';
import 'package:sgi_u_frontend/navigation/seccion.dart';
import 'package:sgi_u_frontend/repositories/auth_repository.dart';
import 'package:sgi_u_frontend/screens/login_screen.dart';
import 'package:sgi_u_frontend/services/api_service.dart';
import 'package:sgi_u_frontend/widgets/marca_negocio.dart';
import 'package:sgi_u_frontend/widgets/side_menu.dart';

/// Parte 1: logo y nombre del negocio en el menú lateral y en el login.
void main() {
  // PNG de 1x1 válido.
  const logoBase64 =
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==';
  final logo = base64Decode(logoBase64);

  tearDown(() => ApiService.configuracionActual = null);

  Future<void> montarMenu(WidgetTester t) async {
    t.view.physicalSize = const Size(1400, 900);
    t.view.devicePixelRatio = 1.0;
    addTearDown(t.view.reset);
    await t.pumpWidget(MaterialApp(
      home: BlocProvider(
        create: (_) => AuthBloc(authRepository: AuthRepository()),
        child: Scaffold(
          body: Row(children: [
            SideMenu(seccionActual: Seccion.catalogo, onSeleccionar: (_) {}),
            const Expanded(child: SizedBox()),
          ]),
        ),
      ),
    ));
  }

  Future<void> colapsar(WidgetTester t) async {
    await t.tap(find.byIcon(Icons.menu));
    await t.pumpAndSettle();
  }

  testWidgets('sin logo: el menú muestra solo el nombre y, colapsado, las iniciales', (t) async {
    ApiService.configuracionActual = const ConfiguracionNegocio(nombre: 'Dulces Sandra');
    await montarMenu(t);

    expect(find.text('Dulces Sandra'), findsOneWidget);
    expect(find.byKey(const Key('logo_negocio_menu')), findsNothing);

    await colapsar(t);
    expect(find.text('Dulces Sandra'), findsNothing);
    expect(find.descendant(of: find.byKey(const Key('iniciales_negocio')), matching: find.text('DS')),
        findsOneWidget);
  });

  testWidgets('con logo: logo + nombre expandido y solo el logo colapsado', (t) async {
    ApiService.configuracionActual = ConfiguracionNegocio(nombre: 'Dulces Sandra', logo: logo);
    await montarMenu(t);

    expect(find.byKey(const Key('logo_negocio_menu')), findsOneWidget);
    expect(find.text('Dulces Sandra'), findsOneWidget);

    await colapsar(t);
    expect(find.byKey(const Key('logo_negocio_compacto')), findsOneWidget);
    expect(find.byKey(const Key('iniciales_negocio')), findsNothing);
    expect(find.text('Dulces Sandra'), findsNothing);
  });

  testWidgets('el logo y el nombre nuevos se ven en el momento, también colapsado', (t) async {
    ApiService.configuracionActual = const ConfiguracionNegocio(nombre: 'SGI-U');
    await montarMenu(t);
    expect(find.byKey(const Key('logo_negocio_menu')), findsNothing);

    // Lo que hace Configuración al guardar.
    ApiService.configuracionActual = ConfiguracionNegocio(nombre: 'Chocolatería Sandra', logo: logo);
    await t.pump();
    expect(find.byKey(const Key('logo_negocio_menu')), findsOneWidget);
    expect(find.text('Chocolatería Sandra'), findsOneWidget);

    await colapsar(t);
    ApiService.configuracionActual = const ConfiguracionNegocio(nombre: 'Chocolatería Sandra');
    await t.pump();
    expect(find.byKey(const Key('logo_negocio_compacto')), findsNothing);
    expect(find.text('CS'), findsOneWidget);
  });

  test('iniciales: dos primeras palabras; sin letras, vacío (se usa un ícono)', () {
    expect(MarcaNegocio.iniciales('Dulces Sandra Regalos'), 'DS');
    expect(MarcaNegocio.iniciales('  ñandú  '), 'Ñ');
    expect(MarcaNegocio.iniciales('***'), '');
  });

  testWidgets('el login muestra el logo y el nombre del endpoint público', (t) async {
    t.view.physicalSize = const Size(1400, 900);
    t.view.devicePixelRatio = 1.0;
    addTearDown(t.view.reset);
    final api = ApiService();
    api.dio = Dio(BaseOptions(baseUrl: 'http://localhost:3000'));
    DioAdapter(dio: api.dio).onGet('/api/configuracion/marca',
        (s) => s.reply(200, {'nombre': 'Dulces Sandra', 'logo': logoBase64}));

    await t.pumpWidget(MaterialApp(
      home: BlocProvider(
        create: (_) => AuthBloc(authRepository: AuthRepository()),
        child: const LoginScreen(),
      ),
    ));
    // La respuesta simulada llega con temporizadores del test.
    for (var i = 0; i < 5; i++) {
      await t.pump(const Duration(milliseconds: 100));
    }

    expect(find.byKey(const Key('logo_negocio_login')), findsOneWidget);
    expect(find.text('Dulces Sandra'), findsOneWidget);
  });

  testWidgets('el login sin logo muestra solo el nombre', (t) async {
    t.view.physicalSize = const Size(1400, 900);
    t.view.devicePixelRatio = 1.0;
    addTearDown(t.view.reset);
    final api = ApiService();
    api.dio = Dio(BaseOptions(baseUrl: 'http://localhost:3000'));
    DioAdapter(dio: api.dio).onGet('/api/configuracion/marca',
        (s) => s.reply(200, {'nombre': 'Dulces Sandra', 'logo': null}));

    await t.pumpWidget(MaterialApp(
      home: BlocProvider(
        create: (_) => AuthBloc(authRepository: AuthRepository()),
        child: const LoginScreen(),
      ),
    ));
    // La respuesta simulada llega con temporizadores del test.
    for (var i = 0; i < 5; i++) {
      await t.pump(const Duration(milliseconds: 100));
    }

    expect(find.byKey(const Key('logo_negocio_login')), findsNothing);
    expect(find.byKey(const Key('nombre_negocio_login')), findsOneWidget);
    expect(find.text('Dulces Sandra'), findsOneWidget);
  });

  test('guardar sin logo pide quitarlo en el backend', () async {
    final api = ApiService();
    api.dio = Dio(BaseOptions(baseUrl: 'http://localhost:3000'));
    Object? enviado;
    DioAdapter(dio: api.dio).onPut('/api/configuracion', (s) => s.reply(200, {'nombre': 'Dulces'}),
        data: Matchers.any);
    api.dio.interceptors.insert(0, InterceptorsWrapper(onRequest: (o, h) {
      enviado = o.data;
      h.next(o);
    }));

    await api.saveConfiguracion(const ConfiguracionNegocio(nombre: 'Dulces'));

    expect((enviado as Map)['quitarLogo'], isTrue);
  });
}
