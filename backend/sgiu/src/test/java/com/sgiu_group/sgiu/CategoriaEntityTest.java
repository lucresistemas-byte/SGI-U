package com.sgiu_group.sgiu;

import com.sgiu_group.sgiu.models.entities.Categoria;
import com.sgiu_group.sgiu.models.entities.EspProducto;
import com.sgiu_group.sgiu.repositories.CategoriaRepository;
import com.sgiu_group.sgiu.repositories.EspProductoRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

import java.math.BigDecimal;

import static org.junit.jupiter.api.Assertions.*;

public class CategoriaEntityTest extends AbstractIntegrationTest {

    @Autowired
    private CategoriaRepository categoriaRepository;

    @Autowired
    private EspProductoRepository espProductoRepository;

    @BeforeEach
    void setup() {
        limpiarBaseDatos();
    }

    @Test
    void persistirCategoriaYAsignarAProducto() {
        Categoria cat = new Categoria("Bebidas", "Gaseosas y jugos");
        cat = categoriaRepository.save(cat);
        assertNotNull(cat.getId());

        EspProducto prod = new EspProducto("PROD-TEST-CAT", "Jugo de Naranja", new BigDecimal("150.00"));
        prod.setCategoria(cat);
        prod = espProductoRepository.save(prod);

        EspProducto recuperado = espProductoRepository.findByCodigo("PROD-TEST-CAT").orElse(null);
        assertNotNull(recuperado);
        assertNotNull(recuperado.getCategoria());
        assertEquals("Bebidas", recuperado.getCategoria().getNombre());
    }
}
