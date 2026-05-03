package com.sgiu_group.sgiu;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication // Spring buscará automáticamente en subpaquetes de com.sgiu_group.sgiu
public class SgiuApplication {
    public static void main(String[] args) {
        SpringApplication.run(SgiuApplication.class, args);
    }
}
