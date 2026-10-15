import 'package:flutter_test/flutter_test.dart';
import 'package:sgi_u_frontend/models/unidad_medida.dart';
import 'package:sgi_u_frontend/utils/numeros.dart';

/// Etapa 2: números con coma decimal (formato argentino) y cantidades amigables.
void main() {
  test('parseDecimal acepta coma decimal y puntos de miles', () {
    expect(parseDecimal('2,5'), 2.5);
    expect(parseDecimal('30.000'), 30000);
    expect(parseDecimal('1.234,56'), 1234.56);
    expect(parseDecimal('0,25'), 0.25);
    expect(parseDecimal('-500'), -500);
    expect(parseDecimal('2.5'), 2.5);
    expect(parseDecimal(''), isNull);
    expect(parseDecimal('abc'), isNull);
  });

  test('formatDecimal usa coma y no muestra ceros de más', () {
    expect(formatDecimal(2.5), '2,5');
    expect(formatDecimal(30000), '30.000');
    expect(formatDecimal(0.125), '0,125');
    expect(formatDecimal(1234.5, decimales: 2), '1.234,5');
  });

  test('formatPesos pone el signo adelante y decimales fijos', () {
    expect(formatPesos(1234.5), '\$ 1.234,50');
    expect(formatPesos(1.2, decimales: 4), '\$ 1,2000');
  });

  test('cantidades en unidad base se muestran de forma amigable', () {
    expect(textoEn(2500, UnidadMedida.kilo), '2,5 kg');
    expect(textoAmigable(2500, FamiliaUnidad.peso), '2,5 kg');
    expect(textoAmigable(800, FamiliaUnidad.peso), '800 g');
    expect(textoAmigable(1500, FamiliaUnidad.volumen), '1,5 l');
    expect(textoAmigable(50, FamiliaUnidad.longitud), '50 cm');
    expect(textoAmigable(1000, FamiliaUnidad.longitud), '10 m');
    expect(textoAmigable(36, FamiliaUnidad.unidad), '36 unidades');
  });

  test('stock con unidades amigables y en plural', () {
    expect(textoStock(4, 'UNIDAD'), '4 unidades');
    expect(textoStock(1, 'UNIDAD'), '1 unidad');
    expect(textoStock(0, 'GRAMO'), '0 g');
    expect(textoStock(2500, 'GRAMO'), '2,5 kg');
    expect(textoStock(2.5, 'KILO'), '2,5 kg');
    expect(textoStock(3, 'Caja'), '3 cajas');
    expect(textoStock(1, 'Caja'), '1 caja');
    expect(textoStock(2, 'DOCENA'), '2 docenas');
    expect(textoStock(-2, 'UNIDAD'), '−2 unidades');
    expect(textoStock(5, null), '5 unidades');
  });

  test('formatPesosConSigno: signo explícito y menos tipográfico', () {
    expect(formatPesosConSigno(38895), '+\$ 38.895,00');
    expect(formatPesosConSigno(-39105), '\u2212\$ 39.105,00');
    expect(formatPesosConSigno(0), '\$ 0,00');
  });
}
