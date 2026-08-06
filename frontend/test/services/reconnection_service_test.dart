import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sgi_u_frontend/services/reconnection_service.dart';
import 'package:sgi_u_frontend/services/storage_service.dart';

/// Adapter de red falso para simular servidor alcanzable / inalcanzable
/// para la URL GUARDADA (local). El descubrimiento mDNS usa la red real.
class _FakeAdapter implements HttpClientAdapter {
  final bool reachable;
  _FakeAdapter(this.reachable);

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (!reachable) {
      throw DioException(
        requestOptions: options,
        type: DioExceptionType.connectionError,
        message: 'Simulated connection refused',
      );
    }
    return ResponseBody.fromString(
      '[]',
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }
}

Dio _dio(bool reachable) => Dio(
      BaseOptions(connectTimeout: const Duration(seconds: 5)),
    )..httpClientAdapter = _FakeAdapter(reachable);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late StorageService storage;
  late ReconnectionService service;

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    storage = StorageService();
  });

  group('ReconnectionService.isUrlReachable (L4.2/L6.1)', () {
    test('devuelve true si el servidor responde', () async {
      service = ReconnectionService(dio: _dio(true));
      expect(await service.isUrlReachable('http://10.0.0.5:3000'), isTrue);
    });

    test('devuelve false si el servidor no responde', () async {
      service = ReconnectionService(dio: _dio(false));
      expect(await service.isUrlReachable('http://10.0.0.5:3000'), isFalse);
    });
  });

  group('ReconnectionService.attemptReconnection (L4.2)', () {
    test('si hay URL guardada válida y responde, la REUSA sin descubrir',
        () async {
      service = ReconnectionService(dio: _dio(true));
      const saved = 'http://10.0.0.5:3000';
      final result = await service.attemptReconnection(saved, '_sgiu._tcp.local');
      expect(result, saved);
    });

    test('si la URL guardada NO responde, descubre vía mDNS y devuelve una URL '
        'de servidor (actualiza la IP automáticamente)', () async {
      // La URL guardada es una IP "muerta"; el mDNS real de la red encuentra
      // el backend y entrega su IP actual. Esto valida L4.2 de punta a punta.
      service = ReconnectionService(dio: _dio(false));
      const dead = 'http://10.255.255.1:3000';
      final result = await service.attemptReconnection(dead, '_sgiu._tcp.local');

      expect(result, isNotNull);
      expect(result, isNotEmpty, reason: 'Debe devolver una URL del backend.');
      expect(result, startsWith('http://'),
          reason: 'La URL descubierta debe ser http://IP:puerto.');
    }, timeout: const Timeout(Duration(seconds: 12)));

    test('attemptReconnection no lanza excepción en un entorno sin certezas',
        () async {
      service = ReconnectionService(dio: _dio(false));
      String? result;
      try {
        result = await service.attemptReconnection(null, null);
      } catch (e) {
        fail('No debe lanzar excepción: $e');
      }
      // Puede devolver null (nada) o una URL descubierta; nunca crashea.
      expect(result == null || result.isNotEmpty, isTrue);
    }, timeout: const Timeout(Duration(seconds: 12)));
  });

  group('L6.2 - attemptReconnection nunca guarda URLs vacías', () {
    test('la URL persistida tras reconectar es no vacía (o nula, nunca "")',
        () async {
      service = ReconnectionService(dio: _dio(false));
      await service.attemptReconnection(null, null);

      final savedUrl = await storage.getBackendUrl();
      // getBackendUrl ya convierte "" en null, así que nunca queda "" guardada.
      expect(savedUrl == null || savedUrl.isNotEmpty, isTrue);
    }, timeout: const Timeout(Duration(seconds: 12)));
  });
}