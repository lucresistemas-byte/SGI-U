import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:sgi_u_frontend/models/configuracion_negocio.dart';
import 'package:sgi_u_frontend/services/api_service.dart';

void main() {
  late ApiService apiService;
  late DioAdapter dioAdapter;

  // 1x1 PNG en Base64 para simular un logo real
  const base64Png =
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=';
  final sampleLogoBytes = base64Decode(base64Png);

  setUp(() {
    apiService = ApiService();
    // Reemplazar Dio con uno aislado para el test
    apiService.dio = Dio(BaseOptions(
      baseUrl: 'http://localhost:3000',
      headers: {'Content-Type': 'application/json'},
    ));
    dioAdapter = DioAdapter(dio: apiService.dio);
  });

  tearDown(() {
    ApiService.configuracionActual = null;
  });

  group('ApiService - Configuración del Negocio (Tarea 6.3)', () {
    test('getConfiguracion realiza GET /api/configuracion y mapea datos y logo', () async {
      final jsonResponse = {
        'nombre': 'Almacén Don Mario',
        'codigoCliente': 'SGIU-CLI-777',
        'logo': base64Png,
        'direccion': 'Av. Belgrano 450',
        'telefono': '+54 11 4444-5555',
        'descripcion': 'Atención de calidad',
      };

      dioAdapter.onGet(
        '/api/configuracion',
        (server) => server.reply(200, jsonResponse),
      );

      final config = await apiService.getConfiguracion();

      expect(config.nombre, equals('Almacén Don Mario'));
      expect(config.codigoCliente, equals('SGIU-CLI-777'));
      expect(config.direccion, equals('Av. Belgrano 450'));
      expect(config.telefono, equals('+54 11 4444-5555'));
      expect(config.descripcion, equals('Atención de calidad'));
      expect(config.logo, isNotNull);
      expect(config.logo, equals(sampleLogoBytes));

      // Comprobar que se guardó en cache singleton
      expect(ApiService.configuracionActual?.nombre, equals('Almacén Don Mario'));
    });

    test('saveConfiguracion realiza PUT /api/configuracion con payload y actualiza cache', () async {
      final configInput = ConfiguracionNegocio(
        nombre: 'Almacén Don Mario Renovado',
        direccion: 'Calle Nueva 100',
        telefono: '11223344',
        logo: sampleLogoBytes,
      );

      final jsonResponse = {
        'nombre': 'Almacén Don Mario Renovado',
        'codigoCliente': 'SGIU-CLI-777',
        'logo': base64Png,
        'direccion': 'Calle Nueva 100',
        'telefono': '11223344',
        'descripcion': null,
      };

      dioAdapter.onPut(
        '/api/configuracion',
        (server) => server.reply(200, jsonResponse),
        data: configInput.toJson(),
      );

      final configResult = await apiService.saveConfiguracion(configInput);

      expect(configResult.nombre, equals('Almacén Don Mario Renovado'));
      expect(configResult.direccion, equals('Calle Nueva 100'));
      expect(configResult.logo, equals(sampleLogoBytes));
      expect(ApiService.configuracionActual?.nombre, equals('Almacén Don Mario Renovado'));
    });

    test('getConfiguracion lanza excepción ante error de servidor (500)', () async {
      dioAdapter.onGet(
        '/api/configuracion',
        (server) => server.reply(500, {'error': 'Internal server error'}),
      );

      expect(
        () async => await apiService.getConfiguracion(),
        throwsA(isA<Exception>()),
      );
    });
  });
}
