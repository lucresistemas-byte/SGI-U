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
import 'package:sgi_u_frontend/models/cart_item.dart';
import 'package:sgi_u_frontend/screens/pos_screen.dart';

class MockPosBloc extends MockBloc<PosEvent, PosState> implements PosBloc {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final pBebida = Product(
    codigo: 'BEB-001',
    nombre: 'Coca Cola 250ml',
    precioUnitario: 1500.0,
    stockActual: 10,
    activo: true,
    categoria: 'Bebidas',
  );

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

  group('Punto 1 - Rediseño barra de búsqueda y edición directa de cantidad en POS', () {
    testWidgets('SearchAddBar NO tiene botón "Agregar" ni campo "Cant." separado',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final state = PosState.initial().copyWith(
        products: [pBebida],
        cart: {},
      );

      when(() => mockPosBloc.state).thenReturn(state);
      whenListen(mockPosBloc, const Stream<PosState>.empty(), initialState: state);

      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Debe tener el campo de búsqueda principal
      expect(find.byType(TextField), findsWidgets);
      expect(find.text('Buscar producto (código o nombre)...'), findsOneWidget);

      // NO debe tener el botón 'Agregar' ni el hint 'Cant.'
      expect(find.text('Agregar'), findsNothing);
      expect(find.text('Cant.'), findsNothing);
    });

    testWidgets('En el carrito hay cajita editable de cantidad junto con botones - y +',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      const cartItem = CartItem(
        codigo: 'BEB-001',
        nombre: 'Coca Cola 250ml',
        precioUnitario: 1500.0,
        cantidad: 2,
      );

      final state = PosState.initial().copyWith(
        products: [pBebida],
        cart: {'BEB-001': cartItem},
      );

      when(() => mockPosBloc.state).thenReturn(state);
      whenListen(mockPosBloc, const Stream<PosState>.empty(), initialState: state);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // En la fila del carrito encontramos el CartQuantityInput
      final qtyInputFinder = find.byType(CartQuantityInput);
      expect(qtyInputFinder, findsOneWidget);

      // Verificamos que contenga botón [-], cajita de texto con '2' y botón [+]
      expect(find.descendant(of: qtyInputFinder, matching: find.byIcon(Icons.remove)), findsOneWidget);
      expect(find.descendant(of: qtyInputFinder, matching: find.byIcon(Icons.add)), findsOneWidget);
      final qtyFieldFinder = find.byKey(const ValueKey('cart_qty_field_BEB-001'));
      expect(qtyFieldFinder, findsOneWidget);
      expect(find.text('2'), findsOneWidget);

      // Ingresamos directamente un nuevo valor '7'
      await tester.enterText(qtyFieldFinder, '7');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      // Debe haberse despachado UpdateCartItemQuantity('BEB-001', 7)
      verify(() => mockPosBloc.add(const UpdateCartItemQuantity('BEB-001', 7))).called(1);
    });
  });
}
