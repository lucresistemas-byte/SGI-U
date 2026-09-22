import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sgi_u_frontend/blocs/recetas/recetas_bloc.dart';
import 'package:sgi_u_frontend/blocs/recetas/recetas_event.dart';
import 'package:sgi_u_frontend/blocs/recetas/recetas_state.dart';
import 'package:sgi_u_frontend/models/insumo.dart';

void main() {
  group('RecetasBloc - Cálculo de Costo en Vivo (Tarea 7.5)', () {
    late RecetasBloc recetasBloc;

    const insumoHarina = Insumo(
      id: 1,
      codigo: 'INS-001',
      nombre: 'Harina 000',
      costoUnitario: 50.0,
      unidadMedida: 'KILO',
      stockActual: 100,
    );

    const insumoAzucar = Insumo(
      id: 2,
      codigo: 'INS-002',
      nombre: 'Azúcar',
      costoUnitario: 80.0,
      unidadMedida: 'KILO',
      stockActual: 50,
    );

    const insumoHuevos = Insumo(
      id: 3,
      codigo: 'INS-003',
      nombre: 'Huevos',
      costoUnitario: 25.0,
      unidadMedida: 'UNIDAD',
      stockActual: 200,
    );

    setUp(() {
      recetasBloc = RecetasBloc();
    });

    tearDown(() {
      recetasBloc.close();
    });

    test('Estado inicial tiene costoTotal en 0 y formulario inválido', () {
      expect(recetasBloc.state.costoTotal, equals(0.0));
      expect(recetasBloc.state.detalles, isEmpty);
      expect(recetasBloc.state.isFormValid, isFalse);
    });

    blocTest<RecetasBloc, RecetasState>(
      'Al agregar un insumo, el estado recalcula automáticamente el costo total (cantidad * costoUnitario)',
      build: () => recetasBloc,
      act: (bloc) => bloc.add(const AgregarFilaInsumo(
        insumo: insumoHarina,
        cantidad: 2.5, // 2.5 * 50.0 = 125.0
      )),
      expect: () => [
        isA<RecetasState>()
            .having((s) => s.detalles.length, 'detalles length', 1)
            .having((s) => s.costoTotal, 'costoTotal', 125.0),
      ],
    );

    blocTest<RecetasBloc, RecetasState>(
      'Al agregar múltiples insumos y costos adicionales, el costo total suma todo',
      build: () => recetasBloc,
      act: (bloc) {
        bloc.add(const CambiarCostosAdicionales(30.0)); // +30
        bloc.add(const AgregarFilaInsumo(
          insumo: insumoHarina,
          cantidad: 2.0, // 2 * 50 = 100
        ));
        bloc.add(const AgregarFilaInsumo(
          insumo: insumoAzucar,
          cantidad: 1.0, // 1 * 80 = 80
        ));
      },
      expect: () => [
        isA<RecetasState>()
            .having((s) => s.costosAdicionales, 'costosAdicionales', 30.0)
            .having((s) => s.costoTotal, 'costoTotal', 30.0),
        isA<RecetasState>()
            .having((s) => s.detalles.length, 'detalles length', 1)
            .having((s) => s.costoTotal, 'costoTotal', 130.0),
        isA<RecetasState>()
            .having((s) => s.detalles.length, 'detalles length', 2)
            .having((s) => s.costoTotal, 'costoTotal', 210.0),
      ],
    );

    blocTest<RecetasBloc, RecetasState>(
      'Al quitar un insumo en el armador de recetas, el estado recalcula automáticamente el costo total',
      build: () => recetasBloc,
      seed: () => const RecetasState(
        costosAdicionales: 20.0,
        detalles: [
          // Detalle 0: Harina subtotal 100.0
          // Detalle 1: Azúcar subtotal 80.0
        ],
        costoTotal: 20.0,
      ),
      act: (bloc) {
        bloc.add(const AgregarFilaInsumo(insumo: insumoHarina, cantidad: 2.0)); // +100 -> 120
        bloc.add(const AgregarFilaInsumo(insumo: insumoAzucar, cantidad: 1.0)); // +80  -> 200
        bloc.add(const RemoverFilaInsumo(0)); // remueve Harina (100) -> queda 100 (80 + 20)
      },
      expect: () => [
        isA<RecetasState>()
            .having((s) => s.detalles.length, 'detalles length', 1)
            .having((s) => s.costoTotal, 'costoTotal', 120.0),
        isA<RecetasState>()
            .having((s) => s.detalles.length, 'detalles length', 2)
            .having((s) => s.costoTotal, 'costoTotal', 200.0),
        isA<RecetasState>()
            .having((s) => s.detalles.length, 'detalles length', 1)
            .having((s) => s.detalles.first.materiaPrimaId, 'materiaPrimaId restante', 2)
            .having((s) => s.costoTotal, 'costoTotal recalculado', 100.0),
      ],
    );

    blocTest<RecetasBloc, RecetasState>(
      'Al modificar la cantidad de un insumo, el subtotal y el costo total se actualizan en vivo',
      build: () => recetasBloc,
      act: (bloc) {
        bloc.add(const AgregarFilaInsumo(insumo: insumoHuevos, cantidad: 4.0)); // 4 * 25 = 100
        bloc.add(const ActualizarCantidadFilaInsumo(index: 0, cantidad: 10.0)); // 10 * 25 = 250
      },
      expect: () => [
        isA<RecetasState>()
            .having((s) => s.costoTotal, 'costoTotal', 100.0),
        isA<RecetasState>()
            .having((s) => s.detalles.first.cantidad, 'cantidad actualizada', 10.0)
            .having((s) => s.detalles.first.subtotal, 'subtotal', 250.0)
            .having((s) => s.costoTotal, 'costoTotal', 250.0),
      ],
    );

    test('isFormValid valida campos obligatorios del armador de recetas', () async {
      var state = RecetasState.initial();
      expect(state.isFormValid, isFalse, reason: 'Vacío debe ser inválido');

      state = state.copyWith(selectedProductoCodigo: 'PROD-001');
      expect(state.isFormValid, isFalse, reason: 'Falta nombre y detalles');

      state = state.copyWith(nombre: 'Torta de Chocolate');
      expect(state.isFormValid, isFalse, reason: 'Faltan detalles');

      state = state.copyWith(
        detalles: const [],
      );
      expect(state.isFormValid, isFalse);

      const detalle = insumoHarina;
      recetasBloc.add(const CambiarProductoReceta(codigo: 'PROD-001', nombre: 'Torta'));
      recetasBloc.add(const CambiarNombreReceta('Torta Especial'));
      recetasBloc.add(const AgregarFilaInsumo(insumo: detalle, cantidad: 2.0));
      await pumpEventQueue();

      expect(recetasBloc.state.selectedProductoCodigo, equals('PROD-001'));
      expect(recetasBloc.state.nombre, equals('Torta Especial'));
      expect(recetasBloc.state.detalles.length, equals(1));
      expect(recetasBloc.state.isFormValid, isTrue);
    });
  });
}
