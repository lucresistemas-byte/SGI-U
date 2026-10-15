import 'package:flutter/widgets.dart';
import 'seccion.dart';

/// Permite que una pantalla pida a AppShell mostrar otra sección (por
/// ejemplo, "Ver en Productos" desde Inicio). Fuera de AppShell (tests de una
/// pantalla suelta) no hay ninguna y [de] devuelve null.
class IrASeccion extends InheritedWidget {
  const IrASeccion({super.key, required this.ir, required super.child});

  final ValueChanged<Seccion> ir;

  static ValueChanged<Seccion>? de(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<IrASeccion>()?.ir;

  @override
  bool updateShouldNotify(IrASeccion oldWidget) => oldWidget.ir != ir;
}
