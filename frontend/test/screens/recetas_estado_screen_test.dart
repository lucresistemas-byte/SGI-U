import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sgi_u_frontend/blocs/recetas/recetas_bloc.dart';
import 'package:sgi_u_frontend/blocs/recetas/recetas_event.dart';
import 'package:sgi_u_frontend/blocs/recetas/recetas_state.dart';
import 'package:sgi_u_frontend/models/receta.dart';
import 'package:sgi_u_frontend/screens/recetas_screen.dart';

class _MockRecetasBloc extends MockBloc<RecetasEvent, RecetasState>
    implements RecetasBloc {}

class _FakeEvent extends Fake implements RecetasEvent {}

/// E-6: en la lista de recetas no hay "Eliminar", solo Activar/Desactivar.
void main() {
  setUpAll(() => registerFallbackValue(_FakeEvent()));

  late _MockRecetasBloc bloc;

  const activa = Receta(id: 1, espProductoCodigo: 'T1', espProductoNombre: 'Torta', nombre: 'Torta base');
  const inactiva = Receta(
      id: 2, espProductoCodigo: 'B1', espProductoNombre: 'Budín', nombre: 'Budín base', activo: false);

  Future<void> montar(WidgetTester tester, RecetasState estado,
      {Stream<RecetasState>? cambios}) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    bloc = _MockRecetasBloc();
    whenListen(bloc, cambios ?? const Stream<RecetasState>.empty(), initialState: estado);
    await tester.pumpWidget(MaterialApp(home: RecetasScreen(recetasBloc: bloc)));
    await tester.pump();
  }

  final lista = RecetasState.initial().copyWith(recetas: const [activa, inactiva]);

  testWidgets('no hay botón de eliminar; la inactiva se marca y se puede activar',
      (tester) async {
    await montar(tester, lista);

    expect(find.byKey(const Key('eliminar_receta_1')), findsNothing);
    expect(find.byIcon(Icons.delete_outline), findsNothing);
    expect(find.byKey(const Key('desactivar_receta_1')), findsOneWidget);
    expect(find.byKey(const Key('activar_receta_2')), findsOneWidget);
    expect(find.text('Inactiva'), findsOneWidget);

    await tester.tap(find.byKey(const Key('activar_receta_2')));
    verify(() => bloc.add(const CambiarEstadoReceta(2, activo: true))).called(1);
  });

  testWidgets('desactivar pide confirmación y no hace nada si se cancela',
      (tester) async {
    await montar(tester, lista);

    await tester.tap(find.byKey(const Key('desactivar_receta_1')));
    await tester.pumpAndSettle();
    expect(find.text('Desactivar receta'), findsOneWidget);

    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    verifyNever(() => bloc.add(any(that: isA<CambiarEstadoReceta>())));

    await tester.tap(find.byKey(const Key('desactivar_receta_1')));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ElevatedButton, 'Desactivar'));
    await tester.pumpAndSettle();
    verify(() => bloc.add(const CambiarEstadoReceta(1, activo: false))).called(1);
  });

  testWidgets('si el producto ya tiene una receta desactivada, ofrece reactivarla',
      (tester) async {
    final conflicto = lista.copyWith(
      recetaInactivaExistenteId: 2,
      recetaInactivaExistenteMensaje:
          'El producto Budín ya tiene una receta desactivada (Budín base). Puede reactivarla y editarla.',
    );
    await montar(tester, lista, cambios: Stream.value(conflicto));
    await tester.pumpAndSettle();

    expect(find.text('Receta desactivada'), findsOneWidget);
    await tester.tap(find.text('Reactivar con estos datos'));
    await tester.pumpAndSettle();

    verify(() => bloc.add(const ReactivarRecetaConDatos(2))).called(1);
  });
}
