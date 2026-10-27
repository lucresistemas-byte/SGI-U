import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Buscador estándar del sistema: un `TextField` sin el borde que aporta el
/// `inputDecorationTheme` global (que se veía como un recuadro rectangular
/// detrás del marco redondeado) dentro de un contenedor con el borde propio.
///
/// Reemplaza los `Container` + `TextField(border: InputBorder.none)` escritos a
/// mano en Productos, Materia Prima, Pedidos y Login.
class CampoBuscador extends StatelessWidget {
  final TextEditingController? controller;
  final String hintText;
  final Key? campoKey;
  final IconData icono;
  final bool iconoAlFrente;
  final ValueChanged<String>? onChanged;
  final double? ancho;
  final double? alto;
  final bool conSombra;
  final bool obscureText;
  final Widget? suffixIcon;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onFieldSubmitted;
  final FocusNode? focusNode;
  final FormFieldValidator<String>? validator;
  final bool esFormField;

  const CampoBuscador({
    super.key,
    this.controller,
    required this.hintText,
    this.campoKey,
    this.icono = Icons.search,
    this.iconoAlFrente = true,
    this.onChanged,
    this.ancho,
    this.alto,
    this.conSombra = true,
    this.obscureText = false,
    this.suffixIcon,
    this.textInputAction,
    this.onFieldSubmitted,
    this.focusNode,
    this.validator,
    this.esFormField = false,
  });

  @override
  Widget build(BuildContext context) {
    final lupa = Icon(icono, color: AppColors.textoTerciario, size: 22);
    final decoration = InputDecoration(
      hintText: hintText,
      hintStyle: AppTypography.texto.copyWith(color: AppColors.textoSecundario),
      prefixIcon: iconoAlFrente ? lupa : null,
      suffixIcon: suffixIcon ?? (iconoAlFrente ? null : lupa),
      // La decoración global del tema pinta un borde rectangular y un
      // relleno que sobresale; acá se anulan para dejar solo el marco del
      // contenedor.
      border: InputBorder.none,
      enabledBorder: InputBorder.none,
      focusedBorder: InputBorder.none,
      filled: false,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.espacioGrande,
          vertical: AppSpacing.espacioMedioGrande),
    );
    final child = esFormField || validator != null
        ? TextFormField(
            key: campoKey,
            controller: controller,
            focusNode: focusNode,
            obscureText: obscureText,
            textInputAction: textInputAction,
            onFieldSubmitted: onFieldSubmitted,
            onChanged: onChanged,
            decoration: decoration,
            validator: validator,
          )
        : TextField(
            key: campoKey,
            controller: controller,
            focusNode: focusNode,
            obscureText: obscureText,
            textInputAction: textInputAction,
            onSubmitted: onFieldSubmitted,
            onChanged: onChanged,
            decoration: decoration,
          );
    return Container(
      width: ancho,
      height: alto,
      decoration: BoxDecoration(
        color: AppColors.fondoSuperficie,
        borderRadius: AppRadii.bordeCampo,
        border: Border.all(color: AppColors.borde),
        boxShadow: conSombra
            ? [
                BoxShadow(
                  color: AppColors.textoPrincipal.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: child,
    );
  }
}
