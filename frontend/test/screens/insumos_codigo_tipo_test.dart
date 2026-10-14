import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sgi_u_frontend/blocs/insumos/insumos_bloc.dart';
import 'package:sgi_u_frontend/blocs/insumos/insumos_event.dart';
import 'package:sgi_u_frontend/blocs/insumos/insumos_state.dart';
import 'package:sgi_u_frontend/models/insumo.dart';
import 'package:sgi_u_frontend/screens/insumos_screen.dart';

class _MockInsumosBloc extends MockBloc<InsumosEvent, InsumosState> implements InsumosBloc {}

class _FakeEvent extends Fake implements InsumosEvent {}

/// Corrección 9: en Materia Prima el código lo genera el sistema según el
/// tipo elegido (Materia prima, Insumo, Reventa + materia prima).
void main() {
  setUpAll(() => registerFallbackValue(_FakeEvent()));

  const cinta = Insumo(
      id: 9, codigo: 'INS-0002', nombre: 'Cinta', costoUnitario: 300, unidadMedida: 'METRO', tipo: 'INSUMO');

  Future<_MockInsumosBloc> montar(WidgetTester t) async {
    t.view.physicalSize = const Size(1280, 900);
    t.view.devicePixelRatio = 1.0;
    addTearDown(t.view.reset);
    final bloc = _MockInsumosBloc();
    when(() => bloc.state).thenReturn(const InsumosLoaded(insumos: [cinta]));
    await t.pumpWidget(MaterialApp(home: InsumosScreen(insumosBloc: bloc)));
    await t.pumpAndSettle();
    return bloc;
  }

  testWidgets('alta: se elige el tipo y no se envía código', (t) async {
    final bloc = await montar(t);
    await t.tap(find.byKey(const Key('nuevo_insumo_button')));
    await t.pumpAndSettle();

    expect(find.text('El código se genera automáticamente al guardar.'), findsOneWidget);
    await t.enterText(find.byKey(const Key('insumo_nombre_input')), 'Caja para torta');
    await t.enterText(find.byKey(const Key('insumo_presentacion_cantidad_input')), '1');
    await t.enterText(find.byKey(const Key('insumo_presentacion_precio_input')), '900');

    // Sin tipo no se guarda.
    await t.tap(find.byKey(const Key('guardar_insumo_button')));
    await t.pumpAndSettle();
    expect(find.text('Elija el tipo'), findsOneWidget);
    verifyNever(() => bloc.add(any(that: isA<CrearInsumoEvent>())));

    await t.tap(find.byKey(const Key('insumo_tipo_dropdown')));
    await t.pumpAndSettle();
    expect(find.text('Materia prima'), findsWidgets);
    expect(find.text('Reventa + materia prima'), findsWidgets);
    await t.tap(find.text('Insumo').last);
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('guardar_insumo_button')));
    await t.pumpAndSettle();

    final evento = verify(() => bloc.add(captureAny(that: isA<CrearInsumoEvent>()))).captured.single
        as CrearInsumoEvent;
    expect(evento.data['tipo'], 'INSUMO');
    expect(evento.data.containsKey('codigo'), isFalse);
  });

  testWidgets('edición: código y tipo se muestran sin poder cambiarlos', (t) async {
    final bloc = await montar(t);
    await t.ensureVisible(find.byKey(const Key('editar_insumo_INS-0002')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('editar_insumo_INS-0002')));
    await t.pumpAndSettle();

    expect(find.text('Código: INS-0002 · Tipo: Insumo'), findsOneWidget);
    expect(find.byKey(const Key('insumo_tipo_dropdown')), findsNothing);

    await t.tap(find.byKey(const Key('guardar_insumo_button')));
    await t.pumpAndSettle();
    final evento = verify(() => bloc.add(captureAny(that: isA<ActualizarInsumoEvent>()))).captured.single
        as ActualizarInsumoEvent;
    expect(evento.data.containsKey('tipo'), isFalse);
    expect(evento.data.containsKey('codigo'), isFalse);
  });

  test('Insumo lee el tipo', () {
    expect(Insumo.fromJson(const {'codigo': 'RMP-0001', 'tipo': 'REVENTA_MATERIA_PRIMA'}).descripcionTipo,
        'Reventa + materia prima');
    expect(Insumo.fromJson(const {'codigo': 'MP-0001'}).tipo, 'MATERIA_PRIMA');
  });
}
