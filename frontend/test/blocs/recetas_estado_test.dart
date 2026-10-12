import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sgi_u_frontend/blocs/recetas/recetas_bloc.dart';
import 'package:sgi_u_frontend/blocs/recetas/recetas_event.dart';
import 'package:sgi_u_frontend/blocs/recetas/recetas_state.dart';
import 'package:sgi_u_frontend/models/receta.dart';
import 'package:sgi_u_frontend/models/receta_detalle.dart';
import 'package:sgi_u_frontend/services/api_service.dart';

class _MockApi extends Mock implements ApiService {}

/// E-6: las recetas no se eliminan; se activan/desactivan y, si el producto ya
/// tiene una desactivada, se ofrece reactivarla con los datos cargados.
void main() {
  late _MockApi api;

  const receta = Receta(id: 9, espProductoCodigo: 'T1', nombre: 'Torta base');
  final borrador = RecetasState.initial().copyWith(
    selectedProductoCodigo: 'T1',
    nombre: 'Torta nueva',
    detalles: const [
      RecetaDetalle(materiaPrimaId: 4, cantidad: 0.2, unidadMedida: 'KILO'),
    ],
  );

  setUp(() {
    api = _MockApi();
    registerFallbackValue(<String, dynamic>{});
    when(() => api.getRecetas(incluirInactivas: any(named: 'incluirInactivas')))
        .thenAnswer((_) async => [receta]);
    when(() => api.cambiarEstadoReceta(any(), activo: any(named: 'activo')))
        .thenAnswer((_) async => receta);
    when(() => api.updateReceta(any(), any())).thenAnswer((_) async => receta);
  });

  blocTest<RecetasBloc, RecetasState>(
    'el listado pide también las recetas desactivadas',
    build: () => RecetasBloc(apiService: api),
    act: (b) => b.add(const CargarRecetas()),
    verify: (_) => verify(() => api.getRecetas(incluirInactivas: true)).called(1),
  );

  blocTest<RecetasBloc, RecetasState>(
    'desactivar llama al PATCH de estado y recarga',
    build: () => RecetasBloc(apiService: api),
    act: (b) => b.add(const CambiarEstadoReceta(9, activo: false)),
    wait: const Duration(milliseconds: 10),
    verify: (_) {
      verify(() => api.cambiarEstadoReceta(9, activo: false)).called(1);
      verify(() => api.getRecetas(incluirInactivas: true)).called(1);
    },
  );

  blocTest<RecetasBloc, RecetasState>(
    'crear para un producto con receta desactivada ofrece reactivarla en vez '
    'de mostrar un error',
    build: () {
      when(() => api.createReceta(any())).thenThrow(const ApiException(
        'El producto Torta ya tiene una receta desactivada (Torta base). Puede reactivarla y editarla.',
        codigo: 'RECETA_INACTIVA_EXISTENTE',
        datos: {'recetaId': 9},
      ));
      return RecetasBloc(apiService: api);
    },
    seed: () => borrador,
    act: (b) => b.add(const GuardarReceta()),
    skip: 1,
    expect: () => [
      isA<RecetasState>()
          .having((s) => s.recetaInactivaExistenteId, 'recetaId', 9)
          .having((s) => s.errorMessage, 'sin error', isNull)
          .having((s) => s.isSaving, 'isSaving', false),
    ],
  );

  blocTest<RecetasBloc, RecetasState>(
    'reactivar con datos guarda el borrador en esa receta y la activa',
    build: () => RecetasBloc(apiService: api),
    seed: () => borrador.copyWith(recetaInactivaExistenteId: 9),
    act: (b) => b.add(const ReactivarRecetaConDatos(9)),
    wait: const Duration(milliseconds: 10),
    verify: (b) {
      final payload = verify(() => api.updateReceta(9, captureAny()))
          .captured
          .single as Map<String, dynamic>;
      expect(payload['nombre'], 'Torta nueva');
      verify(() => api.cambiarEstadoReceta(9, activo: true)).called(1);
      expect(b.state.recetaInactivaExistenteId, isNull);
    },
  );
}
