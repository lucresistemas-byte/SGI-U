@echo off
setlocal enabledelayedexpansion

set RULE_NAME=SGI-U Backend
set PORT=3000

REM Verifica si la regla ya existe (idempotencia)
netsh advfirewall firewall show rule name="%RULE_NAME%" >nul 2>&1

if !errorlevel! == 0 (
    echo La regla de firewall "%RULE_NAME%" ya existe. No se realizan cambios.
) else (
    echo Creando regla de firewall "%RULE_NAME%" para el puerto %PORT%...
    netsh advfirewall firewall add rule name="%RULE_NAME%" dir=in action=allow protocol=TCP localport=%PORT%
    if !errorlevel! == 0 (
        echo Regla creada correctamente.
    ) else (
        echo ERROR: no se pudo crear la regla. Verifique que el script se ejecute como Administrador.
    )
)

endlocal