import 'package:flutter/material.dart';
import '../utils/numeros.dart';

/// Verde si es positivo o cero, rojo si es negativo (ganancias).
Color colorResultado(double valor) =>
    valor < 0 ? const Color(0xFFD32F2F) : const Color(0xFF008A3D);

/// Porcentaje chico al lado de un monto: 50.64 → "50,6 %", -50.92 →
/// "−50,9 %" (mismo signo menos que [formatPesosConSigno]).
String formatPorcentaje(double porcentaje) {
  final texto = '${formatDecimal(porcentaje.abs(), decimales: 1)} %';
  return porcentaje < 0 ? '\u2212$texto' : texto;
}

/// Ícono ⓘ con una explicación al pasar el mouse o mantener apretado.
class AyudaInfo extends StatelessWidget {
  final String texto;
  final Color color;

  const AyudaInfo(this.texto, {super.key, this.color = const Color(0xFF888888)});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: texto,
      triggerMode: TooltipTriggerMode.tap,
      showDuration: const Duration(seconds: 8),
      constraints: const BoxConstraints(maxWidth: 320),
      child: Icon(Icons.info_outline, size: 16, color: color),
    );
  }
}
