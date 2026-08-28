package com.sgiu_group.sgiu;

import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;

class InstallationIdentityTest {

    @Test
    void devuelveElMismoUuidEnEjecucionesConsecutivas() {
        String first = InstallationIdentity.getOrCreate();
        String second = InstallationIdentity.getOrCreate();

        assertNotNull(first);
        assertEquals(first, second);
    }
}