import 'package:flutter/material.dart';
import '../screens/catalogo_screen.dart';
import '../screens/pos_screen.dart'; // Asegurate de que esta ruta sea correcta

class SideMenu extends StatefulWidget {
  // Le pasamos la ruta actual para que sepa qué botón pintar de verde
  final String rutaActual;
  const SideMenu({super.key, required this.rutaActual});

  @override
  State<SideMenu> createState() => _SideMenuState();
}

class _SideMenuState extends State<SideMenu> {
  // Variable que controla si el menú está abierto (260px) o cerrado (80px)
  bool _isCollapsed = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: _isCollapsed ? 80 : 260,
      color: const Color(0xFFF8F9FA),
      clipBehavior: Clip.hardEdge,
      child: Column(
        crossAxisAlignment:
            _isCollapsed ? CrossAxisAlignment.center : CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Row(
              mainAxisAlignment: _isCollapsed
                  ? MainAxisAlignment.center
                  : MainAxisAlignment.start,
              children: [
                // El botón de la hamburguesa que contrae/expande
                InkWell(
                  onTap: () => setState(() => _isCollapsed = !_isCollapsed),
                  child: const Icon(Icons.menu, color: Color(0xFF455A64)),
                ),
                if (!_isCollapsed) ...[
                  const SizedBox(width: 16),
                  const Text('SGI-U',
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B))),
                ]
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Botón: Punto de Venta
          _buildMenuItem(Icons.storefront_outlined, 'Punto de Venta',
              widget.rutaActual == '/pos', () {
            if (widget.rutaActual != '/pos') {
              Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (_) => const PosScreen()));
            }
          }),

          // Botón: Productos (Catálogo)
          _buildMenuItem(
              Icons.inventory_2, 'Productos', widget.rutaActual == '/catalogo',
              () {
            if (widget.rutaActual != '/catalogo') {
              Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (_) => const CatalogoScreen()));
            }
          }),

          _buildMenuItem(Icons.assessment_outlined, 'Balance', false, () {}),
          const Spacer(),
          _buildMenuItem(
              Icons.settings_outlined, 'Configuración', false, () {}),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
      IconData icon, String title, bool isSelected, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
              vertical: 12, horizontal: _isCollapsed ? 0 : 16),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFC8E6C9) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: _isCollapsed
              ? Icon(icon,
                  color: isSelected
                      ? const Color(0xFF004D40)
                      : const Color(0xFF455A64))
              : Row(
                  children: [
                    Icon(icon,
                        color: isSelected
                            ? const Color(0xFF004D40)
                            : const Color(0xFF455A64)),
                    const SizedBox(width: 16),
                    // AGREGAMOS EL EXPANDED ACÁ PARA EVITAR EL OVERFLOW ROJO
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          color: isSelected
                              ? const Color(0xFF004D40)
                              : const Color(0xFF455A64),
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                        overflow: TextOverflow
                            .ellipsis, // Si es muy largo, pone "..."
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
