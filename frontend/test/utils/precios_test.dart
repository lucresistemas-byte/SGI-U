import 'package:flutter_test/flutter_test.dart';
import 'package:sgi_u_frontend/utils/numeros.dart';

/// Etapa 4: todo precio de venta se redondea hacia arriba a $100.
void main() {
  test('redondea hacia arriba al próximo múltiplo de \$100', () {
    expect(redondearA100(3601), 3700);
    expect(redondearA100(3600), 3600);
    expect(redondearA100(3600.01), 3700);
    expect(redondearA100(0.01), 100);
    expect(redondearA100(0), 0);
    // El error de coma flotante no sube un escalón: 2250 × 1,6 = 3600,0000000000005.
    expect(redondearA100(2250 * 1.6), 3600);
  });

  test('precio mínimo: costo × (1 + %), redondeado', () {
    expect(precioMinimo(2250, 60), 3600);
    expect(precioMinimo(70.63, 100), 200);
    expect(precioMinimo(1500, 50), 2300);
  });
}
