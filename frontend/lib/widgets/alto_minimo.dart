import 'package:flutter/material.dart';

/// Pantallas con tarjetas arriba y una tabla que ocupa el resto (Expanded):
/// si la ventana es más baja que [minimo], toda la pantalla se desplaza
/// verticalmente con ese alto, en vez de desbordar o dejar la tabla sin lugar.
class AltoMinimo extends StatelessWidget {
  final double minimo;
  final Widget child;

  const AltoMinimo({super.key, required this.minimo, required this.child});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      if (constraints.maxHeight >= minimo) return child;
      return SingleChildScrollView(
        child: SizedBox(height: minimo, child: child),
      );
    });
  }
}
