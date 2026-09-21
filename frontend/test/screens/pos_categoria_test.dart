import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:sgi_u_frontend/blocs/pos_bloc.dart';
import 'package:sgi_u_frontend/blocs/pos_event.dart';
import 'package:sgi_u_frontend/blocs/pos_state.dart';
import 'package:sgi_u_frontend/models/product.dart';
import 'package:sgi_u_frontend/screens/pos_screen.dart';

class MockPosBloc extends MockBloc<PosEvent, PosState> implements PosBloc {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final pBebida1 = Product(
    codigo: 'BEB-001',
    nombre: 'Coca Cola 250ml',
    precioUnitario: 1500.0,
    stockActual: 10,
    activo: true,
    categoria: 'Bebidas',
  );

  final pBebida2 = Product(
    codigo: 'BEB-002',
    nombre: 'Sprite 250ml',
    precioUnitario: 1400.0,
    stockActual: 8,
    activo: true,
    categoria: 'Bebidas',
  );

  final pComida = Product(
    codigo: 'COM-001',
    nombre: 'Empanada Criolla',
    precioUnitario: 1200.0,
    stockActual: 20,
    activo: true,
    categoria: 'Comidas',
  );

  final allProducts = [pBebida1, pBebida2, pComida];

  late MockPosBloc mockPosBloc;

  setUp(() {
    mockPosBloc = MockPosBloc();
  });

  tearDown(() {
    mockPosBloc.close();
  });

  Widget createTestWidget() {
    return MaterialApp(
      home: BlocProvider<PosBloc>.value(
        value: mockPosBloc,
        child: const PosScreen(),
      ),
    );
  }

  group('POS - Filtros por Categoría en UI (Tarea 2.4)', () {
    testWidgets('Muestra chips de categoría, filtra al hacer tap y valida selección',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final stateController = StreamController<PosState>.broadcast();
      addTearDown(stateController.close);

      final initialState = PosState.initial().copyWith(
        products: allProducts,
        selectedCategory: null,
      );

      final filteredState = PosState.initial().copyWith(
        products: allProducts,
        selectedCategory: 'Bebidas',
      );

      when(() => mockPosBloc.state).thenReturn(initialState);
      whenListen(
        mockPosBloc,
        stateController.stream,
        initialState: initialState,
      );

      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Inicialmente se muestran todos los productos
      expect(find.text('Coca Cola 250ml'), findsOneWidget);
      expect(find.text('Sprite 250ml'), findsOneWidget);
      expect(find.text('Empanada Criolla'), findsOneWidget);

      // Los chips "Todas", "Bebidas" y "Comidas" deben estar visibles
      expect(find.byKey(const ValueKey('pos_category_chip_Todas')), findsOneWidget);
      final bebidasChipFinder = find.byKey(const ValueKey('pos_category_chip_Bebidas'));
      expect(bebidasChipFinder, findsOneWidget);

      // Simulamos tap en el chip de "Bebidas"
      await tester.tap(bebidasChipFinder);
      await tester.pump();

      // Se debe haber despachado FilterByCategoryEvent('Bebidas')
      verify(() => mockPosBloc.add(const FilterByCategoryEvent('Bebidas'))).called(1);

      // Simulamos la emisión del nuevo estado filtrado desde el BLoC
      when(() => mockPosBloc.state).thenReturn(filteredState);
      stateController.add(filteredState);
      await tester.pumpAndSettle();

      // Verificamos que la UI muestre solo las bebidas y no la empanada
      expect(find.text('Coca Cola 250ml'), findsOneWidget);
      expect(find.text('Sprite 250ml'), findsOneWidget);
      expect(find.text('Empanada Criolla'), findsNothing);

      // Verificamos que el chip "Bebidas" quede seleccionado
      final FilterChip chipWidget = tester.widget(bebidasChipFinder);
      expect(chipWidget.selected, isTrue);
    });
  });
}
