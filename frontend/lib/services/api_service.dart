import 'dart:async';
import 'package:dio/dio.dart';
import '../models/product.dart';
import 'package:intl/intl.dart';
class ApiService {
  // --- INICIO DEL FIX: PATRÓN SINGLETON ---
  static final ApiService _instance = ApiService._internal();

  factory ApiService() {
    return _instance;
  }
  // --- FIN DEL FIX ---

  late Dio _dio;
  late String baseUrl;
  String? _authToken;

  // Constructor interno privado
  ApiService._internal() {
    baseUrl = 'http://localhost:3000';
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {'Content-Type': 'application/json'},
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        if (_authToken != null) {
          // Acá se inyecta el token en CADA petición si existe
          options.headers['Authorization'] = 'Bearer $_authToken';
        }
        return handler.next(options);
      },
    ));
  }

  void setAuthToken(String token) {
    _authToken = token;
  }

  void clearAuthToken() {
    _authToken = null;
  }

  /// Update the base URL used by the internal Dio client.
  /// This recreates the Dio instance preserving timeouts, headers and
  /// the authentication behavior (token injection).
  void updateBaseUrl(String newBaseUrl) {
    baseUrl = newBaseUrl;

    // Recreate Dio with the same options but new baseUrl
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {'Content-Type': 'application/json'},
    ));

    // Re-add the auth interceptor so token continues to be injected
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        if (_authToken != null) {
          options.headers['Authorization'] = 'Bearer $_authToken';
        }
        return handler.next(options);
      },
    ));
  }

  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final response = await _dio
          .post('/api/auth/login', data: {
        'username': username,
        'password': password,
      })
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('Credenciales incorrectas');
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError) {
        throw Exception('No se pudo conectar con el servidor. Verifique su conexión.');
      }
      if (e.response?.statusCode == 401) {
        throw Exception('Usuario o contraseña incorrectos');
      }
      throw Exception('Error de conexión: ${e.message}');
    } on TimeoutException {
      throw Exception('Tiempo de espera agotado. El servidor no responde.');
    } catch (e) {
      throw Exception('Error inesperado: $e');
    }
  }

  Future<List<dynamic>> getProducts() async {
    try {
      final response = await _dio.get('/api/productos');
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

  Future<void> createSale(Map<String, dynamic> saleData) async {
    try {
      final response = await _dio.post('/api/ventas', data: saleData);
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

  Future<Product> createProduct(Map<String, dynamic> productData) async {
    try {
      final response = await _dio.post('/api/productos', data: productData);
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
      final response = await _dio.get('/api/finanzas/resumen');
      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('Error al cargar resumen');
      }
    } on DioException catch (e) {
      throw Exception('Error de red: ${e.message}');
    }
  }

  Future<List<dynamic>> getMovimientos({int pagina = 1, int limite = 10}) async {
    try {
      final response = await _dio.get('/api/movimientos', queryParameters: {
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
      final response = await _dio.post('/api/movimientos', data: data);
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
      final response = await _dio.get('/api/balance', queryParameters: {
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
  Future<Product> updateProduct(String codigo, Map<String, dynamic> productData) async {
    try {
      final response = await _dio.put('/api/productos/$codigo', data: productData);
      if (response.statusCode == 200) {
        return Product.fromJson(response.data);
      } else {
        throw Exception('Error al actualizar el producto');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 422) {
        throw Exception('Datos inválidos: verifique el precio o el stock.');
      }
      throw Exception('Error de red al actualizar: ${e.message}');
    }
  }

  Future<Map<String, dynamic>> getDashboardData({
    required DateTime fechaDesde,
    required DateTime fechaHasta,
    String? metodoPago,
    int? productoId,
  }) async {
    // Formateamos las fechas a yyyy-MM-dd como exige el contrato
    final String desdeStr = "${fechaDesde.year}-${fechaDesde.month.toString().padLeft(2, '0')}-${fechaDesde.day.toString().padLeft(2, '0')}";
    final String hastaStr = "${fechaHasta.year}-${fechaHasta.month.toString().padLeft(2, '0')}-${fechaHasta.day.toString().padLeft(2, '0')}";

    try {
      final response = await _dio.get('/api/dashboard', queryParameters: {
        'fechaDesde': desdeStr,
        'fechaHasta': hastaStr,
        // Solo mandamos estos parámetros si el usuario eligió un filtro específico
        if (metodoPago != null && metodoPago != 'Todos') 'metodoPago': metodoPago.toUpperCase(),
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
}