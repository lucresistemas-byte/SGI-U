package com.sgiu_group.sgiu;

import com.sgiu_group.sgiu.models.entities.ConfiguracionNegocio;
import com.sgiu_group.sgiu.repositories.ConfiguracionNegocioRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

import static org.junit.jupiter.api.Assertions.*;

public class ConfiguracionNegocioEntityTest extends AbstractIntegrationTest {

    @Autowired
    private ConfiguracionNegocioRepository configuracionRepository;

    @BeforeEach
    void setup() {
        limpiarBaseDatos();
    }

    @Test
    void persistirYActualizarConfiguracionNegocio() {
        ConfiguracionNegocio config = new ConfiguracionNegocio("Panadería La Espiga", "SGIU-SANDRA-001");
        config.setDireccion("Calle Falsa 123");
        config.setTelefono("12345678");
        config = configuracionRepository.save(config);

        assertNotNull(config.getId());
        assertEquals("Panadería La Espiga", config.getNombre());
        assertEquals("SGIU-SANDRA-001", config.getCodigoCliente());

        config.setNombre("Panadería La Espiga Central");
        configuracionRepository.save(config);

        ConfiguracionNegocio actualizada = configuracionRepository.findFirstByOrderByIdAsc().orElse(null);
        assertNotNull(actualizada);
        assertEquals("Panadería La Espiga Central", actualizada.getNombre());
    }
}
