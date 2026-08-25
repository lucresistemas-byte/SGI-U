import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sgi_u_frontend/main.dart';
import 'package:sgi_u_frontend/services/api_service.dart';
import 'package:sgi_u_frontend/services/discovery_service.dart';
import 'package:sgi_u_frontend/services/reconnection_service.dart';
import 'package:sgi_u_frontend/services/storage_service.dart';

/// Adapter de red falso: simula un servidor que responde correctamente.
/// Sirve para validar que una URL guardada alcanzable tiene prioridad
/// sobre el descubrimiento mDNS.
class _ReachableAdapter implements HttpClientAdapter {
  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody.fromString(
      '[]',
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }
}

DiscoveredService _fakeService({String ip = '192.168.1.77'}) =>
    DiscoveredService(name: '_sgiu._tcp.local', ip: ip, port: 3000);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late StorageService storage;
  late ApiService api;

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    storage = StorageService();
    api = ApiService();
  });

  group('ApiService.setBaseUrl (C.3.4)', () {
    test('actualiza el campo publico y la baseUrl del Dio interno', () {
      expect(api.baseUrl, 'http://localhost:3000');

      api.setBaseUrl('http://192.168.1.50:8080');

      expect(api.baseUrl, 'http://192.168.1.50:8080');
      expect(api.effectiveBaseUrl, 'http://192.168.1.50:8080');
    });
  });

  group('initializeBackendUrl (C.3.4 - cableado de arranque con mocks)', () {
    test(
        'descubre el backend via mock y llama a setBaseUrl con la IP encontrada',
        () async {
      final reconnection = ReconnectionService(
        storageService: storage,
        discoverFn: () async => [_fakeService(ip: '10.0.0.42')],
      );

      await initializeBackendUrl(
        storageService: storage,
        reconnectionService: reconnection,
        apiService: api,
      );

      expect(api.baseUrl, 'http://10.0.0.42:3000');
      expect(api.effectiveBaseUrl, 'http://10.0.0.42:3000');
      // La URL descubierta queda persistida para proximos arranques (L4.2).
      expect(await storage.getBackendUrl(), 'http://10.0.0.42:3000');
    });

    test('sin URL guardada y sin servicios descubiertos conserva el default',
        () async {
      api.setBaseUrl('http://localhost:3000'); // estado conocido del singleton

      final reconnection = ReconnectionService(
        storageService: storage,
        discoverFn: () async => [],
      );

      await initializeBackendUrl(
        storageService: storage,
        reconnectionService: reconnection,
        apiService: api,
      );

      expect(api.baseUrl, 'http://localhost:3000');
    });

    test('si la URL guardada responde, se reutiliza y NO se descubre',
        () async {
      const saved = 'http://10.0.0.5:3000';
      await storage.saveBackendUrl(saved);

      var discoverCalled = false;
      final dio = Dio(BaseOptions(connectTimeout: const Duration(seconds: 5)))
        ..httpClientAdapter = _ReachableAdapter();
      final reconnection = ReconnectionService(
        storageService: storage,
        dio: dio,
        discoverFn: () async {
          discoverCalled = true;
          return [_fakeService()];
        },
      );

      await initializeBackendUrl(
        storageService: storage,
        reconnectionService: reconnection,
        apiService: api,
      );

      expect(discoverCalled, isFalse,
          reason: 'Con URL alcanzable no debe ejecutarse el descubrimiento.');
      expect(api.baseUrl, saved);
    });
  });
}
