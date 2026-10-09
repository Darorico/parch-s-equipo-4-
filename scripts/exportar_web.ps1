# Exporta el juego a HTML5 en export/web (requiere las plantillas de exportación de Godot 4.5.1).
param([string]$Godot = "$env:USERPROFILE\Desktop\Godot_v4.5.1-stable_win64.exe")

$proyecto = Split-Path -Parent $PSScriptRoot
New-Item -ItemType Directory -Force (Join-Path $proyecto "export\web") | Out-Null
& $Godot --headless --path $proyecto --export-release "Web" (Join-Path $proyecto "export\web\index.html")
if ($LASTEXITCODE -eq 0) { Write-Host "Listo: export\web\index.html" }
