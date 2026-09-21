package com.sgiu_group.sgiu;

import com.sgiu_group.sgiu.models.entities.EspProducto;
import com.sgiu_group.sgiu.models.entities.UnidadMedida;
import com.sgiu_group.sgiu.repositories.EspProductoRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

import java.math.BigDecimal;

import static org.junit.jupiter.api.Assertions.*;

public class UnidadMedidaEntityTest extends AbstractIntegrationTest {

    @Autowired
    private EspProductoRepository productoRepository;

    @BeforeEach
    void setup() {
        limpiarBaseDatos();
    }

    @Test
    void productoSinUnidadPersisteComoUnidad() {
        EspProducto p = new EspProducto("P-DEF-UNIDAD", "Galletitas", new BigDecimal("50.00"));
        p = productoRepository.save(p);

        EspProducto recuperado = productoRepository.findByCodigo("P-DEF-UNIDAD").orElse(null);
        assertNotNull(recuperado);
        assertEquals(UnidadMedida.UNIDAD, recuperado.getUnidadMedida());
    }

    @Test
    void productoConKiloPersisteYLeeCorrectamente() {
        EspProducto p = new EspProducto("P-KILO", "Manzanas", new BigDecimal("120.00"));
        p.setUnidadMedida(UnidadMedida.KILO);
        p = productoRepository.save(p);

        EspProducto recuperado = productoRepository.findByCodigo("P-KILO").orElse(null);
        assertNotNull(recuperado);
        assertEquals(UnidadMedida.KILO, recuperado.getUnidadMedida());
    }
}
