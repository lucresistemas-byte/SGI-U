# Simula la creacion de la regla de firewall sin tocar el sistema (idempotencia)
$ruleName = "SGI-U Backend"
$port = 3000

$existingRule = Get-NetFirewallRule -DisplayName $ruleName -ErrorAction SilentlyContinue

if ($existingRule) {
    Write-Output "La regla '$ruleName' ya existe. No se realizarian cambios (simulado)."
} else {
    Write-Output "Simulando creacion de regla '$ruleName' para el puerto $port..."
    New-NetFirewallRule -DisplayName $ruleName -Direction Inbound -Action Allow -Protocol TCP -LocalPort $port -WhatIf
}