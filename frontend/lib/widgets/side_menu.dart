import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/auth/auth_bloc.dart';
import '../blocs/auth/auth_event.dart';
import '../navigation/seccion.dart';
import '../theme/app_breakpoints.dart';
import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../theme/app_spacing.dart';
import '../theme/app_widths.dart';
import 'app_button.dart';
import 'app_dialog.dart';
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
      width: _isCollapsed
          ? AppWidths.anchoMenuColapsado
          : AppWidths.anchoMenuExpandido,
      color: AppColors.fondoMenu,
      clipBehavior: Clip.hardEdge,
      // El diseño compacto depende del ancho REAL (no del flag): durante la
      // animación el ancho pasa por valores intermedios y el contenido
      // expandido no entraba (franjas de overflow).
      child: LayoutBuilder(builder: (context, constraints) {
        final compacto = constraints.maxWidth < AppBreakpoints.corteMenuColapsado;
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
              horizontal: compacto ? AppSpacing.espacioMedio : AppSpacing.espacioSeccion,
              vertical: AppSpacing.espacioSeccion,
            ),
            // La marca escucha la configuración: un logo o nombre nuevo
            // guardado en Configuración se ve acá en el momento.
            child: compacto
                ? Column(
                    children: [
                      InkWell(
                        onTap: () => setState(() => _isCollapsed = !_isCollapsed),
                        child: const Icon(Icons.menu, color: AppColors.menuTexto),
                      ),
                      const SizedBox(height: AppSpacing.espacioEstandar),
                      const MarcaNegocio(estilo: EstiloMarca.menuCompacto),
                    ],
                  )
                : Row(
                    children: [
                      InkWell(
                        onTap: () => setState(() => _isCollapsed = !_isCollapsed),
                        child: const Icon(Icons.menu, color: AppColors.menuTexto),
                      ),
                      const SizedBox(width: AppSpacing.espacioEstandar),
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
            _confirmarCerrarSesion();
          }),
          const SizedBox(height: AppSpacing.espacioGrande),
        ],
      );
  }

  /// Pide confirmación antes de cerrar la sesión. La navegación al login la
  /// hace el listener global de main.dart cuando el AuthBloc emite el logout.
  Future<void> _confirmarCerrarSesion() async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AppDialog(
        titulo: 'Cerrar sesión',
        tamano: TamanoDialogo.chico,
        acciones: [
          AppButton.ghost(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          AppButton.primary(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Cerrar sesión'),
          ),
        ],
        child: const Text('¿Cerrar la sesión actual?'),
      ),
    );
    if (confirmado == true && mounted) {
      context.read<AuthBloc>().add(LogoutRequested());
    }
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
      padding: EdgeInsets.symmetric(
        horizontal: compacto ? AppSpacing.espacioChico : AppSpacing.espacioEstandar,
        vertical: AppSpacing.espacioMinimo,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.bordeTarjeta,
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            vertical: AppSpacing.espacioMedio,
            horizontal: compacto ? AppSpacing.espacioNinguno : AppSpacing.espacioEstandar,
          ),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.seleccionFondo : AppColors.transparente,
            borderRadius: AppRadii.bordeTarjeta,
          ),
          child: compacto
              ? Icon(icon,
              color: isSelected ? AppColors.marcaActiva : AppColors.menuTexto)
              : Row(
            children: [
              Icon(icon,
                  color: isSelected ? AppColors.marcaActiva : AppColors.menuTexto),
              const SizedBox(width: AppSpacing.espacioEstandar),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: isSelected ? AppColors.marcaActiva : AppColors.menuTexto,
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
