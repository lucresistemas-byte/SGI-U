package com.sgiu_group.sgiu;

import org.springframework.boot.SpringApplication;

import java.io.File;
import java.io.IOException;
import java.net.Socket;

public class Launcher {

    private static Process dbProcess;

    public static void main(String[] args) {
        String os = System.getProperty("os.name").toLowerCase();

        // Lógica condicional según Sistema Operativo
        if (os.contains("win")) {
            System.out.println("💻 Entorno Windows detectado. Iniciando MariaDB Portable...");
            startDatabase();
            waitForDatabase(3307); // Espera al puerto definido en la tarea C2.1
        } else {
            System.out.println("🐧 Entorno Unix/Linux detectado. Se asume que la base de datos corre externamente (ej. Docker).");
        }

        System.out.println("🚀 Iniciando Spring Boot...");
        SpringApplication.run(SgiuApplication.class, args);
        
        // Tarea C2.1: ShutdownHook para matar mysqld al cerrar la aplicación
        Runtime.getRuntime().addShutdownHook(new Thread(() -> {
            if (dbProcess != null && dbProcess.isAlive()) {
                System.out.println("🛑 Apagando base de datos MariaDB...");
                dbProcess.destroy();
            }
        }));
    }

    private static void startDatabase() {
        try {
            // Ruta relativa donde Vicki empaquetará MariaDB Portable
            File dbDir = new File("packaging/portable/mariadb/bin");
            ProcessBuilder pb = new ProcessBuilder("mysqld.exe", "--port=3307");
            pb.directory(dbDir);
            
            // Redirige los logs de la BD para mantener la consola limpia
            pb.redirectOutput(ProcessBuilder.Redirect.DISCARD);
            pb.redirectError(ProcessBuilder.Redirect.DISCARD);
            
            dbProcess = pb.start();
        } catch (IOException e) {
            System.err.println("❌ Error al iniciar MariaDB: " + e.getMessage());
        }
    }

    private static void waitForDatabase(int port) {
        System.out.print("⏳ Esperando a que MariaDB responda en el puerto " + port + "...");
        int retries = 30;
        while (retries > 0) {
            try (Socket s = new Socket("localhost", port)) {
                System.out.println(" ¡Listo!");
                return;
            } catch (IOException ex) {
                try {
                    Thread.sleep(1000); // Esperar 1 segundo y reintentar
                } catch (InterruptedException ie) {
                    Thread.currentThread().interrupt();
                }
                retries--;
            }
        }
        System.err.println("\n❌ Tiempo de espera agotado para la base de datos.");
    }
}