import 'package:flutter/material.dart';
import '../../models/categoria.dart';
import '../../services/api_service.dart';

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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(exito)));
      await _cargar();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.redAccent));
    }
  }

  Future<String?> _pedirNombre({required String titulo, String inicial = ''}) {
    final ctrl = TextEditingController(text: inicial);
    return showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(titulo),
        content: TextField(
          key: const Key('categoria_nombre_input'),
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Nombre'),
          onSubmitted: (v) => Navigator.of(dialogContext).pop(v.trim()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(ctrl.text.trim()),
            child: const Text('Guardar'),
          ),
        ],
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
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text('Categorías', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
                TextButton.icon(
                  key: const Key('categoria_nueva_btn'),
                  onPressed: _nueva,
                  icon: const Icon(Icons.add),
                  label: const Text('Nueva categoría'),
                ),
              ],
            ),
            const Text(
              'Etiquetas para filtrar y para los reportes. No se eliminan: se desactivan.',
              style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 8),
            if (_cargando)
              const Padding(padding: EdgeInsets.all(12), child: LinearProgressIndicator())
            else if (_error != null)
              Text(_error!, style: const TextStyle(color: Colors.red))
            else if (_categorias.isEmpty)
              const Text('Todavía no hay categorías.')
            else
              for (final c in _categorias)
                ListTile(
                  key: Key('categoria_${c.id}'),
                  contentPadding: EdgeInsets.zero,
                  title: Text(c.nombre,
                      style: c.activo ? null : const TextStyle(color: Color(0xFF94A3B8))),
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
                            color: c.activo ? const Color(0xFF13894E) : const Color(0xFF94A3B8)),
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
