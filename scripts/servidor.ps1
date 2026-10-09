# Inicia el servidor de juego (WebSocket, sin interfaz) en este equipo.
# Uso:  .\scripts\servidor.ps1                 (puerto 9080)
#       .\scripts\servidor.ps1 -Dados "5,3,6"  (valores fijos del dado para grabar una demo)
param(
    [int]$Puerto = 9080,
    [string]$Dados = "",
    [string]$Godot = "$env:USERPROFILE\Desktop\Godot_v4.5.1-stable_win64.exe"
)

$proyecto = Split-Path -Parent $PSScriptRoot
if (-not (Test-Path $Godot)) {
    Write-Error "No encontré Godot en '$Godot'. Pásalo con -Godot 'ruta\al\Godot.exe'."
    exit 1
}

$argumentos = @("--headless", "--path", $proyecto, "--", "--servidor", "--puerto=$Puerto")
if ($Dados -ne "") { $argumentos += "--dados=$Dados" }

Write-Host "Servidor de Parchís en ws://0.0.0.0:$Puerto  (Ctrl+C para detener)"
Write-Host "Direcciones de este equipo que pueden usar los demás jugadores:"
Get-NetIPAddress -AddressFamily IPv4 |
    Where-Object { $_.IPAddress -notlike "127.*" -and $_.IPAddress -notlike "169.254.*" } |
    ForEach-Object { Write-Host ("   ws://{0}:{1}   ({2})" -f $_.IPAddress, $Puerto, $_.InterfaceAlias) }
& $Godot @argumentos
