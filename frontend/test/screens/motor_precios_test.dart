import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sgi_u_frontend/blocs/recetas/recetas_bloc.dart';
import 'package:sgi_u_frontend/blocs/recetas/recetas_state.dart';
import 'package:sgi_u_frontend/models/categoria.dart';
import 'package:sgi_u_frontend/models/historial_precio.dart';
import 'package:sgi_u_frontend/models/insumo.dart';
import 'package:sgi_u_frontend/models/product.dart';
import 'package:sgi_u_frontend/models/receta.dart';
import 'package:sgi_u_frontend/models/receta_detalle.dart';
import 'package:sgi_u_frontend/screens/historial_precios_view.dart';
import 'package:sgi_u_frontend/screens/recetas_screen.dart';
import 'package:sgi_u_frontend/services/api_service.dart';

class _MockApi extends Mock implements ApiService {}

/// Etapa 4 en el frontend: preparación base con rinde en peso, precio
/// redondeado con ganancia en $, precio a mano e historial de precios.
void main() {
  const chocolate = Insumo(id: 1, codigo: 'MP-1', nombre: 'Chocolate', costoUnitario: 18000, unidadMedida: 'KILO',
      costoUnidadBase: 18);
  const ganache = Insumo(id: 2, codigo: 'ELA-4', nombre: 'Ganache', tipo: 'ELABORADO', costoUnitario: 11.75,
      unidadMedida: 'GRAMO', costoUnidadBase: 11.75);
  late _MockApi api;

  setUp(() {
    api = _MockApi();
    registerFallbackValue(<String, dynamic>{});
    when(() => api.getComponentesReceta()).thenAnswer((_) async => [chocolate, ganache]);
    when(() => api.getProducts()).thenAnswer((_) async => []);
    when(() => api.getCategorias()).thenAnswer((_) async => const [Categoria(id: 7, nombre: 'Tortas')]);
    when(() => api.getRecetas()).thenAnswer((_) async => const <Receta>[]);
    when(() => api.createReceta(any()))
        .thenAnswer((_) async => const Receta(id: 9, espProductoCodigo: 'ELA-9', nombre: 'Ganache'));
  });

  Future<void> tocar(WidgetTester t, Finder f) async {
    await t.ensureVisible(f);
    await t.pumpAndSettle();
    await t.tap(f);
    await t.pumpAndSettle();
  }

  testWidgets('preparación base: rinde en gramos, sin precio, y se envía rindeUnidadMedida', (t) async {
    t.view.physicalSize = const Size(1500, 1800);
    t.view.devicePixelRatio = 1.0;
    addTearDown(t.view.reset);
    await t.pumpWidget(MaterialApp(home: RecetasScreen(recetasBloc: RecetasBloc(apiService: api))));
    await t.pumpAndSettle();
    await tocar(t, find.text('Nueva Receta'));

    await t.enterText(find.byKey(const Key('nuevo_producto_nombre')), 'Ganache');
    await tocar(t, find.byKey(const Key('nuevo_producto_categoria')));
    await tocar(t, find.text('Tortas').last);
    await tocar(t, find.byKey(const Key('nuevo_producto_preparacion_base')));
    expect(find.byKey(const Key('input_rinde_unidad')), findsNothing);
    expect(find.byKey(const ValueKey('input_rinde_unidad_medida_GRAMO')), findsOneWidget);

    await t.enterText(find.byKey(const Key('input_nombre_receta')), 'Ganache');
    await t.enterText(find.byKey(const Key('input_rinde')), '800');
    await tocar(t, find.byKey(const Key('agregar_insumo_fila_button')));
    await tocar(t, find.byKey(const Key('selector_insumo_fila_0')));
    await tocar(t, find.text('Chocolate (MP-1)').last);
    await t.enterText(find.byKey(const Key('cantidad_insumo_fila_0')), '400');
    await t.pumpAndSettle();

    // 400 g × $18 = $7.200 / 800 g = $9 el g, $9.000 el kg; no tiene precio.
    expect(t.widget<Text>(find.byKey(const Key('costo_por_unidad_receta'))).data, '\$ 9.000,00');
    expect(t.widget<Text>(find.byKey(const Key('precio_resultante_receta'))).data, 'No se vende');

    await tocar(t, find.text('Guardar receta'));
    final enviado = verify(() => api.createReceta(captureAny())).captured.single as Map<String, dynamic>;
    expect(enviado['rindeUnidadMedida'], 'GRAMO');
    expect(enviado['productoNuevo']['vendible'], false);
  });

  test('precio del armador: a \$100, precio a mano conservado o subido al mínimo, ganancia en \$', () {
    RecetasState conProducto(Product p) => RecetasState(
          editingRecetaId: null,
          usarProductoNuevo: false,
          selectedProductoCodigo: p.codigo,
          availableProductos: [p],
          rinde: 1,
          costoTotal: 5325,
          detalles: const [RecetaDetalle(articuloId: 1, cantidad: 1)],
        );
    final margen = conProducto(Product(
        codigo: 'ELA-1', nombre: 'Torta', precioUnitario: 0, stockActual: 0, tipo: 'ELABORADO',
        porcentajeGanancia: 100));
    expect(margen.precioResultante, 10700);
    expect(margen.gananciaResultante, 5375);

    final manualAlto = conProducto(Product(
        codigo: 'ELA-1', nombre: 'Torta', precioUnitario: 15000, stockActual: 0, tipo: 'ELABORADO',
        porcentajeGanancia: 100, modoPrecio: 'MANUAL'));
    expect(manualAlto.precioResultante, 15000);

    final manualBajo = conProducto(Product(
        codigo: 'ELA-1', nombre: 'Torta', precioUnitario: 9000, stockActual: 0, tipo: 'ELABORADO',
        porcentajeGanancia: 100, modoPrecio: 'MANUAL'));
    expect(manualBajo.precioResultante, 10700);
  });

  testWidgets('historial de precios: muestra cada cambio y filtra por código', (t) async {
    t.view.physicalSize = const Size(1500, 900);
    t.view.devicePixelRatio = 1.0;
    addTearDown(t.view.reset);
    when(() => api.getHistorialPrecios(
            desde: any(named: 'desde'), hasta: any(named: 'hasta'), codigo: any(named: 'codigo')))
        .thenAnswer((_) async => [
              HistorialPrecio(
                  id: 1,
                  fecha: DateTime(2026, 10, 14, 10, 30),
                  codigo: 'ELA-0002',
                  nombre: 'Torta',
                  tipo: 'ELABORADO',
                  costoAnterior: 14970,
                  costoNuevo: 17370,
                  precioAnterior: 31500,
                  precioNuevo: 36500,
                  causa: 'Cambio en Chocolate cobertura (MP-0005)',
                  usuario: 'admin'),
            ]);
    await t.pumpWidget(MaterialApp(home: Scaffold(body: HistorialPreciosView(apiService: api))));
    await t.pumpAndSettle();

    expect(find.text('Torta (ELA-0002)'), findsOneWidget);
    expect(find.text('\$ 31.500,00 → \$ 36.500,00'), findsOneWidget);
    expect(find.text('Cambio en Chocolate cobertura (MP-0005)'), findsOneWidget);

    await t.enterText(find.byKey(const Key('historial_codigo')), 'ela-0002');
    await t.tap(find.byKey(const Key('historial_buscar')));
    await t.pumpAndSettle();
    verify(() => api.getHistorialPrecios(
        desde: any(named: 'desde'), hasta: any(named: 'hasta'), codigo: 'ELA-0002')).called(1);
  });
}
