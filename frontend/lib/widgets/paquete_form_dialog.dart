import 'package:flutter/material.dart';
import '../models/categoria.dart';
import '../models/insumo.dart';
import '../models/paquete.dart';
import '../models/unidad_medida.dart';
import '../theme/app_colors.dart';
import '../utils/numeros.dart';

/// Una fila del armado mientras se edita.
class _Fila {
  Insumo? insumo;
  UnidadMedida? unidad;
  final TextEditingController cantidad;

  _Fila({this.insumo, this.unidad, String cantidad = ''}) : cantidad = TextEditingController(text: cantidad);

  /// Costo de la fila: cantidad en unidad base × costo por unidad base.
  double get costo {
    final c = parseDecimal(cantidad.text);
    if (insumo == null || unidad == null || c == null || c <= 0) return 0;
    return unidad!.aBase(c) * insumo!.costoUnidadBase;
  }
}

/// Armador de paquetes: nombre, categoría, armado (insumos con cantidad y
/// unidad) y monto fijo. Muestra en vivo el costo del armado, el precio
/// (armado + fijo, hacia arriba a $100) y la ganancia. Devuelve el JSON para
/// la API con `Navigator.pop`.
class PaqueteFormDialog extends StatefulWidget {
  final Paquete? existente;

  /// Insumos activos (cajas, cintas, papel...).
  final List<Insumo> insumos;
  final List<Categoria> categorias;

  const PaqueteFormDialog({super.key, this.existente, required this.insumos, this.categorias = const []});

  @override
  State<PaqueteFormDialog> createState() => _PaqueteFormDialogState();
}

class _PaqueteFormDialogState extends State<PaqueteFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombre;
  late final TextEditingController _montoFijo;
  int? _categoriaId;
  final List<_Fila> _filas = [];

  bool get _esEdicion => widget.existente != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existente;
    _nombre = TextEditingController(text: e?.nombre ?? '');
    _montoFijo = TextEditingController(text: e != null ? formatDecimal(e.montoFijo, decimales: 2) : '');
    _categoriaId = e?.categoriaId;
    for (final f in e?.armado ?? const <FilaArmado>[]) {
      Insumo? insumo;
      for (final i in widget.insumos) {
        if (i.id == f.articuloId) insumo = i;
      }
      _agregarFila(_Fila(insumo: insumo, unidad: UnidadMedida.deCodigo(f.unidadMedida), cantidad: formatDecimal(f.cantidad)));
    }
    if (_filas.isEmpty) _agregarFila(_Fila());
    _montoFijo.addListener(() => setState(() {}));
  }

  void _agregarFila(_Fila fila) {
    fila.cantidad.addListener(() => setState(() {}));
    _filas.add(fila);
  }

  @override
  void dispose() {
    _nombre.dispose();
    _montoFijo.dispose();
    for (final f in _filas) {
      f.cantidad.dispose();
    }
    super.dispose();
  }

  double get _costoArmado => _filas.fold(0.0, (acc, f) => acc + f.costo);

  double get _precio => redondearA100(_costoArmado + (parseDecimal(_montoFijo.text) ?? 0));

  void _guardar() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(<String, dynamic>{
      'nombre': _nombre.text.trim(),
      if (_categoriaId != null) 'categoriaId': _categoriaId,
      'montoFijo': parseDecimal(_montoFijo.text) ?? 0,
      'armado': [
        for (final f in _filas)
          {'articuloId': f.insumo!.id, 'cantidad': parseDecimal(f.cantidad.text), 'unidadMedida': f.unidad!.codigo},
      ],
    });
  }

  Widget _fila(int index) {
    final fila = _filas[index];
    final usados = {for (var i = 0; i < _filas.length; i++) if (i != index && _filas[i].insumo != null) _filas[i].insumo!.id};
    final ofrecidos = widget.insumos.where((i) => !usados.contains(i.id)).toList();
    return Padding(
      key: ObjectKey(fila),
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: DropdownButtonFormField<int>(
              key: Key('paquete_insumo_fila_$index'),
              initialValue: fila.insumo?.id,
              isExpanded: true,
              hint: const Text('Elegir insumo'),
              decoration: const InputDecoration(labelText: 'Insumo', border: OutlineInputBorder()),
              items: [
                for (final i in ofrecidos) DropdownMenuItem(value: i.id, child: Text('${i.nombre} (${i.codigo})')),
              ],
              validator: (v) => v == null ? 'Elija el insumo' : null,
              onChanged: (id) => setState(() {
                fila.insumo = widget.insumos.firstWhere((i) => i.id == id);
                fila.unidad = fila.insumo!.unidad;
              }),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 110,
            child: TextFormField(
              key: Key('paquete_cantidad_fila_$index'),
              controller: fila.cantidad,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Cantidad', border: OutlineInputBorder()),
              validator: (v) {
                final c = parseDecimal(v);
                return c == null || c <= 0 ? 'Mayor a 0' : null;
              },
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 140,
            child: fila.insumo == null
                ? const Padding(padding: EdgeInsets.only(top: 16), child: Text('—'))
                : DropdownButtonFormField<UnidadMedida>(
                    key: ValueKey('paquete_unidad_fila_${index}_${fila.insumo!.id}'),
                    initialValue: fila.unidad,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Unidad', border: OutlineInputBorder()),
                    items: [
                      for (final u in fila.insumo!.familia.unidades) DropdownMenuItem(value: u, child: Text(u.nombre)),
                    ],
                    onChanged: (u) => setState(() => fila.unidad = u),
                  ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 110,
            child: Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(formatPesos(fila.costo), key: Key('paquete_subtotal_fila_$index'), textAlign: TextAlign.right),
            ),
          ),
          IconButton(
            key: Key('paquete_quitar_fila_$index'),
            tooltip: 'Quitar',
            icon: const Icon(Icons.delete_outline),
            onPressed: _filas.length == 1
                ? null
                : () => setState(() {
                      _filas.removeAt(index).cantidad.dispose();
                    }),
          ),
        ],
      ),
    );
  }

  Widget _dato(String titulo, String valor, Key key) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(titulo, style: const TextStyle(fontSize: 13, color: Color(0xFF166534))),
          Text(valor, key: key, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF15803D))),
        ],
      );

  @override
  Widget build(BuildContext context) {
    final costo = _costoArmado;
    final fijo = parseDecimal(_montoFijo.text) ?? 0;
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(_esEdicion ? 'Editar paquete ${widget.existente!.codigo}' : 'Nuevo paquete',
          style: const TextStyle(fontWeight: FontWeight.bold)),
      content: SizedBox(
        width: 720,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        key: const Key('paquete_nombre_input'),
                        controller: _nombre,
                        decoration: const InputDecoration(
                            labelText: 'Nombre *', hintText: 'Ej: Paquete día de la madre', border: OutlineInputBorder()),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Requerido' : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<int?>(
                        key: const Key('paquete_categoria_dropdown'),
                        initialValue: _categoriaId,
                        isExpanded: true,
                        decoration: const InputDecoration(labelText: 'Categoría', border: OutlineInputBorder()),
                        items: [
                          const DropdownMenuItem<int?>(value: null, child: Text('Sin categoría')),
                          for (final c in widget.categorias) DropdownMenuItem<int?>(value: c.id, child: Text(c.nombre)),
                        ],
                        onChanged: (v) => setState(() => _categoriaId = v),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Expanded(child: Text('Armado', style: TextStyle(fontWeight: FontWeight.w600))),
                    TextButton.icon(
                      key: const Key('paquete_agregar_fila'),
                      icon: const Icon(Icons.add),
                      label: const Text('Agregar insumo'),
                      onPressed: () => setState(() => _agregarFila(_Fila())),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (widget.insumos.isEmpty)
                  const Text('No hay insumos activos. Cárguelos en Materia Prima.',
                      style: TextStyle(color: Color(0xFFB45309))),
                for (var i = 0; i < _filas.length; i++) _fila(i),
                const SizedBox(height: 8),
                SizedBox(
                  width: 220,
                  child: TextFormField(
                    key: const Key('paquete_monto_fijo_input'),
                    controller: _montoFijo,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                        labelText: 'Monto fijo *', prefixText: r'$ ', border: OutlineInputBorder()),
                    validator: (v) {
                      final n = parseDecimal(v);
                      return n == null || n < 0 ? 'Ingrese un monto (puede ser 0)' : null;
                    },
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  color: const Color(0xFFF0FDF4),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Wrap(
                      spacing: 28,
                      runSpacing: 12,
                      children: [
                        _dato('Costo del armado', formatPesos(costo), const Key('paquete_costo_armado')),
                        _dato('Monto fijo', formatPesos(fijo), const Key('paquete_monto_fijo')),
                        _dato('Precio (a \$100)', formatPesos(_precio), const Key('paquete_precio')),
                        _dato('Ganancia', formatPesos(_precio - costo), const Key('paquete_ganancia')),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
        ElevatedButton(
          key: const Key('guardar_paquete_button'),
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.verdePrincipal, foregroundColor: Colors.white),
          onPressed: _guardar,
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}
