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

/// Etapa 2: stock en unidad base mostrado amigable y ajuste en cualquier unidad.
void main() {
  setUpAll(() => registerFallbackValue(_FakeEvent()));

  const harina = Insumo(
      id: 1, codigo: 'MP-0001', nombre: 'Harina', costoUnitario: 1200, unidadMedida: 'KILO',
      costoUnidadBase: 1.2, stockActual: 2500, stockMinimo: 5000);

  testWidgets('la tabla muestra 2,5 kg y el ajuste se envía en la unidad elegida', (t) async {
    t.view.physicalSize = const Size(1400, 900);
    t.view.devicePixelRatio = 1.0;
    addTearDown(t.view.reset);
    final bloc = _MockInsumosBloc();
    when(() => bloc.state).thenReturn(const InsumosLoaded(insumos: [harina]));
    await t.pumpWidget(MaterialApp(home: InsumosScreen(insumosBloc: bloc)));
    await t.pumpAndSettle();

    expect(t.widget<Text>(find.byKey(const Key('stock_insumo_MP-0001'))).data, '2,5 kg');
    expect(find.text('5 kg'), findsOneWidget); // stock mínimo
    expect(t.widget<Text>(find.byKey(const Key('costo_insumo_MP-0001'))).data, contains('/ kg'));

    await t.ensureVisible(find.byKey(const Key('ajustar_stock_MP-0001')));
    await t.tap(find.byKey(const Key('ajustar_stock_MP-0001')));
    await t.pumpAndSettle();
    expect(find.text('Stock actual: 2,5 kg'), findsOneWidget);

    await t.enterText(find.byKey(const Key('ajuste_cantidad_input')), '500');
    await t.tap(find.byKey(const Key('ajuste_unidad_dropdown')));
    await t.pumpAndSettle();
    expect(find.text('Litro'), findsNothing);
    await t.tap(find.text('Gramo').last);
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('confirmar_ajuste_button')));
    await t.pumpAndSettle();

    verify(() => bloc.add(const AjustarStockInsumoEvent(
        id: 1, cantidad: 500, unidad: 'GRAMO', motivo: 'Ajuste manual de stock'))).called(1);
  });
}
