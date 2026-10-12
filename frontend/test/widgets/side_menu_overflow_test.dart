import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sgi_u_frontend/blocs/auth/auth_bloc.dart';
import 'package:sgi_u_frontend/navigation/seccion.dart';
import 'package:sgi_u_frontend/repositories/auth_repository.dart';
import 'package:sgi_u_frontend/widgets/side_menu.dart';

/// Corrección 1: colapsar o expandir el menú mostraba franjas rojas de
/// overflow (el contenido cambiaba de forma antes de que terminara la
/// animación del ancho, y con poca altura los ítems no entraban).
void main() {
  Future<void> montar(WidgetTester tester, Size tamanio) async {
    tester.view.physicalSize = tamanio;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
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
    await tester.pump();
  }

  /// Avanza la animación de a pasos chicos y falla si algún frame tira overflow.
  Future<void> animarSinOverflow(WidgetTester tester) async {
    for (var ms = 0; ms <= 300; ms += 25) {
      await tester.pump(const Duration(milliseconds: 25));
      expect(tester.takeException(), isNull, reason: 'overflow a los $ms ms');
    }
  }

  for (final tamanio in [const Size(1400, 900), const Size(1400, 480)]) {
    testWidgets('colapsar y expandir sin overflow (${tamanio.height.toInt()} px de alto)', (tester) async {
      await montar(tester, tamanio);
      expect(tester.takeException(), isNull);

      await tester.tap(find.byIcon(Icons.menu));
      await animarSinOverflow(tester);
      expect(tester.getSize(find.byType(SideMenu)).width, 80);

      await tester.tap(find.byIcon(Icons.menu));
      await animarSinOverflow(tester);
      expect(tester.getSize(find.byType(SideMenu)).width, 260);
    });
  }
}
