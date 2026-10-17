@echo off
:: =============================================================================
:: SGI-U — Script de Restauración de Backup (A7 + A8)
:: Uso: restore-windows.bat <ruta_al_archivo.sql.gz|sql.gz.enc>
::
:: Requisitos:
::   - mariadb.exe disponible en el PATH o en content\bin\
::   - La BD sgiu_db debe existir y estar arrancada en el puerto 3307
::   - Si el backup viene como .sql.gz.enc, debe existir la clave maestra
::     sgiu-backup.key (por defecto en %LOCALAPPDATA%\SGI-U\sgiu-backup.key)
::
:: Lo que hace este script:
::   1. Valida que el archivo existe y tiene extension .sql.gz o .sql.gz.enc
::   2. Verifica el SHA-256 contra el archivo .sha256 hermano (si existe)
::   3. Si es .enc, lo descifra con el jar de SGI-U (--restore=...)
::   4. Descomprime el .gz a un .sql temporal
::   5. Ejecuta mariadb.exe para restaurar contra sgiu_db
::   6. Elimina el .sql temporal
:: =============================================================================

setlocal enabledelayedexpansion

echo.
echo =====================================================
echo   SGI-U Restauracion de Base de Datos (A7 + A8)
echo =====================================================
echo.

:: ---- Parametros ----
set "DUMP_FILE=%~1"
if "%DUMP_FILE%"=="" (
    echo [ERROR] Uso: restore-windows.bat ^<ruta_al_archivo.sql.gz^ o .sql.gz.enc^>
    exit /b 1
)

if not exist "%DUMP_FILE%" (
    echo [ERROR] El archivo no existe: %DUMP_FILE%
    exit /b 1
)

:: Verifica extension .sql.gz o .sql.gz.enc
echo %DUMP_FILE% | findstr /i "\.sql\.gz$" >nul
if errorlevel 1 (
    echo %DUMP_FILE% | findstr /i "\.sql\.gz\.enc$" >nul
    if errorlevel 1 (
        echo [ERROR] El archivo debe tener extension .sql.gz o .sql.gz.enc
        exit /b 1
    )
)

set "SCRIPT_DIR=%~dp0"

:: ---- Configuracion de BD ----
set "DB_HOST=localhost"
set "DB_PORT=3307"
set "DB_NAME=sgiu_db"
set "DB_USER=sgiu_user"
set "DB_PASS=sgiu_1234"

:: ---- Resolver ruta de mariadb.exe ----
set "MARIADB_EXE=mariadb"
if exist "%SCRIPT_DIR%..\content\bin\mariadb.exe" (
    set "MARIADB_EXE=%SCRIPT_DIR%..\content\bin\mariadb.exe"
)

:: ---- PASO 1: Verificacion de integridad (SHA-256) ----
echo.
echo [PASO 1] Verificando SHA-256 de %DUMP_FILE% ...
set "SHA_FILE=%DUMP_FILE%.sha256"
if exist "%SHA_FILE%" (
    powershell -NoProfile -Command ^
      "$hash = (Get-FileHash -Algorithm SHA256 '%DUMP_FILE%').Hash.ToLower();" ^
      "$expected = ((Get-Content '%SHA_FILE%' -First 1).Trim() -split '\s+')[0].ToLower();" ^
      "if ($hash -ne $expected) { Write-Host '  SHA-256 DISTINTO: el archivo esta corrupto.'; exit 3 }" ^
      "Write-Host ('  SHA-256 OK: ' + $hash)"
    if errorlevel 3 (
        echo [ERROR] El archivo NO coincide con su checksum. No se restauro nada.
        echo         Vuelva a descargar el backup desde Backblaze B2.
        exit /b 1
    )
    if errorlevel 1 (
        echo [ERROR] No se pudo calcular el SHA-256.
        exit /b 1
    )
    echo [OK] Integridad verificada.
) else (
    echo [AVISO] No existe %SHA_FILE%; se omite la verificacion de integridad.
)

:: ---- PASO 2: Descifrar .enc si hace falta ----
echo %DUMP_FILE% | findstr /i "\.sql\.gz\.enc$" >nul
if not errorlevel 1 (
    echo.
    echo [PASO 2] Archivo cifrado detectado. Descifrando con SGI-U...

    :: Resolver el jar de la aplicacion (layout del instalador)
    set "SGIU_JAR="
    if exist "%SCRIPT_DIR%..\content\app\sgiu.jar" set "SGIU_JAR=%SCRIPT_DIR%..\content\app\sgiu.jar"
    if not defined SGIU_JAR if exist "%SCRIPT_DIR%..\content\sgiu.jar" set "SGIU_JAR=%SCRIPT_DIR%..\content\sgiu.jar"
    if not defined SGIU_JAR (
        for /f "delims=" %%A in ('dir /b "%SCRIPT_DIR%..\content\app\*.jar" 2^>nul') do if not defined SGIU_JAR set "SGIU_JAR=%SCRIPT_DIR%..\content\app\%%A"
    )
    if not defined SGIU_JAR (
        echo [ERROR] No se encontro el jar de SGI-U en content\app\
        echo         Copie manualmente el backup a este equipo y ejecute:
        echo         java -jar sgiu.jar --restore=ruta\del\archivo.sql.gz.enc
        exit /b 1
    )

    :: Resolver java (JRE propio del instalador o del PATH)
    set "JAVA_EXE=java"
    if exist "%SCRIPT_DIR%..\content\java\bin\java.exe" set "JAVA_EXE=%SCRIPT_DIR%..\content\java\bin\java.exe"
    if exist "%SCRIPT_DIR%..\content\bin\java.exe" set "JAVA_EXE=%SCRIPT_DIR%..\content\bin\java.exe"

    "%JAVA_EXE%" -jar "%SGIU_JAR%" --restore="%DUMP_FILE%"
    if errorlevel 1 (
        echo [ERROR] El descifrado falló (clave incorrecta o archivo alterado).
        echo         Verifique que sgiu-backup.key sea el de la MAQUINA que genero el backup.
        exit /b 1
    )

    :: El .gz descifrado queda al lado del .enc
    set "DUMP_FILE=%DUMP_FILE:~0,-4%"
    if not exist "%DUMP_FILE%" (
        echo [ERROR] No se genero el archivo descifrado esperado: %DUMP_FILE%
        exit /b 1
    )
    echo [OK] Descifrado en %DUMP_FILE%
) else (
    echo.
    echo [PASO 2] Archivo sin cifrar; se usa directamente.
)

:: ---- Archivos temporales ----
set "TEMP_SQL=%TEMP%\sgiu_restore_%RANDOM%.sql"

echo.
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
echo [PASO 3] Descomprimiendo %DUMP_FILE% ...
powershell -NoProfile -Command ^
  "$in = [System.IO.File]::OpenRead('%DUMP_FILE%'); $gz = New-Object IO.Compression.GZipStream($in, [IO.Compression.CompressionMode]::Decompress); $out = [System.IO.File]::Create('%TEMP_SQL%'); $gz.CopyTo($out); $out.Close(); $gz.Close(); $in.Close()"
if errorlevel 1 (
    echo [ERROR] No se pudo descomprimir el archivo.
    exit /b 1
)
echo [OK] Descomprimido en %TEMP_SQL%

:: ---- Verificar cabecera SQL ----
echo.
echo [PASO 4] Verificando cabecera SQL ...
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
echo [PASO 5] Restaurando en %DB_NAME% ...
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
