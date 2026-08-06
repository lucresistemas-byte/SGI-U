@echo off
setlocal

REM V2.1 - Genera un runtime Java reducido (JRE a medida) con jlink,
REM usando solo los modulos que la app realmente necesita (obtenidos con jdeps).

set MODULES=java.base,java.compiler,java.desktop,java.instrument,java.management,java.net.http,java.prefs,java.rmi,java.scripting,java.security.jgss,java.sql.rowset,jdk.jfr,jdk.unsupported
set OUTPUT_DIR=target\runtime

if exist "%OUTPUT_DIR%" (
    echo Eliminando runtime anterior en %OUTPUT_DIR%...
    rmdir /s /q "%OUTPUT_DIR%"
)

echo Generando runtime con los modulos: %MODULES%
jlink --add-modules %MODULES% --output "%OUTPUT_DIR%" --strip-debug --no-header-files --no-man-pages --compress=2

if %errorlevel% == 0 (
    echo Runtime generado correctamente en %OUTPUT_DIR%
) else (
    echo ERROR: jlink fallo al generar el runtime.
)

endlocal
