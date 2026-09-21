import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sgi_u_frontend/blocs/pos_bloc.dart';
import 'package:sgi_u_frontend/models/product.dart';
import 'package:sgi_u_frontend/services/api_service.dart';
import 'package:sgi_u_frontend/widgets/payment_method_selector.dart';

class _StubPosApi implements PosApi {
  @override
  Future<List<dynamic>> getProducts() async => [];

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

void main() {
  // NOTA: el selector real usa radios fijos (EFECTIVO / MERCADO_PAGO).
  // El spec original describía líneas de pago con botón "Agregar"/"Eliminar",
  // pero PosState expone `selectedPaymentMethod` único. Se testea lo real.
  group('PaymentMethodSelector (N3)', () {
    late PosBloc bloc;

    setUp(() {
      bloc = PosBloc(apiService: _StubPosApi());
    });

    Future<void> pumpSelector(WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider.value(
            value: bloc,
            child: const Scaffold(body: PaymentMethodSelector()),
          ),
        ),
      );
    }

    testWidgets('muestra el título y las dos opciones de pago',
        (WidgetTester tester) async {
      await pumpSelector(tester);

      expect(find.text('Método de pago'), findsOneWidget);
      expect(find.text('Efectivo'), findsOneWidget);
      expect(find.text('Mercado Pago'), findsOneWidget);
    });

    testWidgets('seleccionar Mercado Pago actualiza el estado',
        (WidgetTester tester) async {
      await pumpSelector(tester);

      await tester.tap(find.text('Mercado Pago'));
      await tester.pump();

      expect(bloc.state.selectedPaymentMethod, 'MERCADO_PAGO');
    });

    testWidgets('seleccionar Efectivo actualiza el estado',
        (WidgetTester tester) async {
      await pumpSelector(tester);

      await tester.tap(find.text('Efectivo'));
      await tester.pump();

      expect(bloc.state.selectedPaymentMethod, 'EFECTIVO');
    });
  });
}