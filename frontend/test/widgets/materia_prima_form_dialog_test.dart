import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sgi_u_frontend/models/insumo.dart';
import 'package:sgi_u_frontend/widgets/materia_prima_form_dialog.dart';

/// Etapa 2: la materia prima se carga con su presentación de compra y el
/// sistema calcula el costo por unidad base.
void main() {
  Map<String, dynamic>? resultado;

  Future<void> abrir(WidgetTester t, {Insumo? existente}) async {
    t.view.physicalSize = const Size(1200, 1200);
    t.view.devicePixelRatio = 1.0;
    addTearDown(t.view.reset);
    resultado = null;
    await t.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: ElevatedButton(
            onPressed: () async {
              resultado = await showDialog<Map<String, dynamic>>(
                  context: context, builder: (_) => MateriaPrimaFormDialog(existente: existente));
            },
            child: const Text('abrir'),
          ),
        ),
      ),
    ));
    await t.tap(find.text('abrir'));
    await t.pumpAndSettle();
  }

  Future<void> elegir(WidgetTester t, Finder campo, String opcion) async {
    await t.tap(campo);
    await t.pumpAndSettle();
    await t.tap(find.text(opcion).last);
    await t.pumpAndSettle();
  }

  testWidgets('bolsa de 25 kg a \$30.000: costo por gramo y por kilo, en vivo', (t) async {
    await abrir(t);
    await elegir(t, find.byKey(const Key('insumo_tipo_dropdown')), 'Materia prima');
    await t.enterText(find.byKey(const Key('insumo_nombre_input')), 'Harina 000');
    await t.enterText(find.byKey(const Key('insumo_presentacion_descripcion_input')), 'Bolsa 25 kg');
    await t.enterText(find.byKey(const Key('insumo_presentacion_cantidad_input')), '25');
    await t.enterText(find.byKey(const Key('insumo_presentacion_precio_input')), '30.000');
    await t.pump();

    final costo = t.widget<Text>(find.byKey(const Key('insumo_costo_calculado'))).data!;
    expect(costo, contains('1,2000 por g'));
    expect(costo, contains('1.200,00 por kg'));

    await t.enterText(find.byKey(const Key('insumo_stock_input')), '2,5');
    await t.tap(find.byKey(const Key('guardar_insumo_button')));
    await t.pumpAndSettle();

    expect(resultado, {
      'tipo': 'MATERIA_PRIMA',
      'nombre': 'Harina 000',
      'unidadMedida': 'KILO',
      'presentacionDescripcion': 'Bolsa 25 kg',
      'presentacionCantidad': 25.0,
      'presentacionUnidad': 'KILO',
      'presentacionPrecio': 30000.0,
      'stockActual': 2.5,
      'stockMinimo': 0.0,
      'stockUnidad': 'KILO',
    });
  });

  testWidgets('docena de huevos: costo por unidad; la presentación ofrece solo unidades de la familia', (t) async {
    await abrir(t);
    await elegir(t, find.byKey(const Key('insumo_unidad_dropdown')), 'Unidad (unidades)');
    await t.enterText(find.byKey(const Key('insumo_presentacion_cantidad_input')), '1');
    await elegir(t, find.byKey(const ValueKey('insumo_presentacion_unidad_UNIDAD')), 'Docena');
    await t.enterText(find.byKey(const Key('insumo_presentacion_precio_input')), '3000');
    await t.pump();

    expect(t.widget<Text>(find.byKey(const Key('insumo_costo_calculado'))).data, contains('250,0000 por u'));

    await t.tap(find.byKey(const ValueKey('insumo_presentacion_unidad_UNIDAD')));
    await t.pumpAndSettle();
    expect(find.text('Kilo'), findsNothing);
    expect(find.text('Gramo'), findsNothing);
  });

  testWidgets('editar: precarga la presentación guardada', (t) async {
    await abrir(t,
        existente: const Insumo(
          id: 1,
          codigo: 'MP-0001',
          nombre: 'Leche',
          costoUnitario: 1500,
          unidadMedida: 'LITRO',
          costoUnidadBase: 1.5,
          presentacionDescripcion: 'Sachet 1 l',
          presentacionCantidad: 1,
          presentacionUnidad: 'LITRO',
          presentacionPrecio: 1500,
        ));

    expect(find.text('Sachet 1 l'), findsOneWidget);
    expect(t.widget<Text>(find.byKey(const Key('insumo_costo_calculado'))).data, contains('1,5000 por ml'));
    await t.tap(find.byKey(const Key('guardar_insumo_button')));
    await t.pumpAndSettle();
    expect(resultado!.containsKey('stockActual'), isFalse);
    expect(resultado!['presentacionPrecio'], 1500.0);
  });
}
