import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sgi_u_frontend/blocs/insumos/insumos_bloc.dart';
import 'package:sgi_u_frontend/blocs/insumos/insumos_event.dart';
import 'package:sgi_u_frontend/blocs/insumos/insumos_state.dart';
import 'package:sgi_u_frontend/blocs/recetas/recetas_bloc.dart';
import 'package:sgi_u_frontend/models/categoria.dart';
import 'package:sgi_u_frontend/models/insumo.dart';
import 'package:sgi_u_frontend/models/product.dart';
import 'package:sgi_u_frontend/models/receta.dart';
import 'package:sgi_u_frontend/screens/insumos_screen.dart';
import 'package:sgi_u_frontend/screens/recetas_screen.dart';
import 'package:sgi_u_frontend/services/api_service.dart';
import 'package:sgi_u_frontend/widgets/product_card.dart';

class _MockInsumosBloc extends MockBloc<InsumosEvent, InsumosState> implements InsumosBloc {}

class _FakeEvent extends Fake implements InsumosEvent {}

class _MockApi extends Mock implements ApiService {}

/// Etapa 3: la caja de chocolate de 100 g (reventa + materia prima) se compra
/// en bulto de 12 cajas y se vende por caja.
void main() {
  setUpAll(() {
    registerFallbackValue(_FakeEvent());
    registerFallbackValue(<String, dynamic>{});
  });

  const caja = Insumo(
    id: 24,
    codigo: 'RMP-0001',
    nombre: 'Caja de chocolate amargo 100 g',
    tipo: 'REVENTA_MATERIA_PRIMA',
    costoUnitario: 22.5,
    unidadMedida: 'GRAMO',
    costoUnidadBase: 22.5,
    stockActual: 3650,
    stockMinimo: 1200,
    presentacionDescripcion: 'Bulto de 12 cajas',
    presentacionCantidad: 1.2,
    presentacionUnidad: 'KILO',
    presentacionPrecio: 27000,
    ventaUnidadNombre: 'Caja',
    ventaUnidadContenido: 100,
    stockUnidadesVenta: 36,
    stockSuelto: 50,
    costoUnidadVenta: 2250,
    porcentajeGanancia: 60,
    precioVenta: 3600,
  );

  void pantallaGrande(WidgetTester t) {
    t.view.physicalSize = const Size(1500, 1200);
    t.view.devicePixelRatio = 1.0;
    addTearDown(t.view.reset);
  }

  testWidgets('Materia Prima muestra cajas y sueltos, y el ajuste se puede hacer por bulto', (t) async {
    pantallaGrande(t);
    final bloc = _MockInsumosBloc();
    when(() => bloc.state).thenReturn(const InsumosLoaded(insumos: [caja]));
    await t.pumpWidget(MaterialApp(home: InsumosScreen(insumosBloc: bloc)));
    await t.pumpAndSettle();

    expect(t.widget<Text>(find.byKey(const Key('stock_insumo_RMP-0001'))).data, '3.650 g');
    expect(t.widget<Text>(find.byKey(const Key('unidades_venta_insumo_RMP-0001'))).data, '36 Caja · 50 g sueltos');
    expect(t.widget<Text>(find.byKey(const Key('precio_venta_insumo_RMP-0001'))).data, contains('3.600'));

    await t.ensureVisible(find.byKey(const Key('ajustar_stock_RMP-0001')));
    await t.tap(find.byKey(const Key('ajustar_stock_RMP-0001')));
    await t.pumpAndSettle();
    await t.enterText(find.byKey(const Key('ajuste_cantidad_input')), '1');
    await t.tap(find.byKey(const Key('ajuste_unidad_dropdown')));
    await t.pumpAndSettle();
    expect(find.text('Caja (100 g)'), findsWidgets);
    await t.tap(find.text('Bulto de 12 cajas (1,2 kg)').last);
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('confirmar_ajuste_button')));
    await t.pumpAndSettle();

    verify(() => bloc.add(const AjustarStockInsumoEvent(
        id: 24, cantidad: 1, unidad: 'PRESENTACION', motivo: 'Ajuste manual de stock'))).called(1);
  });

  testWidgets('POS: la tarjeta muestra el stock en cajas', (t) async {
    final producto = Product.fromJson(const {
      'codigo': 'RMP-0001',
      'nombre': 'Caja de chocolate amargo 100 g',
      'precioUnitario': 3600.0,
      'stockActual': 36,
      'unidadMedida': 'GRAMO',
      'tipo': 'REVENTA_MATERIA_PRIMA',
      'unidadVenta': 'Caja',
    });
    expect(producto.unidadStock, 'Caja');
    await t.pumpWidget(MaterialApp(home: Scaffold(body: ProductCard(product: producto, onAdd: (_) {}))));
    expect(find.text('Stock: 36 cajas'), findsOneWidget);
  });

  testWidgets('el armador de recetas ofrece la caja como componente, en gramos', (t) async {
    pantallaGrande(t);
    final api = _MockApi();
    when(() => api.getComponentesReceta()).thenAnswer((_) async => [caja]);
    when(() => api.getProducts()).thenAnswer((_) async => []);
    when(() => api.getCategorias()).thenAnswer((_) async => const [Categoria(id: 7, nombre: 'Tortas')]);
    when(() => api.getRecetas()).thenAnswer((_) async => const <Receta>[]);
    await t.pumpWidget(MaterialApp(home: RecetasScreen(recetasBloc: RecetasBloc(apiService: api))));
    await t.pumpAndSettle();

    Future<void> tocar(Finder f) async {
      await t.ensureVisible(f);
      await t.pumpAndSettle();
      await t.tap(f);
      await t.pumpAndSettle();
    }

    await tocar(find.text('Nueva Receta'));
    await tocar(find.byKey(const Key('agregar_insumo_fila_button')));
    await tocar(find.byKey(const Key('selector_insumo_fila_0')));
    await tocar(find.text('Caja de chocolate amargo 100 g (RMP-0001)').last);
    await t.enterText(find.byKey(const Key('cantidad_insumo_fila_0')), '150');
    await t.pumpAndSettle();

    // 150 g × $22,50 = $3.375.
    expect(t.widget<Text>(find.byKey(const Key('costo_total_receta'))).data, '\$ 3.375,00');
  });
}
