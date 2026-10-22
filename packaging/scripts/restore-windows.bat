@echo off
:: =============================================================================
:: SGI-U — Script de Restauración de Backup (Bloque 1 / Seguridad)
:: Uso: restore-windows.bat <ruta_al_archivo.sql.gz>
::
:: Requisitos:
::   - mariadb.exe disponible en el PATH o en content\bin\
::   - La BD sgiu_db ya existe y está arrancada en el puerto 3307
::   - El archivo .sql.gz debe ser el dump DESCIFRADO (sin .enc)
::     (si el backup está cifrado como .sql.gz.enc, primero descifrar
::      con la clave sgiu-backup.key usando EncryptionService o
::      ejecutando el procedimiento documentado en guías de restauración)
::
:: Validaciones de integridad (NIST SP 800-38D / FIPS 180-4):
::   1. Valida que el archivo existe y tiene extensión .sql.gz
::   2. Valida tamaño mínimo (> 15 KB para descartar volcados truncados)
::   3. Valida checksum SHA-256 si existe archivo .sha256 acompañante
::   4. Descomprime el .gz a un .sql temporal
::   5. Valida cabecera SQL
::   6. Ejecuta mariadb.exe para restaurar contra sgiu_db
::   7. Elimina el .sql temporal
:: =============================================================================

setlocal enabledelayedexpansion

echo.
echo =====================================================
echo   SGI-U Restauracion de Base de Datos
echo =====================================================
echo.

:: ---- Parametros ----
set "DUMP_FILE=%~1"
if "%DUMP_FILE%"=="" (
    echo [ERROR] Uso: restore-windows.bat ^<ruta_al_archivo.sql.gz^>
    exit /b 1
)

if not exist "%DUMP_FILE%" (
    echo [ERROR] El archivo no existe: %DUMP_FILE%
    exit /b 1
)

:: Verifica extension .sql.gz
echo %DUMP_FILE% | findstr /i "\.sql\.gz$" >nul
if errorlevel 1 (
    echo [ERROR] El archivo debe tener extension .sql.gz
    echo         Si es .sql.gz.enc, descifre primero con la clave sgiu-backup.key
    exit /b 1
)

:: ---- Validar tamaño (> 15 KB = 15360 bytes) ----
for %%F in ("%DUMP_FILE%") do set "FILE_SIZE=%%~zF"
if %FILE_SIZE% LSS 15360 (
    echo [ERROR] El archivo de backup es demasiado pequenio (%FILE_SIZE% bytes). Minimo requerido: 15360 bytes.
    echo         Posible archivo corrupto, vacio o truncado.
    exit /b 1
)

:: ---- Validar Checksum SHA-256 si existe archivo companion ----
set "SHA_FILE=%DUMP_FILE%.sha256"
if not exist "%SHA_FILE%" (
    :: Verificar si existe con nombre alternativo .sha256
    set "SHA_FILE=%~dpn1.sha256"
)

if exist "%SHA_FILE%" (
    echo [INFO] Archivo de verificacion SHA-256 detectado: %SHA_FILE%
    echo [INFO] Validando integridad criptografica ...
    powershell -NoProfile -Command ^
      "$actual = (Get-FileHash -Path '%DUMP_FILE%' -Algorithm SHA256).Hash.ToLower(); $content = (Get-Content '%SHA_FILE%').Trim(); $expected = ($content -split '\s+')[0].ToLower(); if ($actual -ne $expected) { Write-Host '[ERROR] CHECKSUM NO COINCIDE. Calculado:' $actual 'Esperado:' $expected; exit 2 } else { Write-Host '[OK] Checksum SHA-256 integro y verificado:' $actual }"
    if errorlevel 1 (
        echo [ERROR] Fallo de integridad: el volcado ha sido alterado o corrompido.
        exit /b 1
    )
) else (
    echo [ADVERTENCIA] No se encontro archivo companion .sha256 para validacion previa.
)

:: ---- Configuracion de BD ----
set "DB_HOST=localhost"
set "DB_PORT=3307"
set "DB_NAME=sgiu_db"
set "DB_USER=sgiu_user"
set "DB_PASS=sgiu_1234"

:: ---- Resolver ruta de mariadb.exe ----
set "MARIADB_EXE=mariadb"
set "SCRIPT_DIR=%~dp0"
if exist "%SCRIPT_DIR%..\content\bin\mariadb.exe" (
    set "MARIADB_EXE=%SCRIPT_DIR%..\content\bin\mariadb.exe"
)

:: ---- Archivos temporales ----
set "TEMP_SQL=%TEMP%\sgiu_restore_%RANDOM%.sql"

echo [INFO] Archivo de backup : %DUMP_FILE%
echo [INFO] Base de destino   : %DB_NAME% en %DB_HOST%:%DB_PORT%
echo [INFO] Usuario           : %DB_USER%
echo.

:: ---- Confirmacion de seguridad ----
echo [ADVERTENCIA] Esta operacion REEMPLAZA el contenido actual de %DB_NAME%.
echo               Asegurese de tener un backup actualizado antes de continuar.
echo.
set /p CONFIRMAR="Escriba SI para continuar: "
if /i not "%CONFIRMAR%"=="SI" (
    echo [INFO] Restauracion cancelada por el usuario.
    exit /b 0
)

:: ---- Descomprimir ----
echo.
echo [PASO 1] Descomprimiendo %DUMP_FILE% ...
powershell -NoProfile -Command ^
  "$in = [System.IO.File]::OpenRead('%DUMP_FILE%'); $gz = New-Object IO.Compression.GZipStream($in, [IO.Compression.CompressionMode]::Decompress); $out = [System.IO.File]::Create('%TEMP_SQL%'); $gz.CopyTo($out); $out.Close(); $gz.Close(); $in.Close()"
if errorlevel 1 (
    echo [ERROR] No se pudo descomprimir el archivo.
    exit /b 1
)
echo [OK] Descomprimido en %TEMP_SQL%

:: ---- Verificar cabecera SQL ----
echo.
echo [PASO 2] Verificando cabecera SQL ...
findstr /m "MariaDB dump" "%TEMP_SQL%" >nul 2>&1
if errorlevel 1 (
    findstr /m "MySQL dump" "%TEMP_SQL%" >nul 2>&1
    if errorlevel 1 (
        echo [ERROR] El archivo no parece un dump valido de MariaDB.
        del /f /q "%TEMP_SQL%" >nul 2>&1
        exit /b 1
    )
)
echo [OK] Cabecera SQL verificada.

:: ---- Restaurar ----
echo.
echo [PASO 3] Restaurando en %DB_NAME% ...
"%MARIADB_EXE%" --host=%DB_HOST% --port=%DB_PORT% --user=%DB_USER% --password=%DB_PASS% %DB_NAME% < "%TEMP_SQL%"
set "RESTORE_CODE=%errorlevel%"

:: ---- Limpieza ----
del /f /q "%TEMP_SQL%" >nul 2>&1

if "%RESTORE_CODE%"=="0" (
    echo.
    echo [OK] Restauracion completada exitosamente.
    echo      Reinicie SGI-U para que Flyway valide el esquema.
) else (
    echo.
    echo [ERROR] La restauracion termino con codigo %RESTORE_CODE%.
    echo         Verifique los mensajes de mariadb.exe arriba.
    exit /b %RESTORE_CODE%
)

endlocal
exit /b 0
