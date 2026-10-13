import 'package:flutter/material.dart';
import '../models/insumo.dart';
import '../models/unidad_medida.dart';
import '../theme/app_colors.dart';
import '../utils/numeros.dart';

/// Alta/edición de materia prima. Sandra carga la presentación en que compra
/// (p. ej. "Bolsa 25 kg": 25 kilos a $30.000) y el sistema calcula el costo
/// por unidad base. Devuelve con `Navigator.pop` el JSON para la API.
class MateriaPrimaFormDialog extends StatefulWidget {
  final Insumo? existente;

  const MateriaPrimaFormDialog({super.key, this.existente});

  @override
  State<MateriaPrimaFormDialog> createState() => _MateriaPrimaFormDialogState();
}

class _MateriaPrimaFormDialogState extends State<MateriaPrimaFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombre;
  late final TextEditingController _presentacionDescripcion;
  late final TextEditingController _presentacionCantidad;
  late final TextEditingController _presentacionPrecio;
  late final TextEditingController _stock;
  late final TextEditingController _stockMinimo;
  String? _tipo;
  late UnidadMedida _unidad;
  late UnidadMedida _presentacionUnidad;
  late UnidadMedida _stockUnidad;

  bool get _esEdicion => widget.existente != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existente;
    _nombre = TextEditingController(text: e?.nombre ?? '');
    _unidad = e?.unidad ?? UnidadMedida.kilo;
    _presentacionUnidad = UnidadMedida.deCodigo(e?.presentacionUnidad) ?? _unidad;
    _stockUnidad = _unidad;
    _presentacionDescripcion = TextEditingController(text: e?.presentacionDescripcion ?? '');
    // Sin presentación guardada, se propone 1 unidad al costo actual.
    final cantidad = e == null ? null : (e.presentacionCantidad ?? 1);
    final precio = e == null ? null : (e.presentacionPrecio ?? e.costoUnitario);
    _presentacionCantidad = TextEditingController(text: cantidad != null ? formatDecimal(cantidad) : '');
    _presentacionPrecio = TextEditingController(text: precio != null ? formatDecimal(precio, decimales: 2) : '');
    _stock = TextEditingController(text: '0');
    _stockMinimo = TextEditingController(
        text: e?.stockMinimo != null ? formatDecimal(_unidad.desdeBase(e!.stockMinimo!)) : '0');
    for (final c in [_presentacionCantidad, _presentacionPrecio]) {
      c.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    for (final c in [_nombre, _presentacionDescripcion, _presentacionCantidad, _presentacionPrecio, _stock, _stockMinimo]) {
      c.dispose();
    }
    super.dispose();
  }

  FamiliaUnidad get _familia => _unidad.familia!;

  /// Costo por unidad base según la presentación (null si falta un dato).
  double? get _costoUnidadBase {
    final cantidad = parseDecimal(_presentacionCantidad.text);
    final precio = parseDecimal(_presentacionPrecio.text);
    if (cantidad == null || cantidad <= 0 || precio == null || precio < 0) return null;
    return precio / _presentacionUnidad.aBase(cantidad);
  }

  /// "$ 1,2000 por g · $ 1.200,00 por kg".
  String _textoCosto(double costoBase) {
    final base = _familia.base;
    final grande = _familia.unidades.last;
    return '${formatPesos(costoBase, decimales: 4)} por ${base.abreviatura} · '
        '${formatPesos(costoBase * grande.factor)} por ${grande.abreviatura}';
  }

  void _cambiarUnidad(UnidadMedida nueva) {
    setState(() {
      if (nueva.familia != _unidad.familia) {
        // Otra familia: la presentación y el stock pasan a la unidad elegida.
        _presentacionUnidad = nueva;
        _stockUnidad = nueva;
      }
      _unidad = nueva;
    });
  }

  String? _validarDecimal(String? v, {bool requerido = true, bool positivo = false}) {
    if (v == null || v.trim().isEmpty) return requerido ? 'Requerido' : null;
    final n = parseDecimal(v);
    if (n == null) return 'Número inválido';
    if (positivo ? n <= 0 : n < 0) return positivo ? 'Debe ser mayor a 0' : 'No puede ser negativo';
    return null;
  }

  void _guardar() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(<String, dynamic>{
      if (!_esEdicion) 'tipo': _tipo,
      'nombre': _nombre.text.trim(),
      'unidadMedida': _unidad.codigo,
      'presentacionDescripcion': _presentacionDescripcion.text.trim(),
      'presentacionCantidad': parseDecimal(_presentacionCantidad.text),
      'presentacionUnidad': _presentacionUnidad.codigo,
      'presentacionPrecio': parseDecimal(_presentacionPrecio.text),
      if (!_esEdicion) 'stockActual': parseDecimal(_stock.text) ?? 0,
      'stockMinimo': parseDecimal(_stockMinimo.text) ?? 0,
      'stockUnidad': _stockUnidad.codigo,
    });
  }

  Widget _unidadDropdown({
    required Key key,
    required UnidadMedida valor,
    required List<UnidadMedida> opciones,
    required ValueChanged<UnidadMedida> onChanged,
    String etiqueta = 'Unidad',
    bool conFamilia = false,
  }) {
    return DropdownButtonFormField<UnidadMedida>(
      key: key,
      initialValue: valor,
      isExpanded: true,
      decoration: InputDecoration(labelText: etiqueta, border: const OutlineInputBorder()),
      items: [
        for (final u in opciones)
          DropdownMenuItem(
              value: u, child: Text(conFamilia ? '${u.nombre} (${u.familia!.nombre.toLowerCase()})' : u.nombre)),
      ],
      onChanged: (u) {
        if (u != null) onChanged(u);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final costo = _costoUnidadBase;
    final unidadesFamilia = _familia.unidades;
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(_esEdicion ? 'Editar Insumo' : 'Nuevo Insumo', style: const TextStyle(fontWeight: FontWeight.bold)),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!_esEdicion)
                  DropdownButtonFormField<String>(
                    key: const Key('insumo_tipo_dropdown'),
                    initialValue: _tipo,
                    hint: const Text('Elegir tipo'),
                    decoration: const InputDecoration(
                      labelText: 'Tipo *',
                      helperText: 'El código se genera automáticamente al guardar.',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      for (final t in Insumo.tipos.entries) DropdownMenuItem(value: t.key, child: Text(t.value)),
                    ],
                    validator: (v) => v == null ? 'Elija el tipo' : null,
                    onChanged: (v) => setState(() => _tipo = v),
                  )
                else
                  Text(
                    'Código: ${widget.existente!.codigo} · Tipo: ${widget.existente!.descripcionTipo}',
                    key: const Key('insumo_codigo_tipo_fijo'),
                    style: const TextStyle(color: Color(0xFF475569)),
                  ),
                const SizedBox(height: 12),
                TextFormField(
                  key: const Key('insumo_nombre_input'),
                  controller: _nombre,
                  decoration: const InputDecoration(
                      labelText: 'Nombre *', hintText: 'Ej: Harina 000', border: OutlineInputBorder()),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                ),
                const SizedBox(height: 12),
                _unidadDropdown(
                  key: const Key('insumo_unidad_dropdown'),
                  valor: _unidad,
                  opciones: UnidadMedida.conFamilia,
                  etiqueta: 'Unidad para mostrar *',
                  conFamilia: true,
                  onChanged: _cambiarUnidad,
                ),
                const SizedBox(height: 16),
                const Text('Presentación de compra', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextFormField(
                  key: const Key('insumo_presentacion_descripcion_input'),
                  controller: _presentacionDescripcion,
                  decoration: const InputDecoration(
                      labelText: 'Descripción', hintText: 'Ej: Bolsa 25 kg', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextFormField(
                        key: const Key('insumo_presentacion_cantidad_input'),
                        controller: _presentacionCantidad,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(labelText: 'Trae *', border: OutlineInputBorder()),
                        validator: (v) => _validarDecimal(v, positivo: true),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _unidadDropdown(
                        key: ValueKey('insumo_presentacion_unidad_${_familia.codigo}'),
                        valor: _presentacionUnidad,
                        opciones: unidadesFamilia,
                        onChanged: (u) => setState(() => _presentacionUnidad = u),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        key: const Key('insumo_presentacion_precio_input'),
                        controller: _presentacionPrecio,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                            labelText: 'Precio *', prefixText: r'$ ', border: OutlineInputBorder()),
                        validator: (v) => _validarDecimal(v),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  costo == null ? 'Complete la presentación para calcular el costo.' : 'Costo: ${_textoCosto(costo)}',
                  key: const Key('insumo_costo_calculado'),
                  style: TextStyle(
                      color: costo == null ? const Color(0xFF64748B) : AppColors.verdePrincipal,
                      fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!_esEdicion) ...[
                      Expanded(
                        child: TextFormField(
                          key: const Key('insumo_stock_input'),
                          controller: _stock,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(labelText: 'Stock inicial', border: OutlineInputBorder()),
                          validator: (v) => _validarDecimal(v, requerido: false),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Expanded(
                      child: TextFormField(
                        key: const Key('insumo_stock_minimo_input'),
                        controller: _stockMinimo,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(labelText: 'Stock mínimo', border: OutlineInputBorder()),
                        validator: (v) => _validarDecimal(v, requerido: false),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _unidadDropdown(
                        key: ValueKey('insumo_stock_unidad_${_familia.codigo}'),
                        valor: _stockUnidad,
                        opciones: unidadesFamilia,
                        onChanged: (u) => setState(() => _stockUnidad = u),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
        ElevatedButton(
          key: const Key('guardar_insumo_button'),
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.verdePrincipal, foregroundColor: Colors.white),
          onPressed: _guardar,
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}
