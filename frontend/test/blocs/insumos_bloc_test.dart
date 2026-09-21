import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sgi_u_frontend/blocs/insumos/insumos_bloc.dart';
import 'package:sgi_u_frontend/blocs/insumos/insumos_event.dart';
import 'package:sgi_u_frontend/blocs/insumos/insumos_state.dart';
import 'package:sgi_u_frontend/models/insumo.dart';
import 'package:sgi_u_frontend/services/api_service.dart';

class MockApiService extends Mock implements ApiService {}

void main() {
  group('InsumosBloc - Gestión de Materia Prima (Tarea 7.5)', () {
    late MockApiService mockApiService;
    late InsumosBloc insumosBloc;

    final testInsumos = [
      const Insumo(
        id: 1,
        codigo: 'INS-001',
        nombre: 'Harina Leudante',
        costoUnitario: 120.0,
        unidadMedida: 'KILO',
        stockActual: 50,
      ),
      const Insumo(
        id: 2,
        codigo: 'INS-002',
        nombre: 'Cacao en Polvo',
        costoUnitario: 350.0,
        unidadMedida: 'GRAMO',
        stockActual: 1000,
      ),
    ];

    setUp(() {
      mockApiService = MockApiService();
      insumosBloc = InsumosBloc(apiService: mockApiService);
    });

    tearDown(() {
      insumosBloc.close();
    });

    test('Estado inicial es InsumosInitial', () {
      expect(insumosBloc.state, isA<InsumosInitial>());
    });

    blocTest<InsumosBloc, InsumosState>(
      'CargarInsumos emite [InsumosLoading, InsumosLoaded] exitosamente',
      build: () {
        when(() => mockApiService.getInsumos()).thenAnswer((_) async => testInsumos);
        return insumosBloc;
      },
      act: (bloc) => bloc.add(const CargarInsumos()),
      expect: () => [
        isA<InsumosLoading>(),
        isA<InsumosLoaded>().having((s) => s.insumos.length, 'insumos count', 2),
      ],
      verify: (_) {
        verify(() => mockApiService.getInsumos()).called(1);
      },
    );

    blocTest<InsumosBloc, InsumosState>(
      'FiltrarInsumos filtra correctamente por texto insensible a mayúsculas',
      build: () => insumosBloc,
      seed: () => InsumosLoaded(insumos: testInsumos),
      act: (bloc) => bloc.add(const FiltrarInsumos('cacao')),
      expect: () => [
        isA<InsumosLoaded>()
            .having((s) => s.filteredInsumos.length, 'filtered count', 1)
            .having((s) => s.filteredInsumos.first.nombre, 'primer item', 'Cacao en Polvo'),
      ],
    );

    blocTest<InsumosBloc, InsumosState>(
      'CrearInsumoEvent llama al servicio y recarga la lista',
      build: () {
        when(() => mockApiService.createInsumo(any())).thenAnswer(
          (_) async => testInsumos.first,
        );
        when(() => mockApiService.getInsumos()).thenAnswer((_) async => testInsumos);
        return insumosBloc;
      },
      act: (bloc) => bloc.add(const CrearInsumoEvent({
        'codigo': 'INS-001',
        'nombre': 'Harina Leudante',
        'costoUnitario': 120.0,
      })),
      expect: () => [
        isA<InsumosLoading>(),
        isA<InsumoOperacionExitosa>(),
        isA<InsumosLoading>(),
        isA<InsumosLoaded>(),
      ],
      verify: (_) {
        verify(() => mockApiService.createInsumo(any())).called(1);
      },
    );
  });
}
