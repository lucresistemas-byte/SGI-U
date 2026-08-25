import 'package:flutter_test/flutter_test.dart';
import 'package:sgi_u_frontend/services/discovery_service.dart';

/// L6.1 / C.3.4: el descubrimiento mDNS no debe retrasar el arranque de la app.
/// - Debe no exceder ~3-4 s.
/// - No debe lanzar excepciones.
/// - El entorno sí puede tener un servidor mDNS real; el objetivo es que el
///   descubrimiento termine con resultados (o no) sin bloquear ni crashear.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('L6.1 - discoverServices completa dentro de ~3s sin excepciones',
      () async {
    final sw = Stopwatch()..start();

    final List<DiscoveredService> services;
    try {
      services = await DiscoveryService.discoverServices(
        timeout: const Duration(seconds: 3),
      );
    } catch (e) {
      fail('El descubrimiento no debe lanzar excepción: $e');
    }

    sw.stop();

    expect(
      sw.elapsed,
      lessThan(const Duration(seconds: 4)),
      reason: 'El descubrimiento mDNS debe durar máx. ~3 s.',
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

  test('L6.1 - el timeout por defecto no supera los ~4s (arranque ágil)',
      () async {
    final sw = Stopwatch()..start();
    final services = await DiscoveryService.discoverServices();
    sw.stop();
    expect(
      sw.elapsed,
      lessThan(const Duration(milliseconds: 4000)),
      reason: 'El dtimeout por defecto debe ser ~3 s.',
    );
    expect(services, isA<List<DiscoveredService>>());
  }, timeout: const Timeout(Duration(seconds: 8)));
}