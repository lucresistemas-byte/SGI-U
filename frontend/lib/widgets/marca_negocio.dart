import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../services/api_service.dart';

/// Dónde se muestra la marca del negocio.
enum EstiloMarca {
  /// Menú lateral expandido: logo + nombre (sin logo, solo el nombre).
  menu,

  /// Menú lateral colapsado: solo el logo chico (sin logo, las iniciales o
  /// un ícono neutro).
  menuCompacto,

  /// Pantalla de login: logo + nombre (sin logo, solo el nombre).
  login,
}

/// Logo y nombre del negocio. Escucha [ApiService.configuracion]: un cambio
/// guardado en Configuración se ve en el momento, sin reiniciar.
class MarcaNegocio extends StatelessWidget {
  final EstiloMarca estilo;

  const MarcaNegocio({super.key, required this.estilo});

  /// Trae nombre y logo del backend (login y arranque de la app). Los tests
  /// que no simulan la red lo reemplazan.
  static Future<void> Function() cargar = () => ApiService().cargarMarca();

  /// Iniciales de las dos primeras palabras ("Dulces Sandra" -> "DS").
  static String iniciales(String nombre) => nombre
      .split(RegExp(r'\s+'))
      .where((p) => p.isNotEmpty && RegExp(r'[A-Za-zÁÉÍÓÚÑáéíóúñ0-9]').hasMatch(p[0]))
      .take(2)
      .map((p) => p[0].toUpperCase())
      .join();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: ApiService.configuracion,
      builder: (context, config, _) {
        final nombre = config?.nombre.trim().isNotEmpty == true ? config!.nombre.trim() : 'SGI-U';
        final logo = config?.logo;
        final tieneLogo = logo != null && logo.isNotEmpty;
        switch (estilo) {
          case EstiloMarca.menuCompacto:
            if (tieneLogo) return _logo(logo, 40, const Key('logo_negocio_compacto'));
            final ini = iniciales(nombre);
            return CircleAvatar(
              key: const Key('iniciales_negocio'),
              radius: 20,
              backgroundColor: const Color(0xFFC8E6C9),
              foregroundColor: const Color(0xFF004D40),
              child: ini.isEmpty
                  ? const Icon(Icons.storefront, size: 20)
                  : Text(ini, style: const TextStyle(fontWeight: FontWeight.bold)),
            );
          case EstiloMarca.menu:
            return Row(
              children: [
                if (tieneLogo) ...[
                  _logo(logo, 36, const Key('logo_negocio_menu')),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: Text(
                    nombre,
                    key: const Key('nombre_negocio_menu'),
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            );
          case EstiloMarca.login:
            return Row(
              children: [
                if (tieneLogo) ...[
                  _logo(logo, 56, const Key('logo_negocio_login')),
                  const SizedBox(width: 14),
                ],
                Flexible(
                  child: Text(
                    nombre,
                    key: const Key('nombre_negocio_login'),
                    style: const TextStyle(
                        fontSize: 24, fontWeight: FontWeight.w600, color: Color(0xFF1E2430)),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            );
        }
      },
    );
  }

  Widget _logo(Uint8List bytes, double lado, Key key) => ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.memory(
          bytes,
          key: key,
          width: lado,
          height: lado,
          fit: BoxFit.contain,
          gaplessPlayback: true,
          // Una imagen dañada no rompe el menú ni el login.
          errorBuilder: (_, __, ___) => SizedBox(width: lado, height: lado),
        ),
      );
}
