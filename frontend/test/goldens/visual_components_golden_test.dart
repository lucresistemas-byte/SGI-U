import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sgi_u_frontend/theme/app_colors.dart';
import 'package:sgi_u_frontend/theme/app_theme.dart';
import 'package:sgi_u_frontend/widgets/app_button.dart';
import 'package:sgi_u_frontend/widgets/app_data_table.dart';
import 'package:sgi_u_frontend/widgets/app_dialog.dart';
import 'package:sgi_u_frontend/widgets/card_kpi.dart';
import 'package:sgi_u_frontend/widgets/estado_chip.dart';
import 'package:sgi_u_frontend/widgets/section_header.dart';

Widget _wrap(Widget child, {Size? size}) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: AppTheme.light,
    home: Scaffold(
      backgroundColor: AppColors.fondoApp,
      body: SizedBox(
        width: size?.width,
        height: size?.height,
        child: Center(child: child),
      ),
    ),
  );
}

void main() {
  const sizeDesktop = Size(1366, 768);
  const sizeMobile = Size(800, 600);

  group('Golden Tests - Componentes Reutilizables de Estilo', () {
    testWidgets('AppDataTable - Desktop (1366x768)', (tester) async {
      tester.view.physicalSize = sizeDesktop;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final widget = _wrap(
        const SizedBox(
          width: 900,
          child: AppDataTable(
            columnas: [
              DataColumn(label: Text('Código')),
              DataColumn(label: Text('Nombre')),
              DataColumn(label: Text('Stock')),
              DataColumn(label: Text('Estado')),
            ],
            filas: [
              DataRow(cells: [
                DataCell(Text('ART-001')),
                DataCell(Text('Harina 000 1kg')),
                DataCell(Text('25 un.')),
                DataCell(EstadoChip(etiqueta: 'Activo', tono: TonoEstado.exito)),
              ]),
              DataRow(cells: [
                DataCell(Text('ART-002')),
                DataCell(Text('Azúcar 1kg')),
                DataCell(Text('4 un.')),
                DataCell(EstadoChip(etiqueta: 'Bajo stock', tono: TonoEstado.alerta)),
              ]),
              DataRow(cells: [
                DataCell(Text('ART-003')),
                DataCell(Text('Esencia de Vainilla')),
                DataCell(Text('0 un.')),
                DataCell(EstadoChip(etiqueta: 'Agotado', tono: TonoEstado.error)),
              ]),
            ],
          ),
        ),
        size: sizeDesktop,
      );

      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('snapshots/app_data_table_desktop.png'),
      );
    });

    testWidgets('AppDialog y CardKPI - Tablet/Mobile (800x600)', (tester) async {
      tester.view.physicalSize = sizeMobile;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final widget = _wrap(
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SectionHeader(
                titulo: 'Resumen de Stock',
                subtitulo: 'Monitoreo de componentes en tiempo real',
              ),
              const SizedBox(height: 16),
              const Row(
                children: [
                  Expanded(
                    child: CardKpi(
                      titulo: 'Total Productos',
                      valor: '142',
                      icono: Icons.inventory_2_outlined,
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: CardKpi(
                      titulo: 'En Alerta',
                      valor: '3',
                      colorValor: AppColors.error,
                      icono: Icons.warning_amber_rounded,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              AppDialog(
                titulo: 'Confirmar Operación',
                tamano: TamanoDialogo.chico,
                mostrarCerrar: false,
                acciones: [
                  AppButton.secondary(
                    onPressed: () {},
                    child: const Text('Cancelar'),
                  ),
                  AppButton.primary(
                    onPressed: () {},
                    child: const Text('Aceptar'),
                  ),
                ],
                child: const Text(
                  '¿Desea asentar el cambio en el balance de inventario?',
                ),
              ),
            ],
          ),
        ),
        size: sizeMobile,
      );

      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('snapshots/dialog_and_cards_mobile.png'),
      );
    });
  });
}
