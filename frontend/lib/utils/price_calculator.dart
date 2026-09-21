class PriceCalculator {
  /// Calcula el precio de venta a partir del costo y el porcentaje de ganancia.
  /// Fórmula: precioVenta = costo * (1 + porcentaje / 100)
  /// Retorna null si costo o porcentaje son negativos.
  static double? calcularPrecioVenta(double costo, double porcentajeGanancia) {
    if (costo < 0 || porcentajeGanancia < 0) return null;
    final venta = costo * (1.0 + (porcentajeGanancia / 100.0));
    return double.parse(venta.toStringAsFixed(2));
  }

  /// Calcula el porcentaje de ganancia a partir del costo y el precio de venta.
  /// Fórmula: porcentaje = ((precioVenta - costo) / costo) * 100
  /// Retorna null si costo <= 0 o venta <= 0.
  static double? calcularPorcentajeGanancia(double costo, double precioVenta) {
    if (costo <= 0 || precioVenta <= 0) return null;
    final porcentaje = ((precioVenta - costo) / costo) * 100.0;
    return double.parse(porcentaje.toStringAsFixed(2));
  }

  /// Calcula el precio de costo a partir del precio de venta y el porcentaje de ganancia.
  /// Fórmula: costo = precioVenta / (1 + porcentaje / 100)
  /// Retorna null si venta <= 0 o porcentaje < 0.
  static double? calcularPrecioCosto(double precioVenta, double porcentajeGanancia) {
    if (precioVenta <= 0 || porcentajeGanancia < 0) return null;
    final divisor = 1.0 + (porcentajeGanancia / 100.0);
    if (divisor <= 0) return null;
    final costo = precioVenta / divisor;
    return double.parse(costo.toStringAsFixed(2));
  }
}
