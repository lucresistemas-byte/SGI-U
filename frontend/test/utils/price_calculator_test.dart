import 'package:flutter_test/flutter_test.dart';
import 'package:sgi_u_frontend/utils/price_calculator.dart';

void main() {
  group('PriceCalculator - Pruebas Unitarias de Cálculo Matemático (Tarea 4.3)', () {
    test('Costo \$100 y margen 50% calcula precio de venta \$150', () {
      final venta = PriceCalculator.calcularPrecioVenta(100.0, 50.0);
      expect(venta, 150.0);
    });

    test('Costo \$100 y precio de venta \$125 calcula margen del 25%', () {
      final margen = PriceCalculator.calcularPorcentajeGanancia(100.0, 125.0);
      expect(margen, 25.0);
    });

    test('Costo \$100 y precio de venta \$150 calcula margen del 50%', () {
      final margen = PriceCalculator.calcularPorcentajeGanancia(100.0, 150.0);
      expect(margen, 50.0);
    });

    test('Precio de venta \$150 y margen 50% calcula costo \$100', () {
      final costo = PriceCalculator.calcularPrecioCosto(150.0, 50.0);
      expect(costo, 100.0);
    });

    test('Costo \$0 devuelve venta \$0 y no lanza excepción', () {
      final venta = PriceCalculator.calcularPrecioVenta(0.0, 30.0);
      expect(venta, 0.0);
    });

    test('Cálculo con margen negativo retorna null o inválido', () {
      final venta = PriceCalculator.calcularPrecioVenta(100.0, -10.0);
      expect(venta, isNull);
    });

    test('Cálculo con costo negativo retorna null o inválido', () {
      final venta = PriceCalculator.calcularPrecioVenta(-50.0, 20.0);
      expect(venta, isNull);
    });

    test('Margen con costo <= 0 retorna null para evitar división por cero', () {
      final margenCero = PriceCalculator.calcularPorcentajeGanancia(0.0, 100.0);
      expect(margenCero, isNull);

      final margenNegativo = PriceCalculator.calcularPorcentajeGanancia(-10.0, 100.0);
      expect(margenNegativo, isNull);
    });

    test('Cálculos con decimales se redondean a 2 decimales', () {
      // Costo 33.33 y margen 15% -> 33.33 * 1.15 = 38.3295 -> 38.33
      final venta = PriceCalculator.calcularPrecioVenta(33.33, 15.0);
      expect(venta, 38.33);

      // Costo 30, venta 45.50 -> ((45.50 - 30) / 30) * 100 = 51.666... -> 51.67
      final margen = PriceCalculator.calcularPorcentajeGanancia(30.0, 45.50);
      expect(margen, 51.67);
    });
  });
}
