# Arquitectura del juego: Parchís Club

Mapa de toda la programación del proyecto: qué hace cada script, cómo se comunican y por dónde
pasa cada acción del jugador. Sirve para orientarse antes de modificar algo.

- **Motor:** Godot 4.5.1, GDScript, renderizador *GL Compatibility* (necesario para la Web).
- **Caso de uso implementado:** CU12 *Ejercer turno del juego* (incluye CU04 Lanzar dado, CU05 Liberar
  ficha, CU06 Mover ficha y CU09 Sincronizar tablero), para 2 a 4 jugadores en red.
- **Patrones:** MVC, Observer (señales de Godot), Fachada y Mock, servidor autoritativo.

---

## 1. Vista general

```
                       ┌──────────────────────────── EQUIPO DEL JUGADOR (cliente) ─────────────────────────────┐
  clic ──▶  VISTA (views/)  ──acción──▶  CONTROLADOR (controllers/)  ──▶  Red  ══ WebSocket ══╗
             ▲                                                                                  ║
             │ señales (Observer)                                                               ║
             │                                                                                  ║
          Partida (réplica)  ◀── aplicar_evento() ◀── Red ◀════════ evento replicado (CU09) ═════╣
                       └─────────────────────────────────────────────────────────────────────────║──────────┘
                                                                                                  ║
                       ┌──────────────────────────────── SERVIDOR ─────────────────────────────── ║ ─────────┐
                       │   Red ──▶ Partida (modelo autoritativo) ──▶ FachadaReglas ──▶ ReglasMock ◀╝          │
                       │              │ evento_emitido                                                       │
                       │              └──────────────▶ Red ═══ reenvía a todos los clientes ═══▶            │
                       └──────────────────────────────────────────────────────────────────────────────────────┘
```

Regla de oro: **la Vista nunca le pregunta nada al Modelo.** Solo escucha sus señales y repinta con los
datos que trae cada señal. Las acciones del usuario van siempre Vista → Controlador → (red) → Modelo.

---

## 2. Estructura de carpetas

```
main.gd / main.tscn            Raíz de composición: crea todo y navega entre pantallas
project.godot                  Escena principal, autoloads, ventana y fuente del proyecto
export_presets.cfg             Preset de exportación Web (sin hilos: no necesita cabeceras COOP/COEP)

models/                        MODELO
  partida.gd                   Sujeto observado: estado de la partida, reglas del turno y señales
  jugador.gd                   Jugador: id, nombre, color, avatar, listo, fichas, fichas en meta
  ficha.gd                     Ficha: id, color, casilla (-1 = en casa)
  dado.gd                      Dado: valor actual (lo genera el subsistema de reglas)
  turno.gd                     Orden de turnos, jugador actual, fase y tiros seguidos
  reglas/fachada_reglas.gd     FACHADA del subsistema de reglas de negocio
  reglas/reglas_mock.gd        MOCK: simula las reglas (tablero, dado, capturas, regla del 6)

controllers/                   CONTROLADOR
  controlador_turno.gd         Acciones del turno: lanzar dado, liberar ficha, mover ficha
  controlador_lobby.gd         Registro (CU01), hospedar/unirse y «Listo» (CU02)
  red.gd                       Autoload «Red»: WebSocket, RPC y réplica de eventos (CU09)
  bot_prueba.gd                Jugador automático solo para pruebas (-- --auto)

views/                         VISTA (una por pantalla del storyboard)
  vista_registro.gd            Pantalla 01: registro
  vista_sala_espera.gd         Pantalla 02: sala de espera
  vista_tablero.gd             Pantallas 03 y 04: tablero, turno y selección de ficha
  tablero_dibujo.gd            Tablero y fichas dibujados a crayón; animación de fichas
  panel_jugadores.gd           Lista de jugadores con el turno resaltado
  panel_acciones.gd            Dado, botones del turno y línea de resultado
  dado_vista.gd                Dado dibujado a lápiz con animación stop-motion
  avatar_icono.gd              Avatar del jugador (círculo de color con una figura)
  estilo.gd                    Paleta de crayones, fuente Pangolin, tema y piezas comunes
  fx/                          Servicios de presentación (estilo «cuaderno escolar»)
    garabato.gd                Primitivas de dibujo a mano: líneas temblorosas y relleno de crayón
    stylebox_crayon.gd         StyleBox dibujado a mano (paneles, botones, campos de texto)
    papel.gdshader             Shader de papel blanco arrugado y doblado
    fondo_papel.gd             Rectángulo de fondo que usa ese shader
    decoraciones.gd            Garabatos de los márgenes (estrellas, espirales, crayón)
    gestor_sonidos.gd          Autoload «Sonidos»: efectos de sonido
    gestor_animaciones.gd      Autoload «Animaciones»: ritmo stop-motion y transiciones

assets/fuentes/                Pangolin-Regular.ttf + licencia OFL
assets/sonidos/                Efectos de sonido (vacía hasta que se agreguen; ver LEEME.md)
docs/                          Diagramas UML y documentos de la entrega
scripts/                       PowerShell: servidor, servidor web, exportar, publicar con Tailscale
```

### Autoloads (singletons globales, en este orden)

| Nombre | Script | Para qué |
|---|---|---|
| `Red` | `controllers/red.gd` | Conexión WebSocket, RPC y sincronización del tablero |
| `Sonidos` | `views/fx/gestor_sonidos.gd` | Efectos de sonido (opcionales: si no hay archivo, no suena) |
| `Animaciones` | `views/fx/gestor_animaciones.gd` | Reloj stop-motion (8 cuadros/s), transiciones de pantalla |

---

## 3. Arranque (`main.gd`)

1. Lee los argumentos de línea de comandos (después de `--`).
2. Crea la `Partida`, le da su `FachadaReglas` con un `ReglasMock` y se la pasa a `Red`.
3. **Servidor dedicado:** con `--servidor`, o con `--headless` sin `--cliente`, abre el puerto y
   termina aquí. No crea interfaz.
4. **Cliente:**
   - Crea los controladores y aplica el tema (`Estilo.crear_tema()`).
   - Pone la hoja de cuaderno: `FondoPapel` y `Decoraciones`.
   - Se suscribe a `Partida.jugador_registrado`, a `Partida.partida_iniciada` y a `Red.desconectado`.
   - Muestra la pantalla de registro.
5. **Navegación**, siempre reaccionando a señales:

| Evento | Pantalla nueva |
|---|---|
| inicio, desconexión o «Volver al inicio» | `VistaRegistro` |
| `jugador_registrado` con mi id | `VistaSalaEspera` |
| `partida_iniciada` (si estoy en la lista) | `VistaTablero` |

Cada cambio de pantalla agrega la vista nueva **de inmediato**, ya conectada al Modelo para no perder
eventos, y llama a `Animaciones.transicion_pantalla()`: una hoja de papel se retira a saltos.

### Argumentos de línea de comandos

| Argumento | Efecto |
|---|---|
| `--servidor` | Servidor dedicado sin interfaz |
| `--puerto=9080` | Puerto del servidor |
| `--dados=5,3,6` | Valores forzados del dado en el Mock (demos reproducibles) |
| `--cliente=Nombre` / `--color=rojo` / `--url=ws://…` | Datos precargados en el registro |
| `--auto` | Bot de prueba: se registra, confirma y juega solo |
| `--turnos=10` | Con `--auto`: cambios de turno antes de salir |
| `--capturas=carpeta` | Con `--auto`: guarda capturas de pantalla de cada paso |

---

## 4. Modelo (`models/`)

### `Partida`: el sujeto observado

Es el único objeto que conocen las vistas, y solo a través de sus señales. Funciona en dos modos:

- **Servidor (autoritativo):** sus métodos aplican las reglas, delegando en la fachada, y emiten señales.
- **Cliente (réplica):** `aplicar_evento(nombre, args)` actualiza su estado con lo que manda el servidor y
  vuelve a emitir **la misma señal**. Así una vista funciona igual en el servidor y en cualquier cliente.

**Señales** (todas las replicadas viajan por la red con datos planos: `int`, `String`, `Array`, `Dictionary`):

| Señal | Cuándo | Quién la escucha |
|---|---|---|
| `jugador_registrado(jugador_id)` | CU01, un jugador quedó registrado | `main` (navega a la sala), bot |
| `jugadores_actualizados(jugadores)` | Registro, «Listo», abandono | Sala de espera, panel de jugadores, tablero |
| `partida_iniciada(jugadores, orden)` | CU03, todos listos | `main` (navega al tablero) |
| `turno_cambiado(jugador_id)` | Empieza un turno (o se repite con 6) | `VistaTablero`, bot |
| `dado_lanzado(jugador_id, valor)` | CU04 | `VistaTablero` (anima el dado) |
| `opciones_turno(jugador_id, movibles, puede_liberar)` | Hay fichas para mover o liberar | `VistaTablero` (Pantalla 04), bot |
| `ficha_movida(jugador_id, ficha_id, posiciones)` | CU05/CU06, incluye capturas | `VistaTablero` (anima las fichas) |
| `mensaje(texto)` | Resultado del Mock y avisos | `PanelAcciones` (línea de resultado) |
| `partida_terminada(ganador_id, motivo)` | Queda un solo jugador | `VistaTablero` (tarjeta final) |
| `error_recibido(texto)` *(solo local)* | Acción rechazada o falla de red | Vistas (texto en rojo) |
| `evento_emitido(nombre, args)` *(interna)* | Acompaña a cada señal replicada | `Red` (la difunde) |

`_notificar()` primero difunde el evento por la red y después emite la señal local, para que el orden
de los eventos sea idéntico en todos los equipos.

**Métodos del servidor**, que devuelven `""` si todo salió bien o el texto del error:

| Método | Caso de uso | Qué hace |
|---|---|---|
| `registrar_jugador(id, nombre, color, avatar)` | CU01 | Valida (máximo 4, nombre, color libre) y registra |
| `confirmar_estado(id, listo)` | CU02 | Marca listo y llama a `verificar_estado_partida()` |
| `verificar_estado_partida()` / `iniciar_partida()` | CU03 | Con 2 o más jugadores, todos listos: prepara el tablero y elige al azar quién empieza |
| `lanzar_dado(id)` | CU04 | Valida el turno, pide el valor a la fachada, calcula las opciones |
| `liberar_ficha(id)` | CU05 | Fachada → `posicionar_en_salida` |
| `mover_ficha(id, ficha_id)` | CU06 | Fachada → `actualizar_posicion` (+ captura) |
| `_finalizar_accion(id)` | CU13 | La fachada valida el fin del turno: repite con 6 o pasa al siguiente |
| `quitar_jugador(id)` | CU10/CU11 | Abandono: lo saca del orden; si queda uno, termina la partida |

### `Turno`, `Dado`, `Jugador`, `Ficha`

- `Turno`: orden **horario** fijo de los jugadores (rojo → verde → amarillo → azul), índice del jugador
  actual, `fase` (LANZAR / ELEGIR_FICHA) y `tiros_seguidos` (regla del 6). Métodos: `siguiente()`,
  `repetir()`, `quitar()`, `fijar_actual()` (para las réplicas).
- `Dado.generar_valor(fachada)` guarda el valor que devuelve el subsistema.
- `Jugador.to_dict()` y `desde_dict()` convierten al formato plano que viaja en señales y RPC.
- `Ficha.casilla` vale `-1` si está en casa y de `0` a `67` en el recorrido.

### Subsistema de reglas: Fachada + Mock

`FachadaReglas` es el **único** punto de contacto del Modelo con las reglas de negocio. Hoy delega en
`ReglasMock`; el día que exista el motor real, solo se cambia el objeto que recibe su constructor.

| Fachada | Mock | Resultado |
|---|---|---|
| `iniciar_partida(colores)` | `preparar_tablero` | Todas las fichas en casa |
| `generar_valor()` | `generar_valor` | 1 a 6, o la secuencia de `--dados` |
| `opciones(id, valor)` | `fichas_movibles`, `puede_liberar` | `{movibles, puede_liberar}` |
| `liberar_ficha(id, valor)` | `posicionar_en_salida` | `{ok, ficha_id, mensaje, posiciones}` |
| `mover_ficha(id, ficha, valor)` | `actualizar_posicion` + `enviar_ficha_a_base` | Igual, más la captura |
| `validar_fin_turno(id, valor, tiros)` | `repite_turno` | `true` si el turno termina |
| `retirar_jugador(id)` | `retirar_fichas` | Las fichas desaparecen |

**Reglas que simula el Mock:**
- **Recorrido:** circular de 68 casillas que avanza en sentido **antihorario**.
- **Salidas:** rojo 4, azul 21, amarillo 38 y verde 55.
- **Casillas seguras:** las salidas y las 8 grises (11, 16, 28, 33, 45, 50, 62 y 67).
- **Con 5** se saca una ficha de casa; con cualquier número se mueve una ficha.
- **Captura** fuera de las casillas seguras.
- **Con 6** se vuelve a tirar, máximo 3 veces seguidas.

No simula barreras (CU08), pasillo de meta ni victoria por meta.

---

## 5. Controladores (`controllers/`)

| Script | Métodos | Destino |
|---|---|---|
| `ControladorTurno` | `procesar_lanzamiento_dado()`, `liberar_ficha()`, `mover_ficha(ficha_id)` | `Red.solicitar(...)` |
| `ControladorLobby` | `unirse_a_partida(url, nombre, color, avatar)`, `hospedar_partida(...)`, `registrar_jugador(...)`, `confirmar_estado(listo)`, `salir()` | `Red` |

Los controladores **no tocan la interfaz**: la interfaz cambia sola cuando el Modelo emite sus señales.

### `Red` (autoload): servidor autoritativo sobre WebSocket

- `hospedar(puerto)`: abre `WebSocketMultiplayerPeer` como servidor y se suscribe a
  `Partida.evento_emitido`.
- `unirse(url)`: se conecta como cliente (`ws://` en LAN o Tailscale, `wss://` detrás de HTTPS).
- `solicitar(accion, args)`: si este equipo es el servidor llama directo a la Partida; si no, manda
  `_srv_accion` por RPC al servidor.

| RPC | Dirección | Contenido |
|---|---|---|
| `_srv_accion(accion, args)` | cliente → servidor | `registrar`, `listo`, `lanzar_dado`, `liberar_ficha`, `mover_ficha`. El remitente lo da la red (`get_remote_sender_id`), no el cliente, así nadie puede jugar por otro |
| `_cli_evento(nombre, args)` | servidor → todos | Cada señal replicada de la Partida (CU09) |
| `_cli_error(texto)` | servidor → un cliente | Acción rechazada («No es tu turno»…) |

Desconexiones: si un jugador se va, el servidor llama a `Partida.quitar_jugador()` (CU10). Si se cae el
servidor, el cliente reinicia su réplica y regresa al registro.

---

## 6. Vistas (`views/`)

| Script | Pantalla | Observa | Envía a |
|---|---|---|---|
| `VistaRegistro` | 01 Registro | `error_recibido` | `ControladorLobby` |
| `VistaSalaEspera` | 02 Sala de espera | `jugadores_actualizados`, `error_recibido` | `ControladorLobby` |
| `VistaTablero` | 03/04 Tablero | Todas las señales del turno | `ControladorTurno`, mediante `PanelAcciones` |

**Componentes de `VistaTablero`:** `TableroDibujo`, `PanelJugadores` y `PanelAcciones` (que contiene `DadoVista`).

**Cola de presentación de `VistaTablero`:** los eventos llegan casi juntos (dado, movimiento, cambio de
turno), así que se encolan y se muestran en orden. Cada paso espera a que termine su animación:
- El dado espera `PAUSA_DADO`.
- El movimiento espera lo que devuelve `TableroDibujo.mostrar_posiciones()`, que es la duración del recorrido.

**`PanelAcciones`:**
- Botón «Lanzar dado», activo solo en tu turno.
- Fichas disponibles 1 a 4, junto con «Liberar ficha» y «Mover ficha».
- Una **línea de resultado** con el último `mensaje` del Mock (o el error en rojo).

**`TableroDibujo`:**
- 19×19 casillas. Casas: rojo arriba-izquierda, verde arriba-derecha, amarillo abajo-derecha y azul
  abajo-izquierda.
- `RECORRIDO` (68 casillas en orden antihorario), `SALIDAS`, `SEGUROS` y `PASILLOS`.
- Las fichas resaltadas se pueden elegir con un clic (`ficha_clicada`).

---

## 7. Dirección de arte: «cuaderno escolar» (`views/estilo.gd` y `views/fx/`)

- **Fuente:** Pangolin en todo. Es la `default_font` del tema y la fuente personalizada del proyecto.
  `Estilo.negrita()` es la misma Pangolin «repasada» (`FontVariation` con *embolden*).
- **Paleta:** crayones rojo, verde, amarillo y azul. Lápiz `#2b2622`, texto azul marino, títulos en rojo,
  botón principal azul con letras amarillas y resaltador amarillo.
- **`Garabato`:** dibuja con `RenderingServer` sobre cualquier canvas item.
  - `linea()`: tiembla y se pasa un poco de los extremos.
  - `rect()`, `circulo()` (no cierra perfecto), `contorno()`.
  - `rellenar()`: base tenue más rayado diagonal recortado al polígono con `Geometry2D.intersect_polyline_with_polygon`.
  - `disco()`.
  - `semilla`: el mismo trazo sale siempre igual; con `Garabato.cuadro` tiembla en stop-motion.
- **`StyleBoxCrayon`:** sobrescribe `StyleBox._draw()`. Todos los paneles, botones y campos usan el tema,
  así que toda la UI queda dibujada a mano sin tocar cada pantalla.
- **`FondoPapel` + `papel.gdshader`:** papel blanco con arrugas (facetas de Voronoi), dos dobleces y grano.
  No usa imágenes; para usar una foto de papel, cambia este nodo por un `TextureRect`.
- **`Decoraciones`:** estrellas, espirales, rayones y un crayón en las orillas, detrás de las pantallas.
- **Rendimiento del tablero:** se dibuja una vez en 3 variantes (canvas items hijos) y en cada cuadro solo
  se cambia cuál es visible. Solo las fichas se redibujan cada cuadro.

---

## 8. Sonido (`Sonidos`)

Estructura lista y silenciosa hasta que se agreguen archivos a `assets/sonidos/` (ver su `LEEME.md`).

| Función | Archivo que busca | La llama |
|---|---|---|
| `clic()` | `clic.ogg/.wav/.mp3` | Automático en **todos** los botones (`node_added`) |
| `cambio_pantalla()` | `pantalla.*` | `Animaciones.transicion_pantalla()` |
| `dado()` | `dado.*` | `DadoVista.animar()` |
| `ficha_paso()` | `ficha_paso.*` | `TableroDibujo`, en cada casilla que avanza |
| `ficha_sale()` | `ficha_sale.*` | `TableroDibujo`, al salir de casa |
| `ficha_capturada()` | `ficha_capturada.*` | `TableroDibujo`, al volver a casa |
| `turno_propio()` | `turno.*` | `PanelAcciones.mostrar_turno()` si es tu turno |

Tiene un conjunto de 6 `AudioStreamPlayer`, caché de archivos, `volumen_db` y `silenciado`.

---

## 9. Animación stop-motion (`Animaciones`)

- **Reloj:** `CUADROS_POR_SEGUNDO = 8`. En cada cuadro incrementa `Garabato.cuadro`, emite
  `cuadro_nuevo` y redibuja el grupo `garabato_vivo` (línea viva: los trazos tiemblan). Se apaga con
  `Animaciones.linea_viva = false`.
- **`esperar_cuadros(n)`:** pausa medida en cuadros; todas las animaciones avanzan a ese ritmo.
- **`transicion_pantalla()`:** una hoja de papel con el borde rasgado tapa la pantalla y se retira en 6
  saltos, bamboleándose.
- **Fichas** (`TableroDibujo`): avanzan **una casilla por cuadro**, elevadas y con sombra, y aterrizan al
  final. Al salir de casa o al ser capturadas dan un solo salto.
- **Dado** (`DadoVista`): 5 cuadros con caras al azar, ladeándose, y se queda en el valor final.

Para agregar una animación: escribe una función que cambie el estado, llame a `queue_redraw()` y haga
`await Animaciones.esperar_cuadros(1)` entre cada cambio.

---

## 10. Recorrido completo de un turno

```
Jugador A pulsa «Lanzar dado»
 └─ PanelAcciones._on_lanzar → ControladorTurno.procesar_lanzamiento_dado()
     └─ Red.solicitar("lanzar_dado") ══RPC══▶ servidor: Red._srv_accion → _ejecutar(remitente)
         └─ Partida.lanzar_dado(A)
             ├─ _validar_turno → Dado.generar_valor(fachada) → FachadaReglas → ReglasMock (1..6)
             ├─ _notificar("dado_lanzado")  ══▶ todos: Partida(réplica).aplicar_evento → señal → VistaTablero
             │                                     → DadoVista.animar (stop-motion + Sonidos.dado)
             └─ FachadaReglas.opciones()
                 ├─ sin opciones → mensaje + _finalizar_accion
                 └─ con opciones → _notificar("opciones_turno") → A ve la Pantalla 04
Jugador A elige una ficha y pulsa «Mover ficha» (o «Liberar ficha»)
 └─ ControladorTurno.mover_ficha(n) → Red ══▶ Partida.mover_ficha(A, n)
     ├─ FachadaReglas.mover_ficha → ReglasMock.actualizar_posicion (+ enviar_ficha_a_base)
     ├─ _notificar("ficha_movida") ══▶ todos: TableroDibujo.mostrar_posiciones (saltitos + sonidos)
     ├─ _notificar("mensaje")      ══▶ todos: línea de resultado del PanelAcciones
     └─ _finalizar_accion → FachadaReglas.validar_fin_turno
         ├─ salió 6 y menos de 3 tiros → Turno.repetir → turno_cambiado(A)
         └─ si no → Turno.siguiente → turno_cambiado(B) ══▶ B ve «¡TU TURNO!»
```

---

## 11. Pruebas y herramientas

- **Bot (`--auto`):** recorre el mismo flujo con los mismos controladores. Con `--capturas` guarda PNG de
  cada pantalla.
- **Scripts:**
  - `scripts/servidor.ps1` (con `-Dados`): servidor de juego.
  - `scripts/web.ps1`: servidor de la página web.
  - `scripts/exportar_web.ps1`: exporta a HTML5.
  - `scripts/publicar_tailscale.ps1`: HTTPS dentro de la red de Tailscale. La versión Web de Godot 4 solo
    arranca en `https://` o en `localhost`.
- **Diagramas:** `docs/diseno_clases.puml`, `docs/diseno_secuencia_ejercer_turno.puml`, `docs/casos_de_uso.drawio`.
