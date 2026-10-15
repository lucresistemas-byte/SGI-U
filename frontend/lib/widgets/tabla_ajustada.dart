import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// Ancho de una columna de [TablaAjustada]. Sin [flexible] va a su ancho
/// natural (botones, montos, estados no se cortan). Con [flexible] se queda
/// con el ancho que sobra y, si falta lugar, sus textos pasan a más renglones;
/// su encabezado va siempre entero (la fila de encabezado de la [DataTable] no
/// corta palabras: se saldría de la celda).
class ColumnaAjustable extends TableColumnWidth {
  final double? flexible;

  const ColumnaAjustable({this.flexible});

  @override
  double minIntrinsicWidth(Iterable<RenderBox> cells, double containerWidth) {
    if (flexible == null) return maxIntrinsicWidth(cells, containerWidth);
    var ancho = 0.0;
    var encabezado = true;
    for (final celda in cells) {
      ancho = math.max(
          ancho,
          encabezado
              ? celda.getMaxIntrinsicWidth(double.infinity)
              : celda.getMinIntrinsicWidth(double.infinity));
      encabezado = false;
    }
    return ancho;
  }

  @override
  double maxIntrinsicWidth(Iterable<RenderBox> cells, double containerWidth) {
    var ancho = 0.0;
    for (final celda in cells) {
      ancho = math.max(ancho, celda.getMaxIntrinsicWidth(double.infinity));
    }
    return ancho;
  }

  @override
  double? flex(Iterable<RenderBox> cells) => flexible;
}

/// Columna de ancho natural.
const columnaAjustable = ColumnaAjustable();

/// Columna que se queda con el ancho que sobra (el nombre, la descripción).
const columnaFlexible = ColumnaAjustable(flexible: 3);

/// Columna de texto secundario (categoría, motivo) que también se achica si
/// falta lugar, después de la principal.
const columnaFlexibleSecundaria = ColumnaAjustable(flexible: 1);

/// Envuelve una [DataTable] para que ocupe el ancho disponible sin scroll
/// horizontal: la columna [columnaFlexible] se queda con lo que sobra y, si
/// falta lugar, sus textos pasan a dos renglones, así Acciones siempre se ve.
/// Todas las columnas usan una [ColumnaAjustable].
/// Solo si ni así entra (pantalla muy angosta) aparece el scroll horizontal,
/// en vez de cortar las columnas.
class TablaAjustada extends StatelessWidget {
  final DataTable tabla;

  const TablaAjustada({super.key, required this.tabla});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: _AnchoAlMenos(ancho: constraints.maxWidth, child: tabla),
          ),
        );
      },
    );
  }
}

/// Le da al hijo el ancho [ancho] o, si no le alcanza, el mínimo que necesita.
class _AnchoAlMenos extends SingleChildRenderObjectWidget {
  final double ancho;

  const _AnchoAlMenos({required this.ancho, super.child});

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderAnchoAlMenos(ancho);

  @override
  void updateRenderObject(BuildContext context, _RenderAnchoAlMenos renderObject) => renderObject.ancho = ancho;
}

class _RenderAnchoAlMenos extends RenderProxyBox {
  _RenderAnchoAlMenos(this._ancho);

  double _ancho;
  set ancho(double valor) {
    if (valor == _ancho) return;
    _ancho = valor;
    markNeedsLayout();
  }

  @override
  void performLayout() {
    final hijo = child!;
    final ancho = math.max(_ancho, hijo.getMinIntrinsicWidth(double.infinity));
    hijo.layout(constraints.copyWith(minWidth: ancho, maxWidth: ancho), parentUsesSize: true);
    size = constraints.constrain(hijo.size);
  }
}
