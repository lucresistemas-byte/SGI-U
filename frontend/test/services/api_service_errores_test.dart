import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:sgi_u_frontend/services/api_service.dart';

/// E-9: en POS, Insumos, Recetas y Pedidos el usuario ve el mensaje del
/// backend en un 4xx ({"error": "..."}), uno genérico en español en un 5xx y
/// "No se pudo conectar con el servidor" sin conexión. Nunca el texto de Dio.
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
      expect(e.toString(), isNot(contains('Dio')));
      expect(e.toString(), isNot(contains('status code')));
      return e.toString();
    }
    fail('Se esperaba un ApiException');
  }

  final sinConexion = DioException.connectionError(
      requestOptions: RequestOptions(path: '/'), reason: 'Connection refused');

  test('POS: venta con 400 muestra el mensaje del backend', () async {
    adapter.onPost('/api/ventas',
        (s) => s.reply(400, {'error': "Stock insuficiente para 'Torta' (código T1)"}),
        data: Matchers.any);

    expect(await mensajeDe(() => api.createSale({})),
        "Stock insuficiente para 'Torta' (código T1)");
  });

  test('POS: productos con 500 muestra un mensaje genérico', () async {
    adapter.onGet('/api/productos', (s) => s.reply(500, {'error': 'boom'}));

    expect(await mensajeDe(() => api.getProducts()),
        'No se pudieron cargar los productos. Intente nuevamente.');
  });

  test('Insumos: alta con 400 muestra el mensaje del backend (antes buscaba "message")',
      () async {
    adapter.onPost('/api/insumos',
        (s) => s.reply(400, {'error': 'Ya existe un insumo con el código: HAR'}),
        data: Matchers.any);

    expect(await mensajeDe(() => api.createInsumo({})),
        'Ya existe un insumo con el código: HAR');
  });

  test('Insumos: listado sin conexión', () async {
    adapter.onGet('/api/insumos', (s) => s.throws(0, sinConexion));

    expect(await mensajeDe(() => api.getInsumos()),
        'No se pudo conectar con el servidor. Verifique que esté encendido.');
  });

  test('Recetas: alta con 400 muestra el mensaje del backend', () async {
    adapter.onPost('/api/recetas',
        (s) => s.reply(400, {'error': 'El insumo Harina está dos veces en la receta.'}),
        data: Matchers.any);

    expect(await mensajeDe(() => api.createReceta({})),
        'El insumo Harina está dos veces en la receta.');
  });

  test('Pedidos: abono con 400 muestra el mensaje del backend', () async {
    adapter.onPost('/api/pedidos/3/abonar',
        (s) => s.reply(400, {'error': r'El monto a abonar ($5000) excede el saldo pendiente ($4000.00)'}),
        data: Matchers.any);

    expect(await mensajeDe(() => api.abonarPedido(3, monto: 5000)),
        r'El monto a abonar ($5000) excede el saldo pendiente ($4000.00)');
  });

  test('Pedidos: cancelar con 500 muestra un mensaje genérico', () async {
    adapter.onPost('/api/pedidos/3/cancelar', (s) => s.reply(500, 'x'));

    expect(await mensajeDe(() => api.cancelarPedido(3)),
        'No se pudo cancelar el pedido. Intente nuevamente.');
  });
}
