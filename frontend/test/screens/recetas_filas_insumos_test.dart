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
    when(() => api.getRecetas())
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

  Future<void> elegir(WidgetTester t, int fila, String opcion) async {
    await t.tap(find.byKey(Key('selector_insumo_fila_$fila')));
    await t.pumpAndSettle();
    await t.tap(find.text(opcion).last);
    await t.pumpAndSettle();
  }

  testWidgets('cada fila nueva llega vacía y ofrece solo los insumos no usados', (t) async {
    final bloc = await montar(t);

    await agregar(t);
    // Antes: la fila llegaba con el primer insumo libre y cantidad 1.
    expect(bloc.state.detalles.single.sinInsumo, isTrue);
    expect(bloc.state.detalles.single.cantidad, 0);
    expect(find.text('Elegir insumo'), findsOneWidget);
    expect(opcionesDeLaFila(t, 0), ['Arroz (MP-001)', 'Bolsa (MP-002)', 'Etiqueta (MP-003)']);

    await elegir(t, 0, 'Arroz (MP-001)');
    await agregar(t);
    expect(opcionesDeLaFila(t, 1), ['Bolsa (MP-002)', 'Etiqueta (MP-003)']);
    await elegir(t, 1, 'Bolsa (MP-002)');
    await agregar(t);
    await elegir(t, 2, 'Etiqueta (MP-003)');
    expect(nombres(bloc), ['Arroz', 'Bolsa', 'Etiqueta']);

    await agregar(t);
    expect(nombres(bloc), hasLength(3));
    expect(find.text('Todos los insumos disponibles ya están en la receta.'), findsOneWidget);
  });

  testWidgets('el dropdown no ofrece los insumos de otras filas', (t) async {
    await montar(t);
    await agregar(t);
    await elegir(t, 0, 'Bolsa (MP-002)');
    await agregar(t);
    await elegir(t, 1, 'Arroz (MP-001)');

    expect(opcionesDeLaFila(t, 0), ['Bolsa (MP-002)', 'Etiqueta (MP-003)']);
    expect(opcionesDeLaFila(t, 1), ['Arroz (MP-001)', 'Etiqueta (MP-003)']);
  });

  testWidgets('cambiar el insumo de una fila lo reemplaza en su lugar y conserva la cantidad',
      (t) async {
    final bloc = await montar(t);
    await agregar(t);
    await elegir(t, 0, 'Arroz (MP-001)');
    await agregar(t);
    await elegir(t, 1, 'Bolsa (MP-002)');
    await t.enterText(find.byKey(const Key('cantidad_insumo_fila_0')), '0.25');
    await t.pumpAndSettle();

    await elegir(t, 0, 'Etiqueta (MP-003)');

    expect(nombres(bloc), ['Etiqueta', 'Bolsa']);
    expect(bloc.state.detalles.first.cantidad, 0.25);
    expect(find.text('Etiqueta (MP-003)'), findsOneWidget);
  });

  testWidgets('con filas incompletas no se puede guardar y se explica por qué', (t) async {
    final bloc = await montar(t);
    await agregar(t);
    await t.pumpAndSettle();

    Finder guardar() => find.byKey(const Key('guardar_receta_button'));
    expect(t.widget<ElevatedButton>(guardar()).onPressed, isNull);
    expect(find.byKey(const Key('aviso_filas_incompletas')), findsOneWidget);

    // Con insumo pero sin cantidad sigue incompleta.
    await elegir(t, 0, 'Arroz (MP-001)');
    expect(bloc.state.hayFilasIncompletas, isTrue);
    expect(find.byKey(const Key('aviso_filas_incompletas')), findsOneWidget);

    await t.enterText(find.byKey(const Key('cantidad_insumo_fila_0')), '2');
    await t.pumpAndSettle();
    expect(find.byKey(const Key('aviso_filas_incompletas')), findsNothing);
  });

  testWidgets('cada fila conserva su clave al quitar la de arriba', (t) async {
    final bloc = await montar(t);
    await agregar(t);
    await elegir(t, 0, 'Arroz (MP-001)');
    await agregar(t);
    await elegir(t, 1, 'Bolsa (MP-002)');
    final claveBolsa = bloc.state.detalles[1].claveUi;
    expect(bloc.state.detalles[0].claveUi, isNot(claveBolsa));

    await t.tap(find.byKey(const Key('eliminar_insumo_fila_0')));
    await t.pumpAndSettle();

    expect(bloc.state.detalles.single.claveUi, claveBolsa);
    expect(find.byKey(ValueKey('fila_insumo_$claveBolsa')), findsOneWidget);
    expect(find.text('Bolsa (MP-002)'), findsOneWidget);
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

    blocTest<RecetasBloc, RecetasState>(
      'guardar con una fila sin insumo muestra un error claro y no llama a la API',
      build: () => RecetasBloc(apiService: api),
      seed: () => RecetasState.initial().copyWith(
        selectedProductoCodigo: 'DUL-001',
        nombre: 'Flan',
        detalles: const [
          RecetaDetalle(materiaPrimaId: 1, materiaPrimaNombre: 'Arroz', cantidad: 1, unidadMedida: 'KILO'),
          RecetaDetalle(materiaPrimaId: 0, cantidad: 0, unidadMedida: ''),
        ],
      ),
      act: (b) => b.add(const GuardarReceta()),
      expect: () => [
        isA<RecetasState>()
            .having((s) => s.errorMessage, 'error', RecetasState.mensajeFilasIncompletas),
      ],
      verify: (_) => verifyNever(() => api.createReceta(any())),
    );

    blocTest<RecetasBloc, RecetasState>(
      'AgregarFilaVacia agrega una fila sin insumo con clave propia',
      build: () => RecetasBloc(apiService: api),
      act: (b) => b
        ..add(const AgregarFilaVacia())
        ..add(const AgregarFilaVacia()),
      skip: 1,
      expect: () => [
        isA<RecetasState>().having((s) => s.detalles.map((d) => d.sinInsumo).toList(), 'vacías',
            [true, true]).having((s) => s.detalles.map((d) => d.claveUi).toSet().length,
            'claves distintas', 2),
      ],
    );
  });
}
