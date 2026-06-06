package com.sgiu_group.sgiu.config;

import com.sgiu_group.sgiu.models.entities.EspUsuario;
import com.sgiu_group.sgiu.repositories.EspUsuarioRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.CommandLineRunner;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;

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

    @Override
    public void run(String... args) {
        if (usuarioRepository.count() == 0) {
            EspUsuario admin = new EspUsuario();
            admin.setUsername("admin");
            admin.setPassword(passwordEncoder.encode("admin123"));
            admin.setActivo(true);
            usuarioRepository.save(admin);
        }
    }
}
