import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/auth/auth_bloc.dart';
import '../blocs/auth/auth_event.dart';
import '../blocs/auth/auth_state.dart';
import 'dart:ui' as ui;
import '../theme/app_breakpoints.dart';
import '../theme/app_colors.dart';
import '../theme/app_elevations.dart';
import '../theme/app_radii.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../widgets/app_snack_bar.dart';
import '../widgets/campo_buscador.dart';
import '../widgets/marca_negocio.dart';

const String mensajeSesionVencida = 'Tu sesión venció, vuelve a ingresar';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordFocus = FocusNode();
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    // Logo y nombre del negocio (endpoint público).
    MarcaNegocio.cargar();
    // Muestra el aviso cuando se llega al login con la sesión vencida (el
    // estado se emite antes de montar esta pantalla, por lo que el listener
    // de BlocConsumer no llega a dispararse). Solo la ruta visible lo muestra:
    // al volver a montar StartupDecider, la instancia de la ruta descartada
    // no debe repetir el aviso.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final state = context.read<AuthBloc>().state;
      final esRutaVisible = ModalRoute.of(context)?.isCurrent ?? true;
      if (state is Unauthenticated && state.sesionVencida && esRutaVisible) {
        AppSnackBar.error(context, mensajeSesionVencida);
      }
    });
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  void _login() {
    // Enter puede llegar mientras el login anterior sigue en curso (el botón
    // ya está deshabilitado en ese caso, el teclado no).
    if (context.read<AuthBloc>().state is AuthLoading) return;
    if (_formKey.currentState!.validate()) {
      context.read<AuthBloc>().add(LoginRequested(
        _usernameController.text.trim(),
        _passwordController.text.trim(),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= AppBreakpoints.corteMovil;
          return Stack(
            children: [
              Container(
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/images/login_background.png'),
                    fit: BoxFit.cover,
                  ),
                ),
                child: BackdropFilter(
                  filter: ui.ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
                  child: Container(
                    // Velo oscuro tenue sobre la foto de fondo.
                    color: AppColors.textoPrincipal.withValues(alpha: 0.05),
                  ),
                ),
              ),
              Center(
                child: Container(
                  width: constraints.maxWidth * 0.85,
                  constraints: BoxConstraints(
                    maxHeight: constraints.maxHeight * 0.85,
                  ),
                  decoration: const BoxDecoration(
                    color: AppColors.fondoSuperficie,
                    borderRadius: AppRadii.bordePanel,
                    boxShadow: AppElevations.sombraPanel,
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: isWide
                      ? Row(
                    children: [
                      Expanded(
                        flex: 1,
                        child: _buildLeftPanel(),
                      ),
                      Expanded(
                        flex: 1,
                        child: SingleChildScrollView(
                          child: _buildRightPanel(),
                        ),
                      ),
                    ],
                  )
                      : SingleChildScrollView(
                    child: Column(
                      children: [
                        _buildRightPanel(isMobile: true),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLeftPanel() {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(AppRadii.radioPanel),
        bottomLeft: Radius.circular(AppRadii.radioPanel),
      ),
      child: Image.asset(
        'assets/images/login_background.png',
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      ),
    );
  }

  Widget _buildRightPanel({bool isMobile = false}) {
    final horizontalPadding =
        isMobile ? AppSpacing.espacioPantalla : 48.0; // más espacio en escritorio
    final verticalPadding = isMobile ? AppSpacing.espacioPantalla : 48.0;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: verticalPadding,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const MarcaNegocio(estilo: EstiloMarca.login),
          const SizedBox(height: AppSpacing.espacioSeccion),
          Text(
            'Bienvenido de nuevo',
            // Georgia: excepción de marca del login (no se tokeniza la familia).
            style: AppTypography.tituloPantalla.copyWith(
              fontFamily: 'Georgia',
              fontWeight: FontWeight.w400,
              color: AppColors.textoPrincipal,
            ),
          ),
          const SizedBox(height: AppSpacing.espacioMedio),
          Text(
            'Ingresa tus credenciales para continuar',
            style: AppTypography.texto.copyWith(
              fontWeight: FontWeight.w400,
              color: AppColors.textoSecundario,
            ),
          ),
          const SizedBox(height: AppSpacing.espacioPantalla),
          Form(
            key: _formKey,
            child: Column(
              children: [
                _buildTextField(
                  controller: _usernameController,
                  hintText: 'Usuario',
                  prefixIcon: Icons.person_outline,
                  textInputAction: TextInputAction.next,
                  // Enter en Usuario: pasa a Contraseña si está vacía; si no,
                  // inicia sesión.
                  onFieldSubmitted: (_) => _passwordController.text.isEmpty
                      ? _passwordFocus.requestFocus()
                      : _login(),
                ),
                const SizedBox(height: AppSpacing.espacioGrande),
                _buildPasswordField(),
                const SizedBox(height: AppSpacing.espacioPantalla),
                _buildLoginButton(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData prefixIcon,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputAction? textInputAction,
    ValueChanged<String>? onFieldSubmitted,
    FocusNode? focusNode,
    bool esFormField = false,
    FormFieldValidator<String>? validator,
  }) {
    return SizedBox(
      height: 60,
      child: CampoBuscador(
        controller: controller,
        focusNode: focusNode,
        hintText: hintText,
        icono: prefixIcon,
        iconoAlFrente: true,
        conSombra: false,
        ancho: double.infinity,
        alto: 60,
        obscureText: obscureText,
        suffixIcon: suffixIcon,
        textInputAction: textInputAction,
        onFieldSubmitted: onFieldSubmitted,
        esFormField: esFormField,
        validator: validator,
      ),
    );
  }

  Widget _buildPasswordField() {
    return _buildTextField(
      controller: _passwordController,
      focusNode: _passwordFocus,
      hintText: 'Contraseña',
      prefixIcon: Icons.lock_outline,
      obscureText: _obscurePassword,
      suffixIcon: IconButton(
        icon: Icon(
          _obscurePassword
              ? Icons.visibility_outlined
              : Icons.visibility_off_outlined,
          color: AppColors.textoTerciario,
          size: 22,
        ),
        onPressed: () {
          setState(() {
            _obscurePassword = !_obscurePassword;
          });
        },
      ),
      textInputAction: TextInputAction.done,
      onFieldSubmitted: (_) => _login(),
      esFormField: true,
      validator: (value) =>
          value == null || value.isEmpty ? 'Campo obligatorio' : null,
    );
  }

  Widget _buildLoginButton() {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthError) {
          AppSnackBar.error(context, state.message);
        }
      },
      builder: (context, state) {
        final isLoading = state is AuthLoading;
        return SizedBox(
          width: double.infinity,
          height: 60,
          child: ElevatedButton(
            onPressed: isLoading ? null : _login,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.marca,
              foregroundColor: AppColors.sobreMarca,
              shape: const RoundedRectangleBorder(
                borderRadius: AppRadii.bordeBoton,
              ),
            ),
            child: isLoading
                ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                color: AppColors.sobreMarca,
                strokeWidth: 2,
              ),
            )
                : Text(
              'Iniciar sesión',
              style: AppTypography.subtitulo
                  .copyWith(fontWeight: FontWeight.w600, color: AppColors.sobreMarca),
            ),
          ),
        );
      },
    );
  }
}
