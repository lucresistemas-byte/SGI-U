import 'package:flutter_test/flutter_test.dart';
import 'package:sgi_u_frontend/models/cart_item.dart';
import 'package:sgi_u_frontend/models/completed_sale.dart';

void main() {
  group('CompletedSale (N2)', () {
    final timestamp = DateTime(2026, 9, 21, 10, 30);
    const items = [
      CartItem(
          codigo: 'P001', nombre: 'Café', precioUnitario: 150.0, cantidad: 2),
    ];

    test('construcción correcta con items, método, total y timestamp', () {
      final sale = CompletedSale(
        items: items,
        paymentMethod: 'EFECTIVO',
        totalAmount: 300.0,
        timestamp: timestamp,
      );

      expect(sale.items, items);
      expect(sale.paymentMethod, 'EFECTIVO');
      expect(sale.totalAmount, 300.0);
      expect(sale.timestamp, timestamp);
    });

    test('Equatable: dos ventas con los mismos valores son iguales', () {
      final a = CompletedSale(
        items: items,
        paymentMethod: 'EFECTIVO',
        totalAmount: 300.0,
        timestamp: timestamp,
      );
      final b = CompletedSale(
        items: items,
        paymentMethod: 'EFECTIVO',
        totalAmount: 300.0,
        timestamp: timestamp,
      );

      expect(a, equals(b));
    });

    test('Equatable: ventas con distinto método o total son diferentes', () {
      final a = CompletedSale(
        items: items,
        paymentMethod: 'EFECTIVO',
        totalAmount: 300.0,
        timestamp: timestamp,
      );
      final b = CompletedSale(
        items: items,
        paymentMethod: 'MERCADO_PAGO',
        totalAmount: 300.0,
        timestamp: timestamp,
      );

      expect(a, isNot(equals(b)));
    });
  });
}