import 'package:flutter_test/flutter_test.dart';
import 'package:sgi_u_frontend/models/product.dart';

void main() {
  group('Product Model - Unidad de Medida (Tarea 3.3)', () {
    test('fromJson mapea unidadMedida en camelCase', () {
      final json = {
        'codigo': 'P-01',
        'nombre': 'Harina 000',
        'precioUnitario': 1200.0,
        'stockActual': 50,
        'activo': true,
        'categoria': 'Almacén',
        'unidadMedida': 'KILO',
      };

      final product = Product.fromJson(json);

      expect(product.codigo, 'P-01');
      expect(product.nombre, 'Harina 000');
      expect(product.unidadMedida, 'KILO');
    });

    test('fromJson mapea unidad_medida en snake_case', () {
      final json = {
        'codigo': 'P-02',
        'nombre': 'Levadura Fresca',
        'precioUnitario': 500.0,
        'stockActual': 20,
        'activo': true,
        'unidad_medida': 'GRAMO',
      };

      final product = Product.fromJson(json);

      expect(product.codigo, 'P-02');
      expect(product.unidadMedida, 'GRAMO');
    });

    test('fromJson asigna UNIDAD por defecto cuando el campo es nulo o ausente', () {
      final json = {
        'codigo': 'P-03',
        'nombre': 'Alfajor',
        'precioUnitario': 800.0,
        'stockActual': 100,
        'activo': true,
      };

      final product = Product.fromJson(json);

      expect(product.unidadMedida, 'UNIDAD');
    });

    test('toJson incluye tanto unidadMedida como unidad_medida', () {
      final product = Product(
        codigo: 'P-04',
        nombre: 'Leche Entera',
        precioUnitario: 1100.0,
        stockActual: 30,
        unidadMedida: 'LITRO',
      );

      final json = product.toJson();

      expect(json['unidadMedida'], 'LITRO');
      expect(json['unidad_medida'], 'LITRO');
    });

    test('copyWith preserva o actualiza unidadMedida correctamente', () {
      final product = Product(
        codigo: 'P-05',
        nombre: 'Cable',
        precioUnitario: 350.0,
        stockActual: 200,
        unidadMedida: 'METRO',
      );

      final copySame = product.copyWith();
      expect(copySame.unidadMedida, 'METRO');
      expect(copySame, equals(product));

      final copyModified = product.copyWith(unidadMedida: 'CAJA');
      expect(copyModified.unidadMedida, 'CAJA');
      expect(copyModified == product, isFalse);
    });
  });

  group('Product Model - Precio de Costo y Margen (Tarea 4.3)', () {
    test('fromJson y toJson mapean precioCosto y porcentajeGanancia', () {
      final json = {
        'codigo': 'C-01',
        'nombre': 'Café Torrado',
        'precioUnitario': 150.0,
        'stockActual': 10,
        'precioCosto': 100.0,
        'porcentajeGanancia': 50.0,
      };

      final product = Product.fromJson(json);
      expect(product.precioCosto, 100.0);
      expect(product.porcentajeGanancia, 50.0);

      final outJson = product.toJson();
      expect(outJson['precioCosto'], 100.0);
      expect(outJson['precio_costo'], 100.0);
      expect(outJson['porcentajeGanancia'], 50.0);
      expect(outJson['porcentaje_ganancia'], 50.0);
    });

    test('fromJson soporta snake_case para precio_costo y porcentaje_ganancia', () {
      final json = {
        'codigo': 'C-02',
        'nombre': 'Té Verde',
        'precioUnitario': 125.0,
        'stockActual': 15,
        'precio_costo': 100.0,
        'porcentaje_ganancia': 25.0,
      };

      final product = Product.fromJson(json);
      expect(product.precioCosto, 100.0);
      expect(product.porcentajeGanancia, 25.0);
    });
  });
}
