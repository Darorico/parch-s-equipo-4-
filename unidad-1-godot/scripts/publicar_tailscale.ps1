# Publica el juego por HTTPS dentro de tu red de Tailscale con «tailscale serve».
# La versión Web de Godot 4 solo arranca en https:// (o en localhost), así que esto es lo que
# permite que otros equipos la abran. El WebSocket del juego queda en la misma dirección, en /ws.
#
# Requisitos (una sola vez): en https://login.tailscale.com/admin/dns activa «HTTPS Certificates».
# Antes de jugar, deja corriendo servidor.ps1 y web.ps1 en otras terminales.
# Para dejar de publicar:  tailscale serve reset

tailscale serve --bg --https=443 http://127.0.0.1:8000
tailscale serve --bg --https=443 --set-path /ws http://127.0.0.1:9080

$dns = (tailscale status --json | ConvertFrom-Json).Self.DNSName.TrimEnd(".")
Write-Host ""
Write-Host "Listo. Los jugadores abren:  https://$dns"
Write-Host "(el campo «Servidor» se llena solo con wss://$dns/ws)"
