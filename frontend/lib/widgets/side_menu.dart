import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/auth/auth_bloc.dart';
import '../blocs/auth/auth_event.dart';
import '../navigation/seccion.dart';
import '../services/api_service.dart';

/// Menú lateral. No navega: avisa la sección elegida a AppShell, que cambia
/// el contenido.
class SideMenu extends StatefulWidget {
  final Seccion seccionActual;
  final ValueChanged<Seccion> onSeleccionar;

  const SideMenu({
    super.key,
    required this.seccionActual,
    required this.onSeleccionar,
  });

  @override
  State<SideMenu> createState() => _SideMenuState();
}

class _SideMenuState extends State<SideMenu> {
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
            padding: EdgeInsets.symmetric(
              horizontal: _isCollapsed ? 12.0 : 24.0,
              vertical: 24.0,
            ),
            child: Row(
              mainAxisAlignment: _isCollapsed
                  ? MainAxisAlignment.center
                  : MainAxisAlignment.start,
              children: [
                InkWell(
                  onTap: () => setState(() => _isCollapsed = !_isCollapsed),
                  child: const Icon(Icons.menu, color: Color(0xFF455A64)),
                ),
                if (!_isCollapsed) ...[
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      ApiService.configuracionActual?.nombre.isNotEmpty == true
                          ? ApiService.configuracionActual!.nombre
                          : 'SGI-U',
                      style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B)),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ]
              ],
            ),
          ),
          const SizedBox(height: 10),
          
          for (final seccion in Seccion.values)
            if (seccion != Seccion.settings) _buildSeccionItem(seccion),

          const Spacer(),

          _buildSeccionItem(Seccion.settings),

          // 7. Cerrar Sesión
          _buildMenuItem(Icons.logout, 'Cerrar Sesión', false, () {
            // La navegación al login la hace el listener global de main.dart.
            context.read<AuthBloc>().add(LogoutRequested());
          }),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSeccionItem(Seccion seccion) => _buildMenuItem(
        seccion.icono,
        seccion.etiqueta,
        seccion == widget.seccionActual,
        () => widget.onSeleccionar(seccion),
      );

  Widget _buildMenuItem(IconData icon, String title, bool isSelected, VoidCallback onTap) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: _isCollapsed ? 8 : 16, vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical: 12, horizontal: _isCollapsed ? 0 : 16),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFC8E6C9) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: _isCollapsed
              ? Icon(icon,
              color: isSelected ? const Color(0xFF004D40) : const Color(0xFF455A64))
              : Row(
            children: [
              Icon(icon,
                  color: isSelected ? const Color(0xFF004D40) : const Color(0xFF455A64)),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: isSelected ? const Color(0xFF004D40) : const Color(0xFF455A64),
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}