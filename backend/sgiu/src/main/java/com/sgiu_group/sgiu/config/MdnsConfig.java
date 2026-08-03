package com.sgiu_group.sgiu.config;

import org.springframework.boot.context.event.ApplicationReadyEvent;
import org.springframework.context.event.EventListener;
import org.springframework.stereotype.Component;

import javax.jmdns.JmDNS;
import javax.jmdns.ServiceInfo;
import java.net.InetAddress;

@Component
public class MdnsConfig {

    @EventListener(ApplicationReadyEvent.class)
    public void registerService() {
        try {
            // Obtiene la IP local de tu computadora en la red WiFi
            InetAddress localHost = InetAddress.getLocalHost();
            JmDNS jmdns = JmDNS.create(localHost);
            
            // Crea el anuncio con el nombre del servicio requerido por la Tarea C1.2
            ServiceInfo serviceInfo = ServiceInfo.create("_sgiu._tcp.local.", "SGI-U-Server", 3000, "Servidor SGI-U");
            
            // Registra el servicio en la red
            jmdns.registerService(serviceInfo);
            
            System.out.println("✅ ÉXITO: Servicio mDNS (_sgiu._tcp.local.) registrado en " + localHost.getHostAddress() + ":3000");
        } catch (Exception e) {
            System.err.println("❌ Error al registrar el servicio mDNS: " + e.getMessage());
            e.printStackTrace();
        }
    }
}