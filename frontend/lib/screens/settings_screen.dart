import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../models/configuracion_negocio.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../widgets/app_scaffold.dart';

class SettingsScreen extends StatefulWidget {
  final ApiService? apiService;

  const SettingsScreen({Key? key, this.apiService}) : super(key: key);

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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al seleccionar imagen: $e')),
      );
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Configuración guardada correctamente'),
          backgroundColor: AppColors.verdePrincipal,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al guardar configuración: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Configuración',
      rutaActual: '/settings',
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _cargarConfiguracion,
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Personalización del Negocio',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Configure los datos e imagen corporativa que aparecerán en la interfaz y en los comprobantes.',
                          style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
                        ),
                        const SizedBox(height: 24),

                        // Tarjeta Identidad Visual (Logo)
                        Card(
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
                                const Text(
                                  'Logo del Negocio',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF1E293B),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Container(
                                      width: 100,
                                      height: 100,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF1F5F9),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: const Color(0xFFCBD5E1)),
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
                                                color: Color(0xFF94A3B8),
                                              ),
                                            ),
                                    ),
                                    const SizedBox(width: 20),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        ElevatedButton.icon(
                                          key: const Key('settings_pick_logo_btn'),
                                          onPressed: _seleccionarLogo,
                                          icon: const Icon(Icons.upload, size: 18),
                                          label: const Text('Subir Logo'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppColors.verdePrincipal,
                                            foregroundColor: Colors.white,
                                          ),
                                        ),
                                        if (_logoBytes != null) ...[
                                          const SizedBox(height: 8),
                                          OutlinedButton.icon(
                                            key: const Key('settings_remove_logo_btn'),
                                            onPressed: _eliminarLogo,
                                            icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                                            label: const Text('Quitar Logo', style: TextStyle(color: Colors.red)),
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
                        const SizedBox(height: 24),

                        // Tarjeta Datos del Comercio
                        Card(
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
                                const Text(
                                  'Datos Generales',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF1E293B),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  key: const Key('settings_nombre_field'),
                                  controller: _nombreCtrl,
                                  decoration: const InputDecoration(
                                    labelText: 'Nombre del Negocio *',
                                    hintText: 'Ej: Almacén Don Juan',
                                    border: OutlineInputBorder(),
                                  ),
                                  validator: (v) {
                                    if (v == null || v.trim().isEmpty) {
                                      return 'El nombre del negocio es obligatorio';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  key: const Key('settings_codigo_field'),
                                  controller: _codigoCtrl,
                                  decoration: const InputDecoration(
                                    labelText: 'Código de Cliente',
                                    hintText: 'Ej: SGIU-CLI-001',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        key: const Key('settings_telefono_field'),
                                        controller: _telefonoCtrl,
                                        decoration: const InputDecoration(
                                          labelText: 'Teléfono de Contacto',
                                          hintText: 'Ej: +54 9 11 1234-5678',
                                          border: OutlineInputBorder(),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: TextFormField(
                                        key: const Key('settings_direccion_field'),
                                        controller: _direccionCtrl,
                                        decoration: const InputDecoration(
                                          labelText: 'Dirección Comercial',
                                          hintText: 'Ej: Av. San Martín 1234',
                                          border: OutlineInputBorder(),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  key: const Key('settings_descripcion_field'),
                                  controller: _descripcionCtrl,
                                  maxLines: 2,
                                  decoration: const InputDecoration(
                                    labelText: 'Descripción / Slogan',
                                    hintText: 'Ej: Calidad y servicio desde 1995',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Botón Guardar
                        Align(
                          alignment: Alignment.centerRight,
                          child: ElevatedButton.icon(
                            key: const Key('settings_guardar_btn'),
                            onPressed: _isSaving ? null : _guardarConfiguracion,
                            icon: _isSaving
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.save),
                            label: Text(_isSaving ? 'Guardando...' : 'Guardar Cambios'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.verdePrincipal,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }
}
