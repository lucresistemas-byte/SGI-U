import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dio/dio.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';

// Clases dummy para validar mocktail
class MockClient extends Mock {}

// BLoC dummy para validar bloc_test
class CounterCubit extends Cubit<int> {
  CounterCubit() : super(0);
  void increment() => emit(state + 1);
}

void main() {
  group('Entorno de Testing Scaffolding (Tarea 1.2)', () {
    test('Mocktail inicializa y mockea correctamente', () {
      final client = MockClient();
      expect(client, isNotNull);
    });

    blocTest<CounterCubit, int>(
      'bloc_test emite los estados esperados',
      build: () => CounterCubit(),
      act: (cubit) => cubit.increment(),
      expect: () => [1],
    );

    test('http_mock_adapter intercepta peticiones Dio con éxito', () async {
      final dio = Dio(BaseOptions(baseUrl: 'http://localhost:3000'));
      final dioAdapter = DioAdapter(dio: dio);

      dioAdapter.onGet('/test', (server) => server.reply(200, {'ok': true}));

      final response = await dio.get('/test');
      expect(response.statusCode, equals(200));
      expect(response.data, equals({'ok': true}));
    });
  });
}
