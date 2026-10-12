import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../utils/es_mobile.dart';
import '../widgets/marca_negocio.dart';
import '../widgets/side_menu.dart';
import 'seccion.dart';

/// Contenedor de la app autenticada: menú lateral fijo y área de contenido
/// que cambia según la sección elegida, sin Navigator ni transiciones.
///
/// - Desktop (>= 900 px): menú a la izquierda, contenido a la derecha. El
///   menú es siempre el mismo widget, así que conserva su estado (colapsado).
/// - Móvil (< 900 px): AppBar con el título de la sección y menú en drawer;
///   al elegir una opción se cierra el drawer y cambia el contenido.
///
/// La sección visible se reconstruye cada vez que se muestra (recarga sus
/// datos). El carrito del POS no se pierde porque vive en el PosBloc global.
class AppShell extends StatefulWidget {
  const AppShell({
    super.key,
    this.seccionInicial = Seccion.catalogo,
    this.construirSeccion,
  });

  final Seccion seccionInicial;

  /// Reemplaza la pantalla de cada sección (para tests). Por defecto se usa
  /// [Seccion.construir].
  final Widget Function(Seccion seccion)? construirSeccion;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  late Seccion _seccion = widget.seccionInicial;

  @override
  void initState() {
    super.initState();
    // Nombre y logo para el menú desde el arranque (antes el nombre recién
    // aparecía después de entrar a Configuración).
    MarcaNegocio.cargar();
  }

  void _seleccionar(Seccion seccion) {
    _scaffoldKey.currentState?.closeDrawer();
    if (seccion != _seccion) setState(() => _seccion = seccion);
  }

  @override
  Widget build(BuildContext context) {
    final construir = widget.construirSeccion ?? (s) => s.construir();
    // La key fuerza a crear la sección de nuevo al volver a mostrarla.
    final contenido = KeyedSubtree(
      key: ValueKey(_seccion),
      child: construir(_seccion),
    );
    final menu = SideMenu(seccionActual: _seccion, onSeleccionar: _seleccionar);

    if (!esMobile(context)) {
      return Scaffold(
        key: _scaffoldKey,
        backgroundColor: AppColors.grisFondo,
        body: Row(
          children: [
            menu,
            Expanded(child: contenido),
          ],
        ),
      );
    }

    final drawerWidth =
        (MediaQuery.of(context).size.width * 0.70).clamp(280.0, 320.0);
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.grisFondo,
      appBar: AppBar(
        title: Text(_seccion.titulo),
        backgroundColor: AppColors.verdePrincipal,
        foregroundColor: AppColors.blanco,
      ),
      drawer: Drawer(width: drawerWidth, child: menu),
      body: contenido,
    );
  }
}
