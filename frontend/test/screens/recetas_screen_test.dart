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

class MockRecetasBloc extends MockBloc<RecetasEvent, RecetasState>
    implements RecetasBloc {}

class FakeRecetasEvent extends Fake implements RecetasEvent {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeRecetasEvent());
    registerFallbackValue(const AgregarFilaInsumo(
      insumo: Insumo(codigo: 'X', nombre: 'X', costoUnitario: 1),
    ));
  });

  group('RecetasScreen - Armador Dinámico y Validaciones (Tarea 7.5)', () {
    late MockRecetasBloc mockRecetasBloc;

    final testProductos = [
      Product(
        codigo: 'PROD-001',
        nombre: 'Torta de Cumpleaños',
        precioUnitario: 8000.0,
        stockActual: 5,
      ),
    ];

    const testInsumos = [
      Insumo(
        id: 1,
        codigo: 'INS-001',
        nombre: 'Harina 000',
        costoUnitario: 100.0,
        unidadMedida: 'KILO',
      ),
      Insumo(
        id: 2,
        codigo: 'INS-002',
        nombre: 'Dulce de Leche',
        costoUnitario: 300.0,
        unidadMedida: 'KILO',
      ),
    ];

    setUp(() {
      mockRecetasBloc = MockRecetasBloc();
    });

    tearDown(() {
      mockRecetasBloc.close();
    });

    testWidgets(
      'Usuario puede agregar múltiples filas de insumos dinámicamente y el botón de guardar se deshabilita si hay campos vacíos',
      (tester) async {
        tester.view.physicalSize = const Size(1280, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        final stateController = StreamController<RecetasState>.broadcast();
        addTearDown(stateController.close);

        // 1. Estado inicial: campos vacíos, 0 filas
        final initialState = RecetasState.initial().copyWith(
          availableProductos: testProductos,
          availableInsumos: testInsumos,
          selectedProductoCodigo: '',
          nombre: '',
          detalles: const [],
          costoTotal: 0.0,
        );

        when(() => mockRecetasBloc.state).thenReturn(initialState);
        whenListen(
          mockRecetasBloc,
          stateController.stream,
          initialState: initialState,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: RecetasScreen(
              recetasBloc: mockRecetasBloc,
              initialBuildingMode: true,
            ),
          ),
        );
        await tester.pumpAndSettle();

        // 2. Verificar botón de guardar deshabilitado con campos vacíos
        final guardarBtnFinder = find.byKey(const Key('guardar_receta_button'));
        expect(guardarBtnFinder, findsOneWidget);
        ElevatedButton guardarBtn = tester.widget<ElevatedButton>(guardarBtnFinder);
        expect(guardarBtn.onPressed, isNull, reason: 'Botón guardar debe estar deshabilitado');

        // Inicialmente 0 filas
        expect(find.byKey(const Key('fila_insumo_0')), findsNothing);

        // 3. Agregar primera fila dinámicamente
        final agregarInsumoBtnFinder = find.byKey(const Key('agregar_insumo_fila_button'));
        expect(agregarInsumoBtnFinder, findsOneWidget);
        await tester.tap(agregarInsumoBtnFinder);
        await tester.pump();

        verify(() => mockRecetasBloc.add(any(that: isA<AgregarFilaInsumo>()))).called(1);

        // Emitimos estado con 1 fila
        final stateWith1Row = initialState.copyWith(
          detalles: const [
            RecetaDetalle(
              materiaPrimaId: 1,
              materiaPrimaCodigo: 'INS-001',
              materiaPrimaNombre: 'Harina 000',
              cantidad: 1.0,
              unidadMedida: 'KILO',
              costoUnitario: 100.0,
              subtotal: 100.0,
            ),
          ],
          costoTotal: 100.0,
        );
        when(() => mockRecetasBloc.state).thenReturn(stateWith1Row);
        stateController.add(stateWith1Row);
        await tester.pumpAndSettle();

        // Fila 0 ahora existe
        expect(find.byKey(const Key('fila_insumo_0')), findsOneWidget);

        // Botón guardar sigue deshabilitado (nombre y producto siguen vacíos)
        guardarBtn = tester.widget<ElevatedButton>(guardarBtnFinder);
        expect(guardarBtn.onPressed, isNull);

        // 4. Agregar segunda fila dinámicamente
        await tester.tap(agregarInsumoBtnFinder);
        await tester.pump();

        verify(() => mockRecetasBloc.add(any(that: isA<AgregarFilaInsumo>()))).called(1);

        final stateWith2Rows = stateWith1Row.copyWith(
          detalles: const [
            RecetaDetalle(
              materiaPrimaId: 1,
              materiaPrimaCodigo: 'INS-001',
              materiaPrimaNombre: 'Harina 000',
              cantidad: 1.0,
              unidadMedida: 'KILO',
              costoUnitario: 100.0,
              subtotal: 100.0,
            ),
            RecetaDetalle(
              materiaPrimaId: 2,
              materiaPrimaCodigo: 'INS-002',
              materiaPrimaNombre: 'Dulce de Leche',
              cantidad: 2.0,
              unidadMedida: 'KILO',
              costoUnitario: 300.0,
              subtotal: 600.0,
            ),
          ],
          costoTotal: 700.0,
        );
        when(() => mockRecetasBloc.state).thenReturn(stateWith2Rows);
        stateController.add(stateWith2Rows);
        await tester.pumpAndSettle();

        // Ambas filas se renderizan
        expect(find.byKey(const Key('fila_insumo_0')), findsOneWidget);
        expect(find.byKey(const Key('fila_insumo_1')), findsOneWidget);

        // 5. Completar nombre y producto -> botón de guardar SE HABILITA
        final validState = stateWith2Rows.copyWith(
          selectedProductoCodigo: 'PROD-001',
          selectedProductoNombre: 'Torta de Cumpleaños',
          nombre: 'Receta Especial Torta',
        );
        when(() => mockRecetasBloc.state).thenReturn(validState);
        stateController.add(validState);
        await tester.pumpAndSettle();

        guardarBtn = tester.widget<ElevatedButton>(guardarBtnFinder);
        expect(guardarBtn.onPressed, isNotNull, reason: 'Debe habilitarse con campos válidos');

        // 6. Si un campo requerido queda vacío o una fila tiene cantidad 0 -> SE DESHABILITA
        final invalidRowState = validState.copyWith(
          detalles: const [
            RecetaDetalle(
              materiaPrimaId: 1,
              materiaPrimaCodigo: 'INS-001',
              materiaPrimaNombre: 'Harina 000',
              cantidad: 0.0, // Inválido: cantidad 0
              unidadMedida: 'KILO',
              costoUnitario: 100.0,
              subtotal: 0.0,
            ),
          ],
        );
        when(() => mockRecetasBloc.state).thenReturn(invalidRowState);
        stateController.add(invalidRowState);
        await tester.pumpAndSettle();

        guardarBtn = tester.widget<ElevatedButton>(guardarBtnFinder);
        expect(guardarBtn.onPressed, isNull, reason: 'Debe deshabilitarse si la cantidad es 0');

        // 7. Eliminar fila
        final eliminarFila0Finder = find.byKey(const Key('eliminar_insumo_fila_0'));
        await tester.tap(eliminarFila0Finder);
        await tester.pump();

        verify(() => mockRecetasBloc.add(const RemoverFilaInsumo(0))).called(1);
      },
    );
  });
}
