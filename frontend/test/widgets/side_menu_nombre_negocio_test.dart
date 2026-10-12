import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:sgi_u_frontend/blocs/auth/auth_bloc.dart';
import 'package:sgi_u_frontend/models/configuracion_negocio.dart';
import 'package:sgi_u_frontend/navigation/seccion.dart';
import 'package:sgi_u_frontend/repositories/auth_repository.dart';
import 'package:sgi_u_frontend/services/api_service.dart';
import 'package:sgi_u_frontend/widgets/side_menu.dart';

/// Corrección 2: al guardar la configuración, el nombre nuevo del negocio
/// tiene que verse en el menú lateral en el momento (antes recién aparecía
/// después de colapsar y expandir el menú).
void main() {
  tearDown(() => ApiService.configuracionActual = null);

  testWidgets('guardar la configuración actualiza el nombre del menú sin recargarlo', (tester) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final api = ApiService();
    api.dio = Dio(BaseOptions(baseUrl: 'http://localhost:3000'));
    DioAdapter(dio: api.dio).onPut('/api/configuracion',
        (s) => s.reply(200, {'nombre': 'Dulces Sandra'}),
        data: Matchers.any);

    await tester.pumpWidget(MaterialApp(
      home: BlocProvider(
        create: (_) => AuthBloc(authRepository: AuthRepository()),
        child: Scaffold(
          body: Row(children: [
            SideMenu(seccionActual: Seccion.settings, onSeleccionar: (_) {}),
            const Expanded(child: SizedBox()),
          ]),
        ),
      ),
    ));
    expect(find.text('SGI-U'), findsOneWidget);

    await tester.runAsync(() => api.saveConfiguracion(const ConfiguracionNegocio(nombre: 'Dulces Sandra')));
    await tester.pump();

    expect(find.text('Dulces Sandra'), findsOneWidget);
    expect(find.text('SGI-U'), findsNothing);
  });
}
