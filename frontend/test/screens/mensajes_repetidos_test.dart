import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sgi_u_frontend/blocs/pedidos/pedidos_bloc.dart';
import 'package:sgi_u_frontend/blocs/pedidos/pedidos_event.dart';
import 'package:sgi_u_frontend/blocs/pedidos/pedidos_state.dart';
import 'package:sgi_u_frontend/blocs/recetas/recetas_bloc.dart';
import 'package:sgi_u_frontend/blocs/recetas/recetas_event.dart';
import 'package:sgi_u_frontend/blocs/recetas/recetas_state.dart';
import 'package:sgi_u_frontend/screens/pedidos_screen.dart';
import 'package:sgi_u_frontend/screens/recetas_screen.dart';

class _MockRecetasBloc extends MockBloc<RecetasEvent, RecetasState> implements RecetasBloc {}

class _MockPedidosBloc extends MockBloc<PedidosEvent, PedidosState> implements PedidosBloc {}

class _FakeRecetasEvent extends Fake implements RecetasEvent {}

class _FakePedidosEvent extends Fake implements PedidosEvent {}

/// Problema 3: el mensaje de éxito (o de error) se volvía a mostrar con cada
/// estado nuevo mientras seguía puesto (guardar -> recargar lista = 3 avisos).
void main() {
  setUpAll(() {
    registerFallbackValue(_FakeRecetasEvent());
    registerFallbackValue(_FakePedidosEvent());
  });

  /// Cuenta los SnackBar que se encolaron, cerrándolos de a uno.
  ///
  /// `AppSnackBar` arma el contenido como `Row(Icon, Text)`, así que el mensaje
  /// se toma del `Text` descendiente en vez de castear `content` directo.
  Future<List<String>> snackbarsMostrados(WidgetTester tester) async {
    final textos = <String>[];
    final messenger = tester.state<ScaffoldMessengerState>(find.byType(ScaffoldMessenger));
    for (var i = 0; i < 10; i++) {
      await tester.pump();
      final snack = find.byType(SnackBar);
      if (snack.evaluate().isEmpty) break;
      final texto = find.descendant(of: snack.first, matching: find.byType(Text));
      textos.add(tester.widget<Text>(texto.first).data ?? '');
      messenger.removeCurrentSnackBar();
      await tester.pump();
    }
    return textos;
  }

  void escritorio(WidgetTester tester) {
    tester.view.physicalSize = const Size(1600, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }

  testWidgets('Recetas: guardar y recargar muestra el éxito una sola vez', (tester) async {
    escritorio(tester);
    final bloc = _MockRecetasBloc();
    final base = RecetasState.initial();
    final exito = base.copyWith(successMessage: 'Receta creada exitosamente');
    whenListen(
      bloc,
      Stream.fromIterable([
        exito,
        exito.copyWith(isLoading: true), // CargarRecetas
        exito.copyWith(isLoading: false), // lista recargada
      ]),
      initialState: base,
    );

    await tester.pumpWidget(MaterialApp(home: RecetasScreen(recetasBloc: bloc)));

    expect(await snackbarsMostrados(tester), ['Receta creada exitosamente']);
    verify(() => bloc.add(const LimpiarMensajesRecetas())).called(1);
  });

  testWidgets('Recetas: un error no se repite con los estados siguientes', (tester) async {
    escritorio(tester);
    final bloc = _MockRecetasBloc();
    final base = RecetasState.initial();
    final error = base.copyWith(errorMessage: 'El insumo Arroz está dos veces en la receta.');
    whenListen(
      bloc,
      Stream.fromIterable([error, error.copyWith(nombre: 'T'), error.copyWith(nombre: 'To')]),
      initialState: base,
    );

    await tester.pumpWidget(MaterialApp(home: RecetasScreen(recetasBloc: bloc)));

    expect(await snackbarsMostrados(tester), ['El insumo Arroz está dos veces en la receta.']);
  });

  testWidgets('Pedidos: crear y recargar muestra el éxito una sola vez', (tester) async {
    escritorio(tester);
    final bloc = _MockPedidosBloc();
    const base = PedidosState();
    final exito = base.copyWith(successMessage: 'Pedido registrado con éxito');
    whenListen(
      bloc,
      Stream.fromIterable([
        exito,
        exito.copyWith(isLoading: true), // CargarPedidos
        exito.copyWith(isLoading: false),
      ]),
      initialState: base,
    );

    await tester.pumpWidget(MaterialApp(home: PedidosScreen(pedidosBloc: bloc)));

    expect(await snackbarsMostrados(tester), ['Pedido registrado con éxito']);
  });
}
