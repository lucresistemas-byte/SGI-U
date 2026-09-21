import 'package:flutter_test/flutter_test.dart';
import 'package:sgi_u_frontend/models/movimiento.dart';
import 'package:sgi_u_frontend/utils/finanzas_calculator.dart';

void main() {
  group('Movimiento Model Tests', () {
    test('fromJson y toJson mapean correctamente costo y ganancia', () {
      final json = {
        'id': 10,
        'tipo': 'INGRESO',
        'monto': 1500.50,
        'metodoPago': 'EFECTIVO',
        'categoria': 'Ventas',
        'descripcion': 'Venta mostrador',
        'fechaHora': '2026-09-21T10:30:00.000',
        'costo': 600.25,
        'ganancia': 900.25,
      };

      final mov = Movimiento.fromJson(json);

      expect(mov.id, 10);
      expect(mov.tipo, 'INGRESO');
      expect(mov.monto, 1500.50);
      expect(mov.costo, 600.25);
      expect(mov.ganancia, 900.25);
      expect(mov.metodoPago, 'EFECTIVO');

      final serialized = mov.toJson();
      expect(serialized['costo'], 600.25);
      expect(serialized['ganancia'], 900.25);
      expect(serialized['monto'], 1500.50);
    });

    test('fromJson maneja campos nulos con valores por defecto', () {
      final json = <String, dynamic>{
        'tipo': 'EGRESO',
        'monto': '200',
      };

      final mov = Movimiento.fromJson(json);
      expect(mov.costo, 0.0);
      expect(mov.ganancia, 0.0);
      expect(mov.monto, 200.0);
    });
  });

  group('FinanzasCalculator Tests', () {
    test('calcularGananciaTotal suma correctamente las ganancias de una lista de Movimiento', () {
      final movimientos = [
        const Movimiento(tipo: 'INGRESO', monto: 1000, costo: 600, ganancia: 400),
        const Movimiento(tipo: 'INGRESO', monto: 2000, costo: 1200, ganancia: 800),
        const Movimiento(tipo: 'EGRESO', monto: 300, costo: 300, ganancia: -300),
      ];

      final totalGanancia = FinanzasCalculator.calcularGananciaTotal(movimientos);
      expect(totalGanancia, 900.0);
    });

    test('calcularCostoTotal suma correctamente los costos de una lista de Movimiento', () {
      final movimientos = [
        const Movimiento(tipo: 'INGRESO', monto: 1000, costo: 600, ganancia: 400),
        const Movimiento(tipo: 'INGRESO', monto: 2000, costo: 1200, ganancia: 800),
        const Movimiento(tipo: 'EGRESO', monto: 300, costo: 300, ganancia: -300),
      ];

      final totalCosto = FinanzasCalculator.calcularCostoTotal(movimientos);
      expect(totalCosto, 2100.0);
    });

    test('calcularIngresosTotales y calcularEgresosTotales filtran y suman según tipo', () {
      final movimientos = [
        const Movimiento(tipo: 'INGRESO', monto: 1000),
        const Movimiento(tipo: 'INGRESO', monto: 2500),
        const Movimiento(tipo: 'EGRESO', monto: 400),
        const Movimiento(tipo: 'EGRESO', monto: 600),
      ];

      expect(FinanzasCalculator.calcularIngresosTotales(movimientos), 3500.0);
      expect(FinanzasCalculator.calcularEgresosTotales(movimientos), 1000.0);
    });

    test('calcularGananciaTotalRaw y calcularCostoTotalRaw procesan listas de mapas dinámicos', () {
      final rawList = [
        {'costo': 50.0, 'ganancia': 25.0},
        {'costo': '100.5', 'ganancia': '50.5'},
        {'costo': 0, 'ganancia': 0},
      ];

      expect(FinanzasCalculator.calcularCostoTotalRaw(rawList), 150.5);
      expect(FinanzasCalculator.calcularGananciaTotalRaw(rawList), 75.5);
    });

    test('lista vacía devuelve cero para costos y ganancias', () {
      expect(FinanzasCalculator.calcularGananciaTotal([]), 0.0);
      expect(FinanzasCalculator.calcularCostoTotal([]), 0.0);
      expect(FinanzasCalculator.calcularGananciaTotalRaw([]), 0.0);
      expect(FinanzasCalculator.calcularCostoTotalRaw([]), 0.0);
    });
  });
}
