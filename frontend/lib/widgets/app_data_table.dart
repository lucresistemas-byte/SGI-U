import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'tabla_ajustada.dart';

/// Tabla del sistema: [DataTable] con el estilo del tema y, por defecto,
/// envuelta en [TablaAjustada] para ocupar el ancho disponible sin scroll
/// horizontal (absorbe esa pieza sin cambiar su API).
class AppDataTable extends StatelessWidget {
  final List<DataColumn> columnas;
  final List<DataRow> filas;

  /// Color de la fila de encabezado (por defecto [AppColors.fondoAlternativo]).
  final Color? colorEncabezado;

  /// `false` para dejar la [DataTable] suelta (sin [TablaAjustada]).
  final bool ajustarAncho;

  /// Alto máximo de cada fila. `null` deja el valor por defecto de [DataTable].
  final double? altoFilaMaximo;

  /// Separación horizontal entre columnas (default de [DataTable] si es `null`).
  final double? separacionColumnas;

  /// Margen horizontal del borde de la tabla.
  final double? margenHorizontal;

  const AppDataTable({
    super.key,
    required this.columnas,
    required this.filas,
    this.colorEncabezado,
    this.ajustarAncho = true,
    this.altoFilaMaximo,
    this.separacionColumnas,
    this.margenHorizontal,
  });

  @override
  Widget build(BuildContext context) {
    final tabla = DataTable(
      columns: columnas,
      rows: filas,
      dataRowMaxHeight: altoFilaMaximo,
      columnSpacing: separacionColumnas,
      horizontalMargin: margenHorizontal,
      headingRowColor: WidgetStatePropertyAll(
        colorEncabezado ?? AppColors.fondoAlternativo,
      ),
      headingTextStyle: AppTypography.etiqueta.copyWith(
        color: AppColors.textoSecundario,
        fontWeight: FontWeight.w700,
      ),
      dataTextStyle: AppTypography.textoChico
          .copyWith(color: AppColors.textoPrincipal),
      dividerThickness: 1,
    );
    return ajustarAncho ? TablaAjustada(tabla: tabla) : tabla;
  }
}
