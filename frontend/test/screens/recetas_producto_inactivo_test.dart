import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sgi_u_frontend/blocs/recetas/recetas_bloc.dart';
import 'package:sgi_u_frontend/blocs/recetas/recetas_event.dart';
import 'package:sgi_u_frontend/blocs/recetas/recetas_state.dart';
import 'package:sgi_u_frontend/models/receta.dart';
import 'package:sgi_u_frontend/screens/recetas_screen.dart';

class _MockRecetasBloc extends MockBloc<RecetasEvent, RecetasState> implements RecetasBloc {}

class _FakeEvent extends Fake implements RecetasEvent {}

/// Corrección 4: las recetas no se activan ni desactivan; siempre se ven. Si
/// el producto elaborado está desactivado (desde Productos), se marca.
void main() {
  setUpAll(() => registerFallbackValue(_FakeEvent()));

  const activa = Receta(id: 1, espProductoCodigo: 'ELA-1', espProductoNombre: 'Tarta de coco', nombre: 'Tarta');
  const deInactivo = Receta(
      id: 2, espProductoCodigo: 'ELA-2', espProductoNombre: 'Budín', nombre: 'Budín base', productoActivo: false);

  late _MockRecetasBloc bloc;

  Future<void> montar(WidgetTester tester, RecetasState estado, {bool armador = false}) async {
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    bloc = _MockRecetasBloc();
    whenListen(bloc, const Stream<RecetasState>.empty(), initialState: estado);
    await tester.pumpWidget(MaterialApp(home: RecetasScreen(recetasBloc: bloc, initialBuildingMode: armador)));
    await tester.pump();
  }

  testWidgets('la lista muestra todas las recetas, marca la de producto inactivo y no tiene activar/desactivar',
      (tester) async {
    await montar(tester, RecetasState.initial().copyWith(recetas: const [activa, deInactivo]));

    expect(find.text('Tarta de coco'), findsOneWidget);
    expect(find.text('Budín'), findsOneWidget);
    expect(find.byKey(const Key('producto_inactivo_chip')), findsOneWidget);
    expect(find.byIcon(Icons.toggle_on), findsNothing);
    expect(find.byIcon(Icons.toggle_off), findsNothing);
    expect(find.byIcon(Icons.delete_outline), findsNothing);
  });

  testWidgets('al editar la receta de un producto inactivo, el armador lo indica', (tester) async {
    await montar(
      tester,
      RecetasState.initial().copyWith(
        editingRecetaId: 2,
        selectedProductoCodigo: 'ELA-2',
        selectedProductoNombre: 'Budín',
        productoEditadoActivo: false,
      ),
      armador: true,
    );

    expect(find.byKey(const Key('producto_inactivo_armador')), findsOneWidget);
  });
}
