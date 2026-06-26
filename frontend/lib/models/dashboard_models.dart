// lib/models/dashboard_models.dart

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
  final double egresosPeriodo;
  final double saldoNeto;
  final double margenNetoPorcentaje; // El ajuste de rentabilidad
  final int cantidadVentas;
  final double ticketPromedio;
  final int cantidadProductosStockBajo;

  DashboardKpis({
    required this.ingresosPeriodo,
    required this.egresosPeriodo,
    required this.saldoNeto,
    required this.margenNetoPorcentaje,
    required this.cantidadVentas,
    required this.ticketPromedio,
    required this.cantidadProductosStockBajo,
  });

  factory DashboardKpis.fromJson(Map<String, dynamic> json) {
    return DashboardKpis(
      ingresosPeriodo: (json['ingresosPeriodo'] ?? 0).toDouble(),
      egresosPeriodo: (json['egresosPeriodo'] ?? 0).toDouble(),
      saldoNeto: (json['saldoNeto'] ?? 0).toDouble(),
      margenNetoPorcentaje: (json['margenNetoPorcentaje'] ?? 0).toDouble(),
      cantidadVentas: json['cantidadVentas'] ?? 0,
      ticketPromedio: (json['ticketPromedio'] ?? 0).toDouble(),
      cantidadProductosStockBajo: json['cantidadProductosStockBajo'] ?? 0,
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

  TopProducto({
    required this.nombre, 
    required this.cantidadVendida, 
    required this.montoTotal
  });

  factory TopProducto.fromJson(Map<String, dynamic> json) {
    return TopProducto(
      nombre: json['nombre'] ?? 'Desconocido',
      cantidadVendida: json['cantidadVendida'] ?? 0,
      montoTotal: (json['montoTotal'] ?? 0).toDouble(),
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