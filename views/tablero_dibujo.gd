class_name TableroDibujo
extends Control
## Dibujo del tablero en cruz (19×19 casillas) y de las fichas con su color y número.
## Solo pinta lo que la VistaTablero le indica; si el jugador local está eligiendo ficha, permite
## hacer clic sobre las fichas resaltadas.

signal ficha_clicada(ficha_id: int)

const N := 19
## Esquina superior izquierda de la casa (8×8) de cada color.
const CASAS := {
	"verde": Vector2i(0, 0), "amarillo": Vector2i(11, 0), "azul": Vector2i(11, 11), "rojo": Vector2i(0, 11),
}
## Salida de cada color (índice en el recorrido; coincide con el subsistema de reglas).
const SALIDAS := {"verde": 4, "amarillo": 21, "azul": 38, "rojo": 55}
## Pasillo de meta de cada color: primera casilla y dirección hacia el centro.
const PASILLOS := {
	"amarillo": [Vector2i(9, 1), Vector2i(0, 1)],
	"azul": [Vector2i(17, 9), Vector2i(-1, 0)],
	"rojo": [Vector2i(9, 17), Vector2i(0, -1)],
	"verde": [Vector2i(1, 9), Vector2i(1, 0)],
}
const DESPLAZAMIENTOS := [Vector2(-0.2, -0.2), Vector2(0.2, 0.2), Vector2(0.2, -0.2), Vector2(-0.2, 0.2)]

## Las 68 casillas del recorrido en orden de avance (sentido horario).
static var RECORRIDO: Array[Vector2i] = _construir_recorrido()

var _jugadores: Array = []  # [{id, color, fichas: [casillas]}]
var _activo_id := 0
var _movibles: Array = []
var _seleccionada := 0
var _celda := 0.0
var _origen := Vector2.ZERO
var _zonas_clic: Array = []  # [{centro, radio, ficha}]


func _init() -> void:
	custom_minimum_size = Vector2(420, 420)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	resized.connect(queue_redraw)


func mostrar_jugadores(jugadores: Array) -> void:
	_jugadores = jugadores.duplicate(true)
	queue_redraw()


func mostrar_posiciones(posiciones: Dictionary) -> void:
	for jugador: Dictionary in _jugadores:
		if posiciones.has(jugador.id):
			jugador.fichas = posiciones[jugador.id].duplicate()
	queue_redraw()


## Resalta las fichas que el jugador local puede mover (vacío para quitar el resaltado).
func resaltar(jugador_id: int, movibles: Array, seleccionada := 0) -> void:
	_activo_id = jugador_id
	_movibles = movibles.duplicate()
	_seleccionada = seleccionada
	queue_redraw()


func _gui_input(event: InputEvent) -> void:
	var clic := event as InputEventMouseButton
	if clic == null or not clic.pressed or clic.button_index != MOUSE_BUTTON_LEFT:
		return
	for zona: Dictionary in _zonas_clic:
		if clic.position.distance_to(zona.centro) <= zona.radio * 1.3:
			ficha_clicada.emit(zona.ficha)
			accept_event()
			return


func _draw() -> void:
	_celda = floorf(minf(size.x, size.y) / N)
	_origen = ((size - Vector2.ONE * _celda * N) / 2.0).floor()
	var lado := _celda * N
	draw_style_box(Estilo.caja(Color.WHITE, 12, Estilo.BORDE), Rect2(_origen - Vector2(6, 6), Vector2(lado + 12, lado + 12)))

	for color: String in CASAS:
		_dibujar_casa(color)
	for i in RECORRIDO.size():
		_dibujar_casilla(RECORRIDO[i], Color.WHITE)
	for color: String in SALIDAS:
		var rect := _rect(RECORRIDO[SALIDAS[color]])
		_dibujar_casilla(RECORRIDO[SALIDAS[color]], Estilo.color_de(color).lerp(Color.WHITE, 0.55))
		draw_arc(rect.get_center(), _celda * 0.3, 0.0, TAU, 24, Estilo.color_de(color), 2.5, true)
	for color: String in PASILLOS:
		var inicio: Vector2i = PASILLOS[color][0]
		var direccion: Vector2i = PASILLOS[color][1]
		for k in 7:
			_dibujar_casilla(inicio + direccion * k, Estilo.color_de(color).lerp(Color.WHITE, 0.15))
	_dibujar_meta()
	_dibujar_fichas()


func _dibujar_casa(color: String) -> void:
	var rect := _rect(CASAS[color], Vector2i(8, 8))
	draw_rect(rect, Estilo.color_de(color))
	draw_style_box(Estilo.caja(Color.WHITE, int(_celda * 0.6)), rect.grow(-_celda))
	for k in 4:
		draw_circle(_hueco_casa(color, k), _celda * 0.75, Estilo.color_de(color).lerp(Color.WHITE, 0.75))


func _dibujar_casilla(celda: Vector2i, fondo: Color) -> void:
	var rect := _rect(celda)
	draw_rect(rect, fondo)
	draw_rect(rect, Color("#c9d0db"), false, 1.0)


func _dibujar_meta() -> void:
	var a := _origen + Vector2(8, 8) * _celda
	var b := _origen + Vector2(11, 11) * _celda
	var centro := (a + b) / 2.0
	draw_colored_polygon(PackedVector2Array([a, Vector2(b.x, a.y), centro]), Estilo.color_de("amarillo"))
	draw_colored_polygon(PackedVector2Array([Vector2(b.x, a.y), b, centro]), Estilo.color_de("azul"))
	draw_colored_polygon(PackedVector2Array([b, Vector2(a.x, b.y), centro]), Estilo.color_de("rojo"))
	draw_colored_polygon(PackedVector2Array([Vector2(a.x, b.y), a, centro]), Estilo.color_de("verde"))
	draw_circle(centro, _celda * 0.45, Color.WHITE)


func _dibujar_fichas() -> void:
	_zonas_clic.clear()
	var por_casilla := {}
	for jugador: Dictionary in _jugadores:
		var fichas: Array = jugador.fichas
		for k in fichas.size():
			if fichas[k] < 0:
				_dibujar_ficha(jugador, k, _hueco_casa(jugador.color, k), _celda * 0.58)
			else:
				por_casilla.get_or_add(fichas[k], []).append([jugador, k])
	for casilla: int in por_casilla:
		var grupo: Array = por_casilla[casilla]
		var centro := _rect(RECORRIDO[casilla]).get_center()
		for n in grupo.size():
			if grupo.size() == 1:
				_dibujar_ficha(grupo[n][0], grupo[n][1], centro, _celda * 0.42)
			else:
				_dibujar_ficha(grupo[n][0], grupo[n][1], centro + DESPLAZAMIENTOS[n % 4] * _celda, _celda * 0.3)


func _dibujar_ficha(jugador: Dictionary, indice: int, centro: Vector2, radio: float) -> void:
	var numero := indice + 1
	var es_movible: bool = jugador.id == _activo_id and numero in _movibles
	if es_movible:
		draw_circle(centro, radio + _celda * 0.2, Color(Estilo.PRIMARIO, 0.3))
		_zonas_clic.append({"centro": centro, "radio": radio, "ficha": numero})
	if es_movible and numero == _seleccionada:
		draw_arc(centro, radio + _celda * 0.16, 0.0, TAU, 32, Estilo.PRIMARIO, 3.0, true)
	draw_circle(centro + Vector2(0, 2), radio, Color(0, 0, 0, 0.18))
	draw_circle(centro, radio, Color.WHITE)
	draw_circle(centro, radio * 0.8, Estilo.color_de(jugador.color).darkened(0.05))
	var tamano := maxi(int(radio * 1.05), 8)
	draw_string(Estilo.negrita(), centro + Vector2(-radio, tamano * 0.36), str(numero),
			HORIZONTAL_ALIGNMENT_CENTER, radio * 2.0, tamano, Color.WHITE)


func _hueco_casa(color: String, k: int) -> Vector2:
	var centro := _origen + (Vector2(CASAS[color]) + Vector2(4, 4)) * _celda
	var direcciones := [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]
	return centro + direcciones[k] * _celda * 1.6


func _rect(celda: Vector2i, tamano := Vector2i.ONE) -> Rect2:
	return Rect2(_origen + Vector2(celda) * _celda, Vector2(tamano) * _celda)


static func _construir_recorrido() -> Array[Vector2i]:
	var r: Array[Vector2i] = []
	# Brazo superior: columna izquierda hacia arriba, extremo y columna derecha hacia abajo.
	for y in range(7, -1, -1):
		r.append(Vector2i(8, y))
	r.append(Vector2i(9, 0))
	for y in range(0, 8):
		r.append(Vector2i(10, y))
	# Brazo derecho.
	for x in range(11, 19):
		r.append(Vector2i(x, 8))
	r.append(Vector2i(18, 9))
	for x in range(18, 10, -1):
		r.append(Vector2i(x, 10))
	# Brazo inferior.
	for y in range(11, 19):
		r.append(Vector2i(10, y))
	r.append(Vector2i(9, 18))
	for y in range(18, 10, -1):
		r.append(Vector2i(8, y))
	# Brazo izquierdo.
	for x in range(7, -1, -1):
		r.append(Vector2i(x, 10))
	r.append(Vector2i(0, 9))
	for x in range(0, 8):
		r.append(Vector2i(x, 8))
	return r
