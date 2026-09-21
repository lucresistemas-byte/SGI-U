package com.sgiu_group.sgiu;

import com.sgiu_group.sgiu.repositories.CategoriaRepository;
import com.sgiu_group.sgiu.repositories.ConfiguracionNegocioRepository;
import com.sgiu_group.sgiu.repositories.EspProductoRepository;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

import static org.junit.jupiter.api.Assertions.assertNotNull;

public class NuevoDominioRepositoriesTest extends AbstractIntegrationTest {

    @Autowired
    private CategoriaRepository categoriaRepository;

    @Autowired
    private ConfiguracionNegocioRepository configuracionNegocioRepository;

    @Autowired
    private EspProductoRepository espProductoRepository;

    @Test
    void contextLoadsConNuevosRepositorios() {
        assertNotNull(categoriaRepository);
        assertNotNull(configuracionNegocioRepository);
        assertNotNull(espProductoRepository);
    }
}
