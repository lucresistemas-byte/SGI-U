import 'package:flutter/material.dart';
import '../screens/balance_screen.dart';
import '../screens/catalogo_screen.dart';
import '../screens/dashboard_screen.dart';
import '../screens/insumos_screen.dart';
import '../screens/movimientos_screen.dart';
import '../screens/pedidos_screen.dart';
import '../screens/pos_screen.dart';
import '../screens/recetas_y_paquetes_screen.dart';
import '../screens/settings_screen.dart';

/// Secciones de la app que se muestran dentro de AppShell, en el orden del
/// menú lateral. Agregar una sección es agregar un valor acá.
enum Seccion {
  pos(Icons.storefront_outlined, 'Punto de Venta', 'Punto de Venta'),
  movimientos(Icons.receipt_long, 'Movimientos', 'Movimientos'),
  catalogo(Icons.inventory_2, 'Productos', 'Productos'),
  insumos(Icons.egg_outlined, 'Materia Prima', 'Materia Prima / Insumos'),
  recetas(Icons.menu_book, 'Recetas y paquetes', 'Recetas y paquetes'),
  pedidos(Icons.assignment_outlined, 'Pedidos', 'Pedidos con Seña'),
  balance(Icons.balance, 'Balance', 'Balance'),
  dashboard(Icons.dashboard_outlined, 'Dashboard', 'Dashboard'),
  settings(Icons.settings_outlined, 'Configuración', 'Configuración');

  const Seccion(this.icono, this.etiqueta, this.titulo);

  final IconData icono;

  /// Texto de la opción en el menú lateral.
  final String etiqueta;

  /// Título del AppBar en móvil.
  final String titulo;

  /// Pantalla de la sección. Se construye de nuevo cada vez que se muestra,
  /// así recarga sus datos en initState.
  Widget construir() => switch (this) {
        Seccion.pos => const PosScreen(),
        Seccion.movimientos => const MovimientosScreen(),
        Seccion.catalogo => const CatalogoScreen(),
        Seccion.insumos => const InsumosScreen(),
        Seccion.recetas => const RecetasYPaquetesScreen(),
        Seccion.pedidos => const PedidosScreen(),
        Seccion.balance => const BalanceScreen(),
        Seccion.dashboard => const DashboardScreen(),
        Seccion.settings => const SettingsScreen(),
      };
}
