import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sgi_u_frontend/models/insumo.dart';
import 'package:sgi_u_frontend/widgets/paquete_form_dialog.dart';

/// Etapa 4: armador de paquetes. Caja $900 + 1 m de cinta ($300) + 100 cm de
/// papel ($1.000) = $2.200; + $1.550 fijos = $3.750 → $3.800.
void main() {
  const caja = Insumo(id: 1, codigo: 'INS-0001', nombre: 'Caja', tipo: 'INSUMO', costoUnitario: 900,
      unidadMedida: 'UNIDAD', costoUnidadBase: 900);
  const cinta = Insumo(id: 2, codigo: 'INS-0002', nombre: 'Cinta', tipo: 'INSUMO', costoUnitario: 300,
      unidadMedida: 'METRO', costoUnidadBase: 3);
  const papel = Insumo(id: 3, codigo: 'INS-0004', nombre: 'Papel', tipo: 'INSUMO', costoUnitario: 1000,
      unidadMedida: 'METRO', costoUnidadBase: 10);
  Map<String, dynamic>? resultado;

  Future<void> elegir(WidgetTester t, Finder campo, String opcion) async {
    await t.ensureVisible(campo);
    await t.pumpAndSettle();
    await t.tap(campo);
    await t.pumpAndSettle();
    await t.tap(find.text(opcion).last);
    await t.pumpAndSettle();
  }

  testWidgets('costo del armado, precio redondeado y ganancia en vivo; payload', (t) async {
    t.view.physicalSize = const Size(1400, 1400);
    t.view.devicePixelRatio = 1.0;
    addTearDown(t.view.reset);
    await t.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: ElevatedButton(
            onPressed: () async {
              resultado = await showDialog<Map<String, dynamic>>(
                  context: context, builder: (_) => const PaqueteFormDialog(insumos: [caja, cinta, papel]));
            },
            child: const Text('abrir'),
          ),
        ),
      ),
    ));
    await t.tap(find.text('abrir'));
    await t.pumpAndSettle();

    await t.enterText(find.byKey(const Key('paquete_nombre_input')), 'Paquete día de la madre');
    await elegir(t, find.byKey(const Key('paquete_insumo_fila_0')), 'Caja (INS-0001)');
    await t.enterText(find.byKey(const Key('paquete_cantidad_fila_0')), '1');
    await t.tap(find.byKey(const Key('paquete_agregar_fila')));
    await t.pumpAndSettle();
    await elegir(t, find.byKey(const Key('paquete_insumo_fila_1')), 'Cinta (INS-0002)');
    await t.enterText(find.byKey(const Key('paquete_cantidad_fila_1')), '1');
    await t.tap(find.byKey(const Key('paquete_agregar_fila')));
    await t.pumpAndSettle();
    await elegir(t, find.byKey(const Key('paquete_insumo_fila_2')), 'Papel (INS-0004)');
    await t.enterText(find.byKey(const Key('paquete_cantidad_fila_2')), '100');
    await elegir(t, find.byKey(const ValueKey('paquete_unidad_fila_2_3')), 'Centímetro');
    await t.enterText(find.byKey(const Key('paquete_monto_fijo_input')), '1550');
    await t.pump();

    String texto(String k) => t.widget<Text>(find.byKey(Key(k))).data!;
    expect(texto('paquete_costo_armado'), '\$ 2.200,00');
    expect(texto('paquete_precio'), '\$ 3.800,00');
    expect(texto('paquete_ganancia'), '\$ 1.600,00');

    await t.tap(find.byKey(const Key('guardar_paquete_button')));
    await t.pumpAndSettle();
    expect(resultado, {
      'nombre': 'Paquete día de la madre',
      'montoFijo': 1550.0,
      'armado': [
        {'articuloId': 1, 'cantidad': 1.0, 'unidadMedida': 'UNIDAD'},
        {'articuloId': 2, 'cantidad': 1.0, 'unidadMedida': 'METRO'},
        {'articuloId': 3, 'cantidad': 100.0, 'unidadMedida': 'CENTIMETRO'},
      ],
    });
  });
}
