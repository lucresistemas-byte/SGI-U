import 'package:flutter/material.dart';
import '../../models/categoria.dart';
import '../../services/api_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_elevations.dart';
import '../../theme/app_radii.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../app_button.dart';
import '../app_dialog.dart';
import '../app_snack_bar.dart';

/// Configuración > Categorías: crear, renombrar y desactivar/reactivar.
/// No se eliminan; una desactivada no se ofrece en los formularios, pero los
/// productos que ya la tienen la conservan.
class CategoriasCard extends StatefulWidget {
  final ApiService apiService;

  const CategoriasCard({super.key, required this.apiService});

  @override
  State<CategoriasCard> createState() => _CategoriasCardState();
}

class _CategoriasCardState extends State<CategoriasCard> {
  List<Categoria> _categorias = const [];
  bool _cargando = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final lista = await widget.apiService.getCategorias(incluirInactivas: true);
      if (!mounted) return;
      setState(() {
        _categorias = lista;
        _cargando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'No se pudieron cargar las categorías.';
        _cargando = false;
      });
    }
  }

  Future<void> _ejecutar(Future<void> Function() accion, String exito) async {
    try {
      await accion();
      if (!mounted) return;
      AppSnackBar.exito(context, exito);
      await _cargar();
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.error(context, e.toString());
    }
  }

  Future<String?> _pedirNombre({required String titulo, String inicial = ''}) {
    final ctrl = TextEditingController(text: inicial);
    return showDialog<String>(
      context: context,
      builder: (dialogContext) => AppDialog(
        titulo: titulo,
        tamano: TamanoDialogo.chico,
        acciones: [
          AppButton.ghost(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancelar'),
          ),
          AppButton.primary(
            onPressed: () => Navigator.of(dialogContext).pop(ctrl.text.trim()),
            child: const Text('Guardar'),
          ),
        ],
        child: TextField(
          key: const Key('categoria_nombre_input'),
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Nombre'),
          onSubmitted: (v) => Navigator.of(dialogContext).pop(v.trim()),
        ),
      ),
    );
  }

  Future<void> _nueva() async {
    final nombre = await _pedirNombre(titulo: 'Nueva categoría');
    if (nombre == null || nombre.isEmpty) return;
    await _ejecutar(() => widget.apiService.crearCategoria(nombre), 'Categoría creada');
  }

  Future<void> _renombrar(Categoria c) async {
    final nombre = await _pedirNombre(titulo: 'Renombrar categoría', inicial: c.nombre);
    if (nombre == null || nombre.isEmpty || nombre == c.nombre) return;
    await _ejecutar(() => widget.apiService.actualizarCategoria(c.id, nombre), 'Categoría renombrada');
  }

  Future<void> _cambiarEstado(Categoria c) => _ejecutar(
        () => widget.apiService.cambiarEstadoCategoria(c.id, activo: !c.activo),
        c.activo ? 'Categoría desactivada' : 'Categoría reactivada',
      );

  @override
  Widget build(BuildContext context) {
    return Card(
      key: const Key('config_categorias'),
      elevation: AppElevations.sombraTarjeta,
      shape: const RoundedRectangleBorder(
        borderRadius: AppRadii.bordeCampo,
        side: BorderSide(color: AppColors.bordeSuave),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.espacioGrande),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('Categorías',
                      style: AppTypography.texto.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textoPrincipal)),
                ),
                TextButton.icon(
                  key: const Key('categoria_nueva_btn'),
                  onPressed: _nueva,
                  icon: const Icon(Icons.add),
                  label: const Text('Nueva categoría'),
                ),
              ],
            ),
            Text(
              'Etiquetas para filtrar y para los reportes. No se eliminan: se desactivan.',
              style: AppTypography.etiqueta
                  .copyWith(color: AppColors.textoInactivo),
            ),
            const SizedBox(height: AppSpacing.espacioChico),
            if (_cargando)
              const Padding(
                  padding: EdgeInsets.all(AppSpacing.espacioMedio),
                  child: LinearProgressIndicator())
            else if (_error != null)
              Text(_error!,
                  style: AppTypography.textoChico
                      .copyWith(color: AppColors.error))
            else if (_categorias.isEmpty)
              const Text('Todavía no hay categorías.')
            else
              for (final c in _categorias)
                ListTile(
                  key: Key('categoria_${c.id}'),
                  contentPadding: EdgeInsets.zero,
                  title: Text(c.nombre,
                      style: c.activo
                          ? null
                          : AppTypography.texto
                              .copyWith(color: AppColors.textoInactivo)),
                  subtitle: c.activo ? null : const Text('Inactiva'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        key: Key('categoria_renombrar_${c.id}'),
                        tooltip: 'Renombrar',
                        icon: const Icon(Icons.edit),
                        onPressed: () => _renombrar(c),
                      ),
                      IconButton(
                        key: Key('categoria_estado_${c.id}'),
                        tooltip: c.activo ? 'Desactivar' : 'Reactivar',
                        icon: Icon(c.activo ? Icons.toggle_on : Icons.toggle_off,
                            color: c.activo
                                ? AppColors.estadoActivo
                                : AppColors.textoInactivo),
                        onPressed: () => _cambiarEstado(c),
                      ),
                    ],
                  ),
                ),
          ],
        ),
      ),
    );
  }
}
