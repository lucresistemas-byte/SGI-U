import 'package:flutter_test/flutter_test.dart';
import 'package:sgi_u_frontend/utils/periodo.dart';

void main() {
  // Jueves 15 de octubre de 2026 (a media tarde).
  final jueves = DateTime(2026, 10, 15, 17, 30);

  void rango(Periodo p, DateTime desde, DateTime hasta) {
    expect(p.desde, desde);
    expect(p.hasta, hasta);
  }

  test('hoy, esta semana (desde el lunes), este mes y mes pasado', () {
    rango(Periodo.de(TipoPeriodo.hoy, jueves), DateTime(2026, 10, 15), DateTime(2026, 10, 15));
    rango(Periodo.de(TipoPeriodo.semana, jueves), DateTime(2026, 10, 12), DateTime(2026, 10, 15));
    rango(Periodo.de(TipoPeriodo.mes, jueves), DateTime(2026, 10, 1), DateTime(2026, 10, 15));
    rango(Periodo.de(TipoPeriodo.mesPasado, jueves), DateTime(2026, 9, 1), DateTime(2026, 9, 30));
  });

  test('la semana empieza el lunes: lunes y domingo', () {
    rango(Periodo.de(TipoPeriodo.semana, DateTime(2026, 10, 12, 9)), DateTime(2026, 10, 12), DateTime(2026, 10, 12));
    rango(Periodo.de(TipoPeriodo.semana, DateTime(2026, 10, 18, 9)), DateTime(2026, 10, 12), DateTime(2026, 10, 18));
  });

  test('mes pasado en enero es diciembre del año anterior; febrero bisiesto', () {
    rango(Periodo.de(TipoPeriodo.mesPasado, DateTime(2027, 1, 10)), DateTime(2026, 12, 1), DateTime(2026, 12, 31));
    rango(Periodo.de(TipoPeriodo.mesPasado, DateTime(2028, 3, 5)), DateTime(2028, 2, 1), DateTime(2028, 2, 29));
  });

  test('por defecto es este mes; fechas elegidas en cualquier orden', () {
    expect(Periodo.porDefecto(jueves), Periodo.de(TipoPeriodo.mes, jueves));
    final p = Periodo.elegido(DateTime(2026, 10, 9, 23), DateTime(2026, 10, 3));
    expect(p.tipo, TipoPeriodo.elegido);
    rango(p, DateTime(2026, 10, 3), DateTime(2026, 10, 9));
  });
}
