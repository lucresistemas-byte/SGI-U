import 'dart:async';

import 'package:flutter/material.dart';

/// Indicador de carga del área de contenido de una sección: no muestra nada
/// durante [demora] y recién después un spinner centrado. Así las cargas
/// rápidas no parpadean con un spinner que aparece y desaparece.
class CargandoDiferido extends StatefulWidget {
  static const Duration demoraPorDefecto = Duration(milliseconds: 300);

  final Duration demora;
  final Color? color;

  const CargandoDiferido({
    super.key,
    this.demora = demoraPorDefecto,
    this.color,
  });

  @override
  State<CargandoDiferido> createState() => _CargandoDiferidoState();
}

class _CargandoDiferidoState extends State<CargandoDiferido> {
  Timer? _timer;
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer(widget.demora, () {
      if (mounted) setState(() => _visible = true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_visible) return const SizedBox.shrink();
    return Center(child: CircularProgressIndicator(color: widget.color));
  }
}
