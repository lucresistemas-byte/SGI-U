import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sgi_u_frontend/services/storage_service.dart';

/// Corresponde a L6.2: persistencia sin sobrescribir con valores vacíos.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late StorageService storage;

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    storage = StorageService();
  });

  group('L6.2 - Persistencia de la URL del backend', () {
    test('getBackendUrl devuelve null si no hay nada guardado', () async {
      expect(await storage.getBackendUrl(), isNull);
    });

    test('getBackendUrl devuelve null si guardaron valor vacío (no "" literales)', () async {
      // Simula un valor corrupto guardado directamente.
      await const FlutterSecureStorage().write(key: 'backend_url', value: '');
      expect(await storage.getBackendUrl(), isNull);
    });

    test('saveBackendUrl NO sobreescribe con null', () async {
      await storage.saveBackendUrl('http://192.168.1.10:3000');
      await storage.saveBackendUrl(null);
      expect(await storage.getBackendUrl(), 'http://192.168.1.10:3000');
    });

    test('saveBackendUrl NO sobreescribe con cadena vacía', () async {
      await storage.saveBackendUrl('http://192.168.1.10:3000');
      await storage.saveBackendUrl('');
      expect(await storage.getBackendUrl(), 'http://192.168.1.10:3000');
    });

    test('saveBackendUrl guarda una URL válida', () async {
      await storage.saveBackendUrl('http://192.168.1.20:3000');
      expect(await storage.getBackendUrl(), 'http://192.168.1.20:3000');
    });

    test('saveBackendUrl con solo espacios tampoco se guarda como válida', () async {
      await storage.saveBackendUrl('   ');
      expect(await storage.getBackendUrl(), isNull);
    });
  });

  group('L6.2 - Nombre del servicio', () {
    test('saveBackendServiceName guarda un nombre válido', () async {
      await storage.saveBackendServiceName('_sgiu._tcp.local');
      expect(await storage.getBackendServiceName(), '_sgiu._tcp.local');
    });

    test('saveBackendServiceName vacío BORRA el valor (no deja "")', () async {
      await storage.saveBackendServiceName('_sgiu._tcp.local');
      await storage.saveBackendServiceName('');
      expect(await storage.getBackendServiceName(), isNull);
    });

    test('saveBackendServiceName null BORRA el valor', () async {
      await storage.saveBackendServiceName('_sgiu._tcp.local');
      await storage.saveBackendServiceName(null);
      expect(await storage.getBackendServiceName(), isNull);
    });
  });

  group('L6.2 - clearBackendData', () {
    test('limpia URL y nombre pero NO el token', () async {
      await storage.saveBackendUrl('http://x:3000');
      await storage.saveBackendServiceName('_sgiu._tcp.local');
      await storage.saveToken('abc123');
      await storage.clearBackendData();
      expect(await storage.getBackendUrl(), isNull);
      expect(await storage.getBackendServiceName(), isNull);
      expect(await storage.getToken(), 'abc123');
    });
  });
}