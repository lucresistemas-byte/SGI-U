package com.sgiu_group.sgiu.services;

import com.sgiu_group.sgiu.models.entities.EspProducto;
import com.sgiu_group.sgiu.models.entities.ModoPrecio;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;

import static org.assertj.core.api.Assertions.assertThat;

/** Reglas de precio de CostosService que no necesitan base de datos. */
class CostosServiceTest {

    private final CostosService costos = new CostosService(null, null, null, null);

    private static BigDecimal d(String v) {
        return new BigDecimal(v);
    }

    @Test
    void redondeaHaciaArribaAlProximoMultiploDe100() {
        assertThat(CostosService.redondearA100(d("3601"))).isEqualByComparingTo("3700");
        assertThat(CostosService.redondearA100(d("3600"))).isEqualByComparingTo("3600");
        assertThat(CostosService.redondearA100(d("3600.01"))).isEqualByComparingTo("3700");
        assertThat(CostosService.redondearA100(d("0.01"))).isEqualByComparingTo("100");
        assertThat(CostosService.redondearA100(BigDecimal.ZERO)).isEqualByComparingTo("0");
    }

    @Test
    void gananciaEnPesos_esPrecioMenosCosto() {
        assertThat(CostosService.ganancia(d("3600"), d("2250"))).isEqualByComparingTo("1350");
        assertThat(CostosService.ganancia(d("200"), d("70.63"))).isEqualByComparingTo("129.37");
    }

    private static EspProducto producto(ModoPrecio modo, String costo, String porcentaje, String precio) {
        EspProducto p = new EspProducto("X", "X", d(precio));
        p.setModoPrecio(modo);
        p.setPrecioCosto(d(costo));
        p.setPorcentajeGanancia(d(porcentaje));
        return p;
    }

    @Test
    void margen_costoPorUnoMasPorcentaje_redondeado() {
        assertThat(costos.precioSegunModo(producto(ModoPrecio.MARGEN, "2250", "60", "0"))).isEqualByComparingTo("3600");
        assertThat(costos.precioSegunModo(producto(ModoPrecio.MARGEN, "70.63", "100", "0"))).isEqualByComparingTo("200");
    }

    @Test
    void manual_seConservaMientrasDejeElPorcentaje_ySiNoSubeAlMinimo() {
        assertThat(costos.precioSegunModo(producto(ModoPrecio.MANUAL, "1000", "50", "2000"))).isEqualByComparingTo("2000");
        assertThat(costos.precioSegunModo(producto(ModoPrecio.MANUAL, "1500", "50", "2000"))).isEqualByComparingTo("2300");
    }

    @Test
    void costoMasFijo_armadoMasMontoFijo_redondeado() {
        EspProducto paquete = producto(ModoPrecio.COSTO_MAS_FIJO, "2200", "0", "0");
        paquete.setMontoFijo(d("1550"));
        assertThat(costos.precioSegunModo(paquete)).isEqualByComparingTo("3800");
    }

    @Test
    void porcentajeQueDejaUnPrecio_redondeadoHaciaAbajo() {
        assertThat(costos.porcentajeQueDeja(d("125"), d("100"))).isEqualByComparingTo("100");
        assertThat(costos.porcentajeQueDeja(d("1500"), d("0"))).isEqualByComparingTo("0");
    }
}
