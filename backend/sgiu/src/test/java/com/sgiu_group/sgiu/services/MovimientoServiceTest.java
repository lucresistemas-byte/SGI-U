package com.sgiu_group.sgiu.services;

import com.sgiu_group.sgiu.models.dtos.BalanceResponseDTO;
import com.sgiu_group.sgiu.models.dtos.MovimientoRequestDTO;
import com.sgiu_group.sgiu.models.dtos.MovimientoResponseDTO;
import com.sgiu_group.sgiu.models.entities.MovFinanciero;
import com.sgiu_group.sgiu.models.entities.TipoMovimiento;
import com.sgiu_group.sgiu.repositories.MovFinancieroRepository;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class MovimientoServiceTest {

    @Mock
    private MovFinancieroRepository repository;

    @InjectMocks
    private MovimientoService movimientoService;

    @Test
    void crearMovimiento_tipoInvalido_lanzaExcepcion() {
        MovimientoRequestDTO dto = new MovimientoRequestDTO(
                "TRANSFERENCIA_EXTRA", new BigDecimal("100.00"), "EFECTIVO", "Varios", null, null);

        assertThatThrownBy(() -> movimientoService.crearMovimiento(dto))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessage("El tipo de movimiento debe ser INGRESO o EGRESO.");

        verify(repository, never()).save(any());
    }

    @Test
    void crearMovimiento_sinFechaHora_usaFechaActual() {
        MovimientoRequestDTO dto = new MovimientoRequestDTO(
                "INGRESO", new BigDecimal("150.00"), "TRANSFERENCIA", "Ventas", "Nota", null);
        when(repository.save(any(MovFinanciero.class))).thenAnswer(inv -> inv.getArgument(0));

        MovimientoResponseDTO response = movimientoService.crearMovimiento(dto);

        ArgumentCaptor<MovFinanciero> captor = ArgumentCaptor.forClass(MovFinanciero.class);
        verify(repository).save(captor.capture());
        assertThat(captor.getValue().getTipo()).isEqualTo(TipoMovimiento.INGRESO);
        assertThat(captor.getValue().getFechaHora()).isNotNull();

        assertThat(response.tipo()).isEqualTo("INGRESO");
        assertThat(response.monto()).isEqualByComparingTo("150.00");
        assertThat(response.metodoPago()).isEqualTo("TRANSFERENCIA");
        assertThat(response.categoria()).isEqualTo("Ventas");
        assertThat(response.descripcion()).isEqualTo("Nota");
    }

    @Test
    void crearMovimiento_conFechaHora_preservaLaFecha() {
        LocalDateTime fija = LocalDateTime.of(2026, 9, 20, 15, 30);
        MovimientoRequestDTO dto = new MovimientoRequestDTO(
                "EGRESO", new BigDecimal("50.00"), "TARJETA", "Compras", null, fija);
        when(repository.save(any(MovFinanciero.class))).thenAnswer(inv -> inv.getArgument(0));

        MovimientoResponseDTO response = movimientoService.crearMovimiento(dto);

        assertThat(response.fechaHora()).isEqualTo(fija);
        assertThat(response.tipo()).isEqualTo("EGRESO");
    }

    @Test
    void listarMovimientos_ordenaPorFechaDescendente() {
        MovFinanciero uno = new MovFinanciero(
                TipoMovimiento.INGRESO, new BigDecimal("100.00"), "EFECTIVO", null, null,
                LocalDateTime.of(2026, 9, 20, 10, 0), null);
        MovFinanciero dos = new MovFinanciero(
                TipoMovimiento.EGRESO, new BigDecimal("30.00"), "EFECTIVO", null, null,
                LocalDateTime.of(2026, 9, 21, 10, 0), null);
        when(repository.findAllByOrderByFechaHoraDesc()).thenReturn(List.of(dos, uno));

        List<MovimientoResponseDTO> lista = movimientoService.listarMovimientos();

        assertThat(lista).hasSize(2);
        assertThat(lista.get(0).tipo()).isEqualTo("EGRESO");
        assertThat(lista.get(1).tipo()).isEqualTo("INGRESO");
    }

    @Test
    void calcularBalance_fechaInicioPosteriorAlFin_lanzaExcepcion() {
        LocalDate inicio = LocalDate.of(2026, 9, 22);
        LocalDate fin = LocalDate.of(2026, 9, 20);

        assertThatThrownBy(() -> movimientoService.calcularBalance(inicio, fin))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessage("La fecha de inicio no puede ser posterior a la fecha de fin.");
    }

    @Test
    void calcularBalance_acumulaIngresosYEgresosYCalculaMargen() {
        LocalDate inicio = LocalDate.of(2026, 9, 1);
        LocalDate fin = LocalDate.of(2026, 9, 30);

        when(repository.sumByTipoEnRango(any(), any(), eq(TipoMovimiento.INGRESO)))
                .thenReturn(new BigDecimal("1000.00"));
        when(repository.sumByTipoEnRango(any(), any(), eq(TipoMovimiento.EGRESO)))
                .thenReturn(new BigDecimal("400.00"));

        BalanceResponseDTO balance = movimientoService.calcularBalance(inicio, fin);

        assertThat(balance.totalIngresos()).isEqualByComparingTo("1000.00");
        assertThat(balance.totalEgresos()).isEqualByComparingTo("400.00");
        assertThat(balance.margenNeto()).isEqualByComparingTo("600.00");
        assertThat(balance.movimientos()).isEmpty();

        // El rango se amplía: hasta = fin.plusDays(1).atStartOfDay()
        LocalDateTime desdeEsperado = inicio.atStartOfDay();
        LocalDateTime hastaEsperado = fin.plusDays(1).atStartOfDay();
        verify(repository).sumByTipoEnRango(desdeEsperado, hastaEsperado, TipoMovimiento.INGRESO);
        verify(repository).sumByTipoEnRango(desdeEsperado, hastaEsperado, TipoMovimiento.EGRESO);
    }

    @Test
    void calcularBalance_sinMovimientos_devuelveCeros() {
        when(repository.sumByTipoEnRango(any(), any(), eq(TipoMovimiento.INGRESO))).thenReturn(null);
        when(repository.sumByTipoEnRango(any(), any(), eq(TipoMovimiento.EGRESO))).thenReturn(null);

        BalanceResponseDTO balance = movimientoService.calcularBalance(
                LocalDate.of(2026, 9, 1), LocalDate.of(2026, 9, 30));

        assertThat(balance.totalIngresos()).isEqualByComparingTo("0");
        assertThat(balance.totalEgresos()).isEqualByComparingTo("0");
        assertThat(balance.margenNeto()).isEqualByComparingTo("0");
    }
}