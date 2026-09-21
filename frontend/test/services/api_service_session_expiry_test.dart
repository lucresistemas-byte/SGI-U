import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sgi_u_frontend/services/api_service.dart';

DioException _error(int statusCode, String path) => DioException(
      requestOptions: RequestOptions(path: path),
      response: Response(
        requestOptions: RequestOptions(path: path),
        statusCode: statusCode,
      ),
    );

void main() {
  test('401 en endpoints operativos (productos, ventas) notifica expiración',
      () {
    expect(
        ApiService.shouldNotifySessionExpired(_error(401, '/api/productos')),
        isTrue);
    expect(
        ApiService.shouldNotifySessionExpired(_error(401, '/api/ventas')),
        isTrue);
  });

  test('401 del login NO notifica expiración (credenciales inválidas)', () {
    expect(
        ApiService.shouldNotifySessionExpired(_error(401, '/api/auth/login')),
        isFalse);
  });

  test('otro código de estado (400) no notifica', () {
    expect(
        ApiService.shouldNotifySessionExpired(_error(400, '/api/productos')),
        isFalse);
  });

  test('error sin respuesta (sin conexión) no notifica', () {
    final connectionError = DioException(
      requestOptions: RequestOptions(path: '/api/productos'),
      type: DioExceptionType.connectionError,
    );
    expect(ApiService.shouldNotifySessionExpired(connectionError), isFalse);
  });
}