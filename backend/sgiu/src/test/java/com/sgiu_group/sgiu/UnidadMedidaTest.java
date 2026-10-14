package com.sgiu_group.sgiu;

import com.sgiu_group.sgiu.models.entities.FamiliaUnidad;
import com.sgiu_group.sgiu.models.entities.UnidadMedida;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;

import static org.assertj.core.api.Assertions.assertThat;

/** Etapa 2: conversiones dentro de cada familia de unidades. */
class UnidadMedidaTest {

    private static BigDecimal bd(String v) {
        return new BigDecimal(v);
    }

    @Test
    void peso_kiloAGramos() {
        assertThat(UnidadMedida.KILO.aBase(bd("2.5"))).isEqualByComparingTo("2500");
        assertThat(UnidadMedida.GRAMO.aBase(bd("200"))).isEqualByComparingTo("200");
        assertThat(UnidadMedida.KILO.desdeBase(bd("2500"), 3)).isEqualByComparingTo("2.5");
        assertThat(FamiliaUnidad.PESO.getUnidadBase()).isEqualTo(UnidadMedida.GRAMO);
    }

    @Test
    void volumen_litroAMililitros() {
        assertThat(UnidadMedida.LITRO.aBase(bd("0.15"))).isEqualByComparingTo("150");
        assertThat(UnidadMedida.MILILITRO.aBase(bd("150"))).isEqualByComparingTo("150");
        assertThat(FamiliaUnidad.VOLUMEN.getUnidadBase()).isEqualTo(UnidadMedida.MILILITRO);
    }

    @Test
    void longitud_metroACentimetros() {
        assertThat(UnidadMedida.METRO.aBase(bd("0.5"))).isEqualByComparingTo("50");
        assertThat(UnidadMedida.METRO.desdeBase(bd("1000"), 3)).isEqualByComparingTo("10");
        assertThat(FamiliaUnidad.LONGITUD.getUnidadBase()).isEqualTo(UnidadMedida.CENTIMETRO);
    }

    @Test
    void unidades_docenaADoce() {
        assertThat(UnidadMedida.DOCENA.aBase(bd("2"))).isEqualByComparingTo("24");
        assertThat(UnidadMedida.DOCENA.aBase(bd("0.5"))).isEqualByComparingTo("6");
        assertThat(UnidadMedida.DOCENA.desdeBase(bd("30"), 3)).isEqualByComparingTo("2.5");
        assertThat(FamiliaUnidad.UNIDAD.getUnidadBase()).isEqualTo(UnidadMedida.UNIDAD);
    }

    @Test
    void cadaFamiliaOfreceSoloSusUnidades() {
        assertThat(UnidadMedida.de(FamiliaUnidad.PESO)).containsExactly(UnidadMedida.GRAMO, UnidadMedida.KILO);
        assertThat(UnidadMedida.de(FamiliaUnidad.VOLUMEN)).containsExactly(UnidadMedida.MILILITRO, UnidadMedida.LITRO);
        assertThat(UnidadMedida.de(FamiliaUnidad.LONGITUD)).containsExactly(UnidadMedida.CENTIMETRO, UnidadMedida.METRO);
        assertThat(UnidadMedida.de(FamiliaUnidad.UNIDAD)).containsExactly(UnidadMedida.UNIDAD, UnidadMedida.DOCENA);
        assertThat(UnidadMedida.LITRO.esDe(FamiliaUnidad.PESO)).isFalse();
        assertThat(UnidadMedida.CAJA.getFamilia()).isNull();
    }

    @Test
    void texto_amigableConComaDecimal() {
        assertThat(UnidadMedida.KILO.texto(bd("2500"))).isEqualTo("2,5 kg");
        assertThat(UnidadMedida.LITRO.texto(bd("1000"))).isEqualTo("1 l");
        assertThat(UnidadMedida.GRAMO.texto(bd("200.000"))).isEqualTo("200 g");
    }
}
