import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Guard *ratchet* del sistema de estilos.
///
/// Cuenta los valores de estilo hardcodeados fuera de `lib/theme/` y falla si
/// **suben** respecto de la línea base. La Etapa 2 los bajó migrando pantalla
/// por pantalla; el guard evita que vuelvan a aparecer.
///
/// Se cuentan:
/// - colores: `Color(0x…)` y `Colors.*`;
/// - tipografía: `fontSize: <número>` (los tamaños dinámicos, p. ej.
///   `fontSize: titleSize`, no cuentan: no son valores fijos);
/// - espaciado: un `EdgeInsets.*(...)` con algún número adentro;
/// - bordes: `BorderRadius.circular(<número>)` / `Radius.circular(<número>)`;
/// - elevación: `elevation: <número>`.
void main() {
  test('guard: sin regresión de hardcodeos fuera de lib/theme', () {
    // Línea base: 0 en todas las categorías tras el cierre de la Etapa 2
    // (Fase D10). Quedan fuera `lib/theme/` (define los tokens) y
    // `lib/services/` (usa el paquete `pdf`, otra tipografía: no aplica
    // `AppTypography`).
    const baselineColorHex = 0;
    const baselineColors = 0;
    const baselineFontSize = 0;
    const baselineEdgeInsets = 0;
    const baselineRadios = 0;
    const baselineElevacion = 0;

    final raiz = Directory('lib');
    expect(raiz.existsSync(), isTrue,
        reason: 'El test se corre desde la raíz del paquete (frontend/).');

    var colorHex = 0;
    var colors = 0;
    var fontSize = 0;
    var edgeInsets = 0;
    var radios = 0;
    var elevacion = 0;

    final reHex = RegExp(r'Color\(0x');
    final reColors = RegExp(r'(?<![A-Za-z_])Colors\.');
    final reFontSize = RegExp(r'fontSize:\s*[0-9]');
    final reEdgeInsets = RegExp(r'EdgeInsets\.\w+\([^)]*\)');
    final reRadio = RegExp(r'(?:Border)?Radius\.circular\(\s*[0-9]');
    final reElevacion = RegExp(r'elevation:\s*[0-9]');

    for (final entidad in raiz.listSync(recursive: true)) {
      if (entidad is! File || !entidad.path.endsWith('.dart')) continue;
      final ruta = entidad.path.replaceAll('\\', '/');
      if (ruta.contains('/theme/')) continue;
      if (ruta.contains('/services/')) continue;
      // Se colapsa el espacio para que un EdgeInsets repartido en varias
      // líneas se evalúe como una sola llamada.
      final texto = entidad.readAsStringSync().replaceAll(RegExp(r'\s+'), ' ');
      colorHex += reHex.allMatches(texto).length;
      colors += reColors.allMatches(texto).length;
      fontSize += reFontSize.allMatches(texto).length;
      for (final m in reEdgeInsets.allMatches(texto)) {
        if (RegExp(r'[0-9]').hasMatch(m.group(0)!)) edgeInsets++;
      }
      radios += reRadio.allMatches(texto).length;
      elevacion += reElevacion.allMatches(texto).length;
    }

    expect(colorHex, lessThanOrEqualTo(baselineColorHex),
        reason: 'Aumentaron los `Color(0x…)`: $colorHex (base $baselineColorHex). '
            'Usá los tokens de `lib/theme/`.');
    expect(colors, lessThanOrEqualTo(baselineColors),
        reason: 'Aumentaron los `Colors.*`: $colors (base $baselineColors). '
            'Usar los tokens del tema.');
    expect(fontSize, lessThanOrEqualTo(baselineFontSize),
        reason: 'Aumentaron los `fontSize` numéricos: $fontSize '
            '(base $baselineFontSize). Usar AppTypography.');
    expect(edgeInsets, lessThanOrEqualTo(baselineEdgeInsets),
        reason: 'Aumentaron los `EdgeInsets` con números: $edgeInsets '
            '(base $baselineEdgeInsets). Usar AppSpacing.');
    expect(radios, lessThanOrEqualTo(baselineRadios),
        reason: 'Aumentaron los `…Radius.circular(número)`: $radios '
            '(base $baselineRadios). Usar AppRadii.');
    expect(elevacion, lessThanOrEqualTo(baselineElevacion),
        reason: 'Aumentaron los `elevation:` numéricos: $elevacion '
            '(base $baselineElevacion). Usar AppElevations.');
  });
}
