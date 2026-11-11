"""Servidor web para la exportación HTML5 del juego.

Igual que `python -m http.server`, pero le pide al navegador que no guarde caché. Así, después de
reexportar, siempre se carga la versión nueva del juego (index.pck / index.wasm).

Uso: python scripts/servidor_web.py <carpeta> <puerto>
"""
import functools
import http.server
import sys


class SinCache(http.server.SimpleHTTPRequestHandler):
    extensions_map = {**http.server.SimpleHTTPRequestHandler.extensions_map, ".wasm": "application/wasm"}

    def end_headers(self):
        self.send_header("Cache-Control", "no-store, must-revalidate")
        super().end_headers()


def main():
    carpeta = sys.argv[1] if len(sys.argv) > 1 else "export/web"
    puerto = int(sys.argv[2]) if len(sys.argv) > 2 else 8000
    manejador = functools.partial(SinCache, directory=carpeta)
    with http.server.ThreadingHTTPServer(("0.0.0.0", puerto), manejador) as servidor:
        print(f"Sirviendo {carpeta} en el puerto {puerto} (sin caché). Ctrl+C para detener.")
        servidor.serve_forever()


if __name__ == "__main__":
    main()
