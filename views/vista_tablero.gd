class_name VistaTablero
extends Control
## Pantallas 03 y 04 del storyboard: tablero central, turno activo y selección de ficha.
## Diseño: views/escenas/vista_tablero.tscn (el tablero y los paneles se editan ahí).
##
## OBSERVADOR del Modelo: se suscribe a las señales de Partida y repinta sus subvistas con los datos
## que traen. Nunca consulta al Modelo; las acciones del usuario van al ControladorTurno.
## Los eventos se presentan en orden y esperando a que termine cada animación: primero el dado
## rueda, al terminar se muestra su resultado, luego la ficha avanza casilla por casilla y al final
## se muestra el cambio de turno.

signal volver_al_inicio

@onready var tablero: TableroDibujo = %Tablero
@onready var panel_jugadores: PanelJugadores = %PanelJugadores
@onready var panel_acciones: PanelAcciones = %PanelAcciones
## Opcional: la pantalla del tablero va sin títulos para dejarle más espacio al tablero.
@onready var _encabezado: Control = get_node_or_null("%Encabezado")

var _mi_id := 0
var _nombres := {}  # jugador_id -> nombre (de lo recibido en las señales)
var _movibles: Array = []
var _cola: Array = []  # [[Callable, pausa]]
var _procesando := false


func _ready() -> void:
	_encabezado_normal()


## Se llama después de agregar la vista al árbol. `jugadores` son los datos de partida_iniciada.
func configurar(partida: Partida, controlador: ControladorTurno, mi_id: int, jugadores: Array) -> void:
	_mi_id = mi_id
	panel_acciones.configurar(controlador)
	panel_acciones.ficha_elegida.connect(_on_ficha_elegida)
	tablero.ficha_clicada.connect(panel_acciones.seleccionar_ficha)
	_mostrar_jugadores(jugadores)

	# Patrón Observer: la vista se suscribe a las señales del Modelo.
	partida.jugadores_actualizados.connect(_on_jugadores_actualizados)
	partida.turno_cambiado.connect(_on_turno_cambiado)
	partida.dado_lanzado.connect(_on_dado_lanzado)
	partida.opciones_turno.connect(_on_opciones_turno)
	partida.ficha_movida.connect(_on_ficha_movida)
	partida.mensaje.connect(_on_mensaje)
	partida.error_recibido.connect(_on_error)
	partida.partida_terminada.connect(_on_partida_terminada)


# --- Manejadores de señales del Modelo (se encolan para presentarlos en orden) ---

func _on_jugadores_actualizados(jugadores: Array) -> void:
	_encolar(_mostrar_jugadores.bind(jugadores))


func _on_turno_cambiado(jugador_id: int) -> void:
	_encolar(_mostrar_turno.bind(jugador_id))


## El dado se presenta en dos pasos: rueda (la cola espera a que termine) y luego se revela el valor.
func _on_dado_lanzado(jugador_id: int, valor: int) -> void:
	_encolar(panel_acciones.animar_dado.bind(valor))
	_encolar(panel_acciones.revelar_dado.bind(valor, _nombre(jugador_id), jugador_id == _mi_id))


func _on_opciones_turno(jugador_id: int, movibles: Array, puede_liberar: bool) -> void:
	_encolar(_mostrar_opciones.bind(jugador_id, movibles, puede_liberar))


func _on_ficha_movida(_jugador_id: int, _ficha_id: int, posiciones: Dictionary) -> void:
	_encolar(_mostrar_movimiento.bind(posiciones))


func _on_mensaje(texto: String) -> void:
	_encolar(panel_acciones.mostrar_resultado.bind(texto))


func _on_partida_terminada(ganador_id: int, motivo: String) -> void:
	_encolar(_mostrar_fin.bind(ganador_id, motivo))


func _on_error(texto: String) -> void:
	panel_acciones.mostrar_resultado(texto, true)
	panel_acciones.restaurar()


# --- Repintado ---

func _mostrar_jugadores(jugadores: Array) -> void:
	for datos: Dictionary in jugadores:
		_nombres[datos.id] = datos.nombre
	panel_jugadores.mostrar(jugadores, _mi_id)
	tablero.mostrar_jugadores(jugadores)


func _mostrar_turno(jugador_id: int) -> void:
	panel_jugadores.marcar_turno(jugador_id)
	panel_acciones.mostrar_turno(jugador_id == _mi_id, _nombre(jugador_id))
	tablero.resaltar(0, [])
	_encabezado_normal()


func _mostrar_opciones(jugador_id: int, movibles: Array, puede_liberar: bool) -> void:
	if jugador_id != _mi_id:
		return
	Estilo.cambiar_encabezado(_encabezado, "04", "SELECCIÓN DE FICHA", "Elige una ficha válida",
			"Haz clic en una ficha resaltada del tablero. Con un 5 también puedes liberar una de tu casa.")
	_movibles = movibles
	tablero.resaltar(jugador_id, movibles)
	panel_acciones.mostrar_opciones(movibles, puede_liberar)


## Devuelve la duración de la animación para que la cola espere a que la ficha llegue.
func _mostrar_movimiento(posiciones: Dictionary) -> float:
	tablero.resaltar(0, [])
	panel_acciones.limpiar_opciones()
	return tablero.mostrar_posiciones(posiciones)


func _mostrar_fin(ganador_id: int, motivo: String) -> void:
	panel_acciones.terminar_partida()
	var columna := VBoxContainer.new()
	columna.custom_minimum_size.x = 380
	columna.add_theme_constant_override("separation", 12)
	columna.add_child(Estilo.etiqueta("¡%s gana!" % _nombre(ganador_id), 34, Estilo.TITULO, true))
	columna.add_child(Estilo.parrafo(motivo))
	var boton := Button.new()
	boton.text = "Volver al inicio"
	boton.theme_type_variation = &"BotonPrimario"
	boton.pressed.connect(volver_al_inicio.emit)
	columna.add_child(boton)
	var tarjeta := Estilo.tarjeta("Resultado final", columna)
	tarjeta.add_theme_stylebox_override("panel", Estilo.caja(Estilo.PAPEL, Estilo.LAPIZ, 22.0))
	var centro := CenterContainer.new()
	centro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	centro.add_child(tarjeta)
	add_child(centro)


func _on_ficha_elegida(ficha_id: int) -> void:
	tablero.resaltar(_mi_id, _movibles, ficha_id)


func _encabezado_normal() -> void:
	Estilo.cambiar_encabezado(_encabezado, "03", "TABLERO Y TURNO", "Tablero central y turno activo",
			"Cada jugador ve su avatar, su color, sus fichas en meta y de quién es el turno.")


func _nombre(jugador_id: int) -> String:
	return _nombres.get(jugador_id, "Jugador %d" % jugador_id)


# --- Cola de presentación ---

## `accion` puede devolver un número: los segundos que dura su animación (la cola los espera).
func _encolar(accion: Callable, pausa := 0.0) -> void:
	_cola.append([accion, pausa])
	if not _procesando:
		_procesar_cola()


func _procesar_cola() -> void:
	_procesando = true
	while not _cola.is_empty():
		var siguiente: Array = _cola.pop_front()
		var duracion = siguiente[0].call()
		var espera: float = siguiente[1]
		if duracion is float:
			espera = maxf(espera, duracion)
		if espera > 0.0 and is_inside_tree():
			await get_tree().create_timer(espera).timeout
	_procesando = false
