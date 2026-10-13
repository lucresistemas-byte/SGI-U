import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/auth/auth_bloc.dart';
import '../blocs/auth/auth_event.dart';
import '../navigation/seccion.dart';
import 'marca_negocio.dart';

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
      // El diseño compacto depende del ancho REAL (no del flag): durante la
      // animación el ancho pasa por valores intermedios y el contenido
      // expandido no entraba (franjas de overflow).
      child: LayoutBuilder(builder: (context, constraints) {
        final compacto = constraints.maxWidth < 180;
        return SingleChildScrollView(
          // Con poca altura, los ítems se desplazan en vez de desbordar.
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: _contenido(compacto),
            ),
          ),
        );
      }),
    );
  }

  Widget _contenido(bool compacto) {
    return Column(
        crossAxisAlignment:
        compacto ? CrossAxisAlignment.center : CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: compacto ? 12.0 : 24.0,
              vertical: 24.0,
            ),
            // La marca escucha la configuración: un logo o nombre nuevo
            // guardado en Configuración se ve acá en el momento.
            child: compacto
                ? Column(
                    children: [
                      InkWell(
                        onTap: () => setState(() => _isCollapsed = !_isCollapsed),
                        child: const Icon(Icons.menu, color: Color(0xFF455A64)),
                      ),
                      const SizedBox(height: 16),
                      const MarcaNegocio(estilo: EstiloMarca.menuCompacto),
                    ],
                  )
                : Row(
                    children: [
                      InkWell(
                        onTap: () => setState(() => _isCollapsed = !_isCollapsed),
                        child: const Icon(Icons.menu, color: Color(0xFF455A64)),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(child: MarcaNegocio(estilo: EstiloMarca.menu)),
                    ],
                  ),
          ),
          const SizedBox(height: 10),
          
          for (final seccion in Seccion.values)
            if (seccion != Seccion.settings) _buildSeccionItem(seccion, compacto),

          const Spacer(),

          _buildSeccionItem(Seccion.settings, compacto),

          // 7. Cerrar Sesión
          _buildMenuItem(Icons.logout, 'Cerrar Sesión', false, compacto, () {
            // La navegación al login la hace el listener global de main.dart.
            context.read<AuthBloc>().add(LogoutRequested());
          }),
          const SizedBox(height: 20),
        ],
      );
  }

  Widget _buildSeccionItem(Seccion seccion, bool compacto) => _buildMenuItem(
        seccion.icono,
        seccion.etiqueta,
        seccion == widget.seccionActual,
        compacto,
        () => widget.onSeleccionar(seccion),
      );

  Widget _buildMenuItem(IconData icon, String title, bool isSelected, bool compacto, VoidCallback onTap) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: compacto ? 8 : 16, vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical: 12, horizontal: compacto ? 0 : 16),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFC8E6C9) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: compacto
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