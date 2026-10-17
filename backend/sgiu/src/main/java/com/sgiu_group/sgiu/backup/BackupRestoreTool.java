package com.sgiu_group.sgiu.backup;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.security.MessageDigest;
import java.util.List;

/**
 * Restauración de backups sin levantar Spring: se invoca desde la CLI con
 * {@code --restore=<archivo> [--sha256=<hex>]}.
 * <p>
 * Verifica el SHA-256 ANTES de operar (detecta corrupción de red en la
 * descarga), descifra {@code .enc} con la clave maestra local y también
 * verifica el hash del {@code .sql.gz} resultante cuando existe su
 * {@code .sha256} hermano.
 * <p>
 * Códigos de salida: 0 OK · 2 archivo inexistente · 3 hash distinto ·
 * 4 fallo de descifrado · 1 error genérico.
 */
public final class BackupRestoreTool {

    public static final int OK = 0;
    public static final int ERROR_GENERICO = 1;
    public static final int ARCHIVO_INEXISTENTE = 2;
    public static final int HASH_DISTINTO = 3;
    public static final int DESCIFRADO_FALLIDO = 4;

    private BackupRestoreTool() {
    }

    /**
     * @param archivoRuta     backup a restaurar (.sql.gz o .sql.gz.enc)
     * @param sha256Esperado  hex opcional; si es null se lee el .sha256 hermano
     * @return                código de salida (ver constantes)
     */
    public static int restaurar(String archivoRuta, String sha256Esperado) {
        try {
            File archivo = new File(archivoRuta);
            if (!archivo.exists() || !archivo.isFile()) {
                System.err.println("[RESTORE] El archivo no existe: " + archivoRuta);
                return ARCHIVO_INEXISTENTE;
            }

            // 1) Verificación del archivo recibido (siempre antes de tocar nada).
            String hashEsperado = sha256Esperado;
            if (hashEsperado == null || hashEsperado.isBlank()) {
                hashEsperado = leerHashDelHermano(archivo);
            }
            if (hashEsperado != null && !hashEsperado.isBlank()) {
                String hashReal = sha256Hex(archivo);
                if (!hashReal.equalsIgnoreCase(hashEsperado.trim())) {
                    System.err.println("[RESTORE] SHA-256 DISTINTO: el archivo está corrupto o fue alterado.");
                    System.err.println("  esperado: " + hashEsperado.trim());
                    System.err.println("  obtenido: " + hashReal);
                    System.err.println("  No se restauró nada. Vuelve a descargar el backup.");
                    return HASH_DISTINTO;
                }
                System.out.println("[RESTORE] SHA-256 verificado OK: " + hashReal);
            } else {
                System.out.println("[RESTORE] Aviso: no se encontró checksum; se continúa sin verificar integridad.");
            }

            File gz;
            if (archivo.getName().endsWith(".enc")) {
                gz = descifrar(archivo);
                if (gz == null) {
                    return DESCIFRADO_FALLIDO;
                }
                // Verifica el .gz resultante contra su checksum hermano si existe.
                String hashGzHermano = leerHashDelHermano(gz);
                if (hashGzHermano != null && !hashGzHermano.isBlank()) {
                    String hashGz = sha256Hex(gz);
                    if (!hashGz.equalsIgnoreCase(hashGzHermano.trim())) {
                        System.err.println("[RESTORE] El .sql.gz descifrado NO coincide con su SHA-256 (" + hashGz + ").");
                        return HASH_DISTINTO;
                    }
                    System.out.println("[RESTORE] SHA-256 del .sql.gz verificado OK: " + hashGz);
                }
            } else {
                gz = archivo;
            }

            System.out.println("[RESTORE] Archivo listo para restaurar: " + gz.getAbsolutePath());
            System.out.println("[RESTORE] Siguiente paso (ver RESTORE_GUIA.md): descomprimir y cargar en la BD.");
            return OK;
        } catch (Exception e) {
            System.err.println("[RESTORE] Error inesperado: " + e.getMessage());
            e.printStackTrace();
            return ERROR_GENERICO;
        }
    }

    private static File descifrar(File archivo) {
        try {
            EncryptionService servicio = new EncryptionService();
            servicio.initSolaLectura();
            byte[] contenido = servicio.descifrar(archivo);
            File destino = new File(archivo.getParentFile(),
                    quitarExtension(archivo.getName()));
            try (FileOutputStream fos = new FileOutputStream(destino)) {
                fos.write(contenido);
            }
            System.out.println("[RESTORE] Descifrado OK: " + destino.getName()
                    + " (" + contenido.length + " bytes)");
            return destino;
        } catch (IllegalStateException e) {
            System.err.println("[RESTORE] " + e.getMessage());
            return null;
        } catch (Exception e) {
            System.err.println("[RESTORE] Falló el descifrado (clave incorrecta o archivo alterado): "
                    + e.getMessage());
            return null;
        }
    }

    /** Lee el checksum hermano: <archivo>.sha256 (formato `sha256sum`). */
    static String leerHashDelHermano(File archivo) throws IOException {
        File hermano = new File(archivo.getParentFile(), archivo.getName() + ".sha256");
        if (!hermano.exists()) {
            return null;
        }
        List<String> lineas = Files.readAllLines(hermano.toPath(), StandardCharsets.UTF_8);
        if (lineas.isEmpty()) {
            return null;
        }
        String linea = lineas.get(0).trim();
        int espacio = linea.indexOf(' ');
        return espacio > 0 ? linea.substring(0, espacio) : linea;
    }

    static String quitarExtension(String nombre) {
        return nombre.endsWith(".enc") ? nombre.substring(0, nombre.length() - 4) : nombre;
    }

    public static String sha256Hex(File archivo) throws Exception {
        MessageDigest md = MessageDigest.getInstance("SHA-256");
        try (FileInputStream fis = new FileInputStream(archivo)) {
            byte[] buffer = new byte[8192];
            int read;
            while ((read = fis.read(buffer)) != -1) {
                md.update(buffer, 0, read);
            }
        }
        StringBuilder hex = new StringBuilder();
        for (byte b : md.digest()) {
            hex.append(String.format("%02x", b));
        }
        return hex.toString();
    }
}
