import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sgi_u_frontend/blocs/recetas/recetas_bloc.dart';
import 'package:sgi_u_frontend/blocs/recetas/recetas_event.dart';
import 'package:sgi_u_frontend/blocs/recetas/recetas_state.dart';
import 'package:sgi_u_frontend/models/insumo.dart';
import 'package:sgi_u_frontend/models/receta.dart';
import 'package:sgi_u_frontend/models/unidad_medida.dart';
import 'package:sgi_u_frontend/services/api_service.dart';

class _MockApi extends Mock implements ApiService {}

/// Etapa 2: cada fila tiene su unidad (de la familia del insumo), la receta
/// tiene rinde y se ven costo por porción y precio en vivo.
void main() {
  setUpAll(() => registerFallbackValue(<String, dynamic>{}));

  // Harina comprada por kilo ($1200 el kg), leche por litro ($1500 el l),
  // cinta por metro ($200 el m).
  const harina = Insumo(id: 1, codigo: 'MP-1', nombre: 'Harina', costoUnitario: 1200, unidadMedida: 'KILO', costoUnidadBase: 1.2);
  const leche = Insumo(id: 2, codigo: 'MP-2', nombre: 'Leche', costoUnitario: 1500, unidadMedida: 'LITRO', costoUnidadBase: 1.5);
  const cinta = Insumo(id: 3, codigo: 'INS-1', nombre: 'Cinta', costoUnitario: 200, unidadMedida: 'METRO', costoUnidadBase: 2);

  RecetasBloc bloc([ApiService? api]) => RecetasBloc(apiService: api ?? _MockApi())
    ..emit(RecetasState.initial().copyWith(availableInsumos: const [harina, leche, cinta]));

  blocTest<RecetasBloc, RecetasState>(
    'la fila nueva usa la unidad base; cambiar a kilo recalcula',
    build: bloc,
    act: (b) => b
      ..add(const AgregarFilaInsumo(insumo: harina, cantidad: 200))
      ..add(const ActualizarCantidadFilaInsumo(index: 0, cantidad: 0.2))
      ..add(const CambiarUnidadFila(index: 0, unidad: UnidadMedida.kilo)),
    expect: () => [
      isA<RecetasState>()
          .having((s) => s.detalles.single.unidadMedida, 'unidad', 'GRAMO')
          .having((s) => s.detalles.single.costoUnitario, 'costo por g', closeTo(1.2, 1e-9))
          .having((s) => s.costoTotal, 'total', closeTo(240, 1e-9)),
      isA<RecetasState>().having((s) => s.costoTotal, 'total', closeTo(0.24, 1e-9)),
      isA<RecetasState>()
          .having((s) => s.detalles.single.unidadMedida, 'unidad', 'KILO')
          .having((s) => s.costoTotal, 'total', closeTo(240, 1e-9)),
    ],
  );

  blocTest<RecetasBloc, RecetasState>(
    'una unidad de otra familia no se acepta',
    build: bloc,
    act: (b) => b
      ..add(const AgregarFilaInsumo(insumo: harina, cantidad: 200))
      ..add(const CambiarUnidadFila(index: 0, unidad: UnidadMedida.litro)),
    skip: 1,
    expect: () => [],
  );

  blocTest<RecetasBloc, RecetasState>(
    'unidades mixtas: costo total, costo por porción y precio',
    build: bloc,
    act: (b) => b
      ..add(const AgregarFilaInsumo(insumo: harina, cantidad: 200))
      ..add(const AgregarFilaInsumo(insumo: leche, cantidad: 150))
      ..add(const AgregarFilaInsumo(insumo: cinta, cantidad: 0.5, unidad: UnidadMedida.metro))
      ..add(const CambiarRinde(8))
      ..add(const CambiarModoProductoReceta(productoNuevo: true))
      ..add(const ActualizarProductoNuevoReceta(porcentajeGanancia: 100)),
    skip: 5,
    expect: () => [
      isA<RecetasState>()
          // 200 g × 1,2 + 150 ml × 1,5 + 0,5 m × 200 = 240 + 225 + 100.
          .having((s) => s.costoTotal, 'total', closeTo(565, 1e-9))
          .having((s) => s.costoPorUnidad, 'por porción', closeTo(70.625, 1e-9))
          .having((s) => s.precioResultante, 'precio', closeTo(200, 1e-9)),
    ],
  );

  test('guardar envía unidad por fila, rinde y qué rinde', () async {
    final api = _MockApi();
    when(() => api.createReceta(any())).thenAnswer((_) async => const Receta(espProductoCodigo: 'ELA-1', nombre: 'x'));
    when(() => api.getRecetas()).thenAnswer((_) async => const []);
    final b = bloc(api)
      ..add(const IniciarNuevaReceta(defaultProductoCodigo: 'ELA-1', defaultProductoNombre: 'Torta'))
      ..add(const CambiarNombreReceta('Torta'))
      ..add(const AgregarFilaInsumo(insumo: cinta, cantidad: 0.5, unidad: UnidadMedida.metro))
      ..add(const CambiarRinde(8))
      ..add(const CambiarRindeUnidad('porciones'))
      ..add(const GuardarReceta());
    await pumpEventQueue();

    final payload = verify(() => api.createReceta(captureAny())).captured.single as Map<String, dynamic>;
    expect(payload['rinde'], 8);
    expect(payload['rindeUnidad'], 'porciones');
    expect(payload['detalles'], [
      {'articuloId': 3, 'cantidad': 0.5, 'unidadMedida': 'METRO'}
    ]);
    await b.close();
  });
}
