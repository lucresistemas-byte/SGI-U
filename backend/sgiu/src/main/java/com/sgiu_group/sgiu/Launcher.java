package com.sgiu_group.sgiu;

import org.springframework.boot.SpringApplication;

import java.io.File;
import java.io.IOException;
import java.net.Socket;

import java.io.FileWriter;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.util.UUID;

public class Launcher {

    private static Process dbProcess;

    public static void main(String[] args) {
        String os = System.getProperty("os.name").toLowerCase();

        // Lógica condicional según Sistema Operativo
        if (os.contains("win")) {
            System.out.println("💻 Entorno Windows detectado. Iniciando MariaDB Portable...");
            startDatabase();
            waitForDatabase(3307); // Espera al puerto definido en la tarea C2.1
            configureFirewall(); // <-- Invocación del script de Vicky
        } else {
            System.out.println("🐧 Entorno Unix/Linux detectado. Se asume que la base de datos corre externamente (ej. Docker).");
        }

        setupInstanceId(os);
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

    private static void setupInstanceId(String os) {
        try {
            // Tarea C2.2: Define la ruta según el SO (AppData en Windows, Home en Linux)
            String basePath = os.contains("win") ? System.getenv("APPDATA") : System.getProperty("user.home");
            File dir = new File(basePath, "SGI-U");
            if (!dir.exists()) dir.mkdirs();

            File instanceFile = new File(dir, "instance.json");
            String instanceId;

            if (instanceFile.exists()) {
                // Si ya existe, lee el ID guardado
                String content = new String(Files.readAllBytes(Paths.get(instanceFile.toURI())));
                instanceId = content.split("\"")[3]; // Extracción simple asumiendo {"instanceId": "UUID"}
            } else {
                // Si es el primer arranque, genera un ID único de 8 caracteres
                instanceId = UUID.randomUUID().toString().substring(0, 8);
                String json = "{\"instanceId\":\"" + instanceId + "\"}";
                try (FileWriter fw = new FileWriter(instanceFile)) {
                    fw.write(json);
                }
                System.out.println("🆕 Nueva instalación detectada. Archivo instance.json generado con ID: " + instanceId);
            }
            
            // Guarda el ID en el sistema para que MdnsConfig lo pueda leer luego
            System.setProperty("sgiu.instance-id", instanceId);
        } catch (Exception e) {
            System.err.println("❌ Error manejando instance.json: " + e.getMessage());
            System.setProperty("sgiu.instance-id", "generico");
        }
    }

    private static void configureFirewall() {
        try {
            System.out.println("🛡️ Solicitando permisos UAC para configurar el Firewall de Windows...");

            String appDir = new File(Launcher.class.getProtectionDomain()
                .getCodeSource().getLocation().toURI()).getParentFile().getAbsolutePath();
            String scriptPath = appDir + "\\firewall-windows.bat";

            ProcessBuilder pb = new ProcessBuilder(
                "powershell.exe",
                "-Command",
                "Start-Process cmd.exe -ArgumentList '/c \"" + scriptPath + "\"' -Verb RunAs -WindowStyle Hidden -Wait"
            );
            Process p = pb.start();
            p.waitFor();
            System.out.println("✅ Comando de firewall enviado al sistema.");
        } catch (Exception e) {
            System.err.println("❌ Error al invocar el script del firewall: " + e.getMessage());
        }
    }
}