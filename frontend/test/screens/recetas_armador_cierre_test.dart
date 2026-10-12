import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sgi_u_frontend/blocs/recetas/recetas_bloc.dart';
import 'package:sgi_u_frontend/blocs/recetas/recetas_event.dart';
import 'package:sgi_u_frontend/blocs/recetas/recetas_state.dart';
import 'package:sgi_u_frontend/models/insumo.dart';
import 'package:sgi_u_frontend/models/product.dart';
import 'package:sgi_u_frontend/models/receta_detalle.dart';
import 'package:sgi_u_frontend/screens/recetas_screen.dart';

class _MockRecetasBloc extends MockBloc<RecetasEvent, RecetasState> implements RecetasBloc {}

class _FakeEvent extends Fake implements RecetasEvent {}

/// Problema E: "Guardar receta" cerraba el armador antes de saber si se
/// guardó; si fallaba, el formulario desaparecía.
void main() {
  setUpAll(() => registerFallbackValue(_FakeEvent()));

  final borrador = RecetasState.initial().copyWith(
    availableProductos: [Product(codigo: 'DUL-001', nombre: 'Flan', precioUnitario: 10, stockActual: 1)],
    availableInsumos: const [Insumo(id: 1, codigo: 'MP-001', nombre: 'Arroz', costoUnitario: 35, unidadMedida: 'KILO')],
    selectedProductoCodigo: 'DUL-001',
    nombre: 'Flan base',
    detalles: const [
      RecetaDetalle(materiaPrimaId: 1, materiaPrimaNombre: 'Arroz', cantidad: 1, unidadMedida: 'KILO'),
    ],
  );

  Future<(_MockRecetasBloc, StreamController<RecetasState>)> montar(WidgetTester t) async {
    t.view.physicalSize = const Size(1400, 1200);
    t.view.devicePixelRatio = 1.0;
    addTearDown(t.view.reset);
    final bloc = _MockRecetasBloc();
    final estados = StreamController<RecetasState>.broadcast();
    addTearDown(estados.close);
    whenListen(bloc, estados.stream, initialState: borrador);
    await t.pumpWidget(MaterialApp(home: RecetasScreen(recetasBloc: bloc, initialBuildingMode: true)));
    await t.pump();
    return (bloc, estados);
  }

  Future<void> guardar(WidgetTester t) async {
    await t.ensureVisible(find.text('Guardar receta'));
    await t.tap(find.text('Guardar receta'));
    await t.pump();
  }

  testWidgets('al guardar, el armador sigue abierto hasta saber el resultado', (t) async {
    final (bloc, _) = await montar(t);

    await guardar(t);

    verify(() => bloc.add(const GuardarReceta())).called(1);
    expect(find.text('Guardar receta'), findsOneWidget);
    expect(find.text('Nueva Receta'), findsNothing);
  });

  testWidgets('si el guardado falla, el armador queda abierto con los datos', (t) async {
    final (_, estados) = await montar(t);
    await guardar(t);

    estados.add(borrador.copyWith(errorMessage: 'El insumo Arroz está dos veces en la receta.'));
    await t.pumpAndSettle();

    expect(find.text('Guardar receta'), findsOneWidget);
    expect(find.text('Arroz (MP-001)'), findsOneWidget);
    expect(find.text('El insumo Arroz está dos veces en la receta.'), findsOneWidget);
  });

  testWidgets('si el guardado sale bien, vuelve a la lista', (t) async {
    final (_, estados) = await montar(t);
    await guardar(t);

    estados.add(borrador.copyWith(successMessage: 'Receta creada exitosamente'));
    await t.pumpAndSettle();

    expect(find.text('Guardar receta'), findsNothing);
    expect(find.text('Nueva Receta'), findsOneWidget);
  });
}
