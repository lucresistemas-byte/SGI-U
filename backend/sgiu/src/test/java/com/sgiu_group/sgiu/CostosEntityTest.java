package com.sgiu_group.sgiu;

import com.sgiu_group.sgiu.models.entities.EspProducto;
import com.sgiu_group.sgiu.repositories.EspProductoRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

import java.math.BigDecimal;

import static org.junit.jupiter.api.Assertions.*;

public class CostosEntityTest extends AbstractIntegrationTest {

    @Autowired
    private EspProductoRepository productoRepository;

    @BeforeEach
    void setup() {
        limpiarBaseDatos();
    }

    @Test
    void persistirProductoConCostoYPorcentaje() {
        EspProducto p = new EspProducto("P-COSTO", "Queso Cremoso", new BigDecimal("60.00"));
        p.setPrecioCosto(new BigDecimal("50.00"));
        p.setPorcentajeGanancia(new BigDecimal("20.00"));
        p = productoRepository.save(p);

        EspProducto recuperado = productoRepository.findByCodigo("P-COSTO").orElse(null);
        assertNotNull(recuperado);
        assertEquals(0, new BigDecimal("50.00").compareTo(recuperado.getPrecioCosto()));
        assertEquals(0, new BigDecimal("20.00").compareTo(recuperado.getPorcentajeGanancia()));
    }
}
