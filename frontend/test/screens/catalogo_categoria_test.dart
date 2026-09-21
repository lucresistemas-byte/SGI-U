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
import 'package:sgi_u_frontend/screens/catalogo_screen.dart';

class MockPosBloc extends MockBloc<PosEvent, PosState> implements PosBloc {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final p1 = Product(
    codigo: 'BEB-001',
    nombre: 'Gaseosa Coca Cola 250ml',
    precioUnitario: 1500.0,
    stockActual: 10,
    activo: true,
    categoria: 'Bebidas',
  );

  final p2 = Product(
    codigo: 'BEB-002',
    nombre: 'Jugo de Naranja 500ml',
    precioUnitario: 1800.0,
    stockActual: 5,
    activo: true,
    categoria: 'Bebidas',
  );

  final p3 = Product(
    codigo: 'ALM-001',
    nombre: 'Arroz Integral 1kg',
    precioUnitario: 2200.0,
    stockActual: 15,
    activo: true,
    categoria: 'Alimentos',
  );

  final p4 = Product(
    codigo: 'GEN-001',
    nombre: 'Bolsa Ecológica',
    precioUnitario: 300.0,
    stockActual: 100,
    activo: true,
    categoria: null,
  );

  final allProducts = [p1, p2, p3, p4];

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
        child: const CatalogoScreen(),
      ),
    );
  }

  group('Catálogo - Chips de Categoría y Búsqueda (Tarea 2.5)', () {
    testWidgets(
        'Filtra por categoría con FilterChip y combina con texto del buscador',
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

      final alimentosState = PosState.initial().copyWith(
        products: allProducts,
        selectedCategory: 'Alimentos',
      );

      final bebidasState = PosState.initial().copyWith(
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

      // Verificar que la columna "Categoría" exista en la tabla
      expect(find.text('Categoría'), findsOneWidget);

      // Inicialmente se ven productos de ambas categorías y el sin categoría
      expect(find.text('Gaseosa Coca Cola 250ml'), findsOneWidget);
      expect(find.text('Jugo de Naranja 500ml'), findsOneWidget);
      expect(find.text('Arroz Integral 1kg'), findsOneWidget);
      expect(find.text('Bolsa Ecológica'), findsOneWidget);

      // Los chips "Todas", "Alimentos" y "Bebidas" deben estar visibles
      expect(find.byKey(const ValueKey('catalogo_category_chip_Todas')), findsOneWidget);
      final alimentosChipFinder = find.byKey(const ValueKey('catalogo_category_chip_Alimentos'));
      expect(alimentosChipFinder, findsOneWidget);

      // Simulamos tap en "Alimentos"
      await tester.tap(alimentosChipFinder);
      await tester.pump();

      // Se debe haber despachado FilterByCategoryEvent('Alimentos')
      verify(() => mockPosBloc.add(const FilterByCategoryEvent('Alimentos'))).called(1);

      // BLoC emite estado filtrado por Alimentos
      when(() => mockPosBloc.state).thenReturn(alimentosState);
      stateController.add(alimentosState);
      await tester.pumpAndSettle();

      // Solo debe aparecer el Arroz
      expect(find.text('Arroz Integral 1kg'), findsOneWidget);
      expect(find.text('Gaseosa Coca Cola 250ml'), findsNothing);
      expect(find.text('Jugo de Naranja 500ml'), findsNothing);
      expect(find.text('Bolsa Ecológica'), findsNothing);

      // Seleccionamos "Bebidas"
      final bebidasChipFinder = find.byKey(const ValueKey('catalogo_category_chip_Bebidas'));
      await tester.tap(bebidasChipFinder);
      await tester.pump();

      // Se debe haber despachado FilterByCategoryEvent('Bebidas')
      verify(() => mockPosBloc.add(const FilterByCategoryEvent('Bebidas'))).called(1);

      // BLoC emite estado filtrado por Bebidas
      when(() => mockPosBloc.state).thenReturn(bebidasState);
      stateController.add(bebidasState);
      await tester.pumpAndSettle();

      // Deben aparecer las 2 bebidas
      expect(find.text('Gaseosa Coca Cola 250ml'), findsOneWidget);
      expect(find.text('Jugo de Naranja 500ml'), findsOneWidget);
      expect(find.text('Arroz Integral 1kg'), findsNothing);

      // Combinamos con búsqueda de texto: "Jugo"
      final searchField = find.byType(TextField).first;
      await tester.enterText(searchField, 'Jugo');
      await tester.pumpAndSettle();

      // Intersección: solo Jugo de Naranja
      expect(find.text('Jugo de Naranja 500ml'), findsOneWidget);
      expect(find.text('Gaseosa Coca Cola 250ml'), findsNothing);
      expect(find.text('Arroz Integral 1kg'), findsNothing);
    });
  });
}
