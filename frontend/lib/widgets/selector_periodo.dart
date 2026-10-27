import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../utils/periodo.dart';

/// Hoy · Esta semana · Este mes · Mes pasado · Elegir fechas. Cada opción se
/// aplica en el momento (sin botón "Filtrar"); "Elegir fechas" abre el
/// calendario y, si se cancela, queda el período anterior.
class SelectorPeriodo extends StatelessWidget {
  final Periodo periodo;
  final ValueChanged<Periodo> onCambio;

  /// Para tests: el día que se toma como hoy.
  final DateTime? hoy;

  const SelectorPeriodo({super.key, required this.periodo, required this.onCambio, this.hoy});

  static final _fecha = DateFormat('dd/MM/yyyy');

  Future<void> _elegir(BuildContext context, TipoPeriodo tipo) async {
    final ahora = hoy ?? DateTime.now();
    if (tipo != TipoPeriodo.elegido) {
      onCambio(Periodo.de(tipo, ahora));
      return;
    }
    final rango = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: ahora,
      initialDateRange: DateTimeRange(start: periodo.desde, end: periodo.hasta),
      helpText: 'Elegí desde y hasta qué día',
      builder: (context, child) => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 450, maxHeight: 580),
          child: child,
        ),
      ),
    );
    if (rango != null) onCambio(Periodo.elegido(rango.start, rango.end));
  }

  @override
  Widget build(BuildContext context) {
    final rango = periodo.desde == periodo.hasta
        ? _fecha.format(periodo.desde)
        : '${_fecha.format(periodo.desde)} al ${_fecha.format(periodo.hasta)}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final tipo in TipoPeriodo.values)
              ChoiceChip(
                key: Key('periodo_${tipo.name}'),
                label: Text(tipo == TipoPeriodo.elegido ? '${tipo.etiqueta}…' : tipo.etiqueta),
                avatar: tipo == TipoPeriodo.elegido ? const Icon(Icons.calendar_today, size: 16) : null,
                selected: periodo.tipo == tipo,
                showCheckmark: false,
                selectedColor: AppColors.seleccionFondo,
                onSelected: (_) => _elegir(context, tipo),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.espacioChico),
        Text(rango,
            key: const Key('periodo_rango'),
            style: AppTypography.etiqueta.copyWith(color: AppColors.textoTerciario)),
      ],
    );
  }
}
