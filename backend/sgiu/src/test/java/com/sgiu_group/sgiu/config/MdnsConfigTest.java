package com.sgiu_group.sgiu.config;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import javax.jmdns.JmDNS;
import javax.jmdns.ServiceInfo;
import java.net.InetAddress;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class MdnsConfigTest {

    @Mock
    private JmDNS jmdns;

    @Test
    void registraElServicioConTipoPuertoYNombreUnico() throws Exception {
        System.setProperty("sgiu.instance-id", "test-uuid-1234");
        when(jmdns.getInetAddress()).thenReturn(InetAddress.getLoopbackAddress());

        MdnsConfig mdnsConfig = new MdnsConfig(jmdns);
        mdnsConfig.registerService();

        ArgumentCaptor<ServiceInfo> captor = ArgumentCaptor.forClass(ServiceInfo.class);
        verify(jmdns).registerService(captor.capture());

        ServiceInfo registrado = captor.getValue();
        assertEquals("_sgiu._tcp.local.", registrado.getType());
        assertEquals(3000, registrado.getPort());
        assertEquals("SGI-U-test-uuid-1234", registrado.getName());
    }

    @Test
    void desregistraElServicioYCierraJmdns() throws Exception {
        MdnsConfig mdnsConfig = new MdnsConfig(jmdns);
        mdnsConfig.unregisterService();

        verify(jmdns).unregisterAllServices();
        verify(jmdns).close();
    }
}