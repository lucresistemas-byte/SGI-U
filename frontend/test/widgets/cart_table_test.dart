import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sgi_u_frontend/blocs/pos_bloc.dart';
import 'package:sgi_u_frontend/blocs/pos_event.dart';
import 'package:sgi_u_frontend/models/product.dart';
import 'package:sgi_u_frontend/screens/pos_screen.dart';
import 'package:sgi_u_frontend/services/api_service.dart';

class _FakePosApi implements PosApi {
  @override
  Future<List<dynamic>> getProducts() async => [
        {
          'codigo': 'P1',
          'nombre': 'Café',
          'precioUnitario': 150.0,
          'stockActual': 10,
          'activo': true,
        },
        {
          'codigo': 'P2',
          'nombre': 'Agua',
          'precioUnitario': 50.0,
          'stockActual': 20,
          'activo': true,
        },
      ];

  @override
  Future<void> createSale(Map<String, dynamic> saleData) async {}

  @override
  Future<Product> createProduct(Map<String, dynamic> productData) async {
    throw UnimplementedError();
  }

  @override
  Future<Product> updateProduct(
      String codigo, Map<String, dynamic> productData) async {
    throw UnimplementedError();
  }

  @override
  Future<Product> ajustarStock(String codigo,
      {required int cantidad, required String motivo}) async {
    throw UnimplementedError();
  }
}

/// Prepara un PosBloc ya cargado con productos y, opcionalmente, un carrito.
/// Se siembra con [WidgetTester.pump] (no con firstWhere) porque dentro de
/// `testWidgets` el cuerpo corre en la zona FakeAsync y esperar un evento de
/// stream sin avanzar el reloj cuelga el test.
Future<PosBloc> _blocConCart(
  WidgetTester tester, {
  bool conCart = true,
}) async {
  final bloc = PosBloc(apiService: _FakePosApi());

  bloc.add(const LoadProducts());
  for (var i = 0; i < 10 && bloc.state.products.length < 2; i++) {
    await tester.pump();
  }
  expect(bloc.state.products, hasLength(2));

  if (conCart) {
    bloc.add(const AddToCart('P1', 2));
    for (var i = 0; i < 10 && !bloc.state.cart.containsKey('P1'); i++) {
      await tester.pump();
    }
    bloc.add(const AddToCart('P2', 1));
    for (var i = 0; i < 10 && !bloc.state.cart.containsKey('P2'); i++) {
      await tester.pump();
    }
  }

  return bloc;
}

Future<void> _pumpCart(WidgetTester tester, PosBloc bloc) async {
  await tester.pumpWidget(
    MaterialApp(
      home: BlocProvider.value(
        value: bloc,
        child: const Scaffold(body: CartTable()),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('CartTable (N3)', () {
    testWidgets('sin productos muestra el mensaje de carrito vacío',
        (WidgetTester tester) async {
      final bloc = await _blocConCart(tester, conCart: false);
      await _pumpCart(tester, bloc);

      expect(find.text('No hay productos agregados'), findsOneWidget);
      await tester.runAsync(() => bloc.close());
    });

    testWidgets('muestra una fila por producto del carrito',
        (WidgetTester tester) async {
      final bloc = await _blocConCart(tester);
      await _pumpCart(tester, bloc);

      expect(find.text('Café'), findsOneWidget);
      expect(find.text('Agua'), findsOneWidget);
      expect(find.text('No hay productos agregados'), findsNothing);
      expect(find.byIcon(Icons.delete), findsNWidgets(2));

      // Cantidades: Café x2 y Agua x1
      expect(find.text('2'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
      await tester.runAsync(() => bloc.close());
    });

    testWidgets('el botón de eliminar remueve la fila correspondiente',
        (WidgetTester tester) async {
      final bloc = await _blocConCart(tester);
      await _pumpCart(tester, bloc);

      await tester.tap(find.byIcon(Icons.delete).first);
      await tester.pumpAndSettle();

      expect(find.text('Café'), findsNothing);
      expect(find.text('Agua'), findsOneWidget);
      expect(find.byIcon(Icons.delete), findsOneWidget);
      await tester.runAsync(() => bloc.close());
    });

    testWidgets('el botón + incrementa la cantidad respetando el stock',
        (WidgetTester tester) async {
      final bloc = await _blocConCart(tester);
      await _pumpCart(tester, bloc);

      // Café (stock 10, cantidad 2) -> +1 = 3
      await tester.tap(find.byIcon(Icons.add).first);
      await tester.pumpAndSettle();

      expect(find.text('3'), findsOneWidget);
      await tester.runAsync(() => bloc.close());
    });

    testWidgets('el botón - decrementa la cantidad',
        (WidgetTester tester) async {
      final bloc = await _blocConCart(tester);
      await _pumpCart(tester, bloc);

      // Café (cantidad 2) -> -1 = 1
      await tester.tap(find.byIcon(Icons.remove).first);
      await tester.pumpAndSettle();

      expect(bloc.state.cart['P1']?.cantidad, 1);
      await tester.runAsync(() => bloc.close());
    });

    testWidgets('permite editar la cantidad directamente desde la caja de texto (Punto 1)',
        (WidgetTester tester) async {
      final bloc = await _blocConCart(tester);
      await _pumpCart(tester, bloc);

      // Buscamos la cajita de cantidad de Café ('cart_qty_field_P1')
      final qtyFinder = find.byKey(const ValueKey('cart_qty_field_P1'));
      expect(qtyFinder, findsOneWidget);

      // Ingresamos directamente la cantidad 5
      await tester.enterText(qtyFinder, '5');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(bloc.state.cart['P1']?.cantidad, 5);
      await tester.runAsync(() => bloc.close());
    });
  });
}