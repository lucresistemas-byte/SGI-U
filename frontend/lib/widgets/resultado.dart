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

/// Explicación de una tarjeta de resumen, debajo del monto: chica y en un
/// color secundario. [siNegativo] se agrega solo cuando [negativo] es true;
/// [extras] son líneas adicionales (p. ej. "No se filtra por tipo").
class ExplicacionMonto extends StatelessWidget {
  final String texto;
  final String? siNegativo;
  final bool negativo;
  final List<String> extras;
  final Color color;
  final Color colorNegativo;
  final TextAlign textAlign;

  const ExplicacionMonto(
    this.texto, {
    super.key,
    this.siNegativo,
    this.negativo = false,
    this.extras = const [],
    this.color = const Color(0xFF666666),
    this.colorNegativo = const Color(0xFFB71C1C),
    this.textAlign = TextAlign.start,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          textAlign == TextAlign.center ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(texto, textAlign: textAlign, style: TextStyle(fontSize: 12, height: 1.3, color: color)),
        if (negativo && siNegativo != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(siNegativo!,
                textAlign: textAlign,
                style: TextStyle(fontSize: 12, height: 1.3, fontWeight: FontWeight.w600, color: colorNegativo)),
          ),
        for (final extra in extras)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(extra,
                textAlign: textAlign,
                style: TextStyle(fontSize: 12, height: 1.3, fontStyle: FontStyle.italic, color: color)),
          ),
      ],
    );
  }
}
