import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sgi_u_frontend/blocs/recetas/recetas_bloc.dart';
import 'package:sgi_u_frontend/blocs/recetas/recetas_event.dart';
import 'package:sgi_u_frontend/blocs/recetas/recetas_state.dart';
import 'package:sgi_u_frontend/screens/recetas_screen.dart';

class _MockRecetasBloc extends MockBloc<RecetasEvent, RecetasState>
    implements RecetasBloc {}

class _FakeEvent extends Fake implements RecetasEvent {}

/// E-16: sin insumos cargados, "Agregar Insumo" avisaba nada y agregaba una
/// fila con un insumo ficticio (id 1, "INS-001") que se guardaba contra otro
/// insumo real.
void main() {
  setUpAll(() => registerFallbackValue(_FakeEvent()));

  testWidgets('sin insumos, "Agregar Insumo" muestra un aviso y no agrega filas',
      (tester) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final bloc = _MockRecetasBloc();
    whenListen(bloc, const Stream<RecetasState>.empty(),
        initialState: RecetasState.initial().copyWith(availableInsumos: const []));

    await tester.pumpWidget(MaterialApp(
        home: RecetasScreen(recetasBloc: bloc, initialBuildingMode: true)));
    await tester.pump();

    await tester.tap(find.byKey(const Key('agregar_insumo_fila_button')));
    await tester.pump();

    verifyNever(() => bloc.add(any(that: isA<AgregarFilaInsumo>())));
    verifyNever(() => bloc.add(any(that: isA<AgregarFilaVacia>())));
    expect(
        find.text('No hay insumos activos. Cárguelos en Materia Prima antes de armar la receta.'),
        findsOneWidget);
  });
}
