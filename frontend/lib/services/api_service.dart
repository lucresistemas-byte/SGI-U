import 'dart:async';
import 'package:dio/dio.dart';
import '../models/product.dart';

class ApiService {
  late Dio _dio;
  late String baseUrl;
  String? _authToken;

  ApiService() {
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

  // MÉTODO LOGIN CORREGIDO
  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final response = await _dio
          .post('/api/auth/login', data: {
        'username': username,
        'password': password,
      })
          .timeout(const Duration(seconds: 10)); // Timeout adicional por seguridad

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('Credenciales incorrectas');
      }
    } on DioException catch (e) {
      // Capturamos TODOS los errores de conexión, incluido el servidor apagado
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

// NUEVO: POST para crear un producto (BK-5) adaptado para Dio
  Future<Product> createProduct(Map<String, dynamic> productData) async {
    try {
      // Dio ya sabe que tiene que mandarlo como JSON y usa tu baseUrl automáticamente
      final response = await _dio.post(
        '/api/productos',
        data: productData,
      );

      if (response.statusCode == 201) {
        return Product.fromJson(response.data); // Dio ya te devuelve un Map, no hace falta jsonDecode
      } else {
        throw Exception('Error al crear el producto: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) {
        throw Exception('El código de producto ya existe.');
      }
      throw Exception('Error de red al crear el producto: ${e.message}');
    }
  }

  // NUEVO: PUT para editar o archivar un producto (BK-6) adaptado para Dio
  Future<Product> updateProduct(String codigo, Map<String, dynamic> productData) async {
    try {
      final response = await _dio.put(
        '/api/productos/$codigo',
        data: productData,
      );

      if (response.statusCode == 200) {
        return Product.fromJson(response.data);
      } else {
        throw Exception('Error al actualizar el producto: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw Exception('Error de red al actualizar: ${e.message}');
    }
  }
}