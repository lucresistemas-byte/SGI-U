// lib/models/resultado_periodo.dart

/// Resultado de un período en pesos (ResultadoPeriodoDTO del backend). Las
/// compras de mercadería no se restan de la ganancia neta: su costo ya está
/// en [costoVendido] cuando se vende.
class ResultadoPeriodo {
  final double ventas;
  final double costoVendido;
  final double gananciaBruta;
  final double? margenBrutoPorcentaje;
  final double otrosIngresos;
  final double gastos;
  final double comprasMercaderia;
  final double gananciaNeta;
  final double? margenNetoPorcentaje;

  const ResultadoPeriodo({
    this.ventas = 0,
    this.costoVendido = 0,
    this.gananciaBruta = 0,
    this.margenBrutoPorcentaje,
    this.otrosIngresos = 0,
    this.gastos = 0,
    this.comprasMercaderia = 0,
    this.gananciaNeta = 0,
    this.margenNetoPorcentaje,
  });

  factory ResultadoPeriodo.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const ResultadoPeriodo();
    double d(String k) => (json[k] as num?)?.toDouble() ?? 0;
    return ResultadoPeriodo(
      ventas: d('ventas'),
      costoVendido: d('costoVendido'),
      gananciaBruta: d('gananciaBruta'),
      margenBrutoPorcentaje: (json['margenBrutoPorcentaje'] as num?)?.toDouble(),
      otrosIngresos: d('otrosIngresos'),
      gastos: d('gastos'),
      comprasMercaderia: d('comprasMercaderia'),
      gananciaNeta: d('gananciaNeta'),
      margenNetoPorcentaje: (json['margenNetoPorcentaje'] as num?)?.toDouble(),
    );
  }
}
