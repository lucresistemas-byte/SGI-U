import 'dart:async';
import 'package:dio/dio.dart';
import '../models/product.dart';
import '../models/configuracion_negocio.dart';
import '../models/insumo.dart';
import '../models/receta.dart';
import '../models/pedido.dart';
import 'package:intl/intl.dart';

/// Contrato de operaciones POS/productos usado por PosBloc.
/// Permite inyectar una implementación falsa en los tests.
abstract interface class PosApi {
  Future<List<dynamic>> getProducts();
  Future<void> createSale(Map<String, dynamic> saleData);
  Future<Product> createProduct(Map<String, dynamic> productData);
  Future<Product> updateProduct(String codigo, Map<String, dynamic> productData);
  Future<Product> ajustarStock(String codigo,
      {required int cantidad, required String motivo});
}

class ApiService implements PosApi {
  // --- INICIO DEL FIX: PATRÓN SINGLETON ---
  static final ApiService _instance = ApiService._internal();

  factory ApiService() {
    return _instance;
  }
  // --- FIN DEL FIX ---

  late Dio dio;
  late String baseUrl;
  String? _authToken;

  /// Callback invocado cuando una petición (que no sea /api/auth/login)
  /// responde 401: el backend informa sesión expirada/credenciales inválidas.
  void Function()? onSessionExpired;
  bool _sessionExpiredNotified = false;

  // Constructor interno privado
  ApiService._internal() {
    baseUrl = 'http://localhost:3000';
    dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {'Content-Type': 'application/json'},
    ));

    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        if (_authToken != null) {
          // Acá se inyecta el token en CADA petición si existe
          options.headers['Authorization'] = 'Bearer $_authToken';
        }
        return handler.next(options);
      },
      onError: (error, handler) {
        if (shouldNotifySessionExpired(error)) {
          if (!_sessionExpiredNotified) {
            _sessionExpiredNotified = true;
            onSessionExpired?.call();
          }
        }
        return handler.next(error);
      },
    ));
  }

  /// Predicado puro: una respuesta 401 de un endpoint distinto al login
  /// indica que la sesión expiró (el login maneja su propio error).
  static bool shouldNotifySessionExpired(DioException error) {
    if (error.response?.statusCode != 401) return false;
    return !error.requestOptions.path.contains('/api/auth/login');
  }

  void setAuthToken(String token) {
    _authToken = token;
    _sessionExpiredNotified = false;
  }

  void clearAuthToken() {
    _authToken = null;
    _sessionExpiredNotified = false;
  }

  /// C.3.4: actualiza la URL base usada por el cliente Dio interno.
  /// Preserva timeouts, headers y la inyección del token de autenticación.
  void setBaseUrl(String newBaseUrl) {
    baseUrl = newBaseUrl;
    dio.options.baseUrl = newBaseUrl;
  }

  /// URL base efectiva del cliente Dio interno (útil para diagnóstico/tests).
  String get effectiveBaseUrl => dio.options.baseUrl;


  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final response = await dio.post('/api/auth/login', data: {
        'username': username,
        'password': password,
      }).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('Credenciales incorrectas');
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError) {
        throw Exception(
            'No se pudo conectar con el servidor. Verifique su conexión.');
      }

      // El backend informa el motivo en el body con status 400:
      // {"error": "Credenciales incorrectas"} / {"error": "Usuario no encontrado"}
      final data = e.response?.data;
      if (data is Map &&
          data['error'] is String &&
          (data['error'] as String).isNotEmpty) {
        throw Exception(data['error']);
      }

      // Fallback por código de estado si el body no trae mensaje útil
      final status = e.response?.statusCode;
      if (status == 400 || status == 401 || status == 403) {
        throw Exception('Credenciales incorrectas');
      }

      throw Exception('Error de conexión: ${e.message}');
    } on TimeoutException {
      throw Exception('Tiempo de espera agotado. El servidor no responde.');
    } catch (e) {
      throw Exception('Error inesperado: $e');
    }
  }

  @override
  Future<List<dynamic>> getProducts() async {
    try {
      final response = await dio.get('/api/productos');
      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('Error al cargar productos');
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError) {
        throw Exception('Error de conexión. Verifique su red.');
      }
      throw Exception('Error al cargar productos: ${e.message}');
    }
  }

  @override
  Future<void> createSale(Map<String, dynamic> saleData) async {
    try {
      final response = await dio.post('/api/ventas', data: saleData);
      if (response.statusCode == 201) {
        return;
      } else {
        throw Exception('Error al procesar la venta');
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError) {
        throw Exception('Error de conexión. Verifique su red.');
      }
      if (e.response?.statusCode == 400) {
        throw Exception('Error al procesar la venta');
      }
      throw Exception('Error al procesar la venta: ${e.message}');
    }
  }

  @override
  Future<Product> createProduct(Map<String, dynamic> productData) async {
    try {
      final response = await dio.post('/api/productos/crear', data: productData);
      if (response.statusCode == 201) {
        return Product.fromJson(response.data);
      } else {
        throw Exception('Error al crear el producto');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) {
        throw Exception('El código de producto ya existe.');
      }
      throw Exception('Error de red al crear el producto: ${e.message}');
    }
  }
// dentro de ApiService

  Future<Map<String, dynamic>> getResumenFinanciero() async {
    try {
      final response = await dio.get('/api/finanzas/resumen');
      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('Error al cargar resumen');
      }
    } on DioException catch (e) {
      throw Exception('Error de red: ${e.message}');
    }
  }

  Future<List<dynamic>> getMovimientos(
      {int pagina = 1, int limite = 10}) async {
    try {
      final response = await dio.get('/api/movimientos', queryParameters: {
        'page': pagina,
        'limit': limite,
      });
      if (response.statusCode == 200) {
        // Ahora devolvemos directamente la lista que manda el backend
        return response.data as List<dynamic>;
      } else {
        throw Exception('Error al cargar movimientos');
      }
    } on DioException catch (e) {
      throw Exception('Error de red: ${e.message}');
    }
  }

  Future<void> createMovimiento(Map<String, dynamic> data) async {
    try {
      final response = await dio.post('/api/movimientos', data: data);
      if (response.statusCode != 201) {
        throw Exception('Error al crear movimiento');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        throw Exception('Datos inválidos: ${e.response?.data['message']}');
      }
      throw Exception('Error de conexión');
    }
  }

  Future<Map<String, dynamic>> getBalance(DateTime inicio, DateTime fin) async {
    try {
      final response = await dio.get('/api/balance', queryParameters: {
        // CUIDADO ACÁ: Tienen que llamarse igual que en el BalanceController de Java
        'fechaInicio': DateFormat('yyyy-MM-dd').format(inicio),
        'fechaFin': DateFormat('yyyy-MM-dd').format(fin),
      });
      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('Error al cargar balance');
      }
    } on DioException catch (e) {
      throw Exception('Error de red: ${e.message}');
    }
  }

  @override
  Future<Product> updateProduct(
      String codigo, Map<String, dynamic> productData) async {
    try {
      final response =
          await dio.put('/api/productos/editar/$codigo', data: productData);
      if (response.statusCode == 200) {
        return Product.fromJson(response.data);
      } else {
        throw Exception('Error al actualizar el producto');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 422 || e.response?.statusCode == 400) {
        throw Exception('Datos inválidos: verifique el precio o el stock.');
      }
      throw Exception('Error de red al actualizar: ${e.message}');
    }
  }

  /// Ajusta el stock de un producto usando el endpoint dedicado del backend.
  /// [cantidad] es un delta: positivo suma, negativo resta.
  /// Devuelve el producto actualizado (con el stock resultante).
  @override
  Future<Product> ajustarStock(String codigo,
      {required int cantidad, required String motivo}) async {
    try {
      final response = await dio.put('/api/productos/stock/$codigo', data: {
        'cantidad': cantidad,
        'motivo': motivo,
      });
      if (response.statusCode == 200) {
        return Product.fromJson(response.data);
      } else {
        throw Exception('Error al ajustar el stock');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 422 || e.response?.statusCode == 400) {
        final data = e.response?.data;
        if (data is Map && data['error'] is String) {
          throw Exception(data['error']);
        }
        throw Exception('Datos inválidos al ajustar el stock.');
      }
      throw Exception('Error de red al ajustar el stock: ${e.message}');
    }
  }

  Future<Map<String, dynamic>> getDashboardData({
    required DateTime fechaDesde,
    required DateTime fechaHasta,
    String? metodoPago,
    int? productoId,
  }) async {
    // Formateamos las fechas a yyyy-MM-dd como exige el contrato
    final String desdeStr =
        "${fechaDesde.year}-${fechaDesde.month.toString().padLeft(2, '0')}-${fechaDesde.day.toString().padLeft(2, '0')}";
    final String hastaStr =
        "${fechaHasta.year}-${fechaHasta.month.toString().padLeft(2, '0')}-${fechaHasta.day.toString().padLeft(2, '0')}";

    try {
      final response = await dio.get('/api/dashboard', queryParameters: {
        'fechaDesde': desdeStr,
        'fechaHasta': hastaStr,
        // Solo mandamos estos parámetros si el usuario eligió un filtro específico
        if (metodoPago != null && metodoPago != 'Todos')
          'metodoPago': metodoPago.toUpperCase(),
        if (productoId != null) 'productoId': productoId,
      });

      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      } else {
        throw Exception('Error al cargar el dashboard');
      }
    } on DioException catch (e) {
      throw Exception('Error de red: ${e.message}');
    }
  }

  static ConfiguracionNegocio? configuracionActual;

  Future<ConfiguracionNegocio> getConfiguracion() async {
    try {
      final response = await dio.get('/api/configuracion');
      if (response.statusCode == 200) {
        final config = ConfiguracionNegocio.fromJson(
            response.data as Map<String, dynamic>);
        configuracionActual = config;
        return config;
      } else {
        throw Exception('Error al cargar configuración');
      }
    } on DioException catch (e) {
      throw Exception('Error de red: ${e.message}');
    }
  }

  Future<ConfiguracionNegocio> saveConfiguracion(ConfiguracionNegocio config) async {
    try {
      final response =
          await dio.put('/api/configuracion', data: config.toJson());
      if (response.statusCode == 200) {
        final saved = ConfiguracionNegocio.fromJson(
            response.data as Map<String, dynamic>);
        configuracionActual = saved;
        return saved;
      } else {
        throw Exception('Error al guardar configuración');
      }
    } on DioException catch (e) {
      throw Exception('Error de red: ${e.message}');
    }
  }

  // --- INSUMOS (MATERIA PRIMA) ---
  Future<List<Insumo>> getInsumos() async {
    try {
      final response = await dio.get('/api/insumos');
      if (response.statusCode == 200) {
        final List list = response.data as List;
        return list.map((item) => Insumo.fromJson(item as Map<String, dynamic>)).toList();
      } else {
        throw Exception('Error al obtener insumos');
      }
    } on DioException catch (e) {
      throw Exception('Error de red: ${e.message}');
    }
  }

  Future<Insumo> createInsumo(Map<String, dynamic> data) async {
    try {
      final response = await dio.post('/api/insumos', data: data);
      if (response.statusCode == 201) {
        return Insumo.fromJson(response.data as Map<String, dynamic>);
      } else {
        throw Exception('Error al crear insumo');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 400 || e.response?.statusCode == 422) {
        final body = e.response?.data;
        if (body is Map && body['message'] != null) {
          throw Exception(body['message']);
        }
      }
      throw Exception('Error al crear insumo: ${e.message}');
    }
  }

  Future<Insumo> updateInsumo(int id, Map<String, dynamic> data) async {
    try {
      final response = await dio.put('/api/insumos/$id', data: data);
      if (response.statusCode == 200) {
        return Insumo.fromJson(response.data as Map<String, dynamic>);
      } else {
        throw Exception('Error al actualizar insumo');
      }
    } on DioException catch (e) {
      throw Exception('Error de red: ${e.message}');
    }
  }

  Future<Insumo> ajustarStockInsumo(int id, {required int cantidad, required String motivo}) async {
    try {
      final response = await dio.post(
        '/api/insumos/$id/ajuste-stock',
        data: {'cantidad': cantidad, 'motivo': motivo},
      );
      if (response.statusCode == 200) {
        return Insumo.fromJson(response.data as Map<String, dynamic>);
      } else {
        throw Exception('Error al ajustar stock de insumo');
      }
    } on DioException catch (e) {
      throw Exception('Error de red: ${e.message}');
    }
  }

  // --- RECETAS ---
  Future<List<Receta>> getRecetas() async {
    try {
      final response = await dio.get('/api/recetas');
      if (response.statusCode == 200) {
        final List list = response.data as List;
        return list.map((item) => Receta.fromJson(item as Map<String, dynamic>)).toList();
      } else {
        throw Exception('Error al obtener recetas');
      }
    } on DioException catch (e) {
      throw Exception('Error de red: ${e.message}');
    }
  }

  Future<Receta?> getRecetaByProducto(String codigo) async {
    try {
      final response = await dio.get('/api/recetas/producto/$codigo');
      if (response.statusCode == 200) {
        return Receta.fromJson(response.data as Map<String, dynamic>);
      }
      return null;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      throw Exception('Error de red: ${e.message}');
    }
  }

  Future<Receta> createReceta(Map<String, dynamic> data) async {
    try {
      final response = await dio.post('/api/recetas', data: data);
      if (response.statusCode == 201) {
        return Receta.fromJson(response.data as Map<String, dynamic>);
      } else {
        throw Exception('Error al crear receta');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 400 || e.response?.statusCode == 422) {
        final body = e.response?.data;
        if (body is Map && body['message'] != null) {
          throw Exception(body['message']);
        }
      }
      throw Exception('Error al crear receta: ${e.message}');
    }
  }

  Future<Receta> updateReceta(int id, Map<String, dynamic> data) async {
    try {
      final response = await dio.put('/api/recetas/$id', data: data);
      if (response.statusCode == 200) {
        return Receta.fromJson(response.data as Map<String, dynamic>);
      } else {
        throw Exception('Error al actualizar receta');
      }
    } on DioException catch (e) {
      throw Exception('Error de red: ${e.message}');
    }
  }

  Future<void> deleteReceta(int id) async {
    try {
      final response = await dio.delete('/api/recetas/$id');
      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Error al eliminar receta');
      }
    } on DioException catch (e) {
      throw Exception('Error de red: ${e.message}');
    }
  }

  // --- PEDIDOS CON SEÑA ---
  Future<List<Pedido>> getPedidos({String? query}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (query != null && query.trim().isNotEmpty) {
        queryParams['q'] = query.trim();
      }
      final response = await dio.get('/api/pedidos', queryParameters: queryParams);
      if (response.statusCode == 200) {
        final List list = response.data as List;
        return list.map((item) => Pedido.fromJson(item as Map<String, dynamic>)).toList();
      } else {
        throw Exception('Error al obtener pedidos');
      }
    } on DioException catch (e) {
      throw Exception('Error de red: ${e.message}');
    }
  }

  Future<Pedido> getPedidoById(int id) async {
    try {
      final response = await dio.get('/api/pedidos/$id');
      if (response.statusCode == 200) {
        return Pedido.fromJson(response.data as Map<String, dynamic>);
      } else {
        throw Exception('Error al obtener pedido');
      }
    } on DioException catch (e) {
      throw Exception('Error de red: ${e.message}');
    }
  }

  Future<Pedido> createPedido(Map<String, dynamic> data) async {
    try {
      final response = await dio.post('/api/pedidos', data: data);
      if (response.statusCode == 201) {
        return Pedido.fromJson(response.data as Map<String, dynamic>);
      } else {
        throw Exception('Error al crear pedido');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 400 || e.response?.statusCode == 422) {
        final body = e.response?.data;
        if (body is Map && body['message'] != null) {
          throw Exception(body['message']);
        }
      }
      throw Exception('Error al crear pedido: ${e.message}');
    }
  }

  Future<Pedido> abonarPedido(
    int id, {
    required double monto,
    String? metodoPago,
    String? nota,
  }) async {
    try {
      final payload = {
        'monto': monto,
        if (metodoPago != null) 'metodoPago': metodoPago,
        if (nota != null) 'nota': nota,
      };
      final response = await dio.post('/api/pedidos/$id/abonar', data: payload);
      if (response.statusCode == 200) {
        return Pedido.fromJson(response.data as Map<String, dynamic>);
      } else {
        throw Exception('Error al abonar pedido');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 400 || e.response?.statusCode == 422) {
        final body = e.response?.data;
        if (body is Map && body['message'] != null) {
          throw Exception(body['message']);
        }
      }
      throw Exception('Error al abonar pedido: ${e.message}');
    }
  }

  Future<Pedido> cancelarPedido(int id) async {
    try {
      final response = await dio.post('/api/pedidos/$id/cancelar');
      if (response.statusCode == 200) {
        return Pedido.fromJson(response.data as Map<String, dynamic>);
      } else {
        throw Exception('Error al cancelar pedido');
      }
    } on DioException catch (e) {
      throw Exception('Error de red: ${e.message}');
    }
  }
}
