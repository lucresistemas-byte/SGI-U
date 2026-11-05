import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/auth/auth_bloc.dart';
import '../blocs/auth/auth_event.dart';
import '../blocs/auth/auth_state.dart';

/// A2: pantalla obligatoria al ingresar con la contraseña de fábrica.
/// El backend solo deja pasar /api/auth/cambiar-password hasta que se
/// complete el cambio; al confirmar, el AuthBloc emite Authenticated y
/// StartupDecider muestra el sistema.
class CambioPasswordScreen extends StatefulWidget {
  const CambioPasswordScreen({super.key});

  @override
  State<CambioPasswordScreen> createState() => _CambioPasswordScreenState();
}

class _CambioPasswordScreenState extends State<CambioPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _actualController = TextEditingController();
  final _nuevaController = TextEditingController();
  final _repetirController = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _actualController.dispose();
    _nuevaController.dispose();
    _repetirController.dispose();
    super.dispose();
  }

  void _enviar() {
    if (context.read<AuthBloc>().state is AuthLoading) return;
    if (_formKey.currentState!.validate()) {
      context.read<AuthBloc>().add(CambiarPasswordRequested(
            _actualController.text.trim(),
            _nuevaController.text.trim(),
          ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            width: 440,
            margin: const EdgeInsets.symmetric(vertical: 32),
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 16,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: BlocConsumer<AuthBloc, AuthState>(
              listener: (context, state) {
                if (state is AuthError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.message),
                      backgroundColor: Colors.red.shade800,
                    ),
                  );
                }
              },
              builder: (context, state) {
                final isLoading = state is AuthLoading;
                return Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.lock_reset,
                          size: 40, color: Color(0xFF006B3D)),
                      const SizedBox(height: 16),
                      const Text(
                        'Cambiar contraseña',
                        style: TextStyle(
                          fontFamily: 'Georgia',
                          fontSize: 28,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF1E2430),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Es la primera vez que ingresas. Elegí una contraseña '
                        'nueva para continuar (mínimo 6 caracteres).',
                        style: TextStyle(
                          fontSize: 15,
                          color: Color(0xFF8A8A8A),
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 28),
                      _campo(
                        controller: _actualController,
                        hintText: 'Contraseña actual',
                        validator: (v) => v == null || v.isEmpty
                            ? 'Campo obligatorio'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      _campo(
                        controller: _nuevaController,
                        hintText: 'Nueva contraseña',
                        obscure: _obscure,
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Campo obligatorio';
                          if (v.trim().length < 6) {
                            return 'Mínimo 6 caracteres';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _campo(
                        controller: _repetirController,
                        hintText: 'Repetir nueva contraseña',
                        obscure: _obscure,
                        validator: (v) {
                          if (v != _nuevaController.text) {
                            return 'Las contraseñas no coinciden';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Checkbox(
                            value: !_obscure,
                            onChanged: (v) =>
                                setState(() => _obscure = !(v ?? true)),
                          ),
                          const Text('Mostrar contraseñas'),
                        ],
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : _enviar,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF006B3D),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: isLoading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'Guardar contraseña',
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _campo({
    required TextEditingController controller,
    required String hintText,
    String? Function(String?)? validator,
    bool obscure = false,
  }) {
    return Container(
      height: 54,
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE5E5E5)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscure,
        validator: validator,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(fontSize: 15, color: Color(0xFF8C8C8C)),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        ),
      ),
    );
  }
}
