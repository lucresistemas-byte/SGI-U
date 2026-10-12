import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sgi_u_frontend/blocs/finanzas/finanzas_bloc.dart';
import 'package:sgi_u_frontend/models/metodo_pago.dart';
import 'package:sgi_u_frontend/services/api_service.dart';
import 'package:sgi_u_frontend/widgets/movimiento_form_dialog.dart';

class MockFinanzasApi extends Mock implements ApiService {}

ElevatedButton _btnGuardar(WidgetTester tester) =>
    tester.widget<ElevatedButton>(find.widgetWithText(ElevatedButton, 'Guardar'));

Future<MockFinanzasApi> _pumpDialog(WidgetTester tester,
    {void Function(MockFinanzasApi api)? stub}) async {
  final api = MockFinanzasApi();
  when(() => api.getMovimientos(
          pagina: any(named: 'pagina'), limite: any(named: 'limite')))
      .thenAnswer((_) async => []);
  when(() => api.getBalance(any(), any()))
      .thenAnswer((_) async => {'totalIngresos': 0.0, 'totalEgresos': 0.0});
  // Activos, en orden: el formulario ofrece solo estos (no "Cheque", inactivo).
  when(() => api.getMetodosPago()).thenAnswer((_) async => const [
        MetodoPago(id: 4, nombre: 'Transferencia', orden: 1),
        MetodoPago(id: 1, nombre: 'Efectivo', fijo: true, orden: 2),
      ]);
  if (stub != null) stub(api);

  await tester.pumpWidget(
    MaterialApp(
      home: BlocProvider(
        create: (_) => FinanzasBloc(apiService: api),
        child: const Scaffold(body: MovimientoFormDialog()),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return api;
}

void main() {
  group('MovimientoFormDialog (N3)', () {
    testWidgets('monto vacío: el botón Guardar está deshabilitado',
        (WidgetTester tester) async {
      await _pumpDialog(tester);
      expect(_btnGuardar(tester).onPressed, isNull);
    });

    testWidgets('monto <= 0 deshabilita Guardar',
        (WidgetTester tester) async {
      await _pumpDialog(tester);

      await tester.enterText(
          find.widgetWithText(TextFormField, 'Monto (\$)'), '0');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Descripción'), 'Compra');
      await tester.pump();

      expect(_btnGuardar(tester).onPressed, isNull);
    });

    testWidgets('descripción vacía deshabilita Guardar',
        (WidgetTester tester) async {
      await _pumpDialog(tester);

      await tester.enterText(
          find.widgetWithText(TextFormField, 'Monto (\$)'), '100');
      await tester.pump();

      expect(_btnGuardar(tester).onPressed, isNull);
    });

    testWidgets('formulario válido habilita Guardar y envía el movimiento',
        (WidgetTester tester) async {
      final capturados = <Map<String, dynamic>>[];
      await _pumpDialog(tester, stub: (api) {
        when(() => api.createMovimiento(any())).thenAnswer((inv) async {
          capturados.add(inv.positionalArguments.first as Map<String, dynamic>);
        });
      });

      await tester.enterText(
          find.widgetWithText(TextFormField, 'Monto (\$)'), '100');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Descripción'), 'Venta diaria');
      await tester.pump();

      expect(_btnGuardar(tester).onPressed, isNotNull);

      await tester.tap(find.widgetWithText(ElevatedButton, 'Guardar'));
      await tester.pumpAndSettle();

      expect(capturados, hasLength(1));
      expect(capturados.single['tipo'], 'INGRESO');
      expect(capturados.single['monto'], 100.0);
      expect(capturados.single['descripcion'], 'Venta diaria');
      // Por defecto Efectivo (el fijo), aunque no sea el primero de la lista.
      expect(capturados.single['metodoPagoId'], 1);
    });

    testWidgets('ofrece los métodos activos y envía el id del elegido', (tester) async {
      final capturados = <Map<String, dynamic>>[];
      await _pumpDialog(tester, stub: (api) {
        when(() => api.createMovimiento(any())).thenAnswer((inv) async {
          capturados.add(inv.positionalArguments.first as Map<String, dynamic>);
        });
      });

      await tester.tap(find.byKey(const Key('movimiento_metodo_pago')));
      await tester.pumpAndSettle();
      expect(find.text('Transferencia'), findsWidgets);
      expect(find.text('Tarjeta'), findsNothing);
      await tester.tap(find.text('Transferencia').last);
      await tester.pumpAndSettle();

      await tester.enterText(find.widgetWithText(TextFormField, 'Monto (\$)'), '80');
      await tester.enterText(find.widgetWithText(TextFormField, 'Descripción'), 'Seña');
      await tester.pump();
      await tester.tap(find.widgetWithText(ElevatedButton, 'Guardar'));
      await tester.pumpAndSettle();

      expect(capturados.single['metodoPagoId'], 4);
      expect(capturados.single.containsKey('metodoPago'), isFalse);
    });

    testWidgets('cambiar el tipo a Egreso envía tipo EGRESO con monto '
        'positivo', (WidgetTester tester) async {
      /* CONTRATO VERIFICADO (backend): MovimientoService.crearMovimiento
         persiste dto.monto() tal cual (siempre positivo); el signo se infiere
         del tipo vía MovFinancieroRepository.sumByTipoEnRango. La vista del
         spec ("monto negativo para egresos") es un error de documentación, no
         de código: el frontend envía monto positivo + tipo 'EGRESO'. */
      final capturados = <Map<String, dynamic>>[];
      await _pumpDialog(tester, stub: (api) {
        when(() => api.createMovimiento(any())).thenAnswer((inv) async {
          capturados.add(inv.positionalArguments.first as Map<String, dynamic>);
        });
      });

      await tester.enterText(
          find.widgetWithText(TextFormField, 'Monto (\$)'), '500');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Descripción'), 'Compra insumos');
      await tester.pump();

      await tester.tap(find.text('Ingreso'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Egreso').last);
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ElevatedButton, 'Guardar'));
      await tester.pumpAndSettle();

      expect(capturados, hasLength(1));
      expect(capturados.single['tipo'], 'EGRESO');
      expect(capturados.single['monto'], 500.0);
    });

    testWidgets('éxito del backend cierra el diálogo',
        (WidgetTester tester) async {
      await _pumpDialog(tester, stub: (api) {
        when(() => api.createMovimiento(any())).thenAnswer((_) async {});
      });

      await tester.enterText(
          find.widgetWithText(TextFormField, 'Monto (\$)'), '300');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Descripción'), 'Cobro');
      await tester.pump();

      await tester.tap(find.widgetWithText(ElevatedButton, 'Guardar'));
      await tester.pumpAndSettle();

      expect(find.text('Agregar Nuevo Movimiento'), findsNothing);
    });

    testWidgets('error del backend se muestra limpio y el diálogo queda abierto',
        (WidgetTester tester) async {
      await _pumpDialog(tester, stub: (api) {
        when(() => api.createMovimiento(any()))
            .thenThrow(Exception('No se pudo registrar el movimiento'));
      });

      await tester.enterText(
          find.widgetWithText(TextFormField, 'Monto (\$)'), '999');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Descripción'), 'Intento');
      await tester.pump();

      await tester.tap(find.widgetWithText(ElevatedButton, 'Guardar'));
      await tester.pumpAndSettle();

      expect(find.text('No se pudo registrar el movimiento'), findsOneWidget);
      expect(find.text('Agregar Nuevo Movimiento'), findsOneWidget);
    });
  });

  group('MovimientoFormDialog - categorías según el tipo', () {
    const ingreso = ['Venta', 'Otro ingreso'];
    const egreso = ['Compra', 'Servicios', 'Alquiler', 'Sueldos', 'Otro'];

    /// Abre el dropdown de Categoría (por su valor actual) y devuelve las
    /// opciones visibles en el menú.
    Future<List<String>> opcionesDeCategoria(
        WidgetTester tester, String valorActual) async {
      await tester.tap(find.text(valorActual).last);
      await tester.pumpAndSettle();
      final opciones = [...ingreso, ...egreso]
          .where((o) => find.text(o).evaluate().isNotEmpty)
          .toList();
      // Cierra el menú eligiendo el valor actual.
      await tester.tap(find.text(valorActual).last);
      await tester.pumpAndSettle();
      return opciones;
    }

    Future<void> elegirTipo(WidgetTester tester, String actual, String nuevo) async {
      await tester.tap(find.text(actual));
      await tester.pumpAndSettle();
      await tester.tap(find.text(nuevo).last);
      await tester.pumpAndSettle();
    }

    Future<List<Map<String, dynamic>>> guardar(
        WidgetTester tester, List<Map<String, dynamic>> capturados) async {
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Monto (\$)'), '100');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Descripción'), 'Prueba');
      await tester.pump();
      await tester.tap(find.widgetWithText(ElevatedButton, 'Guardar'));
      await tester.pumpAndSettle();
      return capturados;
    }

    testWidgets('Ingreso ofrece solo Venta y Otro ingreso', (tester) async {
      await _pumpDialog(tester);

      expect(await opcionesDeCategoria(tester, 'Venta'), ingreso);
    });

    testWidgets('al pasar a Egreso la categoría se reinicia a Compra y '
        'ofrece solo las de egreso', (tester) async {
      await _pumpDialog(tester);

      await elegirTipo(tester, 'Ingreso', 'Egreso');

      expect(find.text('Compra'), findsOneWidget);
      expect(await opcionesDeCategoria(tester, 'Compra'), egreso);
    });

    testWidgets('volver a Ingreso reinicia la categoría y envía el código',
        (tester) async {
      final capturados = <Map<String, dynamic>>[];
      await _pumpDialog(tester, stub: (api) {
        when(() => api.createMovimiento(any())).thenAnswer((inv) async {
          capturados.add(inv.positionalArguments.first as Map<String, dynamic>);
        });
      });

      await elegirTipo(tester, 'Ingreso', 'Egreso');
      await tester.tap(find.text('Compra'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sueldos').last);
      await tester.pumpAndSettle();
      await elegirTipo(tester, 'Egreso', 'Ingreso');

      expect(find.text('Sueldos'), findsNothing);
      await guardar(tester, capturados);

      expect(capturados.single['tipo'], 'INGRESO');
      expect(capturados.single['categoria'], 'VENTA');
    });

    testWidgets('Egreso con Sueldos envía tipo EGRESO y categoría SUELDOS',
        (tester) async {
      final capturados = <Map<String, dynamic>>[];
      await _pumpDialog(tester, stub: (api) {
        when(() => api.createMovimiento(any())).thenAnswer((inv) async {
          capturados.add(inv.positionalArguments.first as Map<String, dynamic>);
        });
      });

      await elegirTipo(tester, 'Ingreso', 'Egreso');
      await tester.tap(find.text('Compra'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sueldos').last);
      await tester.pumpAndSettle();
      await guardar(tester, capturados);

      expect(capturados.single['tipo'], 'EGRESO');
      expect(capturados.single['categoria'], 'SUELDOS');
    });
  });
}
