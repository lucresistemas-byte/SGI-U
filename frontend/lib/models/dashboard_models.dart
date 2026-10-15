// lib/models/dashboard_models.dart
import 'resultado_periodo.dart';

class DashboardResponse {
  final DashboardKpis kpis;
  final DashboardGraficos graficos;

  DashboardResponse({required this.kpis, required this.graficos});

  factory DashboardResponse.fromJson(Map<String, dynamic> json) {
    return DashboardResponse(
      kpis: DashboardKpis.fromJson(json['kpis'] ?? {}),
      graficos: DashboardGraficos.fromJson(json['graficos'] ?? {}),
    );
  }
}

class DashboardKpis {
  final double ingresosPeriodo;
  // Null con el filtro por producto: los egresos no son de un producto.
  final double? egresosPeriodo;
  final double? saldoNeto;
  final double? margenNetoPorcentaje; // El ajuste de rentabilidad
  final int cantidadVentas;
  final double ticketPromedio;
  final int cantidadProductosStockBajo;

  /// Costo de lo vendido, ganancia bruta y ganancia neta.
  final ResultadoPeriodo resultado;

  DashboardKpis({
    required this.ingresosPeriodo,
    required this.egresosPeriodo,
    required this.saldoNeto,
    required this.margenNetoPorcentaje,
    required this.cantidadVentas,
    required this.ticketPromedio,
    required this.cantidadProductosStockBajo,
    this.resultado = const ResultadoPeriodo(),
  });

  factory DashboardKpis.fromJson(Map<String, dynamic> json) {
    return DashboardKpis(
      ingresosPeriodo: (json['ingresosPeriodo'] ?? 0).toDouble(),
      egresosPeriodo: (json['egresosPeriodo'] as num?)?.toDouble(),
      saldoNeto: (json['saldoNeto'] as num?)?.toDouble(),
      margenNetoPorcentaje: (json['margenNetoPorcentaje'] as num?)?.toDouble(),
      cantidadVentas: json['cantidadVentas'] ?? 0,
      ticketPromedio: (json['ticketPromedio'] ?? 0).toDouble(),
      cantidadProductosStockBajo: json['cantidadProductosStockBajo'] ?? 0,
      resultado: ResultadoPeriodo.fromJson(json['resultado'] as Map<String, dynamic>?),
    );
  }
}

class DashboardGraficos {
  final List<ProductoStock> productosConMenorStock;
  final List<TopProducto> topProductosMasVendidos;
  final List<EvolucionDiaria> ingresosVsEgresosPorDia;

  DashboardGraficos({
    required this.productosConMenorStock,
    required this.topProductosMasVendidos,
    required this.ingresosVsEgresosPorDia,
  });

  factory DashboardGraficos.fromJson(Map<String, dynamic> json) {
    return DashboardGraficos(
      productosConMenorStock: (json['productosConMenorStock'] as List? ?? [])
          .map((e) => ProductoStock.fromJson(e))
          .toList(),
      topProductosMasVendidos: (json['topProductosMasVendidos'] as List? ?? [])
          .map((e) => TopProducto.fromJson(e))
          .toList(),
      ingresosVsEgresosPorDia: (json['ingresosVsEgresosPorDia'] as List? ?? [])
          .map((e) => EvolucionDiaria.fromJson(e))
          .toList(),
    );
  }
}

class ProductoStock {
  final String nombre;
  final int stockActual;
  final int stockMinimo;
  final String estado; // "OK", "BAJO", o "AGOTADO"

  ProductoStock({
    required this.nombre, 
    required this.stockActual, 
    required this.stockMinimo, 
    required this.estado
  });

  factory ProductoStock.fromJson(Map<String, dynamic> json) {
    return ProductoStock(
      nombre: json['nombre'] ?? 'Desconocido',
      stockActual: json['stockActual'] ?? 0,
      stockMinimo: json['stockMinimo'] ?? 0,
      estado: json['estado'] ?? 'OK',
    );
  }
}

class TopProducto {
  final String nombre;
  final int cantidadVendida;
  final double montoTotal;

  /// Lo vendido menos su costo congelado (null si el backend no la manda).
  final double? ganancia;

  TopProducto({
    required this.nombre, 
    required this.cantidadVendida, 
    required this.montoTotal,
    this.ganancia,
  });

  factory TopProducto.fromJson(Map<String, dynamic> json) {
    return TopProducto(
      nombre: json['nombre'] ?? 'Desconocido',
      cantidadVendida: json['cantidadVendida'] ?? 0,
      montoTotal: (json['montoTotal'] ?? 0).toDouble(),
      ganancia: (json['ganancia'] as num?)?.toDouble(),
    );
  }
}

class EvolucionDiaria {
  final String fecha;
  final double ingresos;
  final double egresos;

  EvolucionDiaria({
    required this.fecha, 
    required this.ingresos, 
    required this.egresos
  });

  factory EvolucionDiaria.fromJson(Map<String, dynamic> json) {
    return EvolucionDiaria(
      fecha: json['fecha'] ?? '',
      ingresos: (json['ingresos'] ?? 0).toDouble(),
      egresos: (json['egresos'] ?? 0).toDouble(),
    );
  }
}