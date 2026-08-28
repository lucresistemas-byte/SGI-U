package com.sgiu_group.sgiu.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import javax.jmdns.JmDNS;
import java.net.DatagramSocket;
import java.net.InetAddress;

@Configuration
public class JmDnsBeanConfig {

    @Bean(destroyMethod = "")
    public JmDNS jmDNS() throws Exception {
        InetAddress localHost;
        try (DatagramSocket socket = new DatagramSocket()) {
            socket.connect(InetAddress.getByName("8.8.8.8"), 10002);
            localHost = socket.getLocalAddress();
        }
        return JmDNS.create(localHost);
    }
}