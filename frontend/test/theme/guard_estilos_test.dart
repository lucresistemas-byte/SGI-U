import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Guard *ratchet* del sistema de estilos.
///
/// Cuenta los valores de estilo hardcodeados fuera de `lib/theme/` y falla si
/// **suben** respecto de la línea base. La Etapa 2 los baja migrando pantalla
/// por pantalla; el guard evita que vuelvan a aparecer.
void main() {
  test('guard: sin regresión de hardcodeos fuera de lib/theme', () {
    // Línea base medida al cerrar la Fase A de la Etapa 2.
    // Quedan fuera `lib/theme/` (define los tokens) y `lib/services/` (usa el
    // paquete `pdf`, otra tipografía: no aplica `AppTypography`).
    const baselineColorHex = 243;
    const baselineColors = 150;
    const baselineFontSize = 112;

    final raiz = Directory('lib');
    expect(raiz.existsSync(), isTrue,
        reason: 'El test se corre desde la raíz del paquete (frontend/).');

    var colorHex = 0;
    var colors = 0;
    var fontSize = 0;

    final reHex = RegExp(r'Color\(0x');
    final reColors = RegExp(r'(?<![A-Za-z_])Colors\.');
    final reFontSize = RegExp(r'fontSize');

    for (final entidad in raiz.listSync(recursive: true)) {
      if (entidad is! File || !entidad.path.endsWith('.dart')) continue;
      final ruta = entidad.path.replaceAll('\\', '/');
      if (ruta.contains('/theme/')) continue;
      if (ruta.contains('/services/')) continue;
      final texto = entidad.readAsStringSync();
      colorHex += reHex.allMatches(texto).length;
      colors += reColors.allMatches(texto).length;
      fontSize += reFontSize.allMatches(texto).length;
    }

    expect(colorHex, lessThanOrEqualTo(baselineColorHex),
        reason: 'Aumentaron los `Color(0x…)`: $colorHex (base $baselineColorHex). '
            'Usá los tokens de `lib/theme/`.');
    expect(colors, lessThanOrEqualTo(baselineColors),
        reason: 'Aumentaron los `Colors.*`: $colors (base $baselineColors). '
            'Usar los tokens del tema.');
    expect(fontSize, lessThanOrEqualTo(baselineFontSize),
        reason: 'Aumentaron los `fontSize` literales: $fontSize '
            '(base $baselineFontSize). Usar AppTypography.');
  });
}
