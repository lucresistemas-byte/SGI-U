package com.sgiu_group.sgiu.config;

import jakarta.annotation.PostConstruct;
import org.springframework.stereotype.Component;

import java.io.File;
import java.util.concurrent.atomic.AtomicBoolean;

@Component
public class ShutdownManager {

    private final MdnsConfig mdnsConfig;
    private final AtomicBoolean alreadyShutdown = new AtomicBoolean(false);

    public ShutdownManager(MdnsConfig mdnsConfig) {
        this.mdnsConfig = mdnsConfig;
    }

    @PostConstruct
    public void registerHook() {
        Runtime.getRuntime().addShutdownHook(new Thread(this::shutdown, "sgiu-shutdown-hook"));
    }

    public void shutdown() {
        if (!alreadyShutdown.compareAndSet(false, true)) {
            System.out.println("Shutdown ya ejecutado anteriormente, se ignora la llamada duplicada.");
            return;
        }

        System.out.println("Iniciando apagado ordenado de SGI-U...");
        stopMariaDb();
        mdnsConfig.unregisterService();
        System.out.println("Apagado ordenado completado.");
    }

    private void stopMariaDb() {
        try {
            File dbDir = resolveInstalledPath("content" + File.separator + "bin", "packaging/portable/mariadb/bin");
            File mysqladmin = new File(dbDir, "mysqladmin.exe");

            if (mysqladmin.exists()) {
                ProcessBuilder shutdownPb = new ProcessBuilder(
                    mysqladmin.getAbsolutePath(),
                    "--port=3307", "-u", "root", "-h", "localhost", "shutdown"
                );
                shutdownPb.redirectOutput(ProcessBuilder.Redirect.DISCARD);
                shutdownPb.redirectError(ProcessBuilder.Redirect.DISCARD);
                Process shutdownProcess = shutdownPb.start();
                boolean exited = shutdownProcess.waitFor(10, java.util.concurrent.TimeUnit.SECONDS);
                if (exited && shutdownProcess.exitValue() == 0) {
                    System.out.println("MariaDB detenida correctamente con mysqladmin shutdown.");
                    return;
                }
            }

            System.out.println("mysqladmin no disponible o fallo; forzando cierre con taskkill.");
            forceKillMysqld();
        } catch (Exception e) {
            System.err.println("Error al detener MariaDB con mysqladmin, forzando cierre: " + e.getMessage());
            forceKillMysqld();
        }
    }

    private void forceKillMysqld() {
        try {
            ProcessBuilder killPb = new ProcessBuilder("taskkill", "/F", "/IM", "mysqld.exe");
            killPb.redirectOutput(ProcessBuilder.Redirect.DISCARD);
            killPb.redirectError(ProcessBuilder.Redirect.DISCARD);
            Process killProcess = killPb.start();
            killProcess.waitFor(5, java.util.concurrent.TimeUnit.SECONDS);
        } catch (Exception ex) {
            System.err.println("Error al forzar el cierre de mysqld.exe: " + ex.getMessage());
        }
    }

    private File resolveInstalledPath(String relativeToInstallDir, String devFallbackRelativePath) {
        String javaHome = System.getProperty("java.home");
        File installDir = new File(javaHome).getParentFile();
        File candidate = new File(installDir, relativeToInstallDir);
        if (candidate.exists()) {
            return candidate;
        }
        return new File(devFallbackRelativePath);
    }
}