import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'paquetes_screen.dart';
import 'recetas_screen.dart';

/// Sección "Recetas y paquetes": dos pestañas, Recetas y Paquetes.
class RecetasYPaquetesScreen extends StatelessWidget {
  const RecetasYPaquetesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.grisFondo,
        body: Column(
          children: [
            Material(
              color: Colors.white,
              child: TabBar(
                key: Key('tabs_recetas_paquetes'),
                labelColor: AppColors.verdePrincipal,
                indicatorColor: AppColors.verdePrincipal,
                tabs: [
                  Tab(key: Key('tab_recetas'), icon: Icon(Icons.menu_book), text: 'Recetas'),
                  Tab(key: Key('tab_paquetes'), icon: Icon(Icons.card_giftcard), text: 'Paquetes'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [RecetasScreen(), PaquetesScreen()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
