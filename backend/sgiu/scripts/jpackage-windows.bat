@echo off
setlocal

REM V4.2 - Genera el instalador .exe de SGI-U usando jpackage,
REM empaquetando el JAR, el runtime de jlink y MariaDB Portable.

set APP_NAME=SGI-U
set APP_VERSION=1.0.0
set MAIN_JAR=sgiu-0.0.1-SNAPSHOT.jar
set MAIN_CLASS=com.sgiu_group.sgiu.Launcher
set INPUT_DIR=packaging\app\input
set RUNTIME_DIR=packaging\app\runtime
set CONTENT_DIR=packaging\app\content
set DEST_DIR=packaging\dist

if not exist "%DEST_DIR%" mkdir "%DEST_DIR%"

jpackage ^
    --type exe ^
    --name "%APP_NAME%" ^
    --app-version %APP_VERSION% ^
    --input "%INPUT_DIR%" ^
    --main-jar %MAIN_JAR% ^
    --main-class %MAIN_CLASS% ^
    --runtime-image "%RUNTIME_DIR%" ^
    --app-content "%CONTENT_DIR%" ^
    --dest "%DEST_DIR%" ^
    --win-shortcut ^
    --win-menu ^
    --vendor "SGI-U Team"

if %errorlevel% == 0 (
    echo Instalador generado correctamente en %DEST_DIR%
) else (
    echo ERROR: jpackage fallo al generar el instalador.
)

endlocal
