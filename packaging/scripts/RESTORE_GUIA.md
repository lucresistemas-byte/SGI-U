# SGI-U — Guía de Restauración de Backups (A7 + A8)

Cómo restaurar la base de datos de SGI-U desde un respaldo generado por el
sistema (archivos `sgiu_AAAAMMDD_HHMMSS.sql.gz.enc` + sus `.sha256`).

## 1. Qué necesitás

| Elemento | Por qué |
|---|---|
| El archivo `.sql.gz.enc` descargado de Backblaze B2 | Es el respaldo cifrado. |
| Sus archivos `.sha256` hermanos (`….sql.gz.enc.sha256` y `….sql.gz.sha256`) | Verifican que la descarga no esté corrupta. |
| La clave maestra `sgiu-backup.key` | Sin ella **no se puede descifrar** el `.enc`. Está en `%LOCALAPPDATA%\SGI-U\sgiu-backup.key` de la máquina que generó el backup. **Guardala aparte (pendrive cifrado).** |
| MariaDB de SGI-U arrancado en el puerto 3307 | Es el destino de la restauración. |
| `restore-windows.bat` (viene con el instalador, en `scripts\`) | Orquesta todo el proceso. |

## 2. Descargar desde Backblaze B2

1. Entrá a <https://secure.backblaze.com/b2_buckets.htm>.
2. Bucket `sgiu-backups` → carpeta `dumps/<TU-CODIGO-CLIENTE>/`.
3. Descargá **el `.enc` y los dos `.sha256`** (deben quedar en la misma carpeta).

## 3. Restaurar (camino normal)

```
scripts\restore-windows.bat "C:\ruta\sgiu_20261017_033000.sql.gz.enc"
```

El script:
1. Verifica el SHA-256 del `.enc` contra su `.sha256`.
2. Lo descifra con el jar de SGI-U (`--restore=`) usando `sgiu-backup.key`.
3. Verifica el SHA-256 del `.sql.gz` resultante.
4. Descomprime, valida la cabecera SQL y la carga en `sgiu_db` con `mariadb.exe`.
5. Te pide escribir `SI` antes de reemplazar los datos.

Al terminar, reiniciá SGI-U para que Flyway valide el esquema.

## 4. Restaurar a mano (sin el bat)

Útil en Linux/Docker o si el instalador no está completo:

```bash
# 1. Verificar integridad del archivo descifrado (opcional pero recomendado)
sha256sum -c sgiu_20261017_033000.sql.gz.enc.sha256

# 2. Descifrar (el .sql.gz queda al lado del .enc)
java -jar sgiu.jar --restore=backups/sgiu_20261017_033000.sql.gz.enc
# código de salida: 0 OK · 2 archivo inexistente · 3 hash distinto · 4 clave/fallo

# 3. Restaurar (ejemplo con Docker; puerto 3306 en dev, 3307 en Windows)
gunzip -c backups/sgiu_20261017_033000.sql.gz | \
  docker exec -i -e MYSQL_PWD=sgiu_1234 sgiu-mariadb mariadb -u sgiu_user sgiu_db
```

Si la clave maestra está en otra ruta:

```bash
java -Dsgiu.backup.encryption.keyPath=/ruta/sgiu-backup.key \
  -jar sgiu.jar --restore=backups/sgiu_20261017_033000.sql.gz.enc
```

## 5. Errores frecuentes

| Mensaje | Causa | Solución |
|---|---|---|
| `SHA-256 DISTINTO` | Descarga incompleta o archivo alterado | Volvé a descargar desde B2. No restaures. |
| `No existe la clave maestra` | Falta `sgiu-backup.key` o está en otra máquina | Recuperá el `.key` de tu copia de seguridad; o pasá su ruta con `-Dsgiu.backup.encryption.keyPath=`. |
| `Falló el descifrado (clave incorrecta o archivo alterado)` | El `.key` no es el que se usó al generar ese backup | Usá el `.key` de la máquina/timestamp correspondiente. |
| `No se encontro el jar de SGI-U` (bat) | El layout del instalador cambió | Ejecutá el paso 2 a mano: `java -jar sgiu.jar --restore=…`. |

## 6. Reglas de la materia

- **Nunca** restaures encima de una base sin verificar el SHA-256.
- La clave `sgiu-backup.key` **no** se sube a B2 ni se comparte por mail.
- Probá la restauración en un equipo de prueba al menos una vez por semestre
  (un backup que nunca se restauró no es un backup).
