package com.sgiu_group.sgiu;

import com.sgiu_group.sgiu.repositories.*;
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

    @Autowired
    private MateriaPrimaRepository materiaPrimaRepository;

    @Autowired
    private RecetaRepository recetaRepository;

    @Autowired
    private PedidoRepository pedidoRepository;

    @Test
    void contextLoadsConNuevosRepositorios() {
        assertNotNull(categoriaRepository);
        assertNotNull(configuracionNegocioRepository);
        assertNotNull(espProductoRepository);
        assertNotNull(materiaPrimaRepository);
        assertNotNull(recetaRepository);
        assertNotNull(pedidoRepository);
    }
}
