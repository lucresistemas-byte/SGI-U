import 'package:intl/intl.dart';

import '../models/unidad_medida.dart';

/// Lee un número escrito con coma decimal (formato argentino): "2,5",
/// "30.000", "1.234,56". Sin coma, un punto se toma como decimal ("2.5").
double? parseDecimal(String? texto) {
  if (texto == null) return null;
  var t = texto.trim().replaceAll(' ', '').replaceAll('\$', '');
  if (t.isEmpty) return null;
  if (t.contains(',')) {
    t = t.replaceAll('.', '').replaceAll(',', '.');
  } else if (RegExp(r'^-?\d{1,3}(\.\d{3})+$').hasMatch(t)) {
    // "30.000": puntos de miles.
    t = t.replaceAll('.', '');
  }
  return double.tryParse(t);
}

/// Número con coma decimal y hasta [decimales] decimales: 2.5 → "2,5".
String formatDecimal(double valor, {int decimales = 3}) {
  final patron = decimales == 0 ? '#,##0' : '#,##0.${'#' * decimales}';
  return NumberFormat(patron, 'es_AR').format(valor);
}

/// Pesos con [decimales] decimales fijos: 1234.5 → "$ 1.234,50".
String formatPesos(double valor, {int decimales = 2}) {
  final patron = decimales == 0 ? '#,##0' : '#,##0.${'0' * decimales}';
  return '\$ ${NumberFormat(patron, 'es_AR').format(valor)}';
}

/// Cantidad en unidad base mostrada en una unidad dada: 2500 g en kilo →
/// "2,5 kg". Las unidades que se cuentan van con su nombre: "4 unidades".
String textoEn(double cantidadBase, UnidadMedida unidad) {
  final cantidad = unidad.desdeBase(cantidadBase);
  final contable = unidad.familia == null || unidad.familia == FamiliaUnidad.unidad;
  return '${formatDecimal(cantidad)} ${contable ? nombreUnidad(unidad.nombre, cantidad) : unidad.abreviatura}';
}

/// Nombre de una unidad que se cuenta, en minúscula y en plural salvo para 1:
/// "unidad" → "unidades", "Caja" → "cajas".
String nombreUnidad(String nombre, num cantidad) {
  final n = nombre.trim().toLowerCase();
  if (n.isEmpty || cantidad.abs() == 1) return n;
  if (RegExp(r'[aeiouáéó]$').hasMatch(n)) return '${n}s';
  if (n.endsWith('s')) return n;
  if (n.endsWith('z')) return '${n.substring(0, n.length - 1)}ces';
  return '${n}es';
}

/// Stock de un artículo en la unidad que viene de la API ("UNIDAD", "GRAMO",
/// o el nombre de la unidad de venta, "Caja"), para leer: "4 unidades",
/// "0 g", "2,5 kg", "3 cajas". El signo menos es "−".
String textoStock(num cantidad, String? unidad) {
  final medida = UnidadMedida.deCodigo(unidad ?? 'UNIDAD');
  final String texto;
  if (medida == null) {
    texto = '${formatDecimal(cantidad.toDouble())} ${nombreUnidad(unidad!, cantidad)}';
  } else if (medida.familia == null || medida.familia == FamiliaUnidad.unidad) {
    texto = textoEn(medida.aBase(cantidad.toDouble()), medida);
  } else {
    texto = textoAmigable(medida.aBase(cantidad.toDouble()), medida.familia!);
  }
  return texto.replaceAll('-', '−');
}

/// Cantidad en unidad base mostrada de forma amigable: la unidad más grande
/// de la familia que no quede en menos de 1 (2500 g → "2,5 kg"; 800 g → "800 g").
String textoAmigable(double cantidadBase, FamiliaUnidad familia) {
  if (familia == FamiliaUnidad.unidad) {
    return textoEn(cantidadBase, UnidadMedida.unidad);
  }
  final grande = familia.unidades.last;
  return cantidadBase.abs() >= grande.factor ? textoEn(cantidadBase, grande) : textoEn(cantidadBase, familia.base);
}

/// Precio de venta: hacia arriba al próximo múltiplo de $100 ($3.601 → $3.700),
/// igual que el backend (CostosService).
double redondearA100(double precio) {
  if (precio <= 0) return 0;
  // Se tolera el error de coma flotante (3600,0000001 no pasa a 3700).
  return ((precio - 1e-6) / 100).ceilToDouble() * 100;
}

/// Precio que calcula el sistema con el % de ganancia: costo × (1 + %), a $100.
double precioMinimo(double costo, double porcentaje) => redondearA100(minimoExacto(costo, porcentaje));

/// Lo mínimo que tiene que valer un precio a mano (sin redondear): costo × (1 + %).
double minimoExacto(double costo, double porcentaje) => costo * (1 + porcentaje / 100);
