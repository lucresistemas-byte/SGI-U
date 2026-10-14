import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sgi_u_frontend/models/cambio_precio.dart';
import 'package:sgi_u_frontend/navigation/app_shell.dart';
import 'package:sgi_u_frontend/navigation/seccion.dart';
import 'package:sgi_u_frontend/services/api_service.dart';

/// Etapa 4: después de un guardado que cambia precios, AppShell muestra
/// "Se actualizaron N precios" con precio anterior, nuevo y ganancia.
void main() {
  testWidgets('la respuesta con cambiosDePrecio abre el resumen', (t) async {
    t.view.physicalSize = const Size(1400, 1000);
    t.view.devicePixelRatio = 1.0;
    addTearDown(t.view.reset);
    await t.pumpWidget(MaterialApp(
      home: AppShell(seccionInicial: Seccion.catalogo, construirSeccion: (_) => const SizedBox()),
    ));

    ApiService.avisarCambiosDePrecio({
      'codigo': 'MP-0005',
      'cambiosDePrecio': [
        {'codigo': 'ELA-0002', 'nombre': 'Torta', 'precioAnterior': 31500, 'precioNuevo': 36500, 'costoNuevo': 17370,
          'gananciaPesos': 19130},
        {'codigo': 'ELA-0005', 'nombre': 'Porción', 'precioAnterior': 3000, 'precioNuevo': 3500, 'costoNuevo': 1374.38,
          'gananciaPesos': 2125.62},
      ],
    });
    await t.pumpAndSettle();

    expect(find.text('Se actualizaron 2 precios'), findsOneWidget);
    expect(t.widget<Text>(find.byKey(const Key('cambio_precio_nuevo_ELA-0002'))).data, '\$ 36.500,00');
    expect(t.widget<Text>(find.byKey(const Key('cambio_ganancia_ELA-0005'))).data, '\$ 2.125,62');

    await t.tap(find.byKey(const Key('cerrar_cambios_precio')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('cambios_precio_dialog')), findsNothing);

    // Sin cambios no se muestra nada.
    ApiService.avisarCambiosDePrecio({'cambiosDePrecio': []});
    await t.pumpAndSettle();
    expect(find.byKey(const Key('cambios_precio_dialog')), findsNothing);
  });

  test('CambioPrecio.deRespuesta lee la lista de la respuesta', () {
    expect(CambioPrecio.deRespuesta({'otro': 1}), isEmpty);
    expect(CambioPrecio.deRespuesta(null), isEmpty);
  });
}
