# Sirve el juego exportado a Web (carpeta export/web) para abrirlo desde cualquier navegador de la red.
# Uso:  .\scripts\web.ps1            (puerto 8000)
param([int]$Puerto = 8000)

$web = Join-Path (Split-Path -Parent $PSScriptRoot) "export\web"
if (-not (Test-Path (Join-Path $web "index.html"))) {
    Write-Error "No existe export\web\index.html. Primero exporta con .\scripts\exportar_web.ps1"
    exit 1
}

Write-Host "Juego disponible en:"
Write-Host "   http://localhost:$Puerto"
Get-NetIPAddress -AddressFamily IPv4 |
    Where-Object { $_.IPAddress -notlike "127.*" -and $_.IPAddress -notlike "169.254.*" } |
    ForEach-Object { Write-Host ("   http://{0}:{1}   ({2})" -f $_.IPAddress, $Puerto, $_.InterfaceAlias) }
python -m http.server $Puerto --bind 0.0.0.0 --directory $web
