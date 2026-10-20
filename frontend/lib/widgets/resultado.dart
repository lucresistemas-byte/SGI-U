import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../utils/numeros.dart';

/// Verde si es positivo o cero, rojo si es negativo (ganancias).
Color colorResultado(double valor) =>
    valor < 0 ? AppColors.error : AppColors.exito;

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

  const AyudaInfo(this.texto, {super.key, this.color = AppColors.textoTerciario});

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
    this.color = AppColors.textoTerciario,
    this.colorNegativo = AppColors.error,
    this.textAlign = TextAlign.start,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          textAlign == TextAlign.center ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(texto,
            textAlign: textAlign,
            style: AppTypography.etiqueta.copyWith(height: 1.3, color: color)),
        if (negativo && siNegativo != null)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.espacioMinimo),
            child: Text(siNegativo!,
                textAlign: textAlign,
                style: AppTypography.etiqueta.copyWith(
                    height: 1.3, fontWeight: FontWeight.w600, color: colorNegativo)),
          ),
        for (final extra in extras)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.espacioMinimo),
            child: Text(extra,
                textAlign: textAlign,
                style: AppTypography.etiqueta
                    .copyWith(height: 1.3, fontStyle: FontStyle.italic, color: color)),
          ),
      ],
    );
  }
}
