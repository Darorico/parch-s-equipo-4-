# Parchís Club: caso de uso «Ejercer turno del juego»

Entrega en equipo de **Arquitectura de Software** (Equipo 4). Es un Parchís multijugador en red hecho en
**Godot 4.5.1** con exportación **Web (HTML5)**. Implementa el caso de uso **CU12 Ejercer Turno del Juego**:
el jugador en turno lanza el dado, la interfaz de *todos* los jugadores refleja el resultado y el turno pasa al
siguiente. Funciona con 2 a 4 jugadores, cada uno en su propio equipo.

## Arquitectura

| Patrón | Dónde |
|---|---|
| **MVC** | `models/` (Modelo), `views/` (Vista) y `controllers/` (Controlador), con responsabilidades separadas. |
| **Observer** | `Partida` es el sujeto: emite señales nativas de Godot (`turno_cambiado`, `dado_lanzado`, `opciones_turno`, `ficha_movida`, `mensaje`…). Las vistas se suscriben y se repintan con los datos de cada señal; **nunca consultan al Modelo**. |
| **Fachada** | `FachadaReglas` es el único punto de acceso del Modelo al subsistema de reglas (Tablero, Casilla, Ficha y Dado). |
| **Mock** | `ReglasMock` simula las reglas detrás de la fachada: dado del 1 al 6; con 5, «Sacar ficha de la casa»; con otro número, «Ficha movida N casillas»; captura simple; con 6 se vuelve a tirar (máximo 3 tiros). |
| **Red (CU09)** | Servidor autoritativo con WebSocket (`controllers/red.gd`). Los clientes mandan acciones y el servidor las valida (por ejemplo, que sea tu turno), las aplica en su `Partida` y reenvía cada señal a todos los clientes. Cada cliente la aplica en su **réplica** de `Partida`, que vuelve a emitir la señal para que su Vista la observe. |

```
Jugador ─clic─▶ PanelAcciones ─▶ ControladorTurno ─▶ Red ─(WebSocket)─▶ Red(servidor) ─▶ Partida ─▶ FachadaReglas ─▶ ReglasMock
                                                                                          │
   VistaTablero ◀─señal─ Partida (réplica) ◀─(WebSocket: evento)─ Red(servidor) ◀─señal───┘
```

### Estructura

```
main.gd / main.tscn           Raíz de composición y navegación entre pantallas
models/                       MODELO
  partida.gd                  Sujeto observado: estado, reglas del turno y señales
  jugador.gd ficha.gd dado.gd turno.gd
  reglas/fachada_reglas.gd    FACHADA del subsistema de reglas
  reglas/reglas_mock.gd       MOCK del subsistema de reglas
controllers/                  CONTROLADOR
  controlador_turno.gd        Acciones del turno (lanzar, liberar, mover)
  controlador_lobby.gd        Registro y «Listo»
  red.gd                      Autoload «Red»: WebSocket, RPC y sincronización (CU09)
  bot_prueba.gd               Jugador automático solo para pruebas
views/                        VISTA (una por pantalla del storyboard)
  escenas/*.tscn              Diseño de cada pantalla, editable en el editor (ver Guia_Editor_Visual.md)
  tema/                       Tema de la interfaz y fuente gruesa
  vista_registro.gd           Pantalla 01 Registro
  vista_sala_espera.gd        Pantalla 02 Sala de espera
  vista_tablero.gd            Pantallas 03 y 04 Tablero, turno y selección de ficha
  tablero_dibujo.gd panel_jugadores.gd panel_acciones.gd dado_vista.gd avatar_icono.gd estilo.gd
  fx/                         Estilo «cuaderno escolar»: crayón, papel, decoraciones, sonidos y animaciones
assets/fuentes/               Pangolin (licencia OFL)
assets/sonidos/               Efectos de sonido (ver assets/sonidos/LEEME.md)
docs/                         Diagramas y documentos de la entrega
scripts/                      servidor.ps1, web.ps1, exportar_web.ps1
```

## Documentos (`docs/`)

- [`Parchis_Equipo4_4+1.mdj`](../docs/Parchis_Equipo4_4+1.mdj): **archivo de StarUML** organizado en las 4+1 vistas. En la Unidad II se movió a `docs/` en la raíz del repositorio porque es el único modelo del equipo. Contiene: casos de uso; clases de análisis y de diseño (vista lógica); secuencias de análisis y de diseño de «Ejercer turno» (vista de procesos); paquetes (vista de desarrollo); y despliegue (vista física).
- [`Guia_Editor_Visual.md`](Guia_Editor_Visual.md): **cómo ver y modificar las pantallas y el tablero en el editor de Godot**.
- [`Arquitectura_Juego.md`](Arquitectura_Juego.md): **mapa de toda la programación**, con cada script, cómo interactúan, estilo visual, sonido y animación.
- [`casos_de_uso.drawio`](docs/casos_de_uso.drawio): diagrama de casos de uso corregido (se abre en draw.io o app.diagrams.net). Respaldo en [`casos_de_uso.puml`](docs/casos_de_uso.puml).
- [`diseno_clases.puml`](docs/diseno_clases.puml) y [`diseno_secuencia_ejercer_turno.puml`](docs/diseno_secuencia_ejercer_turno.puml): **modelo de diseño**, idéntico al código, para pasarlo a StarUML.
- [`revision_diagramas.md`](docs/revision_diagramas.md): observaciones sobre los diagramas de análisis y la correspondencia análisis → diseño → código.
- [`storyboard_objetos_presentacion.md`](docs/storyboard_objetos_presentacion.md): relación entre los elementos del storyboard y los objetos de presentación.

## Cómo correrlo

Se necesita Godot 4.5.1. Los scripts asumen que el ejecutable está en el Escritorio; si no, pásalo con `-Godot`.
Si PowerShell no deja ejecutar scripts, córrelos así: `powershell -ExecutionPolicy Bypass -File .\scripts\servidor.ps1`.

### Opción rápida (todo en un equipo, desde el editor)

1. Abre el proyecto en Godot y presiona **F5**. Escribe tu nombre y pulsa **«Hospedar partida en este equipo»**.
2. Abre otra instancia (en el editor: menú *Depurar → Personalizar instancias de ejecución* y activa 2, o vuelve a
   abrir el ejecutable) y **únete** con `ws://127.0.0.1:9080`.
3. Los dos pulsan **«Listo»** y la partida empieza sola.

### En red (LAN o Tailscale), con el navegador

1. **Exportar a Web** (una sola vez). Instala las plantillas de exportación 4.5.1 en el editor
   (*Editor → Gestionar plantillas de exportación → Descargar e instalar*) y luego ejecuta:
   ```powershell
   .\scripts\exportar_web.ps1
   ```
2. **Servidor de juego** (en el equipo anfitrión):
   ```powershell
   .\scripts\servidor.ps1
   ```
3. **Servidor web** (en el mismo equipo, en otra terminal):
   ```powershell
   .\scripts\web.ps1
   ```
4. **Publicar por HTTPS.** La versión Web de Godot 4 **solo arranca en `https://` o en `localhost`**; por
   `http://IP:8000` sale el error *«Secure Context - use HTTPS»*. Con Tailscale es gratis:
   - Una sola vez: en https://login.tailscale.com/admin/dns activa **HTTPS Certificates**.
   - Ejecuta `.\scripts\publicar_tailscale.ps1`. Te muestra la dirección, por ejemplo
     `https://desktop-xxxx.tailXXXX.ts.net`.
5. Cada jugador abre esa dirección `https://…ts.net` en su navegador. El campo «Servidor» se llena solo con
   `wss://…ts.net/ws`.

En tu propio equipo también puedes jugar en `http://localhost:8000`, porque `localhost` cuenta como seguro.

**Tu amigo tiene que estar en tu red de Tailscale.** Instala Tailscale y acepta la invitación que le mandas
desde el panel (*Machines → tu PC → ⋯ → Share*).

> Para dejar de publicar: `tailscale serve reset`. La primera vez, Windows puede pedir permiso en el firewall
> para *Godot* y *Python*.

### Demo reproducible para el video

Con `-Dados` fijas los valores que devuelve el Mock, para que en el video se vea cada regla:

```powershell
.\scripts\servidor.ps1 -Dados "5,2,3,6,4,1"
```

En este ejemplo: el primer jugador saca 5 y libera una ficha, el segundo saca 2 y pierde el turno (no tiene
fichas fuera), el primero saca 3 y mueve su ficha, etc.

### Guion sugerido del video (de que arranca la app a que termina el caso de uso)

1. Arrancar el servidor (`servidor.ps1`) y mostrar la consola escuchando en el puerto 9080.
2. Abrir el juego en dos navegadores o equipos: **Pantalla 01**. Cada uno se registra con nombre, color y avatar.
3. **Pantalla 02**: aparecen los dos jugadores; cada uno pulsa «Listo» y la partida arranca sola.
4. **Pantalla 03**: se resalta al jugador que eligió el sistema. Solo a él se le resalta el dado para lanzarlo con un clic.
5. Lanza el dado: el dado se anima **en las dos pantallas** (Observer + CU09).
6. **Pantalla 04**: si sacó 5, «Liberar ficha»; si tiene fichas fuera, elige una ficha y «Mover ficha».
7. La bitácora muestra el mensaje del Mock y el turno pasa al otro jugador, resaltado en ambas pantallas.

## Pruebas automáticas

Hay un servidor sin interfaz y dos jugadores automáticos que recorren el mismo flujo con los mismos controladores.
Cada proceso imprime en consola los eventos que envía o recibe:

```bash
Godot_v4.5.1-stable_win64.exe --headless --path . -- --servidor
Godot_v4.5.1-stable_win64.exe --headless --path . -- --cliente=Ana --color=rojo --auto --turnos=12
Godot_v4.5.1-stable_win64.exe --headless --path . -- --cliente=Beto --color=azul --auto --turnos=12
```

## Alcance y limitaciones (intencionales)

- El Mock **no** simula barreras (CU08), el pasillo de meta ni la victoria por meta. Las fichas recorren un
  circuito de 68 casillas. Eso le toca al motor de reglas real, que se conectará detrás de la misma fachada.
- La pantalla 05 (ganador) solo existe en versión mínima, para el caso de abandono.
