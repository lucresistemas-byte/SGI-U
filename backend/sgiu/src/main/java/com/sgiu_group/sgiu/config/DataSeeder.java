package com.sgiu_group.sgiu.config;

import com.sgiu_group.sgiu.models.entities.EspUsuario;
import com.sgiu_group.sgiu.models.entities.MetodoPago;
import com.sgiu_group.sgiu.repositories.EspUsuarioRepository;
import com.sgiu_group.sgiu.repositories.MetodoPagoRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.CommandLineRunner;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;

import java.util.List;

/**
 * Poblado inicial de la base de datos.
 * Si no existen usuarios, crea un administrador por defecto.
 */
@Component
public class DataSeeder implements CommandLineRunner {

    @Autowired
    private EspUsuarioRepository usuarioRepository;

    @Autowired
    private PasswordEncoder passwordEncoder;

    @Autowired
    private MetodoPagoRepository metodoPagoRepository;

    @Override
    public void run(String... args) {
        if (usuarioRepository.count() == 0) {
            EspUsuario admin = new EspUsuario();
            admin.setUsername("admin");
            admin.setPassword(passwordEncoder.encode("admin123"));
            admin.setActivo(true);
            usuarioRepository.save(admin);
        }
        // En MariaDB los crea la migración V2; esto cubre una base sin
        // Flyway (los tests en H2).
        if (metodoPagoRepository.count() == 0) {
            metodoPagoRepository.saveAll(List.of(
                    new MetodoPago("Efectivo", true, 1),
                    new MetodoPago("Mercado Pago", false, 2),
                    new MetodoPago("Tarjeta", false, 3),
                    new MetodoPago("Transferencia", false, 4)));
        }
    }
}
