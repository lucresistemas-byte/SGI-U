import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_elevations.dart';
import '../theme/app_radii.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../theme/app_widths.dart';
import '../widgets/app_button.dart';
import '../widgets/card_kpi.dart';
import '../widgets/estado_chip.dart';
import '../widgets/estado_seccion.dart';
import '../widgets/section_header.dart';

/// Pantalla de referencia del sistema de estilos (solo dev): muestra la
/// paleta, la escala tipográfica, el espaciado, los radios y los componentes.
/// No es una pantalla de negocio: sirve para revisar la base unificada.
class CatalogoEstilosScreen extends StatelessWidget {
  static const String ruta = '/catalogo-estilos';

  const CatalogoEstilosScreen({super.key});

  static const List<(String, Color)> _colores = [
    ('marca', AppColors.marca),
    ('marcaAcento', AppColors.marcaAcento),
    ('marcaActiva', AppColors.marcaActiva),
    ('sobreMarca', AppColors.sobreMarca),
    ('seleccionFondo', AppColors.seleccionFondo),
    ('estadoActivo', AppColors.estadoActivo),
    ('textoPrincipal', AppColors.textoPrincipal),
    ('textoSecundario', AppColors.textoSecundario),
    ('textoTerciario', AppColors.textoTerciario),
    ('textoInactivo', AppColors.textoInactivo),
    ('fondoApp', AppColors.fondoApp),
    ('fondoMenu', AppColors.fondoMenu),
    ('fondoAlternativo', AppColors.fondoAlternativo),
    ('borde', AppColors.borde),
    ('bordeSuave', AppColors.bordeSuave),
    ('menuTexto', AppColors.menuTexto),
    ('exito', AppColors.exito),
    ('exitoFondo', AppColors.exitoFondo),
    ('error', AppColors.error),
    ('alerta', AppColors.alerta),
    ('alertaFondo', AppColors.alertaFondo),
    ('info', AppColors.info),
  ];

  static const List<(String, TextStyle)> _tipografia = [
    ('marca', AppTypography.marca),
    ('tituloPantalla', AppTypography.tituloPantalla),
    ('numeroKpi', AppTypography.numeroKpi),
    ('tituloTarjeta', AppTypography.tituloTarjeta),
    ('subtitulo', AppTypography.subtitulo),
    ('texto', AppTypography.texto),
    ('textoChico', AppTypography.textoChico),
    ('etiqueta', AppTypography.etiqueta),
    ('pie', AppTypography.pie),
    ('micro', AppTypography.micro),
  ];

  static const List<(String, double)> _espaciado = [
    ('espacioMinimo', AppSpacing.espacioMinimo),
    ('espacioChico', AppSpacing.espacioChico),
    ('espacioMedio', AppSpacing.espacioMedio),
    ('espacioEstandar', AppSpacing.espacioEstandar),
    ('espacioGrande', AppSpacing.espacioGrande),
    ('espacioSeccion', AppSpacing.espacioSeccion),
    ('espacioPantalla', AppSpacing.espacioPantalla),
  ];

  static const List<(String, double)> _radios = [
    ('radioMinimo', AppRadii.radioMinimo),
    ('radioChico', AppRadii.radioChico),
    ('radioTarjeta', AppRadii.radioTarjeta),
    ('radioCampo', AppRadii.radioCampo),
    ('radioBoton', AppRadii.radioBoton),
    ('radioPanel', AppRadii.radioPanel),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Catálogo de estilos')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.espacioSeccion),
        children: [
          const SectionHeader(
            titulo: 'Catálogo de estilos',
            subtitulo: 'Referencia del sistema (solo dev).',
          ),
          const SizedBox(height: AppSpacing.espacioPantalla),
          _seccion('Colores'),
          Wrap(
            spacing: AppSpacing.espacioChico,
            runSpacing: AppSpacing.espacioChico,
            children: [
              for (final (nombre, color) in _colores)
                _muestraColor(nombre, color),
            ],
          ),
          const SizedBox(height: AppSpacing.espacioPantalla),
          _seccion('Tipografía'),
          for (final (nombre, estilo) in _tipografia)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.espacioChico),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  SizedBox(
                    width: 150,
                    child: Text(
                      nombre,
                      style: AppTypography.etiqueta
                          .copyWith(color: AppColors.textoSecundario),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'SGI-U 123',
                      style: estilo.copyWith(color: AppColors.textoPrincipal),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: AppSpacing.espacioPantalla),
          _seccion('Espaciado'),
          for (final (nombre, valor) in _espaciado)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.espacioChico),
              child: Row(
                children: [
                  SizedBox(
                    width: 150,
                    child: Text(
                      '$nombre ($valor)',
                      style: AppTypography.etiqueta
                          .copyWith(color: AppColors.textoSecundario),
                    ),
                  ),
                  Container(
                    width: valor,
                    height: AppSpacing.espacioMedio,
                    color: AppColors.marcaAcento,
                  ),
                ],
              ),
            ),
          const SizedBox(height: AppSpacing.espacioPantalla),
          _seccion('Radios'),
          Wrap(
            spacing: AppSpacing.espacioChico,
            runSpacing: AppSpacing.espacioChico,
            children: [
              for (final (nombre, valor) in _radios)
                Column(
                  children: [
                    Container(
                      width: AppWidths.anchoModalChico / 6,
                      height: AppWidths.anchoModalChico / 6,
                      decoration: BoxDecoration(
                        color: AppColors.seleccionFondo,
                        borderRadius: BorderRadius.circular(valor),
                        border: Border.all(color: AppColors.borde),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.espacioMinimo),
                    Text(
                      nombre,
                      style: AppTypography.pie
                          .copyWith(color: AppColors.textoSecundario),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.espacioPantalla),
          _seccion('Componentes'),
          Wrap(
            spacing: AppSpacing.espacioChico,
            runSpacing: AppSpacing.espacioChico,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              AppButton.primary(onPressed: () {}, child: const Text('Primario')),
              AppButton.secondary(
                  onPressed: () {}, icono: Icons.add, child: const Text('Secundario')),
              AppButton.ghost(onPressed: () {}, child: const Text('Ghost')),
              AppButton.danger(onPressed: () {}, child: const Text('Peligro')),
            ],
          ),
          const SizedBox(height: AppSpacing.espacioEstandar),
          const Wrap(
            spacing: AppSpacing.espacioChico,
            runSpacing: AppSpacing.espacioChico,
            children: [
              EstadoChip(etiqueta: 'Activo', tono: TonoEstado.exito),
              EstadoChip(etiqueta: 'Inactivo', tono: TonoEstado.error),
              EstadoChip(etiqueta: 'Stock bajo', tono: TonoEstado.alerta),
              EstadoChip(etiqueta: 'Info', tono: TonoEstado.info),
              EstadoChip(etiqueta: 'Sin estado'),
            ],
          ),
          const SizedBox(height: AppSpacing.espacioPantalla),
          const CardKpi(
            titulo: 'Ventas del mes',
            valor: r'$ 123.456,00',
            icono: Icons.trending_up,
          ),
          const SizedBox(height: AppSpacing.espacioPantalla),
          const EmptyState(mensaje: 'No hay datos para mostrar.'),
          const SizedBox(height: AppSpacing.espacioPantalla),
          ErrorState(
            mensaje: 'No se pudieron cargar los datos.',
            onReintentar: () {},
          ),
          const SizedBox(height: AppSpacing.espacioPantalla),
          _seccion('Sombras'),
          Container(
            height: 80,
            decoration: const BoxDecoration(
              color: AppColors.fondoSuperficie,
              borderRadius: AppRadii.bordeTarjeta,
              boxShadow: AppElevations.sombraPanel,
            ),
          ),
        ],
      ),
    );
  }

  Widget _seccion(String titulo) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.espacioEstandar),
        child: Text(
          titulo,
          style: AppTypography.tituloTarjeta
              .copyWith(color: AppColors.textoPrincipal),
        ),
      );

  Widget _muestraColor(String nombre, Color color) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 120,
            height: 56,
            decoration: BoxDecoration(
              color: color,
              borderRadius: AppRadii.bordeChico,
              border: Border.all(color: AppColors.borde),
            ),
          ),
          const SizedBox(height: AppSpacing.espacioMinimo),
          SizedBox(
            width: 120,
            child: Text(
              nombre,
              textAlign: TextAlign.center,
              style: AppTypography.pie
                  .copyWith(color: AppColors.textoSecundario),
            ),
          ),
        ],
      );
}
