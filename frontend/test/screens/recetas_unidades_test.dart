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

/// Etapa 2: en el armador, la unidad de cada fila es de la familia del
/// insumo (por defecto la más chica) y se ven costo por porción y precio.
void main() {
  const harina = Insumo(id: 1, codigo: 'MP-1', nombre: 'Harina', costoUnitario: 1200, unidadMedida: 'KILO', costoUnidadBase: 1.2);
  late _MockApi api;

  setUp(() {
    api = _MockApi();
    registerFallbackValue(<String, dynamic>{});
    when(() => api.getComponentesReceta()).thenAnswer((_) async => [harina]);
    when(() => api.getProducts()).thenAnswer((_) async => []);
    when(() => api.getCategorias()).thenAnswer((_) async => const [Categoria(id: 7, nombre: 'Tortas')]);
    when(() => api.getRecetas()).thenAnswer((_) async => const <Receta>[]);
    when(() => api.createReceta(any())).thenAnswer((_) async => const Receta(id: 9, espProductoCodigo: 'ELA-1', nombre: 'x'));
  });

  Future<void> tocar(WidgetTester t, Finder f) async {
    await t.ensureVisible(f);
    await t.pumpAndSettle();
    await t.tap(f);
    await t.pumpAndSettle();
  }

  String texto(WidgetTester t, String key) => t.widget<Text>(find.byKey(Key(key))).data!;

  testWidgets('unidad por familia, rinde y precio en vivo', (t) async {
    t.view.physicalSize = const Size(1500, 1800);
    t.view.devicePixelRatio = 1.0;
    addTearDown(t.view.reset);
    await t.pumpWidget(MaterialApp(home: RecetasScreen(recetasBloc: RecetasBloc(apiService: api))));
    await t.pumpAndSettle();
    await tocar(t, find.text('Nueva Receta'));

    await t.enterText(find.byKey(const Key('nuevo_producto_porcentaje')), '100');
    await tocar(t, find.byKey(const Key('agregar_insumo_fila_button')));
    await tocar(t, find.byKey(const Key('selector_insumo_fila_0')));
    await tocar(t, find.text('Harina (MP-1)').last);

    // Por defecto la unidad más chica de la familia; ofrece solo peso.
    await tocar(t, find.byKey(const Key('unidad_insumo_fila_0')));
    expect(find.text('Gramo'), findsWidgets);
    expect(find.text('Kilo'), findsWidgets);
    expect(find.text('Litro'), findsNothing);
    await tocar(t, find.text('Gramo').last);

    await t.enterText(find.byKey(const Key('cantidad_insumo_fila_0')), '200');
    await t.pumpAndSettle();
    expect(texto(t, 'costo_total_receta'), '\$ 240,00');
    expect(texto(t, 'costo_por_unidad_receta'), '—');
    expect(find.byKey(const Key('aviso_rinde')), findsOneWidget);

    await t.enterText(find.byKey(const Key('input_rinde')), '8');
    await t.pumpAndSettle();
    expect(texto(t, 'costo_por_unidad_receta'), '\$ 30,00');
    expect(texto(t, 'porcentaje_ganancia_receta'), '100 %');
    expect(texto(t, 'precio_resultante_receta'), '\$ 100,00'); // $ 60 → hacia arriba a $ 100
    expect(texto(t, 'ganancia_resultante_receta'), '\$ 70,00');
    expect(find.text('Costo por porción'), findsOneWidget);

    // Cambiar a kilo con la misma cantidad multiplica el costo.
    await tocar(t, find.byKey(const Key('unidad_insumo_fila_0')));
    await tocar(t, find.text('Kilo').last);
    await t.enterText(find.byKey(const Key('cantidad_insumo_fila_0')), '0,2');
    await t.pumpAndSettle();
    expect(texto(t, 'costo_total_receta'), '\$ 240,00');
  });
}
