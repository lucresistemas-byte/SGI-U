import 'package:flutter/material.dart';

/// En SGI-U los cambios de pantalla son instantáneos: ninguna navegación de
/// pantalla completa se anima. Los diálogos y SnackBars conservan las suyas.

/// Ruta de pantalla completa sin animación de entrada ni de salida.
Route<T> rutaInstantanea<T>(WidgetBuilder builder) => PageRouteBuilder<T>(
      pageBuilder: (context, _, __) => builder(context),
      transitionDuration: Duration.zero,
      reverseTransitionDuration: Duration.zero,
    );

/// Transición nula para pageTransitionsTheme: cualquier MaterialPageRoute
/// futura se muestra sin efecto visual.
class TransicionInstantanea extends PageTransitionsBuilder {
  const TransicionInstantanea();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) =>
      child;
}

/// Tema de transiciones sin animación para todas las plataformas.
final PageTransitionsTheme transicionesInstantaneas = PageTransitionsTheme(
  builders: {
    for (final plataforma in TargetPlatform.values)
      plataforma: const TransicionInstantanea(),
  },
);
