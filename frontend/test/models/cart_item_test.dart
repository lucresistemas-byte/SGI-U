import 'package:flutter_test/flutter_test.dart';
import 'package:sgi_u_frontend/models/cart_item.dart';

void main() {
  group('CartItem (D.12)', () {
    test('construccion con todos los campos', () {
      const item = CartItem(
        codigo: 'P001',
        nombre: 'Café',
        precioUnitario: 150.0,
        cantidad: 3,
      );

      expect(item.codigo, 'P001');
      expect(item.nombre, 'Café');
      expect(item.precioUnitario, 150.0);
      expect(item.cantidad, 3);
    });

    test('subtotal calcula precioUnitario * cantidad', () {
      const item = CartItem(
        codigo: 'P002',
        nombre: 'Agua',
        precioUnitario: 100.50,
        cantidad: 4,
      );

      expect(item.subtotal, 402.0);
    });

    test('copyWith preserva precioUnitario y cambia cantidad', () {
      const original = CartItem(
        codigo: 'P001',
        nombre: 'Café',
        precioUnitario: 150.0,
        cantidad: 1,
      );

      final updated = original.copyWith(cantidad: 5);

      expect(updated.codigo, original.codigo);
      expect(updated.nombre, original.nombre);
      expect(updated.precioUnitario, original.precioUnitario,
          reason: 'El precio unitario debe preservarse (congelado)');
      expect(updated.cantidad, 5);
    });

    test('copyWith sin argumento preserva la cantidad original', () {
      const original = CartItem(
        codigo: 'P001',
        nombre: 'Café',
        precioUnitario: 150.0,
        cantidad: 3,
      );

      final same = original.copyWith();

      expect(same.cantidad, 3);
      expect(same.precioUnitario, 150.0);
    });

    test('Equatable: dos ítems iguales son iguales', () {
      const a = CartItem(
          codigo: 'P001', nombre: 'Café', precioUnitario: 150.0, cantidad: 2);
      const b = CartItem(
          codigo: 'P001', nombre: 'Café', precioUnitario: 150.0, cantidad: 2);

      expect(a, equals(b));
    });

    test('Equatable: dos ítems con distinta cantidad son diferentes', () {
      const a = CartItem(
          codigo: 'P001', nombre: 'Café', precioUnitario: 150.0, cantidad: 1);
      const b = CartItem(
          codigo: 'P001', nombre: 'Café', precioUnitario: 150.0, cantidad: 5);

      expect(a, isNot(equals(b)));
    });
  });
}
