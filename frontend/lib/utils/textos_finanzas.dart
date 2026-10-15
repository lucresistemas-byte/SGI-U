/// Textos que explican, dentro de cada tarjeta de Dashboard, Balance y
/// Movimientos, cómo leer su número. Una sola fuente: el mismo concepto se
/// explica igual en las tres pantallas (glosario de docs/ANALISIS_FINANZAS.md).
///
/// [cuando] dice el período de la tarjeta: [entreFechas], [hoy] o [enElMes].
class TextosFinanzas {
  TextosFinanzas._();

  static const entreFechas = 'entre estas fechas';
  static const hoy = 'hoy';
  static const enElMes = 'en lo que va del mes';

  // --- Caja: la plata que entró y salió ---

  static String ingresos(String cuando) =>
      'Toda la plata que entró $cuando: lo que cobraste por ventas y los otros '
      'ingresos que cargaste a mano.';

  /// Ingresos con el filtro por tipo de producto del Dashboard.
  static String ingresosDeTipo(String cuando) =>
      'Lo que cobraste $cuando por las ventas de este tipo de producto.';

  static String egresos(String cuando) =>
      'Toda la plata que salió $cuando: gastos del negocio y también compras de '
      'mercadería.';

  static String saldoCaja(String cuando) =>
      'Es la plata que entró menos la que salió $cuando. No incluye la plata que '
      'había antes.';

  static const saldoCajaNegativo =
      'Salió más plata de la que entró. Puede ser por compras de mercadería que '
      'todavía está en stock.';

  // --- Resultado: cuánto se gana ---

  static const costo =
      'Lo que te costó hacer o comprar lo que vendiste: materia prima, insumos o '
      'mercadería de reventa.';

  static const ganancia =
      'Lo que te dejaron las ventas: lo que vendiste menos lo que te costó. '
      'Todavía no se restaron los gastos.';

  static const gananciaNegativa =
      'Vendiste por menos de lo que te costó: conviene revisar los precios.';

  /// [gastos]: el monto ya formateado ("$ 78.000,00").
  static String gananciaNeta(String gastos) =>
      'Lo que te dejaron las ventas después de pagar $gastos de gastos. Las '
      'compras de mercadería no se restan porque la mercadería sigue en stock.';

  static const gananciaNetaNegativa =
      'Las ventas del período no alcanzaron para cubrir los gastos.';

  // --- Ventas ---

  static String cantidadVentas(String cuando, {bool deTipo = false}) => deTipo
      ? 'Cuántas ventas con productos de este tipo cobraste $cuando en el Punto '
          'de Venta.'
      : 'Cuántas ventas cobraste $cuando en el Punto de Venta.';

  static const ticketPromedio =
      'Lo que gastó en promedio cada cliente en una compra.';

  /// Línea extra de Egresos, Saldo de caja y Ganancia neta con el filtro por
  /// tipo de producto del Dashboard.
  static const noSeFiltraPorTipo =
      'No se filtra por tipo: los gastos son de todo el negocio.';
}
