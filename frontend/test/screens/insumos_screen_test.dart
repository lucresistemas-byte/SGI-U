import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sgi_u_frontend/blocs/insumos/insumos_bloc.dart';
import 'package:sgi_u_frontend/blocs/insumos/insumos_event.dart';
import 'package:sgi_u_frontend/blocs/insumos/insumos_state.dart';
import 'package:sgi_u_frontend/models/insumo.dart';
import 'package:sgi_u_frontend/screens/insumos_screen.dart';

class MockInsumosBloc extends MockBloc<InsumosEvent, InsumosState>
    implements InsumosBloc {}

class FakeInsumosEvent extends Fake implements InsumosEvent {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeInsumosEvent());
  });

  group('InsumosScreen - Listado, Filtro y Diálogos (Tarea 7.5)', () {
    late MockInsumosBloc mockInsumosBloc;

    const testInsumo = Insumo(
      id: 1,
      codigo: 'HAR-001',
      nombre: 'Harina 0000',
      costoUnitario: 150.0,
      unidadMedida: 'KILO',
      stockActual: 20,
      stockMinimo: 10,
    );

    setUp(() {
      mockInsumosBloc = MockInsumosBloc();
    });

    tearDown(() {
      mockInsumosBloc.close();
    });

    testWidgets('Muestra lista de insumos y abre diálogo de nuevo insumo', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      when(() => mockInsumosBloc.state).thenReturn(
        const InsumosLoaded(insumos: [testInsumo]),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: InsumosScreen(insumosBloc: mockInsumosBloc),
        ),
      );
      await tester.pumpAndSettle();

      // Verificar tabla y datos
      expect(find.text('Harina 0000'), findsOneWidget);
      expect(find.text('HAR-001'), findsOneWidget);
      expect(find.text('KILO'), findsOneWidget);

      // Buscar insumo
      final buscarInputFinder = find.byKey(const Key('buscar_insumo_input'));
      expect(buscarInputFinder, findsOneWidget);
      await tester.enterText(buscarInputFinder, 'Harina');
      await tester.pump();
      verify(() => mockInsumosBloc.add(const FiltrarInsumos('Harina'))).called(1);

      // Abrir diálogo de nuevo insumo
      final nuevoBtnFinder = find.byKey(const Key('nuevo_insumo_button'));
      expect(nuevoBtnFinder, findsOneWidget);
      await tester.tap(nuevoBtnFinder);
      await tester.pumpAndSettle();

      expect(find.text('Nuevo Insumo'), findsNWidgets(2));
      expect(find.byKey(const Key('insumo_codigo_input')), findsOneWidget);
      expect(find.byKey(const Key('insumo_nombre_input')), findsOneWidget);
      expect(find.byKey(const Key('insumo_costo_input')), findsOneWidget);
      expect(find.byKey(const Key('guardar_insumo_button')), findsOneWidget);

      // Cerrar diálogo
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      // Abrir diálogo de ajuste de stock
      final ajusteBtnFinder = find.byKey(Key('ajustar_stock_${testInsumo.codigo}'));
      expect(ajusteBtnFinder, findsOneWidget);
      await tester.ensureVisible(ajusteBtnFinder);
      await tester.tap(ajusteBtnFinder);
      await tester.pumpAndSettle();

      expect(find.text('Ajustar Stock: Harina 0000'), findsOneWidget);
      expect(find.byKey(const Key('ajuste_cantidad_input')), findsOneWidget);
      expect(find.byKey(const Key('ajuste_motivo_input')), findsOneWidget);
      expect(find.byKey(const Key('confirmar_ajuste_button')), findsOneWidget);
    });
  });
}
