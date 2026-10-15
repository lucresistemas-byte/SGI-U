import 'package:flutter/material.dart';

/// Atajos del selector de período de Inicio y Ganancias.
enum TipoPeriodo {
  hoy('Hoy'),
  semana('Esta semana'),
  mes('Este mes'),
  mesPasado('Mes pasado'),
  elegido('Elegir fechas');

  const TipoPeriodo(this.etiqueta);

  final String etiqueta;
}

/// Un rango de días [desde, hasta], ambos incluidos, sin hora.
class Periodo {
  final TipoPeriodo tipo;
  final DateTime desde;
  final DateTime hasta;

  Periodo._(this.tipo, DateTime desde, DateTime hasta)
      : desde = DateUtils.dateOnly(desde),
        hasta = DateUtils.dateOnly(hasta);

  /// El rango de un atajo visto desde [hoy]. La semana va de lunes a hoy;
  /// el mes, del 1 a hoy; el mes pasado, completo.
  factory Periodo.de(TipoPeriodo tipo, DateTime hoy) {
    final dia = DateUtils.dateOnly(hoy);
    return switch (tipo) {
      TipoPeriodo.hoy => Periodo._(tipo, dia, dia),
      TipoPeriodo.semana =>
        Periodo._(tipo, dia.subtract(Duration(days: dia.weekday - DateTime.monday)), dia),
      TipoPeriodo.mes => Periodo._(tipo, DateTime(dia.year, dia.month, 1), dia),
      TipoPeriodo.mesPasado => Periodo._(
          tipo, DateTime(dia.year, dia.month - 1, 1), DateTime(dia.year, dia.month, 0)),
      // Sin fechas elegidas todavía: el mes en curso.
      TipoPeriodo.elegido => Periodo._(tipo, DateTime(dia.year, dia.month, 1), dia),
    };
  }

  /// Fechas elegidas a mano (en cualquier orden).
  factory Periodo.elegido(DateTime a, DateTime b) =>
      a.isAfter(b) ? Periodo._(TipoPeriodo.elegido, b, a) : Periodo._(TipoPeriodo.elegido, a, b);

  /// Lo que se usa por defecto en Inicio y Ganancias.
  factory Periodo.porDefecto([DateTime? hoy]) => Periodo.de(TipoPeriodo.mes, hoy ?? DateTime.now());

  @override
  bool operator ==(Object other) =>
      other is Periodo && other.tipo == tipo && other.desde == desde && other.hasta == hasta;

  @override
  int get hashCode => Object.hash(tipo, desde, hasta);

  @override
  String toString() => 'Periodo($tipo, $desde, $hasta)';
}
