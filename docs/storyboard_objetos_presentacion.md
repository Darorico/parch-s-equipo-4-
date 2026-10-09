# Storyboard ↔ objetos de presentación

Relación entre los elementos gráficos del storyboard (PDF del Equipo 4) y los objetos de presentación del
modelo de diseño (`views/`). Esta tabla es la que pide la tarea para el PDF de storyboards.

Todas las vistas **observan** al Modelo (`Partida`) a través de señales; ninguna lo consulta. Las acciones del
usuario van al Controlador correspondiente.

## Pantalla 01 · Registro / Membresía (CU01)

| Elemento del storyboard | Objeto de presentación | Comportamiento |
|---|---|---|
| Encabezado «01 · Registro/Membresía · Cada jugador se registra» | `Estilo.encabezado()` dentro de `VistaRegistro` | Estático |
| Tarjeta «Registro individual» | `VistaRegistro` | Contenedor del formulario |
| Campo «Username» | `VistaRegistro._nombre : LineEdit` | Nombre de usuario |
| Opciones «Color de ficha» (Rojo, Azul, Amarillo, Verde) | `VistaRegistro._grupo_color : ButtonGroup` con `AvatarIcono` | Selección única |
| Opciones «Avatar» | `VistaRegistro._grupo_avatar : ButtonGroup` con `AvatarIcono` | Selección única; toma el color elegido |
| Aviso «La información se sincroniza…» | `Estilo.aviso()` | Estático |
| Botón «Unirse a la partida» | `VistaRegistro._boton_unirse` → `ControladorLobby.unirse_a_partida()` | Conecta y registra |
| *(agregado)* Campo «Servidor» | `VistaRegistro._servidor : LineEdit` | Dirección `ws://IP:9080` |
| *(agregado)* Botón «Hospedar partida» | `VistaRegistro._boton_hospedar` → `ControladorLobby.hospedar_partida()` | Solo en escritorio |
| Mensajes de error | `VistaRegistro._estado` | Observa `Partida.error_recibido` |

## Pantalla 02 · Sala de espera / Arranque (CU02, CU03)

| Elemento del storyboard | Objeto de presentación | Comportamiento |
|---|---|---|
| Tarjeta «Sala de espera» con la lista de jugadores | `VistaSalaEspera._lista` | Se repinta con `Partida.jugadores_actualizados` |
| Etiqueta «Listo» / «Esperando» de cada jugador | `Estilo.pildora()` en `VistaSalaEspera._fila()` | Según `datos.listo` |
| Texto «N/4 listos…» | `VistaSalaEspera._resumen` | Se repinta con `jugadores_actualizados` |
| Botón «Listo» | `VistaSalaEspera._boton_listo` → `ControladorLobby.confirmar_estado()` | Alterna listo / cancelar |
| Tarjeta «Estado de la partida» | `VistaSalaEspera._conectados` y reglas activas | Se repinta con `jugadores_actualizados` |
| Paso automático al tablero | `main.gd` observa `Partida.partida_iniciada` | Crea `VistaTablero` |

## Pantalla 03 · Tablero central y turno activo (CU12 → CU04, CU09)

| Elemento del storyboard | Objeto de presentación | Comportamiento |
|---|---|---|
| Tablero de parchís (casas, recorrido, pasillos, meta) | `TableroDibujo` | Dibujado con `_draw()` |
| Fichas con color e identificador | `TableroDibujo._dibujar_ficha()` | Se mueven con `Partida.ficha_movida` |
| Panel «Jugadores» (avatar, color, fichas en meta) | `PanelJugadores` | Se repinta con `jugadores_actualizados` |
| Etiqueta «Turno» y fila resaltada | `PanelJugadores.marcar_turno()` | Observa `Partida.turno_cambiado` |
| Caja «Turno de X · N fichas en meta» | `PanelJugadores._texto_turno` | Observa `turno_cambiado` |
| Botón «Lanzar dado» | `PanelAcciones.boton_lanzar` → `ControladorTurno.procesar_lanzamiento_dado()` | Activo solo para el jugador en turno |
| *(agregado)* Cara del dado | `PanelAcciones.dado : DadoVista` | Se anima con `Partida.dado_lanzado` |
| Caja amarilla de mecánicas | `Bitacora` | Muestra los mensajes de `Partida.mensaje` |

## Pantalla 04 · Selección de ficha y reglas (CU05, CU06, CU07)

| Elemento del storyboard | Objeto de presentación | Comportamiento |
|---|---|---|
| Encabezado «04 · Elige una ficha válida» | Encabezado de `VistaTablero` | Cambia con `Partida.opciones_turno` |
| «Resultado del dado» | `PanelAcciones._resultado` | Observa `dado_lanzado` |
| «Fichas disponibles» (1, 2, 3, 4) | Chips de `PanelAcciones._chips` | Solo se activan las de `opciones_turno.fichas_movibles` |
| Fichas resaltadas en el tablero | `TableroDibujo.resaltar()` | También se pueden elegir con un clic |
| *(agregado)* Botón «Liberar ficha» | `PanelAcciones.boton_liberar` → `ControladorTurno.liberar_ficha()` | Solo si `puede_liberar` (salió 5) |
| Botón «Mover ficha» | `PanelAcciones.boton_mover` → `ControladorTurno.mover_ficha(ficha_id)` | Activo al elegir una ficha |
| Escenario de captura | Mensaje en `Bitacora` + ficha rival de vuelta en su casa | Simulado por `ReglasMock.enviar_ficha_a_base()` |

## Pantalla 05 · Fin del juego (CU10, CU11)

Fuera del alcance de esta entrega. Hay una versión mínima: si un jugador abandona y queda uno solo,
`VistaTablero._mostrar_fin()` muestra la tarjeta «Resultado final» al recibir `Partida.partida_terminada`.
