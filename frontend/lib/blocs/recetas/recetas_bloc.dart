import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/categoria.dart';
import '../../models/insumo.dart';
import '../../models/product.dart';
import '../../models/receta_detalle.dart';
import '../../models/unidad_medida.dart';
import '../../services/api_service.dart';
import 'recetas_event.dart';
import 'recetas_state.dart';

class RecetasBloc extends Bloc<RecetasEvent, RecetasState> {
  final ApiService _apiService;

  RecetasBloc({ApiService? apiService})
      : _apiService = apiService ?? ApiService(),
        super(RecetasState.initial()) {
    on<CargarRecetas>(_onCargarRecetas);
    on<CargarDatosAuxiliaresReceta>(_onCargarDatosAuxiliaresReceta);
    on<IniciarNuevaReceta>(_onIniciarNuevaReceta);
    on<EditarReceta>(_onEditarReceta);
    on<CambiarProductoReceta>(_onCambiarProductoReceta);
    on<CambiarNombreReceta>(_onCambiarNombreReceta);
    on<CambiarDescripcionReceta>(_onCambiarDescripcionReceta);
    on<CambiarCostosAdicionales>(_onCambiarCostosAdicionales);
    on<AgregarFilaInsumo>(_onAgregarFilaInsumo);
    on<AgregarFilaVacia>((event, emit) => emit(state.copyWith(detalles: [
          ...state.detalles,
          RecetaDetalle(articuloId: 0, cantidad: 0, unidadMedida: '', claveUi: _nuevaClave()),
        ])));
    on<RemoverFilaInsumo>(_onRemoverFilaInsumo);
    on<CambiarInsumoFila>(_onCambiarInsumoFila);
    on<CambiarUnidadFila>(_onCambiarUnidadFila);
    on<CambiarRinde>((event, emit) =>
        emit(event.rinde == null ? state.copyWith(quitarRinde: true) : state.copyWith(rinde: event.rinde)));
    on<CambiarRindeUnidad>((event, emit) => emit(state.copyWith(rindeUnidad: event.rindeUnidad)));
    on<CambiarRindeUnidadMedida>((event, emit) => emit(state.copyWith(rindeUnidadMedida: event.unidad)));
    on<CambiarModoProductoReceta>((event, emit) =>
        emit(state.copyWith(usarProductoNuevo: event.productoNuevo)));
    on<ActualizarProductoNuevoReceta>((event, emit) => emit(state.copyWith(
          nuevoProductoNombre: event.nombre,
          nuevoProductoCategoriaId: event.categoriaId,
          quitarNuevoProductoCategoria: event.quitarCategoria,
          nuevoProductoPorcentaje: event.porcentajeGanancia,
          nuevoProductoPreparacionBase: event.preparacionBase,
        )));
    on<CrearCategoriaReceta>(_onCrearCategoriaReceta);
    on<ActualizarCantidadFilaInsumo>(_onActualizarCantidadFilaInsumo);
    on<GuardarReceta>(_onGuardarReceta);
    on<LimpiarMensajesRecetas>((event, emit) =>
        emit(state.copyWith(clearError: true, clearSuccess: true)));
  }

  /// La categoría nueva se agrega a la lista y queda elegida; el resto de
  /// los datos del armador no se toca.
  Future<void> _onCrearCategoriaReceta(
      CrearCategoriaReceta event, Emitter<RecetasState> emit) async {
    try {
      final categoria = await _apiService.crearCategoria(event.nombre.trim());
      emit(state.copyWith(
        availableCategorias: [...state.availableCategorias, categoria],
        nuevoProductoCategoriaId: categoria.id,
      ));
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
    }
  }

  /// Clave estable para cada fila del armador.
  int _ultimaClave = 0;
  int _nuevaClave() => ++_ultimaClave;

  List<RecetaDetalle> _conClaves(List<RecetaDetalle> detalles) =>
      [for (final d in detalles) d.claveUi == null ? d.copyWith(claveUi: _nuevaClave()) : d];

  /// Fila con el costo de la unidad elegida (de la familia del insumo).
  RecetaDetalle _fila(Insumo insumo, double cantidad, UnidadMedida unidad, int? claveUi) {
    final costo = insumo.costoPor(unidad);
    return RecetaDetalle(
      articuloId: insumo.id ?? 0,
      articuloCodigo: insumo.codigo,
      articuloNombre: insumo.nombre,
      cantidad: cantidad,
      unidadMedida: unidad.codigo,
      costoUnitario: costo,
      subtotal: cantidad * costo,
      claveUi: claveUi,
    );
  }

  Insumo? _insumo(int id) {
    for (final i in state.availableInsumos) {
      if (i.id == id) return i;
    }
    return null;
  }

  void _emitirDetalles(Emitter<RecetasState> emit, List<RecetaDetalle> detalles) => emit(state.copyWith(
        detalles: detalles,
        costoTotal: _calcularCostoTotal(detalles, state.costosAdicionales),
      ));

  void _onCambiarUnidadFila(CambiarUnidadFila event, Emitter<RecetasState> emit) {
    if (event.index < 0 || event.index >= state.detalles.length) return;
    final actual = state.detalles[event.index];
    final insumo = _insumo(actual.articuloId);
    if (insumo == null || event.unidad.familia != insumo.familia) return;
    final nuevos = List<RecetaDetalle>.from(state.detalles);
    nuevos[event.index] = _fila(insumo, actual.cantidad, event.unidad, actual.claveUi);
    _emitirDetalles(emit, nuevos);
  }

  double _calcularCostoTotal(List<RecetaDetalle> detalles, double adicionales) {
    final sum = detalles.fold<double>(0.0, (acc, item) => acc + item.subtotal);
    return sum + adicionales;
  }

  Future<void> _onCargarRecetas(
      CargarRecetas event, Emitter<RecetasState> emit) async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final recetas = await _apiService.getRecetas();
      emit(state.copyWith(isLoading: false, recetas: recetas));
    } catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.toString()));
    }
  }

  Future<void> _onCargarDatosAuxiliaresReceta(
      CargarDatosAuxiliaresReceta event, Emitter<RecetasState> emit) async {
    try {
      final insumos = await _apiService.getComponentesReceta();
      final rawProducts = await _apiService.getProducts();
      final products = rawProducts
          .map((p) => Product.fromJson(Map<String, dynamic>.from(p as Map)))
          .toList();
      // Las categorías son opcionales: si fallan, se puede crear sin categoría.
      var categorias = const <Categoria>[];
      try {
        categorias = await _apiService.getCategorias();
      } catch (_) {}
      emit(state.copyWith(
        availableInsumos: insumos,
        availableProductos: products,
        availableCategorias: categorias,
      ));
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
    }
  }

  void _onIniciarNuevaReceta(
      IniciarNuevaReceta event, Emitter<RecetasState> emit) {
    emit(state.copyWith(
      clearEditingId: true,
      selectedProductoCodigo: event.defaultProductoCodigo ?? '',
      selectedProductoNombre: event.defaultProductoNombre ?? '',
      nombre: '',
      descripcion: '',
      costosAdicionales: 0.0,
      detalles: const [],
      costoTotal: 0.0,
      quitarRinde: true,
      rindeUnidad: 'porciones',
      rindeUnidadMedida: 'GRAMO',
      editaPreparacionBase: false,
      clearError: true,
      clearSuccess: true,
      // Por defecto, la receta crea el producto elaborado.
      usarProductoNuevo: event.defaultProductoCodigo == null,
      nuevoProductoNombre: '',
      quitarNuevoProductoCategoria: true,
      nuevoProductoPreparacionBase: false,
    ));
  }

  void _onEditarReceta(EditarReceta event, Emitter<RecetasState> emit) {
    emit(state.copyWith(
      editingRecetaId: event.receta.id,
      productoEditadoActivo: event.receta.productoActivo,
      selectedProductoCodigo: event.receta.espProductoCodigo,
      selectedProductoNombre: event.receta.espProductoNombre ?? '',
      nombre: event.receta.nombre,
      descripcion: event.receta.descripcion ?? '',
      costosAdicionales: event.receta.costosAdicionales,
      detalles: _conClaves(event.receta.detalles),
      costoTotal: event.receta.costoTotal,
      rinde: event.receta.rinde,
      rindeUnidad: event.receta.rindeUnidad,
      rindeUnidadMedida: event.receta.rindeUnidadMedida ?? 'GRAMO',
      editaPreparacionBase: event.receta.preparacionBase,
      clearError: true,
      clearSuccess: true,
    ));
  }

  void _onCambiarProductoReceta(
      CambiarProductoReceta event, Emitter<RecetasState> emit) {
    emit(state.copyWith(
      selectedProductoCodigo: event.codigo,
      selectedProductoNombre: event.nombre,
    ));
  }

  void _onCambiarNombreReceta(
      CambiarNombreReceta event, Emitter<RecetasState> emit) {
    emit(state.copyWith(nombre: event.nombre));
  }

  void _onCambiarDescripcionReceta(
      CambiarDescripcionReceta event, Emitter<RecetasState> emit) {
    emit(state.copyWith(descripcion: event.descripcion));
  }

  void _onCambiarCostosAdicionales(
      CambiarCostosAdicionales event, Emitter<RecetasState> emit) {
    final total = _calcularCostoTotal(state.detalles, event.costosAdicionales);
    emit(state.copyWith(
      costosAdicionales: event.costosAdicionales,
      costoTotal: total,
    ));
  }

  void _onAgregarFilaInsumo(
      AgregarFilaInsumo event, Emitter<RecetasState> emit) {
    // Por defecto la unidad base (la más chica) de la familia del insumo.
    final nuevoDetalle = _fila(
        event.insumo, event.cantidad, event.unidad ?? event.insumo.familia.base, _nuevaClave());

    final nuevosDetalles = List<RecetaDetalle>.from(state.detalles)..add(nuevoDetalle);
    final total = _calcularCostoTotal(nuevosDetalles, state.costosAdicionales);

    emit(state.copyWith(
      detalles: nuevosDetalles,
      costoTotal: total,
    ));
  }

  void _onCambiarInsumoFila(
      CambiarInsumoFila event, Emitter<RecetasState> emit) {
    if (event.index < 0 || event.index >= state.detalles.length) return;
    final actual = state.detalles[event.index];
    final insumo = event.insumo;
    // Antes se borraba la fila y se agregaba la nueva al final: las filas se
    // reordenaban y lo que se veía dejaba de coincidir con lo que se enviaba.
    final nuevosDetalles = List<RecetaDetalle>.from(state.detalles);
    // Misma familia: se conserva la unidad; si no, la base del insumo nuevo.
    final unidadActual = UnidadMedida.deCodigo(actual.unidadMedida);
    final unidad = unidadActual != null && unidadActual.familia == insumo.familia
        ? unidadActual
        : insumo.familia.base;
    nuevosDetalles[event.index] = _fila(insumo, actual.cantidad, unidad, actual.claveUi);
    emit(state.copyWith(
      detalles: nuevosDetalles,
      costoTotal: _calcularCostoTotal(nuevosDetalles, state.costosAdicionales),
    ));
  }

  void _onRemoverFilaInsumo(
      RemoverFilaInsumo event, Emitter<RecetasState> emit) {
    if (event.index >= 0 && event.index < state.detalles.length) {
      final nuevosDetalles = List<RecetaDetalle>.from(state.detalles)..removeAt(event.index);
      final total = _calcularCostoTotal(nuevosDetalles, state.costosAdicionales);

      emit(state.copyWith(
        detalles: nuevosDetalles,
        costoTotal: total,
      ));
    }
  }

  void _onActualizarCantidadFilaInsumo(
      ActualizarCantidadFilaInsumo event, Emitter<RecetasState> emit) {
    if (event.index >= 0 && event.index < state.detalles.length) {
      final item = state.detalles[event.index];
      final updatedItem = item.copyWith(
        cantidad: event.cantidad,
        subtotal: event.cantidad * item.costoUnitario,
      );
      final nuevosDetalles = List<RecetaDetalle>.from(state.detalles);
      nuevosDetalles[event.index] = updatedItem;
      final total = _calcularCostoTotal(nuevosDetalles, state.costosAdicionales);

      emit(state.copyWith(
        detalles: nuevosDetalles,
        costoTotal: total,
      ));
    }
  }

  Future<void> _onGuardarReceta(
      GuardarReceta event, Emitter<RecetasState> emit) async {
    if (state.hayFilasIncompletas) {
      emit(state.copyWith(errorMessage: RecetasState.mensajeFilasIncompletas));
      return;
    }
    if (!state.isFormValid) {
      emit(state.copyWith(
        errorMessage: 'Por favor complete todos los campos requeridos de la receta.',
      ));
      return;
    }

    final repetido = _insumoRepetido();
    if (repetido != null) {
      emit(state.copyWith(
          errorMessage: 'El insumo $repetido está dos veces en la receta.'));
      return;
    }

    emit(state.copyWith(isSaving: true, clearError: true));
    try {
      final payload = _payloadDelBorrador();

      if (state.editingRecetaId == null) {
        await _apiService.createReceta(payload);
        emit(state.copyWith(
          isSaving: false,
          successMessage: 'Receta creada exitosamente',
        ));
      } else {
        await _apiService.updateReceta(state.editingRecetaId!, payload);
        emit(state.copyWith(
          isSaving: false,
          successMessage: 'Receta actualizada exitosamente',
        ));
      }
      add(const CargarRecetas());
    } catch (e) {
      emit(state.copyWith(isSaving: false, errorMessage: e.toString()));
    }
  }

  /// Nombre del primer insumo que aparece más de una vez, o null.
  String? _insumoRepetido() {
    final vistos = <int>{};
    for (final d in state.detalles) {
      if (!d.sinInsumo && !vistos.add(d.articuloId)) {
        return d.articuloNombre ?? 'con ID ${d.articuloId}';
      }
    }
    return null;
  }

  Map<String, dynamic> _payloadDelBorrador() => {
        if (state.creaProductoNuevo)
          'productoNuevo': {
            'nombre': state.nuevoProductoNombre.trim(),
            if (state.nuevoProductoCategoriaId != null)
              'categoriaId': state.nuevoProductoCategoriaId,
            if (state.nuevoProductoPorcentaje != null)
              'porcentajeGanancia': state.nuevoProductoPorcentaje,
            'vendible': !state.nuevoProductoPreparacionBase,
          }
        else
          'espProductoCodigo': state.selectedProductoCodigo,
        'nombre': state.nombre,
        if (state.descripcion.isNotEmpty) 'descripcion': state.descripcion,
        'costosAdicionales': state.costosAdicionales,
        'rinde': state.rinde,
        'rindeUnidad': state.rindeUnidad.trim().isEmpty ? 'unidades' : state.rindeUnidad.trim(),
        if (state.esPreparacionBase) 'rindeUnidadMedida': state.rindeUnidadMedida,
        'detalles': state.detalles.map((d) => {
          'articuloId': d.articuloId,
          'cantidad': d.cantidad,
          'unidadMedida': d.unidadMedida,
        }).toList(),
      };
}
