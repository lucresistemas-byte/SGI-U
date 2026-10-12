import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sgi_u_frontend/blocs/recetas/recetas_bloc.dart';
import 'package:sgi_u_frontend/blocs/recetas/recetas_event.dart';
import 'package:sgi_u_frontend/blocs/recetas/recetas_state.dart';
import 'package:sgi_u_frontend/models/insumo.dart';
import 'package:sgi_u_frontend/models/receta.dart';
import 'package:sgi_u_frontend/models/receta_detalle.dart';
import 'package:sgi_u_frontend/screens/recetas_screen.dart';
import 'package:sgi_u_frontend/services/api_service.dart';

class _MockApi extends Mock implements ApiService {}

/// Problema 2 del Armador: las filas nuevas repetían el primer insumo y
/// cambiar el insumo de una fila la mandaba al final, así que se enviaban
/// insumos repetidos ("duplicado") aunque en pantalla se vieran distintos.
void main() {
  const arroz = Insumo(id: 1, codigo: 'MP-001', nombre: 'Arroz', costoUnitario: 35, unidadMedida: 'KILO');
  const bolsa = Insumo(id: 2, codigo: 'MP-002', nombre: 'Bolsa', costoUnitario: 5, unidadMedida: 'UNIDAD');
  const etiqueta = Insumo(id: 3, codigo: 'MP-003', nombre: 'Etiqueta', costoUnitario: 2.5, unidadMedida: 'UNIDAD');

  late _MockApi api;

  setUp(() {
    api = _MockApi();
    registerFallbackValue(<String, dynamic>{});
    when(() => api.getInsumos()).thenAnswer((_) async => [arroz, bolsa, etiqueta]);
    when(() => api.getProducts()).thenAnswer((_) async => [
          {'codigo': 'DUL-001', 'nombre': 'Flan', 'precioUnitario': 10, 'stockActual': 1, 'activo': true}
        ]);
    when(() => api.getRecetas(incluirInactivas: any(named: 'incluirInactivas')))
        .thenAnswer((_) async => []);
    when(() => api.createReceta(any())).thenAnswer(
        (_) async => const Receta(id: 9, espProductoCodigo: 'DUL-001', nombre: 'x'));
  });

  Future<RecetasBloc> montar(WidgetTester t) async {
    t.view.physicalSize = const Size(1400, 1400);
    t.view.devicePixelRatio = 1.0;
    addTearDown(t.view.reset);
    final bloc = RecetasBloc(apiService: api);
    await t.pumpWidget(MaterialApp(home: RecetasScreen(recetasBloc: bloc, initialBuildingMode: true)));
    await t.pumpAndSettle();
    return bloc;
  }

  Future<void> agregar(WidgetTester t) async {
    await t.tap(find.byKey(const Key('agregar_insumo_fila_button')));
    await t.pumpAndSettle();
  }

  List<String?> nombres(RecetasBloc b) => b.state.detalles.map((d) => d.materiaPrimaNombre).toList();

  List<String> opcionesDeLaFila(WidgetTester t, int fila) => t
      .widget<DropdownButton<int>>(find.descendant(
          of: find.byKey(Key('selector_insumo_fila_$fila')),
          matching: find.byType(DropdownButton<int>)))
      .items!
      .map((i) => ((i.child as Text).data ?? ''))
      .toList();

  testWidgets('cada fila nueva usa un insumo todavía no usado', (t) async {
    final bloc = await montar(t);

    await agregar(t);
    await agregar(t);
    await agregar(t);

    // Antes: [Arroz, Arroz, Arroz].
    expect(nombres(bloc), ['Arroz', 'Bolsa', 'Etiqueta']);

    await agregar(t);
    expect(nombres(bloc), hasLength(3));
    expect(find.text('Todos los insumos disponibles ya están en la receta.'), findsOneWidget);
  });

  testWidgets('el dropdown no ofrece los insumos de otras filas', (t) async {
    await montar(t);
    await agregar(t);
    await agregar(t);

    expect(opcionesDeLaFila(t, 0), ['Arroz (MP-001)', 'Etiqueta (MP-003)']);
    expect(opcionesDeLaFila(t, 1), ['Bolsa (MP-002)', 'Etiqueta (MP-003)']);
  });

  testWidgets('cambiar el insumo de una fila lo reemplaza en su lugar y conserva la cantidad',
      (t) async {
    final bloc = await montar(t);
    await agregar(t);
    await agregar(t);
    bloc.add(const ActualizarCantidadFilaInsumo(index: 0, cantidad: 0.25));
    await t.pumpAndSettle();

    await t.tap(find.byKey(const Key('selector_insumo_fila_0')));
    await t.pumpAndSettle();
    await t.tap(find.text('Etiqueta (MP-003)').last);
    await t.pumpAndSettle();

    // Antes: la fila se iba al final -> [Bolsa, Etiqueta].
    expect(nombres(bloc), ['Etiqueta', 'Bolsa']);
    expect(bloc.state.detalles.first.cantidad, 0.25);
    expect(find.text('Etiqueta (MP-003)'), findsOneWidget);
  });

  group('RecetasBloc', () {
    blocTest<RecetasBloc, RecetasState>(
      'guardar con un insumo repetido muestra un error claro y no llama a la API',
      build: () => RecetasBloc(apiService: api),
      seed: () => RecetasState.initial().copyWith(
        selectedProductoCodigo: 'DUL-001',
        nombre: 'Flan',
        detalles: const [
          RecetaDetalle(materiaPrimaId: 1, materiaPrimaNombre: 'Arroz', cantidad: 1, unidadMedida: 'KILO'),
          RecetaDetalle(materiaPrimaId: 1, materiaPrimaNombre: 'Arroz', cantidad: 2, unidadMedida: 'KILO'),
        ],
      ),
      act: (b) => b.add(const GuardarReceta()),
      expect: () => [
        isA<RecetasState>().having(
            (s) => s.errorMessage, 'error', 'El insumo Arroz está dos veces en la receta.'),
      ],
      verify: (_) => verifyNever(() => api.createReceta(any())),
    );
  });
}
