import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sgi_u_frontend/blocs/recetas/recetas_bloc.dart';
import 'package:sgi_u_frontend/blocs/recetas/recetas_event.dart';
import 'package:sgi_u_frontend/blocs/recetas/recetas_state.dart';
import 'package:sgi_u_frontend/models/insumo.dart';
import 'package:sgi_u_frontend/models/receta_detalle.dart';
import 'package:sgi_u_frontend/screens/recetas_screen.dart';

class _MockRecetasBloc extends MockBloc<RecetasEvent, RecetasState> implements RecetasBloc {}

class _FakeEvent extends Fake implements RecetasEvent {}

/// Corrección 7: el título del armador y "Guardar receta" quedan fijos
/// arriba aunque se desplace una receta larga.
void main() {
  setUpAll(() => registerFallbackValue(_FakeEvent()));

  testWidgets('al desplazar el armador, el encabezado sigue a la vista', (t) async {
    t.view.physicalSize = const Size(1200, 700);
    t.view.devicePixelRatio = 1.0;
    addTearDown(t.view.reset);

    final insumos = [
      for (var i = 1; i <= 12; i++)
        Insumo(id: i, codigo: 'MP-$i', nombre: 'Insumo $i', costoUnitario: 10, unidadMedida: 'KILO'),
    ];
    final bloc = _MockRecetasBloc();
    whenListen(bloc, const Stream<RecetasState>.empty(),
        initialState: RecetasState.initial().copyWith(
          availableInsumos: insumos,
          detalles: [
            for (final i in insumos)
              RecetaDetalle(
                  materiaPrimaId: i.id!, materiaPrimaNombre: i.nombre, cantidad: 1, unidadMedida: 'KILO', claveUi: i.id),
          ],
        ));
    await t.pumpWidget(MaterialApp(home: RecetasScreen(recetasBloc: bloc, initialBuildingMode: true)));
    await t.pump();

    final guardar = find.byKey(const Key('guardar_receta_button'));
    final antes = t.getTopLeft(guardar);
    expect(find.text('Armado de receta'), findsOneWidget);

    await t.drag(find.byKey(const Key('armador_scroll')), const Offset(0, -2000));
    await t.pump();

    // El contenido se desplazó (la primera fila ya no se ve) ...
    expect(find.byKey(const Key('fila_insumo_0')).hitTestable(), findsNothing);
    // ... pero el título y el botón siguen en el mismo lugar.
    expect(t.getTopLeft(guardar), antes);
    expect(guardar.hitTestable(), findsOneWidget);
    expect(find.text('Armado de receta').hitTestable(), findsOneWidget);
  });
}
