import 'package:flutter_test/flutter_test.dart';
import 'package:sgi_u_frontend/models/product.dart';

void main() {
  group('Product.fromJson (N2)', () {
    test('parsea todos los campos', () {
      final p = Product.fromJson(const {
        'codigo': 'P001',
        'nombre': 'Café Especial',
        'precioUnitario': 150.5,
        'stockActual': 12,
        'activo': true,
      });

      expect(p.codigo, 'P001');
      expect(p.nombre, 'Café Especial');
      expect(p.precioUnitario, 150.5);
      expect(p.stockActual, 12);
      expect(p.activo, isTrue);
    });

    test('precioUnitario entero se convierte a double', () {
      final p = Product.fromJson(const {
        'codigo': 'P002',
        'nombre': 'Agua',
        'precioUnitario': 100,
        'stockActual': 3,
      });

      expect(p.precioUnitario, 100.0);
      expect(p.precioUnitario, isA<double>());
    });

    test('activo por defecto es true cuando no viene en el JSON', () {
      final p = Product.fromJson(const {
        'codigo': 'P003',
        'nombre': 'Pan',
        'precioUnitario': 10,
        'stockActual': 0,
      });

      expect(p.activo, isTrue);
    });

    test('activo por defecto es true cuando llega null (campo opcional)', () {
      final p = Product.fromJson(const {
        'codigo': 'P004',
        'nombre': 'Leche',
        'precioUnitario': 80.0,
        'stockActual': 5,
        'activo': null,
      });

      expect(p.activo, isTrue);
    });

    test('activo false se respeta cuando viene explícito', () {
      final p = Product.fromJson(const {
        'codigo': 'P005',
        'nombre': 'Galletas',
        'precioUnitario': 25.0,
        'stockActual': 0,
        'activo': false,
      });

      expect(p.activo, isFalse);
    });

    test('campos requeridos (codigo, nombre, precio, stock) siempre presentes',
        () {
      final p = Product.fromJson(const {
        'codigo': 'P006',
        'nombre': 'Yerba',
        'precioUnitario': 2200.0,
        'stockActual': 40,
      });

      expect(p.codigo, isNotEmpty);
      expect(p.nombre, isNotEmpty);
      expect(p.precioUnitario, greaterThan(0));
      expect(p.stockActual, greaterThanOrEqualTo(0));
    });
  });
}