import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sgi_u_frontend/theme/app_theme.dart';
import 'package:sgi_u_frontend/widgets/app_button.dart';
import 'package:sgi_u_frontend/widgets/app_campos.dart';
import 'package:sgi_u_frontend/widgets/app_data_table.dart';
import 'package:sgi_u_frontend/widgets/app_dialog.dart';
import 'package:sgi_u_frontend/widgets/app_snack_bar.dart';
import 'package:sgi_u_frontend/widgets/card_kpi.dart';
import 'package:sgi_u_frontend/widgets/estado_chip.dart';
import 'package:sgi_u_frontend/widgets/estado_seccion.dart';
import 'package:sgi_u_frontend/widgets/section_header.dart';

Widget _envolver(Widget child) => MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(body: child),
    );

void main() {
  testWidgets('SectionHeader muestra título, bajada y acción', (t) async {
    await t.pumpWidget(_envolver(const SectionHeader(
      titulo: 'Productos',
      subtitulo: 'Catálogo',
      accion: Text('Nuevo'),
    )));
    expect(find.text('Productos'), findsOneWidget);
    expect(find.text('Catálogo'), findsOneWidget);
    expect(find.text('Nuevo'), findsOneWidget);
  });

  testWidgets('AppButton.primary dispara onPressed', (t) async {
    var tocado = false;
    await t.pumpWidget(_envolver(AppButton.primary(
      onPressed: () => tocado = true,
      child: const Text('Guardar'),
    )));
    await t.tap(find.text('Guardar'));
    expect(tocado, isTrue);
  });

  testWidgets('AppDialog muestra título, contenido y acciones', (t) async {
    await t.pumpWidget(_envolver(Builder(
      builder: (context) => TextButton(
        onPressed: () => showDialog<void>(
          context: context,
          builder: (_) => AppDialog(
            titulo: 'Confirmar',
            acciones: [
              TextButton(onPressed: () {}, child: const Text('Sí')),
            ],
            child: const Text('¿Seguro?'),
          ),
        ),
        child: const Text('Abrir'),
      ),
    )));
    await t.tap(find.text('Abrir'));
    await t.pumpAndSettle();
    expect(find.text('Confirmar'), findsOneWidget);
    expect(find.text('¿Seguro?'), findsOneWidget);
    expect(find.text('Sí'), findsOneWidget);
  });

  testWidgets('AppSnackBar.exito muestra el mensaje', (t) async {
    late BuildContext contexto;
    await t.pumpWidget(_envolver(Builder(builder: (context) {
      contexto = context;
      return const SizedBox();
    })));
    AppSnackBar.exito(contexto, 'Guardado');
    await t.pump();
    expect(find.text('Guardado'), findsOneWidget);
  });

  testWidgets('EstadoChip muestra la etiqueta', (t) async {
    await t.pumpWidget(_envolver(const EstadoChip(
      etiqueta: 'Activo',
      tono: TonoEstado.exito,
    )));
    expect(find.text('Activo'), findsOneWidget);
  });

  testWidgets('CardKpi muestra rótulo y número', (t) async {
    await t.pumpWidget(_envolver(const CardKpi(
      titulo: 'Ventas',
      valor: r'$ 100',
    )));
    expect(find.text('Ventas'), findsOneWidget);
    expect(find.text(r'$ 100'), findsOneWidget);
  });

  testWidgets('EmptyState y ErrorState muestran su mensaje', (t) async {
    await t.pumpWidget(_envolver(const EmptyState(mensaje: 'Sin datos')));
    expect(find.text('Sin datos'), findsOneWidget);

    await t.pumpWidget(_envolver(ErrorState(
      mensaje: 'Falló',
      onReintentar: () {},
    )));
    expect(find.text('Falló'), findsOneWidget);
    expect(find.text('Reintentar'), findsOneWidget);
  });

  testWidgets('AppDataTable renderiza columnas y filas', (t) async {
    await t.pumpWidget(_envolver(const AppDataTable(
      columnas: [DataColumn(label: Text('Nombre'))],
      filas: [
        DataRow(cells: [DataCell(Text('Uno'))]),
      ],
    )));
    expect(find.text('Nombre'), findsOneWidget);
    expect(find.text('Uno'), findsOneWidget);
  });

  testWidgets('AppTextField y AppDropdown muestran su etiqueta', (t) async {
    await t.pumpWidget(_envolver(const Column(children: [
      AppTextField(label: 'Usuario'),
      AppDropdown<String>(
        label: 'Rol',
        items: [DropdownMenuItem(value: 'a', child: Text('Admin'))],
      ),
    ])));
    expect(find.text('Usuario'), findsOneWidget);
    expect(find.text('Rol'), findsOneWidget);
  });
}
