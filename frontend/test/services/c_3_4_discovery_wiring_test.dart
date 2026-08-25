import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sgi_u_frontend/main.dart';
import 'package:sgi_u_frontend/services/api_service.dart';
import 'package:sgi_u_frontend/services/discovery_service.dart';
import 'package:sgi_u_frontend/services/reconnection_service.dart';
import 'package:sgi_u_frontend/services/server_store.dart';
import 'package:sgi_u_frontend/services/storage_service.dart';

/// Adapter de red falso: simula un servidor que responde correctamente.
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

/// Adapter de red falso: simula un servidor que no responde.
class _DeadAdapter implements HttpClientAdapter {
  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    throw DioException(
      requestOptions: options,
      type: DioExceptionType.connectionError,
      message: 'Simulated connection refused',
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

  group('initializeBackendUrl (C.3.9 - ServerStore + TTL)', () {
    test('caché fresca con URL alcanzable: se usa sin descubrir y refresca timestamp',
        () async {
      var fixedNow = DateTime(2026, 8, 25, 10);
      final store = ServerStore(now: () => fixedNow);
      await store.save('http://10.0.0.9:3000');

      // 6 horas después, sigue dentro del TTL de 24h
      fixedNow = DateTime(2026, 8, 25, 16);

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
        serverStore: store,
      );

      expect(discoverCalled, isFalse,
          reason: 'Caché fresca con ping OK no debe discover.');
      expect(api.baseUrl, 'http://10.0.0.9:3000');
      final refreshed = await store.read();
      expect(refreshed!.url, 'http://10.0.0.9:3000');
    });

    test('caché fresca pero URL muerta: cae al descubrimiento y guarda la nueva IP',
        () async {
      var fixedNow = DateTime(2026, 8, 25, 10);
      final store = ServerStore(now: () => fixedNow);
      await store.save('http://10.255.255.1:3000');

      // 2 horas después, sigue fresca
      fixedNow = DateTime(2026, 8, 25, 12);

      final deadDio = Dio(BaseOptions(connectTimeout: const Duration(seconds: 5)))
        ..httpClientAdapter = _DeadAdapter();
      final reconnection = ReconnectionService(
        storageService: storage,
        dio: deadDio,
        discoverFn: () async => [_fakeService(ip: '192.168.1.200')],
      );

      await initializeBackendUrl(
        storageService: storage,
        reconnectionService: reconnection,
        apiService: api,
        serverStore: store,
      );

      expect(api.baseUrl, 'http://192.168.1.200:3000');
      final updated = await store.read();
      expect(updated!.url, 'http://192.168.1.200:3000');
    });

    test('caché expirada (>24h): rediscovery aunque la URL esté en caché',
        () async {
      final fixedNow = DateTime(2026, 8, 25, 10);
      final store = ServerStore(now: () => fixedNow);
      await store.save('http://10.0.0.9:3000');

      // 25 horas después, cache expiró
      final expiredStore = ServerStore(
        now: () => DateTime(2026, 8, 26, 11),
      );
      // Reescribimos la entrada directamente para no cambiar la fecha real
      await FlutterSecureStorage().write(
        key: 'server_cache',
        value:
            '{"url":"http://10.0.0.9:3000","savedAt":"2026-08-25T10:00:00.000"}',
      );

      var discoverCalled = false;
      final reconnection = ReconnectionService(
        storageService: storage,
        discoverFn: () async {
          discoverCalled = true;
          return [_fakeService(ip: '10.0.0.77')];
        },
      );

      await initializeBackendUrl(
        storageService: storage,
        reconnectionService: reconnection,
        apiService: api,
        serverStore: expiredStore,
      );

      expect(discoverCalled, isTrue,
          reason: 'Caché expirada debe ejecutar rediscovery.');
      expect(api.baseUrl, 'http://10.0.0.77:3000');
    });
  });
}
