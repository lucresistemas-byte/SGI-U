import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sgi_u_frontend/models/metodo_pago.dart';
import 'package:sgi_u_frontend/screens/dashboard_screen.dart';
import 'package:sgi_u_frontend/services/api_service.dart';

class _MockApi extends Mock implements ApiService {}

/// Parte 2: el filtro del dashboard ofrece los métodos activos de
/// Configuración (antes una lista fija) y envía el id elegido.
void main() {
  setUpAll(() => registerFallbackValue(DateTime(2026)));

  testWidgets('el filtro lista los métodos activos y filtra por id', (t) async {
    t.view.physicalSize = const Size(2400, 1400);
    t.view.devicePixelRatio = 1.0;
    addTearDown(t.view.reset);
    final api = _MockApi();
    when(() => api.getMetodosPago()).thenAnswer((_) async => const [
          MetodoPago(id: 1, nombre: 'Efectivo', fijo: true, orden: 1),
          MetodoPago(id: 6, nombre: 'Cuenta DNI', orden: 2),
        ]);
    when(() => api.getDashboardData(
          fechaDesde: any(named: 'fechaDesde'),
          fechaHasta: any(named: 'fechaHasta'),
          metodoPagoId: any(named: 'metodoPagoId'),
          productoId: any(named: 'productoId'),
        )).thenAnswer((_) async => <String, dynamic>{});

    await t.pumpWidget(MaterialApp(home: DashboardScreen(apiService: api)));
    await t.pumpAndSettle();

    await t.tap(find.byKey(const Key('dashboard_filtro_metodo_pago')));
    await t.pumpAndSettle();
    expect(find.text('Cuenta DNI'), findsWidgets);
    // Ya no está la lista fija de antes.
    expect(find.text('Mercado Pago'), findsNothing);
    await t.tap(find.text('Cuenta DNI').last);
    await t.pumpAndSettle();

    verify(() => api.getDashboardData(
          fechaDesde: any(named: 'fechaDesde'),
          fechaHasta: any(named: 'fechaHasta'),
          metodoPagoId: 6,
          productoId: any(named: 'productoId'),
        )).called(1);
  });
}
