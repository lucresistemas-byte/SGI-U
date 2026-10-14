import 'package:flutter/material.dart';
import '../models/insumo.dart';
import '../models/unidad_medida.dart';
import '../models/unidad_stock.dart';
import '../theme/app_colors.dart';
import '../utils/numeros.dart';

/// Alta/edición de un artículo de Materia Prima. Sandra carga la presentación
/// en que compra (p. ej. "Bolsa 25 kg": 25 kilos a $30.000) y el sistema
/// calcula el costo por unidad base. La reventa + materia prima pide además
/// cómo se vende (por defecto, como se compra), el % de ganancia y, si
/// quiere, un precio fijo. Devuelve con `Navigator.pop` el JSON para la API.
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
  late final TextEditingController _ventaNombre;
  late final TextEditingController _ventaCantidad;
  late final TextEditingController _porcentaje;
  late final TextEditingController _precioVenta;
  String? _tipo;
  late UnidadMedida _unidad;
  late UnidadMedida _presentacionUnidad;
  late UnidadMedida _ventaUnidad;
  late String _stockUnidad;

  /// Reventa + materia prima: se vende la presentación de compra tal cual.
  late bool _ventaIgualCompra;

  bool get _esEdicion => widget.existente != null;

  bool get _esReventaMateriaPrima => (_esEdicion ? widget.existente!.tipo : _tipo) == 'REVENTA_MATERIA_PRIMA';

  @override
  void initState() {
    super.initState();
    final e = widget.existente;
    _nombre = TextEditingController(text: e?.nombre ?? '');
    _unidad = e?.unidad ?? UnidadMedida.kilo;
    _presentacionUnidad = UnidadMedida.deCodigo(e?.presentacionUnidad) ?? _unidad;
    _stockUnidad = _unidad.codigo;
    _presentacionDescripcion = TextEditingController(text: e?.presentacionDescripcion ?? '');
    // Sin presentación guardada, se propone 1 unidad al costo actual.
    final cantidad = e == null ? null : (e.presentacionCantidad ?? 1);
    final precio = e == null ? null : (e.presentacionPrecio ?? e.costoUnitario);
    _presentacionCantidad = TextEditingController(text: cantidad != null ? formatDecimal(cantidad) : '');
    _presentacionPrecio = TextEditingController(text: precio != null ? formatDecimal(precio, decimales: 2) : '');
    _stock = TextEditingController(text: '0');
    _stockMinimo = TextEditingController(
        text: e?.stockMinimo != null ? formatDecimal(_unidad.desdeBase(e!.stockMinimo!)) : '0');

    // Unidad de venta: se edita en la unidad para mostrar ("100 g").
    final contenido = e?.ventaUnidadContenido;
    _ventaIgualCompra = contenido == null || contenido == e?.presentacionEnBase;
    _ventaUnidad = _unidad;
    _ventaNombre = TextEditingController(text: _ventaIgualCompra ? '' : (e?.ventaUnidadNombre ?? ''));
    _ventaCantidad = TextEditingController(
        text: contenido != null && !_ventaIgualCompra ? formatDecimal(_unidad.desdeBase(contenido)) : '');
    _porcentaje = TextEditingController(
        text: e?.porcentajeGanancia != null ? formatDecimal(e!.porcentajeGanancia!, decimales: 2) : '');
    _precioVenta = TextEditingController(
        text: e != null && e.precioManual && e.precioVenta != null ? formatDecimal(e.precioVenta!, decimales: 2) : '');
    for (final c in [_presentacionCantidad, _presentacionPrecio, _presentacionDescripcion, _ventaNombre,
      _ventaCantidad, _porcentaje, _precioVenta]) {
      c.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    for (final c in [_nombre, _presentacionDescripcion, _presentacionCantidad, _presentacionPrecio, _stock,
      _stockMinimo, _ventaNombre, _ventaCantidad, _porcentaje, _precioVenta]) {
      c.dispose();
    }
    super.dispose();
  }

  FamiliaUnidad get _familia => _unidad.familia!;

  /// Cantidad de la presentación en unidad base (null si falta).
  double? get _presentacionBase {
    final cantidad = parseDecimal(_presentacionCantidad.text);
    if (cantidad == null || cantidad <= 0) return null;
    return _presentacionUnidad.aBase(cantidad);
  }

  /// Costo por unidad base según la presentación (null si falta un dato).
  double? get _costoUnidadBase {
    final base = _presentacionBase;
    final precio = parseDecimal(_presentacionPrecio.text);
    if (base == null || precio == null || precio < 0) return null;
    return precio / base;
  }

  /// Contenido de la unidad de venta en unidad base (null si falta).
  double? get _ventaBase {
    if (_ventaIgualCompra) return _presentacionBase;
    final cantidad = parseDecimal(_ventaCantidad.text);
    if (cantidad == null || cantidad <= 0) return null;
    return _ventaUnidad.aBase(cantidad);
  }

  String get _ventaNombreEfectivo {
    final n = (_ventaIgualCompra ? _presentacionDescripcion.text : _ventaNombre.text).trim();
    return n.isEmpty ? 'Unidad' : n;
  }

  /// Unidades en que se puede cargar el stock: las de la familia, la
  /// presentación y (reventa + materia prima) la unidad de venta.
  List<UnidadStock> get _unidadesStock => UnidadStock.opciones(
        _familia,
        presentacionNombre: _presentacionDescripcion.text.trim().isEmpty ? null : _presentacionDescripcion.text.trim(),
        presentacionBase: _presentacionBase,
        ventaNombre: _ventaNombreEfectivo,
        ventaBase: _esReventaMateriaPrima && !_ventaIgualCompra ? _ventaBase : null,
      );

  /// "$ 1,2000 por g · $ 1.200,00 por kg".
  String _textoCosto(double costoBase) {
    final base = _familia.base;
    final grande = _familia.unidades.last;
    return '${formatPesos(costoBase, decimales: 4)} por ${base.abreviatura} · '
        '${formatPesos(costoBase * grande.factor)} por ${grande.abreviatura}';
  }

  /// "Costo por Caja: $ 2.250,00 · Precio: $ 3.600,00 (60 %)".
  String? get _resumenVenta {
    final costoBase = _costoUnidadBase;
    final contenido = _ventaBase;
    if (costoBase == null || contenido == null) return null;
    final costo = costoBase * contenido;
    final manual = parseDecimal(_precioVenta.text);
    final porcentaje = parseDecimal(_porcentaje.text) ?? 0;
    // Como el backend: hacia arriba a $100; el precio fijo no baja del mínimo del %.
    final minimo = precioMinimo(costo, porcentaje);
    final precio = manual == null ? minimo : redondearA100(manual);
    final bajoMinimo = manual != null && precio < minimo;
    return 'Costo por $_ventaNombreEfectivo: ${formatPesos(costo)} · '
        'Precio: ${formatPesos(precio)}${manual != null ? ' (fijo)' : ''} · '
        'Ganancia: ${formatPesos(precio - costo)}'
        '${bajoMinimo ? ' · Por debajo del mínimo con ${formatDecimal(porcentaje, decimales: 2)} %: ${formatPesos(minimo)}' : ''}';
  }

  /// El precio fijo no puede dejar menos del % de ganancia.
  String? _validarPrecioFijo(String? v) {
    final error = _validarDecimal(v, requerido: false, positivo: true);
    if (error != null) return error;
    final manual = parseDecimal(v);
    final costoBase = _costoUnidadBase;
    final contenido = _ventaBase;
    if (manual == null || costoBase == null || contenido == null) return null;
    final minimo = precioMinimo(costoBase * contenido, parseDecimal(_porcentaje.text) ?? 0);
    return redondearA100(manual) < minimo ? 'Mínimo ${formatPesos(minimo)}' : null;
  }

  void _cambiarUnidad(UnidadMedida nueva) {
    setState(() {
      if (nueva.familia != _unidad.familia) {
        // Otra familia: presentación, contenido y stock pasan a la unidad elegida.
        _presentacionUnidad = nueva;
        _ventaUnidad = nueva;
        _stockUnidad = nueva.codigo;
      } else {
        // Misma familia: lo que seguía a la unidad para mostrar la sigue.
        if (_stockUnidad == _unidad.codigo) _stockUnidad = nueva.codigo;
        if (_ventaCantidad.text.trim().isEmpty) _ventaUnidad = nueva;
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
    // Si la unidad de stock dejó de existir (p. ej. se borró la presentación), se usa la de mostrar.
    final stockUnidad =
        _unidadesStock.any((u) => u.codigo == _stockUnidad) ? _stockUnidad : _unidad.codigo;
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
      'stockUnidad': stockUnidad,
      if (_esReventaMateriaPrima) ...{
        // Sin contenido, el backend vende la presentación de compra.
        if (!_ventaIgualCompra) 'ventaUnidadNombre': _ventaNombre.text.trim(),
        if (!_ventaIgualCompra) 'ventaUnidadCantidad': parseDecimal(_ventaCantidad.text),
        if (!_ventaIgualCompra) 'ventaUnidadUnidad': _ventaUnidad.codigo,
        'porcentajeGanancia': parseDecimal(_porcentaje.text) ?? 0,
        'precioVenta': parseDecimal(_precioVenta.text),
        if (widget.existente?.categoriaId != null) 'categoriaId': widget.existente!.categoriaId,
      },
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

  /// Unidad de venta, % de ganancia y precio fijo (solo reventa + materia prima).
  List<Widget> _seccionVenta() {
    final resumen = _resumenVenta;
    return [
      const SizedBox(height: 16),
      const Text('Venta', style: TextStyle(fontWeight: FontWeight.w600)),
      CheckboxListTile(
        key: const Key('insumo_venta_igual_compra_check'),
        contentPadding: EdgeInsets.zero,
        controlAffinity: ListTileControlAffinity.leading,
        value: _ventaIgualCompra,
        title: const Text('Se vende como se compra (la presentación de compra)'),
        subtitle: const Text('Desmárquelo si compra por bulto y vende por unidad (p. ej. caja de 100 g).'),
        onChanged: (v) => setState(() => _ventaIgualCompra = v ?? true),
      ),
      if (!_ventaIgualCompra) ...[
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: TextFormField(
                key: const Key('insumo_venta_nombre_input'),
                controller: _ventaNombre,
                decoration: const InputDecoration(
                    labelText: 'Se vende por *', hintText: 'Ej: Caja', border: OutlineInputBorder()),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextFormField(
                key: const Key('insumo_venta_cantidad_input'),
                controller: _ventaCantidad,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Contiene *', border: OutlineInputBorder()),
                validator: (v) => _validarDecimal(v, positivo: true),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _unidadDropdown(
                key: ValueKey('insumo_venta_unidad_${_familia.codigo}'),
                valor: _ventaUnidad,
                opciones: _familia.unidades,
                onChanged: (u) => setState(() => _ventaUnidad = u),
              ),
            ),
          ],
        ),
      ],
      const SizedBox(height: 12),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: TextFormField(
              key: const Key('insumo_porcentaje_input'),
              controller: _porcentaje,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                  labelText: '% de ganancia *', suffixText: '%', border: OutlineInputBorder()),
              validator: (v) => _validarDecimal(v),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextFormField(
              key: const Key('insumo_precio_venta_input'),
              controller: _precioVenta,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Precio fijo (opcional)',
                prefixText: r'$ ',
                helperText: 'Vacío: costo × (1 + %). Se redondea a \$100.',
                border: OutlineInputBorder(),
              ),
              validator: _validarPrecioFijo,
            ),
          ),
        ],
      ),
      const SizedBox(height: 8),
      Text(
        resumen ?? 'Complete la presentación y la unidad de venta para calcular el precio.',
        key: const Key('insumo_resumen_venta'),
        style: TextStyle(
            color: resumen == null ? const Color(0xFF64748B) : AppColors.verdePrincipal,
            fontWeight: FontWeight.w600),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final costo = _costoUnidadBase;
    final unidadesFamilia = _familia.unidades;
    final unidadesStock = _unidadesStock;
    final stockUnidad = unidadesStock.any((u) => u.codigo == _stockUnidad) ? _stockUnidad : _unidad.codigo;
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(_esEdicion ? 'Editar Insumo' : 'Nuevo Insumo', style: const TextStyle(fontWeight: FontWeight.bold)),
      content: SizedBox(
        width: 520,
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
                if (_esReventaMateriaPrima) ..._seccionVenta(),
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
                      flex: 2,
                      child: DropdownButtonFormField<String>(
                        // Se recrea si cambian las opciones (initialValue se lee una sola vez).
                        key: ValueKey('insumo_stock_unidad_${_familia.codigo}_${unidadesStock.length}_$stockUnidad'),
                        initialValue: stockUnidad,
                        isExpanded: true,
                        decoration: const InputDecoration(labelText: 'Unidad', border: OutlineInputBorder()),
                        items: [
                          for (final u in unidadesStock)
                            DropdownMenuItem(value: u.codigo, child: Text(u.nombre, overflow: TextOverflow.ellipsis)),
                        ],
                        onChanged: (u) {
                          if (u != null) setState(() => _stockUnidad = u);
                        },
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
