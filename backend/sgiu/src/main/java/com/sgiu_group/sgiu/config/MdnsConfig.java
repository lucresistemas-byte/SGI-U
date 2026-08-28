package com.sgiu_group.sgiu.config;

import org.springframework.boot.context.event.ApplicationReadyEvent;
import org.springframework.context.event.EventListener;
import org.springframework.stereotype.Component;

import javax.jmdns.JmDNS;
import javax.jmdns.ServiceInfo;

@Component
public class MdnsConfig {

    private final JmDNS jmdns;

    public MdnsConfig(JmDNS jmdns) {
        this.jmdns = jmdns;
    }

    @EventListener(ApplicationReadyEvent.class)
    public void registerService() {
        try {
            String instanceId = System.getProperty("sgiu.instance-id", "generico");
            String serviceName = "SGI-U-" + instanceId;
            ServiceInfo serviceInfo = ServiceInfo.create("_sgiu._tcp.local.", serviceName, 3000, "Servidor SGI-U");
            jmdns.registerService(serviceInfo);
            System.out.println("EXITO: Servicio mDNS registrado como " + serviceName + " en " + jmdns.getInetAddress().getHostAddress() + ":3000");
        } catch (Exception e) {
            System.err.println("Error al registrar el servicio mDNS: " + e.getMessage());
            e.printStackTrace();
        }
    }

    public void unregisterService() {
        try {
            jmdns.unregisterAllServices();
            jmdns.close();
            System.out.println("Servicio mDNS desregistrado correctamente.");
        } catch (Exception e) {
            System.err.println("Error al desregistrar el servicio mDNS: " + e.getMessage());
        }
    }
}