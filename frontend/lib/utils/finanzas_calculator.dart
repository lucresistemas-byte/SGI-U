import '../models/movimiento.dart';
import 'parsers.dart';

/// Utilidad para cálculos financieros en el frontend (Costo vs Beneficio, sumas de movimientos).
class FinanzasCalculator {
  /// Suma las ganancias totales a partir de una lista de objetos [Movimiento].
  static double calcularGananciaTotal(List<Movimiento> movimientos) {
    return movimientos.fold(0.0, (acc, mov) => acc + mov.ganancia);
  }

  /// Suma el costo total a partir de una lista de objetos [Movimiento].
  static double calcularCostoTotal(List<Movimiento> movimientos) {
    return movimientos.fold(0.0, (acc, mov) => acc + mov.costo);
  }

  /// Suma los ingresos totales (monto de movimientos de tipo INGRESO).
  static double calcularIngresosTotales(List<Movimiento> movimientos) {
    return movimientos
        .where((m) => m.tipo.toUpperCase() == 'INGRESO')
        .fold(0.0, (acc, m) => acc + m.monto);
  }

  /// Suma los egresos totales (monto de movimientos de tipo EGRESO).
  static double calcularEgresosTotales(List<Movimiento> movimientos) {
    return movimientos
        .where((m) => m.tipo.toUpperCase() == 'EGRESO')
        .fold(0.0, (acc, m) => acc + m.monto);
  }

  /// Suma las ganancias totales a partir de una lista dinámica (que puede contener
  /// objetos [Movimiento] o mapas deserializados [Map<String, dynamic>]).
  static double calcularGananciaTotalRaw(List<dynamic> movimientos) {
    double total = 0.0;
    for (final item in movimientos) {
      if (item is Movimiento) {
        total += item.ganancia;
      } else if (item is Map) {
        total += parseDouble(item['ganancia']);
      }
    }
    return total;
  }

  /// Suma los costos totales a partir de una lista dinámica (que puede contener
  /// objetos [Movimiento] o mapas deserializados [Map<String, dynamic>]).
  static double calcularCostoTotalRaw(List<dynamic> movimientos) {
    double total = 0.0;
    for (final item in movimientos) {
      if (item is Movimiento) {
        total += item.costo;
      } else if (item is Map) {
        total += parseDouble(item['costo']);
      }
    }
    return total;
  }
}
