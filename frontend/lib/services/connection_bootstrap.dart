import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'api_service.dart';
import 'discovery_service.dart';

/// Orquesta el arranque silencioso de la conexión (tarea L2.2).
///
/// Al abrir la app se ejecuta [init] sin mostrar ninguna interfaz:
/// 1. Si hay una IP guardada, prueba conectar rápido y la usa.
/// 2. Si no hay IP o falla la conexión, lanza el descubrimiento mDNS
///    en segundo plano para rescatar la nueva IP y la guarda.
class ConnectionBootstrap {
  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  static const String _ipKey = 'api_base_ip';
  static const int _port = 3000;

  static Future<void> init() async {
    final ApiService api = ApiService();
    try {
      final saved = await _storage.read(key: _ipKey);
      if (saved != null && saved.isNotEmpty) {
        api.updateBaseUrl('http://$saved:$_port');
        if (await api.testConnection()) {
          return;
        }
      }
    } catch (_) {
      // ante cualquier problema de storage, no bloquear el arranque
    }

    await _discoverAndApply(api);
  }

  static Future<void> _discoverAndApply(ApiService api) async {
    try {
      final services = await DiscoveryService.discoverServices();
      if (services.isNotEmpty) {
        final service = services.first;
        api.updateBaseUrl('http://${service.ip}:${service.port}');
        await _storage.write(key: _ipKey, value: service.ip);
      } else {
        // Sin servidor detectado: dejar la URL por defecto.
        api.updateBaseUrl('http://localhost:$_port');
      }
    } catch (_) {
      api.updateBaseUrl('http://localhost:$_port');
    }
  }
}