import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../models/configuracion_negocio.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_elevations.dart';
import '../theme/app_radii.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../widgets/app_button.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/app_snack_bar.dart';
import '../widgets/cargando_diferido.dart';
import '../widgets/configuracion/categorias_card.dart';
import '../widgets/configuracion/metodos_pago_card.dart';
import '../widgets/configuracion/tipos_producto_card.dart';

class SettingsScreen extends StatefulWidget {
  final ApiService? apiService;

  const SettingsScreen({super.key, this.apiService});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final ApiService _apiService;
  final _formKey = GlobalKey<FormState>();

  final _nombreCtrl = TextEditingController();
  final _codigoCtrl = TextEditingController();
  final _direccionCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();
  final _descripcionCtrl = TextEditingController();

  Uint8List? _logoBytes;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _apiService = widget.apiService ?? ApiService();
    _cargarConfiguracion();
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _codigoCtrl.dispose();
    _direccionCtrl.dispose();
    _telefonoCtrl.dispose();
    _descripcionCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargarConfiguracion() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final config = await _apiService.getConfiguracion();
      if (!mounted) return;
      setState(() {
        _nombreCtrl.text = config.nombre;
        _codigoCtrl.text = config.codigoCliente ?? '';
        _direccionCtrl.text = config.direccion ?? '';
        _telefonoCtrl.text = config.telefono ?? '';
        _descripcionCtrl.text = config.descripcion ?? '';
        _logoBytes = config.logo;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'No se pudo cargar la configuración: $e';
      });
    }
  }

  Future<void> _seleccionarLogo() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final bytes = result.files.single.bytes;
        if (bytes != null) {
          setState(() {
            _logoBytes = bytes;
          });
        }
      }
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.error(context, 'Error al seleccionar imagen: $e');
    }
  }

  void _eliminarLogo() {
    setState(() {
      _logoBytes = null;
    });
  }

  Future<void> _guardarConfiguracion() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final config = ConfiguracionNegocio(
      nombre: _nombreCtrl.text.trim(),
      codigoCliente: _codigoCtrl.text.trim().isNotEmpty ? _codigoCtrl.text.trim() : null,
      direccion: _direccionCtrl.text.trim().isNotEmpty ? _direccionCtrl.text.trim() : null,
      telefono: _telefonoCtrl.text.trim().isNotEmpty ? _telefonoCtrl.text.trim() : null,
      descripcion: _descripcionCtrl.text.trim().isNotEmpty ? _descripcionCtrl.text.trim() : null,
      logo: _logoBytes,
    );

    try {
      await _apiService.saveConfiguracion(config);
      if (!mounted) return;
      setState(() => _isSaving = false);
      AppSnackBar.exito(context, 'Configuración guardada correctamente');
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      AppSnackBar.error(context, 'Error al guardar configuración: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      body: _isLoading
          ? const CargandoDiferido()
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_errorMessage!,
                          style: AppTypography.texto
                              .copyWith(color: AppColors.error)),
                      const SizedBox(height: AppSpacing.espacioEstandar),
                      AppButton.primary(
                        onPressed: _cargarConfiguracion,
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.espacioSeccion),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Personalización del Negocio',
                          style: AppTypography.tituloPantalla
                              .copyWith(color: AppColors.textoPrincipal),
                        ),
                        const SizedBox(height: AppSpacing.espacioChico),
                        Text(
                          'Configure los datos e imagen corporativa que aparecerán en la interfaz y en los comprobantes.',
                          style: AppTypography.textoChico
                              .copyWith(color: AppColors.textoInactivo),
                        ),
                        const SizedBox(height: AppSpacing.espacioSeccion),

                        // Tarjeta Identidad Visual (Logo)
                        Card(
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
                                Text(
                                  'Logo del Negocio',
                                  style: AppTypography.texto.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textoPrincipal),
                                ),
                                const SizedBox(height: AppSpacing.espacioMedio),
                                Row(
                                  children: [
                                    Container(
                                      width: 100,
                                      height: 100,
                                      decoration: BoxDecoration(
                                        color: AppColors.fondoApp,
                                        borderRadius: AppRadii.bordeTarjeta,
                                        border: Border.all(color: AppColors.bordeSuave),
                                      ),
                                      clipBehavior: Clip.antiAlias,
                                      child: _logoBytes != null && _logoBytes!.isNotEmpty
                                          ? Image.memory(
                                              _logoBytes!,
                                              fit: BoxFit.contain,
                                            )
                                          : const Center(
                                              child: Icon(
                                                Icons.storefront_outlined,
                                                size: 40,
                                                color: AppColors.textoInactivo,
                                              ),
                                            ),
                                    ),
                                    const SizedBox(width: AppSpacing.espacioGrande),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        AppButton.primary(
                                          key: const Key('settings_pick_logo_btn'),
                                          onPressed: _seleccionarLogo,
                                          icono: Icons.upload,
                                          child: const Text('Subir Logo'),
                                        ),
                                        if (_logoBytes != null) ...[
                                          const SizedBox(height: AppSpacing.espacioChico),
                                          AppButton.danger(
                                            key: const Key('settings_remove_logo_btn'),
                                            onPressed: _eliminarLogo,
                                            icono: Icons.delete_outline,
                                            child: const Text('Quitar Logo'),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.espacioSeccion),

                        // Tarjeta Datos del Comercio
                        Card(
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
                                Text(
                                  'Datos Generales',
                                  style: AppTypography.texto.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textoPrincipal),
                                ),
                                const SizedBox(height: AppSpacing.espacioEstandar),
                                TextFormField(
                                  key: const Key('settings_nombre_field'),
                                  controller: _nombreCtrl,
                                  decoration: const InputDecoration(
                                    labelText: 'Nombre del Negocio *',
                                    hintText: 'Ej: Almacén Don Juan',
                                  ),
                                  validator: (v) {
                                    if (v == null || v.trim().isEmpty) {
                                      return 'El nombre del negocio es obligatorio';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: AppSpacing.espacioEstandar),
                                TextFormField(
                                  key: const Key('settings_codigo_field'),
                                  controller: _codigoCtrl,
                                  decoration: const InputDecoration(
                                    labelText: 'Código de Cliente',
                                    hintText: 'Ej: SGIU-CLI-001',
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.espacioEstandar),
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        key: const Key('settings_telefono_field'),
                                        controller: _telefonoCtrl,
                                        decoration: const InputDecoration(
                                          labelText: 'Teléfono de Contacto',
                                          hintText: 'Ej: +54 9 11 1234-5678',
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: AppSpacing.espacioEstandar),
                                    Expanded(
                                      child: TextFormField(
                                        key: const Key('settings_direccion_field'),
                                        controller: _direccionCtrl,
                                        decoration: const InputDecoration(
                                          labelText: 'Dirección Comercial',
                                          hintText: 'Ej: Av. San Martín 1234',
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: AppSpacing.espacioEstandar),
                                TextFormField(
                                  key: const Key('settings_descripcion_field'),
                                  controller: _descripcionCtrl,
                                  maxLines: 2,
                                  decoration: const InputDecoration(
                                    labelText: 'Descripción / Slogan',
                                    hintText: 'Ej: Calidad y servicio desde 1995',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.espacioSeccion),

                        // Botón Guardar
                        Align(
                          alignment: Alignment.centerRight,
                          child: AppButton.primary(
                            key: const Key('settings_guardar_btn'),
                            onPressed: _isSaving ? null : _guardarConfiguracion,
                            child: _isSaving
                                ? const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          color: AppColors.sobreMarca,
                                          strokeWidth: 2,
                                        ),
                                      ),
                                      SizedBox(width: AppSpacing.espacioChico),
                                      Text('Guardando...'),
                                    ],
                                  )
                                : const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.save, size: 18),
                                      SizedBox(width: AppSpacing.espacioChico),
                                      Text('Guardar Cambios'),
                                    ],
                                  ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.espacioPantalla),
                        const TiposProductoCard(),
                        const SizedBox(height: AppSpacing.espacioEstandar),
                        CategoriasCard(apiService: _apiService),
                        const SizedBox(height: AppSpacing.espacioSeccion),
                        MetodosPagoCard(apiService: _apiService),
                      ],
                    ),
                  ),
                ),
    );
  }
}
