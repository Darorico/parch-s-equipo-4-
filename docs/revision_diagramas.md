# Revisión de los diagramas del Equipo 4

Revisión del material entregado hasta ahora (casos de uso, secuencia y clases de análisis, storyboard en PDF)
contra lo que pide la tarea en equipo: **MVC, la Vista observa al Modelo, el Modelo usa un subsistema de
reglas a través de una Fachada con un objeto Mock, y al menos 2 jugadores.**

## Lo que más pesa en la calificación

| # | Problema | Dónde | Cómo corregirlo |
|---|----------|-------|-----------------|
| 1 | Falta el **modelo de diseño**. Los diagramas actuales son de análisis (boundary/control/entity) y no aparecen MVC, Observer, Fachada ni Mock. | Clases y secuencia | Agregar los diagramas de diseño: [`diseno_clases.puml`](diseno_clases.puml) y [`diseno_secuencia_ejercer_turno.puml`](diseno_secuencia_ejercer_turno.puml). |
| 2 | **La Vista no observa al Modelo.** El valor del dado le regresa a la Interfaz desde el Controlador (`retornaValorRandom`) y la actualización de pantallas viene del Servidor (`actualizarPantallas`). | Secuencia, mensajes 3, 4 y 14 | En diseño: el Modelo emite una señal (`dado_lanzado`, `turno_cambiado`…) y la Vista, que está suscrita, se repinta. |
| 3 | **El turno nunca cambia.** No hay `pasarTurno`/`siguienteJugador` ni una clase Turno, aunque el caso de uso termina justamente cuando el turno pasa al siguiente. Tampoco está el camino más común al empezar: sale algo que no es 5 con todas las fichas en casa y se pierde el turno. | Secuencia y clases | Agregar la clase `Turno` (`siguiente()`, `repetir()`) y la validación de fin de turno en la Fachada. |
| 4 | **No hay objetos de presentación** en el diseño, y el PDF del storyboard tiene que relacionar los elementos gráficos con ellos. | Clases / storyboard | Ver [`storyboard_objetos_presentacion.md`](storyboard_objetos_presentacion.md). |

## Errores menores

- **Secuencia:** dentro del `alt` anidado, `enviarFichaABase(rival)` quedó en el operando de «Bloquear camino»; va
  en «Capturar ficha». Además `actualizarPosicion` debería pasar en ambos casos, no solo en uno.
- **Secuencia:** el primer `alt` tiene la guarda del segundo operando escrita como texto suelto
  («[Movimiento estandar CU06 Mover Ficha]»); conviene ponerla como guarda del operando.
- **Clases:** la composición Tablero◆Casilla tiene las multiplicidades al revés. Lo correcto es Tablero `1` ◆— `1..*` Casilla.
- **Clases:** Ficha→Casilla debería ser `0..1`, porque una ficha en casa no está en ninguna casilla del recorrido.
- **Clases:** a Jugador le faltan `id`, `avatar` y `fichasEnMeta`, que pide el PDF del proyecto. `Partida.estado` debería ser un enum.
- **Clases:** `actualizarPantallasConectadas()` no debería estar en Partida: el Modelo solo notifica y no conoce las pantallas.
- **Clases:** `ControladorTurno` manipula Dado y Tablero directamente. En diseño solo habla con el Modelo (Partida).
- **Erratas:** «Contralador», «orgien», «Pantalllas Contectadas», «verificarEStadoPartida», «CU011», «pantallla», «Cu04».
- **Portada del PDF:** Daniel Ramon Romero Duarte e Ilse Yareli Baynori Valenzuela aparecen con la **misma matrícula
  (00000267079)**.

## Casos de uso

Corregido en [`casos_de_uso.drawio`](casos_de_uso.drawio) (respaldo en [`casos_de_uso.puml`](casos_de_uso.puml)).
Se mantiene la numeración para no romper el storyboard:

1. **Nuevo CU12 Ejercer Turno del Juego**, que es el caso de esta entrega y antes no aparecía. Jugador → CU12;
   CU12 «include» CU04, CU06 y CU09. Las asociaciones directas Jugador→CU04 y Jugador→CU06 pasan a CU12.
2. **Nuevo CU13 Repetir Tiro** «extend» CU04: si sale 6 se vuelve a tirar, máximo 3 veces (regla iv del PDF).
3. **CU11 Declarar Ganador** también extiende a CU06 (cuando la 4.ª ficha entra a la meta). Antes solo se ganaba por abandono.
4. **Jugador → CU10 Gestionar Abandono**: es el jugador quien abandona.
5. Erratas y mayúsculas corregidas.

El *Servidor* se queda como actor: es defendible, porque desde el punto de vista del cliente es un sistema externo.

## Correspondencia análisis → diseño → código

| Análisis (su diagrama) | Diseño / código |
|---|---|
| Interfaz | `VistaRegistro`, `VistaSalaEspera`, `VistaTablero` (+ `TableroDibujo`, `PanelJugadores`, `PanelAcciones`, `DadoVista`) |
| ControladorTurno.procesarLanzamientoDado() | `ControladorTurno.procesar_lanzamiento_dado()` |
| ControladorTurno.liberarFicha() | `ControladorTurno.liberar_ficha()` |
| ControladorTurno.moverFicha(origen, destino) | `ControladorTurno.mover_ficha(ficha_id)` (el destino lo calcula el subsistema de reglas) |
| Partida.verificarEstadoPartida() | `Partida.verificar_estado_partida()` |
| Partida.actualizarPantallasConectadas() | Señales de `Partida` + `Red._difundir()` (CU09) |
| Dado.generarValor() | `Dado.generar_valor(fachada)` → `FachadaReglas.generar_valor()` → `ReglasMock.generar_valor()` |
| Tablero.posicionarEnSalida() | `ReglasMock.posicionar_en_salida()` |
| Tablero.actualizarPosicion() | `ReglasMock.actualizar_posicion()` |
| Tablero.enviarFichaABase(rival) | `ReglasMock.enviar_ficha_a_base()` |
| Tablero.establecerBarrera() | `ReglasMock.establecer_barrera()` (no simulado) |
| Servidor | `Red` (autoload) + `Partida` autoritativa en el equipo servidor |
| *(no existía)* Turno | `Turno` (`siguiente()`, `repetir()`, `tiros_seguidos`) |
| *(no existía)* Fachada / Mock | `FachadaReglas` / `ReglasMock` |
