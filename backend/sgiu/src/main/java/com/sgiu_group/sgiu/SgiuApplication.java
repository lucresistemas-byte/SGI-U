package com.sgiu_group.sgiu;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.scheduling.annotation.EnableScheduling;

// A6: @EnableScheduling habilita el cron de backup (03:30); sin esta
// anotación Spring ignora por completo las anotaciones @Scheduled.
@EnableScheduling
@SpringBootApplication // Spring buscará automáticamente en subpaquetes de com.sgiu_group.sgiu
public class SgiuApplication {
    // public static void main(String[] args) {
    //     SpringApplication.run(SgiuApplication.class, args);
    // }
}
