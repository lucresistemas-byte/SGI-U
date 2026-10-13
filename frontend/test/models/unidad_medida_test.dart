import 'package:flutter_test/flutter_test.dart';
import 'package:sgi_u_frontend/models/insumo.dart';
import 'package:sgi_u_frontend/models/unidad_medida.dart';

/// Etapa 2: conversiones dentro de cada familia (incluida la docena).
void main() {
  test('cada familia convierte a su unidad base', () {
    expect(UnidadMedida.kilo.aBase(2.5), 2500);
    expect(UnidadMedida.litro.aBase(0.15), 150);
    expect(UnidadMedida.metro.aBase(0.5), 50);
    expect(UnidadMedida.docena.aBase(2), 24);
    expect(UnidadMedida.docena.desdeBase(30), 2.5);
    expect(FamiliaUnidad.peso.base, UnidadMedida.gramo);
    expect(FamiliaUnidad.volumen.base, UnidadMedida.mililitro);
    expect(FamiliaUnidad.longitud.base, UnidadMedida.centimetro);
    expect(FamiliaUnidad.unidad.base, UnidadMedida.unidad);
  });

  test('cada familia ofrece solo sus unidades; CAJA no tiene familia', () {
    expect(FamiliaUnidad.peso.unidades, [UnidadMedida.gramo, UnidadMedida.kilo]);
    expect(FamiliaUnidad.unidad.unidades, [UnidadMedida.unidad, UnidadMedida.docena]);
    expect(UnidadMedida.conFamilia, isNot(contains(UnidadMedida.caja)));
  });

  test('Insumo: costo por cualquier unidad de su familia', () {
    final harina = Insumo.fromJson(const {
      'codigo': 'MP-0001',
      'nombre': 'Harina',
      'unidadMedida': 'KILO',
      'costoUnitario': 1200,
      'costoUnidadBase': 1.2,
      'stockActual': 2500,
    });
    expect(harina.familia, FamiliaUnidad.peso);
    expect(harina.costoPor(UnidadMedida.gramo), 1.2);
    expect(harina.costoPor(UnidadMedida.kilo), 1200);
    expect(harina.stockActual, 2500);
  });
}
