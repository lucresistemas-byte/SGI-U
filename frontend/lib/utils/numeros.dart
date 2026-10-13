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

/// Cantidad en unidad base mostrada en una unidad dada: 2500 g en kilo → "2,5 kg".
String textoEn(double cantidadBase, UnidadMedida unidad) =>
    '${formatDecimal(unidad.desdeBase(cantidadBase))} ${unidad.abreviatura}';

/// Cantidad en unidad base mostrada de forma amigable: la unidad más grande
/// de la familia que no quede en menos de 1 (2500 g → "2,5 kg"; 800 g → "800 g").
String textoAmigable(double cantidadBase, FamiliaUnidad familia) {
  if (familia == FamiliaUnidad.unidad) {
    return textoEn(cantidadBase, UnidadMedida.unidad);
  }
  final grande = familia.unidades.last;
  return cantidadBase.abs() >= grande.factor ? textoEn(cantidadBase, grande) : textoEn(cantidadBase, familia.base);
}
