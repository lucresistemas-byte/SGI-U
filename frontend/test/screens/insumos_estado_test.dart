import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sgi_u_frontend/blocs/insumos/insumos_bloc.dart';
import 'package:sgi_u_frontend/blocs/insumos/insumos_event.dart';
import 'package:sgi_u_frontend/blocs/insumos/insumos_state.dart';
import 'package:sgi_u_frontend/blocs/recetas/recetas_bloc.dart';
import 'package:sgi_u_frontend/blocs/recetas/recetas_event.dart';
import 'package:sgi_u_frontend/blocs/recetas/recetas_state.dart';
import 'package:sgi_u_frontend/models/insumo.dart';
import 'package:sgi_u_frontend/models/receta.dart';
import 'package:sgi_u_frontend/models/receta_detalle.dart';
import 'package:sgi_u_frontend/screens/insumos_screen.dart';
import 'package:sgi_u_frontend/screens/recetas_screen.dart';
import 'package:sgi_u_frontend/services/api_service.dart';

class _MockInsumosBloc extends MockBloc<InsumosEvent, InsumosState>
    implements InsumosBloc {}

class _MockRecetasBloc extends MockBloc<RecetasEvent, RecetasState>
    implements RecetasBloc {}

class _MockApi extends Mock implements ApiService {}

class _FakeInsumosEvent extends Fake implements InsumosEvent {}

/// E-8: los insumos no se eliminan; se desactivan (avisando en qué recetas
/// activas se usan), se ven atenuados y se pueden reactivar y editar.
void main() {
  setUpAll(() => registerFallbackValue(_FakeInsumosEvent()));

  const harina = Insumo(id: 4, codigo: 'HAR', nombre: 'Harina', costoUnitario: 1000, unidadMedida: 'KILO');
  const huevo = Insumo(
      id: 6, codigo: 'HUE', nombre: 'Huevo', costoUnitario: 250, unidadMedida: 'UNIDAD', activo: false);

  void escritorio(WidgetTester tester) {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }

  group('pantalla de Materia Prima', () {
    late _MockInsumosBloc bloc;

    Future<void> tocar(WidgetTester tester, String key) async {
      await tester.ensureVisible(find.byKey(Key(key)));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(Key(key)));
      await tester.pumpAndSettle();
    }

    Future<void> montar(WidgetTester tester) async {
      escritorio(tester);
      bloc = _MockInsumosBloc();
      whenListen(bloc, const Stream<InsumosState>.empty(),
          initialState: const InsumosLoaded(insumos: [harina, huevo]));
      await tester.pumpWidget(MaterialApp(home: InsumosScreen(insumosBloc: bloc)));
      await tester.pump();
    }

    testWidgets('el inactivo se marca, se puede editar y reactivar', (tester) async {
      await montar(tester);

      expect(find.text('Inactivo'), findsOneWidget);
      expect(find.byKey(const Key('editar_insumo_HUE')), findsOneWidget);
      expect(find.byKey(const Key('desactivar_insumo_HAR')), findsOneWidget);

      await tocar(tester, 'activar_insumo_HUE');
      verify(() => bloc.add(const CambiarEstadoInsumoEvent(6, activo: true))).called(1);
    });

    testWidgets('desactivar avisa en qué recetas activas se usa y pide confirmar',
        (tester) async {
      await montar(tester);
      when(() => bloc.recetasActivasQueUsan(4))
          .thenAnswer((_) async => ['Torta base', 'Budín']);

      await tocar(tester, 'desactivar_insumo_HAR');

      expect(find.textContaining('Torta base, Budín'), findsOneWidget);
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      verifyNever(() => bloc.add(any(that: isA<CambiarEstadoInsumoEvent>())));

      await tocar(tester, 'desactivar_insumo_HAR');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Desactivar'));
      await tester.pumpAndSettle();
      verify(() => bloc.add(const CambiarEstadoInsumoEvent(4, activo: false))).called(1);
    });
  });

  group('InsumosBloc', () {
    late _MockApi api;

    setUp(() {
      api = _MockApi();
      when(() => api.getInsumos(incluirInactivos: any(named: 'incluirInactivos')))
          .thenAnswer((_) async => [harina, huevo]);
      when(() => api.cambiarEstadoInsumo(any(), activo: any(named: 'activo')))
          .thenAnswer((_) async => harina);
    });

    blocTest<InsumosBloc, InsumosState>(
      'lista también los inactivos',
      build: () => InsumosBloc(apiService: api),
      act: (b) => b.add(const CargarInsumos()),
      verify: (_) => verify(() => api.getInsumos(incluirInactivos: true)).called(1),
    );

    blocTest<InsumosBloc, InsumosState>(
      'desactivar llama al PATCH de estado y recarga',
      build: () => InsumosBloc(apiService: api),
      act: (b) => b.add(const CambiarEstadoInsumoEvent(4, activo: false)),
      wait: const Duration(milliseconds: 10),
      verify: (_) => verify(() => api.cambiarEstadoInsumo(4, activo: false)).called(1),
    );

    test('recetasActivasQueUsan devuelve las recetas que tienen el insumo', () async {
      when(() => api.getRecetas()).thenAnswer((_) async => const [
            Receta(id: 1, espProductoCodigo: 'T', nombre: 'Torta base', detalles: [
              RecetaDetalle(articuloId: 4, cantidad: 0.2, unidadMedida: 'KILO'),
            ]),
            Receta(id: 2, espProductoCodigo: 'F', nombre: 'Flan', detalles: [
              RecetaDetalle(articuloId: 6, cantidad: 3, unidadMedida: 'UNIDAD'),
            ]),
          ]);

      expect(await InsumosBloc(apiService: api).recetasActivasQueUsan(4), ['Torta base']);
    });
  });

  testWidgets(
      'editar una receta con un insumo desactivado lo muestra fijo y no rompe el dropdown',
      (tester) async {
    escritorio(tester);
    final bloc = _MockRecetasBloc();
    whenListen(
      bloc,
      const Stream<RecetasState>.empty(),
      initialState: RecetasState.initial().copyWith(
        availableInsumos: const [harina],
        selectedProductoCodigo: 'T',
        nombre: 'Torta',
        detalles: const [
          RecetaDetalle(
              articuloId: 6, articuloNombre: 'Huevo', cantidad: 3, unidadMedida: 'UNIDAD'),
        ],
      ),
    );

    await tester.pumpWidget(MaterialApp(
        home: RecetasScreen(recetasBloc: bloc, initialBuildingMode: true)));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('Huevo (desactivado)'), findsOneWidget);
  });
}
