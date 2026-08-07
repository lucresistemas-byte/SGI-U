import 'package:flutter_test/flutter_test.dart';
import 'package:sgi_u_frontend/services/discovery_service.dart';

/// L6.1: el descubrimiento mDNS no debe retrasar el arranque de la app.
/// - Debe no exceder ~4-5 s.
/// - No debe lanzar excepciones.
/// - El entorno sí puede tener un servidor mDNS real; el objetivo es que el
///   descubrimiento termine con resultados (o no) sin bloquear ni crashear.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('L6.1 - discoverServices completa dentro de ~4s sin excepciones',
      () async {
    final sw = Stopwatch()..start();

    final List<DiscoveredService> services;
    try {
      services = await DiscoveryService.discoverServices(
        timeout: const Duration(seconds: 4),
      );
    } catch (e) {
      fail('El descubrimiento no debe lanzar excepción: $e');
    }

    sw.stop();

    expect(
      sw.elapsed,
      lessThan(const Duration(seconds: 5)),
      reason: 'El descubrimiento mDNS debe durar máx. ~4 s.',
    );

    // El mDNS es opcional: puede haber 0 (no hay servidor) o N servicios.
    expect(services, isA<List<DiscoveredService>>());

    // Si descubre servicios, cada uno expone nombre + ip + puerto.
    for (final s in services) {
      expect(s.name, isNotEmpty);
      expect(s.ip, isNotEmpty);
      expect(s.port, greaterThan(0));
    }
  }, timeout: const Timeout(Duration(seconds: 8)));

  test('L6.1 - el timeout por defecto no supera los ~4.5s (arranque ágil)',
      () async {
    final sw = Stopwatch()..start();
    final services = await DiscoveryService.discoverServices();
    sw.stop();
    expect(
      sw.elapsed,
      lessThan(const Duration(milliseconds: 4500)),
      reason: 'El dtimeout por defecto debe ser ~4 s.',
    );
    expect(services, isA<List<DiscoveredService>>());
  }, timeout: const Timeout(Duration(seconds: 8)));
}