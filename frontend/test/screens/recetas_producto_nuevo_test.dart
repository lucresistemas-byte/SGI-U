import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sgi_u_frontend/blocs/recetas/recetas_bloc.dart';
import 'package:sgi_u_frontend/models/categoria.dart';
import 'package:sgi_u_frontend/models/insumo.dart';
import 'package:sgi_u_frontend/models/receta.dart';
import 'package:sgi_u_frontend/screens/recetas_screen.dart';
import 'package:sgi_u_frontend/services/api_service.dart';

class _MockApi extends Mock implements ApiService {}

/// Etapa 1 (Punto 5): la receta crea el producto elaborado; "Producto
/// existente" ofrece solo elaborados activos sin receta (no reventa).
void main() {
  const harina = Insumo(id: 1, codigo: 'MP-1', nombre: 'Harina', costoUnitario: 1000, unidadMedida: 'KILO');
  late _MockApi api;

  setUp(() {
    api = _MockApi();
    registerFallbackValue(<String, dynamic>{});
    when(() => api.getInsumos()).thenAnswer((_) async => [harina]);
    when(() => api.getProducts()).thenAnswer((_) async => [
          {'codigo': 'ELA-1', 'nombre': 'Tarta de coco', 'precioUnitario': 10800, 'stockActual': 1, 'tipo': 'ELABORADO'},
          {'codigo': 'ELA-2', 'nombre': 'Budín', 'precioUnitario': 5000, 'stockActual': 0, 'tipo': 'ELABORADO'},
          {'codigo': 'ELA-3', 'nombre': 'Viejo', 'precioUnitario': 5000, 'stockActual': 0, 'tipo': 'ELABORADO', 'activo': false},
          {'codigo': 'REV-1', 'nombre': 'Coca-Cola', 'precioUnitario': 1500, 'stockActual': 24, 'tipo': 'REVENTA'},
        ]);
    when(() => api.getCategorias()).thenAnswer((_) async => const [Categoria(id: 7, nombre: 'Tortas')]);
    when(() => api.getRecetas()).thenAnswer((_) async => const [
          Receta(id: 1, espProductoCodigo: 'ELA-1', espProductoNombre: 'Tarta de coco', nombre: 'Tarta'),
        ]);
    when(() => api.createReceta(any())).thenAnswer(
        (_) async => const Receta(id: 9, espProductoCodigo: 'ELA-0001', nombre: 'Torta base'));
  });

  Future<void> abrirArmador(WidgetTester t) async {
    t.view.physicalSize = const Size(1500, 1600);
    t.view.devicePixelRatio = 1.0;
    addTearDown(t.view.reset);
    await t.pumpWidget(MaterialApp(home: RecetasScreen(recetasBloc: RecetasBloc(apiService: api))));
    await t.pumpAndSettle();
    await t.tap(find.text('Nueva Receta'));
    await t.pumpAndSettle();
  }

  Future<void> completarRecetaYGuardar(WidgetTester t) async {
    await t.enterText(find.byKey(const Key('input_nombre_receta')), 'Torta base');
    await t.tap(find.byKey(const Key('agregar_insumo_fila_button')));
    await t.pumpAndSettle();
    final guardar = find.text('Guardar Receta');
    await t.ensureVisible(guardar);
    await t.tap(guardar);
    await t.pumpAndSettle();
  }

  Map<String, dynamic> payload() =>
      verify(() => api.createReceta(captureAny())).captured.single as Map<String, dynamic>;

  testWidgets('por defecto la receta crea un producto nuevo y lo envía en productoNuevo', (t) async {
    await abrirArmador(t);

    await t.enterText(find.byKey(const Key('nuevo_producto_nombre')), 'Torta de frutilla');
    await t.enterText(find.byKey(const Key('nuevo_producto_porcentaje')), '120');
    await t.tap(find.byKey(const Key('nuevo_producto_categoria')));
    await t.pumpAndSettle();
    await t.tap(find.text('Tortas').last);
    await t.pumpAndSettle();
    await completarRecetaYGuardar(t);

    final p = payload();
    expect(p.containsKey('espProductoCodigo'), isFalse);
    expect(p['productoNuevo'], {
      'nombre': 'Torta de frutilla',
      'categoriaId': 7,
      'porcentajeGanancia': 120.0,
      'vendible': true,
    });
  });

  testWidgets('preparación base y código propio', (t) async {
    await abrirArmador(t);

    await t.enterText(find.byKey(const Key('nuevo_producto_nombre')), 'Ganache');
    await t.enterText(find.byKey(const Key('nuevo_producto_codigo')), 'GAN-1');
    await t.tap(find.byKey(const Key('nuevo_producto_preparacion_base')));
    await t.pump();
    await completarRecetaYGuardar(t);

    expect(payload()['productoNuevo'], {'nombre': 'Ganache', 'codigo': 'GAN-1', 'vendible': false});
  });

  testWidgets('producto existente: solo elaborados activos sin receta', (t) async {
    await abrirArmador(t);

    await t.tap(find.text('Producto existente'));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('selector_producto_receta')));
    await t.pumpAndSettle();

    expect(find.text('Budín (ELA-2)'), findsWidgets);
    expect(find.text('Tarta de coco (ELA-1)'), findsNothing); // ya tiene receta
    expect(find.text('Viejo (ELA-3)'), findsNothing); // inactivo
    expect(find.text('Coca-Cola (REV-1)'), findsNothing); // reventa

    await t.tap(find.text('Budín (ELA-2)').last);
    await t.pumpAndSettle();
    await completarRecetaYGuardar(t);

    final p = payload();
    expect(p['espProductoCodigo'], 'ELA-2');
    expect(p.containsKey('productoNuevo'), isFalse);
  });
}
