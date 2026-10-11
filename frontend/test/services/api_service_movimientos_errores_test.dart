import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:sgi_u_frontend/services/api_service.dart';

/// Los errores de Movimientos y Balance llegan a la pantalla en español y sin
/// el texto técnico de Dio ("DioException ... status code of 500").
void main() {
  late ApiService api;
  late DioAdapter adapter;

  setUp(() {
    api = ApiService();
    api.dio = Dio(BaseOptions(baseUrl: 'http://localhost:3000'));
    adapter = DioAdapter(dio: api.dio);
  });

  Future<String> mensajeDe(Future<void> Function() llamada) async {
    try {
      await llamada();
    } on ApiException catch (e) {
      return e.toString();
    }
    fail('Se esperaba un ApiException');
  }

  void sinTextoTecnico(String mensaje) {
    expect(mensaje, isNot(contains('Dio')));
    expect(mensaje, isNot(contains('status code')));
    expect(mensaje, isNot(startsWith('Exception')));
  }

  test('listado con 500: mensaje genérico en español, no el del backend', () async {
    adapter.onGet('/api/movimientos', (s) => s.reply(500, {
          'error': true,
          'codigo': 'ERROR_DASHBOARD',
          'mensaje': 'No se pudo generar el Dashboard',
        }), queryParameters: {'page': 1, 'limit': 10});

    final mensaje = await mensajeDe(() => api.getMovimientos());

    expect(mensaje, 'No se pudieron cargar los movimientos. Intente nuevamente.');
    sinTextoTecnico(mensaje);
  });

  test('sin conexión: avisa que no se pudo conectar con el servidor', () async {
    adapter.onGet(
        '/api/movimientos',
        (s) => s.throws(
              0,
              DioException.connectionError(
                  requestOptions: RequestOptions(path: '/api/movimientos'),
                  reason: 'Connection refused'),
            ),
        queryParameters: {'page': 1, 'limit': 10});

    final mensaje = await mensajeDe(() => api.getMovimientos());

    expect(mensaje,
        'No se pudo conectar con el servidor. Verifique que esté encendido.');
    sinTextoTecnico(mensaje);
  });

  test('crear con 400: muestra el mensaje que manda el backend', () async {
    adapter.onPost('/api/movimientos',
        (s) => s.reply(400, {'error': 'El monto debe ser mayor a cero.'}),
        data: Matchers.any);

    final mensaje = await mensajeDe(() => api.createMovimiento({'monto': 0}));

    expect(mensaje, 'El monto debe ser mayor a cero.');
  });

  test('balance con 500: mensaje genérico en español', () async {
    adapter.onGet('/api/balance', (s) => s.reply(500, 'Error'),
        queryParameters: {'fechaInicio': '2026-10-01', 'fechaFin': '2026-10-11'});

    final mensaje = await mensajeDe(
        () => api.getBalance(DateTime(2026, 10, 1), DateTime(2026, 10, 11)));

    expect(mensaje, 'No se pudo cargar el balance. Intente nuevamente.');
    sinTextoTecnico(mensaje);
  });
}
