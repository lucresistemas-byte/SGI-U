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

        // LÃƒÂ³gica condicional segÃƒÂºn Sistema Operativo
        if (os.contains("win")) {
            System.out.println("Ã°Å¸â€™Â» Entorno Windows detectado. Iniciando MariaDB Portable...");
            startDatabase();
            waitForDatabase(3307); // Espera al puerto definido en la tarea C2.1
            configureFirewall(); // <-- InvocaciÃƒÂ³n del script de Vicky
        } else {
            System.out.println("Ã°Å¸ÂÂ§ Entorno Unix/Linux detectado. Se asume que la base de datos corre externamente (ej. Docker).");
        }

        setupInstanceId(os);
        buildAndRunSpringApplication(args);
        launchFrontend();

        // Tarea D.2: el apagado ordenado (MariaDB + mDNS) ahora lo maneja ShutdownManager (Spring @PostConstruct)
    }

    private static void startDatabase() {
        try {
            File dbDir = resolveInstalledPath("content" + File.separator + "bin", "packaging/portable/mariadb/bin");

            String localAppData = System.getenv("LOCALAPPDATA");
            File dataDir = new File(localAppData, "SGI-U" + File.separator + "mariadb_data");

            boolean needsInit = !dataDir.exists() || dataDir.listFiles() == null || dataDir.listFiles().length == 0;
            if (needsInit) {
                dataDir.mkdirs();
                System.out.println("Inicializando base de datos por primera vez...");
                ProcessBuilder initPb = new ProcessBuilder(
                    new File(dbDir, "mariadb-install-db.exe").getAbsolutePath(),
                    "--datadir=" + dataDir.getAbsolutePath()
                );
                initPb.directory(dbDir);
                initPb.redirectOutput(ProcessBuilder.Redirect.DISCARD);
                initPb.redirectError(ProcessBuilder.Redirect.DISCARD);
                Process initProcess = initPb.start();
                initProcess.waitFor();
                System.out.println("Inicializacion de base de datos completada.");

                setupApplicationUser(dbDir, dataDir);
            }

            ProcessBuilder pb = new ProcessBuilder(
                new File(dbDir, "mysqld.exe").getAbsolutePath(),
                "--datadir=" + dataDir.getAbsolutePath(),
                "--port=3307"
            );
            pb.directory(dbDir);
            pb.redirectOutput(ProcessBuilder.Redirect.DISCARD);
            pb.redirectError(ProcessBuilder.Redirect.DISCARD);
            dbProcess = pb.start();
        } catch (IOException | InterruptedException e) {
            System.err.println("Error al iniciar MariaDB: " + e.getMessage());
        }
    }

    private static void setupApplicationUser(File dbDir, File dataDir) {
        try {
            System.out.println("Configurando usuario y base de datos de la aplicacion...");

            ProcessBuilder tempPb = new ProcessBuilder(
                new File(dbDir, "mysqld.exe").getAbsolutePath(),
                "--datadir=" + dataDir.getAbsolutePath(),
                "--port=3307"
            );
            tempPb.directory(dbDir);
            tempPb.redirectOutput(ProcessBuilder.Redirect.DISCARD);
            tempPb.redirectError(ProcessBuilder.Redirect.DISCARD);
            Process tempProcess = tempPb.start();

            boolean ready = false;
            for (int i = 0; i < 30 && !ready; i++) {
                try (Socket s = new Socket("localhost", 3307)) {
                    ready = true;
                } catch (IOException ex) {
                    Thread.sleep(1000);
                }
            }

            if (ready) {
                String sql = "CREATE DATABASE IF NOT EXISTS sgiu_db; "
                    + "CREATE USER IF NOT EXISTS 'sgiu_user'@'localhost' IDENTIFIED BY 'sgiu_1234'; "
                    + "GRANT ALL PRIVILEGES ON sgiu_db.* TO 'sgiu_user'@'localhost'; "
                    + "FLUSH PRIVILEGES;";

                ProcessBuilder sqlPb = new ProcessBuilder(
                    new File(dbDir, "mariadb.exe").getAbsolutePath(),
                    "--port=3307",
                    "-u", "root", "-h", "localhost", "-e", sql
                );
                sqlPb.directory(dbDir);
                sqlPb.redirectOutput(ProcessBuilder.Redirect.DISCARD);
                sqlPb.redirectError(ProcessBuilder.Redirect.DISCARD);
                Process sqlProcess = sqlPb.start();
                sqlProcess.waitFor();
                System.out.println("Usuario y base de datos configurados correctamente.");
            } else {
                System.err.println("No se pudo conectar para configurar el usuario de la aplicacion.");
            }

            tempProcess.destroy();
            tempProcess.waitFor();
            Thread.sleep(2000);
        } catch (IOException | InterruptedException e) {
            System.err.println("Error al configurar usuario de base de datos: " + e.getMessage());
        }
    }

    private static void waitForDatabase(int port) {
        System.out.print("Ã¢ÂÂ³ Esperando a que MariaDB responda en el puerto " + port + "...");
        int retries = 30;
        while (retries > 0) {
            try (Socket s = new Socket("localhost", port)) {
                System.out.println(" Ã‚Â¡Listo!");
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
        System.err.println("\nÃ¢ÂÅ’ Tiempo de espera agotado para la base de datos.");
    }

    private static void launchFrontend() {
        try {
            System.out.println("Iniciando interfaz de escritorio...");
            File frontendExe = resolveInstalledPath("frontend" + File.separator + "sgi_u_frontend.exe", "../../frontend/build/windows/x64/runner/Release/sgi_u_frontend.exe");
            ProcessBuilder pb = new ProcessBuilder(frontendExe.getAbsolutePath());
            pb.directory(frontendExe.getParentFile());
            pb.redirectOutput(ProcessBuilder.Redirect.DISCARD);
            pb.redirectError(ProcessBuilder.Redirect.DISCARD);
            Process frontendProcess = pb.start();

            Thread watcher = new Thread(() -> {
                try {
                    frontendProcess.waitFor();
                    System.out.println("Interfaz de escritorio cerrada. Apagando el sistema...");
                    System.exit(0);
                } catch (InterruptedException ignored) {
                }
            });
            watcher.setDaemon(true);
            watcher.start();
        } catch (IOException e) {
            System.err.println("Error al iniciar la interfaz de escritorio: " + e.getMessage());
        }
    }

    private static void setupInstanceId(String os) {
        try {
            // A2: UUID persistente en %USERPROFILE%/sgiu-installation.id
            String instanceId = InstallationIdentity.getOrCreate();
            System.setProperty("sgiu.instance-id", instanceId);
            System.out.println("ID de instalacion: " + instanceId);

            // A2: secreto JWT único por instalación, persistido en sgiu-jwt.secret
            String jwtSecret = getOrCreateJwtSecret();
            System.setProperty("SGIU_JWT_SECRET", jwtSecret);
            System.out.println("Secreto JWT de instalacion cargado.");
        } catch (Exception e) {
            System.err.println("Error obteniendo el ID de instalacion: " + e.getMessage());
            System.setProperty("sgiu.instance-id", "generico");
        }
    }

    /**
     * A2: Lee o genera un secreto JWT de 256 bits (base64) único para esta instalación.
     * El archivo se guarda en %USERPROFILE%/sgiu-jwt.secret y nunca debe compartirse.
     */
    private static String getOrCreateJwtSecret() throws java.io.IOException {
        String userProfile = System.getenv("USERPROFILE");
        if (userProfile == null || userProfile.isBlank()) {
            userProfile = System.getProperty("user.home");
        }
        java.nio.file.Path secretPath = java.nio.file.Paths.get(userProfile, "sgiu-jwt.secret");
        if (java.nio.file.Files.exists(secretPath)) {
            String content = java.nio.file.Files.readString(secretPath, java.nio.charset.StandardCharsets.UTF_8).trim();
            if (!content.isBlank()) return content;
        }
        // Genera 32 bytes aleatorios y codifica en base64
        byte[] bytes = new byte[32];
        new java.security.SecureRandom().nextBytes(bytes);
        String secret = java.util.Base64.getEncoder().encodeToString(bytes);
        java.nio.file.Files.writeString(secretPath, secret, java.nio.charset.StandardCharsets.UTF_8);
        System.out.println("Nuevo secreto JWT generado para esta instalacion.");
        return secret;
    }

    private static void configureFirewall() {
        try {
            System.out.println("Solicitando permisos UAC para configurar el Firewall de Windows...");

            File scriptFile = resolveInstalledPath("scripts" + File.separator + "firewall-windows.bat", "../../packaging/scripts/firewall-windows.bat");
            String scriptPath = scriptFile.getAbsolutePath();

            ProcessBuilder pb = new ProcessBuilder(
                "powershell.exe",
                "-Command",
                "Start-Process cmd.exe -ArgumentList '/c \"" + scriptPath + "\"' -Verb RunAs -WindowStyle Hidden -Wait"
            );
            Process p = pb.start();
            p.waitFor();
            System.out.println("Comando de firewall enviado al sistema.");
        } catch (Exception e) {
            System.err.println("Error al invocar el script del firewall: " + e.getMessage());
        }
    }

    private static File resolveInstalledPath(String relativeToInstallDir, String devFallbackRelativePath) {
        String javaHome = System.getProperty("java.home");
        File installDir = new File(javaHome).getParentFile();
        File candidate = new File(installDir, relativeToInstallDir);
        if (candidate.exists()) {
            return candidate;
        }
        return new File(devFallbackRelativePath);
    }

    private static void buildAndRunSpringApplication(String[] args) {
        System.out.println("Iniciando Spring Boot...");
        org.springframework.boot.builder.SpringApplicationBuilder builder =
            new org.springframework.boot.builder.SpringApplicationBuilder(SgiuApplication.class);
        String os = System.getProperty("os.name").toLowerCase();
        java.util.List<String> props = new java.util.ArrayList<>();
        props.add("server.port=3000");
        props.add("server.address=0.0.0.0");
        if (os.contains("win")) {
            props.add("spring.datasource.url=jdbc:mariadb://localhost:3307/sgiu_db");
        }
        builder.properties(props.toArray(new String[0]));
        builder.run(args);
        printListeningInfo();
    }

    private static void printListeningInfo() {
        try {
            java.net.InetAddress localHost;
            try (java.net.DatagramSocket socket = new java.net.DatagramSocket()) {
                socket.connect(java.net.InetAddress.getByName("8.8.8.8"), 10002);
                localHost = socket.getLocalAddress();
            }
            System.out.println("SGI-U escuchando en " + localHost.getHostAddress() + ":3000");
        } catch (Exception e) {
            System.out.println("SGI-U escuchando en el puerto 3000 (no se pudo determinar la IP local: " + e.getMessage() + ")");
        }
    }
}
