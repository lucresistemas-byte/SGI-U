import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/side_menu.dart';
import '../utils/es_mobile.dart';

class AppScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final List<Widget>? actions;
  final String rutaActual;

  const AppScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions,
    required this.rutaActual,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final mobile = esMobile(context);

        if (!mobile) {
          // Desktop layout: Row with SideMenu on left
          return Scaffold(
            backgroundColor: AppColors.grisFondo,
            body: Row(
              children: [
                SideMenu(rutaActual: rutaActual),
                Expanded(child: body),
              ],
            ),
          );
        } else {
          // Mobile layout: Scaffold with AppBar and Drawer
          final drawerWidth =
              (MediaQuery.of(context).size.width * 0.70).clamp(280.0, 320.0);

          return Scaffold(
            backgroundColor: AppColors.grisFondo,
            appBar: AppBar(
              title: Text(title),
              backgroundColor: AppColors.verdePrincipal,
              foregroundColor: AppColors.blanco,
              actions: actions ?? [],
            ),
            drawer: Drawer(
              width: drawerWidth,
              child: SideMenu(rutaActual: rutaActual),
            ),
            body: body,
          );
        }
      },
    );
  }
}
