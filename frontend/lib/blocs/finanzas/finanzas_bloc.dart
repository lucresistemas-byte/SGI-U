// lib/blocs/finanzas/finanzas_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'finanzas_event.dart';
import 'finanzas_state.dart';
import '../../services/api_service.dart';

class FinanzasBloc extends Bloc<FinanzasEvent, FinanzasState> {
  final ApiService _apiService = ApiService();

  FinanzasBloc() : super(FinanzasInitial()) {
    on<CargarResumen>(_onCargarResumen);
    on<CargarMovimientos>(_onCargarMovimientos);
    on<CrearMovimiento>(_onCrearMovimiento);
    on<CargarBalance>(_onCargarBalance);
  }

  Future<void> _onCargarResumen(
      CargarResumen event, Emitter<FinanzasState> emit) async {
    emit(ResumenLoading());
    try {
      final resumen = await _apiService.getResumenFinanciero();
      emit(ResumenLoaded(resumen));
    } catch (e) {
      // Si falla, emitimos un resumen vacío
      emit(ResumenLoaded({'ingresosHoy': 0.0, 'egresosHoy': 0.0, 'saldoActual': 0.0}));
    }
  }

  Future<void> _onCargarMovimientos(
      CargarMovimientos event, Emitter<FinanzasState> emit) async {
    emit(MovimientosLoading());
    try {
      // 1. Buscamos los movimientos para la tabla
      final List<dynamic> data = await _apiService.getMovimientos(
          pagina: event.pagina, limite: event.limite ?? 10);

      // 2. Buscamos los saldos para las tarjetas
      final hoy = DateTime.now();
      final inicioMes = DateTime(hoy.year, hoy.month, 1);
      final dataHoy = await _apiService.getBalance(hoy, hoy);
      final dataMes = await _apiService.getBalance(inicioMes, hoy);

      final resumen = {
        'ingresosHoy': dataHoy['totalIngresos'] ?? 0.0,
        'egresosHoy': dataHoy['totalEgresos'] ?? 0.0,
        'saldoActual': dataMes['margenNeto'] ?? 0.0,
      };

      // 3. Emitimos un ÚNICO estado con todo empaquetado
      emit(MovimientosLoaded(data, resumen, pagina: 1, totalPaginas: 1));
    } catch (e) {
      emit(MovimientosError(e.toString()));
    }
  }

  Future<void> _onCrearMovimiento(
      CrearMovimiento event, Emitter<FinanzasState> emit) async {
    try {
      await _apiService.createMovimiento({
        'tipo': event.tipo,
        'monto': event.monto,
        'metodoPago': event.metodoPago,
        'categoria': event.categoria,
        'descripcion': event.descripcion,
      });
      emit(OperacionExitosa('Movimiento registrado correctamente'));
      // Recargar datos
      add(CargarResumen());
      add(CargarMovimientos());
    } catch (e) {
      emit(MovimientosError(e.toString()));
    }
  }

  Future<void> _onCargarBalance(
      CargarBalance event, Emitter<FinanzasState> emit) async {
    emit(BalanceLoading());
    try {
      final data = await _apiService.getBalance(event.fechaInicio, event.fechaFin);
      emit(BalanceLoaded(data));
    } catch (e) {
      emit(MovimientosError(e.toString()));
    }
  }
}